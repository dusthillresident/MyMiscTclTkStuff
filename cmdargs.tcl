
# Command line argument parsing and value retrieval

# Define a command line argument
proc defineCmdArg { argument expectsParameter {defaultValue {}} {validTypes {}} {description {}} {aliases {}} } {
 if { [info exists ::__cmdArgsData($argument)] } {return}
 set ::__cmdArgsData($argument) 1
 lappend ::__cmdArgsData(__VALID_ARGS__) $argument
 foreach var { expectsParameter defaultValue validTypes description} {
  set ::__cmdArgsData($argument.$var) [set $var]
 }
 set ::__cmdArgsData($argument.value) $defaultValue
 set ::__cmdArgsData($argument.isUsed) 0
 if { [info exists ::__cmdArgsData($argument.aliases)] } {
  set aliases [concat $aliases $::__cmdArgsData($argument.aliases)]
 }
 set ::__cmdArgsData($argument.aliases) $aliases
 foreach alias $aliases {cmdArgAlias $argument $alias}
 
 if {$expectsParameter} {cmdArg $argument} else {cmdArgIsUsed $argument}
}

# make aliases for existing arguments
proc cmdArgAlias {argument alias} {
 lappend ::__cmdArgsData($argument.aliases) $alias
 set ::argv [lmap arg $::argv {
  if {$arg eq $alias} {
   set argument
  } else {
   set arg
  }
 }]
}

# internal helper function: list the valid parameter types for a given argument
proc _cmdArgListValidTypes {argument} {
 if { $::__cmdArgsData($argument.validTypes) ne {} } {
  puts stderr "valid type(s) for its parameter: [join $::__cmdArgsData($argument.validTypes) {, }]"
 }
}

# internal helper function: complain if the parameter value passed to a given argument is not an accepted type
proc _cmdArgValidateType {argument value} {
 if { $::__cmdArgsData($argument.validTypes) eq {} } {return 1}
 set accepted 0
 foreach type $::__cmdArgsData($argument.validTypes) {
  incr accepted [string is $type -strict $value]
 }
 if { ! $accepted } {
  puts stderr "value passed to argument '$argument' was not a suitable type"; _cmdArgListValidTypes $argument
  exit 1
 }
}

# internal helper function: this is used to get the value passed to an argument, and then consume (erase from $::argv) the argument and the parameter
proc _cmdArgGetValue {index} {
 upvar argument argument
 set index2 $index; incr index2
 if { $index2 >= [llength $::argv] } {
  puts stderr "command argument '$argument' expects a parameter"; _cmdArgListValidTypes $argument
  exit 1
 }
 set value [lindex $::argv $index2]
 lset ::argv $index  __CMD_ARG_USED__
 lset ::argv $index2 __CMD_ARG_USED__
 _cmdArgValidateType $argument $value
 if { $::__cmdArgsData($argument.validTypes) eq {double} } {
  set value [expr {double($value)}]
 }
 return $value
}

# get the specified parameter for command-line arguments that expect a parameter.
# if the argument has not been defined previously, if is defined as an argument that takes a parameter
proc cmdArg { argument {default {}} } {
 defineCmdArg $argument 1 $default
 if { ! $::__cmdArgsData($argument.expectsParameter) } {
  error "cmdArg called for argument '$argument' which is defined as not accepting a parameter"
 }
 if { $::__cmdArgsData($argument.isUsed) } {
  return $::__cmdArgsData($argument.value)
 }
 set index [lsearch -exact $::argv $argument]
 if { $index != -1 } {
  set ::__cmdArgsData($argument.isUsed) 1
  set ::__cmdArgsData($argument.value) [_cmdArgGetValue $index]
 } else {
  if { $default ne {} && $default ne $::__cmdArgsData($argument.value) } {
   return $default
  }
 }
 return $::__cmdArgsData($argument.value)
}

# tells you whether or not a given argument has been used/specified.
# if the argument has not been defined previously, if is defined as an argument that doesn't take a parameter
proc cmdArgIsUsed {argument} {
 defineCmdArg $argument 0
 if { $::__cmdArgsData($argument.isUsed) } {return 1}
 set index [lsearch -exact $::argv $argument]
 if { $index != -1 } {
  lset ::argv $index __CMD_ARG_USED__
  set ::__cmdArgsData($argument.isUsed) 1
  return 1
 }
 return 0
}

# tells you whether or not any one from a list of arguments have been used/specified
proc cmdArgsAreUsed {args} {
 set result 0
 foreach i $args {
  if { [cmdArgIsUsed $i] } {set result 1}
 }
 return $result
}

# tells you whether or not the a given argument has NOT been used/specified
proc !cmdArgIsUsed {argument} {
 expr {! [cmdArgIsUsed $argument] }
}

# tells you if all of the arguments in the list have NOT been used/specified
proc !cmdArgsAreUsed {args} {
 expr {! [cmdArgsAreUsed {*}$args] }
}

# internal helper function: remove duplicates from a list
proc _removeDupes {lst} {
 foreach i $lst {
  set dupes($i) 1
 }
 return [array names dupes]
}

# print the usage message listing the recognised command-line arguments and the information about them
proc cmdArgsUsageMessage {} {
 puts stderr "Valid command-line arguments:"
 foreach arg [lsort $::__cmdArgsData(__VALID_ARGS__)] {
  puts stderr " $arg"
  if { $::__cmdArgsData($arg.aliases) ne {} } {
   set ::__cmdArgsData($arg.aliases) [_removeDupes $::__cmdArgsData($arg.aliases)]
   puts stderr "    Also known by alias:\n      [join $::__cmdArgsData($arg.aliases) {, }]"
  }
  if { $::__cmdArgsData($arg.expectsParameter) } {
   puts -nonewline stderr "    Expects a parameter."
   if { $::__cmdArgsData($arg.validTypes) ne {} } {
    puts stderr " Valid parameter types:"
    puts stderr "      [join $::__cmdArgsData($arg.validTypes) {, }]"
   } else {
    puts stderr ""
   }
   if { $::__cmdArgsData($arg.defaultValue) ne {} } {
    puts stderr "    Default value:"
    puts stderr "      $::__cmdArgsData($arg.defaultValue)"
   }
  }
  if { $::__cmdArgsData($arg.description) ne {} } {
   puts stderr "    Description:"
   puts stderr "      $::__cmdArgsData($arg.description)"
  }
 }
}

# this can be redefined as necessary to customise the behaviour of --help
proc cmdArgsHelp {} {
 cmdArgsUsageMessage
 exit 1
}

# this lets you specify how many direct command line parameters you want to allow
# NOT WORKING YET
proc defineDirectCmdArgs { minimumArgs {maximumArgs {}} {descriptionList {}} } {
 if {$maximumArgs eq {}} {set maximumArgs $minimumArgs}
 if {$maximumArgs != -1 && $minimumArgs > $maximumArgs} {error "minimum number of direct command-line parameters can't be greater than the maximum"}
 set ::__cmdArgsData(__DIRECT_PARAMS__) [list $minimumArgs $maximumArgs $descriptionList]
}

# check if any unrecognised arguments have been passed and complain if so
proc checkCmdArgs {} {
 if { ![info exists ::__cmdArgsData(DISABLE_HELP)] && [lsearch -exact $::argv "--help"] != -1 } {
  cmdArgsHelp
  return
 }
 # handle direct params
 if { [info exists ::__cmdArgsData(__DIRECT_PARAMS__)] } {
  lassign $::__cmdArgsData(__DIRECT_PARAMS__) minArgs maxArgs desc
  set ::argv [lmap i $::argv { 
   if {$i eq "__CMD_ARG_USED__"} {continue} else {set i}
  }]
  if { [llength $::argv] < $minArgs } {
   puts stderr "Not enough command-line parameters\nUsage:"
   puts -nonewline stderr "$::argv0"
   set n 1
   for {set n 0} {$n < $minArgs} {incr n} {
    puts -nonewline stderr " ($n: $i)"
    incr n
# WORKING HERE RIGHT NOW
   }
  }
 }
 # check for unknown arguments
 foreach argument $::argv {
  if { $argument ne "__CMD_ARG_USED__" } {
   puts -nonewline stderr "Unknown argument '$argument'"
   if { [info exists ::__cmdArgsData(__DIRECT_PARAMS__)] } {
    " or possibly too many command-line parameters"
   } else {puts stderr ""}
   cmdArgsUsageMessage
   exit 1
  }
 }
}
