package ee.ut.slideplayer {
import com.fxcomponents.controls.FXVideo;

import mx.controls.Alert;
import mx.controls.Image;
import mx.core.UIComponent;
import mx.events.SliderEvent;
import mx.events.VideoEvent;

public class SlidePlayer extends UIComponent {
  private var image:Image;
  private var video:FXVideo;

  private var _videoSource:String;
  private var _imageSource:String;

  private var nextImageId:int;

  private var imageData:Array = [
    {time:0, source:"slaid0.png"},
    {time:10, source:"slaid1.png"},
    {time:20, source:"slaid2.png"},
    {time:30, source:"slaid3.png"},
    {time:40, source:"slaid4.png"},
    {time:50, source:"slaid5.png"},
    {time:60, source:"slaid6.png"},
    {time:70, source:"slaid7.png"},
    {time:80, source:"slaid8.png"}];

  public function SlidePlayer() {
    nextImageId = 0;
  }

  override protected function createChildren():void {
    super.createChildren();

    image = new Image();
    image.width = 640;
    image.height = 480;
//    image.source = imageSource;
    addChild(image);

    video = new FXVideo(this);
    video.width = 120;
    video.height = 90;
    video.source = videoSource;
    video.x = image.width-video.width;
    addChild(video);
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
    super.updateDisplayList(unscaledWidth, unscaledHeight);

    image.setActualSize(unscaledWidth, unscaledHeight);
    image.x = 0;
    image.y = 0;

    video.setActualSize(Math.floor(image.width/4),Math.floor(image.height/4));
    video.y = image.y;
    video.x = image.width-video.width;
  }

  public function stuff():String {
    return this.width + "x" + this.height;
  }

  public function get videoSource():String {
    return _videoSource;
  }

  public function set videoSource(value:String):void {
    _videoSource = value;
  }

  public function get imageSource():String {
    return _imageSource;
  }

  public function set imageSource(value:String):void {
    _imageSource = value;
  }

  public function onVideoPlayheadUpdate(event:VideoEvent):void {
    if (video.playheadTime >= imageData[nextImageId].time) {
      image.source = imageData[nextImageId].source;
      if (nextImageId < imageData.length - 1) {
        nextImageId++;
      }
    }
  }

  public function onVideoThumbRelease(event:SliderEvent):void {
    for (var i:int = 0; i < imageData.length; i++) {
      if (video.playheadTime < imageData[i].time) {
        image.source = imageData[i-1].source;
        nextImageId = i;
        break;
      }
    }
  }
}
}