# These functions print template configuration files 
# Note that shell expansion is suppressed for the HERE documents
# since we make use of the openssl config variables syntax
# When running make, the textual data is parsed into this file
# using sed

# Write a template root ca config file to stdout
cat_root_conf() 
{
  cat << "EOF_ROOT_CA"
# Root CA configuration file

# see https://www.openssl.org/docs/manmaster/apps/config.html
# for an overview of the openssl config format

# The [default] section contains global constants that can be referred to from
# the entire configuration file. It may also hold settings pertaining to more
# than one openssl command.

[ default ]
ca_name                 = @CA_NAME@             	# CA name
ca_dir                  = @CA_DIR@              	# Top dir
default_ca              = $ca_name	               	# The default CA section
ca_key			= $ca_dir/private/$ca_name.key
RANDFILE               	= $ca_dir/mgmt/rnd		# Use RANDFILE
base_url		= http://pki.@CA_NAME@.com	# Sample Base URL
aia_url			= $base_url/$ca_name.cer	# Authority Information Access URL
crl_url			= $base_url/$ca_name.crl	# Certificate Revocation List URL

# The [req] section of the configuration file is used by the openssl req command.
# It defines the CA's key pair, its DN, and the desired extensions for the CA
# certificate.
#
# We do not request extensions for the root certificate. We're root,
# so we just DEFINE extensions 
[ req ]
default_bits            = 4096                 	# RSA key size, see the "pki req" command 
						# for different key types and sizes
default_keyfile		= $ca_key		# CA's private key
encrypt_key             = yes			# Encrypt private key
default_md              = sha256		# see https://www.entrust.com/lp/sha-1-sha-2-faq/ 
utf8                    = yes			# Input is UTF-8
string_mask             = utf8only		# Emit UTF-8 strings
prompt                  = no			# Don't prompt for DN
distinguished_name      = dn			# DN section

# Distinguished name
# These fields seem to be the most common ones in root certificates
[ dn ]
countryName             = "@CA_NAME@ Country Name" 
organizationName        = "@CA_NAME@ Organization"
organizationalUnitName  = "@CA_NAME@ Root CA"
commonName              = "@CA_NAME@ Common Name"

# The remainder of the configuration file is used by the openssl ca command.
# The CA section defines the locations of CA assets, as well as the policies
# applying to the CA.

[ @CA_NAME@ ]
certificate             = $ca_dir/${ca_name}.crt		# The CA cert
private_key             = $ca_key				# CA private key
new_certs_dir           = $ca_dir/certs           		# Certificate archive
serial                  = $ca_dir/mgmt/serial.crt		# CRT serial number
crlnumber               = $ca_dir/mgmt/serial.crl		# CRL serial number
database                = $ca_dir/mgmt/database 		# Database file
unique_subject          = no					# Require unique subject
default_days            = 3650					# Default validity
default_md              = sha256				# MD to use
policy                  = match_pol				# Default naming policy
email_in_dn             = no					# Add email to cert DN
preserve                = no					# Keep passed DN ordering
name_opt                = ca_default				# Subject DN display options
cert_opt                = ca_default				# Certificate display options
copy_extensions         = none					# Copy extensions from CSR
x509_extensions         = tier2_ca_ext				# Default cert extensions
default_crl_days        = 365					# How long before next CRL
crl_extensions          = crl_ext				# CRL extensions

# Naming policies control which parts of a DN end up in the certificate and
# under what circumstances certification should be denied.
[ match_pol ]
countryName             = optional
organizationName        = match               	# Typically an organization will have it's own PKI 
organizationalUnitName  = supplied            	# Organizational unit names help shaping the PKI 
commonName              = supplied           	# Must be present

# These values are listed as a reference.
# A "match-anything" policy makes most sense for external
# (not part of the organizations PKI structure) root CAs

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Certificate extensions define what types of certificates
# the CA is able to create.

# This section is used when self-signing the root certificate
[ root_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always

# Since this is a root ca's config file, it is most likely to sign CA request
# The two sections are configured for different path lengths, hence for a
# Tier2 or Tier3 pki respectively 
[ tier2_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints	= @crl_info

# For more complex setups: a tier3 pki structure 
[ tier3_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:1
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints	= @crl_info

# CRL extensions exist solely to point to the CA certificate that has issued
# the CRL.
[ crl_ext ]
authorityKeyIdentifier  = keyid:always
authorityInfoAccess	= @issuer_info

# Authority Information Access (Issuing CA) URL
# See https://tools.ietf.org/html/rfc5280#section-5.2.7 for details
# BLUF: an url that points to the certificate used to sign the crl
#	one of the urls provided SHOULD be a http url
[ issuer_info ]
caIssuers;URI.0		= $aia_url

# Where to get the certificate revocation list
[ crl_info ]
URI.0			= $crl_url
EOF_ROOT_CA
}

cat_intermediate_conf() 
{
  cat << "EOF_INTERMEDIATE_CA"
# Intermediate CA
# The configuration is customized to meet the needs of a CA-signing CA.

# The [default] section contains global constants that can be referred to from
# the entire configuration file. It may also hold settings pertaining to more
# than one openssl command.

[ default ]
ca_dir                  = @CA_DIR@              	# CA toplevel directory
ca_name                 = @CA_NAME@             	# CA name
default_ca              = $ca_name			# The default CA section
ca_key			= $ca_dir/private/$ca_name.key  # CA private key
RANDFILE                = $ca_dir/mgmt/rnd        	# Use RANDFILE
base_url		= http://pki.@CA_NAME@.com	# Sample Base URL
aia_url			= $base_url/$ca_name.crt	# Authority Information Access URL
crl_url			= $base_url/$ca_name.crl	# Certificate Revocation List URL

# The [req] section of the configuration file is used by the openssl req command.
# It defines the CA's key pair, its DN, and the desired extensions for the CA
# certificate.

[ req ]
default_bits            = 4096                 	# RSA key size, see the "pki req" command 
						# for different key types and sizes
default_keyfile         = $ca_key  		# Default private key file
encrypt_key             = yes			# Protect private key
default_md              = sha256		# MD to use
utf8                    = yes			# Input is UTF-8
string_mask             = utf8only		# Emit UTF-8 strings
prompt                  = no			# Don't prompt for DN
distinguished_name      = dn			# DN section
req_extensions          = reqext            	# Extensions section

[ dn ]
countryName             = "@CA_NAME@ Country Name" 
organizationName        = "@CA_NAME@ Organization"
organizationalUnitName  = "Intermediate CA"
commonName              = "Intermediate CA"

# The default root ca does NOT copy extensions
# We do however define extensions for the certificate request
# so that when the "copy_extensions" policy is changed or the
# request gets signed by a different ca, we already have extensions
# included
#
# Since this is an intermediate (ca-signing ca), we request a pathlen of 1

[ reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:1
subjectKeyIdentifier    = hash
authorityInfoAccess 	= OCSP;URI:http://ocsp.my.host/
authorityInfoAccess     = caIssuers;URI:http://my.ca/ca.html

# The remainder of this configuration file is used by the openssl ca command.
# The [ca] section defines the locations of CA assets, as well as the policies
# applying to the CA.

[ ca ]
certificate             = $ca_dir/${ca_name}.crt       	# The CA cert
private_key             = $ca_key 			# CA private key
new_certs_dir           = $ca_dir/certs          	# Certificate archive
serial                  = $ca_dir/mgmt/serial.crt 	# Serial number file
crlnumber               = $ca_dir/mgmt/serial.crl 	# CRL number file
database                = $ca_dir/mgmt/database 	# Index file
unique_subject          = no				# Require unique subject
default_days            = 730				# How long to certify for
default_md              = sha256			# MD to use
policy                  = match_pol			# Default naming policy
email_in_dn             = no				# Add email to cert DN
preserve                = no				# Keep passed DN ordering
name_opt                = ca_default			# Subject DN display options
cert_opt                = ca_default			# Certificate display options
copy_extensions         = copy				# Copy extensions from CSR
x509_extensions         = ca_ext			# Default cert extensions
default_crl_days        = 7				# How long before next CRL
crl_extensions          = crl_ext			# CRL extensions

# Naming policies control which parts of a DN in a certificate signing request
# end up in the certificate and under what circumstances certification should be denied.

[ match_pol ]
domainComponent         = optional			# Included if present
organizationName        = match             		# Has to match this CA
organizationalUnitName  = optional             		# Included if present
commonName              = supplied              	# Must be present
countryName             = optional

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Certificate extensions define what types of certificates the CA is able to
# create.
#
# Also we use the "copy_extensions" setting to set defaults for certificates
# signed by this ca for the following fields:
#
#subjectKeyIdentifier    = hash
#authorityKeyIdentifier  = keyid:always
#authorityInfoAccess 	 = OCSP;URI:http://ocsp.my.host/
#authorityInfoAccess     = caIssuers;URI:http://my.ca/ca.html
#
# Since this is an intermediate (ca-signing ca), we sign requests with a pathlen of 0

[ ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints	= @crl_info

# CRL extensions exist solely to point to the CA certificate that has issued
# the CRL.

[ crl_ext ]
authorityKeyIdentifier  = keyid:always

# Authority Information Access (Issuing CA) URL
[ issuer_info ]
caIssuers;URI.0		= $aia_url

# Where to get the certificate revocation list
[ crl_info ]
URI.0			= $crl_url
EOF_INTERMEDIATE_CA
}

# Write a template config file for a signing ca to stdout
cat_signing_conf() 
{
  cat << "EOF_SIGNING_CA"
# Simple Signing CA

# The [default] section contains global constants that can be referred to from
# the entire configuration file. It may also hold settings pertaining to more
# than one openssl command.

[ default ]
ca_name                 = @CA_NAME@             	# CA name
ca_dir                  = @CA_DIR@              	# CA top dir
default_ca              = $ca_name		            	# The default CA section
ca_key			= $ca_dir/private/$ca_name.key  # CA private key
RANDFILE                = $ca_dir/mgmt/rnd        	# Use RANDFILE
base_url		= http://pki.@CA_NAME@.com	# Sample Base URL
aia_url			= $base_url/$ca_name.crt	# Authority Information Access URL
crl_url			= $base_url/$ca_name.crl	# Certificate Revocation List URL

# The next part of the configuration file is used by the openssl req command.
# It defines the CA's key pair, its DN, and the desired extensions for the CA
# certificate.

[ req ]
default_bits            = 4096                  	# RSA key size
default_keyfile         = $ca_key  			# Default private key file
encrypt_key             = yes				# Protect private key
default_md              = sha256			# MD to use
utf8                    = yes				# Input is UTF-8
string_mask             = utf8only			# Emit UTF-8 strings
prompt                  = no				# Don't prompt for DN
distinguished_name      = dn				# DN section
req_extensions          = reqext             		# Desired extensions

[ dn ]
countryName             = "@CA_NAME@ Country Name" 
organizationName        = "@CA_NAME@ Organization"
organizationalUnitName  = "@CA_NAME@ Signing CA"
commonName              = "@CA_NAME@ Signing CA"

#
# The default root ca does NOT copy extensions
# We do however define extensions for the certificate request
# so that when the "copy_extensions" policy is changed or the
# request gets signed by a different ca, we already have extensions
# included
#
# Since this is a signing ca, we request a pathlen of 0
[ reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash

# The remainder of the configuration file is used by the openssl ca command.
# The CA section defines the locations of CA assets, as well as the policies
# applying to the CA.

[ @CA_NAME@ ]
certificate             = $ca_dir/$ca_name.crt       	# The CA cert
private_key             = $ca_key 			# CA private key
new_certs_dir           = $ca_dir/certs          	# Certificate archive
serial                  = $ca_dir/mgmt/serial.crt 	# Serial number file
crlnumber               = $ca_dir/mgmt/serial.crl 	# CRL number file
database                = $ca_dir/mgmt/database 	# Index file
unique_subject          = no				# Require unique subject
default_days            = 730				# How long to certify for
default_md              = sha256			# MD to use
policy                  = match_pol			# Default naming policy
email_in_dn             = no				# Add email to cert DN
preserve                = no				# Keep passed DN ordering
name_opt                = ca_default			# Subject DN display options
cert_opt                = ca_default			# Certificate display options
copy_extensions         = copy				# Copy extensions from CSR
x509_extensions         = server_ext			# Default cert extensions
default_crl_days        = 7				# How long before next CRL
crl_extensions          = crl_ext			# CRL extensions

# Naming policies control which parts of a DN in a certificate signing request
# end up in the certificate and under what circumstances certification should be denied.

[ match_pol ]
domainComponent         = optional			# Included if present              	
organizationName        = match             		# Must be present
organizationalUnitName  = match             		# Has to match this CA
commonName              = supplied              	# Must be present
countryName             = optional

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Certificate extensions define what types of certificates the CA is able to
# create.

# Since "copy_extensions" is set to "copy" (see the ca section above), the
# extension sections below include basicConstraints with CA:FALSE 
# Hence, if the request contains a basicConstraints extension it will be
# ignored so we do not issue CA certificates by mistake.
#
# Also we use the "copy_extensions" setting to set defaults for certificates
# signed by this ca:
#
# subjectKeyIdentifier    = hash
# authorityKeyIdentifier  = keyid:always
# authorityInfoAccess 	  = OCSP;URI:http://ocsp.my.host/
# authorityInfoAccess     = caIssuers;URI:http://my.ca/ca.html
#

[ server_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
basicConstraints        = CA:false
extendedKeyUsage        = serverAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints	= @crl_info

[ client_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
basicConstraints        = CA:false
extendedKeyUsage        = clientAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints	= @crl_info

[ identity_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
basicConstraints        = CA:false
extendedKeyUsage        = emailProtection,clientAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
authorityInfoAccess     = @issuer_info
crlDistributionPoints	= @crl_info

# CRL extensions exist solely to point to the CA certificate that has issued
# the CRL.

[ crl_ext ]
authorityKeyIdentifier  = keyid:always

# Authority Information Access (Issuing CA) URL
[ issuer_info ]
caIssuers;URI.0		= $aia_url

# Where to get the certificate revocation list
[ crl_info ]
URI.0			= $crl_url
EOF_SIGNING_CA
}

# Write a template request config file to stdout
cat_request_conf() 
{
  cat << "EOF_REQUEST_CONF"
# Sample request configuration file

# see https://www.openssl.org/docs/manmaster/apps/config.html
# for an overview of the openssl config format

# The next part of the configuration file is used by the openssl req command.
# It defines the CA's key pair, its DN, and the desired extensions for the CA
# certificate.

[ req ]
RANDFILE               	= ~/.rnd		# Use RANDFILE
default_bits            = 4096                  # RSA key size
default_keyfile		= private.key		# Default private key file
encrypt_key             = yes                   # Encrypt private key
default_md              = sha256                # see https://www.entrust.com/lp/sha-1-sha-2-faq/ 
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Don't prompt for DN
distinguished_name      = rootca_dn             # DN section
req_extensions          = reqext                # Desired extensions

# Distinguished name
[ rootca_dn ]
0.domainComponent       = "org"
1.domainComponent       = "sample"
organizationName        = "Simple Inc"
organizationalUnitName  = "Sample Root CA"
commonName              = "Sample Root CA"

# X509v3 extensions for the root CA
[ reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:2
subjectKeyIdentifier    = hash

# Certificate extensions define what types of certificates the CA is able to
# create.

[ root_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash

[ signing_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always

# CRL extensions exist solely to point to the CA certificate that has issued
# the CRL.

[ crl_ext ]
authorityKeyIdentifier  = keyid:always
prompt                 	= no
EOF_REQUEST_CONF
}

# Write a TLS/IPSec server request config file to stdout
cat_tls_ipsec_request_conf() 
{
  cat << "EOF_TLS_REQUEST_CONF"
# Certificate signing request configuration customized for 
# certificates intended to be used with EAP-TLS 

# Generic request section for tls/ipsec certificates 
[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = @ENCRYPT_KEY@         # Password-protect private key
default_keyfile		= @KEYFILE@		# The private keyfile name
default_md              = sha256                # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Prompt for DN
distinguished_name      = dn 	        	# DN template
req_extensions          = tls_ipsec_ext       	# Desired extensions


[ dn ]
organizationName        = "4. Organization Name        (eg, company)  "
organizationalUnitName  = "5. Organizational Unit Name (eg, section)  "
commonName              = "6. Common Name              (eg, FQDN)     "

# Conforming implementations generating new certificates with Network
# Access Identifiers (NAIs) MUST use the rfc822Name in the subject
# alternative name field to describe such identities.  The use of the
# subject name field to contain an emailAddress Relative Distinguished
# Name (RDN) is deprecated, and MUST NOT be used.  The subject name
# field MAY contain other RDNs for representing the subject's identity.
[ tls_ipsec_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment,keyAgreement
extendedKeyUsage        = @EXTENDED_KEY_USAGE@ 
subjectKeyIdentifier    = hash
subjectAltName          = @SAN@
EOF_TLS_REQUEST_CONF
}

# Write a EAP-TLS certificate request config file to stdout
cat_eap_tls_request_conf() 
{
  cat << "EOF_EAP_TLS_REQUEST_CONF"
# Certificate signing request configuration customized for 
# certificates intended to be used with EAP-TLS 

# The key-configuration in this section only applies when the
# -l | legacy switch is used when running "pki eap-tls" 
[ req ]
default_bits            = 4096                  # RSA key size
encrypt_key             = @ENCRYPT_KEY@         # Password-protect private key
default_keyfile		= @KEYFILE@		# The private keyfile name
default_md              = sha256                # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Prompt for DN
distinguished_name      = @IDENTITY@         	# DN template
req_extensions          = eap_tls_ext         	# Desired extensions

# In EAP-TLS, the Peer-Id and Server-Id are determined from the subject
# or subjectAltName fields in the peer and server certificates.  For
# details, see Section 4.1.2.6 of [RFC3280].  Where the subjectAltName
# field is present in the peer or server certificate, the Peer-Id or
# Server-Id MUST be set to the contents of the subjectAltName.  If
# subject naming information is present only in the subjectAltName
# extension of a peer or server certificate, then the subject field
# MUST be an empty sequence and the subjectAltName extension MUST be
# critical.
[ @IDENTITY@ ]
organizationName        = "4. Organization Name        (eg, company)  "
organizationalUnitName  = "5. Organizational Unit Name (eg, section)  "
commonName              = "6. Common Name              (eg, FQDN)     "

# Where the peer identity represents a host, a subjectAltName of type
# dnsName SHOULD be present in the peer certificate.  Where the peer
# identity represents a user and not a resource, a subjectAltName of
# type rfc822Name SHOULD be used, conforming to the grammar for the
# Network Access Identifier (NAI) defined in Section 2.1 of [RFC4282].
# If a dnsName or rfc822Name are not available, other field types (for
# example, a subjectAltName of type ipAddress or
# uniformResourceIdentifier) MAY be used.

# Conforming implementations generating new certificates with Network
# Access Identifiers (NAIs) MUST use the rfc822Name in the subject
# alternative name field to describe such identities.  The use of the
# subject name field to contain an emailAddress Relative Distinguished
# Name (RDN) is deprecated, and MUST NOT be used.  The subject name
# field MAY contain other RDNs for representing the subject's identity.
[ eap_tls_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment,keyAgreement
extendedKeyUsage        = @EXTENDED_KEY_USAGE@ 
subjectKeyIdentifier    = hash
subjectAltName          = @SAN@
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
# Generate or verify a certificate signing request

req_help()
{
      cat << EOF_REQ_HELP
Usage: pki req [OPTION] <config file>
 Create a certificate signing request (csr) from the information provided
 in <config file>. If no options are given, a sample csr config file is
 printed to stdout. 
 If the provided config file defines a CA, then default filenames for
 private key and csr are derived from the VALUES IN the config file.
 Otherwise, default output filenames are derived from the CONFIG FILENAME.
 An existing keyfile will be used. If no keyfile is present, it will be
 created (RSA 4096bit). 

Options:
 -e, --ecc                  Create an elliptic curve (ECDSA) key instead of the
                              default RSA key
 -w, --windows              By default, the secp256k1 curve will be used when generating
                              an ecc private key. When "windows" is specified, a windows
                              compatible (P-256 i.e. prime256v2) curve is used.
 -u, --unencrypted          The generated private key will not be encrypted (e.g. some
                              servers require unencrypted keys with their certificates) 
 -k, --keyfile <file>       Use <file> as private key to sign the csr. If <file>
                              does not exist, a private key is generated and
                              written to <file>
 -o, --outfile <file>       Write csr to <file>. Use this option to override 
                              the default filename (see above)
 -p, --passphrase <secret>  Encrypt the private key using passphrase <secret> or, if a
                             keyfile is provided, use this passphrase for decryption of
                             the given key. Either way the given passphrase is automatically
                             applied when decrypting the private key for signing the csr
 -v, --verify 	  	    Use this option to verify a SIGNED csr. With this
			     option, the given filename is not considered a 
                             config file but rather a signed csr
EOF_REQ_HELP
  return 0
}

#########################################################################

req_cmd() 
{
  local csr_conf private_key key_explicit=0 key_options ecc=0 windows=0 encrypted=1 outfile verify=0
  local optlist="c:ek:o:p:uv:w+config:+ecc+keyfile:+outfile:+passphrase+unencrypted+verify+windows"
  local req_passphrase req_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist req_opt; then 

      case "$req_opt" in
  
        # This option generates an ecc key instead of the default
        # RSA key
        e|ecc)
          [ $ecc -eq 0 ] || more_than_once "$req_opt" 
          ecc=1
          key_options="${key_options+$key_options | }ecc"
          ;;

        # The keyfile may be defined explicitly
        # We need the key_explicit flag later on to be able to distinguish
        # the two key exists / key specified on cmdline cases
        k|keyfile)
          [ -z ${private_key+x} ] || more_than_once "$req_opts"
          key_explicit=1
          private_key="$OPTARG"
          ;;

        # Specify the output file name
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once "$req_opts"
	  outfile="$OPTARG"
          ;;

        # Provide a passphrase on the cmdline with all the pros and cons
        p|passphrase)
          [ -z ${req_passphrase+x} ] || more_than_once "$req_opts"
          req_passphrase="$OPTARG"
          ;;

        # This option uses a Windows CNG - compatible curve when
        # creating an ecc key
        w|windows)
          [ $windows -eq 0 ] || more_than_once "$req_opts"
          key_options="${key_options+$key_options | }windows-compatible"
          windows=1
          ;;

        # Generate an unencrypted key (e.g. for server certificates)
        u|unencrypted)
          [ $encrypted -eq 1 ] || more_than_once "$req_opts"
          key_options="${key_options+$key_options | }unencrypted"
          encrypted=0
          ;;

        # Verify a request
        v|verify)
          [ $verify -eq 0 ] || more_than_once $OPTARG
	  verify=1
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non-option argument is the config file to use 
    # We only accept one config file, i.e. create one request at a time
    else
      argv $OPTIND req_nopt_arg
      [ -z ${csr_conf+x} ] || usage_error "invalid argument on command line <$csr_nopt_arg>"
      csr_conf="$req_nopt_arg"
      OPTIND=$((OPTIND+1))
    fi

  done

  # If the -v switch was given, it's not a config file but 
  # a signed csr to verify 
  if [ $verify -eq 1 ]; then
    [ -z ${csr_conf+x} ] && usage_error "No csr to verify"

    if openssl req -noout -in $config >/dev/null 2>&1; then
      runtime_msg "Certificate verified."
      return 0
    else
      runtime_msg "Certificate failed verification."
      return 1
    fi
  fi

  # No config file, no signing request
  if [ -z ${csr_conf+x} ]; then
    usage_error "No config file to create a csr"
  # Otherwise we SET "config" and hence from now on we USE $config !
  else
    set_config "$csr_conf" || return 1
  fi

  # If a passphrase was provided, we make sure it's not whitespace only
  if ! [ -z ${req_passphrase+x} ]; then
    case "$req_passphrase" in 
      *[![:space:]]*) : ;; 
      *)  usage_error "the passphrase must not be empty" ;;
    esac
  fi

  # If "ca_name" and "ca_dir" are present in the config file, 
  # it is considered a ca config file
  # File name values are then created from the config file variables

  if get_ca_from_config $config; then

    [ -z ${outfile+x} ] && outfile=$ca_dir/$ca_name.csr
    [ -z ${private_key+x} ] && private_key=$ca_dir/private/$ca_name.key

  # If it's not a ca config file, derive "default_keyfile" from req section
  # or set the default value for the private keyfile name 
  # Derive certificate request filename from the config filename
  else
    
    # Private keyfile name
    [ -z ${private_key+x} ] && private_key=$(awk '/^default_keyfile / { print $3 }' $config)
    [ -z "$private_key" ] && private_key=${config%.*}.key

    # Outfile name
    [ -z ${outfile+x} ] && outfile=${config%.*}.csr

  fi

  # We do not overwrite existing files
  if [ -e "$outfile" ]; then
    runtime_error "won't overwrite existing file: <$outfile>"
    return 1
  fi

  # If the private key does not exist, it will be created now
  if ! [ -e "${private_key}" ]; then

    # If creating a private key fails, that's an error
    # This function is added to avoid redundancy 
    failed_key() { runtime_error "Generating a private key failed"; }

    # Use given key options or set default values 
    [ -z ${key_options+x} ] && key_options="default: RSA 4096bit"

    # Short runtime info
    runtime_msg "Creating private key for certificate request"

    # Generate an ecc key if required
    if [ $ecc -eq 1 -o $windows -eq 1 ]; then

      # For windows compatibility we need to stick to CNG supported curves
      # otherwise we use the curve bitcoin is using, too
      [ $windows -eq 0 ] && curve=secp256k1 || curve=prime256v1 
      if ! gen_ecc_key ${private_key} $curve $encrypted "${req_passphrase-}"; then
        failed_key 
        return 1
      fi

    # By default, a rsa key is generated
    else
      if ! gen_rsa_key ${private_key} $encrypted "${req_passphrase-}"; then
        failed_key 
        return 1
      fi
    fi

  # If a key exists, it will be used. This means that key options are
  # not effective, so if key options were given this is probably not 
  # what the user wants, hence we exit with error
  else
    if [ $windows -eq 1 -o $ecc -eq 1 -o $encrypted -eq 0 ]; then
      runtime_error "no key options allowed when using existing keyfile"
      return 1
    fi
    key_options="Using existing key"
  fi
    
  # Print some diagnostics
  echo "Config file: 	<$config>"
  echo "Private key:	<$private_key>"
  echo "Key options: 	<$key_options>"
  echo "Output file: 	<$outfile>"

  # Create the CSR and write it to $outfile
  # If a passphrase was provided, it's added to the command
  if run_openssl $outfile req -new -config $config -key $private_key \
                 "${req_passphrase+-passin pass:$req_passphrase}"; then
    return 0
  else
    return 1
  fi
}
# View the most common x509 file types 

view_help() 
{
      cat << EOF_VIEW_HELP
Usage: pki view <file>
 Print the text version x509 certificate or certificate request. 

Options:
 -n, --name <ca name>   No options so far. TODO	
EOF_VIEW_HELP
  return 0
}

#####################################################################

view_cmd() 
{
  local view_opt infile identified=0 view_nopt_arg
  local filetypes="x509 req"
  local informs="PEM DER NET"
  local view_opt_list="l+list"
  local output_options="-text -noout"

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $view_opt_list view_opt; then 

      case "$view_opt" in

        # Specify the output file name
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once $OPTARG
	  outfile=$OPTARG
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # The non-option argument is the file to view 
    else
      argv $OPTIND view_nopt_arg
      if [ -z ${infile+x} ]; then
        infile="$view_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$view_nopt_arg>" 
      fi
    fi

  done

  # No input file, nothing to view
  if [ -z ${infile+x} ]; then
    usage_error "No input file to view"
  else
    is_readable $infile
  fi

  # The outer loop runs through the known file types
  for filetype in $filetypes; do

    # Inner loop runs through all known file formats 
    for inform in $informs; do 
      view_cmd="openssl $filetype -in $infile -inform $inform"
      $view_cmd > /dev/null 2>&1 && { identified=1; break; }
    done
    [ $identified -eq 1 ] && break

  done
 
  # If the file format is identified, output the text 
  # Otherwise throw a runtime errorr 
  if [ $identified -eq 1 ]; then
    $view_cmd $output_options
  else
    runtime_error "Unknown file type"
    return 1
  fi
  return 0
}
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
# Output a TLS / IPSEC server or client request file which
# can then be edited and signed by a signing ca

tls_ipsec_help()
{
      cat << EOF_TLS_IPSEC_HELP
Usage: pki server [options] <file>
  Create a generic, TLS/IPSec certificate signing request

Options:
 -c, --client		Generate a client csr [default=server csr]

EOF_TLS_IPSEC_HELP
  return 0
}

########################################################################

tls_ipsec_cmd() 
{
  local req_name encrypt_key ext_usage client_req=0 san
  local optlist="c+client" tls_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist req_opt; then 

      case "$req_opt" in

        # Specify the output file
        c|client)
          [ $client_req -eq 0 ] || more_than_once $OPTARG
	  client_req=1 
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # the actual certificate request name is a non-option argument
    else
      argv $OPTIND tls_nopt_arg
      if [ -z ${req_name+x} ]; then
        req_name="$tls_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$tls_nopt_arg>" 
      fi
    fi
  done

  # We need a filename for the server request
  [ -z ${req_name+x} ] && usage_error "Certificate signing request name not specified"

  # We do not want to overwrite existing certificates 
  [ -e $req_name ] && runtime_error "file already exists: <$req_name>"

  # Set client / server extended key Usage
  if [ $client_req -eq 0 ]; then
    encrypt_key="no"
    ext_usage="serverAuth"
    san="DNS:sample.uri.org"
  else
    encrypt_key="yes"
    ext_usage="clientAuth"
    san="email:peer@sample.uri.org"
  fi
  
  echo "TLS/IPSec Server Request:	<$req_name>"
  echo "Extended Key Usage:		<$ext_usage>"

  # Write the server certificate signing request config file to $server
  # and modify it to match the given name
  cat_tls_ipsec_request_conf | \
  sed \
  -e "s|@KEYFILE@|${req_name%.*}.key|g" \
  -e "s/@ENCRYPT_KEY@/$encrypt_key/g" \
  -e "s/@EXTENDED_KEY_USAGE@/$ext_usage/g" \
  -e "s/@SAN@/$san/g" \
  > $req_name

  return 0
}
# Output a certificate signing request whose intended usage is
# as a peer- or server-certificate in EAP-TLS

eap_tls_help()
{
      cat << EOF_EAP_TLS_HELP
Usage: pki eap-tls [options] <name>
  Create a client or server certificate request configuration file <name>
  for certificates used during EAP-TLS handshakes in e.g. wireless LANs.
  (In EAP-TLS terminology the client is called "peer")

Options:
 -c, --client	The certificate configuration will be customized
		 for a "peer_id" (default is "server_id")	
 -l, --legacy	By default, an ECC-key will be created for the certificate
		  which will be used automatically by the "req" command.
		  The legacy-option disables the key creation which effectively
		  means that when running the "req" command, the default 4096-bit
		  RSA key will be created with the certificate signing request. 
 -w, --windows	If the certificate will be used by a Windows client, this option
                  will generate the ECC-key using a NIST-approved curve which is 
                  suitable for the Windows CNG crypto api.
EOF_EAP_TLS_HELP
  return 0
}

##########################################################################

eap_tls_cmd() 
{
  local req_name keyfile encrypt_key=0 ext_usage legacy=0 client_req=0 cng=0 san
  local optlist="clw+client+legacy+windows" req_nopt_arg

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist req_opt; then 

      case "$req_opt" in

        # generate a peer_id certificate 
        c|client)
          [ $client_req -eq 0 ] || more_than_once "$req_opt"
	  client_req=1 
          ;;

        # generate the legacy rsa key instead of a modern ecdsa key
        l|legacy)
          [ $legacy -eq 0 ] || more_than_once "$req_opt"
          legacy=1
          ;;

        # request generation of a key usable by the Windows CNG 
        w|windows)
          [ $cng -eq 0 ] || more_than_once "$req_opt"
          cng=1
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # the actual certificate request name is a non-option argument
    else
      argv $OPTIND req_nopt_arg
      if [ -z ${req_name+x} ]; then
        req_name="${req_nopt_arg}.conf"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$req_nopt_arg>"
      fi
    fi
  done

  # You cannot have both legacy AND windows compatibility
  if [ $cng -eq 1 -a $legacy -eq 1 ]; then
    usage_error "Legacy option not compatible with Windows option"
  fi

  # We need a filename for the request
  [ -z ${req_name+x} ] && usage_error "Certificate signing request name not specified"

  # We do not want to overwrite existing certificates 
  if [ -e $req_name ]; then
    runtime_error "file already exists: <$req_name>"
    return 1
  fi

  # If the legacy key is not requested, an ecdsa key will be created
  # By default we use the secp256k1 curve, which is good enough for BitCoin, too
  # If -w / windows is required, we have to use one of the curves supported by
  # the Windows crypto API, see main.sh / gen_cng_ecc_key() for details
  # We generate the parameters first, then the key so we can encrypt 
  keyfile=${req_name%.*}.key
  if [ $legacy -eq 0 ]; then

    if [ -e $keyfile ]; then
      echo "Not creating private key (file exists)"
    else 
      # If it's not a server request, we encrypt the key
      [ $client_req -eq 1 ] && encrypt_key=1
      if [ $cng -eq 1 ]; then
        echo "[ Generating ecdsa key using prime256v1 elliptic curve algorithm ]"
        gen_cng_ecc_key $keyfile $encrypt_key
      else
        echo "[ Generating ecdsa key using sec256k1 elliptic curve algorithm ]"
        gen_ecc_key $keyfile secp256k1 $encrypt_key
      fi
    fi
  fi

  # Set client / server extended key Usage
  if [ $client_req -eq 0 ]; then
    encrypt_key="no"
    identity="server_id"
    ext_usage="serverAuth" 
    san="DNS:sample.uri.org"
  else
    encrypt_key="yes"
    identity="peer_id"
    ext_usage="clientAuth"
    san="email:peer@sample.uri.org"
  fi
 
  # Print some diagnostics 
  echo "EAP-TLS Certificate Request:	<$req_name>"
  echo "Extended Key Usage:		<$ext_usage>"
  echo "EAP Identity:		        <$identity>"
  echo "SAN Type:			<$san>"

  # Write the server certificate signing request config file to $server
  # and modify it to match the given name
  cat_eap_tls_request_conf | \
  sed \
  -e "s|@KEYFILE@|$keyfile|g" \
  -e "s/@ENCRYPT_KEY@/$encrypt_key/g" \
  -e "s/@IDENTITY@/$identity/g" \
  -e "s/@EXTENDED_KEY_USAGE@/$ext_usage/g" \
  -e "s|@SAN@|$san|g" \
  > $req_name

  return 0
}
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
# This function generates a plain "old" rsa key in KEYFILE_NAME.
# The key will be encrypted when the first optional argument is set to 1
# If the key is encrypted, you can supply a second optional argument
# which will be considered the passphrase to use for encryption 
#
# Usage: gen_rsa_key <KEYFILE_NAME> [0|1] [
# Returns:
# 0 on success
# 1 on error

gen_rsa_key() 
{
  local keyfile cipher_param pass_phrase

  # Argument check
  [ -z ${1+x} ] && debug "gen_rsa_key(): missing argument to function call"
  keyfile=$1

  # The encryption argument is optional, if nothing is specified we go
  # with the openssl default
  if ! [ -z ${2+x} ]; then

    # If encryption is requested, we also check for a passphrase
    if [ $2 -eq 1 ]; then
      cipher_param="-aes-128-cbc"
      [ -z ${3:+x} ] || pass_phrase="-pass pass:$3"
    fi

  fi

  # Set parameters for run_openssl()
  genkey_cmd="genpkey -algorithm rsa -pkeyopt rsa_keygen_bits:4096 \
              ${cipher_param-} ${pass_phrase-}"

  # Generate the key and return
  run_openssl $keyfile $genkey_cmd && return 0 || return 1
}

# This function generates a key using elliptic curve cryptographic algorithms
# 
# https://blog.cloudflare.com/a-relatively-easy-to-understand-primer-on-elliptic-curve-cryptography/
# tells us why elliptic curve cryptography is a good idea 
#
# See https://wiki.openssl.org/index.php/Elliptic_Curve_Cryptography#Named_Curves
# for why it has to be "named_curve"
#
# See https://en.bitcoin.it/wiki/Secp256k1 for the choice of curve when the system supports it
#
# See https://msdn.microsoft.com/en-us/library/windows/desktop/bb204778%28v=vs.85%29.aspx
# for the list of curves that the "Microsoft Cryptography Next Generation" (CNG) API supports:
# prime256v1, secp384r1, and secp521r1
#
# Usage: gen_ecc_key <KEYFILE_NAME> <PRIME> [0|1] [passphrase]
# Returns:
# 0 on success
# 1 on failure

gen_ecc_key() 
{
  local keyfile curve cipher_param retval pass_phrase
  
  # Arg check
  [ $# -lt 2 ] && debug "missing argument to function call: gen_ecc_key()"
  keyfile=$1
  curve=$2

  # Encryption is an optional argument
  if ! [ -z ${3+x} ]; then
    # If encryption is requested, we also check for a passphrase
    if [ $3 -eq 1 ]; then
      cipher_param="-aes-128-cbc"
      [ -z ${4:+x} ] || pass_phrase="-pass pass:$4"
    fi
  fi

  # We generate parameters seperately 
  curve_cmd="ecparam -name $curve -param_enc named_curve -genkey"
  if run_openssl "${keyfile}.ecparam" "$curve_cmd"; then

    # because only then we can choose to encrypt the key (or not)
    genkey_cmd="genpkey -paramfile ${keyfile}.ecparam ${cipher_param-} ${pass_phrase-}"
    if run_openssl $keyfile $genkey_cmd; then
      rm ${keyfile}.ecparam
      return 0
    else
      runtime_error "failed to generate key from ec parameters"
      return 1
    fi

  else
    runtime_error "failed to generate ec parameters for key"
    return 1
  fi
}
# Generate a pkcs12-file 

p12_help()
{
      cat << EOF_PKCS12_HELP
Usage: pki p12 [options] <file>
  Create a pkcs12 container to export a certificate <file> with its
  corresponding private key (plus an optional certificate chain of trust).
 
Options:
 -f, --force           An existing output file (see "outfile" below) is not over-
	                 written by default. Use this option to enforce overwriting. 
 -i, --include <file>  By default, no certificate chain is included. Use this
   		         option to add a certificate (or many certificates bundled
		         in a single file) to the pkcs12 container. To bundle 
			 certificates in a file use the following command:
                         "cat cert1 cert2 ... certX > bundle"
 -k, --keyfile <file>  The default keyfile name is derived from the main input file.
			 If this does not work, use -k to specify the keyfile name.
 -o, --outfile <file>  Specify the output file [default="ca_name".p12]	
		         Use this option if you want to explicitly specify
		         the filename of the pkcs12 file that will be output.
		         By default, the output filename will be derived from
		         the config file basename.
EOF_PKCS12_HELP
  return 0
}

###################################################################################

p12_cmd() 
{
  local basename certfile keyfile outfile include force=0
  local p12_run_cmd p12_nopt_arg
  local optlist="fi:k:o:+force+include:+keyfile:+outfile:"

  # parse the command line for specific settings
  while [ $OPTIND -le $argc ]; do

    if getopts $optlist p12_opt; then 

      case "$p12_opt" in

        # Force overwriting existing files
        f|force)
          [ $force -eq 0 ] || more_than_once $p12_opt 
          force=1
          ;;

        # Specify a file with certificates that should be included
        i|include) 
          [ -z ${include+x} ] || more_than_once $p12_opt 
	  include="$OPTARG"
          ;;

        # Specify the keyfile, if the default does not work 
        k|keyfile)
          [ z ${keyfile+x} ] || more_than_once $OPTARG
          keyfile="$OPTARG"
          ;;

        # Specify the output file
        o|outfile)
          [ -z ${outfile+x} ] || more_than_once $OPTARG
	  outfile="$OPTARG"
          ;;

        # Missing argument to option, invalid option
        ":") missing_argument $OPTARG ;;
        "?") invalid_option ;; 
           
      esac

    # This command does not allow non-option arguments so far
    else
      argv $OPTIND p12_nopt_arg
      if [ -z ${certfile+x} ]; then
        certfile="$p12_nopt_arg"
        OPTIND=$((OPTIND+1))
      else
        usage_error "invalid argument on command line <$p12_nopt_arg>" 
      fi
    fi
  done

  # You want a SafeBag (pkcs12 container) ? Give me some input...
  [ -z ${certfile+x} ] && usage_error "Certificate file not specified"

  # Derive filenames if necessary
  basename=${certfile%.*}
  [ -z ${keyfile+x} ] && keyfile=${basename}.key

  # check if files are readable
  for file in "${include-}" "${keyfile-}"; do
    if ! is_readable "$file"; then
      runtime_error "cannot read <$file>"
      return 1
    fi
  done

  # The outfile will be placed in the current directory, NOT in the
  # absolute directory of the certificate
  [ -z ${outfile+x} ] && outfile="${basename##*/}.p12"
  
  # Are you sure to overwrite existing files ?
  if [ -e $outfile ]; then
    if ! [ $force -eq 1 ]; then
      runtime_error 'file exists: <$outfile> Use "-f" to overwrite'
      return 1
    fi
  fi

  # Output diagnostics: 
  echo "Certificate:	    <$certfile>"
  echo "Keyfile:	    <$keyfile>"
  echo "Included certs in:  <${include--}>"
  echo "Output file: 	    <$outfile>"
  echo

  # All options are set, now pack the pkcs12 container 
  p12_run_cmd="pkcs12 -export -in $certfile -inkey $keyfile ${include+-certfile $include}"
  run_openssl $outfile $p12_run_cmd && return 0 || return 1
}
# Generate a pkcs12-file 
ext() 
{
  local configfile
#  local ext_optlist="fi:k:o:+force+include:+keyfile:+outfile:"

 # # parse the command line for specific settings
 # while [ $OPTIND -le $argc ]; do

 #   if getopts $optlist p12_opt; then 

 #     case "$p12_opt" in

 #       # Force overwriting existing files
 #       f|force)
 #         [ $force -eq 0 ] || more_than_once $OPTARG
 #         force=1
 #         ;;

 #       # Missing argument to option, invalid option
 #       ":") missing_argument $OPTARG ;;
 #       "?") invalid_option ;; 
 #          
 #     esac

 #   # This command does not allow non-option arguments so far
 #   else
 #     if [ -z ${certfile+x} ]; then
 #       certfile=$(argv $OPTIND)
 #       OPTIND=$((OPTIND+1))
 #     else
 #       usage_error "invalid argument ..." 
 #     fi
 #   fi
 # done

 # If a directory was given, assume there's a config file in that 
 # directory
 configfile=$(argv 1)
 if [ -d $configfile ]; then 
   configfile="${configfile}/config"
 fi

 egrep "^ *\[.*ext.*\]" "$configfile"

 return 0

}
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
