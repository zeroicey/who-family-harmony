import { ApiEmptyResponse, ApiEnvironment, ApiResult } from './ApiConfig';
import { HttpClient } from './HttpClient';

/** 内容检查结果：passed=false 时调用方必须阻断提交并提示 message。 */
export class CheckResult {
  passed: boolean = false;
  code: number = 0;
  message: string = '';

  constructor(passed: boolean, code: number, message: string) {
    this.passed = passed;
    this.code = code;
    this.message = message;
  }
}

/**
 * 内容安全检查（与小程序 api/check.js 一致）：
 * - POST /check/text  { text: JSON.stringify(data) }
 * - POST /check/img   { img: base64 或 data:image/...;base64,... }
 * 后端以 code=200 表示通过。
 */
export class CheckApi {
  private static passCode(code: number): boolean {
    return code === 200 || code === 0;
  }

  private static failMessage(result: ApiResult<ApiEmptyResponse>): string {
    if (result.msg !== null && result.msg.length > 0) {
      return result.msg;
    }
    return '内容包含敏感信息，请修改后重试';
  }

  /** 检查文本/对象内容；网络异常时按“未通过”处理，避免绕过检查。 */
  static async checkText(
    token: string,
    data: object,
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<CheckResult> {
    try {
      const payload: Record<string, string> = { 'text': JSON.stringify(data) };
      const result = await HttpClient.post<ApiEmptyResponse>('/check/text', token, payload, apiEnvironment);
      if (CheckApi.passCode(result.code)) {
        return new CheckResult(true, result.code, '');
      }
      return new CheckResult(false, result.code, CheckApi.failMessage(result));
    } catch (err) {
      return new CheckResult(false, 0, '内容检查服务暂不可用，请稍后重试');
    }
  }

  /** 检查图片（传入 base64，自动补 data URL 前缀）。 */
  static async checkImg(
    token: string,
    imageBase64: string,
    mimeType: string = 'image/jpeg',
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<CheckResult> {
    try {
      let img = imageBase64;
      if (img.indexOf('data:') !== 0) {
        img = `data:${mimeType};base64,${imageBase64}`;
      }
      const payload: Record<string, string> = { 'img': img };
      const result = await HttpClient.post<ApiEmptyResponse>('/check/img', token, payload, apiEnvironment);
      if (CheckApi.passCode(result.code)) {
        return new CheckResult(true, result.code, '');
      }
      return new CheckResult(false, result.code, CheckApi.failMessage(result));
    } catch (err) {
      return new CheckResult(false, 0, '图片检查服务暂不可用，请稍后重试');
    }
  }

  /** 文本检查未通过时抛出错误，便于“先检查再提交”的链路直接中断。 */
  static async ensureText(token: string, data: object, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    const result = await CheckApi.checkText(token, data, apiEnvironment);
    if (!result.passed) {
      throw new Error(result.message);
    }
  }

  static async ensureImg(
    token: string,
    imageBase64: string,
    mimeType: string = 'image/jpeg',
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<void> {
    const result = await CheckApi.checkImg(token, imageBase64, mimeType, apiEnvironment);
    if (!result.passed) {
      throw new Error(result.message);
    }
  }
}