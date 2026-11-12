import { PageHeader } from '../components/common/PageHeader';
import { AgreementMock } from '../mock/AgreementMock';
import { AgreementSection } from '../models/MockModels';

@Entry
@Component
struct AgreementUser {
  @State sections: AgreementSection[] = AgreementMock.userAgreement();

  private isListLine(line: string): boolean {
    const match = line.match(/^[0-9]+\./);
    return match !== null;
  }

  private isContactLine(line: string): boolean {
    return line.startsWith('电子邮件：') || line.startsWith('联系电话：') || line.startsWith('联系地址：');
  }

  @Builder
  Paragraphs(content: string) {
    Column() {
      ForEach(content.split('\n'), (line: string, index: number) => {
        Text(line)
          .fontSize(15)
          .fontColor(this.isContactLine(line) ? '#444444' : '#666666')
          .lineHeight(24)
          .width('100%')
          .padding({ left: this.isListLine(line) || this.isContactLine(line) ? 6 : 0 })
          .margin({ bottom: 8 })
      }, (line: string, index: number) => `${index}-${line.length}-${line}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

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
      this.Paragraphs(content)
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
      PageHeader({ title: '用户协议' })
      Scroll() {
        Column() {
          ForEach(this.sections, (section: AgreementSection) => {
            this.Section(section.heading, section.body)
          }, (section: AgreementSection) => section.heading)
          Text(AgreementMock.userAgreementFooter())
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
