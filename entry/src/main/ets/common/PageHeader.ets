/**
 * 通用页头：返回键（可选） + 标题 + 副标题。
 */
const COLOR_HEADER_TITLE = '#102027';
const COLOR_HEADER_SUB = '#78909C';

@Component
export struct PageHeader {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop showBack: boolean = false;

  build() {
    Row({ space: 4 }) {
      if (this.showBack) {
        Text('‹')
          .fontSize(32)
          .fontColor(COLOR_HEADER_TITLE)
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
          .fontColor(COLOR_HEADER_TITLE)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.subtitle !== '') {
          Text(this.subtitle)
            .fontSize(12)
            .fontColor(COLOR_HEADER_SUB)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
  }
}
