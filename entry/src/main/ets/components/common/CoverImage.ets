import { NetImage } from './NetImage';
import { AppColors, AppFont } from '../../theme/Theme';

/**
 * 带角标/水印的图片卡：在 ArkUI Image 之上叠一层文字，不再使用 Web 渲染。
 */
@Component
export struct CoverImage {
  @Prop imageUrl: string = '';
  @Prop title: string = '';
  @Prop watermarkText: string = '互成一家';
  @Prop imageHeight: number = 160;
  @Prop imageRadius: number = 14;

  build() {
    Stack() {
      NetImage({
        imageUrl: this.imageUrl,
        imageHeight: this.imageHeight,
        imageRadius: this.imageRadius,
        fitMode: 'cover',
        imageBgColor: '#DCE7E3'
      })
        .width('100%')
        .height(this.imageHeight)

      if (this.watermarkText.length > 0) {
        Text(this.watermarkText)
          .fontSize(AppFont.sm)
          .fontColor(AppColors.textInverse)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(0x66000000)
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .position({ x: 12, y: 12 })
      }

      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(AppFont.xl)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textInverse)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor(0x550A1F1B)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .position({ x: 12, y: this.imageHeight - 46 })
      }
    }
    .width('100%')
    .height(this.imageHeight)
    .clip(true)
    .borderRadius(this.imageRadius)
    .backgroundColor('#DCE7E3')
  }
}