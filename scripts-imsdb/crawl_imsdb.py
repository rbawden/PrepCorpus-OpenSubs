# -*- coding: utf-8 -*-
import os, sys
import re, string
from bs4 import BeautifulSoup
import requests
if sys.version_info >= (3,0): import urllib.request as urllib
else: import urllib2 as urllib
import mechanize
#from imdb import IMDb
import json
from joblib import Parallel, delayed
import multiprocessing as mp
import httplib
from structure_scripts import *

#from scriptsconstants import *

#-------------------------------------------------------------------
# get all character/actor information for a film
#-------------------------------------------------------------------
def get_film_actors(imdb_num, loaded_people):
        
    film_url = "http://www.imdb.com/title/tt"+str(imdb_num)
    film_url += "/fullcredits?ref_=tt_ov_st_sm"
    soup = read_html(film_url)
    if not soup: return

    # go through cast list
    castlist = soup.find("table", {"class": "cast_list"})
    if not castlist: return []
    potential_actors = castlist.findAll("tr")
    actors = []
    for actor in potential_actors:
        if actor.find("td", {"class": "character"}):
            actors.append(actor)
        
    # reload 
    if loaded_people and len(actors)==len(loaded_people):
        return loaded_people

    # start getting character and actor names (+ gender, + date of birth)
    people = []
    print(len(actors))
    for a, actor in enumerate(actors):

        name, character, actornumber, characternumber, gender, dates = ("NA",)*6
        for link in actor.findAll("a"):
            actorname = re.match("/name/(nm\d+)/.*", link["href"])
            charname = re.match("/character/(ch\d+)/.*", link["href"])
            
            if actorname:
                actornumber = actorname.group(1)
                name = link.text
                actorurl = link["href"]
                gender, dates = get_actor_info("http://www.imdb.com"+actorurl)
                    
            elif charname:
                characternumber = charname.group(1)
                character = re.sub("\s+", " ", link.text.strip().replace("\n", ""))
        #dump_json(people, 'out-test.json')        
        # get character name even if could'nt find it in imdb        
        if character == "NA":
            character = re.sub("\s+", " ", actor.find("td", {"class": "character"}).find("div").text).strip()
        print(len(people))
        
        people.append( (name.strip(), actornumber.strip(), character.strip(), characternumber.strip(), gender, dates) )
        
    return people
    

#-------------------------------------------------------------------
# get actor information from imdb page of actor (gender + birthdate)
#-------------------------------------------------------------------
def get_actor_info(actor_url):
    
    soup = read_html(actor_url)
    if not soup: return "NA", "NA"

    # date of birth
    birthdate = soup.find("time", {"itemprop": "birthDate"})
    if birthdate: birthday = birthdate["datetime"]
    else: birthday = "NA"

    # gender
    gender="NA"
    jobs = soup.findAll("span", {"itemprop": "jobTitle"})
    for job in jobs:
        if "Actor" in job.text: gender="m"
        elif "Actress" in job.text: gender="f"
        if "Actor" in job.text or "Actress" in job.text: break

    return gender.strip(), birthday.strip()

    
    
#-------------------------------------------------------------------

def append_log(message):
    os.sys.stderr.write(message+"\n")

def get_web_page(address):
    try:
        user_agent = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'
        headers = { 'User-Agent' : user_agent }
        request = urllib.Request(address, None, headers)
        response = urllib.urlopen(request, timeout=30)
        try:
            return response.read()
        finally:
            response.close()
    except urllib.HTTPError as e:
        error_desc = httplib.responses.get(e.code, '')
        append_log('HTTP Error: ' + str(e.code) + ': ' + error_desc + ': ' + address)
    except urllib.URLError as e:
        append_log('URL Error: ' + str(e.reason[0]) + ': ' + address)
    except Exception as e:
        append_log('Unknown Error: ' + str(e) + address)

#-------------------------------------------------------------------
# dump meta data to file in json format
def dump_json(to_dump, fname):
    os.sys.stderr.write("\nDumping json meta character file to "+str(fname)+".\n")
    with open(fname, "w") as fp:
        json.dump(to_dump, fp)

#-------------------------------------------------------------------
# load json file
def load_json(fname):
    os.sys.stderr.write("\nLoading json meta character file from "+str(fname)+".\n")
    with open(fname, "r") as fp:
        loaded = json.load( fp)
    return loaded

#-------------------------------------------------------------------
# get meta information for all films given in argument using imdbpy (character/actor list)
def get_all_film_meta_info(ia, imdb_nums, dumpto):
    film2people = {}
    os.sys.stderr.write("\nGetting meta info information for all characters from all films\n")
    os.sys.stderr.flush()

    # if file already exists, reload
    if os.path.isfile(dumpto):
        film2people = json.load(open(dumpto, "r"))
    
    for i, imdb in enumerate(imdb_nums):
        os.sys.stderr.write("\r"+str(i)+"/"+str(len(imdb_nums)))
        film2people[imdb] = get_film_actors(imdb, film2people.get(imdb, None))

        if not film2people[imdb]: del film2people[imdb]
        
        #film2people[imdb] = get_film_meta_info(ia, imdb)
        dump_json(film2people, dumpto)

    return film2people

#-------------------------------------------------------------------
# get meta information for a film using imdbpy (character/actor list)
def get_film_meta_info(ia, imdb_num):
    film = ia.get_movie(str(imdb_num))
    cast = film["cast"]
    people = []
    for a, actor in enumerate(cast):
        os.sys.stderr.write("\r\t"+str(a)+"/"+str(len(cast)))
        person = {"character_name": str(actor.currentRole), "personID": actor.personID} 
        personobj = ia.get_person(actor.personID)
       
        for attr in ["name", "birth date"]:
            if attr in personobj.keys(): person[attr] = personobj[attr]

        # get gender
        if "actor" in personobj.keys(): person["gender"] = "m"
        elif "actress" in personobj.keys(): person["gender"] = "f"
        else: person["gender"] = "NA"
            
        people.append(person)
    return people

#-------------------------------------------------------------------
# get all imdb numbers from film names (as in imsdb). But see get_film_ids to get all imdb numbers
# and film names from the main imsdb url
def get_all_imdb_numbers(names):
    imdb_nums = []
    for name in names:
        imdb_nums.append(get_imdb_number(name))
    return imdb_nums

# WRONG
# def get_imdb_number2(film_url):
#     print(film_url)
#     raw_input()
#     search_page = requests.get(film_url)
#     search_soup = BeautifulSoup(search_page.text, "html.parser")
#     print(search_soup)
#     links = search_soup.findall("a")
#     for link in links:
#         print(link)
#         # link = br.find_link(url_regex = re.compile(r'/title/tt.*'))
#         imdb = re.match("/title/tt([0-9]+)/", link.url).group(1)
#     main_filmpage = BeautifulSoup(search_page.text, "html.parser")


# def get_imdb_number(name, date=None):
#     # print("getting number")
#     film = '+'.join(name.split())
#     br = mechanize.Browser()
#     url = "%s/find?s=tt&q=%s" % ('http://www.imdb.com', film)
#     br.open(url)
 
#     nums = re.search(r'/title/tt(.*)', br.geturl())
#     if nums:
#         print(nums.group(1))
#         return nums.group(1)
#     else:
#         return None

def get_authors(imdb):

    html = read_html("http://www.imdb.com/title/tt"+str(imdb))
    if not html: return []
    authors = []
    for creator in html.findAll("span", {"itemprop": "creator"}):
        link = creator.find("a")
        authors.append(link.text)
    return authors
        
def get_date_from_imdb(imdb):
    html = read_html("http://www.imdb.com/title/tt"+str(imdb))
    if not html: return []
    date = None
    for creator in html.findAll("span", {"id": "titleYear"}):
        date = creator.find("a").text
    return date


def is_not_film_imdb(imdb):
    html = read_html("http://www.imdb.com/title/tt"+str(imdb))
    if not html: return []
    date = None
    for info in html.findAll("a", {"title": "See more release dates"}):
        mediatype = info.text
        if "TV Series" in mediatype: return "TV"
        elif "Video game" in mediatype: return "videogame"
    return "film"

#-------------------------------------------------------------------
# get imdb number (and other information if available - writers, url)
def get_imdb_number(name, date=None, author=None):
    # read html search page for the film
    # name = name.replace(":", "")

    # take first one if no date provided, otherwise write date in search
    # if not date:
    url = 'http://www.imdb.com/find?q=' + name.replace(' ', '+')+"&s=tt&ref_=fn_al_tt_mr"
    # else:
    # url = 'http://www.imdb.com/find?q=' + name.replace(' ', '+') +"%28"+date+"%28" +"&s=all"
    
    br = mechanize.Browser()
    br.addheaders = [('User-agent', 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008071615 Fedora/3.0.1-1.fc9 Firefox/3.0.1')]
    br.set_handle_robots(False) 
    br.open(url)
    
    found = False
    imdbs_searched = []
    # print(author)
    # if the search gives at least one result, it will find a title/tt link
    try:
        # print(len(list( br.links(url_regex = re.compile(r'/title/tt.*')))))
        for link in br.links(url_regex = re.compile(r'/title/tt.*')):
            imdb = re.match("/title/tt([0-9]+)/", link.url).group(1)
            # print(imdb)
            if imdb not in imdbs_searched:
                # print(imdb)
                filmauthors = get_authors(imdb)
                mediatype = is_not_film_imdb(imdb)
                # print(mediatype)
                if mediatype not in ["videogame", "TV"]:
                    imdbs_searched.append(imdb)
                    for aut in author:
                        if aut in filmauthors:
                            found = True
            if found: break
        if not found and len(imdbs_searched)>0: imdb = imdbs_searched[0]
        elif not found: return None
            
        # html = read_html("http://www.imdb.com"+link.url)
        
    # otherwise return None for all fields (same number as below = 3)
    except mechanize._mechanize.LinkNotFoundError:
        # if dateimdb = get_imdb_number(name, date=None)
        os.sys.stderr.write("\t>> Warning! Could not retrieve "+name+" ("+url+")\n\n")
        br.close()
        return None
    br.close()
            
    return imdb #writers, link.url

    
#-------------------------------------------------------------------
#  return html from url (as BeautifulSoup object if bs=True, raw text otherwise)
def read_html(url, bs=True):
    # q = urllib.Request(url)
    # q.add_header('User-agent', 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.116 Safari/537.36')
    # try:
    #     fp = urllib.urlopen(q)
    # except urllib.HTTPError:
    #     os.sys.stderr.write("Warning! Could not open the url "+str(url)+"\n\n")
    #     return None
        
    # print(fp)
    fp = get_web_page(url)
    if not fp: return None
    
    if bs: soup =  BeautifulSoup(fp, "lxml")
    else: soup = fp#.read()
    # fp.close()
    return soup

#-------------------------------------------------------------------
def get_direct_link(name):
    name = "-".join(name.replace(":", "").split())
    return 'http://www.imsdb.com/scripts/'+name+".html"
    # return film_url.replace("all%20scripts/Movie Scripts","scripts").replace(" Script.html", ".html").replace(" ", "-")

#-------------------------------------------------------------------
def queryData(url):
  return requests.get(url).json()

#-------------------------------------------------------------------
# return the html text from a single film url
def get_html_script(film_url):
    main_url = get_direct_link(film_url)
    html = read_html(main_url, True)
    return html

#-------------------------------------------------------------------
# make sure that the directory exists and raise an Exception if not
def dir_exists(dir):
    if not os.path.isdir(dir):
        return False
    return True

#-------------------------------------------------------------------
# make sure that the file exists and raise an Exception if not
def file_exists(fname):
    if not os.path.exists(fname):
        return False
    return True

#-------------------------------------------------------------------
# from page between main page and script page
def get_date(script_fronturl):
    html = read_html(script_fronturl)
    if not html: return None

    script_details = html.find("table", {"class": "script-details"})

    if not script_details:
        os.sys.stderr.write("Could not get date from "+script_fronturl+"\n")
        return None
        
    for td in script_details.findAll('td'):
        text = " ".join(td.findAll(text=True)).replace("\n", " ")
        
        if re.match(".*?IMSDb opinion.*?", text, re.I):
            date = re.match(".*?(?:release|script)? date.*?(\d\d\d\d([-\d+])?).*?", text, re.I)
            if date:
                # print(date.group(1))
                return date.group(1)

    return None

            
#-------------------------------------------------------------------
# get the list of (imdb_num, filmname) pairs for all available scripts
def get_film_ids(imdb_url, dumpto, scriptdir, jobs=1):
    os.sys.stderr.write("Getting all film names and imdb numbers from "+str(imdb_url)+".\n")

    # initialise film_ids w/ previous json file if it exists
    if os.path.exists(dumpto): film_ids = load_json(dumpto)
    else: film_ids = []

    # make scriptdir if it doesn't exist
    if not os.path.exists(scriptdir): os.makedirs(scriptdir)
        
    html = read_html(imdb_url)
    
    for film_p in html.find_all('p'):
        film_a = film_p.find('a')
        link = film_a.get('href')
        writtenby = film_p.findAll("i")
        
        if "/Movie Scripts/" in link:
            filmname = re.match(".*Movie Scripts/(.+) Script.html",link).group(1)

            if filmname in [x[1] for x in film_ids]: continue # skip if already in file
            
            date = get_date("http://www.imsdb.com"+link.replace(" ", "%20"))
            script = get_html_script(filmname)

            # skip if no script is available
            if not script: continue 
            
            # get author from imsdb
            author = None
            for poss in writtenby:
                authormatch = re.match(".*?written by (.*?)$", poss.text, re.I)
                if authormatch: author = [x.strip() for x in authormatch.group(1).split(",")]

            # get imdb number from imdb.com (comparing authors to get right film)
            imdb_num  = get_imdb_number(filmname, date, author)
            if not imdb_num: continue

            # get date from imdb.com and change imprecise date from imsdb if necessary
            imdbdate = get_date_from_imdb(imdb_num)
            if imdbdate: date = imdbdate

            # store and dump (film id and script)
            film_ids.append( (imdb_num, filmname, date, author) )
            dump_json(film_ids, dumpto)
            write_script_to_file(script, scriptdir+"/"+str(imdb_num)+"."+filmname+".html")
            
        os.sys.stderr.write("\r"+str(len(film_ids))+" films")
            
    return film_ids

#-------------------------------------------------------------------
def write_script_to_file(script, fname):
    with open(fname, "w") as fp:
        fp.write(str(script))
        
#-------------------------------------------------------------------
# write all html scripts on imsdb available to file in outputdir, with
# the name of the file the same as the film name
def get_all_html_scripts(imdb_url, outputdir, meta_file, force_reload=False):
    
    if not dir_exists(outputdir): raise Exception("Directory "+str(outputdir)+" does not exist\n")

    # get all films from this page
    html = read_html(imdb_url)
    i = 0
    imdb2people = json.load(meta_file)
    
    for film_p in html.find_all('p'):
        film_a = film_p.find('a')
        link = film_a.get('href')
        
        if "/Movie Scripts/" in link:
            # get extra information about the film
            filmname =  re.match(".*Movie Scripts/(.+) Script.html", link).group(1)
            imdb_num = get_imdb_number(filmname)
            filename = outputdir+"/"+str(imdb_num)+"."+filmname+".html"
            os.sys.stderr.write(filmname+" ("+str(imdb_num)+")\n")

            # load people
            people = imdb2people.get(imdb, [])
            
            # get script in html format and meta info
            script = get_html_script(filmname)
            if not script: continue # if script cannot be retrived
            get_structured_script(script)

            # people = get_film_meta_info(ia, imdb_num)
            # imdb2people[imdb_num] = people
            

            # write to file
            with open(filename, "w") as fp: fp.write(script)

            i+=1
            # if i%10==0: dump_json(people, meta_file) # temporary dump

    # write out metainfo
    dump_json(people, meta_file)



def get_text_from_html(fname):
    soup = BeautifulSoup(open(fname), "html.parser")
    script_text =""
    script = soup.findAll("td", {"class": "scrtext"})
    for s in script:
        # print(s.text)
        # raw_input()
        script_text += s.text

        return script_text
        
def structure_scripts(dirname, jsonfname, outputdir):

    # load json file
    imdb2people = load_json(jsonfname)
    
    # structure all html scripts
    for fic in os.listdir(dirname):
        id_name = re.match("(\d+)\.(.*?).html", fic)
        if id_name:
            imdb = id_name.group(1)
            name = id_name.group(2)
            if imdb not in imdb2people: continue # skip
            people = imdb2people[imdb]

            # get text
            # script_text = get_text_froml_html(dirname+"/"+fic)
            soup = BeautifulSoup(open(dirname+"/"+fic), "lxml", from_encoding="utf-8")
            
            # get script format type
            formattype = define_script_type(soup, people)
            if formattype=="bold":
                print("bold characters")
                script = bold_names(soup, people)
                dump_json(script, outputdir+"/"+str(imdb)+"."+name+".json")
            else:
                print("Cannot determine script format")
            # structure_script(script_text, people)
    


    

        
#-------------------------------------------------------------------
if __name__=="__main__":

    import argparse
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-n', '--num_imdb', nargs=2, \
                       metavar=('json_filename', 'scriptdir'), \
                       help='Get all imdb numbers for imsdb films and dump to json file and scripts to separate txt files')
    group.add_argument('-m', '--meta_info', nargs=2, \
                       metavar=('in_imdbnum_json', 'out_meta_json'), \
                       help='Get meta info for all imsdb films and dump to json file')
    group.add_argument('-s', '--scripts', nargs=4, \
                       metavar=('json_meta_file', 'scriptdir',  'structured_scriptdir', 'char_json'), \
                       help='Get scripts for all imsdb films')
    args = parser.parse_args()

    imdb_url = "http://www.imsdb.com/all%20scripts"
    #ia = IMDb()
    ia = None

    if args.num_imdb:
        imdb_info = get_film_ids(imdb_url, args.num_imdb[0], args.num_imdb[1])
        dump_json(imdb_info, args.num_imdb[0])
    
    elif args.meta_info:
        imdb_info = load_json(args.meta_info[0])
        imdb2people = get_all_film_meta_info(ia, [x[0] for x in imdb_info], args.meta_info[1])
        dump_json(imdb2people, args.meta_info[1])
        

    elif args.scripts:

        meta_fname = args.scripts[0]
        htmldir = args.scripts[1]

        outputdir = args.scripts[2]
        characters_json_fname = args.scripts[3]
        
        force_reload = True

        check_formatting(meta_fname, characters_json_fname, htmldir, outputdir)
            
