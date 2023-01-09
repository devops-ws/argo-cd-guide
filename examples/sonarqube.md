下面是在 Argo CD 中通过 Helm 安装 [SonarQube](https://docs.sonarqube.org/latest/) 的例子：

```shell
cat <<EOF | kubectl apply -n argocd -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sonarqube
spec:
  project: default
  source:
    chart: sonarqube
    repoURL: https://SonarSource.github.io/helm-chart-sonarqube
    targetRevision: 6.0.1+425
    helm:
      releaseName: sonarqube
      parameters:
      - name: service.type
        value: NodePort
      - name: sonarProperties.sonar\.auth\.gitlab\.enabled
        value: 'true'
      - name: sonarProperties.sonar\.auth\.gitlab\.url
        value: http://10.121.218.82:6080/
      - name: sonarProperties.sonar\.auth\.gitlab\.applicationId\.secured
        value: 5ad8f157979f497231074b77b3734a3daa02ed73620e741a0e1b27c2c9903530
      - name: sonarProperties.sonar\.auth\.gitlab\.secret\.secured
        value: 23b1c7bc3583e8454c6a42a1d3bca232a8ada9ceea6913aaf565a50dadb7ea58
      - name: sonarProperties.sonar\.auth\.gitlab\.groupsSync
        value: 'true'
      - name: sonarProperties.sonar\.core\.serverBaseURL
        value: http://10.121.218.184:30008
      - name: plugins.install[0]
        value: https://github.com/vaulttec/sonar-auth-oidc/releases/download/v2.1.1/sonar-auth-oidc-plugin-2.1.1.jar
      - name: sonarProperties.sonar\.auth\.oidc\.enabled
        value: 'true'
      - name: sonarProperties.sonar\.auth\.oidc\.issuerUri
        value: 'https://10.121.218.184:31392/api/dex'
      - name: sonarProperties.sonar\.auth\.oidc\.clientId\.secured
        value: 'sonarqube'
      - name: sonarProperties.sonar\.auth\.oidc\.clientSecret\.secured
        value: 'rick'
      - name: sonarProperties.sonar\.auth\.oidc\.scopes
        value: 'openid email profile'
  destination:
    server: "https://kubernetes.default.svc"
    namespace: sonarqube
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    automated:
      prune: true
      selfHeal: true
EOF
```
