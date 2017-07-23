#!/bin/bash
display_help() {
    echo "Usage: $0 [option...] <source> [<target>]" >&2
    echo
    echo "   -h, --help           :show this page"
    echo "   -p, --partNum        :set partNum. Default: 1"
    echo "   -t, --time        	  :print execution time"
    echo "   -f, --file           :set link to the file"
    exit 1
}

if [ -z "$1" ]; then
    echo "No argument supplied"
    exit 1
fi

START=$(date +%s.%N)

time=false
while :
do
    case "$1" in
      -p | --partNum)
          if [ $# -ne 0 ]; then
          	if [ "$2" = "$2" ]; then
              	partNum="$2"
            else
            	echo "Invalid argument. After -p should be integer number"
            	exit 1
        	fi
          fi
          shift 2
          ;;
      -h | --help)
          display_help
          exit 0
          ;;
      -t | --time)
          time=true
          shift
          ;;
      -f | --file)
		  if [ $# -ne 0 ]; then
		  	link_to_file="$2"
		  else
		  	echo "Invalid argument. Enter working link to file"
            exit 1
          fi
          shift 2
          ;;
      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          display_help
          exit 1 
          ;;
      *)  # No more options
          break
          ;;
    esac
done

if [ ! -e $1 ]; then
	echo "Can't find the file $1" 
	exit 1
else
	SOURCE_FILE=$(readlink -m $1)
fi

if [ ! -z $2 ]; then
	if [ -e $2 ]; then
		TARGET_FILE=$SOURCE_FILE
	else
		TARGET_FILE=$(readlink -m $2)
	fi
else
	TARGET_FILE=$SOURCE_FILE
fi

echo $SOURCE_FILE
echo $TARGET_FILE

if [ ${SOURCE_FILE: -4} != ".ova" ] || [ ${TARGET_FILE: -4} != ".ova" ]; then
	echo "File extension should be .ova"
	exit 1
fi
echo $link_to_file

sourcePath=$(dirname $SOURCE_FILE)
targetPath=$(dirname $TARGET_FILE)

ovftool $SOURCE_FILE $sourcePath/tmp.vmx
sudo mkdir /mnt/tmp
sudo vmware-mount $sourcePath/tmp-disk1.vmdk 1 /mnt/tmp
cd /mnt/tmp/
sudo curl --remote-name $link_to_file
echo File copied
cd $sourcePath
sudo vmware-mount -d /mnt/tmp
sudo rm -rd /mnt/tmp
echo Disk unmounted
ovftool $sourcePath/tmp.vmx $TARGET_FILE

find . -name 'tmp*' -delete
echo Finished
END=$(date +%s.%N)

if [ "$time	" = true ]; then
	DIFF=$(echo "$END - $START" | bc)
	echo $DIFF
fi