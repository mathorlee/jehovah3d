package flashas3.flvplay
{
	/**
	 * 功能：加载flv
	 * 用法：new 构造函数 (url) 
	 */	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;

	public class FlvPlay extends MovieClip
	{
		/**
		 * flv地址 
		 */		
		private var flvUrl:String;
		/**
		 * flv播放器 
		 */		
		private var flvVideo:Video;
		private var flvNetConnection:NetConnection;
		private var flvNetStream:NetStream;
		/**
		 * 循环播放 
		 */		
		private var _loop:Boolean = false;
		/**
		 * 播放状态 
		 */		
		private var _playing:Boolean = false;
		/**
		 * 暂停状态 
		 */		
		private var _paused:Boolean = true;
		/**
		 * 视频容器 
		 */		
		private var _container:Sprite;
		
		public function FlvPlay(url:String)
		{
			var flvObject:Object = new Object();
			this.flvUrl = url;
			this.flvNetConnection = new NetConnection();
			this.flvNetConnection.connect(null);
			this.flvNetStream = new NetStream(this.flvNetConnection);
			this.flvNetStream.play(this.flvUrl);
			this.flvNetStream.client = flvObject;
			this.flvNetStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,errorHandler);
			this.flvNetStream.addEventListener(NetStatusEvent.NET_STATUS,statusHandler);
			this.flvVideo = new Video();
			this.flvVideo.attachNetStream(this.flvNetStream);
			trace("video:  "+this.flvNetStream.info);
			this._container = new Sprite();
			this._container.addChild(this.flvVideo);	
		}
		
		private function errorHandler(evt:AsyncErrorEvent):void
		{
			trace("load flv error");
		}
		
		private function statusHandler(evt:NetStatusEvent):void
		{
			if(evt.info.code=="NetStream.Play.Stop")
			{
				/*循环播放*/
				if(this.loop)
				{
					flvBack();
					flvPlay();
				}
			}
		}
		
		/**
		 * 
		 * flv 返回播放 
		 */		
		public function flvBack():void
		{
			this.flvNetStream.play(this.flvUrl);
		}
		
		/**
		 * flv 播放视频 
		 * 
		 */		
		public function flvPlay():void
		{
			this.flvNetStream.resume();
			this._playing = true;
			this._paused = false;
		}
		
		/**
		 * flv 视频暂停 
		 * 
		 */		
		public function flvPause():void
		{
			this.flvNetStream.pause();
			this._paused = true;
			this._playing = false;
		}
		
		/**
		 * flv 删除视频 
		 * 
		 */		
		public function flvCancel():void
		{
			this.flvNetStream.close();
		}
		
		public function set loop(boo:Boolean):void
		{
			this._loop = boo;
		}
		
		public function get loop():Boolean
		{
			return this._loop;
		}
		
		public function get playing():Boolean
		{
			return this._playing;
		}
		
		public function set playing(boo:Boolean):void
		{
			this._playing = boo;
			if(boo)
				flvPlay();
		}
		
		public function get paused():Boolean
		{
			return this._paused;
		}
		
		public function set paused(boo:Boolean):void
		{
			this._paused = boo;
			if(boo)
				flvPause();
		}
		
		public function get container():Sprite
		{
			return this._container;
		}
	}
}