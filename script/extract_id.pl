#!usr/bin/perl -w
use strict;
unless (@ARGV==3)
{
    die "perl $0 <ID_InfoList> <fasta.file> <output>\n";
}
open IN1, "$ARGV[0]" or die;
open IN2, "$ARGV[1]" or die;
open OUT, ">$ARGV[2]" or die;

my (@tmp,@k1,@k2,@k3,@k4);
my ($title,$i);

while(<IN1>)
{
	chomp;
	@tmp=split;
	push @k1,$tmp[0];
	push @k2,$tmp[1];
	push @k3,$tmp[2];
	push @k4,$tmp[3];
}

while(<IN2>)
{
	if(/^>/)
	{
		$title=(split /\s+/,$_)[0];
		$title=~s/>//g;
		for($i=0;$i<@k1;$i++)
		{
			if($title eq $k2[$i])
			{
				print OUT ">$k1[$i]_$k3[$i]\n";
			}
		}
	}
	else
	{
		print OUT "$_";
	}
}
