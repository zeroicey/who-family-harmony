import { Banner } from '../models/Banner';
import { StudyTask } from '../models/Task';
import { Job, JobType } from '../models/Job';
import { CommunityPost, PostType } from '../models/CommunityPost';
import { MemberWork } from '../models/UserProfile';
import {
  AddressItem,
  ChatMessage,
  GradeRecord,
  KnowledgeArticle,
  PresetQuestion,
  PrintOrder,
  PrintPrice,
  SchoolCourse
} from '../models/MiniProgramModels';
import {
  AgreementSection,
  CampusNotification,
  CampusPlace,
  ErrandTask,
  HomeService,
  ServiceItem
} from '../models/MockModels';
import { HomeMock } from '../mock/HomeMock';
import { CommunityMock } from '../mock/CommunityMock';
import { JobMock } from '../mock/JobMock';
import { TaskMock } from '../mock/TaskMock';
import { ServiceMock } from '../mock/ServiceMock';
import { ChatMock } from '../mock/ChatMock';
import { KnowledgeMock } from '../mock/KnowledgeMock';

export { AgreementSection, CampusNotification, CampusPlace, ErrandTask, HomeService, ServiceItem };

/**
 * Mock 数据门面：数据已按域拆分到 ets/mock/。
 * 保留原有方法名，页面引用无需改动；新代码可直接从对应 domain mock 导入。
 */
export class MockData {
  static banners(): Banner[] {
    return HomeMock.banners();
  }

  static services(): ServiceItem[] {
    return HomeMock.services();
  }

  static homeServices(): HomeService[] {
    return HomeMock.homeServices();
  }

  static campusNotifications(): CampusNotification[] {
    return HomeMock.campusNotifications();
  }

  static places(): CampusPlace[] {
    return HomeMock.places();
  }

  static tasks(): StudyTask[] {
    return TaskMock.tasks();
  }

  static jobTypes(): JobType[] {
    return JobMock.jobTypes();
  }

  static jobs(): Job[] {
    return JobMock.jobs();
  }

  static postTypes(): PostType[] {
    return CommunityMock.postTypes();
  }

  static posts(): CommunityPost[] {
    return CommunityMock.posts();
  }

  static errandTasks(): ErrandTask[] {
    return CommunityMock.errandTasks();
  }

  static knowledgeTabs(): string[] {
    return KnowledgeMock.knowledgeTabs();
  }

  static knowledgeArticles(): KnowledgeArticle[] {
    return KnowledgeMock.knowledgeArticles();
  }

  static presetQuestions(): PresetQuestion[] {
    return ChatMock.presetQuestions();
  }

  static initialMessages(): ChatMessage[] {
    return ChatMock.initialMessages();
  }

  static addresses(): AddressItem[] {
    return ServiceMock.addresses();
  }

  static printPrices(): PrintPrice[] {
    return ServiceMock.printPrices();
  }

  static printOrders(): PrintOrder[] {
    return ServiceMock.printOrders();
  }

  static courses(): SchoolCourse[] {
    return TaskMock.courses();
  }

  static grades(): GradeRecord[] {
    return TaskMock.grades();
  }

  static members(): MemberWork[] {
    return TaskMock.members();
  }
}