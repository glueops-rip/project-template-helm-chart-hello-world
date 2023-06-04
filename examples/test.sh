#!/bin/bash
set -o errexit
set -o pipefail

if [[ ${DEBUG} -eq "1" ]]; then
  set -o xtrace
fi

IGNORE_TESTS_KUBE_SCORE=(--ignore-test=container-image-pull-policy --ignore-test=container-security-context-readonlyrootfilesystem --ignore-test=container-security-context-user-group-id --ignore-test=pod-networkpolicy --ignore-test=ingress-targets-service --ignore-test=container-ephemeral-storage-request-and-limit)

export KUBE_VER=1.27
export KUBE_VER_FULL=`echo $KUBE_VER`.2
for d in */ ; do
  if [[ $d == "testcases/" ]]; then
    echo "[INFO] Skipping $d ..."
    continue
  fi
  echo "$d"
  cd "$d"
  echo "[INFO] helm template on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml
  echo "[INFO] yamllint on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | yamllint -c ../.yamllint.yaml -
  echo "[INFO] kubeconform on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | kubeconform -summary -skip=ExternalSecret,TriggerAuthentication,ScaledObject -
  echo "[INFO] kube-linter on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | kube-linter lint --config ../.kube-linter.yaml -
  echo "[INFO] kube-score on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | kube-score score --output-format ci --kubernetes-version v$KUBE_VER "${IGNORE_TESTS_KUBE_SCORE[@]}" -
  echo "[INFO] polaris on directory: $(pwd)"
  polaris audit --set-exit-code-on-danger --only-show-failed-tests -f pretty --config ../.polaris.yaml --helm-chart ../../ --helm-values values.yaml
  echo "[INFO] kubeval on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml | kubeval --kubernetes-version $KUBE_VER_FULL --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master --skip-kinds=ExternalSecret --skip-kinds=TriggerAuthentication --skip-kinds=ScaledObject
  echo "[INFO] kubectl dry-run on directory: $(pwd)"
  helm template ../../ -f ../../values.yaml -f values.yaml |  kubectl apply --dry-run='client' -f - 
  
  if [[ $d == "keda/" ]] && [[ $CI == "true" ]]; then
    helm install example-app ../../ -f ../../values.yaml -f deployment.yaml --wait
    kubectl wait deployment -n default example-app --for condition=Available=True --timeout=60s
    echo "[INFO] kubectl dry-run on directory: $(pwd)" 
    helm template example-app ../../ -f ../../values.yaml -f values.yaml --replace  |  kubectl apply --dry-run='server' -f - 
    helm delete example-app
  elif [[ $d != "keda/" ]]; then
    echo "[INFO] kubectl dry-run on directory: $(pwd)" 
    helm template ../../ -f ../../values.yaml -f values.yaml |  kubectl apply --dry-run='server' -f - 
  fi
  cd ..
done

if [[ -d "testcases/" ]]; then
  echo "[INFO] Run testcases ..."
  for yamlfile in testcases/*.yaml; do
    echo $yamlfile
    yaml=`basename $yamlfile`
    cd testcases
    echo "[INFO] helm template on file: $yaml"
    helm template ../../ -f ../../values.yaml -f $yaml
    echo "[INFO] yamllint on file: $yaml"
    helm template ../../ -f ../../values.yaml -f $yaml | yamllint -c ../.yamllint.yaml -
    echo "[INFO] kube-linter on file: $yaml"
    helm template ../../ -f ../../values.yaml -f $yaml | kube-linter lint --config ../.kube-linter.yaml -
    echo "[INFO] kube-score on file: $yaml"
    helm template ../../ -f ../../values.yaml -f $yaml | kube-score score --output-format ci --kubernetes-version v$KUBE_VER "${IGNORE_TESTS_KUBE_SCORE[@]}" -
    echo "[INFO] polaris on file: $yaml"
    polaris audit --set-exit-code-on-danger --only-show-failed-tests -f pretty --config ../.polaris.yaml --helm-chart ../../ --helm-values $yaml
    echo "[INFO] kubeval on file: $yaml"
    helm template ../../ -f ../../values.yaml -f $yaml | kubeval --kubernetes-version $KUBE_VER_FULL --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master --skip-kinds=ExternalSecret
    echo "[INFO] kubectl dry-run on file: $yaml"
    helm template ../../ -f ../../values.yaml -f $yaml |  kubectl apply --dry-run='client' -f - 
    helm template ../../ -f ../../values.yaml -f $yaml |  kubectl apply --dry-run='server' -f - 
    cd ..
  done
else
  echo "[INFO] Skipping testcases ..."
fi