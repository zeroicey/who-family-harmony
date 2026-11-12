import { ApiConfig, ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
import { CheckApi } from './CheckApi';
import { HttpClient } from './HttpClient';
import { AddressItem } from '../models/MiniProgramModels';
import { UserProfile } from '../models/UserProfile';

class UserInfoResponse {
  id: string | number = '';
  name: string = '';
  username: string = '';
  avaterId: string | number = '';
  gender: string = '';
  phone: string | null = '';
  email: string | null = '';
  bio: string | null = '';
  school: string | null = '';
  major: string | null = '';
  grade: string | null = '';
  balance: number | string = 0;
  points: number | string = 0;
  level: number | string = 0;
}

class AvatarResponse {
  success: boolean = false;
  data: string = '';
}

class AvatarUploadPayload {
  avatar: string = '';

  constructor(avatar: string) {
    this.avatar = avatar;
  }
}

class AvatarUploadResponse {
  avatarId: string | number = '';
}

class StoragePayload {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string = '') {
    this.key = key;
    this.value = value;
  }
}

class StorageValueResponse {
  value: string = '';
}

export class UserApi {
  private static safeText(value: string | number | boolean | null): string {
    return value ? `${value}` : '';
  }

  private static safeNumber(value: number | string | null): number {
    if (!value) {
      return 0;
    }
    const parsed = Number(value);
    if (parsed >= 0 || parsed < 0) {
      return parsed;
    }
    return 0;
  }

  private static normalizeUser(row: UserInfoResponse): UserProfile {
    const name = UserApi.safeText(row.name).length > 0 ? UserApi.safeText(row.name) : UserApi.safeText(row.username);
    const user = new UserProfile(
      name.length > 0 ? name : '用户',
      UserApi.safeText(row.id),
      '学生',
      UserApi.safeText(row.gender),
      UserApi.safeText(row.school),
      UserApi.safeText(row.major),
      UserApi.safeText(row.grade),
      UserApi.safeText(row.avaterId)
    );
    user.id = UserApi.safeText(row.id);
    user.name = name.length > 0 ? name : '用户';
    user.nickname = user.name;
    user.studentId = user.id.length > 0 ? user.id : ApiConfig.DEMO_USER_ID;
    user.avaterId = UserApi.safeText(row.avaterId);
    user.avatar = user.avaterId;
    user.bio = UserApi.safeText(row.bio);
    user.level = UserApi.safeNumber(row.level);
    return user;
  }

  static async getUserInfo(token: string, id: string = ApiConfig.DEMO_USER_ID, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<UserProfile> {
    const result = await HttpClient.get<UserInfoResponse[]>(`/user/userInfo?id=${id}`, token, apiEnvironment);
    const users = result.data === null ? [] : result.data;
    if (users.length === 0) {
      return new UserProfile();
    }
    return UserApi.normalizeUser(users[0]);
  }

  static async getAvatarUrl(token: string, avatarId: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<string> {
    if (avatarId.length === 0) {
      return '';
    }
    const result = await HttpClient.get<AvatarResponse>(`/user/avater?id=${avatarId}`, token, apiEnvironment);
    if (result.data === null || !result.data.success) {
      return '';
    }
    return result.data.data;
  }

  /** 保存资料前先检查文本，与小程序 api/user.js updateUserInfo 一致。 */
  static async updateUserInfo(token: string, user: UserProfile,
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    const check = await CheckApi.checkText(token, user, apiEnvironment);
    if (!check.passed) {
      throw new Error(check.message);
    }
    await HttpClient.put<ApiEmptyResponse>('/user/userInfo', token, user, apiEnvironment);
  }

  /** 上传头像：先做图片检查，再 PUT /user/avatar，返回 avatarId。 */
  static async updateAvatar(token: string, imageBase64: string, mimeType: string = 'image/png',
    apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<string> {
    const check = await CheckApi.checkImg(token, imageBase64, mimeType, apiEnvironment);
    if (!check.passed) {
      throw new Error(check.message);
    }
    const avatar = `data:${mimeType};base64,${imageBase64}`;
    const result = await HttpClient.put<AvatarUploadResponse>('/user/avatar', token,
      new AvatarUploadPayload(avatar), apiEnvironment);
    if (result.data === null) {
      throw new Error('后端未返回头像 id');
    }
    return UserApi.safeText(result.data.avatarId);
  }

  static async selfPosts<T>(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<T[]> {
    const result = await HttpClient.get<T[]>('/community/self-post', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  static async saveAddresses(token: string, addresses: AddressItem[], apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/storage/setItem', token, new StoragePayload('addresses', JSON.stringify(addresses)), apiEnvironment);
  }

  static async loadAddresses(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<AddressItem[]> {
    // 后端返回 { value: "[...]" }，与小程序 remoteStorage 的 getRemoteStorageSync 一致。
    const result = await HttpClient.post<StorageValueResponse>('/storage/getItem', token,
      new StoragePayload('addresses'), apiEnvironment);
    if (result.data === null || result.data.value.length === 0) {
      return [];
    }
    return JSON.parse(result.data.value) as AddressItem[];
  }
}
