/**
 * 标签详情页：展示某标签下的全部文章。
 * 路由参数：{ tag: encodeURIComponent 后的标签名 }。
 * 主题色经 @StorageProp 订阅 AppStorage，设置页切换即时刷新。
 */
import { ArticleCard } from '../common/ArticleCard';
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { DataRepository } from '../data/DataRepository';
import { ArticleDetailParams, ArticleMeta, CategoryDetailParams, TagDetailParams } from '../model/ArticleModels';

@Entry
@Component
struct TagDetailPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State tag: string = '';
  @State articles: ArticleMeta[] = [];
  @State loadError: string = '';

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as TagDetailParams;
    this.tag = params !== undefined ? decodeURIComponent(params?.tag ?? '') : '';
    if (this.tag === '') {
      this.loadError = '标签参数缺失';
      return;
    }
    try {
      this.articles = DataRepository.getInstance().getArticlesByTag(this.tag);
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  build() {
    Column() {
      Column() {
        PageHeader({
          title: `# ${this.tag}`,
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
            Text('该标签下暂无文章')
              .fontSize(14)
              .fontColor(this.palette().empty)
              .padding(24)
          }
          .width('100%')
        } else {
          Scroll() {
            Column({ space: 10 }) {
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
            .padding({ left: 16, right: 16, top: 8, bottom: 24 })
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

  /** 跳转：文章详情 */
  private gotoArticleDetail(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  /** 跳转：标签详情（同页刷新） */
  private gotoTagDetail(tag: string): void {
    const params: TagDetailParams = { tag: encodeURIComponent(tag) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagDetailPage', params: params });
  }

  /** 跳转：分类详情 */
  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
