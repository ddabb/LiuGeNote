# LgNote 离线文档应用 · 项目文档

参考 Web 静态站发布方案（`F:\SelfJob\vercel-ci` 的 `publish.js`），为 HarmonyOS 打造的
**离线内容应用脚手架**：写作侧只维护 Markdown，构建侧一键渲染为应用内离线数据，
应用侧提供 标签 / 分类 / 文章 的完整浏览与跳转体验。

## 文档目录

| 文档 | 说明 |
|---|---|
| [requirements.md](requirements.md) | 需求说明：背景、功能范围、页面清单、验收标准 |
| [design.md](design.md) | 设计说明：目录结构、rawfile 数据格式、页面导航、关键决策 |
| [publish-workflow.md](publish-workflow.md) | 发布流程：publish.js 的能力、用法、扩展指南 |
| [markdown-rendering.md](markdown-rendering.md) | Markdown 渲染选型：lv-markdown-in 接入与配置 |
| [元宝建议.md](元宝建议.md) | 产品差异化建议与逐项可行性评估、路线图 |

## 一句话架构

```
content/mdfiles/*.md --(node scripts/publish.js)--> entry/src/main/resources/rawfile/*.json|md
                                                        |
                                                        v
                                            HarmonyOS 应用（离线读取 rawfile）
      首页(文章列表+自述说明) / 全文搜索 / 标签与分类列表详情 / 文章详情(阅读画布+导出分享) / 设置(主题·字体·阅读偏好)
```

## 快速开始

```bash
# 1. 写作：把带 front-matter 的 md 放进 content/mdfiles/
# 2. 发布：渲染到 rawfile（纯 Node，无第三方依赖）
node scripts/publish.js
# 3. 构建 & 运行应用
#    使用 DevEco Studio 打开工程构建，或使用本 CLI 的 build_project / start_app
```

## 演示内容说明

`content/mdfiles/` 中的演示文档，均取材于**本脚手架建设过程中遇到的真实问题**：
工程与环境配置、ArkTS 严格模式、rawfile 资源读取、中文与编码、页面跳转传参、
Markdown 离线渲染选型等。它们既是示例内容，也是踩坑记录。
