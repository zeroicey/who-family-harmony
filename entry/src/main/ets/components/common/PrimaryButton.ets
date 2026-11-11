import { AppColors, AppFont, AppRadius, AppTheme } from '../../theme/Theme';

export class ButtonVariant {
  static readonly PRIMARY: string = 'primary';
  static readonly OUTLINE: string = 'outline';
  static readonly GHOST: string = 'ghost';
  static readonly DANGER: string = 'danger';
}

/**
 * 主操作按钮：支持主色/描边/幽灵/危险四种形态，禁用与加载态。
 */
@Component
export struct PrimaryButton {
  @Prop text: string = '确定';
  @Prop variant: string = ButtonVariant.PRIMARY;
  @Prop buttonEnabled: boolean = true;
  @Prop loading: boolean = false;
  @Prop buttonHeight: number = AppTheme.buttonHeight;
  @Prop buttonWidth: Length = '100%';
  @Prop buttonRadius: number = AppRadius.sm;
  onTap: () => void = () => {
  };

  private isDisabled(): boolean {
    return !this.buttonEnabled || this.loading;
  }

  private solidColor(): string {
    if (this.variant === ButtonVariant.DANGER) {
      return AppColors.error;
    }
    if (this.variant === ButtonVariant.PRIMARY) {
      return this.isDisabled() ? AppColors.textDisabled : AppColors.brandBlue;
    }
    return 'rgba(0, 0, 0, 0)';
  }

  private textColor(): string {
    if (this.variant === ButtonVariant.GHOST) {
      return AppColors.brandBlue;
    }
    if (this.variant === ButtonVariant.OUTLINE) {
      return this.isDisabled() ? AppColors.textDisabled : AppColors.brandBlue;
    }
    return AppColors.textInverse;
  }

  private borderColorValue(): string {
    if (this.variant === ButtonVariant.OUTLINE) {
      return this.isDisabled() ? AppColors.textDisabled : AppColors.brandBlue;
    }
    return 'rgba(0, 0, 0, 0)';
  }

  build() {
    Button() {
      Row() {
        if (this.loading) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(this.textColor())
            .margin({ right: 6 })
        }
        Text(this.text)
          .fontSize(AppFont.base)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor())
      }
      .justifyContent(FlexAlign.Center)
    }
    .width(this.buttonWidth)
    .height(this.buttonHeight)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.solidColor())
    .border({ width: 1, color: this.borderColorValue() })
    .borderRadius(this.buttonRadius)
    .stateEffect(!this.isDisabled())
    .enabled(!this.isDisabled())
    .onClick(() => {
      if (!this.isDisabled()) {
        this.onTap();
      }
    })
  }
}