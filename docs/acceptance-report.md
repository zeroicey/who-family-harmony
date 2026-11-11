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
