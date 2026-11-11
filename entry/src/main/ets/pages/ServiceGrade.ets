import { GradeRecord } from '../models/MiniProgramModels';
import { SchoolApi } from '../api/SchoolApi';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct ServiceGrade {
  @State studentNo: string = '';
  @State password: string = '';
  @State term: string = '20243';
  @State loading: boolean = false;
  @State queried: boolean = false;
  @State grades: GradeRecord[] = [];

  private totalCredits(): string {
    let total = 0;
    this.grades.forEach((grade: GradeRecord) => {
      const value = Number(grade.credit);
      if (value >= 0 || value < 0) {
        total += value;
      }
    });
    return total.toFixed(1);
  }

  private averageScore(): string {
    if (this.grades.length === 0) {
      return '0';
    }
    let total = 0;
    this.grades.forEach((grade: GradeRecord) => {
      const value = Number(grade.score);
      if (value >= 0 || value < 0) {
        total += value;
      }
    });
    return (total / this.grades.length).toFixed(1);
  }

  private averageGpa(): string {
    if (this.grades.length === 0) {
      return '0';
    }
    let total = 0;
    this.grades.forEach((grade: GradeRecord) => {
      const value = Number(grade.gpa);
      if (value >= 0 || value < 0) {
        total += value;
      }
    });
    return (total / this.grades.length).toFixed(2);
  }

  private scoreColor(score: string): string {
    const value = Number(score);
    if (value >= 90) {
      return '#34C759';
    }
    if (value >= 80) {
      return '#007AFF';
    }
    if (value >= 60) {
      return '#FF9500';
    }
    return '#FF3B30';
  }

  private scoreLabel(score: string): string {
    const value = Number(score);
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

  async queryGrades(): Promise<void> {
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
      this.grades = await SchoolApi.grades(this.studentNo.trim(), this.password.trim(), this.term.trim());
      this.queried = true;
      ToastUtil.show(this.grades.length > 0 ? `查询成功，共${this.grades.length}门课程` : '暂无成绩数据');
    } catch (err) {
      this.grades = MockData.grades();
      this.queried = true;
      ToastUtil.show(`成绩查询失败：${(err as Error).message}`);
    } finally {
      this.loading = false;
    }
  }

  @Builder
  HeaderSection() {
    Stack() {
      Column() {
        Row() {
          Text('🏅')
            .fontSize(32)
            .textAlign(TextAlign.Center)
            .width(58)
            .height(58)
            .borderRadius(29)
            .backgroundColor(0x22FFFFFF)
          Column() {
            Text('成绩查询')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('查看您的学习成果与学业表现')
              .fontSize(13)
              .fontColor(0xE6FFFFFF)
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 30, bottom: 30 })
    .backgroundColor('#007AFF')
    .borderRadius(24)
  }

  @Builder
  FormCard() {
    Column() {
      Row() {
        Text('👤')
          .fontSize(18)
          .textAlign(TextAlign.Center)
          .width(42)
          .height(42)
          .borderRadius(21)
          .backgroundColor('#007AFF')
        Column() {
          Text('教务系统登录')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('请输入您的学号和密码查询成绩')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')

      this.FieldInput('学号', '请输入学号', false)
      this.PasswordInput()
      this.TermInput()

      Button(this.loading ? '查询中...' : '查询成绩')
        .width('100%')
        .height(50)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(16)
        .margin({ top: 18 })
        .onClick(() => {
          this.queryGrades();
        })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(22)
    .backgroundColor('#FFFFFF')
    .borderRadius(24)
    .margin({ top: 16 })
  }

  @Builder
  FieldInput(label: string, placeholder: string, disabled: boolean) {
    Text(label)
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#333333')
      .margin({ top: 18, bottom: 8 })
    TextInput({ placeholder: placeholder, text: this.studentNo })
      .height(48)
      .enabled(!disabled)
      .backgroundColor('#F8F9FA')
      .borderRadius(16)
      .padding({ left: 14, right: 14 })
      .onChange((value: string) => {
        this.studentNo = value;
      })
  }

  @Builder
  PasswordInput() {
    Text('密码')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#333333')
      .margin({ top: 18, bottom: 8 })
    TextInput({ placeholder: '请输入教务系统密码', text: this.password })
      .height(48)
      .type(InputType.Password)
      .backgroundColor('#F8F9FA')
      .borderRadius(16)
      .padding({ left: 14, right: 14 })
      .onChange((value: string) => {
        this.password = value;
      })
  }

  @Builder
  TermInput() {
    Text('学期')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor('#333333')
      .margin({ top: 18, bottom: 8 })
    TextInput({ placeholder: '例如 20243', text: this.term })
      .height(48)
      .backgroundColor('#F8F9FA')
      .borderRadius(16)
      .padding({ left: 14, right: 14 })
      .onChange((value: string) => {
        this.term = value;
      })
  }

  @Builder
  StatsCard() {
    Column() {
      Row() {
        Text('成绩单')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
        Text(this.term)
          .fontSize(12)
          .fontColor('#007AFF')
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .backgroundColor('#E8F4FF')
          .borderRadius(12)
      }
      .width('100%')
      Row() {
        this.StatItem('📚', `${this.grades.length}`, '总课程数')
        this.StatItem('🎓', this.totalCredits(), '总学分')
        this.StatItem('📊', this.averageScore(), '平均分')
        this.StatItem('⭐', this.averageGpa(), '平均绩点')
      }
      .width('100%')
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 16 })
  }

  @Builder
  StatItem(icon: string, value: string, label: string) {
    Column() {
      Text(icon)
        .fontSize(22)
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 6 })
      Text(label)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  GradeCard(grade: GradeRecord) {
    Column() {
      Row() {
        Column() {
          Text(grade.course.length > 0 ? grade.course : '未知课程')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(grade.courseCode.length > 0 ? grade.courseCode : '无代码')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#45B7D1')
              .borderRadius(8)
            Text(grade.category.length > 0 ? grade.category : '其他')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor('#98D8C8')
              .borderRadius(8)
              .margin({ left: 6 })
          }
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column() {
          Text(grade.score.length > 0 ? grade.score : '0')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.scoreColor(grade.score))
          Text(this.scoreLabel(grade.score))
            .fontSize(11)
            .fontColor(this.scoreColor(grade.score))
        }
        .width(62)
        .height(62)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F8F9FA')
        .borderRadius(16)
      }
      .width('100%')
      Row() {
        this.MetaItem('学分', grade.credit.length > 0 ? grade.credit : '0')
        this.MetaItem('绩点', grade.gpa.length > 0 ? grade.gpa : '0')
        this.MetaItem('类型', grade.type.length > 0 ? grade.type : '未知')
      }
      .width('100%')
      .margin({ top: 14 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .margin({ top: 12 })
  }

  @Builder
  MetaItem(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor('#999999')
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 4 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.HeaderSection()
          if (!this.queried) {
            this.FormCard()
          } else if (this.grades.length > 0) {
            this.StatsCard()
            ForEach(this.grades, (grade: GradeRecord) => {
              this.GradeCard(grade)
            }, (grade: GradeRecord) => grade.id)
          } else {
            Column() {
              Text('ℹ️')
                .fontSize(46)
              Text('暂无成绩数据')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ top: 12 })
              Text('请检查学期选择或稍后重试')
                .fontSize(13)
                .fontColor('#999999')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(30)
            .backgroundColor('#FFFFFF')
            .borderRadius(20)
            .margin({ top: 16 })
          }
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FF')
  }
}
