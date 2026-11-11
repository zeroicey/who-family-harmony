import { AppColors, AppFont, AppRadius, AppSpace } from '../theme/Theme';

@Component
export struct EmptyState {
  @Prop title: string = '暂无数据';
  @Prop description: string = '当前没有可展示的内容';

  build() {
    Column() {
      Text('—')
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
    }
    .width('100%')
    .padding(AppSpace.xxl)
    .borderRadius(AppRadius.md)
    .backgroundColor(AppColors.bgPage)
  }
}