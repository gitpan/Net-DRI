#!/usr/bin/perl -w
#
#
# A Net::DRI example for IRIS DCHK operations, currently only .DE

use strict;

use Net::DRI;

my $dri=Net::DRI->new(10);
my $rc;

eval {

$dri->add_registry('DENIC',{});
$rc=$dri->target('DENIC')->new_current_profile('profile1','dchk',{},[]);
die($rc) unless $rc->is_success();
display($dri,'denic.de');
display($dri,'ecb.de');

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

sub display
{
 my ($dri,$dom)=@_;
 print 'DOMAIN: '.$dom."\n";
 my $rc=$dri->domain_info($dom);
 print 'IS_SUCCESS: '.$dri->result_is_success().' [CODE: '.$dri->result_code().' / '.$dri->result_native_code()."]\n";
 unless ($dri->result_is_success())
 {
  print $dri->result_message(),"\n";
  return;
 }
 my $e=$dri->get_info('exist') || '?';
 print 'EXIST: '.$e."\n";
 if ($e eq '1')
 {
  foreach my $k (qw/crDate exDate duDate idDate/)
  {
   print $k.': '.($dri->get_info($k) || 'n/a')."\n";
  }
  print 'status: '.join(' ',$dri->get_info('status')->list_status())."\n" if defined($dri->get_info('status'));
 }
 my $rs=$dri->get_info('result_status');
 print 'RESULT STATUS: ';
 $rs->print_full() if defined($rs);
 print "\n\n";
}
