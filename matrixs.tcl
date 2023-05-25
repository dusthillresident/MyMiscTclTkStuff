# ---------------------------
# -- Matrix multiplication --
# ---------------------------
#
# AxB=C
# the width of A must be equal to the height of B.
# the dimensions of C are
#  W = the width of B
#  H = the height of A



proc matrixWidth { m } {
 return [llength [lindex $m 0] ]
}



proc matrixHeight { m } {
 return [llength $m]
}



proc matrixGet { m x y } {
 set w [matrixWidth $m]
 set h [matrixHeight $m]
 if {$x<0 || $x>$w || $y<0 || $y>$h} {
  error "matrixGet: out of bounds: x=$x y=$y w=$w h=$h"
 }
 return [lindex [lindex $m $y] $x]
}



proc matrixSet { mvar x y v } {
 upvar $mvar m
 set w [matrixWidth $m]
 set h [matrixHeight $m]
 if {$x<0 || $x>$w || $y<0 || $y>$h} {
  error "matrixGet: out of bounds: x=$x y=$y w=$w h=$h"
 }
 lset m $y $x $v
}



proc newMatrix { w h } {
 for {set x 0} {$x<$w} {incr x} {
  lappend row 0
 } 
 for {set y 0} {$y<$h} {incr y} {
  lappend out $row
 }
 return $out
}



proc dotProduct { a b } {
 if {[matrixWidth $a] != [matrixHeight $b]} {
  error "width of A must be equal to height of B"
 }
 set a_w [matrixWidth $a]
 set a_h [matrixHeight $a]
 set b_w [matrixWidth $b]
 set b_h [matrixHeight $b]
 set c_w $b_w
 set c_h $a_h
 set c   [newMatrix $c_w $c_h]

 for {set i 0} {$i<$a_h} {incr i} {
  for {set j 0} {$j<$b_w} {incr j} {

   set product 0

   for {set k 0} {$k<$a_w} {incr k} {

    set product [expr {[matrixGet $a $k $i] * [matrixGet $b $j $k] + $product}]
    
   }

   matrixSet c $j $i $product
   
  }
 }

 return $c
}



proc transpose { m } {
 set w [matrixWidth $m]
 set h [matrixHeight $m]
 set out [newMatrix $h $w]
 for {set x 0} {$x<$w} {incr x} {
  for {set y 0} {$y<$h} {incr y} {
   matrixSet out $y $x [matrixGet $m $x $y]
  }
 }
 return $out
}



proc printMatrix { m } {
 set w [matrixWidth $m]
 set h [matrixHeight $m]
 set out ""
 foreach j $m {
  set thisLine ""
  foreach i $j {
   append thisLine "	$i"
  }
  append out "$thisLine\n"
 }
 return $out
}



# -------------------------------------------------------------------------------
# -------------------------------------------------------------------------------
# -------------------------------------------------------------------------------

#puts [printMatrix [transpose {
# {1 9 0}
# {2 9 3}
#}]]
#exit

proc demonstrate {a b} {
 puts "------------------------------\n[printMatrix $a] x\n[printMatrix $b] =\n[printMatrix [dotProduct $a $b]]------------------------------"
}

if {$argc} {
 demonstrate [lindex $argv 0] [lindex $argv 1]
 exit
}

demonstrate {
 {1 9 0}
 {2 9 3}
} {
 {7 4 1}
 {4 3 3}
 {9 0 8}
}


demonstrate {
 {3 4}
 {7 2}
 {5 9}
} {
 {3 1 5}
 {6 9 7}
}



