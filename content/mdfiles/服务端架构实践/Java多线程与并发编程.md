---
title: Java多线程与并发编程
tags: [Java, 多线程, 并发编程, 线程池, 同步机制, 并发容器]
description: Java多线程编程核心技术，涵盖线程创建、同步机制、并发容器、性能优化和实战案例
---

# Java多线程与并发编程

## 定义

**多线程编程**是指在一个程序中**同时运行多个线程**，提高程序执行效率和资源利用率。

在零售电商系统中，多线程技术广泛应用于：**订单处理、库存扣减、支付回调、异步通知**等场景。

---

## 核心概念

### 1. 线程创建方式

| 创建方式 | 说明 | 适用场景 |
|----------|------|----------|
| **继承Thread类** | 重写run()方法 | 简单场景，不推荐 |
| **实现Runnable接口** | 实现run()方法 | 推荐方式，可继承其他类 |
| **实现Callable接口** | 实现call()方法，有返回值 | 需要返回结果的场景 |
| **线程池** | Executor框架 | 推荐方式，管理线程生命周期 |

### 2. 线程生命周期

```
新建（New）
  ↓
就绪（Runnable）
  ↓
运行（Running）
  ↓
阻塞（Blocked/Waiting/Timed_Waiting）
  ↓
终止（Terminated）
```

### 3. 同步机制

| 同步方式 | 说明 | 适用场景 |
|----------|------|----------|
| **synchronized** | JVM内置锁，可重入 | 简单同步场景 |
| **ReentrantLock** | JDK实现锁，功能更丰富 | 需要公平锁、超时锁等高级功能 |
| **ReadWriteLock** | 读写锁，读读不互斥 | 读多写少场景 |
| **StampedLock** | 乐观读锁，性能更好 | 读非常多、写很少场景 |

---

## 详细内容

### 1. 线程池技术

#### （1）线程池核心参数

```java
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    10,                          // corePoolSize：核心线程数
    50,                          // maximumPoolSize：最大线程数
    60L,                         // keepAliveTime：空闲线程存活时间
    TimeUnit.SECONDS,            // unit：时间单位
    new LinkedBlockingQueue<>(1000), // workQueue：工作队列
    new ThreadFactory() {},       // threadFactory：线程工厂
    new ThreadPoolExecutor.CallerRunsPolicy() // handler：拒绝策略
);
```

**参数说明**：
- **corePoolSize**：核心线程数，即使空闲也会保持存活
- **maximumPoolSize**：最大线程数，当工作队列满时创建
- **keepAliveTime**：非核心线程空闲存活时间
- **workQueue**：工作队列，存放待执行任务
- **threadFactory**：线程工厂，用于创建线程
- **handler**：拒绝策略，当线程池和工作队列都满时的处理策略

#### （2）拒绝策略

| 拒绝策略 | 说明 | 适用场景 |
|----------|------|----------|
| **AbortPolicy** | 抛出异常（默认） | 重要任务，不能丢失 |
| **CallerRunsPolicy** | 调用者线程执行 | 不丢失任务，但降低提交速度 |
| **DiscardPolicy** | 直接丢弃 | 不重要的任务 |
| **DiscardOldestPolicy** | 丢弃队列最老任务 | 允许丢失旧任务 |

#### （3）电商场景应用

**订单处理线程池**：
```java
// 订单处理线程池配置
ThreadPoolExecutor orderExecutor = new ThreadPoolExecutor(
    20,                          // 核心线程数：20
    100,                         // 最大线程数：100
    60L,                         // 空闲线程存活时间：60秒
    TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(5000), // 工作队列：5000
    new ThreadFactoryBuilder().setNameFormat("order-process-%d").build(),
    new ThreadPoolExecutor.CallerRunsPolicy() // 拒绝策略：调用者执行
);

// 提交订单处理任务
public void processOrder(Order order) {
    orderExecutor.submit(() -> {
        // 1. 库存扣减
        inventoryService.deduct(order);
        // 2. 支付处理
        paymentService.process(order);
        // 3. 订单状态更新
        orderService.updateStatus(order.getId(), OrderStatus.PROCESSING);
    });
}
```

### 2. 同步机制详解

#### （1）synchronized关键字

**用法**：
```java
// 1. 实例方法同步（锁当前实例）
public synchronized void processOrder() {
    // 同步代码
}

// 2. 静态方法同步（锁当前Class对象）
public static synchronized void resetCounter() {
    // 同步代码
}

// 3. 代码块同步（锁指定对象）
public void processOrder() {
    synchronized (this) {
        // 同步代码
    }
}
```

**电商场景**：库存扣减
```java
public class InventoryService {
    // 库存扣减（线程安全）
    public synchronized boolean deduct(Long itemId, Integer quantity) {
        Item item = itemDao.getById(itemId);
        if (item.getStock() >= quantity) {
            item.setStock(item.getStock() - quantity);
            itemDao.update(item);
            return true;
        }
        return false;
    }
}
```

#### （2）ReentrantLock

**优势**：
- 可中断等待
- 可超时获取锁
- 可尝试获取锁
- 可实现公平锁
- 可绑定多个Condition

**用法**：
```java
ReentrantLock lock = new ReentrantLock(true); // 公平锁

public void processOrder() {
    lock.lock();  // 获取锁
    try {
        // 同步代码
    } finally {
        lock.unlock();  // 释放锁（必须在finally块中）
    }
}

// 可超时获取锁
public boolean tryProcessOrder() {
    try {
        if (lock.tryLock(1, TimeUnit.SECONDS)) {  // 尝试获取锁，超时1秒
            try {
                // 同步代码
                return true;
            } finally {
                lock.unlock();
            }
        }
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
    return false;
}
```

**电商场景**：订单号生成
```java
public class OrderNoGenerator {
    private final ReentrantLock lock = new ReentrantLock();
    private long counter = 0;
    
    public String generateOrderNo() {
        lock.lock();
        try {
            counter++;
            return "ORD" + System.currentTimeMillis() + counter;
        } finally {
            lock.unlock();
        }
    }
}
```

#### （3）ReadWriteLock

**核心思想**：读读不互斥，读写互斥，写写互斥。

**用法**：
```java
ReadWriteLock rwLock = new ReentrantReadWriteLock();
Lock readLock = rwLock.readLock();
Lock writeLock = rwLock.writeLock();

// 读操作（多个线程可同时读）
public String getOrder(Long orderId) {
    readLock.lock();
    try {
        return orderDao.getById(orderId);
    } finally {
        readLock.unlock();
    }
}

// 写操作（只能一个线程写）
public void updateOrder(Order order) {
    writeLock.lock();
    try {
        orderDao.update(order);
    } finally {
        writeLock.unlock();
    }
}
```

**电商场景**：商品详情缓存
```java
public class ProductCache {
    private final Map<Long, Product> cache = new HashMap<>();
    private final ReadWriteLock rwLock = new ReentrantReadWriteLock();
    
    // 读缓存（并发读）
    public Product getProduct(Long productId) {
        rwLock.readLock().lock();
        try {
            return cache.get(productId);
        } finally {
            rwLock.readLock().unlock();
        }
    }
    
    // 更新缓存（独占写）
    public void updateProduct(Product product) {
        rwLock.writeLock().lock();
        try {
            cache.put(product.getId(), product);
        } finally {
            rwLock.writeLock().unlock();
        }
    }
}
```

### 3. 并发容器

#### （1）List

| 容器 | 说明 | 线程安全 | 适用场景 |
|----------|----------|----------|----------|
| **Vector** |  synchronized实现 | 是 | 不推荐（性能差） |
| **Collections.synchronizedList** | 同步包装 | 是 | 简单场景 |
| **CopyOnWriteArrayList** | 写时复制 | 是 | 读多写少 |

**CopyOnWriteArrayList原理**：
- 写时复制整个数组，读不需要加锁
- 适合读多写少场景（如：商品分类列表）

**用法**：
```java
// 商品分类列表（读多写少）
CopyOnWriteArrayList<Category> categories = new CopyOnWriteArrayList<>();

// 读操作（无锁，高性能）
public List<Category> getCategories() {
    return new ArrayList<>(categories);  // 返回副本
}

// 写操作（复制整个数组，开销大）
public void addCategory(Category category) {
    categories.add(category);
}
```

#### （2）Map

| 容器 | 说明 | 线程安全 | 适用场景 |
|----------|----------|----------|----------|
| **Hashtable** | synchronized实现 | 是 | 不推荐（性能差） |
| **Collections.synchronizedMap** | 同步包装 | 是 | 简单场景 |
| **ConcurrentHashMap** | 分段锁/CAS | 是 | 推荐（高性能） |

**ConcurrentHashMap原理**：
- JDK 1.7：分段锁（Segment数组）
- JDK 1.8：CAS + synchronized（更细粒度）

**用法**：
```java
// 商品库存缓存（高并发读写）
ConcurrentHashMap<Long, Integer> stockCache = new ConcurrentHashMap<>();

// 获取库存（无锁，高性能）
public Integer getStock(Long itemId) {
    return stockCache.get(itemId);
}

// 更新库存（CAS，无锁）
public void updateStock(Long itemId, int newStock) {
    stockCache.put(itemId, newStock);
}

// 原子更新（库存扣减）
public boolean deductStock(Long itemId, int quantity) {
    Integer stock = stockCache.get(itemId);
    if (stock != null && stock >= quantity) {
        return stockCache.replace(itemId, stock, stock - quantity);
    }
    return false;
}
```

#### （3）Queue

| 容器 | 说明 | 线程安全 | 适用场景 |
|----------|----------|----------|----------|
| **LinkedList** | 链表实现 | 否 | 单线程 |
| **ArrayDeque** | 数组实现 | 否 | 单线程 |
| **PriorityQueue** | 优先队列 | 否 | 单线程 |
| **ConcurrentLinkedQueue** | 无锁队列 | 是 | 一般队列 |
| **LinkedBlockingQueue** | 阻塞队列 | 是 | 生产者-消费者 |
| **ArrayBlockingQueue** | 有界阻塞队列 | 是 | 有界队列 |
| **PriorityBlockingQueue** | 优先阻塞队列 | 是 | 优先级队列 |
| **DelayQueue** | 延迟队列 | 是 | 延迟任务 |
| **SynchronousQueue** | 同步队列 | 是 | 直接传递 |

**电商场景**：订单处理队列
```java
// 订单处理队列（生产者-消费者模式）
BlockingQueue<Order> orderQueue = new LinkedBlockingQueue<>(10000);

// 生产者：提交订单
public void submitOrder(Order order) {
    try {
        orderQueue.put(order);  // 队列满时阻塞
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
}

// 消费者：处理订单
public void startOrderConsumer() {
    new Thread(() -> {
        while (true) {
            try {
                Order order = orderQueue.take();  // 队列空时阻塞
                processOrder(order);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }).start();
}
```

---

## 示例/应用场景

### 示例1：电商订单处理系统

**需求**：
- 高并发订单提交（峰值10万TPS）
- 订单处理异步化（提高响应速度）
- 订单状态一致性（不能超卖）

**技术方案**：
```
用户提交订单
  ↓
订单校验（参数校验、库存校验）
  ↓
订单入库（MySQL）
  ↓
发送消息到订单处理队列（Kafka）
  ↓
返回订单号给用户（异步处理）
  ↓
订单处理消费者（多线程处理）
  - 库存扣减（Redis原子操作）
  - 支付处理（调用支付系统）
  - 物流分配（调用物流系统）
  - 订单状态更新（MySQL）
```

**核心代码**：
```java
// 1. 订单提交（同步）
@RestController
public class OrderController {
    @Autowired
    private OrderService orderService;
    
    @PostMapping("/order/submit")
    public Result submitOrder(@RequestBody OrderDTO orderDTO) {
        // 参数校验
        validateOrder(orderDTO);
        // 库存校验
        if (!inventoryService.checkStock(orderDTO.getItemId(), orderDTO.getQuantity())) {
            return Result.error("库存不足");
        }
        // 创建订单
        Order order = orderService.createOrder(orderDTO);
        // 发送消息到订单处理队列
        kafkaTemplate.send("order-process-topic", order.getId().toString(), order);
        // 返回订单号
        return Result.success(order.getOrderNo());
    }
}

// 2. 订单处理（异步，多线程）
@Component
public class OrderConsumer {
    @KafkaListener(topics = "order-process-topic", groupId = "order-process-group")
    public void processOrder(Order order) {
        // 1. 库存扣减（Redis原子操作）
        if (!inventoryService.deductStock(order.getItemId(), order.getQuantity())) {
            log.error("库存扣减失败，orderId={}", order.getId());
            return;
        }
        // 2. 支付处理（调用支付系统）
        paymentService.process(order);
        // 3. 物流分配（调用物流系统）
        logisticsService.assign(order);
        // 4. 订单状态更新
        orderService.updateStatus(order.getId(), OrderStatus.PROCESSING);
    }
}

// 3. 库存扣减（Redis原子操作）
@Service
public class InventoryService {
    @Autowired
    private StringRedisTemplate redisTemplate;
    
    public boolean deductStock(Long itemId, Integer quantity) {
        String key = "stock:" + itemId;
        Long remaining = redisTemplate.opsForValue().decrement(key, quantity);
        if (remaining < 0) {
            // 库存不足，回滚
            redisTemplate.opsForValue().increment(key, quantity);
            return false;
        }
        return true;
    }
}
```

### 示例2：商品搜索系统

**需求**：
- 商品搜索（关键词搜索、分类筛选、排序）
- 高并发查询（峰值5万QPS）
- 实时性要求高（商品价格、库存变化实时可见）

**技术方案**：
```
用户输入关键词
  ↓
调用搜索服务（ElasticSearch）
  ↓
返回搜索结果（商品列表）
  ↓
前端展示（分页、排序、筛选）
```

**核心代码**：
```java
// 1. 商品索引构建（多线程批量导入）
@Service
public class ProductIndexService {
    @Autowired
    private RestHighLevelClient esClient;
    
    // 批量导入商品数据到ES（多线程）
    public void bulkImportProducts(List<Product> products) {
        // 创建线程池
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
            10, 50, 60L, TimeUnit.SECONDS,
            new LinkedBlockingQueue<>(1000),
            new ThreadFactoryBuilder().setNameFormat("es-import-%d").build(),
            new ThreadPoolExecutor.CallerRunsPolicy()
        );
        
        // 分批导入（每批1000个）
        List<List<Product>> batches = Lists.partition(products, 1000);
        for (List<Product> batch : batches) {
            executor.submit(() -> {
                BulkRequest bulkRequest = new BulkRequest();
                for (Product product : batch) {
                    IndexRequest indexRequest = new IndexRequest("product_index")
                        .id(product.getId().toString())
                        .source(JSON.toJSONString(product), XContentType.JSON);
                    bulkRequest.add(indexRequest);
                }
                try {
                    esClient.bulk(bulkRequest, RequestOptions.DEFAULT);
                } catch (IOException e) {
                    log.error("批量导入商品数据失败", e);
                }
            });
        }
        
        // 关闭线程池
        executor.shutdown();
        try {
            executor.awaitTermination(1, TimeUnit.HOURS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}

// 2. 商品搜索（高并发查询）
@RestController
public class ProductController {
    @Autowired
    private ProductSearchService searchService;
    
    @GetMapping("/product/search")
    public Result searchProducts(
        @RequestParam String keyword,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size) {
        
        // 构建搜索请求
        SearchRequest searchRequest = new SearchRequest("product_index");
        SearchSourceBuilder sourceBuilder = new SearchSourceBuilder();
        
        // 多字段搜索（商品名称、描述、分类）
        QueryBuilder queryBuilder = QueryBuilders.multiMatchQuery(keyword, "name", "description", "category")
            .operator(Operator.AND);
        sourceBuilder.query(queryBuilder);
        
        // 分页
        sourceBuilder.from(page * size);
        sourceBuilder.size(size);
        
        // 排序（按相关性、价格、销量）
        sourceBuilder.sort("_score", SortOrder.DESC);
        sourceBuilder.sort("price", SortOrder.ASC);
        sourceBuilder.sort("sales", SortOrder.DESC);
        
        searchRequest.source(sourceBuilder);
        
        // 执行搜索
        SearchResponse searchResponse = searchService.search(searchRequest);
        
        // 解析结果
        List<Product> products = new ArrayList<>();
        for (SearchHit hit : searchResponse.getHits().getHits()) {
            Product product = JSON.parseObject(hit.getSourceAsString(), Product.class);
            products.add(product);
        }
        
        return Result.success(products);
    }
}
```

---

## 【对应领域考点】

### 1. 线程池核心参数

**考点**：ThreadPoolExecutor的核心参数有哪些？

**答题要点**：
1. **corePoolSize**：核心线程数
2. **maximumPoolSize**：最大线程数
3. **keepAliveTime**：空闲线程存活时间
4. **workQueue**：工作队列
5. **threadFactory**：线程工厂
6. **handler**：拒绝策略

### 2. synchronized与ReentrantLock区别

**考点**：synchronized与ReentrantLock有什么区别？

**答题模板**：
| 对比项 | synchronized | ReentrantLock |
|--------|--------------|---------------|
| **实现方式** | JVM内置 | JDK实现 |
| **锁释放** | 自动释放 | 手动释放（finally） |
| **中断响应** | 不支持 | 支持 |
| **超时获取锁** | 不支持 | 支持 |
| **公平锁** | 不支持 | 支持 |
| **Condition** | 不支持 | 支持 |

### 3. ConcurrentHashMap原理

**考点**：ConcurrentHashMap是如何保证线程安全的？

**答题要点**：
- **JDK 1.7**：分段锁（Segment数组，默认16个分段）
- **JDK 1.8**：CAS + synchronized（更细粒度，性能更好）

---

## 最佳实践

### 1. 线程池配置原则

- **CPU密集型**：核心线程数 = CPU核心数 + 1
- **IO密集型**：核心线程数 = CPU核心数 * 2
- **混合型**：根据IO/CPU比例调整

### 2. 锁使用原则

- **优先使用synchronized**：简单场景，JVM会自动优化
- **需要高级功能时使用ReentrantLock**：公平锁、超时锁、中断响应
- **读多写少场景使用ReadWriteLock**：提高并发性能

### 3. 并发容器选择原则

- **Map**：优先使用ConcurrentHashMap
- **List**：读多写少使用CopyOnWriteArrayList
- **Queue**：生产者-消费者模式使用LinkedBlockingQueue

---

## 【常见错误】

### 错误1：锁范围过大

**表现**：整个方法加锁，性能差。

**正确做法**：
```java
// ❌ 错误：锁范围过大
public synchronized void processOrder(Order order) {
    // 1. 参数校验（不需要锁）
    validateOrder(order);
    // 2. 业务逻辑（需要锁）
    orderService.process(order);
    // 3. 发送通知（不需要锁）
    notificationService.send(order);
}

// ✅ 正确：缩小锁范围
public void processOrder(Order order) {
    // 1. 参数校验（不需要锁）
    validateOrder(order);
    // 2. 业务逻辑（需要锁）
    synchronized (this) {
        orderService.process(order);
    }
    // 3. 发送通知（不需要锁）
    notificationService.send(order);
}
```

### 错误2：线程池使用不当

**表现**：使用Executors工具类创建线程池，可能导致OOM。

**正确做法**：
```java
// ❌ 错误：使用Executors工具类
ExecutorService executor = Executors.newFixedThreadPool(10);  // 无界队列，可能导致OOM

// ✅ 正确：手动创建ThreadPoolExecutor
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    10, 50, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(1000),  // 有界队列
    new ThreadFactoryBuilder().setNameFormat("my-thread-%d").build(),
    new ThreadPoolExecutor.CallerRunsPolicy()
);
```

### 错误3：死锁

**表现**：两个线程互相等待对方释放锁，导致程序卡死。

**正确做法**：
```java
// ❌ 错误：可能导致死锁
public void transfer(Account from, Account to, BigDecimal amount) {
    synchronized (from) {
        synchronized (to) {
            from.deduct(amount);
            to.add(amount);
        }
    }
}

// ✅ 正确：按固定顺序获取锁（避免死锁）
public void transfer(Account from, Account to, BigDecimal amount) {
    Account first, second;
    if (from.getId() < to.getId()) {
        first = from;
        second = to;
    } else {
        first = to;
        second = from;
    }
    
    synchronized (first) {
        synchronized (second) {
            from.deduct(amount);
            to.add(amount);
        }
    }
}
```

---

## 总结

**Java多线程与并发编程**是零售电商系统的核心技术，需要掌握：

1. **线程池技术**：核心参数、拒绝策略、电商场景应用
2. **同步机制**：synchronized、ReentrantLock、ReadWriteLock
3. **并发容器**：CopyOnWriteArrayList、ConcurrentHashMap、BlockingQueue

**核心思想**：
- **线程安全**：共享资源需要同步
- **性能优化**：缩小锁范围、使用并发容器
- **避免死锁**：按固定顺序获取锁

掌握Java多线程与并发编程，让你能够设计出**高并发、高性能、高可用**的零售电商系统。
