import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ApiConfig, ApiEnvironment } from '../api/ApiConfig';
import { UserProfile } from '../models/UserProfile';
import { LogUtil } from '../utils/LogUtil';
import { ENV } from '../api/env';

const AUTH_STORE = 'hcyj_auth_store';

export class AuthStore {
  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return await preferences.getPreferences(context, AUTH_STORE);
  }

  private static safeText(value: string | null): string {
    return value ? value : '';
  }

  /**
   * 首次启动时用本地 env.ets 的 DEMO_TOKEN 播种会话；
   * 已有 token（例如手动登录）则保持不变。
   */
  private static async ensureFixedSession(context: common.UIAbilityContext): Promise<void> {
    const store = await AuthStore.getStore(context);
    const token = await store.get('token', '') as string;
    if (token.length === 0 && ENV.DEMO_TOKEN.length > 0) {
      await store.put('token', ENV.DEMO_TOKEN);
    }
    const backendMode = await store.get('backendMode', '') as string;
    if (backendMode.length === 0) {
      await store.put('backendMode', 'backend');
    }
    const apiEnvironment = await store.get('apiEnvironment', '') as string;
    if (apiEnvironment.length === 0) {
      await store.put('apiEnvironment', ApiEnvironment.PRODUCTION);
    }
    await store.flush();
  }

  static async login(
    context: common.UIAbilityContext,
    user: UserProfile,
    token: string,
    backendMode: string = 'demo',
    apiEnvironment: string = ApiEnvironment.PRODUCTION
  ): Promise<void> {
    const store = await AuthStore.getStore(context);
    await store.put('token', token);
    await store.put('userInfo', JSON.stringify(user));
    await store.put('isLogin', true);
    await store.put('backendMode', backendMode);
    await store.put('apiEnvironment', apiEnvironment);
    await store.flush();
    LogUtil.info('auth', `login user=${user.studentId} mode=${backendMode} env=${apiEnvironment} token=${token.length > 0 ? 'present' : 'empty'}`);
  }

  static async getToken(context: common.UIAbilityContext): Promise<string> {
    await AuthStore.ensureFixedSession(context);
    const store = await AuthStore.getStore(context);
    const token = await store.get('token', '') as string;
    LogUtil.info('auth', `getToken token=${token.length > 0 ? 'present' : 'empty'}`);
    return token;
  }

  static async getUser(context: common.UIAbilityContext): Promise<UserProfile> {
    const store = await AuthStore.getStore(context);
    const text = await store.get('userInfo', '') as string;
    if (text.length === 0) {
      return new UserProfile();
    }
    try {
      const parsed = JSON.parse(text) as UserProfile;
      const nickname = AuthStore.safeText(parsed.nickname).length > 0 ? AuthStore.safeText(parsed.nickname) : AuthStore.safeText(parsed.name);
      const user = new UserProfile(
        nickname,
        parsed.studentId,
        parsed.role,
        parsed.gender,
        parsed.school,
        parsed.major,
        parsed.grade,
        parsed.avatar
      );
      user.id = AuthStore.safeText(parsed.id).length > 0 ? AuthStore.safeText(parsed.id) : user.studentId;
      user.name = nickname;
      user.avaterId = AuthStore.safeText(parsed.avaterId);
      user.avatarUrl = AuthStore.safeText(parsed.avatarUrl);
      user.bio = AuthStore.safeText(parsed.bio);
      user.level = parsed.level ? parsed.level : 0;
      return user;
    } catch (_) {
      return new UserProfile();
    }
  }

  static async isLogin(context: common.UIAbilityContext): Promise<boolean> {
    await AuthStore.ensureFixedSession(context);
    const store = await AuthStore.getStore(context);
    const token = await store.get('token', '') as string;
    LogUtil.info('auth', `isLogin=${token.length > 0}`);
    return token.length > 0;
  }

  static async getBackendMode(context: common.UIAbilityContext): Promise<string> {
    await AuthStore.ensureFixedSession(context);
    const store = await AuthStore.getStore(context);
    return await store.get('backendMode', 'backend') as string;
  }

  static async getApiEnvironment(context: common.UIAbilityContext): Promise<string> {
    await AuthStore.ensureFixedSession(context);
    const store = await AuthStore.getStore(context);
    return await store.get('apiEnvironment', ApiEnvironment.PRODUCTION) as string;
  }

  static async getModeSummary(context: common.UIAbilityContext): Promise<string> {
    const backendMode = await AuthStore.getBackendMode(context);
    const apiEnvironment = await AuthStore.getApiEnvironment(context);
    return backendMode === 'backend' ? `在线服务 · ${ApiConfig.environmentLabel(apiEnvironment)}` : '本地缓存';
  }

  static async clear(context: common.UIAbilityContext): Promise<void> {
    await preferences.deletePreferences(context, AUTH_STORE);
    await AuthStore.ensureFixedSession(context);
    LogUtil.warn('auth', 'clear auth store');
  }

  static async saveUser(context: common.UIAbilityContext, user: UserProfile): Promise<void> {
    await AuthStore.ensureFixedSession(context);
    const store = await AuthStore.getStore(context);
    await store.put('userInfo', JSON.stringify(user));
    await store.flush();
    LogUtil.info('auth', `saveUser user=${user.nickname}`);
  }
}
