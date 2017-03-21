package jehovah3d.core.resource
{
	import flash.display3D.Context3D;

	public class Resource
	{
		/**
		 * cached context3d. this variable is to handle context3d loss and avoid resource reloading. 
		 */		
		public var cachedContext3D:Context3D;
		public var isInObjectPool:Boolean = false; //是否在对象池中
		
		public function Resource()
		{
			
		}
		
		/**
		 * upload data to GPU.
		 * @param context3D
		 * 
		 */		
		public function upload(context3D:Context3D):void
		{
			
		}
		
		/**
		 * dispose resource.
		 * 
		 */		
		public function dispose():void
		{
			if(cachedContext3D)
				cachedContext3D = null;
		}
		
		/**
		 * isUploaded. 
		 * @return 
		 * 
		 */		
		public function get isUploaded():Boolean
		{
			return false;
		}
	}
}
