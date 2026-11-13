
# C/C++系统编程实践

## 定义

C/C++系统编程是**使用C或C++编写直接与操作系统内核交互的底层软件**的实践。C/C++因接近硬件、性能极高，是系统编程首选语言。

**为什么选C/C++**：
- **零开销抽象（C++）**：RAII、模板等特性无运行时开销
- **手动内存管理**：精确控制内存分配/释放
- **内联汇编**：可直接嵌入汇编指令
- **跨平台**：POSIX标准使代码可移植

**C vs C++ 系统编程对比**：
| 维度 | C | C++ |
|------|---|----|
| 抽象能力 | 低（结构体+函数指针） | 高（类、模板、RAII） |
| 内存安全 | 低（易内存泄漏、缓冲区溢出） | 中（RAII、智能指针） |
| 性能 | 极高 | 与C相当（零开销抽象） |
| 学习曲线 | 平缓 | 陡峭 |
| 适用场景 | 内核、嵌入式 | 应用级系统软件（数据库、Web服务器） |

## 核心概念

### 1. 系统调用包装（System Call Wrapper）
- **C方式**：直接调用POSIX API（`open()`、`read()`、`write()`等）
- **C++方式**：用RAII包装系统资源（文件描述符、套接字、互斥锁）
- **优势**：资源自动释放，异常安全

### 2. 错误处理
- **C方式**：检查返回值，设errno
- **C++方式**：抛出异常（但系统编程少用异常，因确定性析构已够）
- **混合方式**：返回`std::expected`（C++23）或`std::optional`

### 3. 内存管理
- **C方式**：`malloc()/free()`，易泄漏
- **C++方式**：`new/delete`，但更推荐智能指针（`std::unique_ptr`、`std::shared_ptr`）
- **自定义分配器**：重载`operator new`或使用内存池

### 4. 并发编程
- **C方式**：Pthreads（pthread_create、pthread_mutex）
- **C++方式**：`std::thread`、`std::mutex`、`std::condition_variable`（C++11+）
- **优势**：类型安全、RAII管理线程生命周期

## 详细内容

### C语言系统编程实践

#### 1. 文件I/O实践
```c
// 打开文件
int fd = open("/tmp/test.txt", O_RDWR | O_CREAT, 0644);
if (fd < 0) {
    perror("open failed");
    return -1;
}

// 写入数据
char buf[] = "Hello, System Programming!";
ssize_t n = write(fd, buf, sizeof(buf) - 1);
if (n < 0) {
    perror("write failed");
    close(fd);
    return -1;
}

// 读取数据
lseek(fd, 0, SEEK_SET);  // 回到文件开头
char rbuf[1024];
n = read(fd, rbuf, sizeof(rbuf) - 1);
if (n < 0) {
    perror("read failed");
    close(fd);
    return -1;
}
rbuf[n] = '\0';

// 关闭文件
close(fd);
```

#### 2. 进程管理实践
```c
pid_t pid = fork();
if (pid < 0) {
    perror("fork failed");
    return -1;
} else if (pid == 0) {
    // 子进程
    execlp("ls", "ls", "-l", NULL);
    perror("exec failed");  // exec失败才执行此行
    exit(EXIT_FAILURE);
} else {
    // 父进程
    int status;
    waitpid(pid, &status, 0);
    printf("Child exited with status %d\n", WEXITSTATUS(status));
}
```

#### 3. 网络编程实践
```c
// 创建TCP socket
int sockfd = socket(AF_INET, SOCK_STREAM, 0);
if (sockfd < 0) {
    perror("socket failed");
    return -1;
}

// 绑定地址
struct sockaddr_in addr;
addr.sin_family = AF_INET;
addr.sin_port = htons(8080);
addr.sin_addr.s_addr = INADDR_ANY;
if (bind(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
    perror("bind failed");
    close(sockfd);
    return -1;
}

// 监听
if (listen(sockfd, SOMAXCONN) < 0) {
    perror("listen failed");
    close(sockfd);
    return -1;
}

// 接受连接
int connfd = accept(sockfd, NULL, NULL);
if (connfd < 0) {
    perror("accept failed");
    close(sockfd);
    return -1;
}

// 处理连接...
close(connfd);
close(sockfd);
```

### C++系统编程实践

#### 1. RAII包装文件描述符
```cpp
class FileDescriptor {
private:
    int fd_;
public:
    explicit FileDescriptor(int fd) : fd_(fd) {}
    ~FileDescriptor() {
        if (fd_ >= 0) {
            close(fd_);
        }
    }
    // 禁止拷贝（使用移动语义）
    FileDescriptor(const FileDescriptor&) = delete;
    FileDescriptor& operator=(const FileDescriptor&) = delete;
    FileDescriptor(FileDescriptor&& other) : fd_(other.fd_) {
        other.fd_ = -1;
    }
    FileDescriptor& operator=(FileDescriptor&& other) {
        if (this != &other) {
            if (fd_ >= 0) close(fd_);
            fd_ = other.fd_;
            other.fd_ = -1;
        }
        return *this;
    }
    int get() const { return fd_; }
};

// 使用
FileDescriptor fd(open("/tmp/test.txt", O_RDWR | O_CREAT, 0644));
if (fd.get() < 0) {
    throw std::runtime_error("open failed");
}
// 无需手动close，析构函数自动关闭
```

#### 2. 内存映射包装
```cpp
class MemoryMappedFile {
private:
    void* addr_;
    size_t length_;
    int fd_;
public:
    MemoryMappedFile(const char* path, size_t length) : addr_(MAP_FAILED), length_(length), fd_(-1) {
        fd_ = open(path, O_RDWR | O_CREAT, 0644);
        if (fd_ < 0) throw std::runtime_error("open failed");
        // 扩展文件到指定长度
        if (ftruncate(fd_, length) < 0) throw std::runtime_error("ftruncate failed");
        addr_ = mmap(nullptr, length, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0);
        if (addr_ == MAP_FAILED) throw std::runtime_error("mmap failed");
    }
    ~MemoryMappedFile() {
        if (addr_ != MAP_FAILED) munmap(addr_, length_);
        if (fd_ >= 0) close(fd_);
    }
    // 禁止拷贝
    MemoryMappedFile(const MemoryMappedFile&) = delete;
    MemoryMappedFile& operator=(const MemoryMappedFile&) = delete;
    // 移动语义
    MemoryMappedFile(MemoryMappedFile&& other) : addr_(other.addr_), length_(other.length_), fd_(other.fd_) {
        other.addr_ = MAP_FAILED;
        other.fd_ = -1;
    }
    void* data() { return addr_; }
    size_t size() const { return length_; }
};
```

#### 3. 线程安全队列（无锁）
```cpp
template<typename T>
class LockFreeQueue {
private:
    struct Node {
        T data;
        std::atomic<Node*> next;
        Node(T val) : data(std::move(val)), next(nullptr) {}
    };
    std::atomic<Node*> head_;
    std::atomic<Node*> tail_;
public:
    LockFreeQueue() {
        Node* dummy = new Node(T());
        head_.store(dummy, std::memory_order_relaxed);
        tail_.store(dummy, std::memory_order_relaxed);
    }
    ~LockFreeQueue() {
        // 清理所有节点...
    }
    void enqueue(T val) {
        Node* node = new Node(std::move(val));
        Node* tail = tail_.load(std::memory_order_relaxed);
        Node* next = nullptr;
        do {
            next = tail->next.load(std::memory_order_relaxed);
            if (next == nullptr) {
                if (tail->next.compare_exchange_weak(next, node,
                                                    std::memory_order_release,
                                                    std::memory_order_relaxed)) {
                    break;
                }
            } else {
                tail_.compare_exchange_weak(tail, next,
                                           std::memory_order_release,
                                           std::memory_order_relaxed);
            }
        } while (true);
        // 尝试移动tail指针
        tail_.compare_exchange_weak(tail, node,
                                   std::memory_order_release,
                                   std::memory_order_relaxed);
    }
    bool dequeue(T& result) {
        Node* head = head_.load(std::memory_order_relaxed);
        Node* tail = tail_.load(std::memory_order_relaxed);
        Node* next = head->next.load(std::memory_order_relaxed);
        if (head == tail) {
            if (next == nullptr) return false;  // 队列空
            // tail落后，尝试推进
            tail_.compare_exchange_weak(tail, next,
                                       std::memory_order_release,
                                       std::memory_order_relaxed);
        } else {
            result = next->data;
            if (head_.compare_exchange_weak(head, next,
                                           std::memory_order_release,
                                           std::memory_order_relaxed)) {
                delete head;
                return true;
            }
        }
        return false;
    }
};
```

## 示例/应用场景

### 场景1：高性能日志库
**需求**：低延迟、高吞吐写入日志

**C++实现技术**：
1. **RAII管理文件描述符**：确保异常安全
2. **内存映射（mmap）**：减少数据拷贝
3. **无锁队列**：多线程安全写入
4. **批量刷盘**：累积多条日志后一次write()
5. **自定义分配器**：减少malloc/free开销

### 场景2：网络服务器框架
**需求**：高并发处理TCP连接

**C++实现技术**：
1. **RAII管理socket**：确保异常安全
2. **事件驱动（epoll）**：单线程处理多连接
3. **线程池**：处理计算密集型任务
4. **零拷贝（sendfile）**：文件传输优化
5. **智能指针**：安全管理连接对象生命周期

### 场景3：内存数据库
**需求**：微秒级读写延迟

**C++实现技术**：
1. **自定义内存分配器**：减少malloc开销
2. **内存池**：预分配内存块
3. **无锁数据结构**：并发访问无锁
4. **RAII管理资源**：确保异常安全
5. **移动语义**：减少拷贝开销

## 【对应领域考点】

1. **C/C++系统编程区别**：抽象能力、内存安全、性能、适用场景
2. **RAII原理**：资源获取即初始化，异常安全
3. **智能指针**：unique_ptr、shared_ptr、weak_ptr使用场景
4. **系统调用包装**：如何用C++包装POSIX API
5. **内存映射**：mmap原理、使用场景、优缺点
6. **无锁编程**：CAS、内存模型、无锁数据结构
7. **跨平台编程**：条件编译、抽象层设计
8. **性能优化**：零拷贝、内存池、自定义分配器

## 最佳实践

### 1. 资源管理
- **RAII原则**：所有资源（文件、套接字、锁）用对象管理
- **禁止裸指针**：使用智能指针或RAII对象
- **异常安全**：确保资源在异常发生时也能释放

### 2. 内存管理
- **避免裸new/delete**：使用`std::make_unique`、`std::make_shared`
- **自定义分配器**：性能关键路径使用内存池
- **内存对齐**：关键数据结构按缓存行对齐

### 3. 并发编程
- **优先使用C++标准库**：`std::thread`、`std::mutex`等
- **无锁数据结构**：竞争不激烈时使用
- **避免死锁**：固定加锁顺序，使用`std::scoped_lock`

### 4. 跨平台
- **POSIX API**：优先使用POSIX标准API
- **条件编译**：封装平台相关代码到独立模块
- **抽象层**：设计跨平台抽象接口（如文件系统、网络）

### 5. 调试与测试
- **AddressSanitizer**：检测内存错误（编译时加`-fsanitize=address`）
- **ThreadSanitizer**：检测数据竞争（编译时加`-fsanitize=thread`）
- **Valgrind**：检测内存泄漏、非法访问

## 【常见错误】

### 错误1：忘记关闭文件描述符
**表现**：`int fd = open(...); /* 忘记close(fd) */`
**后果**：文件描述符泄漏，达到上限后open失败
**正确做法**：使用RAII包装（C++）或确保每次open都有对应close（C）

### 错误2：缓冲区溢出
**表现**：`char buf[10]; strcpy(buf, "1234567890");`
**后果**：覆盖相邻内存，导致崩溃或安全漏洞
**正确做法**：使用`strncpy`、`snprintf`等带长度限制的函数

### 错误3：使用已释放内存
**表现**：`free(ptr); /* ... */ *ptr = 42;`
**后果**：野指针，崩溃或数据损坏
**正确做法**：free后立即将指针置NULL，使用智能指针（C++）

### 错误4：异常不安全
**表现**：
```cpp
void foo() {
    int* p = new int[100];
    bar();  // 可能抛出异常
    delete[] p;  // 异常时不会执行，内存泄漏
}
```
**正确做法**：使用RAII（如`std::unique_ptr<int[]>`）

### 错误5：跨平台兼容性问题
**表现**：使用Linux特有API（如`epoll`）但需运行在Windows
**正确做法**：设计跨平台抽象层，封装平台相关代码

## 总结

C/C++系统编程是构建高性能、高可靠系统软件的基础。

**关键要点**：
1. **RAII**：C++资源管理核心，确保异常安全
2. **智能指针**：避免内存泄漏、悬空指针
3. **系统调用包装**：用C++包装POSIX API，提高安全性
4. **无锁编程**：高性能并发，但复杂度高
5. **跨平台**：POSIX标准、条件编译、抽象层

**学习路径**：
1. 掌握C语言指针、内存管理
2. 理解操作系统原理（进程、内存、文件系统、I/O）
3. 学习C++ RAII、智能指针、移动语义
4. 实践系统编程（文件I/O、进程管理、网络编程）
5. 阅读优秀开源代码（Redis、Nginx、Linux内核）

掌握C/C++系统编程，能让你深入理解计算机系统运作原理，写出高性能、高可靠的系统软件。
