package org.mangui.HLS {


import org.mangui.HLS.streaming.*;
import org.mangui.HLS.utils.*;

import flash.events.*;
import flash.net.NetStream;
import flash.net.NetConnection;

    /** Class that manages the streaming process. **/
    public class HLS extends EventDispatcher {
        /** The quality monitor. **/
        private var _fragmentLoader:FragmentLoader;
        /** The manifest parser. **/
        private var _manifestLoader:ManifestLoader;
        /** HLS NetStream **/
        private var _hlsNetStream:HLSNetStream;

	private var _client:Object = {};

        /** Create and connect all components. **/
    public function HLS():void {
            var connection:NetConnection = new NetConnection();
            connection.connect(null);
            _manifestLoader = new ManifestLoader(this);
            _fragmentLoader = new FragmentLoader(this);
            _hlsNetStream = new HLSNetStream(connection,this, _fragmentLoader);
        };


        /** Forward internal errors. **/
        override public function dispatchEvent(event:Event):Boolean {
            if(event.type == HLSEvent.ERROR) {
                Log.txt(HLSEvent(event).message);
                _hlsNetStream.close();
            }
            return super.dispatchEvent(event);
        };


        /** Return the current quality level. **/
        public function getLevel():Number {
            return _fragmentLoader.getLevel();
        };


        /** Return the list with bitrate levels. **/
        public function getLevels():Array {
            return _manifestLoader.getLevels();
        };


        /** Return the list with switching metrics. **/
        public function getMetrics():Object {
            return _fragmentLoader.getMetrics();
        };


        /** Return the current playback position. **/
        public function getPosition():Number {
            return _hlsNetStream.getPosition();
        };


        /** Return the current playback position. **/
        public function getState():String {
            return _hlsNetStream.getState();
        };


        /** Return the type of stream. **/
        public function getType():String {
            return _manifestLoader.getType();
        };


        /** Start playing an new HLS stream. **/
        public function play(url:String,start:Number=0):void {
            _hlsNetStream.close();
            //_playbackStartPosition = start;
            _manifestLoader.load(url);
        };  

        /** Update the screen width. **/
        public function setWidth(width:Number):void {
            _fragmentLoader.setWidth(width);
        };

        /* update playback quality level */
        public function setPlaybackQuality(level:Number):void {
            _fragmentLoader.setPlaybackQuality(level);
            _hlsNetStream.seek(_hlsNetStream.getPosition());
        };
    public function get stream():NetStream {
        return _hlsNetStream;
    }
    public function get client():Object {
        return _client;
    }
    public function set client(value:Object):void {
        _client = value;
    }
}
;
}