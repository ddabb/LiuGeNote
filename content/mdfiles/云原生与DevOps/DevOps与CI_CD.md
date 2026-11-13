---
title: DevOps与CI/CD
tags: [云原生, DevOps, CI/CD, 持续集成, 持续交付, GitOps]
description: DevOps与CI/CD 定义 DevOps是开发（Dev）与运维（Ops）的文化、实践和工具集合，目标是缩短系统开发生命周期，持续交付高质量软件。 CI/CD是DevOps的核心实践： - CI（持
---

# DevOps与CI/CD

## 定义

DevOps是**开发（Dev）与运维（Ops）的文化、实践和工具集合**，目标是缩短系统开发生命周期，持续交付高质量软件。

**CI/CD**是DevOps的核心实践：
- **CI（持续集成）**：频繁合并代码到主干，自动化构建和测试
- **CD（持续交付/部署）**：自动化将代码部署到生产环境

**核心价值**：
- 加快交付速度（从数周到数天）
- 提高软件质量（自动化测试覆盖）
- 降低部署风险（小批量频繁发布）
- 缩短故障恢复时间（快速回滚）

## 核心概念

### 1. 持续集成（CI）
- **定义**：开发人员频繁（每天多次）合并代码到主干分支
- **关键实践**：自动化构建、自动化测试、快速反馈
- **代表工具**：Jenkins、GitLab CI、GitHub Actions、CircleCI

### 2. 持续交付（Continuous Delivery）
- **定义**：代码随时可安全部署到生产环境（需人工审批）
- **关键实践**：自动化部署流水线、环境一致性、蓝绿部署
- **与持续部署区别**：持续部署无需人工审批，自动部署到生产

### 3. 持续部署（Continuous Deployment）
- **定义**：代码通过所有测试后自动部署到生产环境
- **前置条件**：完善的自动化测试、监控告警、快速回滚机制
- **适用场景**：低风险服务、内部系统

### 4. GitOps
- **定义**：使用Git作为声明式基础设施和应用的单一事实来源
- **核心思想**：Git仓库存储期望状态，自动化系统同步实际状态
- **代表工具**：ArgoCD、Flux CD

### 5. 流水线即代码（Pipeline as Code）
- **定义**：将CI/CD流水线配置存储为代码（YAML、Groovy）
- **核心价值**：版本控制、可复现、代码审查
- **代表实践**：Jenkinsfile、GitLab CI .gitlab-ci.yml

## 详细内容

### CI/CD流水线架构

```
代码提交 (Git Push)
      ↓
触发CI流水线
      ↓
构建 (Build) → 单元测试 (Unit Test)
      ↓
静态代码分析 (SonarQube) → 安全扫描 (Trivy)
      ↓
打包 (Package) → 构建镜像 (Docker Build)
      ↓
推送到镜像仓库 (Docker Push)
      ↓
触发CD流水线
      ↓
部署到测试环境 (Deploy to Test) → 集成测试 (Integration Test)
      ↓
部署到预发布环境 (Deploy to Staging) → 验收测试 (UAT)
      ↓
人工审批 (Manual Approval)
      ↓
部署到生产环境 (Deploy to Production) → 烟雾测试 (Smoke Test)
      ↓
监控与告警 (Monitor & Alert)
```

### Jenkins流水线详解

#### Jenkinsfile示例（声明式流水线）
```groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("myapp:${BUILD_NUMBER}")
                }
            }
        }
        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry('https://registry.example.com', 'docker-credentials') {
                        docker.image("myapp:${BUILD_NUMBER}").push()
                    }
                }
            }
        }
        stage('Deploy to Test') {
            steps {
                sh 'kubectl apply -f k8s/test/'
            }
        }
        stage('Integration Test') {
            steps {
                sh 'mvn verify -Pintegration-test'
            }
        }
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Yes'
                sh 'kubectl apply -f k8s/prod/'
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
```

### GitOps工作流程

#### ArgoCD架构
```
Git仓库 (存储期望状态)
      ↓ (Webhook通知)
ArgoCD Server (检测差异)
      ↓
ArgoCD Controller (同步状态)
      ↓
Kubernetes集群 (实际应用状态)
```

#### ArgoCD应用配置示例
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/example/myapp-config.git
    targetRevision: HEAD
    path: overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

### 测试策略

#### 测试金字塔
```
                    /\
                   /  \
                  / E2E \  (端到端测试，少量)
                 /______\
                /        \
               / Integration \ (集成测试，中量)
              /____________\
             /              \
            /   API Testing   \ (API测试，中量)
           /________________\
          /                    \
         /   Unit Testing       \ (单元测试，大量)
        /______________________\
```

**最佳实践**：
- 单元测试：快速、隔离、 mocking
- 集成测试：测试组件间交互
- E2E测试：模拟用户真实操作

### 部署策略

#### 蓝绿部署（Blue-Green Deployment）
- **原理**：同时运行两个环境（蓝=当前版本，绿=新版本），流量切换瞬间完成
- **优势**：零停机、快速回滚
- **劣势**：资源消耗翻倍

#### 金丝雀发布（Canary Release）
- **原理**：先让小部分用户使用新版本，逐步扩大范围
- **优势**：渐进式发布，风险可控
- **工具**：Istio、Flagger、Argo Rollouts

#### 滚动更新（Rolling Update）
- **原理**：逐步替换旧版本实例
- **优势**：资源消耗少
- **劣势**：新旧版本共存期间可能不兼容

## 示例/应用场景

### 场景1：微服务CI/CD流水线
**需求**：10个微服务，每个服务独立构建、测试、部署

**方案**：
- **代码仓库**：每个微服务独立仓库
- **CI流水线**：GitHub Actions，每个仓库独立流水线
- **镜像管理**：Harbor镜像仓库，镜像扫描（Trivy）
- **CD流水线**：ArgoCD，GitOps模式
- **配置管理**：Helm Chart，按环境（test/staging/prod）覆盖 values

### 场景2：数据库Schema迁移
**需求**：服务版本更新同时迁移数据库Schema

**方案**：
- **迁移工具**：Flyway、Liquibase
- **CI流水线集成**：
  ```yaml
  - name: Run Database Migration
    run: |
      flyway -url=$DB_URL -user=$DB_USER -password=$DB_PASSWORD migrate
  ```
- **回滚策略**：Flyway undo脚本，或蓝绿部署（新旧版本使用不同数据库Schema）

### 场景3：AI模型服务CI/CD（对应岗位要求）
**需求**：AI推理服务频繁更新模型版本

**方案**：
- **模型版本管理**：DVC（Data Version Control）、MLflow
- **CI流水线**：
  1. 训练模型 → 评估指标（精度、延迟）
  2. 如果指标达标 → 构建推理服务镜像
  3. 推送到镜像仓库
- **CD流水线**：
  1. ArgoCD检测到新镜像版本
  2. 金丝雀发布（1%流量 → 10% → 100%）
  3. 监控推理延迟和错误率，异常自动回滚

## 【对应领域考点】

1. **CI/CD核心概念**：持续集成、持续交付、持续部署区别
2. **流水线设计**：构建、测试、打包、部署各阶段最佳实践
3. **GitOps原理**：声明式配置、版本控制、自动化同步
4. **部署策略对比**：蓝绿部署、金丝雀发布、滚动更新适用场景
5. **测试策略**：测试金字塔、单元测试、集成测试、E2E测试
6. **Jenkins vs GitLab CI vs GitHub Actions**：工具选型考量
7. **ArgoCD/Flagger**：GitOps工具、金丝雀发布自动化
8. **安全集成**：DevSecOps、镜像扫描、SAST/DAST

## 最佳实践

### 1. 流水线设计
- **快速反馈**：单元测试在5分钟内完成
- **并行执行**：无依赖的Stage并行执行
- **失败快速（Fail Fast）**：任何阶段失败立即终止流水线
- **环境一致性**：开发、测试、生产环境尽量一致（容器化保证）

### 2. 版本控制
- **主干开发（Trunk-Based Development）**：频繁合并到主干，避免长期分支
- **特性开关（Feature Toggle）**：代码部署但功能不启用，降低发布风险
- **语义化版本（Semantic Versioning）**：v主版本.次版本.修订号

### 3. 配置管理
- **配置与代码分离**：配置文件存储到ConfigMap/Secret，不硬编码
- **环境配置分离**：使用Helm values按环境覆盖
- **敏感信息管理**：使用Vault、Sealed Secrets，不明文存储

### 4. 监控与告警
- **部署后监控**：部署后持续监控关键指标（错误率、延迟、流量）
- **自动化回滚**：指标异常自动触发回滚
- **变更追踪**：每次部署记录版本、时间、操作人员

### 5. 安全集成（DevSecOps）
- **镜像扫描**：Trivy、Clair扫描镜像漏洞
- **SAST（静态应用安全测试）**：SonarQube、Checkmarx
- **DAST（动态应用安全测试）**：OWASP ZAP、Burp Suite
- **依赖扫描**：GitHub Dependabot、Snyk

## 【常见错误】

### 错误1：过长的CI流水线
**表现**：CI流水线执行超过30分钟
**后果**：反馈周期长，开发效率降低
**正确做法**：并行执行、增量构建、测试分层（单元测试快速反馈，集成测试异步执行）

### 错误2：手工部署
**表现**：生产环境手工SSH登录部署
**后果**：部署不一致、易出错、不可追溯
**正确做法**：所有部署通过CI/CD自动化

### 错误3：测试覆盖率不足
**表现**：仅单元测试，无集成测试和E2E测试
**后果**：生产环境频发集成问题
**正确做法**：遵循测试金字塔，多层级测试覆盖

### 错误4：忽略回滚策略
**表现**：部署失败无法快速回滚
**后果**：故障恢复时间长（MTTR高）
**正确做法**：每次部署前备份、蓝绿部署或金丝雀发布支持快速回滚

### 错误5：敏感信息泄露
**表现**：密码、API Key硬编码在代码或CI/CD配置中
**后果**：安全风险，凭证泄露
**正确做法**：使用Vault、AWS Secrets Manager等密钥管理工具

## 总结

DevOps与CI/CD是云原生时代**软件交付的标准实践**，核心价值是**快速、高质量、低风险**的交付软件。

**关键要点**：
1. **CI/CD流水线**：自动化构建、测试、部署全流程
2. **GitOps**：声明式配置、版本控制、自动化同步
3. **部署策略**：蓝绿部署、金丝雀发布降低发布风险
4. **测试策略**：测试金字塔，多层级覆盖
5. **DevSecOps**：安全左移，集成到CI/CD流水线

**学习路径**：
1. 掌握CI/CD核心概念（持续集成、持续交付、持续部署）
2. 实践Jenkins/GitLab CI/GitHub Actions搭建流水线
3. 学习GitOps（ArgoCD、Flux CD）
4. 理解部署策略（蓝绿、金丝雀、滚动更新）
5. 建设DevSecOps（镜像扫描、SAST/DAST、依赖扫描）

DevOps不仅是工具，更是**文化和思维模式的转变**。
