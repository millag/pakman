package{
	
	import flash.display.*;
	import flash.xml.*;
	import flash.geom.*;
	
	public class Map extends MovieClip{
		
		public const DOT:String="d";
		public const VITAMIN:String="v";
		public const BLANK:String="-"
		
		private var map:Array;
		private var dotCnt:int;
		private var lastEatenDot:String;
		
		//tile dimentions
		private var tilew:Number;
		private var tileh:Number;
		//number of columns
		private var mapWidth:int;
		//number of rows
		private var mapHeight:int;
		//hash for display objects that represent dots                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
		private var dotDisplayList:Object;
		
		//vars for pathfinding
		private var openList:Array;
		private var closedList:Array;
		
		private var startP:Point; 
		private var endP:Point;
		private var pathFound:Boolean;
		private var lastPath:Array;
		
		public function Map(dataXml:XML)
		{
			dotCnt=0;
			lastEatenDot="";
			dotDisplayList={};
			
			openList=[];
			closedList=[];
			startP=new Point();
			endP=new Point();
			
			map=parseMapdef(dataXml);
			init();
		}
		
		protected function parseMapdef(dataXml:XML):Array
		{
			var res:Array=[];
			 mapWidth=0;
			 mapHeight=0;
			 
			if(!dataXml) return res;
			
			var rowList:XMLList=dataXml.child("row");
			if(!rowList.length()) return res;
			res.length=rowList.length();
			
			
			var i:int=0;
			for each(var s:XML in rowList){
				var row:Array=parseRow(s);
				
				if(!row.length){
					return [];
				}
				res[i++]=row;
				
			}
			
			mapHeight=i;
			mapWidth=res[0].length;
			
			return res;
		}
		
		protected function parseRow(rowXml:XML):Array
		{
			var res:Array;
			if (!rowXml) return [];
			var s:String=rowXml.toString();
			res=s.split(',');
			
			return res;
		}
		
		protected function init():void
		{
			var tile:Tile=new Tile();
			tilew=tile.width;
			tileh=tile.height;
			var dot:Dot;
			var vitamin:Vitamin;
			
			
			for(var i:int = 0 ;  i <  mapHeight; i++){
				for(var j:int=0 ; j <  mapWidth ; j++){
					if(isWall(j,i)){
						tile=new Tile();
						tile.x=j*tilew;
						tile.y=i*tileh;
						this.addChild(tile);
					}
					else{
						if(map[i][j] == DOT){
							dot=new Dot();
							dot.x=j*tilew;
							dot.y=i*tileh;
							dotDisplayList["dot_"+j+"_"+i]=dot;
							
							++dotCnt;
							this.addChild(dot);
						}
						else{
							if(map[i][j] == VITAMIN){
								vitamin=new Vitamin();
								vitamin.x=j*tilew;
								vitamin.y=i*tileh;
								dotDisplayList["dot_"+j+"_"+i]=vitamin;
								
								++dotCnt;
								this.addChild(vitamin);
							}
						}
					}
				}
			}
		}
		
		//param in map coords
		public function toWorldCoord(p:Point):Point
		{
			if(!map.length) return null;
			if(!p || p.x < 0 || p.y < 0 || p.x >= mapWidth || p.y >= mapHeight)
				return null;
				
			var res=new Point();
			res.x=p.x*tilew+tilew*0.5;
			res.y=p.y*tileh+tileh*0.5;
			
			return res;
		}
		
		//param in world coords
		public function toMapCoord(p:Point):Point
		{
			var res:Point=new Point();
			if(!map.length || !p) return null;
			
			res.x=(p.x < 0)? (mapWidth-1)*tilew:p.x;
			res.y=(p.y < 0)? (mapHeight-1)*tileh:p.y;
			res.x=(p.x >= mapWidth*tilew)?  0:res.x;
			res.y=(p.y >= mapHeight*tileh)? 0:res.y;
				
			res.x=Math.floor(res.x/tilew);
			res.y=Math.floor(res.y/tileh);
			
			if(isWall(res.x,res.y)) return null;
			
			return res;
		}
		
		public function hasDots():Boolean
		{
			return (dotCnt!=0);
		}
		
		//param in map coords
		public function eatDotAt(p:Point):String
		{
			lastEatenDot="";
			var res:String;
			
			if(!p || isWall(p.x,p.y)) return "";
			
			
			if(map[p.y][p.x] !=BLANK){
				res=map[p.y][p.x];
				lastEatenDot="dot_"+p.x+"_"+p.y;
				map[p.y][p.x]=BLANK;
				--dotCnt;
				return res;
			}
			
			return BLANK;
		}
		
		public function update():void
		{
			if(lastEatenDot){
				var child:DisplayObject=(dotDisplayList[lastEatenDot] as DisplayObject);
				if(child){
					this.removeChild(child);
					dotDisplayList[lastEatenDot]=null;
				}
			}
		}
		
		public function isWall(j:int,i:int):Boolean
		{
			if(j < 0 || j >= mapWidth || i < 0 || i >= mapHeight)
				return false;
			
			var ch:String=map[i][j];
			
			switch(ch){
				case "1": 
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
					return true;
				default:
					return false;
			}
			return false;
		}
		
		
		
		public function findPath(start:Point , end:Point ):Array
		{
			if(!start || !end) return [];
			
			if(start.toString() == startP.toString()  && end.toString()==endP.toString() ){
				if(pathFound)
					return lastPath.slice();
				return [];
			}
			
			startP=start.clone();
			endP=end.clone();
			
			openList=[new NodeStruct(startP)];
			closedList=[];
			pathFound=findpath();
			
			if( pathFound ) return getPath();
			return [];
		}
		
		private function getPath():Array
		{
			lastPath=[];
			var currNode:NodeStruct=closedList[closedList.length-1];
			while( currNode.predecessor != null )
			{
				lastPath.unshift(currNode.pos);
				currNode=currNode.predecessor;
			}
			
			return lastPath.slice();
		}
		
		private function findpath():Boolean
		{
			var skip:Boolean;
			var node:NodeStruct;
			var successors:Array;
			var nodeStruct:NodeStruct;
			
			while(openList.length > 0){
				node=openList.shift();
				
				if(node.pos_str == endP.toString()){
					closedList.push(node);
					return true;
				}
				
				successors = getSuccessors (node.pos);
				for(var i:int=0; i < successors.length ; i++){
					skip=false;
					
					nodeStruct=new NodeStruct(successors[i]);
					nodeStruct.predecessor=node;
					nodeStruct.g= node.g + distance(node.pos, nodeStruct.pos);
					nodeStruct.h= hdistance(nodeStruct.pos, endP);
					nodeStruct.f= nodeStruct.g + nodeStruct.h;
					
					for(var j:int=0; j< openList.length ;j++)
					{
						if (openList[j].pos_str == nodeStruct.pos_str) 
						{
							if( openList[j].f <= nodeStruct.f)
                    			skip = true;
							else openList.splice(j,1);
                            break;
                        }
					}
					if(!skip){
						for(j=0; j< closedList.length ;j++)
						{
							if (closedList[j].pos_str == nodeStruct.pos_str) 
							{
								if( closedList[j].f <= nodeStruct.f)
                    				skip = true;
								else closedList.splice(j,1);
                            	break;
                        	}
						}
					}
					
					if(!skip){
						insert(openList,nodeStruct);
					}
				}
				closedList.push(node);
			}
			trace("imposible finding a path");
			return false;
		}
		
		private function getSuccessors(p:Point):Array
		{
			var res:Array=[];
			
			if( p.x >0 && !isWall(p.x-1,p.y))
				res.push(new Point(p.x-1,p.y));
			
			if( p.y > 0 && !isWall(p.x,p.y-1))
				res.push(new Point(p.x,p.y-1));
				
			if( p.y+1 < mapHeight &&!isWall(p.x,p.y+1))
				res.push(new Point(p.x,p.y+1));
			
			if( p.x+1 < mapWidth && !isWall(p.x+1,p.y))
				res.push(new Point(p.x+1,p.y));
				
			
			return res;
		}
		
		private function distance(p1:Point,p2:Point):Number
		{
			return 1;
		}
		
		private function hdistance(p1:Point , p2:Point):Number
		{
			return Math.abs(p2.x-p1.x) + Math.abs(p2.y-p1.y);
		}
		
		private function insert(arr:Array, item:NodeStruct):void
		{
			var l:int=0;
			var r:int=arr.length-1;
			var mid:int=Math.round((l+r)*0.5);
			
			while(l<=r)
			{
				if(arr[mid].f == item.f) { r=mid; break; }
				if(arr[mid].f < item.f) l=mid+1;
				else r=mid-1;
				mid= Math.round((l+r)*0.5);
 			}
			
			arr.splice(r+1,0,item);
		}
		
	}
	
}

class NodeStruct{
		import flash.geom.Point;
	
		public var pos:Point;
		public var predecessor:NodeStruct;
		public var f:Number;
		public var g:Number;
		public var h:Number;
		public var pos_str:String;
		
		public function NodeStruct(p:Point , fr:Number=0, gr:Number =0, hr:Number= 0, parent:NodeStruct =null){
			pos=p;
			f=fr;
			g=gr;
			h=hr;
			predecessor=parent;
			pos_str=pos.toString();
		}
		
		public function setNodeStruct(p:Point , fr:Number, gr:Number, hr:Number , parent:NodeStruct ){
			pos=p;
			f=fr;
			g=gr;
			h=hr;
			predecessor=parent;
			pos_str=pos.toString();
		}
		
		public function posToString():String{
			return pos_str;
		}
}