package jehovah3d.core.pick
{
	import flash.geom.Vector3D;
	/**
	 * 矩形面。 
	 * @author lisongsong
	 * 
	 */
	public class RectFace
	{
		public var p0:Vector3D;
		public var p1:Vector3D;
		public var p2:Vector3D;
		private var _p3:Vector3D;
		private var _dir:Vector3D;
		
		/**
		 * ABC，p0-B, p1-A, p2-C。注意顺序。 
		 * @param p0
		 * @param p1
		 * @param p2
		 * 
		 */		
		public function RectFace(p0:Vector3D, p1:Vector3D, p2:Vector3D) //I feel bad right now.
		{
			this.p0 = p0;
			this.p1 = p1;
			this.p2 = p2;
		}
		
		public function get p3():Vector3D
		{
			if(!_p3)
				_p3 = p2.add(p1.subtract(p0));
			return _p3;
		}
		
		public function get dir():Vector3D
		{
			if(!_dir)
				_dir = p1.subtract(p0).crossProduct(p2.subtract(p0));
			return _dir;
		}
		
		public function toPlane():Plane
		{
			return new Plane(p0, dir);
		}
		
		public function hasIntersectionWithRectFace(rf:RectFace):Boolean
		{
			var dir:Vector3D;
			var t:Number;
			
			dir = rf.p1.subtract(rf.p0);
			t = dir.length;
			dir.normalize();
			if(hasIntersectionWithRay(new Ray(rf.p0, dir), t))
				return true;
			if(hasIntersectionWithRay(new Ray(rf.p2, dir), t))
				return true;
			
			dir = rf.p2.subtract(rf.p0);
			t = dir.length;
			dir.normalize();
			if(hasIntersectionWithRay(new Ray(rf.p0, dir), t))
				return true;
			if(hasIntersectionWithRay(new Ray(rf.p1, dir), t))
				return true;
			
			dir = this.p1.subtract(this.p0);
			t = dir.length;
			dir.normalize();
			if(rf.hasIntersectionWithRay(new Ray(this.p0, dir), t))
				return true;
			if(rf.hasIntersectionWithRay(new Ray(this.p2, dir), t))
				return true;
			
			dir = this.p2.subtract(this.p0);
			t = dir.length;
			dir.normalize();
			if(rf.hasIntersectionWithRay(new Ray(this.p0, dir), t))
				return true;
			if(rf.hasIntersectionWithRay(new Ray(this.p1, dir), t))
				return true;
			
			return false;
		}
		
		public function hasIntersectionWithRay(ray:Ray, rayLength:Number):Boolean
		{
			var v0:Vector3D = MousePickManager.rayRectFaceIntersect(ray, this, false, false);
			if(!v0)
				return false;
			return v0.subtract(ray.p0).length <= rayLength;
		}
	}
}