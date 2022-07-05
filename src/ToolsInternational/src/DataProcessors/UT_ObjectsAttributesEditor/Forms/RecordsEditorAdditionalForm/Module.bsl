&AtClient
Var mCloseFormWithoutQuestion;

&AtClient
Var mRegistersTableCurrRow;

&AtClient
Var mRegistersTableCurrRowOld;
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
	_DevelopmentDescription = Parameters.DevelopmentDescription;

	mObjectRef = Parameters.mObjectRef;
	mObjectRefPrevious = Undefined;
	Title = Title + " (" + _DevelopmentDescription.VersionNo + " from " + _DevelopmentDescription.VersionDate + ")";

	FormsPath = vGetDataProcessor().Metadata().FullName() + ".Form.";

	_FastServerCall = True;
	_ProcessOnlySelectedRowsOnFilling = True;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If mCloseFormWithoutQuestion = True Or _AskQuestionOnClose = False Then
		Return;
	EndIf;

	If _TabRegisters.FindRows(New Structure("Changed", True)).Count() <> 0 Then
		If Exit = Undefined Then
			// For old platform versions
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
	mRegistersTableCurrRowOld = Undefined;

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
	ParamStruct = New Structure("FormsPath, mObjectRef, DevelopmentDescription", FormsPath, mObjectRef,
		_DevelopmentDescription);
	OpenForm("DataProcessor.UT_ObjectsAttributesEditor.Form.RecordsEditorForm", ParamStruct, , CurrentDate(), , , ,
		FormWindowOpeningMode.Independent);
EndProcedure

&AtClient
Procedure _Refresh(Command)
	mRegistersTableCurrRow = Undefined;
	mRegistersTableCurrRowOld = Undefined;

	vClearRecordSets();

	vRefresh();

	Items.RegistersGroup.Title =NSTR("ru = 'Движения документа (';en = 'Document records ('")  + _TabRegisters.Count() + ")";
EndProcedure

&AtClient
Procedure _Write(Command)
	If Not vCheckRecorder() Then
		Return;
	EndIf;

	Value = _TabRegisters.FindRows(New Structure("Write", True)).Count();
	If Value = 0 Then
		vShowMessageBox(NSTR("ru = 'Не отмечены регистры для записи.';en = 'Registers for writing are not set.'"));
		Return;
	EndIf;

	vShowQueryBox("_WriteNext", StrTemplate(NSTR("ru = 'Отмеченные регистры (%1 шт) будут записаны в базу. Продолжить?'; en = 'Selected registers  (%1 pcs) will be written to database. Do you want to continue?'"),
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
Procedure _CheckChangedRows(Command)
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
		vShowMessageBox(NSTR("ru = 'Не отмечены регистры для очистки.';en = 'Registers for clearing are not set.'"));
		Return;
	EndIf;

	vShowQueryBox("_ClearRecordsNext", StrTemplate(NSTR("ru = 'Выбранные регистры (%1 шт) будут очищены. Продолжить?'; en = 'Selected registers  (%1 pcs) will be cleared. Do you want to continue?'"),
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
			vRefreshRecordSet(CurrData.RegisterType, CurrData.Name);
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
		vShowMessageBox(NSTR("ru = 'Не задан набор записей для сохранения';en = 'Recordset for saving is not set.'"));
		Return;
	EndIf;
	vShowQueryBox("_WriteSetNext", NSTR("ru = 'Набор записей будет записан в базу. Продолжить?'; en = 'Recordset will be saved to database. Do you want to continue?'"));
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
	Query = New Query;
	Query.SetParameter("DocumentRecorder", Recorder);

	Query.Text =
	"SELECT
	|	t.*
	|FROM
	|	AccumulationRegister.ClientSettlementsPaymentPlan AS t
	|WHERE
	|	t.DocumentRecorder = &DocumentRecorder";

	Query.Text = StrReplace(Query.Text, "AccumulationRegister.ClientSettlementsPaymentPlan", RegisterType + "."
		+ RegisterName);

	TabResult = Query.Execute().Unload();

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
	пFullName = RegisterType + "." + RegisterName;
	pAttributeName = vGetAttributeName(пFullName);

	Query = New Query;
	Query.SetParameter("Ref", mObjectRef);

	Query.Text = "SELECT TOP 1
				   |	t.Date AS Date
				   |FROM
				   |	" + _DocumentFullName + " AS t
												  |WHERE
												  |	t.Ref = &Ref";

	Selection = Query.Execute().Select();
	pPeriod = ?(Selection.Next(), Selection.Date, Undefined);
	If pPeriod = Undefined Then
		Message(NSTR("ru = 'Не найден указанный документ!';en = 'The specified document was not found.'"));
		Return False;
	EndIf;

	Query = New Query;
	Query.SetParameter("DocumentRecorder", mObjectRef);

	Query.Text =
	"SELECT
	|	t.*
	|FROM
	|	AccumulationRegister.ClientSettlementsPaymentPlan AS t
	|WHERE
	|	t.DocumentRecorder = &DocumentRecorder";

	Query.Text = StrReplace(Query.Text, "AccumulationRegister.ClientSettlementsPaymentPlan", пFullName);

	TabRecordsA = Query.Execute().Unload();
	TabRecordersA = TabRecordsA.Copy( , "Recorder");
	TabRecordersA.GroupBy("Recorder");
	TabRecordsA.Indexes.Add("Recorder");

	TabRecordsB = FormAttributeToValue(pAttributeName);
	TabRecordersB = TabRecordsB.Copy( , "Recorder");
	TabRecordersB.GroupBy("Recorder");
	TabRecordsB.Indexes.Add("Recorder");

	TabRecordersB.Columns.Add("Processed", New TypeDescription("Boolean"));
	TabRecordersB.Columns.Add("Period", New TypeDescription("Date"));

	BeginTransaction();

	For Each StrA In TabRecordersA Do
		Set = vCreateRecordSet(StrA.Recorder, RegisterType, RegisterName);

		Set.Read();
		TabSet = Set.Unload();
		TabSet.Indexes.Add("DocumentRecorder");

		For Each Str In TabSet.FindRows(New Structure("DocumentRecorder", mObjectRef)) Do
			TabSet.Delete(Str);
		EndDo;

		For Each StrB In TabRecordsB.FindRows(New Structure("Recorder", StrA.Recorder)) Do
			NR = TabSet.Add();
			FillPropertyValues(NR, StrB);
			NR.Recorder = StrA.Recorder;
			NR.DocumentRecorder = mObjectRef;
			NR.Period = pPeriod;
		EndDo;

		Set.Load(TabSet);

		StrB = TabRecordersB.Find(StrA.Recorder, "Recorder");
		If StrB <> Undefined Then
			StrB.Processed = True;
		EndIf;

		Try
			If _WriteInLoadingMode Then
				Set.DataExchange.Load = True;
			EndIf;
			Set.Write();
		Except
			Message(BriefErrorDescription(ErrorInfo()));
			RollbackTransaction();

			Return False;
		EndTry;
	EndDo;

	For Each StrA In TabRecordersB.FindRows(New Structure("Processed", False)) Do
		Set = vCreateRecordSet(StrA.Recorder, RegisterType, RegisterName);

		Set.Read();
		TabSet = Set.Unload();

		For Each StrB In TabRecordsB.FindRows(New Structure("Recorder", StrA.Recorder)) Do
			NR = TabSet.Add();
			FillPropertyValues(NR, StrB);
			NR.Recorder = StrA.Recorder;
			NR.DocumentRecorder = mObjectRef;
			NR.Period = pPeriod;
		EndDo;

		Set.Load(TabSet);

		Try
			If _WriteInLoadingMode Then
				Set.DataExchange.Load = True;
			EndIf;
			Set.Write();
		Except
			Message(BriefErrorDescription(ErrorInfo()));
			RollbackTransaction();

			Return False;
		EndTry;
	EndDo;

	CommitTransaction();

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
&AtServer
Procedure vCreateRecordSetsAttributes(CreateAttributes = True)
	TypeVS = Type("ValueStorage");
	TypeTT = Type("Type");
	TypePIT = Type("PointInTime");

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
	//StructSpecColumns = New Structure("Recorder, PointInTime");
	StructSpecColumns = New Structure("LIneNumber, PointInTime, DocumentRecorder");

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
		Item.Visible = False;

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

		For Each Column In TabResult.Columns Do
			If StructSpecColumns.Property(Column.Name) Then
				Continue;
			EndIf;

			Item = ThisForm.Items.Add(AttributeName + "_" + Column.Name, Type("FormField"), VTItem);
			Item.DataPath = AttributeName + "." + Column.Name;
			Item.Type = FormFieldType.InputField;
			Item.AvailableTypes = Column.ValueType;

			If Column.ValueType.ContainsType(TypeVS) Then // version 033
				Item.ReadOnly = True;
			EndIf;

			If Column.Name = "Active" Then
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

			pStruct = vFindAdditionalRegisters(_DocumentFullName);
			If pStruct.DataExists Then
				For Each Item In pStruct.AdditionalRegisters Do
					NR = _TabRegisters.Add();
					NR.Name = Mid(Item.Key, StrFind(Item.Key, ".") + 1);
					NR.Presentation = Item.Value;
					NR.FullName = Item.Key;
					NR.RegisterType = Left(NR.FullName, StrFind(NR.FullName, ".") - 1);
				EndDo;
			EndIf;
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
		mRegistersTableCurrRowOld = mRegistersTableCurrRow;
		mRegistersTableCurrRow = CurrRow;
		AttachIdleHandler("vOnActivateRegistersTableRow", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure vOnActivateRegistersTableRow() Export
	If mRegistersTableCurrRowOld <> Undefined Then
		CurrData = _TabRegisters.FindByID(mRegistersTableCurrRowOld);
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
			CurrData.Write = True;
			CurrData.Changed = True;

			CurrTabFI = Items[AttributeName];
			CurrFieldFI = CurrTabFI.CurrentItem;

			pField = Mid(CurrFieldFI.Name, StrLen(AttributeName) + 2);

			If _ProcessOnlySelectedRowsOnFilling Then
				For Each Item In CurrTabFI.SelectedRows Do
					Str = CurrTab.FindByID(Item);
					Str[pField] = _ValueToFill;
				EndDo;
			Else
				For Each Str In CurrTab Do
					Str[pField] = _ValueToFill;
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
&AtServerNoContext
Function vFindAdditionalRegisters(Val pDocumentFullName)
	pMap = New Map;

	pStruct = New Structure;
	pStruct.Insert("DataExists", False);
	pStruct.Insert("AdditionalRegisters", pMap);

	pMDRecorder = Metadata.Documents.Find("CalculationRecorder");
	If pMDRecorder = Undefined Then
		Return pStruct;
	EndIf;

	If TypeOf(pDocumentFullName) <> Type("String") Then
		pDocumentFullName = pDocumentFullName.Metadata().FullName();
		If StrFind(pDocumentFullName, "Document.") <> 1 Then
			Return pStruct;
		EndIf;
	EndIf;

	For Each MDItem In pMDRecorder.RegisterRecords Do
		pMDAttribute = MDItem.Attribute.Find("DocumentRecorder");
		If pMDAttribute <> Undefined Then
			pRegisterName = MDItem.FullName();

			For Each pType In pMDAttribute.Type.Types() Do
				pMDDoc = Metadata.FindByType(pType);

				If pMDDoc <> Undefined Then
					pDocumentName = pMDDoc.FullName();

					If pDocumentName = pDocumentFullName And pDocumentName <> "Document.CalculationRecorder" Then
						pMap[pRegisterName] = MDItem.Presentation();
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;

	pStruct.DataExists = (pMap.Count() <> 0);

	Return pStruct;
EndFunction

&AtClient
Procedure ChoiceProcessing(SelectedValue, ChoiceSource)

EndProcedure