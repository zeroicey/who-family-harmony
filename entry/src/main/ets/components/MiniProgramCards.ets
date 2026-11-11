import { Banner } from '../models/Banner';
import { CommunityPost } from '../models/CommunityPost';
import { Job } from '../models/Job';
import { PrintPrice } from '../models/MiniProgramModels';
import { UserProfile } from '../models/UserProfile';
import { ServiceItem } from '../utils/MockData';
import { WatermarkImage } from './WatermarkImage';
import { ServiceCard } from './ServiceCard';
import { JobCard } from './JobCard';

@Component
export struct HomeHeaderCard {
  @Prop username: string = '同学';
  @Prop dateText: string = '6.9 · 星期二';
  @Prop banner: Banner = new Banner();

  build() {
    Column() {
      Row() {
        Text(`你好，${this.username}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .layoutWeight(1)
        Text(this.dateText)
          .fontSize(12)
          .fontColor('#667085')
          .backgroundColor('#F2F4F7')
          .borderRadius(14)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      }
      .width('100%')
      WatermarkImage({
        imageUrl: this.banner.imageUrl,
        title: this.banner.title,
        watermarkText: '互成一家',
        imageHeight: 150,
        imageRadius: 16
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
      WatermarkImage({
        imageUrl: this.item.imageUrl,
        title: this.item.title,
        watermarkText: '互成一家 · 服务',
        imageHeight: 112,
        imageRadius: 12
      })
      ServiceCard({ title: this.item.title, summary: this.item.summary, iconText: this.item.iconText })
        .margin({ top: 8 })
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
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .layoutWeight(1)
        Text(this.post.publishTime)
          .fontSize(12)
          .fontColor('#98A2B3')
      }
      Text(this.post.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')
        .width('100%')
        .margin({ top: 10 })
      Text(this.post.content)
        .fontSize(13)
        .fontColor('#667085')
        .lineHeight(21)
        .width('100%')
        .margin({ top: 8 })
      if (this.post.imageUrl.length > 0) {
        WatermarkImage({
          imageUrl: this.post.imageUrl,
          title: this.post.title,
          watermarkText: '互成一家 · 社区',
          imageHeight: 120,
          imageRadius: 12
        })
          .margin({ top: 10 })
      }
      Text(`点赞 ${this.post.likeCount}`)
        .fontSize(12)
        .fontColor('#3563E9')
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
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
        .fontSize(13)
        .fontColor('#667085')
      Text(`¥${this.price.price}`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#3563E9')
        .margin({ top: 6 })
      Text(this.price.unit)
        .fontSize(11)
        .fontColor('#98A2B3')
        .margin({ top: 2 })
    }
    .height(94)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
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
        .fontColor('#182431')
      Text(`${this.user.school} · ${this.user.major} · ${this.user.grade}`)
        .fontSize(13)
        .fontColor('#667085')
        .lineHeight(20)
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
