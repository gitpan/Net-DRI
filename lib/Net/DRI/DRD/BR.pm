## Domain Registry Interface, .BR policies
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

package Net::DRI::DRD::BR;

use strict;
use base qw/Net::DRI::DRD/;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::BR - .BR policies for Net::DRI

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

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=1;
 $self->{info}->{contact_i18n}=2; ## INT only ?

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'RegistroBR'; }
## See http://registro.br/info/dpn.html
sub tlds     { return ('br',map { $_.'.br' } qw/com agr am art edu coop esp far fm g12 gov imb ind inf jus mil net org psi rec srv tmp tur tv etc adm adv arq ato bio bmd cim cng cnt ecn eng eti fnd fot fst ggf jor lel mat med mus not ntr odo ppg pro psc qql slg trd vet zlg blog flog nom vlog sec3 wiki/ ); }
sub object_types { return ('domain','contact'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::BR',$ta,$pa) if ($type eq 'epp');
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,[1,2]);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);

 return 0;
}

sub domain_operation_needs_is_mine
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 return unless defined($op);

 return 1 if ($op=~m/^(?:renew|update|delete)$/);
 return 0 if ($op eq 'transfer');
 return;
}

####################################################################################################
1;
