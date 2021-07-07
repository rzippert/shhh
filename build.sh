#!/bin/bash
PKGNAME="shhh"
PKGROOT="pkgroot"
DEPS=("bash" "ffmpeg" "yad" "expect")
FEEDBACKMAIL="automail_shhh@zppr.tk"
#DEPS="bash, ffmpeg, yad, expect"

while getopts ":v:f" opt; do
  case ${opt} in
    f )
      FORCE="-f "
      ;;
    v )
      VERSION=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done

if [[ -z $VERSION ]]
then
	echo "Please, set a version with -v." 1>&2
	exit 127
fi

# check fpm
type -P "fpm" 2>&1 > /dev/null || { echo "fpm is required."; exit 1; }

# recompile the binary
shc -f shhh.sh -r -m $FEEDBACKMAIL
sudo rm shhh.sh.x.c
sudo cp shhh.sh.x $PKGROOT/usr/bin/shhh
sudo rm shhh.sh.x

# create .deb

#fpm -s dir -t deb "$FORCE"-n $PKGNAME -v "$VERSION" -d "$DEPS" --chdir "$PKGROOT" usr
echo fpm -s dir -t deb "$FORCE"-n $PKGNAME -v "$VERSION" $(for DEP in ${DEPS[@]}; do echo "-d $DEP "; done) --chdir "$PKGROOT" usr
fpm -s dir -t deb "$FORCE"-n $PKGNAME -v "$VERSION" $(for DEP in ${DEPS[@]}; do echo "-d $DEP "; done) --chdir "$PKGROOT" usr
#fpm -s dir -t pacman "$FORCE"-n $PKGNAME -v "$VERSION" -d "$DEPS" --chdir "$PKGROOT" usr

# create arch pkg
echo fpm -s dir -t pacman "$FORCE"-n $PKGNAME -v "$VERSION" $(for DEP in ${DEPS[2]}; do echo "-d $DEP "; done) --chdir "$PKGROOT" usr
fpm -s dir -t pacman "$FORCE"-n $PKGNAME -v "$VERSION" $(for DEP in ${DEPS[2]}; do echo "-d $DEP "; done) --chdir "$PKGROOT" usr

# move packages to build folder
mv *.deb *.tar.xz build 2> /dev/null
