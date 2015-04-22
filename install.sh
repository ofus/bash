#!/bin/bash

for FILE in $(find . -name \.\* -type f  -print | sed 's/.\///g'); do
	OLDFILE=$HOME/$FILE
	OLDSIZE=$(ls -lA $OLDFILE 2> /dev/null | cut -f5 -d' ')
	SIZE=$(ls -lA $FILE | cut -f5 -d' ')
	FILENAME=$(pwd)/$FILE
	# echo $FILE $OLDFILE
	# echo $SIZE $OLDSIZE
	if [[ $SIZE != $OLDSIZE ]]; then
		if [[ -f $OLDFILE ]]; then
			mv $OLDFILE $OLDFILE.bak.$(date +%Y%m%d%H%M%S)
			ln -s $FILENAME $OLDFILE
			echo Replaced $FILE
		else
			read -p "$OLDFILE does not exist. Link this file? " -n 1 -r
			echo    # (optional) move to a new line
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				ln -s $FILENAME $OLDFILE
				echo Added $FILE
			fi
		fi
	fi
done