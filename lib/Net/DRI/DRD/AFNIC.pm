## Domain Registry Interface, AFNIC Registry Driver for .FR/.RE
##
## Copyright (c) 2005,2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::AFNIC;

use strict;
use base qw/Net::DRI::DRD/;

use Carp;
use DateTime::Duration;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

__PACKAGE__->make_exception_for_unavailable_operations(qw/host_update host_current_status host_check host_check_multi host_exist host_delete host_create host_info contact_delete/);

=pod

=head1 NAME

Net::DRI::DRD::AFNIC - AFNIC (.FR/.RE) Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head2 CURRENT LIMITATIONS

Only domain_check (through AFNIC web services) and domain_create (by email) are currently provided.
All operations are available through EPP, but this protocol is not currently in production
at the registry.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=1; ## LOC only
 bless($self,$class);
 return $self;
}

sub periods      { return map { DateTime::Duration->new(years => $_) } (1); }
sub name         { return 'AFNIC'; }
sub tlds         { return (qw/fr re tf wf pm yt/); } ## see http://www.afnic.fr/doc/autres-nic/dom-tom
sub object_types { return ('domain','contact'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'afnic_ws')    && ($tn eq 'soap'));
 return 1 if (($pn eq 'afnic_email') && ($tn eq 'smtp'));
 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 my %ta=(ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta;
 my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ();
 if ($type eq 'email')
 {
  return ('Net::DRI::Transport::SMTP',[\%ta],'Net::DRI::Protocol::AFNIC::Email',\@pa);
 } elsif ($type eq 'ws')
 {
  return ('Net::DRI::Transport::SOAP',[\%ta],'Net::DRI::Protocol::AFNIC::WS',\@pa);
 } elsif ($type eq 'epp')
 {
  carp('AFNIC EPP support is currently being developed, use it only for tests');
  $ta{remote_host}='epp.preprod.nic.fr';
  return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::AFNIC',[\%ta],\@pa);
 }
}

####################################################################################################

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->SUPER::domain_operation_needs_is_mine($ndr,$domain,$op) if ($ndr->protocol()->name() eq 'EPP');
 return;
}

sub domain_create
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $self->SUPER::domain_create($ndr,$domain,$rd) unless ($ndr->protocol()->name() eq 'EPP');
 return $self->SUPER::domain_create($ndr,$domain,$rd) unless (Net::DRI::Util::has_key($rd,'pure_create') && $rd->{pure_create}==1);
 my $ns;
 if (defined($rd) && (ref($rd) eq 'HASH'))
 {
  $ns=$rd->{ns};
  delete($rd->{ns});
 }
 my $rc=$self->SUPER::domain_create($ndr,$domain,$rd); ## create the domain without any nameserver
 return $rc unless $rc->is_success();
 return $rc unless (defined($ns) && Net::DRI::Util::isa_hosts($ns));
 return $self->domain_update_ns_set($ndr,$domain,$ns); ## Finally update domain to add nameservers
}

sub domain_trade_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($ndr,$domain,'trade');
 return $ndr->process('domain','trade_request',[$domain,$rd]);
}

sub domain_trade_query
{
 my ($self,$ndr,$domain)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($ndr,$domain,'trade');
 return $ndr->process('domain','trade_query',[$domain]);
}

sub domain_recover_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($ndr,$domain,'recover');
 return $ndr->process('domain','recover_request',[$domain,$rd]);
}

## domain_check_multi : max 7 !

####################################################################################################
1;
