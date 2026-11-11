import { SchoolCourse } from '../models/MiniProgramModels';
import { SchoolApi } from '../api/SchoolApi';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';
@Entry
@Component
struct ServiceSchedule {
  private readonly terms: string[] = ['20252', '20251', '20243', '20242', '20241', '20233', '20232', '20231', '20223', '20222', '20221'];
  private readonly weekDays: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  private readonly periods: string[] = ['1-2节', '3-4节', '5-6节', '7-8节', '9-10节', '11-12节'];
  @State studentNo: string = '';
  @State password: string = '';
  @State term: string = '20252';
  @State currentWeek: number = 1;
  @State loading: boolean = false;
  @State queried: boolean = false;
  @State courses: SchoolCourse[] = [];
  @State selectedCourse: SchoolCourse = new SchoolCourse();
  @State showDetail: boolean = false;

  private weekText(): string {
    return `${this.currentWeek}`;
  }

  private courseFor(day: string, period: string): string {
    for (let index = 0; index < this.courses.length; index++) {
      const course = this.courses[index];
      if (course.day === day && course.section === period) {
        return `${course.name}\n${course.location}`;
      }
    }
    return '';
  }

  private courseColor(day: string, period: string): string {
    const text = this.courseFor(day, period);
    if (text.length === 0) {
      return '#FFFFFF';
    }
    const palette: string[] = ['#E8F4FD', '#F3E8FD', '#E8FDF0', '#FDF6E8', '#FDE8F0', '#E8FDF8'];
    const seed = day.length + period.length + text.length;
    return palette[seed % palette.length];
  }

  private pickCourse(day: string, period: string): void {
    for (let index = 0; index < this.courses.length; index++) {
      const course = this.courses[index];
      if (course.day === day && course.section === period) {
        this.selectedCourse = course;
        this.showDetail = true;
        return;
      }
    }
  }

  private changeWeek(delta: number): void {
    const nextWeek = this.currentWeek + delta;
    if (nextWeek < 1 || nextWeek > 17) {
      return;
    }
    this.currentWeek = nextWeek;
    if (this.queried) {
      this.querySchedule();
    }
  }

  async querySchedule(): Promise<void> {
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
      this.courses = await SchoolApi.schedule(this.studentNo.trim(), this.password.trim(), this.term.trim(), `${this.currentWeek}`);
      this.queried = true;
      ToastUtil.show(this.courses.length > 0 ? `第${this.currentWeek}周课表加载成功` : `第${this.currentWeek}周暂无课程`);
    } catch (err) {
      this.courses = MockData.courses();
      this.queried = true;
      ToastUtil.show(`课表查询失败：${(err as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  @Builder
  HeaderSection() {
    Column() {
      Row() {
        Text('📅')
          .fontSize(28)
          .textAlign(TextAlign.Center)
          .width(56)
          .height(56)
          .borderRadius(16)
          .backgroundColor(0x22FFFFFF)
        Column() {
          Text('课程表')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('查看您的课程安排')
            .fontSize(13)
            .fontColor(0xDDFFFFFF)
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 16 })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 26, bottom: 26 })
    .backgroundColor('#007AFF')
    .borderRadius(24)
  }

  @Builder
  FormCard() {
    Column() {
      Row() {
        Text('')
          .width(4)
          .height(38)
          .borderRadius(2)
          .backgroundColor('#007AFF')
        Column() {
          Text('教务系统登录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
          Text('ACADEMIC SYSTEM')
            .fontSize(11)
            .fontColor('#8E8E93')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')

      this.FieldLabel('👤', '学号')
      TextInput({ placeholder: '请输入学号', text: this.studentNo })
        .height(48)
        .backgroundColor('#F8F9FA')
        .borderRadius(14)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.studentNo = value;
        })

      this.FieldLabel('🔒', '密码')
      TextInput({ placeholder: '请输入教务系统密码', text: this.password })
        .height(48)
        .type(InputType.Password)
        .backgroundColor('#F8F9FA')
        .borderRadius(14)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => {
          this.password = value;
        })

      Row() {
        Column() {
          this.FieldLabel('📆', '学期')
          TextInput({ placeholder: '学期', text: this.term })
            .height(48)
            .backgroundColor('#F8F9FA')
            .borderRadius(14)
            .padding({ left: 14, right: 14 })
            .onChange((value: string) => {
              this.term = value;
            })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column() {
          this.FieldLabel('📚', '周次')
          Row() {
            Text(`第${this.currentWeek}周`)
              .fontSize(15)
              .fontColor('#1C1C1E')
              .layoutWeight(1)
            Text('›')
              .fontSize(20)
              .fontColor('#C7C7CC')
          }
          .height(48)
          .padding({ left: 14, right: 12 })
          .backgroundColor('#F8F9FA')
          .borderRadius(14)
        }
        .alignItems(HorizontalAlign.Start)
        .width(120)
        .margin({ left: 10 })
      }
      .width('100%')

      Button(this.loading ? '查询中...' : '查询课表')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(14)
        .margin({ top: 20 })
        .onClick(() => {
          this.querySchedule();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .margin({ top: 16 })
  }

  @Builder
  FieldLabel(icon: string, label: string) {
    Row() {
      Text(icon)
        .fontSize(14)
      Text(label)
        .fontSize(14)
        .fontColor('#1C1C1E')
        .fontWeight(FontWeight.Medium)
        .margin({ left: 6 })
    }
    .margin({ top: 18, bottom: 8 })
  }

  @Builder
  WeekSelector() {
    Row() {
      Text('‹')
        .fontSize(24)
        .fontColor(this.currentWeek <= 1 ? '#C7C7CC' : '#007AFF')
        .textAlign(TextAlign.Center)
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          this.changeWeek(-1);
        })
      Text(`第 ${this.weekText()} 周`)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1C1E')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('›')
        .fontSize(24)
        .fontColor(this.currentWeek >= 17 ? '#C7C7CC' : '#007AFF')
        .textAlign(TextAlign.Center)
        .width(42)
        .height(42)
        .borderRadius(21)
        .backgroundColor('#FFFFFF')
        .onClick(() => {
          this.changeWeek(1);
        })
      Text('刷新')
        .fontSize(13)
        .fontColor('#5AC8FA')
        .margin({ left: 12 })
        .onClick(() => {
          this.querySchedule();
        })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#EDF6FF')
    .borderRadius(18)
    .margin({ top: 16 })
  }

  @Builder
  ScheduleGrid() {
    Column() {
      Row() {
        Text('时间')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#6B7280')
          .textAlign(TextAlign.Center)
          .width(54)
        ForEach(this.weekDays, (day: string) => {
          Text(day)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
        }, (day: string) => day)
      }
      .height(38)
      .backgroundColor('#F8FBFF')
      .borderRadius(12)

      ForEach(this.periods, (period: string) => {
        Row() {
          Text(period)
            .fontSize(11)
            .fontColor('#8E8E93')
            .textAlign(TextAlign.Center)
            .width(54)
          ForEach(this.weekDays, (day: string) => {
            Text(this.courseFor(day, period).length > 0 ? this.courseFor(day, period) : ' ')
              .fontSize(10)
              .fontColor('#1C1C1E')
              .lineHeight(14)
              .textAlign(TextAlign.Center)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .height(64)
              .padding(4)
              .backgroundColor(this.courseColor(day, period))
              .borderRadius(8)
              .margin({ left: 4 })
              .onClick(() => {
                this.pickCourse(day, period);
              })
          }, (day: string) => `${day}-${period}`)
        }
        .width('100%')
        .margin({ top: 6 })
      }, (period: string) => period)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 14 })
  }

  @Builder
  CourseDetail() {
    if (this.showDetail) {
      Column() {
        Row() {
          Text(this.selectedCourse.name.length > 0 ? this.selectedCourse.name : '课程详情')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1C1E')
            .layoutWeight(1)
          Text('×')
            .fontSize(22)
            .fontColor('#8E8E93')
            .onClick(() => {
              this.showDetail = false;
            })
        }
        .width('100%')
        this.DetailRow('教室', this.selectedCourse.location.length > 0 ? this.selectedCourse.location : '未安排')
        this.DetailRow('教师', this.selectedCourse.teacher.length > 0 ? this.selectedCourse.teacher : '未安排')
        this.DetailRow('时间', `${this.selectedCourse.day} 第${this.selectedCourse.section}`)
        this.DetailRow('班级', this.selectedCourse.className.length > 0 ? this.selectedCourse.className : '未安排')
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(18)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .margin({ top: 14, bottom: 20 })
    }
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#8E8E93')
        .width(58)
      Text(value)
        .fontSize(14)
        .fontColor('#1C1C1E')
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 12 })
  }

  build() {
    Column() {
      PageHeader({ title: '课表查询' })
      Scroll() {
        Column() {
          this.HeaderSection()
          if (!this.queried) {
            this.FormCard()
          } else {
            this.WeekSelector()
            if (this.courses.length > 0) {
              this.ScheduleGrid()
              this.CourseDetail()
            } else {
              Column() {
                Text('📚')
                  .fontSize(44)
                Text('暂无课程数据')
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1C1C1E')
                  .margin({ top: 10 })
                Text('请检查周次选择或稍后重试')
                  .fontSize(13)
                  .fontColor('#8E8E93')
                  .margin({ top: 6 })
              }
              .width('100%')
              .padding(28)
              .backgroundColor('#FFFFFF')
              .borderRadius(20)
              .margin({ top: 14 })
            }
          }
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F6FA')
  }
}
