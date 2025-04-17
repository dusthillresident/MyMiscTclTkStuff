#!/usr/bin/env tclsh
package require Tk
package require Img

source "cmdargs.tcl"

set chars [cmdArg -charset " `.,;/|GHH"]
if { [cmdArgIsUsed -unicode] } {
 set chars " ░▒▓██"
}
if { [cmdArgIsUsed -unicode2] } {
 set chars " ░▒██"
}
set rangeLength [string length $chars]
incr rangeLength -1

proc get {i} {
 set i [expr { int( min( $::rangeLength, $i ) ) }]
 string range $::chars $i $i
}

if { ! [llength $argv] } {
 puts "usage: $argv0 (picture file)"
 exit 0
}

# Initialisation

# List of filter procedures to be used on input pixels
set filters {}
# The first command-line argument must be the input picture
set filePath [lindex $argv 0]
set argv [lrange $::argv 1 end]
# Set the width in characters of the output image
set width [cmdArg -width 120]
# Enable/disable interpolation of the source image
set hard [cmdArgIsUsed -hard]
# Enable/disable the 'amplify' filter
set amplify [cmdArgsAreUsed -amplify -ampinfo]
# Process command-line arguments for the 'saturation' filter
set saturate [cmdArg -sat 0.0]
if { $saturate != 0.0 } {
 set saturation [expr { double($saturate) }]
 lappend filters filter_saturate
}
# Process command-line arguments for the 'bump' filter
cmdArgAlias -bumpstart -bs
cmdArgAlias -bumpamount -ba
cmdArgAlias -bumpamount -bu
cmdArgAlias -bumpdown -bd
set bumpStart [cmdArg -bumpstart 0]
set bumpAmount [cmdArg -bumpamount 0]
set bumpDown [cmdArg -bumpdown 1.0]
set bumpDown [expr { double( $bumpDown )}]
if {$bumpStart || $bumpAmount} {lappend filters filter_bump}

# Initial resizing and loading of the source image
proc loadPicture {filePath width} {
 image create photo img -file $filePath
 set w [image width img]
 set h [image height img]
 set scf [expr { $width / double($w<<1) }]
 #puts "scf $scf"
 set w [expr { int( $w * $scf * 2 ) }]
 set h [expr { int( $h * $scf ) }]
 if { $::hard } {
  exec convert $filePath -interpolate Integer -filter point -resize [string cat $w x $h !] /tmp/_ansi_tmpfile.png
 } else {
  exec convert $filePath -resize [string cat $w x $h !] /tmp/_ansi_tmpfile.png
 }
 image delete img 
 image create photo img -file /tmp/_ansi_tmpfile.png
 if { ! [image width img] } {
  puts stderr "Failed to load image '$filePath'"
  exit 1
 }
 file delete /tmp/_ansi_tmpfile.png
}

# Get the amplification coefficients for the source image
proc amplify {} {
 set ::ampCoefficients {}
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
  lappend ::ampCoefficients [list $min [expr { 255.0 / ($max - $min) }]]
 }
 if {[cmdArgIsUsed -ampinfo]} {puts "amp coefficients: $::ampCoefficients"}
 set ::filters [concat filter_amplify $::filters]
}

# saturation filter
proc filter_saturate {c} {
 set av [expr { [::tcl::mathop::+ {*}$c] / 3.0 }]
 set c [lmap i $c {
  set d [expr { $av - $i }]
  set s [expr { $d < 0 ? 1 : -1 }]
  set res [expr { max( min( int( $i + (($d/128.0)**2.0)*128.0*$::saturation*$s ), 255 ), 0 ) }]
 }]
}

# amplification filter
proc filter_amplify {c} {
 set n -1
 lmap rgb $c {
  lassign [lindex $::ampCoefficients [incr n]] min mul
  expr { int( ($rgb - $min) * $mul ) }
 }
}

# 'bump' filter
proc filter_bump {c} {
 set n 0
 set c [lmap rgb $c {
  expr { min( 255, int( $rgb >= $::bumpStart ? ( $::bumpStart + $::bumpAmount + ($rgb-$::bumpStart) / double(255-$::bumpStart) * (255.0-$::bumpStart-$::bumpAmount)   ) : $rgb * $::bumpDown ) ) }
 }]
}

# part of the pixel conversion algorithm
proc ::tcl::mathfunc::special {x} {
 #expr { 1.0-((1.0-$x)**2.0) }
 expr { $x*$x }
 #expr { ($x*$x*0.5 + $x*0.5)**2.0 }
}

# simple dithering for the conversion algorithm
proc ::tcl::mathfunc::dither {x} {
 upvar x X y Y
 set ditherv [expr { ($X + $Y) & 1 }]
 set f [expr { $x - int($x) }]
 set x [expr { int( $x ) }]
 expr { $x + ($f >= 0.5 && $ditherv) }
}

# conversion process for pixel x,y of the source image
set lastColour -1
proc doPixel {x y} {
 set c [img get $x $y]
 foreach filter $::filters {
  set c [$filter $c]
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
 }
 set ch [get [expr { dither(  special($brightness / 256.0) * $::rangeLength  ) }]]
 puts -nonewline $ch
}

# check that the command line arguments are valid
checkCmdArgs

# load the picture now
loadPicture $filePath $width
# when amplify is enabled, we must now get the amplification coefficients
if {$amplify} {amplify}
# perform the conversion
puts -nonewline "\x1b\[40m"
for {set y 0} {$y < [image height img] } {incr y} {
 for {set x 0} {$x < [image width img] } {incr x} {
  doPixel $x $y
 }
 puts {}
}

exit
