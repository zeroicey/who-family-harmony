import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { CommunityApi } from '../api/CommunityApi';
import { HelperApi } from '../api/HelperApi';
import { AuthStore } from '../stores/AuthStore';
import { PickedFile, UploadService } from '../services/UploadService';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
import { PrimaryButton } from '../components/common/PrimaryButton';
@Entry
@Component
struct CommunityPublish {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State titleText: string = '';
  @State contentText: string = '';
  @State typeText: string = '好物推荐';
  @State aiSuggestion: string = '';
  @State showUndo: boolean = false;
  @State originalTitle: string = '';
  @State originalContent: string = '';
  @State images: PickedFile[] = [];
  @State previewUri: string = '';
  @State publishing: boolean = false;

  optimize(): void {
    if (this.titleText.trim().length === 0 && this.contentText.trim().length === 0) {
      ToastUtil.show('请先输入标题或内容');
      return;
    }
    this.originalTitle = this.titleText;
    this.originalContent = this.contentText;
    this.aiSuggestion = HelperApi.optimizePost(this.titleText, this.contentText);
    this.contentText = this.aiSuggestion;
    this.showUndo = true;
    ToastUtil.show('润色完成！');
  }

  undoOptimize(): void {
    this.titleText = this.originalTitle;
    this.contentText = this.originalContent;
    this.aiSuggestion = '';
    this.showUndo = false;
    ToastUtil.show('已撤回');
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
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    this.publishing = true;
    try {
      if (this.images.length === 0) {
        await CommunityApi.publishText(token, this.titleText.trim(), this.contentText.trim(), this.typeText.trim(), env);
      } else {
        await CommunityApi.publishWithImages(token, this.titleText.trim(), this.contentText.trim(),
          this.typeText.trim(), this.images, env);
      }
      ToastUtil.show('发布成功!');
      router.back();
    } catch (err) {
      ToastUtil.show(`发布失败：${(err as Error).message}`);
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
            .borderRadius(14)
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
          .borderRadius(14)
          .backgroundColor('#F4F6F8')
          .margin({ right: 10, bottom: 10 })
          .onClick(() => {
            this.pickImages();
          })
      }
    }
    .width('100%')
    .padding({ top: 18, bottom: 16 })
  }

  @Builder
  ActionButtons() {
    Row() {
      if (this.showUndo) {
        Button('↩ 撤回优化')
          .height(42)
          .fontColor('#666666')
          .backgroundColor('#F2F4F7')
          .borderRadius(21)
          .onClick(() => {
            this.undoOptimize();
          })
      }
      Blank()
      Button('✨ AI润色')
        .height(42)
        .fontColor('#FFFFFF')
        .backgroundColor('#2979FF')
        .borderRadius(21)
        .onClick(() => {
          this.optimize();
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

          TextInput({ placeholder: '动态分类：好物推荐 / 跑腿 / 二手 / 评分', text: this.typeText })
            .height(46)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .padding({ left: 16, right: 16 })
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.typeText = value;
            })

          TextArea({
            placeholder: '💭 今天有什么想分享的呢？可以是生活趣事、学习心得、美食推荐...让大家看到不一样的你！✨',
            text: this.contentText
          })
            .height(260)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .padding(16)
            .margin({ top: 12 })
            .onChange((value: string) => {
              this.contentText = value;
            })

          this.ActionButtons()
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
