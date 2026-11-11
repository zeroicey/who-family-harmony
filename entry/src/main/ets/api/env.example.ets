/**
 * 本地私密配置模板。
 *
 * 使用方式：
 *   cp entry/src/main/ets/api/env.example.ets entry/src/main/ets/api/env.ets
 * 然后填写真实值。env.ets 已在 .gitignore 中，不会提交到版本库。
 *
 * 不填也能跑：DEMO_TOKEN 为空时，所有接口自动降级为 MockData 演示数据。
 */
export class ENV {
  /**
   * 互成一家后端演示 token。
   * 后端直接读取 Authorization 头当 Redis key，必须是裸 token，不要加 "Bearer "。
   */
  static readonly DEMO_TOKEN: string = '';

  /** 阿里云 DashScope API Key，用于「AI 助手」页。留空则该页提示未配置。 */
  static readonly DASHSCOPE_API_KEY: string = '';
}