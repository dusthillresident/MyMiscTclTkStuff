package require Tk
tk appname "Yin-Yang"

# ...........................................................
# .. Yin-Yang shape with configurable scaling and rotation ..
# ..  by dust hill resident AKA patty                      ..
# ...........................................................

set PI 3.1415926535897931

set rotangle 0.0
set scalefactor 1.0

set mybgcol \#7f7f7f
set myscaleopts "-orient horizontal -command {update_display} -resolution 0.000001 -showvalue 0 -from 0 -to 1"
pack [canvas .yinyang -width 32 -height 32 -background $mybgcol] -fill both -expand 1
pack [eval scale .siz -variable scalefactor -label "Size" $myscaleopts] -fill x
pack [eval scale .rot -variable rotangle -label "Rotation" $myscaleopts] -fill x

set mycolour white
proc gcol {c} {
 set ::mycolour $c
}

proc cls {} { 
 foreach itm [.yinyang find all] {
  .yinyang delete $itm
 }
}

proc circlefill {x y r} {
 .yinyang create oval [expr {$x-$r}] [expr {$y-$r}] [expr {$x+$r}] [expr {$y+$r}] -fill $::mycolour -outline $::mycolour
}

proc arc {x y r st ext} {
 .yinyang create arc [expr {$x-$r}] [expr {$y-$r}] [expr {$x+$r}] [expr {$y+$r}] -start [expr {$st/$::PI*180.0}] -extent [expr {$ext/$::PI*180.0}] -fill $::mycolour -outline $::mycolour
}

proc drawyinyang {x y r a} {
 gcol black
 circlefill $x $y $r
 gcol white
 arc $x $y $r [expr {$::PI*1.5+$a}] $::PI
 foreach col1 {black white} col2 {white black} ang "[expr {$::PI*1.5-$a}] [expr {$::PI*0.5-$a}]" {
  set xx [expr {$x+cos($ang)*$r*0.5}] 
  set yy [expr {$y+sin($ang)*$r*0.5}]
  gcol $col1
  circlefill $xx $yy [expr {$r*0.5}]
  gcol $col2
  circlefill $xx $yy [expr {$r*0.1666666666666}]
 }
}

proc update_display {nul} {
 set cw [winfo width .yinyang]
 set ch [winfo height .yinyang]
 cls
 drawyinyang [expr {$cw>>1}] [expr {$ch>>1}] [expr {(($ch<$cw ? $ch>>1 : $cw>>1)-5) * $::scalefactor }] [expr {$::rotangle*$::PI}]
}

bind . <Configure> {
 update_display 0 
}

wm geometry . 256x[expr {256+84}]
