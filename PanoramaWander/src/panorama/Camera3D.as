package panorama
{
	import flash.geom.Vector3D;
	
	import panorama.culling.Frustum;
	import panorama.culling.Plane;

	public class Camera3D extends Object3D
	{
		public function Camera3D(fov:Number, viewWidth:Number, viewHeight:Number)
		{
			_fov = fov;
			_viewWidth = viewWidth;
			_viewHeight = viewHeight;
		}
		
		public function calculateFocalLength():void
		{
			_focalLength = _viewWidth * 0.5 / Math.tan(fov * 0.5);
		}
		
		public function updatePM():void
		{
			if(!_projectionMatrixChanged)
				return ;
			_focalLength = _viewWidth * 0.5 / Math.tan(fov * 0.5);
			
			frustum = new Frustum();
			frustum.left = new Plane(new Vector3D(0, 0, 0), new Vector3D(Math.cos(fov * 0.5), 0, Math.sin(fov * 0.5)));
			frustum.right = new Plane(new Vector3D(0, 0, 0), new Vector3D(-Math.cos(fov * 0.5), 0, Math.sin(fov * 0.5)));
			var cos:Number = focalLength / Math.sqrt(focalLength * focalLength + viewHeight * viewHeight * 0.25);
			var sin:Number = viewHeight * 0.5 / Math.sqrt(focalLength * focalLength + viewHeight * viewHeight * 0.25);
			frustum.top = new Plane(new Vector3D(0, 0, 0), new Vector3D(0, cos, sin));
			frustum.bottom = new Plane(new Vector3D(0, 0, 0), new Vector3D(0, -cos, sin));
			frustum.front = new Plane(new Vector3D(0, 0, 10), new Vector3D(0, 0, 1));
			frustum.back = new Plane(new Vector3D(0, 0, 1000), new Vector3D(0, 0, -1));
		}
		
		override public function dispose():void
		{
			super.dispose();
		}
		
		private var _projectionMatrixChanged:Boolean = true;
		public function get projectionMatrixChanged():Boolean { return _projectionMatrixChanged; }
		
		private var _focalLength:Number;
		public function get focalLength():Number { return _focalLength; }
		
		private var _fov:Number;
		public function get fov():Number { return _fov; }
		
		public function set fov(value:Number):void
		{
			if (_fov == value)
				return;
			_fov = value;
			_projectionMatrixChanged = true;
		}
		
		private var _viewWidth:Number;
		public function get viewWidth():Number { return _viewWidth; }
		
		public function set viewWidth(value:Number):void
		{
			if (_viewWidth == value)
				return;
			_viewWidth = value;
			_projectionMatrixChanged = true;
		}
		
		private var _viewHeight:Number;
		public function get viewHeight():Number { return _viewHeight; }
		
		public function set viewHeight(value:Number):void
		{
			if (_viewHeight == value)
				return;
			_viewHeight = value;
			_projectionMatrixChanged = true;
		}
		
		private var _frustum:Frustum;
		public function get frustum():Frustum { return _frustum; }
		
		public function set frustum(value:Frustum):void
		{
			if (_frustum == value)
				return;
			_frustum = value;
		}
		
	}
}