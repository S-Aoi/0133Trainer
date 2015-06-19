package songs.bmses
{
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	/**
	 * 参考资料：
	 * http://blog.csdn.net/teajs/article/details/20698733
	 * http://fileformats.wikia.com/wiki/Be-Music_Script
	 * http://bbs.sjtu.edu.cn/bbstcon,board,MusicGame,reid,1277457310.html
	 * http://hitkey.nekokan.dyndns.info/cmds.htm
	 */
	public final class BMS implements IBMS
	{
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class constants
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Encodings
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal static const ENCODING_SHIFT_JIS:String = 'shift_jis';
		
		internal static const ENCODING_UTF8:String = 'utf-8';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Channels
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public static const CHANNEL_BGM:uint			= 1;
		
		/**
		 * 节拍通道中的数据为一个十进制数值，用于表示当前小节的长度，默认值为1（4/4拍）。 
		 * 
		 * 简要说就是为了调整本节 note 的 offset 的，因为改变了一个小节的长度，
		 * 其中的 note 自然也受到影响。
		 **/
		public static const CHANNEL_METER:uint			= 2;
		
		/** 直接写数值型变速 **/
		public static const CHANNEL_BPM:uint			= 3;
		
		public static const CHANNEL_BGA:uint			= 4;
		
		public static const CHANNEL_MISS:uint			= 6;
		
		public static const CHANNEL_LAYER:uint			= 7;
		
		/** 引用数值型变速 **/
		public static const CHANNEL_BPM_EXTENDED:uint	= 8;
		
		public static const CHANNEL_STOP:uint			= 9;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Type
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal static const TYPE_WAV:String = 'WAV';
		
		internal static const TYPE_BMP:String = 'BMP';
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Class methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public static function isBMS(file:File):Boolean
		{
			var extension:String = file.extension;
			return extension == 'bms'
				|| extension == 'bme'
				|| extension == 'bml'
				|| extension == 'bmx'
				|| extension == 'bns'
				|| extension == 'pms'
				// 等等…… syk 这不是…… さやか 啊！哪有这样吃饱没事干的人？
				|| extension == 'syk' // TODO: 还有什么奇葩格式？
				|| extension == 'sm'; // 待测试
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Constructor
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function BMS(bmsPack:BMSPack = null)
		{
			this._bmsPack = bmsPack;
		}
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Variables
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Header
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * 1 = 单人
		 * 2 = 双人
		 * 3 = 一人♀二角♂
		 */
		public var player:uint = 1;
		
		public var genre:String;
		
		public var title:String;
		
		public var artist:String;
		
		// TODO: 再加上 & subartist。
		public var subartist:String;
		
		public var bpm:Number = NaN;
		
		public var playlevel:Number = NaN;
		
		public var rank:Number = NaN;
		
		public var total:Number = NaN;
		
		// TODO: 这三个都是一样东西，背景图，貌似不一样。
		// TODO: 智能检测图片？
		public var stagefile:String;
		
		public var banner:String;
		
		public var backbmp:String;
		
		public var lntype:uint = 1;
		
		// TODO: 看看 Converter 有什么要改的不。
		public var lnobj:String;
		
		public var difficulty:Number = NaN;
		
		public var subtitle:String;
		
		// TODO: 音效声音。
		public var volwav:Number = 70;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Id
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public var wavs:Array;
		
		public var bmps:Array;
		
		public var bpms:Array;
		
		public var stops:Array;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Main Data
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public var measures:Array;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Content
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		internal var content:String;
		
		internal var lines:Vector.<String>;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Parser
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var parser:BMSParser;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//  Others
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		/**
		 * BMS 文件的名字。不包括后缀名。
		 */
		public var name:String;
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Properties
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		private var _bmsPack:BMSPack;
		
		public function get bmsPack():BMSPack { return _bmsPack; }
		
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		//
		//  Methods
		//
		//☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆☆
		
		public function setData(data:ByteArray, encoding:String):void
		{
			this.content = data.readMultiByte(data.bytesAvailable, encoding);
		}
		
		public function load():void
		{
			parser ||= new BMSParser(this);
			parser.load();
		}
		
		internal function init():void
		{
			lines = Vector.<String>(content.split('\r\n'));
			measures = [];
			
			wavs = [];
			bmps = [];
			bpms = [];
			stops = [];
		}
	}
}
