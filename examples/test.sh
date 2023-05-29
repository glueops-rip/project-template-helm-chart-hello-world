#!/bin/bash
set -o errexit
set -o pipefail

if [[ ${DEBUG} -eq "1" ]]; then
  set -o xtrace
fi

IGNORE_TESTS_KUBE_SCORE=(--ignore-test=container-image-pull-policy --ignore-test=container-security-context-readonlyrootfilesystem --ignore-test=container-security-context-user-group-id --ignore-test=pod-networkpolicy --ignore-test=ingress-targets-service --ignore-test=container-ephemeral-storage-request-and-limit)

export KUBE_VER=1.26
export KUBE_VER_FULL=`echo $KUBE_VER`.3
for d in */ ; do
  echo "$d"
  cd "$d"
  echo "[INFO] helm template on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml
  echo "[INFO] yamllint on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | yamllint -c ../.yamllint.yaml -
  echo "[INFO] kube-linter on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | kube-linter lint --config ../.kube-linter.yaml -
  echo "[INFO] kube-score on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | kube-score score --kubernetes-version v$KUBE_VER "${IGNORE_TESTS_KUBE_SCORE[@]}" -
  echo "[INFO] polaris on directory: $(pwd)"
  polaris audit --set-exit-code-on-danger --only-show-failed-tests -f pretty --config ../.polaris.yaml --helm-chart ../../ --helm-values values.yaml

  if [[ $d == "keda/" ]] || [[ $d == "externalsecret/" ]]; then
    echo "[INFO] Skipping $d ..."
  else
    echo "[INFO] kubectl dry-run on directory: $(pwd)"
    helm template ../../ -f ../../values.yaml -f values.yaml |  kubectl apply --dry-run='client' -f - 
    helm template ../../ -f ../../values.yaml -f values.yaml |  kubectl apply --dry-run='server' -f - 

    echo "[INFO] kubectl dry-run on directory: $(pwd)"
    helm template ../../ -f ../../values.yaml -f values.yaml |  kubectl apply --dry-run='client' -f - 
    helm template ../../ -f ../../values.yaml -f values.yaml |  kubectl apply --dry-run='server' -f - 
    echo "[INFO] kubeval on directory: $(pwd)"
    helm template ../../ -f ../../values.yaml -f values.yaml | kubeval --kubernetes-version $KUBE_VER_FULL --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master
  fi
  cd ..
done
