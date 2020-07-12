# mocaccino-ci

![MocaccinoOS Micro](https://github.com/mocaccinoOS/ci/workflows/MocaccinoOS%20Micro/badge.svg)
![MocaccinoOS GNOME](https://github.com/mocaccinoOS/ci/workflows/MocaccinoOS%20GNOME/badge.svg)
![MocaccinoOS MinimalX](https://github.com/mocaccinoOS/ci/workflows/MocaccinoOS%20MinimalX/badge.svg)

This repository contains GitHub Actions to build MocaccinoOS ISOs.

The CI will deploy from master the iso built in the [mocaccino keybase public directory](https://keybase.pub/mocaccino/iso/).


## Flavors

Each flavor is composed by packages coming from multiple repositories, here is a short summary.

| Flavor |[Mocaccino Micro Repository](https://github.com/mocaccinoOS/mocaccino-micro)|[Mocaccino Extra Repository](https://github.com/mocaccinoOS/mocaccino-extra)|[Mocaccino Desktop Repository](https://github.com/mocaccinoOS/desktop/tree/master/packages)|[LiveCD Repository](https://github.com/Luet-lab/livecd-specs)|[Luet Official Repository](https://github.com/Luet-lab/luet-repo)|
|--------|----------------------------|----------------------------|------------------------------|-------------------|--------------------------|
|[Micro](https://github.com/mocaccinoOS/ci/blob/master/specs/micro.yaml) ([conf](https://github.com/mocaccinoOS/ci/blob/master/conf/luet-micro.yaml))|:heavy_check_mark:             |              :heavy_check_mark:             |               :heavy_check_mark:              |         :heavy_check_mark:         |             :heavy_check_mark:            |
| [GNOME](https://github.com/mocaccinoOS/ci/blob/master/specs/gnome.yaml) ([conf](https://github.com/mocaccinoOS/ci/blob/master/conf/luet-desktop.yaml)) |                            |                            |               :heavy_check_mark:              |         :heavy_check_mark:         |             :heavy_check_mark:            |
| [MATE](https://github.com/mocaccinoOS/ci/blob/master/specs/mate.yaml) ([conf](https://github.com/mocaccinoOS/ci/blob/master/conf/luet-desktop.yaml))|                            |                            |               :heavy_check_mark:              |         :heavy_check_mark:         |             :heavy_check_mark:            |
| [KDE](https://github.com/mocaccinoOS/ci/blob/master/specs/kde.yaml) ([conf](https://github.com/mocaccinoOS/ci/blob/master/conf/luet-desktop.yaml))|                            |                            |               :heavy_check_mark:              |         :heavy_check_mark:         |             :heavy_check_mark:            |
| [LXQT](https://github.com/mocaccinoOS/ci/blob/master/specs/lxqt.yaml) ([conf](https://github.com/mocaccinoOS/ci/blob/master/conf/luet-desktop.yaml))|                            |                            |               :heavy_check_mark:              |         :heavy_check_mark:         |             :heavy_check_mark:            |


*Note: Micro requires the kernel from the [mocaccino-desktop](https://github.com/mocaccinoOS/desktop/tree/master/packages) repository.*

## ISO specs

Each ISO has a corresponding spec that defines which packages and [luet](https://github.com/mudler/luet) repositories are required to build the ISO.

The specs are under the `spec/` folder. Here is an example:

```yaml
packages:
  # Packages to be installed in the rootfs
  rootfs:
  - utils/busybox 
  # Packages to be installed in the uefi image
  uefi:
  - live/systemd-boot
  - system/mocaccino-live-boot
  # Packages to be installed in the isoimage
  isoimage:
  - live/syslinux
  - system/mocaccino-live-boot
  # Packages to be installed in the initramfs
  initramfs:
  - distro/mocaccino-initramfs

# Use overlayfs to mount the rootfs. If disabled, only the initramfs will be booted.
overlay: "true"

# Image prefix. If Image date is disabled is used as the full title.
image_prefix: "MocaccinoOS-Micro-0."
image_date: "true"

# Luet config to use.
# It has to contain the repositories required to install the packages defined above.
luet:
  config: conf/luet-micro.yaml
```

Each spec defines which packages to be installed from [luet](https://github.com/mudler/luet) repositories. A config file for each spec has to be provided and placed in `conf/`.

To build the iso, you need to run the `isospec` script inside `scripts/`, for e.g.

```bash
$> git clone https://github.com/mocaccinoOS/ci.git mocaccino-ci
$> cd mocaccino-ci
$> ./scripts/isospec specs/micro.yaml
```

## Local Requirements

When running it locally, you need these tools installed:

- [luet](https://github.com/mudler/luet)
- luet-extensions (can be installed with `luet install luet-extensions` from the [Luet official repository](https://github.com/Luet-lab/luet-repo))
- xorriso
- squashfs-tools
- dosfstools
- jq
- yq

e.g. the CI installs them as the following:

```bash
$> sudo apt-get install -y xorriso squashfs-tools dosfstools
$> curl https://gist.githubusercontent.com/mudler/8b8d6c53c4669f4b9f9a72d1a2b92172/raw/e9d38b8e0702e7f1ef9a5db1bfa428add12a2d24/get_luet_root.sh | sudo sh
$> sudo luet install repository/mocaccino-extra
$> sudo luet install utils/jq utils/yq
```
