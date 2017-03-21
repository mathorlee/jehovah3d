package jehovah3d.core.material
{
	import jehovah3d.util.HexColor;

	public class VrayMtl extends DiffuseMtl
	{
		/*
		mtl_type(0: stdmtl, 1: vraymtl)
		mtl_name
		mtl_two_sided
		mtl_diffuse_color
		
		stdmtl_ambient_color
		stdmtl_specular_color
		stdmtl_specular_level
		stdmtl_glossiness
		
		vraymtl_reflect_color
		vraymtl_hilight_glossiness
		vraymtl_reflect_glossiness
		vraymtl_hilight_glossiness_lock
		
		mtl_diffuse_map
		*/
		private var _reflectColor:HexColor;
		private var _hilightGlossiness:Number;
		private var _reflectGlossiness:Number;
		private var _hilightGlossinessLock:uint;
		
		public function VrayMtl(diffuseColor:uint, reflectColor:uint, hilightGlossiness:Number, reflectGlossiness:Number, hilightGlossinessLock:uint, diffuseMapURL:String = null, reflectionMapURL:String = null, specularMapURL:String = null, bumpMapURL:String = null, opacityMapURL:String = null)
		{
			super(diffuseMapURL, reflectionMapURL, specularMapURL, bumpMapURL, opacityMapURL);
			
			_diffuseColor = new HexColor(diffuseColor, 1);
			_reflectColor = new HexColor(reflectColor);
			_hilightGlossiness = hilightGlossiness;
			_reflectGlossiness = reflectGlossiness;
			_hilightGlossinessLock = hilightGlossinessLock;
		}
		
		/**
		 * 把VrayMtl转化为StdMtl。 
		 * @return 
		 * 
		 */		
		public function convertToStdMtl():StdMtl
		{
			var diffuse_color:uint;
			var specular_color:uint;
			var specular_level:Number;
			var glossiness:Number;
			
			var red:Number;
			var green:Number;
			var blue:Number;
			
			red = (1 - _reflectColor.fractionalRed) * _diffuseColor.fractionalRed;
			green = (1 - _reflectColor.fractionalGreen) * _diffuseColor.fractionalGreen;
			blue = (1 - _reflectColor.fractionalBlue) * _diffuseColor.fractionalBlue;
			diffuse_color = (255 << 16) * red + (255 << 8) * green + 255 * blue;
			
			specular_color = (255 << 16) * _reflectColor.fractionalRed + (255 << 8) * _reflectColor.fractionalGreen + 255 * _reflectColor.fractionalBlue;
			specular_level = 100.0;
			if(_hilightGlossinessLock)
				glossiness = _reflectGlossiness / 10;
			else
				glossiness = _hilightGlossiness / 10;
			return new StdMtl(diffuse_color, diffuse_color, specular_color, specular_level, glossiness, _diffuseMapURL, _reflectionMapURL, _specularMapURL, _bumpMapURL, _opacityMapURL);
		}
		
		public function get reflectColor():HexColor
		{
			return _reflectColor;
		}
		public function get hilightGlossiness():Number
		{
			return _hilightGlossiness;
		}
		public function get reflectGlossiness():Number
		{
			return _reflectGlossiness;
		}
		public function get hilightGlossinessLock():uint
		{
			return _hilightGlossinessLock;
		}
	}
}