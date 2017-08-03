
# Author: Rachel Bawden
# Contact: rachel.bawden@limsi.fr
# Last modif: 13/06/2017

# one argument is the variable file entitled var

vars=$1
. vars


CTK=$champollion 
LC_ALL=C


# Make directories if necessary
for folder in opensubs_all opensubs_minusimsdb opensubs_train \
			  opensubs_dev imsdb imsdb/subtitles imsdb/speech imsdb/scripts \
			  imsdb/structured_scripts imsdb/alignments; do
	[ -d $working_dir/$folder ] || mkdir $working_dir/$folder
done

# Get imsdb data and character lists
if [ "$redoImsdb" = true ]; then
    echo ">> Getting imsdb data"
    # get imdb numbers of available imsdb films
    $python2 $SCRIPTS/crawl_imsdb.py \
	     -n $working_dir/imsdb/all.nums-titles.json \
			   $working_dir/imsdb/scripts/
    
    # get characters (w/ actor information) for all imsdb films
    if [ ! -f $working_dir/imsdb/all.characters.json ]; then
	$python2 $SCRIPTS/crawl_imsdb.py \
		 -m $working_dir/imsdb/all.nums-titles.json \
		 $working_dir/imsdb/all.characters.json
    fi
    
    # extract scripts and structure them
    $python2 $SCRIPTS/crawl_imsdb.py \
	     -s $working_dir/imsdb/all.nums-titles.json \
	     $working_dir/imsdb/scripts/ \
	     $working_dir/imsdb/structured_scripts/ \
	     $working_dir/imsdb/all_imsdb.imdb2characters.metainfo.json
fi

if [ ! -f $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC ] || [ ! -f $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC ]; then
	echo "First need to generate OpenSubtitles data with scripts-opensubs/prepare_data.sh"
	exit
fi


<<COMMENT
# Remove imsdb films from Opensubs train set
# Get the line numbers of IMSDB films
echo ">> Getting line numbers of imsdb films in OpenSubs"
$python2 $SCRIPTS/get_imsdb_linenumbers.py \
	   $working_dir/imsdb/all.nums-titles.json \
 	   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
 	   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo \
	   > $working_dir/imsdb/opensubs.imsdb.$SRC-$TRG.list

$python2 $SCRIPTS/get_imsdb_linenumbers.py \
	   $working_dir/imsdb/all.nums-titles.json \
 	   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
 	   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo --printfilminfo \
 	   > $working_dir/imsdb/opensubs.imsdb.$SRC-$TRG.filminfo

# Get the line numbers of remaining OpenSubs films
echo ">> Getting line numbers of Opensubs minus imsdb films in OpenSubs"
$python2 $SCRIPTS/get_imsdb_linenumbers.py \
	   $working_dir/imsdb/all.nums-titles.json \
 	   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
 	   -f $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo -v \
 	   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list

$python2 $SCRIPTS/get_imsdb_linenumbers.py \
	   $working_dir/imsdb/all.nums-titles.json \
 	   `wc -l $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | perl -pe 's/^\s*//g' | cut -d" " -f 1` \
 	   -f  $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo --printfilminfo -v \
 	   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo

echo ">> Getting IMSDB films from OpenSubs2016 corpus (opensubs_minusimsdb/)"
# Get the sentences corresponding to opensubs\imsdb numbers
for lang in $SRC $TRG; do
	python $SCRIPTS/get-these-lines-from-numbers.py \
 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$lang \
 		   $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list \
 		   > $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$lang
done

echo ">> Getting just IMSDB from OpenSubs2016 corpus (imsdb/)"
# Get the sentences corresponding to opensubs\imsdb numbers
for lang in $SRC $TRG; do
	python $SCRIPTS/get-these-lines-from-numbers.py \
 		   $working_dir/opensubs_all/noblank.$SRC-$TRG.$lang \
 		   $working_dir/imsdb/opensubs.imsdb.$SRC-$TRG.list \
 		   > $working_dir/imsdb/opensubs.imsdb.$SRC-$TRG.$lang
done

# Remove 5000 films from OpenSubs\imsdb to use as dev if necessary
echo ">> Separating out last 5000 films from OpenSubs2016-IMSDB to make dev set (opensubs_train/ and opensubs_dev/)"


lastline=`tail -5000 $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo | head -1 | cut -f 2 `
firstfilms=`tail -5000 $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo | head -1 | cut -f 1 `

# get dev corpus
cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC \
 	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.$SRC

cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG \
 	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.$TRG

# get line numbers from opensubs_all
cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list \
	| sed -n "${lastline},50000000000p" >  $working_dir/opensubs_dev/opensubs.dev.$SRC-$TRG.list

lastline=$(($lastline-1))
firstfilms=$(($firstfilms-1))

# get train corpus
cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$SRC \
 	| sed -n "1,${lastline}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.$SRC

cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.$TRG \
 	| sed -n "1,${lastline}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.$TRG

cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.filminfo \
 	| sed -n "1,${firstfilms}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.filminfo

# get line numbers from opensubs_all
cat $working_dir/opensubs_minusimsdb/opensubs.minus-imsdb.$SRC-$TRG.list  \
	| sed -n "1,${firstfilms}p" >  $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.list

COMMENT

#---------------------------------------------------------------------
# 5. Now try to align opensubs and imsdb scripts using Champollion
#---------------------------------------------------------------------
export CTK=$champollion

echo ">> Starting alignment of scripts and subtitles"
# make a champollion dictionary from monolingual English data
if [ ! -f $working_dir/opensubs_train/opensubs.train.$SRC-$TRG.en ]; then
    echo "You need to generate an English monolingual corpus to train champollion"
elif [ ! -f $working_dir/en-en.champdict ]; then
    echo ">> Making champollion dictionary" 
    python $SCRIPTS/create-monolingual-champolion-dict.py \
 	   --corpus "$working_dir/opensubs_train/opensubs.train.$SRC-$TRG.en" \
 	   --dict "$working_dir/en-en.champdict"
fi

# then align all films
export ss_dir=$working_dir/imsdb/structured_scripts
export tmpfolder="$working_dir"

# transfer champollion script to champollion directory
cp $SCRIPTS/champollion.EN_EN $champollion/bin/


echo $(date) >> $working_dir/imsdb/alignment_log
justFirst="True"

function align() {

    fname="$1"
    fname="${fname##*/}"
    basename="${fname%.*}"
    
    
    
    year=`echo "$basename" |cut -d. -f1`
    imdb=`echo "$basename" |cut -d. -f2 | perl -pe 's/^0+//'`
    
    fnamenospace=`echo $fname | perl -pe 's/ /_/g' | perl -pe "s/\'/\-/g"`
    
    echo "$fnamenospace"

    #continue
    
    # get script sentences and clean encoding
    $python2 $SCRIPTS/read_script_json.py script "$ss_dir/$fname" "$tmpfolder/imsdb.$fnamenospace.txt"
    cat "$tmpfolder/imsdb.$fnamenospace.txt" | perl $SCRIPTS/fix_mixed_encodings.pl \
						    > "$tmpfolder/clean.imsdb.$fnamenospace.txt"
    #cat "$tmpfolder/clean.imsdb.$fnamenospace.txt" | recode -f u8..unicode | \
#	recode unicode..u8 > "$working_dir/imsdb/speech/$basename.txt"
    # when recode isn't installed..
    cat "$tmpfolder/clean.imsdb.$fnamenospace.txt" > "$working_dir/imsdb/speech/$basename.txt" 
    
    cp "$working_dir/imsdb/speech/$basename.txt" "$tmpfolder/clean.imsdb.$fnamenospace.txt"
    
    echo -e "$basename" >> $working_dir/imsdb/alignment_log
    align_percent=-1
    bestfile=""
    
    if [ -d "$opensubs_dir/raw/en/$year/$imdb" ] && [ ! -f "$working_dir/imsdb/alignments/$basename.align" ]; then
	
	# test each of the osfiles and take the one with the highest overlap
	for osfile in `ls $opensubs_dir/raw/en/$year/$imdb/*.xml.gz`; do
	    
	    # get script sentences and clean encoding
	    $python2 $SCRIPTS/read_script_json.py subtitles "$osfile" \
		       "$tmpfolder/os.$fnamenospace.txt"
	    cat "$tmpfolder/os.$fnamenospace.txt" | perl $SCRIPTS/fix_mixed_encodings.pl \
							 > "$tmpfolder/clean.os.$fnamenospace.txt"
	    cat "$tmpfolder/clean.os.$fnamenospace.txt" | recode -f u8..unicode | \
		recode unicode..u8 > "$tmpfolder/clean.os.$fnamenospace.txt"
	    
	    # align them
	    bash $champollion/bin/champollion.EN_EN \
		 $champollion \
		 "$tmpfolder/clean.imsdb.$fnamenospace.txt" \
		 "$tmpfolder/clean.os.$fnamenospace.txt" \
		 "$tmpfolder/align.$fnamenospace.txt" "$working_dir/en-en.champdict"
	    
	    # get percent of alignment
	    numaligned=`cat "$tmpfolder/align.$fnamenospace.txt" \
				| cut -d">" -f 2 | grep -v "omitted" | perl -pe 's/,/\n/' | perl -pe 's/ //g' | sort -nu | wc -l `
	    totalsubs=`wc -l "$tmpfolder/temp.clean2.os.txt" | perl -pe 's/^ +//' | cut -d' ' -f 1`
	    percent=`echo "($numaligned*100) / $totalsubs" | bc -l | perl -pe 's/\.(\d\d)\d*/\.\1/'`
	    
	    # is is better than previous alignment coverage?
	    if (( justFirst || $(echo "$percent > $align_percent" | bc -l) )); then
		bestfile=$osfile
		align_percent=$percent
		cp "$tmpfolder/temp.clean2.os.txt" "$working_dir/imsdb/subtitles/$basename.txt"
		cp "$tmpfolder/temp.align.txt" "$working_dir/imsdb/alignments/$basename.align"
	    fi
	    
	    # just take the first one rather than find the one with the best alignment
	    if [ $justFirst == "True" ]; then
		continue
	    fi
	    
	    echo -e "\t$year\t$imdb\t$fname\t$osfile\t$percent" >> $working_dir/imsdb/alignment_log
	done
	
	# record best file for this script
	if [ -n "$bestfile" ]; then
	    echo -e "\tBEST:\t$basename\t$bestfile\t$align_percent\n" >> $working_dir/imsdb/alignment_log
	else
	    echo -e "\tBEST:\t$basename\t$None\n" >> $working_dir/imsdb/alignment_log
	fi
	
	rm 	"$tmpfolder/imsdb.$fnamenospace.txt" "$tmpfolder/clean.imsdb.$fnamenospace.txt" \
		"$tmpfolder/os.$fnamenospace.txt" "$tmpfolder/clean.os.$fnamenospace.txt" \
		"$tmpfolder/align.$fnamenospace.txt"
    fi	
}

#export -f align

#parallel align ::: "$ss_dir/*"
OIFS="$IFS"
IFS=$'\n'
# go through and align all files
for fname in `ls $ss_dir/`; do
    align "$fname"
done





		  
