


fail()
{
    log_error "$@"
    exit 1
}

inform()
{
    log_info "$@"
}

realpath()
(
    if [ -d "$1" ] ; then
        cd $1
        pwd
    else
        f="$(basename $1)"
        d="$(dirname $1)"
        cd $d
        echo "$(pwd)/$f"
    fi
)

portz_invoke()
{
    inform "executing: $@"
    quiet_if_success "$@"
    r=$?
    if [ "$r" != "0" ] ; then
        echo "'$@' failed with error code $r" 1>&2
        exit $?
    fi
}

portz_invoke_always()
{
    portz_invoke "$@"
}

portz_assert_know_package()
{
    if [ -n "$unknown_package" ] ; then
        fail "unknown package '$package' (descriptor not found in ${portz_repo})"
    fi
}

# jedit: :tabSize=8:indentSize=4:noTabs=true:mode=shellscript:

