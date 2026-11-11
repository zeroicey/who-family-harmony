import { AppColors, AppFont, AppRadius, AppShadow, AppSpace } from '../../theme/Theme';

/**
 * 通用卡片容器：可选标题/副标题 + 内容区。
 */
@Component
export struct SectionCard {
  @Prop title: string = '';
  @Prop subtitle: string = '';
  @Prop cardBg: string = AppColors.bgCard;
  @Prop cardPadding: number = AppSpace.lg;
  @Prop cardRadius: number = AppRadius.lg;
  @Prop showShadow: boolean = true;
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  build() {
    Column() {
      if (this.title.length > 0 || this.subtitle.length > 0) {
        Row() {
          Column() {
            if (this.title.length > 0) {
              Text(this.title)
                .fontSize(AppFont.lg)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppColors.textPrimary)
            }
            if (this.subtitle.length > 0) {
              Text(this.subtitle)
                .fontSize(AppFont.sm)
                .fontColor(AppColors.textTertiary)
                .margin({ top: AppSpace.xs })
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: AppSpace.md })
      }
      this.content()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(this.cardPadding)
    .borderRadius(this.cardRadius)
    .backgroundColor(this.cardBg)
    .shadow(this.showShadow ? AppShadow.card : AppShadow.none)
  }
}