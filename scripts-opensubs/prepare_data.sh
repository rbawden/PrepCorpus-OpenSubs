
# Author: Rachel Bawden
# Contact: rachel.bawden@limsi.fr
# Last modif: 07/07/2017


#---------------------------------------------------------------------
# paths to your python distributions (python 3)
mypython3=/Users/rbawden/Documents/pyenvs/py3.5/bin/python

# scripts and tools paths
SCRIPTS=/Users/rbawden/phd/OpenSubs2016_notes/scripts/OpenSubs-preparation

# source and target languages
SRC="fr"
TRG="en"

# where raw OpenSubtitles2016 data will be stored
datadir=/Volumes/Mammoth/data/
opensubs_dir=$datadir/OpenSubtitles2016 

# where processed parallel data will be stored
working_dir=/Users/rbawden/phd/OpenSubs2016_notes/data

# can ignore the generation of data if false (otherwise write true to regenerate)
redoOpenSubs=false


#---------------------------------------------------------------------
# 0. make directories if necessary
#---------------------------------------------------------------------
[[ -d $datadir ]] || mkdir $datadir
[ -d $working_dir/opensubs_all ] || mkdir $working_dir/opensubs_all
[ -d $working_dir/opensubs_minusimsdb ] || mkdir $working_dir/opensubs_minusimsdb
[ -d $working_dir/opensubs_train ] || mkdir $working_dir/opensubs_train
[ -d $working_dir/opensubs_dev ] || mkdir $working_dir/opensubs_dev
[ -d $working_dir/imsdb ] || mkdir $working_dir/imsdb
[ -d $working_dir/scripts ] || mkdir $working_dir/scripts
[ -d $working_dir/structured_scripts ] || mkdir $working_dir/structured_scripts
[ -d $working_dir/alignments ] || mkdir $working_dir/alignments


#---------------------------------------------------------------------
# 1. get OpenSubtitles2016 parallel corpus w/ film information
#---------------------------------------------------------------------

# From Opus:
# Download untokenised corpus files (righthand side of matrix) for each language
# Download alignment file for each language (ces)
if [ ! -d $opensubs_dir/raw/$SRC -a ! -f $opensubs_dir/$SRC.raw.tar.gz ]; then
	wget http://opus.lingfil.uu.se/download.php?f=OpenSubtitles2016/$SRC.raw.tar.gz \
		--O $data_dir/$SRC.raw.tar.gz
	tar -xzvf $data_dir/$SRC.raw.tar.gz
fi
if [ ! -d $opensubs_dir/raw/$TRG -a ! -f $opensubs_dir/$TRG.raw.tar.gz ]; then
	echo wget http://opus.lingfil.uu.se/download.php?f=OpenSubtitles2016/$TRG.raw.tar.gz \
		--O $datadir/$TRG.raw.tar.gz
	echo tar -xzvf $data_dir/$TRG.raw.tar.gz 
fi
# which one alphabetically first
align_src=`[ "$SRC" \< "$TRG" ] && echo "$SRC" || echo "$TRG"`
align_trg=`[ "$SRC" \< "$TRG" ] && echo "$TRG" || echo "$SRC"`


if [ ! -f $opensubs_dir/alignments.$align_src-$align_trg.xml.gz -a  -f $opensubs_dir/alignments.$SRC-$TRG.xml.gz ]; then
	wget http://opus.lingfil.uu.se/download.php?f=OpenSubtitles2016/xml/$align_src-$align_trg.xml.gz \
		--O $opensubs_dir/alignments.$SRC-$TRG.xml.gz
	
fi

#---------------------------------------------------------------------
# get all opensubs parallel corpus and preprocess (several cleaning steps)

if [ "$redoOpenSubs" = true ]; then

	echo ">> Preparing all opensubs2016 data (opensubs_all/)"
		
	# Create the parallel version
	$mypython3 $SCRIPTS/create-open-subs-corpus.py \
			   -r $opensubs_dir/raw \
			   -a $alignmentfile -o $working_dir/opensubs_all/raw.$SRC-$TRG \
			   -s $TRG -t $SRC \
			   > $working_dir/opensubs_all/raw.$SRC-$TRG.filminfo

	#---------------------------------------------------------------------
	# precleaning (fix encodings and whitespace characters such as \r) and
	# birecode to eliminate all extra problems
	
	if  [[ "$SRC" == "en" ||  "$SRC" == "fr" ]]; then
		cat $working_dir/opensubs_all/raw.$SRC-$TRG.$SRC | \
			perl $SCRIPTS/fix_mixed_encodings.pl \
				 > $working_dir/opensubs_all/precleaned.$SRC-$TRG.$SRC
	else
		zcat $working_dir/opensubs_all/raw.$SRC-$TRG.$SRC | \
			perl -pe 's/\r//g' | \
			gzip > $working_dir/opensubs_all/precleaned.$SRC-$TRG.$SRC
	fi
	if  [[ "$TRG" == "en" ||  "$TRG" == "fr" ]]; then
		cat $working_dir/opensubs_all/raw.$SRC-$TRG.$TRG | \
			perl $SCRIPTS/fix_mixed_encodings.pl \
				 > $working_dir/opensubs_all/precleaned.$SRC-$TRG.$TRG
	else
		zcat $working_dir/opensubs_all/raw.$SRC-$TRG.$TRG | \
			perl -pe 's/\r//g' | \
			gzip > $working_dir/opensubs_all/precleaned.$SRC-$TRG.$TRG
	fi


	cat $working_dir/opensubs_all/precleaned.$SRC-$TRG.$SRC | recode -f u8..unicode \
		| recode unicode..u8 > $working_dir/opensubs_all/birecoded.$SRC-$TRG.$SRC
	cat $working_dir/opensubs_all/precleaned.$SRC-$TRG.$TRG | recode -f u8..unicode \
		| recode unicode..u8 > $working_dir/opensubs_all/birecoded.$SRC-$TRG.$TRG


	#---------------------------------------------------------------------
	# subtitle-specific cleaning (removed unwanted characters and sentences
	# and correct some ocr problems)
	
	$mypython3 $SCRIPTS/clean-up-subs.py \
			   $working_dir/opensubs_all/birecoded.$SRC-$TRG.$SRC $SRC \
			   > $working_dir/opensubs_all/cleaned.$SRC-$TRG.$SRC
	$mypython3 $SCRIPTS/clean-up-subs.py \
			   $working_dir/opensubs_all/birecoded.$SRC-$TRG.$TRG $TRG \
			   > $working_dir/opensubs_all/cleaned.$SRC-$TRG.$TRG

	
	#---------------------------------------------------------------------
	# remove blank lines and recalculate film info
	$mypython3 $SCRIPTS/filter-empty-lines.py \
			   $working_dir/opensubs_all/cleaned.$SRC-$TRG.$SRC \
			   $working_dir/opensubs_all/cleaned.$SRC-$TRG.$TRG \
			   $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC \
			   $working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG \
			   > $working_dir/tmpfilmlines


	$mypython3 $SCRIPTS/recalculate-film-lines.py \
			   $working_dir/opensubs_all/raw.$SRC-$TRG.filminfo \
			   $working_dir/tmpfilmlines \
	 		   > $working_dir/opensubs_all/opensubs.$SRC-$TRG.filminfo
	 rm $working_dir/tmpfilmlines
	 rm $working_dir/opensubs_all/raw.$SRC-$TRG.filminfo
	
	 # zip pre-processed files for storage
	 gzip $working_dir/opensubs_all/cleaned.$SRC-$TRG.$SRC
	 gzip $working_dir/opensubs_all/cleaned.$SRC-$TRG.$TRG
	 gzip $working_dir/opensubs_all/birecoded.$SRC-$TRG.$SRC
	 gzip $working_dir/opensubs_all/birecoded.$SRC-$TRG.$TRG
	 gzip $working_dir/opensubs_all/precleaned.$SRC-$TRG.$SRC
	 gzip $working_dir/opensubs_all/precleaned.$SRC-$TRG.$TRG
	 gzip $working_dir/opensubs_all/raw.$SRC-$TRG.$SRC
	 gzip $working_dir/opensubs_all/raw.$SRC-$TRG.$TRG

fi
	 # add line numbers to "noblank files"
	 sed  = $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC | sed -e 'N;s/\n/\t/' > $$;
	 cat $$ > $working_dir/opensubs_all/noblank.$SRC-$TRG.$SRC; 
	 rm $$
	 
	 sed  = $working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG |  sed -e 'N;s/\n/\t/' > $$;
	 cat $$ > $working_dir/opensubs_all/noblank.$SRC-$TRG.$TRG; 
	 rm $$







		  
