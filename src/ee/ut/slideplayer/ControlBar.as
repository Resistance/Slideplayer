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

  protected var playPauseButton:PlayPauseButton;

  protected var stopButton:StopButton;

  protected var playheadSlider:FXProgressSlider;

  protected var volumeButton:VolumeButton;

  protected var volumeSlider:FXSlider;

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.ControlBar");

  private var volumeBeforeMute:Number = NaN;

  private var mayUpdatePlayheadSlider:Boolean = true;

  public function ControlBar() {
    //addEventListener(MouseEvent.CLICK, stopPropagationIfVideoDisplayUnset, true);
    //addEventListener(MouseEvent.MOUSE_DOWN, stopPropagationIfVideoDisplayUnset, true);
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
			playheadSlider.maximum = 100;
			playheadSlider.progress = 100;
			playheadSlider.value = playheadSlider.maximum / 2;
			playheadSlider.addEventListener(SliderEvent.THUMB_PRESS, onPlayheadSliderThumbPress);
			playheadSlider.addEventListener(SliderEvent.THUMB_RELEASE, onPlayheadSliderThumbRelease);
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
		playPauseButton.state = playPauseButton.state == "play" ? "pause" : "play";
	}

	private function onStopButtonClick(event:MouseEvent):void {
		log.info("Stop");
		_videoDisplay.stop();
		//playPauseButton.state = "play";
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

  private function onVolumeButtonClick(event:MouseEvent):void {
    if (isNaN(volumeBeforeMute)) {
      log.info("Mute");
      volumeBeforeMute = _videoDisplay.volume;
      volumeSlider.value = _videoDisplay.volume = 0;
    } else {
      log.info("Unmute");
      volumeSlider.value = 100 * (_videoDisplay.volume = volumeBeforeMute);
      volumeBeforeMute = NaN;
    }
  }

	private function onVolumeSliderChange(event:SliderEvent):void {
	}

	private function onPlayheadUpdate(event:VideoEvent):void {
		if (mayUpdatePlayheadSlider) {
			log.info("Updating playhead slider");
			playheadSlider.value = _videoDisplay.playheadTime;
		}
	}

	private function onStateChange(event:VideoEvent):void {
		if (_videoDisplay.state == VideoPlayer.STOPPED) {
			log.info("Stopped");
			playPauseButton.state = "play";
			playheadSlider.value = 0;
		}
	}
}

}
