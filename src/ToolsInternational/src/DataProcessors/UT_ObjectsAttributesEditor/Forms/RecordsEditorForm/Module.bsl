&AtClient
Var mCloseFormWithoutQuestion;

&AtClient
Var mRegistersTableCurrRow;

&AtClient
Var mOldRegistersTableCurrRow;

&AtClient
Var mLastUUID;
&AtClient
Procedure vShowMessageBox(MessageText)
	ShowMessageBox( , MessageText, 20);
EndProcedure

&AtClient
Procedure vShowQueryBox(ProcedureName, QueryText, AdditionalParameters = Undefined)
	ShowQueryBox(New NotifyDescription(ProcedureName, ThisForm, AdditionalParameters), QueryText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure
&AtServer
Function vGetDataProcessor()
	Return FormAttributeToValue("Object");
EndFunction
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	mObjectRef = Parameters.mObjectRef;
	mObjectRefPrevious = Undefined;

	FormsPath = vGetDataProcessor().Metadata().FullName() + ".Form.";

	_FastServerCall = True;
	_ProcessOnlySelectedRowsOnFilling = True;
EndProcedure

&AtClient
Procedure BeforeCloseAtClient(Cancel, Exit, WarningText, StandardProcessing)
	If mCloseFormWithoutQuestion = True Or _AskQuestionOnClose = False Then
		Return;
	EndIf;

	If _TabRegisters.FindRows(New Structure("Changed", True)).Count() <> 0 Then
		If Exit = Undefined Then
			// For the old platform versions.
			Cancel = True;
			vShowQueryBox("vCloseForm", NSTR("ru = 'Редактор движений будет закрыт. Продолжить?';en = 'Records editor will be closed. Do you want to continue?'"));
			Return;
		EndIf;

		If Exit = False Then
			Cancel = True;
			vShowQueryBox("vCloseForm", NSTR("ru = 'Редактор движений будет закрыт. Продолжить?';en = 'Records editor will be closed. Do you want to continue?'"));
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure vCloseForm(QueryResult, AdditionalParameters = Undefined) Export
	If QueryResult = DialogReturnCode.Yes Then
		mCloseFormWithoutQuestion = True;
		ThisForm.Close();
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	mRegistersTableCurrRow = Undefined;
	mOldRegistersTableCurrRow = Undefined;

	AttachIdleHandler("vAfterOpen", 0.1, True);
EndProcedure

&AtClient
Procedure vAfterOpen() Export
	_Refresh(Undefined);
EndProcedure
&AtClient
Procedure mObjectRefOnChange(Item)
	_Refresh(Undefined);
EndProcedure

&AtClient
Procedure mObjectRefStartChoice(Item, ChoiceData, StandardProcessing)
	If mObjectRef = Undefined Then
		StandardProcessing = False;
		ParamStruct = New Structure("CloseOnOwnerClose, MetadataGroups", True, "Documents");
		OpenForm("CommonForm.UT_MetadataSelectionForm", ParamStruct, Item, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		Array = New Array;
		Array.Add(TypeOf(mObjectRef));
		Item.TypeRestriction = New TypeDescription(Array);
	EndIf;
EndProcedure

&AtClient
Procedure mObjectRefClearing(Item, StandardProcessing)
	Item.TypeRestriction = New TypeDescription;
EndProcedure
&AtClient
Function vCheckRecorder()
	If Not ValueIsFilled(mObjectRef) Then
		vShowMessageBox(NSTR("ru = 'Не задан объект для записи движений!';en = 'Object for write records is not set.'"));
		Return False;
	EndIf;

	Return True;
EndFunction

&AtClient
Procedure _OpenInNewWindow(Command)
	ParamStruct = New Structure("FormsPath, mObjectRef", FormsPath, mObjectRef);
	OpenForm("DataProcessor.UT_ObjectsAttributesEditor.Form.RecordsEditorForm", ParamStruct, , CurrentDate(), , ,
		, FormWindowOpeningMode.Independent);
EndProcedure

&AtClient
Procedure _Refresh(Command)
	mRegistersTableCurrRow = Undefined;
	mOldRegistersTableCurrRow = Undefined;

	vClearRecordSets();

	vRefresh();

	Items.RegistersGroup.Title = NSTR("ru = 'Движения документа (';en = 'Document records ('") + _TabRegisters.Count() + ")";
EndProcedure

&AtClient
Procedure _Write(Command)
	If Not vCheckRecorder() Then
		Return;
	EndIf;

	Value = _TabRegisters.FindRows(New Structure("Write", True)).Count();
	If Value = 0 Then
		vShowMessageBox(NSTR("ru = 'Не отмечены регистры для записи.';en = 'Registers for writting not set.'"));
		Return;
	EndIf;

	vShowQueryBox("_WriteNext", StrTemplate(NSTR("ru = 'Отмеченные регистры (%1 шт) будут записаны в базу. Продолжить?';en = 'Selected registers  (%1 pcs) will be written to database. Do you want to continue?'"),
		Value));
EndProcedure

&AtClient
Procedure _WriteNext(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		vWrite();
	EndIf;
EndProcedure

&AtClient
Procedure _SortRegistersByDefault(Command)
	_TabRegisters.Sort("Changed DESC, Write DESC, RecordCount DESC, FullName");
EndProcedure

&AtClient
Procedure _UncheckAll(Command)
	For Each Str In _TabRegisters.FindRows(New Structure("Write", True)) Do
		Str.Write = False;
	EndDo;
EndProcedure

&AtClient
Procedure _CheckAll(Command)
	For Each Str In _TabRegisters.FindRows(New Structure("Write", False)) Do
		Str.Write = True;
	EndDo;
EndProcedure

&AtClient
Procedure _CheckChangedItems(Command)
	For Each Str In _TabRegisters.FindRows(New Structure("Write, Changed", False, True)) Do
		Str.Write = True;
	EndDo;
EndProcedure

&AtClient
Procedure _ClearRecords(Command)
	If Not vCheckRecorder() Then
		Return;
	EndIf;

	Value = Items._TabRegisters.SelectedRows;
	If Value.Count() = 0 Then
		vShowMessageBox(NSTR("ru = 'Не отмечены регистры для очистки.';en = 'Registers for clear not set.'"));
		Return;
	EndIf;

	vShowQueryBox("_ClearRecordsNext", StrTemplate(NStr("ru = 'Выбранные регистры (%1 шт) будут очищены. Продолжить?';en = 'Selected registers  (%1 pcs) will be cleared. Do you want to continue?'"),
		Value.Count()));
EndProcedure

&AtClient
Procedure _ClearRecordsNext(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		SelectedRows = Items._TabRegisters.SelectedRows;
		For Each Item In SelectedRows Do
			RowData = _TabRegisters.FindByID(Item);
			If RowData <> Undefined Then
				AttributeName = vGetAttributeName(RowData.FullName);

				Try
					TabData = ThisForm[AttributeName];
					If TabData.Count() <> 0 Then
						TabData.Clear();
						RowData.Write = True;
						RowData.Changed = True;
						RowData.RecordsExists = False;
						RowData.RecordCount = 0;
					EndIf;
				Except
				EndTry;
			EndIf;
		EndDo;
	EndIf;
EndProcedure
&AtClient
Procedure _RefreshSet(Command)
	CurrData = Items._TabRegisters.CurrentData;
	If CurrData <> Undefined Then
		AttributeName = vGetAttributeName(CurrData.FullName);

		If _FastServerCall Then
			Array = vReadRecordSetToCollection(mObjectRef, CurrData.RegisterType, CurrData.Name);

			Collection = ThisForm[AttributeName];
			Collection.Clear();

			For Each Item In Array Do
				FillPropertyValues(Collection.Add(), Item);
			EndDo;
		Else
			vRefreshRecordSet(CurrData.RegisterType, CurrData.Имя);
		EndIf;

		CurrData.Changed = False;
		CurrData.Write = False;
		CurrData.RecordCount = ThisForm[AttributeName].Count();
		CurrData.RecordsExists = (CurrData.RecordCount <> 0);
	EndIf;
EndProcedure

&AtClient
Procedure _WriteSet(Command)
	If Not vCheckRecorder() Then
		Return;
	EndIf;

	CurrData = Items._TabRegisters.CurrentData;
	If CurrData = Undefined Then
		vShowMessageBox(NStr("ru = 'Не задан набор записей для сохранения';en = 'Recordset for saving is not set.'"));
		Return;
	EndIf;
	vShowQueryBox("_WriteSetNext", NSTR("ru = 'Набор записей будет записан в базу. Продолжить?';en = 'Recordset will be saved to database. Do you want to continue?'"));
EndProcedure

&AtClient
Procedure _WriteSetNext(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		CurrData = Items._TabRegisters.CurrentData;
		If CurrData <> Undefined Then
			If vWriteRecordSet(CurrData.RegisterType, CurrData.Name) Then
				_RefreshSet(Undefined);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _SwitchRecordsActivity(Command)
	CurrData = Items._TabRegisters.CurrentData;
	If CurrData <> Undefined Then
		AttributeName = vGetAttributeName(CurrData.FullName);
		If ThisForm[AttributeName].Count() <> 0 Then

			For Each Str In ThisForm[AttributeName] Do
				Str.Active = Not Str.Active;
			EndDo;

			RecordSetOnChange(Items[AttributeName]);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _OpenObject(Command)
	CurrData = Items._TabRegisters.CurrentData;
	If CurrData <> Undefined Then
		AttributeName = vGetAttributeName(CurrData.FullName);
		CurrTab = ThisForm[AttributeName];

		If CurrTab.Count() > 0 Then
			CurrTabFI = Items[AttributeName];
			CurrFieldFI = CurrTabFI.CurrentItem;

			pField = Mid(CurrFieldFI.Name, StrLen(AttributeName) + 2);
			Value = CurrTabFI.CurrentData[pField];

			If ValueIsFilled(Value) Then

				If TypeOf(Value) = Type("ValueStorage") Then
					vShowValueVS(Value);

				ElsIf vIsMetadataObject(TypeOf(Value)) Then
					UT_CommonClient.EditObject(Value);

				EndIf;

			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _ShowValueType(Command)
	_CurrentFieldValueType = "";

	Value = Undefined;

	CurrData = Items._TabRegisters.CurrentData;
	If CurrData <> Undefined Then
		AttributeName = vGetAttributeName(CurrData.FullName);
		CurrTab = ThisForm[AttributeName];

		If CurrTab.Count() > 0 Then
			CurrTabFI = Items[AttributeName];
			CurrFieldFI = CurrTabFI.CurrentItem;

			pField = Mid(CurrFieldFI.Name, StrLen(AttributeName) + 2);
			Value = CurrTabFI.CurrentData[pField];

		EndIf;
	EndIf;

	If Value = Undefined Then
		TypeName = "Undefined";
	Else
		TypeName = vGenerateTypeNameByValue(Value);
	EndIf;

	_CurrentFieldValueType = TypeName;
EndProcedure

&AtClient
Procedure vShowValueVS(Value)
	ParamStruct = New Structure("FormsPath, ValueStorageData", FormsPath, Value);
	OpenForm("CommonForm.UT_ValueStorageForm", ParamStruct, , CurrentDate());
EndProcedure
&AtClientAtServerNoContext
Function vGetAttributeName(Val FullName)
	Return StrReplace(FullName, ".", "_");
EndFunction

&AtClient
Procedure vClearRecordSets()
	For Each Str In _TabRegisters.FindRows(New Structure("FormAttributeExists", True)) Do
		AttributeName = vGetAttributeName(Str.FullName);
		ThisForm[AttributeName].Clear();
		Str.RecordsExists = False;
		Str.RecordCount = 0;
	EndDo;
EndProcedure

&AtServer
Procedure vDeleteRecordSetsAttributes()
	ArrayToCreate = New Array;
	ArrayToDelete = New Array;

	For Each Str In _TabRegisters.FindRows(New Structure("FormAttributeExists", True)) Do
		AttributeName = vGetAttributeName(Str.FullName);

		If vCheckAttributeExistence(AttributeName) Then
			ArrayToDelete.Add(AttributeName);
		EndIf;
		Str.FormAttributeExists = False;

		FI = Items.Find("Str_" + AttributeName);
		If FI <> Undefined Then
			Items.Delete(FI);
		EndIf;
	EndDo;

	ChangeAttributes(ArrayToCreate, ArrayToDelete);
EndProcedure

&AtServerNoContext
Function vIsMetadataObject(Val Type)
	MDObject = Metadata.FindByType(Type);
	Return (MDObject <> Undefined And Not Metadata.Enums.Contains(MDObject));
EndFunction

&AtServerNoContext
Function vGenerateTypeNameByValue(Val Value)
	pType = TypeOf(Value);

	MDObject = Metadata.FindByType(pType);
	If MDObject <> Undefined Then
		TypeName = MDObject.FullName();
	Else
		TypeName = String(pType);
	EndIf;

	Return TypeName;
EndFunction

&AtServerNoContext
Function vReadRecordSet(Recorder, RegisterType, RegisterName)
	Set = vCreateRecordSet(Recorder, RegisterType, RegisterName);
	Set.Read();

	TabResult = Set.Unload();

	Return TabResult;
EndFunction

&AtServerNoContext
Function vCreateRecordSet(Recorder, RegisterType, RegisterName)
	If RegisterType = "InformationRegister" Then
		Manager = InformationRegisters[RegisterName];
	ElsIf RegisterType = "AccumulationRegister" Then
		Manager = AccumulationRegisters[RegisterName];
	ElsIf RegisterType = "CalculationRegister" Then
		Manager = CalculationRegisters[RegisterName];
	ElsIf RegisterType = "AccountingRegister" Then
		Manager = AccountingRegisters[RegisterName];
	Else
		Manager = Undefined;
	EndIf;

	Set = Manager.CreateRecordSet();
	Set.Filter.Recorder.Set(Recorder);

	Return Set;
EndFunction

&AtServerNoContext
Function vReadRecordSetToCollection(Val Recorder, Val RegisterType, Val RegisterName)
	TabResult = vReadRecordSet(Recorder, RegisterType, RegisterName);

	Struct = New Structure;

	For Each Item In TabResult.Columns Do
		Struct.Insert(Item.Name);
	EndDo;

	Array = New Array;

	For Each Str In TabResult Do
		NS = New Structure;
		For Each Item In Struct Do
			NS.Insert(Item.Key);
		EndDo;

		FillPropertyValues(NS, Str);
		Array.Add(NS);
	EndDo;

	Return Array;
EndFunction

&AtServer
Procedure vRefreshRecordSet(Val RegisterType, Val RegisterName)
	TabResult = vReadRecordSet(mObjectRef, RegisterType, RegisterName);
	ValueToFormAttribute(TabResult, vGetAttributeName(RegisterType + "." + RegisterName));
EndProcedure

&AtServer
Function vWriteRecordSet(Val RegisterType, Val RegisterName)
	Try
		AttributeName = vGetAttributeName(RegisterType + "." + RegisterName);
		Set = vCreateRecordSet(mObjectRef, RegisterType, RegisterName);

		If ThisForm[AttributeName].Count() <> 0 Then
			TabResult = FormAttributeToValue(AttributeName);
			Set.Load(TabResult);
		EndIf;

		If _WriteInLoadingMode Then
			Set.DataExchange.Load = True;
		EndIf;
		Set.Write();
	Except
		Message(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;

	Return True;
EndFunction

&AtServer
Function vWrite()
	FoundRows = _TabRegisters.FindRows(New Structure("Write", True));
	pTransactionExists = (FoundRows.Count() > 1);

	If pTransactionExists Then
		BeginTransaction();
	EndIf;

	For Each Str In FoundRows Do
		If Not vWriteRecordSet(Str.RegisterType, Str.Name) Then
			If pTransactionExists Then
				RollbackTransaction();
				Return False;
			EndIf;
		EndIf;
	EndDo;

	If pTransactionExists Then
		CommitTransaction();
	EndIf;

	For Each Str In FoundRows Do
		AttributeName = vGetAttributeName(Str.FullName);

		vRefreshRecordSet(Str.RegisterType, Str.Name);

		Str.Changed = False;
		Str.Write = False;
		Str.RecordCount = ThisForm[AttributeName].Count();
		Str.RecordsExists = (Str.RecordCount <> 0);
	EndDo;

	Return True;
EndFunction
&AtServerNoContext
Function vUUIDTypeDescription(pTypeDescription)
	If pTypeDescription.Type().Count() = 1 Then
		pNewTypeDescription = New TypeDescription(pTypeDescription, "String");
	Else
		pNewTypeDescription = pTypeDescription;
	EndIf;

	Return pNewTypeDescription;
EndFunction

&AtServer
Procedure vCreateRecordSetsAttributes(CreateAttributes = True)
	TypeVS = Type("ValueStorage");
	TypeTT = Type("Type");
	TypePIT = Type("PointInTime");
	TypeUUID = Type("UUID");

	DataMap = New Map;

	ArrayToCreate = New Array;
	ArrayToDelete = New Array;

	For Each Str In _TabRegisters Do
		Str.FormAttributeExists = True;

		AttributeName = vGetAttributeName(Str.FullName);

		If CreateAttributes Then
			ArrayToCreate.Add(New FormAttribute(AttributeName, New TypeDescription("ValueTable"), ,
				Str.FullName, False));
		EndIf;

		TabResult = vReadRecordSet(mObjectRef, Str.RegisterType, Str.Name);
		DataMap.Insert(AttributeName, TabResult);

		Str.RecordCount = TabResult.Count();
		Str.RecordsExists = (Str.RecordCount <> 0);
		Str.Changed = False;
		Str.Write = False;

		If CreateAttributes Then
			For Each Column In TabResult.Columns Do
				If Column.ValueType.ContainsType(TypeVS) Then
					AttributeValueType = New TypeDescription;
				ElsIf Column.ValueType.ContainsType(TypeTT) Then
					AttributeValueType = New TypeDescription;
				ElsIf Column.ValueType.ContainsType(TypePIT) Then
					AttributeValueType = New TypeDescription;
				ElsIf Column.ValueType.ContainsType(TypeUUID) Then
					AttributeValueType = vUUIDTypeDescription(Column.ValueType);
				Else
					AttributeValueType = Column.ValueType;
				EndIf;
				ArrayToCreate.Add(New FormAttribute(Column.Name, AttributeValueType, AttributeName,
					Column.Title, False));
			EndDo;
		EndIf;

	EndDo;

	If CreateAttributes Then
		ChangeAttributes(ArrayToCreate, ArrayToDelete);
	EndIf;

	_TabRegisters.Sort("Changed DESC, RecordCount DESC, FullName");
	
	// Form items creation
	StructSpecColumns = New Structure("Recorder, PointInTime");

	For Each Item In DataMap Do
		TabResult = Item.Value;
		AttributeName = StrReplace(Item.Key, ".", "_");

		ValueToFormAttribute(Item.Value, Item.Key);

		If Not CreateAttributes Then
			Continue;
		EndIf;

		NewPage = Items.Add("Str_" + AttributeName, Type("FormGroup"), Items.RecordSetsPages);
		NewPage.Type = FormGroupType.Page;
		NewPage.Title = "";
		NewPage.Visible = True;

		VTItem = ThisForm.Items.Add(AttributeName, Type("FormTable"), NewPage);
		VTItem.DataPath = AttributeName;
		VTItem.SetAction("OnChange", "RecordSetOnChange");

		Item = ThisForm.Items.Add("_" + AttributeName + "_SwitchRecordsActivity", Type("FormButton"),
			VTItem.CommandBar);
		Item.Type = FormButtonType.CommandBarButton;
		Item.CommandName = "_SwitchRecordsActivity";

		Item = ThisForm.Items.Add("_" + AttributeName + "_OpenObject", Type("FormButton"),
			VTItem.CommandBar);
		Item.Type = FormButtonType.CommandBarButton;
		Item.CommandName = "_OpenObject";

		Item = ThisForm.Items.Add("_" + AttributeName + "_RefreshSet", Type("FormButton"),
			VTItem.CommandBar);
		Item.Type = FormButtonType.CommandBarButton;
		Item.CommandName = "_RefreshSet";

		Item = ThisForm.Items.Add("_" + AttributeName + "_WriteSet", Type("FormButton"),
			VTItem.CommandBar);
		Item.Type = FormButtonType.CommandBarButton;
		Item.CommandName = "_WriteSet";

		ButtonGroup = Items.Add("Group_" + VTItem.Name, Type("FormGroup"), VTItem.ContextMenu);
		ButtonGroup.Type = FormGroupType.ButtonGroup;

		Button = Items.Add("_InsertUUID_" + VTItem.Name, Type("FormButton"), ButtonGroup);
		Button.Type = FormButtonType.CommandBarButton;
		Button.CommandName = "_InsertUUID";

		For Each Column In TabResult.Columns Do
			If StructSpecColumns.Property(Column.Name) Then
				Continue;
			EndIf;

			Item = ThisForm.Items.Add(AttributeName + "_" + Column.Name, Type("FormField"), VTItem);
			Item.DataPath = AttributeName + "." + Column.Name;
			Item.Type = FormFieldType.InputField;
			Item.AvailableTypes = Column.ValueType;
			Item.ClearButton = True;

			If Column.ValueType.ContainsType(TypeVS) Then // version 033
				Item.ReadOnly = True;
			EndIf;
		EndDo;
	EndDo;
EndProcedure

&AtServer
Function vCheckAttributeExistence(AttributeName)
	Struct = New Structure(AttributeName);
	FillPropertyValues(Struct, ThisForm);

	Return (Struct[AttributeName] <> Undefined);
EndFunction

&AtServer
Procedure vRefresh()
	CreateAttributes = (TypeOf(mObjectRef) <> TypeOf(mObjectRefPrevious));

	mObjectRefPrevious = mObjectRef;

	If CreateAttributes Then
		vDeleteRecordSetsAttributes();

		_TabRegisters.Clear();

		mRegistersTableCurrRow = Undefined;

		If mObjectRef <> Undefined Then
			MDObject = mObjectRef.Metadata();
			_DocumentFullName = MDObject.FullName();

			For Each MDRegisterObject In MDObject.RegisterRecords Do
				NR = _TabRegisters.Add();
				NR.Name = MDRegisterObject.Name;
				NR.Presentation = MDRegisterObject.Presentation();
				NR.FullName = MDRegisterObject.FullName();
				NR.RegisterType = Left(NR.FullName, StrFind(NR.FullName, ".") - 1);
			EndDo;
		EndIf;

		_TabRegisters.Sort("FullName");
	EndIf;

	vCreateRecordSetsAttributes(CreateAttributes);
EndProcedure
&AtClient
Procedure RecordSetOnChange(Item)
	CurrData = Items._TabRegisters.CurrentData;
	If CurrData <> Undefined Then
		CurrData.Changed = True;
		CurrData.Write = True;
		CurrData.RecordCount = ThisForm[Item.Name].Count();
		CurrData.RecordsExists = (CurrData.RecordCount <> 0);
	EndIf;
EndProcedure

&AtClient
Procedure _TabRegistersOnActivateRow(Item)
	CurrRow = Item.CurrentRow;
	If CurrRow <> mRegistersTableCurrRow Then
		mOldRegistersTableCurrRow = mRegistersTableCurrRow;
		mRegistersTableCurrRow = CurrRow;
		AttachIdleHandler("vOnActivateRegistersTableRow", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure vOnActivateRegistersTableRow() Export
	If mOldRegistersTableCurrRow <> Undefined Then
		CurrData = _TabRegisters.FindByID(mOldRegistersTableCurrRow);
		If CurrData <> Undefined Then
			AttributeName = vGetAttributeName(CurrData.FullName);
		EndIf;
	EndIf;

	CurrData = Undefined;
	If mRegistersTableCurrRow <> Undefined Then
		CurrData = _TabRegisters.FindByID(mRegistersTableCurrRow);
		If CurrData <> Undefined Then
			AttributeName = vGetAttributeName(CurrData.FullName);
			Items.RecordSetsPages.CurrentPage = Items["Str_" + AttributeName];
		EndIf;
	EndIf;

	If CurrData = Undefined Then
		Items.RecordSetsPages.CurrentPage = Items.StrExample;
	EndIf;
EndProcedure
&AtClient
Procedure _FillCurrentColumnData(Command)
	CurrData = Items._TabRegisters.CurrentData;
	If CurrData <> Undefined Then
		AttributeName = vGetAttributeName(CurrData.FullName);
		CurrTab = ThisForm[AttributeName];

		If CurrTab.Count() > 0 Then

			pValue = _ValueToFill;

			CurrData.Write = True;
			CurrData.Changed = True;

			CurrTabFI = Items[AttributeName];
			CurrFieldFI = CurrTabFI.CurrentItem;

			pField = Mid(CurrFieldFI.Name, StrLen(AttributeName) + 2);

			If _ProcessOnlySelectedRowsOnFilling Then
				For Each Item In CurrTabFI.SelectedRows Do
					Str = CurrTab.FindByID(Item);
					Str[pField] = pValue;
				EndDo;
			Else
				For Each Str In CurrTab Do
					Str[pField] = pValue;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _ValueToFillStartChoice(Item, ChoiceData, StandardProcessing)
	If _ValueToFill = Undefined Then
		StandardProcessing = False;
		ParamStruct = New Structure("CloseOnOwnerClose, TypesToFillValues", True, True);
		OpenForm("CommonForm.UT_MetadataSelectionForm", ParamStruct, Item, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	ElsIf TypeOf(_ValueToFill) = Type("UUID") Then
		StandardProcessing = False;
	Else
		Array = New Array;
		Array.Add(TypeOf(_ValueToFill));
		Item.TypeRestriction = New TypeDescription(Array);
	EndIf;
EndProcedure

&AtClient
Procedure _ValueToFillClearing(Item, StandardProcessing)
	Item.TypeRestriction = New TypeDescription;
EndProcedure


// Loading records from another document.
&AtServerNoContext
Function vGetRecordingPeriod(DocRef, TableName)
	Query = New Query;
	Query.SetParameter("Ref", DocRef);
	Query.Текст = "SELECT TOP 1
				   |	AdvanceReport.Date AS Date
				   |IN
				   |	" + TableName + " AS AdvanceReport
										 |WHERE
										 |	AdvanceReport.Ref = &Ref";

	Selection = Query.Execute().Select();

	Return ?(Selection.Next(), Selection.Date, Undefined);
EndFunction
&AtClient
Procedure _LoadOtherDocumentRecords(Command)
	If Not vCheckRecorder() Then
		Return;
	EndIf;

	ParamStruct = New Structure("CloseOnOwnerClose, MetadataGroups", True, "Documents");
	OpenForm("CommonForm.UT_MetadataSelectionForm", ParamStruct, ThisForm, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ChoiceProcessingAtClient(SelectedValue, ChoiceSource)
	ShowInputValue(New NotifyDescription("vHandleDocumentSelectionForLoadingRecords", ThisForm),
		SelectedValue, NStr("ru = 'Документ для загрузки движений';en = 'Document for loading records.'"));
EndProcedure

&AtClient
Procedure vHandleDocumentSelectionForLoadingRecords(Value, AdditionalParameters = Undefined) Export
	If Value <> Undefined Then
		vShowQueryBox("vLoadRecordsFromDocument",
			NStr("ru = 'Будут загружены движения из выбранного документа. Продолжить?';en = 'Records from the selected document will be loaded. Do you want to continue?'"), Value);
	EndIf;
EndProcedure

&AtClient
Procedure vLoadRecordsFromDocument(QueryResult, DocRef) Export
	If QueryResult = DialogReturnCode.Yes And ValueIsFilled(DocRef) Then
		If vLoadRecordsFromDocumentAtServer(DocRef) Then
			_SortRegistersByDefault(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function vLoadRecordsFromDocumentAtServer(DocRef)
	pResult = False;

	pRecordsDestination = mObjectRef.Metadata().RegisterRecords;

	For Each MDItem In DocRef.Metadata().RegisterRecords Do
		If pRecordsDestination.Contains(MDItem) Then
			pFullName = MDItem.FullName();
			pRegisterType = Left(pFullName, StrFind(pFullName, ".") - 1);

			TabData = vReadRecordSet(DocRef, pRegisterType, MDItem.Name);
			If TabData.Count() <> 0 Then
				StructMain = New Structure("Period, Recorder", vGetRecordingPeriod(mObjectRef,
					_DocumentFullName), mObjectRef);
				AttributeName = vGetAttributeName(pFullName);
				TabSet = ThisForm[AttributeName];
				For Each Str In TabData Do
					NR = TabSet.Add();
					FillPropertyValues(NR, Str);
					FillPropertyValues(NR, StructMain);
				EndDo;

				Array = _TabRegisters.FindRows(New Structure("FullName", pFullName));
				If Array.Count() <> 0 Then
					StrRegister = Array[0];
					StrRegister.Write = True;
					StrRegister.Changed = True;
					StrRegister.RecordsExists = True;
					StrRegister.RecordCount = TabSet.Count();
				EndIf;

				pResult = True;
			EndIf;
		EndIf;
	EndDo;

	Return pResult;
EndFunction
&AtClient
Procedure _InsertUUID(Command)
	CurrTable = ThisForm.CurrentItem;

	If CurrTable.Name = "_ValueToFill" Then
		pStruct = New Structure("Table", CurrTable.Name);
		ShowInputString(New NotifyDescription("vProcessInput_UUID", ThisForm, pStruct), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор';en = 'Enter a unique identifier (UUID)'"), , False);
		Return;
	ElsIf TypeOf(CurrTable) <> Тип("FormTable") Then
		Return;
	EndIf;

	CurrColumn = CurrTable.CurrentItem;
	If CurrColumn = Undefined Or CurrColumn.ReadOnly Then
		Return;
	EndIf;

	Try
		pAvailableTypes = CurrColumn.AvailableTypes.Types();
		If pAvailableTypes.Count() <> 0 And pAvailableTypes.Find(Type("UUID")) <> 0 Then
			Return;
		EndIf;
	Except
	EndTry;

	CurrData = Items[CurrTable.Name].CurrentData;
	If CurrData <> Undefined Then
		pStruct = New Structure("Table", CurrTable.Name);

		pStruct.Insert("Field", Сред(CurrColumn.Name, StrLen(CurrTable.Name) + 2));

		ShowInputString(New NotifyDescription("vProcessInput_UUID", ThisForm, pStruct), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор';en = 'Enter a unique identifier (UUID)'"), , False);
	EndIf;
EndProcedure

&AtClient
Procedure vProcessInput_UUID(String, pStruct = Undefined) Export
	If String <> Undefined And Not isBlankString(String) Then
		Try
			pValue = New UUID(String);
			mLastUUID = String;
		Except
			ShowMessageBox( , NSTR("ru = 'Значение не может быть преобразовано в Уникальный идентификатор!';en = 'The value cannot be converted to a Unique identifier (UUID).'"), 20);
			Return;
		EndTry;

		If pStruct.Table = "_ValueToFill" Then
			_ValueToFill = pValue;
		Else
			CurrData = Items[pStruct.Таблица].CurrentData;
			If CurrData <> Undefined Then
				CurrData[pStruct.Field] = pValue;

				CurrDataReg = Items._TabRegisters.CurrentData;
				CurrDataReg.Write = True;
				CurrDataReg.Changed = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure