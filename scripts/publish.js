#!/usr/bin/env node
/**
 * 行知离线内容发布脚本（对标 F:\SelfJob\vercel-ci\publish.js）
 *
 * 职责：
 *   content/mdfiles/<分类>/*.md  ──解析 front-matter──▶  entry/src/main/resources/rawfile/
 *     ├── index.json       文章元数据索引（对标 jsons/mdfiles.json）
 *     ├── taxonomy.json    标签/分类统计（对标 taxonomy 统计）
 *     ├── quiz.json        知识问答题库（B1：从正文二级小节自动出题）
 *     └── articles/<slug>.md  正文（front-matter 已剥离，对标 md2html 产物的数据部分）
 *
 * 特性：纯 Node 内置模块（fs/path），零第三方依赖；slug 清洗对标 sanitizeFileName；
 *       slug 撞车直接失败；无描述文章自动摘要兜底并警告。
 *       目录即分类（对齐 PortableKnowledge source/）：rel 第一级子目录名 = 分类，
 *       根级平铺文件回退 front-matter.category，再回退"未分类"。
 *
 * 用法：node scripts/publish.js [--content <dir>] [--out <dir>] [--watch]
 */
'use strict';

const fs = require('fs');
const path = require('path');

/* ------------------------------ 参数解析 ------------------------------ */
function parseArgs(argv) {
  const args = { content: null, out: null, watch: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--content') args.content = argv[++i];
    else if (a === '--out') args.out = argv[++i];
    else if (a === '--watch') args.watch = true;
    else if (a === '--help' || a === '-h') {
      console.log('用法: node scripts/publish.js [--content <dir>] [--out <dir>] [--watch]');
      process.exit(0);
    } else {
      console.error(`未知参数: ${a}`);
      process.exit(1);
    }
  }
  return args;
}

/* ------------------------------ 常量与工具 ------------------------------ */
const ROOT = path.resolve(__dirname, '..');
const args = parseArgs(process.argv);
const MD_DIR = path.resolve(ROOT, args.content || path.join('content', 'mdfiles'));
const OUT_DIR = path.resolve(ROOT, args.out || path.join('entry', 'src', 'main', 'resources', 'rawfile'));
const ARTICLES_DIR = path.join(OUT_DIR, 'articles');

const DEFAULT_CATEGORY = '未分类';
const DESC_FALLBACK_LEN = 80;

/* B1 知识问答出题参数 */
const QUIZ_SENT_MIN = 12; // 候选句最短长度（字符）
const QUIZ_SENT_MAX = 90; // 候选句最长长度（字符）
const QUIZ_CJK_MIN = 4; // 候选句最少中文字符数
const QUIZ_OPTION_MAX = 64; // 选项截断长度（超长加省略号）
const QUIZ_OVERLAP_LIMIT = 0.6; // 干扰项与正确项 bigram 重合度上限
const QUIZ_MAX_PER_ARTICLE = 4; // 每篇文章最多出题数

/** 对标 vercel-ci/publish.js 的 sanitizeFileName：清洗文件系统/URL 非法字符 */
function sanitizeFileName(name) {
  return String(name).replace(/[\/\\?%*:|"'<>]/g, '-').trim();
}

/** BOM 剥离（对标参考项目 front-matter 正则里的 (\uFEFF)? 容错） */
function stripBom(text) {
  return text.charCodeAt(0) === 0xfeff ? text.slice(1) : text;
}

/**
 * FNV-1a 32位哈希 → 8位十六进制 fileId
 * 正文文件用 fileId 命名（articles/<fileId>.md），规避 rawfile 中文路径的兼容性风险；
 * slug 保持中文用于展示与路由，fileId 是存储 ID。slug 稳定 ⇒ fileId 稳定。
 */
function fnv1aFileId(str) {
  let h = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return (h >>> 0).toString(16).padStart(8, '0');
}

/* ------------------------------ front-matter ------------------------------ */
/** 解析 YAML 子集 value：数组 / true / false / 数字 / 引号字符串 / 裸字符串 */
function parseValue(raw) {
  const s = String(raw).trim();
  if (s.startsWith('[') && s.endsWith(']')) {
    return s
      .slice(1, -1)
      .split(',')
      .map((x) => x.trim().replace(/^['"]|['"]$/g, ''))
      .filter(Boolean);
  }
  if (s === 'true') return true;
  if (s === 'false') return false;
  if (/^-?\d+(\.\d+)?$/.test(s)) return Number(s);
  return s.replace(/^['"]|['"]$/g, '');
}

/**
 * 提取 front-matter 与正文字数（对标 extractFrontMatterAndCountWords）
 * 返回 { frontMatter, body, wordCount }
 */
function extractFrontMatterAndCountWords(content) {
  const text = stripBom(content);
  const fmRegex = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/;
  const match = text.match(fmRegex);

  let frontMatter = {};
  let body = text;

  if (match) {
    body = text.slice(match[0].length);
    for (const line of match[1].split(/\r?\n/)) {
      const idx = line.indexOf(':');
      if (idx <= 0) {
        if (line.trim()) console.warn(`  ⚠ front-matter 无法解析的行: "${line}"`);
        continue;
      }
      const key = line.slice(0, idx).trim();
      const value = line.slice(idx + 1);
      if (value.trim() === '') {
        frontMatter[key] = '';
      } else {
        frontMatter[key] = parseValue(value);
      }
    }
  }

  // 字数统计口径与参考项目一致：剥离所有空白后按字符计数
  const wordCount = body.replace(/\s+/g, '').length;
  return { frontMatter, body, wordCount };
}

/** 规范化 tags 字段：数组 / 逗号字符串均接受（对标参考项目兼容逻辑） */
function normalizeTags(tags) {
  if (Array.isArray(tags)) return tags.map((t) => String(t).trim()).filter(Boolean);
  if (typeof tags === 'string') return tags.split(',').map((t) => t.trim()).filter(Boolean);
  return [];
}

/** 描述兜底：正文前 N 字符（去掉 md 块级标记符号的近似纯文本） */
function fallbackDescription(body) {
  const plain = body
    .replace(/^#{1,6}\s+/gm, '')
    .replace(/[`*>\-|#]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
  return plain.slice(0, DESC_FALLBACK_LEN);
}

/* ------------------------------ 目录处理 ------------------------------ */
/** 递归清空目录内容（对标 emptyDirectory），目录本身保留 */
function emptyDirectory(dirPath) {
  if (!fs.existsSync(dirPath)) return;
  for (const entry of fs.readdirSync(dirPath, { withFileTypes: true })) {
    const target = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      emptyDirectory(target);
      fs.rmdirSync(target);
    } else {
      fs.unlinkSync(target);
    }
  }
}

/** 递归收集 .md 文件（跳过 _ 开头的文件与目录） */
function collectMdFiles(dir, base = '') {
  const result = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name.startsWith('_') || entry.name.startsWith('.')) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      result.push(...collectMdFiles(full, path.join(base, entry.name)));
    } else if (entry.isFile() && path.extname(entry.name) === '.md') {
      result.push({ full, rel: path.join(base, entry.name) });
    }
  }
  return result;
}

/* ------------------------------ quiz 题库生成（B1） ------------------------------ */
/** 种子随机（mulberry32）：题目种子取自 slug+小节标题哈希，内容不变时 quiz.json 可复现 */
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** 稳定洗牌（不改原数组） */
function seededShuffle(arr, rand) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** bigram 重合度（0-1）：干扰项与正确项语义过近时剔除 */
function overlapRatio(x, y) {
  const grams = (s) => {
    const set = new Set();
    for (let i = 0; i < s.length - 1; i++) set.add(s.slice(i, i + 2));
    return set;
  };
  const A = grams(x);
  const B = grams(y);
  if (A.size === 0 || B.size === 0) return 1;
  let hit = 0;
  for (const g of A) if (B.has(g)) hit++;
  return hit / Math.min(A.size, B.size);
}

/** 剥离行内 markdown 标记（图片/链接/加粗/行内代码等） */
function stripInlineMd(s) {
  return s
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/[*_~`]+/g, '')
    .replace(/[<>]/g, '')
    .trim();
}

/** 选项截断（超长截断加省略号，保证答题卡排版） */
function clipOption(s) {
  const t = s.trim();
  return t.length <= QUIZ_OPTION_MAX ? t : t.slice(0, QUIZ_OPTION_MAX - 1) + '…';
}

/** 拆二级标题小节（跳过代码围栏内的 #；仅 ## 级） */
function splitSections(body) {
  const sections = [];
  const lines = body.split(/\r?\n/);
  let inFence = false;
  let cur = null;
  for (const line of lines) {
    if (/^\s*```/.test(line)) inFence = !inFence;
    if (!inFence && /^##\s+/.test(line)) {
      const title = line.replace(/^##\s+/, '').replace(/\s*##\s*$/, '').trim();
      cur = { title, lines: [] };
      sections.push(cur);
    } else if (cur) {
      cur.lines.push(line);
    }
  }
  return sections.filter((s) => s.title);
}

/** 从小节正文抽句：跳过标题/表格/代码/引用；需含足量中文、长度合规、无链接 */
function sectionSentences(lines) {
  const kept = [];
  let inFence = false;
  for (const raw of lines) {
    const line = raw.trim();
    if (/^```/.test(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence || line === '' || line.startsWith('#') || line.startsWith('|') || line.startsWith('>')) continue;
    kept.push(stripInlineMd(line));
  }
  const text = kept.join('');
  const parts = text.split(/(?<=[。！？；])/);
  const out = [];
  for (const part of parts) {
    const s = part
      .replace(/^[-*•·]\s*/, '')
      .replace(/^\d+[.、)）]\s*/, '')
      .trim();
    if (s.length < QUIZ_SENT_MIN || s.length > QUIZ_SENT_MAX) continue;
    const cjk = (s.match(/[\u4e00-\u9fff]/g) || []).length;
    if (cjk < QUIZ_CJK_MIN) continue;
    if (/https?:\/\//.test(s)) continue;
    out.push(s);
  }
  return out;
}

/**
 * 生成问答题库：
 * - 正确项：每篇最多 QUIZ_MAX_PER_ARTICLE 个小节的首句（全库去重）
 * - 题干：文章标题 + 小节标题上下文
 * - 干扰项：同分类其它小节句子（语义过近剔除），不足 3 个降级跳过该题
 * - 种子随机洗牌选项；id 用 q1..qN 稳定编号
 */
function buildQuiz(files) {
  const bank = [];
  const seenSentence = new Set();
  for (const f of files) {
    let produced = 0;
    for (const sec of splitSections(f.body)) {
      if (produced >= QUIZ_MAX_PER_ARTICLE) break;
      const sentences = sectionSentences(sec.lines);
      if (sentences.length === 0) continue;
      const answer = sentences[0];
      if (seenSentence.has(answer)) continue;
      seenSentence.add(answer);
      bank.push({ file: f, sectionTitle: sec.title, sentence: answer });
      produced++;
    }
  }

  const questions = [];
  for (const cand of bank) {
    const rand = mulberry32(parseInt(fnv1aFileId(`${cand.file.slug}#${cand.sectionTitle}`), 16));
    const pool = bank.filter((x) => x.file.category === cand.file.category && x.sentence !== cand.sentence);
    const correctOpt = clipOption(cand.sentence);
    const distractors = [];
    for (const p of seededShuffle(pool, rand)) {
      if (distractors.length >= 3) break;
      const opt = clipOption(p.sentence);
      if (opt === correctOpt) continue;
      if (overlapRatio(p.sentence, cand.sentence) >= QUIZ_OVERLAP_LIMIT) continue;
      if (distractors.some((d) => d === opt || overlapRatio(d, opt) >= 0.8)) continue;
      distractors.push(opt);
    }
    if (distractors.length < 3) continue;
    const options = seededShuffle([correctOpt, ...distractors], rand);
    questions.push({
      id: `q${questions.length + 1}`,
      slug: cand.file.slug,
      category: cand.file.category,
      question: `《${cand.file.title}》中「${cand.sectionTitle}」一节，以下说法正确的是？`,
      options,
      answer: options.indexOf(correctOpt),
      explanation: `出自《${cand.file.title}》的「${cand.sectionTitle}」小节。`,
    });
  }
  return questions;
}

/* ------------------------------ 主流程 ------------------------------ */
function publish() {
  const started = Date.now();

  if (!fs.existsSync(MD_DIR)) {
    console.error(`❌ 内容目录不存在: ${MD_DIR}`);
    process.exit(1);
  }

  const mdFilesRaw = collectMdFiles(MD_DIR);
  if (mdFilesRaw.length === 0) {
    console.error(`❌ 内容目录没有任何 .md 文件: ${MD_DIR}`);
    process.exit(1);
  }

  /* 1. 解析全部文档 */
  const files = [];
  const noDescriptionFiles = [];
  const slugOwner = new Map(); // slug -> 来源文件（撞车检测）
  const fileIdOwner = new Map(); // fileId -> 来源文件（哈希撞车检测）

  for (const { full, rel } of mdFilesRaw) {
    const stats = fs.statSync(full);
    const content = fs.readFileSync(full, 'utf8');
    const { frontMatter, body, wordCount } = extractFrontMatterAndCountWords(content);

    const slug = sanitizeFileName(path.basename(rel, '.md'));
    if (slugOwner.has(slug)) {
      console.error(`❌ slug 撞车: "${slug}"`);
      console.error(`   来源1: ${slugOwner.get(slug)}`);
      console.error(`   来源2: ${rel}`);
      process.exit(1);
    }
    slugOwner.set(slug, rel);

    const fileId = fnv1aFileId(slug);
    if (fileIdOwner.has(fileId)) {
      console.error(`❌ fileId 哈希撞车: "${fileId}"`);
      console.error(`   来源1: ${slugOwner.get(fileIdOwner.get(fileId)) ?? fileIdOwner.get(fileId)}`);
      console.error(`   来源2: ${rel}`);
      process.exit(1);
    }
    fileIdOwner.set(fileId, rel);

    const fmTitle = typeof frontMatter.title === 'string' ? frontMatter.title : '';
    const fmDesc = typeof frontMatter.description === 'string' ? frontMatter.description : '';

    // 目录即分类（对齐 PortableKnowledge source/<分类>/…）：
    // rel 第一级子目录名 = 分类；根级平铺文件回退 front-matter.category；再回退未分类。
    const dirParts = rel.split(path.sep);
    const dirCategory = dirParts.length > 1 ? dirParts[0].trim() : '';
    const fmCategory =
      typeof frontMatter.category === 'string' && frontMatter.category.trim()
        ? frontMatter.category.trim()
        : '';
    const category = dirCategory || fmCategory || DEFAULT_CATEGORY;

    let description = fmDesc.trim();
    if (!description) {
      description = fallbackDescription(body);
      noDescriptionFiles.push(rel);
    }

    files.push({
      slug,
      fileId,
      name: path.basename(rel),
      title: fmTitle.trim() || slug,
      description,
      category,
      tags: normalizeTags(frontMatter.tags),
      wordCount,
      createTime: stats.birthtime.toISOString(),
      updateTime: stats.mtime.toISOString(),
      body,
    });
  }

  /* 2. 排序与序号（对标：mtime 降序 + order） */
  files.sort((a, b) => (a.updateTime < b.updateTime ? 1 : a.updateTime > b.updateTime ? -1 : 0));
  files.forEach((f, i) => (f.order = i + 1));

  /* 3. taxonomy 统计（对标 generateTaxonomy） */
  const tagCount = new Map();
  const categoryCount = new Map();
  for (const f of files) {
    categoryCount.set(f.category, (categoryCount.get(f.category) || 0) + 1);
    for (const t of f.tags) tagCount.set(t, (tagCount.get(t) || 0) + 1);
  }

  const tags = [...tagCount.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name, 'zh'));
  const categories = [...categoryCount.entries()]
    .map(([name, count]) => ({ name, count }))
    .sort((a, b) => a.name.localeCompare(b.name, 'zh'));

  /* 4. 写产物 */
  fs.mkdirSync(ARTICLES_DIR, { recursive: true });
  emptyDirectory(ARTICLES_DIR);

  for (const f of files) {
    fs.writeFileSync(path.join(ARTICLES_DIR, `${f.fileId}.md`), f.body, 'utf8');
  }

  const generatedAt = new Date().toISOString();
  const indexJson = {
    meta: {
      generatedAt,
      totalFiles: files.length,
      generator: 'lgnote publish.js',
    },
    files: files.map(
      ({
        slug,
        fileId,
        title,
        description,
        category,
        tags: t,
        wordCount,
        createTime,
        updateTime,
        order,
      }) => ({
        slug,
        fileId,
        title,
        description,
        category,
        tags: t,
        wordCount,
        createTime,
        updateTime,
        order,
      })
    ),
  };

  const taxonomyJson = { generatedAt, tags, categories };

  /* 3.5 quiz 题库生成（B1 知识问答数据管线） */
  const quizQuestions = buildQuiz(files);
  const quizJson = { generatedAt, total: quizQuestions.length, questions: quizQuestions };

  fs.writeFileSync(path.join(OUT_DIR, 'index.json'), JSON.stringify(indexJson, null, 2) + '\n', 'utf8');
  fs.writeFileSync(path.join(OUT_DIR, 'taxonomy.json'), JSON.stringify(taxonomyJson, null, 2) + '\n', 'utf8');
  fs.writeFileSync(path.join(OUT_DIR, 'quiz.json'), JSON.stringify(quizJson, null, 2) + '\n', 'utf8');

  /* 5. 报告 */
  console.log(`✅ 已更新: ${path.join(OUT_DIR, 'index.json')}`);
  console.log(`✅ 已更新: ${path.join(OUT_DIR, 'taxonomy.json')}`);
  console.log(`✅ 已更新: ${path.join(OUT_DIR, 'quiz.json')} (${quizQuestions.length} 题)`);
  console.log(`✅ 已写入正文: ${ARTICLES_DIR} (${files.length} 篇)`);
  console.log(`📂 分类统计: ${categories.length} 个`);
  console.log(`🏷️  标签统计: ${tags.length} 个`);

  if (noDescriptionFiles.length) {
    console.log(`⚠ 无描述文章（已用正文前 ${DESC_FALLBACK_LEN} 字兜底）：`);
    for (const rel of noDescriptionFiles) console.log(`  - ${rel}`);
  }

  console.log(`\n✅ 发布完成，耗时 ${Date.now() - started} ms`);
}

/* ------------------------------ watch 模式 ------------------------------ */
if (args.watch) {
  console.log(`👁 监听目录: ${MD_DIR}`);
  publish();
  let timer = null;
  fs.watch(MD_DIR, { recursive: true }, () => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      console.log('\n--- 检测到变化，重新发布 ---');
      try {
        publish();
      } catch (e) {
        console.error(`❌ 发布失败: ${e.message}`);
      }
    }, 200);
  });
} else {
  try {
    publish();
  } catch (e) {
    console.error(`❌ 发布失败: ${e.message}`);
    process.exit(1);
  }
}
