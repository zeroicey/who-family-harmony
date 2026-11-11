import { http } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';
import { ApiConfig, ApiEnvironment, ApiResult } from './ApiConfig';
import { LogUtil } from '../utils/LogUtil';

/** 统一网络错误：携带 HTTP 状态码与后端业务码，页面可据此降级。 */
export class ApiError extends Error {
  statusCode: number = 0;
  apiCode: number = 0;

  constructor(message: string, statusCode: number = 0, apiCode: number = 0) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.apiCode = apiCode;
  }
}

/** 流式响应回调：chunk 为增量文本，完成/失败各回调一次。 */
export interface StreamCallbacks {
  onChunk: (text: string) => void;
  onComplete: () => void;
  onError: (message: string) => void;
}

/** 流式请求句柄，支持中途取消（AI 生成停止）。 */
export class StreamRequest {
  private task: http.HttpRequest;
  private canceled: boolean = false;

  constructor(task: http.HttpRequest) {
    this.task = task;
  }

  isCanceled(): boolean {
    return this.canceled;
  }

  cancel(): void {
    if (this.canceled) {
      return;
    }
    this.canceled = true;
    try {
      this.task.off('dataReceive');
      this.task.off('dataEnd');
      this.task.off('dataReceiveProgress');
      this.task.destroy();
    } catch (err) {
      LogUtil.warn('http', `stream cancel cleanup failed: ${(err as Error).message}`);
    }
  }
}

export class HttpClient {
  private static lastRequestSummary: string = '尚未发起请求';
  private static unauthorizedListener: () => void = () => {
  };
  private static hasUnauthorizedListener: boolean = false;

  static getLastRequestSummary(): string {
    return HttpClient.lastRequestSummary;
  }

  /**
   * 注册 401 统一处理（例如清理会话、回到首页）。默认不做任何事，避免演示 token 被误清。
   */
  static setUnauthorizedHandler(handler: () => void): void {
    HttpClient.unauthorizedListener = handler;
    HttpClient.hasUnauthorizedListener = true;
  }

  private static notifyUnauthorized(): void {
    if (HttpClient.hasUnauthorizedListener) {
      HttpClient.unauthorizedListener();
    }
  }

  private static methodName(method: http.RequestMethod): string {
    if (method === http.RequestMethod.GET) {
      return 'GET';
    }
    if (method === http.RequestMethod.POST) {
      return 'POST';
    }
    if (method === http.RequestMethod.PUT) {
      return 'PUT';
    }
    if (method === http.RequestMethod.DELETE) {
      return 'DELETE';
    }
    return 'HTTP';
  }

  private static buildHeader(token: string): Record<string, string> {
    const header: Record<string, string> = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
    if (token.length > 0) {
      header['Authorization'] = token;
    }
    return header;
  }

  private static requestUrl(path: string, apiEnvironment: string): string {
    const isAbsoluteUrl = path.indexOf('http://') === 0 || path.indexOf('https://') === 0;
    return isAbsoluteUrl ? path : `${ApiConfig.currentBaseUrl(apiEnvironment)}${path}`;
  }

  /** 校验 token；缺失时统一抛出 401 语义错误（不自动清会话）。 */
  private static requireToken(token: string, methodText: string, path: string): void {
    if (token.length > 0) {
      return;
    }
    HttpClient.lastRequestSummary = `${methodText} ${path} 未发送：缺少 token`;
    LogUtil.warn('http', `${methodText} ${path} skip token=empty`);
    HttpClient.notifyUnauthorized();
    throw new ApiError('缺少 token，使用演示数据', 401);
  }

  /** 统一处理状态码 + JSON 信封解包。 */
  private static parseEnvelope<T>(
    response: http.HttpResponse,
    methodText: string,
    path: string,
    apiEnvironment: string
  ): ApiResult<T> {
    const status = response.responseCode;
    if (status === 401) {
      HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 未授权 HTTP 401`;
      LogUtil.warn('http', `${methodText} ${path} unauthorized`);
      HttpClient.notifyUnauthorized();
      throw new ApiError('登录状态已失效', 401);
    }
    if (status < 200 || status >= 300) {
      HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} HTTP ${status}`;
      LogUtil.error('http', `${methodText} ${path} status=${status}`);
      throw new ApiError(`HTTP ${status}`, status);
    }
    try {
      const raw = response.result as string;
      const parsed = JSON.parse(raw) as ApiResult<T>;
      HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 成功：HTTP ${status}`;
      LogUtil.info('http', `${methodText} ${path} success status=${status}`);
      return parsed;
    } catch (err) {
      HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 响应 JSON 解析失败`;
      LogUtil.error('http', `${methodText} ${path} parse_failed`);
      throw new ApiError('响应 JSON 解析失败', status);
    }
  }

  static async request<T>(
    path: string,
    method: http.RequestMethod,
    token: string = '',
    data: object | null = null,
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<ApiResult<T>> {
    const methodText = HttpClient.methodName(method);
    HttpClient.requireToken(token, methodText, path);
    const requestUrl = HttpClient.requestUrl(path, apiEnvironment);
    HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 请求中`;
    LogUtil.info('http', `${methodText} ${requestUrl} start token=present env=${apiEnvironment}`);

    return await new Promise<ApiResult<T>>((resolve, reject) => {
      const requestTask = http.createHttp();
      const options: http.HttpRequestOptions = {
        method: method,
        header: HttpClient.buildHeader(token),
        expectDataType: http.HttpDataType.STRING,
        readTimeout: ApiConfig.TIMEOUT,
        connectTimeout: ApiConfig.TIMEOUT,
        usingCache: false
      };

      if (data !== null) {
        options.extraData = JSON.stringify(data);
        LogUtil.info('http', `${methodText} ${path} body=${options.extraData}`);
      }

      requestTask.request(requestUrl, options, (err: Error, response: http.HttpResponse) => {
        requestTask.destroy();
        if (err) {
          HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 请求失败：${err.message}`;
          LogUtil.error('http', `${methodText} ${requestUrl} error=${err.message}`);
          reject(err);
          return;
        }
        try {
          resolve(HttpClient.parseEnvelope<T>(response, methodText, path, apiEnvironment));
        } catch (parseErr) {
          reject(parseErr);
        }
      });
    });
  }

  /**
   * 二进制上传（PUT）：用于社区图片、打印文件等直传对象存储。
   * 注意：不使用 JSON 序列化，保留调用方给定的 Content-Type。
   */
  static async putBinary<T>(
    path: string,
    token: string,
    binary: ArrayBuffer,
    contentType: string,
    apiEnvironment: string = ApiEnvironment.PRODUCTION,
    onProgress: (received: number, total: number) => void = () => {
    }
  ): Promise<ApiResult<T>> {
    const methodText = 'PUT';
    HttpClient.requireToken(token, methodText, path);
    const requestUrl = HttpClient.requestUrl(path, apiEnvironment);
    HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 上传中`;
    LogUtil.info('http', `${methodText} ${requestUrl} binary bytes=${binary.byteLength} type=${contentType}`);

    return await new Promise<ApiResult<T>>((resolve, reject) => {
      const requestTask = http.createHttp();
      const header: Record<string, string> = {
        'Accept': 'application/json',
        'Content-Type': contentType
      };
      if (token.length > 0) {
        header['Authorization'] = token;
      }
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.PUT,
        header: header,
        extraData: binary,
        expectDataType: http.HttpDataType.STRING,
        readTimeout: ApiConfig.TIMEOUT * 3,
        connectTimeout: ApiConfig.TIMEOUT,
        usingCache: false
      };

      requestTask.on('dataSendProgress', (info: http.DataSendProgressInfo) => {
        onProgress(info.sendSize, info.totalSize);
      });

      requestTask.request(requestUrl, options, (err: Error, response: http.HttpResponse) => {
        requestTask.off('dataSendProgress');
        requestTask.destroy();
        if (err) {
          HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 上传失败：${err.message}`;
          LogUtil.error('http', `${methodText} ${requestUrl} upload_error=${err.message}`);
          reject(err);
          return;
        }
        try {
          resolve(HttpClient.parseEnvelope<T>(response, methodText, path, apiEnvironment));
        } catch (parseErr) {
          reject(parseErr);
        }
      });
    });
  }

  /**
   * 流式请求（SSE / chunked）：用于 DashScope 逐字输出。
   * 返回句柄可取消；chunk 已按 UTF-8 增量解码。
   */
  static startStream(
    path: string,
    token: string,
    data: object,
    callbacks: StreamCallbacks,
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): StreamRequest {
    const requestUrl = HttpClient.requestUrl(path, apiEnvironment);
    HttpClient.lastRequestSummary = `STREAM ${path} 请求中`;
    LogUtil.info('http', `POST ${requestUrl} stream start`);
    const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
    const requestTask = http.createHttp();
    let finished = false;

    const header: Record<string, string> = {
      'Accept': 'text/event-stream',
      'Content-Type': 'application/json'
    };
    if (token.length > 0) {
      header['Authorization'] = token;
    }
    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.POST,
      header: header,
      extraData: JSON.stringify(data),
      connectTimeout: ApiConfig.TIMEOUT,
      // 流式响应可能持续数分钟，读超时放宽
      readTimeout: 300000,
      usingCache: false
    };

    requestTask.on('dataReceive', (chunk: ArrayBuffer) => {
      if (finished) {
        return;
      }
      try {
        const text = decoder.decodeWithStream(new Uint8Array(chunk), { stream: true });
        if (text.length > 0) {
          callbacks.onChunk(text);
        }
      } catch (err) {
        LogUtil.warn('http', `stream decode failed: ${(err as Error).message}`);
      }
    });
    requestTask.on('dataReceiveProgress', (info: http.DataReceiveProgressInfo) => {
      if (!finished && info.totalSize > 0) {
        HttpClient.lastRequestSummary = `STREAM ${path} 接收中 ${info.receiveSize}/${info.totalSize}`;
      }
    });
    requestTask.on('dataEnd', () => {
      if (finished) {
        return;
      }
      finished = true;
      HttpClient.lastRequestSummary = `STREAM ${path} 完成`;
      LogUtil.info('http', `POST ${requestUrl} stream end`);
      requestTask.off('dataReceive');
      requestTask.off('dataEnd');
      requestTask.off('dataReceiveProgress');
      requestTask.destroy();
      callbacks.onComplete();
    });

    requestTask.requestInStream(requestUrl, options, (err: Error, code: number) => {
      if (finished) {
        return;
      }
      if (err) {
        finished = true;
        HttpClient.lastRequestSummary = `STREAM ${path} 失败：${err.message}`;
        LogUtil.error('http', `POST ${requestUrl} stream error=${err.message}`);
        requestTask.off('dataReceive');
        requestTask.off('dataEnd');
        requestTask.off('dataReceiveProgress');
        requestTask.destroy();
        callbacks.onError(err.message);
        return;
      }
      if (code === 401) {
        HttpClient.notifyUnauthorized();
      }
      if (code < 200 || code >= 300) {
        finished = true;
        HttpClient.lastRequestSummary = `STREAM ${path} HTTP ${code}`;
        LogUtil.error('http', `POST ${requestUrl} stream status=${code}`);
        requestTask.off('dataReceive');
        requestTask.off('dataEnd');
        requestTask.off('dataReceiveProgress');
        requestTask.destroy();
        callbacks.onError(`HTTP ${code}`);
        return;
      }
      LogUtil.info('http', `POST ${requestUrl} stream opened status=${code}`);
    });

    return new StreamRequest(requestTask);
  }

  /** GET 可选重试：仅用于幂等请求，指数退避（300ms / 900ms）。 */
  static async getWithRetry<T>(
    path: string,
    token: string,
    retries: number = 2,
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<ApiResult<T>> {
    let lastError: Error = new Error('请求失败');
    for (let attempt = 0; attempt <= retries; attempt++) {
      try {
        return await HttpClient.get<T>(path, token, apiEnvironment);
      } catch (err) {
        lastError = err as Error;
        if (err instanceof ApiError && err.statusCode === 401) {
          throw lastError;
        }
        if (attempt < retries) {
          LogUtil.warn('http', `GET ${path} retry ${attempt + 1} after ${lastError.message}`);
          await HttpClient.sleep(300 * (attempt + 1));
        }
      }
    }
    throw lastError;
  }

  private static sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  static async get<T>(path: string, token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<ApiResult<T>> {
    return await HttpClient.request<T>(path, http.RequestMethod.GET, token, null, apiEnvironment);
  }

  static async post<T>(path: string, token: string, data: object, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<ApiResult<T>> {
    return await HttpClient.request<T>(path, http.RequestMethod.POST, token, data, apiEnvironment);
  }

  static async put<T>(path: string, token: string, data: object, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<ApiResult<T>> {
    return await HttpClient.request<T>(path, http.RequestMethod.PUT, token, data, apiEnvironment);
  }

  static async delete<T>(path: string, token: string, data: object, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<ApiResult<T>> {
    return await HttpClient.request<T>(path, http.RequestMethod.DELETE, token, data, apiEnvironment);
  }
}