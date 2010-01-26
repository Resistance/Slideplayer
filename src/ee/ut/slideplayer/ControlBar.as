package ee.ut.slideplayer {

import com.fxcomponents.controls.FXProgressSlider;
import com.fxcomponents.controls.FXSlider;
import com.fxcomponents.controls.fxvideo.PlayPauseButton;
import com.fxcomponents.controls.fxvideo.StopButton;
import com.fxcomponents.controls.fxvideo.VolumeButton;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;

import mx.controls.Text;
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

	protected var playheadTime:Text;

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

  private var controls:Array = new Array();

  private var controlSizingProperties:Array = new Array();

  public function ControlBar() {
    addEventListener(MouseEvent.CLICK, stopPropagationIfNotInteractable, true);
    addEventListener(MouseEvent.MOUSE_DOWN, stopPropagationIfNotInteractable, true);
  }

	/* Common component methods */

  public function insertControl(index:int, control:UIComponent, sizingProperties:Object = null):void {
    controls.splice(index, 0, control);
    controlSizingProperties.splice(index, 0, sizingProperties);
    addChild(control);
    invalidateDisplayList();
  }

	override protected function createChildren():void {
		if (!playPauseButton) {
			playPauseButton = new PlayPauseButton();
			playPauseButton.state = "play";
			playPauseButton.addEventListener(MouseEvent.CLICK, onPlayPauseButtonClick);
      insertControl(0, playPauseButton);
		}

		if (!stopButton) {
			stopButton = new StopButton();
			stopButton.addEventListener(MouseEvent.CLICK, onStopButtonClick);
      insertControl(1, stopButton);
		}

		if (!playheadTime) {
			playheadTime = new Text();
			playheadTime.text = "0:00:00\n0:00:00";
      playheadTime.setStyle("fontSize", 8);
      playheadTime.selectable = false;
      insertControl(2, playheadTime);
		}

		if (!playheadSlider) {
			playheadSlider = new FXProgressSlider();
			playheadSlider.progress = 100;
			playheadSlider.addEventListener(MouseEvent.MOUSE_DOWN, onPlayheadSliderMouseDown);
			playheadSlider.addEventListener(SliderEvent.CHANGE, onPlayheadSliderChange);
      insertControl(3, playheadSlider, {});
		}

		if (!volumeButton) {
			volumeButton = new VolumeButton();
			volumeButton.addEventListener(MouseEvent.CLICK, onVolumeButtonClick);
      insertControl(4, volumeButton);
		}

		if (!volumeSlider) {
			volumeSlider = new FXSlider();
			volumeSlider.maximum = 1;
			volumeSlider.value = volumeSlider.maximum / 2;
			volumeSlider.addEventListener(SliderEvent.CHANGE, onVolumeSliderChange);
      insertControl(5, volumeSlider, {width: 0.3, maxWidth: 100});
		}

		super.createChildren();
	}

  override protected function commitProperties():void {
    super.commitProperties();

    if (videoDisplayChanged) {
      if (previousVideoDisplay)
        detach();
      if (_videoDisplay) {
        attach();
      }
      previousVideoDisplay = undefined;
      videoDisplayChanged = false;
    }
  }

  override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
		super.updateDisplayList(unscaledWidth, unscaledHeight);
    var preferredSizedControls:Array = controls.filter(function(control:UIComponent, index:int, array:Array):Boolean {
      return controlSizingProperties[index] == null;
    });
    var stretchingControls:Array = new Array();
    var stretchingControlSizingProperties:Array = new Array();
    controls.forEach(function(control:UIComponent, index:int, array:Array):void {
      var sizingProperties:Object = controlSizingProperties[index];
      if ((sizingProperties != null) && (sizingProperties.width != undefined)) {
        stretchingControls.push(control);
        stretchingControlSizingProperties.push(sizingProperties);
      }
    });
    var evenlySizedControls:Array = controls.filter(function(control:UIComponent, index:int, array:Array):Boolean {
      var sizingProperties:Object = controlSizingProperties[index];
      return (sizingProperties != null) && (sizingProperties.width == undefined);
    });
    var widthLeft:int = unscaledWidth - LayoutHelper.resizeAsPreferred(preferredSizedControls);
    widthLeft = LayoutHelper.resizeAsSpecified(stretchingControls, stretchingControlSizingProperties, widthLeft);
    LayoutHelper.resizeEvely(evenlySizedControls, widthLeft);
		LayoutHelper.layoutLinearly(unscaledHeight, controls);
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

    dispatchEvent(new ControlBarEvent(ControlBarEvent.ATTACHED));
	}

	private function detach():void {
		log.debug("Detaching");
		previousVideoDisplay.removeEventListener(VideoEvent.STATE_CHANGE, onVideoDisplayStateChange);
		previousVideoDisplay.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, onVideoDisplayPlayheadUpdate);
    previousVideoDisplay.removeEventListener(ProgressEvent.PROGRESS, onVideoDisplayProgress);

    dispatchEvent(new ControlBarEvent(ControlBarEvent.DETACHED));
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
      dispatchEvent(new ControlBarEvent(ControlBarEvent.STARTING));
			_videoDisplay.play();
		} else {
			log.debug("Pause");
      dispatchEvent(new ControlBarEvent(ControlBarEvent.PAUSING));
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
    dispatchEvent(new ControlBarEvent(ControlBarEvent.SEEKING));
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
    var playing:Boolean = _videoDisplay.playing;
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
        dispatchEvent(new ControlBarEvent(ControlBarEvent.SEEKED));
			}
      dispatchEvent(new ControlBarEvent(ControlBarEvent.PLAYING));
		}
    if (paused) {
      dispatchEvent(new ControlBarEvent(ControlBarEvent.PAUSED));
    }
    if (stopped) {
      dispatchEvent(new ControlBarEvent(ControlBarEvent.STOPPED));
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
			playheadTime.text = formatTime(time, _videoDisplay.totalTime);
			invalidateDisplayList();
    } else {
      log.debug("Ignoring playhead slider update: " + _videoDisplay.playheadTime);
    }
  }

	private function formatTime(current:Number, total:Number):String {
    var totalHours:int = Math.floor(total / 3600);
    var totalFullMinutes:int = Math.floor((total / 60) % 3600);
    var totalFullSeconds:int = Math.floor(total % 60);
    var hasHours:Boolean = totalHours > 0;
    var hasMinutes:Boolean = totalFullMinutes > 0;
    var totalResult:String = ((totalFullSeconds < 10) && (hasMinutes || hasHours) ? "0" : "") + totalFullSeconds;
		var currentHours:int = Math.floor(current / 3600);
		var currentFullMinutes:int = Math.floor((current / 60) % 3600);
		var currentFullSeconds:int = Math.floor(current % 60);
		var currentResult:String = ((currentFullSeconds < 10) && (hasMinutes || hasHours) ? "0" : "") + currentFullSeconds;
		if (hasMinutes) {
			totalResult = ((totalFullMinutes < 10) && hasHours ? "0" : "") + totalFullMinutes + ":" + totalResult;
			currentResult = ((currentFullMinutes < 10) && hasHours ? "0" : "") + currentFullMinutes + ":" + currentResult;
		}
		if (hasHours) {
			totalResult = totalHours + ":" + totalResult;
			currentResult = currentHours + ":" + currentResult;
		}
		return currentResult + "\n" + totalResult;
	}

  private function onVideoDisplayProgress(event:ProgressEvent):void {
    log.debug("Progress: " + _videoDisplay.bytesLoaded + "/" + _videoDisplay.bytesTotal);
    playheadSlider.progress = 100 * (_videoDisplay.bytesLoaded / _videoDisplay.bytesTotal);
  }
}
}
