## Domain Registry Interface, ASIA IPR extension
##
## Copyright (c) 2007 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::ASIA::IPR;

use strict;

use DateTime;

our $VERSION=do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::ASIA::IPR - .ASIA EPP IPR extensions

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
 my %tmp=(
           create =>		[ \&create, undef ],
	   info =>		[ undef, \&parse ]
         );

 return { 'domain' => \%tmp };
}

####################################################################################################

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();

 if (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{ipr}))
 {
  my @iprdata;
  push(@iprdata, ['ipr:name', $rd->{ipr}->{name}])
	if (exists($rd->{ipr}->{name}));
  push(@iprdata, ['ipr:ccLocality', $rd->{ipr}->{cc}])
	if (exists($rd->{ipr}->{cc}));
  push(@iprdata, ['ipr:number', $rd->{ipr}->{number}])
	if (exists($rd->{ipr}->{number}));
  push(@iprdata, ['ipr:appDate', $rd->{ipr}->{appDate}->ymd()])
	if (exists($rd->{ipr}->{appDate}) &&
	ref($rd->{ipr}->{appDate}) eq 'DateTime');
  push(@iprdata, ['ipr:regDate', $rd->{ipr}->{regDate}->ymd()])
	if (exists($rd->{ipr}->{regDate}) &&
	ref($rd->{ipr}->{regDate}) eq 'DateTime');
  push(@iprdata, ['ipr:class', int($rd->{ipr}->{class})])
	if (exists($rd->{ipr}->{class}));
  push(@iprdata, ['ipr:entitlement', $rd->{ipr}->{entitlement}])
	if (exists($rd->{ipr}->{entitlement}));
  push(@iprdata, ['ipr:form', $rd->{ipr}->{form}])
	if (exists($rd->{ipr}->{form}));
  push(@iprdata, ['ipr:type', $rd->{ipr}->{type}])
	if (exists($rd->{ipr}->{type}));
  push(@iprdata, ['ipr:preVerified', $rd->{ipr}->{preVerified}])
	if (exists($rd->{ipr}->{preVerified}));
  push(@iprdata, ['ipr:phase', $rd->{ipr}->{phase}])
	if (exists($rd->{ipr}->{phase}));

  my $eid=$mes->command_extension_register('ipr:create','xmlns:ipr="urn:afilias:params:xml:ns:ipr-1.0" xsi:schemaLocation="urn:afilias:params:xml:ns:ipr-1.0 ipr-1.0.xsd"');
  $mes->command_extension($eid,[@iprdata]);
 }
}

sub parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 my $infdata=$mes->get_content('infData', 'urn:afilias:params:xml:ns:ipr-1.0', 1);
 my $ipr = {};
 my $c;

 return unless ($infdata);

 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'name');
 $ipr->{name} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'ccLocality');
 $ipr->{cc} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'number');
 $ipr->{number} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'appDate');
 $ipr->{appDate} = DateTime->from_epoch(epoch => str2time($c->shift()->getFirstChild()->getData())) if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'regDate');
 $ipr->{regDate} = DateTime->from_epoch(epoch => str2time($c->shift()->getFirstChild()->getData())) if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'class');
 $ipr->{class} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'entitlement');
 $ipr->{entitlement} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'form');
 $ipr->{form} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'preVerified');
 $ipr->{preVerified} = $c->shift()->getFirstChild()->getData() if ($c);
 $c = $infdata->getElementsByTagNameNS('urn:afilias:params:xml:ns:ipr-1.0', 'phase');
 $ipr->{phase} = $c->shift()->getFirstChild()->getData() if ($c);
 $rinfo->{$otype}->{$oname}->{ipr} = $ipr;
}

####################################################################################################
1;
