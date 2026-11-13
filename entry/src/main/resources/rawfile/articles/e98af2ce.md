
# SQL基础查询

## 定义

**SQL基础查询**是使用**SELECT**语句从数据库中查询数据的基本操作。

对于数据分析师而言，掌握**SQL基础查询**，是**从数据库中提取、筛选、汇总数据**的关键技能。

---

## 核心概念

### 1. SELECT语句基本结构

| 子句 | 说明 | 示例 |
|------|------|------|
| **SELECT** | 指定要查询的列 | `SELECT 列1, 列2` |
| **FROM** | 指定要查询的表 | `FROM 表名` |
| **WHERE** | 指定查询条件 | `WHERE 条件` |
| **GROUP BY** | 按指定列分组 | `GROUP BY 列1, 列2` |
| **HAVING** | 指定分组后的筛选条件 | `HAVING 条件` |
| **ORDER BY** | 指定排序方式 | `ORDER BY 列1 ASC/DESC` |
| **LIMIT** | 限制返回行数 | `LIMIT 数量` |

### 2. 常用运算符

| 运算符类型 | 运算符 | 说明 |
|-------------|--------|------|
| **比较运算符** | `=`, `!=`, `>`, `<`, `>=`, `<=` | 比较值 |
| **逻辑运算符** | `AND`, `OR`, `NOT` | 组合条件 |
| **模糊匹配** | `LIKE`, `NOT LIKE` | 模糊匹配 |
| **范围查询** | `BETWEEN...AND...`, `NOT BETWEEN...AND...` | 范围查询 |
| **列表查询** | `IN`, `NOT IN` | 列表查询 |
| **空值判断** | `IS NULL`, `IS NOT NULL` | 空值判断 |

### 3. 常用聚合函数

| 函数 | 说明 | 示例 |
|------|------|------|
| **COUNT()** | 计数 | `COUNT(*)` 或 `COUNT(列名)` |
| **SUM()** | 求和 | `SUM(列名)` |
| **AVG()** | 平均值 | `AVG(列名)` |
| **MAX()** | 最大值 | `MAX(列名)` |
| **MIN()** | 最小值 | `MIN(列名)` |

---

## 详细内容

### 一、SELECT语句基本用法

#### 1.1 查询所有列

```sql
SELECT * FROM 表名;
```

**示例**：
```sql
-- 查询所有员工信息
SELECT * FROM employees;
```

#### 1.2 查询指定列

```sql
SELECT 列1, 列2, ... FROM 表名;
```

**示例**：
```sql
-- 查询员工姓名和工资
SELECT employee_name, salary FROM employees;
```

#### 1.3 使用别名

```sql
SELECT 列名 AS 别名 FROM 表名;
```

**示例**：
```sql
-- 查询员工姓名和工资，并使用别名
SELECT employee_name AS 姓名, salary AS 工资 FROM employees;
```

---

### 二、WHERE子句

#### 2.1 比较运算符

```sql
SELECT 列1, 列2, ... 
FROM 表名 
WHERE 条件;
```

**示例**：
```sql
-- 查询工资大于5000的员工
SELECT * FROM employees 
WHERE salary > 5000;
```

#### 2.2 逻辑运算符

```sql
SELECT 列1, 列2, ... 
FROM 表名 
WHERE 条件1 AND/OR 条件2;
```

**示例**：
```sql
-- 查询工资大于5000且部门为IT的员工
SELECT * FROM employees 
WHERE salary > 5000 AND department = 'IT';
```

#### 2.3 模糊匹配（LIKE）

```sql
SELECT 列1, 列2, ... 
FROM 表名 
WHERE 列名 LIKE '模式';
```

**通配符**：
- `%`：匹配任意多个字符（包括0个）
- `_`：匹配一个字符

**示例**：
```sql
-- 查询姓名以'张'开头的员工
SELECT * FROM employees 
WHERE employee_name LIKE '张%';

-- 查询姓名第二个字为'小'的员工
SELECT * FROM employees 
WHERE employee_name LIKE '_小%';
```

#### 2.4 范围查询（BETWEEN...AND...）

```sql
SELECT 列1, 列2, ... 
FROM 表名 
WHERE 列名 BETWEEN 值1 AND 值2;
```

**示例**：
```sql
-- 查询工资在5000到10000之间的员工
SELECT * FROM employees 
WHERE salary BETWEEN 5000 AND 10000;
```

#### 2.5 列表查询（IN）

```sql
SELECT 列1, 列2, ... 
FROM 表名 
WHERE 列名 IN (值1, 值2, ...);
```

**示例**：
```sql
-- 查询部门为IT或HR的员工
SELECT * FROM employees 
WHERE department IN ('IT', 'HR');
```

#### 2.6 空值判断（IS NULL / IS NOT NULL）

```sql
SELECT 列1, 列2, ... 
FROM 表名 
WHERE 列名 IS NULL;
```

**示例**：
```sql
-- 查询没有填写邮箱的员工
SELECT * FROM employees 
WHERE email IS NULL;
```

---

### 三、GROUP BY子句和聚合函数

#### 3.1 使用聚合函数

```sql
SELECT 聚合函数(列名) 
FROM 表名;
```

**示例**：
```sql
-- 查询员工总数
SELECT COUNT(*) AS 员工总数 
FROM employees;

-- 查询平均工资
SELECT AVG(salary) AS 平均工资 
FROM employees;

-- 查询最高工资和最低工资
SELECT MAX(salary) AS 最高工资, MIN(salary) AS 最低工资 
FROM employees;
```

#### 3.2 GROUP BY子句

```sql
SELECT 列名, 聚合函数(列名) 
FROM 表名 
GROUP BY 列名;
```

**示例**：
```sql
-- 查询各部门的平均工资
SELECT department, AVG(salary) AS 平均工资 
FROM employees 
GROUP BY department;
```

#### 3.3 HAVING子句

```sql
SELECT 列名, 聚合函数(列名) 
FROM 表名 
GROUP BY 列名 
HAVING 聚合函数(列名) 条件;
```

**示例**：
```sql
-- 查询平均工资大于8000的部门
SELECT department, AVG(salary) AS 平均工资 
FROM employees 
GROUP BY department 
HAVING AVG(salary) > 8000;
```

**注意**：WHERE和HAVING的区别
- WHERE：在分组前筛选数据
- HAVING：在分组后筛选数据

---

### 四、ORDER BY子句和LIMIT子句

#### 4.1 ORDER BY子句

```sql
SELECT 列1, 列2, ... 
FROM 表名 
ORDER BY 列名 ASC/DESC;
```

**示例**：
```sql
-- 查询员工信息，按工资升序排序
SELECT * FROM employees 
ORDER BY salary ASC;

-- 查询员工信息，按工资降序排序
SELECT * FROM employees 
ORDER BY salary DESC;

-- 查询员工信息，先按部门升序，再按工资降序
SELECT * FROM employees 
ORDER BY department ASC, salary DESC;
```

#### 4.2 LIMIT子句

```sql
SELECT 列1, 列2, ... 
FROM 表名 
LIMIT 数量;
```

**示例**：
```sql
-- 查询工资最高的前10名员工
SELECT * FROM employees 
ORDER BY salary DESC 
LIMIT 10;
```

---

## 示例/应用场景

### 示例1：电商销售数据分析

**业务问题**：分析电商销售数据，查询销售额TOP10的商品。

**数据**：电商销售数据表（商品ID、商品名称、销售额、销量）

**分析**：

**SQL查询**：
```sql
SELECT 
    product_id AS 商品ID,
    product_name AS 商品名称,
    sales_amount AS 销售额,
    sales_volume AS 销量
FROM 
    sales_data
ORDER BY 
    sales_amount DESC
LIMIT 10;
```

**洞察与建议**：
- 如果某商品销售额高，说明该商品受欢迎
- 可以针对高销售额商品制定营销策略
- 可以分析高销售额商品的特征，优化商品推荐

### 示例2：电商用户行为分析

**业务问题**：分析电商用户行为，查询各用户类型的访问量和转化率。

**数据**：电商用户行为数据表（用户ID、用户类型、访问量、转化量）

**分析**：

**SQL查询**：
```sql
SELECT 
    user_type AS 用户类型,
    SUM(visit_count) AS 总访问量,
    SUM(conversion_count) AS 总转化量,
    SUM(conversion_count) / SUM(visit_count) AS 转化率
FROM 
    user_behavior_data
GROUP BY 
    user_type
HAVING 
    SUM(visit_count) > 1000;
```

**洞察与建议**：
- 如果某用户类型转化率高，说明该用户类型用户质量高
- 可以针对高转化率用户类型制定精准营销策略
- 可以分析高转化率用户的行为特征，优化产品推荐策略

### 示例3：电商商品价格分析

**业务问题**：分析电商商品价格，查询各品类商品价格分布。

**数据**：电商商品价格数据表（商品ID、品类、价格）

**分析**：

**SQL查询**：
```sql
SELECT 
    category AS 品类,
    AVG(price) AS 平均价格,
    MAX(price) AS 最高价格,
    MIN(price) AS 最低价格,
    STDDEV(price) AS 价格标准差
FROM 
    product_price_data
GROUP BY 
    category
HAVING 
    STDDEV(price) > 100;
```

**洞察与建议**：
- 如果某品类价格标准差大，说明该品类价格差异大
- 可以针对价格差异大的品类制定统一的价格策略
- 可以分析价格差异的原因，优化产品定位

---

## 数据分析师考点

### SQL基础查询常见考点

1. **SELECT语句基本结构**：SELECT、FROM、WHERE、GROUP BY、HAVING、ORDER BY、LIMIT
2. **常用运算符**：比较运算符、逻辑运算符、模糊匹配、范围查询、列表查询、空值判断
3. **常用聚合函数**：COUNT()、SUM()、AVG()、MAX()、MIN()
4. **SQL基础查询应用**：电商销售数据分析、电商用户行为分析、电商商品价格分析

### 实战考点

1. **电商销售分析**：
   - 如何使用SQL查询销售额TOP10的商品
   - 如何计算各品类销售额占比
   - 如何根据分析结果制定营销策略
2. **电商用户分析**：
   - 如何使用SQL查询各用户类型的访问量和转化率
   - 如何计算用户留存率
   - 如何根据用户行为分析制定用户运营策略
3. **电商商品分析**：
   - 如何使用SQL查询各品类商品价格分布
   - 如何计算商品价格波动系数
   - 如何根据价格分析制定价格策略

---

## 最佳实践

### 1. 使用明确的列名，避免使用SELECT *

**不推荐**（使用SELECT *）：
```sql
SELECT * FROM employees;
```

**推荐**（使用明确的列名）：
```sql
SELECT employee_id, employee_name, salary 
FROM employees;
```

### 2. 使用别名提高可读性

**不推荐**（不使用别名）：
```sql
SELECT department, AVG(salary) 
FROM employees 
GROUP BY department;
```

**推荐**（使用别名）：
```sql
SELECT department AS 部门, AVG(salary) AS 平均工资 
FROM employees 
GROUP BY department;
```

### 3. 正确使用WHERE和HAVING

**不推荐**（混淆WHERE和HAVING）：
```sql
SELECT department, AVG(salary) 
FROM employees 
WHERE AVG(salary) > 8000 
GROUP BY department;
```

**推荐**（正确使用WHERE和HAVING）：
```sql
SELECT department, AVG(salary) AS 平均工资 
FROM employees 
GROUP BY department 
HAVING AVG(salary) > 8000;
```

### 4. 结合业务场景解释查询结果

**不推荐**（只报告查询结果）：
```sql
-- 查询结果为：IT部门平均工资为9000
```

**推荐**（结合业务场景解释查询结果）：
```sql
-- IT部门平均工资为9000，说明IT部门员工薪资水平较高。
-- 可以根据此结果调整薪资结构，或制定更有竞争力的薪资政策。
```

---

## 常见错误

### 1. 使用SELECT * 查询所有列

**错误示例**：
```sql
SELECT * FROM employees;
```

**正确做法**：
```sql
SELECT employee_id, employee_name, salary 
FROM employees;
```

### 2. 混淆WHERE和HAVING

**错误示例**：
```sql
SELECT department, AVG(salary) 
FROM employees 
WHERE AVG(salary) > 8000 
GROUP BY department;
```

**正确做法**：
```sql
SELECT department, AVG(salary) AS 平均工资 
FROM employees 
GROUP BY department 
HAVING AVG(salary) > 8000;
```

### 3. 不正确使用GROUP BY

**错误示例**：
```sql
SELECT department, employee_name, AVG(salary) 
FROM employees 
GROUP BY department;
```

**正确做法**：
```sql
SELECT department, AVG(salary) AS 平均工资 
FROM employees 
GROUP BY department;
```

### 4. 不结合业务场景解释查询结果

**错误示例**：
```sql
-- 查询结果为：IT部门平均工资为9000
```

**正确做法**：
```sql
-- IT部门平均工资为9000，说明IT部门员工薪资水平较高。
-- 可以根据此结果调整薪资结构，或制定更有竞争力的薪资政策。
```

### 5. 不正确使用LIMIT

**错误示例**：
```sql
-- 想要查询工资最高的前10名员工，但写法错误
SELECT * FROM employees 
LIMIT 10 
ORDER BY salary DESC;
```

**正确做法**：
```sql
-- 正确写法：先排序，再限制返回行数
SELECT * FROM employees 
ORDER BY salary DESC 
LIMIT 10;
```

---

## 总结

SQL基础查询是数据分析师操作数据库的基本技能，关键要点包括：

1. **掌握SELECT语句基本结构**：SELECT、FROM、WHERE、GROUP BY、HAVING、ORDER BY、LIMIT
2. **掌握常用运算符**：比较运算符、逻辑运算符、模糊匹配、范围查询、列表查询、空值判断
3. **掌握常用聚合函数**：COUNT()、SUM()、AVG()、MAX()、MIN()
4. **熟练应用SQL基础查询**：电商销售数据分析、电商用户行为分析、电商商品价格分析
5. **注意最佳实践**：使用明确的列名避免使用SELECT *、使用别名提高可读性、正确使用WHERE和HAVING、结合业务场景解释查询结果
6. **避免常见错误**：使用SELECT *查询所有列、混淆WHERE和HAVING、不正确使用GROUP BY、不结合业务场景解释查询结果、不正确使用LIMIT

SQL基础查询是数据分析师的必备技能，需要在实践中不断积累经验。

---

## 扩展阅读

### 高级主题

1. **SQL多表连接**：INNER JOIN、LEFT JOIN、RIGHT JOIN、FULL JOIN
2. **SQL子查询**：单行子查询、多行子查询、多列子查询
3. **SQL窗口函数**：ROW_NUMBER()、RANK()、DENSE_RANK()、NTILE()
4. **SQL性能优化**：索引、查询计划、SQL优化技巧

### 实战案例

1. **电商销售分析**：销售趋势分析、品类对比分析、地区销售分析
2. **电商用户分析**：用户行为分析、用户画像分析、用户流失分析
3. **电商商品分析**：商品价格分析、商品销量预测、商品推荐分析
4. **金融数据分析**：股票价格分析、风险分析、投资组合分析

---

**注**：本文件内容适用于所有需要使用SQL进行数据查询和分析的场景，是数据分析师的必备技能。
