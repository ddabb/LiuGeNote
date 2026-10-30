/**
 * 首页：全部文章列表 + 标签/分类快捷入口。
 * 离线数据来自 rawfile（DataRepository），无网络请求。
 */
import { ArticleCard } from '../common/ArticleCard';
import { PageHeader } from '../common/PageHeader';
import { DataRepository } from '../data/DataRepository';
import { ArticleDetailParams, ArticleMeta, CategoryDetailParams, TagDetailParams } from '../model/ArticleModels';

const PAGE_BG = '#F4F6F8';

@Entry
@Component
struct Index {
  @State articles: ArticleMeta[] = [];
  @State totalCount: number = 0;
  @State tagCount: number = 0;
  @State categoryCount: number = 0;
  @State loadError: string = '';

  aboutToAppear(): void {
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

  build() {
    Column() {
      PageHeader({ title: 'LgNote 离线笔记', subtitle: `共 ${this.totalCount} 篇 · 纯离线内容` })

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
            .fontColor('#C62828')
          Text(this.loadError)
            .fontSize(13)
            .fontColor('#757575')
          Text('请先执行 node scripts/publish.js 生成 rawfile 数据，再重新构建应用')
            .fontSize(12)
            .fontColor('#9E9E9E')
            .textAlign(TextAlign.Center)
        }
        .padding(24)
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
          .padding({ left: 16, right: 16, top: 6, bottom: 24 })
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

  /** 快捷入口胶囊 */
  @Builder
  entryChip(label: string, count: number, onTap: () => void) {
    Row({ space: 6 }) {
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A237E')
      Text(`${count}`)
        .fontSize(12)
        .fontColor('#5C6BC0')
        .padding({ left: 8, right: 8, top: 1, bottom: 1 })
        .backgroundColor('#E8EAF6')
        .borderRadius(9)
    }
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .onClick(() => onTap())
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
