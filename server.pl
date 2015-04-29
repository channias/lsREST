#!/usr/bin/perl

=head1

server.pl

=head1 SYNOPSIS

RESTFUL interface for Livestatus

=head1

This server returns JSON data from a livestatus TCP socket via a simple RESTFUL interface

=head1 AUTHOR

2015, Nicolas Chancereul, <nicolas.chancereul@gmail.com>

=head1 Referenced Scripts

http://search.cpan.org/~nierlein/Monitoring-Livestatus-0.74/lib/Monitoring/Livestatus.pm
2009, Sven Nierlein, <nierlein@cpan.org> - Perl Cpan Module

=cut

use strict;
use warnings;
use Pod::Usage;
use Dancer;
use Monitoring::Livestatus;
use Dancer qw/:syntax/;


########################## Functions ##############################
our $ml = Monitoring::Livestatus->new(
    name => config->{peer_name},
    peer => config->{peer_address},
    verbose => 0,
    timeout => 2,
    keepalive => 1,
    query_timeout => 30,
    warnings => 0,
);



sub get_all_hosts {
    my $result = $ml->selectcol_arrayref(
        "GET hosts\nColumns: name"
    );

    return $result;
}

sub get_all_services {
    my $result = $ml->selectall_arrayref(
        "GET services\nColumns: description host_name"
    );

    return $result;
}

sub get_host {
    my $name = shift;

    my $result = $ml->selectrow_hashref(
        "GET hosts\nFilter: name = $name"
    );

    return clear_ls_output($result);
}

sub get_all_services_for_host {
    my $name = shift;

    my $result = $ml->selectcol_arrayref(
        "GET services\nColumns: description\nFilter: host_name = $name"
    );

    return $result;
}

sub get_service_for_host {
    my $name = shift;
    my $description = shift;

    my $result = $ml->selectrow_hashref(
        "GET services\nFilter: host_name = $name\nFilter: description = $description"
    );

    return clear_ls_output($result);
}





sub clear_ls_output {
    my $result = shift;

    my @filtered_col = qw/custom_variable_names custom_variable_values contacts contact_groups host_custom_variable_names host_custom_variable_values host_contacts host_contact_groups/;

    foreach my $colname (@filtered_col) {
        if (exists $result->{$colname}) { delete $result->{$colname}; }
    }

    return $result;
}

########################## Routing ##############################
prefix '/ls';

get '/hosts' => sub {
    my $hosts = get_all_hosts();
    
    return to_json($hosts);
};

get '/hosts/:name' => sub {
    my $host = get_host(param('name'));

    return to_json($host);
};

get '/hosts/:name/services' => sub {
    my $services = get_all_services_for_host(param('name'));

    return to_json($services);
};

get '/hosts/:name/services/:description' => sub {
    my $service = get_service_for_host(param('name'), param('description'));

    return to_json($service);
};

get '/services' => sub {
    my $services = get_all_services();

    return to_json($services);
};



########################## Main ##############################


dance;


__END__
vim: expandtab:ts=4:sw=4
