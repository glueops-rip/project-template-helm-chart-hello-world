{{- define "chart.podTemplate" -}}
metadata:
  labels:
    {{- include "chart.commonLabels" .Root | indent 4 }}
    {{- include "chart.deploymentLabels" .Root | indent 4 }}
    {{- if .matchLabels }}
    {{- toYaml .matchLabels | nindent 4 }}
    {{- end }}
    {{- if eq .resourceType "cronJob" }}
    resource-type: "cronjob"
    cronjob: {{ include "app.name" .Root }}-{{.name}}
    {{- else if eq .resourceType "job" }}
    resource-type: "job"
    {{- if .suffixName }}
    job: {{ include "app.name" .Root }}-{{.suffixName}}
    {{- else}}
    job: {{ include "app.name" .Root }}-{{.name}}
    {{- end }}
    {{- end }}
    {{- if .labels }}
    {{- range $key, $value := .labels }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
    {{- end }}
  annotations:
    {{- include "chart.commonAnnotations" .Root | indent 4 }}
    {{- include "chart.deploymentAnnotations" .Root | indent 4 }}
    {{- if .annotations }}
    {{- range $key, $value := .annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
    {{- end }}
spec:
  terminationGracePeriodSeconds: {{ .terminationGracePeriodSeconds | default "60" }}
  {{- if .hostNetwork }}
  hostNetwork: {{ .hostNetwork | default false }} 
  {{- end }}
  {{- if .hostAliases }}
  hostAliases:      
  {{- toYaml .hostAliases | nindent 4 }}
  {{- end }}
  {{- if and (hasKey . "serviceAccount") .serviceAccount.enabled }}
  {{- if or (eq .resourceType "deployment") (eq .resourceType "statefulSet") }}
  serviceAccountName: {{ include "chart.serviceAccountName" .Root }}
  {{- else if hasKey .serviceAccount "name" }}
  serviceAccountName: {{ .serviceAccount.name | default .Root.Values.serviceAccount.name | default (include "app.name" .Root) }}
  {{- else }}
  serviceAccountName: {{ include "app.name" .Root }}
  {{- end }}
  {{- end }}
  {{- if and (hasKey . "serviceAccount") (hasKey .serviceAccount "automountServiceAccountToken") }}
  automountServiceAccountToken: {{ .serviceAccount.automountServiceAccountToken }}
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
      maxSkew: {{ .topologySpreadConstraintsMaxSkew | default 1 }}
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
  {{- if or (eq .resourceType "deployment") (eq .resourceType "statefulSet") }}
  {{- if .restartPolicy }}
  restartPolicy: {{ .restartPolicy | default "Always" }}
  {{- end }}
  {{- else if eq .resourceType "cronJob" }}
  restartPolicy: {{ .restartPolicy | default "OnFailure" }}
  {{- else if eq .resourceType "job" }}
  restartPolicy: {{ .restartPolicy | default "Never" }}
  {{- end }}
  # volumes
  volumes:
  {{- if and (ne .resourceType "statefulSet") .Root.Values.PersistentVolumeClaim.enabled }}
  - name: {{ include "app.name" .Root }}-pvc
    persistentVolumeClaim:
      {{- if .Root.Values.PersistentVolumeClaim.name }}
      claimName: {{ .Root.Values.PersistentVolumeClaim.name }}
      {{- else }}
      claimName: {{ include "app.name" .Root }}-pvc
      {{- end }}
  {{- end }}
  {{- if .volumes }}
  {{- with .volumes }}
  {{- tpl (toYaml .) $.Root | nindent 2 }}
  {{- end }}
  {{- end }}
  {{- if .initContainers }}
  {{- with .initContainers }}
  initContainers:
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- end }}
  containers:
  - name: {{ include "app.name" .Root }}
    imagePullPolicy: {{ title (.imagePullPolicy | default "IfNotPresent") }}
    {{- if .image }}
    image: {{.image}}
    {{- else }}
    image: {{ printf "%s/%s:%s" .Root.Values.image.registry .Root.Values.image.repository (toString (.Root.Values.image.tag | default .Root.Values.appVersion | default .Chart.Version)) }}
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
      containerPort: {{ include "app.port" .Root }}
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
      value: {{ include "app.name" .Root }}
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
    {{- if .envVariables }}
    # envVariables
    {{- range .envVariables }}
    - name: {{ .name }}
      value: {{ .value | quote }}
    {{- end }}
    {{- end }}
    {{- if .envSecrets }}
    # secret variables
    {{- range .envSecrets }}
    - name: {{.variable}}
      valueFrom:
        secretKeyRef:
          name: {{.secretName}}
          key: {{.secretKey}}
    {{- end }}
    {{- end }}
    {{- if .Root.Values.externalSecret.enabled  }}
    {{- range $nameSuffix, $data := .Root.Values.externalSecret.secrets }}
    {{- if hasKey $data "data" }}
    # externalSecret
    {{- range $secretKey, $secretProperty := $data.data}}
    - name: {{ $secretProperty.envName | default $secretKey }}
      valueFrom:
        secretKeyRef:
          name: {{ $data.name | default (printf "%s-%s" (include "app.name" $.Root) $nameSuffix) }}
          key: {{ $secretKey }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if .envConfigMaps }}
    # configMap variables
    {{- range .envConfigMaps }}
    - name: {{.variable}}
      valueFrom:
        configMapKeyRef:
          name: {{.configMapName}}
          key: {{.configMapKey}}
    {{- end }}
    {{- end }}
    {{- if .envMap }}
    # envMap
    {{- range $envKey, $envValue := .envMap }}
    - name: {{ $envKey }}
      {{- toYaml $envValue | nindent 6 }}
    {{- end }}
    {{- end }}
    {{- if or .envFrom .Root.Values.externalSecret.enabled  }}
    # envFrom
    envFrom:
    {{- range $nameSuffix, $data := .Root.Values.externalSecret.secrets }}
    {{- if and (hasKey $data "dataFrom") (hasKey $data.dataFrom "key") }}
    # externalSecret
    - secretRef:
        name: {{ $data.name | default (printf "%s-%s" (include "app.name" $.Root) $nameSuffix) }}
    {{- end }}
    {{- end }}
    {{- range .envFrom }}
    - {{ .type }}:
        name: {{ .name }}
    {{- end }}
    {{- end }}
    {{- if .resources }}
    # resources
    resources: {{ toYaml .resources | nindent 6 }}
    {{- end }}
    {{- if .startupProbe }}
    # startupProbe
    startupProbe:
      {{- toYaml .startupProbe | nindent 6 }}
    {{- end }}
    {{- if .livenessProbe }}
    # livenessProbe
    livenessProbe:
      {{- toYaml .livenessProbe | nindent 6 }}
    {{- end }}
    {{- if .readinessProbe }}
    # readinessProbe
    readinessProbe:
      {{- toYaml .readinessProbe | nindent 6 }}
    {{- end }}
    {{- if .containerSecurityContext }}
    # securityContext
    securityContext:
    {{- toYaml .containerSecurityContext | nindent 6 }}
    {{- end }}
    # volumeMounts
    volumeMounts:
    {{- if eq .resourceType "statefulSet" }}
    {{- if .volumeClaimTemplates }}
    {{- range $key, $value := .volumeClaimTemplates }}
    - name: {{$key}}
      mountPath: {{$value.mountPath}}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if .Root.Values.PersistentVolumeClaim.enabled }}
    - name: {{ include "app.name" .Root }}-pvc
      mountPath: {{ .Root.Values.PersistentVolumeClaim.mountPath }}
    {{- end }}
    {{- if .volumeMounts }}
    {{- with .volumeMounts }}
    {{- tpl (toYaml .) $.Root | nindent 4 }}
    {{- end }}
    {{- end }}
  {{- if .sidecar }}
  # sidecar
  {{- toYaml .sidecar | nindent 2 }}
  {{- end }}
{{ end -}}
