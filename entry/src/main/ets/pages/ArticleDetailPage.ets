/**
 * 文章详情页：front-matter 元信息 + Markdown 正文离线渲染。
 * 正文渲染由 @luvi/lv-markdown-in（lv-markdown-in）引擎承担，
 * 依赖通过 ohpm 注册表声明（见根 oh-package.json5），禁止 file: 本地绝对路径引用。
 * 路由参数：{ slug: encodeURIComponent 后的文章 slug }。
 * 文内分类/标签可继续跳转对应详情页。
 */
import { Markdown } from '@luvi/lv-markdown-in';
import { PageHeader } from '../common/PageHeader';
import { DataRepository } from '../data/DataRepository';
import {
  ArticleDetailParams,
  ArticleMeta,
  CategoryDetailParams,
  createEmptyArticleMeta,
  TagDetailParams
} from '../model/ArticleModels';

const PAGE_BG = '#F4F6F8';
const CARD_BG = '#FFFFFF';

@Entry
@Component
struct ArticleDetailPage {
  @State article: ArticleMeta = createEmptyArticleMeta();
  @State bodyText: string = '';
  @State loadError: string = '';
  @State isLoaded: boolean = false;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as ArticleDetailParams;
    const slug: string = params !== undefined ? decodeURIComponent(params?.slug ?? '') : '';
    if (slug === '') {
      this.loadError = '文章参数缺失';
      return;
    }
    try {
      const repo = DataRepository.getInstance();
      const meta: ArticleMeta | undefined = repo.getArticleMeta(slug);
      if (meta === undefined) {
        this.loadError = `未找到文章：${slug}`;
        return;
      }
      this.article = meta;
      // 正文为 front-matter 剥离后的 Markdown 文本，交给引擎解析渲染
      this.bodyText = repo.getArticleBody(meta);
      this.isLoaded = true;
    } catch (e) {
      this.loadError = `文章加载失败：${(e as Error).message}`;
    }
  }

  build() {
    Column() {
      PageHeader({
        title: this.isLoaded ? this.article.title : '文章详情',
        subtitle: this.isLoaded
          ? `${this.article.category} · ${this.article.wordCount} 字 · ${this.datePart(this.article.updateTime)}`
          : '',
        showBack: true
      })

      if (this.loadError !== '') {
        Column({ space: 8 }) {
          Text('无法打开文章')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#C62828')
          Text(this.loadError)
            .fontSize(13)
            .fontColor('#757575')
        }
        .padding(24)
        .width('100%')
      } else if (!this.isLoaded) {
        Column() {
          LoadingProgress()
            .width(36)
            .height(36)
            .color('#5C6BC0')
          Text('加载中...')
            .fontSize(13)
            .fontColor('#9E9E9E')
            .margin({ top: 8 })
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width('100%')
      } else {
        Scroll() {
          Column() {
            // 元信息卡：分类 + 标签（可跳转）
            Column() {
              Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
                Text(this.article.category)
                  .fontSize(12)
                  .fontColor('#0D47A1')
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .backgroundColor('#E3F2FD')
                  .borderRadius(11)
                  .margin({ right: 6, bottom: 6 })
                  .onClick(() => {
                    this.gotoCategoryDetail(this.article.category);
                  })
                ForEach(this.article.tags, (tag: string) => {
                  Text(`# ${tag}`)
                    .fontSize(12)
                    .fontColor('#546E7A')
                    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                    .backgroundColor('#F0F3F5')
                    .borderRadius(11)
                    .margin({ right: 6, bottom: 6 })
                    .onClick(() => {
                      this.gotoTagDetail(tag);
                    })
                }, (tag: string) => tag)
              }
              .width('100%')
            }
            .padding(14)
            .borderRadius(12)
            .backgroundColor(CARD_BG)
            .width('100%')

            // Markdown 正文：lv-markdown-in 引擎渲染
            Markdown({
              text: this.bodyText,
              mode: 'text',
              callback: {
                complete: () => {
                },
                fail: (code: number, message: string) => {
                  this.loadError = `正文渲染失败（${code}）：${message}`;
                }
              }
            })
              .padding({ top: 16, bottom: 16 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 32 })
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

  /** ISO 时间取日期部分 */
  private datePart(iso: string): string {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }

  /** 跳转：标签详情 */
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
