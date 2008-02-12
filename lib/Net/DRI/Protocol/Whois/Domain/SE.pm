## Domain Registry Interface, Whois commands for .SE (RFC3912)
##
## Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois::Domain::SE;

use strict;

use Carp;
use DateTime::Format::Strptime;
use Net::DRI::Exception;
use Net::DRI::Util;
use Net::DRI::Data::Contact::SE;
use Net::DRI::Data::ContactSet;
use Net::DRI::Protocol::EPP::Core::Status;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Whois::Domain::SE - .SE Whois commands (RFC3912) for Net::DRI

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

Copyright (c) 2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 return { 'domain' => { info   => [ \&info, \&info_parse ] } };
}

sub info
{
 my ($po,$domain,$rd)=@_;
 my $mes=$po->message();
 Net::DRI::Exception->die(1,'protocol/whois',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 $mes->command(lc($domain));
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rr=$mes->response();
 my $rd=$mes->response_raw();
 my ($domain,$exist)=parse_domain($rr,$rd,$rinfo);
 $domain=lc($oname) unless defined($domain);
 $rinfo->{domain}->{$domain}->{exist}=$exist;
 $rinfo->{domain}->{$domain}->{action}='info';

 return unless $exist;

 parse_contacts($domain,$rr,$rinfo);
 parse_dates($domain,$rr,$rinfo);
 parse_ns($domain,$rr,$rinfo);
 parse_status($domain,$rr,$rinfo);
}

sub parse_domain
{
 my ($rr,$rd,$rinfo)=@_;
 my ($dom,$e);

 if (exists($rr->{'domain'}))
 {
  $e=1;
  $dom=lc($rr->{'domain'}->[0]);
## what is state ?
 } else
 {
  $e=0;
 }
 return ($dom,$e);
}

sub parse_registrar
{
 my ($domain,$rr,$rinfo)=@_;
 $rinfo->{domain}->{$domain}->{clName}=$rr->{'Registrar Name'}->[0] if (exists($rr->{'Registrar Name'}) && $rr->{'Registrar Name'}->[0]) ;
 $rinfo->{domain}->{$domain}->{clEmail}=$rr->{'Registrar Email'}->[0] if (exists($rr->{'Registrar Email'}) && $rr->{'Registrar Email'}->[0]);
 $rinfo->{domain}->{$domain}->{clVoice}=$rr->{'Registrar Telephone'}->[0] if (exists($rr->{'Registrar Telephone'}) && $rr->{'Registrar Telephone'}->[0]);
 $rinfo->{domain}->{$domain}->{clWhois}=$rr->{'Registrar Whois'}->[0] if (exists($rr->{'Registrar Whois'}) &&$rr->{'Registrar Whois'}->[0]) ;
}

sub parse_contacts
{
 my ($domain,$rr,$rinfo)=@_;
 my $cs=Net::DRI::Data::ContactSet->new();
 my %t=qw/holder registrant admin-c admin tech-c tech billing-c billing/;
 while (my ($s,$type)=each(%t))
 {
  next unless (exists($rr->{$s}) && $rr->{$s}->[0] && ($rr->{$s}->[0] ne '-'));
  my $c=Net::DRI::Data::Contact::SE->new();
  $c->srid($rr->{$s}->[0]);
  $cs->add($c,$type);
 }
 $rinfo->{domain}->{$domain}->{contact}=$cs;
}

sub parse_dates
{
 my ($domain,$rr,$rinfo)=@_;
 my $strp=DateTime::Format::Strptime->new(pattern => '%Y-%m-%d', time_zone => 'Europe/Stockholm');
 my %t=qw/created crDate modified upDate expires exDate/;
 while (my ($s,$type)=each(%t))
 {
  next unless (exists($rr->{$s}) && $rr->{$s}->[0] && ($rr->{$s}->[0] ne '-'));
  $rinfo->{domain}->{$domain}->{$type}=$strp->parse_datetime($rr->{$s}->[0]);
 }
}

sub parse_ns
{
 my ($domain,$rr,$rinfo)=@_;
 return unless (exists($rr->{nserver}));
 my $h=Net::DRI::Data::Hosts->new();
 foreach my $ns (grep { defined($_) && $_ } @{$rr->{nserver}})
 {
  my @w=split(/ /,$ns);
  my $name=shift(@w);
  if (@w)
  {
   $h->add($name,\@w);
  } else
  {
   $h->add($name);
  }
 }
 $rinfo->{domain}->{$domain}->{ns}=$h unless $h->is_empty();
}

sub parse_status
{
 my ($domain,$rr,$rinfo)=@_;
 return unless (exists($rr->{'status'}));
 my @s=@{$rr->{'status'}};
 carp('For '.$domain.' new status found, please report: '.join(' ',@s)) if (grep { $_ ne 'ok' } @s);
 $rinfo->{domain}->{$domain}->{status}=Net::DRI::Protocol::EPP::Core::Status->new(\@s) if @s;
 $rinfo->{domain}->{$domain}->{dnssec}=$rr->{'dnssec'}->[0];
}

####################################################################################################
1;
