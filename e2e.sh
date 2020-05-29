#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

ROOT=$(dirname "${BASH_SOURCE[0]}")

source "${ROOT}/kvm.sh"

trap cleanup EXIT
trap cleanup SIGINT

cargo || true
cargo install just
just 
