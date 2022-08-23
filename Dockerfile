FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

RUN set -e \
    && sed -i 's/archive.ubuntu.com/mirrors.nju.edu.cn/g' /etc/apt/sources.list \
    && sudo apt-get update \
    && sudo apt-get install --no-install-recommends -y \
    acl aptly aria2 bc binfmt-support bison btrfs-progs build-essential busybox  \
    ca-certificates ccache clang coreutils cpio crossbuild-essential-arm64  \
    cryptsetup curl debian-archive-keyring debian-keyring debootstrap  \
    device-tree-compiler dialog dirmngr distcc dosfstools dwarves f2fs-tools  \
    fakeroot flex gawk gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi gdisk git gpg  \
    gzip imagemagick jq kmod lib32ncurses-dev lib32stdc++6 libbison-dev  \
    libc6-dev-armhf-cross libc6-i386 libcrypto++-dev libelf-dev libfdt-dev  \
    libfile-fcntllock-perl libfl-dev liblz4-tool libncurses-dev libncurses5  \
    libncurses5-dev libncursesw5-dev libpython2.7-dev libssl-dev libusb-1.0-0-dev  \
    linux-base lld llvm locales lz4 lzma lzop ncurses-base ncurses-term  \
    nfs-kernel-server ntpdate p7zip p7zip-full parallel parted patchutils pigz pixz  \
    pkg-config pv python2 python3 python3-dev python3-distutils qemu-user-static  \
    rename rsync subversion swig tar u-boot-tools udev unzip uuid-dev vim wget  \
    whiptail xsltproc xz-utils zip zlib1g-dev zstd  \
    && sudo apt-get autoremove --purge -y \
    && sudo rm -rf /var/lib/apt/lists/* 2>/dev/null
