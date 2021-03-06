#!/bin/bash

FILE=~/chrPos2rsIDdbSNP147CommonPlusRareVariants/dbSNP147allSNPs
DIR=~/chrPos2rsIDdbSNP147CommonPlusRareVariants
SNPS=$(pwd)/$1
echo Proccesing file:
echo $SNPS 

#check if working folder exist, if not, create

if [ ! -d $DIR ]
then
mkdir ~/chrPos2rsIDdbSNP147CommonPlusRareVariants
fi

cd ~/chrPos2rsIDdbSNP147CommonPlusRareVariants

#check if dbsnp file exists, if not, download from snp147Common table using mysql

if [ ! -f $FILE ]
then
wget https://www.dropbox.com/s/tb1q19vdvgnq4tu/dbSNP147allSNPs.gz?dl=0

fi

tabsep $SNPS
sed 's/^/chr/g' $SNPS | sed -e 's/_[ATCG]*/\t/' | sed -e 's/_[ATCG]*//' | sed 's/_.//' > $1.mod
sed 's/^MarkerName/chr\tposition\t/g' <(head -n1 $SNPS) > $1.head
cat $1.head <(tail -n+2 $1.mod) > $1.mod2
mv $1.mod2 $1.mod
tabsep $1.mod
tail -n+2 $1.mod > $1.mod2
head -n1 $1.mod > $1.head

#parse dbSNPs into insertions, SNPs and simple deletions, large deletions

if [ ! -f snp147Common.bed.insertions ]
then
awk '$2 == $3 {print $0}' dbSNP147allSNPs > snp147Common.bed.insertions
fi

if [ ! -f snp147Common.bed.snp.plus.simple.deletions ]
then
awk '$3 == $2+1 {print $0}' dbSNP147allSNPs > snp147Common.bed.snp.plus.simple.deletions
fi

if [ ! -f snp147Common.bed.large.deletions ]
then
awk '{if ($3 != $2+1 && $2 != $3) print $0}' dbSNP147allSNPs > snp147Common.bed.large.deletions
fi

#find positions of snps from the input list by comparing to snpdb

awk 'NR==FNR {h1[$1] = $1; h2[$2]=$2; h3[$1$2]=$4; h4[$1$2]=1; next} {if(h2[$2]==$2 && h1[$1]==$1 && h4[$1$2]==1) print h3[$1$2]"\t"$0}' snp147Common.bed.insertions $1.mod2 > $1.rsID.nohead.insertions
awk 'NR==FNR {h1[$1] = $1; h2[$3]=$3; h3[$1$3]=$4; h4[$1$3]=1; next} {if(h2[$2]==$2 && h1[$1]==$1 && h4[$1$2]==1) print h3[$1$2]"\t"$0}' snp147Common.bed.snp.plus.simple.deletions $1.mod2 > $1.rsID.nohead.snp.plus.simple.deletions
awk 'NR==FNR {h1[$1] = $1; h2[$3]=$3; h3[$1$3]=$4; h4[$1$3]=1; next} {if(h2[$2]==$2 && h1[$1]==$1 && h4[$1$2]==1) print h3[$1$2]"\t"$0}' snp147Common.bed.large.deletions $1.mod2 > $1.rsID.nohead.large.deletions

#merge insertions, SNPs and simple deletions, large deletions

cat $1.rsID.nohead.insertions $1.rsID.nohead.snp.plus.simple.deletions $1.rsID.nohead.large.deletions > $1.rsID

sed -i '1s/^/rsID\t/' $1.head
cat $1.head $1.rsID > $1.rsID.final

rm $1.mod
rm $1.mod2
rm $1.head
