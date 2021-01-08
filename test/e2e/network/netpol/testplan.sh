#!/bin/sh
# https://github.com/kubernetes/kubernetes/pull/97571
set -euvx -o pipefail

CONF="calico-conf.yaml"
CALICO="calico.yaml"

test -f "$CALICO" || { echo no $CALICO ; exit 1 ; }
test -f "$CONF" && mv "$CONF" "${CONF}.old"

cat <<EOF > "$CONF"
# auto-generated `date`
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true # disable kindnet
  podSubnet: 192.168.0.0/16 # set to Calico's default subnet
nodes:
- role: control-plane
- role: worker
EOF

kind create cluster --name calico-test --config "$CONF"
until kubectl cluster-info ; do
	echo `date` waiting...
	sleep 2
done

kubectl apply -f "$CALICO"
kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
kubectl -n kube-system set env daemonset/calico-node FELIX_XDPENABLED=false
