# hello-world

![Version: 0.4.0-antonio-alpha18](https://img.shields.io/badge/Version-0.4.0--antonio--alpha18-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.2.2](https://img.shields.io/badge/AppVersion-v0.2.2-informational?style=flat-square)

A Helm chart for Kubernetes web apps

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| captain_domain | string | `"<cluster-environment-name>.<companykey>.glueopshosted.com"` |  |
| containerName | string | `"app"` |  |
| containerPort | int | `3000` |  |
| cpuLimitInM | string | `nil` |  |
| cpuRequestInM | string | `nil` |  |
| domain | string | `"nil"` |  |
| image.name | string | `"glueops/tacos_app_react_js"` |  |
| image.tag | string | `"v0.2.2"` |  |
| memoryLimitInMi | string | `nil` |  |
| memoryRequestInMi | string | `nil` |  |
| prometheus-alertmanagerconfig-opsgenie.labels | object | `{"alertname":"nil","component":"nil","team":"nil"}` | These labels are additional filters you can use to keep these notifications for one particular team, component, or alert. Note: you must set the same filters (with the exception of alertname) on the alert definition itself. The alert definition is also refered to as the prometheusrule. |
| prometheus-alertmanagerconfig-opsgenie.opsgenie.apikey | string | `"nil"` | Leave this value as `nil` if you provided a `vault_path`. Otherwise, this value must be set. You CANNOT have a `vault_path` and `opsgenie.apikey` defined at the same time. |
| prometheus-alertmanagerconfig-opsgenie.route | object | `{"groupInterval":"5m","repeatInterval":"5m"}` | Amount of time to fire an alert again after the first one is sent. |
| replicaCount | int | `1` |  |
| vault_path | string | `"nil"` |  |
| vault_path_overrides | string | `"nil"` |  |
| vault_path_registry_credentials | string | `"nil"` |  |
