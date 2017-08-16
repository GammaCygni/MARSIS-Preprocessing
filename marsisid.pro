; Katy Fallows, Boston University
; September 2013
;--------------------------------------------------------------------------------

FUNCTION MARSISID, INDEX = ind, DOYYYYY = doyin, DOY2005 = doy2005, DATE = datein, $
         orbit = orbitin, STRUCT = struct, FILE = file, silent = silent
  
;--------------------------------------------------------------------------------
;
; Given one identifier of an MARSIS data point, in marsis data set, find the others.
;
; INPUTS:  INDEX   - index in marsis data structure structure, integer out of 168724
;          DOYYYYY - day of year and year, format 'DDD-YYYY'
;          DOY2005   - day of year since 1/1/2005
;          xxx NAME    - name of occultation profile, e.g. '0306B35A.EDS'
;          DATE    - calendar date, in format YYYY-MM-DD
;          FILE    - if I pass this, can I avoid the time of loading it each time I call this?
;
; RETURNS - Array containing all of the above identifiers
;
;--------------------------------------------------------------------------------
  
IF N_ELEMENTS(file) EQ 0 THEN $
  RESTORE, 'C:\Users\kfallows\IDLWorkspaces\General\Data\MARSIS\peak_edens_working_array_16jan2014.sav' $
ELSE RESTORE, file
    mdoy2005 = DOY_2005_SORT
    nmeas = N_ELEMENTS(mdoy2005)
    orbits  = ORBIT_SORT 

    nids = 5
    monthdays = [31,28,31,30,31,30,31,31,30,31,30,31] 
    if n_elements(doy2005) ne 0 THEN doy2005 = FLOOR(doy2005)    ; Decimal in MARSIS file; convert in case not already done.

    refjuldate = JULDAY(12,31,2004)
    CALDAT, (FLOOR(mdoy2005) + refjuldate), mm, dd, yyyy
    ;stop
    sdates = STRING(yyyy,F='(I04)')+'-'+STRING(mm,F='(I02)')+'-'+STRING(dd,F='(I02)')
    mdoy = FLTARR(nmeas)
    FOR i=0,nmeas-1 DO BEGIN
        mdoy[i] = TOTAL(monthdays[0:mm[i]-1]) - monthdays[mm[i]-1] + dd[i]
        IF yyyy[i] EQ 2008 OR yyyy[i] EQ 2012 THEN BEGIN
            IF mdoy[i] GT 60 THEN mdoy[i] = mdoy[i] + 1
        ENDIF
    ENDFOR
    
    nind   = N_ELEMENTS(ind)
    ndoy   = N_ELEMENTS(doyin)
    ndoy05 = N_ELEMENTS(doy2005)
    ndate  = N_ELEMENTS(datein)
    norb   = N_ELEMENTS(orbitin)
    
    npin      = nind > ndoy > ndoy05 > ndate > norb ; number of input dates/profiles
    maxdays   = 880                               ; max possible profiles on one date.
    savecount = INTARR(npin)                      ; for number of profiles on each of input dates
    
    IDarray = STRARR(npin, maxdays, nids)            ; for ID results, (input date, profile, ID)


    FOR i = 0,npin-1 DO BEGIN
    
      count = 1
      
      IF N_ELEMENTS(doyin) NE 0 THEN doy = STRSPLIT(doyin[i], '-', /EXTRACT)
      
           IF nind   NE 0 THEN p = ind[i] $
      ELSE IF ndoy   NE 0 THEN p = WHERE((MDOY EQ FIX(doy[0])) AND (YYYY EQ FIX(doy[1])), count) $
      ELSE IF ndoy05 NE 0 THEN p = WHERE(FLOOR(MDOY2005) EQ doy2005[i], count) $
      ELSE IF ndate  NE 0 THEN p = WHERE(sdates EQ datein[i], count) $
      ELSE IF norb   NE 0 THEN p = WHERE(orbits EQ orbitin[i], count)
      
      savecount[i] = count
      
      IF count GT 0 THEN BEGIN
      
        ;IDsi = STRARR(N_ELEMENTS(p)*5)
        IDsi = [ STRING(p), $
          STRING(MDOY[p], F='(I3)')+'-'+STRING(YYYY[p],F='(I4)'), $
          STRING(MDOY2005[p],F='(I4)'), $
          sdates[p], $
          STRING(orbits[p],F='(I5)') ]
          
        IDs = REFORM(IDsi, count, nids)
        
        IDarray[i,0:count-1,*] = IDs
        
      ENDIF ELSE BEGIN
          IF KEYWORD_SET(silent) EQ 0 THEN $    
          PRINT, 'Input profile/date '+STRTRIM(i,1)+' not found in MARSIS data.'
      ENDELSE
      
    ENDFOR
    
    maxcount = MAX(savecount)
    IDarray = IDarray[*,0:maxcount-1,*]   ;get rid of empty dates
    
    RETURN, IDarray

END