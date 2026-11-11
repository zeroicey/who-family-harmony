import { router } from '@kit.ArkUI';
import { RouteParams } from '../models/MiniProgramModels';

@Entry
@Component
struct ServiceSuccess {
  @State titleText: string = '服务提交成功';
  @State descText: string = '请等待校内服务人员联系。';
  @State typeText: string = '校园服务';

  aboutToAppear(): void {
    const params = router.getParams() as RouteParams;
    if (params && params.type === 'print') {
      this.titleText = '下单成功';
      this.descText = '请添加商家微信进行联系';
      this.typeText = '文件打印';
    } else if (params && params.type === 'express') {
      this.titleText = '提交成功';
      this.descText = '快递代取需求已提交，请保持电话畅通。';
      this.typeText = '快递代取';
    }
  }

  @Builder
  SummaryCard() {
    Column() {
      Row() {
        Row() {
          Text(this.typeText === '文件打印' ? '🖨️' : '📦')
            .fontSize(18)
          Text(this.typeText)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ left: 8 })
        }
        .layoutWeight(1)
        Text('待处理')
          .fontSize(12)
          .fontColor('#1890FF')
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#E6F7FF')
          .borderRadius(14)
      }
      .width('100%')
      .padding({ bottom: 14 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })
      this.InfoRow('提交时间:', new Date().toLocaleString())
      this.InfoRow('处理方式:', '校内服务人员线下确认')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 24 })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#888888')
        .width(86)
      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .margin({ top: 16 })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Text(this.titleText)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
            .margin({ top: 30 })
          Text(this.descText)
            .fontSize(15)
            .fontColor('#888888')
            .width('100%')
            .margin({ top: 10 })
          this.SummaryCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 120 })
      }
      .layoutWeight(1)

      Button('返回首页')
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#FF6B00')
        .borderRadius(25)
        .margin({ left: 20, right: 20, top: 12, bottom: 20 })
        .onClick(() => {
          router.replaceUrl({ url: 'pages/Index' });
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
