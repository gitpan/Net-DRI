## Domain Registry Interface, EPP Connection handling
##
## Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Connection;

use strict;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.13 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Connection - EPP Connection handling (RFC4934) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub login
{
 shift if ($_[0] eq __PACKAGE__);
 my ($cm,$id,$pass,$cltrid,$dr,$newpass,$pdata)=@_;

 my $got=$cm->();
 $got->parse($dr);
 my $rg=$got->result_greeting();

 my $mes=$cm->();
 $mes->command(['login']);
 my @d;
 push @d,['clID',$id];
 push @d,['pw',$pass];
 push @d,['newPW',$newpass] if (defined($newpass) && $newpass);
 push @d,['options',['version',$rg->{version}->[0]],['lang','en']];

 my @s;
 push @s,map { ['objURI',$_] } @{$rg->{svcs}};
 push @s,['svcExtension',map {['extURI',$_]} @{$rg->{svcext}}] if (exists($rg->{svcext}) && defined($rg->{svcext}) && (ref($rg->{svcext}) eq 'ARRAY'));
 @s=$pdata->{login_service_filter}->(@s) if (defined($pdata) && ref($pdata) eq 'HASH' && exists($pdata->{login_service_filter}) && ref($pdata->{login_service_filter}) eq 'CODE');
 push @d,['svcs',@s] if @s;

 $mes->command_body(\@d);
 $mes->cltrid($cltrid) if $cltrid;
 return $mes->as_string('tcp');
}

sub logout
{
 shift if ($_[0] eq __PACKAGE__);
 my ($cm,$cltrid)=@_;
 my $mes=$cm->();
 $mes->command(['logout']);
 $mes->cltrid($cltrid) if $cltrid;
 return $mes->as_string('tcp');
}

sub keepalive
{
 shift if ($_[0] eq __PACKAGE__);
 my ($cm,$cltrid)=@_;
 my $mes=$cm->();
 $mes->command(['hello']);
 return $mes->as_string('tcp');
}

####################################################################################################

sub get_data
{
 shift if ($_[0] eq __PACKAGE__);
 my ($to,$sock)=@_;

 my $c;
 $sock->read($c,4); ## first 4 bytes are the packed length
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','Unable to read EPP 4 bytes length (connection closed by registry ?)','en')) unless $c;
 my $length=unpack('N',$c)-4;
 my ($m);
 while ($length > 0)
 {
  my $new;
  $length-=$sock->read($new,$length);
  $m.=$new;
 }
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',$m? $m : '<empty message from server>','en')) unless ($m=~m!</epp>$!);

 return Net::DRI::Data::Raw->new_from_string($m);
}

sub parse_greeting
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift;
 my ($code,$msg,$lang)=find_code($dc);
 unless (defined($code) && ($code==1000))
 {
  return Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','No greeting node',$lang);
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL','Greeting OK',$lang);
 }
}

## Since <hello /> is used as keepalive, answer is a <greeting>
sub parse_keepalive
{
 return shift->parse_greeting(@_);
}

sub parse_login
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift;
 my ($code,$msg,$lang)=find_code($dc);
 unless (defined($code) && ($code==1000))
 {
  my $eppcode=(defined($code))? $code : 'COMMAND_SYNTAX_ERROR';
  return Net::DRI::Protocol::ResultStatus->new_error($eppcode,$msg || 'Login failed',$lang);
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL',$msg || 'Login OK',$lang);
 }
}

sub parse_logout
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift;
 my ($code,$msg,$lang)=find_code($dc);
 unless (defined($code) && ($code==1500))
 {
  my $eppcode=(defined($code))? $code : 'COMMAND_SYNTAX_ERROR';
  return Net::DRI::Protocol::ResultStatus->new_error($eppcode,$msg || 'Logout failed',$lang);
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL_END ',$msg || 'Logout OK',$lang);
 }
}

sub find_code
{
 my $dc=shift;
 my $a=$dc->as_string();
 return () unless ($a=~m!</epp>!);
 return (1000,'Greeting OK')  if ($a=~m!<greeting>!);
 $a=~s/>[\n\s\t]+/>/g;
 my ($code,$msg,$lang);
 return () unless (($code)=($a=~m!<response><result code=["'](\d+)["']>!));
 return () unless (($lang,$msg)=($a=~m!<msg(?: lang=["'](\S+)["'])?>(.+)</msg>!));
 return (0+$code,$msg,$lang || 'en');
}

####################################################################################################
1;
