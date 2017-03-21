package panorama
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class Object3D
	{
		public function Object3D()
		{
			
		}
		
		public function updateMatrix():void
		{
			if(_transformChanged)
				composeTransforms();
		}
		public function composeTransforms():void
		{
			_matrix.identity();
			_matrix.appendRotation(rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			_matrix.appendRotation(rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			_matrix.appendRotation(rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			_matrix.appendTranslation(x, y, z);
			
			_inverseMatrix.identity();
			_inverseMatrix.appendTranslation(-x, -y, -z);
			_inverseMatrix.appendRotation(-rotationX * 180 / Math.PI, Vector3D.X_AXIS);
			_inverseMatrix.appendRotation(-rotationY * 180 / Math.PI, Vector3D.Y_AXIS);
			_inverseMatrix.appendRotation(-rotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
		}
		
		public function dispose():void
		{
			if(_matrix)
				_matrix = null;
			if(_inverseMatrix)
				_inverseMatrix = null;
		}
		
		private var _matrix:Matrix3D = new Matrix3D();;
		public function get matrix():Matrix3D { return _matrix; }
		private var _inverseMatrix:Matrix3D = new Matrix3D();
		public function get inverseMatrix():Matrix3D { return _inverseMatrix; }
		
		private var _transformChanged:Boolean = true;
		public function get transformChanged():Boolean { return _transformChanged; }
		
		private var _x:Number = 0;
		public function get x():Number { return _x; }
		
		public function set x(value:Number):void
		{
			if (_x == value)
				return;
			_x = value;
			_transformChanged = true;
		}
		
		private var _y:Number = 0;
		public function get y():Number { return _y; }
		
		public function set y(value:Number):void
		{
			if (_y == value)
				return;
			_y = value;
			_transformChanged = true;
		}
		
		private var _z:Number = 0;
		public function get z():Number { return _z; }
		
		public function set z(value:Number):void
		{
			if (_z == value)
				return;
			_z = value;
			_transformChanged = true;
		}
		
		private var _rotationX:Number = 0;
		public function get rotationX():Number { return _rotationX; }
		
		public function set rotationX(value:Number):void
		{
			if (_rotationX == value)
				return;
			_rotationX = value;
			if(_rotationX > Math.PI)
				_rotationX -= Math.PI * 2;
			if(_rotationX <= -Math.PI)
				_rotationX += Math.PI * 2;
			_transformChanged = true;
		}
		
		private var _rotationY:Number = 0;
		public function get rotationY():Number { return _rotationY; }
		
		public function set rotationY(value:Number):void
		{
			if (_rotationY == value)
				return;
			_rotationY = value;
			if(_rotationY > Math.PI)
				_rotationY -= Math.PI * 2;
			if(_rotationY <= -Math.PI)
				_rotationY += Math.PI * 2;
			_transformChanged = true;
		}
		
		private var _rotationZ:Number = 0;
		public function get rotationZ():Number { return _rotationZ; }
		
		public function set rotationZ(value:Number):void
		{
			if (_rotationZ == value)
				return;
			_rotationZ = value;
			if(_rotationZ > Math.PI)
				_rotationZ -= Math.PI * 2;
			if(_rotationZ <= -Math.PI)
				_rotationZ += Math.PI * 2;
			_transformChanged = true;
		}
	}
}