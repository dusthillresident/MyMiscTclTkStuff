#!/usr/bin/env tclsh
package require Tk
package require Img

source "cmdargs.tcl"

set chars "`.,;/|GHH"

proc get {i} {
 string range $::chars $i $i
}

set lastColour -1

if { ! [llength $argv] } {
 puts "usage: $argv0 (picture file)"
 exit 0
}

set filePath [lindex $argv 0]
set argv [lrange $::argv 1 end]



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

set amplify [cmdArgIsUsed -amplify]

if { $amplify } {
 set channels [lrepeat 3 {255 0}]
 for {set y 0} {$y < [image height img] } {incr y} {
  for {set x 0} {$x < [image width img] } {incr x} {
   set p [img get $x $y]
   set n 0
   foreach i $p {
    lassign [lindex $channels $n] min max
    set min [expr { min($min,$i) }]
    set max [expr { max($max,$i) }]
    lset channels $n [list $min $max]
    incr n
   }
  }
 }
 foreach i $channels {
  lassign $i min max
  lappend ampCoefficients [list $min [expr { 255.0 / ($max - $min) }]]
 }
 puts "amp coefficients: $ampCoefficients"
}

cmdArgAlias -bumpstart -bs
cmdArgAlias -bumpamount -ba
cmdArgAlias -bumpamount -bu
cmdArgAlias -bumpdown -bd

set bumpStart [cmdArg -bumpstart 0]
set bumpAmount [cmdArg -bumpamount 0]
set bumpDown [cmdArg -bumpdown 1.0]
set bumpDown [expr { double( $bumpDown )}]
set bump [expr {$bumpStart || $bumpAmount}]

set saturate [cmdArg -sat 0.0]
if { $saturate != 0.0 } {
 set saturation [expr { double($saturate) }]
 set saturate 1
} else {
 set saturate 0
}

proc ::tcl::mathfunc::special {x} {
 #expr { 1.0-((1.0-$x)**2.0) }
 expr { $x*$x }
 #expr { ($x*$x*0.5 + $x*0.5)**2.0 }
}

proc ::tcl::mathfunc::dither {x} {
 upvar x X y Y
 set ditherv [expr { ($X + $Y) & 1 }]
 set f [expr { $x - int($x) }]
 set x [expr { int( $x ) }]
 expr { $x + ($f >= 0.5 && $ditherv) }
}


proc doPixel {x y} {
 set c [img get $x $y]
 if {$::saturate} {
  set av [expr { [::tcl::mathop::+ {*}$c] / 3.0 }]
  set c [lmap i $c {
   set d [expr { $av - $i }]
   set s [expr { $d < 0 ? 1 : -1 }]
   set res [expr { max( min( int( $i + (($d/128.0)**2.0)*128.0*$::saturation*$s ), 255 ), 0 ) }]
   set res
  }]
 }
 if { $::amplify } {
  set n 0
  set c [lmap rgb $c {
   lassign [lindex $::ampCoefficients $n] min mul
   expr { int( ($rgb - $min) * $mul ) }
  }]
 }
 if { $::bump } {
  set n 0
  set c [lmap rgb $c {
   expr { int( $rgb >= $::bumpStart ? ( $::bumpStart + $::bumpAmount + ($rgb-$::bumpStart) / double(255-$::bumpStart) * (255.0-$::bumpStart-$::bumpAmount)   ) : $rgb * $::bumpDown ) }
  }]
 }
 set brightness [::tcl::mathfunc::max {*}$c]
 set average [expr { [::tcl::mathop::+ {*}$c] / 3.0  }]
 set col [expr { $brightness > 96 }]
 foreach i [lreverse $c] {
  set col [expr { ($col<<1) |  ( ( dither($i / 16.0)+1 >= ($brightness >> 4) ) && ($i > 44) )   }]
 }
 if { $::lastColour != $col } {
  puts -nonewline "\x1b\[38;5;[set col]m"
  set ::lastColour $col
  #puts -nonewline "38;5;[set col]m"
 }
 #set ch [get [expr { dither(  special(($average+$brightness)/2.0 / 256.0) * 8.0  ) }]]
 set ch [get [expr { dither(  special($brightness / 256.0) * 8.0  ) }]]
 puts -nonewline $ch
}

checkCmdArgs

puts -nonewline "\x1b\[40m"
for {set y 0} {$y < [image height img] } {incr y} {
 for {set x 0} {$x < [image width img] } {incr x} {
  doPixel $x $y
 }
 puts {}
}

exit
