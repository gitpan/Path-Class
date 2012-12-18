
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Cross-platform path specification manipulation",
  "AUTHOR" => "Ken Williams <kwilliams\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.3601",
    "Test" => 0,
    "Test::More" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "Path-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Path::Class",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Cwd" => 0,
    "Exporter" => 0,
    "File::Path" => 0,
    "File::Spec" => "0.87",
    "File::Temp" => 0,
    "File::stat" => 0,
    "IO::Dir" => 0,
    "IO::File" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0
  },
  "VERSION" => "0.29",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



