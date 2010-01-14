use strict;
use warnings;

package Test::EMC;

use Test::More ();
use eleMentalClinic::TestCase;
use lib 't/lib';

use Sub::Exporter -setup => {
  exports => [
    args => \&_args,
    run  => \&_run,
    test => \&_test,
  ],
  groups => {
    default => [qw(-all)],
  },
  collectors => {
    INIT => \&_INIT,
  },
};

sub _INIT {
  my ($col, $arg) = @_;
  my $into = $arg->{into};
  eval sprintf <<END, $into;
  package %s;
  use Test::More;
END
  die $@ if $@;
  return 1;
}

our ($TEST, @ARGS, @RUN);
my $test_n = 0;
sub _test {
  return sub {
    die "Can't nest 'test' blocks" if $TEST;
    my ($name, $code) = @_;
    if (@_ == 1) {
      $code = $name;
      $name = 'test ' . ++$test_n;
    }
    local ($TEST, @ARGS, @RUN);
    # maybe this can be something more useful later; it's still a handy place
    # to put methods
    $TEST = eleMentalClinic::TestCase->new;
    $code->($TEST);
    @ARGS or @ARGS = ([ [], 'no args' ]);
    for my $run (@RUN) {
      for my $args (@ARGS) {
        if ($ENV{TEST_VERBOSE}) { # prove -v
          Test::More::diag("[$name] $args->[1] > $run->[1]");
        }
        # for some reason, running this directly (without the eval/die) doesn't
        # cause a test failure with no_plan
        eval { $run->[0]->(@{$args->[0]}) };
        die $@ if $@;
      }
    }
  }
}

sub _args {
  return sub {
    die "Can't have 'args' without 'test'" unless $TEST;
    my ($name, $args) = @_;
    if (@_ == 1) {  
      $args = $name;
      $name = 'args ' . (1 + @ARGS);
    }
    $args = [ $args->() ] if ref $args eq 'CODE';
    push @ARGS, [
      $args,
      $name,
    ];
  };
}

sub _run {
  return sub {
    die "Can't have 'run' without 'test'" unless $TEST;
    my ($name, $code) = @_;
    if (@_ == 1) {  
      $code = $name;
      $name = 'run ' . (1 + @RUN);
    }

#    $prop->{txn} = 1 unless exists $prop->{txn};
#    if ($prop->{txn}) {
#      my $orig = $code;
#      $code = sub {
#        eleMentalClinic::DB->new->transaction_do($orig);
#      }
#    }

    push @RUN, [ $code, $name ];
  };
}

1;
