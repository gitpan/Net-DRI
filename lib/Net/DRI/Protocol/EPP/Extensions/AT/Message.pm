## Domain Registry Interface, nic.at domain transactions extension
## Contributed by Michael Braunoeder from NIC.AT <mib@nic.at>
##
## Copyright (c) 2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::AT::Message;

use strict;

use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

our $NS='http://www.nic.at/xsd/at-ext-message-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::AT::Message - NIC.AT Message EPP Mapping for Net::DRI

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

Copyright (c) 2006,2007 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;

 my %tmp=(
           atretrieve => [ \&pollreq, \&parse_poll ],
           atdelete   => [ \&pollack, undef ],
         );

 return { 'message' => \%tmp };
}

sub pollack
{
 my ($epp,$msgid)=@_;
 my $mes=$epp->message();
 $mes->command([['poll',{op=>'ack',msgID=>$msgid}]]);
}

sub pollreq
{
 my ($epp,$msgid)=@_;
 Net::DRI::Exception::usererr_invalid_parameters('In EPP, you can not specify the message id you want to retrieve') if defined($msgid);
 my $mes=$epp->message();
 $mes->command([['poll',{op=>'req'}]]);
}


## We take into account all parse functions, to be able to parse any result
sub parse_poll
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();

 return unless $mes->is_success();
 return if ($mes->{errcode} eq "1300");   # no messages in queue


 my $msgid=$mes->msg_id();
 $rinfo->{message}->{session}->{last_id}=$msgid;

 my $mesdata=$mes->get_content('message',$NS,0);
 $rinfo->{domain}->{$oname}->{message}=$mesdata;
 return unless $mesdata;
}

####################################################################################################
1;
