import { Job } from '../models/Job';

@Component
export struct JobCard {
  @ObjectLink job: Job;

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.job.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#182431')
          Text(this.job.organization)
            .fontSize(12)
            .fontColor('#667085')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.job.collected ? '已收藏' : '收藏')
          .fontSize(12)
          .fontColor(this.job.collected ? '#B42318' : '#0A7D6C')
          .backgroundColor(this.job.collected ? '#FFF0F0' : '#E7F5F1')
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      }

      Row() {
        Text(this.job.location)
          .fontSize(12)
          .fontColor('#475467')
        Text(this.job.salary)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0A7D6C')
          .margin({ left: 12 })
      }
      .width('100%')
      .margin({ top: 10 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.job.tags, (tag: string) => {
          Text(tag)
            .fontSize(11)
            .fontColor('#475467')
            .backgroundColor('#F2F4F7')
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .margin({ right: 6, top: 8 })
        }, (tag: string) => tag)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .borderRadius(12)
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 10, color: '#12000000', offsetX: 0, offsetY: 4 })
  }
}
