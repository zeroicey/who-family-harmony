@Component
export struct LoadingView {
  @Prop text: string = '正在加载';

  build() {
    Row() {
      LoadingProgress()
        .width(22)
        .height(22)
        .color('#0A7D6C')
      Text(this.text)
        .fontSize(13)
        .fontColor('#667085')
        .margin({ left: 8 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(18)
  }
}
