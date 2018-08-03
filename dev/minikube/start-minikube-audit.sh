#!/bin/sh
# set -e
# set -x

# wait for minikube to be available
(
    echo -n waiting for minikube:
    while [ ! `minikube ip 2> /dev/null| grep .` ]
    do
        echo -n .
        sleep 5
    done && (
        # mount this dir to /audit-logging
        # background minikube mount and sleep while it starts
        minikube mount .:/audit-logging/ & sleep 3
    )
    # patch apiserver config to log to /audit-logging/
    minikube ssh sudo /audit-logging/patch-apiserver.sh
) &

minikube start --v=4  --mount --mount-string=$PWD:/audit-logging \
         --feature-gates=AdvancedAuditing=true
# wait for our all commands to finish
wait
# echo
# echo "Running this should update kube-apiserver.yaml and trigger a restart:"
# echo ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    # -i $(minikube ssh-key) docker@$(minikube ip) \
    # sudo /audit-logging/apiserver-config-v2.patch.sh
# echo
# echo "Running this sets up a test server to receive events from the webhook:"
# echo "go run test-server.go"
