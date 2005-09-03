use inc::Module::Install;

name          ( 'Perl-MinimumVersion'        );
abstract      ( 'Find the minimum required Perl version for any code' );
author        ( 'Adam Kennedy <cpan@ali.as>' );
version_from  ( 'lib/Perl/MinimumVersion.pm' );
license       ( 'perl'                       );
requires      ( 'perl'            => '5.005' );
requires      ( 'version'         => '0.42'  );
requires      ( 'Carp'            => 0       );
requires      ( 'List::Util'      => '1.10'  );
requires      ( 'Params::Util'    => '0.05'  );
requires      ( 'PPI'             => '1.000' );
build_requires( 'Test::More'      => '0.47'  );
build_requires( 'File::Spec'      => '0.80'  );
auto_install  (                              );

&WriteAll;
