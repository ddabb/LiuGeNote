#!/usr/bin/env node
/**
 * 行知（LgNote）离线内容发布脚本（对标 F:\SelfJob\vercel-ci\publish.js）
 *
 * 职责：
 *   content/mdfiles/<分类>/*.md  ──解析 front-matter──▶  entry/src/main/resources/rawfile/
 *     ├── index.json       文章元数据索引（对标 jsons/mdfiles.json）
 *     ├── taxonomy.json    标签/分类统计（对标 taxonomy 统计）
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

  fs.writeFileSync(path.join(OUT_DIR, 'index.json'), JSON.stringify(indexJson, null, 2) + '\n', 'utf8');
  fs.writeFileSync(path.join(OUT_DIR, 'taxonomy.json'), JSON.stringify(taxonomyJson, null, 2) + '\n', 'utf8');

  /* 5. 报告 */
  console.log(`✅ 已更新: ${path.join(OUT_DIR, 'index.json')}`);
  console.log(`✅ 已更新: ${path.join(OUT_DIR, 'taxonomy.json')}`);
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
