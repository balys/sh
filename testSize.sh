#!/bin/bash

size=0
touch results.txt

 for file in *; do

  if [ -d $file ]; then
    for filesize in `find . -type f | xargs du 2>/dev/null | awk '{print $1;}'` ; do
        size=$(($size + $filesize))
        if [ $size -gt 2000000 ]
         then
                echo "$file size is at least $size Kbytes, more than 2GB" >> results.txt
                size=0
                break
        fi
    done

    if [ $size -lt 2000000 ]
     then
        echo "$file size is $size Kbytes" >> results.txt
        size=0
    fi
  fi
 done

exit 0;

