package scenes.game.components
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import constraints.Constraint;
	import constraints.ConstraintVar;
	
	import display.BasicButton;
	import display.MapHideButton;
	import display.MapShowButton;
	
	import events.MiniMapEvent;
	import events.MoveEvent;
	import events.WidgetChangeEvent;
	
	import scenes.BaseComponent;
	import scenes.game.display.ClauseNode;
	import scenes.game.display.Level;
	import scenes.game.display.Node;
	import scenes.game.display.NodeSkin;
	
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.PropDictionary;
	import utils.XMath;
	
	public class MiniMap extends BaseComponent
	{
		public static const WIDTH:Number = 58;
		public static const HEIGHT:Number = 58;
		
		public static const HIDDEN_Y:Number = HEIGHT * 60.0 / 268.0 - HEIGHT;
		public static const TOP_Y:Number = 255;
		public static const SHOWN_Y:Number = 0;
		
		public static const CLICK_AREA:Rectangle = new Rectangle(0,0,WIDTH, HEIGHT);//WIDTH * 44.0 / 280.0, 0.0, (1.0 - 44.0 / 280.0) * WIDTH, (1.0 - 62.0 / 268.0) * HEIGHT);
		public static const VIEW_AREA:Rectangle = CLICK_AREA.clone();
		{
			VIEW_AREA.inflate( -15.0 * WIDTH / 280.0, -15.0 * HEIGHT / 268.0);
		}
		public static const HIDE_SHOW_BUTTON_LOC:Point = new Point(CLICK_AREA.x + 0.5 * CLICK_AREA.width, CLICK_AREA.bottom + 2);
		private static const HIDE_SHOW_TIME_SEC:Number = 0.8;
		
		private static const MIN_ICON_SIZE:Number = 4;
		
		protected var nodeErrorDict:Dictionary = new Dictionary();
		protected var currentLevel:Level;
		protected var backgroundImage:Image;
		protected var gameNodeLayer:Sprite;
		protected var errorLayer:Sprite;
		protected var viewRectLayer:Sprite;
		private var m_clickPane:Quad; // clickable area
		private var m_showButton:BasicButton;
		private var m_hideButton:BasicButton;
		private var m_hidden:Boolean = true;
		private var m_hiding:Boolean = false; // true if animating up to hide
		private var m_showing:Boolean = false; // true if animating down to show
		
		private var m_viewSpaceIndicator:Sprite;
		private var m_viewSpaceQuads:Vector.<Quad>;
		
		private var m_contentX:Number;
		private var m_contentY:Number;
		private var m_contentScale:Number;
		public var isDirty:Boolean;
		public var imageIsDirty:Boolean;
		protected var nodeBitmapData:BitmapData;
		protected var bitmapImage:Image;
		protected var bitmapTexture:Texture;
		protected var wideColor:int;
		protected var narrowColor:int;
		protected var errorColor:int = 0xFFFF0000;
		
		private var showNumConflicts:Boolean = false;
		private var numConflictsTextField:TextFieldHack;
		static public var numConflicts:int;
		static public var maxNumConflicts:int;
		
		public function MiniMap()
		{
			super();
			
			width = WIDTH;
			height = HEIGHT;
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			
			gameNodeLayer = new Sprite();
			addChild(gameNodeLayer);
			errorLayer = new Sprite();
			addChild(errorLayer);
			viewRectLayer = new Sprite();
			viewRectLayer.visible = false;
			addChild(viewRectLayer);
			m_clickPane = new Quad(CLICK_AREA.width / scaleX, CLICK_AREA.height / scaleY);
			m_clickPane.alpha = 0;
			m_clickPane.x = CLICK_AREA.x / scaleX;
			m_clickPane.y = CLICK_AREA.y / scaleY;
			addChild(m_clickPane);
			
//			m_showButton = new MapShowButton();
//			m_showButton.addEventListener(Event.TRIGGERED, showMap);
//			m_hideButton = new MapHideButton();
//			m_hideButton.addEventListener(Event.TRIGGERED, hideMap);
//			m_showButton.x = m_hideButton.x = HIDE_SHOW_BUTTON_LOC.x / scaleX;
//			m_showButton.y = m_hideButton.y = HIDE_SHOW_BUTTON_LOC.y / scaleY;
//			addChild(m_showButton);
			
//			numConflictsTextField = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_UBUNTU, 30,20, 18, 0xff0000) as TextFieldHack;
//			numConflictsTextField.touchable = false;
//			numConflictsTextField.x = 100;
//			numConflictsTextField.y = 215;
//			TextFactory.getInstance().updateAlign(numConflictsTextField, 2, 1);
//			if(showNumConflicts)
//				addChild(numConflictsTextField);
			
			wideColor = 0xFF000000 ^ NodeSkin.WIDE_COLOR;
			narrowColor = 0xFF000000 ^ NodeSkin.NARROW_COLOR;
			
			isDirty = true;
			imageIsDirty = true;
		}
		
		public function hideMap(evt:Event):void
		{
			if (m_hiding) return;
			if (m_hidden && !m_showing) return;
			// Swap out hide button with show button
			if (m_showButton) addChild(m_showButton);
			if (m_hideButton) m_hideButton.removeFromParent();
			// Stop showing animation (if any) and animate this up to hide
			Starling.juggler.removeTweens(this);
			m_showing = false;
			m_hiding = true;
			Starling.juggler.tween(this, HIDE_SHOW_TIME_SEC, { y:HIDDEN_Y, transition: Transitions.EASE_OUT, onComplete:onHideComplete } );
		}
		
		private function onHideComplete():void
		{
			m_hiding = false;
			m_hidden = true;
			viewRectLayer.visible = false;
		}
		
		
		public function showMap(evt:Event):void
		{
			if (m_showing) return;
			if (!m_hidden && !m_hiding) return;
			// Swap out show button with hide button
			if (m_hideButton) addChild(m_hideButton);
			if (m_showButton) m_showButton.removeFromParent();
			// Stop hiding animation (if any) and animate this down to show
			Starling.juggler.removeTweens(this);
			m_hiding = false;
			m_showing = true;

	//		Starling.juggler.tween(this, HIDE_SHOW_TIME_SEC, { y:SHOWN_Y, transition: Transitions.EASE_OUT, onComplete:onShowComplete } );
			onShowComplete();
		}
		
		private function onShowComplete():void
		{
			m_showing = false;
			m_hidden = false;
			viewRectLayer.visible = true;
		}
		
		public function centerMap():void
		{
			showMap(null);
			var levPct:Point = new Point(.5,.5);
			dispatchEvent(new MoveEvent(MoveEvent.MOVE_TO_POINT, null, levPct, null));
		}
		public function addedToStage(event:starling.events.Event):void
		{				
			if (m_clickPane) m_clickPane.addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(event:EnterFrameEvent):void
		{
			if (isDirty) draw();
		}
		
		public function removedFromStage(event:starling.events.Event):void
		{
			if (gameNodeLayer) gameNodeLayer.removeChildren(0, -1, true);
			if (errorLayer) errorLayer.removeChildren(0, -1, true);
			if (viewRectLayer) viewRectLayer.removeChildren(0, -1, true);
			if (m_clickPane) m_clickPane.removeEventListener(TouchEvent.TOUCH, onTouch);
			removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			
			if(nodeBitmapData)
			{
				nodeBitmapData.dispose();
				nodeBitmapData = null;
			}
		}
		
		override protected function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length || event.getTouches(this, TouchPhase.MOVED).length)
			{
				var mapPoint:Point = touches[0].getLocation(this);
				var levPct:Point = map2pct(mapPoint);
				// clamp to 0->1
				levPct.x = XMath.clamp(levPct.x, 0.0, 1.0);
				levPct.y = XMath.clamp(levPct.y, 0.0, 1.0);
				dispatchEvent(new MoveEvent(MoveEvent.MOVE_TO_POINT, null, levPct, null));
			}
		}
		
		public function onViewspaceChanged(event:MiniMapEvent):void
		{
			m_contentX = event.contentX;
			m_contentY = event.contentY;
			m_contentScale = event.contentScale;
			setLevel(event.level);
		}
		
		public function setLevel(level:Level):void
		{
			currentLevel = level;
			drawViewSpaceIndicator();
		}
		
		private function draw():void
		{
			if (!currentLevel) return;
			
			if(imageIsDirty)
			{
				imageIsDirty = false;
				if(bitmapImage)
				{
					removeChild(bitmapImage, true);
					bitmapImage.dispose();
					bitmapTexture.dispose();
					if(nodeBitmapData)
					{
						nodeBitmapData.dispose();
						nodeBitmapData = null;
					}
				}
				var oldNumConflicts:int = numConflicts;
				numConflicts = 0;
				maxNumConflicts = 0;
				nodeErrorDict = new Dictionary();
				for (var errorId:String in currentLevel.levelGraph.unsatisfiedConstraintDict) {
				//	var constraint:Constraint = currentLevel.levelGraph.constraintsDict[errorId];
				//	if (currentLevel.edgeLayoutObjs.hasOwnProperty(constraint.id)) {
				//		var edgeLayout:Object = currentLevel.edgeLayoutObjs[constraint.id];
						//mark the 'to' node to the error dict as the spot of the error
						nodeErrorDict[errorId] = errorId;
				//	}
				}
				var nodeDict:Dictionary = currentLevel.nodeLayoutObjs;
				
				var dataNotValid:Boolean = true;
			//	while(dataNotValid)
				{
					//if we are updating this after sleeping we crash on null object error. Try to recover.
					try
					{
						if(nodeBitmapData == null)
						{
							nodeBitmapData = new BitmapData(width/scaleX, height/scaleY, true, 0x00000000);
						}
			
						for (var nodeId:String in nodeDict) {
							if (nodeDict[nodeId] is ClauseNode)
								addWidget(nodeDict[nodeId], false);
						}
						
						bitmapTexture = Texture.fromBitmapData(nodeBitmapData);
						bitmapImage = new Image(bitmapTexture);
						dataNotValid = false;
						
					}
					catch(e:Error)
					{
						trace("Caught updating error");
					}
				}
				if(bitmapImage)
					addChildAt(bitmapImage, 1);
				
			}
			drawViewSpaceIndicator();
			isDirty = false;

			//Update score based on new numConflicts value
			if(numConflicts != oldNumConflicts)
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, null, null));
	}
		
		private function drawViewSpaceIndicator():void
		{
			if (m_viewSpaceIndicator == null) {
				m_viewSpaceIndicator = new Sprite();
				if (m_viewSpaceQuads == null) {
					m_viewSpaceQuads = new Vector.<Quad>();
					for (var i:int = 0; i < 8; i++) {
						var myq:Quad = new Quad(1, 1, Constants.GOLD);
						m_viewSpaceQuads.push(myq);
						m_viewSpaceIndicator.addChild(myq);
					}
				}
				viewRectLayer.addChild(m_viewSpaceIndicator);
			}
			
			var viewWidth:Number = (VIEW_AREA.width / scaleX) * (GridViewPanel.WIDTH / m_contentScale) / visibleBB.width;
			var viewHeight:Number = (VIEW_AREA.height / scaleY) * ((GridViewPanel.HEIGHT /*- GameControlPanel.OVERLAP*/) / m_contentScale) / visibleBB.height;
			
			var viewTopLeftInLevelSpace:Point = new Point(-m_contentX / m_contentScale, -m_contentY / m_contentScale);
			var viewTopLeftInMapSpace:Point = level2map(viewTopLeftInLevelSpace);
			var viewX:Number = viewTopLeftInMapSpace.x;
			var viewY:Number = viewTopLeftInMapSpace.y;
			
			// Setup quad crosshairs/frame to indicate view:
			//           |2
			//     ------6-------
			//0----|4           5|------1
			//     ------7-------
			//           |3
			const THICK:Number = 3.0;
			const THIN:Number = 1.0;
			// Crosshairs
			m_viewSpaceQuads[0].x = CLICK_AREA.left / scaleX;
			m_viewSpaceQuads[0].width = Math.max(0, viewX - m_viewSpaceQuads[0].x);
			m_viewSpaceQuads[0].height = m_viewSpaceQuads[1].height = THIN / scaleY;
			m_viewSpaceQuads[0].y = m_viewSpaceQuads[1].y = viewY + 0.5 * viewHeight;
			m_viewSpaceQuads[1].x = viewX + viewWidth;
			m_viewSpaceQuads[1].width = Math.max(0, WIDTH / scaleX - m_viewSpaceQuads[1].x);
			m_viewSpaceQuads[2].y = 0;
			m_viewSpaceQuads[2].height = Math.max(0, viewY);
			m_viewSpaceQuads[2].x = m_viewSpaceQuads[3].x = viewX + 0.5 * viewWidth;
			m_viewSpaceQuads[2].width = m_viewSpaceQuads[3].width = THIN / scaleX;
			m_viewSpaceQuads[3].y = viewY + viewHeight;
			m_viewSpaceQuads[3].height = Math.max(0, CLICK_AREA.bottom / scaleY - m_viewSpaceQuads[3].y);
			m_viewSpaceQuads[0].alpha = m_viewSpaceQuads[1].alpha = m_viewSpaceQuads[2].alpha = m_viewSpaceQuads[3].alpha = 1;
			// Border
			m_viewSpaceQuads[4].x = viewX - 0.5 * THICK / scaleX;
			m_viewSpaceQuads[4].y = m_viewSpaceQuads[5].y = viewY + 0.5 * THICK / scaleY;
			m_viewSpaceQuads[4].width = m_viewSpaceQuads[5].width = THICK / scaleX;
			m_viewSpaceQuads[4].height = m_viewSpaceQuads[5].height = viewHeight - THICK / scaleY;
			m_viewSpaceQuads[5].x = viewX + viewWidth - 0.5 * THICK / scaleX;
			m_viewSpaceQuads[6].x = m_viewSpaceQuads[7].x = viewX - 0.5 * THICK / scaleX;
			m_viewSpaceQuads[6].y = viewY - 0.5 * THICK / scaleY;
			m_viewSpaceQuads[6].width = m_viewSpaceQuads[7].width = viewWidth + THICK / scaleX;
			m_viewSpaceQuads[6].height = m_viewSpaceQuads[7].height = THICK / scaleY;
			m_viewSpaceQuads[7].y = viewY + viewHeight - 0.5 * THICK / scaleY;
			m_viewSpaceQuads[4].alpha = m_viewSpaceQuads[5].alpha = m_viewSpaceQuads[6].alpha = m_viewSpaceQuads[7].alpha = 0.5;
		}
		
		private var savedBB:Rectangle;
		private function get visibleBB():Rectangle
		{
			if(savedBB == null || savedBB.width != currentLevel.m_boundingBox.width)
			{
				trace('BB', currentLevel.m_boundingBox.width, currentLevel.m_boundingBox.height);
				savedBB = currentLevel.m_boundingBox.clone();
			}
			var levelBB:Rectangle = currentLevel ? currentLevel.m_boundingBox.clone() : new Rectangle();
			levelBB.inflate(0.1 * GridViewPanel.WIDTH * currentLevel.levelLayoutScale / GridViewPanel.MIN_SCALE, 0.1 * GridViewPanel.HEIGHT * currentLevel.levelLayoutScale / GridViewPanel.MIN_SCALE);
			return levelBB;
		}
		
		public function errorConstraintAdded(edgeLayout:Object, flatten:Boolean = true):void
		{
//			if (!errorLayer) return;
//			
//			var errImage:Image = new Image(ErrorParticleSystem.errorTexture);
//			errImage.width = errImage.height = 80;
//			errImage.alpha = 0.6;
//			errImage.color = 0xFF0000;
//			var edgeId:String = edgeLayout["id"];
//			var prevErrorImage:Image = edgeErrorDict[edgeId] as Image;
//			if (prevErrorImage) prevErrorImage.removeFromParent(true);
//			edgeErrorDict[edgeId] = errImage;
//			
//			var bb:Rectangle = edgeLayout["bb"] as Rectangle;
//			if (bb == null) throw new Error("Tried to add edge error to MiniMap but no bounding box found in edge layout information.");
//			var errorLevelPt:Point = new Point(bb.x + 0.5 * bb.width, bb.y + 0.5 * bb.height);
//			var errPt:Point = level2map(errorLevelPt);
//			
//			errImage.x = errPt.x - 0.5 * errImage.width;
//			errImage.y = errPt.y - 0.5 * errImage.height; 
//			
//			errorLayer.addChild(errImage);
//			if (flatten) errorLayer.flatten();
		}
		
		public function errorRemoved(edgeLayout:Object):void
		{
			var edgeId:String = edgeLayout["id"];
			var toNode:String = edgeLayout["to_var_id"];
			delete nodeErrorDict[toNode];
		}
		
		public function addWidget(node:ClauseNode, flatten:Boolean = true):void
		{
			if (!gameNodeLayer) return;
			var id:String = node.id;
			var bb:Rectangle = node.bb;
			if (bb == null) throw new Error("Tried to add widget to MiniMap but no bounding box found in layout information.");
			
			var levelPctLeftX:Number = (bb.topLeft.x - visibleBB.x) / visibleBB.width;
			var mapLeftX:Number = levelPctLeftX * (VIEW_AREA.width / scaleX) + VIEW_AREA.x / scaleX;
			
			var levelPctRightX:Number = (bb.bottomRight.x - visibleBB.x) / visibleBB.width;
			var mapRightX:Number = levelPctRightX * (VIEW_AREA.width / scaleX) + VIEW_AREA.x / scaleX;
			
			var iconWidth:Number = Math.min(2 / scaleX, mapRightX - mapLeftX);
			var iconHeight:Number = bb.height / 2.0; // keep constant height so widgets always visible
			//var constrVar:ConstraintVar = node.graphVar;
			//var isNarrow:Boolean = constrVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			//var icon:Quad = new Quad(Math.max(MIN_ICON_SIZE, iconWidth), Math.max(MIN_ICON_SIZE, iconHeight), isNarrow ? GameComponent.NARROW_COLOR : GameComponent.WIDE_COLOR);
			
			var widgetLevelPt:Point = new Point(bb.x + 0.5 * bb.width, bb.y + 0.5 * bb.height);
			var iconLoc:Point = level2map(widgetLevelPt);
			var color:int = wideColor;
			//just make them red or blue, don't care about wide and narrow distinction?
			if(nodeErrorDict[id] != null)
			{
				color = errorColor;
				numConflicts++;
			}
			maxNumConflicts++;
		//	else if(isNarrow)
		//		color = narrowColor;
			
			//set the 2x2 square
			var size:int = 2;

			for(var i:int = iconLoc.x; i<iconLoc.x+size; i++)
				for(var j:int = iconLoc.y; j<iconLoc.y+size; j++)
					nodeBitmapData.setPixel32(i,j, color);
		}
		
		private function level2pct(pt:Point):Point
		{
			var pct:Point = new Point((pt.x - visibleBB.x) / visibleBB.width,
			                          (pt.y - visibleBB.y) / visibleBB.height);
			//pct.x = XMath.clamp(pct.x, 0.0, 1.0);
			//pct.y = XMath.clamp(pct.y, 0.0, 1.0);
			return pct;
		}
		
		private function map2pct(pt:Point):Point
		{
			var pct:Point = new Point((pt.x - VIEW_AREA.x / scaleX) / (VIEW_AREA.width / scaleX),
			                          (pt.y - VIEW_AREA.y / scaleY) / (VIEW_AREA.height / scaleY));
			//pct.x = XMath.clamp(pct.x, 0.0, 1.0);
			//pct.y = XMath.clamp(pct.y, 0.0, 1.0);
			return pct;
		}
		
		private function pct2level(pct:Point):Point
		{
			var pt:Point = new Point(visibleBB.width * pct.x + visibleBB.x,
			                         visibleBB.height * pct.y + visibleBB.y);
			return pt;
		}
		
		private function pct2map(pct:Point):Point
		{
			var pt:Point = new Point(pct.x * (VIEW_AREA.width / scaleX) + VIEW_AREA.x / scaleX,
			                         pct.y * (VIEW_AREA.height / scaleY) + VIEW_AREA.y / scaleY);
			return pt;
		}
		
		private function level2map(pt:Point):Point
		{
			var pct:Point = level2pct(pt);
			return pct2map(pct);
		}
	}
}