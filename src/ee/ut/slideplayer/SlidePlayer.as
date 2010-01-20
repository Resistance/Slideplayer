package ee.ut.slideplayer {
import com.fxcomponents.controls.FXVideo;

import flash.events.HTTPStatusEvent;

import mx.collections.ArrayList;
import mx.controls.Alert;
import mx.controls.Image;
import mx.controls.List;
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
  private var images:Array;
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

    images = new Array(new Image(), new Image());
    for (var i in images) {
      images[i].width = 640;
      images[i].height = 480;
      (images[i] as Image).visible = false;
      addChild(images[i]);
    }

    video = new VideoDisplay();
    video.width = 120;
    video.height = 90;
    video.source = videoSource;
    video.x = images[0].width-video.width;
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

    for (var i in images) {
      (images[i] as Image).setActualSize(unscaledWidth, unscaledHeight-controlBarHeight);
      (images[i] as Image).move(0, 0);
    }

    var image:Image = images[0] as Image;
//    video.setActualSize(Math.floor(image.width/4),Math.floor(image.height/4));
    video.setActualSize(320, 240);
    video.move(image.width-video.width, image.y);

    controlBar.move(0, image.height);
    controlBar.setActualSize(unscaledWidth, controlBarHeight);
  }

  public function stuff():String {
//    log.debug("image: " + image.enabled.toString());
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
      var currentImage:Image = images[(nextImageId+1) % 2] as Image;
      var nextImage:Image = images[nextImageId % 2] as Image;

      nextImage.visible = true;
      currentImage.visible = false;
      if (nextImageId < imageData.length - 1) {
        nextImageId++;
        currentImage.source = _imageData[nextImageId].source;
      }
    }
  }

  public function onVideoStateChange(event:VideoEvent):void {
    if (video.state == VideoPlayer.PLAYING || video.state == VideoPlayer.PAUSED) {
      for (var i:int = 0; i < _imageData.length; i++) {
        if (video.playheadTime < _imageData[i].time) {
          nextImageId = i;
          (images[(nextImageId+1) % 2] as Image).source = _imageData[nextImageId-1].source;
          (images[nextImageId % 2] as Image).source = _imageData[nextImageId].source;
          break;
        }
      }
    } else if (video.state == VideoPlayer.STOPPED) {
      nextImageId = 0;
      images[nextImageId % 2].source = _imageData[nextImageId].source;
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
