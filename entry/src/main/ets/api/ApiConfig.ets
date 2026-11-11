/**
 * 后端地址与通用请求配置。
 *
 * 互成一家鸿蒙版与微信小程序版共用同一套后端：
 *   生产：https://api.hcyj.xyz
 *   本地：http://localhost:3000
 */
export class ApiEnvironment {
  static readonly PRODUCTION: string = 'production';
  static readonly LOCAL: string = 'local';
}

export class ApiConfig {
  static readonly BASE_URL: string = 'https://api.hcyj.xyz';
  static readonly DEV_BASE_URL: string = 'http://localhost:3000';
  static readonly TIMEOUT: number = 10000;

  /** 演示账号 ID，对应后端 /user/userInfo?id=... */
  static readonly DEMO_USER_ID: string = '2';

  static currentBaseUrl(apiEnvironment: string): string {
    return apiEnvironment === ApiEnvironment.LOCAL ? ApiConfig.DEV_BASE_URL : ApiConfig.BASE_URL;
  }

  static environmentLabel(apiEnvironment: string): string {
    return apiEnvironment === ApiEnvironment.LOCAL ? '本地后端' : '生产后端';
  }
}

export class ApiResult<T> {
  code: number = 0;
  msg: string = '';
  data: T | null = null;
}

export class ApiEmptyResponse {
}