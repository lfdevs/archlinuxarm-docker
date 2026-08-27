# Arch Linux AArch64 OCI Images

This branch builds unofficial Arch Linux OCI images for AArch64 systems from
the package repositories at
[arch-linux-repo.drzee.net](https://arch-linux-repo.drzee.net/arch/).

The packages target ARMv8.2-A and later processors. They are not built, hosted,
or signed by Arch Linux infrastructure, and will not run on earlier ARMv8-A
processors such as the Raspberry Pi 4. For details, please refer to the
[Arch Linux official documentation on AArch64](https://ports.archlinux.page/aarch64/).

## Images

The GitHub Actions workflow builds natively on an ARM64 runner and publishes
these Docker Hub tags:

| Image | Tags |
| --- | --- |
| `lfdevs/archlinux-ports` | `latest`, `base`, `base-<build-number>` |
| `lfdevs/archlinux-ports` | `base-devel`, `base-devel-<build-number>` |

```sh
docker pull lfdevs/archlinux-ports:latest
docker run --rm -it lfdevs/archlinux-ports:base-devel
```

The bootstrap archive and packages are verified with the drzee.net signing key
before use. The resulting image retains the drzee repository configuration and
its key, so `pacman` works after the container starts.

Because this is a rolling-release repository, update a running container before
installing additional packages:

```sh
pacman -Syu
```

## Local Build

Build on a native AArch64 Arch Linux environment with `make`, `fakechroot`,
`fakeroot`, `gnupg`, and `zstd` installed:

```sh
make image-base
make image-base-devel
```

The supported root filesystem groups are `base` and `base-devel`. The upstream
`multilib-devel` and `repro` variants are intentionally not built because the
drzee.net AArch64 repositories do not provide an AArch64 multilib repository or
an archive snapshot service for reproducing those upstream images.

This repository is derived from
[archlinux/archlinux-docker](https://github.com/archlinux/archlinux-docker).
