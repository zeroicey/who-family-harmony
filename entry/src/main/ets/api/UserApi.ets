import { ApiConfig, ApiEmptyResponse, ApiEnvironment } from './ApiConfig';
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

class StoragePayload {
  key: string = '';
  value: string = '';

  constructor(key: string, value: string = '') {
    this.key = key;
    this.value = value;
  }
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

  static async updateUserInfo(token: string, user: UserProfile, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.put<ApiEmptyResponse>('/user/userInfo', token, user, apiEnvironment);
  }

  static async selfPosts<T>(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<T[]> {
    const result = await HttpClient.get<T[]>('/community/self-post', token, apiEnvironment);
    return result.data === null ? [] : result.data;
  }

  static async saveAddresses(token: string, addresses: AddressItem[], apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<void> {
    await HttpClient.post<ApiEmptyResponse>('/storage/setItem', token, new StoragePayload('addresses', JSON.stringify(addresses)), apiEnvironment);
  }

  static async loadAddresses(token: string, apiEnvironment: string = ApiEnvironment.PRODUCTION): Promise<AddressItem[]> {
    const result = await HttpClient.post<string>('/storage/getItem', token, new StoragePayload('addresses'), apiEnvironment);
    if (result.data === null || result.data.length === 0) {
      return [];
    }
    return JSON.parse(result.data) as AddressItem[];
  }
}
