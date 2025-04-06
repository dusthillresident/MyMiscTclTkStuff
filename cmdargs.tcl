
# Command line argument parsing and value retrieval


proc defineCmdArg { argument expectsParameter {defaultValue {}} {validTypes {}} {description {}} {aliases {}} } {
 if { [info exists ::__cmdArgsData($argument)] } {return}
 set ::__cmdArgsData($argument) 1
 lappend ::__cmdArgsData(__VALID_ARGS__) $argument
 foreach var { expectsParameter defaultValue validTypes description aliases} {
  set ::__cmdArgsData($argument.$var) [set $var]
 }
 set ::__cmdArgsData($argument.value) $defaultValue
 set ::__cmdArgsData($argument.isUsed) 0
 
 if {$expectsParameter} {cmdArg $argument} else {cmdArgIsUsed $argument}
}

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

proc _cmdArgListValidTypes {argument} {
 if { $::__cmdArgsData($argument.validTypes) ne {} } {
  puts stderr "valid type(s) for its parameter: [join $::__cmdArgsData($argument.validTypes) {, }]"
 }
}

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

# Get the specified parameter for command-line arguments that expect a parameter.
proc cmdArg { argument {default {}} } {
 defineCmdArg $argument 1
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
  return $::__cmdArgsData($argument.value)
 } else {
  return $default
 }
}

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

proc cmdArgsAreUsed {args} {
 set result 0
 foreach i $args {
  if { [cmdArgIsUsed $i] } {set result 1}
 }
 return $result
}

proc !cmdArgIsUsed {argument} {
 expr {! [cmdArgIsUsed $argument] }
}

proc !cmdArgsAreUsed {args} {
 expr {! [cmdArgsAreUsed {*}$args] }
}

proc cmdArgsUsageMessage {} {
 puts stderr "Valid command-line arguments:"
 foreach arg $::__cmdArgsData(__VALID_ARGS__) {
  puts stderr " $arg"
  if { $::__cmdArgsData($arg.aliases) ne {} } {
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

proc cmdArgsHelp {} {
 cmdArgsUsageMessage
 exit 1
}

proc checkCmdArgs {} {
 if { ![info exists ::__cmdArgsData(DISABLE_HELP)] && [lsearch -exact $::argv "--help"] != -1 } {
  cmdArgsHelp
  return
 }
 foreach argument $::argv {
  if { $argument ne "__CMD_ARG_USED__" } {
   puts stderr "Unknown argument '$argument'"
   cmdArgsUsageMessage
   exit 1
  }
 }
}





if 0 {
 
 if 1 {
  puts "\nLet's define the command line options:"
  defineCmdArg  -testarg  1  1234   {integer double}  {This is a test.}
  defineCmdArg  -blah     0  {}     {}                {This does nothing.}
  defineCmdArg  -dub	 1  {-1.0} double            {This is something.}	
  defineCmdArg	-nuts	0   {}      {}		     "Here's something."
  puts "OK"
 }
 puts "\nLet's set some option aliases"
 cmdArgAlias -testarg -ta
 cmdArgAlias -dub -db
 puts "OK"

 proc checkvalues {} {
 uplevel 1 {
 puts "\nLet's check the values:"
 foreach i { -testarg -dub } {
  puts " value of $i		[cmdArg $i]"
 }
 puts "And let's check if -nuts is used: [cmdArgIsUsed -nuts]"
 }
 }
 checkvalues 

 puts "\nLet's check if the command line options are valid using 'checkCmdArgs'"
 checkCmdArgs
 puts {
  ____                 _ _ _ _ 
 / ___| ___   ___   __| | | | |
| |  _ / _ \ / _ \ / _` | | | |
| |_| | (_) | (_) | (_| |_|_|_|
 \____|\___/ \___/ \__,_(_|_|_)}

 puts -nonewline "\nAgain, "
 checkvalues

 puts "\nLet's display the usage message."
 cmdArgsUsageMessage
}