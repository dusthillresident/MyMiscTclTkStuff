package require Tk

proc generate {lists} {
 set out ""
 foreach i $lists {
  append out [lindex $i [expr {int(rand()*[llength $i])}]]
 }
 return $out
}

proc randomname {} {

 append name [generate {
  {Mr. Ms. Mrs. Mx.}
 }]
 append name " "

 append name [generate {
  {Pa Ha Da Ro Ste Ru Wi Si Ja Theo A Ai}
  {tt tr v n b m l p d rr}
  {y ick yn id ve iel ik ert ian son on ore in} 
 }]
 append name " "

 append name [generate {
  {Be Wi Co Wo Ma Po Ho Ha}
  {nn l ck dgr ckb {} w p rr ls v }
  {ett en oft ove urn y ell er is on}
 }]

 return $name

}

pack [button .b -text "Generate" -command { set nameResultVariable [randomname] } ] -side right
pack [entry .e -textvariable nameResultVariable -font {-size 20}] -side left -fill x -expand 1

.b invoke