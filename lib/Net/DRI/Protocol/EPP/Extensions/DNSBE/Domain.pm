## Domain Registry Interface, DNSBE Domain EPP extension commands
## (based on Registration_guidelines_v4_7_2-Part_4-epp.pdf)
##
## Copyright (c) 2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
#########################################################################################

package Net::DRI::Protocol::EPP::Extensions::DNSBE::Domain;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Data::Hosts;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::DNSBE::Domain - DNSBE EPP Domain extension commands for Net::DRI

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

Copyright (c) 2006,2007 Patrick Mevzek <netdri@dotandco.com>.
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
          info              => [ undef, \&info_parse ],
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
 
 my @ns=@{$mes->ns->{dnsbe}};
 return $mes->command_extension_register($tag,sprintf('xmlns:dnsbe="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1]));
}

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 ## Registrant contact is mandatory (optional in EPP), already added in Core, we just verify here
 Net::DRI::Exception->die(0,'protocol/EPP',11,'Registrant contact is mandatory in domain_create')
     unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{contact}) && UNIVERSAL::isa($rd->{contact},'Net::DRI::Data::ContactSet') 
           && $rd->{contact}->get('registrant')->srid());

 return unless exists($rd->{nsgroup});
 my @n=add_nsgroup($rd->{nsgroup});

 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:create',['dnsbe:domain',@n]]);
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
 push @n,['dnsbe:add',add_nsgroup($nsgadd)] if $nsgadd;
 push @n,['dnsbe:rem',add_nsgroup($nsgdel)] if $nsgdel;

 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:update',['dnsbe:domain',@n]]);
}

## This is not written in the PDF document, but it should probably be there, like for .EU
sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $infdata=$mes->get_content('infData',$mes->ns('dnsbe'),1);
 return unless $infdata;

 my @c;
 foreach my $el ($infdata->getElementsByTagNameNS($mes->ns('dnsbe'),'nsgroup'))
 {
  push @c,Net::DRI::Data::Hosts->new()->name($el->getFirstChild()->getData());
 }

 $rinfo->{domain}->{$oname}->{nsgroup}=\@c;
}

sub delete
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists($rd->{deleteDate}) && $rd->{deleteDate});

 Net::DRI::Util::check_isa($rd->{deleteDate},'DateTime');

 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 my @n=('dnsbe:delete',['dnsbe:domain',['dnsbe:deleteDate',$rd->{deleteDate}->set_time_zone('UTC')->strftime("%Y-%m-%dT%T.%NZ")]]);
 $mes->command_extension($eid,\@n);
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:transfer',['dnsbe:domain',@n]]);
}

sub add_transfer
{
 my ($epp,$mes,$domain,$rd)=@_;

 Net::DRI::Exception::usererr_insufficient_parameters('registrant and billing are mandatory') unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{contact}) && UNIVERSAL::isa($rd->{contact},'Net::DRI::Data::ContactSet') && $rd->{contact}->has_type('registrant') && $rd->{contact}->has_type('billing'));

 my $cs=$rd->{contact};
 my @n;

 my $creg=$cs->get('registrant');
 Net::DRI::Exception::usererr_invalid_parameters('registrant must be a contact object or #AUTO#') unless (UNIVERSAL::isa($creg,'Net::DRI::Data::Contact') || (!ref($creg) && ($creg eq '#AUTO#')));
 push @n,['dnsbe:registrant',ref($creg)? $creg->srid() : '#AUTO#' ];

 if (exists($rd->{trDate}))
 {
  Net::DRI::Util::check_isa($rd->{trDate},'DateTime');
  push @n,['dnsbe:trDate',$rd->{trDate}->set_time_zone('UTC')->strftime("%Y-%m-%dT%T.%NZ")];
 }

 my $cbill=$cs->get('billing');
 Net::DRI::Exception::usererr_invalid_parameters('billing must be a contact object') unless UNIVERSAL::isa($cbill,'Net::DRI::Data::Contact');
 push @n,['dnsbe:billing',$cbill->srid()];

 push @n,add_contact('accmgr',$cs,1) if $cs->has_type('accmgr');
 push @n,add_contact('tech',$cs,9) if $cs->has_type('tech');
 push @n,add_contact('onsite',$cs,5) if $cs->has_type('onsite');

 if (exists($rd->{ns}) && (UNIVERSAL::isa($rd->{ns},'Net::DRI::Data::Hosts')) && !$rd->{ns}->is_empty())
 {
  my $n=Net::DRI::Protocol::EPP::Core::Domain::build_ns($epp,$rd->{ns},$domain,'dnsbe');
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
 return map { ['dnsbe:nsgroup',$_] } grep {defined} @a[0..8];
}

sub add_contact
{
 my ($type,$cs,$max)=@_;
 $max--;
 my @r=grep { UNIVERSAL::isa($_,'Net::DRI::Data::Contact') } ($cs->get($type));
 return map { ['dnsbe:'.$type,$_->srid()] } grep {defined} @r[0..$max];
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
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:transferq',['dnsbe:domain',@n]]);
}

sub trade
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'trade',$domain);
 $mes->command_body(\@d);

 my @n=add_transfer($epp,$mes,$domain,$rd);
 my $eid=build_command_extension($mes,$epp,'dnsbe:ext');
 $mes->command_extension($eid,['dnsbe:trade',['dnsbe:domain',@n]]);
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
