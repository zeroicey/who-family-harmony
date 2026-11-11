import { common } from '@kit.AbilityKit';
import { GradeRecord } from '../models/MiniProgramModels';
import { SchoolApi } from '../api/SchoolApi';
import { AiCallbacks, AiMessage, AiOptions, AiService, AiSession } from '../services/AiService';
import { CacheStore } from '../stores/CacheStore';
import { LogUtil } from '../utils/LogUtil';
import { ToastUtil } from '../utils/ToastUtil';
import { PageHeader } from '../components/common/PageHeader';
import { MarkdownView } from '../components/common/MarkdownView';

class GradeCredentials {
  studentNo: string = '';
  password: string = '';
}

@Entry
@Component
struct ServiceGrade {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private readonly termLabels: string[] = ['2025-2026-2', '2025-2026-1', '2024-2025-3', '2024-2025-2',
    '2024-2025-1', '2023-2024-3', '2023-2024-2', '2023-2024-1'];
  private readonly termValues: string[] = ['20252', '20251', '20243', '20242', '20241', '20233', '20232', '20231'];
  private readonly badgePalette: string[] = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA07A', '#98D8C8',
    '#F7DC6F', '#BB8FCE', '#85C1E2', '#F8B500', '#6C5CE7'];
  private aiSession: AiSession | null = null;
  private aiScroller: Scroller = new Scroller();

  @State studentNo: string = '';
  @State password: string = '';
  @State termIndex: number = 2;
  @State loading: boolean = false;
  @State isLoggedIn: boolean = false;
  @State grades: GradeRecord[] = [];
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
    const credentials = await CacheStore.getJson<GradeCredentials>(this.context, 'schoolGradeCredentials',
      new GradeCredentials());
    if (credentials.studentNo.length > 0) {
      this.studentNo = credentials.studentNo;
      this.password = credentials.password;
    }
  }

  private async saveCredentials(): Promise<void> {
    const credentials = new GradeCredentials();
    credentials.studentNo = this.studentNo;
    credentials.password = this.password;
    await CacheStore.setJson<GradeCredentials>(this.context, 'schoolGradeCredentials', credentials);
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

  private numeric(value: string): number {
    const parsed = Number(value);
    if (parsed >= 0 || parsed < 0) {
      return parsed;
    }
    return 0;
  }

  private totalCredits(): string {
    let total = 0;
    this.grades.forEach((grade: GradeRecord) => {
      total += this.numeric(grade.credit);
    });
    return `${Math.round(total * 10) / 10}`;
  }

  private averageScore(): string {
    if (this.grades.length === 0) {
      return '0';
    }
    let total = 0;
    this.grades.forEach((grade: GradeRecord) => {
      total += this.numeric(grade.score);
    });
    return `${Math.round(total / this.grades.length * 10) / 10}`;
  }

  private averageGpa(): string {
    if (this.grades.length === 0) {
      return '0';
    }
    let total = 0;
    this.grades.forEach((grade: GradeRecord) => {
      total += this.numeric(grade.gpa);
    });
    return `${Math.round(total / this.grades.length * 100) / 100}`;
  }

  private scoreLevel(score: string): string {
    const value = this.numeric(score);
    if (value >= 90) {
      return 'excellent';
    }
    if (value >= 80) {
      return 'good';
    }
    if (value >= 70) {
      return 'average';
    }
    if (value >= 60) {
      return 'pass';
    }
    return 'fail';
  }

  private scoreLabel(score: string): string {
    const value = this.numeric(score);
    if (value >= 90) {
      return '优秀';
    }
    if (value >= 80) {
      return '良好';
    }
    if (value >= 70) {
      return '中等';
    }
    if (value >= 60) {
      return '及格';
    }
    return '不及格';
  }

  private scoreGradient(score: string): Array<[ResourceColor, number]> {
    const level = this.scoreLevel(score);
    if (level === 'excellent') {
      return [['#4CAF50', 0], ['#66BB6A', 1]];
    }
    if (level === 'good') {
      return [['#2196F3', 0], ['#42A5F5', 1]];
    }
    if (level === 'average') {
      return [['#FF9800', 0], ['#FFA726', 1]];
    }
    if (level === 'pass') {
      return [['#9C27B0', 0], ['#AB47BC', 1]];
    }
    return [['#F44336', 0], ['#EF5350', 1]];
  }

  private badgeColor(text: string): string {
    if (text.length === 0) {
      return '#BDC3C7';
    }
    let hash = 0;
    for (let index = 0; index < text.length; index++) {
      hash = (hash * 31 + text.charCodeAt(index)) % 997;
    }
    return this.badgePalette[hash % this.badgePalette.length];
  }

  private async queryGrades(): Promise<void> {
    if (this.studentNo.trim().length === 0) {
      ToastUtil.show('请输入学号');
      return;
    }
    if (this.password.trim().length === 0) {
      ToastUtil.show('请输入密码');
      return;
    }
    this.loading = true;
    try {
      const grades = await SchoolApi.grades(this.studentNo.trim(), this.password, this.termValues[this.termIndex]);
      await this.saveCredentials();
      this.grades = grades;
      this.isLoggedIn = true;
      ToastUtil.show(grades.length > 0 ? '查询成功' : '暂无成绩数据');
    } catch (err) {
      this.grades = [];
      LogUtil.warn('grade', `query failed ${(err as Error).message}`);
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

  private resetForm(): void {
    this.isLoggedIn = false;
    this.grades = [];
    this.studentNo = '';
    this.password = '';
    this.termIndex = 2;
  }

  private aiPrompt(): string {
    let text = '## 课程成绩明细\n\n';
    this.grades.forEach((grade: GradeRecord, index: number) => {
      text += `${index + 1}. **${grade.course}** (${grade.courseCode.length > 0 ? grade.courseCode : '无代码'})\n`;
      text += `   - 成绩：${grade.score}分\n`;
      text += `   - 学分：${grade.credit}\n`;
      text += `   - 绩点：${grade.gpa}\n`;
      text += `   - 类型：${grade.type.length > 0 ? grade.type : '未知'}\n`;
      text += `   - 类别：${grade.category.length > 0 ? grade.category : '其他'}\n\n`;
    });
    text += '## 统计数据\n\n';
    text += `- 总课程数：${this.grades.length}门\n`;
    text += `- 总学分：${this.totalCredits()}\n`;
    text += `- 平均分：${this.averageScore()}\n`;
    text += `- 平均绩点：${this.averageGpa()}\n`;
    return text;
  }

  private startAnalysis(): void {
    if (this.aiSession !== null) {
      this.aiSession.cancel();
      this.aiSession = null;
    }
    this.aiText = '';
    this.aiLoading = true;
    const prompt = `你是一个专业的学业顾问，请分析以下学生的成绩数据，提供专业的学习建议和评价。\n\n` +
      `${this.aiPrompt()}\n\n请从以下几个方面进行分析：\n` +
      `1. **总体评价**：整体学业表现概述，包括成绩水平、排名等\n` +
      `2. **成绩亮点**：表现优秀的课程和值得肯定的地方\n` +
      `3. **改进建议**：针对薄弱环节的具体改进措施\n` +
      `4. **学习规划**：下学期的学习重点和计划建议\n\n` +
      `**格式要求（重要）**：\n- 使用 Markdown 格式，包括标题、列表等\n` +
      `- 严禁使用表格（table）元素，因为显示区域较小，表格显示效果不好\n` +
      `- 使用列表（bullet points）代替表格来组织信息\n` +
      `- 代码块仅在必要时使用，优先使用加粗、列表等简洁格式\n\n` +
      `语气要友好鼓励，帮助学生建立信心。`;
    const options = new AiOptions();
    options.maxTokens = 1600;
    options.temperature = 0.7;
    options.retries = 1;
    const messages: AiMessage[] = [
      new AiMessage('system', '你是校园学业顾问，用 Markdown 输出清晰、可执行的成绩分析与学习建议。'),
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
        LogUtil.warn('grade-ai', `analysis failed ${message}`);
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
    if (this.grades.length === 0) {
      this.aiText = '_暂无成绩数据可供分析_';
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
      Text('🏅')
        .fontSize(26)
        .textAlign(TextAlign.Center)
        .width(54)
        .height(54)
        .borderRadius(14)
        .backgroundColor('#26FFFFFF')
      Column() {
        Text('成绩查询')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('查看您的学习成果与学业表现')
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
  LoginForm() {
    Column() {
      Row() {
        Text('👤')
          .fontSize(15)
          .textAlign(TextAlign.Center)
          .width(38)
          .height(38)
          .borderRadius(19)
          .backgroundColor('#007AFF')
        Column() {
          Text('教务系统登录')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
          Text('请输入您的学号和密码查询成绩')
            .fontSize(11)
            .fontColor('#8E8E93')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 16 })

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

      Row() {
        Text(this.termLabels[this.termIndex])
          .fontSize(14)
          .fontColor('#333333')
          .layoutWeight(1)
        Text('▾')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .backgroundColor('#F7F9FC')
      .borderRadius(10)
      .bindMenu(this.termMenu())

      Button(this.loading ? '查询中...' : '查询成绩')
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
          this.queryGrades();
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
  StatItem(icon: string, iconBg: string, kind: string) {
    Column() {
      Text(icon)
        .fontSize(16)
        .textAlign(TextAlign.Center)
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor(iconBg)
      Text(kind === 'courses' ? `${this.grades.length}` :
        kind === 'credits' ? this.totalCredits() :
          kind === 'score' ? this.averageScore() : this.averageGpa())
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#007AFF')
        .margin({ top: 6 })
      Text(kind === 'courses' ? '总课程数' : kind === 'credits' ? '总学分' :
        kind === 'score' ? '平均分' : '平均绩点')
        .fontSize(11)
        .fontColor('#666666')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  GradeItem(grade: GradeRecord) {
    Column() {
      Row() {
        Column() {
          Text(grade.course.length > 0 ? grade.course : '未知课程')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(grade.courseCode.length > 0 ? grade.courseCode : '无代码')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .backgroundColor(this.badgeColor(grade.courseCode))
              .borderRadius(5)
            Text(grade.category.length > 0 ? grade.category : '其他')
              .fontSize(10)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .backgroundColor(this.badgeColor(grade.category))
              .borderRadius(5)
              .margin({ left: 5 })
          }
          .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(grade.score.length > 0 ? grade.score : '0')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.scoreLabel(grade.score))
            .fontSize(10)
            .fontColor('#E6FFFFFF')
            .margin({ top: 2 })
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(9)
        .linearGradient({ angle: 135, colors: this.scoreGradient(grade.score) })
        .margin({ left: 10 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Row() {
        this.DetailItem('📘', '学分', grade.credit)
        this.DetailItem('⭐', '绩点', grade.gpa)
        this.DetailItem('🏷️', '类型', grade.type.length > 0 ? grade.type : '未知')
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .shadow({ radius: 10, color: '#0A000000', offsetY: 2 })
  }

  @Builder
  DetailItem(icon: string, label: string, value: string) {
    Row() {
      Text(icon)
        .fontSize(11)
      Column() {
        Text(label)
          .fontSize(9)
          .fontColor('#999999')
        Text(value.length > 0 ? value : '-')
          .fontSize(11)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 1 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 4 })
    }
    .layoutWeight(1)
    .padding({ left: 6, right: 4, top: 6, bottom: 6 })
    .backgroundColor('#F8F9FA')
    .borderRadius(7)
    .margin({ right: 6 })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('📋')
        .fontSize(40)
      Text('暂无成绩数据')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 10 })
      Text('请检查学期选择或稍后重试')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
      Button('重新选择学期')
        .fontSize(12)
        .fontColor('#007AFF')
        .height(36)
        .padding({ left: 18, right: 18 })
        .backgroundColor('#E8F1FF')
        .borderRadius(18)
        .margin({ top: 14 })
        .onClick(() => {
          this.resetForm();
        })
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
  }

  @Builder
  AiPanel() {
    Column() {
      Row() {
        Text('✨')
          .fontSize(16)
        Text('AI成绩分析')
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
        PageHeader({ title: '成绩查询' })
        Scroll() {
          Column() {
            this.HeaderSection()

            if (!this.isLoggedIn) {
              Column() {
                this.LoginForm()
              }
              .margin({ top: 14 })
            } else {
              Row() {
                Text('📋')
                  .fontSize(18)
                Text('成绩单')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .margin({ left: 8 })
                  .layoutWeight(1)
                Text(this.termLabels[this.termIndex])
                  .fontSize(11)
                  .fontColor('#007AFF')
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .backgroundColor('#E8F1FF')
                  .borderRadius(6)
              }
              .width('100%')
              .padding({ left: 4, right: 4, top: 6, bottom: 6 })

              Row() {
                this.StatItem('📚', '#E3F2FD', 'courses')
                this.StatItem('🎓', '#F3E5F5', 'credits')
                this.StatItem('📊', '#E8F5E8', 'score')
                this.StatItem('⭐', '#FFF3E0', 'gpa')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 10, color: '#0A000000', offsetY: 2 })
              .margin({ top: 8 })

              if (this.loading) {
                Row() {
                  LoadingProgress()
                    .width(22)
                    .height(22)
                    .color('#007AFF')
                  Text('查询中...')
                    .fontSize(12)
                    .fontColor('#8E8E93')
                    .margin({ left: 8 })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .padding(24)
              } else if (this.grades.length > 0) {
                Column() {
                  ForEach(this.grades, (grade: GradeRecord) => {
                    Column() {
                      this.GradeItem(grade)
                    }
                    .margin({ top: 10 })
                  }, (grade: GradeRecord) => `${grade.id}-${grade.course}-${grade.score}`)
                }
                .margin({ top: 2 })

                Button('重新查询')
                  .fontSize(13)
                  .fontColor('#007AFF')
                  .height(42)
                  .width('100%')
                  .backgroundColor('#E8F1FF')
                  .borderRadius(21)
                  .margin({ top: 16 })
                  .onClick(() => {
                    this.resetForm();
                  })
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

      if (this.isLoggedIn && !this.showAi) {
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
