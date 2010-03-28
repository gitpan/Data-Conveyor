
use strict;
use warnings;

 BEGIN { require 5.008; } 

use ExtUtils::MakeMaker 6.11;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Data::Conveyor',
                       'DISTNAME' => 'Data-Conveyor',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.11'
                                               },
                       'AUTHOR' => 'Marcel Gruenauer <marcel@cpan.org>, Florian Helmberger <fh@univie.ac.at>, Achim Adam <ac@univie.ac.at>, Mark Hofstetter <mh@univie.ac.at>, Heinz Ekker <ek@univie.ac.at>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Stage-based conveyor-belt-like ticket handling system',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100870',
                       'PREREQ_PM' => {
                                        'Class::Scaffold::Base' => '0',
                                        'Text::Table' => '0',
                                        'YAML' => '0',
                                        'Pod::Text' => '0',
                                        'Class::Scaffold::Test::UtilLoader' => '0',
                                        'Class::Scaffold::Factory::Type' => '0',
                                        'Storable' => '0',
                                        'Class::Scaffold::YAML::Active::Hash' => '0',
                                        'Error::Hierarchy' => '0',
                                        'YAML::Active' => '0',
                                        'DBI' => '0',
                                        'English' => '0',
                                        'Class::Scaffold::App::CommandLine' => '0',
                                        'charnames' => '0',
                                        'Class::Value::Exception::Base' => '0',
                                        'Date::Calc' => '0',
                                        'Data::Storage::DBI::Oracle' => '0',
                                        'Class::Scaffold::Util' => '0',
                                        'String::FlexMatch::Test' => '0',
                                        'Error::Hierarchy::Internal::DBI::STH' => '0',
                                        'Data::Storage::DBI::Mock' => '0',
                                        'Class::Value::String' => '0',
                                        'Compress::Zlib' => '0',
                                        'Error::Hierarchy::Util' => '0',
                                        'IO::Handle' => '0',
                                        'Data::Storage::Null' => '0',
                                        'Class::Scaffold::HierarchicalDirty' => '0',
                                        'Class::Scaffold::Exception::Business' => '0',
                                        'Error' => '0',
                                        'File::Find' => '0',
                                        'Hook::Modular' => '0',
                                        'Class::Scaffold::Storable' => '0',
                                        'constant' => '0',
                                        'IO::Pager' => '0',
                                        'Class::Scaffold::Accessor' => '0',
                                        'Exporter' => '0',
                                        'Class::Scaffold::ConstantImporter' => '0',
                                        'Carp' => '0',
                                        'Error::Hierarchy::Internal' => '0',
                                        'Class::Scaffold::Environment' => '0',
                                        'Hook::Modular::Plugin' => '0',
                                        'Data::Miscellany' => '0',
                                        'Class::Scaffold::Factory' => '0',
                                        'Class::Value::Enum' => '0',
                                        'Term::Shell::Enhanced' => '0',
                                        'Data::Storage::Memory' => '0',
                                        'Hash::Flatten' => '0',
                                        'Test::Builder' => '0',
                                        'Class::Scaffold::Test' => '0',
                                        'Data::Inherited' => '0',
                                        'Error::Hierarchy::Test' => '0',
                                        'Class::Scaffold::YAML::Marshall' => '0',
                                        'Data::Storage::DBI::SQLite' => '0',
                                        'once' => '0',
                                        'Getopt::Long' => '0',
                                        'parent' => '0',
                                        'Test::Class' => '0',
                                        'Data::Container' => '0',
                                        'Data::Dumper' => '0',
                                        'overload' => '0',
                                        'Class::Scaffold::Log' => '0',
                                        'Class::Scaffold::App::Test::YAMLDriven' => '0',
                                        'Test::More' => '0.88',
                                        'File::Temp' => '0',
                                        'Class::Scaffold::Exception::Util' => '0',
                                        'Scalar::Util' => '0',
                                        'FindBin' => '0',
                                        'Class::Scaffold::Delegate::Mixin' => '0',
                                        'Fcntl' => '0',
                                        'Class::Scaffold::Exception::Container' => '0',
                                        'Class::Value' => '0',
                                        'Class::Scaffold::Test::Inherited' => '0',
                                        'Class::Scaffold::App::Test::Classes' => '0',
                                        'Error::Hierarchy::Internal::CustomMessage' => '0',
                                        'Class::Accessor::Complex' => '0',
                                        'Class::Scaffold::Exception' => '0',
                                        'Time::HiRes' => '0',
                                        'YAML::Marshall' => '0',
                                        'Data::Storage::DBI::Postgres' => '0',
                                        'Class::Value::Exception::NotWellFormedValue' => '0',
                                        'Class::Scaffold::YAML::Active' => '0',
                                        'Sys::Hostname' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };

WriteMakefile(%WriteMakefileArgs);



