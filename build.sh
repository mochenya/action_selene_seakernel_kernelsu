#!/bin/sh
#
# Copyright (C) 2023 MoChenYa mochenya20070702@gmail.com
#

WORKDIR="$(pwd)"

ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/17.0.0-20230401-release/Clang-17.0.0-20230401.tar.gz"
ZYCLANG_DIR="$WORKDIR/ZyClang/bin"

KERENEL_GIT="https://github.com/Kentanglu/Sea_Kernel-Selene.git"
KERNEL_BRANCHE="twelve-release"
KERNEL_DIR="$WORKDIR/SeaKernel"

ANYKERNEL3_GIT="https://github.com/Kentanglu/AnyKernel3.git"
ANYKERNEL3_BRANCHE="selene"

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

msg " • 🌸 Work on $WORKDIR 🌸"
msg " • 🌸 Cloning Toolchain 🌸 "
mkdir -p ZyClang
aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
tar -C ZyClang/ -zxvf ZyClang.tar.gz
rm -rf ZyClang.tar.gz

# CLANG LLVM VERSIONS
CLANG_VERSION="$("$ZYCLANG_DIR"/clang --version | head -n 1)"
LLD_VERSION="$("$ZYCLANG_DIR"/ld.lld --version | head -n 1)"

msg " • 🌸 Cloning Kernel Source 🌸 "
git clone --depth=1 $KERENEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
cd $KERNEL_DIR

msg " • 🌸 Patching KernelSU 🌸 "
curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
KERNELSU_VERSION=$(($KSU_GIT_VERSION + 10000 + 200))
msg " • 🌸 KernelSU version: $KERNELSU_VERSION 🌸 "

# PATCH KERNELSU
msg " • || Patching KernelSU || "

apply_patchs () {
for patch_file in $WORKDIR/patchs/*.patch
	do
	patch -p1 < "$patch_file"
done
}
#apply_patchs

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
echo "• With KernelSU $KERNELSU_VERSION !!!" >> $WORKDIR/Anykernel3/banner

# PACK FILE
ZIP_NAME="KernelSU-$KERNELSU_VERSION.R-OSS.selene.$KERNEL_VERSION.Sea.$(TZ=Asia/Shanghai date +"%Y-%m-%d-%H").GithubCI.zip"
zip -r9 $ZIP_NAME *
mkdir -p $WORKDIR/out && cp *.zip $WORKDIR/out
cd $WORKDIR/out
echo "
### SEA KERNEL WITH KERNELSU
1. 🌊 **时间** : $(TZ=Asia/Shanghai date) # SHANGHAI TIME
2. 🌊 **设备代号** : $DEVICES_CODE
3. 🌊 **LINUX 版本** : $KERNEL_VERSION
4. 🌊 **KERNELSU 版本**: $KERNELSU_VERSION
5. 🌊 **CLANG 版本**: $CLANG_VERSION
6. 🌊 **LLD 版本**: $LLD_VERSION
7. 🌊 **文件名**: $ZIP_NAME.zip
8. 🌊 **文件MD5**: $(md5sum $ZIP_NAME | awk '{print $1}')
" > RELEASE.md
echo "KernelSU $KERNELSU_VERSION $(TZ=Asia/Shanghai date +"%Y-%m-%d-%H")" > RELEASETITLE.txt
cat RELEASE.md
cat RELEASETITLE.txt
msg "• 🌸 Done! 🌸 "
