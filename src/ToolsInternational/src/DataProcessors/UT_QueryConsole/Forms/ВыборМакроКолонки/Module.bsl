#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	QueryColumn = Parameters.QueryColumn;
	ColumnType = "UUID";
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	GenerateTextToInsert();
EndProcedure

#EndRegion

#Region FormItemsEventHandlers
&AtClient
Procedure ColumnTypeOnChange(Item)
	GenerateTextToInsert();
EndProcedure

&AtClient
Procedure QueryColumnOnChange(Item)
	GenerateTextToInsert();
EndProcedure

#EndRegion


#Region FormCommandHandlers

&AtClient
Procedure Insert(Command)
	Close(TextToInsert);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateTextToInsert()
	TextToInsert = "";
	If ColumnType = "UUID" Then
		TextToInsert="&__UUID_"+QueryColumn;
	ElsIf ColumnType = "CreationDate" Then
		TextToInsert="&__CreationDate_"+QueryColumn;
	EndIf;
EndProcedure

#EndRegion

