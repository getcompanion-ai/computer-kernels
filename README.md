## computer-kernels

<img width=auto height=auto alt="Gemini_Generated_Image_d10lsxd10lsxd10l" src="https://github.com/user-attachments/assets/2f422d7e-0e17-4106-826a-0516f1edc828" />

computer-kernels is the monorepo source surface for the Firecracker guest
kernel artifacts used by the runtime.

It is the private source of truth for the public `computer-kernels` mirror.

Current scope:
- pin kernel versions in `kernel_versions.txt`
- keep per-arch kernel config under `configs/`
- build `vmlinux` artifacts for Firecracker guests

Current bootstrap target:
- `x86_64`
- `6.1.158`
