#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

ROOT=$(dirname "${BASH_SOURCE[0]}")

source "${ROOT}/kvm.sh"

trap cleanup EXIT
trap cleanup SIGINT

just
setup
boot
wait_for_boot
sync_file target/debug/adjustd /home/ubuntu/adjustd
sync_file data/config.yaml /home/ubuntu/config.yaml
vm_ssh sudo mv /home/ubuntu/adjustd /usr/local/bin/adjustd
vm_ssh sudo mkdir -p /usr/local/bin/data
vm_ssh sudo mv /home/ubuntu/config.yaml /usr/local/bin/data/config.yaml
vm_ssh bash -c "cd /usr/local/bin && ./adjustd"
vm_ssh du -b /usr/local/bin/adjustd | numfmt --to=iec
