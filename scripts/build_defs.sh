#
# build_defs.mk (current: defs.mk)
#   functions use by steps !
#     remove package_XXX detection and move to 'package_defs.mk' 

if [ -z "$OSTYPE" ] ; then
    OSTYPE=`uname`
fi 

#
# all defaults
#
CC=${CC-gcc}
CXX=${CXX-g++}

export CC CFLAGS
export CXX CXXFLAGS

def_dist_name="$(uname -s | tr A-Z a-z)-$(uname -m)"
def_prefix=/usr

TAR=tar
PATCH=patch
MAKE=make
PYTHON=python

#
# custom platforms
#

case "$OSTYPE" in
    *solaris*)
        TAR=gtar
        PATCH=gpatch
	MAKE=gmake
        ;;
    *freebsd*|*FreeBSD*)
        MAKE=gmake
        C_INCLUDE_PATH=$C_INCLUDE_PATH:/usr/local/include
        CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/usr/local/include
        LIBRARY_PATH=$LIBRARY_PATH:/usr/local/lib
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib	
        export C_INCLUDE_PATH CPLUS_INCLUDE_PATH
	;;
    *msys*|MINGW*)
        def_prefix=/mingw
        def_dist_name="mingw-$(uname -m)"
        ;;
    *darwin*)
        is_macosx=1
    	;;
esac

#
# 
#

stereotype="${stereotype-auto}"

#
# archiecture
#

config_guess()
{
    sh ${portz_scripts}/config.guess
}

addpath() {
        local name=$1 ; shift
        eval "current=\"\$$name\""
        if [ -z "$current" ] ; then
                D=""
        else
                D=":"
        fi
        for path in $* ; do
                if [ -d $path ] ; then
                        current="${path}${D}${current}"
                        D=":"
                fi
        done
        eval "$name=\"$current\""
        export $name

        unset name first current D
}


current_arch=$(config_guess)

#
# site
#
if [ -n "$site" ] ; then
	#echo "$0: using site settings from $site"
	prefix="$site"
	exec_prefix="${prefix}"

	# other defaults
        addpath LIBRARY_PATH       $site/lib
        addpath PKG_CONFIG_PATH    $site/lib/pkgconfig
	
	# noarch paths
        addpath C_INCLUDE_PATH     $base/include
        addpath CPLUS_INCLUDE_PATH $base/include
        addpath MANPATH            $base/share/man
        addpath PYTHONPATH         $base/lib/python{2.3,2.4,2.5,2.6,2.7,3.0}/site-packages

	PORTZ_SEPARATE_EXEC=0
	if [ -f "$site/.portz.conf" ] ; then
		. "$site/.portz.conf"
	fi

	if [ -z "$arch" -o "$current_arch" = "$arch" ] ; then
		addpath PATH $site/bin
		addpath LD_LIBRARY_PATH $site/lib
	fi
fi

target_arch=${arch-$current_arch}

if [ "$current_arch" != "$target_arch" ] ; then
        PORTZ_SEPARATE_EXEC=${PORTZ_SEPARATE_EXEC-1}
fi

#
# prefix and exec_prefix 
# 
prefix=${prefix-$def_prefix}

if test "x$PORTZ_SEPARATE_EXEC" = "x1"
then
    def_exec_prefix=${prefix}/platforms/${target_arch}
else
    def_exec_prefix=${prefix}
fi

exec_prefix=${exec_prefix-$def_exec_prefix}

export prefix exec_prefix

inform "prefix      = $prefix"
inform "exec_prefix = $exec_prefix"

if [ -z "${dist_name}" ]; then
    dist_name="${def_dist_name}"
fi

#
# now when arch & directories are known,
# prepare default C/C++ compile and linking flags
#
#

C_INCLUDE_PATH="${prefix}/include:$C_INCLUDE_PATH"
CPLUS_INCLUDE_PATH="${prefix}/include:$CPLUS_INCLUDE_PATH"
LD_LIBRARY_PATH="${exec_prefix}/lib:$CPLUS_INCLUDE_PATH"
PKG_CONFIG_PATH="${exec_prefix}/lib/pkgconfig:${prefix}/lib/pkgconfig:$PKG_CONFIG_PATH"

export C_INCLUDE_PATH CPLUS_INCLUDE_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH

if [ "$current_arch" != "$target_arch" ] ; then
        cross_configure_options="--host=$target_arch"
        case $target_arch in
            *i*86-*linux*)
                CROSS_CFLAGS="-m32"
                CROSS_CXXFLAGS="-m32"
                CROSS_LDFLAGS="-m32"
                ;;
            x86_64*linux*)
                CROSS_CFLAGS="-m64"
                CROSS_CXXFLAGS="-m64"
                CROSS_LDFLAGS="-m64"
                ;;
            default)
                # no universal special handling
                true
                ;;
        esac
        
        CROSS_CC=${target_arch}-cc
        CROSS_CXX=${target_arch}-c++
        
        if which $CROSS_CC > /dev/null; then
            CC=$CROSS_CC
            export CC
        fi
        if which $CROSS_CXX > /dev/null ; then
            CXX=$CROSS_CXX
            export CXX
        fi 
fi

STD_CFLAGS="${CFLAGS--g -O2}"
STD_CXXFLAGS="${CXXFLAGS--g -O2}"
STD_LDFLAGS="${LDFLAGS--g}"

CFLAGS="$STD_CFLAGS $CROSS_CFLAGS"
CXXFLAGS="$STD_CXXFLAGS $CROSS_CXXFLAGS"
LDFLAGS="$STD_LDFLAGS $CROSS_LDFLAGS"

export CFLAGS CXXFLAGS LDFLAGS

#
# dist platform suffix
#
dist_suffix="-${dist_name}"

#
# detect cpu count
#   TODO: move to  separate script
#
if [ -f /proc/cpuinfo ] ; then
    cpus=$(cat /proc/cpuinfo | egrep "^processor" | wc -l)
elif [ -n "$NUMBER_OF_PROCESSORS" ] ; then
    cpus=$NUMBER_OF_PROCESSORS
elif [ -n "$is_macosx" ] ; then
    cpus="$(sysctl -n hw.ncpu)"
else
    cpus=1
fi
log_info "detected cpu/core count: $cpus"

portz_make_parallel()
{
    ${MAKE} -j$cpus "$@"
}

MAKE_PARALLEL="${MAKE} -j$cpus"

if [ -z "${TMP}" ] ; then
    TMP="${TEMP-/tmp}"
fi
