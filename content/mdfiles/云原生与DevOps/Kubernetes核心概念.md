---
title: Kubernetes核心概念
tags: [云原生, Kubernetes, 容器编排, 容器管理]
description: Kubernetes核心概念 定义 Kubernetes（K8s）是开源的容器编排平台，用于自动化部署、扩展和管理容器化应用。Google基于内部Borg系统经验开源，现为CNCF核心项目。 核心价值
---

# Kubernetes核心概念

## 定义

Kubernetes（K8s）是开源的**容器编排平台**，用于自动化部署、扩展和管理容器化应用。Google基于内部Borg系统经验开源，现为CNCF核心项目。

**核心价值**：
- 自动化工件部署与运维
- 弹性扩缩容应对流量波动
- 自我修复（Self-healing）保证高可用
- 服务发现和负载均衡
- 滚动更新和灰度发布

## 核心概念

### 1. 集群架构
**控制平面（Control Plane）组件**：
- **API Server**：集群统一入口，所有操作通过REST API
- **etcd**：分布式键值存储，保存集群状态和配置
- **Scheduler**：调度Pod到合适节点（考虑资源、亲和性、污点等）
- **Controller Manager**：运行控制器（如Deployment、ReplicaSet控制器）
- **Cloud Controller Manager**：与云厂商API交互（可选）

**数据平面（Data Plane）组件**：
- **Kubelet**：节点代理，确保容器在Pod中运行
- **Kube-proxy**：维护网络规则，实现Service抽象
- **Container Runtime**：容器运行时（Docker、Containerd、CRI-O）

### 2. 对象模型
**基础对象**：
- **Pod**：最小调度单元，包含一个或多个容器
- **ReplicaSet**：维持Pod副本数量
- **Deployment**：声明式更新Pod和ReplicaSet
- **StatefulSet**：有状态应用（稳定的网络标识、持久存储）
- **DaemonSet**：每个节点运行一个Pod副本
- **Job/CronJob**：批处理任务

**配置对象**：
- **ConfigMap**：存储非敏感配置数据
- **Secret**：存储敏感数据（密码、Token）
- **ServiceAccount**：Pod的身份标识

**存储对象**：
- **PersistentVolume（PV）**：集群级存储资源
- **PersistentVolumeClaim（PVC）**：用户对存储的请求
- **StorageClass**：动态供给存储

**网络对象**：
- **Service**：为一组Pod提供稳定网络访问
- **Ingress**：HTTP/HTTPS路由规则
- **NetworkPolicy**：网络流量控制策略

### 3. 控制器模式
**核心思想**：声明式API + 控制器循环（Control Loop）
- 用户声明期望状态（Desired State）
- 控制器观察实际状态（Actual State）
- 控制器调和差异，驱动实际状态向期望状态收敛

**典型控制器**：
- **Deployment Controller**：管理ReplicaSet版本和更新
- **ReplicaSet Controller**：维持Pod副本数
- **Node Controller**：监控节点状态
- **Endpoint Controller**：维护Service到Pod的映射

## 详细内容

### Pod详解
**为什么需要Pod**：
- 紧密耦合的容器需要共享资源（网络、存储）
- 类似"豌豆荚"概念，一个Pod内容器共享IPC、Network、UTS命名空间

**Pod网络模型**：
- 每个Pod分配唯一IP（扁平网络模型）
- 所有Pod在不使用NAT的情况下可以相互通信
- 节点上的Pod可以与所有节点上的Pod通信

**Pod生命周期**：
- **Pending**：已接受但未调度或拉取镜像
- **Running**：绑定到节点且容器已创建
- **Succeeded/Failed**：所有容器成功/失败终止
- **Unknown**：无法获取状态

### 调度机制
**调度流程**：
1. 过滤（Filtering）：排除不满足条件的节点
2. 打分（Scoring）：对可行节点评分
3. 绑定（Binding）：选择得分最高节点

**影响调度因素**：
- **资源请求（Requests）**：CPU、内存请求量
- **节点亲和性（Node Affinity）**：硬性/软性规则
- **Pod亲和性/反亲和性**：Pod间位置关系
- **污点（Taints）和容忍（Tolerations）**：节点排斥机制

### 服务发现与负载均衡
**Service类型**：
- **ClusterIP**：集群内部访问（默认）
- **NodePort**：通过节点IP+端口访问
- **LoadBalancer**：云厂商负载均衡器
- **ExternalName**：DNS CNAME记录

**服务发现机制**：
- **环境变量**：早期方式，有限制
- **DNS**：推荐方式，CoreDNS提供域名解析
- **Headless Service**：无ClusterIP，直接返回Pod IP

### 存储编排
**Volume类型**：
- **emptyDir**：Pod生命周期内的临时存储
- **hostPath**：挂载节点文件系统
- **persistentVolumeClaim**：动态申请持久存储
- **configMap/secret**：将配置/密钥挂载为文件

**持久化存储流程**：
1. 管理员创建PV（或StorageClass动态供给）
2. 用户创建PVC绑定PV
3. Pod通过PVC挂载存储

### 滚动更新与回滚
**Deployment更新策略**：
- **RollingUpdate**：滚动更新（默认）
- **Recreate**：先删除旧Pod，再创建新Pod

**滚动更新流程**：
1. 创建新ReplicaSet，逐步扩容
2. 旧ReplicaSet逐步缩容
3. 通过maxSurge和maxUnavailable控制节奏

**回滚机制**：
- 保留历史ReplicaSet
- 可回滚到任意历史版本

## 示例/应用场景

### 场景1：Web应用部署
**需求**：部署前端+后端，前端3副本，后端5副本
**K8s方案**：
- 前端：Deployment（replicas=3）+ Service（ClusterIP）
- 后端：Deployment（replicas=5）+ Service（ClusterIP）
- 数据库：StatefulSet + Headless Service + PVC
- 外部访问：Ingress路由到前端Service

### 场景2：批处理任务
**需求**：每天定时执行数据处理任务
**K8s方案**：
- 使用CronJob资源
- 配置schedule: "0 2 * * *"（每天凌晨2点）
- 任务失败重试策略（backoffLimit）
- 任务执行完自动清理（successfulJobsHistoryLimit）

### 场景3：有状态应用（数据库）
**需求**：部署MySQL主从复制
**K8s方案**：
- 主库：StatefulSet（replicas=1）+ Headless Service
- 从库：StatefulSet（replicas=2）+ Headless Service
- 稳定网络标识：mysql-0.mysql.default.svc.cluster.local
- 持久存储：每个Pod独立PVC

## 【对应领域考点】

1. **Pod销毁流程**：删除Pod → 发送SIGTERM → 等待grace period → 发送SIGKILL
2. **控制器模式**：声明式API、控制循环、调和循环（Reconcile Loop）
3. **调度器算法**：过滤+打分，优先级函数
4. **Service实现机制**：kube-proxy iptables/ipvs模式，IPVS性能更优
5. **存储动态供给**：StorageClass + Provisioner，按需创建PV
6. **滚动更新参数**：maxSurge（最大超出副本数）、maxUnavailable（最大不可用副本数）
7. **健康检查**：livenessProbe（存活探针）、readinessProbe（就绪探针）、startupProbe（启动探针）
8. **资源QoS等级**：Guaranteed、Burstable、BestEffort

## 最佳实践

### 1. 资源配置
- **必须设置requests和limits**：避免资源争抢，保证QoS等级
- **CPU单位**：cpu: "500m" = 0.5核；memory单位：memory: "512Mi"
- **QoS策略**：关键服务设置为Guaranteed（requests=limits）

### 2. 健康检查配置
- **livenessProbe**：检测容器是否存活，失败则重启
- **readinessProbe**：检测容器是否就绪，失败则从Service端点移除
- **startupProbe**：慢启动容器专用，在启动探针成功前禁用其他探针

### 3. 标签（Labels）和注解（Annotations）使用
- **Labels**：用于选择对象（selector），应有意义且稳定
- **Annotations**：存储非标识信息（如构建信息、联系方式）
- **推荐标签**：app、version、component、part-of、managed-by

### 4. 命名空间（Namespace）隔离
- **按环境隔离**：dev、test、prod命名空间
- **资源配额**：ResourceQuota限制命名空间总资源
- **网络策略**：NetworkPolicy控制命名空间间流量

### 5. 安全加固
- **RBAC**：基于角色的访问控制，最小权限原则
- **Pod Security Standards**：Privileged、Baseline、Restricted
- **Secret加密**：启用EncryptionConfiguration加密etcd中的Secret
- **网络策略**：限制Pod间通信，默认拒绝所有流量

## 【常见错误】

### 错误1：未设置资源请求和限制
**表现**：Pod未配置requests/limits
**后果**：节点资源超卖，关键Pod被驱逐
**正确做法**：强制所有Pod设置resources.requests和resources.limits

### 错误2：使用latest标签
**表现**：镜像标签为latest
**后果**：无法追溯版本，回滚困难
**正确做法**：使用具体版本标签（如v1.2.3），配合镜像摘要（digest）

### 错误3：忽视探针配置
**表现**：未配置livenessProbe和readinessProbe
**后果**：服务不可用但Pod未重启，流量打到未就绪Pod
**正确做法**：所有服务必须配置探针，初始延迟（initialDelaySeconds）要充足

### 错误4：在Pod中存储数据
**表现**：使用emptyDir或hostPath存储重要数据
**后果**：Pod重建数据丢失
**正确做法**：使用PV/PVC持久化，数据库使用云托管服务

### 错误5：忽视日志收集
**表现**：日志输出到文件，未集中收集
**后果**：Pod重建后日志丢失，故障排查困难
**正确做法**：日志输出到stdout/stderr，配合EFK/PLG栈收集

## 总结

Kubernetes是云原生时代的**操作系统**，掌握其核心概念是云原生工程师的必修课。

**关键要点**：
1. **声明式API**：描述期望状态，系统自动调和
2. **控制器模式**：控制循环保证实际状态=期望状态
3. **调度机制**：资源请求、亲和性、污点共同决定Pod位置
4. **服务发现**：DNS + Service抽象，屏蔽后端变化
5. **存储编排**：PV/PVC/StorageClass解耦存储与计算

**学习路径**：
1. 理解Pod、Deployment、Service核心概念
2. 掌握调度、网络、存储三大机制
3. 实践滚动更新、扩缩容、自愈能力
4. 深入控制器模式和可扩展机制（CRD、Operator）
5. 参与Kubernetes社区，阅读官方文档

Kubernetes复杂度高，但掌握后收益巨大，是云原生领域的基石技术。
