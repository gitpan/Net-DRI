#!/usr/bin/perl -w
#
#
# A Net::DRI example

use strict;

use Net::DRI;

my $dri=Net::DRI->new(10);
my $rc;

eval {
############################################################################################################

$dri->add_registry('VNDS',{});
$rc=$dri->target('VNDS')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('nsi.com',$dri);
display('laposte.net',$dri);

$dri->add_registry('AERO',{});
$rc=$dri->target('AERO')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('cdg.aero',$dri);

$dri->add_registry('ORG',{});
$rc=$dri->target('ORG')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('laptop.org',$dri);

$dri->add_registry('INFO',{});
$rc=$dri->target('INFO')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('mta.info',$dri);

$dri->add_registry('EURid',{});
$rc=$dri->target('EURid')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('europa.eu',$dri);

$dri->add_registry('BIZ',{});
$rc=$dri->target('BIZ')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('neulevel.biz',$dri);

$dri->add_registry('MOBI',{});
$rc=$dri->target('MOBI')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('buongiorno.mobi',$dri);

$dri->add_registry('NAME',{});
$rc=$dri->target('NAME')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('sudoku.name',$dri);

$dri->add_registry('LU',{});
$rc=$dri->target('LU')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('restena.lu',$dri);

$dri->add_registry('WS',{});
$rc=$dri->target('WS')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('website.ws',$dri);

$dri->add_registry('SE',{});
$rc=$dri->target('SE')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('malmo.se',$dri);

$dri->add_registry('CAT',{});
$rc=$dri->target('CAT')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('madrid.cat',$dri);

$dri->add_registry('AT',{});
$rc=$dri->target('AT')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('stare.at',$dri);

$dri->add_registry('TRAVEL',{});
$rc=$dri->target('TRAVEL')->new_current_profile('profile1','whois');
die($rc) unless $rc->is_success();
display('paris.travel',$dri);

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
 my ($dom,$dri)=@_;
 print 'DOMAIN: '.$dom."\n";
 my $rc=$dri->domain_info($dom);
 print 'IS_SUCCESS: '.$dri->result_is_success().' [CODE: '.$dri->result_code().' / '.$dri->result_native_code()."]\n";
 my $e=$dri->get_info('exist');
 print 'EXIST: '.$e."\n";
 if ($e)
 {
  foreach my $k (qw/clName clID clWebsite clWhois upName upID crName crID crDate upDate exDate wuDate/)
  {
   print $k.': '.($dri->get_info($k) || 'n/a')."\n";
  }
  print 'status: '.join(' ',$dri->get_info('status')->list_status())."\n" if defined($dri->get_info('status'));
  print 'ns: '.$dri->get_info('ns')->as_string()."\n" if defined($dri->get_info('ns'));
 }
 my $cs=$dri->get_info('contact');
 if ($cs)
 {
  foreach my $t ($cs->types())
  {
   foreach my $c ($cs->get($t))
   {
    print 'contact '.$t.' : '.$c->as_string()."\n";
   }
  }
 }
 print "\n\n";
}
