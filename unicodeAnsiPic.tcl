#!/usr/bin/env tclsh

set shades {░▒▓█}
if { [llength $argv] == 0 } {
 puts "Usage: $argv0 (picture)"
 exit 1
}
set filePath [lindex $argv 0]
set argv [lrange $::argv 1 end]

source "cmdargs.tcl"


set basePalette [list \
 [list 0	0	0] \
 [list 0	0	255] \
 [list 0	255	0] \
 [list 0	255	255] \
 [list 255	0	0] \
 [list 255	0	255] \
 [list 255	255	0] \
 [list 255	255	255] \
]

proc baseColourToAnsi {c} {
 set result 0
 foreach i [lreverse $c] {
  set result [expr { ($result << 1) | ($i > 128) }]
 }
 return [expr { $result | ( (($result & 1) + (($result>>1)&1) + (($result>>2)&1)) > 1 ? 8 : 0) }]
}

foreach i $basePalette {
 lappend realPalette [list $i 0 [baseColourToAnsi $i] █]
 foreach j $basePalette {
  if {$i ne $j} {
   set bg [baseColourToAnsi $i]
   set fg [baseColourToAnsi $j]
   set n 0
   for {set x 0.25} {$x<1.0} {set x [expr {$x + 0.25}]} {
    set c {}
    foreach a $i b $j {
     set d [expr { $b - $a }]
     lappend c [expr { int( $a + $d * $x ) }]
    }
    lappend extendedPalette $c
    lappend realPalette [list $c $bg $fg [lindex {░ ▒ ▓} $n]]
    incr n
   }
  }
 }
}

package require Tk
package require Img

proc loadPicture {filePath width} {
 image create photo img -file $filePath
 set w [image width img]
 set h [image height img]
 set scf [expr { $width / double($w<<1) }]
 #puts "scf $scf"
 set w [expr { int( $w * $scf * 2 ) }]
 set h [expr { int( $h * $scf ) }]
 if { [cmdArgIsUsed -hard] } {
  exec convert $filePath -interpolate Integer -filter point -resize [string cat $w x $h !] /tmp/_ansi_tmpfile.png
 } else {
  exec convert $filePath -resize [string cat $w x $h !] /tmp/_ansi_tmpfile.png
 }
 image delete img 
 image create photo img -file /tmp/_ansi_tmpfile.png
 file delete /tmp/_ansi_tmpfile.png
}

loadPicture $filePath [cmdArg -width 120]

set lastBg -1
set lastFg -1


set saturate [cmdArg -sat 0.0]
if { $saturate != 0.0 } {
 set saturation [expr { double($saturate) }]
 set saturate 1
} else {
 set saturate 0
}

set sqrV [cmdArg -sqrv 2.0]
set sqrV [expr { double( $sqrV ) }]
set square [expr { [cmdArgIsUsed -sqr] || [cmdArgIsUsed -sqrv] }]

proc doPixel {x y} {
 set c1 [img get $x $y]
 
 if {$::square} {
  set c1 [lmap i $c1 {
   expr { int( (1.0-((1.0-($i / 255.0))**$::sqrV))*255.0 ) }
  }]
 }

 if {$::saturate} {
  set av [expr { [::tcl::mathop::+ {*}$c1] / 3.0 }]
  set c1 [lmap i $c1 {
   set d [expr { $av - $i }]
   set s [expr { $d < 0 ? 1 : -1 }]
   set res [expr { max( min( int( $i + (($d/128.0)**2.0)*128.0*$::saturation*$s ), 255 ), 0 ) }]
   #puts "was $i, now $res	av $av"
   set res
  }]
  #return
 }

 set minDiff 999999999
 foreach i $::realPalette {
  set c2 [lindex $i 0]
  set thisDiff 0
  foreach rgb1 $c1 rgb2 $c2 {
   incr thisDiff [expr { abs( $rgb1 - $rgb2 ) }]
  }
  if {$thisDiff < $minDiff} {
   set minDiff $thisDiff
   set result $i
   if {$minDiff < 63} {break}
  }
 }
 lassign $result realColour ansiBg ansiFg character
 if {$ansiBg != $::lastBg} {
  puts -nonewline "\x1b\[48;5;[set ansiBg]m"
  set ::lastBg $ansiBg
 }
 if {$ansiFg != $::lastFg} {
  puts -nonewline "\x1b\[38;5;[set ansiFg]m"
  set ::lastFg $ansiFg
 }
 puts -nonewline $character
}

checkCmdArgs

puts -nonewline "\x1b\[40m"
for {set y 0} {$y < [image height img] } {incr y} {
 for {set x 0} {$x < [image width img] } {incr x} {
  doPixel $x $y
 }
 puts "\x1b\[40m"; set lastBg -1
}

exit