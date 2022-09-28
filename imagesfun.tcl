package require Tk

wm title . "Image Demo"

set img .image_1
set maxw 192
set maxh 192

frame .top
frame .f

for {set i 1} {$i <= 4} {incr i} {
 label .f.label_$i -image [image create photo .image_$i]
 .image_$i put "#000" -to 0 0 $maxw $maxh
}

grid .f.label_1 .f.label_2
grid .f.label_3 .f.label_4



pack [label .top.title -text "Click the button to render the images"] -side left
pack [button .top.b -text "Begin" -command {.top.b configure -state disabled; .top.title configure -text "Rendering, please wait..."; . configure -cursor watch; after 32 {render 1}}] -side right
pack .top .f -expand 1 -fill both


proc rgb {r g b} {
 set H "#"
 return $H[format %02x [expr {int($r)&0xff}]][format %02x [expr {int($g)&0xff}]][format %02x [expr {int($b)&0xff}]]
}

proc pixel {x y c} {
 global img maxw maxh
 if { $x < 0 || $y < 0 } return
 $img put $c -to [expr {int($x)}] [expr {int($y)}]
}

proc randomcolour {} {
 return [rgb [expr {rand()*255}] [expr {rand()*255}] [expr {rand()*255}]]
}

proc rnd {n} {
 return [expr {int(rand()*$n)}]
}

proc crcl {x y r c} {
 global img maxw maxh
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

proc render {n} {
 global img maxw maxh
 wm title . "Image Demo: rendering $n of 4"
 switch $n {
  1 {
   set img .image_1
   for {set x 0} {$x<$maxw} {incr x} {
    for {set y 0} {$y<$maxh} {incr y} {
     pixel $x $y [rgb [expr {($x ^ $y)}] [expr {($x ^ $y)<<1}] [expr {($x ^ $y)<<2}]]
    }
   }
  }
  2 {
   set img .image_2
   time { crcl [rnd $maxw] [rnd $maxh] [rnd 76] [randomcolour] } 17
  }
  3 {
   set img .image_3
   for {set x 0} {$x<$maxw} {incr x} {
    for {set y 0} {$y<$maxh} {incr y} {
     pixel $x $y [randomcolour]
    }
   }
  }
  4 {
   set img .image_4
   for {set x 0} {$x<$maxw} {incr x} {
    for {set y 0} {$y<$maxh} {incr y} {
     set v [expr {-!!($x & $y)}]
     pixel $x $y [rgb $v $v $v]
    }
   }
  }
  5 {
   wm title . "Image Demo: completed"
   .top.title configure -text "Thank you"
   . configure -cursor top_left_arrow
   .top.b configure -state normal -text "End" -command exit
   return
  }
 }
 incr n
 after 32 "render $n"
}
