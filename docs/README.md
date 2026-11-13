# 行知 离线文档应用 · 项目文档

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

## 内容库说明

`content/mdfiles/` 共 928 篇文章、35 个分类、2600+ 标签（2026-11 扩充，应对 AppGallery
复审第 3.5 项"内容丰富度"意见；由 `scripts/import-content.js` 从自有知识库分批导入）。

内容分四层：

| 层 | 分类 | 说明 |
|---|---|---|
| 鸿蒙开发手记 | ArkTS语言与规范 / 状态管理与数据持久化 / 组件进阶与系统能力 / 动画与交互 / 页面与导航 / 数据与渲染 / 性能与调试 / 环境与工程配置 / 发布链路 | 原始 54 篇：脚手架建设过程的真实问题与踩坑记录 |
| 技术进阶 | 后端与API开发 / 系统编程与底层原理 / 云原生与DevOps / 分布式系统 / 服务端架构实践 / 数据库内核与存储 / AI推理与高性能计算 / 金融科技架构 | 服务端与底层技术知识 |
| 考试与学习 | 项目管理知识体系 / 软考综合与备考 / 数据分析 / 教师资格考试 / 英语学习 / 经济学基础与经济师 / 财税与经济法常识 / 公务员与考研 | 备考知识体系 |
| 通识与生活 | 心理学知识 / 营养与健康生活 / 家庭教育与亲子 / 职场与创业 / 数字营销与内容创作 / 家庭理财 / 法律与生活权益 / 认知与思维 / 鸿蒙生态与科技观察 / 安全急救与生活通识 | 通识阅读内容 |

内容红线（导入时已排除）：医疗资质类（疾病营养/心理障碍/疾病管理）、投资建议类（K线/荐股）、
无法核实时效的内容；含 2024+ 年份的文章已加时效标注。

