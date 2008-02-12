## Domain Registry Interface, Infrastructure ENUM.AT policy on reserved names
## Contributed by Michael Braunoeder from ENUM.AT <michael.braunoeder@enum.at>
##
## Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::DRD::IENUMAT;

use strict;
use base qw/Net::DRI::DRD/;

use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::IENUMAT - Infrastructure ENUM.AT policies for Net::DRI

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

Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>.
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
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;

 bless($self,$class);

 return $self;
}

sub is_my_tld
{
   my ($self,$domain)=@_;
   my ($tld) = uc($self->tlds());

   return 1 if (uc($domain) =~ /.*$tld$/);
   return 0;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'IENUMAT'; }
sub tlds     { return ('i.3.4.e164.arpa'); }
sub object_types { return ('domain'); }

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
 return Net::DRI::DRD::_transport_protocol_default_epp('Net::DRI::Protocol::EPP::Extensions::IENUMAT',$ta,$pa) if ($type eq 'epp');
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));



 my @splited = split /\./,$domain;
 my $count = @splited;
 $count--;
 my $r=$self->SUPER::check_name($domain,$count);
 return $r if ($r);
 return 10 unless $self->is_my_tld($domain);

 my @d=split(/\./,$domain);

 return 11 if exists($Net::DRI::Util::CCA2{uc($d[0])});

 return 0;
}

sub domain_operation_needs_is_mine
{
    my ($self,$ndr,$domain,$op)=@_;
    ($domain,$op)=($ndr,$domain) unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));

    return unless defined($op);

    return 1 if ($op=~m/^(?:update|delete)$/);
    return 0 if ($op eq 'transfer');
    return; #renew not implemented
}


## The domain renew command are not implemented at the ienum43 EPP server, domains are renewed automatically
sub domain_renew        { Net::DRI::Exception->die(0,'DRD',4,'No domain renew available in IENUM.AT'); }

####################################################################################################
1;
