
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

# ----------------------------------------------------------------------------
# CONFIGURATION - edit these values to customise some details for your own use
# ----------------------------------------------------------------------------

# Do you want square pixels in the conversion preview by default?
# 0 : No
# 1 : Yes
set  config_previewSquarePixelsByDefault  0

# Character to use for transparent parts of input images.
# Only the first character of this string is used.
# You should only set it to one of these characters: "0123456789abcdef" unless you have a very specific reason to do otherwise.
# If you set this to " " (space), the image preview will render that as a transparent pixel.
# ComputerCraft monitors/paintutils don't support transparent images; this option is just here in case it's useful for people writing their own scripts or utilities which need support for transparency.
set  config_transparentCharacter          "f"

# Default zoom level, an integer from 0 (not zoomed) to 5 (max zoom)
set  config_defaultZoomLevel              2

# --------------------------
# Process and sanitise config parameters
# --------------------------

# square pixels option
if {[string is bool -strict $config_previewSquarePixelsByDefault]} {
 set config_previewSquarePixelsByDefault [expr !!$config_previewSquarePixelsByDefault]
} else {
 puts "Warning: config option 'config_previewSquarePixelsByDefault' is invalid"
 set config_previewSquarePixelsByDefault 0
}
set sqrPix $config_previewSquarePixelsByDefault

# transparent character option
set config_transparentCharacter [string range $config_transparentCharacter 0 0]
if {[string length $config_transparentCharacter]==0} {
 puts "Warning: config option 'config_transparentCharacter' is invalid"
 set config_transparentCharacter "f"
}

# zoom setting option
if {$config_defaultZoomLevel<0 || $config_defaultZoomLevel>5} {
 puts "Warning: config option 'config_defaultZoomLevel' is invalid"
 set config_defaultZoomLevel 1
}
set zoomsetting $config_defaultZoomLevel

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
 if {$c eq {255 0 255}} {
  return " "
 }
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
 global cancel config_transparentCharacter
 set w [image width $img]
 set h [image height $img]
 set doProgress [expr {$w*$h>128*128}]
 if $doProgress {
  progress_start "Converting image"
 }
 set out ""
 for {set y 0} {$y<$h} {incr y} {
  for {set x 0} {$x<$w} {incr x} {
   if [$img transparency get $x $y] {
    append out $config_transparentCharacter
   } else {
    append out [convert_img_col [$img get $x $y]]
   }
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


# -------------------------------------------------------------
# load_image - Load and convert an image and update the preview
# -------------------------------------------------------------

proc load_image {f} {
 global cancel
 set cancel 0
 if {$f eq ""} {
  return
 }
 catch {image destroy tempimg}
 if [catch {image create photo tempimg -file $f}] {
  tk_messageBox -title "Something happened" -message "Failed to load the image"
 } else {
  textwindow delete 0.0 end
  textwindow insert 0.0 [convert_image_to_minecraft tempimg]
  if $cancel { return }
  .f.b4 invoke
  progress_finish
 }
}

# -----------------------------------------------------------
# Create and setup the various GUI controls for the interface
# -----------------------------------------------------------

# top frame for the main action buttons
pack [frame .f] -fill x 

# the text window for the converted image string
set textWindowPath .textWindowFrame.t
pack [ frame .textWindowFrame ] -side left -fill both -expand 1
#-exportselection 1
grid [ text $textWindowPath -width 0 -height 0 -wrap none -xscrollcommand {.textWindowFrame.sb2 set} -yscrollcommand {.textWindowFrame.sb1 set} ] \
     [ scrollbar .textWindowFrame.sb1 -command "$textWindowPath yview" ]
grid [ scrollbar .textWindowFrame.sb2 -orient horiz -command "$textWindowPath xview" ]
grid configure .textWindowFrame.sb2 -sticky ew
grid configure .textWindowFrame.sb1 -sticky ns
grid configure $textWindowPath -sticky nsew
grid columnconfigure .textWindowFrame 0 -weight 1
grid rowconfigure .textWindowFrame 0 -weight 1
# convenient way to access the text widget
proc textwindow {args} {
 global textWindowPath
 return [eval $textWindowPath $args]
}
textwindow insert 0.0 "0123\n4567\n89ab\ncdef"
if {[tk windowingsystem] eq "x11"} {
 foreach i {<Control-a> <Control-A>} {
  bind . $i {
   textwindow tag add sel 0.0 end
  }
 }
}

# the "load image" action button
pack [button .f.b1 -text "Load PNG" -command {
 load_image [tk_getOpenFile]
}] -side left

# the "copy to clipboard" action button
pack [button .f.b2 -text "Copy" -command {
 clipboard clear
 clipboard append [trimFinalNewline [textwindow get 0.0 end]]
}] -side left

# the "save" action button
pack [button .f.b3 -text "Save" -command {
 set f [tk_getSaveFile]
 if {$f eq ""} {
  return
 }
 if [catch {set fout [open $f w]}] {
  tk_messageBox -title "Something happened" -message "Failed to open file for writing"
 } else {
  puts -nonewline $fout [trimFinalNewline [textwindow get 0.0 end]]
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

#set sqrPix 0
pack [checkbutton .f.cb -text "Square pixels" -variable sqrPix -command update_preview] -side left

# the preview zoom setting option
pack [label .f.scl0 -text +]\
     [scale .f.sc -orient horiz -variable zoomsetting -showvalue 0 -from 0 -to 5]\
     [label .f.scl -text "Zoom -"] -side right
#set zoomsetting 2
.f.sc conf -command update_preview

# the frame that contains the preview image
pack [frame .previewframe] -side right
pack [ label .previewframe.l -text "Preview" ] -side top -fill y -expand 1
pack [ label .previewframe.img ] -side bottom -fill y


# ------------------------
# update the preview image
# ------------------------

proc update_preview {args} {
 global col_array zoomsetting cancel sqrPix
 if $cancel { return }
 catch {image delete previewimage}
 image create photo previewimage
 .previewframe.img conf -image previewimage
 set s [trimFinalNewline [textwindow get 0.0 end]]
 set l [string length $s]
 set doProgress [expr {$l>128*128}]
 if $doProgress {
  progress_start "Updating preview"
 }
 set x 0
 set y 0
 set odd_frame 0
 for {set i 0} {$i<$l} {incr i} {
  set c [string range $s $i $i]
  switch -- $c {
   " " {
    incr x
   }
   "\n" {
    set x 0
    # The ComputerCraft monitors' pixels appear to be roughly 1.5x as tall as they are wide.
    # To make the preview approximately match that, double every other pixel.
    incr y [expr {1+($odd_frame&1&!$sqrPix)}]
    set odd_frame [expr {!$odd_frame}]
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
                                          [expr {($y+2-$sqrPix)<<$zoomsetting}]
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

# ---------------------
# Drag and drop support
# ---------------------

if {![catch {package require tkdnd}]} {
 tkdnd::drop_target register .textWindowFrame DND_Files
 bind .textWindowFrame <<Drop:DND_Files>> {
  load_image [lindex %D 0]
 }
}

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

# --------------------
# final initialisation
# --------------------

wm geometry . 640x400
update_preview

