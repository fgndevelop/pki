# main.sh
#

###############################################################################################

# The config file is reused throughout sub commands so we unify the procedure here.
# This function sets the global "$config" variable to the config file name.
# If the argument provided is a directory, a default config file named "config" in
# that directory is expected. 
#
# Usage: set_config <directory|filename>
# Returns: 
# 0 if config file was found and is_readable
# 1 otherwise

set_config() 
{
  local config_candidate

  # argument check
  [ -z ${1+x} ] && debug "missing argument to function call: set_config()"

  # are we set already ?
  if [ $config_set -eq 1 ]; then
    usage_error "config file already set to <$config>"  
    return 1
  fi
  
  # Adjust candidate filename if we were given a directory 
  [ -d "$1" ] && config_candidate="${1%/}/config" || config_candidate="$1"
 
  # If we can't read it, we fail
  if ! is_readable "$config_candidate"; then
    runtime_error "cannot read config file: <$config_candidate>"
    return 1

  # or set the global variables
  else
    config_set=1
    config="$config_candidate"
    return 0
  fi
} 

# Get ca data from the config file and set the global variables
# ca and ca_dir accordingly

# Usage: get_ca_from_config <CONFIG FILE>
get_ca_from_config() 
{
  local ca_config_file

  # Argument check
  [ -z ${1+x} ] && debug "get_ca_from_config(): missing argument to function call"

  # Before we proceed, make sure we can read the config file
  is_readable "$1" && ca_config_file="$1" || return 1

  # Get ca name from the config file
  ca_name=$(awk '/^ca_name / { print $3 }' $ca_config_file)
  [ -z "$ca_name" ] && return 1

  # Get ca dir from the config file
  ca_dir=$(awk '/^ca_dir/ { print $3 }' $ca_config_file)
  [ -z "$ca_dir" ] && return 1 

  return 0
}

###############################################################################################

# Openssl every now and then leaves stale output files of zero length behind,
# when interrupted (CTRL-C) or when it fails (e.g. wrong password)
# To avoid having empty / stale output files, we use the -outfile option with
# openssl whenever an output file is required and only on successful return
# of the relevant openssl command the $tmpfile is moved to the actual output file.
# This exit hook removes an existing tmpfile

pki_exit_hook() 
{
  [ -z "$tmpfile" ] || rm -f $tmpfile
  return 0
}

###############################################################################################

# This function is used to run openssl commands and takes care of the 
# aforementioned $tmpfile / $outfile
# Usage: <outfile> <cmd ...>
run_openssl() 
{
  local openssl_outfile openssl_cmd size openssl_redirect

  # Argument check
  [ $# -lt 2 ] && debug "Missing argument to run_openssl() function call"

  # Parse arguments
  openssl_outfile="$1"
  shift 1 
  openssl_cmd="$@"

  # Execute the openssl command
  if openssl $openssl_cmd -out $tmpfile; then

    # openssl seems to return 0 even when it failed, e.g. when creating a key
    # fails because an empty passphrase was provided
    # So we stat $tmpfile and if it's empty we failed

    if [ -e "$tmpfile" ]; then
      size=$(stat -c "%s" $tmpfile)
      if [ $size -gt 0 ]; then
        mv $tmpfile $openssl_outfile
        return 0
      fi
    fi

  fi

  # Unfortunately, we failed
  rm -f $tmpfile
  return 1
}

###############################################################################################

# Global variables
tmpfile=".tmpfile.pki_$$"
ca_name=""
ca_dir=""

# Default configuration file is assumed to be in the current directory
config="./config"
config_set=0

# root directory is the current working directory
root_dir=$(pwd)

# Main function, obviously
main() 
{
  local help_for_cmd

  # Install our own exit handler
  set_exit_hook pki_exit_hook 

  # If a command was given without the required arguments, we 
  # generously print the help for the command
  case $cmd in
    initca|req|selfsign|sign|view|tls|ipsec|eap-tls|revoke|clr|p12|ext)
      [ $argc -eq 0 ] && { help_cmd $cmd; return 1; } ;; 
  esac

  # Check whether a valid command was given and 
  # call the subroutines 
  case $cmd in
  
    # Initialize a CA and it's directory structure
    # Type of CA is the required minimum of arguments
    initca) 
      initca_cmd || { runtime_error "Initializing the CA failed"; return 1; }
      ;;
  
    # Generate a certificate signing request
    req)
      req_cmd || { runtime_error "Creating a certificate signing request failed"; return 1; }
      ;;
  
    # Selfsign a certificate signing request
    selfsign)
      selfsign_cmd || { runtime_error "Selfsigning the csr failed"; return 1; }
      ;;
  
    # Sign a certificate request, at least the csr file is required as
    # an argument
    sign)
      sign_cmd || { runtime_error "Signing a certificate failed"; return 1; }
      ;;
  
    # View a certificate request | certificate | ...
    # Requires the file to view as an argument
    view) view_cmd || return 1 ;;
  
    # Create a certificate request for a TLS/IPSEC server, at least
    # a (file)name has to be provided
    tls|ipsec) tls_ipsec_cmd || return 1 ;; 
  
    # Create a certificate request for a EAP-TLS Certificate, same as 
    # for tls / ipsec
    eap-tls) eap_tls_cmd || return 1 ;; 
  
    # Revoke a certificate 
    revoke) revoke_cmd || return 1 ;; 
  
    # Generate a certificate revocation list for a ca 
    crl) crl_cmd || return 1 ;; 
  
    # Generate a pkcs12 container
    p12) p12_cmd || return 1 ;;
  
    # Get detailed help on individual commands
    help)
      argv 1 help_for_cmd || usage_error "Help for what ?" 
      help_cmd "$help_for_cmd"
      ;;

    # Show extensions present in a config file
    ext) ext_cmd || return 1
      ;; 
     
  esac
}

####################################################

# Call the main loop. All subcommands are expected to properly return 0
# on success and 1 on failure so that we can exit with an overall return
# value of 0 or 1 respectively from here.

if main; then
  exit 0
else
  exit 1
fi

# End of file main.sh
