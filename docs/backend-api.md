# 互成一家后端接口说明

鸿蒙版与微信小程序版共用同一套后端，本文记录本仓库实际调用的接口与约定。

## 基础信息

| 项 | 值 |
| --- | --- |
| 生产地址 | `https://api.hcyj.xyz` |
| 本地地址 | `http://localhost:3000` |
| 技术栈 | Node.js + Express，Redis 存会话 |
| 超时 | `10000ms`（`ApiConfig.TIMEOUT`） |
| 响应信封 | `{ code, msg, data }` |

`HttpClient` 会先判断响应是否为对象，再解包 `data`；未知路径返回的是 `text/plain` 的 404，不能直接按 JSON 解析。

## 鉴权

- 除 `POST /login/wechat-login`、静态资源和 `OPTIONS` 预检外，其余路由都需要 token。
- 请求头写法：`Authorization: <token>`，**裸 token，不加 `Bearer ` 前缀**。后端直接用它当 Redis key。
- token 过期或缺失时返回 HTTP `401`，客户端应清理会话并引导重新登录。
- 鸿蒙版当前用 `env.ets` 中的演示 token 播种会话；未配置时降级到 Mock 数据。

## 本仓库已接入的接口

### 系统 / 用户

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/sys/banners` | 首页轮播 |
| GET | `/user/userInfo?id=` | 用户资料 |
| GET | `/user/avater?id=` | 头像地址 |

### 社区

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/community/postTypes` | 动态分类 |
| GET | `/community/recommend-post` | 推荐动态（支持 `lastPostId`） |
| GET | `/community/post?id=` | 动态详情 |
| GET | `/community/self-post` | 我的动态 |
| POST | `/community/prepare-post` | 发布前准备（上传凭证等） |
| POST | `/community/finalize-post` | 完成发布 |
| POST | `/community/like-post` | 点赞 / 取消点赞 |
| GET | `/community/post-comment?id=` | 一级评论 |
| POST | `/community/post-comment` | 发表一级评论 |
| GET | `/community/post-comment-reply?id=` | 二级回复 |

### 待办与专注

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/checkin/todos` | 待办列表 |
| POST | `/checkin/addTodo` | 新增待办 |
| PUT | `/checkin/done` | 标记完成 |
| PUT | `/checkin/todo` | 标记未完成 |
| DELETE | `/checkin/todo` | 删除待办 |
| POST | `/checkin/focus` | 记录专注分钟（1–120） |
| GET | `/checkin/focus/today` | 今日专注 |

### 岗位

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/hire/recommend-jobs` | 推荐岗位（支持 `lastId`） |
| GET | `/hire/job?id=` | 岗位详情 |
| GET | `/hire/job-types` | 岗位分类 |
| POST | `/hire/collect-job` | 收藏 / 取消收藏 |
| POST | `/hire/submit` | 投递简历 |

### 打印

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/print/is-open` | 打印服务是否开放 |
| GET | `/print/price` | 价格表 |
| POST | `/print/order` | 创建打印订单 |
| GET | `/print/self-orders` | 我的打印订单 |

### 远端存储

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| POST | `/storage/setItem` | 写入键值 |
| POST | `/storage/getItem` | 读取键值 |
| POST | `/storage/removeItem` | 删除键值 |

### 校园服务（外部服务，非主后端）

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/yeciorez/neusoft/schedule` | 课表查询 |
| GET | `/yeciorez/neusoft/grades` | 成绩查询 |

这两个接口把学号、密码作为 query 参数直接传给上游，属于演示用能力；正式产品必须改为服务端加密托管或校方 OAuth。

## 数据策略

1. **能用真实接口就用**：轮播、岗位、社区、待办、专注、打印。
2. **失败即降级**：任何接口异常都回退到 `MockData`，保证页面可演示。
3. **不做微信登录**：鸿蒙端不复刻 `wx.login`，使用演示会话或后续真实账号体系。

## 注意

- 不要提交真实 token、DashScope Key、学号密码到仓库。
- 生产域名与小程序共用，改动接口前先确认后端兼容性。