#!/bin/bash

#
#  Build Script for RenderZenith!
#

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Source from build config
if [ $# -ne 0 ]; then
    if [ ! -f $1 ]; then
        echo "$1 not found in current directory!"
        exit 1
    else
	source $1
    fi
elif [ -f build.config.default ]; then
    source build.config.default
else
    echo "build.config.default not found in current directory!"
    exit 1
fi

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"

# Create output directory
mkdir -p $KBUILD_OUTPUT

# Functions
function clean_all {
    rm -rf $AK2_DIR/$MODULES_DIR/*
    rm -f $AK2_DIR/$KERNEL
    rm -f $AK2_DIR/zImage
    echo
    make O=$KBUILD_OUTPUT clean && make O=$KBUILD_OUTPUT mrproper
}

function make_kernel {
    echo
    make $DEFCONFIG O=$KBUILD_OUTPUT 
    
    if [[ $CC = *clang* ]]; then
    # Clang
    echo
    echo "Building with Clang..."
    echo
    make $THREAD \
         ARCH=$ARCH \
	 CC="$CCACHE $CC" \
	 CLANG_TRIPLE=$CLANG_TRIPLE \
         CROSS_COMPILE="$CROSS_COMPILE" \
         KBUILD_BUILD_USER=$KBUILD_BUILD_USER \
         KBUILD_BUILD_HOST=$KBUILD_BUILD_HOST \
         LOCALVERSION=$LOCALVERSION \
         O=$KBUILD_OUTPUT
    else
    # GCC
    echo
    echo "Building with GCC..."
    echo
    make $THREAD \
         ARCH=$ARCH \
         CROSS_COMPILE="$CCACHE $CROSS_COMPILE" \
         KBUILD_BUILD_USER=$KBUILD_BUILD_USER \
         KBUILD_BUILD_HOST=$KBUILD_BUILD_HOST \
         LOCALVERSION=$LOCALVERSION \
         O=$KBUILD_OUTPUT
    fi
}

function make_modules {
    # Remove and re-create modules directory
    rm -rf $MODULES_DIR
    mkdir -p $MODULES_DIR/system/lib/modules
    mkdir -p $MODULES_DIR/system/vendor/lib/modules

    # Copy modules over
    echo
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
    cp -vr $ZIMAGE_DIR/$KERNEL $AK2_DIR/zImage
    pushd $AK2_DIR
    zip -r9 $KERNEL_ZIP.zip *
    mkdir -p $ZIP_MOVE
    mv $KERNEL_ZIP.zip $ZIP_MOVE
    popd
}

echo -e "${green}"
echo "Building $KERNEL_ZIP"
echo ""
echo "RenderZenith creation script:"
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
    y|Y )
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
    TIME_START=$(date +"%s")

    make_kernel

    TIME_END=$(date +"%s")
    DIFF=$(($TIME_END - $TIME_START))
    TIME_MSG="Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
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
while read -p "Do you want to ZIP kernel (y/n)? " dchoice
do
case "$dchoice" in
  y|Y)
    make_modules
    make_zip

    FILENAME_MSG="Filename: $KERNEL_ZIP.zip"
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

if [ ! -z ${TIME_MSG+x} ]; then
echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"
echo $TIME_MSG
echo
fi

if [ ! -z ${FILENAME_MSG+x} ]; then
echo $FILENAME_MSG 
echo
fi
