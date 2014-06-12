package org.mangui.HLS.streaming {


    import org.mangui.HLS.*;
    import org.mangui.HLS.parsing.*;
    import org.mangui.HLS.utils.*;
    import flash.events.*;
    import flash.net.*;
    import flash.utils.*;


    /** Loader for hls manifests. **/
    public class ManifestLoader {


        /** Reference to the hls framework controller. **/
        private var _hls:HLS;
        /** Array with levels. **/
        private var _levels:Array = [];
        /** Object that fetches the manifest. **/
        private var _urlloader:URLLoader;
        /** Link to the M3U8 file. **/
        private var _url:String;
        /** are all playlists filled ? **/
        private var _canStart:Boolean;
        /** Timeout ID for reloading live playlists. **/
        private var _timeoutID:Number;
        /** Streaming type (live, ondemand). **/
        private var _type:String;
        /** last reload manifest time **/
        private var _reload_playlists_timer:uint;
        /** current level **/
        private var _current_level:Number;
        /** current level **/
        private var _load_in_progress:Boolean = false;

        /** Setup the loader. **/
        public function ManifestLoader(hls:HLS) {
            _hls = hls;
            _hls.addEventListener(HLSEvent.STATE,_stateHandler);
            _hls.addEventListener(HLSEvent.QUALITY_SWITCH,_levelSwitchHandler);
            _levels = [];
            _urlloader = new URLLoader();
            _urlloader.addEventListener(Event.COMPLETE,_loaderHandler);
            _urlloader.addEventListener(IOErrorEvent.IO_ERROR,_errorHandler);
            _urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,_errorHandler);
        };


        /** Loading failed; return errors. **/
        private function _errorHandler(event:ErrorEvent):void {
            var txt:String;
            if(event is SecurityErrorEvent) {
                txt = "Cannot load M3U8: crossdomain access denied";
            } else if (event is IOErrorEvent) {
                Log.txt("I/O Error while trying to load Playlist, retry in 2s");
                _timeoutID = setTimeout(_loadPlaylist,2000);
            } else {
               txt = "Cannot load M3U8: "+event.text;
            }
            _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR,txt));
        };

        /** Return the current manifest. **/
        public function getLevels():Array {
            return _levels;
        };


        /** Return the stream type. **/
        public function getType():String {
            return _type;
        };


        /** Load the manifest file. **/
        public function load(url:String):void {
            _url = url;
            _levels = [];
            _current_level = 0;
            _canStart = false;
            _reload_playlists_timer = getTimer();
            _urlloader.load(new URLRequest(_url));
        };


        /** Manifest loaded; check and parse it **/
        private function _loaderHandler(event:Event):void {
            _parseManifest(String(event.target.data));
        };
        
        /** parse a playlist **/
        private function _parsePlaylist(string:String,url:String,index:Number):void {
        	Log.txt("BJA _parsePlaylist called: string " + string +" url " + url + " index " + index);
            if(string != null && string.length != 0) {
               Log.txt("BJA Try getContinuityIndex ");            
               var continuity_index:Number = _levels[index].getContinuityIndex();
               Log.txt("BJA highest continuity index: " + continuity_index );
               var frags:Array = Manifest.getFragments(string,continuity_index,url);
               
               _levels[index].updateFragments(frags);
               _levels[index].targetduration = Manifest.getTargetDuration(string);
            }
  
            // Check whether the stream is live or not finished yet
            if(Manifest.hasEndlist(string)) {
                _type = HLSTypes.VOD;
            } else {
                _type = HLSTypes.LIVE;
                var timeout:Number = Math.max(100,_reload_playlists_timer + 1000*_levels[index].averageduration - getTimer());
                Log.txt("Level " + index + " Live Playlist parsing finished: reload in " + timeout + " ms");
                _timeoutID = setTimeout(_loadPlaylist,timeout);
            }
            if (!_canStart && (_canStart = (_levels[index].fragments.length >= 2  ))) {
               Log.txt("first level filled with at least 2 fragments, notify event");
               _hls.dispatchEvent(new HLSEvent(HLSEvent.MANIFEST_LOADED,_levels));
            }
            _hls.dispatchEvent(new HLSEvent(HLSEvent.LEVEL_UPDATED,index));
            _load_in_progress = false;
        };

        /** Parse First Level Playlist **/
        private function _parseManifest(string:String):void {
            // Check for M3U8 playlist or manifest.
            if(string.indexOf(Manifest.HEADER) == 0) {
               //1 level playlist, create unique level and parse playlist
                if(string.indexOf(Manifest.FRAGMENT) > 0) {
                    var level:Level = new Level();
                    level.url = _url;
                    _levels.push(level);
                    Log.txt("1 Level Playlist, load it");
                    _parsePlaylist(string,_url,0);
                } else if(string.indexOf(Manifest.LEVEL) > 0) {
                  //adaptative playlist, extract levels from playlist, get them and parse them
                  _levels = Manifest.extractLevels(string,_url);
                  _loadPlaylist();
                }
            } else {
                var message:String = "Manifest is not a valid M3U8 file" + _url;
                _hls.dispatchEvent(new HLSEvent(HLSEvent.ERROR,message));
            }
        };

        /** load/reload active M3U8 playlist **/
        private function _loadPlaylist():void {
            _load_in_progress = true;
            _reload_playlists_timer = getTimer();
            // load active M3U8 playlist only
            new Manifest().loadPlaylist(_levels[_current_level].url,_parsePlaylist,_errorHandler,_current_level);
        };

        /** When level switch occurs, assess the need of (re)loading new level playlist **/
        public function _levelSwitchHandler(event:HLSEvent):void {
            _current_level = event.level;
            if(_load_in_progress == false && (_type == HLSTypes.LIVE || _levels[_current_level].fragments.length == 0)) {
              Log.txt("switch Level, (Re)Load Playlist");
              clearTimeout(_timeoutID);
              _timeoutID = setTimeout(_loadPlaylist,0);
            }
        };

        /** When the framework idles out, reloading is cancelled. **/
        public function _stateHandler(event:HLSEvent):void {
            if(event.state == HLSStates.IDLE) {
                clearTimeout(_timeoutID);
            }
        };
    }
}