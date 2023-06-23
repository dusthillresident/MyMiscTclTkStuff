#!/usr/bin/tclsh

# A random solution finder for New York Times "digits" puzzles
# usage: digits.tcl target_number n1 n2 n3 n4 n5 n6

proc digits {target numbersGiven} {
 if {![string is integer -strict $target]} {
  error "invalid 'target'"
 }
 if {[llength $numbersGiven] != 6} {
  error "not enough numbers given"
 }
 foreach i $numbersGiven {
  if {![string is integer -strict $i]} {
   error "invalid input '$i'"
  }
 }
 set resultValue -1
 while {$resultValue != $target} {
  set numbers $numbersGiven
  while {[llength $numbers] > 1 } {
   set ia [expr {int(rand()*[llength $numbers])}]
   set ib [expr {int(rand()*[llength $numbers])}]
   if {$ia==$ib} {
    set ib [expr ($ib+1)%[llength $numbers]]
   }
   lassign [lindex $numbers $ia] a A
   lassign [lindex $numbers $ib] b B
   lset numbers $ia "x"
   lset numbers $ib "x"
   set numbers [string map {x ""} $numbers]
   set notDivisable [expr {$b==0 ? 1 : !!($a%$b)}]
   set operation [lindex [lindex {{+ - * /} {+ - *}} $notDivisable] [expr {int(rand()*(4-$notDivisable))}]]
   if {($operation eq "-" && $a<$b) || ($operation eq "+" && $a>$b)} {
    lassign "$a $b" b a
   }
   set resultValue [expr $a $operation $b]
   set result [list $resultValue "$A$B$a$operation$b;"]
   lappend numbers $result
   if {$resultValue == $target} break
  }
 }
 return [string map {";" "\n"} [lindex $result 1]]
}


proc verify {target numbersGiven solution} {
 set solution "$numbersGiven\n$solution"
 while {[llength $solution] > 1} {
  foreach i $solution {
   if {![string is integer $i]} break
  }
  if {[string is integer $i]} {
   puts "\$i = '$i'"
   error "no operation found"
  }
  set index [lsearch $solution $i]
  lassign [split $i "+-/*"] a b
  foreach j "$a $b" {
   if {[lsearch $solution $j]==-1} {
    error "'$j' used in this expression '$i' was not found"
   }
  }
  foreach j "$a $b" {
   set removeIndex [lsearch $solution $j]
   lset solution $removeIndex x
  }
  set result [expr $i]
  lset solution $index $result
  set solution [string map {x ""} $solution]
  if {$result==$target} break
 }
 if {$result != $target} {
  error "solution result '$solution' doesn't equal target '$target'"
 }
 return "Result = $result" 
}


set solutionOutput [ digits [lindex $argv 0] [lrange $argv 1 end] ]
puts $solutionOutput
puts [verify [lindex $argv 0] [lrange $argv 1 end] $solutionOutput]
