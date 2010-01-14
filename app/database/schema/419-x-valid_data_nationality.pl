my $db = eleMentalClinic::DB->new;
unless ($db->select_one(
    [ '*' ],
    'valid_data_valid_data',
    "name = 'valid_data_nationality'"
)) {
    $db->do_sql(<<END, 1);
INSERT INTO valid_data_valid_data ( dept_id, name, description, readonly, active ) VALUES ( 1001, 'valid_data_nationality', 'Nationality', 0, 1 );
END
}
