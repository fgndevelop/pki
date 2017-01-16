# Revoke a certificate request

revoke_help()
{
      cat << EOF_REVOKE_HELP
Usage: pki revoke [options] <file>
  Revoke a certificate (crt)

Options:
 -c, --config <file>	Read configuration from <file> [default=./config]
 -r, --reason <name>  	Reason why the certificate was revoked [default=unspecified]
     		          Valid reasons are: unspecified, keyCompromise, CACompromise,
           		  affiliationChanged, superseded, cessationOfOperation,
                          certificateHold or removeFromCRL 
EOF_REVOKE_HELP
  return 0
}

revoke_cmd() 
{
  local revoke_opt crt reason revoke_nopt_arg
  local optlist="c:r:+config:+reason:"

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist revoke_opt; then 

      case "$revoke_opt" in

        # Specify the configuration file to use    
        c|config) 
          set_config "$OPTARG" 
          ;;

        # Provide the reason for revocation
        r|reason)
          [ -z ${reason+x} ] || more_than_one "$revoke_opt" 
          reason="$OPTARG"
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # This command does not allow non-option arguments so far
    else
      argv $OPTIND revoke_nopt_arg 
      if [ -z ${crt+x} ]; then
        crt="$revoke_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$revoke_nopt_arg>" 
      fi
    fi
  done

  # If no filename was provided, what can we revoke ?!
  [ -z ${crt+x} ] && usage_error "Certificate to revoke not specified"

  # Set a default revocation reason if none was specified
  [ -z ${reason+x} ] && reason="unspecified" 

  # Check if we can read our input files (default config file is set globally)
  for file in "$crt" "$config"; do
    if ! is_readable "$file"; then
      runtime_error "cannot read file: <$file>"
      return 1
    fi
  done

  # Output diagnostics: 
  echo "Config:		<$config>"
  echo "Certificate:	<$crt>"
  echo "Reason: 	<${reason}>"
  echo

  # All options are set, now sign the certificate request
  # We don't use run_openssl as we don't have an output file
  revoke_cmd="ca -config $config -revoke $crt -crl_reason $reason"
  openssl $revoke_cmd && return 0 || return 1
}
