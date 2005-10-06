use inc::Module::Install;

name           ( 'Perl-MinimumVersion'        );
abstract       ( 'Find the minimum required Perl version for any code' );
author         ( 'Adam Kennedy <cpan@ali.as>' );
version_from   ( 'lib/Perl/MinimumVersion.pm' );
license        ( 'perl'                       );
requires       ( 'perl'            => '5.005' );
# Version 0.48 gets rid of the XS bugs at least
# We need a newer version to deal with the qv() bug
requires       ( 'version'         => '0.48'  );
requires       ( 'Carp'            => 0       );
requires       ( 'List::Util'      => '1.15'  ); # Fixes leak in first
requires       ( 'Params::Util'    => '0.06'  );
requires       ( 'PPI'             => '1.103' );
build_requires ( 'Test::More'      => '0.47'  );
build_requires ( 'File::Spec'      => '0.80'  );
install_script ( 'bin/perlver'                );
auto_install   (                              );

&WriteAll;
