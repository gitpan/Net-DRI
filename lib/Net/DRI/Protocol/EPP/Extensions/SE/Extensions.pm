## Domain Registry Interface, .SE EPP Domain/Contact Extensions for Net::DRI
## Contributed by Elias Sidenbladh from NIC SE
##
## Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::SE::Extensions;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;

our $VERSION=do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };
our $NS='http://www.nic.se/xml/epp/ext-1.0';

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::SE::Extensions - .SE EPP Domain/Contact Extensions for Net::DRI

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

Copyright (c) 2006,2008 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

###################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my $domain={
	     info   => [ undef, \&domain_parse ],
	     create => [ \&domain_create, \&domain_parse ],
	     check  => [ \&domain_check, undef ],
	    };
 my $contact={
	      info   => [ undef, \&contact_parse ],
	      create => [ \&contact_create, undef ],
	     };

 return { 'domain' => $domain, 'contact' => $contact };
}

###################################################################################################

sub format_se
{
 my $e = shift;
 my $op = shift;
 my $obj = shift;

 my @c;
 if ($obj eq 'domain') {
     if (($op eq 'create' || $op eq 'check') && Net::DRI::Util::has_key($e,'book')) {
	 Net::DRI::Exception::usererr_invalid_parameters("Book can only be '1' or '0'") if ($e->{book}!~/^(0|1)$/);
	 push @c,['ext:book',$e->{book}];
     } else {
	 Net::DRI::Exception::usererr_invalid_parameters('This operation has no extensions');
     }
 } elsif ($obj eq 'contact') {
     if ($op eq 'create') {
	 Net::DRI::Exception::usererr_insufficient_parameters('Attribute orgno must exist') unless (Net::DRI::Util::isa_contact($e,'Net::DRI::Data::Contact::SE') && $e->orgno());
	 push @c,['ext:orgno',$e->{orgno}];
     } else {
	 Net::DRI::Exception::usererr_invalid_parameters('This operation has no extensions');
     }
 } else {
     Net::DRI::Exception::usererr_invalid_parameters('This operation has no extensions');
 }
 return @c;
}

##################################################################################################

########### Query commands

#
# parse domain info and create responses
#
sub domain_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $result=$mes->get_content('result',$NS,1);
 return unless $result;

 my @ds;
 foreach my $el ($result->getElementsByTagNameNS($NS,'msg')) {
     $rinfo->{domain}->{$oname}->{msg}=$el->firstChild->getData();
 }
}

#
# parse contact info responses
#
sub contact_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $result=$mes->get_content('infData',$NS,1);
 return unless $result;

 foreach my $el ($result->getElementsByTagNameNS($NS,'orgno')) {
     $rinfo->{contact}->{$oname}->{self}->orgno($el->firstChild->getData());
 }
}


############ Transform commands

#
# domain create command extension
#
sub domain_create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists $rd->{book});

 my $eid=$mes->command_extension_register('ext:create','xmlns:ext="'.$NS.'" xsi:schemaLocation="'.$NS.' ext-1.0.xsd"');
 my @n= format_se($rd,'create','domain');
 $mes->command_extension($eid,\@n);
}

#
# domain check command extension
#
sub domain_check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 return unless (exists $rd->{book});

 my $eid=$mes->command_extension_register('ext:check','xmlns:ext="'.$NS.'" xsi:schemaLocation="'.$NS.' ext-1.0.xsd"');
 my @n= format_se($rd,'check','domain');
 $mes->command_extension($eid,\@n);
}

#
# contact create command extension
#
sub contact_create
{
 my ($epp,$contact,$rd)=@_;
 my $mes=$epp->message();
 my $eid=$mes->command_extension_register('ext:create','xmlns:ext="'.$NS.'" xsi:schemaLocation="'.$NS.' ext-1.0.xsd"');
 my @n=format_se($contact,'create','contact');
 $mes->command_extension($eid,\@n);
}

####################################################################################################
1;
