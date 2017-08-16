; Either:  1. Check to see if a MARSIS orbit is available by consulting a list
;          2. Add a missing orbit to the list.
;
;Returns:  1 if the orbit is on the missing list
;          0 if the orbit is not on the missing list (and, presumably, available)

FUNCTION orbit_available, find = orb_find, add = add

IF KEYWORD_SET(add) THEN addflag = 1 ELSE addflag = 0

list_file = 'C:/Users/kfallows/IDLWorkspaces/General/Data/MARSIS/MissingOrbits.txt'
READCOL, list_file, orbs_miss, /silent

x = WHERE(orbs_miss EQ orb_find, count)

IF KEYWORD_SET(add) THEN BEGIN
    IF count LE 0 THEN BEGIN
        OPENU, lun2, list_file, /get_lun, /append
        PRINTF, lun2, orb_find
        CLOSE, lun2
        FREE_LUN, lun2
        PRINT, 'Orbit '+STRING(orb_find,F='(I5)')+' added to missing list.'
    ENDIF
    RETURN, 1
ENDIF ELSE BEGIN
    IF count GT 0 THEN RETURN, 1 $
                  ELSE RETURN, 0
ENDELSE

END

