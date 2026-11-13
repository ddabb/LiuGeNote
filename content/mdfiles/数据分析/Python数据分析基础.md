---
title: Python数据分析基础
tags: [Python数据分析, 数据分析师, Python基础, NumPy, Pandas, 数据分析]
description: Python数据分析基础是使用Python进行数据分析的入门知识，包括NumPy、Pandas、Matplotlib等库的基本使用
---

# Python数据分析基础

## 定义

Python数据分析基础是**使用Python进行数据分析的入门知识**，包括NumPy、Pandas、Matplotlib等库的基本使用。

对于数据分析师而言，Python是**处理结构化数据、进行统计分析、可视化**的核心工具。

---

## 核心概念

### 1. Python数据分析常用库

| 库 | 说明 | 主要用途 |
|------|------|----------|
| **NumPy** | 科学计算基础库 | 数组操作、数学运算 |
| **Pandas** | 数据分析核心库 | 数据读取、清洗、转换、聚合 |
| **Matplotlib** | 数据可视化基础库 | 绘制基础图表 |
| **Seaborn** | 统计数据可视化库 | 绘制高级统计图表 |
| **Scikit-learn** | 机器学习库 | 数据挖掘、建模 |

### 2. Pandas数据结构

| 数据结构 | 说明 | 示例 |
|-----------|------|------|
| **Series** | 一维数组 | `s = pd.Series([1, 2, 3, 4])` |
| **DataFrame** | 二维表格 | `df = pd.DataFrame({'A': [1, 2], 'B': [3, 4]})` |

### 3. 数据读取

| 函数 | 说明 | 示例 |
|------|------|------|
| `pd.read_csv()` | 读取CSV文件 | `df = pd.read_csv('data.csv')` |
| `pd.read_excel()` | 读取Excel文件 | `df = pd.read_excel('data.xlsx')` |
| `pd.read_sql()` | 读取SQL查询结果 | `df = pd.read_sql(query, conn)` |

---

## 详细内容

### 一、NumPy基础

#### 1.1 创建数组

```python
import numpy as np

# 创建一维数组
arr1 = np.array([1, 2, 3, 4, 5])

# 创建二维数组
arr2 = np.array([[1, 2, 3], [4, 5, 6]])

# 创建全0数组
zeros = np.zeros((3, 4))

# 创建全1数组
ones = np.ones((3, 4))

# 创建等差数列数组
arange = np.arange(0, 10, 2)  # [0, 2, 4, 6, 8]
linspace = np.linspace(0, 10, 5)  # [0., 2.5, 5., 7.5, 10.]
```

#### 1.2 数组操作

```python
import numpy as np

arr = np.array([[1, 2, 3], [4, 5, 6]])

# 形状
print(arr.shape)  # (2, 3)

# 重塑形状
reshaped = arr.reshape((3, 2))

# 转置
transposed = arr.T

# 索引和切片
print(arr[0, 1])  # 2
print(arr[0, :])  # [1, 2, 3]
print(arr[:, 1])  # [2, 5]
```

#### 1.3 数学运算

```python
import numpy as np

arr1 = np.array([1, 2, 3])
arr2 = np.array([4, 5, 6])

# 加法
print(arr1 + arr2)  # [5, 7, 9]

# 减法
print(arr1 - arr2)  # [-3, -3, -3]

# 乘法（逐元素）
print(arr1 * arr2)  # [4, 10, 18]

# 除法（逐元素）
print(arr1 / arr2)  # [0.25, 0.4, 0.5]

# 矩阵乘法
print(np.dot(arr1, arr2))  # 32

# 聚合函数
print(np.sum(arr1))  # 6
print(np.mean(arr1))  # 2.0
print(np.std(arr1))  # 0.816496580927726
print(np.max(arr1))  # 3
print(np.min(arr1))  # 1
```

---

### 二、Pandas基础

#### 2.1 创建Series和DataFrame

```python
import pandas as pd

# 创建Series
s = pd.Series([1, 2, 3, 4], index=['a', 'b', 'c', 'd'])
print(s)
# a    1
# b    2
# c    3
# d    4
# dtype: int64

# 创建DataFrame
df = pd.DataFrame({
    'name': ['Alice', 'Bob', 'Charlie'],
    'age': [25, 30, 35],
    'city': ['New York', 'London', 'Tokyo']
})
print(df)
#       name  age      city
# 0    Alice   25  New York
# 1      Bob   30   London
# 2  Charlie   35    Tokyo
```

#### 2.2 数据读取

```python
import pandas as pd

# 读取CSV文件
df_csv = pd.read_csv('data.csv')

# 读取Excel文件
df_excel = pd.read_excel('data.xlsx', sheet_name='Sheet1')

# 读取SQL查询结果
import sqlite3
conn = sqlite3.connect('database.db')
query = "SELECT * FROM users"
df_sql = pd.read_sql(query, conn)
```

#### 2.3 数据查看

```python
import pandas as pd

# 读取数据
df = pd.read_csv('data.csv')

# 查看前N行
print(df.head(5))

# 查看后N行
print(df.tail(5))

# 查看形状
print(df.shape)

# 查看列名
print(df.columns)

# 查看索引
print(df.index)

# 查看数据类型
print(df.dtypes)

# 查看基本统计信息
print(df.describe())
```

#### 2.4 数据选择和过滤

```python
import pandas as pd

# 读取数据
df = pd.read_csv('data.csv')

# 选择单列
print(df['name'])

# 选择多列
print(df[['name', 'age']])

# 按标签选择行（loc）
print(df.loc[0])  # 第一行
print(df.loc[0:2, ['name', 'age']])  # 前三行的name和age列

# 按位置选择行（iloc）
print(df.iloc[0])  # 第一行
print(df.iloc[0:3, 0:2])  # 前三行的前两列

# 过滤行
print(df[df['age'] > 30])
print(df[(df['age'] > 30) & (df['city'] == 'New York')])
```

#### 2.5 数据清洗

```python
import pandas as pd
import numpy as np

# 读取数据
df = pd.read_csv('data.csv')

# 检查缺失值
print(df.isnull().sum())

# 删除缺失值
df_dropped = df.dropna()

# 填充缺失值
df_filled = df.fillna(0)  # 填充为0
df_filled = df.fillna(df.mean())  # 填充为均值

# 删除重复行
df_dedup = df.drop_duplicates()

# 重命名列
df_renamed = df.rename(columns={'name': 'full_name', 'age': 'age_years'})
```

#### 2.6 数据聚合

```python
import pandas as pd

# 读取数据
df = pd.read_csv('data.csv')

# 分组聚合
grouped = df.groupby('city')['age'].mean()
print(grouped)

# 多个聚合函数
aggregated = df.groupby('city').agg({
    'age': ['mean', 'max', 'min'],
    'salary': ['mean', 'sum']
})
print(aggregated)
```

---

### 三、Matplotlib基础

#### 3.1 绘制基础图表

```python
import matplotlib.pyplot as plt
import pandas as pd

# 读取数据
df = pd.read_csv('data.csv')

# 折线图
plt.plot(df['date'], df['sales'])
plt.xlabel('Date')
plt.ylabel('Sales')
plt.title('Sales Trend')
plt.show()

# 柱状图
plt.bar(df['category'], df['sales'])
plt.xlabel('Category')
plt.ylabel('Sales')
plt.title('Sales by Category')
plt.show()

# 直方图
plt.hist(df['age'], bins=10)
plt.xlabel('Age')
plt.ylabel('Frequency')
plt.title('Age Distribution')
plt.show()

# 散点图
plt.scatter(df['height'], df['weight'])
plt.xlabel('Height')
plt.ylabel('Weight')
plt.title('Height vs Weight')
plt.show()
```

---

## 示例/应用场景

### 示例1：电商用户行为分析 - 用户年龄分布

**业务问题**：分析电商用户的年龄分布。

**分析**：

```python
import pandas as pd
import matplotlib.pyplot as plt

# 读取用户数据
df = pd.read_csv('users.csv')

# 查看基本统计信息
print(df['age'].describe())

# 绘制年龄分布直方图
plt.hist(df['age'], bins=10)
plt.xlabel('Age')
plt.ylabel('Frequency')
plt.title('User Age Distribution')
plt.show()

# 计算各年龄段用户数
age_bins = [0, 18, 30, 50, 100]
age_labels = ['<18', '18-30', '30-50', '50+']
df['age_group'] = pd.cut(df['age'], bins=age_bins, labels=age_labels)
age_group_counts = df['age_group'].value_counts()
print(age_group_counts)

# 绘制年龄段分布柱状图
age_group_counts.plot(kind='bar')
plt.xlabel('Age Group')
plt.ylabel('Number of Users')
plt.title('User Age Group Distribution')
plt.show()
```

**洞察与建议**：
- 如果年轻用户（18-30）占比高，可以主打年轻人市场
- 如果中年用户（30-50）占比高，可以主打中年人市场

### 示例2：电商销售分析 - 月度销售趋势

**业务问题**：分析电商月度销售趋势。

**分析**：

```python
import pandas as pd
import matplotlib.pyplot as plt

# 读取销售数据
df = pd.read_csv('sales.csv')

# 将日期列转换为datetime类型
df['date'] = pd.to_datetime(df['date'])

# 按月份聚合销售额
df['month'] = df['date'].dt.to_period('M')
monthly_sales = df.groupby('month')['amount'].sum()

# 绘制月度销售趋势折线图
plt.plot(monthly_sales.index.to_timestamp(), monthly_sales.values)
plt.xlabel('Month')
plt.ylabel('Sales')
plt.title('Monthly Sales Trend')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# 计算环比增长率
monthly_sales_growth = monthly_sales.pct_change()
print(monthly_sales_growth)

# 绘制环比增长率折线图
plt.plot(monthly_sales_growth.index.to_timestamp(), monthly_sales_growth.values)
plt.xlabel('Month')
plt.ylabel('Growth Rate')
plt.title('Monthly Sales Growth Rate')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()
```

**洞察与建议**：
- 如果销售趋势上升，可以加大库存和营销投入
- 如果销售趋势下降，需要分析原因并调整策略

### 示例3：电商商品分析 - 商品销量TOP10

**业务问题**：分析电商商品销量TOP10。

**分析**：

```python
import pandas as pd
import matplotlib.pyplot as plt

# 读取商品销售数据
df = pd.read_csv('product_sales.csv')

# 按商品ID聚合销量
product_sales = df.groupby('product_id')['quantity'].sum()

# 排序并取TOP10
top10_products = product_sales.sort_values(ascending=False).head(10)

# 绘制商品销量TOP10柱状图
top10_products.plot(kind='bar')
plt.xlabel('Product ID')
plt.ylabel('Sales Quantity')
plt.title('Top 10 Products by Sales Quantity')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# 计算TOP10商品销量占比
total_sales = product_sales.sum()
top10_sales = top10_products.sum()
top10_ratio = top10_sales / total_sales
print(f'TOP10商品销量占比: {top10_ratio:.2%}')
```

**洞察与建议**：
- 可以加大TOP10商品的库存和推广力度
- 可以分析TOP10商品的特征，应用到其他商品

---

## 数据分析师考点

### Python数据分析基础常见考点

1. **Python数据分析常用库**：NumPy、Pandas、Matplotlib、Seaborn、Scikit-learn
2. **Pandas数据结构**：Series、DataFrame
3. **数据读取**：`pd.read_csv()`、`pd.read_excel()`、`pd.read_sql()`
4. **NumPy基础**：创建数组、数组操作、数学运算
5. **Pandas基础**：创建Series和DataFrame、数据读取、数据查看、数据选择和过滤、数据清洗、数据聚合
6. **Matplotlib基础**：绘制折线图、柱状图、直方图、散点图

### 实战考点

1. **电商用户行为分析**：
   - 如何使用Pandas读取用户数据
   - 如何使用Pandas进行数据清洗（处理缺失值、重复值等）
   - 如何使用Pandas进行数据聚合（按年龄段聚合等）
   - 如何使用Matplotlib绘制用户年龄分布直方图、年龄段分布柱状图
2. **电商销售分析**：
   - 如何使用Pandas读取销售数据
   - 如何使用Pandas进行数据聚合（按月份聚合销售额等）
   - 如何使用Matplotlib绘制月度销售趋势折线图、环比增长率折线图
3. **电商商品分析**：
   - 如何使用Pandas读取商品销售数据
   - 如何使用Pandas进行数据聚合（按商品ID聚合销量等）
   - 如何使用Matplotlib绘制商品销量TOP10柱状图

---

## 最佳实践

### 1. 使用合适的库，提高效率

**不推荐**（使用纯Python处理数据）：

```python
# 使用纯Python计算均值
data = [1, 2, 3, 4, 5]
mean = sum(data) / len(data)
```

**推荐**（使用NumPy或Pandas处理数据）：

```python
# 使用NumPy计算均值
import numpy as np
data = np.array([1, 2, 3, 4, 5])
mean = np.mean(data)

# 使用Pandas计算均值
import pandas as pd
data = pd.Series([1, 2, 3, 4, 5])
mean = data.mean()
```

### 2. 使用向量化操作，避免循环

**不推荐**（使用循环）：

```python
# 使用循环计算数组中每个元素的平方
import numpy as np
arr = np.array([1, 2, 3, 4, 5])
squared = np.zeros_like(arr)
for i in range(len(arr)):
    squared[i] = arr[i] ** 2
```

**推荐**（使用向量化操作）：

```python
# 使用向量化操作计算数组中每个元素的平方
import numpy as np
arr = np.array([1, 2, 3, 4, 5])
squared = arr ** 2
```

### 3. 使用链式操作，提高代码可读性

**不推荐**（不使用链式操作）：

```python
# 不使用链式操作
import pandas as pd
df = pd.read_csv('data.csv')
df = df.dropna()
df = df[df['age'] > 30]
result = df.groupby('city')['salary'].mean()
```

**推荐**（使用链式操作）：

```python
# 使用链式操作
import pandas as pd
result = (
    pd.read_csv('data.csv')
    .dropna()
    .query('age > 30')
    .groupby('city')['salary']
    .mean()
)
```

### 4. 使用合适的图表类型，提高可视化效果

**不推荐**（使用错误的图表类型）：

```python
# 使用折线图展示分类数据
import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv('data.csv')
plt.plot(df['category'], df['sales'])
plt.show()
```

**推荐**（使用合适的图表类型）：

```python
# 使用柱状图展示分类数据
import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv('data.csv')
plt.bar(df['category'], df['sales'])
plt.show()
```

---

## 常见错误

### 1. 使用纯Python处理数据，效率低下

**错误示例**：

```python
# 使用纯Python计算均值
data = [1, 2, 3, 4, 5]
mean = sum(data) / len(data)
```

**正确做法**：

```python
# 使用NumPy或Pandas处理数据
import numpy as np
data = np.array([1, 2, 3, 4, 5])
mean = np.mean(data)
```

### 2. 使用循环，效率低下

**错误示例**：

```python
# 使用循环计算数组中每个元素的平方
import numpy as np
arr = np.array([1, 2, 3, 4, 5])
squared = np.zeros_like(arr)
for i in range(len(arr)):
    squared[i] = arr[i] ** 2
```

**正确做法**：

```python
# 使用向量化操作计算数组中每个元素的平方
import numpy as np
arr = np.array([1, 2, 3, 4, 5])
squared = arr ** 2
```

### 3. 不使用链式操作，代码可读性差

**错误示例**：

```python
# 不使用链式操作
import pandas as pd
df = pd.read_csv('data.csv')
df = df.dropna()
df = df[df['age'] > 30]
result = df.groupby('city')['salary'].mean()
```

**正确做法**：

```python
# 使用链式操作
import pandas as pd
result = (
    pd.read_csv('data.csv')
    .dropna()
    .query('age > 30')
    .groupby('city')['salary']
    .mean()
)
```

### 4. 使用错误的图表类型，可视化效果差

**错误示例**：

```python
# 使用折线图展示分类数据
import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv('data.csv')
plt.plot(df['category'], df['sales'])
plt.show()
```

**正确做法**：

```python
# 使用柱状图展示分类数据
import matplotlib.pyplot as plt
import pandas as pd

df = pd.read_csv('data.csv')
plt.bar(df['category'], df['sales'])
plt.show()
```

### 5. 不处理缺失值，导致分析结果错误

**错误示例**：

```python
# 不处理缺失值，直接计算均值
import pandas as pd

df = pd.read_csv('data.csv')
mean = df['age'].mean()
```

**正确做法**：

```python
# 处理缺失值，再计算均值
import pandas as pd

df = pd.read_csv('data.csv')
df = df.dropna(subset=['age'])  # 删除age列缺失的行
mean = df['age'].mean()
```

---

## 总结

Python数据分析基础是数据分析师的必备技能，关键要点包括：

1. **掌握Python数据分析常用库**：NumPy、Pandas、Matplotlib、Seaborn、Scikit-learn
2. **理解Pandas数据结构**：Series、DataFrame
3. **熟练使用数据读取函数**：`pd.read_csv()`、`pd.read_excel()`、`pd.read_sql()`
4. **熟练使用NumPy基础**：创建数组、数组操作、数学运算
5. **熟练使用Pandas基础**：创建Series和DataFrame、数据读取、数据查看、数据选择和过滤、数据清洗、数据聚合
6. **熟练使用Matplotlib基础**：绘制折线图、柱状图、直方图、散点图
7. **注意最佳实践**：使用合适的库提高效率、使用向量化操作避免循环、使用链式操作提高代码可读性、使用合适的图表类型提高可视化效果
8. **避免常见错误**：使用纯Python处理数据效率低下、使用循环效率低下、不使用链式操作代码可读性差、使用错误的图表类型可视化效果差、不处理缺失值导致分析结果错误

Python数据分析基础是数据分析师的必备技能，需要在实践中不断积累经验。

---

## 扩展阅读

### 高级主题

1. **Pandas高级操作**：多层索引、透视表、交叉表
2. **Matplotlib高级操作**：子图、自定义样式、注解
3. **Seaborn高级可视化**：热力图、配对图、分类图
4. **Scikit-learn机器学习入门**：线性回归、逻辑回归、决策树

### 实战案例

1. **电商用户行为分析**：用户年龄分布、用户活跃度分析、用户留存分析
2. **电商销售分析**：月度销售趋势、销售渠道分析、销售预测
3. **电商商品分析**：商品销量TOP10、商品关联分析、商品评论分析

---

**注**：本文件内容适用于所有需要使用Python进行数据分析的场景，是数据分析师的必备基础知识。

---
