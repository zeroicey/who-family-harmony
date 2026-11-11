import { AppColors, AppFont, AppRadius } from '../../theme/Theme';

/**
 * 标签/徽标：默认浅绿底绿字，可按语义换色。
 */
@Component
export struct Tag {
  @Prop text: string = '';
  @Prop fgColor: string = AppColors.primary;
  @Prop bgColor: string = AppColors.primaryLight;
  @Prop fontSize: number = AppFont.xs;
  @Prop tagRadius: number = AppRadius.xs;
  @Prop tagPaddingH: number = 6;
  @Prop tagPaddingV: number = 2;

  build() {
    Text(this.text)
      .fontSize(this.fontSize)
      .fontColor(this.fgColor)
      .backgroundColor(this.bgColor)
      .borderRadius(this.tagRadius)
      .padding({ left: this.tagPaddingH, right: this.tagPaddingH, top: this.tagPaddingV, bottom: this.tagPaddingV })
      .maxLines(1)
  }
}