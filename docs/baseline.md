# 鸿蒙版施工基线（2026-11-11）

> 对应任务：P0.1 / P0.2 / P0.3。
> 本文件记录开工基线、当前验证手段、已知风险与未完成项；后续批次请在文末追加新基线。

## 1. 环境

| 项 | 值 |
| --- | --- |
| 仓库 | `/Users/zeroicey/data/dev/hcyj-harmony` |
| 基线提交 | `688905d`（docs/脚本尚未提交） |
| 系统 | macOS 26.6.2（Darwin 25.6.0） |
| DevEco Studio | 26.0.1 |
| SDK | compatible `6.0.0(20)` / target `6.1.1(24)` |
| 设备 | 模拟器 `127.0.0.1:5555`（hdc 在线） |
| 后端 | 生产 `https://api.hcyj.xyz` |
| 参考实现 | `../who_family_wechat`（只读，未修改） |

构建 / 检查命令见 `scripts/build.sh`、`scripts/lint.sh`，一键预检：`./scripts/preflight.sh`。

## 2. 构建与静态检查基线

| 阶段 | 构建 | CodeLinter | 预检 Web 图片 |
| --- | --- | --- | --- |
| 开工基线（F3 前） | `BUILD SUCCESSFUL` | 0 error / 14 warning | 1 warning（页面仍引用 Web 图片组件） |
| 本批完成（F1–F11） | `BUILD SUCCESSFUL`，产物 `entry-default-unsigned.hap` | **0 error / 21 warning** | **0 warning** |

- 新增 7 条 warning 均为 `@performance/avoid-overusing-custom-component-check`（基础组件库的通用建议），不是缺陷。
- 预检路由检查：30 个注册路由全部有 `@Entry`，无未注册页面。
- 仓库卫生：未跟踪 `env.ets`、签名、`build/`、`.oh_modules/`。

## 3. 设备验证

- 安装：未签名 HAP 可直接 `hdc install -r` 到本机模拟器。
- 启动：`aa start -a EntryAbility -b com.hcyj.harmony` 正常。
- 已截图（`docs/acceptance/screenshots/`）：

| 文件 | 页面/状态 |
| --- | --- |
| `baseline-home-default.png` | F3 前首页基线（图片为破图，保留作对照） |
| `f13-home-default.png` | 首页：轮播 + 推荐服务 + 校园动态（7 条） |
| `f13-community-default.png` | 社区 Tab（空态） |
| `f13-mine-default.png` | 我的 Tab |
| `f13-meorder-pageheader.png` | 子页 PageHeader（我的订单）+ 返回 |
| `f13-knowledge-default.png` | 知识 Tab |
| `f13-knowledgearticle-markdown.png` | 知识详情：Markdown 渲染（标题/引用/列表/加粗） |
| `f13-meabout-pageheader.png` | 关于页：PageHeader + Scroll 包裹 |
| `f13-helper-default.png` | 助手 Tab |
| `f13-helper-stream-fixed.png` | 助手流式失败态（重试后友好错误气泡） |

- 已验证：首页/社区/知识/我的 4 个 Tab 可进入；我的 → 我的订单、知识 → 知识详情、我的 → 关于 可进入且返回正常；网络图片可正常显示。
- **未做真机验证**：只有模拟器。

## 4. 已知风险 / 环境问题

1. **演示 token 当前返回 401**：`/user/userInfo`、`/community/recommend-post`、`/checkin/*` 等接口均 `unauthorized`。页面按设计降级到 Mock/缓存，不白屏；但本批无法验证真实接口链路。需负责人更新 `env.ets` 的 `DEMO_TOKEN`。
2. **DashScope 在模拟器内无响应内容**：流式请求 160ms 内 `dataEnd`，无 chunk。代码已按“空响应=失败”处理并重试 2 次，最终显示“AI 服务暂不可用”。逐字输出的真实效果需在可访问外网的真机/模拟器环境复验。
3. **状态栏**：当前窗口未开启全屏布局，系统状态栏在应用内容区之外；`PageHeader` 不再重复计算状态栏高度。若后续改为沉浸式，需给 `PageHeader` 传 `topInset`。
4. 未签名 HAP 仅适用于本机模拟器；真机需 DevEco 自动签名。

## 5. 截图约定（P0.3）

- 目录：`docs/acceptance/screenshots/`。
- 命名：`<page>-<state>.png`，例如 `community-list-default.png`、`community-detail-loading.png`。
- 页面名用小写 kebab-case，状态取 `default / loading / empty / error / streaming / pageheader` 等。
- 采集命令：`scripts/screenshot.sh <page>-<state>`；脚本以 `.jpeg` 抓取后用 `sips` 转 `.png`（设备 `snapshot_display` 只接受 `.jpeg`）。

## 6. 本批未完成 / 后续

- 未进入 P2 页面任务（按要求）。
- F4/F5/F8/F9 为服务层，已通过编译与代码路径验证；尚未接入页面形成端到端演示。
- F7 流式链路已跑通（请求、重试、取消、错误态），真实内容输出待网络恢复后复验。