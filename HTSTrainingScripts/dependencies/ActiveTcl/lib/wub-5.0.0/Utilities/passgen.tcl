# password generator
# generate a password according to the passgen_rules array
#
# Source: http://mini.net/tcl/Password%20Generator
# Author: Mark Oakden http:/wiki.tcl.tk/MNO
# Version: 1.0

# no sanity checks on the supplied rules are done.

package provide passgen 1.0

set ::API(Utilities/passgen) {
    {
	password generator - generate a password according to the passgen_rules array

	Author: Mark Oakden http:/wiki.tcl.tk/MNO
    }
}

namespace eval ::passgen {
    # datasets for password generation:-
    # separate lowercase and UPPERCASE letters so we can demand minimum
    # number of each separately.
    variable passgen {
	letters "abcdefghijklmnopqrstuvwxyz"
	LETTERS "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	numbers "0123456789"
	punctuation "$%&*+=@#?"
    }

    # a complex set might be, for example:
    # variable passgen {
    #	letters "abcdefghijklmnopqrstuvwxyz"
    #	LETTERS "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    #	numbers "0123456789"
    #	punctuation "!\"\x{00A3}$%^&*()_+-={};':@#~<>,.?/\\|"
    #	}

    # a simpler set might be, for example:-
    # variable passgen {
    #	letters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    #	numbers "0123456789"
    #	punctuation "!\"\x{00A3}$%^&*()_+-={};':@#~<>,.?/\\|"
    # }

    # the rules determine characteristics of the randomly generated passwords
    # presently available are:-
    # passgen_rules(len) password length
    # passgen_rules(<dataset_name>,min) minimum number of characters from <dataset_name>
    # entry on the passgen array
    
    # example rules:-
    # password 7 chars long, with at least one U/C char, one l/c char,
    # one number and one punctuation.
    variable passgen_rules {
	len 7
	letters,min 1
	LETTERS,min 1
	numbers,min 1
	punctuation,min 1
    }

    # example rules appropriate to the commented "simpler" datasets above:-
    #
    # set passgen_rules(len) 7
    # set passgen_rules(numbers,min) 1
    # set passgen_rules(punctuation,min) 1

    # picks a (pseudo)random char from str
    proc OneCharFrom {str} {
	set len [string length $str]
	set indx [expr int(rand()*$len)]
	return [string index $str $indx]
    }

    # given a string, and integers i and j, swap the ith and jth chars of str
    # return the result
    proc Swap { str i j } {
	if { $i == $j } {
	    return $str
	}
	if { $i > $j } {
	    set t $j
	    set j $i
	    set i $t
	}
	set pre [string range $str 0 [expr $i - 1]]
	set chari [string index $str $i]
	set mid [string range $str [expr $i + 1] [expr $j - 1]]
	set charj [string index $str $j]
	set end [string range $str [expr $j + 1] end]
	
	set ret ${pre}${charj}${mid}${chari}${end}
	return $ret
    }

    # for a string of length n,  swap random pairs of chars n times
    # and return the result
    proc Shuffle {str} {
	set len [string length $str]
	for { set i 1 } { $i <= $len } { incr i 1 } {
	    set indx1 [expr int(rand()*$len)]
	    set indx2 [expr int(rand()*$len)]
	    set str [Swap $str $indx1 $indx2]
	}
	return $str
    }
    
    # generate a password
    proc Generate {args} {
	if {[llength $args] == 1} {
	    set args [lindex $args 0]
	}

	variable passgen
	variable passgen_rules

	# make local modified copy of passgen
	array set pg $passgen
	array set pg $args

	# remove contamination from rules
	array unset pg *,min
	array unset pg len
	array unset pg saltstr

	# set salt for later
	set pg(saltstr) "$pg(LETTERS)$pg(letters)$pg(numbers)"
	set passgen [array get pg]

	# make local modified copy of passgen_rules
	array set rules $passgen_rules
	array set rules $args

	# Algorithm
	# 1. foreach dataset with a min parameter, choose exactly min
	#    random chars from it
	# 2. concatenate results of above into password
	# 3. concatenate all datasets into large dataset
	# 4. choose desired_length-password_length chars from large
	# 5. concatenate (4) and (2)
	# 6. shuffle (5)
	
	set password {}
	foreach indx [array names rules *,min] {
	    set ds_name [lindex [split $indx ,] 0]
	    set num $rules($indx)
	    for {set i 1} {$i <= $num} {incr i 1} {
		append password [OneCharFrom $pg($ds_name)]
	    }
	}
	
	set all_data {}
	foreach set [array names pg] {
	    append all_data $pg($set)
	}
	
	set rem_len [expr $rules(len) - [string length $password]]
	for {set i 1} {$i <= $rem_len} {incr i 1} {
	    append password [OneCharFrom $all_data]
	}
	
	return [Shuffle $password]
    }
    
    proc Salt {} {
	variable passgen
	set slen [string len $passgen(saltstr)]
	return "[string index $passgen(saltstr) [expr round(rand() * $slen)]][string index $passgen(saltstr) [expr round(rand() * $slen)]]"
    }

    namespace export -clear *
    namespace ensemble create -subcommands {}
}
