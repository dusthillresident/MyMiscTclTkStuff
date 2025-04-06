source "cmdargs.tcl"

if 1 {
 cmdArgAlias -testarg -PENIS
 if 1 {
  puts "\nLet's define the command line options:"
  defineCmdArg  -testarg  1  1234   {integer double}  {This is a test.}  {-testes -magic}
  defineCmdArg  -blah     0  {}     {}                {This does nothing.}
  defineCmdArg  -dub	 1  {-1.0} double            {This is something.}	-dubble
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
    puts " value of $i		[cmdArg $i someGarbageDefaultValue]"
    puts "(test2 [cmdArg $i])"
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