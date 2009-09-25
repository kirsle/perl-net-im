#!/usr/bin/perl -w

use strict;
use warnings;
use lib "./lib";


use Data::Dumper;

use Net::IM::Client::TestClient;
my $client = new Net::IM::Client::TestClient();

$client->show_name();
#print Dumper($client);
