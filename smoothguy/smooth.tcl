package require Tk
set counter 0
set npics 27
foreach i [lsort [glob *.png]] {
 set pics($counter) [image create photo -file $i]
 incr counter
}

pack [label .l]

proc range {start end} {
 while {abs($start-$end)} {
  lappend out $start
  incr start [expr {$end-$start>0 ? 1 : -1}]
 }
 lappend out $start
 return $out
}

set frameLists [list \
 [range 0 14] \
 [range 16 30] 
]
set counter 0
set current 0

set pi [expr acos(0)*2]

set omul 3
set mul 3
pack [scale .s -from 1 -to 8 -resolution 0 -variable mul -orient h] -fill x  

set numCapturedFrameLists 999
set captureFrameCounter 1000

proc nextFrame {} {
 global counter current frameLists pi pics mul numCapturedFrameLists captureFrameCounter
 set thisList [lindex $frameLists $current]
 set l [llength $thisList]
 set v [expr { int(( ((-cos( ( $counter/double($l*$mul+0) )*$pi )+1)*0.5) )*$l) }]
 .l configure -image $pics([lindex $thisList $v])
 if {$numCapturedFrameLists < [llength $frameLists]} {
  $pics([lindex $thisList $v]) write frameoutput/$captureFrameCounter.png;
  incr captureFrameCounter
 }
 incr counter
 if {$counter >= int($l*$mul)} {
  set current [expr {($current+1)%[llength $frameLists]}]
  set counter 0
  incr numCapturedFrameLists
 }
 after 17 nextFrame
}

nextFrame
