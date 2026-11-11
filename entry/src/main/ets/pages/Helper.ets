import { common } from '@kit.AbilityKit';
import { AppIcon } from '../components/AppIcon';
import { ChatMessage, PresetQuestion } from '../models/MiniProgramModels';
import { HelperApi } from '../api/HelperApi';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';
import { MarkdownView } from '../components/common/MarkdownView';
import { AiCallbacks, AiSession } from '../services/AiService';

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

  async load(): Promise<void> {
    const cached = await CacheStore.getJson<ChatMessage[]>(this.context, 'helperMessages', MockData.initialMessages());
    this.messages = cached.filter((item: ChatMessage) => item.id.indexOf('ai-pending') !== 0);
    this.scrollToBottom();
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

  async send(content: string): Promise<void> {
    if (this.isAIReplying) {
      ToastUtil.show('AI 正在回复，请稍候');
      return;
    }
    const safeText = content.trim();
    if (safeText.length === 0) {
      ToastUtil.show('请输入问题');
      return;
    }
    const userMessage = new ChatMessage(`user-${new Date().getTime()}`, 'user', safeText);
    const pendingId = `ai-pending-${new Date().getTime()}`;
    const pendingMessage = new ChatMessage(pendingId, 'ai', '正在思考...');
    this.messages = this.messages.concat([userMessage, pendingMessage]);
    this.inputText = '';
    this.isAIReplying = true;
    this.scrollToBottom();
    let accumulated = '';
    const callbacks = new AiCallbacks(
      (chunk: string) => {
        accumulated += chunk;
        this.replaceMessage(pendingId, accumulated);
      },
      (fullText: string) => {
        this.replaceMessage(pendingId, fullText);
        this.isAIReplying = false;
        this.aiSession = null;
        this.persistMessages();
      },
      (message: string) => {
        this.replaceMessage(pendingId, message);
        this.isAIReplying = false;
        this.aiSession = null;
        this.persistMessages();
        ToastUtil.show('AI 回复失败');
      }
    );
    // 逐字流式输出；请求失败时 AiService 自动重试一次
    this.aiSession = HelperApi.sendStream(safeText, callbacks);
  }

  private persistMessages(): void {
    CacheStore.setJson<ChatMessage[]>(this.context, 'helperMessages', this.messages).catch(() => {
    });
  }

  replaceMessage(id: string, content: string): void {
    const updatedMessages: ChatMessage[] = [];
    this.messages.forEach((message: ChatMessage) => {
      if (message.id === id) {
        updatedMessages.push(new ChatMessage(id, 'ai', content));
      } else {
        updatedMessages.push(message);
      }
    });
    this.messages = updatedMessages;
    this.scrollToBottom();
  }

  clearMessages(): void {
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
          CacheStore.setJson<ChatMessage[]>(this.context, 'helperMessages', this.messages);
        }
      },
      secondaryButton: { value: '取消', action: () => {} }
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
        .borderRadius(15)
        .backgroundColor('#CCFFFFFF')
        .onClick(() => {
          this.clearMessages();
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
  MessageBubble(message: ChatMessage) {
    Row() {
      if (message.role === 'user') {
        Blank()
          .layoutWeight(1)
      }
      if (message.role === 'ai') {
        AppIcon({ name: 'ai', iconSize: 30, radius: 15 })
          .margin({ right: 8 })
      }
      Column() {
        if (message.role === 'ai') {
          MarkdownView({ markdown: message.content, baseFontSize: 14 })
            .width('100%')
        } else {
          Text(message.content)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .lineHeight(22)
        }
      }
      .constraintSize({ maxWidth: '78%' })
      .padding({ left: 14, right: 14, top: 11, bottom: 11 })
      .backgroundColor(message.role === 'user' ? '#007AFF' : '#FFFFFF')
      .borderRadius(16)
      .shadow(message.role === 'ai' ? { radius: 4, color: '#0A000000', offsetX: 0, offsetY: 1 } : undefined)
      if (message.role === 'ai') {
        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .margin({ top: 10 })
  }

  @Builder
  PresetQuestions() {
    Column() {
      ForEach(this.questions, (question: PresetQuestion) => {
        Text(question.title)
          .fontSize(13)
          .fontColor('#007AFF')
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ top: 8 })
          .onClick(() => {
            this.send(question.content);
          })
      }, (question: PresetQuestion) => question.id)
    }
    .width('100%')
    .margin({ top: 10 })
  }

  build() {
    Column() {
      this.Header()
      Scroll(this.scroller) {
        Column() {
          ForEach(this.messages, (message: ChatMessage) => {
            this.MessageBubble(message)
          }, (message: ChatMessage) => `${message.id}-${message.content.length}-${message.content}`)

          if (this.messages.length === 1) {
            this.PresetQuestions()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 24 })
      }
      .layoutWeight(1)

      Row() {
        TextInput({ placeholder: '请输入你的问题', text: this.inputText })
          .layoutWeight(1)
          .height(44)
          .fontSize(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(22)
          .onChange((value: string) => {
            this.inputText = value;
          })
        Button(this.isAIReplying ? '思考中' : '发送')
          .height(44)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isAIReplying ? '#8EBBFF' : '#007AFF')
          .borderRadius(22)
          .margin({ left: 8 })
          .onClick(() => {
            this.send(this.inputText);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 14 })
      .backgroundColor('#F5F5F7')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }
}
