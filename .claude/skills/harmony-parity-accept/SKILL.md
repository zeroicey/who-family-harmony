---
name: harmony-parity-accept
description: Use when independently verifying the hcyj-harmony parity work against docs/acceptance.md. Read-only acceptance: build/lint gates, page-by-page checks, screenshots, defect severity, and the acceptance report.
---

# 鸿蒙对齐验收

依据 `docs/acceptance.md` 独立验收。**只读**：不改 `entry/`、不改构建配置、不“顺手修复”。

## 开始前

1. 记录代码冻结提交：`git rev-parse HEAD`；确认验收期间无新提交。
2. 读 `AGENTS.md`、`docs/acceptance.md`、`docs/parity-plan.md`。
3. 确认 `entry/src/main/ets/api/env.ets` 已配置可用演示 token 与 DashScope key（不要回显）。
4. 确认设备/模拟器与后端环境，写入报告。

## 门槛检查

```bash
./scripts/preflight.sh
```

- 构建失败、CodeLinter error、密钥/构建产物被跟踪、参考实现被修改 → Blocker。
- Web 图片残留计入性能缺陷（F3 完成后应为 0）。

## 页面走查

1. 按 `docs/acceptance.md` 第 4 节逐页执行。
2. 每页至少截图一张：

```bash
./scripts/screenshot.sh <page>-<state>
```

3. 对照参考实现源码（必要时用微信开发者工具打开 `../who_family_wechat`）核对：
   - 区块顺序、文案、配色、字号层级、间距节奏
   - 交互与状态（加载/空/失败/弹层）
   - 接口行为与数据字段
4. 额外执行：
   - 无 token、401、断网
   - 上传、AI、分页、重复提交
   - 30 个路由各进出两次
   - 长列表滚动/长文本/键盘遮挡

## 缺陷与结论

- 分级：Blocker / Major / Minor（定义见 `docs/acceptance.md` 第 7 节）。
- 每条缺陷必须有：编号、页面、复现步骤、期望、实际、截图。
- 通过规则：Blocker = 0 且 Major = 0；Minor 全部登记。
- 未测项标 `NOT TESTED` 并说明原因。

## 输出

写 `docs/acceptance-report.md`（覆盖上一版），截图放 `docs/acceptance/screenshots/`。报告结构见 `docs/acceptance.md` 第 9 节。

最后只给结论：

```text
结论：通过 / 不通过
Blocker x / Major y / Minor z
报告：docs/acceptance-report.md
```

## 不要做

- 不要修改任何源代码、任务状态或构建配置。
- 不要把“看起来差不多”判为通过。
- 不要接受未登记的偏差。
- 不要因为时间紧跳过异常态和截图。
