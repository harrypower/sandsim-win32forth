\ vectortools.f

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

\ tools to convert gcode to vector data used by vectordraw.f

\ Requires:
\ raw x and y data input file at -> c:\Users\Philip\Documents\inkscape-stuff\raw.data
\ processed angle distance output file placed at -> c:\Users\Philip\Documents\inkscape-stuff\vector.data

\ Revisions:
\ 07/01/2021 started coding
\ 07/15/2021 file input and processing to internal list of xypairs
\ 07/15/2021 rect to polar converstion

needs linklist.f
needs extstruct.f

10 set-precision
0.0e fvalue tempx
0.0e fvalue tempy
0 value fid
256 value buffersize
0 value xypairsize
buffersize chars buffer: xypair$
\ 0.0e fvalue fx1
\ 0.0e fvalue fy1
\ 0.0e fvalue fx2
\ 0.0e fvalue fy2
\ 0.0e fvalue fangle
\ 0.0e fvalue fdistance

: openrawfile ( -- )
  s" c:\Users\Philip\Documents\inkscape-stuff\raw.data" r/o open-file throw to fid ;

: openvectoroutfile ( -- )
  s" c:\Users\Philip\Documents\inkscape-stuff\vector.data" file-status true <> if
    s" c:\Users\Philip\Documents\inkscape-stuff\vector.data" delete-file throw
  then
  drop
  s" c:\Users\Philip\Documents\inkscape-stuff\vector.data" w/o create-file throw to fid ;

: getxf ( naddr u -- nflag  fs: -- fx ) \ string naddr u if it contains the x string turn it in floating stack and true
    2dup s"  " search if swap drop - >float if true else false 0.0e then else 2drop 2drop false 0.0e then ;

: getyf ( naddr u -- nflag  fs: -- fy ) \ string naddr u if it contains the y string turn it in floating stack and true
\ if string is not understandable as a floating number then return false and the floating stack contains 0.0e
  s"  " search if 1 /string  -trailing >float if true else false 0.0e then else 2drop false 0.0e then ;

: getxyf ( naddr u -- nflag fs: -- fx fy )
  2dup getxf rot rot getyf and ;

: getxypair ( -- nflag fs: -- fx fy )
\ nflag is true if an xy pair was read in from file
\ nflag is false if the file has no more lines to read or if the raw.data file is not readable
\ the floating value of xy pair are returned on floating stack and is only valid if nflag is true
  xypair$ buffersize fid read-line throw
  if
    xypair$ swap getxyf
  else
    drop false 0.0e 0.0e
  then ;

:struct rawpoint
  b/float fx
  b/float fy
;struct

:struct vectordata
  b/float fangle
  b/float fdistance
;struct

\ rawpoint vectordata  \ this is needed to allow the structure members to be visible after this point in code for compiling
\ sizeof rawpoint allocate throw value myfloat
\ f# 123.234503 myfloat fx f!
\ previous previous \ these are needed to remove the visability of the structure members exposed above

\ Define Object containing the line data list
:OBJECT rawxy <SUPER Linked-List

:M ClassInit:  ( -- ) \ constructor
  ClassInit: super
  ;M

:M ~: ( -- ) \ destructor
  \ first remove all the allocated floating data in the list here
  >firstlink: self
  #links: self 1 - 0 ?do
    data@: self >nextlink: self
    dup 0 = if drop else free throw then
  loop
  ~: super
  ;M

:M fxy!: ( -- f: fx fy -- ) \ store fx and fy in list
  sizeof rawpoint allocate throw
  [ rawpoint ]
  dup dup fy f! fx f!
  data!: self addlink: self
  [ previous ]
  ;M

:M fxy@: ( -- f: -- fx fy ) \ retrieve next nx ny from list ... note this also steps to next link
  data@: self >nextlink: self
  [ rawpoint ]
  dup fx f@ fy f@
  [ previous ]
  ;M

:M qnt: ( -- nline-qnt ) \ return how many data pairs
  #Links: self 1 - ;M

;OBJECT

\ previous previous

: readrawxy ( -- ) \ opens and reads raw.data file and puts the xy data in rawxy linked list
  openrawfile
  qnt: rawxy 0 <> if ~: rawxy then
  begin
    getxypair
    if fxy!: rawxy false else fdrop fdrop true then
  until
  fid close-file throw ;

: rect>polar ( -- f: fx1 fy1 fx2 fy2 -- fangle fdistance )
  frot f- ( -- f: -- fx1 fx2 fy )
  fswap frot f- ( -- f: -- fy fx )
  fdup frot fdup frot ( -- f: -- fx fy fy fx )
  2.0e f** fswap 2.0e f** ( -- f: -- fx fy fx3 fy3 )
  f+ fsqrt ( -- f: -- fx fy fdistance )
  frot frot ( -- f: -- fdistance fx fy )
  fswap fatan2 ( -- f: -- fdistance fangleradian )
  180e fpi f/ f* fswap ( -- f: -- fangle fdistance )
;

:OBJECT rawad <SUPER Linked-List

:M ClassInit:  ( -- ) \ constructor
  ClassInit: super
  ;M

:M ~: ( -- ) \ destructor
\ first remove all the allocated floating data in the list here
  >firstlink: self
  #links: self 1 - 0 ?do
    data@: self >nextlink: self
    dup 0 = if drop else free throw then
  loop
  ~: super
  ;M

:M fad!: ( -- f: fangle fdistance -- ) \ store fangle and fdistance in list
  sizeof vectordata allocate throw
  [ vectordata ]
  dup dup fdistance f! fangle f!
  data!: self addlink: self
  [ previous ]
  ;M

:M fad@: ( -- f: -- fangle fdistance ) \ retrieve next nx ny from list
  data@: self >nextlink: self
  [ vectordata ]
  dup fangle f@ fdistance f@
  [ previous ]
  ;M

:M qnt: ( -- nline-qnt ) \ return how many data pairs
  #Links: self 1 - ;M

;OBJECT

: makepolar ( -- ) \ take rect data list and make the polar data list from it
  >firstlink: rawxy
  qnt: rawad 0 <> if ~: rawxy then
  qnt: rawxy 1 - 0 ?do
    fxy@: rawxy
    fxy@: rawxy
    link#: rawxy 1 - >link#: rawxy
    rect>polar
    fad!: rawad
  loop
;
