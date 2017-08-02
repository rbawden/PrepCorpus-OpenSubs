import argparse
import os
import gzip
# Extract from a corpus the lines corresponding to the numbers given
# in the line number file (starting from line 1). The line number file
# must be sorted (asc).

# read the line number file and return a list of the line numbers
def get_line_numbers(line_file):
    if ".gz" in line_file: fp = gzip.open(line_file, "rt")
    else: fp = open(line_file, "r")

    linenumbers = fp.readlines()
    for i, line in enumerate(linenumbers):
        linenumbers[i] = int(line.strip())#- 686069   #fr 1630000
            
        # print(linenumbers[i])
        # check that list is sorted
        if i>0 and linenumbers[i] <= linenumbers[i-1]:
            exit("The line number list is not sorted.\n Try: cat unsortedfile | sort -n > sortedfile")
    fp.close()
    return [x for x in linenumbers if x > 0]


# go through corpus and print out the lines corresponding to those in
# the list. If stickprevious is True, prints out the previous line,
# followed by //, followed by the current line.
def get_corpus(corpus, linenumbers, stickprevious):
    j = 0
    previous = ""
    if len(linenumbers)==0: return
    if ".gz" in corpus: fp = gzip.open(corpus, "rt")
    else: fp = open(corpus, "r")
    for i, line in enumerate(fp):
        if i+1 > linenumbers[-1]: break

        if i+1==linenumbers[j]:
            # if j>0: os.sys.stdout.write("\n")
            # print("yes")
            if stickprevious:
                os.sys.stdout.write(previous.strip()+" // ")
            os.sys.stdout.write(line.strip()+"\n")
            j+=1
        if stickprevious: previous=line
    fp.close()

if __name__=="__main__":
    parser = argparse.ArgumentParser(description="""Prints to STDOUT 
the lines from a corpus corresponding to the line numbers given in 
the list. If the flag -stick_previous (-s) is used, also prints out
the previous line, separated from the current line by //.""")
 
    parser.add_argument('corpus')
    parser.add_argument('line_number_file') 
    parser.add_argument('-s', '-stick_previous', default=False, action='store_true') 
    args = parser.parse_args()

    lines = get_line_numbers(args.line_number_file)
    get_corpus(args.corpus, lines, args.s)
