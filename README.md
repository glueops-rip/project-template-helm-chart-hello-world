# hello-world

![Version: 0.4.0](https://img.shields.io/badge/Version-0.4.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.2.2](https://img.shields.io/badge/AppVersion-v0.2.2-informational?style=flat-square)

A Helm chart for Kubernetes web apps

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| alerts.labels | object | `{"alertname":"nil","component":"nil","team":"nil"}` | These labels are additional filters you can use to keep these notifications for one particular team, component, or alert. Note: you must set the same filters (with the exception of alertname) on the alert definition itself. The alert definition is also refered to as the prometheusrule. |
| captain_domain | string | `"<cluster-environment-name>.<companykey>.glueopshosted.com"` |  |
| containerPort | int | `3000` |  |
| cpuLimit | string | `nil` |  |
| cpuRequest | int | `300` |  |
| domain | string | `"nil"` |  |
| image.name | string | `"glueops/tacos_app_react_js"` |  |
| image.tag | string | `"v0.2.2"` |  |
| memoryLimit | string | `nil` |  |
| memoryRequest | int | `32` |  |
| replicaCount | int | `1` |  |
| vault_path | string | `"nil"` |  |
| vault_path_overrides | string | `"nil"` |  |
| vault_path_registry_credentials | string | `"nil"` |  |
