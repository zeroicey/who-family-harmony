import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct ServicePersonInfo {
  private readonly categories: string[] = ['教学楼', '饭堂', '校道'];
  private readonly buildings: string[] = ['A栋', 'B栋', 'C栋', 'D栋', 'E栋', 'F栋', 'G栋', 'H栋'];
  private readonly canteens: string[] = ['学四饭堂', '学五饭堂', '学二饭堂', '学二饭堂楼下'];
  private readonly roads: string[] = ['星光大道', '行政楼路口', '钟楼到java宿舍', 'EF栋一楼路', '图书馆到学五路', '操场c栋'];
  private readonly personSlots: number[] = [0, 1, 2, 3, 4];
  @State currentCategory: string = '教学楼';
  @State currentLocation: string = 'A栋';
  @State updateTime: string = '';

  aboutToAppear(): void {
    this.refreshTime();
  }

  private refreshTime(): void {
    const now = new Date();
    const month = `${now.getMonth() + 1}`.padStart(2, '0');
    const day = `${now.getDate()}`.padStart(2, '0');
    const hours = `${now.getHours()}`.padStart(2, '0');
    const minutes = `${now.getMinutes()}`.padStart(2, '0');
    this.updateTime = `${now.getFullYear()}-${month}-${day} ${hours}:${minutes}`;
  }

  private currentLocations(): string[] {
    if (this.currentCategory === '饭堂') {
      return this.canteens;
    }
    if (this.currentCategory === '校道') {
      return this.roads;
    }
    return this.buildings;
  }

  private selectCategory(category: string): void {
    if (this.currentCategory === category) {
      return;
    }
    this.currentCategory = category;
    this.currentLocation = this.currentLocations()[0];
    this.refreshTime();
  }

  private selectLocation(location: string): void {
    this.currentLocation = location;
    this.refreshTime();
  }

  private basePercent(): number {
    if (this.currentCategory === '饭堂') {
      if (this.currentLocation === '学五饭堂') {
        return 78;
      }
      if (this.currentLocation === '学二饭堂楼下') {
        return 92;
      }
      if (this.currentLocation === '学二饭堂') {
        return 18;
      }
      return 42;
    }
    if (this.currentCategory === '校道') {
      if (this.currentLocation === '行政楼路口') {
        return 65;
      }
      if (this.currentLocation === '图书馆到学五路') {
        return 75;
      }
      if (this.currentLocation === '钟楼到java宿舍') {
        return 22;
      }
      return 48;
    }
    return 0;
  }

  private realtimePercent(): number {
    if (this.currentCategory !== '教学楼') {
      return this.basePercent();
    }
    const index = this.buildings.indexOf(this.currentLocation);
    if (index < 0) {
      return 20;
    }
    return 18 + index * 8 > 86 ? 86 : 18 + index * 8;
  }

  private predictPercent(): number {
    if (this.currentCategory !== '教学楼') {
      return this.basePercent();
    }
    const index = this.buildings.indexOf(this.currentLocation);
    if (index < 0) {
      return 24;
    }
    return 24 + index * 7 > 88 ? 88 : 24 + index * 7;
  }

  private statusKey(percent: number): string {
    if (percent < 25) {
      return 'comfortable';
    }
    if (percent < 50) {
      return 'moderate';
    }
    if (percent < 75) {
      return 'crowded';
    }
    return 'saturated';
  }

  private statusLabel(percent: number): string {
    const key = this.statusKey(percent);
    if (key === 'comfortable') {
      return '舒适';
    }
    if (key === 'moderate') {
      return '适中';
    }
    if (key === 'crowded') {
      return '拥挤';
    }
    return '饱和';
  }

  private statusColor(percent: number): string {
    const key = this.statusKey(percent);
    if (key === 'comfortable') {
      return '#4CAF50';
    }
    if (key === 'moderate') {
      return '#2196F3';
    }
    if (key === 'crowded') {
      return '#FF9800';
    }
    return '#F44336';
  }

  private adviceText(): string {
    const percent = this.currentCategory === '教学楼' ? this.realtimePercent() : this.basePercent();
    const key = this.statusKey(percent);
    if (this.currentCategory === '饭堂') {
      if (key === 'comfortable') {
        return '空位充足，点餐无需等待';
      }
      if (key === 'moderate') {
        return '人流正常，点餐基本无需等待';
      }
      if (key === 'crowded') {
        return '正值就餐高峰，预计需要排队寻找座位';
      }
      return '人流已达上限，建议错峰就餐或选择打包';
    }
    if (this.currentCategory === '校道') {
      if (key === 'comfortable') {
        return '道路通畅，可正常通行';
      }
      if (key === 'moderate') {
        return '人流适中，通行无阻';
      }
      if (key === 'crowded') {
        return '人流密集，请慢行注意安全';
      }
      return '道路拥挤，建议绕行或稍后通过';
    }
    if (key === 'comfortable') {
      return '当前人流稀少，楼道通畅，可放心通行';
    }
    if (key === 'moderate') {
      return '人流适中，楼道较为通畅，通行基本无阻';
    }
    if (key === 'crowded') {
      return '人流较多，下课时楼道可能拥挤，建议稍作停留或走楼梯';
    }
    return '人流密集，建议错峰通行或绕行其他楼栋，注意安全';
  }

  @Builder
  HeaderCard() {
    Column() {
      Row() {
        Column() {
          Text('校园实时监测')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('Campus Real-time Monitoring')
            .fontSize(12)
            .fontColor(0xDDFFFFFF)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Row() {
          Text('')
            .width(7)
            .height(7)
            .borderRadius(4)
            .backgroundColor('#34C759')
          Text('实时')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .margin({ left: 6 })
        }
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(0x22FFFFFF)
        .borderRadius(14)
      }
      .width('100%')
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#4CAF50')
    .borderRadius(24)
  }

  @Builder
  SegmentControl() {
    Row() {
      ForEach(this.categories, (category: string) => {
        Text(category)
          .fontSize(14)
          .fontWeight(this.currentCategory === category ? FontWeight.Bold : FontWeight.Regular)
          .fontColor(this.currentCategory === category ? '#FFFFFF' : '#666666')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(42)
          .borderRadius(14)
          .backgroundColor(this.currentCategory === category ? '#4CAF50' : '#FFFFFF')
          .onClick(() => {
            this.selectCategory(category);
          })
      }, (category: string) => category)
    }
    .width('100%')
    .padding(5)
    .backgroundColor('#F1F4F2')
    .borderRadius(18)
    .margin({ top: 16 })
  }

  @Builder
  LocationSwitcher() {
    Scroll() {
      Row() {
        ForEach(this.currentLocations(), (location: string) => {
          Text(location)
            .fontSize(13)
            .fontColor(this.currentLocation === location ? '#FFFFFF' : '#4CAF50')
            .fontWeight(this.currentLocation === location ? FontWeight.Bold : FontWeight.Regular)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(this.currentLocation === location ? '#4CAF50' : '#FFFFFF')
            .borderRadius(18)
            .margin({ right: 8 })
            .onClick(() => {
              this.selectLocation(location);
            })
        }, (location: string) => location)
      }
      .padding({ left: 1, right: 1 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .margin({ top: 14 })
  }

  @Builder
  PeopleDots(percent: number, color: string) {
    Row() {
      ForEach(this.personSlots, (index: number) => {
        Text('')
          .width(18)
          .height(28)
          .borderRadius(9)
          .backgroundColor(percent >= (index + 1) * 20 ? color : '#E8E8E8')
          .margin({ right: 8 })
      }, (index: number) => `${index}`)
    }
    .margin({ top: 12 })
  }

  @Builder
  DataBlock(icon: string, title: string, source: string, percent: number, desc: string) {
    Column() {
      Row() {
        Text(icon)
          .fontSize(22)
          .textAlign(TextAlign.Center)
          .width(44)
          .height(44)
          .borderRadius(14)
          .backgroundColor('#F4F8F5')
        Column() {
          Text(title)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(source)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      this.PeopleDots(percent, this.statusColor(percent))
      Row() {
        Text(this.statusLabel(percent))
          .fontSize(12)
          .fontColor(this.statusColor(percent))
          .fontWeight(FontWeight.Bold)
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#F7FBF8')
          .borderRadius(14)
        Text(`${percent}%`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.statusColor(percent))
          .margin({ left: 10 })
      }
      .margin({ top: 10 })
      Text(desc)
        .fontSize(12)
        .fontColor('#666666')
        .lineHeight(18)
        .margin({ top: 8 })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  CrowdCard() {
    Column() {
      Row() {
        Text('')
          .width(4)
          .height(36)
          .borderRadius(2)
          .backgroundColor('#4CAF50')
        Column() {
          Text('人流监测')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('CROWD MONITORING')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        .layoutWeight(1)
        Text(this.currentLocation)
          .fontSize(12)
          .fontColor('#4CAF50')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor('#EAF7EC')
          .borderRadius(14)
      }
      .width('100%')

      if (this.currentCategory === '教学楼') {
        Row() {
          this.DataBlock('🚁', '实时人流', '无人机监测', this.realtimePercent(), this.statusLabel(this.realtimePercent()) === '舒适' ? '上课中，楼道人流稀少' : '下课高峰，楼道人流变化明显')
          Text('')
            .width(1)
            .height(126)
            .backgroundColor('#EEF1F2')
            .margin({ left: 14, right: 14 })
          this.DataBlock('📅', '预测下课人流', '课表系统分析', this.predictPercent(), this.statusLabel(this.predictPercent()) === '饱和' ? '预计下课后人流较大' : '预计下课后人流可控')
        }
        .width('100%')
        .margin({ top: 20 })
      } else {
        this.PeopleDots(this.basePercent(), this.statusColor(this.basePercent()))
        Row() {
          Text(this.statusLabel(this.basePercent()))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.statusColor(this.basePercent()))
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor('#F7FBF8')
            .borderRadius(14)
          Text(`${this.basePercent()}%`)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.statusColor(this.basePercent()))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ top: 16 })
        Row() {
          Text('')
            .height(8)
            .width(`${this.basePercent()}%`)
            .borderRadius(4)
            .backgroundColor(this.statusColor(this.basePercent()))
        }
        .width('100%')
        .height(8)
        .backgroundColor('#E8E8E8')
        .borderRadius(4)
        .margin({ top: 10 })
      }

      Row() {
        Text('✓')
          .fontSize(16)
          .fontColor(this.statusColor(this.currentCategory === '教学楼' ? this.realtimePercent() : this.basePercent()))
        Text(this.adviceText())
          .fontSize(13)
          .fontColor('#555555')
          .lineHeight(19)
          .layoutWeight(1)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#F8FBF8')
      .borderRadius(14)
      .margin({ top: 18 })

      Text(`数据更新于：${this.updateTime} (无人机与课表系统联合分析)`)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .margin({ top: 16 })
  }

  @Builder
  WeatherCard() {
    Column() {
      Row() {
        Text('')
          .width(4)
          .height(34)
          .borderRadius(2)
          .backgroundColor('#34C759')
        Column() {
          Text('环境感知')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('ENVIRONMENT')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
      }
      .width('100%')
      Row() {
        Column() {
          Text('🌤️')
            .fontSize(38)
          Row() {
            Text('26')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            Text('°C')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ left: 2, top: 12 })
          }
          Text('多云')
            .fontSize(13)
            .fontColor('#666666')
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
        Column() {
          this.WeatherMetric('PM2.5', '35 μg/m³')
          this.WeatherMetric('空气质量', '良')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 16 })
      Text(`数据更新于：${this.updateTime} (无人机与课表系统联合分析)`)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 12 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(22)
    .margin({ top: 16, bottom: 24 })
  }

  @Builder
  WeatherMetric(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
    }
    .width('100%')
    .margin({ bottom: 14 })
  }

  build() {
    Column() {
      PageHeader({ title: '校园人流数据' })
      Scroll() {
        Column() {
          this.HeaderCard()
          this.SegmentControl()
          this.LocationSwitcher()
          this.CrowdCard()
          this.WeatherCard()
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F8F6')
  }
}
