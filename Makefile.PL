use inc::Module::Install;
include 'Module::AutoInstall';

name 'Data-Conveyor';
all_from 'lib/Data/Conveyor.pm';
readme_from_pod;
readme_markdown_from_pod;

auto_set_homepage;
auto_set_bugtracker;
auto_set_repository;

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
requires 'HTTP::Engine::FirePHP';
requires 'IO::Pager';
requires 'JSON::XS';
requires 'Log::Dispatch';
requires 'MIME::Types';
requires 'once';
requires 'Path::Class::Unicode';
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

author_requires 'ShipIt';
author_requires 'ShipIt::Step::DistClean';
author_requires 'ShipIt::Step::DistTestExtra';
author_requires 'ShipIt::Step::Manifest';
author_requires 'ShipIt::Step::Twitter';
author_requires 'Test::Compile';
author_requires 'Test::Perl::Critic';
author_requires 'Test::Pod';
author_requires 'Test::Spelling';
author_requires 'Pod::Wordlist::hanekomu';
author_requires 'Test::Pod::Coverage';
# author_requires 'Test::Kwalitee';   # Attempt to free unreferenced scalar
author_requires 'Test::YAML::Meta';
author_requires 'Test::Portability::Files';
author_requires 'Test::Synopsis';

auto_install;
auto_include;
WriteAll;
