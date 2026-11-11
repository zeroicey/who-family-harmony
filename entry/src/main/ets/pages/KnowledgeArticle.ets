import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { KnowledgeArticle, RouteParams } from '../models/MiniProgramModels';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
import { MarkdownView } from '../components/common/MarkdownView';
import { KnowledgeMock } from '../mock/KnowledgeMock';
@Entry
@Component
struct KnowledgeArticlePage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State article: KnowledgeArticle = MockData.knowledgeArticles()[0];
  @State isLiked: boolean = false;
  @State showAi: boolean = false;
  @State aiLoading: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    const id = params && params.id ? params.id : 'k-1';
    const fallback = MockData.knowledgeArticles().find((item: KnowledgeArticle) => item.id === id) || MockData.knowledgeArticles()[0];
    this.article = await CacheStore.getJson<KnowledgeArticle>(this.context, `knowledge:${id}`, fallback);
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

  private authorInitial(): string {
    return this.article.author.length > 0 ? this.article.author.substring(0, 1) : '互';
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

  toggleLike(): void {
    this.isLiked = !this.isLiked;
    ToastUtil.show(this.isLiked ? '收藏成功' : '取消收藏');
  }

  showAIInterpretation(): void {
    this.showAi = true;
    this.aiLoading = true;
    setTimeout(() => {
      this.aiLoading = false;
    }, 600);
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
        Text(this.authorInitial())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#2979FF')
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
        Text(`👍 ${this.formatNumber(this.article.likes)}`)
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
    .padding({ left: 16, right: 16, top: 34, bottom: 16 })
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
      Text('AI')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#101010')
        .textAlign(TextAlign.Center)
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
          .onClick(() => {
            this.showAi = false;
          })
      }
      .width('100%')
      if (this.aiLoading) {
        Text('AI 正在解读文章...')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 48, bottom: 48 })
      } else {
        Text(`这篇文章适合${this.article.level}水平学习，核心内容围绕${this.article.tags.join('、')}展开。建议先抓住概念，再结合题目或项目实践复盘。`)
          .fontSize(14)
          .fontColor('#555555')
          .lineHeight(24)
          .margin({ top: 14 })
        Text('学习建议')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 18, bottom: 8 })
        Text('1. 先通读文章，标记不理解的概念。\n2. 用一个小例子手写推导。\n3. 学完后用任务页记录下一步练习。')
          .fontSize(14)
          .fontColor('#555555')
          .lineHeight(24)
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('90%')
    .padding(18)
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
