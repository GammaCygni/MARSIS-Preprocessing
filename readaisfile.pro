PRO readaisfile, orbit = orbit, frame = frame, datapath = datapath, $
    freq = freq2darr, delaytime = time2darr, power = powerarr, $
    stimes = timelabels, dectimes = dectimes, ngrams = ngrams

; The goal of this is simply to read in the AIS binary file and return key pieces, 
; and/or to save them to a .sav file.  Many of these pieces are in ionogram.pro
; and ionogram_info.pro, but I think they need to be streamlined a bit, and 
; organized so that the same data isn't being repeatedly read in unnecessarily
 
; -----------------------------------------------------------------------------

allflag = 0
IF N_ELEMENTS(frame) EQ 0 THEN allflag = 1
IF NOT KEYWORD_SET(datapath) THEN datapath = 'C:\Users\kfallows\IDLWorkspaces\General\Data\MARSIS\'

sorbitin = STRTRIM(STRING(orbit,F='(I5)'),2)

aisfile = datapath+'frm_ais_rdr_'+sorbitin+'.dat'
result = FILE_TEST(aisfile)

onlist = orbit_available(find=orbit)
IF onlist THEN BEGIN
  PRINT, 'Orbit '+sorbitin+' is on missing orbit list.'
  RETURN
ENDIF


IF NOT result AND NOT onlist THEN BEGIN
    PRINT, 'Attempting to download AIS file for '+sorbitin+'.'
    fetch_ais, orbit, respcode = rc
    IF NOT (rc EQ !NULL) THEN BEGIN
      PRINT, '  Readaisfile: No file for orbit '+sorbitin+'.'
      dummy = orbit_available(find=orbit, /add)
      ngrams = -1
      RETURN
    ENDIF
ENDIF


x = file_lines(aisfile)
l = 160

;iend = l*frame
;istart = l*(frame-1)

x = get_number_frames(orbit, stoptime = stoptime)

IF allflag THEN BEGIN
    ngrams = x
    fstart = LONG(0)
    fend = LONG(ngrams)
ENDIF ELSE BEGIN
    ngrams = 1
    fstart = LONG(frame)
    fend = LONG(frame)+1
ENDELSE

freqarr = dblarr(l)
powerarr = dblarr(ngrams,l,80)
freq2darr_out = powerarr*0.
time2darr = freq2darr_out

timelabels = strarr(ngrams)
dectimes   = dblarr(ngrams)

; As is this pulls out only one frame. 
 
openr, lun1, aisfile, /get_lun


breakflag = 0

i=LONG(0)
for f=0,ngrams-1 do begin

    f2 = fstart+f

    iend = l*(f2+1)-1
    istart = l*f2
    
    while i le iend do begin
    
      col01 = 0L
      col02 = 0S
      col03 = 0S
      col04 = 0L
      col05 = 0L
      gap02 = bytarr(8)
      col06 = '                        '
      ;col06 = bytarr(24)
      col07 = 0B
      col08 = 0B
      gap03 = bytarr(9)
      col09 = 0B
      col10 = 0B
      col11 = 0B
      col12 = 0B
      col13 = 0B
      gap01 = bytarr(12)
      col14 = 0E
      col15 = fltarr(80)
      
      
      readu, lun1, col01
      readu, lun1, col02
      readu, lun1, col03
      readu, lun1, col04
      readu, lun1, col05
      readu, lun1, gap02
      readu, lun1, col06
      readu, lun1, col07
      readu, lun1, col08
      readu, lun1, gap03
      readu, lun1, col09
      readu, lun1, col10
      readu, lun1, col11
      readu, lun1, col12
      readu, lun1, col13
      readu, lun1, gap01
      readu, lun1, col14
      readu, lun1, col15
      
      ;if i eq istart+2 then $
      ;print, col01, col02, col03, col04, col05, gap02, col06, col07, col08, gap03, col09, col10, col11, col12, col13, gap01, col14, col15
      
      if i ge istart then begin
        ;print, i, i-istart
        freqarr(i-istart) = swap_endian(col14)
        powerarr(f,i-istart,*) = swap_endian(col15)
      endif
      
      i++
    endwhile
    
    j=0
    while j lt 80 do begin
      freq2darr_out(f,*,j) = freqarr(*)
      time2darr(f,*,j) = 91.4e-6 * (j+1) + 162.5e-6
      j++
    endwhile

    
    timelabel = STRSPLIT(col06, 'T', /EXTRACT)
    stime = timelabel[1]
    timejunk = STRSPLIT(stime, ':', /EXTRACT)
    dtime = timejunk[0] + timejunk[1]/60. + timejunk[2]/60.0^2
    
    timelabels[f] = stime
    dectimes[f] = dtime

    ;print, stime

    ;      if f EQ 232 THEN BEGIN
    ;          help, col06, stoptime
    ;          print, col06, stoptime
    ;          if strtrim(col06,2) eq strtrim(stoptime,2) then print, 'match'
    ;          stop
    ;      ENDIF
    
    if strtrim(col06,2) eq strtrim(stoptime,2) then begin
      ngrams = f+1
      breakflag = 1
      break
    endif

end  ;f

IF breakflag THEN BEGIN

    freq2darr_out = freq2darr_out[0:ngrams-1,*,*]
    time2darr = time2darr[0:ngrams-1,*,*]
    powerarr = powerarr[0:ngrams-1,*,*]
    timelabels = timelabels[0:ngrams-1]
    dectimes = dectimes[0:ngrams-1]

ENDIF  

free_lun, lun1
freq2darr = freq2darr_out

END