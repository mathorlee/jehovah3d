package panorama
{
	import com.fuwo.math.MyMath;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.TriangleCulling;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import panorama.culling.CalculateCulling;
	import panorama.culling.Frustum;
	import panorama.geometry.Triangle;
	import panorama.geometry.Vertex;
	
	import utils.easybutton.EasyButton;
	
	public class EmbedResourceSpherePanorama3DShowPlayLoadingMultiRoom extends Sprite
	{
		[Embed(source="/panorama/assets/sphere/vertex.txt", mimeType="application/octet-stream")]
		public var VERTEX:Class;
		[Embed(source="/panorama/assets/sphere/uv.txt", mimeType="application/octet-stream")]
		public var UV:Class;
		[Embed(source="/panorama/assets/sphere/index.txt", mimeType="application/octet-stream")]
		public var INDEX:Class;
		
		private var bmd:BitmapData;
		private var scene:Object3D;
		private var camera:Camera3D;
		private var canvas:Sprite;
		private var frustum:Frustum;
		private var inputTriangles:Vector.<Triangle>;
		
		private var imageURL:String;
		private var canvasWidth:Number;
		private var canvasHeight:Number;
		
		private var oldPoint:Point = new Point();
		private var newPoint:Point = new Point();
		private var showPurchaseButton:Boolean = true;
//		private var initRotationY:Number = 2.0254186533319953;
		private var initRotationY:Number = 0;
		private var speedX:Number = 0;
		private var speedY:Number = 0;
		private var useSpeed:Boolean = true;
		private var autoRotate:Boolean = true;
		private var autoRotateSpeed:Number = 0.005;
		
		private var loadingFlower:LoadingFlower;
		
		private var multiRoom:MultiRoom;
		
		public function EmbedResourceSpherePanorama3DShowPlayLoadingMultiRoom()
		{
			onAdded();
		}
		
		private function onAdded():void
		{
			stage.addEventListener(Event.RESIZE, onResize);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			canvasWidth = stage.stageWidth;
			canvasHeight = stage.stageHeight;
			
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			
			initTriangles();
			//bmd = new TEXTURE().bitmapData as BitmapData;
			
			multiRoom = new MultiRoom();
			bmd = multiRoom.getFirstBMD();
			addChild(multiRoom);
			
			initLoadingPage();
		}
		
		public function setBMD(bitmapData:BitmapData):void
		{
			bmd = bitmapData;
		}
		
		private function initTriangles():void
		{
			var t:ByteArray = new VERTEX() as ByteArray;
			var v_str:String = t.readUTFBytes(t.length);
			var arr:Array;
			
			arr = v_str.split("\r\n");
			
			var v_arr:Array;
			var uv_arr:Array;
			var i_arr:Array;
			var i:int;
			var ba:ByteArray;
			var tmp_arr:Array;
			
			ba = new VERTEX() as ByteArray;
			v_arr = ba.readUTFBytes(ba.length).split("\r\n");
			ba = new UV() as ByteArray;
			uv_arr = ba.readUTFBytes(ba.length).split("\r\n");
			ba = new INDEX() as ByteArray;
			i_arr = ba.readUTFBytes(ba.length).split("\r\n");
			for (i = 0; i < v_arr.length; i ++)
				v_arr[i] = String(v_arr[i]).split(" ");
			for (i = 0; i < uv_arr.length; i ++)
				uv_arr[i] = String(uv_arr[i]).split(" ");
			for (i = 0; i < i_arr.length; i ++)
				i_arr[i] = String(i_arr[i]).split(" ");
			
			
			inputTriangles = new Vector.<Triangle>();
			for (i = 0; i < i_arr.length; i ++)
			{
				var i0:int = i_arr[i][0];
				var i1:int = i_arr[i][3];
				var i2:int = i_arr[i][6];
				var uv0:int = i_arr[i][2];
				var uv1:int = i_arr[i][5];
				var uv2:int = i_arr[i][8];
				
				//(x,y,z)->(x,-z,y), (u,v)->(-u,1-v)
				inputTriangles.push(new Triangle(
					new Vertex(new Vector3D(v_arr[i0][0], -v_arr[i0][2], v_arr[i0][1]), new Point(-uv_arr[uv0][0], 1 - uv_arr[uv0][1])), 
					new Vertex(new Vector3D(v_arr[i1][0], -v_arr[i1][2], v_arr[i1][1]), new Point(-uv_arr[uv1][0], 1 - uv_arr[uv1][1])), 
					new Vertex(new Vector3D(v_arr[i2][0], -v_arr[i2][2], v_arr[i2][1]), new Point(-uv_arr[uv2][0], 1 - uv_arr[uv2][1]))
				));
			}
		}
		
		private function onResize(evt:Event):void
		{
			canvasWidth = stage.stageWidth;
			canvasHeight = stage.stageHeight;
			if(canvas)
			{
				canvas.x = canvasWidth * 0.5;
				canvas.y = canvasHeight * 0.5;
			}
			if(camera)
			{
				camera.viewWidth = canvasWidth;
				camera.viewHeight = canvasHeight;
			}
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
			if(loadingFlower)
			{
				loadingFlower.x = stage.stageWidth / 2 - loadingFlower.width / 2;
				loadingFlower.y = stage.stageHeight/ 2 - loadingFlower.height / 2;
			}
			if (playBTN)
			{
				playBTN.x = stage.stageWidth / 2 - playBTN.width / 2;
				playBTN.y = stage.stageHeight/ 2 - playBTN.height / 2;
			}
		}
		
		private function onRemove(evt:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			canvas.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			canvas.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			canvas.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			dispose();
		}
		
		private function initScene():void
		{
			scene = new Object3D();
			camera = new Camera3D(Math.PI * 0.5, canvasWidth, canvasHeight);
			camera.z = 0;
			
			canvas = new Sprite();
			addChildAt(canvas, 0);
			canvas.x = canvasWidth * 0.5;
			canvas.y = canvasHeight * 0.5;
			
			onResetClick(null);
		}
		
		private function initBehavior():void
		{
			Mouse.cursor = MouseCursor.HAND;
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			canvas.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			canvas.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			canvas.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
		
		private function onEnterFrame(evt:Event):void
		{
			render();
			var sceneMatrix:Matrix3D = new Matrix3D();
			sceneMatrix.appendRotation(-scene.rotationY / Math.PI * 180, Vector3D.Z_AXIS);
			sceneMatrix.appendRotation(scene.rotationX / Math.PI * 180, Vector3D.X_AXIS);
			multiRoom.updateButtons(sceneMatrix, camera.viewWidth, camera.viewHeight, camera.fov, bmd);
			multiRoom.updateRoomButtonBar(stage.stageWidth, stage.stageHeight);
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			autoRotate = false;
			useSpeed = false;
			canvas.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			canvas.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			canvas.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
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
			
			speedX = (newPoint.y - oldPoint.y) / stage.stageHeight * 180 / 180 * Math.PI;
			speedY = -(newPoint.x - oldPoint.x) / stage.stageWidth * 180 / 180 * Math.PI;
			scene.rotationX += speedX;
			scene.rotationY += speedY;
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		
		private function onMouseUp(evt:MouseEvent):void
		{
			useSpeed = true;
			if(canvas.hasEventListener(MouseEvent.MOUSE_MOVE))
				canvas.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if(canvas.hasEventListener(MouseEvent.MOUSE_UP))
				canvas.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(canvas.hasEventListener(MouseEvent.MOUSE_OUT))
				canvas.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
		}
		
		private function render():void
		{
			speedX *= 0.9;
			speedY *= 0.9;
			if (useSpeed && Math.abs(speedX) > 0.0001)
				scene.rotationX += speedX;
			if (useSpeed && Math.abs(speedY) > 0.0001)
				scene.rotationY += speedY;
			if (autoRotate)
				scene.rotationY -= autoRotateSpeed;
			
			camera.updateMatrix();
			camera.updatePM();
			scene.updateMatrix();
			var matrix:Matrix3D = new Matrix3D();
			matrix.copyFrom(scene.matrix);
			matrix.append(camera.inverseMatrix);
			
			var i:int;
			var inputCopy:Vector.<Triangle> = new Vector.<Triangle>();
			for(i = 0; i < inputTriangles.length; i ++)
				inputCopy.push(inputTriangles[i].clone());
			for(i = 0; i < inputCopy.length; i ++)
			{
				inputCopy[i].va.position = matrix.transformVector(inputCopy[i].va.position);
				inputCopy[i].vb.position = matrix.transformVector(inputCopy[i].vb.position);
				inputCopy[i].vc.position = matrix.transformVector(inputCopy[i].vc.position);
			}
			var outputTriangles:Vector.<Triangle> = CalculateCulling.frustumCutTriangles(camera.frustum, inputCopy);
//			trace(outputTriangles.length);
			
			//calcualte triangle projection.
			var vertices:Vector.<Number> = new Vector.<Number>();
			var uvtData:Vector.<Number> = new Vector.<Number>();
			for(i = 0; i < outputTriangles.length; i ++)
			{
				vertices.push(
					camera.focalLength / outputTriangles[i].va.position.z * outputTriangles[i].va.position.x, 
					camera.focalLength / outputTriangles[i].va.position.z * outputTriangles[i].va.position.y, 
					camera.focalLength / outputTriangles[i].vb.position.z * outputTriangles[i].vb.position.x, 
					camera.focalLength / outputTriangles[i].vb.position.z * outputTriangles[i].vb.position.y, 
					camera.focalLength / outputTriangles[i].vc.position.z * outputTriangles[i].vc.position.x, 
					camera.focalLength / outputTriangles[i].vc.position.z * outputTriangles[i].vc.position.y
				);
				uvtData.push(
					outputTriangles[i].va.uv.x, outputTriangles[i].va.uv.y, camera.focalLength / outputTriangles[i].va.position.z, 
					outputTriangles[i].vb.uv.x, outputTriangles[i].vb.uv.y, camera.focalLength / outputTriangles[i].vb.position.z, 
					outputTriangles[i].vc.uv.x, outputTriangles[i].vc.uv.y, camera.focalLength / outputTriangles[i].vc.position.z
				);
			}
			
			//draw triangles.
			canvas.graphics.clear();
//			canvas.graphics.lineStyle(1, 0x000000, 1);
			canvas.graphics.beginBitmapFill(bmd, null, true, true);
			canvas.graphics.drawTriangles(vertices, null, uvtData, TriangleCulling.POSITIVE);
			canvas.graphics.endFill();
		}
		
		private function dispose():void
		{
			if(bmd)
			{
				bmd.dispose();
				bmd = null;
			}
			if(scene)
			{
				scene.dispose();
				scene = null;
			}
			if(camera)
			{
				camera.dispose();
				camera = null;
			}
			if(canvas)
			{
				if(canvas.parent && canvas.parent == this)
					removeChild(canvas);
				canvas = null;
			}
			if(frustum)
				frustum = null;
			if(inputTriangles)
				inputTriangles.length = 0;
			if(oldPoint)
				oldPoint = null;
			if(newPoint)
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
		
		//重置按钮
		[Embed(source="/panorama/assets/images/newui/reset-normal.png", mimeType="image/png")]
		private var reset_default:Class;
		[Embed(source="/panorama/assets/images/newui/reset-hover.png", mimeType="image/png")]
		private var reset_over:Class;
		private var resetBTN:EasyButton;
		//下
		[Embed(source="/panorama/assets/images/newui/arrow-down-normal.png", mimeType="image/png")]
		private var down_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-down-hover.png", mimeType="image/png")]
		private var down_over:Class;
		private var downBTN:EasyButton;
		//上
		[Embed(source="/panorama/assets/images/newui/arrow-up-normal.png", mimeType="image/png")]
		private var up_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-up-hover.png", mimeType="image/png")]
		private var up_over:Class;
		private var upBTN:EasyButton;
		//左
		[Embed(source="/panorama/assets/images/newui/arrow-left-normal.png", mimeType="image/png")]
		private var left_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-left-hover.png", mimeType="image/png")]
		private var left_over:Class;
		private var leftBTN:EasyButton;
		//右
		[Embed(source="/panorama/assets/images/newui/arrow-right-normal.png", mimeType="image/png")]
		private var right_default:Class;
		[Embed(source="/panorama/assets/images/newui/arrow-right-hover.png", mimeType="image/png")]
		private var right_over:Class;
		private var rightBTN:EasyButton;
		//推
		[Embed(source="/panorama/assets/images/newui/zoom-in-normal.png", mimeType="image/png")]
		private var zoomin_default:Class;
		[Embed(source="/panorama/assets/images/newui/zoom-in-hover.png", mimeType="image/png")]
		private var zoomin_over:Class;
		private var zoominBTN:EasyButton;
		//拉
		[Embed(source="/panorama/assets/images/newui/zoom-out-normal.png", mimeType="image/png")]
		private var zoomout_default:Class;
		[Embed(source="/panorama/assets/images/newui/zoom-out-hover.png", mimeType="image/png")]
		private var zoomout_over:Class;
		private var zoomoutBTN:EasyButton;
		//购买
		[Embed(source="/panorama/assets/images/newui/shopping-normal.png", mimeType="image/png")]
		private var purchase_default:Class;
		[Embed(source="/panorama/assets/images/newui/shopping-hover.png", mimeType="image/png")]
		private var purchase_over:Class;
		private var purchaseBTN:EasyButton;
		//线
		[Embed(source="/panorama/assets/images/newui/line-1px.png", mimeType="image/png")]
		private var line_1px:Class;
		[Embed(source="/panorama/assets/images/newui/line-2px.png", mimeType="image/png")]
		private var line_2px:Class;
		//爱福窝logo
		[Embed(source="/panorama/assets/images/newui/logo.png", mimeType="image/png")]
		private var logo_default:Class;
		//品牌logo
		[Embed(source="/panorama/assets/multiroom/brandlogo-normal.png", mimeType="image/png")]
		private var brand_logo_default:Class;
		//工具栏背景
		[Embed(source="/panorama/assets/images/newui2/bg-misu-normal.jpg", mimeType="image/jpeg")]
		private var bg_default:Class;
		//播放
		[Embed(source="/panorama/assets/images/newui2/play-normal.png", mimeType="image/png")]
		private var play_default:Class;
		[Embed(source="/panorama/assets/images/newui2/play-hover.png", mimeType="image/png")]
		private var play_over:Class;
		private var playBTN:EasyButton;
		
		private var toolbar:Sprite;
		private var logo:Sprite;
		
		private function initLoadingPage():void
		{
			var bg:Bitmap = new bg_default() as Bitmap;
			bg.smoothing = true;
			addChild(bg);
			var scale:Number = Math.max(stage.stageWidth * 1.0 / bg.width, stage.stageHeight * 1.0 / bg.height);
			bg.x = -(bg.width * scale - stage.stageWidth) / 2;
			bg.scaleX = bg.scaleY = scale;
			
			playBTN = new EasyButton(new play_default(), new play_over(), new play_default());
			addChild(playBTN);
			playBTN.x = 528 * scale + bg.x;
			playBTN.y = 300 * scale;
			playBTN.scaleX = playBTN.scaleY = scale;
			
			playBTN.addEventListener(MouseEvent.CLICK, function onPlayClick(evt:MouseEvent):void
			{
				loadingFlower = new LoadingFlower();
				loadingFlower.percentText = "0%";
				addChild(loadingFlower);
				loadingFlower.x = playBTN.x + playBTN.width / 2 - loadingFlower.width / 2 * scale;
				loadingFlower.y = playBTN.y + playBTN.height / 2 - loadingFlower.height / 2 * scale;
				loadingFlower.scaleX = loadingFlower.scaleY = scale;
				
				removeChild(playBTN);
				playBTN = null;
				
				var timer:Timer = new Timer(100, 10);
				timer.addEventListener(TimerEvent.TIMER, function onTimer(evt:TimerEvent):void
				{
					loadingFlower.percentTF.text = int(timer.currentCount * 1.0 / timer.repeatCount * 100).toString() + "%";
					if (timer.currentCount == timer.repeatCount)
					{
						removeChild(bg);
						bg_default = null;
						removeChild(loadingFlower);
						loadingFlower = null;
						
						initScene();
						initBehavior();
						initUI();
					}
				});
				timer.start();
			});
		}
		
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
			//purchaseBTN.visible = false;
			logo = new Sprite(); logo.addChild(new logo_default());
			addChild(new brand_logo_default());
			
			resetBTN.addEventListener(MouseEvent.CLICK, onResetClick);
			downBTN.addEventListener(MouseEvent.CLICK, onDownClick);
			upBTN.addEventListener(MouseEvent.CLICK, onUpClick);
			leftBTN.addEventListener(MouseEvent.CLICK, onLeftClick);
			rightBTN.addEventListener(MouseEvent.CLICK, onRightClick);
			zoominBTN.addEventListener(MouseEvent.CLICK, onZoomInClick);
			zoomoutBTN.addEventListener(MouseEvent.CLICK, onZoomOutClick);
			purchaseBTN.addEventListener(MouseEvent.CLICK, onPurchaseClick);
			//logo.addEventListener(MouseEvent.CLICK, onLogoClick); logo.buttonMode = true;
			
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
			//addChild(purchaseBTN);
			addChild(logo);
			
			onResize(null);
			
//			toolbar.addEventListener(MouseEvent.MOUSE_OUT, onToolbarMouseOut);
//			toolbar.addEventListener(MouseEvent.MOUSE_OVER, onToolbarMouseOver);
		}
		private function onResetClick(evt:MouseEvent):void
		{
			scene.rotationX = 0;
			scene.rotationY = initRotationY;
			speedX = 0;
			speedY = 0;
			autoRotate = true;
		}
		private function onDownClick(evt:MouseEvent):void
		{
			scene.rotationX += 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedX = 1.0 / 180 * Math.PI;
		}
		private function onUpClick(evt:MouseEvent):void
		{
			scene.rotationX -= 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedX = -1.0 / 180 * Math.PI;
		}
		private function onLeftClick(evt:MouseEvent):void
		{
			scene.rotationY += 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedY = 1.0 / 180 * Math.PI;
		}
		private function onRightClick(evt:MouseEvent):void
		{
			scene.rotationY -= 4.0 / 180 * Math.PI;
			autoRotate = false;
			speedY = -1.0 / 180 * Math.PI;
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
