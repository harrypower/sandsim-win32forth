\ spirograph.f
\    Copyright (C) 2020  Philip King Smith

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
\ on Gforth
\ sandmotorapi.fs
\ random.fs
\ on win32forth
\ sandmotorapi.f

\ Revisions:
\ 06/15/2020 started coding

: gforthtest ( -- nflag ) \ nflag is false if gforth is not running.  nflag is true if gforth is running
  c" gforth" find swap drop false = if false else true then ;
gforthtest true = [if]
  require random.fs
  require sandmotorapi.fs
[else]
  needs sandmotorapi.f
[then]

0 value xcenter
0 value ycenter
0 value x1
0 value y1
0 value aangle1
0 value bangle1
0 value distance1
0 value x2
0 value y2
0 value aangle2
0 value bangle2
0 value distance2
0 value x3
0 value y3
0 value aangle3
0 value bangle3
0 value distance3
0 value nsteps
0 value xend
0 value yend

: polar>rect ( nangle ndistance - nx ny ) \ convert angle distance to x and y corrodinates with unit circle math
  2dup
  s>f deg>rads fcos f* \ ( nangle ndistance -- ) ( -- :r nx )
  s>f deg>rads fsin f* f>s f>s swap ; \ ( nx ny -- )

: threeleggedspiral ( ntimes nx ny angle1 distance1 angle2 distance2 angel3 distance3 -- ) \ draws 3 legged spirograph assuming current x and y possion is start of pattern and 0 angle is start for all 3 legs
  to distance3
  to aangle3
  to distance2
  to aangle2
  to distance1
  to aangle1
  to yend
  to xend
  to nsteps
  0 to bangle1
  0 to bangle2
  0 to bangle3
  180 distance3 polar>rect yend + to y2 xend + to x2
  180 distance2 polar>rect y2 + to y1 x2 + to x1
  180 distance1 polar>rect y1 + to ycenter x1 + to xcenter \ now i have the center coordinates
  nsteps 0 ?do
    aangle1 bangle1 + dup to bangle1 distance1 polar>rect ycenter + to y1 xcenter + to x1
    aangle2 bangle2 + dup to bangle2 distance2 polar>rect y1 + to y2 x1 + to x2
    aangle3 bangle3 + dup to bangle3 distance3 polar>rect y2 + to y3 x2 + to x3 \ now i have new x an y coordinates to move to
    xend yend x3 y3 drawline . \ now xposition and yposition have moved so redo this caluclation from center again
    x3 to xend y3 to yend
  loop ;
