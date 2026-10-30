/**
 * 首页：全部文章列表 + 页头搜索/设置入口 + 标签/分类快捷入口。
 * 离线数据来自 rawfile（DataRepository），无网络请求。
 * 主题色与字体偏好由 AppStorage 驱动（@StorageProp），设置页修改即时生效。
 * 页头动作区（搜索/设置）收纳低频入口；应用自述说明条点明内容定位。
 */
import { ArticleCard } from '../common/ArticleCard';
import { HeaderAction, PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { FontRegistry } from '../common/FontRegistry';
import { DataRepository } from '../data/DataRepository';
import { ArticleDetailParams, ArticleMeta, CategoryDetailParams, TagDetailParams } from '../model/ArticleModels';

@Entry
@Component
struct Index {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State articles: ArticleMeta[] = [];
  @State totalCount: number = 0;
  @State tagCount: number = 0;
  @State categoryCount: number = 0;
  @State loadError: string = '';

  private headerActions: HeaderAction[] = [];

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    this.buildHeaderActions();
    // 首页为应用入口：注册内置字体一次（幂等），供正文渲染与设置页预览使用
    FontRegistry.registerAll(this.getUIContext());
    try {
      const repo = DataRepository.getInstance();
      this.articles = repo.getAllArticles();
      this.totalCount = this.articles.length;
      const taxonomy = repo.getTaxonomy();
      this.tagCount = taxonomy.tags.length;
      this.categoryCount = taxonomy.categories.length;
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  /** 页头动作：全文搜索 / 设置（低频入口收纳，不占列表首屏） */
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
          title: 'LgNote 离线笔记',
          subtitle: `共 ${this.totalCount} 篇 · 纯离线内容`,
          actions: this.headerActions
        })

        // 快捷入口：标签 / 分类
        Row({ space: 10 }) {
          this.entryChip('标签', this.tagCount, () => {
            this.gotoTagList();
          })
          this.entryChip('分类', this.categoryCount, () => {
            this.gotoCategoryList();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 8 })

        if (this.loadError !== '') {
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
          .padding(24)
          .width('100%')
        } else {
          Scroll() {
            Column({ space: 10 }) {
              // 应用自述：点明本应用"记录自己诞生"的内容定位（信息说明条）
              Column({ space: 3 }) {
                Text('应用自述')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.palette().primaryDeep)
                Text(`这个应用会记录自己的诞生 —— 下方 ${this.totalCount} 篇构建手记即它的出生证明`)
                  .fontSize(11)
                  .fontColor(this.palette().desc)
                  .lineHeight(16)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(this.palette().tint)
              .borderRadius(12)

              ForEach(this.articles, (article: ArticleMeta) => {
                ArticleCard({
                  article: article,
                  onTap: () => {
                    this.gotoArticleDetail(article.slug);
                  },
                  onTagTap: (tag: string) => {
                    this.gotoTagDetail(tag);
                  },
                  onCategoryTap: (category: string) => {
                    this.gotoCategoryDetail(category);
                  }
                })
              }, (article: ArticleMeta) => article.slug)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 6, bottom: 24 })
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1)
          .width('100%')
        }
      }
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      .width('100%')
      .height('100%')
    }
    .backgroundColor(this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 快捷入口胶囊（主题色驱动） */
  @Builder
  entryChip(label: string, count: number, onTap: () => void) {
    Row({ space: 6 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().primaryDeep)
      Text(`${count}`)
        .fontSize(12)
        .fontColor(this.palette().primarySoft)
        .padding({ left: 8, right: 8, top: 1, bottom: 1 })
        .backgroundColor(this.palette().tint)
        .borderRadius(9)
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(this.palette().cardBg)
    .borderRadius(20)
    .onClick(() => onTap())
  }

  /** 跳转：全文搜索 */
  private gotoSearch(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SearchPage' });
  }

  /** 跳转：设置 */
  private gotoSettings(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/SettingsPage' });
  }

  /** 跳转：文章详情（slug 编码传递） */
  private gotoArticleDetail(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  /** 跳转：标签列表 */
  private gotoTagList(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagListPage' });
  }

  /** 跳转：标签详情 */
  private gotoTagDetail(tag: string): void {
    const params: TagDetailParams = { tag: encodeURIComponent(tag) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagDetailPage', params: params });
  }

  /** 跳转：分类列表 */
  private gotoCategoryList(): void {
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryListPage' });
  }

  /** 跳转：分类详情 */
  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
