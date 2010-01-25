package ee.ut.slideplayer {
import mx.controls.VideoDisplay;
import mx.controls.videoClasses.VideoPlayer;
import mx.core.mx_internal;

use namespace mx_internal;

public class EVideoDisplay extends VideoDisplay{
  public function EVideoDisplay() {
    super();
  }

  public function get aspectRatio():Number {
    return videoPlayer.width/videoPlayer.height;
  }
}
}