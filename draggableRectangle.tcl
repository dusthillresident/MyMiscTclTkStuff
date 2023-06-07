package require Tk

set canvasw 640
set canvash 512

grid [ canvas .c -width $canvasw -height $canvash -relief sunken -borderwidth 0 -background darkblue -scrollregion "0 0 $canvasw $canvash"] [scrollbar .sbv -orient v] -sticky ns
grid [scrollbar .sbh -orient h] -sticky ew

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

.c configure -xscrollcommand {.sbh set} -yscrollcommand {.sbv set}
.sbh configure -command {.c xview}
.sbv configure -command {.c yview}


if {[lsearch -exact [info commands] lassign] == -1} {
 proc lassign { assignmentlist args } {
  set counter 0
  foreach i $args {
   uplevel 1 [subst {set $i \"[lindex $assignmentlist $counter]\"}]
   incr counter
  }
  return [lrange $assignmentlist $counter end]
 }
}


proc makeDraggableRect { canv x y w h col } {
 set x2 [expr {$x+$w}]
 set y2 [expr {$y+$h}]
 set rectItem [$canv create rectangle $x $y $x2 $y2 -outline white -fill $col -activefill red -width 2 ]
 $canv bind $rectItem <ButtonPress-1> [string map "%canv $canv %rectItem $rectItem" {
  set tempCordsList [%canv coords %rectItem]
  lassign $tempCordsList tempX tempY tempX2 tempY2
  set x [expr {[%canv canvasx %x]}]
  set y [expr {[%canv canvasy %y]}]
  %canv addtag [list dragging \
                     [expr {$tempX-1-%x}] \
                     [expr {$tempY-1-%y}] \
                     [expr { 	(-(abs($tempX-$x) <= 4) & 0b0001)
				|
				(-(abs($tempY-$y) <= 4) & 0b0010)
				|
				(-(abs($tempX2-$x) <= 4) & 0b0100)
				|
				(-(abs($tempY2-$y) <= 4) & 0b1000) } ] \
                     $tempCordsList \
               ] \
               withtag %rectItem
 }]
 $canv bind $rectItem <ButtonRelease-1> [string map "%canv $canv %rectItem $rectItem" {
  %canv dtag %rectItem [lsearch -inline [%canv gettags %rectItem] *dragging* ]
 }]
 $canv bind $rectItem <ButtonPress-2> [string map "%canv $canv %rectItem $rectItem" {
  %canv lower %rectItem
 }]
 $canv bind $rectItem <Motion> [string map "%canv $canv %rectItem $rectItem" {
  if { [set tempDragList [lsearch -inline [%canv gettags %rectItem] *dragging* ]] ne "" } {
   lassign $tempDragList {} xoff yoff dragflags oldCordsList
   if {$dragflags} {
    lassign $oldCordsList x1 y1 x2 y2
    set L [expr { !!( $dragflags & 0b0001 )}]
    set R [expr { !!( $dragflags & 0b0100 )}]
    set U [expr { !!( $dragflags & 0b0010 )}]
    set D [expr { !!( $dragflags & 0b1000 )}]
    set x [expr {[%canv canvasx %x]}]
    set y [expr {[%canv canvasy %y]}]
    set x1 [expr {$L ? $x : $x1} ]
    set y1 [expr {$U ? $y : $y1} ]
    set x2 [expr {$R ? $x : $x2} ]
    set y2 [expr {$D ? $y : $y2} ]
    if {$x1>$x2} { puts "x flipped!" }
    if {$y1>$y2} { puts "y flipped!" }
    %canv coords %rectItem $x1 $y1 $x2 $y2
   } else {
    %canv moveto %rectItem [expr %x+$xoff] [expr %y+$yoff]
   }
   unset tempDragList xoff yoff dragflags
  }
 }]
 return $rectItem
}

makeDraggableRect .c 10 10 150 100 purple
makeDraggableRect .c 240 110 60 70 teal
makeDraggableRect .c 30 50 40 40 {}