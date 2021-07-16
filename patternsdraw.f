\ patternsdraw.f

\    Copyright (C) 2021  Philip King Smith

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

\ words to read data from vector files made by vectortools.f
\ then this vector data can be drawn on the sandtable with and angle offset and a scale factor  at any x y location

\ Requires:
\ this will run under win32forth for the sandsim to test patterns first
\ i may try to make this work for both gforth and win32forth but not at this moment

\ Revisions:
\ 07/01/2021 started coding

needs linklist.f
needs extstruct.f
needs sandmotorapi.f

10 set-precision
0 value fid
256 value buffersize
0 value adsize
buffersize chars buffer: adpair$

: openvectorfile ( -- )
  s" c:\Users\Philip\Documents\inkscape-stuff\vector.data" r/o open-file throw to fid ;
