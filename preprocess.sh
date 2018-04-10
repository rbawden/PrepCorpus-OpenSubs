#!/bin/sh

# this sample script preprocesses a sample corpus, including tokenization,
# truecasing, and subword segmentation.
# for application to a different language pair,
# change source and target prefix, optionally the number of BPE operations,

# suffix of source language files
SRC=fr

# suffix of target language files
TRG=en

# number of merge operations. Network vocabulary should be slightly larger (to include characters),
# or smaller if the operations are learned on the joint vocabulary
bpe_operations=90000

#minimum number of times we need to have seen a character sequence in the training text before we merge it into one unit
#this is applied to each training text independently, even with joint BPE
bpe_threshold=50

# path to moses decoder: https://github.com/moses-smt/mosesdecoder
mosesdecoder=/path/to/tools/mosesdecoder

# path to subword segmentation scripts: https://github.com/rsennrich/subword-nmt
subword_nmt=/path/to/tools/subword-nmt

# path to nematus ( https://www.github.com/rsennrich/nematus )
nematus=/path/to/tools/nematus

# path to your main data folder (in which the corpus can be found)
datadir=/path/to/datadir

# train prefix (depending on the name of the files) E.g. 
train_prefix=train
dev_prefix= dev
test_prefix=test

# tokenize

for prefix in $datadir/train $datadir/dev $datadir/test
 do
   cat $datadir/$prefix.$SRC | \
   $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $SRC | \
   $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $SRC > $datadir/$prefix.tok.$SRC

   cat $datadir/$prefix.$TRG | \
   $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $TRG | \
   $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $TRG > $datadir/$prefix.tok.$TRG

 done

# clean empty and long sentences, and sentences with high source-target ratio (training corpus only)
$mosesdecoder/scripts/training/clean-corpus-n.perl $datadir/$train_prefix.tok $SRC $TRG $datadir/$train_prefix.tok.clean 1 80

# train truecaser
$mosesdecoder/scripts/recaser/train-truecaser.perl -corpus $datadir/$train_prefix.tok.clean.$SRC -model model/truecase-model.$SRC
$mosesdecoder/scripts/recaser/train-truecaser.perl -corpus $datadir/$train_prefix.tok.clean.$TRG -model model/truecase-model.$TRG

# apply truecaser (cleaned training corpus)
for prefix in $train_prefix 
 do
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$SRC < $datadir/$prefix.tok.clean.$SRC > $datadir/$prefix.tc.$SRC
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$TRG < $datadir/$prefix.tok.clean.$TRG > $datadir/$prefix.tc.$TRG
 done

# apply truecaser (dev/test files)
for prefix in $dev_prefix $test_prefix
 do
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$SRC < $datadir/$prefix.tok.$SRC > $datadir/$prefix.tc.$SRC
  $mosesdecoder/scripts/recaser/truecase.perl -model model/truecase-model.$TRG < $datadir/$prefix.tok.$TRG > $datadir/$prefix.tc.$TRG
 done

# train BPE
$subword_nmt/learn_joint_bpe_and_vocab.py -i $datadir/$train_prefix.tc.$SRC $datadir/$train_prefix.tc.$TRG --write-vocabulary $datadir/vocab.$SRC $datadir/vocab.$TRG -s $bpe_operations -o model/$SRC$TRG.bpe

# apply BPE

for prefix in $train_prefix $dev_prefix $test_prefix
 do
  $subword_nmt/apply_bpe.py -c model/$SRC$TRG.bpe --vocabulary $datadir/vocab.$SRC --vocabulary-threshold $bpe_threshold < $datadir/$prefix.tc.$SRC > $datadir/$prefix.bpe.$SRC
  $subword_nmt/apply_bpe.py -c model/$SRC$TRG.bpe --vocabulary $datadir/vocab.$TRG --vocabulary-threshold $bpe_threshold < $datadir/$prefix.tc.$TRG > $datadir/$prefix.bpe.$TRG
 done

# build network dictionary
$nematus/$datadir/build_dictionary.py $datadir/$train_prefix.bpe.$SRC $datadir/$train_prefix.bpe.$TRG

