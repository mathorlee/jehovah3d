package jehovah3d
{
	import flash.display3D.Context3D;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.light.Light3D;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Ray;

	public class Jehovah
	{
		//lighting system
		public static var ambientCoefficient:Number = 0.5;
		public static var diffuseCoefficient:Number = 0.6;
		public static var lights:Vector.<Light3D> = new Vector.<Light3D>();
		public static var currentLight:Light3D;
		public static var defaultLight:Light3D; //3d秀默认一只平行光
		public static var useDefaultLight:Boolean = true; //使用默认灯光, 灯光固定, 旋转场景
		
		public static var camera:Camera3D;
		public static var scene:Object3D;
		public static var context3D:Context3D;
		
		//render mode, affects render channel
		public static const RENDER_ALL:uint = 0;
		public static const RENDER_DEPTH:uint = 1;
		public static const RENDER_NORMAL:uint = 2;
		public static const RENDER_AMBIENTANDREFLECTION:uint = 3; //存储到camera.ambientAndReflectionTexture
		public static const RENDER_DIFFUSEANDSEPCULAR:uint = 4; //存储到light.diffuseAndSpecularTexture
		public static const RENDER_UNIQUE_COLOR:uint = 5;
		public static var renderMode:uint = 0;
		
		public static var useSSAO:Boolean = false; //是否启用SSAO
		
		public static var enableCollisionDetection:Boolean = false; //enable collision detection.
		public static var maxVertexCountInOneVertexBuffer:int = 65535; //每个顶点缓冲中最大顶点数。
		public static var vertexAndLinePickToleranceInPixels:Number = 10; //点击SUVertex、SUEdge时屏幕上像素容忍度
		
		public static function mousePick(evt:MouseEvent, clearFunction:Function = null, compareFunction:Function = null):void
		{
			MousePickManager.clear();
			
			var ray:Ray = calculateRay(new Point(evt.localX, evt.localY));
			scene.mousePick(ray, new Point(evt.localX, evt.localY));
			MousePickManager.sort(compareFunction);
			if (MousePickManager.target)
				MousePickManager.target.output();
		}
		
		/**
		 * 根据MouseEvent计算从相机发射的射线。 
		 * @param evt
		 * @return 
		 * 
		 */		
		public static function calculateRay(mousePoint:Point):Ray
		{
			var p0:Vector3D;
			var dir:Vector3D;
			if(camera.orthographic)
			{
				p0 = new Vector3D((mousePoint.x - camera.viewWidth * 0.5) * camera.scaleX, (camera.viewHeight * 0.5 - mousePoint.y) * camera.scaleY, 0);
				dir = new Vector3D(0, 0, -1);
			}
			else
			{
				p0 = new Vector3D(0, 0, 0);
				dir = new Vector3D((mousePoint.x - camera.viewWidth * 0.5) / camera.scaleX, (camera.viewHeight * 0.5 - mousePoint.y) / camera.scaleY, -camera.viewWidth * 0.5 / Math.tan(camera.fov * 0.5) / camera.scaleZ);
				dir.normalize();
			}
			return new Ray(p0, dir).transform(camera.localToGlobalMatrix);
//			return new Ray(p0, dir).transform(camera.noScaleMatrix);
		}
		
		public static function dispose():void
		{
			if(lights)
				lights.length = 0;
			if(currentLight)
				currentLight = null;
			if(camera)
				camera = null;
			if(scene)
				scene = null;
			if(context3D)
				context3D = null;
		}
		
	}
}