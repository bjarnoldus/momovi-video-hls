package org.mangui.HLS {


    import flash.events.Event;


    /** Event fired when an error prevents playback. **/
    public class HLSEvent extends Event {


        /** Identifier for a playback complete event. **/
        public static const PLAYBACK_COMPLETE:String = "hlsEventPlayBackComplete";
        /** Identifier for a playback error event. **/
        public static const ERROR:String = "hlsEventError";
        /** Identifier for a fragment load event. **/
        public static const FRAGMENT_LOADED:String = "hlsEventFragmentLoaded";
        /** Identifier when last fragment of playlist has been loaded **/
        public static const LAST_VOD_FRAGMENT_LOADED:String = "hlsEventLastFragmentLoaded";
        /** Identifier for a manifest (re)load event. **/
        public static const MANIFEST_LOADED:String = "hlsEventManifest";
        /** Identifier for a playback media time change event. **/
        public static const MEDIA_TIME:String = "hlsEventMediaTime";
        /** Identifier for a playback state switch event. **/
        public static const STATE:String = "hlsEventState";
        /** Identifier for a quality level switch event. **/
        public static const QUALITY_SWITCH:String = "hlsEventQualitySwitch";
        /** Identifier for a level updated event (playlist loaded) **/
        public static const LEVEL_UPDATED:String = "hlsEventLevelUpdated";
        /** Identifier for a Level Time Stamp updated event (PTS updated) **/
        public static const LEVEL_PTS_UPDATED:String = "hlsEventLevelPTSUpdated";
        /** Identifier for a audio only fragment **/        
        public static const AUDIO_ONLY:String = "audioOnly";

        /** The current quality level. **/
        public var level:Number;
        /** The list with quality levels. **/
        public var levels:Array;
        /** The error message. **/
        public var message:String;
        /** The current QOS metrics. **/
        public var metrics:Object;
        /** The time position. **/
        public var mediatime:Object;
        /** The new playback state. **/
        public var state:String;


        /** Assign event parameter and dispatch. **/
        public function HLSEvent(type:String, parameter:*=null) {
            switch(type) {
                case HLSEvent.ERROR:
                    message = parameter as String;
                    break;
                case HLSEvent.FRAGMENT_LOADED:
                    metrics = parameter as Object;
                    break;
                case HLSEvent.MANIFEST_LOADED:
                    levels = parameter as Array;
                    break;
                case HLSEvent.MEDIA_TIME:
                    mediatime = parameter as Object;
                    break;
                case HLSEvent.STATE:
                    state = parameter as String;
                    break;
                case HLSEvent.QUALITY_SWITCH:
                    level = parameter as Number;
                    break;
                case HLSEvent.LEVEL_UPDATED:
                    level = parameter as Number;
                    break;
                case HLSEvent.LEVEL_PTS_UPDATED:
                    level = parameter as Number;
                    break;
            }
            super(type, false, false);
        };


    }


}