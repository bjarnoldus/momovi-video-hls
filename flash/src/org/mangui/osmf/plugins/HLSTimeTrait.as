package org.mangui.osmf.plugins
{
	import org.osmf.traits.TimeTrait;
  
  import org.mangui.HLS.HLS;
  import org.mangui.HLS.HLSEvent;
  import org.mangui.HLS.utils.*;
	
	public class HLSTimeTrait extends TimeTrait
	{
	  private var _hls:HLS;
	  private var _duration:Number = 0;
	  private var _position:Number = 0;
		public function HLSTimeTrait(hls:HLS,duration:Number=0)
		{
			super(duration);
			_duration = duration;
			_hls = hls;
      _hls.addEventListener(HLSEvent.MEDIA_TIME,_mediaTimeHandler);
		}
		
		override public function get duration():Number
		{
			return _duration;
		}
		
		override public function get currentTime():Number
		{
      //Log.txt("HLSTimeTrait:get currentTime:" + _position);
			return _position;
		}
		
    /** Update playback position/duration **/
    private function _mediaTimeHandler(event:HLSEvent):void {
      _position = event.mediatime.position;
      _duration = event.mediatime.duration;
  };
	}
}