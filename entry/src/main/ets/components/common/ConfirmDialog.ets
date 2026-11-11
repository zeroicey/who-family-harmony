import { AppColors, AppFont, AppRadius, AppSpace } from '../../theme/Theme';

/**
 * 二次确认弹窗。用法（宿主页面）：
 *
 *   private confirmController: CustomDialogController = new CustomDialogController({
 *     builder: ConfirmDialog({
 *       title: '删除动态',
 *       message: '删除后不可恢复，确定删除吗？',
 *       onConfirm: () => { ... }
 *     }),
 *     autoCancel: true,
 *     alignment: DialogAlignment.Center
 *   });
 *
 *   点击时调用 this.confirmController.open();
 */
@CustomDialog
export struct ConfirmDialog {
  controller?: CustomDialogController;
  @Prop title: string = '提示';
  @Prop message: string = '';
  @Prop confirmText: string = '确定';
  @Prop cancelText: string = '取消';
  @Prop confirmColor: string = AppColors.brandBlue;
  @Prop showCancel: boolean = true;
  onConfirm: () => void = () => {
  };
  onCancel: () => void = () => {
  };

  private close(): void {
    if (this.controller !== undefined) {
      this.controller.close();
    }
  }

  build() {
    Column() {
      Text(this.title)
        .fontSize(AppFont.lg)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.textPrimary)
        .width('100%')
        .textAlign(TextAlign.Center)
      Text(this.message)
        .fontSize(AppFont.base)
        .fontColor(AppColors.textSecondary)
        .lineHeight(21)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: AppSpace.md })

      Row() {
        if (this.showCancel) {
          Button(this.cancelText)
            .fontSize(AppFont.base)
            .fontColor(AppColors.textSecondary)
            .backgroundColor(AppColors.bgPage)
            .borderRadius(AppRadius.xs)
            .height(40)
            .layoutWeight(1)
            .onClick(() => {
              this.onCancel();
              this.close();
            })
        }
        Button(this.confirmText)
          .fontSize(AppFont.base)
          .fontColor(AppColors.textInverse)
          .backgroundColor(this.confirmColor)
          .borderRadius(AppRadius.xs)
          .height(40)
          .layoutWeight(1)
          .margin({ left: this.showCancel ? AppSpace.md : 0 })
          .onClick(() => {
            this.onConfirm();
            this.close();
          })
      }
      .width('100%')
      .margin({ top: AppSpace.xl })
    }
    .width('100%')
    .padding(AppSpace.xl)
    .backgroundColor(AppColors.bgCard)
    .borderRadius(AppRadius.lg)
  }
}