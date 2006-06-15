## Domain Registry Interface, Main entry point
##
## Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI;

use Net::DRI::Cache;
use Net::DRI::Registry;
use Net::DRI::Util;

use strict;

our $AUTOLOAD;
our $VERSION='0.30';
our $CVS_REVISION=do { my @r=(q$Revision: 1.23 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI - Interface to Domain Name Registries/Registrars/Resellers

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

Copyright (c) 2005,2006 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

#########################################################################################
#########################################################################################

sub new
{
 my $proto=shift;
 my $class=ref($proto) || $proto;
 my ($cachettl,$globaltimeout)=@_;
 $cachettl=0 unless defined($cachettl);

 my $self={ cache            => Net::DRI::Cache->new($cachettl),
            global_timeout   => $globaltimeout,
            current_registry => undef, ## registry name (key of next hash)
            registries       => {}, ## registry name => Net::DRI::Registry object
            tlds             => {}, ## tld => [ registries name ]
            time_created     => time(),
            trid_factory     => \&Net::DRI::Util::create_trid_1,
          };

 bless($self,$class); 
 return $self;
}

sub add_registry
{
 my $self=shift;

 my $reg=shift;
 $reg='Net::DRI::DRD::'.$reg unless ($reg=~m/::/);

 eval "require $reg";
 Net::DRI::Exception->die(1,'DRI',8,"Failed to load Perl module $reg ($@)") if $@;

 my $drd=$reg->new(@_);
 Net::DRI::Exception->die(1,'DRI',9,"Failed to initialize registry $reg") unless ($drd && ref($drd));

 Net::DRI::Exception::err_method_not_implemented("name() in $reg") unless $drd->can('name');
 my $regname=$drd->name();
 Net::DRI::Exception->die(1,'DRI',10,"No dot allowed in registry name: $regname") unless (index($regname,'.')==-1);
 Net::DRI::Exception->die(1,'DRI',11,"New registry name already in use") if (exists($self->{registries}->{$regname}));

 my $ndr=Net::DRI::Registry->new($regname,$drd,$self->{cache},$self->{trid_factory});
 $self->{registries}->{$regname}=$ndr;

 Net::DRI::Exception::err_method_not_implemented("tlds() in $reg") unless $drd->can('tlds');
 foreach my $tld ($drd->tlds())
 {
  $tld=lc($tld);
  $self->{tlds}->{$tld}=[] unless exists($self->{tlds}->{$tld});
  push @{$self->{tlds}->{$tld}},$regname
 }

 return $self;
}

###########################################################################################################

sub err_no_current_registry          { Net::DRI::Exception->die(0,'DRI',1,"No current registry available"); }
sub err_registry_name_does_not_exist { Net::DRI::Exception->die(0,'DRI',2,"Registry name $_[0] does not exist"); }
sub err_no_current_profile           { Net::DRI::Exception->die(0,'DRI',3,"No current profile available"); }
sub err_profile_name_does_not_exist  { Net::DRI::Exception->die(0,'DRI',4,"Profile name $_[0] does not exist"); }

###########################################################################################################
## Accessor functions

sub available_registries { return keys(%{shift->{registries}}); }
sub registry_name { return shift->{current_registry}; }

sub registry
{
 my ($self)=@_;
 my $regname=$self->registry_name();
 err_no_current_registry()                  unless (defined($regname) && $regname);
 err_registry_name_does_not_exist($regname) unless (exists($self->{registries}->{$regname}));
 my $ndr=$self->{registries}->{$regname};
 return wantarray()? ($regname,$ndr) : $ndr;
}

sub tld2reg
{
 my ($self,$tld)=@_;
 return unless defined($tld) && $tld;
 $tld=lc($tld);
 $tld=$1 if ($tld=~m/\.([a-z0-9]+)$/);
 return unless exists($self->{tlds}->{$tld});
 my @t=@{$self->{tlds}->{$tld}};
 return @t;
}

#########################################################################################################
sub target
{
 my ($self,$driver,$profile)=@_;

 ## Try to convert if given a domain name or a tld instead of a driver's name
 if (defined($driver) && !exists($self->{registries}->{$driver})) 
 {
  my @t=$self->tld2reg($driver);
  Net::DRI::Exception->die(0,'DRI',7,"Registry not found for domain name/TLD $driver") unless (@t==1);
  $driver=$t[0];
 }

 $driver=$self->registry_name() unless defined($driver);
 err_registry_name_does_not_exist($driver) unless defined($driver) && $driver;
 
 if (defined($profile))
 {
  $self->{registries}->{$driver}->target($profile);
 }

 $self->{current_registry}=$driver;
 return $self;
}

####################################################################################################
## The meat of everything
## See Cookbook, page 468
sub AUTOLOAD
{
 my $self=shift;
 my $attr=$AUTOLOAD;
 $attr=~s/.*:://;
 return unless $attr=~m/[^A-Z]/; ## skip DESTROY and all-cap methods

 my $ndr=$self->registry(); ## This is a Net::DRI::Registry object
 Net::DRI::Exception::err_method_not_implemented("$attr in $ndr") unless (ref($ndr) && $ndr->can($attr));
 return $ndr->$attr(@_); ## is goto beter here ?
}

sub end
{
 my $self=shift;

 foreach my $v (values(%{$self->{registries}}))
 {
  $v->end() if (ref($v) && $v->can('end'));
  $v={};
 }
 $self->{tlds}={};
 $self->{registries}={};
 $self->{current_registry}=undef;
}

sub DESTROY { shift->end(); }

####################################################################################################
1;
