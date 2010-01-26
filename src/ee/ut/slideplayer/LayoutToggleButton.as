package ee.ut.slideplayer
{
import com.fxcomponents.controls.fxvideo.*;

import flash.display.Shape;
import flash.events.MouseEvent;

import com.fxcomponents.controls.fxvideo.Button;

public class LayoutToggleButton extends Button
{
	public function LayoutToggleButton()
	{
		super();
	}
	
	private var _state:String = "image";
	
	public function set state(value:String):void
	{
		_state = value;
		
		invalidateDisplayList();
	}
	
	public function get state():String
	{
		return _state;
	}
	
	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
	{
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		
		icon.graphics.clear();
		
		if(_state == "video")
		{
      icon.graphics.lineStyle(1, iconColor);
			icon.graphics.drawRect(0, 0, 11, 8);
      icon.graphics.lineStyle();
      icon.graphics.beginFill(iconColor);
      icon.graphics.drawRect(0, 0, 6, 4);
      icon.graphics.drawRect(0, 4, 11, 4);
		}
		
		if(_state == "image")
		{
      icon.graphics.lineStyle(1, iconColor);
			icon.graphics.drawRect(0, 0, 11, 8);
      icon.graphics.lineStyle();
      icon.graphics.beginFill(iconColor);
      icon.graphics.drawRect(7, 0, 5, 4);
		}
		
		centerIcon();
	}
}
}