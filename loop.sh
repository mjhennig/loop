#!/bin/sh
# ------------------------------------------------------------------------
# vim: set expandtab tabstop=4 shiftwidth=4 softtabstop=4 textwidth=75   :
# ------------------------------------------------------------------------
# Mathias J. Hennig wrote this script. As long as you retain this notice :
# you can do whatever you want with this stuff. If we meet some day, and :
# you think this stuff is worth it, you can buy me a beer in return.     :
# ------------------------------------------------------------------------

##
# If nonempty, loop will be run in debug mode
[ -z "$LOOP_DEBUG" ] && LOOP_DEBUG=

##
# If nonempty, loop will ignore failures by default
[ -z "$LOOP_IGNORE_FAILURES" ] && LOOP_IGNORE_FAILURES=

##
# If nonempty, loop will be in verbose mode by default
[ -z "$LOOP_VERBOSE" ] && LOOP_VERBOSE=

##
# If nonempty, loop will clear the screen in each iteration by default
[ -z "$LOOP_CLEAR" ] && LOOP_CLEAR=

##
# If nonempty, loop will wait for a keystroke after each iteration
[ -z "$LOOP_WAITKEY" ] && LOOP_WAITKEY=

##
# The loop_usage() function creates a usage hint in case of failure or if
# the user has requested it (via -h, for example). To notify any misuse of
# options or else, the according message can be passed to this function -
# it will then print the hint on STDERR and prepend the message.
loop_usage() {
    name="`basename $0`"
    if [ 'x0' = "x$#" ]; then
        stream=/dev/stdout
    else
        stream=/dev/stderr
        echo "$name:" "$@" > $stream
    fi
    cat > $stream <<END
Usage:  $name [-cCFfFhHIrRvVwW] [-i limit] [-d secs] command
        $name -h

END
}

##
# Print messages prefixed with argv[0] if $LOOP_VERBOSE is given
loop_verbose() {
    if [ 'x' != "x$LOOP_VERBOSE" -o 'x' != "x$LOOP_DEBUG" ]; then
        echo "`basename $0`:" "$@" >> /dev/stderr
    fi
}

##
# The command invoked in "waitkey" mode; probably not that portable yet
loop_waitkey() {
    stty -F/dev/tty -echo
    if [ -z "$LOOP_DEBUG" ]; then
        dd count=1 if=/dev/tty of=/dev/null >/dev/null 2>&1
    else
        dd count=1 if=/dev/tty of=/dev/null
    fi
    stty -F/dev/tty echo
}

##
# Option handling, part 1
set -- `getopt -un "\`basename $0\`" '+cCd:DfFhHi:IrRvVwW' "$@"`

##
# Option handling, part 2
while :; do
    case "$1" in

        -c) LOOP_CLEAR=1
            loop_verbose "Refresh mode enabled."
            ;;
        -C) LOOP_CLEAR=
            loop_verbose "Refresh mode disabled."
            ;;

        -d) shift
            LOOP_DELAY=`printf "%d" "$1" `
            if [ 0 -gt $LOOP_DELAY ]; then
                loop_usage "Invalid number of delay seconds: $1"
                exit 1
            fi
            loop_verbose "Delay set to $LOOP_DELAY seconds."
            ;;
        -D) LOOP_DELAY=
            loop_verbose 'Delay mode disabled.'
            ;;

        -f) LOOP_IGNORE_FAILURES=1
            loop_verbose 'Failure ignore mode enabled.'
            ;;
        -F) LOOP_IGNORE_FAILURES=
            loop_verbose 'Failure ignore mode disabled.'
            ;;

        -h) loop_usage >> /dev/stdout ; exit ;;
        -H) loop_usage >> /dev/stderr ; exit ;;

        -i) shift
            LOOP_MAX=`printf "%d" "$1" 2>/dev/null`
            if [ 0 -gt $LOOP_MAX ]; then
                loop_usage "Invalid number of iterations: $1"
                exit 1
            fi
            loop_verbose "Max. number of iterations: $LOOP_MAX"
            ;;

        -I) LOOP_MAX=
            loop_verbose 'Iteration limit mode disabled.'
            ;;

        -r) LOOP_READ=1
            loop_verbose 'Input from STDIN will be exported as $LINE.'
            ;;

        -R) LOOP_READ=
            loop_verbose 'Readline mode disabled.'
            ;;

        -v) LOOP_VERBOSE=1
            loop_verbose 'Verbose mode enabled.'
            ;;
        -V) LOOP_VERBOSE=
            loop_verbose 'Verbose mode disabled.'
            ;;

        -w) LOOP_WAITKEY=1
            loop_verbose 'Waitkey mode enabled.'
            ;;
        -W) LOOP_WAITKEY=
            loop_verbose 'Waitkey mode disabled.'
            ;;

        --) shift; break
            ;;
    esac
    shift
done

##
# The main condition to stay in the loop
if [ 'x' != "x$LOOP_READ" ]; then
    LOOP_COMMAND='read LINE'
    LOOP_RETVAL=EOF
else
    LOOP_COMMAND=':'
fi

##
# The (internal) iterator to be increased for each loop, exported as $LOOP
LOOP_ITER=-1

##
# The loop itself. Note that we use eval() to execute the command, so it's
# possible - but not recommended - to manipulate the loop variables..
while IFS=\$ $LOOP_COMMAND
do
    LOOP_RETVAL=0
    LOOP_ITER=`expr $LOOP_ITER + 1`

    if [ "x$LOOP_ITER" = "x$LOOP_MAX" ]; then
        loop_verbose 'Loop aborted due to iteraton maximum reached.'
        break
    fi

    [ -z "$LOOP_CLEAR" ] || clear

    export ITER=$LOOP_ITER
    export LINE

    eval "$@"
    LOOP_RETVAL=$?

    if [ 'x0' != "x$LOOP_RETVAL" -a -z "$LOOP_IGNORE_FAILURES" ]; then
        loop_verbose 'Loop aborted due to failure reported by command.'
        break
    fi

    if [ ! -z "$LOOP_DELAY" ]; then
        loop_verbose "Will now sleep for $LOOP_DELAY seconds.."
        sleep $LOOP_DELAY
    fi

    # "A" key might be easier to find than "ANY"
    if [ ! -z "$LOOP_WAITKEY" ]; then
        echo -n "Press a key to continue.."
        loop_waitkey
        echo
    elif [ 'x' != "x$LOOP_DEBUG" ]; then
        loop_verbose "Waiting for keystroke because of DEBUG mode!"
        loop_waitkey
    fi

    # If not overwritten, we know the input stream has run dry
    LOOP_RETVAL=EOF

done

##
# Over & out
if [ 'xEOF' = "x$LOOP_RETVAL" ]; then
    loop_verbose 'Loop aborted due to EOF.'
    exit
else
    exit $LOOP_RETVAL
fi

