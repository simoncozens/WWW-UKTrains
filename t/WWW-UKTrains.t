use Test::More tests => 4;
BEGIN { use_ok('WWW::UKTrains') };
is($WWW::UKTrains::Stations::abbr2station{ACC}, "Acton Central");
is($WWW::UKTrains::Stations::station2abbr{Deal}, "DEA");
my @sugg = WWW::UKTrains::Stations::complete("Aberd");
is_deeply(\@sugg, [ map { "Aberd$_" } qw/are een our ovey/ ]);
