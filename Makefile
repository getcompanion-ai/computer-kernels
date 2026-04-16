ARCH ?= x86_64
KERNEL_VERSION ?= $(shell head -n 1 kernel_versions.txt)

.PHONY: build print-kernel-version

build:
	./build.sh --arch $(ARCH) --kernel-version $(KERNEL_VERSION)

print-kernel-version:
	@echo $(KERNEL_VERSION)
