package jehovah3d.core.pick
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	public class Plane
	{
		private var _p0:Vector3D;
		private var _dir:Vector3D;
		
		public function Plane(p0:Vector3D, dir:Vector3D)
		{
			_p0 = p0;
			_dir = dir;
		}
		
		public function whichSideIsPointAt(point:Vector3D):Number
		{
			var v1:Vector3D = point.subtract(_p0);
			v1.normalize();
			var dot:Number = v1.dotProduct(_dir);
			if(MyMath.isNumberEqual(dot, 0))
				return 0;
			else if(dot > 0)
				return 1;
			return -1;
		}
		
		/**
		 * 判断单位向量在plane的哪一侧。不是单位向量也没关系。 
		 * @param vector
		 * @return 
		 * 
		 */		
		public function whichSideIsVectorAt(vector:Vector3D):Number
		{
			var dot:Number = vector.dotProduct(_dir);
			if(MyMath.isNumberEqual(dot, 0))
				return 0;
			else if(dot > 0)
				return 1;
			return -1;
		}
		
		public function get p0():Vector3D
		{
			return _p0;
		}
		public function get dir():Vector3D
		{
			return _dir;
		}
		
		/**
		 * 返回plane在新的坐标系下的表示。 
		 * @param matrix
		 * @return 
		 * 
		 */		
		public function transform(matrix:Matrix3D):Plane
		{
			return new Plane(matrix.transformVector(_p0), matrix.deltaTransformVector(_dir));
		}
		
		public static function calculateIntersectionLineOfTwoPlane(plane0:Plane, plane1:Plane):Line
		{
			if(MyMath.isNumberEqual(plane0.dir.dotProduct(plane1.dir), 0))
				return null;
			
			//计算平面上任意一点 dot(X, v0) = c0, x * v0.x + y * v0.y + z * v0.z = c0
			var v0:Vector3D = plane0.dir.add(plane1.dir);
			var c0:Number = plane0.dir.dotProduct(plane0.p0) + plane1.dir.dotProduct(plane1.p0);
			
			var abitraryPointOnLine:Vector3D;
			var bx:Boolean = MyMath.isNumberEqual(v0.x, 0);
			var by:Boolean = MyMath.isNumberEqual(v0.y, 0);
			var bz:Boolean = MyMath.isNumberEqual(v0.z, 0);
			
			if(bx)
			{
				if(by)
				{
					if(bz) //000
						return null;
					else //001
						abitraryPointOnLine = new Vector3D(0, 0, c0 / v0.z);
				}
				else
				{
					if(bz) //010
						abitraryPointOnLine = new Vector3D(0, c0 / v0.y, 0);
					else //011
						abitraryPointOnLine = new Vector3D(0, 1, (c0 - v0.y) / v0.z);
				}
			}
			else
			{
				if(by)
				{
					if(bz) //100
						abitraryPointOnLine = new Vector3D(c0 / v0.x, 0, 0);
					else //101
						abitraryPointOnLine = new Vector3D(1, 0, (c0 - v0.x) / v0.z);
				}
				else
				{
					if(bz) //110
						abitraryPointOnLine = new Vector3D(1, (c0 - v0.x) / v0.y, 0);
					else //111
						abitraryPointOnLine = new Vector3D(1, 1, (c0 - v0.x - v0.y) / v0.z);
				}
			}
			if(!abitraryPointOnLine)
				return null;
			return new Line(abitraryPointOnLine, plane0.dir.crossProduct(plane1.dir));
		}
	}
}