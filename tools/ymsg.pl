#!/usr/bin/perl

use Term::ANSIColor;
use Socket;
use Data::Dumper;

use Constants ':all';

$|++;

$/ = '#';

open(NG,"ngrep -x -ltd en0 ^YMSG |");
#open(NG,"ngrep -x -ltd en0 ^YMSG |");

while(<NG>) {
    s/#$//;
    my $packet = $_;

    my $data = '';

    if($packet =~ m/T/){
        my @rows = split("\n", $packet);
        # extra row
        shift @rows;
        my $header = shift @rows;
        $header =~ s/\s->//;
        my (undef, $date, $time, $from, $to, undef)  = split(' ', $header); 
        
        my $color = ($to =~ m/\:5050/)?'green':'red';
        print colored ("From: $from : To: $to at: $time\n\n".join("\n",@rows)."\n\n", $color);

        foreach my $row (@rows){
            my ($chunk) = $row =~ /(.{52})/;
            $chunk =~ s/\s//gs;
            $data .= $chunk;
        }
        
        my $packet = {};
        
        $data =~ s/([a-fA-F0-9]{2})/chr(hex $1)/eg;
        my $packet_data = '';

        my $sep = "\xC0\x80";
        ($packet->{signature},
        $packet->{version},
        $packet->{flag},
        $packet->{length},
        $packet->{event_code},
        $packet->{ret},
        $packet->{identifier},$packet_data) = unpack("a4n4NVa*",$data);
       
        my $p_packet_data = $packet_data;
        $p_packet_data =~ s/\Q$sep\E/&/g;

        print colored ("PACKET Data: $p_packet_data\n\n", $color);

        $packet->{event_string} = sprintf("0x%02X", $packet->{event_code}).": ".Constants::getNameByValue($packet->{event_code});

        # print the raw packet dump
        $Data::Dumper::Varname  = 'Packet_';
        print colored (Dumper($packet), $color);

        my @bits = split(/\Q$sep\E/, $packet_data);        
        # The eventual hashref.
        my $map = {};
        for (my $i = 0; $i < scalar(@bits); $i += 2) {
            if (exists $map->{ $bits[$i] }) {
                # More than one field with the same number!
                if (ref $map->{ $bits[$i] } ne "ARRAY") {
                     $map->{ $bits[$i] } = [ $map->{$bits[$i]} ];
                }
                push (@{$map->{ $bits[$i] }}, $bits[ $i + 1 ]);
            }
            else {
                $map->{ $bits[$i] } = $bits[ $i + 1 ];
            }
        }
        #print Dumper($map);
        $Data::Dumper::Varname = 'PacketData_';
        print colored (Dumper($map), $color);
        print "------------------------------------------------------------\n";
    }
}
