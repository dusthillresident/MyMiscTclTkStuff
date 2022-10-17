package require Tk
tk appname "Yin-Yang"

# ...........................................................
# .. Yin-Yang shape with configurable scaling and rotation ..
# ..  by dust hill resident AKA patty                      ..
# ...........................................................

set PI 3.1415926535897931

set rotangle 1.0
set scalefactor 1.0
set yinyangflip 0

set yinyangcolours(bg) #7f7f7f
set yinyangcolours(white) white
set yinyangcolours(black) black
image create photo bgColIcon
image create photo whiteColIcon
image create photo blackColIcon
proc update_colicons {} {
 global yinyangcolours
 foreach img {bgColIcon blackColIcon whiteColIcon} col {bg black white} {
  $img put $yinyangcolours($col) -to 0 0 14 14
 }
}
update_colicons

rename tk_chooseColor _tk_chooseColor
proc tk_chooseColor {args} {
 set result [eval _tk_chooseColor $args]
 if [string length $result] {
  return $result
 }
 for {set i 0} {$i<[llength $args]} {incr i} {
  if [string match [lindex $args $i] "-initialcolor"] {
   incr i
   return [lindex $args $i]
  }
 }
 return ""
}

set myscaleopts "-orient horizontal -command {update_display} -resolution 0.000001 -showvalue 0 -from 0 -to 1"
pack [canvas .yinyang -width 32 -height 32 -background $yinyangcolours(bg)] -fill both -expand 1
pack [eval scale .siz -variable scalefactor -label "Size" $myscaleopts] -fill x
pack [eval scale .rot -variable rotangle -label "Rotation" $myscaleopts] -fill x

pack [frame .extracontrols] -fill x
pack [checkbutton .extracontrols.flip -text "Flip" -variable yinyangflip -command {update_display 0}] -side left
foreach img {bgColIcon whiteColIcon blackColIcon} col {bg white black} str {BG Yang Yin} {
 pack [button .extracontrols.b_$img -command "set yinyangcolours\($col\) \[tk_chooseColor -title \"$str Colour\" -initialcolor \$yinyangcolours($col)\]; .yinyang configure -background \$yinyangcolours(bg); update_colicons; update_display 0" -image $img] -side right
}
pack [label .extracontrols.colourslabel -text "Colours"] -side right

set mycolour white
proc gcol {c} {
 global mycolour
 set mycolour $c
}

proc cls {} { 
 foreach itm [.yinyang find all] {
  .yinyang delete $itm
 }
}

proc circlefill {x y r} {
 global mycolour
 .yinyang create oval [expr {$x-$r}] [expr {$y-$r}] [expr {$x+$r}] [expr {$y+$r}] -fill $mycolour -outline $mycolour
}

proc arc {x y r st ext} {
 global mycolour PI
 .yinyang create arc [expr {$x-$r}] [expr {$y-$r}] [expr {$x+$r}] [expr {$y+$r}] -start [expr {$st/$PI*180.0}] -extent [expr {$ext/$PI*180.0}] -fill $mycolour -outline $mycolour
}

proc drawyinyang {x y r a yin yang} {
 global yinyangcolours mycolour PI yinyangflip
 gcol $yin
 circlefill $x $y $r
 gcol $yang
 arc $x $y $r [expr {$PI*1.5+$a}] $PI
 foreach col1 "$yin $yang" col2 "$yang $yin" ang "[expr {$PI*1.5-$a+$yinyangflip*$PI}] [expr {$PI*0.5-$a+$yinyangflip*$PI}]" {
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
 global PI scalefactor rotangle yinyangcolours
 drawyinyang [expr {$cw>>1}] [expr {$ch>>1}] [expr {(($ch<$cw ? $ch>>1 : $cw>>1)-5) * $scalefactor }] [expr {$rotangle*$PI}] $yinyangcolours(black) $yinyangcolours(white)
}

bind . <Configure> {
 update_display 0 
}

wm geometry . 280x397
