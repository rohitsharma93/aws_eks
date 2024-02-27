apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: loki
  namespace: argo
spec:
  project: helm
  source:
    repoURL:  https://grafana.github.io/helm-charts
    targetRevision: 2.9.11
    chart: loki-stack
    helm:
      releaseName: loki
      parameters:
        - name: loki.config.compactor.retention_delete_delay
          value: 2h
        - name: loki.config.compactor.retention_enabled
          value: "true"
        - name: loki.config.compactor.shared_store
          value: s3
        - name: loki.config.compactor.working_directory
          value: /data/compactor
        - name: loki.config.storage_config.aws.region
          value: ${aws_region}
        - name: loki.config.storage_config.aws.bucketnames
          value: ${loki_bucket}
        - name : loki.config.table_manager.retention_deletes_enabled
          value: "true"
        - name : loki.config.table_manager.retention_period
          value: 90d
        - name: loki.config.storage_config.aws.s3forcepathstyle
          value: "false"
        - name: loki.config.storage_config.boltdb_shipper.shared_store
          value: s3
      values: |
        loki:
          config:  
            schema_config:
              configs:
              - from: 2020-05-15
                store: boltdb-shipper
                object_store: s3
                schema: v11
                index:
                  period: 24h
                  prefix: loki_index_
  destination:
    server: https://kubernetes.default.svc
    namespace: loki
  syncPolicy:
    syncOptions:
    - CreateNamespace=true 
