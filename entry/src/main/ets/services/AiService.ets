import { http } from '@kit.NetworkKit';
import { ENV } from '../api/env';
import { HttpClient, StreamRequest } from '../api/HttpClient';
import { LogUtil } from '../utils/LogUtil';

/** 单条对话消息。 */
export class AiMessage {
  role: string = 'user';
  content: string = '';

  constructor(role: string, content: string) {
    this.role = role;
    this.content = content;
  }
}

/** 流式回调。onComplete 只在正常结束时调用一次；取消不触发。 */
export class AiCallbacks {
  onChunk: (text: string) => void = () => {
  };
  onComplete: (fullText: string) => void = () => {
  };
  onError: (message: string) => void = () => {
  };

  constructor(onChunk: (text: string) => void, onComplete: (fullText: string) => void, onError: (message: string) => void) {
    this.onChunk = onChunk;
    this.onComplete = onComplete;
    this.onError = onError;
  }
}

/** 生成参数。 */
export class AiOptions {
  model: string = 'qwen-plus';
  systemPrompt: string = '';
  maxTokens: number = 1000;
  temperature: number = 0.7;
  topP: number = 0.7;
  frequencyPenalty: number = 0.5;
  retries: number = 2;
}

/** 流式会话句柄：可取消，取消后不再触发任何回调。 */
export class AiSession {
  private request: StreamRequest | null = null;
  private canceled: boolean = false;

  attach(request: StreamRequest): void {
    this.request = request;
  }

  isCanceled(): boolean {
    return this.canceled;
  }

  cancel(): void {
    this.canceled = true;
    if (this.request !== null) {
      this.request.cancel();
      this.request = null;
    }
  }
}

interface DashScopeDelta {
  content?: string;
}

interface DashScopeChoice {
  delta?: DashScopeDelta;
  message?: DashScopeDelta;
}

interface DashScopeChunk {
  choices?: DashScopeChoice[];
}

class DashScopeRequest {
  model: string = 'qwen-plus';
  messages: AiMessage[] = [];
  stream: boolean = false;
  max_tokens: number = 1000;
  temperature: number = 0.7;
  top_p: number = 0.7;
  frequency_penalty: number = 0.5;

  constructor(messages: AiMessage[], options: AiOptions, stream: boolean) {
    this.model = options.model;
    this.messages = messages;
    this.stream = stream;
    this.max_tokens = options.maxTokens;
    this.temperature = options.temperature;
    this.top_p = options.topP;
    this.frequency_penalty = options.frequencyPenalty;
  }
}

/**
 * DashScope 客户端（客户端直连，沿用 env.ets 的 DASHSCOPE_API_KEY）。
 *
 * - 流式：chat / chatWithMessages，逐字回调，可取消；
 * - 一次性：complete，用于成绩/课表分析等无需逐字的场景；
 * - 失败重试：仅在尚未输出任何内容时按 retries 重试；
 * - 不打印 API Key。
 */
export class AiService {
  static readonly DEFAULT_SYSTEM_PROMPT: string =
    '你是一个校园AI助手，名字叫答答Novus，专门为大学生提供帮助。请用简洁、友好的语言回答问题，重点关注校园生活、学习、服务等相关内容。\n\n回答格式要求：\n1. 可以使用 Markdown 格式，包括标题、列表、代码块等\n2. 代码块使用三个反引号包裹并注明语言\n3. 重要内容可以使用粗体或斜体强调\n4. 保持回答简洁明了，避免冗长';
  static readonly API_URL: string = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';

  static isConfigured(): boolean {
    return ENV.DASHSCOPE_API_KEY.trim().length > 0;
  }

  /** 默认携带助手人设的单轮问答。 */
  static chat(message: string, callbacks: AiCallbacks, options: AiOptions = new AiOptions()): AiSession {
    const opts = options;
    if (opts.systemPrompt.trim().length === 0) {
      opts.systemPrompt = AiService.DEFAULT_SYSTEM_PROMPT;
    }
    const messages: AiMessage[] = [new AiMessage('system', opts.systemPrompt), new AiMessage('user', message)];
    return AiService.chatWithMessages(messages, callbacks, opts);
  }

  /** 多轮对话（知识解读、润色、分析共用）。 */
  static chatWithMessages(messages: AiMessage[], callbacks: AiCallbacks, options: AiOptions = new AiOptions()): AiSession {
    const session = new AiSession();
    if (!AiService.isConfigured()) {
      callbacks.onError('请先在 entry/src/main/ets/api/env.ets 中填写 ENV.DASHSCOPE_API_KEY。');
      return session;
    }
    AiService.startAttempt(session, messages, callbacks, options, 0, '');
    return session;
  }

  private static startAttempt(
    session: AiSession,
    messages: AiMessage[],
    callbacks: AiCallbacks,
    options: AiOptions,
    attempt: number,
    accumulated: string
  ): void {
    if (session.isCanceled()) {
      return;
    }
    const payload = new DashScopeRequest(messages, options, true);
    let buffer = '';
    let received = accumulated;
    let done = false;

    const stream = HttpClient.startStream(
      AiService.API_URL,
      `Bearer ${ENV.DASHSCOPE_API_KEY}`,
      payload,
      {
        onChunk: (text: string) => {
          if (session.isCanceled() || done) {
            return;
          }
          buffer += text.split('\r').join('');
          let eventEnd = buffer.indexOf('\n\n');
          while (eventEnd >= 0) {
            const event = buffer.substring(0, eventEnd);
            buffer = buffer.substring(eventEnd + 2);
            const delta = AiService.parseEvent(event);
            if (delta === '[DONE]') {
              done = true;
              callbacks.onComplete(received);
              return;
            }
            if (delta.length > 0) {
              received += delta;
              callbacks.onChunk(delta);
            }
            eventEnd = buffer.indexOf('\n\n');
          }
        },
        onComplete: () => {
          if (session.isCanceled() || done) {
            return;
          }
          done = true;
          // 空响应按失败处理，避免出现空白气泡
          AiService.failOrRetry(session, messages, callbacks, options, attempt, received, 'AI 服务未返回内容，请稍后重试');
        },
        onError: (message: string) => {
          if (session.isCanceled() || done) {
            return;
          }
          done = true;
          AiService.failOrRetry(session, messages, callbacks, options, attempt, received, message);
        }
      }
    );
    session.attach(stream);
  }

  /** 失败处理：未输出任何内容时按配置重试，否则回调错误。 */
  private static failOrRetry(
    session: AiSession,
    messages: AiMessage[],
    callbacks: AiCallbacks,
    options: AiOptions,
    attempt: number,
    received: string,
    message: string
  ): void {
    if (session.isCanceled()) {
      return;
    }
    if (received.length === 0 && attempt < options.retries) {
      LogUtil.warn('ai', `stream retry ${attempt + 1} reason=${message}`);
      setTimeout(() => {
        AiService.startAttempt(session, messages, callbacks, options, attempt + 1, received);
      }, 600 * (attempt + 1));
      return;
    }
    callbacks.onError(AiService.friendlyError(message));
  }

  /** 解析一条 SSE 事件，返回增量文本；[DONE] 原样返回。 */
  private static parseEvent(event: string): string {
    const lines: string[] = event.split('\n');
    let text = '';
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.indexOf('data:') !== 0) {
        continue;
      }
      const data = line.substring(5).trim();
      if (data === '[DONE]') {
        return '[DONE]';
      }
      if (data.length === 0) {
        continue;
      }
      try {
        const chunk = JSON.parse(data) as DashScopeChunk;
        if (chunk.choices !== undefined && chunk.choices.length > 0) {
          const choice = chunk.choices[0];
          if (choice.delta !== undefined && choice.delta.content !== undefined) {
            text += choice.delta.content;
          }
        }
      } catch (err) {
        LogUtil.warn('ai', `sse parse failed len=${data.length}`);
      }
    }
    return text;
  }

  /** 一次性补全（非流式）。失败抛出带友好信息的 Error。 */
  static async complete(messages: AiMessage[], options: AiOptions = new AiOptions()): Promise<string> {
    if (!AiService.isConfigured()) {
      throw new Error('请先在 entry/src/main/ets/api/env.ets 中填写 ENV.DASHSCOPE_API_KEY。');
    }
    const payload = new DashScopeRequest(messages, options, false);
    return await new Promise<string>((resolve, reject) => {
      const task = http.createHttp();
      const headers: Record<string, string> = {
        'Authorization': `Bearer ${ENV.DASHSCOPE_API_KEY}`,
        'Content-Type': 'application/json'
      };
      task.request(AiService.API_URL, {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: JSON.stringify(payload),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 60000,
        connectTimeout: 30000,
        usingCache: false
      }, (err: Error, response: http.HttpResponse) => {
        task.destroy();
        if (err) {
          reject(new Error(AiService.friendlyError(err.message)));
          return;
        }
        const raw = typeof response.result === 'string' ? response.result as string : '';
        if (response.responseCode < 200 || response.responseCode >= 300) {
          reject(new Error(AiService.friendlyError(`HTTP ${response.responseCode}`)));
          return;
        }
        try {
          const chunk = JSON.parse(raw) as DashScopeChunk;
          if (chunk.choices !== undefined && chunk.choices.length > 0) {
            const choice = chunk.choices[0];
            if (choice.message !== undefined && choice.message.content !== undefined) {
              resolve(choice.message.content);
              return;
            }
          }
          resolve(raw);
        } catch (parseErr) {
          reject(new Error('AI 响应解析失败'));
        }
      });
    });
  }

  /** 单轮问答的一次性版本。 */
  static async ask(message: string, systemPrompt: string = '', options: AiOptions = new AiOptions()): Promise<string> {
    const system = systemPrompt.trim().length > 0 ? systemPrompt : AiService.DEFAULT_SYSTEM_PROMPT;
    return await AiService.complete([new AiMessage('system', system), new AiMessage('user', message)], options);
  }

  private static friendlyError(message: string): string {
    if (message.indexOf('401') >= 0) {
      return 'AI 服务鉴权失败，请检查 DASHSCOPE_API_KEY 是否有效。';
    }
    if (message.indexOf('429') >= 0) {
      return 'AI 请求过于频繁，请稍后再试。';
    }
    if (message.indexOf('timeout') >= 0 || message.indexOf('Timeout') >= 0) {
      return 'AI 响应超时，请稍后重试。';
    }
    return `AI 服务暂不可用：${message}`;
  }
}