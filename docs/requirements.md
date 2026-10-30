# 需求说明（Requirements）

> 对齐 `F:\SelfJob\vercel-ci\publish.js` 的核心能力，迁移到 HarmonyOS 离线应用场景。

## 1. 背景

- 参考项目 `vercel-ci` 的发布链路：`mdfiles/*.md`（front-matter 元数据）→ `publish.js`
  （解析元数据、统计分类/标签、渲染列表页与详情页）→ 静态 HTML 站点。
- 本项目将同一思路落地到 **HarmonyOS 离线应用**：不依赖任何服务器与网络，
  内容在**构建期**由 Node 脚本渲染为 `rawfile` 静态数据，应用**运行期纯本地读取**。

## 2. 功能范围（对标 publish.js）

| vercel-ci（Web） | 本项目（HarmonyOS） | 说明 |
|---|---|---|
| 解析 md front-matter（title/description/category/tags） | `scripts/publish.js` 同样解析 | 含字数统计、时间戳、排序 |
| 生成 `jsons/mdfiles.json`（元数据索引） | `rawfile/index.json` | 文章元数据索引 |
| 生成 taxonomy（分类/标签计数） | `rawfile/taxonomy.json` | 标签与分类统计 |
| EJS 渲染 `tag/`、`category/` 列表+详情 HTML 页 | 由应用内原生页面承担 | 列表/详情页改为 ArkUI 页面 |
| `md2html.js` 正文转 HTML | `rawfile/articles/<slug>.md` + 应用内解析渲染 | 离线原生渲染 |
| SEO/RSS/Sitemap/Excel 等 Web 专属产物 | 不适用（离线应用无 SEO 需求） | 按需扩展，不在本期范围 |

## 3. 页面清单与跳转需求

| 页面 | 内容 | 跳转入口 | 跳转目标 |
|---|---|---|---|
| 首页（文章列表） | 全部文章卡片（标题/描述/分类/标签/字数/时间） | 顶部 Tab：标签、分类 | 文章详情、标签详情、分类详情 |
| 标签列表页 | 全部标签 + 文章计数，按数量降序 | 首页入口 | 标签详情页 |
| 标签详情页 | 该标签下的文章列表 | 标签列表/文章标签点击 | 文章详情页 |
| 分类列表页 | 全部分类 + 文章计数 | 首页入口 | 分类详情页 |
| 分类详情页 | 该分类下的文章列表 | 分类列表/文章分类点击 | 文章详情页 |
| 文章详情页 | front-matter 元信息 + Markdown 正文原生渲染 | 各列表页点击 | 文内标签/分类可继续跳转 |

- 跳转方式：`router.pushUrl`，标签名/分类名/slug 作为页面参数传递。
- 所有页面支持系统返回。

## 4. 非功能需求

1. **离线**：应用不申请网络权限，不访问网络；全部数据来自 `rawfile`。
2. **零依赖构建脚本**：`publish.js` 仅用 Node 内置模块（fs/path），不安装 npm 包，
   保证任何有 Node 的机器都能发布内容。
3. **可扩展**：新增 md 文件后重跑 `node scripts/publish.js` 即完成内容更新；
   文章 slug 稳定（由文件名派生），页面间引用不会因重发布而漂移。
4. **健壮性**：front-matter 缺失字段有默认值（category=未分类、tags=[]、
   description 取正文前 N 字）；非法文件名字符做清洗（对标 `sanitizeFileName`）。

## 5. 演示内容需求

- 演示 md 取材于**本项目建设过程中的真实问题**（环境搭建、ArkTS 严格模式、
  rawfile 读取、编码、路由传参、Markdown 渲染选型等）。
- 覆盖 ≥3 个分类、≥6 篇文章、每篇 2~5 个标签，充分演示列表/详情/交叉跳转。

## 6. 验收标准

1. `node scripts/publish.js` 成功产出 `rawfile/index.json`、`rawfile/taxonomy.json`、
   `rawfile/articles/*.md`，且重跑幂等。
2. 应用构建通过，真机/模拟器启动后无需网络即可浏览全部内容。
3. 首页 → 标签列表 → 标签详情 → 文章详情 → 文内标签/分类 → 对应详情，全链路跳转可达。
4. 首页 → 分类列表 → 分类详情 → 文章详情，全链路跳转可达。
5. 每个列表页的计数与详情页文章数一致（对标 publish.js 的 taxonomy 统计）。
