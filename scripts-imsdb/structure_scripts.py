import os
from crawl_imsdb import *


# constants
RE_DOCID              = re.compile('docid="([0-9]+/[0-9]+)"')
RE_MOVIENAME          = re.compile('<title>(.*?)subtitles')
RE_MOVIESCRIPT        = re.compile('<pre>(.*?)</pre>', re.S)
RE_SPEAKER_OR_CONTEXT = re.compile('<b>(.+?)</b>', re.S)
RE_QUOTE_OR_CONTEXT   = re.compile('</b>(.+?)<b>', re.S)
RE_INDENTATION        = re.compile('^(\s*)\S')

#RE_MOVIESCENE         = re.compile('(<b>\d+.*?)(?=<b>\d|</b></pre>)', re.S)
RE_BOLD_REGULAR_PAIR  = re.compile('<b>([^<]*?)</b>([^<]+?)(?=<b>)', re.S)
RE_SPEAKER_QUOTE_PAIR = re.compile('<b>(.*?)</b>(.+?)(?=<b>)', re.S)
RE_SENTENCE           = re.compile('<s id="\d+">.*?</s>', re.S)
RE_WORD               = re.compile('<w id="\d+\.\d+">(.*?)</w>')
RE_TIMESTAMP          = re.compile('<(time id=".*?" value=".*?") />')
RE_MOVIE_GENRES       = re.compile('<a href="/genre/(.*?)"')
RE_FROM_DOCID         = re.compile('(?<=fromDoc=").*?(?=")')
RE_TO_DOCID           = re.compile('(?<=toDoc=").*?(?=")')
RE_SUBT_MAP           = re.compile('xtargets="(.*?);(.*?)"')

SPEAKER_INFO      = ["V.O.", "CONT'D", "contd", "O.S.", "NARRATOR"]
CHARACTERS_DATA   = "movie_characters_metadata.txt"
SCENE_INFORMATION = ["DAY", "NIGHT", "DAWN", "DUSK", "MORNING", "AFTERNOON", 
                     "EVENING", "NIGHT", "LATER", "HOUSE", "ROOM", "OFFICE",
                     "CAR", "YARD", "SUITE", "RESTAURANT", "LATE", "EARLY",
                     "FLOOR", "INSERT", "CUT TO", "DISSOLVE", "EXT", "INT"]

LANGUAGE_MAPPING  = {"de":"german", "nl":"dutch", "en":"english",
                     "fr":"french", "zh_cn":"chinese", "ar":"arabic",
                     "ru":"russian", "fa":"persian", "bg":"bulgarian",
                     "es":"spanish"} #TODO: extend!

# some debugging parameters
DEBUG = False
DEBUG_EXTRACT  = True
DEBUG_ALIGN    = False
DOWNLOAD_FILES = False
DETERMINE_INDENTATION = False
if DETERMINE_INDENTATION or DEBUG_EXTRACT or DEBUG_ALIGN:
    MOVIE_ID_OUTFILE = "new-movie-ids-to-titles-debug"
    ID2TITLES_FILE   = "movie-ids-to-titles-debug"
else:
    MOVIE_ID_OUTFILE = "new-movie-ids-to-titles"
    ID2TITLES_FILE   = "movie-ids-to-titles"
                     







def get_all_charnames(characters):
    charnames = set([])
    toreplace = ["\(uncredited\)", "\((singing )?voice\)", "\(.*? episode .*?\)"]
    
    for character in characters:
        name = character[2]
        name = re.sub("("+"|".join(toreplace)+")"," ", name).strip()

        # sometimes their name is written in brackets ... (as mr smith)
        extra = re.match("(.+?) \(as (.+?)\)", name)
        if extra:
            charnames.add(extra.group(1))
            charnames.add(extra.group(2))
            name = extra.group(2)
        else:
            charnames.add(name)

        # add first and last names (can add some noise because of charcter descriptions)
        if " " in name:
            # if DEBUG: print(name)
            for partname in name.split(" "):
                if partname.strip()=="": continue
                # only add if uppercase and not punctuation
                if partname[0].upper() == partname[0] and re.match("\w", partname[0]):
                    charnames.add(partname)
    return list(charnames)


def abbreviated_names(charnames, text):
    for char in charnames:
        if len(char) > len(text) and text in char[:len(text)]:
            return char[:len(text)]
    return None


            
def read_name_list(fname):
    names = []
    with open(fname) as fp:
        for line in fp:
            names.append(line.upper().strip())
    return names

names = read_name_list("/Users/rbawden/Documents/tq_in_mt/resources/gals.list")
names.extend(read_name_list("/Users/rbawden/Documents/tq_in_mt/resources/guys.list"))

def extract_script(fname, character_actors, speaker_indent=["xxx"], scene_indent=["xxx"], speech_indent=["xxx"], colon=False):
    
    if "xxx" in speaker_indent:
        numpass = 1
    else:
        numpass = 2
    
    characters = get_all_charnames(character_actors)
    uppercharacters = [x.upper() for x in characters if x!=""]

    rawtext = get_text_from_html(fname)
    if not rawtext:
        return (None,)*6

    indents = {"speaker": {}, "scene": {}, "speech": {}}
    film = []
    speaker = None
    speech = ""
    last_indent = ""
    breakit = True
    blanks = 0 # count blank lines
    colonsep = 0
    
    for line in rawtext.split("\n"):
        
        line = line.strip("\n")
        if re.match(".*?(<|href)", line): continue
        if re.match("\(.+?\)", line.strip()): continue
        if re.match("CUT TO:", line.strip()): continue
        indent = re.match("(\s*)([^\s]*?)", line).group(1)
        colonmatch = re.match("([A-Z\W0-9 \']+):(.+?)$", line.strip())

        if line.strip()=="":
            last_indent = "none"
            blanks+=1
        else:
            blanks = 0

        if len(film)< 15 and blanks > 3:
            film = [] # reset (everything before was just film information)

        if line.strip()=="": continue

        # if line is all uppercase, stock and break regardless
        if speech!="" and line.strip()!="" and (re.match("[A-Z\W 0-9\']+$", line) or re.match("[A-Z\W 0-9\']+[\:\-]", line)) and \
          not re.match("\W", line.strip()[-1]) and not colon:
            if DEBUG: print("hup", line.strip())
            if speaker: film.append( ("speech", speaker, speech) )
            else: film.append( ("scene", speech) )
            speech = ""
            speaker = ""

        #---------------------------------------------------------
        # start long list here!!!

        # for scripts formatted as character:speech

        # if numpass==2:
        #     print(line)
        #     print(colonmatch)
        #     if colonmatch:
        #         print(colonmatch.group(1))
        #         print(colonmatch.group(1) in uppercharacters)
        #     raw_input()

            
        if colonmatch and (colon or colonmatch.group(1) in uppercharacters):
            if speech!="":
                    if speaker: film.append( ("speech", speaker, speech) )
                    else: film.append( ("scene", speech) )
            speaker = colonmatch.group(1).strip()
            speech = colonmatch.group(2).strip()
            colonsep += 1
            
        # if pretty sure that it is a colon-separated script and this is scene info
        elif colon and line.strip()[0]=="(":
                if speech!="":
                    if speaker: film.append( ("speech", speaker, speech) )
                    else: film.append( ("scene", speech) )
                speaker = ""
                if line.strip!="": speech = line.strip()

        # in middle of speaker talking
        elif colon and speaker:
            if line.strip!="": speech +=" "+line.strip()

        elif colon and not speaker:
            if line.strip!="": speech += " "+line.strip()
        
        
        # for other scripts
        
        # if line has just speaker in it
        elif line.strip() in uppercharacters:
            if DEBUG: print("speaker: "+line.strip())
            # add previous speech/scene
            if speech!="":
                if speaker: film.append( ("speech", speaker, speech) )
                else: film.append( ("scene", speech) )
            speech = ""
            last_indent = ""

            # stock speaker
            speaker = line.strip()

            # if speaker_indent!="xxx" and speaker_indent==indent:
            #     if DEBUG: print([line])
            #     if DEBUG: print(len(indent))
            #     raw_input()
            
            # save indent type (1st pass)
            if "xxx" in speaker_indent:
                if indent not in indents["speaker"]: indents["speaker"][indent] = 0
                indents["speaker"][indent] += 1

                
        # name is an abbreviated form a of a known character (add it afterwards)
        elif re.match("[A-Z 0-9\']+(\(.+?\))?\s*$", line.strip()) and abbreviated_names(uppercharacters, line.strip()):
            if DEBUG: print("abbrev")
            # add previous speech/scene
            if speech!="":
                if speaker: film.append( ("speech", speaker, speech) )
                else: film.append( ("scene", speech) )
                
            newcharacter = abbreviated_names(uppercharacters, line.strip())
            speaker = newcharacter
            uppercharacters.append(newcharacter)
            character_actors.append(("", "", newcharacter, "", ""))

            
        elif line.strip() in names:
            if DEBUG: print("names")
            speaker = line.strip()
            uppercharacters.append(speaker)
            character_actors.append(("", "", speaker, "", ""))
            
            # add previous speech/scene
            if speech!="":
                if speaker: film.append( ("speech", speaker, speech) )
                else: film.append( ("scene", speech) )
            speech = ""
            last_indent = ""

            # stock speaker
            speaker = line.strip()
            
            # save indent type (1st pass)
            if "xxx" in speaker_indent:
                if indent not in indents["speaker"]: indents["speaker"][indent] = 0
                indents["speaker"][indent] += 1

        # # could be a single name, followed by something in brackets
        # elif re.match("[A-Z0-9 ]+ \(.+?\)$", line.strip()):

        #     speaker = line.strip().split("(")[0]
        #     uppercharacters.append(speaker)
        #     character_actors.append(("", "", speaker, "", ""))
            
        # is probably a speaker even though it doesn't satisfy the above (2nd pass)
        # RB: taken out constraint on speaker indent
        elif indent!=last_indent and re.match("[A-Z0-9 \W ]+(\(.+?\))?$", line.strip()) and \
            len(line.strip().split("(")[0].split()) < 3:
            if DEBUG: print("prob speaker"+line.strip())
            if DEBUG: print(speaker_indent)
            
            # add previous speech/scene
            if speech!="":
                if speaker: film.append( ("speech", speaker, speech) )
                else: film.append( ("scene", speech) )

            speech = ""
            speaker = line.strip().split("(")[0]
            uppercharacters.append(speaker)
            character_actors.append(("", "", speaker, "", ""))
            
        # in middle of speaker's speech or within a scene
        elif speech and indent==last_indent:
            if DEBUG: print("same indent")
            if line.strip()!="":
                speech += " "+line.strip()

            
        # probably speech, but no speaker (probably had scene information between)
        elif indent in speech_indent and not speaker and last_indent==indent:
            if DEBUG: print("prob speech but funny:"+line.strip())
            # get last speaker
            for item in reversed(film):
                if item[0]=="speech":
                    speaker=item[1]
                    break
            speech = line.strip()

        # probably speech, but no speaker (probably had scene information between)
        elif indent in speech_indent and not speaker and last_indent==indent:
            if DEBUG: print("prob speech but funny2:"+line.strip())
            if speech!="":
                film.append( ("scene", speech) )
            # get last speaker
            for item in reversed(film):
                if item[0]=="speech":
                    speaker=item[1]
                    break
            speech = line.strip()
            

        # just seen speaker in previous line but no text yet
        elif speaker and not speech:
            if DEBUG: print("first line of speech")
            last_indent = indent
            speech = line.strip()

            # save indent type
            if "xxx" in speaker_indent:
                if indent not in indents["speech"]: indents["speech"][indent] = 0
                indents["speech"][indent] += 1
            


        # the line is essentially blank and in middle of text
        # elif speech and line.strip()=="":
        #     if speaker: film.append( ("speech", speaker, speech) )
        #     else: film.append( ("scene", speech) )
        #     speech = ""

        # just seen speech but now scene information (indent different)
        elif speaker and speech and indent!=last_indent:
            if DEBUG: print("scene")
            # add speaker
            film.append( ("speech", speaker, speech) )
            speaker, speech = "", ""

            # start scene
            speech += line.strip()
            last_indent = indent

            # save indent type
            if "xxx" in speaker_indent:
                if indent not in indents["scene"]: indents["scene"][indent] = 0
                indents["scene"][indent] += 1

                
        # probably scene information
        elif last_indent==indent:  #indent in scene_indent and
            if DEBUG: print("continue scene")
            if speech!="":
                speech += " " + line.strip()
            else:
                speech = line.strip()

        elif indent in scene_indent:
            if DEBUG: print("new scene2: "+line.strip())
            # if DEBUG: print("probably scene")
            if speech!="":
                if speaker: film.append( ("speech", speaker, speech) )
                else: film.append( ("scene", speech) )
            speaker = ""
            speech = line.strip()

        # scene info but nothing before
        # elif not speaker and not speech and line.strip()!="":
        #     if DEBUG: print("new scene line: "+line.strip())
        #     # if DEBUG: print(len(indent))
        #     speech += line.strip()
        #     last_indent = indent

        #     # save indent type
        #     if "xxx" in speaker_indent:
        #         if indent not in indents["scene"]: indents["scene"][indent] = 0
        #         indents["scene"][indent] += 1

        # within scene but now a different indent
        elif not speaker and speech and last_indent!=indent:
            if DEBUG: print("diff indent")
            # if DEBUG: print(line.strip())
            # if DEBUG: print(len(indent))
            film.append( ("scene", speech) )
            speech = line.strip()
            last_indent = indent


        else:
            if DEBUG: print("default")
            if line.strip()!="": speech += " "+line.strip()
            
            #if DEBUG: print("oops ="+str([line]))

        last_indent = indent
            
        # print out
        # if "xxx" not in scene_indent and len(film)>0:
        #     if DEBUG: print(film[-1])
        #     raw_input()

        
    # for item in indents:
    #     if DEBUG: print(item)
    #     for indent in indents[item]:
    #         if DEBUG: print("\t"+str(len(indent))+": " +str(indents[item][indent]))
    #     if DEBUG: print("\n")

    # raw_input()


    if len(film)<10:
        return (None,)*6
    
    if "xxx" in speaker_indent:

        # TODO get several if there are a number of different ones
        
        speaker_indents = list(sorted(indents["speaker"].iterkeys(), key=(lambda key: indents["speaker"][key])))
        speech_indents = list(sorted(indents["speech"].iterkeys(), key=(lambda key: indents["speech"][key])))
        scene_indents = list(sorted(indents["scene"].iterkeys(), key=(lambda key: indents["scene"][key])))

        if len(speaker_indents)>0: speaker_indent = [speaker_indents[0]]
        else: speaker_indent = []
        if len(speech_indents)>0:speech_indent = [speech_indents[0]]
        else: speech_indent = []
        if len(scene_indents)>0:scene_indent = [scene_indents[0]]
        else: scene_indent = []

        # if DEBUG: print(indents["speaker"][speaker_indents[1]])
        # if DEBUG: print(indents["speech"].get(speaker_indents[1], 0))
        
        if len(speaker_indents)>1 and indents["speaker"][speaker_indents[1]] > indents["speech"].get(speaker_indents[1], 0) and\
          indents["speaker"][speaker_indents[1]] > indents["scene"].get(speaker_indents[1], 0):
          speaker_indent.append(speaker_indents[1])

        if len(speech_indents)>1 and indents["speech"][speech_indents[1]] > indents["scene"].get(speech_indents[1], 0) and\
          indents["speech"][speech_indents[1]] > indents["speaker"].get(speech_indents[1], 0):
          speech_indent.append(speech_indents[1])

        if len(scene_indents)>1 and indents["scene"][scene_indents[1]] > indents["speech"].get(scene_indents[1], 0) and\
          indents["scene"][scene_indents[1]] > indents["speaker"].get(scene_indents[1], 0):
          scene_indent.append(scene_indents[1])
        
    # if DEBUG: print(speaker_indent)
    # if DEBUG: print(speech_indent)
    # if DEBUG: print(scene_indent)
    # raw_input()

    # is colon-separated
    if colonsep > 10: colon = True
    else: colon = False

    # print(film)
    # print(len((film, character_actors, speaker_indent, speech_indent, scene_indent, colon)))
    # raw_input()
    
    return film, character_actors, speaker_indent, speech_indent, scene_indent, colon


    


def check_formatting(imdb_json_fname, characters_json_fname, htmldir, outdir):

    imdb2people = load_json(characters_json_fname)
    imdbinfo = load_json(imdb_json_fname)
    # formats = read_format_file(format_fname)
    found = 0
    notfound = 0

    i = 0
    for film in imdbinfo:
        imdb, name, date, writers = tuple(film)

        if i<739:
            i+=1
            continue

        # print(name)
        # print(imdb2people[imdb])
        # print(imdb)
        # raw_input()
        
        # double pass
        # thing = extract_script(htmldir+"/"+str(imdb)+"."+name+".html", imdb2people[imdb])
        # print(thing)
        # print(len(thing))

        if imdb not in imdb2people:
            os.sys.stderr.write("Will deal with "+name+" later... ignoring for now\n")
            continue

        
        film, characters, speaker_indent, speech_indent, scene_indent, colon = extract_script(htmldir+"/"+str(imdb)+"."+name+".html", imdb2people[imdb])

        # if DEBUG:
        #     print([speaker_indent])
        #     raw_input()

        if not film:
            os.sys.stderr.write(str(i)+": Problem with "+name+" ("+str(imdb)+")\n")
            continue
        
        film, _, _, _, _, _ = extract_script(htmldir+"/"+str(imdb)+"."+name+".html", characters, speaker_indent, scene_indent, speech_indent, colon)

        
        os.sys.stderr.write(str(i)+": Ok for "+name+" ("+str(imdb)+")\n")
        
        # if DEBUG: print(len(speech_indent))
        # if DEBUG: print(len(speaker_indent))
        # if DEBUG: print(len(scene_indent))
        # if DEBUG: print(characters)
        
        dump_json(film, outdir+"/"+str(date)+"."+str(imdb)+"."+name+".json")
        
        # for scene in film:
        #     if DEBUG: print(scene)
        #     raw_input()

        i += 1

        # exit()



