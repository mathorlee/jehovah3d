package panorama
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.TriangleCulling;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flashas3.flvplay.TvPosition;
	import flashas3.flvplay.VideoTexture;
	import panorama.culling.CalculateCulling;
	import panorama.culling.Frustum;
	import panorama.geometry.Triangle;
	import panorama.geometry.Vertex;
	
	import utils.easybutton.EasyButton;
	
	public class Panorama extends Sprite
	{
		public static const FOV_CHANGE:String = "FovChange";
		
		public var bmd:BitmapData; //由外部传入
		
		public var canvasWidth:Number = 100;
		public var canvasHeight:Number = 100;
		public var scene:Object3D;
		public var camera:Camera3D;
		private var canvas:Sprite;
		private var frustum:Frustum;	
		private var inputTriangles:Vector.<Triangle>;
		
		/**
		 * 电视四个顶点位置 
		 */		
		public var tvPoints: Vector.<Point>;
		/**
		 * 电视视频地址 
		 */		
		public var flvUrl:String = "assets/test.flv";
		//视频容器
		private var flvCanvas:Sprite;
		//视频三角形
		private var flvInputTriangles:Vector.<Triangle>;
		private var tvposition:TvPosition;
		private var flvTexture:VideoTexture;
		//视频位图
		private var flvBitmapData:BitmapData;
		
		private var oldPoint:Point = new Point();
		private var newPoint:Point = new Point();
		
		private var initRotationY:Number = 0;
		private var speedX:Number = 0;
		private var speedY:Number = 0;
		private var useSpeed:Boolean = true;
		public var autoRotate:Boolean = true;
		private var autoRotateSpeed:Number = 0.0025;
		public var maxFov:Number = 0.7;
		public var minFov:Number = 0.5;
		public var defaultFov:Number = 0.6;
		
		public function Panorama(toolBarVisible:Boolean=true)
		{
			initScene();
			initBehavior();
			initUI(toolBarVisible);
			initFlv();
		}
		
		public function onResize(evt:Event):void
		{
			if(canvasWidth > 0 && canvasHeight > 0)
			{
				if(camera)
				{
					camera.viewWidth = canvasWidth;
					camera.viewHeight = canvasHeight;
				}
				if(canvas)
				{
					canvas.x = canvasWidth * 0.5;
					canvas.y = canvasHeight * 0.5;
				}
				if(flvCanvas)			
				{
					flvCanvas.x = canvasWidth * 0.5;
					flvCanvas.y = canvasHeight * 0.5;
				}
				
				if(toolbar)
				{
					toolbar.x = (canvasWidth - toolbar.width) * 0.5;
					toolbar.y = canvasHeight - toolbar.height;
				}
				if(purchaseBTN)
				{
					purchaseBTN.x = canvasWidth - purchaseBTN.width;
					purchaseBTN.y = canvasHeight - purchaseBTN.height;
				}
				if(logo)
				{
					logo.x = 0;
					logo.y = canvasHeight - logo.height;
				}
				if(toolbarBg)
				{
					toolbarBg.x = 0;
					toolbarBg.y = canvasHeight - toolbarBg.height;
					toolbarBg.width = canvasWidth;
				}
				if(foldButton)		
				{
					foldButton.x = canvasWidth-foldButton.width;
					foldButton.y = canvasHeight - foldButton.height;
					unfoldButton.x = canvasWidth-unfoldButton.width;
					unfoldButton.y = canvasHeight - unfoldButton.height;
				}
			}
		}
		
		private function initScene():void
		{
			scene = new Object3D();
//			scene.rotationY = Math.PI * 0.75;
			camera = new Camera3D(Math.PI * defaultFov, canvasWidth, canvasHeight);
			camera.z = 0;
			
			canvas = new Sprite();
			addChild(canvas);
			this.flvCanvas = new Sprite();
			this.addChild(this.flvCanvas);
			onResize(null);
			
			inputTriangles = new Vector.<Triangle>();
			var u0:Number = 2.0 / 1540;
			var u1:Number = 514.0 / 1540;
			var u2:Number = 1026.0 / 1540;
			var u3:Number = 1538 / 1540;
			var v1:Number = 0.25;
			var v2:Number = 0.5;
			var v3:Number = 0.75;
			//back
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, -100, 100), new Point(u2, v1)), 
				new Vertex(new Vector3D(-100, -100, 100), new Point(u1, v1)), 
				new Vertex(new Vector3D(-100, 100, 100), new Point(u1, v2))
			));
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, -100, 100), new Point(u2, v1)), 
				new Vertex(new Vector3D(-100, 100, 100), new Point(u1, v2)), 
				new Vertex(new Vector3D(100, 100, 100), new Point(u2, v2))
			));
			//front
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(-100, -100, -100), new Point(u1, 1)), 
				new Vertex(new Vector3D(100, -100, -100), new Point(u2, 1)), 
				new Vertex(new Vector3D(100, 100, -100), new Point(u2, v3))
			));
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(-100, -100, -100), new Point(u1, 1)), 
				new Vertex(new Vector3D(100, 100, -100), new Point(u2, v3)), 
				new Vertex(new Vector3D(-100, 100, -100), new Point(u1, v3))
			));
			
			//left
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(-100, -100, 100), new Point(u1, v1)), 
				new Vertex(new Vector3D(-100, -100, -100), new Point(u0, v1)), 
				new Vertex(new Vector3D(-100, 100, -100), new Point(u0, v2))
			));
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(-100, -100, 100), new Point(u1, v1)), 
				new Vertex(new Vector3D(-100, 100, -100), new Point(u0, v2)), 
				new Vertex(new Vector3D(-100, 100, 100), new Point(u1, v2))
			));
			//right
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, -100, -100), new Point(u3, v1)), 
				new Vertex(new Vector3D(100, -100, 100), new Point(u2, v1)), 
				new Vertex(new Vector3D(100, 100, 100), new Point(u2, v2))
			));
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, -100, -100), new Point(u3, v1)), 
				new Vertex(new Vector3D(100, 100, 100), new Point(u2, v2)), 
				new Vertex(new Vector3D(100, 100, -100), new Point(u3, v2))
			));
			//top
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, -100, -100), new Point(u2, 0)), 
				new Vertex(new Vector3D(-100, -100, -100), new Point(u1, 0)), 
				new Vertex(new Vector3D(-100, -100, 100), new Point(u1, v1))
			));
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, -100, -100), new Point(u2, 0)), 
				new Vertex(new Vector3D(-100, -100, 100), new Point(u1, v1)), 
				new Vertex(new Vector3D(100, -100, 100), new Point(u2, v1))
			));
			//bottom
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, 100, 100), new Point(u2, v2)), 
				new Vertex(new Vector3D(-100, 100, 100), new Point(u1, v2)), 
				new Vertex(new Vector3D(-100, 100, -100), new Point(u1, v3))
			));
			inputTriangles.push(new Triangle(
				new Vertex(new Vector3D(100, 100, 100), new Point(u2, v2)), 
				new Vertex(new Vector3D(-100, 100, -100), new Point(u1, v3)), 
				new Vertex(new Vector3D(100, 100, -100), new Point(u2, v3))
			));
			
			initFlvScence();
		}
		
		/*初始化电视面板*/
		private function initFlvScence():void
		{
			if(tvPoints==null)
			{
				//test used
				tvPoints = new Vector.<Point>();
				tvPoints.push(new Point(1369,696));
				tvPoints.push(new Point(1178,696));
				tvPoints.push(new Point(1178,796));
				tvPoints.push(new Point(1369,796));
			}
			tvposition = new TvPosition(tvPoints);
			this.flvInputTriangles = tvposition.tvInputTriangles;
		}
		
		private function initBehavior():void
		{
//			canvas.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			canvas.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			canvas.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			canvas.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			flvCanvas.buttonMode = true;
			flvCanvas.addEventListener(MouseEvent.CLICK,omMouseClick);
			flvCanvas.addEventListener(MouseEvent.MOUSE_OVER, onFlvMouseOver);
			flvCanvas.addEventListener(MouseEvent.MOUSE_OUT, onFlvMouseOut);
			flvCanvas.addEventListener(MouseEvent.MOUSE_MOVE, onFlvMouseMove);
		}
		
		/*初始化加载视频*/
		private function initFlv():void
		{
			this.flvTexture = new VideoTexture(this.flvUrl,true,true);
			this.flvBitmapData = this.flvTexture.bitmapData;
		}
		
		private function onMouseWheel(evt:MouseEvent):void
		{
			if(evt.delta > 0)
				camera.fov -= 0.1;
			else
				camera.fov += 0.1;
			if(camera.fov > Math.PI * maxFov)
				camera.fov = Math.PI * maxFov;
			if(camera.fov < Math.PI * minFov)
				camera.fov = Math.PI * minFov;
			dispatchEvent(new Event(FOV_CHANGE, false, false));
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			canvas.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			canvas.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			canvas.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			oldPoint.x = evt.localX;
			oldPoint.y = evt.localY;
//			autoRotate = false;
		}
		
		/**
		 * 
		 * 视频是否显示 
		 * @param bmdInt
		 * 
		 */		
		public function flvDisplay(bmdInt:int):void
		{
			if(bmdInt!=0)
			{
				if(this.flvTexture)
				{
					this.flvTexture.autoUpdate = false;
					this.flvTexture.player.flvPause();
					this.flvCanvas.visible = false;
				}
			}else
			{
				if(this.flvTexture)
				{
//					this.flvTexture.player.flvBack();
					this.flvTexture.player.flvPlay();
					this.flvTexture.autoUpdate = true;
					this.flvCanvas.visible = true;
				}
			}		
		}
		
		private function omMouseClick(evt:MouseEvent):void
		{
			evt.stopImmediatePropagation();
			if(this.flvTexture.player.playing)
			{
				this.flvTexture.player.paused = true;
				this.txt.text = "点击播放";
			}
			else
			{
				this.flvTexture.player.playing = true;
				this.txt.text = "点击停止";
			}	
		}
		
		private function onFlvMouseOver(evt:MouseEvent):void
		{
			evt.stopImmediatePropagation();
//			this.txt.visible = true;
			if(this.flvTexture.player.playing)
				this.txt.text = "点击停止";	
			else if(this.flvTexture.player.paused)
				this.txt.text = "点击播放";
			var pt:Point = localToGlobal(new Point(evt.localX,evt.localY));
			this.txt.x = pt.x + canvasWidth * 0.5-10; 
			this.txt.y = pt.y + canvasHeight * 0.5 -20;
		}
		
		private function onFlvMouseMove(evt:MouseEvent):void
		{
			evt.stopImmediatePropagation();
			var pt:Point = localToGlobal(new Point(evt.localX,evt.localY));
			this.txt.x = pt.x + canvasWidth * 0.5-10; 
			this.txt.y = pt.y + canvasHeight * 0.5 -20;
		}
		
		private function onFlvMouseOut(evt:MouseEvent):void
		{
			evt.stopImmediatePropagation();
			this.txt.visible = false;
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
			autoRotate = false;
			newPoint.x = evt.localX;
			newPoint.y = evt.localY;
			
			scene.rotationX += (newPoint.y - oldPoint.y) / 200;
			scene.rotationY -= (newPoint.x - oldPoint.x) / 200;
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		
		private function onMouseUp(evt:MouseEvent):void
		{
			autoRotate = true;
			if(canvas.hasEventListener(MouseEvent.MOUSE_MOVE))
				canvas.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if(canvas.hasEventListener(MouseEvent.MOUSE_UP))
				canvas.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(canvas.hasEventListener(MouseEvent.MOUSE_OUT))
				canvas.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
		}
		
		public function render():void
		{
			if(!bmd)
				return ;
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
			
			/*渲染tv面板*/
			var t:int;
			var tvinputCopy:Vector.<Triangle> = new Vector.<Triangle>();
			for(t = 0; t < flvInputTriangles.length; t ++)
				tvinputCopy.push(flvInputTriangles[t].clone());
			for(t = 0; t < tvinputCopy.length; t ++)
			{
				tvinputCopy[t].va.position = matrix.transformVector(tvinputCopy[t].va.position);
				tvinputCopy[t].vb.position = matrix.transformVector(tvinputCopy[t].vb.position);
				tvinputCopy[t].vc.position = matrix.transformVector(tvinputCopy[t].vc.position);
			}
			var tvoutputTriangles:Vector.<Triangle> = CalculateCulling.frustumCutTriangles(camera.frustum, tvinputCopy);
			
			var tvvertices:Vector.<Number> = new Vector.<Number>();
			var tvuvtData:Vector.<Number> = new Vector.<Number>();
			for(t = 0; t < tvoutputTriangles.length; t ++)
			{
				tvvertices.push(
					camera.focalLength / tvoutputTriangles[t].va.position.z * tvoutputTriangles[t].va.position.x, 
					camera.focalLength / tvoutputTriangles[t].va.position.z * tvoutputTriangles[t].va.position.y, 
					camera.focalLength / tvoutputTriangles[t].vb.position.z * tvoutputTriangles[t].vb.position.x, 
					camera.focalLength / tvoutputTriangles[t].vb.position.z * tvoutputTriangles[t].vb.position.y, 
					camera.focalLength / tvoutputTriangles[t].vc.position.z * tvoutputTriangles[t].vc.position.x, 
					camera.focalLength / tvoutputTriangles[t].vc.position.z * tvoutputTriangles[t].vc.position.y
				);
				tvuvtData.push(
					tvoutputTriangles[t].va.uv.x, tvoutputTriangles[t].va.uv.y, camera.focalLength / tvoutputTriangles[t].va.position.z, 
					tvoutputTriangles[t].vb.uv.x, tvoutputTriangles[t].vb.uv.y, camera.focalLength / tvoutputTriangles[t].vb.position.z, 
					tvoutputTriangles[t].vc.uv.x, tvoutputTriangles[t].vc.uv.y, camera.focalLength / tvoutputTriangles[t].vc.position.z
				);
			}
			if(flvCanvas!=null)
			{
				flvCanvas.graphics.clear();
				flvCanvas.graphics.beginBitmapFill(this.flvBitmapData, null, true, true);
				flvCanvas.graphics.drawTriangles(tvvertices, null, tvuvtData, TriangleCulling.POSITIVE);
				flvCanvas.graphics.endFill();
			}
		}
		
		
		[Embed(source="../assets/newui/reset-normal.png", mimeType="image/png")]
		private var reset_default:Class;
		[Embed(source="../assets/newui/reset-hover.png", mimeType="image/png")]
		private var reset_over:Class;
		private var resetBTN:EasyButton;
		
		[Embed(source="../assets/newui/arrow-down-normal.png", mimeType="image/png")]
		private var down_default:Class;
		[Embed(source="../assets/newui/arrow-down-hover.png", mimeType="image/png")]
		private var down_over:Class;
		private var downBTN:EasyButton;
		
		[Embed(source="../assets/newui/arrow-up-normal.png", mimeType="image/png")]
		private var up_default:Class;
		[Embed(source="../assets/newui/arrow-up-hover.png", mimeType="image/png")]
		private var up_over:Class;
		private var upBTN:EasyButton;
		
		[Embed(source="../assets/newui/arrow-left-normal.png", mimeType="image/png")]
		private var left_default:Class;
		[Embed(source="../assets/newui/arrow-left-hover.png", mimeType="image/png")]
		private var left_over:Class;
		private var leftBTN:EasyButton;
		
		[Embed(source="../assets/newui/arrow-right-normal.png", mimeType="image/png")]
		private var right_default:Class;
		[Embed(source="../assets/newui/arrow-right-hover.png", mimeType="image/png")]
		private var right_over:Class;
		private var rightBTN:EasyButton;
		
		[Embed(source="../assets/newui/zoom-in-normal.png", mimeType="image/png")]
		private var zoomin_default:Class;
		[Embed(source="../assets/newui/zoom-in-hover.png", mimeType="image/png")]
		private var zoomin_over:Class;
		private var zoominBTN:EasyButton;
		
		[Embed(source="../assets/newui/zoom-out-normal.png", mimeType="image/png")]
		private var zoomout_default:Class;
		[Embed(source="../assets/newui/zoom-out-hover.png", mimeType="image/png")]
		private var zoomout_over:Class;
		private var zoomoutBTN:EasyButton;
		
		[Embed(source="../assets/newui/shopping-normal.png", mimeType="image/png")]
		private var purchase_default:Class;
		[Embed(source="../assets/newui/shopping-hover.png", mimeType="image/png")]
		private var purchase_over:Class;
		private var purchaseBTN:EasyButton;
		
		[Embed(source="../assets/newui/line-1px.png", mimeType="image/png")]
		private var line_1px:Class;
		[Embed(source="../assets/newui/line-2px.png", mimeType="image/png")]
		private var line_2px:Class;
		
		[Embed(source="../assets/newui/logo.png", mimeType="image/png")]
		private var logo_default:Class;
		
		[Embed(source="../assets/newui/bannerBg.png", mimeType="image/png")]
		private var toolbar_default:Class;
		
		[Embed(source="../assets/newui/fold-normal.png", mimeType="image/png")]
		private var fold_default:Class;
		[Embed(source="../assets/newui/fold-hover.png", mimeType="image/png")]
		private var fold_over:Class;
		private var foldButton:EasyButton;
		
		[Embed(source="../assets/newui/unfold-normal.png", mimeType="image/png")]
		private var unfold_default:Class;
		[Embed(source="../assets/newui/unfold-hover.png", mimeType="image/png")]
		private var unfold_over:Class;
		private var unfoldButton:EasyButton;
		
		private var toolbar:Sprite;
		private var logo:Sprite;
		private var toolbarBg:Sprite;
		private var txt:TextField;
		
		private function initUI(toolBarVisible:Boolean=true):void
		{
			toolbarBg = new Sprite();
			toolbarBg.addChild(new toolbar_default());
			toolbarBg.visible = toolBarVisible;
			addChild(toolbarBg);
			toolbar = new Sprite();
			toolbar.visible = toolBarVisible;
			addChild(toolbar);
			setFlvTipUI();
			
			resetBTN = new EasyButton(new reset_default(), new reset_over(), new reset_default());
			downBTN = new EasyButton(new down_default(), new down_over(), new down_default());
			upBTN = new EasyButton(new up_default(), new up_over(), new up_default());
			leftBTN = new EasyButton(new left_default(), new left_over(), new left_default());
			rightBTN = new EasyButton(new right_default(), new right_over(), new right_default());
			zoominBTN = new EasyButton(new zoomin_default(), new zoomin_over(), new zoomin_default());
			zoomoutBTN = new EasyButton(new zoomout_default(), new zoomout_over(), new zoomout_default());
			purchaseBTN = new EasyButton(new purchase_default(), new purchase_over(), new purchase_default());
			foldButton = new EasyButton(new fold_default(), new fold_over(), new fold_default());
			unfoldButton = new EasyButton(new unfold_default(), new unfold_over(), new unfold_default());
			
			logo = new Sprite();
//			logo.addChild(new logo_default());
			
			resetBTN.addEventListener(MouseEvent.CLICK, onResetClick);
			downBTN.addEventListener(MouseEvent.CLICK, onDownClick);
			upBTN.addEventListener(MouseEvent.CLICK, onUpClick);
			leftBTN.addEventListener(MouseEvent.CLICK, onLeftClick);
			rightBTN.addEventListener(MouseEvent.CLICK, onRightClick);
			zoominBTN.addEventListener(MouseEvent.CLICK, onZoomInClick);
			zoomoutBTN.addEventListener(MouseEvent.CLICK, onZoomOutClick);
			purchaseBTN.addEventListener(MouseEvent.CLICK, onPurchaseClick);
			foldButton.addEventListener(MouseEvent.CLICK, onfoldButtonClick);
			unfoldButton.addEventListener(MouseEvent.CLICK, onunfoldButtonClick);
			logo.addEventListener(MouseEvent.CLICK, onLogoClick); logo.buttonMode = true;
			
			var tmp:Number = 0;

			toolbar.addChild(leftBTN); leftBTN.x = tmp; tmp += leftBTN.width;
			toolbar.addChild(rightBTN); rightBTN.x = tmp; tmp += rightBTN.width;
			toolbar.addChild(upBTN); upBTN.x = tmp; tmp += upBTN.width;
			toolbar.addChild(downBTN); downBTN.x = tmp; tmp += downBTN.width;
			toolbar.addChild(zoominBTN); zoominBTN.x = tmp; tmp += zoominBTN.width;
			toolbar.addChild(zoomoutBTN); zoomoutBTN.x = tmp; tmp += zoomoutBTN.width;
			toolbar.addChild(resetBTN); resetBTN.x = tmp; tmp += resetBTN.width;
//			addChild(purchaseBTN);
			addChild(logo);
			
			foldButton.visible = toolBarVisible;
			unfoldButton.visible = !toolBarVisible;
			addChild(unfoldButton);
			addChild(foldButton);
			onResize(null);
		}
		
		//视频点击tip
		private function setFlvTipUI():void
		{
			txt = new TextField();
			txt.text = "点击停止";
			txt.selectable = false;
			addChild(txt);
			txt.filters = [new DropShadowFilter(2,45,0x000000,1,4,4)];
			txt.visible = false;
			var txtFormat:TextFormat = new TextFormat();
			txtFormat.size = 40;
			txtFormat.color = 0xffffff;
			txt.setTextFormat(txtFormat);
		}
		
		private function onResetClick(evt:MouseEvent):void
		{
			scene.rotationX = 0;
			scene.rotationY = initRotationY;
			speedX = 0;
			speedY = 0;
			autoRotate = true;
			camera.fov = Math.PI * defaultFov;
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
			if(camera.fov > Math.PI * maxFov)
				camera.fov = Math.PI * maxFov;
			if(camera.fov < Math.PI * minFov)
				camera.fov = Math.PI * minFov;
		}
		private function onZoomOutClick(evt:MouseEvent):void
		{
			camera.fov += 0.1;
			if(camera.fov > Math.PI * maxFov)
				camera.fov = Math.PI * maxFov;
			if(camera.fov < Math.PI * minFov)
				camera.fov = Math.PI * minFov;
		}
		private function onPurchaseClick(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://www.fuwo.com"), "_blank");
		}
		private function onLogoClick(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://fuwu.taobao.com/ser/detail.htm?spm=a1z13.1113643.1113643.15.wCDzlW&service_code=FW_GOODS-1868472&tracelog=search&scm=&ppath=&labels="), "_blank");
		}
		
		private function onfoldButtonClick(evt:MouseEvent):void
		{
			foldButton.visible = false;
			unfoldButton.visible = true;
			toolbar.visible = false;
			toolbarBg.visible = false;
		}
		
		private function onunfoldButtonClick(evt:MouseEvent):void
		{
			foldButton.visible = true;
			unfoldButton.visible = false;
			toolbar.visible = true;
			toolbarBg.visible = true;
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

