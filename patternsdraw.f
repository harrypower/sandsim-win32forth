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

: getaf ( naddr u -- nflag  fs: -- fa ) \ string naddr u if it contains the angle string turn it in floating stack and true
    2dup s"  " search if swap drop - >float if true else false 0.0e then else 2drop 2drop false 0.0e then ;

: getdf ( naddr u -- nflag  fs: -- fd ) \ string naddr u if it contains the distance string turn it in floating stack and true
\ if string is not understandable as a floating number then return false and the floating stack contains 0.0e
  s"  " search if 1 /string  -trailing >float if true else false 0.0e then else 2drop false 0.0e then ;

: getadf ( naddr u -- nflag fs: -- fa fd )
  2dup getaf rot rot getdf and ;

: getadpair ( -- nflag fs: -- fx fy )
\ nflag is true if an xy pair was read in from file
\ nflag is false if the file has no more lines to read or if the raw.data file is not readable
\ the floating value of xy pair are returned on floating stack and is only valid if nflag is true
  adpair$ buffersize fid read-line throw
  if
    adpair$ swap getadf
  else
    drop false 0.0e 0.0e
  then ;

:struct vectordata
  b/float fangle
  b/float fdistance
;struct

:OBJECT rawad <SUPER Linked-List \ object to contain fangle and fdistance linked list

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

:M fad@: ( -- f: -- fangle fdistance ) \ retrieve nx ny from list at current link
  data@: self
  [ vectordata ]
  dup fangle f@ fdistance f@
  [ previous ]
  ;M

:M qnt: ( -- nline-qnt ) \ return how many data pairs
  #Links: self 1 - ;M

;OBJECT

: readrawad ( -- ) \ opens and reads vector.data file and puts the xy data in rawad linked list
  openvectorfile
  qnt: rawad 0 <> if ~: rawad then
  begin
    getadpair
    if fad!: rawad false else fdrop fdrop true then
  until
  fid close-file throw ;

:struct deltpoint
  b/float fx
  b/float fy
;struct

:OBJECT deltaxy <SUPER Linked-List \ object to contain delta x and delta y data calculated from rawad data

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

:M fxy!: ( -- f: fx fy -- ) \ store fx and fy in list at current link list location
  sizeof deltpoint allocate throw
  [ deltpoint ]
  dup dup fy f! fx f!
  data!: self addlink: self
  [ previous ]
  ;M

:M fxy@: ( -- f: -- fx fy ) \ retrieve next nx ny from list ... note this does not step to the next list node
  data@: self
  [ deltpoint ]
  dup fx f@ fy f@
  [ previous ]
  ;M

:M qnt: ( -- nline-qnt ) \ return how many data pairs
  #Links: self 1 - ;M

;OBJECT

: degrees>radians ( -- f: fangle -- fangle1 ) \ convert degrees to radians
  fpi 180e f/ f* ;

: calcpolar>rect  ( nxscale nyscale nangle -- f: fangle fdistance -- fx fy )
\ given the nangle change and the nxscale and nyscale change calculate the fx and fy of the input fangle and fdistance data
\ fx and fy is the change assuming the fangle fdistance started at x 0 and y 0
  fswap degrees>radians s>f degrees>radians f+ ( nxscale nyscale f: fdistance fangle1 )
  f2dup fcos f* ( nxscale nyscale f: fdistance fangle1 fx )
  frot frot fsin f* ( nxscale nyscale f: fx fy )
  s>f 10.0e f/ f* ( nxscale f: fx fy1 )
  fswap s>f 10.0e f/ f* fswap ( f: fx1 fy1 )
;

: calcdeltaxy { nxscale nyscale nangle -- } \ read the rawad data and calculate the offsetpoint data given the nxscale nyscale and nangle data then store in deltaxy
  qnt: deltaxy 0 <> if ~: deltaxy then
  >firstlink: rawad
  qnt: rawad 0 ?do
    fad@: rawad nxscale nyscale nangle calcpolar>rect
    fxy!: deltaxy
    >nextlink: rawad
  loop
;
