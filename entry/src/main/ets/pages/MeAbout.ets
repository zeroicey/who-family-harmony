import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct MeAbout {
  @Builder
  ModuleItem(icon: string, name: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .fontColor('#007AFF')
      Text(name)
        .fontSize(13)
        .fontColor('#34495E')
        .margin({ top: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .height(72)
  }

  @Builder
  FeatureItem(icon: string, text: string) {
    Row() {
      Text(icon)
        .fontSize(20)
        .fontColor('#28A745')
      Text(text)
        .fontSize(14)
        .fontColor('#555555')
        .layoutWeight(1)
        .margin({ left: 10 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  ContentCard(title: string) {
    Column() {
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C3E50')
        .width('100%')
        .padding({ left: 10 })
        .border({ width: { left: 4 }, color: '#4FACFE' })
        .margin({ bottom: 16 })

      if (title === '平台定位') {
        Text('“互成一家”小程序旨在打造一个全方位的校园互助与成长平台，紧密围绕大学生的学习、生活和职业发展需求，整合多种实用功能，为校园用户提供更便捷、高效、丰富的线上互动体验，促进同学们之间的交流与互助，助力个人成长与校园生活的优化。')
          .fontSize(14)
          .fontColor('#555555')
          .lineHeight(25)
          .width('100%')
      } else if (title === '核心模块') {
        Row() {
          this.ModuleItem('💬', '社区动态')
          this.ModuleItem('📅', '计划打卡')
          this.ModuleItem('✈', '专注模式')
        }
        .width('100%')
        Row() {
          this.ModuleItem('🚩', '社团招聘')
          this.ModuleItem('🛒', '校园服务')
          this.ModuleItem('👤', '用户认证')
        }
        .width('100%')
      } else {
        this.FeatureItem('⭐', '一站式满足多元化需求')
        this.FeatureItem('⚙', '操作便捷，功能丰富')
        this.FeatureItem('🤝', '营造互助共进的校园生态')
        this.FeatureItem('🙌', '助力成长、友谊与机遇')
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ left: 15, right: 15, bottom: 15 })
    .shadow({ radius: 12, color: '#12000000', offsetX: 0, offsetY: 4 })
  }

  build() {
    Column() {
      PageHeader({ title: '关于' })
      Scroll() {
      Column() {
        Row() {
          Image($r('app.media.icon_logo'))
            .width(60)
            .height(60)
            .borderRadius(30)
            .border({ width: 2, color: '#CCFFFFFF' })
            .objectFit(ImageFit.Cover)
          Column() {
            Text('互成一家')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('全方位校园互助与成长平台')
              .fontSize(14)
              .fontColor('#EFFFFFFF')
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 16 })
        }
        .width('100%')
        .height(200)
        .padding({ left: 24, right: 24, top: 34 })
        .linearGradient({
          angle: 135,
          colors: [['#A1C4FD', 0.0], ['#C2E9FB', 1.0]]
        })

        Column() {
          this.ContentCard('平台定位')
          this.ContentCard('核心模块')
          this.ContentCard('我们的优势')
          Text('互成一家，让校园生活更精彩')
            .fontSize(12)
            .fontColor('#AAAAAA')
            .margin({ top: 10, bottom: 24 })
        }
        .width('100%')
        .margin({ top: -38 })
      }
      .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F6F8')
  }
}
