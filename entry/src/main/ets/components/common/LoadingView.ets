import { AppColors, AppFont, AppSpace } from '../../theme/Theme';

/**
 * 加载态：旋转指示 + 文案，可铺满内容区。
 */
@Component
export struct LoadingView {
  @Prop text: string = '正在加载';
  @Prop showText: boolean = true;
  @Prop spinnerSize: number = 22;
  @Prop minHeight: number = 0;
  @Prop spinnerColor: string = AppColors.primary;

  build() {
    Row() {
      LoadingProgress()
        .width(this.spinnerSize)
        .height(this.spinnerSize)
        .color(this.spinnerColor)
      if (this.showText) {
        Text(this.text)
          .fontSize(AppFont.sm)
          .fontColor(AppColors.textSecondary)
          .margin({ left: AppSpace.sm })
      }
    }
    .width('100%')
    .constraintSize({ minHeight: this.minHeight })
    .justifyContent(FlexAlign.Center)
    .padding(AppSpace.lg)
  }
}