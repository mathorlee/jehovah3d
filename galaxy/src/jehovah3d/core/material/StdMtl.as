package jehovah3d.core.material
{
	import jehovah3d.util.HexColor;

	public class StdMtl extends DiffuseMtl
	{
		private var _ambientColor:HexColor;
		private var _specularColor:HexColor;
		private var _specularLevel:Number;
		private var _glossiness:Number;
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
		public function StdMtl(ambientColor:uint, diffuseColor:uint, specularColor:uint, specularLevel:Number, glossiness:Number, diffuseMapURL:String = null, reflectionMapURL:String = null, specularMapURL:String = null, bumpMapURL:String = null, opacityMapURL:String = null)
		{
			super(diffuseMapURL, reflectionMapURL, specularMapURL, bumpMapURL, opacityMapURL);
			
			_ambientColor = new HexColor(ambientColor, 1);
			_diffuseColor = new HexColor(diffuseColor, 1);
			_specularColor = new HexColor(specularColor, 1);
			_specularLevel = specularLevel;
			_glossiness = glossiness;
		}
		
		override public function dispose():void
		{
			super.dispose();
		}
		
		public function get ambientColor():HexColor
		{
			return _ambientColor;
		}
		public function get specularColor():HexColor
		{
			return _specularColor;
		}
		public function get specularLevel():Number
		{
			return _specularLevel;
		}
		public function get glossiness():Number
		{
			return _glossiness;
		}
	}
}