/**
 * 分类详情页：展示某分类下的全部文章。
 * 路由参数：{ category: encodeURIComponent 后的分类名 }。
 */
import { ArticleCard } from '../common/ArticleCard';
import { PageHeader } from '../common/PageHeader';
import { DataRepository } from '../data/DataRepository';
import { ArticleDetailParams, ArticleMeta, CategoryDetailParams, TagDetailParams } from '../model/ArticleModels';

const PAGE_BG = '#F4F6F8';

@Entry
@Component
struct CategoryDetailPage {
  @State category: string = '';
  @State articles: ArticleMeta[] = [];
  @State loadError: string = '';

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as CategoryDetailParams;
    this.category = params !== undefined ? decodeURIComponent(params?.category ?? '') : '';
    if (this.category === '') {
      this.loadError = '分类参数缺失';
      return;
    }
    try {
      this.articles = DataRepository.getInstance().getArticlesByCategory(this.category);
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  build() {
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
            .fontColor('#C62828')
            .padding(24)
        }
        .width('100%')
      } else if (this.articles.length === 0) {
        Column() {
          Text('该分类下暂无文章')
            .fontSize(14)
            .fontColor('#9E9E9E')
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
    .backgroundColor(PAGE_BG)
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
