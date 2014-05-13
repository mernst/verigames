package scenes.game.display
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	
	import constraints.ConstraintValue;
	import constraints.ConstraintVar;
	
	import display.NineSliceBatch;
	
	import events.ToolTipEvent;
	import events.UndoEvent;
	import events.WidgetChangeEvent;
	
	import graph.PropDictionary;
	
	import starling.display.Quad;
	import starling.events.Event;
	import starling.filters.BlurFilter;
	import starling.textures.TextureAtlas;
	import starling.display.Image;
	
	public class GameNode extends GameNodeBase
	{
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		private var m_scoreBlock:ScoreBlock;
		private var m_highlightRect:Quad;
		
		public function GameNode(_layoutObj:Object, _constraintVar:ConstraintVar, _draggable:Boolean = true)
		{
			super(_layoutObj, _constraintVar);
			draggable = _draggable;
			
			shapeWidth = boundingBox.width;
			shapeHeight = boundingBox.height;
			
			m_isEditable = !constraintVar.constant;
			m_isWide = !constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			
	//		draw();
		}
		
		public override function onClicked(pt:Point):void
		{
			var eventToUndo:WidgetChangeEvent,  eventToDispatch:UndoEvent;
			if (m_propertyMode == PropDictionary.PROP_NARROW) {
				if(m_isEditable) {
					var newIsWide:Boolean = !m_isWide;
					handleWidthChange(newIsWide, false, pt);
					//dispatchEvent(new starling.events.Event(Level.UNSELECT_ALL, true, this));
					eventToUndo = new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, this, PropDictionary.PROP_NARROW, !newIsWide);
					eventToDispatch = new UndoEvent(eventToUndo, this);
					dispatchEvent(eventToDispatch);
				}
			} else if (m_propertyMode.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0) {
				var propVal:Boolean = constraintVar.getProps().hasProp(m_propertyMode);
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, this, m_propertyMode, !propVal, null, false, pt));
				eventToUndo = new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, this, m_propertyMode, !propVal);
				eventToDispatch = new UndoEvent(eventToUndo, this);
				dispatchEvent(eventToDispatch);
				m_isDirty = true;
			}
		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			if (undoEvent is WidgetChangeEvent) {
				var evt:WidgetChangeEvent = undoEvent as WidgetChangeEvent;
				if (evt.prop == PropDictionary.PROP_NARROW) {
					// This is a confusing double negative, if narrow is TRUE then isWide = false, but negate for undo
					handleWidthChange(isUndo ? evt.propValue : !evt.propValue);
				} else if (m_propertyMode.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0) {
					dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, this, m_propertyMode, isUndo ? !evt.propValue : evt.propValue, null, false, null));
					m_isDirty = true;
				}
			} else {
				m_isDirty = true;
			}
		}
		
		public function handleWidthChange(newIsWide:Boolean, silent:Boolean = false, pt:Point = null):void
		{
			var redraw:Boolean = (m_isWide != newIsWide);
			m_isWide = newIsWide;
			m_isDirty = redraw;
			// Need to dispatch AFTER setting width, this will trigger the score update
			// (we don't want to update the score with old values, we only know they're old
			// if we properly mark them dirty first)
			dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, this, PropDictionary.PROP_NARROW, !newIsWide, null, silent, pt));
			for each (var iedge:GameEdgeContainer in orderedIncomingEdges) {
				iedge.onWidgetChange(this);
			}
			for each (var oedge:GameEdgeContainer in orderedOutgoingEdges) {
				oedge.onWidgetChange(this);
			}
		}
		
		public function get assetName():String
		{
			var _assetName:String;
			if(m_isEditable == true)
			{
				if (m_isWide == true)
					_assetName = AssetInterface.PipeJamSubTexture_BlueDarkBoxPrefix;
				else
					_assetName = AssetInterface.PipeJamSubTexture_BlueLightBoxPrefix;
			}
			else //not adjustable
			{
				if(m_isWide == true)
					_assetName = AssetInterface.PipeJamSubTexture_GrayDarkBoxPrefix;
				else
					_assetName = AssetInterface.PipeJamSubTexture_GrayLightBoxPrefix;
			}
			//if (isSelected) _assetName += "Select";
			return _assetName;
		}
		
		override public function draw():void
		{
			if (costume) {
				costume.removeFromParent(true);
			}
			costume = new NineSliceBatch(shapeWidth, shapeHeight, shapeHeight / 3.0, shapeHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", assetName);
			addChild(costume);

			var wideScore:Number = constraintVar.scoringConfig.getScoringValue(ConstraintValue.VERBOSE_TYPE_1);
			var narrowScore:Number = constraintVar.scoringConfig.getScoringValue(ConstraintValue.VERBOSE_TYPE_0);
			const BLK_SZ:Number = 20; // create an upscaled version for better quality, then update width/height to shrink
			const BLK_RAD:Number = (shapeHeight / 3.0) * (BLK_SZ * 2 / boundingBox.height);
			if (wideScore > narrowScore) {
				m_scoreBlock = new ScoreBlock(AssetInterface.PipeJamSubTexture_BlueDarkBoxPrefix, (wideScore - narrowScore).toString(), BLK_SZ - BLK_RAD, BLK_SZ - BLK_RAD, BLK_SZ, null, BLK_RAD);
				m_scoreBlock.width = m_scoreBlock.height = boundingBox.height / 2;
				addChild(m_scoreBlock);
			} else if (narrowScore > wideScore) {
				m_scoreBlock = new ScoreBlock(AssetInterface.PipeJamSubTexture_BlueLightBoxPrefix, (narrowScore - wideScore).toString(), BLK_SZ - BLK_RAD, BLK_SZ - BLK_RAD, BLK_SZ, null, BLK_RAD);
				m_scoreBlock.width = m_scoreBlock.height = boundingBox.height / 2;
				addChild(m_scoreBlock);
			}
			useHandCursor = m_isEditable;
			

			
			if (constraintVar) {
				var i:int = 0;
				for (var prop:String in constraintVar.getProps().iterProps()) {
					if (prop == PropDictionary.PROP_NARROW) continue;
					if (prop == m_propertyMode) {
						var keyQuad:Quad = new Quad(3, 3, KEYFOR_COLOR);
						keyQuad.x = 1 + i * 4;
						keyQuad.y = boundingBox.height - 4;
						addChild(keyQuad);
						i++;
					}
				}
			}
			
			if (isSelected)
			{
				// Apply the glow filter
				this.filter = BlurFilter.createGlow();
			}
			else
			{
				if(this.filter)
					this.filter.dispose();
			}
			
			super.draw();
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
		
		override protected function getToolTipEvent():ToolTipEvent
		{
			var lockedTxt:String = isEditable() ? "" : "Locked ";
			var wideTxt:String = isWide() ? "Wide " : "Narrow ";
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, lockedTxt + wideTxt + "Widget", 8);
		}
		
	}
}