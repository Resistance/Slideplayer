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

  private var _configChanged:Boolean;
  private var _videoSourceChanged:Boolean;
  private var _imageDataChanged:Boolean;

  private var nextImageId:int;

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.SlidePlayer");

  private var _imageData:Array = [];

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
    video.autoPlay = false;
    addChild(video);

    video.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoPlayheadUpdate);
    video.addEventListener(VideoEvent.STATE_CHANGE, onVideoStateChange);

    controlBar = new ControlBar();
    controlBar.videoDisplay = video;
    addChild(controlBar);
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
    super.updateDisplayList(unscaledWidth, unscaledHeight);

    var controlBarHeight:Number = 21;

    image.setActualSize(unscaledWidth, unscaledHeight-controlBarHeight);
    image.move(0, 0);

//    video.setActualSize(Math.floor(image.width/4),Math.floor(image.height/4));
    video.setActualSize(320, 240);
    video.move(image.width-video.width, image.y);

    controlBar.move(0, image.height);
    controlBar.setActualSize(unscaledWidth, controlBarHeight);
  }

  public function stuff():String {
    log.debug("image: " + image.enabled.toString());
    log.debug("video: " + video.enabled.toString());
    log.debug("controlBar: " + controlBar.enabled.toString());
    return "";
  }

  public function get videoSource():String {
    return _videoSource;
  }

  public function set videoSource(value:String):void {
    _videoSource = value;
    _videoSourceChanged = true;
    invalidateProperties();
  }

  public function get imageSource():String {
    return _imageSource;
  }

  public function set imageSource(value:String):void {
    _imageSource = value;
  }

  public function onVideoPlayheadUpdate(event:VideoEvent):void {
    if (video.playheadTime >= imageData[nextImageId].time) {
      if (image.source != imageData[nextImageId].source) {
        image.source = imageData[nextImageId].source;
      }
      if (nextImageId < imageData.length - 1) {
        nextImageId++;
      }
    }
  }

  public function onVideoStateChange(event:VideoEvent):void {
    if (video.state == VideoPlayer.PLAYING || video.state == VideoPlayer.PAUSED) {
      for (var i:int = 0; i < _imageData.length; i++) {
        if (video.playheadTime < _imageData[i].time) {
          image.source = _imageData[i-1].source;
          nextImageId = i;
          break;
        }
      }
    } else if (video.state == VideoPlayer.STOPPED) {
      nextImageId = 0;
      onVideoPlayheadUpdate(null);
    }
  }

  override protected function commitProperties():void {
    super.commitProperties();

    if (_imageDataChanged) {
      _imageDataChanged = false;
    }

    if (_videoSourceChanged) {
      video.source = _videoSource;
      _videoSourceChanged = false;
    }
  }

  public function get imageData():Array {
    return _imageData;
  }

  public function set imageData(value:Array):void {
    _imageData = value;
    _imageDataChanged = true;
    invalidateProperties();
  }
}
}
