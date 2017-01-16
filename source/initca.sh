# Initialize a directory to be used for a ca

initca_help() 
{
      cat << EOF_INITCA_HELP
Usage: pki initca <CA TYPE> [OPTIONS] [<dirname>]
 Initialize a directory <dirname> with the directory and file tree
 required by the openssl "ca" command to work. The created config
 file <dirname>/config works, but is meant as an example/template only.
 If <dirname> is not specified, it defaults to rootCA, intermediateCA
 or signingCA accordingly.

Options:
 -r, --root	 	Toplevel CA, trust anchor	
 -i, --intermediate 	Subordinate CA that authorizes signing CAs in a tier3-hierarchy 
 -s, --signing	 	CA that issues end user / client certificates ("leaf ca")
 -f, --force		Force overwriting an existing directory structure
 -n, --name <ca name>	Set the name of the CA to <ca name>, default is <dirname>
EOF_INITCA_HELP
  return 0
}

############################################################################

initca_cmd() 
{
  local initca_opts ca_type force=0 initca_nopt_arg ca_subdir
  local initca_optlist="fin:rs+force+intermediate+name:+signing+root"

  # Subfunctions for uniform error messages
  # Error: The CA type was specified more than one
  type_specified_already() 
  {
    usage_error "CA type specified already, invalid option: <$initca_opts>"
  }

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $initca_optlist initca_opts; then 

      case "$initca_opts" in 
  
        # Force overwriting existing directory tree
        f|force)
          [ $force -eq 0 ] || more_than_once $initca_opts
          force=1
	  ;;

        # sub CA, e.g. intermediate CA or subject CA
	i|intermediate)
	  [ -z ${ca_type+x} ] && ca_type="intermediate" || type_specified_already
	  ;;

        # root ca
	r|root)
          [ -z ${ca_type+x} ] && ca_type="root" || type_specified_already
	  ;;

	# signing ca
	s|signing)
          [ -z ${ca_type+x} ] && ca_type="signing" || type_specified_already
	  ;;

  	# Set the CA name
  	n|name)
	  [ -z "$ca_name" ] && ca_name="$OPTARG" || more_than_once $OPTARG 
	  ;;
          
        # Missing argument, invalid option
        ":") missing_argument "$OPTARG" ;;
	"?") invalid_option ;; 

      esac

    # Not an option, so this must be our directory name
    else
      argv $OPTIND initca_nopt_arg
      [ -z "$ca_dir" ] || usage_error "invalid argument on command line <$initca_nopt_arg>" 
      ca_dir="$initca_nopt_arg"
      OPTIND=$((OPTIND+1))
    fi

  done

  # Check if a type was specified
  [ -z ${ca_type+x} ] && usage_error "CA type not specified, cannot init CA"

  # If no directory was given, a default is set
  if [ -z "$ca_dir" ]; then
    case "$ca_type" in
      root) 
        ca_dir="rootCA" ;;
      intermediate) 
        ca_dir="subCA" ;;
      signing) 
        ca_dir="signingCA" ;;
    esac
  fi
    
  # Strip a potential trailing "/"
  ca_dir="${ca_dir%/}"

  # If dirname starts with a "/" we consider it an absolute path,
  # otherwise dirname is relative to cwd 
  [ "${ca_dir#/}" = "$ca_dir" ] && ca_dir="${root_dir}/${ca_dir}"

  # Check if a name was specified, else default to last part of ca_dir
  [ -n "$ca_name" ] || ca_name="${ca_dir##*/}"

  # Check if it's all valid characters
  # Changed to use '!' for negation in the second character class as that's
  # what's supported by dash, too
  # Character constraints for CA names are taken from 
  # https://www.openssl.org/docs/manmaster/apps/config.html
  case "$ca_name" in 
    *[[:blank:]]*)
      runtime_error "whitespace not allowed in ca name: <$ca_name>" 
      return 1
      ;;
    *[!.,\;_A-Za-z0-9]*) 
      runtime_error "illegal character in CA name: <$ca_name>"
      return 1
      ;;
    *) : ;;
  esac

  # Do not overwrite existing directories unless explicitly requested
  if [ -d "$ca_dir" ]; then
    if [ $force -eq 0 ]; then
      runtime_error "directory <$ca_dir> already exists. Use -f to overwrite"
      return 1
    fi
  else
    if ! mkdir -p "$ca_dir" 2>/dev/null; then
      runtime_error "failed to create directory <$ca_dir>, check directory permissions"
      return 1
    fi
  fi

  # Create ca directory tree 
  for ca_subdir in private mgmt certs; do
    mkdir -p $ca_dir/$ca_subdir
  done
  chmod 0700 $ca_dir/private

  # Output the config file
  write_conf $ca_type > $ca_dir/config

  # Parse the config file 
  parse_conf $ca_dir/config

  # Initialize the database, filenames must match the config file !
  > $ca_dir/mgmt/database
  echo 01 > $ca_dir/mgmt/serial.crt
  echo 01 > $ca_dir/mgmt/serial.crl
  return 0
}
