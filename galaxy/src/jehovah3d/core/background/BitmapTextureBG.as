package jehovah3d.core.background
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Context3DProperty;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.resource.GeometryResource;
	import jehovah3d.core.resource.ShaderResource;
	import jehovah3d.core.resource.TextureResource;

	public class BitmapTextureBG extends Object3D
	{
		private var _geometry:GeometryResource;
		private var _shader:ShaderResource;
		
		private var _tr:TextureResource;
		
		public function BitmapTextureBG(bitmapData:BitmapData)
		{
			_tr = new TextureResource(bitmapData);
			mouseEnabled = false;
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
			_geometry.diffuseUVData = Vector.<Number>([
				1, 0, 0, 0, 0, 1, 1, 1
			]);
			_geometry.indexData = Vector.<uint>([
				0, 1, 2, 0, 2, 3
			]);
		}
		
		public function updateBackgoundImage(bitmapData:BitmapData):void
		{
			_tr.dispose();
			_tr = new TextureResource(bitmapData);
		}
		
		/**
		 * re-upload BG's resource to GPU. 
		 * @param context3D
		 * 
		 */		
		override public function uploadResource(context3D:Context3D):void
		{
			_geometry.upload(context3D);
			if(_tr)
				_tr.upload(context3D);
			if(_shader)
				_shader.upload(context3D);
			super.uploadResource(context3D);
		}
		
		public function render(context3D:Context3D, context3DProperty:Context3DProperty):void
		{
			if(!_geometry.isUploaded)
				_geometry.upload(context3D);
			if(!_tr.isUploaded)
				_tr.upload(context3D);
			collectResource();
			if(!_shader)
				return ;
			if(!_shader.isUploaded)
				_shader.upload(context3D);
			if(Jehovah.renderMode != Jehovah.RENDER_ALL && Jehovah.renderMode != Jehovah.RENDER_AMBIENTANDREFLECTION)
				return ;
			
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
			
			context3DProperty.dispose(context3D);
			
			context3D.setProgram(_shader.program3D);
			context3D.setVertexBufferAt(0, _geometry.coordinateBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
			context3D.setVertexBufferAt(1, _geometry.diffuseUVBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context3D.setTextureAt(0, _tr.texture);
			newUsedBuffer = 3; //(1 << 0) | (1 << 1)
			newUsedTexture = 1; //(1 << 0)
			context3D.drawTriangles(_geometry.indexBuffer, 0, _geometry.numTriangle);
			
			context3DProperty.usedBuffer = newUsedBuffer;
			context3DProperty.usedTexture = newUsedTexture;
		}
		
		override public function collectRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			if(!visible)
				return ;
			opaqueRenderList.push(this);
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
				"tex ft0, v0, fs0<2d,repeat,miplinea,linear>\n" + 
				"mov oc, ft0\n";
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
			if(_tr)
			{
				_tr.dispose();
				_tr = null;
			}
		}
	}
}