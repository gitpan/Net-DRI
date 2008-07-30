## Domain Registry Interface, OpenSRS XCP Protocol
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

package Net::DRI::Protocol::OpenSRS::XCP;

use strict;

use base qw(Net::DRI::Protocol);

use Net::DRI::Protocol::OpenSRS::XCP::Message;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::OpenSRS::XCP - OpenSRS XCP Protocol for Net::DRI

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
 my ($c,$drd)=@_;

 my $self=$c->SUPER::new();
 $self->name('opensrs_xcp');
 $self->version('3.0'); ## Specification March 17, 2008
 $self->factories('message',sub { my $m=Net::DRI::Protocol::OpenSRS::XCP::Message->new(); return $m; });
 $self->_load();
 return $self;
}

sub _load
{
 my ($self,$extrah)=@_;
 my @class=map { 'Net::DRI::Protocol::OpenSRS::XCP::'.$_ } (qw/Account Domain Session/);
 $self->SUPER::_load(@class);
}

####################################################################################################
1;
