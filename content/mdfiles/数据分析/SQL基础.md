---
title: SQL基础
tags: [SQL数据库, 数据分析师, SQL基础, SELECT, WHERE]
description: SQL基础是数据分析师操作关系型数据库的核心技能，包括SELECT、WHERE、ORDER BY、GROUP BY等基础语法
---

# SQL基础

## 定义

SQL（Structured Query Language，结构化查询语言）是用于操作关系型数据库的标准语言。

对于数据分析师而言，SQL 是日常工作中使用频率最高的技能——几乎所有业务数据都存储在数据库中，需要通过 SQL 查询、提取、分析数据。

---

## 核心概念

### 1. SQL 语句的分类

| 分类 | 说明 | 常用语句 |
|------|------|----------|
| **DQL（Data Query Language）** | 数据查询 | `SELECT` |
| **DML（Data Manipulation Language）** | 数据操作 | `INSERT`、`UPDATE`、`DELETE` |
| **DDL（Data Definition Language）** | 数据定义 | `CREATE`、`ALTER`、`DROP` |
| **DCL（Data Control Language）** | 数据控制 | `GRANT`、`REVKE` |
| **TCL（Transaction Control Language）** | 事务控制 | `COMMIT`、`ROLLBACK` |

**数据分析师重点**：DQL（`SELECT`）是最常用的，DML 中的 `INSERT`、`UPDATE`、`DELETE` 有时也会用到。

### 2. SELECT 语句的执行顺序

```sql
SELECT DISTINCT 列名          -- 5. 选择列（去重）
FROM 表名                   -- 1. 确定数据来源
WHERE 条件                  -- 2. 过滤行
GROUP BY 列名               -- 3. 分组
HAVING 条件                -- 4. 过滤组
ORDER BY 列名               -- 6. 排序
LIMIT 行数;                -- 7. 限制返回行数
```

**重要**：书写顺序不等于执行顺序！上面的编号是实际执行顺序。

### 3. 基础语法规则

- SQL 语句**不区分大小写**（但习惯上关键字大写，表名、列名小写）
- 一条 SQL 语句以**分号 `;`** 结束（有些数据库不需要）
- 注释：
  - 单行注释：`-- 这是注释`
  - 多行注释：`/* 这是注释 */`

---

## 详细内容

### 一、基础查询（SELECT ... FROM）

#### 1.1 查询所有列

```sql
SELECT * FROM employees;
```

**说明**：`*` 表示所有列。

**不推荐**：生产环境中不建议使用 `*`，因为：
1. 可能返回不必要的列，浪费性能
2. 如果表结构变化（增加/删除列），`*` 的结果也会变化，可能导致程序出错

**推荐**：明确指定列名

```sql
SELECT employee_id, first_name, last_name, salary
FROM employees;
```

#### 1.2 列别名（AS）

```sql
SELECT 
    first_name AS "名",
    last_name AS "姓",
    salary AS "工资"
FROM employees;
```

**说明**：
- `AS` 可以省略（`first_name "名"` 也可以）
- 如果别名包含空格或特殊字符，需要用双引号括起来

#### 1.3 去除重复行（DISTINCT）

```sql
-- 查询所有不同的部门ID
SELECT DISTINCT department_id
FROM employees;
```

**注意**：`DISTINCT` 作用于**所有选中的列**，而不仅仅是第一列。

```sql
-- 查询所有不同的"部门ID + 职位ID"组合
SELECT DISTINCT department_id, job_id
FROM employees;
```

---

### 二、过滤数据（WHERE）

#### 2.1 比较运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `=` | 等于 | `WHERE salary = 5000` |
| `<>` 或 `!=` | 不等于 | `WHERE salary <> 5000` |
| `>` | 大于 | `WHERE salary > 5000` |
| `<` | 小于 | `WHERE salary < 5000` |
| `>=` | 大于等于 | `WHERE salary >= 5000` |
| `<=` | 小于等于 | `WHERE salary <= 5000` |

#### 2.2 逻辑运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `AND` | 逻辑与（同时满足） | `WHERE salary > 5000 AND department_id = 10` |
| `OR` | 逻辑或（满足任意一个） | `WHERE department_id = 10 OR department_id = 20` |
| `NOT` | 逻辑非（取反） | `WHERE NOT (salary > 5000)` |

**优先级**：`NOT` > `AND` > `OR`。建议使用括号明确优先级。

```sql
-- 不推荐（依赖默认优先级）
SELECT * FROM employees
WHERE salary > 5000 AND department_id = 10 OR department_id = 20;

-- 推荐（使用括号明确优先级）
SELECT * FROM employees
WHERE salary > 5000 AND (department_id = 10 OR department_id = 20);
```

#### 2.3 其他常用运算符

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `BETWEEN ... AND ...` | 在某个范围内（包含边界） | `WHERE salary BETWEEN 5000 AND 10000` |
| `IN (...)` | 在某个列表中 | `WHERE department_id IN (10, 20, 30)` |
| `LIKE` | 模糊匹配 | `WHERE first_name LIKE 'A%'` |
| `IS NULL` | 是 NULL | `WHERE department_id IS NULL` |
| `IS NOT NULL` | 不是 NULL | `WHERE department_id IS NOT NULL` |

**LIKE 通配符**：
- `%`：匹配任意长度的任意字符（包括0个）
- `_`：匹配单个任意字符

```sql
-- 查询名字以'A'开头的员工
SELECT * FROM employees
WHERE first_name LIKE 'A%';

-- 查询名字第二个字母是'a'的员工
SELECT * FROM employees
WHERE first_name LIKE '_a%';
```

---

### 三、排序（ORDER BY）

#### 3.1 单列排序

```sql
-- 按工资升序排序（默认升序）
SELECT first_name, salary
FROM employees
ORDER BY salary;

-- 按工资降序排序
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;
```

#### 3.2 多列排序

```sql
-- 先按部门ID升序，再按工资降序
SELECT first_name, department_id, salary
FROM employees
ORDER BY department_id ASC, salary DESC;
```

**说明**：多列排序时，先按第一列排序，第一列相同时再按第二列排序。

#### 3.3 按列位置排序

```sql
-- 按第2列（salary）排序
SELECT first_name, salary
FROM employees
ORDER BY 2 DESC;
```

**不推荐**：按列位置排序的可读性差，且如果 SELECT 列顺序变化，排序也会变化。

---

### 四、限制返回行数（LIMIT）

**注意**：不同数据库的限制返回行数语法不同。

| 数据库 | 语法 |
|--------|------|
| MySQL、PostgreSQL | `LIMIT n` |
| Oracle | `WHERE ROWNUM <= n` |
| SQL Server | `TOP n` 或 `OFFSET ... FETCH`（SQL Server 2012+） |

**MySQL / PostgreSQL**：

```sql
-- 返回前10行
SELECT * FROM employees
ORDER BY salary DESC
LIMIT 10;

-- 分页（跳过前10行，返回接下来10行）
SELECT * FROM employees
ORDER BY salary DESC
LIMIT 10 OFFSET 10;
-- 或简写
LIMIT 10, 10;  -- 第一个数是偏移量，第二个数是返回行数
```

---

### 五、条件表达式（CASE WHEN）

#### 5.1 简单 CASE 表达式

```sql
SELECT 
    first_name,
    salary,
    CASE department_id
        WHEN 10 THEN '行政部'
        WHEN 20 THEN '研发部'
        WHEN 30 THEN '销售部'
        ELSE '其他部门'
    END AS department_name
FROM employees;
```

#### 5.2 搜索 CASE 表达式（更灵活）

```sql
SELECT 
    first_name,
    salary,
    CASE 
        WHEN salary < 5000 THEN '低工资'
        WHEN salary BETWEEN 5000 AND 10000 THEN '中等工资'
        ELSE '高工资'
    END AS salary_level
FROM employees;
```

**说明**：`CASE WHEN` 可以用于 SELECT、WHERE、ORDER BY 等子句中。

---

## 示例/应用场景

### 示例1：电商订单分析

**需求**：查询2024年1月订单金额大于1000的订单，按订单金额降序排序，只返回前10条记录。

**涉及的表**：
- `orders`：订单表（订单ID、用户ID、订单金额、订单日期）

**SQL语句**：

```sql
SELECT 
    order_id,
    user_id,
    order_amount,
    order_date
FROM orders
WHERE order_date BETWEEN '2024-01-01' AND '2024-01-31'
  AND order_amount > 1000
ORDER BY order_amount DESC
LIMIT 10;
```

### 示例2：员工薪资分析

**需求**：查询工资在5000到10000之间，且属于"研发部"或"销售部"的员工姓名、部门名称、工资，按工资降序排序。

**涉及的表**：
- `employees`：员工表（员工ID、姓名、部门ID、工资）
- `departments`：部门表（部门ID、部门名称）

**SQL语句**：

```sql
SELECT 
    e.first_name,
    e.last_name,
    d.department_name,
    e.salary
FROM employees e
INNER JOIN departments d
  ON e.department_id = d.department_id
WHERE e.salary BETWEEN 5000 AND 10000
  AND d.department_name IN ('研发部', '销售部')
ORDER BY e.salary DESC;
```

### 示例3：用户活跃度分析

**需求**：查询2024年1月登录次数大于等于5次的用户ID和登录次数，按登录次数降序排序。

**涉及的表**：
- `user_login`：用户登录表（用户ID、登录日期）

**SQL语句**：

```sql
SELECT 
    user_id,
    COUNT(*) AS login_count
FROM user_login
WHERE login_date BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY user_id
HAVING COUNT(*) >= 5
ORDER BY login_count DESC;
```

---

## 数据分析师考点

### SQL基础常见考点

1. **SELECT 语句的执行顺序**：FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
2. **比较运算符和逻辑运算符**：`=`、`>`、`<`、`AND`、`OR`、`NOT`
3. **BETWEEN ... AND ...**：包含边界值
4. **IN (...)**：判断是否在列表中
5. **LIKE**：模糊匹配，`%` 匹配任意长度，`_` 匹配单个字符
6. **NULL 值判断**：用 `IS NULL` 或 `IS NOT NULL`，不能用 `= NULL`
7. **ORDER BY**：升序（ASC，默认）、降序（DESC）
8. **LIMIT**：限制返回行数（不同数据库语法不同）
9. **CASE WHEN**：条件表达式，用于条件判断

### 实战考点

1. **NULL 值的处理**：
   - NULL 表示"未知"，不是"空字符串"或"0"
   - NULL 与任何值比较都返回 NULL（不是 TRUE 也不是 FALSE）
   - 判断 NULL 必须用 `IS NULL` 或 `IS NOT NULL`
2. **列别名的使用位置**：
   - 列别名可以在 ORDER BY 中使用
   - 列别名不能在 WHERE 中使用（因为 WHERE 执行顺序早于 SELECT）
3. **BETWEEN ... AND ... 的边界**：包含边界值，如 `BETWEEN 1 AND 3` 等价于 `>= 1 AND <= 3`
4. **LIMIT 的分页用法**：`LIMIT offset, row_count` 或 `LIMIT row_count OFFSET offset`

---

## 最佳实践

### 1. 明确指定列名，避免使用 `SELECT *`

**不推荐**：
```sql
SELECT * FROM employees;
```

**推荐**：
```sql
SELECT employee_id, first_name, last_name, salary
FROM employees;
```

**理由**：
- 明确指定列名可以减少数据传输量，提升性能
- 如果表结构变化，`SELECT *` 的结果也会变化，可能导致程序出错

### 2. 使用列别名提升可读性

**不推荐**：
```sql
SELECT 
    COUNT(*)，
    AVG(salary)
FROM employees
GROUP BY department_id;
```

**推荐**：
```sql
SELECT 
    COUNT(*) AS employee_count,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id;
```

**理由**：列别名可以让结果更易读。

### 3. 使用 CASE WHEN 替代复杂的条件判断

**不推荐**（在 WHERE 中使用复杂的条件判断）：
```sql
SELECT * FROM employees
WHERE (salary < 5000)
   OR (salary BETWEEN 5000 AND 10000 AND department_id = 10)
   OR (salary > 10000 AND department_id IN (10, 20));
```

**推荐**（使用 CASE WHEN 在 SELECT 中分类）：
```sql
SELECT 
    first_name,
    salary,
    CASE 
        WHEN salary < 5000 THEN '低工资'
        WHEN salary BETWEEN 5000 AND 10000 THEN '中等工资'
        ELSE '高工资'
    END AS salary_level
FROM employees;
```

### 4. 注意 NULL 值的处理

**问题**：NULL 与任何值比较都返回 NULL，可能导致过滤失效。

**错误示例**：
```sql
-- 想查询没有分配部门的员工，但这样写会漏掉 department_id 为 NULL 的行
SELECT * FROM employees
WHERE department_id = NULL;  -- 错误！应该用 IS NULL
```

**正确做法**：
```sql
SELECT * FROM employees
WHERE department_id IS NULL;
```

---

## 常见错误

### 1. 在 WHERE 中使用列别名

**错误示例**：
```sql
-- 错误：WHERE 执行顺序早于 SELECT，不能使用列别名
SELECT 
    salary * 12 AS annual_salary
FROM employees
WHERE annual_salary > 60000;  -- 错误！
```

**正确做法**：
```sql
-- 方法1：在 WHERE 中重复表达式
SELECT 
    salary * 12 AS annual_salary
FROM employees
WHERE salary * 12 > 60000;

-- 方法2：使用派生表
SELECT * FROM (
    SELECT 
        salary * 12 AS annual_salary
    FROM employees
) t
WHERE annual_salary > 60000;
```

### 2. 混淆 NULL 值判断

**错误示例**：
```sql
-- 错误：不能用 = NULL 判断 NULL
SELECT * FROM employees
WHERE department_id = NULL;
```

**正确做法**：
```sql
SELECT * FROM employees
WHERE department_id IS NULL;
```

### 3. 忽略 BETWEEN ... AND ... 包含边界值

**错误理解**：认为 `BETWEEN 1 AND 3` 等价于 `> 1 AND < 3`（不包含边界）

**正确理解**：`BETWEEN 1 AND 3` 等价于 `>= 1 AND <= 3`（包含边界）

### 4. 在 WHERE 中使用聚合函数

**错误示例**：
```sql
-- 错误：WHERE 中不能使用聚合函数
SELECT department_id, AVG(salary)
FROM employees
WHERE AVG(salary) > 5000
GROUP BY department_id;
```

**正确做法**：
```sql
-- 使用 HAVING 过滤分组
SELECT department_id, AVG(salary) AS avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 5000;
```

### 5. 混淆 AND 和 OR 的优先级

**错误示例**：
```sql
-- 错误：想查询工资大于5000且部门为10或20的员工，但这样写会返回所有部门中工资大于5000的员工，以及部门为10或20的所有员工
SELECT * FROM employees
WHERE salary > 5000
  AND department_id = 10
  OR department_id = 20;
```

**正确做法**：
```sql
-- 使用括号明确优先级
SELECT * FROM employees
WHERE salary > 5000
  AND (department_id = 10 OR department_id = 20);
```

---

## 总结

SQL 基础是数据分析师操作关系型数据库的核心技能，关键要点包括：

1. **掌握 SELECT 语句的执行顺序**：FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT
2. **熟练使用 WHERE 过滤数据**：比较运算符、逻辑运算符、BETWEEN、IN、LIKE、IS NULL
3. **掌握 ORDER BY 排序**：升序（ASC）、降序（DESC）、多列排序
4. **掌握 LIMIT 限制返回行数**：不同数据库语法不同
5. **熟练使用 CASE WHEN 条件表达式**：用于条件判断
6. **注意 NULL 值的处理**：用 IS NULL 或 IS NOT NULL 判断

SQL 基础是数据分析师的必备技能，需要在实践中不断积累经验。

---

## 扩展阅读

### 高级主题

1. **多表连接（JOIN）**：INNER JOIN、LEFT JOIN、RIGHT JOIN、FULL JOIN、CROSS JOIN、SELF JOIN
2. **分组聚合（GROUP BY）**：GROUP BY、HAVING、聚合函数（SUM、AVG、COUNT、MAX、MIN）
3. **子查询（Subquery）**：WHERE 子句中的子查询、FROM 子句中的子查询（派生表）、SELECT 子句中的子查询
4. **窗口函数（Window Functions）**：ROW_NUMBER、RANK、DENSE_RANK、LAG、LEAD、SUM OVER

### 实战案例

1. **电商分析**：订单分析、用户行为分析、商品分析
2. **金融分析**：股票数据分析、风险分析、投资组合分析
3. **用户行为分析**：留存分析、漏斗分析、路径分析
4. **日志分析**：Web 日志分析、应用日志分析、异常检测

---

**注**：本文件内容适用于所有主流关系型数据库（MySQL、PostgreSQL、Oracle、SQL Server 等），部分数据库有特定的语法扩展。

---
