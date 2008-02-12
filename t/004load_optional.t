#!/usr/bin/perl -w
#
# Here we test the presence of optional modules,
# needed for some registries in Net::DRI but not all of them,
# and we warn the user if they are not present

use Test::More tests => 6;

SKIP: {
	eval { require Net::SMTP; };
	skip 'Module Net::SMTP is not installed, you need it if you want to use Net::DRI for: AFNIC (emails)',1 if $@;
	require_ok('Net::DRI::Transport::SMTP');
}

SKIP: {
	eval { require MIME::Entity; };
	skip 'Module MIME::Entity is not installed, you need it if you want to use Net::DRI for: AFNIC (emails)',1 if $@;
	require_ok('Net::DRI::Protocol::AFNIC::Email::Message');
}

SKIP: {
	eval { require XMLRPC::Lite; };
	skip 'Module XMLRPC::Lite is not installed, you need it if you want to use Net::DRI for: Gandi (WebServices)',2 if $@;
	require_ok('Net::DRI::Transport::HTTP::XMLRPCLite');
        require_ok('Net::DRI::Protocol::Gandi::WS::Connection'); ## depends on XMLRPC::Data
}

SKIP: {
	eval { require SOAP::Lite; };
	skip 'Module SOAP::Lite is not installed, you need it if you want to use Net::DRI for: AFNIC (WebServices), BookMyName (WebServices)',1 if $@;
	require_ok('Net::DRI::Transport::HTTP::SOAPLite');
}

SKIP: {
	eval { require SOAP::WSDL; }; ## also needs SOAP::Lite
	skip('Module SOAP::WSDL is not installed, you need it if you want to use Net::DRI for: OVH (WebServices)',1) if $@;
	require_ok('Net::DRI::Transport::HTTP::SOAPWSDL');
}

exit 0;
