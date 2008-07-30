## Domain Registry Interface, RRI Connection handling
##
## Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::RRI::Connection;

use strict;

use Encode ();

use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRI::Connection - RRI Connection handling (DENIC-11) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>tonnerre.lombard@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007,2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
 my ($class, $to, $cm, $id, $pass, $cltrid, $dr, $newpass, $pdata) = @_;

 my $mes=$cm->();
 $mes->command(['login']);
 my @d;
 push @d,['user',$id];
 push @d,['password',$pass];
 $mes->command_body(\@d);
 return $class->write_message($to,$mes);
}

sub logout
{
 my ($class,$to,$cm,$cltrid)=@_;
 my $mes=$cm->();
 $mes->command(['logout']);
 $mes->cltrid($cltrid) if $cltrid;
 return $class->write_message($to,$mes);
}

sub keepalive
{
 my ($class,$to,$cm,$cltrid)=@_;
 my $mes=$cm->();
 $mes->command(['hello']);
 return $class->write_message($to,$mes);
}

####################################################################################################

sub read_data
{
 my ($class,$to,$sock)=@_;

 my $version = $to->{transport}->{protocol_version};
 my $m;
 my $c;
 $sock->read($c, 4); ## first 4 bytes are the packed length
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED',
	'Unable to read RRI 4 bytes length (connection closed by registry ?)',
	'en')) unless $c;
 my $length = unpack('N', $c);
 while ($length > 0)
 {
  my $new;
  $length-=$sock->read($new,$length);
  $m.=$new;
 }

 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',
	$m ? $m : '<empty message from server>', 'en'))
	unless ($m =~ m!</registry-response>$!);

 return Net::DRI::Data::Raw->new_from_string($m);
}

sub write_message
{
 my ($self,$to,$msg)=@_;

 my $m=Encode::encode('utf8',$msg->as_string());
 my $l = pack('N', length($m)); ## DENIC-11
 return $l.$m;
}

sub parse_login
{
 my ($class,$dc)=@_;
 my ($result,$code,$msg)=find_result($dc);
 unless (defined($result) && ($result eq 'success'))
 {
  return Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',
	(defined($msg) && length($msg) ? $msg : 'Login failed'), 'en');
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL',
	'Login OK', 'en');
 }
}

sub parse_logout
{
 my ($class,$dc)=@_;
 my ($result,$code,$msg)=find_result($dc);
 unless (defined($result) && ($result eq 'success'))
 {
  return Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',
        (defined($msg) && length($msg) ? $msg : 'Logout failed'), 'en');
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL',
	'Logout OK', 'en');
 }
}

sub find_result
{
 my $dc=shift;
 my $a=$dc->as_string();
 return () unless ($a=~m!</registry-response>!);
 $a=~s/>[\n\s\t]+/>/g;
 my ($result,$code,$msg);
 return () unless (($result)=($a=~m!<tr:result>(\w+)</tr:result>!));
 ($code) = ($a =~ m!<tr:message.*code="(\d+)">!);
 ($msg) = ($a =~ m!<tr:text>([^>]+)</tr:text>!);
 return ($result, $code, $msg);
}

####################################################################################################
1;
