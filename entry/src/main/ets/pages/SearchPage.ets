/**
 * 全文搜索页：标题/标签/分类/正文离线秒搜（内存倒排语料，DataRepository.searchArticles）。
 * - 输入即时搜索（多关键词空格分词，全部命中才计入，按相关度降序）
 * - 结果行：标题 + 命中摘要 + 分类/日期，点击进入文章详情
 * - 纯本地检索，无网络、无权限、无索引服务
 */
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { DataRepository } from '../data/DataRepository';
import {
  ArticleDetailParams,
  CategoryDetailParams,
  SearchResult
} from '../model/ArticleModels';

@Entry
@Component
struct SearchPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State query: string = '';
  @State results: SearchResult[] = [];

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  /** 输入即时搜索（当前语料规模毫秒级，无需防抖） */
  private doSearch(keyword: string): void {
    this.query = keyword;
    try {
      this.results = DataRepository.getInstance().searchArticles(keyword);
    } catch (e) {
      this.results = [];
    }
  }

  build() {
    Column() {
      Column() {
        PageHeader({ title: '搜索', subtitle: '标题 · 标签 · 全文', showBack: true })

        // 搜索输入框
        Row({ space: 8 }) {
          TextInput({ placeholder: '输入关键词，空格分隔多个', text: this.query })
            .fontSize(14)
            .fontColor(this.palette().headerTitle)
            .placeholderColor(this.palette().empty)
            .placeholderFont({ size: 14 })
            .backgroundColor(this.palette().cardBg)
            .borderRadius(12)
            .height(42)
            .layoutWeight(1)
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => {
              this.doSearch(value);
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 10 })

        Scroll() {
          Column({ space: 10 }) {
            if (this.query.trim() === '') {
              Column({ space: 8 }) {
                Text('全文搜索')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.palette().desc)
                Text('支持标题、标签、分类与正文检索；\n多个关键词用空格分隔，全部命中才会返回。')
                  .fontSize(12)
                  .fontColor(this.palette().empty)
                  .lineHeight(19)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding({ top: 64, bottom: 32 })
              .alignItems(HorizontalAlign.Center)
            } else if (this.results.length === 0) {
              Column({ space: 8 }) {
                Text('没有找到相关内容')
                  .fontSize(14)
                  .fontColor(this.palette().empty)
                Text('换个关键词试试')
                  .fontSize(12)
                  .fontColor(this.palette().empty)
              }
              .width('100%')
              .padding({ top: 64, bottom: 32 })
              .alignItems(HorizontalAlign.Center)
            } else {
              ForEach(this.results, (item: SearchResult) => {
                this.resultRow(item)
              }, (item: SearchResult) => `${item.article.slug}-${item.score}`)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 2, bottom: 24 })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')
      }
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      .width('100%')
      .height('100%')
    }
    .backgroundColor(this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 搜索结果行：标题 + 命中摘要 + 分类/日期 */
  @Builder
  resultRow(item: SearchResult) {
    Column({ space: 7 }) {
      Text(item.article.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.palette().headerTitle)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (item.snippet !== '') {
        Text(item.snippet)
          .fontSize(12)
          .fontColor(this.palette().desc)
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      Row({ space: 8 }) {
        Text(item.article.category)
          .fontSize(11)
          .fontColor(this.palette().primary)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor(this.palette().tint)
          .borderRadius(9)
          .maxLines(1)
          .onClick(() => {
            this.gotoCategoryDetail(item.article.category);
          })
        Text(`${item.article.wordCount} 字 · ${this.datePart(item.article.updateTime)}`)
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 16, right: 16, top: 13, bottom: 13 })
    .backgroundColor(this.palette().cardBg)
    .borderRadius(12)
    .onClick(() => {
      this.gotoArticleDetail(item.article.slug);
    })
  }

  /** ISO 时间取日期部分 */
  private datePart(iso: string): string {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  /** 跳转：文章详情 */
  private gotoArticleDetail(slug: string): void {
    const params: ArticleDetailParams = { slug: encodeURIComponent(slug) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/ArticleDetailPage', params: params });
  }

  /** 跳转：分类详情 */
  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
