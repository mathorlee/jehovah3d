package jehovah3d.core.renderer
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.ShaderResource;

	public class Renderer
	{
		public static const NAME:String = "Renderer";
		
		protected var _mesh:Mesh;
		protected var _shader:ShaderResource;
		
		protected var textures:Vector.<TextureBase> = new Vector.<TextureBase>();
		protected var textureSamplers:Vector.<uint> = new Vector.<uint>();
		protected var vertexBuffers:Vector.<VertexBuffer3D> = new Vector.<VertexBuffer3D>();
		protected var vertexBufferIndices:Vector.<uint> = new Vector.<uint>();
		protected var vertexBufferFormats:Vector.<String> = new Vector.<String>();
		
		protected var vertexConstants:Vector.<Number> = new Vector.<Number>();
		protected var fragmentConstants:Vector.<Number> = new Vector.<Number>();
		
		public function Renderer(mesh:Mesh)
		{
			_mesh = mesh;
		}
		
		public function get mesh():Mesh
		{
			return _mesh;
		}
		public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			collectResource();
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
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, vertexConstants, vertexConstants.length / 4);
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
		
		public function collectResource():void
		{
			
		}
		public function generateVertexShader(assetsDict:Dictionary):String
		{
			return "";
		}
		public function generateFragmentShader(assetsDict:Dictionary):String
		{
			return "";
		}
		public function dispose():void
		{
			_mesh = null;
			if(_shader)
			{
				_shader.dispose();
				_shader = null;
			}
			if(textures)
			{
				textures.length = 0;
				textures = null;
			}
			if(textureSamplers)
			{
				textureSamplers.length = 0;
				textureSamplers = null;
			}
			if(vertexBuffers)
			{
				vertexBuffers.length = 0;
				vertexBuffers = null;
			}
			if(vertexBufferIndices)
			{
				vertexBufferIndices.length = 0;
				vertexBufferIndices = null;
			}
			if(vertexBufferFormats)
			{
				vertexBufferFormats.length = 0;
				vertexBufferFormats = null;
			}
			if(vertexConstants)
			{
				vertexConstants.length = 0;
				vertexConstants = null;
			}
			if(fragmentConstants)
			{
				fragmentConstants.length = 0;
				fragmentConstants = null;
			}
		}
		
		/**
		 * dispose shader.
		 * 
		 */		
		public function disposeShader():void
		{
			if(_shader)
			{
				_shader.dispose();
				_shader = null;
			}
		}
		
		
		
		
		
		public function currentVC():String
		{
			return "vc" + String(vertexConstants.length / 4);
		}
		public function currentVCIndex():int
		{
			return vertexConstants.length / 4;
		}
		public function currentFC():String
		{
			if(fragmentConstants.length % 4 != 0)
				throw new Error("");
			return "fc" + String(fragmentConstants.length / 4);
		}
		public function currentFCIndex():int
		{
			return fragmentConstants.length / 4;
		}
		public static function CVVUVToScreenUVMatrix():Vector.<Number>
		{
			return Vector.<Number>([
				0.5, 0, 0.5, 1, 
				0, -0.5, 0.5, 1, 
				0, 0, 1, 1
			]);
		}
		public static function ScreenUVToCVVUVMatrix():Vector.<Number>
		{
			return Vector.<Number>([
				2, 0, -1, 1, 
				0, -2, 1, 1, 
				0, 0, 1, 1
			]);
		}
		
		public static function dunkM44(m44:Matrix3D, constants:Vector.<Number>):void
		{
			constants.push(m44.rawData[0], m44.rawData[4], m44.rawData[8], m44.rawData[12]);
			constants.push(m44.rawData[1], m44.rawData[5], m44.rawData[9], m44.rawData[13]);
			constants.push(m44.rawData[2], m44.rawData[6], m44.rawData[10], m44.rawData[14]);
			constants.push(m44.rawData[3], m44.rawData[7], m44.rawData[11], m44.rawData[15]);
		}
		
		/**
		 *  
		 * @param dimension: 2d/3d/cube
		 * @param mip: nomip/mipnearest/miplinear
		 * @param filter: nearest/linear
		 * @param repeat: repeat/wrap/clamp
		 * @return 
		 * 
		 */		
		public function texParameter(dimension:String):String
		{
			var ret:String = "";
			if(mesh.useMip)
				ret += "<" + dimension + ",miplinear,linear,";
			else
				ret += "<" + dimension + ",nomip,linear,";
			
			if(dimension == "2d")
				ret += "repeat>";
			else if(dimension == "cube")
				ret += "clamp>";
			
			return ret;
		}
		
		public static function agal(opcode:String, destination:String, destinationMask:String, source1:String, source1Mask:String, source2:String = null, source2Mask:String = null):String
		{
			var ret:String = opcode + " ";
			
			ret += destination;
			if(destinationMask)
				ret += "." + destinationMask;
			ret += ", ";
			
			ret += source1;
			if(source1Mask)
				ret += "." + source1Mask;
			
			if(source2)
			{
				ret += ", ";
				ret += source2;
				if(source2Mask)
					ret += "." + source2Mask;
			}
			
			ret += "\n";
			
			return ret;
		}
		
		
		
		/**
		 * 生成FT_LIGHT_DIRECTION
		 * @param assetsDict
		 * @param resultRegister
		 * @param tmpRegister
		 * @return 
		 * 
		 */		
		protected function getLightDirection(assetsDict:Dictionary, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
			ret += agal("m44", tmpRegister, null, assetsDict[V_COORDINATE], null, assetsDict[C_LOCAL_TO_GLOBAL_MATRIX], null);
			ret += agal("sub", tmpRegister, "xyz", assetsDict[FLOAT4_LIGHT_POSITION], "xyz", tmpRegister, "xyz");
			ret += agal("nrm", tmpRegister, "xyz", tmpRegister, "xyz");
			ret += agal("mov", tmpRegister, "w", assetsDict[C_ONE].toString(1), null);
			ret += agal("sub", tmpRegister, "w", tmpRegister, "w", assetsDict[BOOL_LIGHT_TYPE_DIRECTIONAL].toString(1), null);
			ret += agal("mul", tmpRegister, "xyz", tmpRegister, "xyz", tmpRegister, "www");
			
			ret += agal("mov", resultRegister, "xyz", assetsDict[FLOAT4_LIGHT_DIRECTION], "xyz");
			ret += agal("mul", resultRegister, "xyz", resultRegister, "xyz", assetsDict[BOOL_LIGHT_TYPE_DIRECTIONAL].toString(1), null);
			ret += agal("add", resultRegister, "xyz", resultRegister, "xyz", tmpRegister, "xyz");
			
			return ret;
		}
		
		/**
		 * 生成FT_NORMAL
		 * @param assetsDict
		 * @param resultRegister
		 * @return 
		 * 
		 */		
		protected function getNormalRegister(assetsDict:Dictionary, resultRegister:String):String
		{
			var ret:String = "";
			
			//计算法线
			if(assetsDict[FS_BUMP] && assetsDict[V_TANGENT]) //使用法线贴图。
			{
				//ft3 = normal
				ret += agal("mov", "ft3", null, assetsDict[V_NORMAL], null);
				ret += agal("nrm", "ft3", "xyz", "ft3", "xyz");
				
				//ft1 = tangent
				ret += agal("mov", "ft1", null, assetsDict[V_TANGENT], null);
				ret += agal("nrm", "ft1", "xyz", "ft1", "xyz");
				
				//ft2 = binormal = crs(normal, tangent)
				ret += agal("crs", "ft2", "xyz", "ft3", "xyz", "ft1", "xyz"); //binormal = crs(normal, tangent)
				ret += agal("mov", "ft2", "w", "ft1", "w");
				
				//[ft4, ft5, ft6] = m33
				ret += agal("mov", "ft4", null, "ft1", null);
				ret += agal("mov", "ft5", null, "ft2", null);
				ret += agal("mov", "ft6", null, "ft3", null);
				ret += agal("mov", "ft4", "y", "ft2", "x");
				ret += agal("mov", "ft4", "z", "ft3", "x");
				ret += agal("mov", "ft5", "x", "ft1", "y");
				ret += agal("mov", "ft5", "z", "ft3", "y");
				ret += agal("mov", "ft6", "x", "ft1", "z");
				ret += agal("mov", "ft6", "y", "ft2", "z");
				
				//ft1 = normal in TBN coordinate system.
				ret += agal("dp3", "ft1", "x", assetsDict[V_UVW], "xyz", assetsDict[BUMP_UV_MATRIX], "xyz");
				ret += agal("dp3", "ft1", "y", assetsDict[V_UVW], "xyz", assetsDict[BUMP_UV_MATRIX].next(1), "xyz");
				ret += agal("tex", "ft2", null, "ft1", "xy", assetsDict[FS_BUMP] + texParameter("2d"), null);
				ret += agal("add", "ft1", "xyz", "ft2", "xyz", "ft2", "xyz");
				ret += agal("sub", "ft1", "xyz", "ft1", "xyz", assetsDict[FLOAT4_CAMERA_POSITON], "w");
				ret += agal("nrm", "ft1", "xyz", "ft1", "xyz");
				
				ret += agal("m33", resultRegister, "xyz", "ft1", "xyz", "ft4", null);
				ret += agal("m33", resultRegister, "xyz", assetsDict[FT_NORMAL], "xyz", assetsDict[C_LOCAL_TO_GLOBAL_MATRIX], null);
			}
			else //不使用法线贴图。
			{
				//只能在顶点程序中写入变化寄存器。
				ret += agal("m33", resultRegister, "xyz", assetsDict[V_NORMAL], "xyz", assetsDict[C_LOCAL_TO_GLOBAL_MATRIX], null);
				ret += agal("nrm", resultRegister, "xyz", assetsDict[FT_NORMAL], "xyz"); //ft7 = normal
			}
			
			return ret;
		}
		
		protected function calculateAmbientAndDiffuse(assetsDict:Dictionary, resultRegister:String):String
		{
			var ret:String = "";
			
			if(assetsDict[FS_DIFFUSE])
			{
				ret += agal("m33", resultRegister, "xyz", assetsDict[V_UVW], "xyz", assetsDict[DIFFUSE_UV_MATRIX], null);
				ret += agal("tex", resultRegister, null, resultRegister, "xy", assetsDict[FS_DIFFUSE] + texParameter("2d"), null);
			}
			else
				ret += agal("mov", resultRegister, null, assetsDict[DIFFUSE_COLOR], null);
			ret += agal("mul", resultRegister, "xyz", resultRegister, "xyz", assetsDict[FLOAT4_LIGHT_COLOR], "xyz"); //乘以灯光的颜色
			ret += agal("dp3", resultRegister, "w", assetsDict[FT_NORMAL], "xyz", assetsDict[FT_LIGHT_DIRECTION], "xyz"); //ft1.w = dot(N, I)
			ret += agal("sat", resultRegister, "w", resultRegister, "w"); //ft1.w = max(0, ft1.w)
			ret += agal("mul", resultRegister, "w", resultRegister, "w", assetsDict[C_DIFFUSE_COEFFICIENT].toString(1), null); //ft1.w *= diffuseCoefficient
			ret += agal("add", resultRegister, "w", resultRegister, "w", assetsDict[C_AMBIENT_COEFFICIENT].toString(1), null); //ft1.w += ambientCoefficient
			ret += agal("mul", resultRegister, "xyz", resultRegister, "xyz", resultRegister, "www");
			
			return ret;
		}
		
		protected function calculateSpecular(assetsDict:Dictionary, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
			ret += agal("dp3", tmpRegister, "w", assetsDict[FT_NORMAL], "xyz", assetsDict[FT_LIGHT_DIRECTION], "xyz"); //tmpRegister.w = dot(N, I)
			ret += agal("mul", tmpRegister, "xyz", assetsDict[FT_NORMAL], "xyz", tmpRegister, "www"); //tmpRegister.xyz = N * dot(N, I)
			ret += agal("add", tmpRegister, "xyz", tmpRegister, "xyz", tmpRegister, "xyz"); //tmpRegister.xyz = 2 * N * dot(N, I)
			ret += agal("sub", tmpRegister, "xyz", tmpRegister, "xyz", assetsDict[FT_LIGHT_DIRECTION], "xyz"); //tmpRegister = R = 2 * N * dot(N, I) - I
			
			ret += agal("m44", resultRegister, null, assetsDict[V_COORDINATE], null, assetsDict[C_LOCAL_TO_GLOBAL_MATRIX], null);
			ret += agal("sub", resultRegister, "xyz", assetsDict[FLOAT4_CAMERA_POSITON], "xyz", resultRegister, "xyz");
			ret += agal("nrm", resultRegister, "xyz", resultRegister, "xyz"); //resultRegister = E = CameraPosition - globalCoordinate
			ret += agal("dp3", resultRegister, "w", resultRegister, "xyz", tmpRegister, "xyz"); //resultRegister.w = dp3(R, E)
			ret += agal("sat", resultRegister, "w", resultRegister, "w");
			ret += agal("pow", resultRegister, "w", resultRegister, "w", assetsDict[GLOSSINESS].toString(1), null);
			ret += agal("mul", resultRegister, "w", resultRegister, "w", assetsDict[SPECULAR_LEVEL].toString(1), null); //resultRegister = specularCoefficient
			if(assetsDict[FS_SPECULAR])
			{
				ret += agal("dp3", tmpRegister, "x", assetsDict[V_UVW], "xyz", assetsDict[SPECULAR_UV_MATRIX], "xyz");
				ret += agal("dp3", tmpRegister, "y", assetsDict[V_UVW], "xyz", assetsDict[SPECULAR_UV_MATRIX].next(1), "xyz");
				ret += agal("tex", tmpRegister, null, tmpRegister, "xy", assetsDict[FS_SPECULAR] + texParameter("2d"), null);
				
				ret += agal("mul", resultRegister, "w", resultRegister, "w", assetsDict[SPECULAR_MAP_AMOUNT], "x"); //乘以map的amount属性。
			}
			else
				ret += agal("mov", tmpRegister, null, assetsDict[SPECULAR_COLOR], null); //ft2 = specularColor
			ret += agal("mul", tmpRegister, "xyz", tmpRegister, "xyz", assetsDict[FLOAT4_LIGHT_COLOR], "xyz"); //乘以灯光的颜色
			ret += agal("mul", resultRegister, "xyz", tmpRegister, "xyz", resultRegister, "www"); //ft1 = specular
			
			return ret;
		}
		
		protected function calculateReflection(assetsDict:Dictionary, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
			if(assetsDict[FS_REFLECTION])
			{
				//ft1 = 顶点到眼睛的射线，单位向量。
				ret += agal("m44", resultRegister, null, assetsDict[V_COORDINATE], null, assetsDict[C_LOCAL_TO_GLOBAL_MATRIX], null);
				ret += agal("sub", resultRegister, "xyz", assetsDict[FLOAT4_CAMERA_POSITON], "xyz", resultRegister, "xyz");
				ret += agal("nrm", resultRegister, "xyz", resultRegister, "xyz");
				
				//ft1 = 顶点到environment box的射线，单位向量。 R = 2 * N * dot(N, L) - L。
				ret += agal("dp3", resultRegister, "w", resultRegister, "xyz", assetsDict[FT_NORMAL], "xyz");
				ret += agal("mul", tmpRegister, "xyz", assetsDict[FT_NORMAL], "xyz", resultRegister, "www");
				ret += agal("add", tmpRegister, "xyz", tmpRegister, "xyz", tmpRegister, "xyz");
				ret += agal("sub", resultRegister, "xyz", tmpRegister, "xyz", resultRegister, "xyz");
				ret += agal("nrm", resultRegister, "xyz", resultRegister, "xyz"); 
				
				ret += agal("tex", resultRegister, null, resultRegister, "xyz", assetsDict[FS_REFLECTION] + texParameter("cube"), null);
				ret += agal("mul", resultRegister, "xyz", resultRegister, "xyz", assetsDict[REFLECTION_MAP_AMOUNT], "xyz");
			}
			else
				ret += agal("mov", resultRegister, "xyz", assetsDict[C_ZERO].toString(3), null);
			
			return ret;
		}
		
		
		
		
		
		
		/*
		以下是用来合成shader的。
		Functions below are to compound shader.
		*/
		
		//material alpha
		public static const MATERIAL_ALPHA:String = "MaterialAlpha";
		
		//use light
		public static const USE_SPCEULAR:String = "UseSpecular";
		
		//vertex attribute
		public static const VA_COORDINATE:String = "VA_Coordinate";
		public static const VA_COLOR:String = "VA_Color";
		public static const VA_NORMAL:String = "VA_Normal";
		public static const VA_UVW:String = "VA_UVW";
		public static const VA_TANGENT:String = "VA_Tangent";
		public static const VA_LIGHT_UVW:String = "VA_LightUVW";
		
		//variable
		public static const V_COORDINATE:String = "V_Coordinate";
		public static const V_COLOR:String = "V_Color";
		public static const V_NORMAL:String = "V_Normal";
		public static const V_UVW:String = "V_UVW";
		public static const V_TANGENT:String = "V_Tangent";
		public static const V_LIGHT_UVW:String = "V_LightUVW";
		public static const V_VIEW_SPACE_COORDINATE:String = "LightSpaceCoordinate"; //view坐标系下的坐标
		public static const V_CVV_COORDINATE:String = "CVVCoordinate"; //CVV坐标系下的坐标
		
		//matrix
		public static const C_FINALMATRIX:String = "FinalMatrix";
		public static const C_LOCAL_TO_GLOBAL_MATRIX:String = "LocalToGlobalMatrix";
		public static const C_LOCAL_TO_VIEW_MATRIX:String = "LocalToViewMatrix";
		public static const C_PROJECTION_MATRIX:String = "ProjectionMatrix";
		
		//fragment sampler
		public static const FS_DIFFUSE:String = "DiffuseMap";
		public static const FS_REFLECTION:String = "ReflectionMap";
		public static const FS_SPECULAR:String = "SpecularMap";
		public static const FS_BUMP:String = "BumpMap";
		public static const FS_OPACITY:String = "OpacityMap";
		public static const FS_LIGHT:String = "LightMap";
		public static const FS_LIGHTDEPTH:String = "LightDepth";
		
		public static const DIFFUSE_MAP_AMOUNT:String = "DiffuseMapAmount";
		public static const REFLECTION_MAP_AMOUNT:String = "ReflectionMapAmount";
		public static const SPECULAR_MAP_AMOUNT:String = "SpecularMapAmount";
		public static const BUMP_MAP_AMOUNT:String = "BumpMapAmount";
		public static const OPACITY_MAP_AMOUNT:String = "OpacityMapAmount";
		
		public static const DIFFUSE_UV_MATRIX:String = "DiffuseUVMatrix";
		public static const DIFFUSE_UV_MATRIX_ROW1:String = "DiffuseUVMatrixRow1";
		public static const DIFFUSE_UV_MATRIX_ROW2:String = "DiffuseUVMatrixRow2";
		public static const SPECULAR_UV_MATRIX:String = "SpecularUVMatrix";
		public static const REFLECTION_UV_MATRIX:String = "ReflectionUVMatrix";
		public static const BUMP_UV_MATRIX:String = "BumpUVMatrix";
		public static const OPACITY_UV_MATRIX:String = "OpacityUVMatrix";
		public static const LIGHT_UV_MATRIX:String = "LightUVMatrix";
		
		//常用常数
		public static const C_HALF:String = "Half";
		public static const C_NEGTIVE_ONE:String = "NegtiveOne";
		public static const C_ZERO:String = "Zero";
		public static const C_ONE:String = "One";
		public static const C_TWO:String = "Two";
		public static const C_THREE:String = "Three";
		public static const C_FOUR:String = "Four";
		public static const C_FIVE:String = "CFive";
		public static const C_SIX:String = "CSix";
		public static const C_SEVEN:String = "CSeven";
		public static const C_EIGHT:String = "CEight";
		public static const C_NINE:String = "CNine";
		public static const C_255:String = "255";
		public static const C_255_COMPOSE_DEPTH:String = "255DecomposeDepth"; //[1.0, 1.0 / 255, 1.0 / 255 / 255, 1.0], 用来根据depthTexture(R, G, B, A)计算depth(0-1之间)
		public static const C_DEPTH_COMPARE_TOLERANCE:String = "DEPTHCompareTolerance";
		public static const C_FLOAT:String = "CFloat";
		public static const C_SCREEN_SIZE:String = "CScreenSize";
		
		public static const C_ZFAR:String = "ZFar"; //camera.zFar
		public static const C_RCP_OF_LIGHT_VIEW_WIDTH:String = "RCPOfLightViewWidth";
		public static const C_RCP_OF_LIGHT_VIEW_HEIGHT:String = "RCPOfLightViewHeight";
		public static const C_AMBIENT_COEFFICIENT:String = "AmbientCoefficient";
		public static const C_DIFFUSE_COEFFICIENT:String = "DiffuseCoefficient";
		/**
		 * register.xyz = (zFar * tan(hFov / 2), zFar * tan(vFov / 2), -zFar)
		 */		
		public static const REGISTER_FRUMSTUM_XYZ:String = "FrustumXYZ";
		
		public static const C_CVVUV_TO_SCREENUV_MATRIX:String = "CVVUVToScreenUVMatirx";
		public static const C_SCREENUV_TO_CVVUV_MATRIX:String = "ScreenUVToCVVUVMatrix";
		
		public static const DIFFUSE_COLOR:String = "DiffuseColor";
		public static const SPECULAR_COLOR:String = "SpecularColor";
		public static const SPECULAR_LEVEL:String = "SpecularLevel";
		public static const GLOSSINESS:String = "Glossiness";
		
		public static const C_LINE_DEPTH_OFFSET:String = "C_LINE_DEPTH_OFFSET"; //wireframe易被面覆盖。将其CVV的z提高一些。
		public static const TMP_CONSTANT:String = "Tmp_Constant";
		
		//camera
		public static const FLOAT4_CAMERA_POSITON:String = "Float4CameraPosition";
		public static const FLOAT4_LIGHT_DIRECTION:String = "Float4LightDirection";
		public static const FLOAT4_LIGHT_POSITION:String = "Float4LightPosition";
		public static const FLOAT4_LIGHT_COLOR:String = "Float4LightColor";
		
		//fragment temporary
		public static const FT_NORMAL:String = "FragmentTemporary_Normal";
		public static const FT_OC:String = "FragmentTemporary_OC";
		public static const FT_LIGHT_DIRECTION:String = "FTLightDirection";
		
		/**
		 * 双面材质: 1, 单面材质: 0
		 */		
		public static const BOOL_TWO_SIDED:String = "BoolTwoSided";
		
		/**
		 * 圆截面: 1, 方界面: 0
		 */		
		public static const BOOL_LIGHT_CONE_CIRCLE:String = "BoolLightConeCircle";
		
		/**
		 * 平行光: 1, 锥形光: 0
		 */		
		public static const BOOL_LIGHT_TYPE_DIRECTIONAL:String = "BoolLightTypeDirection";
		/**
		 * 开启阴影: 1, 关闭阴影: 0
		 */		
		public static const BOOL_SHADOW_ON:String = "BoolShadowOn";
		
		/**
		 * float2 [1 / viewWidth, 1 / viewHeight]
		 */		
		public static const FLOAT2_TEXEL_SIZE:String = "Float2TexelSize";
	}
}