/**
 * 分类列表页：展示全部分类及文章计数（按名称排序，数据来自 taxonomy.json）。
 * 主题色经 @StorageProp 订阅 AppStorage，设置页切换即时刷新。
 */
import { PageHeader } from '../common/PageHeader';
import { AppTheme, ThemePalette } from '../common/AppTheme';
import { DataRepository } from '../data/DataRepository';
import { CategoryDetailParams, TaxonomyItem } from '../model/ArticleModels';

@Entry
@Component
struct CategoryListPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @State categories: TaxonomyItem[] = [];
  @State loadError: string = '';

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  aboutToAppear(): void {
    try {
      this.categories = DataRepository.getInstance().getTaxonomy().categories;
    } catch (e) {
      this.loadError = `数据加载失败：${(e as Error).message}`;
    }
  }

  build() {
    Column() {
      Column() {
        PageHeader({ title: '分类列表', subtitle: `共 ${this.categories.length} 个分类`, showBack: true })

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
              ForEach(this.categories, (item: TaxonomyItem) => {
                Row() {
                  Column({ space: 3 }) {
                    Text(item.name)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.palette().headerTitle)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(`${item.count} 篇文章`)
                      .fontSize(12)
                      .fontColor(this.palette().primarySoft)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .onClick(() => {
                    this.gotoCategoryDetail(item.name);
                  })
                  Text('›')
                    .fontSize(22)
                    .fontColor(this.palette().meta)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
                .padding({ left: 16, right: 16, top: 13, bottom: 13 })
                .backgroundColor(this.palette().cardBg)
                .borderRadius(12)
                .onClick(() => {
                  this.gotoCategoryDetail(item.name);
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

  /** 跳转：分类详情 */
  private gotoCategoryDetail(category: string): void {
    const params: CategoryDetailParams = { category: encodeURIComponent(category) };
    this.getUIContext().getRouter().pushUrl({ url: 'pages/CategoryDetailPage', params: params });
  }
}
