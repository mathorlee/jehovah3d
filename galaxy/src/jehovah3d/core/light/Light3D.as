package jehovah3d.core.light
{
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.wireframe.WireFrame;
	import jehovah3d.util.HexColor;
	
	import utils.UIDUtil;

	public class Light3D extends Object3D
	{
		private var _useShadow:Boolean = false;
		private var _color:HexColor;
		private var _intensity:Number = 1.0;
		private var _shadowmappingsize:int = 1024;
		protected var _zNear:Number;
		protected var _zFar:Number;
		
		protected var _lightHead:WireFrame; //灯光的显示 头
		protected var _lightBody:WireFrame; //灯光的显示 边界
		
		public var depthTexture:Texture;
		public var diffuseAndSpecularTexture:Texture;
		public var projectionMatrix:Matrix3D;
		
		public function Light3D(color:uint, zNear:Number, zFar:Number)
		{
			name = UIDUtil.createUID();
			_color = new HexColor(color, 1);
			_zNear = zNear;
			_zFar = zFar;
		}
		
		public function get direction():Vector3D
		{
			if(Jehovah.useDefaultLight)
				return inverseMatrix.deltaTransformVector(new Vector3D(0, 0, 1));
			return localToGlobalMatrix.deltaTransformVector(new Vector3D(0, 0, 1));
		}
		
		override public function get globalPosition():Vector3D
		{
			var v0:Vector3D = Jehovah.useDefaultLight ? position : super.globalPosition;
			return v0;
		}
		
		public function get color():HexColor
		{
			return _color;
		}
		public function set color(value:HexColor):void
		{
			_color = value;
		}
		public function get intensity():Number
		{
			return _intensity;
		}
		public function set intensity(value:Number):void
		{
			if(_intensity != value)
				_intensity = value;
		}
		
		public function get useShadow():Boolean
		{
			return _useShadow;
		}
		public function set useShadow(value:Boolean):void
		{
			if(_useShadow != value)
			{
				_useShadow = value;
				
			}
		}
		public function get shadowmappingsize():int
		{
			return _shadowmappingsize;
		}
		public function set shadowmappingsize(value:int):void
		{
			if(_shadowmappingsize != value)
			{
				_shadowmappingsize = value;
				if(depthTexture)
				{
					depthTexture.dispose();
					depthTexture = null;
				}
			}
		}
		public function get zNear():Number
		{
			return _zNear;
		}
		public function set zNear(value:Number):void
		{
			if(_zNear != value)
				_zNear = value;
		}
		public function get zFar():Number
		{
			return _zFar;
		}
		public function set zFar(value:Number):void
		{
			if(_zFar != value)
				_zFar = value;
		}
		
		public function calculateProjectionMatrix():void
		{
			
		}
		public function get globalToCVVMatrix():Matrix3D
		{
			var ret:Matrix3D = inverseMatrix.clone();
			ret.append(projectionMatrix);
			return ret;
		}
		
		override public function collectRenderList(opaqueRenderList:Vector.<Object3D>, transparentRenderList:Vector.<Object3D>):void
		{
			super.collectRenderList(opaqueRenderList, transparentRenderList);
		}
		override public function dispose():void
		{
			super.dispose();
			if(_color)
				_color = null;
			if(depthTexture)
			{
				depthTexture.dispose();
				depthTexture = null;
			}
			if(diffuseAndSpecularTexture)
			{
				diffuseAndSpecularTexture.dispose();
				diffuseAndSpecularTexture = null;
			}
			if(projectionMatrix)
				projectionMatrix = null;
		}
	}
}