import { common } from '@kit.AbilityKit';
import { StudyTask } from '../models/Task';
import { TaskApi } from '../api/TaskApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { DateUtil } from '../utils/DateUtil';
import { ToastUtil } from '../utils/ToastUtil';

@Entry
@Component
struct TaskPage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private quotes: string[] = [
    '每完成一个任务，都是向目标迈进的一步',
    '今天的努力，是明天成功的基石',
    '行动是治愈拖延的良药',
    '专注当下，成就未来'
  ];
  @State tasks: StudyTask[] = [];
  @State newTaskTitle: string = '';
  @State selectedTask: StudyTask = new StudyTask();
  @State showDetail: boolean = false;
  @State quoteIndex: number = 0;

  aboutToAppear(): void {
    this.loadTasks();
  }

  private randomQuote(): string {
    return this.quotes[this.quoteIndex % this.quotes.length];
  }

  async loadTasks(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      this.tasks = await TaskApi.list(token, env);
      await CacheStore.setJson<StudyTask[]>(this.context, 'tasks', this.tasks);
    } catch (_) {
      this.tasks = await CacheStore.getJson<StudyTask[]>(this.context, 'tasks', []);
    }
  }

  async addNewTask(): Promise<void> {
    const title = this.newTaskTitle.trim();
    if (title.length === 0) {
      ToastUtil.show('请输入任务内容');
      return;
    }
    const task = new StudyTask(DateUtil.nowId('task'), title, title, DateUtil.todayText(), '待完成');
    this.tasks = [task].concat(this.tasks);
    this.newTaskTitle = '';
    this.quoteIndex = (this.quoteIndex + 1) % this.quotes.length;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await TaskApi.add(token, task, env);
      ToastUtil.show('添加成功');
    } catch (err) {
      ToastUtil.show(`添加失败：${(err as Error).message}`);
    }
    await CacheStore.setJson<StudyTask[]>(this.context, 'tasks', this.tasks);
  }

  showTask(task: StudyTask): void {
    this.selectedTask = task;
    this.showDetail = true;
  }

  async toggleTask(task: StudyTask): Promise<void> {
    const nextStatus = task.status === '已完成' ? '待完成' : '已完成';
    this.tasks = this.tasks.map((item: StudyTask) => {
      if (item.id === task.id) {
        item.status = nextStatus;
      }
      return item;
    });
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      if (nextStatus === '已完成') {
        await TaskApi.done(token, task.id, env);
        ToastUtil.show('任务已完成！');
      } else {
        await TaskApi.todo(token, task.id, env);
        ToastUtil.show('已标记为待完成');
      }
    } catch (err) {
      ToastUtil.show(`操作失败：${(err as Error).message}`);
    }
    await CacheStore.setJson<StudyTask[]>(this.context, 'tasks', this.tasks);
  }

  confirmDelete(task: StudyTask): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这个任务吗？',
      primaryButton: {
        value: '删除',
        action: () => {
          this.deleteTask(task.id);
        }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    });
  }

  async deleteTask(id: string): Promise<void> {
    this.tasks = this.tasks.filter((item: StudyTask) => item.id !== id);
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      await TaskApi.remove(token, id, env);
      ToastUtil.show('删除成功');
    } catch (err) {
      ToastUtil.show(`删除失败：${(err as Error).message}`);
    }
    await CacheStore.setJson<StudyTask[]>(this.context, 'tasks', this.tasks);
  }

  @Builder
  AddTaskBar() {
    Row() {
      TextInput({ placeholder: '输入新任务，回车即可添加', text: this.newTaskTitle })
        .height(48)
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .padding({ left: 18, right: 12 })
        .onChange((value: string) => {
          this.newTaskTitle = value;
        })
      Text('+')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .width(46)
        .height(46)
        .borderRadius(23)
        .backgroundColor('#007BFF')
        .margin({ left: 10 })
        .onClick(() => {
          this.addNewTask();
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20 })
  }

  @Builder
  Motivation() {
    Text(this.randomQuote())
      .fontSize(15)
      .fontColor('#7F8C8D')
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ left: 24, right: 24, top: 18, bottom: 18 })
  }

  @Builder
  TaskItem(task: StudyTask) {
    Row() {
      Row() {
        Text(task.status === '已完成' ? '✓' : '')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width(28)
          .height(28)
          .borderRadius(14)
          .backgroundColor(task.status === '已完成' ? '#28A745' : '#FFFFFF')
          .border({ width: 1, color: task.status === '已完成' ? '#28A745' : '#CED4DA' })
          .onClick(() => {
            this.toggleTask(task);
          })
        Text(task.title)
          .fontSize(16)
          .fontColor(task.status === '已完成' ? '#ADB5BD' : '#343A40')
          .decoration({ type: task.status === '已完成' ? TextDecorationType.LineThrough : TextDecorationType.None })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 14 })
      }
      .layoutWeight(1)
      .onClick(() => {
        this.showTask(task);
      })

      Text('×')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#DC3545')
        .textAlign(TextAlign.Center)
        .width(42)
        .height(42)
        .onClick(() => {
          this.confirmDelete(task);
        })
    }
    .width('calc(100% - 40vp)')
    .padding({ left: 16, right: 10, top: 16, bottom: 16 })
    .backgroundColor(task.status === '已完成' ? '#F8F9FA' : '#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 10, color: 0x12000000, offsetY: 4 })
    .margin({ left: 20, right: 20, bottom: 14 })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('🗒️')
        .fontSize(56)
      Text('还没有任务哦，快添加一个吧！')
        .fontSize(16)
        .fontColor('#7F8C8D')
        .margin({ top: 18 })
    }
    .width('100%')
    .padding({ top: 80 })
  }

  @Builder
  DetailModal() {
    if (this.showDetail) {
      Column() {
        Row() {
          Text('任务详情')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .layoutWeight(1)
          Text('×')
            .fontSize(28)
            .fontColor('#999999')
            .onClick(() => {
              this.showDetail = false;
            })
        }
        .width('100%')
        .padding({ bottom: 14 })
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })
        this.DetailRow('内容:', this.selectedTask.title)
        this.DetailRow('状态:', this.selectedTask.status)
        this.DetailRow('创建时间:', this.selectedTask.deadline.length > 0 ? this.selectedTask.deadline : '今天')
      }
      .alignItems(HorizontalAlign.Start)
      .width('84%')
      .padding(22)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .position({ x: '8%', y: '28%' })
      .zIndex(8)
    }
  }

  @Builder
  DetailRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#555555')
        .width(82)
      Text(value)
        .fontSize(15)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .alignItems(VerticalAlign.Top)
    .margin({ top: 18 })
  }

  build() {
    Stack() {
      Column() {
        this.AddTaskBar()
        this.Motivation()
        Scroll() {
          Column() {
            if (this.tasks.length === 0) {
              this.EmptyState()
            } else {
              ForEach(this.tasks, (task: StudyTask) => {
                this.TaskItem(task)
              }, (task: StudyTask) => task.id)
            }
          }
          .width('100%')
          .padding({ bottom: 24 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F6F8')
      if (this.showDetail) {
        Text('')
          .width('100%')
          .height('100%')
          .backgroundColor(0x66000000)
          .onClick(() => {
            this.showDetail = false;
          })
      }
      this.DetailModal()
    }
    .width('100%')
    .height('100%')
  }
}
