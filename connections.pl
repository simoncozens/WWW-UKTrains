#!/usr/bin/perl
my %cache;
use List::Util qw(min sum);
use WWW::UKTrains;
use Web::Scraper;
use Graph::Directed;
use URI::Escape;
use WWW::Mechanize;
use strict;
use URI;

my ($dep, $dst, $time) = (@ARGV);
my $g = new Graph::Directed;

my $j = scraper { process "ul>li", "journeys[]" => 
 scraper { process "a", description => 'TEXT', url => '@href' }
 };
my $connections = scraper { process "ul>li", "connections[]" => "TEXT" };
# XXX No note of $time here
my $stuff = $j->scrape(URI->new("http://m.traintimes.org.uk/$dep/$dst"))->{journeys};
pop @$stuff;
pop @$stuff;
use Data::Dumper;
my %change;
for (@$stuff) {
    my $url; next unless $url = $_->{url};
    next if $_->{description} =~ /direct/;
    my $x = $connections->scrape($url);
    my $i = 0;
    my @change;
    for (@{$x->{connections}}) {
    #print $_."\n";
        /\(([A-Z]+)\).*\(([A-Z]+)\)/ or die $_;
        push @change, $2;
        $g->add_edge($1, $2);
    }
    pop @change;
    @change{@change} = @change;
}

sub connect_downwards {
    my $vertex = shift;
    for ($g->all_successors($vertex)) {
        $g->add_edge($vertex, $_);
        connect_downwards($_);
    }
}

my @all_paths;
sub follow_path {
    my ($src, $dst, $path) = @_;
    if ($src eq $dst) {
        push @$path, $src;
        push @all_paths, $path;
    }
    if (grep { $_ eq $src } @$path) { return }
    push @$path, $src;
    for ($g->all_successors($src)) {
        follow_path($_, $dst, [@$path]);
    }
    pop @$path;
}

print "Computing paths...\n";
connect_downwards($dep);
follow_path($dep, $dst, []);
print "Done\n";
# First let's do it the boring way:
my $basic = sum ticket_costs([$dep, $dst]);
printf "Normal ticket: $dep->$dst: %0.2f\n", $basic;
# Now try the other ideas.
my $best = [$dep, $dst];
for (@all_paths) { 
    next if @$_ == 2;
    my @costs = ticket_costs($_);
    my $sum = sum(@costs);
    if ($sum < $basic) {
        $best = $_;
        print " * ";
    }
    print " @$_: ";
    print join " + ", @costs;
    printf " = %0.2f", $sum;
    if ($sum < $basic) { printf " (%2d%% saving!)", 100*($basic-$sum)/$basic }
    print "\n";
}


sub ticket_costs {
    my $route = shift;
    my @costs;
    my $connection;
    if ($time) { # XXX This is a hack
        eval { $connection = Time::Piece->strptime($time, "%F %H:%M"); };
        if ($@) { die "Bad time format" }
    }
    for (0..$#{$route}-1) {
        my ($dep, $dst) = ($route->[$_], $route->[$_+1]);
        push @costs,
        ($cache{"$dep;$dst"} ||= do {
            my @journeys = 
                sort { $a->cheapest cmp $b->cheapest }
                WWW::UKTrains::NationalRail::journeys(
                    dep => $dep,
                    dst => $dst,
                    defined $connection ? (time => $connection) : ()
                );
            $connection = $journeys[0]->end_time;
            $journeys[0]->cheapest;
        })
    }
    return @costs;
}

