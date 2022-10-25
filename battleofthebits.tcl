#!/usr/bin/tclsh

# ================================
# ===== "Tcl/Tk Programming" =====
# ================================

# This is my entry for the battleofthebits.org battle "Future Battles III"

package require Tk

image create photo tcl_logo -data {
 iVBORw0KGgoAAAANSUhEUgAAAEQAAABkBAMAAADNkYu3AAAAGFBMVEUAM53NMQN0T2I0YZXNTkT4
 rKvvw1P///8EFq/vAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH5goYFiweCEG84QAAAppJ
 REFUSMfV172PmzAUAPBXoOpa35ncmqiJunKF7OeckWcaEHOWm5sGxL/f9/gINgZzJ3VorUSB8Iv9
 sJ+JDc1qAeOsLrBIWVqkvZBLLKwrvDBILaVgVkmH60VRQs1mi+yqxV8vkrH8Q4Q3f51cGHu7zJFm
 ON4sk6H7N51ykbf2ZZXwY+QytMMLsUJ42VTLpP1Uza1eIH0ovInBE0ukbUfdAPzdSJ4swssIALRa
 lE7aaEOsBAK2RNpvIrMdm3CqxO9bvQwk00kY9e1shs62iEIBO308LHKG4X4GUk4I7+6HZtgQi0Eo
 Wgpll9IgDakzJW20URxXY3ZNCfUKFq/uh3SGvEJHqpE08ySo7gnIF8ixuke7RA7ZKvmeaXMESWUT
 JZwkxpEu2DJ5aYmX66k7IV/B+waT7J6QRwiQHNkyyR8gwCHYO0hxgiTq8nKJlDc4RPDJSWIiQhoT
 YEKw1yKIawc5g08Z8w5SrRLfRX6Ct0ZO8AOJ5yJpR/QMerJIgjP2c+boujQiErhJgCTJHYRvA+zg
 xKrlOiV7i+hfbBMkB+EgfEvhSuaq5cVTmFHSRV5xAAJVrZFndWWTeaSTRxyA2M8cRD7ENNIuos7+
 Ggljyt0vwkHwgZlGcHQRzEycJHvmIipCkjsJvx0jXzgJOyW/PGYR80f727P5V24Rxn9PlnClSTg+
 5PpgZT5PWCkGwiuTcDESelpKm4R0zu+E10S41ElaC8bzvCUpETytUjmtRYl6JFRLajVU0vMLSSg6
 UlczhJmkNsmVGqJa8DjrG1KZQTC+EMPlWAsnkuMd0D1oawYKHv+cOb3z/rBfZitt6XfPcfNUzawx
 xTph/zV5WifhR4mU2u5mSvAKbmG0PdKwG5Iypc3P/eK7dlmz5Q+sAetv1sISvgAAAABJRU5ErkJg
 gg==
}
image create photo logobuffer
proc update_logobuffer {subsamp} {
 logobuffer blank
 set w [image width tcl_logo]
 set h [image height tcl_logo]
 logobuffer copy tcl_logo -subsample $subsamp -to [expr { $w-($w/$subsamp)>>1 }]\
                                                  [expr { $h-($h/$subsamp)>>1 }]
}
update_logobuffer 1

set v_opts {-padx 4 -pady 4 -width 120 -height 300 -borderwidth 6}
set h_opts {-padx 4 -pady 4 -width 300 -height 120 -borderwidth 6}
frame .centre -width 180 -height 180 -pady 40
eval frame .topleft $v_opts -relief ridge
eval frame .bottomright $v_opts -relief sunken
eval frame .topright $h_opts -relief raised
eval frame .bottomleft $h_opts -relief groove

foreach i {.topleft .bottomright .topright .bottomleft .centre} {
 pack propagate $i 0
}


# ==========================
# ===== TOP LEFT FRAME =====
# ==========================

# top row: a button and a checkbutton
pack [frame .topleft.top] -fill x -side top -expand 0
pack [button .topleft.top.b -text Button -command {
 tk_messageBox -title "Message" -message "You need to learn Tcl/Tk.\n\nVisit https://tcl.tk to see what I mean."
}] -side left
pack [checkbutton .topleft.top.cb] -side right

# middle row: a listbox with scrollbars
pack [frame .topleft.listboxframe] -side top
pack [listbox .topleft.listboxframe.lb -listvariable listbox_demo_list -width 10 -xscrollcommand {.topleft.hframe.sb set} -yscrollcommand {.topleft.listboxframe.sb set}] -side left -fill both -expand 1
pack [scrollbar .topleft.listboxframe.sb -command {.topleft.listboxframe.lb yview}] -side right -fill y
pack [frame .topleft.hframe] -fill x
pack [scrollbar .topleft.hframe.sb -orient horiz -command {.topleft.listboxframe.lb xview}] -side left -fill x -expand 1
pack [frame .topleft.hframe.l -width 16 -height 8] -side right
set listbox_demo_list {listbox}
for {set i 1} {$i<=10} {incr i} {
 lappend listbox_demo_list "list item $i"
}
lappend listbox_demo_list This is a listbox. It's an amazing example of the power and utility of Tcl/Tk

# bottom row: a scale and a label with an image
pack [frame .topleft.bottom ] -fill both -expand 1
pack [scale .topleft.bottom.sc -from 1 -to 4 -variable myscale -showvalue 0 -command {update_logobuffer}] -fill y -side left
pack [label .topleft.bottom.l -image logobuffer] -fill both -expand 1


# ===========================
# ===== TOP RIGHT FRAME =====
# ===========================

pack [frame .topright.left] -side left -fill both
pack [frame .topright.right] -side right -fill both -expand 1
set freq 4
pack [scale .topright.left.sc -orient horiz -label Frequency -variable freq -showvalue 0 -from 2 -to 16 -resolution 0.01 -command update_sine] -fill both
pack [label .topright.left.lf] -fill x -expand 1
pack [label .topright.left.lf.l -text " DC offset" -justify left] -fill both -side left
pack [label .topright.left.lf.pad] -fill both  -side right
set dcoffset 0
pack [spinbox .topright.left.sb -textvariable dcoffset -from -100 -to 100 -command update_sine] -fill both -side top

pack [canvas .topright.right.c -background black] -fill both -expand 1

proc drawsine {w f o} {
 $w delete all
 set width [winfo width $w]
 set height [expr {[winfo height $w]>>1}]
 for {set x 0} {$x<$width} {incr x} {
  set X [expr {$x+1}]
  $w create line $x [expr {$height-sin($x*$f*( (22.0/7)/$width) )*$height*0.7-$o}]\
                 $X [expr {$height-sin($X*$f*( (22.0/7)/$width) )*$height*0.7-$o}]\
                 -fill white
 }
}

proc update_sine {args} {
 global freq dcoffset
 drawsine .topright.right.c $freq $dcoffset
}

# ==============================
# ===== BOTTOM RIGHT FRAME =====
# ==============================

pack [frame .bottomright.menubar -relief raised -borderwidth 1] -fill x
pack [menubutton .bottomright.menubar.file -text File] -side left
menu .bottomright.menubar.file.m
.bottomright.menubar.file.m add command -label "Load text file" -command {
 set f [tk_getOpenFile -filetypes {{Text {.txt}}} ]
 if {$f eq ""} return
 if [catch {set textfile [open $f r]}] {
  tk_messageBox -icon error -title "Error" -message "Couldn't open text file\n$f"
  return
 }
 if [catch {set newtext [read $textfile]}] {
  tk_messageBox -icon error -title "Error" -message "Couldn't read text file\n$f"
  return
 }
 .bottomright.text delete 0.0 end
 .bottomright.text insert 0.0 $newtext
 close $textfile
}
.bottomright.menubar.file.m add command -label "Save text file" -command {
 set f [tk_getSaveFile -filetypes {{Text {.txt}}} ]
 if {$f eq ""} return
 if [file exists $f] {
  tk_messageBox -message "File exists, to be safe let's not overwrite it."
  return
 }
 if [catch {set fileout [open $f w]}] {
  tk_messageBox -message "Something happened" -title "Something happened"
  return
 }
 set textout [.bottomright.text get 0.0 end]
 puts $fileout $textout
 close $fileout
}
.bottomright.menubar.file conf -menu .bottomright.menubar.file.m
pack [menubutton .bottomright.menubar.edit -text Edit] -side left
menu .bottomright.menubar.edit.m
.bottomright.menubar.edit.m add command -label "Cut" -command {
 tk_textCut .bottomright.text
}
.bottomright.menubar.edit.m add command -label "Copy" -command {
 tk_textCopy .bottomright.text
}
.bottomright.menubar.edit.m add command -label "Paste" -command {
 tk_textPaste .bottomright.text
}
.bottomright.menubar.edit conf -menu .bottomright.menubar.edit.m
pack [text .bottomright.text -yscrollcommand {.bottomright.sb set} -width 10] -fill y -side left
pack [scrollbar .bottomright.sb -command {.bottomright.text yview}] -fill y -side right

.bottomright.text insert 0.0 "Lorem ipsum dolor sit amet, sit ipsum quaeque eu, mutat qualisque dissentiet at mel. Debet placerat vel cu, ne vim stet mucius scriptorem, eu mazim placerat per. Eam id dictas delicata, ei brute solet recteque mel. Sit docendi suscipiantur et. Ei graece definitiones pro, nemore expetendis sed an.

Nihil mandamus persecuti ad mea, vel at scripta copiosae consequat, fabulas ornatus forensibus ne his. Illud hendrerit nec te, qui probo justo putant at, odio ignota eum eu. Mei sale scaevola ea, ex solum velit aliquid nam, in mel dicam sensibus. Ad sit conceptam democritum. Duo in quis dolorem, has cibo habeo congue no, ex suas legimus hendrerit has. Elitr decore eos eu. Prompta partiendo eu eos, tation deserunt pro te.

Ei putent pertinacia nec, dolore quaeque ut eos, lobortis delicata maluisset ei eam. His ea decore reprimique, mea noster audiam no. In sumo movet everti mel, ne iracundia voluptatum nec, graeci nominati in his. Eu vel molestie erroribus, ridens commune ne eum. Dolore singulis mel eu.

Ex cibo phaedrum mei. Vis esse aeque voluptaria te, ad mel timeam facilis singulis. Ad sint vivendo sit. Ea sint scaevola euripidis qui. Eum habemus menandri sententiae ea, an accusamus constituto mel. Intellegat interesset vituperatoribus vel et, no debet definitiones est. Te epicuri accumsan dissentiet vis, in aeque albucius concludaturque qui, ut qui quidam aperiri malorum.

Nominavi quaestio explicari eu usu. At cum summo accumsan incorrupte, magna vitae oblique est cu, no graece putant fabellas est. Viris numquam nam ea, eos id quis assum summo, mel suas exerci libris an. Duo quem iriure persecuti te. Quando ridens prodesset eu usu. Discere corrumpit ut has, id debet admodum senserit quo, veniam populo ius cu. Mei ex quas mucius."

# =============================
# ===== BOTTOM LEFT FRAME =====
# =============================

set rbw 96
set rbh 96
image create photo renderbuffer -width $rbw -height $rbh
#renderbuffer put red -to 0 0 $rbw $rbh

pack [frame .bottomleft.left] -side left
foreach i {r g b} j {
  {$x / double($w)*255}
  {$y / double($h)*255}
  {($w+$h)-($x+$y)}
 } {
 pack [frame .bottomleft.left.$i]
 pack [label .bottomleft.left.$i.l -text [string toupper $i]] -side left
 pack [entry .bottomleft.left.$i.e -textvariable fn_$i] -fill x -side left
 .bottomleft.left.$i.e insert 0 $j
}
pack [frame .bottomleft.left.control]
pack [button .bottomleft.left.control.b -text Render -command {
 if [catch render resultvar] {
  tk_messageBox -title "Error" -message "The render failed.\n\nInfo: $resultvar"
  $::renderControlButton conf -state normal
 } 
}] -side left
pack [ttk::progressbar .bottomleft.left.control.p -maximum 1.0] -side left -fill x
set renderControlButton .bottomleft.left.control.b
set renderProgressBar .bottomleft.left.control.p

pack [frame .bottomleft.right -relief sunken -borderwidth 1] -fill both -expand 1 -side right
pack [label .bottomleft.right.l -image renderbuffer] -fill both -expand 1

set wait_var 0
proc gui_update {progress} {
 global wait_var renderProgressBar
 $renderProgressBar conf -value $progress
 after 1 set wait_var 1
 tkwait variable wait_var
}

proc rgb {r g b} {
 set H "#"
 return $H[format %02x [expr {int($r)&0xff}]][format %02x [expr {int($g)&0xff}]][format %02x [expr {int($b)&0xff}]]
}

proc render {} {
 global renderControlButton renderProgressBar  fn_r fn_g fn_b
 upvar rbw w rbh h
 $renderControlButton conf -state disabled
 for {set x 0} {$x<$w} {incr x} {
  for {set y 0} {$y<$h} {incr y} {
   renderbuffer put [rgb [expr $fn_r] [expr $fn_g] [expr $fn_b]] -to $x $y
  }
  gui_update [expr {$x/double($w)}]
 }
 $renderControlButton conf -state normal
}


# ========================
# ===== CENTRE FRAME =====
# ========================


pack [label .centre.title1 -text "battleofthebits.org" -justify center -font {-size 9}] -fill both -expand 1
pack [label .centre.title2 -text "Tcl/Tk" -justify center -font {-size 40}] -fill both -expand 1
pack [label .centre.title3 -text "P R O G R A M M I N G" -justify center -font {-size 9}] -fill both -expand 1


# ===========================
# ===== WINDOW RESIZING =====
# ===========================

bind . <Configure> {
 set winw [winfo width .]; set winh [winfo height .];
 set wh [expr {$winw<$winh ? $winw : $winh}]
 set short [expr {int($wh/420.0*120)}]
 set long [expr {int($wh/420.0*300)}]
 set medium [expr {$wh-$short}]
 foreach i { .topleft .bottomright } {
  $i configure -width $short -height $long
 }
 foreach i { .topright .bottomleft } {
  $i configure -width $long -height $short
 }
 set cw [expr {$wh-$short*2}]
 .centre configure -width $cw -height $cw
 place .topleft -x 0 -y 0
 place .topright -x $short -y 0
 place .bottomleft -x 0 -y $medium
 place .bottomright -x $medium -y $short
 place .centre -x $short -y $short
 .topleft.listboxframe.lb conf -width [expr {[winfo width .topleft]/11}] -height [expr {[winfo height .topleft]/40}]
 .bottomright.text conf -width [expr {int(([winfo width .bottomright]-0)/120.0*10.75)}]
 update_sine
}

wm geometry . 420x420
wm aspect . 1 1 1 1
wm title . "Tcl/Tk"
