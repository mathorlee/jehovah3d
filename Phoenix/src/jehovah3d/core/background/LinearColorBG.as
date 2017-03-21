package jehovah3d.core.background
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.priority.RenderPriority;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.ShaderResource;
	import jehovah3d.util.HexColor;

	public class LinearColorBG extends Object3D
	{
		private var _geometry:GeometryResource;
		private var _shader:ShaderResource;
		
		private var _topColor:HexColor;
		private var _bottomColor:HexColor;
		
		public function LinearColorBG(topColor:uint, bottomColor:uint)
		{
			this.renderPriority = RenderPriority.BG;
			_topColor = new HexColor(topColor, 1);
			_bottomColor = new HexColor(bottomColor);
			initGeometry();
		}
		
		private function initGeometry():void
		{
			_geometry = new GeometryResource();
			_geometry.coordinateData = Vector.<Number>([
				1, 1, 1 - 0.00001, 
				-1, 1, 1 - 0.00001, 
				-1, -1, 1 - 0.00001, 
				1, -1, 1 - 0.00001
			]);
			_geometry.vertexColorData = Vector.<Number>([
				_topColor.fractionalRed, _topColor.fractionalGreen, _topColor.fractionalBlue, 
				_topColor.fractionalRed, _topColor.fractionalGreen, _topColor.fractionalBlue, 
				_bottomColor.fractionalRed, _bottomColor.fractionalGreen, _bottomColor.fractionalBlue, 
				_bottomColor.fractionalRed, _bottomColor.fractionalGreen, _bottomColor.fractionalBlue
			]);
			_geometry.indexData = Vector.<uint>([
				0, 1, 2, 0, 2, 3
			]);
		}
		
		override public function uploadResource(context3D:Context3D):void
		{
			_geometry.upload(context3D);
			if(_shader)
			{
				_shader.dispose();
				_shader = null;
			}
			super.uploadResource(context3D);
		}
		
		public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			if(!_geometry.isUploaded)
				_geometry.upload(context3D);
			
			collectResource();
			if(!_shader)
				return ;
			if(!_shader.isUploaded)
				_shader.upload(context3D);
			
			var index:uint;
			var newUsedBuffer:uint;
			var newUsedTexture:uint;
			
			if(Context3DBlendFactor.ONE != context3DProperty.sourceFactor || Context3DBlendFactor.ZERO != context3DProperty.destinationFactor)
			{
				context3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				context3DProperty.sourceFactor = Context3DBlendFactor.ONE;
				context3DProperty.destinationFactor = Context3DBlendFactor.ZERO;
			}
			if(context3DProperty.culling != Context3DTriangleFace.FRONT)
			{
				context3D.setCulling(Context3DTriangleFace.FRONT);
				context3DProperty.culling = Context3DTriangleFace.FRONT;
			}
			context3D.setProgram(_shader.program3D);
			context3D.setVertexBufferAt(0, _geometry.coordinateBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1, _geometry.vertexColorBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			newUsedBuffer = 3; //(1 << 0) | (1 << 1)
			newUsedTexture = 0;
			var bufferDiffer:uint = context3DProperty.usedBuffer & ~newUsedBuffer;
			var textureDiffer:uint = context3DProperty.usedTexture & ~newUsedTexture;
			for(index = 0; bufferDiffer > 0; index ++)
			{
				if(bufferDiffer & 1)
					context3D.setVertexBufferAt(index, null);
				bufferDiffer >>= 1;
			}
			for(index = 0; textureDiffer > 0; index ++)
			{
				if(textureDiffer & 1)
					context3D.setTextureAt(index, null);
				textureDiffer >>= 1;
			}
			context3DProperty.usedBuffer = newUsedBuffer;
			context3DProperty.usedTexture = newUsedTexture;
			context3D.drawTriangles(_geometry.indexBuffer, 0, _geometry.numTriangle);
		}
		
		private function collectResource():void
		{
			if(_shader)
				return ;
			_shader = new ShaderResource();
			var vertexAGAL:String = 
				"mov op, va0\n" + 
				"mov v0, va1\n";
			var fragmentAGAL:String = 
				"mov oc, v0\n";
			_shader.vertexShaderString = vertexAGAL;
			_shader.fragmentShaderString = fragmentAGAL;
		}
		
		override public function dispose():void
		{
			super.dispose();
			if(_geometry)
			{
				_geometry.dispose();
				_geometry = null;
			}
			if(_shader)
			{
				_shader.dispose();
				_shader = null;
			}
			if(_topColor)
				_topColor = null;
			if(_bottomColor)
				_bottomColor = null;
		}
	}
}