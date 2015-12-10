# What is this?
# ===========================
#
# This is a Dockerfile used to build Basecamp REE for the legacy stuff that
# still uses it. It's pretty specific to Basecamp, for example the paths to
# Ruby, but it could easily be edited for your needs. If you can think of a
# good way of making it more generic and allowing for the paths, names etc.
# to be passed on the command line please submit a pull request!
#
# Contact Github:@wjessop or will@willj.net for more details
#
# Usage
# ===========================
#
# 1. Install Docker
#
# On Linux: use your package manager.
#
# On a mac: Install https://www.docker.com/docker-toolbox and run
#
# docker-machine create --driver virtualbox default
# eval "$(docker-machine env default)"
#
# This lets the docker command interact with a copy of linux that can actually
# run docker. See http://docs.docker.com/engine/installation/mac/ for more
# details.
#
# 2. Build
#
#     $ docker build --rm=true --no-cache=true .
#
# 3. Find the result image
#
# Look for the last line:
#
#     Successfully built 571f4315d3e9
#
# 4. Copy the files out
#
# Poke this value into the following command:
#
# docker run -i -v ${PWD}/tmp/:/tmp/package 571f4315d3e9 <<COMMANDS
# cp /tmp/ruby/ruby-ree-1.8.7-2015.04_1.8.7-2015.04-37s~trusty_amd64.deb /tmp/package/
# cp /tmp/rubygems/rubygems-ree_1.8.30-2015.04-37s~trusty_amd64.deb /tmp/package/
# COMMANDS
#
# You should see your packages magically appear in the tmp dir:
#
# $ ls -l tmp/
# total 5032
# -rw-r--r--  1 mkent  staff  2443070  9 Dec 15:37 ruby-ree-1.8.7-2015.04_1.8.7-2015.04-37s~trusty_amd64.deb
# -rw-r--r--  1 mkent  staff   127506  9 Dec 15:37 rubygems-ree_1.8.30-2015.04-37s~trusty_amd64.deb
#
# Building for Precise or Lucid
# ===========================
#
# Same as above, but specify the precise or lucid Dockerfile for the build
# command:
#
#     docker build --rm=true --no-cache=true -f Dockerfile.lucid .
#

FROM ubuntu:14.04
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y bison autoconf build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev checkinstall git

# Make and install Ruby
ADD . /tmp/ruby/
WORKDIR /tmp/ruby/
RUN for i in `cat debian/patches/series`; do patch -p1 < debian/patches/$i; done
RUN autoconf
# CFLAGS to fix segfaults per
# https://github.com/rbenv/ruby-build/wiki#187-p302-and-lower-segfaults-for-https-requests-on-os-x-107
RUN ./configure --prefix=/opt/rubyree-1.8.7-2015.04 --enable-pthread CFLAGS="-O2 -fno-tree-dce -fno-optimize-sibling-calls"
RUN make
RUN checkinstall --nodoc --type=debian --pkgname=ruby-ree-1.8.7-2015.04 --pkgversion=1.8.7-2015.04 --pkgrelease=37s~trusty --arch=amd64 --requires=libstdc++6,libc6,libffi6,libgdbm3,libncurses5,libreadline6,libssl1.0.0,zlib1g

# Next up, Rubygems
WORKDIR /tmp
RUN git clone https://github.com/rubygems/rubygems.git
WORKDIR /tmp/rubygems
RUN git fetch --tags
RUN git checkout tags/v1.8.30
RUN checkinstall --nodoc --type=debian --pkgname=rubygems-ree --pkgversion=1.8.30-2015.04 --pkgrelease=37s~trusty --arch=amd64 /opt/rubyree-1.8.7-2015.04/bin/ruby setup.rb
