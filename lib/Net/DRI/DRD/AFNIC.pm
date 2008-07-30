## Domain Registry Interface, AFNIC Registry Driver for .FR/.RE
##
## Copyright (c) 2005,2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

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

Copyright (c) 2005,2006,2008 Patrick Mevzek <netdri@dotandco.com>.
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
 if ($type eq 'email')
 {
  my %ta=(ref($ta) eq 'ARRAY')? %{$ta->[0]} : %$ta;
  my @pa=(ref($pa) eq 'ARRAY' && @$pa)? @$pa : ();
  return ('Net::DRI::Transport::SMTP',[\%ta],'Net::DRI::Protocol::AFNIC::Email',\@pa);
 } elsif ($type eq 'epp')
 {
  carp('AFNIC EPP support is currently being developed, use it only for tests');
  return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::AFNIC',$ta,$pa);
 }
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,1);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 return 0;
}

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return;
}

sub host_update { Net::DRI::Exception->die(0,'DRD',4,'No host update available for AFNIC'); }
sub host_current_status { Net::DRI::Exception->die(0,'DRD',4,'No host status update available for AFNIC'); }
sub host_check { Net::DRI::Exception->die(0,'DRD',4,'No host check available for AFNIC'); }
sub host_check_multi { Net::DRI::Exception->die(0,'DRD',4,'No host check available for AFNIC'); }
sub host_exist { Net::DRI::Exception->die(0,'DRD',4,'No host check available for AFNIC'); }
sub host_delete { Net::DRI::Exception->die(0,'DRD',4,'No host delete available for AFNIC'); }
sub host_create { Net::DRI::Exception->die(0,'DRD',4,'No host creation possible for AFNIC'); }
sub host_info { Net::DRI::Exception->die(0,'DRD',4,'No host info possible for AFNIC'); }
sub contact_delete { Net::DRI::Exception->die(0,'DRD',4,'No contact delete possible for AFNIC'); }

sub domain_create_only
{
 my ($self,$ndr,$domain,$rd)=@_;
 return $self->SUPER::domain_create_only($ndr,$domain,$rd) unless $ndr->protocol()->name() eq 'EPP';
 my $ns;
 if (defined($rd) && (ref($rd) eq 'HASH'))
 {
  $ns=$rd->{ns};
  delete($rd->{ns});
 }
 my $rc=$self->SUPER::domain_create_only($ndr,$domain,$rd); ## create the domain without any nameserver
 return $rc unless $rc->is_success();
 return $rc unless (defined($ns) && Net::DRI::Util::isa_hosts($ns));
 return $self->domain_update_ns_set($ndr,$domain,$ns); ## Finally update domain to add nameservers
}

sub domain_trade_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'trade');
 return $ndr->process('domain','trade_request',[$domain,$rd]);
}

sub domain_trade_query
{
 my ($self,$ndr,$domain)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'trade');
 return $ndr->process('domain','trade_query',[$domain]);
}

sub domain_recover_start
{
 my ($self,$ndr,$domain,$rd)=@_;
 $self->err_invalid_domain_name($domain) if $self->verify_name_domain($domain,'recover');
 return $ndr->process('domain','recover_request',[$domain,$rd]);
}

## domain_check_multi : max 7 !

####################################################################################################
1;