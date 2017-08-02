import argparse
import gzip
import os
from crawl_imsdb import *
from utils import *


# sort according to line numbers
def get_lines(fname):
    if ".gz" in fname: fp = gzip.open(fname, "rt", encoding="utf-8")
    else: fp = open(fname, "r", encoding="utf-8")
    lines = []
    for line in fp:
        lines.append(int(line))
    fp.close()
    return lines

def get_filminfo(fname):
    if ".gz" in fname: fl = gzip.open(fname, "rt")
    else: fl = open(fname, "rt")
    filmlines = []

    for line in fl:
        line = line.strip("\n")
        filminfo = line.split("\t")
        for i in range(len(filminfo)):
            if i < 4: filminfo[i] = int(filminfo[i])
            else: filminfo[i] = str(filminfo[i])
        filmlines.append(filminfo)
    fl.close()
    return filmlines


def get_imsdb_line_numbers(imdbnums, filminfo):
    linenums = []
    for film in filminfo:
        if film[3] in imdbnums:
            for i in range(film[1], film[2]+1):
                linenums.append(i)
    return linenums

def print_filminfo(filminfo):
    for i, film in enumerate(filminfo):
        print(str(i+1) +"\t" + "\t".join([str(x) for x in film[1:]]))


def read_imdb_nums(json_fname):
    imdbs = []
    for film in load_json(json_fname):
        imdbs.append(int(film[0]))
    return imdbs
        
def get_new_films(filmlines, imsdb, imsdb_set=True):
    new_films = []
    i = 0
    if imsdb_set: isthere = True
    else: isthere = False

    linenum = 0
    for film in filmlines:
        # check if starting and finishing lines of film are in imsdb lines
        if bin_search(film[1], imsdb)==isthere and bin_search(film[2], imsdb)==isthere:
            film[2] = str(int(film[2])-int(film[1])+linenum)
            film[1] = str(linenum)
            linenum = linenum + int(film[2])-int(film[1]) + 1
            new_films.append(film)
            i += 1
        elif bin_search(film[1], imsdb)==isthere or bin_search(film[2], imsdb)==isthere:
            exit("The film info file is not compatible with the imsdb file\n")

    os.sys.stderr.write(str(i)+" films found\n")
    return new_films

def check_sorted(imsdb):
    last=0
    for i in range(len(imsdb)):
        if imsdb[i]<last: exit("The list is not sorted")
    
def print_line_numbers(imsdb_lines, max_num, imsdb=True):
    for i in range(1, max_num + 1):
        if bin_search(i, imsdb_lines) == imsdb:
            print(i)

if __name__=="__main__":
    argparser = argparse.ArgumentParser()            
    argparser.add_argument('json_num_titles', help="json file containing the film numbers and titles")
    argparser.add_argument('max_lines', type=int, help="The number of lines in the OpenSubtitles corpus")
    argparser.add_argument('-f', '--filminfo', help="The filminfo file for the OpenSubtitles corpus")
    argparser.add_argument('--printfilminfo', default=False, action="store_true", help="print out the corresponding filminfo")
    argparser.add_argument('-v', action="store_true", default=False, help="Inverse: get the non-imsdb line numbers")
    args = argparser.parse_args()
    
    imsdb = read_imdb_nums(args.json_num_titles)
    filmlines = get_filminfo(args.filminfo)
    imsdb_lines = get_imsdb_line_numbers(imsdb, filmlines)
    sorted(imsdb_lines) # make sure the lines are sorted
    check_sorted(imsdb) # check this

    if args.printfilminfo:
        newfilminfo = get_new_films(filmlines, imsdb_lines, not args.v)
        print_filminfo(newfilminfo)
    else:
        print_line_numbers(imsdb_lines, args.max_lines, not args.v)
