import { AppColors, AppFont, AppSpace } from '../../theme/Theme';

/**
 * 网络图片组件：使用 ArkUI Image 直接加载，替代早期的 Web 渲染方案。
 *
 * - 空 URL / 加载失败：展示灰底占位，不创建 Web 引擎；
 * - 圆角裁剪：clip + borderRadius；
 * - 列表复用：Image 自带缓存，无需额外处理；
 * - 不注册 onSslErrorEvent，不做 SSL 自动放行。
 */
@Component
export struct NetImage {
  @Prop @Watch('onImageUrlChanged') imageUrl: string = '';
  @Prop imageHeight: number = 120;
  @Prop imageRadius: number = 0;
  @Prop fitMode: string = 'cover';
  @Prop imageBgColor: string = AppColors.bgPlaceholder;
  @Prop placeholderText: string = '';
  @State private loadFailed: boolean = false;

  /** URL 变化后必须重置失败态，否则列表复用或换图后仍显示占位。 */
  onImageUrlChanged(): void {
    if (this.loadFailed) {
      this.loadFailed = false;
    }
  }

  aboutToReuse(params: Record<string, Object>): void {
    this.loadFailed = false;
  }

  private imageFit(): ImageFit {
    if (this.fitMode === 'contain') {
      return ImageFit.Contain;
    }
    if (this.fitMode === 'fill') {
      return ImageFit.Fill;
    }
    if (this.fitMode === 'none') {
      return ImageFit.None;
    }
    if (this.fitMode === 'scale-down') {
      return ImageFit.ScaleDown;
    }
    return ImageFit.Cover;
  }

  @Builder
  Placeholder() {
    Column() {
      Text('图')
        .fontSize(AppFont.xl)
        .fontColor(AppColors.textDisabled)
      if (this.placeholderText.length > 0) {
        Text(this.placeholderText)
          .fontSize(AppFont.xs)
          .fontColor(AppColors.textTertiary)
          .margin({ top: AppSpace.xs })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.imageBgColor)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.imageUrl.length === 0 || this.loadFailed) {
        this.Placeholder()
      } else {
        Image(this.imageUrl)
          .width('100%')
          .height('100%')
          .objectFit(this.imageFit())
          .interpolation(ImageInterpolation.Medium)
          .onError(() => {
            this.loadFailed = true;
          })
      }
    }
    .width('100%')
    .height(this.imageHeight)
    .borderRadius(this.imageRadius)
    .clip(true)
    .backgroundColor(this.imageBgColor)
  }
}