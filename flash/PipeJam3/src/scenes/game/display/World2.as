package scenes.game.display
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import constraints.ConstraintGraph;
	
	import dialogs.InGameMenuDialog;
	import dialogs.SaveDialog;
	import dialogs.SimpleAlertDialog;
	import dialogs.SubmitLevelDialog;
	
	import display.NineSliceBatch;
	import display.SoundButton;
	import display.TextBubble;
	import display.ToolTipText;
	
	import events.ConflictChangeEvent;
	import events.ErrorEvent;
	import events.GameComponentEvent;
	import events.MenuEvent;
	import events.MiniMapEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.ToolTipEvent;
	import events.UndoEvent;
	import events.WidgetChangeEvent;
	
	import graph.PropDictionary;
	
	import networking.Achievements;
	import networking.GameFileHandler;
	import networking.PlayerValidation;
	import networking.TutorialController;
	
	import particle.ErrorParticleSystem;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import scenes.game.components.MiniMap;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.textures.Texture;
	
	import system.Solver;
	import system.VerigameServerConstants;
	
	import utils.XMath;
	
	/**
	 * World that contains levels that each contain boards that each contain pipes
	 */
	public class World2 extends World
	{	
		
		public function World2(_worldGraphDict:Dictionary, _worldObj:Object, _layout:Object, _assignments:Object)
		{
			super(_worldGraphDict, _worldObj, _layout, _assignments);	
		}

	}
}

