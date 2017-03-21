package jehovah3d.core.pick
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.controller.SelectMove;
	import jehovah3d.core.Object3D;

	/**
	 * RayIntersectionManager.
	 * @author fuwo
	 * 
	 */	
	public class MousePickManager
	{
		private static var _target:MousePickData;
		private static var _detectTarget:MousePickData;
		private static var _rids:Vector.<MousePickData> = new Vector.<MousePickData>();
		
		/**
		 * add. 
		 * @param rid
		 * 
		 */		
		public static function add(rid:MousePickData):void
		{
			_rids.push(rid);
		}
		
		/**
		 * sort. 
		 * 
		 */		
		public static function sort():void
		{
			if(_rids.length == 0)
				return ;
			function cmp(t1:MousePickData, t2:MousePickData):Number
			{
				if(t1.object is SelectMove && !(t2.object is SelectMove))
					return -1;
				if(!(t1.object is SelectMove) && t2.object is SelectMove)
					return 1;
				if(t1.dist < t2.dist)
					return -1;
				if(t1.dist > t2.dist)
					return 1;
				return 0;
			}
			_rids.sort(cmp);
			_target = _rids[0];
			
//			trace("after sort:");
//			var i:int;
//			for(i = 0; i < _rids.length; i ++)
//				trace(_rids[i].object, _rids[i].dist);
		}
		
		public static function sortBy(compareFunction:Function, setSortResultTo:String = "target"):void
		{
			if(_rids.length == 0)
				return ;
			
//			var i:int;
//			trace("before sort:");
//			for(i = 0; i < _rids.length; i ++)
//				trace(_rids[i].isPenetrable, _rids[i].object, _rids[i].dist);
			
			_rids = _rids.sort(compareFunction);
			
//			trace("after sort:");
//			for(i = 0; i < _rids.length; i ++)
//				trace(_rids[i].isPenetrable, _rids[i].object, _rids[i].dist);
			if(setSortResultTo == "target")
				_target = _rids[0];
			else if(setSortResultTo == "detectTarget")
				_detectTarget = _rids[0];
		}
		
		/**
		 * clear. 
		 * 
		 */		
		public static function clear():void
		{
			var i:int;
			for(i = 0; i < _rids.length; i ++)
				_rids[i].clear();
			_rids.length = 0;
			if(_target)
				_target = null;
			if(_detectTarget)
				_detectTarget = null;
		}
		
		public static function clearBy(clearFunction:Function):void
		{
			clearFunction.call(null, _target);
			clear();
		}
		
		public static function clearDetectTarget():void
		{
			_rids.length = 0;
			if(_detectTarget)
				_detectTarget = null;
		}
		
		/**
		 * target. 
		 * @return 
		 * 
		 */		
		public static function get target():MousePickData
		{
			return _target;
		}
		
		public static function get detectTarget():MousePickData
		{
			return _detectTarget;
		}
		public static function get object():Object3D
		{
			return _target ? _target.object : null;
		}
		
		public static function linePlaneIntersect(line:Line, plane:Plane):Object
		{
			/*
			dot(line.p0 + line.dir * t - plane.p0, plane.dir) = 0
			dot(line.p0 - plane.p0, plane.dir) + dot(line.dir, plane.dir) * t = 0
			t = -dot(line.p0 - plane.p0, plane.dir) / dot(line.dir, plane.dir)
			if(dot(line.dir, plane.dir) === 0) no intersection.
			*/
			var d0:Number = line.dir.dotProduct(plane.dir);
			if(MyMath.isNumberEqual(d0, 0))
				return null;
			var t:Number = -line.p0.subtract(plane.p0).dotProduct(plane.dir) / d0;
			return {"point": new Vector3D(line.p0.x + line.dir.x * t, line.p0.y + line.dir.y * t, line.p0.z + line.dir.z * t), "t": t};
		}
		/**
		 * ray plane intersection.
		 * + 
		 * @param ray
		 * @param plane
		 * @return 
		 * 
		 */		
		public static function rayPlaneIntersect(ray:Ray, plane:Plane):Object
		{
			var ret:Object = new Object();
			/*
			plane: (x - plane.p0) * plane.dir = 0;
			ray:  ray.p0 + ray.dir * t;
			
			(ray.p0 - plane.p0 + ray.dir * t) * plane.dir = 0;
			t * (ray.dir * plane.dir) = (plane.p0 - ray.p0) * plane.dir
			*/
			var b0:Number = plane.whichSideIsPointAt(ray.p0);
			var b1:Number = plane.whichSideIsVectorAt(ray.dir);
			if(b0 * b1 > 0) //判断ray和plane没有交点，return null。
				return null;
			var t:Number = plane.p0.subtract(ray.p0).dotProduct(plane.dir) / ray.dir.dotProduct(plane.dir);
			ret.t = t;
			ret.point = ray.p0.add(new Vector3D(ray.dir.x * t, ray.dir.y * t, ray.dir.z * t));
			return ret;
		}
		/**
		 * 返回point到plane的距离。正值。 
		 * @param point
		 * @param plane
		 * @return 
		 * 
		 */		
		public static function pointPlaneDistance(point:Vector3D, plane:Plane):Number
		{
			var v0:Vector3D = point.subtract(plane.p0);
			return Math.abs(v0.dotProduct(plane.dir));
		}
		
		/**
		 * ray plane intersect. 
		 * @param ray
		 * @param plane
		 * @param detectTriangle
		 * @return 
		 * 
		 */		
		public static function rayRectFaceIntersect(ray:Ray, face:RectFace, detectTriangle:Boolean = false, allowRayDirectionNegate:Boolean = false):Vector3D
		{
			var rawData:Vector.<Number> = new Vector.<Number>(16);
			rawData[0] = ray.p0.x - ray.p1.x;
			rawData[1] = ray.p0.y - ray.p1.y;
			rawData[2] = ray.p0.z - ray.p1.z;
			
			rawData[4] = face.p1.x - face.p0.x;
			rawData[5] = face.p1.y - face.p0.y;
			rawData[6] = face.p1.z - face.p0.z;
			
			rawData[8] = face.p2.x - face.p0.x;
			rawData[9] = face.p2.y - face.p0.y;
			rawData[10] = face.p2.z - face.p0.z;
			rawData[15] = 1;
			
			var matrix:Matrix3D = new Matrix3D(rawData);
			
			var t:Number;
			var u:Number
			var v:Number;
			var v0:Vector3D = new Vector3D(ray.p0.x - face.p0.x, ray.p0.y - face.p0.y, ray.p0.z - face.p0.z);
			var v1:Vector3D;
			
			if(matrix.invert())
			{
				v1 = matrix.transformVector(v0);
				t = v1.x;
				u = v1.y;
				v = v1.z;
				
				if(detectTriangle)
				{
					if(
						(u > 0 || MyMath.isNumberEqual(u, 0)) && 
						(v > 0 || MyMath.isNumberEqual(v, 0)) && 
						(u + v < 1 || MyMath.isNumberEqual(u + v, 1)))
					{
						if(t > 0 || (t < 0 && allowRayDirectionNegate))
							return new Vector3D(ray.p0.x + ray.dir.x * t, ray.p0.y + ray.dir.y * t, ray.p0.z + ray.dir.z * t);
					}
				}
				else
				{
					if(
						(u > 0 || MyMath.isNumberEqual(u, 0)) && 
						(u < 1 || MyMath.isNumberEqual(u, 1)) && 
						(v > 0 || MyMath.isNumberEqual(v, 0)) && 
						(v < 1 || MyMath.isNumberEqual(v, 1)))
					{
						if(t > 0 || (t < 0 && allowRayDirectionNegate))
							return new Vector3D(ray.p0.x + ray.dir.x * t, ray.p0.y + ray.dir.y * t, ray.p0.z + ray.dir.z * t);
					}
				}
			}
			else //empty set
			{
				
			}
			return null;
		}
		
	}
}