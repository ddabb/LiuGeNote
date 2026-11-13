
# Redis使用

## 定义

Redis（Remote Dictionary Server）是一个开源的内存数据结构存储系统，可以用作数据库、缓存和消息代理。它支持多种数据结构，如字符串、哈希、列表、集合、有序集合等，并提供高性能和丰富的功能。

## 核心概念

### 1. 数据结构
- **字符串（String）**：最基本的数据类型，键值对
- **哈希（Hash）**：键值对集合，适合存储对象
- **列表（List）**：有序字符串列表，可实现队列、栈
- **集合（Set）**：无序唯一字符串集合
- **有序集合（Sorted Set）**：每个成员关联一个分数，按分数排序

### 2. 持久化（Persistence）
- **RDB（Redis Database Backup）**：定时快照
- **AOF（Append Only File）**：记录每个写操作
- **混合持久化**：RDB + AOF

### 3. 高可用（High Availability）
- **主从复制**：数据从主节点复制到从节点
- **哨兵（Sentinel）**：监控、通知、自动故障转移
- **集群（Cluster）**：数据分片，水平扩展

### 4. 事务（Transaction）
- **定义**：一组命令，要么全部执行，要么全部不执行
- **实现**：MULTI、EXEC、DISCARD、WATCH
- **注意**：Redis事务不支持回滚

## 详细内容

### Redis应用场景

1. **缓存**
   - **目的**：减轻数据库压力，提高响应速度
   - **策略**：设置TTL（生存时间），淘汰策略
   - **示例**：缓存用户信息、热门商品

2. **会话存储**
   - **目的**：存储用户会话数据
   - **优势**：多服务器共享会话
   - **示例**：Web应用会话管理

3. **排行榜**
   - **目的**：实现实时排行榜
   - **数据结构**：有序集合（Sorted Set）
   - **示例**：游戏积分排行榜

4. **计数器**
   - **目的**：实现快速计数
   - **数据结构**：字符串（String）
   - **示例**：文章浏览量、点赞数

5. **消息队列**
   - **目的**：实现异步处理
   - **数据结构**：列表（List）、发布/订阅（Pub/Sub）
   - **示例**：订单处理队列

### Node.js中操作Redis

1. **使用redis客户端**
   - **redis**：官方Redis客户端
   - **ioredis**：功能更丰富的客户端
   - **连接配置**：主机、端口、密码、数据库

2. **基本操作**
   - **字符串**：SET、GET、INCR、EXPIRE
   - **哈希**：HSET、HGET、HGETALL
   - **列表**：LPUSH、RPUSH、LPOP、RPOP
   - **集合**：SADD、SREM、SMEMBERS
   - **有序集合**：ZADD、ZRANGE、ZREVRANGE

3. **高级功能**
   - **管道（Pipeline）**：批量执行命令，减少网络往返
   - **事务**：MULTI/EXEC
   - **发布/订阅**：PUBLISH、SUBSCRIBE

## 示例/应用场景

### 示例1：使用ioredis进行基本操作

**安装**：
```bash
npm install ioredis
```

**连接Redis**：
```javascript
const Redis = require('ioredis');

// 创建Redis客户端
const redis = new Redis({
  host: 'localhost',
  port: 6379,
  password: 'password',
  db: 0,
  retryStrategy: (times) => {
    // 重试策略
    const delay = Math.min(times * 50, 2000);
    return delay;
  }
});

// 错误处理
redis.on('error', (error) => {
  console.error('Redis错误:', error);
});

// 字符串操作
async function stringExample() {
  // 设置键值
  await redis.set('user:1:name', '张三');
  await redis.set('user:1:email', 'zhangsan@example.com');
  
  // 设置过期时间（秒）
  await redis.expire('user:1:name', 3600);
  
  // 获取值
  const name = await redis.get('user:1:name');
  console.log('用户名:', name);
  
  // 计数器
  await redis.incr('page:view:count');
  const count = await redis.get('page:view:count');
  console.log('页面浏览量:', count);
}

// 哈希操作
async function hashExample() {
  // 设置哈希字段
  await redis.hset('user:1', 'name', '张三');
  await redis.hset('user:1', 'email', 'zhangsan@example.com');
  await redis.hset('user:1', 'age', '30');
  
  // 获取单个字段
  const name = await redis.hget('user:1', 'name');
  console.log('用户名:', name);
  
  // 获取所有字段
  const user = await redis.hgetall('user:1');
  console.log('用户信息:', user);
}

// 列表操作
async function listExample() {
  // 推入元素
  await redis.lpush('tasks', 'task1');
  await redis.lpush('tasks', 'task2');
  await redis.rpush('tasks', 'task3');
  
  // 弹出元素
  const task = await redis.rpop('tasks');
  console.log('处理任务:', task);
  
  // 获取列表长度
  const length = await redis.llen('tasks');
  console.log('剩余任务数:', length);
}

// 有序集合操作（排行榜）
async function sortedSetExample() {
  // 添加成员
  await redis.zadd('leaderboard', 100, 'player1');
  await redis.zadd('leaderboard', 200, 'player2');
  await redis.zadd('leaderboard', 150, 'player3');
  
  // 获取前10名（分数从高到低）
  const top10 = await redis.zrevrange('leaderboard', 0, 9, 'WITHSCORES');
  console.log('排行榜前10名:', top10);
  
  // 获取用户排名
  const rank = await redis.zrevrank('leaderboard', 'player1');
  console.log('player1排名:', rank + 1); // 排名从0开始
}

// 执行示例
(async () => {
  await stringExample();
  await hashExample();
  await listExample();
  await sortedSetExample();
  
  // 关闭连接
  redis.disconnect();
})();
```

### 示例2：使用Redis实现缓存

```javascript
const Redis = require('ioredis');
const mysql = require('mysql2/promise');

const redis = new Redis();
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'password',
  database: 'myapp'
});

// 缓存中间件
async function getUserWithCache(userId) {
  // 尝试从缓存获取
  const cacheKey = `user:${userId}`;
  const cachedUser = await redis.get(cacheKey);
  
  if (cachedUser) {
    console.log('从缓存获取用户');
    return JSON.parse(cachedUser);
  }
  
  // 缓存未命中，从数据库获取
  console.log('从数据库获取用户');
  const [rows] = await pool.execute(
    'SELECT * FROM users WHERE id = ?',
    [userId]
  );
  
  if (rows.length === 0) {
    return null;
  }
  
  const user = rows[0];
  
  // 存入缓存，设置60秒过期
  await redis.setex(cacheKey, 60, JSON.stringify(user));
  
  return user;
}

// 清除缓存
async function updateUserAndClearCache(userId, updates) {
  // 更新数据库
  await pool.execute(
    'UPDATE users SET name = ?, email = ? WHERE id = ?',
    [updates.name, updates.email, userId]
  );
  
  // 清除缓存
  const cacheKey = `user:${userId}`;
  await redis.del(cacheKey);
  
  console.log('用户更新成功，缓存已清除');
}
```

## 【Node.js后端开发】最佳实践

### 1. 缓存策略
- **设置TTL**：为缓存设置合理的过期时间
- **缓存穿透防护**：缓存空值或使用布隆过滤器
- **缓存雪崩防护**：使用随机TTL或分布式锁
- **缓存更新策略**：Cache-Aside、Read-Through、Write-Through

### 2. 内存管理
- **设置最大内存**：配置maxmemory参数
- **选择合适的淘汰策略**：LRU、LFU、TTL等
- **监控内存使用**：定期监控Redis内存使用

### 3. 高可用配置
- **主从复制**：配置主从复制，实现读写分离
- **哨兵模式**：配置哨兵，实现自动故障转移
- **集群模式**：数据量大时使用集群分片

### 4. 性能优化
- **使用管道**：批量执行命令，减少网络往返
- **避免大键**：单个键的值不要过大
- **选择合适数据结构**：根据场景选择最合适的数据结构
- **使用连接池**：复用Redis连接

### 5. 监控与维护
- **监控指标**：内存使用、连接数、命中率、延迟
- **慢查询日志**：开启并分析慢查询
- **定期备份**：定期备份Redis数据

## 【常见错误】

### 1. 缓存穿透
- **错误**：查询不存在的数据，导致每次都访问数据库
- **正确**：缓存空值或使用布隆过滤器

### 2. 缓存雪崩
- **错误**：大量缓存同时过期
- **正确**：使用随机TTL

### 3. 大键问题
- **错误**：单个键存储过多数据
- **正确**：拆分大键，避免阻塞

### 4. 忽略持久化
- **错误**：不配置持久化，重启后数据丢失
- **正确**：根据需求配置RDB和AOF

## 总结

Redis是高性能的的内存数据结构存储系统，可作为数据库、缓存和消息代理使用。掌握Redis数据结构、应用场景、Node.js客户端使用和最佳实践，可以显著提升应用性能和可扩展性。在Node.js后端开发中，Redis常用于缓存、会话存储、排行榜、计数器等场景。
