# momovi.com HTML5 HLS video player

The momovi.com video player ([demo](https://momovi.com/static/player/momovi.com-hls-video-player/player.html)) is a free to use, open source HTML5 HLS video player.
Supported platforms:
- all major browsers, including Safari, Chrome, FireFox, Internet Explorer;
- Tablets, including iPad and Android 4.2+
- Smart phones, including iPhone, Android 4.2+ and Black Berry.

## Usage
  - Download the video player from [momovi.com video hls player](https://momovi.com/opensource/momovi-video-hls)
  - Unzip, extract and upload the content to your server
  - Configure the HTML to your needs

## Features

  - VoD & Live playlists
  - Adaptive streaming
  - Discontinuity support of video tracks
  - Supported by major desktop browsers, iOS, black berry and android
  - Configurable seeking method on VoD
    - Accurate seeking to exact requested position
    - Key frame based seeking (nearest key frame)
    - Segment based seeking (beginning of segment)
  - AES-128 decryption 
  - Buffer progress report
  - Error resilience
    - Retry mechanism on I/O errors 
    - Recovery mechanism on badly segmented TS streams

### Supported M3U8 tags

  - `#EXTM3U`
  - `#EXTINF`
  - `#EXT-X-STREAM-INF` (Multiple bitrate)
  - `#EXT-X-ENDLIST` (VoD / Live playlist)
  - `#EXT-X-MEDIA-SEQUENCE`
  - `#EXT-X-TARGETDURATION`
  - `#EXT-X-DISCONTINUITY` (VoD and Live playlist)
  - `#EXT-X-DISCONTINUITY-SEQUENCE` (VoD and Live playlist)
  - `#EXT-X-PROGRAM-DATE-TIME` (optional, used to synchronize time-stamps and sequence number when switching from one level to another)
  - `#EXT-X-KEY` (AES-128 method supported only)
  - `#EXT-X-BYTERANGE`



## Contributing
The momovi.com video player is a free and open source library, and we appreciate any help you're willing to give. Contact us for bugs, feature requests and other questions at opensource@momovi.com .

## License
The momovi.com video player is based on two open source projects, released under different licences
  
  - HTML5 video player:
    - hls flash integration - Copyright 2014 momovi.com
    - original videojs - Copyright 2013 Brightcove, Inc.

  - HLS Flash player plugin:
    - discontinuity tag - Copyright (c) 2014 momovi.com
    - original - Copyright (c) 2013 Guillaume du Pontavice (https://github.com/mangui/HLSprovider)





