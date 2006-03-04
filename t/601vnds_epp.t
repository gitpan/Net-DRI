#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 185;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend
{
 my ($transport,$count,$msg)=@_;
 $R1=$msg->as_string();
 return 1;
}

our $R2;
sub myrecv
{
 return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2);
}

my $dri=Net::DRI->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->new_current_profile('p1','Net::DRI::Transport::Dummy',[{f_send=>\&mysend,f_recv=>\&myrecv}],'Net::DRI::Protocol::EPP',[]);

my $rc;
my $s;
my $d;
my ($dh,@c);

## Domain commands
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example3.com</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('example3.com');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example3.com</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','example3.com'),0,'domain_check get_info(exist) from cache');


$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="1">example22.com</domain:name></domain:cd><domain:cd><domain:name avail="0">example2.net</domain:name><domain:reason>In use</domain:reason></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_multi('example22.com','example2.net');
is($R1,$E1.'<command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example22.com</domain:name><domain:name>example2.net</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check_multi build');
is($rc->is_success(),1,'domain_check_multi is_success');
is($dri->get_info('exist','domain','example22.com'),0,'domain_check_multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.net'),1,'domain_check_multi get_info(exist) 2/2');
is($dri->get_info('exist_reason','domain','example2.net'),'In use','domain_check_multi get_info(exist_reason)');


$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:status s="ok"/><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:host>ns1.example.com</domain:host><domain:host>ns2.example.com</domain:host><domain:clID>ClientX</domain:clID><domain:crID>ClientY</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>ClientX</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate><domain:trDate>2000-04-08T09:00:00.0Z</domain:trDate><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example2.com',{auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example2.com</domain:name><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'EXAMPLE1-REP','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['admin','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'jd1234','domain_info get_info(contact) registrant srid');
is($s->get('admin')->srid(),'sh8013','domain_info get_info(contact) admin srid');
is($s->get('tech')->srid(),'sh8013','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('host');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(host)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.com','ns2.example.com'],'domain_info get_info(host) get_names');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.com','ns1.example.net'],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');
is($dri->get_info('crID'),'ClientY','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'ClientX','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_info get_info(exDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','domain_info get_info(trDate)');
is("".$d,'2000-04-08T09:00:00','domain_info get_info(trDate) value');
is_deeply($dri->get_info('auth'),{pw=>'2fooBAR'},'domain_info get_info(auth)');


$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example200.com</domain:name><domain:roid>EXAMPLE1-REP</domain:roid><domain:clID>ClientX</domain:clID></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example200.com');
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name hosts="all">example200.com</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build without auth');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'EXAMPLE1-REP','domain_info get_info(roid)');
is($dri->get_info('clID'),'ClientX','domain_info get_info(clID)');


$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example201.com</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-06T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-11T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2; 
$rc=$dri->domain_transfer_query('example201.com',{auth=>{pw=>'2fooBAR',roid=>'JD1234-REP'}});
is($R1,$E1.'<command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example201.com</domain:name><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_query build');
is($dri->get_info('exist'),1,'domain_transfer_query get_info(exist)');
is($dri->get_info('trStatus'),'pending','domain_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_query get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(reDate)');
is("".$d,'2000-06-06T22:00:00','domain_transfer_query get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_query get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(acDate)');
is("".$d,'2000-06-11T22:00:00','domain_transfer_query get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_query get_info(exDate) value');


$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202.com</domain:name><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:exDate>2001-04-03T22:00:00.0Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
my $cs=$dri->local_object('contactset')->new();
my $c1=$dri->local_object('contact')->srid('jd1234');
my $c2=$dri->local_object('contact')->srid('sh8013');
$cs->set($c1,'registrant');
$cs->set($c2,'admin');
$cs->set($c2,'tech');
$rc=$dri->domain_create_only('example202.com',{duration=>DateTime::Duration->new(years=>2),ns=>$dri->local_object('hosts')->set(['ns1.example.com'],['ns1.example.net']),contact=>$cs,auth=>{pw=>'2fooBAR'}});
is($R1,$E1.'<command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example202.com</domain:name><domain:period unit="y">2</domain:period><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj><domain:hostObj>ns1.example.net</domain:hostObj></domain:ns><domain:registrant>jd1234</domain:registrant><domain:contact type="admin">sh8013</domain:contact><domain:contact type="tech">sh8013</domain:contact><domain:authInfo><domain:pw>2fooBAR</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_create_only build');
is($dri->get_info('exist'),1,'domain_create_only get_info(exist)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_create_only get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','domain_create_only get_info(crDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_create_only get_info(exDate)');
is("".$d,'2001-04-03T22:00:00','domain_create_only get_info(exDate) value');


$R2='';
$rc=$dri->domain_delete_only('example203.com');
is($R1,$E1.'<command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example203.com</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete_only build');
is($rc->is_success(),1,'domain_delete_only is_success');


$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example204.com</domain:name><domain:exDate>2005-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example204.com',DateTime::Duration->new(years=>5),DateTime->new(year=>2000,month=>4,day=>3));
is($R1,$E1.'<command><renew><domain:renew xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example204.com</domain:name><domain:curExpDate>2000-04-03</domain:curExpDate><domain:period unit="y">5</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is("".$d,'2005-04-03T22:00:00','domain_renew get_info(exDate) value');


$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example205.com</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>ClientX</domain:reID><domain:reDate>2000-06-08T22:00:00.0Z</domain:reDate><domain:acID>ClientY</domain:acID><domain:acDate>2000-06-13T22:00:00.0Z</domain:acDate><domain:exDate>2002-09-08T22:00:00.0Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
{
 no warnings;
 *Net::DRI::DRD::VNDS::verify_duration_transfer=sub { return 0; };
}
$rc=$dri->domain_transfer_start('example205.com',{auth=>{pw=>'2fooBAR',roid=>"JD1234-REP"},period=>DateTime::Duration->new(years=>1)});
is($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example205.com</domain:name><domain:period unit="y">1</domain:period><domain:authInfo><domain:pw roid="JD1234-REP">2fooBAR</domain:pw></domain:authInfo></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');
is($dri->get_info('exist'),1,'domain_transfer_start get_info(exist)');
is($dri->get_info('trStatus'),'pending','domain_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','domain_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(reDate)');
is("".$d,'2000-06-08T22:00:00','domain_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','domain_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(acDate)');
is("".$d,'2000-06-13T22:00:00','domain_transfer_start get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_start get_info(exDate)');
is("".$d,'2002-09-08T22:00:00','domain_transfer_start get_info(exDate) value');


$R2='';
$toc=$dri->local_object('changes')->new();
$toc->add('ns',$dri->local_object('hosts')->set('ns2.example.com'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('mak21'),'tech');
$toc->add('contact',$cs);
$toc->add('status',$dri->local_object('status')->no('publish','Payment overdue.'));
$toc->del('ns',$dri->local_object('hosts')->set('ns1.example.com'));
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('sh8013'),'tech');
$toc->del('contact',$cs);
$toc->del('status',$dri->local_object('status')->no('update'));
$toc->set('registrant',$dri->local_object('contact')->srid('sh8013'));
$toc->set('auth',{pw=>'2BARfoo'});
$rc=$dri->domain_update('example206.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example206.com</domain:name><domain:add><domain:ns><domain:hostObj>ns2.example.com</domain:hostObj></domain:ns><domain:contact type="tech">mak21</domain:contact><domain:status lang="en" s="clientHold">Payment overdue.</domain:status></domain:add><domain:rem><domain:ns><domain:hostObj>ns1.example.com</domain:hostObj></domain:ns><domain:contact type="tech">sh8013</domain:contact><domain:status s="clientUpdateProhibited"/></domain:rem><domain:chg><domain:registrant>sh8013</domain:registrant><domain:authInfo><domain:pw>2BARfoo</domain:pw></domain:authInfo></domain:chg></domain:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');
is($rc->is_success(),1,'domain_update is_success');

 
##################################################################################################################
## Host commands

$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="0">ns2.example2.com</host:name><host:reason>In use</host:reason></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check('ns2.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns2.example2.com</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check build');
is($dri->get_info('exist'),1,'host_check get_info(exist)');
is($dri->get_info('exist','host','ns2.example2.com'),1,'host_check get_info(exist) from cache');
is($dri->get_info('exist_reason'),'In use','host_check reason');


$R2=$E1.'<response>'.r().'<resData><host:chkData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:cd><host:name avail="1">ns10.example2.com</host:name></host:cd><host:cd><host:name avail="0">ns20.example2.com</host:name><host:reason>In use</host:reason></host:cd><host:cd><host:name avail="1">ns30.example2.com</host:name></host:cd></host:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_check_multi('ns10.example2.com','ns20.example2.com','ns30.example2.com');
is($R1,$E1.'<command><check><host:check xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns10.example2.com</host:name><host:name>ns20.example2.com</host:name><host:name>ns30.example2.com</host:name></host:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'host_check_multi build');
is($rc->is_success(),1,'host_check_multi is_success');
is($dri->get_info('exist','host','ns10.example2.com'),0,'host_check_multi get_info(exist) 1/3');
is($dri->get_info('exist','host','ns20.example2.com'),1,'host_check_multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','host',,'ns20.example2.com'),'In use','host_check_multi get_info(exist_reason)');
is($dri->get_info('exist','host','ns30.example2.com'),0,'host_check_multi get_info(exist) 3/3');


$R2=$E1.'<response>'.r().'<resData><host:infData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns100.example2.com</host:name><host:roid>NS1_EXAMPLE1-REP</host:roid><host:status s="linked"/><host:status s="clientUpdateProhibited"/><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr><host:clID>ClientY</host:clID><host:crID>ClientX</host:crID><host:crDate>1999-04-03T22:00:00.0Z</host:crDate><host:upID>ClientX</host:upID><host:upDate>1999-12-03T09:00:00.0Z</host:upDate><host:trDate>2000-04-08T09:00:00.0Z</host:trDate></host:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_info('ns100.example2.com');
is($R1,$E1.'<command><info><host:info xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns100.example2.com</host:name></host:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($dri->get_info('roid'),'NS1_EXAMPLE1-REP','host_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','host_info get_info(status)');
is_deeply([$s->list_status()],['clientUpdateProhibited','linked'],'host_info get_info(status) list');
is($s->is_linked(),1,'host_info get_info(status) is_linked');
is($s->can_update(),0,'host_info get_info(status) can_update');
$s=$dri->get_info('self');
isa_ok($s,'Net::DRI::Data::Hosts','host_info get_info(self)');
my ($name,$ip4,$ip6)=$s->get_details(1);
is($name,'ns100.example2.com','host_info self name');
is_deeply($ip4,['193.0.2.2','193.0.2.29'],'host_info self ip4');
is_deeply($ip6,['2000:0:0:0:8:800:200C:417A'],'host_info self ip6');
is($dri->get_info('clID'),'ClientY','host_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','host_info get_info(crID)');
is($dri->get_info('upID'),'ClientX','host_info get_info(upID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_info get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','host_info get_info(upDate)');
is($d.'','1999-12-03T09:00:00','host_info get_info(upDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','host_info get_info(trDate)');
is($d.'','2000-04-08T09:00:00','host_info get_info(trDate) value');


$R2=$E1.'<response>'.r().'<resData><host:creData xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:crDate>1999-04-03T22:00:00.0Z</host:crDate></host:creData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_create($dri->local_object('hosts')->add('ns101.example1.com',['193.0.2.2','193.0.2.29'],['2000:0:0:0:8:800:200C:417A']));
is($R1,$E1.'<command><create><host:create xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns101.example1.com</host:name><host:addr ip="v4">193.0.2.2</host:addr><host:addr ip="v4">193.0.2.29</host:addr><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'host_create build');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_create get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_create get_info(crDate) value');


$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
$rc=$dri->host_delete('ns102.example1.com');
is($R1,$E1.'<command><delete><host:delete xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns102.example1.com</host:name></host:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'host_delete build');
is($rc->is_success(),1,'host_delete is_success');


$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
my $toc=$dri->local_object('changes');
$toc->add('ip',$dri->local_object('hosts')->add('ns1.example1.com',['193.0.2.22'],[]));
$toc->add('status',$dri->local_object('status')->no('update'));
$toc->del('ip',$dri->local_object('hosts')->add('ns1.example1.com',[],['2000:0:0:0:8:800:200C:417A']));
$toc->set('name','ns104.example2.com');
$rc=$dri->host_update('ns103.example1.com',$toc);
is($R1,$E1.'<command><update><host:update xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"><host:name>ns103.example1.com</host:name><host:add><host:addr ip="v4">193.0.2.22</host:addr><host:status s="clientUpdateProhibited"/></host:add><host:rem><host:addr ip="v6">2000:0:0:0:8:800:200C:417A</host:addr></host:rem><host:chg><host:name>ns104.example2.com</host:name></host:chg></host:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

#########################################################################################################
## Contact commands

my $co;
$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">sh8000</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8000'); #->auth({pw=>'2fooBAR'});
$rc=$dri->contact_check($co);
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8000</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check build'); 
is($rc->is_success(),1,'contact_check is_success');
is($dri->get_info('exist'),0,'contact_check get_info(exist)');
is($dri->get_info('exist','contact','sh8000'),0,'contact_check get_info(exist) from cache');


$R2=$E1.'<response>'.r().'<resData><contact:chkData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:cd><contact:id avail="1">sh8001</contact:id></contact:cd><contact:cd><contact:id avail="0">sh8002</contact:id><contact:reason>In use</contact:reason></contact:cd><contact:cd><contact:id avail="1">sh8003</contact:id></contact:cd></contact:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_check_multi(map { $dri->local_object('contact')->srid($_) } ('sh8001','sh8002','sh8003'));
is($R1,$E1.'<command><check><contact:check xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8001</contact:id><contact:id>sh8002</contact:id><contact:id>sh8003</contact:id></contact:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_check_multi build');
is($rc->is_success(),1,'contact_check_multi is_success');
is($dri->get_info('exist','contact','sh8001'),0,'contact_check_multi get_info(exist) 1/3');
is($dri->get_info('exist','contact','sh8002'),1,'contact_check_multi get_info(exist) 2/3');
is($dri->get_info('exist_reason','contact','sh8002'),'In use','contact_check_multi get_info(exist_reason)');
is($dri->get_info('exist','contact','sh8003'),0,'contact_check_multi get_info(exist) 3/3');


$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:roid>SH8013-REP</contact:roid><contact:status s="linked"/><contact:status s="clientDeleteProhibited"/><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:clID>ClientY</contact:clID><contact:crID>ClientX</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>ClientX</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate><contact:trDate>2000-04-08T09:00:00.0Z</contact:trDate><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8013')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_info($co);
is($R1,$E1.'<command><info><contact:info xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'sh8013','contact_info get_info(self) srid');
is($co->roid(),'SH8013-REP','contact_info get_info(self) roid');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','contact_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited','linked'],'contact_info get_info(status) list_status');
is($s->can_delete(),0,'contact_info get_info(status) can_delete');
is($co->name(),'John Doe','contact_info get_info(self) name');
is($co->org(),'Example Inc.','contact_info get_info(self) org');
is_deeply($co->street(),['123 Example Dr.','Suite 100'],'contact_info get_info(self) street');
is($co->city(),'Dulles','contact_info get_info(self) city');
is($co->sp(),'VA','contact_info get_info(self) sp');
is($co->pc(),'20166-6503','contact_info get_info(self) pc');
is($co->cc(),'US','contact_info get_info(self) cc');
is($co->voice(),'+1.7035555555x1234','contact_info get_info(self) voice');
is($co->fax(),'+1.7035555556','contact_info get_info(self) fax');
is($co->email(),'jdoe@example.com','contact_info get_info(self) email');
is($dri->get_info('clID'),'ClientY','contact_info get_info(clID)');
is($dri->get_info('crID'),'ClientX','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is("".$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
is($dri->get_info('upID'),'ClientX','contact_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is("".$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');
$d=$dri->get_info('trDate');
isa_ok($d,'DateTime','contact_info get_info(trDate)');
is("".$d,'2000-04-08T09:00:00','contact_info get_info(trDate) value');
is_deeply($co->auth(),{pw=>'2fooBAR'},'contact_info get_info(self) auth');
is_deeply($co->disclose(),{voice=>0,email=>0},'contact_info get_info(self) disclose');


$R2=$E1.'<response>'.r().'<resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8013</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>ClientX</contact:reID><contact:reDate>2000-06-06T22:00:00.0Z</contact:reDate><contact:acID>ClientY</contact:acID><contact:acDate>2000-06-11T22:00:00.0Z</contact:acDate></contact:trnData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8014')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_transfer_query($co);
is($R1,$E1.'<command><transfer op="query"><contact:transfer xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8014</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_transfer_query build');
is($rc->is_success(),1,'contact_transfer_query is_success');
is($dri->get_info('trStatus'),'pending','contact_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','contact_transfer_query get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','contact_transfer_query get_info(reDate)');
is("".$d,'2000-06-06T22:00:00','contact_transfer_query get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','contact_transfer_query get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','contact_transfer_query get_info(acDate)');
is("".$d,'2000-06-11T22:00:00','contact_transfer_query get_info(acDate) value');


$R2=$E1.'<response>'.r().'<resData><contact:creData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8015</contact:id><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate></contact:creData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('sh8015');
$co->name('John Doe');
$co->org('Example Inc.');
$co->street(['123 Example Dr.','Suite 100']);
$co->city('Dulles');
$co->sp('VA');
$co->pc('20166-6503');
$co->cc('US');
$co->voice('+1.7035555555x1234');
$co->fax('+1.7035555556');
$co->email('jdoe@example.com');
$co->auth({pw=>'2fooBAR'});
$co->disclose({voice=>0,email=>0});
$rc=$dri->contact_create($co);
is($R1,$E1.'<command><create><contact:create xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8015</contact:id><contact:postalInfo type="loc"><contact:name>John Doe</contact:name><contact:org>Example Inc.</contact:org><contact:addr><contact:street>123 Example Dr.</contact:street><contact:street>Suite 100</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice x="1234">+1.7035555555</contact:voice><contact:fax>+1.7035555556</contact:fax><contact:email>jdoe@example.com</contact:email><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="0"><contact:voice/><contact:email/></contact:disclose></contact:create></create><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_create build');
is($rc->is_success(),1,'contact_create is_success');


$R2='';
$co=$dri->local_object('contact')->srid('sh8016')->auth({pw=>'2fooBAR'});
$rc=$dri->contact_delete($co);
is($R1,$E1.'<command><delete><contact:delete xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8016</contact:id></contact:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_delete build');
is($rc->is_success(),1,'contact_delete is_success');


$co=$dri->local_object('contact')->srid('sh8017')->auth({pw=>'2fooBAR'});
$R2=$E1.'<response>'.r().'<resData><contact:trnData xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8017</contact:id><contact:trStatus>pending</contact:trStatus><contact:reID>ClientX</contact:reID><contact:reDate>2000-06-08T22:00:00.0Z</contact:reDate><contact:acID>ClientY</contact:acID><contact:acDate>2000-06-13T22:00:00.0Z</contact:acDate></contact:trnData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->contact_transfer_start($co);
is($R1,$E1.'<command><transfer op="request"><contact:transfer xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8017</contact:id><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo></contact:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_transfer_start build');
is($rc->is_success(),1,'contact_transfer_start is_success');
is($dri->get_info('trStatus'),'pending','contact_transfer_start get_info(trStatus)');
is($dri->get_info('reID'),'ClientX','contact_transfer_start get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','contact_transfer_start get_info(reDate)');
is("".$d,'2000-06-08T22:00:00','contact_transfer_start get_info(reDate) value');
is($dri->get_info('acID'),'ClientY','contact_transfer_start get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','contact_transfer_start get_info(acDate)');
is("".$d,'2000-06-13T22:00:00','contact_transfer_start get_info(acDate) value');


$R2='';
$co=$dri->local_object('contact')->srid('sh8018')->auth({pw=>'2fooBAR'});
$toc=$dri->local_object('changes');
$toc->add('status',$dri->local_object('status')->no('delete'));
my $co2=$dri->local_object('contact');
$co2->org('');
$co2->street(['124 Example Dr.','Suite 200']);
$co2->city('Dulles');
$co2->sp('VA');
$co2->pc('20166-6503');
$co2->cc('US');
$co2->voice('+1.7034444444');
$co2->fax('');
$co2->auth({pw=>'2fooBAR'});
$co2->disclose({voice=>1,email=>1});
$toc->set('info',$co2);
$rc=$dri->contact_update($co,$toc);
is($R1,$E1.'<command><update><contact:update xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"><contact:id>sh8018</contact:id><contact:add><contact:status s="clientDeleteProhibited"/></contact:add><contact:chg><contact:postalInfo type="loc"><contact:org/><contact:addr><contact:street>124 Example Dr.</contact:street><contact:street>Suite 200</contact:street><contact:city>Dulles</contact:city><contact:sp>VA</contact:sp><contact:pc>20166-6503</contact:pc><contact:cc>US</contact:cc></contact:addr></contact:postalInfo><contact:voice>+1.7034444444</contact:voice><contact:fax/><contact:authInfo><contact:pw>2fooBAR</contact:pw></contact:authInfo><contact:disclose flag="1"><contact:voice/><contact:email/></contact:disclose></contact:chg></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

## Session commands
$R2='';
$rc=$dri->process('session','noop',[]);
is($R1,$E1.'<command><poll op="req"/><clTRID>ABC-12345</clTRID></command>'.$E2,'session noop build');
is($rc->is_success(),1,'session noop is_success');


$R2=$E1.'<response>'.r(1500).$TRID.'</response>'.$E2;
$rc=$dri->process('session','logout',[]);
is($R1,$E1.'<command><logout/><clTRID>ABC-12345</clTRID></command>'.$E2,'session logout build');
is($rc->is_success(),1,'session logout is_success');


$R2=$E1.'<greeting><svID>Example EPP server epp.example.com</svID><svDate>2000-06-08T22:00:00.0Z</svDate><svcMenu><version>1.0</version><lang>en</lang><lang>fr</lang><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcMenu><dcp><access><all/></access><statement><purpose><admin/><prov/></purpose><recipient><ours/><public/></recipient><retention><stated/></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','connect',[]);
is($R1,$E1.'<hello/>'.$E2,'session connect build (hello command)');
is($rc->is_success(),1,'session connect is_success');
is_deeply($dri->protocol->server_greeting(),{svID=>'Example EPP server epp.example.com',svDate=>'2000-06-08T22:00:00.0Z',version=>['1.0'],lang=>['en','fr'],svcext=>['http://custom/obj1ext-1.0'],svcs=>['urn:ietf:params:xml:ns:obj1','urn:ietf:params:xml:ns:obj2','urn:ietf:params:xml:ns:obj3']},'session connect server_greeting parse');


$R2='';
$rc=$dri->process('session','login',['ClientX','foo-BAR2','bar-FOO2']);
is($R1,$E1.'<command><login><clID>ClientX</clID><pw>foo-BAR2</pw><newPW>bar-FOO2</newPW><options><version>1.0</version><lang>en</lang></options><svcs><objURI>urn:ietf:params:xml:ns:obj1</objURI><objURI>urn:ietf:params:xml:ns:obj2</objURI><objURI>urn:ietf:params:xml:ns:obj3</objURI><svcExtension><extURI>http://custom/obj1ext-1.0</extURI></svcExtension></svcs></login><clTRID>ABC-12345</clTRID></command>'.$E2,'session login build');
is($rc->is_success(),1,'session login is_success');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
