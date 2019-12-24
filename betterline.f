\ betterline.f

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

\ a better line and lines method

\ Requires:
\ on Gforth
\ sandmotorapi.fs
\ random.fs
\ on win32forth
\ sandmotorapi.f

\ Revisions:
\ 12/01/2019 started coding
\ 12/07/2019 started new aligorition

: gforthtest ( -- nflag ) \ nflag is false if gforth is not running.  nflag is true if gforth is running
  c" gforth" find swap drop false = if false else true then ;
gforthtest true = [if]
  require random.fs
  require sandmotorapi.fs
[else]
  needs sandmotorapi.f
[then]

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

: (calc-x)2 ( uc uangle -- nx )
  { uc uangle } uangle 90 >= if
    180 uangle - deg>rads fsin uc s>f f* f>s
  else
    uangle deg>rads fsin uc s>f f* f>s
  then ;

: (calc-y)2 ( uc uangle -- ny )
  { uc uangle } uangle 90 >= if
    90 180 uangle - - deg>rads fsin uc s>f f* f>s
  else
    90 uangle - deg>rads fsin uc s>f f* f>s
  then ;

0e fvalue fslope
0e fvalue fXn
0e fvalue ftablemax
0e fvalue fdpl ( dots per line to calculate distance to next line )
0e fvalue fltomin ( lines to min this is how many lines to draw from base line to the edge of the sandtable in the minimum direction )

: lines2 ( nx ny uangle uqnt -- ) \ draw uqnt lines with one intersecting with nx ny with uangle from horizontal
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
  else \ this is for all angles other then 0 90 180 270
    \ calculate slope from this base line
    nbasey1 nbasey2 - s>f
    nbasex1 nbasex2 - s>f
    f/ \ slope in floating stack ( f: fslope )
    fdup to fslope
    \ use B = Y - ( m * X ) to solve for this y intercept
    nx s>f f*
    ny s>f fswap f- fabs \ y intercept in floating stack  ( f: fYintercept )
    uangle 90 > uangle 180 < and if
      90 180 uangle - -
    then
    uangle 0 > uangle 90 < and if
      180 90 uangle + -
    then
    deg>rads
    fsin f* \ xn is now on floating stack ( f: fXn )
    to fXn
    \ solve y intercept for tablemax
    fslope xm-max s>f f*
    ym-max s>f fswap f- fabs  \ ( f: fYintereceptmax )
    uangle 90 > uangle 180 < and if
      90 180 uangle - -
    then
    uangle 0 > uangle 90 < and if
      180 90 uangle + -
    then
    deg>rads
    fsin f* fdup to ftablemax ( f: ftablemax )
    uqnt s>f f/ fdup to fdpl  ( f: fdpl )
    fXn fswap f/ fdup to fltomin    ( f: fltomin )
    f>s fdpl f>s * dup
    uangle (calc-x)2 to na
    uangle (calc-y)2 to nb
    nbasex1 nbasey1 nbasex2 nbasey2 na 0 swap - nb 0 swap - offset-line order-line
    to nyj2 to nxj2 to nyj1 to nxj1
    uqnt 0 ?do
        i fdpl f>s * dup
        uangle (calc-x)2 to na
        uangle (calc-y)2 to nb
        nxj1 nyj1 nxj2 nyj2 na nb offset-line order-line .s drawline . cr
    loop
  then
  \ redraw base line and place ball at nx ny location
  nbasex1 nbasey1 nbasex2 nbasey2 order-line .s drawline . cr
  nx ny movetoxy . cr
  ;

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
