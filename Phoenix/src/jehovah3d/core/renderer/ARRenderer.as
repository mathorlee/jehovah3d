package jehovah3d.core.renderer
{
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.material.StdMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	
	/**
	 * ambient and reflection renderer
	 * @author lisongsong
	 * 
	 */	
	public class ARRenderer extends Renderer
	{
		public static const NAME:String = "AFRenderer";
		
		public function ARRenderer(mesh:Mesh)
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
			
			index = currentFCIndex();
			assetsDict[C_ZERO] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			fragmentConstants.push(0, 0, 0, 0);
			
			assetsDict[C_FINALMATRIX] = currentVC();
			vertexConstants.push(mesh.finalMatrix.rawData[0], mesh.finalMatrix.rawData[4], mesh.finalMatrix.rawData[8], mesh.finalMatrix.rawData[12]);
			vertexConstants.push(mesh.finalMatrix.rawData[1], mesh.finalMatrix.rawData[5], mesh.finalMatrix.rawData[9], mesh.finalMatrix.rawData[13]);
			vertexConstants.push(mesh.finalMatrix.rawData[2], mesh.finalMatrix.rawData[6], mesh.finalMatrix.rawData[10], mesh.finalMatrix.rawData[14]);
			vertexConstants.push(mesh.finalMatrix.rawData[3], mesh.finalMatrix.rawData[7], mesh.finalMatrix.rawData[11], mesh.finalMatrix.rawData[15]);
			
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
			
			if(mesh.mtl.useUVW)
			{
				//push uvw buffer
				vertexBuffers.push(mesh.geometry.diffuseUVBuffer);
				vertexBufferIndices.push(2);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_2);
				assetsDict[V_UVW] = "v2";
				assetsDict[VA_UVW] = "va2";
			}
			
			//push localToGlobalMatrix to fragment constants
			assetsDict[C_LOCAL_TO_GLOBAL_MATRIX] = currentFC();
			fragmentConstants.push(mesh.localToGlobalMatrix.rawData[0], mesh.localToGlobalMatrix.rawData[4], mesh.localToGlobalMatrix.rawData[8], mesh.localToGlobalMatrix.rawData[12]);
			fragmentConstants.push(mesh.localToGlobalMatrix.rawData[1], mesh.localToGlobalMatrix.rawData[5], mesh.localToGlobalMatrix.rawData[9], mesh.localToGlobalMatrix.rawData[13]);
			fragmentConstants.push(mesh.localToGlobalMatrix.rawData[2], mesh.localToGlobalMatrix.rawData[6], mesh.localToGlobalMatrix.rawData[10], mesh.localToGlobalMatrix.rawData[14]);
			fragmentConstants.push(mesh.localToGlobalMatrix.rawData[3], mesh.localToGlobalMatrix.rawData[7], mesh.localToGlobalMatrix.rawData[11], mesh.localToGlobalMatrix.rawData[15]);
			
			if(mesh.mtl.alpha < 1)
			{
				assetsDict[MATERIAL_ALPHA] = currentFC();
				fragmentConstants.push(mesh.mtl.alpha, mesh.mtl.alpha, mesh.mtl.alpha, 1);
			}
			
			if(mesh.mtl.useDiffuseMapChannel)
			{
				//push diffuse texture
				textures.push(mesh.mtl.diffuseMapResource.texture);
				textureSamplers.push(0);
				assetsDict[FS_DIFFUSE] = "fs0";
				
				//push diffuse uv matrix.
				assetsDict[DIFFUSE_UV_MATRIX] = currentFC();
				fragmentConstants.push(mesh.mtl.diffuseUVMatrix.a, mesh.mtl.diffuseUVMatrix.b, mesh.mtl.diffuseUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.diffuseUVMatrix.c, mesh.mtl.diffuseUVMatrix.d, mesh.mtl.diffuseUVMatrix.ty, 1);
				fragmentConstants.push(0, 0, 1, 1);
			}
			
			if(mesh.mtl.useReflectionMapChannel)
			{
				//push reflection texture
				textures.push(mesh.mtl.reflectionMapResource.texture);
				textureSamplers.push(1);
				assetsDict[FS_REFLECTION] = "fs1";
				
				//push reflection uv matrix
				assetsDict[REFLECTION_UV_MATRIX] = currentFC();
				fragmentConstants.push(mesh.mtl.reflectionUVMatrix.a, mesh.mtl.reflectionUVMatrix.b, mesh.mtl.reflectionUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.reflectionUVMatrix.c, mesh.mtl.reflectionUVMatrix.d, mesh.mtl.reflectionUVMatrix.ty, 1);
				fragmentConstants.push(0, 0, 0, 1);
				
				assetsDict[REFLECTION_MAP_AMOUNT] = currentFC();
				fragmentConstants.push(mesh.mtl.reflectionAmount, mesh.mtl.reflectionAmount, mesh.mtl.reflectionAmount, 1);
			}
			
			if(mesh.mtl.useBumpMapChannel)
			{
				//push bump texture
				textures.push(mesh.mtl.bumpMapResource.texture);
				textureSamplers.push(3);
				assetsDict[FS_BUMP] = "fs3";
				
				//push bump uv matrix
				assetsDict[BUMP_UV_MATRIX] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, currentFCIndex(), null);
				fragmentConstants.push(mesh.mtl.bumpUVMatrix.a, mesh.mtl.bumpUVMatrix.b, mesh.mtl.bumpUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.bumpUVMatrix.c, mesh.mtl.bumpUVMatrix.d, mesh.mtl.bumpUVMatrix.ty, 1);
				
				//push tangent buffer
				vertexBuffers.push(mesh.geometry.tangentBuffer);
				vertexBufferIndices.push(3);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_TANGENT] = "v3"; //va3/v3: tangent buffer.
				assetsDict[VA_TANGENT] = "va3";
			}
			
			if(mesh.mtl.useOpacityMapChannel)
			{
				//push opacity texture
				textures.push(mesh.mtl.opacityMapResource.texture);
				textureSamplers.push(4);
				assetsDict[FS_OPACITY] = "fs4";
				
				//push opacity uv matrix
				assetsDict[OPACITY_UV_MATRIX] = currentFC();
				fragmentConstants.push(mesh.mtl.opacityUVMatrix.a, mesh.mtl.opacityUVMatrix.b, mesh.mtl.opacityUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.opacityUVMatrix.c, mesh.mtl.opacityUVMatrix.d, mesh.mtl.opacityUVMatrix.ty, 1);
				fragmentConstants.push(0, 0, 0, 1);
			}
			
			if(mesh.mtl is StdMtl) //StdMtl.
			{
				assetsDict[DIFFUSE_COLOR] = currentFC(); //diffuseColor
				fragmentConstants.push(mesh.mtl.diffuseColor.fractionalRed, mesh.mtl.diffuseColor.fractionalGreen, mesh.mtl.diffuseColor.fractionalBlue, 1); //diffuse color
				
				assetsDict[SPECULAR_COLOR] = currentFC(); //specularColor.
				fragmentConstants.push(StdMtl(mesh.mtl).specularColor.fractionalRed, StdMtl(mesh.mtl).specularColor.fractionalGreen, StdMtl(mesh.mtl).specularColor.fractionalBlue, 1);
				
				index = currentFCIndex();
				assetsDict[C_AMBIENT_COEFFICIENT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x"); //ambientCoefficient
				fragmentConstants.push(Jehovah.ambientCoefficient, 0, 0, 0);
				
				assetsDict[FLOAT4_CAMERA_POSITON] = currentFC(); //cameraPosition
				fragmentConstants.push(Jehovah.camera.x, Jehovah.camera.y, Jehovah.camera.z, 1);
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShader(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
		}
		
		override public function generateVertexShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			ret += agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null); //op
			ret += agal("mov", assetsDict[V_COORDINATE], null, assetsDict[VA_COORDINATE], null); //coordinate
			if(assetsDict[VA_NORMAL]) //normal
				ret += agal("mov", assetsDict[V_NORMAL], null, assetsDict[VA_NORMAL], null);
			if(assetsDict[VA_UVW]) //uvw
				ret += agal("mov", assetsDict[V_UVW], null, assetsDict[VA_UVW], null);
			if(assetsDict[VA_TANGENT]) //tangent  
				ret += agal("mov", assetsDict[V_TANGENT], null, assetsDict[VA_TANGENT], null);
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			assetsDict[FT_OC] = "ft0";
			assetsDict[FT_NORMAL] = "ft7";
			var ret:String = "";
			ret += getNormalRegister(assetsDict, assetsDict[FT_NORMAL]);
			
			//计算ambient
			if(assetsDict[FS_DIFFUSE])
			{
				ret += agal("m33", "ft3", "xyz", assetsDict[V_UVW], "xyz", assetsDict[DIFFUSE_UV_MATRIX], null);
				ret += agal("tex", "ft2", null, "ft3", "xy", assetsDict[FS_DIFFUSE] + texParameter("2d"), null);
			}
			else
				ret += agal("mov", "ft2", null, assetsDict[DIFFUSE_COLOR], null);
			ret += agal("mul", assetsDict[FT_OC], "xyz", assetsDict[C_AMBIENT_COEFFICIENT], "xxx", "ft2", "xyz"); //oc.xyz = ambient + diffuse = mul(ft1.xxx, ft2.xyz);
			
			//计算环境反射
			ret += calculateReflection(assetsDict, "ft1", "ft2");
			ret += agal("add", assetsDict[FT_OC], "xyz", assetsDict[FT_OC], "xyz", "ft1", "xyz");
			
			//使用透明贴图。
			if(assetsDict[FS_OPACITY])
			{
				//黑透白不透。
				ret += agal("m33", "ft1", "xyz", assetsDict[V_UVW], "xyz", assetsDict[OPACITY_UV_MATRIX], null);
				ret += agal("tex", "ft2", null, "ft1", "xy", assetsDict[FS_OPACITY] + texParameter("2d"), null);
				ret += agal("mov", assetsDict[FT_OC], "w", "ft2", "x");
				ret += agal("mov", "oc", null, assetsDict[FT_OC], "xyzw");
			}
			else
			{
				if(assetsDict[MATERIAL_ALPHA]) //透明材质。
				{
					ret += agal("mov", assetsDict[FT_OC], "w", assetsDict[MATERIAL_ALPHA], "x");
					ret += agal("mov", "oc", null, assetsDict[FT_OC], "xyzw");
				}
				else //不透明材质。
					ret += agal("mov", "oc", null, assetsDict[FT_OC], "xyz");
			}
			
			return ret;
		}
	}
}