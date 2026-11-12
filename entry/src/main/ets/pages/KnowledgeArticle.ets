import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { KnowledgeArticle, RouteParams } from '../models/MiniProgramModels';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
import { MarkdownView } from '../components/common/MarkdownView';
import { NetImage } from '../components/common/NetImage';
import { KnowledgeMock } from '../mock/KnowledgeMock';
import { AiCallbacks, AiMessage, AiOptions, AiService, AiSession } from '../services/AiService';

@Entry
@Component
struct KnowledgeArticlePage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State article: KnowledgeArticle = MockData.knowledgeArticles()[0];
  @State isLiked: boolean = false;
  @State showAi: boolean = false;
  @State aiLoading: boolean = false;
  @State aiText: string = '';
  @State aiError: string = '';
  private aiSession: AiSession | null = null;
  private aiScroller: Scroller = new Scroller();

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
    const params = router.getParams() as RouteParams;
    const id = params && params.id ? params.id : 'k-1';
    // 正文是随包静态内容，必须优先使用当前 Mock，避免读到旧版本缓存导致截断。
    const fallback = MockData.knowledgeArticles().find((item: KnowledgeArticle) => item.id === id) ||
      MockData.knowledgeArticles()[0];
    this.article = fallback;
    this.isLiked = false;
    await CacheStore.setJson<KnowledgeArticle>(this.context, `knowledge:${this.article.id}`, this.article);
  }

  private levelBg(): string {
    if (this.article.level === '高级') {
      return '#FFEBEE';
    }
    if (this.article.level === '中级') {
      return '#FFF3E0';
    }
    return '#E8F5E3';
  }

  private levelColor(): string {
    if (this.article.level === '高级') {
      return '#F44336';
    }
    if (this.article.level === '中级') {
      return '#FF9800';
    }
    return '#4CAF50';
  }

  private avatarUrl(author: string): string {
    return `https://api.dicebear.com/7.x/pixel-art/png?seed=${encodeURIComponent(author)}`;
  }

  private formatNumber(value: number): string {
    if (value >= 10000) {
      return `${(value / 10000).toFixed(1)}w`;
    }
    if (value >= 1000) {
      return `${(value / 1000).toFixed(1)}k`;
    }
    return `${value}`;
  }

  private likeCount(): number {
    return this.article.likes;
  }

  toggleLike(): void {
    this.isLiked = !this.isLiked;
    ToastUtil.show(this.isLiked ? '收藏成功' : '取消收藏');
  }

  private aiPrompt(): string {
    return `请解读下面这篇文章，用 Markdown 输出：核心要点、关键概念解释、学习建议。\n\n` +
      `标题：${this.article.title}\n` +
      `难度：${this.article.level}\n` +
      `标签：${this.article.tags.join('、')}\n` +
      `摘要：${this.article.description}\n\n` +
      `正文：\n${KnowledgeMock.articleMarkdown(this.article)}`;
  }

  private aiScrollToBottom(): void {
    setTimeout(() => {
      try {
        this.aiScroller.scrollEdge(Edge.Bottom);
      } catch (_) {
      }
    }, 40);
  }

  showAIInterpretation(): void {
    this.showAi = true;
    this.aiLoading = true;
    this.aiText = '';
    this.aiError = '';
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
    const options = new AiOptions();
    options.maxTokens = 1200;
    options.temperature = 0.6;
    options.retries = 1;
    const messages: AiMessage[] = [
      new AiMessage('system',
        '你是校园知识库的 AI 解读助手。请用 Markdown 输出结构化的文章解读，包含核心要点、难点解释和学习建议；只依据文章内容，不要编造。'),
      new AiMessage('user', this.aiPrompt())
    ];
    const callbacks = new AiCallbacks(
      (chunk: string) => {
        this.aiText += chunk;
        this.aiLoading = true;
        this.aiScrollToBottom();
      },
      (fullText: string) => {
        if (fullText.length > 0) {
          this.aiText = fullText;
        }
        this.aiLoading = false;
        this.aiSession = null;
      },
      (message: string) => {
        LogUtil.warn('knowledge-ai', `interpret failed ${message}`);
        this.aiError = message;
        this.aiLoading = false;
        this.aiSession = null;
      }
    );
    this.aiSession = AiService.chatWithMessages(messages, callbacks, options);
  }

  @Builder
  ArticleHeader() {
    Column() {
      Row() {
        Text(this.article.level)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.levelColor())
          .backgroundColor(this.levelBg())
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        Text(this.article.publishDate)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 8 })
      }
      .width('100%')

      Text(this.article.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .lineHeight(31)
        .width('100%')
        .margin({ top: 14 })

      Row() {
        Stack() {
          NetImage({
            imageUrl: this.avatarUrl(this.article.author),
            imageHeight: 40,
            imageRadius: 20,
            fitMode: 'cover'
          })
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .clip(true)
        Column() {
          Text(this.article.author)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(`${this.article.readTime} · ${this.article.wordCount}字`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 8 })
      }
      .width('100%')
      .margin({ top: 14 })

      Row() {
        Text(`👁 ${this.formatNumber(this.article.views)}`)
          .fontSize(12)
          .fontColor('#666666')
        Text(`👍 ${this.formatNumber(this.likeCount())}`)
          .fontSize(12)
          .fontColor('#666666')
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ top: 10 })
      .margin({ top: 10 })
      .border({ width: { top: 1 }, color: '#F0F0F0' })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TagsSection() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.article.tags, (tag: string) => {
        Text(`#${tag}`)
          .fontSize(12)
          .fontColor('#2979FF')
          .backgroundColor('#E8F2FF')
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .margin({ right: 8, bottom: 8 })
      }, (tag: string) => tag)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 4 })
    .backgroundColor('#FFFFFF')
  }

  @Builder
  ArticleContent() {
    Column() {
      MarkdownView({ markdown: KnowledgeMock.articleMarkdown(this.article) })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }

  @Builder
  FloatButtons() {
    Column() {
      Text(this.isLiked ? '❤️' : '🤍')
        .fontSize(22)
        .textAlign(TextAlign.Center)
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 10, color: '#26000000', offsetX: 0, offsetY: 2 })
        .onClick(() => {
          this.toggleLike();
        })
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.icon_tab_helper'))
          .width(24)
          .height(24)
          .objectFit(ImageFit.Contain)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('#39FF14')
      .margin({ top: 12 })
      .shadow({ radius: 10, color: '#26000000', offsetX: 0, offsetY: 2 })
      .onClick(() => {
        this.showAIInterpretation();
      })
    }
  }

  @Builder
  AiPanel() {
    Column() {
      Row() {
        Text('AI 智能解读')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('关闭')
          .fontSize(13)
          .fontColor('#2979FF')
          .padding({ left: 10, top: 4, bottom: 4 })
          .onClick(() => {
            this.showAi = false;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Scroll(this.aiScroller) {
        Column() {
          if (this.aiError.length > 0) {
            Text(`⚠️ ${this.aiError}`)
              .fontSize(13)
              .fontColor('#DD524D')
              .lineHeight(21)
              .width('100%')
            Button('重新解读')
              .height(34)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor('#2979FF')
              .borderRadius(6)
              .margin({ top: 14 })
              .onClick(() => {
                this.showAIInterpretation();
              })
          } else if (this.aiText.length === 0) {
            Row() {
              LoadingProgress()
                .width(22)
                .height(22)
                .color('#2979FF')
              Text('AI 正在解读文章...')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ left: 10 })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 60, bottom: 60 })
          } else {
            MarkdownView({ markdown: this.aiText, baseFontSize: 14 })
              .width('100%')
            if (this.aiLoading) {
              Text('▋')
                .fontSize(12)
                .fontColor('#2979FF')
                .margin({ top: 4 })
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .alignItems(HorizontalAlign.Start)
    .width('90%')
    .height('78%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 18, color: '#33000000', offsetX: 0, offsetY: 6 })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        PageHeader({ title: '知识详情' })
        Scroll() {
          Column() {
            this.ArticleHeader()
            this.TagsSection()
            Divider()
              .height(8)
              .color('#FAFAFA')
            this.ArticleContent()
          }
          .width('100%')
          .padding({ bottom: 92 })
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      Column() {
        this.FloatButtons()
      }
      .margin({ right: 16, bottom: 50 })

      if (this.showAi) {
        Column() {
          this.AiPanel()
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }
}
