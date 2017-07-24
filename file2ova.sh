#!/bin/bash
display_help() {
    echo "Warning: this script depends on ovftool and vmware-mount"
    echo "It's highly recommended to use latest ovftool >= 4.2.0"
    if ! hash ovftool 2>/dev/null; then
    echo "Ovftool doesn't installed. Please install it with VMware Workstation Player 12 or download it here: https://my.vmware.com/web/vmware/details?productId=614&downloadGroup=OVFTOOL420"
    fi
    if ! hash vmware-mount 2>/dev/null; then
    echo "VMware-mount doesn't installed. Please install it with VMware Workstation Player 12 or download it here: https://my.vmware.com/web/vmware/details?productId=46&downloadGroup=WKST-550-DISK-MOUNT-UTL"
    fi
    echo
    echo "Usage: $0 [option...] <-f|-l> <path> <source> [<target>]" >&2
    echo
    echo "   -h, --help               :show this page"
    echo "   -p, --partNum   <numb>   :set partNum. Default: 1"
    echo "   -t, --time               :print execution time"
    echo "   -f, --file      <path>   :set path to the file, that should be added into ova"
    echo "   -l, --link      <link>   :set link to the file, that should be added into ova"
    echo "   -d, --directory <path>   :set path to directory on disk for adding new files"
    echo 
    echo "You can supply a link to file on server or file in local directory, or both."
    echo
    echo "Example 1: " 
    echo "We setting only file directory, and setting source, which means we overwriting it"
    echo "./file2ova.sh -f <path>/<to>/<file> <path>/<to>/<source>.ova"
    echo
    echo "Example 2: " 
    echo "We setting link to the file on server, and setting source and a target"
    echo "./file2ova.sh -l https://<link>/<to>/<file> <path>/<to>/<source>.ova <path>/<to>/<target>.ova"
    echo
    echo "You can use two of this options to add 2 files from different sources"
    exit 1
}

if ! hash ovftool 2>/dev/null; then
    echo "Ovftool doesn't installed. Please install it with VMware Workstation Player 12 or download it here: https://my.vmware.com/web/vmware/details?productId=614&downloadGroup=OVFTOOL420"
    exit 1
fi

if ! hash vmware-mount 2>/dev/null; then
    echo "VMware-mount doesn't installed. Please install it with VMware Workstation Player 12 or download it here: https://my.vmware.com/web/vmware/details?productId=46&downloadGroup=WKST-550-DISK-MOUNT-UTL"
    exit 1
fi

if [ -z "$1" ]; then
    echo "No argument supplied, please refer to help"
    echo
    display_help
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
      -l | --link)
    		  if [ $# -ne 0 ]; then
    		  	link_to_file="$2"
    		  else
    		  	echo "Invalid argument. Enter working link to file"
            echo
            exit 1
          fi
          shift 2
          ;;
      -f | --file)
		      if [ $# -ne 0 ]; then
		  	     path_to_file=$(readlink -m $2)
		      else
		  	     echo "Invalid argument. Enter working path to file"
             echo
             exit 1
          fi
          shift 2
          ;;
      -d | --directory)
          if [ $# -ne 0 ]; then
             file_location="$2"
          else
             echo "Invalid argument. Enter working path to directory"
             echo
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
	echo
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
	echo
	exit 1
fi
echo $file_location
echo $link_to_file
echo $path_to_file

sourcePath=$(dirname $SOURCE_FILE)
targetPath=$(dirname $TARGET_FILE)

ovftool $SOURCE_FILE $sourcePath/tmp.vmx
sudo mkdir /mnt/tmp
sudo vmware-mount $sourcePath/tmp-disk1.vmdk 1 /mnt/tmp
cd /mnt/tmp$file_location
if [ ! -z $link_to_file ]; then
	sudo curl --remote-name $link_to_file
fi
if [ ! -z $path_to_file ]; then
	sudo cp $path_to_file /mnt/tmp$file_location$(basename $path_to_file)
fi
echo File copied
cd $sourcePath
sudo vmware-mount -d /mnt/tmp
sudo rm -rd /mnt/tmp
echo Disk unmounted
ovftool -o $sourcePath/tmp.vmx $TARGET_FILE

find . -name 'tmp*' -delete
echo Finished
END=$(date +%s.%N)

if [ "$time" = true ]; then
	DIFF=$(echo "$END - $START" | bc)
	echo $DIFF
fi