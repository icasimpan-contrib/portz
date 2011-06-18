#!/usr/bin/env bash

# fetch and unarchive

. ${portz_root}/scripts/fetch_src.sh

# find dirs

src_dir=$(portz_step ${TMP}/portz/${package}/src find_src_dir)
inform src_dir="$src_dir"

bld_dir=$(portz_step ${src_dir} find_bld_dir)
inform bld_dir="$bld_dir"

export src_dir bld_dir

if [ "$stereotype" = "auto" ] ; then
	inform "detecting stereotype"
	if [ -f "${src_dir}/configure" ] ; then
		inform "stereotype=gnu"
		export stereotype=gnu
	else
		inform "unknown stereotype, assuming make works"
	fi
fi
# preparation

portz_optional_step ${src_dir} patch
portz_optional_step ${bld_dir} configure
portz_optional_step ${bld_dir} patch_after_conf

# build
portz_step ${bld_dir} build

# and staging install
rm -rf ${staging_dir}
portz_step ${bld_dir} install_staging 

# update manifest

portz_step ${staging_dir} make_manifest

