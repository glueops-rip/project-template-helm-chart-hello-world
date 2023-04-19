# hello-world

![Version: 0.3.1](https://img.shields.io/badge/Version-0.3.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.2.2](https://img.shields.io/badge/AppVersion-v0.2.2-informational?style=flat-square)

A Helm chart for Kubernetes web apps

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| captain_domain | string | `"<cluster-environment-name>.<companykey>.glueopshosted.com"` |  |
| containerPort | int | `3000` |  |
| domain | string | `"nil"` |  |
| image.name | string | `"glueops/tacos_app_react_js"` |  |
| image.tag | string | `"v0.2.2"` |  |
| replicaCount | int | `1` |  |
| vault_path | string | `"nil"` |  |
| vault_path_overrides | string | `"nil"` |  |
| vault_path_registry_credentials | string | `"nil"` |  |
