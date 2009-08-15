## Domain Registry Interface, Infrastructure ENUM.AT policy on reserved names
## Contributed by Michael Braunoeder from ENUM.AT <michael.braunoeder@enum.at>
##
## Copyright (c) 2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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
use warnings;

use base qw/Net::DRI::DRD/;

use Net::DRI::Util;
use DateTime::Duration;

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

## The domain renew command are not implemented at the ienum43 EPP server, domains are renewed automatically
__PACKAGE__->make_exception_for_unavailable_operations(qw/domain_renew/);

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

Copyright (c) 2006,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
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

sub periods  { return map { DateTime::Duration->new(years => $_) } (1); }
sub name     { return 'IENUMAT'; }
sub tlds     { return ('i.3.4.e164.arpa'); }
sub object_types { return ('domain'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::IENUMAT',{}) if $type eq 'epp';
 return;
}

####################################################################################################
## TODO : this should be converted to the new framework !
sub verify_name_domain
{
 my ($self,$ndr,$domain)=@_;
 $domain=$ndr unless (defined($ndr) && $ndr && (ref($ndr) eq 'Net::DRI::Registry'));



 my @splited = split /\./,$domain;
 my $count = @splited;
 $count--;
 my $r=$self->SUPER::check_name($domain,$count);
 return $r if ($r);
 return 10 unless $self->is_my_tld($ndr,$domain,0);

 my @d=split(/\./,$domain);

 return 14 if exists($Net::DRI::Util::CCA2{uc($d[0])});

 return 0;
}

####################################################################################################
1;
