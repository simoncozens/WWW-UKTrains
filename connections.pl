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

my ($dep, $dst) = (@ARGV);
my $g = new Graph::Directed;

my $j = scraper { process "ul>li", "journeys[]" => 
 scraper { process "a", description => 'TEXT', url => '@href' }
 };
my $connections = scraper { process "ul>li", "connections[]" => "TEXT" };
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
for (@all_paths) { 
    my @costs = ticket_costs($_);
    print " @$_: ";
    print join " + ", @costs;
    print " = ", sum(@costs);
    print "\n";
}


sub ticket_costs {
    my $route = shift;
    my @costs;
    for (0..$#{$route}-1) {
        my ($dep, $dst) = ($route->[$_], $route->[$_+1]);
        push @costs,
        ($cache{"$dep;$dst"} ||= do {
            my @journeys = WWW::UKTrains::NationalRail::journeys(
                dep => $dep,
                dst => $dst
            );
            min map { $_->cheapest }@journeys;
        })
    }
    return @costs;
}
