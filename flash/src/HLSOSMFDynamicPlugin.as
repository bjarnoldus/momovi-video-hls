package
{
	import flash.display.Sprite;
	import flash.system.Security;
	
	import org.mangui.osmf.plugins.HLSPlugin;
	import org.osmf.media.PluginInfo;
	
	public class HLSOSMFDynamicPlugin extends Sprite
	{
		private var _pluginInfo:PluginInfo;
		
		public function HLSOSMFDynamicPlugin()
		{
			super();
			Security.allowDomain("*");
			_pluginInfo = new HLSPlugin();
		}
		
		public function get pluginInfo():PluginInfo{
			return _pluginInfo;
		}
	}
}