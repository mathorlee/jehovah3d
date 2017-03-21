package jehovah3d.core.material
{
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Matrix;
	
	import jehovah3d.core.resource.TextureResourceBase;
	import jehovah3d.util.HexColor;

	/**
	 * 材质基类。 
	 * @author Administrator
	 * 
	 */	
	public class DiffuseMtl
	{
		//blend factor
		public var sourceFactor:String = Context3DBlendFactor.ONE;
		public var destinationFactor:String = Context3DBlendFactor.ZERO;
		
		//culling
		public var culling:String = Context3DTriangleFace.FRONT;
		
		//没有被搜集到AssetsManager中的TextureResource在DiffuseMtl中dispose。针对。BBFurniture。
		public var disposeTextureResource:Boolean = false;
		
		//texture resource.
		protected var _diffuseMapResource:TextureResourceBase;
		protected var _reflectionMapResource:TextureResourceBase;
		protected var _specularMapResource:TextureResourceBase;
		protected var _bumpMapResource:TextureResourceBase;
		protected var _opacityMapResource:TextureResourceBase;
		
		protected var _diffuseAmount:Number = 1.0;
		protected var _reflectionAmount:Number = 1.0;
		protected var _specularAmount:Number = 1.0;
		protected var _bumpAmount:Number = 1.0;
		protected var _opacityAmount:Number = 1.0;
		
		protected var _diffuseUVMatrix:Matrix;
		protected var _specularUVMatrix:Matrix;
		protected var _reflectionUVMatrix:Matrix;
		protected var _bumpUVMatrix:Matrix;
		protected var _opacityUVMatrix:Matrix;
		
		//map url.
		protected var _diffuseMapURL:String;
		protected var _reflectionMapURL:String;
		protected var _specularMapURL:String;
		protected var _bumpMapURL:String;
		protected var _opacityMapURL:String;
		
		//diffuse color.
		protected var _diffuseColor:HexColor;
		
		//alpha.
		private var _alpha:Number = 1.0;
		
		private var _doubleSided:Boolean = false;
		
		public var materialInAssetsManager:Boolean = false;
		
		public function DiffuseMtl(diffuseMapURL:String = null, reflectionMapURL:String = null, specularMapURL:String = null, bumpMapURL:String = null, opacityMapURL:String = null)
		{
			_diffuseMapURL = diffuseMapURL;
			_reflectionMapURL = reflectionMapURL;
			_specularMapURL = specularMapURL;
			_bumpMapURL = bumpMapURL;
			_opacityMapURL = opacityMapURL;
		}
		
		public function dispose():void
		{
			//dispose resources.
			if(disposeTextureResource)
			{
				if(_diffuseMapResource)
					_diffuseMapResource.dispose();
				if(_reflectionMapResource)
					_reflectionMapResource.dispose();
				if(_specularMapResource)
					_specularMapResource.dispose();
				if(_bumpMapResource)
					_bumpMapResource.dispose();
				if(_opacityMapResource)
					_opacityMapResource.dispose();
			}
			if(_diffuseUVMatrix)
				_diffuseUVMatrix = null;
			if(_specularUVMatrix)
				_specularUVMatrix = null;
			if(_bumpUVMatrix)
				_bumpUVMatrix = null;
			if(_reflectionUVMatrix)
				_reflectionUVMatrix = null;
			if(_opacityUVMatrix)
				_opacityUVMatrix = null;
			
			//clear reference.
			_diffuseMapResource = null;
			_reflectionMapResource = null;
			_specularMapResource = null;
			_bumpMapResource = null;
			_opacityMapResource = null;
			
			if(_diffuseColor)
				_diffuseColor = null;
		}
		
		public function get isUploaded():Boolean
		{
			if(_diffuseMapURL)
			{
				if(!_diffuseMapResource)
					return false;
				if(_diffuseMapResource && !_diffuseMapResource.isUploaded)
					return false;
			}
			if(_reflectionMapURL)
			{
				if(!_reflectionMapResource)
					return false;
				if(_reflectionMapResource && !_reflectionMapResource.isUploaded)
					return false;
			}
			if(_specularMapURL)
			{
				if(!_specularMapResource)
					return false;
				if(_specularMapResource && !_specularMapResource.isUploaded)
					return false;
			}
			if(_bumpMapURL)
			{
				if(!_bumpMapResource)
					return false;
				if(_bumpMapResource && !_bumpMapResource.isUploaded)
					return false;
			}
			if(_opacityMapURL)
			{
				if(!_opacityMapResource)
					return false;
				if(_opacityMapResource && !_opacityMapResource.isUploaded)
					return false;
			}
			return true;
		}
		
		/*
		use map channel.
		*/
		public function get useDiffuseMapChannel():Boolean
		{
//			return _diffuseMapURL != null && _diffuseMapResource != null;
			return _diffuseMapResource != null;
		}
		public function get useReflectionMapChannel():Boolean
		{
//			return _reflectionMapResource != null && _reflectionMapURL != null;
			return _reflectionMapResource != null;
		}
		public function get useSpecularMapChannel():Boolean
		{
//			return _specularMapResource != null && _specularMapURL != null;
			return _specularMapResource != null;
		}
		public function get useBumpMapChannel():Boolean
		{
//			return _bumpMapResource != null && _bumpMapURL != null;
			return _bumpMapResource != null;
		}
		public function get useOpacityMapChannel():Boolean
		{
//			return _opacityMapResource != null && _opacityMapURL != null;
			return _opacityMapResource != null;
		}
		public function get useUVW():Boolean
		{
			return useDiffuseMapChannel || useSpecularMapChannel || useBumpMapChannel || useOpacityMapChannel;
		}
		
		public function get needDiffuse():Boolean
		{
			return _diffuseMapURL != null;
		}
		public function get needReflection():Boolean
		{
			return _reflectionMapURL != null;
		}
		public function get needSpecular():Boolean
		{
			return _specularMapURL != null;
		}
		public function get needBump():Boolean
		{
			return _bumpMapURL != null;
		}
		public function get needOpacity():Boolean
		{
			return _opacityMapURL != null;
		}
		/**
		 * 当材质有贴图通道时，就需要uvwData了 
		 * @return 
		 * 
		 */		
		public function get needUVWData():Boolean
		{
			return needDiffuse || needSpecular || needBump || needOpacity;
		}
		
		public function get diffuseUVMatrix():Matrix
		{
			return _diffuseUVMatrix;
		}
		public function set diffuseUVMatrix(value:Matrix):void
		{
			if(_diffuseUVMatrix != value)
				_diffuseUVMatrix = value;
		}
		
		public function get specularUVMatrix():Matrix
		{
			return _specularUVMatrix;
		}
		public function set specularUVMatrix(value:Matrix):void
		{
			if(_specularUVMatrix != value)
				_specularUVMatrix = value;
		}
		
		public function get reflectionUVMatrix():Matrix
		{
			return _reflectionUVMatrix;
		}
		public function set reflectionUVMatrix(value:Matrix):void
		{
			if(_reflectionUVMatrix != value)
				_reflectionUVMatrix = value;
		}
		
		public function get bumpUVMatrix():Matrix
		{
			return _bumpUVMatrix;
		}
		public function set bumpUVMatrix(value:Matrix):void
		{
			if(_bumpUVMatrix != value)
				_bumpUVMatrix = value;
		}
		public function get opacityUVMatrix():Matrix
		{
			return _opacityUVMatrix;
		}
		public function set opacityUVMatrix(value:Matrix):void
		{
			if(_opacityUVMatrix != value)
				_opacityUVMatrix = value;
		}
		
		/*
		texture resource.
		*/
		public function get diffuseMapResource():TextureResourceBase
		{
			return _diffuseMapResource;
		}
		public function set diffuseMapResource(val:TextureResourceBase):void
		{
			if(_diffuseMapResource != val)
				_diffuseMapResource = val;
		}
		public function get reflectionMapResource():TextureResourceBase
		{
			return _reflectionMapResource;
		}
		public function set reflectionMapResource(val:TextureResourceBase):void
		{
			if(_reflectionMapResource != val)
				_reflectionMapResource = val;
		}
		public function get specularMapResource():TextureResourceBase
		{
			return _specularMapResource;
		}
		public function set specularMapResource(val:TextureResourceBase):void
		{
			if(_specularMapResource != val)
				_specularMapResource = val;
		}
		public function get bumpMapResource():TextureResourceBase
		{
			return _bumpMapResource;
		}
		public function set bumpMapResource(val:TextureResourceBase):void
		{
			if(_bumpMapResource != val)
				_bumpMapResource = val;
		}
		public function get opacityMapResource():TextureResourceBase
		{
			return _opacityMapResource;
		}
		public function set opacityMapResource(val:TextureResourceBase):void
		{
			if(_opacityMapResource != val)
			{
				_opacityMapResource = val;
				if(_opacityMapResource)
				{
					sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
					destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				}
				else
				{
					sourceFactor = Context3DBlendFactor.ONE;
					destinationFactor = Context3DBlendFactor.ZERO;
				}
			}
		}
		
		public function get diffuseAmount():Number
		{
			return _diffuseAmount;
		}
		public function set diffuseAmount(value:Number):void
		{
			if(_diffuseAmount != value)
				_diffuseAmount = value;
		}
		public function get reflectionAmount():Number
		{
			return _reflectionAmount;
		}
		public function set reflectionAmount(value:Number):void
		{
			if(_reflectionAmount != value)
				_reflectionAmount = value;
		}
		public function get specularAmount():Number
		{
			return _specularAmount;
		}
		public function set specularAmount(value:Number):void
		{
			if(_specularAmount != value)
				_specularAmount = value;
		}
		public function get bumpAmount():Number
		{
			return _bumpAmount;
		}
		public function set bumpAmount(value:Number):void
		{
			if(_bumpAmount != value)
				_bumpAmount = value;
		}
		public function get opacityAmount():Number
		{
			return _opacityAmount;
		}
		public function set opacityAmount(value:Number):void
		{
			if(_opacityAmount != value)
				_opacityAmount = value;
		}
		
		/*
		map url.
		*/
		public function get diffuseMapURL():String
		{
			return _diffuseMapURL;
		}
		public function set diffuseMapURL(value:String):void
		{
			if(_diffuseMapURL != value)
				_diffuseMapURL = value;
		}
		public function get reflectionMapURL():String
		{
			return _reflectionMapURL;
		}
		public function set reflectionMapURL(value:String):void
		{
			if(_reflectionMapURL != value)
				_reflectionMapURL = value;
		}
		public function get specularMapURL():String
		{
			return _specularMapURL;
		}
		public function set specularMapURL(value:String):void
		{
			if(_specularMapURL != value)
				_specularMapURL = value;
		}
		public function get bumpMapURL():String
		{
			return _bumpMapURL;
		}
		public function set bumpMapURL(value:String):void
		{
			if(_bumpMapURL != value)
				_bumpMapURL = value;
		}
		public function get opacityMapURL():String
		{
			return _opacityMapURL;
		}
		public function set opacityMapURL(value:String):void
		{
			if(_opacityMapURL != value)
				_opacityMapURL = value;
		}
		
		/*
		diffuse color.
		*/
		public function get diffuseColor():HexColor
		{
			return _diffuseColor;
		}
		public function set diffuseColor(val:HexColor):void
		{
			_diffuseColor = val;
			alpha = _diffuseColor.fractionalAlpha;
		}
		
		/*
		alpha.
		*/
		public function get alpha():Number
		{
			return _alpha;
		}
		public function set alpha(value:Number):void
		{
			_alpha = value;
			if(_alpha < 1)
			{
				sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
				destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			}
			else if(_alpha == 1)
			{
				sourceFactor = Context3DBlendFactor.ONE;
				destinationFactor = Context3DBlendFactor.ZERO;
			}
		}
		public function get doubleSided():Boolean
		{
			return _doubleSided;
		}
		public function set doubleSided(value:Boolean):void
		{
			_doubleSided = value;
			if(_doubleSided)
				culling = Context3DTriangleFace.NONE;
			else
				culling = Context3DTriangleFace.FRONT;
		}
	}
}