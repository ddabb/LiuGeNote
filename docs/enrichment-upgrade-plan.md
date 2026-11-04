# 应用丰富性升级方案（A1+B1+B3+C1+D1）

> 背景：应用市场审核反馈 —— "应用仅有 ArkTS 知识内容文字罗列，展现形式与网页浏览体验较为接近，难以满足用户对应用的丰富性需求"。
> 本方案从信息架构、交互玩法、系统能力、视觉呈现四个维度组合发力，将"内容阅读网页"升级为"具备应用化体验的学习工具"。

## 总览

| 编号 | 维度 | 内容 | 主要落点 |
|------|------|------|----------|
| A1 | 信息架构 | 底部三 Tab 应用框架（学习 / 知识库 / 我的） | `pages/Index.ets` 重构 |
| B1 | 交互玩法 | 知识问答（每日一题、随机练习、判分、错题本） | `scripts/publish.js` + `QuizManager` + `QuizPage` + `WrongBookPage` |
| B3 | 交互玩法 | 成就徽章系统（阅读/答题/坚持三类，数据全部本地派生） | `AchievementManager` + 我的页成就区 |
| C1 | 系统能力 | Form Kit 桌面互动卡片（每日知识点，点击直达文章） | `EntryFormAbility` + `DailyTipCard` |
| D1 | 视觉呈现 | 学习页信息流改版（阅读仪表盘 / 分类宫格 / 每日推荐 Banner） | `StudyTab` + `StatsDashboard` |

## A1 底部三 Tab 架构

`Index.ets` 由"单页列表"重构为 `Tabs({ barPosition: BarPosition.End })` 容器，自定义 TabBar（主题色驱动）：

- **学习**（默认选中）：D1 改版后的信息流 —— 阅读仪表盘、每日推荐 Banner、继续阅读、分类宫格、每日一题入口、文章流。
- **知识库**：分类卡片流（含篇数徽章，点击进分类详情）+ 标签云（点击进标签详情）+ 全部文章列表。
- **我的**：阅读统计仪表盘、成就徽章墙、错题本入口、设置入口。

约束：
- 原有独立页面（搜索/设置/标签/分类/详情）保留路由不变，Tab 内作为入口跳转。
- 宽屏仍受 `CONTENT_MAX_WIDTH` 约束。
- TabBar 图标采用文字 + 圆点指示器方案（不依赖不确定的 sys.symbol 资源）。

## B1 知识问答

### 数据管线（scripts/publish.js 扩展）

- 从每篇 Markdown 的二级标题（`##`）小节中自动提取问答题：
  - 题干：小节标题（去 `##` 前缀，补全为"《文章标题》中提到：xxx"上下文）。
  - 答案要点：小节正文首句/关键结论行。
  - 出题形式：单选题 —— 正确项取自本小节结论，干扰项取同分类其它小节结论（保证语义相近、难度真实）。
- 产物：`rawfile/quiz.json` —— `{ generatedAt, questions: [{ id, slug, category, question, options[4], answer(index), explanation }] }`。
- 小节不足 4 个候选干扰项时降级跳过该题，保证题目质量；id 用 `q1..qN` 稳定编号。

### 应用侧

- `core/QuizManager.ets`：加载 quiz.json；preferences 持久化答题记录（累计答题数、答对数、每日一题完成日期、错题 slug 列表）。
- `pages/QuizPage.ets`：答题界面 —— 单题卡片、四选项点选、即时判分（对绿错红 + 解析）、进度指示、结算页（得分 + 再来一组）。
- `pages/WrongBookPage.ets`：错题本 —— 错题重练，答对自动移出错题本。
- 每日一题：按日期哈希从题库选题，学习页卡片入口，完成当日题后显示已打卡状态。

## B3 成就徽章

`core/AchievementManager.ets`：纯本地派生（阅读数据来自 `ReadingTracker`，答题数据来自 `QuizManager`，无需新增存储）。

成就定义（10 枚，三档梯度）：

| 成就 | 条件 |
|------|------|
| 初窥门径 / 渐入佳境 / 博览群书 | 读完 1 / 5 / 15 篇 |
| 坚持之始 / 七日之约 | 连续阅读 1 / 7 天 |
| 小试牛刀 / 百题斩 | 累计答题 10 / 100 题 |
| 每日精进 | 完成一次每日一题 |
| 学而不厌 | 累计阅读 60 分钟 |

- 徽章解锁状态即时计算；首次达成时间持久化（preferences，用于展示"解锁于 xx"）。
- 我的页徽章墙：2 列 Grid，未解锁置灰 + 锁标，已解锁展示达成时间。
- 结算页答满 10 题后跳转提示可查看新成就。

## C1 桌面每日知识点卡片（Form Kit）

- `EntryFormAbility`（`FormExtensionAbility`）：
  - `onAddForm`/`onUpdateForm` 读取 `rawfile/index.json`，按"当天在文章列表中的序号（日期哈希取模）"选出每日文章，推送 `{ title, description, dateLabel, slug }`。
  - `formProvider.updateForm` 定时刷新（`updateDuration: 48` ≈ 24h，兜底 `scheduledUpdateTime`）。
- `DailyTipCard.ets`（ArkTS 动态卡片，2x2）：
  - `@LocalStorageProp` 绑定数据；显示"每日知识点"标签 + 日期 + 文章标题 + 摘要。
  - `postCardAction` router 事件拉起 EntryAbility，携带 `slug` 参数直达文章详情（EntryAbility `onNewWant`/`onCreate` 解析后路由）。
- `module.json5` 注册 `extensionAbilities`（type: form）+ `resources/base/profile/form_config.json`。
- 无需新增权限（卡片为本地静态数据推送，无网络）。

## D1 学习页信息流改版

学习 Tab 自上而下：

1. **阅读仪表盘（StatsDashboard）**：三格横排 —— 今日阅读分钟 / 连续天数 / 已读篇数（附总篇数分母），卡片化 + 主题色数字，数据来自 `ReadingTracker.getStats`。
2. **每日推荐 Banner**：日期哈希选文，主题色渐变大卡（标题 + 摘要 + "今日推荐"角标），点击直达文章。
3. **继续阅读卡片**：沿用现有进度环设计（Kindle 式续读）。
4. **每日一题入口**：题库总数 + 当日完成状态，点击进 QuizPage。
5. **分类宫格**：2 列 Grid，分类名 + 篇数，点击进分类详情页。
6. **文章流**：沿用 `ArticleCard`（refreshTick 机制保留）。

## 文件清单

新增：
- `entry/src/main/ets/core/QuizManager.ets`
- `entry/src/main/ets/core/AchievementManager.ets`
- `entry/src/main/ets/core/DailyPick.ets`（日期哈希选文/选题，学习页与桌面卡片共用）
- `entry/src/main/ets/common/StatsDashboard.ets`（学习/我的共用的仪表盘组件）
- `entry/src/main/ets/pages/QuizPage.ets`
- `entry/src/main/ets/pages/WrongBookPage.ets`
- `entry/src/main/ets/pages/tabs/StudyTab.ets` / `LibraryTab.ets` / `MineTab.ets`
- `entry/src/main/ets/entryformability/EntryFormAbility.ets`
- `entry/src/main/ets/widget/pages/DailyTipCard.ets`
- `entry/src/main/resources/base/profile/form_config.json`

修改：
- `scripts/publish.js` —— 生成 quiz.json
- `entry/src/main/ets/model/ArticleModels.ets` —— Quiz 模型 + KEY_PENDING_ARTICLE 常量
- `entry/src/main/ets/pages/Index.ets` —— 重构为三 Tab
- `entry/src/main/ets/common/AppTheme.ets` —— 新增 paletteFromPrefs（卡片进程直读主题色，不依赖 AppStorage）
- `entry/src/main/ets/entryability/EntryAbility.ets` —— Quiz/Achievement 初始化接线 + 解析卡片拉起参数（onCreate/onNewWant 暂存 slug）
- `entry/src/main/module.json5` —— 注册 FormExtensionAbility
- `entry/src/main/resources/base/profile/main_pages.json` —— 注册 QuizPage/WrongBookPage
- `resources/base/element/string.json` —— 卡片名称等字符串资源

## 实施状态（2026-11-04 完成）

- 全部 A1/B1/B3/C1/D1 项落地；BUG-001 同步修复。
- `node scripts/publish.js`：生成 quiz.json 共 59 题（16 篇文章 / 5 分类 / 60 标签）。
- ArkTS 静态检查（arkts_check）全部通过；`build_project` BUILD SUCCESSFUL（1 min 28 s）。
- 模拟器（CopybookPad）安装启动正常。
- 待人工验收：桌面长按添加「每日知识点」2x2 卡片，确认展示当日文章、点击直达详情（验收口径第 4 条）。

## 验收口径

1. 底部三 Tab 可切换，学习页含仪表盘/每日推荐/分类宫格；知识库页可跳分类/标签详情；我的页含统计、成就墙、错题本、设置入口。
2. 每日一题可答题、判分、记错题；错题本可重练移除。
3. 成就随阅读/答题数据即时点亮。
4. 桌面添加"每日知识点"2x2 卡片，展示当日文章，点击拉起应用直达该文章。
5. `node scripts/publish.js` 生成 quiz.json；构建通过，真机/模拟器运行正常。

## 问题修复记录

### BUG-001 详情页代码块复制失败（2026-11-04）

- 复现路径：首页 → 文章详情页 → 点击代码块"复制"按钮。
- 现象：提示"复制失败，请检查setCodeListener接口实现"，剪贴板无内容。
- 根因：`@luvi/lv-markdown-in@3.4.5` 因系统隐私策略调整不再代宿主写剪贴板，需宿主经 `MarkdownController.setCodeCopyListener(event: (text: string) => void)` 注册监听并自行实现复制逻辑；宿主未注册，引擎仅弹失败提示。
- 修复（`entry/src/main/ets/pages/ArticleDetailPage.ets`）：
  - 新增 `import { BusinessError, pasteboard } from '@kit.BasicServicesKit'`。
  - `applyMarkdownStyles()` 链式注册 `setCodeCopyListener`；同源问题一并注册 `setTextSelectionCopyListener`（3.4.0+ 跨文本选择复制接口，未注册时同样弹"复制失败，请检查 setTextSelectionCopyListener 接口实现"）。
  - 新增 `copyToClipboard(text)`：`pasteboard.createData(MIMETYPE_TEXT_PLAIN, text)` → `getSystemPasteboard().setData()`，成功提示"已复制到剪贴板"，异常提示重试。
- 验证口径：详情页点代码块"复制"提示成功且粘贴可得代码全文；长按跨文本选择后"复制"同理生效。
