
# ---------------------------------------------------
# ---- ComputerCraft mod image conversion tool ------
# Generates images for 'ComputerCraft' minecraft mod.
# ---------------------------------------------------

# To use this software:
#  On Windows:
#   * Download a "Base TclKit" from here (you must use version 8.6 or later):
#   * http://tclkits.rkeene.org/fossil/wiki/Downloads
#   * Open the .tcl file with the TclKit exe.
#  On Linux: 
#   * Install Tcl/Tk (on debian/ubuntu run this command as root: "apt-get install tcl tk".
#   * Open the .tcl file with "tclsh" or "wish".
#  On MacOS:
#   Use "homebrew" to install Tcl/Tk because the preinstalled version is broken.
#   Then use the homebrew version of "wish" to open the .tcl file.

# README NOTE:
# If you get a "failed to load the image" error,
# make sure that you're using a TclKit or version of Tcl/Tk that supports loading png images.
# You need at least version "8.6".

package require Tk
tk appname "ComputerCraft Image Conversion Tool"
set cancel 0

# ---------------------------------------------------------------------------------------------
# Convert a named colour (eg 'magenta' or '#ff00ff') to a list of rgb values (eg '{255 0 255}')
# ---------------------------------------------------------------------------------------------

image create photo scratchpad
proc colname_to_collist {name} {
 scratchpad put $name -to 0 0
 return [scratchpad get 0 0]
}

# --------------------------------------------------------------------
# Create the array of colours represented by the minecraft wool blocks
# --------------------------------------------------------------------

set c 0
foreach i {
 "#F0F0F0"
 "#F2B233"
 "#E57FD8"
 "#99B2F2"
 "#DEDE6C"
 "#7FCC19"
 "#F2B2CC"
 "#4C4C4C"
 "#999999"
 "#4C99B2"
 "#B266E5"
 "#3366CC"
 "#7F664C"
 "#57A64E"
 "#CC4C4C"
 "#191919"
} {
 set v [colname_to_collist $i]
 set col_array($c) $v
 set col_array([format "%x" $c]) $v
 set col_array(_[format "%x" $c]) $i
 incr c
}

# ------------------------------------------------------------------------------------------
# Take a colour as taken from a 'photo' image ( a list of rgb values, such as {255 255 255})
# and convert it to a minecraft wool colour (a single hex digit between '0' and 'f')
# ------------------------------------------------------------------------------------------

proc convert_img_col {c} {
 global col_array
 set mindiff [expr 0xffffff]
 set p 0
 for {set i 0} {$i<16} {incr i} {
  set diff 0
  foreach a $col_array($i) b $c {
   set diff [expr {$diff+abs($a-$b)}]
  }
  if {$diff<$mindiff} {
   set p $i
   set mindiff $diff
  }
 }
 return [format "%x" $p]
}

# ----------------------------------------------------------------------
# Take a 'photo' image and output a converted ComputerCraft image string
# ----------------------------------------------------------------------

proc convert_image_to_minecraft {img} {
 global cancel
 set w [image width $img]
 set h [image height $img]
 set doProgress [expr {$w*$h>128*128}]
 if $doProgress {
  progress_start "Converting image"
 }
 set out ""
 for {set y 0} {$y<$h} {incr y} {
  for {set x 0} {$x<$w} {incr x} {
   append out [convert_img_col [$img get $x $y]]
  }
  if {$y<$h-1} { append out "\n" }
  if $doProgress {
   progress_update [expr {$y/double($h)}]
  }
  if $cancel {
   progress_finish
   return $out
  }
 }
 progress_finish
 return $out
}

# -----------------------------------------------------------
# Create and setup the various GUI controls for the interface
# -----------------------------------------------------------

# top frame for the main action buttons
pack [frame .f] -fill x 

# the text window for the converted image string
pack [text .t -width 0] -side left -fill both -expand 1
.t insert 0.0 "Converted image will appear here"

# the "load image" action button
pack [button .f.b1 -text "Load PNG" -command {
 set cancel 0
 set f [tk_getOpenFile]
 if {$f eq ""} {
  return
 }
 catch {image destroy tempimg}
 if [catch {image create photo tempimg -file $f}] {
  tk_messageBox -title "Something happened" -message "Failed to load the image"
 } else {
  .t delete 0.0 end
  .t insert 0.0 [convert_image_to_minecraft tempimg]
  if $cancel { return }
  .f.b4 invoke
  progress_finish
 }
}] -side left

# the "copy to clipboard" action button
pack [button .f.b2 -text "Copy to clipboard" -command {
 clipboard clear
 clipboard append [trimFinalNewline [.t get 0.0 end]]
}] -side left

# the "save" action button
pack [button .f.b3 -text "Save to file" -command {
 set f [tk_getSaveFile]
 if {$f eq ""} {
  return
 }
 if [catch {set fout [open $f w]}] {
  tk_messageBox -title "Something happened" -message "Failed to open file for writing"
 } else {
  puts -nonewline $fout [trimFinalNewline [.t get 0.0 end]]
  close $fout
 }
}] -side left

# the "update preview" action button
pack [button .f.b4 -text "Update preview" -command {
 set cancel 0
 if [catch {update_preview} myinfovar] {
  tk_messageBox -title "Preview render failed" -message $myinfovar
  progress_finish
  set cancel 0
 }
}] -side left

# the preview zoom setting option
pack [label .f.scl0 -text +]\
     [scale .f.sc -orient horiz -variable zoomsetting -showvalue 0 -from 0 -to 5]\
     [label .f.scl -text "Zoom -"] -side right
set zoomsetting 2
# for some reason on windows it looks like the scale gets triggered during initialisation,
# and its command gets run, unless we wait a brief moment before assigning the command to it.
# So I schedule the command to be assigned to the scale 176ms later.
after 176 { .f.sc conf -command update_preview }

# the frame that contains the preview image
pack [frame .previewframe] -side right
pack [ label .previewframe.l -text Preview ] -side top
pack [ label .previewframe.img ] -side bottom -fill y


# ------------------------
# update the preview image
# ------------------------

proc update_preview {args} {
 global col_array zoomsetting cancel
 if $cancel { return }
 catch {image delete previewimage}
 image create photo previewimage
 .previewframe.img conf -image previewimage
 set s [trimFinalNewline [.t get 0.0 end]]
 set l [string length $s]
 set doProgress [expr {$l>128*128}]
 if $doProgress {
  progress_start "Updating preview"
 }
 set x 0
 set y 0
 for {set i 0} {$i<$l} {incr i} {
  set c [string range $s $i $i]
  switch -- $c {
   "\n" {
    set x 0
    incr y 2
    if $doProgress {
     progress_update [expr {$i/double($l)}]
    }
   }
   default {
    if $cancel {
     progress_finish
     return
    }
    if {[info exists col_array(_$c)]} {
     previewimage put $col_array(_$c) -to [expr {$x<<$zoomsetting}] \
                                          [expr {$y<<$zoomsetting}] \
                                          [expr {($x+1)<<$zoomsetting}] \
                                          [expr {($y+2)<<$zoomsetting}]
    } else {
     if {![info exists warnBadData]} {
      set warnBadData ""
      tk_messageBox -title "Warning" -message "There is an invalid character, '$c', in the image string."
     }
    }
    incr x
   }
  }
 }
 if $doProgress {
  progress_finish
 }
}

# ---------------------------------------------------------------
# I don't know how to stop the text widget from putting a newline
# at the end of the output string when we 'get' the text from it, 
# so I have to do this to remove that manually
# ---------------------------------------------------------------

proc trimFinalNewline {s} {
 set l [string length $s]
 incr l -2
 return [string range $s 0 $l]
}

wm geometry . 640x400

# -----------------------------------------------------------------------------------------
# Progress indicator stuff that's used when working with images with more than 10000 pixels
# -----------------------------------------------------------------------------------------

proc make_progress_window {} {
 toplevel .progress
 wm title .progress "Please wait"
 pack [label .progress.l -text ""] -fill both -expand 1
 pack [ttk::progressbar .progress.pb]  -fill both
 pack [label .progress.p ] -side bottom -fill both -expand 1
 pack [button .progress.b -text "Give up" -command {set cancel 1}] -side bottom -fill y
 wm withdraw .progress
}

proc progress_start {description} {
 if {![winfo exists .progress]} {
  make_progress_window
 }
 .progress.l conf -text $description
 wm deiconify .progress
 raise .progress
}

proc progress_update {v} {
 if [catch {
  .progress.pb conf -value [expr {int($v*100)}]
 }] {
  progress_start "DBZ FOREVER!!! !!! !!!"
 }
 update
}

proc progress_finish {} {
 catch {
  wm withdraw .progress
 }
}

