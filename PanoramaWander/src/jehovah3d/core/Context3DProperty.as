package jehovah3d.core
{
	import flash.display3D.Context3D;

	public class Context3DProperty
	{
		public var sourceFactor:String;
		public var destinationFactor:String;
		public var culling:String;
		
		public var usedBuffer:uint = 0;
		public var usedTexture:uint = 0;
		
		public function Context3DProperty()
		{
			
		}
		public function dispose(context3D:Context3D):void
		{
			var index:int;
			for(index = 0; usedBuffer > 0; index ++)
			{
				if(usedBuffer & 1)
					context3D.setVertexBufferAt(index, null);
				usedBuffer >>= 1;
			}
			for(index = 0; usedTexture > 0; index ++)
			{
				if(usedTexture & 1)
					context3D.setTextureAt(index, null);
				usedTexture >>= 1;
			}
		}
	}
}