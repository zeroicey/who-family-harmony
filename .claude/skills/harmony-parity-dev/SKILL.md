---
name: harmony-parity-dev
description: Use when implementing a page-level parity task in hcyj-harmony (HarmonyOS ArkTS) against the WeChat mini-program reference. Covers task selection, reference reading, ArkTS implementation, build/lint preflight, self-test, and checklist updates.
---

# 鸿蒙对齐开发

把鸿蒙版逐页对齐 `../who_family_wechat`。先读 `AGENTS.md`，再读 `docs/parity-plan.md`。**一次只做一个任务**。

## 开工前

1. 确认参考实现存在：`../who_family_wechat`（只读，禁止修改）。
2. 读任务对应的小程序源码：
   - 页面 `.vue`
   - 它引用的 `components/**`
   - 相关 `store/modules/*.js` 与 `api/*.js`
3. 读鸿蒙现有页面、相关 `api/`、`models/`、`components/`。
4. 在回复里先写一个 5 行以内的实现清单：区块顺序、数据来源、交互、状态、要改的文件。

## 实现规则

- 顺序：先做 `docs/parity-plan.md` 中依赖已满足的最小 ID；F3（图片替换）、F1/F2（主题/组件）是多数页面任务的前置。
- 复用现有 `theme/`、`components/common/`、`services/`；没有就先补基础能力，不要复制粘贴样式。
- ArkTS 严格模式：不用 `any` / `unknown` / 动态索引 / `eval`。
- 网络图片只用 `Image(url)`，禁止新增 Web 渲染图片。
- 新增路由页面必须注册到 `entry/src/main/resources/base/profile/main_pages.json`，并带 `@Entry`。
- 子页必须有统一 `PageHeader`（返回 + 标题）。
- 中文文案、标点、emoji 与小程序逐字一致。
- 每个列表/详情都要有：加载中、成功、空数据、失败降级。
- 不引入第三方运行时依赖；不改构建配置；不动 `../who_family_wechat`。
- 不提交 `env.ets`、签名、`build/`、`oh_modules/`。

## 完成后必须做

```bash
./scripts/preflight.sh
```

要求：构建通过、CodeLinter 0 error。若有 Web 图片残留，F3 完成后必须为 0。

再在真机/模拟器上：

1. 进入页面 → 操作主流程 → 返回。
2. 验证空态/失败态（断网或清 token）。
3. 截图：

```bash
./scripts/screenshot.sh <page>-<state>
```

最后更新 `docs/parity-plan.md`：

- 任务状态改 `DONE`，行末加日期与 agent。
- `## 变更记录` 加一行：任务 ID、改动文件、验证结果、截图路径。
- 有未完成项或风险，写清楚，不要隐瞒。

## 交付回复模板

```text
任务：P2.x
改动：<文件列表>
验证：preflight 通过 / 截图 <路径>
未完成/风险：<无 或 列表>
```

## 不要做

- 不要实现登录、微信分享、朋友圈、订阅消息、支付。
- 不要为了“更好看”改掉小程序的区块顺序或文案。
- 不要顺手重构无关页面。
- 不要在验收阶段改代码。
