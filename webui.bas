Const PANEL = "panel", BUTTON = "button", LABEL = "label", TEXTBOX = "textbox"
Const LAYOUT_FIXED = "fixed", LAYOUT_FLOW = "flow"

Export PANEL, BUTTON, LABEL, TEXTBOX
Export LAYOUT_FIXED, LAYOUT_FLOW
Export Init, CreatePanel, CreateButton, CreateLabel, CreateTextBox
Export SetName, GetName, SetText, GetText, SetPos, SetWidth, SetHeight, GetWidth, GetHeight, Event, CSS
Export GetEventHandler, SetEventHandler, GetEvents, ControlCount
Export GetControl, ExportUI, LoadUI, GetSub

Const GRIDSIZE = 5
Const True = -1, False = 0

Type Control
    type As Integer
    name As String
    e As Object
    parent As Integer
    sibling As Integer
    layout As Integer
    text As String
    multiline As Integer
    x As String
    y As String
    width As String
    height As String
    padding As String
    margin As String
    events As Object
End Type

Type CEvent
    cid As Integer
    event As String
    method As String
End Type

ReDim Shared controls(0) As Control
'Dim Shared events(0) As CEvent
ReDim Shared eventMap() As String
Dim Shared As Object cpanel


Function ExportUI
    Dim i As Integer
    Dim As String s, l, e, c
	l = "webui_" + (Timer * 1000)

	For i = 1 To UBound(controls)
		If controls(i).name Then
			If e = "" Then
				e = "Const " + controls(i).name + " = " + i
			Else
				e = e + ", " + controls(i).name + " = " + i
			End If
		End If
	Next i

	For i = 1 To UBound(controls)
		If controls(i).name Then
			If c = "" Then
				c = "Export " + controls(i).name
			Else
				c = c + ", " + controls(i).name
			End If
		End If
	Next i

	If e Then
		s = s + e + Chr$(10)
	End If
	If c Then
		s = s + c + Chr$(10)
	End If

	s = s + "__Load" + Chr$(10) + Chr$(10)
	
	s = s + l + ":" + Chr$(10)
	s = s + "' Controls" + Chr$(10)
    s = s + "Data " + UBound(controls) + Chr$(10)
    For i = 1 To UBound(controls)
        Dim ctrl As Control: ctrl = controls(i)        
        s = s + "Data " + i + ","
        s = s + Q(ctrl.type) + ","
        s = s + Q(ctrl.name)  + ","
        s = s + ctrl.parent + ","
        s = s + Q(ctrl.layout) + ","
        s = s + Q(GXSTR_Replace(ctrl.text, Chr$(10), "\n")) + ","
        s = s + ctrl.multiline + ","
        s = s + Q(ctrl.x) + ","
        s = s + Q(ctrl.y) + ","
        s = s + Q(ctrl.width) + ","
        s = s + Q(ctrl.height) + ","
        s = s + Q(ctrl.padding) + ","
        s = s + Q(ctrl.margin)
        s = s + Chr$(10) 'Chr$(13)
    Next i
    
    ReDim events(0) As CEvent
    GetEvents events
	s = s + "' Events" + Chr$(10)
    s = s + "Data " + UBound(events) + Chr$(10)
    For i = 1 To UBound(events)
        s = s + "Data "' + i + ","
        s = s + events(i).cid + ","
        s = s + Q(events(i).event) + ","
        s = s + Q(events(i).method) + Chr$(10)
    Next i
	
	s = s + "Data " + Q("webui_end") + Chr$(10) + Chr$(10)
	
	s = s + "Sub __Load" + Chr$(10)
	s = s + "    Restore " + l + Chr$(10)
	s = s + "    UI.LoadUI" + Chr$(10)
	s = s + "End Sub"
	
    ExportUI = s
End Sub

Sub LoadUI
	Init
	
    ' Create controls
    Dim As Integer i, id, mutiline, parent
    Dim As String ftype, fname, text, layout, x, y, w, h, p, m

    Dim size As Integer
    Read size
    'Console.Log size
    For i = 1 To size
        Read id
        Read ftype
        Read fname
        Read parent
        Read layout
        Read text
        Read multiline
        Read x
        Read y
        Read w
        Read h
        Read p
        Read m
        
        'Console.Log id + ":" + ftype + ":" + fname + ":" + parent + ":" + layout + ":" + text + ":" + multiline + ":" + x + ":" + y + ":" + w + ":" + h

        id = 0
        If ftype = PANEL Then
            id = CreatePanel(layout, parent)
        ElseIf ftype = LABEL Then
            id = CreateLabel(parent, text)
        ElseIf ftype = TEXTBOX Then
            id = CreateTextBox(parent, multiline)
        ElseIf ftype = BUTTON Then
            id = CreateButton(parent, text)
        End If
        If id Then
            If x <> "" And y <> "" Then
                SetPos id, x, y
            End If
            
            If w <> "" Then SetWidth id, w
            If h <> "" Then SetHeight id, h
        End If
		SetName id, fname
    Next i
    
    ' Register Events
    Dim As String event, callback
    Read size
    'Console.Log size
    For i = 1 To size
        'Read id
        'Console.Log ">" + id
        Read id
        'Console.Log ">>" + id
        Read event
        Read callback
        
        'Console.Log id + ":" + event + ":" + callback
        Event id, event, callback
    Next i
End Sub

Function Q(s As String)
	Q = Chr$(34) + s + Chr$(34)
End Function

Sub Init (dmode As Integer)
    Clear
    ReDim controls(0) As Control
    'designMode = dmode
    
    Dom.Container().style.textAlign = "left"
    Dom.Container().style.backgroundColor = "#efefef"
    Dom.Container().style.color = "#333"
    Dom.Container().style.fontFamily = "sans-serif"
    Dom.Container().style.fontSize = "14px"
    Dom.GetImage(0).style.display = "none"
    
    Dim s As Object
    s = Dom.Create("style")
    s.innerHTML = "input, select, textarea { font-family: sans-serif; font-size: 14px }"

    cpanel = Dom.Create("div")

    eventMap("Click") = "click"
    eventMap("SetFocus") = "focus"
End Sub

Function CreatePanel (layout, parentId)
    If layout = undefined Then
        layout = LAYOUT_FLOW
    End If
    
    Dim id As Integer: id = NewControl
    controls(id).type = PANEL
    controls(id).layout = layout

    If parentId = undefined Or parentId = 0 Then
        controls(id).e = Dom.Create("div", cpanel)
        If layout = LAYOUT_FIXED Then CSS id, "position", "relative"
    Else
        controls(id).parent = parentId
        Dim parent As Control
        parent = controls(parentId)
        _Echo "parent: " + parent
        controls(id).e = Dom.Create("div", parent.e)
        If parent.layout = LAYOUT_FIXED Then 
            CSS id, "position", "absolute"
        ElseIf layout = LAYOUT_FIXED Then
            CSS id, "position", "relative"
        End If
    End If
   
    CSS id, "background-color", "#efefef"
    'If layout = LAYOUT_FIXED Then
    '    CSS id, "background-image", "url('" + DataUrl("img/grid-5.png") + "')"
    'End If
    
    'If designMode Then
    '    Event id, "mousedown", "OnMouseDown"
    '    Event id, "mousemove", "OnMouseMove"
    '    Event id, "mouseup", "OnMouseUp"
    'End If
    'If parentId Then MakeDraggable id
    
    controls(id).e.id = "vqb-" + id
    controls(id).e.cid = id

    CreatePanel = id
End Function

Function CreateButton (parentId As Integer, text As String)
    Dim parent As Control
    parent = controls(parentId)
    If parent = undefined Then Exit Sub
    If text = undefined Then text = ""
    
    Dim id As Integer: id = NewControl
    controls(id).type = BUTTON
    controls(id).parent = parentId
    controls(id).text = text
    controls(id).e = Dom.Create("button", parent.e, text)
    controls(id).e.cid = id
    CSS id, "vertical-align", "top"

    If parent.layout = LAYOUT_FIXED Then
        CSS id, "position", "absolute"
    End If
    'MakeDraggable id
    
    CreateButton = id
End Function

Function CreateLabel (parentId As Integer, text As String)
    Dim parent As Control
    parent = controls(parentId)
    If parent = undefined Then Exit Sub
    If text = undefined Then text = ""

    Dim id As Integer: id = NewControl
    controls(id).type = LABEL
    controls(id).parent = parentId
    controls(id).text = text 
    controls(id).e = Dom.Create("span", parent.e, GXSTR_Replace(text, Chr$(10), "<br>"))
    controls(id).e.cid = id
    CSS id, "display", "inline-block"
    CSS id, "vertical-align", "top"

    If parent.layout = LAYOUT_FIXED Then
        CSS id, "position", "absolute"
    End If
    'MakeDraggable id
    
    CreateLabel = id
End Function

Function CreateTextBox (parentId As Integer, multiline)
    Dim parent As Control
    parent = controls(parentId)
    If parent = undefined Then Exit Sub

    Dim id As Integer: id = NewControl
    controls(id).type = TEXTBOX
    controls(id).parent = parentId
    If multiline Then
        controls(id).e = Dom.Create("textarea", parent.e)
        controls(id).multiline = True
    Else
        controls(id).e = Dom.Create("input", parent.e)
        controls(id).multiline = False
    End If
    controls(id).e.cid = id

    CSS id, "vertical-align", "top"
    
    If parent.layout = LAYOUT_FIXED Then
        CSS id, "position", "absolute"
    End If
    'MakeDraggable id

    CreateTextBox = id
End Function

Function NewControl
    Dim id As Integer
    id = UBound(controls) + 1
    ReDim Preserve controls(id) As Control
    NewControl = id
End Function

Function GetControl (id As Integer)
    GetControl = controls(id)
End Function

Function ControlCount
    ControlCount = UBound(controls)
End Function

'Function NewEvent
'    Dim id As Integer
'    id = UBound(events) + 1
'    ReDim Preserve events(id) As CEvent
'    NewEvent = id
'End Function

Sub SetName (id As Integer, name As String)
    Dim c As Control
    c = controls(id)
    If c = undefined Then Exit Sub
    
    c.text = text
End Sub

Function GetName (id As Integer)
    Dim cname As String
    Dim c As Control
    c = controls(id)
    If c <> undefined Then
        cname = controls(i).name
    End If
    GetName = cname
End Function

Sub SetText (id As Integer, text As String)
    Dim c As Control
    c = controls(id)
    If c = undefined Then Exit Sub
    
    c.text = text
    If c.e.value <> undefined Then
        c.e.value = text
    Else
        c.e.innerHTML = text
    End If
End Sub

Function GetText (id As Integer)
    Dim c As Control
    c = controls(id)
    If c = undefined Then Exit Sub
    
    If c.type = TEXTBOX Then
        If c.multiline Then
            GetText = c.e.innerText
        Else
            GetText = c.e.value
        End If
    ElseIf c.type = LABEL Or c.type = BUTTON Then
        GetText = c.e.innerHTML
    End If
End Function

Sub SetPos (id As Integer, x As Integer, y As Integer)
    Dim c As Control: c = controls(id)
    If c = undefined Then Exit Sub
    
    c.x = Round(x / GRIDSIZE) * GRIDSIZE
    c.y = Round(y / GRIDSIZE) * GRIDSIZE

    c.e.style.left = c.x + "px"
    c.e.style.top = c.y + "px"
End Sub

Sub SetWidth (id As Integer, w As String)
	If w = undefined Then w = ""
	controls(id).width = w
	If w <> "" Then w = w + "px"
	controls(id).e.style.width = w
End Sub

Function GetWidth (id As Integer) : GetWidth = controls(id).width : End Function

Sub SetHeight (id As Integer, h As String)
	If h = undefined Then h = ""
	controls(id).height = h
	If h <> "" Then h = h + "px"
	controls(id).e.style.height = h
End Sub

Function GetHeight (id As Integer) : GetHeight = controls(id).height : End Function

Sub SetName (id As Integer, cname As String) : controls(id).name = cname : End Sub
Function GetName (id As Integer) : GetName = controls(id).name : End Function

Sub Event (id As Integer, event As String, subName As String)
    Dim fn As Object
    fn = GetSub(subName)
    If fn = undefined Then 
        Exit Sub
    End If
    
    Dim ctrl As Object
    ctrl = controls(id)
    If ctrl = undefined Then 
        Exit Sub
    End If
    
    Dim jsEvent As String
    jsEvent = eventMap(event)
    If jsEvent = undefined Then 
        Exit Sub
    End If

    Dom.Event ctrl.e, jsEvent, fn 
    SetEventHandler id, event, subName
End Sub


Function GetEventHandler (cid As Integer, event As String)
    Dim As Object ctrl
    ctrl = controls(cid)
    If ctrl = undefined Then 
        Exit Sub
    End If

    Dim subName As String
    subName = ctrl.events[event]
    If subName = undefined Then 
        subName = ""
    End If

    GetEventHandler = subName
End Function



Sub CSS (id As Integer, name As String, value As String)
    Dim ctrl As Object: ctrl = controls(id)
    '_Echo ctrl
    If ctrl = undefined Then
        Exit Sub
    End If
    $If Javascript Then
        ctrl.e.style[name] = value
    $End If
End Sub

Function GetSub(subName As String)
    Dim fn As Object
    $If Javascript Then
        fn = eval("sub_" + subName);
    $End If
    GetSub = fn
End Function


Sub SetEventHandler (cid As Integer, event As String, subName As String)
    Dim As Object ctrl
    ctrl = controls(cid)
    If ctrl = undefined Then 
        Exit Sub
    End If

    '_Echo event + ":" + subName
    $If Javascript Then
        ctrl.events[event] = subName
    $End If
End Sub

Sub GetEvents (events() As CEvent)
    ReDim events(0) As CEvent
    Dim i As Integer
    For i = 1 To UBound(controls)
        Dim ce As Object
        ce = controls(i).events
        'Dim subName As String
        $If Javascript Then
            var keys = Object.keys(ce);
            //console.log(ce);
            //console.log(keys);
            console.log("l:" + keys.length);
            for (var ki=0; ki < keys.length; ki++) {
                var k = keys[ki];
                var subName = ce[k];
                console.log("key: " + k);                
                console.log("sub: " + subName);
        $End If
                Dim ecount As Integer
                ecount = UBound(events) + 1
                ReDim _Preserve events(ecount) As CEvent
                events(ecount).cid = i
                events(ecount).event = k
                events(ecount).method = subName
        $If Javascript Then
            }
        $End If
    Next i
End Sub

Sub Clear
$If Javascript Then
    if (QB._domElements) {
        var e = null;    
        while (e = QB._domElements.pop()) {
            e.remove();
        }
    }
    else { 
        QB._domElements = []; 
    }

    if (QB._domEvents) {
        while (e = QB._domEvents.pop()) {
            e.target.removeEventListener(e.eventType, e.callbackFn);
        }
    }
    else {
        QB._domEvents = [];
    }
$End If
End Sub