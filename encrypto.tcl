package require Tk
tk appname "dusthillresident's encrypted messages"

set state [lrepeat 16 0]

proc passkey { k } {
 global state
 set n 1
 set x {}
 foreach i $state {
  lappend x [incr n]
 }
 set state  $x
 foreach i $x {rnd}
 foreach i [split $k {}] {
  set c [scan $i %c]
  lset state 0 [expr { ((($c + [lindex $state 0]) &  0xffffffff) * 0x61c94e2d) & 0xffffffff }]
  rnd
 }
 foreach j $x {foreach i $x {rnd}}
}

proc rnd { {x 256} } {
 global state
 set o [lindex $state 0]
 set state [concat [lindex $state end] [lrange $state 0 end-1]]
 set v [lindex $state 0]
 set v [expr { (  (($v * 0x72a9e681) & 0xffffffff)  ^  ($o>>7) ) & 0xffffffff }]
 lset state 0 $v
 expr { ($v & 0x7fffffff) % $x }
}

set charTable {\" ' , . ? ! { } \n 1 2 3 4 5 6 7 8 9 0}
foreach j {a A} {
 for {set i 0} {$i < 26} {incr i} {
  lappend charTable [format %c [expr { [scan $j %c] + $i }]]
 }
}

proc encrypt {msg op} {
 global charTable
 set msg [split $msg {}]
 set result {}
 set l [llength $charTable]
 foreach char $msg {
  set index [lsearch -exact $charTable $char]
  if { $index == -1 } {
   switch -- $char {
    ; - - {error "not allowed character '$char' found\n(maybe encoding an already encoded message?)"}
    default {error "not allowed character '$char' found"}
   }
  }
  set newChar [lindex $charTable [expr ( $index $op [rnd $l] ) % $l ]]
  append result $newChar  
 }
 return $result
}

pack [frame .ftop] -fill x 
pack [labelframe .ftop.key -text Key] -side left -fill x -expand 1
pack [entry .ftop.key.e -textvariable key] -fill x -expand 1

pack [button .ftop.b4 -text "Paste message"] -side right
pack [button .ftop.b3 -text "Copy message"] -side right
pack [button .ftop.b2 -text Decode] -side right
pack [button .ftop.b1 -text Encode] -side right

pack [labelframe .f -text Message] -fill both -expand 1
pack [text .f.t -yscrollcommand {.f.s set} -width 0 -height 0] -fill both -expand 1 -side left
pack [scrollbar .f.s -command {.f.t yview}] -fill y -side right


proc encdec {op} {
 passkey $::key
 set text [string range [.f.t get 0.0 end] 0 end-1]
 if {$op eq {-}} {
  set text [string map { - { } ; \n } $text]
 }
 set msg [encrypt $text $op]
 if {$op eq {+}} {
  set msg [string map { { } - \n ; } $msg]
 }
 .f.t delete 0.0 end
 .f.t insert 0.0 $msg
}

.ftop.b1 configure -command {
 encdec +
}

.ftop.b2 configure -command {
 encdec -
}

.ftop.b3 configure -command {
 clipboard clear
 clipboard append [string range [.f.t get 0.0 end] 0 end-1]
}

.ftop.b4 configure -command {
 .f.t delete 0.0 end
 catch {.f.t insert 0.0 [clipboard get]}
}

update idletasks
wm geometry . [winfo width .]x400
