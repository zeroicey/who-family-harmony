import { router } from '@kit.ArkUI';
import { WatermarkImage } from '../components/WatermarkImage';
import { MockData, ServiceItem } from '../utils/MockData';

@Entry
@Component
struct Service {
  @State services: ServiceItem[] = MockData.services();

  openService(item: ServiceItem): void {
    if (item.id === 'schedule') {
      router.pushUrl({ url: 'pages/ServiceSchedule' });
    } else if (item.id === 'grade') {
      router.pushUrl({ url: 'pages/ServiceGrade' });
    } else if (item.id === 'flow') {
      router.pushUrl({ url: 'pages/ServicePersonInfo' });
    } else if (item.id === 'print') {
      router.pushUrl({ url: 'pages/ServicePrint' });
    } else if (item.id === 'express') {
      router.pushUrl({ url: 'pages/ServiceExpress' });
    }
  }

  private priceText(item: ServiceItem): string {
    if (item.id === 'print') {
      return '¥0.2/页';
    }
    if (item.id === 'express') {
      return '¥3起';
    }
    return '';
  }

  @Builder
  Header() {
    Column() {
      Text('推荐服务')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .width('100%')
      Text('超多服务等你来！')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 6 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 24, bottom: 10 })
  }

  @Builder
  ServiceCard(item: ServiceItem) {
    Column() {
      Stack() {
        WatermarkImage({
          imageUrl: item.imageUrl,
          title: '',
          watermarkText: this.priceText(item).length > 0 ? this.priceText(item) : '互成一家',
          imageHeight: 168,
          imageRadius: 0
        })
        if (this.priceText(item).length > 0) {
          Text(this.priceText(item))
            .fontSize(12)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#FF4D4F')
            .borderRadius({ topLeft: 16, bottomLeft: 16 })
            .position({ x: 228, y: 12 })
        }
      }
      .width('100%')
      .height(168)
      .clip(true)
      Column() {
        Text(item.title)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.summary)
          .fontSize(13)
          .fontColor('#666666')
          .lineHeight(19)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 8 })
        Row() {
          Text('5.0')
            .fontSize(12)
            .fontColor('#FF9500')
            .fontWeight(FontWeight.Bold)
          Text(' ★★★★★')
            .fontSize(11)
            .fontColor('#FF9500')
          Text(item.id === 'flow' ? '4060人已预约' : item.id === 'print' ? '2350人已预约' : '1580人已预约')
            .fontSize(11)
            .fontColor('#999999')
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding(16)
    }
    .width(300)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .clip(true)
    .margin({ right: 16 })
    .onClick(() => {
      this.openService(item);
    })
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Row() {
          ForEach(this.services, (item: ServiceItem) => {
            this.ServiceCard(item)
          }, (item: ServiceItem) => item.id)
        }
        .padding({ left: 20, right: 20, bottom: 16 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .height(300)

      Column() {
        Text('校园服务')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
        Text('课表、成绩、人流、打印等入口集中在这里，常用服务一点直达。')
          .fontSize(13)
          .fontColor('#666666')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 8 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('calc(100% - 40vp)')
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .margin({ top: 12 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
