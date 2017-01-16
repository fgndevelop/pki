#---------------------------------------------------------->
#
#  Shell Script Framework v0.1a library
#
#  sfw_cli.sh
#
#  Command line interface for sfw scripts
#  See the Makefile on how to define values for _sfw_ variables
#
#<----------------------------------------------------------

# Usage: getopts <optstring> <return variable> [arg]
#
# getopts() processes the arguments given with [arg] or, if there are no
# arguments provided, processes the arguments on the command line.
# OPTIND indicates the next argument that will be processed by getopts() 
#
# optstring:
# All allowed short (i.e. single character) options are simply concatenated,
# if an option requires an argument it is followed by a colon ":"
# Long options are prefixed with a plus sign "+". If they require an 
# argument, a colon has to be appended to the long option.
# There is no "optional argument", but this is something the caller
# can easily implement using the required argument ":" syntax (see Return Values)
# In an optstring consisting of mixed short and long options, short options have
# to come first.
# Example: "aei:OU+long-opt+long-opt-with-required-arg:"
# This optstring allows for the short options a, e, O, U and i which requires an argument.
# Long options are "long-opt" and "long-opt-with-required-arg" which requires an argument.
#
# Short Options
# Short options start with a single dash "-". Arguments to short options can either
# be directly appended to the option as in "-Ieth0" (implicit argument) or can 
# directly  follow the option as a seperate element on the command line as in 
# "-I eth0" (explicit argument)
# Short options can be concatenated into an option list, e.g.: "-aeOU"
# If an option with a required argument is part of an option list, it has to 
# be the last option in the list as otherwise all characters following the 
# option are considered an implicit argument.
# E.g: "-aeOUIeth0" or "-aeOUI eth0", NOT "-aIOUe eth0"
# getopts() uses the global variable _sfw_optlistind to keep track of which
# character in the option list should be processed next
#
# Long Options
# Long options start with a double dash "--". Arguments to long options can either
# be directly appended to the option using an equal sign "=" as in "--long-opt=file"
# (implicit argument) or can directly follow the option as a seperate command line argument
# as in "--long-opt file" (explicit argument).
# Long options must not be concatenated.
#
# Return Values:
#
# 1 getopts() returns 1 if the argument indicated by OPTIND is NOT an option
#   according to the optstring provided or if OPTIND is larger than the number
#   of available options. The end of available options can be marked by the non-optional
#   argument "--". In the absence of "--", all arguments provided to getopts / on the 
#   command line are considered options.
#
# 0 In all other cases, getopts returns 0. If a valid option (according to "optstring")
#   was found, <return variable> is set to the option character or option string respectively.
#   If the option requires an argument and the argument is present, it will be placed into OPTARG.
# 
# 0 If an invalid option was found, <return variable> is set to "?" and the invalid
#   option character or string will be placed into OPTARG.
#
# 0 If a valid option was found that requires an argument, but no argument (neither
#   implicit nor explicit) was provided, then <return variable> will be set to ":" and the
#   option name will be put into OPTARG. It is then up to the caller to decide whether
#   this is an error or not - which is practically identical to an "optional argument"
#
# Unless the return value is 1, the OPTIND variable will be updated to point to the next
# argument to be processed. 
#
# Error Reporting
# This getopts() simply does not print any error messages, so unlike with bash or dash
# getopts you do not need to prepend a ":" before your optstring to silence error reporting.
# It is entirely up to the calling function to determine what is considered an error and 
# how to act upon it.

###############################################################################


# These variables are global to make clear that they are used by all three
# getopts() functions: getopts(), _sfw_is_valid_short() and _sfw_is_valid_long()

_sfw_sh_opts=""
_sfw_l_opts=""
_sfw_optlistind=1
_sfw_token=""
_sfw_valid=""
_sfw_option=""
_sfw_possible_arg=""
_sfw_arg_required=0

###############################################################################

# Validate a short option. This function is called by the getopts() function.
# It checks if _sfw_token against the short options in _sfw_sh_opts
#
# Usage: _sfw_validate_short
# Returns:
# 0 = it is a valid short option (if it needs an argument, that is in OPTARG)
# 1 = it is NOT a valid short option
# 2 = it is a valid short option BUT a required argument was not found

_sfw_validate_short() 
{
  local _sfw_trim_count _sfw_token_cutoff

  # If _sfw_optlistind is larger than the number of characters in our option (list), 
  # somebody miscounted and that's an error. We return "invalid short option" then
  # as we don't know any better.
  [ $_sfw_optlistind -gt ${#_sfw_token} ] && return 1 

  # If _sfw_optlistind is greater than one, we are currently processing a short option
  # list, so trim our option list down to the next character indicated by _sfw_optlistind 
  if [ $_sfw_optlistind -gt 1 ]; then
    # Remove the first character _sfw_optlistind-1 times
    _sfw_trim_count=$((_sfw_optlistind-1))
    while [ $_sfw_trim_count -gt 0 ]; do
      _sfw_token=${_sfw_token#?}
      _sfw_trim_count=$((_sfw_trim_count-1))
    done
  fi

  # We update pointers now. Whether or not the option proves to be valid
  # doesn't matter, we process it once and then move on to the next 
  # _sfw_token might be a single character option with implicit argument,
  # which we don't know now at this point and have to adjust later on 
  if [ ${#_sfw_token} -gt 1 ]; then
    _sfw_optlistind=$((_sfw_optlistind+1))
  else
    OPTIND=$((OPTIND+1))
    _sfw_optlistind=1; 
  fi

  # Isolate the first character from our (possible) option character list 
  # and remove it from the token. The rest of the token serves as implicit
  # argument. In some shells combining # / % expansion in one expression is
  # possible yet it has proven to not be portable (e.g. raspberry pi's dash won't do it)
  # Hence the _sfw_cutoff variable had to be introduced
  _sfw_token_cutoff="${_sfw_token#?}"
  _sfw_option="${_sfw_token%${_sfw_token_cutoff}}"
  _sfw_token=${_sfw_token#$_sfw_option}

  # Now parse through the option string, character by character
  while [ -n "$_sfw_sh_opts" ]; do 

    # Get the next option character from our optstr and
    # remove it from the optstring itself
    _sfw_valid=${_sfw_sh_opts%${_sfw_sh_opts#?}}
    _sfw_sh_opts=${_sfw_sh_opts#$_sfw_valid}

    # Check if there's an argument indicator following in the optstring,
    # we have to remove it anyway 
    case "$_sfw_sh_opts" in
      :*) _sfw_arg_required=1 ; _sfw_sh_opts=${_sfw_sh_opts#:} ;;
      *)  _sfw_arg_required=0 ;;
    esac

    # If the character doesn*t match our valid character from the optstring,
    # we're done here 
    [ "$_sfw_option" = "$_sfw_valid" ] || continue

    # If we don't need an argument, we have all we need in _sfw_option  
    [ $_sfw_arg_required -eq 0 ] && return 0

    # So we need an argument...
    # Since the rest of the token is considered an implicit argument AND
    # has precedence over possible explicit arguments, we overwrite 
    # _sfw_possible_arg
    [ -n "$_sfw_token" ] && _sfw_possible_arg="$_sfw_token"

    # Now we only have to check against _sfw_possible_arg which was either
    # empty and overwritten with the implicit argument, is still empty or
    # was set to the explict arg from the very start 
    # OPTIND has to be increased either because we had an explicit argument
    # or because it was not increased when entering the function
    if [ -n "$_sfw_possible_arg" ]; then
      OPTARG="$_sfw_possible_arg"
      OPTIND=$((OPTIND+1))
      _sfw_optlistind=1
      return 0
    else
      return 2
    fi
  done

  # It's not a valid option
  return 1 
}

###############################################################################

# Usage: _sfw_validate_long optstring name [possible_arg]
# Return values:
# 0 = it is a valid long option (if it needs an argument, that is in OPTARG)
# 1 = it is NOT a valid long option
# 2 = it is a valid long option BUT a required argument was not found
_sfw_validate_long() 
{
  # long options are easy - they cannot be concatenated, so we can safely
  # update OPTIND right away 
  OPTIND=$((OPTIND+1))

  # We set _sfw_option here and adjust it if need be
  _sfw_option="$_sfw_token"

  # Long options are all seperated by "+" so this ev[ia]l magic serves
  # as a basic syntax check, too - and saves us some variable definitions
  eval IFS=\"+\" command eval set -- '\$_sfw_l_opts' 

  # Now parse through the optstring
  for _sfw_valid in "$@"; do 

    # Check if an argument modifier is present and remove it from the option 
    case "$_sfw_valid" in
      *:) _sfw_arg_required=1
          _sfw_valid=${_sfw_valid%:} ;;
      *)  _sfw_arg_required=0 ;;
    esac

    # Check if the beginning of our token matches the valid option 
    # If not, we can move right on to the next valid option 
    [ "$_sfw_option" = "${_sfw_option#$_sfw_valid}" ] && continue

    # Now it can be one of three things: 
    # 1) an exact match with our long option
    # 2) an exact match with an implicit argument appended using "="
    # 3) anything else => garbage

    # If there are trailing characters in our token, they are per definitionem
    # the implicit argument to that option as concatenation is NOT allowed with
    # long options ...
    if [ -n "${_sfw_option#$_sfw_valid}" ]; then

      # ... so if we DON'T need an argument, that makes it an invalid option
      [ $_sfw_arg_required -eq 1 ] || return 1

      # If it starts with "=", the argument to our option is syntactically correct
      # and we can return. Otherwise, it's an invalid option
      _sfw_possible_arg="${_sfw_option#$_sfw_valid}"
      case "$_sfw_possible_arg" in
        =*) 
          OPTARG="${_sfw_possible_arg#=}"
          _sfw_option="${_sfw_valid}"
          return 0
          ;;
        *) return 1 ;;
      esac

    # No trailing characters, so we take it from here 
    else
      
      # If no argument is required, then we're good !
      [ $_sfw_arg_required -eq 0 ] && return 0
       
      # We need an argument, so if it's not there, return an error
      [ -n "$_sfw_possible_arg" ] || return 2 

      # Otherwise set OPTARG, OPTIND and return
      OPTARG="$_sfw_possible_arg"
      OPTIND=$((OPTIND+1))
      return 0

    fi
  done

  # No more options in optstr => it's not a valid option
  # _sfw_option is set already, so all we need to do is to return an error
  return 1 
}

###############################################################################

# --- This is the main getopts() code ---

# Usage:
# getopts <optstring> <return variable> [arguments to parse]
# Returns: 
# 0 in most cases
# 1 if blabla

getopts() 
{
  local _sfw_optstring _sfw_last_arg _sfw_ret_value_var _sfw_ret_value

  # Argument check
  [ $# -lt 2 ] && debug "missing argument to function call getopts()"
  _sfw_optstring="$1" _sfw_ret_var="$2"

  # Roughly check the optstring, at least for whitespace 
  case "$_sfw_optstring" in
    *[[:blank:]]*) debug "illegal character in optstring <$_sfw_optstring>" ;;
  esac

  # clear OPTARG
  OPTARG=""

  # Split the optstring into short and long options
  _sfw_l_opts="${_sfw_optstring#*+}"
  if [ -n "${_sfw_l_opts}" ]; then
    _sfw_l_opts="+${_sfw_l_opts}"
    _sfw_sh_opts=${_sfw_optstring%${_sfw_l_opts}}
  else  
    _sfw_sh_opts="${_sfw_optstring}"
  fi 

  # If more arguments were provided, those are parsed - otherwise 
  # _sfw_cmdline_arg_list (the script's command line arguments) will be parsed 
  # If there's nothing to parse at all, we return an error
  shift 2
  if [ -z "$*" ]; then
    eval set -- $_sfw_cmdline_arg_list
    [ -z "$*" ] && return 1
  fi

  # We set <_sfw_ret_var> to "?" once, which is what  we return in case of error
  # If anything like a valid option is found, it will be set properly
  # If not, we have an error anyway and this way we save a few lines of code
  eval "$_sfw_ret_var=\"?\""

  # Determine the last argument, i.e. count the arguments before the argument 
  # list delimiter (if there is one) 
  _sfw_last_arg=0
  for _sfw_token in "$@"; do
    [ "$_sfw_token" = "--" ] && break
    _sfw_last_arg=$((_sfw_last_arg+1))
  done

  # OPTIND is a shell variable and we neither initialized it nor do we
  # know if someone else fiddled around with it. So we just make sure it is
  # no less than 1 and no more than _$sfw_last_arg
  # Otherwise we simply return 1 and the caller can find out what's wrong
  [ $OPTIND -gt $_sfw_last_arg ] && return 1
  [ $OPTIND -lt 1 ] && return 1

  # Adjust the argument list, so we start with the argument pointed to by OPTIND 
  # OPTIND is updated by is_valid_short and is_valid_long only, we do not touch
  # it here. 
  shift $((OPTIND-1))

  # The (now) first positional parameter is our possible option.
  _sfw_token="${1}"

  # The following positional parameter is a possible argument to the first one
  # if it is not empty and does not start with a "-", that is.
  _sfw_possible_arg="${2-}"
  [ "$_sfw_possible_arg" = "${_sfw_possible_arg#-}" ] || _sfw_possible_arg=""

  # Determine if we have a long, a short or no option and call the
  # appropriate validation function 
  case "$_sfw_token" in  

    # Check if it's a VALID long option
    --*) _sfw_token=${_sfw_token#--}
        _sfw_validate_long
        _sfw_ret_value=$?
        ;;

    # Check if it's a valid SHORT option 
    -*) _sfw_token=${_sfw_token#-}
        _sfw_validate_short
        _sfw_ret_value=$?
        ;;
 
    # It's neither nor, return an error
     *) return 1
        ;;
  esac

  # _sfw_option is set to the option (short or long) that was considered
  # for validation and OPTARG is set (if required by the optstring)
  case "$_sfw_ret_value" in 

    # valid option: return _sfw_option
    0) eval "$_sfw_ret_var=\"$_sfw_option\""
       ;;
         
    # invalid option: return "?" + the invalid option in OPTARG
    1) eval "$_sfw_ret_var=?" 
       OPTARG="$_sfw_option"
       ;;
         
    # valid option, missing argument: return ":" + option in OPTARG
    2) eval "$_sfw_ret_var=:"
       OPTARG="$_sfw_option"
       ;;

  esac
  return 0
}

######################################################################

# Convenience functions for consistent error messages.  
# See the sample script for usage examples.

invalid_option() { usage_error "invalid option -- '$OPTARG'"; }
missing_argument() { usage_error "missing argument to option -- '$OPTARG'"; }
more_than_once() { usage_error "option given more than once -- '$1'"; }

######################################################################

# These functions are complements to the getopts() functions.
# Instead of dealing with all command line arguments though, they deal
# with what is left behind after parsing the command line with getopts():
# the non-optional arguments.
# If your script is supposed to deal with more than one non-optional argument,
# e.g. a list of filenames, these functions are quite useful. Since it takes
# getopts() functionality to find out what is a non-optional argument on the
# command line rather than an argument to an option, these functions are
# included in this library.
# See the sample script for a detailed example on how to use getopts() and
# noptv() functions to provide a very robust command line for your script.

# noptc, as opposed to argc, is the global counter for non-optional arguments
# This variable should be considered read only (but that would be a bashism).
# It will be updated by add_nopt()
nopt_argc=0

# This list is for internal use only. Elements should be added to this list
# using add_nopt()
_sfw_nopt_arg_list=""

# Add a non-option argument to the _sfw_nopt_list. This function must be
# called by the programmer as he's the only one to know what is an option,
# an argument to an option and a non-option argument
# It is best called during command line argument parsing, see the sfw
# sample script for an example of the intended use
#
# Usage: is_nopt_arg <index>
#

is_nopt_arg()
{
  local _sfw_nopt_arg

  # Argument check
  [ -z ${1+x} ] && debug "missing argument to function call: is_nopt_arg()"

  # Get the command line argument and add it to the list
  if argv $1 _sfw_nopt_arg; then
    _sfw_nopt_arg_list="${_sfw_nopt_arg_list:-} '$_sfw_nopt_arg'"
    nopt_argc=$((nopt_argc+1))
    return 0
  else
    return 1
  fi 
}

# This function is the equivalent to argv() for non-optional arguments
# It can only return arguments that have been added using add_nopt_arg()
# Usage: nopt_argv [N] [variable name]
# If N is not specified, it defaults to 1
 # You have to specifiy the numeric argument
nopt_argv() { _sfw_get_arg_from_list nopt_argv _sfw_nopt_arg_list $@ && return 0 || return 1; }

# End of file sfw_cli.sh
