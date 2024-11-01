Import Dom From "lib/web/dom.bas"
Import PGrid From "property-grid.bas"
Import UI From "webui.bas"
Import FS From "lib/io/fs.bas"
Import Console From "lib/web/console.bas"
Console.LogLevel Console.NONE

Const False = 0
Const True = Not False
Const NL = Chr$(10)

Dim Shared As Object props, sstyle, rsize
Dim Shared As Integer selected, frmMain, moving, resizing

Init

Dim info As String
info = "QBJS Form Designer - POC" + NL + NL + _
       "Drag a control type from the upper left to add it to the form." + NL + NL + _
       "Resize the selected control by dragging the lower right corner."

Dim As Object label
label = UI.CreateLabel(frmMain, info)
UI.CSS label, "user-select", "none"
UI.SetName label, "lblDemo"
UI.SetPos label, 30, 30




Sub Init
    UI.Init
    
    frmMain = UI.CreatePanel(UI.LAYOUT_FIXED)
    UI.SetName frmMain, "frmMain"
    UI.CSS frmMain, "background-image", "url('" + DataURL("img/grid-5.png") + "')"
    
    Dim As Object o, cpanel
    o = UI.GetControl(frmMain)
    cpanel = o.e.parentNode
    
    cpanel.style.display = "grid"
    cpanel.style.gridTemplateColumns = "300px auto"
    cpanel.style.height = "100%"

    Dim lpanel As Object
    lpanel = Dom.Create("div", cpanel, , , o.e)
    lpanel.style.padding = "4px"
    lpanel.style.borderRight = "1px solid #999"

    Dim As Object toolbar, btnSave, btnSaveProj, btnLoad
    toolbar = Dom.Create("div", lpanel)
    toolbar.style.padding = "5px"
    toolbar.style.paddingTop = "0px"
    toolbar.style.marginBottom = "4px"
    toolbar.style.borderBottom = "1px solid #999"
    btnLoad = Dom.Create("a", toolbar, "Load Form")
    btnLoad.href = "#"
    Dom.Event btnLoad, "click", sub_OnLoad
    btnSave = Dom.Create("a", toolbar, "Save Form")
    btnSave.href = "#"
    btnSave.style.borderLeft = "1px solid #999"
    btnSave.style.paddingLeft = "4px"
    Dom.Event btnSave, "click", sub_OnSaveForm
    btnSaveProj = Dom.Create("a", toolbar, "Save Project")
    btnSaveProj.href = "#"
    btnSaveProj.style.borderLeft = "1px solid #999"
    btnSaveProj.style.paddingLeft = "4px"
    Dom.Event btnSaveProj, "click", sub_OnSaveProject
    

    Dim As Object bpanel
    bpanel = Dom.Create("div", lpanel)
    bpanel.style.marginBottom = "4px"
    bpanel.style.overflow = "auto"
    AddControlButton UI.LABEL, "label.png", bpanel, True
    AddControlButton UI.TEXTBOX, "textbox.png", bpanel, True
    AddControlButton UI.BUTTON, "button.png", bpanel, True
    AddControlButton UI.PANEL, "panel.png", bpanel, True
    
    props = PGrid.CreatePropertyGrid(lpanel)
    props.style.border = "1px inset #fff"
    Dom.Event props, "propchange", sub_OnPropChange
    
    Dom.Event document, "dragenter", sub_OnDragEnter
    Dom.Event document, "dragover", sub_OnDragOver
    Dom.Event document, "drop", sub_OnDrop
    
    Dom.Event o.e, "mousedown", sub_OnMouseDown
    Dom.Event o.e, "mousemove", sub_OnMouseMove
    Dom.Event o.e, "mouseup", sub_OnMouseUp
    
    SelectControl frmMain
End Sub

Sub AddControlButton(ftype, imgpath, bpanel, isImage)
    Dim btn As Object
    If isImage Then
        btn = Dom.Create("div", bpanel, "&nbsp;")
    Else
        btn = Dom.Create("div", bpanel, imgpath)
    End If
    btn.title = UCase$(Mid$(ftype, 1, 1)) + Mid$(ftype, 2)
    btn.draggable = true
    btn.ftype = ftype
    btn.style.display = "inline-block"
    btn.style.border = "1px solid #666"
    btn.style.borderRadius = "5px"
    btn.style.marginRight = "2px"
    btn.style.width = "24px"
    btn.style.height = "24px"
    If isImage Then
        btn.style.backgroundImage = "url('" + DataURL("img/" + imgpath) + "')"
        btn.style.backgroundRepeat = "no-repeat"
        btn.style.backgroundSize = "20px 20px"
        btn.style.backgroundPosition = "center"
    End If
    Dom.Event btn, "dragstart", sub_OnTypeDragStart
End Sub

Sub SelectControl (id As Integer)
    If selected Then
        Dim e As Object
        e = UI.GetControl(selected).e
        e.style.border = sstyle.border
        e.style.boxShadow = sstyle.boxShadow
    End If
    
    selected = id
    Dim ctrl As Object
    ctrl = UI.GetControl(selected)
    sstyle.border = ctrl.e.style.border
    sstyle.boxShadow = ctrl.e.style.boxShadow
    If ctrl.type = UI.LABEL Or _
       ctrl.type = UI.PANEL Then
        ctrl.e.style.border = "1px dashed #333"
    End If
    ctrl.e.style.boxShadow = "0px 0px 15px #999"

    PGrid.Clear
    PGrid.AddProp "ID", id, True
    PGrid.AddProp "Type", ctrl.type, True
    PGrid.AddProp "Name", ctrl.name
    If ctrl.type = UI.PANEL Then
        Dim optsLayout(2) As String
        optsLayout(1) = UI.LAYOUT_FIXED '"fixed"
        optsLayout(2) = UI.LAYOUT_FLOW '"flow"
        'optsLayout(3) = "grid"
        PGrid.AddProp "Layout", ctrl.layout, , optsLayout
    Else
        PGrid.AddProp "Text", ctrl.text, , , True
    End If
    
    If ctrl.type = UI.TEXTBOX Then
        Dim optsBool(2) As String
        optsBool(1) = "true"
        optsBool(2) = "false"
        Dim svalue As String
        If ctrl.multiline Then svalue = "true" Else svalue = "false"
        PGrid.AddProp "Multiline", svalue, , optsBool
    End If
    PGrid.AddProp "Left", ctrl.x, True
    PGrid.AddProp "Top", ctrl.y, True
    PGrid.AddProp "Width", ctrl.width
    PGrid.AddProp "Height", ctrl.height
    PGrid.AddHeader "Events"
    PGrid.AddProp "Click", UI.GetEventHandler(id, "Click")
    PGrid.AddProp "SetFocus", UI.GetEventHandler(id, "SetFocus")
End Sub

Sub UpdateControl (id)
    Dim c As Object
    c = UI.GetControl(id)
    
    If c.type = UI.BUTTON Or c.type = UI.LABEL Then
        c.e.innerHTML = GXSTR_Replace(c.text, NL, "<br>")
    End If
    
    If c.type = UI.TEXTBOX Then
        If (c.multiline And c.e.nodeName = "INPUT") Or (Not c.multiline And c.e.nodeName = "TEXTAREA") Then
            Dim As Object oc, nc
            oc = c.e
            If c.multiline Then
                nc = Dom.Create("textarea")
                nc.style.resize = "none"
            Else
                nc = Dom.Create("input")
            End If                
            nc.draggable = oc.dragable
            nc.style.position = oc.style.position
            nc.style.left = oc.style.left
            nc.style.top = oc.style.top
            nc.style.border = oc.style.border
            nc.cid = oc.cid
            Dom.Add nc, oc.parentNode, oc
            c.e = nc
            Dom.Remove oc
            'MakeDraggable id
            UI.Event id, "mousedown", "OnMouseDown"
        End If
    End If
    
    If c.type = UI.TEXTBOX Then
        c.e.value = c.text
    End If

    If c.width Then c.e.style.width = c.width + "px" Else c.e.style.width = "auto"
    If c.height Then c.e.style.height = c.height + "px" Else c.e.style.height = "auto"
End Sub

Function Q (text As String)
    Q = Chr$(34) + text + Chr$(34)
End Function

Function Unquote (text As String)
    Unquote = Mid$(text, 2, Len(text) - 2)
End Function

Sub ListSplit (sourceString As String, results() As String)
    Dim cstr As String
    Dim As Long p, curpos, arrpos, dpos

    cstr = _Trim$(sourceString)

    ReDim As String results(0)

    Dim quoteMode As Integer
    Dim result As String
    Dim count As Integer
    Dim paren As Integer
    Dim i As Integer
    For i = 1 To Len(cstr)
        Dim c As String
        c = Mid$(cstr, i, 1)

        If c = Chr$(34) Then
            quoteMode = Not quoteMode
            result = result + c

        ElseIf quoteMode Then
            result = result + c

        ElseIf c = "(" Then
            paren = paren + 1
            result = result + c

        ElseIf c = ")" Then
            paren = paren - 1
            result = result + c

        ElseIf paren > 0 Then
            result = result + c

        ElseIf c = "," Then

            count = UBound(results) + 1
            ReDim _Preserve As String results(count)
            results(count) = result
            result = ""
        Else
            result = result + c
        End If

    Next i

    ' add the leftover last segment
    If result <> "" Then
        count = UBound(results) + 1
        ReDim _Preserve As String results(count)
        results(count) = result
    End If
End Sub

Function Replace$ (s As String, searchString As String, newString As String)
    Dim ns As String
    Dim i As Integer

    Dim slen As Integer
    slen = Len(searchString)

    For i = 1 To Len(s) '- slen + 1
        If Mid$(s, i, slen) = searchString Then
            ns = ns + newString
            i = i + slen - 1
        Else
            ns = ns + Mid$(s, i, 1)
        End If
    Next i

    Replace = ns
End Function

' Event Handlers
Sub OnPropChange (event)
    Dim As Integer id
    Dim As String ftype
    id = PGrid.GetValue("ID")
    ftype = PGrid.GetValue("Type")

    Dim As Object ctrl
    ctrl = UI.GetControl(id)
    ctrl.name = PGrid.GetValue("Name")
    ctrl.width = PGrid.GetValue("Width")
    ctrl.height = PGrid.GetValue("Height")

    If ftype = UI.PANEL Then
        Dim As String layout
        layout = PGrid.GetValue("Layout")
        If layout <> ctrl.layout Then
            If layout = UI.LAYOUT_FLOW Then
                UI.CSS id, "background-image", "none"
            Else
                UI.CSS id, "background-image", "url('" + DataUrl("img/grid-5.png") + "')"
            End If
                    
            Dim i As Integer
            For i = 1 To UI.ControlCount
                Dim cctrl As Object
                cctrl = UI.GetControl(i)
                If cctrl.parent = id Then
                    If layout = UI.LAYOUT_FLOW Then
                        UI.CSS i, "position", "static"
                    Else
                        UI.CSS i, "position", "absolute"
                    End If
                End If
            Next i
            ctrl.layout = layout
        End If
    Else
        ctrl.text = PGrid.GetValue("Text")
    End If
    
    If ftype = UI.TEXTBOX Then
        Dim mval As String
        mval = PGrid.GetValue("Multiline")
        If mval = "true" Then
            ctrl.multiline = True
        Else
            ctrl.multiline = False
        End If
    End If
    
    UI.SetEventHandler id, "Click", PGrid.GetValue("Click")
    UI.SetEventHandler id, "SetFocus", PGrid.GetValue("SetFocus")
    UpdateControl id
End Sub

Sub OnLoad
    FS.UploadFile "/tmp", ".frm", sub_OnLoadComplete
End Sub

Sub OnLoadComplete (filepath As String)
    Init

    Dim readEnabled As Integer
    Dim section As String
    ReDim parts(0) As String

    Open filepath For Input As #1
    While Not EOF(1)
        Dim s As String
        Line Input #1, s
        Print s
    
        If readEnabled Then
            If Mid$(s, 1, 1) = "'" Then
                section = Mid$(s, 3)
                Line Input #1, s ' throw away the count we don't need it here

            ElseIf s = "Data " + Chr$(34) + "webui_end" + Chr$(34) Then
                readEnabled = 0
            
            ElseIf section = "Controls" Then
                ListSplit s, parts()
                Dim As String ctype, cname, layout, text, x, y, cwidth, cheight
                Dim As Integer parentId, multiline, cid
                cid = Val(Mid$(parts(1), 6))
                ctype = Unquote(parts(2))
                cname = Unquote(parts(3))
                parentId = Val(parts(4))
                layout = Unquote(parts(5))
                text = Replace(Unquote(parts(6)), "\n", NL)
                multiline = Val(parts(7))
                x = Unquote(parts(8))
                y = Unquote(parts(9))
                cwidth = Unquote(parts(10))
                cheight = Unquote(parts(11))
                'Print ctype, cname, parentId, layout, text
                Dim c As Integer
                If ctype = "panel" Then
                    If cid = 1 Then
                        c = 1
                    Else
                        c = UI.CreatePanel(layout, parentId)
                    End If
                ElseIf ctype = "label" Then
                    c = UI.CreateLabel(parentId, text)
                ElseIf ctype = "textbox" Then
                    c = UI.CreateTextbox(parentId, multiline)
                ElseIf ctype = "button" Then
                    c = UI.CreateButton(parentId, text)
                End If
                If cname <> "" Then
                    UI.SetName c, cname
                End If
                If x <> "" And y <> "" Then
                    UI.SetPos c, x, y
                End If
                If cwidth <> "" Then UI.SetWidth c, cwidth
                If cheight <> "" Then UI.SetHeight c, cheight
            
            ElseIf section = "Events" Then
                Console.Echo s
                Dim As Integer cid
                Dim As String event, method
                ListSplit s, parts()
                cid = Val(Mid$(parts(1), 6))
                event = Unquote(parts(2))
                method = Unquote(parts(3))
                If event <> "" And method <> "" Then
                    UI.SetEventHandler cid, event, method
                End If
            End If
        End If

        If Mid$(s, 1, 6) = "webui_" Then
            readEnabled = -1
        End If    
    Wend
    Close #1
End Sub

Sub OnSaveForm
    Save False
End Sub

Sub OnSaveProject
    Save True
End Sub

Sub Save (project As Integer)
    MkDir "tmp"
    Open "tmp/program.frm" For Output As #1
    Print #1, UI.ExportUI
    Close #1
    
    If project Then
        Open "tmp/main.bas" For Output As #1
        Print #1, "Import Dom From " + Q("lib/web/dom.bas")
        Print #1, "Import Console From " + Q("lib/web/console.bas")
        Print #1, "Import UI From " + Q("webui.bas")
        Print #1, "Import Form From " + Q("program.frm")
        Print #1, ""
        Print #1, "' TODO: Your code here."
        ReDim events(0) As Object
        UI.GetEvents events()
        If UBound(events) > 0 Then
            Print #1, NL
            Print #1, "' Event Handlers"
            Print #1, "' ------------------------------------------------------------"
            Dim i As Integer
            For i = 1 To UBound(events)
                Print #1, ""
                Print #1, "Sub "; events(i).method;
                Print #1, "    ' TODO: event logic here"
                Print #1, "    Console.Log " + Q(events(i).method)
                Print #1, "End Sub"
            Next i
        End If    
        Close #1


        Open "webui.bas" For Input As #1
        Open "tmp/webui.bas" For Output As #2
        Dim As String s, text
        While Not EOF(1)
            Line Input #1, text
            Print #2, text
        Wend
        Close #1
        Close #2
        ZipProject
    Else
        FS.DownloadFile "tmp/program.frm"
    End If
End Sub


Sub OnDragEnter(event)
    PreventDefault event
End Sub

Sub OnDragOver(event)
    PreventDefault event
    event.dataTransfer.dropEffect = "move"
End Sub

Sub OnDragStart(event)
    event.dataTransfer.effectAllowed = "copyMove"
    msx = event.pageX
    msy = event.pageY
    osx = event.offsetX
    osy = event.offsetY
End Sub

Sub OnTypeDragStart(event)
    dragType = event.target.ftype
End Sub

Sub OnDragEnd(event)
Console.Echo selected
    If Not selected Then Exit Sub
    Dim dx, dy
    dx = event.pageX - msx
    dy = event.pageY - msy
    
    Dim cx, cy
    cx = GXSTR_Replace(event.target.style.left, "px", "") * 1
    cy = GXSTR_Replace(event.target.style.top, "px", "") * 1
    UI.SetPos selected, Round((cx + dx)/5)*5, Round((cy + dy)/5)*5
    StopPropagation event
    SelectControl selected
End Sub

Sub OnDrop(event)
'If Not dragType Then Exit Sub
    Dim As Object rect
    rect = GetBoundingClientRect(event.target)

    Dim As Integer x, y, cid
    x = Round(event.clientX - rect.left)
    y = Round(event.clientY - rect.top)

    If (dragType) Then
        ' do nothing
    Else
'        If event.target.cid Then
'            cid = event.target.cid
'            If controls(cid).type <> PANEL Then cid = GetParentId(cid)
'            
'            If selected And cid Then
'                rect = GetBoundingClientRect(controls(cid).e)
'                x = Round(event.clientX - rect.left)
'                y = Round(event.clientY - rect.top)
'
'                If controls(selected).e <> controls(cid).e Then
'                    If cid <> event.target.cid And controls(cid).layout <> LAYOUT_FIXED Then
'                        ' insert before the selected element
'                        Dom.Add controls(selected).e, controls(cid).e, controls(event.target.cid).e
'                    Else
'                        Dom.Add controls(selected).e, controls(cid).e
'                    End If
'                    controls(selected).parent = cid
'                    SetPos selected, x - osx, y - osy
'                    
'                    Dim e As Object
'                    e = controls(selected).e
'                    e.style.border = sstyle.border
'                    e.style.boxShadow = sstyle.boxShadow
'                    
'                    If controls(cid).layout = LAYOUT_FLOW Then
'                        CSS selected, "position", "static"
'                    Else
'                        CSS selected, "position", "absolute"
'                    End If
'
'                    ' de-select
'                    selected = undefined
'                    StopPropagation event
'                End If
'            End If
'        End If
        Exit Sub
    End If

    Dim As Integer ctrl, cid
    cid = event.target.cid
    Console.Log "cid: " + cid
    If cid Then
        Console.Log dragType
        If dragType = UI.LABEL Then
            ctrl = UI.CreateLabel(cid, "New Label")
            
        ElseIf dragType = UI.TEXTBOX Then
            ctrl = UI.CreateTextBox(cid)
            
        ElseIf dragType = UI.BUTTON Then
            ctrl = UI.CreateButton(cid, "New Button")
            
        ElseIf dragType = UI.PANEL Then
            'ctrl = UI.CreatePanel(LAYOUT_FIXED, cid)
            ctrl = UI.CreatePanel(UI.LAYOUT_FLOW, cid)
            'controls(ctrl).width = 200
            'controls(ctrl).height = 200
            'UI.CSS ctrl, "width", "200px"
            'UI.CSS ctrl, "height", "200px"
            UI.SetWidth ctrl, 200
            UI.SetHeight ctrl, 200
            UI.CSS ctrl, "border", "1px solid #ccc"
        End If
        
        Dim parent As Object
        parent = UI.GetControl(cid)
        Console.Log parent.layout
        If parent.layout = UI.LAYOUT_FLOW Then
            UI.CSS ctrl, "position", "static"
        Else
            UI.CSS ctrl, "position", "absolute"
        End If
        UI.SetPos ctrl, x, y
        SelectControl ctrl
    End If
    
    dragType = undefined
End Sub

Sub OnMouseMove(event)
    Dim As Object ctrl

    If resizing Then
        Dim As Integer w, h
        w = event.pageX - rsize.sx
        h = event.pageY - rsize.sy
        If w < 10 then w = 10
        If h < 10 Then h = 10
        ctrl = UI.GetControl(selected)
        ctrl.width = Round(w/5) * 5
        ctrl.height = Round(h/5) * 5
        UpdateControl selected
   
    ElseIf moving Then
        'If event.target = controls(selected).e Then
            'PreventDefault event
            'StopPropagation event
         '   Exit Sub
        'End If
        'Console.Log event.offsetX + ", " + event.offsetY
        Dim dx, dy
        dx = event.pageX - msx
        dy = event.pageY - msy
        msx = event.pageX
        msy = event.pageY
    
        Dim cx, cy
        ctrl = UI.GetControl(selected)
        'cx = GXSTR_Replace(event.target.style.left, "px", "") * 1
        'cy = GXSTR_Replace(event.target.style.top, "px", "") * 1
        cx = GXSTR_Replace(ctrl.e.style.left, "px", "") * 1
        cy = GXSTR_Replace(ctrl.e.style.top, "px", "") * 1
        'SetPos selected, Round((cx + dx)/5)*5, Round((cy + dy)/5)*5
        UI.SetPos selected, cx + dx, cy + dy, True
        PreventDefault event
        StopPropagation event
    Else
        Dim As Object rect
        rect = GetBoundingClientRect(event.target)
        If rect.width - event.offsetX <= 8 And rect.height - event.offsetY <= 8 Then
            event.target.style.cursor = "nwse-resize"
        Else
            event.target.style.cursor = "default"
        End If
    End If
End Sub

Sub OnMouseDown(event)
    Dim cid As Integer
    cid = event.target.cid
    'Console.Log cid
    'Console.Log controls(cid).parent
    SelectControl event.target.cid
    
    Dim As Object rect
    rect = GetBoundingClientRect(event.target)
    If rect.width - event.offsetX <= 8 And rect.height - event.offsetY <= 8 Then
        resizing = True
        rsize.sx = event.pageX - rect.width
        rsize.sy = event.pageY - rect.height
        'controls(event.target.cid).e.draggable = false
        PreventDefault event
    Else
        Dim ctrl As Object
        ctrl = UI.GetControl(event.target.cid)
        If ctrl.parent Then
            moving = True
            msx = event.pageX
            msy = event.pageY
            msz = event.target.style.zIndex
            event.target.style.zIndex = "1000"
            event.target.style.position = "absolute"
        End If
    End If
End Sub

Sub OnMouseUp(event)
    If moving Then
        'snap to grid
        Dim cx, cy, pid
        Dim As Object ctrl
        ctrl = UI.GetControl(selected)
        cx = GXSTR_Replace(ctrl.e.style.left, "px", "") * 1
        cy = GXSTR_Replace(ctrl.e.style.top, "px", "") * 1
        pid = GetDropTarget(event)
        'Console.Log pid + " - " + controls(pid).type
        If pid <> ctrl.parent Then
        End If
        UI.SetPos selected, cx, cy
        ctrl.e.style.zIndex = msz
    End if
    resizing = False
    moving = False
    If selected Then 
        'controls(selected).e.draggable = true
        SelectControl selected
    End If
End Sub


Function GetBoundingClientRect(element)
$If Javascript Then
    GetBoundingClientRect = element.getBoundingClientRect();
$End If
End Function

Function DataURL(filepath As String)
    $If Javascript Then
        var vfs = GX.vfs();
        var file = vfs.getNode(filepath, vfs.rootDirectory());
        if (file) {
            DataURL = vfs.getDataURL(file);
        }
        else {
            DataURL = filepath;
        }
    $End If
End Function

Sub PreventDefault(event)
$If Javascript Then
    event.preventDefault();
$End If
End Sub

Sub StopPropagation(event)
$If Javascript Then
    event.stopPropagation();
$End If
End Sub


Function GetDropTarget(event)
    Dim As Integer pid, tid
    $If Javascript Then
        var elements = document.elementsFromPoint(event.clientX, event.clientY);
        for (var i=0; i < elements.length && pid < 1; i++) {
            if (elements[i].cid && elements[i].cid != selected) {
                pid = elements[i].cid;
            }
        }
    $End If
    GetDropTarget = pid
End Function

Sub ZipProject
$If Javascript Then
    var vfs = QB.vfs();
    var node = vfs.getNode("/tmp");
    var zip = new JSZip();

    var files = vfs.getChildren(node, vfs.FILE);
    for (var i=0; i < files.length; i++) {
        var f = files[i];
        var path = f.name; //vfs.fullPath(f).substring(1);
        zip.file(path, f.data);
    }

    zip.generateAsync({type:"blob",compression:"DEFLATE"}).then(function(content) {
        QB.downloadFile(content, "project.zip");
    });

$End If
End Sub