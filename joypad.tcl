package require Tk
tk appname "Joypad tester"

if {[llength $argv]} {
 set joyDev [lindex $argv 0]
} else {
 set joyDev "/dev/input/js0"
}
if [catch {set js0 [open $joyDev {RDONLY BINARY}]}] {
 puts "Couldn't open joypad device '$joyDev'"
 exit 1
}

proc translateJoypadEvent {data} {
 binary scan $data {i s c c} joy_time joy_value joy_type joy_number
 set joy_time [expr {$joy_time & 0xffffffff}]
 set joy_type [expr {$joy_type & 0xff}]
 set joy_number [expr {$joy_number & 0xff}]
 switch $joy_type {
  1 {
   return [list [lindex {buttonRelease buttonPress} $joy_value] \
                $joy_number \
                $joy_time]
  }
  2 {
   return [list axisMoved \
                $joy_number \
                $joy_value \
                $joy_time]
  }
  129 {
   return "buttonInit $joy_number $joy_time"
  }
  130 {
   return "axisInit $joy_number $joy_time"
  }
  default {
   return "unknown $joy_time $joy_value $joy_type $joy_number"
  }
 }
}

pack [frame .f] -fill both -expand 1
pack [frame .f.buttons ] -side left -fill both -expand 1
pack [frame .f.axes ] -side right -fill both -expand 1

set oldLastEventTime 0
set lastEventTime 0

fileevent $js0 readable {
 set event [translateJoypadEvent [read $js0 8]]
 set eventType [lindex $event 0]
 set eventData [lrange $event 1 end]
 set oldLastEventTime $lastEventTime
 switch $eventType {
  buttonInit {
   lassign $eventData buttonNumber lastEventTime
   set oldLastEventTime $lastEventTime
   pack [button .f.buttons.b$buttonNumber -text "Button $buttonNumber" -background black -disabledforeground white -state disabled]
  }
  axisInit {
   lassign $eventData axisNumber axisValue lastEventTime
   set oldLastEventTime $lastEventTime
   pack [scale .f.axes.a$axisNumber -label "Axis $axisNumber" -orient h -from -32768 -to 32767 -resolution 1 -state disabled -length 150]
  }
  buttonPress {
   lassign $eventData buttonNumber lastEventTime
   .f.buttons.b$buttonNumber configure -disabledforeground black -background white
  }
  buttonRelease {
   lassign $eventData buttonNumber lastEventTime
   .f.buttons.b$buttonNumber configure -disabledforeground white -background black
  }
  axisMoved {
   lassign $eventData axisNumber axisValue lastEventTime
   .f.axes.a$axisNumber configure -state normal
   .f.axes.a$axisNumber set $axisValue
   .f.axes.a$axisNumber configure -state disabled
  }
 }
}