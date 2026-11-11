import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { LogUtil } from '../utils/LogUtil';

const CACHE_STORE = 'hcyj_cache_store';

export class CacheStore {
  private static async getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    return await preferences.getPreferences(context, CACHE_STORE);
  }

  static async setString(context: common.UIAbilityContext, key: string, value: string): Promise<void> {
    const store = await CacheStore.getStore(context);
    await store.put(key, value);
    await store.flush();
    LogUtil.info('cache', `set key=${key} length=${value.length}`);
  }

  static async getString(context: common.UIAbilityContext, key: string, defaultValue: string = ''): Promise<string> {
    const store = await CacheStore.getStore(context);
    const value = await store.get(key, defaultValue);
    const text = value as string;
    LogUtil.info('cache', `get key=${key} hit=${text.length > 0 ? 'true' : 'false'} length=${text.length}`);
    return text;
  }

  static async setJson<T>(context: common.UIAbilityContext, key: string, value: T): Promise<void> {
    await CacheStore.setString(context, key, JSON.stringify(value));
  }

  static async getJson<T>(context: common.UIAbilityContext, key: string, fallback: T): Promise<T> {
    const text = await CacheStore.getString(context, key, '');
    if (text.length === 0) {
      LogUtil.warn('cache', `json key=${key} empty use=fallback`);
      return fallback;
    }
    try {
      const parsed = JSON.parse(text) as T;
      LogUtil.info('cache', `json key=${key} parsed`);
      return parsed;
    } catch (_) {
      LogUtil.error('cache', `json key=${key} parse_failed use=fallback`);
      return fallback;
    }
  }

  static async clear(context: common.UIAbilityContext): Promise<void> {
    await preferences.deletePreferences(context, CACHE_STORE);
    LogUtil.warn('cache', 'clear cache store');
  }
}
