#!python
#
# v0.1 Dec 12 2011
# v0.2 Dec 31 2011
#
#

import os
import glob
import re
import time

TEDdir = 'C:/iPod/Music/Podcasts/TEDTalks (video)'
command = 'ffmpeg -i "infile" -vcodec mpeg4 "outfile"'

os.system('title ConvertTED')

mp4Files = glob.glob(TEDdir + '/*.mp4')
for f in mp4Files:
	if (f.find('_ORIG') != -1):
		nf = f.replace('_ORIG', '')
		if (os.path.exists(nf)):
			print 'SKIP ' + f
		else:
			print 'REMOVE ORPHAN ORIG ' + f
			os.remove(f)
		continue

	(pri, pro) = os.popen4('ffprobe "' + f + '"', 't')
	videoData = re.search('Stream[^\n]*Video[^\n]*', pro.read()).group(0)
	pri.close()
	pro.close()
	
	if (videoData.find('h264') == -1 or videoData.find('x288') == -1):
		print 'SKIP ' + f
		continue
		
	print 'PROCESS ' + f
	(base, ext, ignore) = f.partition('.mp4')
	origF = base + '_ORIG' + ext
	cmdStr = 'ffmpeg -i "' + origF + '" -vcodec mpeg4 "' + f + '"'
	print 'rename ' + f + ' ' + origF
	print cmdStr
	os.rename(f, origF)
	os.system(cmdStr)

	time.sleep(180)
	
os.system('pause')


