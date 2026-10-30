/**
 * 标签列表页：展示全部标签及文章计数（按计数降序，数据来自 taxonomy.json）。
 * 主题色经 @StorageProp 订阅 AppStorage，设置页切换即时刷新。
 */
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { DataRepository } from '../data/DataRepository';
import { TagDetailParams, TaxonomyItem } from '../model/ArticleModels';

@Entry
@Component
struct TagListPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State tags: TaxonomyItem[] = [];
  @State loadError: string = '';

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    try {
      this.tags = DataRepository.getInstance().getTaxonomy().tags;
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  build() {
    Column() {
      Column() {
        PageHeader({ title: '标签列表', subtitle: `共 ${this.tags.length} 个标签`, showBack: true })

        if (this.loadError !== '') {
          Column() {
            Text(this.loadError)
              .fontSize(14)
              .fontColor(this.palette().error)
              .padding(24)
          }
          .width('100%')
        } else {
          Scroll() {
            Column({ space: 8 }) {
              ForEach(this.tags, (item: TaxonomyItem) => {
                Row() {
                  Text(`# ${item.name}`)
                    .fontSize(15)
                    .fontColor(this.palette().headerTitle)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text(`${item.count} 篇`)
                    .fontSize(12)
                    .fontColor(this.palette().primarySoft)
                    .padding({ left: 10, right: 10, top: 3, bottom: 3 })
                    .backgroundColor(this.palette().tint)
                    .borderRadius(10)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 13, bottom: 13 })
                .backgroundColor(this.palette().cardBg)
                .borderRadius(12)
                .onClick(() => {
                  this.gotoTagDetail(item.name);
                })
              }, (item: TaxonomyItem) => item.name)
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

  /** 跳转：标签详情 */
  private gotoTagDetail(tag: string): void {
    const params: TagDetailParams = { tag: encodeURIComponent(tag) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/TagDetailPage', params: params });
  }
}
