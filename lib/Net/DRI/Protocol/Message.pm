## Domain Registry Interface, Protocol messages (pure virtual superclass)
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

package Net::DRI::Protocol::Message;

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d"."%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::Message

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


sub new           { Net::DRI::Exception::err_method_not_implemented(); }
sub is_success    { Net::DRI::Exception::err_method_not_implemented(); }
sub result_status { Net::DRI::Exception::err_method_not_implemented(); }
sub parse         { Net::DRI::Exception::err_method_not_implemented(); }
sub as_string     { Net::DRI::Exception::err_method_not_implemented(); }
sub version       { Net::DRI::Exception::err_method_not_implemented(); }

1;
