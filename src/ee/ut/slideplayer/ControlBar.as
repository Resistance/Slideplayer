package ee.ut.slideplayer {
import com.fxcomponents.controls.FXProgressSlider;
import com.fxcomponents.controls.FXSlider;
import com.fxcomponents.controls.fxvideo.Button;
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

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.ControlBar");

  private var volumeBeforeMute:Number = NaN;

  private var mayUpdatePlayheadSlider:Boolean = true;

  public function ControlBar() {
    addEventListener(MouseEvent.CLICK, stopPropagationIfVideoDisplayUnset, true);
    addEventListener(MouseEvent.MOUSE_DOWN, stopPropagationIfVideoDisplayUnset, true);
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

	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
		super.updateDisplayList(unscaledWidth, unscaledHeight);

		playPauseButton.setActualSize(21, 21);
		stopButton.setActualSize(21, 21);
		volumeButton.setActualSize(21, 21);
		var slidersWidth:Number = unscaledWidth - (playPauseButton.width + stopButton.width + volumeButton.width);
		var volumeSliderToSlidersWidthRatio:Number = 0.3;
		var volumeSliderWidth:Number = Math.min(Math.floor(slidersWidth * volumeSliderToSlidersWidthRatio), 100);
		playheadSlider.setActualSize(slidersWidth - volumeSliderWidth, 9);
		volumeSlider.setActualSize(volumeSliderWidth, 9);

		playPauseButton.move(0, (unscaledHeight - playPauseButton.height) / 2);
		stopButton.move(playPauseButton.width, stopButton.y = (unscaledHeight - stopButton.height) / 2);
		playheadSlider.move(stopButton.x + stopButton.width, (unscaledHeight - playheadSlider.height) / 2);
		volumeButton.move(playheadSlider.x + playheadSlider.width, (unscaledHeight - volumeButton.height) / 2);
		volumeSlider.move(volumeButton.x + volumeButton.width, (unscaledHeight - volumeSlider.height) / 2);
	}

	/* Our methods */

	private function attach():void {
		log.debug("Attaching");

    _videoDisplay.addEventListener(VideoEvent.STATE_CHANGE, onVideoDisplayStateChange);
    _videoDisplay.addEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoDisplayPlayheadUpdate);
    _videoDisplay.addEventListener(ProgressEvent.PROGRESS, onVideoDisplayProgress);

		playPauseButton.state = _videoDisplay.state == VideoPlayer.PLAYING ? "pause" : "play";
		playheadSlider.maximum = _videoDisplay.totalTime;
    playheadSlider.progress = 100 * (_videoDisplay.bytesLoaded / _videoDisplay.bytesTotal);
		playheadSlider.value = _videoDisplay.playheadTime;
		volumeSlider.value = _videoDisplay.volume;
	}

	private function detach():void {
		log.debug("Detaching");
		_videoDisplay.removeEventListener(VideoEvent.STATE_CHANGE, onVideoDisplayStateChange);
		_videoDisplay.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoDisplayPlayheadUpdate);
    _videoDisplay.removeEventListener(ProgressEvent.PROGRESS, onVideoDisplayProgress);
	}

	/* Properties */

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

	/* Event listeners */

	private function stopPropagationIfVideoDisplayUnset(event:Event):void {
		if (_videoDisplay == null)
			event.stopPropagation();
	}

	private function onPlayPauseButtonClick(event:MouseEvent):void {
		if (playPauseButton.state == "play") {
			log.info("Play");
			_videoDisplay.play();
		} else {
			log.info("Pause");
			_videoDisplay.pause();
		}
	}

	private function onStopButtonClick(event:MouseEvent):void {
		log.info("Stop");
		_videoDisplay.stop();
	}

	private function onPlayheadSliderMouseDown(event:MouseEvent):void {
    log.info("Disabling playead slider updates");
    mayUpdatePlayheadSlider = false;
  }

  private function onPlayheadSliderChange(event:SliderEvent):void {
    log.info("Seek: " + playheadSlider.value + "; enabling playhead slider updates");
    mayUpdatePlayheadSlider = true;
    _videoDisplay.playheadTime = playheadSlider.value;
  }

  private function onVolumeButtonClick(event:MouseEvent):void {
    if (isNaN(volumeBeforeMute)) {
      log.info("Mute");
      volumeBeforeMute = _videoDisplay.volume;
      volumeSlider.value = _videoDisplay.volume = 0;
    } else {
      log.info("Unmute");
      volumeSlider.value = _videoDisplay.volume = volumeBeforeMute;
      volumeBeforeMute = NaN;
    }
  }

	private function onVolumeSliderChange(event:SliderEvent):void {
    log.info("Volume: " + volumeSlider.value);
    _videoDisplay.volume = volumeSlider.value;
	}

	private function onVideoDisplayStateChange(event:VideoEvent):void {
    var state:String = _videoDisplay.state;
    var playing:Boolean = state == VideoPlayer.PLAYING;
    var paused:Boolean = state == VideoPlayer.PAUSED;
    var stopped:Boolean = state == VideoPlayer.STOPPED;
    log.info("State changed: " + state + "; Time: " + _videoDisplay.playheadTime);
    if (playing || paused || stopped) {
      playPauseButton.state = playing ? "pause" : "play";      
    }
	}

  private function onVideoDisplayPlayheadUpdate(event:VideoEvent):void {
    if ((_videoDisplay.state == VideoPlayer.PLAYING) && mayUpdatePlayheadSlider) {
      log.info("Updating playhead slider: " + _videoDisplay.playheadTime);
      playheadSlider.value = _videoDisplay.playheadTime;
    } else {
      log.info("Ignoring playhead slider update: " + _videoDisplay.playheadTime);
    }
  }

  private function onVideoDisplayProgress(event:ProgressEvent):void {
    log.info("Progress: " + _videoDisplay.bytesLoaded + "/" + _videoDisplay.bytesTotal)
    playheadSlider.progress = 100 * (_videoDisplay.bytesLoaded / _videoDisplay.bytesTotal);
  }
}
}
