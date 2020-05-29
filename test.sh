#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

set -x

SSH_OPTS="-o PasswordAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=5"

function vm_ssh() {
    ssh -i /tmp/sshkey -p "2222" ubuntu@localhost $SSH_OPTS "$@"
}

function cleanup() {
    if [ -e /tmp/qemu-kvm.id ]; then
        PID=$(cat /tmp/qemu-kvm.id)
        vm_ssh sudo shutdown now || true
        sleep 2
        kill "$PID" || true
        rm -f /tmp/qemu-kvm.id
    fi
}

function boot() {
    echo "Cleaning up old VM"
    if [ -e /tmp/qemu-kvm.id ]; then
        PID=$(cat /tmp/qemu-kvm.id)
        kill "$PID" || true
        rm -f /tmp/qemu-kvm.id
    fi
    echo "Booting VM"
    qemu-system-x86_64 \
        -pidfile /tmp/qemu-kvm.id \
        -enable-kvm \
        -smp cpus=2 \
        -m 4096 \
        -drive file=bionic.img,if=virtio \
        -drive file=userdata.img,format=raw,if=virtio \
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
    scp -i /tmp/sshkey -P 2222 $SSH_OPTS "$1" "ubuntu@localhost:$2"
}

function setup() {
    wget -O bionic.img https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
    sudo apt update && sudo apt install -y qemu-kvm cloud-image-utils
    ssh-keygen -n 4096 -t rsa -f /tmp/sshkey -q -N "" <<< y > /dev/null
    CLOUD_CONFIG="#cloud-config
password: root
chpasswd: { expire: False }
ssh_pwauth: True
ssh_authorized_keys:
- $(cat /tmp/sshkey.pub)
"
    cat > userdata <<EOF
$CLOUD_CONFIG
EOF
    cloud-localds userdata.img userdata
}

trap cleanup EXIT
trap cleanup SIGINT

setup
boot
wait_for_boot
add_file blah.txt /home/ubuntu/boo.txt
vm_ssh sudo mv /home/ubuntu/boo.txt /etc/boo.txt
