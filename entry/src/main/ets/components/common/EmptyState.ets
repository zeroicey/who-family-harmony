import { AppColors, AppFont, AppSpace } from '../../theme/Theme';

/**
 * 空态：默认灰底提示，可选一个行动按钮。
 */
@Component
export struct EmptyState {
  @Prop title: string = '暂无数据';
  @Prop description: string = '当前没有可展示的内容';
  @Prop iconText: string = '—';
  @Prop actionText: string = '';
  @Prop cardBg: string = AppColors.bgPage;
  onAction: () => void = () => {
  };

  build() {
    Column() {
      Text(this.iconText)
        .fontSize(28)
        .fontColor(AppColors.textTertiary)
      Text(this.title)
        .fontSize(AppFont.md)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.textSecondary)
        .margin({ top: AppSpace.sm })
      Text(this.description)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textTertiary)
        .margin({ top: AppSpace.xs })
        .textAlign(TextAlign.Center)
      if (this.actionText.length > 0) {
        Button(this.actionText)
          .fontSize(AppFont.sm)
          .fontColor(AppColors.brandBlue)
          .backgroundColor('rgba(0, 0, 0, 0)')
          .height(36)
          .margin({ top: AppSpace.sm })
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .width('100%')
    .padding(AppSpace.xxl)
    .borderRadius(12)
    .backgroundColor(this.cardBg)
  }
}