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
[ 'x' = 'x$LOOP_DEBUG' ] && LOOP_DEBUG=

##
# If nonempty, loop will ignore failures by default
[ 'x' = 'x$LOOP_IGNORE_FAILURES' ] && LOOP_IGNORE_FAILURES=

##
# If nonempty, loop will be in verbose mode by default
[ 'x' = 'x$LOOP_VERBOSE' ] && LOOP_VERBOSE=

##
# If nonempty, loop will clear the screen in each iteration by default
[ 'x' = 'x$LOOP_CLEAR' ] && LOOP_CLEAR=

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
Usage:  $name [-cCfv] [-i limit] [-d secs] command
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
# Option handling, part 1
set -- `getopt -un "\`basename $0\`" '+cCd:DfFhHi:IrRvV' "$@"`

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
            loop_delay=`printf "%d" "$1" `
            if [ 0 -gt $loop_delay ]; then
                loop_usage "Invalid number of delay seconds: $1"
                exit 1
            fi
            loop_verbose "Delay set to $loop_delay seconds."
            ;;
        -D) loop_delay=
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
            loop_max=`printf "%d" "$1" 2>/dev/null`
            if [ 0 -gt $loop_max ]; then
                loop_usage "Invalid number of iterations: $1"
                exit 1
            fi
            loop_verbose "Max. number of iterations: $loop_max"
            ;;

        -I) loop_max=
            loop_verbose 'Iteration limit mode disabled.'
            ;;
        
        -r) loop_read=1
            loop_verbose 'Input from STDIN will be exported as $LINE.'
            ;;

        -R) loop_read=
            loop_verbose 'Readline mode disabled.'
            ;;

        -v) LOOP_VERBOSE=1
            loop_verbose 'Verbose mode enabled.'
            ;;
        -V) LOOP_VERBOSE=
            loop_verbose 'Verbose mode disabled.'
            ;;

        --) shift; break
            ;;
    esac
    shift
done

##
# The main condition to stay in the loop
if [ 'x' != "x$loop_read" ]; then
    loop_command='read LINE'
    loop_retval=EOF
else
    loop_command=':'
fi

##
# The (internal) iterator to be increased for each loop, exported as $LOOP
loop_iter=-1

##
# The loop itself. Note that we use eval() to execute the command, so it's
# possible - but not recommended - to manipulate the loop variables..
while $loop_command; do

    loop_retval=0
    loop_iter=`echo "$loop_iter + 1" | bc`

    if [ "x$loop_iter" = "x$loop_max" ]; then
        loop_verbose 'Loop aborted due to iteraton maximum reached.'
        break
    fi

    [ 'x' = "x$LOOP_CLEAR" ] || clear

    export ITER=$loop_iter 
    export LINE

    eval "$@"
    loop_retval=$?

    if [ 'x0' != "x$loop_retval" -a 'x' = "x$LOOP_IGNORE_FAILURES" ]; then
        loop_verbose 'Loop aborted due to failure reported by command.'
        break
    fi

    if [ ! 'x' = "x$loop_delay" ]; then
        loop_verbose "Will now sleep for $loop_delay seconds.."
        sleep $loop_delay
    fi

    loop_retval=EOF

done

##
# Over & out
if [ 'xEOF' = "x$loop_retval" ]; then
    loop_verbose 'Loop aborted due to EOF.'
    exit
else
    exit $loop_retval
fi

