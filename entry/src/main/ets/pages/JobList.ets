import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { NetImage } from '../components/common/NetImage';
import { Job } from '../models/Job';
import { JobApi } from '../api/JobApi';
import { AuthStore } from '../stores/AuthStore';
import { LogUtil } from '../utils/LogUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
export struct JobList {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State jobs: Job[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const apiEnvironment = await AuthStore.getApiEnvironment(this.context);
    try {
      this.jobs = await JobApi.recommend(token, apiEnvironment);
    } catch (err) {
      LogUtil.warn('recruit', `recommend jobs failed ${(err as Error).message}`);
      this.jobs = [];
    }
  }

  private firstLogoText(job: Job): string {
    if (job.organization.length > 0) {
      return job.organization.substring(0, 1);
    }
    return '招';
  }

  private deadline(job: Job): string {
    if (job.endTime.length === 0) {
      return '';
    }
    return job.endTime.substring(0, 10);
  }

  openDetail(job: Job): void {
    router.pushUrl({
      url: 'pages/JobDetail',
      params: { id: job.id }
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
    } catch (err) {
      LogUtil.warn('recruit', `submit failed ${(err as Error).message}`);
    }
  }

  @Builder RecruitCard(job: Job) {
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
            Text('')
              .width(3)
              .height(3)
              .backgroundColor('#a8edea')
              .borderRadius(2)
              .margin({ right: 6 })
            Text(job.organization)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#8a8a8a')
          }
          .margin({ top: 5 })
          Row() {
            Text('活动招募')
              .fontSize(12)
              .fontColor('#1890ff')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#e6f7ff')
              .borderRadius(12)
              .margin({ right: 8 })
            if (job.isHot) {
              Text('热门')
                .fontSize(12)
                .fontColor('#fa541c')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .backgroundColor('#fff2e8')
                .borderRadius(12)
            }
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          if (job.isRecommended) {
            Text('推荐')
              .fontSize(10)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#ff6b6b')
              .borderRadius(12)
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
          this.submit(job);
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

  build() {
    Column() {
      PageHeader({ title: '招聘' })
      Scroll() {
      Column() {
        ForEach(this.jobs, (job: Job) => {
          this.RecruitCard(job)
        }, (job: Job) => job.id)
      }
      .width('100%')
      .padding(10)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
