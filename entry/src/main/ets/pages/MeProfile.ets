import { common } from '@kit.AbilityKit';
import { AppIcon } from '../components/AppIcon';
import { RemoteImage } from '../components/RemoteImage';
import { UserProfile } from '../models/UserProfile';
import { AuthStore } from '../stores/AuthStore';
import { UserApi } from '../api/UserApi';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct MeProfile {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State user: UserProfile = new UserProfile();

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.user = await AuthStore.getUser(this.context);
  }

  private avatarText(): string {
    const name = this.user.nickname.length > 0 ? this.user.nickname : this.user.name;
    return name.length > 0 ? name.substring(0, 1) : '互';
  }

  private bioCount(): string {
    return `${this.user.bio.length}/100`;
  }

  setGender(value: string): void {
    this.user.gender = value;
  }

  setGrade(value: string): void {
    this.user.grade = value;
  }

  async save(): Promise<void> {
    if (this.user.nickname.length > 15) {
      ToastUtil.show('昵称不能超过15个字');
      return;
    }
    if (this.user.bio.length > 100) {
      ToastUtil.show('个人简介不能超过100个字');
      return;
    }
    this.user.name = this.user.nickname;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    await AuthStore.login(this.context, this.user, token, await AuthStore.getBackendMode(this.context), env);
    try {
      await UserApi.updateUserInfo(token, this.user, env);
      ToastUtil.show('保存成功');
    } catch (_) {
      ToastUtil.show('保存成功');
    }
  }

  @Builder
  AvatarSection() {
    Column() {
      Text('头像')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.user.avatarUrl.length > 0) {
          RemoteImage({
            imageUrl: this.user.avatarUrl,
            imageHeight: 86,
            imageRadius: 43,
            fitMode: 'cover'
          })
            .width(86)
        } else {
          Text(this.avatarText())
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .textAlign(TextAlign.Center)
            .width(86)
            .height(86)
            .borderRadius(43)
            .backgroundColor('#007AFF')
        }
        Text('更换')
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('#80000000')
          .borderRadius(12)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
      .margin({ top: 18 })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  FormInput(label: string, placeholder: string, value: string, field: string, icon: string) {
    Row() {
      AppIcon({ name: icon, iconSize: 22 })
        .margin({ right: 8 })
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .width(78)
      TextInput({ placeholder: placeholder, text: value })
        .layoutWeight(1)
        .height(44)
        .fontSize(15)
        .backgroundColor('#FFFFFF')
        .onChange((text: string) => {
          if (field === 'nickname') {
            this.user.nickname = text;
            this.user.name = text;
          } else if (field === 'school') {
            this.user.school = text;
          } else if (field === 'major') {
            this.user.major = text;
          } else if (field === 'studentId') {
            this.user.studentId = text;
          }
        })
      Text('›')
        .fontSize(20)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(54)
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  @Builder
  OptionButton(label: string, current: string, group: string) {
    Text(label)
      .fontSize(13)
      .fontColor(current === label ? '#FFFFFF' : '#555555')
      .backgroundColor(current === label ? '#007AFF' : '#F0F0F0')
      .borderRadius(15)
      .padding({ left: 14, right: 14, top: 7, bottom: 7 })
      .margin({ right: 8 })
      .onClick(() => {
        if (group === 'gender') {
          this.setGender(label);
        } else {
          this.setGrade(label);
        }
      })
  }

  @Builder
  SelectRow(label: string, current: string, group: string, icon: string) {
    Row() {
      AppIcon({ name: icon, iconSize: 22 })
        .margin({ right: 8 })
      Text(label)
        .fontSize(15)
        .fontColor('#333333')
        .width(78)
      Flex({ wrap: FlexWrap.Wrap }) {
        if (group === 'gender') {
          this.OptionButton('男', current, group)
          this.OptionButton('女', current, group)
        } else {
          this.OptionButton('大一', current, group)
          this.OptionButton('大二', current, group)
          this.OptionButton('大三', current, group)
          this.OptionButton('大四', current, group)
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  @Builder
  FormGroupBasic() {
    Column() {
      this.FormInput('昵称', '请输入昵称', this.user.nickname, 'nickname', 'profile_name')
      this.SelectRow('性别', this.user.gender, 'gender', 'profile_gender')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  FormGroupSchool() {
    Column() {
      this.FormInput('学校', '请输入学校名称', this.user.school, 'school', 'profile_school')
      this.FormInput('专业', '请输入专业名称', this.user.major, 'major', 'profile_major')
      this.SelectRow('年级', this.user.grade, 'grade', 'profile_grade')
      this.FormInput('学号', '请输入学号', this.user.studentId, 'studentId', 'profile_phone')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  BioGroup() {
    Column() {
      Row() {
        AppIcon({ name: 'profile_bio', iconSize: 22 })
          .margin({ right: 8 })
        Text('个人简介')
          .fontSize(15)
          .fontColor('#333333')
          .width(78)
        TextArea({ placeholder: '请输入个人简介', text: this.user.bio })
          .layoutWeight(1)
          .height(92)
          .fontSize(15)
          .backgroundColor('#FFFFFF')
          .onChange((value: string) => {
            this.user.bio = value;
          })
      }
      .width('100%')
      .padding({ top: 12, bottom: 8 })
      Text(this.bioCount())
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .textAlign(TextAlign.End)
        .margin({ bottom: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.AvatarSection()
          this.FormGroupBasic()
          this.FormGroupSchool()
          this.BioGroup()
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14, bottom: 96 })
      }
      .layoutWeight(1)

      Button('保存修改')
        .width('92%')
        .height(46)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(23)
        .margin({ bottom: 22 })
        .onClick(() => {
          this.save();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
