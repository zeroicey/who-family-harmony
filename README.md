# 互成一家 · 鸿蒙版

HarmonyOS NEXT（ArkTS / ArkUI）客户端，与「互成一家」微信小程序共用同一套后端：

- 生产：`https://api.hcyj.xyz`
- 本地：`http://localhost:3000`

项目从课程期末作业的 HarmonyOS 实现中抽取而来，现已作为独立客户端项目维护，不再只是一份作业交付物。

## 功能

五大 Tab：**首页 / 社区 / 助手 / 知识 / 我的**，共 30 个页面。

| 模块 | 能力 |
| --- | --- |
| 首页 | 轮播、服务入口、推荐岗位、社区动态、学习任务概览 |
| 社区 | 动态列表与详情、点赞、一级/二级评论、发布动态（图片上传） |
| 助手 | AI 对话（DashScope）、今日专注打卡、待办增删改查 |
| 知识 | 文章分类与详情 |
| 我的 | 个人资料、我的动态、订单、收货地址、意见反馈、设置 |
| 校园服务 | 远程打印下单与价格查询、快递代取、成绩查询、课表查询 |
| 通用 | 生产/本地后端切换、Preferences 会话缓存、接口失败自动降级 Mock 数据 |

## 技术栈

- **语言 / UI**：ArkTS + ArkUI 声明式 UI，Stage 模型
- **网络**：`@kit.NetworkKit`，自封装 `HttpClient`（统一信封解包、401 处理、超时）
- **存储**：`@kit.ArkData` Preferences（登录态、资料缓存、后端环境）
- **架构**：`api` 接口层 / `models` 模型层 / `stores` 状态层 / `pages` 页面层 / `components` 通用组件
- **SDK**：compatible `6.0.0(20)`，target `6.1.1(24)`

## 目录结构

```text
.
├── AppScope/                     # 应用级配置与图标
├── entry/                        # 主模块
│   └── src/main/
│       ├── ets/
│       │   ├── api/              # ApiConfig、HttpClient 与各业务接口
│       │   ├── components/       # 通用 UI 组件
│       │   ├── models/           # 数据模型
│       │   ├── pages/            # 30 个页面
│       │   ├── stores/           # AuthStore、CacheStore
│       │   └── utils/            # MockData、日期、日志、Toast
│       ├── resources/            # 字符串、颜色、图片、rawfile
│       └── module.json5
├── docs/
│   └── backend-api.md            # 后端接口与鉴权说明
├── build-profile.json5
└── hvigorfile.ts
```

## 快速开始

1. 安装 **DevEco Studio 6.x**，SDK 安装 API 20 及以上。
2. 复制本地配置模板并填写演示 token：

   ```bash
   cp entry/src/main/ets/api/env.example.ets entry/src/main/ets/api/env.ets
   ```

   `env.ets` 已在 `.gitignore` 中，**不会**进版本库。

3. DevEco Studio 打开本目录（不是 `entry/`），等待 Sync 完成。
4. 签名：`File → Project Structure → Signing Configs`，勾选
   **Automatically generate signature**。证书与密码不要提交。
5. 连接真机或模拟器运行 `entry` 模块。

未填写 `DEMO_TOKEN` 时，网络请求会失败并自动回退到 `utils/MockData.ets` 的演示数据，页面仍可浏览。

## 本地私密配置

`entry/src/main/ets/api/env.ets`：

```ts
export class ENV {
  // 互成一家后端演示 token（Authorization 裸 token，不要加 Bearer）
  static readonly DEMO_TOKEN: string = '';
  // 阿里云 DashScope API Key，用于「助手」页
  static readonly DASHSCOPE_API_KEY: string = '';
}
```

## 后端联调

- 默认环境为生产 `https://api.hcyj.xyz`，定义在 `entry/src/main/ets/api/ApiConfig.ets`。
- 切到本地后端：把 `ApiEnvironment.LOCAL` 写入 Preferences 的 `apiEnvironment`
  （`AuthStore` 默认播种 `PRODUCTION`），本地地址为 `http://localhost:3000`。
- 鉴权：后端直接读取 `Authorization` 头当 Redis key，**必须传裸 token**，不能加 `Bearer ` 前缀。
- 接口清单、返回信封、已接入/未接入接口见 [docs/backend-api.md](docs/backend-api.md)。

## 与既有项目的关系

| 仓库 | 角色 |
| --- | --- |
| `hcyj-series` | 互成一家全系列：`server` / `admin` / `miniapp` / `web` |
| `who_family_wechat` | 微信小程序客户端 |
| **本仓库** | HarmonyOS NEXT 客户端，只放鸿蒙端代码 |

## 开发计划

- [ ] 登录闭环：替换演示 token，接入真实登录与 401 重登
- [ ] 主题与设计 token 抽离，统一间距、圆角、字号
- [ ] 列表分页与下拉刷新标准化
- [ ] 关键链路 UI 测试与接口 Mock 测试
- [ ] CI：`hvigorw` 静态检查与构建

## 许可

修改版 MIT，仅限获得书面授权的使用者。详见 [LICENSE](LICENSE)。