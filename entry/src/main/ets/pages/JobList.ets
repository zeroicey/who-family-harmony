import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { BackToTop } from '../components/common/BackToTop';
import { EmptyState } from '../components/common/EmptyState';
import { NetImage } from '../components/common/NetImage';
import { Skeleton } from '../components/common/Skeleton';
import { Tag } from '../components/common/Tag';
import { Job, JobType } from '../models/Job';
import { JobApi } from '../api/JobApi';
import { JobMock } from '../mock/JobMock';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { PageResult, PagedListController, ScrollToTop } from '../services/PagedList';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';

@Entry
@Component
export struct JobList {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State jobs: Job[] = [];
  @State types: JobType[] = [];
  @State selectedTypeIndex: number = 0;
  @State loading: boolean = true;
  @State refreshing: boolean = false;
  @State footerText: string = '';
  @State showBackToTop: boolean = false;
  @State usedFallback: boolean = false;
  @StorageLink('jobDelta') @Watch('onJobDelta') jobDelta: string = '';
  private scroller: Scroller = new Scroller();

  private pager: PagedListController<Job> =
    new PagedListController<Job>((cursor: string) => this.loadJobPage(cursor));

  aboutToAppear(): void {
    this.bootstrap();
  }

  private async bootstrap(): Promise<void> {
    this.loading = true;
    await this.loadTypes();
    await this.pager.refresh();
    this.syncPagerState();
    this.loading = false;
  }

  private async loadTypes(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      this.types = await JobApi.types(token, apiEnvironment);
    } catch (err) {
      LogUtil.warn('recruit', `job types failed ${(err as Error).message}`);
      this.types = [];
    }
  }

  /** 第一页 / lastId 分页；失败时退回缓存或本地 Mock，保证不白屏。 */
  private async loadJobPage(cursor: string): Promise<PageResult<Job>> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      const jobs = cursor.length > 0 ?
        await JobApi.recommendMore(token, cursor, apiEnvironment) :
        await JobApi.recommend(token, apiEnvironment);
      const nextCursor = jobs.length > 0 ? jobs[jobs.length - 1].id : '';
      const repeated = cursor.length > 0 && nextCursor === cursor;
      const hasMore = jobs.length >= 10 && !repeated && nextCursor.length > 0;
      if (cursor.length === 0) {
        this.usedFallback = false;
        await CacheStore.setJson<Job[]>(this.context, 'recruitJobs', jobs);
      }
      return new PageResult<Job>(jobs, hasMore ? nextCursor : '', hasMore);
    } catch (err) {
      LogUtil.warn('recruit', `jobs failed cursor=${cursor} ${(err as Error).message}`);
      if (cursor.length > 0) {
        throw new Error('加载更多失败，请重试');
      }
      this.usedFallback = true;
      const cached = await CacheStore.getJson<Job[]>(this.context, 'recruitJobs', []);
      if (cached.length > 0) {
        return new PageResult<Job>(cached, '', false);
      }
      return new PageResult<Job>(JobMock.jobs(), '', false);
    }
  }

  private allTabs(): JobType[] {
    const tabs: JobType[] = [
      new JobType('-1', '所有'),
      new JobType('-2', '已收藏')
    ];
    this.types.forEach((type: JobType) => {
      tabs.push(type);
    });
    return tabs;
  }

  private visibleJobs(): Job[] {
    if (this.selectedTypeIndex === 0) {
      return this.jobs;
    }
    if (this.selectedTypeIndex === 1) {
      return this.jobs.filter((job: Job) => job.collected);
    }
    const tabs = this.allTabs();
    if (this.selectedTypeIndex >= tabs.length) {
      return this.jobs;
    }
    const typeName = tabs[this.selectedTypeIndex].name;
    return this.jobs.filter((job: Job) => job.tags.length > 0 && job.tags[0] === typeName);
  }

  private syncPagerState(): void {
    this.jobs = this.pager.items;
    this.footerText = this.selectedTypeIndex === 0 ? this.pager.footerText() : '';
  }

  async onRefresh(): Promise<void> {
    this.refreshing = true;
    try {
      await this.pager.refresh();
      this.syncPagerState();
      ToastUtil.show(this.usedFallback ? '刷新失败，已显示本地缓存' : '刷新成功');
    } finally {
      this.refreshing = false;
    }
  }

  async loadMore(): Promise<void> {
    // 与小程序一致：仅在“所有”分类下分页，筛选结果本地过滤不分页。
    if (this.selectedTypeIndex !== 0) {
      return;
    }
    if (!this.pager.hasMore || this.pager.loading || this.pager.refreshing) {
      return;
    }
    this.footerText = '加载中...';
    await this.pager.loadMore();
    this.syncPagerState();
    if (this.pager.error.length > 0) {
      ToastUtil.show('加载失败');
    }
  }

  private selectType(index: number): void {
    this.selectedTypeIndex = index;
    this.footerText = index === 0 ? this.pager.footerText() : '';
    this.showBackToTop = false;
  }

  /** 详情页返回后同步收藏 / 投递状态。 */
  private onJobDelta(): void {
    if (this.jobDelta.length === 0) {
      return;
    }
    const parts = this.jobDelta.split('|');
    if (parts.length < 3) {
      AppStorage.setOrCreate<string>('jobDelta', '');
      return;
    }
    const id = parts[0];
    const collected = parts[1] === '1';
    const delivered = parts[2] === '1';
    const apply = (job: Job): Job => {
      if (job.id !== id) {
        return job;
      }
      job.collected = collected;
      job.isDeliver = delivered;
      return job;
    };
    this.jobs = this.jobs.map(apply);
    this.pager.items = this.pager.items.map(apply);
    AppStorage.setOrCreate<string>('jobDelta', '');
  }

  private firstLogoText(job: Job): string {
    if (job.organization.length > 0) {
      return job.organization.substring(0, 1);
    }
    return '招';
  }

  /** 与 RecruitCard.vue 的 formatTime 一致：yyyy-MM-dd。 */
  private deadline(job: Job): string {
    if (job.endTime.length === 0) {
      return '';
    }
    const day = job.endTime.substring(0, 10).split('-');
    if (day.length !== 3) {
      return job.endTime;
    }
    return `${day[0]}-${day[1]}-${day[2]}`;
  }

  openDetail(job: Job): void {
    router.pushUrl({
      url: 'pages/JobDetail',
      params: { id: job.id }
    });
  }

  private confirmSubmit(job: Job): void {
    if (job.isDeliver) {
      ToastUtil.show('您已投递过该职位');
      return;
    }
    AlertDialog.show({
      title: '确认投递',
      message: '确定要投递该职位吗？投递后无法撤销。',
      primaryButton: {
        value: '确定',
        action: () => {
          this.submit(job);
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {
        }
      }
    });
  }

  async submit(job: Job): Promise<void> {
    if (job.isDeliver) {
      return;
    }
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      await JobApi.submit(token, job.id, apiEnvironment);
      job.isDeliver = true;
      this.jobs = this.jobs.map((item: Job) => item.id === job.id ? job : item);
      this.pager.items = this.pager.items.map((item: Job) => item.id === job.id ? job : item);
      ToastUtil.show('投递成功');
    } catch (err) {
      LogUtil.warn('recruit', `submit failed ${(err as Error).message}`);
      ToastUtil.show('投递失败，请重试');
    }
  }

  @Builder
  CategoryTabs() {
    Scroll() {
      Row() {
        ForEach(this.allTabs(), (type: JobType, index: number) => {
          Column() {
            Text(type.name)
              .fontSize(14)
              .fontWeight(this.selectedTypeIndex === index ? FontWeight.Medium : FontWeight.Regular)
              .fontColor(this.selectedTypeIndex === index ? '#4a90e2' : '#666666')
            Text('')
              .width(20)
              .height(2)
              .backgroundColor(this.selectedTypeIndex === index ? '#4a90e2' : '#00FFFFFF')
              .borderRadius(1)
              .margin({ top: 4 })
          }
          .height(44)
          .padding({ left: 14, right: 14 })
          .margin({ left: 4, right: 4 })
          .justifyContent(FlexAlign.Center)
          .backgroundColor(this.selectedTypeIndex === index ? 'rgba(74,144,226,0.08)' : '#FFFFFF')
          .borderRadius(4)
          .onClick(() => {
            this.selectType(index);
          })
        }, (type: JobType) => type.id)
      }
      .padding({ left: 6, right: 6 })
      .height(52)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height(52)
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#f0f0f0' })
    .shadow({ radius: 4, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  RecruitCard(job: Job) {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          if (job.logoUrl.length > 0) {
            NetImage({
              imageUrl: job.logoUrl,
              imageHeight: 60,
              imageRadius: 10,
              fitMode: 'cover'
            })
              .width(60)
          } else {
            Text(this.firstLogoText(job))
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .width(60)
              .height(60)
              .textAlign(TextAlign.Center)
              .backgroundColor('#a8edea')
              .borderRadius(10)
          }
        }
        .width(60)
        .height(60)
        .margin({ right: 12 })
        .shadow({ radius: 12, color: '#4Da8edea', offsetX: 0, offsetY: 4 })

        Column() {
          Text(job.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1a1a1a')
            .lineHeight(24)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(job.organization)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8a8a8a')
          }
          .margin({ top: 5 })
          Row() {
            Tag({
              text: '活动招募',
              fgColor: '#1890ff',
              bgColor: '#e6f7ff',
              fontSize: 12,
              tagRadius: 12,
              tagPaddingH: 10,
              tagPaddingV: 4
            })
              .margin({ right: 8 })
            if (job.isHot) {
              Tag({
                text: '热门',
                fgColor: '#fa541c',
                bgColor: '#fff2e8',
                fontSize: 12,
                tagRadius: 12,
                tagPaddingH: 10,
                tagPaddingV: 4
              })
            }
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          if (job.isRecommended) {
            Tag({
              text: '推荐',
              fgColor: '#FFFFFF',
              bgColor: '#ff6b6b',
              fontSize: 10,
              tagRadius: 12,
              tagPaddingH: 8,
              tagPaddingV: 4
            })
          }
          if (job.location.length > 0) {
            Text(`📍${job.location}`)
              .fontSize(10)
              .fontColor('#666666')
              .padding({ left: 7, right: 7, top: 4, bottom: 4 })
              .backgroundColor('#FFFFFF')
              .border({ width: 1, color: '#f0f0f0' })
              .borderRadius(8)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 8 })
              .constraintSize({ maxWidth: 82 })
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .margin({ bottom: 16 })
      .onClick(() => {
        this.openDetail(job);
      })

      Text(job.description)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(22)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ bottom: 16 })

      Row() {
        Row() {
          Column() {
            Text('招募')
              .fontSize(12)
              .fontColor('#999999')
            Text(`${job.positions}人`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ right: 28 })
          Column() {
            Text('已申请')
              .fontSize(12)
              .fontColor('#999999')
            Text('12人')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)

        Column() {
          Text('截止日期')
            .fontSize(12)
            .fontColor('#999999')
          Text(this.deadline(job))
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#fa8c16')
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#f9fafc')
      .borderRadius(12)
      .margin({ bottom: 18 })

      Button(job.isDeliver ? '已投递' : '立即申请')
        .width('100%')
        .height(40)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(job.isDeliver ? '#999999' : '#FFFFFF')
        .backgroundColor(job.isDeliver ? '#d9d9d9' : '#1890ff')
        .borderRadius(20)
        .shadow({ radius: job.isDeliver ? 0 : 12, color: '#4D1890ff', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          this.confirmSubmit(job);
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 16, color: '#0F000000', offsetX: 0, offsetY: 4 })
    .margin({ bottom: 20 })
  }

  @Builder
  FallbackBanner() {
    Row() {
      Text('网络开小差了，已显示本地缓存')
        .fontSize(12)
        .fontColor('#B26A00')
        .layoutWeight(1)
      Text('重试')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1890ff')
        .onClick(() => {
          this.onRefresh();
        })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFF7E6')
    .border({ width: { bottom: 1 }, color: '#FFE7BA' })
  }

  @Builder
  EmptyTip() {
    if (this.selectedTypeIndex === 1) {
      EmptyState({
        title: '还没有收藏的岗位',
        description: '去岗位详情收藏感兴趣的岗位吧'
      })
        .margin({ top: 10 })
    } else if (this.selectedTypeIndex > 1) {
      EmptyState({
        title: '暂无相关岗位',
        description: '换个分类看看吧'
      })
        .margin({ top: 10 })
    } else {
      EmptyState({
        title: '暂无招聘信息',
        description: '稍后再来看看吧',
        actionText: '重新加载',
        onAction: () => {
          this.onRefresh();
        }
      })
        .margin({ top: 10 })
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        PageHeader({ title: '招聘' })
        this.CategoryTabs()
        if (this.usedFallback) {
          this.FallbackBanner()
        }
        Refresh({ refreshing: $$this.refreshing }) {
          Scroll(this.scroller) {
            Column() {
              if (this.loading && this.jobs.length === 0) {
                Skeleton({ rows: 5, showAvatar: true })
                  .margin({ top: 10 })
              } else if (this.visibleJobs().length === 0) {
                this.EmptyTip()
              } else {
                ForEach(this.visibleJobs(), (job: Job) => {
                  this.RecruitCard(job)
                }, (job: Job) => job.id)
              }
              if (this.footerText.length > 0) {
                Text(this.footerText)
                  .fontSize(13)
                  .fontColor('#999999')
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding({ top: 10, bottom: 20 })
              }
            }
            .width('100%')
            .padding(10)
          }
          .width('100%')
          .height('100%')
          .scrollBar(BarState.Off)
          .onScroll(() => {
            this.showBackToTop = Math.abs(this.scroller.currentOffset().yOffset) > 300;
          })
          .onScrollEdge((side: Edge) => {
            if (side === Edge.Bottom) {
              this.loadMore();
            }
          })
        }
        .layoutWeight(1)
        .onRefreshing(() => {
          this.onRefresh();
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
