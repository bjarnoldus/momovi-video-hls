#BUILD

Unzip de zip in sdks to 4.6.0
OS X issue: remove the -d32 option in $FLEXPATH/bin/mxmlc batch file of flash

run the build.sh in builds

The result is an OSMF player for StrobeMediaPlayback

#PATCHES By BJA  / NoZAP

Now handles discontinuities in live streams automatically

#TODO (but not really important)
-Set player to Live or VOD (now hided in the webpage)
-subtitles
-test for multiple streams


#HLSprovider

**HLSProvider** is an AS3 plugin that allows you to play HLS playlist using either :

* **Chromeless** Flash Player
* **JWPlayer** Flash free edition version **5.x**
* **JWPlayer** Flash free edition version **6.x**
* **OSMF** version **2.0** (beta stage, any help welcomed !)
 

**HLSProvider** supports the following features :

* VOD/live/DVR playlists
* multiple bitrate playlist / adaptive streaming
* automatic quality switching, using serial segment fetching method described in [http://www.cs.tut.fi/%7Emoncef/publications/rate-adaptation-IC-2011.pdf](http://www.cs.tut.fi/%7Emoncef/publications/rate-adaptation-IC-2011.pdf)
* manual quality switching (JWPlayer 6 only)
* seeking in VoD and live playlist
* buffer progress report
* error resilience (retry mechanism in case of I/O Errors)
* accurate seeking (seek to exact position,not to fragment boundary)

the following M3U8 tags are supported: 

* #EXTM3U
* #EXTINF
* #EXT-X-STREAM-INF (used to support multiple bitrate)
* #EXT-X-ENDLIST (supports live / event / VOD playlist)
* #EXT-X-MEDIA-SEQUENCE (value is used for live playlist update)
* #EXT-X-TARGETDURATION (value is used as live playlist reload interval)
* #EXT-X-DISCONTINUITY

##HLSProvider in action :

* http://streambox.fr/HLSProvider/chromeless
* http://streambox.fr/HLSProvider/jwplayer5
* http://streambox.fr/HLSProvider/jwplayer6
* http://streambox.fr/HLSProvider/osmf


##How to use it :

download package : https://github.com/mangui/HLSprovider/archive/master.zip

###jwplayer5 based setup:
from zip, extract test/chromeless folder, and get inspired by example.html

###OSMF based setup:
from zip, extract test/osmf folder, and get inspired by index.html

###jwplayer5 based setup:
from zip, extract test/jwplayer5 folder, and get inspired by example.html

    <div style="width: 640px; height: 360px;" id="player"></div>
    <script type="text/javascript" src="jwplayer.js"></script>
    <script type="text/javascript">
    
    jwplayer("player").setup({
    width: 640,height: 360,
    modes: [
    { type:'flash', src:'player.swf', config: { provider:'HLSProvider5.swf', file:'http://mysite.com/stream.m3u8' } },
    { type:'html5', config: { file:'http://mysite.com/stream.m3u8' } }
    ]});
    
    </script>

###jwplayer6 based setup:
from zip, extract test/jwplayer6 folder, and get inspired by example.html

    <div style="width: 640px; height: 360px;" id="player"></div>
    <script type="text/javascript" src="jwplayer.js"></script>
    <script type="text/javascript">

    jwplayer("player").setup({
    playlist: [{
    file:'http://mysite.com/stream.m3u8',
    provider:'HLSProvider6.swf',
    type:'hls'
    }],
    width: 640,
    height: 480,
    primary: "flash"
    });

###License
the following files (from [jwplayer.com](http://www.jwplayer.com)) are governed by a Creative Commons license:

* lib/jw5/jwplayer-5-lib.swc
* lib/jw5/jwplayer-5-classes.xml
* lib/jw6/jwplayer-6-lib.swc
* lib/jw6/jwplayer-6-classes.xml
* test/HLSProvider5/jwplayer.js
* test/HLSProvider5/player.swf
* test/HLSProvider6/jwplayer.js
* test/HLSProvider6/jwplayer.html5.js
* test/HLSProvider6/jwplayer.flash.swf

You can use, modify, copy, and distribute them as long as it's for non-commercial use, you provide attribution, and share under a similar license.

The license summary and full text can be found here: [CC BY-NC-SA 3.0](http://creativecommons.org/licenses/by-nc-sa/3.0/ "CC BY-NC-SA 3.0")

**All other files (source code and executable) are governed by MPL 2.0** (Mozilla Public License 2.0).
The license full text can be found here: [MPL 2.0](http://www.mozilla.org/MPL/2.0/)

###Donate
If you'd like to support future development and new product features, please make a donation via PayPal - a secure online banking service.These donations are used to cover my ongoing expenses - web hosting, domain registrations, and software and hardware purchases.

[![Donate](https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=463RB2ALVXJLA)