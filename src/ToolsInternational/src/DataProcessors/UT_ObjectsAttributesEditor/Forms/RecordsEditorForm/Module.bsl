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
		AttributeName = vGetAttributeName(CurrentData.FullName);
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
	ParamsStruct = New Structure("FormsPath, ValueStorageData", FormsPath, Value);
	OpenForm("CommonForm.UT_ValueStorageForm", ParamsStruct, , CurrentDate());
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
Function vCheckAttributeExistence(ИмяРеквизита)
	Струк = New Structure(ИмяРеквизита);
	FillPropertyValues(Струк, ThisForm);

	Return (Струк[ИмяРеквизита] <> Undefined);
EndFunction

&AtServer
Procedure vRefresh()
	НадоСоздаватьРеквизиты = (TypeOf(mObjectRef) <> TypeOf(mObjectRefPrevious));

	mObjectRefPrevious = mObjectRef;

	If НадоСоздаватьРеквизиты Then
		vDeleteRecordSetsAttributes();

		_TabRegisters.Очистить();

		mRegistersTableCurrRow = Undefined;

		If mObjectRef <> Undefined Then
			ОбъектМД = mObjectRef.Metadata();
			_FullNameДокумента = ОбъектМД.FullName();

			For Each ОбъектРегистрМД Из ОбъектМД.Движения Do
				НС = _TabRegisters.Добавить();
				НС.Name = ОбъектРегистрМД.Name;
				НС.Presentation = ОбъектРегистрМД.Представление();
				НС.FullName = ОбъектРегистрМД.FullName();
				НС.RegisterType = Лев(НС.FullName, СтрНайти(НС.FullName, ".") - 1);
			EndDo;
		EndIf;

		_TabRegisters.Сортировать("FullName");
	EndIf;

	vCreateRecordSetsAttributes(НадоСоздаватьРеквизиты);
EndProcedure
&AtClient
Procedure RecordSetOnChange(Элемент)
	ТекДанные = Items._TabRegisters.ТекущиеДанные;
	If ТекДанные <> Undefined Then
		ТекДанные.Changed = True;
		ТекДанные.Write = True;
		ТекДанные.RecordCount = ThisForm[Элемент.Name].Количество();
		ТекДанные.RecordsExists = (ТекДанные.RecordCount <> 0);
	EndIf;
EndProcedure

&AtClient
Procedure _TabRegistersOnActivateRow(Элемент)
	ТекСтрока = Элемент.ТекущаяСтрока;
	If ТекСтрока <> mRegistersTableCurrRow Then
		mOldRegistersTableCurrRow = mRegistersTableCurrRow;
		mRegistersTableCurrRow = ТекСтрока;
		AttachIdleHandler("вПриАктивизацииСтрокиТаблицыРегистров", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure вПриАктивизацииСтрокиТаблицыРегистров() Export
	If mOldRegistersTableCurrRow <> Undefined Then
		ТекДанные = _TabRegisters.FindByID(mOldRegistersTableCurrRow);
		If ТекДанные <> Undefined Then
			ИмяРеквизита = vGetAttributeName(ТекДанные.FullName);
		EndIf;
	EndIf;

	ТекДанные = Undefined;
	If mRegistersTableCurrRow <> Undefined Then
		ТекДанные = _TabRegisters.FindByID(mRegistersTableCurrRow);
		If ТекДанные <> Undefined Then
			ИмяРеквизита = vGetAttributeName(ТекДанные.FullName);
			Items.RecordSetsPages.ТекущаяСтраница = Items["Стр_" + ИмяРеквизита];
		EndIf;
	EndIf;

	If ТекДанные = Undefined Then
		Items.RecordSetsPages.ТекущаяСтраница = Items.StrExample;
	EndIf;
EndProcedure
&AtClient
Procedure _FillCurrentColumnData(Команда)
	ТекДанные = Items._TabRegisters.ТекущиеДанные;
	If ТекДанные <> Undefined Then
		ИмяРеквизита = vGetAttributeName(ТекДанные.FullName);
		ТекТаб = ThisForm[ИмяРеквизита];

		If ТекТаб.Количество() > 0 Then

			пЗначение = _ValueToFill;

			ТекДанные.Write = True;
			ТекДанные.Changed = True;

			ТекТабЭФ = Items[ИмяРеквизита];
			ТекПолеЭФ = ТекТабЭФ.ТекущийЭлемент;

			пПоле = Сред(ТекПолеЭФ.Имя, StrLen(ИмяРеквизита) + 2);

			If _ProcessOnlySelectedRowsOnFilling Then
				For Each Элем Из ТекТабЭФ.ВыделенныеСтроки Do
					Стр = ТекТаб.FindByID(Элем);
					Стр[пПоле] = пЗначение;
				EndDo;
			Else
				For Each Стр Из ТекТаб Do
					Стр[пПоле] = пЗначение;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _ValueToFillStartChoice(Элемент, ДанныеВыбора, StandardProcessing)
	If _ValueToFill = Undefined Then
		StandardProcessing = False;
		СтрукПарам = New Structure("CloseOnOwnerClose, TypesToFillValues", True, True);
		OpenForm("CommonForm.UT_MetadataSelectionForm", СтрукПарам, Элемент, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	ElsIf TypeOf(_ValueToFill) = Тип("УникальныйИдентификатор") Then
		StandardProcessing = False;
	Else
		Array = New Array;
		Array.Добавить(TypeOf(_ValueToFill));
		Элемент.TypeRestriction = New TypeDescription(Array);
	EndIf;
EndProcedure

&AtClient
Procedure _ValueToFillClearing(Элемент, StandardProcessing)
	Элемент.TypeRestriction = New TypeDescription;
EndProcedure


// загрузка движений из другого документа
&AtServerNoContext
Function вПолучитьПериодРегистрации(ДокСсылка, ИмяТаблицы)
	Запрос = New Запрос;
	Запрос.УстановитьПараметр("Ссылка", ДокСсылка);
	Запрос.Текст = "ВЫБРАТЬ ПЕРВЫЕ 1
				   |	АвансовыйОтчет.Дата КАК Дата
				   |ИЗ
				   |	" + ИмяТаблицы + " КАК АвансовыйОтчет
										 |ГДЕ
										 |	АвансовыйОтчет.Ссылка = &Ссылка";

	Выборка = Запрос.Выполнить().Выбрать();

	Return ?(Выборка.Следующий(), Выборка.Дата, Undefined);
EndFunction
&AtClient
Procedure _LoadOtherDocumentRecords(Команда)
	If Не vCheckRecorder() Then
		Return;
	EndIf;

	СтрукПарам = New Structure("CloseOnOwnerClose, MetadataGroups", True, "Documents");
	OpenForm("CommonForm.UT_MetadataSelectionForm", СтрукПарам, ThisForm, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure ChoiceProcessingAtClient(ВыбранноеЗначение, ИсточникВыбора)
	ПоказатьВводЗначения(New NotifyDescription("вОбработатьВыборДокументаДляЗагрузкиДвижений", ThisForm),
		ВыбранноеЗначение, NStr("ru = 'Документ для загрузки движений';en = 'Document for records loading'"));
EndProcedure

&AtClient
Procedure вОбработатьВыборДокументаДляЗагрузкиДвижений(Значение, ДопParameters = Undefined) Export
	If Значение <> Undefined Then
		vShowQueryBox("вЗагрузитьДвиженияИзДокумента",
			nstr("ru = 'Будут загружены движения из выбранного документа. Продолжить?';en = 'Will be loaded records from selected document. Continue?'"), Значение);
	EndIf;
EndProcedure

&AtClient
Procedure вЗагрузитьДвиженияИзДокумента(РезультатВопроса, ДокСсылка) Export
	If РезультатВопроса = DialogReturnCode.Да И ValueIsFilled(ДокСсылка) Then
		If вЗагрузитьДвиженияИзДокументаНаСервере(ДокСсылка) Then
			_СортироватьРегистрыСтандартно(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function вЗагрузитьДвиженияИзДокументаНаСервере(ДокСсылка)
	пРезультат = False;

	пДжвиженияПриемник = mObjectRef.Metadata().Движения;

	For Each ЭлеметМД Из ДокСсылка.Metadata().Движения Do
		If пДжвиженияПриемник.Содержит(ЭлеметМД) Then
			пFullName = ЭлеметМД.FullName();
			пВидРегистра = Лев(пFullName, СтрНайти(пFullName, ".") - 1);

			ТабДанные = vReadRecordSet(ДокСсылка, пВидРегистра, ЭлеметМД.Имя);
			If ТабДанные.Количество() <> 0 Then
				СтрукОсновное = New Structure("Период, Recorder", вПолучитьПериодРегистрации(mObjectRef,
					_FullNameДокумента), mObjectRef);
				ИмяРеквизита = vGetAttributeName(пFullName);
				ТабНабор = ThisForm[ИмяРеквизита];
				For Each Стр Из ТабДанные Do
					НС = ТабНабор.Добавить();
					FillPropertyValues(НС, Стр);
					FillPropertyValues(НС, СтрукОсновное);
				EndDo;

				Array = _TabRegisters.FindRows(New Structure("FullName", пFullName));
				If Array.Количество() <> 0 Then
					СтрРегистр = Array[0];
					СтрРегистр.Write = True;
					СтрРегистр.Changed = True;
					СтрРегистр.RecordsExists = True;
					СтрРегистр.RecordCount = ТабНабор.Количество();
				EndIf;

				пРезультат = True;
			EndIf;
		EndIf;
	EndDo;

	Return пРезультат;
EndFunction
&AtClient
Procedure _InsertUUID(Команда)
	ТекТаблица = ThisForm.ТекущийЭлемент;

	If ТекТаблица.Name = "_ValueToFill" Then
		пСтрук = New Structure("Таблица", ТекТаблица.Name);
		ПоказатьВводСтроки(New NotifyDescription("вОбработатьВвод_UUID", ThisForm, пСтрук), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор';en = 'Enter a unique identifier (UUID)'"), , False);
		Return;
	ElsIf TypeOf(ТекТаблица) <> Тип("ТаблицаФормы") Then
		Return;
	EndIf;

	ТекКолонка = ТекТаблица.ТекущийЭлемент;
	If ТекКолонка = Undefined Или ТекКолонка.ТолькоПросмотр Then
		Return;
	EndIf;

	Try
		пДоступныеТипы = ТекКолонка.ДоступныеТипы.Типы();
		If пДоступныеТипы.Количество() <> 0 И пДоступныеТипы.Найти(Тип("УникальныйИдентификатор")) <> 0 Then
			Return;
		EndIf;
	Except
	EndTry;

	ТекДанные = Items[ТекТаблица.Name].ТекущиеДанные;
	If ТекДанные <> Undefined Then
		пСтрук = New Structure("Таблица", ТекТаблица.Name);

		пСтрук.Вставить("Поле", Сред(ТекКолонка.Имя, StrLen(ТекТаблица.Имя) + 2));

		ПоказатьВводСтроки(New NotifyDescription("вОбработатьВвод_UUID", ThisForm, пСтрук), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор';en = 'Enter a unique identifier (UUID)'"), , False);
	EndIf;
EndProcedure

&AtClient
Procedure вОбработатьВвод_UUID(Строка, пСтрук = Undefined) Export
	If Строка <> Undefined И Не ПустаяСтрока(Строка) Then
		Try
			пЗначение = New УникальныйИдентификатор(Строка);
			mLastUUID = Строка;
		Except
			ПоказатьПредупреждение( , NSTR("ru = 'Значение не может быть преобразовано в Уникальный идентификатор!';en = 'The value cannot be converted to a Unique identifier! (UUID)'"), 20);
			Return;
		EndTry;

		If пСтрук.Таблица = "_ValueToFill" Then
			_ValueToFill = пЗначение;
		Else
			ТекДанные = Items[пСтрук.Таблица].ТекущиеДанные;
			If ТекДанные <> Undefined Then
				ТекДанные[пСтрук.Поле] = пЗначение;

				ТекДанныеРег = Items._TabRegisters.ТекущиеДанные;
				ТекДанныеРег.Write = True;
				ТекДанныеРег.Changed = True;
			EndIf;
		EndIf;
	EndIf;
EndProcedure