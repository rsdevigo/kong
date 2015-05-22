#!/bin/bash

set -o errexit

##############################################################
# Make sure you have the dependencies for building OpenResty #
##############################################################

BUILD_DIR=/tmp
OPENRESTY_VERSION=1.7.10.2rc0
OPENSSL_VERSION=1.0.2a
OPENRESTY_BASE=ngx_openresty-$OPENRESTY_VERSION
OPENSSL_BASE=openssl-$OPENSSL_VERSION

cd $BUILD_DIR

# Download OpenSSL
wget https://www.openssl.org/source/$OPENSSL_BASE.tar.gz -O $OPENSSL_BASE.tar.gz
tar xzf $OPENSSL_BASE.tar.gz
OPENRESTY_CONFIGURE_PARAMS="--with-openssl=$BUILD_DIR/$OPENSSL_BASE"
if [ "$(uname)" = "Darwin" ]; then # Checking if OS X
  OPENRESTY_CONFIGURE_PARAMS=$OPENRESTY_CONFIGURE_PARAMS" --with-cc-opt=-I/usr/local/include --with-ld-opt=-L/usr/local/lib"
  export KERNEL_BITS=64 # This sets the right OpenSSL variable for OS X
fi

# Download OpenResty
curl http://openresty.org/download/$OPENRESTY_BASE.tar.gz | tar xz

# Download and apply nginx patch
cd $OPENRESTY_BASE/bundle/nginx-*
wget https://raw.githubusercontent.com/openresty/lua-nginx-module/ssl-cert-by-lua/patches/nginx-ssl-cert.patch --no-check-certificate
patch -p1 < nginx-ssl-cert.patch
cd ..

# Download `ssl-cert-by-lua` branch
wget https://github.com/openresty/lua-nginx-module/archive/ssl-cert-by-lua.tar.gz -O ssl-cert-by-lua.tar.gz --no-check-certificate
tar xzf ssl-cert-by-lua.tar.gz

# Replace `ngx_lua-*` with `ssl-cert-by-lua` branch
NGX_LUA=`ls | grep ngx_lua-*`
rm -rf $NGX_LUA
mv lua-nginx-module-ssl-cert-by-lua $NGX_LUA

# Install ssl.lua
cd $NGX_LUA/lua
echo '
package = "ngxssl"
version = "0.1-1"
source = {
  url = "git://github.com/openresty/lua-nginx-module",
  branch = "ssl-cert-by-lua"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["ngx.ssl"] = "ngx/ssl.lua"
  }
}
' > ngxssl-0.1-1.rockspec
sudo luarocks make ngxssl-0.1-1.rockspec

# Install OpenResty
cd $BUILD_DIR/$OPENRESTY_BASE
./configure --with-pcre-jit --with-ipv6 --with-http_realip_module --with-http_ssl_module --with-http_stub_status_module $OPENRESTY_CONFIGURE_PARAMS
make && sudo make install
cd $BUILD_DIR
rm -rf $OPENRESTY_BASE
rm -rf $OPENSSL_BASE
