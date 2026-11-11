import { http } from '@kit.NetworkKit';
import { ApiConfig, ApiEnvironment, ApiResult } from './ApiConfig';
import { LogUtil } from '../utils/LogUtil';

export class HttpClient {
  private static lastRequestSummary: string = '尚未发起请求';

  static getLastRequestSummary(): string {
    return HttpClient.lastRequestSummary;
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

  static async request<T>(
    path: string,
    method: http.RequestMethod,
    token: string = '',
    data: object | null = null,
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<ApiResult<T>> {
    const methodText = HttpClient.methodName(method);
    if (token.length === 0) {
      HttpClient.lastRequestSummary = `${methodText} ${path} 未发送：缺少 token`;
      LogUtil.warn('http', `${methodText} ${path} skip token=empty`);
      throw new Error('缺少 token，使用演示数据');
    }

    const isAbsoluteUrl = path.indexOf('http://') === 0 || path.indexOf('https://') === 0;
    const baseUrl = isAbsoluteUrl ? '' : ApiConfig.currentBaseUrl(apiEnvironment);
    const requestUrl = `${baseUrl}${path}`;
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
        if (response.responseCode < 200 || response.responseCode >= 300) {
          HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} HTTP ${response.responseCode}`;
          LogUtil.error('http', `${methodText} ${requestUrl} status=${response.responseCode}`);
          reject(new Error(`HTTP ${response.responseCode}`));
          return;
        }
        try {
          const parsed = JSON.parse(response.result as string) as ApiResult<T>;
          HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 成功：HTTP ${response.responseCode}`;
          LogUtil.info('http', `${methodText} ${requestUrl} success status=${response.responseCode}`);
          resolve(parsed);
        } catch (_) {
          HttpClient.lastRequestSummary = `${ApiConfig.environmentLabel(apiEnvironment)} ${methodText} ${path} 响应 JSON 解析失败`;
          LogUtil.error('http', `${methodText} ${requestUrl} parse_failed`);
          reject(new Error('响应 JSON 解析失败'));
        }
      });
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
