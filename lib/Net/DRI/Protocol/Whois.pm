## Domain Registry Interface, Whois Protocol
##
## Copyright (c) 2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::Whois;

use strict;

use base qw(Net::DRI::Protocol);

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::Whois::Message;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Whois - Whois Protocol for Net::DRI

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

Copyright (c) 2007 Patrick Mevzek <netdri@dotandco.com>.
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
 my $h=shift;
 my $c=ref($h) || $h;

 my ($drd,$version,$extrah)=@_;

 my $self=$c->SUPER::new(); ## we are now officially a Net::DRI::Protocol object
 $self->name('Whois');
 $version=Net::DRI::Util::check_equal($version,['1.0'],'1.0');
 $self->version($version);

 bless($self,$c); ## rebless

 my @tlds=$drd->tlds();
 Net::DRI::Exception::usererr_invalid_parameters('Whois can not be used for registry handling multiple TLDs: '.join(',',@tlds)) unless (@tlds==1 || lc($tlds[0]) eq 'com');
 $self->factories({ message => sub { return Net::DRI::Protocol::Whois::Message->new(@_)->version($version); } });
 $self->_load(uc($tlds[0]),$extrah);
 return $self;
}

sub _load
{
 my ($self,$tld,$extrah)=@_;
 $self->SUPER::_load('Net::DRI::Protocol::Whois::Domain::'.$tld);
}

############################################################################################
1;
