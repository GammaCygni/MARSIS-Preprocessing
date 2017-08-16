; This procedure is to ingest and organize the ancillary information for
; the MARSIS ionograms on PDS.  There is one "geo_mars.dat" file for each
; of the primaey and extended mission.
; I want to both get all of this data, and then find the subset for which
; there is a matching point in our set of peak densities from Dave Morgan

; **** This has been subsumed into marsis_flare_selection_v3.pro

pro make_geomars

datapath = 'C:\Users\kfallows\IDLWorkspaces\General\Data\MARSIS\'
RESTORE, datapath+'peak_edens_working_array_16jan2014.sav'
  
    doy2005 = FLOOR(DOY_2005_SORT)    ; DOUBLE    = Array[168724] - doy2005 only, no time/decimal info
    ddoy2005 = DOY_2005_SORT   ; DOUBLE    = Array[168724] - Decimal doy2005 (includes time of day as fraction of day)
    lat     = LAT_SORT         ; FLOAT     = Array[168724]
    orbit   = ORBIT_SORT       ; INT       = Array[168724]
    nmax    = PEAK_EDENS_SORT  ; FLOAT     = Array[168724]
    sza     = SZA_SORT         ; FLOAT     = Array[168724]
    timelab    = TIME_LABEL_SORT  ; LONG      = Array[168724] - hhmmss
    lon     = WLON_SORT        ; FLOAT     = Array[168724]

mdates = [31,28,31,30,31,30,31,31,30,31,30,31]
ddoy05_leap = [1155, 2616, 4077]                ;2008-2-29, 2012-2-29, 2016-2-29
  
geofiles = FILE_SEARCH(datapath, 'geo_mars*.tab')
nfiles = N_ELEMENTS(geofiles)

ddoypds = []
orbitpds = []
altitude = []
alts = []
datetime = []
latitude = []
longitude = []
sza_pds = []

LSpds = []
LTSTpds = []
sslon_pds = []
sslat_pds = []

PRINT, ''

FOR f=0,nfiles-1 DO BEGIN
  
  PRINT, 'Reading geofile '+STRTRIM(f,1)+':'
  
  READCOL, geofiles[f], /silent, $
    v1,v2,v3,v4,v5,v6,v7,v8,v9, datetime0,orbitpds0,LS0,sslat0,sslon0, v15, $
    v16,v17,v18,v19,v20,v21,v22,v23,v24,v25,v26,v27, altitude0, $
    latitude0,longitude0, v31, LTST0, $
    FORMAT = 'F,F,A,A,A,A,A,F,F,A,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,F,A,F', $
    DELIMITER = ' ,"'
    
  ;2005-06-23T22:05:24.308
  nrecords0 = FILE_LINES(geofiles[f])
  ddoypds0 = DBLARR(nrecords0)
  savemms = INTARR(nrecords0)
  
  ; OMG AM I SKIPPING LEAP DAYS IN HERE?  THAT WOULD BE SUPER LAME. WHY IS THIS ONLY A PROBLEM NOW!?
  ;leap = 0
  
  for j=0,nrecords0-1 do begin
    timejunk = STRSPLIT(datetime0[j], '-T:', /EXTRACT)
    mm = FIX(timejunk[1])
    savemms[j] = mm
    ddoypds0[j] = (FIX(timejunk[0])-2005)*365 + $
      (TOTAL(mdates[0:mm-1])-mdates[mm-1]) + $
      FIX(timejunk[2]) + $
      DOUBLE(timejunk[3])/24. + $
      DOUBLE(timejunk[4])/(24.*60.) + $
      DOUBLE(timejunk[5])/(24.*60.*60) 
      ;+ leap
    
  endfor

;increment ones that should have leap days in them
  for l = 0,2 do begin
    x = where(FLOOR(ddoypds0) gt ddoy05_leap[l])
    y = where(FLOOR(ddoypds0) eq ddoy05_leap[l] and savemms eq 3)
    ddoypds0[x] = ddoypds0[x]+1
    ddoypds0[y] = ddoypds0[y]+1
  endfor
  
  ; find matching quantities for the peak densities\
  ; find altitudes in geomars that match peak density array
  
  asub = where(ddoy2005 le max(ddoypds0) and ddoy2005 ge min(ddoypds0), count)
  sza0 = FLTARR(nrecords0)
  
  IF count GT 0 THEN BEGIN
    
      PRINT, ' ... Matching PDS and Density records'

      alts0 = FLTARR(count)
      for p=0,count-1 do begin
        index = closest(ddoypds0, ddoy2005[asub[p]], /one)
        if ABS(ddoypds0[index]-ddoy2005[asub[p]]) LT 1E-3 THEN BEGIN
          alts0[p] = altitude0[index] 
        endif else begin
          alts0[p] = !VALUES.F_NAN
        endelse
        if p mod 1000 eq 0 then print, '  ', p, alts0[p], orbitpds0[index], ddoypds0[index], orbit[asub[p]], ddoy2005[asub[p]]
        ;if ( p lt 7700 and p gt 7500 ) then print, p, alts0[p], orbitpds0[index], ddoypds0[index], orbit[asub[p]], ddoy2005[asub[p]] 
      endfor
    
      for q=0,nrecords0-1 do begin
        index = closest(ddoy2005, ddoypds0[q], /one)
        if ABS(ddoypds0[q]-ddoy2005[index]) LT 1E-3 THEN BEGIN
          sza0[q] = sza[index]
        endif else begin
          sza0[q] = !VALUES.F_NAN
        endelse  
      endfor
  ENDIF ELSE BEGIN
      sza0[*] = !VALUES.F_NAN
      alts0 = []
  ENDELSE
  
  PRINT, ' ... Updating output arrays'
  ddoypds = [ddoypds,ddoypds0]
  orbitpds = [orbitpds,orbitpds0]
  altitude = [altitude,altitude0]
  alts = [alts,alts0]
  datetime = [datetime,datetime0]
  latitude = [latitude,latitude0]
  longitude = [longitude,longitude0]
  sza_pds = [sza_pds,sza0]
  LSpds = [LSpds,LS0]
  LTSTpds = [LTSTpds,LTST0]
  sslon_pds = [sslon_pds,sslon0]
  sslat_pds = [sslat_pds,sslat0]
  
endfor
setwin
plot, ddoypds, LTSTpds

stop
savefile = datapath+'MARSIS_PDS_geomars4.sav'

PRINT, ' '
PRINT, 'Saving output file '+savefile

help, ddoypds, orbitpds, altitude, datetime, latitude, longitude, alts, sza_pds, $
      LSpds, LTSTpds, sslon_pds, sslat_pds
SAVE, ddoypds, orbitpds, altitude, datetime, latitude, longitude, alts, sza_pds, $
      LSpds, LTSTpds, sslon_pds, sslat_pds, $
    filename = savefile


end