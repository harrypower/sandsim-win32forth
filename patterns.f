\ patterns.fs

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

\ patterns for drawing on sandtable

\ Requires:
\ sandmotorapi.fs
\ random.fs

\ Revisions:
\ 04/06/2019 started coding

\ require random.fs
\ require sandmotorapi.fs
needs sandmotorapi.f

: rndstar ( uamount -- ) \ will start at a random board location and draw random length lines from that start point radiating out
  xm-max random ym-max random 0 0 { nx ny nx1 ny1 }
  0 ?do
    xm-max random to nx1
    ym-max random to ny1
    nx ny nx1 ny1 drawline .
    nx1 ny1 nx ny drawline .
  loop ;

: rndstar2 ( uamount nx ny -- )
  0 0 { uamount nx ny nx1 ny1 }
  uamount 0 ?do
    xm-max random to nx1
    ym-max random to ny1
    nx ny nx1 ny1 drawline .
    nx1 ny1 nx ny drawline .
  loop ;

: rdeg>rrad ( rangle -- f: rrad ) \ rangle from fstack gets converted to rads and place back in floating stack
  fpi 180e f/ f* ;

: linestar ( nx ny nangle usize uquant -- ) \ move to nx ny and draw nquant lines of nsize from nx ny location with rotation of nangle
  0 { nx ny nangle usize uquant uintangle }
  xposition yposition nx ny drawline .
  360e uquant s>f f/ f>s to uintangle
  uquant 0 ?do
    nx ny
    uintangle s>f i s>f f* nangle s>f f+ rdeg>rrad fcos usize s>f f* f>s nx +
    uintangle s>f i s>f f* nangle s>f f+ rdeg>rrad fsin usize s>f f* f>s ny +
    .s drawline . cr
    xposition yposition nx ny drawline .
  loop ;

0e fvalue rcx
0e fvalue rcy
: circle ( nx ny nangle nsize ) \ nx ny is circle center nangle is start of drawing on circle nsize is radius of circle
  \ will draw lines between points on circle every 5 degrees
  { nx ny nangle nsize }
  nangle s>f rdeg>rrad fcos nsize s>f f* nx s>f f+ to rcx
  nangle s>f rdeg>rrad fsin nsize s>f f* ny s>f f+ to rcy
  rcx f>s rcy f>s movetoxy .
  365 0 do
    rcx f>s rcy f>s
    nangle i + s>f rdeg>rrad fcos nsize s>f f* nx s>f f+ to rcx
    nangle i + s>f rdeg>rrad fsin nsize s>f f* ny s>f f+ to rcy
    rcx f>s rcy f>s drawline .
  5 +loop ;

: circle2 ( nx ny nangle nsize ) \ nx ny start point on circle nangle is angle pointing at center of circle nsize is the radius of circle
  { nx ny nangle nsize }
  nangle s>f rdeg>rrad fcos nsize s>f f* nx s>f f+ to rcx
  nangle s>f rdeg>rrad fsin nsize s>f f* ny s>f f+ to rcy
  nangle 180 + to nangle
  nx ny movetoxy .
  365 0 do
    nx ny
    nangle i + s>f rdeg>rrad fcos nsize s>f f* rcx f+ f>s to nx
    nangle i + s>f rdeg>rrad fsin nsize s>f f* rcy f+ f>s to ny
    nx ny drawline .
  5 +loop ;
