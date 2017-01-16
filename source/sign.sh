# Sign a certificate request

sign_help()
{
      cat << EOF_SIGN_HELP
Usage: pki sign [options] <file>
  Sign the certificate signing request (csr) in <file> 

Options:
 -c, --config <file|dir>  Read configuration from <file> [default=./config]
  			    Alternatively you may specify a directory, if that
		            directory has a ca configuration file named <config>
			    (i.e. the directory was created using the "initca" command)
 -e, --extension <name>	  Use extension <name> [default=set in config file]
			    This option can be given multiple times. For
			    each given extension, a section must exist in
			    the config file.
 -o, --outfile <file>	  Specify the output file [default="ca_name".crt]	
			    Use this option if you want to explicitly specify
			    the filename of the certificate that will be output.
			    By default, the output filename will be derived from
			    the config file basename.
EOF_SIGN_HELP
  return 0
}

#######################################################################

sign_cmd() 
{
  local sign_opt config_set=0 ext_list ext_opts="" csr sign_cmd outfile
  local optlist="c:e:o:+config:+extensions+outfile:" csr_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist sign_opt; then 

      case "$sign_opt" in

        # Specify the configuration file or directory to use 
        c|config) 
	  set_config "$OPTARG" || return 1
          ;;

        # Specify the extensions to use
        e|extensions)
          ext_list="${ext_list+$ext_list }$OPTARG" 
          ;;

        # Specify the output file
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once $OPTARG
	  outfile=$OPTARG
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non optional argument is the certificate request to sign
    else
      argv $OPTIND csr_nopt_arg
      if [ -z ${csr+x} ]; then
        csr="$csr_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$csr_nopt_arg>"
      fi
    fi
  done

  # We need a readable certificate signing request 
  [ -z ${csr+x} ] && usage_error "Certificate signing request not specified"
  if ! is_readable $csr; then
    runtime_error "cannot read csr <$csr>"
    return 1
  fi

  # If extensions are provided using -e, we make sure the corresponding
  # sections are present in the config file
  if [ -n "${ext_list+x}" ]; then

    # Report an error if an extension is not found in the config file
    for ext in $ext_list; do
      if grep "\[ *${ext} *\]" $config >/dev/null 2>&1; then
        ext_opts="-extensions $ext"
      else
        runtime_error "No section for $ext in <$config>"
        return 1
      fi
    done

  else
    ext_list="ca default extensions"
  fi

  # If no outfile is defined, we create a name from the certificate request 
  if [ -z ${outfile+x} ]; then
    outfile=${csr%.*}.crt
  fi

  # We do not want to overwrite existing certificates 
  if [ -e $outfile ]; then
    runtime_error "file already exists: <$outfile>"
    return 1
  fi

  # Output diagnostics: 
  echo "Config:		<$config>"
  echo "Request:	<$csr>"
  echo "Extensions:	<$ext_list>"
  echo "Output file: 	<$outfile>"
  echo

  # All options are set, now sign the certificate request
  sign_cmd="ca -config $config -in $csr ${ext_opts} -notext"
  run_openssl $outfile $sign_cmd && return 0 || return 1
}
