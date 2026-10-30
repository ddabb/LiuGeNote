/**
 * 通用页头：返回键（可选） + 标题 + 副标题 + 右侧动作区。
 * - actions：图标动作按钮（如搜索/设置），系统符号库 SymbolGlyph 渲染
 * - menuItems：非空时渲染"⋯"按钮并绑定弹出菜单（如导出/分享）
 * - onDark：暗色阅读模式下翻转页头配色（文章详情页暗夜背景时传入）
 */
import { AppTheme, ThemePalette } from './AppTheme';

/** 页头右侧图标动作 */
export class HeaderAction {
  /** 系统符号资源（sys.symbol.*） */
  icon: Resource | undefined = undefined;
  onClick: () => void = () => {
  };
}

@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = false;
  @Prop onDark: boolean = false;
  /** 右侧图标动作（初始化时传入，不响应动态变更） */
  actions: HeaderAction[] = [];
  /** 右侧"更多"菜单项（非空时渲染 ⋯ 按钮） */
  menuItems: MenuElement[] = [];
  @StorageProp(AppTheme.STORAGE_THEME) themeId: number = 0;

  private palette(): ThemePalette {
    return AppTheme.paletteOf(this.themeId);
  }

  private titleColor(): string {
    return this.onDark ? '#ECEFF1' : '#102027';
  }

  private subColor(): string {
    return this.onDark ? '#8A9299' : '#78909C';
  }

  build() {
    Row({ space: 4 }) {
      if (this.showBack) {
        Text('‹')
          .fontSize(32)
          .fontColor(this.titleColor())
          .width(34)
          .height(34)
          .textAlign(TextAlign.Center)
          .borderRadius(17)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
      }
      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.titleColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle !== '') {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor(this.subColor())
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧图标动作区（搜索 / 设置等）
      Row({ space: 6 }) {
        ForEach(this.actions, (action: HeaderAction, index: number) => {
          if (action.icon !== undefined) {
            SymbolGlyph(action.icon)
              .fontSize(18)
              .fontColor([this.onDark ? this.palette().primarySoft : this.palette().primaryDeep])
              .width(34)
              .height(34)
              .borderRadius(17)
              .backgroundColor(this.onDark ? '#2C3036' : this.palette().tint)
              .onClick(() => {
                action.onClick();
              })
          }
        }, (action: HeaderAction, index: number) => index.toString())

        // "更多"菜单（导出/分享等低频动作收纳于此）
        if (this.menuItems.length > 0) {
          Text('⋯')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.onDark ? '#ECEFF1' : '#455A64')
            .width(34)
            .height(34)
            .textAlign(TextAlign.Center)
            .borderRadius(17)
            .backgroundColor(this.onDark ? '#2C3036' : this.palette().tint)
            .bindMenu(this.menuItems)
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }
}
