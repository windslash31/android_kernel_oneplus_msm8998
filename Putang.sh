#

#Custom Build Script

#
# Copyright © 2016, "Pavu(ZaMaSu)" <pravinchaudharyn@gmail.com>

# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it

# Init Script
KERNEL_DIR=$PWD
KERNEL="Image.gz-dtb"
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
BASE_VER="Putang-EAS"
VER="-v0-$(date +"%Y-%m-%d"-%H%M)-"
BUILD_START=$(date +"%s")
ANYKERNEL_DIR=/home/android/Downloads/Putang/
ANYKERNEL_DIR_CUSTOM=/home/android/Downloads/Putang-Op/kernels/custom/
EXPORT_DIR=/home/android/Desktop/zips/

# Change every build
ZIP_NAME="Putangnized-0.2"

# Color Code Script
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
nocol='\033[0m'         # Default

# Tweakable Options Below
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="EAS"
export KBUILD_BUILD_HOST="Wind"
export CROSS_COMPILE="/home/android/Desktop/linaro/bin/aarch64-linux-gnu-"
export KBUILD_COMPILER_STRING=$(/home/android/Desktop/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Branding

echo "                                         "
echo " ______ _   _ _____ ___   _   _ _____    "
echo " | ___ \ | | |_   _/ _ \ | \ | |  __ \   "
echo " | |_/ / | | | | |/ /_\ \|  \| | |  \/   "
echo " | |   | |_| | | || | | || |\  | |_\ \   "
echo " \_|    \___/  \_/\_| |_/\_| \_/\____/   "
echo "                                         "


# Compilation Scripts Are Below
echo -e "${Green}"
echo "-----------------------------------------------"
echo "  Initializing build to compile Ver: $VER    "
echo "-----------------------------------------------"

echo -e "$Yellow***********************************************"
echo "         Creating Output Directory: out      "
echo -e "***********************************************$nocol"

mkdir -p out

echo -e "$Yellow***********************************************"
echo "          Cleaning Up Before Compile          "
echo -e "***********************************************$nocol"

make O=out clean 
make O=out mrproper

echo -e "$Yellow***********************************************"
echo "          Initialising DEFCONFIG        "
echo -e "***********************************************$nocol"

make O=out ARCH=arm64 oneplus5_defconfig

echo -e "$Yellow***********************************************"
echo "          Cooking Putang, Grab a coke!!        "
echo -e "***********************************************$nocol"

make -j$(nproc --all) O=out ARCH=arm64 \
		              CC="/home/android/Desktop/clang/bin/clang" \
                      CLANG_TRIPLE="/home/android/Desktop/linaro/bin/aarch64-linux-gnu-"

# If the above was successful
if [ -a $KERN_IMG ]; then
   BUILD_RESULT_STRING="BUILD SUCCESSFUL"

echo -e "$Purple***********************************************"
echo "       Making Flashable Zip       "
echo -e "***********************************************$nocol"
   # Make the zip file
   echo "MAKING FLASHABLE ZIP"

   cp -vr ${KERN_IMG} ${ANYKERNEL_DIR_CUSTOM} 
   cd ${ANYKERNEL_DIR}
   zip -r9 ${ZIP_NAME}.zip * -x README ${ZIP_NAME}.zip

else
   BUILD_RESULT_STRING="BUILD FAILED"
fi

NOW=$(date +"%m-%d")
ZIP_LOCATION=${ANYKERNEL_DIR}/${ZIP_NAME}.zip
ZIP_EXPORT=${EXPORT_DIR}/${NOW}
ZIP_EXPORT_LOCATION=${EXPORT_DIR}/${NOW}/${ZIP_NAME}.zip

rm -rf ${ZIP_EXPORT}
mkdir ${ZIP_EXPORT}
mv ${ZIP_LOCATION} ${ZIP_EXPORT}
cd ${HOME}

# End the script
echo "${BUILD_RESULT_STRING}!"

# BUILD TIME
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$Yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
