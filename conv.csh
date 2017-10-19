#!/bin/csh
#
# Convert movie files to format that can be read on my old 3rd Gen iPod Nano
#
# Clay Budin
# clay_budin@hotmail.com
# Jul-Sep 2016
#
# NOTES:
#	To use this, first use iTunes to download the videos to be watched
#	Move the videos from /Users/clay_budin/Music/iTunes/iTunes Media/iTunes U/<Course>
#	  to here (/Users/clay_budin/work/Personal/iTunes)
#	Best to work on movies from one course at a time, for naming and possible indexing
#	Set parameters for this script, mostly courseName and optional indexing
#	If using indexing, need to manually order files for processing (see examples below)
#		can also number files themselves so they are in order
#	Check movie type and audio codec with ffmpeg -i <movie> on one of the movie files
#		video should be h264 and audio aac - most are, if not may need to adjust vars below
#		audio check now done automatically
#	Run this script ./conv.csh
#	This script will delete the original movies after it converts them if doDeleteOrig is 1
#	Load the converted movies (with IPOD) onto iPod into Movies area (not iTunes)
#	Delete both original and converted movie files from here
#	Delete videos from list in iTunes
#
# TO DO:
#	+Detect resolution and aspect ratio of video automatically - letterboxing
#	Detect video type automatically
#	Detect audio type and automatically switch between copy and libva_aacenc
#	Add course name automatically - shorten somehow
#

set courseName = MoralPol				# set title of course to group videos together
set indexStart = -1					# if > 0 then add a starting index to names - need to order file sequence in loop below

# file list - if using index then need to set order to match index order
#set files = (*)
set files = (*.mov *.m4v *.mp4)
#set files = ("Hemingway's In Our Time.m4v")
#set files = (*Ring* *Parts* *Well* *PTSD* *Virtue*)
#set files = (02*)


set sleepSecs = 300					# how long to wait between processing movies - let the CPU cool down
set videoType = h264				# check movie type with ffmpeg -i Every iTunes video so far has been h264
set doDeleteOrig = 0				# 1 == delete original movie files, 0 == don't







set echo_style = "both"				# allow escape sequences (color) in echo

set i = 1
set fcount = 0
while ($i <= $#files)
	set f = "$files[$i]"
	@ i = $i + 1

	# skip already processed movies
	#if ("$f" !~ "L*") continue
	#if ("$f" == "_NOTES*" || "$f" == "conv.csh" || "$f" =~ "*IPOD*" || "$f" == "tmp" || "$f" =~ "meta*") continue
	if ("$f" =~ "*IPOD*") continue

	set doLetterbox = 0					# Now done automatically - check movie with ffmpeg -i and if 16:9 set this to 1, if 4:3 set to 0

	# add indexing - some sets of movies don't have starting index numbers
	set idx = ""
	if ($indexStart > 0) then
		@ idx = $indexStart + $fcount
		if ($idx < 10) then
			set idx = "0$idx "
		else
			set idx = "$idx "
		endif
	endif

	# get metadata from file - alter title to include course name at start
	ffmpeg -hide_banner -v error -i "$f" -f ffmetadata -y meta.txt
	sed "s/^title=/title=${courseName}: ${idx}/" meta.txt > meta2.txt

	# output file name - add course name to start (no colon)
	#set outName = "${f:r} IPOD.${f:e}"
	set outName = "${courseName} ${idx}${f:r} IPOD.${f:e}"
	echo ""; echo "Processing: $outName"

	# most movie files have still image for title, which is listed as a video stream
	# by default fmpeg chooses the "best" video stream - highest res - so still image is getting selected
	# stream 0:0 is usually video, but not always, so use this to get it
	#set vs = 0
	set vs = `ffmpeg -hide_banner -i "$f" |& grep -o "Stream #.*$videoType" | grep -o '0:\d\+'`
	if ("$vs" == "") then 
		echo "\e[5;41;1;37m********** ERROR: Could not locate video stream!\e[0m"
	endif

	# get resolution of video, aspect ratio and whether to letterbox or not
	set res = `ffmpeg -hide_banner -i "$f" |& grep "Stream #.*$videoType" | grep -o '\d\{3,\}x\d\+' | sed 's/x/ /'`
	if ("$res" == "") then
		echo "\e[5;41;1;37m********** ERROR: Could not determine video resolution!\e[0m"
		continue
	endif
	set asp = `echo "scale = 2 ; $res[1] / $res[2]" | bc -l`
	if ("$asp" == "1.77") then
		echo "Do Letterboxing"
		set doLetterbox = 1
	else if ("$asp" != "1.33") then
		echo "\e[5;41;1;37m********** ERROR: Strange video aspect ratio: $asp\e[0m"
		continue
	endif

	# determine audio type automatically
	if (`ffmpeg -hide_banner -i "$f" |& grep "Stream #.*Audio:" | wc -l` != 1) then
		echo "\e[5;41;1;37m********** ERROR: Could not determine audio type!\e[0m"
		continue
	endif

	set audioCodec = copy				# usual audio codec - copy input - use when audio is already ACC (check w/ ffmpeg -i on movie)
	#set audioCodec = libvo_aacenc		# for some courses that used weird audio format - convert to AAC
	if (`ffmpeg -hide_banner -i "$f" |& grep "Stream #.*Audio:" | grep aac | wc -l` != 1) then
		echo "Convert audio to AAC"
		set audioCodec = libvo_aacenc
	endif

	# use of -map strips out subtitles and still image(s)
	if ($doLetterbox) then
		# assumes incoming movie is 16:9 - scales and letterboxes in center
		ffmpeg -hide_banner -v warning -i "$f" -i meta2.txt -map_metadata 1 -map $vs -map 0:a -sn -acodec $audioCodec -codec:v mpeg4 -filter:v "scale=320:180, pad=320:240:0:30" -y "$outName"
	else
		# incoming movie is 4:3 - just scaled to 320x240
		ffmpeg -hide_banner -v warning -i "$f" -i meta2.txt -map_metadata 1 -map $vs -map 0:a -sn -acodec $audioCodec -codec:v mpeg4 -filter:v "scale=320:240" -y "$outName"
	endif

	if ($doDeleteOrig) rm "$f"
	rm meta.txt meta2.txt
	@ fcount = $fcount + 1

	if ($i <= $#files) then
		echo "sleep $sleepSecs"
		sleep $sleepSecs
	endif
end

echo ""
echo "***** Done: $#files files specified, $fcount files processed"










