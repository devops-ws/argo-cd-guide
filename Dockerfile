FROM ghcr.io/linuxsuren/hd:v0.0.70

RUN hd i kubernetes-sigs/kubectl
RUN hd get https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

CMD ["kubectl", "apply", "-f", "install.yaml"]
