## Domain Registry Interface, EPP Connection handling for .PL
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

package Net::DRI::Protocol::EPP::Extensions::PL::Connection;

use strict;
use base qw/Net::DRI::Protocol::EPP::Connection/;

use Encode ();
use HTTP::Request ();

use Net::DRI::Exception;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PL::Connection - .PL EPP over HTTPS connection handling for Net::DRI

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

sub init
{
 my ($class,$to)=@_;
 my $t=$to->transport_data();

 foreach my $p (qw/client_login client_password remote_url/)
 {
  Net::DRI::Exception::usererr_insufficient_parameters($p.' must be defined') unless (exists($t->{$p}) && $t->{$p});
 }
}

sub greeting
{
 my ($class,$to,$cm)=@_;
 return $class->keepalive($to,$cm); ## will send an <hello/> message, which is in fact a greeting !
}

####################################################################################################

sub read_data
{
 my ($class,$to,$res)=@_;
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED',sprintf('Got unsuccessfull HTTP response: %d %s',$res->code(),$res->message()),'en')) unless $res->is_success();
 return Net::DRI::Data::Raw->new_from_string($res->content());
}

sub write_message
{
 my ($class,$to,$msg)=@_;
 my $t=$to->transport_data();
 my $req=HTTP::Request->new('POST',$t->{remote_url});
 $req->header('Content-Type','text/xml');
 $req->content(Encode::encode('utf8',$msg->as_string()));
 ## Content-Length will be automatically computed during Transport by LWP::UserAgent
 return $req;
}

####################################################################################################
1;
