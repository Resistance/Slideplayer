package ee.ut.slideplayer {
import com.fxcomponents.controls.FXVideo;

import flash.events.HTTPStatusEvent;

import mx.controls.Alert;
import mx.controls.Image;
import mx.controls.VideoDisplay;
import mx.controls.videoClasses.VideoPlayer;
import mx.core.UIComponent;
import mx.events.SliderEvent;
import mx.events.VideoEvent;
import mx.logging.ILogger;
import mx.logging.Log;
import mx.rpc.events.ResultEvent;
import mx.rpc.http.HTTPService;

public class SlidePlayer extends UIComponent {
  private var image:Image;
  private var video:VideoDisplay;
  private var controlBar:ControlBar;

  private var _videoSource:String;
  private var _imageSource:String;
  private var _config:String;
  private var _lectureTitle:String;

  private var configChanged:Boolean;

  private var nextImageId:int;

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.SlidePlayer");

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
    addChild(image);

    video = new VideoDisplay();
    video.width = 120;
    video.height = 90;
    video.source = videoSource;
    video.x = image.width-video.width;
    addChild(video);

    video.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoPlayheadUpdate);
    video.addEventListener(VideoEvent.STATE_CHANGE, onVideoStateChange);
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
    super.updateDisplayList(unscaledWidth, unscaledHeight);

    image.setActualSize(unscaledWidth, unscaledHeight);
    image.move(0, 0);

//    video.setActualSize(Math.floor(image.width/4),Math.floor(image.height/4));
    video.setActualSize(320, 240);
    video.move(image.width-video.width, image.y);
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

  public function onVideoStateChange(event:VideoEvent):void {

    if (video.state == VideoPlayer.PLAYING || video.state == VideoPlayer.PAUSED) {
      for (var i:int = 0; i < imageData.length; i++) {
        if (video.playheadTime < imageData[i].time) {
          image.source = imageData[i-1].source;
          nextImageId = i;
          break;
        }
      }
    }
  }

  private function loadConfig():void {
    var configLoader:HTTPService = new HTTPService();
    configLoader.url = config;
    configLoader.method = "get";
    configLoader.resultFormat = "e4x";
    configLoader.addEventListener("result", parseLoadedConfig);
    configLoader.send();
  }

  private function parseLoadedConfig(event:ResultEvent):void {
    log.debug("GOT RESULT");
    var lectures:XMLList = XML(event.result).lecture;
    for each (var lecture:XML in lectures) {
      if (lecture.attribute("title") == _lectureTitle) {
        log.debug(lecture.attribute("title") + ": " + lecture.attribute("file"));

        for each (var slide:XML in lecture) {
          imageData.push({
            time:int(slide.attribute("time")),
            source:slide.attribute("file")}
          );
        }
      }
    }

    log.debug(imageData.toString());
  }

  public function get config():String {
    return _config;
  }

  public function set config(value:String):void {
    _config = value;
    configChanged = true;
    invalidateProperties();
  }

  override protected function commitProperties():void {
    super.commitProperties();

    if (configChanged) {
      loadConfig();
      configChanged = false;
    }
  }

  public function get lectureTitle():String {
    return _lectureTitle;
  }

  public function set lectureTitle(value:String):void {
    _lectureTitle = value;
  }
}
}
