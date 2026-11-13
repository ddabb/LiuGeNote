---
title: Excel数据分析常用函数
tags: [Excel数据分析, 数据分析师, 常用函数, 查找函数, 逻辑函数, 文本函数, 日期时间函数, 数据分析]
description: Excel提供了丰富的数据分析函数，包括查找函数、逻辑函数、文本函数、日期时间函数等，掌握这些函数能有效提升数据分析效率
---

# Excel数据分析常用函数

## 定义

**Excel数据分析常用函数**包括**查找函数、逻辑函数、文本函数、日期时间函数**等。

对于数据分析师而言，掌握这些**常用函数**，是**提升Excel数据分析效率、解决复杂数据问题**的关键。

---

## 核心概念

### 1. 查找函数

| 函数 | 说明 | 语法 |
|------|------|------|
| **VLOOKUP** | 垂直查找 | `=VLOOKUP(lookup_value, table_array, col_index_num, [range_lookup])` |
| **HLOOKUP** | 水平查找 | `=HLOOKUP(lookup_value, table_array, row_index_num, [range_lookup])` |
| **XLOOKUP** | 高级查找（Office 365） | `=XLOOKUP(lookup_value, lookup_array, return_array, [if_not_found], [match_mode], [search_mode])` |
| **INDEX** | 返回指定位置的值 | `=INDEX(array, row_num, [column_num])` |
| **MATCH** | 返回指定值的位置 | `=MATCH(lookup_value, lookup_array, [match_type])` |

### 2. 逻辑函数

| 函数 | 说明 | 语法 |
|------|------|------|
| **IF** | 条件判断 | `=IF(logical_test, value_if_true, value_if_false)` |
| **IFS** | 多条件判断（Office 365） | `=IFS(logical_test1, value_if_true1, [logical_test2, value_if_true2], ...)` |
| **AND** | 逻辑与 | `=AND(logical1, [logical2], ...)` |
| **OR** | 逻辑或 | `=OR(logical1, [logical2], ...)` |
| **NOT** | 逻辑非 | `=NOT(logical)` |

### 3. 文本函数

| 函数 | 说明 | 语法 |
|------|------|------|
| **LEFT** | 提取左侧字符 | `=LEFT(text, [num_chars])` |
| **RIGHT** | 提取右侧字符 | `=RIGHT(text, [num_chars])` |
| **MID** | 提取中间字符 | `=MID(text, start_num, num_chars)` |
| **LEN** | 计算文本长度 | `=LEN(text)` |
| **TEXT** | 格式化文本 | `=TEXT(value, format_text)` |
| **TRIM** | 清除空格 | `=TRIM(text)` |
| **SUBSTITUTE** | 替换文本 | `=SUBSTITUTE(text, old_text, new_text, [instance_num])` |

### 4. 日期时间函数

| 函数 | 说明 | 语法 |
|------|------|------|
| **DATE** | 创建日期 | `=DATE(year, month, day)` |
| **YEAR** | 提取年份 | `=YEAR(serial_number)` |
| **MONTH** | 提取月份 | `=MONTH(serial_number)` |
| **DAY** | 提取日期 | `=DAY(serial_number)` |
| **TODAY** | 当前日期 | `=TODAY()` |
| **NOW** | 当前日期时间 | `=NOW()` |
| **DATEDIF** | 计算日期差 | `=DATEDIF(start_date, end_date, unit)` |

---

## 详细内容

### 一、查找函数

#### 1.1 VLOOKUP函数

**语法**：`=VLOOKUP(lookup_value, table_array, col_index_num, [range_lookup])`

**参数说明**：
- `lookup_value`：要查找的值
- `table_array`：查找范围
- `col_index_num`：返回值的列序号
- `range_lookup`：匹配模式（FALSE为精确匹配，TRUE为近似匹配）

**示例**：
```excel
=VLOOKUP("苹果", A1:C10, 3, FALSE)
```
**说明**：在A1:C10区域的第一列查找"苹果"，返回第三列的值。

#### 1.2 XLOOKUP函数（Office 365）

**语法**：`=XLOOKUP(lookup_value, lookup_array, return_array, [if_not_found], [match_mode], [search_mode])`

**参数说明**：
- `lookup_value`：要查找的值
- `lookup_array`：查找数组
- `return_array`：返回数组
- `if_not_found`：未找到时返回的值
- `match_mode`：匹配模式（0为精确匹配，1为近似匹配）
- `search_mode`：搜索模式（1为从头到尾，-1为从尾到头）

**示例**：
```excel
=XLOOKUP("苹果", A1:A10, C1:C10, "未找到", 0, 1)
```
**说明**：在A1:A10区域查找"苹果"，返回C1:C10区域对应的值，未找到时返回"未找到"。

#### 1.3 INDEX+MATCH组合

**语法**：`=INDEX(return_array, MATCH(lookup_value, lookup_array, [match_type])`

**示例**：
```excel
=INDEX(C1:C10, MATCH("苹果", A1:A10, 0))
```
**说明**：在A1:A10区域查找"苹果"的位置，返回C1:C10区域对应位置的值。

---

### 二、逻辑函数

#### 2.1 IF函数

**语法**：`=IF(logical_test, value_if_true, value_if_false)`

**示例**：
```excel
=IF(A1>60, "及格", "不及格")
```
**说明**：如果A1大于60，返回"及格"，否则返回"不及格"。

#### 2.2 IFS函数（Office 365）

**语法**：`=IFS(logical_test1, value_if_true1, [logical_test2, value_if_true2], ...)`

**示例**：
```excel
=IFS(A1>90, "优秀", A1>80, "良好", A1>60, "及格", TRUE, "不及格")
```
**说明**：多条件判断，A1>90返回"优秀"，A1>80返回"良好"，A1>60返回"及格"，否则返回"不及格"。

#### 2.3 AND函数和OR函数

**示例1：AND函数**
```excel
=IF(AND(A1>60, B1>60), "及格", "不及格")
```
**说明**：如果A1和B1都大于60，返回"及格"，否则返回"不及格"。

**示例2：OR函数**
```excel
=IF(OR(A1>60, B1>60), "及格", "不及格")
```
**说明**：如果A1或B1大于60，返回"及格"，否则返回"不及格"。

---

### 三、文本函数

#### 3.1 LEFT、RIGHT、MID函数

**示例1：LEFT函数**
```excel
=LEFT(A1, 3)
```
**说明**：提取A1左侧3个字符。

**示例2：RIGHT函数**
```excel
=RIGHT(A1, 4)
```
**说明**：提取A1右侧4个字符。

**示例3：MID函数**
```excel
=MID(A1, 2, 3)
```
**说明**：从A1的第2个字符开始，提取3个字符。

#### 3.2 TEXT函数

**示例**：
```excel
=TEXT(A1, "yyyy-mm-dd")
```
**说明**：将A1格式化为"yyyy-mm-dd"格式的文本。

#### 3.3 TRIM函数和SUBSTITUTE函数

**示例1：TRIM函数**
```excel
=TRIM(A1)
```
**说明**：清除A1中的空格（仅保留单词间的单个空格）。

**示例2：SUBSTITUTE函数**
```excel
=SUBSTITUTE(A1, " ", "")
```
**说明**：将A1中的空格替换为空（清除所有空格）。

---

### 四、日期时间函数

#### 4.1 DATE、YEAR、MONTH、DAY函数

**示例1：DATE函数**
```excel
=DATE(2026, 6, 2)
```
**说明**：创建日期2026年6月2日。

**示例2：YEAR、MONTH、DAY函数**
```excel
=YEAR(A1)  // 提取年份
=MONTH(A1) // 提取月份
=DAY(A1)   // 提取日期
```

#### 4.2 DATEDIF函数

**语法**：`=DATEDIF(start_date, end_date, unit)`

**参数说明**：
- `start_date`：开始日期
- `end_date`：结束日期
- `unit`：单位（"Y"为年，"M"为月，"D"为天）

**示例**：
```excel
=DATEDIF(A1, B1, "D")
```
**说明**：计算A1和B1之间的天数差。

---

## 示例/应用场景

### 示例1：电商销售数据分析

**业务问题**：分析电商销售数据，根据销售额计算销售等级。

**数据**：电商销售数据（销售员、销售额）

**分析**：

**Excel公式**：
```excel
=IFS(
    B1>=1000000, "A级",
    B1>=500000, "B级",
    B1>=100000, "C级",
    TRUE, "D级"
)
```

**洞察与建议**：
- 如果某销售员等级高，说明该销售员销售业绩好
- 可以根据销售等级制定销售激励政策
- 可以分析销售等级分布，优化销售团队管理

### 示例2：电商用户行为分析

**业务问题**：分析电商用户行为，根据用户类型和行为类型计算转化率。

**数据**：电商用户行为数据（用户ID、用户类型、行为类型）

**分析**：

**Excel公式**：
```excel
=LET(
    data, A1:C1000,
    user_type, B1:B1000,
    behavior_type, C1:C1000,
    view_count, COUNTIFS(user_type, "新用户", behavior_type, "view"),
    purchase_count, COUNTIFS(user_type, "新用户", behavior_type, "purchase"),
    conversion, purchase_count/view_count,
    conversion
)
```

**洞察与建议**：
- 如果某用户类型转化率高，说明该用户类型用户质量高
- 可以针对高转化率用户类型制定精准营销策略
- 可以分析高转化率用户的行为特征，优化产品推荐策略

### 示例3：电商商品价格分析

**业务问题**：分析电商商品价格，根据价格区间计算商品等级。

**数据**：电商商品价格数据（商品ID、价格）

**分析**：

**Excel公式**：
```excel
=IFS(
    B1>=1000, "高端",
    B1>=500, "中端",
    B1>=100, "低端",
    TRUE, "超低端"
)
```

**洞察与建议**：
- 如果某商品等级高，说明该商品定位高端
- 可以根据商品等级制定差异化定价策略
- 可以分析不同等级商品的销售情况，优化商品结构

---

## 数据分析师考点

### Excel数据分析常用函数常见考点

1. **查找函数**：VLOOKUP、HLOOKUP、XLOOKUP、INDEX、MATCH
2. **逻辑函数**：IF、IFS、AND、OR、NOT
3. **文本函数**：LEFT、RIGHT、MID、LEN、TEXT、TRIM、SUBSTITUTE
4. **日期时间函数**：DATE、YEAR、MONTH、DAY、TODAY、NOW、DATEDIF
5. **Excel数据分析常用函数应用**：电商销售数据分析、电商用户行为分析、电商商品价格分析

### 实战考点

1. **电商销售分析**：
   - 如何使用Excel常用函数分析销售数据
   - 如何根据销售额计算销售等级
   - 如何根据销售等级制定销售激励政策
2. **电商用户分析**：
   - 如何使用Excel常用函数分析用户行为
   - 如何根据用户类型和行为类型计算转化率
   - 如何根据转化率制定精准营销策略
3. **电商商品分析**：
   - 如何使用Excel常用函数分析商品价格
   - 如何根据价格区间计算商品等级
   - 如何根据商品等级制定差异化定价策略

---

## 最佳实践

### 1. 根据数据特征，选择合适的函数

**不推荐**（盲目使用VLOOKUP函数）：

```
无论什么查找需求，都使用VLOOKUP函数。
```

**推荐**（根据数据特征，选择合适的函数）：

```
- 简单垂直查找 → VLOOKUP函数
- 高级查找（Office 365） → XLOOKUP函数
- 灵活查找 → INDEX+MATCH组合
```

### 2. 使用IFS函数替代嵌套IF函数

**不推荐**（嵌套IF函数）：

```
=IF(A1>90, "优秀", IF(A1>80, "良好", IF(A1>60, "及格", "不及格")))
```

**推荐**（使用IFS函数）：

```
=IFS(A1>90, "优秀", A1>80, "良好", A1>60, "及格", TRUE, "不及格")
```

### 3. 使用XLOOKUP函数替代VLOOKUP函数

**不推荐**（使用VLOOKUP函数）：

```
=VLOOKUP("苹果", A1:C10, 3, FALSE)
```

**推荐**（使用XLOOKUP函数）：

```
=XLOOKUP("苹果", A1:A10, C1:C10, "未找到", 0, 1)
```

### 4. 结合业务场景解释函数结果

**不推荐**（只报告函数结果）：

```
IF函数结果为"及格"。
```

**推荐**（结合业务场景解释函数结果）：

```
IF函数结果为"及格"，说明该学生成绩及格。可以根据此结果制定教学计划。
```

---

## 常见错误

### 1. 盲目使用某种函数

**错误示例**：

```
无论什么查找需求，都使用VLOOKUP函数。
```

**正确做法**：

```
根据数据特征，选择合适的函数。
```

### 2. 嵌套过多IF函数

**错误示例**：

```
=IF(A1>90, "优秀", IF(A1>80, "良好", IF(A1>60, "及格", "不及格")))
```

**正确做法**：

```
使用IFS函数替代嵌套IF函数。
```

### 3. 不使用XLOOKUP函数（Office 365用户）

**错误示例**：

```
使用VLOOKUP函数进行查找。
```

**正确做法**：

```
使用XLOOKUP函数替代VLOOKUP函数。
```

### 4. 不结合业务场景解释函数结果

**错误示例**：

```
IF函数结果为"及格"。
```

**正确做法**：

```
结合业务场景解释函数结果。
```

### 5. 日期时间函数使用错误

**错误示例**：

```
使用文本格式存储日期，导致日期计算错误。
```

**正确做法**：

```
使用日期时间函数处理日期，确保日期计算正确。
```

---

## 总结

Excel数据分析常用函数是数据分析师提升Excel数据分析效率的关键技能，关键要点包括：

1. **掌握查找函数**：VLOOKUP、HLOOKUP、XLOOKUP、INDEX、MATCH
2. **掌握逻辑函数**：IF、IFS、AND、OR、NOT
3. **掌握文本函数**：LEFT、RIGHT、MID、LEN、TEXT、TRIM、SUBSTITUTE
4. **掌握日期时间函数**：DATE、YEAR、MONTH、DAY、TODAY、NOW、DATEDIF
5. **熟练应用Excel数据分析常用函数**：电商销售数据分析、电商用户行为分析、电商商品价格分析
6. **注意最佳实践**：根据数据特征选择合适的函数、使用IFS函数替代嵌套IF函数、使用XLOOKUP函数替代VLOOKUP函数、结合业务场景解释函数结果
7. **避免常见错误**：盲目使用某种函数、嵌套过多IF函数、不使用XLOOKUP函数（Office 365用户）、不结合业务场景解释函数结果、日期时间函数使用错误

Excel数据分析常用函数是数据分析师的必备技能，需要在实践中不断积累经验。

---

## 扩展阅读

### 高级主题

1. **Excel高级函数组合**：结合多种函数解决复杂问题
2. **Excel数组函数**：使用数组函数进行批量计算
3. **Excel动态数组函数**：使用动态数组函数进行灵活计算
4. **Excel函数与VBA结合**：使用VBA扩展函数功能

### 实战案例

1. **电商销售分析**：销售趋势分析、品类对比分析、地区销售分析
2. **电商用户分析**：用户行为分析、用户画像分析、用户流失分析
3. **电商商品分析**：商品价格分析、商品销量预测、商品推荐分析
4. **金融数据分析**：股票价格分析、风险分析、投资组合分析

---

**注**：本文件内容适用于所有需要使用Excel常用函数进行数据分析的场景，是数据分析师的必备技能。
