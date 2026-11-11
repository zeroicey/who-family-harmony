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
