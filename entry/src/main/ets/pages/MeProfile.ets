import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { AppIcon } from '../components/AppIcon';
import { LoadingView } from '../components/common/LoadingView';
import { NetImage } from '../components/common/NetImage';
import { PrimaryButton } from '../components/common/PrimaryButton';
import { UserProfile } from '../models/UserProfile';
import { AuthStore } from '../stores/AuthStore';
import { UserApi } from '../api/UserApi';
import { PickedFile, UploadService } from '../services/UploadService';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct MeProfile {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State user: UserProfile = new UserProfile();
  @State saving: boolean = false;
  @State uploadingAvatar: boolean = false;
  @State loaded: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.user = await AuthStore.getUser(this.context);
    // 小程序：年级不在 大一–大四 时回落到「大一」。
    const grades: string[] = ['大一', '大二', '大三', '大四'];
    if (!grades.includes(this.user.grade)) {
      this.user.grade = '大一';
    }
    this.loaded = true;
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

  /** 选择头像 → 图片检查 → PUT /user/avatar → 刷新全局头像。 */
  async pickAvatar(): Promise<void> {
    if (this.uploadingAvatar) {
      return;
    }
    try {
      const picked = await UploadService.pickImages(1);
      if (picked.length === 0) {
        return;
      }
      const file: PickedFile = picked[0];
      const reason = UploadService.checkImage(file);
      if (reason.length > 0) {
        ToastUtil.show(reason);
        return;
      }
      this.uploadingAvatar = true;
      const token = await AuthStore.getToken(this.context);
      const env = await AuthStore.getApiEnvironment(this.context);
      const avatarId = await UserApi.updateAvatar(token, file.base64(), file.mimeType, env);
      const remoteUrl = await UserApi.getAvatarUrl(token, avatarId, env);
      this.user.avaterId = avatarId;
      this.user.avatarUrl = remoteUrl.length > 0 ? remoteUrl : file.uri;
      await AuthStore.saveUser(this.context, this.user);
      // 全局头像：Mine 通过 @StorageLink 即时刷新，无需重新进页面。
      AppStorage.setOrCreate<string>('avatarUrl', this.user.avatarUrl);
      AppStorage.setOrCreate<string>('userRefreshAt', `${Date.now()}`);
      ToastUtil.show('头像更新成功');
    } catch (err) {
      LogUtil.warn('profile', `avatar upload failed ${(err as Error).message}`);
      ToastUtil.show(`头像上传失败：${(err as Error).message}`);
    } finally {
      this.uploadingAvatar = false;
    }
  }

  async save(): Promise<void> {
    if (this.saving) {
      return;
    }
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
    this.saving = true;
    try {
      // UserApi.updateUserInfo 内部先做 /check/text，未通过或 401 会抛出。
      await UserApi.updateUserInfo(token, this.user, env);
      await AuthStore.login(this.context, this.user, token, await AuthStore.getBackendMode(this.context), env);
      AppStorage.setOrCreate<string>('userRefreshAt', `${Date.now()}`);
      ToastUtil.show('保存成功');
      // 小程序保存后切回「我的」页；鸿蒙侧等价于返回上一页。
      router.back();
    } catch (err) {
      LogUtil.warn('profile', `save failed ${(err as Error).message}`);
      ToastUtil.show('保存失败，请稍后再试');
    } finally {
      this.saving = false;
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
          NetImage({
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
        Text(this.uploadingAvatar ? '上传中' : '更换')
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor('#80000000')
          .borderRadius(12)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
      }
      .margin({ top: 18 })
      .onClick(() => {
        this.pickAvatar();
      })
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  FormInput(label: string, placeholder: string, value: string, field: string, icon: string, limit: number = 200) {
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
        .maxLength(limit)
        .textAlign(TextAlign.End)
        .backgroundColor('#FFFFFF')
        .onChange((text: string) => {
          if (field === 'nickname') {
            this.user.nickname = text;
            this.user.name = text;
          } else if (field === 'school') {
            this.user.school = text;
          } else if (field === 'major') {
            this.user.major = text;
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

  private optionIndex(current: string, group: string): number {
    const options: string[] = group === 'gender' ? ['男', '女'] : ['大一', '大二', '大三', '大四'];
    const index = options.indexOf(current);
    return index < 0 ? 0 : index;
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
      Blank()
      Select(group === 'gender' ? [{ value: '男' }, { value: '女' }] :
        [{ value: '大一' }, { value: '大二' }, { value: '大三' }, { value: '大四' }])
        .selected(this.optionIndex(current, group))
        .value(current)
        .font({ size: 15 })
        .fontColor('#555555')
        .optionFont({ size: 15 })
        .selectedOptionFont({ size: 15 })
        .backgroundColor('#00000000')
        .onSelect((index: number, value: string) => {
          if (group === 'gender') {
            this.setGender(value);
          } else {
            this.setGrade(value);
          }
        })
        .margin({ right: -6 })
    }
    .width('100%')
    .height(54)
    .border({ width: { bottom: 1 }, color: '#F0F0F0' })
  }

  @Builder
  FormGroupBasic() {
    Column() {
      this.FormInput('昵称', '请输入昵称', this.user.nickname, 'nickname', 'profile_name', 15)
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
          .maxLength(100)
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
      PageHeader({ title: '个人资料' })
      Scroll() {
        Column() {
          if (!this.loaded) {
            LoadingView({ text: '正在加载', minHeight: 240 })
          } else {
            this.AvatarSection()
            this.FormGroupBasic()
            this.FormGroupSchool()
            this.BioGroup()
          }
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: 14, bottom: 96 })
      }
      .layoutWeight(1)

      if (this.loaded) {
        PrimaryButton({
          text: '保存修改',
          loading: this.saving,
          buttonWidth: '92%',
          buttonHeight: 46,
          buttonRadius: 23,
          onTap: () => {
            this.save();
          }
        })
          .margin({ bottom: 22 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
