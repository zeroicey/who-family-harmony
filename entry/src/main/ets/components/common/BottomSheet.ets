import { AppColors, AppFont, AppRadius, AppSpace } from '../../theme/Theme';

/**
 * 底部弹层：基于 bindSheet，调用方用 @Link 双向绑定显示状态。
 *
 * 用法：
 *   @State sheetVisible: boolean = false;
 *   ...
 *   BottomSheet({ show: $sheetVisible, title: '评论' }) {
 *     // 内容
 *   }
 */
@Component
export struct BottomSheet {
  @Link show: boolean;
  @Prop title: string = '';
  @Prop sheetHeight: number = 360;
  @Prop sheetBackground: string = AppColors.bgCard;
  onClose: () => void = () => {
  };
  @BuilderParam content: () => void = this.emptyContent;

  @Builder
  emptyContent() {
  }

  @Builder
  SheetBody() {
    Column() {
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(AppFont.lg)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textPrimary)
          .width('100%')
          .padding({ left: AppSpace.page, right: AppSpace.page, top: AppSpace.md, bottom: AppSpace.sm })
      }
      Scroll() {
        Column() {
          this.content()
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.sheetBackground)
    .borderRadius({ topLeft: AppRadius.xl, topRight: AppRadius.xl })
  }

  build() {
    Row()
      .width(0)
      .height(0)
      .bindSheet($$this.show, this.SheetBody(), {
        height: this.sheetHeight,
        dragBar: true,
        showClose: true,
        backgroundColor: this.sheetBackground,
        onDisappear: () => {
          this.onClose();
        }
      })
  }
}