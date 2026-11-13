/**
 * 学习 Tab（应用默认首页）：D1 信息流改版。
 * 自上而下：阅读仪表盘 → 每日推荐 Banner（日期哈希选文）→ 继续阅读（Kindle 式续读）
 * → 每日一题入口 → 分类速览宫格 → 全部文章流。
 * 数据刷新：Index.onPageShow 自增 refreshTick，经 @Prop @Watch 触发重载；
 * 文章流走 List + LazyForEach(ArticleDataSource) 懒加载，刷新经 dataSource.reload() 通知。
 */
import { ArticleCard } from '../../common/ArticleCard';
import { ArticleDataSource } from '../../common/ArticleDataSource';
import { HeaderAction, PageHeader } from '../../common/PageHeader';
import { AppTheme, ThemePalette } from '../../common/AppTheme';
import { StatsDashboard } from '../../common/StatsDashboard';
import { DailyPick } from '../../core/DailyPick';
import { ReadingStats, ReadingTracker } from '../../core/ReadingTracker';
import { QuizManager } from '../../core/QuizManager';
import { DataRepository } from '../../data/DataRepository';
import {
  ArticleDetailParams,
  ArticleMeta,
  CategoryDetailParams,
  estReadingMinutes,
  QuizPageParams,
  TagDetailParams,
  TaxonomyItem
} from '../../model/ArticleModels';

/** 分类宫格两列布局的成对单元格载体 */
class CategoryPair {
  first: TaxonomyItem | undefined = undefined;
  second: TaxonomyItem | undefined = undefined;
}

@Component
export struct StudyTab {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @Prop @Watch('onTickChange') refreshTick: number = 0;
  @State loadError: string = '';
  @State articles: ArticleMeta[] = [];
  @State categories: TaxonomyItem[] = [];
  @State stats: ReadingStats = new ReadingStats();
  @State dailyMeta: ArticleMeta | undefined = undefined;
  @State continueMeta: ArticleMeta | undefined = undefined;
  @State continuePct: number = 0;
  @State quizTotal: number = 0;
  @State dailyDone: boolean = false;

  private headerActions: HeaderAction[] = [];
  /** 懒加载数据源：与页面同生命周期，禁止重新赋值（LazyForEach 约束） */
  private dataSource: ArticleDataSource = new ArticleDataSource();

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    this.buildHeaderActions();
    this.reload();
  }

  /** 父页 onPageShow 触发：重载统计/推荐/续读/打卡状态 */
  private onTickChange(): void {
    this.reload();
  }

  private reload(): void {
    try {
      const repo = DataRepository.getInstance();
      this.articles = repo.getAllArticles();
      this.categories = repo.getTaxonomy().categories;
      this.quizTotal = QuizManager.getBank().total;
      this.dailyDone = QuizManager.isDailyDone();
      this.stats = ReadingTracker.getStats(this.articles);
      const dailyIdx: number = DailyPick.pickIndex(this.articles.length, DailyPick.todayKey());
      this.dailyMeta = dailyIdx >= 0 ? this.articles[dailyIdx] : undefined;
      this.loadContinue();
      this.dataSource.reload(this.articles);
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  /** 继续阅读目标（进度 3%-96% 间才展示） */
  private loadContinue(): void {
    this.continueMeta = undefined;
    this.continuePct = 0;
    const lastSlug: string = ReadingTracker.getLastSlug();
    if (lastSlug === '') {
      return;
    }
    const meta: ArticleMeta | undefined = DataRepository.getInstance().getArticleMeta(lastSlug);
    const pct: number = ReadingTracker.getProgress(lastSlug);
    if (meta !== undefined && pct >= 3 && pct < ReadingTracker.DONE_PCT) {
      this.continueMeta = meta;
      this.continuePct = pct;
    }
  }

  /** 页头动态副标题：总篇数 + 已读数 + 连续天数 */
  private buildSubtitle(): string {
    let subtitle: string = `共 ${this.articles.length} 篇`;
    if (this.stats.doneCount > 0) {
      subtitle += ` · 已读 ${this.stats.doneCount}`;
    }
    if (this.stats.streakDays > 0) {
      subtitle += ` · 连续 ${this.stats.streakDays} 天`;
    }
    return subtitle;
  }

  /** 页头动作：全文搜索 / 设置 */
  private buildHeaderActions(): void {
    const search: HeaderAction = new HeaderAction();
    search.icon = $r('sys.symbol.magnifyingglass');
    search.onClick = () => {
      this.gotoSearch();
    };
    const settings: HeaderAction = new HeaderAction();
    settings.icon = $r('sys.symbol.gearshape');
    settings.onClick = () => {
      this.gotoSettings();
    };
    this.headerActions = [search, settings];
  }

  build() {
    Column() {
      Column() {
        PageHeader({
          title: '行知',
          subtitle: this.buildSubtitle(),
          actions: this.headerActions
        })
      }
      .width('100%')
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      if (this.loadError !== '') {
        this.errorView()
      } else {
        List({ space: 12 }) {
          ListItem() {
            StatsDashboard({
              todayMinutes: Math.round(this.stats.todaySeconds / 60),
              streakDays: this.stats.streakDays,
              doneCount: this.stats.doneCount,
              totalCount: this.stats.totalCount
            })
          }

          if (this.dailyMeta !== undefined) {
            ListItem() {
              this.dailyBanner(this.dailyMeta)
            }
          }

          if (this.continueMeta !== undefined) {
            ListItem() {
              this.continueCard(this.continueMeta, this.continuePct)
            }
          }

          ListItem() {
            this.dailyQuizEntry()
          }

          if (this.categories.length > 0) {
            ListItem() {
              this.categoryGrid()
            }
          }

          LazyForEach(this.dataSource, (article: ArticleMeta) => {
            ListItem() {
              ArticleCard({
                article: article,
                onTap: () => {
                  this.gotoArticle(article.slug);
                },
                onTagTap: (tag: string) => {
                  this.gotoTagDetail(tag);
                },
                onCategoryTap: (category: string) => {
                  this.gotoCategoryDetail(category);
                }
              })
            }
          }, (article: ArticleMeta) => article.slug)
        }
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 16, right: 16, top: 6, bottom: 24 })
        .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 数据加载失败视图（rawfile 未生成等场景） */
  @Builder
  private errorView() {
    Column({ space: 8 }) {
      Text('数据加载失败')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().error)
      Text(this.loadError)
        .fontSize(13)
        .fontColor(this.palette().desc)
      Text('请先执行 node scripts/publish.js 生成 rawfile 数据，再重新构建应用')
        .fontSize(12)
        .fontColor(this.palette().empty)
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .width('100%')
    .padding(24)
  }

  /** 每日推荐 Banner：日期哈希选文 + 主题色描边大卡 */
  @Builder
  private dailyBanner(meta: ArticleMeta) {
    Column({ space: 8 }) {
      Row() {
        Text('今日推荐')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(9)
          .backgroundColor(this.palette().primary)
        Text(DailyPick.dateLabel())
          .fontSize(10)
          .fontColor(this.palette().primary)
        Text('›')
          .fontSize(18)
          .fontColor(this.palette().primary)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(meta.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryDeep)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
      Text(meta.description)
        .fontSize(12)
        .fontColor(this.palette().desc)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(14)
    .backgroundColor(this.palette().tint)
    .border({ width: 1, color: this.palette().primary })
    .onClick(() => {
      this.gotoArticle(meta.slug);
    })
  }

  /** 继续阅读卡片：进度环 + 标题 + 剩余分钟（Kindle 式续读） */
  @Builder
  private continueCard(meta: ArticleMeta, pct: number) {
    Row({ space: 14 }) {
      Progress({ value: pct, total: 100, type: ProgressType.Ring })
        .width(46)
        .height(46)
        .color(this.palette().primary)
      Column({ space: 3 }) {
        Text('继续阅读')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.palette().primary)
        Text(meta.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryDeep)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`${meta.category} · 已读 ${pct}% · 剩约 ${this.remainMinutes(meta, pct)} 分钟`)
          .fontSize(11)
          .fontColor(this.palette().meta)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .border({ width: 1, color: this.palette().tint })
    .onClick(() => {
      this.gotoArticle(meta.slug);
    })
  }

  /** 继续阅读剩余分钟（按未读比例折算，至少 1 分钟） */
  private remainMinutes(meta: ArticleMeta, pct: number): number {
    return Math.max(1, Math.round(estReadingMinutes(meta.wordCount) * (100 - pct) / 100));
  }

  /** 每日一题入口：题库规模 + 当日打卡状态 */
  @Builder
  private dailyQuizEntry() {
    Row({ space: 12 }) {
      Column({ space: 3 }) {
        Text('每日一题')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryDeep)
        Text(this.quizTotal > 0
          ? (this.dailyDone ? '今日已完成，明天再来' : `题库 ${this.quizTotal} 题，今日还没打卡`)
          : '题库生成中，先去读篇文章吧')
          .fontSize(11)
          .fontColor(this.palette().meta)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(this.dailyDone ? '已打卡' : '去答题')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.dailyDone ? this.palette().meta : '#FFFFFF')
        .padding({ left: 12, right: 12, top: 7, bottom: 7 })
        .borderRadius(14)
        .backgroundColor(this.dailyDone ? this.palette().tint : this.palette().primary)
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .onClick(() => {
      if (this.quizTotal > 0) {
        this.gotoDailyQuiz();
      }
    })
  }

  /** 分类速览宫格：两列布局（分类名 + 篇数，点击进分类详情） */
  @Builder
  private categoryGrid() {
    Column({ space: 10 }) {
      Text('分类速览')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().meta)
        .width('100%')
      ForEach(this.categoryPairs(), (pair: CategoryPair) => {
        Row({ space: 10 }) {
          if (pair.first !== undefined) {
            this.categoryCell(pair.first)
          }
          if (pair.second !== undefined) {
            this.categoryCell(pair.second)
          } else {
            Column()
              .layoutWeight(1)
          }
        }
        .width('100%')
      }, (pair: CategoryPair) => `${pair.first?.name ?? ''}_${pair.second?.name ?? ''}`)
    }
    .width('100%')
  }

  /** 分类单元格 */
  @Builder
  private categoryCell(item: TaxonomyItem) {
    Column({ space: 4 }) {
      Text(item.name)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.palette().primaryDeep)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(`${item.count} 篇`)
        .fontSize(11)
        .fontColor(this.palette().primary)
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .border({ width: 1, color: this.palette().tint })
    .onClick(() => {
      this.gotoCategoryDetail(item.name);
    })
  }

  /** 分类两两成对（宫格两列布局用） */
  private categoryPairs(): CategoryPair[] {
    const pairs: CategoryPair[] = [];
    for (let i: number = 0; i < this.categories.length; i += 2) {
      const p: CategoryPair = new CategoryPair();
      p.first = this.categories[i];
      p.second = i + 1 < this.categories.length ? this.categories[i + 1] : undefined;
      pairs.push(p);
    }
    return pairs;
  }

  /* ---------------- 跳转 ---------------- */

  private gotoSearch(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SearchPage' });
  }

  private gotoSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsPage' });
  }

  private gotoDailyQuiz(): void {
    const params: QuizPageParams = { mode: QuizManager.MODE_DAILY };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/QuizPage', params: params });
  }

  private gotoArticle(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  private gotoTagDetail(tag: string): void {
    const params: TagDetailParams = { tag: encodeURIComponent(tag) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagDetailPage', params: params });
  }

  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
