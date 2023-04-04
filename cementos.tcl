# Cementos - rectangle parsing function based on this youtube video https://www.youtube.com/watch?v=C9Vyn5KYKSs&start=113

package require Tk

# this proc takes an image, and returns a list of rectangles found in the image
# white coloured areas in the image are used to specify what's part of a rectangle and what isn't
# the rectangles are represented as a list like {X Y Width Height}
proc imgToRectangleList {img} {
 set w [image width $img]
 set h [image height $img]
 if {!$w || !$h} {
  error "0 width or 0 height in this image..."
 }
 set outputList {}
 set rectangleCount 0
 set currentX 0
 set currentY 0
 set currentW 0
 set currentH 0
 # Iterate through the image starting at the top left corner, moving to the right, in reading order.
 for {set y 0} {$y<$h} {incr y} {
  for {set x 0} {$x<$w} {incr x} {
   # If we find a white pixel, it becomes the top-left corner of our rectangle.
   if {[$img get $x $y] eq "255 255 255"} {
    set currentX $x
    set currentY $y
    set currentW 0
    set currentH 0
    set xxx $currentX
    # Seek to the right until we find the top-right corner of the rectangle.
    # We stop seeking once we find a pixel that isn't white or we've reached the right edge of the image and so can't go further right.
    while { ($xxx < $w) && ([$img get $xxx $currentY] eq "255 255 255") } {
     incr currentW
     incr xxx
    }
    # Seek downwards until we find the bottom edge of this rectangle.
    set yyy $currentY
    while { ($currentY+$currentH < $h) && [
     set yCheck 1
     for {set xxx $currentX} { ($xxx < min($currentX+$currentW,$w)) } {incr xxx} {
      set yCheck [expr {$yCheck && ([$img get $xxx [expr {$currentY+$currentH}]] eq "255 255 255")}]
     }
     set yCheck
    ] } {
     incr currentH
     incr yyy
    }
    # Now we have the dimensions of our rectangle. We'll append it to our output list.
    lappend outputList [list $currentX $currentY $currentW $currentH]
    # Now we must paint over white area of the rectangle we just found, so it isn't white anymore, so our rectangle finding code won't pick up the area that we've just finished mapping.
    # For fun and for visual inspection, let's paint the rectangles we found in a few different colours.
    incr rectangleCount
    $img put [lindex {red green blue purple orange magenta cyan gold} [expr {$rectangleCount & 7}]] -to $currentX $currentY [expr {$currentX+$currentW+1}] [expr {$currentY+$currentH+1}]
   } ;# endif
  } ;# next x
 } ;# next y
 return $outputList
} ;# endproc

if [llength $argv] {
 set inputImg [image create photo -file [lindex $argv 0]]
 puts [imgToRectangleList $inputImg]
 pack [label .l -image image1]
} else {
 puts "usage: $argv0 (a png image containing the rectangles you want to process)"
 exit
}