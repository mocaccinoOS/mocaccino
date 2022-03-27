#!/bin/bash
#  2004/08/22  K. Piche  Find missing library references.
ifs=$IFS
IFS=':'

libdirs="/lib:/lib64:/usr/lib:/usr/lib64"
extras=

#  Check ELF binaries in the PATH and specified dir trees.
for tree in $PATH $libdirs $extras
do
        echo DIR $tree

        #  Get list of files in tree.
        files=$(find $tree -type f)
        IFS=$ifs
        for i in $files
        do
                if [ `file $i | grep -c 'ELF'` -ne 0 ]; then
                        #  Is an ELF binary.
                        if [ `ldd $i 2>/dev/null | grep -c 'not found'` -ne 0 ]; then
                                #  Missing lib.
                                echo "$i:"
                                ldd $i 2>/dev/null | grep 'not found'
                        fi
                fi
        done
done

exit