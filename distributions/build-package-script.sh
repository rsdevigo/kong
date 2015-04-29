#!/bin/bash

# Create "pkg": wget https://raw.githubusercontent.com/Mashape/kong/master/versions.sh --no-check-certificate && wget -O - https://raw.githubusercontent.com/Mashape/kong/master/package-build.sh --no-check-certificate | /bin/bash
# Create "rpm": docker run centos:5 /bin/bash -c "yum -y install wget && wget https://raw.githubusercontent.com/Mashape/kong/master/versions.sh --no-check-certificate && wget -O - https://raw.githubusercontent.com/Mashape/kong/master/package-build.sh --no-check-certificate | /bin/bash"
# Create "deb": docker run debian:6 /bin/bash -c "apt-get update && apt-get -y install wget && wget https://raw.githubusercontent.com/Mashape/kong/master/versions.sh --no-check-certificate && wget -O - https://raw.githubusercontent.com/Mashape/kong/master/package-build.sh --no-check-certificate | /bin/bash"

# docker run -v $(pwd)/:/build-data centos:5 /bin/bash -c "/build-data/package-build.sh"

set -o errexit

# Preparing environment
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "Current directory is: "$DIR
if [ "$DIR" == "/" ]; then
  DIR=""
fi
OUT=/tmp/build/out
TMP=/tmp/build/tmp
echo "Cleaning directories"
rm -rf $OUT
rm -rf $TMP
echo "Preparing environment"
mkdir -p $OUT
mkdir -p $TMP

# Load dependencies versions
source $DIR/../versions.sh

# Variables to be used in the build process
PACKAGE_TYPE=""
MKTEMP_LUAROCKS_CONF=""
MKTEMP_POSTSCRIPT_CONF=""
LUA_MAKE=""
OPENRESTY_CONFIGURE=""
LUAROCKS_CONFIGURE=""
FPM_PARAMS=""
FINAL_FILE_NAME=""

FINAL_BUILD_OUTPUT="/build-data/build-output"

if [ "$(uname)" = "Darwin" ]; then
  brew install gpg
  brew install ruby

  PACKAGE_TYPE="osxpkg"
  LUA_MAKE="macosx"
  MKTEMP_LUAROCKS_CONF="-t rocks_config.lua"
  MKTEMP_POSTSCRIPT_CONF="-t post_install_script.sh"
  FPM_PARAMS="--osxpkg-identifier-prefix org.kong"
  FINAL_FILE_NAME="kong-$KONG_VERSION.pkg"

  FINAL_BUILD_OUTPUT="$DIR/build-output"
elif hash yum 2>/dev/null; then
  yum -y install epel-release
  yum -y install wget tar make curl ldconfig gcc perl pcre-devel openssl-devel ldconfig unzip git rpm-build ncurses-devel which lua-$LUA_VERSION lua-devel-$LUA_VERSION gpg

  CENTOS_VERSION=`cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+'`

  # Install Ruby for fpm
  if [[ ${CENTOS_VERSION%.*} == "5" ]]; then
    cd $TMP
    wget http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.2.tar.gz
    tar xvfvz ruby-2.2.2.tar.gz
    cd ruby-2.2.2
    ./configure
    make
    make install
    gem update --system
  else
    yum -y install ruby ruby-devel rubygems
  fi

  PACKAGE_TYPE="rpm"
  LUA_MAKE="linux"
  FPM_PARAMS="-d epel-release -d sudo -d nc -d 'lua = $LUA_VERSION' -d openssl -d pcre -d openssl098e"
  FINAL_FILE_NAME="kong-${KONG_VERSION/-/_}.el${CENTOS_VERSION%.*}.noarch.rpm"
elif hash apt-get 2>/dev/null; then
  apt-get update && apt-get -y install wget curl gnupg tar make gcc libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl unzip git lua${LUA_VERSION%.*} liblua${LUA_VERSION%.*}-0-dev lsb-release ruby ruby-dev

  DEBIAN_VERSION=`lsb_release -cs`
  if ! [[ "$DEBIAN_VERSION" == "trusty" ]]; then
    apt-get -y install rubygems
  fi

  PACKAGE_TYPE="deb"
  LUA_MAKE="linux"
  FPM_PARAMS="-d netcat -d sudo -d lua5.1 -d openssl -d libpcre3"
  FINAL_FILE_NAME="kong-$KONG_VERSION.${DEBIAN_VERSION}_all.deb"
else
  echo "Unsupported platform"
  exit 1
fi

export PATH=$PATH:${OUT}/usr/local/bin:$(gem environment | awk -F': *' '/EXECUTABLE DIRECTORY/ {print $2}')

# Install fpm
gem install fpm

##############################################################
# Starting building software (to be included in the package) #
##############################################################

if [ "$(uname)" = "Darwin" ]; then
  # Install PCRE
  cd $TMP
  wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-$PCRE_VERSION.tar.gz
  tar xzf pcre-$PCRE_VERSION.tar.gz
  cd pcre-$PCRE_VERSION
  ./configure
  make
  make install DESTDIR=$OUT
  cd $OUT

  # Install Lua
  cd $TMP
  wget http://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz
  tar xzf lua-$LUA_VERSION.tar.gz
  cd lua-$LUA_VERSION
  make $LUA_MAKE
  make install INSTALL_TOP=$OUT/usr/local
  cd $OUT

  LUAROCKS_CONFIGURE="--with-lua-include=$OUT/usr/local/include"
  OPENRESTY_CONFIGURE="--with-cc-opt=-I$OUT/usr/local/include --with-ld-opt=-L$OUT/usr/local/lib"
fi

# Install OpenResty
cd $TMP
wget http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz
tar xzf ngx_openresty-$OPENRESTY_VERSION.tar.gz
cd ngx_openresty-$OPENRESTY_VERSION
./configure --with-pcre-jit --with-ipv6 --with-http_realip_module --with-http_ssl_module --with-http_stub_status_module ${OPENRESTY_CONFIGURE}
make
make install DESTDIR=$OUT
cd $OUT

# Install LuaRocks
cd $TMP
wget http://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz
tar xzf luarocks-$LUAROCKS_VERSION.tar.gz
cd luarocks-$LUAROCKS_VERSION
./configure $LUAROCKS_CONFIGURE
make build
make install DESTDIR=$OUT
cd $OUT

# Configure LuaRocks
rocks_config=$(mktemp $MKTEMP_LUAROCKS_CONF)
echo "
rocks_trees = {
   { name = [[system]], root = [[${OUT}/usr/local]] }
}
" > $rocks_config
export LUAROCKS_CONFIG=$rocks_config
export LUA_PATH=${OUT}/usr/local/share/lua/5.1/?.lua

# Install Kong
$OUT/usr/local/bin/luarocks install kong $KONG_VERSION

# Fix the Kong bin file
sed -i.bak s@${OUT}@@g $OUT/usr/local/bin/kong
rm $OUT/usr/local/bin/kong.bak

# Copy the conf to /etc/kong
post_install_script=$(mktemp $MKTEMP_POSTSCRIPT_CONF)
echo "#!/bin/sh
sudo mkdir -p /etc/kong
sudo cp /usr/local/lib/luarocks/rocks/kong/$KONG_VERSION/conf/kong.yml /etc/kong/kong.yml" > $post_install_script

##############################################################
#                      Build the package                     #
##############################################################

# Execute fpm
cd $OUT
eval "fpm -a all -f -s dir -t $PACKAGE_TYPE -n 'kong' -v $KONG_VERSION $FPM_PARAMS \
--iteration 1 \
--description 'Kong is an open distributed platform for your APIs, focused on high performance and reliability.' \
--vendor Mashape \
--license MIT \
--url http://getkong.org/ \
--after-install $post_install_script \
usr"

# Copy file to host
mkdir -p $FINAL_BUILD_OUTPUT
cp $(find $OUT -maxdepth 1 -type f -name "kong*.*" | head -1) $FINAL_BUILD_OUTPUT/$FINAL_FILE_NAME

echo "DONE"