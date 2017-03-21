package jehovah3d.parser
{
	import com.fuwo.math.MyMath;
	
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import jehovah3d.Jehovah;
	import jehovah3d.core.Object3D;
	import jehovah3d.core.material.DiffuseMtl;
	import jehovah3d.core.material.StdMtl;
	import jehovah3d.core.material.VrayMtl;
	import jehovah3d.core.mesh.Mesh;
	import jehovah3d.core.resource.GeometryResource;

	public class ParserFUWO3D
	{
		/*
		OBJECT_BLOCK(0x4000)
			TRIANGULAR_MESH(0x4100)
				VERTICES_LIST(0x4110)
				FACES_DESCRIPTION(0x4120)
					FACES_MATERIAL_LIST(0x4130)
					SMOOTHING_GROUPS_LIST(0x4150)
				MAPPING_COOORDINATES_LIST(0x4140)
				LOCAL_COORDINATE_SYSTEM(0x4160)
		*/
		private static const MAIN_CHUNK:uint = 0x4D4D;
		private static const THREED_EDITOR_CHUNCK:uint = 0x3D3D;
		private static const OBJECT_BLOCK:uint = 0x4000; //father: 0x3D3D
		private static const TRIANGULAR_MESH:uint = 0x4100; //father: 0x40000
		private static const VERTICES_LIST:uint = 0x4110; //father: 0x4100
		private static const FACES_DESCRIPTION:uint = 0x4120; //father: 0x4100
		private static const UVFACES_DESCRIPTION:uint = 0x4125; //father: 0x4100
		private static const FACES_MATERIAL_LIST:uint = 0x4130; //father: 0x4120
		private static const MAPPING_COOORDINATES_LIST:uint = 0x4140; //father: 4100
		private static const SMOOTHING_GROUPS_LIST:uint = 0x4150; //father: 0x4120
		private static const LOCAL_COORDINATE_SYSTEM:uint = 0x4160; //0x4100
		
		
		private var _data:ByteArray;
		private var _baseURL:String;
		private var objects:Vector.<ObjectVO>;
		private var materials:Object;
		private var cur_obj:ObjectVO;
		private var cur_obj_end:uint;
		private var cur_mat:MaterialVO;
		private var cur_mat_end:uint;
		
		public function ParserFUWO3D()
		{
			objects = new Vector.<ObjectVO>();
			materials = new Object();
			cur_obj_end = uint.MAX_VALUE;
			cur_mat_end = uint.MAX_VALUE;
		}
		
		public function parse():void
		{
			while(data.bytesAvailable >= 6)
			{
				var id:uint = data.readUnsignedShort();
				var len:uint = data.readUnsignedInt();
				var end:uint = data.position + (len - 6);
//				trace("id: " + id.toString(16));
//				trace(data.position - 6, len, end);
				switch(id)
				{
					case MAIN_CHUNK:
					case THREED_EDITOR_CHUNCK:
						break;
					case MATERIAL_EDITOR_CHUNK:
						cur_mat = new MaterialVO();
						cur_mat_end = end;
						parseMaterial();
						break;
					case OBJECT_BLOCK:
						cur_obj = new ObjectVO();
						cur_obj.name = readNulTermString();
						cur_obj.materialNames = new Vector.<String>();
						cur_obj.materialFaces = {};
						cur_obj_end = end;
						break;
					case TRIANGULAR_MESH:
						break;
					case VERTICES_LIST:
						parseVerticesList();
						break;
					case FACES_DESCRIPTION:
						parseFacesDescription();
						break;
					case UVFACES_DESCRIPTION:
						parseUVFaces();
						break;
					case FACES_MATERIAL_LIST:
						parseFacesMaterialList();
						break;
					case MAPPING_COOORDINATES_LIST:
						parseMappingCoordinatesList();
						break;
					case LOCAL_COORDINATE_SYSTEM:
						parseLocalCoordinateSystem();
						break;
					default:
						data.position += (len - 6);
						break;
				}
//				trace("after: ", data.position, cur_obj_end);
//				trace();
				if(cur_obj && data.position　>=  cur_obj_end)
				{
					objects.push(cur_obj);
					cur_obj_end = uint.MAX_VALUE;
					cur_obj = null;
				}
				if(cur_mat && data.position >= cur_mat_end)
				{
					materials[cur_mat.mtl_name] = cur_mat;
					cur_mat_end = uint.MAX_VALUE;
					cur_mat = null;
				}
			}
		}
		
		
		
		private static const MATERIAL_EDITOR_CHUNK:uint = 0xAFFF; //father: 0x3D3D
		private static const MATERIAL_NAME:uint = 0xA000; //father: 0xAFFF
		private static const MATERIAL_AMBIENT_COLOR:uint = 0xA010; //father: 0xAFFF
		private static const MATERIAL_DIFFUSE_COLOR:uint = 0xA020; //father: 0xAFFF
		private static const MATERIAL_SPECULAR_COLOR:uint = 0xA030; //father: 0xAFFF
		private static const MATERIAL_TRANSPARENCY:uint = 0xA050;
		private static const TWO_SIDED:uint = 0xA081; //father: 0xAFFF
//		private static const TEXTURE_MAP_1:uint = 0xA200; //
//		private static const TEXTURE_MAP_2:uint = 0xA33A; //
		private static const DIFFUSE_MAP:uint = 0xA200; //diffuse mapping.
		private static const SPECULAR_MAP:uint = 0xA204; //specular mapping.
		private static const OPACITY_MAP:uint = 0xA210; //opaque mapping.
		private static const BUMP_MAP:uint = 0xA230; //bump or normal mapping.
		private static const REFLECTION_MAP:uint = 0xA220; //reflection mapping.
		
		private static const SHININESS_PERCENT:uint = 0xA040; //father: 0xAFFF, glossiness
		private static const SHININESS_STRENGTH_PERCENT:uint = 0xA041; //father: 0xAFFF, specular level
		
		private static const MAT_TYPE:uint = 0x9FFF;
		private static const VRAYMTL_REFLECT_COLOR:uint = 0xA060;
		private static const VRAYMTL_HILIGHT_GLOSSINESS:uint = 0xA061;
		private static const VRAYMTL_REFLECT_GLOSSINESS:uint = 0XA062;
		private static const VRAYMTL_HILIGHT_GLOSSINESS_LOCK:uint = 0xA063;
		
		private function parseMaterial():void
		{
			while(data.position < cur_mat_end)
			{
				var id:uint = data.readUnsignedShort();
				var len:uint = data.readUnsignedInt();
				var end:uint = data.position + (len - 6);
				switch(id)
				{
					case MATERIAL_EDITOR_CHUNK:
						break;
					case MATERIAL_NAME:
						cur_mat.mtl_name = readNulTermString();
						break;
					case MATERIAL_AMBIENT_COLOR:
						cur_mat.stdmtl_ambient_color = readColor();
						break;
					case MATERIAL_DIFFUSE_COLOR:
						cur_mat.mtl_diffuse_color = readColor();
						break;
					case MATERIAL_SPECULAR_COLOR:
						cur_mat.stdmtl_specular_color = readColor();
						break;
					case MATERIAL_TRANSPARENCY:
						cur_mat.mtl_transparency = readPercentChunk();
						break;
					case SHININESS_PERCENT:
						cur_mat.stdmtl_glossiness = readPercentChunk();
						break;
					case SHININESS_STRENGTH_PERCENT:
						cur_mat.stdmtl_specular_level = readPercentChunk();
						break;
					case TWO_SIDED:
						cur_mat.mtl_two_sided = true;
						break;
					
					case DIFFUSE_MAP:
						cur_mat.mtl_diffuse_map = parseTexture(end);
						break;
					
					case SPECULAR_MAP:
						cur_mat.mtl_specular_map = parseTexture(end);
						break;
					
					case OPACITY_MAP:
						cur_mat.mtl_opacity_map = parseTexture(end);
						break;
					
					case BUMP_MAP:
						cur_mat.mtl_bump_map = parseTexture(end);
						break;
					
					case REFLECTION_MAP:
						cur_mat.mtl_reflection_map = parseTexture(end);
						break;
					
					//for vraymtl and compatible
					case MAT_TYPE:
						cur_mat.mtl_type = readPercentChunk();
						break;
					case VRAYMTL_REFLECT_COLOR:
						cur_mat.vraymtl_reflect_color = readColor();
						break;
					case VRAYMTL_HILIGHT_GLOSSINESS:
						cur_mat.vraymtl_hilight_glossiness = readPercentChunk();
						break;
					case VRAYMTL_REFLECT_GLOSSINESS:
						cur_mat.vraymtl_reflect_glossiness = readPercentChunk();
						break;
					case VRAYMTL_HILIGHT_GLOSSINESS_LOCK:
						cur_mat.vraymtl_hilight_glossiness_lock = readPercentChunk();
						break;
					default:
						data.position += (len - 6);
						break;
				}
			}
		}
		private function readColor():uint
		{
			var id:uint = data.readUnsignedShort();
			var len:uint = data.readUnsignedInt();
			var r:uint, g:uint, b:uint;
			switch(id)
			{
				case 0x0010: //Floats
					r = data.readFloat() * 255;
					g = data.readFloat() * 255;
					b = data.readFloat() * 255;
					break;
				case 0x0011: //24-bit color
					r = data.readUnsignedByte();
					g = data.readUnsignedByte();
					b = data.readUnsignedByte();
					break;
				default:
					data.position += (len-6);
					break;
			}
			return (r<<16) | (g<<8) | b;
		}
		private function readPercentChunk():Number
		{
			var id:uint = data.readUnsignedShort();
			var len:uint = data.readUnsignedInt();
			var percent:Number;
			switch(id)
			{
				case 0x0030: //int
					percent = data.readUnsignedShort();
					break;
				case 0x0031: //float
					percent = data.readFloat();
					break;
				default:
					data.position += (len-6);
					break;
			}
			return percent;
		}
		private function parseTexture(end:uint):MapVO
		{
			var map:MapVO = new MapVO();
			map.percent = readPercentChunk();
			while (data.position < end)
			{
				var id:uint = data.readUnsignedShort();
				var len:uint = data.readUnsignedInt();
				switch (id)
				{
					case 0xA300: //Mapping Filename
						map.url = readNulTermString();
						break;
					case 0xA354:
						map.scaleU = data.readFloat();
						break;
					case 0xA356:
						map.scaleV = data.readFloat();
						break;
					case 0xA358:
						map.offsetU = data.readFloat();
						break;
					case 0xA35A:
						map.offsetV = data.readFloat();
						break;
					case 0xA35C:
						map.rotateZ = data.readFloat();
						break;
					default:
						data.position += (len-6);
						break;
				}
			}
			return map;
		}
		
		
		
		
		
		
		
		private function parseVerticesList():void
		{
			var count:uint = data.readUnsignedInt();
			cur_obj.vertices = new Vector.<Number>(count * 3);
			var i:uint;
			for(i = 0; i < count * 3; i ++)
				cur_obj.vertices[i] = data.readFloat();
		}
		private function parseFacesDescription():void
		{
			var count:uint = data.readUnsignedInt();
			cur_obj.indices = new Vector.<uint>(count * 3, true);
			var i:uint;
			for(i = 0; i < count; i ++)
			{
				cur_obj.indices[i * 3] = data.readUnsignedInt();
				cur_obj.indices[i * 3 + 1] = data.readUnsignedInt();
				cur_obj.indices[i * 3 + 2] = data.readUnsignedInt();
				data.position += 2;
			}
		}
		private function parseUVFaces():void
		{
			var count:uint = data.readUnsignedInt();
			cur_obj.uvindices = new Vector.<uint>(count * 3, true);
			var i:uint;
			for(i = 0; i < count; i ++)
			{
				cur_obj.uvindices[i * 3 + 0] = data.readUnsignedInt();
				cur_obj.uvindices[i * 3 + 1] = data.readUnsignedInt();
				cur_obj.uvindices[i * 3 + 2] = data.readUnsignedInt();
			}
		}
		private function parseFacesMaterialList():void
		{
			var name:String = readNulTermString();
			var count:uint = data.readUnsignedInt();
			var faces:Vector.<uint> = new Vector.<uint>(count);
			var i:uint;
			for(i = 0; i < count; i ++)
				faces[i] = data.readUnsignedInt();
			cur_obj.materialNames.push(name);
			cur_obj.materialFaces[name] = faces;
		}
		private function parseMappingCoordinatesList():void
		{
			var count:uint = data.readUnsignedInt();
			cur_obj.uvs = new Vector.<Number>(count * 2, true);
			var i:uint;
			for(i = 0; i < count; i ++)
			{
				cur_obj.uvs[i * 2] = data.readFloat();
				cur_obj.uvs[i * 2 + 1] = data.readFloat();
			}
		}
		private function parseLocalCoordinateSystem():void
		{
			cur_obj.transform = new Vector.<Number>();
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(0);
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(0);
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(0);
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(data.readFloat());
			cur_obj.transform.push(1);
		}
		private function readNulTermString():String
		{
			var chr : uint;
			var str : String = new String();
			while ((chr = data.readUnsignedByte()) > 0)
				str += String.fromCharCode(chr);
			return str;
		}
		
		public function parseResult():Vector.<Object3D>
		{
			var i:int;
			var j:int;
			var k:int;
			var materialName:String;
			
			var mDic:Object = new Object();
			var mtl:DiffuseMtl;
			for(materialName in materials)
			{
				var mvo:MaterialVO = materials[materialName];
				if(mvo.mtl_diffuse_map && mvo.mtl_diffuse_map.url == "") mvo.mtl_diffuse_map = null;
				if(mvo.mtl_reflection_map && mvo.mtl_reflection_map.url == "") mvo.mtl_reflection_map = null;
				if(mvo.mtl_specular_map && mvo.mtl_specular_map.url == "") mvo.mtl_specular_map = null;
				if(mvo.mtl_bump_map && mvo.mtl_bump_map.url == "") mvo.mtl_bump_map = null;
				if(mvo.mtl_opacity_map && mvo.mtl_opacity_map.url == "") mvo.mtl_opacity_map = null;
				
				if(mvo.mtl_type == 0)
				{
					mtl = new StdMtl(
						mvo.stdmtl_ambient_color, 
						mvo.mtl_diffuse_color, 
						mvo.stdmtl_specular_color, 
						mvo.stdmtl_specular_level, 
						mvo.stdmtl_glossiness, 
						mvo.mtl_diffuse_map == null ? null : _baseURL + mvo.mtl_diffuse_map.url, 
						mvo.mtl_reflection_map == null ? null : _baseURL + mvo.mtl_reflection_map.url, 
						mvo.mtl_specular_map == null ? null : _baseURL + mvo.mtl_specular_map.url, 
						mvo.mtl_bump_map == null ? null : _baseURL + mvo.mtl_bump_map.url, 
						mvo.mtl_opacity_map == null ? null : _baseURL + mvo.mtl_opacity_map.url
					);
					mtl.disposeTextureResource = true;
				}
				else if(mvo.mtl_type == 1)
				{
					mtl = new VrayMtl(
						mvo.mtl_diffuse_color, 
						mvo.vraymtl_reflect_color, 
						mvo.vraymtl_hilight_glossiness, 
						mvo.vraymtl_reflect_glossiness, 
						mvo.vraymtl_hilight_glossiness_lock, 
						mvo.mtl_diffuse_map == null ? null : _baseURL + mvo.mtl_diffuse_map.url, 
						mvo.mtl_reflection_map == null ? null : _baseURL + mvo.mtl_reflection_map.url, 
						mvo.mtl_specular_map == null ? null : _baseURL + mvo.mtl_specular_map.url, 
						mvo.mtl_bump_map == null ? null : _baseURL + mvo.mtl_bump_map.url, 
						mvo.mtl_opacity_map == null ? null : _baseURL + mvo.mtl_opacity_map.url
					);
					mtl = VrayMtl(mtl).convertToStdMtl();
					mtl.disposeTextureResource = true;
				}
				
				if(mvo.mtl_diffuse_map)
				{
					mvo.mtl_diffuse_map.composeMatrix();
					mtl.diffuseUVMatrix = mvo.mtl_diffuse_map.matrix;
					mtl.diffuseAmount = mvo.mtl_diffuse_map.percent / 100.0;
				}
				if(mvo.mtl_specular_map)
				{
					mvo.mtl_specular_map.composeMatrix();
					mtl.specularUVMatrix = mvo.mtl_specular_map.matrix;
					mtl.specularAmount = mvo.mtl_specular_map.percent / 100.0;
				}
				if(mvo.mtl_reflection_map)
				{
					mvo.mtl_reflection_map.composeMatrix();
					mtl.reflectionUVMatrix = mvo.mtl_reflection_map.matrix;
					mtl.reflectionAmount = mvo.mtl_reflection_map.percent / 100.0;
				}
				if(mvo.mtl_bump_map)
				{
					mvo.mtl_bump_map.composeMatrix();
					mtl.bumpUVMatrix = mvo.mtl_bump_map.matrix;
					mtl.bumpAmount = mvo.mtl_bump_map.percent / 100.0;
				}
				if(mvo.mtl_opacity_map)
				{
					mvo.mtl_opacity_map.composeMatrix();
					mtl.opacityUVMatrix = mvo.mtl_opacity_map.matrix;
					mtl.opacityAmount = mvo.mtl_opacity_map.percent / 100.0;
				}
				if(mvo.mtl_two_sided)
					mtl.doubleSided = true;
				
				mtl.alpha = 1.0 - mvo.mtl_transparency / 100;
				mDic[mvo.mtl_name] = mtl;
			}
			
			var ret:Vector.<Object3D> = new Vector.<Object3D>();
			for(i = 0; i < objects.length; i ++)
			{
				if(objects[i].isEmpty)
					continue;
				if(objects[i].materialNames.length == 0)
				{
					trace(objects[i].name + "has no material!");
					continue;
				}
				
				objects[i].calculateNormal();
				if(objects[i].hasUV)
					splitUV(objects[i]);
				
				var object3d:Object3D = splitBigMesh(objects[i], mDic, Jehovah.maxVertexCountInOneVertexBuffer);
				if(!object3d)
					continue;
				object3d.matrix = objects[i].matrix;;
				ret.push(object3d);
			}
			return ret;
		}
		
		public function splitUV(objVO:ObjectVO):void
		{
			var i:int;
			var j:int;
			var k:int;
			var vi:int;
			var uvi:int;
			
			var newUVs:Vector.<Number> = new Vector.<Number>(objVO.numVertices * 2);
			var visited:Vector.<Boolean> = new Vector.<Boolean>(objVO.numVertices);
			var brothers:Vector.<Vector.<int>> = new Vector.<Vector.<int>>(objVO.numVertices);
			for(i = 0; i < brothers.length; i ++)
				brothers[i] = new Vector.<int>(0);
			
			for(i = 0; i < objVO.numFaces; i ++)
			{
				for(j = 0; j < 3; j ++)
				{
					vi = objVO.indices[3 * i + j]; //顶点索引。
					uvi = objVO.uvindices[3 * i + j]; //UV索引。
					if(visited[vi])
					{
						if(!MyMath.isNumberEqual2(newUVs[vi * 2 + 0], objVO.uvs[uvi * 2 + 0]) || 
							!MyMath.isNumberEqual2(newUVs[vi * 2 + 1], objVO.uvs[uvi * 2 + 1]))
						{
							var find:Boolean = false;
							for(k = 0; k < brothers[vi].length; k ++)
							{
								if(MyMath.isNumberEqual2(newUVs[brothers[vi][k] * 2 + 0], objVO.uvs[uvi * 2 + 0]) && 
									MyMath.isNumberEqual2(newUVs[brothers[vi][k] * 2 + 1], objVO.uvs[uvi * 2 + 1]))
								{
									objVO.indices[3 * i + j] = brothers[vi][k];
									find = true;
									break;
								}
							}
							if(!find)
							{
								brothers[vi].push(objVO.numVertices);
								brothers.push(new Vector.<int>(0));
								newUVs.push(objVO.uvs[uvi * 2 + 0], objVO.uvs[uvi * 2 + 1]);
								objVO.indices[3 * i + j] = objVO.numVertices;
								objVO.vertices.push(objVO.vertices[vi * 3 + 0], objVO.vertices[vi * 3 + 1], objVO.vertices[vi * 3 + 2]);
								objVO.normals.push(objVO.normals[vi * 3 + 0], objVO.normals[vi * 3 + 1], objVO.normals[vi * 3 + 2]);
							}
						}
					}
					else
					{
						visited[vi] = true;
						newUVs[vi * 2 + 0] = objVO.uvs[uvi * 2 + 0];
						newUVs[vi * 2 + 1] = objVO.uvs[uvi * 2 + 1];
					}
				}
			}
			objVO.uvs = newUVs;
			
//			trace("after split uv:");
//			trace("    numVertices: " + objVO.numVertices);
//			trace("    numUVs: " + objVO.numUVs);
//			trace("    numFaces: " + objVO.numFaces);
//			trace();
		}
		
		public function generateSmallMesh(objVO:ObjectVO, mDict:Object):Mesh
		{
			var i:int;
			var j:int;
			var materialName:String;
			var faceList:Vector.<uint>;
			var indices:Vector.<uint> = new Vector.<uint>();
			for(materialName in objVO.materialFaces)
			{
				faceList = objVO.materialFaces[materialName];
				if(faceList.length == 0)
					continue;
				
				for(i = 0; i < faceList.length; i ++)
					indices.push(objVO.indices[faceList[i] * 3 + 0], objVO.indices[faceList[i] * 3 + 1], objVO.indices[faceList[i] * 3 + 2]);
			}
			var mesh:Mesh = new Mesh();
			mesh.name = objVO.name;
			mesh.geometry = new GeometryResource();
			mesh.geometry.coordinateData = objVO.vertices;
			mesh.geometry.indexData = indices;
			if(objVO.uvs)
				mesh.geometry.diffuseUVData = objVO.uvs;
			mesh.geometry.normalData = objVO.normals;
			
			trace("numVertices:", mesh.geometry.numVertices, "numTriangle:", mesh.geometry.numTriangle);
			var faceCnt:int = 0;
			for(materialName in objVO.materialFaces)
			{
				faceList = objVO.materialFaces[materialName];
				if(faceList.length == 0)
					continue;
				
//				mesh.addSurface(mDict[materialName], Vector.<uint>([faceCnt * 3]), Vector.<uint>([faceList.length]));
				trace("indexBegin:", faceCnt * 3, "numTriangle:", faceList.length);
				faceCnt += faceList.length;
			}
			trace();
			return mesh;
		}
		
		public function splitBigMesh(objVO:ObjectVO, mDict:Object, maxVertexCount:int):Object3D
		{
			//顶点数>=2^16
			var i:int;
			var j:int;
			var materialName:String;
			var meshes:Vector.<Mesh> = new Vector.<Mesh>();
			for(materialName in objVO.materialFaces)
			{
				var faceList:Vector.<uint> = objVO.materialFaces[materialName];
				if(faceList.length == 0)
					continue;
				
				var vertices:Vector.<uint> = new Vector.<uint>();
				var indices:Vector.<uint> = new Vector.<uint>();
				
				var map:Vector.<int> = new Vector.<int>(objVO.numVertices); //map[key] = value. key：旧的顶点索引，在ObjectVO.indices；value：新的顶点索引。
				for(i = 0; i < map.length; i ++)
					map[i] = -1;
				
				var v:Vector.<uint> = new Vector.<uint>(3);
				
				for(i = 0; i < faceList.length; i ++)
				{
					v[0] = objVO.indices[faceList[i] * 3 + 0];
					v[1] = objVO.indices[faceList[i] * 3 + 1];
					v[2] = objVO.indices[faceList[i] * 3 + 2];
					for(j = 0; j < 3; j ++)
					{
						if(map[v[j]] == -1)
						{
							map[v[j]] = vertices.length; //记录新的顶点索引。
							indices.push(vertices.length); //添加顶点索引。
							vertices.push(v[j]);
						}
						else
						{
							indices.push(map[v[j]]); //添加顶点索引。
						}
					}
					
					if(vertices.length == maxVertexCount || vertices.length == maxVertexCount - 1 || vertices.length == maxVertexCount - 2 || i == faceList.length - 1) //分割mesh。
					{
						var coordinateData:Vector.<Number> = new Vector.<Number>();
						var diffuseUVData:Vector.<Number> = new Vector.<Number>();
						var normalData:Vector.<Number> = new Vector.<Number>();
						for(j = 0; j < vertices.length; j ++)
						{
							coordinateData.push(objVO.vertices[vertices[j] * 3 + 0], objVO.vertices[vertices[j] * 3 + 1],objVO.vertices[vertices[j] * 3 + 2]);
							if(DiffuseMtl(mDict[materialName]).needUVWData && objVO.uvs)
								diffuseUVData.push(objVO.uvs[vertices[j] * 2 + 0], objVO.uvs[vertices[j] * 2 + 1]);
							normalData.push(objVO.normals[vertices[j] * 3 + 0], objVO.normals[vertices[j] * 3 + 1], objVO.normals[vertices[j] * 3 + 2]);
						}
						var mesh:Mesh = new Mesh();
						mesh.name = objVO.name;
						mesh.geometry = new GeometryResource();
						mesh.geometry.coordinateData = coordinateData;
						if(DiffuseMtl(mDict[materialName]).needUVWData && objVO.uvs)
							mesh.geometry.diffuseUVData = diffuseUVData;
						mesh.geometry.normalData = normalData;
						mesh.geometry.indexData = indices;
						if(DiffuseMtl(mDict[materialName]).needBump)
							mesh.geometry.calculateTangent();
						mesh.mtl = mDict[materialName];
						meshes.push(mesh);
						
						//初始化vertices, indices, map，继续分割。
						for(j = 0; j < map.length; j ++)
							map[j] = -1;
						vertices.length = 0;
						indices.length = 0;
					}
				}
			}
			
			if(meshes.length == 1)
				return meshes[0];
			if(meshes.length == 0)
				return null;
			var ret:Object3D = new Object3D();
			ret.name = objVO.name;
			for(i = 0; i < meshes.length; i ++)
				ret.addChild(meshes[i]);
			return ret;
		}
		
		public function get data():ByteArray
		{
			return _data;
		}
		public function set data(val:ByteArray):void
		{
			if(_data != val)
			{
				_data = val;
				_data.endian = Endian.LITTLE_ENDIAN;
			}
		}
		public function get baseURL():String
		{
			return _baseURL;
		}
		public function set baseURL(val:String):void
		{
			if(_baseURL != val)
				_baseURL = val;
		}
	}
}
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Vector3D;

internal class MapVO
{
	public var percent:Number;
	public var url:String;
	public var offsetU:Number = 0;
	public var offsetV:Number = 0;
	public var scaleU:Number = 1;
	public var scaleV:Number = 1;
	public var rotateZ:Number = 0;
	public var matrix:Matrix;
	
	public function composeMatrix():void
	{
		matrix = new Matrix();
		
		matrix.translate(0.5 / scaleU, 0.5/scaleV);
		matrix.translate(-offsetU, -offsetV);
		matrix.rotate(-rotateZ / 180 * Math.PI);
		matrix.translate(-0.5, -0.5);
		matrix.scale(scaleU, scaleV);
		
		var vInverseMatrix:Matrix = new Matrix(1, 0, 0, -1, 0, 1);
		matrix.concat(vInverseMatrix);
	}
}

internal class MaterialVO
{
	/*
	mtl_type(0: stdmtl, 1: vraymtl)
	mtl_name
	mtl_two_sided
	mtl_diffuse_color
	
	stdmtl_ambient_color
	stdmtl_specular_color
	stdmtl_specular_level
	stdmtl_glossiness
	
	vraymtl_reflect_color
	vraymtl_hilight_glossiness
	vraymtl_reflect_glossiness
	vraymtl_hilight_glossiness_lock
	
	mtl_diffuse_map
	*/
	public var mtl_type:uint;
	public var mtl_name:String;
	public var mtl_two_sided:Boolean;
	public var mtl_diffuse_color:uint;
	public var mtl_transparency:Number = 100;
	
	public var stdmtl_ambient_color:uint;
	public var stdmtl_specular_color:uint;
	public var stdmtl_specular_level:Number;
	public var stdmtl_glossiness:Number;
	
	public var vraymtl_reflect_color:uint;
	public var vraymtl_hilight_glossiness:Number;
	public var vraymtl_reflect_glossiness:Number;
	public var vraymtl_hilight_glossiness_lock:uint = uint.MAX_VALUE;
	
	public var mtl_diffuse_map:MapVO;
	public var mtl_specular_map:MapVO;
	public var mtl_opacity_map:MapVO;
	public var mtl_bump_map:MapVO;
	public var mtl_reflection_map:MapVO;
}

internal class ObjectVO
{
	public var name:String;
	public var transform:Vector.<Number>;
	public var vertices:Vector.<Number>;
	public var indices:Vector.<uint>;
	public var uvindices:Vector.<uint>;
	public var uvs:Vector.<Number>;
	public var normals:Vector.<Number>;
	public var materialFaces:Object;
	public var materialNames:Vector.<String>;
	
	public function get matrix():Matrix3D
	{
		var mat:Matrix3D = new Matrix3D(transform);
		return mat;
	}
	public function get numVertices():int
	{
		return vertices.length / 3;
	}
	public function get numUVs():int
	{
		return uvs.length / 2;
	}
	public function get numFaces():int
	{
		return indices.length / 3;
	}
	public function get hasUV():Boolean
	{
		return uvs != null && uvindices != null;
	}
	public function get isEmpty():Boolean
	{
		if(vertices == null || indices == null)
			return true;
		if(vertices.length == 0 || indices.length == 0)
			return true;
		return false;
	}
	public function calculateNormal():void
	{
		normals = new Vector.<Number>(numVertices * 3);
		var i:int;
		for(i = 0; i < indices.length / 3; i ++)
		{
			var index1:uint = indices[3 * i];
			var index2:uint = indices[3 * i + 1];
			var index3:uint = indices[3 * i + 2];
			var edge1:Vector3D = new Vector3D(
				vertices[index2 * 3] - vertices[index1 * 3], 
				vertices[index2 * 3 + 1] - vertices[index1 * 3 + 1], 
				vertices[index2 * 3 + 2] - vertices[index1 * 3 + 2]
			);
			var edge2:Vector3D = new Vector3D(
				vertices[index3 * 3] - vertices[index1 * 3], 
				vertices[index3 * 3 + 1] - vertices[index1 * 3 + 1], 
				vertices[index3 * 3 + 2] - vertices[index1 * 3 + 2]
			);
			var cp:Vector3D = edge1.crossProduct(edge2);
			cp.normalize(); //normalize or not, different result. To be tested.
			normals[index1 * 3] += cp.x;
			normals[index1 * 3 + 1] += cp.y;
			normals[index1 * 3 + 2] += cp.z;
			normals[index2 * 3] += cp.x;
			normals[index2 * 3 + 1] += cp.y;
			normals[index2 * 3 + 2] += cp.z;
			normals[index3 * 3] += cp.x;
			normals[index3 * 3 + 1] += cp.y;
			normals[index3 * 3 + 2] += cp.z;
		}
		
		//normalize normals.
		var length:Number;
		for(i = 0; i < numVertices; i ++)
		{
			length = Math.sqrt(normals[i * 3 + 0] * normals[i * 3 + 0] + normals[i * 3 + 1] * normals[i * 3 + 1] + normals[i * 3 + 2] * normals[i * 3 + 2]);
			if(length == 0)
				continue;
			normals[i * 3 + 0] /= length;
			normals[i * 3 + 1] /= length;
			normals[i * 3 + 2] /= length;
		}
	}
	
}
