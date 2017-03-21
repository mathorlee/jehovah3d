package
{
	import com.fuwo.math.MyMath;
	
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import flashas3.flvplay.FlvPlay;
	import flashas3.flvplay.VideoTexture;
	
	import jehovah3d.core.pick.MousePickManager;
	import jehovah3d.core.pick.Ray;
	import jehovah3d.core.pick.RectFace;
	
	import panorama.Camera3D;
	import panorama.Object3D;
	
	import utils.easybutton.AdvancedButton;

	public class DoorVisibility
	{
		//design data
		private var points:Array = [];
		private var walls:Array = [];
		private var rooms:Array = [];
		private var panoramaData:Array;
		
		/**
		 * {"matrix": Matrix3D, "position": Vector3D, "clickPosition": Vector3D, "wallName": String, "otherWallName": String, "roomName": String, "otherRoomName": String}<br>
		 * matrix: 矩阵<br>
		 * position: 门洞的位置<br>
		 * clickPosition: 门上按钮的位置<br>
		 * roomName: opening所在的房间的名字<br>
		 * otherRoomName: opening的另一个房间<br>
		 */		
		private var openings:Array = [];
		
		/**
		 * {"position": Vector3D}<br>
		 * position: 相机的位置
		 */		
		private var cameraInfos:Array;
		
		/**
		 * [{"openingName": String, "behindDoorRoomName": String, "boxPosition": Vector3D, "button": AdvancedButton}, ...]<br>
		 * openingName: 门的名字<br>
		 * behindDoorRoomName: 点击门进入的下一个房间的名字<br>
		 * boxPosition: 
		 * button: 
		 */		
		public var visibleDoors:Vector.<Object> = new Vector.<Object>();
		
		private var rectfaces:Vector.<RectFace> = new Vector.<RectFace>();
		
		/**
		 * key: wallName<br>
		 * value: wall
		 */		
		private var wallDict:Dictionary = new Dictionary();
		
		public function DoorVisibility(designData:Object, data:Array)
		{
			points = designData.points;
			walls = designData.walls;
			rooms = designData.rooms;
			openings = designData.openings;
			cameraInfos = new Array();
			panoramaData = data;
			for(var i:int = 0; i < data.length; i ++)
				cameraInfos.push({"position": new Vector3D(data[i].cameraPosition.x, -data[i].cameraPosition.y, data[i].cameraPosition.z)});
			
			init();
			checkDoorVisibility();
		}
		
		
		/**
		 * 判断某房间是否有全景图片
		 * @param roomName
		 * @return 
		 * 
		 */		
		private function doesRoomHasPanorama(roomName:String):Boolean
		{
			var i:int;
			for (i = 0; i < panoramaData.length; i ++)
				if (panoramaData[i].roomName == roomName)
					return true;
			return false;
		}
				
		public function updateButton(renderTaskIndex:int, camera:Camera3D, scene:Object3D):void
		{
			var i:int;
			var j:int;
			for(i = 0; i < visibleDoors.length; i ++)
				for(j = 0; j < visibleDoors[i].length; j ++)
				{
					if (i == renderTaskIndex)
					{
						visibleDoors[i][j].button.visible = true;
						if (!doesRoomHasPanorama(visibleDoors[i][j].behindDoorRoomName))
							visibleDoors[i][j].button.visible = false;
					}
					else
						visibleDoors[i][j].button.visible = false;
				}
			
			var sceneMatrix:Matrix3D = new Matrix3D();
			sceneMatrix.appendRotation(-scene.rotationY / Math.PI * 180, Vector3D.Z_AXIS);
			sceneMatrix.appendRotation(scene.rotationX / Math.PI * 180, Vector3D.X_AXIS);
			for(i = 0; i < visibleDoors[renderTaskIndex].length; i ++)
			{
				if (visibleDoors[renderTaskIndex][i].button.visible)
				{
					var p0:Point = calculateProjectionOfBoxPosition(visibleDoors[renderTaskIndex][i].boxPosition, sceneMatrix, camera.viewWidth, camera.viewHeight, camera.fov);
					visibleDoors[renderTaskIndex][i].button.visible = (p0 != null);
					if(p0)
					{
						visibleDoors[renderTaskIndex][i].button.x = p0.x;
						visibleDoors[renderTaskIndex][i].button.y = p0.y;
					}
				}
			}
		}
		
		private function init():void
		{
			var i:int;
			var j:int;
			var p0:Point;
			var p1:Point;
			var dir:Point;
			var matrix:Matrix3D;
			var inverseMatrix:Matrix3D;
			var v0:Vector3D;
			
			for(i = 0; i < points.length; i ++)
				points[i].y = -points[i].y;
			
			//计算墙的matrix, width
			for(i = 0; i < walls.length; i ++)
			{
				p0 = new Point(points[walls[i].startPointIndex].x, points[walls[i].startPointIndex].y);
				p1 = new Point(points[walls[i].stopPointIndex].x, points[walls[i].stopPointIndex].y);
				walls[i].startPoint = p0;
				walls[i].stopPoint = p1;
				walls[i].x = (p0.x + p1.x) * 0.5;
				walls[i].y = (p0.y + p1.y) * 0.5;
				walls[i].z = 0;
				dir = p1.subtract(p0);
				if(MyMath.isNumberEqual(dir.x, 0) && MyMath.isNumberEqual(dir.y, 0))
				{
					walls[i].width = 0;
					walls[i].isEmpty = 1;
					walls[i].rotationZ = 0;
				}
				else
				{
					walls[i].width = dir.length;
					walls[i].isEmpty = 0;
					dir.normalize(1);
					walls[i].rotationZ = Math.atan2(dir.y, dir.x);
				}
				matrix = new Matrix3D();
				matrix.appendRotation(walls[i].rotationZ / Math.PI * 180, Vector3D.Z_AXIS);
				matrix.appendTranslation(walls[i].x, walls[i].y, walls[i].z);
				walls[i].matrix = matrix;
				inverseMatrix = matrix.clone();
				inverseMatrix.invert();
				walls[i].inverseMatrix = inverseMatrix;
				wallDict[walls[i].name] = walls[i];
			}
			
			//计算墙洞的position, clickPosition, matrix, otherWallName, otherRoomName, wallName, roomName
			for(i = 0; i < openings.length; i ++)
			{
				v0 = Matrix3D(wallDict[openings[i].wallName].matrix).transformVector(new Vector3D(openings[i].wallX, 0, openings[i].z ? openings[i].z : 0));
				openings[i].position = v0;
				openings[i].clickPosition = new Vector3D(v0.x, v0.y, 120);
				matrix = new Matrix3D();
				matrix.appendRotation(getWallOfOpening(openings[i]).rotationZ / Math.PI * 180, Vector3D.Z_AXIS);
				matrix.appendTranslation(v0.x, v0.y, v0.z);
				openings[i].matrix = matrix;
				
				openings[i].roomName = getRoomByWall(getWallByName(openings[i].wallName)).name;
				for(j = 0; j < walls.length; j ++)
				{
					v0 = Matrix3D(walls[j].inverseMatrix).transformVector(openings[i].position);
					if(Math.abs(v0.y) < 0.01 && Math.abs(v0.x) <= walls[j].width / 2)
					{
						if(openings[i].wallName != walls[j].name)
						{
							openings[i].otherWallName = walls[j].name;
							openings[i].otherRoomName = getRoomByWall(getWallByName(openings[i].otherWallName)).name;
							break;
						}
					}
				}
			}
			
			//计算墙体被分成了几段
			var wallOpenings:Array = [];
			for(i = 0; i < walls.length; i ++)
			{
				wallOpenings.length = 0;
				for(j = 0; j < openings.length; j ++)
					if(openings[j].openingType == 0) //墙洞
					{
//						v0 = Matrix3D(walls[i].inverseMatrix).transformVector(openings[j].position);
//						if(Math.abs(v0.y) < 0.01 && v0.x + openings[j].width / 2 <= walls[i].width / 2 && v0.x - openings[j].width / 2 >= -walls[i].width / 2)
						if(openings[j].wallName == walls[i].name || openings[j].otherWallName == walls[i].name)
						{
							wallOpenings.push(MyMath.cloneObject(openings[j]));
							wallOpenings[wallOpenings.length - 1].wallX = v0.x;
						}
					}
				wallOpenings.sortOn("wallX", Array.NUMERIC);
				addRectFaces(walls[i], wallOpenings);
			}
		}
		
		private function checkDoorVisibility():void
		{
			var i:int;
			var j:int;
			
			for(i = 0; i < cameraInfos.length; i ++)
			{
				visibleDoors.push([]);
				for(j = 0; j < openings.length; j ++)
					if(openings[j].openingType == 1)
					{
						if(legalSight(cameraInfos[i].position, openings[j].clickPosition))
							visibleDoors[i].push({"openingName": openings[j].name});
					}
//				trace(cameraInfos[i].roomName, visibleDoors[i].length);
			}
			
			
			var dir0:Vector3D;
			var dir1:Vector3D;
			var dot:Number;
			for(i = 0; i < visibleDoors.length; i ++)
			{
//				trace(cameraInfos[i].roomName);
				for(j = 0; j < visibleDoors[i].length; j ++)
				{
					visibleDoors[i][j].boxPosition = calculateBoxPosition(cameraInfos[i].position, getOpeningByName(visibleDoors[i][j].openingName).clickPosition);
					visibleDoors[i][j].button = createEnterRoomButton();
//					trace("    ", visibleDoors[i][j].boxPosition.x, visibleDoors[i][j].boxPosition.y, visibleDoors[i][j].boxPosition.z);
					
					dir0 = getOpeningByName(visibleDoors[i][j].openingName).clickPosition.subtract(cameraInfos[i].position);
					dir0.normalize();
					dir1 = Matrix3D(getOpeningByName(visibleDoors[i][j].openingName).matrix).deltaTransformVector(Vector3D.Y_AXIS);
					dot = dir0.dotProduct(dir1);
					if(dot > 0)
						visibleDoors[i][j].behindDoorRoomName = getOpeningByName(visibleDoors[i][j].openingName).roomName;
					else
						visibleDoors[i][j].behindDoorRoomName = getOpeningByName(visibleDoors[i][j].openingName).otherRoomName;
					AdvancedButton(visibleDoors[i][j].button).additionalData = {"behindDoorRoomName": visibleDoors[i][j].behindDoorRoomName};
				}
			}
		}
		
		public function calculateBoxPosition(cameraPos:Vector3D, targetPos:Vector3D, cameraFov:Number = Math.PI / 2):Vector3D
		{
			var ret:Vector3D = new Vector3D();
			
			var dir:Vector3D = targetPos.subtract(cameraPos);
			dir.normalize();
			var angle:Number = Math.atan2(dir.y, dir.x);
			if(angle < 0)
				angle += Math.PI * 2;
			
			var matrix:Matrix3D;
			var d0:Vector3D;
			
			if(angle >= Math.PI * 0.75 && angle <= Math.PI * 1.25) //x-
			//if(angle >= 0 && angle < Math.PI / 2) //x-
			{
				matrix = new Matrix3D();
				matrix.appendRotation(-90, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = -1;
				ret.y = d0.x / d0.y;
				ret.z = d0.z / d0.y;
			}
			else if(angle >= Math.PI * 1.25 && angle <= Math.PI * 1.75) //y-
			//else if(angle >= Math.PI / 2 && angle < Math.PI) //y-
			{
				matrix = new Matrix3D();
				matrix.appendRotation(-180, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = -d0.x / d0.y;
				ret.y = -1;
				ret.z = d0.z / d0.y;
			}
			else if((angle >= Math.PI * 1.75 && angle <= Math.PI * 2) || (angle >= 0 && angle <= Math.PI * 0.25)) //x+
			//else if(angle >= Math.PI && angle < Math.PI * 1.5) //x+
			{
				matrix = new Matrix3D();
				matrix.appendRotation(90, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = 1;
				ret.y = -d0.x / d0.y;
				ret.z = d0.z / d0.y;
			}
			else if(angle >= Math.PI / 4 && angle <= Math.PI * 0.75) //y+
			//else if(angle >= Math.PI * 1.5 && angle < Math.PI * 2) //y+
			{
				matrix = new Matrix3D();
				matrix.appendRotation(0, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = d0.x / d0.y;
				ret.y = 1;
				ret.z = d0.z / d0.y;
			}
			
			return ret;
		}
		
		
		/**
		 * 根据相机的坐标和目标的坐标，计算其在全景图box上的坐标。box的尺寸是1*1*1
		 * @param cameraPos
		 * @param targetPos
		 * @param cameraFov
		 * @return 
		 * 
		 */		
		public function calculateBoxPosition2(cameraPos:Vector3D, targetPos:Vector3D, cameraFov:Number = Math.PI / 2):Vector3D
		{
			var ret:Vector3D = new Vector3D();
			
			var dir:Vector3D = targetPos.subtract(cameraPos);
			dir.normalize();
			var angle:Number = Math.atan2(dir.y, dir.x);
			if(angle < 0)
				angle += Math.PI * 2;
			
			var matrix:Matrix3D;
			var d0:Vector3D;
			if(angle >= 0 && angle < Math.PI / 2) //x-
			{
				matrix = new Matrix3D();
				matrix.appendRotation(45, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = -1;
				ret.y = d0.x / d0.y;
				ret.z = d0.z / d0.y;
			}
			else if(angle >= Math.PI / 2 && angle < Math.PI) //y-
			{
				matrix = new Matrix3D();
				matrix.appendRotation(-45, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = -d0.x / d0.y;
				ret.y = -1;
				ret.z = d0.z / d0.y;
			}
			else if(angle >= Math.PI && angle < Math.PI * 1.5) //x+
			{
				matrix = new Matrix3D();
				matrix.appendRotation(-135, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = 1;
				ret.y = -d0.x / d0.y;
				ret.z = d0.z / d0.y;
			}
			else if(angle >= Math.PI * 1.5 && angle < Math.PI * 2) //y+
			{
				matrix = new Matrix3D();
				matrix.appendRotation(135, Vector3D.Z_AXIS);
				d0 = matrix.deltaTransformVector(dir);
				
				ret.x = d0.x / d0.y;
				ret.y = 1;
				ret.z = d0.z / d0.y;
			}
			
			return ret;
		}
		
		
		/**
		 * 
		 * @param boxPosition
		 * @param sceneMatrix
		 * @param viewWidth
		 * @param viewHeight
		 * @return 
		 * 
		 */		
		public function calculateProjectionOfBoxPosition(boxPosition:Vector3D, sceneMatrix:Matrix3D, viewWidth:Number, viewHeight:Number, fov:Number):Point
		{
			var ret:Point = new Point();
			var v0:Vector3D = sceneMatrix.transformVector(boxPosition);
//			trace(boxPosition.x, boxPosition.y, boxPosition.z);
//			trace(v0.x, v0.y, v0.z);
			if(v0.y <= 0)
				return null;
			ret.x = v0.x / v0.y;
			ret.y = v0.z / v0.y;
			ret.x /= Math.tan(fov / 2);
			ret.y /= (Math.tan(fov / 2) / viewWidth * viewHeight);
			if(Math.abs(ret.x) > 1 || Math.abs(ret.y) > 1)
				return null;
//			trace(ret.x, ret.y);
			
			ret.x = ret.x * 0.5 + 0.5;
			ret.y = 0.5 - ret.y * 0.5;
			ret.x *= viewWidth;
			ret.y *= viewHeight;
			return ret;
		}
		private function legalSight(v0:Vector3D, v1:Vector3D):Boolean
		{
			var i:int;
			var intersect:Vector3D;
			var dir:Vector3D = v1.subtract(v0);
			var segLength:Number = dir.length;
			dir.normalize();
			var ray:Ray = new Ray(v0, dir);
			
			for(i = 0; i < rectfaces.length; i ++)
			{
				intersect = MousePickManager.rayRectFaceIntersect(ray, rectfaces[i]);
				if(intersect && intersect.subtract(ray.p0).length + 5 < segLength)
					return false;
			}
			return true;
		}
		
		private function addRectFaces(wall:Object, wallOpenings:Array):void
		{
//			trace("wallOpenings.length: " + wallOpenings.length);
			var rectface:RectFace;
			if(wallOpenings.length == 0)
			{
				rectface = new RectFace(
					new Vector3D(wall.startPoint.x, wall.startPoint.y, wall.height), 
					new Vector3D(wall.startPoint.x, wall.startPoint.y, 0), 
					new Vector3D(wall.stopPoint.x, wall.stopPoint.y, wall.height)
				);
				rectfaces.push(rectface);
				return ;
			}
			
			var i:int;
			var x0:Number = -wall.width / 2;
			for(i = 0; i < wallOpenings.length; i ++)
			{
				rectface = new RectFace(
					new Vector3D(x0, 0, wall.height), 
					new Vector3D(x0, 0, 0), 
					new Vector3D(wallOpenings[i].wallX - wallOpenings[i].width / 2, 0, wall.height)
				);
				rectface = rectface.transform(wall.matrix);
				rectfaces.push(rectface);
				x0 = wallOpenings[i].wallX + wallOpenings[i].width / 2;
			}
			
			rectface = new RectFace(
				new Vector3D(x0, 0, wall.height), 
				new Vector3D(x0, 0, 0), 
				new Vector3D(wall.width / 2, 0, wall.height)
			);
			rectface = rectface.transform(wall.matrix);
			rectfaces.push(rectface);
		}
		
		public function getRoomByName(roomName:String):Object
		{
			var i:int;
			for(i = 0; i < rooms.length; i ++)
				if(rooms[i].name == roomName)
					return rooms[i];
			return null;
		}
		public function getWallByName(wallName:String):Object
		{
			var i:int;
			for(i = 0; i < walls.length; i ++)
				if(walls[i].name == wallName)
					return walls[i];
			return null;
		}
		public function getOpeningByName(openingName:String):Object
		{
			var i:int;
			for(i = 0; i < openings.length; i ++)
				if(openings[i].name == openingName)
					return openings[i];
			return null;
		}
		public function getRoomByWall(wall:Object):Object
		{
			return getRoomByName(wall.roomName);
		}
		public function getWallOfOpening(opening:Object):Object
		{
			return getWallByName(opening.wallName);
		}
		public function getOtherWallOfOpening(opening:Object):Object
		{
			return null;
		}
		
		[Embed(source="assets/out-normal.png", mimeType="image/png")]
		public static const ENTER_ROOM:Class;
		[Embed(source="assets/out-hover.png", mimeType="image/png")]
		public static const ENTER_ROOM_OVER:Class;
		
		public static function createEnterRoomButton():AdvancedButton
		{
			var up:DisplayObject = new ENTER_ROOM();
			var over:DisplayObject = new ENTER_ROOM_OVER();
			over.filters = [new GlowFilter(0xFFFFFF, 0.5, 4, 4)];
			var down:DisplayObject = new ENTER_ROOM();
			down.filters = [new GlowFilter(0x666666, 1, 8, 8)];
			up.x = over.x = down.x = -up.width / 2;
			up.y = over.y = down.y = -up.height / 2;
			return new AdvancedButton(up, over, down);
		}
	}
}