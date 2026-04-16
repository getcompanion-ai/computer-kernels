ARCH ?= x86_64
KERNEL_VERSION ?= $(shell awk 'NF && $$1 !~ /^#/' kernel_versions.txt | head -n 1)
OUTPUT_DIR ?= .out
LINUX_REPO_DIR ?= .work/linux
JOBS ?= $(shell nproc)

.PHONY: build print-kernel-version

build:
	./build.sh --arch $(ARCH) --kernel-version $(KERNEL_VERSION) --output-dir $(OUTPUT_DIR) --linux-repo-dir $(LINUX_REPO_DIR) --jobs $(JOBS)

print-kernel-version:
	@echo $(KERNEL_VERSION)
