# MARSIS-Preprocessing

Includes various files for downloading, parsing, viewing, and organizing MARSIS ionogram
data files. Accesses publicly available data on the NASA Planetary Data System.  Requires 
the astronomy IDl library.

fetch_ais.pro downloads the data for the specified orbit; if not available, adds the
  orbit to a running list of unavailable files, via orbit_available.pro
  
orbit_available.pro checks adds an orbit to a list of missing or unavailable data

load_ais_orbit.pro reads in the data files and selects out the useful quantites in
  useful formats for analysis - arrays with power, frequency, and time delay
  
make_geomars.pro reads in a series of files with ancillary data about each orbit and
  compiles them into one .sav file in array format
  
marsisid.pro compiles various identifiers for each orbit (orbit number, string date,
  day of year, etc.) for easy lookup when comparing data sets labelled differently
