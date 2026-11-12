# 参考实现通读记录（P0.2）

> 参考：`../who_family_wechat`（uni-app 微信小程序，只读）。
> 本文件逐页记录区块顺序、关键文案、交互、接口与空态，作为 P2 页面施工与验收依据。
> 记录时间：2026-11-11。导航标题以 `pages.json` 为准。

## 0. 全局

- 注册页面 27 个；文件存在 30 个。未注册：`service/express.vue`、`service/success.vue`、`me/setting/index.vue`（0 字节）。
- TabBar：首页 / 社区 / 助手 / 知识 / 我的。
- 接口基址：生产 `https://api.hcyj.xyz`，本地 `http://localhost:3000`；请求头 `Authorization: <裸 token>`。
- 内容检查：`POST /check/text { text: JSON.stringify(data) }`、`POST /check/img { img }`；返回 `code=200` 为通过。

## 1. 逐页清单

### 首页 `pages/home/index.vue` — 首页
- 区块：`HomeHeader`（问候语 + 4 张轮播）→ `ServiceRecommend`（横向服务卡）→ `CampusNotifications`（7 条）→ `RecruitmentCard`（最多 5 条）→ 安全区。
- 文案：问候 `凌晨好/早上好/上午好/中午好/下午好/晚上好/夜深了`，用户名缺省 `同学`；日期 `M.D · 星期X`。
- 交互：轮播 3s 自动；服务卡 `navigateTo`；`查看更多` → 招聘 Tab；招聘项 → 详情。
- 接口：`GET /hire/recommend-jobs`（招聘卡懒加载）。
- 空态：招聘 `暂无招聘信息` / `正在加载...`；服务失败 toast `服务数据加载失败`。

### 社区 `pages/community/index.vue` — 社区（下拉刷新）
- 区块：4 个分类 Tab（动态/跑腿/二手/评分）→ 对应卡片流 → 右下 `+` 发布。
- 交互：切 Tab；下拉 `fetch_first_posts`；触底 `fetch_more_posts`；发布 → `community/publish`。
- 接口：`GET /community/recommend-post`、`?lastPostId=`；`GET /community/postTypes`。
- 空态：`暂无动态`、`暂无跑腿任务`、`二手功能开发中...`、`评分功能开发中...`。

### 动态详情 `pages/community/detail.vue` — 动态详情
- 区块：作者信息 → 正文 → 图片九宫格 → 统计栏 → 评论。
- 交互：评论/回复/删除、查看更多回复、点赞、图片预览。
- 接口：`/community/post`、`/community/post-comment`、`/community/post-comment-reply`、`/community/like-post`、`/user/avater`。
- 空态：`暂无评论，快来抢沙发吧！`；失败 `加载评论失败`；删除他人评论 `无法删除他人评论`。

### 发布动态 `pages/community/publish.vue` — 发布动态
- 区块：图片网格（最多 4 张）→ 标题 + 发布 → 分割线 → 正文 → `撤回优化` / `AI润色`。
- 文案：标题占位 `✨ 给你的动态起个有趣的标题吧~`；正文占位 `💭 今天有什么想分享的呢？可以是生活趣事、学习心得、美食推荐...让大家看到不一样的你！✨`。
- 交互：选图/预览/删除；AI 润色与撤回；发布。
- 接口：`/check/text`、`/community/prepare-post`、图片直传、`/community/img-uploaded`、`/community/finalize-post`；DashScope 润色。
- 校验：标题 ≤99 字、正文 ≤10000 字；固定类型 `好物推荐`。

### 助手 `pages/helper/index.vue` — 助手（自定义导航）
- 区块：自定义头（`校园AI助手`）→ 消息列表 → 预设问题 → 输入框。
- 首条消息：`👋 你好！我是校园AI助手，很高兴为你提供服务！` + 5 个主题 + `有什么问题尽管问我吧～`。
- 交互：发送、点预设发送、清空聊天、AI 状态检查、自动滚动。
- 接口：DashScope `https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions`（流式）。
- 状态：输入光标 `▋`；失败 toast `发送失败，请重试`。

### 知识 `pages/knowledge/index.vue` — 知识
- 区块：15 个分类胶囊（仅前 6 个有数据）→ 文章卡（推荐、标题、等级、摘要、标签、作者、日期、阅读/点赞）。
- 交互：切分类；卡片 → `knowledge/article?id=`。
- 接口：无（本地 `knowledgeData`）。
- 空态：无显式空态；后 9 个分类列表为空。

### 知识详情 `pages/knowledge/article.vue` — 知识详情（自定义导航）
- 区块：等级 + 日期 → 标题 → 作者 + 阅读时长/字数 → 阅读/点赞统计 → 标签 → Markdown 正文 → 浮动点赞/AI → AI 解读浮窗。
- 交互：点赞本地切换；AI 解读 1.5s 后打开预生成内容；分享。
- 数据：所有 `?id=` 都渲染同一篇 `动态规划经典题` 正文。
- 空态：无。

### 招聘 `pages/recruit/index.vue` — 招聘
- 区块：分类 Tab（模板中已注释）→ 岗位卡列表 → `加载中...` → `没有更多数据了`。
- 交互：下拉刷新、触底加载；卡片 → 详情。
- 接口：`GET /hire/recommend-jobs`、`?lastId=`、`GET /hire/job-types`。
- 状态：加载失败 `加载失败`；无显式空态。

### 招聘详情 `pages/recruit/detail.vue` — 招聘详情
- 区块：加载中 → 企业头（logo、`organizationName`、位置）→ 岗位（名称、薪资、类型、`🔥 热门`/`⭐ 推荐`）→ `📋 职位描述` / `✅ 任职要求` / `🎁 福利待遇` → 联系方式 → 底部操作。
- 交互：收藏、投递（`确认投递`：`确定要投递该职位吗？投递后无法撤销。`）。
- 接口：`/hire/job?id=`、`/hire/collect-job`、`/hire/submit`。
- 状态：`您已投递过该职位`、`投递成功`、`投递失败`。

### 我的 `pages/me/index.vue` — 我的（下拉刷新）
- 区块：用户卡（Lv、品牌称号、学校/专业/年级）→ 快捷入口（订单/地址/消息/关于/反馈）→ 任务待办 + 专注时刻 → 我的动态 → 回到顶部。
- 接口：`GET /community/self-post`、`?lastPostId=`；登录刷新。
- 空态：我的动态无显式空态。

### 反馈 `pages/me/feedback.vue` — 反馈
- 区块：头图（`倾听您的声音` / `您的每一个建议，都是我们成长的动力`）→ 表单（类型/内容 0-500/截图 ≤3/联系方式）→ 常见问题 → 提交。
- 文案：占位 `请详细描述您遇到的问题或建议...`、`选填，便于我们与您联系（手机/QQ/微信）`；FAQ 三条。
- 交互：提交模拟 1.5s 后 toast 并返回。
- 状态：`反馈内容不能为空哦`、`正在提交...`、`感谢您的反馈！`。

### 关于 `pages/me/about.vue` — 关于
- 区块：Logo + `互成一家` / `全方位校园互助与成长平台` → `平台定位` → `核心模块` 3×2 → `我们的优势` 4 条 → 页脚 `互成一家，让校园生活更精彩`。

### 地址管理 `pages/me/address/index.vue` — 地址管理
- 区块：地址列表（`[默认]`、编辑/删除）→ 空态 → `新增收货地址`。
- 交互：点行设默认；编辑/新增；删除确认 `确认删除` / `确定要删除这个地址吗？`。
- 接口：仅远程存储 `/storage/getItem`、`/storage/setItem`（key `addresses`）。
- 空态：`还没有收货地址，快去添加一个吧`。

### 新增/修改地址 `pages/me/address/create.vue` / `update.vue` — 新增地址 / 修改地址
- 字段：地址别名、收货人姓名、手机号码、详细地址、`设为默认地址`、保存。
- 占位：`如：家、学校`、`请填写收货人姓名`、`请填写收货人手机号`、`请输入详细地址，如街道、楼牌号等`。
- 校验：`请填写完整的地址信息`。

### 我的订单 `pages/me/order/index.vue` — 我的订单
- 区块：状态筛选（全部/待处理/处理中/已完成）→ 订单卡（订单号、时间、状态、服务方式、联系人、电话、配送地址、备注、创建/完成时间）→ 空态。
- 接口：`GET /print/self-orders`。
- 空态：`暂无订单记录` / `您还没有任何打印订单` / `去打印`。

### 个人资料 `pages/me/profile/index.vue` — 个人资料
- 区块：头像（`更换`）→ 昵称/性别/学校/专业/年级 → 个人简介（0-100）→ `保存修改`。
- 接口：`PUT /user/userInfo`、`PUT /user/avatar`、`GET /user/avater?id=`。

### 课表 `pages/service/schedule.vue` — 课表查询
- 区块：页头（`课程表` / `查看您的课程安排`）→ 教务登录卡 → 周次步进 → 课表 → 课程详情弹窗 → AI 分析。
- 文案：`查询课表`、`暂无课程数据`、`请检查周次选择或稍后重试`、`未安排`、`教室/教师/周次/时间`。
- 接口：`GET https://api.hcyj.xyz/yeciorez/neusoft/schedule?studentNo&password&term&week`；DashScope。
- 状态：`请输入学号/请输入密码/请选择学期`、`第N周课表加载成功`、`第N周暂无课程`、`账号或密码错误`。

### 成绩 `pages/service/grade.vue` — 成绩查询
- 区块：页头 → 登录卡 → 成绩单（学期徽标 + `总课程数/总学分/平均分/平均绩点`）→ 成绩卡 → `重新查询` → AI 分析。
- 接口：`GET /yeciorez/neusoft/grades?studentNo&password&term`。
- 空态：`暂无成绩数据` / `请检查学期选择或稍后重试`；成功 `查询成功，共N门课程`。

### 校园人流 `pages/service/personinfo/personinfo.vue` — 校园人流数据
- 区块：页头（`校园实时监测` / `Campus Real-time Monitoring`）→ 分类（教学楼/饭堂/校道）→ 地点胶囊 → `人流监测` 卡 → `环境感知` 卡 → 页脚。
- 文案：状态 `舒适/适中/拥挤/饱和`；天气 `多云`、`26°C`、`PM2.5 35 μg/m³`、`良`；页脚 `数据仅供参考 · 请以实际情况为准`。
- 接口：无，静态数据。

### 打印 `pages/service/print/index.vue` — 文件打印
- 区块：头图 → `ServiceIntroCard` → `服务范围说明` → `打印价格` → `PrintForm` → `服务信息` → `服务优势`/`附加服务`。
- 文案：`点击选择文件 (支持 PDF，DOCS，DOC)`、`打印份数`、`立即下单`；取件地址 `广东东软学院图书馆4楼sovo互成一家工位`。
- 接口：`GET /print/price`、`GET /print/is-open`、`POST /print/order`。
- 状态：`服务未开启`；`价格加载中...` / `价格获取失败，请稍后重试`；校验 `请先选择要打印的文件`、`请选择收货地址`、`请填写联系电话`。

### 打印成功 `pages/service/print/success.vue` — 打印下单成功
- 区块：`下单成功` / `请添加商家微信进行联系` → 订单卡（订单号/收货地址/份数/创建时间）→ `返回首页`。
- 接口：读 `GET /print/self-orders` 缓存。

### 专注 `pages/focus/index.vue` — 专注
- 区块：头（`专注时刻` / `今日已专注：…`）→ 圆环计时 → 开始/结束/放弃 → 语录 + `专注期间请勿退出或锁屏，否则计时将中断` → 完成动画 `太棒了！专注完成！`。
- 接口：`POST /checkin/focus`、`GET /checkin/focus/today`。
- 状态：`确定要放弃本次专注吗？`、`开始专注失败`、`专注完成！`、`已取消专注`。

### 任务 `pages/task/index.vue` — 任务
- 区块：新增输入（`输入新任务，回车即可添加` + `+`）→ 激励语 → 任务列表 → 详情弹窗。
- 接口：`GET /checkin/todos`、`POST /checkin/addTodo`、`PUT /checkin/done`、`PUT /checkin/todo`、`DELETE /checkin/todo`。
- 空态：`还没有任务哦，快添加一个吧！`；校验 `任务内容不能超过50个字`。

### 用户协议 `pages/agreement/user.vue` — 用户协议
- 8 节：`欢迎使用互成一家`、`账号注册与使用`、`用户行为规范`、`知识产权`、`免责声明`、`协议修改`、`法律适用与争议解决`、`联系我们`。
- 无接口；页脚 `本用户协议更新日期：2025年4月22日 / 生效日期：2025年4月22日`。

### 隐私政策 `pages/agreement/privacy.vue` — 隐私政策
- 5 节：`引言`、`我们收集的信息`、`信息的使用`、`信息的共享`、`联系我们`。
- 联系方式：`privacy@whofamily.com` / `17727316901` / `佛山市南海区信息大道中互成一家传媒公司`。
- 页脚同日期。

### 未注册额外页
- `pages/service/express.vue`：头图 → `闪电速递，使命必达` → 权益 → 表单（地址/大小/重量）→ 服务流程 → 用户评价 → 立即下单。鸿蒙版保留为 `ServiceExpress`。
- `pages/service/success.vue`：`下单成功` + 快递/打印订单卡 + 返回首页。鸿蒙版保留为 `ServiceSuccess`。
- `pages/me/setting/index.vue`：空文件。鸿蒙版保留为 `MeSetting`，按产品决策补齐设置能力。

## 2. 静态内容迁移清单（已落到 `ets/mock/`）

| 内容 | 原位置 | 鸿蒙位置 |
| --- | --- | --- |
| 知识文章 28 篇 + 正文 | `static/mock/knowledge/*` | `mock/KnowledgeMock.ets`（正文为 `dynamic-programming.js` 全文，所有 id 共用，与小程序一致） |
| 校园动态 7 条 | `components/home/CampusNotifications.vue` | `mock/HomeMock.ets#campusNotifications` |
| 首页服务卡 5 张 | `components/home/ServiceRecommend.vue` | `mock/HomeMock.ets#homeServices` |
| 用户协议 / 隐私政策全文 | `pages/agreement/*.vue` | `mock/AgreementMock.ets` |
| 助手预设问题 6 条 + 首条消息 | `store/modules/helper.js` | `mock/ChatMock.ets` |
| 轮播、任务、岗位、社区、课程、成绩等 | `MockData.ets` | `mock/HomeMock|CommunityMock|JobMock|TaskMock|ServiceMock`，`utils/MockData.ets` 仅作门面 |

## 3. 页面标题映射（F10 已应用）

| 鸿蒙页面 | 标题 |
| --- | --- |
| ServiceSchedule | 课表查询 |
| ServiceGrade | 成绩查询 |
| ServicePersonInfo | 校园人流数据 |
| ServicePrint | 文件打印 |
| ServicePrintSuccess | 打印下单成功 |
| FocusPage | 专注 |
| TaskPage | 任务 |
| JobList | 招聘 |
| JobDetail | 招聘详情 |
| CommunityDetail | 动态详情 |
| CommunityPublish | 发布动态 |
| KnowledgeArticle | 知识详情（自定义导航已统一为 PageHeader） |
| MeProfile | 个人资料 |
| MeAddress | 地址管理 |
| MeAddressCreate | 新增地址 |
| MeAddressUpdate | 修改地址 |
| MeOrder | 我的订单 |
| MeFeedback | 反馈 |
| MeAbout | 关于 |
| AgreementUser | 用户协议 |
| AgreementPrivacy | 隐私政策 |
| Service（额外） | 服务 |
| ServiceExpress（额外） | 快递代取 |
| ServiceSuccess（额外） | 下单成功 |
| MeSetting（额外） | 设置 |

Tab 宿主（Index/Community/Helper/Knowledge/Mine）沿用页面内自定义头部，不叠加 PageHeader。