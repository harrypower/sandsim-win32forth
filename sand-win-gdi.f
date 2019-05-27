\ sand-win-gdi.F    Sandtable tester for windows using GDI and win32forth
\ used original example figgraph.f from win32forth
\ Written by David R. Pochin

\ Used to test sandtable drawing patterns
\ 05/26/2019 started coding

anew -FigGraph.f

needs gdi/gdi.f
create polytest
  160 , 90 , 200 , 120 ,
polytest value polydataddr@
2 value polysize

\ Define an Object that is a child of the Class Window
:OBJECT Sandtable-demo <SUPER WINDOW

gdiWindowDC tDC

\ Set Up handles for Pens and Brushes.
gdiPen hPen1
gdiPen hPen2
gdiPen hPen3
gdiPen hPen4
gdiHatchBrush hBrush1

\ Set up Array of Data Points for use with Polyline.
Create POLYDATA
        ( x1 , y1 , x2 , y2 , etc )
        140 , 70 , 180 , 100 , 200 , 50 , 230 , 90 , 250 , 80 ,

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

:M DrawPolyLine:  ( n addr -- )
        swap Polyline: tDC ;M

\ Remember to delete any objects you have made before closing.
:M Close:       ( -- )
        Destroy: hPen1
        Destroy: hPen2
        Destroy: hPen3
        Destroy: hPen4
        Destroy: hBrush1
        Destroy: tDC
        Close: super
        ;M

:M On_Init:     ( -- )

        \ Create all non Stock Object Pens and Brushes required.
        \ ONLY PenWidth 1 allowed with PenStyles other than PS_SOLID
        128 128 128 SetRGB: hPen1 12 SetWidth: hPen1 PS_SOLID SetStyle: hPen1 Create: hPen1
          0   0 255 SetRGB: hPen2  1 SetWidth: hPen2 PS_DOT   SetStyle: hPen2 Create: hPen2
        255   0   0 SetRGB: hPen3  4 SetWidth: hPen3 PS_SOLID SetStyle: hPen3 Create: hPen3
          0  255  0 SetRGB: hPen4  1 SetWidth: hPen4 PS_NULL  SetStyle: hPen4 Create: hPen4

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

                \ Change the pen colour and draw a polyline
                Pen: MAGENTA SelectObject: tDC drop
                5 POLYDATA DrawPolyLine: self
                hPen3 SelectObject: tDC drop
                polysize polydataddr@ DrawPolyLine: self

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
