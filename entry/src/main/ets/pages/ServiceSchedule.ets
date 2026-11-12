import { common } from '@kit.AbilityKit';
import { SchoolCourse } from '../models/MiniProgramModels';
import { SchoolApi } from '../api/SchoolApi';
import { AiCallbacks, AiMessage, AiOptions, AiService, AiSession } from '../services/AiService';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { PageHeader } from '../components/common/PageHeader';
import { MarkdownView } from '../components/common/MarkdownView';

class ScheduleCredentials {
  studentNo: string = '';
  password: string = '';
}

@Entry
@Component
struct ServiceSchedule {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private readonly termLabels: string[] = ['2025-2026-2', '2025-2026-1', '2024-2025-3', '2024-2025-2',
    '2024-2025-1', '2023-2024-3', '2023-2024-2', '2023-2024-1'];
  private readonly termValues: string[] = ['20252', '20251', '20243', '20242', '20241', '20233', '20232', '20231'];
  private readonly weekDays: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  private readonly weekLabels: string[] = ['第1周', '第2周', '第3周', '第4周', '第5周', '第6周', '第7周',
    '第8周', '第9周', '第10周', '第11周', '第12周', '第13周', '第14周', '第15周', '第16周', '第17周'];
  private readonly timePeriods: string[] = ['08:30-10:05', '10:25-12:00', '14:00-15:35', '15:55-17:30',
    '18:30-20:05', '20:25-22:00'];
  private readonly cardBackgrounds: string[] = ['#E8F4FD', '#F3E8FD', '#E8FDF0', '#FDF6E8', '#FDE8F0',
    '#E8FDF8', '#F0FDE8', '#FDFBE8', '#ECE8FD', '#F8F8F8'];
  private readonly cardAccents: string[] = ['#5AC8FA', '#AF52DE', '#34C759', '#FF9500', '#FF2D55',
    '#00C7BE', '#30D158', '#FFD60A', '#BF5AF2', '#8E8E93'];
  private aiSession: AiSession | null = null;
  private aiScroller: Scroller = new Scroller();

  @State studentNo: string = '';
  @State password: string = '';
  @State termIndex: number = 0;
  @State weekIndex: number = 0;
  @State isLoggedIn: boolean = false;
  @State loading: boolean = false;
  @State courses: SchoolCourse[] = [];
  @State currentWeek: number = 1;
  @State showDetail: boolean = false;
  @State selectedCourse: SchoolCourse = new SchoolCourse();
  @State showAi: boolean = false;
  @State aiText: string = '';
  @State aiLoading: boolean = false;

  aboutToAppear(): void {
    this.loadCredentials();
  }

  aboutToDisappear(): void {
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
  }

  private async loadCredentials(): Promise<void> {
    const credentials = await CacheStore.getJson<ScheduleCredentials>(this.context, 'schoolScheduleCredentials',
      new ScheduleCredentials());
    if (credentials.studentNo.length > 0) {
      this.studentNo = credentials.studentNo;
      this.password = credentials.password;
    }
  }

  private async saveCredentials(): Promise<void> {
    const credentials = new ScheduleCredentials();
    credentials.studentNo = this.studentNo;
    credentials.password = this.password;
    await CacheStore.setJson<ScheduleCredentials>(this.context, 'schoolScheduleCredentials', credentials);
  }

  private termMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    this.termLabels.forEach((label: string, index: number) => {
      items.push({
        value: label,
        action: () => {
          this.termIndex = index;
        }
      });
    });
    return items;
  }

  private weekMenu(): MenuElement[] {
    const items: MenuElement[] = [];
    this.weekLabels.forEach((label: string, index: number) => {
      items.push({
        value: label,
        action: () => {
          this.weekIndex = index;
        }
      });
    });
    return items;
  }

  private todayIndex(): number {
    const day = new Date().getDay();
    return day === 0 ? 6 : day - 1;
  }

  private async querySchedule(): Promise<void> {
    if (this.studentNo.trim().length === 0) {
      ToastUtil.show('请输入学号');
      return;
    }
    if (this.password.trim().length === 0) {
      ToastUtil.show('请输入密码');
      return;
    }
    this.loading = true;
    const startTime = Date.now();
    try {
      const courses = await SchoolApi.schedule(this.studentNo.trim(), this.password,
        this.termValues[this.termIndex], `${this.currentWeek}`);
      await this.waitAtLeast(startTime);
      await this.saveCredentials();
      this.courses = courses;
      this.isLoggedIn = true;
      ToastUtil.show(courses.length > 0 ? '查询成功' : '该周次暂无课程安排');
    } catch (err) {
      await this.waitAtLeast(startTime);
      this.courses = [];
      LogUtil.warn('schedule', `query failed ${(err as Error).message}`);
      ToastUtil.show(this.errorMessage((err as Error).message));
    } finally {
      this.loading = false;
    }
  }

  private async loadScheduleData(): Promise<void> {
    if (!this.isLoggedIn) {
      return;
    }
    this.loading = true;
    try {
      this.courses = await SchoolApi.schedule(this.studentNo.trim(), this.password,
        this.termValues[this.termIndex], `${this.currentWeek}`);
      if (this.courses.length === 0) {
        ToastUtil.show(`第${this.currentWeek}周暂无课程`);
      } else {
        ToastUtil.show(`第${this.currentWeek}周课表加载成功`);
      }
    } catch (err) {
      ToastUtil.show(this.errorMessage((err as Error).message));
    } finally {
      this.loading = false;
    }
  }

  private errorMessage(message: string): string {
    if (message.includes('401') || message.includes('Unauthorized')) {
      return '账号或密码错误';
    }
    if (message.includes('timeout')) {
      return '网络超时，请检查网络';
    }
    if (message.includes('network')) {
      return '网络连接失败';
    }
    return '查询失败，请稍后重试';
  }

  private async waitAtLeast(startTime: number): Promise<void> {
    const remain = 800 - (Date.now() - startTime);
    if (remain > 0) {
      await new Promise<void>((resolve: () => void) => {
        setTimeout(() => {
          resolve();
        }, remain);
      });
    }
  }

  private changeWeek(delta: number): void {
    const next = this.currentWeek + delta;
    if (next < 1 || next > 17) {
      return;
    }
    this.currentWeek = next;
    this.weekIndex = next - 1;
    this.loadScheduleData();
  }

  private resetForm(): void {
    this.isLoggedIn = false;
    this.courses = [];
    this.studentNo = '';
    this.password = '';
    this.termIndex = 0;
    this.weekIndex = 0;
    this.currentWeek = 1;
  }

  private visibleCourses(): SchoolCourse[] {
    const result: SchoolCourse[] = [];
    for (let index = 0; index < this.courses.length; index++) {
      const course = this.courses[index];
      if (course.dayOfWeek >= 1 && course.dayOfWeek <= 7 && course.startTime >= 1) {
        result.push(course);
      }
    }
    return result;
  }

  private courseRowStart(course: SchoolCourse): number {
    return Math.max(Math.floor((course.startTime - 1) / 2), 0);
  }

  private courseRowEnd(course: SchoolCourse): number {
    return Math.min(Math.ceil(course.endTime / 2) - 1, 5);
  }

  private colorIndex(course: SchoolCourse): number {
    const seed = course.courseCode.length + course.name.length;
    return seed % 10;
  }

  private courseBackground(course: SchoolCourse): string {
    return this.cardBackgrounds[this.colorIndex(course)];
  }

  private courseAccent(course: SchoolCourse): string {
    return this.cardAccents[this.colorIndex(course)];
  }

  private dayLabel(course: SchoolCourse): string {
    return course.dayOfWeek >= 1 && course.dayOfWeek <= 7 ? this.weekDays[course.dayOfWeek - 1] : '周一';
  }

  private openDetail(course: SchoolCourse): void {
    this.selectedCourse = course;
    this.showDetail = true;
  }

  private aiPrompt(): string {
    let text = `## 第${this.currentWeek}周课程表\n\n`;
    const totalCourses = this.courses.length;
    let totalHours = 0;
    this.courses.forEach((course: SchoolCourse) => {
      totalHours += course.endTime - course.startTime + 1;
    });
    for (let day = 1; day <= 7; day++) {
      const dayCourses = this.courses.filter((course: SchoolCourse) => course.dayOfWeek === day);
      if (dayCourses.length > 0) {
        text += `### ${this.weekDays[day - 1]} (${dayCourses.length}门课)\n\n`;
        dayCourses.forEach((course: SchoolCourse) => {
          const slot = this.timePeriods[Math.floor((course.startTime - 1) / 2)];
          text += `- **${course.name}** (${course.courseCode.length > 0 ? course.courseCode : '无代码'})\n`;
          text += `  - 时间：${slot}\n`;
          text += `  - 地点：${course.location.length > 0 ? course.location : '待定'}\n`;
          text += `  - 教师：${course.teacher.length > 0 ? course.teacher : '未知'}\n\n`;
        });
      } else {
        text += `### ${this.weekDays[day - 1]} (无课程)\n\n`;
      }
    }
    text += '## 统计信息\n\n';
    text += `- 本周总课程：${totalCourses}门\n`;
    text += `- 本周总课时：${totalHours}节\n`;
    return text;
  }

  private startAnalysis(): void {
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
    this.aiText = '';
    this.aiLoading = true;
    const prompt = `你是一个专业的时间管理顾问，请分析以下学生的课程安排，提供时间管理建议。\n\n` +
      `${this.aiPrompt()}\n\n请从以下几个方面进行分析：\n` +
      `1. **时间安排**：课程分布是否合理，是否存在过载或空闲时间过多的情况\n` +
      `2. **空闲时间利用**：建议如何有效利用空闲时间，包括学习、休息、社交等\n` +
      `3. **学习建议**：根据课程特点、时间分布提供学习方法建议\n` +
      `4. **注意事项**：需要特别关注的时间点，如早八课程、连续上课等\n\n` +
      `**格式要求（重要）**：\n- 使用 Markdown 格式，包括标题、列表等\n` +
      `- 严禁使用表格（table）元素，因为显示区域较小，表格显示效果不好\n` +
      `- 使用列表（bullet points）代替表格来组织信息\n` +
      `- 代码块仅在必要时使用，优先使用加粗、列表等简洁格式\n\n` +
      `语气要友好实用，提供可操作的建议。`;
    const options = new AiOptions();
    options.maxTokens = 1600;
    options.temperature = 0.6;
    options.retries = 1;
    const messages: AiMessage[] = [
      new AiMessage('system', '你是校园教务助手，用 Markdown 输出清晰、可执行的课表分析建议。'),
      new AiMessage('user', prompt)
    ];
    const callbacks = new AiCallbacks(
      (chunk: string) => {
        this.aiText += chunk;
        this.aiLoading = true;
        this.scrollAiToBottom();
      },
      (fullText: string) => {
        if (fullText.length > 0) {
          this.aiText = fullText;
        }
        this.aiLoading = false;
        this.aiSession = null;
      },
      (message: string) => {
        LogUtil.warn('schedule-ai', `analysis failed ${message}`);
        this.aiText = '抱歉，AI分析失败，请稍后重试。';
        this.aiLoading = false;
        this.aiSession = null;
      }
    );
    this.aiSession = AiService.chatWithMessages(messages, callbacks, options);
  }

  private scrollAiToBottom(): void {
    setTimeout(() => {
      this.aiScroller.scrollEdge(Edge.Bottom);
    }, 80);
  }

  private openAi(): void {
    this.showAi = true;
    if (this.courses.length === 0) {
      this.aiText = '_暂无课程数据可供分析_';
      this.aiLoading = false;
      return;
    }
    this.startAnalysis();
  }

  private closeAi(): void {
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
    this.showAi = false;
  }

  @Builder
  HeaderSection() {
    Row() {
      Text('📅')
        .fontSize(24)
        .textAlign(TextAlign.Center)
        .width(52)
        .height(52)
        .borderRadius(14)
        .backgroundColor('#33FFFFFF')
      Column() {
        Text('课程表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('查看您的课程安排')
          .fontSize(12)
          .fontColor('#D9FFFFFF')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .linearGradient({ angle: 135, colors: [['#007AFF', 0], ['#5AC8FA', 1]] })
    .shadow({ radius: 16, color: '#1A007AFF', offsetY: 4 })
  }

  @Builder
  FormLabel(icon: string, label: string) {
    Row() {
      Text(icon)
        .fontSize(13)
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .margin({ left: 5 })
    }
    .margin({ bottom: 6 })
  }

  @Builder
  PickerField(text: string, menu: MenuElement[]) {
    Row() {
      Text(text)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
      Text('▾')
        .fontSize(12)
        .fontColor('#C7C7CC')
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#F7F9FC')
    .borderRadius(10)
    .bindMenu(menu)
  }

  @Builder
  LoginForm() {
    Column() {
      Row() {
        Column()
          .width(3)
          .height(18)
          .backgroundColor('#007AFF')
          .borderRadius(2)
          .margin({ right: 8 })
        Column() {
          Text('教务系统登录')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
          Text('ACADEMIC SYSTEM')
            .fontSize(9)
            .fontColor('#8E8E93')
            .letterSpacing(0.5)
            .margin({ top: 1 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ bottom: 14 })

      this.FormLabel('👤', '学号')
      TextInput({ placeholder: '请输入学号', text: this.studentNo })
        .height(44)
        .fontSize(14)
        .backgroundColor('#F7F9FC')
        .borderRadius(10)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.studentNo = value;
        })

      Column() {
        this.FormLabel('🔒', '密码')
      }
      .margin({ top: 12 })

      TextInput({ placeholder: '请输入教务系统密码', text: this.password })
        .type(InputType.Password)
        .height(44)
        .fontSize(14)
        .backgroundColor('#F7F9FC')
        .borderRadius(10)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.password = value;
        })

      Column() {
        this.FormLabel('📅', '学期')
      }
      .margin({ top: 12 })

      this.PickerField(this.termLabels[this.termIndex], this.termMenu())

      Column() {
        this.FormLabel('📅', '周次')
      }
      .margin({ top: 12 })

      this.PickerField(`第${this.weekIndex + 1}周`, this.weekMenu())

      Button(this.loading ? '查询中...' : '查询课表')
        .width('100%')
        .height(46)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .backgroundColor(this.loading ? '#99A8C7' : '#007AFF')
        .borderRadius(10)
        .margin({ top: 20 })
        .enabled(!this.loading)
        .onClick(() => {
          this.currentWeek = this.weekIndex + 1;
          this.querySchedule();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 12, color: '#0A000000', offsetY: 2 })
  }

  @Builder
  WeekSelector() {
    Row() {
      Text('‹')
        .fontSize(20)
        .fontColor(this.currentWeek <= 1 ? '#C7C7CC' : '#007AFF')
        .textAlign(TextAlign.Center)
        .width(34)
        .height(34)
        .backgroundColor('#F2F6FA')
        .borderRadius(9)
        .onClick(() => {
          this.changeWeek(-1);
        })
      Row() {
        Text('第')
          .fontSize(12)
          .fontColor('#8E8E93')
        Text(`${this.currentWeek}`)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007AFF')
          .margin({ left: 2, right: 2 })
        Text('周')
          .fontSize(12)
          .fontColor('#8E8E93')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      Text('›')
        .fontSize(20)
        .fontColor(this.currentWeek >= 17 ? '#C7C7CC' : '#007AFF')
        .textAlign(TextAlign.Center)
        .width(34)
        .height(34)
        .backgroundColor('#F2F6FA')
        .borderRadius(9)
        .onClick(() => {
          this.changeWeek(1);
        })
      Column()
        .width(1)
        .height(20)
        .backgroundColor('#E5E6EB')
        .margin({ left: 12, right: 12 })
      Row() {
        Text('⟳')
          .fontSize(16)
          .fontColor('#5AC8FA')
        Text('重新查询')
          .fontSize(12)
          .fontColor('#5AC8FA')
          .margin({ left: 4 })
      }
      .onClick(() => {
        this.resetForm();
      })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 8, color: '#0A000000', offsetY: 2 })
  }

  @Builder
  TimeCell(index: number) {
    Column() {
      Text(`${index * 2 + 1}-${index * 2 + 2}节`)
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor('#007AFF')
      Text(this.timePeriods[index])
        .fontSize(7)
        .fontColor('#8E8E93')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F8FAFC')
    .border({ width: { bottom: 0.5 }, color: '#EFF2F6' })
  }

  @Builder
  CourseCell(course: SchoolCourse) {
    Row() {
      Column()
        .width(2)
        .height('86%')
        .backgroundColor(this.courseAccent(course))
        .borderRadius(1)
        .margin({ right: 3 })
      Column() {
        Text(course.name)
          .fontSize(8)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1C1E')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(course.location)
          .fontSize(7)
          .fontColor('#6B7280')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(3)
    .backgroundColor(this.courseBackground(course))
    .borderRadius(5)
    .onClick(() => {
      this.openDetail(course);
    })
  }

  @Builder
  ScheduleCard() {
    Column() {
      Row() {
        Text('时间')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .width(38)
        ForEach(this.weekDays, (day: string, index: number) => {
          Text(day)
            .fontSize(10)
            .fontWeight(index === this.todayIndex() ? FontWeight.Bold : FontWeight.Medium)
            .fontColor(index === this.todayIndex() ? '#007AFF' : '#666666')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (day: string) => day)
      }
      .width('100%')
      .height(32)
      .backgroundColor('#F8FAFC')

      Grid() {
        ForEach(this.timePeriods, (period: string, index: number) => {
          GridItem() {
            this.TimeCell(index)
          }
          .rowStart(index)
          .rowEnd(index)
          .columnStart(0)
          .columnEnd(0)
        }, (period: string) => period)

        ForEach(this.visibleCourses(), (course: SchoolCourse) => {
          GridItem() {
            this.CourseCell(course)
          }
          .rowStart(this.courseRowStart(course))
          .rowEnd(this.courseRowEnd(course))
          .columnStart(course.dayOfWeek)
          .columnEnd(course.dayOfWeek)
        }, (course: SchoolCourse) => `${course.id}-${course.dayOfWeek}-${course.startTime}-${course.name}`)
      }
      .columnsTemplate('38fr repeat(7, 1fr)')
      .rowsTemplate('repeat(6, 1fr)')
      .columnsGap(1)
      .rowsGap(1)
      .width('100%')
      .height(390)
      .backgroundColor('#EFF2F6')
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .clip(true)
    .shadow({ radius: 12, color: '#0A000000', offsetY: 2 })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('📚')
        .fontSize(40)
      Text('暂无课程数据')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 10 })
      Text('请检查周次选择或稍后重试')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
  }

  @Builder
  DetailRow(icon: string, label: string, value: string) {
    Row() {
      Text(icon)
        .fontSize(13)
        .width(22)
      Text(label)
        .fontSize(12)
        .fontColor('#8E8E93')
        .width(52)
      Text(value)
        .fontSize(13)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  CourseDetailModal() {
    Column() {
      Row() {
        Column()
          .width(3)
          .height(20)
          .backgroundColor(this.courseAccent(this.selectedCourse))
          .borderRadius(2)
          .margin({ right: 8 })
        Text(this.selectedCourse.name.length > 0 ? this.selectedCourse.name : '课程详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .layoutWeight(1)
        Text('✕')
          .fontSize(16)
          .fontColor('#8E8E93')
          .padding(4)
          .onClick(() => {
            this.showDetail = false;
          })
      }
      .width('100%')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Column() {
        this.DetailRow('📍', '教室', this.selectedCourse.location.length > 0 ? this.selectedCourse.location : '未安排')
        this.DetailRow('👨‍🏫', '教师', this.selectedCourse.teacher.length > 0 ? this.selectedCourse.teacher : '未安排')
        this.DetailRow('📅', '周次', `第${this.selectedCourse.week}周`)
        this.DetailRow('🕐', '时间',
          `${this.dayLabel(this.selectedCourse)} 第${this.selectedCourse.startTime}-${this.selectedCourse.endTime}节`)
        if (this.selectedCourse.className.length > 0) {
          this.DetailRow('🏫', '班级', this.selectedCourse.className)
        }
        if (this.selectedCourse.credits > 0) {
          this.DetailRow('📖', '学分', `${this.selectedCourse.credits} 学分`)
        }
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('82%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .onClick(() => {
    })
  }

  @Builder
  AiPanel() {
    Column() {
      Row() {
        Text('✨')
          .fontSize(16)
        Text('AI课表分析')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1C1E')
          .margin({ left: 6 })
          .layoutWeight(1)
        Text('✕')
          .fontSize(16)
          .fontColor('#8E8E93')
          .padding(4)
          .onClick(() => {
            this.closeAi();
          })
      }
      .width('100%')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: '#F0F0F0' })

      Scroll(this.aiScroller) {
        Column() {
          if (this.aiText.length > 0) {
            MarkdownView({ markdown: this.aiText, baseFontSize: 13 })
          } else {
            Text('正在生成分析...')
              .fontSize(13)
              .fontColor('#8E8E93')
          }
          if (this.aiLoading) {
            Text('▋')
              .fontSize(13)
              .fontColor('#007AFF')
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .margin({ top: 8 })
    }
    .width('86%')
    .height('65%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .onClick(() => {
    })
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        PageHeader({ title: '课表查询' })
        Scroll() {
          Column() {
            this.HeaderSection()

            if (!this.isLoggedIn) {
              Column() {
                this.LoginForm()
              }
              .margin({ top: 14 })
            } else {
              Column() {
                this.WeekSelector()
              }
              .margin({ top: 14 })

              if (this.loading) {
                Row() {
                  LoadingProgress()
                    .width(22)
                    .height(22)
                    .color('#007AFF')
                  Text('加载中...')
                    .fontSize(12)
                    .fontColor('#8E8E93')
                    .margin({ left: 8 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding(24)
              } else if (this.courses.length > 0) {
                Column() {
                  this.ScheduleCard()
                }
                .margin({ top: 14 })
              } else {
                this.EmptyState()
              }
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 90 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')

      if (this.isLoggedIn && !this.showAi && !this.showDetail) {
        Row() {
          Text('💬')
            .fontSize(15)
          Text('AI分析')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ left: 5 })
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('#007AFF')
        .borderRadius(22)
        .shadow({ radius: 14, color: '#33007AFF', offsetY: 4 })
        .margin({ right: 18, bottom: 28 })
        .onClick(() => {
          this.openAi();
        })
      }

      if (this.showAi) {
        Column() {
          this.AiPanel()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#66000000')
        .onClick(() => {
          this.closeAi();
        })
      }

      if (this.showDetail) {
        Column() {
          this.CourseDetailModal()
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#66000000')
        .onClick(() => {
          this.showDetail = false;
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F6FA')
  }
}
