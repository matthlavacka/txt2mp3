#!/bin/bash
#
####################################
# Text to MP3 Converter
# written by Tobias Mejstad
# created April 2013
####################################

showHelp(){
	echo "Text to MP3 Converter";
	echo;
	echo "Usage: txt2mp3 [FILES]...";
}

checkExitStatus(){
	if [[ $? -eq 0 ]]; then
		echo "--> ...done";
	elif [[ $? -ne 0 ]]; then
		echo "--> ...ERROR";
	fi
	EXITSTATUS=$((${EXITSTATUS}+$?));
}

if [[ $# -eq 0 ]] || [[ "${1}" == "--help" ]]; then
    showHelp;

elif [[ $# -gt 0 ]] && [[ "${1}" != "--help" ]]; then

	# set start time
	T="$(date +%s)";

	# get path
	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
	# echo $DIR;

	# set log file
	LOGFILE="${DIR}/logfile.log";
	if [ -f "${LOGFILE}" ]; then
		mv ${LOGFILE} "${LOGFILE%%.*}".old;
	fi
	touch ${LOGFILE};

	EXITSTATUS=0;

	for var in "$@"
	do
		FULLFILE="${var}";
		FILE="${FULLFILE%%.*}";
		FILEEXT="${FULLFILE##*.}";

		# if file extension is not txt, goto next iteration
		if [[ "${FILEEXT}" != txt ]]; then
			printf "%s\n\n" "--> NOTE: file ${FULLFILE} is not a text file, skipping it";
			continue;
		fi

		# convert text to an audio (aiff) file 
		echo "--> converting ${FILE}.txt to ${FILE}.aiff";
		`say -f ${FILE}.txt -o ${FILE}.aiff >>${LOGFILE} 2>&1`; # -r for rate supported in newer versions of OSX
		checkExitStatus;
		
		# convert file to mp3
		echo "--> converting ${FILE}.aiff to ${FILE}.mp3";
		# `ffmpeg -y -i ${FILE}.aiff ${FILE}.mp3 >>${LOGFILE} 2>&1`; # not working well, itunes gets wrong track length
		lame -h -m m -b 32 ${FILE}.aiff ${FILE}.mp3 >>${LOGFILE} 2>&1;
		checkExitStatus;
		
		# change the MP3 ID3 for the file
		echo "--> tagging file ${FILE}.mp3";
		id3tag -atxt2mp3 -A${FILE} -s${FILE} ${FILE}.mp3 >>${LOGFILE} 2>&1;
		checkExitStatus;
		
		# remove aiff file
		echo "--> removing ${FILE}.aiff"
		`rm ${FILE}.aiff`;
		checkExitStatus;

		# add file to iTunes
		echo "--> adding ${FILE}.mp3 to iTunes"
		FULLPATH="${DIR}/${FILE}.mp3";

		/usr/bin/osascript >>${LOGFILE} 2>&1 <<-EOS
		tell application "System Events"
			set ProcessList to name of every process
			if "iTunes" is not in ProcessList then
				do shell script "open /Applications/iTunes.app && sleep 10"
			end if
		end tell
		EOS

		/usr/bin/osascript >>${LOGFILE} 2>&1 <<-EOT
		tell application "iTunes"
			add POSIX file "${FULLPATH}"
		end tell
		EOT
		checkExitStatus;

		# add blank line to log file for readability
		echo "" >>${LOGFILE};
		
		# print status for file
		printf "%s\n\n" "--> done with ${FILE}.mp3";
	done

	# calculate time diff
	T="$(($(date +%s)-T))";

	# print time output
	printf "%s\n\n" "Completed in ${T} seconds";

	# print error output
	if [[ EXITSTATUS -ne 0 ]]; then
			echo "Errors printed to ${LOGFILE}";
	elif [[ EXITSTATUS -eq 0 ]]; then
			echo "No errors";
	fi
fi
