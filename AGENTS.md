# AGENTS.md

> 面向所有参与本仓库的 AI agent 的入门说明。开始工作前请完整阅读本文件，再阅读：
>
> - [`docs/parity-plan.md`](docs/parity-plan.md)：逐项任务清单（唯一施工清单）
> - [`docs/acceptance.md`](docs/acceptance.md)：验收标准（验收 agent 唯一依据）
> - [`docs/tech-notes.md`](docs/tech-notes.md)：鸿蒙新能力评估与采用结论
> - [`docs/backend-api.md`](docs/backend-api.md)：后端接口与鉴权约定

---

## 0. TL;DR

- 这是「互成一家」的 **HarmonyOS NEXT（ArkTS / ArkUI）客户端**，与本机另一目录的微信小程序版 `../who_family_wechat` 共用同一套后端。
- 当前任务：**不重写架构，把鸿蒙版逐页对齐微信小程序版**（功能、交互、视觉尽量一致）。
- **已完成架构评审：可用，继续在现有工程上施工。** 构建与静态检查当前均通过。
- **不做真实登录**：按产品决策继续使用演示 token；不要实现微信登录或伪造登录流程。
- 小程序版是**只读参考实现**，禁止修改 `../who_family_wechat`。
- 运行时零第三方依赖；不要擅自引入 UI 库、Markdown 库或状态管理库。

---

## 1. 项目背景

| 项 | 值 |
| --- | --- |
| 应用名 | 互成一家 · 鸿蒙版 |
| bundleName | `com.hcyj.harmony` |
| 后端生产地址 | `https://api.hcyj.xyz` |
| 后端本地地址 | `http://localhost:3000` |
| 参考实现 | `../who_family_wechat`（uni-app 微信小程序） |
| 技术栈 | ArkTS + ArkUI 声明式 UI + Stage 模型 |
| SDK | compatible `6.0.0(20)`，target `6.1.1(24)` |
| 运行时依赖 | 无 |

后端响应信封统一为 `{ code, msg, data }`，鉴权头为 `Authorization: <裸 token>`（不加 `Bearer`）。详见 `docs/backend-api.md`。

---

## 2. 已确认的产品决策（2026-11-11）

以下决策已经由项目负责人确认，**不要自行更改或扩展范围**：

1. **登录**：继续使用 `entry/src/main/ets/api/env.ets` 中的 `DEMO_TOKEN` 播种会话，**不做**登录页、微信登录、华为账号或 token 刷新。
2. **对齐标准**："尽量一模一样"——页面结构、文案、配色、间距、交互、状态尽量与小程序一致；不要求像素级完全一致，但明显的视觉/行为差异必须记录并说明。
3. **微信专属能力**：好做的用鸿蒙系统能力替代（如文件选择、图片选择、系统分享）；不好做的（微信好友分享、朋友圈、订阅消息）可以不做，但必须登记为允许偏差。
4. **AI**：继续由客户端直连 DashScope（沿用 `env.ets` 的 `DASHSCOPE_API_KEY`），不新增后端代理。
5. **支付**：不实现。
6. **鸿蒙额外页面**：`Service` / `ServiceExpress` / `ServiceSuccess` / `MeSetting` **全部保留，并做到可用、好用**。小程序里对应的 `express` / `success` / `me/setting` 虽是未注册死代码，但鸿蒙版按独立功能补齐：服务聚合页要有真实入口与分组，快递代取要有完整下单/地址/价格/成功流程，通用成功页要能承载多业务，设置页要提供缓存清理、后端环境切换、版本信息等真实能力。它们同样纳入验收。

---

## 3. 快速开始

### 3.1 前置条件

- DevEco Studio 6.x，SDK 安装 API 20 及以上。
- 本机工具链路径（macOS）：
  - `DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk`
  - hvigor：`/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw`
  - ohpm：`/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin`
  - CodeLinter：`/Applications/DevEco-Studio.app/Contents/plugins/codelinter/run/index.js`

### 3.2 本地私密配置

`entry/src/main/ets/api/env.ets` 已被 `.gitignore` 忽略，**禁止提交**。首次配置：

```bash
cp entry/src/main/ets/api/env.example.ets entry/src/main/ets/api/env.ets
# 然后填入本机可用的 DEMO_TOKEN 与 DASHSCOPE_API_KEY
```

- 不要把真实 token / API Key 写进任何文档、提交、日志或回复。
- 需要密钥时向项目负责人索取，不要读取或回显已有值。

### 3.3 构建（已验证可用）

```bash
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export PATH=/Applications/DevEco-Studio.app/Contents/tools/node/bin:/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin:$PATH

/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`。

### 3.4 静态检查（已验证可用）

```bash
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node \
  /Applications/DevEco-Studio.app/Contents/plugins/codelinter/run/index.js \
  -c code-linter.json5 -e error entry/src/main/ets
```

基线：**0 error / 14 warning**。warning 为性能建议，可在收尾阶段处理，但 error 必须保持为 0。

### 3.5 运行

用 DevEco Studio 打开项目根目录（不是 `entry/`），在 `File → Project Structure → Signing Configs` 勾选自动签名，然后运行 `entry` 到真机或模拟器。签名材料不进版本库。

### 3.6 检索工具：cormorant MCP

项目根目录 `.mcp.json` 已配置 `cormorant` 多源检索：

```json
{ "mcpServers": { "cormorant": { "type": "http", "url": "http://100.64.0.1:8848/mcp" } } }
```

- Claude Code：首次打开项目需批准该 MCP server；可用 `claude mcp list` 查看状态。
- Codex CLI：已全局注册，`codex mcp list` 可见。
- 依赖 tailnet（`100.64.0.1`）；不可达时改用 WebSearch/WebFetch，并在结论里标注。
- 用途：查 HarmonyOS 官方 API、组件、Kit 版本；**不要凭记忆写 API**。
- 技术选型结论统一记录到 [`docs/tech-notes.md`](docs/tech-notes.md)，不要散落在对话里。

---

## 4. 架构地图

```text
.
├── AppScope/                       # 应用级配置、图标
├── entry/src/main/
│   ├── ets/
│   │   ├── api/                    # 后端接口封装（HttpClient + 各业务 Api）
│   │   ├── components/             # 通用 UI 组件
│   │   ├── models/                 # 数据模型
│   │   ├── pages/                  # 30 个页面（含 5 个 Tab 宿主）
│   │   ├── stores/                 # AuthStore、CacheStore
│   │   ├── utils/                  # MockData、日期、日志、Toast
│   │   ├── entryability/           # UIAbility 入口
│   │   └── entrybackupability/     # 备份扩展
│   ├── resources/                  # 字符串、颜色、图片、路由表
│   └── module.json5                # 权限（仅 INTERNET）、入口页
├── docs/
│   ├── backend-api.md
│   ├── parity-plan.md              # 施工清单
│   ├── acceptance.md               # 验收标准
│   └── tech-notes.md               # 鸿蒙新能力评估
├── scripts/                        # 构建/检查/预检/截图（跨 agent）
├── .claude/skills/                 # 编码与验收的项目级 skill
└── build-profile.json5
```

### 4.1 关键文件

| 文件 | 职责 |
| --- | --- |
| `entry/src/main/ets/entryability/EntryAbility.ets` | 加载 `pages/Index` |
| `entry/src/main/ets/pages/Index.ets` | 5 Tab 宿主：首页 / 社区 / 助手 / 知识 / 我的 |
| `entry/src/main/ets/api/ApiConfig.ets` | Base URL、超时、演示用户 `DEMO_USER_ID='2'`、响应信封 |
| `entry/src/main/ets/api/HttpClient.ets` | 统一请求、解包、日志；**无 token 直接抛错** |
| `entry/src/main/ets/stores/AuthStore.ets` | Preferences 会话、token、环境、后端模式 |
| `entry/src/main/ets/stores/CacheStore.ets` | JSON/字符串缓存（页面降级数据） |
| `entry/src/main/ets/utils/MockData.ets` | 全部降级演示数据（30KB，后续按域拆分） |
| `entry/src/main/ets/components/RemoteImage.ets` | 当前用 Web 渲染网络图，**待替换为 Image** |
| `entry/src/main/resources/base/profile/main_pages.json` | 路由表，新增页面必须登记 |

### 4.2 数据流

```text
Page(@State) → XxxApi → HttpClient → 后端
     ↑              ↓ 失败/无 token
     └── CacheStore / MockData（降级） ── AuthStore(token/env)
```

- 页面直接持有业务状态（无全局 store），跨页数据通过 `CacheStore` 或接口重新拉取。
- 所有接口失败都应降级到本地数据或空态，不能白屏/崩溃。
- 现有页面的 API 成功链路大多已通；缺口主要是 UI/交互与少数链路（上传、AI、分页）。

### 4.3 导航

- 启动页固定为 `pages/Index`，5 个 Tab 用 `Tabs + TabContent`。
- 子页用 `router.pushUrl({ url: 'pages/Xxx' })`，必须在 `main_pages.json` 注册且标 `@Entry`。
- **现状问题**：除少数页面外，子页没有顶部标题栏/返回按钮，只能依赖系统返回手势。任务清单 F2/F8 会统一补齐。

---

## 5. 架构评审结论（2026-11-11）

### 5.1 结论

**现有架构可用，不需要重写。** 依据：

- `assembleHap` debug 构建通过。
- CodeLinter 0 error（14 warning）。
- 分层清晰：`api / models / stores / pages / components`，没有循环依赖。
- 30 个页面已注册，覆盖小程序 27 个注册页面中的 26 个（仅缺 `login`）。
- 接口路径、响应信封、鉴权头与小程序一致，且已有真实接口成功链路。
- 图标等静态资源已基本迁移，运行时零第三方依赖。

### 5.2 施工前必须先解决的架构级问题

按顺序处理，否则后续逐页对齐会反复返工：

1. **网络图片用 Web 组件渲染**（`RemoteImage` / `WatermarkImage`）：列表里每个条目一个 Web 引擎，性能和内存不可接受，且自动接受 SSL 错误。统一替换为 ArkUI `Image` + 本地占位图 + 失败回退。
2. **子页缺导航栏**：需要统一的 `PageHeader`（返回 + 标题 + 可选右侧操作），按小程序 `pages.json` 的标题逐页配置。
3. **没有设计 token / 公共组件层**：颜色、间距、圆角、字号散落在页面内，逐页对齐会大量重复。先建 `theme/` 与基础组件。
4. **网络层能力不足**：只支持 JSON 请求，缺二进制上传、流式响应、401/无 token 的统一处理。
5. **缺媒体选择与上传链路**：头像、社区发图、反馈截图、打印文件目前都无法实现。
6. **缺 Markdown 渲染与流式 AI**：助手、知识解读、成绩/课表 AI 分析都依赖这两项。
7. **缺列表分页/下拉刷新/回到顶部模式**：小程序社区支持 `lastPostId`、下拉刷新，鸿蒙目前没有。
8. **Mock 数据集中且内容缩水**：`MockData.ets` 单文件 30KB，知识文章正文只有 3 句占位，协议正文被压缩。需要按域拆并迁移参考内容。

### 5.3 目标增量（不改变现有分层）

```text
ets/
├── api/          # 现有 + BinaryUpload / Stream / CheckApi
├── models/
├── stores/       # AuthStore / CacheStore + 领域 Store（分页、缓存）
├── services/     # AiService、UploadService、PagedList 辅助
├── theme/        # 颜色、字号、间距、圆角、阴影 token
├── components/   # common/ 与模块组件
└── pages/
```

不引入第三方运行时依赖；Markdown 渲染手写轻量实现。
不升级 SDK、不迁移 ArkUI V2 / Navigation、不用 `@kit.UIDesignKit`（HDS）重做核心五 Tab 视觉；理由与例外见 [`docs/tech-notes.md`](docs/tech-notes.md)。

---

## 6. 编码约定

### 6.1 参考实现优先

- 每做一个页面前，先读小程序对应 `.vue` 与其子组件、store、api，列出该页的：区块顺序、文案、交互、状态、接口。
- 小程序 → 鸿蒙页面映射见 `docs/parity-plan.md` 的对照表。
- 不要凭截图"大概还原"；以源码为准。

### 6.2 ArkTS / ArkUI

- 严格模式：不使用 `any` / `unknown`，不写动态索引、`eval`、对象展开等 ArkTS 受限语法。
- 页面/组件：`@Component export struct`；路由页面加 `@Entry`。
- 状态：`@State` 本地状态；`@Prop` 单向传值；需要双向/引用更新时用 `@Observed` + `@ObjectLink`（参考 `models/Job.ets` 与 `components/JobCard.ets`）。
- `ForEach` 在列表内容会变化时提供稳定 key；长列表优先考虑 `LazyForEach`。
- 网络图片统一用 `Image(url).objectFit(ImageFit.Cover)`，禁止新增 Web 渲染图片。
- 所有新增页面必须登记到 `entry/src/main/resources/base/profile/main_pages.json`。
- 所有新增子页必须使用统一 `PageHeader`（阶段 1 完成后），保证可返回。

### 6.3 样式与尺寸

- 小程序大量使用 `rpx` / `vw`；鸿蒙用 `vp`。换算参考：`750rpx ≈ 360vp`（约 `0.48×`），`100vw = 屏幕宽`。不要直接照搬数值。
- 优先使用阶段 1 引入的 `theme/` token；新代码不允许再散落魔法色值/字号。
- 底部 Tab 选中色沿用小程序 `#07c160`。
- 中文文案逐字对齐小程序；标点、空格、emoji 也一致。

### 6.4 接口

- 路径、方法、参数以小程序 `api/*.js` 与 `docs/backend-api.md` 为准。
- 新接口封装到对应 `XxxApi.ets`，页面不直接拼 URL。
- 所有请求需带 token（演示 token 已在 `AuthStore` 播种）。
- 失败处理：优先使用缓存/`MockData` 降级；必要时 Toast 提示，禁止吞掉错误导致空屏。

### 6.5 安全与仓库卫生

- 禁止提交 `entry/src/main/ets/api/env.ets`、签名文件、`build/`、`.hvigor/`、`oh_modules/`。
- 禁止修改 `../who_family_wechat`。
- 禁止在代码注释、文档、commit、回复中写入真实 token / API Key。
- 构建产物只用于本机验证，不提交。

### 6.6 提交与进度

- 一个任务一个提交/一批小提交；提交信息用中文，建议前缀 `feat(parity):` / `fix(parity):` / `docs(parity):`。
- 完成后在 `docs/parity-plan.md` 把任务状态改为 `DONE`，并附一行说明（改了哪些文件、验证命令、截图路径）。
- 不在任务范围内的大改（重构、换库、改构建）必须先问项目负责人。

---

## 7. 已知坑

1. **`HttpClient` 在 token 为空时直接抛错**，不会尝试登录；演示 token 失效会走 Mock。请求 401 时同样按失败降级。
2. **`DEMO_USER_ID='2'` 写死在 `Index` / `Mine` 等页面**；后续统一从 `AuthStore` 读取，不要继续扩散。
3. **Tab 页面同时标了 `@Entry` 又被 `Index` 当组件使用**：目前可运行，但不是理想结构；非必要不要改动，避免回归。
4. **小程序 `service/express`、`service/success`、`me/setting` 未注册**，但鸿蒙对应的 `ServiceExpress` / `ServiceSuccess` / `MeSetting` **要保留并做成可用功能**，不要按死代码删除；验收同样覆盖。
5. **小程序登录是纯 `wx.login`**，鸿蒙无法复刻；按决策不做登录，验收时作为允许偏差。
6. **本地后端是 `http://localhost:3000`**；真机访问需要改成电脑局域网 IP，且可能需要在 `module.json5` 配置 cleartext 网络策略。生产环境用 HTTPS，一般无需改。
7. **`RemoteImage` 自动接受所有 SSL 错误**，属于安全隐患；替换时不要保留该行为。
8. **知识文章/协议正文目前是占位或压缩版本**，不是小程序原文；内容迁移是独立任务。
9. **无自动化 UI 测试**；验证主要靠构建 + 真机/模拟器逐页走查 + 截图对比。

---

## 8. 多 agent 协作

### 8.1 编码 agent

- 建议先调用 skill `/harmony-parity-dev`（或阅读同名 `SKILL.md`）。
- 只依据 `docs/parity-plan.md` 施工，按 ID 顺序推进；有依赖的先等依赖完成。
- 每个任务完成后必须：构建通过、CodeLinter 0 error、相关页面真机/模拟器自测、任务状态更新。
- 不越界修改参考实现、不改构建配置、不引入依赖。
- 交付时给出：任务 ID、改动文件、验证命令与结果、截图路径、未完成项/风险。

### 8.2 验收 agent

- 建议先调用 skill `/harmony-parity-accept`（或阅读同名 `SKILL.md`）。
- **只读**：不修改 `entry/src/main/ets`、不"顺手修复"。发现问题写进报告。
- 依据 `docs/acceptance.md` 逐项执行，输出通过/失败/未测。
- 可以使用同一演示 token 与生产后端；可以构造失败场景（断网、无效 token）验证降级。
- 报告路径：`docs/acceptance-report.md`（覆盖上一版），截图放 `docs/acceptance/screenshots/`。
- 缺陷分级：Blocker / Major / Minor；Blocker 或 Major 未清零则验收不通过。

### 8.3 并行限制

- 同一时间只安排一个编码 agent 修改 `entry/src/main/ets`，避免同文件冲突。
- 验收在编码冻结后进行；验收期间不再合并新代码。

---

## 9. 常用命令速查

优先使用仓库自带脚本（跨 agent 通用，自动定位 DevEco 工具链）：

```bash
# 开工/交付前预检：卫生 + 路由 + 构建 + 静态检查
./scripts/preflight.sh

# 只跑静态部分（快）
./scripts/preflight.sh --no-build

# 单独构建 / 静态检查
./scripts/build.sh
./scripts/lint.sh

# 设备截图（需已连接真机/模拟器）
./scripts/screenshot.sh <page>-<state>

# 查看 git 状态/差异
git status -sb
git diff --stat

# 参考实现（只读）
ls ../who_family_wechat/pages
```

其他 DevEco 安装路径：`DEVECO_HOME=/path/to/DevEco-Studio.app ./scripts/preflight.sh`。

### 9.1 项目级 skill

Claude Code 环境下可直接使用：

- `/harmony-parity-dev`：编码 agent 的施工流程。
- `/harmony-parity-accept`：验收 agent 的只读验收流程。
- `/harmony-api-research`：HarmonyOS API / 新能力检索与版本判定。

其他 agent 直接读 `.claude/skills/*/SKILL.md` 或本文档即可；脚本对所有 agent 可用。

MCP：

```bash
claude mcp list        # 查看 cormorant 是否已批准
codex mcp list         # Codex 全局配置
```

---

## 10. 交付定义（DoD）

一个任务只有同时满足以下条件才算完成：

1. 功能/视觉与小程序对应页面一致，或差异已登记并获批。
2. `assembleHap` 通过；CodeLinter 无 error。
3. 页面可进入、可返回、无白屏/崩溃；空态、失败态可用。
4. 有真机或模拟器截图（存 `docs/acceptance/screenshots/`，命名 `<page>-<state>.png`）。
5. `docs/parity-plan.md` 状态与备注已更新。
6. 没有提交任何密钥、签名或构建产物。