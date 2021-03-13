export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
export ISO?=$(ROOT_DIR)/$(shell ls *.iso)

# QEMU

$(ROOT_DIR)/.qemu:
	mkdir -p $(ROOT_DIR)/.qemu

$(ROOT_DIR)/.qemu/drive.img: $(ROOT_DIR)/.qemu
	qemu-img create -f qcow2 $(ROOT_DIR)/.qemu/drive.img 16g

run-qemu: $(ROOT_DIR)/.qemu/drive.img
	$(QEMU) \
	-m $(QEMU_MEMORY) \
	-cdrom $(ISO) \
	-nographic \
	-serial mon:stdio \
	-rtc base=utc,clock=rt \
	-chardev socket,path=$(ROOT_DIR)/.qemu/qga.sock,server,nowait,id=qga0 \
	-device virtio-serial \
	-hda $(ROOT_DIR)/.qemu/drive.img $(QEMU_ARGS)

# Packer

.PHONY: packer
packer:
	cd $(ROOT_DIR)/packer && packer build -var "iso=$(ISO)" $(PACKER_ARGS) images.json

# Tests

prepare-test:
	vagrant box add mocaccino packer/*.box
	vagrant up || true

Vagrantfile:
	vagrant init mocaccino

test-clean:
	vagrant destroy || true
	vagrant box remove mocaccino || true

test: test-clean Vagrantfile prepare-test
	cd $(ROOT_DIR)/tests && go test
