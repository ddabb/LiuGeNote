/**
 * 设置页：主题色 / 正文字体 / 阅读背景 / 字号行距 配置。
 * - 选择即时生效（AppStorage 驱动全部页面刷新）并自动持久化（preferences）
 * - 字体选项：系统默认 / 思源黑体 / 霞鹜文楷（内置 rawfile 字体，详见 FontRegistry）
 * - 阅读背景四套：纸白 / 羊皮纸 / 护眼 / 暗夜；字号 14-22fp，行距 1.3-2.0 倍
 * - 底部固定实时预览条：不随内容滚动，调整任意偏好效果即时可见
 */
import { AppTheme, ReadingBg, ThemePalette } from '../common/AppTheme';
import { FontEntry, FontRegistry } from '../common/FontRegistry';
import { PageHeader } from '../common/PageHeader';

@Entry
@Component
struct SettingsPage {
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;
  @StorageProp(AppTheme.STORAGE_FONT) fontId: number = 0;
  @StorageProp(AppTheme.STORAGE_READ_BG) readBgId: number = 0;
  @StorageProp(AppTheme.STORAGE_TEXT_SIZE) textSize: number = AppTheme.TEXT_SIZE_DEFAULT;
  @StorageProp(AppTheme.STORAGE_LINE_SPACING) lineSpacing: number = AppTheme.LINE_SPACING_DEFAULT;

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  private readingBg(): ReadingBg {
    return AppTheme.readingBgOf(this.readBgId);
  }

  /** 字体预览：默认字体显式指定 HarmonyOS Sans，内置字体用注册 family */
  private familyOfPreview(id: number): string {
    const family: string = FontRegistry.familyOf(id);
    return family !== '' ? family : 'HarmonyOS Sans';
  }

  build() {
    Column() {
      Column() {
        PageHeader({ title: '设置', subtitle: '主题与阅读偏好', showBack: true })

        Scroll() {
          Column({ space: 14 }) {
            // ---------- 主题色（3 列 × 2 行） ----------
            Column({ space: 14 }) {
              Text('主题色')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().headerTitle)
              Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
                ForEach(AppTheme.allPalettes(), (p: ThemePalette) => {
                  Column({ space: 6 }) {
                    // 选中态：外圈主题色描边环
                    Column() {
                      Column() {
                        if (this.themeId === p.id) {
                          Text('✓')
                            .fontSize(18)
                            .fontWeight(FontWeight.Bold)
                            .fontColor('#FFFFFF')
                        }
                      }
                      .width(44)
                      .height(44)
                      .borderRadius(22)
                      .justifyContent(FlexAlign.Center)
                      .backgroundColor(p.primary)
                    }
                    .justifyContent(FlexAlign.Center)
                    .alignItems(HorizontalAlign.Center)
                    .width(52)
                    .height(52)
                    .borderRadius(26)
                    .border({
                      width: this.themeId === p.id ? 2 : 2,
                      color: this.themeId === p.id ? p.primary : '#00000000'
                    })
                    Text(p.name)
                      .fontSize(12)
                      .fontColor(this.themeId === p.id ? this.palette().primaryDeep : this.palette().meta)
                  }
                  .width('33.3%')
                  .margin({ top: 4, bottom: 4 })
                  .onClick(() => {
                    AppTheme.setThemeId(p.id);
                  })
                }, (p: ThemePalette) => p.id.toString())
              }
              .width('100%')
            }
            .padding(16)
            .borderRadius(12)
            .backgroundColor(this.palette().cardBg)
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // ---------- 正文字体 ----------
            Column({ space: 14 }) {
              Text('正文字体')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().headerTitle)
              Row({ space: 10 }) {
                ForEach(FontRegistry.ENTRIES, (entry: FontEntry) => {
                  Column({ space: 5 }) {
                    Text(entry.label)
                      .fontSize(12)
                      .fontColor(this.fontId === entry.id ? this.palette().primaryDeep : this.palette().desc)
                    Text('笔记 Aa 123')
                      .fontSize(16)
                      .fontFamily(this.familyOfPreview(entry.id))
                      .fontColor(this.palette().headerTitle)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .layoutWeight(1)
                  .padding({ top: 12, bottom: 12, left: 8, right: 8 })
                  .borderRadius(10)
                  .backgroundColor(this.fontId === entry.id ? this.palette().tint : '#FAFBFC')
                  .border({
                    width: this.fontId === entry.id ? 1.5 : 1,
                    color: this.fontId === entry.id ? this.palette().primary : '#E3E7EA'
                  })
                  .onClick(() => {
                    AppTheme.setFontId(entry.id);
                  })
                }, (entry: FontEntry) => entry.id.toString())
              }
              .width('100%')
            }
            .padding(16)
            .borderRadius(12)
            .backgroundColor(this.palette().cardBg)
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // ---------- 阅读背景 ----------
            Column({ space: 14 }) {
              Text('阅读背景')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().headerTitle)
              Row({ space: 10 }) {
                ForEach(AppTheme.allReadingBgs(), (bg: ReadingBg) => {
                  Column({ space: 6 }) {
                    // 色板：按方案底色/文字色渲染样例字符
                    Column() {
                      Text('Aa 文')
                        .fontSize(16)
                        .fontFamily(this.familyOfPreview(this.fontId))
                        .fontColor(bg.bodyText)
                    }
                    .width('100%')
                    .height(52)
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(bg.contentBg)
                    .borderRadius(10)
                    .border({
                      width: this.readBgId === bg.id ? 2 : 1,
                      color: this.readBgId === bg.id ? this.palette().primary : '#E3E7EA'
                    })
                    Text(bg.name)
                      .fontSize(12)
                      .fontColor(this.readBgId === bg.id ? this.palette().primaryDeep : this.palette().meta)
                  }
                  .layoutWeight(1)
                  .onClick(() => {
                    AppTheme.setReadBgId(bg.id);
                  })
                }, (bg: ReadingBg) => bg.id.toString())
              }
              .width('100%')
            }
            .padding(16)
            .borderRadius(12)
            .backgroundColor(this.palette().cardBg)
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            // ---------- 字号 / 行距 ----------
            Column({ space: 16 }) {
              Text('排版')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.palette().headerTitle)

              Row() {
                Text('正文字号')
                  .fontSize(14)
                  .fontColor(this.palette().desc)
                  .layoutWeight(1)
                Text(`${Math.round(this.textSize)} fp`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.palette().primaryDeep)
              }
              .width('100%')
              Slider({
                value: this.textSize,
                min: AppTheme.TEXT_SIZE_MIN,
                max: AppTheme.TEXT_SIZE_MAX,
                step: 1,
                style: SliderStyle.OutSet
              })
                .selectedColor(this.palette().primary)
                .trackColor(this.palette().tint)
                .blockColor(this.palette().primaryDeep)
                .width('100%')
                .onChange((value: number) => {
                  AppTheme.setTextSize(value);
                })

              Row() {
                Text('行距')
                  .fontSize(14)
                  .fontColor(this.palette().desc)
                  .layoutWeight(1)
                Text(`×${this.lineSpacing.toFixed(2)}`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.palette().primaryDeep)
              }
              .width('100%')
              Slider({
                value: this.lineSpacing,
                min: AppTheme.LINE_SPACING_MIN,
                max: AppTheme.LINE_SPACING_MAX,
                step: 0.05,
                style: SliderStyle.OutSet
              })
                .selectedColor(this.palette().primary)
                .trackColor(this.palette().tint)
                .blockColor(this.palette().primaryDeep)
                .width('100%')
                .onChange((value: number) => {
                  AppTheme.setLineSpacing(value);
                })
            }
            .padding(16)
            .borderRadius(12)
            .backgroundColor(this.palette().cardBg)
            .width('100%')
            .alignItems(HorizontalAlign.Start)

            Text('主题、字体与阅读偏好修改即时生效并自动保存；正文字体同时应用于文章渲染与 PDF 导出。')
              .fontSize(12)
              .fontColor(this.palette().meta)
              .lineHeight(18)
              .padding({ left: 4, right: 4 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 10, bottom: 32 })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .width('100%')

        // 底部固定实时预览：不随内容滚动，拖动滑条/切换偏好效果即时可见
        this.livePreviewBar()
      }
      .constraintSize({ maxWidth: AppTheme.CONTENT_MAX_WIDTH })
      .width('100%')
      .height('100%')
    }
    .backgroundColor(this.palette().pageBg)
    .height('100%')
    .width('100%')
  }

  /** 底部固定实时预览条：按当前字体/字号/行距/阅读背景渲染样例 */
  @Builder
  livePreviewBar() {
    Column({ space: 8 }) {
      Row() {
        Text('实时预览')
          .fontSize(11)
          .fontColor(this.palette().meta)
        Text(`${Math.round(this.textSize)} fp · ×${this.lineSpacing.toFixed(2)}`)
          .fontSize(11)
          .fontColor(this.palette().meta)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text('鹤鸣于九皋，声闻于野。\n离线笔记 Aa 123，纯本地渲染。')
        .fontSize(Math.round(this.textSize))
        .lineHeight(Math.round(this.textSize * this.lineSpacing))
        .fontFamily(this.familyOfPreview(this.fontId))
        .fontColor(this.readingBg().bodyText)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .margin({ left: 16, right: 16, bottom: 12 })
    .borderRadius(12)
    .backgroundColor(this.readingBg().contentBg)
    .border({
      width: 1,
      color: this.readingBg().dark ? '#3A3F45' : '#E3E7EA'
    })
  }
}
