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









#  Discover the job ID to run, from either a grid environment variable and a
#  command line offset, or directly from the command line.
#
if [ x$CANU_LOCAL_JOB_ID = x -o x$CANU_LOCAL_JOB_ID = xundefined -o x$CANU_LOCAL_JOB_ID = x0 ]; then
  baseid=$1
  offset=0
else
  baseid=$CANU_LOCAL_JOB_ID
  offset=$1
fi
if [ x$offset = x ]; then
  offset=0
fi
if [ x$baseid = x ]; then
  echo Error: I need CANU_LOCAL_JOB_ID set, or a job index on the command line.
  exit
fi
jobid=`expr -- $baseid + $offset`
if [ x$CANU_LOCAL_JOB_ID = x ]; then
  echo Running job $jobid based on command line options.
else
  echo Running job $jobid based on CANU_LOCAL_JOB_ID=$CANU_LOCAL_JOB_ID and offset=$offset.
fi

if [ -e ../Alpha.canu.ctgStore/seqDB.v001.tig ] ; then
  exit 0
fi

#
#  Check if the outputs exist.
#
#  The boilerplate function for doing this fails if the file isn't
#  strictly below the current directory, so some gymnastics is needed.
#

cd ..

if [ -e Alpha.canu.ctgStore/seqDB.v001.tig ]; then
  exists=true
else
  exists=false
fi

cd 4-unitigger

#
#  Run if needed.
#

if [ $exists = false ] ; then
  $bin/bogart \
    -S ../../Alpha.canu.seqStore \
    -O    ../Alpha.canu.ovlStore \
    -o     ./Alpha.canu \
    -gs 30000 \
    -eg 0.12 \
    -eM 0.12 \
    -mo 500 \
    -covgapolap 500 \
    -covgaptype deadend \
    -lopsided 25  \
    -minolappercent   0.0  \
    -dg 12 \
    -db 1 \
    -dr 1 \
    -ca 2500 \
    -cp 15 \
    -threads 4 \
    -M 16 \
    -unassembled 2 0 1.0 0.5 3 \
    > ./unitigger.err 2>&1 \
  && \
  mv ./Alpha.canu.ctgStore ../Alpha.canu.ctgStore
fi

if [ ! -e ../Alpha.canu.ctgStore ] ; then
  echo bogart appears to have failed.  No Alpha.canu.ctgStore found.
  exit 1
fi

if [ ! -e ../Alpha.canu.ctgStore/seqDB.v001.sizes.txt ] ; then
  $bin/tgStoreDump \
    -S ../../Alpha.canu.seqStore \
    -T ../Alpha.canu.ctgStore 1 \
    -sizes -s 30000 \
   > ../Alpha.canu.ctgStore/seqDB.v001.sizes.txt
fi


cd ../Alpha.canu.ctgStore
cd -


exit 0
