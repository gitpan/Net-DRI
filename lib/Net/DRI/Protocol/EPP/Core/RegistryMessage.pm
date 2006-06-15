## Domain Registry Interface, EPP Registry messages commands (RFC3730)
##
## Copyright (c) 2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::RegistryMessage;

use strict;

use DateTime::Format::ISO8601;

use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::RegistryMessage - EPP Registry messages commands (RFC3730) for Net::DRI

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

Copyright (c) 2006 Patrick Mevzek <netdri@dotandco.com>.
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
           retrieve => [ \&pollreq, \&parse_poll ],
           delete   => [ \&pollack ],
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

sub parse_poll
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 ## For now we only parse (domain|host|contact):panData child of <resData> as it is the only thing present in RFC3731/3732/3733
 ## even if RFC3730 gives another example
 my $msgid=$mes->msg_id();

 my ($type,$n);
 $n=$mes->get_content('panData',$mes->ns('domain'));
 if ($n)
 {
  $type='domain';
 } else
 {
  $n=$mes->get_content('panData',$mes->ns('host'));
  if ($n)
  {
   $type='host';
  } else
  {
   $n=$mes->get_content('panData',$mes->ns('contact'));
   return unless $n;
   $type='contact';
  }
 }

 my $rd=$rinfo->{message}->{$msgid};
 $rd->{object_type}=$type;
 my $c=$n->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name=~m/^(?:name|id)$/) ## domain+host:name & contact:id
  {
   $rd->{object_id}=$c->getFirstChild()->getData(); ## for domain/host this will be their name
   $rd->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
  } elsif ($name eq 'paTRID')
  {
   $rd->{trid}=($c->getElementsByTagNameNS($mes->ns('_main'),'clTRID'))[0]->getFirstChild()->getData();
   $rd->{svtrid}=($c->getElementsByTagNameNS($mes->ns('_main'),'svTRID'))[0]->getFirstChild()->getData();
  } elsif ($name eq 'paDate')
  {
   $rd->{date}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  }
  $c=$c->getNextSibling();
 }

}

####################################################################################################
1;
