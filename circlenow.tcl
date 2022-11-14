package require Tk

image create photo p -width 640 -height 480

# Draw a filled circle into a 'photo' image
proc crcl {img x y r c} {
 set maxw [image width $img]
 set maxh [image height $img]
 set x [expr {int($x)}]
 set y [expr {int($y)}]
 set r [expr {int($r)}].0
 for {set xx [expr {int(-$r)}]} {$xx < $r} {incr xx} {
  set X [expr {$x+$xx}]
  if {$X>=$maxw} return
  if {$X>-1} {
   set l [expr {int(sin(acos($xx/$r))*$r)}]
   set yl1 [expr {$y-$l} ]
   set yl2 [expr {$y+$l} ]
   $img put $c -to $X [expr {$yl2>=$maxh?$maxh:$yl2}] [expr {$X+1}] [expr {$yl1<0?0:$yl1} ]
  }
 }
}

proc rnd {n} {
 return [expr {int(rand()*$n)}]
}

pack [button .b -command {
 crcl p [rnd [image width p]] \
        [rnd [image height p]] \
        [rnd [expr {[image height p]/2}]] \
        [lindex {red green blue purple orange cyan magenta gold silver darkblue} [rnd 10]]
} -text "Draw a circle"]
pack [label .l -image p -relief sunken -borderwidth 1]