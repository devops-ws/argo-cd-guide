---
link: https://blog.argoproj.io/draft-argo-cd-v2-6-release-candidate-ced1853bbfdb
---

# Argo CD v2.6 Release Candidate

Argo CD v2.6 Release Candidate 发布了。在这个版本中，你会发现一些很赞的 Argo CD 功能以及改进。
有超过 83 名人员参与到了新功能开发、缺陷修复以及改进易用性。当然，正式版本的发布前还希望大家多多尝试。
我们非常开心地宣布 v2.6 的首个候选版本，并期待听到您的反馈。您可以反馈对新的变更的看法，以及发现了的缺陷。

![Photo by Mathieu Stern](https://miro.medium.com/max/720/1*Go_t0XBjnOlKfRnkDMyfyg.webp)
Photo by Mathieu Stern

## 参数化配置管理插件
配置管理插件（CMP）的参数化，使得插件可以申明并使用参数。
申明参数使得 CMPs 可以提供类似于内置配置管理工具（例如：Helm、Kustomize 等）的体验。
在此之前，只能通过设置环境变量给 CMPs 提供参数。

![](https://miro.medium.com/max/720/0*OrZrhoGvQYLXd9rS.webp)

感谢来自 Intuit 的 Michael Crenshaw 和 Zach Aller 在这个特性上做出的贡献。

## 通过选项 syncOptions `CreateNamespace=true` 创建的命名空间支持添加元信息
现在，你可以通过 `managedNamespaceMetadatain` 向 Application 所在的命名空间添加标签（label）和注解（annotation）。
这个特性会在命名空间是由 Argo CD 创建时添加自定义标签。下面是一个该功能的例子。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  namespace: test
spec:
  syncPolicy:
    managedNamespaceMetadata:
      labels: # The labels to set on the application namespace
        any: label
        you: like
      annotations: # The annotations to set on the application namespace
        the: same
        applies: for
        annotations: on-the-namespace
    syncOptions:
    - CreateNamespace=true
```

感谢来自 Krobier 的 Blake Pettersson 在这个功能上做出的贡献。

## 支持 Google Cloud Source 仓库
Argo CD 现在支持连接托管在 Google Cloud Source 上的仓库了。
这为依赖 Google Cloud Source 的应用打开了可能性，这是一个值得期待的功能。

感谢来自 GetYourGuide 的 Alex Eftimie 在这功能上做出的贡献。

## Application 支持多源
Application 对多源支持的支持是一个 beta 功能。
UI 和 CLI 任然只支持第一个源，完整的支持会在后续的版本中出现。
该功能在稳定之前可能会有不兼容的情况出现。

Argo CD 可以在单个 Application 中指定多个源。
Argo CD 会合并源后进行同步资源。该功能的一个使用场景是，Helm Chart 应用通常会
将 Helm Chart 与 values 文件分别存储。任何一个源有变化后，将会更新 Argo CD application。

下面指定多个源的例子。当您设置字段 `sources` 后，Argo CD 会忽略字段 `source`。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  sources:
    - chart: elasticsearch
      repoURL: https://helm.elastic.co
      targetRevision: 7.6.0
    - repoURL: https://github.com/argoproj/argocd-example-apps.git
      path: guestbook
      targetRevision: HEAD
```

感谢来自 Red Hat 的 Ishita Sequeira 在这个功能上做出的贡献。

## ApplicationSet 资源的渐进式 Rollouts
这是实验性并处于 alpha 阶段的功能，在后续的版本中可能会以不兼容的方式移除或修改。

借助这功能，ApplicationSet 控制器可以有序地创建、更新由 ApplicationSet 控制的资源。

作为实验性功能，渐进式 Rollouts 必须要通过以下方式显式地启用。

1. 传递参数 `--enable-progressive-rollouts` 给 ApplicationSet 控制器
1. 在 ApplicationSet 控制器中设置环境变量 `ARGOCD_APPLICATIONSET_ENABLE_PROGRESSIVE_ROLLOUTS=true`
1. 在 ArgoCD ConfigMap 中设置 `applicationsetcontroller.enable.progressive.rollouts: true`

为了使用渐进式 Rollouts，需要在 ApplicattionSet 中设置字段 `strategy`。
字段 `strategy` 允许你对生成的 Application 资源通过标签进行分组。
当 ApplicationSet 发生改变时，变更会顺序地应用到每组 Application 上。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook
spec:
  generators:
  - list:
     ...
  strategy:
    type: RollingSync
    rollingSync:
    ...
```

感谢 wmgroot 在这功能上的贡献。

## 其他显著的变更
在 v2.6 版本中，包含了 84 位 contributor 的 183 个（其中 53 名是新加入的） contribution，36 个功能以及 15 个缺陷修复。下面是其中的一部分：

* CMPv2 支持显示的 plugin.name（由 IBM 的 Sujeily Fonseca 提供）。这个新功能确保了 CMPv2 与 CMPv1 保持兼容。
* 在 Application 详情页面显示自动同步状态（由 GetYourGuide 的 Alex Eftimie 提供）。
* OCI Helm 仓库的 targetRevision 支持通配符（由 GetYourGuide 的 Alex Eftimie 提供）。
* 支持代理扩展 (#11307) (由 Intuit 的 Leonardo Almeida 提供）。
* 增加新的 admin 命令来打印 Argo CD 初始密码（由 RedHat 的 Abhishek Veeramalla 提供）。
* 在冲突的情况下，Matrix 生成器支持两个 Git 子生成器 (#10522) (#10523) （由 Matthew Bennett 提供）。
