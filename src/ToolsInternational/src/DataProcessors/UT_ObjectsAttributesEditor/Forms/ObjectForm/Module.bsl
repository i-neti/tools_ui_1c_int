&AtClient
Var mTypeVS;

&AtClient
Var mTypeUUID;

&AtClient
Var mLastUUID;
&AtServer
Function vGetDataProcessor()
	Return FormAttributeToValue("Object");
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	FormsPath = vGetDataProcessor().Metadata().FullName() + ".Form.";

	_PrefixForNewItems = "__XXX__";
	_ObjectType = "";
	_ProcessOnlySelectedRows = True;
	_ConfigurationAllowsAdditionalRecords = (Metadata.Documents.Find("CalculationRecorder") <> Undefined);
	mPreviousObjectRef = Undefined;

	Items.DocumentRecordsPage.Visible = False;
	Items._OpenAdditionalRecordsEditor.Visible = False;

	If Not UT_Users.IsFullUser() Then
		Items.Form_DeleteObject.Visible = False;
	EndIf;

	If Parameters.Property("mObjectRef") Then
		mObjectRef = Parameters.mObjectRef;
	ElsIf Parameters.Property("DebugData") Then
		DataToDebug = GetFromTempStorage(Parameters.DebugData);
		mObjectRef = DataToDebug.Object;

	EndIf;

	UT_Forms.CreateWriteParametersAttributesFormOnCreateAtServer(ThisObject,
		Items.WriteParametersGroup);
	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	mTypeVS = Type("ValueStorage");
	mTypeUUID = Type("UUID");

	RefreshObjectData(Undefined);
EndProcedure

&AtClient
Procedure mObjectRefStartChoice(Item, ChoiceData, StandardProcessing)
	UT_CommonClient.FormFieldValueStartChoice(ThisObject, Item, mObjectRef, StandardProcessing,
		New NotifyDescription("mObjectRefStartChoiceBlankValueChoiceCompletion", ThisObject), "Refs");
EndProcedure

&AtClient
Procedure mObjectRefStartChoiceBlankValueChoiceCompletion(Result, AdditionalParameters) Export
	mObjectRef = Result;
	OnChangeMRef();
EndProcedure

&AtClient
Procedure mObjectRefOnChange(Item)
	OnChangeMRef();
EndProcedure

&AtClient
Procedure OnChangeMRef()
	ThisForm.UniqueKey = mObjectRef;

	_URL = "";

	If mObjectRef <> Undefined Then
		_UUID = "";
	EndIf;

	RefreshObjectData(Undefined);
EndProcedure

&AtClient
Procedure mObjectRefClearing(Item, StandardProcessing)
	UT_CommonClient.FormFieldClear(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure _SelectDeletedObject(Command)
	ShowInputString(New NotifyDescription("vProcessInputString_ObjectNotFound", ThisForm), ,
		NSTR("ru = 'Введите битую ссылку: <Объект не найден> ... ';en = 'Enter the broken ref: <Object not found> ...'"), , False);
EndProcedure

&AtClient
Procedure vProcessInputString_ObjectNotFound(String, AddParam = Undefined) Export
	If String <> Undefined And Not IsBlankString(String) Then
		pStruct = vGetRemoteObjectRef(String);
		If Not pStruct.Cancel Then
			mObjectRef = pStruct.Ref;
			RefreshObjectData(Undefined);
		ElsIf Not IsBlankString(pStruct.CancelCause) Then
			Message(pStruct.CancelCause);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _URLOnChange(Item)
	If Not IsBlankString(_URL) Then
		FindObjectByURL(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure _RecordSetNameOnChange(Item)
	vRefreshRecordSet();
EndProcedure

&AtClient
Procedure RefreshObjectData(Command)
	vRefreshObjectData();
EndProcedure

&AtClient
Procedure _FillBySample(Command)
	If mObjectRef = Undefined Then
		ShowMessageBox( , NSTR("ru = 'Не задан объект для обработки!';en = 'No object has been set for processing!'"), 20);
		Return;
	EndIf;

	pFullName = vGetFullNameMD(mObjectRef);
	OpenForm(pFullName + ".ChoiceForm", , , , , ,
		New NotifyDescription("pProcessFillingSampleSelection", ThisForm),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure pProcessFillingSampleSelection(ClosingResult, AddParam = Undefined) Export
	If ClosingResult <> Undefined Then
		pObjectRef = mObjectRef;
		mObjectRef = ClosingResult;

		Try
			vRefreshObjectData();
		Except
		EndTry;

		mObjectRef = pObjectRef;
		_UUID = mObjectRef.UUID();
		_URL  = vGetURL(mObjectRef);
	EndIf;
EndProcedure
&AtClient
Procedure WriteObject(Command)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан объект для записи!';en = 'Not set object for write!'"), 20);
		Return;
	EndIf;
	ShowQueryBox(New NotifyDescription("WriteObjectNext", ThisForm),
		NSTR("ru = 'Объект будет записан в базу. Продолжить?';en = 'Object will be writed to the database. Continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure _WriteObjectAsNew(Command)
	If mObjectRef = Undefined Then
		ShowMessageBox( , NSTR("ru = 'Не заданы данные объекта для записи!';en = 'Object data is not set for recording!'"), 20);
		Return;
	EndIf;
	ShowQueryBox(New NotifyDescription("WriteObjectAsNewNext", ThisForm),
		NSTR("ru = 'В базу будет записан New объект. Продолжить?';en = 'New object will be written to database. Continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure _WriteObjectAsNewWithSpecifiedUUID(Command)
	If mObjectRef = Undefined Then
		ShowMessageBox( , NSTR("ru = 'Не заданы данные объекта для записи!';en = 'Object data is not set for recording!'"), 20);
		Return;
	ElsIf IsBlankString(_UUID) Then
		ShowMessageBox( , NSTR("ru = 'Не задан UUID для нового объекта!';en = 'UUID for new object is not set!'"), 20);
		Return;
	EndIf;

		pText =	StrTemplate(NSTR("ru = 'В базу будет записан New объект с заданным UUID.
							 |UUID: %1
							 |
							 |Продолжить?';en = 'New object with  specified UUID will be written to database.
							 |UUID: %1
							 |
							 |Continue?'"),_UUID);
	ShowQueryBox(New NotifyDescription("WriteObjectAsNewNext", ThisForm, _UUID), pText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure _DeleteObject(Command)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( ,NSTR("ru = 'Не задан объект для удаления!';en = 'Object to delete is not specified!'") , 20);
		Return;
	EndIf;
	QueryText = NSTR("ru = 'Объект будет удален из базы!
				  |Никакие проверки производиться не будут (возможно появление битых ссылок)!
				  |
				  |Продолжить?';en = 'The object will be deleted from the database!
				  |No checks will be performed (broken  references may appear)!
				  |
				  |Continue?'");
	ShowQueryBox(New NotifyDescription("DeleteObjectNext", ThisForm), QueryText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure WriteObjectNext(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		If vWriteObject(False) Then
			RepresentDataChange(mObjectRef, DataChangeType.Update);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure WriteObjectAsNewNext(QueryResult, AdditionalParameters = Undefined) Export
	If QueryResult = DialogReturnCode.Yes Then
		If vWriteObject(True, AdditionalParameters) Then
			RepresentDataChange(mObjectRef, DataChangeType.Create);
			If AdditionalParameters <> Undefined Then
				RepresentDataChange(mObjectRef, DataChangeType.Update);
				//ShowMessageBox(,NStr("ru = 'Объект успешно записан!
				//|Для отображения новой ссылки необходимо перевыбрать объект.';
				//|en = 'Object successfully written.
				//|Reselect object to display new reference.'"), 20);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteObjectNext(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		pArray = New Array;
		pArray.Add(TypeOf(mObjectRef));
		pTypeDescription = New TypeDescription(pArray);

		If vDeleteObjectAtServer(mObjectRef) Then
			RepresentDataChange(mObjectRef, DataChangeType.Delete);
			mObjectRef = pTypeDescription.AdjustValue();
			RefreshObjectData(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _SwitchRecordsActivity(Command)
	For Each Row In _RecordSet Do
		Row.Active = Not Row.Active;
	EndDo;
EndProcedure

&AtClient
Procedure _RefreshRecordSet(Command)
	vRefreshRecordSet();
EndProcedure

&AtClient
Procedure _WriteRecordSet(Command)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан объект для записи движений';en = 'Object for write records is not specified'"), 20);
		Return;
	EndIf;
	If IsBlankString(_RecordSetName) Then
		ShowMessageBox( , NStr("ru = 'Не задан набор записей для сохранения';en = 'Recordset for save records is not set'"), 20);
		Return;
	EndIf;
	ShowQueryBox(New NotifyDescription("_WriteRecordSetNext", ThisForm),
		NSTR("ru = 'Набор записей будет записан в базу. Продолжить?';en = 'Recordset will be saved to database. Continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure _WriteRecordSetNext(QueryResult, AdditionalParameters) Export
	If QueryResult = DialogReturnCode.Yes Then
		vWriteRecordSet();
	EndIf;
EndProcedure

&AtClient
Procedure _ShowAllRecords(Command)
	If ValueIsFilled(mObjectRef) Then
		RegisterList = Items._RecordSetName.ChoiceList.Copy();
		If RegisterList.Count() <> 0 Then
			TDoc = vGenerateRecordsReport(mObjectRef, RegisterList, _ConfigurationAllowsAdditionalRecords);
			TDoc.Show(NSTR("ru = 'Наличие движений';en = 'Records existence'"));
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure FindObjectByUUID(Command)
	FindObjectByUUIDServer();
EndProcedure

&AtClient
Procedure FindObjectByType_UUID(Command)
	FindObjectByType_UUIDServer();
EndProcedure

&AtClient
Procedure FindObjectByURL(Command)
	Value = pFindObjectByURL(_URL);

	If mObjectRef <> Value Then
		mObjectRef = Value;
		RefreshObjectData(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure _OpenListForm(Command)
	If mObjectRef <> Undefined Then
		pFullName = vGetFullNameMD(mObjectRef);
		UT_CommonClient.ОpenDynamicList(pFullName);
	EndIf;
EndProcedure

&AtClient
Procedure OpenObject(Command)
	Value = Undefined;

	FI = ThisForm.CurrentItem;

	Name = vGetCurrentItemDataPath();
	If Not ValueIsFilled(Name) Then
		Return;
	EndIf;

	If TypeOf(FI) = Type("FormField") Then
		Value = ThisForm[Name];
	ElsIf TypeOf(FI) = Type("FormTable") Then
		CurData = FI.CurrentData;
		If CurData <> Undefined Then
			If FI.Name = "ObjectAttributes" Then
				Value = CurData.Value;
			Else
				Value = CurData[Name];
			EndIf;
		EndIf;
	EndIf;

	If ValueIsFilled(Value) Then
		If TypeOf(Value) = mTypeVS Then
			vShowValueVS(Value);

		ElsIf vIsMetadataObject(TypeOf(Value)) Then
			UT_CommonClient.EditObject(Value);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _ShowValueType(Command)
	_CurrentFieldValueType = "";

	Value = Undefined;

	FI = ThisForm.CurrentItem;

	Name = vGetCurrentItemDataPath();
	If Not ValueIsFilled(Name) Then
		Return;
	EndIf;

	If TypeOf(FI) = Type("FormField") Then
		Value = ThisForm[Name];
	ElsIf TypeOf(FI) = Type("FormTable") Then
		CurData = FI.CurrentData;
		If CurData <> Undefined Then
			If FI.Name = "ObjectAttributes" Then
				Value = CurData.Value;
			Else
				Value = CurData[Name];
			EndIf;
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
&AtServer
Function vGetCurrentItemDataPath()
	FI = ThisForm.CurrentItem;

	If TypeOf(FI) = Type("FormTable") Then
		CurField = FI.CurrentItem;
		If TypeOf(CurField) = Type("FormField") Then
			Value = CurField.DataPath;
			Pos = Find(Value, ".");
			If Pos <> 0 Then
				Value = Mid(Value, Pos + 1);
				If Find(Value, ".") = 0 Then
					Return Value;
				EndIf;
			EndIf;
		EndIf;
	ElsIf TypeOf(FI) = Type("FormField") Then
		Return FI.DataPath;
	EndIf;

	Return "";
EndFunction

&AtServer
Function vGetTableFieldProperties(Val FIName)
	pResult = New Structure("Cancel, Table, Field", True, "", "");

	FI = ThisForm.Items[FIName];

	If TypeOf(FI) = Type("FormTable") Then
		pResult.Insert("Table", FI.DataPath);

		CurField = FI.CurrentItem;
		If TypeOf(CurField) = Type("FormField") Then
			Value = CurField.DataPath;
			Pos = Find(Value, ".");
			If Pos <> 0 Then
				Value = Mid(Value, Pos + 1);
				pResult.Insert("Field", Value);
			EndIf;
		EndIf;
	EndIf;

	pResult.Cancel = (IsBlankString(pResult.Table) Or IsBlankString(pResult.Field));

	Return pResult;
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
Function vIsMetadataObject(Val Type)
	MDObject = Metadata.FindByType(Type);
	Return (MDObject <> Undefined And Not Metadata.Enums.Contains(MDObject));
EndFunction

&AtServerNoContext
Function vGetFullNameMD(Ref)
	Return Ref.Metadata().FullName();
EndFunction

&AtServerNoContext
Function pFindObjectByURL(Val URL)
	Pos1 = Find(URL, "e1cib/data/");
	Pos2 = Find(URL, "?ref=");

	If Pos1 = 0 Or Pos2 = 0 Then
		Return Undefined;
	EndIf;

	Try
		TypeName = Mid(URL, Pos1 + 11, Pos2 - Pos1 - 11);
		ValueTemplate = ValueToStringInternal(PredefinedValue(TypeName + ".EmptyRef"));
		RefValue = StrReplace(ValueTemplate, "00000000000000000000000000000000", Mid(URL, Pos2 + 5));
		Ref = ValueFromStringInternal(RefValue);
	Except
		Return Undefined;
	EndTry;

	Return Ref;
EndFunction

&AtServerNoContext
Function vGetRemoteObjectRef(Val pObjectNotFoundString)
	pResult = New Structure("Cancel, CancelCause, Ref", True, "");
	pResult.CancelCause = NSTR("ru = 'Неправильный формат строки!';en = 'Incorrect string format.'");

	If IsBlankString(pObjectNotFoundString) Then
		pObjectNotFoundString = "<Object no found> (769:b1390050568b35ac11e6e46fdd2c3861)";
	EndIf;

	pObjectNotFoundString = Mid(pObjectNotFoundString, StrFind(pObjectNotFoundString, "(") + 1);
	pObjectNotFoundString = StrReplace(pObjectNotFoundString, ")", "");
	pObjectNotFoundString = TrimAll(pObjectNotFoundString);

	Pos = StrFind(pObjectNotFoundString, ":");

	pType = Left(pObjectNotFoundString, Pos - 1);
	pString = Mid(pObjectNotFoundString, Pos + 1);

	Try
		pUUID = Mid(pString, 25, 8) + "-" + Mid(pString, 21, 4) + "-" + Mid(pString, 17, 4) + "-" + Mid(pString, 1,
			4) + "-" + Mid(pString, 5, 12);
		pUUID = New UUID(pUUID);

		pStructMDObjects = New Structure("ExchangePlans, Catalogs, Documents, ChartsOfCalculationTypes, ChartsOfCharacteristicTypes, ChartsOfAccounts, BusinessProcesses, Tasks");

		For Each pSection In pStructMDObjects Do
			For Each Item In Metadata[pSection.Key] Do
				pManager = Eval(pSection.Key + "[Item.Name]");
				pString = ValueToStringInternal(pManager.EmptyRef());
				Pos1 = StrFind(pString, ",", SearchDirection.FromEnd);
				Pos2 = StrFind(pString, ":");

				If Mid(pString, Pos1 + 1, Pos2 - Pos1 - 1) = pType Then
					pResult.Ref = pManager.GetRef(pUUID);
					pResult.Cancel = False;

					Return pResult;
				EndIf;
			EndDo;
		EndDo;
	Except
		pResult.CancelCause = pResult.CancelCause + Chars.LF + BriefErrorDescription(
			ErrorInfo());
		Return pResult;
	EndTry;

	Return pResult;
EndFunction
&AtServer
Procedure FindObjectByUUIDServer()
	If Not IsBlankString(_UUID) Then
		mObjectRef = Undefined;
		_ObjectType = "";

		Try
			UID = New UUID(_UUID);
		Except
				Message(NSTR("ru = 'Неправильное значение UUID';en = 'Incorrect UUID value.'"));
			Return;
		EndTry;

		If Not ValueIsFilled(UID) Then
			Return;
		EndIf;

		Struct = New Structure("Catalogs, Documents, ChartsOfCalculationTypes, ChartsOfCharacteristicTypes, ChartsOfAccounts, BusinessProcesses, Tasks");
		For Each Item In Struct Do
			ObjectsManager = Eval(Item.Key);
			For Each Manager In ObjectsManager Do
				X = Manager.GetRef(UID);
				If X.GetObject() <> Undefined Then
					mObjectRef = X;
					_ObjectType = mObjectRef.Metadata().FullName();
					vRefreshObjectData();
					Return;
				EndIf;
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure FindObjectByType_UUIDServer()
	If Not IsBlankString(_ObjectType) And Not IsBlankString(_UUID) Then
		Try
			UID = New UUID(_UUID);
		Except
				Message(NSTR("ru = 'Неправильное значение UUID';en = 'Incorrect UUID value.'"));
			Return;
		EndTry;

		TypeName = StrReplace(_ObjectType, ".", "Ref.");
		Try
			mObjectRef = XMLValue(Type(TypeName), _UUID);
			vRefreshObjectData();
		Except
		EndTry;
	EndIf;
EndProcedure
&AtServer
Function vCreateNewОбъект(MDObject)
	pName = MDObject.Name;

	If Metadata.Catalogs.Contains(MDObject) Or Metadata.ChartsOfCharacteristicTypes.Contains(MDObject) Then
		IsHierarchyFoldersAndItems = vIsHierarchyFoldersAndItems(MDObject);

		If IsHierarchyFoldersAndItems Then
			Array = ObjectAttributes.FindRows(New Structure("Name", "IsFolder"));
			pIsFolder = (Array.Count() = 1 And Array[0].IsFolder = True);
		Else
			pIsFolder = False;
		EndIf;

		If Metadata.Catalogs.Contains(MDObject) Then
			Manager = Catalogs;
		Else
			Manager = ChartsOfCharacteristicTypes;
		EndIf;

		NewObject = ?(pIsFolder, Manager[pName].CreateFolder(), Manager[pName].CreateItem());

	ElsIf Metadata.ExchangePlans.Contains(MDObject) Then
		NewObject = ExchangePlans[pName].CreateNode();

	ElsIf Metadata.Documents.Contains(MDObject) Then
		NewObject = Documents[pName].CreateDocument();

	ElsIf Metadata.ChartsOfAccounts.Contains(MDObject) Then
		NewObject = ChartsOfAccounts[pName].CreateAccount();

	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MDObject) Then
		NewObject = ChartsOfCalculationTypes[pName].CreateCalculationType();

	ElsIf Metadata.BusinessProcesses.Contains(MDObject) Then
		NewObject = BusinessProcesses[pName].CreateBusinessProcess();

	ElsIf Metadata.Tasks.Contains(MDObject) Then
		NewObject = Tasks[pName].CreateTask();

	Else
		NewObject = Undefined;
	EndIf;

	Return NewObject;
EndFunction

&AtServerNoContext
Function vSetNewObjectRef(pObject, Val pStringUUID)
	Try
		pUUID = New UUID(pStringUUID);
	Except
		Message(NSTR("ru = 'Неправильный формат UUID!';en = 'Incorrect UUID format.'"));
		Return False;
	EndTry;

	MDObject = pObject.Metadata();
	pName = MDObject.Name;

	If Metadata.Catalogs.Contains(MDObject) Then
		pManager = Catalogs[pName];

	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MDObject) Then
		pManager = ChartsOfCharacteristicTypes[pName];

	ElsIf Metadata.ExchangePlans.Contains(MDObject) Then
		pManager = ExchangePlans[pName];

	ElsIf Metadata.Documents.Contains(MDObject) Then
		pManager = Documents[pName];

	ElsIf Metadata.ChartsOfAccounts.Contains(MDObject) Then
		pManager = ChartsOfAccounts[pName];

	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MDObject) Then
		pManager = ChartsOfCalculationTypes[pName];

	ElsIf Metadata.BusinessProcesses.Contains(MDObject) Then
		pManager = BusinessProcesses[pName];

	ElsIf Metadata.Tasks.Contains(MDObject) Then
		pManager = Tasks[pName];

	Else
		Message(MDObject.FullName() + NSTR("ru = ' - данный тип не обрабатывается!';en = '- this type is not processed.'"));
		Return False;
	EndIf;

	Try
		pNewRef = pManager.GetRef(pUUID);
		pObject.SetNewObjectRef(pNewRef);
	Except
		Message(NSTR("ru = 'Не удалось установить ссылку для нового объекта!';en = 'Failed to set reference for new object.'"));
		Message(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;

	Return True;
EndFunction

&AtServerNoContext
Function vGetObjectRef(Val pRef)
	SetPrivilegedMode(True);

	pFullName = pRef.Metadata().FullName();

	Query = New Query;
	Query.SetParameter("Ref", pRef);

	Query.Text = "SELECT TOP 1
				 |	t.Ref AS Ref
				 |FROM
				 |	" + pFullName + " AS t
									|WHERE
									|	t.Ref = &Ref";

	Selection = Query.Execute().Select();

	Return ?(Selection.Next(), Selection.Ref, Undefined);
EndFunction

&AtServer
Function vWriteObject(Val AsNew = False, Val pStringUUID = Undefined)
	If AsNew Then
		If Not vCheckObjectExistence(mObjectRef) Then
			MDObject = mObjectRef.Metadata();
			ObjectToWrite = vCreateNewОбъект(MDObject);
			If ObjectToWrite = Undefined Then
				Message(NSTR("ru = 'Не удалось создать New объект типа ';en = 'Failed to create a new object of type.'") + MDObject.FullName());
				Return False;
			EndIf;
		Else
			ObjectToWrite = mObjectRef.Copy();
		EndIf;

		If pStringUUID <> Undefined Then
			If Not vSetNewObjectRef(ObjectToWrite, pStringUUID) Then
				Return False;
			EndIf;
		EndIf;
	Else
		ObjectToWrite = mObjectRef.GetObject();
	EndIf;

	If ObjectToWrite = Undefined Then
		Message(NSTR("ru = 'Не удалось получить объект для записи (битая ссылка)!';en = 'Failed to get object to write to (broken reference).'"));
		Return False;
	EndIf;

//	If _WriteInLoadingMode Then
//		ObjectToWrite.DataExchange.Load = True;
//	EndIf;

//	If _UseAdditionalPropertiesOnWrite И _AdditionalProperties.Count() <> 0 Then
//		Try
//			For Each Str In _AdditionalProperties Do
//				ObjectToWrite.AdditionalProperties.Insert(Str.Key, Str.Value);
//			EndDo;
//		Except
//			Message(NStr("ru = 'Ошибка при установке ДополнительныхСвойств: неправильное значение ключа '; en = 'AdditionalProperties set error: wrong key value.'""") + Str.Key + """");
//			Return False;
//		EndTry;
//	EndIf;

	Struct = New Structure("IsFolder");

	Try
		MDObject = ObjectToWrite.Metadata();
		IsHierarchyFoldersAndItems = vIsHierarchyFoldersAndItems(MDObject);
		IsFolder = ?(IsHierarchyFoldersAndItems, ObjectToWrite.IsFolder, False);

		For Each Str In ObjectAttributes Do
			If Not Struct.Property(Str.Name) And Str.Категория <> -1 Then
				If IsHierarchyFoldersAndItems Then
					If (IsFolder And Str.ForFolderAndItem = 1) Or (Not IsFolder And Str.ForFolderAndItem = -1) Then
						Continue;
					EndIf;
				EndIf;
				If ObjectToWrite[Str.Name] <> Str.Value Then
					ObjectToWrite[Str.Name] = Str.Value;
				EndIf;
			EndIf;
		EndDo;
		
		// 1C special tabular sections
		vWriteSpecialTabularSections(MDObject, ObjectToWrite);

		For Each TSItem In MDObject.TabularSections Do
			If IsHierarchyFoldersAndItems Then
				If (IsFolder And TSItem.Use
					= Metadata.ObjectProperties.AttributeUse.ForItem) Then
					Continue;
				EndIf;
				If (Not IsFolder And TSItem.Use
					= Metadata.ObjectProperties.AttributeUse.ForFolder) Then
					Continue;
				EndIf;
			EndIf;
			TabSection = ObjectToWrite[TSItem.Name];
			TabSection.Clear();
			TabName = _PrefixForNewItems + TSItem.Name;
			TabResult = FormAttributeToValue(TabName);
			TabSection.Load(TabResult);
		EndDo;

//		If _UseBeforeWriteProcedure And Not IsBlankString(_BeforeWriteProcedure) Then
//			If Not vExecuteBeforeWriteProcedure(ObjectToWrite, _BeforeWriteProcedure) Then
//				Return False;
//			EndIf;
//		EndIf;
//
//		ObjectToWrite.Write();

		If UT_Common.WriteObjectToDB(ObjectToWrite,
			UT_CommonClientServer.FormWriteSettings(ThisObject)) Then
			mObjectRef = ObjectToWrite.Ref;
			vRefreshObjectData();
			Return True;
		Else
			Return False;
		EndIf;
	Except
		Message(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
EndFunction

&AtServerNoContext
Function vCheckObjectExistence(Val pRef)
	If pRef = Undefined Or Not ValueIsFilled(pRef) Then
		Return False;
	EndIf;

	SetPrivilegedMode(True);

	pFullName = pRef.Metadata().FullName();

	Query = New Query;
	Query.SetParameter("Ref", pRef);

	Query.Текст = "SELECT TOP 1
				   |	t.Ref AS Ref
				   |FROM
				   |	" + pFullName + " AS t
										 |WHERE
										 |	t.Ref = &Ref";

	Return Not Query.Execute().IsEmpty();
EndFunction

&AtServer
Function vDeleteObjectAtServer(Val Ref)
	Try
		pObject = Ref.GetObject();
		If pObject = Undefined Then
			Return False;
		EndIf;

		If UT_Common.WriteObjectToDB(pObject, UT_CommonClientServer.FormWriteSettings(
			ThisObject), "DirectDeletion") Then

			Return True;
		Else
			Return False;
		EndIf;
	Except
		Message(NSTR("ru = 'Ошибка при удалении объекта:';en = 'Error while deleting object:'") + Chars.LF + BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
EndFunction

&AtServer
Procedure vRefreshRecordSet()
	_RecordSet.Clear();

	ChangeAttributes = (_RecordSetName <> _RecordSetNamePrevious);

	ArrayToCreate = New Array;
	ArrayToDelete = New Array;

	If ChangeAttributes Then
		TabResult = FormAttributeToValue("_RecordSet");
		For Each Column In TabResult.Columns Do
			ArrayToDelete.Add("_RecordSet." + Column.Name);
			Item = Items.Find("_RecordSet_" + Column.Name);
			If Item <> Undefined Then
				Items.Delete(Item);
			EndIf;
		EndDo;
	EndIf;

	If Not IsBlankString(_RecordSetName) Then
		Manager = vCreateRecordSetManager(_RecordSetName);
		If Manager = Undefined Then
			If ChangeAttributes Then
				ChangeAttributes(ArrayToCreate, ArrayToDelete);
			EndIf;
			Return;
		EndIf;

		Set = Manager.CreateRecordSet();
		Set.Filter.Recorder.Set(mObjectRef);
		Set.Read();

		TabResult = Set.Unload();

		Try
			If ChangeAttributes Then
				TypeVS = Type("ValueStorage");
				TypeTT = Type("Type");
				TypePT = Type("PointInTime");
				TypeUUID = Type("UUID");

				SpecColumnsStruct = New Structure("Recorder, PointInTime");

				For Each Column In TabResult.Columns Do
					//If SpecColumnsStruct.Property(Column.Name) Then
					//	Continue;
					//EndIf;

					If Column.ValueType.ContainsType(TypeVS) Then
						AttributeValueType = New TypeDescription;
					ElsIf Column.ValueType.ContainsType(TypeTT) Then
						AttributeValueType = New TypeDescription;
					ElsIf Column.ValueType.ContainsType(TypePT) Then
						AttributeValueType = New TypeDescription;
					ElsIf Column.ValueType.ContainsType(TypeUUID) Then
						AttributeValueType = vUUIDTypeDescription(Column.ValueType);
					Else
						AttributeValueType = Column.ValueType;
					EndIf;
					ArrayToCreate.Add(New FormAttribute(Column.Name, AttributeValueType, "_RecordSet",
						Column.Title, False));
				EndDo;

				ChangeAttributes(ArrayToCreate, ArrayToDelete);
			EndIf;

			ValueToFormAttribute(TabResult, "_RecordSet");

			If ChangeAttributes Then
				For Each Column In TabResult.Columns Do
					If SpecColumnsStruct.Property(Column.Name) Then
						Continue;
					EndIf;

					Item = ThisForm.Items.Add("_RecordSet_" + Column.Name, Type("FormField"),
						ThisForm.Items._RecordSet);
					Item.DataPath="_RecordSet." + Column.Name;
					Item.Type=FormFieldType.InputField;
					Item.AvailableTypes=Column.ValueType;
					Item.ClearButton = True;

					If Column.ValueType.ContainsType(TypeVS) Then // 033 version
						Item.ReadOnly = True;
					EndIf;
				EndDo;
			EndIf;

		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;

	ElsIf ChangeAttributes Then
		ChangeAttributes(ArrayToCreate, ArrayToDelete);
	EndIf;

	_RecordSetNamePrevious = _RecordSetName;
EndProcedure

&AtServer
Procedure vWriteRecordSet()
	If Not IsBlankString(_RecordSetName) And ValueIsFilled(mObjectRef) Then
		Manager = vCreateRecordSetManager(_RecordSetName);
		If Manager <> Undefined Then
			Set = Manager.CreateRecordSet();
			Set.Filter.Recorder.Set(mObjectRef);
			WriteParameters=UT_CommonClientServer.FormWriteSettings(ThisObject);

			If WriteParameters.WriteInLoadingMode Then
				Set.DataExchange.Load = True;
			EndIf;

			Try
				TabResult = FormAttributeToValue("_RecordSet");
				TabResult.FillValues(mObjectRef, "Recorder");
				Set.Load(TabResult);

				Set.Write(True);

				vRefreshRecordSet();
			Except
				Message(BriefErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function vCreateRecordSetManager(Val pRecordSetName)
	Pos = StrFind(pRecordSetName, ".");

	pRegisterType = Left(pRecordSetName, Pos - 1);
	pRegisterName = Mid(pRecordSetName, Pos + 1);

	Manager = Undefined;

	If pRegisterType = "InformationRegister" Then
		Manager = InformationRegisters[pRegisterName];
	ElsIf pRegisterType = "AccumulationRegister" Then
		Manager = AccumulationRegisters[pRegisterName];
	ElsIf pRegisterType = "CalculationRegister" Then
		Manager = CalculationRegisters[pRegisterName];
	ElsIf pRegisterType = "AccountingRegister" Then
		Manager = AccountingRegisters[pRegisterName];
	EndIf;

	Return Manager;
EndFunction
&AtServerNoContext
Function vUUIDTypeDescription(pTypeDescription)
	If pTypeDescription.Types().Count() = 1 Then
		pNewTypeDescription = New TypeDescription(pTypeDescription, "String");
	Else
		pNewTypeDescription = pTypeDescription;
	EndIf;

	Return pNewTypeDescription;
EndFunction

&AtServer
Procedure vClearObjectData()
	ObjectAttributes.Clear();
EndProcedure

&AtServer
Procedure vFillObjectData(CreateAttributes)
	Var NS;

	StructTypes = vGenerateTypesStructure();
	pTypeVS = Type("ValueStorage");

	If CreateAttributes Then
		ArrayToCreate = New Array;
		ArrayToDelete = New Array;
		
		// 1С special tabular sections
		StructSpecData = New Structure(vSpecialTabularSectionsList("ChartOfAccounts") + ", "
			+ vSpecialTabularSectionsList("ChartOfCalculationTypes"));

		If mPreviousObjectRef <> Undefined Then
			MDObject = mPreviousObjectRef.Metadata();
			For Each TSItem In MDObject.TabularSections Do
				TabName = _PrefixForNewItems + TSItem.Name;
				ArrayToDelete.Add(TabName);
			EndDo;
			
			// 1С special tabular sections
			For Each Item In StructSpecData Do
				TabName = _PrefixForNewItems + Item.Key;
				If vCheckFormAttributeExistence(TabName) Then
					ArrayToDelete.Add(TabName);
				EndIf;
			EndDo;
		EndIf;
		_RecordSetName = "";
		RecordSectionVisibility = False;
		If Not IsBlankString(_RecordSetNamePrevious) Then
			vRefreshRecordSet();
		EndIf;

		If mObjectRef <> Undefined Then
			MDObject = mObjectRef.Metadata();

			If Metadata.Documents.Contains(MDObject) Then
				If MDObject.RegisterRecords.Count() <> 0 Then
					RecordSectionVisibility = True;
					_PostingIsAllowed = (MDObject.Posting = Metadata.ObjectProperties.Posting.Allow);

					List = Items._RecordSetName.ChoiceList;
					List.Clear();
					For Each MDRegisterObject In MDObject.RegisterRecords Do
						List.Add(MDRegisterObject.FullName(), MDRegisterObject.Presentation());
					EndDo;

					List.SortByValue();
				EndIf;
			EndIf;
			
			// 1С special tabular sections
			vCreateSpecialTabularSections(MDObject, ArrayToCreate);

			For Each TSItem In MDObject.TabularSections Do
				TabName = _PrefixForNewItems + TSItem.Name;
				ArrayToCreate.Add(New FormAttribute(TabName, New TypeDescription("ValueTable"), ,
					TSItem.Name));
				For Each Item In TSItem.Attributes Do
					If Item.Type.ContainsType(pTypeVS) Then
						ArrayToCreate.Add(New FormAttribute(Item.Name, New TypeDescription, TabName, Item.Name));
					ElsIf Item.Type.ContainsType(StructTypes.mTypeUUID) Then
						ArrayToCreate.Add(New FormAttribute(Item.Name, vUUIDTypeDescription(Item.Type), TabName,
							Item.Name));
					Else
						ArrayToCreate.Add(New FormAttribute(Item.Name, Item.Type, TabName, Item.Name));
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		Items.DocumentRecordsPage.Visible = RecordSectionVisibility;

		If ArrayToCreate.Count() <> 0 Or ArrayToDelete.Count() <> 0 Then
			ChangeAttributes(ArrayToCreate, ArrayToDelete);
		EndIf;

		If ArrayToDelete.Count() <> 0 Then
			MDObject = mPreviousObjectRef.Metadata();
			
			// 1С special tabular sections
			For Each Item In StructSpecData Do
				TabName = _PrefixForNewItems + Item.Key;
				FI = Items.Find("Str" + TabName);
				If FI <> Undefined Then
					Items.Delete(FI);
				EndIf;
			EndDo;

			For Each TSItem In MDObject.TabularSections Do
				TabName = _PrefixForNewItems + TSItem.Name;
				Items.Delete(Items.Find("Str" + TabName));
			EndDo;
		EndIf;

		If ArrayToCreate.Count() <> 0 Then
			MDObject = mObjectRef.Metadata();
			
			// 1С special tabular sections
			vCreateSpecialTabularSections_Items(MDObject);

			For Each TSItem In MDObject.TabularSections Do
				TabName = _PrefixForNewItems + TSItem.Name;
				NewPage = Items.Add("Str" + TabName, Type("FormGroup"), Items.PagesGroup);
				NewPage.Type = FormGroupType.Page;
				NewPage.Title = TabularSectionPageTitle(TSItem.Name, mObjectRef[TSItem.Name]);
				NewPage.ToolTip = TSItem.Presentation();

				FIAppearanceTemplate = Items.ObjectAttributesDecoration;
				FI = Items.Add("Label_" + TabName, Type("FormDecoration"), NewPage);
				FI.Type = FormDecorationType.Label;
				FI.TextColor = FIAppearanceTemplate.TextColor;
				FI.Font = FIAppearanceTemplate.Font;
				FI.AutoMaxWidth = False;
				FI.HorizontalStretch = True;
				FI.Title = TSItem.Name + ": " + TSItem.Presentation();

				NewTable = Items.Add(TabName, Type("FormTable"), NewPage);
				NewTable.DataPath = TabName;

				For Each Item In TSItem.Attributes Do
					NewColumn = Items.Add(TabName + Item.Name, Type("FormField"), NewTable);
					NewColumn.Type = FormFieldType.InputField;
					NewColumn.DataPath = TabName + "." + Item.Name;
					NewColumn.ClearButton = True;
					If Not Item.Type.ContainsType(pTypeVS) Then
						//If Not Item.Type.ContainsType(StructTypes.mTypeUUID) Then
						//	NewColumn.AvailableTypes = Item.Type;
						//EndIf;
						NewColumn.AvailableTypes = Item.Type;
					Else
						NewColumn.ReadOnly = True;
					EndIf;
				EndDo;

				NewTable.SetAction("Selection", "TabularSectionSelection");
				NewTable.SetAction("OnEditEnd", "TabularSectionOnEditEnd");
				NewTable.SetAction("AfterDeleteRow", "TabularSectionAfterDeleteRow");
				
				// context menu
				ButtonGroup = Items.Add("Group_" + TabName, Type("FormGroup"), NewTable.ContextMenu);
				ButtonGroup.Type = FormGroupType.ButtonGroup;

				Button = Items.Add("_InsertUUID_" + TabName, Type("FormButton"),
					ButtonGroup);
				Button.Type = FormButtonType.CommandBarButton;
				Button.CommandName = "_InsertUUID";

				Button = Items.Add("OpenObject_" + TabName, Type("FormButton"), ButtonGroup);
				Button.Type = FormButtonType.CommandBarButton;
				Button.CommandName = "OpenObject";
			EndDo;
		EndIf;
	EndIf;	
	
	If mObjectRef <> Undefined Then
		FullName = mObjectRef.Metadata().FullName();
		ObjectType = Left(FullName, Find(FullName, ".") - 1);
		_ObjectType = FullName;

		_UUID = mObjectRef.UUID();
		_URL  = vGetURL(mObjectRef);

		MDObject = Metadata.FindByFullName(FullName);

		If MDObject <> Undefined Then

			IsHierarchyFoldersAndItems = vIsHierarchyFoldersAndItems(MDObject);

			vFillStandardAttributes(MDObject);
			
			For Each CommonAttribute In Metadata.CommonAttributes Do
				ContentItem = CommonAttribute.Content.Find(MDObject);
				If ContentItem <> Undefined
					And ContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use 
					Then
					
					NR = ObjectAttributes.Add();
					NR.Name = CommonAttribute.Name;
					NR.Presentation = CommonAttribute.Presentation();
					NR.Category = 1;
					NR.ValueType = CommonAttribute.Type;
					NR.TypeString = vTypeDescriptionToString(CommonAttribute.Type, StructTypes);
					NR.Value = mObjectRef[NR.Name];
					
				EndIf;	
			EndDo;

			For Each Item In MDObject.Attributes Do
				NR = ObjectAttributes.Add();
				NR.Name = Item.Name;
				NR.Presentation = Item.Presentation();
				NR.Category = 1;
				NR.ValueType = Item.Type;
				NR.TypeString = vTypeDescriptionToString(Item.Type, StructTypes);
				NR.Value = mObjectRef[Item.Name];

				If IsHierarchyFoldersAndItems Then
					If Item.Use = Metadata.ObjectProperties.AttributeUse.ForFolder Then
						NR.ForFolderAndItem = -1;
					ElsIf Item.Use = Metadata.ObjectProperties.AttributeUse.ForItem Then
						NR.ForFolderAndItem = 1;
					Else
						NR.ForFolderAndItem = 0;
					EndIf;
				EndIf;
			EndDo;

			If ObjectType = "ChartOfAccounts" Then
				For Each Item In MDObject.AccountingFlags Do
					NR = ObjectAttributes.Add();
					NR.Name = Item.Name;
					NR.Presentation = Item.Presentation();
					NR.Category = 1;
					NR.ValueType = Item.Type;
					NR.TypeString = vTypeDescriptionToString(Item.Type, StructTypes);
					NR.Value = mObjectRef[Item.Name];
				EndDo;
			EndIf;

			If ObjectType = "Task" Then
				For Each Item In MDObject.AddressingAttributes Do
					NR = ObjectAttributes.Add();
					NR.Name = Item.Name;
					NR.Presentation = Item.Presentation();
					NR.Category = 1;
					NR.ValueType = Item.Type;
					NR.TypeString = vTypeDescriptionToString(Item.Type, StructTypes);
					NR.Value = mObjectRef[Item.Name];
				EndDo;
			EndIf;

			ObjectAttributes.Sort("Category, Name");
			
			// 1С special tabular sections
			vFillSpecialTabularSections(MDObject);

			For Each TSItem Из MDObject.TabularSections Do
				TabName = _PrefixForNewItems + TSItem.Name;
				TabResult = mObjectRef[TSItem.Name].Unload();
				ValueToFormAttribute(TabResult, TabName);
			EndDo;
		EndIf;
	Else
		_ObjectType = "";
	EndIf;
EndProcedure
&AtServerNoContext
Function vSpecialTabularSectionsList(ObjectType)
	If ObjectType = "ChartOfAccounts" Then
		Return "ExtDimensionTypes";
	ElsIf ObjectType = "ChartOfCalculationTypes" Then
		Return "BaseCalculationTypes, LeadingCalculationTypes, DisplacingCalculationTypes";
	Else
		Return "";
	EndIf;
EndFunction

&AtServerNoContext
Function vCheckObjectAttributeExistence(Ref, AttributeName, ValueForNonExistent = -1)
	Struct = New Structure(AttributeName, ValueForNonExistent);
	FillPropertyValues(Struct, Ref);

	Return (Struct[AttributeName] <> ValueForNonExistent);
EndFunction

&AtServerNoContext
Function vGenerateRecordsReport(Val DocRef, Val RegisterList, Val pConfigurationAllowsAdditionalRecords)
	pQueryTableCount = 200;

	If pConfigurationAllowsAdditionalRecords Then
		pStruct = vFindAdditionalRegisters(DocRef);
		If pStruct.DataExists Then
			For Each Item In pStruct.AdditionalRegisters Do
				RegisterList.Add("+" + Item.Key, Item.Value);
			EndDo;
		EndIf;
	EndIf;

	Query = New Query;
	Query.SetParameter("Recorder", DocRef);

	QueryBeginText = "SELECT 0 AS Ind, 100000000 AS FieldA WHERE False";
	QueryText = QueryBeginText;

	TabResult = Undefined;
	Ind = -1;
	Counter = 0;

	For Each Item In RegisterList Do
		Ind = Ind + 1;
		Counter = Counter + 1;

		If Counter > pQueryTableCount Then
			Counter = 1;

			Query.Text = QueryText;
			TabData = Query.Execute().Unload();

			If TabResult = Undefined Then
				TabResult = TabData;
			Else
				For Each Str In TabData Do
					FillPropertyValues(TabResult.Add(), Str);
				EndDo;
			EndIf;

			QueryText = QueryBeginText;
		EndIf;

		If Left(Item.Value, 1) = "+" Then
			QueryText = QueryText + "
										  |UNION ALL
										  |SELECT " + Ind + ", COUNT(*) FROM " + Mid(Item.Value, 2)
				+ " AS t WHERE t.RecorderDocument = &Recorder HAVING COUNT(*) > 0";
		Else
			QueryText = QueryText + "
										  |UNION ALL
										  |SELECT " + Ind + ", COUNT(*) FROM " + Item.Value
				+ " AS t WHERE t.Recorder = &Recorder HAVING COUNT(*) > 0";
		EndIf;
	EndDo;

	Query.Text = QueryText;
	TabData = Query.Execute().Unload();

	If TabResult = Undefined Then
		TabResult = TabData;
	Else
		For Each Str In TabData Do
			FillPropertyValues(TabResult.Add(), Str);
		EndDo;
	EndIf;

	Line1 = New Line(SpreadsheetDocumentCellLineType.Solid, 2);

	SDoc = New SpreadsheetDocument;

	SDoc.Area( , 1, , 1).ColumnWidth = 2;
	SDoc.Area( , 2, , 2).ColumnWidth = 50;
	SDoc.Area( , 3, , 3).ColumnWidth = 50;
	SDoc.Area( , 4, , 4).ColumnWidth = 12;

	SDoc.Area(2, 2).Text = String(DocRef);
	SDoc.Area(2, 2, 2, 3).Outline( , , , Line1);

	SDoc.Area(4, 2).Text = NStr("ru = 'Имя регистра'; en = 'Register name'");
	SDoc.Area(4, 3).Text = NStr("ru = 'Представление'; en = 'Presentation'");
	SDoc.Area(4, 4).Text = NStr("ru = 'Число записей'; en = 'Count of records'");
	SDoc.Area(4, 2, 4, 4).BackColor = WebColors.LightGoldenRodYellow;
	SDoc.Area(4, 2, 4, 4).Outline(Line1, Line1, Line1, Line1);

	SN = 4;
	For Each Str In TabResult Do
		SN = SN + 1;
		pRegisterName = RegisterList[Str.Ind].Value;
		pIsAdditionalRecord = pConfigurationAllowsAdditionalRecords And (Left(pRegisterName, 1) = "+");

		SDoc.Area(SN, 2).Text = ?(pIsAdditionalRecord, Mid(pRegisterName, 2), pRegisterName);
		SDoc.Area(SN, 3).Text = RegisterList[Str.Ind].Presentation;
		SDoc.Area(SN, 4).Text = Str.FieldA;

		If pIsAdditionalRecord Then
			SDoc.Area(SN, 2, SN, 4).TextColor = WebColors.Green;
		EndIf;
	EndDo;

	SDoc.Area(4, 2, SN, 4).Outline(Line1, Line1, Line1, Line1);

	Return SDoc;
EndFunction

&AtClientAtServerNoContext
Function vGetURL(Ref)
	// Some platforms occurs an error while getting an URL for some objects (for example, accounts).

	Try
		Return GetURL(Ref);
	Except
		Return "";
	EndTry;
EndFunction

&AtServer
Function vCheckFormAttributeExistence(AttributeName, ValueForNonExistent = -1)
	Struct = New Structure(AttributeName, ValueForNonExistent);
	FillPropertyValues(Struct, ThisForm);

	Return (Struct[AttributeName] <> ValueForNonExistent);
EndFunction

&AtServer
Procedure vCreateSpecialTabularSections(Val MDObject, Val ArrayToCreate)
	FullName = MDObject.FullName();
	ObjectType = Left(FullName, Find(FullName, ".") - 1);

	TSList = vSpecialTabularSectionsList(ObjectType);
	If Not IsBlankString(TSList) Then
		Struct = New Structure(TSList);
		For Each Item In Struct Do
			TSName = Item.Key;
			If vCheckObjectAttributeExistence(mObjectRef, TSName) Then
				TabResult = mObjectRef[TSName].Unload();

				TabName = _PrefixForNewItems + TSName;
				ArrayToCreate.Add(New FormAttribute(TabName, New TypeDescription("ValueTable"), , TSName));
				For Each Item In TabResult.Columns Do
					If Item.Name <> "LineNumber" Then
						ArrayToCreate.Add(New FormAttribute(Item.Name, Item.ValueType, TabName, Item.Name));
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vCreateSpecialTabularSections_Items(Val MDObject)
	FullName = MDObject.FullName();
	ObjectType = Лев(FullName, Найти(FullName, ".") - 1);

	TSList = vSpecialTabularSectionsList(ObjectType);
	If Not IsBlankString(TSList) Then
		Struct = New Structure(TSList);
		For Each Item In Struct Do
			TSName = Item.Key;
			If vCheckObjectAttributeExistence(mObjectRef, TSName) Then
				TabResult = mObjectRef[TSName].Unload();

				TabName = _PrefixForNewItems + TSName;
				NewPage = Items.Add("Str" + TabName, Type("FormGroup"), Items.PagesGroup);
				NewPage.Type = FormGroupType.Page;
				NewPage.Title = TSName;

				NewTable = Items.Add(TabName, Type("FormTable"), NewPage);
				NewTable.DataPath = TabName;

				For Each Item In TabResult.Columns Do
					If Item.Name <> "LineNumber" Then
						NewColumn = Items.Add(TabName + Item.Name, Type("FormField"), NewTable);
						NewColumn.Type = FormFieldType.InputField;
						NewColumn.DataPath = TabName + "." + Item.Name;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillSpecialTabularSections(Val MDObject)
	FullName = MDObject.FullName();
	ObjectType = Left(FullName, Find(FullName, ".") - 1);

	TSList = vSpecialTabularSectionsList(ObjectType);
	If Not IsBlankString(TSList) Then
		Struct = New Structure(TSList);
		For Each Item In Struct Do
			TSName = Item.Key;
			TabName = _PrefixForNewItems + TSName;

			If vCheckObjectAttributeExistence(mObjectRef, TSName) Then
				TabResult = mObjectRef[TSName].Unload();
				ValueToFormAttribute(TabResult, TabName);
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vWriteSpecialTabularSections(MDObject, ObjectToWrite)
	FullName = MDObject.FullName();
	ObjectType = Left(FullName, Find(FullName, ".") - 1);

	TSList = vSpecialTabularSectionsList(ObjectType);
	If Not IsBlankString(TSList) Then
		Struct = New Structure(TSList);
		For Each Item In Struct Do
			TSName = Item.Key;
			TabName = _PrefixForNewItems + TSName;

			If vCheckObjectAttributeExistence(ObjectToWrite, TSName) Then
				TabSection = ObjectToWrite[TSName];
				TabSection.Clear();

				TabResult = FormAttributeToValue(TabName);
				TabSection.Load(TabResult);
			EndIf;
		EndDo;
	EndIf;
EndProcedure
&AtServerNoContext
Function vTypeDescriptionToString(TypeDescription, StructTypes)
	If TypeDescription = Undefined Then
		Return "";
	EndIf;

	Value = "";
	Types = TypeDescription.Types();
	For Each Item In Types Do
		TypeName = vStringTypeName(StructTypes, Item, TypeDescription);
		If Not IsBlankString(TypeName) Then
			Value = Value + "," + TypeName;
		EndIf;
	EndDo;

	Return Mid(Value, 2);
EndFunction

&AtServerNoContext
Function vStringTypeName(StructTypes, Type, TypeDescription)
	TypeName = "";

	If Type = StructTypes.mTypeNumber Then
		TypeName = "Number";
		If TypeDescription.NumberQualifiers.Digits <> 0 Then
			TypeName = TypeName + "(" + TypeDescription.NumberQualifiers.Digits + "."
				+ TypeDescription.NumberQualifiers.FractionDigits + ")";
		EndIf;
	ElsIf Type = StructTypes.mTypeString Then
		TypeName = "String";
		If TypeDescription.StringQualifiers.Length <> 0 Then
			TypeName = TypeName + "(" + ?(TypeDescription.StringQualifiers.AllowedLength = AllowedLength.Variable,
				"V", "F") + TypeDescription.StringQualifiers.Length + ")";
		EndIf;
	ElsIf Type = StructTypes.mTypeDate Then
		TypeName = ?(TypeDescription.DateQualifiers.DateFractions = DateFractions.Time, "Time", ?(
			TypeDescription.DateQualifiers.DateFractions = DateFractions.Date, "Date", "DateTime"));
	ElsIf Type = StructTypes.mTypeBoolean Then
		TypeName = "Boolean";
	ElsIf Type = StructTypes.mTypeBinaryData Then
		TypeName = "BinaryData";
	ElsIf Type = StructTypes.mTypeValueStorage Then
		TypeName = "ValueStorage";
	ElsIf Type = StructTypes.mTypeUUID Then
		TypeName = "UUID";
	Else
		MDObject = Metadata.FindByType(Type);
		If MDObject <> Undefined Then
			TypeName = MDObject.FullName();
		Else
			TypeName = String(Type);
		EndIf;
	EndIf;

	Return TypeName;
EndFunction

&AtServerNoContext
Function vGenerateTypesStructure()
	Result = New Structure;

	Result.Insert("mTypeString", Type("String"));
	Result.Insert("mTypeBoolean", Type("Boolean"));
	Result.Insert("mTypeNumber", Type("Number"));
	Result.Insert("mTypeDate", Type("Date"));
	Result.Insert("mTypeStructure", Type("Structure"));
	Result.Insert("mTypeValueStorage", Type("ValueStorage"));
	Result.Insert("mTypeBinaryData", Type("BinaryData"));
	Result.Insert("mTypeValueTree", Type("ValueTree"));
	Result.Insert("mTypeMetadataObject", Type("MetadataObject"));
	Result.Insert("mTypeUUID", Type("UUID"));

	Return Result;
EndFunction

&AtServerNoContext
Function vIsHierarchyFoldersAndItems(MDObject)
	Struct = New Structure("Hierarchical, HierarchyType");
	FillPropertyValues(Struct, MDObject);
	Return (Struct.Hierarchical = True And Struct.HierarchyType
		= Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems);
EndFunction

&AtServerNoContext
Function vStringTypeDescription(StringLength, VariableLength = True)
	Return New TypeDescription("String", , , , New StringQualifiers(StringLength, ?(VariableLength,
		AllowedLength.Variable, AllowedLength.Fixed)));
EndFunction

&AtServerNoContext
Function vNumberTypeDescription(DigitsCount, FractionDigitsCount = 0)
	Return New TypeDescription("Number", , , New NumberQualifiers(DigitsCount, FractionDigitsCount));
EndFunction

&AtServerNoContext
Function vCodeTypeDescription(CodeType, CodeLength, CodeAllowedLength)
	Return ?(String(CodeType) = "Number", vNumberTypeDescription(CodeLength), vStringTypeDescription(CodeLength, ?(String(
		CodeAllowedLength) = "Fixed", False, True)));
EndFunction

&AtServerNoContext
Function vObjectNumberTypeDescription(NumberType, NumberLength)
	Return ?(String(NumberType) = "Number", vNumberTypeDescription(NumberLength), vStringTypeDescription(NumberLength, False));
EndFunction

&AtServerNoContext
Function vOwnerTypeDescription(MDCollection)
	TypeArray = New Array;
	For Each Item In MDCollection Do
		TypeName = Item.FullName();
		TypeName = StrReplace(TypeName, ".", "Ref.");
		TypeArray.Add(Type(TypeName));
	EndDo;

	Return New TypeDescription(TypeArray);
EndFunction

&AtServer
Procedure vFillStandardAttributes(MDObject)
	Var NR;

	AttributeList = "Code, Number, Date, Posted, DeletionMark, IsFolder, Description, Owner, Parent, BusinessProcess, Executed, Completed, Started, SentNo, ReceivedNo, ThisNode";
	PropertyList = "CodeType, NumberType, CodeLength, CodeAllowedLength, NumberLength, DescriptionLength, Hierarchical, HierarchyType, Owners";

	StructAttributes = New Structure(AttributeList);
	StructProperties = New Structure(PropertyList);

	FillPropertyValues(StructProperties, MDObject);
	FillPropertyValues(StructAttributes, mObjectRef);

	If Metadata.ExchangePlans.Contains(MDObject) Then
		If StructProperties.CodeType = Undefined Then
			StructProperties.CodeType = "String";
		EndIf;
	EndIf;

	If Metadata.ChartsOfAccounts.Contains(MDObject) Then
		If StructProperties.CodeType = Undefined Then
			StructProperties.CodeType = "String";
		EndIf;
	EndIf;

	If StructProperties.NumberType <> Undefined And ValueIsFilled(StructProperties.NumberLength) Then
		NR = ObjectAttributes.Add();
		NR.Name = "Number";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = vObjectNumberTypeDescription(StructProperties.NumberType, StructProperties.NumberLength);
		NR.Value = StructAttributes.Number;
	EndIf;

	If StructProperties.CodeType <> Undefined And ValueIsFilled(StructProperties.CodeLength) Then
		NR = ObjectAttributes.Add();
		NR.Name = "Code";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = vCodeTypeDescription(StructProperties.CodeType, StructProperties.CodeLength,
			StructProperties.CodeAllowedLength);
		NR.Value = StructAttributes.Code;
	EndIf;

	If StructAttributes.Description <> Undefined And ValueIsFilled(StructProperties.DescriptionLength) Then
		NR = ObjectAttributes.Add();
		NR.Name = "Description";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = vStringTypeDescription(StructProperties.DescriptionLength);
		NR.Value = StructAttributes.Description;
	EndIf;

	If StructAttributes.Date <> Undefined Then
		NR = ObjectAttributes.Add();
		NR.Name = "Date";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Date", , , , , New DateQualifiers(DateFractions.DateTime));
		NR.Value = StructAttributes.Date;
	EndIf;

	If StructProperties.Hierarchical = True Then
		NR = ObjectAttributes.Add();
		NR.Name = "Parent";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		Array = New Array;
		Array.Add(TypeOf(mObjectRef));
		NR.ValueType = New TypeDescription(Array);
		NR.Value = StructAttributes.Parent;
	EndIf;

	If StructAttributes.DeletionMark <> Undefined Then
		NR = ObjectAttributes.Add();
		NR.Name = "DeletionMark";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.DeletionMark;
	EndIf;

	If StructAttributes.IsFolder <> Undefined And StructProperties.Hierarchical = True And StructProperties.HierarchyType
		= Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		NR = ObjectAttributes.Add();
		NR.Name = "IsFolder";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.IsFolder;
	EndIf;

	If StructProperties.Owners <> Undefined И StructProperties.Owners.Count() <> 0 Then
		NR = ObjectAttributes.Add();
		NR.Name = "Owner";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = vOwnerTypeDescription(StructProperties.Owners);
		NR.Value = StructAttributes.Owner;
	EndIf;

	If Metadata.Documents.Contains(MDObject) Then
		NR = ObjectAttributes.Add();
		NR.Name = "Posted";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.Posted;
	EndIf;

	If Metadata.Tasks.Contains(MDObject) Then
		NR = ObjectAttributes.Add();
		NR.Name = "BusinessProcess";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		Array = New Array;
		Array.Add(TypeOf(StructAttributes.BusinessProcess));
		NR.ValueType = New TypeDescription(Array);
		NR.Value = StructAttributes.BusinessProcess;

		NR = ObjectAttributes.Add();
		NR.Name = "Executed";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.Executed;
	EndIf;

	If Metadata.BusinessProcesses.Contains(MDObject) Then
		NR = ObjectAttributes.Add();
		NR.Name = "Started";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.Started;

		NR = ObjectAttributes.Add();
		NR.Name = "Completed";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.Completed;
	EndIf;

	If Metadata.ExchangePlans.Contains(MDObject) Then
		NR.Name = "SentNo";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Number");
		NR.Value = StructAttributes.SentNo;

		NR = ObjectAttributes.Add();
		NR.Name = "ReceivedNo";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Number");
		NR.Value = StructAttributes.ReceivedNo;

		NR = ObjectAttributes.Add();
		NR.Name = "ThisNode";
		NR.Presentation = NR.Name;
		NR.Category = 0;
		NR.ValueType = New TypeDescription("Boolean");
		NR.Value = StructAttributes.ThisNode;
	EndIf;
EndProcedure
&AtServer
Procedure vRefreshObjectData()
	If mObjectRef <> Undefined Then
		Array = New Array;
		Array.Add(TypeOf(mObjectRef));
		Items.mObjectRef.TypeRestriction = New TypeDescription(Array);
	EndIf;

	CreateAttributes = (TypeOf(mObjectRef) <> TypeOf(mPreviousObjectRef));

	If _ConfigurationAllowsAdditionalRecords And CreateAttributes And ValueIsFilled(mObjectRef) Then
		pStruct = vFindAdditionalRegisters(mObjectRef);
		Items._OpenAdditionalRecordsEditor.Visible = pStruct.DataExists;
	EndIf;

	vClearObjectData();
	vFillObjectData(CreateAttributes);
	mPreviousObjectRef = mObjectRef;
	vRefreshRecordSet();
	If ValueIsFilled(mObjectRef) Then
		UT_CreationDate = UT_Common.ReferenceCreationDate(mObjectRef);
	EndIf;
EndProcedure

&AtClient
Procedure ObjectAttributesOnActivateRow(Item)
	Return;
	CurrData = Items.ObjectAttributes.CurrentData;
	If CurrData <> Undefined Then
		Items.ObjectAttributesValue.TypeRestriction = CurrData.ValueType;
		//Items.ObjectAttributesValue.AvailableTypes = CurrData.ValueType;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectAttributesBeforeRowChange(Item, Cancel)
	CurrData = Item.CurrentData;
	If CurrData <> Undefined Then
		Value = CurrData["Value"];
		
		//If TypeOf(Value) = mTypeVS Or TypeOf(Value) = mTypeUUID Then
		If TypeOf(Value) = mTypeVS Then
			Cancel = True;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectAttributesSelection(Item, SelectedRow, Field, StandardProcessing)
	If Field.Name = "ObjectAttributesValue" Then
		CurrData = Item.CurrentData;
		If CurrData <> Undefined Then
			Value = CurrData["Value"];

			If TypeOf(Value) = mTypeVS Then
				StandardProcessing = False;
				vShowValueVS(Value);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure TabularSectionSelection(Item, SelectedRow, Field, StandardProcessing)
	CurrData = Item.CurrentData;
	If CurrData <> Undefined Then
		ColumnName = Сред(Field.Name, StrLen(Item.Name) + 1);
		Value = CurrData[ColumnName];

		If TypeOf(Value) = mTypeVS Then
			StandardProcessing = False;
			vShowValueVS(Value);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure TabularSectionOnEditEnd(Item, NewItem, CancelEdit)
	If CancelEdit Then
		Return;
	EndIf;
	
	RefreshTabularSectionPageTitle(Item);
EndProcedure


&AtClient
Procedure TabularSectionAfterDeleteRow(Item)
	RefreshTabularSectionPageTitle(Item);
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
//	If Settings["_AdditionalProperties"] = Undefined Then
//		AdditionalProperties.Clear();
//	EndIf;
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	//If ValueIsFilled(mObjectRef) Then
	If mObjectRef <> Undefined Then
		vRefreshObjectData();
	EndIf;
EndProcedure

&AtClient
Procedure _OpenRecordsEditor(Command)
	ParamStruct = New Structure("FormsPath, mObjectRef", FormsPath, mObjectRef);
	Try
		OpenForm("DataProcessor.UT_ObjectsAttributesEditor.Form.RecordsEditorForm", ParamStruct, , mObjectRef);
	Except
		Message(NSTR("ru = 'Не найдена форма ""RecordsEditorForm""!';en = 'RecordsEditorForm form not found.'"));
	EndTry;
EndProcedure

&AtClient
Procedure _OpenAdditionalRecordsEditor(Command)
	ParamStruct = New Structure("FormsPath, mObjectRef", FormsPath, mObjectRef);
	Try
		OpenForm("DataProcessor.UT_ObjectsAttributesEditor.Form.RecordsEditorAdditionalForm", ParamStruct, ,
			mObjectRef);
	Except
		Message(NSTR("ru = 'Не найдена форма ""RecordsEditorAdditionalForm""!';en = 'RecordsEditorAdditionalForm form not found.'"));
	EndTry;
EndProcedure
&AtClient
Procedure _FillCurrentColumnData(Command)
	CurrPage = Items.PagesGroup.CurrentPage;
	If CurrPage.Name = "ObjectAttributesPage" Or CurrPage.Name = "SettingsPage" Then
		Return;
	EndIf;

	CurrTab = Undefined;
	For Each Item In CurrPage.ChildItems Do
		If TypeOf(Item) = Type("FormTable") Then
			CurrTab = Item;
			Break;
		EndIf;
	EndDo;

	pValue = _ValueToFill;

	If CurrTab <> Undefined Then
		StructData = vGetTableFieldProperties(CurrTab.Name);
		If Not StructData.Cancel Then
			pTable = ThisForm[StructData.Table];
			pField = StructData.Field;

			If pTable.Count() <> 0 Then

				If _ProcessOnlySelectedRows Then
					For Each Item In CurrTab.SelectedRows Do
						Str = pTable.FindByID(Item);
						Str[pField] = pValue;
					EndDo;
				Else
					For Each Str In pTable Do
						Str[pField] = pValue;
					EndDo;
				EndIf;

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


// documents
&AtClient
Procedure _PostDocument(Command)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан документ для обработки';en = 'No document set for processing.'"), 20);
		Return;
	EndIf;

	If Not _PostingIsAllowed Then
		ShowMessageBox( , NSTR("ru = 'Проведение документов данного типа запрещено!';en = 'Posting of this type documents is prohibited.'"), 20);
		Return;
	EndIf;

	ShowQueryBox(New NotifyDescription("vPostDocumentNext", ThisForm),
		NSTR("ru = 'Документ будет перепроведен. Продолжить?';en = 'Document will be reposted. Do you want to continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure _UndoPosting(Command)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан документ для обработки';en = 'No document set for processing.'"), 20);
		Return;
	EndIf;

	If Not _PostingIsAllowed Then
		ShowMessageBox( , NSTR("ru = 'Проведение документов данного типа запрещено!';en = 'Posting of this type documents is prohibited.'"), 20);
		Return;
	EndIf;

	ShowQueryBox(New NotifyDescription("vUndoPostingNext", ThisForm),
		NSTR("ru = 'Для документа будет выполнена отмена проведения. Продолжить?';en = 'Undo posting will be performed for document. Do you want to continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure vPostDocumentNext(QueryResult, AdditionalParameters = Undefined) Export
	If QueryResult = DialogReturnCode.Yes Then
		pStruct = New Structure;

//		If _UseAdditionalPropertiesOnWrite And _AdditionalProperties.Count() <> 0 Then
//			pStruct.AdditionalProperties = New Structure;
//			Try
//				For Each Str In _AdditionalProperties Do
//					pStruct.AdditionalProperties.Insert(Str.Key, Str.Value);
//				EndDo;
//			Except
//				Message(NStr("ru = 'Ошибка при установке ДополнительныхСвойств: неправильное значение ключа ""'; en = 'AdditionalProperties setting error: wrong key value.'") + Str.Key + """");
//				Return;
//			EndTry;
//		EndIf;

//		If _UseBeforeWriteProcedure And Not IsBlankString(_BeforeWriteProcedure) Then
//			pStruct.BeforeWriteProcedure = _BeforeWriteProcedure;
//		EndIf;

		If vPostUndoPostingDocument(mObjectRef, True, pStruct) Then
			RefreshObjectData(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure vUndoPostingNext(РезультатВопроса, ДопПараметры = Undefined) Export
	If РезультатВопроса = DialogReturnCode.Да Then
		If vPostUndoPostingDocument(mObjectRef, False) Then
			RefreshObjectData(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function vPostUndoPostingDocument(Ref, Post = True, pParamStruct = Undefined)
	Mode = ?(Post, DocumentWriteMode.Posting, DocumentWriteMode.UndoPosting);

	DocObject = Ref.GetObject();

	Return UT_Common.WriteObjectToDB(DocObject, UT_CommonClientServer.FormWriteSettings(ThisObject), , Mode);

EndFunction


// loading / unloading object via XML
&AtClient
Function vGetXMLFileDialog(Open = True, FilePath = "")
	Dialog = New FileDialog(?(Open, FileDialogMode.Open, FileDialogMode.Save));

	Dialog.FullFileName = FilePath;
	Dialog.Title  = NSTR("ru = 'Файл данных XML';en = 'XML data file'");
	Dialog.Filter     = NSTR("ru = 'Файлы данных XML (*.xml)|*.xml|Все файлы (*.*)|*.*';en = 'XML data files (*.xml)|*.xml|All files (*.*)|*.*'");
	Dialog.Extension = "xml";

	Return Dialog;
EndFunction

&AtClient
Procedure _UnloadRecordSet(Command)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан объект для выгрузки движений';en = 'Object for records unloading is not set.'"), 20);
		Return;
	EndIf;
	If IsBlankString(_RecordSetName) Then
		ShowMessageBox( ,NSTR("ru = 'Не задан набор записей для выгрузки';en = 'Recordset for unloading is not specified.'") , 20);
		Return;
	EndIf;

	vUnloadObject(4);
EndProcedure

&AtClient
Procedure _UnloadObject(Command)
	vUnloadObject(1);
EndProcedure

&AtClient
Procedure _UnloadObjectWithRecords(Command)
	vUnloadObject(2);
EndProcedure

&AtClient
Procedure _UnloadObjectRecords(Command)
	vUnloadObject(3);
EndProcedure

&AtClient
Procedure _LoadXMLData(Command)
	Dialog = vGetXMLFileDialog(True);
	Dialog.Show(New NotifyDescription("vLoadDataFromFile", ThisForm));
EndProcedure

&AtClient
Procedure vLoadDataFromFile(SelectedFiles, AddParam = Undefined) Export
	If SelectedFiles <> Undefined Then
		pFileName = SelectedFiles[0];
		TDoc = New TextDocument;
		TDoc.BeginReading(New NotifyDescription("pAfterFinishReadFile", ThisForm, TDoc), pFileName, "UTF-8");
	EndIf;
EndProcedure

&AtClient
Procedure pAfterFinishReadFile(TDoc) Export
	If TypeOf(TDoc) = Type("TextDocument") Then
		XMLString = TDoc.GetText();
		If Not IsBlankString(XMLString) Then
			vLoadXMLData(XMLString);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure vUnloadObject(pMode)
	If Not ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан документ для выгрузки';en = 'No document specified for unloading.'"), 20);
		Return;
	EndIf;

	Dialog = vGetXMLFileDialog(False);

	If pMode = 1 Then
		Dialog.FullFileName = NSTR("ru = 'Объект';en = 'Object'");
	ElsIf pMode = 2 Then
		Dialog.FullFileName =NSTR("ru = 'Объект (с движениями)';en = 'Object (with records)'") ;
	ElsIf pMode = 3 Then
		Dialog.FullFileName =NSTR("ru = 'Объект (движения)';en = 'Object (records)'") ;
	ElsIf pMode = 4 Then
		Dialog.FullFileName = _RecordSetName;
	EndIf;

	Dialog.Show(New NotifyDescription("vUnloadObjectToFile", ThisForm, pMode));
EndProcedure

&AtClient
Procedure vUnloadObjectToFile(SelectedFiles, pMode = Undefined) Export
	If SelectedFiles <> Undefined Then
		XMLString = vGenerateXMLUnloading(mObjectRef, pMode, _RecordSetName);
		If Not IsBlankString(XMLString) Then
			pFileName = SelectedFiles[0];
			TDoc = New TextDocument;
			TDoc.SetText(XMLString);
			TDoc.BeginWriting(New NotifyDescription("vAfterFinishWriteFile", ThisForm), pFileName, "UTF-8");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure vAfterFinishWriteFile(Result, AddParam = Undefined) Export
	If Result = True Then
		ShowMessageBox( , NSTR("ru = 'Данные выгружены в файл';en = 'Data is unloaded to file.'"), 20);
	EndIf;
EndProcedure
&AtServerNoContext
Function vGenerateXMLUnloading(Val pRef, Val pMode, Val pRecordSetName = "")

	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-8");

	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("_1CV8DtUD", "http://www.1c.ru/V8/1CV8DtUD/");
	XMLWriter.WriteNamespaceMapping("V8Exch", "http://www.1c.ru/V8/1CV8DtUD/");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	XMLWriter.WriteNamespaceMapping("core", "http://v8.1c.ru/data");

	XMLWriter.WriteNamespaceMapping("v8", "http://v8.1c.ru/8.1/data/enterprise/current-config");
	XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");

	XMLWriter.WriteStartElement("V8Exch:Data");
	If pMode = 4 Then
		Manager = vCreateRecordSetManager(pRecordSetName);
		If Manager <> Undefined Then
			Set = Manager.CreateRecordSet();
			Set.Filter.Recorder.Set(pRef);
			Set.Read();

			XDTOSerializer.WriteXML(XMLWriter, Set);
		EndIf;
	Else
		Try
			pObject = pRef.GetObject();
		Except
			Message(BriefErrorDescription(ErrorInfo()), MessageStatus.Important);
			Message(NSTR("ru = 'Выгрузка данных не выполнена!';en = 'Failed to unload data.'"), MessageStatus.Important);
			Return "";
		EndTry;

		If pMode = 1 Or pMode = 2 Then
			XDTOSerializer.WriteXML(XMLWriter, pObject, XMLTypeAssignment.Explicit);
		EndIf;

		If pMode = 2 Or pMode = 3 Then
			pMDObject = pObject.Metadata();
			If Metadata.Documents.Contains(pMDObject) Then
				For Each Record In pObject.RegisterRecords Do
					Record.Read();
					XDTOSerializer.WriteXML(XMLWriter, Record);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	XMLWriter.WriteEndElement(); // V8Exc:Data
	XMLWriter.WriteEndElement(); // V8Exc:_1CV8DtUD

	XMLString = XMLWriter.Close();

	Return XMLString;
EndFunction

&AtServerNoContext
Procedure vLoadXMLData(Val XMLString)
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);

	Message(NSTR("ru = 'Загрузка данных стартована';en = 'Data loading started.'"));

	pFormatError = False;
	pStringIncorrectFormat = NStr("ru = 'Неверный формат файла выгрузки';en = 'Incorrect unload file format.'");

	Try
		// format checking
		If pFormatError Or Not XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.StartElement
			Or XMLReader.LocalName <> "_1CV8DtUD" Or XMLReader.NamespaceURI
			<> "http://www.1c.ru/V8/1CV8DtUD/" Then

			pFormatError = True;
		EndIf;

		If pFormatError Or Not XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.StartElement
			Or XMLReader.LocalName <> "Data" Then

			pFormatError = True;
		EndIf;

		If pFormatError Or Not XMLReader.Read() Then

			pFormatError = True;
		EndIf;

	Except
		pFormatError = True;
	EndTry;

	If pFormatError Then
		Message(pStringIncorrectFormat, MessageStatus.Important);
		XMLReader.Close();
		Return;
	EndIf;
	
	
	// data reading
	BeginTransaction();

	While XDTOSerializer.CanReadXML(XMLReader) Do
		Try
			pObject = XDTOSerializer.ReadXML(XMLReader);
			pObject.DataExchange.Load = True;
			pObject.Write();
		Except
			pFormatError = True;
			Message(BriefErrorDescription(ErrorInfo()), MessageStatus.Important);
			Break;
		EndTry;
	EndDo;

	If pFormatError Then
		RollbackTransaction();

		XMLReader.Close();
		Message(NSTR("ru = 'Загрузка данных прервана';en = 'Data loading aborted.'"), MessageStatus.Important);
		Return;
	Else
		CommitTransaction();
	EndIf;
	
	
	// format checking
	If pFormatError Or XMLReader.NodeType <> XMLNodeType.EndElement Or XMLReader.LocalName <> "Data" Then

		pFormatError = True;
	EndIf;

	If pFormatError Or Not XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.EndElement
		Or XMLReader.LocalName <> "_1CV8DtUD" Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then

		pFormatError = True;
	EndIf;

	If pFormatError Then
		Message(pStringIncorrectFormat, MessageStatus.Important);
		XMLReader.Close();
		Message(NSTR("ru = 'Загрузка данных завершена';en = 'Data loading completed.'"));
		Return;
	EndIf;

	XMLReader.Close();
	Message(NSTR("ru = 'Загрузка данных завершена';en = 'Data loading completed.'"));
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
		pMDAttribute = MDItem.Attributes.Find("DocumentRecorder");
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
Procedure _InsertUUID(Command)
	CurrTable = ThisForm.CurrentItem;

	If CurrTable.Name = "_ValueToFill" Then
		pStruct = New Structure("Table", CurrTable.Name);
		ShowInputString(New NotifyDescription("vProcessInputUUID", ThisForm, pStruct), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор'; en = 'Enter a unique identifier (UUID)'"), , False);
		Return;
	ElsIf TypeOf(CurrTable) <> Type("FormTable") Then
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

		If CurrTable.Name = "ObjectAttributes" Then
			pStruct.Insert("Field", "Value");
//		ElsIf CurrTable.Name = "_AdditionalProperties" Then
//			pStruct.Insert("Field", "Value");
		Else
			pStruct.Insert("Field", Mid(CurrColumn.Name, StrLen(CurrTable.Name) + 1));
		EndIf;

		ShowInputString(New NotifyDescription("vProcessInputUUID", ThisForm, pStruct), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор'; en = 'Enter a unique identifier (UUID)'"), , False);
	EndIf;
EndProcedure

&AtClient
Procedure vProcessInputUUID(String, pStruct = Undefined) Export
	If String <> Undefined And Not IsBlankString(String) Then
		Try
			pValue = New UUID(String);
			mLastUUID = String;
		Except
			ShowMessageBox( , NSTR("ru = 'Значение не может быть преобразовано в Уникальный идентификатор!'; en = 'The value cannot be converted to a Unique identifier (UUID).'"), 20);
			Return;
		EndTry;

		If pStruct.Table = "_ValueToFill" Then
			_ValueToFill = pValue;
		Else
			CurrData = Items[pStruct.Table].CurrentData;
			If CurrData <> Undefined Then
				CurrData[pStruct.Field] = pValue;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

// Tabular section page title.
// 
// Parameters:
//  TSName - String - a tabular section name.
//  TSTable - ValueTable - a table containing a tabular section data.
// 
// Return value:
//  String
&AtClientAtServerNoContext
Function TabularSectionPageTitle(TSName, TSTable)
	If TSTable.Count() =0 Then
		Return TSName;
	Else
		Return TSName + " ("+TSTable.Count()+")";
	EndIf;			
EndFunction

&AtClient
Procedure RefreshTabularSectionPageTitle(TabularSectionItem)
	If Not StrStartsWith(TabularSectionItem.Name, _PrefixForNewItems) Then
		Return;
	EndIf;

	TableName = Mid(TabularSectionItem.Name, StrLen(_PrefixForNewItems) + 1);
	Items["Стр" + TabularSectionItem.Name].Title = TabularSectionPageTitle(TableName,
		ThisObject[TabularSectionItem.Name]);

EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_SetWriteSettings(Command)
	UT_CommonClient.EditWriteSettings(ThisObject);
EndProcedure