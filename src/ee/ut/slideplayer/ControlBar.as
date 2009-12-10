package ee.ut.slideplayer {
import com.fxcomponents.controls.FXProgressSlider;
import com.fxcomponents.controls.FXSlider;
import com.fxcomponents.controls.fxvideo.Button;
import com.fxcomponents.controls.fxvideo.PlayPauseButton;
import com.fxcomponents.controls.fxvideo.StopButton;

import com.fxcomponents.controls.fxvideo.VolumeButton;

import flash.events.Event;
import flash.events.MouseEvent;

import mx.controls.VideoDisplay;
import mx.controls.videoClasses.VideoPlayer;
import mx.core.UIComponent;
import mx.events.SliderEvent;
import mx.events.VideoEvent;
import mx.logging.ILogger;
import mx.logging.Log;

public class ControlBar extends UIComponent {
  private var _videoDisplay:VideoDisplay;

  private var playPauseButton:PlayPauseButton = new PlayPauseButton();

  private var stopButton:StopButton = new StopButton();

  private var playheadSlider:FXProgressSlider = new FXProgressSlider();

  private var volumeButton:VolumeButton = new VolumeButton();

  private var volumeSlider:FXSlider = new FXSlider();

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.ControlBar");

  private var volumeBeforeMute:Number = NaN;

  private var mayUpdatePlayheadSlider:Boolean = true;

  public function ControlBar() {
    addEventListener(MouseEvent.CLICK, stopPropagationIfVideoDisplayUnset, true);
    addEventListener(MouseEvent.MOUSE_DOWN, stopPropagationIfVideoDisplayUnset, true);

    playPauseButton.addEventListener(MouseEvent.CLICK, onPlayPauseButtonClick);
    stopButton.addEventListener(MouseEvent.CLICK, onStopButtonClick);
    playheadSlider.addEventListener(SliderEvent.THUMB_PRESS, onPlayheadSliderThumbPress);
    playheadSlider.addEventListener(SliderEvent.THUMB_RELEASE, onPlayheadSliderThumbRelease);
    playheadSlider.addEventListener(SliderEvent.CHANGE, onPlayheadSliderChange);
    volumeButton.addEventListener(MouseEvent.CLICK, onVolumeButtonClick);
  }

  private function onPlayheadSliderThumbPress(event:SliderEvent):void {
    log.info("Disabling playead slider updates");
    mayUpdatePlayheadSlider = false;
  }

  private function onPlayheadSliderThumbRelease(event:SliderEvent):void {
    log.info("Enabling playead slider updates");
    mayUpdatePlayheadSlider = true;
  }

  private function onPlayheadSliderChange(event:SliderEvent):void {
    log.info("Seeking to " + playheadSlider.value);
    _videoDisplay.playheadTime = playheadSlider.value;
  }

  private function stopPropagationIfVideoDisplayUnset(event:Event):void {
    if (_videoDisplay == null)
      event.stopPropagation();
  }

  private static function handleIfVideoDisplayIsSet(listener:Function):Function {
    return function(event:Event) {
      if (this._videoDisplay != null)
        listener(event);
    };
  }

  private function onPlayPauseButtonClick(event:MouseEvent):void {
    if (playPauseButton.state == "play") {
      log.info("Play");
      videoDisplay.play();
    } else {
      log.info("Pause");
      videoDisplay.pause();
    }
    playPauseButton.state = playPauseButton.state == "play" ? "pause" : "play";
    invalidateDisplayList();
  }

  private function onStopButtonClick(event:MouseEvent):void {
    log.info("Stop");
    videoDisplay.stop();
    playPauseButton.state = "play";
    invalidateDisplayList();
  }

  private function onVolumeButtonClick(event:MouseEvent):void {
    if (isNaN(volumeBeforeMute)) {
      log.info("Mute");
      volumeBeforeMute = videoDisplay.volume;
      volumeSlider.value = videoDisplay.volume = 0;
      invalidateDisplayList();
    } else {
      log.info("Unmute");
      volumeSlider.value = 100 * (videoDisplay.volume = volumeBeforeMute);
      volumeBeforeMute = NaN;
      invalidateDisplayList();
    }
  }

  override protected function createChildren():void {
    super.createChildren();

    playPauseButton.state = "play";
    playheadSlider.maximum = 100;
    playheadSlider.progress = 100;
    playheadSlider.value = playheadSlider.maximum / 2;
    volumeSlider.maximum = 100;
    volumeSlider.value = volumeSlider.maximum / 2;

    addChild(playPauseButton);
    addChild(stopButton);
    addChild(playheadSlider);
    addChild(volumeButton);
    addChild(volumeSlider);
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
    super.updateDisplayList(unscaledWidth, unscaledHeight);

    playPauseButton.setActualSize(21, 21);
    stopButton.setActualSize(21, 21);
    volumeButton.setActualSize(21, 21);
    var slidersWidth:Number = width - (playPauseButton.width + stopButton.width + volumeButton.width);
    var volumeSliderToSlidersWidthRatio:Number = 0.3;
    var volumeSliderWidth:Number = Math.min(Math.floor(slidersWidth * volumeSliderToSlidersWidthRatio), 100);
    playheadSlider.setActualSize(slidersWidth - volumeSliderWidth, 9);
    volumeSlider.setActualSize(volumeSliderWidth, 9);

    playPauseButton.x = 0;
    playPauseButton.y = (height - playPauseButton.height) / 2;
    stopButton.x = playPauseButton.width;
    stopButton.y = (height - stopButton.height) / 2;
    playheadSlider.x = stopButton.x + stopButton.width;
    playheadSlider.y = (height - playheadSlider.height) / 2;
    volumeButton.x = playheadSlider.x + playheadSlider.width;
    volumeButton.y = (height - volumeButton.height) / 2;
    volumeSlider.x = volumeButton.x + volumeButton.width;
    volumeSlider.y = (height - volumeSlider.height) / 2;
  }

  private function onPlayheadUpdate(event:VideoEvent):void {
    if (mayUpdatePlayheadSlider) {
      playheadSlider.value = _videoDisplay.playheadTime;
      invalidateDisplayList();
    }
  }

  private function onStateChange(event:VideoEvent):void {
    if (_videoDisplay.state == VideoPlayer.STOPPED) {
      log.info("Stopped");
      playPauseButton.state = "play";
      playheadSlider.value = 0;
      invalidateDisplayList();
    }
  }

	private function attach():void {
		log.debug("Attaching");

		_videoDisplay.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onPlayheadUpdate);
		_videoDisplay.addEventListener(VideoEvent.STATE_CHANGE, onStateChange);

		playPauseButton.state = _videoDisplay.state == VideoPlayer.PLAYING ? "pause" : "play";
		playheadSlider.maximum = _videoDisplay.totalTime;
		playheadSlider.value = _videoDisplay.playheadTime;
		volumeSlider.value = _videoDisplay.volume * 100;
		invalidateDisplayList();
	}

  private function detach():void {
    log.debug("Detaching");

    _videoDisplay.removeEventListener(VideoEvent.STOPPED, onStateChange);
    _videoDisplay.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, onPlayheadUpdate);
  }

  public function get videoDisplay():VideoDisplay {
    return _videoDisplay;
  }

  public function set videoDisplay(value:VideoDisplay):void {
    if (value == _videoDisplay)
      return;
    if (_videoDisplay != null)
      detach();
    _videoDisplay = value;
    if (_videoDisplay != null)
      attach();
    invalidateProperties();
  }
}

}
