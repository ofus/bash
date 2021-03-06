#!/usr/bin/env bash

OLDDIR=$HOME/.oldbash~
mkdir -p "$OLDDIR"

for FILE in $(find . -name \.\* -type f  -print | sed 's/.\///g'); do
    OLDFILE=$HOME/$FILE
    FILENAME=$(pwd)/$FILE

    if ! cmp -s "$FILENAME" "$OLDFILE"; then
        if [[ -f $OLDFILE ]]; then
            read -p "$OLDFILE exists. Overwrite this file? " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mv "$OLDFILE" "$OLDDIR/$FILE.bak.$(date +%Y%m%d%H%M%S)"
                cp "$FILENAME" "$OLDFILE"
                echo Updated "$FILE"
            fi
        else
            read -p "$OLDFILE does not exist. Add this file? " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp "$FILENAME" "$OLDFILE"
                echo Added "$FILE"
            fi
        fi
    fi
done

exec bash
