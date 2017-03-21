package jehovah3d.core.pick
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import jehovah3d.controller.SelectMove;

	/**
	 * RayIntersectionManager.
	 * @author fuwo
	 * 
	 */	
	public class MousePickManager
	{
		private static var _target:MousePickData;
		private static var _mousePickDatas:Vector.<MousePickData> = new Vector.<MousePickData>();
		
		/**
		 * add. 
		 * @param rid
		 * 
		 */		
		public static function add(mpd:MousePickData):void
		{
			_mousePickDatas.push(mpd);
		}
		
		/**
		 * sort. 
		 * 
		 */		
		public static function sort(compareFunction:Function = null):void
		{
			if(_mousePickDatas.length == 0)
				return ;
			
			_mousePickDatas.sort(compareFunction != null ? compareFunction : defaultCompareFunc);
			_target = _mousePickDatas[0];
		}
		
		private static function defaultCompareFunc(t1:MousePickData, t2:MousePickData):int
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
		
		public static function outputMousePickDatas():void
		{
			for each (var data:MousePickData in _mousePickDatas)
			{
				trace(data.isPenetrable, data.object.name, data.dist);
			}
		}
		
		/**
		 * clear. 
		 * 
		 */		
		public static function clear(clearFunction:Function = null):void
		{
			var i:int;
			for(i = 0; i < _mousePickDatas.length; i ++)
			{
//				clearFunction.call(null, _target);
				_mousePickDatas[i].clear();
			}
			_mousePickDatas.length = 0;
			if(_target)
				_target = null;
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