#!/usr/bin/perl
# assembler.pl
# Created by ken hua on 2014/4/16
# Usage:
#     Input format: 
#         perl assembler.pl [S file path] [start PC]
#         * example: perl assembler.pl test.S 12
#                    perl assembler.pl test.S 0x200
#         warning: it doesn't work for -0x format
#     Output: a iimage.bin file
#     
# S file content:
#     Note: One line for one instruction.
#
#     Registers format: 
#         It works using register number: $0~$31
#         or register name: $zero $at $t0~$t9 $s0~$s7 $a0~$a3 
#                           $v0~$v1 $k1~$k2 $sp $fp $gp $ra
#         * example: add $t9, $15, $16
#
#     Instructions:
#         space by "," or blanks
#         *example add $9, $9, $9
#                  add $9  $9 $9
#                  add $9, $9 $9
#
#     Values:
#         You can use the expression of hexadecimal or decimal: 
#         * example: slti $9, $8, 0x88
#                    lw   $20,-0x20($0)
#                    addi $29, $29, 4
#         warning: it doesn't work for -0x80000000
#
#     Lables: 
#         A valid label followed by a colon,
#         so you can use it in the branch and jump instruction or not.
#         * example: for1st: add $11, $12, $13
#                            j   for1st
#                            beq $12, $13, -2
#     Comments: 
#         Words behind a comment sign will be ignored
#         * example: add $1, $1 ,$0  # this is a comment
#
#

#test parameters
if($#ARGV!=1){
    print "Argument error.\n";
    print "useage: perl assembler.pl [S file name] [PC start number]\n";
    print "Ex: perl assembler.pl example.S 12\n";
    exit 1;
}

$file=$ARGV[0];
$pc_start=$ARGV[1];

#detect file
if(!-e $file){
    print "$file don't exist.\n";
    exit 1;
}

#detect pc_start
if($pc_start =~ /^0x/){
    $pc_start=hex($pc_start);
}
print "Start PC: $pc_start\n";
#start write iimage.bin
open(OUT,'>:raw',"iimage.bin");

#write pc_start for little-endian of 32bit 
print OUT pack('l<',$pc_start);

open(IN,"$file");
my $num_lines=0;
while(<IN>){
#ingore something
    $_ =~ s/[,()]//g;
    $_ =~ s/\$/ \$/g;
    $_ =~ s/(?<=^)\s+//g;
    $_ =~ s/#.*//g;
    @ina = split /\s+/,$_;
    if($#ina>=0 && $#ina<=4){
        $num_lines++;
    }else{
        print "error: $_";
    }
    if($ina[0] =~ /(.*):/){
        $hash{$1}=$num_lines;
    }
}
print "PC address table:\n";
for(sort {$hash{$a}<=> $hash{$b}} keys %hash){
    print "\t$_: PC=",$pc_start+$hash{$_}*4-4,"\n";
}
print "\n";

print OUT pack('l<',$num_lines);
close(IN);


open(IN,"$file");
$count=0;
while(<IN>){
    # delete comment
    for(0..31){
        $str[$_]=0;
    }
    $_ =~ s/[,()]//g;
    $_ =~ s/\$/ \$/g;
    $_ =~ s/(?<=^)\s+//g;
    $_ =~ s/#.*//g;
    @in = split /\s+/,$_;
    if($in[0] =~ /(\w+):/){shift @in;}
    if($#in<0 || $#in>4){next;}
    print "PC:",$pc_start+$count*4,"\n";
    print "@in","\n";
    for (1..$#in){
        if($in[$_]=~/^-(0[Xx]\w+)/){
            $in[$_]=-1*hex($1);
        }
        elsif($in[$_]=~/^(0[Xx]\w+)/){
            $in[$_]=hex($1);
        }
    }
    &ins;
    my $add=0;
    for(my $i=0;$i<=31;$i+=1){
        if($str[$i]){
            $add+=2**(31-$i);
        }
    }
    print OUT pack('l<',$add);
    $out=sprintf("%08x\n",$add);
    print substr($out,6,2);
    print substr($out,4,2);
    print substr($out,2,2);
    print substr($out,0,2);
    print "\n";
    print join '',@str;
    print "\n";
    print "\n";
    $count++;
}


sub ins{
    if($in[0] eq 'add'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=1; #funct
    }elsif($in[0] eq 'sub'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[30]=1; #funct
    }elsif($in[0] eq 'and'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[29]=1; #funct
    }elsif($in[0] eq 'or'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[29]=$str[31]=1; #funct
    }elsif($in[0] eq 'xor'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[29]=$str[30]=1; #funct
    }elsif($in[0] eq 'nor'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[29]=$str[30]=$str[31]=1; #funct
    }elsif($in[0] eq 'nand'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[28]=1; #funct
    }elsif($in[0] eq 'slt'){
        reg($in[2],6);
        reg($in[3],11);
        reg($in[1],16);
        $str[26]=$str[28]=$str[30]=1; #funct
    }elsif($in[0] eq 'sll'){
        reg($in[2],11);
        reg($in[1],16);
        sha($in[3],21);
        #funct
    }elsif($in[0] eq 'srl'){
        reg($in[2],11);
        reg($in[1],16);
        sha($in[3],21);
        $str[30]=1; #funct
    }elsif($in[0] eq 'sra'){
        reg($in[2],11);
        reg($in[1],16);
        sha($in[3],21);
        $str[30]=$str[31]=1; #funct
    }elsif($in[0] eq 'jr'){
        reg($in[1],6);
        $str[28]=1;           #funct
    }elsif($in[0] eq 'addi'){
        $str[2]=1;
        reg($in[2],6);
        reg($in[1],11);
        binary($in[3],16);
    }elsif($in[0] eq 'lw'){
        $str[0]=$str[4]=$str[5]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'lh'){
        $str[0]=$str[5]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'lhu'){
        $str[0]=$str[3]=$str[5]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'lb'){
        $str[0]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'lbu'){
        $str[0]=$str[3]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'sw'){
        $str[0]=$str[2]=$str[4]=$str[5]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'sh'){
        $str[0]=$str[2]=$str[5]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'sb'){
        $str[0]=$str[2]=1;
        reg($in[3],6);
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'lui'){
        $str[2]=$str[3]=$str[4]=$str[5]=1;
        reg($in[1],11);
        binary($in[2],16);
    }elsif($in[0] eq 'andi'){
        $str[2]=$str[3]=1;
        reg($in[2],6);
        reg($in[1],11);
        binary($in[3],16);
    }elsif($in[0] eq 'ori'){
        $str[2]=$str[3]=$str[5]=1;
        reg($in[2],6);
        reg($in[1],11);
        binary($in[3],16);
    }elsif($in[0] eq 'nori'){
        $str[2]=$str[3]=$str[4]=1;
        reg($in[2],6);
        reg($in[1],11);
        binary($in[3],16);
    }elsif($in[0] eq 'slti'){
        $str[2]=$str[4]=1;
        reg($in[2],6);
        reg($in[1],11);
        binary($in[3],16);
    }elsif($in[0] eq 'beq'){
        $str[3]=1;
        reg($in[1],6);
        reg($in[2],11);
        $jump_site=-1;
        for(keys %hash){
            if($in[3] eq $_){
                $jump_site=$hash{$_}-$count-2;
            }
        }
        if($jump_site == -1){$jump_site=$in[3];}
        binary($jump_site,16);
    }elsif($in[0] eq 'bne'){
        $str[3]=$str[5]=1;
        reg($in[1],6);
        reg($in[2],11);
        $jump_site=-1;
        for(keys %hash){
            if($in[3] eq $_){
                $jump_site=$hash{$_}-$count-2;
            }
        }
        if($jump_site == -1){$jump_site=$in[3];}
        binary($jump_site,16);
    }elsif($in[0] eq 'j'){
        $str[4]=1;
        $jump_site=-1;
        for(keys %hash){
            if($in[1] eq $_){
                $jump_site=$hash{$_}+($pc_start/4)-1;
            }
        }
        if($jump_site == -1){$jump_site=$in[1];}
        address($jump_site,6);
    }elsif($in[0] eq 'jal'){
        $str[4]=$str[5]=1;
        $jump_site=-1;
        for(keys %hash){
            if($in[1] eq $_){
                $jump_site=$hash{$_}+($pc_start/4)-1;
            }
        }
        if($jump_site == -1){$jump_site=$in[1];}
        address($jump_site,6);
    }elsif($in[0] eq 'halt'){
        for(0..31){
            $str[$_]=1;
        }
    }else{
        return 0;
    }
}


sub reg{
    my $a = shift;
    my $b = shift;
    if($a eq '$zero'|$a eq '$0'){
    }elsif($a eq '$at'|$a eq '$1'){
        $str[$b+4]=1;
    }elsif($a eq '$v0'|$a eq '$2'){
        $str[$b+3]=1;
    }elsif($a eq '$v1'|$a eq '$3'){
        $str[$b+3]=$str[$b+4]=1
    }elsif($a eq '$a0'|$a eq '$4'){
        $str[$b+2]=1;
    }elsif($a eq '$a1'|$a eq '$5'){
        $str[$b+2]=$str[$b+4]=1;
    }elsif($a eq '$a2'|$a eq '$6'){
        $str[$b+2]=$str[$b+3]=1; 
    }elsif($a eq '$a3'|$a eq '$7'){
        $str[$b+2]=$str[$b+3]=$str[$b+4]=1;
    }elsif($a eq '$t0'|$a eq '$8'){
        $str[$b+1]=1;
    }elsif($a eq '$t1'|$a eq '$9'){
        $str[$b+1]=$str[$b+4]=1;
    }elsif($a eq '$t2'|$a eq '$10'){
        $str[$b+1]=$str[$b+3]=1;
    }elsif($a eq '$t3'|$a eq '$11'){
        $str[$b+1]=$str[$b+3]=$str[$b+4]=1;
    }elsif($a eq '$t4'|$a eq '$12'){
        $str[$b+1]=$str[$b+2]=1;
    }elsif($a eq '$t5'|$a eq '$13'){
        $str[$b+1]=$str[$b+2]=$str[$b+4]=1;
    }elsif($a eq '$t6'|$a eq '$14'){
        $str[$b+1]=$str[$b+2]=$str[$b+3]=1;
    }elsif($a eq '$t7'|$a eq '$15'){
        $str[$b+1]=$str[$b+2]=$str[$b+3]=$str[$b+4]=1;
    }elsif($a eq '$s0'|$a eq '$16'){
        $str[$b]=1;
    }elsif($a eq '$s1'|$a eq '$17'){
        $str[$b]=$str[$b+4]=1;
    }elsif($a eq '$s2'|$a eq '$18'){
        $str[$b]=$str[$b+3]=1;
    }elsif($a eq '$s3'|$a eq '$19'){
        $str[$b]=$str[$b+3]=$str[$b+4]=1;
    }elsif($a eq '$s4'|$a eq '$20'){
        $str[$b]=$str[$b+2]=1;
    }elsif($a eq '$s5'|$a eq '$21'){
        $str[$b]=$str[$b+2]=$str[$b+4]=1;
    }elsif($a eq '$s6'|$a eq '$22'){
        $str[$b]=$str[$b+2]=$str[$b+3]=1;
    }elsif($a eq '$s7'|$a eq '$23'){
        $str[$b]=$str[$b+2]=$str[$b+3]=$str[$b+4]=1;
    }elsif($a eq '$t8'|$a eq '$24'){
        $str[$b]=$str[$b+1]=1;
    }elsif($a eq '$t9'|$a eq '$25'){
        $str[$b]=$str[$b+1]=$str[$b+4]=1;
    }elsif($a eq '$k0'|$a eq '$26'){
        $str[$b]=$str[$b+1]=$str[$b+3]=1;
    }elsif($a eq '$k1'|$a eq '$27'){
        $str[$b]=$str[$b+1]=$str[$b+3]=$str[$b+4]=1;
    }elsif($a eq '$gp'|$a eq '$28'){
        $str[$b]=$str[$b+1]=$str[$b+2]=1;
    }elsif($a eq '$sp'|$a eq '$29'){
        $str[$b]=$str[$b+1]=$str[$b+2]=$str[$b+4]=1;
    }elsif($a eq '$fp'|$a eq '$30'){
        $str[$b]=$str[$b+1]=$str[$b+2]=$str[$b+3]=1;
    }elsif($a eq '$ra'|$a eq '$31'){
        $str[$b]=$str[$b+1]=$str[$b+2]=$str[$b+3]=$str[$b+4]=1;
    }else{
        die "rgerr";
    }
}
sub binary{
    my $num=shift;
    my $b=shift;
    if ($num < 0){$num+=65536}
    for(my $i=0;$i<=15;$i++){
        if($num>=(2**(15-$i))){
            $str[$b+$i]=1;
            $num-=(2**(15-$i));
        }
    }
}
sub address{
    my $num=shift;
    my $b=shift;
    for(my $i=0;$i<=25;$i++){
        if($num>=(2**(25-$i))){
            $str[$b+$i]=1;
            $num-=(2**(25-$i));
        }
    }
}
sub sha{
    my $num=shift;
    my $b=shift;
    for(my $i=0;$i<=4;$i++){
        if($num>=(2**(4-$i))){
            $str[$b+$i]=1;
            $num-=(2**(4-$i));
        }
    }
}

