import { Banner } from '../models/Banner';
import { CommunityPost } from '../models/CommunityPost';
import { Job } from '../models/Job';
import { PrintPrice } from '../models/MiniProgramModels';
import { UserProfile } from '../models/UserProfile';
import { ServiceItem } from '../utils/MockData';
import { CoverImage } from './common/CoverImage';
import { ServiceCard } from './ServiceCard';
import { JobCard } from './JobCard';
import { AppColors, AppFont, AppRadius, AppSpace } from '../theme/Theme';

@Component
export struct HomeHeaderCard {
  @Prop username: string = '同学';
  @Prop dateText: string = '6.9 · 星期二';
  @Prop banner: Banner = new Banner();

  build() {
    Column() {
      Row() {
        Text(`你好，${this.username}`)
          .fontSize(AppFont.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textPrimary)
          .layoutWeight(1)
        Text(this.dateText)
          .fontSize(AppFont.sm)
          .fontColor(AppColors.textSecondary)
          .backgroundColor(AppColors.bgPage)
          .borderRadius(AppRadius.pill)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      }
      .width('100%')
      CoverImage({
        imageUrl: this.banner.imageUrl,
        title: this.banner.title,
        watermarkText: '互成一家',
        imageHeight: 150,
        imageRadius: AppRadius.xl
      })
        .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }
}

@Component
export struct ServiceRecommendCard {
  @Prop item: ServiceItem = new ServiceItem('', '', '', 'tab_service', '');

  build() {
    Column() {
      CoverImage({
        imageUrl: this.item.imageUrl,
        title: this.item.title,
        watermarkText: '互成一家 · 服务',
        imageHeight: 112,
        imageRadius: AppRadius.lg
      })
      ServiceCard({ title: this.item.title, summary: this.item.summary, iconText: this.item.iconText })
        .margin({ top: AppSpace.sm })
    }
    .width('100%')
  }
}

@Component
export struct CommunityPostCard {
  @Prop post: CommunityPost = new CommunityPost();

  build() {
    Column() {
      Row() {
        Text(this.post.author)
          .fontSize(AppFont.base)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.textPrimary)
          .layoutWeight(1)
        Text(this.post.publishTime)
          .fontSize(AppFont.sm)
          .fontColor(AppColors.textTertiary)
      }
      Text(this.post.title)
        .fontSize(AppFont.lg)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.textPrimary)
        .width('100%')
        .margin({ top: AppSpace.md })
      Text(this.post.content)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textSecondary)
        .lineHeight(21)
        .width('100%')
        .margin({ top: AppSpace.sm })
      if (this.post.imageUrl.length > 0) {
        CoverImage({
          imageUrl: this.post.imageUrl,
          title: this.post.title,
          watermarkText: '互成一家 · 社区',
          imageHeight: 120,
          imageRadius: AppRadius.lg
        })
          .margin({ top: AppSpace.md })
      }
      Text(`点赞 ${this.post.likeCount}`)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.brandBlue)
        .margin({ top: AppSpace.md })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor(AppColors.bgCard)
    .borderRadius(AppRadius.lg)
  }
}

@Component
export struct RecruitCard {
  @Prop job: Job = new Job();

  build() {
    JobCard({ job: this.job })
  }
}

@Component
export struct PrintPriceCard {
  @Prop price: PrintPrice = new PrintPrice();

  build() {
    Column() {
      Text(this.price.name)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textSecondary)
      Text(`¥${this.price.price}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.brandBlue)
        .margin({ top: 6 })
      Text(this.price.unit)
        .fontSize(AppFont.xs)
        .fontColor(AppColors.textTertiary)
        .margin({ top: 2 })
    }
    .height(94)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(AppColors.bgCard)
    .borderRadius(AppRadius.lg)
  }
}

@Component
export struct UserProfileCard {
  @Prop user: UserProfile = new UserProfile();

  build() {
    Column() {
      Text(this.user.nickname)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.textPrimary)
      Text(`${this.user.school} · ${this.user.major} · ${this.user.grade}`)
        .fontSize(AppFont.sm)
        .fontColor(AppColors.textSecondary)
        .lineHeight(20)
        .margin({ top: AppSpace.sm })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(AppSpace.lg)
    .backgroundColor(AppColors.bgCard)
    .borderRadius(AppRadius.xl)
  }
}
