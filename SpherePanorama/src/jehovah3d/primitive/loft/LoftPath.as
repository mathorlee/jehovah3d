package jehovah3d.primitive.loft
{
	import com.fuwo.math.MyMath;
	
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import jehovah3d.core.pick.Plane;
	
	import phoenix.model.threed.a3d.Room3Dgenerator;

	/**
	 * 放样路径，（非）闭合
	 * @author lisongsong
	 * 
	 */	
	public class LoftPath
	{
		private var _points:Vector.<Point>;
		private var _closed:Boolean;
		private var _planes:Vector.<Plane>;
		private var _n:int;
		
		public var realX:Number;
		public var realY:Number;
		public var realWidth:Number;
		public var realLength:Number;
		
		public function LoftPath(points:Vector.<Point>, closed:Boolean)
		{
			_points = points.slice();
			_n = _points.length;
			if(_n <= 1)
				throw new Error();
			_closed = closed;
			
			calculateRealXY();
			initPlanes();
		}
		
		public function calculateRealXY():void
		{
			var i:int;
			var minX:Number = Number.MAX_VALUE;
			var minY:Number = Number.MAX_VALUE;
			var maxX:Number = -Number.MAX_VALUE;
			var maxY:Number = -Number.MAX_VALUE;
			
			for(i = 0; i < _points.length; i ++)
			{
				minX = Math.min(minX, _points[i].x);
				minY = Math.min(minY, _points[i].y);
				maxX = Math.max(maxX, _points[i].x);
				maxY = Math.max(maxY, _points[i].y);
			}
			realX = (minX + maxX) / 2;
			realY = (minY + maxY) / 2;
			
			realWidth = maxX - minX;
			realLength = maxY - minY;
			for(i = 0; i < _points.length; i ++)
			{
				_points[i].x -= realX;
				_points[i].y -= realY;
			}
		}
		
		/**
		 * 计算planes
		 * 
		 */		
		private function initPlanes():void
		{
			var i:int;
			_planes = new Vector.<Plane>();
			if(_n == 2)
			{
				_planes.push(calculatePlane(_points[0], _points[0], _points[1]));
				_planes.push(calculatePlane(_points[0], _points[1], _points[1]));
			}
			else
			{
				_planes.push(calculatePlane(_points[closed ? _n - 1 : 0], _points[0], _points[1]));
				for(i = 1; i < _n - 1; i ++)
					_planes.push(calculatePlane(_points[i - 1], _points[i], _points[i + 1]));
				_planes.push(calculatePlane(_points[n - 2], _points[n - 1], _points[closed ? 0 : n - 1]));
			}
		}
		
		private function calculatePlane(p0:Point, p1:Point, p2:Point):Plane
		{
			var dir:Point;
			if(MyMath.isTwoPointEqual(p0, p1))
			{
				dir = p2.subtract(p1);
				dir.normalize(1);
				return new Plane(new Vector3D(p1.x, p1.y, 0), new Vector3D(dir.x, dir.y, 0));
			}
			else if(MyMath.isTwoPointEqual(p1, p2))
			{
				dir = p1.subtract(p0);
				dir.normalize(1);
				return new Plane(new Vector3D(p1.x, p1.y, 0), new Vector3D(dir.x, dir.y, 0));
			}
			
			return Room3Dgenerator.calculateBisectorPlane(p0, p1, p2)
		}
		
		/**
		 * 放样路径上的点序列
		 * @return 
		 * 
		 */		
		public function get points():Vector.<Point>
		{
			return _points;
		}
		
		/**
		 * 放样路径是否是闭合的
		 * @return 
		 * 
		 */		
		public function get closed():Boolean
		{
			return _closed;
		}
		
		/**
		 * 点所在的角平分线表示的平面
		 * @return 
		 * 
		 */		
		public function get planes():Vector.<Plane>
		{
			return _planes;
		}
		public function get n():int
		{
			return _n;
		}
	}
}