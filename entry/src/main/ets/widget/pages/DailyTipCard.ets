/**
 * 每日知识点卡片 UI（2x2 ArkTS 卡片）：
 * - 数据由 EntryFormAbility 经 formBindingData 下发，@LocalStorageProp 接收
 * - 点击卡片 postCardAction router 拉起 EntryAbility 并携带 slug（直达文章详情）
 * - 卡片仅支持 ArkUI 子集：纯布局 + 点击，无复杂手势与滚动
 * - 主题色跟随主应用（preferences 直读后随卡片数据下发）
 */
let storage = new LocalStorage();

@Entry(storage)
@Component
struct DailyTipCard {
  @LocalStorageProp('title') title: string = '行知';
  @LocalStorageProp('description') description: string = '每天一篇 ArkTS 构建手记';
  @LocalStorageProp('dateLabel') dateLabel: string = '';
  @LocalStorageProp('slug') slug: string = '';
  @LocalStorageProp('primary') primary: string = '#5C6BC0';
  @LocalStorageProp('primaryDeep') primaryDeep: string = '#1A237E';

  build() {
    Column({ space: 6 }) {
      Row() {
        Text('行知 · 每日知识点')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.primary)
        Text(this.dateLabel)
          .fontSize(9)
          .fontColor('#90A4AE')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryDeep)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        Text(this.description)
          .fontSize(10)
          .lineHeight(14)
          .fontColor('#546E7A')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .layoutWeight(1)

      Text('点击阅读全文 ›')
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.primary)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(12)
    .onClick(() => {
      this.openArticle();
    })
  }

  /** 点击卡片：router 拉起主应用（携带 slug 直达文章；slug 为空仅打开应用） */
  private openArticle(): void {
    const action: Record<string, Object> = {};
    action['action'] = 'router';
    action['abilityName'] = 'EntryAbility';
    if (this.slug !== '') {
      const params: Record<string, string> = {};
      params['slug'] = this.slug;
      action['params'] = params;
    }
    postCardAction(this, action);
  }
}
