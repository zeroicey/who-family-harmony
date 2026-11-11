import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { CommunityApi } from '../api/CommunityApi';
import { HelperApi } from '../api/HelperApi';
import { AuthStore } from '../stores/AuthStore';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
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

  async publish(): Promise<void> {
    if (this.titleText.trim().length === 0) {
      ToastUtil.show('请输入标题');
      return;
    }
    if (this.contentText.trim().length === 0) {
      ToastUtil.show('请输入内容');
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await CommunityApi.publishText(token, this.titleText.trim(), this.contentText.trim(), this.typeText.trim(), env);
      ToastUtil.show('发布成功!');
      router.back();
    } catch (err) {
      ToastUtil.show(`发布失败：${(err as Error).message}`);
    }
  }

  @Builder
  ImageUploader() {
    Row() {
      Text('+')
        .fontSize(34)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .width(86)
        .height(86)
        .borderRadius(14)
        .backgroundColor('#F4F6F8')
      Text('+')
        .fontSize(34)
        .fontColor('#C7C7CC')
        .textAlign(TextAlign.Center)
        .width(86)
        .height(86)
        .borderRadius(14)
        .backgroundColor('#F4F6F8')
        .margin({ left: 10 })
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
            Button('发布')
              .height(40)
              .fontColor('#FFFFFF')
              .backgroundColor('#07C160')
              .borderRadius(20)
              .margin({ left: 10 })
              .onClick(() => {
                this.publish();
              })
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
  }
}
