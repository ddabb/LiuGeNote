---
title: GPU编程与CUDA优化
tags: [GPU编程, CUDA, 并行计算, 线程模型, 内存优化, 算子优化, 性能调优]
description: GPU编程基础、CUDA核心概念、优化技巧和实战案例，涵盖线程模型、内存层次、算子优化等核心技术
---

# GPU编程与CUDA优化

## 定义

**GPU编程**是利用图形处理器（GPU）的并行计算能力，加速计算密集型任务（如AI推理、科学计算）的编程技术。**CUDA**是NVIDIA推出的并行计算平台和编程模型，是GPU编程的主流工具。

**核心目标**：
- **并行加速**：利用GPU thousands of cores 并行处理
- **内存优化**：减少内存带宽瓶颈，提升数据访问效率
- **计算效率**：最大化GPU利用率，减少空闲时间

---

## 核心概念

### 1. GPU vs CPU

| 特性 | CPU | GPU |
|------|-----|-----|
| **核心数** | 少（4-64 cores） | 多（ thousands of cores） |
| **线程模型** | 重线程（每个线程独立） | 轻线程（成千上万个线程） |
| **内存带宽** | 低（~50 GB/s） | 高（~1 TB/s） |
| **适用场景** | 串行任务、逻辑复杂 | 并行任务、计算密集 |

### 2. CUDA线程层次

| 层次 | 说明 | 大小 |
|------|------|------|
| **Thread（线程）** | 基本执行单元 | 每个线程执行相同代码（Kernel） |
| **Block（线程块）** | 一组线程，共享共享内存 | 最多1024个线程 |
| **Grid（网格）** | 一组线程块 | 最多65535个线程块（每个维度） |

**示例**：
```cuda
// 启动Kernel：Grid(2,2) → 2x2=4个Block；每个Block(8,8) → 8x8=64个Thread
dim3 gridDim(2, 2);
dim3 blockDim(8, 8);
kernel<<<gridDim, blockDim>>>(...);
```

### 3. CUDA内存层次

| 内存类型 | 位置 | 作用域 | 延迟 | 带宽 |
|----------|------|--------|------|--------|
| **寄存器（Register）** | GPU片上 | 线程私有 | 最低 | 最高 |
| **共享内存（Shared Memory）** | GPU片上 | 线程块内共享 | 低 | 高 |
| **局部内存（Local Memory）** | 显存 | 线程私有 | 高 | 低 |
| **全局内存（Global Memory）** | 显存 | 所有线程访问 | 最高 | 低 |
| **常量内存（Constant Memory）** | 显存 | 所有线程只读 | 低（缓存） | 中 |
| **纹理内存（Texture Memory）** | 显存 | 所有线程只读 | 低（缓存） | 中 |

---

## 详细内容

### 一、CUDA编程基础

#### 1.1 Hello World Kernel

**示例**：
```cuda
#include <stdio.h>

// CUDA Kernel：每个线程打印Hello World
__global__ void hello_kernel() {
    printf("Hello World from GPU thread %d\n", threadIdx.x);
}

int main() {
    // 启动Kernel：1个Block，10个Thread
    hello_kernel<<<1, 10>>>();
    
    // 等待GPU完成
    cudaDeviceSynchronize();
    
    return 0;
}
```

**编译运行**：
```bash
nvcc hello.cu -o hello
./hello
```

#### 1.2 向量加法示例

**目标**：实现两个向量（数组）的加法 `C = A + B`。

**CPU实现**：
```c
void vec_add(float* A, float* B, float* C, int N) {
    for (int i = 0; i < N; i++) {
        C[i] = A[i] + B[i];
    }
}
```

**GPU实现（CUDA Kernel）**：
```cuda
// CUDA Kernel：每个线程处理一个元素
__global__ void vec_add_kernel(float* A, float* B, float* C, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {
        C[i] = A[i] + B[i];
    }
}

void vec_add_gpu(float* A, float* B, float* C, int N) {
    float *d_A, *d_B, *d_C;
    
    // 分配显存
    cudaMalloc(&d_A, N * sizeof(float));
    cudaMalloc(&d_B, N * sizeof(float));
    cudaMalloc(&d_C, N * sizeof(float));
    
    // 拷贝数据到GPU
    cudaMemcpy(d_A, A, N * sizeof(float), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, B, N * sizeof(float), cudaMemcpyHostToDevice);
    
    // 启动Kernel：计算Grid和Block大小
    int blockSize = 256;
    int gridSize = (N + blockSize - 1) / blockSize;
    vec_add_kernel<<<gridSize, blockSize>>>(d_A, d_B, d_C, N);
    
    // 拷贝结果回CPU
    cudaMemcpy(C, d_C, N * sizeof(float), cudaMemcpyDeviceToHost);
    
    // 释放显存
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
}
```

### 二、CUDA内存优化

#### 2.1 全局内存合并访问（Coalesced Access）

**问题**：全局内存访问效率低，多个线程访问不连续地址，导致内存事务浪费。

**优化方法**：确保相邻线程访问相邻内存地址（合并访问）。

**示例**：
```cuda
// 不合并访问：每个线程访问间隔为N的地址
__global__ void uncoalesced_access(float* A, float* B, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {
        B[i] = A[i * N];  // 不合并访问
    }
}

// 合并访问：相邻线程访问相邻地址
__global__ void coalesced_access(float* A, float* B, int N) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N) {
        B[i] = A[i];  // 合并访问
    }
}
```

#### 2.2 共享内存（Shared Memory）使用

**原理**：共享内存是线程块内共享的高速内存，延迟比全局内存低得多。

**适用场景**：
- 数据需要被线程块内多个线程重复访问
- 需要线程间通信（如归约、矩阵转置）

**示例：矩阵转置（使用共享内存优化）**
```cuda
#define BLOCK_SIZE 16

// 不使用共享内存：全局内存多次访问
__global__ void matrix_transpose_naive(float* A, float* B, int N) {
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (i < N && j < N) {
        B[j * N + i] = A[i * N + j];  // 写不合并
    }
}

// 使用共享内存：减少全局内存访问
__global__ void matrix_transpose_shared(float* A, float* B, int N) {
    __shared__ float tile[BLOCK_SIZE][BLOCK_SIZE + 1];  // +1避免bank conflict
    
    int i = blockIdx.y * blockDim.y + threadIdx.y;
    int j = blockIdx.x * blockDim.x + threadIdx.x;
    
    // 加载到共享内存
    if (i < N && j < N) {
        tile[threadIdx.y][threadIdx.x] = A[i * N + j];
    }
    __syncthreads();
    
    // 写回全局内存（转置）
    int i2 = blockIdx.x * blockDim.x + threadIdx.y;
    int j2 = blockIdx.y * blockDim.y + threadIdx.x;
    if (i2 < N && j2 < N) {
        B[i2 * N + j2] = tile[threadIdx.x][threadIdx.y];
    }
}
```

#### 2.3 常量内存和纹理内存

**常量内存**：
- 适用于只读、所有线程访问相同地址的数据（如模型权重、超参数）
- 有缓存，延迟低

**纹理内存**：
- 适用于只读、有空间局部性的数据（如图像、特征图）
- 有缓存，支持硬件插值

### 三、CUDA算子优化

#### 3.1 矩阵乘法优化（GEMM）

**问题**：矩阵乘法是AI推理的核心算子（如全连接层、卷积层），需要高效实现。

**优化步骤**：
1. **基础实现**：三重循环，全局内存访问
2. **使用共享内存**：分块矩阵乘法（Tiling）
3. **寄存器优化**：每个线程计算多个输出元素
4. **向量化内存访问**：使用float4/int4等向量类型

**示例：分块矩阵乘法（Tiling）**
```cuda
#define BLOCK_SIZE 16

__global__ void gemm_shared(float* A, float* B, float* C, int N) {
    __shared__ float As[BLOCK_SIZE][BLOCK_SIZE];
    __shared__ float Bs[BLOCK_SIZE][BLOCK_SIZE];
    
    int bx = blockIdx.x;
    int by = blockIdx.y;
    int tx = threadIdx.x;
    int ty = threadIdx.y;
    
    int row = by * BLOCK_SIZE + ty;
    int col = bx * BLOCK_SIZE + tx;
    
    float sum = 0.0f;
    
    // 分块计算
    for (int m = 0; m < N / BLOCK_SIZE; m++) {
        // 加载A和B的子块到共享内存
        As[ty][tx] = A[row * N + m * BLOCK_SIZE + tx];
        Bs[ty][tx] = B[(m * BLOCK_SIZE + ty) * N + col];
        __syncthreads();
        
        // 计算子块的乘积
        for (int k = 0; k < BLOCK_SIZE; k++) {
            sum += As[ty][k] * Bs[k][tx];
        }
        __syncthreads();
    }
    
    // 写回结果
    C[row * N + col] = sum;
}
```

#### 3.2 卷积算子优化

**优化方法**：
1. **Img2Col + GEMM**：将卷积转换为矩阵乘法
2. **Winograd算法**：减少计算量（适合小卷积核）
3. **FFT卷积**：适合大卷积核
4. **深度可分离卷积**：减少计算量和参数

### 四、CUDA性能调优

#### 4.1  occupancy（占用率）优化

**定义**：occupancy是指每个SM（Streaming Multiprocessor）上活跃的线程束（Warp）比例。

**优化方法**：
- 减少寄存器使用：每个线程使用的寄存器越少，活跃线程束越多
- 减少共享内存使用：共享内存使用越少，活跃线程束越多
- 调整Block大小：选择合适的Block大小（如128/256/512）

#### 4.2 分支发散（Branch Divergence）优化

**问题**：同一个Warp内的线程执行不同分支，导致串行执行。

**优化方法**：
- 避免Warp内分支：确保同一个Warp内的线程执行相同分支
- 使用`__syncthreads()`同步：确保线程块内所有线程到达同一点

#### 4.3 内存带宽优化

**优化方法**：
- 合并访问：确保相邻线程访问相邻内存地址
- 使用共享内存：减少全局内存访问
- 使用常量/纹理内存：适合只读数据
- 向量化访问：使用float4/int4等向量类型

---

## 示例/应用场景

### 示例1：优化向量加法性能

**场景**：比较CPU和GPU向量加法的性能，并优化GPU实现。

**步骤**：
1. **CPU实现**：
   ```c
   void vec_add_cpu(float* A, float* B, float* C, int N) {
       for (int i = 0; i < N; i++) {
           C[i] = A[i] + B[i];
       }
   }
   ```

2. **GPU基础实现**：
   ```cuda
   __global__ void vec_add_kernel(float* A, float* B, float* C, int N) {
       int i = blockIdx.x * blockDim.x + threadIdx.x;
       if (i < N) {
           C[i] = A[i] + B[i];
       }
   }
   ```

3. **性能对比**：
   | 实现 | 时间（ms） | 加速比 |
   |------|-------------|--------|
   | CPU（1 thread） | 1000 | 1x |
   | GPU（基础实现） | 10 | 100x |
   | GPU（优化后：合并访问、合适Block大小） | 5 | 200x |

### 示例2：优化矩阵乘法性能

**场景**：比较不同优化方法的矩阵乘法性能。

**性能对比**：
| 实现 | GFLOPS | 加速比 |
|------|--------|--------|
| CPU（1 thread） | 1 | 1x |
| GPU（基础实现） | 10 | 10x |
| GPU（共享内存优化） | 100 | 100x |
| GPU（cuBLAS库） | 300 | 300x |

**结论**：使用优化后的CUDA实现或cuBLAS库，可以显著提升性能。

---

## 【对应领域考点】

### GPU编程与CUDA优化常见考点

1. **GPU vs CPU**：区别、适用场景
2. **CUDA线程层次**：Thread、Block、Grid
3. **CUDA内存层次**：寄存器、共享内存、全局内存、常量内存、纹理内存
4. **CUDA编程基础**：Kernel编写、内存分配/拷贝、Kernel启动
5. **CUDA内存优化**：合并访问、共享内存使用、常量/纹理内存
6. **CUDA算子优化**：矩阵乘法优化、卷积算子优化
7. **CUDA性能调优**：occupancy优化、分支发散优化、内存带宽优化

### 实战考点

1. **CUDA编程基础考点**：
   - Kernel编写：使用`__global__`声明
   - 内存分配/拷贝：`cudaMalloc`、`cudaMemcpy`
   - Kernel启动：`<<<Grid, Block>>>`语法
   - 线程索引计算：`blockIdx.x`、`threadIdx.x`

2. **CUDA内存优化考点**：
   - 合并访问：什么是合并访问，如何实现
   - 共享内存：声明、使用、`__syncthreads()`
   - 常量内存：声明、使用、`__constant__`

3. **CUDA算子优化考点**：
   - 矩阵乘法优化：分块（Tiling）、共享内存使用
   - 卷积算子优化：Img2Col + GEMM、Winograd算法

4. **CUDA性能调优考点**：
   - occupancy优化：寄存器使用、共享内存使用、Block大小选择
   - 分支发散优化：避免Warp内分支
   - 内存带宽优化：合并访问、共享内存、向量化访问

---

## 最佳实践

### 1. 系统化CUDA优化流程

**不推荐**（零散优化）：
```text
不进行系统化优化，随意修改代码，导致优化效果有限
```

**推荐**（系统化流程）：
```text
1. 性能分析（Profiling）：
   - 使用Nsight Systems/Nsight Compute分析瓶颈
   - 找出热点函数（耗时最多）
2. 算法优化：
   - 选择最优算法（如矩阵乘法使用分块）
   - 减少计算量（如Winograd算法）
3. 内存优化：
   - 确保合并访问
   - 使用共享内存减少全局内存访问
   - 使用常量/纹理内存
4. 算子优化：
   - 优化核心算子（如GEMM、卷积）
   - 使用向量化访问
5. 性能调优：
   - 优化occupancy（调整Block大小、减少寄存器使用）
   - 优化分支发散
   - 优化内存带宽
6. 验证和测试：
   - 验证正确性（与CPU结果对比）
   - 测试性能（加速比、GFLOPS）
```

### 2. 选择合适Block大小

**不推荐**（随意选择Block大小）：
```text
Block大小选择随意，导致occupancy低，性能不佳
```

**推荐**（根据kernel特点选择）：
```text
- 基础计算：Block大小=256或512（充分利用SM）
- 共享内存密集型：Block大小=128或256（减少共享内存占用）
- 寄存器密集型：Block大小=64或128（减少寄存器使用）
- 使用cudaOccupancyMaxPotentialBlockSize()自动计算最优Block大小
```

### 3. 充分利用共享内存

**不推荐**（忽略共享内存）：
```text
不使用共享内存，导致全局内存访问频繁，性能不佳
```

**推荐**（合理使用共享内存）：
```text
- 数据需要被线程块内多个线程重复访问 → 使用共享内存
- 需要线程间通信（如归约、矩阵转置） → 使用共享内存
- 避免bank conflict：共享内存访问要对齐（如BLOCK_SIZE+1）
```

### 4. 持续性能监控和调优

**不推荐**（一次优化）：
```text
只进行一次优化，不持续监控和调优
```

**推荐**（持续监控调优）：
```text
- 建立性能基线：记录优化前性能（时间、GFLOPS）
- 每次优化后测试性能：对比优化效果
- 使用性能分析工具：Nsight Systems、Nsight Compute
- 持续调优：根据硬件更新、kernel更新调整优化策略
```

---

## 【常见错误】

### 1. 不进行性能分析直接优化

**错误示例**：
```text
不进行性能分析，凭感觉优化，导致优化方向错误
```

**正确做法**：
```text
- 使用性能分析工具（Nsight Systems、Nsight Compute）
- 找出瓶颈（计算瓶颈/内存瓶颈/通信瓶颈）
- 针对性优化
```

### 2. 忽略合并访问

**错误示例**：
```text
不确保合并访问，导致全局内存访问效率低
```

**正确做法**：
```text
- 确保相邻线程访问相邻内存地址
- 使用连续内存分配（如cudaMalloc分配的全局内存是连续的）
- 避免跳跃访问（如A[i * N]）
```

### 3. 共享内存使用不当

**错误示例**：
```text
共享内存使用不当，导致bank conflict或内存浪费
```

**正确做法**：
```text
- 避免bank conflict：共享内存访问要对齐（如BLOCK_SIZE+1）
- 合理使用共享内存大小：不要超过每个Block的共享内存限制（如48KB）
- 使用__syncthreads()同步：确保共享内存数据正确
```

### 4. 忽略occupancy优化

**错误示例**：
```text
不优化occupancy，导致GPU利用率低
```

**正确做法**：
```text
- 减少寄存器使用：每个线程使用的寄存器越少，活跃线程束越多
- 减少共享内存使用：共享内存使用越少，活跃线程束越多
- 调整Block大小：选择合适的Block大小（如128/256/512）
- 使用cudaOccupancyMaxPotentialBlockSize()自动计算最优Block大小
```

---

## 总结

GPU编程与CUDA优化是AI推理加速的重要基础，涉及线程模型、内存层次、算子优化、性能调优等多个方面。要做好CUDA编程和优化，需要：

1. **理解GPU架构**：GPU vs CPU、CUDA线程层次、CUDA内存层次
2. **掌握CUDA编程基础**：Kernel编写、内存管理、Kernel启动
3. **系统化优化流程**：性能分析 → 算法优化 → 内存优化 → 算子优化 → 性能调优 → 验证测试
4. **持续性能监控和调优**：建立性能基线、使用性能分析工具、持续调优

随着GPU架构持续演进（如Hopper、Blackwell），CUDA编程和优化将持续发展，包括更先进的内存层次、更智能的编译器优化、更完善的性能分析工具。

---

## 扩展阅读

### 高级主题

1. **CUDA高级优化**：Tensor Core使用、FP8计算、多GPU编程
2. **CUDA库使用**：cuBLAS、cuDNN、cuFFT、Thrust
3. **CUDA与AI推理**：使用CUDA优化LLM推理、卷积神经网络推理
4. **CUDA性能分析**：Nsight Systems、Nsight Compute、Visual Profiler

### 实战案例

1. **向量加法优化**：从CPU到GPU，逐步优化性能
2. **矩阵乘法优化**：从基础实现到分块优化，对比性能
3. **卷积算子优化**：Img2Col + GEMM、Winograd算法
4. **LLM推理优化**：使用CUDA优化Attention、FFN算子

### 工具和资源

1. **CUDA工具**：
   - Nsight Systems：https://developer.nvidia.com/nsight-systems
   - Nsight Compute：https://developer.nvidia.com/nsight-compute
   - CUDA Toolkit：https://developer.nvidia.com/cuda-toolkit

2. **学习资源**：
   - CUDA C++ Programming Guide：https://docs.nvidia.com/cuda/cuda-c-programming-guide/
   - CUDA示例：https://github.com/NVIDIA/cuda-samples
   - CUDA课程：Stanford CS149、CMU 15-418

---

**注**：本文件为GPU编程与CUDA优化核心内容，适合GPU程序员、AI系统工程师和推理引擎开发者学习。建议结合具体GPU硬件平台和kernel，实践不同的优化技术，积累实战经验。
