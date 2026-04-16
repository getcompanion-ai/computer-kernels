## computer-kernels

<img width="3598" height="1184" alt="Gemini_Generated_Image_d10lsxd10lsxd10l" src="https://github.com/user-attachments/assets/10959cd0-3999-4160-8519-d8d33b7c084c" />

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
