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
	}
}