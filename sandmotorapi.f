\ sandmotorapi.f

\    Copyright (C) 2019  Philip King Smith
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

\ originaly from my sandtable git and was called sandmotorapi.fs
\ I have modified this file to work with win32forth and the sandtable simulator for windows
\ I have removed all motor controler stuff and removed or changed words not in win32forth

\ Requires:
\ needs sand-win-gdi.f
\ Revisions:
\ 5/28/2019 started coding
\ 5/30/2019 changed steps to 1 for simulator
\ movetoxy movetox movetoy working for simulator
\ drawline working now

needs sand-win-gdi.f

in-system
\ this -do and -loop are needed only once in following code and here because win32forth does not have them
: -LOOP ( compilation -do-sys -- ; run-time loop-sys1 +n -- | loop-sys2 )
     POSTPONE negate POSTPONE +loop
     POSTPONE else POSTPONE 2drop POSTPONE then ; immediate

: -DO ( compilation -- -do-sys ; run-time n1 n2 -- | loop-sys )
     POSTPONE 2dup POSTPONE < POSTPONE if
     POSTPONE swap POSTPONE 1+ POSTPONE swap POSTPONE do ; immediate
in-application

0 value xmotor
0 value ymotor
true value configured?  \ true means not configured false means configured
false value homedone?   \ false means table has not been homed true means table was homed succesfully
0 constant xm
1 constant ym
3000 value stopbuffer
0 constant xm-min
0 constant ym-min
600 constant xm-max \ note this is windows drawing size x
600 constant ym-max \ note this is windows drawing size y
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
1 value steps \ 1 for windows simulator 10 for real sandtable
1 value xcalreg
1 value ycalreg
200 value calwait
32 value max-cal-test

\ ************ configure-stuff needs to be used first and return false to allow other operations with sandtable
: configure-stuff ( -- nflag ) \ nflag is false if configuration happened other value if some problems
  false to configured?
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
      ux to xposition
      xposition yposition nxy!: line-list
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
      uy to yposition
      xposition yposition nxy!: line-list
      200
    else
      201
    then
  else
    202
  then ;

\ ***** add code to place data for display to windows in this movetoxy ********
0e fvalue mslope
0e fvalue bintercept
: movetoxy ( ux uy -- nflag ) \ move to the x and y location at the same time ...
  \ nflag is 200 if the move is executed
  \ nflag is 201 if ux uy are not on sandtable
  \ nflag is 202 if sandtable is not configured or homed yet
  { ux uy }
  0e to mslope
  0e to bintercept
  ux xposition = if uy movetoy exit then
  uy yposition = if ux movetox exit then
  configured? false = homedone? true = yposition true <> xposition true <> and and and
  if \ only do steps if all configured and home is know
    ym-max uy >= ym-min uy <= and xm-max ux >= xm-min ux <= and and
    if
      yposition uy - s>f
      xposition ux - s>f
      f/ to mslope
      yposition s>f mslope xposition s>f f* f- to bintercept
      ux xposition >
      if
        ux 1 + xposition do
          i yposition nxy!: line-list i to xposition
          mslope i s>f f* bintercept f+ f>s dup dup yposition <>
          if
            xposition swap nxy!: line-list to yposition
          else
            drop drop
          then
        steps +loop
      else
        ux 1 - xposition -do
          i yposition nxy!: line-list i to xposition
          mslope i s>f f* bintercept f+ f>s dup dup yposition <>
          if
            xposition swap nxy!: line-list to yposition
          else
            drop drop
          then
        steps -loop
      then
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
  0 { nx ny nflag } \ simply move the ball to each closest edge one direction at a time
  xposition xm-min <> xposition xm-max <> and
  yposition ym-min <> yposition ym-max <> and or if
    xposition xm-min -
    xm-max xposition - min
    yposition ym-min -
    ym-max yposition - min > if \ y first then x
      yposition xm-min - ym-max yposition - > if
        ym-max movetoy to nflag
      else
        ym-min movetoy to nflag
      then
      xposition xm-min - xm-max xposition - > if
        xm-max movetox to nflag
      else
        xm-min movetox to nflag
      then
    else \ x first then y
      xposition xm-min - xm-max xposition - > if
        xm-max movetox to nflag
      else
        xm-min movetox to nflag
      then
      yposition xm-min - ym-max yposition - > if
        ym-max movetoy to nflag
      else
        ym-min movetoy to nflag
      then
    then
  then
  xm-min nx abs - abs
  xm-max nx abs - abs min
  ym-min ny abs - abs
  ym-max ny abs - abs min < if
    nx xm-min < if xm-min movetox to nflag then
    nx xm-max > if xm-max movetox to nflag then
    ny ym-min < if ym-min movetoy to nflag then
    ny ym-max > if ym-max movetoy to nflag then
  else
    ny ym-min < if ym-min movetoy to nflag then
    ny ym-max > if ym-max movetoy to nflag then
    nx xm-min < if xm-min movetox to nflag then
    nx xm-max > if xm-max movetox to nflag then
  then nflag  ;

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
0e fvalue mslope1
0e fvalue bintercept1
: drawline ( nx1 ny1 nx2 ny2 -- nflag ) \ draw the line on the sandtable and move drawing stylus around the boarder if needed because line is behond table
\ nx1 ny1 is start of line ... nx2 ny2 is end of line drawn
\ nflag returns information about what happened in drawing the requested line
\ nflag is 200 if line was drawn with no issues
\ nflag is 202 if sandtable not configured yet home not found yet
  { nx1 ny1 nx2 ny2 }
  0 to pointtest
  0 to boardertest
  0e to mslope1
  0e to bintercept1
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

  ny2 ny1 - s>f nx2 nx1 - s>f f/ to mslope1
  ny1 s>f nx1 s>f mslope1 f* f- to bintercept1

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
    \ x=0 then bintercept1 is y
    bintercept1 ym-min s>f f>= bintercept1 ym-max s>f f<= and if 0 to nbx1 bintercept1 f>s to nby1 1 to boardertest else 0 to boardertest then
    \ y=mx+b
    mslope1 xm-max s>f f* bintercept1 f+ fdup fdup
    ym-min s>f f>= ym-max s>f f<= and if boardertest 0 = if xm-max to nbx1 f>s to nby1 else xm-max to nbx2 f>s to nby2 then boardertest 1 + to boardertest else fdrop then
    \ y-b=mx ... x = (y/m)-(b/m)
    ym-min s>f mslope1 f/ bintercept1 mslope1 f/ f- fdup fdup
    xm-min s>f f>= xm-max s>f f<= and boardertest 2 < and if boardertest 0 = if f>s to nbx1 ym-min to nby1 else f>s to nbx2 ym-min to nby2 then boardertest 1 + to boardertest else fdrop then
    ym-max s>f mslope1 f/ bintercept1 mslope1 f/ f- fdup fdup
    xm-min s>f f>= xm-max s>f f<= and boardertest 2 < and if boardertest 0 = if f>s to nbx1 ym-max to nby1 else f>s to nbx2 ym-max to nby2 then boardertest 1 + to boardertest else fdrop then

    boardertest 0 = pointtest 0 = and if nx2 ny2 boardermove exit then \ line is not on sandtable
    nx1 xm-min < nx2 xm-min < and
    ny1 ym-min < ny2 ym-min < and or
    nx1 xm-max > nx2 xm-max > and
    ny1 ym-max > ny2 ym-max > and or or if nx2 ny2 boardermove exit then \ line intersects with sandtable edge but exceeds sandtable

    pointtest 0 = if \ then both boarders found are simply used
      nx1 ny1 boardermove drop \ this is prefered rather then diagnal movement to first boarder
      nbx1 to nsx1
      nby1 to nsy1
      nbx2 to nsx2
      nby2 to nsy2
      2 to pointtest
    else \ pointtest must be 1 so the correct boarder to use needs to be determined
      nx1 nsx1 = nx2 nx1 > and if nbx1 nx1 >= if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then
      nx1 nsx1 = nx2 nx1 < and if nbx1 nx1 <= if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then

      nx2 nsx1 = nx1 nx2 > and if nbx1 nx2 >= if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then
      nx2 nsx1 = nx1 nx2 < and if nbx1 nx2 <= if nbx1 to nsx2 nby1 to nsy2 else nbx2 to nsx2 nby2 to nsy2 then then
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

\ ********** this is the only word to calibrate the sandtable that should be used.  ************
: dohome ( -- nflag ) \ find x and y home position ... nflag is true if calibration is done.   nflag is false for or other value for a calibration failure
  xm-min to xposition
  ym-min to yposition
  0 0 nxy!: line-list
  true to homedone?
  homedone? ;

: closedown ( -- )
  true to configured?  \ true means not configured false means configured
  false to homedone?   \ false means table has not been homed true means table was homed succesfully
  true to xposition  \ is the real location of x motor .. note if value is true then home position not know so x is not know yet
  true to yposition  \ is the real location of y motor .. note if value is true then home position not know so y is not know yet
  ;

: border ( -- nflag )  \ draws a boarder around sandtable ... nflag is 200 if no drawing issues ... any other number is some sandtable error
\ if nflag is 200 then ball currently is at x 0 y 0
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
    200 ;

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
  s>f fpi 180e f/ f* ;

: coordinates? ( nx1 ny1 ndistance uangle -- nx2 ny2 ) \ given nx1 ny1 ndistance and uangle return the nx2 and ny2 corrodiantes
  0 0 { nx1 ny1 ndistance uangle na nb }
  ndistance s>f 360 uangle - deg>rads fcos  f* f>s to na
  ndistance s>f 360 uangle - deg>rads fsin  f* f>s to nb
  nx1 na + ny1 nb + ;

: (calc-na) ( uc uangle -- nx ) \ find na
  { uc uangle } uangle 90 >= if
    180 90 90 180 uangle - - + - deg>rads fsin
  else
    uangle deg>rads fsin
  then
  uc s>f f* f>s ;

: (calc-nb) ( uc uangle -- ny ) \ find nb
  { uc uangle } uangle 90 >= if
    90 180 uangle - - deg>rads fsin
  else
    90 uangle - deg>rads fsin
  then
  uc s>f f* f>s ;

0e fvalue fslope
0e fvalue fXn
0e fvalue ftablemax
0e fvalue fdpl ( dots per line to calculate distance to next line )
0e fvalue fltomin ( lines to min this is how many lines to draw from base line to the edge of the sandtable in the minimum direction )
0e fvalue fYintercept
: lines ( nx ny uangle uqnt -- ) \ draw uqnt lines with one intersecting with nx ny with uangle from horizontal
  0 0 1500000 { nx ny uangle uqnt nb na usize }
  \ uqnt 1 + to uqnt
  uangle 360 mod 180 >= if
    uangle 360 mod 180 - to uangle
  else
    uangle 360 mod to uangle
  then
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
  uangle 90 =  uangle 0 = or if \ this is for angles 0,90,180 or 270 only
    uangle 0 = if
      \ need to solve fdpl and nxj1,nxj2,nyj1,nyj2 amounts for 0 or 180 degrees horizontal line
      ym-max s>f uqnt s>f f/ to fdpl
      ny s>f fdpl f/ to fltomin
      fltomin f>s fdpl f>s * to nb
      0 to na
      nbasex1 nbasey1 nbasex2 nbasey2 na 0 swap - nb 0 swap - offset-line order-line
      to nyj2 to nxj2 to nyj1 to nxj1
      uqnt 0 ?do
          0 to na
          i fdpl f>s * to nb
          nxj1 nyj1 nxj2 nyj2 na nb offset-line order-line .s drawline . cr
      loop
    then
    uangle 90 = if
      \ need to solve fdpl and nxj1,nxj2,nyj1,nyj2 amounts for 90 or 270 degrees vertical line
      xm-max s>f uqnt s>f f/ to fdpl
      nx s>f fdpl f/ to fltomin
      0 to nb
      fltomin f>s fdpl f>s * to na
      nbasex1 nbasey1 nbasex2 nbasey2 na 0 swap - nb 0 swap - offset-line order-line
      to nyj2 to nxj2 to nyj1 to nxj1
      uqnt 0 ?do
          i fdpl f>s * to na
          0 to nb
          nxj1 nyj1 nxj2 nyj2 na nb offset-line order-line .s drawline . cr
      loop
    then
  else
    \ calculate slope from this base line
    nbasey1 nbasey2 - s>f
    nbasex1 nbasex2 - s>f
    f/ \ slope in floating stack ( f: fslope )
    fdup to fslope
    \ use B = Y - ( m * X ) to solve for this y intercept
    nx s>f f*
    ny s>f fswap f- to fYintercept \ y intercept in floating stack  ( f: fYintercept )
    uangle 90 < if
      fYintercept 90 uangle - deg>rads fsin f* to fXn
      \ solve y intercept for tablemax
      fslope xm-max s>f f*
      ym-max s>f fswap f-  \ ( f: fYintereceptmax )
      90 uangle - deg>rads fsin f*  fdup to ftablemax ( f: ftablemax )
      uqnt s>f f/ fdup to fdpl  ( f: fdpl )
      fXn fswap f/ fdup to fltomin    ( f: fltomin )
      f>s fdpl f>s * dup
      uangle (calc-na) to na
      uangle (calc-nb) to nb
      nbasex1 nbasey1 nbasex2 nbasey2 na 0 swap - nb 0 swap - offset-line order-line
      to nyj2 to nxj2 to nyj1 to nxj1
      uqnt 0 ?do
          i fdpl f>s * dup
          uangle (calc-na) to na
          uangle (calc-nb) to nb
          nxj1 nyj1 nxj2 nyj2 na nb offset-line order-line .s drawline . cr
      loop
    else \ this is for uangle > 90 < 180
      \ fslope known, fYintercept know
      \ solve for xn
      ym-max s>f fYintercept f-
      90 180 uangle - - deg>rads fsin f* to fXn
      nx ny xm-max ym-min distance? s>f fxn f+ fdup to ftablemax
      uqnt s>f f/ fdup to fdpl
      fXn fswap f/ fdup to fltomin
      f>s fdpl f>s * dup
      uangle (calc-na) to na
      uangle (calc-nb) to nb
      nbasex1 nbasey1 nbasex2 nbasey2 na 0 swap - nb  offset-line order-line
      to nyj2 to nxj2 to nyj1 to nxj1
      uqnt 0 ?do
          i fdpl f>s * dup
          uangle (calc-na) to na
          uangle (calc-nb) to nb
          nxj1 nyj1 nxj2 nyj2 na nb 0 swap - offset-line order-line .s drawline . cr
      loop
    then
  then
  \ redraw base line and place ball at nx ny location
  nbasex1 nbasey1 nbasex2 nbasey2 order-line .s drawline . cr
  nx ny movetoxy . cr  ;

: zigzag-line ( nsteps uxy -- nflag ) \ nflag is false if all ok other numbers are errors
  0 { nsteps uxy nxyamount }
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
    endcase ;
\ ******************* these words are for testing
: quickstart ( ux uy -- nflag ) \ start up sandtable assuming the physical table is at ux and uy location
  to yposition
  to xposition
  xposition yposition nxy!: line-list
  true to homedone?
  configure-stuff ;

: testdata nsx1 . nsy1 . nsx2 . nsy2 . pointtest . boardertest . xposition . yposition . cr ;
