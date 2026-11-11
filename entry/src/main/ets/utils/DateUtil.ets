export class DateUtil {
  static todayText(): string {
    const date = new Date();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${date.getFullYear()}-${month < 10 ? '0' + month : month}-${day < 10 ? '0' + day : day}`;
  }

  static nowId(prefix: string): string {
    return `${prefix}-${new Date().getTime()}`;
  }
}
