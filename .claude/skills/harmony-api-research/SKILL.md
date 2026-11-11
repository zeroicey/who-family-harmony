---
name: harmony-api-research
description: Use when unsure which HarmonyOS kit/API/component to use, or when evaluating newer HarmonyOS features for hcyj-harmony. Researches official docs via cormorant MCP, checks API availability against compatible SDK 20 / target 24, and records decisions in docs/tech-notes.md.
---

# 鸿蒙 API / 技术选型检索

先读 `docs/tech-notes.md` 的既有结论，避免重复调研。

## 检索

优先用 cormorant MCP（项目 `.mcp.json` / Codex 全局已配置）：

- `search`：`query` + `category: "docs"`，需要最新信息时加 `freshness: "year"`。
- `fetch`：取官方文档正文；遇到反爬/超时，改用搜索摘要或社区镜像，并在结论里标注来源等级。
- `status`：确认检索源健康；`meta.degraded` / `meta.failed_sources` 不为空时不要假装成功。

没有 MCP 的 agent 用 WebSearch / WebFetch，结论同样要给出 URL。

## 判定规则

1. 先查官方文档（`developer.huawei.com`），再看社区文章。
2. 必须确认"起始版本"（API x / HarmonyOS x.y）。
3. 与本项目约束对比：
   - `compatibleSdkVersion 6.0.0(20)`
   - `targetSdkVersion 6.1.1(24)`
   - API > 20 必须 `canIUse` / 版本判断 + 降级，或由负责人决定抬高 compatible。
4. 判断是否破坏"与小程序一模一样"：
   - 会改变核心五 Tab 视觉/交互的，默认不用。
   - 只影响四个增强页的，可作为可选项，需版本守卫。
5. 运行时零第三方依赖：优先系统 Kit，不新增库。

## 输出

把结论追加到 `docs/tech-notes.md`：

```text
| 能力 | 起始 API | 采用/不采用/可选 | 理由 |
```

并附：

- 官方链接
- 起始版本
- 兼容策略（旧设备怎么办）
- 对验收的影响

## 红线

- 不凭记忆报 API 版本；查不到就标 `UNVERIFIED`。
- 不因为"新"就升级 SDK、抬高 compatible、替换路由/状态管理。
- 不引入第三方 UI 库、Markdown 库、网络库。
- 不在核心页面使用 HDS / UIDesignKit 重做视觉。
