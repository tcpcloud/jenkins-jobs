#!/bin/bash -xe
# When building in parallel, scons dependency cycles occurs
#JOBS_COUNT=${JOBS_COUNT:-$(cat /proc/cpuinfo | grep -c processor || echo 1)}
#export DEB_BUILD_OPTIONS="parallel=${JOBS_COUNT}"

export COMPONENTS="main security tcp extra"
for i in *.dsc; do
    pkgname=$(echo $i|cut -d "_" -f 1)
    [ ! -d $pkgname ] && mkdir $pkgname
    mv ${pkgname}_*.gz ${pkgname}_*.dsc ${pkgname}/
    cd $pkgname
    export WORKSPACE=$(pwd)
    /usr/bin/build-and-provide-package
    cd ..
done
export WORKSPACE=$(pwd)
