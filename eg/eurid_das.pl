#!/usr/bin/perl -w
#
#
# A Net::DRI example

use strict;

use Net::DRI;

my $dri=Net::DRI->new(10);

eval {
############################################################################################################
$dri->add_registry('EURid',{});

my $rc=$dri->target('EURid')->new_current_profile('profile1','das');

die($rc) unless $rc->is_success();

foreach my $dom (qw/europa.eu dezedfezecvvz.eu/)
{
print 'DOMAIN: '.$dom."\n";
$rc=$dri->domain_check($dom);
print 'IS_SUCCESS: '.$dri->result_is_success()."\n";
print 'CODE: '.$dri->result_code().' / '.$dri->result_native_code()."\n";
print 'MESSAGE: ('.$dri->result_lang().') '.$dri->result_message()."\n";
print 'EXIST: '.$dri->get_info('exist')."\n";
print 'EXIST_REASON: '.$dri->get_info('exist_reason')."\n";
print "\n";
}

$dri->end();
};

if ($@)
{ 
 print "\n\nAn EXCEPTION happened !\n";
 if (ref($@))
 {
  $@->print();
 } else
 {
  print($@);
 }
} else
{
 print "\n\nNo exception happened";
}

print "\n";
exit 0;
