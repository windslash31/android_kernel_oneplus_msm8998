#!/bin/bash

#
#  Build Script for RenderZenith for OnePlus 5!
#  Based off AK'sbuild script - Thanks!
#

VENDOR_MODULES=(
  "msm_11ad_proxy.ko"
  "wil6210.ko"
)

# Bash Color
rm .version
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz-dtb"
DEFCONFIG="oneplus5_defconfig"

# Kernel Details
VER=Render-Kernel
VARIANT="OP5-OOS-N-EAS"

# Vars
export LOCALVERSION=~`echo $VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=RenderZenith
export KBUILD_BUILD_HOST=RenderServer.net
export CCACHE=ccache

# Paths
KERNEL_DIR=`pwd`
KBUILD_OUTPUT="${KERNEL_DIR}/../out"
REPACK_DIR="${HOME}/android/source/kernel/AnyKernel2"
PATCH_DIR="${HOME}/android/source/kernel/AnyKernel2/patch"
MODULES_DIR="${HOME}/android/source/kernel/AnyKernel2/modules"
ZIP_MOVE="${HOME}/android/source/zips/OP5-zips"
ZIMAGE_DIR="$KBUILD_OUTPUT/arch/arm64/boot"

# Create output directory
mkdir -p ${KBUILD_OUTPUT}

# Functions
function checkout_ak_branches {
        cd $REPACK_DIR
        git checkout rk-op5-oos-o
        cd $KERNEL_DIR
}

function clean_all {
        cd $REPACK_DIR
        rm -rf $MODULES_DIR/*
        rm -rf $KERNEL
        rm -rf $DTBIMAGE
        rm -rf zImage
        cd $KERNEL_DIR
        echo
        make O=${KBUILD_OUTPUT} clean && make O=${KBUILD_OUTPUT} mrproper
}

function make_kernel {
        echo
        make O=${KBUILD_OUTPUT} $DEFCONFIG
        make O=${KBUILD_OUTPUT} $THREAD
}

function make_modules {
	# Remove and re-create modules directory
	rm -rf $MODULES_DIR
	mkdir -p $MODULES_DIR/system/lib/modules
	mkdir -p $MODULES_DIR/system/vendor/lib/modules

	# Copy modules over
	echo ""
        find $KBUILD_OUTPUT -name '*.ko' -exec cp -v {} $MODULES_DIR/system/lib/modules \;

	# Strip modules
	${CROSS_COMPILE}strip --strip-unneeded $MODULES_DIR/system/lib/modules/*.ko

	# Sign modules
	find $MODULES_DIR/system/lib/modules -name '*.ko' -exec $KBUILD_OUTPUT/scripts/sign-file sha512 $KBUILD_OUTPUT/certs/signing_key.pem $KBUILD_OUTPUT/certs/signing_key.x509 {} \;

	# Move vendor modules to vendor directory
	if [ ${#VENDOR_MODULES[@]} -ne 0 ]; then
	  echo ""
	  for mod in ${VENDOR_MODULES[@]}; do
	    if [ -f $MODULES_DIR/system/lib/modules/$mod ]; then
	      mv $MODULES_DIR/system/lib/modules/$mod $MODULES_DIR/system/vendor/lib/modules
	      echo "Moved $mod to /system/vendor/lib/modules."
	    fi
	  done
	  echo ""
	fi
}

function make_zip {
        cp -vr $ZIMAGE_DIR/$KERNEL $REPACK_DIR/zImage
        cd $REPACK_DIR
        zip -r9 RenderZenith-"$VARIANT"-V.zip *
        mv RenderZenith-"$VARIANT"-V.zip $ZIP_MOVE
        cd $KERNEL_DIR
}

DATE_START=$(date +"%s")

echo -e "${green}"
echo "RenderZenith Creation Script:"
echo -e "${restore}"

echo "Pick Toolchain..."
select choice in LINARO-aarch64-linux-gnu-4.9.4-012017 LINARO-aarch64-linux-gnu-6.4.1-082017 LINARO-aarch64-linux-gnu-7.1.1-082017
do
case "$choice" in
    "LINARO-aarch64-linux-gnu-4.9.4-012017")
        export CROSS_COMPILE=${HOME}/android/source/toolchains/LINARO-aarch64-linux-gnu-4.9.4-012017/bin/aarch64-linux-android-
        break;;
    "LINARO-aarch64-linux-gnu-6.4.1-082017")
        export CROSS_COMPILE=${HOME}/android/source/toolchains/LINARO-aarch64-linux-gnu-6.4.1-082017/bin/aarch64-linux-gnu-
        break;;
    "LINARO-aarch64-linux-gnu-7.1.1-082017")
        export CROSS_COMPILE=${HOME}/android/source/toolchains/LINARO-aarch64-linux-gnu-7.1.1-082017/bin/aarch64-linux-gnu-
        break;;

esac
done

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
    y|Y )
        checkout_ak_branches
        clean_all
        echo
        echo "All Cleaned now."
        break
        ;;
    n|N )
        break
        ;;
    * )
        echo
        echo "Invalid try again!"
        echo
        ;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
  y|Y)
    make_kernel
    break
    ;;
  n|N )
    break
    ;;
  * )
    echo
    echo "Invalid try again!"
    echo
    ;;
esac
done

while read -p "Do you want to ZIP kernel (y/n)? " dchoice
do
case "$dchoice" in
  y|Y)
    make_modules
    make_zip
    break
    ;;
  n|N )
    break
    ;;
  * )
    echo
    echo "Invalid try again!"
    echo
    ;;
esac
done

echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
