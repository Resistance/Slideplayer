package ee.ut.slideplayer {
import com.fxcomponents.controls.FXProgressSlider;
import com.fxcomponents.controls.FXSlider;
import com.fxcomponents.controls.fxvideo.PlayPauseButton;
import com.fxcomponents.controls.fxvideo.StopButton;

import com.fxcomponents.controls.fxvideo.VolumeButton;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.events.ProgressEvent;

import mx.controls.Label;
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

	protected var playheadTime:Label;

  protected var playheadSlider:FXProgressSlider;

  protected var volumeButton:VolumeButton;

  protected var volumeSlider:FXSlider;

  private var log:ILogger = Log.getLogger("ee.ut.slideplayer.Controlbar");

  private var volumeBeforeMute:Number = NaN;

  private var mayUpdatePlayheadSlider:Boolean = true;

  private var previousVideoDisplay:*;

  private var videoDisplayChanged:Boolean;

  private var controlsInitialized:Boolean;

	private var seeking:Boolean;

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

		if (!playheadTime) {
			playheadTime = new Label();
			playheadTime.text = "0:00:00";
			addChild(playheadTime);
		}

		if (!playheadSlider) {
			playheadSlider = new FXProgressSlider();
			playheadSlider.progress = 100;
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


	private function resizeAsPreferred(... components):int {
		var linearWidth:int = 0;
		components.forEach(function(component:UIComponent, index:Object, array:Object):void {
			component.setActualSize(component.measuredWidth, component.measuredHeight);
			linearWidth += component.width;
		}, null);
		return linearWidth;
	}

	private function layoutLinearly(unscaledHeight:Number, startX:int = 0, ... components):void {
		components.forEach(function(component:UIComponent, index:Object, array:Object):void {
			component.move(startX, (unscaledHeight - component.height) / 2);
			startX += component.width;
		});
	}

	override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
		super.updateDisplayList(unscaledWidth, unscaledHeight);
		var othersWidth:int = resizeAsPreferred(playPauseButton, stopButton, playheadTime, volumeButton);
		var slidersWidth:Number = unscaledWidth - othersWidth;
		var volumeSliderToSlidersWidthRatio:Number = 0.3;
		var volumeSliderWidth:Number = Math.min(Math.floor(slidersWidth * volumeSliderToSlidersWidthRatio), 100);
		playheadSlider.setActualSize(slidersWidth - volumeSliderWidth, playheadSlider.measuredHeight);
		volumeSlider.setActualSize(volumeSliderWidth, volumeSlider.measuredHeight);
		layoutLinearly(unscaledHeight, 0, playPauseButton, stopButton, playheadTime, playheadSlider, volumeButton, volumeSlider);
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
    log.debug("Seek: " + playheadSlider.value);
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
		if (playing) {
			if (seeking) {
				log.debug("Seeking complete. Enabling playhead slider updates");
				seeking = false;
				mayUpdatePlayheadSlider = true;
			}
		}
		if (state == VideoPlayer.SEEKING) {
			log.debug("Seeking started");
			seeking = true;
		}
    initializeControls();
	}

  private function onVideoDisplayPlayheadUpdate(event:VideoEvent):void {
    log.debug("Playhead updated. cs=" + _videoDisplay.state + ", es=" + event.state + ", ct=" + _videoDisplay.playheadTime + ", et=" + event.playheadTime);
    if ((_videoDisplay.state == VideoPlayer.PLAYING) && mayUpdatePlayheadSlider) {
			var time:Number = _videoDisplay.playheadTime;
			log.debug("Updating playhead slider: " + time);
      playheadSlider.value = time;
			playheadTime.text = formatTime(time) + "/" + formatTime(_videoDisplay.totalTime);
			invalidateDisplayList();
    } else {
      log.debug("Ignoring playhead slider update: " + _videoDisplay.playheadTime);
    }
  }

	private function formatTime(time:Number):String {
		var hours:int = Math.floor(time / 3600);
		var fullMinutes:int = Math.floor((time / 60) % 3600);
		var fullSeconds:int = Math.floor(time % 60);
		var result:String = ((fullSeconds < 10) && (fullMinutes > 0) && (hours > 0) ? "0" : "") + fullSeconds;
		if (fullMinutes > 0) {
			result = ((fullMinutes < 10) && (hours > 0) ? "0" : "") + fullMinutes + ":" + result;
		}
		if (hours > 0) {
			result = hours + ":" + result;
		}
		return result;
	}

  private function onVideoDisplayProgress(event:ProgressEvent):void {
    log.debug("Progress: " + _videoDisplay.bytesLoaded + "/" + _videoDisplay.bytesTotal);
    playheadSlider.progress = 100 * (_videoDisplay.bytesLoaded / _videoDisplay.bytesTotal);
  }
}
}
