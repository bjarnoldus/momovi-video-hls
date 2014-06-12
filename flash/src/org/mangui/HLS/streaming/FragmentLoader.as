package org.mangui.HLS.streaming {


    import org.mangui.HLS.*;
    import org.mangui.HLS.muxing.*;
    import org.mangui.HLS.parsing.*;
    import org.mangui.HLS.streaming.*;
    import org.mangui.HLS.utils.*;

    import flash.events.*;
    import flash.net.*;
    import flash.text.engine.TabStop;
    import flash.utils.ByteArray;
    import flash.utils.Timer;

    /** Class that fetches fragments. **/
    public class FragmentLoader {
        /** Reference to the HLS controller. **/
        private var _hls:HLS;
        /** Bandwidth of the last loaded fragment **/
        private var _last_bandwidth:int = 0;
        /** fetch time of the last loaded fragment **/
        private var _last_fetch_duration:Number = 0;
        /** duration of the last loaded fragment **/
        private var _last_segment_duration:Number = 0;
        /** duration of the last loaded fragment **/
        private var _last_segment_start_pts:Number = 0;
        /** end of the last loaded fragment FIX DE -100 **/
        private var _last_segment_end_pts:Number = -100;
        /** continuity counter of the last fragment load. **/
        private var _last_segment_continuity_counter:Number = 0;
        /** Callback for passing forward the fragment tags. **/
        private var _callback:Function;
        /** sequence number that's currently loading. **/
        private var _seqnum:Number;
        /** Quality level of the last fragment load. **/
        private var _level:int = 0;
        /* overrided quality_manual_level level */
        private var _manual_level:int = -1;
        /** Reference to the manifest levels. **/
        private var _levels:Array;
        /** Util for loading the fragment. **/
        private var _urlstreamloader:URLStream;
         /** Data read from stream loader **/
        private var _loaderData:ByteArray;
        /** Time the loading started. **/
        private var _started:Number;
        /** Did the stream switch quality levels. **/
        private var _switchlevel:Boolean;
        /** Did a discontinuity occurs in the stream **/
        private var _hasDiscontinuity:Boolean;
        /** Width of the stage. **/
        private var _width:Number = 480;
        /** The current TS packet being read **/
        private var _ts:TS;
        /** The current tags vector being created as the TS packet is read **/
        private var _tags:Vector.<Tag>;
        /** switch up threshold **/
        private var _switchup:Array = null;
        /** switch down threshold **/
        private var _switchdown:Array = null;
        /* variable to deal with IO Error retry */
        private var _bIOError:Boolean=false;
        private var _nIOErrorDate:Number=0;
        /** boolean to track playlist PTS loading/loaded state */
        private var _playlist_pts_loading:Boolean=false;
        private var _playlist_pts_loaded:Boolean=false;

        /** Create the loader. **/
        public function FragmentLoader(hls:HLS):void {
            _hls = hls;
            _hls.addEventListener(HLSEvent.MANIFEST_LOADED, _levelsHandler);
            _urlstreamloader = new URLStream();
            _urlstreamloader.addEventListener(IOErrorEvent.IO_ERROR, _errorHandler);
            //_urlstreamloader.addEventListener(HTTPStatusEvent.HTTP_STATUS, _httpStatusHandler);
            _urlstreamloader.addEventListener(Event.COMPLETE, _completeHandler);
        };

         private function _httpStatusHandler(event:HTTPStatusEvent):void {
            //Log.txt("httpStatusHandler: " + event);
          }

        /** Fragment load completed. **/
        private function _completeHandler(event:Event):void {
            //Log.txt("loading completed");
            _bIOError = false;
            // Calculate bandwidth
            _last_fetch_duration = (new Date().valueOf() - _started);
            _last_bandwidth = Math.round(_urlstreamloader.bytesAvailable * 8000 / _last_fetch_duration);
			// Collect stream loader data
			if( _urlstreamloader.bytesAvailable > 0 ) {
				_loaderData = new ByteArray();
				_urlstreamloader.readBytes(_loaderData,0,0);
			}
            // Extract tags.
			_tags = new Vector.<Tag>();
            _parseTS();
        };


		/** Kill any active load **/
		public function clearLoader():void {
			if(_urlstreamloader.connected) {
				_urlstreamloader.close();
			}
			_ts = null;
			_tags = null;
      _bIOError = false;
		}


        /** Catch IO and security errors. **/
        private function _errorHandler(event:ErrorEvent):void {
            /* usually, errors happen in two situations :
            - bad networks  : in that case, the second or third reload of URL should fix the issue
            - live playlist : when we are trying to load an out of bound fragments : for example,
                              the playlist on webserver is from SN [51-61]
                              the one in memory is from SN [50-60], and we are trying to load SN50.
                              we will keep getting 404 error if the HLS server does not follow HLS spec,
                              which states that the server should keep SN50 during EXT-X-TARGETDURATION period
                              after it is removed from playlist
                              in the meantime, ManifestLoader will keep refreshing the playlist in the background ...
                              so if the error still happens after EXT-X-TARGETDURATION, it means that there is something wrong
                              we need to report it.
            */

            if(_bIOError == false) {
              _bIOError=true;
              _nIOErrorDate = new Date().valueOf();
            } else if((new Date().valueOf() - _nIOErrorDate) > 1000*getSegmentAverageDuration() ) {
              _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR, "I/O Error"));
            }
        };

        public function needReload():Boolean {
          return (_bIOError || _playlist_pts_loaded);
        };

        /** Get the quality level for the next fragment. **/
        public function getLevel():Number {
            return _level;
        };

        /** Get the suggested buffer length from rate adaptation algorithm **/
        public function getBufferLength():Number {
            if(_levels != null) {
               return _levels[_level].averageduration*Math.max((_levels[_levels.length-1].bitrate/_levels[0].bitrate),6);
            } else {
               return 10;
            }
        };

        /** Get the current QOS metrics. **/
        public function getMetrics():Object {
            return { bandwidth:_last_bandwidth, level:_level, screenwidth:_width };
        };

        /** Get the playlist duration **/
        public function getPlayListDuration():Number {
            return _levels[_level].duration;
        };

        /** Get segment average duration **/
        public function getSegmentAverageDuration():Number {
            return _levels[_level].averageduration;
        };

       private function updateLevel(buffer:Number):void {
          var level:Number;
          /* in case IO Error has been raised, stick to same level */
          if(_bIOError == true) {
            level = _level;
          /* in case fragment was loaded for PTS analysis, stick to same level */
          } else if(_playlist_pts_loaded == true) {
            _playlist_pts_loaded = false;
            level = _level;
            /* in case we are switching levels (waiting for playlist to reload), stick to same level */
          } else if(_switchlevel == true) {
            level = _level;
          } else if (_manual_level == -1 ) {
            level = _getnextlevel(buffer);
          } else {
            level = _manual_level;
          }
          if(level != _level) {
              _level = level;
              _switchlevel = true;
              _hls.dispatchEvent(new HLSEvent(HLSEvent.QUALITY_SWITCH,_level));
          }
       }

        public function loadfirstfragment(position:Number,callback:Function):Number {
        //Log.txt("loadfirstfragment(" + position + ")");
             if(_urlstreamloader.connected) {
                _urlstreamloader.close();
            }
            _switchlevel = true;
            updateLevel(0);
            // reset IO Error when loading new fragment
            _bIOError = false;

            if (_hls.getType() == HLSTypes.LIVE) {
               var seek_position:Number;
               /* follow HLS spec :
                  If the EXT-X-ENDLIST tag is not present
                  and the client intends to play the media regularly (i.e. in playlist
                  order at the nominal playback rate), the client SHOULD NOT
                  choose a segment which starts less than three target durations from
                  the end of the Playlist file */
               var maxLivePosition:Number = Math.max(0,_levels[_level].duration -3*_levels[_level].averageduration);
               if (position == 0) {
                  // seek 3 fragments from end
                  seek_position = maxLivePosition;
               } else {
                  seek_position = Math.min(position,maxLivePosition);
               }
               Log.txt("loadfirstfragment : requested position:" + position + ",seek position:"+seek_position);
               position = seek_position;
            }
            var seqnum:Number= _levels[_level].getSeqNumBeforePosition(position);
            _callback = callback;
            _started = new Date().valueOf();
            var frag:Fragment = _levels[_level].getFragmentfromSeqNum(seqnum);
            _seqnum = seqnum;
            _hasDiscontinuity = true;
            _last_segment_continuity_counter = frag.continuity;
            //Log.txt("Loading SN "+ _seqnum +  " of [" + (_levels[_level].start_seqnum) + "," + (_levels[_level].end_seqnum) + "],level "+ _level + ",URL=" + frag.url);
            Log.txt("Loading SN "+ _seqnum +  " of [" + (_levels[_level].start_seqnum) + "," + (_levels[_level].end_seqnum) + "],level "+ _level);
            try {
               _urlstreamloader.load(new URLRequest(frag.url));
            } catch (error:Error) {
                _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR, error.message));
            }
            return 0;
        }

        /** Load a fragment **/
        public function loadnextfragment(buffer:Number,callback:Function):Number {
          //Log.txt("loadnextfragment(buffer):(" + buffer+ ")");

            if(_urlstreamloader.connected) {
                _urlstreamloader.close();
            }
            updateLevel(buffer);
            // reset IO Error when loading new fragment
            _bIOError = false;

            /* According to HLS spec,
              Each variant stream MUST present the same content, including stream discontinuities. 
              here we try to retrieve the last seqnum of fragment, in new playlist
              new seqnum should be last seqnum + 1 */
            var last_seqnum:Number = _levels[_level].getSeqNumNearestPTS(_last_segment_start_pts,_last_segment_continuity_counter);
            Log.txt("loadnextfragment : getSeqNumNearestPTS("+_last_segment_start_pts+","+_last_segment_continuity_counter+")="+last_seqnum);
            if (last_seqnum == -1) {
              /* we need to perform PTS analysis on fragments from same continuity range 
              get first fragment from playlist matching with criteria and load pts */
              last_seqnum = _levels[_level].getFirstSeqNumfromContinuity(_last_segment_continuity_counter);
              if (last_seqnum == Number.NEGATIVE_INFINITY) {
                // playlist not yet received
                return 1;
              }
              /* when probing PTS, take second fragment from continuity counter */
              _seqnum=Math.min(last_seqnum+1,_levels[_level].getLastSeqNumfromContinuity(_last_segment_continuity_counter));
              _playlist_pts_loading = true;
              Log.txt("loadnextfragment : continuity start pts undefined, get PTS from segment:"+_seqnum);
            } else if(last_seqnum == _levels[_level].end_seqnum) {
              // notify last fragment loaded event, and return 1
              if (_hls.getType() == HLSTypes.VOD)
                _hls.dispatchEvent(new HLSEvent(HLSEvent.LAST_VOD_FRAGMENT_LOADED));
              return 1;
            } else {
              _seqnum = last_seqnum + 1;
            }
            _callback = callback;
            _started = new Date().valueOf();
            var frag:Fragment = _levels[_level].getFragmentfromSeqNum(_seqnum);
            _hasDiscontinuity = (frag.continuity != _last_segment_continuity_counter);
            _last_segment_continuity_counter = frag.continuity;
            
            //Log.txt("Loading SN "+ _seqnum +  " of [" + (_levels[_level].start_seqnum) + "," + (_levels[_level].end_seqnum) + "],level "+ _level + ",URL=" + frag.url);
            Log.txt("Loading SN "+ _seqnum +  " of [" + (_levels[_level].start_seqnum) + "," + (_levels[_level].end_seqnum) + "],level "+ _level);
            try {
               _urlstreamloader.load(new URLRequest(frag.url));
            } catch (error:Error) {
                _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR, error.message));
            }
            return 0;
        };

        /** Store the manifest data. **/
        private function _levelsHandler(event:HLSEvent):void {
            _levels = event.levels;
            _level = 0;
            _initlevelswitch();
        };
        
        /** Parse a TS fragment. **/
        private function _parseTS():void {
          //if(_switchlevel) {
            _ts = new TS(_loaderData);
            _ts.addEventListener(TS.READCOMPLETE, _readHandler);
            _ts.startReading();
          //} else {
           // _ts.addData(_loaderData);
          //}
        };


    /** Handles the actual reading of the TS fragment **/
    private function _readHandler(e:Event):void {
       var min_pts:Number = Number.POSITIVE_INFINITY;
       var max_pts:Number = Number.NEGATIVE_INFINITY;
       // Tags used for PTS analysis
       var ptsTags:Vector.<Tag>;

       if (_ts.audioTags.length > 0) {
        ptsTags = _ts.audioTags;
      } else {
      // no audio, video only stream
        ptsTags = _ts.videoTags;
      }

      for(var k:Number=0; k < ptsTags.length; k++) {
         min_pts = Math.min(min_pts,ptsTags[k].pts);
         max_pts = Math.max(max_pts,ptsTags[k].pts);
      }

      Log.txt("BJA: Sequence Number " + _seqnum +  " min_PTS: " + min_pts + " max_PTS: " + max_pts);
	  if(_last_segment_end_pts > min_pts){
	  		Log.txt("BJA: Detected PTS discontinuity (_last_segment_end_pts: " +_last_segment_end_pts+ ") (min_pts: "+ min_pts + ")");
	  		_hasDiscontinuity = true;
			_last_segment_continuity_counter=_last_segment_continuity_counter+1;
			_levels[_level].updateContinuityFragmentsFromSeqNum(_seqnum,_last_segment_continuity_counter);
	  }


       /* in case we are loading first fragment of a playlist, just retrieve
       minimum PTS value to synchronize playlist PTS / sequence number.
       then return. this will force the Buffer Manager to reload the
       fragment at right offset */
       if(_playlist_pts_loading == true) {
         _levels[_level].updatePTS(_seqnum,min_pts,max_pts);
         Log.txt("Loaded  SN " + _seqnum +  " of [" + (_levels[_level].start_seqnum) + "," + (_levels[_level].end_seqnum) + "],level "+ _level + " min/max PTS:" + min_pts +"/" + max_pts);
         _playlist_pts_loading = false;
         _playlist_pts_loaded = true;
         return;
       }

      // Save codecprivate when not available.
      if(!_levels[_level].avcc && !_levels[_level].adif) {
        _levels[_level].avcc = _ts.getAVCC();
        _levels[_level].adif = _ts.getADIF();
      }
      // Push codecprivate tags only when switching.
      if(_switchlevel) {
        if (_ts.videoTags.length > 0) {
          // Audio only file don't have videoTags[0]
          var avccTag:Tag = new Tag(Tag.AVC_HEADER,_ts.videoTags[0].pts,_ts.videoTags[0].dts,true);
          avccTag.push(_levels[_level].avcc,0,_levels[_level].avcc.length);
          _tags.push(avccTag);
        }
        if (_ts.audioTags.length > 0) {
          if(_ts.audioTags[0].type == Tag.AAC_RAW) {
            var adifTag:Tag = new Tag(Tag.AAC_HEADER,_ts.audioTags[0].pts,_ts.audioTags[0].dts,true);
            adifTag.push(_levels[_level].adif,0,2)
            _tags.push(adifTag);
          }
        }
      }
      // Push regular tags into buffer.
      for(var i:Number=0; i < _ts.videoTags.length; i++) {
        _tags.push(_ts.videoTags[i]);
      }
      for(var j:Number=0; j < _ts.audioTags.length; j++) {
        _tags.push(_ts.audioTags[j]);
      }

      // change the media to null if the file is only audio.
      if(_ts.videoTags.length == 0) {
        _hls.dispatchEvent(new HLSEvent(HLSEvent.AUDIO_ONLY));
      }

      try {
         _switchlevel = false;
         _last_segment_duration = max_pts-min_pts;
         _last_segment_start_pts = min_pts;
         _last_segment_end_pts = max_pts;
         
         Log.txt("Loaded  SN " + _seqnum +  " of [" + (_levels[_level].start_seqnum) + "," + (_levels[_level].end_seqnum) + "],level "+ _level + " m/M/delta PTS:" + min_pts +"/" + max_pts + "/" + _last_segment_duration);
         var start_offset:Number = _levels[_level].updatePTS(_seqnum,min_pts,max_pts);
         Log.txt("start_offset:"+ start_offset);
         _callback(_tags,min_pts,max_pts,_hasDiscontinuity,start_offset);
         _hls.dispatchEvent(new HLSEvent(HLSEvent.FRAGMENT_LOADED, getMetrics()));
      } catch (error:Error) {
        _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR, error.toString()));
      }
    }

    /* initialize level switching heuristic tables */
    private function _initlevelswitch():void {
      var i:Number;
      var maxswitchup:Number=0;
      var minswitchdwown:Number=Number.MAX_VALUE;
      _switchup = new Array(_levels.length);
      _switchdown = new Array(_levels.length);
      
      for(i=0 ; i < _levels.length-1; i++) {
         _switchup[i] = (_levels[i+1].bitrate - _levels[i].bitrate) / _levels[i].bitrate;
         maxswitchup = Math.max(maxswitchup,_switchup[i]);
      }
      for(i=0 ; i < _levels.length-1; i++) {
         _switchup[i] = Math.min(maxswitchup,2*_switchup[i]);
         //Log.txt("_switchup["+i+"]="+_switchup[i]);
      }
      
      
      for(i = 1; i < _levels.length; i++) {
         _switchdown[i] = (_levels[i].bitrate - _levels[i-1].bitrate) / _levels[i].bitrate;
         minswitchdwown  =Math.min(minswitchdwown,_switchdown[i]);
      }
      for(i = 1; i < _levels.length; i++) {
         _switchdown[i] = Math.max(2*minswitchdwown,_switchdown[i]);
         //Log.txt("_switchdown["+i+"]="+_switchdown[i]);
      }          
    }

        /** Update the quality level for the next fragment load. **/
        private function _getnextlevel(buffer:Number):Number {
         var i:Number;

            var level:Number = -1;
            // Select the lowest non-audio level.
            for(i = 0; i < _levels.length; i++) {
                if(!_levels[i].audio) {
                    level = i;
                    break;
                }
            }
            if(level == -1) {
                Log.txt("No other quality levels are available");
                return -1;
            }
            if(_last_fetch_duration == 0 || _last_segment_duration == 0) {
               return 0;
            }
            var fetchratio:Number = _last_segment_duration/_last_fetch_duration;
            var bufferratio:Number = 1000*buffer/_last_segment_duration;
            //Log.txt("fetchratio:" + fetchratio);
            //Log.txt("bufferratio:" + bufferratio);

            /* to switch level up :
              fetchratio should be greater than switch up condition,
               but also, when switching levels, we might have to load two fragments :
                - first one for PTS analysis,
                - second one for NetStream injection
               the condition (bufferratio > 2*_levels[_level+1].bitrate/_last_bandwidth)
               ensures that buffer time is bigger than than the time to download 2 fragments from _level+1, if we keep same bandwidth
            */
            if((_level < _levels.length-1) && (fetchratio > (1+_switchup[_level])) && (bufferratio > 2*_levels[_level+1].bitrate/_last_bandwidth)) {
               //Log.txt("fetchratio:> 1+_switchup[_level]="+(1+_switchup[_level]));
               Log.txt("switch to level " + (_level+1));
                  //level up
                  return (_level+1);
            }
            /* to switch level down :
              fetchratio should be smaller than switch down condition,
               or buffer time is too small to retrieve one fragment with current level
            */

            else if(_level > 0 &&((fetchratio < (1-_switchdown[_level])) || (bufferratio < 1)) ) {
                  //Log.txt("bufferratio < 2 || fetchratio: < 1-_switchdown[_level]="+(1-_switchdown[_level]));
                  /* find suitable level matching current bandwidth, starting from current level
                     when switching level down, we also need to consider that we might need to load two fragments.
                     the condition (bufferratio > 2*_levels[j].bitrate/_last_bandwidth)
                    ensures that buffer time is bigger than than the time to download 2 fragments from level j, if we keep same bandwidth
                  */
                  for(var j:Number = _level; j > 0; j--) {
                     if( _levels[j].bitrate <= _last_bandwidth && (bufferratio > 2*_levels[j].bitrate/_last_bandwidth)) {
                          Log.txt("switch to level " + j);
                          return j;
                      }
                  }
                  Log.txt("switch to level 0");
                  return 0;
               }
            return _level;
        }

        /** Provide the loader with screen width information. **/
        public function setWidth(width:Number):void {
            _width = width;
        }

        /* update playback quality level */
        public function setPlaybackQuality(level:Number):void {
           _manual_level = level;
        };
    }
}