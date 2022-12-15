# Argo CD Guide

[Argo CD]（https://argo-cd.readthedocs.io/） 是基于 [Kubernetes](https://kubernetes.io/) 的申明式、GitOps 持续部署工具。

## 安装
TODO

## 一个简单的示例
TODO

## 概念
TODO

## 模板工具
TODO

## Webhook
TODO

```
https://ip:port/api/webhook
```

## 配置管理插件
配置管理工具（Config Management Plugin，CMP）使得 Argo CD 可以支持 Helm、Kustomize 以外的（可转化为 Kubernetes 资源）格式。

例如：我们可以将 GitHub Actions 的配置文件转为 Argo Workflows 的文件，从而实现在不了解 Argo Workflows 的 `WorkflowTemplate` 写法的前提下，也可以把 Argo Workflows 作为 CI 工具。

> 下面的例子中需要用到 Argo Workflows，请自行安装，或查看[这篇中文教程](https://github.com/LinuxSuRen/argo-workflows-guide)。

我们只需要将插件作为 sidecar 添加到 `argocd-repo-server` 即可。下面是 sidecar 的配置：

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-repo-server
  namespace: argocd
spec:
  template:
    spec:
      containers:
      - args:
        - --loglevel
        - debug
        command:
        - /var/run/argocd/argocd-cmp-server
        image: ghcr.io/linuxsuren/github-action-workflow:master
        imagePullPolicy: IfNotPresent
        name: tool
        resources: {}
        securityContext:
          runAsNonRoot: true
          runAsUser: 999
        volumeMounts:
        - mountPath: /var/run/argocd
          name: var-files
        - mountPath: /home/argocd/cmp-server/plugins
          name: plugins
```

然后，再添加如下 Argo CD Application 后，我们就可以看到已经有多个 Argo Workflows 被创建出来了。


```yaml
kind: Application
metadata:
  name: yaml-readme
  namespace: argocd
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    path: .github/workflows/                            # It will generate multiple Argo CD application manifests 
                                                        # base on YAML files from this directory.
                                                        # Please make sure the path ends with slash.
    plugin: {}                                          # Argo CD will choose the corresponding CMP automatically
    repoURL: https://gitee.com/linuxsuren/yaml-readme   # a sample project for discovering manifests
    targetRevision: HEAD
  syncPolicy:
    automated:
      selfHeal: true
```

这一点对于 Argo Workflows 落地为持续集成（CI）工具时，非常有帮助。如果您觉得 GitHub Actions 的语法足够清晰，那么，可以直接使用上面的插件。或者，您希望能定义出更简单的 YAML，也可以自行实现插件。插件的核心逻辑就是将目标文件（集）转为 Kubernetes 的 YAML 文件，在这里就是 `WorkflowTemplate`。

如果再发散性地思考下，我们也可以通过自定义格式的 YAML（或 JSON 等任意格式）文件转为 Jenkins 可以识别的 Jenkinsfile，或其他持续集成工具的配置文件格式。

## 凭据管理
TODO

## 单点登录
TODO

## 组件介绍
TODO
