---
title: MongoDB使用
tags: [Node.js, MongoDB, NoSQL, 文档数据库, 后端开发, 数据库, Mongoose]
description: MongoDB使用 定义 MongoDB是一个开源的文档型NoSQL数据库，使用JSON风格的文档存储数据。它具有高灵活性、可扩展性和高性能，适合处理非结构化或半结构化数据。 核心概念 1. 文档（D
---

# MongoDB使用

## 定义

MongoDB是一个开源的文档型NoSQL数据库，使用JSON风格的文档存储数据。它具有高灵活性、可扩展性和高性能，适合处理非结构化或半结构化数据。

## 核心概念

### 1. 文档（Document）
- **定义**：MongoDB中的数据基本单位，类似JSON对象
- **格式**：BSON（Binary JSON），支持更多数据类型
- **示例**：`{ "name": "张三", "age": 30, "email": "zhangsan@example.com" }`

### 2. 集合（Collection）
- **定义**：文档的容器，类似关系型数据库中的表
- **特点**：无固定模式，文档可以有不同结构
- **示例**：`users`集合可以包含不同结构的用户文档

### 3. 数据库（Database）
- **定义**：集合的容器
- **特点**：一个MongoDB实例可以包含多个数据库
- **示例**：`myapp`数据库包含`users`、`products`等集合

### 4. ObjectId
- **定义**：MongoDB自动生成的唯一标识符
- **特点**：12字节，包含时间戳、机器标识、进程ID、计数器
- **用途**：作为文档的主键

## 详细内容

### MongoDB应用场景

1. **内容管理系统**
   - **优势**：灵活的数据模型，适合多样化内容
   - **示例**：博客文章、新闻、产品目录

2. **实时分析**
   - **优势**：高性能读写，聚合框架
   - **示例**：用户行为分析、日志分析

3. **物联网应用**
   - **优势**：高吞吐量写入，灵活模式
   - **示例**：传感器数据存储、设备监控

4. **移动应用后端**
   - **优势**：快速开发，可扩展
   - **示例**：用户数据、社交网络数据

### Node.js中操作MongoDB

1. **使用官方驱动**
   - **mongodb**：MongoDB官方Node.js驱动
   - **优点**：功能完整，性能高
   - **缺点**：需要手写查询，较底层

2. **使用ODM**
   - **Mongoose**：流行的MongoDB ODM（对象文档映射）
   - **优点**：Schema定义，数据验证，中间件
   - **缺点**：性能略低，学习成本

3. **使用查询构建器**
   - **mongodb-query-builder**：构建复杂查询
   - **优点**：灵活构建查询
   - **缺点**：需要了解MongoDB查询语法

### MongoDB vs 关系型数据库

| 特性 | MongoDB | 关系型数据库（MySQL） |
|------|---------|----------------------|
| 数据模型 | 文档（JSON风格） | 表（行和列） |
| 模式 | 灵活，无固定模式 | 固定模式 |
| 查询语言 | MongoDB查询语言 | SQL |
| 事务 | 支持（4.0+） | 完善支持 |
| 扩展性 | 水平扩展（分片） | 垂直扩展为主 |
| 适用场景 | 非结构化数据、快速迭代 | 结构化数据、复杂事务 |

## 示例/应用场景

### 示例1：使用Mongoose ODM

**安装**：
```bash
npm install mongoose
```

**连接数据库**：
```javascript
const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/myapp', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

const db = mongoose.connection;
db.on('error', console.error.bind(console, '连接错误:'));
db.once('open', () => {
  console.log('数据库连接成功');
});
```

**定义Schema和Model**：
```javascript
const mongoose = require('mongoose');

// 定义用户Schema
const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  age: {
    type: Number,
    min: 0,
    max: 120
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// 定义中间件（预保存钩子）
userSchema.pre('save', function(next) {
  console.log('即将保存用户:', this.name);
  next();
});

// 定义实例方法
userSchema.methods.getInfo = function() {
  return `${this.name} (${this.email})`;
};

// 定义静态方法
userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email });
};

// 创建User模型
const User = mongoose.model('User', userSchema);

module.exports = User;
```

**使用模型**：
```javascript
const User = require('./models/User');

// 创建用户
async function createUser(userData) {
  try {
    const user = new User(userData);
    await user.save();
    console.log('用户创建成功:', user);
    return user;
  } catch (error) {
    console.error('创建用户失败:', error);
    throw error;
  }
}

// 查询用户
async function getUsers() {
  try {
    const users = await User.find({ age: { $gte: 18 } })
      .sort({ createdAt: -1 })
      .limit(10);
    return users;
  } catch (error) {
    console.error('查询用户失败:', error);
    throw error;
  }
}

// 更新用户
async function updateUser(id, updates) {
  try {
    const user = await User.findByIdAndUpdate(
      id,
      updates,
      { new: true, runValidators: true }
    );
    return user;
  } catch (error) {
    console.error('更新用户失败:', error);
    throw error;
  }
}

// 删除用户
async function deleteUser(id) {
  try {
    await User.findByIdAndDelete(id);
    console.log('用户删除成功');
  } catch (error) {
    console.error('删除用户失败:', error);
    throw error;
  }
}

module.exports = { createUser, getUsers, updateUser, deleteUser };
```

### 示例2：聚合查询

```javascript
const User = require('./models/User');
const Order = require('./models/Order');

// 聚合查询：统计每个用户的订单总金额
async function getUserOrderStats() {
  try {
    const stats = await Order.aggregate([
      // 第一阶段：按用户ID分组，计算订单总金额
      {
        $group: {
          _id: '$userId',
          totalAmount: { $sum: '$amount' },
          orderCount: { $sum: 1 }
        }
      },
      // 第二阶段：连接用户集合
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'user'
        }
      },
      // 第三阶段：展开用户数组
      {
        $unwind: '$user'
      },
      // 第四阶段：投影，只返回需要的字段
      {
        $project: {
          _id: 0,
          userId: '$_id',
          userName: '$user.name',
          userEmail: '$user.email',
          totalAmount: 1,
          orderCount: 1
        }
      },
      // 第五阶段：按订单总金额降序排序
      {
        $sort: { totalAmount: -1 }
      }
    ]);
    
    return stats;
  } catch (error) {
    console.error('统计用户订单失败:', error);
    throw error;
  }
}
```

## 【Node.js后端开发】最佳实践

### 1. Schema设计
- **根据查询模式设计**：考虑常见查询，优化Schema
- **避免过度嵌套**：嵌套文档不要太深
- **使用引用还是嵌入**：根据数据关系和查询需求决定
- **考虑文档大小限制**：单个文档不超过16MB

### 2. 索引优化
- **为常用查询字段创建索引**
- **使用复合索引**：支持多个字段的查询
- **注意索引顺序**：等值查询字段在前，范围查询字段在后
- **监控索引使用**：使用`explain()`分析查询

### 3. 性能优化
- **使用投影**：只返回需要的字段
- **限制结果集**：使用`limit()`和`skip()`分页
- **避免大型结果集**：分批处理大量数据
- **使用聚合管道**：复杂查询使用聚合框架

### 4. 数据安全
- **输入验证**：使用Mongoose验证或自定义验证
- **防注入**：使用Mongoose或官方驱动，避免拼接查询
- **敏感数据加密**：密码使用bcrypt加密
- **访问控制**：实现合适的访问控制策略

### 5. 监控与维护
- **监控性能指标**：查询时间、索引使用、内存使用
- **定期备份**：使用`mongodump`备份数据
- **更新MongoDB版本**：保持MongoDB版本更新
- **监控日志**：监控MongoDB日志，及时发现问题

## 【常见错误】

### 1. 过度使用嵌套
- **错误**：嵌套文档过深，导致查询复杂
- **正确**：合理设计Schema，使用引用

### 2. 忽略索引
- **错误**：不为常用查询字段创建索引
- **正确**：分析查询，创建合适索引

### 3. 大型结果集
- **错误**：一次查询返回大量数据
- **正确**：使用分页或流式处理

### 4. 忽略数据验证
- **错误**：不验证输入数据
- **正确**：使用Mongoose验证或自定义验证

## 总结

MongoDB是灵活的文档型NoSQL数据库，适合处理非结构化或半结构化数据。通过Mongoose ODM或官方驱动，可以在Node.js中方便地操作MongoDB。掌握MongoDB核心概念、Schema设计、查询优化和最佳实践，是构建高性能、可扩展Node.js应用的重要技能。
