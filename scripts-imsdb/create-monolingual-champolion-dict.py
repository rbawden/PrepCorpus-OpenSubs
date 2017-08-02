"""
Script that creates an identity dictionary from a large monolingual corpus.

Latest sanity check: 2015-12-02
(script from M. van der Wees)
"""

# imports
import argparse
import gzip

# helper functions
def parse_commandline():
    """
    Commandline argument parser
    """
    program = "My program description"
    parser  = argparse.ArgumentParser(prog=program)
    parser.add_argument("--corpus", required=True, help="Path to big monolingual corpus")
    parser.add_argument("--dict_name", required=True, help="Name of dictionary output file")
    return parser.parse_args()

def create_dictionary(corpus, dict_name):
    """
    Function that creates an identity dictionary from a large monolingual corpus.
    """
    if ".gz" in corpus: infile = gzip.open(corpus, "rt")
    else: infile = open(corpus, "r")
    words_in_corpus = infile.read().lower().split()
    unique_words    = set(words_in_corpus)
    infile.close()
        
    with open(dict_name, "w+") as outfile:
        for word in sorted(unique_words):
            outfile.write(word + " <> " + word + "\n")


# run program
def main():
    """
    Main functionality: calls helper functions
    """
    options   = parse_commandline()
    corpus    = options.corpus
    dict_name = options.dict_name

    create_dictionary(corpus, dict_name)
  
if __name__ == "__main__":
  main()
