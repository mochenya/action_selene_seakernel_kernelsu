#!/usr/bin/env sh
#
# GNU General Public License v3.0
# Copyright (C) 2023 MoChenYa mochenya20070702@gmail.com
#

WORKDIR="$(pwd)"

# ZyClang
ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-20230621-release/Clang-17.0.0-20230621.tar.gz"
ZYCLANG_DIR="$WORKDIR/ZyClang/bin"

# Kernel Source
KERNEL_GIT="https://github.com/mochenya/Sea_Kernel-Selene.git"
KERNEL_BRANCHE="twelve-test"
KERNEL_DIR="$WORKDIR/SeaKernel"

# Anykernel3
ANYKERNEL3_GIT="https://github.com/Kentanglu/AnyKernel3.git"
ANYKERNEL3_BRANCHE="selene-old"

# Magiskboot
MAGISKBOOT_DLINK="https://github.com/xiaoxindada/magiskboot_ndk_on_linux/releases/download/Magiskboot-26102-41/magiskboot.7z"
MAGISKBOOT="$WORKDIR/magiskboot/magiskboot"
ORIGIN_BOOTIMG_DLINK="https://github.com/mochenya/action_selene_seakernel_kernelsu/releases/download/originboot/boot.img"

# Build
DEVICES_CODE="selene"
DEVICE_DEFCONFIG="selene_defconfig"
DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/arch/arm64/configs/$DEVICE_DEFCONFIG"
IMAGE="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
DTB="$KERNEL_DIR/out/arch/arm64/boot/dts/mediatek/mt6768.dtb"
DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"

export KBUILD_BUILD_USER=MoChenYa
export KBUILD_BUILD_HOST=GitHubCI

msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

cd $WORKDIR

# Download ZyClang
msg " • 🌸 Work on $WORKDIR 🌸"
msg " • 🌸 Cloning Toolchain 🌸 "
mkdir -p ZyClang
aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
tar -C ZyClang/ -zxvf ZyClang.tar.gz
rm -rf ZyClang.tar.gz

# CLANG LLVM VERSIONS
CLANG_VERSION="$($ZYCLANG_DIR/clang --version | head -n 1)"
LLD_VERSION="$($ZYCLANG_DIR/ld.lld --version | head -n 1)"

msg " • 🌸 Cloning Kernel Source 🌸 "
git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
cd $KERNEL_DIR

msg " • 🌸 Patching KernelSU 🌸 "
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
KERNELSU_VERSION=$(($KSU_GIT_VERSION + 10000 + 200))
msg " • 🌸 KernelSU version: $KERNELSU_VERSION 🌸 "

# PATCH KERNELSU
msg " • 🌸 Applying patches || "

apply_patchs () {
for patch_file in $WORKDIR/patchs/*.patch
	do
	patch -p1 < "$patch_file"
done
}
apply_patchs

sed -i "/CONFIG_LOCALVERSION=\"/s/.$/-KSU-$KERNELSU_VERSION\"/" $DEVICE_DEFCONFIG_FILE

# BUILD KERNEL
msg " • 🌸 Started Compilation 🌸 "

args="PATH=$ZYCLANG_DIR:$PATH \
ARCH=arm64 \
SUBARCH=arm64 \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
CC=clang \
NM=llvm-nm \
CXX=clang++ \
AR=llvm-ar \
LD=ld.lld \
STRIP=llvm-strip \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
OBJSIZE=llvm-size \
READELF=llvm-readelf \
HOSTAR=llvm-ar \
HOSTLD=ld.lld \
HOSTCC=clang \
HOSTCXX=clang++ \
LLVM=1 \
LLVM_IAS=1"

# LINUX KERNEL VERSION
rm -rf out
make O=out $args $DEVICE_DEFCONFIG
KERNEL_VERSION=$(make O=out $args kernelversion | grep "4.14")
msg " • 🌸 LINUX KERNEL VERSION : $KERNEL_VERSION 🌸 "
make O=out $args -j"$(nproc --all)"

msg " • 🌸 Packing Kernel 🌸 "
cd $WORKDIR
git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCHE $WORKDIR/Anykernel3
cd $WORKDIR/Anykernel3
cp $IMAGE .
cp $DTB $WORKDIR/Anykernel3/dtb
cp $DTBO .
echo "• Within KernelSU $KERNELSU_VERSION !!!" >> $WORKDIR/Anykernel3/banner

# PACK FILE
time=$(TZ='Asia/Shanghai' date +"%Y-%m-%d %H:%M:%S")
shanghai_time=$(TZ='Asia/Shanghai' date +%Y%m%d%H)
ZIP_NAME="KernelSU-$KERNELSU_VERSION-ROSS-selene-$KERNEL_VERSION-SeaWe-$shanghai_time-GithubCI"
find ./ * -exec touch -m -d "$time" {} \;
zip -r9 $ZIP_NAME.zip *
mkdir -p $WORKDIR/out && cp *.zip $WORKDIR/out && cp $DTBO $WORKDIR/out

# Packed Image
# Setup magiskboot
cd $WORKDIR && mkdir magiskboot
aria2c -s16 -x16 -k1M $MAGISKBOOT_DLINK -o magiskboot.7z
7z e magiskboot.7z out/x86_64/magiskboot -omagiskboot/
rm -rf magiskboot.7z

# Download original boot.img
aria2c -s16 -x16 -k1M $ORIGIN_BOOTIMG_DLINK -o magiskboot/boot.img
cd $WORKDIR/magiskboot

# Packing
$MAGISKBOOT unpack -h boot.img
cp $IMAGE ./Image.gz-dtb
$MAGISKBOOT split Image.gz-dtb
cp $DTB ./dtb
$MAGISKBOOT repack boot.img
mv new-boot.img $WORKDIR/out/$ZIP_NAME.img
# SElinux Permissive
sed -i '/cmdline=/ s/$/ androidboot.selinux=permissive/' header
$MAGISKBOOT repack boot.img
mv new-boot.img $WORKDIR/out/$ZIP_NAME-Permissive.img

cd $WORKDIR/out
echo "
### SEA KERNEL WITH KERNELSU
1. 🌊 **时间** : $(TZ='Asia/Shanghai' date +"%Y-%m-%d %H:%M:%S") # ShangHai TIME
2. 🌊 **设备代号** : $DEVICES_CODE
3. 🌊 **LINUX 版本** : $KERNEL_VERSION
4. 🌊 **KERNELSU 版本**: $KERNELSU_VERSION
5. 🌊 **CLANG 版本**: $CLANG_VERSION
6. 🌊 **LLD 版本**: $LLD_VERSION
7. 🌊 **Anykernel3**: $ZIP_NAME.zip
8. 🌊 **Anykernel3 MD5**: $(md5sum $ZIP_NAME.zip | awk '{print $1}')
9. 🌊 **Image镜像**: $ZIP_NAME.img
10. 🌊 **Image镜像 MD5** $(md5sum $ZIP_NAME.img | awk '{print $1}')
11. 🌊 **Image镜像(Permissive)**: $ZIP_NAME-Permissive.img
12. 🌊 **Image镜像(Permissive) MD5**: $(md5sum $ZIP_NAME-Permissive.img | awk '{print $1}')
" > RELEASE.md
echo "$(TZ='Asia/Shanghai' date +"%Y-%m-%d %H:%M:%S") KernelSU $KERNELSU_VERSION" > RELEASETITLE.txt
cat RELEASE.md
cat RELEASETITLE.txt
msg "• 🌸 Done! 🌸 "
