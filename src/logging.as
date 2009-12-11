import flash.events.Event;

import mx.logging.Log;
import mx.logging.targets.TraceTarget;

private function initializeLogging():void {
  var target:TraceTarget = new TraceTarget();
  target.includeCategory = true;
  target.includeTime = true;
  target.includeLevel = true;
  Log.addTarget(target);
}
