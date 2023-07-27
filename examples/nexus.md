```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nexus
  namespace: argocd
spec:
  project: default
  source:
    chart: nexus-repository-manager
    repoURL: https://sonatype.github.io/helm3-charts
    targetRevision: "58.1.0"
    helm:
      releaseName: sonarqube
      parameters:
      - name: service.type
        value: NodePort
  destination:
    server: "https://kubernetes.default.svc"
    namespace: sonarqube
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
```
