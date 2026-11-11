import { AppIcon } from './AppIcon';

@Component
export struct ServiceCard {
  @Prop title: string = '';
  @Prop summary: string = '';
  @Prop iconText: string = 'tab_service';

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        AppIcon({ name: this.iconText, iconSize: 28 })
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor('#E9F8F0')

      Column() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
        Text(this.summary)
          .fontSize(12)
          .fontColor('#667085')
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 10, color: '#14000000', offsetX: 0, offsetY: 4 })
  }
}
