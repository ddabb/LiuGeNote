/**
 * 分类详情页：展示某分类下的全部文章。
 * 路由参数：{ category: encodeURIComponent 后的分类名 }。
 * 主题色经 @StorageProp 订阅 AppStorage，设置页切换即时刷新。
 */
import { ArticleCard } from '../common/ArticleCard';
import { ArticleDataSource } from '../common/ArticleDataSource';
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { DataRepository } from '../data/DataRepository';
import { ArticleDetailParams, ArticleMeta, CategoryDetailParams, TagDetailParams } from '../model/ArticleModels';

@Entry
@Component
struct CategoryDetailPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State category: string = '';
  @State articles: ArticleMeta[] = [];
  @State loadError: string = '';
  /** 懒加载数据源：与页面同生命周期，禁止重新赋值（LazyForEach 约束） */
  private dataSource: ArticleDataSource = new ArticleDataSource();

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as CategoryDetailParams;
    this.category = params !== undefined ? decodeURIComponent(params?.category ?? '') : '';
    if (this.category === '') {
      this.loadError = '分类参数缺失';
      return;
    }
    try {
      this.articles = DataRepository.getInstance().getArticlesByCategory(this.category);
      this.dataSource.reload(this.articles);
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  /** 从详情页返回时刷新可见卡片的已读状态（数据不变，仅重建可见项） */
  onPageShow(): void {
    this.dataSource.notifyReload();
  }

  build() {
    Column() {
      Column() {
        PageHeader({
          title: this.category !== '' ? this.category : '分类详情',
          subtitle: this.loadError === '' ? `共 ${this.articles.length} 篇文章` : '',
          showBack: true
        })

        if (this.loadError !== '') {
          Column() {
            Text(this.loadError)
              .fontSize(14)
              .fontColor(this.palette().error)
              .padding(24)
          }
          .width('100%')
        } else if (this.articles.length === 0) {
          Column() {
            Text('该分类下暂无文章')
              .fontSize(14)
              .fontColor(this.palette().empty)
              .padding(24)
          }
          .width('100%')
        } else {
          List({ space: 10 }) {
            LazyForEach(this.dataSource, (article: ArticleMeta) => {
              ListItem() {
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
              }
            }, (article: ArticleMeta) => article.slug)
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 24 })
        }
      }
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      .width('100%')
      .height('100%')
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 跳转：文章详情 */
  private gotoArticleDetail(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  /** 跳转：标签详情 */
  private gotoTagDetail(tag: string): void {
    const params: TagDetailParams = { tag: encodeURIComponent(tag) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagDetailPage', params: params });
  }

  /** 跳转：分类详情（同页刷新） */
  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
