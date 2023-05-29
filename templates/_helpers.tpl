
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.name" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Define the name of the chart/application.
*/}}
{{- define "app.name" -}}
{{- .Values.appName | default .Chart.Name  | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define the version of the chart/application.
*/}}
{{- define "app.version" -}}
{{- .Values.appVersion | default .Chart.Version -}}
{{- end -}}

{{/*
Define the port of the chart/application.
*/}}
{{- define "app.port" -}}
{{- .Values.appPort | default .Values.image.port | default .Values.deployment.port | default 8080 -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "app.namespace" -}}
{{- .Values.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{/*Create the name of the service account to use*/}}
{{- define "chart.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
{{ .Values.serviceAccount.name }}
{{- else if .Values.deployment.serviceAccount.name }}
{{ .Values.deployment.serviceAccount.name }}
{{- else -}}
{{ include "app.name" . }}
{{- end -}}
{{- end -}}

{{/* Shared labels used for selector */}}
{{- define "chart.appLabels" }}
{{- if .suffixName }}
app.kubernetes.io/name: {{ include "app.name" . }}-{{.suffixName}}
{{- else}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end }}
app.kubernetes.io/version: {{ include "app.version" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Common labels for the whole chart */}}
{{- define "chart.commonLabels" -}}
{{ include "chart.appLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "chart.name" . }}
{{- if .Values.commonLabels }}
{{- range $key, $value := .commonLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* Common annotations for the whole chart */}}
{{- define "chart.commonAnnotations" }}
{{- if .Values.commonAnnotations }}
{{- range $key, $value := .Values.commonAnnotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* Deployment labels */}}
{{- define "chart.deploymentLabels" -}}
{{- if .Values.deployment.labels }}
{{- range $key, $value := .Values.deployment.labels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* Deployment annotations */}}
{{- define "chart.deploymentAnnotations" -}}
{{- if .Values.deployment.annotations }}
{{- range $key, $value := .Values.deployment.annotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}
