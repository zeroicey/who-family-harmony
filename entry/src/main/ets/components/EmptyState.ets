@Component
export struct EmptyState {
  @Prop title: string = '暂无数据';
  @Prop description: string = '当前没有可展示的内容';

  build() {
    Column() {
      Text('—')
        .fontSize(28)
        .fontColor('#98A2B3')
      Text(this.title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#475467')
      Text(this.description)
        .fontSize(12)
        .fontColor('#98A2B3')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(24)
    .borderRadius(12)
    .backgroundColor('#F9FAFB')
  }
}
