package jehovah3d.core.renderer
{
	import com.fuwo.math.MyMath;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.ShaderResource;
	import jehovah3d.core.resource.TextureResource;
	import jehovah3d.core.shader.ShaderConstant;
	
	/**
	 * SSAO<br>
	 * @author lisongsong
	 * 
	 */	
	public class SSAORenderer extends Renderer
	{
		public static const NAME:String = "SSAORenderer";
		
		[Embed(source="/jehovah3d/assets/noise.jpg", mimeType="image/jpeg")]
		private var NOISE_BITMAP:Class;
		
		public var depthTexture:TextureBase;
		public var normalTexture:TextureBase;
		public var noiseTexture:TextureBase;
		
		private var _geometry:GeometryResource;
		
		public var scale:Number = 0.02;
		public var bias:Number = 0.1;
		public var sampleRadius:Number = 30;
		public var intensity:Number = 1.0;
		
		public function SSAORenderer(mesh:Mesh)
		{
			super(mesh);
			initGeometry();
		}
		
		private function initGeometry():void
		{
			_geometry = new GeometryResource();
			_geometry.coordinateData = Vector.<Number>([
				1, 1, 0.5, 
				-1, 1, 0.5, 
				-1, -1, 0.5, 
				1, -1, 0.5
			]);
			_geometry.indexData = Vector.<uint>([
				0, 1, 2, 0, 2, 3
			]);
			_geometry.upload(Jehovah.context3D);
		}
		
		private function generateNoiseTexture():void
		{
			var bmd:BitmapData = new NOISE_BITMAP().bitmapData as BitmapData;
			var tr:TextureResource = new TextureResource(bmd, true);
			tr.upload(Jehovah.context3D);
			noiseTexture = tr.texture;
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
			if(!noiseTexture)
				generateNoiseTexture();
			textures.push(depthTexture, normalTexture, noiseTexture);
			textureSamplers.push(0, 1, 2);
			
			var assetsDict:Dictionary = new Dictionary();
			var tmp:Number;
			var index:int;
			
			//push coordinate buffer
			vertexBuffers.push(_geometry.coordinateBuffer);
			vertexBufferIndices.push(0);
			vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
			assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
			assetsDict[VA_COORDINATE] = "va0";
			
			vertexConstants.push(1, 2, 0, 0);
			
			//投影矩阵，ViewToCVVMatrix
			var pm:Matrix3D = Jehovah.camera.pm;
			assetsDict[C_PROJECTION_MATRIX] = currentFC();
			fragmentConstants.push(pm.rawData[0], pm.rawData[4], pm.rawData[8], pm.rawData[12]);
			fragmentConstants.push(pm.rawData[1], pm.rawData[5], pm.rawData[9], pm.rawData[13]);
			fragmentConstants.push(pm.rawData[2], pm.rawData[6], pm.rawData[10], pm.rawData[14]);
			fragmentConstants.push(pm.rawData[3], pm.rawData[7], pm.rawData[11], pm.rawData[15]);
			
			//视椎尺寸
			assetsDict[REGISTER_FRUMSTUM_XYZ] = currentFC();
			tmp = Jehovah.camera.zFar * Math.tan(Jehovah.camera.fov / 2);
			fragmentConstants.push(tmp, tmp / Jehovah.camera.screenRatio, -Jehovah.camera.zFar, 1);
			
			assetsDict[C_255_COMPOSE_DEPTH] = currentFC();
			fragmentConstants.push(1.0, 1.0 / 255, 1.0 / 255 / 255, 1.0 / 255 / 255 / 255);
			
			index = currentFCIndex();
			assetsDict[C_HALP] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[C_ZERO] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[C_ONE] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			assetsDict[C_TWO] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "w");
			fragmentConstants.push(0.5, 0, 1, 2);
			
			index = currentFCIndex();
			assetsDict[FLOAT_RANDOM_UV_REPEAT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[C_FOUR] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[FLOAT_BIAS] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			assetsDict[FLOAT_INTENSITY] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "w");
			fragmentConstants.push(8, 4, bias, intensity);
			
			index = currentFCIndex();
			assetsDict[FLOAT_SAMPLE_RADIUS] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "x");
			assetsDict[FLOAT_LINEAR_ATTENUATION] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "y");
			assetsDict[C_EIGHT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "z");
			assetsDict[C_FLOAT] = new ShaderConstant(ShaderConstant.FRAGMENT_CONSTANT, index, "w");
			fragmentConstants.push(sampleRadius, scale, 8, 1 / 255);
			
			assetsDict[C_SCREENUV_TO_CVVUV_MATRIX] = currentFC();
			MyMath.mergeTwoNumberVector(fragmentConstants, Renderer.ScreenUVToCVVUVMatrix(), true);
			
			assetsDict[M33_ROTATE_45_DEGREE_BY_Z] = currentFC();
			MyMath.mergeTwoNumberVector(fragmentConstants, rotateFortyFiveDegreeMatrix(), true);
			
			assetsDict[FLOAT2_TEXEL_SIZE] = currentFC();
			fragmentConstants.push(1 / Jehovah.camera.viewWidth, 1 / Jehovah.camera.viewHeight, 0, 0);
			
			var kernals:Vector.<Vector3D> = generateKernal();
			var i:int;
			for(i = 0; i < kernals.length; i ++)
			{
				assetsDict[KERNAL_AT + String(i)] = currentFC();
				fragmentConstants.push(kernals[i].x, kernals[i].y, kernals[i].z, 1);
			}
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(assetsDict);
				_shader.fragmentShaderString = generateFragmentShader(assetsDict);
//				trace("new ssao shader:");
//				trace(_shader.vertexShaderString);
//				trace(_shader.fragmentShaderString);
//				var arr:Array = _shader.fragmentShaderString.split("\n");
//				trace(arr.length);
				_shader.upload(Jehovah.context3D);
			}
		}
		
		override public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			collectResource();
			
			var i:uint;
			var usedBuffer:uint = 0;
			var usedTexture:uint = 0;
			
			context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
			context3DProperty.sourceFactor = Context3DBlendFactor.ONE;
			context3DProperty.destinationFactor = Context3DBlendFactor.ZERO;
			context3DProperty.culling = Context3DTriangleFace.FRONT;
			context3D.setCulling(Context3DTriangleFace.FRONT);
			
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
			context3D.drawTriangles(_geometry.indexBuffer, 0, _geometry.numTriangle);
			
			context3DProperty.usedBuffer = usedBuffer;
			context3DProperty.usedTexture = usedTexture;
		}
		
		override public function generateVertexShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			ret += agal("mov", "op", null, "va0", null);
			ret += agal("mov", "vt0", null, "va0", null);
			ret += agal("neg", "vt0", "y", "vt0", "y");
			ret += agal("add", "vt0", "xy", "vt0", "xy", "vc0.xx", null);
			ret += agal("div", "vt0", "xy", "vt0", "xy", "vc0.yy", null);
			ret += agal("mov", "v0", null, "vt0", null);
			
			ret += agal("mov", "v1", null, "va0", null);
			
			return ret;
		}
		
		/**
		 * resultRegister.xyz存储View坐标系下的坐标, resultRegister.w存储线性深度
		 * @param assetsDict 哈希表
		 * @param screenUV 屏幕UV
		 * @param depthBuffer 深度缓冲
		 * @param resultRegister 目标寄存器, 存储结果
		 * @param tmpRegister 临时寄存器
		 * @return 
		 * 
		 */		
		private function getPosition(assetsDict:Dictionary, screenUV:String, depthBuffer:String, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
			ret += agal("tex", resultRegister, null, screenUV, "xy", depthBuffer + "<2d,miplinear,linear,clamp>", null);
			ret += agal("dp4", resultRegister, "w", resultRegister, "xyzw", assetsDict[C_255_COMPOSE_DEPTH], "xyzw"); //resultRegister.w = depth
			
			ret += agal("mov", tmpRegister, "xy", screenUV, "xy");
			ret += agal("mov", tmpRegister, "z", assetsDict[C_ONE].toString(1), null);
			ret += agal("m33", tmpRegister, "xyz", tmpRegister, "xyz", assetsDict[C_SCREENUV_TO_CVVUV_MATRIX], null); //tmpRegister.xy = cvvuv
			
//			ret += agalExpression("mov", tmpRegister, "w", assetsDict[C_ONE].toString(1), null);
//			ret += agalExpression("mov", "oc", null, tmpRegister, null);
			
			ret += agal("mul", tmpRegister, "xyz", tmpRegister, "xyz", assetsDict[REGISTER_FRUMSTUM_XYZ], "xyz");
			ret += agal("mul", resultRegister, "xyz", tmpRegister, "xyz", resultRegister, "www");
			
			return ret;
		}
		
		private function getNormal(assetsDict:Dictionary, screenUV:String, normalBuffer:String, resultRegister:String):String
		{
			var ret:String = "";
			
			ret += agal("tex", resultRegister, null, screenUV, "xy", normalBuffer + "<2d,miplinear,linear,clamp>", null);
			ret += agal("mul", resultRegister, "xyz", resultRegister, "xyz", assetsDict[C_TWO].toString(3), null);
			ret += agal("sub", resultRegister, "xyz", resultRegister, "xyz", assetsDict[C_ONE].toString(3), null);
			ret += agal("nrm", resultRegister, "xyz", resultRegister, "xyz");
			
			return ret;
		}
		
		private function getRandom(assetsDict:Dictionary, screenUV:String, randomBuffer:String, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
//			ret += agalExpression("mul", resultRegister, "xy", screenUV, "xy", assetsDict[SSAO_RANDOM_UV_REPEAT].toString(2), null);
			ret += agal("mov", resultRegister, "xy", screenUV, "xy");
			ret += agal("tex", resultRegister, null, resultRegister, "xy", randomBuffer + "<2d,nomip,nearest,repeat>", null);
//			ret += agalExpression("mov", "oc", "xyzw", resultRegister, "xyzw");
			ret += agal("mov", resultRegister, "z", assetsDict[C_ZERO].toString(1), null); //把random的z设为0
			ret += agal("mul", resultRegister, "xy", resultRegister, "xy", assetsDict[C_TWO].toString(3), null);
			ret += agal("sub", resultRegister, "xy", resultRegister, "xy", assetsDict[C_ONE].toString(3), null);
			ret += agal("nrm", resultRegister, "xyz", resultRegister, "xyz");
//			ret += agalExpression("mov", "oc", "xyzw", resultRegister, "xyzw");
			
			return ret;
		}
		
		/**
		 * 镜面反射. R - I = -2 * N * dot(I, N) ==> R = I - 2 * N * dot(I, N)
		 * @param assetsDict 哈希表
		 * @param incidentRegister 入射光, 单位向量
		 * @param normalRegister 法线, 单位向量
		 * @param resultRegister 目标寄存器, 存储结果
		 * @param tmpRegister 临时寄存器
		 * @return 
		 * 
		 */		
		public function reflect(assetsDict:Dictionary, incidentRegister:String, normalRegister:String, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
			ret += agal("dp3", tmpRegister, "w", incidentRegister, "xyz", normalRegister, "xyz");
			ret += agal("mul", tmpRegister, "w", tmpRegister, "w", assetsDict[C_TWO].toString(1), null);
			ret += agal("mul", tmpRegister, "xyz", normalRegister, "xyz", tmpRegister, "www");
			ret += agal("sub", resultRegister, "xyz", incidentRegister, "xyz", tmpRegister, "xyz");
			
			return ret;
		}
		
		/**
		 * P: base point. S: sample point. ao = sat(dot(P.normal, nrm(PS))-bias) * intensity / (1 + |PS| * scale)
		 * @param assetsDict
		 * @param positionRegister
		 * @param newUV
		 * @param normalRegister
		 * @param resultRegister
		 * @param tmpRegister
		 * @return 
		 * 
		 */		
		private function doAmbientOcclusion(assetsDict:Dictionary, positionRegister:String, newUV:String, normalRegister:String, resultRegister:String, tmpRegister:String):String
		{
			var ret:String = "";
			
			ret += getPosition(assetsDict, newUV, "fs0", resultRegister, tmpRegister);
//			ret += agalExpression("sub", resultRegister, "w", resultRegister, "w", positionRegister, "w");
//			ret += agalExpression("mov", "oc", "xyzw", resultRegister, "xyzw");
			ret += agal("sub", resultRegister, "xyz", resultRegister, "xyz", positionRegister, "xyz");
			ret += agal("dp3", resultRegister, "w", resultRegister, "xyz", resultRegister, "xyz");
			ret += agal("sqt", resultRegister, "w", resultRegister, "w"); //resultRegister.w = |PS|
			ret += agal("mul", resultRegister, "w", resultRegister, "w", assetsDict[FLOAT_LINEAR_ATTENUATION].toString(1), null);
			ret += agal("add", resultRegister, "w", resultRegister, "w", assetsDict[C_ONE].toString(1), null); //resultRegister.w = 1 + |PS| * scale
//			ret += agalExpression("mov", "oc", null, resultRegister, null);
			ret += agal("nrm", resultRegister, "xyz", resultRegister, "xyz"); //resultRegister.xyz = nrm(PS)
			
			ret += agal("dp3", resultRegister, "x", resultRegister, "xyz", normalRegister, "xyz");
//			ret += agalExpression("mov", "oc", "xyzw", resultRegister, "xxxx");
			ret += agal("sub", resultRegister, "x", resultRegister, "x", assetsDict[FLOAT_BIAS].toString(1), null);
			ret += agal("sat", resultRegister, "x", resultRegister, "x"); //resultRegister.x = sat(dot(P.normal, nrm(PS))-bias)
			ret += agal("mul", resultRegister, "x", resultRegister, "x", assetsDict[FLOAT_INTENSITY].toString(1), null); //得到sat(dot(P.normal, nrm(PS))-bias) * intensity
			ret += agal("div", resultRegister, "x", resultRegister, "x", resultRegister, "w"); //resultRegister.x = sat(dot(P.normal, nrm(PS))-bias) * intensity / (1 + |PS| * scale)
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			assetsDict[POSITION] = "ft1";
			assetsDict[NORMAL] = "ft2";
			assetsDict[NOISE] = "ft3";
			var i:int;
			
			ret += getPosition(assetsDict, "v0", "fs0", assetsDict[POSITION], "ft7");
			ret += getNormal(assetsDict, "v0", "fs1", assetsDict[NORMAL]);
			ret += getRandom(assetsDict, "v0", "fs2", assetsDict[NOISE], null);
			
			ret += agal("mov", "ft0", "x", assetsDict[C_ZERO].toString(1), null);
//			ret += agalExpression("div", "ft0", "y", assetsDict[SSAO_SAMPLE_RADIUS].toString(1), null, assetsDict[POSITION], "w"); //ft0.y = radius = sampleRadius / position.depth
//			ret += agalExpression("mov", "ft0", "y", assetsDict[FLOAT_SAMPLE_RADIUS].toString(1), null);
			ret += agal("sub", "ft0", "y", assetsDict[C_ZERO].toString(1), null, assetsDict[POSITION], "w");
			ret += agal("mul", "ft0", "y", "ft0", "y", assetsDict[FLOAT_SAMPLE_RADIUS].toString(1), null);
			ret += agal("mul", "ft0", "yz", "ft0", "yy", assetsDict[FLOAT2_TEXEL_SIZE], "xy");
			for(i = 0; i < 4; i ++)
			{
				ret += agal("mov", "ft4", null, assetsDict[KERNAL_AT + String(i)], null);
//				ret += reflect(assetsDict, "ft4", assetsDict[NOISE], "ft4", "ft7");
				ret += agal("mul", "ft4", "xy", "ft4", "xy", "ft0", "yz");
				
				ret += agal("add", "ft5", "xy", "ft4", "xy", "v0", "xy");
				ret += doAmbientOcclusion(assetsDict, assetsDict[POSITION], "ft5", assetsDict[NORMAL], "ft6", "ft7");
				ret += agal("add", "ft0", "x", "ft0", "x", "ft6", "x");
				
				ret += agal("m33", "ft5", "xyz", "ft4", "xyz", assetsDict[M33_ROTATE_45_DEGREE_BY_Z], null);
				ret += agal("add", "ft5", "xy", "ft5", "xy", "v0", "xy");
				ret += doAmbientOcclusion(assetsDict, assetsDict[POSITION], "ft5", assetsDict[NORMAL], "ft6", "ft7");
				ret += agal("add", "ft0", "x", "ft0", "x", "ft6", "x");
			}
			ret += agal("div", "ft0", "x", "ft0", "x", assetsDict[C_EIGHT].toString(1), null);
			ret += agal("sub", "ft0", "x", assetsDict[C_ONE].toString(1), null, "ft0", "x");
			ret += agal("mov", "oc", "xyzw", "ft0", "xxxx");
			
			return ret;
		}
		
		private function generateKernal():Vector.<Vector3D>
		{
			return Vector.<Vector3D>([
				new Vector3D(1, 0, 0), new Vector3D(0, 1, 0), new Vector3D(-1, 0, 0), new Vector3D(0, -1, 0)
			]);
		}
		
		override public function dispose():void
		{
			super.dispose();
			depthTexture = null;
			normalTexture = null;
			if(noiseTexture)
			{
				noiseTexture.dispose();
				noiseTexture = null;
			}
			if(_geometry)
			{
				_geometry.dispose();
				_geometry = null;
			}
		}
		
		/**
		 * rotateFortyFiveDegreeMatrix * (x, y) = (0.707 * x - 0.707 * y, 0.707 * x + 0.707 * y)
		 * @return 
		 * 
		 */		
		public static function rotateFortyFiveDegreeMatrix():Vector.<Number>
		{
			var tmp:Number = Math.SQRT2;
			return Vector.<Number>([
				tmp, -tmp, 0, 0, 
				tmp, tmp, 0, 0, 
				0, 0, 0, 1
			]);
		}
		
		public static const POSITION:String = "Position";
		public static const NORMAL:String = "Normal";
		public static const NOISE:String = "Noise";
		
		/**
		 * 缩放遮挡者和被遮挡者之间的距离, 线性衰减系数
		 */		
		public static const FLOAT_LINEAR_ATTENUATION:String = "FloatLinearAttenuation";
		
		/**
		 * 控制被遮挡者所受的遮挡圆锥宽度
		 */		
		public static const FLOAT_BIAS:String = "FloatBias";
		
		/**
		 * 采样半径
		 */		
		public static const FLOAT_SAMPLE_RADIUS:String = "FloatSampleRadius";
		
		/**
		 * AO强度
		 */		
		public static const FLOAT_INTENSITY:String = "Float_Intensity";
		
		/**
		 * random贴图UV重复的次数
		 */		
		public static const FLOAT_RANDOM_UV_REPEAT:String = "Float_RandomUVRepeat";
		
		/**
		 * sqrt(2) / 2, -sqrt(2) / 2, 0, 0
		 * sqrt(2) / 2, sqrt(2) / 2, 0, 0
		 * 0, 0, 0, 1
		 */		
		public static const M33_ROTATE_45_DEGREE_BY_Z:String = "M33_Rotate45ByZ";
		
		public static const KERNAL_AT:String = "KernalAT";
	}
}