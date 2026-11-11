@Entry
@Component
struct AgreementPrivacy {
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
        this.Section('引言', '欢迎使用“互成一家”小程序。我们非常重视您的个人信息和隐私保护。本隐私政策旨在向您说明我们如何收集、使用、存储、共享和保护您的个人信息，以及您享有的相关权利。')
        this.Section('我们收集的信息', '为了向您提供校园互助与成长平台服务，我们可能会收集账号信息、个人资料、使用记录、设备信息和经您授权后的位置信息。')
        this.Section('信息的使用', '我们使用收集的信息用于提供、维护和改进小程序服务，验证您的身份，处理您在小程序中的请求和交易，优化用户体验，并遵守法律法规要求。')
        this.Section('信息的共享', '除获得您的明确同意、遵守法律法规、完成必要服务或维护我们及其他用户合法权益的情形外，我们不会向第三方共享您的个人信息。')
        this.Section('联系我们', '如果您对本隐私政策有任何疑问、意见或建议，请通过以下方式与我们联系：\n电子邮件：privacy@whofamily.com\n联系电话：17727316901\n联系地址：佛山市南海区信息大道中互成一家传媒公司')
        Text('本隐私政策更新日期：2025年4月22日\n生效日期：2025年4月22日')
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
