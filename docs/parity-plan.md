# 鸿蒙版对齐任务清单

> 目标：在不重写架构的前提下，把 HarmonyOS 版逐页对齐微信小程序版 `../who_family_wechat`。
> 本文件是**唯一施工清单**。编码 agent 按 ID 顺序执行并更新状态；验收 agent 依据 `docs/acceptance.md` 独立验收。
>
> 最后更新：2026-11-11
> 基线提交：`688905d`（docs 未提交前）
> 构建基线：`assembleHap` 通过；CodeLinter 0 error / 14 warning

## 状态与约定

| 标记 | 含义 |
| --- | --- |
| `TODO` | 未开始 |
| `WIP` | 进行中（同时只能有一个编码 agent） |
| `BLOCKED` | 等待依赖或决策 |
| `DONE` | 完成并通过自测 |
| `DEFERRED` | 本轮不做，已登记为允许偏差 |

完成一个任务时，在对应行末追加：`DONE 2026-11-xx @agent`，并在 `## 变更记录` 写一行说明。

---

## 0. 范围与已确认决策

- **登录**：不做。继续使用 `env.ets` 的 `DEMO_TOKEN`，启动直接进 `Index`。`pages/login.vue` 不复刻，登记为允许偏差。
- **对齐标准**：结构、文案、配色、交互、状态尽量一致；像素级不强制。
- **微信专属**：文件/图片选择、系统分享等好做的用鸿蒙能力替代；微信好友分享/朋友圈/订阅消息不做。
- **AI**：客户端直连 DashScope，沿用 `env.ets` 的 key；需要流式。
- **支付**：不做。
- **鸿蒙额外页面全部保留并做好**：`Service`（服务聚合）、`ServiceExpress`（快递代取）、`ServiceSuccess`（通用成功）、`MeSetting`（设置）不做删除，按独立功能补齐并纳入验收。

## 页面映射

| # | 小程序（参考） | 鸿蒙（目标） | 备注 |
| --- | --- | --- | --- |
| 1 | `pages/home/index.vue` + `components/home/*` | `pages/Index.ets` | 5 Tab 宿主 |
| 2 | `pages/community/index.vue` + `components/community/*` | `pages/Community.ets` | Tab |
| 3 | `pages/community/detail.vue` + `components/community/detail/*` | `pages/CommunityDetail.ets` | |
| 4 | `pages/community/publish.vue` | `pages/CommunityPublish.ets` | 含选图与 AI 润色 |
| 5 | `pages/helper/index.vue` + `components/helper/*` | `pages/Helper.ets` | Tab，需流式 + Markdown |
| 6 | `pages/knowledge/index.vue` | `pages/Knowledge.ets` | Tab |
| 7 | `pages/knowledge/article.vue` + `FloatWindow` | `pages/KnowledgeArticle.ets` | 正文 + AI 解读 |
| 8 | `pages/recruit/index.vue` + `CategoryTabs`/`RecruitCard` | `pages/JobList.ets` | |
| 9 | `pages/recruit/detail.vue` | `pages/JobDetail.ets` | |
| 10 | `pages/me/index.vue` + `components/me/*` | `pages/Mine.ets` | Tab |
| 11 | `pages/me/profile/index.vue` | `pages/MeProfile.ets` | 头像上传 |
| 12 | `pages/me/address/index.vue` | `pages/MeAddress.ets` | |
| 13 | `pages/me/address/create.vue` | `pages/MeAddressCreate.ets` | |
| 14 | `pages/me/address/update.vue` | `pages/MeAddressUpdate.ets` | |
| 15 | `pages/me/order/index.vue` | `pages/MeOrder.ets` | |
| 16 | `pages/me/feedback.vue` | `pages/MeFeedback.ets` | 选图 + FAQ |
| 17 | `pages/me/about.vue` | `pages/MeAbout.ets` | |
| 18 | `pages/service/personinfo/personinfo.vue` | `pages/ServicePersonInfo.ets` | 静态模拟 + 天气 |
| 19 | `pages/service/schedule.vue` | `pages/ServiceSchedule.ets` | 含 AI 分析 |
| 20 | `pages/service/grade.vue` | `pages/ServiceGrade.ets` | 含 AI 分析 |
| 21 | `pages/service/print/index.vue` + `components/service/print/*` | `pages/ServicePrint.ets` | 文件选择上传 |
| 22 | `pages/service/print/success.vue` | `pages/ServicePrintSuccess.ets` | |
| 23 | `pages/focus/index.vue` | `pages/FocusPage.ets` | |
| 24 | `pages/task/index.vue` | `pages/TaskPage.ets` | |
| 25 | `pages/agreement/user.vue` | `pages/AgreementUser.ets` | 全文 |
| 26 | `pages/agreement/privacy.vue` | `pages/AgreementPrivacy.ets` | 全文 |
| 27 | `pages/login.vue` | 无 | DEFERRED（demo token） |
| — | （未注册）`service/express.vue` | `pages/ServiceExpress.ets` | 保留并完善（下单/地址/价格/成功） |
| — | （未注册）`service/success.vue` | `pages/ServiceSuccess.ets` | 保留并完善（通用成功页） |
| — | （未注册）`me/setting/` | `pages/MeSetting.ets` | 保留并完善（缓存/环境/版本） |
| — | 无 | `pages/Service.ets` | 保留并完善（服务聚合入口） |

---

## 阶段 0：基线

| ID | 任务 | 状态 |
| --- | --- | --- |
| P0.1 | 记录构建/检查基线：执行 `assembleHap` 与 CodeLinter，把命令、结果、环境写入 `docs/baseline.md`；截图当前 30 个页面（能跑设备时） | DONE 2026-11-11 @agent |
| P0.2 | 通读参考实现：为每个页面记录区块顺序、文案、交互、接口、空态（可直接补在对应任务下） | DONE 2026-11-11 @agent |
| P0.3 | 建立截图目录 `docs/acceptance/screenshots/`，约定命名 `<page>-<state>.png` | DONE 2026-11-11 @agent |

---

## 阶段 1：基础能力（必须先于页面施工）

| ID | 任务 | 关键实现 | 主要文件 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| F1 | 主题与设计 token | 颜色（含 `#07c160`/`#007aff`/背景灰）、字号层级、间距、圆角、阴影；提供 ArkUI 可直接用的常量/方法 | 新建 `ets/theme/Theme.ets` | 新页面不再散落魔法值；至少 3 个现有组件改用 token | DONE 2026-11-11 @agent |
| F2 | 基础组件库 | `PageHeader`（返回+标题+右侧）、`SectionCard`、`Tag`、`PrimaryButton`、`EmptyState`（升级）、`LoadingView`（升级）、`Skeleton`、`BottomSheet`、`ConfirmDialog`、`BackToTop` | `ets/components/common/*` | 组件可在任意页面复用；状态齐全（默认/按压/禁用） | DONE 2026-11-11 @agent（复修 M1：公共组件已接入页面；BottomSheet 暂未接入，确认场景统一用 ConfirmDialog；复验待定） |
| F3 | 网络图片替换 | 用 `Image(url)` 替代 Web 渲染；本地占位图、加载失败回退、圆角/裁剪、列表复用 | 重写 `components/RemoteImage.ets`，删除/改造 `WatermarkImage.ets` | 所有网络图不再创建 Web 引擎；列表滚动无明显卡顿；无 SSL 自动放行 | DONE 2026-11-11 @agent |
| F4 | 网络层增强 | 二进制 `PUT` 上传、流式响应（SSE/chunk）、无 token/401 统一处理、可选重试；保持现有信封解包 | `api/HttpClient.ets`、`api/ApiConfig.ets` | 单测/手工验证 JSON、二进制、流式三类请求 | DONE 2026-11-11 @agent（复修 M2：UploadService→putBinary 已接入；401 探测通过，真实上传成功 NOT TESTED；复验待定） |
| F5 | 媒体选择与上传 | `PhotoViewPicker` 选图（头像/社区/反馈）、`DocumentViewPicker` 选文件（打印）、读文件为 base64/ArrayBuffer、大小/类型校验 | 新建 `services/UploadService.ets` | 三类场景均能选到文件并产出可上传数据 | DONE 2026-11-11 @agent（复修 M3：发布/头像/反馈/打印四处已接入选择器；模拟器无媒体/文件，选择后读取链路 NOT TESTED；复验待定） |
| F6 | Markdown 渲染 | 标题、列表、粗斜体、行内/块代码、引用、链接、分割线；不引入第三方依赖 | 新建 `components/common/MarkdownView.ets` | 助手回复与知识正文可正确渲染代码块和列表 | DONE 2026-11-11 @agent |
| F7 | AI 服务层 | DashScope 流式对话、取消、错误重试；成绩/课表分析、发布润色、知识解读共用 | 新建 `services/AiService.ets`；改造 `api/HelperApi.ets` | 流式逐字输出；断网有错误态；key 不落日志 | DONE 2026-11-11 @agent |
| F8 | 内容检查接口 | `/check/text`、`/check/img` 封装；上传前先检查，失败阻断并提示 | 新建 `api/CheckApi.ets` | 发布/资料保存前均走检查（与小程序一致） | DONE 2026-11-11 @agent（复修 M4：发布/评论/资料/头像已接入检查；401 阻断已验证，通过路径 NOT TESTED；复验待定） |
| F9 | 列表模式 | 下拉刷新、分页（`lastPostId`/`lastCommentId`）、加载更多、到底提示、回到顶部 | 新建 `services/PagedList.ets` 或页面内统一模式 | 社区/我的动态/评论三处复用同一模式 | DONE 2026-11-11 @agent（复修 M5：三处分页/刷新/回顶已接入；真实分页 NOT TESTED（401），回顶与到底提示已验证；复验待定） |
| F10 | 导航栏统一 | 所有子页加 `PageHeader`，标题按小程序 `pages.json`；安全区/状态栏适配 | 全部子页 | 每个子页都能点返回；标题与小程序一致 | DONE 2026-11-11 @agent |
| F11 | Mock 拆分与内容迁移 | `MockData.ets` 按域拆分到 `ets/mock/`；迁移知识文章、校园通知、服务卡、协议全文 | `ets/utils/MockData.ets` → `ets/mock/*` | 页面引用不变或平滑迁移；内容与参考一致 | DONE 2026-11-11 @agent（复修 M6：知识正文逐字迁移 4434 字符，代码块/列表/链接运行态已验证；复验待定） |

---

## 阶段 2：页面对齐

### 2.1 首页 / 社区 / 招聘

| ID | 页面 | 当前差距 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| P2.1 | 首页 `Index.ets` | 轮播/服务/通知写死（与小程序一致）；招聘卡、问候语、日期、布局细节需逐项比对 | 对齐 `HomeHeader`、`ServiceRecommend`、`CampusNotifications`、`RecruitmentCard` 的区块顺序/文案/尺寸；服务入口跳转正确；招聘卡跳详情 | 与小程序首页逐区块对照无缺项；滚动/点击正常 | DONE 2026-11-11 @coding-agent |
| P2.2 | 社区列表 `Community.ets` | 缺分类 Tab、动态类型卡片（好物/跑腿/二手/评分）、图片九宫格、分页、下拉刷新、回到顶部；点赞为局部更新 | 对齐 `PostCard`/`ErrandCard`/`Rating`/`SecondHand`；实现 `postTypes`、`lastPostId` 分页、下拉刷新、乐观点赞 | 四类卡片可展示；分页/刷新/点赞与小程序一致 | DONE 2026-11-11 @coding-agent（顶部四 Tab 固定，`postTypes` 用于发布分类；二手/评分保持参考的“开发中”占位） |
| P2.3 | 社区详情 `CommunityDetail.ets` | 缺作者信息完整布局、图片网格、统计栏、二级回复、评论点赞/删除、分页 | 对齐 `components/community/detail/*`；实现一级/二级评论、回复、删除、加载更多 | 评论两级完整；删除/回复可用；图片网格正确 | DONE 2026-11-11 @coding-agent（参考实现无“评论点赞”，未新增；加载更多评论按“满 10 条”显示） |
| P2.4 | 发布动态 `CommunityPublish.ets` | 分类是手输文本；无选图；AI 润色是假 Toast；无内容检查 | 分类选择器；最多 3/9 张图（以小程序为准）；`prepare-post → 上传 → finalize-post`；AI 流式润色；文本/图片检查 | 纯文字与带图发布均成功；润色可用；检查失败有提示 | DONE 2026-11-11 @coding-agent（最多 4 张，与参考一致；图片发布链路未实测） |
| P2.5 | 招聘列表 `JobList.ets` | 缺分类 Tab、筛选/搜索、卡片信息密度 | 对齐 `RecruitCard`；参考页 `CategoryTabs` 被注释，最终**隐藏分类栏**；分页/刷新/回顶保留 | 与参考一致（无分类栏）；卡片/分页/刷新正常 | DONE 2026-11-11 @coding-agent（按复验意见隐藏分类栏；后端仅 4 条推荐岗位，`lastId` 加载更多未触发；失败降级/全量空态未实测） |
| P2.6 | 招聘详情 `JobDetail.ets` | 基础信息/收藏已有；投递、公司信息、福利标签、底部操作栏需比对 | 对齐 `pages/recruit/detail.vue` 全区块；投递状态与接口一致 | 所有区块齐全；投递/收藏状态可持久 | DONE 2026-11-11 @coding-agent（补投递人数/发布时间/失败重试；收藏切换与返回列表同步已实测并恢复；投递会写生产数据，未实测） |

### 2.2 助手 / 知识

| ID | 页面 | 当前差距 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| P2.7 | 助手 `Helper.ets` | 非流式、无 Markdown、无预设问题动效/会话管理/复制/重试 | 基于 F7 改流式；`MarkdownView`；对齐 `ChatInput`/`PresetQuestions`/`AIMessage`；消息缓存与清空 | 逐字输出；代码块正确；预设问题可点；历史可恢复 | DONE 2026-11-11 @coding-agent（错误气泡/重试、预设问题、复制、清空、历史恢复已实测；真实逐字输出 NOT TESTED：DashScope key 401） |
| P2.8 | 知识列表 `Knowledge.ets` | Mock 数据缩水；分类/推荐/搜索/排序可能缺失 | 迁移 `static/mock/knowledge/index.js`；对齐卡片、分类 Tab、推荐标识 | 分类/推荐/搜索与小程序一致；文章可进入 | DONE 2026-11-11 @coding-agent（参考实现无搜索/排序，未新增；28 篇文章与 15 个分类已迁移；分类/推荐/进入详情/收藏数同步已实测） |
| P2.9 | 知识详情 `KnowledgeArticle.ets` | 正文仅 3 句占位；AI 解读为假加载；无 Markdown/TOC/收藏 | 迁移 `dynamic-programming.js` 等正文；`MarkdownView`；AI 解读走 F7 流式；点赞/收藏 | 正文完整可滚动；AI 解读真实输出；收藏状态正确 | DONE 2026-11-11 @coding-agent（正文/代码块/到底/点赞收藏持久/列表同步/AI 错误态已实测；参考无 TOC，未新增；AI 真实解读 NOT TESTED：key 401） |

### 2.3 我的

| ID | 页面 | 当前差距 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| P2.10 | 我的 `Mine.ets` | 主体已有；缺头像上传入口、消息入口行为、我的动态卡片样式、下拉刷新/回到顶部 | 对齐 `UserProfile`/`QuickNav`/`CoreFunctions`/`MyPostCard`；我的动态分页 | 四个区块与小程序一致；动态可进详情；刷新可用 | DONE 2026-11-12 @coding-agent（补齐我的动态多图网格/预览、浏览量保底、相对时间、本地点赞、删除二次确认；资料返回后 `userRefreshAt` 触发全局刷新；回顶阈值对齐 400；修复专注时长 NaN。删除动态仅验证确认框，未执行真实删除；动态分页未触发） |
| P2.11 | 个人资料 `MeProfile.ets` | 无头像选择/上传；检查接口未接 | 基于 F5 选图 + `/check/img` + `PUT /user/avatar`；文本走 `/check/text`；字段/校验对齐 | 头像可改并刷新全局；非法内容被拦截 | DONE 2026-11-12 @coding-agent（头像选择→10MB/类型校验→`/check/img`→`PUT /user/avatar`→全局头像刷新；昵称 15/简介 100 限制与 `/check/text`；性别/年级改为下拉选择；移除参考中不存在的“学号”；保存后返回“我的”并触发资料刷新。原值保存已实测且恢复；相册为空，选图后上传链路 NOT TESTED） |
| P2.12 | 地址三页 | 列表/新增/修改已有；默认地址、删除确认、表单校验需比对 | 对齐 `me/address/*`；空态/错误态 | 增删改查/默认切换完整 | DONE 2026-11-12 @coding-agent（字段改为参考的 `alias/fullAddress`，数字 id 与小程序兼容；列表默认标识、点击设默认、新增置顶与自动默认、编辑、删除确认、删除默认后首条回补默认；新增/编辑/删除已实测，随后恢复后端原 3 条地址与原默认；失败降级 NOT TESTED） |
| P2.13 | 订单 `MeOrder.ets` | 状态筛选与卡片细节需比对 | 对齐小程序订单状态、空态、跳转打印 | 筛选正确；空态/跳转正常 | DONE 2026-11-12 @coding-agent（状态筛选/空态/去打印、卡片字段对齐参考：`startOrderTime`/`endOrderTime`、派送地址仅派送服务显示、状态色；后端 null 字段归一化修复崩溃。已完成筛选空态、去打印跳转已实测；未创建打印订单） |
| P2.14 | 反馈 `MeFeedback.ets` | 无选图、FAQ、字数统计、联系方式校验 | 对齐 `me/feedback.vue`；提交行为与小程序一致（本地模拟也是允许的） | UI 完全一致；提交反馈符合参考行为 | DONE 2026-11-12 @coding-agent（装饰圆、必填红星、正文 500 上限与计数、最多 3 图选择/预览/删除、选图走 `UploadService`+`/check/img`、联系方式、FAQ；提交按参考 1.5s 模拟→提示→返回。模拟器相册为空，选图后的检查/入列 NOT TESTED。FAQ 参考为静态条目，未做展开） |
| P2.15 | 关于 `MeAbout.ets` | 内容/布局需比对 | 对齐 `me/about.vue` 全部条目与链接 | 文案/链接一致 | DONE 2026-11-12 @coding-agent（渐变头图+logo、平台定位/核心模块/我们的优势/页脚逐字对齐；参考无联系方式、协议入口与版本号，未新增，相关入口在设置页；条目与链接已实测） |
| P2.16 | 设置 `MeSetting.ets` | 小程序未注册（死代码），鸿蒙版保留 | 做完整设置页：缓存清理（含确认）、生产/本地后端切换并即时生效、当前环境展示、版本信息、关于/协议入口、演示会话重置（不清 token，只清缓存） | 每个开关/按钮有真实效果；切换环境后接口立即走新地址；无死链 | DONE 2026-11-12 @coding-agent（当前环境/后端地址展示、生产↔本地即时切换并实测连通性（本地失败、生产恢复成功）、版本信息 `1.0.0 (1000000)`、关于/用户协议/隐私政策入口、清除缓存确认、演示会话重置仅清缓存保留 token；上传链路自检保留） |

### 2.4 校园服务

| ID | 页面 | 当前差距 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| P2.17 | 人流监测 `ServicePersonInfo.ets` | 静态简化：缺温度/天气图标、实时/预测双栏细节、5 槽位、建议区、刷新节奏 | 迁移 `academic-data.json` 与小程序算法/文案；对齐 `personinfo.vue` 全区块；图表用 `DataPanel`/`Gauge`/`Canvas`，实现前调用 `dataviz` skill | 三类地点切换正确；实时/预测数据与参考逻辑一致；天气区完整；图表配色/结构一致 | TODO |
| P2.18 | 课表 `ServiceSchedule.ets` | 查询通；缺 AI 分析、学期/周次细节、课程详情弹层、空态 | 对齐 `schedule.vue`；接入 F7 AI 分析；保存学号/密码方式与小程序一致 | 查询/切换周次/详情/AI 分析均可用 | TODO |
| P2.19 | 成绩 `ServiceGrade.ets` | 查询通；缺 AI 分析、统计卡、学期筛选、详情 | 对齐 `grade.vue`；接入 F7 AI 分析 | 统计/GPA/筛选/AI 分析均可用 | TODO |
| P2.20 | 打印 `ServicePrint.ets` | 文件名手输；无文件选择/预览/大小；价格与表单细节不足 | 基于 F5 选文件为 base64；对齐 `PrintForm`/`PriceCard`/`ServiceAreaNotice`/`ServiceIntroCard`；份数、地址、校验 | 选文件→下单成功；成功页跳转正确 | TODO |
| P2.21 | 打印成功 `ServicePrintSuccess.ets` | 细节比对 | 对齐 `print/success.vue` | 订单信息/按钮行为一致 | TODO |
| P2.22 | 专注 `FocusPage.ets` | 计时/今日分钟已有；缺 <10 分钟拒绝、放弃确认、完成态/文案 | 对齐 `focus/index.vue` 与 `store/modules/focus.js` | 开始/放弃/结束/不足 10 分钟提示与参考一致 | TODO |
| P2.23 | 任务 `TaskPage.ets` | 基础 CRUD；缺筛选、详情弹层、状态切换细节、空态 | 对齐 `task/index.vue` 与 `store/modules/task.js` | 增删改查/完成切换/筛选/空态一致 | TODO |
| P2.24 | 快递代取 `ServiceExpress.ets` | 小程序未注册（死代码），鸿蒙版保留但功能简单 | 对齐 `service/express.vue` 的视觉与内容，并补完整流程：收货地址选择（复用地址簿）、快递大小/重量、价格计算、备注、立即下单、本地订单记录、成功页；无后端接口时用本地订单 + 明确演示提示 | 从入口到下单成功全流程可走通；地址/价格/校验正确；返回不丢状态 | TODO |

### 2.5 鸿蒙增强页面（保留并做好）

| ID | 页面 | 目标 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| P2.27 | 服务聚合 `Service.ets` | 让"更多服务"成为真实入口 | 服务分组（校园查询 / 生活服务 / 打印快递），卡片含图标、标题、描述、状态；跳转人流/课表/成绩/打印/快递；首页"更多服务"指向此页 | 所有卡片可点且目标正确；首页入口打通；无空链接 | TODO |
| P2.28 | 通用成功 `ServiceSuccess.ets` | 承载快递/其他业务成功态 | 按 `type` 展示标题、订单号、说明、主次按钮；与打印成功页风格统一；返回首页/查看订单 | 快递下单后正确跳转并展示对应文案；按钮可用 | TODO |
| P2.29 | 额外页面入口与去死链 | 四个增强页面都有明确入口 | `Mine`/`Service`/首页增加设置、服务聚合、快递入口；路由可达；不出现点了没反应的按钮 | 每个页面至少一条可达路径；全量路由无死链 | TODO |

### 2.6 协议

| ID | 页面 | 当前差距 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- | --- |
| P2.25 | 用户协议 `AgreementUser.ets` | 被压缩为 6 段 | 从 `pages/agreement/user.vue` 逐段迁移全文，保留日期 | 正文与参考逐字一致 | TODO |
| P2.26 | 隐私政策 `AgreementPrivacy.ets` | 被压缩 | 同上，迁移 `privacy.vue` 全文 | 正文与参考逐字一致 | TODO |

---

## 阶段 3：内容与数据

| ID | 任务 | 实现要点 | 完成标准 | 状态 |
| --- | --- | --- | --- | --- |
| P3.1 | 知识内容迁移 | `static/mock/knowledge/index.js`、`dynamic-programming.js`、`academic-data.json` → 鸿蒙静态数据 | 文章/分类/正文/人流静态数据与参考一致 | TODO |
| P3.2 | 首页与服务卡内容 | 轮播、服务卡、校园通知、评价、打印价格文案逐项对齐 | 文案/图片 URL/数字一致 | TODO |
| P3.3 | 全量文案审校 | 逐页对比中文文案、标点、emoji、按钮文字 | 无遗漏/错别字；差异已登记 | TODO |

---

## 阶段 4：收尾与回归

| ID | 任务 | 完成标准 | 状态 |
| --- | --- | --- | --- |
| P4.1 | 全页面走查 | 30 个路由均可进入/返回；无白屏/崩溃 | TODO |
| P4.2 | 异常路径 | 断网、空 token、401、空列表、超长文本均有降级/空态 | TODO |
| P4.3 | 性能 | 列表滚动流畅；无每项 Web 引擎；首屏无明显卡顿 | TODO |
| P4.4 | 静态检查 | CodeLinter 0 error；warning 逐条评估（不强制清零） | TODO |
| P4.5 | 文档更新 | README/AGENTS/本轮差异登记同步 | TODO |

---

## 阶段 5：独立验收

| ID | 任务 | 完成标准 | 状态 |
| --- | --- | --- | --- |
| P5.1 | 验收 agent 执行 `docs/acceptance.md` | 输出 `docs/acceptance-report.md`；Blocker/Major 为 0 | TODO |

---

## 推荐施工顺序

```text
P0 → F1 → F3 → F2 → F4 → F5 → F6 → F7 → F8 → F9 → F10 → F11
   → P2.1 → P2.2 → P2.3 → P2.4 → P2.5 → P2.6
   → P2.7 → P2.8 → P2.9
   → P2.10 → P2.11 → P2.12 → P2.13 → P2.14 → P2.15 → P2.16
   → P2.17 → P2.18 → P2.19 → P2.20 → P2.21 → P2.22 → P2.23 → P2.24
   → P2.27 → P2.28 → P2.29
   → P2.25 → P2.26
   → P3 → P4 → P5
```

依赖说明：

- F3（替换 Web 图片）必须最先做，否则所有列表页验收都不可靠。
- F5/F8 是 P2.4、P2.11、P2.14、P2.20 的前置。
- F6/F7 是 P2.7、P2.9、P2.18、P2.19 的前置。
- F10 可与页面任务并行，但每个页面完成前必须有可用返回。
- P3 可在对应页面完成后立即进行，不必等全部页面。

---

## 验收缺陷复修（M1–M6、m1–m3，2026-11-11）

> 依据 `docs/acceptance-report.md` 复修；验收报告本身未改动。环境仍为无效 `DEMO_TOKEN` / `DASHSCOPE_API_KEY`，因此真实成功链路统一标注 NOT TESTED。

| ID | 状态 | 实现与验证 |
| --- | --- | --- |
| M1 | DONE（组件接入） | 删除重复的 `components/EmptyState.ets`、`components/LoadingView.ets`；EmptyState/LoadingView/Skeleton 接入社区、详情、我的动态、招聘、知识、订单；Tag 接入社区卡片、招聘卡片/详情；PrimaryButton 接入发布/资料保存/反馈/打印下单；ConfirmDialog 接入评论删除、地址删除、清缓存、打印确认；BackToTop 接入社区/详情/我的/知识；SectionCard 接入我的/设置/服务聚合。BottomSheet 本轮未接入（所需确认场景均由 ConfirmDialog 覆盖）。 |
| M2 | DONE（代码 + 401 链路验证） | `UploadService.uploadToUrl()` 调用 `HttpClient.putBinary`；发布页 `publishWithImages` 走 prepare-post→图片检查→PUT→img-uploaded→finalize-post。设置页新增“上传链路自检”：选图（相册不可用时用内置 1x1 PNG）→ PUT → 显示 `HTTP 401（请求已发出）`。真实对象存储上传成功 **NOT TESTED**。 |
| M3 | DONE（选择器接入）/ 部分 NOT TESTED | 发布页最多 4 图、预览、删除；头像选图上传并写 `AppStorage.avatarUrl` 刷新全局头像；反馈最多 3 图；打印用 DocumentViewPicker 并展示文件名/大小/base64 下单。模拟器相册与文件目录为空：选择器均能打开（4/3/1 限额正确），但“选中文件后读取/预览/删除” **NOT TESTED**。 |
| M4 | DONE（阻断验证） | 发布（文本+图片）、评论、资料保存、头像保存均先走 CheckApi；401/失败阻断提交并提示。评论实测返回“内容检查未授权（401）”且不落本地评论；检查通过路径 **NOT TESTED**。 |
| M5 | DONE（代码）/ 部分 NOT TESTED | 社区推荐（lastPostId）、详情评论（lastCommentId）、我的动态（lastPostId）使用 PagedListController + Refresh + onScrollEdge + BackToTop；API 已补游标参数。回顶与“没有更多数据了”实测通过；真实后端分页 **NOT TESTED**（401 降级为 Mock）。 |
| M6 | DONE | `mock/KnowledgeContent.ets` 逐字迁移参考正文 4434 字符（脚本比对 `equal=true`，12 个代码围栏、无孤立反斜杠）；修复旧缓存导致截断的问题；运行态验证标题/列表/引用/代码块/链接与正文到底。 |
| m1 | DONE | 助手发送、流式回复、错误气泡后 `scrollEdge(Edge.Bottom)`；实测错误气泡自动进入可见区。 |
| m2 | DONE | 社区 401/失败优先读缓存，其次 `CommunityMock.posts()`；实测显示 4 条演示动态。 |
| m3 | DONE（代码） | `NetImage` 对 `imageUrl` 加 `@Watch` 重置 `loadFailed`，并实现 `aboutToReuse`；列表复用/URL 变化场景 **NOT TESTED**（无真实接口数据）。 |

### 本轮复修未验证项（NOT TESTED）

- 真实 `DEMO_TOKEN` 下的 JSON 成功链路、图片对象存储 PUT 成功、内容检查通过路径。
- 真实后端分页 `lastPostId` / `lastCommentId` 的翻页、去重、到底终止。
- 相册/文件选择后的实际读取、预览、删除、上传与 base64 下单（模拟器无媒体与文件）。
- `NetImage` 列表复用换 URL 的真实场景。
- `DASHSCOPE_API_KEY` 有效时的逐字流式输出（仅验证错误气泡与自动滚动）。

## 变更记录

| 日期 | 任务 | 说明 |
| --- | --- | --- |
| 2026-11-11 | — | 初始版本：完成架构评审、页面映射、任务拆分 |
| 2026-11-11 | P2.16 / P2.24 / P2.27–P2.29 | 决策：`Service` / `ServiceExpress` / `ServiceSuccess` / `MeSetting` 全部保留并完善，纳入验收 |
| 2026-11-11 | 工具链 | 新增 `scripts/` 预检、构建、检查、截图脚本；新增 dev/accept 两个项目级 skill |
| 2026-11-11 | P0.1–P0.3 | 新增 `docs/baseline.md`、`docs/reference-inventory.md`；截图约定 `<page>-<state>.png`；修复截图脚本 `.jpeg` 后缀问题 |
| 2026-11-11 | F1 | 新增 `theme/Theme.ets`（颜色/字号/间距/圆角/阴影）；`EmptyState`、`LoadingView`、`ServiceCard`、`MiniProgramCards` 改用 token |
| 2026-11-11 | F3 | 删除 `RemoteImage`/`WatermarkImage`，改为 `common/NetImage.ets`、`common/CoverImage.ets`（ArkUI Image、占位/失败回退/圆角裁剪）；预检 Web 图片 0 |
| 2026-11-11 | F2 | 新增 `components/common/`：PageHeader、SectionCard、Tag、PrimaryButton、EmptyState、LoadingView、Skeleton、BottomSheet、ConfirmDialog、BackToTop |
| 2026-11-11 | F4 | `HttpClient` 增加二进制 PUT、SSE 流式、401/缺 token 统一处理、GET 重试 |
| 2026-11-11 | F5 | 新增 `services/UploadService.ets`（PhotoViewPicker/DocumentViewPicker/fileIo/base64/大小类型校验） |
| 2026-11-11 | F6 | 新增 `components/common/MarkdownView.ets`（标题/列表/粗斜体/代码/引用/链接/分割线，自研解析）；知识正文与助手消息接入 |
| 2026-11-11 | F7 | 新增 `services/AiService.ets`（DashScope 流式/取消/空响应重试）；`HelperApi` 增加流式接口；助手页改用流式 |
| 2026-11-11 | F8 | 新增 `api/CheckApi.ets`（/check/text、/check/img，失败阻断） |
| 2026-11-11 | F9 | 新增 `services/PagedList.ets`（刷新/加载更多/到底文案/回到顶部） |
| 2026-11-11 | F10 | 全部 25 个子页加 `PageHeader` 并按 `pages.json` 对齐标题；Scroll/Stack 根页面完成包裹 |
| 2026-11-11 | F11 | Mock 按域拆分到 `ets/mock/`，迁移知识 28 篇+正文、校园动态 7 条、服务卡 5 张、协议全文；`MockData` 保留门面 |
| 2026-11-11 | 工具链 | 配置 cormorant MCP；新增 `docs/tech-notes.md` 与 `/harmony-api-research` skill；P2.17 图表接入 dataviz |
| 2026-11-11 | M1–M6 / m1–m3 | 复修验收缺陷：公共组件接入、上传链路与选图/选文件、内容检查、三处分页/刷新/回顶、知识正文完整迁移、助手自动滚动、社区失败降级、NetImage URL 重置；新增设置页上传链路自检。预检 `BUILD SUCCESSFUL`、CodeLinter 0 error / 19 warning；截图见 `docs/acceptance/screenshots/fix-*.png`；真实成功链路仍受 401 阻塞，详见“验收缺陷复修”节 |
| 2026-11-11 | P2.1 | 首页按 `HomeHeader`/`ServiceRecommend`/`CampusNotifications`/`RecruitmentCard` 对齐：轮播渐变遮罩与指示点、日期/问候语、5 张服务卡（含“更多服务”→`pages/Service`）、校园动态、招聘卡类型/单位/截止日期与空/加载态；“查看更多”修正为只跳 `JobList`（不再误切社区 Tab）。真实接口（用户、推荐岗位）已验证。截图 `p2-home-*.png` |
| 2026-11-11 | P2.2 | 社区列表：4 个固定 Tab（动态/跑腿/二手/评分，图标尺寸按参考）、动态多图网格（1/2/3/4 图）与点击预览、作者品牌标签（完整 26 个、旋转角标）、相对时间、乐观点赞+失败回滚、点赞/评论数从详情回传同步、发布后自动刷新、分页 `lastPostId`、下拉刷新、到底文案、回到顶部、关注本地切换；跑腿图标补齐 position/yuan/more 资源映射。真实接口分页/点赞/刷新已验证。二手/评分按参考保持“开发中”占位。截图 `p2-community-*.png` |
| 2026-11-11 | P2.3 | 社区详情：作者区/标题/正文/4 图网格（单图 16:9）/统计栏、一级评论（头像、作者、相对时间、内容、回复/删除）、二级回复（查看回复、加载更多、删除）、`lastCommentId` 分页、输入框（回复目标提示、200 字）、发送前后端 `/check/text`、删除确认、返回列表计数同步；评论 id 使用后端返回值以支持删除。真实接口已验证新增/删除一级评论与二级回复、点赞。评论点赞参考实现不存在，未实现。截图 `p2-community-detail-*.png`、`p2-detail-*.png` |
| 2026-11-11 | P2.4 | 发布动态：分类改为后端 `postTypes` 胶囊选择器（失败用参考兜底，不再手输）、最多 4 图与预览/删除、标题 99/正文 10000 限制、`check/text → prepare-post → finalize-post`（文本发布真实验证成功；修正后端数字 `communityId` 解析）、图片发布链路保留并在发布后清空表单/刷新社区第一页。AI 润色改为 `HelperApi.polishStream` 流式建议面板（查看/应用/取消/撤回/重试），服务不可用时保留原文并显示错误，不再假 Toast。截图 `p2-publish-*.png` |
| 2026-11-11 | P2.5 | 招聘列表：新增 `所有/已收藏/后端岗位类型` 横向分类 Tab、本地筛选、`recommend-jobs?lastId` 分页、下拉刷新、到底文案、回到顶部、失败缓存/Mock 降级与重试横幅；卡片按 `RecruitCard.vue` 对齐（logo/标题/单位/活动招募/热门/推荐/地点/描述/招募/已申请/截止日期/申请按钮），申请前确认。真实接口已验证分类切换、刷新、回顶、详情跳转、收藏回传；后端仅 4 条推荐岗位，分页未触发。截图 `p2b-joblist-*.png` |
| 2026-11-11 | P2.6 | 招聘详情：补 `投递人数`/`发布时间` 字段与详情失败重试态；`↵` 还原换行；收藏仅在接口成功后更新并写缓存/`jobDelta`，列表返回同步；投递确认与状态回传。收藏切换已实测并恢复原状态。截图 `p2b-jobdetail-*.png` |
| 2026-11-11 | P2.7 | 助手：对齐 `ChatInput`（输入框+纸飞机）/`PresetQuestions`（双列卡片、只在首条消息后显示）/`AIMessage`（头像+“答答Novus智能校园助手”+Markdown+光标）；错误气泡带“重试”，长按复制，菜单 ActionSheet（清空/检查AI状态），消息缓存支持重启恢复（含错误气泡）。截图 `p2b-helper-*.png` |
| 2026-11-11 | P2.8 | 知识列表：核对 15 分类/28 篇 Mock 与参考一致；卡片底部图标改为 `👁/👍`；启动与详情返回同步点赞数（`knowledgeLikedDelta`），分类/推荐/进详情已实测。参考无搜索/排序，未新增。截图 `p2b-knowledge-*.png` |
| 2026-11-11 | P2.9 | 知识详情：完整正文 Markdown/代码块/到底；点赞收藏落缓存并跨重启保持、返回列表同步；AI 智能解读改 `AiService.chatWithMessages` 真流式，失败显示错误与“重新解读”，不再假加载；浮窗按钮对齐绿色 AI 图标。截图 `p2b-knowledge-article-*.png`、`p2b-knowledge-ai-error.png` |
| 2026-11-12 | P2.10–P2.16 | 对齐“我的/资料/地址/订单/反馈/关于/设置”：多图动态与点赞删除、资料头像链路与下拉字段、地址 alias/fullAddress 与数字 id、订单时间字段与状态色、反馈 500 字/3 图/模拟提交、关于页渐变头图、设置页环境切换/版本/缓存/重置。preflight errors=0（CodeLinter 0 error / 19 warning）；截图 `docs/acceptance/screenshots/p2c-*.png` |

### P2.1–P2.4 未验证项与环境限制（2026-11-11）

- **图片资源 SSL**：后端 `imgList` 指向 `https://s3.hcyj.xyz:59000/...`，该域名证书无法通过系统校验（`curl` 直接失败，`-k` 返回 200）。ArkUI `Image` 按既定约束不做 SSL 放行，因此真实动态图片显示为 `NetImage` 占位；小程序不受此限制。属后端证书/环境问题，非页面代码缺陷。
- **图片发布**：模拟器相册为空且相机入口不可用，未能实际选择图片；`prepare-post → check/img → PUT → img-uploaded → finalize-post` 仅做代码走查，未跑通真实上传（S3 证书同样会影响 PUT）。文本发布已真实跑通（社区动态 id 195）。
- **AI 润色**：`DASHSCOPE_API_KEY` 仍为无效 key，已实测错误面板与“保留原文”，逐字流式输出 **NOT TESTED**。
- **评论点赞**：参考实现 `CommentItem.vue` 无点赞入口，按“以参考源码为准”未新增。
- **发布测试数据**：真实验证留下的自测动态（id 194、195、196、197）已通过后端 `DELETE /community/post` 清理并验证不存在。

### P2.5–P2.9 未验证项与环境限制（2026-11-11）

- **招聘分页**：`/hire/recommend-jobs` 当前仅返回 4 条岗位（不足一页），`lastId` 加载更多路径未触发；列表按“满 10 条才可能继续”判断，实际显示“没有更多数据了”。真实后端分页 **NOT TESTED**。
- **招聘投递**：`POST /hire/submit` 会在生产后端创建投递记录，按任务约定未发起真实投递；按钮确认框与状态回传为代码走查。**NOT TESTED**。
- **招聘失败态**：设备网络与演示 token 均可用，未能制造接口失败；缓存/Mock 降级与“重试”横幅为代码走查。**NOT TESTED**。
- **AI 逐字输出**：`DASHSCOPE_API_KEY` 仍为无效 key（实测返回“AI 服务未返回内容”）；已验证助手错误气泡/重试/原文保留/复制/自动滚底/重启恢复，以及知识 AI 解读错误态与“重新解读”。真实流式输出 **NOT TESTED**。
- **助手复制**：长按 AI/用户消息复制到系统剪贴板并提示“已复制”，未回读剪贴板内容核对（模拟器无剪贴板查看工具）。
- **知识收藏**：已按参考改为仅本地切换图标，不改计数、不落盘。
- **分类 Tab**：参考 `pages/recruit/index.vue` 中 `CategoryTabs` 被注释，复验后已隐藏分类栏，与参考渲染一致。
- **作者头像**：已改用 `api.dicebear.com/7.x/pixel-art/png` 网络头像（参考为 SVG，视觉等价），列表与详情一致。

### P2.10–P2.16 未验证项与环境限制（2026-11-12）

- **头像上传链路**：模拟器相册为空，`PhotoViewPicker` 可打开但无可选图片；“选图→`/check/img`→`PUT /user/avatar`→全局刷新”的完整链路 **NOT TESTED**（代码与 `/check/img` 接入已走查）。
- **反馈选图检查**：同上，相册为空；“选图→本地校验→`/check/img`→入列” **NOT TESTED**；`+` 按钮可打开选择器，已截图。
- **我的动态删除**：确认框文案/按钮已实测，未点“删除”执行真实删除（避免误删生产动态）；接口调用路径与社区删除一致。
- **我的动态分页**：未滚动到底触发 `lastId` 加载更多；到底文案与分页路径为代码走查。**NOT TESTED**。
- **地址失败态**：未在地址页单独制造接口失败；本地后端切换时空态/降级路径未打开地址页验证。**NOT TESTED**。
- **反馈 FAQ 展开**：参考 `me/feedback.vue` 为三条静态 FAQ，无展开交互；按参考未新增展开。
- **关于页联系方式/协议/版本**：参考 `me/about.vue` 不含这些条目，未自行新增；对应入口位于设置页并已实测。
- **环境切换**：本地后端未启动时“检测连接”提示失败；切回生产后提示“连接正常：zeroiceyaaaa”，`apiEnvironment` 持久化为 `production`，未留本地模式。
- **地址测试数据**：临时地址（id 4）已删除；后端 `addresses` 已恢复为原 3 条且默认地址为“张开鑫”。
