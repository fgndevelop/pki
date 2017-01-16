# These functions print template configuration files 
# Note that shell expansion is suppressed for the HERE documents
# since we make use of the openssl config variables syntax
# When running make, the textual data is parsed into this file
# using sed

# Write a template root ca config file to stdout
cat_root_conf() 
{
  cat << "EOF_ROOT_CA"
@root_ca_config_file@
EOF_ROOT_CA
}

cat_intermediate_conf() 
{
  cat << "EOF_INTERMEDIATE_CA"
@intermediate_ca_config_file@
EOF_INTERMEDIATE_CA
}

# Write a template config file for a signing ca to stdout
cat_signing_conf() 
{
  cat << "EOF_SIGNING_CA"
@signing_ca_config_file@
EOF_SIGNING_CA
}

# Write a template request config file to stdout
cat_request_conf() 
{
  cat << "EOF_REQUEST_CONF"
@request_config_file@
EOF_REQUEST_CONF
}

# Write a TLS/IPSec server request config file to stdout
cat_tls_ipsec_request_conf() 
{
  cat << "EOF_TLS_REQUEST_CONF"
@tls_ipsec_request_config_file@
EOF_TLS_REQUEST_CONF
}

# Write a EAP-TLS certificate request config file to stdout
cat_eap_tls_request_conf() 
{
  cat << "EOF_EAP_TLS_REQUEST_CONF"
@eap_tls_request_config_file@
EOF_EAP_TLS_REQUEST_CONF
}

# Write an email request config file to stdout
cat_email_request_conf() 
{
  cat << "EOF_EMAIL_REQUEST_CONF"
@email_request_config_file@
EOF_EMAIL_REQUEST_CONF
}

# Write the config file to the given directory, this function
# is a convenience wrapper for the above config file functions
# Usage: write_conf TYPE 
write_conf() 
{
  # Mere argument check
  [ -z ${1+x} ] && debug "write_conf(): missing argument to function call"

  # Supported config file types
  # Practically, a two- or three-tier CA structure should fit any purpose
  case $1 in 
    root)          cat_root_conf ;;
    intermediate)  cat_intermediate_conf ;;
    signing) 	   cat_signing_conf ;;
    *) 		   debug "write_conf(): illegal argument to function call <$1>" ;;
  esac
  return 0
}

# Parse a CA config file to substitute CA_NAME and CA_DIR variables
# Usage: parse_conf CONFIG_FILE

parse_conf() 
{
  # Mere argument check
  [ -z ${1+x} ] && debug "parse_conf(): missing argument to function call"

  # Substitute the two variables using sed
  if sed -i \
  -e "s/@CA_NAME@/$ca_name/g" \
  -e "s|@CA_DIR@|$ca_dir|g" \
  $1; then
    return 0
  else 
    return 1
  fi
}
