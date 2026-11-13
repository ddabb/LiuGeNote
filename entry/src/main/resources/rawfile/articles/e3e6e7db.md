
# Linux系统编程API详解

## 定义

Linux系统编程API是**Linux内核提供给用户空间的系统调用和库函数接口**，是编写系统级软件的基础。

**核心API分类**：
- **文件I/O**：open、read、write、close、mmap
- **进程管理**：fork、exec、wait、exit
- **内存管理**：brk、mmap、munmap、mprotect
- **网络通信**：socket、bind、listen、accept、connect
- **信号处理**：signal、sigaction、kill、pause
- **时间管理**：gettimeofday、clock_gettime、nanosleep

**为什么需要掌握**：
- **性能优化**：理解API底层行为，针对性优化
- **调试能力**：通过strace跟踪系统调用，定位问题
- **安全编程**：正确使用API，避免安全漏洞

## 核心概念

### 1. 系统调用 vs 库函数
- **系统调用**：陷入内核，执行特权操作（如read、write）
- **库函数**：用户态函数，可能封装系统调用（如fopen封装open）
- **区别**：
  - 系统调用开销大（特权级切换）
  - 库函数开销小（用户态执行）
  - 库函数可能缓冲（如stdio的FILE*）

### 2. 文件描述符（File Descriptor）
- **定义**：非负整数，标识打开的文件
- **特殊fd**：
  - 0：标准输入（stdin）
  - 1：标准输出（stdout）
  - 2：标准错误（stderr）
- **分配规则**：最小未使用的fd

### 3. 内核数据结构
- **进程表项**：每个进程一个，包含fd表指针
- **文件表**：每个打开文件一个，包含偏移量、状态标志、inode指针
- **inode表**：每个文件一个，包含文件元数据（大小、权限、磁盘地址）

### 4. 原子操作
- **定义**：不可中断的操作
- **重要性**：避免竞态条件（如open with O_CREAT|O_EXCL）
- **示例**：`pread`、`pwrite`（原子读写，不更新文件偏移量）

## 详细内容

### 文件I/O API

#### 1. open()
```c
#include <fcntl.h>
int open(const char *pathname, int flags, mode_t mode);
```
- **功能**：打开或创建文件
- **flags**：
  - `O_RDONLY`：只读
  - `O_WRONLY`：只写
  - `O_RDWR`：读写
  - `O_CREAT`：不存在则创建
  - `O_EXCL`：与O_CREAT连用，文件已存在则失败
  - `O_APPEND`：追加写
  - `O_TRUNC`：清空文件
  - `O_NONBLOCK`：非阻塞
  - `O_DIRECT`：直接I/O，绕过页缓存
- **返回**：文件描述符（成功），-1（失败）
- **示例**：
  ```c
  int fd = open("test.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) { perror("open"); return -1; }
  ```

#### 2. read()
```c
#include <unistd.h>
ssize_t read(int fd, void *buf, size_t count);
```
- **功能**：从fd读取数据
- **返回**：
  - 正数：读取的字节数
  - 0：到达文件末尾（EOF）
  - -1：错误（errno设置）
- **注意**：
  - 可能读取少于count字节（信号中断、管道空等）
  - 需循环读取直到满足需求
- **示例**：
  ```c
  char buf[1024];
  ssize_t n;
  while ((n = read(fd, buf, sizeof(buf))) > 0) {
      // 处理buf中的数据
  }
  if (n < 0) { perror("read"); }
  ```

#### 3. write()
```c
#include <unistd.h>
ssize_t write(int fd, const void *buf, size_t count);
```
- **功能**：向fd写入数据
- **返回**：写入的字节数（可能少于count），-1（错误）
- **注意**：
  - 可能写入少于count字节（磁盘满、信号中断）
  - 需循环写入直到全部写入
- **示例**：
  ```c
  char *msg = "Hello, World!\n";
  size_t len = strlen(msg);
  ssize_t n = write(fd, msg, len);
  if (n != len) { perror("write"); }
  ```

#### 4. close()
```c
#include <unistd.h>
int close(int fd);
```
- **功能**：关闭文件描述符
- **返回**：0（成功），-1（错误）
- **注意**：
  - 关闭fd后，不再能访问对应文件
  - 进程终止时，所有打开的fd自动关闭

#### 5. mmap()
```c
#include <sys/mman.h>
void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
```
- **功能**：将文件或设备映射到内存
- **prot**：
  - `PROT_READ`：可读
  - `PROT_WRITE`：可写
  - `PROT_EXEC`：可执行
  - `PROT_NONE`：不可访问
- **flags**：
  - `MAP_SHARED`：共享映射，修改写回文件
  - `MAP_PRIVATE`：私有映射，写时复制（COW）
  - `MAP_ANONYMOUS`：匿名映射，不关联文件（用于分配内存）
- **返回**：映射的内存地址（成功），MAP_FAILED（失败）
- **示例**：
  ```c
  int fd = open("test.txt", O_RDWR);
  struct stat st;
  fstat(fd, &st);
  char *addr = mmap(NULL, st.st_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (addr == MAP_FAILED) { perror("mmap"); return -1; }
  // 现在可以通过addr读写文件
  addr[0] = 'H';  // 修改会写回文件
  munmap(addr, st.st_size);
  close(fd);
  ```

### 进程管理API

#### 1. fork()
```c
#include <unistd.h>
pid_t fork(void);
```
- **功能**：创建子进程
- **返回**：
  - 父进程：返回子进程pid
  - 子进程：返回0
  - 错误：返回-1
- **注意**：
  - 子进程复制父进程地址空间（写时复制，COW）
  - 子进程继承父进程打开的文件描述符
- **示例**：
  ```c
  pid_t pid = fork();
  if (pid < 0) { perror("fork"); return -1; }
  else if (pid == 0) {
      // 子进程
      execlp("ls", "ls", "-l", NULL);
      perror("exec");  // exec失败才执行此行
      exit(EXIT_FAILURE);
  } else {
      // 父进程
      int status;
      waitpid(pid, &status, 0);
      printf("Child exited with status %d\n", WEXITSTATUS(status));
  }
  ```

#### 2. exec族函数
```c
#include <unistd.h>
int execlp(const char *file, const char *arg, ..., NULL);
int execvp(const char *file, char *const argv[]);
```
- **功能**：加载并执行新程序
- **注意**：
  - exec成功则不返回（替换当前进程映像）
  - exec失败返回-1
- **示例**：见fork示例

#### 3. wait()/waitpid()
```c
#include <sys/wait.h>
pid_t wait(int *status);
pid_t waitpid(pid_t pid, int *status, int options);
```
- **功能**：等待子进程状态改变
- **status**：存储子进程退出状态（需用宏解析）
  - `WIFEXITED(status)`：子进程正常退出？
  - `WEXITSTATUS(status)`：获取退出码
  - `WIFSIGNALED(status)`：被子信号终止？
  - `WTERMSIG(status)`：获取终止信号
- **示例**：见fork示例

### 内存管理API

#### 1. brk()/sbrk()
```c
#include <unistd.h>
int brk(void *addr);
void *sbrk(intptr_t increment);
```
- **功能**：调整堆末尾位置（传统malloc实现方式）
- **注意**：现代malloc多使用mmap，较少直接使用brk/sbrk

#### 2. mmap()（匿名映射）
```c
// 分配内存（类似malloc）
void *addr = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
if (addr == MAP_FAILED) { perror("mmap"); return -1; }
// 使用addr...
munmap(addr, 4096);
```

## 示例/应用场景

### 场景1：高性能文件复制
**需求**：快速复制大文件

**使用API**：
1. **open()**：打开源文件和目标文件（O_RDONLY、O_WRONLY|O_CREAT）
2. **mmap()**：映射源文件到内存（MAP_PRIVATE）
3. **mmap()**：映射目标文件到内存（MAP_SHARED）
4. **memcpy()**：内存复制（内核自动处理页面调度）
5. **munmap()**：取消映射
6. **close()**：关闭文件

**优势**：减少read/write系统调用，利用页缓存

### 场景2：进程池实现
**需求**：预先创建多个子进程处理任务

**使用API**：
1. **socketpair()**：创建Unix域套接字对（用于父子进程通信）
2. **fork()**：创建多个子进程
3. **read()/write()**：父子进程通过套接字通信
4. **waitpid()**：父进程回收子进程

**优势**：减少进程创建开销，提高响应速度

### 场景3：共享内存通信
**需求**：多个进程共享数据（如数据库缓存）

**使用API**：
1. **shm_open()**：创建/打开共享内存对象
2. **ftruncate()**：设置共享内存大小
3. **mmap()**：映射共享内存到进程地址空间
4. **munmap()**：取消映射
5. **shm_unlink()**：删除共享内存对象

**优势**：最快的IPC（无需内核复制）

## 【对应领域考点】

1. **文件I/O API**：open、read、write、close、mmap参数和返回值
2. **进程管理API**：fork、exec、wait、exit，父子进程关系
3. **内存管理API**：brk、sbrk、mmap、munmap使用场景
4. **文件描述符**：定义、特殊fd（0/1/2）、继承规则
5. **原子操作**：O_EXCL、pread/pwrite、F_SETLK
6. **内核数据结构**：进程表项、文件表、inode表关系
7. **性能优化**：mmap vs read/write、直接I/O、非阻塞I/O
8. **错误处理**：errno、perror、检查返回值

## 最佳实践

### 1. 始终检查返回值
- **规则**：每个系统调用都检查返回值
- **示例**：
  ```c
  int fd = open("file.txt", O_RDONLY);
  if (fd < 0) { perror("open"); return -1; }
  ```

### 2. 正确处理EAGAIN/EWOULDBLOCK
- **场景**：非阻塞I/O
- **做法**：
  ```c
  while (1) {
      ssize_t n = read(fd, buf, sizeof(buf));
      if (n < 0) {
          if (errno == EAGAIN) { /* 暂无数据 */ break; }
          else { perror("read"); break; }
      } else if (n == 0) { /* EOF */ break; }
      else { /* 处理数据 */ }
  }
  ```

### 3. 使用pread/pwrite避免竞态
- **问题**：多线程共享fd时，lseek+read/write非原子
- **解决**：使用pread/pwrite（原子操作，不更新文件偏移量）

### 4. 及时关闭文件描述符
- **规则**：open/close配对，避免文件描述符泄漏
- **检测**：使用lsof查看进程打开的fd

### 5. 使用mmap处理大文件
- **场景**：文件大小超过可用内存？不，mmap可映射大于内存的文件（按需分页）
- **优势**：简化I/O代码，利用页缓存

## 【常见错误】

### 错误1：忽略read/write返回值
**表现**：
```c
read(fd, buf, 1024);  // 假设一定读取1024字节
```
**后果**：实际读取可能少于1024字节（信号中断、管道空等）
**正确做法**：循环读取，检查返回值

### 错误2：fork后忘记wait
**表现**：
```c
pid_t pid = fork();
if (pid == 0) { /* 子进程 */ exit(0); }
// 父进程忘记wait
```
**后果**：子进程变成僵尸进程（Zombie）
**正确做法**：父进程调用wait/waitpid回收子进程

### 错误3：mmap后忘记munmap
**表现**：映射内存后忘记取消映射
**后果**：内存泄漏（进程退出后自动取消，但长时间运行的程序会泄漏）
**正确做法**：mmap/munmap配对

### 错误4：使用O_CREAT但不指定mode
**表现**：
```c
int fd = open("file.txt", O_WRONLY | O_CREAT);  // 缺少mode参数
```
**后果**：mode参数未定义，可能创建权限错误的文件
**正确做法**：`open("file.txt", O_WRONLY | O_CREAT, 0644)`

### 错误5：多线程共享fd但不使用pread/pwrite
**表现**：多个线程使用同一fd，调用lseek+read/write
**后果**：竞态条件，文件偏移量混乱
**正确做法**：使用pread/pwrite（原子操作）

## 总结

Linux系统编程API是编写高性能系统软件的基础。

**关键要点**：
1. **文件I/O**：open/read/write/close/mmap是核心
2. **进程管理**：fork/exec/wait是创建子进程的基础
3. **内存管理**：mmap既可映射文件，也可分配内存
4. **错误处理**：始终检查返回值，使用perror打印错误
5. **性能优化**：根据场景选择I/O模型（read/write vs mmap vs 直接I/O）

**学习路径**：
1. 阅读《UNIX环境高级编程》（APUE）
2. 实践每个API（编写小测试程序）
3. 使用strace跟踪系统调用，理解底层行为
4. 阅读优秀开源代码（Redis、Nginx、Linux内核）
5. 掌握性能优化技巧（零拷贝、I/O多路复用、内存映射）

掌握Linux系统编程API，能让你深入理解操作系统工作原理，编写高性能、高可靠的系统软件。
