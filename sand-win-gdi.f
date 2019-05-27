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
:OBJECT Grafdemo <SUPER WINDOW

ButtonControl Button_1   \ a button

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
        z" Drawing Figures with Win32Forth " ;M

:M StartSize:   ( -- width height )
        550 230 ;M

:M StartPos:    ( -- x y )
        100 100 ;M

\ Create five drawing methods.
\ Follow these patterns for other Windows figures such as Arc.
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

        \ Set up a Button
        IDOK               SetID: Button_1
        self               Start: Button_1
        160 180 70 25       Move: Button_1
        s" CLOSE"        SetText: Button_1
                        GetStyle: Button_1 BS_DEFPUSHBUTTON OR
                        SetStyle: Button_1

        \ Create all non Stock Object Pens and Brushes required.
        \ ONLY PenWidth 1 allowed with PenStyles other than PS_SOLID
        128 128 128 SetRGB: hPen1 12 SetWidth: hPen1 PS_SOLID SetStyle: hPen1 Create: hPen1
          0   0 255 SetRGB: hPen2  1 SetWidth: hPen1 PS_DOT   SetStyle: hPen2 Create: hPen2
        255   0   0 SetRGB: hPen3  4 SetWidth: hPen1 PS_SOLID SetStyle: hPen3 Create: hPen3
          0  255  0 SetRGB: hPen4  1 SetWidth: hPen1 PS_NULL  SetStyle: hPen4 Create: hPen4

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
                hPen1 SelectObject: tDC
                100 80 20 20 DrawRect: self

                \ Change the pen colour and draw a polyline
                Pen: MAGENTA SelectObject: tDC drop
                5 POLYDATA DrawPolyLine: self
                Pen: MAGENTA SelectObject: tDC drop
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
        Start: Grafdemo ;
DEMO

\ END OF LISTING
