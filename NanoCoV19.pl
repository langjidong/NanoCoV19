#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Long;
use FindBin qw/$Bin/;

sub USAGE
{
    my $usage=<<USAGE;

===============================================
Edit by Jidong Lang; E-mail: langjidong\@hotmail.com;
===============================================

Option
        -fq	<Input File>	Input *.fq file
	-genome_size	<Estimated Genome Size>	Estimated genome size, the unit is kb,mb,gb and so on
        -ngs_polishing	<yes:1|no:0>	Whether need NGS data for polishing, default: 0
	-ngs_file1	<NGS Fastq file1>	The ngs fastq file, such as read_1.fq.gz
	-ngs_file2	<NGS Fastq file2>	The ngs fastq file, such as read_2.fq.gz
	-outputdir	<Output Dir>	The output results pathdir
	-reference	<Reference Genome>	The reference genome of similar species
	-hotspot	<Hotspot Loci List>	The hotspot loci list
        -process	<Number of process used>	N processes to use, default is 1
        -help	print HELP message

Example:

perl $0 -fq nanopore.fq -genome_size 30kb -ngs_polishing 0|<1 -ngs_file1 read_1.fq.gz -ngs_file2 read_2.fq.gz> -outputdir ./outputdir -reference reference.fasta -hotspot hotspot.list -process 16

USAGE
}

unless(@ARGV>5)
{
    die USAGE;
    exit 0;
}


my ($fq,$genome_size,$ngs_polishing,$ngs_file1,$ngs_file2,$outputdir,$reference,$hotspot,$process);
GetOptions
(
    'fq=s'=>\$fq,
    'genome_size=s'=>\$genome_size,
    'ngs_polishing=i'=>\$ngs_polishing,
    'ngs_file1=s'=>\$ngs_file1,
    'ngs_file2=s'=>\$ngs_file2,
    'outputdir=s'=>\$outputdir,
    'reference=s'=>\$reference,
    'hotspot=s'=>\$hotspot,
    'process=i'=>\$process,
    'help'=>\&USAGE,
);

$ngs_polishing ||=0;
$process ||=1;

my $basename=basename($fq);
$basename=~s/(.*).fq/$1/g;

####Data Pre-processing and Quanlity Control-1####
`mkdir $outputdir/clean_data`;
`porechop -t $process -i $fq -o $outputdir/clean_data/$basename.fq`;
`mkdir $outputdir/QC`;
`NanoPlot -t $process --fastq $outputdir/clean_data/$basename.fq --plots hex dot -o $outputdir/QC -p $basename`;
#`NanoFilt -q 5 -l 100 < $outputdir/clean_data/$basename.fq.gz > $outputdir/clean_data/$basename.clean.fq.gz`;

####Multi-Assembly####
`mkdir $outputdir/Assembly`;
####FlyE Assembly####
`mkdir $outputdir/Assembly/FlyE`;
`flye --nano-raw $outputdir/clean_data/$basename.fq --out-dir $outputdir/Assembly/FlyE --genome-size $genome_size --threads $process --iterations 3`;
####FlyE Racon Self Correction####
`mkdir $outputdir/Assembly/Racon`;
`cp $outputdir/Assembly/FlyE/assembly.fasta $outputdir/Assembly/Racon/$basename.flye.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/$basename.flye.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/$basename.flye.fasta > $outputdir/Assembly/Racon/tmp.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/tmp.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp.fasta > $outputdir/Assembly/Racon/tmp-1.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/tmp-1.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp-1.fasta > $outputdir/Assembly/Racon/$basename.flye.racon.fasta`;
`rm -rf $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp.fasta $outputdir/Assembly/Racon/tmp-1.fasta`;

####Canu Assembly####
`mkdir $outputdir/Assembly/Canu`;
`canu -p $basename.canu -d $outputdir/Assembly/Canu genomeSize=$genome_size -nanopore $outputdir/clean_data/$basename.fq`;
####Canu Racon Self Correction####
`cp $outputdir/Assembly/Canu/$basename.canu.contigs.fasta $outputdir/Assembly/Racon/$basename.canu.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/$basename.canu.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/$basename.canu.fasta > $outputdir/Assembly/Racon/tmp.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/tmp.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp.fasta > $outputdir/Assembly/Racon/tmp-1.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/tmp-1.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp-1.fasta > $outputdir/Assembly/Racon/$basename.canu.racon.fasta`;
`rm -rf $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp.fasta $outputdir/Assembly/Racon/tmp-1.fasta`;

####Wtdbg2 Assembly####
`mkdir $outputdir/Assembly/Wtdbg2`;
`wtdbg2 -i $outputdir/clean_data/$basename.fq -t $process -x ont,preset2 -g $genome_size -f -o $outputdir/Assembly/Wtdbg2/$basename`;
`wtpoa-cns -t $process -i $outputdir/Assembly/Wtdbg2/$basename.ctg.lay.gz -f -o $outputdir/Assembly/Wtdbg2/$basename.raw.fa`;
`minimap2 -t $process -a -x map-ont -r2k $outputdir/Assembly/Wtdbg2/$basename.raw.fa $outputdir/clean_data/$basename.fq | samtools sort -@ 16 - > $outputdir/Assembly/Wtdbg2/$basename.bam`;
`samtools view -F0x900 $outputdir/Assembly/Wtdbg2/$basename.bam | wtpoa-cns -t $process -d $outputdir/Assembly/Wtdbg2/$basename.raw.fa -i - -f -o $outputdir/Assembly/Wtdbg2/$basename.cns.fa`;
####Wtdbg2 Racon Self Correction####
`cp $outputdir/Assembly/Wtdbg2/$basename.cns.fa $outputdir/Assembly/Racon/$basename.wtdbg2.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/$basename.wtdbg2.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/$basename.wtdbg2.fasta > $outputdir/Assembly/Racon/tmp.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/tmp.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp.fasta > $outputdir/Assembly/Racon/tmp-1.fasta`;
`minimap2 -a -x map-ont $outputdir/Assembly/Racon/tmp-1.fasta $outputdir/clean_data/$basename.fq -t $process > $outputdir/Assembly/Racon/tmp.sam`;
`racon -t $process $outputdir/clean_data/$basename.fq $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp-1.fasta > $outputdir/Assembly/Racon/$basename.wtdbg2.racon.fasta`;
`rm -rf $outputdir/Assembly/Racon/tmp.sam $outputdir/Assembly/Racon/tmp.fasta $outputdir/Assembly/Racon/tmp-1.fasta`;

####Raven Assembly####
`mkdir $outputdir/Assembly/Raven`;
`raven -t $process -p 3 $outputdir/clean_data/$basename.fq > $outputdir/Assembly/Raven/$basename.raven.fasta`;
`cp $outputdir/Assembly/Raven/$basename.raven.fasta $outputdir/Assembly/Racon/$basename.raven.racon.fasta`;

####Pilon NGS Polishibg####
if($ngs_polishing == 1)
{
	####FlyE Polishing####
	`mkdir $outputdir/Assembly/Pilon`;
	`cp $outputdir/Assembly/Racon/$basename.flye.racon.fasta $outputdir/Assembly/Pilon/$basename.fasta`;
	`bwa index $outputdir/Assembly/Pilon/$basename.fasta`;
	`bwa mem -t $process $outputdir/Assembly/Pilon/$basename.fasta $ngs_file1 $ngs_file2 | samtools sort -@ $process -O bam -o $outputdir/Assembly/Pilon/align.bam -`;
	`/mnt/gvol/langjidong/miniconda3/envs/Python2/bin/sambamba markdup -t $process $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam`;
	`samtools view -b -@ $process -q 30 $outputdir/Assembly/Pilon/align_markdup.bam -o $outputdir/Assembly/Pilon/align_filter.bam`;
	`samtools index -@ $process $outputdir/Assembly/Pilon/align_filter.bam`;
	`rm -rf $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam $outputdir/Assembly/Pilon/align_markdup.bam.bai`;
	`pilon -Xmx4096m -XX:-UseGCOverheadLimit --genome $outputdir/Assembly/Pilon/$basename.fasta --frags $outputdir/Assembly/Pilon/align_filter.bam --vcf --output $outputdir/Assembly/Pilon/$basename.flye.pilon`;
	`rm -rf $outputdir/Assembly/Pilon/$basename.fasta* $outputdir/Assembly/Pilon/align_filter.bam $outputdir/Assembly/Pilon/align_filter.bam.bai`;
	
	####Canu Polishing####
	`cp $outputdir/Assembly/Racon/$basename.canu.racon.fasta $outputdir/Assembly/Pilon/$basename.fasta`;
        `bwa index $outputdir/Assembly/Pilon/$basename.fasta`;
        `bwa mem -t $process $outputdir/Assembly/Pilon/$basename.fasta $ngs_file1 $ngs_file2 | samtools sort -@ $process -O bam -o $outputdir/Assembly/Pilon/align.bam -`;
        `/mnt/gvol/langjidong/miniconda3/envs/Python2/bin/sambamba markdup -t $process $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam`;
        `samtools view -b -@ $process -q 30 $outputdir/Assembly/Pilon/align_markdup.bam -o $outputdir/Assembly/Pilon/align_filter.bam`;
        `samtools index -@ $process $outputdir/Assembly/Pilon/align_filter.bam`;
        `rm -rf $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam $outputdir/Assembly/Pilon/align_markdup.bam.bai`;
        `pilon -Xmx4096m -XX:-UseGCOverheadLimit --genome $outputdir/Assembly/Pilon/$basename.fasta --frags $outputdir/Assembly/Pilon/align_filter.bam --vcf --output $outputdir/Assembly/Pilon/$basename.canu.pilon`;
        `rm -rf $outputdir/Assembly/Pilon/$basename.fasta* $outputdir/Assembly/Pilon/align_filter.bam $outputdir/Assembly/Pilon/align_filter.bam.bai`;
	
	####Wtdbg2 Polishing####
        `cp $outputdir/Assembly/Racon/$basename.wtdbg2.racon.fasta $outputdir/Assembly/Pilon/$basename.fasta`;
        `bwa index $outputdir/Assembly/Pilon/$basename.fasta`;
        `bwa mem -t $process $outputdir/Assembly/Pilon/$basename.fasta $ngs_file1 $ngs_file2 | samtools sort -@ $process -O bam -o $outputdir/Assembly/Pilon/align.bam -`;
        `/mnt/gvol/langjidong/miniconda3/envs/Python2/bin/sambamba markdup -t $process $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam`;
        `samtools view -b -@ $process -q 30 $outputdir/Assembly/Pilon/align_markdup.bam -o $outputdir/Assembly/Pilon/align_filter.bam`;
        `samtools index -@ $process $outputdir/Assembly/Pilon/align_filter.bam`;
        `rm -rf $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam $outputdir/Assembly/Pilon/align_markdup.bam.bai`;
        `pilon -Xmx4096m -XX:-UseGCOverheadLimit --genome $outputdir/Assembly/Pilon/$basename.fasta --frags $outputdir/Assembly/Pilon/align_filter.bam --vcf --output $outputdir/Assembly/Pilon/$basename.wtdbg2.pilon`;
        `rm -rf $outputdir/Assembly/Pilon/$basename.fasta* $outputdir/Assembly/Pilon/align_filter.bam $outputdir/Assembly/Pilon/align_filter.bam.bai`;

        ####Raven Polishing####
        `cp $outputdir/Assembly/Racon/$basename.raven.racon.fasta $outputdir/Assembly/Pilon/$basename.fasta`;
        `bwa index $outputdir/Assembly/Pilon/$basename.fasta`;
        `bwa mem -t $process $outputdir/Assembly/Pilon/$basename.fasta $ngs_file1 $ngs_file2 | samtools sort -@ $process -O bam -o $outputdir/Assembly/Pilon/align.bam -`;
        `/mnt/gvol/langjidong/miniconda3/envs/Python2/bin/sambamba markdup -t $process $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam`;
        `samtools view -b -@ $process -q 30 $outputdir/Assembly/Pilon/align_markdup.bam -o $outputdir/Assembly/Pilon/align_filter.bam`;
        `samtools index -@ $process $outputdir/Assembly/Pilon/align_filter.bam`;
        `rm -rf $outputdir/Assembly/Pilon/align.bam $outputdir/Assembly/Pilon/align_markdup.bam $outputdir/Assembly/Pilon/align_markdup.bam.bai`;
        `pilon -Xmx4096m -XX:-UseGCOverheadLimit --genome $outputdir/Assembly/Pilon/$basename.fasta --frags $outputdir/Assembly/Pilon/align_filter.bam --vcf --output $outputdir/Assembly/Pilon/$basename.raven.pilon`;
        `rm -rf $outputdir/Assembly/Pilon/$basename.fasta* $outputdir/Assembly/Pilon/align_filter.bam $outputdir/Assembly/Pilon/align_filter.bam.bai`;

	####Combination Results####
	`mkdir $outputdir/Trycycler`;
	`cp $outputdir/Assembly/Pilon/$basename.flye.pilon.fasta $outputdir/Trycycler/$basename.flye.trycycler.fasta`;
	`cp $outputdir/Assembly/Pilon/$basename.canu.pilon.fasta $outputdir/Trycycler/$basename.canu.trycycler.fasta`;
	`cp $outputdir/Assembly/Pilon/$basename.wtdbg2.pilon.fasta $outputdir/Trycycler/$basename.wtdbg2.trycycler.fasta`;
	`cp $outputdir/Assembly/Pilon/$basename.raven.pilon.fasta $outputdir/Trycycler/$basename.raven.trycycler.fasta`;
}
else
{
	`mkdir $outputdir/Trycycler`;
	`cp $outputdir/Assembly/Racon/$basename.flye.racon.fasta $outputdir/Trycycler/$basename.flye.trycycler.fasta`;
	`cp $outputdir/Assembly/Racon/$basename.canu.racon.fasta $outputdir/Trycycler/$basename.canu.trycycler.fasta`;
	`cp $outputdir/Assembly/Racon/$basename.wtdbg2.racon.fasta $outputdir/Trycycler/$basename.wtdbg2.trycycler.fasta`;
	`cp $outputdir/Assembly/Racon/$basename.raven.racon.fasta $outputdir/Trycycler/$basename.raven.trycycler.fasta`;
}

####Trycycler Consensus Assemblies####
`mv $outputdir/Trycycler/$basename.canu.trycycler.fasta $outputdir/Trycycler/$basename.canu.trycycler.fasta-raw`;    ####Delete this line####
`mkdir $outputdir/Trycycler/cluster-step1`;
`trycycler cluster -a $outputdir/Trycycler/*.fasta -r $outputdir/clean_data/$basename.fq -o $outputdir/Trycycler/cluster-step1`;
`trycycler reconcile -r $outputdir/clean_data/$basename.fq -c $outputdir/Trycycler/cluster-step1/cluster_001/ -t $process`;
`trycycler msa -c $outputdir/Trycycler/cluster-step1/cluster_001/ -t $process`;
`trycycler partition -r $outputdir/clean_data/$basename.fq -c $outputdir/Trycycler/cluster-step1/cluster_001/ -t $process`;
`trycycler consensus -c $outputdir/Trycycler/cluster-step1/cluster_001/ -t $process`;
`trycycler dotplot -c $outputdir/Trycycler/cluster-step1/cluster_001/`;
`cat $outputdir/Trycycler/cluster-step1/cluster_*/7_final_consensus.fasta > $outputdir/Trycycler/$basename.consensus.fasta`;

####Construct Phygenetic Tree####
`mkdir $outputdir/MSA-PhyTree`;
`less $outputdir/Trycycler/$basename.consensus.fasta|perl -e 'while(<>) {chomp; \$_=~s/^>(.*)/>$basename/g; print "\$_\n";}' > $outputdir/MSA-PhyTree/tmp.fasta`;
`cat $outputdir/MSA-PhyTree/tmp.fasta /mnt/nas/bioinfo/langjidong/PERL/software/Third-Generation/Pipeline/NanoCoV19/Ref_Database/all.fasta > $outputdir/MSA-PhyTree/all.fasta`;
`rm -rf $outputdir/MSA-PhyTree/tmp.fasta`;
`mafft --auto --thread -1 $outputdir/MSA-PhyTree/all.fasta > $outputdir/MSA-PhyTree/SARS-CoV-2.MSA`;
`iqtree2 -s $outputdir/MSA-PhyTree/SARS-CoV-2.MSA --alrt 1000 -B 1000 -T AUTO`;

####Variant Calling####
`mkdir $outputdir/Mutation`;
`minimap2 -a -x map-ont $reference $outputdir/clean_data/$basename.fq -t $process > $outputdir/Mutation/$basename.sam`;
`/mnt/gvol/langjidong/miniconda3/envs/Python2/bin/sambamba view -h -S --format=bam -t $process $outputdir/Mutation/$basename.sam > $outputdir/Mutation/$basename.bam`;
`/mnt/gvol/langjidong/miniconda3/envs/Python2/bin/sambamba sort -t $process $outputdir/Mutation/$basename.bam -o $outputdir/Mutation/$basename.sort.bam`;
`/mnt/nas/bioinfo/langjidong/PERL/resequencing/bin1/reseq/CNV/soap.coverage -cvg -p $process -sam -i $outputdir/Mutation/$basename.sam -refsingle $reference -o $outputdir/QC/$basename.coverage.txt`;
`rm -rf $outputdir/Mutation/$basename.sam $outputdir/Mutation/$basename.bam $outputdir/Mutation/$basename.bam.bai`;
`samtools depth -a --reference $reference -b $reference.bed -d 1000000 -o $outputdir/QC/$basename.depthstat.txt $outputdir/Mutation/$basename.sort.bam`;
`longshot --bam $outputdir/Mutation/$basename.sort.bam --ref $reference --out $outputdir/Mutation/$basename.vcf --stable_alignment --min_cov 4 --max_cov 20000 --min_alt_frac 0.01`;
`less $hotspot|while read a;do less $outputdir/Mutation/$basename.vcf|grep -v "\#"|awk '{print \$4\$2\$5}'|grep "\${a}";done > $outputdir/Mutation/$basename.hotspot.txt`;
