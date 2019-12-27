\ triangles.f

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

\ triangles drawing on sandtable

\ Requires:
\ on Gforth
\ sandmotorapi.fs
\ random.fs
\ on win32forth
\ sandmotorapi.f

\ Revisions:
\ 26/12/2019 started coding


: gforthtest ( -- nflag ) \ nflag is false if gforth is not running.  nflag is true if gforth is running
  c" gforth" find swap drop false = if false else true then ;
gforthtest true = [if]
  require random.fs
  require sandmotorapi.fs
[else]
  needs sandmotorapi.f
[then]
0 value trix1
0 value triy1
0 value trix2
0 value triy2
0 value trix3
0 value triy3
: triangle ( nxstart nystart udist1 uangle1 udist2 uangle2 -- ) \ draw triangle starting at nxstart nystart
\ note uangle1 and uangle2 are angles relative to drawing coordinates not triangle angles
  { nxstart nystart udist1 uangle1 udist2 uangle2 }
  nxstart nystart udist1 uangle1 coordinates? to triy1 to trix1
  nxstart nystart trix1 triy1 .s drawline . cr
  trix1 triy1 udist2 uangle2 coordinates? to triy2 to trix2
  trix1 triy1 trix2 triy2 .s drawline . cr
  trix2 triy2 nxstart nystart .s drawline . cr ;

: triangle2 ( udist1 uangle1 udist2 uangle2 -- ) \ draw trangle starting at current xposition and yposition
\ note uangle1 and uangle2 are not triangle angles but drawing angles relative to drawing coordinates
  xposition yposition { udist1 uangle1 udist2 uangle2 nx ny }
  xposition yposition 2dup udist1 uangle1 coordinates? .s drawline . cr
  xposition yposition 2dup udist2 uangle2 coordinates? .s drawline . cr
  xposition yposition nx ny .s drawline . cr ;
