## Domain Registry Interface, EURid Domain EPP extension commands
## (based on EURid registration_guidelines_v1_0E-epp.pdf)
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Domain;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::ContactSet;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.9 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Domain - EURid EPP Domain extension commands for Net::DRI

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

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=( 
          create            => [ \&create, undef ],
          update            => [ \&update, undef ],
          info              => [ \&info, \&info_parse ],
	  check             => [ \&check, \&check_parse ],
          delete            => [ \&delete, undef ],
          transfer_request  => [ \&transfer_request, undef ],
          undelete          => [ \&undelete, undef ],
          transferq_request => [ \&transferq_request, undef ],
          trade             => [ \&trade, undef ],
          reactivate        => [ \&reactivate, undef ],
         );

 return { 'domain' => \%tmp };
}

sub capabilities_add
{
 return { 'domain_update' => { 'nsgroup' => [ 'add','del']} };
}

####################################################################################################

sub build_command_extension
{
 my ($mes,$epp,$tag)=@_;
 
 my @ns=@{$mes->ns->{eurid}};
 return $mes->command_extension_register($tag,sprintf('xmlns:eurid="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1]));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless exists($rd->{nsgroup});
 my @n=add_nsgroup($rd->{nsgroup});

 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:create',['eurid:domain',@n]]);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 if (grep { ! /^(?:add|del)$/ } $todo->types('nsgroup'))
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only nsgroup add/del available for domain');
 }

 my $nsgadd=$todo->add('nsgroup');
 my $nsgdel=$todo->del('nsgroup');
 return unless ($nsgadd || $nsgdel);

 my @n;
 push @n,['eurid:add',add_nsgroup($nsgadd)] if $nsgadd;
 push @n,['eurid:rem',add_nsgroup($nsgdel)] if $nsgdel;

 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:update',['eurid:domain',@n]]);
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:info',['eurid:domain',{version=>'2.0'}]]);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$mes->ns('eurid'),1);
 return unless $infdata;

 my @c;
 foreach my $el ($infdata->getElementsByTagNameNS($mes->ns('eurid'),'nsgroup'))
 {
  push @c,Net::DRI::Data::Hosts->new()->name($el->getFirstChild()->getData());
 }

 $rinfo->{domain}->{$oname}->{nsgroup}=\@c;

 my $cs=$rinfo->{domain}->{$oname}->{status};
 foreach my $s (qw/onhold quarantined/) ## onhold here has nothing to do with EPP client|serverHold, unfortunately
 {
  my @s=$infdata->getElementsByTagNameNS($mes->ns('eurid'),$s);
  next unless @s;
  $cs->add($s) if Net::DRI::Util::xml_parse_boolean($s[0]->getFirstChild()->getData()); ## should we also remove 'ok' status then ?
 }
 foreach my $d (qw/availableDate deletionDate/)
 {
  my @d=$infdata->getElementsByTagNameNS($mes->ns('eurid'),$d);
  next unless @d;
  $rinfo->{domain}->{$oname}->{$d}=DateTime::Format::ISO8601->new()->parse_datetime($d[0]->getFirstChild()->getData());
 }

 my $pt=$infdata->getElementsByTagNameNS($mes->ns('eurid'),'pendingTransaction');
 if ($pt->size())
 {
  my %p;
  foreach my $t (qw/trade transfer transferq/)
  {
   my $r=$infdata->getElementsByTagNameNS($mes->ns('eurid'),$t);
   next unless $r->size();
   $p{type}=$t;
   $cs->add(($t eq 'trade')? 'pendingUpdate' : 'pendingTransfer');

   my $c=$r->shift()->getFirstChild();
   while ($c)
   {
    next unless ($c->nodeType() == 1); ## only for element nodes
    my $name=$c->localname() || $c->nodeName();
    next unless $name;
    if ($name eq 'domain')
    {
     my $cs2=Net::DRI::Data::ContactSet->new();
     my $cf=$po->factories()->{contact};
     my $cc=$c->getFirstChild();
     while($cc)
     {
      next unless ($cc->nodeType() == 1); ## only for element nodes
      my $name2=$cc->localname() || $cc->nodeName();
      next unless $name2;
      if ($name2=~m/^(registrant|tech|billing)$/)
      {
       $cs2->set($cf->()->srid($cc->getFirstChild()->getData()),$name2);       
      } elsif ($name2=~m/^(trDate)$/)
      {
       $p{$1}=DateTime::Format::ISO8601->new()->parse_datetime($cc->getFirstChild()->getData());
      }
     } continue { $cc=$cc->getNextSibling(); }
     $p{contact}=$cs2;
    } elsif ($name=~m/^(initiationDate|unscreenedFax)$/)
    {
     $p{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
    } elsif ($name=~m/^(status|replySeller|replyBuyer|replyOwner)$/)
    {
     $p{$1}=$c->getFirstChild()->getData();
    }
   } continue { $c=$c->getNextSibling(); }
   last;
  }
  $rinfo->{domain}->{$oname}->{pending_transaction}=\%p;
 }
}

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:check',['eurid:domain',{version=>'2.0'}]]);
}

sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_content('chkData',$mes->ns('eurid'),1);
 return unless $chkdata;

 foreach my $cd ($chkdata->getElementsByTagNameNS($mes->ns('eurid'),'cd'))
 {
  my $c=$cd->getFirstChild();
  my $domain;
  while($c)
  {
   next unless ($c->nodeType() == 1); ## only for element nodes
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $domain=lc($c->getFirstChild()->getData());
    $rinfo->{domain}->{$domain}->{action}='check';
    foreach my $ef (qw/accepted expired initial rejected/) ## only for domain applications
    {
     next unless $c->hasAttribute($ef);
     $rinfo->{domain}->{$domain}->{'application_'.$ef}=Net::DRI::Util::xml_parse_boolean($c->getAttribute($ef));
    }
   } elsif ($n eq 'availableDate')
   {
    $rinfo->{domain}->{$domain}->{availableDate}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
   }
  } continue { $c=$c->getNextSibling(); }
 }
}


sub delete
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists($rd->{deleteDate}) && $rd->{deleteDate});

 Net::DRI::Util::check_isa($rd->{deleteDate},'DateTime');

 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 my @n=('eurid:delete',['eurid:domain',['eurid:deleteDate',$rd->{deleteDate}->set_time_zone('UTC')->strftime("%Y-%m-%dT%T.%NZ")]]);
 $mes->command_extension($eid,\@n);
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:transfer',['eurid:domain',@n]]);
}

sub add_transfer
{
 my ($epp,$mes,$domain,$rd)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('registrant and billing are mandatory') unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{contact}) && UNIVERSAL::isa($rd->{contact},'Net::DRI::Data::ContactSet') && $rd->{contact}->has_type('registrant') && $rd->{contact}->has_type('billing'));

 my $cs=$rd->{contact};
 my @n;

 my $creg=$cs->get('registrant');
 Net::DRI::Exception::usererr_invalid_parameters('registrant must be a contact object or #AUTO#') unless (UNIVERSAL::isa($creg,'Net::DRI::Data::Contact') || (!ref($creg) && ($creg eq '#AUTO#')));
 push @n,['eurid:registrant',ref($creg)? $creg->srid() : '#AUTO#' ];

 if (exists($rd->{trDate}))
 {
  Net::DRI::Util::check_isa($rd->{trDate},'DateTime');
  push @n,['eurid:trDate',$rd->{trDate}->set_time_zone('UTC')->strftime("%Y-%m-%dT%T.%NZ")];
 }

 my $cbill=$cs->get('billing');
 Net::DRI::Exception::usererr_invalid_parameters('billing must be a contact object') unless UNIVERSAL::isa($cbill,'Net::DRI::Data::Contact');
 push @n,['eurid:billing',$cbill->srid()];

 push @n,add_contact('tech',$cs,9) if $cs->has_type('tech');
 push @n,add_contact('onsite',$cs,5) if $cs->has_type('onsite');

 if (exists($rd->{ns}) && (UNIVERSAL::isa($rd->{ns},'Net::DRI::Data::Hosts')) && !$rd->{ns}->is_empty())
 {
  my $n=Net::DRI::Protocol::EPP::Core::Domain::build_ns($epp,$rd->{ns},$domain,'eurid');
  my @ns=@{$mes->ns->{domain}};
  push @$n,{'xmlns:domain'=>$ns[0],'xsi:schemaLocation'=>sprintf('%s %s',@ns)};
  push @n,$n;
 }

 push @n,add_nsgroup($rd->{nsgroup}) if (exists($rd->{nsgroup}));
 return @n;
}

sub add_nsgroup
{
 my ($nsg)=@_;
 return unless (defined($nsg) && $nsg);
 my @a=grep { defined($_) && Net::DRI::Util::xml_is_normalizedstring($_,1,100) } map { UNIVERSAL::isa($_,'Net::DRI::Data::Hosts')? $_->name() : $_ } (ref($nsg) eq 'ARRAY')? @$nsg : ($nsg);
 return map { ['eurid:nsgroup',$_] } grep {defined} @a[0..8];
}

sub add_contact
{
 my ($type,$cs,$max)=@_;
 $max--;
 my @r=grep { UNIVERSAL::isa($_,'Net::DRI::Data::Contact') } ($cs->get($type));
 return map { ['eurid:'.$type,$_->srid()] } grep {defined} @r[0..$max];
}

sub undelete
{
 my ($epp,$domain)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'undelete',$domain);
 $mes->command_body(\@d);
}

sub transferq_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,['transferq',{'op'=>'request'}],$domain);

 if (Net::DRI::Protocol::EPP::Core::Domain::verify_rd($rd,'period'))
 {
  Net::DRI::Util::check_isa($rd->{period},'DateTime::Duration');
  push @d,Net::DRI::Protocol::EPP::Core::Domain::build_period($rd->{period});
 }

 $mes->command_body(\@d);

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:transferq',['eurid:domain',@n]]);
}

sub trade
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'trade',$domain);
 $mes->command_body(\@d);

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'eurid:ext');
 $mes->command_extension($eid,['eurid:trade',['eurid:domain',@n]]);
}

sub reactivate
{
 my ($epp,$domain)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'reactivate',$domain);
 $mes->command_body(\@d);
}

####################################################################################################
1;
