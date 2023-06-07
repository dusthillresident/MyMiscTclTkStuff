package require Tk

proc scaleImage { img xs {ys ""} } {
 if {$ys eq ""} {
  set ys $xs
 }
 set subsampx 1
 set subsampy 1
 if {$xs<0} {
  set xs [expr {-$xs}]
  set subsampx -1
 }
 if {$ys<0} {
  set ys [expr {-$ys}]
  set subsampy -1
 }
 set new [image create photo]
 set new2 [image create photo]

 set ow [image width $img]
 set oh [image height $img]
 set nw [expr {int($ow*$xs)}]
 set nh [expr {int($oh*$ys)}]
 set xst [expr {1.0/$xs}]
 set yst [expr {1.0/$ys}]

 set xstep [expr {max(1,$nw/$ow)}]
 set ystep [expr {max(1,$nh/$oh)}]

 for {set x 0} {$x<$nw} {incr x $xstep} {
  set p [expr {int($x*$xst)}]
  $new copy $img  -from $p 0 [expr {$p+1}] $oh  -to $x 0 [expr {$x+$xstep}] $oh  -subsample 1 $subsampy
 }

 for {set y 0} {$y<$nh} {incr y $ystep} {
  set p [expr {int($y*$yst)}]
  $new2 copy $new  -from 0 $p $nw [expr {$p+1}]  -to 0 $y $nw [expr {$y+$ystep}]  -subsample $subsampx 1
 }

 $img blank
 $img copy $new2
 $img configure -width $nw -height $nh
 $img configure -width 0 -height 0

 image delete $new
 image delete $new2

}

set img [image create photo -file "pic.png"]
set img_show [image create photo]
$img_show copy $img
pack [frame .f]
set xfact 1.0
set yfact 1.0
pack [entry .f.e1 -textvariable xfact] -side left
pack [entry .f.e2 -textvariable yfact] -side right
pack [label .l -image $img_show]
pack [button .b -command {
 if {$xfact==0 || $yfact==0} {
  tk_dialog .magicpenis "Something happened" "Something happened" error "" "ok"
  return
 }
 $img_show blank
 $img_show configure -width 1 -height 1
 $img_show configure -width 0 -height 0
 $img_show copy $img
 scaleImage $img_show $xfact $yfact
} -text buton]
