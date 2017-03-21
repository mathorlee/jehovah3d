package jehovah3d.core.renderer
{
	import com.fuwo.math.MyMath;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.textures.TextureBase;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.ShaderResource;
	
	public class AddMultiTextureRenderer extends Renderer
	{
		public static const NAME:String = "AddMultiTextureRenderer";
		
		private var _geometry:GeometryResource;
		public var ambientAndReflectionTexture:TextureBase;
		private var _aoTexture:TextureBase;
		private var _diffuseAndSpecularTextures:Vector.<TextureBase> = new Vector.<TextureBase>();
		
		public function AddMultiTextureRenderer(mesh:Mesh)
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
		
		public function set aoTexture(value:TextureBase):void
		{
			if(_aoTexture != value)
			{
				if(_shader)
				{
					_shader.dispose();
					_shader = null;
				}
				_aoTexture = value;
			}
		}
		public function set diffuseAndSpecularTextures(value:Vector.<TextureBase>):void
		{
			if(_diffuseAndSpecularTextures.length != value.length)
			{
				if(_shader)
				{
					_shader.dispose();
					_shader = null;
				}
			}
			_diffuseAndSpecularTextures = value.slice();
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
			var i:int;
			
			assetsDict[C_ONE] = currentVC();
			vertexConstants.push(1, 1, 1, 1);
			assetsDict[C_CVVUV_TO_SCREENUV_MATRIX] = currentFC();
			MyMath.mergeTwoNumberVector(fragmentConstants, Renderer.CVVUVToScreenUVMatrix(), true);
			
			//push coordinate buffer
			vertexBuffers.push(_geometry.coordinateBuffer);
			vertexBufferIndices.push(0);
			vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
			assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
			assetsDict[VA_COORDINATE] = "va0";
			
			assetsDict[FS_AMBIENT_AND_REFLECTION] = "fs0";
			textures.push(ambientAndReflectionTexture);
			textureSamplers.push(0);
			if(_aoTexture)
			{
				assetsDict[FS_AO] = "fs1";
				textures.push(_aoTexture);
				textureSamplers.push(1);
			}
			for(i = 0; i < _diffuseAndSpecularTextures.length; i ++)
			{
				assetsDict[FS_DIFFUSE_AND_SPECULAR_AT + String(i)] = "fs" + String(i + 2);
				textures.push(_diffuseAndSpecularTextures[i]);
				textureSamplers.push(i + 2);
			}
			assetsDict[CPU_DS_COUNT] = _diffuseAndSpecularTextures.length;
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(assetsDict);
				_shader.fragmentShaderString = generateFragmentShader(assetsDict);
//				trace(_shader.vertexShaderString);
//				trace(_shader.fragmentShaderString);
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
			ret += agal("mov", "v0", null, "va0", null);
			ret += agal("mov", "v0", "z", assetsDict[C_ONE], "x");
			
			return ret;
		}
		
		override public function generateFragmentShader(assetsDict:Dictionary):String
		{
			var ret:String = "";
			var SCREEN_UV:String = "ScreenUV";
			assetsDict[SCREEN_UV] = "ft0";
			
			ret += agal("m33", assetsDict[SCREEN_UV], "xyz", "v0", "xyz", assetsDict[C_CVVUV_TO_SCREENUV_MATRIX], null);
			ret += agal("tex", "ft1", null, assetsDict[SCREEN_UV], "xy", assetsDict[FS_AMBIENT_AND_REFLECTION] + "<2d,miplinear,linear,repeat>", null);
			if(assetsDict[FS_AO])
			{
				ret += agal("tex", "ft2", null, assetsDict[SCREEN_UV], "xy", assetsDict[FS_AO] + "<2d,miplinear,linear,repeat>", null);
				ret += agal("mul", "ft1", "xyz", "ft1", "xyz", "ft2", "xyz");
			}
			var i:int;
			for(i = 0; i < assetsDict[CPU_DS_COUNT]; i ++)
			{
				ret += agal("tex", "ft2", null, assetsDict[SCREEN_UV], "xy", assetsDict[FS_DIFFUSE_AND_SPECULAR_AT + String(i)] + "<2d,miplinear,linear,repeat>", null);
				ret += agal("add", "ft1", "xyz", "ft1", "xyz", "ft2", "xyz");
			}
			ret += agal("mov", "oc", null, "ft1", null);
			
			return ret;
		}
		
		override public function dispose():void
		{
			super.dispose();
			if(_geometry)
			{
				_geometry.dispose();
				_geometry = null;
			}
			ambientAndReflectionTexture = null;
			if(_diffuseAndSpecularTextures)
			{
				_diffuseAndSpecularTextures.length = 0;
				_diffuseAndSpecularTextures = null;
			}
		}
		
		public static const FS_AO:String = "FSAO";
		public static const FS_AMBIENT_AND_REFLECTION:String = "FSAmbientAndReflection";
		public static const FS_DIFFUSE_AND_SPECULAR_AT:String = "FSDiffuseAndSpecularAt";
		public static const CPU_DS_COUNT:String = "CPUDSCount";
	}
}