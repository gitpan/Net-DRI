## Domain Registry Interface, DAS Message
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

package Net::DRI::Protocol::DAS::Message;

use strict;

use Encode ();

use Net::DRI::Protocol::ResultStatus;
use Net::DRI::Exception;
use Net::DRI::Util;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version errcode errmsg errlang command command_param command_tld cltrid response));

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::DAS::Message - DAS Message for Net::DRI

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
 my $proto=shift;
 my $class=ref($proto) || $proto;
 my $trid=shift;

 my $self={
           errcode => -1000,
	   response => {},
          };

 bless($self,$class);
 $self->cltrid($trid) if (defined($trid) && $trid);
 return $self;
}

sub is_success { return (shift->errcode()==0)? 1 : 0; }

sub result_status
{
 my $self=shift;
 ## From http://www.dns.be/en/home.php?n=317
 ## See also http://www.dns.be/en/home.php?n=44
 my %C=( 0 => 1500, ## Command successful + connection closed
        -9 => 2201, ## IP address blocked => Authorization error
        -8 => 2400, ## Timeout => Command failed
        -7 => 2005, ## Invalid pattern => Parameter value syntax error
        -6 => 2005, ## Invalid version => Parameter value syntax error
       );
 my $c=$self->errcode();
 my $rs=Net::DRI::Protocol::ResultStatus->new('das',$c,exists($C{$c})? $C{$c} : $Net::DRI::Protocol::ResultStatus::EPP_CODES{GENERIC_ERROR},$self->is_success(),$self->errmsg(),$self->errlang(),undef);
 $rs->_set_trid([ $self->cltrid(),undef ]);
 return $rs;
}

sub as_string
{
 my ($self,$to)=@_;
 my $s=sprintf("%s %s %s\x0d\x0a",$self->command(),$self->version(),$self->command_param());
 return Encode::encode('ascii',$s);
}

sub parse
{
 my ($self,$dc,$rinfo)=@_;
 my @d=$dc->as_array();
 my @tmp=grep { /^%% RC = \S+/ } @d;
 Net::DRI::Exception->die(0,'protocol/DAS',1,'Unsuccessfull parse, no RC in server reply') unless (@tmp==1);
 my ($rc)=($tmp[0]=~m/^%% RC = (\S+)\s*$/);
 $self->errcode($rc);

 if ($rc==0) ## success
 {
  my %info=map { m/^(\S+):\s+(.*\S)\s*$/; $1 => $2 } grep { /^\S+: / } @d;
  Net::DRI::Exception->die(0,'protocol/DAS',1,'Unsuccessfull parse, missing key Domain') unless (exists($info{Domain}));
  Net::DRI::Exception->die(0,'protocol/DAS',1,'Unsuccessfull parse, missing key Status') unless (exists($info{Status}));
  $self->response(\%info);
 } else
 {
  $self->errlang('en'); ## really ?
  my ($msg)=($d[-1]=~m/^%\s*(\S.+\S)\s*$/);
  $self->errmsg($msg);
 }
}

sub get_name_from_message
{
 my ($self)=@_;
 return lc($self->command_param().'.'.$self->command_tld());
}

########################################################################
1;
