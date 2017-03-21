package jehovah3d.core.event
{
	import flash.events.Event;
	
	import jehovah3d.core.Object3D;
	
	public class MouseEvent3D extends Event
	{
		public static const MOUSE_DOWN:String = "MouseDown";
		public static const MOUSE_UP:String = "MouseUp";
		public static const MOUSE_OVER:String = "MouseOver";
		public static const MOUSE_CLICK:String = "MouseClick";
		
		private var _obj3d:Object3D;
		public function MouseEvent3D(type:String, obj3d:Object3D, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_obj3d = obj3d;
		}
		
		public function get obj3d():Object3D
		{
			return _obj3d;
		}
		
		override public function clone():Event
		{
			return new MouseEvent3D(type, obj3d, bubbles, cancelable);
		}
	}
}