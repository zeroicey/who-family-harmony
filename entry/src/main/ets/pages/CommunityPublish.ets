import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { CommunityApi } from '../api/CommunityApi';
import { HelperApi } from '../api/HelperApi';
import { PostType } from '../models/CommunityPost';
import { CommunityMock } from '../mock/CommunityMock';
import { AuthStore } from '../stores/AuthStore';
import { AiCallbacks, AiSession } from '../services/AiService';
import { PickedFile, UploadService } from '../services/UploadService';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
import { PrimaryButton } from '../components/common/PrimaryButton';

/** DashScope 润色结果（system prompt 要求返回 JSON）。 */
class PolishResult {
  title: string = '';
  content: string = '';
}

@Entry
@Component
struct CommunityPublish {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State titleText: string = '';
  @State contentText: string = '';
  @State postTypes: PostType[] = [];
  @State selectedType: string = '';
  @State typesLoading: boolean = true;
  @State images: PickedFile[] = [];
  @State previewUri: string = '';
  @State publishing: boolean = false;
  @State showUndo: boolean = false;
  @State aiBusy: boolean = false;
  @State aiPanelVisible: boolean = false;
  @State aiRaw: string = '';
  @State aiTitle: string = '';
  @State aiContent: string = '';
  @State aiError: string = '';
  private originalTitle: string = '';
  private originalContent: string = '';
  private aiSession: AiSession | null = null;

  aboutToAppear(): void {
    this.loadPostTypes();
  }

  aboutToDisappear(): void {
    this.cancelAi();
  }

  /** 分类来自后端 postTypes；失败时保留参考数据兜底，不允许手输。 */
  private async loadPostTypes(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const remoteTypes = await CommunityApi.types(token, env);
      this.postTypes = remoteTypes.length > 0 ? remoteTypes : CommunityMock.postTypes();
    } catch (err) {
      LogUtil.warn('publish', `post types failed ${(err as Error).message}`);
      this.postTypes = CommunityMock.postTypes();
    }
    if (this.postTypes.length > 0) {
      let matched = false;
      this.postTypes.forEach((type: PostType) => {
        if (type.name === this.selectedType) {
          matched = true;
        }
      });
      if (!matched) {
        this.selectedType = this.postTypes[0].name;
      }
    }
    this.typesLoading = false;
  }

  /** 相册最多 4 张，和微信小程序发布页一致。 */
  async pickImages(): Promise<void> {
    const remain = 4 - this.images.length;
    if (remain <= 0) {
      ToastUtil.show('最多上传4张图片');
      return;
    }
    try {
      const picked = await UploadService.pickImages(remain);
      if (picked.length === 0) {
        return;
      }
      const accepted: PickedFile[] = [];
      picked.forEach((file: PickedFile) => {
        const reason = UploadService.checkImage(file);
        if (reason.length > 0) {
          ToastUtil.show(reason);
        } else {
          accepted.push(file);
        }
      });
      this.images = this.images.concat(accepted.slice(0, remain));
    } catch (err) {
      LogUtil.warn('publish', `pick images failed ${(err as Error).message}`);
      ToastUtil.show('选择图片失败，请重试');
    }
  }

  deleteImage(index: number): void {
    if (index < 0 || index >= this.images.length) {
      return;
    }
    const next: PickedFile[] = [];
    this.images.forEach((file: PickedFile, fileIndex: number) => {
      if (fileIndex !== index) {
        next.push(file);
      }
    });
    this.images = next;
  }

  /** AI 润色：流式输出到建议面板，用户确认后才覆盖原文；失败保留原文。 */
  optimize(): void {
    if (this.titleText.trim().length === 0 && this.contentText.trim().length === 0) {
      ToastUtil.show('请先输入标题或内容');
      return;
    }
    this.cancelAi();
    this.originalTitle = this.titleText;
    this.originalContent = this.contentText;
    this.aiBusy = true;
    this.aiPanelVisible = true;
    this.aiRaw = '';
    this.aiTitle = '';
    this.aiContent = '';
    this.aiError = '';
    let accumulated = '';
    const callbacks = new AiCallbacks(
      (chunk: string) => {
        accumulated += chunk;
        this.aiRaw = accumulated;
      },
      (fullText: string) => {
        this.aiRaw = fullText;
        this.aiBusy = false;
        this.aiSession = null;
        this.parsePolishResult(fullText);
      },
      (message: string) => {
        this.aiBusy = false;
        this.aiSession = null;
        this.aiError = message;
        LogUtil.warn('publish', `ai polish failed ${message}`);
      }
    );
    this.aiSession = HelperApi.polishStream(this.titleText, this.contentText, callbacks);
  }

  private parsePolishResult(raw: string): void {
    const text = raw.trim();
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      try {
        const parsed = JSON.parse(text.substring(start, end + 1)) as PolishResult;
        if (parsed.title.length > 0 || parsed.content.length > 0) {
          this.aiTitle = parsed.title.length > 0 ? parsed.title : this.titleText;
          this.aiContent = parsed.content.length > 0 ? parsed.content : this.contentText;
          return;
        }
      } catch (_) {
        LogUtil.warn('publish', 'ai polish json parse failed');
      }
    }
    this.aiTitle = this.titleText;
    this.aiContent = text;
  }

  applyAi(): void {
    if (this.aiTitle.trim().length === 0 && this.aiContent.trim().length === 0) {
      return;
    }
    this.titleText = this.aiTitle;
    this.contentText = this.aiContent;
    this.showUndo = true;
    this.aiPanelVisible = false;
    this.aiRaw = '';
    ToastUtil.show('润色完成！');
  }

  cancelAi(): void {
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
    this.aiBusy = false;
  }

  dismissAi(): void {
    this.cancelAi();
    this.aiPanelVisible = false;
    this.aiError = '';
    this.aiRaw = '';
    this.aiTitle = '';
    this.aiContent = '';
  }

  undoOptimize(): void {
    this.titleText = this.originalTitle;
    this.contentText = this.originalContent;
    this.showUndo = false;
    ToastUtil.show('已撤回');
  }

  async publish(): Promise<void> {
    if (this.publishing) {
      return;
    }
    if (this.titleText.trim().length === 0) {
      ToastUtil.show('请输入标题');
      return;
    }
    if (this.titleText.length > 99) {
      ToastUtil.show('标题不能超过99个字');
      return;
    }
    if (this.contentText.trim().length === 0) {
      ToastUtil.show('请输入内容');
      return;
    }
    if (this.contentText.length > 10000) {
      ToastUtil.show('内容不能超过10000个字');
      return;
    }
    if (this.typesLoading) {
      ToastUtil.show('分类加载中，请稍候');
      return;
    }
    let typeValid = false;
    this.postTypes.forEach((type: PostType) => {
      if (type.name === this.selectedType) {
        typeValid = true;
      }
    });
    if (!typeValid) {
      ToastUtil.show('请选择有效的动态分类');
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    this.publishing = true;
    try {
      if (this.images.length === 0) {
        await CommunityApi.publishText(token, this.titleText.trim(), this.contentText.trim(),
          this.selectedType.trim(), env);
      } else {
        await CommunityApi.publishWithImages(token, this.titleText.trim(), this.contentText.trim(),
          this.selectedType.trim(), this.images, env);
      }
      this.titleText = '';
      this.contentText = '';
      this.images = [];
      // 通知社区列表重新拉取第一页（与小程序发布后 fetch_first_posts 一致）。
      AppStorage.setOrCreate<string>('communityRefreshAt', `${new Date().getTime()}`);
      ToastUtil.show('发布成功!');
      router.back();
    } catch (err) {
      LogUtil.warn('publish', `publish failed ${(err as Error).message}`);
      ToastUtil.show('发布失败，请重试');
    } finally {
      this.publishing = false;
    }
  }

  @Builder
  ImageUploader() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.images, (file: PickedFile, index: number) => {
        Stack({ alignContent: Alignment.TopEnd }) {
          Image(file.uri)
            .width(86)
            .height(86)
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .onClick(() => {
              this.previewUri = file.uri;
            })
          Text('×')
            .fontSize(16)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width(22)
            .height(22)
            .borderRadius(11)
            .backgroundColor('#99000000')
            .onClick(() => {
              this.deleteImage(index);
            })
        }
        .width(86)
        .height(86)
        .margin({ right: 10, bottom: 10 })
      }, (file: PickedFile, index: number) => `${file.uri}-${index}`)

      if (this.images.length < 4) {
        Text('+')
          .fontSize(34)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .width(86)
          .height(86)
          .borderRadius(8)
          .backgroundColor('#F4F6F8')
          .margin({ right: 10, bottom: 10 })
          .onClick(() => {
            this.pickImages();
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  CategorySelector() {
    Scroll() {
      Row() {
        if (this.typesLoading) {
          Text('分类加载中...')
            .fontSize(13)
            .fontColor('#999999')
        } else {
          ForEach(this.postTypes, (type: PostType) => {
            Text(type.name)
              .fontSize(13)
              .fontWeight(this.selectedType === type.name ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.selectedType === type.name ? '#FFFFFF' : '#666666')
              .padding({ left: 14, right: 14, top: 6, bottom: 6 })
              .backgroundColor(this.selectedType === type.name ? '#00cc6a' : '#F4F6F8')
              .borderRadius(15)
              .margin({ right: 8 })
              .onClick(() => {
                this.selectedType = type.name;
              })
          }, (type: PostType) => type.id)
        }
      }
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 12 })
  }

  @Builder
  AiPanel() {
    Column() {
      Row() {
        Text('AI 润色建议')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('×')
          .fontSize(16)
          .fontColor('#999999')
          .width(24)
          .height(24)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.dismissAi();
          })
      }
      .width('100%')

      if (this.aiError.length > 0) {
        Text(this.aiError)
          .fontSize(13)
          .fontColor('#FF4D4F')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 8 })
        Row() {
          Text('重试')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#6e8efb')
            .borderRadius(15)
            .onClick(() => {
              this.optimize();
            })
        }
        .justifyContent(FlexAlign.End)
        .width('100%')
        .margin({ top: 10 })
      } else if (this.aiBusy) {
        Text(this.aiRaw.length > 0 ? this.aiRaw : '润色中...')
          .fontSize(13)
          .fontColor('#666666')
          .lineHeight(20)
          .maxLines(8)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 8 })
        Row() {
          Text('取消')
            .fontSize(13)
            .fontColor('#666666')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#F2F4F7')
            .borderRadius(15)
            .onClick(() => {
              this.dismissAi();
            })
        }
        .justifyContent(FlexAlign.End)
        .width('100%')
        .margin({ top: 10 })
      } else {
        Text(`标题：${this.aiTitle}`)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 8 })
        Text(`正文：${this.aiContent}`)
          .fontSize(13)
          .fontColor('#555555')
          .lineHeight(20)
          .maxLines(8)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .margin({ top: 6 })
        Row() {
          Text('取消')
            .fontSize(13)
            .fontColor('#666666')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#F2F4F7')
            .borderRadius(15)
            .margin({ right: 10 })
            .onClick(() => {
              this.dismissAi();
            })
          Text('应用')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .borderRadius(15)
            .linearGradient({
              angle: 135,
              colors: [['#6e8efb', 0.0], ['#a777e3', 1.0]]
            })
            .onClick(() => {
              this.applyAi();
            })
        }
        .justifyContent(FlexAlign.End)
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 1, color: '#E9ECF5' })
    .margin({ top: 12 })
  }

  @Builder
  ActionButtons() {
    Row() {
      if (this.showUndo) {
        Text('↩ 撤回优化')
          .fontSize(14)
          .fontColor('#666666')
          .height(42)
          .padding({ left: 16, right: 16 })
          .textAlign(TextAlign.Center)
          .backgroundColor('#F2F4F7')
          .borderRadius(21)
          .margin({ right: 10 })
          .onClick(() => {
            this.undoOptimize();
          })
      }
      Blank()
      Text(this.aiBusy ? '润色中...' : '✨ AI润色')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .height(42)
        .padding({ left: 18, right: 18 })
        .textAlign(TextAlign.Center)
        .borderRadius(21)
        .linearGradient({
          angle: 135,
          colors: [['#6e8efb', 0.0], ['#a777e3', 1.0]]
        })
        .onClick(() => {
          if (!this.aiBusy) {
            this.optimize();
          }
        })
    }
    .width('100%')
    .margin({ top: 14 })
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        PageHeader({ title: '发布动态' })
        Scroll() {
          Column() {
            this.ImageUploader()

            Row() {
              TextInput({ placeholder: '✨ 给你的动态起个有趣的标题吧~', text: this.titleText })
                .layoutWeight(1)
                .height(48)
                .fontSize(15)
                .maxLength(99)
                .backgroundColor('#FFFFFF')
                .onChange((value: string) => {
                  this.titleText = value;
                })
              PrimaryButton({
                text: '发布',
                loading: this.publishing,
                buttonWidth: 76,
                buttonHeight: 40,
                buttonRadius: 20,
                onTap: () => {
                  this.publish();
                }
              })
                .margin({ left: 10 })
            }
            .width('100%')
            .padding({ left: 16, right: 12, top: 10, bottom: 10 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ top: 12 })

            this.CategorySelector()

            TextArea({
              placeholder: '💭 今天有什么想分享的呢？可以是生活趣事、学习心得、美食推荐...让大家看到不一样的你！✨',
              text: this.contentText
            })
              .height(260)
              .fontSize(15)
              .maxLength(10000)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .padding(16)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.contentText = value;
              })

            this.ActionButtons()

            if (this.aiPanelVisible) {
              this.AiPanel()
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 24 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')

      if (this.previewUri.length > 0) {
        Column() {
          Image(this.previewUri)
            .width('100%')
            .height('80%')
            .objectFit(ImageFit.Contain)
          Text('点击任意处关闭')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ top: 18 })
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')
        .zIndex(20)
        .onClick(() => {
          this.previewUri = '';
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}
