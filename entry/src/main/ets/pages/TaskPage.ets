import { common } from '@kit.AbilityKit';
import { StudyTask } from '../models/Task';
import { TaskApi } from '../api/TaskApi';
import { AuthStore } from '../stores/AuthStore';
import { CacheStore } from '../stores/CacheStore';
import { DateUtil } from '../utils/DateUtil';
import { MockData } from '../utils/MockData';
import { ToastUtil } from '../utils/ToastUtil';

import { PageHeader } from '../components/common/PageHeader';

@Entry
@Component
struct TaskPage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private quotes: string[] = [
    '每完成一个任务，都是向目标迈进的一步 💪',
    '今天的努力，是明天成功的基石 ✨',
    '坚持不懈，成功就在前方 🌟',
    '每一个小目标的达成，都值得庆祝 🎉',
    '行动是治愈恐惧的良药 🚀',
    '专注当下，成就未来 🎯',
    '进步不在于速度，而在于方向 🧭',
    '今天比昨天更好一点点 📈',
    '相信自己，你比想象中更强大 💎',
    '每一次努力都不会白费 🌱',
    '成功源于日复一日的坚持 ⭐',
    '梦想不会逃跑，逃跑的永远是自己 🏃‍♂️',
    '优秀是一种习惯，坚持是一种品格 🏆',
    '今天的汗水，是明天的收获 🌾',
    '做最好的自己，成就最美的人生 🌈'
  ];
  @State tasks: StudyTask[] = [];
  @State newTaskTitle: string = '';
  @State selectedTask: StudyTask = new StudyTask();
  @State showDetail: boolean = false;
  @State quoteIndex: number = 0;
  @State activeFilter: string = '全部';
  @State editing: boolean = false;
  @State editTitle: string = '';
  @State saving: boolean = false;

  aboutToAppear(): void {
    this.quoteIndex = Math.floor(Math.random() * this.quotes.length);
    this.loadTasks();
  }

  private currentQuote(): string {
    return this.quotes[this.quoteIndex % this.quotes.length];
  }

  private nextQuote(): void {
    this.quoteIndex = Math.floor(Math.random() * this.quotes.length);
  }

  async loadTasks(): Promise<void> {
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      this.tasks = await TaskApi.list(token, env);
      await CacheStore.setJson<StudyTask[]>(this.context, 'tasks', this.tasks);
    } catch (_) {
      // 接口失败降级：优先本地缓存，其次演示数据，不白屏。
      const cached = await CacheStore.getJson<StudyTask[]>(this.context, 'tasks', []);
      this.tasks = cached.length > 0 ? cached : MockData.tasks();
      ToastUtil.demoData();
    }
  }

  private persist(): void {
    CacheStore.setJson<StudyTask[]>(this.context, 'tasks', this.tasks);
  }

  private visibleTasks(): StudyTask[] {
    if (this.activeFilter === '待完成') {
      return this.tasks.filter((item: StudyTask) => item.status !== '已完成');
    }
    if (this.activeFilter === '已完成') {
      return this.tasks.filter((item: StudyTask) => item.status === '已完成');
    }
    return this.tasks;
  }

  private todoCount(): number {
    return this.tasks.filter((item: StudyTask) => item.status !== '已完成').length;
  }

  private doneCount(): number {
    return this.tasks.filter((item: StudyTask) => item.status === '已完成').length;
  }

  async addNewTask(): Promise<void> {
    const title = this.newTaskTitle.trim();
    if (title.length === 0) {
      ToastUtil.show('请输入任务内容');
      return;
    }
    if (title.length > 50) {
      ToastUtil.show('任务内容不能超过50个字');
      return;
    }
    const nowText = new Date().toLocaleString();
    let task = new StudyTask(DateUtil.nowId('task'), title, title, DateUtil.todayText(), '待完成', nowText);
    this.newTaskTitle = '';
    this.nextQuote();
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    try {
      const remoteId = await TaskApi.add(token, task, env);
      if (remoteId.length > 0) {
        task = new StudyTask(remoteId, title, title, DateUtil.todayText(), '待完成', nowText);
      }
      this.tasks = [task].concat(this.tasks);
      ToastUtil.show('添加成功');
    } catch (_) {
      // 失败降级：保留本地任务，明确提示未同步。
      this.tasks = [task].concat(this.tasks);
      ToastUtil.show('添加失败，已保存到本地');
    }
    this.persist();
  }

  showTask(task: StudyTask): void {
    this.selectedTask = task;
    this.editing = false;
    this.editTitle = task.title;
    this.showDetail = true;
  }

  closeDetail(): void {
    this.showDetail = false;
    this.editing = false;
  }

  async toggleTask(task: StudyTask): Promise<void> {
    const nextStatus = task.status === '已完成' ? '待完成' : '已完成';
    const updated = new StudyTask(task.id, task.title, task.description, task.deadline, nextStatus, task.createTime);
    this.tasks = this.tasks.map((item: StudyTask) => item.id === task.id ? updated : item);
    if (this.showDetail && this.selectedTask.id === task.id) {
      this.selectedTask = updated;
    }
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
    } catch (_) {
      ToastUtil.show('操作失败，已在本地更新');
    }
    this.persist();
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
        action: () => {
        }
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
    } catch (_) {
      ToastUtil.show('删除失败，已在本地移除');
    }
    this.persist();
  }

  startEdit(): void {
    this.editTitle = this.selectedTask.title;
    this.editing = true;
  }

  cancelEdit(): void {
    this.editing = false;
  }

  /**
   * 后端没有任务更新接口，按参考实现已有的 add/delete 组合实现编辑：
   * 新建同状态任务后删除旧任务；网络失败时仅更新本地并明确提示。
   */
  async saveEdit(): Promise<void> {
    const title = this.editTitle.trim();
    if (title.length === 0) {
      ToastUtil.show('请输入任务内容');
      return;
    }
    if (title.length > 50) {
      ToastUtil.show('任务内容不能超过50个字');
      return;
    }
    if (title === this.selectedTask.title) {
      this.editing = false;
      return;
    }
    if (this.saving) {
      return;
    }
    this.saving = true;
    const old = this.selectedTask;
    const token = await AuthStore.getToken(this.context);
    const env = await AuthStore.getApiEnvironment(this.context);
    let remoteId = '';
    try {
      remoteId = await TaskApi.add(token,
        new StudyTask('', title, title, old.deadline, old.status, old.createTime), env);
    } catch (_) {
      remoteId = '';
    }
    if (remoteId.length === 0) {
      // 新增失败：只更新本地，明确提示未同步。
      const localUpdated = new StudyTask(old.id, title, title, old.deadline, old.status, old.createTime);
      this.tasks = this.tasks.map((item: StudyTask) => item.id === old.id ? localUpdated : item);
      this.selectedTask = localUpdated;
      ToastUtil.show('网络异常，已保存到本地');
    } else {
      // 新增成功：同步完成态并清理旧任务；清理失败不覆盖本地新任务。
      let synced = true;
      try {
        if (old.status === '已完成') {
          await TaskApi.done(token, remoteId, env);
        }
        await TaskApi.remove(token, old.id, env);
      } catch (_) {
        synced = false;
      }
      const updated = new StudyTask(remoteId, title, title, old.deadline, old.status, old.createTime);
      this.tasks = this.tasks.map((item: StudyTask) => item.id === old.id ? updated : item);
      this.selectedTask = updated;
      ToastUtil.show(synced ? '任务已更新' : '任务已更新，旧任务未同步删除');
    }
    this.persist();
    this.saving = false;
    this.editing = false;
  }

  @Builder
  AddTaskBar() {
    Row() {
      TextInput({ placeholder: '输入新任务，回车即可添加', text: this.newTaskTitle })
        .height(48)
        .layoutWeight(1)
        .maxLength(50)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .padding({ left: 18, right: 12 })
        .enterKeyType(EnterKeyType.Done)
        .onChange((value: string) => {
          this.newTaskTitle = value;
        })
        .onSubmit(() => {
          this.addNewTask();
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
    Text(this.currentQuote())
      .fontSize(15)
      .fontColor('#7F8C8D')
      .textAlign(TextAlign.Center)
      .width('100%')
      .padding({ left: 24, right: 24, top: 18, bottom: 10 })
  }

  @Builder
  FilterBar() {
    Row() {
      this.FilterChip('全部', this.tasks.length)
      this.FilterChip('待完成', this.todoCount())
      this.FilterChip('已完成', this.doneCount())
    }
    .width('100%')
    .padding({ left: 20, right: 20, bottom: 12 })
  }

  @Builder
  FilterChip(label: string, count: number) {
    Text(`${label} ${count}`)
      .fontSize(13)
      .fontWeight(this.activeFilter === label ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.activeFilter === label ? '#FFFFFF' : '#5F6B7A')
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(15)
      .backgroundColor(this.activeFilter === label ? '#409EFF' : '#FFFFFF')
      .margin({ right: 8 })
      .onClick(() => {
        this.activeFilter = label;
      })
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
      Text(this.tasks.length === 0 ? '还没有任务哦，快添加一个吧！' : '没有符合条件的任务')
        .fontSize(16)
        .fontColor('#7F8C8D')
        .margin({ top: 18 })
    }
    .width('100%')
    .padding({ top: 80 })
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
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.closeDetail();
            })
        }
        .width('100%')
        .padding({ bottom: 14 })
        .border({ width: { bottom: 1 }, color: '#F0F0F0' })

        if (this.editing) {
          Text('内容:')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#555555')
            .width('100%')
            .margin({ top: 18 })
          TextInput({ text: this.editTitle, placeholder: '请输入任务内容' })
            .height(46)
            .maxLength(50)
            .backgroundColor('#F4F6F8')
            .borderRadius(10)
            .padding({ left: 12, right: 12 })
            .margin({ top: 8 })
            .onChange((value: string) => {
              this.editTitle = value;
            })
        } else {
          this.DetailRow('内容:', this.selectedTask.title)
        }
        this.DetailRow('状态:', this.selectedTask.status)
        this.DetailRow('创建时间:', this.selectedTask.createTime.length > 0
          ? this.selectedTask.createTime
          : (this.selectedTask.deadline.length > 0 ? this.selectedTask.deadline : '今天'))

        Row() {
          if (this.editing) {
            Button('取消')
              .layoutWeight(1)
              .height(42)
              .fontSize(15)
              .fontColor('#555555')
              .backgroundColor('#F0F2F5')
              .borderRadius(21)
              .onClick(() => {
                this.cancelEdit();
              })
            Button(this.saving ? '保存中...' : '保存')
              .layoutWeight(1)
              .height(42)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#409EFF')
              .borderRadius(21)
              .margin({ left: 10 })
              .enabled(!this.saving)
              .onClick(() => {
                this.saveEdit();
              })
          } else {
            Button('编辑任务')
              .width('100%')
              .height(42)
              .fontSize(15)
              .fontColor('#FFFFFF')
              .backgroundColor('#409EFF')
              .borderRadius(21)
              .onClick(() => {
                this.startEdit();
              })
          }
        }
        .width('100%')
        .margin({ top: 24 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('84%')
      .padding(22)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 8 })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        PageHeader({ title: '任务' })
        this.AddTaskBar()
        this.Motivation()
        this.FilterBar()
        Scroll() {
          Column() {
            if (this.visibleTasks().length === 0) {
              this.EmptyState()
            } else {
              ForEach(this.visibleTasks(), (task: StudyTask) => {
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
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.4)')
          .onClick(() => {
            this.closeDetail();
          })
        this.DetailModal()
      }
    }
    .width('100%')
    .height('100%')
  }
}
