#!/bin/sh


#  Path to Canu.

bin="/mnt/gvol/langjidong/miniconda3/bin"

#  Report paths.

echo ""
echo "Found perl:"
echo "  " `which perl`
echo "  " `perl --version | grep version`
echo ""
echo "Found java:"
echo "  " `which /mnt/gvol/langjidong/miniconda3/bin/java`
echo "  " `/mnt/gvol/langjidong/miniconda3/bin/java -showversion 2>&1 | head -n 1`
echo ""
echo "Found canu:"
echo "  " $bin/canu
echo "  " `$bin/canu -version`
echo ""


#  Environment for any object storage.

export CANU_OBJECT_STORE_CLIENT=
export CANU_OBJECT_STORE_CLIENT_UA=
export CANU_OBJECT_STORE_CLIENT_DA=
export CANU_OBJECT_STORE_NAMESPACE=
export CANU_OBJECT_STORE_PROJECT=





/mnt/gvol/langjidong/miniconda3/bin/sqStoreCreate \
  -o ./Alpha.canu.seqStore.BUILDING \
  -minlength 1000 \
  -genomesize 30000 \
  -coverage   200 \
  -bias       0 \
  -raw -nanopore Alpha /mnt/users/bioinfo/langjidong/PERL/software/Third-Generation/Pipeline/NanoCoV19/deletion/clean_data/Alpha.fq \
&& \
mv ./Alpha.canu.seqStore.BUILDING ./Alpha.canu.seqStore \
&& \
exit 0

exit 1
