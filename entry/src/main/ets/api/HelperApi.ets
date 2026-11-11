import { http } from '@kit.NetworkKit';
import { ENV } from './env';
import { ChatMessage } from '../models/MiniProgramModels';

class DashScopeMessage {
  role: string = '';
  content: string = '';

  constructor(role: string, content: string) {
    this.role = role;
    this.content = content;
  }
}

class DashScopeChatRequest {
  model: string = 'qwen-plus';
  messages: DashScopeMessage[] = [];
  stream: boolean = false;
  max_tokens: number = 1000;
  temperature: number = 0.7;
  top_p: number = 0.7;
  frequency_penalty: number = 0.5;

  constructor(message: string) {
    this.messages = [
      new DashScopeMessage(
        'system',
        '你是一个校园AI助手，名字叫答答Novus，专门为大学生提供帮助。请用简洁、友好的语言回答问题，重点关注校园生活、学习、服务等相关内容。\n\n回答格式要求：\n1. 可以使用 Markdown 格式，包括标题、列表、代码块等\n2. 代码块使用三个反引号包裹并注明语言\n3. 重要内容可以使用粗体或斜体强调\n4. 保持回答简洁明了，避免冗长'
      ),
      new DashScopeMessage('user', message)
    ];
  }
}

class DashScopeResponseMessage {
  role: string = '';
  content: string = '';
}

class DashScopeChoice {
  message: DashScopeResponseMessage = new DashScopeResponseMessage();
}

class DashScopeChatResponse {
  choices: DashScopeChoice[] = [];
}

export class HelperApi {
  private static readonly DASHSCOPE_API_URL: string = 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';

  private static buildHeader(): Record<string, string> {
    return {
      'Authorization': `Bearer ${ENV.DASHSCOPE_API_KEY}`,
      'Content-Type': 'application/json'
    };
  }

  private static messageId(): string {
    return `ai-${new Date().getTime()}`;
  }

  private static responseText(response: http.HttpResponse): string {
    if (typeof response.result === 'string') {
      return response.result;
    }
    if (response.result === null || response.result === undefined) {
      return '';
    }
    return `${response.result}`;
  }

  private static contentFromResponse(responseText: string): string {
    try {
      const parsed = JSON.parse(responseText) as DashScopeChatResponse;
      if (parsed.choices && parsed.choices.length > 0 && parsed.choices[0].message) {
        const content = parsed.choices[0].message.content;
        return content.length > 0 ? content : responseText;
      }
    } catch (_) {
      return responseText;
    }
    return responseText;
  }

  static async sendMessage(message: string): Promise<ChatMessage> {
    if (ENV.DASHSCOPE_API_KEY.trim().length === 0) {
      return new ChatMessage(
        HelperApi.messageId(),
        'ai',
        '请先在 entry/src/main/ets/api/env.ets 中填写 ENV.DASHSCOPE_API_KEY。'
      );
    }

    const payload = new DashScopeChatRequest(message);
    return await new Promise<ChatMessage>((resolve) => {
      const requestTask = http.createHttp();
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: HelperApi.buildHeader(),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: 30000,
        connectTimeout: 30000,
        usingCache: false,
        extraData: JSON.stringify(payload)
      };

      requestTask.request(HelperApi.DASHSCOPE_API_URL, options, (err: Error, response: http.HttpResponse) => {
        requestTask.destroy();
        if (err) {
          resolve(new ChatMessage(HelperApi.messageId(), 'ai', `AI API 调用失败：${err.message}`));
          return;
        }

        const rawText = HelperApi.responseText(response);
        if (response.responseCode < 200 || response.responseCode >= 300) {
          const content = rawText.length > 0 ? rawText : `HTTP ${response.responseCode}`;
          resolve(new ChatMessage(HelperApi.messageId(), 'ai', content));
          return;
        }

        resolve(new ChatMessage(HelperApi.messageId(), 'ai', HelperApi.contentFromResponse(rawText)));
      });
    });
  }

  static optimizePost(title: string, content: string): string {
    const safeTitle = title.trim().length === 0 ? '校园分享' : title.trim();
    const safeContent = content.trim().length === 0 ? '今天想记录一件校园生活里的小事。' : content.trim();
    return `标题建议：${safeTitle}\n\n正文润色：${safeContent}\n\n补充建议：可以写清时间、地点、需求和联系方式，让社区同学更容易理解并回应。`;
  }
}
