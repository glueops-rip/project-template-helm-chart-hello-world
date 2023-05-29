{{- define "chart.podTemplate" }}
metadata:
  labels:
    {{- include "chart.commonLabels" .Root | indent 4 }}
    {{- if eq .resourceType "deployment" }}
    {{- include "chart.deploymentLabels" .Root | indent 4 }}
    {{- if .matchLabels }}
    {{- toYaml .matchLabels | nindent 4 }}
    {{- end }}
    {{- else if eq .resourceType "cronJob" }}
    resource-type: "cronjob"
    cronjob: {{ include "app.name" .Root }}-{{.name}}
    {{- if .Root.Values.cronJob.labels }}
    {{- range $key, $value := .Root.Values.cronJob.labels }}
    {{$key}}: {{$value | quote}}
    {{- end }}
    {{- end }}
    {{- else if eq .resourceType "job" }}
    resource-type: "job"
    {{- if .suffixName }}
    job: {{ include "app.name" .Root }}-{{.suffixName}}
    {{- else}}
    job: {{ include "app.name" .Root }}-{{.name}}-{{ now | date "200601021504" }}
    {{- end }}
    {{- if .Root.Values.job.labels }}
    {{- range $key, $value := .Root.Values.job.labels }}
    {{$key}}: {{$value | quote}}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- range $key, $value := .labels }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
  annotations:
    {{- include "chart.commonAnnotations" .Root | indent 4 }}
    {{- if eq .resourceType "deployment" }}
    {{- include "chart.deploymentAnnotations" .Root | indent 4 }}
    {{- else if eq .resourceType "cronJob" }}
    {{- if .Root.Values.cronJob.annotations }}
    {{- range $key, $value := .Root.Values.cronJob.annotations }}
    {{$key}}: {{$value | quote}}
    {{- end }}
    {{- end }}
    {{- else if eq .resourceType "job" }}
    {{- if .Root.Values.job.labels }}
    {{- range $key, $value := .Root.Values.job.labels }}
    {{$key}}: {{$value | quote}}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- range $key, $value := .annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
spec:
  terminationGracePeriodSeconds: {{ .terminationPeriod | default "60" }}
  hostNetwork: {{ .hostNetwork | default false }} 
  {{- if .hostAliases }}
  hostAliases:      
  {{- toYaml .hostAliases | nindent 4 }}
  {{- end }}
  {{- if .serviceAccount.enabled }}
  {{- if eq .resourceType "deployment" }}
  serviceAccountName: {{ include "chart.serviceAccountName" .Root }}
  {{- else if or (eq .resourceType "cronJob") (eq .resourceType "job") }}
  serviceAccountName: {{ .serviceAccount.name | default .Root.Values.serviceAccount.name | default (include "app.name" .Root) }}
  {{- end }}
  {{- end }}
  {{- if .nodeSelector }}
  nodeSelector:
  {{- toYaml .nodeSelector | nindent 4 }}
  {{- end }}
  {{- if .tolerations }}
  tolerations:
  {{- toYaml .tolerations | nindent 4 }}
  {{- end }}
  {{- if .affinity }}
  affinity:
  {{- tpl (toYaml .affinity) .Root | nindent 4 }}
  {{- end }}
  {{- if .topologySpreadConstraints }}
  topologySpreadConstraints:
  {{- tpl (toYaml .topologySpreadConstraints) .Root | nindent 4 }}
  {{- else }}
  topologySpreadConstraints:
    - labelSelector:
        matchLabels:
          {{- include "chart.appLabels" .Root | indent 10 }}
          {{- if .matchLabels }}
          {{- toYaml .matchLabels | nindent 10 }}
          {{- end }}
      maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
      whenUnsatisfiable: ScheduleAnyway
  {{- end }}
  {{- if .imagePullSecrets }}
  imagePullSecrets:
  - name: {{ .imagePullSecrets }}
  {{- end }}
  {{- if .securityContext }}
  securityContext:
  {{- toYaml .securityContext | nindent 4 }}
  {{- end }}

  {{- if .dnsPolicy }}
  dnsPolicy: {{ .dnsPolicy }}
  {{- end }}
  {{- if .dnsConfig }}
  dnsConfig:      
  {{- toYaml .dnsConfig | nindent 4 }}
  {{- end }}
  {{- if .shareProcessNamespace }}
  shareProcessNamespace: {{ .shareProcessNamespace | default true }}
  {{- end }}
  {{- if .priorityClassName }}
  priorityClassName: {{ .priorityClassName }}
  {{- end }}
  {{- if eq .resourceType "deployment" }}
  restartPolicy: {{ .restartPolicy | default "Always" }}
  {{- else if eq .resourceType "cronJob" }}
  restartPolicy: {{ .restartPolicy | default "OnFailure" }}
  {{- else if eq .resourceType "job" }}
  restartPolicy: {{ .restartPolicy | default "Never" }}
  {{- end }}
  # volumes
  volumes:
  {{- if eq .Root.Values.PersistentVolumeClaim.mountPVC true }}
  - name: {{ template "app.name" .Root }}-pvc
    persistentVolumeClaim:
      {{- if .Root.Values.PersistentVolumeClaim.name }}
      claimName: {{ .Root.Values.PersistentVolumeClaim.name }}
      {{- else }}
      claimName: {{ template "app.name" .Root }}-pvc
      {{- end }}
  {{- end }}
  {{- if .volumes }}
  # volumes variables
  {{- with .volumes }}
  {{- tpl (toYaml .) $.Root | nindent 2 }}
  {{- end }}
  {{- end }}
  {{- with .initContainers }}
  initContainers:
  {{- toYaml . | nindent 2 }}
  {{- end }}
  containers:
  - name: {{ template "app.name" .Root }}
    imagePullPolicy: {{ .imagePullPolicy | default "IfNotPresent" }}
    {{- if .image }}
    image: {{.image}}
    {{- else }}
    image: {{ printf "%s/%s:%s" .Root.Values.image.registry .Root.Values.image.repository (.Root.Values.image.tag | default .Root.Values.appVersion | default .Chart.Version) }}
    {{- end }}
    {{- if .Root.Values.image.command }}
    command:
    {{- range .Root.Values.image.command }}
    - {{.}}
    {{- end }}
    {{- else if .command }}
    command:
    {{- range .command }}
    - {{.}}
    {{- end }}
    {{- end }}
    {{- if .Root.Values.image.args }}
    args:
    {{- range .Root.Values.image.args }}
    - {{.}}
    {{- end }}
    {{- else if .args }}
    args:
    {{- range .args }}
    - {{.}}
    {{- end }}
    {{- end }}
    {{- if .Root.Values.image.lifecycle }}
    lifecycle:
    {{- toYaml .Root.Values.image.lifecycle | nindent 6 }}
    {{- else if .lifecycle }}
    lifecycle:
    {{- toYaml .lifecycle | nindent 6 }}
    {{- end }}
    ports:
    - name: {{.portName | default "http" }}
      containerPort: {{ template "app.port" .Root }}
      {{- if .Root.Values.image.protocol }}
      protocol: {{.Root.Values.image.protocol}}
      {{- else if .protocol }}
      protocol: {{.protocol}}
      {{- else }}
      protocol: "TCP"
      {{- end }}
    {{- range .containerPorts }}
    - name: {{ .name }}
      containerPort: {{ int .port }}
      protocol: {{ .protocol | default "TCP" }}
    {{- end }}
    env:
    # default variables
    - name: ENV_APP_NAME
      value: {{ template "app.name" .Root }}
    - name: ENV_APP_VERSION
      value: {{ include "app.version" .Root | quote }}
    - name: ENV_APP_ENV
      value: "{{.Root.Values.appEnv}}"
    - name: ENV_APP_PORT
      value: {{ include "app.port" .Root | quote }}
    - name: ENV_NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: ENV_POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: ENV_POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: ENV_POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    # envVariables
    {{- range .envVariables }}
    - name: {{ .name }}
      value: {{ .value | quote }}
    {{- end }}
    # secret variables
    {{- range .envSecrets }}
    - name: {{.variable}}
      valueFrom:
        secretKeyRef:
          name: {{.secretName}}
          key: {{.secretKey}}
    {{- end }}
    # configMap variables
    {{- range .envConfigMaps }}
    - name: {{.variable}}
      valueFrom:
        configMapKeyRef:
          name: {{.configMapName}}
          key: {{.configMapKey}}
    {{- end }}
    # envMap
    {{- range $envKey, $envValue := .envMap }}
    - name: {{ $envKey }}
      {{- toYaml $envValue | nindent 6 }}
    {{- end }}
    # resources
    {{- if .resources }}
    resources: {{ toYaml .resources | nindent 6 }}
    {{- end }}
    # startupProbe
    {{- if .startupProbe }}
    startupProbe:
      {{- toYaml .startupProbe | nindent 6 }}
    {{- end }}
    # livenessProbe
    {{- if .livenessProbe }}
    livenessProbe:
      {{- toYaml .livenessProbe | nindent 6 }}
    {{- end }}

    # readinessProbe
    {{- if .readinessProbe }}
    readinessProbe:
      {{- toYaml .readinessProbe | nindent 6 }}
    {{- end }}
    # volumeMounts
    {{- if or (.volumeMounts) (and (eq .Root.Values.PersistentVolumeClaim.enabled true) (eq .Root.Values.PersistentVolumeClaim.mountPVC true) )}} 
    volumeMounts:
    {{- if eq .Root.Values.PersistentVolumeClaim.mountPVC true }}
    - mountPath: {{ .Root.Values.PersistentVolumeClaim.mountPath }}
      name: {{ template "app.name" .Root }}-pvc
    {{- end }}
    {{- with .volumeMounts }}
    {{- tpl (toYaml .) $.Root | nindent 4 }}
    {{- end }}
    {{- end }}

  # sidecar
  {{- if .sidecar }}
  {{- toYaml .sidecar | nindent 2 }}
  {{- end }}

{{ end -}}


