import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'hcyj';

export class LogUtil {
  static info(scope: string, message: string): void {
    hilog.info(DOMAIN, TAG, '%{public}s', `[${scope}] ${message}`);
  }

  static warn(scope: string, message: string): void {
    hilog.warn(DOMAIN, TAG, '%{public}s', `[${scope}] ${message}`);
  }

  static error(scope: string, message: string): void {
    hilog.error(DOMAIN, TAG, '%{public}s', `[${scope}] ${message}`);
  }
}
