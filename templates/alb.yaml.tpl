apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ingress
  namespace: argo
spec:
  project: helm
  source:
    repoURL: https://aws.github.io/eks-charts
    targetRevision: 1.7.0
    chart: aws-load-balancer-controller
    helm:
      releaseName: ingress
      parameters:
        - name: clusterName
          value: "${cluster_name}"
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
