import { router } from '@kit.ArkUI';
import { CoverImage } from '../components/common/CoverImage';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct ServiceExpress {
  @State name: string = '互成一家用户';
  @State phone: string = '';
  @State address: string = '广东东软学院 SOVO 公寓';
  @State code: string = '';

  submit(): void {
    if (this.phone.trim().length === 0 || this.code.trim().length === 0) {
      ToastUtil.show('请填写手机号和取件码');
      return;
    }
    router.pushUrl({ url: 'pages/ServiceSuccess', params: { type: 'express' } });
  }

  @Builder
  FormInput(label: string, placeholder: string, value: string) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .fontColor('#333333')
      .margin({ top: 14, bottom: 8 })
    TextInput({ placeholder: placeholder, text: value })
      .height(48)
      .backgroundColor('#F8F9FA')
      .borderRadius(14)
      .padding({ left: 14, right: 14 })
      .onChange((next: string) => {
        if (label === '收件人') {
          this.name = next;
        } else if (label === '联系电话') {
          this.phone = next;
        } else if (label === '宿舍/配送地址') {
          this.address = next;
        } else {
          this.code = next;
        }
      })
  }

  @Builder
  InfoCard() {
    Column() {
      Text('服务说明')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
      Text('请确认取件码、收件人和配送地点准确，提交后等待校内服务人员联系。')
        .fontSize(13)
        .fontColor('#666666')
        .lineHeight(20)
        .margin({ top: 8 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14, bottom: 24 })
  }

  build() {
    Column() {
      PageHeader({ title: '快递代取' })
      Scroll() {
        Column() {
          CoverImage({
            imageUrl: 'https://api.hcyj.xyz/images/dngg.jpg',
            title: '',
            watermarkText: '互成一家 | 快递代取',
            imageHeight: 210,
            imageRadius: 0
          })

          Column() {
            Text('快递代取服务')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text('校内快递专人代取，省时省力')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 8 })
            Row() {
              Text('¥3起')
                .fontSize(12)
                .fontColor('#FF4D4F')
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor('#FFF1F0')
                .borderRadius(14)
              Text('安全送达')
                .fontSize(12)
                .fontColor('#007AFF')
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor('#E8F4FF')
                .borderRadius(14)
                .margin({ left: 8 })
            }
            .margin({ top: 14 })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(20)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .margin({ top: -26 })

          Column() {
            this.FormInput('收件人', '请输入收件人', this.name)
            this.FormInput('联系电话', '请输入联系电话', this.phone)
            this.FormInput('宿舍/配送地址', '请输入宿舍或配送地址', this.address)
            this.FormInput('取件码', '请输入取件码', this.code)

            Button('提交代取需求')
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor('#07C160')
              .borderRadius(25)
              .margin({ top: 18 })
              .onClick(() => {
                this.submit();
              })
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(18)
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
          .margin({ top: 14 })

          this.InfoCard()
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
