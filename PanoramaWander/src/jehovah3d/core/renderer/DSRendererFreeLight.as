package jehovah3d.core.renderer
{
	import com.fuwo.math.MyMath;
	
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.light.FreeLight3D;
	import jehovah3d.core.material.StdMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;
	import jehovah3d.core.shader.ShaderConstant;
	
	/**
	 * diffuse and specular renderer under free light
	 * @author Administrator
	 * 
	 */	
	public class DSRendererFreeLight extends Renderer
	{
		public static const NAME:String = "DSRendererFreeLight";
		
		private var _freeLight:FreeLight3D;
		
		public function DSRendererFreeLight(mesh:Mesh, freeLight:FreeLight3D)
		{
			super(mesh);
			_freeLight = freeLight;
		}
		
		public function get freeLight():FreeLight3D
		{
			return _freeLight;
		}
		
		/**
		 * <b>shadow mapping:</b><br>
		 * p0: global point<br>
		 * p1: light space point, p1 = light.inverseMatrix * p0<br>
		 * p2: cvv point, -1 <= p2.xy <= 1, 0 <= p2.z <= 1, p2 = light.projectMatrix * p1, p2.xyzw/p2.wwww<br>
		 * depth0 = -p1.z / zFar<br>
		 * p3.xy = cvvuv_to_screenuv_matrix * p2.xy<br>
		 * depth1 = tex2D(p3.xy, light.depthTexture)<br>
		 * if(depth0 < depth1) 像素被照亮<br>
		 * @param assetsDict
		 * @return 
		 * 
		 */		
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
			assetsDict[C_FINALMATRIX] = currentVC(); //Final矩阵
			MyMath.mergeTwoNumberVector(vertexConstants, MyMath.matrix3DToProgram3DConstants(mesh.finalMatrix), true);
			var localToLight:Matrix3D = mesh.localToGlobalMatrix.clone();
			if(Jehovah.useDefaultLight)
				localToLight.append(freeLight.inverseMatrix);
			else
				localToLight.append(freeLight.globalToLocalMatrix);
			assetsDict[C_LOCAL_TO_VIEW_MATRIX] = currentVC(); //局部到灯光矩阵
			MyMath.mergeTwoNumberVector(vertexConstants, MyMath.matrix3DToProgram3DConstants(localToLight), true);
			assetsDict[C_PROJECTION_MATRIX] = currentVC(); //灯光的投影矩阵
			MyMath.mergeTwoNumberVector(vertexConstants, MyMath.matrix3DToProgram3DConstants(freeLight.projectionMatrix), true);
			
			//push coordinate buffer
			if(mesh.geometry.coordinateBuffer)
			{
				vertexBuffers.push(mesh.geometry.coordinateBuffer);
				vertexBufferIndices.push(0);
				vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
				assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
				assetsDict[VA_COORDINATE] = "va0";
				
				assetsDict[V_VIEW_SPACE_COORDINATE] = "v3";
				assetsDict[V_CVV_COORDINATE] = "v4";
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
			
			index = currentFCIndex();
			assetsDict[C_ZERO] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[C_ONE] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[C_DEPTH_COMPARE_TOLERANCE] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			assetsDict[C_ZFAR] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "w");
			fragmentConstants.push(0, 1, freeLight.depthCompareTolerance, freeLight.zFar);
			
			index = currentFCIndex();
			assetsDict[C_RCP_OF_LIGHT_VIEW_WIDTH] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[C_RCP_OF_LIGHT_VIEW_HEIGHT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[C_FIVE] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			assetsDict[C_NINE] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "w");
			fragmentConstants.push(1.0 / 1024, 1.0 / 1024, 5, 9);
			
			assetsDict[C_255_COMPOSE_DEPTH] = currentFC();
			fragmentConstants.push(1.0, 1.0 / 255, 1.0 / 255 / 255, 1.0 / 255 / 255 / 255);
			assetsDict[C_CVVUV_TO_SCREENUV_MATRIX] = currentFC();
			MyMath.mergeTwoNumberVector(fragmentConstants, CVVUVToScreenUVMatrix(), true);
			
			if(mesh.mtl.useDiffuseMapChannel)
			{
				//push diffuse texture
				textures.push(mesh.mtl.diffuseMapResource.texture);
				textureSamplers.push(0);
				assetsDict[FS_DIFFUSE] = "fs0";
				
				//push diffuse uv matrix.
				assetsDict[DIFFUSE_UV_MATRIX] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, currentFCIndex(), null);
				fragmentConstants.push(mesh.mtl.diffuseUVMatrix.a, mesh.mtl.diffuseUVMatrix.b, mesh.mtl.diffuseUVMatrix.tx, 1);
				fragmentConstants.push(mesh.mtl.diffuseUVMatrix.c, mesh.mtl.diffuseUVMatrix.d, mesh.mtl.diffuseUVMatrix.ty, 1);
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
			
			//light depth
			textures.push(freeLight.depthTexture);
			textureSamplers.push(5);
			assetsDict[FS_LIGHTDEPTH] = "fs5";
			
			var shadowOn:int = freeLight.useShadow ? 1 : 0;
			var circleCone:int = freeLight.lightCone == FreeLight3D.CONE_CIRCLE ? 1 : 0;
			var directionalType:int = freeLight.lightType == FreeLight3D.TYPE_DIRECTIONAL_LIGHT ? 1 : 0;
			index = currentFCIndex();
			assetsDict[BOOL_SHADOW_ON] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[BOOL_LIGHT_CONE_CIRCLE] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[BOOL_LIGHT_TYPE_DIRECTIONAL] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			fragmentConstants.push(shadowOn, circleCone, directionalType, 1);
			
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
				fragmentConstants.push(0, Jehovah.diffuseCoefficient, StdMtl(mesh.mtl).specularLevel / 100, StdMtl(mesh.mtl).glossiness)
				
				var v0:Vector3D;
				//相机位置
				assetsDict[FLOAT4_CAMERA_POSITON] = currentFC();
				fragmentConstants.push(Jehovah.camera.x, Jehovah.camera.y, Jehovah.camera.z, 1);
				//灯光位置
				assetsDict[FLOAT4_LIGHT_POSITION] = currentFC();
				v0 = freeLight.globalPosition;
				fragmentConstants.push(v0.x, v0.y, v0.z, 1);
				//灯光方向
				assetsDict[FLOAT4_LIGHT_DIRECTION] = currentFC();
				v0 = freeLight.direction;
				fragmentConstants.push(v0.x, v0.y, v0.z, 1);
				//灯光颜色
				assetsDict[FLOAT4_LIGHT_COLOR] = currentFC();
				fragmentConstants.push(freeLight.color.fractionalRed, freeLight.color.fractionalGreen, freeLight.color.fractionalBlue, freeLight.color.fractionalAlpha);
				
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
			
			ret += agal("m44", "op", null, assetsDict[VA_COORDINATE], null, assetsDict[C_FINALMATRIX], null);
			ret += agal("m44", "vt0", null, assetsDict[VA_COORDINATE], null, assetsDict[C_LOCAL_TO_VIEW_MATRIX], null);
			ret += agal("mov", assetsDict[V_VIEW_SPACE_COORDINATE], null, "vt0", null);
			ret += agal("m44", "vt0", null, "vt0", null, assetsDict[C_PROJECTION_MATRIX], null);
			ret += agal("mov", assetsDict[V_CVV_COORDINATE], null, "vt0", null);
			
			ret += agal("mov", assetsDict[V_COORDINATE], null, assetsDict[VA_COORDINATE], null); //coordinate
			if(assetsDict[VA_NORMAL]) //normal
				ret += agal("mov", assetsDict[V_NORMAL], null, assetsDict[VA_NORMAL], null);
			if(assetsDict[VA_UVW]) //uvw
			{
				ret += agal("mov", assetsDict[V_UVW], null, assetsDict[VA_UVW], null);
				ret += agal("mov", assetsDict[V_UVW], "z", "vc7", "w");
			}
			if(assetsDict[VA_TANGENT]) //tangent
				ret += agal("mov", assetsDict[V_TANGENT], null, assetsDict[VA_TANGENT], null);
			
			return ret;
		}
		
		/**
		 * 判断像素是否可见
		 * @param assetsDict
		 * @param resultRegister
		 * @return 
		 * 
		 */		
		private function checkIfPixelIsLit(assetsDict:Dictionary, resultRegister:String):String
		{
			/*
			A = [1 - (圆 * (sqr(x) + sqr(y) > 1))] * (-1 <= x <= 1) * (-1 <= y <= 1) * (0 <= z <= 1)
			B = PCF, 0<=B<=1
			C = 1 - (1 - B) * shadowOn
			return A * C
			mul oc.xyz, oc.xyz, BBB
			*/
			var ret:String = "";
			
			ret += agal("div", resultRegister, "xyzw", assetsDict[V_CVV_COORDINATE], "xyzw", assetsDict[V_CVV_COORDINATE], "wwww");
			ret += agal("div", "ft3", "x", assetsDict[V_VIEW_SPACE_COORDINATE], "z", assetsDict[C_ZFAR].toString(1), null);
			ret += agal("neg", "ft3", "x", "ft3", "x"); //计算depth0, 暂存在ft3.x
			
			ret += agal("sge", "ft1", "w", resultRegister, "z", assetsDict[C_ZERO].toString(1), null); //z >= 0
			ret += agal("sge", "ft1", "z", assetsDict[C_ONE].toString(1), null, resultRegister, "z"); //1 >= z
			ret += agal("mul", "ft1", "w", "ft1", "w", "ft1", "z"); //0 <= z <= 1
			
			ret += agal("abs", "ft1", "xy", resultRegister, "xy");
			ret += agal("sge", "ft1", "z", assetsDict[C_ONE].toString(1),null, "ft1", "x");
			ret += agal("mul", "ft1", "w", "ft1", "w", "ft1", "z");
			ret += agal("sge", "ft1", "z", assetsDict[C_ONE].toString(1),null, "ft1", "y");
			ret += agal("mul", "ft1", "w", "ft1", "w", "ft1", "z"); //(-1 <= x <= 1) * (-1 <= y <= 1) * (0 <= z <= 1)
			
			ret += agal("mul", "ft2", "xy", "ft1", "xy", "ft1", "xy");
			ret += agal("add", "ft2", "x", "ft2", "x", "ft2", "y");
			ret += agal("slt", "ft2", "x", assetsDict[C_ONE].toString(1), null, "ft2", "x"); //(sqr(x) + sqr(y) > 1
			ret += agal("mul", "ft2", "x", "ft2", "x", assetsDict[BOOL_LIGHT_CONE_CIRCLE].toString(1), null); //圆 * (sqr(x) + sqr(y) > 1)
			ret += agal("sub", "ft2", "x", assetsDict[C_ONE].toString(1), null, "ft2", "x"); //[1 - (圆 * (sqr(x) + sqr(y) > 1))]
			ret += agal("mul", "ft1", "w", "ft1", "w", "ft2", "x"); //A = [1 - (圆 * (sqr(x) + sqr(y) > 1))] * (-1 <= x <= 1) * (-1 <= y <= 1) * (0 <= z <= 1)
			
			//shadow mapping
			ret += agal("mov", "ft1", "xy", resultRegister, "xy");
			ret += agal("mov", "ft1", "z", assetsDict[C_ONE].toString(1), null); //cvv uv
			ret += agal("m33", "ft1", "xyz", "ft1", "xyz", assetsDict[C_CVVUV_TO_SCREENUV_MATRIX], null); //screen uv
			
			//PCF(0, 0)
			ret += agal("tex", "ft2", null, "ft1", "xy", assetsDict[FS_LIGHTDEPTH] + "<2d,nomip,linear,clamp>", null);
			ret += agal("dp4", "ft2", "x", "ft2", "xyzw", assetsDict[C_255_COMPOSE_DEPTH], "xyzw"); //depth1
			ret += agal("add", "ft2", "x", "ft2", "x", assetsDict[C_DEPTH_COMPARE_TOLERANCE].toString(1), null);
			ret += agal("sge", "ft1", "z", "ft2", "x", "ft3", "x"); //ft1.z存储PCF(percentage closer filter)
			
			//PCF(1, 0)
			ret += agal("add", "ft2", "x", "ft1", "x", assetsDict[C_RCP_OF_LIGHT_VIEW_WIDTH].toString(1), null);
			ret += agal("mov", "ft2", "y", "ft1", "y");
			ret += agal("tex", "ft2", null, "ft2", "xy", assetsDict[FS_LIGHTDEPTH] + "<2d,nomip,linear,clamp>", null);
			ret += agal("dp4", "ft2", "x", "ft2", "xyzw", assetsDict[C_255_COMPOSE_DEPTH], "xyzw"); //depth1
			ret += agal("add", "ft2", "x", "ft2", "x", assetsDict[C_DEPTH_COMPARE_TOLERANCE].toString(1), null);
			ret += agal("sge", "ft2", "x", "ft2", "x", "ft3", "x"); //ft1.z存储PCF(percentage closer filter)
			ret += agal("add", "ft1", "z", "ft1", "z", "ft2", "x");
			
			//PCF(-1, 0)
			ret += agal("sub", "ft2", "x", "ft1", "x", assetsDict[C_RCP_OF_LIGHT_VIEW_WIDTH].toString(1), null);
			ret += agal("mov", "ft2", "y", "ft1", "y");
			ret += agal("tex", "ft2", null, "ft2", "xy", assetsDict[FS_LIGHTDEPTH] + "<2d,nomip,linear,clamp>", null);
			ret += agal("dp4", "ft2", "x", "ft2", "xyzw", assetsDict[C_255_COMPOSE_DEPTH], "xyzw"); //depth1
			ret += agal("add", "ft2", "x", "ft2", "x", assetsDict[C_DEPTH_COMPARE_TOLERANCE].toString(1), null);
			ret += agal("sge", "ft2", "x", "ft2", "x", "ft3", "x"); //ft1.z存储PCF(percentage closer filter)
			ret += agal("add", "ft1", "z", "ft1", "z", "ft2", "x");
			
			//PCF(0, 1)
			ret += agal("mov", "ft2", "x", "ft1", "x");
			ret += agal("add", "ft2", "y", "ft1", "y", assetsDict[C_RCP_OF_LIGHT_VIEW_HEIGHT].toString(1), null);
			ret += agal("tex", "ft2", null, "ft2", "xy", assetsDict[FS_LIGHTDEPTH] + "<2d,nomip,linear,clamp>", null);
			ret += agal("dp4", "ft2", "x", "ft2", "xyzw", assetsDict[C_255_COMPOSE_DEPTH], "xyzw"); //depth1
			ret += agal("add", "ft2", "x", "ft2", "x", assetsDict[C_DEPTH_COMPARE_TOLERANCE].toString(1), null);
			ret += agal("sge", "ft2", "x", "ft2", "x", "ft3", "x"); //ft1.z存储PCF(percentage closer filter)
			ret += agal("add", "ft1", "z", "ft1", "z", "ft2", "x");
			
			//PCF(0, -1)
			ret += agal("mov", "ft2", "x", "ft1", "x");
			ret += agal("sub", "ft2", "y", "ft1", "y", assetsDict[C_RCP_OF_LIGHT_VIEW_HEIGHT].toString(1), null);
			ret += agal("tex", "ft2", null, "ft2", "xy", assetsDict[FS_LIGHTDEPTH] + "<2d,nomip,linear,clamp>", null);
			ret += agal("dp4", "ft2", "x", "ft2", "xyzw", assetsDict[C_255_COMPOSE_DEPTH], "xyzw"); //depth1
			ret += agal("add", "ft2", "x", "ft2", "x", assetsDict[C_DEPTH_COMPARE_TOLERANCE].toString(1), null);
			ret += agal("sge", "ft2", "x", "ft2", "x", "ft3", "x"); //ft1.z存储PCF(percentage closer filter)
			ret += agal("add", "ft1", "z", "ft1", "z", "ft2", "x");
			
			ret += agal("div", "ft1", "z", "ft1", "z", assetsDict[C_FIVE].toString(1), null); //B = PCF
			
			ret += agal("sub", "ft1", "z", assetsDict[C_ONE].toString(1), null, "ft1", "z");
			ret += agal("mul", "ft1", "z", "ft1", "z", assetsDict[BOOL_SHADOW_ON].toString(1), null);
			ret += agal("sub", "ft1", "z", assetsDict[C_ONE].toString(1), null, "ft1", "z"); //C = 1 - (1 - B) * shadowon
			
			ret += agal("mul", resultRegister, "w", "ft1", "z", "ft1", "w"); //最后存储在ft0.w中，ft0.w = A * C
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			assetsDict[FT_OC] = "ft0";
			assetsDict[FT_NORMAL] = "ft7";
			assetsDict[FT_LIGHT_DIRECTION] = "ft6";
			var ret:String = "";
			ret += checkIfPixelIsLit(assetsDict, assetsDict[FT_OC]);
			ret += getNormalRegister(assetsDict, assetsDict[FT_NORMAL]);
			ret += getLightDirection(assetsDict, assetsDict[FT_LIGHT_DIRECTION], "ft5");
			
			//计算“环境光+漫反射”。
			ret += calculateAmbientAndDiffuse(assetsDict, "ft1");
			ret += agal("mul", assetsDict[FT_OC], "xyz", "ft1", "xyz", assetsDict[FT_OC], "www");
			
			//计算高光
			ret += calculateSpecular(assetsDict, "ft1", "ft2");
			ret += agal("mul", "ft1", "xyz", "ft1", "xyz", assetsDict[FT_OC], "www"); //乘以0/1，是否被照亮
			ret += agal("add", assetsDict[FT_OC], "xyz", assetsDict[FT_OC], "xyz", "ft1", "xyz"); //oc = ambient + diffuse + specular
			
			//输出颜色
			ret += agal("mov", "oc", null, assetsDict[FT_OC], "xyz");
			return ret;
		}
		
		override public function dispose():void
		{
			super.dispose();
			_freeLight = null;
		}
	}
}