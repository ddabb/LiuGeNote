# 设计说明（Design）

## 1. 工程目录结构

```
lgnote2/                                # HarmonyOS 工程根（bundleName: com.ddabb.lgnote）
├── docs/                               # 需求与设计文档（本目录）
│   ├── README.md                       # 文档索引
│   ├── requirements.md                 # 需求说明
│   ├── design.md                       # 本文件：结构与数据设计
│   ├── publish-workflow.md             # 发布流程与 publish.js 用法
│   ├── markdown-rendering.md           # Markdown 渲染选型（lv-markdown-in）
│   └── 元宝建议.md                      # 产品建议与可行性评估
├── content/
│   └── mdfiles/                        # ★ 内容源：Markdown 文档（带 front-matter，12 篇构建手记）
├── scripts/
│   └── publish.js                      # ★ 发布脚本：md → rawfile（纯 Node 内置模块，零依赖）
├── entry/src/main/
│   ├── ets/
│   │   ├── entryability/EntryAbility.ets   # 应用入口：注入 context、初始化主题偏好
│   │   ├── model/
│   │   │   └── ArticleModels.ets       # 数据模型：ArticleMeta / Taxonomy / SearchResult / 路由参数
│   │   ├── data/
│   │   │   └── DataRepository.ets      # 数据仓库：读 rawfile、缓存、过滤、全文搜索
│   │   ├── common/
│   │   │   ├── AppTheme.ets            # 主题色板(6)/阅读背景(4)/字号行距 + preferences 持久化
│   │   │   ├── FontRegistry.ets        # 内置字体注册（rawfile TTF → 双通道）与沙箱供给
│   │   │   ├── PageHeader.ets          # 通用页头：返回 + 标题 + 右侧图标动作/⋯菜单
│   │   │   ├── ToastUtil.ets           # 轻提示（UIContext.getPromptAction）
│   │   │   └── ArticleCard.ets         # 通用文章卡片组件（各列表页复用）
│   │   ├── core/pdf/
│   │   │   └── ArticlePdfExporter.ets  # PDF 导出（@kit.PDFKit 从零构建 A4）/ MD 导出 / 分享
│   │   └── pages/
│   │       ├── Index.ets               # 首页：文章列表 + 搜索/设置入口 + 自述说明条
│   │       ├── SearchPage.ets          # 全文搜索页（内存语料即时检索）
│   │       ├── SettingsPage.ets        # 设置页：主题色/字体/阅读背景/字号/行距
│   │       ├── TagListPage.ets         # 标签列表页
│   │       ├── TagDetailPage.ets       # 标签详情页
│   │       ├── CategoryListPage.ets    # 分类列表页
│   │       ├── CategoryDetailPage.ets  # 分类详情页
│   │       └── ArticleDetailPage.ets   # 文章详情页：阅读画布 + 导出/分享（⋯菜单）
│   └── resources/rawfile/              # ★ publish.js 的输出目标（应用离线数据）
│       ├── index.json                  # 文章元数据索引（含 meta.totalFiles）
│       ├── taxonomy.json               # 标签/分类统计
│       ├── articles/<fileId>.md        # 每篇文章正文（front-matter 已剥离）
│       └── font/                       # 内置 TTF 字体（思源黑体/霞鹜文楷）
```

## 2. Markdown 文档源约定（content/mdfiles/*.md）

```markdown
---
title: 文章标题（缺省时取文件名去扩展名）
category: 分类名（缺省 "未分类"）
tags: [标签1, 标签2]        # 或逗号分隔字符串
description: 摘要（缺省取正文前 80 字）
---

# 正文（Markdown）...
```

- front-matter 解析规则对标 `publish.js`：`---` 围栏、YAML 子集（title/category/tags/description）。
- 正文字数统计：剥离所有空白字符后计数（与 publish.js 的 wordCount 口径一致）。
- slug：文件名去 `.md` 并清洗非法字符（`/ \ ? % * : | " < >` → `-`），是文章稳定 ID。

## 3. rawfile 数据格式（publish.js 输出）

### 3.1 `index.json` —— 文章索引

```json
{
  "meta": { "generatedAt": "ISO时间", "totalFiles": 12, "generator": "lgnote publish.js" },
  "files": [
    {
      "slug": "arkts-严格模式踩坑",
      "fileId": "0feb380f",
      "title": "…", "description": "…",
      "category": "工程与语言",
      "tags": ["ArkTS", "严格模式"],
      "wordCount": 1234,
      "createTime": "…", "updateTime": "…",
      "order": 1
    }
  ]
}
```

- `files` 按 `updateTime` 降序（对标 publish.js 排序），`order` 为序号。
- `slug`：中文名，用于路由与展示（稳定 ID）；`fileId`：slug 的 FNV-1a 32 位哈希（8 位十六进制），
  是正文文件的存储 ID —— 规避 rawfile 中文路径在不同设备上的兼容性风险（本项目踩坑预防）。
- slug 撞车与 fileId 哈希撞车在发布期直接失败（退出码 1）。

### 3.2 `taxonomy.json` —— 标签/分类统计

```json
{
  "generatedAt": "…",
  "tags":       [{ "name": "ArkTS", "count": 3 }],
  "categories": [{ "name": "工程与语言", "count": 4 }]
}
```

### 3.3 `articles/<fileId>.md` —— 正文

front-matter 剥离后的纯 Markdown 正文，应用内交 `@luvi/lv-markdown-in` 引擎解析渲染。

## 4. 页面导航设计

```
                ┌──────────────────┐
                │ Index 首页        │◄──────────────────┐
                │ 文章列表+自述说明  │                   │
                └─┬────┬────┬────┬─┘                   │
        pushUrl   │    │    │    │ (页头动作：搜索/设置)   │
   ┌──────────────┘    │    │    └──────────┐          │
   ▼                   ▼    ▼               ▼          │
┌───────────┐  ┌──────────────┐ ┌──────────────┐ ┌───────────┐
│TagListPage│  │CategoryList  │ │SearchPage    │ │SettingsPage│
│标签列表    │  │Page 分类列表 │ │全文搜索       │ │主题/阅读偏好│
└─────┬─────┘  └──────┬───────┘ └──────┬───────┘ └───────────┘
      │ pushUrl(tag)  │ pushUrl(cat)   │ pushUrl(slug)
      ▼               ▼                ▼
┌─────────────┐ ┌────────────────┐ ┌──────────────────┐
│TagDetailPage│ │CategoryDetail  │ │ArticleDetailPage │
│标签详情      │ │Page 分类详情   │ │文章详情(阅读画布) │
└──────┬──────┘ └───────┬────────┘ │ ⋯菜单: 导出PDF/MD │
       │ 点击文章卡片     │ 点击卡片    │        /分享      │
       └────────┬───────┴────────────┘                  │
                ▼ pushUrl(slug)                          │
        ArticleDetailPage ◄──────────────────────────────┘
        （文内标签/分类可跳详情；返回键逐级回退）─┘
```

- 路由参数统一为字符串：`{ slug: '…' }` / `{ tag: '…' }` / `{ category: '…' }`，中文参数
  `encodeURIComponent` 编码传递（规避历史踩坑）。
- 页头动作位（`PageHeader.actions`，SymbolGlyph 系统符号）收纳搜索/设置等入口；
  `menuItems` 渲染"⋯"按钮（bindMenu）收纳导出/分享等低频动作。
- 所有页面内容区 `constraintSize({ maxWidth: 720 })` 居中收窄，平板/折叠屏展开态行长可控。

## 5. 应用内数据流

1. `EntryAbility.onCreate`：注入 `context` → `DataRepository.init` + `AppTheme.init`
   （preferences 读取 themeId/fontId/readBgId/textSize/lineSpacing 播种 AppStorage）。
2. `DataRepository`（单例）：rawfile 读取 index/taxonomy 缓存；正文按需加载、LRU 缓存；
   全文搜索首次触发时构建全量小写语料（slug → body），加权计分排序。
3. 阅读偏好（AppStorage + @StorageProp @Watch）驱动 `ArticleDetailPage` 的
   `MarkdownController` 五维配置（文字色/字体/字号/行高/引用代码表格配色），
   暗夜背景附加深色配色补偿；设置页修改即时生效。
4. 导出链路：markdown → `ArticlePdfExporter`（PDF Kit 从零构建 A4 分页，内置字体沙箱化）
   → 系统保存器（DocumentViewPicker 免权限）/ 系统分享面板（ShareKit）。

## 6. 关键技术决策

| 决策点 | 选择 | 理由 |
|---|---|---|
| 内容存储 | rawfile 静态文件 | 离线、随包分发、构建期可校验；对标 Web 静态资源 |
| Markdown 渲染 | `@luvi/lv-markdown-in`（ohpm 注册表依赖） | 70+ 样式 API、代码高亮/LaTeX/Mermaid、worker 解析；替代自研解析器（见 markdown-rendering.md） |
| 主题与阅读偏好 | AppStorage + preferences 持久化 | 页面 @StorageProp 即时刷新；重启经 preferences 恢复 |
| 内置字体 | rawfile TTF + 双通道注册 | FontCollection.loadFontSync（正文）+ Font.registerFont（预览）；沙箱拷贝供 PDF FontInfo |
| PDF 导出 | @kit.PDFKit 从零构建 | 免模板；A4 595×842pt 分页；createDocument→insertBlankPage→deletePage 链路 |
| 全文搜索 | 内存语料 + 加权计分 | 12~600 篇毫秒级；零服务零索引文件；FTS5 属过度设计 |
| 平板适配 | 内容 maxWidth 720 居中 | 行长可控、PocketToolbox 同款方案；双栏待内容量增长 |
| 路由 | `@ohos.router` 多页面 | 每页独立注册（main_pages.json），中文参数编码传递 |
| 构建脚本 | 纯 Node 内置模块 | 零安装成本，任何环境可发布 |
