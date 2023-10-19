以下是通过 Helm 来安装 SkyWalking 的例子：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: skywalking
  namespace: argocd
spec:
  project: default
  source:
    chart: "skywalking-helm"
    repoURL: registry-1.docker.io/apache
    targetRevision: 4.3.0
    helm:
      releaseName: skywalking
      parameters:
      - name: oap.image.tag
        value: "9.2.0"
      - name: oap.storageType
        value: elasticsearch
      - name: ui.image.tag
        value: "9.2.0"
  destination:
    server: "https://kubernetes.default.svc"
    namespace: skywalking
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    - RespectIgnoreDifferences=true
    automated:
      prune: true
      selfHeal: true
````
