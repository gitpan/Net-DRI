## Domain Registry Interface, AFNIC EPP Domain extensions
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

package Net::DRI::Protocol::EPP::Extensions::AFNIC::Domain;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AFNIC::Domain - AFNIC (.FR/.RE) EPP Domain extensions for Net::DRI

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
 my %tmp=(
           update => [ \&update, undef ],
           transfer_request => [ \&transfer_request, undef ],
           trade_request     => [ \&trade_request, \&trade_parse ],
           trade_query      => [ \&trade_query , \&trade_parse ],
           recover_request => [ \&recover_request, \&recover_parse],
           check => [ undef, \&check_parse],
           info => [ undef, \&info_parse],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 return $mes->command_extension_register($tag,sprintf('xmlns:frnic="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('frnic')));
}

sub build_domain
{
 my ($domain)=@_;
 Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($domain) && $domain;
 Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$domain) unless Net::DRI::Util::is_hostname($domain);
 return ['frnic:name',$domain];
 }

sub build_registrant
{
 my ($rd)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('AFNIC needs contact for domain_trade') unless Net::DRI::Util::has_contact($rd);
 my @t=$rd->{contact}->get('registrant');
 Net::DRI::Exception::usererr_invalid_parameters('AFNIC needs one contact of type registrant') unless (@t==1 && Net::DRI::Util::isa_contact($t[0]));
 return ['frnic:registrant',$t[0]->srid()];
}

sub build_cltrid
{
 my ($mes)=@_;
 return (['frnic:clTRID',$mes->cltrid()]);
}

sub verify_contacts
{
 my $rd=shift;
 Net::DRI::Exception::usererr_invalid_parameters('AFNIC needs contact for domain_transfer/domain_trade') unless Net::DRI::Util::has_contact($rd);
 my @t=$rd->{contact}->get('admin');
 Net::DRI::Exception::usererr_invalid_parameters('AFNIC needs only one contact of type admin') unless (@t==1 && Net::DRI::Util::isa_contact($t[0]));
 @t=grep { Net::DRI::Util::isa_contact($_) } $rd->{contact}->get('tech');
 Net::DRI::Exception::usererr_invalid_parameters('AFNIC needs one to three contacts of type tech') unless (@t >= 1 && @t <= 3);
 }

sub build_contacts
{
 my ($rd)=@_;
 my $cs=$rd->{contact};
 my @n;
 push @n,['frnic:contact',{type => 'admin'},$cs->get('admin')->srid()]; ## only one admin allowed
 push @n,map { ['frnic:contact',{type => 'tech'},$_->srid()] } $cs->get('tech'); ## 1 to 3 allowed
 return @n;
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 ## We just verify that if we do a redemption, we only use op=request, because RFC3915 allows also op=report
 my $rgp=$todo->set('rgp');
 return unless (defined($rgp) && $rgp && (ref($rgp) eq 'HASH'));
 my $op=$rgp->{op} || '';
 Net::DRI::Exception::usererr_invalid_parameters('RGP op can only be request for AFNIC') unless ($op eq 'request');
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 verify_contacts($rd);
 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 $mes->command_extension($eid,['frnic:transfer',['frnic:domain',build_contacts($rd)]]);
}

sub parse_trade_recover
{
 my ($po,$otype,$oaction,$oname,$rinfo,$s)=@_;
 my $mes=$po->message();

 my $infdata=$mes->get_extension('frnic','ext');
 return unless $infdata;
 my $ns=$mes->ns('frnic');
 my $c=$infdata->getChildrenByTagNameNS($ns,'resData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,$s);
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'domain');
 return unless $c->size();

 my $pd=DateTime::Format::ISO8601->new();
 $c=$c->shift()->getFirstChild();
 while($c)
 {
  next unless ($c->nodeType() == 1); ## only for element nodes
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}=$oaction;
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name eq 'trStatus')
  {
   $rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(reID|reHldID|acID|acHldID)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(reDate|rhDate|ahDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$name}=$pd->parse_datetime($c->getFirstChild()->getData());
  }
 } continue { $c=$c->getNextSibling(); }
}

sub trade_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 my @n=build_domain($domain);
 push @n,build_registrant($rd);
 push @n,build_contacts($rd);
 $mes->command_extension($eid,['frnic:command',['frnic:trade',{op=>'request'},['frnic:domain',@n]],build_cltrid($mes)]);
}

sub trade_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 my @n=build_domain($domain);
 $mes->command_extension($eid,['frnic:command',['frnic:trade',{op=>'query'},['frnic:domain',@n]],build_cltrid($mes)]);
}

sub trade_parse
{
  my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 parse_trade_recover($po,$otype,'trade',$oname,$rinfo,'traData');
}

sub recover_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message(); 

 my $eid=build_command_extension($mes,$epp,'frnic:ext');
 my @n=build_domain($domain);
 Net::DRI::Exception::usererr_invalid_parameters('authInfo is mandatory for a recover request') unless (Net::DRI::Util::has_auth($rd) && exists($rd->{auth}->{pw}) && $rd->{auth}->{pw});
 push @n,['frnic:authInfo',['frnic:pw',$rd->{auth}->{pw}]];
 push @n,build_registrant($rd);
 push @n,build_contacts($rd);
 $mes->command_extension($eid,['frnic:command',['frnic:recover',{op=>'request'},['frnic:domain',@n]],build_cltrid($mes)]);
}

sub recover_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 parse_trade_recover($po,$otype,'recover',$oname,$rinfo,'recData');
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_extension('frnic','ext');
 return unless $chkdata;
 my $ns=$mes->ns('frnic');
 my $c=$chkdata->getChildrenByTagNameNS($ns,'resData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'chkData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'domain');
 return unless $c->size();

 foreach my $cd ($c->shift()->getChildrenByTagNameNS($ns,'cd'))
 {
  my $c=$cd->getFirstChild();
  my (@r,@f,$domain);
  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $domain=lc($c->getFirstChild()->getData());
    $rinfo->{domain}->{$domain}->{action}='check';
    $rinfo->{domain}->{$domain}->{reserved}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('reserved'));
    $rinfo->{domain}->{$domain}->{forbidden}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('forbidden'));
   } elsif ($n eq 'rsvReason')
   {
    push @r,$c->getFirstChild()->getData();
   } elsif ($n eq 'fbdReason')
   {
    push @f,$c->getFirstChild()->getData();
   }
  } continue { $c=$c->getNextSibling(); }

  ## There may be multiple of them !
  $rinfo->{domain}->{$domain}->{reserved_reason}=join("\n",@r);
  $rinfo->{domain}->{$domain}->{forbidden_reason}=join("\n",@f);
 } ## end of foreach
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_extension('frnic','ext');
 return unless $infdata;
 my $ns=$mes->ns('frnic');
 my $c=$infdata->getChildrenByTagNameNS($ns,'resData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'infData');
 return unless $c->size();
 $c=$c->shift()->getChildrenByTagNameNS($ns,'domain');
 return unless $c->size();

 my $cs=$rinfo->{domain}->{$oname}->{status}; ## a Net::DRI::Protocol::EPP::Extensions::AFNIC::Status object
 foreach my $el ($c->shift()->getChildrenByTagNameNS($mes->ns('frnic'),'status'))
 {
  $cs->rem('ok');
  $cs->add($el->getAttribute('s'));
 }

}

####################################################################################################
1;
