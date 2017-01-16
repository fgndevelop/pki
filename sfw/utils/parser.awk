# Shell Script Framework v1.0
#
# Parse a file for variables using awk, which allows this parser to act as a pipe.
# Variables in the source are denoted by $sep (which defaults to "@", e.g. "@VARIABLE@")
# and are substituted with the value of the corresponding environment variable VARIABLE.
#
# Unset variables
# If "silent" is set to 0 (which is the default), unset variables will be reported as an
# error. When "silent" is set to 1 (as in "awk -v silent=1" ...), unset variables will 
# silently be ignored.
#
# Empty variables
# Empty variables will be empty in the resulting output, too.

BEGIN {

  # Assign the default seperator if it has not been set on the command line...
  if (!sep) sep="@"

  # ... If it comes from the command line, make sure it is just a single char 
  else if (length(sep)!=1) { 
    print "parser: Seperator has to be a single character: <" sep ">"  > "/dev/stderr"
    exit 1
  }
  
  # Assign the default value to silent
  if (!silent) silent=0

  # Set the regular expression to find variable expressions in the source
  var_match = sep "[^ " sep "]*" sep

}

# Select only those lines containing variable expressions 
match ($0,var_match) {

  # Initialize the search string to the whole line
  search_string=$0

  # This loop runs at least once for our first match and will then
  # continue to run as long as we find more matches on this line 
  do {

    # get the variable expression without the seperators
    found=substr(search_string,RSTART+1,RLENGTH-2)

    # if this variable is available, substitute it ...
    if (found in ENVIRON)
      sub(var_match,ENVIRON[found])

    # ... otherwise bail out with error or continue, depending on "silent"
    else {
      if (silent==0) {
        print "parser: Variable <"found "> unset, cannot substitute." > "/dev/stderr" 
	exit 1
      }
    } 
 
    # adjust the search string
    search_string=substr(search_string,RSTART+RLENGTH)
  
  } while (match (search_string,var_match))
}

# Finally, print each line 
{ print }
