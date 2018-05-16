#!/bin/bash

funval=""
cursor=0
enter_pressed=-1

while :
do

verticalLine()
{
	# start_row $1
	# start_col $2
	# end_row $3
	# end_col $2

	for (( i="$1"; i<="$3"; i++ ))
	do
		tput cup $i $2
		printf "|"
	done
}

frame()
{
	echo "=============================================== 2017203059 ChungRyeol Lee =============================================="
	echo "========================================================= List ========================================================="
	verticalLine 2 0 28
	verticalLine 2 29 28
	verticalLine 2 76 28
	verticalLine 2 119 28
	echo "====================================================== Information ====================================================="
	verticalLine 30 0 35
	tput cup 36 0
	echo "========================================================= Total ========================================================"
	verticalLine 37 0 37
	tput cup 38 0
	echo "========================================================== END ========================================================="
	tput cup 2 1
}

isDirectory()
{
	[ -d "$1" ] && funval="true" || funval="false"
}

isFile()
{
	[ -f "$1" ] && funval="true" || funval="false"
}

isCompressed()
{
	case "$1" in
	*.tar.gz | *.zip ) funval="true";;
	* ) funval="false";;
	esac
}

isExecutable() {
	[ -x "$1" ] && funval="true" || funval="false"
}

readArray()
{
	listarray[$1]="$2"
}

fileType()
{
	filetypearray[0]="first" # ..
	len=${#listarray[@]}

	for (( i=1; i<$len; i++ ))
	do
		isDirectory ${listarray[$i]}
		if [ "$funval" = "true" ]
		then
			filetypearray[$i]="dir"
		else
			isFile ${listarray[$i]}
			if [ "$funval" = "true" ]
			then
				isCompressed ${listarray[$i]}
				if [ "$funval" = "true" ]
				then
					filetypearray[$i]="zip"
				else
					isExecutable ${listarray[$i]}
					if [ "$funval" = "true" ]
					then
						filetypearray[$i]="exe"
					else
						filetypearray[$i]="nor"
					fi
				fi
			fi
		fi
	done
}

printArray()
{
	for (( i=0; i<27; i++ ))
	do
		tput cup `expr $i + 2` 1
		if [ $cursor = $i ]
		then
			case ${filetypearray[$i]} in
			"dir" ) echo [30m[44m"${listarray[$i]:0:28}[0m";;
			"zip" ) echo [30m[41m"${listarray[$i]:0:28}[0m";;
			"exe" ) echo [30m[42m"${listarray[$i]:0:28}[0m";;
			"nor" ) echo [30m[107m"${listarray[$i]:0:28}[0m";;
			"first" ) echo [30m[41m"${listarray[$i]:0:28}[0m";;
			* ) ;;
			esac
		else
			case ${filetypearray[$i]} in
			"dir" ) echo [34m[49m"${listarray[$i]:0:28}[0m";;
			"zip" ) echo [31m[49m"${listarray[$i]:0:28}[0m";;
			"exe" ) echo [32m[49m"${listarray[$i]:0:28}[0m";;
			"nor" ) echo [97m[49m"${listarray[$i]:0:28}[0m";;
			"first" ) echo [31m[49m"${listarray[$i]:0:28}[0m";;
			* ) ;;
			esac
		fi
	done
}

fileInfoType()
{
	case ${filetypearray[$1]} in
	"dir" ) echo [34m[49m"directory[0m";;
	"zip" ) echo [31m[49m"compressed file[0m";;
	"exe" ) echo [32m[49m"execute file[0m";;
	"nor" ) echo [97m[49m"regular file[0m";;
	"first" ) echo [34m[49m"directory[0m";;
	* ) ;;
	esac	
}

fileInfo()
{
	filename=${listarray[$1]}

	tput cup 30 1
	echo "file name : ${filename:0:106}"

	tput cup 31 1
	printf "file type : "
	fileInfoType $1

	tput cup 32 1
	echo "file size : `stat -c %s $filename`"

	tput cup 33 1
	echo "creation time : `stat -c %x $filename`"

	tput cup 34 1
	echo "permission : `stat -c %a $filename`"

	tput cup 35 1
	printf "absolute path : "
	pwd | tr -d '\n'
	echo "/.."
}

printFile()
{
	i=1
	cat "$1" | \
	while read LINES; do
		tput cup `expr $i + 1` 30
		if [ $i -le 9 ]; then
			echo "$i  ${LINES:0:43}"
		else
			echo "$i ${LINES:0:43}"
		fi

		i=`expr $i + 1`
		if [ $i = 28 ]; then
			break;
		fi
	done
}

enterPressed()
{
	if [ $1 = $enter_pressed ]
	then
		case ${filetypearray[$1]} in
		"dir" ) cd ${listarray[$1]};cursor=0;;
		"zip" ) ;;
		"exe" | "nor" ) printFile ${listarray[$1]};;
		"first" ) cd ${listarray[$1]};cursor=0;;
		* ) ;;
		esac	
	fi
}

count=0

dircount=0
filecount=0
sfilecount=0

countFiles()
{
	len=${#listarray[@]}
	for (( i=0; i<$len; i++ )); do
		case ${filetypearray[$i]} in
		"zip" | "exe" ) sfilecount=`expr $sfilecount + 1`;;
		"dir" ) dircount=`expr $dircount + 1`;;
		"nor" ) filecount=`expr $filecount + 1`;;
		* ) ;;
		esac
	done
}

countPrint()
{
	bytes=`du -bs . | cut -f 1 -d '	'`
	tput cup 37 10
	printf "$count total   $dircount dir   $filecount file   $sfilecount Sfile   $bytes bytes"
}

clear	#clear the screen
frame	#function call: draw lines

tput cup 2 1

enterPressed $cursor

listarray=( )
listarray[0]=".."

# putting directories
for line in `ls`
do
	isDirectory $line
	if [ "$funval" = "true" ]
	then
		count=`expr $count + 1`
		readArray $count $line
	fi
done

# putting files
for line in `ls`
do
	isFile $line
	if [ "$funval" = "true" ]
	then
		count=`expr $count + 1`
		readArray $count $line
	fi
done

filetypearray=( )
fileType
printArray

# === Information ===
fileInfo $cursor

# === Total ===
countFiles
countPrint

# reading key input
tput cup 40 0
read -n 3 key

if [[ $key = "" ]]
then
	# if pressed "enter", let the program know in the next loop.
	# not working. (why?)
	enter_pressed=${cursor}
elif [[ $key = "[A" ]]
then
	enter_pressed=-1
	if [ $cursor = 0 ]
	then
		if [ $count -gt 26 ]; then
			cursor=26
		else
			cursor=$count
		fi
	else
		cursor=`expr $cursor - 1`
	fi
elif [[ $key = "[B" ]]
then
	enter_pressed=-1

	if [ $cursor = $count ] || [ $cursor = 26 ]
	then
		cursor=0
	else
		cursor=`expr $cursor + 1`
	fi
fi

############
# END LOOP #
############
done
