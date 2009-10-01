package {
	
	import flash.display.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.xml.*;
	import flash.utils.*;
	import flash.net.*;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.geom.*;
	
	public class Game extends MovieClip{
		//     Members Definition
		
		public const url:String="mapDef.xml";
		
		private var map:Map;
		private var pac:Pacman;
		private var ghostList:Array;
		private var timestamp:Number;
		
		private var keyboardInput:Object;
		private var level:int;
		
		private var xml:XML;
		private var loader:URLLoader;
		private var request:URLRequest;
		
		//     Members Definition
		
		//constructor
		public function Game()
		{
			keyboardInput={left: false, up: false , right: false , down: false};
			ghostList=[];
			timestamp=getTimer();
			level=0;
			
			this.addEventListener(Event.ADDED_TO_STAGE,addedToStageHandler);
		}
		
		
		private function addedToStageHandler(e:Event =null):void
		{
			if(this.hasEventListener(Event.ADDED_TO_STAGE)){
				this.removeEventListener(Event.ADDED_TO_STAGE,addedToStageHandler);
			}
			
			request= new URLRequest(url);
			loader= new URLLoader();
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(Event.COMPLETE, loaderCompleteHandler);
			
			try {
				loader.load(request);
			}
			catch (error:SecurityError)
			{
 				trace("A SecurityError has occurred.");
			}	
		}
			
		private function loaderCompleteHandler(event:Event):void
		{
			try {
				xml = new XML(loader.data);
				init(xml);    
   			 } catch (e:TypeError) {
    			trace("Could not parse the XML file.");
    		}
		}

		private function errorHandler(e:IOErrorEvent):void
		{
			trace( "Had problem loading the XML File.");
		}           

		private function init(dataXml:XML):void
		{
			if(dataXml==null) return;

			var mapXml:XML=dataXml.child("mapdef")[0];
			map=new Map(mapXml);
			
			var pacXml:XML=dataXml.child("pacman")[0];
			pac= new Pacman(new Point(pacXml.@x,pacXml.@y),map);
			
			var gList:XMLList=dataXml.child("ghost");
			i=0;
			for each (var g:XML in gList){
				
				var ghost:Ghost=new Ghost( new Point(g.@x,g.@y), map,i);
				ghostList.push(ghost);
				++i;
			}
			
			this.addChild(map);
			this.addChild(pac);
			for(var i:int=0; i < ghostList.length ;i++){
				this.addChild(ghostList[i]);
			}
			
			this.addEventListener(Event.ENTER_FRAME,update);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyUpHandler);
		}
		
		private function update(e:Event):void
		{
			var time:Number=getTimer();
			
			setPacDirection();
			pac.update(time-timestamp);
			
			var pacpos:Point=pac.getPos();
			var vitaminized:Boolean=pac.isVitaminized();
			
			var ghostPos:Point;
			for(var i:int = 0 ; i < ghostList.length  ; i++ ){
				ghostList[i].update(time-timestamp,vitaminized);
				ghostPos=ghostList[i].getPos();
				if( ghostList[i].getMode() != Ghost.DEAD && 
					(pacpos.toString() == ghostPos.toString() 
						|| (pac.x-ghostList[i].x)*(pac.x-ghostList[i].x)+(pac.y-ghostList[i].y)*(pac.y-ghostList[i].y) <= 10))
				{
					if(vitaminized)
						ghostList[i].die();
					else{
						pac.reset();
						for(var j:int=0;j< ghostList.length;j++){
							ghostList[j].reset();
						}
						break;
					}
				}
			}
			trace(getTimer()-time);
			map.update();
			timestamp=time;
			
			if(!map.hasDots()){
				nextLevel(++level);
			}
			
		}
		
		private function nextLevel(level:int):void{
			var levelOver:LevelOver=new LevelOver();
			levelOver.x=this.width/2;
			levelOver.y=this.height/2;
			this.removeEventListener(Event.ENTER_FRAME,update);
			this.addChild(levelOver);
		}
		
		public function getPacPos():Point
		{
			return pac.getPos();
		}
		
		
		private function setPacDirection():void
		{
			
			if(keyboardInput.left){
				pac.setDirection(Player.Left);
			}else
				if(keyboardInput.right){
					pac.setDirection(Player.Right);
				}
			if(keyboardInput.up){
				pac.setDirection(Player.Up);
			}else
				if(keyboardInput.down){
					pac.setDirection(Player.Down);
				}
			
		}
		
		private function keyDownHandler(e:KeyboardEvent):void
		{
			switch(e.keyCode){
				case Keyboard.LEFT:
					keyboardInput["left"] = true;
					break;
				case Keyboard.UP:
					keyboardInput["up"] = true;
					break;
				case Keyboard.RIGHT:
					keyboardInput["right"] = true;
					break;
				case Keyboard.DOWN:
					keyboardInput["down"] = true;
					break;
				default:
					;
			}
			
		}
		
		private function keyUpHandler(e:KeyboardEvent):void
		{
			switch(e.keyCode){
				case Keyboard.LEFT:
					keyboardInput["left"] = false;
					break;
				case Keyboard.UP:
					keyboardInput["up"] = false;
					break;
				case Keyboard.RIGHT:
					keyboardInput["right"] = false;
					break;
				case Keyboard.DOWN:
					keyboardInput["down"] = false;
					break;
				default:
					;
			}
		}
		
	}
	
}