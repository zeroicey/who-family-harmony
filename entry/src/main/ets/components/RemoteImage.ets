import { webview } from '@kit.ArkWeb';
import { LogUtil } from '../utils/LogUtil';

@Component
export struct RemoteImage {
  @Prop imageUrl: string = '';
  @Prop imageHeight: number = 120;
  @Prop imageRadius: number = 0;
  @Prop fitMode: string = 'cover';
  @Prop imageBgColor: string = '#F5F5F5';
  private controller: webview.WebviewController = new webview.WebviewController();

  private escapedUrl(): string {
    return this.imageUrl
      .split('&').join('&amp;')
      .split('"').join('&quot;')
      .split('<').join('&lt;')
      .split('>').join('&gt;');
  }

  private imageHtml(): string {
    const url = this.escapedUrl();
    return `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>html,body{margin:0;width:100%;height:100%;overflow:hidden;background:${this.imageBgColor};}img{width:100%;height:100%;object-fit:${this.fitMode};display:block;}</style></head><body><img src="${url}"></body></html>`;
  }

  build() {
    Web({ src: `data:text/html;charset=utf-8,${encodeURIComponent(this.imageHtml())}`, controller: this.controller })
      .width('100%')
      .height(this.imageHeight)
      .javaScriptAccess(false)
      .domStorageAccess(false)
      .mixedMode(MixedMode.All)
      .onSslErrorEvent((event) => {
        LogUtil.warn('remote-image', `ssl_confirm url=${event.url} error=${event.error}`);
        event.handler.handleConfirm();
      })
      .onErrorReceive(() => {
        LogUtil.error('remote-image', `web_error url=${this.imageUrl}`);
      })
      .clip(true)
      .borderRadius(this.imageRadius)
      .backgroundColor(this.imageBgColor)
  }
}
