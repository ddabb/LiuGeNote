/**
 * 知识库 Tab：分类卡片流（含篇数）→ 标签云 → 全部文章列表。
 * 分类/标签数据来自 rawfile/taxonomy.json；跳转沿用既有路由页。
 * 数据刷新：Index.onPageShow 自增 refreshTick，经 @Prop @Watch 触发重载。
 */
import { ArticleCard } from '../../common/ArticleCard';
import { PageHeader } from '../../common/PageHeader';
import { AppTheme, ThemePalette } from '../../common/AppTheme';
import { DataRepository } from '../../data/DataRepository';
import {
  ArticleDetailParams,
  ArticleMeta,
  CategoryDetailParams,
  TagDetailParams,
  TaxonomyItem
} from '../../model/ArticleModels';

@Component
export struct LibraryTab {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @Prop @Watch('onTickChange') refreshTick: number = 0;
  @State loadError: string = '';
  @State articles: ArticleMeta[] = [];
  @State categories: TaxonomyItem[] = [];
  @State tags: TaxonomyItem[] = [];

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    this.reload();
  }

  private onTickChange(): void {
    this.reload();
  }

  private reload(): void {
    try {
      const repo = DataRepository.getInstance();
      this.articles = repo.getAllArticles();
      this.categories = repo.getTaxonomy().categories;
      this.tags = repo.getTaxonomy().tags;
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  build() {
    Column() {
      PageHeader({
        title: '知识库',
        subtitle: `${this.categories.length} 分类 · ${this.tags.length} 标签 · ${this.articles.length} 篇`
      })
      if (this.loadError !== '') {
        Column({ space: 8 }) {
          Text('数据加载失败')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.palette().error)
          Text(this.loadError)
            .fontSize(13)
            .fontColor(this.palette().desc)
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width('100%')
        .padding(24)
      } else {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.categories, (c: TaxonomyItem) => {
              this.categoryRow(c)
            }, (c: TaxonomyItem) => `${c.name}_${this.refreshTick}`)

            Column({ space: 8 }) {
              Text('标签')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.palette().meta)
                .width('100%')
              Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                ForEach(this.tags, (t: TaxonomyItem) => {
                  Text(`# ${t.name} ${t.count}`)
                    .fontSize(11)
                    .fontColor(this.palette().desc)
                    .padding({ left: 9, right: 9, top: 5, bottom: 5 })
                    .backgroundColor(this.palette().cardBg)
                    .borderRadius(12)
                    .margin({ right: 6, bottom: 6 })
                    .onClick(() => {
                      this.gotoTagDetail(t.name);
                    })
                }, (t: TaxonomyItem) => t.name)
              }
              .width('100%')
            }
            .width('100%')

            Text('全部文章')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.palette().meta)
              .width('100%')

            ForEach(this.articles, (article: ArticleMeta) => {
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
            }, (article: ArticleMeta) => `${article.slug}_${this.refreshTick}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 24 })
          .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 分类行：分类名 + 篇数 + 进入箭头 */
  @Builder
  private categoryRow(c: TaxonomyItem) {
    Row({ space: 10 }) {
      Column({ space: 3 }) {
        Text(c.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.palette().primaryDeep)
        Text(`共 ${c.count} 篇文章`)
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('›')
        .fontSize(18)
        .fontColor(this.palette().meta)
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor(this.palette().cardBg)
    .border({ width: 1, color: this.palette().tint })
    .onClick(() => {
      this.gotoCategoryDetail(c.name);
    })
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
