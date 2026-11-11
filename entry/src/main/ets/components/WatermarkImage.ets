import { LogUtil } from '../utils/LogUtil';
import { webview } from '@kit.ArkWeb';

@Component
export struct WatermarkImage {
  @Prop imageUrl: string = '';
  @Prop title: string = '';
  @Prop watermarkText: string = '互成一家';
  @Prop imageHeight: number = 160;
  @Prop imageRadius: number = 14;
  private controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    LogUtil.info('image', `prepare real_url=${this.imageUrl} title=${this.title}`);
  }

  private imageHtml(): string {
    return `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:#DCE7E3;}img{width:100%;height:100%;object-fit:cover;display:block;}</style></head><body><img src="${this.imageUrl}"></body></html>`;
  }

  build() {
    Stack() {
      Web({ src: `data:text/html;charset=utf-8,${encodeURIComponent(this.imageHtml())}`, controller: this.controller })
        .width('100%')
        .height(this.imageHeight)
        .javaScriptAccess(false)
        .domStorageAccess(false)
        .mixedMode(MixedMode.All)
        .onPageEnd(() => {
          LogUtil.info('image', `web_loaded real_url=${this.imageUrl} title=${this.title}`);
        })
        .onErrorReceive(() => {
          LogUtil.error('image', `web_error real_url=${this.imageUrl} title=${this.title}`);
        })
        .onSslErrorEvent((event) => {
          LogUtil.warn('image', `ssl_confirm real_url=${event.url} error=${event.error} title=${this.title}`);
          event.handler.handleConfirm();
        })

      Text(this.watermarkText)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .backgroundColor(0x66000000)
        .borderRadius(10)
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .position({ x: 12, y: 12 })

      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
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
