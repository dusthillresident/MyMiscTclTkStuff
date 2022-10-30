
package require Tk

# --------------------------------------------------------------------
# -- tabook.tcl: a simple tab book / notebook home-made tk 'widget' --
# --------------------------------------------------------------------


# ------------------------
# -- _tabbook_adjustCol --
# ------------------------
# A procedure that brightens or darkens a given colour. This is used by 'tabbook' to give the inactive tabs a dimmed colour.
# parameters:
#  col          The input colour
#  mul          The colour multiplication coefficient.
#               E.g. a value of 1.0 will return the same colour you put in, 
#               and value of 0.5 will return a darker colour, and 1.5 a brighter colour, etc.
# returns:
#  A 24bit hex colour value string.

proc _tabbook_adjustCol {col mul} {
 foreach i {r g b} j [winfo rgb . $col] {
  if {[set $i [expr {(int($j*$mul)>>8)}]]>255} {set $i 255}
 }
 return [format "#%02x%02x%02x" $r $g $b]
}


# -------------
# -- tabbook --
# -------------
# Tab book 'widget'. It shows a group of buttons ('tabs') at the top, and a currently active window underneath.
# The tabs switch between which window is visible. The tab corresponding to the currently visible window will appear brighter than the others.
# parameters:
#  win          The name of the window to be created for the tab book.
# returns:
#  The name of the window created. This is also the widget command for the tab book that was created.
# global variables used:
#  _tabbook     An array containing info such as the number of tabs in each tabbook, lists of the tab buttons, etc.

# tab book widget command:
#  pathname add window title
#   Adds a window to the tab book, with 'title' as the name that appears on the tab. Must be a child of the tab book window.
#   Returns the number of the tab created.
#  pathname tab tabNumber
#   Sets the tab specified by tabNumber as the currently active/visible tab.

proc tabbook {win} {
 frame $win
 $win conf -relief raised -borderwidth 1
 rename $win main_frame$win
 pack [frame $win.tabsframe -relief raised -borderwidth 1] -side top -fill x 
 scrollbar $win._colref
 global _tabbook
 set _tabbook($win+numTabs) 0
 set _tabbook($win+tabButtons) ""
 proc $win {args} {
  global _tabbook
  set thisTabBook [lindex [info level 0] 0]
  switch -- [lindex $args 0] {
   add {
    if { [llength $args] != 3 } {
     error "wrong # args: should be \"$thisTabBook add window title\""
    }
    set tabno [incr _tabbook($thisTabBook+numTabs)]
    foreach i {addwin addtitle} j [lrange $args 1 3] {
     set $i $j
    }
    set newTabButton $thisTabBook.tabsframe.b$tabno
    pack [button $newTabButton -command "$thisTabBook tab $tabno" -text $addtitle -borderwidth 1] -side left
    lappend _tabbook($thisTabBook+tabButtons) $newTabButton
    set _tabbook($thisTabBook+tab$tabno) $addwin
    if {![info exists _tabbook($thisTabBook+current)]} {
     $thisTabBook tab $tabno
    } else {
     $thisTabBook tab $_tabbook($thisTabBook+curTabNo)
    }
    return $tabno
   }
   tab {
    if { [llength $args] != 2 } {
     error "wrong # args: should be \"$thisTabBook tab tab_number\""
    }
    set tabToSwitchTo [lindex $args 1]
    if {![info exists _tabbook($thisTabBook+tab$tabToSwitchTo)]} {
     error "requested tab number doesn't exist"
    }
    catch { pack forget $_tabbook($thisTabBook+current) }
    set dimCol "darkgrey"
    set brightCol "lightgrey"
    foreach i [$thisTabBook._colref conf] {
     switch -- [lindex $i 0] {
      -background {
       set brightCol [lindex $i end]
      }
     }
     set dimCol [_tabbook_adjustCol $brightCol 0.85]
    }
    foreach i $_tabbook($thisTabBook+tabButtons) {
     $i conf -background $dimCol
    }
    $thisTabBook.tabsframe.b$tabToSwitchTo conf -background $brightCol
    set _tabbook($thisTabBook+current) $_tabbook($thisTabBook+tab$tabToSwitchTo)
    set _tabbook($thisTabBook+curTabNo) $tabToSwitchTo
    pack $_tabbook($thisTabBook+current) -side bottom -fill both -expand 1
   }
   default {
    error "bad option \"[lindex $args 0]\": must be add, or tab"
   }
  }
  return ""
 }
 return $win
}


# -------------------------
# -- demonstration stuff --
# -------------------------

set t [tabbook .t]
pack .t -fill both -expand 1

frame .t.f1
pack [label .t.f1.l -text "label in frame 1"]
pack [button .t.f1.b -text test]

frame .t.f2
pack [label .t.f2.l -text "script evaluator"]
pack [button .t.f2.b -text "evaluate" -command {
 set myscript [.t.f2.tf.t get 0.0 end]
 if [catch {
  set myresult [eval $myscript]
 } myresultvar] {
  set myresult $myresultvar
 }
 .t.f2.r delete 0.0 end
 .t.f2.r insert 0.0 $myresult
}]
pack [frame .t.f2.tf]
grid [text .t.f2.tf.t -height 12 -xscrollcommand {.t.f2.tf.sbh set} -yscrollcommand {.t.f2.tf.sbv set} ]\
     [scrollbar .t.f2.tf.sbv -command {.t.f2.tf.t yview}] -sticky nsew
grid [scrollbar .t.f2.tf.sbh -orient horiz -command {.t.f2.tf.t xview} ] -sticky ew
grid columnconfigure .t.f2.tf 0 -weight 1
grid rowconfigure .t.f2.tf 0 -weight 1
pack [label .t.f2.rl -text "result:"]
pack [text .t.f2.r] 


.t add .t.f1 "Tab #1"
.t add .t.f2 "Script tester"
if {![catch { package require Img }] && ![catch {image create photo mypic -file "satanya.jpg"}]} {
 frame .t.f3
 pack [label .t.f3.l -image mypic]
 .t add .t.f3 "Satanya"
}
