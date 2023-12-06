# NanoCoV19
NanoCoV19: An Analytical Pipeline for Rapid Detection of Severe Acute Respiratory Syndrome Coronavirus 2 (SARS-CoV-2)

NanoCoV19 is an analytical pipeline for SARS-CoV-2 rapid detection and lineage identification that integrates phylogenetic-tree and hotspot mutation analysis. This method not only can distinguish and trace the lineages contained in the alpha, beta, delta, gamma, lambda, and omicron variants of SARS-CoV-2 but is also rapid and efficient, completing overall analysis within 1 h. We hope that NanoCoV19 can be used as an auxiliary tool for rapid subtyping and pedigree analysis of SARS-CoV-2 and, more importantly, that it can promote further applications of NST in public-health and -safety plans similar to those formulated to address the COVID-19 outbreak.

Option

        -fq                 <Input File>                  Input *.fq file
        -genome_size        <Estimated Genome Size>       Estimated genome size, the unit is kb,mb,gb and so on
        -ngs_polishing      <yes:1|no:0>                  Whether need NGS data for polishing, default: 0
        -ngs_file1          <NGS Fastq file1>             The ngs fastq file, such as read_1.fq.gz
        -ngs_file2          <NGS Fastq file2>             The ngs fastq file, such as read_2.fq.gz
        -outputdir          <Output Dir>                  The output results pathdir
        -reference          <Reference Genome>            The reference genome of similar species
        -hotspot            <Hotspot Loci List>           The hotspot loci list
        -process            <Number of process used>      N processes to use, default is 1
        -help                                             print HELP message


Example:<br>
**perl NanoCoV19.pl -fq nanopore.fq -genome_size 30kb -ngs_polishing 0|<1 -ngs_file1 read_1.fq.gz -ngs_file2 read_2.fq.gz> -outputdir ./outputdir -reference reference.fasta -hotspot hotspot.list -process 16**

The method is still under further optimization and development, please contact us if you have any good suggestions and questions.<br>
***Contact and E-mail: langjidong@hotmail.com***

**Publications**

Lang J. NanoCoV19: An analytical pipeline for rapid detection of severe acute respiratory syndrome coronavirus 2. Front Genet. 2022 Sep 15;13:1008792. doi: 10.3389/fgene.2022.1008792. PMID: 36186464; PMCID: PMC9520466.
