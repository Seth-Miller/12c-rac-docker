#!/bin/sh


CONTAINER=$1

pidlist ()
{
    local thispid=$1;
    local fulllist=;
    local childlist=;
    childlist=$(ps --ppid $thispid -o pid h);
    for pid in $childlist;
    do
        fulllist="$(pidlist $pid) $fulllist";
    done;
    echo "$thispid $fulllist"
}

pscap | awk '$2 ~ /'$(pidlist \
            $(docker inspect --format {{.State.Pid}} $CONTAINER) | \
            sed -e 's/^\s*\|\s*$//g' -e 's/\s\+/|/g')'/' | \
            sort -n -k 2
