---
title: SQL窗口函数
tags: [SQL数据库, 数据分析师, 窗口函数, SQL高级查询, 数据分析]
description: 窗口函数（Window Function）在保留明细数据的同时进行聚合计算，是数据分析师处理复杂排名、趋势、同比环比等场景的核心技能
---

# SQL窗口函数

## 定义

窗口函数（Window Function）是**在保留明细数据的同时进行聚合计算**的SQL功能。

对于数据分析师而言，窗口函数是**处理复杂排名、趋势、同比环比**等场景的核心技能，避免了自连接或子查询的复杂性。

---

## 核心概念

### 1. 窗口函数的基本语法

```sql
函数名(列名) OVER (
    PARTITION BY 分区列
    ORDER BY 排序列
    ROWS/RANGE 窗口范围
)
```

**关键点**：
- **OVER子句**：定义窗口范围
- **PARTITION BY**：分区（类似GROUP BY，但不聚合）
- **ORDER BY**：排序
- **ROWS/RANGE**：定义窗口范围（如前行到后行）

### 2. 窗口函数的类型

| 类型 | 函数 | 说明 |
|------|------|------|
| **排序窗口函数** | `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()` | 排名 |
| **聚合窗口函数** | `SUM() OVER(...)`, `AVG() OVER(...)`, `COUNT() OVER(...)` | 聚合计算 |
| **取值窗口函数** | `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()` | 取前后行的值 |
| **分布窗口函数** | `NTILE()` | 分桶 |

### 3. 窗口范围（ROWS vs RANGE）

| 关键字 | 说明 |
|--------|------|
| **ROWS** | 物理行范围（如前行3行到后1行） |
| **RANGE** | 逻辑范围（如当前值±10） |

**示例**：
```sql
ROWS BETWEEN 3 PRECEDING AND 1 FOLLOWING  -- 前行3行到后1行
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW  -- 从开头到当前行
```

---

## 详细内容

### 一、排序窗口函数

#### 1.1 ROW_NUMBER()

**功能**：为每一行分配唯一的序号（连续不跳号）

**示例**：
```sql
-- 为每个部门的员工按薪资降序排名
SELECT 
    dept,
    name,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
FROM employees;
```

**结果示例**：
| dept | name | salary | rn |
|------|-------|--------|-----|
| IT | 张三 | 10000 | 1 |
| IT | 李四 | 9000 | 2 |
| IT | 王五 | 9000 | 3 |  ← 注意：薪资相同，序号不同

#### 1.2 RANK()

**功能**：排名（有跳号）

**示例**：
```sql
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees;
```

**结果示例**：
| dept | name | salary | rk |
|------|-------|--------|-----|
| IT | 张三 | 10000 | 1 |
| IT | 李四 | 9000 | 2 |
| IT | 王五 | 9000 | 2 |  ← 注意：薪资相同，排名相同
| IT | 赵六 | 8000 | 4 |  ← 注意：跳号了

#### 1.3 DENSE_RANK()

**功能**：排名（无跳号）

**示例**：
```sql
SELECT 
    dept,
    name,
    salary,
    DENSE_RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS drk
FROM employees;
```

**结果示例**：
| dept | name | salary | drk |
|------|-------|--------|-----|
| IT | 张三 | 10000 | 1 |
| IT | 李四 | 9000 | 2 |
| IT | 王五 | 9000 | 2 |  ← 注意：薪资相同，排名相同
| IT | 赵六 | 8000 | 3 |  ← 注意：没有跳号

---

### 二、聚合窗口函数

#### 2.1 SUM() OVER(...)

**功能**：计算累计和、移动和等

**示例**：
```sql
-- 计算员工薪资的累计和（按入职时间排序）
SELECT 
    name,
    hire_date,
    salary,
    SUM(salary) OVER (ORDER BY hire_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_salary
FROM employees;
```

#### 2.2 AVG() OVER(...)

**功能**：计算移动平均等

**示例**：
```sql
-- 计算员工薪资的移动平均（前3行到当前行）
SELECT 
    name,
    hire_date,
    salary,
    AVG(salary) OVER (ORDER BY hire_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_salary
FROM employees;
```

---

### 三、取值窗口函数

#### 3.1 LAG()

**功能**：取前N行的值

**示例**：
```sql
-- 计算本月销售额与上月销售额的差值
SELECT 
    month,
    sales,
    LAG(sales, 1) OVER (ORDER BY month) AS prev_month_sales,
    sales - LAG(sales, 1) OVER (ORDER BY month) AS sales_growth
FROM monthly_sales;
```

#### 3.2 LEAD()

**功能**：取后N行的值

**示例**：
```sql
-- 计算本月销售额与下月销售额的差值
SELECT 
    month,
    sales,
    LEAD(sales, 1) OVER (ORDER BY month) AS next_month_sales,
    LEAD(sales, 1) OVER (ORDER BY month) - sales AS sales_growth_next
FROM monthly_sales;
```

---

### 四、分布窗口函数

#### 4.1 NTILE()

**功能**：将数据集分成N个桶，并为每一行分配桶号

**示例**：
```sql
-- 将员工按薪资分成4个桶（四分位数）
SELECT 
    name,
    salary,
    NTILE(4) OVER (ORDER BY salary DESC) AS salary_quartile
FROM employees;
```

---

## 示例/应用场景

### 示例1：电商用户行为分析 - 计算用户购买频次排名

**业务问题**：计算每个用户在某段时间内的购买频次，并按购买频次排名。

**分析**：

```sql
-- 假设orders表有用户ID字段：user_id，下单时间字段：order_time
SELECT 
    user_id,
    COUNT(*) AS purchase_frequency,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS frequency_rank
FROM orders
WHERE order_time >= '2023-01-01' AND order_time < '2024-01-01'
GROUP BY user_id
ORDER BY frequency_rank;
```

**洞察与建议**：
- 可以识别高频购买用户（购买频次排名靠前），进行精准营销
- 可以识别低频购买用户（购买频次排名靠后），进行唤醒营销

### 示例2：电商销售分析 - 计算销售额的累计和、移动平均

**业务问题**：计算2023年每月的销售额累计和、移动平均（前3个月到当月）。

**分析**：

```sql
-- 假设monthly_sales表有月份字段：month，销售额字段：sales
SELECT 
    month,
    sales,
    SUM(sales) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    AVG(sales) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_sales
FROM monthly_sales
WHERE month >= '2023-01' AND month <= '2023-12'
ORDER BY month;
```

**洞察与建议**：
- 可以识别销售额的增长趋势（累计和）
- 可以平滑销售额的波动（移动平均）

### 示例3：电商商品分析 - 计算商品销量的同比增长率

**业务问题**：计算2023年每月每个商品的销量同比增长率（同比=今年本月销量 vs 去年本月销量）。

**分析**：

```sql
-- 假设monthly_product_sales表有月份字段：month，商品ID字段：product_id，销量字段：sales_volume
WITH current_year AS (
    SELECT 
        month,
        product_id,
        sales_volume
    FROM monthly_product_sales
    WHERE month >= '2023-01' AND month <= '2023-12'
),
prev_year AS (
    SELECT 
        month,
        product_id,
        sales_volume
    FROM monthly_product_sales
    WHERE month >= '2022-01' AND month <= '2022-12'
)
SELECT 
    c.month,
    c.product_id,
    c.sales_volume AS current_sales_volume,
    p.sales_volume AS prev_sales_volume,
    (c.sales_volume - p.sales_volume) / p.sales_volume AS yoy_growth_rate
FROM current_year c
LEFT JOIN prev_year p ON c.product_id = p.product_id 
    AND SUBSTR(c.month, 6, 2) = SUBSTR(p.month, 6, 2)  -- 匹配同月份
ORDER BY c.month, c.product_id;
```

**注意**：上述查询使用了自连接，如果使用窗口函数LAG()，可以更简洁：

```sql
-- 使用LAG()窗口函数
SELECT 
    month,
    product_id,
    sales_volume AS current_sales_volume,
    LAG(sales_volume, 12) OVER (PARTITION BY product_id ORDER BY month) AS prev_year_sales_volume,
    (sales_volume - LAG(sales_volume, 12) OVER (PARTITION BY product_id ORDER BY month)) / 
    LAG(sales_volume, 12) OVER (PARTITION BY product_id ORDER BY month) AS yoy_growth_rate
FROM monthly_product_sales
WHERE month >= '2023-01' AND month <= '2023-12'
ORDER BY month, product_id;
```

**洞察与建议**：
- 可以识别销量同比增长率高的商品，加大推广力度
- 可以识别销量同比增长率为负的商品，分析原因并优化

---

## 数据分析师考点

### SQL窗口函数常见考点

1. **窗口函数的基本语法**：`函数名(列名) OVER (PARTITION BY 分区列 ORDER BY 排序列 ROWS/RANGE 窗口范围)`
2. **窗口函数的类型**：排序窗口函数、聚合窗口函数、取值窗口函数、分布窗口函数
3. **排序窗口函数**：`ROW_NUMBER()`、`RANK()`、`DENSE_RANK()`
4. **聚合窗口函数**：`SUM() OVER(...)`、`AVG() OVER(...)`、`COUNT() OVER(...)`
5. **取值窗口函数**：`LAG()`、`LEAD()`、`FIRST_VALUE()`、`LAST_VALUE()`
6. **分布窗口函数**：`NTILE()`
7. **窗口范围**：`ROWS`、`RANGE`、`PRECEDING`、`FOLLOWING`、`CURRENT ROW`、`UNBOUNDED PRECEDING`、`UNBOUNDED FOLLOWING`
8. **窗口函数的应用场景**：排名、累计和、移动平均、同比环比、增长率等

### 实战考点

1. **电商用户行为分析**：
   - 如何计算用户购买频次排名
   - 如何计算用户活跃度排名
   - 如何计算用户价值排名（RFM模型）
2. **电商销售分析**：
   - 如何计算销售额的累计和、移动平均
   - 如何计算销售额的同比增长率、环比增长率
   - 如何计算销售额的占比（如每月销售额占全年销售额的比例）
3. **电商商品分析**：
   - 如何计算商品销量的排名
   - 如何计算商品销量的同比增长率、环比增长率
   - 如何计算商品销量的移动平均

---

## 最佳实践

### 1. 选择合适的排序窗口函数（ROW_NUMBER vs RANK vs DENSE_RANK）

**不推荐**（盲目使用ROW_NUMBER()）：

```sql
-- 如果需要排名，但使用了ROW_NUMBER()，导致排名不准确的场景（如同分不同排名）
SELECT 
    dept,
    name,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
FROM employees;
```

**推荐**（根据业务需求选择合适的排序窗口函数）：

```sql
-- 如果需要排名，且同分同名，使用RANK()或DENSE_RANK()
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees;
```

### 2. 注意窗口范围的正确使用

**不推荐**（不正确使用窗口范围）：

```sql
-- 错误：没有指定窗口范围，默认是RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
SELECT 
    month,
    sales,
    SUM(sales) OVER (ORDER BY month) AS cumulative_sales
FROM monthly_sales;
```

**推荐**（明确指定窗口范围）：

```sql
-- 正确：明确指定窗口范围
SELECT 
    month,
    sales,
    SUM(sales) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM monthly_sales;
```

### 3. 使用窗口函数替代自连接或子查询，提高代码可读性和性能

**不推荐**（使用自连接或子查询）：

```sql
-- 使用自连接计算本月销售额与上月销售额的差值
SELECT 
    c.month,
    c.sales,
    p.sales AS prev_month_sales,
    c.sales - p.sales AS sales_growth
FROM monthly_sales c
LEFT JOIN monthly_sales p ON c.month = DATE_ADD(p.month, INTERVAL 1 MONTH);
```

**推荐**（使用窗口函数LAG()）：

```sql
-- 使用窗口函数LAG()计算本月销售额与上月销售额的差值
SELECT 
    month,
    sales,
    LAG(sales, 1) OVER (ORDER BY month) AS prev_month_sales,
    sales - LAG(sales, 1) OVER (ORDER BY month) AS sales_growth
FROM monthly_sales;
```

### 4. 注意窗口函数与GROUP BY的区别

**不推荐**（混淆窗口函数与GROUP BY）：

```sql
-- 错误：窗口函数不会减少行数，GROUP BY会减少行数
-- 如果既要排名又要保留明细，应该使用窗口函数，而不是GROUP BY
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees
GROUP BY dept;  -- 错误：GROUP BY会与窗口函数冲突
```

**推荐**（正确使用窗口函数）：

```sql
-- 正确：窗口函数不会减少行数，可以保留明细
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees;
```

---

## 常见错误

### 1. 混淆ROW_NUMBER()、RANK()、DENSE_RANK()

**错误示例**：

```sql
-- 错误：需要排名且同分同名，但使用了ROW_NUMBER()
SELECT 
    dept,
    name,
    salary,
    ROW_NUMBER() OVER (PARTITION BY dept ORDER BY salary DESC) AS rn
FROM employees;
```

**正确做法**：

```sql
-- 正确：根据业务需求选择合适的排序窗口函数
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees;
```

### 2. 不正确使用窗口范围

**错误示例**：

```sql
-- 错误：没有指定窗口范围，默认是RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
SELECT 
    month,
    sales,
    SUM(sales) OVER (ORDER BY month) AS cumulative_sales
FROM monthly_sales;
```

**正确做法**：

```sql
-- 正确：明确指定窗口范围
SELECT 
    month,
    sales,
    SUM(sales) OVER (ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM monthly_sales;
```

### 3. 使用自连接或子查询，而不使用窗口函数

**错误示例**：

```sql
-- 错误：使用自连接计算本月销售额与上月销售额的差值
SELECT 
    c.month,
    c.sales,
    p.sales AS prev_month_sales,
    c.sales - p.sales AS sales_growth
FROM monthly_sales c
LEFT JOIN monthly_sales p ON c.month = DATE_ADD(p.month, INTERVAL 1 MONTH);
```

**正确做法**：

```sql
-- 正确：使用窗口函数LAG()计算本月销售额与上月销售额的差值
SELECT 
    month,
    sales,
    LAG(sales, 1) OVER (ORDER BY month) AS prev_month_sales,
    sales - LAG(sales, 1) OVER (ORDER BY month) AS sales_growth
FROM monthly_sales;
```

### 4. 混淆窗口函数与GROUP BY

**错误示例**：

```sql
-- 错误：窗口函数不会减少行数，GROUP BY会减少行数
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees
GROUP BY dept;  -- 错误：GROUP BY会与窗口函数冲突
```

**正确做法**：

```sql
-- 正确：窗口函数不会减少行数，可以保留明细
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees;
```

### 5. 在WHERE子中使用窗口函数

**错误示例**：

```sql
-- 错误：不能在WHERE子中使用窗口函数
SELECT 
    dept,
    name,
    salary,
    RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
FROM employees
WHERE RANK() OVER (PARTITION BY dept ORDER BY salary DESC) <= 3;  -- 错误
```

**正确做法**：

```sql
-- 正确：使用子查询或CTE
WITH ranked_employees AS (
    SELECT 
        dept,
        name,
        salary,
        RANK() OVER (PARTITION BY dept ORDER BY salary DESC) AS rk
    FROM employees
)
SELECT *
FROM ranked_employees
WHERE rk <= 3;
```

---

## 总结

窗口函数是数据分析师的高级技能，关键要点包括：

1. **掌握窗口函数的基本语法**：`函数名(列名) OVER (PARTITION BY 分区列 ORDER BY 排序列 ROWS/RANGE 窗口范围)`
2. **理解窗口函数的类型**：排序窗口函数、聚合窗口函数、取值窗口函数、分布窗口函数
3. **熟练使用排序窗口函数**：`ROW_NUMBER()`、`RANK()`、`DENSE_RANK()`
4. **熟练使用聚合窗口函数**：`SUM() OVER(...)`、`AVG() OVER(...)`、`COUNT() OVER(...)`
5. **熟练使用取值窗口函数**：`LAG()`、`LEAD()`、`FIRST_VALUE()`、`LAST_VALUE()`
6. **熟练使用分布窗口函数**：`NTILE()`
7. **理解窗口范围**：`ROWS`、`RANGE`、`PRECEDING`、`FOLLOWING`、`CURRENT ROW`、`UNBOUNDED PRECEDING`、`UNBOUNDED FOLLOWING`
8. **注意最佳实践**：选择合适的排序窗口函数、注意窗口范围的正确使用、使用窗口函数替代自连接或子查询提高代码可读性和性能、注意窗口函数与GROUP BY的区别
9. **避免常见错误**：混淆ROW_NUMBER()、RANK()、DENSE_RANK()、不正确使用窗口范围、使用自连接或子查询而不使用窗口函数、混淆窗口函数与GROUP BY、在WHERE子中使用窗口函数

窗口函数是数据分析师的必备高级技能，需要在实践中不断积累经验。

---

## 扩展阅读

### 高级主题

1. **高级窗口范围**：`ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`、`RANGE BETWEEN INTERVAL '1' YEAR PRECEDING AND CURRENT ROW`
2. **高级窗口函数**：`PERCENT_RANK()`、`CUME_DIST()`
3. **窗口函数与CTE结合**：使用WITH语句创建临时结果集，然后在外部查询中使用窗口函数
4. **窗口函数性能优化**：使用合适的索引、避免不必要的分区和排序

### 实战案例

1. **电商用户行为分析**：用户购买频次排名、用户活跃度排名、用户价值排名（RFM模型）
2. **电商销售分析**：销售额的累计和、移动平均、同比增长率、环比增长率、占比
3. **电商商品分析**：商品销量排名、商品销量同比增长率、环比增长率、移动平均
4. **金融数据分析**：股票价格排名、收益率排名、风险指标排名

---

**注**：本文件内容适用于所有需要使用窗口函数的分析场景，是数据分析师的必备高级知识。

---
