# Argo CD Guide

[Argo CD](https://argo-cd.readthedocs.io/) 是基于 [Kubernetes](https://kubernetes.io/) 的申明式、GitOps 持续部署工具。

本教程可以通过 [mde](https://github.com/LinuxSuRen/md-exec) 实现交互式体验。

## 安装
首先，你需要有一套 [Kubernetes](https://github.com/kubernetes/kubernetes/) 环境。下面的工具可以帮助你快速按照好一套 Kubernetes 环境：

> 推荐使用 [hd](https://github.com/LinuxSuRen/http-downloader) 安装下面的工具
>
> 安装 `hd` 的命令为：`curl https://linuxsuren.github.io/tools/install.sh|bash`

| 工具 | 工具安装 |使用 |
|---|---|---|
| [k3d](https://k3d.io/) | `hd i k3d` | `k3d cluster create` |
| [kubekey](https://github.com/kubesphere/kubekey) | `hd i kk` | `kk create cluster` |
| [minikube](https://github.com/kubernetes/minikube) | `hd i minikube` | `minikube start` |

```shell
#!title: Install K3d
hd i k3d
```

```shell
#!title: Reinstall K3d cluster
k3d cluster delete
k3d cluster create
```

当 Kubernetes 环境就绪后，就可以通过下面的命令会在命名空间（`argo`）下安装最新版本的 `Argo CD`：

```shell
#!title: Install ArgoCD
kubectl create namespace argocd || true
hd get https://raw.githubusercontent.com/argoproj/argo-cd/master/manifests/install.yaml
kubectl apply -n argocd -f install.yaml || rm -rf install.yaml
rm -rf install.yaml
```

如果你的环境访问 GitHub 时有网络问题，可以使用下面的命令来安装：

```shell
docker run -it --rm -v /root/.kube/:/root/.kube --network host --pull always ghcr.io/linuxsuren/argo-cd-guide:master
```

查看初始化密码：
```shell
#!title: Get Password
kubectl -n argocd get secret argocd-initial-admin-secret -ojsonpath={.data.password} | base64 -d
```

设置访问方式：
```shell
kubectl -n argocd patch svc argocd-server --type='json' -p '[{"op":"replace", "path":"/spec/type", "value":"NodePort"}, {"op":"add", "path":"/spec/ports/0/nodePort","value":31518}]'
# 暴露 k3d 端口
k3d node edit k3d-k3s-default-serverlb --port-add 31518:31518
```

推荐使用的工具：

||||
|---|---|---|
| [k9s](https://k9scli.io/) | `hd i k9s` | K9s is a terminal based UI to interact with your Kubernetes clusters. |
| `argocd` | `hd i argoproj/argo-cd` |  |

## 一个简单的示例
执行下面的命令后

```shell
#!title: Create A Sample App +f
cat <<EOF | kubectl apply -n argocd -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: learn-pipeline-go
spec:
  destination:
    namespace: default
    server: https://kubernetes.default.svc
  project: default
  source:
    repoURL: https://gitee.com/devops-ws/learn-pipeline-go   # 示例工程
    path: kustomize                                           # 从该目录下查找 Kubernetes 文件
    targetRevision: HEAD
    kustomize:
      namePrefix: foo
EOF
```

更多应用的例子请查看：

* [SonarQube](examples/sonarqube.md)
* [Harbor](examples/harbor.md)

## 概念
TODO

## 同步策略

Argo CD 可以[指定 Git 仓库中的特定目录](https://argo-cd.readthedocs.io/en/stable/user-guide/directory/)，已经一些通用配置：
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample
spec:
  source:
    repoURL: https://github.com/devops-ws/learn-pipeline-go
    targetRevision: HEAD
    path: kustomize                           # 指定父目录
    directory:
      recurse: true                           # 支持遍历子目录
      exclude: '{config.json,env-usw2/*}'     # 忽略部分
      include: '*.yaml'                       # 包含所有 YAML 文件
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
```

设置[同步策略](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/)：
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample
spec:
  syncPolicy:
    syncOptions:
    - CreateNamespace=true      # 自动创建命名空间
    automated:
      prune: true               # Git 库中删除的资源，也会在集群中删除
      selfHeal: true
```

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
apiVersion: argoproj.io/v1alpha1
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

由于用到 PVC 作为 Pod 之间的共享存储，我们还需要安装对应的依赖。如果是测试环境，可以安装 [OpenEBS](https://openebs.io/docs/user-guides/installation)。并设置其中的 为[默认存储卷](https://kubernetes.io/zh-cn/docs/tasks/administer-cluster/change-default-storage-class/)：

```shell
kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

如果需要用到 Git 凭据的话，可以通过下面的命令拿到：

```shell
kubectl create secret generic git-secret --from-file=id_rsa=/root/.ssh/id_rsa --from-file=known_hosts=/root/.ssh/known_hosts --dry-run=client -oyaml
```

这一点对于 Argo Workflows 落地为持续集成（CI）工具时，非常有帮助。如果您觉得 GitHub Actions 的语法足够清晰，那么，可以直接使用上面的插件。或者，您希望能定义出更简单的 YAML，也可以自行实现插件。插件的核心逻辑就是将目标文件（集）转为 Kubernetes 的 YAML 文件，在这里就是 `WorkflowTemplate`。

如果再发散性地思考下，我们也可以通过自定义格式的 YAML（或 JSON 等任意格式）文件转为 Jenkins 可以识别的 Jenkinsfile，或其他持续集成工具的配置文件格式。

## 凭据管理
可以通过下面的命令，生成一个加密后的 Secret：
```shell
kubectl create secret generic test --from-literal=username=admin --from-literal=password=admin --dry-run=client -oyaml -n default | kubeseal -oyaml
```

下面是生成 Docker 认证信息的命令：
```shell
kubectl create secret docker-registry harbor --docker-server='10.121.218.184:30002' \
  --docker-username=admin --docker-password=password \
  --dry-run=client -oyaml -n default | kubeseal -oyaml
```

## 单点登录
Argo CD 内置了 Dex 服务，我们可以参考如下的配置来对接外部身份认证服务：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://10.121.218.184:31392
  dex.config: |
    logger:
      level: debug
    connectors:
      - type: gitlab
        id: gitlab
        name: GitLab
        config:
          baseURL: http://10.121.218.82:6080
          clientID: b9119ac2313f62625d8b1e9648f7b10b9dad9c5198f19e5df731b09ffa5d008d
          clientSecret: a0c1bef745da758609acceb5beba3c0104f04c3b0a491aee7c7c479ed3e26309
          redirectURI: https://10.121.218.184:31392/api/dex/callback
          groups:
          - dev               # 只允许 dev 用户组
          useLoginAsID: false
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.csv: |
    # 只允许 dev 组的用户查看 application
    p, role:org-readonly, applications, get, default/*, allow

    g, dev, role:org-readonly           # 假如用户组名为 dev
  policy.default: role:org-readonly
  scopes: '[groups, email]' 
```

## 组件介绍
TODO

## FAQ

| 组件 | 日志 | 方案 |
|---|---|---|
| `argocd-repo-server` | `gpg --no-permission-warning --logger-fd 1 --batch --gen-key /tmp/gpg-k ││ ey-recipe1158238699 failed exit status 2` | 删除 `seccompProfile` |

## 其他资料
* [Argo CD 视频教程](https://www.bilibili.com/video/BV17F411h7Zh/)
