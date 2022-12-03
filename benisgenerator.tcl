package require Tk

set a [split pe/be/de/pa/pae/dee/da /]
set b {n ng m nn nh}
set c [split is/ius/ith/ix/us/uth /]

foreach i {a b c} {
 catch { 
  set f [open $i.txt]
  set $i [string map {"\n" " "} [read $f]]
  close $f
 }
}

pack [labelframe .l1 -text "Result"] -fill x -expand 1
pack [labelframe .l2 -text Parameters] -fill both -expand 1

pack [button .l1.b -text "Generate" -command generate_string] -side right
set resultVar "Result here"
pack [entry .l1.e -textvariable resultVar -font {-size 25}] -side left -fill both -expand 1

pack [entry .l2.a -textvariable a] \
     [entry .l2.b -textvariable b] \
     [entry .l2.c -textvariable c] -fill both -expand 1

proc random_list_item {list} {
 set l [llength $list]
 return [lindex $list [expr {int(rand()*$l)}]]
}
proc generate_string {} {
 global resultVar a b c
 set resultVar ""
 foreach i {a b c} {
  append resultVar [random_list_item [set $i]]
 }
}

wm title . "Benis generator"
.l1.b invoke