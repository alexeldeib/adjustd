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
sync_file target/debug/adjustd /usr/local/bin/adjustd
vm_ssh ls /usr/local/bin | grep adjust
