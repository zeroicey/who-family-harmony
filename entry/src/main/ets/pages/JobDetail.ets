import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Job } from '../models/Job';
import { RouteParams } from '../models/MiniProgramModels';
import { RemoteImage } from '../components/RemoteImage';
import { JobApi } from '../api/JobApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct JobDetail {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State job: Job = MockData.jobs()[0];
  @State isDelivered: boolean = false;
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    const id = params && params.id ? params.id : await CacheStore.getString(this.context, 'lastJobId', 'job-1');
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    this.loading = true;
    try {
      const detail = await JobApi.detail(token, id, apiEnvironment);
      if (detail !== null) {
        this.job = detail;
        this.isDelivered = detail.isDeliver;
        await CacheStore.setJson<Job>(this.context, `job:${id}`, this.job);
      }
    } catch (_) {
      const fallback = MockData.jobs().find((item: Job) => item.id === id) || MockData.jobs()[0];
      this.job = await CacheStore.getJson<Job>(this.context, `job:${id}`, fallback);
      this.isDelivered = this.job.isDeliver;
      LogUtil.warn('job-detail', `detail fallback id=${id}`);
    }
    this.loading = false;
  }

  async toggleCollect(): Promise<void> {
    const nextCollected = !this.job.collected;
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      await JobApi.collect(token, this.job.id, nextCollected, apiEnvironment);
      this.job.collected = nextCollected;
      ToastUtil.show(nextCollected ? '收藏成功' : '取消收藏成功');
    } catch (_) {
      this.job.collected = nextCollected;
      ToastUtil.show(nextCollected ? '已收藏' : '已取消收藏');
    }
    await CacheStore.setJson<Job>(this.context, `job:${this.job.id}`, this.job);
  }

  handleApply(): void {
    if (this.isDelivered) {
      ToastUtil.show('您已投递过该职位');
      return;
    }
    AlertDialog.show({
      title: '确认投递',
      message: '确定要投递该职位吗？投递后无法撤销。',
      primaryButton: {
        value: '确定',
        action: () => {
          this.submitJob();
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    });
  }

  async submitJob(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      await JobApi.submit(token, this.job.id, apiEnvironment);
      this.isDelivered = true;
      this.job.isDeliver = true;
      ToastUtil.show('投递成功');
      await CacheStore.setJson<Job>(this.context, `job:${this.job.id}`, this.job);
    } catch (err) {
      ToastUtil.show(`投递失败：${(err as Error).message}`);
    }
  }

  private locationText(): string {
    return this.job.location.length > 0 ? `📍 ${this.job.location}` : '📍 校园内';
  }

  private typeText(): string {
    return this.job.tags.length > 0 && this.job.tags[0].length > 0 ? this.job.tags[0] : '校园岗位';
  }

  private positionsText(): string {
    return this.job.positions > 0 ? `${this.job.positions}人` : '若干';
  }

  private dateText(value: string): string {
    if (value.length >= 10) {
      return value.substring(0, 10);
    }
    return value.length > 0 ? value : '长期有效';
  }

  @Builder
  HeaderSection() {
    Column() {
      Row() {
        if (this.job.logoUrl.length > 0) {
          RemoteImage({
            imageUrl: this.job.logoUrl,
            imageHeight: 50,
            imageRadius: 6,
            fitMode: 'contain'
          })
            .width(50)
            .backgroundColor('#F5F5F5')
        } else {
          Text(this.job.organization.length > 0 ? this.job.organization.substring(0, 1) : '互')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1890FF')
            .textAlign(TextAlign.Center)
            .width(50)
            .height(50)
            .borderRadius(6)
            .backgroundColor('#E6F7FF')
        }
        Column() {
          Text(this.job.organization.length > 0 ? this.job.organization : '互成一家')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text(this.locationText())
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 10 })
      }
      .width('100%')

      Column() {
        Text(this.job.title.length > 0 ? this.job.title : '岗位详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .lineHeight(24)
          .width('100%')
        Text(this.job.salary.length > 0 ? this.job.salary : '面议')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF4D4F')
          .margin({ top: 6 })
        Flex({ wrap: FlexWrap.Wrap }) {
          Text(this.typeText())
            .fontSize(11)
            .fontColor('#1890FF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .backgroundColor('#E6F7FF')
            .borderRadius(8)
            .margin({ top: 10, right: 6 })
          if (this.job.isHot) {
            Text('🔥 热门')
              .fontSize(11)
              .fontColor('#FA8C16')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#FFF2E8')
              .borderRadius(8)
              .margin({ top: 10, right: 6 })
          }
          if (this.job.isRecommended) {
            Text('⭐ 推荐')
              .fontSize(11)
              .fontColor('#52C41A')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('#F6FFED')
              .borderRadius(8)
              .margin({ top: 10, right: 6 })
          }
        }
        .width('100%')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: 16 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 6, color: '#0A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  DetailSection(title: string, content: string, isContact: boolean = false) {
    Column() {
      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 10 })
      Text(content.length > 0 ? content : '暂无')
        .fontSize(13)
        .fontColor(isContact ? '#1890FF' : '#666666')
        .lineHeight(22)
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ top: 8 })
    .shadow({ radius: 6, color: '#0A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  InfoGrid() {
    Column() {
      Text('📊 招聘信息')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 10 })
      Row() {
        this.InfoCell('招聘人数', this.positionsText())
        this.InfoCell('投递状态', this.isDelivered ? '已投递' : '未投递')
      }
      .width('100%')
      Row() {
        this.InfoCell('截止时间', this.dateText(this.job.endTime))
        this.InfoCell('发布时间', '最近更新')
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ top: 8 })
    .shadow({ radius: 6, color: '#0A000000', offsetX: 0, offsetY: 1 })
  }

  @Builder
  InfoCell(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor('#999999')
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 3 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(8)
    .backgroundColor('#FAFAFA')
    .borderRadius(4)
    .margin({ right: 5 })
  }

  build() {
    Column() {
      if (this.loading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height('100%')
      } else {
        Scroll() {
          Column() {
            this.HeaderSection()
            this.DetailSection('📋 职位描述', this.job.description)
            this.DetailSection('✅ 任职要求', this.job.requirement)
            this.DetailSection('🎁 福利待遇', this.job.welfare)
            this.DetailSection('📞 联系方式', this.job.contact, true)
            this.InfoGrid()
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 84 })
        }
        .layoutWeight(1)

        Row() {
          Column() {
            Text(this.job.collected ? '❤️' : '🤍')
              .fontSize(18)
            Text(this.job.collected ? '已收藏' : '收藏')
              .fontSize(11)
              .fontColor('#666666')
              .margin({ top: 1 })
          }
          .justifyContent(FlexAlign.Center)
          .width(50)
          .height(44)
          .borderRadius(6)
          .backgroundColor('#F8F9FA')
          .border({ width: 1, color: '#E8E8E8' })
          .onClick(() => {
            this.toggleCollect();
          })

          Button(this.isDelivered ? '已投递' : '立即申请')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isDelivered ? '#999999' : '#FFFFFF')
            .backgroundColor(this.isDelivered ? '#D9D9D9' : '#1890FF')
            .borderRadius(6)
            .margin({ left: 10 })
            .onClick(() => {
              this.handleApply();
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 16 })
        .backgroundColor('#FFFFFF')
        .border({ width: { top: 1 }, color: '#F0F0F0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}
