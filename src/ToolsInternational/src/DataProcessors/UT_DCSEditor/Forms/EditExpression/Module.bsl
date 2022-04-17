#Region Variables

&AtClient
Var UT_CodeEditorClientData Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Title") Then
		Title  = Parameters.Title;
	EndIf;

	ExpressionText = Parameters.Text;
	
	FillAvailableDCSFields();
	
	UT_CodeEditorServer.FormOnCreateAtServer(ThisObject);

	UT_CodeEditorServer.CreateCodeEditorItems(ThisObject,
													   "Expression",
													   Items.ExpressionEditingField,
													   ,
													   "dcs_query");
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UT_CodeEditorClient.FormOnOpen(ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DCSFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RowData = DCSFields.FindByID(RowSelected);
	UT_CodeEditorClient.InsertTextInCursorLocation(ThisObject, "Expression", RowData.DataPath);
	
EndProcedure


#EndRegion


#Region CommandFormEventHandlers

&AtClient
Procedure Apply(Command)
	Close(ExpressionCurrentText());
EndProcedure

#EndRegion

#Region Private

#Region CodeEditor

&AtClient
Procedure SetExpressionText(NewText, SetOriginalText = False, NewOriginalText = "")
	UT_CodeEditorClient.SetEditorText(ThisObject, "Expression", NewText);

	If SetOriginalText Then
		UT_CodeEditorClient.SetEditorOriginalText(ThisObject, "Expression", NewOriginalText);
	EndIf;
EndProcedure

&AtClient
Function ExpressionCurrentText()
	Return UT_CodeEditorClient.EditorCodeText(ThisObject, "Expression");
EndFunction

//@skip-warning
&AtClient
Procedure Attachable_EditorFieldDocumentGenerated(Item)
	UT_CodeEditorClient.HTMLEditorFieldDocumentGenerated(ThisObject, Item);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_EditorFieldOnClick(Item, EventData, StandardProcessing)
	UT_CodeEditorClient.HTMLEditorFieldOnClick(ThisObject, Item, EventData, StandardProcessing);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_CodeEditorDeferredInitializingEditors()
	UT_CodeEditorClient.CodeEditorDeferredInitializingEditors(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_CodeEditorInitializingCompletion() Export
	SetExpressionText(ExpressionText, True, ExpressionText);
	UT_AddFieldsContext();
EndProcedure

&AtClient
Procedure Attachable_CodeEditorDeferProcessingOfEditorEvents() Export
	UT_CodeEditorClient.EditorEventsDeferProcessing(ThisObject);
EndProcedure

#EndRegion

&AtServer
Procedure FillAvailableDCSFields()
	
	FieldsTypes = Parameters.DataSetFieldsTypes;
	PictureAttribute=PictureLib.Attribute;
	PictureCustomExpression=PictureLib.CustomExpression;
	PictureFolder = PictureLib.Folder;
	
	RowsIDMap = New Map;

	For Each CurrentFiled ИЗ Parameters.Fields Do
		If CurrentFiled.Type <> FieldsTypes.Field Then
			Continue;
		EndIf;
		
		PathArray = StrSplit(CurrentFiled.DataPath, ".", False);
		
		CurrentPath = "";
		CurrentParent = DCSFields;
		
		For PathIndex=0  To PathArray.Count()-1 Do
			PathItem = PathArray[PathIndex];
			
			CurrentPath = CurrentPath + ?(ValueIsFilled(CurrentPath),".","") + PathItem;
			
			If CurrentPath = CurrentFiled.DataPath Then
				NewField = CurrentParent.GetItems().Add();
				NewField.Field = PathItem;
				NewField.DataPath = CurrentPath;
				NewField.ValueType = CurrentFiled.ValueType;
				If NewField.ValueType = New TypeDescription Then
					NewField.ValueType = CurrentFiled.QueryValueType;
				EndIf;
				If CurrentFiled.CalculatedField Then
					NewField.Picture = PictureCustomExpression;	
				Else
					NewField.Picture = PictureAttribute;
				EndIf;
				
				Continue;
			EndIf;
			
			RowID = RowsIDMap[Lower(CurrentPath)];
			If RowID = Undefined Then
				NewField = CurrentParent.GetItems().Add();
				NewField.Field = PathItem;
				NewField.DataPath = CurrentPath;
				NewField.ValueType = New TypeDescription("Number");
				NewField.Picture = PictureFolder;

				RowID = NewField.GetID();
				RowsIDMap.Insert(Lower(CurrentPath), RowID);
				
				CurrentParent = NewField;
			Else
				CurrentParent = DCSFields.FindByID(RowID);
			EndIf;
		EndDo;
	EndDo;
	
	FolderSystemFields = DCSFields.GetItems().Add();
	FolderSystemFields.DataPath = "SystemFields";
	FolderSystemFields.Field = "SystemFields";
	FolderSystemFields.Picture = PictureFolder;
	
	NewField = FolderSystemFields.GetItems().Add();
	NewField.Field = "SerialNumber";
	NewField.DataPath = FolderSystemFields.DataPath+"."+NewField.Field;
	NewField.ValueType = New TypeDescription("Number");
	NewField.Picture = PictureAttribute;
	
	NewField = FolderSystemFields.GetItems().Add();
	NewField.Field = "GroupSerialNumber";
	NewField.DataPath = FolderSystemFields.DataPath+"."+NewField.Field;
	NewField.ValueType = New TypeDescription("Number");
	NewField.Picture = PictureAttribute;
	
	NewField = FolderSystemFields.GetItems().Add();
	NewField.Field = "Level";
	NewField.DataPath = FolderSystemFields.DataPath+"."+NewField.Field;
	NewField.ValueType = New TypeDescription("Number");
	NewField.Picture = PictureAttribute;
	
	NewField = FolderSystemFields.GetItems().Add();
	NewField.Field = "LevelInGroup";
	NewField.DataPath = FolderSystemFields.DataPath+"."+NewField.Field;
	NewField.ValueType = New TypeDescription("Number");
	NewField.Picture = PictureAttribute;
	
EndProcedure

&AtClient
Procedure AddFieldsGroupContext(AdditionalContextStructure, DCSFieldsRow, EmptyTypesDescription)
	For Each AvailableVariable In DCSFieldsRow.GetItems() Do
		ChildsCollection = AvailableVariable.GetItems();
		If ChildsCollection.Count() = 0 Then
			Types = AvailableVariable.ValueType.Types();
			If Types.Count() = 0 Then
				VariableStructure = "";
			Else
				VariableStructure = Types[0];
			EndIf;
		Else
			VariableStructure = New Structure;
			If AvailableVariable.ValueType = EmptyTypesDescription Then
				VariableStructure.Insert("Type", "");
			Else
				VariableStructure.Insert("Type", AvailableVariable.ValueType);
			EndIf;
			ChildProperties = New Structure;
			
			AddFieldsGroupContext(ChildProperties, AvailableVariable, EmptyTypesDescription);
			VariableStructure.Insert("ChildProperties", ChildProperties);
			
		EndIf;
		
		AdditionalContextStructure.Insert(AvailableVariable.Field, VariableStructure);
	EndDo;
	
EndProcedure

&AtClient
Procedure UT_AddFieldsContext()
	AdditionalContextStructure = New Structure;

	EmptyTypesDescription = New TypeDescription;
	
	AddFieldsGroupContext(AdditionalContextStructure, DCSFields, EmptyTypesDescription);
	
	UT_CodeEditorClient.AddCodeEditorContext(ThisObject, "Expression", AdditionalContextStructure);

EndProcedure

#EndRegion