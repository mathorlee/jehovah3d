package panorama
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display.TriangleCulling;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import panorama.culling.CalculateCulling;
	import panorama.culling.Frustum;
	import panorama.geometry.Triangle;
	import panorama.geometry.Vertex;
	
	import utils.loadingbar.LoadingBar;
	
	public class Panorama extends Sprite
	{
		private var loader:Loader = new Loader();
		private var loadingBar:LoadingBar;
		//private var arrow:ArrowMC;
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
		
		public function Panorama()
		{
			getURLParameter();
			if(stage)
				onAdded();
			else
				addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function getURLParameter():void
		{
			var obj:Object = loaderInfo.parameters;
			if (obj.hasOwnProperty("imageURL"))
				imageURL = obj.imageURL;
			else
				imageURL = "http://www.fuwo.com/static/ifuwo/phoenix/phoenix/assets/images/overview_demo.jpg";
			
			if(obj.hasOwnProperty("canvasWidth"))
				canvasWidth = obj.canvasWidth;
			else
				canvasWidth = 600;
			
			if(obj.hasOwnProperty("canvasHeight"))
				canvasHeight = obj.canvasHeight;
			else
				canvasHeight = 512;
		}
		
		private function onAdded(evt:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			addEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			Mouse.cursor = MouseCursor.HAND;
			initScene();
			loadTexture();
		}
		
		private function onRemove(evt:Event):void
		{
			if(hasEventListener(Event.REMOVED_FROM_STAGE))
				removeEventListener(Event.REMOVED_FROM_STAGE, onRemove);
			if(hasEventListener(Event.ENTER_FRAME))
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			removeEventListener(Event.ENTER_FRAME, autoRotation);
			
			if(canvas.hasEventListener(MouseEvent.MOUSE_WHEEL))
				canvas.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			if(canvas.hasEventListener(MouseEvent.MOUSE_DOWN))
				canvas.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			
			if(canvas.hasEventListener(MouseEvent.MOUSE_OVER))
				canvas.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			if(canvas.hasEventListener(MouseEvent.MOUSE_OUT))
				canvas.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			dispose();
		}
		
		private function loadTexture():void
		{
			loadingBar = new LoadingBar();
			addChild(loadingBar);
			loadingBar.x = int(canvasWidth * 0.5);
			loadingBar.y = int(canvasHeight * 0.5);
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.load(new URLRequest(imageURL), new LoaderContext(true));
//			loader.load(new URLRequest("http://www.emptywhite.com/bulkloader-assets/shoes.jpg"));
		}
		
		private function onComplete(evt:Event):void
		{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onComplete);
			loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
//			bmd = Bitmap(loader.contentLoaderInfo.content).bitmapData;
			bmd = handleBoxPanoramaBitmapData(Bitmap(loader.contentLoaderInfo.content).bitmapData, 512, 2);
			
			removeChild(loadingBar);
			loadingBar = null;
			
			/*if (canvasWidth > 350)
			{
				this.arrow = new ArrowMC();
				this.arrow.x = int(canvasWidth * 0.5);
				this.arrow.y = int(canvasHeight * 0.5);
				this.arrow.alpha = 0.3;
				addChild(this.arrow);
			}*/
			
			initBehavior();
		}
		private function onProgress(evt:ProgressEvent):void
		{
			loadingBar.percent = evt.bytesLoaded / evt.bytesTotal;
		}
		private function onError(evt:IOErrorEvent):void
		{
			//trace(evt.errorID);
		}
		/*private function showArrow():void
		{
			if (this.arrow)
				this.arrow.visible = true;
		}
		private function hideArrow():void
		{
			if (this.arrow)
				this.arrow.visible = false;
		}*/
		
		private function initScene():void
		{
			scene = new Object3D();
			camera = new Camera3D(Math.PI * 0.5, canvasWidth, canvasHeight);
			camera.z = 0;
			
			canvas = new Sprite();
			addChild(canvas);
			canvas.x = canvasWidth * 0.5;
			canvas.y = canvasHeight * 0.5;
			
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
		}
		
		private function initBehavior():void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			canvas.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			canvas.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			canvas.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			canvas.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			
			addEventListener(Event.ENTER_FRAME, autoRotation);
		}
		
		private function onEnterFrame(evt:Event):void
		{
			render();
		}
		/**
		 * 自动旋转
		 */
		private function autoRotation(evt:Event):void
		{
			scene.rotationY -= 0.006;
		}
		
		private function onMouseWheel(evt:MouseEvent):void
		{
			if(evt.delta > 0)
				camera.fov -= 0.1;
			else
				camera.fov += 0.1;
			if(camera.fov > Math.PI * 0.6)
				camera.fov = Math.PI * 0.6;
			if(camera.fov < Math.PI * 0.25)
				camera.fov = Math.PI * 0.25;
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			canvas.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			canvas.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			canvas.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			oldPoint.x = evt.localX;
			oldPoint.y = evt.localY;
		}
		
		private function onMouseOver(evt:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.HAND;
			removeEventListener(Event.ENTER_FRAME, autoRotation);
			//this.hideArrow();
		}
		
		private function onMouseOut(evt:MouseEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
			addEventListener(Event.ENTER_FRAME, autoRotation);
			//this.showArrow();
		}
		
		private function onMouseMove(evt:MouseEvent):void
		{
			newPoint.x = evt.localX;
			newPoint.y = evt.localY;
			
			scene.rotationX += (newPoint.y - oldPoint.y) / 200;
			scene.rotationY -= (newPoint.x - oldPoint.x) / 200;
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		
		private function onMouseUp(evt:MouseEvent):void
		{
			if(canvas.hasEventListener(MouseEvent.MOUSE_MOVE))
				canvas.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if(canvas.hasEventListener(MouseEvent.MOUSE_UP))
				canvas.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(canvas.hasEventListener(MouseEvent.MOUSE_OUT))
				canvas.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
		}
		
		private function render():void
		{
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
			if(loader)
			{
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onComplete);
				loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onError);
				loader = null;
			}
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
		
		private function handleBoxPanoramaBitmapData(source:BitmapData, size:int, expand:int):BitmapData
		{
			var ret:BitmapData = new BitmapData(source.width + expand * 2, source.height, source.transparent);
			ret.copyPixels(source, new Rectangle(0, 0, source.width, source.height), new Point(expand, 0)); //第1次拷贝，大区域。
			
			var t0:BitmapData = new BitmapData(expand, size + expand, false);
			t0.copyPixels(source, new Rectangle(size - expand, size * 3 - expand, t0.width, t0.height), new Point());
			var t1:BitmapData = rotateBitmapDataByPI(t0);
			ret.copyPixels(t1, new Rectangle(0, 0, t1.width, t1.height), new Point(0, size)); //第2次拷贝，左侧的细长条。
			
			var t2:BitmapData = new BitmapData(expand, size + expand, false);
			t2.copyPixels(source, new Rectangle(size * 2, size * 3 - expand, t2.width, t2.height), new Point());
			var t3:BitmapData = rotateBitmapDataByPI(t2);
			ret.copyPixels(t3, new Rectangle(0, 0, t3.width, t3.height), new Point(size * 3 + expand, size)); //第3次拷贝，右侧的细长条。
			
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
	}
}

