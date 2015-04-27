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
# On Linux use your package manager, on a mac: http://boot2docker.io/
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
# cp /tmp/ruby/ruby-ree-1.8.7-2015.04_1.8.7-2015.04-37s~precise_amd64.deb /tmp/package/
# cp /tmp/rubygems/rubygems-ree_1.8.30-2015.04-37s~precise_amd64.deb /tmp/package/
# COMMANDS
#
# You should see your packages magically appear in the tmp dir:
#
# $ ls -l tmp/
# total 6288
# -rw-r--r--  1 will  staff  3061900 21 Apr 00:00 ruby-ree-1.8.7-2015.04_1.8.7-2015.04-37s~precise_amd64.deb
# -rw-r--r--  1 will  staff   155290 21 Apr 00:00 rubygems-ree_1.8.30-2015.04-37s~precise_amd64.deb
#
# Building for Lucid
# ===========================
#
# Same as above, but specify the lucid Dockerfile for the build command
#
#     docker build --rm=true --no-cache=true -f Dockerfile.lucid .
#
# ToDo
# ===========================
#
# * Deps for packages

FROM ubuntu:12.04
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y bison autoconf build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm3 libgdbm-dev checkinstall git

# Make and install Ruby
ADD . /tmp/ruby/
WORKDIR /tmp/ruby/
RUN for i in `cat debian/patches/series`; do patch -p1 < debian/patches/$i; done
RUN autoconf
RUN ./configure --prefix=/opt/rubyree-1.8.7-2015.04
RUN make
RUN checkinstall --nodoc --type=debian --pkgname=ruby-ree-1.8.7-2015.04 --pkgversion=1.8.7-2015.04 --pkgrelease=37s~precise --arch=amd64

# Next up, Rubygems
WORKDIR /tmp
RUN git clone https://github.com/rubygems/rubygems.git
WORKDIR /tmp/rubygems
RUN git fetch --tags
RUN git checkout tags/v1.8.30
RUN checkinstall --nodoc --type=debian --pkgname=rubygems-ree --pkgversion=1.8.30-2015.04 --pkgrelease=37s~precise --arch=amd64 /opt/rubyree-1.8.7-2015.04/bin/ruby setup.rb
