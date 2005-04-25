## Domain Registry Interface, RRP Message
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

package Net::DRI::Protocol::RRP::Message;

use strict;

use Net::DRI::Exception;

use base qw(Class::Accessor::Chained::Fast Net::DRI::Protocol::Message);
__PACKAGE__->mk_accessors(qw(version errcode errmsg command entityname));

our $VERSION=do { my @r=(q$Revision: 1.6 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::RRP::Message - RRP Message for Net::DRI

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


our $EOL="\r\n"; ## as mandated by RFC 2832

our %CODES; ## defined at bottom

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;

 my $self={errcode => 0};
 bless($self,$class);

 my $rh=shift;
 if (defined($rh) && (ref($rh) eq 'HASH'))
 {
  $self->command($rh->{command})       if exists($rh->{command});
  $self->options($rh->{options})       if exists($rh->{options});
  $self->entityname($rh->{entityname}) if exists($rh->{entityname});
  if (exists($rh->{entities}))
  {
   while(my ($k,$v)=each(%{$rh->{entities}})) { $self->entities($k,$v); };
  }
 }
 return $self;
}

sub is_success { return (shift->errcode()=~m/^2/)? 1 : 0; }

sub result_status
{
 my $self=shift;
 return Net::DRI::Protocol::ResultStatus->new('rrp',$self->errcode(),\%CODES,$self->is_success(),$self->errmsg());
}

sub as_string
{
 my $self=shift;
 my @r;
 push @r,$self->command();
 my $en=$self->entityname();
 push @r,"EntityName:${en}" if ($en); ## test mandatory for quit/session/describe commands (without entityname)

 ## Entities
 foreach my $k ($self->entities())
 {
  push @r,map { "${k}:${_}" } ($self->entities($k));
 }

 ## Options
 while(my ($k,$v)=each(%{$self->options()}))
 {
  push @r,"-${k}:${v}";
 }

 push @r,"."; ## end
 return join($EOL,@r).$EOL;
}

sub parse
{
 my ($self,$dc)=@_; ## DataRaw
 my @todo=map { s/\r*\n*\r*$//; $_; } grep { defined() && ! /^\s+$/ } $dc->as_array();
 Net::DRI::Exception->die(0,'protocol/RRP',1,"Unsuccessfull parse (last line not '.')") unless (pop(@todo) eq '.');

 my $t=shift(@todo);
 $t=~m/^(\d+)\s+(\S.*\S)\s*$/;
 $self->errcode($1);
 $self->errmsg($2);

 foreach my $l (@todo)
 {
  my ($lh,$rh)=split(/:/,$l,2);
  if ($lh=~m/^-(.+)$/) ## option
  {
   $self->options($1,$rh);
  } else ## entity
  {
   $self->entities($lh,$rh);
  }
 }
}

sub entities
{
 my ($self,$k,$v)=@_;
 if (defined($k))
 {
  if (defined($v)) ## key + value => add
  {
   $self->{entities}={} unless exists($self->{entities});
   my @v=(ref($v) eq 'ARRAY')? @$v : ($v);
   if (exists($self->{entities}->{$k}))
   {
    push @{$self->{entities}->{$k}},@v;
   } else
   {
    $self->{entities}->{$k}=\@v;
   }
   return;
  } else ## only key given => get value of key
  {
   return undef unless (exists($self->{entities}));
   $k=lc($k);
   foreach my $i (keys(%{$self->{entities}})) { next unless (lc($i) eq $k); $k=$i; last; };
   return undef unless (exists($self->{entities}->{$k}));
   return wantarray()? @{$self->{entities}->{$k}} : join(" ",@{$self->{entities}->{$k}});
  }
 } else ## nothing given => get list of keys
 {
  return () unless exists($self->{entities});
  my @k=keys(%{$self->{entities}});
  return ('DomainName',grep { $_ ne 'DomainName' } @k) if exists($self->{entities}->{DomainName});
  return ('NameServer',grep { $_ ne 'NameServer' } @k) if exists($self->{entities}->{NameServer});
  return @k;
 }
}

sub options
{
 my ($self,$rh1,$v)=@_;
 if (defined($rh1)) ## something to add
 {
  $self->{options}={} unless exists($self->{options});
  if (ref($rh1) eq 'HASH')
  {
   $self->{options}={ %{$self->{options}}, %$rh1 };
  } else
  {
   $self->{options}->{$rh1}=$v;
  }
 }
 return exists($self->{options})? $self->{options} : {};
}

########################################################################

sub get_name_from_message
{
 my ($self)=@_;
 my $ename=$self->entityname();

 return uc($self->entities('DomainName')) if ($ename eq 'Domain');
 return uc($self->entities('NameServer')) if ($ename eq 'NameServer');
}

#############################################################################################


%CODES=( 'rrp' =>
          {
           200 => 1000, # Command completed successfully
           210 => 2303, # Domain name available => Object does not exist
           211 => 2302, # Domain name not available => Object exists
           212 => 2303, # Name server available => Object does not exist
           213 => 2302, # Name server not available => Object exists
           220 => 1500, # Command completed successfully. Server closing connection
           420 => 2500, # Command failed due to server error. Server closing connection
           421 => 2400, # Command failed due to server error. Client should try again
           500 => 2000, # Invalid command name => Unknown command
           501 => 2102, # Invalid command option => Unimplemented option
           502 => 2005, # Invalid entity value => Parameter value syntax error
           503 => 2005, # Invalid attribute name => Parameter value syntax error
           504 => 2003, # Missing required attribute => Required parameter missing
           505 => 2005, # Invalid attribute value syntax => Parameter value syntax error
           506 => 2004, # Invalid option value => Parameter value range error
           507 => 2001, # Invalid command format => Command syntax error
           508 => 2003, # Missing required entity => Required parameter missing
           509 => 2003, # Missing command option => Required parameter missing
           510 => 2306, # Invalid encoding => Parameter value policy error (RRP v2.0)
           520 => 2500, # Server closing connection. Client should try opening new connection => Command failed; server closing connection
           521 => 2502, # Too many sessions open. Server closing connection => Session limit exceeded; server closing connection
           530 => 2200, # Authentication failed => Authentication error
           531 => 2201, # Authorization failed => Authorization error
           532 => 2305, # Domain names linked with name server => Object association prohibits operation
           533 => 2305, # Domain name has active name servers => Object association prohibits operation
           534 => 2301, # Domain name has not been flagged for transfer => Object not pending transfer
           535 => 2306, # Restricted IP address => Parameter value policy error
           536 => 2300, # Domain already flagged for transfer => Object pending transfer
           540 => 2308, # Attribute value is not unique => Data management policy violation
           541 => 2005, # Invalid attribute value => Parameter value syntax error
           542 => 2306, # Invalid old value for an attribute => Parameter value policy error
           543 => 2308, # Final or implicit attribute cannot be updated => Data management policy violation
           544 => 2304, # Entity on hold => Object status prohibits operation
           545 => 2308, # Entity reference not found => Data management policy violation
           546 => 2104, # Credit limit exceeded => Billing failure
           547 => 2002, # Invalid command sequence => Command use error
           548 => 2105, # Domain is not up for renewal => Object is not eligible for renewal
           549 => 2400, # Command failed
           550 => 2308, # Parent domain not registered => Data management policy violation
           551 => 2308, # Parent domain status does not allow for operation => Data management policy violation
           552 => 2304, # Domain status does not allow for operation => Object status prohibits operation
           553 => 2300, # Operation not allowed. Domain pending transfer => Object pending transfer
           554 => 2302, # Domain already registered => Object exists
           555 => 2105, # Domain already renewed => Object is not eligible for renewal
           556 => 2308, # Maximum registration period exceeded => Data management policy violation
           557 => 2304, # Name server locked => Object status prohibits operation (RRP v2.0)
          },
       );

########################################################################
1;
