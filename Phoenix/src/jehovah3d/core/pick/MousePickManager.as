package jehovah3d.core.pick
{
	/**
	 * SUMousePickManager
	 * @author 李松松
	 * 
	 */	
	public class MousePickManager
	{
		public static var target:MousePickData;
		private static var dataArr:Vector.<MousePickData> = new Vector.<MousePickData>();
		
		/**
		 * 添加
		 * @param rid
		 * 
		 */		
		public static function add(mpd:MousePickData):void
		{
			dataArr.push(mpd);
		}
		
		/**
		 * 排序
		 * 
		 */		
		public static function sort(compareFunction:Function = null):void
		{
			if(dataArr.length == 0)
				return ;
			
			dataArr.sort(compareFunction != null ? compareFunction : defaultCompareFunc);
			target = dataArr[0];
		}
		
		/**
		 * 默认排序函数
		 * @param t1
		 * @param t2
		 * @return 
		 * 
		 */		
		private static function defaultCompareFunc(t1:MousePickData, t2:MousePickData):int
		{
			if(t1.dist < t2.dist)
				return -1;
			if(t1.dist > t2.dist)
				return 1;
			return 0;
		}
		
		/**
		 * clear. 
		 * 
		 */		
		public static function dispose(disposeFunction:Function = null):void
		{
			for each (var sub:MousePickData in dataArr)
			{
				disposeFunction.apply(null, [sub]);
				sub.dispose();
			}
			dataArr.length = 0;
			target = null;
		}
		
		public static function output():void
		{
			trace("cnt: " + dataArr.length);
			for each (var data:MousePickData in dataArr)
			{
				data.output();
			}
			trace();
		}
	}
}