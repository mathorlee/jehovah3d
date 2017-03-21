package jehovah3d.core.mesh
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.ShaderResource;

	public class SkyBox extends Mesh
	{
		/*
		var skybox:SkyBox = new SkyBox();
		var skyboxmtl:DiffuseMtl = new DiffuseMtl(null, key);
		skyboxmtl.reflectionMapResource = AssetsManager.getTextureResourceByKey(key).textureResource;
		skybox.geometry.upload(Jehovah.cachedContext3D);
		skybox.mtl = skyboxmtl;
		skybox.name = "_bg_";
		sceneContent.addChild(skybox);
		*/
		public function SkyBox()
		{
			initGeometry();
		}
		
		private function initGeometry():void
		{
//			var a:Number = Jehovah.camera.zFar / Math.sqrt(3.0) - 10;
			var a:Number = 50;
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			coordinateData.push(
				a, -a, a, a, a, a, a, a, -a, a, -a, -a, //x+
				-a, a, a, -a, -a, a, -a, -a, -a, -a, a, -a, //x-
				a, a, a, -a, a, a, -a, a, -a, a, a, -a, //y+
				-a, -a, a, a, -a, a, a, -a, -a, -a, -a, -a, //y-
				-a, a, a, a, a, a, a, -a, a, -a, -a, a, //z+
				a, a, -a, -a, a, -a, -a, -a, -a, a, -a, -a//z-
			);
			
			
			var indexData:Vector.<uint> = new Vector.<uint>();
			var i:int;
			for(i = 0; i < 6; i ++)
				indexData.push(4 * i + 0, 4 * i + 1, 4 * i + 2, 4 * i + 0, 4 * i + 2, 4 * i + 3);
			_geometry = new GeometryResource();
			_geometry.coordinateData = coordinateData;
			_geometry.indexData = indexData;
		}
		
		override public function collectResource():void
		{
			vertexConstants.length = 0;
			fragmentConstants.length = 0;
			
			vertexBuffers.length = 0;
			vertexBufferIndices.length = 0;
			vertexBufferFormats.length = 0;
			
			textures.length = 0;
			textureSamplers.length = 0;
			
			//push coordinate buffer
			vertexBuffers.push(geometry.coordinateBuffer);
			vertexBufferIndices.push(0);
			vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
			
			//push reflection texture
			textures.push(_mtl.reflectionMapResource.texture);
			textureSamplers.push(1);
			
			fragmentConstants.push(0.5, 1, 2, 0);
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(null);
				_shader.fragmentShaderString = generateFragmentShader(null);
				
//				trace("Vertex Shader:");
//				trace(generateVertexShader(null));
//				trace("Fragment Shader:");
//				trace(generateFragmentShader(null));
				
				_shader.upload(Jehovah.context3D);
			}
		}
		
		override public function generateVertexShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agalExpression("m44", "op", null, "va0", null, "vc0", null);
			ret += agalExpression("mov", "v0", null, "va0", null);
			
			return ret;
		}
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agalExpression("mov", "ft1", null, "v0", null);
			ret += agalExpression("nrm", "ft1", "xyz", "ft1", "xyz");
			ret += agalExpression("tex", "ft2", null, "ft1", "xyz", "fs1" + "<cube,linear,clamp>", null);
			ret += agalExpression("mov", "oc", null, "ft2", "xyz");
			
			return ret;
		}
		
	}
}