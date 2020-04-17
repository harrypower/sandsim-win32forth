\ vectordraw.f

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
\ on win32forth
\ sandmotorapi.f

\ Revisions:
\ 04/17/2020 started coding

: gforthtest ( -- nflag ) \ nflag is false if gforth is not running.  nflag is true if gforth is running
  c" gforth" find swap drop false = if false else true then ;
gforthtest true = [if]
  require sandmotorapi.fs
[else]
  needs sandmotorapi.f
[then]

: drawvector ( nx ny nangle ndistance -- nx1 ny1 nflag ) \ starting at nx ny location draw a line ndistance long nangles from 3 oclock as 0 angle
\ nflag is 200 if drawing took place and nx1 ny1 are valid current drawing locations
\ nflag is 201 if drawing had some error and nx1 and ny1 are not valid current drawing locations
  0 0 { nx ny nangle ndistance nx1 ny1 }
  ndistance nangle (calc-na) to nx1
  ndistance nangle (calc-nb) to ny1
  nx1 nx + to nx1
  ny1 ny + to ny1
  nx ny nx1 ny1 drawline
  nx1 swap ny1 swap ;
