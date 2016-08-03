#!/bin/csh
#
# Convert movie files to format that can be read on my old 3rd Gen iPod Nano
#
#
# TO DO:
#	+Detect resolution and aspect ratio of video automatically
#	Detect video type automatically
#	Add course name automatically - shorten somehow
#

set courseName = Autism
#set files = (*)
set files = (*.mov *.m4v *.mp4)
#set files = ("Hemingway's In Our Time.m4v")
#set files = (1*)

set sleepSecs = 15
set doLetterbox = 0
set videoType = h264
set fcount = 0
set i = 1

while ($i <= $#files)
	set f = "$files[$i]"
	@ i = $i + 1

	#if ("$f" !~ "L*") continue
	#if ("$f" == "_NOTES*" || "$f" == "conv.csh" || "$f" =~ "*IPOD*" || "$f" == "tmp" || "$f" =~ "meta*") continue
	if ("$f" =~ "*IPOD*") continue

	# get metadata from file - alter title to include course name at start
	ffmpeg -hide_banner -v error -i "$f" -f ffmetadata -y meta.txt
	sed "s/^title=/title=${courseName}: /" meta.txt > meta2.txt

	# output file name - add course name to start (no colon)
	set outName = "${courseName} ${f:r} IPOD.${f:e}"
	#set outName = "${f:r} IPOD.${f:e}"
	echo ""; echo "Processing: $outName"

	# most movie files have still image for title, which is listed as a video stream
	# by default fmpeg chooses the "best" video stream - highest res - so still image is getting selected
	# stream 0:0 is usually video, but not always, so use this to get it
	#set vs = 0
	set vs = `ffmpeg -hide_banner -i "$f" |& grep -o "Stream #.*$videoType" | grep -o '0:\d\+'`
	if ("$vs" == "") then 
		echo "ERROR: Could not locate video stream!"
	endif

	# get resolution of video, aspect ratio and whether to letterbox or not
	set res = `ffmpeg -hide_banner -i "$f" |& grep "Stream #.*$videoType" | grep -o '\d\{3,\}x\d\+' | sed 's/x/ /'`
	if ("$res" == "") then
		echo "Could not determine video resolution!"
		continue
	endif
	set asp = `echo "scale = 2 ; $res[1] / $res[2]" | bc -l`
	if ("$asp" == "1.77") then
		set doLetterbox = 1
	else if ("$asp" != "1.33") then
		echo "Strange video aspect ratio: $asp"
		continue
	endif

	# use of -map strips out subtitles and still image(s)
	if ($doLetterbox) then
		# assumes incoming movie is 16:9 - scales and letterboxes in center
		ffmpeg -hide_banner -v warning -i "$f" -i meta2.txt -map_metadata 1 -map $vs -map 0:a -codec copy -sn -codec:v mpeg4 -filter:v "scale=320:180, pad=320:240:0:30" -y "$outName"
	else
		# incoming movie is 4:3 - just scaled to 320x240
		ffmpeg -hide_banner -v warning -i "$f" -i meta2.txt -map_metadata 1 -map $vs -map 0:a -codec copy -sn -codec:v mpeg4 -filter:v "scale=320:240" -y "$outName"
	endif

	rm "$f"
	rm meta.txt meta2.txt
	@ fcount = $fcount + 1

	if ($i <= $#files) sleep $sleepSecs
end

echo ""
echo "Done: $#files files specified, $fcount files processed"










