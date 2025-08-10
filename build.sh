#!/usr/bin/env bash
#
# GNU General Public License v3.0
# Copyright (C) 2024 MoChenYa mochenya20070702@gmail.com
#

# 设置工作目录
WORKDIR="$(pwd)"

# ZyClang 工具链下载链接
ZYCLANG_DLINK="https://github.com/ZyCromerZ/Clang/releases/download/19.0.0git-20240217-release/Clang-19.0.0git-20240217.tar.gz"
# ZyClang 工具链路径
ZYCLANG_DIR="$WORKDIR/ZyClang/bin"

# 内核源码 Git 仓库地址
KERNEL_GIT="https://github.com/25ji-Telegram-de/android_kernel_xiaomi_selene.git"
# 内核源码分支
KERNEL_BRANCHE="yuki-saisei"
# 内核源码目录
KERNEL_DIR="$WORKDIR/Kernel"
# SeaKernel 版本号
SEA_KERNEL_VERSION="Ayaka"
# SeaKernel 代号
SEA_KERNEL_CODENAME="9/Ayaka🐲✨"
# SeaKernel 代号（用于 sed）
SEA_KERNEL_CODENAME_ESCAPE="9\/Ayaka🐲✨"

# 编译配置
# 设备代号
DEVICES_CODE="selene"
# 设备 defconfig 文件名
DEVICE_DEFCONFIG="selene_defconfig"
# 设备 defconfig 文件路径
DEVICE_DEFCONFIG_FILE="$KERNEL_DIR/arch/arm64/configs/$DEVICE_DEFCONFIG"
# 内核镜像路径
IMAGE="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
# DTB 文件路径
DTB="$KERNEL_DIR/out/arch/arm64/boot/dts/mediatek/mt6768.dtb"
# DTBO 镜像路径
DTBO="$KERNEL_DIR/out/arch/arm64/boot/dtbo.img"

# 设置编译用户信息
export KBUILD_BUILD_USER=MoChenYa
export KBUILD_BUILD_HOST=GitHubCI

# 自定义消息输出函数
msg() {
	echo
	echo -e "\e[1;32m$*\e[0m"
	echo
}

# 切换到工作目录
cd $WORKDIR

# 下载并解压 ZyClang 工具链
msg " • 🌸 Work on $WORKDIR 🌸"
msg " • 🌸 Cloning Toolchain 🌸 "
msg " • 🌸 Donwload $ZYCLANG_DLINK 🌸 "
mkdir -p ZyClang
aria2c -s16 -x16 -k1M $ZYCLANG_DLINK -o ZyClang.tar.gz
tar -C ZyClang/ -zxvf ZyClang.tar.gz
rm -rf ZyClang.tar.gz

# 获取 CLANG 和 LLVM 版本信息
CLANG_VERSION="$($ZYCLANG_DIR/clang --version | head -n 1)"
LLD_VERSION="$($ZYCLANG_DIR/ld.lld --version | head -n 1)"

# 克隆内核源码
msg " • 🌸 Cloning Kernel Source 🌸 "
git clone --depth=1 $KERNEL_GIT -b $KERNEL_BRANCHE $KERNEL_DIR
cd $KERNEL_DIR
# 获取最新的 commit hash
KERNEL_HEAD_HASH=$(git log --pretty=format:'%H' -1)

# 集成 KernelSU
# msg " • 🌸 Patching KernelSU 🌸 "
# curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -
# KSU_GIT_VERSION=$(cd KernelSU && git rev-list --count HEAD)
# KERNELSU_VERSION=$(($KSU_GIT_VERSION + 10000 + 200))
# msg " • 🌸 KernelSU version: $KERNELSU_VERSION 🌸 "

# 应用补丁
# msg " • 🌸 Applying patches 🌸 "

# apply_patchs () {
# for patch_file in $WORKDIR/patchs/*.patch
# 	do
# 	patch -p1 < "$patch_file"
# done
# }
# apply_patchs

# # 启用 KernelSU
# echo -e "\n# KernelSU\nCONFIG_KSU=y" >> $DEVICE_DEFCONFIG_FILE

# 修改内核版本号
# sed -i "/CONFIG_LOCALVERSION=\"/s/.$/$SEA_KERNEL_CODENAME_ESCAPE-KSU-$KERNELSU_VERSION"/g" $DEVICE_DEFCONFIG_FILE
# msg " • 🌸 $(grep 'CONFIG_LOCALVERSION=' $DEVICE_DEFCONFIG_FILE) 🌸 "

# 编译内核
msg " • 🌸 Started Compilation 🌸 "

# 创建输出目录
mkdir -p $WORKDIR/out

# 编译参数
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
LLVM=1"

# 获取 Linux 内核版本
rm -rf out
make O=out $args $DEVICE_DEFCONFIG
KERNEL_VERSION=$(make O=out $args kernelversion | grep "4.14")
msg " • 🌸 LINUX KERNEL VERSION : $KERNEL_VERSION 🌸 "
# 开始编译
make O=out $args -j"$(nproc --all)" | tee "$WORKDIR/out/Build.log"

# 检查编译结果
msg " • 🌸 Checking builds 🌸 "
if [ ! -e $IMAGE ]; then
    echo -e " • 🌸 \033[31mBuild Failed!\033[0m"
    exit 1
fi

# 打包内核
msg " • 🌸 Packing Kernel 🌸 "
cd $WORKDIR
# 克隆 Anykernel3
git clone --depth=1 $ANYKERNEL3_GIT -b $ANYKERNEL3_BRANCHE $WORKDIR/Anykernel3
cd $WORKDIR/Anykernel3
# 复制内核镜像、dtb、dtbo
cp $IMAGE .
cp $DTB $WORKDIR/Anykernel3/dtb
cp $DTBO .
# 添加 KernelSU 版本信息到 banner
echo "• Within KernelSU $KERNELSU_VERSION !!!" >> $WORKDIR/Anykernel3/banner

# 打包成 zip
time=$(TZ='Asia/Shanghai' date +"%Y-%m-%d %H:%M:%S")
shanghai_time=$(TZ='Asia/Shanghai' date +%Y%m%d%H)
ZIP_NAME="KernelSU-$KERNELSU_VERSION-ROSS-selene-$KERNEL_VERSION-Sea-$SEA_KERNEL_VERSION-$shanghai_time-GithubCI"
find ./ * -exec touch -m -d "$time" {} \;
zip -r9 $ZIP_NAME.zip *
cp *.zip $WORKDIR/out && cp $DTBO $WORKDIR/out

# 生成 Release 信息
cd $WORKDIR/out
echo "
### SEA KERNEL WITH KERNELSU
- 🌊 **Build Time** : $(TZ='Asia/Shanghai' date +"%Y-%m-%d %H:%M:%S") # ShangHai TIME
- 🌊 **Device Code** : $DEVICES_CODE
- 🌊 **Sea Kernel Codename** : R¹.$SEA_KERNEL_CODENAME
- 🌊 **Linux Version** : $KERNEL_VERSION
- 🌊 **KernelSU Version**: $KERNELSU_VERSION
- 🌊 **Clang Version**: $CLANG_VERSION
- 🌊 **LLD Version**: $LLD_VERSION
- 🌊 **Anykernel3**: $ZIP_NAME.zip
- 🌊 **Anykernel3 MD5**: $(md5sum $ZIP_NAME.zip | awk '{print $1}')
- 🌊 **Image**: $ZIP_NAME.img
- 🌊 **Image MD5** $(md5sum $ZIP_NAME.img | awk '{print $1}')
- 🌊 **Image(Permissive)**: $ZIP_NAME-Permissive.img
- 🌊 **Image(Permissive) MD5**: $(md5sum $ZIP_NAME-Permissive.img | awk '{print $1}')
" > RELEASE.md
echo "$KERNELSU_VERSION" > KSU_VERSION.txt
echo "$KERNEL_VERSION" > KERNEL_VERSION.txt
echo "$KERNEL_HEAD_HASH" > KERNEL_HEAD_HASH.txt
cat RELEASE.md
cat KSU_VERSION.txt
cat KERNEL_VERSION.txt
cat KERNEL_HEAD_HASH.txt
msg "• 🌸 Done! 🌸 "