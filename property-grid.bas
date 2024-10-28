Export CreatePropertyGrid, AddProp, AddHeader, GetPropCount, GetPropName, GetValue, RemoveAll As Clear

Const True = -1
Const False = 0

Dim Shared As Object grid, activeCell, activeEdit, valueMap
ReDim Shared As String properties(0)

Sub OnChange (event As Object)
    Dom.Alert event.name + " : " + event.value
End Sub

Function CreatePropertyGrid (parent)
    grid = Dom.Create("div", parent)
    CSS grid, "display", "grid"
    CSS grid, "grid-template-columns", "1fr 3fr" 
    CreatePropertyGrid = grid
End Function

Sub AddHeader (name As String)
	Dim cell As Object
	cell = AddCell(name)
	cell.style.fontWeight = "bold"
	cell.style.borderRight = "0"
	cell = AddCell("")
	cell.style.borderLeft = "0"
End Sub

Sub AddProp (name As String, value As String, readOnly As Integer, optList() As String, multiline As Integer)
    Dim cell As Object
    cell = AddCell(name)
    cell = AddCell(value)
    cell.vname = name
    cell.multiline = multiline
    If optList <> undefined Then
        cell.optList = MakeSelect(optList())
    End If
    cell.style.backgroundColor = "#fff"
    If Not readOnly Then
        Dom.Event cell, "click", sub_OnEditCell
    Else
        cell.style.color = "#666"
    End If

    SetValue name, value
    Dim i As Integer
    i = UBound(properties) + 1
    ReDim Preserve properties(i) As String
    properties(i) = name
End Sub

Function MakeSelect(optList() As String)
    Dim i As Integer
    Dim html As String
    For i = 1 To UBound(optList)
        html = html + "<option value=" + Chr$(34) + optList(i) + Chr$(34) + ">" + optList(i) + "</option>"
    Next i
    Dim obj As Object
    obj = Dom.Create("select")
    obj.innerHTML = html
    Dom.Remove obj
    MakeSelect = obj
End Function

Function AddCell (text As String)
    Dim cell As Object
    cell = Dom.Create("div", grid, text)
    cell.style.padding = "4px"
    cell.style.border = "1px solid #ccc"
    AddCell = cell
End Function

Sub OnEditBlur(event)
    Dim e As Object: e = event.target
    activeCell.innerHTML = activeEdit.value
    Dom.Add activeCell, e.parentNode, e
    Dom.Remove activeEdit

    Dim oldValue As String
    oldValue = GetValue(activeCell.vname)
    
    If activeEdit.value <> oldValue Then
        'set the value in the underlying model
        SetValue activeCell.vname, activeEdit.value
    
        'fire the change event
        FireEvent "propchange", activeCell.vname, activeEdit.value
    End If
End Sub

Sub OnEditCell(event)
    Dim e As Object: e = event.target
    If e.optList Then
        activeEdit = e.optList
        activeEdit.value = e.innerHTML
        Dom.Add e.optList, e.parentNode, e
    ElseIf e.multiline Then
		activeEdit = Dom.Create("textarea", e.parentNode, e.innerHTML, , e)
		activeEdit.style.height = "75px"
	Else
		activeEdit = Dom.Create("input", e.parentNode, e.innerHTML, , e)
    End If
    Dom.Event activeEdit, "blur", sub_OnEditBlur
    activeCell = e
    Dom.Remove e
    $If Javascript Then
        activeEdit.focus();
    $End If
End Sub

Function GetPropCount
    GetPropCount = UBound(properties)
End Function

Function GetPropName(i As Integer)
    GetPropName = properties(i)
End Function

Function GetValue (name As String)
    $If Javascript Then
        GetValue = valueMap[name];
    $End If
End Function

Sub SetValue(name As String, value As String)
    $If Javascript Then
        valueMap[name] = value;
    $End If
End Sub

Sub CSS (e As Object, name As String, value As String)
    $If Javascript Then
        e.style[name] = value;
    $End If
End Sub

Sub FireEvent(etype As String, name As String, value As String)
    $If Javascript Then
        var e = new Event(etype);
        e.name = name;
        e.value = value;
        grid.dispatchEvent(e);
    $End If
End Sub


Sub RemoveAll
	$If Javascript Then
		if (grid.replaceChildren) { grid.replaceChildren(); }
	$End If
End Sub