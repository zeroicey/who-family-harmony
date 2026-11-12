import { ChatMessage, PresetQuestion } from '../models/MiniProgramModels';

export class ChatMock {
  static presetQuestions(): PresetQuestion[] {
    return [
      new PresetQuestion('q-1', '💙 如何克服想家情绪？', '刚上大学总是想家，晚上经常想哭，怎么调节这种情绪？有什么好的方法适应大学生活吗？'),
      new PresetQuestion('q-2', '🤝 怎样和室友友好相处？', '和室友生活习惯不同，有时会有小摩擦，怎么处理室友关系？如何建立良好的宿舍氛围？'),
      new PresetQuestion('q-3', '😔 不想上学怎么办？', '最近对学习失去兴趣，不想去上课，感觉很迷茫，这种状态该如何调整？'),
      new PresetQuestion('q-4', '👥 如何交到真心朋友？', '在大学里感觉很孤单，不知道怎么交朋友，怎样才能找到志同道合的人？'),
      new PresetQuestion('q-5', '📱 如何控制手机依赖？', '总是忍不住刷手机，影响学习和睡眠，怎么戒掉手机瘾，提高自控力？'),
      new PresetQuestion('q-6', '⚖️ 怎样平衡学习和社交？', '想要好好学习，但也想参加社团活动交朋友，如何在学业和社交之间找到平衡？')
    ];
  }
  static initialMessages(): ChatMessage[] {
    return [
      new ChatMessage('ai-welcome', 'ai', '👋 你好！我是校园AI助手，很高兴为你服务！\n\n我可以帮助你解决各种校园生活问题，比如：\n\n• 📚 学习相关问题\n\n• 🏫 校园生活指导\n\n• 📋 各类手续办理\n\n• 🎯 社团活动咨询\n\n• 💡 生活小贴士\n\n有什么问题尽管问我吧～')
    ];
  }
}
