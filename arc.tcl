package require Tk

set startAng 0
set extAng 359

frame .a
pack [label .a.l -text "Start"] -side left -pady 5
pack [spinbox .a.s -textvariable startAng -from 0 -to 359 -wrap 1 -command updateArc] -side right
frame .b
pack [label .b.l -text "Extent"] -side left -pady 5
pack [spinbox .b.s -textvariable extAng -from 0 -to 359 -wrap 1 -command updateArc] -side right
pack .a -fill x
pack .b -fill x

foreach i {.a.s .b.s} {
 foreach j {<ButtonPress> <ButtonRelease> <Key-Return> <KeyPress> <KeyRelease>} {
  bind $i $j {
   updateArc
  }
 }
}

pack [ canvas .c ] -fill both -expand 1

set ovalItem [ .c create oval 0 0 10 10 -outline white]
set arcItem  [ .c create arc 0 0 10 10 -fill darkblue -outline white -start $startAng -extent $extAng ]


if {[tk windowingsystem] eq "x11"} {
 foreach i {.a.s .b.s} {
  bind $i <Button-4> "
   $i invoke buttonup
  "
  bind $i <Button-5> "
   $i invoke buttondown
  "
 }
} else {
 foreach i {.a.s .b.s} {
  bind $i <MouseWheel> "if %D<0 \{ $i invoke buttondown \} else \{ $i invoke buttonup \}"
 }
}

if 0 {
foreach i [bind .a.s] {
 puts "a: $i	[bind .a.s $i]"
}

foreach i [bind .b.s] {
 puts "b: $i	[bind .b.s $i]"
}

bind .c <Button-5> { puts "penistos" }
}

#puts $arcItem

#puts [.c itemconfigure $arcItem]

proc updateArc {} {
 global ovalItem arcItem startAng extAng
 set w [winfo width .c ]
 set h [winfo height .c ]
 set wh [expr { int(($w<$h ? $w : $h)*0.925) }]
 set x [expr {($w-$wh)>>1}]
 set y [expr {($h-$wh)>>1}]
 .c coords $arcItem  $x $y [expr {$wh+$x}] [expr {$wh+$y}]
 .c coords $ovalItem $x $y [expr {$wh+$x}] [expr {$wh+$y}]
 if {[string is double -strict $startAng] && [string is double -strict $extAng]} {
  .c itemconfigure $arcItem -start $startAng -extent $extAng
 }
}

bind . <Configure> {
 updateArc
}
wm title . "FunWithArcs"