# help.sh
#
# Since the pki script is a little complex, we provide help on individual commands 
# Instead of putting all the help texts in here, we leave them with the actual 
# subcommand source as this way it's easier to correct the help texts when 
# a command's parameters change etc.
 
help_cmd() 
{
  # Argument check  
  [ -z ${1+x} ] && debug "missing argument to function call help_cmd()"

  # Call the subcommand's help routine
  case "$1" in 
    initca) initca_help ;;

    req) req_help ;;

    selfsign) selfsign_help ;;

    sign) sign_help ;;

    eap-tls) eap_tls_help ;;
  
    tls|ipsec) tls_ipsec_help ;;

    revoke) revoke_help ;;

    crl) crl_help ;;

    p12) p12_help ;;

    *) usage_error "unknown command: <$help_for_cmd>" ;;
  esac
} 

# End of file help.sh
