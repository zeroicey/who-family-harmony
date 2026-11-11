import { PageHeader } from '../components/common/PageHeader';
import { AgreementMock } from '../mock/AgreementMock';
import { AgreementSection } from '../models/MockModels';
@Entry
@Component
struct AgreementPrivacy {
  @State sections: AgreementSection[] = AgreementMock.privacyPolicy();

  @Builder
  Section(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .padding({ left: 12 })
        .border({ width: { left: 4 }, color: '#3498DB' })
        .margin({ bottom: 12 })
      Text(content)
        .fontSize(15)
        .fontColor('#666666')
        .lineHeight(25)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 18 })
    .shadow({ radius: 6, color: '#0D000000', offsetX: 0, offsetY: 1 })
  }

  build() {
    Column() {
      PageHeader({ title: '隐私政策' })
      Scroll() {
      Column() {
        ForEach(this.sections, (section: AgreementSection) => {
          this.Section(section.heading, section.body)
        }, (section: AgreementSection) => section.heading)
        Text(AgreementMock.privacyPolicyFooter())
          .fontSize(12)
          .fontColor('#999999')
          .lineHeight(20)
          .textAlign(TextAlign.Center)
          .margin({ top: 4, bottom: 24 })
      }
      .width('100%')
      .padding(16)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}
