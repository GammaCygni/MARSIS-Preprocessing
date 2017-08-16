pro fetch_ais, orbitin, respcode = RespCode

sorbitin = STRTRIM(STRING(orbitin,F='(I5)'),1)

datapath = 'C:\Users\kfallows\IDLWorkspaces\General\Data\MARSIS\'
aisfilename = 'frm_ais_rdr_'+sorbitin+'.dat'
lblfilename = 'frm_ais_rdr_'+sorbitin+'.lbl'


onlist = orbit_available(find=orbitin)
IF onlist THEN BEGIN
    PRINT, 'fetch_ais: Orbit '+sorbitin+' is on missing orbit list.'
    onlist = orbit_available(find=orbitin, /add)
    RETURN
ENDIF


; These limits were determined by visually scanning the folders on PDS
;   for the lowest and highest orbit numbers.  Could do a more thorough
;   search, but probably won't.

CASE 1 OF
    (orbitin GE 1844) AND (orbitin LE 2539): mission = 1
    (orbitin GE 2540) AND (orbitin LE 4598): mission = 2
    (orbitin GE 4800) AND (orbitin LE 7669): mission = 3
    (orbitin GE 7695) AND (orbitin LE 11440): mission = 4
    (orbitin GE 11450) AND (orbitin LE 13969): mission = 5
    ELSE: BEGIN
            PRINT, 'fetch_ais: No AIS file for that orbit.'
            RespCode = -1
            RETURN
          END
ENDCASE

smission = STRING(mission,F='(I1)')
smission1 = STRING(mission-1,F='(I1)')

IF mission GT 1 THEN extension = '-ext'+smission1 ELSE extension = ''

folder1 = 'mex-m-marsis-3-rdr-ais'+extension+'-v1/
folder2 = 'mexmdi_100'+smission+'/'
folder3 = 'rdr'+STRMID(sorbitin,0,3)+'x/'

destination = 'http://pds-geosciences.wustl.edu/mex/'+folder1+folder2+'data/active_ionospheric_sounder/'+folder3


obj = obj_new('IDLnetURL')



CATCH, Error_status

;This statement begins the error handler:

;RespCode = !NULL
IF Error_status NE 0 THEN BEGIN
  obj->GetProperty, RESPONSE_CODE=RespCode
  PRINT, 'Error downloading orbit '+sorbitin+': '+ STRTRIM(RespCode,1)
  FILE_DELETE, datapath+aisfilename, /ALLOW_NONEXISTENT
  RETURN
  CATCH, /CANCEL
ENDIF

dat_result = obj->Get( FILENAME=datapath+aisfilename, URL=destination+aisfilename)
lbl_result = obj->Get( FILENAME=datapath+lblfilename, URL=destination+lblfilename)

PRINT, 'Downloaded: '
PRINT, '  '+dat_result
PRINT, '  '+lbl_result

OBJ_DESTROY, obj

end