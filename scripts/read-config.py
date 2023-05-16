#!/usr/bin/python3
# This simple script is used for reading values from INI configuration file

import configparser;
import sys;

def usage():
    sys.stderr.write("Usage: read_config.py FILENAME SECTION PARAM\n")
    sys.stderr.write("or\n")
    sys.stderr.write("Usage: read_config.py FILENAME\n")

if (len(sys.argv) == 4):
    configfile = sys.argv[1]
    section = sys.argv[2]
    param = sys.argv[3]
    try:
        config = configparser.ConfigParser()
        config.read(configfile)
        print (config.get(section, param))
    except:
        print ("")
elif (len(sys.argv) == 2):
    configfile = sys.argv[1]
    try:
        config = configparser.ConfigParser()
        config.read(configfile)
        sections = config.sections()
        while "common" in sections: sections.remove("common")
        print (*sections)
    except:
        print ("")
else:
    usage()
    sys.exit(1)
