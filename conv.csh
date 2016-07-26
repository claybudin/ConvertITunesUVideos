#!/bin/csh
#
# Convert movie files to format that can be read on my old 3rd Gen iPod Nano
#
#
# TO DO:
#	Detect resolution and aspect ratio of video automatically
#	Detect video type automatically
#	Add course name automatically - shorten somehow
#

set courseName = iOS
set doLetterbox = 1
set videoType = h264

set sleepSecs = 5

#foreach f (*)
foreach f (*.mov *.m4v *.mp4)
	#if ("$f" !~ "L*") continue
	#if ("$f" == "_NOTES*" || "$f" == "conv.csh" || "$f" =~ "*IPOD*" || "$f" == "tmp" || "$f" =~ "meta*") continue
	if ("$f" =~ "*IPOD*") continue

	# get metadata from file - alter title to include course name at start
	ffmpeg -hide_banner -v error -i "$f" -f ffmetadata -y meta.txt
	sed "s/^title=/title=${courseName}: /" meta.txt > meta2.txt

	#set outName = "${courseName} ${f:r} IPOD.${f:e}"
	set outName = "${f:r} IPOD.${f:e}"
	echo ""; echo "Processing: $outName"

	# most movie files have still image for title, which is listed as a video stream
	# by default fmpeg chooses the "best" video stream - highest res - so still image is getting selected
	# stream 0:0 is usually video, but not always, so use this to get it
	# only gets single-digit stream number
	#set vs = 0
	set vs = `ffmpeg -hide_banner -i "$f" |& grep -o "Stream #.*$videoType" | sed "s/Stream #0:\([0-9]\).*$videoType/\1/"`

	if ("$vs" != "") then 
		# use of -map strips out subtitles and still image(s)

		if ($doLetterbox) then
			# assumes incoming movie is 16:9 - scales and letterboxes in center
			ffmpeg -hide_banner -v warning -i "$f" -i meta2.txt -map_metadata 1 -map 0:$vs -map 0:a -codec copy -sn -codec:v mpeg4 -filter:v "scale=320:180, pad=320:240:0:30" -y "$outName"
		else
			# incoming movie is 4:3 - just scaled to 320x240
			ffmpeg -hide_banner -v warning -i "$f" -i meta2.txt -map_metadata 1 -map 0:$vs -map 0:a -codec copy -sn -codec:v mpeg4 -filter:v "scale=320:240" -y "$outName"
		endif

		rm "$f"
		sleep $sleepSecs
	else
		echo "ERROR: Could not locate video stream!"
	endif

	rm meta.txt meta2.txt

end












