package jehovah3d.core.renderer
{
	import com.fuwo.math.MyMath;
	
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	public class UniqueColorRenderer extends Renderer
	{
		public static const NAME:String = "UniqueColorRenderer";
		
		public function UniqueColorRenderer(mesh:Mesh)
		{
			super(mesh);
		}
		
		override public  function collectResource():void
		{
			vertexConstants.length = 0;
			fragmentConstants.length = 0;
			
			vertexBuffers.length = 0;
			vertexBufferIndices.length = 0;
			vertexBufferFormats.length = 0;
			
			textures.length = 0;
			textureSamplers.length = 0;
			
			var assetsDict:Dictionary = new Dictionary();
			var index:int;
			
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
				assetsDict[VA_COORDINATE] = "va0";
			}
			
			assetsDict[C_FINALMATRIX] = currentVC();
			MyMath.mergeTwoNumberVector(vertexConstants, MyMath.matrix3DToProgram3DConstants(mesh.finalMatrix), true);
			
			assetsDict[DIFFUSE_COLOR] = currentFC();
			fragmentConstants.push(mesh.uniqueColor.fractionalRed, mesh.uniqueColor.fractionalGreen, mesh.uniqueColor.fractionalBlue, mesh.uniqueColor.fractionalAlpha);
			
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
			return agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null);
		}
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			return agal("mov", "oc", null, assetsDict[DIFFUSE_COLOR], null);
		}
	}
}