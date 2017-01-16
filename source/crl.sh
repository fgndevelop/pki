# Generate a certificate revocation list. A CA configuration file is required,
# since obviously only those who issue certificates can revoke them.
# Sometimes the default keyfile name is changed to something more meaningful
# so it can be chosen via cmdline option -k | --keyfile

crl_help() 
{
      cat << EOF_CRL_HELP
Usage: pki crl [OPTION] <config file|directory>
 Create a certificate revocation list(crl) from the information provided
 in <config file>. If you specify a directory here, that directory must
 have a ca configuration file named <config> 
 (i.e. the directory was created using the "initca" command)

Options:
 -o, --outfile <file>	Write crl to <file> Use this option to override 
	                  the default filename (see above)
 -k, --keyfile <file>	Use <file> as private key to sign the crl
EOF_CRL_HELP
  return 0
}

##################################################################

crl_cmd() 
{
  local crl_conf private_key key_opts outfile force=0 verify=0
  local optlist="o:+outfile:+verify" crl_run_cmd crl_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist crl_opt; then 

      case "$crl_opt" in

        # The keyfile may be defined explicitly
        k|keyfile)
          [ -z ${private_key+x} ] || more_than_once "$crl_opt" 
          private_key=$OPTARG
          ;;

        # Specify the output file
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once "$crl_opt" 
	  outfile="$OPTARG"
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non-option argument is the config file to use. Only one
    # config file can be used.
    else
      argv crl_nopt_arg $OPTIND
      if [ -z ${crl_conf+x} ]; then
        crl_conf="$crl_nopt_arg" 
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line: <$crl_nopt_arg>" 
      fi
    fi

  done

  # No config file, no signing request
  [ -z ${crl_conf+x} ] && usage_error "No config file to create a crl"
    
  # Set the config file 
  set_config "$crl_conf" || return 1

  # If a keyfile is provided, make sure we can read it
  if [ -z ${private_key+x} ]; then
    if ! is_readable $private_key; then
      runtime_error "cannot read private key <$private_key>"
      return 1
    fi 
  fi

  # If "ca_name" and "ca_dir" are present in the config file, 
  # it is considered a ca config file. Required file names are
  # then created from the config file variables

  if get_ca_from_config $crl_conf; then

    [ -z ${outfile+x} ] && outfile="$ca_dir/$ca_name.crl"
    [ -z ${private_key+x} ] && private_key="$ca_dir/private/$ca_name.key"

  # If it's NOT a CA config file, that's an error
  else
    runtime_error "not a CA config file: <$crl_conf>"
    return 1
  fi

  # We do not overwrite existing files, let the user delete it first
  if [ -e "$outfile" ]; then
    runtime_error "file already exists: <$OPTARG>"
    return 1
  fi

  # Print some diagnostics
  echo "Config file: 	<$crl_conf>"
  echo "Private key:	<$private_key>"
  echo "Output file: 	<$outfile>"
  echo

  # Create the CSR and write it to $outfile
  crl_run_cmd="ca -gencrl -config $crl_conf ${keyopts+$keyopts}"
  run_openssl "$outfile" "$crl_run_cmd" && return 0 | return 1
}
