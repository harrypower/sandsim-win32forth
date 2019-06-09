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

: linestar ( nx ny nangle usize uquant -- ) \ move to nx ny and draw nquant lines of usize from nx ny location with rotation of nangle
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
: circle ( nx ny nangle usize ) \ nx ny is circle center nangle is start of drawing on circle usize is radius of circle
  \ will draw lines between points on circle every 5 degrees
  { nx ny nangle usize }
  nangle s>f rdeg>rrad fcos usize s>f f* nx s>f f+ to rcx
  nangle s>f rdeg>rrad fsin usize s>f f* ny s>f f+ to rcy
  rcx f>s rcy f>s movetoxy .
  365 0 do
    rcx f>s rcy f>s
    nangle i + s>f rdeg>rrad fcos usize s>f f* nx s>f f+ to rcx
    nangle i + s>f rdeg>rrad fsin usize s>f f* ny s>f f+ to rcy
    rcx f>s rcy f>s drawline .
  5 +loop ;

: circle2 ( nx ny nangle usize ) \ nx ny start point on circle nangle is angle pointing at center of circle usize is the radius of circle
  { nx ny nangle usize }
  nangle s>f rdeg>rrad fcos usize s>f f* nx s>f f+ to rcx
  nangle s>f rdeg>rrad fsin usize s>f f* ny s>f f+ to rcy
  nangle 180 + to nangle
  nx ny movetoxy .
  365 0 do
    nx ny
    nangle i + s>f rdeg>rrad fcos usize s>f f* rcx f+ f>s to nx
    nangle i + s>f rdeg>rrad fsin usize s>f f* rcy f+ f>s to ny
    nx ny drawline .
  5 +loop ;

: concentric-circles ( nx ny nangle usize ustep uqnt ) \ makes concentric cirles with nx ny as center, nangle as starting location
\ ustep is how many absolute location steps between circles with uqnt being how many circles to make
  { nx ny nangle usize ustep uqnt }
  uqnt 0 ?do
    nx ny nangle usize i ustep * + circle
  loop  ;

: circle-circles ( nx ny nangle usize uqnt usize2 )
  \ imagine a circle then on that circle are circles drawn around it
  \ nx ny are the location for first circle to draw nangle from to its center with usize as the radius
  \ uqnt is how many of these circles are drawn around the main circle that is not drawn
  \ usize2 is the radius of the distance of the next circle that is to start but it will be drawn with usize
  { nx ny nangle usize uqnt usize2 }
  nx s>f to rcx
  ny s>f to rcy
  uqnt 0 ?do
    rcx f>s to nx
    rcy f>s to ny
    nx ny nangle usize circle2
    nangle 360 uqnt / + to nangle
    nangle s>f rdeg>rrad fcos usize2 s>f f* nx s>f f+ to rcx
    nangle s>f rdeg>rrad fsin usize2 s>f f* ny s>f f+ to rcy
  loop ;

: circle-spin ( nx ny nangle usize uqnt )
\ nx ny is the center of where the circles spin around so it is an edge of all the circles
\ uangle is start angle for the circles of usize being the radius
\ uqnt is the amount of circles that are rotated around
  { nx ny nangle usize uqnt }
  uqnt 0 ?do
    nx ny nangle usize circle2
    nangle 360 uqnt / + to nangle
  loop ;

: ncircle-spin ( nx ny nangle usize uqnt uchange ulayers )
\ this will use circle-spin to draw circles around the point nx ny
\ then the next layer will be change with uchange added to usize for radius of next layer of circles
\ ulayers is the total layers that this process is done too
  { nx ny nangle usize uqnt uchange ulayers }
  ulayers 0 ?do
    nx ny nangle usize uqnt circle-spin
    usize uchange + to usize
  loop ;
