#!/usr/bin/perl
# dimageMaker.pl
# Created by ken hua on 2014/4/16
# Usage: 
#     Input format: 
#         perl dimageMaker.pl [data file path] [start sp]
#         * example: perl dimageMaker.pl dataMem 0x200
#                    perl dimageMaker.pl dataMem 12
#         warning: it doesn't work for -0x format
#     Output: a dimage.bin file
#
# data file content:
#     hexadecimal or decimal numbers be spaced by a few blanks, tabs, and \n.
#     *example: 0x07        20 11      
#               13
#     warning: it doesn't work for -0x80000000


my $file = $ARGV[0];
my $sp_value = $ARGV[1];

open(IN,"$file");
my @content = <IN>;
close(IN);

chomp @content;
my $data = join ' ',@content;
$data =~ s/(?<=^)\s+//g;
my @values = split /\s+/, $data;

open(OUT,'>:raw',"dimage.bin");

if($sp_value =~ /^0x/){
    $sp_value=hex($sp_value);
}

print "sp: $sp_value\n";
print "value number: ",$#values+1,"\n";

print OUT pack('l<',$sp_value);
print OUT pack('l<',$#values+1);

for(@values){
    if($_ =~ /0[Xx]/){
        if($_=~/^-(0[Xx]\w+)/){
            print OUT pack('l<',-hex($1));
        }
        elsif($_=~/^(0[Xx]\w+)/){
            print OUT pack('l<',hex($1));
        }
    }
    else{
        print OUT pack('l<',$_);
    }
}
close(OUT);

