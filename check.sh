#!/bin/bash

curl "https://api.github.com/repos/mochenya/action_selene_seakernel_kernelsu/releases/latest" | jq -r '.assets[].browser_download_url' > chktmp
LAST_KERNEL_HEAD_HASH=$(curl -L $(cat chktmp | grep KERNEL_HEAD_HASH))
LAST_KSU_VERSION=$(curl -L $(cat chktmp | grep KSU_VERSION))
rm chktmp

git clone https://github.com/tiann/KernelSU ksu_tmp
# use this one if main branch should be checked
#KSU_GIT_VERSION=$(cd ksu_tmp && git rev-list --count HEAD)
# use this one if latest tag (stable) should be checked
KSU_GIT_VERSION=$(cd ksu_tmp && git checkout "$(git describe --abbrev=0 --tags)" && git rev-list --count HEAD)
KSU_VERSION=$(($KSU_GIT_VERSION + 10000 + 200))
rm -rf ksu_tmp

REMOTE_HEAD_HASH=$(curl "https://api.github.com/repos/mochenya/Sea_Kernel-Selene/commits?per_page=1" | jq -r '.[].sha')

if [[ $LAST_KSU_VERSION == $KSU_VERSION ]] && [[ $LAST_KERNEL_HEAD_HASH == $REMOTE_HEAD_HASH ]] ; then
  echo no diff
  exit 1
fi
