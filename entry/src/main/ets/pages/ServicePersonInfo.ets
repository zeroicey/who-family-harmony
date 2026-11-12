import { AcademicData } from '../data/AcademicData';
import { PageHeader } from '../components/common/PageHeader';

class TimePhase {
  phase: string;
  period: string;

  constructor(phase: string = 'free', period: string = '') {
    this.phase = phase;
    this.period = period;
  }
}

@Entry
@Component
struct ServicePersonInfo {
  private readonly categories: string[] = ['教学楼', '饭堂', '校道'];
  private readonly buildings: string[] = ['A栋', 'B栋', 'C栋', 'D栋', 'E栋', 'F栋', 'G栋', 'H栋'];
  private readonly canteens: string[] = ['学四饭堂', '学五饭堂', '学二饭堂', '学二饭堂楼下'];
  private readonly roads: string[] = ['星光大道', '行政楼路口', '钟楼到java宿舍', 'EF栋一楼路', '图书馆到学五路',
    '操场c栋', '图书馆到东南二门路线'];
  private readonly personSlots: number[] = [0, 1, 2, 3, 4];
  private readonly periodNames: string[] = ['第1-2节', '第3-4节', '第5-6节', '第7-8节', '第9-10节', '第11-12节'];
  private readonly periodStart: number[] = [8.5, 10.417, 14, 15.917, 18.5, 20.417];
  private readonly periodEnd: number[] = [10.083, 12, 15.583, 17.5, 20.083, 22];
  private readonly passingStart: number[] = [10.083, 12, 15.583, 17.5, 20.083, 22];
  private readonly passingEnd: number[] = [10.583, 12.5, 16.083, 18, 20.583, 22.5];
  private readonly weekDays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  private timerId: number = -1;
  private currentDate: Date = new Date();

  @State currentCategory: string = '教学楼';
  @State currentLocation: string = 'A栋';
  @State updateTime: string = '';

  aboutToAppear(): void {
    this.refreshTime();
    this.timerId = setInterval(() => {
      this.refreshTime();
    }, 60000);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private twoDigits(value: number): string {
    return `${value}`.padStart(2, '0');
  }

  private refreshTime(): void {
    const now = new Date();
    this.currentDate = now;
    this.updateTime = `${now.getFullYear()}-${this.twoDigits(now.getMonth() + 1)}-` +
      `${this.twoDigits(now.getDate())} ${this.twoDigits(now.getHours())}:` +
      `${this.twoDigits(now.getMinutes())}:${this.twoDigits(now.getSeconds())}`;
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

  private mockPercentage(): number {
    if (this.currentLocation === '学四饭堂') {
      return 42;
    }
    if (this.currentLocation === '学五饭堂') {
      return 78;
    }
    if (this.currentLocation === '学二饭堂') {
      return 18;
    }
    if (this.currentLocation === '学二饭堂楼下') {
      return 92;
    }
    if (this.currentLocation === '星光大道') {
      return 35;
    }
    if (this.currentLocation === '行政楼路口') {
      return 65;
    }
    if (this.currentLocation === '钟楼到java宿舍') {
      return 22;
    }
    if (this.currentLocation === 'EF栋一楼路') {
      return 48;
    }
    if (this.currentLocation === '图书馆到学五路') {
      return 75;
    }
    if (this.currentLocation === '操场c栋') {
      return 30;
    }
    if (this.currentLocation === '图书馆到东南二门路线') {
      return 55;
    }
    return 0;
  }

  private currentDay(): string {
    return this.weekDays[this.currentDate.getDay()];
  }

  private currentTimeValue(): number {
    return this.currentDate.getHours() + this.currentDate.getMinutes() / 60;
  }

  private timePhase(): TimePhase {
    const value = this.currentTimeValue();
    for (let index = 0; index < this.periodNames.length; index++) {
      if (value >= this.periodStart[index] && value < this.periodEnd[index]) {
        return new TimePhase('inClass', this.periodNames[index]);
      }
    }
    for (let index = 0; index < this.periodNames.length; index++) {
      if (value >= this.passingStart[index] && value <= this.passingEnd[index]) {
        return new TimePhase('passing', this.periodNames[index]);
      }
    }
    return new TimePhase('free', '');
  }

  private dataBuilding(): string {
    return `${this.currentLocation.replace('栋', '')} 栋`;
  }

  private studentCount(day: string, period: string): number {
    return AcademicData.studentCount(day, period, this.dataBuilding());
  }

  private realtimePercent(): number {
    if (this.currentCategory !== '教学楼') {
      return 0;
    }
    const day = this.currentDay();
    if (day === '周日' || day === '周六') {
      return 10;
    }
    const phase = this.timePhase();
    if (phase.phase === 'inClass') {
      return 8;
    }
    if (phase.phase === 'passing') {
      const passingStudents = Math.floor(this.studentCount(day, phase.period) * 0.4);
      if (passingStudents > 400) {
        return 75;
      }
      return passingStudents > 200 ? 50 : 20;
    }
    return 15;
  }

  private realtimeStatus(): string {
    if (this.currentCategory !== '教学楼') {
      return 'low';
    }
    const day = this.currentDay();
    if (day === '周日' || day === '周六') {
      return 'low';
    }
    const phase = this.timePhase();
    if (phase.phase === 'inClass') {
      return 'low';
    }
    if (phase.phase === 'passing') {
      const passingStudents = Math.floor(this.studentCount(day, phase.period) * 0.4);
      if (passingStudents > 400) {
        return 'high';
      }
      return passingStudents > 200 ? 'medium' : 'low';
    }
    return 'low';
  }

  private realtimeText(): string {
    if (this.currentCategory !== '教学楼') {
      return '暂无数据';
    }
    const day = this.currentDay();
    if (day === '周日' || day === '周六') {
      return '周末人流稀少';
    }
    const phase = this.timePhase();
    if (phase.phase === 'inClass') {
      return '上课中，楼道人流稀少';
    }
    if (phase.phase === 'passing') {
      const status = this.realtimeStatus();
      if (status === 'high') {
        return '下课高峰，楼道人流密集';
      }
      if (status === 'medium') {
        return '下课高峰，楼道人流适中';
      }
      return '下课时间，楼道人流较少';
    }
    return '非上课时间，人流稀少';
  }

  private predictPercent(): number {
    if (this.currentCategory !== '教学楼') {
      return 0;
    }
    const day = this.currentDay();
    if (day === '周日' || day === '周六') {
      return 0;
    }
    const phase = this.timePhase();
    if (phase.phase === 'inClass') {
      const students = this.studentCount(day, phase.period);
      if (students > 1000) {
        return 85;
      }
      if (students > 500) {
        return 65;
      }
      return students > 200 ? 45 : 20;
    }
    if (phase.phase === 'passing') {
      const students = this.studentCount(day, phase.period);
      if (students > 1000) {
        return 80;
      }
      if (students > 500) {
        return 60;
      }
      return students > 200 ? 40 : 25;
    }
    const value = this.currentTimeValue();
    for (let index = 0; index < this.periodNames.length; index++) {
      if (value < this.periodStart[index]) {
        const students = this.studentCount(day, this.periodNames[index]);
        if (students > 0) {
          if (students > 1000) {
            return 70;
          }
          if (students > 500) {
            return 50;
          }
          return students > 200 ? 35 : 15;
        }
        break;
      }
    }
    return 0;
  }

  private predictStatus(): string {
    if (this.currentCategory !== '教学楼') {
      return 'none';
    }
    const day = this.currentDay();
    if (day === '周日' || day === '周六') {
      return 'none';
    }
    const phase = this.timePhase();
    if (phase.phase === 'inClass' || phase.phase === 'passing') {
      const students = this.studentCount(day, phase.period);
      if (students > 800) {
        return 'high';
      }
      return students > 300 ? 'medium' : 'low';
    }
    const value = this.currentTimeValue();
    for (let index = 0; index < this.periodNames.length; index++) {
      if (value < this.periodStart[index]) {
        const students = this.studentCount(day, this.periodNames[index]);
        if (students > 0) {
          if (students > 800) {
            return 'high';
          }
          return students > 300 ? 'medium' : 'low';
        }
        break;
      }
    }
    return 'none';
  }

  private predictText(): string {
    if (this.currentCategory !== '教学楼') {
      return '暂无预测';
    }
    const day = this.currentDay();
    if (day === '周日' || day === '周六') {
      return '周末无课程安排';
    }
    const phase = this.timePhase();
    const status = this.predictStatus();
    if (status === 'none') {
      return '暂无后续课程安排';
    }
    if (phase.phase === 'inClass') {
      const periodAfter = phase.period.replace('节', '节课后');
      if (status === 'high') {
        return `预计${periodAfter}人流较大`;
      }
      return status === 'medium' ? `预计${periodAfter}人流适中` : `预计${periodAfter}人流较少`;
    }
    if (phase.phase === 'passing') {
      if (status === 'high') {
        return `当前${phase.period}下课人流高峰`;
      }
      return status === 'medium' ? `当前${phase.period}下课人流适中` : `当前${phase.period}下课人流较少`;
    }
    const value = this.currentTimeValue();
    for (let index = 0; index < this.periodNames.length; index++) {
      if (value < this.periodStart[index]) {
        const period = this.periodNames[index];
        if (this.studentCount(day, period) > 0) {
          if (status === 'high') {
            return `下节${period}，下课时人流较大`;
          }
          return status === 'medium' ? `下节${period}，下课时人流适中` : `下节${period}，下课时人流较少`;
        }
        break;
      }
    }
    return '暂无后续课程安排';
  }

  private realtimeStatusText(): string {
    const status = this.realtimeStatus();
    if (status === 'medium') {
      return '适中';
    }
    if (status === 'high') {
      return '拥挤';
    }
    return '通畅';
  }

  private predictStatusText(): string {
    const status = this.predictStatus();
    if (status === 'none') {
      return '无预测';
    }
    if (status === 'medium') {
      return '适中';
    }
    if (status === 'high') {
      return '大量';
    }
    if (status === 'predict') {
      return '预计';
    }
    return '少量';
  }

  private crowdStatus(): string {
    if (this.currentCategory === '教学楼') {
      const status = this.realtimeStatus();
      if (status === 'medium') {
        return 'crowded';
      }
      if (status === 'high') {
        return 'saturated';
      }
      return 'comfortable';
    }
    const percent = this.mockPercentage();
    if (percent < 25) {
      return 'comfortable';
    }
    if (percent < 50) {
      return 'moderate';
    }
    return percent < 75 ? 'crowded' : 'saturated';
  }

  private statusLabel(): string {
    const status = this.crowdStatus();
    if (status === 'moderate') {
      return '适中';
    }
    if (status === 'crowded') {
      return '拥挤';
    }
    if (status === 'saturated') {
      return '饱和';
    }
    return '舒适';
  }

  private statusColor(): string {
    const status = this.crowdStatus();
    if (status === 'moderate') {
      return '#2196F3';
    }
    if (status === 'crowded') {
      return '#FF9800';
    }
    if (status === 'saturated') {
      return '#F44336';
    }
    return '#4CAF50';
  }

  private statusBg(): string {
    const status = this.crowdStatus();
    if (status === 'moderate') {
      return '#1A2196F3';
    }
    if (status === 'crowded') {
      return '#1AFF9800';
    }
    if (status === 'saturated') {
      return '#1AF44336';
    }
    return '#1A4CAF50';
  }

  private adviceIcon(): string {
    const status = this.crowdStatus();
    if (status === 'moderate') {
      return '◐';
    }
    if (status === 'crowded') {
      return '◑';
    }
    if (status === 'saturated') {
      return '✕';
    }
    return '✓';
  }

  private adviceText(): string {
    const status = this.crowdStatus();
    if (this.currentCategory === '饭堂') {
      if (status === 'comfortable') {
        return '空位充足，点餐无需等待';
      }
      if (status === 'moderate') {
        return '人流正常，点餐基本无需等待';
      }
      if (status === 'crowded') {
        return '正值就餐高峰，预计需要排队寻找座位';
      }
      return '人流已达上限，建议错峰就餐或选择打包';
    }
    if (this.currentCategory === '校道') {
      if (status === 'comfortable') {
        return '道路通畅，可正常通行';
      }
      if (status === 'moderate') {
        return '人流适中，通行无阻';
      }
      if (status === 'crowded') {
        return '人流密集，请慢行注意安全';
      }
      return '道路拥挤，建议绕行或稍后通过';
    }
    if (status === 'comfortable') {
      return '当前人流稀少，楼道通畅，可放心通行';
    }
    if (status === 'moderate') {
      return '人流适中，楼道较为通畅，通行基本无阻';
    }
    if (status === 'crowded') {
      return '人流较多，下课时楼道可能拥挤，建议稍作停留或走楼梯';
    }
    return '人流密集！建议错峰通行或绕行其他楼栋，注意安全';
  }

  private adviceBg(): string {
    const status = this.crowdStatus();
    if (status === 'moderate') {
      return '#F0F7FF';
    }
    if (status === 'crowded') {
      return '#FFF7EC';
    }
    if (status === 'saturated') {
      return '#FFF0F0';
    }
    return '#F1FAF2';
  }

  private realtimePersonColor(index: number): string {
    const percentage = this.realtimePercent();
    const status = this.realtimeStatus();
    let color = '#8E8E93';
    if (status === 'medium') {
      color = '#FF9800';
    } else if (status === 'high') {
      color = '#F44336';
    } else if (status === 'low') {
      color = '#4CAF50';
    }
    if (percentage >= (index + 1) * 20 || percentage > index * 20) {
      return color;
    }
    return '#E8E8E8';
  }

  private predictPersonColor(index: number): string {
    const percentage = this.predictPercent();
    const status = this.predictStatus();
    let color = '#8E8E93';
    if (status === 'low') {
      color = '#4CAF50';
    } else if (status === 'medium') {
      color = '#FF9800';
    } else if (status === 'high') {
      color = '#F44336';
    } else if (status === 'predict') {
      color = '#2196F3';
    }
    if (percentage >= (index + 1) * 20 || percentage > index * 20) {
      return color;
    }
    return '#E8E8E8';
  }

  private crowdPersonColor(index: number): string {
    const percentage = this.mockPercentage();
    if (percentage >= (index + 1) * 20 || percentage > index * 20) {
      return this.statusColor();
    }
    return '#E8E8E8';
  }

  private statusBadgeBg(status: string): string {
    if (status === 'medium') {
      return '#1FFFC107';
    }
    if (status === 'high') {
      return '#1FF44336';
    }
    if (status === 'none') {
      return '#1F8E8E93';
    }
    return '#1F4CAF50';
  }

  private statusBadgeColor(status: string): string {
    if (status === 'medium') {
      return '#FF9800';
    }
    if (status === 'high') {
      return '#F44336';
    }
    if (status === 'none') {
      return '#8E8E93';
    }
    if (status === 'predict') {
      return '#2196F3';
    }
    return '#4CAF50';
  }

  @Builder
  HeaderCard() {
    Row() {
      Column() {
        Text('校园实时监测')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .letterSpacing(1)
        Text('Campus Real-time Monitoring')
          .fontSize(11)
          .fontColor('#D9FFFFFF')
          .letterSpacing(0.5)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row() {
        Column()
          .width(6)
          .height(6)
          .backgroundColor('#FFFFFF')
          .borderRadius(3)
        Text('实时')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .margin({ left: 5 })
      }
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#33FFFFFF')
      .borderRadius(10)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 18, bottom: 18 })
    .linearGradient({ angle: 135, colors: [['#4CAF50', 0], ['#66BB6A', 1]] })
    .borderRadius(10)
    .shadow({ radius: 16, color: '#334CAF50', offsetY: 4 })
  }

  @Builder
  SegmentControl() {
    Row() {
      ForEach(this.categories, (category: string) => {
        Text(category)
          .fontSize(13)
          .fontWeight(this.currentCategory === category ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.currentCategory === category ? '#FFFFFF' : '#8E8E93')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(36)
          .borderRadius(6)
          .linearGradient(this.currentCategory === category ?
            { angle: 135, colors: [['#4CAF50', 0], ['#66BB6A', 1]] } :
            { angle: 135, colors: [['#FFFFFF', 0], ['#FFFFFF', 1]] })
          .onClick(() => {
            this.selectCategory(category);
          })
      }, (category: string) => category)
    }
    .width('100%')
    .padding(3)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .shadow({ radius: 8, color: '#0A000000', offsetY: 2 })
  }

  @Builder
  LocationSwitcher() {
    Scroll() {
      Row() {
        ForEach(this.currentLocations(), (location: string) => {
          Text(location)
            .fontSize(13)
            .fontWeight(this.currentLocation === location ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(this.currentLocation === location ? '#FFFFFF' : '#3A3A3C')
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .borderRadius(14)
            .backgroundColor(this.currentLocation === location ? '#4CAF50' : '#FFFFFF')
            .shadow({ radius: 6, color: '#0A000000', offsetY: 1 })
            .margin({ right: 6 })
            .onClick(() => {
              this.selectLocation(location);
            })
        }, (location: string) => location)
      }
      .padding({ top: 2, bottom: 2 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .align(Alignment.Start)
  }

  @Builder
  CardHeader(title: string, subtitle: string, showLocation: boolean) {
    Row() {
      Column()
        .width(3)
        .height(18)
        .backgroundColor('#4CAF50')
        .borderRadius(2)
        .margin({ right: 8 })
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')
        Text(subtitle)
          .fontSize(10)
          .fontColor('#8E8E93')
          .letterSpacing(0.5)
          .margin({ top: 1 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (showLocation) {
        Text(this.currentLocation)
          .fontSize(11)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Medium)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#1A4CAF50')
          .borderRadius(6)
      }
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  BlockPersonIcon(index: number, isRealtime: boolean) {
    Column() {
      Column()
        .width(24 * 0.34)
        .height(24 * 0.34)
        .backgroundColor(isRealtime ? this.realtimePersonColor(index) : this.predictPersonColor(index))
        .borderRadius(24 * 0.17)
      Column()
        .width(24 * 0.68)
        .height(24 * 0.46)
        .backgroundColor(isRealtime ? this.realtimePersonColor(index) : this.predictPersonColor(index))
        .borderRadius({ topLeft: 24 * 0.2, topRight: 24 * 0.2, bottomLeft: 24 * 0.08, bottomRight: 24 * 0.08 })
        .margin({ top: 24 * 0.04 })
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  CrowdPersonIcon(index: number) {
    Column() {
      Column()
        .width(36 * 0.34)
        .height(36 * 0.34)
        .backgroundColor(this.crowdPersonColor(index))
        .borderRadius(36 * 0.17)
      Column()
        .width(36 * 0.68)
        .height(36 * 0.46)
        .backgroundColor(this.crowdPersonColor(index))
        .borderRadius({ topLeft: 36 * 0.2, topRight: 36 * 0.2, bottomLeft: 36 * 0.08, bottomRight: 36 * 0.08 })
        .margin({ top: 36 * 0.04 })
    }
    .width(36)
    .height(36)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  DataBlock(isRealtime: boolean) {
    Column() {
      Row() {
        Text(isRealtime ? '🚁' : '📅')
          .fontSize(12)
          .textAlign(TextAlign.Center)
          .width(24)
          .height(24)
          .borderRadius(6)
          .backgroundColor(isRealtime ? '#4CAF50' : '#2196F3')
        Column() {
          Text(isRealtime ? '实时人流' : '预测下课人流')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1C1E')
          Text(isRealtime ? '无人机监测' : '课表系统分析')
            .fontSize(10)
            .fontColor('#8E8E93')
            .margin({ top: 1 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 6 })
      }
      .width('100%')

      Row() {
        ForEach(this.personSlots, (slot: number) => {
          this.BlockPersonIcon(slot, isRealtime)
        }, (slot: number) => `block-${isRealtime ? 'r' : 'p'}-${slot}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 8, bottom: 6 })

      Row() {
        Column()
          .width(5)
          .height(5)
          .borderRadius(2.5)
          .backgroundColor(this.statusBadgeColor(isRealtime ? this.realtimeStatus() : this.predictStatus()))
        Text(isRealtime ? this.realtimeStatusText() : this.predictStatusText())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.statusBadgeColor(isRealtime ? this.realtimeStatus() : this.predictStatus()))
          .margin({ left: 4 })
      }
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor(this.statusBadgeBg(isRealtime ? this.realtimeStatus() : this.predictStatus()))
      .borderRadius(8)

      Text(isRealtime ? this.realtimeText() : this.predictText())
        .fontSize(11)
        .fontColor('#666666')
        .lineHeight(17)
        .textAlign(TextAlign.Center)
        .margin({ top: 6 })
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
    .padding(8)
  }

  @Builder
  CrowdCard() {
    Column() {
      this.CardHeader('人流监测', 'CROWD MONITORING', true)

      if (this.currentCategory === '教学楼') {
        Row() {
          this.DataBlock(true)
          Column()
            .width(1)
            .height(120)
            .backgroundColor('#F0F0F0')
            .margin({ left: 6, right: 6 })
          this.DataBlock(false)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ top: 10, bottom: 10 })
        .margin({ bottom: 12 })
      } else {
        Column() {
          Row() {
            ForEach(this.personSlots, (slot: number) => {
              this.CrowdPersonIcon(slot)
            }, (slot: number) => `crowd-${slot}`)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Row() {
            Row() {
              Column()
                .width(5)
                .height(5)
                .borderRadius(2.5)
                .backgroundColor(this.statusColor())
              Text(this.statusLabel())
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.statusColor())
                .margin({ left: 4 })
            }
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.statusBg())
            .borderRadius(8)

            Text(`${this.mockPercentage()}%`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')
              .margin({ left: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 8 })

          Stack({ alignContent: Alignment.Start }) {
            Column()
              .width('100%')
              .height(6)
              .backgroundColor('#F0F0F0')
              .borderRadius(3)
            Column()
              .width(`${this.mockPercentage()}%`)
              .height(6)
              .backgroundColor(this.statusColor())
              .borderRadius(3)
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 8, bottom: 12 })
      }

      Row() {
        Text(this.adviceIcon())
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.statusColor())
          .textAlign(TextAlign.Center)
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor('#FFFFFF')
        Text(this.adviceText())
          .fontSize(12)
          .fontColor('#333333')
          .lineHeight(18)
          .layoutWeight(1)
          .margin({ left: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding(10)
      .backgroundColor(this.adviceBg())
      .borderRadius(8)

      Text(`数据更新于：${this.updateTime} (无人机与课表系统联合分析)`)
        .fontSize(10)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 12, color: '#0A000000', offsetY: 2 })
  }

  @Builder
  WeatherCard() {
    Column() {
      this.CardHeader('环境感知', 'ENVIRONMENT', false)

      Row() {
        Column() {
          Text('🌤️')
            .fontSize(34)
          Row() {
            Text('26')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')
            Text('°C')
              .fontSize(14)
              .fontColor('#8E8E93')
              .margin({ left: 1, bottom: 4 })
          }
          .alignItems(VerticalAlign.Bottom)
          Text('多云')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Row() {
            Text('PM2.5')
              .fontSize(12)
              .fontColor('#666666')
            Blank()
            Text('35')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1C1E')
            Text('μg/m³')
              .fontSize(10)
              .fontColor('#8E8E93')
              .margin({ left: 2, bottom: 2 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)

          Row() {
            Text('空气质量')
              .fontSize(12)
              .fontColor('#666666')
            Blank()
            Text('良')
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor('#4CAF50')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#1A4CAF50')
              .borderRadius(6)
          }
          .width('100%')
          .margin({ top: 12 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 16 })
      }
      .width('100%')
      .padding({ top: 6, bottom: 6 })

      Text(`数据更新于：${this.updateTime} (无人机与课表系统联合分析)`)
        .fontSize(10)
        .fontColor('#999999')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 10 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 12, color: '#0A000000', offsetY: 2 })
  }

  build() {
    Column() {
      PageHeader({ title: '校园人流数据' })
      Scroll() {
        Column() {
          this.HeaderCard()
          Column() {
            this.SegmentControl()
          }
          .margin({ top: 12 })
          Column() {
            this.LocationSwitcher()
          }
          .margin({ top: 10, bottom: 12 })
          this.CrowdCard()
          Column() {
            this.WeatherCard()
          }
          .margin({ top: 12 })
          Text('数据仅供参考 · 请以实际情况为准')
            .fontSize(10)
            .fontColor('#999999')
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 16, bottom: 8 })
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }
}
