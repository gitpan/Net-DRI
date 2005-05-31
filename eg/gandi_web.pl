#!/usr/bin/perl -w
#
# A Net::DRI example

use strict;

use Net::DRI;

my $dri=Net::DRI->new();

eval {
$dri->add_registry('Gandi');

## You need to provide your Gandi handle and associated password in the credentials hash ref
$dri->target('Gandi')->new_current_profile('p1','Net::DRI::Transport::Web',[{protocol_connection=>'Net::DRI::Protocol::Gandi::Web::Connection',credentials=>{handle=>'',pass=>''},defer=>0}],'Net::DRI::Protocol::Gandi::Web',[]);

## You want to add Gandi nameserver to your domain example.com (change the domain name !)
my $nsg=Net::DRI::Data::Hosts->new('ns6.gandi.net',['217.70.177.40']);
my $rc=$dri->domain_update_ns_add('example.com',$nsg);

## You can also use domain_update_ns_del and domain_update_ns_set

print "Operation is a success: ".($rc->is_success()? 'YES' : 'NO');
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
