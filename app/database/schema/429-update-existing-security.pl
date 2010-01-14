use strict;
use warnings;

my $db = eleMentalClinic::DB->new;

my %roles = (
  active              => '1______',
  admin               => '_1_____',
  service_coordinator => '__1____',
  writer              => '___1___',
  financial           => '____1__',
  supervisor          => '_____1_',
  scanner             => '______1',
);

$db->transaction_do(sub {
    for my $name ( keys %roles ) {
        $db->do_sql(sprintf( <<'END',
INSERT INTO personnel_security_role(staff_id, role_name)
  SELECT staff_id, '%s' FROM personnel
  WHERE security like '%s'
END
            $name, $roles{$name},
        ), 1);
    }

    $db->do_sql('ALTER TABLE personnel DROP COLUMN security', 1);
});
