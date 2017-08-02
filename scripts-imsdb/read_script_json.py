# coding=utf-8
from crawl_imsdb import *
import gzip

def dump_script(json_fname, outname):
    script = load_json(json_fname)
    #os.sys.stderr.write("Outputting imsdb script to "+outname+"\n")
    with open(outname, "w") as outfp:
        for item in script:
            if item[0] == "speech":
                outfp.write(item[2].encode("utf-8")+"\n")

                
def dump_subtitles(fname, outname):
    #os.sys.stderr.write("Outputting opensubs script to "+outname+"\n")
    with gzip.open(fname) as fp, \
      open(outname, "w") as outfp:
        contents = fp.read().replace("\n", " ")
        for segment in re.findall("<s id=\"\d+\">(.*?)</s>", contents):
            segment = re.sub("<time [^><]*?/>", "", segment)
            segment = re.sub("(^[ \-]+|[ \-]$)", "", segment)
            # print(segment)
            outfp.write(segment+"\n")
            


#-------------------------------------------------------------------
if __name__=="__main__":

    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("filetype", choices=["subtitles", "script"])
    parser.add_argument("infile")
    parser.add_argument("outfile")
    args = parser.parse_args()
    
    if args.filetype=="script":
        dump_script(args.infile, args.outfile)
    else:
        dump_subtitles(args.infile, args.outfile)

    

