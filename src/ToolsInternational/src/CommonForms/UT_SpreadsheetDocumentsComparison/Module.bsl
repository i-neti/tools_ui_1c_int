///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
// Translated by Neti Company
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SpreadsheetDocumentsToCompare = GetFromTempStorage(Parameters.SpreadsheetDocumentsAddress);
	SpreadsheetDocumentLeft = PrepareSpreadsheetDocument(SpreadsheetDocumentsToCompare.Left);
	SpreadsheetDocumentRight = PrepareSpreadsheetDocument(SpreadsheetDocumentsToCompare.Right);
	
	Items.LeftSpreadsheetDocumentGroup.Title = Parameters.TitleLeft;
	Items.RightSpreadsheetDocumentGroup.Title = Parameters.TitleRight;
	
	CompareAtServer();
	
EndProcedure

#EndRegion

#Region SpreadsheetDocumentLeftFormTableItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentLeftOnActivateArea(Item)
	
	If DisableOnActivateHandler = True Then
		Return;
	EndIf;
	
	Source = New Structure("Object, Item", SpreadsheetDocumentLeft, Items.SpreadsheetDocumentLeft);
	Destination = New Structure("Object, Item", SpreadsheetDocumentRight, Items.SpreadsheetDocumentRight);
	
	MatchesSource = New Structure("Rows, Columns", RowsMapLeft, ColumnsMapLeft);
	MatchesDestination = New Structure("Rows, Columns", RowsMapRight, ColumnsMapRight);
	
	ProcessAreaActivation(Source, Destination, MatchesSource, MatchesDestination);
	
EndProcedure

#EndRegion

#Region SpreadsheetDocumentRightFormTableItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentRightOnActivateArea(Item)
	
	If DisableOnActivateHandler = True Then
		Return;
	EndIf;
		
	Source = New Structure("Object, Item", SpreadsheetDocumentRight, Items.SpreadsheetDocumentRight);
	Destination = New Structure("Object, Item", SpreadsheetDocumentLeft, Items.SpreadsheetDocumentLeft);
	
	MatchesSource = New Structure("Rows, Columns", RowsMapRight, ColumnsMapRight);
	MatchesDestination = New Structure("Rows, Columns", RowsMapLeft, ColumnsMapLeft);
	
	ProcessAreaActivation(Source, Destination, MatchesSource, MatchesDestination);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PreviousChangeLeftCommand(Command)
	
	PreviousChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure

&AtClient
Procedure PreviousChangeRightCommand(Command)
	
	PreviousChange(Items.SpreadsheetDocumentRight, SpreadsheetDocumentRight, CellDifferencesRight);
	
EndProcedure

&AtClient
Procedure NextChangeLeftCommand(Command)
	
	NextChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure

&AtClient
Procedure NextChangeRightCommand(Command)
	
	NextChange(Items.SpreadsheetDocumentRight, SpreadsheetDocumentRight, CellDifferencesRight);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CompareAtServer()

	DisableOnActivateHandler = True;
			
	RowsMapLeft = New ValueList;
	RowsMapRight = New ValueList;
	
	ColumnsMapLeft = New ValueList;
	ColumnsMapRight = New ValueList;
	
	CellDifferencesLeft.Clear();
	CellDifferencesRight.Clear();
	
	Compare();
	
	DisableOnActivateHandler = False;
	
EndProcedure	

&AtServer
Procedure Compare()
	
	#Region Comparison
	
	// Exporting text from spreadsheet document cells to the value tables.
	LeftDocumentTable = ReadSpreadsheetDocument(SpreadsheetDocumentLeft);
	RightDocumentTable = ReadSpreadsheetDocument(SpreadsheetDocumentRight);
	
	// Comparing the spreadsheet documents by rows and selecting the matching rows.
	Matches = GenerateMatches(LeftDocumentTable, RightDocumentTable, True);
	RowsMapLeft = Matches[0];
	RowsMapRight = Matches[1];
	
	// Comparing the spreadsheet documents by columns and selecting the matching columns.
	Matches = GenerateMatches(LeftDocumentTable, RightDocumentTable, False);
	ColumnsMapLeft = Matches[0];
	ColumnsMapRight = Matches[1];
	
	LeftDocumentTable = Undefined;
	RightDocumentTable = Undefined;
	
	#EndRegion
	
	#Region DifferencesView
	
	DeletedAreaColorBackground		= WebColors.LightPink;
	//@skip-check new-color
	AddedAreaColorBackground	= New Color(204, 255, 204);
	ChangedAreaColorBackground	= WebColors.LightCyan;
	ChangedAreaColorText	= WebColors.Blue;
		
	
	LeftTableHeight = SpreadsheetDocumentLeft.TableHeight;
	LeftTableWidth = SpreadsheetDocumentLeft.TableWidth;
	
	RightTableHeight = SpreadsheetDocumentRight.TableHeight;
	RightTableWidth = SpreadsheetDocumentRight.TableWidth;

	// Rows that were deleted from the left spreadsheet document.
	For RowNumber = 1 To RowsMapLeft.Count()-1 Do
		
		If RowsMapLeft[RowNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentLeft.Area(RowNumber, 1, RowNumber, LeftTableWidth);
			Area.BackColor = DeletedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesLeft.Add();
			NewDifferenceRow.RowNumber = RowNumber;
			NewDifferenceRow.ColumnNumber = 0;
			
		EndIf;
		
	EndDo;
	
	// Columns that were deleted from the left spreadsheet document.
	For ColumnNumber = 1 To ColumnsMapLeft.Count()-1 Do
		
		If ColumnsMapLeft[ColumnNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentLeft.Area(1, ColumnNumber, LeftTableHeight, ColumnNumber);
			Area.BackColor = DeletedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesLeft.Add();
			NewDifferenceRow.RowNumber = 0;
			NewDifferenceRow.ColumnNumber = ColumnNumber;
			
		EndIf;
		
	EndDo;
	
	// Rows that were added to the right spreadsheet document.
	For RowNumber = 1 To RowsMapRight.Count()-1 Do
		
		If RowsMapRight[RowNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentRight.Area(RowNumber, 1, RowNumber, RightTableWidth);
			Area.BackColor = AddedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesRight.Add();
			NewDifferenceRow.RowNumber = RowNumber;
			NewDifferenceRow.ColumnNumber = 0;
			
		EndIf;
		
	EndDo;
	
	// Columns that were added to the right spreadsheet document.
	For ColumnNumber = 1 To ColumnsMapRight.Count()-1 Do
		
		If ColumnsMapRight[ColumnNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentRight.Area(1, ColumnNumber, RightTableHeight, ColumnNumber);
			Area.BackColor = AddedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesRight.Add();
			NewDifferenceRow.RowNumber = 0;
			NewDifferenceRow.ColumnNumber = ColumnNumber;
			
		EndIf;
		
	EndDo;
	
	// Cells that were modified.
	For RowNumber1 = 1 To RowsMapLeft.Count()-1 Do
		
		RowNumber2 = RowsMapLeft[RowNumber1].Value;
		If RowNumber2 = Undefined Then
			Continue;
		EndIf;
		
		For ColumnNumber1 = 1 To ColumnsMapLeft.Count()-1 Do
			
			ColumnNumber2 = ColumnsMapLeft[ColumnNumber1].Value;
			If ColumnNumber2 = Undefined Then
				Continue;
			EndIf;
			
			Area1 = SpreadsheetDocumentLeft.Area(RowNumber1, ColumnNumber1, RowNumber1, ColumnNumber1);
			Area2 = SpreadsheetDocumentRight.Area(RowNumber2, ColumnNumber2, RowNumber2, ColumnNumber2);
			
			If Not CompareAreas(Area1, Area2) Then
				
				Area1 = SpreadsheetDocumentLeft.Area(RowNumber1, ColumnNumber1);
				Area2 = SpreadsheetDocumentRight.Area(RowNumber2, ColumnNumber2);
				
				Area1.TextColor = ChangedAreaColorText;
				Area2.TextColor = ChangedAreaColorText;
				
				Area1.BackColor = ChangedAreaColorBackground;
				Area2.BackColor = ChangedAreaColorBackground;
				
				
				NewDifferenceRow = CellDifferencesLeft.Add();
				NewDifferenceRow.RowNumber = RowNumber1;
				NewDifferenceRow.ColumnNumber = ColumnNumber1;
				
				NewDifferenceRow = CellDifferencesRight.Add();
				NewDifferenceRow.RowNumber = RowNumber2;
				NewDifferenceRow.ColumnNumber = ColumnNumber2;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	CellDifferencesLeft.Sort("RowNumber, ColumnNumber");
	CellDifferencesRight.Sort("RowNumber, ColumnNumber");
	
	#EndRegion
	
EndProcedure

&AtServer
Function CompareAreas(Area1, Area2)
	
	If Area1.Text <> Area2.Text Then
		Return False;
	EndIf;
	
	If Area1.Comment.Text <> Area2.Comment.Text Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function ReadSpreadsheetDocument(SourceSpreadsheetDocument)
	
	ColumnsCount = SourceSpreadsheetDocument.TableWidth;
	
	If ColumnsCount = 0 Then
		Return New ValueTable;
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	For ColumnNumber = 1 To ColumnsCount Do
		SpreadsheetDocument.Area(1, ColumnNumber, 1, ColumnNumber).Text = NStr("ru = 'Номер_'; en = 'Number_'") + Format(ColumnNumber,"NG=0");
	EndDo;
	
	SpreadsheetDocument.Put(SourceSpreadsheetDocument);
	
	Builder = New QueryBuilder;
	
	Builder.DataSource = New DataSourceDescription(SpreadsheetDocument.Area());
	Builder.Execute();
	ValueTableResult = Builder.Result.Unload();
	
	Return ValueTableResult;
	
EndFunction

&AtServer
Function GenerateMatches(LeftTable, RightTable, ByRows)
	
	DataFromLeftTable = GetDataForComparison(LeftTable, ByRows);
	
	DataFromRightTable = GetDataForComparison(RightTable, ByRows);
	
	If ByRows Then
		MatchResultLeft = New ValueList;
		MatchResultLeft.LoadValues(New Array(LeftTable.Count()+1));
		
		MatchResultRight = New ValueList;
		MatchResultRight.LoadValues(New Array(RightTable.Count()+1));		
		
	Else
		MatchResultLeft = New ValueList;
		MatchResultLeft.LoadValues(New Array(LeftTable.Columns.Count()+1));
		
		MatchResultRight = New ValueList;
		MatchResultRight.LoadValues(New Array(RightTable.Columns.Count()+1));
		
	EndIf;
	
	QueryText = "";
	
	QueryText = QueryText + "	SELECT * INTO LeftTable 
								|	FROM &DataFromLeftTable AS DataFromLeftTable;" + Chars.LF;
								
	QueryText = QueryText + "	SELECT * INTO RightTable
								|	FROM &DataFromRightTable AS DataFromRightTable;" + Chars.LF;
		
	QueryText = QueryText + "SELECT
		|	LeftTable.Number AS ItemNumberLeft,
		|	RightTable.Number AS ItemNumberRight,
		|	CASE
		|		WHEN RightTable.Number - LeftTable.Number < 0
		|			THEN LeftTable.Number - RightTable.Number
		|		ELSE RightTable.Number - LeftTable.Number
		|	END AS DistanceFromBeginning,
		|	CASE
		|		WHEN &RowCountRight - RightTable.Number - (&RowCountLeft - LeftTable.Number) < 0
		|			THEN &RowCountLeft - LeftTable.Number - (&RowCountRight - RightTable.Number)
		|		ELSE  &RowCountRight - RightTable.Number - (&RowCountLeft - LeftTable.Number)
		|	END AS DistanceFromEnd,
		|	SUM(CASE
		|			WHEN LeftTable.Value <> """"
		|				THEN CASE
		|						WHEN LeftTable.Count < RightTable.Count
		|							THEN LeftTable.Count
		|						ELSE RightTable.Count
		|					END
		|			ELSE 0
		|		END) AS ValueMatchesCount,
		|	SUM(CASE
		|			WHEN LeftTable.Count < RightTable.Count
		|				THEN LeftTable.Count
		|			ELSE RightTable.Count
		|		END) AS TotalMatchesCount
		|INTO DataCollapsed
		|FROM
		|	LeftTable AS LeftTable
		|		INNER JOIN RightTable AS RightTable
		|		ON LeftTable.Value = RightTable.Value
		|
		|GROUP BY
		|	LeftTable.Number,
		|	RightTable.Number
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataCollapsed.ItemNumberLeft AS ItemNumberLeft,
		|	DataCollapsed.ItemNumberRight AS ItemNumberRight,
		|	DataCollapsed.ValueMatchesCount AS ValueMatchesCount,
		|	DataCollapsed.TotalMatchesCount AS TotalMatchesCount,
		|	CASE
		|		WHEN DataCollapsed.DistanceFromBeginning < DataCollapsed.DistanceFromEnd
		|			THEN DataCollapsed.DistanceFromBeginning
		|		ELSE DataCollapsed.DistanceFromEnd
		|	END AS MinDistance
		|FROM
		|	DataCollapsed AS DataCollapsed
		|
		|ORDER BY
		|	ValueMatchesCount DESC,
		|	TotalMatchesCount DESC,
		|	MinDistance,
		|	ItemNumberLeft,
		|	ItemNumberRight";

	Query = New Query(QueryText);
	Query.SetParameter("DataFromLeftTable", DataFromLeftTable);
	Query.SetParameter("DataFromRightTable", DataFromRightTable);
	Query.SetParameter("RowCountLeft", LeftTable.Count());
	Query.SetParameter("RowCountRight", RightTable.Count());
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If MatchResultLeft[Selection.ItemNumberLeft].Value = Undefined
			AND MatchResultRight[Selection.ItemNumberRight].Value = Undefined Then
				MatchResultLeft[Selection.ItemNumberLeft].Value = Selection.ItemNumberRight;
				MatchResultRight[Selection.ItemNumberRight].Value = Selection.ItemNumberLeft;
		EndIf;
	EndDo;
	
	Result = New Array;
	Result.Add(MatchResultLeft);
	Result.Add(MatchResultRight);
	
	Return Result;

EndFunction

&AtServer
Function GetDataForComparison(SourceValueTable, ByRows)
	
	MaxRowSize = New StringQualifiers(100);
	
	Result = New ValueTable;
	Result.Columns.Add("Number",		New TypeDescription("Number"));
	Result.Columns.Add("Value",	New TypeDescription("String", , MaxRowSize));
	
	Boundary1 = ?(ByRows, SourceValueTable.Count(),
							SourceValueTable.Columns.Count()) - 1;
		
	Boundary2 = ?(ByRows, SourceValueTable.Columns.Count(),
							SourceValueTable.Count()) - 1;
		
	For Index1 = 0 To Boundary1 Do
		
		For Index2 = 0 To Boundary2 Do
			
			NewRow = Result.Add();
			NewRow.Number = Index1+1;
			NewRow.Value = ?(ByRows, SourceValueTable[Index1][Index2],
												SourceValueTable[Index2][Index1]);
			
		EndDo;
		
	EndDo;

	Result.Columns.Add("Count", New TypeDescription("Number"));
	Result.FillValues(1, "Count");
	
	Result.GroupBy("Number, Value", "Count");
	
	Return Result;
		
EndFunction


&AtClient
Procedure ProcessAreaActivation(SourceSpreadDoc, DestinationSpreadDoc, MatchesSource, MatchesDestination)
	
	DisableOnActivateHandler = True;
	
	CurArea = SourceSpreadDoc.Item.CurrentArea;
	
	If CurArea.AreaType = SpreadsheetDocumentCellAreaType.Table Then
		
		SelectedArea = DestinationSpreadDoc.Area();
		
	Else
	
		If CurArea.Bottom < MatchesSource.Rows.Count() Then
			RowNumber = MatchesSource.Rows[CurArea.Bottom].Value;
		Else
			RowNumber = CurArea.Bottom 
							- MatchesSource.Rows.Count()
								+ MatchesDestination.Rows.Count();
		EndIf;
		
		If CurArea.Left < MatchesSource.Columns.Count() Then
			ColumnNumber = MatchesSource.Columns[CurArea.Left].Value;
		Else
			ColumnNumber = CurArea.Left
							- MatchesSource.Columns.Count()
								+ MatchesDestination.Columns.Count();
		EndIf;
		
		
		SelectedArea = Undefined;
		
		If CurArea.AreaType = SpreadsheetDocumentCellAreaType.Rectangle Then
					
			If RowNumber <> Undefined And ColumnNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(RowNumber, ColumnNumber);
			EndIf;
					
		ElsIf CurArea.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			If RowNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(RowNumber, 0, RowNumber, 0);
			EndIf;
			
		ElsIf CurArea.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			
			If ColumnNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(0, ColumnNumber, 0, ColumnNumber);
			EndIf;
			
		Else		
			
			Return;
			
		EndIf;
		
	EndIf;
	
	DestinationSpreadDoc.Item.CurrentArea = SelectedArea;
	
	DisableOnActivateHandler = False;
	
EndProcedure

&AtClient
Procedure PreviousChange(FormItem, FormAttribute, DifferenceTable)
	
	Var Index;
	
	CurCell = FormItem.CurrentArea;
	RowNumber = CurCell.Top;
	ColumnNumber = CurCell.Left;
	For Each curRow In DifferenceTable Do
		If curRow.RowNumber < RowNumber 
			Or curRow.RowNumber = RowNumber And curRow.ColumnNumber < ColumnNumber Then
			Index = DifferenceTable.IndexOf(curRow);
		ElsIf curRow.RowNumber >= RowNumber And curRow.ColumnNumber > ColumnNumber Then
			Break;
		EndIf;
	EndDo;
	
	If Index <> Undefined Then
		DifferenceRow = DifferenceTable[Index];
		RowNumber = DifferenceRow.RowNumber;
		ColumnNumber = DifferenceRow.ColumnNumber;
		FormItem.CurrentArea = FormAttribute.Area(RowNumber, ColumnNumber, RowNumber, ColumnNumber);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure NextChange(FormItem, FormAttribute, DifferenceTable)
	
	Var Index;
	
	CurCell = FormItem.CurrentArea;
	RowNumber = CurCell.Top;
	ColumnNumber = CurCell.Left;
	For Each curRow In DifferenceTable Do
		If curRow.RowNumber = RowNumber And curRow.ColumnNumber > ColumnNumber 
			Or curRow.RowNumber > RowNumber Then
			Index = DifferenceTable.IndexOf(curRow);
			Break;
		EndIf;
	EndDo;
	
	If Index <> Undefined Then
		DifferenceRow = DifferenceTable[Index];
		RowNumber = DifferenceRow.RowNumber;
		ColumnNumber = DifferenceRow.ColumnNumber;
		FormItem.CurrentArea = FormAttribute.Area(RowNumber, ColumnNumber, RowNumber, ColumnNumber);
	EndIf;

EndProcedure

&AtServer
Function PrepareSpreadsheetDocument(SpreadsheetDocument)
	
	If TypeOf(SpreadsheetDocument) = Type("SpreadsheetDocument") Then
		Return SpreadsheetDocument;
	EndIf;
	
	BinaryData = GetFromTempStorage(SpreadsheetDocument); 
	If TypeOf(BinaryData) = Type("SpreadsheetDocument") Then
		Return BinaryData;
	EndIf;
	TempFileName = GetTempFileName("mxl");
	BinaryData.Write(TempFileName);
	
	Result = New SpreadsheetDocument;
	Result.Read(TempFileName);
	
	DeleteFiles(TempFileName);
	
	Return Result;

EndFunction

#EndRegion