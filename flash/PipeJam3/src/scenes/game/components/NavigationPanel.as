package scenes.game.components
{
	
	import assets.AssetInterface;
	
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import scenes.game.display.Board;
	import scenes.game.display.BoardView;
	import scenes.game.display.Level;
	
	import starling.display.*;
	import starling.events.*;
	import starling.textures.Texture;
	import scenes.BaseComponent;
	
	public class NavigationPanel extends BaseComponent
	{
		/** composed of upper navigation bar area, lower navigation panel area, and rightmost navigation_map_area. */
		private var board_navigation_bar_area:BaseComponent;
		private var navigation_content_area:BaseComponent;
		private var navigation_map_area:BaseComponent;
		
		protected var navigationContentAreaBoardPanels:Vector.<BaseComponent>;
		/** The thumbnail of the active board used to scroll around */
		public var navigation_map_board:Board = null;
		
		/** The drawing area for the current board navigation map */
		public var navigation_map_drawing_area:BaseComponent;
		
		/** overlay on top of the drawing area to handle positioning clicks, and limit clicks through to map */
		public var navigation_map_drawing_area_overlay:BaseComponent;
		
		/** If a board navigation map, this rectangle indicates the currently viewed area of the board (yellow rectangle) */
		public var board_navigation_scroll_rect_indication:Sprite;

		
		/** Horizontal sprite indicating all boards for this level and their status (reg/green) allowing user to click to visit any board */
		private var board_navigation_bar:BaseComponent;
		
		private var board_navigation_bar_current_view:BaseComponent;

		/** Portion of the board_navigation_bar that highlights which boards are shown below (parentheses-looking bookends and lighter portion) */
		private var board_navigation_bar_viewable_area:Sprite = new Sprite();
		
		private var board_navigation_bar_square_board_icons:Sprite = new Sprite();
		
		/** Clickable area associated with board_navigation_bar */
		protected var board_navigation_bar_click_area:Sprite;
		
		/** Maximum width of the board_navigation_bar */
		protected const BOARD_NAV_MAX_BOARD_WIDTH:Number = 15.0;
		
		/** Maximum spacing of the board_navigation_bar so levels with 2, 3 board aren't spread far far apart */
		protected const BOARD_NAV_MAX_BOARD_SPACING:Number = 10.0;
		
		/** Minimum number of pixels that a single board icon can be on the board_navigation_bar */
		protected const BOARD_NAV_MIN_BOARD_WIDTH:Number = 2.0;
		
		/** Minimum spacing of the board_navigation_bar so levels with many board aren't on top of one another */
		protected const BOARD_NAV_MIN_BOARD_SPACING:Number = 1.0;
		
		/** Width of the entire area used to display boards, used to calculate viewable area marker */
		private static var BOARD_NAV_UI_WIDTH:Number;
		
		/** Number of board thumbnails that are visible at a given time used to calculate viewable area marker */
		private static var BOARD_NAV_VISIBLE_BOARDS:uint = 4;
			
		/** Current width of the board_navigation_bar */
		protected var board_nav_width:Number;
		
		/** Current X coordinate of theboard_navigation_bar*/
		protected var board_nav_x:Number;
		
		/** Current width of each of the boards on the board_navigation_bar */
		protected var board_nav_board_width:Number;
		
		/** Current spacing of the boards on the board_navigation_bar */
		protected var board_nav_board_spacing:Number;
		
		/** Width of the thumbnail copy of the board used to scroll around */
		protected var NAVIGATION_BOARD_WIDTH:uint;
		
		/** Height of the thumbnail copy of the board used to scroll around */
		protected var NAVIGATION_BOARD_HEIGHT:uint;
		
		/** Size of spacing between nav boards */
		protected var NAV_BOARD_SPACING:uint;
		
		/** The percent of the width of the content space a board should take. 4 boards + room for 3 borders between. */
		protected var INACTIVE_BOARD_SIZE_WIDTH_PERCENT:Number = 23;
		
		/** The percent of the height of the space the board should take. Rest is border on top and bottom. */
		protected var INACTIVE_BOARD_SIZE_HEIGHT_PERCENT:Number = 92;
		
		/** The percent of the width for spacing. */
		protected var NAV_BOARD_SPACING_PERCENT:uint = 2;
		
		protected var m_currentScrollPosition:int = 0;
		
		protected var active_board:Board;
		
		protected var m_initialized:Boolean = false;

		protected var m_boardCount:uint = 0;
		
		protected var clicking:Boolean = false;
		private var m_currentLevel:Level;
		
		private var m_mapSelectionImage:Image;
		private var m_mapSelectionTexture:Texture;
		
		public function NavigationPanel()
		{			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			this.addEventListener(starling.events.TouchEvent.TOUCH, onNavBoardTouchEvent);
		}
		
		public function initialize():void
		{
			var navigationBorder:uint = 10; //10 pixel border around map
			var contentAreaWidth:int = width*.75;
			
			NAVIGATION_BOARD_WIDTH = INACTIVE_BOARD_SIZE_WIDTH_PERCENT * contentAreaWidth/100;
			NAVIGATION_BOARD_HEIGHT = INACTIVE_BOARD_SIZE_HEIGHT_PERCENT * height/100;
			NAV_BOARD_SPACING = NAV_BOARD_SPACING_PERCENT*contentAreaWidth/100;

			board_navigation_bar_area = new BaseComponent;
			board_navigation_bar_area.setPosition(0, 0, contentAreaWidth, 20);
			board_navigation_bar = new BaseComponent;
			board_navigation_bar.setPosition(5, 2.5, board_navigation_bar_area.width - 10, board_navigation_bar_area.height - 5);
			board_navigation_bar.name = "board_navigation_bar";
			board_navigation_bar_area.addChild(board_navigation_bar);
			addChild(board_navigation_bar_area);
			
			board_navigation_bar_current_view = new BaseComponent;
			board_navigation_bar_area.addChild(board_navigation_bar_current_view);
			
			navigation_content_area = new BaseComponent;
			navigation_content_area.setPosition(NAV_BOARD_SPACING, board_navigation_bar_area.height, contentAreaWidth- 2*NAV_BOARD_SPACING, height - board_navigation_bar_area.height);
			addChild(navigation_content_area);
			
			navigation_map_area = new BaseComponent;
			navigation_map_area.setPosition(contentAreaWidth, height - NAVIGATION_BOARD_HEIGHT - 2*navigationBorder, 
												width - contentAreaWidth-50, NAVIGATION_BOARD_HEIGHT+2*navigationBorder);
			addChild(navigation_map_area);
			
			navigation_map_drawing_area = new BaseComponent;
			navigation_map_drawing_area.setPosition(5,5, navigation_map_area.width-10, navigation_map_area.height-10);
			navigation_map_area.addChild(navigation_map_drawing_area);
			
			navigation_map_drawing_area_overlay = new BaseComponent;
			navigation_map_drawing_area_overlay.setPosition(5,5, navigation_map_area.width-10, navigation_map_area.height-10);
			navigation_map_area.addChild(navigation_map_drawing_area_overlay);
			navigation_map_drawing_area_overlay.addEventListener(starling.events.TouchEvent.TOUCH, onNavMapTouchEvent);
			navigation_map_drawing_area_overlay.addEventListener(TouchEvent.TOUCH, boardNavigationMapClick);
			navigationContentAreaBoardPanels = new Vector.<BaseComponent>;
			for(var index:uint = 0; index<BOARD_NAV_VISIBLE_BOARDS; index++)
			{
				var newPanel:BaseComponent = new BaseComponent;
				newPanel.setPosition(index*(NAVIGATION_BOARD_WIDTH+NAV_BOARD_SPACING), NAV_BOARD_SPACING_PERCENT,
										NAVIGATION_BOARD_WIDTH, NAVIGATION_BOARD_HEIGHT);
				navigation_content_area.addChild(newPanel);
				navigationContentAreaBoardPanels.push(newPanel);
				newPanel.name = index.toString();
				newPanel.addEventListener(starling.events.TouchEvent.TOUCH, onNavBoardTouchEvent);
			}
			
			var left_side_scroll:Texture = AssetInterface.getTexture("Game", "ArrowLeftClass");
			var left_side_scrollImage:Image = new Image(left_side_scroll);
			left_side_scrollImage.addEventListener(TouchEvent.TOUCH, clickScrollRight);
			left_side_scrollImage.x = navigation_content_area.x - 0.5*left_side_scrollImage.width;
			left_side_scrollImage.y = navigation_content_area.height/2;
			addChild(left_side_scrollImage);
			
			var right_side_scroll:Texture = AssetInterface.getTexture("Game", "ArrowRightClass");
			var right_side_scrollImage:Image = new Image(right_side_scroll);
			right_side_scrollImage.addEventListener(TouchEvent.TOUCH, clickScrollLeft);
			right_side_scrollImage.x = navigation_content_area.width - 0.5*right_side_scrollImage.width;
			right_side_scrollImage.y = navigation_content_area.height/2;
			addChild(right_side_scrollImage);
			
//			
//			//set full size and resize later as needed
//			board_navigation_scroll_rect_indication = new Sprite( -10, -10, navigation_map_drawing_area.width+20, navigation_map_drawing_area.height+20);
//			var nav_glow:GlowFilter = new GlowFilter(0xFFFF00, 1.0, 6, 6, 6);
//			board_navigation_scroll_rect_indication.filters = [nav_glow];
//			navigation_map_drawing_area.addChild(board_navigation_scroll_rect_indication);
//			navigation_map_area.addChild(navigation_map_drawing_area);
			
			m_initialized = true;
		}
		
		private function onNavMapTouchEvent(event:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		private function onRemovedFromStage():void
		{
		}
		
		
		public function isInitialized():Boolean
		{
			return m_initialized;
		}
		
		public function onNavBoardTouchEvent(event:starling.events.TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length){
				if (touches.length == 1)
				{
					var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
					//find boardView parent
					var obj:DisplayObject = touch.target as DisplayObject;
					while(obj && Class(getDefinitionByName(getQualifiedClassName(obj))).toString().indexOf("BoardView") == -1)
						obj = obj.parent;
					var boardView:BoardView = obj as BoardView;
					if(boardView)
					{
						var parentBoard:Board = boardView.m_parentBoard;
						dispatchEvent(new starling.events.Event(Board.BOARD_SELECTED, true, parentBoard));
					}
				}
			}
		}
		
		protected function onBoardDisplayClick(e:MouseEvent):void
		{
			//find the right index, and then select that board
//			var globalPt:Point = e.currentTarget.localToGlobal(new Point(e.localX, e.localY));
//			var localPt:Point = boardDisplayWindow.globalToLocal(globalPt);
//			var index:uint = Math.floor(e.localX/NAV_BOARD_SCROLL_AMOUNT);
//			selectBoard(index);
		}
		
		protected function onNavBarClick(e:MouseEvent):void
		{
			//find the right index, and then select that board
			var globalPt:Point = e.target.localToGlobal(new Point(e.localX, e.localY));
			var localPt:Point = board_navigation_bar_square_board_icons.globalToLocal(globalPt);
			var index:uint = Math.floor((localPt.x - (board_nav_x+0.5*board_nav_board_spacing))/(board_nav_board_spacing+board_nav_board_width));
	//		selectBoard(index);
			
			//scroll pane to center selection (if possible), and that will update visible nav bar selection
//			var maxScrollPosition:int = -((m_world.active_level.boards.length - 4)*NAV_BOARD_SCROLL_AMOUNT);
//
//			var new_x:int = Math.max(maxScrollPosition,-(index-3)*NAV_BOARD_SCROLL_AMOUNT);
//			if(new_x > 0)
//				new_x = 0;
			
	//		TweenLite.to(boardDisplayScrollPane, VerigameSystem.BOARD_TRANSITION_TIME/2, { x:new_x,  onComplete:scrollEnded} );
		}
		
		public function onLevelSelected(event:starling.events.Event):void
		{
			m_currentLevel = event.data as Level;

			setNavigationContentBoards();
			layoutNavigationBar();
		}
		
		private var mapWidth:Number = 1;
		private var mapHeight:Number;
		public function onBoardSelected(event:starling.events.Event):void
		{
			if(active_board == event.data as Board)
				return;
			
			active_board = event.data as Board;
			//for some reason these drift, so remember and reset
			if(mapWidth == 1)
			{
				mapWidth = navigation_map_drawing_area.width;
				mapHeight = navigation_map_drawing_area.height;
			}
			navigation_map_drawing_area.width = mapWidth;
			navigation_map_drawing_area.height = mapHeight;

			var map_view:BoardView = active_board.navigation_map_view;
			map_view.scaleX = navigation_map_drawing_area.width/map_view.m_parentBoard.boardViewDefaultSize.x;
			map_view.scaleY = navigation_map_drawing_area.height/map_view.m_parentBoard.boardViewDefaultSize.y;

			this.navigation_map_drawing_area.removeChildren(1);
			this.navigation_map_drawing_area.addChild(map_view);
			
			updateNavigationMapSelectionArea(null);
		}
		
		public function setNavigationContentBoards():void
		{
			for (var index:int = 0; index<BOARD_NAV_VISIBLE_BOARDS; index++)
			{
				if(m_currentScrollPosition+index < m_currentLevel.boards.length)
					addBoardToPanel(m_currentLevel.boards[m_currentScrollPosition+index], index);
				else //empty the panel of existing boards
					addBoardToPanel(null, index);
			}
		}
		
		protected function addBoardToPanel(board:Board, boardIndex:uint):void
		{
			if(boardIndex >= BOARD_NAV_VISIBLE_BOARDS || boardIndex < 0)
				return;
			
			//remove existing board, if there is one, leave the sizing image
			if(navigationContentAreaBoardPanels[boardIndex].numChildren > 1)
				navigationContentAreaBoardPanels[boardIndex].removeChildAt(1);
			
			if(board)
			{
				var navView:BoardView = board.getNavigationBoardView();
				navView.scaleX = navigationContentAreaBoardPanels[boardIndex].width/navView.m_parentBoard.boardViewDefaultSize.x;
				navView.scaleY = navigationContentAreaBoardPanels[boardIndex].height/navView.m_parentBoard.boardViewDefaultSize.y;
				var savedWidth:Number = navigationContentAreaBoardPanels[boardIndex].width;
				navigationContentAreaBoardPanels[boardIndex].addChild(navView);
				board.getNavigationBoardView().m_navPanelIndex = boardIndex;
			}
		}
		
		
		public function onBoardSectionDisplayed(event:Event):void
		{
			updateNavigationMapSelectionArea(event.data as Rectangle);
		}
		
		/**
		 * Called when the left side scroll button is clicked to scroll right to see more boards
		 * @param	e Associated mouseEvent
		 */
		public function clickScrollRight(event:TouchEvent):void 
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length){
				if (touches.length == 1)
				{
					m_currentScrollPosition--;
					if(m_currentScrollPosition < 0)
						m_currentScrollPosition = 0;
					else
						setNavigationContentBoards();
				}
			}
		}
		
		/**
		 * Called when the right side scroll button is clicked to scroll left to see more boards
		 * @param	e Associated mouseEvent
		 */
		public function clickScrollLeft(event:TouchEvent):void 
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length){
				if (touches.length == 1)
				{
					m_currentScrollPosition++;
					if(m_currentScrollPosition + NavigationPanel.BOARD_NAV_VISIBLE_BOARDS > m_currentLevel.boards.length)
						m_currentScrollPosition = m_currentLevel.boards.length - NavigationPanel.BOARD_NAV_VISIBLE_BOARDS;
					else
						setNavigationContentBoards();
				}
			}

		}
		
		//called after scrolling ends, so accessories can be updated
		protected function scrollEnded():void
		{
			checkToRemoveScrollButtons();
//			drawNavBarViewableArea();	
		}
		
		/**
		 * Called after a scroll to determine whether there are more boards to the left/right and removes appropriate scroll buttons if not
		 */
		public function checkToRemoveScrollButtons():void {
			
//			if(!m_initialized)
//				return;
//			
//			var boards_to_the_left:Boolean = false;
//			var boards_to_the_right:Boolean = false;
//			if (boardDisplayScrollPane.x < 0)
//				boards_to_the_left = true;
//			if (boardDisplayScrollPane.x+boardDisplayScrollPane.width > boardDisplayWindow.width)
//				boards_to_the_right = true;
//			
//			if(left_side_scroll_simplebutton.parent)
//				left_side_scroll_simplebutton.parent.removeChild(left_side_scroll_simplebutton);
//			if(right_side_scroll_simplebutton.parent)
//				right_side_scroll_simplebutton.parent.removeChild(right_side_scroll_simplebutton);
//			if (boards_to_the_left)
//				boardDisplayWindow.addChild(left_side_scroll_simplebutton);
//			if (boards_to_the_right)
//				boardDisplayWindow.addChild(right_side_scroll_simplebutton);
		}
		
		/**
		 * Creates the horizontal bar used to view the status of all boards
		 */
		public function layoutNavigationBar():void {
			if (m_currentLevel == null) {
				return;
			}
			if (m_currentLevel.boards.length == 0) {
				return;
			}
			
			if ((m_currentLevel.boards.length*BOARD_NAV_MAX_BOARD_WIDTH + m_currentLevel.boards.length + 1)*BOARD_NAV_MAX_BOARD_SPACING < board_navigation_bar.width) {
				// in this case, the nav bar needs to be scaled down and centered
				board_nav_width = m_currentLevel.boards.length*BOARD_NAV_MAX_BOARD_WIDTH + (m_currentLevel.boards.length + 1)*BOARD_NAV_MAX_BOARD_SPACING;
				board_nav_x = 0.5*(board_navigation_bar.width - board_nav_width);
				board_nav_board_width = BOARD_NAV_MAX_BOARD_WIDTH;
				board_nav_board_spacing = BOARD_NAV_MAX_BOARD_SPACING;
			} else {
				// in this case the nav bar will stretch the whole width - 100 and icons
				board_nav_width = board_navigation_bar.width;
				board_nav_x = 0.0;
				board_nav_board_width = Math.max( BOARD_NAV_MIN_BOARD_WIDTH, board_nav_width / (2*m_currentLevel.boards.length + 1) );
				board_nav_board_spacing = Math.max( BOARD_NAV_MIN_BOARD_SPACING, board_nav_width / (2*m_currentLevel.boards.length + 1) );
			}
			
			board_navigation_bar_current_view.removeChildren();
			board_navigation_bar_current_view.setPosition(0,0, 
							m_currentLevel.boards.length*board_nav_board_width+(m_currentLevel.boards.length+1)*board_nav_board_width,
							board_navigation_bar_area.height-5, 1.0, 0x008888);
			
//			board_navigation_bar_click_area = new Sprite(board_navigation_bar_square_board_icons.x, 
//																		board_navigation_bar_square_board_icons.y,
//																		board_navigation_bar_square_board_icons.width, 
//																		board_navigation_bar_square_board_icons.height);
//			board_navigation_bar_click_area.graphics.clear();
//			board_navigation_bar_click_area.graphics.lineStyle(0.0, 0x0, 0.0);
//			board_navigation_bar_click_area.graphics.beginFill(0x0, 0.0);
//			board_navigation_bar_click_area.graphics.drawRoundRect(board_navigation_bar.x, board_navigation_bar.y - 5, board_nav_width, board_navigation_bar.height + 10, 6, 6);
//			board_navigation_bar_click_area.graphics.endFill();
//			board_navigation_bar_click_area.buttonMode = true;
//
//			
//			board_navigation_bar_square_board_icons.graphics.clear();
			
			for (var bint:int = 0; bint < m_currentLevel.boards.length; bint++) 
			{
//				if (m_currentLevel.boards[bint].trouble_points.length == 0) {
//					board_navigation_bar_square_board_icons.graphics.lineStyle(1.0, 0x005500, my_alpha);
//					board_navigation_bar_square_board_icons.graphics.beginFill(0x00FF00, my_alpha);
//				} else {
//					board_navigation_bar_square_board_icons.graphics.lineStyle(1.0, 0x550000, my_alpha);
//					board_navigation_bar_square_board_icons.graphics.beginFill(0xFF0000, my_alpha);
//				}
//				if (m_currentLevel.active_board != null) {
//					if (m_currentLevel.active_board == m_currentLevel.current_level.boards[bint]) {
//						board_navigation_bar_square_board_icons.graphics.lineStyle(2.0, 0xFFFFFF, 1.0);
//					}
//				}
				var board_navigation_bar_square:BaseComponent = new BaseComponent;
				board_navigation_bar_square.setPosition(board_nav_x + bint*board_nav_board_width + (bint + 1)*board_nav_board_spacing, 3, board_nav_board_width, 8, 1.0, 0x00ff00);
				board_navigation_bar_current_view.addChild(board_navigation_bar_square);
				board_navigation_bar_square.name = bint.toString();
				board_navigation_bar_square.addEventListener(TouchEvent.TOUCH, onNavBarTouch);
			}
//			board_navigation_bar_area.addEventListener(MouseEvent.CLICK, onNavBarClick);
//			board_navigation_bar_square_board_icons.addChild(board_navigation_bar_viewable_area);
//			
//			board_navigation_bar_area.addChild(board_navigation_bar_square_board_icons);
//			board_navigation_bar_area.addChild(board_navigation_bar_click_area);
		}
		
		private function onNavBarTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length){
				if (touches.length == 1)
				{
					var navSquare:BaseComponent = touches[0].target.parent as BaseComponent;
					if(navSquare)
					{
						var boardNumber:Number = parseInt(navSquare.name);
						dispatchEvent(new starling.events.Event(Board.BOARD_SELECTED, true, m_currentLevel.boards[boardNumber]));
					}
				}
			}
			
		}
		
		protected function updateNavigationMapSelectionArea(displayedArea:Rectangle):void
		{
			this.navigation_map_drawing_area_overlay.removeChildren(1);
			
			if(!displayedArea)
				displayedArea = new Rectangle(0,0,100,100); //select all
			
			var drawing_sprite:flash.display.Sprite = new flash.display.Sprite();

			var color:uint = 0xffff00;
			drawing_sprite.graphics.lineStyle(3, color, 1.0);
			drawing_sprite.graphics.drawRoundRect(-displayedArea.x*navigation_map_drawing_area.width/100,
												-displayedArea.y*navigation_map_drawing_area.height/100,
												displayedArea.width*navigation_map_drawing_area.width/100 + 4,
												displayedArea.height*navigation_map_drawing_area.height/100 + 4, 8, 8);

			
			var bmd:BitmapData = new BitmapData(this.navigation_map_drawing_area_overlay.width+8, navigation_map_drawing_area_overlay.height+8, true, color);
			
			bmd.draw(drawing_sprite);
			if(m_mapSelectionImage)
				m_mapSelectionImage.dispose();
			if(m_mapSelectionTexture)
				m_mapSelectionTexture.dispose();
			m_mapSelectionTexture = Texture.fromBitmapData(bmd);
			bmd.dispose();
			m_mapSelectionImage = new Image(m_mapSelectionTexture);
			m_mapSelectionImage.x = m_mapSelectionImage.y = -2;
			navigation_map_drawing_area_overlay.addChild(m_mapSelectionImage);
		}
		
		/**
		 * Called when the user clicks on this board (if this board is a board navigation map)
		 * @param	e Assocated MouseEvent
		 */
		private var startClickPt:Point;
		public function boardNavigationMapClick(e:TouchEvent):void {
			var touches:Vector.<Touch> = e.touches;
			if(e.getTouches(this, TouchPhase.BEGAN).length)
			{
				if (touches.length == 1)
				{
					startClickPt = touches[0].getLocation(navigation_map_drawing_area_overlay, null);
				}
			}
			else if(e.getTouches(this, TouchPhase.MOVED).length)
			{
				var currentClickPt:Point;
				if (touches.length == 1)
				{
					currentClickPt = touches[0].getLocation(navigation_map_drawing_area_overlay, null);
					//as a percentage of the board
					var touchDifference:Point = new Point((currentClickPt.x - startClickPt.x)*100/navigation_map_drawing_area_overlay.width,
												(currentClickPt.y - startClickPt.y)*100/navigation_map_drawing_area_overlay.height);
					startClickPt = currentClickPt;
					dispatchEvent(new starling.events.Event(Board.BOARD_SCROLLED, true, touchDifference));
				}
			}
		}
		
		
		/**
		 * Changes the section of the actual board being viewed, this is only called if this board is a board navigation map
		 * @param	_x New board X coordinate to view
		 * @param	_y New board Y coordinate to view
		 */
		public function shiftBoardViewAndMapIndicator(_x:Number, _y:Number):void {
/*			navigation_map_board.clone_parent.scroll_rect = new Rectangle(Math.max(0, Math.min(Math.max(width, navigation_map_board.max_pipe_width + 2*navigation_map_board.WIDE_PIPE_WIDTH + 10) - navigation_map_board.clone_parent.width,
																					_x - 0.5*navigation_map_board.clone_parent.width)) - 40,
																		Math.max(0, Math.min(Math.max(height, navigation_map_board.max_pipe_height) - navigation_map_board.clone_parent.height, 
																					_y - 0.5*navigation_map_board.clone_parent.height)) - 40,
																		navigation_map_board.clone_parent.width + 40,
																		navigation_map_board.clone_parent.height + 40);
			
			navigation_map_board.clone_parent.scrolling_pane.scrollRect = navigation_map_board.clone_parent.scroll_rect;

			var globalPt:Point = navigation_map_board.overlay.localToGlobal(new Point(_x, _y));
			var localPt:Point = navigation_map_drawing_area.globalToLocal(globalPt);
			
			if(localPt.x + board_navigation_scroll_rect_indication.width > navigation_map_drawing_area.width)
				localPt.x = navigation_map_drawing_area.width - board_navigation_scroll_rect_indication.width;

			if(localPt.y + board_navigation_scroll_rect_indication.height > navigation_map_drawing_area.height)
				localPt.y = navigation_map_drawing_area.height - board_navigation_scroll_rect_indication.height;
			board_navigation_scroll_rect_indication.x = localPt.x;
			board_navigation_scroll_rect_indication.y = localPt.y;
			if (board_navigation_scroll_rect_indication.parent == this) {
				removeChild(board_navigation_scroll_rect_indication);
			}
			navigation_map_drawing_area.addChild(board_navigation_scroll_rect_indication);
			if (navigation_map_board.overlay.parent != this) {
				navigation_map_board.addChild(navigation_map_board.overlay);
			} else {
				navigation_map_board.setChildIndex(navigation_map_board.overlay, numChildren - 1);
			}
			clicking = true;*/
		}
		
		/**
		 * Changes the section of THIS board being viewed, and updates the board_navigation_clone as needed to match.
		 * @param	_x New board X coordinate to view
		 * @param	_y New board Y coordinate to view
		 */
		public function scrollThisBoardTo(_x:Number, _y:Number):void {
			//trace("scroll to : " + _x + ", " + _y);
//			navigation_map_board.clone_parent.scroll_rect = new Rectangle(Math.max(0, Math.min(Math.max(width, navigation_map_board.max_pipe_width + 2*navigation_map_board.WIDE_PIPE_WIDTH) - width + 0, _x - 0.5*width)) - 40, Math.max(0, Math.min(Math.max(height, navigation_map_board.max_pipe_height) - height, _y - 0.5*height)) - 40, width + 40, height + 40);
//			navigation_map_board.clone_parent.scrolling_pane.scrollRect = navigation_map_board.clone_parent.scroll_rect;
//			if (navigation_map_board) {
//				board_navigation_scroll_rect_indication.x = navigation_map_board.clone_parent.scroll_rect.x + 40;
//				board_navigation_scroll_rect_indication.y = navigation_map_board.clone_parent.scroll_rect.y + 40;
//				if (board_navigation_scroll_rect_indication.parent == navigation_map_board) {
//					navigation_map_board.removeChild(board_navigation_scroll_rect_indication);
//				}
//				navigation_map_board.addChild(board_navigation_scroll_rect_indication);
//				if (navigation_map_board.overlay.parent == navigation_map_board) {
//					navigation_map_board.removeChild(navigation_map_board.overlay);
//				}
//				navigation_map_board.addChild(navigation_map_board.overlay);
//			}
		}
		
		/**
		 * Called when user mouses over this board if this board is a navigation map, and moves the focus of the board if the user is click-dragging
		 * @param	e Assocated MouseEvent
		 */
		public function boardNavigationMapRollOver(e:TouchEvent):void {
//			if (clicking) {
//				//system.printDebug("ROLLOVER (clicking = true)");
//				shiftBoardViewAndMapIndicator(e.localX, e.localY);
//			} else {
//				navigation_map_board.overlay.removeEventListener(MouseEvent.MOUSE_MOVE, boardNavigationMapRollOver);
//				//system.printDebug("ROLLOVER (clicking = false)");
//			}
		}
		
		/**
		 * Called when user mouses out of this board if this board is a navigation map
		 * @param	e Assocated MouseEvent
		 */
		public function boardNavigationMapRollOut(e:TouchEvent):void {
			//system.printDebug("ROLLOUT OR MOUSE_UP");
			// Decision: allow user to mouseout (by accident) and still scroll
//			navigation_map_board.overlay.removeEventListener(MouseEvent.MOUSE_MOVE, boardNavigationMapRollOver);
//			clicking = false;
		}
	}
}