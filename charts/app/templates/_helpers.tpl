{{/*
Application name
*/}}
{{- define "app.name" -}}
{{- default .Release.Name .Values.name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Common labels
*/}}
{{- define "app.labels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Project namespace
*/}}
{{- define "project.namespace" -}}
{{- default .Release.Namespace .Values.namespace }}
{{- end }}


{{/*
Addon name
*/}}
{{- define "addon.name" -}}
{{- required "addon.name is required" .name | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Addon service name
*/}}
{{- define "addon.serviceName" -}}
{{- default (include "addon.name" .) .serviceName | trunc 63 | trimSuffix "-" }}
{{- end }}


{{/*
Addon labels
*/}}
{{- define "addon.labels" -}}
app.kubernetes.io/name: {{ include "addon.name" . }}
app.kubernetes.io/instance: {{ include "addon.name" . }}
{{- end }}


{{/*
Addon selector labels
*/}}
{{- define "addon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "addon.name" . }}
app.kubernetes.io/instance: {{ include "addon.name" . }}
{{- end }}


{{/*
Addon storage size
*/}}
{{- define "addon.storageSize" -}}
{{- if kindIs "map" .storage -}}
{{- required "addon.storage.size is required" .storage.size -}}
{{- else -}}
{{- default "10Gi" .storage -}}
{{- end -}}
{{- end }}
