Opt('TrayMenuMode',1)
Opt('TrayAutoPause',0)
Opt('TrayOnEventMode',1)
TrayItemSetOnEvent(TrayCreateItem('Exit'),Quit)
Global Const $DELTA_THRESHOLD = 48*48, $activationFingerCount = 3
Global Const $user32 = DllOpen('user32.dll')
Global Const $targetPage = 0xd, $targetUsage = 0x5
RegisterDevice($targetPage,$targetUsage,256,GUICreate(''))
GUIRegisterMsg(0xff,WM_INPUT)
Do
Until GUIGetMsg()=-3

Func WM_INPUT($h,$m,$w,$l)
     Local Static $lastFinger = 0, $lastCenter = [0,0], $accu=[0,0], $residual=[0,0], $hold=True
     Local Static $sendTag = 'dword;struct;long;long;dword;dword;dword;ulong_ptr;endstruct;'
     Local $raw = GetData($l)
     Local $parse = RAWHID($raw)
     Local $center = GetCenter($parse)
     Local $finger = DllStructGetData($parse,'input1',$parse.SizeHid-1)
     If $lastFinger = $activationFingerCount Then
        If $finger = $activationFingerCount Then
           Local $dx = $center[0]-$lastCenter[0], $dy = $center[1]-$lastCenter[1]
           If $hold Then
              $accu[0]+=$dx
              $accu[1]+=$dy
              If $accu[0]*$accu[0] + $accu[1]*$accu[1] > $DELTA_THRESHOLD Then
                 $hold = False
                 $accu[0] = 0
                 $accu[1] = 0
                 Local $struct = DllStructCreate($sendTag)
                 DllStructSetData($struct,1,0)
                 DllStructSetData($struct,5,2)
                 DllCall( $user32, 'uint', 'SendInput', 'uint', 1, 'struct*', $struct, 'int', DllStructGetSize($struct) )
              EndIf
           ElseIf $dx<>0 or $dy<>0 Then
              Local $struct = DllStructCreate($sendTag)
              Local $send = [ $residual[0]+$dx , $residual[1]+$dy ]
              $residual[0] = $send[0]-round($send[0])
              $residual[1] = $send[1]-round($send[1])
              DllStructSetData($struct,1,0)
              DllStructSetData($struct,2,round($send[0]))
              DllStructSetData($struct,3,round($send[1]))
              DllStructSetData($struct,5,1)
              DllCall( $user32, 'uint', 'SendInput', 'uint', 1, 'struct*', $struct, 'int', DllStructGetSize($struct) )
           EndIf
        Else
           $hold = True
           Local $struct = DllStructCreate($sendTag)
           DllStructSetData($struct,1,0)
           DllStructSetData($struct,5,4)
           DllCall( $user32, 'uint', 'SendInput', 'uint', 1, 'struct*', $struct, 'int', DllStructGetSize($struct) )
        EndIf
     EndIf
     $lastFinger = $finger
     $lastCenter = $center
     Return 0
EndFunc

Func GetCenter($parse)
     Local $_ = ToFingerCoord($parse), $count = DllStructGetData($parse,'input1',$parse.SizeHid-1)
     Local $a = [($_.x1+$_.x2+$_.x3+$_.x4+$_.x5)/$count,($_.y1+$_.y2+$_.y3+$_.y4+$_.y5)/$count]
     Return $a
EndFunc

Func ToFingerCoord($parse)
     Local $_ = DllStructCreate('ushort x1;ushort y1;ushort x2;ushort y2;ushort x3;ushort y3;ushort x4;ushort y4;ushort x5;ushort y5')
     Local $offset = 2
     For $i=1 to 5
         DllStructSetData($_, 'x' & $i, DllStructGetData($parse,'input1',$offset+1) + 256*DllStructGetData($parse,'input1',$offset+2) )
         DllStructSetData($_, 'y' & $i, DllStructGetData($parse,'input1',$offset+3) + 256*DllStructGetData($parse,'input1',$offset+4) )
         $offset += 5
     Next
     Return $_
EndFunc

Func RegisterDevice($page,$usage,$flag,$hWnd)
     Local Static $size = DllStructGetSize(DllStructCreate('ushort;ushort;dword;hwnd;'))
     Local $_ = DllStructCreate('ushort;ushort;dword;hwnd;')
     DllStructSetData($_,1,$page)
     DllStructSetData($_,2,$usage)
     DllStructSetData($_,3,$flag)
     DllStructSetData($_,4,$hWnd)
     DllCall($user32,'bool','RegisterRawInputDevices','struct*',$_,'uint',1,'uint',$size)
EndFunc

Func GetData($h)
     Local Static $headSize = DllStructGetSize(DllStructCreate('struct;dword;dword;handle;wparam;endstruct;'))
     Local $s = DllCall($user32, _
          'uint', 'GetRawInputData', _
        'handle', $h, _
          'uint', 0x10000003, _
       'struct*', Null, _
         'uint*', Null, _
          'uint', $headSize)[4]
     Return DllCall($user32, _
          'uint', 'GetRawInputData', _
        'handle', $h, _
          'uint', 0x10000003, _
       'struct*', DllStructCreate('byte[' & $s & ']'), _
         'uint*', $s, _
          'uint', $headSize)[3]
EndFunc

Func RAWHID($raw)
     Local Static $pre = 'struct;dword Type;dword Size;handle hDevice;wparam wParam;endstruct;dword SizeHid;dword Count;'
     Local $ptr = DllStructGetPtr($raw)
     Local $_ = DllStructCreate($pre,$ptr)
     Local $s = DllStructGetData($_,'SizeHid')
     Local $tag = $pre
     For $i=1 to DllStructGetData($_,'Count')
         $tag &= 'byte input' & $i & '[' & $s & '];'
     Next
     Return DllStructCreate( $tag , $ptr )
EndFunc

Func Quit()
     Exit
EndFunc