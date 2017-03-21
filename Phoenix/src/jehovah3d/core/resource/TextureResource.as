package jehovah3d.core.resource
{
	import com.fuwo.extend.CalculateSingle;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	

	public class TextureResource extends TextureResourceBase
	{
		public function TextureResource(bitmapData:BitmapData, mip:Boolean = true)
		{
			super(bitmapData, mip);
			_bitmapData = CalculateSingle.handleTextureBMD(bitmapData);
			_mip = mip;
		}
		
		/**
		 * upload texture resource to GPU. 
		 * @param context3D
		 * 
		 */		
		override public function upload(context3D:Context3D):void
		{
			if(isUploaded && cachedContext3D == context3D) //if texture is uploaded and cached context3d equals current context3d, no need to continue.
				return ;
			else //else, update cached context3d and upload. the can handle context3d loss.
				cachedContext3D = context3D;
			
//			trace("texture upload");
			if(_texture)
				_texture.dispose();
			_texture = context3D.createTexture(_bitmapData.width, _bitmapData.height, Context3DTextureFormat.BGRA, false);
//			_texture.uploadFromBitmapData(_bitmapData, 0);
			if(_mip)
			{
				var w:int = _bitmapData.width;
				var h:int = _bitmapData.height;
				var mipLevel:int = 0;
				var bmd:BitmapData;
				var matrix:Matrix = new Matrix();
				while(w > 0 || h > 0)
				{
					if(bmd)
						bmd.dispose();
					if(w == 0)
						w = 1;
					if(h == 0)
						h = 1;
					bmd = new BitmapData(w, h, true, 0x00000000);
					bmd.draw(_bitmapData, matrix, null, null, null, true);
					Texture(_texture).uploadFromBitmapData(bmd, mipLevel);
					matrix.scale(0.5, 0.5);
					mipLevel ++;
					w >>= 1;
					h >>= 1;
				}
				if(bmd)
					bmd.dispose();
			}
			else
			{
				Texture(_texture).uploadFromBitmapData(_bitmapData, 0);
			}
			
		}
	}
}