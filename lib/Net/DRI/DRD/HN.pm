## Domain Registry Interface, Afilias ccTLD policies for .HN
##
## Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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

package Net::DRI::DRD::HN;

use strict;
use base qw/Net::DRI::DRD/;

use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::HN - .HN policies for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
 $self->{info}->{host_as_attr}=0;

 bless($self,$class);
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Afilias HN'; }
sub tlds     { return qw/hn com.hn net.hn org.hn edu.hn/; }
sub object_types { return ('domain','contact','ns'); }

sub transport_protocol_compatible
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'EPP') && ($tn eq 'socket_inet'));
 return;
}

sub transport_protocol_default
{
 my ($drd,$ndr,$type,$ta,$pa)=@_;
 $type='epp' if (!defined($type) || ref($type));
 return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::Afilias',$ta,$pa) if ($type eq 'epp');
}

####################################################################################################
## http://www.afilias-grs.info/public/policies/hn
## http://www.nic.hn/politicas/sobre_dominios.html
sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

 my $r=$self->SUPER::check_name($domain,[1,2]); ## one or two dots
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);
 
 my @d=split(/\./,$domain);
 return 12 if length($d[0]) < 3; ## http://www.nic.hn/politicas/sobre_dominios.html �1.c

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
