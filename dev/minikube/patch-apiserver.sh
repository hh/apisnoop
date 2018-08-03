#!/bin/sh
SCRIPT=$(readlink -f "$0")
WD=$(dirname "$SCRIPT")
IFS=''
APISERVER_CONFIG="/etc/kubernetes/manifests/kube-apiserver.yaml"
PATCHED_CONFIG="/tmp/kube-apiserver.yaml.patched"
rm -f "$PATCHED_CONFIG"

echo Waiting for $APISERVER_CONFIG to exist!
while [ ! -f $APISERVER_CONFIG ]
do
    echo -n .
    sleep 4
done

# patch won't work because of indeterministic volume(Mount) ordering
# could probably be sed as well
while read LINE
do
    echo "$LINE" >> "$PATCHED_CONFIG"
    # Append a few lines when in case of a $LINE containing:
    case "$LINE" in
        *"- kube-apiserver"*)
            echo "    - --audit-log-path=${WD}/audit.log" >> "$PATCHED_CONFIG"
            echo "    - --audit-policy-file=${WD}/audit-policy.yaml" >> "$PATCHED_CONFIG"
            # echo "    - --audit-webhook-config-file=${WD}/webhook-config.yaml" >> "$PATCHED_CONFIG"
            ;;
        *"volumeMounts:"*)
            echo "    - mountPath: ${WD}" >> "$PATCHED_CONFIG"
            echo "      name: data" >> "$PATCHED_CONFIG"
            ;;
        *"volumes:"*)
            echo "  - hostPath:" >> "$PATCHED_CONFIG"
            echo "      path: ${WD}" >> "$PATCHED_CONFIG"
            echo "    name: data" >> "$PATCHED_CONFIG"
            ;;
    esac
done < "$APISERVER_CONFIG"

cp "$APISERVER_CONFIG" "/tmp/kube-apiserver.yaml.original"
cp "$PATCHED_CONFIG" "$APISERVER_CONFIG"

echo $APISERVER_CONFIG patched for audit-logging!
