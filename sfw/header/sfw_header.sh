#!@SCRIPT_INTERPRETER@
#------------------------------------------------------>
#
# Name:	 	@SCRIPT_NAME@
# Created:  	@SCRIPT_MTIME@ 
# Man Page:     @MAN_TITLE_LOWER@(@MAN_SECTION@)
#
# Description:  @SCRIPT_SHORT_DESCRIPTION@	
# 
# Powered by:	Shell Script Framework v1.0 
#
#<------------------------------------------------------
#
# Global variables used by the Shell Script Framework and it's functions.
# In order to minimize namespace conflicts, variables as well as framework-internal
# functions are prefixed with "_sfw_". This accounts for function's local variables,
# too as they inherit variables local to the caller which is another possible source
# of namespace conflicts. "_sfw_"-variables are not meant to be referenced directly
# from the main script.
#
# Variables are mostly initialized by sfw_init or the Makefile
#

# Generic script information
_sfw_script_name="@SCRIPT_NAME@"						
_sfw_script_version="@SCRIPT_VERSION@"				
_sfw_synopsis="@SCRIPT_SYNOPSIS@"				
_sfw_man_section="@MAN_SECTION@"
_sfw_man_title="@MAN_TITLE_LOWER@"

# Copyright and license information, appended to the version information
_sfw_copyright="@COPYRIGHT@"
_sfw_license="@LICENSE@"
_sfw_copying="@COPYING@"
_sfw_warranty="@WARRANTY@"

# Variables used for command line argument handling
_sfw_cmd_list="@SCRIPT_CMD_LIST@"			# The script's cmdlist
_sfw_min_args=@SCRIPT_MIN_ARGS@				# required number of arguments to the script
_sfw_cmdline_arg_list=""				# Command line arguments, will be set at the end of header

# User-defined cleanup hook that will be called on exit
_sfw_user_exit_hook=""

# Global variables for the user (i.e. script programmer)
argc=$#							# Number of cmdline arguments

# This is the generic sfw clean up function wich cleans up sfw changes
# to the environment. This is not necessary when the script is executed
# in a subshell, but a script might get sourced using ".", too.
# If set, a user defined cleanup hook will be called, too.
#
# For more information regarding traps and signal propagation in shell scripts,
# see this not exhaustive list: 
# http://www.cons.org/cracauer/sigint.html
# http://www.vidarholen.net/contents/blog/?p=34

# https://www.gnu.org/software/autoconf/manual/autoconf-2.69/html_node/Signal-Handling.html
# http://docstore.mik.ua/orelly/unix/ksh/ch08_04.htm

# Clean up sfw changes to the environment
_sfw_cleanup() 
{
  # Restore IFS
  [ -z ${_sfw_old_ifs+x} ] && IFS=$_sfw_old_ifs

  # call a user provided cleanup hook, if it is set
  [ -n "${_sfw_user_exit_hook}" ] && eval "$_sfw_user_exit_hook"

  # explicitly set return value to 0 as otherwise the return value 
  # will be the result of the above comparison 
  return 0
}

# This function can be called by the script to install a custom exit
# hook since _sfw_cleanup just cleans up the mess we made ourselves

set_exit_hook() 
{
  [ -z ${1+x} ] && debug "Missing argument to function call set_exit_hook()"
  _sfw_user_exit_hook=$1
  return 0
}

# A wrapper for the _sfw_internal_variable
unset_exit_hook() { _sfw_user_cleanup_hook=""; return 0; }

# SIGINT, SIGHUP and SIGTERM trap
# This is not a perfectly clean solution as there may be case when a program
# called by the script has a legitimate reason to receive SIGINT without 
# actually exiting (e.g. emacs), yet those cases are rare.
#
# So all we do for now is calling the cleanup function and then removing
# the trap to kill ourselves. The EXIT trap is removed because otherwise 
# the cleanup function would be called twice. If this is not what you want
# in your particular script, choose a different interrupt handler using 
# set_interrupt 
#
# Signal propagation also enables the shell to set the return code according
# to the signal received (e.g. on SIGINT, return code $? will be 130) 

_sfw_interrupt_handler() 
{
  # Tell the user what happened
  printf '\n%s: terminating script on SIG%s, cleaning up\n' "$_sfw_script_name" $1 >&2
  _sfw_cleanup

  # Unset the exit trap as all it does is to call _sfw_cleanup
  # The user is not supposed to set it's own exit trap, rather
  # use "set_cleanup_hook" to set up a hook for user-specific cleanup
  trap - EXIT $1
  kill -s $1 $$
  return 0
}

set_interrupt() 
{
  local sig signals="INT TERM HUP"

  # Set interrupt handler for all of the above signals
  for sig in $signals; do
    trap "${1-_sfw_interrupt_handler} $sig" $sig
  done
}

#
# Printing information and error messages in sfw scripts. These functions
# are provided in order to unify output throughout the script whenever
# runtime messages or errors have to be provided to the user.
#

# This function is meant for internal use only and does not check arguments.
# ALL runtime output goes to stderr, so it can easily be suppressed / distinguished
# from application output
_sfw_print_msg () { printf "%s: %s\n" $_sfw_script_name "$*" >&2; }

# Generic runtime information can be printed using this function. All it does
# is to prepend the script's name to the given text
# 
# Usage:
# runtime_msg <message>

runtime_msg()
{
  # Argument check 
  [ -z ${1+x} ] && debug "Missing argument to function call: runtime_error()"
  
  # Pretty message
  _sfw_print_msg "$*" 
}

# Type of error: usage_error
# The user made a mistake in the usage of the script, most of the time this
# happens when fiddeling with command line arguments. Hence along with the
# actual error message information on how to get further help is provided.
# The error message is printed to stderr
#
# Usage:
# usage_error <error message>

usage_error()
{	
  # Argument check 
  [ -z ${1+x} ] && debug "missing argument to function call: usage_error()"

  # Print error message, give advice
  _sfw_print_msg "$*" 
  echo "Try '$_sfw_script_name --help' for more information." >&2
  exit 1
} 

# Type of error: runtime_error
# This function is for errors that occured outside of the script's
# responsibility. Since it's not a syntactical error, no additional
# information is displayed (main difference to usage_error)
#
# Usage:
# runtime_error <error message>

runtime_error()
{
  # Argument check 
  [ -z ${1+x} ] && debug "Missing argument to function call: runtime_error()"

  # Pretty error message
  _sfw_print_msg "$*"
} 

# Output an internal error. The programmer made a mistake, so a
# bug report help message is printed, too.
#
# Usage:
# debug <message>

debug ()
{
  # Now this really shouldn't happen 
  [ -z ${1+x} ] && debug "Missing argument to function call: debug()"

  # Print error and bug report message
  _sfw_print_msg "$*"
  _sfw_print_msg "Command line: $_sfw_cmdline_arg_list"
  _sfw_print_msg "Report this bug to: @SCRIPT_BUGREPORT@"
  exit 1
} 
# Usage and version information are displayed if the user ask's for them.
# Usage text and variable values are parsed into the executable script
# automatically when running "make"
#
# "--help" and "--version / -V" are expected to work for all scripts. Period.
# Since the getopts() library is not a requirement, we do not rely on it's
# functionality and simple parse the command line ourselves.
# Since these functions are either called during script initialization or 
# not at all, they will be unset by the init code. 

_sfw_help_version_check()
{
  local cmdline_arg

  for cmdline_arg in "$@"; do 
    case $cmdline_arg in
 
      # Print usage text
      --help)
	cat << EOF_USAGE_TEXT
Usage: $_sfw_script_name $_sfw_synopsis
@SCRIPT_SHORT_DESCRIPTION@

_usage_text_replaced_by_sed_

For more details see ${_sfw_man_title}(${_sfw_man_section}).
EOF_USAGE_TEXT
	exit 0
	;;

      # Print version information
      -V|--version)
  	echo "$_sfw_script_name $_sfw_script_version (powered by Shell Script Framework v1.0)"
  	echo "$_sfw_copyright"
  	echo "$_sfw_license"
  	echo "$_sfw_copying"
  	echo "$_sfw_warranty"
  	exit 0
	;;
    esac
  done
}

# Generic functions that do not fit into one of the other categories
# but are part of the basic sfw framework. This is NOT the place
# for "nice to have" library functions 

# This function uses eval magic to split up a list of items that possibly contain
# whitespace. This function is required by argv() and also by the sfw_cli.sh library
# for the nopt_argv() function, see sfw_cli.sh for details. It is not meant to be 
# called directly as it does not do proper error checking 

# See also:
# http://www.linuxjournal.com/content/bash-preserving-whitespace-using-set-and-eval
#
# Usage: _sfw_get_arg_from_list <name of list> <N> <name of return variable>
# Returns: 
# 0 on success (with $return_variable = N-th argument)
# 1 on failure


# This function is meant to provide a single point of failure for both the
# argv() function from the generic sfw header as well as for the nopt_argv()
# function that is part of the sfw_cli.sh library
# It is not meant to be called directly and simply provides a consistent 
# argument check for both (argv and nopt_argv) use cases. 
#
# Usage _sfw_argv_wrapper <caller name> <arg list name> [arguments to the originating function call]
_sfw_get_arg_from_list() 
{
  local _sfw_caller _sfw_arg_list _sfw_numeric_arg _sfw_var_name _sfw_nth_arg

  # We only check rudimentarily for our "own" arguments and store them 
  [ $# -lt 2 ] && debug "illegal number of arguments to function call: _sfw_arg_wrapper()"
  _sfw_caller="$1"
  eval _sfw_arg_list="\$${2}"

  # We shift for easier reading. From now on we're dealing with the arguments
  # that were provided to the CALLING function (remember, this is a wrapper)
  # Hence we're performing argument checking on the caller's behalf
  shift 2

  # Now we check if the caller was called properly
  [ -z ${1+x} ] && debug "missing argument to function call: ${_sfw_caller}()"

  # Check if the argument is indeed numeric and if so, store it
  case "$1" in
    *[!0-9]*) debug "numeric argument to function call expected: ${_sfw_caller}()" ;;
  esac

  # Make sure N is >= 1 (this one is nasty, did YOU think of it ?)
  [ $1 -ge 1 ] && _sfw_numeric_arg=$1 || _sfw_numeric_arg=1

  # If there is another argument, the caller wants the result in a variable 
  [ -z ${2:+x} ] || _sfw_var_name=$2

  # Get the argument from the list using ev[ia]l magic
  # We WANT parameter expansion here so we do NOT quote
  eval set -- $_sfw_arg_list
  
  # If the numerical argument is out of range, we return right away
  # Otherwise we now have the Nth argument from the list and "set" it
  [ $_sfw_numeric_arg -le $# ] && eval set -- \$${_sfw_numeric_arg} || return 1

  # Let's see how the caller wants the result returned
  [ -z ${_sfw_var_name+x} ] && printf "%s\n" "$*" || eval $_sfw_var_name=\"$*\"

  return 0
}

# This function is the user level interface to command line arguments 
# It simply calls the sfw internal function _sfw_argv_wrapper, see above
# Usage: argv <N> [variable name]
# Returns:
argv() { _sfw_get_arg_from_list argv _sfw_cmdline_arg_list $@ && return 0 || return 1; }

# echo does, depending on the shell, support a couple of options
# Hence a mere 'echo $var' will not always yield the result which
# you might expect, try this with 
#
# var="-e -n value" ; echo $var
# and / or read 
# http://unix.stackexchange.com/questions/65803/why-is-printf-better-than-echo/65819#65819
#
# This is not an issue as long as you control the output / value of $var,
# but if you are working with text from unknown sources / user input, it
# might ruin your output. This simple echo replacement avoids that issue
# in a portable manner.
# 
# Usage: echo TEXT
echo() { printf '%s\n' "$*"; }
# Strictly report errors and unset variables
# This requires the following:
#  
# When working with positional parameters: 
#  use ${1-} to avoid error messages when using positional parameters
#
# When dealing with variables:
#  Use [ -z ${var+x} ] to check if a variable is set before using it
#  The result is true, if the variable is unset, false otherwise
#
# see http://www.redsymbol.net/articles/unofficial-bash-strict-mode/
# for details
#
# CAVE: pipefail
# Since "pipefail" is not overly portable it is not set here.
# Either set it yourself or see:
# http://unix.stackexchange.com/questions/14270/get-exit-status-of-process-thats-piped-to-another

set -o nounset
set -o errexit

# Make sure IFS is what we expect it to be.
# (Unsetting IFS makes IFS default to ' \t\n' in many, but not all shells.
# Do NOT use bashism here, see
#  https://wiki.ubuntu.com/DashAsBinSh#I_am_a_developer._How_can_I_avoid_this_problem_in_future.3F
_sfw_old_ifs=$IFS
IFS=$(printf ' \t\n')

# Set exit and interrupt traps
trap _sfw_cleanup EXIT
set_interrupt _sfw_interrupt_handler

# Check whether "--help or -V/--version" is on the cmdline
_sfw_help_version_check "$@"
unset _sfw_help_version_check

# Even if a script does not use commands, there might be a 
# requirement for a certain number of arguments, e.g. a filename
# Hence if a minimum number of arguments is defined (via the Makefile),
# it will automatically be checked
if [ -n "$_sfw_min_args" ]; then
  [ $# -lt $_sfw_min_args ] && usage_error "missing command line argument"
fi

# For ease of development, the Makefile provides the variable SCRIPT_CMD_LIST 
# All words in that variable are considered valid commands to the script
# If a SCRIPT_CMD_LIST was provided, "cmd" is now set to the command provided
# on the command line or we exit with error

if [ -n "$_sfw_cmd_list" ]; then 

  # No cmdline arguments => no valid command
  [ -z ${1+x} ] && usage_error "missing command"

  # Now scan the whole SCRIPT_CMD_LIST
  for cmd in $_sfw_cmd_list; do
    [ "$cmd" = "$1" ] && break
  done

  # To avoid setting a flag in the for-loop to indicate a valid command was found,
  # we simply check the _sfw_cmd against $1 again to find out why the loop finished
  [ "$cmd" = "$1" ] || usage_error "invalid command <$1>"

  # Now remove the command from the cmdline and adjust relevant variables
  shift 1
  argc=$((argc-1))
fi

# Finally, save the command line arguments to an internal list so we can 
# provide command line arguments anywhere in the script. Each argument is
# quoted so that even whitespace containing arguments will be returned intact
# See argv() for details

for arg in "$@"; do 
  _sfw_cmdline_arg_list="${_sfw_cmdline_arg_list:-} '${arg}'"
done
_sfw_cmdline_arg_list="${_sfw_cmdline_arg_list# }"
unset arg


#------------------------------------------------------>
#
# end of Shell Script Framework v1.0 header
#  
#<------------------------------------------------------

