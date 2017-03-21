package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	/**
	 * 直线Renderer
	 * @author lisongsong
	 * 
	 */	
	public class LineRenderer extends Renderer
	{
		public static const NAME:String = "LineRenderer";
		
		public var depthOffset:Number = 1;
		public var useDepthOffset:Boolean = true;
		
		public function LineRenderer(mesh:Mesh)
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
			var index:int;
			assetsDict[C_FINALMATRIX] = currentVC();
			var pm:Matrix3D = Jehovah.camera.pm;
			Renderer.dunkM44(pm, vertexConstants);
			index = currentVCIndex();
			assetsDict[C_LINE_DEPTH_OFFSET] = new ShaderConstant(ShaderConstant.VERTEX_CONSTANT, index, "x");
			vertexConstants.push(depthOffset, 0, 0, 0);
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0";
				assetsDict[VA_COORDINATE] = "va0";
			}
			if (mesh.geometry.vertexColorBuffer)
			{
				vertexBuffers.push(mesh.geometry.vertexColorBuffer);
				vertexBufferIndices.push(1);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COLOR] = "v1"; //va1/v1: vertexColor buffer.
				assetsDict[VA_COLOR] = "va1";
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
			var ret:String = "";
			
			if (useDepthOffset)
			{
				ret += agal("mov", "vt0", null, assetsDict[VA_COORDINATE], null);
				ret += agal("nrm", "vt1", "xyz", "vt0", "xyz");
				ret += agal("mul", "vt1", "xyz", "vt1", "xyz", assetsDict[C_LINE_DEPTH_OFFSET].toString(3), null);
				ret += agal("sub", "vt0", "xyz", "vt0", "xyz", "vt1", "xyz");
				ret += agal("m44", "op", null, "vt0", null, assetsDict[C_FINALMATRIX], null);
			}
			else
				ret += agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null);
			
			if (assetsDict[VA_COLOR])
				ret += agal("mov", assetsDict[V_COLOR], null, assetsDict[VA_COLOR], null);
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			if (assetsDict[VA_COLOR])
				return agal("mov", "oc", null, assetsDict[V_COLOR], null);
			else
				return agal("mov", "oc", null, assetsDict[DIFFUSE_COLOR], null);
		}
	}
}