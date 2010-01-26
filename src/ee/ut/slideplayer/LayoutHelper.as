package ee.ut.slideplayer {
import mx.core.UIComponent;

public final class LayoutHelper {
  function LayoutHelper() {
  }

  public static function resizeAsPreferred(components:Array):Number {
    var width:Number = 0;
    components.forEach(function(component:UIComponent, index:Object, array:Array):void {
      component.setActualSize(component.measuredWidth, component.measuredHeight);
      width += component.width;
    }, null);
    return width;
  }

  public static function resizeAsSpecified(components:Array, controlSizingProperties:Array, width:Number):Number {
    var left:Number = width;
    components.forEach(function(component:UIComponent, index:int, array:Array):void {
      var sizingProperties:Object = controlSizingProperties[index];
      var controlWidth:Number = width * sizingProperties.width;
      if (sizingProperties.maxWidth != undefined)
        controlWidth = Math.min(controlWidth, sizingProperties.maxWidth);
      component.setActualSize(controlWidth, component.measuredHeight);
      left -= component.width;
    });
    return left;
  }

  public static function resizeEvely(components:Array, width:Number):void {
    components.forEach(function(component:UIComponent, index:int, array:Array):void {
      component.setActualSize(width / components.length, component.measuredHeight);
    });
  }

  public static function layoutLinearly(unscaledHeight:Number, components:Array, startX:Number = 0):void {
    components.forEach(function(component:UIComponent, index:Object, array:Array):void {
      component.move(startX, (unscaledHeight - component.height) / 2);
      startX += component.width;
    });
  }
}
}