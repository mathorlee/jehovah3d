package jehovah3d
{
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.light.Light3D;
	import jehovah3d.core.pick.MousePickManager;

	import com.fuwo.math.Ray3D;

	import flash.display3D.Context3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	/**
	 * 虚线Renderer
	 * @author lisongsong
	 * 
	 */	
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
		public static const MAX_TEXTURE_SIZE:int = 2048;
		
		public static function mousePick(mousePoint:Point, disposeFunction:Function = null, compareFunction:Function = null):void
		{
			MousePickManager.dispose(disposeFunction);
			var ray:Ray3D = calculateRay(mousePoint);
			scene.mousePick(ray, mousePoint);
			MousePickManager.sort(compareFunction);
		}
		
		/**
		 * 根据MouseEvent计算从相机发射的射线。 
		 * @param evt
		 * @return 
		 * 
		 */		
		public static function calculateRay(mousePoint:Point):Ray3D
		{
			var p0:Vector3D;
			var dir:Vector3D;
			if(camera.orthographic)
			{
				p0 = new Vector3D((mousePoint.x - camera.viewWidth * 0.5) / camera.viewScale, (camera.viewHeight * 0.5 - mousePoint.y) / camera.viewScale, 0);
				dir = new Vector3D(0, 0, -1);
			}
			else
			{
				p0 = new Vector3D(0, 0, 0);
				dir = new Vector3D((mousePoint.x - camera.viewWidth * 0.5) / camera.viewScale, (camera.viewHeight * 0.5 - mousePoint.y) / camera.viewScale, -camera.viewWidth * 0.5 / Math.tan(camera.fov * 0.5));
				dir.normalize();
			}
			return new Ray3D(p0, dir).transform(camera.localToGlobalMatrix);
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