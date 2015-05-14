### LINUX ATOMIC ###
_build_atomic() {
# source: http://vincesoft.blogspot.com.br/2012/04/how-to-solve-undefined-reference-to.html
local FOLDER="linux-atomic"

rm -vfR "target/${FOLDER}"
mkdir -p "target/${FOLDER}"
pushd "target/${FOLDER}"
wget -O linux-atomic.c "https://github.com/gcc-mirror/gcc/raw/gcc-4_7_0-release/libgcc/config/arm/linux-atomic.c"
libtool --tag=CC --mode=compile "${CC}" ${CFLAGS} -g -MT linux-atomic.lo -MD -MP -MF linux-atomic.Tpo -c -o linux-atomic.lo linux-atomic.c
libtool --tag=CC --mode=link "${CC}" ${LDFLAGS} -g -Os -o liblinux-atomic.la linux-atomic.lo

mkdir -p "${DEPS}/lib"
cp -va liblinux-atomic.la "${DEPS}/lib/"
cp -va .libs/liblinux-atomic.a "${DEPS}/lib/"
popd
}

### LINUX ATOMIC64 ###
_build_atomic64() {
# source: http://vincesoft.blogspot.com.br/2012/04/how-to-solve-undefined-reference-to.html
local FOLDER="linux-atomic-64bit"

rm -vfR "target/${FOLDER}"
mkdir -p "target/${FOLDER}"
pushd "target/${FOLDER}"
wget -O linux-atomic-64bit.c "https://github.com/gcc-mirror/gcc/raw/gcc-4_7_0-release/libgcc/config/arm/linux-atomic-64bit.c"
libtool --tag=CC --mode=compile "${CC}" ${CFLAGS} -g -MT linux-atomic-64bit.lo -MD -MP -MF linux-atomic-64bit.Tpo -c -o linux-atomic-64bit.lo linux-atomic-64bit.c
libtool --tag=CC --mode=link "${CC}" ${LDFLAGS} -g -Os -o liblinux-atomic-64bit.la linux-atomic-64bit.lo

mkdir -p "${DEPS}/lib"
cp -va liblinux-atomic-64bit.la "${DEPS}/lib/"
cp -va .libs/liblinux-atomic-64bit.a "${DEPS}/lib/"
popd
}

### SCONS ###
_check_scons() {
  if [ ! -x /usr/bin/scons ]; then
    sudo apt-get install scons
  fi
}

### MONGODB ###
_build_mongodb() {
# These steps build a simplified version of mongodb, which has the following restrictions:
# 1) There is no javascript support; currently V8 does not support cross-compilation to ARM.
# 2) There is no wiredtiger support; wiredtiger is also not cross-compile friendly.
# 3) The only target built is mongod; everything else is untested.
#    In particular, the boost lib used in mongo shell is known to trigger a bug in GCC 4.4.
# 4) Since mongodb requires 64-bit atomic builtins, we borrow those from GCC 4.7.0.
#    That workaround works, but has not been extensively tested.
# The compilation uses distcc and ccache.
local VERSION="3.0.2"
local FOLDER="mongodb-src-r${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://fastdl.mongodb.org/src/${FILE}"
local CACHE_DIR="$PWD/target/cache"

mkdir -p "${CACHE_DIR}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf src/linux-atomic.c "target/${FOLDER}/src/mongo/"
cp -vf src/linux-atomic-64bit.c "target/${FOLDER}/src/mongo/"
cp -vf src/SConscript-atomic.patch "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch src/mongo/SConscript SConscript-atomic.patch

#sed -e "s/V8_TARGET_ARCH_IA32/V8_TARGET_ARCH_ARM/g" -i src/third_party/v8/SConscript
#sed -e "s/V8_TARGET_ARCH_IA32/V8_TARGET_ARCH_ARM/g" -i src/third_party/v8-3.25/SConscript

#export DISTCC_LOG="$PWD/distcc.log"
eval `distcc-pump --startup`
scons --jobs=16 --prefix="${DEST}" \
  --propagate-shell-environment --cc-use-shell-environment --cxx-use-shell-environment \
  --disable-minimum-compiler-version-enforcement --disable-warnings-as-errors \
  --dbg=off --opt=on --nostrip --debug={explain,findlibs,includes,prepare,presub,stacktrace} \
  --noshell --js-engine=none --wiredtiger=off mongod \
  --cache --cache-dir="${CACHE_DIR}" --distcc \
  CCFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections" \
  CXXFLAGS="${CXXFLAGS:-} -ffunction-sections -fdata-sections" \
  LINKFLAGS="${LDFLAGS:-} -Wl,--gc-sections"
distcc-pump --shutdown
mkdir -p "${DEST}/bin"
cp -v build/cached/mongo/mongod "${DEST}/bin/"
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/bin/mongod"
popd
}

_build() {
#  _build_atomic
#  _build_atomic64
  _check_scons
  _build_mongodb
  _package
}
