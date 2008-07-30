## Domain Registry Interface, EPP Registry messages commands (RFC4930)
##
## Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::RegistryMessage;

use strict;

use Net::DRI::Exception;
use Net::DRI::Util;

our $VERSION=do { my @r=(q$Revision: 1.10 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::RegistryMessage - EPP Registry messages commands (RFC4930 obsoleting RFC3730) for Net::DRI

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

Copyright (c) 2006,2007,2008 Patrick Mevzek <netdri@dotandco.com>.
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

## We take into account all parse functions, to be able to parse any result
sub parse_poll
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $msgid=$mes->msg_id();
 return unless (defined($msgid) && $msgid);
 $rinfo->{message}->{session}->{last_id}=$msgid; ## needed here and not lower below, in case of pure text registry message

 ## Was there really a registry message with some content ?
 return unless ($mes->result_code() == 1301 && (defined($mes->node_resdata()) || defined($mes->node_extension()) || defined($mes->node_msg())));

 my $rd=$rinfo->{message}->{$msgid}; ## already partially filled by Message::parse()
 my ($totype,$toaction,$toname); ## $toaction will remain undef, but could be $haction if only one
 my %info;
 my $h=$po->commands();

 while (my ($htype,$hv)=each(%$h))
 {
  while (my ($haction,$hv2)=each(%$hv))
  {
   next if (($htype eq 'message') && ($haction eq 'retrieve')); ## calling myself here would be a very bad idea !
   foreach my $t (@$hv2)
   {
    my $pf=$t->[1];
    next unless (defined($pf) && (ref($pf) eq 'CODE'));
    $pf->($po,$totype,$toaction,$toname,\%info);
    next unless keys(%info);
    next if defined($toname);
    Net::DRI::Exception::err_assert('EPP::parse_poll can not handle multiple types !') unless (keys(%info)==1);
    $totype=(keys(%info))[0];
    Net::DRI::Exception::err_assert('EPP::parse_poll can not handle multiple names !') unless (keys(%{$info{$totype}})==1); ## this may happen for check_multi !
    $toname=(keys(%{$info{$totype}}))[0];
    $info{$totype}->{$toname}->{name}=$toname;
   }
  }
 }
 Net::DRI::Exception::err_assert('EPP::parse_poll was not able to parse anything, please report !') unless $toname;

 ## Copy local %info into $rd (which is in fact global info as set above) someway (we're working with references)
 ## Here, $rd=$rinfo->{message}->{$msgid}
 $rd->{object_type}=$totype;
 $rd->{object_id}=$toname; ## this has to be taken broadly, it is in fact a name for domains and hosts
 while(my ($k,$v)=each(%{$info{$totype}->{$toname}}))
 {
  $rd->{$k}=$v;
 }
 ## Also update data about the queried object, for easier access
 while(my ($k,$v)=each(%$rd))
 {
  $rinfo->{$totype}->{$toname}->{$k}=$v;
 }
}

####################################################################################################
1;
