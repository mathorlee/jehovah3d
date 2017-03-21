package flashas3.preloader
{
	import flash.display.*;
	import utils.loadingbar.LoadingBar;

	/**              
	 * 功能：SWF自身的加载条              
	 * 用法：在需要实现自加载的类声明前加上
	 * [Frame(factoryClass="flashas3.preloader.Preloader")]             
	 *             
	 */
	public class Preloader extends MovieClip
	{
		/**              
		 * 是否本地运行               
		 */
		protected var mNative:Boolean;              
		/**              
		 * 模拟当前加载量(本地运行时)              
		 */
		protected var mIndex:int = 0;              
		/**              
		 * 模拟最大加载量(本地运行时)              
		 */
		protected const mMax:int = 100;
		//进度条
		private var loadingBar:LoadingBar;
		//背景图
		[Embed(source="/assets/scene0/bg.jpg", mimeType="image/jpeg")]
		private var TEXTURE_BG:Class;
		private var backgroundImage:Bitmap;
		
		public function Preloader()
		{
			addEventListener("addedToStage", addedToStageHandler); 
		}
		
		protected function addedToStageHandler(e:*):void
		{   
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			this.backgroundImage = new TEXTURE_BG();
			this.loadingBar = new LoadingBar();
			this.addChild(this.backgroundImage);
			this.addChild(this.loadingBar);
			this.loadingBar.x = stage.stageWidth/2;
			this.loadingBar.y = stage.stageHeight/2;
			removeEventListener("addedToStage", addedToStageHandler);              
			//如果已经加载完，那估计就是本地运行了，这时候我们搞个假的Preloader了              
			mNative = loaderInfo.bytesLoaded == loaderInfo.bytesTotal;              
			addListeners();              
		}
		
		/**              
		 *               
		 * 侦听加载事件              
		 */  
		protected function addListeners():void
		{              
			if(mNative)              
				addEventListener("enterFrame", enterFrameHandler);              
			else
			{              
				loaderInfo.addEventListener("progress", progressHandler);              
				loaderInfo.addEventListener("complete", completeHandler);
			}              
		}  
		
		/**              
		 *               
		 * 移除加载事件              
		 */  
		protected function removeListeners():void
		{              
			if(mNative)              
				removeEventListener("enterFrame", enterFrameHandler);              
			else
			{              
				loaderInfo.removeEventListener("progress", progressHandler);              
				loaderInfo.removeEventListener("complete", completeHandler);              
			}              
		}  
		
		/**              
		 * 用ENTER_FRAME模拟加载事件(本地运行时)              
		 * @param e              
		 *               
		 */  
		protected function enterFrameHandler(e:*):void
		{      
			completeHandler();
		}   
		
		/**              
		 * 显示进度条              
		 * @param value 进度比 0.0 ~ 1.0              
		 *               
		 */  
		protected function setProgress(value:Number):void
		{              
			this.loadingBar.percent(value,1);
		}              
		/**              
		 * 加载事件              
		 * @param e              
		 *               
		 */  
		protected function progressHandler(e:*):void
		{              
			setProgress(loaderInfo.bytesLoaded/loaderInfo.bytesTotal)              
		}     
		
		protected function completeHandler(e:*=null):void
		{             
			this.loadingBar.percent(1,1);
			removeListeners();              
			addEventListener("enterFrame", init);              
		} 
		
		/**              
		 * 加载完成后 构造主程序              
		 */
		protected function init(e:*):void
		{              
			/*currentLabels[1].name 获得第二帧的标签 也就是主程序的类名以"_"连接如：
            com_adobe_class_Main,我们需要将其转换为com.adobe.class::Main这样的格式 */             
			var prefix:Array = currentLabels[1].name.split("_");              
			var suffix:String = prefix.pop();              
			var cName:String =  prefix.join(".") + "::" + suffix;              
			//判断是否存在主程序的类              
			if(loaderInfo.applicationDomain.hasDefinition(cName))              
			{              
				//知道存在主程序的类了，删除enterFrame的侦听              
				removeEventListener("enterFrame", init);              
				
				var clas:Class = loaderInfo.applicationDomain.getDefinition(cName) as Class;              
				var main:DisplayObject = new clas();              
				parent.addChild( main );              
				parent.removeChild(this);              
			}              
		}     
	}
}