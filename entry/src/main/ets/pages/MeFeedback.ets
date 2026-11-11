import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct MeFeedback {
  @State activeType: string = '功能建议';
  @State content: string = '';
  @State contact: string = '';

  setType(value: string): void {
    this.activeType = value;
  }

  submit(): void {
    if (this.content.trim().length === 0) {
      ToastUtil.show('反馈内容不能为空哦');
      return;
    }
    ToastUtil.show('感谢您的反馈！');
    this.content = '';
    this.contact = '';
  }

  @Builder
  TypeTag(label: string) {
    Text(label)
      .fontSize(13)
      .fontWeight(this.activeType === label ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.activeType === label ? '#FFFFFF' : '#555555')
      .backgroundColor(this.activeType === label ? '#007AFF' : '#F0F0F0')
      .borderRadius(15)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .margin({ right: 10, bottom: 8 })
      .onClick(() => {
        this.setType(label);
      })
  }

  @Builder
  Label(title: string, required: boolean = false) {
    Row() {
      Text(required ? `${title} *` : title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(required ? '#333333' : '#333333')
    }
    .width('100%')
    .margin({ bottom: 10 })
  }

  @Builder
  FormCard() {
    Column() {
      Column() {
        this.Label('反馈类型', true)
        Flex({ wrap: FlexWrap.Wrap }) {
          this.TypeTag('功能建议')
          this.TypeTag('界面优化')
          this.TypeTag('程序BUG')
          this.TypeTag('其他问题')
        }
        .width('100%')
      }
      .width('100%')
      .padding({ top: 8, bottom: 16 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Column() {
        this.Label('反馈内容', true)
        TextArea({ placeholder: '请详细描述您遇到的问题或建议...', text: this.content })
          .width('100%')
          .height(160)
          .fontSize(14)
          .backgroundColor('#F8F9FA')
          .borderRadius(10)
          .onChange((value: string) => {
            this.content = value;
          })
        Text(`${this.content.length}/500`)
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .textAlign(TextAlign.End)
          .margin({ top: 6 })
      }
      .width('100%')
      .padding({ top: 18, bottom: 16 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Column() {
        this.Label('截图凭证')
        Text('最多选择3张图片')
          .fontSize(14)
          .fontColor('#999999')
          .width('100%')
          .height(56)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F8F9FA')
          .borderRadius(10)
      }
      .width('100%')
      .padding({ top: 18, bottom: 16 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Column() {
        this.Label('联系方式')
        TextInput({ placeholder: '选填，便于我们与您联系（手机/QQ/微信）', text: this.contact })
          .height(44)
          .fontSize(14)
          .backgroundColor('#F8F9FA')
          .borderRadius(10)
          .onChange((value: string) => {
            this.contact = value;
          })
      }
      .width('100%')
      .padding({ top: 18, bottom: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 15, right: 15 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 18, color: '#0F000000', offsetX: 0, offsetY: 5 })
  }

  @Builder
  FaqCard() {
    Column() {
      Text('常见问题')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 10 })
      Text('Q: 为什么我的订单一直没人接？')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 8 })
      Text('Q: 如何申请成为骑手？')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 8 })
      Text('Q: 优惠券如何使用？')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ top: 20 })
    .shadow({ radius: 18, color: '#0F000000', offsetX: 0, offsetY: 5 })
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Text('倾听您的声音')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .width('100%')
          Text('您的每一个建议，都是我们成长的动力')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .margin({ top: 8, bottom: 24 })
          this.FormCard()
          this.FaqCard()
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 15, right: 15, top: 36, bottom: 110 })
      }
      .layoutWeight(1)

      Button('提交反馈')
        .width('90%')
        .height(46)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(23)
        .margin({ bottom: 22 })
        .onClick(() => {
          this.submit();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}
