## Domain Registry Interface, EURid Sunrise EPP extension for Net::DRI
## (from registration_guidelines_v1_0E-appendix2-sunrise.pdf )
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

package Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Protocol::EPP::Extensions::EURid::Domain;
use Net::DRI::DRD::EURid;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise - EURid Sunrise EPP extension for Net::DRI

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

###################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           apply  => [ \&apply, \&apply_parse ],
#           info   => [ \&info, \&info_parse ], ## p.12, to be specified by EURid
         );

 return { 'domain' => \%tmp };
}


####################################################################################################

########### Query commands

############ Transform commands

sub apply
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=Net::DRI::Protocol::EPP::Core::Domain::build_command($mes,'apply',$domain);

 Net::DRI::Exception::usererr_insufficient_parameters('Apply action needs parameters') unless (defined($rd) && (ref($rd) eq 'HASH'));
 my @need=grep { !(exists($rd->{$_}) && $rd->{$_}) } qw/reference right prior-right-on-name prior-right-country documentaryevidence evidence-lang/;
 Net::DRI::Exception::usererr_insufficient_parameters('The following parameters are needed: '.join(' ',@need)) if @need;

 Net::DRI::Exception::usererr_invalid_parameters('Reference must be a normalizedstring from 1 to 100 characters long') unless Net::DRI::Util::xml_is_normalizedstring($rd->{reference},1,100);
 push @d,['domain:reference',$rd->{reference}];

 Net::DRI::Exception::usererr_invalid_parameters('Right must be PUBLICBODY, REG-TM-NAT, REG-TM-COM-INTL, GEO-DOO, COMP-ID, UNREG-TM, TITLES-ART, OTHER') unless ($rd->{right}=~m/^(?:PUBLICBODY|REG-TM-NAT|REG-TM-COM-INTL|GEO-DOO|COMP-ID|UNREG-TM|TITLES-ART|OTHER)/);
 push @d,['domain:right',$rd->{right}];

 Net::DRI::Exception::usererr_invalid_parameters('Prior-right-on-name must be a token from 1 to 255 characters long') unless Net::DRI::Util::xml_is_token($rd->{'prior-right-on-name'},1,255);
 push @d,['domain:prior-right-on-name',$rd->{'prior-right-on-name'}];

 Net::DRI::Exception::usererr_invalid_parameters('Prior-right-country must be a CC of EU member') unless (length($rd->{'prior-right-country'})==2 && exists($Net::DRI::DRD::EURid::CCA2_EU{uc($rd->{'prior-right-country'})})); ####
 push @d,['domain:prior-right-country',uc($rd->{'prior-right-country'})];

 Net::DRI::Exception::usererr_invalid_parameters('Documentaryevidence must be applicant, registrar or thirdparty') unless $rd->{documentaryevidence}=~m/^(?:applicant|registrar|thirdparty)$/;
 push @d,['domain:documentaryevidence',['domain:'.$rd->{documentaryevidence}]]; #### email when thirdparty

 Net::DRI::Exception::usererr_invalid_parameters('Evidence-lang must be a lang of EU member') unless (length($rd->{'evidence-lang'})==2 && exists($Net::DRI::DRD::EURid::LANGA2_EU{lc($rd->{'evidence-lang'})})); ####
 push @d,['domain:evidence-lang',lc($rd->{'evidence-lang'})];


 ## Nameservers, OPTIONAL
 push @d,Net::DRI::Protocol::EPP::Core::Domain::build_ns($epp,$rd->{ns},$domain,'domain') if (exists($rd->{ns}) && UNIVERSAL::isa($rd->{ns},'Net::DRI::Data::Hosts'));

 ## Contacts, all OPTIONAL
 if (exists($rd->{contact}) && UNIVERSAL::isa($rd->{contact},'Net::DRI::Data::ContactSet'))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o);
  push @d,Net::DRI::Protocol::EPP::Core::Domain::build_contact_noregistrant($cs);
 }

 $mes->command_body(\@d);

 if (exists($rd->{nsgroup}))
 {
  my @n=Net::DRI::Protocol::EPP::EURid::Extensions::Domain::add_nsgroup($rd->{nsgroup});
  my $eid=Net::DRI::Protocol::EPP::EURid::Extensions::Domain::build_command_extension($mes,$epp,'eurid:ext');
  $mes->command_extension($eid,['eurid:apply',['eurid:domain',@n]]);
 }
}

sub apply_parse
{
 return Net::DRI::Protocol::EPP::Core::Domain::create_parse(@_);
}

####################################################################################################
1;
