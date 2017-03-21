package jehovah3d.primitive.loft
{
	import flash.geom.Point;

	/**
	 * 闭合路径，坐标系：x右，y上，图形在第四象限，点序列逆时针
	 * @author lisongsong
	 * 
	 */	
	public class LoftShape
	{
		private var _points:Vector.<Point>;
		private var _smoothingGroups:Vector.<int>;
		private var _n:int;
		private var _no:String
		
		public var realHeight:Number;
		public var leftPointIndex:int;
		public var rightPointIndex:int;
		
		/**
		 * 
		 * @param data{"shapePoints", "no", "imageUrl"}
		 * 
		 */		
		public function LoftShape(points:Array, smoothingGroups:Array, no:String)
		{
			var i:int;
			_points = new Vector.<Point>();
			_smoothingGroups = new Vector.<int>();
			for(i = 0; i < points.length; i ++)
			{
				_points.push(new Point(points[i].x, points[i].y));
				_smoothingGroups.push(smoothingGroups[i]);
			}
			_n = _points.length;
			_no = no;
			if(_no == null || _no == "")
				_no = "dd0";
			
			//计算realHeight
			realHeight = 0;
			for(i = 0; i < _points.length; i ++)
				realHeight = Math.max(realHeight, Math.abs(_points[i].y));
			
			//计算leftPointIndex, rightPointIndex
			var minX:Number = Number.MAX_VALUE;
			var maxX:Number = -Number.MAX_VALUE;
			for(i = 0; i < _points.length; i ++)
			{
				minX = Math.min(minX, _points[i].x);
				maxX = Math.max(maxX, _points[i].x);
			}
			for(i = 0; i < _points.length; i ++)
				if(_points[i].x == minX)
				{
					leftPointIndex = i;
					break;
				}
			for(i = 0; i < _points.length; i ++)
				if(_points[i].x == maxX)
				{
					rightPointIndex = i;
					break;
				}
		}
		
		public function get points():Vector.<Point> 
		{
			return _points;
		}
		public function get smoothingGroups():Vector.<int>
		{
			return _smoothingGroups;
		}
		public function get n():int
		{
			return _n;
		}
		public function get no():String
		{
			return _no;
		}
		
		public static const JSON_DD0:String = "{\"imageUrl\":\"phoenix/assets/images/wowUI/loftroofshape/dd0.png\",\"lightSmoothingGroups\":[0,0,0,0],\"no\":\"dd0\",\"lightPoints\":[{\"y\":-3,\"x\":21.75},{\"y\":-7,\"x\":21.75},{\"y\":-7,\"x\":27.25},{\"y\":-3,\"x\":27.25}],\"mainSmoothingGroups\":[\"0\",\"0\",\"0\",\"0\",\"0\",\"0\"],\"mainPoints\":[{\"y\":-7,\"x\":18.999996},{\"y\":0,\"x\":18.999996},{\"y\":0,\"x\":0},{\"y\":-16.999998,\"x\":0},{\"y\":-16.999998,\"x\":30},{\"y\":-6.999994,\"x\":30}]}";
		public static const JSON_DD1:String = "{\"imageUrl\":\"phoenix/assets/images/wowUI/loftroofshape/dd1.png\",\"lightSmoothingGroups\":[0,0,0,0],\"no\":\"dd1\",\"lightPoints\":[{\"y\":-2,\"x\":21.75},{\"y\":-6,\"x\":21.75},{\"y\":-6,\"x\":27.25},{\"y\":-2,\"x\":27.25}],\"mainSmoothingGroups\":[\"0\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"0\",\"0\",\"0\",\"0\",\"0\"],\"mainPoints\":[{\"y\":-16.999998,\"x\":0},{\"y\":-16.999998,\"x\":21.000004},{\"y\":-16.831104,\"x\":21.004311},{\"y\":-16.66688,\"x\":21.032997},{\"y\":-16.509727,\"x\":21.084869},{\"y\":-16.362057,\"x\":21.158707},{\"y\":-16.226274,\"x\":21.253319},{\"y\":-16.104786,\"x\":21.367481},{\"y\":-15.999998,\"x\":21.5},{\"y\":-15.699999,\"x\":21.5},{\"y\":-14.849148,\"x\":21.493073},{\"y\":-14.010551,\"x\":21.585178},{\"y\":-13.19239,\"x\":21.773403},{\"y\":-12.402838,\"x\":22.054829},{\"y\":-11.65007,\"x\":22.426537},{\"y\":-10.942266,\"x\":22.885593},{\"y\":-10.287598,\"x\":23.4291},{\"y\":-9.701406,\"x\":24.045864},{\"y\":-9.195922,\"x\":24.721291},{\"y\":-8.774599,\"x\":25.447433},{\"y\":-8.440893,\"x\":26.216331},{\"y\":-8.198255,\"x\":27.020035},{\"y\":-8.050139,\"x\":27.850578},{\"y\":-8,\"x\":28.700005},{\"y\":-8,\"x\":29},{\"y\":-7.867414,\"x\":29.104748},{\"y\":-7.753212,\"x\":29.226196},{\"y\":-7.658595,\"x\":29.361958},{\"y\":-7.584765,\"x\":29.509617},{\"y\":-7.532921,\"x\":29.666786},{\"y\":-7.504266,\"x\":29.831039},{\"y\":-7.5,\"x\":30},{\"y\":-5.156834,\"x\":30},{\"y\":-5.156834,\"x\":19.000004},{\"y\":0,\"x\":19.000004},{\"y\":0,\"x\":0}]}";
		public static const JSON_DD2:String = "{\"imageUrl\":\"phoenix/assets/images/wowUI/loftroofshape/dd2.png\",\"lightSmoothingGroups\":[0,0,0,0],\"no\":\"dd2\",\"lightPoints\":[{\"y\":-2,\"x\":21.75},{\"y\":-6,\"x\":21.75},{\"y\":-6,\"x\":27.25},{\"y\":-2,\"x\":27.25}],\"mainSmoothingGroups\":[\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\"],\"mainPoints\":[{\"y\":-7,\"x\":18.999996},{\"y\":0,\"x\":18.999996},{\"y\":0,\"x\":0},{\"y\":-17,\"x\":0},{\"y\":-17,\"x\":20.335739},{\"y\":-16.236717,\"x\":20.335739},{\"y\":-16.236717,\"x\":21.487301},{\"y\":-17,\"x\":21.487301},{\"y\":-17,\"x\":24.271675},{\"y\":-12.377636,\"x\":24.271675},{\"y\":-12.377636,\"x\":30},{\"y\":-7.00001,\"x\":30}]}";
		public static const JSON_DD3:String = "{\"imageUrl\":\"phoenix/assets/images/wowUI/loftroofshape/dd3.png\",\"lightSmoothingGroups\":[0,0,0,0],\"no\":\"dd3\",\"lightPoints\":[{\"y\":-3,\"x\":21.75},{\"y\":-7,\"x\":21.75},{\"y\":-7,\"x\":27.25},{\"y\":-3,\"x\":27.25}],\"mainSmoothingGroups\":[\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\",\"0\"],\"mainPoints\":[{\"y\":-7.000002,\"x\":18.999992},{\"y\":0,\"x\":18.999992},{\"y\":0,\"x\":0},{\"y\":-16.999998,\"x\":0},{\"y\":-16.999998,\"x\":20.335739},{\"y\":-15.200686,\"x\":20.335739},{\"y\":-15.200686,\"x\":23.093155},{\"y\":-13.200975,\"x\":23.093155},{\"y\":-13.200975,\"x\":25.582024},{\"y\":-11.152441,\"x\":25.582024},{\"y\":-11.152441,\"x\":29.999992},{\"y\":-7.000002,\"x\":29.999992}]}";
		public static const JSON_DD4:String = "{\"imageUrl\":\"phoenix/assets/images/wowUI/loftroofshape/dd4.png\",\"lightSmoothingGroups\":[0,0,0,0],\"no\":\"dd4\",\"lightPoints\":[{\"y\":-2,\"x\":21.75},{\"y\":-6,\"x\":21.75},{\"y\":-6,\"x\":27.25},{\"y\":-2,\"x\":27.25}],\"mainSmoothingGroups\":[\"0\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"1\",\"0\",\"0\",\"0\",\"0\",\"0\"],\"mainPoints\":[{\"y\":-15.199997,\"x\":0},{\"y\":-15.199997,\"x\":22.699997},{\"y\":-14.499998,\"x\":22.699997},{\"y\":-14.499998,\"x\":23.199997},{\"y\":-13.99995,\"x\":23.199997},{\"y\":-13.774651,\"x\":23.71381},{\"y\":-13.462032,\"x\":24.164371},{\"y\":-13.074642,\"x\":24.543325},{\"y\":-12.625042,\"x\":24.842329},{\"y\":-12.125774,\"x\":25.053032},{\"y\":-11.589399,\"x\":25.167095},{\"y\":-11.028465,\"x\":25.17617},{\"y\":-10.328617,\"x\":25.392097},{\"y\":-9.70443,\"x\":25.738003},{\"y\":-9.169662,\"x\":26.196247},{\"y\":-8.738073,\"x\":26.749203},{\"y\":-8.423426,\"x\":27.379232},{\"y\":-8.239481,\"x\":28.068712},{\"y\":-8.199999,\"x\":28.800003},{\"y\":-8.199999,\"x\":29.300003},{\"y\":-7.699999,\"x\":29.300003},{\"y\":-7.699999,\"x\":30},{\"y\":-4.72249,\"x\":30},{\"y\":-4.72249,\"x\":19},{\"y\":0,\"x\":19},{\"y\":0,\"x\":0}]}";
		public static const JSON_DD5:String = "{\"no\":\"dd5\",\"lightSmoothingGroups\":[0,0,0,0],\"lightPoints\":[{\"y\":0,\"x\":0},{\"y\":0,\"x\":0},{\"y\":0,\"x\":0},{\"y\":0,\"x\":0}],\"mainSmoothingGroups\":[\"0\",\"0\",\"0\",\"0\"],\"mainPoints\":[{\"y\":0,\"x\":0},{\"y\":-20,\"x\":0},{\"y\":-20,\"x\":40},{\"y\":0,\"x\":40}],\"imageUrl\":\"phoenix/assets/images/wowUI/loftroofshape/dd5.png\"}";
	}
}