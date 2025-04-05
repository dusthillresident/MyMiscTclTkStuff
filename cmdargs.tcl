
#set ::requiredNumberOfDirectParameters 0
#set ::minimumNumberOfDirectParameters 0

proc defineCmdArgument {argument expectsParameter } {
 set ::validCmdArgs($argument) $expectsParameter
}

proc cmdAlias {argument alias} {
 set ::argv [lmap arg $::argv {
  if {$arg eq $alias} {
   set argument
  } else {
   set arg
  }
 }]
}

proc cmdArgument {argument {default {}} } {
 defineCmdArgument $argument 1
 set index [lsearch -exact $::argv $argument]
 set result $default
 if {$index != -1} {
  set ::usedCmdArgs($argument) 1
  if {$index == [llength $::argv]-1} {
   puts stderr "command argument '$argument' expects a parameter"
   exit 1
  }
  set result [lindex $::argv $index+1]
  lset ::argv $index __CMD_ARG_USED__
  lset ::argv [incr index] __CMD_ARG_USED__
 }
 return $result
}

proc cmdArgumentIsUsed {argument} {
 if { [info exists ::usedCmdArgs($argument)] } {return 1}
 set index [lsearch -exact $::argv $argument]
 defineCmdArgument $argument 0
 if { $index != -1 } {
  set ::usedCmdArgs($argument) 1
  lset ::argv $index __CMD_ARG_USED__
  return 1
 }
 return 0
}

proc cmdArgumentsAreUsed {args} {
 set result 0
 foreach i $args {
  if { [cmdArgumentIsUsed $i] } {set result 1}
 }
 return $result
}

proc !cmdArgumentIsUsed {argument} {
 expr {! [cmdArgumentIsUsed $argument] }
}

proc !cmdArgumentsAreUsed {args} {
 expr {! [cmdArgumentsAreUsed {*}$args] }
}

proc checkCmdArgs {} {
 foreach argument $::argv {
  if { $argument ne "__CMD_ARG_USED__" } {
   puts "Unknown argument '$argument'"
   #if { ! [info exists ::validCmdArgs] } return
   catch {
    set msg "Valid arguments are:\n"
    foreach validArg [array names ::validCmdArgs] {
     append msg "	$validArg		[lindex { {} {(requires parameter)} } $::validCmdArgs($validArg)]\n"
    }
    puts -nonewline $msg
   }
   exit 1
  }
 }
}

if 0 {
 cmdArgument -penismagic 2
 cmdArgumentIsUsed -smashin
 checkCmdArgs
}