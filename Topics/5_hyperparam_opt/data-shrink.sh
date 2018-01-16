#!/bin/bash
set -eu

# DATA SHRINK

usage()
{
  echo "usage: data-shrink.sh <DIRECTORY>"
  exit 1
}

if [ ${#} != 1 ]
then
  usage
  exit 1
fi

DIRECTORY=$1
FRACTION=0.10

if ! [ -d $DIRECTORY ]
then
  echo "DIRECTORY=$DIRECTORY does not exist!"
  exit 1
fi

cd $DIRECTORY

TEST_CSV=nt_test2.csv
TRAIN_CSV=nt_train2.csv

if ! [ -f $TRAIN_CSV ]
then
  echo "Could not find $TRAIN_CSV!"
  exit 1
fi

mv -v $TRAIN_CSV $TRAIN_CSV.original
mv -v $TEST_CSV  $TEST_CSV.original

# We use awk just to do a floating point multiplication

TOTAL=$( wc -l < $TRAIN_CSV.original )
set -x
SHRUNK=$( awk "BEGIN { print int( $TOTAL * $FRACTION ) }" /dev/null )
echo "shrinking $TRAIN_CSV from $TOTAL to $SHRUNK"
head -n $SHRUNK $TRAIN_CSV.original > $TRAIN_CSV

TOTAL=$( wc -l < $TEST_CSV.original )
SHRUNK=$( awk "BEGIN { print int( $TOTAL * $FRACTION ) }" /dev/null )
echo "shrinking $TEST_CSV from $TOTAL to $SHRUNK"
head -n $SHRUNK $TEST_CSV.original > $TEST_CSV

echo "OK"
