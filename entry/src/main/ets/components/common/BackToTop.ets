import { AppColors, AppShadow } from '../../theme/Theme';

/**
 * 回到顶部悬浮按钮。
 *
 * 用法：把页面根容器写成 Stack({ alignContent: Alignment.BottomEnd })，并把
 * BackToTop 作为最后一个子组件放入：
 *
 *   Stack({ alignContent: Alignment.BottomEnd }) {
 *     Scroll() { ... }.layoutWeight(1)
 *     BackToTop({ visible: this.showBackToTop })
 *   }
 *   .width('100%').height('100%')
 */
@Component
export struct BackToTop {
  @Prop visible: boolean = false;
  @Prop marginRight: number = 16;
  @Prop marginBottom: number = 96;
  @Prop buttonSize: number = 44;
  onTap: () => void = () => {
  };

  build() {
    if (this.visible) {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.icon_me_back_to_top'))
          .width(22)
          .height(22)
          .objectFit(ImageFit.Contain)
      }
      .width(this.buttonSize)
      .height(this.buttonSize)
      .borderRadius(this.buttonSize / 2)
      .backgroundColor(AppColors.bgCard)
      .shadow(AppShadow.floating)
      .margin({ right: this.marginRight, bottom: this.marginBottom })
      .onClick(() => {
        this.onTap();
      })
    }
  }
}