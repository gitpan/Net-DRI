## Domain Registry Interface, RRP Connection handling
##
## Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::RRP::Connection;

use strict;
use Net::DRI::Protocol::RRP::Message;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Connection - RRP Connection handling for Net::DRI

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

Copyright (c) 2005 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut


###############################################################################


sub login
{
 shift if ($_[0] eq __PACKAGE__);
 my ($id,$pass)=@_;
 my $mes=Net::DRI::Protocol::RRP::Message->new({ command => 'session', options => { Id => $id, Password => $pass}});
 return $mes->as_string();
}

sub logout
{
 my $mes=Net::DRI::Protocol::RRP::Message->new({ command => 'quit' });
 return $mes->as_string();
}

sub keepalive
{
 my $mes=Net::DRI::Protocol::RRP::Message->new({ command => 'describe' });
 return $mes->as_string();
}

########################################################################

sub is_login_successfull
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift; ## a DataRaw object
 my $code=find_code($dc);
 return (defined($code) && ($code==200));
}

sub is_end_command
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift; ## a DataRaw object
 my $ll=(ref($dc) eq 'ARRAY')? $dc->[-1] : $dc->last_line();
 return ($ll=~m/^\.\s*\n?$/)? 1 : 0;
}

sub is_server_close
{
 shift if ($_[0] eq __PACKAGE__);
 my $dc=shift; ## a DataRaw object
 my $code=find_code($dc);

 ## 220 : after a successfull QUIT
 ## 420 : Command failed due to server error. Server closing connection
 ## 520 : Server closing connection. Client should try opening new connection (timeout)
 ## 521 : Too many sessions open. Server closing connection
 return (defined($code) && ($code=~m/^([245]20|521)$/));
}

sub find_code
{
 my $dc=shift; ## a DataRaw object
 my @a=(ref($dc) eq 'ARRAY')? @$dc : $dc->as_array();
 return 0 if ($a[0]=~m/^.+ RRP Server version/); ## initial login
 return undef unless $#a>0; ## at least 2 lines
 return undef unless $a[-1]=~m/^\.\s*\n?$/;
 return undef unless $a[0]=~m/^(\d+) \S/;
 return 0+$1;
}

###################################################################################################################:
1;
