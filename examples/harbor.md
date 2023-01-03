下面是在 Argo CD 中通过 Helm 安装 [Harbor](https://goharbor.io/) 的例子：

```shell
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: harbor
  namespace: argocd
spec:
  project: default
  source:
    chart: harbor
    repoURL: https://helm.goharbor.io
    targetRevision: 1.10.2
    helm:
      releaseName: harbor
      parameters:
      - name: expose.type
        value: nodePort
      - name: expose.tls.enabled
        value: "false"
      - name: externalURL
        value: http://10.121.218.184:30002
  destination:
    server: "https://kubernetes.default.svc"
    namespace: harbor
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
    automated:
      prune: true
      selfHeal: true
```

备注：
* 建议设置访问地址，也就是：`externalURL`
