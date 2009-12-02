package ee.ut.slideplayer {
import com.fxcomponents.controls.FXVideo;

import mx.controls.Alert;
import mx.controls.Image;
import mx.core.UIComponent;
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
    {time:15, source:"slaid2.png"},
    {time:20, source:"slaid3.png"},
    {time:30, source:"slaid4.png"}];

  public function SlidePlayer() {
    nextImageId = 0;
  }

  override protected function createChildren():void {
    super.createChildren();

    image = new Image();
    image.width = 480;
    image.height = 360;
//    image.source = imageSource;
    addChild(image);

    video = new FXVideo(this);
    video.width = 320;
    video.height = 280;
    video.source = videoSource;
    video.x = image.width;
    addChild(video);
  }

  public function stuff():String {
    return image.source.toString();
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
}
}