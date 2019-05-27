\ sandmotorapi.fs

\    Copyright (C) 2018  Philip King Smith
\    This program is free software: you can redistribute it and/or modify
\    it under the terms of the GNU General Public License as published by
\    the Free Software Foundation, either version 3 of the License, or
\    (at your option) any later version.

\    This program is distributed in the hope that it will be useful,
\    but WITHOUT ANY WARRANTY; without even the implied warranty of
\    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\    GNU General Public License for more details.

\    You should have received a copy of the GNU General Public License
\    along with this program.  If not, see <http://www.gnu.org/licenses/>.

\ configures x and y motors and can control motors

\ Requires:
\ tmc2130.fs
\ BBB_GPIO_lib.fs
\ objects.fs
\ mdca-obj.fs
\ double-linked-list.fs

\ Revisions:
\ 11/09/2018 started coding
\ 19/12/2018 calibration simplified but needs to have realtime standard deviation impimented to detect bad calibration
\ - movetoxy has issues yet with speed and calculation errors... need to come up with better idea here
\ 28/1/2019 updated require list
\ many changes to calibration method with helper words for testing
\ movetoxy now does both x and y at same time based on y=mx+b slope idea
\ test outputs need to be removed yet from calibration or set up as a test flag conditional to output
\ 2/5/2019 drawline added and tested to act as windowed line drawing algorithom
\ added perallel line drawing algoritom to replace zigzag-clean
\ added quickstart to allow calibration less startup if know x y location of sandball

require tmc2130.fs
require realtimeMSD.fs
require Gforth-Objects/double-linked-list.fs

double-linked-list dict-new constant x-array-data
double-linked-list dict-new constant y-array-data
realtimeMSD dict-new constant xdata
realtimeMSD dict-new constant ydata
0 value xmotor
0 value ymotor
true value configured?  \ true means not configured false means configured
false value homedone?   \ false means table has not been homed true means table was homed succesfully
0 constant xm
1 constant ym
3000 value stopbuffer
0 constant xm-min
0 constant ym-min
274000 constant xm-max
274000 constant ym-max
1 constant forward
0 constant backward
true value xposition  \ is the real location of x motor .. note if value is true then home position not know so x is not know yet
true value yposition  \ is the real location of y motor .. note if value is true then home position not know so y is not know yet
1200 value silentspeed  \ loop wait amount for normal silent operation .... 500 to 3000 is operating range
8000 value xcalspeed
1 value xcalsteps
8000 value ycalspeed
1 value ycalsteps
75 value calstep-amounts
1.5e fvariable xcal-threshold-a xcal-threshold-a f!
2e fvariable xcal-threshold-b xcal-threshold-b f!
1.6e fvariable ycal-threshold-a ycal-threshold-a f!
2e fvariable ycal-threshold-b ycal-threshold-b f!
10 value steps
1 value xcalreg
1 value ycalreg
200 value calwait
32 value max-cal-test

\ ************ configure-stuff needs to be used first and return false to allow other operations with sandtable
: configure-stuff ( -- nflag ) \ nflag is false if configuration happened other value if some problems
  s" /home/debian/sandtable/config-pins.fs" system $? to configured?
  configured? 0 = if
    1 %10000000000000000 1 %10000000000000 1 %1000000000000 1
    tmc2130 heap-new to xmotor abort" xmotor did not construct"
    xmotor disable-motor
    1 %100000000000000000 1 %1000000000000000 1 %100000000000000 0
    tmc2130 heap-new to ymotor abort" ymotor did not construct"
    ymotor disable-motor

    \ GCONF uIHOLD_IRUN uTPOWERDOWN uTPWMTHRS uTCOOLTHRS uTHIGH uCHOPCONF   uCOOLCONF                  uPWMCONF
    %100 %01110001111100000000 1 0    0 0 %00110000000000101000000010010011 0                          %0111000000101011111111
    0 xmotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000000000000000000000000 %0001000000111111111111
    1 xmotor quickreg!
    1 xmotor usequickreg
    forward xmotor setdirection
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %0000000000000000000000000 %0111100000101011111111
    2 xmotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000111100000000000000000 %0001000000111111111111
    3 xmotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000101000000000000000000 %0001000000111111111111
    4 xmotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000010100000000000000000 %0001000000111111111111
    5 xmotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000000000000000000000000 %0001000000111111111111
    6 xmotor quickreg!

    %100 %01110001111100000000 1 0    0 0 %00110000000000101000000010010011 0                          %0111000000101011111111
    0 ymotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000000000000000000000000 %0001000000111111111111
    1 ymotor quickreg!
    1 ymotor usequickreg
    forward ymotor setdirection
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %0000000000000000000000000 %0111100000101011111111
    2 ymotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000111100000000000000000 %0001000000111111111111
    3 ymotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000101000000000000000000 %0001000000111111111111
    4 ymotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000010100000000000000000 %0001000000111111111111
    5 ymotor quickreg!
    %100 %00000000001100000011 1 1000 0 0 %00011000000000001000000010010011 %1000000000000000000000000 %0001000000111111111111
    6 ymotor quickreg!
  then
  configured? ;

\ ************************ These following words are for normal speed movement only and as such are silent
: movetox { ux -- nflag } \ move to x position on table
  \ nflag is 200 if the move is executed
  \ nflag is 201 if ny is not on sandtable
  \ nflag is 202 if table not configured or homed
  configured? false = homedone? true = xposition true <> and and
  if \ only do steps if all configured and home is know
    xm-max ux >= xm-min ux <= and
    if
      xmotor enable-motor
      0 xmotor usequickreg
      xposition ux >
      if
        backward xmotor setdirection
        silentspeed xposition ux - xmotor timedsteps
      else
        forward xmotor setdirection
        silentspeed ux xposition - xmotor timedsteps
      then
      ux to xposition
      xmotor disable-motor
      200
    else
      201
    then
  else
    202
  then ;

: movetoy { uy -- nflag } \ move to y position on table
  \ nflag is 200 if the move is executed
  \ nflag is 201 if ny is not on sandtable
  \ nflag is 202 if table not configured or homed
  configured? false = homedone? true = yposition true <> and and
  if \ only do steps if all configured and home is know
    ym-max uy >= ym-min uy <= and
    if
      ymotor enable-motor
      0 ymotor usequickreg
      yposition uy >
      if
        backward ymotor setdirection
        silentspeed yposition uy - ymotor timedsteps
      else
        forward ymotor setdirection
        silentspeed uy yposition - ymotor timedsteps
      then
      uy to yposition
      ymotor disable-motor
      200
    else
      201
    then
  else
    202
  then ;

: movetoxy ( ux uy -- nflag ) \ move to the x and y location at the same time ...
  \ nflag is 200 if the move is executed
  \ nflag is 201 if ux uy are not on sandtable
  \ nflag is 202 if sandtable is not configured or homed yet
  0e 0e { ux uy F: mslope F: bintercept }
  ux xposition = if uy movetoy exit then
  uy yposition = if ux movetox exit then
  configured? false = homedone? true = yposition true <> xposition true <> and and and
  if \ only do steps if all configured and home is know
    ym-max uy >= ym-min uy <= and xm-max ux >= xm-min ux <= and and
    if
      ymotor enable-motor xmotor enable-motor
      0 ymotor usequickreg 0 xmotor usequickreg
      xposition ux > if 0 else 1 then xmotor setdirection
      yposition uy > if 0 else 1 then ymotor setdirection
      yposition uy - s>f
      xposition ux - s>f
      f/ to mslope
      yposition s>f mslope xposition s>f f* f- to bintercept
      ux xposition >
      if
        ux 1 + xposition do
          silentspeed
          steps xmotor timedsteps i to xposition
          mslope i s>f f* bintercept f+ f>s dup dup yposition <>
          if
            yposition - abs silentspeed
            swap ymotor timedsteps to yposition
          else
            drop drop
          then
        steps +loop
      else
        ux 1 - xposition -do
          silentspeed
          steps xmotor timedsteps i to xposition
          mslope i s>f f* bintercept f+ f>s dup dup yposition <>
          if
            yposition - abs silentspeed
            swap ymotor timedsteps to yposition
          else
            drop drop
          then
        steps -loop
      then
      ymotor disable-motor xmotor disable-motor
      \ rounding error cleanup final draw
      xposition ux <> if ux movetox dup 200 <> if exit else drop then then
      yposition uy <> if uy movetoy dup 200 <> if exit else drop then then
      200 \ move done
    else 201 \ not in bounds
    then
  else 202 \ not configured or home yet
  then ;

\ *********** these next words are used to process and make a word that allows printing on the sandtable as a window
\ these valuese are used to do internal sandtable location calculations in the following words only
: boardermove  ( nx ny -- nflag )
  0 { nx ny nflag } \ simply move the ball to each closest edge one dirction at a time
  nx xm-min < if xm-min movetox to nflag then
  nx xm-max > if xm-max movetox to nflag then
  ny ym-min < if ym-min movetoy to nflag then
  ny ym-max > if ym-max movetoy to nflag then nflag ;

: distance? { nx1 ny1 nx2 ny2 -- ndistance } \ return calculated distance between two dots
  nx2 nx1 - s>f 2e f**
  ny2 ny1 - s>f 2e f**
  f+ fsqrt f>s ;
0 value nsx1 \ used by drawline for real sandtable corrodinates
0 value nsy1
0 value nsx2
0 value nsy2
0 value nbx1 \ used by drawline for real boarder corrodinates on sandtable
0 value nby1
0 value nbx2
0 value nby2
0 value pointtest
0 value boardertest
0e fvariable mslope mslope f!
0e fvariable bintersect bintersect f!
: drawline ( nx1 ny1 nx2 ny2 -- nflag ) \ draw the line on the sandtable and move drawing stylus around the boarder if needed because line is behond table
\ nx1 ny1 is start of line ... nx2 ny2 is end of line drawn
\ nflag returns information about what happened in drawing the requested line
\ nflag is 200 if line was drawn with no issues
\ nflag is 202 if sandtable not configured yet home not found yet
  { nx1 ny1 nx2 ny2 }
  0 to pointtest
  0 to boardertest
  nx1 nx2 = ny1 ny2 = and nx1 xm-min >= nx1 xm-max <= and and ny1 ym-min >= ny1 ym-max <= and and if nx1 ny1 movetoxy exit then
  nx1 nx2 = ny1 ny2 = and nx1 xm-min < nx1 xm-max > or and if nx1 ny1 boardermove exit then
  nx1 nx2 = ny1 ny2 = and ny1 ym-min < ny1 ym-max > or and if nx1 ny1 boardermove exit then
  nx1 nx2 = nx1 xm-min < nx1 xm-max > or and if nx2 ny2 boardermove exit then \ vertical line not on sandtable
  ny1 ny2 = ny1 ym-min < ny1 ym-max > or and if nx2 ny2 boardermove exit then \ horizontal line not on sandtable

  nx1 nx2 = if
  \ vertical line
    nx1 to nsx1
    nx1 to nsx2
    ny1 ym-min >= ny1 ym-max <= and ny2 ym-min >= ny2 ym-max <= and and if
      \ y is on sandtable
      ny1 to nsy1 ny2 to nsy2
    else
      \ y is not on sandtable
      ny1 ym-min >= ny1 ym-max <= and if
        ny1 to nsy1
      else
        ny1 ym-min < if ym-min to nsy1 else ym-max to nsy1 then
      then
      ny2 ym-min >= ny2 ym-max <= and if
        ny2 to nsy2
      else
        ny2 ym-min < if ym-min to nsy2 else ym-max to nsy2 then
      then
    then
    2 to pointtest
  then

  ny1 ny2 = if
  \ horizontal line
    ny1 to nsy1
    ny1 to nsy2
    nx1 xm-min >= nx1 xm-max <= and nx2 xm-min >= nx2 xm-max <= and and if
      \ x is on sandtable
      nx1 to nsx1 nx2 to nsx2
    else
      \ x is not on sandtable
      nx1 xm-min >= nx1 xm-max <= and if
        nx1 to nsx1
      else
        nx1 xm-min < if xm-min to nsx1 else xm-max to nsx1 then
      then
      nx2 xm-min >= nx2 xm-max <= and if
        nx2 to nsx2
      else
        nx2 xm-min < if xm-min to nsx2 else xm-max to nsx2 then
      then
    then
    2 to pointtest
  then

  ny2 ny1 - s>f nx2 nx1 - s>f f/ mslope f!
  ny1 s>f nx1 s>f mslope f@ f* f- bintersect f!

  nx1 nx2 = ny1 ny2 = or invert \ test horizontal or vertical
  nx1 xm-min >= nx1 xm-max <= and \ test if in bounds or out of bounds
  ny1 ym-min >= ny1 ym-max <= and and and
  if \ nx1 ny1 are on real sandtable
    nx1 to nsx1
    ny1 to nsy1
    1 to pointtest
  then

  nx1 nx2 = ny1 ny2 = or invert \ test no horizontal or vertical
  nx2 xm-min >= nx2 xm-max <= and \ test if in bounds or out of bounds
  ny2 ym-min >= ny2 ym-max <= and and and
  if \ nx2 ny2 are on real sandtable
    pointtest 0 = if nx2 to nsx1 ny2 to nsy1 else nx2 to nsx2 ny2 to nsy2 then
    pointtest 1 + to pointtest
  then

  pointtest 2 <> if
    \ x=0 then bintersect is y
    bintersect f@ ym-min s>f f>= bintersect f@ ym-max s>f f<= and if 0 to nbx1 bintersect f@ f>s to nby1 1 to boardertest else 0 to boardertest then
    \ y=mx+b
    mslope f@ xm-max s>f f* bintersect f@ f+ fdup fdup
    ym-min s>f f>= ym-max s>f f<= and if boardertest 0 = if xm-max to nbx1 f>s to nby1 else xm-max to nbx2 f>s to nby2 then boardertest 1 + to boardertest else fdrop then
    \ y-b=mx ... x = (y/m)-(b/m)
    ym-min s>f mslope f@ f/ bintersect f@ mslope f@ f/ f- fdup fdup
    xm-min s>f f>= xm-max s>f f<= and boardertest 2 < and if boardertest 0 = if f>s to nbx1 ym-min to nby1 else f>s to nbx2 ym-min to nby2 then boardertest 1 + to boardertest else fdrop then
    ym-max s>f mslope f@ f/ bintersect f@ mslope f@ f/ f- fdup fdup
    xm-min s>f f>= xm-max s>f f<= and boardertest 2 < and if boardertest 0 = if f>s to nbx1 ym-max to nby1 else f>s to nbx2 ym-max to nby2 then boardertest 1 + to boardertest else fdrop then

    boardertest 0 = pointtest 0 = and if nx2 ny2 boardermove exit then \ line is not on sandtable
    nx1 xm-min < nx2 xm-min < and
    ny1 ym-min < ny2 ym-min < and or
    nx1 xm-max > nx2 xm-max > and
    ny1 ym-max > ny2 ym-max > and or or if nx2 ny2 boardermove exit then \ line intersects with sandtable but is not on the sandtable

    pointtest 0 = if \ then both boarders found are simply used
      nx1 ny1 boardermove drop \ this is prefered rather then diagnal movement to first boarder
      nbx1 to nsx1
      nby1 to nsy1
      nbx2 to nsx2
      nby2 to nsy2
      2 to pointtest
    else \ pointtest must be 1 so the correct boarder to use needs to be determined
      nx1 nsx1 = nx2 nx1 > and if nbx1 nx1 > if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then
      nx1 nsx1 = nx2 nx1 < and if nbx1 nx1 < if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then

      nx2 nsx1 = nx1 nx2 > and if nbx1 nx2 > if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then
      nx2 nsx1 = nx1 nx2 < and if nbx1 nx2 < if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then
      2 to pointtest
    then
  then
  nx1 ny1 nsx1 nsy1 distance?
  nx1 ny1 nsx2 nsy2 distance? > if
    nsx1 nsy1 nsx2 nsy2
    to nsy1 to nsx1
    to nsy2 to nsx2
  then
  nsx1 xposition = nsy1 yposition = and if
    \ draw to nsx2 nsy2
    nsx2 nsy2 movetoxy
  else
    nsx1 nsy1 movetoxy drop
    nsx2 nsy2 movetoxy
  then ;
\ ************************   these following words are for home position use only not for normal movement use above words for that
\ also note that these home position words do not check if sandtable is configured so only use the dohome word to calibrate the sandtable

: xyget-sg_result ( uxym -- usgr )  \ get result of stall guard readings
  case
  xm of
    DRV_STATUS xmotor getreg abort" xmotor DRV_STATUS failed" swap drop
  endof
  ym of
    DRV_STATUS ymotor getreg abort" ymotor DRV_STATUS failed" swap drop
  endof
  endcase
  %1111111111 and ;

: xyget-MSCURACT ( uxym -- nCUR_A nCUR_B ) \ uxym is a motor ym or xm.  this will return the microstep for motor for each phase
  case
  xm of
    MSCURACT xmotor getreg abort" xmotor MSCURACT failed" swap drop
  endof
  ym of
    MSCURACT xmotor getreg abort" ymotor MSCURACT failed" swap drop
  endof
  endcase
  dup %111111111 and swap
  %1111111110000000000000000 and 16 rshift
;
: xyget-LOST_STEPS ( uxym -- ulost ) \ uxym is a motor ym or xm.  ulost is the value returned indicating lost steps
  case
  xm of
    LOST_STEPS xmotor getreg abort" xmotor LOST_STEPS failed" swap drop
  endof
  ym of
    LOST_STEPS ymotor getreg abort" ymotor LOST_STEPS failed" swap drop
  endof
  endcase ;
: xyget-MSCNT ( uxym -- uMSCNT )  \ uxym is motor ym or xm... MSCNT is the register in tmc2130 that says the actual phase of motor
  case
  xm of
    MSCNT xmotor getreg abort" xmotor MSCNT read failed" swap drop
  endof
  ym of
    MSCNT ymotor getreg abort" ymotor MSCNT read failed" swap drop
  endof
  endcase ;

: xysteps { uquickreg udirection ucalspeed ucalsteps uxy -- uresult } \ simply step motor based on this info then return stall guard result
  configured? false = if
    uxy case
      xm of
        uquickreg xmotor usequickreg
        udirection xmotor setdirection
        ucalspeed ucalsteps xmotor timedsteps
        xm xyget-sg_result
      endof
      ym of
        uquickreg ymotor usequickreg
        udirection ymotor setdirection
        ucalspeed ucalsteps ymotor timedsteps
        ym xyget-sg_result
      endof
    endcase
  else 0 then ;

: ndosteps { uquickreg udirection ucalspeed ucalsteps uloop uxy -- umean usd }  \ used for testing ... umean and usd are returned after uloop of ucalsteps are done
  configured? false = if
    uxy case xm of xmotor enable-motor endof ym of ymotor enable-motor endof endcase
    uxy case xm of xdata endof ym of ydata endof endcase
    [bind] realtimeMSD construct
    uloop 0 do
      uquickreg udirection ucalspeed ucalsteps uxy xysteps
      uxy case xm of xdata endof ym of ydata endof endcase n>data
    loop
    uxy case xm of xmotor disable-motor endof ym of ymotor disable-motor endof endcase
    uxy case xm of xdata endof ym of ydata endof endcase
    dup nmean@ swap nsdp@
  else 0 0
  then
;


: nstep-list { uquickreg udirection ucalspeed ucalsteps uloop uxy -- uxydll }  \ used for testing .. uxydll is double linked list containing stall guard data
  configured? false = if
    uxy case xm of xmotor enable-motor endof ym of ymotor enable-motor endof endcase
    uxy case xm of x-array-data endof ym of y-array-data endof endcase
    [bind] double-linked-list construct
    uloop 0 do
      uquickreg udirection ucalspeed ucalsteps uxy xysteps
      uxy case xm of x-array-data endof ym of y-array-data endof endcase ll-cell!
    loop
    uxy case xm of xmotor disable-motor endof ym of ymotor disable-motor endof endcase
    uxy case xm of x-array-data endof ym of y-array-data endof endcase
  else 0
  then ;

: listmotordata { udatalist -- }  \ use for testing..  displays data in double linked list to console
  udatalist ll-set-start
  begin udatalist ll-cell@ . udatalist ll> until ;

: xedgedetect ( usd umean utestsd utestmean -- nflag ) \ looks for edge conditions ... nflag is true if edge found or false if not found
  { usd umean utestsd utestmean }
  utestmean usd s>f xcal-threshold-a f@ f* f>s umean + >
  umean usd s>f xcal-threshold-a f@ f* f>s - 0 < if utestmean 0 = else utestmean umean usd s>f xcal-threshold-a f@ f* f>s - < then or
  utestsd usd s>f xcal-threshold-b f@ f* f>s > or ;
: yedgedetect ( usd umean utestsd utestmean -- nflag ) \ looks for edge conditions ... nflag is true if edge found or false if not found
  { usd umean utestsd utestmean }
  utestmean usd s>f ycal-threshold-a f@ f* f>s umean + >
  umean usd s>f ycal-threshold-a f@ f* f>s - 0 < if utestmean 0 = else utestmean umean usd s>f ycal-threshold-a f@ f* f>s - < then or
  utestsd usd s>f ycal-threshold-b f@ f* f>s > or ;

: doxycalibrate ( uxy -- nflag ) \ uxy is ym or xm ... nflag is false for calibration failed and true for calibration passed
  0 0 0 { uxy umean usd maxloops }
  configured? false = if
    uxy case
      xm of
        begin
          xcalreg forward xcalspeed xcalsteps calstep-amounts 2 * xm ndosteps 2drop
          calwait ms
          xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps 2drop
          calwait ms
          xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps to usd to umean
          usd . ." x usd " umean . ." x umean  #1" cr
          calwait ms
          usd umean xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps swap
          .s ." x usd umean testsd testmean " maxloops . ." maxloops" cr
          xedgedetect if
            calwait ms
            xcalreg forward xcalspeed xcalsteps calstep-amounts 2 * xm ndosteps 2drop
            calwait ms
            xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps 2drop
            calwait ms
            xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps to usd to umean
            usd . ." x usd " umean . ." x umean  #2" cr
            calwait ms
            usd umean xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps swap
            .s ." x usd umean testsd testmean " cr
            xedgedetect if
              calwait ms
              xcalreg forward xcalspeed xcalsteps calstep-amounts 2 * xm ndosteps 2drop
              calwait ms
              xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps 2drop
              calwait ms
              xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps to usd to umean
              usd . ." x usd " umean . ." x umean  #3" cr
              calwait ms
              usd umean xcalreg backward xcalspeed xcalsteps calstep-amounts xm ndosteps swap
              .s ." x usd umean testsd testmean final" cr
              xedgedetect
            else
              false
            then          else
            false
          then
          maxloops 1 + dup to maxloops max-cal-test >= or
        until
        maxloops max-cal-test >= if 10 throw else true then \ edge not detected for x axis calibration failed!
      endof
      ym of
        begin
          ycalreg forward ycalspeed ycalsteps calstep-amounts 2 * ym ndosteps 2drop
          calwait ms
          ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps 2drop
          calwait ms
          ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps to usd to umean
          usd . ." y usd " umean . ." y umean #1" cr
          calwait ms
          usd umean ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps swap
          .s ." y usd umean testsd testmean " maxloops . ." maxloops" cr
          yedgedetect if
            calwait ms
            ycalreg forward ycalspeed ycalsteps calstep-amounts 2 * ym ndosteps 2drop
            calwait ms
            ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps 2drop
            calwait ms
            ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps to usd to umean
            usd . ." y usd " umean . ." y umean #2" cr
            calwait ms
            usd umean ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps swap
            .s ." y usd umean testsd testmean " cr
            yedgedetect if
              calwait ms
              ycalreg forward ycalspeed ycalsteps calstep-amounts 2 * ym ndosteps 2drop
              calwait ms
              ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps 2drop
              calwait ms
              ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps to usd to umean
              usd . ." y usd " umean . ." y umean #3" cr
              calwait ms
              usd umean ycalreg backward ycalspeed ycalsteps calstep-amounts ym ndosteps swap
              .s ." y usd umean testsd testmean final" cr
              yedgedetect
            else
              false
            then
          else
            false
          then
          maxloops 1 + dup to maxloops max-cal-test >= or
        until
        maxloops max-cal-test >= if 11 throw else true then \ edge not detected for y axis calibration failed!
      endof
    endcase
  else false then ;

\ ********** this is the only word to calibrate the sandtable that should be used.  ************
: dohome ( -- nflag ) \ find x and y home position ... nflag is true if calibration is done.   nflag is false for or other value for a calibration failure
  try
    configured? false = if
      xm doxycalibrate if
        xmotor enable-motor
        0 forward silentspeed stopbuffer xm xysteps drop \ moves a small distance from home stop position
        xmotor disable-motor
        xm-min to xposition
        true
      else false
      then
      ym doxycalibrate if
        ymotor enable-motor
        0 forward silentspeed stopbuffer ym xysteps drop \ moves a small distance from home stop position
        ymotor disable-motor
        ym-min to  yposition
        true
      else false
      then
      and
    else
        false
    then
  restore dup true = if true to homedone? else false to homedone? true to xposition true to yposition then
  endtry ;

: closedown ( -- )
  true to configured?  \ true means not configured false means configured
  false to homedone?   \ false means table has not been homed true means table was homed succesfully
  true to xposition  \ is the real location of x motor .. note if value is true then home position not know so x is not know yet
  true to yposition  \ is the real location of y motor .. note if value is true then home position not know so y is not know yet
  xmotor disable-motor
  ymotor disable-motor
  xmotor [bind] tmc2130 destruct
  ymotor [bind] tmc2130 destruct ;

: border ( -- nflag )  \ draws a boarder around sandtable ... nflag is 200 if no drawing issues ... any other number is some sandtable error
\ if nflag is 200 then ball currently is at x 0 y 0
  try
    xposition xm-min = if ym-min movetoy dup 200 <> if throw else drop then then
    xposition xm-max = if ym-min movetoy dup 200 <> if throw else drop then then
    yposition ym-min = if xm-min movetox dup 200 <> if throw else drop then then
    yposition ym-max = if xm-min movetox dup 200 <> if throw else drop then then
    xm-min movetox dup 200 <> if throw else drop then
    ym-min movetoy dup 200 <> if throw else drop then
    xm-min ym-max movetoxy dup 200 <> if throw else drop then
    xm-max ym-max movetoxy dup 200 <> if throw else drop then
    xm-max ym-min movetoxy dup 200 <> if throw else drop then
    xm-min ym-min movetoxy dup 200 <> if throw else drop then
    200
  restore
  endtry ;

0 value nbasex1
0 value nbasey1
0 value nbasex2
0 value nbasey2
0 value nxj1
0 value nyj1
0 value nxj2
0 value nyj2
: order-line ( nx1 ny1 nx2 ny2 -- nx ny nx' ny' ) \ reorder input x y such that nx ny is closest to current xposition yposition
  { nx1 ny1 nx2 ny2 }
  xposition yposition nx1 ny1 distance?
  xposition yposition nx2 ny2 distance?
  < if
    nx1 ny1 nx2 ny2
  else
    nx2 ny2 nx1 ny1
  then ;

: offset-line ( nx1 ny1 nx2 ny2 nxoffset nyoffset -- nx ny nx' ny' ) \ add noffset to quardinates
  { nx1 ny1 nx2 ny2 nxoffset nyoffset }
  nx1 nxoffset +
  ny1 nyoffset +
  nx2 nxoffset +
  ny2 nyoffset + ;

: deg>rads ( uangle -- f: rrad ) \ unangle from stack gets converted to rads and place in floating stack
  s>f pi 180e f/ f* ;

: (calc-c) ( uangle uqnt -- utotal ustep ) \ used by lines to be the distance offset calulation
  { uangle uqnt }
  uangle 90 mod dup
  deg>rads fsin deg>rads fcos f+ xm-max s>f f*
  fdup uqnt s>f f/
  f>s f>s swap ;
: (calc-x) ( uc uangle -- nx ) \ used by lines to calculate x offset from uangle and c distance from calc-c
  deg>rads fsin s>f f* f>s ;
: (calc-y) ( uc uangle -- ny ) \ used by lines to calculate y offset from uangle and c distance from calc-c
  90 swap - deg>rads fsin s>f f* f>s ;

: lines ( nx ny uangle uqnt -- ) \ draw uqnt lines with one intersecting with nx ny with uangle from horizontal
  0 0 1500000 { nx ny uangle uqnt nb na usize }
  uangle 360 mod to uangle
  uangle 0 <> if
    uangle deg>rads   \ remember fsin uses rads not angles so convert
    fsin usize s>f f*
    90 deg>rads
    fsin f/ f>s to na
    90 uangle - deg>rads
    fsin na s>f f*
    uangle deg>rads
    fsin f/ f>s to nb
  else
    usize to nb
    0 to na
  then
  nx nb - ny na + \ - direction from nx ny
  to nbasey1 to nbasex1
  nx nb + ny na - \ + direction from nx ny
  to nbasey2 to nbasex2
  \ this is the line that intersects with nx ny point
  uangle uqnt (calc-c) to usize drop
  nbasex1 nbasey1 nbasex2 nbasey2
  uangle uqnt (calc-c) drop uangle (calc-x) 0 swap -
  uangle uqnt (calc-c) drop uangle (calc-y) 0 swap -
  offset-line \ calculate start line with offset from base line
  to nyj2 to nxj2 to nyj1 to nxj1
  uqnt 2 * 0 ?do
    i usize * uangle (calc-x) to na
    i usize * uangle (calc-y) to nb
    nxj1 nyj1 nxj2 nyj2 na nb offset-line
    .s drawline . cr
    nxj2 nyj2 nxj1 nyj1 na nb offset-line
    usize uangle (calc-x)
    usize uangle (calc-y)
    offset-line \ add offset for second line
    .s drawline . cr
  2 +loop
  \ border ." boarder " . cr
  nbasex1 nbasey1 nbasex2 nbasey2 order-line
  .s drawline . cr
  nx ny movetoxy . cr  ;

: zigzag-line ( nsteps uxy -- nflag ) \ nflag is false if all ok other numbers are errors
  0 { nsteps uxy nxyamount }
  try
    uxy case
      xm of
        xm-max xm-min - nsteps / to nxyamount
        xm-min ym-min movetoxy 200 <> if 300 throw then
        nxyamount nsteps * xm-min do
          i nxyamount 2 / + ym-max movetoxy 200 <> if 301 throw then
          i nxyamount + ym-min movetoxy 200 <> if 302 throw then
        nxyamount +loop
        border 200 <> if 303 throw then
        false
      endof
      ym of
        ym-max ym-min - nsteps / to nxyamount
        xm-min ym-min movetoxy 200 <> if 300 throw then
        nxyamount nsteps * ym-min do
          i nxyamount 2 / + xm-max swap movetoxy 200 <> if 301 throw then
          i nxyamount + xm-min swap movetoxy 200 <> if 302 throw then
        nxyamount +loop
        border 200 <> if 303 throw then
        false
      endof
    endcase
  restore
  endtry ;
\ ******************* these words are for testing
: quickstart ( ux uy -- nflag ) \ start up sandtable assuming the physical table is at ux and uy location
  to yposition
  to xposition
  true to homedone?
  configure-stuff ;

: testdata nsx1 . nsy1 . nsx2 . nsy2 . pointtest . boardertest . xposition . yposition . cr ;
