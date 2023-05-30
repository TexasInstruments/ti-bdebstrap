# ti-bdebstrap

Scripts to build custom bootstrap images using bdebstrap for TI platforms

## Directory Structure

```bash
ti-bdebstrap
├── build.sh
├── scripts
│   ├── build_bsp.sh
│   ├── common.sh
│   ├── read-config.py
│   └── setup.sh
├── configs
│   └── debian-bullseye.yaml
├── machines.ini
├── README.md
└── LICENSE
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

Note: The build script has to be run as root user

To build all distros for all supported machines, run

```bash
host$ ./build.sh
```

To build for a single machine, run

```bash
host$ ./build.sh <machine>
```

The output will be generated at `build/`

For ex:

To build for am62xx-evm

```bash
host$ ./build.sh am62xx-evm

```

and the output will be generated in ${topdir}/build

