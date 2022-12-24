&AtClient
Procedure WriteAndClose(Command)
	If Not Parameters.Rename Then
		ChangeParameter();
		Notify("ParameterChanged");
	EndIf;
	Close();
EndProcedure

&AtClient
Procedure SetParameterName(Command)
	ParameterName=TrimAll(ParameterName);
	If ParameterNameHasErrors(ParameterName) Then
		Message = New UserMessage;
		Message.Text = NSTR("ru = 'Введите наименование параметра';en = 'Input parameter name'");
		Message.Field = "ParameterName";
		Message.Message();
	Else
		If Parameters.Rename Then
			RenameParameter(Parameters.ParameterName, ParameterName);
			Notify("ParameterChanged");
			Close();
		Else
			ThisForm.Title= StrTemplate(NSTR("ru = 'Новый параметр';en = 'New parameter'"),ParameterName);
			FormItemsVisibilityManaging("SelectedType", False);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Function ParameterNameHasErrors(Name)
	If IsBlankString(Name) Then
		Return True;
	Else
		 //TODO  Check for available symbols
		Return False;
	EndIf;
EndFunction

&AtClient
Procedure SelectedTypeOnChange(Item)
	Parameters.ParameterType=SelectedType;
	FormItemsVisibilityManaging(SelectedType);
EndProcedure

&AtClient
Procedure ExternalFileStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing=False;
	Dialog = New FileDialog(FileDialogMode.Opening);
	Dialog.Title = NSTR("ru = 'Выберите файл';en = 'Choose file'");
	Dialog.FullFileName = "";
	Filter =NSTR("ru = 'Все файлы  (*.*)|*.*';en = 'All files (*.*)|*.*'");
	Dialog.Filter = Filter;
	Dialog.Multiselect = False;
	Dialog.Show(New NotifyDescription("ExternalFileStartChoiceOnEnd", ThisForm));
EndProcedure

&AtClient
Procedure ExternalFileStartChoiceOnEnd(SelectedFiles, AdditionalParameters) Export
	If (TypeOf(SelectedFiles) = Type("Array") And SelectedFiles.Count() > 0) Then
		ExternalFile = SelectedFiles[0];
		NotifyDescription = New NotifyDescription("PutFileEnd", ThisObject);
		BeginPutFile(NotifyDescription, , ExternalFile, False, ThisForm.UUID);
	EndIf;
EndProcedure

&AtClient
Procedure PutFileEnd(Result, Address, SelectedFileName, AdditionalParameters) Export
	StorageURL = Address;
EndProcedure

&AtServer
Procedure FormItemsVisibilityManaging(Param = "", ButtonsVisibility = True)
	For Each Item In Items Do
		If TypeOf(Item) = Type("FormDecoration") Then
			Continue;
		EndIf;
		If Not IsBlankString(Param) Then
			Item.Visible=?(Find(Item.Name, Param) > 0, True, False);
		EndIf;
		If Find(Item.Name, "Close") > 0 Then
			Item.Visible=ButtonsVisibility;
			Item.Parent.Visible=True;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure CollectionVisibilityManaging(Param = "Array")
	If Not IsBlankString(Parameters.ParameterName) Then
		Items.TypeCollection.Visible=False;
	EndIf;
	If Param = "Array" Then
		Catalogs.UT_Algorithms.AddColumnNL(ThisObject, "Value", TypeDescription, "ParameterCollection"); // - In item form - this code has view : UT_Forms.AddColumnNL(ThisObject, "Value", TypeDescription, "ParameterCollection");	
	ElsIf Param = "Structure" Then
		Items.TypeDescription.Visible=False;
		Items.AddColumn.Visible=False;
		TD= New TypeDescription("String", , New StringQualifiers(20, AllowedLength.Variable));
		Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Key", TD, "CollectionParameter");
		Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Value", TypeDescription, "CollectionParameter");
	ElsIf Param = "Map" Then
		Items.TypeDescription.Visible=False;
		Items.AddColumn.Visible=False;
		Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Key", TypeDescription, "CollectionParameter");
		Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Value", TypeDescription, "CollectionParameter");
	Else
		Items.TypeDescription.Visible=True;
		Items.AddColumn.Visible=True;
		Items.DeleteColumn.Visible=True;
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If IsBlankString(Parameters.ParameterName) Then
		ThisForm.Title=NStr("ru = 'Новый параметр';en = 'New parameter'");
		FormItemsVisibilityManaging("Title", False);
	ElsIf Parameters.Rename Then
		ThisForm.Title=StrTemplate("%1 :%2",Parameters.ParameterName,NSTR("ru = 'Новое имя параметра';en = 'New parameter name'"));
		ParameterName=Parameters.ParameterName;
		FormItemsVisibilityManaging("Title");
	Else
		ParameterName=Parameters.ParameterName;
		ThisForm.Title=StrTemplate("%1 :%2",Parameters.ParameterName,NSTR("ru = 'Изменение параметра';en = 'Changing  parameter'"));;
		OnParameterChangeAction();
	EndIf;
EndProcedure

&AtServer
Procedure OnParameterChangeAction()
	Parameter=GetParameter(Parameters.ParameterName);
	M = New Map;
	M.Insert("Array", "Collection");
	M.Insert("Structure", "Collection");
	M.Insert("Map", "Collection");
	M.Insert("Value Table", "Collection");
	M.Insert("Binary data", "ExternalFile");
	M.Insert(Undefined, "AvailableTypes");
	ParameterType=M.Get(Parameters.ParameterType);
	If ParameterType = Undefined Then
		FormItemsVisibilityManaging("AvailableTypes");
		AvailableTypes=Parameter;
		Items.AvailableTypes.Title=Parameters.ParameterType;
		Items.AvailableTypes.ChooseType=False;
		Parameters.ParameterType="AvailableTypes";
	ElsIf ParameterType = "Collection" Then
		FormItemsVisibilityManaging("Collection");
		Items.TypeCollection.Visible=False;
		For Each CollectionItem In Items.CollectionParameter.ChildItems Do
			CollectionItem.Visible=True;
		EndDo;
		If Parameters.ParameterType = "Array" Then
			Catalogs.UT_Algorithms.AddColumnNL(ThisObject, "Value", TypeDescription, "CollectionParameter");
			Table = Catalogs.UT_Algorithms.CollectionToValueTable(Parameter);
			CollectionParameter.Load(Table);
			TypeCollection="Array";
		ElsIf Parameters.ParameterType = "Structure" Then
			Items.TypeDescription.Visible=False;
			Items.AddColumn.Visible=False;
			TD= New TypeDescription("String", , New StringQualifiers(20, AllowedLength.Variable));
			Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Key", TD, "CollectionParameter");
			Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Value", TypeDescription, "CollectionParameter");
			Table = Catalogs.UT_Algorithms.CollectionToValueTable(Parameter);
			CollectionParameter.Load(Table);
			TypeCollection="Structure";
		ElsIf Parameters.ParameterType = "Map" Then
			Items.TypeDescription.Visible=False;
			Items.AddColumn.Visible=False;
			Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Key", TD, "CollectionParameter");
			Catalogs.UT_Algorithms.AddColumnNL(ThisObject,"Value", TypeDescription, "CollectionParameter");
			Table = Catalogs.UT_Algorithms.CollectionToValueTable(Parameter);
			CollectionParameter.Load(Table);
			TypeCollection="Map";
		Else
			Items.TypeDescription.Visible=True;
			Items.AddColumn.Visible=True;
			Items.DeleteColumn.Visible=True;
			For Each Column In Parameter.Columns Do
				Catalogs.UT_Algorithms.AddColumnNL(ThisObject,Column.Name, Column.ValueType, "CollectionParameter");
			EndDo;
			CollectionParameter.Load(Parameter);
		EndIf;
	Else
		Parameters.ParameterType="ExternalFile";
		FormItemsVisibilityManaging("ExternalFile");
	EndIf;
EndProcedure

&AtServer
Procedure RenameParameter(Key, NewName)
	SelectedObject=FormAttributeToValue("Object");
	SelectedObject.RenameParameter(Key, NewName);
EndProcedure

/// Interface

&AtClient
Procedure AddColumn(Command)
	ColumnName="";
	ShowInputValue(New NotifyDescription("AddColumnEnd", ThisForm, New Structure("ColumnName",
		ColumnName)), ColumnName, Nstr("ru = 'Введите имя новой колонки';en = 'Input name of new column'"), "String");
EndProcedure

&AtClient
Procedure AddColumnEnd(Value, AdditionalParameters) Export

	ColumnName = ?(Value = Undefined, AdditionalParameters.ColumnName, Value);
	If Not IsBlankString(ColumnName) Then
		AddColumnNLAtServer(ThisObject,TrimAll(ColumnName), TypeDescription, "CollectionParameter");
		TypeDescription="";
	Else
		Return;
	EndIf;

EndProcedure

&AtServerNoContext
Procedure AddColumnNLAtServer(pForm, ColumnName, TypeDescription, TableName)
	Catalogs.UT_Algorithms.AddColumnNL(pForm, ColumnName, TypeDescription, TableName);
EndProcedure

&AtServerNoContext
Procedure DeleteColumnNlAtServer(pForm, ColumnName, TableName)
	Catalogs.UT_Algorithms.DeleteColumnNL(pForm, ColumnName, TableName);
EndProcedure

&AtClient
Procedure DeleteColumn(Command)
	ColumnName=Items.CollectionParameter.CurrentItem.Name;
	If Items.CollectionParameter.CurrentItem <> Undefined Then
		ShowQueryBox(New NotifyDescription("DeleteColumnEnd", ThisForm, New Structure("ColumnName",
			ColumnName)),StrTemplate("%1 %2 ?",NStr("ru = 'Вы уверены , что хотите изменить удалить колонку ';en = 'Are you sure you want to change delete column'"),ColumnName) ,
			QuestionDialogMode.YesNo);
	Else
		ShowMessageBox(Undefined, NSTR("ru = 'Нужно выбрать колонку таблицы !';en = 'You need to select a table column !'"));
	EndIf;
EndProcedure

&AtClient
Procedure DeleteColumnEnd(QuestionResult, AdditionalParameters) Export

	ColumnName = AdditionalParameters.ColumnName;

	If QuestionResult = DialogReturnCode.Yes Then
		DeleteColumnNlAtServer(ThisForm,ColumnName, "CollectionParameter");
	EndIf;

EndProcedure

&AtClient
Procedure TypeCollectionOnChange(Item)
	CollectionVisibilityManaging(TypeCollection);
	Item.Visible=False;
EndProcedure

&AtServer
Procedure ChangeParameter()
	NewValue=GetNewValue();
	If Not NewValue = Undefined Then
		SelectedObject=FormAttributeToValue("Object");
		SelectedObject.ChangeParameter(ParameterName,NewValue);
	EndIf;
EndProcedure

&AtServer
Function GetNewValue()
	If Parameters.ParameterType = "AvailableTypes" Then
		Return AvailableTypes;
	ElsIf Parameters.ParameterType = "ExternalFile" Then
		Pos = StrFind(ExternalFile, ".", SearchDirection.FromEnd);
		Return "{" + ?(Pos > 0, Mid(ExternalFile, Pos + 1) + "}", "}") + StorageURL;
	ElsIf Parameters.ParameterType = "DefinedType" Then
		Try
			Result=Undefined;
			Execute (DefinedType);
			Return Result;
		Except
			Message(ErrorDescription());
			Return Undefined;
		EndTry;
	Else
		Table=FormAttributeToValue("CollectionParameter");
		If TypeCollection = "Array" Then
			Return Table.UnloadColumn(0);
		ElsIf TypeCollection = "Structure" Then
			S=New Structure;
			For Each Row In Table Do
				S.Insert(Row.Key, Row.Value);EndDo
			;
			Return S;
		ElsIf TypeCollection = "Map" Then
			S=New Map;
			For Each Row In Table Do
				S.Insert(Row.Key, Row.Value);EndDo
			;
			Return S;
		Else
			Return Table;
		EndIf;
	EndIf;
EndFunction

&AtServer
Function GetParameter(ParameterName)
	SelectedObject=FormAttributeToValue("Object");
	Return SelectedObject.GetParameter(ParameterName);
EndFunction // GetParameter()

&AtClient
Procedure ParameterNameOnChange(Item)
	If Not Parameters.Rename Then
		Parameters.ParameterName=TrimAll(ParameterName);
	EndIf;
EndProcedure

&AtClient
Procedure AvailableTypesOnChange(Item)
	Item.Title=TypeOf(AvailableTypes);
EndProcedure

&AtClient
Procedure DefinedTypeTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	Parameters.ParameterType="DefinedType";
EndProcedure
