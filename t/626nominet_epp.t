#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 219;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
*{'main::is_string'}=\&main::is if $@;

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
$dri->add_registry('Nominet');
$dri->target('Nominet')->new_current_profile('p1','Net::DRI::Transport::Dummy',[{f_send=>\&mysend,f_recv=>\&myrecv}],'Net::DRI::Protocol::EPP::Extensions::Nominet',[]);

my ($rc,$s,$d,$dh,@c,$co);

# ## Domain commands
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:cd><domain:name avail="0">example.co.uk</domain:name></domain:cd><domain:cd><domain:name avail="1">example2.co.uk</domain:name></domain:cd></domain:chkData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check_multi('example.co.uk','example2.co.uk');
is_string($R1,$E1.'<command><check><domain:check xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name><domain:name>example2.co.uk</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_check build');
is($rc->is_success(),1,'domain_check_multi is_success');
is($dri->get_info('exist','domain','example.co.uk'),1,'domain_check_multi get_info(exist) 1/2');
is($dri->get_info('exist','domain','example2.co.uk'),0,'domain_check_multi get_info(exist) 2/2');

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name><domain:reg-status>Registration request being processed.</domain:reg-status><domain:account><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.0" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.0"><account:roid>S123456</account:roid><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr type="admin"><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact type="admin" order="1"><contact:infData><contact:roid>C12345</contact:roid><contact:name>Mr R.Strant</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="admin" order="2"><contact:infData><contact:roid>C23456</contact:roid><contact:name>Ms S. Strant</contact:name><contact:phone>01865 123457</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>s.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="billing" order="1"><contact:infData><contact:roid>C12347</contact:roid><contact:name>A. Ccountant</contact:name><contact:phone>01865 657893</contact:phone><contact:email>acc@billing.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:clID>TEST</account:clID><account:crID>TEST</account:crID><account:crDate>1999-04-03T22:00:00.0Z</account:crDate><account:upID>domains@isp.com</account:upID><account:upDate>1999-12-03T09:00:00.0Z</account:upDate></account:infData></domain:account><domain:ns xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.0"><ns:infData><ns:roid>NS12345</ns:roid><ns:name>ns1.example.co.uk</ns:name><ns:addr ip="v4">10.10.10.10</ns:addr><ns:clID>TEST</ns:clID><ns:crID>domains@isp.com</ns:crID><ns:crDate>1999-04-03T22:00:00.0Z</ns:crDate><ns:upID>domains@isp.com</ns:upID><ns:upDate>1999-12-03T09:00:00.0Z</ns:upDate></ns:infData><ns:infData><ns:roid>NS12346</ns:roid><ns:name>ns1.example.com</ns:name><ns:clID>TEST</ns:clID><ns:crID>domains@isp.com</ns:crID><ns:crDate>1999-04-03T22:00:00.0Z</ns:crDate><ns:upID>domains@isp.com</ns:upID><ns:upDate>1999-12-03T09:00:00.0Z</ns:upDate></ns:infData></domain:ns><domain:clID>TEST</domain:clID><domain:crID>TEST</domain:crID><domain:crDate>1999-04-03T22:00:00.0Z</domain:crDate><domain:upID>domains@isp.com</domain:upID><domain:upDate>1999-12-03T09:00:00.0Z</domain:upDate><domain:exDate>2007-12-03T09:00:00.0Z</domain:exDate></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('example.co.uk');
is_string($R1,$E1.'<command><info><domain:info xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('reg-status'),'Registration request being processed.','domain_info get_info(reg-status)');

$co=$dri->get_info('contact');
isa_ok($co,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$co->types()],['admin','billing','registrant'],'domain_info get_info(contact) types');

$d=$co->get('registrant');
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(registrant)');
is($d->roid(),'S123456','domain_info get_info(contact) get(registrant) roid');
is($d->name(),'Mr R. Strant','domain_info get_info(contact) get(registrant) name');
is($d->org(),'R. S. Industries','domain_info get_info(contact) get(registrant) org/trad-name');
is($d->type(),'STRA','domain_info get_info(contact) get(registrant) type');
is($d->co_no(),'NI123456','domain_info get_info(contact) get(registrant) co_no');
is($d->opt_out(),'N','domain_info get_info(contact) get(registrant) opt_out');
is_deeply($d->street(),['2102 High Street','Carfax'],'domain_info get_info(contact) get(registrant) street');
is($d->city(),'Oxford','domain_info get_info(contact) get(registrant) city');
is($d->sp(),'Oxfordshire','domain_info get_info(contact) get(registrant) sp/county');
is($d->pc(),'OX1 1DF','domain_info get_info(contact) get(registrant) pc/postcode');
is($d->cc(),'GB','domain_info get_info(contact) get(registrant) country');

$d=($co->get('admin'))[0];
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(admin1)');
is($dri->get_info('action','contact',$d->roid()),'info','domain_info get_info(action,contact,admin1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'domain_info get_info(exist,contact,admin1->roid)');
is($d->roid(),'C12345','domain_info get_info(contact) get(admin1) roid');
is($d->name(),'Mr R.Strant','domain_info get_info(contact) get(admin1) name');
is($d->voice(),'01865 123456','domain_info get_info(contact) get(admin1) voice');
is($d->fax(),'01865 123456','domain_info get_info(contact) get(admin1) fax');
is($d->email(),'r.strant@strant.co.uk','domain_info get_info(contact) get(admin1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','domain_info get_info(clID,contact,admin1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','domain_info get_info(crID,contact,admin1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','domain_info get_info(crDate,contact,admin1->roid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,contact,admin1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID,contact,admin1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate,contact,admin1->roid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,contact,admin1->roid) value');

$d=($co->get('admin'))[1];
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(admin2)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,admin2->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,admin2->roid)');
is($d->roid(),'C23456','domain_info get_info(contact) get(admin2) roid');
is($d->name(),'Ms S. Strant','domain_info get_info(contact) get(admin2) name');
is($d->voice(),'01865 123457','domain_info get_info(contact) get(admin2) voice');
is($d->fax(),'01865 123456','domain_info get_info(contact) get(admin2) fax');
is($d->email(),'s.strant@strant.co.uk','domain_info get_info(contact) get(admin2) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','domain_info get_info(clID,contact,admin2->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','domain_info get_info(crID,contact,admin2->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','domain_info get_info(crDate,contact,admin2->roid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,contact,admin2->roid) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID,contact,admin2->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate,contact,admin2->roid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,contact,admin2->roid) value');

$d=($co->get('billing'))[0];
isa_ok($d,'Net::DRI::Data::Contact','domain_info get_info(contact) get(billing1)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,billing1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'domain_info get_info(exist,contact,billing1->roid)');
is($d->roid(),'C12347','domain_info get_info(contact) get(billing1) roid');
is($d->name(),'A. Ccountant','domain_info get_info(contact) get(billing1) name');
is($d->voice(),'01865 657893','domain_info get_info(contact) get(billing1) voice');
is($d->email(),'acc@billing.co.uk','domain_info get_info(contact) get(billing1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','domain_info get_info(clID,contact,billing1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','domain_info get_info(crID,contact,billing1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','domain_info get_info(crDate,contact,billing1->roid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,contact,billing1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID,contact,billing1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate,contact,billing1->roid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,contact,billing1->roid) value');

is($dri->get_info('clID','account','S123456'),'TEST','domain_info get_info(clID,account,registrant->srid)');
is($dri->get_info('crID','account','S123456'),'TEST','domain_info get_info(crID,account,registrant->srid)'),
$d=$dri->get_info('crDate','account','S123456');
isa_ok($d,'DateTime','domain_info get_info(crDate,account,registrant->srid)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate,account,registrant->srid) value');
is($dri->get_info('upID','account','S123456'),'domains@isp.com','domain_info get_info(upID,account,registrant->srid)');
$d=$dri->get_info('upDate','account','S123456');
isa_ok($d,'DateTime','domain_info get_info(upDate,account,registrant->srid)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate,account,registrant->srid) value');

$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.example.co.uk','ns1.example.com'],'domain_info get_info(ns) get_names');
@c=$dh->get_details(1);
is($c[0],'ns1.example.co.uk','domain_info get_info(ns) get_details(1) $hostname');
is_deeply($c[1],['10.10.10.10'],'domain_info get_info(ns) get_details(1) ipv4');
is($dri->get_info('roid','host',$c[0]),'NS12345','domain_info get_info(roid,host,$hostname)');
is($dri->get_info('name','host',$dri->get_info('roid','host',$c[0])),$c[0],'domain_info get_info(name,host,get_info(roid,host,$hostname))');
is($dri->get_info('clID','host',$c[0]),'TEST','domain_info get_info(clID,host,$hostname)');
is($dri->get_info('crID','host',$c[0]),'domains@isp.com','domain_info get_info(crID,host,$hostname)');
is($dri->get_info('upID','host',$c[0]),'domains@isp.com','domain_info get_info(upID,host,$hostname)');
$d=$dri->get_info('crDate','host',$c[0]);
isa_ok($d,'DateTime','domain_info get_info(crDate,host,$hostname)');
is($d.'','1999-04-03T22:00:00','domain_info get_info(crDate,host,$hostname) value');
$d=$dri->get_info('upDate','host',$c[0]);
isa_ok($d,'DateTime','domain_info get_info(upDate,host,$hostname)');
is($d.'','1999-12-03T09:00:00','domain_info get_info(upDate,host,$hostname) value');

is($dri->get_info('clID'),'TEST','domain_info get_info(clID)');
is($dri->get_info('crID'),'TEST','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'1999-04-03T22:00:00','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'domains@isp.com','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'1999-12-03T09:00:00','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2007-12-03T09:00:00','domain_info get_info(exDate) value');

$R2='';
$rc=$dri->domain_delete_only('example.co.uk');
is_string($R1,$E1.'<command><delete><domain:delete xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_delete_only build');
is($rc->is_success(),1,'domain_delete_only is_success');

$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name><domain:exDate>2007-04-03T22:00:00.0Z</domain:exDate></domain:renData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('example.co.uk',{duration => DateTime::Duration->new(years=>2)});
is_string($R1,$E1.'<command><renew><domain:renew xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name><domain:period unit="y">2</domain:period></domain:renew></renew><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_renew build');
is($dri->get_info('action'),'renew','domain_renew get_info(action)');
is($dri->get_info('exist'),1,'domain_renew get_info(exist)');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_renew get_info(exDate)');
is(''.$d,'2007-04-03T22:00:00','domain_renew get_info(exDate) value');

$R2='';
$rc=$dri->domain_transfer_start('example.co.uk',{registrar_tag => 'TEST', account_id => '123456'});
is_string($R1,$E1.'<command><transfer op="request"><domain:transfer xmlns:domain="http://www.nominet.org.uk/epp/xml/nom-domain-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-domain-1.0 nom-domain-1.0.xsd"><domain:name>example.co.uk</domain:name><domain:registrar-tag>TEST</domain:registrar-tag><domain:account><domain:account-id>123456</domain:account-id></domain:account></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_request build');
is($rc->is_success(),1,'domain_transfer_request is_success');

## The domain is not really used for accept/refuse, nor even sent to registry, but must be there, whatever value it has as long as it is a domain name in the .UK registry
$R2='';
$rc=$dri->domain_transfer_accept('whatever.co.uk',{case_id => 10001});
is_string($R1,$E1.'<command><transfer op="approve"><n:rcCase xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.0 nom-notifications-1.0.xsd"><n:case-id>10001</n:case-id></n:rcCase></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_accept build');
is($rc->is_success(),1,'domain_transfer_accept is_success');

$R2='';
$rc=$dri->domain_transfer_refuse('whatever.co.uk',{case_id => 10001});
is_string($R1,$E1.'<command><transfer op="reject"><n:rcCase xmlns:n="http://www.nominet.org.uk/epp/xml/nom-notifications-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-notifications-1.0 nom-notifications-1.0.xsd"><n:case-id>10001</n:case-id></n:rcCase></transfer><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_transfer_accept build');
is($rc->is_success(),1,'domain_transfer_refuse is_success');


$dri->cache_clear(); ## this is needed to make sure that calls below to host_info & contact_info do in fact do the query and not take results from cache

##################################################################################################################
## Host commands

$R2=$E1.'<response>'.r().'<resData><ns:infData xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-ns-1.0 nom-ns-1.0.xsd"><ns:roid>NS12345</ns:roid><ns:name>ns1.example.co.uk</ns:name><ns:addr ip="v4">10.10.10.10</ns:addr><ns:clID>TEST</ns:clID><ns:crID>TEST</ns:crID><ns:crDate>1999-04-03T22:00:00.0Z</ns:crDate><ns:upID>TEST</ns:upID><ns:upDate>1999-12-03T09:00:00.0Z</ns:upDate></ns:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->host_info('NS12345');
is_string($R1,$E1.'<command><info><ns:info xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-ns-1.0 nom-ns-1.0.xsd"><ns:roid>NS12345</ns:roid></ns:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'host_info build');
is($dri->get_info('action'),'info','host_info get_info(action)');
is($dri->get_info('exist'),1,'host_info get_info(exist)');
is($dri->get_info('roid'),'NS12345','host_info get_info(roid)');
$s=$dri->get_info('self');
isa_ok($s,'Net::DRI::Data::Hosts','host_info get_info(self)');
my ($name,$ip4,$ip6)=$s->get_details(1);
is($name,'ns1.example.co.uk','host_info self name');
is($s->roid(),'NS12345','host_info self roid');
is_deeply($ip4,['10.10.10.10'],'host_info self ip4');
is($dri->get_info('clID'),'TEST','host_info get_info(clID)');
is($dri->get_info('crID'),'TEST','host_info get_info(crID)');
is($dri->get_info('upID'),'TEST','host_info get_info(upID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','host_info get_info(crDate)');
is($d.'','1999-04-03T22:00:00','host_info get_info(crDate) value');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','host_info get_info(upDate)');
is($d.'','1999-12-03T09:00:00','host_info get_info(upDate) value');

$R2=$E1.'<response>'.r().$TRID.'</response>'.$E2;
my $toc=$dri->local_object('changes');
$toc->set('name','ns0.example2.co.uk');
$rc=$dri->host_update('NS1001',$toc);
is_string($R1,$E1.'<command><update><ns:update xmlns:ns="http://www.nominet.org.uk/epp/xml/nom-ns-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-ns-1.0 nom-ns-1.0.xsd"><ns:roid>NS1001</ns:roid><ns:name>ns0.example2.co.uk</ns:name></ns:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'host_update build');
is($rc->is_success(),1,'host_update is_success');

#########################################################################################################
## Contact commands

$co=$dri->local_object('contact');
isa_ok($co,'Net::DRI::Data::Contact::Nominet','contact');
$co->srid('T1');
is($co->roid(),'T1','contact roid = srid');
$co->roid('T2');
is($co->srid(),'T2','contact srid = roid');

$R2=$E1.'<response>'.r().'<resData><contact:infData xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.0 nom-contact-1.0.xsd"><contact:roid>C12345</contact:roid><contact:name>Mr Contact</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>TEST</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>TEST</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></resData>'.$TRID.'</response>'.$E2;
$co=$dri->local_object('contact')->srid('C12345');
$rc=$dri->contact_info($co);
is_string($R1,$E1.'<command><info><contact:info xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.0 nom-contact-1.0.xsd"><contact:roid>C12345</contact:roid></contact:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_info build');
is($rc->is_success(),1,'contact_info is_success');
is($dri->get_info('action'),'info','contact_info get_info(action)');
is($dri->get_info('exist'),1,'contact_info get_info(exist)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::Contact','contact_info get_info(self)');
is($co->srid(),'C12345','contact_info get_info(self) srid');
is($co->roid(),'C12345','contact_info get_info(self) roid');
is($co->name(),'Mr Contact','contact_info get_info(self) name');
is($co->voice(),'01865 123456','contact_info get_info(self) voice');
is($co->fax(),'01865 123456','contact_info get_info(self) fax');
is($co->email(),'r.strant@strant.co.uk','contact_info get_info(self) email');
is($dri->get_info('clID'),'TEST','contact_info get_info(clID)');
is($dri->get_info('crID'),'TEST','contact_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','contact_info get_info(crDate)');
is(''.$d,'1999-04-03T22:00:00','contact_info get_info(crDate) value');
is($dri->get_info('upID'),'TEST','contact_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','contact_info get_info(upDate)');
is(''.$d,'1999-12-03T09:00:00','contact_info get_info(upDate) value');

$R2='';
$co=$dri->local_object('contact')->srid('C11001');
$toc=$dri->local_object('changes');
$co->fax('');
$co->email('contact@example.co.uk');
$toc->set('info',$co);
$rc=$dri->contact_update($co,$toc);
is_string($R1,$E1.'<command><update><contact:update xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-contact-1.0 nom-contact-1.0.xsd"><contact:roid>C11001</contact:roid><contact:fax/><contact:email>contact@example.co.uk</contact:email></contact:update></update><clTRID>ABC-12345</clTRID></command>'.$E2,'contact_update build');
is($rc->is_success(),1,'contact_update is_success');

####################################################################################################
## Account

$R2=$E1.'<response>'.r().'<resData><account:infData xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.0" xmlns:contact="http://www.nominet.org.uk/epp/xml/nom-contact-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.0 nom-account-1.0.xsd"><account:roid>S123456</account:roid><account:name>Mr R. Strant</account:name><account:trad-name>R. S. Industries</account:trad-name><account:type>STRA</account:type><account:co-no>NI123456</account:co-no><account:opt-out>N</account:opt-out><account:addr><account:street>2102 High Street</account:street><account:locality>Carfax</account:locality><account:city>Oxford</account:city><account:county>Oxfordshire</account:county><account:postcode>OX1 1DF</account:postcode><account:country>GB</account:country></account:addr><account:contact type="admin" order="1"><contact:infData><contact:roid>C12345</contact:roid><contact:name>Mr R.Strant</contact:name><contact:phone>01865 123456</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>r.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="admin" order="2"><contact:infData><contact:roid>C23456</contact:roid><contact:name>Ms S. Strant</contact:name><contact:phone>01865 123457</contact:phone><contact:fax>01865 123456</contact:fax><contact:email>s.strant@strant.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:contact type="billing" order="1"><contact:infData><contact:roid>C12347</contact:roid><contact:name>A. Ccountant</contact:name><contact:phone>01865 657893</contact:phone><contact:email>acc@billing.co.uk</contact:email><contact:clID>TEST</contact:clID><contact:crID>domains@isp.com</contact:crID><contact:crDate>1999-04-03T22:00:00.0Z</contact:crDate><contact:upID>domains@isp.com</contact:upID><contact:upDate>1999-12-03T09:00:00.0Z</contact:upDate></contact:infData></account:contact><account:clID>TEST</account:clID><account:crID>TEST</account:crID><account:crDate>1999-04-03T22:00:00.0Z</account:crDate><account:upID>domains@isp.com</account:upID><account:upDate>1999-12-03T09:00:00.0Z</account:upDate></account:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->account_info('S123456');
is_string($R1,$E1.'<command><info><account:info xmlns:account="http://www.nominet.org.uk/epp/xml/nom-account-1.0" xsi:schemaLocation="http://www.nominet.org.uk/epp/xml/nom-account-1.0 nom-account-1.0.xsd"><account:roid>S123456</account:roid></account:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'account_info build');
is($rc->is_success(),1,'account_info is_success');
is($dri->get_info('action'),'info','account_info get_info(action)');
is($dri->get_info('exist'),1,'account_info get_info(exist)');
is($dri->get_info('roid'),'S123456','account_info get_info(roid)');
$co=$dri->get_info('self');
isa_ok($co,'Net::DRI::Data::ContactSet','account_info get_info(self)');
is_deeply([$co->types()],[qw/admin billing registrant/],'account_info get_info(self) types');
$d=$co->get('registrant');
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(registrant)');
is($d->roid(),'S123456','account_info get_info(self) get(registrant) roid');
is($d->name(),'Mr R. Strant','account_info get_info(self) get(registrant) name');
is($d->org(),'R. S. Industries','account_info get_info(self) get(registrant) org/trad-name');
is($d->type(),'STRA','account_info get_info(self) get(registrant) type');
is($d->co_no(),'NI123456','account_info get_info(self) get(registrant) co_no');
is($d->opt_out(),'N','account_info get_info(self) get(registrant) opt_out');
is_deeply($d->street(),['2102 High Street','Carfax'],'account_info get_info(self) get(registrant) street');
is($d->city(),'Oxford','account_info get_info(self) get(registrant) city');
is($d->sp(),'Oxfordshire','account_info get_info(self) get(registrant) sp/county');
is($d->pc(),'OX1 1DF','account_info get_info(self) get(registrant) pc/postcode');
is($d->cc(),'GB','account_info get_info(self) get(registrant) country');

$d=($co->get('admin'))[0];
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(admin1)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,admin1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,admin1->roid)');
is($d->roid(),'C12345','account_info get_info(self) get(admin1) roid');
is($d->name(),'Mr R.Strant','account_info get_info(self) get(admin1) name');
is($d->voice(),'01865 123456','account_info get_info(self) get(admin1) voice');
is($d->fax(),'01865 123456','account_info get_info(self) get(admin1) fax');
is($d->email(),'r.strant@strant.co.uk','account_info get_info(self) get(admin1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','account_info get_info(clID,contact,admin1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','account_info get_info(crID,contact,admin1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','account_info get_info(crDate,contact,admin1->roid)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate,contact,admin1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID,contact,admin1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate,contact,admin1->roid)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate,contact,admin1->roid) value');

$d=($co->get('admin'))[1];
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(admin2)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,admin2->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,admin2->roid)');
is($d->roid(),'C23456','account_info get_info(self) get(admin2) roid');
is($d->name(),'Ms S. Strant','account_info get_info(self) get(admin2) name');
is($d->voice(),'01865 123457','account_info get_info(self) get(admin2) voice');
is($d->fax(),'01865 123456','account_info get_info(self) get(admin2) fax');
is($d->email(),'s.strant@strant.co.uk','account_info get_info(self) get(admin2) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','account_info get_info(clID,contact,admin2->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','account_info get_info(crID,contact,admin2->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','account_info get_info(crDate,contact,admin2->roid)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate,contact,admin2->roid) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID,contact,admin2->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate,contact,admin2->roid)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate,contact,admin2->roid) value');

$d=($co->get('billing'))[0];
isa_ok($d,'Net::DRI::Data::Contact','account_info get_info(self) get(billing1)');
is($dri->get_info('action','contact',$d->roid()),'info','account_info get_info(action,contact,billing1->roid)');
is($dri->get_info('exist','contact',$d->roid()),1,'account_info get_info(exist,contact,billing1->roid)');
is($d->roid(),'C12347','account_info get_info(self) get(billing1) roid');
is($d->name(),'A. Ccountant','account_info get_info(self) get(billing1) name');
is($d->voice(),'01865 657893','account_info get_info(self) get(billing1) voice');
is($d->email(),'acc@billing.co.uk','account_info get_info(self) get(billing1) email');
is($dri->get_info('clID','contact',$d->roid()),'TEST','account_info get_info(clID,contact,billing1->roid)');
is($dri->get_info('crID','contact',$d->roid()),'domains@isp.com','account_info get_info(crID,contact,billing1->roid)'),
$d=$dri->get_info('crDate','contact',$d->roid());
isa_ok($d,'DateTime','account_info get_info(crDate,contact,billing1->roid)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate,contact,billing1->roid) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID,contact,billing1->roid)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate,contact,billing1->roid)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate,contact,billing1->roid) value');

is($dri->get_info('clID'),'TEST','account_info get_info(clID)');
is($dri->get_info('crID'),'TEST','account_info get_info(crID)'),
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','account_info get_info(crDate)');
is(''.$d,'1999-04-03T22:00:00','account_info get_info(crDate) value');
is($dri->get_info('upID'),'domains@isp.com','account_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','account_info get_info(upDate)');
is(''.$d,'1999-12-03T09:00:00','account_info get_info(upDate) value');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
