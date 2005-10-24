#!/usr/bin/perl -w

use Test::More tests => 58;

BEGIN { 
use_ok('Net::DRI');
use_ok('Net::DRI::Transport');
use_ok('Net::DRI::Exception');
use_ok('Net::DRI::Cache');
use_ok('Net::DRI::Protocol');
use_ok('Net::DRI::Util');
use_ok('Net::DRI::Registry');
use_ok('Net::DRI::DRD');
use_ok('Net::DRI::DRD::ICANN');
use_ok('Net::DRI::DRD::VNDS');
use_ok('Net::DRI::DRD::AFNIC');
use_ok('Net::DRI::DRD::Gandi');
use_ok('Net::DRI::DRD::WS');
use_ok('Net::DRI::DRD::EURid');
use_ok('Net::DRI::Data::Raw');
use_ok('Net::DRI::Data::Hosts');
use_ok('Net::DRI::Data::Changes');
use_ok('Net::DRI::Data::StatusList');
use_ok('Net::DRI::Data::RegistryObject');
use_ok('Net::DRI::Data::Contact');
use_ok('Net::DRI::Data::ContactSet');
use_ok('Net::DRI::Data::Contact::EURid');
use_ok('Net::DRI::Transport::Socket');
use_ok('Net::DRI::Transport::Dummy');
use_ok('Net::DRI::Transport::SOAP');
use_ok('Net::DRI::Transport::Web');
use_ok('Net::DRI::Protocol::ResultStatus');
use_ok('Net::DRI::Protocol::Message');
use_ok('Net::DRI::Protocol::RRP::Message');
use_ok('Net::DRI::Protocol::RRP::Core::Domain');
use_ok('Net::DRI::Protocol::RRP::Core::Host');
use_ok('Net::DRI::Protocol::RRP::Core::Status');
use_ok('Net::DRI::Protocol::RRP::Core::Session');
use_ok('Net::DRI::Protocol::RRP::Connection');
use_ok('Net::DRI::Protocol::RRP');
use_ok('Net::DRI::Protocol::AFNIC::WS::Domain');
use_ok('Net::DRI::Protocol::AFNIC::WS::Message');
use_ok('Net::DRI::Protocol::AFNIC::WS');
use_ok('Net::DRI::Protocol::Gandi::Web::Connection');
use_ok('Net::DRI::Protocol::Gandi::Web::Domain');
use_ok('Net::DRI::Protocol::Gandi::Web::Message');
use_ok('Net::DRI::Protocol::Gandi::Web');
use_ok('Net::DRI::Protocol::EPP');
use_ok('Net::DRI::Protocol::EPP::Message');
use_ok('Net::DRI::Protocol::EPP::Connection');
use_ok('Net::DRI::Protocol::EPP::Core::Status');
use_ok('Net::DRI::Protocol::EPP::Core::Contact');
use_ok('Net::DRI::Protocol::EPP::Core::Domain');
use_ok('Net::DRI::Protocol::EPP::Core::Host');
use_ok('Net::DRI::Protocol::EPP::Core::Session');
use_ok('Net::DRI::Protocol::EPP::Extensions::GracePeriod');
use_ok('Net::DRI::Protocol::EPP::Extensions::E164');
use_ok('Net::DRI::Protocol::EPP::Extensions::SecDNS');
use_ok('Net::DRI::Protocol::EPP::Extensions::NSgroup');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Sunrise');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Domain');
use_ok('Net::DRI::Protocol::EPP::Extensions::EURid::Contact');
}

exit 0;
