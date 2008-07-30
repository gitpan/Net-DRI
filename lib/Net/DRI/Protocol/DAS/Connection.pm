## Domain Registry Interface, DAS Connection handling
##
## Copyright (c) 2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::DAS::Connection;

use strict;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::DAS::Connection - DAS Connection handling for Net::DRI

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

Copyright (c) 2007,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub read_data
{
 my ($class,$to,$sock)=@_;

 my @a;
 while(my $l=$sock->getline())
 {
  chomp($l);
  push @a,$l;
  last if $l=~m/^Status: /;
 }

 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED','Unable to read answer (connection closed by registry ?)','en')) unless $a[-1]=~m/^Status: /;
 return Net::DRI::Data::Raw->new_from_array(\@a);
}

sub write_message
{
 my ($class,$to,$msg)=@_;
 return $msg->as_string();
}

####################################################################################################
1;
