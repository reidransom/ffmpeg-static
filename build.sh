#!/bin/sh

set -x

usage()
{
cat << EOF
usage: $0 ffmpeg|libav|ffmbc

Build static binaries of ffmpeg or libav or ffmbc.

EOF
}

set -e
set -u

cd `dirname $0`
ENV_ROOT=`pwd`
. ./env.source

rm -rf "$BUILD_DIR" "$TARGET_DIR"
mkdir -p "$BUILD_DIR" "$TARGET_DIR"

FFGET=""
FFDIR=""
FFCONFIG="./configure --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --enable-cross-compile --arch=x86_64 --arch=i386 --target-os=`uname | awk '{print tolower($0)}'` --disable-ffplay --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-libvpx --enable-bzlib --enable-zlib --enable-nonfree --disable-devices --extra-libs=$TARGET_DIR/lib/libfaac.a --extra-libs=$TARGET_DIR/lib/libvorbis.a --extra-libs=$TARGET_DIR/lib/libxvidcore.a"

if [ "$1" == "ffmpeg" ] ; then
    FFGET="git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg-git"
    FFDIR="ffmpeg-git"
elif [ "$1" == "libav" ] ; then
    FFGET="../fetchurl http://libav.org/releases/libav-9.8.tar.gz"
    FFDIR="libav-9.8"
    FFCONFIG="./configure --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --enable-cross-compile --arch=x86_64 --arch=i386 --target-os=`uname | awk '{print tolower($0)}'` --disable-doc --enable-gpl --enable-pthreads --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-libvpx --enable-bzlib --enable-zlib --enable-nonfree --disable-devices --extra-libs=$TARGET_DIR/lib/libfaac.a --extra-libs=$TARGET_DIR/lib/libvorbis.a --extra-libs=$TARGET_DIR/lib/libxvidcore.a"
elif [ "$1" == "ffmbc" ] ; then
    FFGET="../fetchurl http://ffmbc.googlecode.com/files/FFmbc-0.7-rc8.tar.bz2"
    FFDIR="FFmbc-0.7-rc8"
else
    usage
    exit 1
fi

# NOTE: this is a fetchurl parameter, nothing to do with the current script
#export TARGET_DIR_DIR="$BUILD_DIR"

# TODO: Move git to fetchurl script, thus adding caching

echo "#### FFmpeg static build, by STVS SA ####"
cd $BUILD_DIR
../fetchurl "http://www.tortall.net/projects/yasm/releases/yasm-1.2.0.tar.gz"
../fetchurl "http://zlib.net/zlib-1.2.8.tar.gz"
../fetchurl "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
../fetchurl "http://downloads.sourceforge.net/project/libpng/libpng16/1.6.3/libpng-1.6.3.tar.gz"
../fetchurl "http://download.savannah.gnu.org/releases/freetype/freetype-2.5.0.1.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz"
../fetchurl "http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2"
#../fetchurl "http://webm.googlecode.com/files/libvpx-v1.1.0.tar.bz2"
git clone http://git.chromium.org/webm/libvpx.git libvpx-git
../fetchurl "http://downloads.sourceforge.net/project/faac/faac-src/faac-1.28/faac-1.28.tar.bz2"
../fetchurl "ftp://ftp.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-20130806-2245-stable.tar.bz2"
../fetchurl "http://downloads.xvid.org/downloads/xvidcore-1.3.2.tar.bz2"
../fetchurl "http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz"
$FFGET

echo "*** Building yasm ***"
cd "$BUILD_DIR/yasm-1.2.0"
./configure --prefix=$TARGET_DIR
make -j 4 && make install

echo "*** Building zlib ***"
cd "$BUILD_DIR/zlib-1.2.8"
./configure --prefix=$TARGET_DIR --static
make -j 4 && make install

echo "*** Building bzip2 ***"
cd "$BUILD_DIR/bzip2-1.0.6"
make
make install PREFIX=$TARGET_DIR

echo "*** Building libpng ***"
cd "$BUILD_DIR/libpng-1.6.3"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install

echo "** Building freetype **"
cd "$BUILD_DIR/freetype-2.5.0.1"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install

# Ogg before vorbis
echo "*** Building libogg ***"
cd "$BUILD_DIR/libogg-1.3.1"
./configure --prefix=$TARGET_DIR --build=x86_64 --enable-static --disable-shared
make -j 4 && make install

# Vorbis before theora
echo "*** Building libvorbis ***"
cd "$BUILD_DIR/libvorbis-1.3.3"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install

echo "*** Building libtheora ***"
cd "$BUILD_DIR/libtheora-1.1.1"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install

echo "*** Building livpx ***"
cd "$BUILD_DIR/libvpx-git"
./configure --prefix=$TARGET_DIR
make -j 4 && make install

echo "*** Building faac ***"
cd "$BUILD_DIR/faac-1.28"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
# FIXME: gcc incompatibility, does not work with log()
sed -i -e "s|^char \*strcasestr.*|//\0|" common/mp4v2/mpeg4ip.h
make -j 4 && make install

echo "*** Building x264 ***"
cd "$BUILD_DIR/x264-snapshot-20130806-2245-stable"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install


echo "*** Building xvidcore ***"
cd "$BUILD_DIR/xvidcore/build/generic"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install
#rm $TARGET_DIR/lib/libxvidcore.so.*

echo "*** Building lame ***"
cd "$BUILD_DIR/lame-3.99.5"
./configure --prefix=$TARGET_DIR --enable-static --disable-shared
make -j 4 && make install

# FIXME: only OS-sepcific
rm -f "$TARGET_DIR/lib/*.dylib"
rm -f "$TARGET_DIR/lib/*.so"

echo "*** Building $FFDIR ***"
cd "$BUILD_DIR/$FFDIR"
#./configure --prefix=${OUTPUT_DIR:-$TARGET_DIR} --extra-version=static --disable-debug --disable-shared --enable-static --extra-cflags=--static --enable-cross-compile --arch=x86_64 --arch=i386 --target-os=`uname | awk '{print tolower($0)}'` --disable-ffplay --disable-doc --enable-gpl --enable-pthreads --enable-postproc --enable-gray --enable-runtime-cpudetect --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libx264 --enable-libxvid --enable-libfreetype --enable-bzlib --enable-zlib --enable-nonfree --disable-devices --extra-libs=$TARGET_DIR/lib/libfaac.a --extra-libs=$TARGET_DIR/lib/libvorbis.a --extra-libs=$TARGET_DIR/lib/libxvidcore.a
$FFCONFIG
make -j 4 && make install
