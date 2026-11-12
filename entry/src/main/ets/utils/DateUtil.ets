export class DateUtil {
  static todayText(): string {
    const date = new Date();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${date.getFullYear()}-${month < 10 ? '0' + month : month}-${day < 10 ? '0' + day : day}`;
  }

  /** 与小程序 `toLocaleString('zh-CN')` 一致的数字格式，避免英文 AM/PM。 */
  static nowText(): string {
    const date = new Date();
    const pad = (value: number): string => value < 10 ? `0${value}` : `${value}`;
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ` +
      `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
  }

  static nowId(prefix: string): string {
    return `${prefix}-${new Date().getTime()}`;
  }
}
