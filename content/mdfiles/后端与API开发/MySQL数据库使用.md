---
title: MySQL数据库使用
tags: [Node.js, MySQL, 关系型数据库, 后端开发, 数据库, SQL, ORM, Sequelize]
description: MySQL数据库使用 定义 MySQL是一个开源的关系型数据库管理系统（RDBMS），使用SQL（Structured Query Language）进行数据操作。在Node.js后端开发中，MySQ
---

# MySQL数据库使用

## 定义

MySQL是一个开源的关系型数据库管理系统（RDBMS），使用SQL（Structured Query Language）进行数据操作。在Node.js后端开发中，MySQL常用于存储结构化数据，如用户信息、订单数据等。

## 核心概念

### 1. 数据库连接
- **定义**：建立Node.js应用与MySQL服务器的连接
- **方式**：使用连接池或单个连接
- **配置**：主机、端口、用户名、密码、数据库名

### 2. SQL查询
- **定义**：使用SQL语句操作数据库
- **类型**：SELECT（查询）、INSERT（插入）、UPDATE（更新）、DELETE（删除）
- **参数化查询**：使用参数防止SQL注入

### 3. ORM（对象关系映射）
- **定义**：将数据库表映射为程序中的对象
- **常见ORM**：Sequelize、TypeORM、Prisma
- **优势**：简化数据库操作，减少SQL编写

### 4. 事务（Transaction）
- **定义**：一组操作，要么全部成功，要么全部失败
- **ACID特性**：原子性、一致性、隔离性、持久性
- **使用场景**：转账、订单创建等需要数据一致性的操作

## 详细内容

### Node.js中操作MySQL的方式

1. **使用原生驱动**
   - **mysql2**：流行的MySQL驱动
   - **优点**：轻量、直接、高性能
   - **缺点**：需要手写SQL，容易出错

2. **使用ORM**
   - **Sequelize**：流行的Node.js ORM
   - **优点**：简化操作，模型定义，关系管理
   - **缺点**：性能略低，学习成本

3. **使用查询构建器**
   - **Knex.js**：SQL查询构建器
   - **优点**：灵活，可手写SQL也可构建查询
   - **缺点**：需要了解SQL

### 数据库连接池

**为什么需要连接池**：
- 创建数据库连接开销大
- 连接池复用连接，提高性能
- 限制最大连接数，防止数据库过载

**配置参数**：
- `connectionLimit`：最大连接数
- `queueLimit`：队列长度限制
- `acquireTimeout`：获取连接超时时间

### SQL注入防护

**SQL注入**：
- 攻击者通过在输入中插入恶意SQL代码
- 可以窃取、修改或删除数据

**防护措施**：
1. **参数化查询**：使用`?`占位符
2. **存储过程**：使用预编译的SQL
3. **输入验证**：验证所有用户输入
4. **最小权限**：数据库用户只授予必要权限

## 示例/应用场景

### 示例1：使用mysql2进行基本操作

**安装**：
```bash
npm install mysql2
```

**连接数据库**：
```javascript
const mysql = require('mysql2/promise');

// 创建连接池
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'password',
  database: 'myapp',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// 查询数据
async function getUsers() {
  try {
    const [rows, fields] = await pool.execute(
      'SELECT * FROM users WHERE status = ?',
      ['active']
    );
    return rows;
  } catch (error) {
    console.error('查询用户失败:', error);
    throw error;
  }
}

// 插入数据
async function createUser(user) {
  try {
    const [result] = await pool.execute(
      'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
      [user.name, user.email, user.password]
    );
    return result.insertId;
  } catch (error) {
    console.error('创建用户失败:', error);
    throw error;
  }
}

// 更新数据
async function updateUser(id, updates) {
  try {
    const [result] = await pool.execute(
      'UPDATE users SET name = ?, email = ? WHERE id = ?',
      [updates.name, updates.email, id]
    );
    return result.affectedRows;
  } catch (error) {
    console.error('更新用户失败:', error);
    throw error;
  }
}

// 删除数据
async function deleteUser(id) {
  try {
    const [result] = await pool.execute(
      'DELETE FROM users WHERE id = ?',
      [id]
    );
    return result.affectedRows;
  } catch (error) {
    console.error('删除用户失败:', error);
    throw error;
  }
}

module.exports = { getUsers, createUser, updateUser, deleteUser };
```

### 示例2：使用Sequelize ORM

**安装**：
```bash
npm install sequelize sequelize-cli mysql2
```

**定义模型**：
```javascript
const { Sequelize, DataTypes } = require('sequelize');

// 创建Sequelize实例
const sequelize = new Sequelize('myapp', 'root', 'password', {
  host: 'localhost',
  dialect: 'mysql',
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});

// 定义User模型
const User = sequelize.define('User', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  email: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
    validate: {
      isEmail: true
    }
  },
  password: {
    type: DataTypes.STRING,
    allowNull: false
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive'),
    defaultValue: 'active'
  }
}, {
  tableName: 'users',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

// 同步模型到数据库
(async () => {
  await sequelize.sync({ force: false });
  console.log('数据库同步完成');
})();

// 使用模型
async function getUsers() {
  try {
    const users = await User.findAll({
      where: { status: 'active' }
    });
    return users;
  } catch (error) {
    console.error('查询用户失败:', error);
    throw error;
  }
}

async function createUser(userData) {
  try {
    const user = await User.create(userData);
    return user;
  } catch (error) {
    console.error('创建用户失败:', error);
    throw error;
  }
}

module.exports = { User, getUsers, createUser };
```

## 【Node.js后端开发】最佳实践

### 1. 数据库连接管理
- **使用连接池**：提高性能，防止连接泄露
- **正确处理连接**：使用try-catch-finally或async/await确保连接释放
- **监控连接**：监控连接池状态，及时调整配置

### 2. SQL查询优化
- **使用索引**：为常用查询字段创建索引
- **避免SELECT ***：只查询需要的字段
- **分页查询**：大数据集使用LIMIT分页
- **使用EXPLAIN**：分析查询性能

### 3. 安全防护
- **参数化查询**：防止SQL注入
- **输入验证**：验证所有用户输入
- **最小权限**：数据库用户只授予必要权限
- **敏感数据加密**：密码使用bcrypt等加密存储

### 4. 错误处理
- **统一错误处理**：捕获并处理数据库错误
- **错误日志**：记录数据库错误信息
- **优雅降级**：数据库不可用时提供降级服务

### 5. 性能优化
- **读写分离**：主库写，从库读
- **数据库分片**：数据量大时考虑分片
- **缓存策略**：使用Redis缓存热点数据
- **连接池调优**：根据负载调整连接池配置

## 【常见错误】

### 1. SQL注入
- **错误**：拼接SQL字符串
- **正确**：使用参数化查询

### 2. 连接泄露
- **错误**：不释放数据库连接
- **正确**：使用连接池，确保连接释放

### 3. 忽略索引
- **错误**：不为常用查询字段创建索引
- **正确**：分析查询，创建合适索引

### 4. 过度查询
- **错误**：查询不需要的数据
- **正确**：只查询需要的字段，使用分页

## 总结

MySQL是Node.js后端开发中常用的关系型数据库，通过原生驱动或ORM进行操作。掌握数据库连接管理、SQL查询编写、事务处理、性能优化和安全防护，是构建高质量数据访问层的基础。遵循最佳实践，可以确保数据库操作的高效性、安全性和可维护性。
