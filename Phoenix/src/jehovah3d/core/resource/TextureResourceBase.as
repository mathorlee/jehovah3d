package jehovah3d.core.resource
{
	import flash.display.BitmapData;
	import flash.display3D.textures.TextureBase;
	
	public class TextureResourceBase extends Resource
	{
		protected var _texture:TextureBase;
		protected var _bitmapData:BitmapData;
		protected var _mip:Boolean;
		
		public function TextureResourceBase(_bitmapData:BitmapData, mip:Boolean = false)
		{
			
		}
		
		override public function dispose():void
		{
			super.dispose();
			if(_texture)
			{
				_texture.dispose();
				_texture = null;
			}
			if(_bitmapData)
			{
				_bitmapData.dispose();
				_bitmapData = null;
			}
		}
		
		override public function get isUploaded():Boolean
		{
			return _texture != null;
		}
		
		/**
		 * texture. 
		 * @return 
		 * 
		 */		
		public function get texture():TextureBase
		{
			return _texture;
		}
		
		/**
		 * mip默认为true。不到万不得已别关闭mip。使用billboard为了得到更清晰的家具效果才选择关闭mip。 
		 * @return 
		 * 
		 */		
		public function get mip():Boolean
		{
			return _mip;
		}
	}
}