package ee.ut.slideplayer {
import flash.display.MovieClip;
import flash.events.Event;
import flash.events.MouseEvent;

import mx.controls.SWFLoader;
import mx.controls.videoClasses.VideoPlayer;
import mx.core.UIComponent;
import mx.events.VideoEvent;
import mx.logging.ILogger;
import mx.logging.Log;

public class SlidePlayer extends UIComponent {
  private var _swfLoader:SWFLoader;
  private var _slidesMovie:MovieClip;
  private var video:EVideoDisplay;
  private var controlBar:ControlBar;
  private var layoutToggleButton:LayoutToggleButton;

  private var _videoSource:String;
  private var _slidesSource:String;
  private var _slideTimings:Array = [];

  private var _videoSourceChanged:Boolean;
  private var _slidesSourceChanged:Boolean;
  private var _slideTimingsChanged:Boolean;

  private var _nextImageId:int;

  private var _normalLayout:Boolean = true; // normal = large slide, small video
  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.SlidePlayer");

  public function SlidePlayer() {
    _nextImageId = 0;
  }

  override protected function createChildren():void {
    super.createChildren();

    _swfLoader = new SWFLoader();
    _swfLoader.width = 640;
    _swfLoader.height = 480;
    _swfLoader.scaleContent = true;
    addChild(_swfLoader);

    _swfLoader.addEventListener(Event.COMPLETE, onSWFLoaderComplete);

    video = new EVideoDisplay();
    video.width = 120;
    video.height = 90;
    video.source = videoSource;
    video.x = _swfLoader.width-video.width;
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

    if (_normalLayout) {
      _swfLoader.setActualSize(unscaledWidth, unscaledHeight-controlBarHeight);
      _swfLoader.move(0, 0);

      video.setActualSize(320, 240);
      video.move(unscaledWidth-video.width, 0);

      addChild(video);
    } else {
      _swfLoader.setActualSize(320, 240);
      _swfLoader.move(unscaledWidth-_swfLoader.width, 0);

      if (aspectRatio > video.aspectRatio) {
        video.setActualSize((unscaledHeight-controlBarHeight)*video.aspectRatio, unscaledHeight-controlBarHeight);
      } else {
        video.setActualSize(unscaledWidth, unscaledWidth/video.aspectRatio);
      }
      video.move(0, 0);

    }

    controlBar.move(0, unscaledHeight-controlBarHeight);
    controlBar.setActualSize(unscaledWidth, controlBarHeight);
  }

  public function get videoSource():String {
    return _videoSource;
  }

  public function set videoSource(value:String):void {
    _videoSource = value;
    _videoSourceChanged = true;
    invalidateProperties();
  }

  public function get slidesSource():String {
    return _slidesSource;
  }

  public function set slidesSource(value:String):void {
    _slidesSource = value;
    _slidesSourceChanged = true;
    invalidateProperties();
  }

  public function onVideoPlayheadUpdate(event:VideoEvent):void {
    if (_nextImageId < slideTimings.length && video.playheadTime >= slideTimings[_nextImageId].time) {
      _slidesMovie.gotoAndStop(_slideTimings[_nextImageId].number);

      if (_slideTimings.length > _nextImageId + 1) {
        _nextImageId++;
      }
    }
  }

  public function onVideoStateChange(event:VideoEvent):void {
    if (video.state == VideoPlayer.PLAYING || video.state == VideoPlayer.PAUSED) {
      for (var i:int = 0; i < _slideTimings.length; i++) {
        if (video.playheadTime < _slideTimings[i].time) {
          _nextImageId = i;
          _slidesMovie.gotoAndStop(_slideTimings[i-1].number);
          break;
        }
      }
    } else if (video.state == VideoPlayer.STOPPED) {
      // This is also fired on initial video loading
      _nextImageId = 0;
      if (_slidesMovie != null) {
        onVideoPlayheadUpdate(null);
      }
    }
  }

  override protected function commitProperties():void {
    log.debug("commitProperties");
    super.commitProperties();

    if (_slideTimingsChanged) {
//      log.debug(_imageData.map(function(i) { return i.source}).join(', '));
      _slideTimingsChanged = false;
    }

    if (_slidesSourceChanged) {
      _swfLoader.unloadAndStop();
      _swfLoader.source = _slidesSource;
      _swfLoader.load();

      _slidesSourceChanged = false;
    }

    if (_videoSourceChanged) {

      // If there is some video loaded, stop:
      if (video.bytesLoaded > 0) {
        video.stop();
      }
      video.source = _videoSource;
      video.load();
      controlBar.videoDisplay = null;
//      controlBar.videoDisplay = video;
      _videoSourceChanged = false;
    }
  }

  public function get slideTimings():Array {
    return _slideTimings;
  }

  public function set slideTimings(value:Array):void {
    _slideTimings = value;
    _slideTimingsChanged = true;
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

  private function onSWFLoaderComplete(event:Event):void {
    log.debug("SWFLoader loading completed");

    _slidesMovie = _swfLoader.content as MovieClip;

    log.debug("Scenes: " + _slidesMovie.currentScene.name + "/" + _slidesMovie.scenes.length);
    log.debug("Frames: " + _slidesMovie.currentFrame + "/" + _slidesMovie.totalFrames);

    controlBar.videoDisplay = video;
  }
}
}
