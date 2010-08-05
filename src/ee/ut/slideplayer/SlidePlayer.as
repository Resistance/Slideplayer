package ee.ut.slideplayer {
import ee.ut.slideplayer.ControlBar;

import flash.events.MouseEvent;

import mx.controls.Image;
import mx.controls.videoClasses.VideoPlayer;
import mx.core.UIComponent;
import mx.events.VideoEvent;
import mx.logging.ILogger;
import mx.logging.Log;

public class SlidePlayer extends UIComponent {
  private var images:Array;
  private var video:EVideoDisplay;
  private var controlBar:ControlBar;
  private var layoutToggleButton:LayoutToggleButton;

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

    video = new EVideoDisplay();
    video.width = 120;
    video.height = 90;
    video.source = videoSource;
    video.x = images[0].width-video.width;
    video.autoPlay = false;
    addChild(video);

    video.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoPlayheadUpdate);
    video.addEventListener(VideoEvent.STATE_CHANGE, onVideoStateChange);

    layoutToggleButton = new LayoutToggleButton();
    layoutToggleButton.addEventListener(MouseEvent.CLICK, onLayoutToggleButtonClick);

    controlBar = new ControlBar();
//    controlBar.videoDisplay = video;
    addChild(controlBar);
    controlBar.insertControl(6, layoutToggleButton);
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
    super.updateDisplayList(unscaledWidth, unscaledHeight);

    var controlBarHeight:Number = 21;
    var aspectRatio:Number = unscaledWidth/(unscaledHeight-controlBarHeight);

    var i:int;
    if (_normalLayout) {
      for (i = 0; i < images.length; i++) {
        (images[i] as Image).setActualSize(unscaledWidth, unscaledHeight-controlBarHeight);
        (images[i] as Image).move(0, 0);
      }

      video.setActualSize(320, 240);
      video.move(unscaledWidth-video.width, 0);

      addChild(video);
    } else {
      for (i = 0; i < images.length; i++) {
        (images[i] as Image).setActualSize(320, 240);
        (images[i] as Image).move(unscaledWidth-images[i].width, 0);
      }

      if (aspectRatio > video.aspectRatio) {
        video.setActualSize((unscaledHeight-controlBarHeight)*video.aspectRatio, unscaledHeight-controlBarHeight);
      } else {
        video.setActualSize(unscaledWidth, unscaledWidth/video.aspectRatio);
      }
      video.move(0, 0);

      for (var o:int = 0; o < images.length; o++) {
        addChild(images[o]);
      }
    }

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

  public function onVideoPlayheadUpdate(event:VideoEvent):void {
    if (nextImageId < imageData.length && video.playheadTime >= imageData[nextImageId].time) {
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
    log.debug("commitProperties");
    super.commitProperties();

    if (_imageDataChanged) {
//      log.debug(_imageData.map(function(i) { return i.source}).join(', '));
      _imageDataChanged = false;
    }

    if (_videoSourceChanged) {

      // If there is some video loaded, stop:
      if (video.bytesLoaded > 0) {
        video.stop();
      }
      video.source = _videoSource;
      video.load();
//      video.invalidateProperties();
      controlBar.videoDisplay = null; // HACK, so controlbar gets reattached
      controlBar.videoDisplay = video;
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
    layoutToggleButton.state = _normalLayout ? "image" : "video";
    invalidateDisplayList();
  }

  private function onLayoutToggleButtonClick(event:MouseEvent):void {
    toggleLayout();
  }

  public function stop():void {
    video.stop();
  }
}
}
