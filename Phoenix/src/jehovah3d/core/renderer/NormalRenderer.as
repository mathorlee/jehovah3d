package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	public class NormalRenderer extends Renderer
	{
		public static const NAME:String = "NormalRenderer";
		
		public function NormalRenderer(mesh:Mesh)
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
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
				assetsDict[VA_COORDINATE] = "va0";
			}
			
			//push normal buffer
			if(mesh.geometry.normalBuffer)
			{
				vertexBuffers.push(mesh.geometry.normalBuffer);
				vertexBufferIndices.push(1);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_NORMAL] = "v1"; //va1/v1: normal buffer.
				assetsDict[VA_NORMAL] = "va1";
			}
			
			assetsDict[C_FINALMATRIX] = currentVC();
			vertexConstants.push(mesh.finalMatrix.rawData[0], mesh.finalMatrix.rawData[4], mesh.finalMatrix.rawData[8], mesh.finalMatrix.rawData[12]);
			vertexConstants.push(mesh.finalMatrix.rawData[1], mesh.finalMatrix.rawData[5], mesh.finalMatrix.rawData[9], mesh.finalMatrix.rawData[13]);
			vertexConstants.push(mesh.finalMatrix.rawData[2], mesh.finalMatrix.rawData[6], mesh.finalMatrix.rawData[10], mesh.finalMatrix.rawData[14]);
			vertexConstants.push(mesh.finalMatrix.rawData[3], mesh.finalMatrix.rawData[7], mesh.finalMatrix.rawData[11], mesh.finalMatrix.rawData[15]);
			
			assetsDict[C_LOCAL_TO_VIEW_MATRIX] = currentFC();
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[0], mesh.localToCameraMatrix.rawData[4], mesh.localToCameraMatrix.rawData[8], mesh.localToCameraMatrix.rawData[12]);
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[1], mesh.localToCameraMatrix.rawData[5], mesh.localToCameraMatrix.rawData[9], mesh.localToCameraMatrix.rawData[13]);
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[2], mesh.localToCameraMatrix.rawData[6], mesh.localToCameraMatrix.rawData[10], mesh.localToCameraMatrix.rawData[14]);
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[3], mesh.localToCameraMatrix.rawData[7], mesh.localToCameraMatrix.rawData[11], mesh.localToCameraMatrix.rawData[15]);
			
			assetsDict[C_HALF] = currentFC();
			fragmentConstants.push(0.5, 0.5, 0.5, 0.5);
			assetsDict[C_ONE] = currentFC();
			fragmentConstants.push(1.0, 1.0, 1.0, 1.0);
			
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
			var ret:String = "";
			
			ret += agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null);
			ret += agal("mov", "v0", null, assetsDict[VA_NORMAL], null);
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agal("nrm", "ft0", "xyz", "v0", "xyz");
			ret += agal("m33", "ft0", "xyz", "ft0", "xyz", assetsDict[C_LOCAL_TO_VIEW_MATRIX], null);
			ret += agal("add", "ft0", "xyz", "ft0", "xyz", assetsDict[C_ONE], "xxx");
			ret += agal("mul", "ft0", "xyz", "ft0", "xyz", assetsDict[C_HALF], "xxx");
			ret += agal("mov", "oc", null, "ft0", "xyz");
			
			return ret;
		}
	}
}