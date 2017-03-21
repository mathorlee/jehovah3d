package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	/**
	 * 树叶Renderer。杀死透明像素
	 * @author lisongsong
	 * 
	 */	
	public class LeafRenderer extends Renderer
	{
		public static const NAME:String = "LeafRenderer";
		public static const ALPHA_TOLERANCE:Number = 0.1;
		
		public function LeafRenderer(mesh:Mesh)
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
			Renderer.dunkM44(mesh.finalMatrix, vertexConstants);
			
			index = currentFCIndex();
			assetsDict[TMP_CONSTANT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			fragmentConstants.push(ALPHA_TOLERANCE, 0, 0, 0);
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0";
				assetsDict[VA_COORDINATE] = "va0";
			}
			
			if(mesh.mtl.useUVW)
			{
				//push uvw buffer
				vertexBuffers.push(mesh.geometry.diffuseUVBuffer);
				vertexBufferIndices.push(2);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_2);
				assetsDict[V_UVW] = "v2";
				assetsDict[VA_UVW] = "va2";
			}
			
			if(mesh.mtl.useDiffuseMapChannel)
			{
				//push diffuse texture
				textures.push(mesh.mtl.diffuseMapResource.texture);
				textureSamplers.push(0);
				assetsDict[FS_DIFFUSE] = "fs0";
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
			
			ret += agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null); //op
			ret += agal("mov", assetsDict[V_UVW], null, assetsDict[VA_UVW], null);
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agal("tex", "ft0", null, assetsDict[V_UVW], "xy", assetsDict[FS_DIFFUSE] + texParameter("2d"), null);
			ret += agal("slt", "ft1", "x", "ft0", "w", assetsDict[TMP_CONSTANT], null);
			ret += agal("sub", "ft0", "w", "ft0", "w", "ft1", "x");
			ret += "kil ft0.w\n";
			ret += agal("mov", "oc", null, "ft0", null, null, null);
			
			return ret;
		}
	}
}