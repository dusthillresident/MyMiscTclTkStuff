package require Tk

proc stringToAsciiList {input} {
 foreach i [split $input {}] {
  lappend output [
   scan $i %c char
   set char 
  ]
 }
 return $output
}

proc asciiListToString {input} {
 foreach i $input {
  append output [format %c $i]
 }
 return $output
}

set cols { "#007" "#00f" "#070" "#077" "#07f" "#0f0" "#0f7" "#0ff"
           "#700" "#707" "#70f" "#f00" "#f07" "#f0f" "#f70" "#f77" }

set stopCol "#fff"

proc stringToPixelsList {input} {
 foreach i [stringToAsciiList $input] {
  lappend output [expr {$i>>4}] [expr {$i&0xf}]
 }
 return $output
}

proc pixelsListToString {input} {
 global cols
 set out ""
 foreach {i j} $input {
  append out [format %c [expr { ([lsearch $cols $i]<<4) | [lsearch $cols $j] }]]
 }
 return $out
}

proc pixelsListToPhoto {input} {
 set l [llength $input]
 set r [expr { sqrt($l) }]
 set wh [expr {int($r)}]
 if {int($r) != $r} {
  incr wh
 }
 set p [image create photo -width $wh -height $wh]
 global cols stopCol
 set c 0
 foreach i $input {
  $p put [lindex $cols $i] -to [expr {$c % $wh}] [expr {$c / $wh}]
  incr c
 }
 while {$c<$wh*$wh} {
  $p put $stopCol -to [expr {$c % $wh}] [expr {$c / $wh}]
  incr c
 }
 return $p
}

proc photoToPixelsList {p} {
 global stopCol
 set out ""
 set w [image width $p]
 set h [image height $p]
 for {set y 0} {$y<$h} {incr y} {
  for {set x 0} {$x<$w} {incr x} {
   set v "#"
   foreach i [$p get $x $y] {
    append v [lindex {0 7 f} [expr {round($i/128.0)}]]
   }
   if {$v eq $stopCol} { return $out }
   lappend out $v
  }
 }
 return $out
}

pack [frame .f] -side top
pack [frame .f2] -side bottom -fill both -expand 1

grid [text .f2.t -xscrollcommand {.f2.s2 set} -yscrollcommand {.f2.s1 set} ] [scrollbar .f2.s1 -command {.f2.t yview}] [label .f2.l] -sticky nsew
grid [scrollbar .f2.s2 -orient horiz -command {.f2.t xview}] -sticky ew

set myimage ""

pack [button .f.b -text "Update image" -command {
 set thisString [.f2.t get 0.0 end]
 if {$thisString eq "\n"} {
  return
 }
 catch {
  image destroy $myimage
 }
 set myimage [pixelsListToPhoto [stringToPixelsList $thisString]]
 .f2.l conf -image $myimage
 .f.b2 configure -state normal
}] -side left

pack [button .f.b3 -text "Load image" -command {
 set f [tk_getOpenFile]
 if {$f eq ""} {
  return
 }
 catch {image destroy $myimage}
 if [catch {set myimage [image create photo -file $f]} errormagic ] {
  tk_messageBox -title "Something happened" -message "Something happened:\n$errormagic"
  return
 }
 set thisString [pixelsListToString [photoToPixelsList $myimage]]
 .f2.t delete 0.0 end
 .f2.t insert 0.0 $thisString
 .f2.l conf -image $myimage
 .f.b2 configure -state normal
}] -side left

pack [button .f.bLoadText -text "Load text" -command {
 set f [tk_getOpenFile]
 if {$f ne ""} {
  if [catch {
   set f [open $f r]
   .f2.t delete 0.0 end
   .f2.t insert 0.0 [read $f]
   close $f
  } errormagic] {
   tk_messageBox -title "Something happened" -message "Something happened:\n$errormagic"
  }
 }
}] -side left

pack [button .f.b2 -text "Save image" -state disabled -command {
 set f [tk_getSaveFile]
 if [string length $f] {
  if [catch {$myimage write $f.png} errormagic ] {
   tk_messageBox -title "Something happened" -message "Something happened:\n$errormagic"
  }
 }
}] -side left

pack [button .f.b4 -text "Save text" -command {
 set f [tk_getSaveFile]
 if [string length $f] {
  if [
  catch {
   set f [open $f w]
   puts $f [.f2.t get 0.0 end]
   close $f
  } errormagic] {
   tk_messageBox -title "Something happened" -message "Something happened:\n$errormagic"
  }
 }
}] -side left

grid columnconfigure .f2 0 -weight 1
grid rowconfigure .f2 0 -weight 1