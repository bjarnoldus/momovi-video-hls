package { 


    import org.mangui.HLS.*;
    import flash.display.*;
    import flash.events.*;
    import flash.net.*;
    import flash.external.ExternalInterface;
    import flash.geom.Rectangle;
    import flash.media.Video;
    import flash.media.SoundTransform;
    import flash.media.StageVideo;
    import flash.media.StageVideoAvailability;
    import flash.utils.setTimeout;    


    public class ChromelessPlayer extends Sprite {


        /** reference to the framework. **/
        private var _hls:HLS;
        /** Sheet to place on top of the video. **/
        private var _sheet:Sprite;
        /** Reference to the video element. **/
        private var _video:StageVideo;
        /** Javascript callbacks. **/
        private var _callbacks:Object = {};

        /** Initialization. **/
        public function ChromelessPlayer():void {
            // Set stage properties
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.fullScreenSourceRect = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
            stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, _onStageVideoState);
            // Draw sheet for catching clicks
            _sheet = new Sprite();
            _sheet.graphics.beginFill(0x000000,0);
            _sheet.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
            _sheet.addEventListener(MouseEvent.CLICK,_clickHandler);
            _sheet.buttonMode = true;
            addChild(_sheet);
            // Connect getters to JS.
            ExternalInterface.addCallback("getLevel",_getLevel);
            ExternalInterface.addCallback("getLevels",_getLevels);
            ExternalInterface.addCallback("getMetrics",_getMetrics);
            ExternalInterface.addCallback("getPosition",_getPosition);
            ExternalInterface.addCallback("getState",_getState);
            ExternalInterface.addCallback("getType",_getType);
            // Connect calls to JS.
            ExternalInterface.addCallback("play",_play);
            ExternalInterface.addCallback("pause",_pause);
            ExternalInterface.addCallback("resume",_resume);
            ExternalInterface.addCallback("seek",_seek);
            ExternalInterface.addCallback("stop",_stop);
            ExternalInterface.addCallback("volume",_volume);
            ExternalInterface.addCallback("setLevel",_setLevel);
            setTimeout(_pingJavascript,50);
        };

        /** Notify javascript the framework is ready. **/
        private function _pingJavascript():void {
            ExternalInterface.call("onHLSReady",ExternalInterface.objectID);
        };

        /** Forward events from the framework. **/
        private function _completeHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onComplete");
            }
        };
        private function _errorHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onError",event.message);
            }
        };
        
        private function _fragmentHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onFragment",event.metrics.bandwidth,event.metrics.level,event.metrics.screenwidth);
            }
        };
        
        private function _manifestHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onManifest");
            }
            _seek(0);
        };
        private function _mediaTimeHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onPosition",event.mediatime.position,event.mediatime.duration);
            }
        };
        private function _stateHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onState",event.state);
            }
        };
        private function _switchHandler(event:HLSEvent):void {
            if (ExternalInterface.available) {
                ExternalInterface.call("onSwitch",event.level);
            }
        };

        /** Javascript getters. **/
        private function _getLevel():Number { return _hls.getLevel(); };
        private function _getLevels():Array { return _hls.getLevels(); };
        private function _getMetrics():Object { return _hls.getMetrics(); };
        private function _getPosition():Number { return _hls.getPosition(); };
        private function _getState():String { return _hls.getState(); };
        private function _getType():String { return _hls.getType(); };


        /** Javascript calls. **/
        private function _play(url:String,start:Number=0):void { _hls.play(url,start); };
        private function _pause():void { _hls.stream.pause(); };
        private function _resume():void { _hls.stream.resume(); };
        private function _seek(position:Number):void { _hls.stream.seek(position); };
        private function _stop():void { _hls.stream.close(); };
        private function _volume(percent:Number):void { _hls.stream.soundTransform = new SoundTransform(percent/100);};
        private function _setLevel(level:Number):void { _hls.setPlaybackQuality(level);};


        /** Mouse click handler. **/
        private function _clickHandler(event:MouseEvent):void {
            if(stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE || stage.displayState==StageDisplayState.FULL_SCREEN) {
                stage.displayState = StageDisplayState.NORMAL;
            } else {
                stage.displayState = StageDisplayState.FULL_SCREEN;
            }
            _hls.setWidth(stage.stageWidth);
        };


        /** StageVideo detector. **/
        private function _onStageVideoState(event:StageVideoAvailabilityEvent):void {
            var available:Boolean = (event.availability == StageVideoAvailability.AVAILABLE);
            if (available && stage.stageVideos.length > 0) {
              _video = stage.stageVideos[0];
              _video.viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
              _hls = new HLS();
              _video.attachNetStream(_hls.stream);
            } else {
              var video:Video = new Video(stage.stageWidth, stage.stageHeight);
              addChild(video);
              _hls = new HLS();
              video.smoothing = true;
              video.attachNetStream(_hls.stream);
            }
            _hls.setWidth(stage.stageWidth);
            _hls.addEventListener(HLSEvent.PLAYBACK_COMPLETE,_completeHandler);
            _hls.addEventListener(HLSEvent.ERROR,_errorHandler);
            _hls.addEventListener(HLSEvent.FRAGMENT_LOADED,_fragmentHandler);
            _hls.addEventListener(HLSEvent.MANIFEST_LOADED,_manifestHandler);
            _hls.addEventListener(HLSEvent.MEDIA_TIME,_mediaTimeHandler);
            _hls.addEventListener(HLSEvent.STATE,_stateHandler);
            _hls.addEventListener(HLSEvent.QUALITY_SWITCH,_switchHandler);
        };


    }


}