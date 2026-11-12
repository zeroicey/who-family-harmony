import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { BackToTop } from '../components/common/BackToTop';
import { EmptyState } from '../components/common/EmptyState';
import { NetImage } from '../components/common/NetImage';
import { KnowledgeArticle } from '../models/MiniProgramModels';
import { ScrollToTop } from '../services/PagedList';
import { CacheStore } from '../stores/CacheStore';
import { MockData } from '../utils/MockData';

@Entry
@Component
export struct Knowledge {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State tabs: string[] = MockData.knowledgeTabs();
  @State activeTab: string = '前端';
  @State articles: KnowledgeArticle[] = MockData.knowledgeArticles();
  @State showBackToTop: boolean = false;
  private scroller: Scroller = new Scroller();

  filteredArticles(): KnowledgeArticle[] {
    return this.articles.filter((item: KnowledgeArticle) => item.category === this.activeTab);
  }

  async openArticle(item: KnowledgeArticle): Promise<void> {
    await CacheStore.setJson<KnowledgeArticle>(this.context, `knowledge:${item.id}`, item);
    router.pushUrl({ url: 'pages/KnowledgeArticle', params: { id: item.id } });
  }

  private avatarUrl(author: string): string {
    return `https://api.dicebear.com/7.x/pixel-art/png?seed=${encodeURIComponent(author)}`;
  }

  private levelColor(level: string): string {
    if (level === '高级') {
      return '#f44336';
    }
    if (level === '中级') {
      return '#ff9800';
    }
    return '#4caf50';
  }

  private levelBg(level: string): string {
    if (level === '高级') {
      return '#ffebee';
    }
    if (level === '中级') {
      return '#fff3e0';
    }
    return '#e8f5e3';
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

  @Builder TabItem(tab: string) {
    Text(tab)
      .fontSize(14)
      .fontWeight(this.activeTab === tab ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.activeTab === tab ? '#FFFFFF' : '#2979ff')
      .height(34)
      .padding({ left: 18, right: 18 })
      .backgroundColor(this.activeTab === tab ? '#2979ff' : '#f5f5f5')
      .borderRadius(20)
      .margin({ right: 8 })
      .onClick(() => {
        this.activeTab = tab;
      })
  }

  @Builder KnowledgeCard(item: KnowledgeArticle) {
    Column() {
      Row() {
        Row() {
          if (item.isRecommended) {
            Text('推荐')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 7, right: 7, top: 3, bottom: 3 })
              .backgroundColor('#ff6b6b')
              .borderRadius(4)
              .margin({ right: 8 })
          }
          Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
            .lineHeight(22)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)

        Text(item.level)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.levelColor(item.level))
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(this.levelBg(item.level))
          .borderRadius(12)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      Text(item.description)
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(21)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(item.tags, (tag: string) => {
          Text(tag)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#5a6c7d')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor('#f0f2f5')
            .borderRadius(4)
            .margin({ right: 6, bottom: 6 })
        }, (tag: string) => tag)
      }
      .width('100%')

      Row() {
        Stack() {
          NetImage({
            imageUrl: this.avatarUrl(item.author),
            imageHeight: 24,
            imageRadius: 12,
            fitMode: 'cover'
          })
        }
        .width(24)
        .height(24)
        .borderRadius(12)
        .clip(true)
        Text(item.author)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 8 })
        Text(item.publishDate)
          .fontSize(11)
          .fontColor('#999999')
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#f0f0f0' })
      .margin({ top: 6, bottom: 10 })

      Row() {
        Text(`⏱ ${item.readTime}`)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ right: 14 })
        Text(`📄 ${item.wordCount}字`)
          .fontSize(11)
          .fontColor('#999999')
          .layoutWeight(1)
        Text(`👁 ${this.formatNumber(item.views)}`)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ right: 12 })
        Text(`👍 ${this.formatNumber(item.likes)}`)
          .fontSize(11)
          .fontColor('#999999')
      }
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 10, color: '#0F000000', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 12 })
    .onClick(() => {
      this.openArticle(item);
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Scroll() {
          Row() {
            ForEach(this.tabs, (tab: string) => {
              this.TabItem(tab)
            }, (tab: string) => tab)
          }
          .padding({ left: 10, right: 10 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
        .height(40)
        .backgroundColor('#FFFFFF')
        .border({ width: { bottom: 1 }, color: '#e5e5e5' })
        .scrollBar(BarState.Off)

        Scroll(this.scroller) {
          Column() {
            if (this.filteredArticles().length === 0) {
              EmptyState({
                title: '暂无知识内容',
                description: '换个分类看看吧'
              })
                .margin({ top: 12 })
            } else {
              ForEach(this.filteredArticles(), (item: KnowledgeArticle) => {
                this.KnowledgeCard(item)
              }, (item: KnowledgeArticle) => `${item.id}-${item.likes}`)
            }
          }
          .width('100%')
          .padding(12)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .onScroll(() => {
          this.showBackToTop = Math.abs(this.scroller.currentOffset().yOffset) > 300;
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f5f5f5')

      BackToTop({
        visible: this.showBackToTop,
        onTap: () => {
          ScrollToTop.toTop(this.scroller);
          this.showBackToTop = false;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
