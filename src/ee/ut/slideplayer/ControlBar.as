package ee.ut.slideplayer {
import com.fxcomponents.controls.FXProgressSlider;
import com.fxcomponents.controls.FXSlider;
import com.fxcomponents.controls.fxvideo.PlayPauseButton;
import com.fxcomponents.controls.fxvideo.StopButton;

import com.fxcomponents.controls.fxvideo.VolumeButton;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.events.ProgressEvent;

import mx.controls.VideoDisplay;
import mx.controls.videoClasses.VideoPlayer;
import mx.core.UIComponent;
import mx.events.SliderEvent;
import mx.events.VideoEvent;
import mx.logging.ILogger;
import mx.logging.Log;

public class ControlBar extends UIComponent {
  private var _videoDisplay:VideoDisplay;

  protected var playPauseButton:PlayPauseButton;

  protected var stopButton:StopButton;

  protected var playheadSlider:FXProgressSlider;

  protected var volumeButton:VolumeButton;

  protected var volumeSlider:FXSlider;

  private var log:ILogger = Log.getLogger("ControlBar");

  private var volumeBeforeMute:Number = NaN;

  private var mayUpdatePlayheadSlider:Boolean = true;

  private var previousVideoDisplay:*;

  private var videoDisplayChanged:Boolean;

  private var controlsInitialized:Boolean;

  public function ControlBar() {
    addEventListener(MouseEvent.CLICK, stopPropagationIfNotInteractable, true);
    addEventListener(MouseEvent.MOUSE_DOWN, stopPropagationIfNotInteractable, true);
  }

	/* Common component methods */

	override protected function createChildren():void {
		if (!playPauseButton) {
			playPauseButton = new PlayPauseButton();
			playPauseButton.state = "play";
			playPauseButton.addEventListener(MouseEvent.CLICK, onPlayPauseButtonClick);
			addChild(playPauseButton);
		}

		if (!stopButton) {
			stopButton = new StopButton();
			stopButton.addEventListener(MouseEvent.CLICK, onStopButtonClick);
			addChild(stopButton);
		}

		if (!playheadSlider) {
			playheadSlider = new FXProgressSlider();
			playheadSlider.addEventListener(MouseEvent.MOUSE_DOWN, onPlayheadSliderMouseDown);
			playheadSlider.addEventListener(SliderEvent.CHANGE, onPlayheadSliderChange);
			addChild(playheadSlider);
		}

		if (!volumeButton) {
			volumeButton = new VolumeButton();
			volumeButton.addEventListener(MouseEvent.CLICK, onVolumeButtonClick);
			addChild(volumeButton);
		}

		if (!volumeSlider) {
			volumeSlider = new FXSlider();
			volumeSlider.maximum = 1;
			volumeSlider.value = volumeSlider.maximum / 2;
			volumeSlider.addEventListener(SliderEvent.CHANGE, onVolumeSliderChange);
			addChild(volumeSlider);
		}

		super.createChildren();
	}

  override protected function commitProperties():void {
    super.commitProperties();

    if (videoDisplayChanged) {
      if (previousVideoDisplay)
        detach();
      if (_videoDisplay)
        attach();
      previousVideoDisplay = undefined;
      videoDisplayChanged = false;
    }
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		playPauseButton.setActualSize(playPauseButton.measuredWidth, playPauseButton.measuredHeight);
		stopButton.setActualSize(stopButton.measuredWidth, stopButton.measuredHeight);
		volumeButton.setActualSize(volumeButton.measuredWidth, volumeButton.measuredHeight);
		var slidersWidth:Number = unscaledWidth - (playPauseButton.width + stopButton.width + volumeButton.width);
		var volumeSliderToSlidersWidthRatio:Number = 0.3;
		var volumeSliderWidth:Number = Math.min(Math.floor(slidersWidth * volumeSliderToSlidersWidthRatio), 100);
		playheadSlider.setActualSize(slidersWidth - volumeSliderWidth, playheadSlider.measuredHeight);
		volumeSlider.setActualSize(volumeSliderWidth, volumeSlider.measuredHeight);

		playPauseButton.move(0, (unscaledHeight - playPauseButton.height) / 2);
		stopButton.move(playPauseButton.width, stopButton.y = (unscaledHeight - stopButton.height) / 2);
		playheadSlider.move(stopButton.x + stopButton.width, (unscaledHeight - playheadSlider.height) / 2);
		volumeButton.move(playheadSlider.x + playheadSlider.width, (unscaledHeight - volumeButton.height) / 2);
		volumeSlider.move(volumeButton.x + volumeButton.width, (unscaledHeight - volumeSlider.height) / 2);
	}

	/* Our methods */

  private function initializeControls():Boolean {
    if (controlsInitialized || (_videoDisplay.state == VideoPlayer.DISCONNECTED) || (_videoDisplay.state == VideoPlayer.LOADING))
      return false;
    playheadSlider.maximum = _videoDisplay.totalTime;
    playheadSlider.progress = 100 * (_videoDisplay.bytesLoaded / _videoDisplay.bytesTotal);
    playheadSlider.value = _videoDisplay.playheadTime;
    volumeSlider.value = _videoDisplay.volume;
    controlsInitialized = true;
    return true;
  }

  private function attach():void {
		log.debug("Attaching");

    playPauseButton.state = _videoDisplay.state == VideoPlayer.PLAYING ? "pause" : "play";
    initializeControls();

    _videoDisplay.addEventListener(VideoEvent.STATE_CHANGE, onVideoDisplayStateChange);
    _videoDisplay.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoDisplayPlayheadUpdate);
    _videoDisplay.addEventListener(ProgressEvent.PROGRESS, onVideoDisplayProgress);
	}

	private function detach():void {
		log.debug("Detaching");
		previousVideoDisplay.removeEventListener(VideoEvent.STATE_CHANGE, onVideoDisplayStateChange);
		previousVideoDisplay.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoDisplayPlayheadUpdate);
    previousVideoDisplay.removeEventListener(ProgressEvent.PROGRESS, onVideoDisplayProgress);
	}

	/* Properties */

	public function get videoDisplay():VideoDisplay {
		return _videoDisplay;
	}

	public function set videoDisplay(value:VideoDisplay):void {
		if (value == _videoDisplay)
			return;
    // Record only the first old value if property gets changed multiple times in succession
    if (previousVideoDisplay === undefined)
      previousVideoDisplay = _videoDisplay;
		_videoDisplay = value;
    // Prevent expensive detach/attach if property gets changed back to old value
    videoDisplayChanged = _videoDisplay != previousVideoDisplay;
		invalidateProperties();
	}

  public function get interactable():Boolean {
    return enabled && _videoDisplay && (_videoDisplay.state != VideoPlayer.DISCONNECTED) && (_videoDisplay.state != VideoPlayer.LOADING);
  }

  /* Event listeners */

	private function stopPropagationIfNotInteractable(event:Event):void {
		if (!interactable)
			event.stopPropagation();
	}

	private function onPlayPauseButtonClick(event:MouseEvent):void {
		if (playPauseButton.state == "play") {
			log.debug("Play");
			_videoDisplay.play();
		} else {
			log.debug("Pause");
			_videoDisplay.pause();
		}
	}

	private function onStopButtonClick(event:MouseEvent):void {
		log.debug("Stop");
		_videoDisplay.stop();
	}

	private function onPlayheadSliderMouseDown(event:MouseEvent):void {
    log.debug("Disabling playead slider updates");
    mayUpdatePlayheadSlider = false;
  }

  private function onPlayheadSliderChange(event:SliderEvent):void {
    log.debug("Seek: " + playheadSlider.value + ". Enabling playhead slider updates");
    mayUpdatePlayheadSlider = true;
    _videoDisplay.playheadTime = playheadSlider.value;
  }

  private function onVolumeButtonClick(event:MouseEvent):void {
    if (isNaN(volumeBeforeMute)) {
      log.debug("Mute");
      volumeBeforeMute = _videoDisplay.volume;
      volumeSlider.value = _videoDisplay.volume = 0;
    } else {
      log.debug("Unmute");
      volumeSlider.value = _videoDisplay.volume = volumeBeforeMute;
      volumeBeforeMute = NaN;
    }
  }

	private function onVolumeSliderChange(event:SliderEvent):void {
    log.debug("Volume: " + volumeSlider.value);
    _videoDisplay.volume = volumeSlider.value;
	}

	private function onVideoDisplayStateChange(event:VideoEvent):void {
    var state:String = _videoDisplay.state;
    var playing:Boolean = state == VideoPlayer.PLAYING;
    var paused:Boolean = state == VideoPlayer.PAUSED;
    var stopped:Boolean = state == VideoPlayer.STOPPED;
    log.debug("State changed. cs=" + state + ", es=" + event.state + ", ct=" + _videoDisplay.playheadTime + ", et=" + event.playheadTime);
    if (playing || paused || stopped) {
      playPauseButton.state = playing ? "pause" : "play";      
    }
    initializeControls();
	}

  private function onVideoDisplayPlayheadUpdate(event:VideoEvent):void {
    log.debug("Playhead updated. cs=" + _videoDisplay.state + ", es=" + event.state + ", ct=" + _videoDisplay.playheadTime + ", et=" + event.playheadTime);
    if ((_videoDisplay.state == VideoPlayer.PLAYING) && mayUpdatePlayheadSlider) {
      log.debug("Updating playhead slider: " + _videoDisplay.playheadTime);
      playheadSlider.value = _videoDisplay.playheadTime;
    } else {
      log.debug("Ignoring playhead slider update: " + _videoDisplay.playheadTime);
    }
  }

  private function onVideoDisplayProgress(event:ProgressEvent):void {
    log.debug("Progress: " + _videoDisplay.bytesLoaded + "/" + _videoDisplay.bytesTotal);
    playheadSlider.progress = 100 * (_videoDisplay.bytesLoaded / _videoDisplay.bytesTotal);
  }
}
}
