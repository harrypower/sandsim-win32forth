\ sand-win-gdi.F    Sandtable tester for windows using GDI and win32forth
\ used original example figgraph.f from win32forth
\ Written by David R. Pochin

\ Used to test sandtable drawing patterns
\ 05/26/2019 started coding

anew -sand-win-gdi.f
needs linklist.f
needs gdi/gdi.f

\ Define an Object that is a child of the Class Window
:OBJECT Sandtable-demo <SUPER WINDOW

gdiWindowDC tDC

\ Set Up handles for Pens and Brushes.
gdiPen hPen1
gdiPen hPen2
gdiHatchBrush hBrush1

\ Things to do at the start of window creation
:M ClassInit:   ( -- )
        ClassInit: super \ Do anything the super class needs.
        ;M

:M WindowTitle: ( -- title )
        z" Simulated sandtable with Win32Forth " ;M

:M StartSize:   ( -- width height )
        600 600 ;M

:M StartPos:    ( -- x y )
        100 100 ;M

:M DrawRect:    ( bottom right top left -- )
        4reverse Rectangle: tDC ;M

:M DrawLineto: ( nxend nyend -- )
        LineTo: tDC ;M

\ Remember to delete any objects you have made before closing.
:M Close:       ( -- )
        Destroy: hPen1
        Destroy: hPen2
        Destroy: hBrush1
        Destroy: tDC
        Close: super
        ;M

:M On_Init:     ( -- )

        \ Create all non Stock Object Pens and Brushes required.
        \ ONLY PenWidth 1 allowed with PenStyles other than PS_SOLID
        128 128 128 SetRGB: hPen1 12 SetWidth: hPen1 PS_SOLID SetStyle: hPen1 Create: hPen1
        255   0   0 SetRGB: hPen2  4 SetWidth: hPen2 PS_SOLID SetStyle: hPen2 Create: hPen2

          0 128 128 SetRGB: hBrush1 HS_DIAGCROSS SetStyle: hBrush1 Create: hBrush1

        ;M

:M On_Paint:  ( -- )          \ screen redraw procedure
        GetHandle: self GetDC: tDC
        if
                \ Select pen hPen1
                hPen1 SelectObject: tDC

                \ Set Brush to LTGREEN
                Brush: LTGREEN SelectObject: tDC

                \ draw a rectangle with solid fill
                hPen1 SelectObject: tDC drop
                0 0  StartSize: self DrawRect: self

                0 0 MoveTo: tDC drop drop
                \ Change the pen colour and draw a line
                hPen2 SelectObject: tDC drop
                100 200 DrawLineto: self
                200 300 DrawLineto: self
                300 300 DrawLineto: self

                \ cleanup
                SelectObject: tDC drop \ bursh
                SelectObject: tDC drop \ pen
                Release: tDC
        then ;M

 :M WM_COMMAND   ( hwnd msg wparam lparam -- res )
        OVER LOWORD ( Id )
        CASE    IDOK OF Close: self ENDOF
        ENDCASE 0 ;M

 ;OBJECT

: DEMO  ( -- )
        Start: Sandtable-demo ;
DEMO

\ END OF LISTING
