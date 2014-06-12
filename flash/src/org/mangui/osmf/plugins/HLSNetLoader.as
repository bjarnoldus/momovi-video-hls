 package org.mangui.osmf.plugins
{
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import org.osmf.media.MediaResourceBase;
	import org.osmf.media.URLResource;
	import org.osmf.net.NetStreamLoadTrait;
	import org.osmf.net.httpstreaming.HTTPStreamingNetLoader;
	import org.osmf.traits.LoadState;
		
  import org.mangui.HLS.HLS;
  import org.mangui.HLS.utils.*;
  
	public class HLSNetLoader extends HTTPStreamingNetLoader
	{
	  
	  private var _duration:Number;
	  private var _hls:HLS;

		public function HLSNetLoader(hls:HLS,duration:Number){
		  _hls = hls;
		  _duration = duration;
			super();
		}

		override public function canHandleResource(resource:MediaResourceBase):Boolean
		{
			return true;
		}
		
		override protected function createNetStream(connection:NetConnection, resource:URLResource):NetStream
		{
			return _hls.stream;
		}
		
		override protected function processFinishLoading(loadTrait:NetStreamLoadTrait):void
		{
			var resource:URLResource = loadTrait.resource as URLResource;
			loadTrait.setTrait(new HLSTimeTrait(_hls,_duration));
		  updateLoadTrait(loadTrait, LoadState.READY);
		 return;
	  }
	}
}
