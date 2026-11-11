# 鸿蒙新技术评估（2026-11）

> 目的：判断哪些新能力能直接用于本项目，哪些会破坏"与小程序一模一样"的目标。
> 结论会随官方文档更新；新增结论请追加到文末，不要直接覆盖历史判断。

## 1. 约束

- 工程：`compatibleSdkVersion 6.0.0(20)`，`targetSdkVersion 6.1.1(24)`。
- **API 22+ 的能力不能无条件使用**：在 API 20 设备上会不可用。必须用 `canIUse` / 版本判断 + 降级，或整体抬高 `compatibleSdkVersion`（需要产品确认）。
- 项目目标是对齐微信小程序，不是做一套新的鸿蒙原生视觉。
- 运行时零第三方依赖；不因"新"而引入库。

## 2. 结论速览

| 能力 | 起始 API | 结论 | 用途 |
| --- | --- | --- | --- |
| `Image` 加载网络图 | 7 | ✅ 采用 | 替换 `RemoteImage` 的 Web 渲染（F3） |
| `PhotoViewPicker` | 10 | ✅ 采用 | 头像、社区发图、反馈截图（F5） |
| `DocumentViewPicker` | 9 | ✅ 采用 | 打印文件选择（F5） |
| HTTP 流式（`requestInStream`） | 10 | ✅ 采用 | AI 逐字输出（F4/F7） |
| `bindSheet` / `bindContentCover` | 11 | ✅ 采用 | 评论、详情、AI 解读弹层（F2） |
| `LazyForEach` / `Repeat` | 7 / 12 | ✅ 采用 | 社区、招聘、我的动态长列表（F9） |
| `pasteboard` | 6 | ✅ 采用 | 助手消息复制 |
| `connection` | 7 | ✅ 采用 | 断网提示与自动重试 |
| `DataPanel` / `Gauge` / `Canvas` | 7 / 8 / 8 | ✅ 采用 | 人流监测图表（P2.17） |
| `ShareKit` 系统分享 | 11 | 🟡 可选 | 知识/岗位分享；微信分享无法复刻 |
| `@kit.UIDesignKit`（HdsTabs、hdsMaterial） | 22 / 23 | ❌ 不采用 | 视觉会偏离小程序；且 compatible 20 不满足 |
| HarmonyOS 7.0 新特性 | 25+ | ❌ 暂不升级 | target 24 已足够；升级会缩小设备覆盖 |
| ArkUI 状态管理 V2 | 12 | ❌ 暂不迁移 | 现有 V1 统一；混用风险大于收益 |
| `Navigation` / `NavPathStack` | 9/10 | ❌ 暂不迁移 | 30 页改造成本高；用 `PageHeader` 补齐导航栏 |
| `@kit.UIDesignKit` 仅用于增强页 | 22 | 🟡 可选 | 仅 `Service`/`MeSetting` 可考虑，且需版本守卫 |
| `harmonyos-skills` 离线文档 | — | 🟡 参考 | 17k+ 官方文档镜像；本机 GitHub 直连受限，未安装 |

## 3. 值得关注但本轮不用的能力

### 3.1 API 21（6.0.1）

- ArkUI 组件能力增强，新增一批属性样式的 C API；`Image` 增强 SVG 解析。
- 对本项目：`Image` 的 SVG 支持可以少放一套 SVG 资源，但不是必须。
- 来源：华为 API 21 版本说明（媒体转述）。

### 3.2 API 22 / 23（6.0.2 / 6.1.0）与 UI Design Kit

- `@kit.UIDesignKit` 提供 HDS 扩展组件与材质效果：
  - `HdsTabs`（底部页签，支持分割线、模糊、侧边栏样式），从 6.0.2(22) 可用。
  - `hdsMaterial` 光影/材质效果，适合"高端精致"的原生风格。
  - 6.1 进一步支持悬浮页签、沉浸光感、多设备平行视界等。
- **为什么不用**：小程序是自定义绿色 tabBar 与卡片体系，HDS 会带来明显不同的视觉语言；且 `compatibleSdkVersion=20`，API 22 组件在旧设备不可用。
- **例外**：如果负责人希望四个增强页（Service / Express / Success / Setting）更"鸿蒙原生"，可在页面级做 `canIUse('SystemCapability...')` 判断 + 旧版降级；不要动首页/社区/助手/知识/我的。
- 参考：`HdsTabs (底部页签)` 官方文档、`@kit.UIDesignKit` 组件解读。

### 3.3 HarmonyOS 7.0

- 2026-09 已发布，带来新一轮系统能力与开发工具升级。
- 本项目 target 24，暂不跟进；升级 SDK 需要重新评估设备覆盖、签名、HDS/ArkUI 兼容性与验收成本。
- 结论：**本轮不升级**；等对齐完成、稳定后再单独评估。

### 3.4 ArkUI 状态管理 V2

- `@ComponentV2` / `@Local` / `@Param` / `@Event` / `@Monitor` 等更适合复杂状态。
- 现有 30 页均为 V1；混用会提高维护成本。本轮统一 V1，新增组件也优先 V1。
- 若后续做大重构，再统一迁移。

### 3.5 Navigation / NavPathStack

- 新工程推荐 `Navigation` 管理路由与标题栏；本项目是 `router` + 30 个 `@Entry` 页面。
- 迁移成本高、回归面大；用统一 `PageHeader` 解决返回/标题即可。

## 4. 本轮直接采用的能力（施工要求）

1. **图片**：`Image(this.url).objectFit(ImageFit.Cover)` + 占位/失败回退；禁止 Web 渲染图片。
2. **选图/选文件**：
   - `photoAccessHelper.PhotoViewPicker` 或 `picker.PhotoViewPicker`。
   - `picker.DocumentViewPicker` + `fileIo` 读取 → base64 / ArrayBuffer。
3. **流式 AI**：`http.HttpRequest.requestInStream` + `on('dataReceive')`，按 SSE 解析；支持取消。
4. **弹层**：`bindSheet` / `bindContentCover`，替代自绘全屏遮罩。
5. **列表**：`LazyForEach`（或 `Repeat`）处理长列表；配合 `Refresh` 组件实现下拉刷新。
6. **复制**：`pasteboard` 复制助手消息。
7. **网络状态**：`connection` 监听断网，页面显示离线提示。
8. **图表**：人流监测用 `DataPanel`/`Gauge`/`Canvas`，颜色与小程序一致；实现前调用 `dataviz` skill。

## 4.1 AI key 的接入约定

- 唯一配置入口：`entry/src/main/ets/api/env.ets` 的 `DASHSCOPE_API_KEY`（gitignored）。
- 代码只读该常量，不允许硬编码、不允许在日志/界面回显。
- 未配置或无效时：助手/发布润色/成绩分析/课表分析/知识解读都必须显示明确错误，不崩溃、不伪造结果。
- 负责人后续填入有效 key 后，**无需改代码**，重新构建即可使用。
- 在 key 不可用期间，验收将 AI 真实输出标为 `NOT TESTED`，不计为缺陷。

## 5. UI 设计方面要不要上"UI/UX 技能"？

**结论：本轮不需要通用 UI/UX 重设计技能。**

- 本项目的设计规范就是微信小程序版；目标函数是"一致"，不是"更好看"。
- 引入 `ui-ux-pro-max` 这类设计技能，容易产生新的配色、圆角、排版体系，反而增加验收成本。
- 真正需要的是：
  1. `theme/` 设计 token（F1）；
  2. 逐页视觉对照 + 截图验收（`docs/acceptance.md`）；
  3. 图表场景使用 `dataviz` skill（人流的柱状/占比图）。
- 如果四个增强页（Service / Express / Success / Setting）想做得更精致，可以让 UI 技能**只在这四个页面内**给建议，并强制复用现有 token；不要动核心五 Tab。

## 6. 检索与验证方式

- 统一使用 **cormorant MCP**（`search` / `fetch` / `status`）查官方文档与社区文章。
- 判定一条 API 能否使用，至少确认：
  1. 官方文档的"起始版本"；
  2. 是否高于 `compatibleSdkVersion 20`；
  3. 是否需要 `canIUse` 或系统能力声明；
  4. 是否有旧设备降级路径。
- 查不到官方依据时，不要猜；记录为 `UNVERIFIED` 并找负责人确认。
- 参考实现：`../who_family_wechat` 只读。

## 7. 参考来源

- API 21 / 6.0.1 版本说明（华为开发者官网，媒体转述）：
  - https://www.huaweicentral.com/harmonyos-6-0-1-api-21-beta-details-are-out-with-new-enhancements
- HarmonyOS 6.1 新特性（社区整理）：
  - https://zhuanlan.zhihu.com/p/2033210619806097695
- UI Design Kit 官方介绍：
  - https://developer.huawei.com/consumer/cn/sdk/ui-design-kit
- HdsTabs 文档：
  - https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ui-design-hdstabs
- harmonyos-skills（17k+ 官方文档离线镜像，MIT）：
  - https://github.com/liasica/harmonyos-skills

## 8. 变更记录

| 日期 | 变更 |
| --- | --- |
| 2026-11-11 | 初始评估：确定 Image/选择器/流式/弹层/列表为采用项；HDS、HarmonyOS 7.0、ArkUI V2、Navigation 不采用 |