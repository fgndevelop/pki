
#---------------------------------------------------------->
#
#  Shell Script Framework v1.0 library
#
#  sfw_std.sh
#
#  Standard functionality
#
#<----------------------------------------------------------

# Make sure a file is readable
# Usage: is_readable FILENAME
#
# Returns: 
# 0: file exists and is readable
# 1: file does not exist
# 2: file cannot be read

is_readable()
{
  # Argument check
  [ -z ${1+x} ] && debug "missing argument to function call: is_readable()"

  # Perform the checks, return error values
  [ -e "$1" ] || return 1
  [ -r "$1" ] || return 2
  return 0
}

# DEFINITELY: looking for contributors !
# MAYBE: create a directory if it does not exist
# MAYBE: create a file if it does not exist
# MAYBE: check whether a specific program is installed and executable
# MAYBE: check whether the program is being run with uid = root / sudo ?!?
