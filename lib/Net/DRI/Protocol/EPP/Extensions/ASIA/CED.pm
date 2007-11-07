## Domain Registry Interface, ASIA CED extension
##
## Copyright (c) 2006 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ASIA::CED;

use strict;

our $VERSION=do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ASIA::CED - .ASIA EPP CED extensions

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bdsprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
 my %domtmp=(
           create =>		[ \&dom_create, undef ],
	   info =>		[ undef, \&dom_parse ]
         );
 my %contacttmp=(
	   create =>		[ \&user_create, undef ],
	   update =>		[ \&user_update, undef ],
	   info =>		[ undef, \&user_info ]
	 );

 return { 'domain' => \%domtmp, 'contact' => \%contacttmp };
}

####################################################################################################

############ Transform commands

sub dom_create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $cs = $rd->{contact};
 my @ceddata;

 if (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{url}))
 {
  push(@ceddata, ['asia:maintainerUrl', $rd->{ced}->{url}])
	if (exists($rd->{ced}->{url}));
 }

 if (defined($cs))
 {
  foreach my $type ($cs->types())
  {
	# Skip standard types and registration agent
	next if (grep { $_ eq $type } qw(registrant admin tech billing regAgent));

	foreach my $c ($cs->get($type))
	{
		push(@ceddata, ['asia:contact', {type => $type}, $c->srid()]);
	}
  }
 }

 if (@ceddata)
 {
  my $eid=$mes->command_extension_register('asia:create','xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"');
  $mes->command_extension($eid,[@ceddata]);
 }
}

sub dom_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $ceddata=$mes->get_content('infData', 'urn:afilias:params:xml:ns:asia-1.0', 1);
 my $cs = $rinfo->{$otype}->{$oname}->{contact};
 my $ct;
 my $c;

 return unless ($ceddata);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'mantainerUrl');
 $rinfo->{$otype}->{$oname}->{url} = $c->shift()->getFirstChild()->getData()
	if ($c);

 foreach my $ct ($ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0', 'contact'))
 {
  my $contact = $po->create_local_object('contact');
  my $type = $ct->getAttribute('type');
  my $srid = $ct->getFirstChild()->getData();

  $contact->srid($srid);
  $cs->add($contact, $type);
 }
}

sub user_create
{
 my ($epp,$contact,$rd)=@_;
 my $mes=$epp->message();
 my @ceddata;

 return unless (UNIVERSAL::isa($contact, 'Net::DRI::Data::Contact::ASIA'));

 push(@ceddata, ['asia:ccLocality', $contact->cedcc()])
	if (UNIVERSAL::can($contact, 'cedcc') && defined($contact->cedcc()) && length($contact->cedcc()));
 push(@ceddata, ['asia:localitySp', $contact->cedsp()])
	if (UNIVERSAL::can($contact, 'cedsp') && defined($contact->cedsp()) && length($contact->cedsp()));
 push(@ceddata, ['asia:localityCity', $contact->cedcity()])
	if (UNIVERSAL::can($contact, 'cedcity') && defined($contact->cedcity()) && length($contact->cedcity()));
 push(@ceddata, ['asia:legalEntityType', $contact->cedetype()])
	if (UNIVERSAL::can($contact, 'cedetype') && defined($contact->cedetype()) && length($contact->cedetype()));
 push(@ceddata, ['asia:identForm', $contact->cediform()])
	if (UNIVERSAL::can($contact, 'cediform') && defined($contact->cediform()) && length($contact->cediform()));
 push(@ceddata, ['asia:identNumber', $contact->cedinum()])
	if (UNIVERSAL::can($contact, 'cedinum') && defined($contact->cedinum()) && length($contact->cedinum()));
 push(@ceddata, ['asia:otherLEType', $contact->cedothertype()])
	if (UNIVERSAL::can($contact, 'cedothertype') && defined($contact->cedothertype()) && length($contact->cedothertype()));
 push(@ceddata, ['asia:otherIdentForm', $contact->cedoiform()])
	if (UNIVERSAL::can($contact, 'cedoiform') && defined($contact->cedoiform()) && length($contact->cedoiform()));

 return unless (@ceddata);

 my $eid=$mes->command_extension_register('asia:create',
	'xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" ' .
	'xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"');
 $mes->command_extension($eid,['asia:cedData', @ceddata]);
}

sub user_update
{
 my ($epp,$contact,$todo)=@_;
 my $mes=$epp->message();
 my $newc=$todo->set('info');
 my @ceddata;

 push(@ceddata, ['asia:ccLocality', $contact->cedcc()])
	if (UNIVERSAL::can($contact, 'cedcc') && defined($contact->cedcc()));
 push(@ceddata, ['asia:localitySp', $contact->cedsp()])
	if (UNIVERSAL::can($contact, 'cedsp') && defined($contact->cedsp()));
 push(@ceddata, ['asia:localityCity', $contact->cedcity()])
	if (UNIVERSAL::can($contact, 'cedcity') &&
		defined($contact->cedcity()));
 push(@ceddata, ['asia:legalEntityType', $contact->cedetype()])
	if (UNIVERSAL::can($contact, 'cedetype') &&
		defined($contact->cedetype()));
 push(@ceddata, ['asia:identForm', $contact->cediform()])
	if (UNIVERSAL::can($contact, 'cediform') &&
		defined($contact->cediform()));
 push(@ceddata, ['asia:identNumber', $contact->cedinum()])
	if (UNIVERSAL::can($contact, 'cedinum') &&
		defined($contact->cedinum()));
 push(@ceddata, ['asia:otherLEType', $contact->cedothertype()])
	if (UNIVERSAL::can($contact, 'cedothertype') &&
		defined($contact->cedothertype()));
 push(@ceddata, ['asia:otherIdentForm', $contact->cedoiform()])
	if (UNIVERSAL::can($contact, 'cedoiform') &&
		defined($contact->cedoiform()));

 return unless (@ceddata);

 my $eid=$mes->command_extension_register('asia:update',
	'xmlns:asia="urn:afilias:params:xml:ns:asia-1.0" ' .
	'xsi:schemaLocation="urn:afilias:params:xml:ns:asia-1.0 asia-1.0.xsd"');
 $mes->command_extension($eid,['asia:chg', ['asia:cedData', @ceddata]]);
}

sub user_info
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_content('infData', 'urn:afilias:params:xml:ns:asia-1.0', 1);
 my $ceddata;
 my $contact = $rinfo->{$otype}->{$oname}->{self};
 my $c;

 $ceddata = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0', 'cedData')->shift()
	if (defined($infdata));
 return unless ($ceddata);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'ccLocality');
 $contact->cedcc($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'localitySp');
 $contact->cedsp($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'localityCity');
 $contact->cedcity($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'legalEntityType');
 $contact->cedetype($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'identForm');
 $contact->cediform($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'identNumber');
 $contact->cedinum($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'otherLEType');
 $contact->cedothertype($c->shift()->getFirstChild()->getData()) if ($c);

 $c = $ceddata->getElementsByTagNameNS('urn:afilias:params:xml:ns:asia-1.0',
	'otherIdentForm');
 $contact->cedoiform($c->shift()->getFirstChild()->getData()) if ($c);
}

####################################################################################################
1;
