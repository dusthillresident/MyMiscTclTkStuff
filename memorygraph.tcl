
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

set graph_max_size 1000
set graph_update_interval 1760
set graph_update_interval_sb $graph_update_interval
array set graph_colours {
 freemem green
 usedmem red
 freeswp cyan
 usedswp magenta
}

set m [read_memory_info]
set total_memory [lindex $m 7]
set total_swap [lindex $m 14]

set freemem {}
set usedmem {}
set freeswp {}
set usedswp {}

proc update_mem_info {} {
 global usedmem freemem usedswp freeswp graph_max_size
 set m [read_memory_info]
 foreach i {usedmem freemem usedswp freeswp} j {8 9 15 16} {
  if {[llength [lappend $i [lindex $m $j]]] > $graph_max_size} {
   set $i [lrange [set $i] 1 end]
  }  
 }
}

update_mem_info

if 0 {
 puts $total_memory
 puts $total_swap
 puts ""
 puts $usedswp
 puts $freeswp
}


# prepare the GUI

pack [labelframe .lf1 -text "Update interval (ms)"] -fill x -padx 2 -pady 2
pack [spinbox .lf1.sb -textvariable graph_update_interval_sb -from 1 -to 5000 -command reconfigure_interval] -fill x
bind .lf1.sb <Key> {
 reconfigure_interval
}

proc reconfigure_interval {} {
 global graph_update_interval graph_update_interval_sb
 if { [string is integer -strict $graph_update_interval_sb]\
       && ($graph_update_interval_sb>32 && $graph_update_interval_sb<5000) } {
  set graph_update_interval $graph_update_interval_sb
 }
}

pack [canvas .c -relief sunken -borderwidth 1] -fill both -expand 1 -padx 2 -pady 2

#.c create oval 0 0 100 100 -fill blue -outline white
#.c delete all

proc update_graph {} {
 .c delete all
 global freemem usedmem freeswp usedswp graph_colours total_memory total_swap
 foreach i {freemem usedmem freeswp usedswp} k "$total_memory $total_memory $total_swap $total_swap" {
  set c $graph_colours($i)
  set l [llength [set $i]]
  set w [winfo width .c]
  set h [winfo height .c]
  set w_step [expr { $w/double($l-1) }]
  set h_step [expr { $h/double($k) }]
  for {set j 0} {$j<$l-1} {incr j} {
   set points [lrange [set $i] $j [expr {$j+1}]]
   .c create line [expr {floor($w_step*$j)}]\
                  [expr { $h-int( $h_step*[lindex $points 0] ) }]\
                  [expr {floor($w_step*($j+1))}]\
                  [expr { $h-int( $h_step*[lindex $points 1] ) }]\
                  -fill $c -width 3
  }
 }
 for {set count 0} {$count<4} {incr count} {
  set c $graph_colours([lindex {freemem usedmem freeswp usedswp} $count])
  .c create text 60 [expr {10+12*$count}]\
                    -text [lindex {"Free memory" "Used memory" "Free swap" "Used swap"} $count]\
                    -fill $c -justify right
 }
}

bind . <Configure> {
 update_graph
}

proc updater {} {
 global graph_update_interval
 update_mem_info
 update_graph
 after $graph_update_interval updater
}

update_mem_info
update_mem_info

updater