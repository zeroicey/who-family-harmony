import { AppIcon } from './AppIcon';
import { AppColors, AppFont, AppRadius, AppShadow, AppSpace } from '../theme/Theme';

@Component
export struct ServiceCard {
  @Prop title: string = '';
  @Prop summary: string = '';
  @Prop iconText: string = 'tab_service';

  build() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        AppIcon({ name: this.iconText, iconSize: 28 })
      }
      .width(44)
      .height(44)
      .borderRadius(22)
      .backgroundColor(AppColors.primaryLight)

      Column() {
        Text(this.title)
          .fontSize(AppFont.lg)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textPrimary)
        Text(this.summary)
          .fontSize(AppFont.sm)
          .fontColor(AppColors.textSecondary)
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: AppSpace.xs })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: AppSpace.md })
    }
    .width('100%')
    .padding(14)
    .borderRadius(AppRadius.lg)
    .backgroundColor(AppColors.bgCard)
    .shadow(AppShadow.card)
  }
}