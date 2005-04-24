## Domain Registry Interface, Encapsulating result status, standardized on EPP codes
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

package Net::DRI::Protocol::ResultStatus;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf("%d"."%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::ResultStatus - store details of an operation results

=head1 DESCRIPTION

You have the following methods available:

=over

=item *

C<is_success()> returns 1 if the operation was a success

=item *

C<code()> returns the EPP code corresponding to the native code (registry dependent)
  for this operation (see RFC for full list or source of this file)

=item *

C<native_code()> gives the true status code we got back from registry

=item *

C<message()> gives the message attached to the the status code we got back from registry

=item *

C<object_exist()> and C<object_available()> is an abstraction over specific EPP code for
  object existence or availability at registry

=back

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

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

sub new
{
 my ($class,$type,$code,$rcodes,$is_success,$message)=@_;
 my %s=(
        is_success  => defined($is_success)? $is_success : 0,
        native_code => $code,
        message     => $message || '',
        type        => $type, ## rrp/epp/afnic/etc...
       );

 $s{code}=_standardize_code($type,$code,$rcodes,$is_success);
 bless(\%s,$class);
 return \%s;
}

sub is_success  { return shift->{is_success}; }
sub native_code { return shift->{native_code}; }
sub code        { return shift->{code}; }
sub message     { return shift->{message}; }

sub object_exist 
{ 
 my $code=shift->code();
 return 1 if ($code==2302);
 return 0 if ($code==2303);
 return undef;
}

sub object_available
{
 my $e=shift->object_exist();
 return undef unless defined($e);
 return 1-$e;
}

## Local codes (not used in EPP): 19XX for ok, 29XX for errors
## Thus: EPP/2900 : Undefined error
##       EPP/1900 : Undefined success
sub _standardize_code
{
 my ($type,$code,$rcodes,$is_success)=@_;
 return 2900 unless defined($type) && $type && defined($code); ## $code can be 0 maybe
 $type=lc($type);
 return $code if ($type eq 'epp'); ## we standardize on EPP codes
 return 2900 unless (defined($rcodes) && (ref($rcodes) eq 'HASH') && exists($rcodes->{$type}));
 return $rcodes->{$type}->{$code} if exists($rcodes->{$type}->{$code});
 return (defined($is_success) && $is_success)? 1900 : 2900;
}

###################################################################################################################
1;
