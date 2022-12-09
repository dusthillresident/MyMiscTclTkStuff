
# Memory Graph
# Show a graph of how much memory is free on the system

package require Tk

proc read_memory_info {} {
 set f [open "|free"]
 set out [read $f]
 close $f
 return $out
}

#set count 0; foreach i [read_memory_info] { puts "$count	$i"; incr count }; exit

set graph_max_size 1200
set graph_max_size_sb $graph_max_size
set graph_update_interval 1760
set graph_update_interval_sb $graph_update_interval

set m [read_memory_info]
set total_memory [lindex $m 7]
set total_swap [lindex $m 14]

# 'Graph item' structure:
#0: Name of this graph item. This is the name that's presented on the graph colour key list, as well as the name of the variable containing the list of graph points.
#1: 'lindex' to the output of 'free'. This is used for updating this graph item.
#2: Max value. This is used for deciding how tall the graph line should be.
#3: Graph colour. The colour that this graph item is drawn in.

set graph_items {}

lappend graph_items \
 [list "Used memory"        8  $total_memory  red ] \
 [list "Free memory"        9  $total_memory  green ] \
 [list "Available memory"  12  $total_memory  orange ] \
 [list "Free swap"         16  $total_swap    cyan ] \
 [list "Used swap"         15  $total_swap    magenta ] \
 [list "Buff/cache"        11  $total_memory  pink ] \
 [list "Shared"            10  $total_memory  blue ]

proc update_graph_data {} {
 global graph_items graph_max_size
 set m [read_memory_info]
 foreach i $graph_items {
  lassign $i item index maxVal colour
  upvar "#0" $item graphList
  if {[llength [lappend graphList [lindex $m $index]]] > $graph_max_size} {
   set graphList [lrange $graphList 1 end]
  }
 }
}


# prepare the GUI
pack [frame .topframe] -fill x 
pack [labelframe .topframe.lf1 -text "Update interval (ms)"] -fill x -padx 2 -pady 2 -side left -expand 1
pack [spinbox .topframe.lf1.sb -textvariable graph_update_interval_sb -width 4 -from 1 -to 5000 -command reconfigure_interval] -fill x 
pack [labelframe .topframe.lf2 -text "Max graph length"] -fill x -padx 2 -pady 2 -side left -expand 1
pack [spinbox .topframe.lf2.sb -textvariable graph_max_size_sb -width 4 -from 10 -to 5000 -command {
 if {[string is integer -strict $graph_max_size_sb] \
      && ($graph_max_size_sb>=10 && $graph_max_size_sb<=5000)} {
  set graph_max_size $graph_max_size_sb
 }
}] -fill x -expand 1
pack [canvas .c -relief sunken -borderwidth 1] -fill both -expand 1 -padx 2 -pady 2
bind .topframe.lf1.sb <Key> reconfigure_interval
bind .topframe.lf2.sb <Key-Return> [lindex [.topframe.lf2.sb conf -command] end]


proc reconfigure_interval {} {
 global graph_update_interval graph_update_interval_sb after_id
 if { [string is integer -strict $graph_update_interval_sb] \
       && ($graph_update_interval_sb>32 && $graph_update_interval_sb<5000) } {
  set graph_update_interval $graph_update_interval_sb
 }
 catch {
  after cancel $after_id
 }
 updater
}


proc update_graph_display {} {
 .c delete all
 global graph_items
 set w [winfo width .c]
 set h [winfo height .c]
 # Draw graph lines
 foreach i $graph_items {
  lassign $i item index maxVal colour
  upvar "#0" $item graphList
  set l [llength $graphList]
  set w_step [expr { $w/double($l-1) }]
  set h_step [expr { $h/double($maxVal) }]
  set step [expr {int($l/$w)}]
  set step [expr {$step==0?1:$step}]
  for {set j 0} {$j<$l-$step} {incr j $step} {
   set points "[lindex $graphList $j] [lindex $graphList [expr {$j+$step}]]"
   .c create line [expr {floor($w_step*$j)}]\
                  [expr { $h-int( $h_step*[lindex $points 0] ) }]\
                  [expr {floor($w_step*($j+$step))}]\
                  [expr { $h-int( $h_step*[lindex $points 1] ) }]\
                  -fill $colour -width 3
  }
 }
 # Draw the graph legend names
 set count 0
 foreach i $graph_items {
  lassign $i item index maxVal colour
  .c create text 60 [expr {10+12*$count}] -text $item -fill $colour -justify right
  incr count
 }
}

bind . <Configure> {
 update_graph_display
}

set after_id ""
proc updater {} {
 global graph_update_interval after_id
 update_graph_data
 update_graph_display
 set after_id [after $graph_update_interval updater]
}

update_graph_data

updater