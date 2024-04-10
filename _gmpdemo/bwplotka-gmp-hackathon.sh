#!/usr/bin/env bash

# Example on how to use it https://github.com/bwplotka/demo-nav/blob/master/example/demo-example.sh

NUMS=false
#IMMEDIATE_REVEAL=true

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. "${DIR}/demo-nav.sh"

# Yolo aliases
function cat() {
    bat -p "$@"
}

function k8sgpt() {
    ${DIR}/../bin/k8sgpt "$@"
}


clear

export CLUSTER_NAME="bwplotka-stdtest"

printf "Let's imagine our customers creates a new namespace called 'demo' in their GKE cluster with GMP Collection enabled.\n\nThey've created a 'demo' namespace and plan to deploy & monitor a new deployment:\n\n"

r "kubectl apply -n demo -f manifests/my-application.yaml" "kubectl apply -n demo -f manifests/broken-pod.yaml"
r "cat manifests/my-application.yaml" "cat manifests/broken-pod.yaml"
r "kubectl get -n demo po"

r "kubectl apply -n demo -f manifests/my-application-pod-monitoring1.yaml" "kubectl apply -n demo -f manifests/pm-wrong-selector.yaml"
r "cat manifests/my-application-pod-monitoring1.yaml" "cat manifests/pm-wrong-selector.yaml"
r "Checking GCM for heap memory metric for 'my-application' pods... Nothing there!" "open 'https://pantheon.corp.google.com/monitoring/metrics-explorer;duration=PT5M?project=gpe-test-1&pageState=%7B%22xyChart%22:%7B%22constantLines%22:%5B%5D,%22dataSets%22:%5B%7B%22plotType%22:%22LINE%22,%22prometheusQuery%22:%22go_memstats_alloc_bytes%7Bcluster%3D%5C%22${CLUSTER_NAME}%5C%22,%20pod%3D~%5C%22my-application.*%5C%22%7D%22,%22targetAxis%22:%22Y1%22,%22unitOverride%22:%22%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22y1Axis%22:%7B%22label%22:%22%22,%22scale%22:%22LINEAR%22%7D%7D%7D'"

r "Let's analyze GMP PodMonitoring using K8sGPT tool! 🚀" "open 'https://k8sgpt.ai/'"

r "k8sgpt analyze -v -n demo -f PodMonitoring"

r "k8sgpt auth list"
r "Officially contributed Google provider last week!" "open 'https://github.com/k8sgpt-ai/k8sgpt/pull/829'"
r "k8sgpt auth add --backend google --model gemini-pro --password '\$(cat api.key)' && k8sgpt auth default -p google" "k8sgpt auth add --backend google --model gemini-pro --password '$(cat api.key)' && k8sgpt auth default -p google"
r "k8sgpt auth list"

r "k8sgpt analyze -c -n demo -f PodMonitoring --explain # With broken selector"

r "kubectl apply -n demo -f manifests/my-application-pod-monitoring2.yaml" "kubectl apply -n demo -f manifests/pm-wrong-port.yaml"
r "cat manifests/my-application-pod-monitoring2.yaml" "cat manifests/pm-wrong-port.yaml"

r "k8sgpt analyze -c -n demo -f PodMonitoring --explain # With not running pod"

r "kubectl apply -n demo -f manifests/my-application-fixed.yaml" "kubectl apply -n demo -f manifests/working-pod.yaml"
r "cat manifests/my-application-fixed.yaml" "cat manifests/working-pod.yaml"
r "kubectl get -n demo po"

r "cat manifests/my-application-pod-monitoring2.yaml" "cat manifests/pm-wrong-port.yaml"
r "k8sgpt analyze -c -n demo -f PodMonitoring --explain # With broken port"

r "kubectl apply -n demo -f manifests/my-application-pod-monitoring-fixed.yaml" "kubectl apply -n demo -f manifests/pm-correct.yaml"
r "cat manifests/my-application-pod-monitoring-fixed.yaml" "cat manifests/pm-correct.yaml"

r "k8sgpt analyze -c -n demo -f PodMonitoring --explain # Should be fine?"
r "We should have now our heap memory metric for 'my-application' pod in GCM! 💪🏽" "open 'https://pantheon.corp.google.com/monitoring/metrics-explorer;duration=PT5M?project=gpe-test-1&pageState=%7B%22xyChart%22:%7B%22constantLines%22:%5B%5D,%22dataSets%22:%5B%7B%22plotType%22:%22LINE%22,%22prometheusQuery%22:%22go_memstats_alloc_bytes%7Bcluster%3D%5C%22${CLUSTER_NAME}%5C%22,%20pod%3D~%5C%22my-application.*%5C%22%7D%22,%22targetAxis%22:%22Y1%22,%22unitOverride%22:%22%22%7D%5D,%22options%22:%7B%22mode%22:%22COLOR%22%7D,%22y1Axis%22:%7B%22label%22:%22%22,%22scale%22:%22LINEAR%22%7D%7D%7D'"

r "Next steps: Discuss with K8sGPT how to integrate that and give to OSS users; Perhaps add as a GMP extension, our own CLI or UI feature?" "open 'https://github.com/k8sgpt-ai/k8sgpt/pull/857'"
r "That's it, thanks!" "echo '🤙🏽'"

navigate true
