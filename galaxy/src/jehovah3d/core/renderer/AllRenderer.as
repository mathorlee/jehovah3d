package jehovah3d.core.renderer
{
	import com.fuwo.math.MyMath;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.material.LightMtl;
	import jehovah3d.core.material.StdMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	import jehovah3d.core.shader.ShaderConstant;
	
	public class AllRenderer extends Renderer
	{
		public static const NAME:String = "AllRenderer";
		
		private var tmp_buffers:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>(8);
		private var tmp_formats:Vector.<String> = new Vector.<String>(8);
		private var tmp_textures:Vector.<TextureBase> = new Vector.<TextureBase>(8);
		private var used_b:uint = 0;
		private var used_t:uint = 0;
		
		public function AllRenderer(mesh:Mesh)
		{
			super(mesh);
		}
		
		
		private function myRender2(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			myCollectResource();
			if(!_shader)
				return ;
			
			var i:uint;
			var usedBuffer:uint = 0;
			var usedTexture:uint = 0;
			
			if(mesh.mtl.sourceFactor != context3DProperty.sourceFactor || mesh.mtl.destinationFactor != context3DProperty.destinationFactor)
			{
				context3D.setBlendFactors(mesh.mtl.sourceFactor, mesh.mtl.destinationFactor);
				context3DProperty.sourceFactor = mesh.mtl.sourceFactor;
				context3DProperty.destinationFactor = mesh.mtl.destinationFactor;
			}
			if(context3DProperty.culling != mesh.mtl.culling)
			{
				context3DProperty.culling = mesh.mtl.culling;
				context3D.setCulling(mesh.mtl.culling);
			}
			context3DProperty.dispose(context3D);
			context3D.setProgram(_shader.program3D);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mesh.finalMatrix, true);
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, fragmentConstants, fragmentConstants.length / 4);
			for(i = 0; i < vertexBuffers.length; i ++)
			{
				context3D.setVertexBufferAt(vertexBufferIndices[i], vertexBuffers[i], 0, vertexBufferFormats[i]);
				usedBuffer |= (1 << vertexBufferIndices[i]);
			}
			for(i = 0; i < textures.length; i ++)
			{
				context3D.setTextureAt(textureSamplers[i], textures[i]);
				usedTexture |= (1 << textureSamplers[i]);
			}
			context3D.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangle);
			
			context3DProperty.usedBuffer = usedBuffer;
			context3DProperty.usedTexture = usedTexture;
		}
		private function myRender(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			myCollectResource();
			if(!_shader)
				return ;
			
			if(mesh.mtl.sourceFactor != context3DProperty.sourceFactor || mesh.mtl.destinationFactor != context3DProperty.destinationFactor)
			{
				context3D.setBlendFactors(mesh.mtl.sourceFactor, mesh.mtl.destinationFactor);
				context3DProperty.sourceFactor = mesh.mtl.sourceFactor;
				context3DProperty.destinationFactor = mesh.mtl.destinationFactor;
			}
			if(context3DProperty.culling != mesh.mtl.culling)
			{
				context3DProperty.culling = mesh.mtl.culling;
				context3D.setCulling(mesh.mtl.culling);
			}
			
			context3D.setProgram(_shader.program3D);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mesh.finalMatrix, true);
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, fragmentConstants, fragmentConstants.length / 4);
			
			var index:int;
			var bits:uint;
			bits = used_b | context3DProperty.usedBuffer;
			for(index = 0; bits > 0; index ++)
			{
				if((used_b & (1 << index)) < (context3DProperty.usedBuffer & (1 << index)))
					context3D.setVertexBufferAt(index, null);
				else
					context3D.setVertexBufferAt(index, tmp_buffers[index], 0, tmp_formats[index]);
				bits >>= 1;
			}
			bits = used_t | context3DProperty.usedTexture;
			for(index = 0; bits > 0; index ++)
			{
				if((used_t & (1 << index)) < (context3DProperty.usedTexture & (1 << index)))
					context3D.setTextureAt(index, null);
				else
					context3D.setTextureAt(index, tmp_textures[index]);
				bits >>= 1;
			}
			context3D.drawTriangles(mesh.geometry.indexBuffer, 0, mesh.geometry.numTriangle);
			
			context3DProperty.usedBuffer = used_b;
			context3DProperty.usedTexture = used_t;
		}
		private function myCollectResource2():void
		{
			if(_shader)
				return ;
			if(!_mesh.mtl || !_mesh.geometry)
				return ;
			
			vertexConstants.length = 0;
			fragmentConstants.length = 0;
			
			vertexBuffers.length = 0;
			vertexBufferIndices.length = 0;
			vertexBufferFormats.length = 0;
			
			textures.length = 0;
			textureSamplers.length = 0;
			
			var assetsDict:Dictionary = new Dictionary();
			assetsDict[C_FINALMATRIX] = currentVC();
			
			vertexBuffers.push(mesh.geometry.coordinateBuffer);
			vertexBufferIndices.push(0);
			vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
			assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
			assetsDict[VA_COORDINATE] = "va0";
			
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
			
			if(mesh.mtl is LightMtl)
			{
				//push light texture
				textures.push(LightMtl(mesh.mtl).lightMapResource.texture);
				textureSamplers.push(5);
				assetsDict[FS_LIGHT] = "fs5";
				
				//push uvw buffer
				vertexBuffers.push(mesh.geometry.lightUVBuffer);
				vertexBufferIndices.push(4);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_2);
				assetsDict[V_LIGHT_UVW] = "v4";
				assetsDict[VA_LIGHT_UVW] = "va4";
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShaderForLightMtl(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
			else
			{
				if(mesh.mtl.diffuseColor)
				{
					assetsDict[DIFFUSE_COLOR] = currentFC(); //diffuseColor
					fragmentConstants.push(mesh.mtl.diffuseColor.fractionalRed, mesh.mtl.diffuseColor.fractionalGreen, mesh.mtl.diffuseColor.fractionalBlue, mesh.mtl.diffuseColor.fractionalAlpha); //diffuse color
				}
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShaderForSimpleMtl(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
		}
		private function myCollectResource():void
		{
			if(_shader)
				return ;
			if(!_mesh.mtl || !_mesh.geometry)
				return ;
			
			var assetsDict:Dictionary = new Dictionary();
			assetsDict[C_FINALMATRIX] = currentVC();
			
			assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
			assetsDict[VA_COORDINATE] = "va0";
			tmp_buffers[0] = mesh.geometry.coordinateBuffer;
			tmp_formats[0] = Context3DVertexBufferFormat.FLOAT_3;
			used_b |= (1 << 0);
			
			if(mesh.mtl.useUVW)
			{
				//push uvw buffer
				assetsDict[V_UVW] = "v2";
				assetsDict[VA_UVW] = "va2";
				tmp_buffers[2] = mesh.geometry.diffuseUVBuffer;
				tmp_formats[2] = Context3DVertexBufferFormat.FLOAT_2;
				used_b |= (1 << 2);
			}
			if(mesh.mtl.useDiffuseMapChannel)
			{
				//push diffuse texture
				assetsDict[FS_DIFFUSE] = "fs0";
				tmp_textures[0] = mesh.mtl.diffuseMapResource.texture;
				used_t |= (1 << 0);
			}
			
			if(mesh.mtl is LightMtl)
			{
				//push light texture
				assetsDict[FS_LIGHT] = "fs5";
				tmp_textures[5] = LightMtl(mesh.mtl).lightMapResource.texture;
				used_t |= (1 << 5);
				
				//push uvw buffer
				assetsDict[V_LIGHT_UVW] = "v4";
				assetsDict[VA_LIGHT_UVW] = "va4";
				tmp_buffers[4] = mesh.geometry.lightUVBuffer;
				tmp_formats[4] = Context3DVertexBufferFormat.FLOAT_2;
				used_b |= (1 << 4);
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShaderForLightMtl(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
			else
			{
				if(mesh.mtl.diffuseColor)
				{
					assetsDict[DIFFUSE_COLOR] = currentFC(); //diffuseColor
					fragmentConstants.push(mesh.mtl.diffuseColor.fractionalRed, mesh.mtl.diffuseColor.fractionalGreen, mesh.mtl.diffuseColor.fractionalBlue, mesh.mtl.diffuseColor.fractionalAlpha); //diffuse color
				}
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShaderForSimpleMtl(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
		}
		override public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			if(_mesh.mtl is StdMtl)
				super.render(context3D, context3DProperty);
			else
				myRender(context3D, context3DProperty);
		}
		override public function collectResource():void
		{
			if(!_mesh.mtl || !_mesh.geometry || (_mesh.geometry && !_mesh.geometry.isUploaded))
				return ;
			
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
			MyMath.mergeTwoNumberVector(vertexConstants, MyMath.matrix3DToProgram3DConstants(mesh.finalMatrix), true);
			
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
			
			assetsDict[C_LOCAL_TO_GLOBAL_MATRIX] = currentFC(); //局部到全局矩阵
			MyMath.mergeTwoNumberVector(fragmentConstants, MyMath.matrix3DToProgram3DConstants(mesh.localToGlobalMatrix), true);
			
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
				
				if(!mesh.mtl.diffuseUVMatrix)
					mesh.mtl.diffuseUVMatrix = new Matrix();
				//push diffuse uv matrix.
				assetsDict[DIFFUSE_UV_MATRIX] = currentFC();
				fragmentConstants.push(mesh.mtl.diffuseUVMatrix.a, mesh.mtl.diffuseUVMatrix.b, mesh.mtl.diffuseUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.diffuseUVMatrix.c, mesh.mtl.diffuseUVMatrix.d, mesh.mtl.diffuseUVMatrix.ty, 1);
				fragmentConstants.push(0, 0, 0, 1);
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
			
			if(mesh.mtl.useSpecularMapChannel)
			{
				//push specular texture
				textures.push(mesh.mtl.specularMapResource.texture);
				textureSamplers.push(2);
				assetsDict[FS_SPECULAR] = "fs2";
				
				//push specular uv matrix
				assetsDict[SPECULAR_UV_MATRIX] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, currentFCIndex(), null);
				fragmentConstants.push(mesh.mtl.specularUVMatrix.a, mesh.mtl.specularUVMatrix.b, mesh.mtl.specularUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.specularUVMatrix.c, mesh.mtl.specularUVMatrix.d, mesh.mtl.specularUVMatrix.ty, 1);
				
				assetsDict[SPECULAR_MAP_AMOUNT] = currentFC();
				fragmentConstants.push(mesh.mtl.specularAmount, mesh.mtl.specularAmount, mesh.mtl.specularAmount, 1);
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
				assetsDict[C_AMBIENT_COEFFICIENT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
				assetsDict[C_DIFFUSE_COEFFICIENT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
				assetsDict[SPECULAR_LEVEL] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
				assetsDict[GLOSSINESS] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "w");
				fragmentConstants.push(Jehovah.ambientCoefficient, Jehovah.diffuseCoefficient, StdMtl(mesh.mtl).specularLevel / 100, StdMtl(mesh.mtl).glossiness)
				
				assetsDict[FLOAT4_CAMERA_POSITON] = currentFC(); //cameraPosition
				fragmentConstants.push(Jehovah.camera.x, Jehovah.camera.y, Jehovah.camera.z, 1);
				
				assetsDict[FLOAT4_LIGHT_DIRECTION] = currentFC(); //lightDirection
				fragmentConstants.push(Jehovah.defaultLight.direction.x, Jehovah.defaultLight.direction.y, Jehovah.defaultLight.direction.z, 1);
				
				assetsDict[FLOAT4_LIGHT_COLOR] = currentFC();
				fragmentConstants.push(Jehovah.defaultLight.color.fractionalRed, Jehovah.defaultLight.color.fractionalGreen, Jehovah.defaultLight.color.fractionalBlue, Jehovah.defaultLight.color.fractionalAlpha);
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShader(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
			else if(mesh.mtl is LightMtl)
			{
				//push light texture
				textures.push(LightMtl(mesh.mtl).lightMapResource.texture);
				textureSamplers.push(5);
				assetsDict[FS_LIGHT] = "fs5";
				
				//push uvw buffer
				vertexBuffers.push(mesh.geometry.lightUVBuffer);
				vertexBufferIndices.push(4);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_2);
				assetsDict[V_LIGHT_UVW] = "v4";
				assetsDict[VA_LIGHT_UVW] = "va4";
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShaderForLightMtl(assetsDict);
					_shader.upload(Jehovah.context3D);
				}
			}
			else
			{
				if(mesh.mtl.diffuseColor)
				{
					assetsDict[DIFFUSE_COLOR] = currentFC(); //diffuseColor
					fragmentConstants.push(mesh.mtl.diffuseColor.fractionalRed, mesh.mtl.diffuseColor.fractionalGreen, mesh.mtl.diffuseColor.fractionalBlue, mesh.mtl.diffuseColor.fractionalAlpha); //diffuse color
				}
				
				if(!_shader)
				{
					_shader = new ShaderResource();
					_shader.vertexShaderString = generateVertexShader(assetsDict);
					_shader.fragmentShaderString = generateFragmentShaderForSimpleMtl(assetsDict);
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
			if(assetsDict[VA_LIGHT_UVW])
				ret += agal("mov", assetsDict[V_LIGHT_UVW], null, assetsDict[VA_LIGHT_UVW], null);
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			assetsDict[FT_OC] = "ft0";
			assetsDict[FT_NORMAL] = "ft7";
			assetsDict[FT_LIGHT_DIRECTION] = "ft6";
			var ret:String = "";
			ret += getNormalRegister(assetsDict, assetsDict[FT_NORMAL]);
			ret += agal("mov", assetsDict[FT_LIGHT_DIRECTION], null, assetsDict[FLOAT4_LIGHT_DIRECTION], null);
			
			ret += calculateAmbientAndDiffuse(assetsDict, assetsDict[FT_OC]); //计算“环境光+漫反射”。
			
			//计算高光
			ret += calculateSpecular(assetsDict, "ft1", "ft2");
			ret += agal("add", assetsDict[FT_OC], "xyz", assetsDict[FT_OC], "xyz", "ft1", "xyz"); //oc = ambient + diffuse + specular
			
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
		
		private function generateFragmentShaderForSimpleMtl(assetsDict:Dictionary):String
		{
			var ret:String = "";
			
			if(assetsDict[FS_DIFFUSE])
				ret += agal("tex", "oc", null, assetsDict[V_UVW], "xy", assetsDict[FS_DIFFUSE] + texParameter("2d"), null);
			else if(assetsDict[DIFFUSE_COLOR])
				ret += agal("mov", "oc", null, assetsDict[DIFFUSE_COLOR], null);
			
			return ret;
		}
		
		private function generateFragmentShaderForLightMtl(assetsDict:Dictionary):String
		{
			/*
			"tex ft0, v2, fs0 <2d,linear,miplinear,repeat>", 
			"tex ft1, v3, fs1 <2d,linear,miplinear,repeat>", 
			"add ft1, ft1, ft1", 
			"mul ft0.xyz, ft0.xyz, ft1.xyz", 
			"mov oc, ft0"
			*/
			var ret:String = "";
			
			ret += agal("tex", "ft0", null, assetsDict[V_UVW], "xy", assetsDict[FS_DIFFUSE] + texParameter("2d"), null);
			ret += agal("tex", "ft1", null, assetsDict[V_LIGHT_UVW], "xy", assetsDict[FS_LIGHT] + texParameter("2d"), null);
			
			ret += agal("add", "ft1", null, "ft1", null, "ft1", null);
			ret += agal("mul", "ft0", "xyz", "ft0", "xyz", "ft1", "zyz");
			ret += agal("mov", "oc", null, "ft0", null);
			
			return ret;
		}
		
		override public function dispose():void
		{
			super.dispose();
			tmp_buffers.length = 0;
			tmp_formats.length = 0;
			tmp_textures.length = 0;
		}
	}
}