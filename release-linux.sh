#!/bin/sh
# WARNING: This script might only work with the authors setup...

set -ex

svnclean

qmake
make

rm -rf release
mkdir -p release/{bin,lib/openscad}

cat > release/bin/openscad << "EOT"
#!/bin/bash

cd "$( dirname "$( type -p $0 )" )"
libdir=$PWD/../lib/openscad/
cd "$OLDPWD"

export LD_LIBRARY_PATH="$libdir${LD_LIBRARY_PATH:+:}$LD_LIBRARY_PATH"
exec $libdir/openscad "$@"
EOT

cp openscad release/lib/openscad/
gcc -o chrpath_linux chrpath_linux.c
./chrpath_linux -d release/lib/openscad/openscad

ldd openscad | sed -r 's,.* => ,,; s,[\t ].*,,; /./ ! d; /libGLcore/ d; /libnvidia/ d;' | xargs cp -vt release/lib/openscad/
strip release/lib/openscad/*

cat > release/install.sh << "EOT"
#!/bin/bash

# change to the install source directory
cd "$( dirname "$( type -p $0 )" )"

if ! [ -f bin/openscad -a -d lib/openscad -a -d examples ]; then
	echo "Error: Can't change to install source directory!" >&2
	exit 1
fi

echo "This will install openscad. Please enter the install prefix"
echo "or press Ctrl-C to abort the install process:"
read -p "[/usr/local]: " prefix

if [ "$prefix" = "" ]; then
	prefix="/usr/local"
fi

if [ ! -d "$prefix" ]; then
	echo; echo "Install prefix \`$prefix' does not exist. Press ENTER to continue"
	echo "or press Ctrl-C to abort the install process:"
	read -p "press enter to continue> "
fi

mkdir -p "$prefix"/{bin,lib/openscad}

if ! [ -w "$prefix"/bin/ -a -w "$prefix"/lib/ ]; then
	echo "You does not seam to have write permissions for prefix \`$prefix'!" >&2
	echo "Maybe you should have run this install script using \`sudo'?" >&2
	exit 1
fi

echo "Copying application wrappers..."
cp -rv bin/. "$prefix"/bin/

echo "Copying application and libraries..."
cp -rv lib/. "$prefix"/lib/

echo "Installation finished. Have a nice day."
EOT

chmod 755 -R release/

cp -r examples release/
chmod 644 -R release/examples/*
