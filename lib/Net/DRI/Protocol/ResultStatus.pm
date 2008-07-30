## Domain Registry Interface, Encapsulating result status, standardized on EPP codes
##
## Copyright (c) 2005,2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::ResultStatus;

use strict;

use base qw(Class::Accessor::Chained::Fast);
__PACKAGE__->mk_ro_accessors(qw(is_success native_code code message lang next));

our $VERSION=do { my @r=(q$Revision: 1.19 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::ResultStatus - Encapsulate details of an operation result with standardization on EPP for Net::DRI

=head1 DESCRIPTION

An object of this class represents all details of an operation result as given back from the registry,
with standardization on EPP as much as possible, for error codes and list of fields available.

=head1 METHODS

=head2 is_success()

returns 1 if the operation was a success

=head2 code()

returns the EPP code corresponding to the native code (registry dependent)
for this operation (see RFC for full list or source of this file)

=head2 native_code()

gives the true status code we got back from registry

=head2 message()

gives the message attached to the the status code we got back from registry

=head2 lang()

gives the language in which the message above is written

=head2 info()

gives back an array with additionnal data from registry, especially in case of errors. If no data, an empty array is returned

=head2 as_string(EXTRA)

returns a string with all details (with the info part if EXTRA is defined and true)

=head2 print()

same as CORE::print($rs->as_string(0))

=head2 print_full()

same as CORE::print($rs->as_string(1))

=head2 trid()

in scalar context, gives the transaction id (our transaction id, that is the client part in EPP) which has generated this result,
in array context, gives the transaction id followed by other ids given by registry (example in EPP : server transaction id)

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

http://www.dotandco.com/services/software/Net-DRI/

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

## We give symbolic names only to codes that are used in some modules
our %EPP_CODES=(
                COMMAND_SUCCESSFUL => 1000,
		COMMAND_SUCCESSFUL_PENDING => 1001, ## needed for async registries when action done correctly on our side
                COMMAND_SUCCESSFUL_END => 1500, ## after logout

                COMMAND_SYNTAX_ERROR => 2001,
                AUTHENTICATION_ERROR => 2200,
                AUTHORIZATION_ERROR => 2201,
                OBJECT_EXISTS   => 2302,
                OBJECT_DOES_NOT_EXIST => 2303,
                COMMAND_FAILED => 2400, ## Internal server error not related to the protocol

                GENERIC_SUCCESS => 1900, ## these codes are not defined in EPP RFCs, but provide a nice extension
                GENERIC_ERROR   => 2900, ##     19XX for ok (1900=Undefined success), 29XX for errors (2900=Undefined error)
               );

sub new
{
 my ($class,$type,$code,$eppcode,$is_success,$message,$lang,$info)=@_;
 my %s=(
        is_success  => (defined($is_success) && $is_success)? 1 : 0,
        native_code => $code,
        message     => $message || '',
        type        => $type, ## rrp/epp/afnic/etc...
        lang        => $lang || '?',
	'next'	=> undef,
       );

 $s{code}=_eppcode($type,$code,$eppcode,$s{is_success});
 $s{info}=(defined($info))? $info : [];
 bless(\%s,$class);
 return \%s;
}

sub trid
{
 my $self=shift;
 return unless (exists($self->{trid}) && (ref($self->{trid}) eq 'ARRAY'));
 return wantarray()? @{$self->{trid}} : $self->{trid}->[0];
}

sub _set_trid { my ($self,$v)=@_; $self->{'trid'}=$v; }
sub _set_next { my ($self,$v)=@_; $self->{'next'}=$v; }
sub _eppcode
{
 my ($type,$code,$eppcode,$is_success)=@_;
 return $EPP_CODES{GENERIC_ERROR} unless defined($type) && $type && defined($code);
 $eppcode=$code if (!defined($eppcode) && ($type eq 'epp'));
 return $is_success? $EPP_CODES{GENERIC_SUCCESS} : $EPP_CODES{GENERIC_ERROR} unless defined($eppcode);
 return $eppcode if ($eppcode=~m/^\d{4}$/);
 return $EPP_CODES{$eppcode} if exists($EPP_CODES{$eppcode});
 return $EPP_CODES{GENERIC_ERROR};
}

sub new_generic_success { my ($class,$msg,$lang)=@_; return $class->new('epp',$EPP_CODES{GENERIC_SUCCESS},undef,1,$msg,$lang); }
sub new_generic_error   { my ($class,$msg,$lang)=@_; return $class->new('epp',$EPP_CODES{GENERIC_ERROR},undef,0,$msg,$lang); }
sub new_success         { my ($class,$code,$msg,$lang)=@_; return $class->new('epp',$code,undef,1,$msg,$lang); }
sub new_error           { my ($class,$code,$msg,$lang)=@_; return $class->new('epp',$code,undef,0,$msg,$lang); }

sub info
{
 my $self=shift;
 return (defined($self->{info}) && (ref($self->{info}) eq 'ARRAY'))? @{$self->{info}} : ();
}

sub as_string
{
 my ($self,$withinfo)=@_;
 my $b=sprintf('%s (%s/%s) %s',$self->message(),$self->code(),$self->native_code(),$self->is_success()? 'SUCCESS' : 'ERROR' );
 if (defined($withinfo) && $withinfo)
 {
  my @i=$self->info();
  $b.="\n".join("\n",@i) if @i;
 }
 return $b;
}

sub print { print shift->as_string(0); }
sub print_full { print shift->as_string(1); }

sub is_pending
{
 my $self=shift;
 return ($self->code()==$EPP_CODES{COMMAND_SUCCESSFUL_PENDING});
}

####################################################################################################
1;
