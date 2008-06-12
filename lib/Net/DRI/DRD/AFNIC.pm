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
#########################################################################################

package Net::DRI::DRD::AFNIC;

use strict;
use base qw/Net::DRI::DRD/;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::DRD::AFNIC - AFNIC .FR/.RE Registry driver for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head2 CURRENT LIMITATIONS

Only domain_check (through AFNIC web services) and domain_create are currently provided.

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


#####################################################################################

sub name         { return 'AFNIC'; }
sub tlds         { return ('fr','re'); }
sub object_types { return ('domain'); }

sub transport_protocol_compatible 
{
 my ($self,$to,$po)=@_;
 my $pn=$po->name();
 my $pv=$po->version();
 my $tn=$to->name();

 return 1 if (($pn eq 'afnic_ws')    && ($tn eq 'soap'));
 return 1 if (($pn eq 'afnic_email') && ($tn eq 'smtp'));
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
 }
}


######################################################################################

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

######################################################################################
1;
