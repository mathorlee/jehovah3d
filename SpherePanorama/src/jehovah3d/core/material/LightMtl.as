package jehovah3d.core.material
{
	import flash.geom.Matrix;
	
	import jehovah3d.core.resource.TextureResourceBase;

	public class LightMtl extends DiffuseMtl
	{
		protected var _lightMapResource:TextureResourceBase;
		protected var _lightUVMatrix:Matrix;
		
		public function LightMtl(diffuseMapURL:String=null)
		{
			super(diffuseMapURL);
		}
		
		override public function get isUploaded():Boolean
		{
			if(!_lightMapResource)
				return false;
			if(_lightMapResource && !_lightMapResource.isUploaded)
				return false;
			if(useDiffuseMapChannel) //if diffuse map is empty, return false.
			{
				if(!_diffuseMapResource)
					return false;
				if(_diffuseMapResource && !_diffuseMapResource.isUploaded) //if diffuse map hasn't been uploaded, return false.
					return false;
			}
			else if(!_diffuseColor) //if diffuse color is empty, return false.
				return false;
			return true;
		}
		
		override public function dispose():void
		{
			if(_lightMapResource)
			{
				if(disposeTextureResource)
					_lightMapResource.dispose();
				_lightMapResource = null;
			}
			super.dispose();
		}
		
		public function get lightMapResource():TextureResourceBase
		{
			return _lightMapResource;
		}
		public function set lightMapResource(value:TextureResourceBase):void
		{
			if(_lightMapResource != value)
				_lightMapResource = value;
		}
		
		public function get lightUVMatrix():Matrix
		{
			return _lightUVMatrix;
		}
		public function set lightUVMatrix(value:Matrix):void
		{
			if(_lightUVMatrix != value)
				_lightUVMatrix = value;
		}
		
	}
}