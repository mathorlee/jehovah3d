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
	
	public class DisplayTextureRenderer extends Renderer
	{
		public static const NAME:String = "DisplayTextureRenderer";
		
		private var _geometry:GeometryResource;
		private var _texture:TextureBase;
		public function DisplayTextureRenderer(mesh:Mesh)
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
		
		public function set texture(value:TextureBase):void
		{
			_texture = value;
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
			assetsDict[C_ONE] = currentVC();
			vertexConstants.push(1, 1, 1, 1);
			assetsDict[C_CVVUV_TO_SCREENUV_MATRIX] = currentFC();
			MyMath.mergeTwoArray(fragmentConstants, Renderer.CVVUVToScreenUVMatrix(), true);
			assetsDict["TextureCount"] = Jehovah.lights.length + 1;
			
			//push coordinate buffer
			vertexBuffers.push(_geometry.coordinateBuffer);
			vertexBufferIndices.push(0);
			vertexBufferFormats.push(Context3DVertexBufferFormat.FLOAT_3);
			assetsDict[V_COORDINATE] = "v0"; //va0/v0: coordinate buffer.
			assetsDict[VA_COORDINATE] = "va0";
			
			textures.push(_texture);
			textureSamplers.push(0);
			
			if(!_shader)
			{
				_shader = new ShaderResource();
				_shader.vertexShaderString = generateVertexShader(assetsDict);
				_shader.fragmentShaderString = generateFragmentShader(assetsDict);
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
			
			ret += agal("m33", "ft0", "xyz", "v0", "xyz", assetsDict[C_CVVUV_TO_SCREENUV_MATRIX], null);
			ret += agal("tex", "oc", null, "ft0", "xy", "fs0" + "<2d,miplinear,linear,repeat>", null);
			
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
			_texture = null;
		}
	}
}