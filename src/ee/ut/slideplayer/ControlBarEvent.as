package ee.ut.slideplayer {
import flash.events.Event;

public class ControlBarEvent extends Event {
  public static const ATTACHED:String = "attached";
  public static const DETACHED:String = "detached";
  public static const STARTING:String = "starting";
  public static const PLAYING:String = "playing";
  public static const PAUSING:String = "pausing";
  public static const PAUSED:String = "paused";
  public static const STOPPING:String = "stopping";
  public static const STOPPED:String = "stopped";
  public static const BUFFERING:String = "buffering";
  public static const BUFFERED:String = "buffered";
  public static const SEEKING:String = "seeking";
  public static const SEEKED:String = "seeked"; 

  public function ControlBarEvent(type:String,bubbles:Boolean = false,cancelable:Boolean = false) {
    super(type, bubbles, cancelable);
  }
}
}