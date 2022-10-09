&AtClient
Procedure RunDebug(Command)
	CurrentData=Items.SavedSettingsTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CommonClient.RunDebugConsoleByDebugDataSettingsKey(CurrentData.SettingsKey);

EndProcedure

&AtClient
Procedure RefreshTable(Command)
	RefreshTableAtServer();
EndProcedure

&AtServer
Procedure RefreshTableAtServer()
	SavedSettingsTable.Clear();

	SearchStructure=New Structure;
	SearchStructure.Insert("ObjectKey", SettingsObjectKey);

	Selection=SystemSettingsStorage.Select(SearchStructure);

	While Selection.Next() Do
		NewRow=SavedSettingsTable.Add();
		NewRow.SettingsKey=Selection.SettingsKey;
		NewRow.User=Selection.User;

		SettingsKeyArray=StrSplit(NewRow.SettingsKey, "/");

		NewRow.Author=SettingsKeyArray[1];
		NewRow.DebuggingObjectType=SettingsKeyArray[0];
		Try
			NewRow.CreationDate=Date(SettingsKeyArray[2]);
		Except
			NewRow.CreationDate="";
		EndTry;

	EndDo;

	SavedSettingsTable.Sort("CreationDate Desc");
EndProcedure

&AtClient
Procedure Delete(Command)

	SelectedRows = Items.SavedSettingsTable.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	Endif;

	DeleteSelectedRows(SelectedRows);

EndProcedure

&AtServer
Procedure DeleteSelectedRows(Val SelectedRows)

	For each SelectedRow in SelectedRows do
		DeleteAtServer(SelectedRow);
	enddo; 	
	RefreshTableAtServer();

EndProcedure // DeleteSelectedRows()
 
&AtServer
Procedure DeleteAtServer(CurrentRow)

	TabularSectionRow = SavedSettingsTable.FindByID(CurrentRow);

	UT_Common.SystemSettingsStorageDelete(SettingsObjectKey, TabularSectionRow.SettingsKey,
		TabularSectionRow.User);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SettingsObjectKey=UT_CommonClientServer.DebuggingDataObjectDataKeyInSettingsStorage();

	RefreshTableAtServer();
EndProcedure