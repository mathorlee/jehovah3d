package galaxy
{
	import com.adobe.images.JPGEncoder;
	import com.fuwo.math.MyMath;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.display3D.Context3DBlendFactor;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.utils.Dictionary;
	
	import jehovah3d.Jehovah;
	import jehovah3d.Scene3DTemplateForASProject;
	import jehovah3d.core.Bounding;
	import jehovah3d.core.Camera3D;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.background.BitmapTextureBG;
	import jehovah3d.core.light.FreeLight3D;
	import jehovah3d.core.light.Light3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Plane;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.renderer.SSAORenderer;
	import jehovah3d.core.resource.TextureResource;
	import jehovah3d.core.wireframe.WireFrame;
	import jehovah3d.parser.ParserFUWO3D;
	import jehovah3d.primitive.PrimitivePlane;
	import jehovah3d.util.AssetsManager;
	import jehovah3d.util.HexColor;
	
	import utils.TextHint;
	import utils.bulkloader.AdvancedLoader;
	import utils.bulkloader.BulkLoader;
	import utils.easybutton.EasyButton;
	import utils.easybutton.EasyButtonState;
	
	[SWF(frameRate="30", widthPercent="100%", heightPercent="100%")]
	public class LVD_06039 extends Scene3DTemplateForASProject
	{
		private const BACKGROUN_COLOR:uint = 0xFFFFFF;
		private const RULER_COLOR:uint = 0x333333;
		
		private var baseURL:String = "";
		private var host:String = "http://3dshow.flash.jaeapp.com/view/api/3dshow.php";
		private var id:String;
		private var language:String;
		private var preText:String;
		private var pressBarOrginWid:Number =402.4;
		private var pressTxtOrginWid:Number = 111;
		private var need_light:int;
		private var is_bottom:int;
		private var folder:String;
		private var use_mip:int;
		
		private var interaction:Object = [];
		private var textSequence:Array = new Array();
		private var inverseTextSequence:Array = new Array();
		private var instructionDict:Dictionary = new Dictionary();
		private var totalAnimationFrame:int;
		private var hasAnimation:Boolean = false; //是否有动画
		private var hasInstruction:Boolean = false; //是否有说明文字
		private var mouseDectiveHint:TextHint; //鼠标检测时的说明文字
		private var animationHint:TextHint; //动画时的说明文字
		private var totalHint:TextHint; //右上角的所有文字
		private var currentFrameIndex:int = int.MAX_VALUE;
		private var inverseAnimation:Boolean = false;
		
		private var bg_type:int;
		private var bg_color:String;
		private var bg_image:String;
		
		private var sceneContent:Object3D; //存储场景
		private var ruler:Object3D; //存储尺寸向相关
		private var sceneBG:Object3D; //存储_bg_
		public var obj3ds:Vector.<Object3D>;
		public var cubeTextureDict:Dictionary = new Dictionary();
		
		private var preview:Bitmap;
		private var play:MovieClip;
		private var bg:Sprite;
		/**
		 *相应版本语言 
		 */        	
		private var _assembleStep:String;
		private var _disassembleStep:String;
		private var _revolve:String;
		private var _move:String;
		private var _zoom:String;
		private var _reset:String;
		private var _assemble:String;
		private var _disassemble:String;
		private var _assembleOperater:String;
		private var _disassembleOperater:String;
		private var _glassPanel:String;
		private var _lampBracket:String;
		private var _electricalboxCover:String;
		private var _electricalbox:String;
		private var _ballast:String;
		
		public function LVD_06039()
		{
			getURLParameter();
			super();
		}
		
		override public function initCamera():void
		{
			scene = new Object3D();
			camera = new Camera3D(stage.stageWidth, stage.stageHeight, 1, 2000.0,  Math.PI * 3 / 8, false, BACKGROUN_COLOR);
			camera.view.hideDiagram();
		}
		override public function initScene():void
		{
			initLight();
			Jehovah.useSSAO = true;
			
			sceneContent = new Object3D();
			scene.addChild(sceneContent);
			sceneBG = new Object3D();
			scene.addChild(sceneBG);
			ruler = new Object3D();
			ruler.visible = false;
			scene.addChild(ruler);
			
			var recordLoader:AdvancedLoader = new AdvancedLoader();
			var recordRequest:URLRequest = new URLRequest(host + "?id=" + id);
			recordRequest.method = URLRequestMethod.GET;
			recordLoader.addEventListener(Event.COMPLETE, onRecordComplete);
			recordLoader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			recordLoader.load(recordRequest, 3);
		}
		private function getURLParameter():void
		{
			id = loaderInfo.parameters.id;
			language = loaderInfo.parameters.language;
			setLanguage();
		}
		
		private function setLanguage():void
		{
			switch(language)
			{
				case "zh_CN":
					_assembleStep="组合步骤：\n";
					_disassembleStep="拆解步骤：\n";
					_revolve="旋转";
					_move="移动";
					_zoom="缩放";
					_reset="重置";
					_assemble="组合";
					_disassemble="拆分";
					_assembleOperater="PS：组合时按拆分步骤反之即可";
					_disassembleOperater="PS:拆解时按组合步骤反之即可";
					preText = "点击与宝贝亲密互动!";
					break;
				case "en_US":
					_assembleStep="Steps of assembling:\n";
					_disassembleStep="Steps of disassembling:\n";
					_revolve="Revolve";
					_move="Move";
					_zoom="Zoom";
					_reset="Reset";
					_assemble="Assemble";
					_disassemble="Disassemble";
					_assembleOperater="PS: Steps of assembling are contrary.";
					_disassembleOperater="PS: Steps of disassembling are contrary.";
					preText = "Click for intimate interaction with products!";
					break;
				case "ja_JP" :
					_assembleStep="組み合わせるステップ:\n";
					_disassembleStep="解体ステップ:\n";
					_revolve="回転";
					_move="移動";
					_zoom="ズーム";
					_reset="リセット";
					_assemble="組み合わせる";
					_disassemble="解体";
					_assembleOperater="PS:組み合わせる時解体ステップの逆で行う。";
					_disassembleOperater="PS：解体する時に組み合わせるステップの逆で行う。";
					preText = "クリック!";
					break;
				case "ko_KR" :
					_assembleStep="조합절차:\n";
					_disassembleStep="분해절차:\n";
					_revolve="회전";
					_move="이동";
					_zoom="축합";
					_reset="재취득";
					_assemble="조합";
					_disassemble="분해 조립";
					_assembleOperater="PS：조합시 분해절차에 따라 반대로 하면 된다";
					_disassembleOperater="PS：분해시 조합절차에 따라 반대로 하면 된다";
					preText = "클릭하여 보배와 접촉!";
					break;
				case "fr_FR" :
					_assembleStep="Etapes de combinaison: \n";
					_disassembleStep="Etapes de Démontage: \n";
					_revolve="Rotation";
					_move="Déplacement";
					_zoom="Zoom";
					_reset="Remettre";
					_assemble="Combinaison";
					_disassemble="Démontage";
					_assembleOperater="PS: lors du montage, suivre les étapes contraires";
					_disassembleOperater="PS: Lors du démontage, suivre les étapes contraires";
					preText = "Cliquez pour avoir une interaction intime avec le produit!";
					break;
				case "ru_RU" :
					_assembleStep="Шаг комбинации: \n";
					_disassembleStep="Шаг разборки: \n";
					_revolve="Вращение";
					_move="Переселение";
					_zoom="Зум";
					_reset="Возврат";
					_assemble="Комбинация ";
					_disassemble="Разрешение";
					_assembleOperater="Примечание：Шаги комбинации и разборки противоположной";
					_disassembleOperater="Примечание：Шаги разборки и комбинации противоположной";
					preText = "Нажмите кнопку детский тесное взаимодействие!";
					break;
				case "ar_SA":
					_assembleStep=":خطوات التجمع التالية"+"\n";
					_disassembleStep=":خطوات التفكيك التالية"+"\n";
					_revolve="مستدار";
					_move="متنقل";
					_zoom="مصغر";
					_reset="أعاد التشغيل";
					_assemble="تجمع";
					_disassemble="تفكيك";
					_assembleOperater="ملاجظات: وفقا لخطوات التفكيك  للمصابيح عندما تجمعها و بالعكس ممكن";
					_disassembleOperater="ملاجظات: وفقا لخطوات التجمع للمصابيح عندما تفكيكها و بالعكس ممكن";
					preText = "!انقر لتفاعل مع الإضاءة";
					break;
				case "es_ES":
					_assembleStep="Pasos de montaje：\n";
					_disassembleStep="Pasos de desmontaje：\n";
					_revolve="girar";
					_move="Mover";
					_zoom="Zoom";
					_reset="Restablecer";
					_assemble="componer";
					_disassemble="Separado";
					_assembleOperater="P.D Los pasos de montaje son contrarias";
					_disassembleOperater="P.D Pasos de desmontaje son contrarias";
					preText = "Haga clic para una interacción íntima con productos!";
					break;	
			}
		}
		
		private function updateTextSequence():void
		{
			if(currentFrameIndex <= totalAnimationFrame)
			{
				var i:int;
				for(i = 0; i < textSequence.length; i ++)
				{
					if(inverseAnimation)
					{
						if(inverseTextSequence[i].startFrame == currentFrameIndex)
						{
							showInstruction(inverseTextSequence[i].text);
							break;
						}
						if(inverseTextSequence[i].stopFrame == currentFrameIndex)
						{
							hideInstruction();
							break;
						}
					}
					else
					{
						if(textSequence[i].startFrame == currentFrameIndex)
						{
							showInstruction(textSequence[i].text);
							break;
						}
						if(textSequence[i].stopFrame == currentFrameIndex)
						{
							hideInstruction();
							break;
						}
					}
				}
				if(currentFrameIndex == totalAnimationFrame)
				{
					if(inverseAnimation)
						totalHint.text = totalHint.text + _assembleOperater;
					else
						totalHint.text = totalHint.text + _disassembleOperater;
				}
				
				currentFrameIndex ++;
			}
		}
		private function onEnterFrame(evt:Event):void
		{
			updateTextSequence();
			
			if(!ruler)
				return ;
			//add deafult rotate z each frame.
			if(resetMode)
				RZ += 0.015;
			
			//add inertia rotate.
			if(useInertia)
			{
				RX += initSpeedRX - initSpeedRX / totalInertiaCount * currentInertiaCount;
				RZ += initSpeedRZ - initSpeedRZ / totalInertiaCount * currentInertiaCount;
				currentInertiaCount ++;
				if(currentInertiaCount >= totalInertiaCount)
					useInertia = false;
			}
			
			//set limit to RX.
			if(RX > maxRX)
				RX = maxRX;
			if(RX < minRX)
				RX = minRX;
			
			//update scene matrix.
			updateTarget();
			
//			trace(camera.x, camera.y, camera.z);
			//render.
			camera.render();
		}
		
		override public function onResize(evt:Event):void
		{
			super.onResize(evt);
			if(logo)
				logo.y = stage.stageHeight - logo.height;
			if(bounding)
				resetTargetAndCamera();
			
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				if(toolbar)
				{
					toolbar.x = (stage.stageWidth - toolbar.width) * 0.5;
					toolbar.y = stage.stageHeight - toolbar.height;
				}
				if(interactiveToolbar)
				{
					interactiveToolbar.x = toolbar.x + toolbar.width + 20;
					interactiveToolbar.y = toolbar.y;
				}
				if(play)
				{
					play.x = stage.stageWidth * 0.5;
					play.y = stage.stageHeight * 0.5;
				}
				if(bg)
				{
					bg.width = stage.stageWidth;
					bg.height = stage.stageHeight;
				}
				if(totalHint)
				{
					totalHint.x = stage.stageWidth - 260;
				}
			}
		}
		
		private function initLight():void
		{
			var defaultLight:Light3D = new Light3D(0xFFFFFF, 10, 500);
			defaultLight.rotationX = Math.PI / 6;
			defaultLight.rotationZ = 0.75 * Math.PI;
			defaultLight.composeTransform();
			Jehovah.defaultLight = defaultLight;
		}
		
		/**
		 * 加载playIcon完成时执行
		 * @param evt
		 * 
		 */		
		private function addPreplay():void
		{
			//添加logo
			logo = new Sprite();
			logo.addChild(new title_default());
			logo.addEventListener(MouseEvent.CLICK, logo_onClick);
			logo.buttonMode = true;
//			addChild(logo);
			
			//添加半透明的背景
			bg = new Sprite();
			bg.graphics.beginFill(0, 0.6);
			bg.graphics.drawRect(0, 0, 100, 100);
			bg.graphics.endFill();
			addChild(bg);
			
			//添加播放按钮
			play = new beforePlay() as MovieClip;
			play.buttonMode = true;
			TextField(MovieClip(play.getChildByName("pressText")).pressText.pressTxt).text = preText;
			TextField(MovieClip(play.getChildByName("pressText")).pressText1.pressTxt).text = preText;
			var tempLen:Number = TextField(MovieClip(play.getChildByName("pressText")).pressText.pressTxt).textWidth;
			if(language=="ja_JP")
				play.getChildByName("pressText").x+=20;
			if(language=="ar_SA")
				play.getChildByName("pressText").x+=10;
			if(tempLen>pressTxtOrginWid)
			{
				play.getChildByName("pressBar").width +=tempLen-pressTxtOrginWid+20;
//				play.getChildByName("pressBar").x-=(tempLen-pressTxtOrginWid)/2;
				play.getChildByName("pressText").x-=(tempLen-pressTxtOrginWid)/2;
			}
			addChild(play);
			play.getChildByName("allMask").width = stage.stageWidth;
			play.getChildByName("allMask").height = stage.stageHeight;
			
			//如果舞台尺寸ok，初始化ui坐标
			if(stage.stageWidth > 0 && stage.stageHeight > 0)
			{
				play.x = stage.stageWidth * 0.5;
				play.y = stage.stageHeight * 0.5;
				bg.width = stage.stageWidth;
				bg.height = stage.stageHeight;
				logo.y = stage.stageHeight - logo.height;
			}
			
			//侦听播放按钮的click事件
			play.addEventListener(MouseEvent.CLICK, onPlayClick);
		}
		private function addPreview():void
		{
			var loader:AdvancedLoader = new AdvancedLoader();
			loader.addEventListener(Event.COMPLETE, onPreviewComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.load(new URLRequest(baseURL + "&name=preview.jpg"), 3);
		}
		private function onPlayClick(evt:MouseEvent):void
		{
			evt.currentTarget.removeEventListener(MouseEvent.CLICK, onPlayClick);
			play.buttonMode = false;
			play.getChildByName("pressText").visible = false;
			play.getChildByName("loadingText").visible = true;
			TextField(play.getChildByName("loadingText")).text = "0%";
			
			initTextSequence();
			initInstruction();
			
			var loader:AdvancedLoader = new AdvancedLoader();
			loader.addEventListener(Event.COMPLETE, onFUWO3DComplete);
			loader.addEventListener(ProgressEvent.PROGRESS, onFUWO3DProgress);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.load(new URLRequest(baseURL + "&name=model.F3D"), 3);
		}
		
		private function onRecordComplete(evt:Event):void
		{
			var data:Object = JSON.parse(evt.target.data).data;
			var i:int;
			
			is_bottom = data.is_bottom;
			folder = data.folder;
			use_mip = data.mipmap;
			bg_type = data.bg_type;
			bg_color = data.bg_color;
			baseURL = "http://3dshow.flash.jaeapp.com/view/file/getfile.php?folder=" + folder;
			bg_image = baseURL + "&name=background.jpg";
			if(data.need_light == 0)
			{
				Jehovah.ambientCoefficient = 1;
				Jehovah.diffuseCoefficient = 0;
			}
			//解析setting
			if(data.shadow && data.shadow != "")
			{
				var setting:Object = JSON.parse(data.shadow);
				Jehovah.ambientCoefficient = setting.ambientCoefficient;
				Jehovah.diffuseCoefficient = setting.diffuseCoefficient;
				Jehovah.useDefaultLight = Boolean(setting.useDefaultLight);
				if(!Jehovah.useDefaultLight)
				{
					for(i = 0; i < setting.lights.length; i ++)
					{
						var light:FreeLight3D = FreeLight3D.fromObject(setting.lights[i]);
						Jehovah.lights.push(light);
						light.visible = false;
						scene.addChild(light);
					}
					var ao:Object = setting.ao;
					Jehovah.useSSAO = Boolean(ao.useSSAO);
					if(Jehovah.useSSAO)
					{
						if(!Jehovah.camera.rendererDict[SSAORenderer.NAME])
						{
							var ssao:SSAORenderer = new SSAORenderer(null);
							ssao.scale = ao.scale;
							ssao.bias = ao.bias;
							ssao.sampleRadius = ao.sampleRadius;
							ssao.intensity = ao.intensity;
							Jehovah.camera.rendererDict[SSAORenderer.NAME] = ssao;
						}
					}
				}
			}
			
			//解析动画
			if(data.interaction && data.interaction != "")
			{
				interaction = JSON.parse(data.interaction).interaction;
				for(i = 0; i < interaction.length; i ++)
					if(interaction[i].frameCount && interaction[i].frameCount > 0)
						totalAnimationFrame = Math.max(totalAnimationFrame, interaction[i].stopFrameIndex);
				if(totalAnimationFrame > 0)
					hasAnimation = true;
			}
			
			addPreplay();
			addPreview();
		}
		private function onFUWO3DProgress(evt:ProgressEvent):void
		{
			var percent:int;
			if(evt.bytesTotal == 0)
				percent = Math.min(Math.round(evt.bytesLoaded / 2000000 * 0.5 * 100), 100);
			else
				percent = Math.min(Math.round(evt.bytesLoaded / evt.bytesTotal * 0.5 * 100), 100);
			TextField(play.getChildByName("loadingText")).text = String(percent) + "%";
			MovieClip(play.getChildByName("pressBar")).gotoAndStop(percent);
		}
		private function onPreviewComplete(evt:Event):void
		{
			if(play && evt.target.data && evt.target.data is Bitmap)
			{
				preview = evt.target.data as Bitmap;
				if(preview.width * stage.stageHeight == preview.height * stage.stageWidth || stage.stageWidth == 0 || stage.stageHeight == 0)
				{
					addChildAt(preview, 1);
					return ;
				}
				
				var bmd:BitmapData;
				if(preview.width / preview.height > stage.stageWidth / stage.stageHeight)
				{
					var newW:int = stage.stageWidth / stage.stageHeight * preview.height;
					bmd = new BitmapData(newW, preview.height, false);
					bmd.copyPixels(preview.bitmapData, new Rectangle((preview.width - newW) * 0.5, 0, newW, preview.height), new Point(0, 0));
				}
				else
				{
					var newH:int = stage.stageHeight / stage.stageWidth * preview.width;
					bmd = new BitmapData(preview.width, newH, false);
					bmd.copyPixels(preview.bitmapData, new Rectangle(0, (preview.height - newH) * 0.5, preview.width, newH), new Point(0, 0));
				}
				preview = new Bitmap(bmd);
				preview.width = stage.stageWidth;
				preview.height = stage.stageHeight;
				addChildAt(preview, 1);
			}
		}
		
		private var currentInstructionObject:Object3D;
		private var currentInstruction:String;
		private function onStartAnimation(evt:Event):void
		{
			currentInstructionObject = evt.target as Object3D;
			showInstruction(evt.target.instruction);
//			trace(evt.target.instruction);
		}
		private function onStopAnimation(evt:Event):void
		{
			if(evt.target == currentInstructionObject)
			{
				currentInstructionObject = null;
				hideInstruction();
			}
		}
		private function showInstruction(instruction:String):void
		{
//			trace("show: ", instruction);
			if(!animationHint)
			{
				switch(language)
				{
					case "zh_CN":
						animationHint = new TextHint(16, false, 0);
						break;
					default:
						animationHint = new TextHint(13, false, 0);
						break;
				}
				//animationHint = new TextHint(16, false, 0);
				addChild(animationHint);
			}
			totalHint.text = totalHint.text + instruction + "\n";
			animationHint.text = instruction;
			animationHint.x = (stage.stageWidth - animationHint.width) * 0.5;
			animationHint.y = stage.stageHeight - animationHint.height - toolbar.height - 5;
			animationHint.visible = true;
		}
		private function hideInstruction():void
		{
			if(animationHint)
			{
				animationHint.text = "";
				animationHint.visible = false;
			}
		}
		
		private function initTextSequence():void
		{
			switch (language)
			{
				case "zh_CN" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.按下顶部卡扣，打开电箱", "inverseText": "3.盖上电箱，按上卡扣"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.拧下灯罩支架螺丝，取下灯管支架", "inverseText": "2.安装灯管支架，拧上螺丝"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.拧下螺丝，取出镇流器", "inverseText": "1.安装镇流器，拧上螺丝"}
					);
					break;
				case "en_US" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.Tighten top buckle, open electrical box", "inverseText": "3.Close electrical box and then tighten buckle"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.Remove shade bracket screws and remove lamp and bracket", "inverseText": "2.Mount lamp and bracket, and then tighten screws"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.Unscrew screws and then remove ballast", "inverseText": "1.Install ballast and then tighten screws"}
					);
					break;
				case "ja_JP" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.上のファスナーを開いて、電器を開く。", "inverseText": "3.電器箱に蓋をして、ファスナーを押す。"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.ランプかさのブラケットのネジを緩めて、灯管スタンドを取り外す。", "inverseText": "2.灯管のスタンドを取り付けて、ネジを締める。"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.ネジを緩めて、バラストを取り出す。", "inverseText": "1.バラストを取り付けて、ネジを締める。"}
					);
					break;
				case "ko_KR" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.위쪽 단춧구멍을 풀이고 전함을 열리다", "inverseText": "3.전함 덮개를 닫고 단춧구멍을 채우다"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.등갓,스탠드,나사를 빼내고 등관,스탠드를 꺼내다", "inverseText": "2.스탠드와 등관을 설치하고 나사를 조인다"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.나사를 빼내고 안정기를 꺼내다", "inverseText": "1.안정기를 설치하고 나사를 조인다"}
					);
					break;
				case "fr_FR" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.Appuyez sur le composant enfichable, ouvrez la boîte électrique", "inverseText": "3.Fermer la boîte électrique, pressez sur le composant enfichable"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.Retirez les vis du support de l'abat-jour, retirez le ballast", "inverseText": "2.Installez le support de lampe et serrez les vis"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.Dévissez et enlevez le ballast", "inverseText": "1.Installez ballast, serrez les vis"}
					);
					break;
				case "ru_RU" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.Снимите пряжку и откройте электрическии блок", "inverseText": "3.Покрывает крышку электрического блока, установите и пряжку"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.Отверните винт абажура，снимите кронштейн и трубку", "inverseText": "2.Установите кронштейн и трубку, ввинтите винт"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.Отверните винт, принимает вне балласт", "inverseText": "1.Установите балласт, ввинтите винт"}
					);
					break;
				case "ar_SA" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1انقر الرز على الرأس  لفتح المربع الكهربائي", "inverseText": "3تركيب غطاء المربع الكهربائي مع تشديد الرز"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2فك مسامير فرع المصباح وإزالة فرع المصباح", "inverseText": "2تثبيت فرع المصباح، و تشديد المسامير"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3فك المسمار وإزالة الكابح", "inverseText": "1تثبيت الكابح وتشديد المسامير"}
					);
					break;
				case "es_ES" :
					textSequence.push(
						{"startFrame": 10, "stopFrame": 82, "text": "1.abierta la hebilla de la parte superior y abierta la caja eléctrica.", "inverseText": "3.cierre la tapa de la caja eléctrica, apretar la hebilla"}, 
						{"startFrame": 106, "stopFrame": 202, "text": "2.Afloje los tornillos de soporte, retire la lámpara y soporte.", "inverseText": "2.Monte el soporte, Apriete los tornillos"}, 
						{"startFrame": 226, "stopFrame": 321, "text": "3.Afloje los tornillos,retire el balastro.", "inverseText": "1.Instale balastro, Apriete los tornillos"}
					);
					break;
			}
			
			var i:int;
			for(i = textSequence.length - 1; i >= 0; i --)
			{
				inverseTextSequence.push({
					"startFrame": totalAnimationFrame - textSequence[i].stopFrame, 
					"stopFrame": totalAnimationFrame - textSequence[i].startFrame, 
					"text": textSequence[i].inverseText
				});
			}
		}
		private function initInstruction():void
		{
			switch (language)
			{
				case "zh_CN" :
					instructionDict["zhenliuqi"] = "镇流器";//Ballast
					instructionDict["dianxiang"] = "电箱";
					instructionDict["dengguanzhijia"] = "灯管支架";//Lamp and bracket
					break;
				case "en_US" :
					instructionDict["zhenliuqi"] = "Ballast";
					instructionDict["dianxiang"] = "Electrical box";
					instructionDict["dengguanzhijia"] = "Lamp and bracket";
					break;
				case "ja_JP" :
					instructionDict["zhenliuqi"] = "バラスト";
					instructionDict["dianxiang"] = "電器箱";
					instructionDict["dengguanzhijia"] = "灯管スタンド";
					break;
				case "ko_KR" :
					instructionDict["zhenliuqi"] = "안정기";
					instructionDict["dianxiang"] = "전함";
					instructionDict["dengguanzhijia"] = "등관스탠드";
					break;
				case "fr_FR" :
					instructionDict["zhenliuqi"] = "Ballast";
					instructionDict["dianxiang"] = "Boîte électrique";
					instructionDict["dengguanzhijia"] = "Support de lampe";
					break;
				case "ru_RU" :
					instructionDict["zhenliuqi"] = "балласт";
					instructionDict["dianxiang"] = "электрический блок";
					instructionDict["dengguanzhijia"] = "кронштейн трубки";
					break;
				case "ar_SA" :
					instructionDict["zhenliuqi"] = "الكوابح";
					instructionDict["dianxiang"] = "المربع الكهربائي";
					instructionDict["dengguanzhijia"] = "فرع المصباح";
					break;
				case "es_ES" :
					instructionDict["zhenliuqi"] = "El balastro";
					instructionDict["dianxiang"] = "la caja eléctrica";
					instructionDict["dengguanzhijia"] = "Lámpara y soporte";
					break;
			}
			hasInstruction = true;
		}
		
		private function onFUWO3DComplete(evt:Event):void
		{
			//解析meshes。
			var data:ByteArray = evt.target.data as ByteArray;
			data.uncompress(CompressionAlgorithm.LZMA);
			var parser:ParserFUWO3D = new ParserFUWO3D();
			parser.data = data;
			parser.baseURL = baseURL + "&name=";
			parser.parse();
			
			obj3ds = parser.parseResult();
			var i:int;
			var j:int;
			
			for(i = 0; i < obj3ds.length; i ++)
			{
				//名字里有"_L"，是低模
				if(obj3ds[i].name.indexOf("_L") != -1)
					continue;
				
				//寻找doppergangerGeometry
				var ist:String;
				for(j = i + 1;j  < obj3ds.length; j ++)
					if(obj3ds[j].name == obj3ds[i].name + "_L" && obj3ds[j] is Mesh)
					{
						obj3ds[i].doppergangerGeometry = Mesh(obj3ds[j]).geometry;
						break;
					}
				
				//设置鼠标经过时的显示文字。无文字的不参与射线检测
				if(instructionDict[obj3ds[i].name])
				{
					obj3ds[i].mouseEnabled = true;
//					trace(obj3ds[i].name);
					if(obj3ds[i].getNumTriangle() > 100 && !obj3ds[i].doppergangerGeometry)
					{
						trace(obj3ds[i].name + "有" + scene.getNumTriangle() + "个三角形，却没有简模，鼠标检测会很慢！");
						obj3ds[i].mouseEnabled = false;
					}
				}
				else
					obj3ds[i].mouseEnabled = false;
				
				//添加物体到场景
				if(obj3ds[i].name != null && obj3ds[i].name.indexOf("_bg_") != -1)
					sceneBG.addChild(obj3ds[i]);
				else
					sceneContent.addChild(obj3ds[i]);
			}
			scene.useMip = (use_mip == 1);
			scene.uploadResource(Jehovah.context3D);
			
			//初始化bounding。
			camera.updateHierarchyMatrix();
			bounding = sceneContent.bounding;
			trace(bounding.width, bounding.length, bounding.height);
			sceneContent.x = sceneBG.x = -(bounding.minX + bounding.maxX) * 0.5;
			sceneContent.y = sceneBG.y = -(bounding.minY + bounding.maxY) * 0.5;
			sceneContent.z = sceneBG.z = -(bounding.minZ + bounding.maxZ) * 0.5;
			
			addRuler();
			
			//加载贴图。
			var bulkloader:BulkLoader = new BulkLoader();
			var meshes:Vector.<Mesh> = retrieveMeshes();
			for(i = 0; i < meshes.length; i ++)
			{
				if(meshes[i].mtl.diffuseMapURL)
					bulkloader.add(meshes[i].mtl.diffuseMapURL);
				if(meshes[i].mtl.specularMapURL)
					bulkloader.add(meshes[i].mtl.specularMapURL);
				if(meshes[i].mtl.bumpMapURL)
					bulkloader.add(meshes[i].mtl.bumpMapURL);
				if(meshes[i].mtl.reflectionMapURL)
				{
					bulkloader.add(meshes[i].mtl.reflectionMapURL);
					cubeTextureDict[meshes[i].mtl.reflectionMapURL] = true;
				}
				if(meshes[i].mtl.opacityMapURL)
					bulkloader.add(meshes[i].mtl.opacityMapURL);
			}
			
			if(bg_type == 1)
				bulkloader.add(bg_image);
			bulkloader.addEventListener(Event.COMPLETE, onBulkLoaderComplete);
			bulkloader.addEventListener(ProgressEvent.PROGRESS, onBulkLoaderProgress);
			bulkloader.load();
		}
		
		private function retrieveMeshes():Vector.<Mesh>
		{
			var ret:Vector.<Mesh> = new Vector.<Mesh>();
			var i:int;
			var j:int;
			for(i = 0; i < obj3ds.length; i ++)
			{
				if(obj3ds[i] is Mesh)
					ret.push(obj3ds[i]);
				else
				{
					for(j = 0; j < obj3ds[i].numChildren; j ++)
						if(obj3ds[i].getChildAt(j) is Mesh)
							ret.push(obj3ds[i].getChildAt(j));
				}
			}
			return ret;
		}
		private function onBulkLoaderProgress(evt:ProgressEvent):void
		{
			var percent:int = Math.min(Math.round((0.5 + evt.bytesLoaded / evt.bytesTotal * 0.5) * 100), 100);
			TextField(play.getChildByName("loadingText")).text = String(percent) + "%";
			MovieClip(play.getChildByName("pressBar")).gotoAndStop(percent);
		}
		private function onBulkLoaderComplete(evt:Event):void
		{
			//remove callback。
			var bulkloader:BulkLoader = evt.target as BulkLoader;
			bulkloader.removeEventListener(Event.COMPLETE, onBulkLoaderComplete);
			bulkloader.removeEventListener(ProgressEvent.PROGRESS, onBulkLoaderProgress);
			
			//将贴图资源添加到AssetManager中。
			var keys:Array = [];
			var key:*;
			for(key in bulkloader.tasks)
				keys.push(key);
			for each(key in keys)
			{
				if(bulkloader.tasks[key].state == BulkLoader.STATE_SUCCESS)
				{
					if(cubeTextureDict[key])
						AssetsManager.addCubeTextureResource(key, Bitmap(bulkloader.tasks[key].data).bitmapData.clone());
					else
						AssetsManager.addTextureResource(key, Bitmap(bulkloader.tasks[key].data).bitmapData.clone());
				}
			}
			
			if(bg_type == 1 && bulkloader.tasks[bg_image].state == BulkLoader.STATE_SUCCESS) //使用背景图片
			{
				var bg3d:BitmapTextureBG = new BitmapTextureBG(Bitmap(bulkloader.tasks[bg_image].data).bitmapData.clone());
				sceneContent.addChild(bg3d);
			}
			else //使用背景色
			{
				if(bg_color == "") //默认背景色
					camera.bgColor = new HexColor(0xFFFFFF, 1);
				else
				{
					if(bg_color.charAt(0) == "#")
						bg_color = bg_color.substr(1);
					camera.bgColor = new HexColor(parseInt(bg_color, 16), 1);
				}
			}
			
			//set textureresource.
			var i:int;
			var j:int;
			var meshes:Vector.<Mesh> = retrieveMeshes();
			for(i = 0; i < meshes.length; i ++)
			{
				if(meshes[i].mtl.diffuseMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.diffuseMapURL))
						meshes[i].mtl.diffuseMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.diffuseMapURL).textureResource;
				}
				if(meshes[i].mtl.specularMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.specularMapURL))
						meshes[i].mtl.specularMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.specularMapURL).textureResource;
				}
				if(meshes[i].mtl.bumpMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.bumpMapURL))
						meshes[i].mtl.bumpMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.bumpMapURL).textureResource;
				}
				if(meshes[i].mtl.reflectionMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.reflectionMapURL))
						meshes[i].mtl.reflectionMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.reflectionMapURL).textureResource;
				}
				if(meshes[i].mtl.opacityMapURL != null)
				{
					if(AssetsManager.getTextureResourceByKey(meshes[i].mtl.opacityMapURL))
						meshes[i].mtl.opacityMapResource = AssetsManager.getTextureResourceByKey(meshes[i].mtl.opacityMapURL).textureResource;
				}
			}
			
			if(preview)
			{
				removeChild(preview);
				preview = null;
			}
			addEventListener(Event.ENTER_FRAME, fadePlay);
			
			initBehavior();
			initUI();
		}
		
		private function fadePlay(evt:Event):void
		{
			play.alpha -= 0.1;
			bg.alpha -= 0.1;
			if(play.alpha <= 0)
			{
				removeEventListener(Event.ENTER_FRAME, fadePlay);
				removeChild(play);
				play = null;
				removeChild(bg);
				bg = null;
			}
		}
		
		private function onIOError(evt:IOErrorEvent):void
		{
			trace("IO Error!");
		}
		
		private function addRuler():void
		{
			ruler.z = -bounding.height * 0.5;
			
			bounding.width = Math.floor(bounding.width + 0.5);
			bounding.length = Math.floor(bounding.length + 0.5);
			bounding.height = Math.floor(bounding.height + 0.5);
			
			var x0:Number = bounding.width * 0.5;
			var y0:Number = bounding.length * 0.5;
			var z0:Number = bounding.height * 0.5;
			var x1:Number = x0 * 0.15;
			var y1:Number = y0 * 0.15;
			var z1:Number = z0 * 0.15;
			var average:Number = (x0 + y0 + z0) / 3;
			
			var boundingWF:WireFrame = new WireFrame(Vector.<Vector3D>([
				new Vector3D(x0, y0, 0), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, y0, 0), 
				
				new Vector3D(x0, y0, z0 * 2), 
				new Vector3D(-x0, y0, z0 * 2), 
				new Vector3D(-x0, y0, z0 * 2), 
				new Vector3D(-x0, -y0, z0 * 2), 
				new Vector3D(-x0, -y0, z0 * 2), 
				new Vector3D(x0, -y0, z0 * 2), 
				new Vector3D(x0, -y0, z0 * 2), 
				new Vector3D(x0, y0, z0 * 2), 
				
				new Vector3D(x0, y0, 0), 
				new Vector3D(x0, y0, z0 * 2), 
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0, y0, z0 * 2), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0, z0 * 2), 
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, -y0, z0 * 2)
			]), 0xFFFFFF, 1);
			ruler.addChild(boundingWF);
			
			var rulerWF:WireFrame = new WireFrame(Vector.<Vector3D>([
				//x axis
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0, -y0 - y1, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0, -y0 - y1, 0), 
				new Vector3D(x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(-x0, -y0 - y1 * 0.5, 0), 
				
				new Vector3D(x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(x0 - y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.25, 0), 
				new Vector3D(x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(x0 - y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.75, 0), 
				
				new Vector3D(-x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(-x0 + y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.25, 0), 
				new Vector3D(-x0, -y0 - y1 * 0.5, 0), 
				new Vector3D(-x0 + y1 * 0.25 / Math.atan(15 / 180 * Math.PI), -y0 - y1 * 0.75, 0), 
				
				//y axis
				new Vector3D(-x0, y0, 0), 
				new Vector3D(-x0 - x1, y0, 0), 
				new Vector3D(-x0, -y0, 0), 
				new Vector3D(-x0 - x1, -y0, 0), 
				new Vector3D(-x0 - x1 * 0.5, y0, 0), 
				new Vector3D(-x0 - x1 * 0.5, -y0, 0), 
				
				new Vector3D(-x0 - x1 * 0.5, y0, 0), 
				new Vector3D(-x0 - x1 * 0.25, y0 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				new Vector3D(-x0 - x1 * 0.5, y0, 0), 
				new Vector3D(-x0 - x1 * 0.75, y0 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				
				new Vector3D(-x0 - x1 * 0.5, -y0, 0), 
				new Vector3D(-x0 - x1 * 0.25, -y0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				new Vector3D(-x0 - x1 * 0.5, -y0, 0), 
				new Vector3D(-x0 - x1 * 0.75, -y0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI), 0), 
				
				//z axis
				new Vector3D(x0, -y0, 0), 
				new Vector3D(x0 + x1, -y0, 0), 
				new Vector3D(x0, -y0, z0 * 2), 
				new Vector3D(x0 + x1, -y0, z0 * 2), 
				new Vector3D(x0 + x1 * 0.5, -y0, 0), 
				new Vector3D(x0 + x1 * 0.5, -y0, z0 * 2), 
				
				new Vector3D(x0 + x1 * 0.5, -y0, 0), 
				new Vector3D(x0 + x1 * 0.25, -y0, 0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI)), 
				new Vector3D(x0 + x1 * 0.5, -y0, 0), 
				new Vector3D(x0 + x1 * 0.75, -y0, 0 + x1 * 0.25 / Math.atan(15 / 180 * Math.PI)), 
				
				new Vector3D(x0 + x1 * 0.5, -y0, z0 * 2), 
				new Vector3D(x0 + x1 * 0.25, -y0, z0 * 2 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI)), 
				new Vector3D(x0 + x1 * 0.5, -y0, z0 * 2), 
				new Vector3D(x0 + x1 * 0.75, -y0, z0 * 2 - x1 * 0.25 / Math.atan(15 / 180 * Math.PI))
			]), RULER_COLOR, 1);
			ruler.addChild(rulerWF);
			
			var tf:TextField = new TextField();
			tf.width = 128;
			tf.height = 32;
			var format:TextFormat = new TextFormat("Arial", 16, RULER_COLOR, false);
			tf.defaultTextFormat = format;
			
			tf.text = MyMath.toPrecision(bounding.width, 0) + "cm";
			var rulerXTextBMD:BitmapData = new BitmapData(64, 32, true, 0x00000000);
			rulerXTextBMD.draw(tf);
			
			tf.text = MyMath.toPrecision(bounding.length, 0) + "cm";
			var rulerYTextBMD:BitmapData = new BitmapData(64, 32, true, 0x00000000);
			rulerYTextBMD.draw(tf, null, null, null, null, true);
			
			tf.text = MyMath.toPrecision(bounding.height, 0) + "cm";
			var rulerZTextBMD:BitmapData = new BitmapData(64, 32, true, 0x00000000);
			rulerZTextBMD.draw(tf);
			
			var xtr:TextureResource = new TextureResource(rulerXTextBMD);
			var ytr:TextureResource = new TextureResource(rulerYTextBMD);
			var ztr:TextureResource = new TextureResource(rulerZTextBMD);
			xtr.upload(Jehovah.context3D);
			ytr.upload(Jehovah.context3D);
			ztr.upload(Jehovah.context3D);
			
			var xdm:DiffuseMtl = new DiffuseMtl();
			xdm.diffuseMapResource = xtr;
			xdm.diffuseUVMatrix = new Matrix();
			xdm.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
			xdm.destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			xdm.culling = "none";
			
			var ydm:DiffuseMtl = new DiffuseMtl();
			ydm.diffuseMapResource = ytr;
			ydm.diffuseUVMatrix = new Matrix();
			ydm.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
			ydm.destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			ydm.culling = "none";
			
			var zdm:DiffuseMtl = new DiffuseMtl();
			zdm.diffuseMapResource = ztr;
			zdm.diffuseUVMatrix = new Matrix();
			zdm.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
			zdm.destinationFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
			zdm.culling = "none";
			
			var px:PrimitivePlane = new PrimitivePlane(average * 0.5, average * 0.25);
			px.geometry.upload(Jehovah.context3D);
			px.mtl = xdm;
			px.y = -y0 - average * 0.25;
			px.z = 1;
			ruler.addChild(px);
			
			var py:PrimitivePlane = new PrimitivePlane(average * 0.5, average * 0.25);
			py.geometry.upload(Jehovah.context3D);
			py.mtl = ydm;
			py.rotationZ = -Math.PI * 0.5;
			py.x = -x0 - average * 0.25;
			py.z = 1;
			ruler.addChild(py);
			
			var pz:PrimitivePlane = new PrimitivePlane(average * 0.5, average * 0.25);
			pz.geometry.upload(Jehovah.context3D);
			pz.mtl = zdm;
			pz.rotationZ = -Math.PI * 0.5;
			pz.rotationY = Math.PI * 0.5;
			pz.x = x0 + average * 0.25;
			pz.y = -y0;
			pz.z = z0;
			ruler.addChild(pz);
		}
		
		
		
		
		
		
		
		
		
		private var maxRX:Number;
		private var minRX:Number;
		private var maxScale:Number = 2;
		private var minScale:Number = 0.4;
		private var bounding:Bounding;
		private var RX:Number = 0; //R: rotation
		private var RZ:Number = 0;
		private var scale:Number = 1.0;
		
		//inertia.
		private var initSpeedRX:Number;
		private var initSpeedRZ:Number;
		private var currentInertiaCount:int = 0;
		private var totalInertiaCount:int = 40;
		private var useInertia:Boolean = false;
		
		private var oldPoint:Point = new Point();
		private var newPoint:Point = new Point();
		
		//inertia
		private var downPoint:Point = new Point();
		private var upPoint:Point = new Point();
		private var frameTicked:int = 0;
		
		private function initBehavior():void
		{
			resetTargetAndCamera();
			maxRX = 0;
			if(is_bottom)
				minRX = -Math.PI;
			else
				minRX = -Math.PI * 0.5;
			
			camera.view.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			//当存在文字说明时，鼠标移动时的显示文字说明
			if(hasInstruction)
				camera.view.addEventListener(MouseEvent.MOUSE_MOVE, onDetectMouseMove);
		}
		
		private function onMouseDown(evt:MouseEvent):void
		{
			if(hasInstruction)
			{
				camera.view.removeEventListener(MouseEvent.MOUSE_MOVE, onDetectMouseMove);
				mouseDectiveHint.visible = false;
			}
			
			if(resetMode)
				resetMode = false;
			camera.view.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			camera.view.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			camera.view.addEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			oldPoint.x = evt.localX;
			oldPoint.y = evt.localY;
			
			//on mouse down, set init inertia speed to zero.s
			initSpeedRX = 0;
			initSpeedRZ = 0;
			//on mouse down, switch off inertia.
			useInertia = false;
		}
		private function onMouseMove(evt:MouseEvent):void
		{
			newPoint.x = evt.localX;
			newPoint.y = evt.localY;
			
			if(state == 0) //rotate mode
			{
				RX += (newPoint.y - oldPoint.y) / 100;
				RZ += (newPoint.x - oldPoint.x) / 100;
				initSpeedRX = (newPoint.y - oldPoint.y) / 100;
				initSpeedRZ = (newPoint.x - oldPoint.x) / 100;
			}
			else if(state == 1) //move mode
			{
				var oldRay:Ray = Jehovah.calculateRay(oldPoint);
				var newRay:Ray = Jehovah.calculateRay(newPoint);
				var plane:Plane = new jehovah3d.core.pick.Plane(new Vector3D(), new Vector3D(0, 0, 1));
				var i0:Object = MousePickManager.rayPlaneIntersect(oldRay, plane);
				var i1:Object = MousePickManager.rayPlaneIntersect(newRay, plane);
				if(i0 && i1)
				{
					var v0:Vector3D = i0.point;
					var v1:Vector3D = i1.point;
					camera.x -= (v1.x - v0.x);
					camera.y -= (v1.y - v0.y);
				}
			}
			else if(state == 2)
			{
				if(newPoint.y - oldPoint.y > 0)
					scale *= 1.03;
				else if(newPoint.y - oldPoint.y < 0)
					scale /= 1.03;
				if(scale < minScale)
					scale = minScale;
				if(scale > maxScale)
					scale = maxScale;
				camera.z = camera.calculateInitDistByTargetBounding(bounding.radius * scale, 0);
			}
			
			oldPoint.x = newPoint.x;
			oldPoint.y = newPoint.y;
		}
		
		private function onDetectMouseMove(evt:MouseEvent):void
		{
			Jehovah.mousePick(evt);
			if(MousePickManager.target)
			{
				Mouse.cursor = MouseCursor.BUTTON;
//				trace(MousePickManager.target.object.name);
				if(instructionDict[MousePickManager.target.object.name])
					mouseDectiveHint.text = instructionDict[MousePickManager.target.object.name];
				
				mouseDectiveHint.visible = true;
				mouseDectiveHint.x = evt.localX - mouseDectiveHint.width * 0.5;
				mouseDectiveHint.y = evt.localY - mouseDectiveHint.height - 10;
			}
			else
			{
				Mouse.cursor = MouseCursor.AUTO;
				mouseDectiveHint.visible = false;
			}
		}
		
		private function onMouseUp(evt:MouseEvent):void
		{
			if(camera.view.hasEventListener(MouseEvent.MOUSE_MOVE))
				camera.view.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if(camera.view.hasEventListener(MouseEvent.MOUSE_UP))
				camera.view.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(camera.view.hasEventListener(MouseEvent.MOUSE_OUT))
				camera.view.removeEventListener(MouseEvent.MOUSE_OUT, onMouseUp);
			
			//当存在文字说明时，鼠标移动时的显示文字说明
			if(hasInstruction)
				camera.view.addEventListener(MouseEvent.MOUSE_MOVE, onDetectMouseMove);
			
			//on mouse up, switch on inertia. restart by set current inertia count to zero.
			useInertia = true;
			currentInertiaCount = 0;
		}
		
		private function onMouseWheel(evt:MouseEvent):void
		{
			if(evt.delta > 0)
				zoomIn();
			else
				zoomOut();
			evt.stopImmediatePropagation();
		}
		
		private function onKeyDown(evt:KeyboardEvent):void
		{
			if(evt.charCode == Keyboard.ESCAPE)
				resetTargetAndCamera();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 50)
				flipMip();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 52)
				onFSClick(null);
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 53)
			{
				resetTargetAndCamera();
				generatePreview();
			}
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 54)
				generatePreview();
			else if(evt.ctrlKey && evt.altKey && evt.charCode == 55)
				flipUseShadow();
		}
		private function flipUseShadow():void
		{
			var i:int;
			for(i = 0; i < Jehovah.lights.length; i ++)
				Jehovah.lights[i].useShadow = !Jehovah.lights[i].useShadow;
		}
		private function flipMip():void
		{
			scene.useMip = !scene.useMip;
		}
		private function generatePreview():void
		{
			camera.drawToBitmapData = true;
			camera.render();
			var bmd:BitmapData = camera.screenShot.clone();
			camera.drawToBitmapData = false;
			var fr:FileReference = new FileReference();
			var jpg:JPGEncoder = new JPGEncoder();
			fr.save(jpg.encode(bmd), "preview.jpg");
		}
		
		private function resetTargetAndCamera():void
		{
			scale = 1;
			camera.x = camera.y = 0;
			camera.z = camera.calculateInitDistByTargetBounding(bounding.radius * scale, 0);
			camera.zFar = camera.calculateInitDistByTargetBounding(bounding.radius * maxScale, 0) + bounding.radius * 2;
			
			RX = -Math.PI / 3;
			RZ = Math.PI / 4;
			updateTarget();
		}
		private function updateTarget():void
		{
			var matrix:Matrix3D = new Matrix3D();
			matrix.appendRotation(RZ * 180 / Math.PI, Vector3D.Z_AXIS);
			matrix.appendRotation(RX * 180 / Math.PI, Vector3D.X_AXIS);
			scene.matrix = matrix;
		}
		private function zoomIn():void
		{
			
		}
		private function zoomOut():void
		{
			
		}
		
		[Embed(source="assets/ui/newtitle.png", mimeType="image/png")]
		private var title_default:Class;
		
		[Embed(source="assets/ui/toolbar/rotate_default.png", mimeType="image/png")]
		private var rotate_default:Class;
		
		[Embed(source="assets/ui/toolbar/move_default.png", mimeType="image/png")]
		private var move_default:Class;
		
		[Embed(source="assets/ui/toolbar/zoom_default.png", mimeType="image/png")]
		private var zoom_default:Class;
		
		[Embed(source="assets/ui/toolbar/reset_default.png", mimeType="image/png")]
		private var reset_default:Class;
		
		[Embed(source="assets/ui/toolbar/showruler_default.png", mimeType="image/png")]
		private var showruler_default:Class;
		
		[Embed(source="assets/ui/toolbar/hideruler_default.png", mimeType="image/png")]
		private var hideruler_default:Class;
		
		//交互按钮
		[Embed(source="assets/ui/toolbar/compose_default.png", mimeType="image/png")]
		private var compose_default:Class;
		
		[Embed(source="assets/ui/toolbar/decompose_default.png", mimeType="image/png")]
		private var decompose_default:Class;
		
		private var logo:Sprite;
		private var toolbar:Sprite;
		private var rotate:EasyButton;
		private var move:EasyButton;
		private var zoom:EasyButton;
		private var reset:EasyButton;
		private var showruler:EasyButton;
		private var hideruler:EasyButton;
		
		private var interactiveToolbar:Sprite;
		private var compose:EasyButton;
		private var decompose:EasyButton;
		
		private var _state:uint = uint.MAX_VALUE;
		private var resetMode:Boolean = true;
		private function initUI():void
		{
			//创建toolbar
			toolbar = new Sprite();
			addChild(toolbar);
			rotate = new EasyButton(new rotate_default(), _revolve);
			toolbar.addChild(rotate);
			rotate.x = 2;
			rotate.y = 1;
			move = new EasyButton(new move_default(), _move);
			toolbar.addChild(move);
//			move.x = 2 + 49;
			move.x = 2 + rotate.width;
			move.y = 1;
			zoom = new EasyButton(new zoom_default(), _zoom);
			toolbar.addChild(zoom);
//			zoom.x = 2 + 49 * 2;
			zoom.x = move.x+move.width;
			zoom.y = 1;
			reset = new EasyButton(new reset_default(), _reset);
			toolbar.addChild(reset);
//			reset.x = 2 + 49 * 3;
			reset.x = zoom.x+zoom.width;
			reset.y = 1;
			
			showruler = new EasyButton(new showruler_default(), "显示尺寸");
//			toolbar.addChild(showruler);
			showruler.x = 2 + 49 * 4;
			showruler.y = 1;
			hideruler = new EasyButton(new hideruler_default(), "隐藏尺寸");
//			toolbar.addChild(hideruler);
			hideruler.x = 2 + 49 * 4;
			hideruler.y = 1;
			hideruler.visible = false;
			
			toolbar.graphics.clear();
			toolbar.graphics.beginFill(0, 0.3);
			toolbar.graphics.drawRoundRect(0, 0, toolbar.width, toolbar.height, 25, 25);
			toolbar.graphics.endFill();
			
			toolbar.x = (stage.stageWidth - toolbar.width) * 0.5;
			toolbar.y = stage.stageHeight - toolbar.height - 2;
			
			state = 0; 
			
			rotate.addEventListener(MouseEvent.CLICK, onRotateClick);
			move.addEventListener(MouseEvent.CLICK, onMoveClick);
			zoom.addEventListener(MouseEvent.CLICK, onZoomClick);
			reset.addEventListener(MouseEvent.CLICK, onResetClick);
			showruler.addEventListener(MouseEvent.CLICK, onShowRulerClick);
			hideruler.addEventListener(MouseEvent.CLICK, onHideRulerClick);
			
			this.addEventListener(MouseEvent.ROLL_OUT, onToolbarMouseOut);
			this.addEventListener(MouseEvent.ROLL_OVER, onToolbarMouseOver);
			
			//若有动画，创建interactivetoolbar
			if(hasAnimation)
			{
				interactiveToolbar = new Sprite();
				addChild(interactiveToolbar);
				compose = new EasyButton(new compose_default(), _assemble);
				interactiveToolbar.addChild(compose);
				compose.x = 2;
				if(language=="en_US"||language=="es_ES")
					compose.x = 6;
				if(language=="ru_RU")
					compose.x = 0;
				compose.y = 1;
				decompose = new EasyButton(new decompose_default(), _disassemble);
				interactiveToolbar.addChild(decompose);
//				decompose.x = 2 + 49 * 1;
				decompose.x = 2 + compose.width;
				if(language=="en_US"||language=="es_ES")
					decompose.x = 3 + compose.width;
				if(language=="ru_RU")
					decompose.x = 1+ compose.width;
				decompose.y = 1;
				interactiveToolbar.x = toolbar.x + toolbar.width + 20;
				interactiveToolbar.y = toolbar.y;
				
				interactiveToolbar.graphics.clear();
				interactiveToolbar.graphics.beginFill(0, 0.3);
				interactiveToolbar.graphics.drawRoundRect(0, 0, interactiveToolbar.width, interactiveToolbar.height, 25, 25);
				interactiveToolbar.graphics.endFill();
				
				compose.addEventListener(MouseEvent.CLICK, onComposeClick);
				decompose.addEventListener(MouseEvent.CLICK, onDecomposeClick);
			}
			
			//若有说明文字，创建说明文字
			if(hasInstruction)
			{
				mouseDectiveHint = new TextHint(12, false, 0);
				mouseDectiveHint.visible = false;
				addChild(mouseDectiveHint);
			}
		}
		private function logo_onClick(evt:MouseEvent):void
		{
			navigateToURL(new URLRequest("http://fuwu.taobao.com/ser/detail.htm?spm=a1z13.1113643.1113643.15.wCDzlW&service_code=FW_GOODS-1868472&tracelog=search&scm=&ppath=&labels="), "_blank");
		}
		private function onRotateClick(evt:MouseEvent):void
		{
			state = 0;
		}
		private function onMoveClick(evt:MouseEvent):void
		{
			state = 1;
		}
		private function onZoomClick(evt:MouseEvent):void
		{
			state = 2;
		}
		private function onZoomInClick(evt:MouseEvent):void
		{
			zoomIn();
		}
		private function onZoomOutClick(evt:MouseEvent):void
		{
			zoomOut();
		}
		private function onResetClick(evt:MouseEvent):void
		{
			resetMode = true;
			resetTargetAndCamera();
		}
		private function onShowRulerClick(evt:MouseEvent):void
		{
			resetTargetAndCamera();
			
			ruler.visible = !ruler.visible;
			showruler.visible = false;
			hideruler.visible = true;
		}
		private function onHideRulerClick(evt:MouseEvent):void
		{
			ruler.visible = !ruler.visible;
			showruler.visible = true;
			hideruler.visible = false;
		}
		private function onComposeClick(evt:MouseEvent):void
		{
			var i:int;
			var obj3d:Object3D;
			for(i = 0; i < interaction.length; i ++)
			{
				if(interaction[i].frameCount > 0 && interaction[i].matrices)
				{
					obj3d = scene.getChildByName_DeepDown(interaction[i].name);
					if(!obj3d)
						throw new Error("?");
					
					if(!obj3d.animation)
						obj3d.addAnimation(interaction[i], totalAnimationFrame);
					obj3d.inverseAnimation = true;
					obj3d.frameIndex = totalAnimationFrame;
				}
			}
			currentFrameIndex = 0;
			inverseAnimation = true;
			
			if(!totalHint)
			{
				switch(language)
				{
					case "zh_CN":
						totalHint = new TextHint(16, true, 8);
						break;
					default:
						if(language=="ar_SA")
							totalHint = new TextHint(13, true, 8,"ar_SA");
						else
							totalHint = new TextHint(13, true, 8);
						break;
				}
				//totalHint = new TextHint(16, true, 8);
				totalHint.fixedWidth = 260;
				addChild(totalHint);
				totalHint.x = stage.stageWidth - 260;
			}
			totalHint.text = _assembleStep;
		}
		private function onDecomposeClick(evt:MouseEvent):void
		{
			var i:int;
			var obj3d:Object3D;
			for(i = 0; i < interaction.length; i ++)
			{
				if(interaction[i].frameCount > 0 && interaction[i].matrices)
				{
					obj3d = scene.getChildByName_DeepDown(interaction[i].name);
					if(!obj3d)
						throw new Error("?");
					
					if(!obj3d.animation)
						obj3d.addAnimation(interaction[i], totalAnimationFrame);
					obj3d.inverseAnimation = false;
					obj3d.frameIndex = 0;
				}
			}
			currentFrameIndex = 0;
			inverseAnimation = false;
			
			if(!totalHint)
			{
				switch(language)
				{
					case "zh_CN":
						totalHint = new TextHint(16, true, 8);
						break;
					default:
						if(language=="ar_SA")
							totalHint = new TextHint(13, true, 8,"ar_SA");
						else
							totalHint = new TextHint(13, true, 8);
						break;
				}
				//totalHint = new TextHint(16, true, 8);
				totalHint.fixedWidth = 260;
				addChild(totalHint);
				totalHint.x = stage.stageWidth - 260;
			}
			totalHint.text = _disassembleStep;
		}
		private function onFSClick(evt:MouseEvent = null):void
		{
			if(stage.displayState == StageDisplayState.NORMAL)
				stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		private function onEFSClick(evt:MouseEvent):void
		{
			if(stage.displayState == StageDisplayState.FULL_SCREEN)
				stage.displayState = StageDisplayState.NORMAL;
		}
		
		private function onToolbarMouseOut(evt:MouseEvent):void
		{
			toolbar.removeEventListener(Event.ENTER_FRAME, fadeIn);
			toolbar.addEventListener(Event.ENTER_FRAME, fadeOut);
		}
		private function onToolbarMouseOver(evt:MouseEvent):void
		{
			toolbar.removeEventListener(Event.ENTER_FRAME, fadeOut);
			toolbar.addEventListener(Event.ENTER_FRAME, fadeIn);
		}
		
		private function fadeIn(evt:Event):void
		{
			if (toolbar.alpha > 0.8)
			{
				toolbar.alpha = 1;
				if(interactiveToolbar)
					interactiveToolbar.alpha = 1;
				toolbar.removeEventListener(Event.ENTER_FRAME, fadeIn);
				return;
			}
			toolbar.alpha += 0.2;
			if(interactiveToolbar)
				interactiveToolbar.alpha += 0.2;
		}
		private function fadeOut(evt:Event):void
		{
			if (toolbar.alpha < 0.2)
			{
				toolbar.alpha = 0;
				if(interactiveToolbar)
					interactiveToolbar.alpha = 0;
				toolbar.removeEventListener(Event.ENTER_FRAME, fadeOut);
				return;
			}
			toolbar.alpha -= 0.2;
			if(interactiveToolbar)
				interactiveToolbar.alpha -= 0.2;
		}
		
		
		
		/**
		 * state of toolbar. 0: rotate mode; 1: move mode; 2: zoom mode 
		 * @return 
		 * 
		 */		
		private function get state():uint
		{
			return _state;
		}
		private function set state(val:uint):void
		{
			if(_state != val)
			{
				_state = val;
				updateToolbarFacade();
			}
		}
		
		/**
		 * update toolbar facade. 
		 * 
		 */		
		private function updateToolbarFacade():void
		{
			switch (_state)
			{
				case 0:
					rotate.state = EasyButtonState.DOWN_STATE;
					rotate.lockState = true;
					move.lockState = false;
					move.state = EasyButtonState.UP_STATE;
					zoom.lockState = false;
					zoom.state = EasyButtonState.UP_STATE;
					break;
				case 1:
					rotate.lockState = false;
					rotate.state = EasyButtonState.UP_STATE;
					move.state = EasyButtonState.DOWN_STATE;
					move.lockState = true;
					zoom.lockState = false;
					zoom.state = EasyButtonState.UP_STATE;
					break;
				case 2:
					rotate.lockState = false;
					rotate.state = EasyButtonState.UP_STATE;
					move.lockState = false;
					move.state = EasyButtonState.UP_STATE;
					zoom.state = EasyButtonState.DOWN_STATE;
					zoom.lockState = true;
					break;
			}
		}
	}
}