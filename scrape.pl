use Data::Dumper;
use URI;
use Web::Scraper;
my $scraper = scraper { process "td", "stuff[]" => "TEXT" };
my $ds = $scraper->scrape(URI->new("file:///Users/simon/WWW-UKTrains/foo.html"));
my @things = @{$ds->{stuff}};
splice @things, 0, 17;
my @journeys;
my @headers = qw(start_time end_time duration changes nothing1 nothing2
advance_fare offpeak_fare anytime_fare);
while (my @row = splice (@things, 0, 5)) {
    my $h = shift @headers;
    for (0..4) { 
        if ($h =~ /fare/) { $row[$_] = $row[$_] =~ /([\d\.]+)/ ? $1 : "" }
        $journeys[$_]{$h} = $row[$_] unless $h =~ /nothing/;
    }
}

print Dumper(\@journeys);
