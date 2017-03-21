package editor.view.mediator
{
	import com.fuwo.math.MyMath;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	import flash.xml.XMLDocument;
	
	import mx.events.FlexEvent;
	import mx.rpc.xml.SimpleXMLDecoder;
	
	import editor.ApplicationFacade;
	import editor.view.Load;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.light.FreeLight3D;
	import jehovah3d.parser.ParserDAE;
	
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	import utils.HexToDecimal;
	import utils.file.AdvancedFileFeferenceList;
	
	public class LoadMediator extends Mediator
	{
		public static const NAME:String = 'LoadMediator';
		private var multiFileReference:AdvancedFileFeferenceList;
		private var singleFileReference:FileReference;
		
		public function LoadMediator(mediatorName:String=null, viewComponent:Object=null)
		{
			super(mediatorName, viewComponent);
		}
		
		override public function onRegister():void
		{
			view.loadButton.addEventListener(MouseEvent.CLICK, onLoadClick);
			view.exportSettingBTN.addEventListener(MouseEvent.CLICK, onExportSettingClick);
			view.loadAnimation.addEventListener(MouseEvent.CLICK, onLoadAnimationClick);
			view.hexVRToDecimalVR.addEventListener(MouseEvent.CLICK, onHexVRToDecimalVRClick);
//			view.lzmaCompressBTN.addEventListener(MouseEvent.CLICK, onLAMACompressClick);
//			view.lzmaUncompressBTN.addEventListener(MouseEvent.CLICK, onLZMAUncompressClick);
			view.useDefaultLightCB.addEventListener(Event.CHANGE, onUseDefaultLightChange);
			
			view.ambientTI.text = "0.5";
			view.diffuseTI.text = "0.6";
			view.ambientTI.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			view.ambientTI.addEventListener(FlexEvent.ENTER, onEnter);
			view.diffuseTI.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			view.diffuseTI.addEventListener(FlexEvent.ENTER, onEnter);
			view.zNearTI.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			view.zNearTI.addEventListener(FlexEvent.ENTER, onEnter);
			view.zFarTI.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
			view.zFarTI.addEventListener(FlexEvent.ENTER, onEnter);
		}
		private function onFocusOut(evt:FocusEvent):void
		{
			onChange(evt.currentTarget);
		}
		private function onEnter(evt:FlexEvent):void
		{
			Scene3DMediator(facade.retrieveMediator(Scene3DMediator.NAME)).view.setFocus();
		}
		private function onChange(target:Object):void
		{
			switch(target)
			{
				case view.ambientTI:
					Jehovah.ambientCoefficient = Number(view.ambientTI.text);
					break;
				
				case view.diffuseTI:
					Jehovah.diffuseCoefficient = Number(view.diffuseTI.text);
					break;
				
				case view.zNearTI:
					if(Jehovah.camera)
						Jehovah.camera.zNear = Number(view.zNearTI.text);
					break;
				
				case view.zFarTI:
					if(Jehovah.camera)
						Jehovah.camera.zFar = Number(view.zFarTI.text);
					break;
				
				default:
					break;
			}
		}
		
		private function onLoadClick(evt:MouseEvent):void
		{
			if(!multiFileReference)
			{
				multiFileReference = new AdvancedFileFeferenceList();
				multiFileReference.addEventListener(AdvancedFileFeferenceList.START_LOADING, onStart);
				multiFileReference.addEventListener(Event.COMPLETE, onFilesComplete);
				multiFileReference.addEventListener(ProgressEvent.PROGRESS, onFilesProgress);
			}
			var filter:FileFilter = new FileFilter("爱福窝3D秀资源文件(*.FUWO3D, *.F3D, *.OBJ, *.jpg, *.png, *.bmp, *.tga)", "*.FUWO3D;*.F3D;*.OBJ;*.jpg;*.png;*.bmp;*.tga");
			multiFileReference.browse([filter, AdvancedFileFeferenceList.allFileFilter("所有文件(*.*)")]);
		}
		private function onExportSettingClick(evt:MouseEvent):void
		{
			var obj:Object = {};
			obj.ambientCoefficient = Jehovah.ambientCoefficient;
			obj.diffuseCoefficient = Jehovah.diffuseCoefficient;
			obj.useDefaultLight = int(Jehovah.useDefaultLight);
			if(!obj.useDefaultLight)
			{
				var lights:Array = [];
				var i:int;
				for(i = 0; i < Jehovah.lights.length; i ++)
					if(Jehovah.lights[i] is FreeLight3D)
						lights.push(FreeLight3D(Jehovah.lights[i]).toObject());
				obj.lights = lights;
				
				//写入AO信息
				var ao:Object = {};
				ao.useSSAO = int(Jehovah.useSSAO);
				if(ao.useSSAO)
				{
					ao.scale = Number(view.ao.scaleTI.text);
					ao.bias = Number(view.ao.biasTI.text);
					ao.sampleRadius = Number(view.ao.sampleRadiusTI.text);
					ao.intensity = Number(view.ao.intensityTI.text);
				}
				obj.ao = ao;
			}
			var setting:String = JSON.stringify(obj);
			var ff:FileReference = new FileReference();
			ff.save(JSON.stringify(obj), "setting.json");
		}
		private function onUseDefaultLightChange(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.USE_DEFAULT_LIGHT, {"useDefaultLight": view.useDefaultLightCB.selected}, null);
		}
		
		private function onStart(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_START, null, null);
		}
		
		private function onFilesComplete(evt:Event):void
		{
//			trace("onFilesComplete");
			var fuwo3ds:Vector.<String> = new Vector.<String>();
			for(var key:* in multiFileReference.tasks)
			{
				if(multiFileReference.tasks[key].extension == "FUWO3D" || multiFileReference.tasks[key].extension == "F3D" || multiFileReference.tasks[key].extension == "OBJ")
					fuwo3ds.push(key);
			}
			if(fuwo3ds.length == 0) //无fuwo3d
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
			else if(fuwo3ds.length == 1)
			{
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
				facade.sendNotification(ApplicationFacade.HIDE_MISSINGTEXTURE_WARNING, null, null);
				facade.sendNotification(ApplicationFacade.LOAD_SCENEFILES_COMPLETE, {"tasks": multiFileReference.tasks, "fuwo3d": fuwo3ds[0]}, null);
			}
			else if(fuwo3ds.length > 1)
			{
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
				facade.sendNotification(ApplicationFacade.HIDE_MISSINGTEXTURE_WARNING, null, null);
				facade.sendNotification(ApplicationFacade.WARN_MULTI_SCENE, {"tasks": multiFileReference.tasks, "fuwo3ds": fuwo3ds}, null);
			}
		}
		
		private function onFilesProgress(evt:ProgressEvent):void
		{
//			trace("onFilesProgress");
//			trace(evt.bytesLoaded / evt.bytesTotal);
			facade.sendNotification(ApplicationFacade.LOAD_PROGRESS, {"percent": evt.bytesLoaded / evt.bytesTotal}, null);
		}
		
		//加载XML
		private function onLoadAnimationClick(evt:MouseEvent):void
		{
			if(!singleFileReference)
			{
				singleFileReference = new FileReference();
				singleFileReference.addEventListener(Event.SELECT, onFileSelected);
				singleFileReference.addEventListener(Event.CANCEL, onCancel);
				singleFileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				singleFileReference.addEventListener(Event.COMPLETE, onAnimationComplete);
			}
			singleFileReference.browse([new FileFilter("Autodesk Collada (*.DAE)", "*.DAE")]);
		}
		private function onHexVRToDecimalVRClick(evt:MouseEvent):void
		{
			if(!singleFileReference)
			{
				singleFileReference = new FileReference();
				singleFileReference.addEventListener(Event.SELECT, onFileSelected);
				singleFileReference.addEventListener(Event.CANCEL, onCancel);
				singleFileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				singleFileReference.addEventListener(Event.COMPLETE, onVRSceneComplete);
			}
			singleFileReference.browse([new FileFilter("VR-Scene", "*.vrscene")]);
		}
		
		private function onLAMACompressClick(evt:MouseEvent):void
		{
			if(!singleFileReference)
			{
				singleFileReference = new FileReference();
				singleFileReference.addEventListener(Event.SELECT, onFileSelected);
				singleFileReference.addEventListener(Event.CANCEL, onCancel);
				singleFileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				singleFileReference.addEventListener(Event.COMPLETE, onCompressComplete);
			}
			singleFileReference.browse([new FileFilter("lzma压缩", "*.*")]);
		}
		
		private function onLZMAUncompressClick(evt:MouseEvent):void
		{
			if(!singleFileReference)
			{
				singleFileReference = new FileReference();
				singleFileReference.addEventListener(Event.SELECT, onFileSelected);
				singleFileReference.addEventListener(Event.CANCEL, onCancel);
				singleFileReference.addEventListener(ProgressEvent.PROGRESS, onProgress);
				singleFileReference.addEventListener(Event.COMPLETE, onUncompressComplete);
			}
			singleFileReference.browse([new FileFilter("lzma解压缩", "*.*")]);
		}
		
		private function onFileSelected(evt:Event):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_START, null, null);
			singleFileReference.load();
		}
		public function onCancel(evt:Event):void
		{
			
		}
		private function onProgress(evt:ProgressEvent):void
		{
			facade.sendNotification(ApplicationFacade.LOAD_PROGRESS, {"percent": evt.bytesLoaded / evt.bytesTotal}, null);
		}
		private function onAnimationComplete(evt:Event):void
		{
			var fileExtention:String = MyMath.analysisFileExtentionFromURL(evt.target.name).toUpperCase();
			var data:ByteArray = evt.target.data as ByteArray;
			if(fileExtention == "DAE")
			{
				var str:String = data.readUTFBytes(data.length);
				var xmlDoc:XMLDocument = new XMLDocument();
				xmlDoc.parseXML(str);
				var decoder:SimpleXMLDecoder = new SimpleXMLDecoder();
				var obj:Object = decoder.decodeXML(xmlDoc);
				var parser:ParserDAE = new ParserDAE();
				var result:Object = parser.parse(obj);
				
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
				facade.sendNotification(ApplicationFacade.PARSE_ANIMATION_COMPLETE, result, null);
			}
			else
			{
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
			}
		}
		private function onVRSceneComplete(evt:Event):void
		{
			var fileExtention:String = MyMath.analysisFileExtentionFromURL(evt.target.name).toUpperCase();
			var data:ByteArray = evt.target.data as ByteArray;
			if(fileExtention == "VRSCENE")
			{
				var str:String = data.readUTFBytes(data.length);
				str = HexToDecimal.hexVRSceneToDecimalVRScene(str);
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
				facade.sendNotification(ApplicationFacade.POPUP_DECIMAL_VRSCENE, {"decimalVRScene": str}, null);
			}
			else
			{
				facade.sendNotification(ApplicationFacade.LOAD_COMPLETE, null, null);
			}
		}
		
		private function onCompressComplete(evt:Event):void
		{
			var data:ByteArray = evt.target.data as ByteArray;
			data.compress(CompressionAlgorithm.LZMA);
		}
		
		private function onUncompressComplete(evt:Event):void
		{
			var data:ByteArray = evt.target.data as ByteArray;
			data.uncompress(CompressionAlgorithm.LZMA);
		}
		
		override public function listNotificationInterests():Array
		{
			return [
				ApplicationFacade.USE_DEFAULT_LIGHT, 
				ApplicationFacade.CAMERA_ZNEAR_ZFAR_CHANGE
			];
		}
		override public function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case ApplicationFacade.USE_DEFAULT_LIGHT:
					view.ao.visible = Boolean(1 - notification.getBody().useDefaultLight);
					break;
				
				case ApplicationFacade.CAMERA_ZNEAR_ZFAR_CHANGE:
					var data:Object = notification.getBody();
					if(data.zNear < data.zFar && data.zNear > 0 && data.zFar > 0)
					{
						view.zNearTI.text = String(data.zNear);
						view.zFarTI.text = String(data.zFar);
					}
					break;
				
				default:
					break;
			}
		}
		
		public function get view():Load
		{
			return viewComponent as Load;
		}
	}
}