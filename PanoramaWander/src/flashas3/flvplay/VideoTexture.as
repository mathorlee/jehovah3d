package flashas3.flvplay
{
	/**
	 * 视频位图 
	 */	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;

	public class VideoTexture
	{
		private var _broadcaster:Sprite;
		//自动播放
		private var _autoPlay:Boolean;
		//自动更新
		private var _autoUpdate:Boolean;
		private var _materialWidth:uint;
		private var _materialHeight:uint;
		//播放器
		private var _player:FlvPlay;
		private var _clippingRect:Rectangle;
		//视频位图
		private var _bitmapdata:BitmapData;
		
		public function VideoTexture(source:String, loop:Boolean = true, autoPlay:Boolean = false, materialWidth:uint = 320, materialHeight:uint = 240)
		{
			_broadcaster = new Sprite();
			
			// validates the size of the video
			_materialWidth = materialWidth;
			_materialHeight = materialHeight;
			
			// this clipping ensures the bimapdata size is valid.
			_clippingRect = new Rectangle(0, 0, _materialWidth, _materialHeight);
			
			// assigns the provided player or creates a simple player if null.
			_player = new FlvPlay(source);
			_player.loop = loop;
			_player.width = _materialWidth;
			_player.height = _materialHeight;
			
			// sets autplay
			_autoPlay = autoPlay;
			
			// Sets up the bitmap material
			bitmapData = new BitmapData(_materialWidth, _materialHeight, true, 0);
			
			// if autoplay start video
			if (autoPlay)
				_player.flvPlay();
			
			// auto update is true by default
			autoUpdate = true;
		}
		
		public function get bitmapData():BitmapData
		{
			return this._bitmapdata;
		}
		
		public function set bitmapData(bmd:BitmapData):void
		{
			this._bitmapdata = bmd;
		}
		
		/**
		 * Indicates whether the material will redraw onEnterFrame
		 */
		public function get autoUpdate():Boolean
		{
			return _autoUpdate;
		}
		
		public function set autoUpdate(value:Boolean):void
		{
			if (value == _autoUpdate)
				return;
			
			_autoUpdate = value;
			
			if (value)
				_broadcaster.addEventListener(Event.ENTER_FRAME, autoUpdateHandler, false, 0, true);
			else
				_broadcaster.removeEventListener(Event.ENTER_FRAME, autoUpdateHandler);
		}
		
		private function autoUpdateHandler(event:Event):void
		{
			update();
		}
		
		/**
		 * Draws the video and updates the bitmap texture
		 * If autoUpdate is false and this function is not 
		 * called the bitmap texture will not update!
		 */
		public function update():void
		{			
			if (_player.playing && !_player.paused) {
				
				bitmapData.lock();
				bitmapData.fillRect(_clippingRect, 0);
				bitmapData.draw(_player.container, null, null, null, _clippingRect);
				bitmapData.unlock();
			}
		}
		
		public function get player():FlvPlay
		{
			return this._player;
		}
	}
}