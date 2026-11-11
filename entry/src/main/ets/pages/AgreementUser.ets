@Entry
@Component
struct AgreementUser {
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
    Scroll() {
      Column() {
        this.Section('欢迎使用互成一家', '欢迎您使用“互成一家”小程序。在您使用本小程序之前，请您仔细阅读本用户协议。本协议是您与本小程序运营方之间关于您使用本小程序服务所订立的协议。\n\n当您点击同意或使用本小程序时，即表示您已充分阅读、理解并接受本协议的全部内容。')
        this.Section('账号注册与使用', '1. 您在使用本小程序时，需要通过授权方式登录。\n2. 您应保证提供信息的真实性、完整性和准确性。\n3. 您应妥善保管账号信息，因个人原因导致账号被他人使用而产生的后果由您自行承担。')
        this.Section('用户行为规范', '在使用本小程序的过程中，您必须遵守中华人民共和国相关法律法规，不得发布、传播违法、违规、侵犯他人权益或违反社会公德的信息，不得利用本小程序从事影响平台正常运行的行为。')
        this.Section('知识产权', '本小程序的所有权、运营权和知识产权归运营方所有。未经书面同意，您不得以任何方式复制、传播、展示、上传、下载、修改或出售本小程序的任何内容。')
        this.Section('免责声明', '我们不对用户发布的内容进行事先审查，但有权依法对涉嫌违法或违反本协议的内容进行处理。因网络状况、通讯线路或第三方服务原因导致您不能正常使用本小程序的，平台将在合理范围内协助处理。')
        this.Section('联系我们', '电子邮件：service@whofamily.com\n联系电话：17727316901\n联系地址：佛山市南海区信息大道中互成一家传媒公司')
        Text('本用户协议更新日期：2025年4月22日\n生效日期：2025年4月22日')
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
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}
