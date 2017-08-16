; Katy Fallows, 1/19/2016
; Load the MARSIS AIS data for the specified orbit. 
; Adapted from readais.pro, Paul Withers, 2014.10.01, Astronomy Department, Boston University


PRO load_ais_orbit, datapath = datapath, filename = filename, orbit = orbit, ngrams = ngrams, $
                    frequency = freq2darr, returntime = time2darr, power = powerarr, frametime = frametime, $
                    ftimelabel = frametimelabel
                  

; -----------------------------------------------------------------------------
; INPUTS: DATAPATH - path to find the AIS data files
;         FILENAME - name of data file for the orbit
;         ORBIT    - the orbit for which data should be loaded
;         NGRAMS   - number of ionograms in the orbit, if not all 
;
; OUTPUTS: frequency - frequencies swept through during data collection (Y)
;          return time - return time (X)
;          power - reflected power at a given return time and frequency P(X,Y)
;
; -----------------------------------------------------------------------------

IF NOT KEYWORD_SET(datapath) THEN datapath = 'C:\Users\kfallows\IDLWorkspaces\General\Data\MARSIS\'
IF NOT KEYWORD_SET(orbit) THEN orbit = 2359
IF NOT KEYWORD_SET(frame) THEN frame = 1 
;IF NOT KEYWORD_SET(filename) THEN outfile = 'C:\Users\kfallows\IDLWorkspaces\MARSIS Flares\ionogram_'+STRING(orbit,F='(I04)')+'_f'+STRING(frame,F='(I03)')+'.ps'

IF NOT KEYWORD_SET(filename) THEN aisfile = datapath+'frm_ais_rdr_'+STRING(orbit,F='(I04)')+'.dat' ELSE aisfile = filename
labfile = datapath+'frm_ais_rdr_'+STRING(orbit,F='(I04)')+'.lbl'


cycletime = 7.54  ;s

IF NOT KEYWORD_SET(ngrams) THEN BEGIN
;Find the number of ionograms along the orbit from the label file, using the start time, stop time, and cycle time.

    OPENR, lun1, labfile, /GET_LUN

    i=0L
    WHILE NOT EOF(lun1) DO BEGIN
      line = ''
      READF, lun1, line
      ;PRINT, line, STRPOS(line, 'START_TIME'), STRPOS(line, 'STOP_TIME')
      IF STRPOS(line, 'START_TIME') GE 0 THEN BEGIN
        ;PRINT, line
        timejunk = STRSPLIT(line, '=', /EXTRACT)
        timejunk = STRSPLIT(timejunk[1], 'T:', /EXTRACT)
        time1 = timejunk[1]*60^2 + timejunk[2]*60+timejunk[3]
      ENDIF
      IF STRPOS(line, 'STOP_TIME') GE 0 THEN BEGIN
        ;PRINT, line
        timejunk = STRSPLIT(line, '=', /EXTRACT)
        timejunk = STRSPLIT(timejunk[1], 'T:', /EXTRACT)
        time2 = timejunk[1]*60^2 + timejunk[2]*60+timejunk[3]
      ENDIF
      i++
      ;if i eq 16 then stop
    ENDWHILE
    
    ngrams = FIX( (time2-time1)/cycletime ) + 1

    FREE_LUN, lun1

ENDIF


x = file_lines(aisfile)
l = 160L                ;some sort of "size" of one ionogram (frame) - number of frequencies, I think.
r = 80L                 ;return time bins

;iend = l*frame
;istart = l*(frame-1)
istart = 0
iend = l*ngrams

frametimelabel = strarr(ngrams)
frametime = fltarr(ngrams)

freqarr = dblarr(ngrams,l)
powerarr = dblarr(ngrams,l,r)

col06 = !NULL

openr, lun1, aisfile, /get_lun
i=0L
while i lt iend do begin

  freq = i MOD l          ; 0 to 159
  frame = LONG(i)/LONG(l)   ; 0 to ngrams-1

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
  col15 = fltarr(r)
  
  IF EOF(lun1) THEN BEGIN
    endframe = frame-1
    RETURN    
  ENDIF
  
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
    ;    freqarr(i-istart) = swap_endian(col14)
    ;    powerarr(i-istart,*) = swap_endian(col15)
    freqarr(frame,freq) = swap_endian(col14)
    powerarr(frame,freq,*) = swap_endian(col15)
  endif

;if freq eq 0 then print, frame, powerarr(frame,freq,0)
  
  timelabel = STRSPLIT(col06, 'T', /EXTRACT)
  timejunk = STRSPLIT(timelabel[1], ':', /EXTRACT)
  frametime[frame] = FLOAT(timejunk[0]) + FLOAT(timejunk[1])/60. + FLOAT(timejunk[2])/60.^2 
  frametimelabel[frame] = timelabel[1]

;if freq eq 0 then print, i, frame, freq, freqarr[frame,freq], frametimelabel[frame]
  
  i++
endwhile
free_lun, lun1

IF col06 EQ !NULL THEN BEGIN
  endframe = frame-1
  RETURN
ENDIF

blah=0
if blah ne 0. then begin
  help, swap_endian(col01)
  help, swap_endian(col02)
  help, swap_endian(col03)
  help, swap_endian(col04)
  help, swap_endian(col05)
  help, col06
  
  help, col07
  help, col08
  help, col09
  help, col10
  help, col11
  help, col12
  help, col13
  
  help, col14, swap_endian(col14)
  
  print, swap_endian(col15)
  
  print,''
  print,''
  help, col06
endif

freq2darr = powerarr*0.
time2darr = freq2darr

i=0
while i lt r do begin
  ; powerarr(frame,freq,*) = swap_endian(col15)
  freq2darr(*,*,i) = freqarr(*,*)
  time2darr(*,*,i) = 91.4e-6 * (i+1) + 162.5e-6
  i++
endwhile

; --- An estimate of true altitude from apparant range
; ----- Would like to revisit later if I can.

;tracetimearr = dblarr(l)
;tracetimearr(62:82) = time2darr(0,9)
;tracetimearr(83:90) = time2darr(0,10)
;tracetimearr(91:94) = time2darr(0,11)
;
;;tracetimearr(95:107) = time2darr(0,12)
;;tracetimearr(108:123) = time2darr(0,13)
;
;tracetimearr(95:110) = time2darr(0,12)
;tracetimearr(111:123) = time2darr(0,13)
;
;tracetimearr(124:128) = time2darr(0,14)
;tracetimearr(129) = time2darr(0,15)
;tracetimearr(130) = time2darr(0,16)
;
;tracetimearr(62:130) = tracetimearr(62:130) + 0.5*(time2darr(0,9)-time2darr(0,8))
;
;
;
;freq_arr_mhz = freqarr(62:130)/1e6
;time_arr_msec = tracetimearr(62:130)/1e-3
;
;freq_arr_mhz = [0.075, freq_arr_mhz] ; Value from figure 4 of Morgan et al.
;time_arr_msec = [0., time_arr_msec]
;
;;freq_arr_mhz = freq_arr_mhz[0:4]
;;time_arr_msec = time_arr_msec[0:4]
;
;c_kmps = 3e5
;
;nfreqs = n_elements(freq_arr_mhz)
;range_exp = dblarr(nfreqs)
;alpha_arr = dblarr(nfreqs)
;freq_rat = dblarr(nfreqs, nfreqs)
;diff_exp = dblarr(nfreqs, nfreqs)
;
;freq_arr = freq_arr_mhz*1e6
;l_rat_freq = alog(freq_arr(1:*)/freq_arr)
;
;time_arr = time_arr_msec*1e-3 / 2.
;time_arr(0) = 0.
;app_range = c_kmps * time_arr
;
;for i=1, nfreqs-1 do begin
;  freq_rat(i,0:i) = freq_arr(0:i)/freq_arr(i)
;endfor
;
;oldfreq_rat = freq_rat
;
;freq_rat = asin(freq_rat)
;for i=1, nfreqs-1 do begin
;  freq_rat(i,i) = !dpi/2.d0
;endfor
;
;cos_f = cos(freq_rat)
;exp_weight = 0.5*alog((1.d0-cos_f)/(1.d0+cos_f))
;
;for i=1, nfreqs-1 do begin
;  diff_exp(i,1:i) = exp_weight(i,1:i) - exp_weight(i,0:i-1)
;endfor
;
;alpha_arr(1) = -1.d*diff_exp(1,1)/app_range(1)
;
;for i=2, nfreqs-1 do begin
;  alpha_arr(i) = -1.d * diff_exp(i,i) / $
;    (app_range(i) + total((diff_exp(i,1:i-1)/alpha_arr(1:i-1))))
;endfor
;
;range_exp(0) = 0d
;
;for i=1, nfreqs-1 do begin
;  range_exp(i) = range_exp(i-1)-l_rat_freq(i-1)/alpha_arr(i)
;endfor
;
;truezkm = 315. - range_exp ; 315 km is an eyeballed spacecraft altitude from Morgan et al. figure 8



;------------------------------------------------------------------------------
; Plot this stuff
;------------------------------------------------------------------------------

;SETPS
LOADCT, 39, /SILENT

;IF NOT KEYWORD_SET(panel) AND NOT KEYWORD_SET(win) THEN $
;    DEVICE,  filename=outfile, /portrait, /bold, decomposed=0

;!p.background = 255
;!p.charthick = 1.0
;charsize = 1.5
;position = [0.15,0.15,0.75,0.9]
;barposition = [0.90, 0.15, 0.95, 0.95]
;ybartitle = -25
;IF KEYWORD_SET(quarter) THEN BEGIN
;    positions = [ [0.10,0.57,0.40,0.90], [0.55,0.57,0.80,0.90], [0.10,0.10,0.40,0.48], [0.550,0.10,0.80,0.48] ]
;    position = positions[*,quarter-1]
;    barposition = [position[2]+0.07, position[1], position[2]+0.10, position[3]]
;    charsize = 1.0
;    ybartitle = 30
;ENDIF
;
;timelabel = STRSPLIT(col06, 'T', /EXTRACT)
;
;PLOT, [0,4], [0,3], /nodata, font=1, $
;    title = 'Orbit '+STRING(orbit,F='(I4)')+', '+timelabel[1], charsize = charsize, color = 0, $
;    xtitle='Frequency (MHz)',  xticks=8, xminor=5, xra = [0,CEIL(MAX(freq2darr)/1E6)], xstyle=1, $
;    ytitle='Time delay (msec)',  ystyle=1, yrange = [8,0], $   ; yrange = [3,0] , yra=[CEIL(MAX(time2darr)*1E3),0]
;    ;position=[0.15,0.15,0.75,0.9]
;    position = position
;  
;    i=0
;    while i lt 160-1 do begin
;      j=0
;      while j lt 80-1 do begin
;      
;        colfill = (alog10(powerarr(i,j))+17.)/8. * 255.
;        if colfill lt 0 then colfill = 0
;        ; ^ Without this line, when using window, will assign colors to -255 (black) through -1 (red)
;        ;     don't know why, but this fixes it.
;        ;print, (alog10(powerarr(i,j))+17.), colfill
;        ;if time2darr(i+1,j+1)/1e-3 lt 3 then $
;        polyfill, [freq2darr(i,j), freq2darr(i+1,j), freq2darr(i+1,j), freq2darr(i,j)]/1e6, $
;          [time2darr(i,j), time2darr(i,j), time2darr(i,j+1), time2darr(i,j+1)]/1e-3, color=colfill
;        
;         ;if i eq 150 then print, powerarr(i,j), colfill
;          
;        j++
;      endwhile
;      ;stop
;      i++ 
;    endwhile
;
;;OPLOT, freqarr(62:130)/1e6, tracetimearr(62:130)/1e-3, color=255
;;OPLOT, [freqarr(62)]/1e6, [tracetimearr(62)]/1e-3, psym=7, symsize=2, color=255
;;OPLOT, [freqarr(130)]/1e6, [tracetimearr(130)]/1e-3, psym=7, symsize=2, color=255
;
;
;;PLOT, [0,4], [0,3], /nodata, /noerase, $
;;  xtitle='Frequency (MHz)', xticks=8, xminor=5, $
;;  ytitle='Time delay (msec)', yra=[3,0], /ystyle;, $
;;  ;position=[0.15,0.15,0.75,0.9]
;;  position = position
;;  
;cols = REVERSE(dindgen(255))
;ncol = n_elements(cols)
;scale = findgen(ncol)
;bar = [1,1]#scale
;cols = reverse(cols)
;
;CONTOUR, bar, [0,1], scale, c_colors=cols, levels=scale, cell_fill=1, charsize = charsize/2, color = 0, $
;  /noerase, yrange=[0,ncol-1], ystyle=1, xticks=1, $
;  xticklen=0.0002, xcharsize=0.002, position=barposition, $
;  yticks=4, ytickname=['1E-17', '1E-15', '1E-13', '1E-11', '1E-09']
;  
;XYOUTS, -1.5, ybartitle, 'Spectral power density (V!U2!N m!U-2!N Hz!U-1!N)', orientation=90, charsize = charsize, color = 0

;IF NOT KEYWORD_SET(panel) AND NOT KEYWORD_SET(win) THEN DEVICE, /CLOSE

;stop
END