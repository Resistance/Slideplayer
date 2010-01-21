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
  private var _normalLayout:Boolean = true; // normal = large slide, small video

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.SlidePlayer");

  private var _imageData:Array = [];

  public function SlidePlayer() {
    nextImageId = 0;
  }

  override protected function createChildren():void {
    super.createChildren();

    images = new Array(new Image(), new Image());
    for (var i:int = 0; i < images.length; i++) {
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

    var imageWidth:Number = unscaledWidth;
    var imageHeight:Number = unscaledHeight-controlBarHeight;
    var imageX:Number = 0;
    var imageY:Number = 0;
    var videoWidth: Number = 320;
    var videoHeight: Number = 240;
    var videoX:Number = imageWidth-videoWidth;
    var videoY:Number = imageY;

    if (_normalLayout) {
      addChild(video);
    } else {
      for (var o:int = 0; o < images.length; o++) {
        addChild(images[o]);
      }

      var tempWidth:Number = imageWidth;
      var tempHeight:Number = imageHeight;
      var tempX:Number = imageX;
      var tempY:Number = imageY;

      imageWidth = videoWidth;
      imageHeight = videoHeight;
      imageX = videoX;
      imageY = videoY;

      videoWidth = tempWidth;
      videoHeight = tempHeight;
      videoX = tempX;
      videoY = tempY;
    }

    for (var i:int = 0; i < images.length; i++) {
      (images[i] as Image).setActualSize(imageWidth, imageHeight);
      (images[i] as Image).move(imageX, imageY);
    }

    video.setActualSize(videoWidth, videoHeight);
    video.move(videoX, videoY);

    controlBar.move(0, unscaledHeight-controlBarHeight);
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
      // this is also fired on initial video loading
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

  public function toggleLayout():void {
    _normalLayout = !_normalLayout;
    invalidateDisplayList();
  }

  private function swap(a:Object, b:Object):void {
    var c:Object = a;
    a = b;
    b = c;
  }
}
}
