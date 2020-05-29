#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

SSH_OPTS="-o PasswordAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=5"
TMPDIR="$(mktemp -d)"

function vm_ssh() {
    ssh -i "${TMPDIR}/sshkey" -p "2222" $SSH_OPTS ubuntu@localhost "$@"
}

function cleanup() {
    if [ -e "${TMPDIR}/qemu-kvm.id" ]; then
        PID=$(cat "${TMPDIR}/qemu-kvm.id")
        vm_ssh sudo shutdown now || true
        sleep 2
        kill "$PID" || true
        rm -rf "${TMPDIR}"
    fi
}

function boot() {
    echo "Cleaning up old VM"
    if [ -e "${TMPDIR}/qemu-kvm.id" ]; then
        PID=$(cat "${TMPDIR}/qemu-kvm.id")
        kill "$PID" || true
        rm -f "${TMPDIR}/qemu-kvm.id"
    fi
    echo "Booting VM"
    # Add '-serial mon:stdio' below for debugging.
    # it will print all VM output to stdio from the background.
    qemu-system-x86_64 \
        -pidfile "${TMPDIR}/qemu-kvm.id" \
        -enable-kvm \
        -smp cpus=2 \
        -m 4096 \
        -drive file="${TMPDIR}/bionic.img",format=raw,if=virtio,cache=off,aio=native \
        -drive file="${TMPDIR}/userdata.img",format=raw,if=virtio \
        -net nic,model=virtio \
        -net user,hostfwd=tcp::2222-:22 \
        -display none \
        -device virtio-rng-pci \
        -device virtio-balloon & 
}

function wait_for_boot() {
	attempts=0
    max=20
	echo "Waiting for VM to come up..."
	while ! vm_ssh true 2>&1 >/dev/null
	do
		sleep 5
		attempts=$((attempts + 1))
		if [ "$attempts" -eq "$max" ]
		then
			echo "Giving up."
			cleanup
			exit 1
		fi
		echo "Attempt $attempts..."
	done
    echo "Booted successfully!"
}

function add_file() {
    echo "Copying $1 to $2 on target host"
    scp -i ${TMPDIR}/sshkey -P 2222 $SSH_OPTS "$1" "ubuntu@localhost:$2"
}

function setup() {
    wget -O "${TMPDIR}/bionic-qcow.img" https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
    qemu-img convert -f qcow2 -O raw "${TMPDIR}/bionic-qcow.img" "${TMPDIR}/bionic.img"
    sudo apt update && sudo apt install -y qemu-kvm cloud-image-utils
    ssh-keygen -n 4096 -t rsa -f "${TMPDIR}/sshkey" -q -N "" <<< y > /dev/null
    CLOUD_CONFIG="#cloud-config
ssh_pwauth: False
ssh_authorized_keys:
- $(cat ${TMPDIR}/sshkey.pub)
"
    cat > "${TMPDIR}/userdata" <<EOF
$CLOUD_CONFIG
EOF
    cloud-localds "${TMPDIR}/userdata.img" "${TMPDIR}/userdata"
}

function sync_file() {
    echo "Copying $1 to $2 on target host"
    rsync -avz -e "ssh -i ${TMPDIR}/sshkey $SSH_OPTS -p 2222" "$1" "ubuntu@localhost:$2"
}
