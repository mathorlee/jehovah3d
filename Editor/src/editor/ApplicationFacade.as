package editor
{
	import editor.contorller.init.StartupCommand;
	
	import org.puremvc.as3.patterns.facade.Facade;
	
	public class ApplicationFacade extends Facade
	{
		/**
		 * Application.creationComplete时启动
		 */		
		public static const START:String = "Start";
		
		/**
		 * 舞台发生了缩放<br>
		 * {"width": , "height": }
		 */		
		public static const STAGE_RESIZE:String = "StageResize";
		
		/**
		 * 是否使用程序光选项发生了变化<br>
		 * {"useDefaultLight": Boolean}
		 */		
		public static const USE_DEFAULT_LIGHT:String = "UseDefaultLight";
		
		/**
		 * 更换3D背景色<br>
		 * {"color": uint}
		 */		
		public static const BACKGROUNDCOLOR_CHANGE:String = "BackgroundColorChange";
		
		/**
		 * 更换3D背景图片<br>
		 * {"bitmapData": BitmapData}
		 */		
		public static const BACKGROUNDIMAGE_CHANGE:String = "BackgroundImageChange";
		
		/**
		 * 3D背景图是否显示发生了改变<br>
		 * {"visible": Boolean}
		 */		
		public static const BACKGROUNDIMAGE_VISIBLE_CHANGE:String = "BackgroundImageVisibleChange";
		
		/**
		 * 加载开始，显示进度条
		 */		
		public static const LOAD_START:String = "LoadStart";
		
		/**
		 * 加载进行中，更新进度条<br>
		 * {"percent": Number}
		 */		
		public static const LOAD_PROGRESS:String = "LoadProgress";
		
		/**
		 * 加载结束，隐藏进度条
		 */		
		public static const LOAD_COMPLETE:String = "LoadComplete";
		
		/**
		 * 加载完带有FUWO3D文件的文件序列后，刷新3D场景<br>
		 * {"tasks": Dictionary, "fuwo3d": String}
		 */		
		public static const LOAD_SCENEFILES_COMPLETE:String = "LoadSceneFilesComplete";
		
		/**
		 * 加载完丢失贴图后，刷新3D物体的材质<br>
		 * {"tasks": Dictionary}
		 */		
		public static const LOAD_MISSINGTEXTURES_COMPLETE:String = "LoadMissingTexturesComplete";
		
		/**
		 * 警告当前场景存在多个FUWO3D文件<br>
		 * {"tasks": Dictionary, "fuwo3ds": Vector.<String>}
		 */		
		public static const WARN_MULTI_SCENE:String = "WarnMultiScene";
		
		/**
		 * 警告场景缺少贴图文件<br>
		 * {"missingTextures": Vector.<String>}
		 */		
		public static const WARN_MISSING_TEXTURE:String = "WarnMissingTexture";
		
		/**
		 * 隐藏缺少贴图的窗口
		 */		
		public static const HIDE_MISSINGTEXTURE_WARNING:String = "HideMissingTextureWarning";
		
		/**
		 * 用ParserDAE解析动画完成后，发送这条通知<br>
		 * {parser.parse()}
		 */		
		public static const PARSE_ANIMATION_COMPLETE:String = "ParseAnimationComplete";
		
		/**
		 * 将hex vrscene转化为decimal vrscene后发送这条通知<br>
		 * {"decimalVRScene": String}
		 */		
		public static const POPUP_DECIMAL_VRSCENE:String = "PopupDecimalVRScene";
		public static const DESTROY_DECIMAL_VRSCENE:String = "DestroyDecimalVRScene";
		
		/**
		 * 3D下物体被选中
		 * {"object": Ojbect3D}
		 */		
		public static const OBJECT3D_IS_SELECTED:String = "Object3DIsSelected";
		
		/**
		 * 点击"创建FreeLight"按钮, 添加一个FreeLight
		 */		
		public static const CREATE_FREE_LIGHT:String = "CreateFreeLight";
		
		/**
		 * 相机zNear或zFar发生了改变
		 * {"zNear": Number, "zFar": Number}
		 */		
		public static const CAMERA_ZNEAR_ZFAR_CHANGE:String = "CameraZNearZFarChange";
		
		public function ApplicationFacade()
		{
			super();
		}
		
		public static function getInstance():ApplicationFacade
		{
			if ( instance == null )
				instance = new ApplicationFacade();
			return ApplicationFacade(instance);
		}
		
		override protected function initializeController():void
		{
			super.initializeController();
			registerCommand(START, StartupCommand);
		}
	}
}