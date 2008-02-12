## Domain Registry Interface, OVH Web Services Connection handling
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

package Net::DRI::Protocol::OVH::WS::Connection;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::OVH::WS::Connection - OVH Web Services Connection handling for Net::DRI

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

sub login
{
 shift if ($_[0] eq __PACKAGE__);
 my ($cm,$id,$pass,$cltrid)=@_;
 my $mes=$cm->();
 $mes->method('login');
 $mes->params({nic => $id,password => $pass});
 return $mes;
}

sub parse_login
{
 shift if ($_[0] eq __PACKAGE__);
 my $mes=shift;
 $mes->errmsg($mes->is_success()? 'Login OK' : 'Login failed') unless $mes->errmsg();
 return $mes->result_status();
}

sub extract_session
{
 shift if ($_[0] eq __PACKAGE__);
 my $mes=shift;
 return { id => $mes->result() };
}

####################################################################################################

sub logout
{
 shift if ($_[0] eq __PACKAGE__);
 my ($cm,$cltrid,$sd)=@_;
 my $mes=$cm->();
 $mes->method('logout');
 $mes->params({session => $sd->{id}});
 return $mes;
}

sub parse_logout
{
 shift if ($_[0] eq __PACKAGE__);
 my $mes=shift;
 $mes->errmsg($mes->is_success()? 'Logout OK' : 'Logout failed') unless $mes->errmsg();
 return $mes->result_status();
}

####################################################################################################
1;
