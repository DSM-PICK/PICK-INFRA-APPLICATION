{{- define "app.alloy.config" -}}
logging {
  level  = "info"
  format = "logfmt"
}

discovery.kubernetes "pods" {
  role = "pod"
}

discovery.relabel "pods" {
  targets = discovery.kubernetes.pods.targets

  rule {
    source_labels = ["__meta_kubernetes_namespace"]
    target_label  = "namespace"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_name"]
    target_label  = "pod"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_container_name"]
    target_label  = "container"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_node_name"]
    target_label  = "node"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app"]
    target_label  = "app"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    target_label  = "app_kubernetes_io_name"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_component"]
    target_label  = "app_kubernetes_io_component"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app", "__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    regex         = "(.+);.*|;(.+)"
    target_label  = "service"
    replacement   = "$1$2"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app"]
    regex         = "pick-core.*"
    target_label  = "tier"
    replacement   = "backend"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app"]
    regex         = "pick-(admin|teacher).*"
    target_label  = "tier"
    replacement   = "frontend"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    regex         = ".*kafka.*"
    target_label  = "tier"
    replacement   = "kafka"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    regex         = ".*redis.*"
    target_label  = "tier"
    replacement   = "redis"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    regex         = ".*mysql.*"
    target_label  = "tier"
    replacement   = "db"
  }

  rule {
    source_labels = ["__meta_kubernetes_pod_label_app_kubernetes_io_name"]
    regex         = ".*debezium.*"
    target_label  = "tier"
    replacement   = "cdc"
  }
}

loki.source.kubernetes "pods" {
  targets    = discovery.relabel.pods.output
  forward_to = [loki.write.default.receiver]
}

loki.write "default" {
  endpoint {
    url = {{ .lokiURL | quote }}
  }
}
{{- end -}}
