package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	public class WireFrameRenderer extends Renderer
	{
		public static const NAME:String = "WireFrameRenderer";
		
		public function WireFrameRenderer(mesh:Mesh)
		{
			super(mesh);
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
			
			var assetsDict:Dictionary = new Dictionary();
			assetsDict[C_PROJECTION_MATRIX] = currentVC();
//			var pm:Matrix3D = Jehovah.currentLight ? Jehovah.currentLight.projectionMatrix : Jehovah.camera.pm;
			var pm:Matrix3D = Jehovah.camera.pm;
			vertexConstants.push(pm.rawData[0], pm.rawData[4], pm.rawData[8], pm.rawData[12]);
			vertexConstants.push(pm.rawData[1], pm.rawData[5], pm.rawData[9], pm.rawData[13]);
			vertexConstants.push(pm.rawData[2], pm.rawData[6], pm.rawData[10], pm.rawData[14]);
			vertexConstants.push(pm.rawData[3], pm.rawData[7], pm.rawData[11], pm.rawData[15]);
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
				assetsDict[VA_COORDINATE] = "va0";
			}
			if(mesh.mtl.diffuseColor)
			{
				assetsDict[DIFFUSE_COLOR] = currentFC(); //diffuseColor
				fragmentConstants.push(mesh.mtl.diffuseColor.fractionalRed, mesh.mtl.diffuseColor.fractionalGreen, mesh.mtl.diffuseColor.fractionalBlue, mesh.mtl.diffuseColor.fractionalAlpha); //diffuse color
			}
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(assetsDict);
				_shader.fragmentShaderString = generateFragmentShader(assetsDict);
				_shader.upload(Jehovah.context3D);
			}
		}
		
		override public function generateVertexShader(assetsDict:Dictionary):String
		{
			return agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_PROJECTION_MATRIX], null);
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			return agal("mov", "oc", null, assetsDict[DIFFUSE_COLOR], null);
		}
	}
}