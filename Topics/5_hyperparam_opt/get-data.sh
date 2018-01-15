#!/bin/bash
set -eu

# TOPICS 5 GET DATA

if [ ${#} != 1 ]
then
  echo "usage: get-data.sh <BENCHMARKS>"
  exit 1
fi

cd $1
mkdir -pv Data/Pilot1
cd Data/Pilot1

echo "Downloading bulk data to: $( /bin/pwd )"
sleep 2
echo

COMBO=http://ftp.mcs.anl.gov/pub/candle/public/benchmarks/Pilot1/combo

FILES=(
  ALMANAC_drug_descriptors_dragon7.txt
  ComboDrugGrowth.txt
  GDSC_PubChemCID_drug_descriptors_dragon7
  GDSC_drugs
  GSE32474_U133Plus2_GCRMA_gene_median.txt
  NCI60_CELLNAME_to_Combo.new.txt
  NCI60_CELLNAME_to_Combo.txt
  NCI60_drug_sets.tsv
  NCI_IOA_AOA_drug_descriptors_dragon7
  NCI_IOA_AOA_drugs
  combined_rnaseq_data
  combined_rnaseq_data_lincs1000
  lincs1000.tsv
  new_descriptors.txt
)

for FILE in ${FILES[@]}
do
  echo "Downloading: $COMBO/$FILE"
  wget --no-verbose $COMBO/$FILE
  echo
done
