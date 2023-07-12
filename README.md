# ti-bdebstrap

Scripts to build custom bootstrap images using bdebstrap for TI platforms

## Directory Structure

```bash
├── build.sh
├── builds.toml
├── configs
│   ├── bdebstrap_configs
│   │   ├── bookworm-default.yaml
│   │   └── bullseye-default.yaml
│   ├── bsp_sources.toml
│   └── machines.toml
├── LICENSE
├── README.md
├── scripts
│   ├── build_bsp.sh
│   ├── build_distro.sh
│   ├── common.sh
│   └── setup.sh
├── target
│   └── files for target configs
```

## Prerequisites

Host Setup - Ubuntu 22.04 (Recommended)

To install the dependencies, run the following commands

```bash
sudo apt update
sudo apt install -y \
        pigz expect pv \
        binfmtc binfmt-support \
        qemu-user qemu-user-static qemu-system-arm \
        debian-archive-keyring bdebstrap \
        build-essential autoconf automake \
        bison flex libssl-dev \
        bc u-boot-tools swig python3-pyelftools
sudo apt install --fix-broken
pip3 install toml-cli
```

## Usage

A **build** (specified in `builds.toml` file) represents the image for a
particular machine, BSP version and distribution variant. The `builds.toml`
file contains a list of builds, with corresponding machine, BSP version and
distribution variant specifications.

Further, each machine is defined in `configs/machines.toml`. Each BSP version is
defined in `configs/bsp_sources.toml`. Each distribution variant is defined in
the `configs/bdebstrap_configs/` directory.

Running these scripts requires root privileges.

##### General Syntax:

```bash
sudo ./build.sh <build>
```

Each successful build is placed in `build/` directory. Logs for each build are
placed in the `logs/` directory.

For example, the following command builds a Bookworm Debian image for am62xx-evm
machine, where the BSP version is 09.00.00.005.

```bash
sudo ./build.sh am62x_bookworm-no-km_09.00.00.005
```

The output will be generated at `build/`. The log file will be
`logs/am62x_bookworm-no-km_09.00.00.005.log`.

## Post-Build:

During the build, a tar file is stored in `build/`. Untar it and flash the
rootfs and boot partitions into a SD card.

Following that, you should have a basic Debian system set up. However, this
system does not yet contain any out-of-tree kernel modules. Therefore they need
to be installed after booting in.

At the very least, you should install the `ti-img-rogue-driver` to enable
display. Use the following command:

```bash
apt install ti-img-rogue-driver
```

To load the driver, reboot.

Once rebooted, the driver should work. To verify that it is loaded, type:

```bash
lsmod | grep pvr
```
If you see output of pvrsrvkm driver, it means that the driver has loaded
correctly.
