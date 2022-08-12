#!/usr/bin/perl -w 
if( @ARGV != 2  ) 
{
    print "Usage: we need two files\n";
    exit 0;
}
my %hash;
my $ID=shift @ARGV;
my $fasta=shift @ARGV;
open FH1,"<$ID" or die "can not open the file,$!";
while (<FH1>)
{
    chomp;
    $hash{$_}=1;
}
#读取第一个参数，ID列表，每一行的ID都扫描进去hash表
open FH2,"$fasta" or die "can not open the file,$!";
while(defined(my $line=<FH2>))
{
    chomp $line;
    if($line =~ />/)
    {
        $key = (split /\s/,$line)[0];
        $key =~ s/>//g;
        $flag = exists $hash{$key}?1:0;
    }#这个flag是用来控制这个标记下面的序列是否输出

        print $line."\n" if $flag == 1;

}
