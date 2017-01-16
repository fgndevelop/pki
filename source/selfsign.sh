# Selfsign a root ca's certificate request

selfsign_help()
{
      cat << EOF_SELFSIGN_HELP
Usage: pki selfsign [options] <csr> 
  Selfsign the (root ca's) Certificate Signing Request in file <csr>
  This command makes most sense after creating a ca of type "root ca"
  The generated certificate is a "stand alone" certificate, it will
  not affect the ca database in terms of serial number etc.

Options:
 -c, --config <file>	  Read configuration from <file> [default=./config]
 -e, --extension <name>	  Use extension <name> [default=root_ca_ext]
                            This option can be given multiple times. For
 	                    each given extension, a section must exist in
 	                    the config file.
 -o, --outfile <file>     Specify the output file [default="ca_name".crt]	
                            Use this option if you want to explicitly specify
 		            the filename of the certificate that will be output.
 			    By default, the output filename will be derived from
 		            values set in the config file
 -p, --passphrase <pass>  The private key's passphrase. If this value is unset and
                           the private key is encrypted, the passphrase will be asked
                           for
 -s, --serial <number>	  Set the serial number (default is 1)
 -d, --digest <digest>	  Specify the digest algorithm to use (default is sha256)
 -v, --validity <days>	  Specify the certificate's validity in days (default is 30 years)
EOF_SELFSIGN_HELP
  return 0
}

###########################################################################

selfsign_cmd() 
{
  local sign_opt ext_list extensions csr selfsign_cmd outfile privkey_passphrase 
  local sign_key validity=10680 digest=sha256 serial=1 selfsign_nopt_arg
  local optlist="c:d:e:o:p:r:s:v:+config:+digest:+extensions+outfile:+passphrase+request:+serial:+validity:"

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist sign_opt; then 

      case "$sign_opt" in

        # Specify the configuration file to use
	# Since we are using the x509 command, only extension
        # sections in the config file are relevant
        c|config) set_config "$OPTARG" ;;

        # Provide a passphrase on the cmdline with all the pros and cons
        p|passphrase)
          [ -z ${privkey_passphrase+x} ] || more_than_once "$sign_opt"
          privkey_passphrase="$OPTARG"
          ;;

        # Specify the extension sections to use, these must be
	# present in the config file
        e|extensions)
          ext_list="${ext_list+$ext_list }$OPTARG" 
          ;;

        # Specify the output file
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once "$sign_opt" 
	  outfile=$OPTARG
          ;;

        # Digest to use, default is sha256
	d|digest)
          digest=$OPTARG
	  ;;

	# Serial Number for the certificate, default is 1
	s|serial)
	  serial=$OPTARG
	  ;;

        # Validity in days for the certificate, default is 30 years
  	v|validity)
	  validity=$OPTARG
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non-option argument is the request to selfsign 
    else
      argv $OPTIND selfsign_nopt_arg
      [ -z ${csr+x} ] || usage_error "invalid argument on command line <$selfsign_nopt_arg>"
      csr="$selfsign_nopt_arg"
      OPTIND=$((OPTIND+1))
    fi

  done

  # No request to selfsign, no signinature
  [ -z ${csr+x} ] && usage_error "Missing argument: certificate signing request"

  # 

  # Make sure we can read input files (global default for $config is "./config")
  for file in "$csr" "$config"; do
    if ! is_readable "$file"; then
      runtime_error "cannot read file: <$file>"
      return 1
    fi
  done

  # Since we're self signing, this is most likely a ROOT CA creating
  # the root certificate. Hence this is the default extension if no
  # extensions are provided using the -e option 
  #
  # If extensions are provided using -e, we make sure the corresponding
  # sections are present in the config file
 
  # Set the default if no extensions were given 
  [ -z ${ext_list+x} ] && ext_list="root_ca_ext"

  # Report an error if an extension is not found in the config file
  for ext in $ext_list; do
    if grep "\[ *${ext} *\]" $config >/dev/null 2>&1; then
      extensions="${ext_opts+$ext_opts }-extensions $ext"
    else
      runtime_error "no section for $ext in <$config>"
      return 1
    fi
  done

  # If no outfile is defined, we assume a default file name in accordance
  # with the default settings in the config file: $ca_dir/$ca_name.crt
  # (values are retrieved from the config file)

  get_ca_from_config $config || runtime_error "Could not get ca name from <$config>"

  # We make sure not to overwrite existing files
  if [ -z ${outfile+x} ]; then
    outfile=$ca_dir/${ca_name}.crt
  fi
  
  # We assume the default keyfile name (MAYBE: add a k|key option?)"
  sign_key=${ca_dir}/private/${ca_name}.key

  # Overwriting is probably not what the user wanted
  if [ -e $outfile ]; then
    runtime_error "won't overwrite existing file: <$outfile>" 
    return 1
  fi

  # Output diagnostics: 
  echo "Output file: 	<$outfile>"
  echo "Config:		<$config>"
  echo "Request:	<$csr>"
  echo "Sign key: 	<$sign_key>"
  echo "Extensions:	<$ext_list>"
  echo

  # All options are set, now selfsign the certificate request and return
  selfsign_cmd="x509 -req -signkey $sign_key \
	        -days $validity -set_serial $serial -$digest \
		-extfile $config $extensions \
		-in $csr \
                ${privkey_passphrase+-passin pass:$privkey_passphrase}"

  run_openssl "${outfile}" "$selfsign_cmd" && return 0 || return 1 

}

