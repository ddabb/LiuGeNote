#!/usr/bin/env node
/**
 * 内容导入脚本（配套 docs/content-import-manifest.md，Gate 1 已批准）
 *
 * 职责：
 *   来源A F:/SelfJob/PortableKnowledge/source 与 来源B F:/SelfJob/vercel-ci/mdfiles
 *   按批次映射加工后写入 content/mdfiles/<分类>/：
 *     - front-matter 规范化：统一 title/tags/description 三字段 + 闭合 ---
 *       （A 部分文件缺闭合 ---，publish.js 的正则要求闭合，必须补齐）
 *     - 剥离原 category/date 字段（分类由目标目录决定）
 *     - 清洗 LaTeX（$\color{red}{x}$ → x、\textbf{x} → **x**）
 *     - 正文无 H1 时补 "# 标题"；H1 粗体规范为纯文本
 *     - 标题含 2024~2029 年份的篇目文首加时效标注
 *     - 文件名去空格/非法字符（slug 风格对齐现有内容）
 *     - slug 撞车检测（与 content/mdfiles 既有文件 + 本批内）
 *     - exclude 规则：*.md 结尾按相对路径精确匹配，否则按目录段匹配
 *
 * 用法：node scripts/import-content.js --batch b1|b2|b3|b4|b5|b6|all [--dry-run]
 */
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const CONTENT_DIR = path.join(ROOT, 'content', 'mdfiles');
const SRC_A = 'F:/SelfJob/PortableKnowledge/source';
const SRC_B = 'F:/SelfJob/vercel-ci/mdfiles';

const TIMELINESS_NOTE = '> 内容整理时间：2026-11，文中涉及的年份、数据与生态状态请以最新官方资料为准。';
const DESC_MAX = 120;

/* ------------------------------ 参数 ------------------------------ */
function parseArgs(argv) {
  const args = { batch: null, dryRun: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--batch') args.batch = argv[++i];
    else if (a === '--dry-run') args.dryRun = true;
    else if (a === '--help' || a === '-h') {
      console.log('用法: node scripts/import-content.js --batch b1|b2|b3|b4|b5|b6|all [--dry-run]');
      process.exit(0);
    } else {
      console.error(`未知参数: ${a}`);
      process.exit(1);
    }
  }
  if (!args.batch) {
    console.error('缺少 --batch，可选: b1 b2 b3 b4 b5 b6 all');
    process.exit(1);
  }
  return args;
}

/* ------------------------------ 批次映射 ------------------------------ */
/** A 目录映射：src 相对 SRC_A；recursive 递归子目录；subdirTag 补子目录名进 tags；exclude 排除 */
function A(src, dest, opts = {}) {
  return { type: 'dir', src: SRC_A + '/' + src, dest, ...opts };
}
/** A 单文件映射；opts.rename 为字符串时重命名目标（slug 与标题） */
function AFile(srcRel, dest, opts = {}) {
  return { type: 'file', src: path.join(SRC_A, ...srcRel.split('/')), dest, ...opts };
}
/** B 单文件映射 */
function B(fileName, dest) {
  return { type: 'bfile', src: path.join(SRC_B, fileName), dest };
}

const BATCHES = {
  /* B1 技术拓展组 96 篇 */
  b1: [
    A('技术/Node.js后端开发', '后端与API开发'),
    A('技术/系统编程', '系统编程与底层原理'),
    A('技术/云原生', '云原生与DevOps'),
    A('技术/分布式系统', '分布式系统'),
    A('技术/服务端架构', '服务端架构实践'),
    A('商业/零售电商系统', '服务端架构实践', { recursive: true }),
    A('技术/数据库内核', '数据库内核与存储'),
    A('技术/AI推理加速', 'AI推理与高性能计算'),
    A('技术/高性能计算', 'AI推理与高性能计算'),
    A('技术/金融信贷科技', '金融科技架构', { recursive: true }),
  ],
  /* B2 项目管理知识体系 228 + 软考综合与备考 136 */
  b2: [
    A('考试/软考/项目管理', '项目管理知识体系', { recursive: true, subdirTag: true }),
    A('考试/软考/综合知识', '软考综合与备考', { recursive: true, subdirTag: true }),
    AFile('考试/软考/软考图表速查.md', '软考综合与备考'),
    B('李白的项目管理思维：漫游与创作生涯的规划.md', '项目管理知识体系'),
    B('顶级魔术师的表演设计：范围管理与时间管理的艺术.md', '项目管理知识体系'),
    B('侦探破案思维与项目问题排查：通用根因分析RCA剧本建立.md', '项目管理知识体系'),
    B('魔兽世界副本团长团队管理：如何管理500人线上社群.md', '项目管理知识体系'),
    B('网红减肥训练营运营模式分析：项目管理三角的应用与用户依赖形成.md', '项目管理知识体系'),
    B('做自己人生的CEO：去公司化的人生项目管理.md', '项目管理知识体系'),
    B('项目管理式人生：在规划与随性之间找到平衡.md', '项目管理知识体系'),
    B('过度依赖项目管理规划人生：如何为随机性预留空间.md', '项目管理知识体系'),
    B('敏捷项目管理：灵活应对变化的高效方法.md', '项目管理知识体系'),
    B('混合项目管理：结合传统与敏捷的最佳实践.md', '项目管理知识体系'),
    B('宇宙热寂视角下的项目风险重估：什么是值得管理的真风险.md', '项目管理知识体系'),
    B('国际化项目管理：跨文化协作与全球成功的实践指南.md', '项目管理知识体系'),
  ],
  /* B3 学习与考试组 190 篇 */
  b3: [
    A('考试/数据分析师', '数据分析', { recursive: true, subdirTag: true, exclude: ['SQL多表连接.md'], rename: { 'Python数据分析/数据可视化基础.md': 'Python数据可视化基础' } }),
    A('考试/教师资格证', '教师资格考试', { recursive: true, subdirTag: true, rename: { '核心考点.md': '教师资格证核心考点' } }),
    A('考试/英语考试', '英语学习', { recursive: true, subdirTag: true }),
    A('考试/中级经济师', '经济学基础与经济师', { recursive: true, subdirTag: true, rename: { '核心考点.md': '经济师核心考点' } }),
    A('考试/注册会计师/经济法', '财税与经济法常识'),
    A('考试/注册会计师/税法', '财税与经济法常识'),
    AFile('考试/注册会计师/核心考点.md', '财税与经济法常识', { rename: '注册会计师核心考点' }),
    A('考试/公务员', '公务员与考研', { recursive: true, subdirTag: true, rename: { '核心考点.md': '公务员核心考点' } }),
    A('考试/考研专业课', '公务员与考研'),
  ],
  /* B4 心理与健康组 74 篇 */
  b4: [
    A('健康/心理学', '心理学知识', { recursive: true, subdirTag: true }),
    A('健康/心理咨询师', '心理学知识', { recursive: true, subdirTag: true, exclude: ['心理障碍'] }),
    A('健康/营养师', '营养与健康生活', { exclude: ['疾病营养.md'] }),
    A('通用/生活通识/健康养生', '营养与健康生活', {
      exclude: ['糖尿病管理.md', '癌症预防指南.md', '心脑血管疾病预防.md'],
    }),
    B('踢猫效应：情绪传递背后的心理真相.md', '心理学知识'),
    B('社交焦虑的「正向转化」：将紧张转化为人际吸引力.md', '心理学知识'),
    B('正念冥想与心理健康：从压力到平静的转变.md', '心理学知识'),
    B('不确定性的心理学：如何在不确定世界中保持掌控感.md', '心理学知识'),
    B('心理韧性培养：从逆境到成长.md', '心理学知识'),
    B('如何应对现代生活中的焦虑和压力.md', '心理学知识'),
    B('睡眠革命2026：基于最新研究的R90睡眠周期法实践指南.md', '营养与健康生活'),
    B('睡眠健康的科学：从睡眠周期到优质睡眠.md', '营养与健康生活'),
    B('「微运动」的健康价值：如何在忙碌中保持身体活力.md', '营养与健康生活'),
    B('健康生活的底层逻辑：从认知到行动的转变.md', '营养与健康生活'),
    B('健康饮食：从科学认知到日常实践的营养指南.md', '营养与健康生活'),
    B('跨代际沟通中的数字素养差异与桥梁构建.md', '家庭教育与亲子'),
    B('如何培养孩子的阅读习惯.md', '家庭教育与亲子'),
    B('如何培养孩子的良好习惯：从生活到学习的实用指南.md', '家庭教育与亲子'),
    B('如何提高孩子的学习动力.md', '家庭教育与亲子'),
    B('如何建立和维护健康的亲子关系？实用指南.md', '家庭教育与亲子'),
    B('儿童心理健康的早期培养：筑牢孩子未来的根基.md', '家庭教育与亲子'),
  ],
  /* B5 职业与生活组 113 篇 */
  b5: [
    A('商业/创业指南', '职场与创业'),
    A('商业/产品研发', '职场与创业'),
    A('商业/职场生存/个人品牌', '职场与创业'),
    A('商业/数字营销', '数字营销与内容创作', { recursive: true, subdirTag: true }),
    A('商业/营销增长', '数字营销与内容创作'),
    A('商业/营销自动化', '数字营销与内容创作'),
    A('通用/家庭理财', '家庭理财', { recursive: true, subdirTag: true, exclude: ['股票投资/K线图入门.md', '股票投资/K线技术指标.md'] }),
    A('通用/法律常识', '法律与生活权益'),
    A('商业/职场生存/劳动权益', '法律与生活权益'),
    A('通用/认知思维', '认知与思维', { recursive: true, subdirTag: true }),
    B('程序员技术好的评判标准.md', '职场与创业'),
    B('程序员独立赚钱的实用指南.md', '职场与创业'),
    B('程序员创业的十大误区：避开这些“技术陷阱”才能走得更远.md', '职场与创业'),
    B('IT行业新人快速成长指南.md', '职场与创业'),
    B('技术领导者的必备技能与成长路径.md', '职场与创业'),
    B('技术团队高效协作的实践指南.md', '职场与创业'),
    B('技术债务管理：如何平衡速度与质量.md', '职场与创业'),
    B('当代码重构遇上技术革命：程序员岗位变迁的五个关键信号.md', '职场与创业'),
    B('远程工作：从低效到高效的全方位指南.md', '职场与创业'),
    B('远程工作的高效管理：从工具到文化的构建.md', '职场与创业'),
    B('远程项目管理：打造高效虚拟团队的实践指南.md', '职场与创业'),
    B('远程工作时代的技术团队管理策略.md', '职场与创业'),
    B('职场倦怠的预防与应对：如何保持工作热情.md', '职场与创业'),
    B('职场沟通的艺术：如何有效表达和倾听.md', '职场与创业'),
    B('职场中的「心理契约」：如何建立互信的工作关系.md', '职场与创业'),
    B('内向者在职场沟通中的策略与优势.md', '职场与创业'),
    B('职场薪资谈判进阶指南：高级策略与实战技巧（2026年版）.md', '职场与创业'),
    B('互联网行业“35岁危机”蔓延与春招应届生职业规划.md', '职场与创业'),
    B('2026年SEO趋势完全指南：算法更新、核心策略与实践技巧.md', '数字营销与内容创作'),
    B('常见SEO错误避坑指南：90%网站都犯过的10个错误.md', '数字营销与内容创作'),
    B('本地SEO优化全攻略：让本地客户主动找到你.md', '数字营销与内容创作'),
    B('AI时代的SEO：如何利用AI工具提升排名.md', '数字营销与内容创作'),
    B('微信公众号爆款文章打造全攻略.md', '数字营销与内容创作'),
    B('手冲咖啡与精品公众号：从0到1打造的耐心、变量控制与仪式感.md', '数字营销与内容创作'),
    B('碎片时间写作法：利用通勤时间完成一本书的创作.md', '数字营销与内容创作'),
    B('极端换位思考：与最讨厌的人交换思维模式运营公众号.md', '数字营销与内容创作'),
    B('年轻一代的财富管理：如何在早期建立财务基础.md', '家庭理财'),
    B('财富管理中的税务筹划：合法减少税务负担.md', '家庭理财'),
    B('财富管理中的教育规划：为子女教育做好财务准备.md', '家庭理财'),
    B('财富管理中的现金流管理：如何保持财务健康.md', '家庭理财'),
    B('财富管理中的风险管理：如何保护你的财富安全.md', '家庭理财'),
    B('财富管理的心理学：如何克服投资中的心理障碍.md', '家庭理财'),
    B('财务自由的路径：如何规划个人财务.md', '家庭理财'),
    B('退休规划：精心布局畅享无忧老年生活.md', '家庭理财'),
    B('退休后的学习与成长：活到老，学到老，开启人生新篇章.md', '家庭理财'),
    B('退休后的时间管理：从容安排每一天，享受慢节奏生活.md', '家庭理财'),
    B('退休后的社交生活：建立新的人际圈，拥抱丰富晚年.md', '家庭理财'),
    B('数字围城下的生存法则：普通人的隐私自卫指南.md', '法律与生活权益'),
    B('AI时代的个人数据管理：从隐私保护到价值创造.md', '法律与生活权益'),
    B('如何在数字化时代保护个人隐私.md', '法律与生活权益'),
    B('守株待兔：被误读的概率思维实验.md', '认知与思维'),
    B('田忌赛马：被低估的职场生存术，看懂的人早已逆袭.md', '认知与思维'),
    B('庖丁解牛：被低估的系统思维智慧.md', '认知与思维'),
    B('纸上谈兵：被误读千年的“知识陷阱”，藏着现代人最深的焦虑.md', '认知与思维'),
    B('邯郸学步：被误读的学习方法实验.md', '认知与思维'),
    B('揠苗助长：被误读的成长规律实验.md', '认知与思维'),
    B('自相矛盾：被低估的逻辑思维实验.md', '认知与思维'),
    B('负荆请罪：一场跨越千年的非暴力沟通范本.md', '认知与思维'),
    B('朝三暮四：被误读的预期管理智慧.md', '认知与思维'),
    B('缘木求鱼：逆向思维下的认知突围与生命韧性.md', '认知与思维'),
    B('数字极简主义：告别信息过载的生活革命.md', '认知与思维'),
    B('数字时代的注意力管理：从信息过载到专注创造.md', '认知与思维'),
    B('注意力资产负债表编制：如何管理你的终极货币.md', '认知与思维'),
    B('数字时代的知识管理：如何构建个人知识体系.md', '认知与思维'),
    B('为什么你的知识管理系统总是失败：从卡片笔记到第二大脑的真相.md', '认知与思维'),
    B('知识体系的操作成本优化：从微不足道到关键突破.md', '认知与思维'),
    B('数字时代的「阅读仪式感」：如何在碎片化时代深度阅读.md', '认知与思维'),
    B('系统思维的实践指南：从复杂系统到人生管理.md', '认知与思维'),
    B('数据驱动决策的黑暗面与直觉平衡：何时相信数据何时听从直觉.md', '认知与思维'),
    B('如何通过阅读提升个人认知.md', '认知与思维'),
    B('长期主义的心理陷阱：如何辨别真伪长期主义.md', '认知与思维'),
    B('长期主义作为敏捷迭代项目：最小可行产品与衡量标准.md', '认知与思维'),
  ],
  /* B6 鸿蒙生态与科技观察 28 + 安全急救与生活通识 9 */
  b6: [
    B('我升级到了鸿蒙6.0，这是我的真实体验.md', '鸿蒙生态与科技观察'),
    B('我放弃了鸿蒙Next，回归了使用鸿蒙4.2的用户阵营.md', '鸿蒙生态与科技观察'),
    B('华为鸿蒙OS：连接万物的智能操作系统.md', '鸿蒙生态与科技观察'),
    B('鸿蒙系统产品哲学：优化公司会议与家庭决策流程.md', '鸿蒙生态与科技观察'),
    B('华为企业文化：创新与责任的完美体现.md', '鸿蒙生态与科技观察'),
    B('华为5G技术：引领全球通信行业的创新力量.md', '鸿蒙生态与科技观察'),
    B('华为Mate 60 Pro使用体验：科技与美学的完美融合.md', '鸿蒙生态与科技观察'),
    B('华为云服务：企业数字化转型的强大引擎.md', '鸿蒙生态与科技观察'),
    B('量子计算：未来计算的革命性突破.md', '鸿蒙生态与科技观察'),
    B('量子计算与信息安全：密码学的未来挑战.md', '鸿蒙生态与科技观察'),
    B('脑机接口：人类与机器的未来融合.md', '鸿蒙生态与科技观察'),
    B('脑机接口时代的隐私保护：神经数据的伦理边界.md', '鸿蒙生态与科技观察'),
    B('数字孪生：现实与虚拟的融合.md', '鸿蒙生态与科技观察'),
    B('自动驾驶汽车：何时能真正实现普及？.md', '鸿蒙生态与科技观察'),
    B('区块链：重塑信任的分布式账本技术.md', '鸿蒙生态与科技观察'),
    B('5G技术：将如何改变我们的生活与社会？.md', '鸿蒙生态与科技观察'),
    B('基因编辑：改写生命密码的革命性技术.md', '鸿蒙生态与科技观察'),
    B('人工智能伦理：平衡技术创新与人类价值.md', '鸿蒙生态与科技观察'),
    B('人工智能时代的隐私保护：挑战与解决方案.md', '鸿蒙生态与科技观察'),
    B('虚拟现实技术：将如何改变我们的生活？.md', '鸿蒙生态与科技观察'),
    B('2026年DeepSeek技术解析：从自然语言处理到多模态模型的跨越.md', '鸿蒙生态与科技观察'),
    B('用DeepSeek高效创作：2026年内容创作者AI工具实战手册.md', '鸿蒙生态与科技观察'),
    B('AI训练师职业揭秘：2026年入门门槛、薪资前景与必备技能清单.md', '鸿蒙生态与科技观察'),
    B('大模型应用的最后一公里：从技术到商业的转化.md', '鸿蒙生态与科技观察'),
    B('最先被人工智能取代的职业有哪些？.md', '鸿蒙生态与科技观察'),
    B('新职业形态：AI时代的职业转型与技能重塑.md', '鸿蒙生态与科技观察'),
    B('AI协作能力：2026年职场新人必备的AI协作技能.md', '鸿蒙生态与科技观察'),
    B('职场效率革命：DeepSeek如何重塑数据分析、会议纪要与简历优化.md', '鸿蒙生态与科技观察'),
    A('通用/生活通识/安全防范', '安全急救与生活通识'),
    A('通用/生活通识/急救知识', '安全急救与生活通识'),
    A('通用/生活通识/社保公积金', '安全急救与生活通识'),
    A('通用/生活通识/自然灾害', '安全急救与生活通识'),
    B('碳中和生活：2026年家庭实现零碳排放的实用策略.md', '安全急救与生活通识'),
    B('极简环保生活实践：一年轻松减少30%家庭垃圾.md', '安全急救与生活通识'),
  ],
};

/* ------------------------------ 工具函数 ------------------------------ */
function stripBom(text) {
  return text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
}

/** 容错解析来源 front-matter：支持缺闭合 --- 的 A 源文件 */
function parseSource(content) {
  const text = stripBom(content).replace(/\r\n/g, '\n');
  if (!text.startsWith('---')) return { fm: {}, body: text };
  const lines = text.split('\n');
  let closeIdx = -1;
  for (let i = 1; i < Math.min(lines.length, 80); i++) {
    if (lines[i].trim() === '---') {
      closeIdx = i;
      break;
    }
  }
  let fmLines;
  let bodyStart;
  if (closeIdx > 0) {
    fmLines = lines.slice(1, closeIdx);
    bodyStart = closeIdx + 1;
  } else {
    let i = 1;
    while (i < lines.length && /^\s*[A-Za-z_\u4e00-\u9fa5][A-Za-z0-9_\u4e00-\u9fa5]*\s*:/.test(lines[i])) {
      i++;
    }
    fmLines = lines.slice(1, i);
    bodyStart = i;
  }
  const fm = {};
  for (const line of fmLines) {
    const idx = line.indexOf(':');
    if (idx <= 0) continue;
    fm[line.slice(0, idx).trim()] = line.slice(idx + 1).trim().replace(/^['"]|['"]$/g, '');
  }
  return { fm, body: lines.slice(bodyStart).join('\n') };
}

/** tags 字符串 → 数组 */
function parseTags(raw) {
  if (!raw) return [];
  let s = String(raw).trim();
  if (s.startsWith('[') && s.endsWith(']')) s = s.slice(1, -1);
  else if (s.startsWith('[')) s = s.slice(1);
  return s
    .split(',')
    .map((x) => x.trim().replace(/^['"]|['"]$/g, ''))
    .filter(Boolean);
}

/** 清洗 LaTeX/markdown 装饰为纯文本 */
function cleanText(s) {
  return String(s)
    .replace(/\$\\color\{[^}]*\}\{([^}]*)\}\$/g, '$1')
    .replace(/\\textbf\{([^}]+)\}/g, '$1')
    .replace(/\s+/g, ' ')
    .trim();
}

/** 正文清洗 */
function cleanBody(body) {
  let text = body
    .replace(/\$\\color\{[^}]*\}\{([^}]*)\}\$/g, '$1')
    .replace(/\\textbf\{([^}]+)\}/g, '**$1**')
    .replace(/\r\n/g, '\n');
  return text.replace(/^\s*\n+/, '').replace(/\n+\s*$/, '') + '\n';
}

/** 描述兜底：正文前 N 字符 */
function fallbackDescription(body) {
  const plain = body
    .replace(/^#{1,6}\s+/gm, '')
    .replace(/^>\s*/gm, '')
    .replace(/[`*>#|]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  return plain.slice(0, 100);
}

/** 文件名 → slug：去空格与非法字符 */
function cleanSlug(name) {
  return name.replace(/\s+/g, '').replace(/[\/\\?%*:|"'<>]/g, '');
}

/** 递归收集 .md 文件，返回 [{ abs, rel }]（rel 用 / 分隔） */
function collectMdFiles(dir, base = '') {
  const result = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('_') || entry.name.startsWith('.')) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectMdFiles(full, base ? base + '/' + entry.name : entry.name));
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      result.push({ abs: full, rel: base ? base + '/' + entry.name : entry.name });
    }
  }
  return result;
}

/** exclude 匹配：*.md 结尾按 rel 精确匹配，否则按目录段匹配 */
function isExcluded(rel, exclude) {
  if (!exclude) return false;
  return exclude.some((e) => {
    if (e.endsWith('.md')) return rel === e;
    return rel.split('/').includes(e);
  });
}

/** rename 查找：先按 rel 全路径匹配，再按文件名匹配 */
function resolveRename(rename, rel) {
  if (!rename || typeof rename !== 'object') return null;
  if (rename[rel]) return rename[rel];
  const base = rel.split('/').pop();
  return rename[base] || null;
}

/** 既有 slug 收集（撞车检测基线） */
function collectExistingSlugs(dir, base = '') {
  const result = new Map();
  if (!fs.existsSync(dir)) return result;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      for (const [k, v] of collectExistingSlugs(full, base ? base + '/' + entry.name : entry.name)) {
        result.set(k, v);
      }
    } else if (entry.isFile() && entry.name.endsWith('.md')) {
      result.set(cleanSlug(path.basename(entry.name, '.md')), base ? base + '/' + entry.name : entry.name);
    }
  }
  return result;
}

/* ------------------------------ 主流程 ------------------------------ */
function main() {
  const args = parseArgs(process.argv);
  const batchNames = args.batch === 'all' ? ['b1', 'b2', 'b3', 'b4', 'b5', 'b6'] : [args.batch];
  const mappings = batchNames.flatMap((b) => {
    if (!BATCHES[b]) {
      console.error(`未知批次: ${b}`);
      process.exit(1);
    }
    return BATCHES[b];
  });

  const existingSlugs = collectExistingSlugs(CONTENT_DIR);
  const plan = [];
  const problems = [];
  const notes = [];
  const fallbacks = [];

  for (const m of mappings) {
    let items = [];
    if (m.type === 'dir') {
      if (!fs.existsSync(m.src)) {
        problems.push(`来源目录不存在: ${m.src}`);
        continue;
      }
      const all = m.recursive === false ? [] : collectMdFiles(m.src);
      if (!m.recursive) {
        // 非递归：仅取 src 直下文件
        for (const f of all) if (!f.rel.includes('/')) items.push(f);
      } else {
        items = all;
      }
      for (const f of items) {
        if (isExcluded(f.rel, m.exclude)) continue;
        const subdir = f.rel.includes('/') ? f.rel.split('/')[0] : null;
        const renameTo = resolveRename(m.rename, f.rel);
        plan.push({ abs: f.abs, rel: f.rel, dest: m.dest, subdirTag: m.subdirTag ? subdir : null, renameTo, mapping: m });
      }
    } else {
      if (!fs.existsSync(m.src)) {
        problems.push(`来源文件不存在: ${m.src}`);
        continue;
      }
      const renameTo = typeof m.rename === 'string' ? m.rename : resolveRename(m.rename, path.basename(m.src));
      plan.push({ abs: m.src, rel: path.basename(m.src), dest: m.dest, subdirTag: null, renameTo, mapping: m });
    }
  }

  /* 逐篇加工 */
  const outputs = [];
  const seenSlugs = new Map();
  for (const item of plan) {
    const raw = fs.readFileSync(item.abs, 'utf8');
    const { fm, body } = parseSource(raw);
    const baseName = item.renameTo || path.basename(item.abs, '.md');
    const slug = cleanSlug(baseName);
    if (!slug) {
      problems.push(`slug 为空: ${item.abs}`);
      continue;
    }
    if (existingSlugs.has(slug)) {
      problems.push(`slug 与既有文件撞车: "${slug}"（既有: ${existingSlugs.get(slug)}）`);
      continue;
    }
    if (seenSlugs.has(slug)) {
      problems.push(`slug 本批内撞车: "${slug}"（${seenSlugs.get(slug)} / ${item.abs}）`);
      continue;
    }
    seenSlugs.set(slug, item.abs);

    const title = cleanText(item.renameTo || fm.title || baseName);
    let tags = parseTags(fm.tags);
    if (item.subdirTag) tags.unshift(item.subdirTag);
    tags = [...new Set(tags.map((t) => t.trim()).filter(Boolean))].slice(0, 8);
    if (tags.length === 0) tags = [item.dest];

    let description = cleanText(fm.description || '');
    if (!description) {
      description = fallbackDescription(body);
      fallbacks.push(`${item.dest}/${slug}`);
    }
    if (description.length > DESC_MAX) description = description.slice(0, DESC_MAX);

    let outBody = cleanBody(body);
    /* H1 规范化 / 补齐 */
    const lines = outBody.split('\n');
    let firstIdx = 0;
    while (firstIdx < lines.length && lines[firstIdx].trim() === '') firstIdx++;
    if (firstIdx < lines.length && /^#\s+/.test(lines[firstIdx])) {
      const h1 = lines[firstIdx].replace(/^#\s+/, '');
      lines[firstIdx] = '# ' + h1.replace(/^\*\*(.+)\*\*$/, '$1').trim();
      outBody = lines.slice(firstIdx).join('\n');
    } else {
      outBody = `# ${title}\n\n` + outBody;
    }
    /* 时效标注 */
    if (/20(2[4-9])/.test(title)) {
      outBody = TIMELINESS_NOTE + '\n\n' + outBody;
      notes.push(`${item.dest}/${slug}`);
    }

    const frontMatter = `---\ntitle: ${title}\ntags: [${tags.join(', ')}]\ndescription: ${description}\n---\n\n`;
    outputs.push({ dest: item.dest, slug, content: frontMatter + outBody });
  }

  /* 报告与写入 */
  const byDest = new Map();
  for (const o of outputs) byDest.set(o.dest, (byDest.get(o.dest) || 0) + 1);

  console.log(`\n===== 批次 ${batchNames.join('+')} 计划 =====`);
  for (const [dest, count] of [...byDest.entries()].sort()) {
    console.log(`  ${dest}: ${count} 篇`);
  }
  console.log(`  合计: ${outputs.length} 篇（映射源 ${plan.length} 个）`);
  if (fallbacks.length) {
    console.log(`\n⚠ 描述缺失已兜底（${fallbacks.length} 篇）:`);
    for (const f of fallbacks) console.log(`  - ${f}`);
  }
  const renamedItems = plan.filter((p) => p.renameTo);
  if (renamedItems.length) {
    console.log(`\n🔁 重命名（${renamedItems.length} 篇）:`);
    for (const r of renamedItems) console.log(`  - ${r.rel} -> ${r.dest}/${r.renameTo}.md`);
  }
  if (notes.length) {
    console.log(`\n⏱ 已加时效标注（${notes.length} 篇）:`);
    for (const n of notes) console.log(`  - ${n}`);
  }
  if (problems.length) {
    console.log(`\n❌ 问题（${problems.length}，需处理后重跑）:`);
    for (const p of problems) console.log(`  - ${p}`);
    process.exit(1);
  }

  if (args.dryRun) {
    console.log('\n[dry-run] 未写入。明细:');
    for (const o of outputs) console.log(`  ${o.dest}/${o.slug}.md`);
    return;
  }

  for (const o of outputs) {
    const destDir = path.join(CONTENT_DIR, o.dest);
    fs.mkdirSync(destDir, { recursive: true });
    fs.writeFileSync(path.join(destDir, o.slug + '.md'), o.content, 'utf8');
  }
  console.log(`\n✅ 已写入 ${outputs.length} 篇到 content/mdfiles/`);
}

main();
