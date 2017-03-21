package panorama
{
	import com.fuwo.math.MyMath;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import jehovah3d.Jehovah;
	import jehovah3d.Scene3DTemplateForASProject;
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.util.AssetsManager;
	import jehovah3d.util.MeshMaker;
	
	import utils.easybutton.EasyButton;
	
	public class SpherePanoramaGPU extends Scene3DTemplateForASProject
	{
		[Embed(source="/panorama/assets/sphere/1.jpg", mimeType="image/jpeg")]
		public var TEXTURE:Class;
		
		private var oldPoint:Point = new Point();
		private var newPoint:Point = new Point();
		private var showPurchaseButton:Boolean = true;
		private var speedX:Number = 0;
		private var speedZ:Number = 0;
		private var useSpeed:Boolean = true;
		private var autoRotate:Boolean = true;
		private var autoRotateSpeed:Number = 0.005;
		
		private var cameraRotationX:Number;
		private var cameraRotationZ:Number;
		private var initCameraRotationX:Number = Math.PI / 2;
		private var initCameraRotationZ:Number = 0;
		
		public function SpherePanoramaGPU()
		{
			super();
		}
		
		override public function initCamera():void
		{
			camera = new jehovah3d.core.Camera3D(stage.stageWidth, stage.stageHeight, 10, 1000, Math.PI * 0.5, false, 0xFF7700);
			camera.view.hideDiagram();
		}
		
		override public function initScene():void
		{
			scene.addChild(camera);
			Mouse.cursor = MouseCursor.HAND;
			
			//贴图
			var bmd:BitmapData = new TEXTURE().bitmapData as BitmapData;
			
			var bmd0:BitmapData = new BitmapData(bmd.height, bmd.height, bmd.transparent);
			bmd0.copyPixels(bmd, new Rectangle(bmd.height, 0, bmd.height, bmd.height), new Point(0, 0));
			AssetsManager.addTextureResource("bmd0", bmd0);
			
			var bmd1:BitmapData = new BitmapData(bmd.height, bmd.height, bmd.transparent);
			bmd1.copyPixels(bmd, new Rectangle(0, 0, bmd.height, bmd.height), new Point(0, 0));
			AssetsManager.addTextureResource("bmd1", bmd1);
			
			//Mesh
			var coordinateData:Vector.<Number> = new Vector.<Number>();
			var coordinateDataSmall:Vector.<Number> = new Vector.<Number>();
			var diffuseUVData:Vector.<Number> = new Vector.<Number>();
			var indexData:Vector.<uint> = new Vector.<uint>();
			var i:int;
			var j:int;
			var n:int = 180;
			var m:int = n / 2;
			var radius:Number = 100;
			for (i = 0; i <= n / 2; i ++)
			{
				var alpha:Number = Math.PI * 2 * i / n;
				for (j = 0; j <=m ; j ++)
				{
					var beta:Number = -Math.PI / 2 + Math.PI / m * j;
					coordinateData.push(Math.cos(beta) * Math.cos(alpha) * radius, Math.cos(beta) * Math.sin(alpha) * radius, Math.sin(beta) * radius);
					coordinateDataSmall.push(Math.cos(beta) * Math.cos(alpha) * radius / 2, Math.cos(beta) * Math.sin(alpha) * radius / 2, Math.sin(beta) * radius / 2);
					diffuseUVData.push(1 - i / n * 2, 0.5 - beta / Math.PI);
				}
			}
			//添加n*(m-2)*2+n*2个三角形
			for (i = 0; i < n / 2; i ++)
			{
				var t0:int = (m + 1) * i;
				var t1:int = (m + 1) * (i + 1);
				for (j = 0; j < m; j ++)
				{
					indexData.push(
						t0 + j, t0 + j + 1, t1 + j + 1, 
						t0 + j, t1 + j + 1, t1 + j
					);
				}
			}
//			MeshMaker.generateSphereGeometrySplitUV(coordinateData, diffuseUVData, indexData, 100, 180, null);
			var mesh0:Mesh = MeshMaker.generateMesh(coordinateData, diffuseUVData, null, indexData, "mesh0");
			mesh0.mtl = new DiffuseMtl();
			mesh0.mtl.diffuseMapResource = AssetsManager.getTextureResourceByKey("bmd0").textureResource;
			mesh0.geometry.upload(Jehovah.context3D);
			mesh0.useMip = false;
			mesh0.useClamp = true;
			scene.addChild(mesh0);
			
			var mesh1:Mesh = MeshMaker.generateMesh(coordinateData, diffuseUVData, null, indexData, "mesh1");
			mesh1.mtl = new DiffuseMtl();
			mesh1.mtl.diffuseMapResource = AssetsManager.getTextureResourceByKey("bmd1").textureResource;
			mesh1.geometry.upload(Jehovah.context3D);
			mesh1.useMip = false;
			mesh1.useClamp = true;
			scene.addChild(mesh1);
			mesh1.rotationZ = Math.PI;
			
			initBehavior();
			initUI();
			onResetClick(null);
		}
		
		private function initBehavior():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
		
		override public function onResize(evt:Event):void
		{
			super.onResize(evt);
			if(toolbar)
			{
				toolbar.x = (stage.stageWidth - toolbar.width) * 0.5;
				toolbar.y = stage.stageHeight - toolbar.height;
			}
			if(purchaseBTN)
			{
				purchaseBTN.x = stage.stageWidth - purchaseBTN.width;
				purchaseBTN.y = stage.stageHeight - purchaseBTN.height;
			}
			if(logo)
			{
				logo.x = 0;
				logo.y = stage.stageHeight - logo.height;
			}
		}
		
		private function onRemove(evt:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			dispose();
		}
		
		private function onEnterFrame(evt:Event):void
		{
			speedZ *= 0.9;
			speedX *= 0.9;
			if (useSpeed && Math.abs(speedZ) > 0.0001)
				cameraRotationZ += speedZ;
			if (useSpeed && Math.abs(speedX) > 0.0001)
				cameraRotationX += speedX;
			if (autoRotate)
				cameraRotationZ += autoRotateSpeed;
			
			updateCameraMatrix();
			camera.render();
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			autoRotate = false;
			useSpeed = false;
			
			addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			
			oldPoint.x = evt.localX;
			oldPoint.y = evt.localY;
		}
		
		private function onMouseOver(evt:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.HAND;
		}
		
		private function onMouseOut(evt:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		private function onMouseMove(evt:MouseEvent):void
		{
			newPoint.x = evt.localX;
			newPoint.y = evt.localY;
			
			var p0:Point = newPoint.subtract(oldPoint);
			speedZ = -(p0.x / camera.viewWidth) * Math.PI;
			speedX = -(p0.y / camera.viewHeight) * Math.PI / 2;
			cameraRotationZ += speedZ;
			cameraRotationX += speedX;
			
			oldPoint.x = evt.localX;
			oldPoint.y = evt.localY;
		}
		
		private function onMouseUp(evt:MouseEvent):void
		{
			useSpeed = true;
			removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
		}
		
		/**
		 * 更新相机矩阵
		 * 
		 */		
		private function updateCameraMatrix():void
		{
			var matrix:Matrix3D = new Matrix3D();
			matrix.appendRotation(cameraRotationX * 180 / Math.PI, Vector3D.X_AXIS);
			matrix.appendRotation(cameraRotationZ * 180 / Math.PI, Vector3D.Z_AXIS);
			camera.matrix = matrix;
		}
		
		override public function dispose():void
		{
			super.dispose();
			oldPoint = null;
			newPoint = null;
		}
		
		public static function expand34BoxPanorama(source:BitmapData, a:int, b:int):BitmapData
		{
			var transparent:Boolean = source.transparent;
			var ret:BitmapData = new BitmapData(3 * a + 2 * b, 4 * a + 2 * b, transparent);
			ret.copyPixels(source, new Rectangle(0, 0, 3 * a, 4 * a), new Point(b, b));
			
			var arr:Array = [
				[0, a, a, b, Math.PI / 2], //1
				[2 * a, a, 2 * a + b, b, -Math.PI / 2], 
				[a, 0, b, a, -Math.PI / 2], 
				[2 * a - b, 0, 2 * a + b, a, Math.PI / 2], 
				[a, 2 * a, b, 2 * a + b, Math.PI / 2], 
				[2 * a - b, 2 * a, 2 * a + b, 2 * a + b, -Math.PI / 2], 
				[0, 2 * a - b, a, 2 * a + b, -Math.PI / 2], 
				[2 * a, 2 * a - b, 2 * a + b, 2 * a + b, Math.PI / 2], 
				[0, a, a, 3 * a + b, Math.PI], 
				[3 * a - b, a, 2 * a + b, 3 * a + b, Math.PI], 
				[a, 3 * a, 0, a + b, Math.PI], //11
				[2 * a - b, 3 * a, 3 * a + b, a + b, Math.PI], 
				[a, 4 * a - b, a + b, 0, 0], 
				[a, 0, a + b, 4 * a + b, 0]
			];
			
			var i:int;
			var piece:BitmapData;
			for(i = 10; i < arr.length; i ++)
			{
				if([1, 2, 7, 8, 13, 14].indexOf(i + 1) != -1)
					piece = new BitmapData(a, b, transparent);
				else
					piece = new BitmapData(b, a, transparent);
				piece.copyPixels(source, new Rectangle(arr[i][0], arr[i][1], piece.width, piece.height), new Point(0, 0));
				piece = MyMath.rotateBitmapData(arr[i][4], piece);
				ret.copyPixels(piece, new Rectangle(0, 0, piece.width, piece.height), new Point(arr[i][2], arr[i][3]));
			}
			return ret;
		}
		
		private function rotateBitmapDataByPI(source:BitmapData):BitmapData
		{
			var ret:BitmapData = new BitmapData(source.width, source.height, source.transparent);
			var matrix:Matrix = new Matrix();
			matrix.scale(-1, -1);
			matrix.translate(source.width, source.height);
			ret.draw(source, matrix);
			return ret;
		}
		
		
		[Embed(source="/panorama/assets/images/newui/reset-normal.png", mimeType="image/png")]
		private var reset_default:Class;
		[Embed(source="/panorama/assets/images/newui/reset-hover.png", mimeType="image/png")]
		private var reset_over:Class;
		private var resetBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/arrow-down-normal.png", mimeType="image/png")]
		private var down_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-down-hover.png", mimeType="image/png")]
		private var down_over:Class;
		private var downBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/arrow-up-normal.png", mimeType="image/png")]
		private var up_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-up-hover.png", mimeType="image/png")]
		private var up_over:Class;
		private var upBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/arrow-left-normal.png", mimeType="image/png")]
		private var left_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-left-hover.png", mimeType="image/png")]
		private var left_over:Class;
		private var leftBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/arrow-right-normal.png", mimeType="image/png")]
		private var right_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-right-hover.png", mimeType="image/png")]
		private var right_over:Class;
		private var rightBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/zoom-in-normal.png", mimeType="image/png")]
		private var zoomin_default:Class;
		[Embed(source="/panorama/assets/images/newui/zoom-in-hover.png", mimeType="image/png")]
		private var zoomin_over:Class;
		private var zoominBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/zoom-out-normal.png", mimeType="image/png")]
		private var zoomout_default:Class;
		[Embed(source="/panorama/assets/images/newui/zoom-out-hover.png", mimeType="image/png")]
		private var zoomout_over:Class;
		private var zoomoutBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/shopping-normal.png", mimeType="image/png")]
		private var purchase_default:Class;
		[Embed(source="/panorama/assets/images/newui/shopping-hover.png", mimeType="image/png")]
		private var purchase_over:Class;
		private var purchaseBTN:EasyButton;
		
		[Embed(source="/panorama/assets/images/newui/line-1px.png", mimeType="image/png")]
		private var line_1px:Class;
		[Embed(source="/panorama/assets/images/newui/line-2px.png", mimeType="image/png")]
		private var line_2px:Class;
		
		[Embed(source="/panorama/assets/images/newui/logo.png", mimeType="image/png")]
		private var logo_default:Class;
		
		[Embed(source="/panorama/assets/images/newui2/shiyun_logo.png", mimeType="image/png")]
		private var logo_shop:Class;
		
		private var toolbar:Sprite;
		private var logo:Sprite;
		private var shoplogo:Sprite;
		
		private function initUI():void
		{
			toolbar = new Sprite();
			addChild(toolbar);
			
			resetBTN = new EasyButton(new reset_default(), new reset_over(), new reset_default());
			downBTN = new EasyButton(new down_default(), new down_over(), new down_default());
			upBTN = new EasyButton(new up_default(), new up_over(), new up_default());
			leftBTN = new EasyButton(new left_default(), new left_over(), new left_default());
			rightBTN = new EasyButton(new right_default(), new right_over(), new right_default());
			zoominBTN = new EasyButton(new zoomin_default(), new zoomin_over(), new zoomin_default());
			zoomoutBTN = new EasyButton(new zoomout_default(), new zoomout_over(), new zoomout_default());
			purchaseBTN = new EasyButton(new purchase_default(), new purchase_over(), new purchase_default());
			logo = new Sprite(); logo.addChild(new logo_default());
			
			shoplogo = new Sprite(); 
//			shoplogo.addChild(new logo_shop());
			
			resetBTN.addEventListener(MouseEvent.CLICK, onResetClick);
			downBTN.addEventListener(MouseEvent.CLICK, onDownClick);
			upBTN.addEventListener(MouseEvent.CLICK, onUpClick);
			leftBTN.addEventListener(MouseEvent.CLICK, onLeftClick);
			rightBTN.addEventListener(MouseEvent.CLICK, onRightClick);
			zoominBTN.addEventListener(MouseEvent.CLICK, onZoomInClick);
			zoomoutBTN.addEventListener(MouseEvent.CLICK, onZoomOutClick);
			purchaseBTN.addEventListener(MouseEvent.CLICK, onPurchaseClick);
			logo.addEventListener(MouseEvent.CLICK, onLogoClick); logo.buttonMode = true;
			
			var tmp:Number = 0;
			toolbar.addChild(resetBTN); resetBTN.x = tmp; tmp += resetBTN.width;
			toolbar.addChild(new line_2px()); toolbar.getChildAt(toolbar.numChildren - 1).x = tmp; tmp += 2;
			toolbar.addChild(leftBTN); leftBTN.x = tmp; tmp += leftBTN.width;
			toolbar.addChild(new line_1px()); toolbar.getChildAt(toolbar.numChildren - 1).x = tmp; tmp += 1;
			toolbar.addChild(rightBTN); rightBTN.x = tmp; tmp += rightBTN.width;
			toolbar.addChild(new line_1px()); toolbar.getChildAt(toolbar.numChildren - 1).x = tmp; tmp += 1;
			toolbar.addChild(upBTN); upBTN.x = tmp; tmp += upBTN.width;
			toolbar.addChild(new line_1px()); toolbar.getChildAt(toolbar.numChildren - 1).x = tmp; tmp += 1;
			toolbar.addChild(downBTN); downBTN.x = tmp; tmp += downBTN.width;
			toolbar.addChild(new line_2px()); toolbar.getChildAt(toolbar.numChildren - 1).x = tmp; tmp += 2;
			toolbar.addChild(zoominBTN); zoominBTN.x = tmp; tmp += zoominBTN.width;
			toolbar.addChild(new line_1px()); toolbar.getChildAt(toolbar.numChildren - 1).x = tmp; tmp += 1;
			toolbar.addChild(zoomoutBTN); zoomoutBTN.x = tmp; tmp += zoomoutBTN.width;
			addChild(purchaseBTN);
			purchaseBTN.visible = false;
			addChild(logo);
			addChild(shoplogo);
			onResize(null);
			
//			toolbar.addEventListener(MouseEvent.MOUSE_OUT, onToolbarMouseOut);
//			toolbar.addEventListener(MouseEvent.MOUSE_OVER, onToolbarMouseOver);
		}
		private function onResetClick(evt:MouseEvent):void
		{
			cameraRotationX = initCameraRotationX;
			cameraRotationZ = initCameraRotationZ;
			speedZ = 0;
			speedX = 0;
			autoRotate = true;
		}
		private function onDownClick(evt:MouseEvent):void
		{
			cameraRotationX -= 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedX = -1.0 / 180 * Math.PI;
		}
		private function onUpClick(evt:MouseEvent):void
		{
			cameraRotationX += 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedX = 1.0 / 180 * Math.PI;
		}
		private function onLeftClick(evt:MouseEvent):void
		{
			cameraRotationZ += 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedZ = 1.0 / 180 * Math.PI;
		}
		private function onRightClick(evt:MouseEvent):void
		{
			cameraRotationZ -= 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedZ = -1.0 / 180 * Math.PI;
		}
		private function onZoomInClick(evt:MouseEvent):void
		{
			camera.fov -= 0.1;
			if(camera.fov > Math.PI * 0.6)
				camera.fov = Math.PI * 0.6;
			if(camera.fov < Math.PI * 0.25)
				camera.fov = Math.PI * 0.25;
		}
		private function onZoomOutClick(evt:MouseEvent):void
		{
			camera.fov += 0.1;
			if(camera.fov > Math.PI * 0.6)
				camera.fov = Math.PI * 0.6;
			if(camera.fov < Math.PI * 0.25)
				camera.fov = Math.PI * 0.25;
		}
		private function onPurchaseClick(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://detail.tmall.com/item.htm?id=38780224577"), "_blank");
		}
		private function onLogoClick(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://fuwu.taobao.com/ser/detail.htm?spm=a1z13.1113643.1113643.15.wCDzlW&service_code=FW_GOODS-1868472&tracelog=search&scm=&ppath=&labels="), "_blank");
		}
		
		private function onToolbarMouseOut(evt:MouseEvent):void
		{
			toolbar.addEventListener(Event.ENTER_FRAME, fadeDisappear);
		}
		private function onToolbarMouseOver(evt:MouseEvent):void
		{
			if(toolbar.hasEventListener(Event.ENTER_FRAME))
				toolbar.removeEventListener(Event.ENTER_FRAME, fadeDisappear);
			toolbar.alpha = 1.0;
		}
		private function fadeDisappear(evt:Event):void
		{
			toolbar.alpha -= 0.02;
			if(toolbar.alpha <= 0)
				toolbar.removeEventListener(Event.ENTER_FRAME, fadeDisappear);
		}
	}
}

