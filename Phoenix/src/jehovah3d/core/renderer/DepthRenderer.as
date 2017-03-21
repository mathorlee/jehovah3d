package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	public class DepthRenderer extends Renderer
	{
		public static const NAME:String = "DepthRenderer";
		
		public function DepthRenderer(mesh:Mesh)
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
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
				assetsDict[VA_COORDINATE] = "va0";
			}
			
			assetsDict[C_FINALMATRIX] = currentVC();
			vertexConstants.push(mesh.finalMatrix.rawData[0], mesh.finalMatrix.rawData[4], mesh.finalMatrix.rawData[8], mesh.finalMatrix.rawData[12]);
			vertexConstants.push(mesh.finalMatrix.rawData[1], mesh.finalMatrix.rawData[5], mesh.finalMatrix.rawData[9], mesh.finalMatrix.rawData[13]);
			vertexConstants.push(mesh.finalMatrix.rawData[2], mesh.finalMatrix.rawData[6], mesh.finalMatrix.rawData[10], mesh.finalMatrix.rawData[14]);
			vertexConstants.push(mesh.finalMatrix.rawData[3], mesh.finalMatrix.rawData[7], mesh.finalMatrix.rawData[11], mesh.finalMatrix.rawData[15]);
			
			index = currentFCIndex();
			assetsDict[C_255] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[C_ZFAR] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			fragmentConstants.push(255, Jehovah.currentLight ? -Jehovah.currentLight.zFar : -Jehovah.camera.zFar, 0, 0);
			
			assetsDict[C_LOCAL_TO_VIEW_MATRIX] = currentFC();
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[0], mesh.localToCameraMatrix.rawData[4], mesh.localToCameraMatrix.rawData[8], mesh.localToCameraMatrix.rawData[12]);
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[1], mesh.localToCameraMatrix.rawData[5], mesh.localToCameraMatrix.rawData[9], mesh.localToCameraMatrix.rawData[13]);
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[2], mesh.localToCameraMatrix.rawData[6], mesh.localToCameraMatrix.rawData[10], mesh.localToCameraMatrix.rawData[14]);
			fragmentConstants.push(mesh.localToCameraMatrix.rawData[3], mesh.localToCameraMatrix.rawData[7], mesh.localToCameraMatrix.rawData[11], mesh.localToCameraMatrix.rawData[15]);
			
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
			ret += agal("mov", assetsDict[V_COORDINATE], null, assetsDict[VA_COORDINATE], null);
			
			return ret;
		}
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agal("m44", "ft0", null, assetsDict[V_COORDINATE], null, assetsDict[C_LOCAL_TO_VIEW_MATRIX], null);
			ret += agal("div", "ft0", "x", "ft0", "z", assetsDict[C_ZFAR].toString(1), null);
			
			//ft0.y = frc(ft0.x * 255)
			ret += agal("mul", "ft0", "y", "ft0", "x", assetsDict[C_255].toString(1), null);
			ret += agal("frc", "ft0", "y", "ft0", "y");
			
			//ft0.z = frc(ft0.y * 255)
			ret += agal("mul", "ft0", "z", "ft0", "y", assetsDict[C_255].toString(1), null);
			ret += agal("frc", "ft0", "z", "ft0", "z");
			
			//ft0.w = frc(ft0.z * 255)
			ret += agal("mul", "ft0", "w", "ft0", "z", assetsDict[C_255].toString(1), null);
			ret += agal("frc", "ft0", "w", "ft0", "w");
			
			//v0 = ft0.xyz - ft0.yzw / 255
			ret += agal("div", "ft1", "xyz", "ft0", "yzw", assetsDict[C_255].toString(3), null);
			ret += agal("sub", "ft0", "xyz", "ft0",  "xyz", "ft1",  "xyz");
			ret += agal("mov", "oc", null, "ft0", null);
			
			return ret;
		}
	}
}