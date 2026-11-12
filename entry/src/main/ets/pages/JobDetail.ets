import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { Job } from '../models/Job';
import { RouteParams } from '../models/MiniProgramModels';
import { LoadingView } from '../components/common/LoadingView';
import { NetImage } from '../components/common/NetImage';
import { Tag } from '../components/common/Tag';
import { JobApi } from '../api/JobApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct JobDetail {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State job: Job = MockData.jobs()[0];
  @State isDelivered: boolean = false;
  @State loading: boolean = true;
  @State loadError: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    const params = router.getParams() as RouteParams;
    const id = params && params.id ? params.id : await CacheStore.getString(this.context, 'lastJobId', 'job-1');
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    this.loading = true;
    this.loadError = false;
    try {
      const detail = await JobApi.detail(token, id, apiEnvironment);
      if (detail !== null) {
        this.job = detail;
        this.isDelivered = detail.isDeliver;
        await CacheStore.setJson<Job>(this.context, `job:${id}`, this.job);
      } else {
        this.applyCachedJob(id);
      }
    } catch (_) {
      LogUtil.warn('job-detail', `detail fallback id=${id}`);
      await this.applyCachedJob(id);
    }
    this.loading = false;
  }

  /** 网络失败时优先用该岗位的缓存；没有缓存进入失败态，避免展示错误岗位。 */
  private async applyCachedJob(id: string): Promise<void> {
    const cached = await CacheStore.getJson<Job>(this.context, `job:${id}`, new Job('__missing__'));
    if (cached.id === id) {
      this.job = cached;
      this.isDelivered = cached.isDeliver;
      this.loadError = false;
    } else {
      this.loadError = true;
    }
  }

  private publishDelta(): void {
    AppStorage.setOrCreate<string>('jobDelta',
      `${this.job.id}|${this.job.collected ? '1' : '0'}|${this.isDelivered ? '1' : '0'}`);
  }

  async toggleCollect(): Promise<void> {
    const nextCollected = !this.job.collected;
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      await JobApi.collect(token, this.job.id, nextCollected, apiEnvironment);
      this.job.collected = nextCollected;
      ToastUtil.show(nextCollected ? '收藏成功' : '取消收藏');
      await CacheStore.setJson<Job>(this.context, `job:${this.job.id}`, this.job);
      this.publishDelta();
    } catch (err) {
      LogUtil.warn('job-detail', `collect failed ${(err as Error).message}`);
      ToastUtil.show('操作失败，请重试');
    }
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
      this.publishDelta();
    } catch (err) {
      ToastUtil.show(`投递失败：${(err as Error).message}`);
    }
  }

  private locationText(): string {
    return this.job.location.length > 0 ? `📍 ${this.job.location}` : '📍';
  }

  private typeText(): string {
    return this.job.tags.length > 0 && this.job.tags[0].length > 0 ? this.job.tags[0] : '活动招募';
  }

  private positionsText(): string {
    return `${this.job.positions ? this.job.positions : 0}人`;
  }

  private deliverCountText(): string {
    return `${this.job.deliverCount ? this.job.deliverCount : 0}人`;
  }

  private dateText(value: string): string {
    if (!value) {
      return '';
    }
    if (value.length >= 10) {
      return value.substring(0, 10);
    }
    return value;
  }

  /** 与 detail.vue 的 formatText 一致：把接口返回的 ↵ 还原成换行。 */
  private formatText(content: string): string {
    return content.split('↵').join('\n');
  }

  @Builder
  HeaderSection() {
    Column() {
      Row() {
        if (this.job.logoUrl.length > 0) {
          NetImage({
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
          Tag({
            text: this.typeText(),
            fgColor: '#1890FF',
            bgColor: '#E6F7FF',
            fontSize: 11,
            tagRadius: 8,
            tagPaddingH: 8,
            tagPaddingV: 3
          })
            .margin({ top: 10, right: 6 })
          if (this.job.isHot) {
            Tag({
              text: '🔥 热门',
              fgColor: '#FA8C16',
              bgColor: '#FFF2E8',
              fontSize: 11,
              tagRadius: 8,
              tagPaddingH: 8,
              tagPaddingV: 3
            })
              .margin({ top: 10, right: 6 })
          }
          if (this.job.isRecommended) {
            Tag({
              text: '⭐ 推荐',
              fgColor: '#52C41A',
              bgColor: '#F6FFED',
              fontSize: 11,
              tagRadius: 8,
              tagPaddingH: 8,
              tagPaddingV: 3
            })
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
      Text(content.length > 0 ? this.formatText(content) : '暂无')
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
        this.InfoCell('投递人数', this.deliverCountText())
      }
      .width('100%')
      Row() {
        this.InfoCell('截止时间', this.dateText(this.job.endTime))
        this.InfoCell('发布时间', this.dateText(this.job.createTime))
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
      PageHeader({ title: '招聘详情' })
      if (this.loading) {
        LoadingView({ text: '正在加载招聘详情', minHeight: 240 })
          .width('100%')
      } else if (this.loadError) {
        Column() {
          Text('加载失败，请重试')
            .fontSize(15)
            .fontColor('#666666')
            .margin({ bottom: 18 })
          Button('重新加载')
            .height(38)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1890FF')
            .borderRadius(6)
            .onClick(() => {
              this.load();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
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
