# Arch Linux ARM Images
Forked From [Arch Linux / archlinux-docker · GitLab](https://gitlab.archlinux.org/archlinux/archlinux-docker)

---

> [!TIP]
> [Arch Linux Ports AArch64](https://ports.archlinux.page/aarch64/) OCI Images are now available, please switch to the `ports` branch of this repository to learn more: <https://github.com/lfdevs/archlinuxarm-docker/tree/ports>

This repository provides Docker container images in Docker Hub: https://hub.docker.com/r/lfdevs/archlinuxarm

```bash
docker pull lfdevs/archlinuxarm:base-devel
```

Only one version of the images is provided currently: `base-devel` (approx. 300 MiB)

It is strongly recommended running `pacman -Syyu` right after starting a container due to the rolling release nature of Arch Linux.

## Build
This image is automatically built once a month on the 8th using [GitHub Actions](https://github.com/lfdevs/archlinuxarm-docker/actions/workflows/build.yml).

The Rootfs used in this image is from the Arch Linux ARM official website: http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz