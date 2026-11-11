import { AppColors, AppFont, AppSpace } from '../theme/Theme';

@Component
export struct LoadingView {
  @Prop text: string = '正在加载';

  build() {
    Row() {
      LoadingProgress()
        .width(22)
        .height(22)
        .color(AppColors.primary)
      Text(this.text)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textSecondary)
        .margin({ left: AppSpace.sm })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(AppSpace.lg)
  }
}