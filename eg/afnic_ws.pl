#!/usr/bin/perl -w
#
# A Net::DRI example

use strict;

use Net::DRI;

my $dri=Net::DRI->new();

eval {
$dri->add_registry('AFNIC');

## You need 
## 1) to download Domain-perl.wsdl and put it in the same path (or correct the URI in service_wsdl),
##    as well as the certificate file, with name afnic-ca.crt (or change the name in ssl_ca_file)
## 2) to replace USERNAME and PASSWORD with your credentials at AFNIC.
$dri->target('AFNIC')->new_current_profile('profile1','Net::DRI::Transport::SOAP',[{proxy_url=>'https://soap-adh.nic.fr/',service_wsdl=>{Domain=>'file:./Domain-perl.wsdl'},ssl_ca_file=>'./afnic-ca.crt',credentials=>['soap-adh.nic.fr:443','Webservices Adherents AFNIC','USERNAME','PASSWORD']}],'Net::DRI::Protocol::AFNIC::WS',[]);

my $rc=$dri->domain_check('toto.fr');
print "Object exist: ".($rc->object_exist()? 'YES' : 'NO');
print "\n";
};

if ($@)
{ 
 print "AN ERROR happened !!!\n";
 $@->print();
} else
{
 print "No error";
}

print "\n";

exit 0;
