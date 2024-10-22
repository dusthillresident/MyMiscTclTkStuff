package require Tk
tk appname "Pentomino Puzzle Solver"

# ==========================
# ==== Board management ====
# ==========================

set board 0
set boardW 0
set boardH 0
set boardMask [expr [string cat "0b" [string repeat "1" [expr {21*21}]]]]
set rowMask [expr 0b111111111111111111111]
set dotMask [expr 0b100000000000000000000]

proc makeBoard {w h} {
 global board boardMask boardW boardH rowMask
 set row [string cat [string repeat "0" $w] [string repeat "1" [expr {21-$w}]]]
 set board [expr [string cat "0b" \
  [string repeat [string repeat "1" 21] [expr {21-$h}]] \
  [string repeat $row $h] \
 ]]
 set boardW $w
 set boardH $h
 set ::defaultwinw [expr {$boardW*24.0+4.0}]
 set ::defaultwinh [expr {$boardH*24.0+4.0}]
 set ::savedBoard $board
 $::solverCanvas configure -width $::defaultwinw -height $::defaultwinh
}

# ==========================
# ==== Piece management ====
# ==========================

proc _makePiece {a} {
 set a [lmap i $a { string cat $i [string repeat "0" [expr {21-[string length $i]}]] }]
 return [expr [join [join [list "0b" $a]] ""]]
}

proc rotatos {a} {
 set a [lmap i $a {split $i ""}]
 set w [llength [lindex $a 0]] 
 set h [llength $a]
 set new [string repeat "{[string repeat 0\  $h]} " $w]
 for {set y 0} {$y<$h} {incr y} {
  for {set x 0} {$x<$w} {incr x} {
   lset new $x [expr {$h-1-$y}] [lindex $a $y $x]
  }
 }
 return [lmap i $new { join [lrange $i 0 end] "" }]
}

proc makePiece {a} {
 foreach j {1 2} {
  foreach i {1 2 3 4} {
   incr arr([_makePiece $a])
   set a [rotatos $a]
  }
  set a [lmap i $a {string reverse $i}]
 }
 return [array names arr]
}

# ................................
# . Definition of all the pieces .
# ................................

set pieces [list \
 [makePiece {
   100
   100
   111
  }] \
 \
 [makePiece {
   100
   111
   001
  }] \
 \
 [makePiece {
   1111
   0010
  }] \
 \
 [makePiece {
   001
   011
   110
  }] \
 \
 [makePiece {
   010
   010
   111
  }] \
 \
 [makePiece {
   100
   111
   010
  }] \
 \
 [makePiece {
   1110
   0011
  }] \
 \
 [makePiece {
   0001
   1111
  }] \
 \
 [makePiece {
   11111
  }] \
 \
 [makePiece {
   110
   111
  }] \
 \
 [makePiece {
   010
   111
   010
  }] \
 \
 [makePiece {
   11
   01
   11
  }] \
 \
 ]

# ============================================================
# ==== Conversion of piece data for canvas representation ====
# ============================================================

proc p {x y} {
 set x [expr {[expr $x]>>1}]
 set y [expr {[expr $y]>>1}]
 if {$x<0 || $y<0} {return 0}
 upvar p p
 global dotMask
 return [expr {$p & ($dotMask>>$x<<$y*21)}]
}

proc lrotate {l n} {
 set n [expr {$n % [llength $l]}]
 return [join [list [lrange $l $n end] [lrange $l 0 $n-1]]]
}

proc makePieceVertexList {p} {
 set x 0
 set y 0
 while {![p $x $y]} {
  incr y
 }
 set endy [expr {$y+1}]
 set dirx {  0   1   0  -1  }
 set diry {  -1  0   1   0  }
 set direction 1 
 while 1 { 
  lappend out [list $x $y]
  if {!$x && $y==$endy} break
  set l [list [p $x $y-1] [p $x+1 $y] [p $x $y+1] [p $x-1 $y]]
  lassign [lrotate $l $direction] up right down left
  set direction [expr {($direction + -($up && $left) + (!$up && $right)) & 3}]
  incr x [lindex $dirx $direction]
  incr y [lindex $diry $direction]
 }
 return [join $out]
}

set pieceColourList {green red blue violet orange khaki slate\ grey slate\ blue goldenrod cyan magenta orchid}

set n 0
foreach piece $pieces {
 foreach variant $piece {
  set pieceVertices($variant) [makePieceVertexList $variant]
  set pieceColours($variant) [lindex $pieceColourList $n] 
 }
 incr n
}
unset variant

# =======================
# ==== Puzzle solver ====
# =======================

proc findFirstEmpty {} {
 global board boardW boardH dotMask rowMask
 set row $rowMask
 for {set y 0} {$y<$boardH} {incr y; set row [expr {$row<<21}]} {
  if {($board&$row)!=$row} {
   set dot [expr {$dotMask<<$y*21}]
   for {set x 0} {$x<$boardW} {incr x; set dot [expr {$dot>>1}]} {
    if {!($board & $dot)} {
     return [list $x $y $dot]
    }
   }
  }
 }
 error "findFirstEmpty is expected to be called only when we are certain that is an empty square on the board, this should not happen"
}

proc isPossibleFiller {m} {
 global fboard
 incr fboard $m
 set c 1
 foreach i [list [expr {$m>>21}] [expr {$m<<21}] [expr {$m<<1}] [expr {$m>>1}]] {
  if {$i && !($fboard & $i)} {
   incr c [isPossibleFiller $i]
  }
 }
 return $c
}

proc isPossible {} {
 global fboard board boardMask
 lassign [findFirstEmpty] x y m
 set fboard $board
 return [expr {[isPossibleFiller $m]%5==0}]
}

set pieceIsAvailable {1 1 1 1 1 1 1 1 1 1 1 1}
set solutionsFound 0

proc solve {} {
 global pieces board boardW boardH pieceIsAvailable boardMask solutionsFound solverUpdateCounter solverPaused solverAnimate solverAutoPause solverCancel
 if {$solverCancel} return
 set pieceNum 0
 foreach piece $pieces {

  if {[lindex $pieceIsAvailable $pieceNum]} {

   lassign [findFirstEmpty] firstEmptyX y firstEmptyMask
   set holdBoard $board

   foreach variant $piece {

    for {set x [expr {$firstEmptyX>2?$firstEmptyX-3:0}]} {$x<=$firstEmptyX} {incr x} {

      set p [expr {$variant>>$x<<$y*21}]
      if {!($firstEmptyMask&$p) || $board & $p} continue
      set board [expr {$board|$p}]

      if {$board==$boardMask} {
       incr solutionsFound

       updateGui
       if {$solverAutoPause} {
        set solverPaused 1
        . conf -cursor {}
        .solverScreen.topRow.step configure -state normal
        yield
       }

       set board $holdBoard
       continue
      }

      if {[isPossible]} {
       lset pieceIsAvailable $pieceNum 0

       if {$solverPaused} {
        updateGui
        yield
       } elseif {$solverAnimate} {
        updateGui
       } else {
        # We want the gui to remain responsive even while the solver is running
        if {![set solverUpdateCounter [expr {$solverUpdateCounter+1 & 0xff}]]} update
       }

       solve
       if {$solverCancel} return
       lset pieceIsAvailable $pieceNum 1
      }

      set board $holdBoard
      
    }

   }

  }

  incr pieceNum
 }
}

proc verifyPossible {} {
 global board fboard boardMask
 set holdBoard $board
 set fboard $board
 set result 1
 while {$fboard != $boardMask} {
  if {[catch {lassign [findFirstEmpty] x y m}]} {
   set result 0
   break
  }
  if {[isPossibleFiller $m]%5} {set result 0; break}
  set board $fboard
 }
 set board $holdBoard
 return $result
}

proc solverReset {} {
 for {set i 0} {$i<12} {incr i} {
  lset ::pieceIsAvailable $i [set ::pieceSwitch$i]
 }
 set ::solutionsFound 0
 set ::solverCancel 0
 set ::solverPaused $::solverStartPaused
 set ::solverCompleted 0
 set ::board $::savedBoard
}

# ==================
# ==== Main GUI ====
# ==================

# .................
# . Solver screen .
# .................

frame .solverScreen

set selectedWidth 6
set selectedHeight 10
set solverPaused 0
set solverAutoPause 1
set solverAnimate 0
set solverStartPaused 0
set solverUpdateCounter 0
set solverCancel 0
set solverCompleted 0

pack [frame .solverScreen.topRow ] -fill x
pack [checkbutton .solverScreen.topRow.pause -text "Paused" -variable solverPaused -command {
 .solverScreen.topRow.step configure -state [lindex {disabled normal} $solverPaused]
 if {!$solverPaused} {
  . conf -cursor watch
  solverCoroutine
 } else {
  . conf -cursor {}
 }
} ] -side left
pack [button      .solverScreen.topRow.step -text "Step" -state disabled -command solverCoroutine] -side left
pack [button      .solverScreen.topRow.cancel -text "Cancel" -command {
 if {$::solverCompleted} {
  switchToOptions
 } else {
  set ::solverCancel 1
  if {$::solverPaused} {
   solverCoroutine
  }
 }
}] -side left
pack [checkbutton .solverScreen.topRow.animate -text "Animate" -variable solverAnimate ] -side left
pack [checkbutton .solverScreen.topRow.autoPause -text "Autopause" -variable solverAutoPause ] -side left
pack [label       .solverScreen.topRow.spacer] -side right -fill x -expand 1

pack [canvas      .solverScreen.solver -background black] -fill both -expand 1

# ..........................................
# . Options and board configuration screen .
# ..........................................

frame .optionScreen

# top row
pack [frame   .optionScreen.topRow -borderwidth 1 -relief raised] -fill x 
pack [button  .optionScreen.topRow.solve -text Solve] \
     [label   .optionScreen.topRow.l1 -text Width:] \
     [ttk::spinbox .optionScreen.topRow.w -textvariable selectedWidth -width 3 -from 2 -to 20] \
     [label   .optionScreen.topRow.l2 -text Height:] \
     [ttk::spinbox .optionScreen.topRow.h -textvariable selectedHeight -width 3 -from 2 -to 20] \
     [label   .optionScreen.topRow.spacesString -text "Extra spaces: "] \
     [label   .optionScreen.topRow.spacesInfo -width 3] -side left -padx 4
pack [label   .optionScreen.topRow.spacer ] -side right -fill x -expand 1

# piece enable/disable row
button .temp; set defaultBgColour [lindex [lsearch -inline -index 0 [.temp configure] -background] end]; destroy .temp
pack [frame .optionScreen.pieceRow -borderwidth 1 -relief raised] -fill x
for {set i 0} {$i<12} {incr i} {
 set f .optionScreen.pieceRow.p$i
 pack [frame $f] -side left
 lappend pieceIconCanvases $f.canv
 pack [canvas $f.canv -width 24 -height 24 -background $defaultBgColour]
 pack [checkbutton $f.check -variable pieceSwitch$i -command "incr ::extraSpaces \[expr \{\$pieceSwitch$i?-5:5\}\]; updateExtraSpacesDisplay" ]
 set pieceSwitch$i 1
}
pack [label .optionScreen.pieceRow.spacer] -side right -fill x -expand 1

# last row, for misc options
pack [frame .optionScreen.lastRow -borderwidth 1 -relief raised] -fill x
pack [checkbutton .optionScreen.lastRow.animate -variable solverAnimate -text "Animate"] -side left
pack [checkbutton .optionScreen.lastRow.autoPause -variable solverAutoPause -text "Autopause"] -side left
pack [checkbutton .optionScreen.lastRow.startPaused -variable solverStartPaused -text "Start paused"] -side left
pack [button      .optionScreen.lastRow.flipWH -text "Rotate board" -command {
 if { !( [string is integer -strict $selectedWidth] && [string is integer -strict $selectedHeight] ) } {
  set selectedWidth $boardW
  set selectedHeight $boardH
 }
 set b $board
 set savedWH [list $selectedWidth $selectedHeight]
 set selectedWidth {}
 lassign $savedWH selectedHeight selectedWidth
 for {set x 0} {$x<$selectedWidth} {incr x} {
  for {set y 0} {$y<$selectedHeight} {incr y} {
   if {$b&($dotMask>>$y<<21*($selectedWidth-1-$x))} {.optionScreen.boardEditor.x$x,y$y invoke}
  }
 }
}] -side left

# ..............................
# . Board configuration editor .
# ..............................

pack [frame .optionScreen.boardEditor ] -fill both -expand 1

proc updateExtraSpacesDisplay {} {
 .optionScreen.topRow.spacesInfo configure -text $::extraSpaces
}

proc flipBoardCell {x y} {
 set state [set ::btn$x,$y [expr {![set ::btn$x,$y]}]]
 set colour [lindex {black white} $state]
 .optionScreen.boardEditor.x$x,y$y configure -background $colour -activebackground $colour
 global extraSpaces board dotMask
 incr extraSpaces [expr {!$state-$state}]
 updateExtraSpacesDisplay
 set board [expr {$board ^ ($dotMask>>$x<<$y*21)}]
}

image create photo £ -width 12 -height 12

proc reconfigureBoardEditor {} {
 global boardW boardH boardSpaces extraSpaces
 foreach i [winfo children .optionScreen.boardEditor] {destroy $i}
 set boardSpaces [expr {$boardW*$boardH}]
 for {set y 0} {$y<$boardH} {incr y} {
  for {set x 0} {$x<$boardW} {incr x} {
   set btn .optionScreen.boardEditor.x$x,y$y
   set ::btn$x,$y 0
   grid [button $btn -command [subst {flipBoardCell $x $y}] -image £ -background black -activebackground black] -column $x -row $y
  }
 }
 set extraSpaces [expr {$boardSpaces-5*[::tcl::mathop::+ {*}[set l {}; for {set i 0} {$i<12} {incr i} {lappend l [set ::pieceSwitch$i]}; set l]]}]
 updateExtraSpacesDisplay
 makeBoard $boardW $boardH
 after 11 fitWindow
}

foreach i {selectedWidth selectedHeight} {
 trace add variable $i {write} {apply {{args} {
  foreach i [list $::selectedWidth $::selectedHeight] {if {![string is integer -strict $i] || ($i<=0 || $i>20)} return}
  set ::boardW $::selectedWidth; set ::boardH $::selectedHeight; reconfigureBoardEditor
 }} }
}

# ..........................................................................
# . 'Solve' button and management (starting/stopping) of the puzzle solver .
# ..........................................................................

.optionScreen.topRow.solve configure -command {
 if {$extraSpaces>0} {
  tk_messageBox -title "No possible solution" \
                -message "Impossible board" \
                -detail "This board configuration is unsolvable because there is more space than can be filled by the available pieces."
 } elseif {$extraSpaces%5} {
  tk_messageBox -title "No possible solution" \
                -message "Impossible board" \
                -detail "This board configuration is unsolvable because the amount of spaces is not divisble by 5,\nwhich means that it can't be filled by pentominoes."
 } elseif {![verifyPossible]} {
  tk_messageBox -title "No possible solution" \
                -message "Impossible board" \
                -detail "This board configuration is unsolvable because it contains spaces not divisable by 5, which means that it can't be filled by pentominoes."
 } elseif {$board == $boardMask} {
  tk_messageBox -title "Something happened" -message "Something happened" -detail "Something happened"
 } else {
  # Clear the solver canvas and switch context to the puzzle solver screen
  foreach i [$solverCanvas find all] { $solverCanvas dtag $i on; $solverCanvas move $i 65536 0 }
  switchToSolver
  # Start the solver
  set savedBoard $board
  solverReset
  updateCanvas
  eval [bind $solverCanvas <Configure>]
  .solverScreen.topRow.pause configure -state normal
  set solverPaused $solverStartPaused
  .solverScreen.topRow.step  configure -state [lindex {disabled normal} $solverPaused]
  . conf -cursor [lindex {watch {}} $solverPaused]
  coroutine solverCoroutine apply {{} {
   solve
   if {$::solverCancel} {
    switchToOptions
   } else {
    tk_messageBox -title   "Report" \
                  -message "Search completed" \
                  -detail  "$::solutionsFound solutions were found."
   }
   .solverScreen.topRow.pause configure -state disabled
   .solverScreen.topRow.step  configure -state disabled
   . conf -cursor {}
   solverReset
   set ::solverCompleted 1
   set board $::savedBoard
   rename solverCoroutine {}
  }}
 }
}

proc fitWindow {} {
 set rw [winfo reqwidth  .]
 set rh [winfo reqheight .]
 set w  [winfo width  .]
 set h  [winfo height .]
 if {$rw>$w || $rh>$h} {
  wm geometry . [expr {max($rw,$w)}]x[expr {max($rh,$h)}]
 }
}

proc switchToSolver {} {
 pack forget .optionScreen
 pack .solverScreen -fill both -expand 1
 after 11 fitWindow
}
proc switchToOptions {} {
 pack forget .solverScreen
 pack .optionScreen -fill both -expand 1
 solverReset
 .solverScreen.topRow.pause configure -state normal
 .solverScreen.topRow.step  configure -state disabled
 after 11 fitWindow
}

# ===========================================
# ==== Solver canvas / graphical display ====
# ===========================================

set defaultwinw 144.0
set defaultwinh 240.0
set solverCanvas .solverScreen.solver

set linewidth 5
set n 0
foreach i $pieces {
 foreach v $i {
  set item [$solverCanvas create polygon $pieceVertices($v) \
                              -outline dark\ $pieceColours($v)\
                              -fill $pieceColours($v)\
                              -width $linewidth\
                              -tags [list p$v {pos 65536.0 0.0}]]
 }
 set c [lindex $pieceIconCanvases $n]
 set item [$c create polygon $pieceVertices($v) -outline dark\ $pieceColours($v) -fill $pieceColours($v) -width 1]
 $c scale all 0 0 3 3
 lassign [$c bbox $item] x y x2 y2
 set x [expr {12-($x2-$x)/2}]
 set y [expr {12-($y2-$y)/2}]
 $c moveto $item $x $y
 incr n
}

proc getPieceCPos {p} {
 set tag [lsearch -inline [$::solverCanvas gettags $p] pos*]
 return [lrange $tag 1 end]
}
proc setPieceCPos {p x y} {
 set tag [lsearch -inline [$::solverCanvas gettags $p] pos*]
 $::solverCanvas dtag $p $tag
 $::solverCanvas addtag [list pos $x $y] withtag $p
}

proc updateCanvas {} {
 global scf
 foreach i [$::solverCanvas find withtag on] {
  lassign [lsearch -inline [$::solverCanvas gettags $i] pos*] p x y
  $::solverCanvas moveto $i [expr {int($x*$scf+$scf/6.0)}] [expr {int($y*$scf+$scf/6.0)}]
 }
}

set scf 24.2

proc updateGui {} {
 global pieceVertices pieceColours scf solverCanvas
 set level 1
 foreach i [$solverCanvas find all] {
  $solverCanvas dtag $i on
  $solverCanvas moveto $i 65536 0
 }
 while 1 {
  if {[catch {
   upvar $level variant v x x y y
   set v
  }]} {
   updateCanvas
   update
   return
  }
  setPieceCPos p$v $x $y
  $solverCanvas addtag on withtag p$v
  incr level
 }
}

set scalingFactor 1.0

bind $solverCanvas <Configure> {
 set neww [winfo width $solverCanvas]
 set newh [winfo height $solverCanvas]
 if {$neww/$defaultwinw < $newh/$defaultwinh} {
  set a $defaultwinw
  set b $neww
 } else {
  set a $defaultwinh
  set b $newh
 }
 set factor [expr {double($b)/double($a)}]
 set undoPreviousScaling [expr {1.0/$scalingFactor}]
 $solverCanvas scale all 0 0 $undoPreviousScaling $undoPreviousScaling 
 set scalingFactor [expr {$factor*12.0}]
 $solverCanvas scale all 0 0 $scalingFactor $scalingFactor
 set scf [expr {24.0*$factor}]
 foreach i [$solverCanvas find all] {
  $solverCanvas itemconfigure $i -width [expr {$scf/4.0}]
 }
 set winw [expr {double($neww)}]
 set winh [expr {double($newh)}]
 updateCanvas
}

# ==============
# ==== Init ====
# ==============

pack .optionScreen -fill both -expand 1
makeBoard 6 10
reconfigureBoardEditor
