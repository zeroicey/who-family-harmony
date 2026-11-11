import { common } from '@kit.AbilityKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { AppIcon } from '../components/AppIcon';
import { ChatMessage, PresetQuestion } from '../models/MiniProgramModels';
import { HelperApi } from '../api/HelperApi';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';
import { MarkdownView } from '../components/common/MarkdownView';
import { AiCallbacks, AiOptions, AiService, AiSession } from '../services/AiService';

@Entry
@Component
export struct Helper {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State messages: ChatMessage[] = MockData.initialMessages();
  @State questions: PresetQuestion[] = MockData.presetQuestions();
  @State inputText: string = '';
  @State isAIReplying: boolean = false;
  private aiSession: AiSession | null = null;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.load();
  }

  aboutToDisappear(): void {
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
  }

  async load(): Promise<void> {
    const cached = await CacheStore.getJson<ChatMessage[]>(this.context, 'helperMessages', MockData.initialMessages());
    // 只丢弃流式输出中断的消息；错误气泡保留，重启后仍可重试。
    const restored = cached.filter((item: ChatMessage) => item.status !== 'typing' && item.content.length > 0);
    this.messages = restored.length > 0 ? restored : MockData.initialMessages();
    if (this.messages.length > 1) {
      this.scrollToBottom();
    }
  }

  /** 等布局完成后再滚到底，保证新气泡进入可见区域（m1）。 */
  private scrollToBottom(): void {
    setTimeout(() => {
      try {
        this.scroller.scrollEdge(Edge.Bottom);
      } catch (_) {
      }
    }, 50);
  }

  async send(content: string, retryId: string = ''): Promise<void> {
    if (this.isAIReplying) {
      ToastUtil.show('AI 正在回复，请稍候');
      return;
    }
    const safeText = content.trim();
    if (safeText.length === 0) {
      ToastUtil.show('请输入问题');
      return;
    }
    this.inputText = '';
    if (retryId.length > 0) {
      // 错误气泡重试：复用原 AI 消息位置，不重复插入用户消息。
      this.updateMessage(retryId, '正在思考...', 'typing', safeText);
      this.startStream(safeText, retryId);
      return;
    }
    const userMessage = new ChatMessage(`user-${new Date().getTime()}`, 'user', safeText);
    const pendingId = `ai-pending-${new Date().getTime()}`;
    const pendingMessage = new ChatMessage(pendingId, 'ai', '正在思考...');
    pendingMessage.status = 'typing';
    pendingMessage.question = safeText;
    this.messages = this.messages.concat([userMessage, pendingMessage]);
    this.startStream(safeText, pendingId);
  }

  private startStream(question: string, aiId: string): void {
    this.isAIReplying = true;
    this.scrollToBottom();
    let accumulated = '';
    const callbacks = new AiCallbacks(
      (chunk: string) => {
        accumulated += chunk;
        this.updateMessage(aiId, accumulated, 'typing', question);
      },
      (fullText: string) => {
        this.updateMessage(aiId, fullText.length > 0 ? fullText : accumulated, 'done', question);
        this.isAIReplying = false;
        this.aiSession = null;
        this.persistMessages();
      },
      (message: string) => {
        this.updateMessage(aiId, message, 'error', question);
        this.isAIReplying = false;
        this.aiSession = null;
        this.persistMessages();
        ToastUtil.show('AI 回复失败');
      }
    );
    // 逐字流式输出；请求失败时 AiService 自动重试。
    this.aiSession = HelperApi.sendStream(question, callbacks);
  }

  private persistMessages(): void {
    const stable = this.messages.filter((item: ChatMessage) => item.status !== 'typing');
    CacheStore.setJson<ChatMessage[]>(this.context, 'helperMessages', stable).catch(() => {
    });
  }

  private updateMessage(id: string, content: string, status: string, question: string): void {
    const updatedMessages: ChatMessage[] = [];
    this.messages.forEach((message: ChatMessage) => {
      if (message.id === id) {
        const next = new ChatMessage(id, 'ai', content);
        next.status = status;
        next.question = question;
        updatedMessages.push(next);
      } else {
        updatedMessages.push(message);
      }
    });
    this.messages = updatedMessages;
    this.scrollToBottom();
  }

  private retryMessage(message: ChatMessage): void {
    let question = message.question;
    if (question.length === 0) {
      let index = -1;
      for (let i = 0; i < this.messages.length; i++) {
        if (this.messages[i].id === message.id) {
          index = i;
          break;
        }
      }
      for (let i = index - 1; i >= 0; i--) {
        if (this.messages[i].role === 'user') {
          question = this.messages[i].content;
          break;
        }
      }
    }
    if (question.length === 0) {
      ToastUtil.show('请重新输入问题');
      return;
    }
    this.send(question, message.id);
  }

  private copyMessage(message: ChatMessage): void {
    if (message.content.length === 0 || message.status === 'error') {
      return;
    }
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, message.content);
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        ToastUtil.show('已复制');
      }).catch(() => {
        ToastUtil.show('复制失败');
      });
    } catch (_) {
      ToastUtil.show('复制失败');
    }
  }

  private clearMessages(): void {
    AlertDialog.show({
      title: '确认清空',
      message: '确定要清空所有聊天记录吗？',
      primaryButton: {
        value: '清空',
        action: () => {
          if (this.aiSession !== null) {
            this.aiSession.cancel();
            this.aiSession = null;
            this.isAIReplying = false;
          }
          this.messages = MockData.initialMessages();
          this.persistMessages();
          // 清空后只剩欢迎语与预设问题，回到顶部展示完整欢迎语。
          setTimeout(() => {
            try {
              this.scroller.scrollEdge(Edge.Top);
            } catch (_) {
            }
          }, 50);
        }
      },
      secondaryButton: { value: '取消', action: () => {
      } }
    });
  }

  private async checkAiStatus(): Promise<void> {
    ToastUtil.show('正在检查 AI 状态...');
    const options = new AiOptions();
    options.maxTokens = 8;
    options.retries = 0;
    try {
      await AiService.ask('你好', '只回复一个字：好', options);
      ToastUtil.show('AI 服务正常');
    } catch (err) {
      ToastUtil.show((err as Error).message);
    }
  }

  private onMenuClick(): void {
    ActionSheet.show({
      title: '聊天设置',
      message: '',
      sheets: [
        {
          title: '清空聊天记录',
          action: () => {
            this.clearMessages();
          }
        },
        {
          title: '检查AI状态',
          action: () => {
            this.checkAiStatus();
          }
        }
      ],
      cancel: () => {
      }
    });
  }

  @Builder
  Header() {
    Row() {
      Text('☰')
        .fontSize(20)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)
        .width(30)
        .height(30)
        .onClick(() => {
          this.onMenuClick();
        })
      Text('校园AI助手')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
      Blank()
        .width(30)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 20, bottom: 10 })
    .backgroundColor('#F5F5F7')
    .border({ width: { bottom: 1 }, color: '#E5E5E7' })
  }

  @Builder
  AiHeader() {
    Row() {
      AppIcon({ name: 'ai', iconSize: 30, radius: 15 })
        .margin({ right: 6 })
      Text('答答Novus智能校园助手')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#666666')
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  AiBubble(message: ChatMessage) {
    Column() {
      this.AiHeader()
      if (message.status === 'error') {
        Row() {
          Text(`⚠️ ${message.content}`)
            .fontSize(13)
            .fontColor('#DD524D')
            .lineHeight(21)
            .layoutWeight(1)
          Text('重试')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#4A8BFF')
            .padding({ left: 10, right: 6, top: 4, bottom: 4 })
            .onClick(() => {
              this.retryMessage(message);
            })
        }
        .width('100%')
        .margin({ top: 6 })
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor('#FFF1F0')
        .borderRadius(8)
      } else {
        Column() {
          MarkdownView({ markdown: message.content, baseFontSize: 14 })
            .width('100%')
          if (message.status === 'typing' && message.content.length > 0) {
            Text('▋')
              .fontSize(12)
              .fontColor('#007AFF')
          }
        }
        .width('100%')
        .margin({ top: 6 })
        .gesture(LongPressGesture({ duration: 500 }).onAction(() => {
          this.copyMessage(message);
        }))
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 15, right: 15, top: 10 })
  }

  @Builder
  UserBubble(message: ChatMessage) {
    Row() {
      Blank()
        .layoutWeight(1)
      Text(message.content)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .lineHeight(20)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#4A8BFF')
        .borderRadius({ topLeft: 10, topRight: 10, bottomLeft: 10, bottomRight: 4 })
        .constraintSize({ maxWidth: '70%' })
        .gesture(LongPressGesture({ duration: 500 }).onAction(() => {
          this.copyMessage(message);
        }))
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 10 })
  }

  @Builder
  PresetQuestions() {
    Column() {
      Column() {
        Text('💡 常见问题')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        Text('点击下方问题快速咨询')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
        ForEach(this.questions, (question: PresetQuestion) => {
          Column() {
            Text(question.title)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Text(this.previewText(question.content))
                .fontSize(11)
                .fontColor('#999999')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)
              Text('›')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ left: 4 })
            }
            .width('100%')
            .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('48.5%')
          .padding(10)
          .backgroundColor('#FFFFFF')
          .borderRadius(10)
          .margin({ bottom: 8 })
          .onClick(() => {
            this.send(question.content);
          })
        }, (question: PresetQuestion) => question.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 6, bottom: 10 })
  }

  private previewText(content: string): string {
    return content.length > 30 ? `${content.substring(0, 30)}...` : content;
  }

  @Builder
  InputBar() {
    Row() {
      TextInput({ placeholder: '请输入消息...', text: this.inputText })
        .layoutWeight(1)
        .height(36)
        .fontSize(13)
        .fontColor('#333333')
        .placeholderColor('#999999')
        .backgroundColor(Color.Transparent)
        .padding({ left: 6, right: 6 })
        .onChange((value: string) => {
          this.inputText = value;
        })
      Text('➤')
        .fontSize(18)
        .fontColor(this.isAIReplying ? '#A0BFFF' : '#4A8BFF')
        .textAlign(TextAlign.Center)
        .width(36)
        .height(36)
        .onClick(() => {
          this.send(this.inputText);
        })
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 10, color: '#1A000000', offsetX: 0, offsetY: -2 })
  }

  build() {
    Column() {
      this.Header()
      Scroll(this.scroller) {
        Column() {
          ForEach(this.messages, (message: ChatMessage) => {
            if (message.role === 'ai') {
              this.AiBubble(message)
            } else {
              this.UserBubble(message)
            }
          }, (message: ChatMessage) => `${message.id}-${message.status}-${message.content.length}`)

          if (this.messages.length === 1) {
            this.PresetQuestions()
          }
        }
        .width('100%')
        .padding({ top: 10, bottom: 20 })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F5F5F7')
      .scrollBar(BarState.Off)

      Column() {
        this.InputBar()
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 6, bottom: 8 })
      .backgroundColor('#F5F5F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }
}
