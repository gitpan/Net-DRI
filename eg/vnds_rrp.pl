#!/usr/bin/perl -w
#
# A Net::DRI example
# See also t/600vnds_rrp.t

use strict;

use Net::DRI;

my $dri=Net::DRI->new(10); ## 10 seconds cache

eval
{
$dri->add_registry('VNDS',{tz=>'America/New_York'});

## See Net::DRI::Transport::Socket documentation for list of options
$dri->target('VNDS')->new_current_profile('profile1','Net::DRI::Transport::Socket',[{timeout=>10,defer=>1,close_after=>1,socktype=>'tcp',remote_host=>'localhost',remote_port=>5555,protocol_connection=>'Net::DRI::Protocol::RRP::Connection',protocol_version=>1,client_login=>'MyLOGIN',client_password=>'MyPASSWORD'}],'Net::DRI::Protocol::RRP',[]);

my $rc=$dri->domain_create_only('example.com',{Duration => DateTime::Duration->new(years => 2)});

my $exd=$dri->get_info('exDate'); ## a DateTime object

$rc=$dri->domain_info('example.com');

$rc=$dri->domain_delete_only('example.com');

};


if ($@)
{
 print "AN ERROR happened !!!\n";
  $@->print();
} else
{
 print "OK\n";
}


exit 0;
