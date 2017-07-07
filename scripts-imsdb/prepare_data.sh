
# Author: Rachel Bawden
# Contact: rachel.bawden@limsi.fr
# Last modif: 13/06/2017


#---------------------------------------------------------------------
mypython2=/Users/rbawden/Documents/pyenvs/py2.7/bin/python
mypython3=/Users/rbawden/Documents/pyenvs/py3.5/bin/python

SRC="fr"
TRG="en"

# alignmentfile=/Users/rbawden/Documents/data/parallel/OpenSubtitles2016/alignments.fr-en.xml.gz
datadir=/Volumes/Mammoth/data/
opensubs_dir=$datadir/OpenSubtitles2016 #"/Users/rbawden/Documents/data/parallel/OpenSubtitles2016/raw"
working_dir=/Users/rbawden/phd/OpenSubs2016_notes/data
SCRIPTS=/Users/rbawden/phd/OpenSubs2016_notes/scripts/corpus
champollion=/Users/rbawden/Documents/tools/champollion-1.2/

# can ignore the generation of data if false (otherwise write true to regenerate)
redoImsdb=false


#---------------------------------------------------------------------
# 0. make directories if necessary
#---------------------------------------------------------------------
[ -d $datadir ] || mkdir $datadir
[ -d $working_dir/opensubs_all ] || mkdir $working_dir/opensubs_all
[ -d $working_dir/opensubs_minusimsdb ] || mkdir $working_dir/opensubs_minusimsdb
[ -d $working_dir/opensubs_train ] || mkdir $working_dir/opensubs_train
[ -d $working_dir/opensubs_dev ] || mkdir $working_dir/opensubs_dev
[ -d $working_dir/imsdb ] || mkdir $working_dir/imsdb
[ -d $working_dir/scripts ] || mkdir $working_dir/scripts
[ -d $working_dir/structured_scripts ] || mkdir $working_dir/structured_scripts
[ -d $working_dir/alignments ] || mkdir $working_dir/alignments


#---------------------------------------------------------------------
# 1. get imsdb data and character lists
#---------------------------------------------------------------------
if [ "$redoImsdb" = true ]; then
	# get imdb numbers of available imsdb films
	$mypython2 $SCRIPTS/crawl_imsdb.py \
			   -n $working_dir/imsdb/all.nums-titles.json \
			   $working_dir/imsdb/scripts/
	
	# get characters (w/ actor information) for all imsdb films
	if [ ! -f $working_dir/imsdb/all.characters.json ]; then
		$mypython3 $SCRIPTS/crawl_imsdb.py \
				   -m $working_dir/imsdb/all.nums-titles.json \
				   $working_dir/imsdb/all.characters.json
	fi

	# extract scripts and structure them
	$mypython2 $SCRIPTS/crawl_imsdb.py \
			   -s $working_dir/imsdb/all.nums-titles.json \
			   $working_dir/imsdb/scripts/ \
			   $working_dir/imsdb/structured_scripts/ \
			   $working_dir/imsdb/all_imsdb.imdb2characters.metainfo.json
fi


#---------------------------------------------------------------------
# 3. Remove imsdb films from Opensubs train set
#---------------------------------------------------------------------
echo ">> Getting line numbers of imsdb films in OpenSubs"

# # get the line numbers of remaining OpenSubs films
# $mypython2 $SCRIPTS/get_inverse_numbers.py \
# 		   $working_dir/imsdb/all.nums-titles.json \
# 		   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
# 		   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list


# echo ">> Removing IMSDB films from OpenSubs2016 corpus (opensubs_minusimsdb/)"

# # get the sentences corresponding to those line numbers
# $mypython3 $SCRIPTS/get-these-lines-from-numbers.py \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC \
# 		   $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC


# $mypython3 $SCRIPTS/get-these-lines-from-numbers.py \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG \
# 		   $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG

# # get filminfo for just these films
# $mypython2 $SCRIPTS/get_inverse_numbers.py \
# 		   $working_dir/imsdb/all.nums-titles.json\
# 		   --printfilminfo \
# 		   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
# 		   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo


# echo ">> Stocking film info and line numbers for imsdb scripts (imsdb/)"

# # get the line numbers of imsdb films
# $mypython2 $SCRIPTS/get_inverse_numbers.py -v \
# 		   $working_dir/imsdb/all.nums-titles.json \
# 		   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
# 		   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo \
# 		   > $working_dir/imsdb/imsdb.$SRC-$TRG.list

# # get filminfo for just these films
# $mypython2 $SCRIPTS/get_inverse_numbers.py -v \
# 		   $working_dir/imsdb/all.nums-titles.json \
# 		   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
# 		   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo \
# 		   > $working_dir/imsdb/imsdb.$SRC-$TRG.filminfo

#---------------------------------------------------------------------
# 4. Remove 5000 films from OpenSubs to use as dev if necessary
#---------------------------------------------------------------------

# echo ">> Separating out last 5000 films from OpenSubs2016-IMSDB to make dev set (opensubs_train/ and opensubs_dev/)"

# lastline=`tail -5000 $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo | head -1 | cut -f 2 `
# firstfilms=`tail -5000 $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo | head -1 | cut -f 1 `

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC \
# 	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.$SRC

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG \
# 	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.$TRG

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo \
# 	| sed -n "${firstfilms},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.filminfo

# lastline=$(($lastline-1))
# firstfilms=$(($firstfilms-1))
		
# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC \
# 	| sed -n "1,${lastline}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.$SRC

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG \
# 	| sed -n "1,${lastline}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.$TRG

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo \
# 	| sed -n "1,${firstfilms}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.filminfo


#---------------------------------------------------------------------
# 5. Now try to align opensubs and imsdb scripts using Champollion
#---------------------------------------------------------------------
export CTK=$champollion

# make a champollion dictionary from monolingual English data
# if [ ! -f $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.en ]; then
# 	echo >> "You need to generate an English monolingual corpus to train champollion"
# else
# 	python $SCRIPTS/create-monolingual-champolion-dict.py \
# 		   --corpus "$working_dir/opensubs_train/opensubs.train.$SRC-$TRG.en" \
# 		   --dict "$working_dir/en-en.champdict"
# fi

# transfer champollion script to champollion directory
cp $SCRIPTS/champollion.EN_EN $champollion/bin/

# then align all films
ss_dir=$working_dir/imsdb/structured_scripts
tmpfolder="$working_dir/"

# go through and align all files
for fname in $ss_dir/*; do
	fname=${fname##*/}
	basename=${fname%.*}
	
	year="`echo "$basename" |cut -d. -f1`"
	imdb="`echo "$basename" |cut -d. -f2 | perl -pe 's/^0+//'`"
	echo "ls $opensubs_dir/raw/en/$year/$imdb/*.xml.gz 2>/dev/null | head -1"
	osfile=`ls $opensubs_dir/raw/en/$year/$imdb/*.xml.gz 2>/dev/null | head -1`

	echo "Imsdb file = '$fname', OpenSubs file = '$osfile'"
	
	# do not continue if blank	
	if [ -n "$osfile" ]; then
		
		# dump both scripts to file (one sentence per line)
		$mypython2 $SCRIPTS/read_script_json.py \
				   "$ss_dir/$fname" "$osfile" -t "$tmpfolder/"
		
		# clean up both for encoding problems
		cat "$tmpfolder/temp.os.txt" | perl $SCRIPTS/fix_mixed_encodings.pl \
											> "$tmpfolder/temp.clean.os.txt"
		cat "$tmpfolder/temp.imsdb.txt" | perl $SCRIPTS/fix_mixed_encodings.pl \
											   > "$tmpfolder/temp.clean.imsdb.txt"
		cat "$tmpfolder/temp.clean.os.txt" | recode -f u8..unicode | \
			recode unicode..u8 > "$tmpfolder/temp.os.txt"
		cat "$tmpfolder/temp.clean.imsdb.txt" | recode -f u8..unicode | \
			recode unicode..u8 > "$tmpfolder/temp.imsdb.txt"
		
		# align them
		# bash $champollion/bin/champollion.EN_EN \
		#	 "$tmpfolder/temp.imsdb.txt"  \
		#	 "$tmpfolder/temp.os.txt" \
		#	 testalign $working_dir/en-en.champdict

		perl $SCRIPTS/sentence-align.pl --aligner=champollian \
			 --src-dirs=$tmpfolder/imsdb/scripts \
			 --trg-dirs=$tmpfolder/imsdb/subtitles \
			 --aligned-dir=$working_dir/imsdb/alignments \
			 --dict=$working_dir/en-en.champdict \
			 --bitext-src=temp.os.txt \
			 --bitext-trg=temp.imsdb.txt \
			 --src-suffix="" \
			 --trg-suffix="" \
			 --min-11=0 --max-aligned=10 --refine --keep-files
		
		# how many subtitles aligned?
		numaligned=`cat testalign | cut -d"<" -f 1 | grep -v "omitted" | perl -pe 's/,/\n/g'| sort -nu | wc -l `
		totalsubs=`wc -l $tmpfolder/temp.os.txt | perl -pe 's/^ +//' | cut -d' ' -f 1`
		echo "$numaligned, $totalsubs"

		percent=`echo "($numaligned*100) / $totalsubs" | bc -l | perl -pe 's/\.(\d\d)\d*/\.\1/'`
		echo "Aligned: $percent %"
		
		read
	fi
done



rm "$tmpfolder/temp.os.txt" \
   "$tmpfolder/temp.imsdb.txt" \
   "$tmpfolder/temp.clean.imsdb.txt" \
   "$tmpfolder/temp.clean.os.txt"

exit

#---------------------------------------------------------------------
# 2. get imsdb data and opensubs data
#---------------------------------------------------------------------
# get imdb numbers of available imsdb films
# $mypython2 $SCRIPTS/crawl_imsdb.py -n $working_dir/imsdb/all.nums-titles.json \
		   # $working_dir/imsdb/scripts/

echo ">> Extracting imsdb films from OpenSubtitles2016 corpus (opensubs_imsdb/)"

# extract imsdb films from OpenSubs set
# $mypython3 $SCRIPTS/get_imsdb_openSubs.py \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.filminfo \
# 		   $working_dir/imsdb/all.nums-titles.json \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG \
# 		   $working_dir/imsdb/imsdb.$SRC-$TRG.list \
# 		   $working_dir/imsdb/imsdb.$SRC-$TRG.tmpfilminfo \
# 		   2> $working_dir/imsdb/imsdb.notInOpenSubs.$SRC-$TRG

# # get lines corresponding to line numbers
# $mypython2 $SCRIPTS/get-these-lines-from-numbers.py \
# 	$working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC \
# 	$working_dir/imsdb/imsdb.$SRC-$TRG.list \
# 	> $working_dir/imsdb/imsdb.noblank.$SRC-$TRG.$SRC

# $mypython2 $SCRIPTS/get-these-lines-from-numbers.py \
# 	$working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG \
# 	$working_dir/imsdb/imsdb.$SRC-$TRG.list \
# 	> $working_dir/imsdb/imsdb.noblank.$SRC-$TRG.$TRG

# # # set line numbers of metainfo file to correspond to line numbers in imsdb (starting from 1)
# $mypython3 $SCRIPTS/recalculate_filminfo_from_1.py \
# 		   $working_dir/imsdb/imsdb.$SRC-$TRG.tmpfilminfo \
# 		   > $working_dir/imsdb/imsdb.$SRC-$TRG.filminfo

# rm $working_dir/imsdb/imsdb.$SRC-$TRG.tmpfilminfo

# #---------------------------------------------------------------------
# # 3. get opensubs data without imsdb data
# #---------------------------------------------------------------------
# # get the line numbers
# $mypython3 $SCRIPTS/get_inverse_numbers.py \
# 		   $working_dir/imsdb/imsdb.$SRC-$TRG.list \
# 		   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list

# echo ">> Removing IMSDB films from OpenSubs2016 corpus (opensubs_minusimsdb/)"

# # get the sentences corresponding to those line numbers
# $mypython3 $SCRIPTS/get-these-lines-from-numbers.py \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC \
# 		   $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC


# $mypython3 $SCRIPTS/get-these-lines-from-numbers.py \
# 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG \
# 		   $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG

# # get filminfo for just these films
# $mypython3 $SCRIPTS/get_inverse_numbers.py \
# 		   $working_dir/imsdb/imsdb.$SRC-$TRG.list \
# 		   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
# 		   -f  $working_dir/opensubs_all/noblank.$SRC-$TRG.filminfo \
# 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo


# #---------------------------------------------------------------------
# # 4. take last 5000 films of Opensubs2016 as dev and keep rest for training
# #---------------------------------------------------------------------

# echo ">> Separating out last 5000 films from OpenSubs2016-IMSDB to make dev set (opensubs_train/ and opensubs_dev/)"

# lastline=`tail -4999 $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo | head -1 | cut -f 2 `
# firstfilms=`tail -4999 $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo | head -1 | cut -f 1 `

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC \
# 	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.$SRC

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG \
# 	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.$TRG

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo \
# 	| sed -n "${firstfilms},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.filminfo

# lastline=$(($lastline-1))
# firstfilms=$(($firstfilms-1))
		
# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC \
# 	| sed -n "1,${lastline}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.$SRC

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG \
# 	| sed -n "1,${lastline}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.$TRG

# cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo \
# 	| sed -n "1,${firstfilms}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.filminfo




# get line numbers of imsdb films from OpenSubs
# $mypython2 $SCRIPTS/get_imsdb_imdbs.py > $working_dir/imsdb/all.nums.list







		  
