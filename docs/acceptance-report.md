# 验收报告（基础能力批次 F1–F11）

- 验收日期：2026-11-11
- 验收范围：P0.1–P0.3、F1–F11；P2 页面视觉矩阵不在本批
- 仓库：`/Users/zeroicey/data/dev/hcyj-harmony`
- 参考实现：`../who_family_wechat`（只读，提交 `47896e3`，工作区干净）
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，API 24，型号 `emulator`
- 后端：生产 `https://api.hcyj.xyz`
- 构建结果：clean 后 `BUILD SUCCESSFUL`，产物 `entry/build/default/outputs/default/entry-default-unsigned.hap`
- CodeLinter：**0 error / 21 warning**（warning 均为性能建议）

## 冻结与工作区

| 项 | 值 |
| --- | --- |
| `git rev-parse HEAD` | `688905de09d57b98a92c6360369466b6721555af` |
| `git status --short` | 验收开始前 56 项；写入本报告后 57 项。39 个已跟踪文件被修改，另有 `theme/`、`services/`、`components/common/`、`mock/`、`api/CheckApi.ets`、`docs/`、`scripts/` 等未跟踪 |
| `git diff --stat` | 39 files changed, 656 insertions(+), 651 deletions(-)（不含未跟踪文件） |

**冻结风险（不计入缺陷数）**：当前 HEAD 仍是施工前基线 `688905d`，本批全部改动尚未提交。报告中的“冻结提交”无法代表被验收代码，复验前应先由编码 agent 提交，否则后续任何改动都无法与本次证据区分。

## 环境阻塞

| 项 | 实测 | 影响 |
| --- | --- | --- |
| `DEMO_TOKEN` | `GET /user/userInfo?id=2` 返回 **HTTP 401 Unauthorized** | 首页/社区/我的等真实接口成功链路无法验证；页面按失败路径降级 |
| `DASHSCOPE_API_KEY` | DashScope 返回 **HTTP 401 invalid_api_key** | AI 真实逐字流式输出无法验证；只验证到失败重试与错误气泡 |

上述两项是环境/凭据问题，不作为代码缺陷。密钥值未读取回显，仅确认已配置且无效。

## 全局门槛

| ID | 结果 | 证据 / 备注 |
| --- | --- | --- |
| G1 构建 | PASS | 清理构建目录后重新 `assembleHap`，`BUILD SUCCESSFUL in 4s`，HAP 存在 |
| G2 静态检查 | PASS | `./scripts/lint.sh`：`Defects: 21; Errors: 0; Warns: 21` |
| G3 仓库卫生 | PASS | `env.ets` 已被 `.gitignore` 忽略；`git ls-files` 无 env/签名/build/.hvigor/oh_modules；但工作区未提交，见“冻结风险” |
| G4 参考实现完整性 | PASS | `../who_family_wechat` HEAD `47896e3`，`git status --short` 为空 |
| G5 路由完整 | PASS（静态）/ NOT TESTED（全量运行） | `main_pages.json` 30 条路由均有文件且带 `@Entry`；本批只实际走查 5 Tab + 4 个子页，未逐条进出 30 路由 |
| G6 演示数据链路 | NOT TESTED（真实接口）/ 部分通过（降级） | token 401，真实成功链路未验证；首页/我的可显示 Mock，社区 401 后直接置空，见 M8 |
| G7 密钥安全 | PASS | 日志仅打印 `token=present`；未发现 key/token 明文日志；报告不含密钥 |
| G8 截图证据 | PASS（本批范围） | 主要页面与关键状态截图已重新独立采集，见“页面走查”；未覆盖全部 30 页 |

## F1–F11 结果

| ID | 结果 | 证据 | 缺陷 |
| --- | --- | --- | --- |
| F1 主题 token | PASS | `entry/src/main/ets/theme/Theme.ets` 提供颜色/字号/间距/圆角/阴影；18 个文件引用；`EmptyState`、`LoadingView`、`MiniProgramCards`、`ServiceCard` 已改用 token | — |
| F2 公共组件 | **FAIL** | 10 个组件文件齐全，但只有 `PageHeader` 被 25 个子页使用；`SectionCard`、`Tag`、`PrimaryButton`、`EmptyState`、`LoadingView`、`Skeleton`、`BottomSheet`、`ConfirmDialog`、`BackToTop` 在页面中均无导入/调用（页面里的 `EmptyState()`/`Tag()` 是本地 Builder，不是公共组件）；默认/按压/禁用状态无法实际验证 | M1 |
| F3 网络图片替换 | PASS | 预检“Web 图片残留”为 0；`RemoteImage.ets`、`WatermarkImage.ets` 已删除；`NetImage`/`CoverImage` 被 8 个页面/卡片引用；首页网络图正常显示；无 `onSslErrorEvent` | m3（状态复用） |
| F4 网络层增强 | **FAIL** | JSON/401/无 token 逻辑存在；流式经 `AiService` 实际跑到失败重试；`putBinary` 只有定义（`HttpClient.ets`）无任何调用方，二进制 PUT 未验证；JSON 成功链路被 401 阻塞。F4 完成标准要求的 JSON/二进制/流式三类手工验证未达成 | M2 |
| F5 媒体选择与上传 | **FAIL** | `UploadService.ets` 实现了 PhotoViewPicker/DocumentViewPicker/fileIo/base64/大小类型校验，但全仓库零引用；发布页两个 `+` 是静态 Text，无点击；个人资料头像、反馈选图、打印选文件均未接入 | M3 |
| F6 Markdown 渲染 | PASS（部分 NOT TESTED） | `MarkdownView.ets` 支持标题/列表/粗斜体/行内代码/代码块/引用/链接/分割线；知识详情实际渲染了标题、引用、有序列表、粗体、分割线。**代码块/行内代码/链接运行态 NOT TESTED**：知识正文在代码块前被截断，AI 无真实输出 | M6（内容原因） |
| F7 AI 服务层 | PASS（错误态）/ NOT TESTED（逐字输出） | `Helper` → `HelperApi.sendStream` → `AiService` → `HttpClient.startStream` 链路可达；空响应重试 2 次后回调错误，日志确认 `stream retry 1/2`；真实逐字输出因 DashScope 401 无法验证；key 未落日志 | m1 |
| F8 内容检查接口 | **FAIL** | `CheckApi.ets` 封装了 `/check/text`、`/check/img`，但全仓库零引用；`CommunityApi`、`UserApi`、发布页、资料保存、反馈均未调用；参考实现是在 `api/community.js`、`api/user.js` 内先检查再提交 | M4 |
| F9 列表模式 | **FAIL** | `PagedList.ets` 与 `ScrollToTop` 零引用；社区 `refresh()` 一次性拉取，无 `lastPostId`/加载更多/到底提示/回到顶部；评论接口无 `lastCommentId` 分页；我的动态无分页 | M5 |
| F10 导航栏统一 | PASS | 25 个子页全部使用 `PageHeader`；标题与 `pages.json` 对照一致（含招聘、招聘详情、动态详情、发布动态、知识详情、我的订单、打印下单成功等）；实测 ServicePersonInfo、MeOrder、MeAbout 标题栏可返回 | — |
| F11 Mock 拆分与内容迁移 | **FAIL** | `MockData.ets` 已拆为 `ets/mock/*` 门面，协议全文（用户 8 段、隐私 5 段、日期/联系方式）、校园通知 7 条、服务卡文案与参考一致；但知识正文 `KnowledgeMock.dpMarkdownBlocks()` 仅约 662 字符，参考 `dynamic-programming.js` 正文约 4468 字符，且截断在“代码实现：”后的一个反斜杠 | M6 |

## 页面走查

| 页面/状态 | 结果 | 截图 |
| --- | --- | --- |
| 首页（5 Tab、网络图、服务卡、校园动态） | PASS | `docs/acceptance/screenshots/accept-home-default.png` |
| 社区（401 后空态、底部 Tab） | PASS（空态可见，未降级 Mock） | `docs/acceptance/screenshots/accept-community-empty.png` |
| 助手（初始态、输入框、键盘避让） | PASS | `docs/acceptance/screenshots/accept-helper-default.png` |
| 助手（AI 发送后、错误气泡未自动进入视口） | 缺陷 m1 | `docs/acceptance/screenshots/accept-helper-ai-error-before-scroll.png` |
| 助手（手动上滑后可见“AI 服务暂不可用…”） | PASS（错误回调存在） | `docs/acceptance/screenshots/accept-helper-ai-error-visible.png` |
| 知识列表 | PASS | `docs/acceptance/screenshots/accept-knowledge-default.png` |
| 知识详情 Markdown（标题/引用/列表/粗体） | PASS | `docs/acceptance/screenshots/accept-knowledge-article-markdown.png` |
| 知识详情到底（正文截断） | **FAIL**（M6） | `docs/acceptance/screenshots/accept-knowledge-article-end.png` |
| 我的 | PASS | `docs/acceptance/screenshots/accept-mine-default.png` |
| 我的订单（PageHeader + 返回 + Mock 订单） | PASS | `docs/acceptance/screenshots/accept-meorder-pageheader.png` |
| 关于（PageHeader + 返回） | PASS | `docs/acceptance/screenshots/accept-meabout-pageheader.png` |
| 校园人流数据（服务子页、PageHeader + 返回） | PASS | `docs/acceptance/screenshots/accept-servicepersoninfo-default.png` |

## 缺陷清单

| 编号 | 级别 | 页面/任务 | 描述 | 复现 | 期望 | 截图/证据 |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | Major | F2 公共组件 | 10 个基础组件中 9 个没有任何页面引用，只有 `PageHeader` 在用；组件默认/按压/禁用状态无法验收 | `grep -rn "components/common/\(SectionCard\|Tag\|PrimaryButton\|EmptyState\|LoadingView\|Skeleton\|BottomSheet\|ConfirmDialog\|BackToTop\)" entry/src/main/ets/pages` 无结果；页面里的 `EmptyState()`/`Tag()` 是本地 Builder | 每个批次落地的组件至少被目标页面实际使用，或明确标注为“待接入”而非 DONE | `entry/src/main/ets/components/common/` |
| M2 | Major | F4 HttpClient | `putBinary` 无调用方，二进制 PUT 未验证；JSON 成功链路被 401 阻塞，F4 的“JSON/二进制/流式三类请求手工验证”未完成 | `grep -rn "putBinary" entry/src/main/ets` 只命中 `HttpClient.ets`；所有业务接口日志为 401 | 至少有一个可执行的二进制上传验证路径，并记录 JSON/二进制/流式三类结果 | `entry/src/main/ets/api/HttpClient.ets` |
| M3 | Major | F5 上传 | `UploadService` 零引用；发布页选图 `+` 无点击事件，资料头像、反馈选图、打印选文件均未接入 | 发布页点击两个 `+` 无反应；`grep -rn "UploadService" entry/src/main/ets` 只命中服务文件 | 三类场景实际唤起相册/文件选择器并产出 base64/ArrayBuffer；失败可重试 | `entry/src/main/ets/pages/CommunityPublish.ets`、`MeProfile.ets`、`MeFeedback.ets`、`ServicePrint.ets` |
| M4 | Major | F8 内容检查 | `CheckApi` 零引用，发布/资料保存未先检查；参考实现已在 `api/community.js`、`api/user.js` 接入 | `grep -rn "CheckApi" entry/src/main/ets` 只命中 `CheckApi.ets`；发布逻辑直接 `CommunityApi.publishText` | 发布、评论、资料/头像保存前调用 `/check/text`、`/check/img`，失败阻断并提示 | `entry/src/main/ets/api/CheckApi.ets`、`CommunityApi.ets` |
| M5 | Major | F9 分页 | `PagedList`/`ScrollToTop` 零引用；社区、评论、我的动态没有刷新/分页/到底提示/回到顶部 | 社区只调用一次 `recommend`；详情评论无 `lastCommentId`；页面无 `Refresh`/`onReachEnd`/`BackToTop` | 三处复用统一分页模式，游标正确、无重复漏项、到底有提示 | `entry/src/main/ets/services/PagedList.ets`、`pages/Community.ets`、`CommunityDetail.ets` |
| M6 | Major | F11 内容迁移 | 知识正文严重截断，用户可见页面在“代码实现：”后以孤立反斜杠结束；参考正文约 4468 字符，迁移仅约 662 字符 | 知识 Tab → 任意文章 → 连续上滑到底 | 正文与 `static/mock/knowledge/dynamic-programming.js` 逐字一致，代码块完整可渲染 | `docs/acceptance/screenshots/accept-knowledge-article-end.png`；`entry/src/main/ets/mock/KnowledgeMock.ets` |
| m1 | Minor | F7 助手 | AI 失败气泡追加在列表底部但不自动滚动到可见区域，用户发送后只看到自己的消息，需要手动上滑才能看到错误提示 | 助手输入“测试”发送，等待重试结束；截图无错误气泡，上滑后出现 | 新消息/错误态自动滚入视口 | `accept-helper-ai-error-before-scroll.png`、`accept-helper-ai-error-visible.png` |
| m2 | Minor | G6 社区降级 | 社区接口 401 时 `catch` 直接 `posts = []`，未使用 `CommunityMock.posts()`/缓存，演示数据丢失，只剩空态 | 启动后进入社区；日志 `recommend failed 登录状态已失效`，页面“暂无动态” | 失败时优先使用 Mock/缓存，至少保留可浏览的演示动态 | `accept-community-empty.png`；`pages/Community.ets` |
| m3 | Minor | F3 图片复用 | `NetImage` 的 `loadFailed` 在 `imageUrl` 变化时未重置；同一组件复用为另一 URL 时可能继续显示失败占位 | 静态审查；列表项 URL 变化/复用场景 | URL 变化时重置失败状态并重新加载 | `entry/src/main/ets/components/common/NetImage.ets` |

## 允许偏差

- 无登录页/无微信登录：沿用 demo token 决策，不作为缺陷。
- 无微信好友分享/朋友圈/订阅消息、无支付：平台与产品决策，不作为缺陷。
- 系统状态栏/字体渲染差异：不作为缺陷；本批未发现布局错位。
- `Service`、`ServiceExpress`、`ServiceSuccess`、`MeSetting` 保留为鸿蒙增强页：符合 AGENTS.md 决策，不作为死代码删除。
- 真实后端/AI 成功链路：受 token 401 与 DashScope 401 阻塞，相关项标 NOT TESTED，不判代码缺陷。

## 结论

**不通过**：Blocker 0 / Major 6 / Minor 3。

F2、F4、F5、F8、F9、F11 未达到本批完成标准；F6 的代码块/行内代码/链接与 F7 的真实逐字输出为 NOT TESTED。建议编码 agent 先提交当前工作区，再补齐组件接入、上传/检查/分页链路和知识正文，然后提交复验。复验只需覆盖上述缺陷及受影响页面。

## 复验（round 2，73dcef8）

- 复验日期：2026-11-11
- 分支：`feat/harmony-parity`
- 冻结点：`73dcef8d69c4a0a6cde1425f57aaea6e9cf57ded`
- 冻结状态：复验开始前 `git status --short` 为空；复验期间未修改源码、构建配置、`docs/parity-plan.md` 或 `env.ets`
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，型号 `emulator`，API 24
- 后端：生产 `https://api.hcyj.xyz`
- 安装包：`entry-default-unsigned.hap`，SHA-256 `f37e61eb2eca241a38fb1de81d05cfb5dc75c76f47f9210dcf6619145872f99d`，安装成功
- 参考实现：`../who_family_wechat` HEAD `47896e31150215b31e751e1f04427f7a56b53f99`，`git status --short` 为空

### 门槛与环境

| 项 | 结果 | 证据 / 备注 |
| --- | --- | --- |
| 构建 | PASS | `./scripts/preflight.sh`：`BUILD SUCCESSFUL`，HAP 存在 |
| CodeLinter | PASS | `Defects: 19; Errors: 0; Warns: 19; Suggestions: 0` |
| Web 图片残留 | PASS | 预检输出 `OK：无 Web 图片组件残留` |
| 路由 | PASS | `注册路由 30 个`，路由文件与注册表一致 |
| `DEMO_TOKEN` | 环境阻塞 | 启动后 `/user/userInfo?id=2`、社区、资料、检查、打印等请求均返回 HTTP 401；已按失败路径降级。真实成功链路无法验证 |
| `DASHSCOPE_API_KEY` | 环境阻塞 | DashScope 流式请求无内容，重试 2 次后出现错误气泡；真实逐字输出无法验证 |
| 模拟器媒体/文件 | 环境阻塞 | 相册无图片、文件选择器显示“没有文件”；选择器可打开，选中后的读取/预览/删除/上传无法验证 |

### 复验项

| ID | 结果 | 证据 |
| --- | --- | --- |
| M1 公共组件接入 | **PASS** | 旧 `components/EmptyState.ets`、`components/LoadingView.ets` 已删除。公共组件有真实 import 与调用：`EmptyState`（Community/JobList/Mine/CommunityDetail/Knowledge/MeOrder）、`LoadingView`（JobDetail）、`Skeleton`（Community/JobList/Mine/CommunityDetail/MeOrder）、`Tag`（Community/JobList/JobDetail）、`PrimaryButton`（CommunityPublish/MeProfile/MeFeedback/ServicePrint）、`ConfirmDialog`（CommunityDetail/MeAddress/MeSetting/ServicePrint）、`BackToTop`（Community/CommunityDetail/Mine/Knowledge）、`SectionCard`（Mine/Service/MeSetting）。`BottomSheet` 未接入，但确认场景由 `ConfirmDialog` 覆盖，按约定记录为偏差 |
| M2 二进制上传链路 | **PASS（401 链路；真实成功 NOT TESTED）** | `UploadService.uploadToUrl()` 调用 `HttpClient.putBinary`；`publishWithImages` 顺序为文本检查 → `prepare-post` → 图片检查 → PUT → `img-uploaded` → `finalize-post`。设置页自检实际打开相册，取消后用内置 PNG 发出 `PUT /community/img-uploaded`，日志为 `binary bytes=68`、`HTTP 401`，界面提示“HTTP 401（请求已发出）”。截图：`accept2-settings-upload-picker.png`、`accept2-settings-upload-401.png` |
| M3 选图/选文件 | **PASS（入口与限额）／选中后 NOT TESTED** | 发布相册选择器日志 `maxSelectCount=4`，界面“已选 0/4”；头像选择器 `maxSelectCount=1`；反馈选择器 `maxSelectCount=3`；打印文档选择器可打开并显示“没有文件”。预览/删除及文件名、大小展示在源码中存在。模拟器无媒体/文件，选中后的读取、预览、删除、base64 下单 NOT TESTED。截图：`accept2-publish-photo-picker.png`、`accept2-avatar-photo-picker.png`、`accept2-feedback-photo-picker.png`、`accept2-print-document-picker.png` |
| M4 内容检查 | **PASS（401 阻断；检查通过 NOT TESTED）** | 发布、评论、资料保存均先调用 `CheckApi`；头像保存走 `UserApi.updateAvatar` 的 `/check/img`。实测评论、发布、资料保存均先发出 `/check/text`，401 后阻止提交并提示，未新增本地评论或保存资料。日志分别见评论 `POST /check/text unauthorized`、发布 `POST /check/text unauthorized`、资料 `内容检查未授权（401）`。截图：`accept2-comment-check-blocked.png`、`accept2-publish-check-blocked.png`、`accept2-profile-check-blocked.png`。检查通过路径 NOT TESTED |
| M5 分页/刷新/回顶 | **FAIL** | `PagedListController`、`Refresh`、`onScrollEdge`、`BackToTop` 已接入社区、详情评论和我的动态；`lastPostId`/`lastCommentId` 参数确实拼入 API 请求；社区 401 Mock 降级后可浏览，底部显示“没有更多数据了”，回顶按钮实测可回到顶部。**但下拉刷新失效**：`Refresh({ refreshing: $$this.refreshing })` 在进入刷新态时先把 `refreshing` 置为 true，而三个页面的 `onRefresh()` 开头均 `if (this.refreshing) return`，导致首次刷新直接返回、请求不发出且指示器永久旋转。社区与详情均复现；三个页面源码模式相同。真实分页翻页 NOT TESTED（401）。截图：`accept2-community-fallback.png`、`accept2-community-bottom.png`、`accept2-community-top-after-backtotop.png`、`accept2-community-detail.png`、`accept2-community-refresh-drag.png`、`accept2-detail-refresh2.png` |
| M6 知识正文完整 | **PASS** | 临时脚本比对 `KnowledgeContent.ets` 与 `../who_family_wechat/static/mock/knowledge/dynamic-programming.js`：`refLength=4434`、`dpLength=4434`、`equal=true`；代码围栏各 12 个，反斜杠各 0 个。运行态文章标题/引用/列表/引用块/代码块和末尾“坚持刷题…”完整可见，无孤立反斜杠。详情加载强制使用当前 Mock，旧缓存不再覆盖正文。截图：`accept2-knowledge-article-top.png`、`accept2-knowledge-article-code.png`、`accept2-knowledge-article-end.png` |
| m1 助手自动滚底 | **PASS** | 发送 `scrolltest` 后，最新用户气泡与错误气泡“AI 服务暂不可用：AI 服务未返回内容，请稍后重试”自动进入当前视口，无需手动上滑。截图：`accept2-helper-error-autoscroll.png` |
| m2 社区 401 降级 | **PASS（附带 m4）** | 社区 401 日志后命中缓存失败并回退 `CommunityMock.posts()`，页面实际显示 4 条演示动态；下拉区/底部提示可见。社区卡片浏览量显示 `NaN`，另登记为 m4。截图：`accept2-community-fallback.png`、`accept2-community-bottom.png` |
| m3 NetImage URL 重置 | **NOT TESTED（静态未见缺陷）** | `NetImage` 已对 `imageUrl` 增加 `@Watch('onImageUrlChanged')` 并在 `aboutToReuse` 中重置 `loadFailed`；当前模拟器数据无法构造同一列表项 URL 变化或复用换图场景，运行态未验证。依据验收规则不判 PASS |

### 新缺陷

| 编号 | 级别 | 页面/任务 | 描述 | 复现 | 期望 | 截图/证据 |
| --- | --- | --- | --- | --- | --- | --- |
| M5 | Major | 社区/详情/我的动态刷新 | 下拉刷新被 `if (this.refreshing) return` 吞掉；`$$refreshing` 已由 Refresh 置 true，导致回调直接返回、请求不发、指示器不停 | 社区顶部下拉直至刷新指示器出现；等待超过 10 秒，无新的 `recommend-post` 请求，指示器仍在。详情页同样复现 | 下拉后发出刷新请求，完成后复位 `refreshing` | `accept2-community-refresh-drag.png`、`accept2-detail-refresh2.png`；`pages/Community.ets:79`、`CommunityDetail.ets:106`、`Mine.ets:108` |
| m4 | Minor | 社区降级列表 | Mock 动态 ID 为 `post-1` 等非数字字符串，`Number(post.id) % 191` 得到 `NaN`，卡片浏览量显示 `NaN` | 401 降级进入社区列表，任意 Mock 动态底部眼睛图标后显示 `NaN` | 显示可读的浏览量或回退为 0/固定演示值 | `accept2-community-fallback.png`、`accept2-community-bottom.png`；`pages/Community.ets:130-134` |

### 允许偏差与未测项

- `BottomSheet` 本轮未接入；评论删除、地址删除、清缓存、打印确认均由 `ConfirmDialog` 覆盖，按修复说明记录为允许偏差。
- 真实上传成功、内容检查通过、后端分页翻页、AI 逐字输出：受 401/无效 key 阻塞，标记 NOT TESTED，不判代码缺陷；已验证到请求与失败处理链路。
- 相册/文件选择后的读取、预览、删除、上传与 base64 下单：模拟器无媒体/文件，NOT TESTED。
- NetImage 列表复用/URL 变化：无法构造运行态场景，NOT TESTED。
- 未重新执行完整 P2 页面视觉矩阵，仅复验本轮缺陷及直接受影响页面。

### 结论

**不通过：Blocker 0 / Major 1 / Minor 1。**

M1、M2、M3、M4、M6、m1、m2 在可验证范围内通过；M5 因三处下拉刷新被状态守卫吞掉而未达到完成标准；m3 运行态 NOT TESTED。下一步应先修复 M5 的刷新入口与 `try/finally` 复位逻辑，并修复 Mock 浏览量的 `NaN`，随后只复验这两项及受影响页面。

## 复验（round 3，95e34a4）

- 复验日期：2026-11-11
- 分支：`feat/harmony-parity`
- 冻结点：`95e34a4e38370050a8b81fe5d88dc02206955085`
- 冻结状态：复验开始前 `git status --short` 为空；复验期间未修改 `entry/`、构建配置、`docs/parity-plan.md` 或 `env.ets`，仅写入本报告与 `docs/acceptance/screenshots/`
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，型号 `emulator`，API 24
- 后端：生产 `https://api.hcyj.xyz`
- 安装包：`entry-default-unsigned.hap`，SHA-256 `1fd75a24d189ed02bdb8ef7d63ec2c950fbea7fdc0d686de0fd28f198c39e983d`，覆盖安装成功并重启 `EntryAbility`
- 复验范围：仅 round 2 遗留的 M5、m4；token/key 401 环境阻塞与本次两项无关，沿用既有结论，不展开

### 门槛

| 项 | 结果 | 证据 / 备注 |
| --- | --- | --- |
| 冻结点与工作区 | PASS | `git rev-parse HEAD` 为 `95e34a4e38370050a8b81fe5d88dc02206955085`；开始前 `git status --short` 为空 |
| 构建 | PASS | `./scripts/preflight.sh`：`BUILD SUCCESSFUL`，HAP 存在 |
| CodeLinter | PASS | `Defects: 19; Errors: 0; Warns: 19; Suggestions: 0` |
| 安装与启动 | PASS | `hdc install -r` 返回 `install bundle successfully`；`EntryAbility` 处于 `FOREGROUND` |

### 复验项

| ID | 结果 | 证据 |
| --- | --- | --- |
| M5 下拉刷新 | **PASS** | 三处 `onRefresh()` 均已移除 `if (this.refreshing) return`，并在 `try/finally` 中复位 `refreshing`：`Community.ets:79-89`、`CommunityDetail.ets:106-116`、`Mine.ets:108-117`。社区下拉拖动时捕获到刷新指示器（`accept3-community-refresh-indicator.png`），释放后日志出现 `GET /community/recommend-post`，HTTP 401 后走 Mock，完成后指示器消失且 4 条动态仍在（`accept3-community-refresh-done.png`）。详情下拉捕获到指示器（`accept3-detail-pull-indicator.png`），释放后日志出现 `GET /community/post-comment?id=post-1`，401 后保留默认评论，完成后指示器消失（`accept3-detail-refresh-done.png`）。我的下拉捕获到指示器（`accept3-mine-pull-indicator.png`），释放后依次发出 `/user/userInfo?id=2`、`/community/self-post`、`/checkin/todos`、`/checkin/focus/today`，均 401 降级；完成后指示器消失，页面内容正常、无白屏或崩溃（`accept3-mine-refresh-done.png`）。401 下“我的”无自有动态缓存，显示既有空态，属数据缺失而非刷新失效 |
| m4 Mock 浏览量 | **PASS** | `Community.ets:132-142` 已改为对 `post.id`（为空时用标题）逐字符做 `seed = (seed * 31 + charCode) % 100000` 的稳定哈希，返回 `10 + seed % 191`，不再使用 `Number(post.id)`，结果范围固定为 10–200。运行态 4 条 Mock 动态浏览量依次为 `122/123/124/125`（`accept3-community-mock.png`、`accept3-community-scroll1.png`、`accept3-community-scroll2.png`），独立脚本按同一算法计算 `post-1` 至 `post-4` 得到一致结果 `122/123/124/125`；刷新后首条仍为 `122`，前后均未出现 `NaN` |

### 新缺陷

无。Blocker 0 / Major 0 / Minor 0。

### 未测项

- 本轮只定点复验 M5、m4，未重跑完整 P2 页面矩阵；round 2 的 m3 运行态仍为 NOT TESTED，不因本轮通过而改变。
- 真实后端成功链路、AI 逐字输出、媒体选中后上传仍受既有 401/无效 key/模拟器媒体限制，未在本轮展开。

### 结论

**通过：Blocker 0 / Major 0 / Minor 0。**

M5 已关闭：社区、详情、我的三处下拉均出现刷新反馈、实际触发请求并在失败降级后复位。m4 已关闭：非数字 ID 的 Mock 浏览量使用稳定哈希，运行态与脚本结果均为 10–200 内的数字，无 `NaN`。本轮两项均 PASS。

## 页面验收（P2.1–P2.4，340e8a3）

- 验收日期：2026-11-11
- 分支：`feat/harmony-parity`
- 冻结点：`340e8a320434880c85a5cd8d985408a97debcbc0`
- 冻结状态：开始验收时 `git status --short` 为空；验收期间未修改 `entry/`、构建配置、`docs/parity-plan.md` 或 `env.ets`
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，API 24
- 后端：生产 `https://api.hcyj.xyz`；演示 token 有效，真实接口可访问
- 安装包：`entry-default-unsigned.hap`，SHA-256 `9b01918ff50ece11ae21b26ce22497da9093a2903dfc8b32708857ffafc64e48`
- 参考实现：`../who_family_wechat`，HEAD `47896e31150215b31e751e1f04427f7a56b53f99`，工作区干净
- 范围：仅 P2.1 首页、P2.2 社区列表、P2.3 社区详情、P2.4 发布动态；未验收 P2.5 及后续页面

### 门槛与冻结

| 项 | 结果 | 证据 |
| --- | --- | --- |
| 冻结点 | PASS | `git rev-parse HEAD` 为 `340e8a320434880c85a5cd8d985408a97debcbc0` |
| 工作区 | PASS | 开始前 `git status --short` 为空 |
| 构建 | PASS | `./scripts/preflight.sh`：`BUILD SUCCESSFUL`，HAP 存在 |
| CodeLinter | PASS | `Errors: 0 / Warns: 19` |
| 路由表 | PASS | `preflight` 检查 30 条路由 |
| Web 图片残留 | PASS | `preflight` 检查 Web 图片引用为 0；网络图片使用 `Image/NetImage` |
| 安装与启动 | PASS | `hdc install -r` 成功；`EntryAbility` 为 `FOREGROUND`，无启动崩溃或白屏 |

### 环境更新与数据说明

| 项 | 本轮结论 | 证据 |
| --- | --- | --- |
| S3 图片证书 | **PASS，原环境阻塞已解除** | MinIO 证书续签后，未使用 `-k` 直连签名图片 GET：HTTP 200、`ssl_verify_result=0`、`324702` bytes；应用内社区列表与详情实图均正常显示。此前“真实图片只能显示占位”的结论不再适用于本轮 |
| DashScope | **NOT TESTED（真实流式）** | 无有效 key；仅验证错误面板、原文保留、重试、关闭。真实逐字润色/应用建议未测，按既有允许偏差处理，不计代码缺陷 |
| 模拟器相册 | **NOT TESTED（选中后链路）** | 系统图片选择器可打开，显示“已选 0/4”，相册为空；选图、预览、删除、图片检查、上传、带图发布均未测 |
| 生产测试数据 | 记录，不计代码缺陷 | 动态 id `194`、`195` 标题含“自测”；本轮未修改或删除这两条动态 |

### 页面结果汇总

| 页面 | 结果 | 缺陷 | 未测项 |
| --- | --- | --- | --- |
| P2.1 首页 | **PASS（核心链路）** | 无 | 构造断网/空数据后的首页失败态、空态未单独复测；加载态已观察 |
| P2.2 社区列表 | **PASS（Minor 1）** | D-P2-02 | 断网/强制空列表状态未单独构造 |
| P2.3 社区详情 | **PASS（核心链路）** | 无 | `lastCommentId` 评论分页 NOT TESTED（无 ≥10 条评论的现成动态，且本轮不构造大数据） |
| P2.4 发布动态 | **FAIL** | D-P2-01 | 图片选择后链路 NOT TESTED（相册空）；AI 真实流式 NOT TESTED（无有效 key） |

### P2.1 首页

**结果：PASS（核心链路）。** 截图：`accept-p2-home-default.png`、`accept-p2-home-banner-swiped.png`、`accept-p2-home-services-scrolled.png`、`accept-p2-home-recruitment.png`、`accept-p2-home-jobs.png`。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 区块顺序与文案 | PASS | 问候/日期 → 轮播 → 推荐服务 → 校园动态 → 推荐岗位，与参考 `pages/home/index.vue` 及 `components/home/*` 的结构一致 |
| 真实用户 | PASS | 显示真实用户名 `zeroiceyaaaa` 和真实问候/日期，非 Mock 用户 |
| 轮播 | PASS | 轮播图、标题/副标题、页码点可见；左右滑动后第二张与指示点同步变化 |
| 服务入口 | PASS | `校园人流天气`→`ServicePersonInfo`、`课表`→`ServiceSchedule`、`成绩`→`ServiceGrade`、`打印`→`ServicePrint`、`更多服务`→`Service`，逐项点击验证 |
| 校园动态 | PASS | 动态条数、等级标签、标题、摘要、发布人、相对时间/已读数与参考字段一致 |
| 推荐岗位 | PASS | 真实岗位数据展示；岗位卡进入 `JobDetail`，“查看更多”进入 `JobList` |
| 加载/空/失败态 | 部分 NOT TESTED | 冷启动加载态可见且无白屏；本轮未单独构造断网、空岗位或空动态场景，空态/失败态标 NOT TESTED |
| 视觉与滚动 | PASS | 浅灰背景、绿色强调色、服务卡横向滚动与参考一致；连续滚动无白块、崩溃或明显掉帧。右侧第二张服务卡仅露出部分是横向滚动设计，与参考 `scroll-x` 一致，非缺陷 |
| 返回与安全区 | PASS | 首页作为 Tab 正常显示，子页 PageHeader 返回可用；状态栏、底部安全区无遮挡 |

### P2.2 社区列表

**结果：PASS（核心链路，登记 Minor 1）。** 截图：`accept-p2-community-default.png`、`accept-p2-community-scroll1.png`、`accept-p2-community-scroll2.png`、`accept-p2-community-like.png`、`accept-p2-community-like-top.png`、`accept-p2-community-page2.png`、`accept-p2-community-end.png`、`accept-p2-community-no-more.png`、`accept-p2-community-end-check.png`、`accept-p2-community-refreshing.png`、`accept-p2-community-refresh-done.png`、`accept-p2-community-errand.png`、`accept-p2-community-secondhand.png`、`accept-p2-community-rating.png`、`accept-p2-community-images-default.png`、`accept-p2-community-images-loaded.png`、`accept-p2-community-images-live.png`。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 顶层 Tab | PASS | 固定四项“动态 / 跑腿 / 二手 / 评分”，图标大小、选中色、下划线切换与参考一致 |
| 分类内容 | PASS | 动态展示真实推荐动态；跑腿展示类型、地点、价格、状态；二手/评分按参考显示“开发中...”占位 |
| 卡片结构 | PASS | 作者头像/品牌标签、用户名、相对时间、关注、正文、1/2/3/4 图网格、浏览量/评论数/点赞数与参考结构一致 |
| 真实数据与图片 | PASS | `GET /community/recommend-post` HTTP 200；证书续签后实图可见，1/2/3/4 图布局均验证；截图 `accept-p2-community-images-loaded.png`、`accept-p2-community-images-live.png` |
| 点赞 | PASS | 点击后服务端 `POST /community/like-post` HTTP 200，计数 0→1，图标与总数同步；失败回滚源码存在 |
| 关注 | PASS | 点击后本地按钮状态切换；取消关注有确认逻辑，未发现布局或状态异常 |
| 下拉刷新 | PASS | 下拉出现刷新指示器，释放后发出 `/community/recommend-post`，完成后指示器消失、列表保持可用 |
| 分页 | PASS（功能翻页）/ FAIL（末页文案，Minor） | 首屏 20 条；后续 `lastPostId=136→87→29→2` 均 HTTP 200，最终返回 0 条且停止再请求，无重复/漏项；但末页仍显示“上拉加载更多”，见 D-P2-02 |
| 回到顶部 | PASS | 滚动超过阈值出现上箭头，点击回到首条，按钮随后隐藏 |
| 返回与稳定性 | PASS | 进入详情再返回后计数同步；连续滚动和分页过程中无崩溃、白屏或明显掉帧 |
| 空/失败态 | NOT TESTED | 本轮使用有效 token，未单独构造 401/断网/空列表；失败降级和空态仅由源码确认 |

### P2.3 社区详情

**结果：PASS（核心链路；评论分页 NOT TESTED）。** 截图：`accept-p2-detail-default.png`、`accept-p2-detail-comment-typed.png`、`accept-p2-detail-comment-sent.png`、`accept-p2-detail-maxlength.png`、`accept-p2-detail-reply-sent.png`、`accept-p2-detail-replies-loaded.png`、`accept-p2-detail-delete-confirm.png`、`accept-p2-detail-reply-delete-confirm.png`、`accept-p2-detail-reply-deleted.png`、`accept-p2-detail-comment-deleted.png`、`accept-p2-detail-refreshing.png`、`accept-p2-detail-two-images.png`、`accept-p2-detail-two-images-loaded.png`、`accept-p2-detail-image-preview.png`。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 作者/标题/正文/统计 | PASS | 真实动态详情展示作者、品牌标签、时间、标题、正文、浏览量/点赞/评论统计；与参考 `PostAuthorInfo`、`PostContent` 结构一致 |
| 图片网格 | PASS | 两图并排、单图比例、点击预览与关闭均正常；S3 实图正常加载 |
| 一级评论 | PASS | 空态“暂无评论”可见；输入、`/check/text` 通过、发送、服务端返回 id、列表更新均成功 |
| 二级回复 | PASS | 点击回复出现目标条“回复 我: 验收评论测试”；发送后回复节点与计数更新；“查看回复/加载更多回复”结构可见 |
| 字数限制 | PASS | 评论框 `maxLength=200`；输入 205 字被截断为 200 字，超出部分不可输入 |
| 内容检查 | PASS | 评论和回复发送前均调用 `POST /check/text`，HTTP 200 后才写入；检查失败提示路径由源码确认 |
| 删除确认/删除 | PASS | 一级评论与回复均先弹确认框，确认后调用 DELETE HTTP 200，节点和计数同步移除；取消不会删除 |
| 返回列表同步 | PASS | 详情点赞、评论变化写入共享状态；返回社区后对应卡片计数同步 |
| 评论点赞 | 一致，不计缺陷 | 参考 `CommentItem.vue` 无评论点赞入口；鸿蒙版未新增，按“参考没有即不实现”处理 |
| 评论分页 | NOT TESTED | 只有首屏满 10 条才显示“加载更多评论”（`CommunityDetail.ets:116-126`）；现有测试动态最多 5 条评论，未构造 ≥10 条评论，`lastCommentId` 运行态未测 |
| 下拉刷新/返回 | PASS | 下拉出现刷新指示并完成；PageHeader 返回可用；测试期间无崩溃、白屏 |

### P2.4 发布动态

**结果：FAIL（Major 1）。** 截图：`accept-p2-publish-default.png`、`accept-p2-publish-empty-validation.png`、`accept-p2-publish-title-only-validation.png`、`accept-p2-publish-filled.png`、`accept-p2-publish-categories.png`、`accept-p2-publish-categories-live.png`、`accept-p2-publish-ai-error-top.png`、`accept-p2-publish-ai-error.png`、`accept-p2-publish-photo-picker.png`、`accept-p2-publish-success.png`。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 页面结构 | PASS | 图片上传区、标题+发布按钮、分类胶囊、正文、AI 润色按钮的区块与参考一致 |
| 分类来自 `postTypes` | **FAIL** | `GET /community/postTypes` HTTP 200，返回“好物推荐 / 日常分享 / 求助问答 / 活动召集”，但页面连续两次仍显示旧兜底“评分 / 好物推荐 / 跑腿 / 二手”；见 D-P2-01 |
| 必填/长度校验 | PASS | 空标题提示“请输入标题”；仅标题提示“请输入内容”；标题 `maxLength=99`、正文 `maxLength=10000`，源码同时保留超限提示 |
| 纯文字发布 | PASS（使用有效分类） | 选择“好物推荐”后 `/check/text` 200 → `prepare-post` 200 → `finalize-post` 200，社区刷新并将新动态置于首位；创建 id `196` |
| 发布失败处理 | 可复现 | 选择页面显示的旧分类“跑腿”后 `/check/text` 200、`prepare-post` HTTP 500，界面提示“发布失败，请重试”；未生成动态 |
| 发布后刷新 | PASS | 成功后触发 `communityRefreshAt`，返回社区第一页可见“验收动态-页面测试”首位展示 |
| AI 润色错误路径 | PASS（仅错误路径） | 无有效 key 时显示“AI 服务暂不可用：AI 服务未返回内容，请稍后重试”；原文保留；重试再次请求；关闭面板不覆盖标题/正文。真实逐字输出、应用/撤回建议 NOT TESTED |
| 图片选择/预览/删除 | NOT TESTED | 系统选择器可打开并显示“已选 0/4”；模拟器相册为空，选中后的预览、删除、检查、PUT 上传、带图发布未测。该未测原因是相册为空，不是 S3 证书 |
| 防重复提交 | PASS（源码+运行态） | `publishing` 在请求前置位，发布按钮 `loading`；运行态未出现重复动态 |
| 返回与安全区 | PASS | PageHeader 返回社区；键盘/输入区无遮挡，状态栏与底部安全区正常 |

### 缺陷

#### D-P2-01（Major，P2.4 发布分类回退且可导致发布 500）

- 复现：有效 token，进入 `+` 发布页；等待 `GET /community/postTypes` HTTP 200。接口返回 `好物推荐 / 日常分享 / 求助问答 / 活动召集`，页面仍显示 `评分 / 好物推荐 / 跑腿 / 二手`；两次独立进入均复现。
- 实际：选择一个页面可见但不在后端当前分类中的“跑腿”，填写标题和正文后，`/check/text` 200，`POST /community/prepare-post` HTTP 500，Toast“发布失败，请重试”；改选“好物推荐”后可正常发布。
- 期望：分类胶囊在任何时刻都反映后端 `postTypes` 返回值；可选择项均应能正常发布。兜底数据仅可用于接口失败，不能覆盖已成功的响应。
- 证据：[`accept-p2-publish-categories-live.png`](acceptance/screenshots/accept-p2-publish-categories-live.png)、[`accept-p2-publish-categories.png`](acceptance/screenshots/accept-p2-publish-categories.png)。相关实现：`entry/src/main/ets/pages/CommunityPublish.ets:28`、`:53-75`、`:309-334`。
- 影响：用户按页面提供的分类操作会直接发布失败，属核心发布功能严重不符；Page 结果 FAIL。

#### D-P2-02（Minor，P2.2 社区末页仍显示“上拉加载更多”）

- 复现：社区动态连续上拉翻页，最后一次 `lastPostId=2` 返回 0 条后，页面底部仍显示“上拉加载更多”；继续上拉不再发请求。
- 实际：末页提示与“无更多数据”状态不一致，易误导用户继续等待/刷新。
- 期望：无更多数据时显示“没有更多数据了”，并停止触发加载。
- 证据：[`accept-p2-community-end-check.png`](acceptance/screenshots/accept-p2-community-end-check.png)、[`accept-p2-community-no-more.png`](acceptance/screenshots/accept-p2-community-no-more.png)。相关实现：`entry/src/main/ets/pages/Community.ets:97-100`、`:541-578`、`:709-713`，`entry/src/main/ets/services/PagedList.ets:104-112`。
- 影响：不影响已加载内容，但到底状态提示错误；按 Minor 登记。

### 测试数据与清理

- 未修改/删除生产动态 `194`、`195`；其“自测”标题按已知测试数据记录，不计代码缺陷。
- 为验证纯文字发布真实链路，新建 1 条动态：id **`196`**，标题 `验收动态-页面测试`，正文 `验收动态内容，仅用于功能验证。`；请在验收结束后清理。
- 评论/回复验收产生的临时评论 id `88`、回复 id `26` 已在现场删除，动态计数恢复；未保留评论测试数据。

### 结论

**不通过：Blocker 0 / Major 1 / Minor 1。**

P2.1 首页核心链路 PASS；P2.2 社区列表核心链路 PASS（到底文案 Minor）；P2.3 详情核心链路 PASS（评论分页 NOT TESTED）；P2.4 发布页因分类未反映成功接口且可导致 `prepare-post` 500，判 FAIL。S3 证书续签后真实图片加载 PASS，不再是环境阻塞。AI 真实流式、图片选中后上传、评论分页仍为 NOT TESTED，分别受有效 key、空相册、无 ≥10 条评论数据限制。

## 页面验收复验（P2.1–P2.4，18da44a）

- 复验日期：2026-11-11
- 分支：`feat/harmony-parity`
- 冻结点：`18da44ade2846b4ce43062e192dfcb1ec7edf676`
- 冻结状态：开始复验时 `git status --short` 为空；复验期间未修改 `entry/`、构建配置、`docs/parity-plan.md` 或 `env.ets`，仅写入本报告与 `docs/acceptance/screenshots/`
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，型号 `emulator`，API 24
- 后端：生产 `https://api.hcyj.xyz`；演示 token 有效，真实用户、社区分页、点赞、发布链路均返回成功
- 安装包：`entry-default-unsigned.hap`，SHA-256 `2f8b6ac9e100b9b52fc28c4c0be49932d8120afe0e557345fd949b5bb2f05e36`，覆盖安装成功并冷启动验证
- 参考实现：`../who_family_wechat`，HEAD `47896e31150215b31e751e1f04427f7a56b53f99`，工作区干净
- 复验范围：仅上轮遗留的 D-P2-01、D-P2-02，以及受影响的 P2.2 四 Tab/点赞/刷新和 P2.4 分类/校验/返回回归

### 门槛

| 项 | 结果 | 证据 / 备注 |
| --- | --- | --- |
| 冻结点与工作区 | PASS | `git rev-parse HEAD` 为 `18da44ade2846b4ce43062e192dfcb1ec7edf676`；开始前 `git status --short` 为空 |
| 构建 | PASS | `./scripts/preflight.sh`：`BUILD SUCCESSFUL`，HAP 存在 |
| CodeLinter | PASS | `Defects: 19; Errors: 0; Warns: 19; Suggestions: 0` |
| 路由与图片组件 | PASS | `preflight`：注册路由 30 个，Web 图片引用为 0 |
| 安装与启动 | PASS | `hdc install -r` 成功；冷启动 `EntryAbility` 前台运行，无崩溃或白屏 |
| 参考实现完整性 | PASS | `../who_family_wechat` 工作区干净，未修改 |

### 定点复验

| ID | 结果 | 证据摘要 |
| --- | --- | --- |
| D-P2-01 发布分类回退 | **PASS（已关闭）** | `postTypes` 200 后页面显示后端四个分类；逐项点击选中态正确；选择“日常分享”纯文字发布成功；新建动态位列社区首位 |
| D-P2-02 社区末页提示 | **FAIL（未关闭）** | 冷启动连续翻至最后一页，`lastPostId=26` 返回 14 条后底部仍显示“上拉加载更多”；切 Tab 触发重渲染后才变为“没有更多数据了” |

#### D-P2-01（PASS）

| 检查项 | 结果 | 运行态证据 |
| --- | --- | --- |
| 后端分类替换旧兜底 | PASS | `GET /community/postTypes` HTTP 200；页面显示“好物推荐 / 日常分享 / 求助问答 / 活动召集”，旧“跑腿 / 二手 / 评分”均不再出现。见 [`accept-p2-fix-publish-categories.png`](acceptance/screenshots/accept-p2-fix-publish-categories.png) |
| 加载期间禁止误选旧分类 | PASS（源码 + 初始态） | 初始 `postTypes=[]`、`selectedType=''`、`typesLoading=true`，此时仅渲染“分类加载中...”，不渲染可点击分类；分类点击仅在加载完成后出现。分类接口本次约 21ms 返回，布局抓取时已加载完成，因此未截到加载窗口。相关实现：`entry/src/main/ets/pages/CommunityPublish.ets:28-30`、`:54-75`、`:232-245`、`:327-345` |
| 逐个分类选中态 | PASS | 依次点击四个分类，均只有当前项背景为 `#FF00CC6A`，其余为 `#FFF4F6F8`；最终选中“日常分享”。见 [`accept-p2-fix-publish-filled.png`](acceptance/screenshots/accept-p2-fix-publish-filled.png) |
| 有效分类纯文字发布 | PASS | `POST /check/text` 200 → `POST /community/prepare-post` 200（`type=日常分享`）→ `POST /community/finalize-post` 200（`id=197`）；未再出现 500 |
| 发布后社区首位刷新 | PASS | 返回社区后自动重新拉取第一页，标题正文为本次测试内容的动态位于首位。见 [`accept-p2-fix-publish-after2.png`](acceptance/screenshots/accept-p2-fix-publish-after2.png) |
| AI 错误面板 | PASS（仅错误路径） | 无可用 key 时显示“AI 服务暂不可用：AI 服务未返回内容，请稍后重试”；标题与正文保留。真实润色输出仍按允许偏差 NOT TESTED。见 [`accept-p2-fix-publish-ai-error.png`](acceptance/screenshots/accept-p2-fix-publish-ai-error.png) |
| 必填校验与返回 | PASS | 空标题点击发布提示“请输入标题”，且未发出 `check/text`、`prepare-post`、`finalize-post`；PageHeader 返回社区正常。见 [`accept-p2-fix-publish-validate.png`](acceptance/screenshots/accept-p2-fix-publish-validate.png) |

#### D-P2-02（FAIL）

- 复现：冷启动进入社区，动态列表从第一页连续上拉到底。日志依次为 `lastPostId=112` 返回 20 条、`lastPostId=85` 返回 20 条、`lastPostId=26` 返回 14 条；此后继续上拉不再发请求，内容停在末条，但底部持续显示“上拉加载更多”。
- 实际：最后一页 14 条已渲染，底部文案仍为“上拉加载更多”；持续滚动约 35 秒、70 次上拉后仍未变化。见 [`accept-p2-fix-community-end-stale.png`](acceptance/screenshots/accept-p2-fix-community-end-stale.png)。
- 对照：切换至“跑腿”再切回“动态”，重新滚到底后显示“没有更多数据了”。说明分页数据与 `hasMore` 已更新，但首次到底时底部文案未随 `pager.hasMore` 变更刷新。
- 相关实现：`entry/src/main/ets/pages/Community.ets:46` 为非 `@State` 的 `private pager`，`:99-101` 在 `loadMore()` 后只回写 `posts`，`:573` 直接读取 `this.pager.footerText()`；`entry/src/main/ets/services/PagedList.ets:104-112` 的 `hasMore` 已为 false。建议将到底提示改为直接依赖可观察状态，但验收阶段未修改代码。
- 影响：不影响已加载内容，但到底状态仍会误导用户；D-P2-02 维持 Minor，未关闭。
- 我的动态：PASS。进入“我的”滚动自有动态到底，底部显示“没有更多数据了”；当前账号自有动态不足 20 条，走同一 `hasMore=false` 初始加载分支。见 [`accept-p2-fix-mine-end.png`](acceptance/screenshots/accept-p2-fix-mine-end.png)。

### 回归

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| P2.2 四 Tab | PASS | “动态”显示真实动态；“跑腿”显示真实跑腿任务；“二手”“评分”分别显示参考实现中的开发中占位。见 [`accept-p2-fix-community-dynamic.png`](acceptance/screenshots/accept-p2-fix-community-dynamic.png)、[`accept-p2-fix-community-errand.png`](acceptance/screenshots/accept-p2-fix-community-errand.png)、[`accept-p2-fix-community-secondhand.png`](acceptance/screenshots/accept-p2-fix-community-secondhand.png)、[`accept-p2-fix-community-rating.png`](acceptance/screenshots/accept-p2-fix-community-rating.png) |
| 点赞 | PASS | 对动态 `197` 点赞与取消：计数 `25 → 26 → 25`，两次 `POST /community/like-post` 均 200，最终恢复原状态。见 [`accept-p2-fix-community-like.png`](acceptance/screenshots/accept-p2-fix-community-like.png) |
| 下拉刷新 | PASS | 顶部下拉发出 `GET /community/recommend-post` 并 200，第一页内容保留、无白屏。见 [`accept-p2-fix-community-refresh-done.png`](acceptance/screenshots/accept-p2-fix-community-refresh-done.png) |
| P2.4 分类/校验/返回 | PASS | 四分类逐项可选；“日常分享”发布成功；空标题校验与返回社区均正常 |
| P2.1 首页 / P2.3 详情 | 未重跑 | 本轮仅做定点复验与受影响页面回归；上轮首页/详情结论不变 |

### 测试数据

- 本轮仅新建 1 条动态：id **`197`**，标题 `复验-发布分类修复-2240`，分类“日常分享”，正文 `这是一条用于P2.1验收的纯文字动态，发布后记录ID，验证prepare-post与finalize-post。`；无删除动态接口，请验收结束后人工清理。
- 点赞已现场取消，计数恢复为 `0`；未新增评论、回复或其他测试动态。

### 结论

**不通过（定点复验）：Blocker 0 / Major 0 / Minor 1。**

D-P2-01 已通过并关闭：发布页稳定显示后端四个有效分类，加载期间不暴露旧分类，逐项选中正常，使用“日常分享”完成了真实的 `check/text → prepare-post → finalize-post` 发布链路，新动态位于社区首位。D-P2-02 未通过：社区自然滚到最后一页仍显示“上拉加载更多”，仅在切 Tab 触发重渲染后恢复正确文案。AI 真实润色、图片选中后上传仍按既有环境限制标 NOT TESTED，不计缺陷。

## 页面验收复验 2（P2.1–P2.4，4704e2a）

- 复验日期：2026-11-11
- 分支：`feat/harmony-parity`
- 冻结点：`4704e2aa2b28459badad522e7e0e4211577dc112`
- 冻结状态：开始复验时 `git status --short` 为空；复验期间未修改 `entry/`、构建配置、`docs/parity-plan.md` 或 `env.ets`，仅写入本报告与 `docs/acceptance/screenshots/`
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，API 24
- 后端：生产 `https://api.hcyj.xyz`；日志均为 `token=present`，分页、点赞请求返回 200
- 安装包：`entry-default-unsigned.hap`，覆盖安装成功并冷启动验证
- 复验范围：仅上轮遗留的 D-P2-02，以及其修复涉及的社区/我的动态 footer 与四 Tab、点赞、详情回归

### 门槛

| 项 | 结果 | 证据 / 备注 |
| --- | --- | --- |
| 冻结点与工作区 | PASS | `git rev-parse HEAD` 为 `4704e2aa2b28459badad522e7e0e4211577dc112`；开始前 `git status --short` 为空 |
| 构建 | PASS | `./scripts/preflight.sh`：`BUILD SUCCESSFUL`，HAP 存在 |
| CodeLinter | PASS | `Defects: 19; Errors: 0; Warns: 19`，无 error；warning 全部位于 `AppIcon`/`MiniProgramCards`/`common/*`/`ServiceSchedule`，与本次改动文件无关 |
| 路由与图片组件 | PASS | `preflight`：注册路由 30 个，Web 图片引用为 0 |
| 安装与启动 | PASS | `hdc install -r` 成功；`aa force-stop` 后冷启动，进程前台运行，无崩溃或白屏 |
| 参考实现完整性 | PASS | 未读取或修改 `../who_family_wechat` |

### 定点复验

| ID | 结果 | 证据摘要 |
| --- | --- | --- |
| D-P2-02 社区末页提示 | **PASS（已关闭）** | 冷启动进入社区后连续翻到最后一页，最后一批数据返回后底部**立即**显示“没有更多数据了”，全程未切 Tab；继续上拉 6 次文案保持不变且不再发请求；下拉刷新后分页从第一页重新开始，再次到底仍显示“没有更多数据了” |
| D-P2-02 我的动态末页 | PASS | “我的”页滚到自有动态末尾，底部显示“没有更多数据了” |

#### D-P2-02（PASS）

| 检查项 | 结果 | 运行态证据 |
| --- | --- | --- |
| 冷启动末页立即更新 | PASS | 冷启动后仅点击一次“社区”入口，未切换 Tab。请求依次为 `lastPostId=111` → 20 条、`lastPostId=84` → 20 条、`lastPostId=25` → 13 条；13 条返回后首次抓取布局即读到“没有更多数据了”。见 [`accept-p2-fix2-community-end.png`](acceptance/screenshots/accept-p2-fix2-community-end.png) |
| 继续上拉保持正确 | PASS | 到底后继续上拉 6 次，布局持续为“没有更多数据了”；应用日志最后一条分页请求仍停在末页，未再发出 `recommend-post`。见 [`accept-p2-fix2-community-end-repeat.png`](acceptance/screenshots/accept-p2-fix2-community-end-repeat.png) |
| 下拉刷新后状态恢复 | PASS | 在顶部下拉触发 `GET /community/recommend-post`（无 cursor）返回 20 条；随后翻页重新从 `lastPostId=111`、`84`、`25` 拉取，说明 `hasMore` 已复位并继续分页，未被上轮的“没有更多数据了”卡死；再次到底显示“没有更多数据了”。见 [`accept-p2-fix2-community-refresh.png`](acceptance/screenshots/accept-p2-fix2-community-refresh.png) |
| 我的动态末页 | PASS | “我的”页滚到末尾，底部显示“没有更多数据了”。见 [`accept-p2-fix2-mine-end.png`](acceptance/screenshots/accept-p2-fix2-mine-end.png) |

说明：

- 本轮末页为 `lastPostId=25` 返回 13 条（上轮为 `lastPostId=26` 返回 14 条），差额对应提交说明中已清理的测试动态 `197`；末页条数小于 20 的判定路径一致。
- 页面 footer 是列表唯一尾部节点，`Scroll.onScrollEdge(Edge.Bottom)` 会在到达页 1 边界时立即触发下一页，因此“上拉加载更多”只存在于请求返回前的瞬时态，未截到静态帧；刷新后分页能从页 1 继续（日志中的 `lastPostId=111` 请求）证明该状态下 `hasMore=true`，不存在残留“没有更多数据了”。

### 回归

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| 四 Tab | PASS | “跑腿”显示真实跑腿任务；“二手”“评分”显示参考实现中的开发中占位；“动态”恢复真实动态。见 [`accept-p2-fix2-tab-errand.png`](acceptance/screenshots/accept-p2-fix2-tab-errand.png)、[`accept-p2-fix2-tab-secondhand.png`](acceptance/screenshots/accept-p2-fix2-tab-secondhand.png)、[`accept-p2-fix2-tab-rating.png`](acceptance/screenshots/accept-p2-fix2-tab-rating.png)、[`accept-p2-fix2-tab-dynamic.png`](acceptance/screenshots/accept-p2-fix2-tab-dynamic.png) |
| 点赞 | PASS | 对动态 `177` 点赞/取消：计数 `1 → 2 → 1`，两次 `POST /community/like-post` 均 200，最终恢复原状态。见 [`accept-p2-fix2-like.png`](acceptance/screenshots/accept-p2-fix2-like.png) |
| 进入详情/返回 | PASS | 点击动态进入“动态详情”，正文与空评论态正常；点 PageHeader 返回后社区列表与点赞计数保持。见 [`accept-p2-fix2-detail.png`](acceptance/screenshots/accept-p2-fix2-detail.png) |
| S3 图片 | PASS | 末页与刷新后首屏图片均正常解码显示，无占位/破图 |
| token | PASS | 全部请求 `token=present`，未出现 401 或 Mock 降级 |

### 测试数据

- 点赞已现场取消，动态 `177` 计数恢复为 `1`。
- 未新建/删除动态、评论或回复；未操作生产测试数据。

### 结论

**通过：Blocker 0 / Major 0 / Minor 0。**

D-P2-02 已关闭：社区冷启动翻到末页后底部文案即时变为“没有更多数据了”，继续上拉保持稳定；下拉刷新后分页正确复位并可从第一页继续加载，末尾状态仍正确；我的动态末页表现一致。四 Tab、点赞、详情进入/返回回归均通过。AI 真实流式与图片上传仍受既有环境限制，不在本轮范围。

## 页面验收（P2.5–P2.9，795d2ac）

- 验收日期：2026-11-11–2026-11-12
- 分支：`feat/harmony-parity`
- 冻结点：`795d2acda874b754747268ab6f23c4ab2f242fee`
- 冻结状态：开始前 `git status --short` 为空；验收期间未修改 `entry/`、构建配置、`docs/parity-plan.md` 或 `env.ets`
- 设备：鸿蒙模拟器 `127.0.0.1:5555`，API 24，分辨率 1320×2856；应用已安装并运行，无启动崩溃
- 后端：生产 `https://api.hcyj.xyz`；演示 token 有效，招聘与知识真实数据可访问
- 安装包：`entry-default-unsigned.hap`，SHA-256 `6825e1c03417a51478e88bce9122666b9fb3e3a3d6b28890323558ef523e6fac`
- 参考实现：`../who_family_wechat`，HEAD `47896e31150215b31e751e1f04427f7a56b53f99`，工作区干净
- 范围：仅 P2.5 招聘列表、P2.6 招聘详情、P2.7 助手、P2.8 知识列表、P2.9 知识详情；未验收 P2.10 及后续页面

### 门槛与冻结

| 项 | 结果 | 证据 |
| --- | --- | --- |
| 冻结点 | PASS | `git rev-parse HEAD` 为 `795d2acda874b754747268ab6f23c4ab2f242fee` |
| 工作区 | PASS | 开始前 `git status --short` 为空 |
| 构建 | PASS | `./scripts/preflight.sh`：`BUILD SUCCESSFUL`，HAP 存在 |
| CodeLinter | PASS | `Defects: 19; Errors: 0; Warns: 19; Suggestions: 0`，无 error |
| 路由表 | PASS | `preflight` 检查 30 条注册路由，路由文件与注册表一致 |
| Web 图片残留 | PASS | `preflight` 检查 Web 图片组件为 0；网络图使用 ArkUI `Image`/`NetImage` |
| 仓库卫生 | PASS | `preflight` 未发现未跟踪密钥、签名或构建产物 |
| 参考实现完整性 | PASS | `../who_family_wechat` HEAD 固定且工作区干净，未修改 |

### 页面结果汇总

| 页面 | 结果 | 缺陷/偏差 | 未测项 |
| --- | --- | --- | --- |
| P2.5 招聘列表 | **PASS（核心链路）** | P2B-01 | 后端分页、下拉刷新请求、加载/全量空/失败降级未取得可靠运行态证据 |
| P2.6 招聘详情 | **PASS** | 无 | 投递行为按红线 NOT TESTED |
| P2.7 助手 | **PASS（核心链路）** | P2B-02 | AI 真实逐字输出、富 Markdown 历史消息 NOT TESTED |
| P2.8 知识列表 | **PASS** | P2B-03 | 无 |
| P2.9 知识详情 | **PASS（核心链路）** | P2B-04 | AI 真实解读输出 NOT TESTED |

### P2.5 招聘列表

**结果：PASS（核心链路，登记 Minor 偏差 1）。** 截图：[`默认态`](acceptance/screenshots/accept-p2b-joblist-default.png)、[`分类空态`](acceptance/screenshots/accept-p2b-joblist-type-intern.png)、[`到底`](acceptance/screenshots/accept-p2b-joblist-bottom2.png)。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 分类栏与筛选 | PASS（偏差见 P2B-01） | 显示“所有 / 已收藏 / 实习招聘 / 志愿者招募 / 校招”等横向分类；逐项切换选中态正确；“实习招聘”无数据时显示“暂无相关岗位 / 换个分类看看吧”。见 [`accept-p2b-joblist-default.png`](acceptance/screenshots/accept-p2b-joblist-default.png)、[`accept-p2b-joblist-type-intern.png`](acceptance/screenshots/accept-p2b-joblist-type-intern.png) |
| 真实接口与卡片 | PASS | `GET /hire/job-types`、`GET /hire/recommend-jobs` 均 HTTP 200；当前 4 个真实岗位，卡片含 logo、岗位名、单位、活动招募/热门/推荐标签、地点、描述、招募人数、已申请人数、截止日期与申请/已投递状态。字段与 `components/recruit/RecruitCard.vue` 对齐 |
| 进入详情 | PASS | 点击岗位卡进入“招聘详情”，岗位标题与所选卡片一致，PageHeader 返回列表正常 |
| 收藏状态同步 | PASS | 招聘详情初始为已收藏；取消收藏后返回列表状态已更新，再收藏恢复；最终恢复为原始“已收藏”，未留下测试状态。见 [`accept-p2b-jobdetail-uncollected.png`](acceptance/screenshots/accept-p2b-jobdetail-uncollected.png)、[`accept-p2b-jobdetail-restored.png`](acceptance/screenshots/accept-p2b-jobdetail-restored.png) |
| 到底提示 | PASS | 全部 4 条岗位后显示“没有更多数据了”，继续上拉不再请求。见 [`accept-p2b-joblist-bottom2.png`](acceptance/screenshots/accept-p2b-joblist-bottom2.png) |
| 回到顶部 | PASS | 列表滚动后浮动回顶按钮出现，点击后回到首卡顶部。见 [`accept-p2b-joblist-backtotop.png`](acceptance/screenshots/accept-p2b-joblist-backtotop.png) |
| 加载/空/失败态 | 部分 NOT TESTED | 分类空态 PASS；冷启动加载态、全量空态、断网/无效 token 降级与“重试”横幅未取得可靠静态证据，仅做源码走查，不据此判 PASS |
| 分页与下拉刷新 | NOT TESTED | 后端当前仅返回 4 条，不足以触发 `lastId` 下一页；下拉刷新指示器与刷新请求未截到可靠帧，未将 `refreshing/refresh-done` 截图作为通过证据 |
| 视觉、滚动、返回与安全区 | PASS | PageHeader、状态栏、底部安全区正常；长描述不溢出，连续滚动无白屏、崩溃或明显卡顿 |

### P2.6 招聘详情

**结果：PASS。** 截图：[`默认态`](acceptance/screenshots/accept-p2b-jobdetail-default.png)、[`下半部`](acceptance/screenshots/accept-p2b-jobdetail-lower.png)。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 基础信息 | PASS | 公司 logo/名称、岗位名、推荐/活动招募/热门标签、地点、薪资、岗位职责与公司信息完整 |
| 职责/要求/福利 | PASS | 职责、任职要求、福利待遇分区渲染，换行正常，未出现占位或压缩正文 |
| 招聘信息 | PASS | 招募人数、投递人数、截止时间、发布时间字段齐全；本次后端截止时间为空，页面保留字段但不显示日期，属数据缺失而非字段缺失。见 [`accept-p2b-jobdetail-lower.png`](acceptance/screenshots/accept-p2b-jobdetail-lower.png) |
| 联系方式与标签 | PASS | 手机号按接口返回值脱敏显示；标签、发布时间与详情字段一致 |
| 收藏 | PASS | 点击底部“已收藏”后变为“收藏”，Toast“取消收藏”；再次点击恢复“已收藏”，返回列表同步；最终恢复原状态 |
| 底部操作栏 | PASS | 收藏按钮与申请/已投递状态按钮固定在底部安全区上方，不遮挡正文；已投递状态为禁用外观 |
| 返回 | PASS | PageHeader 返回招聘列表，滚动位置和收藏状态同步，无黑屏/白屏 |
| 投递行为 | **NOT TESTED** | 按红线不发起 `POST /hire/submit`，不写生产投递记录；确认框、状态回传与请求参数仅代码走查，不据此判运行态通过 |

### P2.7 助手

**结果：PASS（核心链路，登记 Minor 偏差 1）。** 截图：[`默认态`](acceptance/screenshots/accept-p2b-helper-default.png)、[`ActionSheet`](acceptance/screenshots/accept-p2b-helper-actionsheet.png)、[`等待态`](acceptance/screenshots/accept-p2b-helper-waiting.png)、[`错误态`](acceptance/screenshots/accept-p2b-helper-error.png)、[`重试错误`](acceptance/screenshots/accept-p2b-helper-retry-error.png)、[`历史恢复`](acceptance/screenshots/accept-p2b-helper-history-restored.png)。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 预设问题 | PASS（配色偏差见 P2B-02） | 首次进入显示欢迎语与 2×3 预设问题卡，图标/标题/摘要/箭头齐全；点击预设问题直接发送，发送后预设区隐藏。见 [`accept-p2b-helper-default.png`](acceptance/screenshots/accept-p2b-helper-default.png) |
| 输入与键盘 | PASS | 输入框可输入，键盘弹起时输入区/发送按钮保持可见；收起后布局恢复。见 [`accept-p2b-helper-keyboard.png`](acceptance/screenshots/accept-p2b-helper-keyboard.png) |
| 发送与等待态 | PASS | 发送后立即出现右侧用户气泡；左侧显示“答答Novus智能校园助手”、头像与等待/加载指示，无重复发送 |
| 错误气泡 | PASS | 无效 DashScope key 下显示“⚠️ AI 服务暂不可用：AI 服务未返回内容，请稍后重试”，用户消息和欢迎原文均保留；无崩溃/白屏。见 [`accept-p2b-helper-error.png`](acceptance/screenshots/accept-p2b-helper-error.png) |
| 重试 | PASS | 点击“重试”再次进入等待态并返回错误，不会重复插入用户消息；重试期间历史内容保持。见 [`accept-p2b-helper-retry-error.png`](acceptance/screenshots/accept-p2b-helper-retry-error.png) |
| 复制 | PASS（有限验证） | 长按 AI/用户消息打开菜单并选择复制，出现“已复制”Toast。模拟器无剪贴板查看工具，未回读剪贴板内容核对 |
| ActionSheet/清空 | PASS | 顶部菜单打开 ActionSheet；选择清空后二次确认，确认后清空会话并恢复欢迎语和预设问题。见 [`accept-p2b-helper-actionsheet.png`](acceptance/screenshots/accept-p2b-helper-actionsheet.png)、[`accept-p2b-helper-clear-confirm.png`](acceptance/screenshots/accept-p2b-helper-clear-confirm.png) |
| 历史恢复 | PASS | 发送并产生错误气泡后强制结束应用再冷启动，欢迎语、用户消息与错误气泡恢复，输入区正常。见 [`accept-p2b-helper-history-restored.png`](acceptance/screenshots/accept-p2b-helper-history-restored.png) |
| 自动滚底 | PASS | 发送、等待、错误与重试后列表滚至最新消息，输入区不被遮挡；清空后回到顶部显示完整欢迎语 |
| Markdown 渲染 | 部分 NOT TESTED | 欢迎语列表与错误文案正常；因无有效 AI key，未能生成含标题/粗体/链接/代码块的富 Markdown 历史消息，相关渲染未测 |
| AI 真实逐字输出 | **NOT TESTED** | `DASHSCOPE_API_KEY` 无效；仅验证错误态、重试、原文保留、清空与历史恢复。按 `docs/tech-notes.md` 的约定不计代码缺陷 |

### P2.8 知识列表

**结果：PASS。** 截图：[`默认态`](acceptance/screenshots/accept-p2b-knowledge-default.png)、[`算法分类`](acceptance/screenshots/accept-p2b-knowledge-algorithm.png)、[`分类末尾`](acceptance/screenshots/accept-p2b-knowledge-tabs-end.png)、[`空分类`](acceptance/screenshots/accept-p2b-knowledge-empty.png)、[`到底`](acceptance/screenshots/accept-p2b-knowledge-list-bottom.png)。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 分类与数据量 | PASS | 15 个分类横向滚动可达；分类切换选中态正确；28 篇文章与参考 `static/mock/knowledge/index.js` 数量一致 |
| 推荐标识与卡片 | PASS | 推荐红标、难度标、标题、摘要、主题标签、作者、日期、阅读时长/字数、浏览量、点赞数齐全；布局与参考卡片层级一致。见 [`accept-p2b-knowledge-default.png`](acceptance/screenshots/accept-p2b-knowledge-default.png) |
| 搜索/排序 | PASS（以参考为准） | 参考 `pages/knowledge/index.vue` 未提供搜索或排序入口，本页未新增，不判缺失 |
| 空分类 | PASS | 当前无文章分类显示“暂无知识内容 / 换个分类看看吧”，底部 Tab 保持可用。见 [`accept-p2b-knowledge-empty.png`](acceptance/screenshots/accept-p2b-knowledge-empty.png) |
| 进入详情 | PASS | 点击文章进入“知识详情”，标题、作者、难度、日期与列表一致；PageHeader 返回列表正常 |
| 点赞数同步 | PASS（行为偏差见 P2B-04） | 详情点赞后返回列表，对应文章点赞数同步 +1；再次取消后恢复；列表滚动/回顶正常。见 [`accept-p2b-knowledge-list-restored.png`](acceptance/screenshots/accept-p2b-knowledge-list-restored.png)、[`accept-p2b-knowledge-list-backtotop.png`](acceptance/screenshots/accept-p2b-knowledge-list-backtotop.png) |
| 视觉、滚动与安全区 | PASS | 分类胶囊横向滚动，长列表滚动到底显示完整末尾卡片；无白屏、崩溃或明显掉帧。作者头像首字色块差异见 P2B-03 |

### P2.9 知识详情

**结果：PASS（核心链路，登记 Minor 行为偏差 1）。** 截图：[`顶部`](acceptance/screenshots/accept-p2b-knowledge-article-default.png)、[`中部`](acceptance/screenshots/accept-p2b-knowledge-article-mid.png)、[`代码块/下半部`](acceptance/screenshots/accept-p2b-knowledge-article-lower.png)、[`到底`](acceptance/screenshots/accept-p2b-knowledge-article-liked-bottom.png)、[`AI 错误`](acceptance/screenshots/accept-p2b-knowledge-ai-error.png)。

| 检查项 | 结果 | 证据 |
| --- | --- | --- |
| 完整正文 | PASS | 动态规划正文非 3 句占位；标题、引用、段落、粗体、有序/无序列表、提示框与“推荐练习顺序”完整可读，内容与参考 Markdown 一致 |
| 代码块 | PASS | 多个代码块使用深色背景、等宽字体与横向内容布局，未被截断为纯文本；长代码可随页面滚动查看 |
| 到底提示 | PASS | 连续滚动到底显示“坚持刷题，你一定能掌握动态规划！ 🚀”，无空白尾屏或重复内容。见 [`accept-p2b-knowledge-article-liked-bottom.png`](acceptance/screenshots/accept-p2b-knowledge-article-liked-bottom.png) |
| 点赞/收藏 | PASS（参考行为偏差见 P2B-04） | 浮动红心从 `🤍` 切为 `❤️`，点赞数 `567 → 568`，Toast“收藏成功”；取消后 `568 → 567`；返回列表计数同步；重启后收藏状态与计数可恢复。最终已恢复原状态。见 [`accept-p2b-knowledge-article-liked-persisted.png`](acceptance/screenshots/accept-p2b-knowledge-article-liked-persisted.png)、[`accept-p2b-knowledge-article-restored.png`](acceptance/screenshots/accept-p2b-knowledge-article-restored.png) |
| AI 解读面板 | PASS（仅错误路径） | 点击绿色 AI 浮动按钮显示“AI 智能解读”面板与加载态；无效 key 时显示“AI 服务暂不可用：AI 服务未返回内容，请稍后重试”，正文仍保留；“重新解读”可重试，关闭恢复页面。见 [`accept-p2b-knowledge-ai-error.png`](acceptance/screenshots/accept-p2b-knowledge-ai-error.png)、[`accept-p2b-knowledge-ai-retry-error.png`](acceptance/screenshots/accept-p2b-knowledge-ai-retry-error.png) |
| 目录/滚动 | PASS（以参考为准） | 参考文章页无 TOC，本页未新增，不判缺失；顶部无横向溢出，正文滚动条与底部浮动按钮不互相遮挡 |
| AI 真实解读输出 | **NOT TESTED** | 无效 `DASHSCOPE_API_KEY` 导致无法产生真实输出；加载/错误/重试/关闭链路已验证，按既有环境限制不计缺陷 |
| 返回与安全区 | PASS | PageHeader 返回知识列表，点赞数与收藏状态同步；状态栏、底部安全区及浮动按钮未被系统手势区遮挡 |

### 通用检查

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| PageHeader/返回 | PASS | 招聘列表/详情、知识列表/详情均有 PageHeader 返回；助手为 Tab 页，使用与小程序的菜单式标题栏；逐页返回无黑屏或错误 Tab |
| 状态栏/安全区 | PASS | 五个页面状态栏内容可读，底部导航/操作栏/输入区未被系统手势条遮挡 |
| 无死链 | PASS | 本批页面卡片、分类、收藏、AI、菜单、返回等可点元素均有响应；未发现无响应按钮 |
| 无白屏/崩溃 | PASS | 页面进入、滚动、返回、重启恢复期间应用保持前台，无崩溃或空白页 |
| 列表滚动 | PASS | 招聘、知识及助手消息列表连续滚动正常；回顶/到底行为可用 |
| 生产数据红线 | PASS | 未发起招聘投递；未发布动态/评论；未删除生产内容 |

### 缺陷与偏差

#### P2B-01（Minor，P2.5 招聘分类栏与当前参考渲染不一致）

- 参考：`../who_family_wechat/pages/recruit/index.vue:4` 中 `CategoryTabs` 被注释，当前小程序页面不渲染分类栏。
- 实际：鸿蒙 `entry/src/main/ets/pages/JobList.ets:247` 定义、`:522` 渲染分类栏；功能正常，包含所有/已收藏/后端岗位类型。
- 判定：`docs/parity-plan.md:110` 明确要求启用分类栏，因此这是任务清单主动偏差，但确实改变参考页布局。按 Minor 登记，建议负责人确认“以任务清单为准”或改为在验收时将该项列为允许偏差；验收阶段未修改代码。
- 证据：[`accept-p2b-joblist-default.png`](acceptance/screenshots/accept-p2b-joblist-default.png)。

#### P2B-02（Minor，P2.7 预设问题卡配色与参考不一致）

- 参考：`../who_family_wechat/components/helper/PresetQuestions.vue:76-105` 使用四组渐变彩色卡片，按奇偶/3n/4n 着色。
- 实际：`entry/src/main/ets/pages/Helper.ets:343-391` 结构与交互一致，但所有卡片统一为白底、灰字，缺少参考的多彩渐变视觉。
- 期望：卡片结构不变的前提下恢复多色渐变或登记为可接受的视觉偏差。属 Minor 视觉差异，不影响点击与发送。
- 证据：[`accept-p2b-helper-default.png`](acceptance/screenshots/accept-p2b-helper-default.png)。

#### P2B-03（Minor，P2.8/P2.9 知识作者头像与参考不一致）

- 参考：`../who_family_wechat/utils/randomData.js:2` 使用 `api.dicebear.com/7.x/pixel-art/svg?seed=<name>` 生成像素头像；列表与详情均加载该网络图。
- 实际：`entry/src/main/ets/pages/Knowledge.ets:176` 与 `KnowledgeArticle.ets:192` 使用作者首字 + 固定蓝色圆底色块。视觉可读、无破图，但与参考头像风格明显不同。
- 判定：首字色块可接受，但按“允许偏差必须登记”的原则登记为 Minor；若负责人将“避免第三方外链”列为设计决策，可转为允许偏差。验收阶段未修改代码。
- 证据：[`accept-p2b-knowledge-default.png`](acceptance/screenshots/accept-p2b-knowledge-default.png)、[`accept-p2b-knowledge-article-default.png`](acceptance/screenshots/accept-p2b-knowledge-article-default.png)。

#### P2B-04（Minor，P2.9 知识点赞会改计数并持久化，参考仅本地图标切换）

- 参考：`../who_family_wechat/pages/knowledge/article.vue:147-153` 的 `toggleLike` 只切换 `isLiked` 并显示 Toast，不修改 `likes`、不写入本地存储；本页计数始终为基础值。
- 实际：`entry/src/main/ets/pages/KnowledgeArticle.ets:88` 在已点赞时返回 `article.likes + 1`；`:91-103` 写入 `knowledgeLikedIds` 并通过 `knowledgeLikedDelta` 通知列表；`Knowledge.ets:27-56` 启动时与返回时同步计数，跨重启保持。运行态为 `567 → 568 → 567`，已恢复。
- 判定：这是比参考更完整的持久化收藏/点赞体验，但改变了参考的计数与持久化语义，按未登记行为偏差登记为 Minor。建议负责人确认是否将“点赞数 +1 且持久化”列为主动增强；验收阶段未修改代码。
- 证据：[`accept-p2b-knowledge-article-liked-bottom.png`](acceptance/screenshots/accept-p2b-knowledge-article-liked-bottom.png)、[`accept-p2b-knowledge-article-liked-persisted.png`](acceptance/screenshots/accept-p2b-knowledge-article-liked-persisted.png)、[`accept-p2b-knowledge-list-restored.png`](acceptance/screenshots/accept-p2b-knowledge-list-restored.png)。

### 环境限制与 NOT TESTED 汇总

| 项目 | 状态 | 原因与处理 |
| --- | --- | --- |
| AI 真实逐字输出/知识解读 | NOT TESTED | `DASHSCOPE_API_KEY` 无效，实际返回“AI 服务未返回内容”；已验证错误气泡、原文保留、自动滚底、重试、历史恢复与关闭。按 `docs/tech-notes.md:82-88` 不计代码缺陷 |
| 招聘投递 | NOT TESTED | `POST /hire/submit` 会写生产投递记录，按任务红线未发起；仅代码走查确认入口与状态回传 |
| 招聘后端分页 | NOT TESTED | `/hire/recommend-jobs` 当前仅 4 条，未达到触发 `lastId` 的阈值；到底文案已验证 |
| 招聘下拉刷新/失败降级 | NOT TESTED | 未取得可靠刷新指示器/请求证据；有效 token 与网络稳定时未构造接口失败，失败重试与服务降级不作运行态结论 |
| 招聘加载/全量空态 | 部分 NOT TESTED | 分类空态已实测；冷启动骨架与全量空态未取得可靠截图 |
| 助手富 Markdown 历史 | NOT TESTED | 无有效 AI key，无法产生含代码块/标题/链接的 AI 回复；欢迎语列表与错误文案已正常显示 |
| 剪贴板内容 | NOT TESTED | 复制按钮有“已复制”Toast；模拟器无剪贴板读取工具，未逐字核对剪贴板内容 |

### 测试数据与清理

- 招聘收藏：初始为已收藏；测试中取消并恢复，最终保持原始已收藏状态。
- 知识点赞：`567 → 568 → 567`；持久化状态重新验证后恢复，最终列表/详情回到原始计数。
- 助手会话：测试产生的用户消息与错误气泡已清空，恢复欢迎语与预设问题。
- 招聘投递：未发起，未写入任何投递记录。
- 动态/评论：未创建、修改或删除任何生产动态、评论或回复。
- 设备网络：测试期间曾关闭 WLAN 验证网络页/降级入口，随后已恢复联网；应用最终停在首页前台运行。

### 结论

**通过：Blocker 0 / Major 0 / Minor 4。**

P2.5–P2.9 五个页面的核心链路均可进入、可返回、可滚动，真实招聘与知识数据正常展示，收藏/点赞测试后已恢复，未产生招聘投递等生产副作用。分类栏、助手预设问题配色、知识作者头像、知识点赞持久化四项为已登记的 Minor 偏差，其中分类栏与点赞持久化更接近任务清单的主动增强而非阻断缺陷，建议负责人确认后转为允许偏差。AI 真实逐字输出与知识 AI 解读受无效 DashScope key 限制，招聘投递、后端分页与部分异常态按明确红线或数据条件标为 NOT TESTED；这些均不构成本轮代码缺陷。

---

## 页面验收复验（P2.5–P2.9，ad84970）

**复验范围**：仅复验 P2B-01–P2B-04 四项 Minor 修复及其回归，不重新展开 P2.5–P2.9 全量验收。
**冻结点**：`ad84970`（`git rev-parse HEAD` 一致），复验开始时 `git status --short` 为空，分支 `feat/harmony-parity`。
**环境**：HarmonyOS 模拟器 `127.0.0.1:5555`（1320×2856）。`./scripts/preflight.sh` 通过：`BUILD SUCCESSFUL`；CodeLinter `Errors: 0 / Warns: 19`（均为既有性能建议，较文档基线 14 条多 5 条，无 error，不构成验收失败）。
**参考实现**：`../who_family_wechat`（只读）。

### P2B-01 招聘分类栏 —— PASS

- 代码：`entry/src/main/ets/pages/JobList.ets:522` 已移除 `this.CategoryTabs()` 调用，仅保留注释说明；`build()` 为 `PageHeader` → `Refresh/Scroll` → 岗位列表，分类栏组件定义（`:247`）不再被引用。
- 参考：`../who_family_wechat/pages/recruit/index.vue:3-4` 的 `CategoryTabs` 处于注释状态，页面只渲染招聘列表。
- 运行：招聘页首屏只有标题栏与岗位卡，无分类/筛选栏；列表滚动正常。见 [`accept-p2b-fix-joblist.png`](acceptance/screenshots/accept-p2b-fix-joblist.png)。
- 回归：点击岗位可进入详情，职位描述/任职要求/底部收藏与投递状态正常。见 [`accept-p2b-fix-jobdetail.png`](acceptance/screenshots/accept-p2b-fix-jobdetail.png)。

### P2B-02 助手预设问题渐变 —— PASS

- 代码：`entry/src/main/ets/pages/Helper.ets:359` 为每个问题传入索引，`:385` 应用 `.linearGradient(this.presetGradient(index))`，`:404-421` 按 `index % 6` 返回参考的 6 组 135° 渐变色；摘要与箭头颜色同步改为参考的 `#666666`。
- 参考：`../who_family_wechat/components/PresetQuestions.vue` 的卡片渐变依次为紫 `#e8d5ff→#d4b8ff`、粉 `#ffd6e8→#ffc2e2`、蓝 `#d4ecff→#b8ddff`、绿 `#d4ffe8→#b8ffd4`、橙 `#ffe8d4→#ffd4b8`、黄 `#fff5d4→#ffeab8`。当前固定 6 条问题，参考 `nth-child` 级联的最终颜色与 `index % 6` 一一对应。
- 运行：2×3 预设问题卡按紫/粉/蓝/绿/橙/黄顺序显示，渐变与文字可读，点击可发送。见 [`accept-p2b-fix-helper-presets.png`](acceptance/screenshots/accept-p2b-fix-helper-presets.png)。
- 回归：发送后错误气泡、原文保留、重试入口正常；清空会话后恢复欢迎语与 6 张预设卡。见 [`accept-p2b-fix-helper-error.png`](acceptance/screenshots/accept-p2b-fix-helper-error.png)、[`accept-p2b-fix-helper-restored.png`](acceptance/screenshots/accept-p2b-fix-helper-restored.png)。

### P2B-03 知识作者 Dicebear 头像 —— PASS

- 代码：`entry/src/main/ets/pages/Knowledge.ets:30` 与 `KnowledgeArticle.ets:70` 统一生成 `https://api.dicebear.com/7.x/pixel-art/png?seed=<encodeURIComponent(author)>`；列表 `Knowledge.ets:141`、详情 `KnowledgeArticle.ets:180` 均改用 `NetImage`（ArkUI `Image`）并做圆形裁剪。
- 参考：`../who_family_wechat/utils/randomData.js:1-3` 使用 Dicebear 7.x `pixel-art` + 作者名 seed；`knowledge/index.vue` 与 `knowledge/article.vue` 均加载该头像。本实现同 provider、同风格、同 seed，返回格式为 PNG（本轮任务要求，ArkUI `Image` 可直接加载），视觉等价。
- 运行：列表全部卡片与详情页作者头像均为 Dicebear 像素头像，无首字色块、无破图。见 [`accept-p2b-fix-knowledge-list-avatars.png`](acceptance/screenshots/accept-p2b-fix-knowledge-list-avatars.png)、[`accept-p2b-fix-knowledge-article.png`](acceptance/screenshots/accept-p2b-fix-knowledge-article.png)。
- 失败占位：`components/common/NetImage.ets` 在 URL 为空或 `onError` 时置 `loadFailed` 并渲染灰底“图”占位，列表/详情外层 `Stack` 另有 `clip(true)`；本轮未实机断网触发失败态，按代码路径确认。

### P2B-04 知识点赞仅本地切换 —— PASS

- 代码：`KnowledgeArticle.ets:46` 进入详情固定 `isLiked = false`；`:84-86` 计数只返回 `article.likes`；`:88-91` `toggleLike()` 仅切换 `isLiked` + Toast，无 `CacheStore`/`AppStorage` 写入。全仓检索 `knowledgeLikedIds` / `knowledgeLikedDelta` 已无引用；列表 key 不再依赖点赞状态。
- 参考：`../who_family_wechat/pages/knowledge/article.vue:147-153` 仅切换 `isLiked` 并 Toast，计数始终为 `article.likes`。
- 运行：详情计数 `342` → 点击后红心 + “收藏成功” Toast，计数仍 `342`；返回列表仍 `342`；强制结束并冷启动后重新进入，恢复白心且计数仍 `342`。见 [`accept-p2b-fix-knowledge-liked.png`](acceptance/screenshots/accept-p2b-fix-knowledge-liked.png)、[`accept-p2b-fix-knowledge-list-after-like.png`](acceptance/screenshots/accept-p2b-fix-knowledge-list-after-like.png)、[`accept-p2b-fix-knowledge-relaunch.png`](acceptance/screenshots/accept-p2b-fix-knowledge-relaunch.png)、[`accept-p2b-fix-knowledge-liked-cleared.png`](acceptance/screenshots/accept-p2b-fix-knowledge-liked-cleared.png)。

### 回归检查

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| 招聘列表/详情 | PASS | 列表无分类栏、岗位卡与滚动正常；详情字段、底部操作正常。见 [`accept-p2b-fix-joblist.png`](acceptance/screenshots/accept-p2b-fix-joblist.png)、[`accept-p2b-fix-jobdetail.png`](acceptance/screenshots/accept-p2b-fix-jobdetail.png) |
| 助手错误态 | PASS | 无效 DashScope key 下错误气泡、重试、原文保留正常；清空后恢复欢迎态。见 [`accept-p2b-fix-helper-error.png`](acceptance/screenshots/accept-p2b-fix-helper-error.png) |
| 知识分类 | PASS | 切换到“算法”分类后列表与选中态正确，作者头像正常。见 [`accept-p2b-fix-knowledge-category.png`](acceptance/screenshots/accept-p2b-fix-knowledge-category.png) |
| 知识正文/代码块 | PASS | 标题、引用、列表、代码块（语言标签/等宽/灰底）与后续段落渲染正常。见 [`accept-p2b-fix-knowledge-codeblock.png`](acceptance/screenshots/accept-p2b-fix-knowledge-codeblock.png) |

### 范围外观察（不计缺陷）

- `P2B-02` 参考卡片另有阴影、右上角径向装饰与右下角半透明圆形箭头底纹，当前实现仍是纯渐变 + “›”文本；本轮 Minor 仅要求补渐变，沿用上轮视觉结论，建议后续统一打磨。
- 参考预设问题使用 `nth-child` 级联，理论上第 8 条会命中 `4n` 绿色；当前问题数固定 6 条，`index % 6` 与参考完全一致，暂无运行影响。
- `k-1` 详情标题为“Vue3 响应式原理”，正文仍为动态规划占位内容；上一轮已验证同样现象，属 `AGENTS.md` 第 7.8 条登记的内容迁移遗留，不是本轮回归。

### 数据清理

- 知识点赞：始终 `342`，未落盘；冷启动后为未点赞。
- 助手会话：测试消息与错误气泡已清空，恢复欢迎语与预设问题。
- 招聘：未发起投递；收藏状态保持测试前原样（已收藏）。
- 未创建、修改或删除任何生产动态、评论或回复。

### 结论

**通过：Blocker 0 / Major 0 / Minor 0（本轮范围）。**

P2B-01–P2B-04 四项 Minor 均已关闭，招聘、助手、知识三条回归链路正常。构建通过、CodeLinter 0 error；无新增 Functional/Behavioral 偏差。

---

## 最终验收 P2.10–P2.29（2026-11-12）

- 提交：`11cdeaea8bc5e8c612fe0e3e3c832f807dc49dbb`（`feat/harmony-parity`）
- 参考实现：`../who_family_wechat`，提交 `47896e31150215b31e751e1f04427f7a56b53f99`，工作区干净（`git status --porcelain` 为空）
- 日期：2026-11-12
- 设备/模拟器：`127.0.0.1:5555`，`emulator`，API 24，系统 `6.1.0.117(SP37DEVC00E115R4P11)`
- 后端环境：生产 `https://api.hcyj.xyz`
- 安装包：`entry/build/default/outputs/default/entry-default-unsigned.hap`，SHA-256 `3f43f7a76a5c035ea964c254d600e450e81839e876661672cb0199b9b420f5a2`
- 构建结果：`hvigorw clean` 后执行 `./scripts/build.sh`，`BUILD SUCCESSFUL in 4s 887ms`
- CodeLinter：`./scripts/lint.sh`，**0 error / 18 warning**（新增 `ServicePersonInfo.ets:55` Date 复用提示）
- 安装说明：首次检查发现模拟器仍装 01:23 旧包；12:19 clean 重建并重装后复测，12:32 再次 clean 构建、重装最终 HAP 后重复关键失败用例。以下结论以重装后的包为准。

### 全局门槛

| ID | 结果 | 证据 / 备注 |
| --- | --- | --- |
| G1 构建 | PASS | clean 后 `assembleHap` 成功，HAP 存在；最终 HAP 已 `hdc install -r` 成功 |
| G2 静态检查 | PASS | `Defects: 18; Errors: 0; Warns: 18; Suggestions: 0` |
| G3 仓库卫生 | PASS | `git ls-files` 无 `env.ets`、签名、`.hvigor/`、`build/`、`oh_modules/`；本轮只新增报告与截图 |
| G4 参考实现完整性 | PASS | 参考仓库 HEAD `47896e3`，工作区干净，未修改 |
| G5 路由完整 | PASS（静态 30/30）/ NOT TESTED（全量运行 P4） | `main_pages.json` 30 条；30 个页面文件均存在且均有 `@Entry`；按 `router.pushUrl/replaceUrl`、Tab 宿主与动态 `route` 构造路由图，30/30 从 `pages/Index` 可达，所有目标均在路由表内 |
| G6 演示数据链路 | PASS（正常接口）/ 降级未重跑 | 生产 token 可读取首页、订单等真实数据；本轮未重复制造 401/断网场景 |
| G7 密钥安全 | PASS | 报告与本轮日志未记录 token、API key、JWT、签名材料；未读取或回显 `env.ets` 值 |
| G8 截图证据 | PASS（本批次，P2.21 运行态缺失） | P2.10–P2.29 关键页与关键状态均已截图或引用既有截图；P2.21 因未写生产订单，无真实成功页截图；未覆盖全部 30 页默认态 |

### 页面结果

| 页面 / 任务 | 结果 | 已验证项 | 缺陷 | 截图 |
| --- | --- | --- | --- | --- |
| P2.10 我的 `Mine` | PASS | 资料头、快捷导航 5 项、任务/专注摘要、我的动态、多图预览、回顶、资料返回刷新；消息入口 Toast 为已登记偏差 | — | [`p2final-mine-latest.png`](acceptance/screenshots/p2final-mine-latest.png) |
| P2.11 个人资料 `MeProfile` | PASS（相册选图 NOT TESTED） | 字段/长度限制/下拉选择/保存返回与全局刷新代码路径；原值保存已由施工方实测并恢复 | — | `p2c-*` |
| P2.12 地址三页 | PASS | 列表、默认标识、新增、编辑、删除确认、默认回补；`alias/fullAddress` 与数字 id 适配；快递/打印复用地址簿 | — | `p2c-address-*.png` |
| P2.13 我的订单 `MeOrder` | PASS（空态路径 Minor） | 四状态筛选、卡片字段、数字 id 归一化、去打印跳转；当前生产订单可正常展示 | m2 | `p2c-order-*.png` |
| P2.14 反馈 `MeFeedback` | PASS（选图 NOT TESTED） | 类型/正文 500 字计数/最多 3 图入口/联系方式/FAQ/1.5s 模拟提交与返回；相册为空，检查与入列未实测 | — | 既有 `p2c-feedback-default.png` 等（本轮未重拍） |
| P2.15 关于 `MeAbout` | PASS | 渐变头图、平台定位、核心模块、我们的优势、页脚；与参考区块一致 | — | 既有 `p2c-*` |
| P2.16 设置 `MeSetting` | PASS（Minor） | 缓存清理确认、生产/本地切换、当前后端地址、检测连接、版本、关于/协议入口、会话重置；最终 HAP 下环境行点击仍无动作 | m1 | [`p2final-setting-default-latest.png`](acceptance/screenshots/p2final-setting-default-latest.png) |
| P2.17 人流 `ServicePersonInfo` | PASS（标题 Minor） | 三类地点、地点胶囊、实时/预测双栏、5 槽位、天气/建议、刷新节奏；标题与 `pages.json` 不一致 | m3 | [`p2final-personinfo-latest.png`](acceptance/screenshots/p2final-personinfo-latest.png) |
| P2.18 课表 `ServiceSchedule` | PASS（查询/AI NOT TESTED） | 学期/周次、查询表单、课程详情与空态代码路径；无有效学号密码，未发起真实查询；标题不一致 | m3 | [`p2final-schedule-latest.png`](acceptance/screenshots/p2final-schedule-latest.png) |
| P2.19 成绩 `ServiceGrade` | PASS（查询/AI NOT TESTED） | 统计卡/GPA/学期筛选/成绩详情代码路径；无有效凭据，未发起真实查询 | — | [`p2final-grade-latest.png`](acceptance/screenshots/p2final-grade-latest.png) |
| P2.20 打印 `ServicePrint` | **FAIL（静态）** | 服务关闭态、价格卡、文件选择/大小校验/预览、份数、取件/派送、地址簿、手机号校验 UI 均存在；真实下单受“禁止写生产数据”限制未执行 | M2 | [`p2final-print-default.png`](acceptance/screenshots/p2final-print-default.png) |
| P2.21 打印成功 `ServicePrintSuccess` | **FAIL（静态）** | 页面结构、状态色、返回首页/查看订单按钮存在；后端返回与数字 id 未归一化，成功页订单号/查找会失败 | M2 | 无真实成功订单截图（NOT TESTED） |
| P2.22 专注 `FocusPage` | PASS（满 10 分钟 NOT TESTED） | 开始/放弃确认/结束、不足 10 分钟拒绝、今日分钟同步 | — | [`p2final-focus-latest.png`](acceptance/screenshots/p2final-focus-latest.png) |
| P2.23 任务 `TaskPage` | PASS（Minor） | 全部/待完成/已完成筛选切换、完成切换、详情弹层、增删改、空态、远程+本地兜底；筛选计数不更新 | m6 | [`p2final-task-latest.png`](acceptance/screenshots/p2final-task-latest.png) |
| P2.24 快递代取 `ServiceExpress` | **FAIL** | 地址选择/新增、大小重量计价（¥7.00）、备注、校验、本地订单列表、演示提示均正常；下单跳转后成功页不展示该订单 | M1、m4 | [`p2final-express-default.png`](acceptance/screenshots/p2final-express-default.png)、[`p2final-express-orders-latest.png`](acceptance/screenshots/p2final-express-orders-latest.png) |
| P2.25 用户协议 `AgreementUser` | PASS | 全文归一化比对与参考完全一致（1264 字）；首段、8 个章节、联系方式、更新/生效日期 `2025年4月22日` 一致；可滚到底 | — | [`p2final-agreement-user-latest.png`](acceptance/screenshots/p2final-agreement-user-latest.png)、[`p2final-agreement-user-bottom-latest.png`](acceptance/screenshots/p2final-agreement-user-bottom-latest.png) |
| P2.26 隐私政策 `AgreementPrivacy` | PASS | 全文归一化比对与参考完全一致（781 字）；引言、收集/使用/共享、联系方式、日期 `2025年4月22日` 一致；可滚到底 | — | [`p2final-agreement-privacy-latest.png`](acceptance/screenshots/p2final-agreement-privacy-latest.png)、[`p2final-agreement-privacy-bottom-latest.png`](acceptance/screenshots/p2final-agreement-privacy-bottom-latest.png) |
| P2.27 服务聚合 `Service` | PASS | 校园查询/打印快递/生活服务分组；人流、课表、成绩、打印、快递、订单、地址入口均正确；首页“更多服务”可达 | — | [`p2final-service-default.png`](acceptance/screenshots/p2final-service-default.png)、[`p2final-home-more-service.png`](acceptance/screenshots/p2final-home-more-service.png) |
| P2.28 通用成功 `ServiceSuccess` | **FAIL** | `type=express` 标题/文案/按钮正确；订单卡未显示刚创建的本地订单；“查看订单”回下单表单 | M1、m4 | [`p2final-express-success-final-hap.png`](acceptance/screenshots/p2final-express-success-final-hap.png)、[`p2final-express-vieworder-final-hap.png`](acceptance/screenshots/p2final-express-vieworder-final-hap.png) |
| P2.29 入口与死链 | PASS（Minor） | 首页“更多服务”、我的快捷入口/功能卡/设置、服务聚合、地址/订单/打印/快递互跳可达；路由图 30/30；设置页仍有带箭头无动作行 | m1 | 同上 |

### 缺陷清单

| 编号 | 级别 | 页面 / 任务 | 描述 | 复现步骤 | 期望 / 实际 | 文件 / 截图 |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | **Major** | P2.24 / P2.28 快递成功页 | 快递下单成功页始终渲染默认 `ExpressOrder()`。缓存已写入真实订单，`CacheStore` 日志为 `get key=expressOrders hit=true`、`json parsed`，本地订单列表也能展示同样订单，但成功页未使用查找结果 | Service → 快递代取 → 立即下单；在最终 HAP 上重复执行 | 期望展示真实订单号、收货地址、大小/重量、¥7.00、创建时间；实际固定显示 `订单号: draft`、`收货地址: 未填写`、`预估费用: ¥0.00` | `entry/src/main/ets/pages/ServiceSuccess.ets:61-73`、`:167-190`；[`p2final-express-success-final-hap.png`](acceptance/screenshots/p2final-express-success-final-hap.png)；对照 [`p2final-express-orders-latest.png`](acceptance/screenshots/p2final-express-orders-latest.png) |
| M2 | **Major（静态）** | P2.20 / P2.21 打印下单成功链路 | `/print/order` 返回值被直接当作完整 `PrintOrder`；参考实现仅读取 `data.id` 并用提交表单构造本地订单，且参考以 `parseInt` 处理数字订单 id。当前 `created.createdAt.length` 在仅返回 id 时会抛错；即便返回完整订单，数字 id 也会使 `orderId.length` 与 `this.order.id.length` 取不到值 | 选择文件 → 填写表单 → 下单（生产写入限制，未实际提交） | 期望合并提交表单与返回 id、将 id 统一为字符串后传入成功页；实际会在下单成功后提示失败，或成功页订单号显示 `draft` 且按 orderId 查找失败 | `entry/src/main/ets/pages/ServicePrint.ets:211-218`；`entry/src/main/ets/pages/ServicePrintSuccess.ets:30-45`；同类路径 `ServiceSuccess.ets:44-55`；参考 `../who_family_wechat/store/modules/print.js` |
| m1 | Minor | P2.16 / P2.29 设置页 | 四个信息行带 `›` 箭头但无任何点击效果：当前环境、当前后端地址、版本信息、应用标识；其中应用标识走 `SettingRow` 的空 URL 分支 | 设置页点击“当前环境”“当前后端地址”“版本信息”“应用标识” | 期望要么可展开/复制/跳转，要么移除箭头；实际无响应、无 Toast | `entry/src/main/ets/pages/MeSetting.ets:172-200`、`:230-291`、`:358`；[`p2final-setting-default-latest.png`](acceptance/screenshots/p2final-setting-default-latest.png) |
| m2 | Minor | P2.13 我的订单 | 后端成功返回空数组时被 `MockData.printOrders()` 顶替，用户看不到参考实现的订单空态 | 使用无订单账号进入“我的订单”（或让 `/print/self-orders` 返回 `[]`） | 期望“暂无订单记录 / 您还没有任何打印订单 / 去打印”；实际显示演示订单，误导为真实记录 | `entry/src/main/ets/pages/MeOrder.ets:56-59`；参考 `../who_family_wechat/pages/me/order/index.vue` 空态分支 |
| m3 | Minor | P2.17 / P2.18 页面标题 | 标题与参考 `pages.json` 不一致 | 进入人流/课表页看顶部标题 | 期望“校园人流数据”“课表查询”；实际“人流监测”“课程表” | `ServicePersonInfo.ets:1011`、`ServiceSchedule.ets:824`；[`p2final-personinfo-latest.png`](acceptance/screenshots/p2final-personinfo-latest.png)、[`p2final-schedule-latest.png`](acceptance/screenshots/p2final-schedule-latest.png) |
| m4 | Minor | P2.24 / P2.28 快递成功页 | “查看订单”对快递执行 `replaceUrl('pages/ServiceExpress')`，回到下单表单而非本地订单记录 | 快递成功页点击“查看订单” | 期望看到本地代取订单列表/记录，或隐藏该按钮；实际回到空白下单表单 | `entry/src/main/ets/pages/ServiceSuccess.ets:228-233`；[`p2final-express-vieworder-final-hap.png`](acceptance/screenshots/p2final-express-vieworder-final-hap.png) |
| m5 | Minor | P2.25 / P2.26 文档 | 协议全文已完成并实机验证，但施工清单仍标 `TODO` | 查看 `docs/parity-plan.md` 协议表 | 期望状态改为 `DONE` 并附验证说明；实际仍为 `TODO` | `docs/parity-plan.md:157-158` |
| m6 | Minor | P2.23 任务页筛选 | 列表已渲染 4 条任务，但“全部/待完成/已完成”计数均为 `0`；点击切换筛选、退出后重新进入仍为 `0` | 我的 → 任务待办 → 查看筛选栏 | 期望“全部 4 / 待完成 4 / 已完成 0”；实际三项均为 0，与列表内容矛盾 | `entry/src/main/ets/pages/TaskPage.ets:303-307`、`:314-317`；[`p2final-task-latest.png`](acceptance/screenshots/p2final-task-latest.png) |

### 允许偏差

- `Mine` 快捷导航“消息”：参考实现无跳转；鸿蒙版增加 Toast“消息功能暂未开放”，属 P2.29 计划内主动反馈，不计缺陷。
- `Service` / `ServiceExpress` / `ServiceSuccess` / `MeSetting` 为鸿蒙增强页，标题与信息组织不完全对应未注册的小程序死代码，按产品决策保留，不计缺陷。
- 无登录页、无微信登录、无微信好友/朋友圈分享、无支付：沿用既有产品决策与平台差异，不计缺陷。
- AI 真实流式输出、头像/反馈选图上传、课表/成绩真实查询、打印真实下单、专注满 10 分钟记录：环境或生产数据限制，标 `NOT TESTED`，不计运行态缺陷；M2 为静态代码契约缺陷，单独登记。

### NOT TESTED

- 头像选择/上传、反馈选图、打印文件真实上传：模拟器相册为空；打印提交还受“禁止写生产数据”限制。
- 课表/成绩真实查询与 AI 分析：缺少有效学号/密码；`DASHSCOPE_API_KEY` 无效，AI 真实输出按既有约定不计缺陷。
- 打印真实下单成功页、订单号回填与 `orderId` 运行态匹配：未写生产数据，仅做代码审查。
- 专注满 10 分钟记录/完成弹窗：未等待完整计时。
- A2 无 token、A3 401、A4 断网、A7 分页、A8 重复提交：本轮未重新构造，沿用前序验证据。
- P4 全量 30 路由各进出 2 次：仅完成静态 30/30 可达与关键路径实机抽查。

### 数据与仓库

- 本轮未修改 `entry/`、构建配置或参考仓库；仅追加本报告与 `docs/acceptance/screenshots/p2final-*` 截图。
- 本轮验收共新增 5 条本地演示快递订单（`expressOrders` 缓存），未提交后端；未创建、修改或删除任何生产订单、地址、动态或评论。
- 未读取或回显 `DEMO_TOKEN`、`DASHSCOPE_API_KEY`、JWT 或签名材料。

### 结论

**不通过：Blocker 0 / Major 2 / Minor 6。**

P2.10–P2.29 的页面主体、协议全文、服务入口与 30 条路由静态可达性总体完成；但快递成功页不展示订单（M1）、打印下单成功链路未适配后端返回与数字 id（M2）均影响核心下单结果，必须修复后复验。m1–m6 可随修复一并处理。
