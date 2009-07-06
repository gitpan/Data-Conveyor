use inc::Module::Install;
include 'Module::AutoInstall';

name 'Data-Conveyor';
all_from 'lib/Data/Conveyor.pm';
perl_version '5.006';

requires 'Class::Scaffold' => '0.08';
requires 'Class::Null';
requires 'Data::Container';
requires 'Data::Storage';
requires 'Data::Comparable';
requires 'Data::Inherited';
requires 'Data::Miscellany';
requires 'Date::Calc';
requires 'DBI';
requires 'Encode';
requires 'Error::Hierarchy';
requires 'Hash::Flatten';
requires 'Hook::Modular';
requires 'HTTP::Date';
requires 'HTTP::Engine';
requires 'IO::Pager';
requires 'JSON::XS';
requires 'Log::Dispatch';
requires 'MIME::Types';
requires 'Pod::PlainText';
requires 'String::CamelCase';
requires 'String::FlexMatch';
requires 'SOAP::Lite';
requires 'Term::Shell::Enhanced';
requires 'Test::Differences';
requires 'Test::More';
requires 'Test::utf8';
requires 'Text::Table';
requires 'Time::HiRes';
requires 'URI::Escape';
requires 'YAML';
requires 'YAML::Active';

test_requires 'Test::More' => '0.70';
extra_tests;

auto_install;
auto_include;
WriteAll;
