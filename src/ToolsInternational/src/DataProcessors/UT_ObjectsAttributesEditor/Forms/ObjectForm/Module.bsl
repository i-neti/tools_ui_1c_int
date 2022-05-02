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
	If mObjectRef = Undefined Then
		StandardProcessing = False;
		ParamStruct = New Structure("CloseOnOwnerClose", True);
		OpenForm("CommonForm.UT_MetadataSelectionForm", ParamStruct, Item, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		Array = New Array;
		Array.Add(TypeOf(mObjectRef));
		Item.TypeRestriction = New TypeDescription(Array);

		If _UseNonStandardFormToSelect Then
			StandardProcessing = False;
			pFullName = vGetFullNameMD(mObjectRef);
			ParametersStruct = New Structure("MetadataObjectName", pFullName);
			ParametersStruct.Insert("ChoiceMode", True);
			Try
				OpenForm("DataProcessor.UT_DynamicList.Form", ParamStruct, Item, True, , , ,
					FormWindowOpeningMode.LockOwnerWindow);
			Except
				pErrorDescription = ErrorDescription();
				StandardProcessing = True;
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure mObjectRefOnChange(Item)
	ThisForm.UniqueKey = mObjectRef;

	_URL = "";

	If mObjectRef <> Undefined Then
		_UUID = "";
	EndIf;

	RefreshObjectData(Undefined);
EndProcedure

&AtClient
Procedure mObjectRefClearing(Item, StandardProcessing)
	Item.TypeRestriction = New TypeDescription;
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
			UUID = New UUID(_UUID);
		Except
				Message(NSTR("ru = 'Неправильное значение UUID';en = 'Incorrect UUID value.'"));
			Return;
		EndTry;

		If Not ValueIsFilled(UUID) Then
			Return;
		EndIf;

		Struct = New Structure("Catalogs, Documents, ChartsOfCalculationTypes, ChartsOfCharacteristicTypes, ChartsOfAccounts, BusinessProcesses, Tasks");
		For Each Item In Struct Do
			ObjectsManager = Eval(Item.Key);
			For Each Manager In ObjectsManager Do
				X = Manager.GetRef(UUID);
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
			UUID = New UUID(_UUID);
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
		If Not vCheckObjectExisting(mObjectRef) Then
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
		
		// специализированные табличные части 1С
		вЗаписатьСпециализированныеТабличныеЧасти(MDObject, ОбъектДляЗаписи);

		For Each ЭлемТЧ Из MDObject.ТабличныеЧасти Do
			If ЭтоИерархияГруппИЭлементов Then
				If (ЭтоГруппа И ЭлемТЧ.Использование
					= Метаданные.СвойстваОбъектов.ИспользованиеРеквизита.ДляЭлемента) Then
					Продолжить;
				EndIf;
				If (Не ЭтоГруппа И ЭлемТЧ.Использование
					= Метаданные.СвойстваОбъектов.ИспользованиеРеквизита.ДляГруппы) Then
					Продолжить;
				EndIf;
			EndIf;
			ТабЧасть = ОбъектДляЗаписи[ЭлемТЧ.Name];
			ТабЧасть.Очистить();
			ИмяТаб = _PrefixForNewItems + ЭлемТЧ.Name;
			ТабРезультат = FormAttributeToValue(ИмяТаб);
			ТабЧасть.Загрузить(ТабРезультат);
		EndDo;

//		If _ИспользоватьПроцедуруПередЗаписью И Не IsBlankString(_ProcedureПередЗаписью) Then
//			If Не вВыполнитьПроцедуруПередЗаписью(ОбъектДляЗаписи, _ProcedureПередЗаписью) Then
//				Return False;
//			EndIf;
//		EndIf;
//
//		ОбъектДляЗаписи.Записать();

		If UT_Common.WriteObjectToDB(ОбъектДляЗаписи,
			UT_CommonClientServer.FormWriteSettings(ЭтотОбъект)) Then
			mObjectRef = ОбъектДляЗаписи.Ссылка;
			vRefreshObjectData();
			Return True;
		Else
			Return False;
		EndIf;
	Except
		Сообщить(КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
		Return False;
	EndTry;
EndFunction

&AtServerБезКонтекста
Function vCheckObjectExisting(Знач пСсылка)
	If пСсылка = Undefined Или Не ValueIsFilled(пСсылка) Then
		Return False;
	EndIf;

	УстановитьПривилегированныйРежим(True);

	пПолноеИмя = пСсылка.Метаданные().ПолноеИмя();

	Запрос = New Запрос;
	Запрос.УстановитьПараметр("Ссылка", пСсылка);

	Запрос.Текст = "ВЫБРАТЬ ПЕРВЫЕ 1
				   |	т.Ссылка КАК Ссылка
				   |ИЗ
				   |	" + пПолноеИмя + " КАК т
										 |ГДЕ
										 |	т.Ссылка = &Ссылка";

	Return Не Запрос.Выполнить().Пустой();
EndFunction

&AtServer
Function vDeleteObjectAtServer(Знач Ссылка)
	Try
		пОбъект = Ссылка.ПолучитьОбъект();
		If пОбъект = Undefined Then
			Return False;
		EndIf;

//		If ЗаписьВРежимеЗагрузки Then
//			пОбъект.ОбменДанными.Загрузка = True;
//		EndIf;

		If UT_Common.WriteObjectToDB(пОбъект, UT_CommonClientServer.FormWriteSettings(
			ЭтотОбъект)) Then
//		пОбъект.Удалить();

			Return True;
		Else
			Return False;
		EndIf;
	Except
		Сообщить(NSTR("ru = 'Ошибка при удалении объекта:';en = 'Error while deleting object:'") + Символы.ПС + КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
		Return False;
	EndTry;
EndFunction

&AtServer
Procedure vRefreshRecordSet()
	_RecordSet.Очистить();

	НадоИзменитьРеквизиты = (_RecordSetName <> _ИмяНабораЗаписейПредыдущий);

	ArrayКСозданию = New Array;
	ArrayКУдалению = New Array;

	If НадоИзменитьРеквизиты Then
		ТабРезультат = FormAttributeToValue("_RecordSet");
		For Each Колонка Из ТабРезультат.Колонки Do
			ArrayКУдалению.Добавить("_RecordSet." + Колонка.Name);
			Элем = Items.Найти("_НаборЗаписей_" + Колонка.Name);
			If Элем <> Undefined Then
				Items.Удалить(Элем);
			EndIf;
		EndDo;
	EndIf;

	If Не IsBlankString(_RecordSetName) Then
		Менеджер = вСоздатьМенеджерНабораЗаписей(_RecordSetName);
		If Менеджер = Undefined Then
			If НадоИзменитьРеквизиты Then
				ИзменитьРеквизиты(ArrayКСозданию, ArrayКУдалению);
			EndIf;
			Return;
		EndIf;

		Набор = Менеджер.СоздатьНаборЗаписей();
		Набор.Отбор.Регистратор.Установить(mObjectRef);
		Набор.Прочитать();

		ТабРезультат = Набор.Выгрузить();

		Try
			If НадоИзменитьРеквизиты Then
				ТипХЗ = Тип("ХранилищеЗначения");
				ТипТТ = Тип("Тип");
				ТипМВ = Тип("МоментВремени");
				ТипUUID = Тип("УникальныйИдентификатор");

				СтрукСпецКолонки = New Structure("Регистратор, МоментВремени");

				For Each Колонка Из ТабРезультат.Колонки Do
					//If СтрукСпецКолонки.Свойство(Колонка.Name) Then
					//	Продолжить;
					//EndIf;

					If Колонка.ValueType.СодержитТип(ТипХЗ) Then
						ТипЗначенияРеквизита = New ОписаниеТипов;
					ElsIf Колонка.ValueType.СодержитТип(ТипТТ) Then
						ТипЗначенияРеквизита = New ОписаниеТипов;
					ElsIf Колонка.ValueType.СодержитТип(ТипМВ) Then
						ТипЗначенияРеквизита = New ОписаниеТипов;
					ElsIf Колонка.ValueType.СодержитТип(ТипUUID) Then
						ТипЗначенияРеквизита = вОписаниеТиповДляUUID(Колонка.ТипЗначения);
					Else
						ТипЗначенияРеквизита = Колонка.ValueType;
					EndIf;
					ArrayКСозданию.Добавить(New РеквизитФормы(Колонка.Name, ТипЗначенияРеквизита, "_RecordSet",
						Колонка.Заголовок, False));
				EndDo;

				ИзменитьРеквизиты(ArrayКСозданию, ArrayКУдалению);
			EndIf;

			ЗначениеВРеквизитФормы(ТабРезультат, "_RecordSet");

			If НадоИзменитьРеквизиты Then
				For Each Колонка Из ТабРезультат.Колонки Do
					If СтрукСпецКолонки.Свойство(Колонка.Имя) Then
						Продолжить;
					EndIf;

					Элем = ThisForm.Items.Добавить("_НаборЗаписей_" + Колонка.Name, Тип("ПолеФормы"),
						ThisForm.Items._RecordSet);
					Элем.ПутьКДанным="_RecordSet." + Колонка.Name;
					Элем.Вид=ВидПоляФормы.ПолеВвода;
					Элем.ДоступныеТипы=Колонка.ValueType;
					Элем.КнопкаОчистки = True;

					If Колонка.ValueType.СодержитТип(ТипХЗ) Then // версия 033
						Элем.ТолькоПросмотр = True;
					EndIf;
				EndDo;
			EndIf;

		Except
			Сообщить(КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
		EndTry;

	ElsIf НадоИзменитьРеквизиты Then
		ИзменитьРеквизиты(ArrayКСозданию, ArrayКУдалению);
	EndIf;

	_ИмяНабораЗаписейПредыдущий = _RecordSetName;
EndProcedure

&AtServer
Procedure vWriteRecordSet()
	If Не IsBlankString(_RecordSetName) И ValueIsFilled(mObjectRef) Then
		Менеджер = вСоздатьМенеджерНабораЗаписей(_RecordSetName);
		If Менеджер <> Undefined Then
			Набор = Менеджер.СоздатьНаборЗаписей();
			Набор.Отбор.Регистратор.Установить(mObjectRef);
			ПараметрыЗаписи=UT_CommonClientServer.FormWriteSettings(ЭтотОбъект);

			If ПараметрыЗаписи.ЗаписьВРежимеЗагрузки Then
				Набор.ОбменДанными.Загрузка = True;
			EndIf;

			Try
				ТабРезультат = FormAttributeToValue("_RecordSet");
				ТабРезультат.ЗаполнитьЗначения(mObjectRef, "Регистратор");
				Набор.Загрузить(ТабРезультат);

				Набор.Записать(True);

				vRefreshRecordSet();
			Except
				Сообщить(КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtServerБезКонтекста
Function вСоздатьМенеджерНабораЗаписей(Знач пИмяНабораЗаписей)
	Поз = СтрНайти(пИмяНабораЗаписей, ".");

	пВидРегистра = Лев(пИмяНабораЗаписей, Поз - 1);
	пИмяРегистра = Сред(пИмяНабораЗаписей, Поз + 1);

	Менеджер = Undefined;

	If пВидРегистра = "РегистрСведений" Then
		Менеджер = РегистрыСведений[пИмяРегистра];
	ElsIf пВидРегистра = "РегистрНакопления" Then
		Менеджер = РегистрыНакопления[пИмяРегистра];
	ElsIf пВидРегистра = "РегистрРасчета" Then
		Менеджер = РегистрыРасчета[пИмяРегистра];
	ElsIf пВидРегистра = "РегистрБухгалтерии" Then
		Менеджер = РегистрыБухгалтерии[пИмяРегистра];
	EndIf;

	Return Менеджер;
EndFunction
&AtServerБезКонтекста
Function вОписаниеТиповДляUUID(пОписаниеТипов)
	If пОписаниеТипов.Типы().Количество() = 1 Then
		пНовоеОписаниеТипов = New ОписаниеТипов(пОписаниеТипов, "Строка");
	Else
		пНовоеОписаниеТипов = пОписаниеТипов;
	EndIf;

	Return пНовоеОписаниеТипов;
EndFunction

&AtServer
Procedure вОчиститьДанныеОбъекта()
	ObjectAttributes.Очистить();
EndProcedure

&AtServer
Procedure вЗаполнитьДанныеОбъекта(НадоСоздаватьРеквизиты)
	Перем НС;

	СтрукТипы = вСформироватьСтруктуруТипов();
	пТипХЗ = Тип("ХранилищеЗначения");

	If НадоСоздаватьРеквизиты Then
		ArrayКСозданию = New Array;
		ArrayКУдалению = New Array;
		
		// специализированные табличные части 1С
		СтрукСпецДанные = New Structure(вПереченьСпециализированныхТабличныхЧастей("ПланСчетов") + ", "
			+ вПереченьСпециализированныхТабличныхЧастей("ПланВидовРасчета"));

		If mPreviousObjectRef <> Undefined Then
			ОбъектМД = mPreviousObjectRef.Метаданные();
			For Each ЭлемТЧ Из ОбъектМД.ТабличныеЧасти Do
				ИмяТаб = _PrefixForNewItems + ЭлемТЧ.Name;
				ArrayКУдалению.Добавить(ИмяТаб);
			EndDo;
			
			// специализированные табличные части 1С
			For Each Элем Из СтрукСпецДанные Do
				ИмяТаб = _PrefixForNewItems + Элем.Ключ;
				If вПроверитьНаличиеРеквизитаФормы(ИмяТаб) Then
					ArrayКУдалению.Добавить(ИмяТаб);
				EndIf;
			EndDo;
		EndIf;
		_RecordSetName = "";
		VisibleРазделаДвижения = False;
		If Не IsBlankString(_ИмяНабораЗаписейПредыдущий) Then
			vRefreshRecordSet();
		EndIf;

		If mObjectRef <> Undefined Then
			ОбъектМД = mObjectRef.Метаданные();

			If Метаданные.Документы.Содержит(ОбъектМД) Then
				If ОбъектМД.Движения.Количество() <> 0 Then
					VisibleРазделаДвижения = True;
					_ПроведениеРазрешено = (ОбъектМД.Проведение = Метаданные.СвойстваОбъектов.Проведение.Разрешить);

					Список = Items._RecordSetName.СписокВыбора;
					Список.Очистить();
					For Each ОбъектРегистрМД Из ОбъектМД.Движения Do
						Список.Добавить(ОбъектРегистрМД.ПолноеИмя(), ОбъектРегистрМД.Представление());
					EndDo;

					Список.СортироватьПоЗначению();
				EndIf;
			EndIf;
			
			// специализированные табличные части 1С
			вСоздатьСпециализированныеТабличныеЧасти(ОбъектМД, ArrayКСозданию);

			For Each ЭлемТЧ Из ОбъектМД.ТабличныеЧасти Do
				ИмяТаб = _PrefixForNewItems + ЭлемТЧ.Name;
				ArrayКСозданию.Добавить(New РеквизитФормы(ИмяТаб, New ОписаниеТипов("ТаблицаЗначений"), ,
					ЭлемТЧ.Name));
				For Each Элем Из ЭлемТЧ.Реквизиты Do
					If Элем.Тип.СодержитТип(пТипХЗ) Then
						ArrayКСозданию.Добавить(New РеквизитФормы(Элем.Name, New ОписаниеТипов, ИмяТаб, Элем.Name));
					ElsIf Элем.Тип.СодержитТип(СтрукТипы.мТипУникальныйИдентификатор) Then
						ArrayКСозданию.Добавить(New РеквизитФормы(Элем.Name, вОписаниеТиповДляUUID(Элем.Тип), ИмяТаб,
							Элем.Name));
					Else
						ArrayКСозданию.Добавить(New РеквизитФормы(Элем.Name, Элем.Тип, ИмяТаб, Элем.Name));
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		Items.DocumentRecordsPage.Visible = VisibleРазделаДвижения;

		If ArrayКСозданию.Количество() <> 0 Или ArrayКУдалению.Количество() <> 0 Then
			ИзменитьРеквизиты(ArrayКСозданию, ArrayКУдалению);
		EndIf;

		If ArrayКУдалению.Количество() <> 0 Then
			ОбъектМД = mPreviousObjectRef.Метаданные();
			
			// специализированные табличные части 1С
			For Each Элем Из СтрукСпецДанные Do
				ИмяТаб = _PrefixForNewItems + Элем.Ключ;
				ЭФ = Items.Найти("Стр" + ИмяТаб);
				If ЭФ <> Undefined Then
					Items.Удалить(ЭФ);
				EndIf;
			EndDo;

			For Each ЭлемТЧ Из ОбъектМД.ТабличныеЧасти Do
				ИмяТаб = _PrefixForNewItems + ЭлемТЧ.Name;
				Items.Удалить(Items.Найти("Стр" + ИмяТаб));
			EndDo;
		EndIf;

		If ArrayКСозданию.Количество() <> 0 Then
			ОбъектМД = mObjectRef.Метаданные();
			
			// специализированные табличные части 1С
			вСоздатьСпециализированныеТабличныеЧасти_Items(ОбъектМД);

			For Each ЭлемТЧ Из ОбъектМД.ТабличныеЧасти Do
				ИмяТаб = _PrefixForNewItems + ЭлемТЧ.Name;
				НоваяСтраница = Items.Добавить("Стр" + ИмяТаб, Тип("ГруппаФормы"), Items.ГруппаСтраницы);
				НоваяСтраница.Вид = ВидГруппыФормы.Страница;
				НоваяСтраница.Заголовок = ЭлемТЧ.Name;
				НоваяСтраница.Подсказка = ЭлемТЧ.Представление();

				ШаблонОформленияЭФ = Items.ObjectAttributesDecoration;
				ЭФ = Items.Добавить("Надпись_" + ИмяТаб, Тип("ДекорацияФормы"), НоваяСтраница);
				ЭФ.Вид = ВидДекорацииФормы.Надпись;
				ЭФ.ЦветТекста = ШаблонОформленияЭФ.ЦветТекста;
				ЭФ.Шрифт = ШаблонОформленияЭФ.Шрифт;
				ЭФ.АвтоМаксимальнаяШирина = False;
				ЭФ.РастягиватьПоГоризонтали = True;
				ЭФ.Заголовок = ЭлемТЧ.Name + ": " + ЭлемТЧ.Представление();

				НоваяТаблица = Items.Добавить(ИмяТаб, Тип("ТаблицаФормы"), НоваяСтраница);
				НоваяТаблица.ПутьКДанным = ИмяТаб;

				For Each Элем Из ЭлемТЧ.Реквизиты Do
					НоваяКолонка = Items.Добавить(ИмяТаб + Элем.Name, Тип("ПолеФормы"), НоваяТаблица);
					НоваяКолонка.Вид = ВидПоляФормы.ПолеВвода;
					НоваяКолонка.ПутьКДанным = ИмяТаб + "." + Элем.Name;
					НоваяКолонка.КнопкаОчистки = True;
					If Не Элем.Тип.СодержитТип(пТипХЗ) Then
						//If не Элем.Тип.СодержитТип(СтрукТипы.мТипУникальныйИдентификатор) Then
						//	НоваяКолонка.ДоступныеТипы = Элем.Тип;
						//EndIf;
						НоваяКолонка.ДоступныеТипы = Элем.Тип;
					Else
						НоваяКолонка.ТолькоПросмотр = True;
					EndIf;
				EndDo;

				НоваяТаблица.УстановитьДействие("Выбор", "ТабличнаяЧастьВыбор");
				
				// контекстное меню
				ГруппаКнопок = Items.Добавить("Группа_" + ИмяТаб, Тип("ГруппаФормы"), НоваяТаблица.КонтекстноеМеню);
				ГруппаКнопок.Вид = ВидГруппыФормы.ГруппаКнопок;

				Кнопка = Items.Добавить("_ВставитьУникальныйИдентификатор_" + ИмяТаб, Тип("КнопкаФормы"),
					ГруппаКнопок);
				Кнопка.Вид = ВидКнопкиФормы.КнопкаКоманднойПанели;
				Кнопка.ИмяКоманды = "_InsertUUID";

				Кнопка = Items.Добавить("ОткрытьОбъект_" + ИмяТаб, Тип("КнопкаФормы"), ГруппаКнопок);
				Кнопка.Вид = ВидКнопкиФормы.КнопкаКоманднойПанели;
				Кнопка.ИмяКоманды = "OpenObject";
			EndDo;
		EndIf;
	EndIf;	
	
	If mObjectRef <> Undefined Then
		ПолноеИмя = mObjectRef.Метаданные().ПолноеИмя();
		ВидОбъекта = Лев(ПолноеИмя, Найти(ПолноеИмя, ".") - 1);
		_ObjectType = ПолноеИмя;

		_UUID = mObjectRef.УникальныйИдентификатор();
		_URL  = vGetURL(mObjectRef);

		ОбъектМД = Метаданные.НайтиПоПолномуИмени(ПолноеИмя);

		If ОбъектМД <> Undefined Then

			ЭтоИерархияГруппИЭлементов = vIsHierarchyFoldersAndItems(ОбъектМД);

			вЗаполнитьСтандартныеРеквизиты(ОбъектМД);
			
			For Each ОбщийРеквизит Из Метаданные.ОбщиеРеквизиты Do
				ЭлементСостава = ОбщийРеквизит.Состав.Найти(ОбъектМД);
				If ЭлементСостава <> Undefined
					И ЭлементСостава.Использование = Метаданные.СвойстваОбъектов.ИспользованиеОбщегоРеквизита.Использовать 
					Then
					
					НС = ObjectAttributes.Добавить();
					НС.Name = ОбщийРеквизит.Name;
					НС.Presentation = ОбщийРеквизит.Представление();
					НС.Категория = 1;
					НС.ValueType = ОбщийРеквизит.Тип;
					НС.TypeString = вОписаниеТиповВСтроку(ОбщийРеквизит.Тип, СтрукТипы);
					НС.Value = mObjectRef[НС.Name];
					
				EndIf;	
			EndDo;

			For Each Элем Из ОбъектМД.Реквизиты Do
				НС = ObjectAttributes.Добавить();
				НС.Name = Элем.Name;
				НС.Presentation = Элем.Представление();
				НС.Категория = 1;
				НС.ValueType = Элем.Тип;
				НС.TypeString = вОписаниеТиповВСтроку(Элем.Тип, СтрукТипы);
				НС.Value = mObjectRef[Элем.Name];

				If ЭтоИерархияГруппИЭлементов Then
					If Элем.Использование = Метаданные.СвойстваОбъектов.ИспользованиеРеквизита.ДляГруппы Then
						НС.ДляГруппыИлиЭлемента = -1;
					ElsIf Элем.Использование = Метаданные.СвойстваОбъектов.ИспользованиеРеквизита.ДляЭлемента Then
						НС.ДляГруппыИлиЭлемента = 1;
					Else
						НС.ДляГруппыИлиЭлемента = 0;
					EndIf;
				EndIf;
			EndDo;

			If ВидОбъекта = "ПланСчетов" Then
				For Each Элем Из ОбъектМД.ПризнакиУчета Do
					НС = ObjectAttributes.Добавить();
					НС.Name = Элем.Name;
					НС.Presentation = Элем.Представление();
					НС.Категория = 1;
					НС.ValueType = Элем.Тип;
					НС.TypeString = вОписаниеТиповВСтроку(Элем.Тип, СтрукТипы);
					НС.Value = mObjectRef[Элем.Name];
				EndDo;
			EndIf;

			If ВидОбъекта = "Задача" Then
				For Each Элем Из ОбъектМД.РеквизитыАдресации Do
					НС = ObjectAttributes.Добавить();
					НС.Name = Элем.Name;
					НС.Presentation = Элем.Представление();
					НС.Категория = 1;
					НС.ValueType = Элем.Тип;
					НС.TypeString = вОписаниеТиповВСтроку(Элем.Тип, СтрукТипы);
					НС.Value = mObjectRef[Элем.Name];
				EndDo;
			EndIf;

			ObjectAttributes.Сортировать("Категория, Name");
			
			// специализированные табличные части 1С
			вЗаполнитьСпециализированныеТабличныеЧасти(ОбъектМД);

			For Each ЭлемТЧ Из ОбъектМД.ТабличныеЧасти Do
				ИмяТаб = _PrefixForNewItems + ЭлемТЧ.Name;
				ТабРезультат = mObjectRef[ЭлемТЧ.Name].Выгрузить();
				ЗначениеВРеквизитФормы(ТабРезультат, ИмяТаб);
			EndDo;
		EndIf;
	Else
		_ObjectType = "";
	EndIf;
EndProcedure
&AtServerБезКонтекста
Function вПереченьСпециализированныхТабличныхЧастей(ВидОбъекта)
	If ВидОбъекта = "ПланСчетов" Then
		Return "ВидыСубконто";
	ElsIf ВидОбъекта = "ПланВидовРасчета" Then
		Return "БазовыеВидыРасчета, ВедущиеВидыРасчета, ВытесняющиеВидыРасчета";
	Else
		Return "";
	EndIf;
EndFunction

&AtServerБезКонтекста
Function вПроверитьНаличиеРеквизитаОбъекта(Ссылка, ИмяРеквизита, ЗначениеДляОтсутствующего = -1)
	Струк = New Structure(ИмяРеквизита, ЗначениеДляОтсутствующего);
	ЗаполнитьЗначенияСвойств(Струк, Ссылка);

	Return (Струк[ИмяРеквизита] <> ЗначениеДляОтсутствующего);
EndFunction

&AtServerБезКонтекста
Function vGenerateRecordsReport(Знач ДокСсылка, Знач СписокРегистров, Знач пКонфигурацияДопускаетДопДвижения)
	пЧислоТаблицВЗапросе = 200;

	If пКонфигурацияДопускаетДопДвижения Then
		пСтрук = вОпределитьДополнительныеРегистрыДокумента(ДокСсылка);
		If пСтрук.ЕстьДанные Then
			For Each Элем Из пСтрук.ДополнительныеРегистры Do
				СписокРегистров.Добавить("+" + Элем.Ключ, Элем.Значение);
			EndDo;
		EndIf;
	EndIf;

	Запрос = New Запрос;
	Запрос.УстановитьПараметр("Регистратор", ДокСсылка);

	ТекстНачалаЗапроса = "ВЫБРАТЬ 0 КАК Инд, 100000000 КАК ПолеА ГДЕ False";
	ТекстЗапроса = ТекстНачалаЗапроса;

	ТабРезультат = Undefined;
	Инд = -1;
	Сч = 0;

	For Each Элем Из СписокРегистров Do
		Инд = Инд + 1;
		Сч = Сч + 1;

		If Сч > пЧислоТаблицВЗапросе Then
			Сч = 1;

			Запрос.Текст = ТекстЗапроса;
			ТабДанные = Запрос.Выполнить().Выгрузить();

			If ТабРезультат = Undefined Then
				ТабРезультат = ТабДанные;
			Else
				For Each Стр Из ТабДанные Do
					ЗаполнитьЗначенияСвойств(ТабРезультат.Добавить(), Стр);
				EndDo;
			EndIf;

			ТекстЗапроса = ТекстНачалаЗапроса;
		EndIf;

		If Лев(Элем.Значение, 1) = "+" Then
			ТекстЗапроса = ТекстЗапроса + "
										  |ОБЪЕДИНИТЬ ВСЕ
										  |ВЫБРАТЬ " + Инд + ", КОЛИЧЕСТВО(*) ИЗ " + Сред(Элем.Значение, 2)
				+ " КАК т ГДЕ т.ДокументРегистратор = &Регистратор ИМЕЮЩИЕ КОЛИЧЕСТВО(*) > 0";
		Else
			ТекстЗапроса = ТекстЗапроса + "
										  |ОБЪЕДИНИТЬ ВСЕ
										  |ВЫБРАТЬ " + Инд + ", КОЛИЧЕСТВО(*) ИЗ " + Элем.Value
				+ " КАК т ГДЕ т.Регистратор = &Регистратор ИМЕЮЩИЕ КОЛИЧЕСТВО(*) > 0";
		EndIf;
	EndDo;

	Запрос.Текст = ТекстЗапроса;
	ТабДанные = Запрос.Выполнить().Выгрузить();

	If ТабРезультат = Undefined Then
		ТабРезультат = ТабДанные;
	Else
		For Each Стр Из ТабДанные Do
			ЗаполнитьЗначенияСвойств(ТабРезультат.Добавить(), Стр);
		EndDo;
	EndIf;

	Линия1 = New Линия(ТипЛинииЯчейкиТабличногоДокумента.Сплошная, 2);

	ТДок = New ТабличныйДокумент;

	ТДок.Область( , 1, , 1).ШиринаКолонки = 2;
	ТДок.Область( , 2, , 2).ШиринаКолонки = 50;
	ТДок.Область( , 3, , 3).ШиринаКолонки = 50;
	ТДок.Область( , 4, , 4).ШиринаКолонки = 12;

	ТДок.Область(2, 2).Текст = Строка(ДокСсылка);
	ТДок.Область(2, 2, 2, 3).Обвести( , , , Линия1);

	ТДок.Область(4, 2).Текст = "Имя регистра";
	ТДок.Область(4, 3).Текст = "Presentation";
	ТДок.Область(4, 4).Текст = "Число записей";
	ТДок.Область(4, 2, 4, 4).ЦветФона = WebЦвета.СветлоЖелтыйЗолотистый;
	ТДок.Область(4, 2, 4, 4).Обвести(Линия1, Линия1, Линия1, Линия1);

	НПП = 4;
	For Each Стр Из ТабРезультат Do
		НПП = НПП + 1;
		пИмяРегистра = СписокРегистров[Стр.Инд].Value;
		пЭтоДопДвижение = пКонфигурацияДопускаетДопДвижения И (Лев(пИмяРегистра, 1) = "+");

		ТДок.Область(НПП, 2).Текст = ?(пЭтоДопДвижение, Сред(пИмяРегистра, 2), пИмяРегистра);
		ТДок.Область(НПП, 3).Текст = СписокРегистров[Стр.Инд].Presentation;
		ТДок.Область(НПП, 4).Текст = Стр.ПолеА;

		If пЭтоДопДвижение Then
			ТДок.Область(НПП, 2, НПП, 4).ЦветТекста = WebЦвета.Зеленый;
		EndIf;
	EndDo;

	ТДок.Область(4, 2, НПП, 4).Обвести(Линия1, Линия1, Линия1, Линия1);

	Return ТДок;
EndFunction

&AtClientНаСервереБезКонтекста
Function vGetURL(Ссылка)
	// на некотрых платформах возникает ошибка при получении НавСсылки определенных объектов (на пример, счета БУ)

	Try
		Return ПолучитьНавигационнуюСсылку(Ссылка);
	Except
		Return "";
	EndTry;
EndFunction

&AtServer
Function вПроверитьНаличиеРеквизитаФормы(ИмяРеквизита, ЗначениеДляОтсутствующего = -1)
	Струк = New Structure(ИмяРеквизита, ЗначениеДляОтсутствующего);
	ЗаполнитьЗначенияСвойств(Струк, ThisForm);

	Return (Струк[ИмяРеквизита] <> ЗначениеДляОтсутствующего);
EndFunction

&AtServer
Procedure вСоздатьСпециализированныеТабличныеЧасти(Знач ОбъектМД, Знач ArrayКСозданию)
	ПолноеИмя = ОбъектМД.ПолноеИмя();
	ВидОбъекта = Лев(ПолноеИмя, Найти(ПолноеИмя, ".") - 1);

	ПереченьТЧ = вПереченьСпециализированныхТабличныхЧастей(ВидОбъекта);
	If Не IsBlankString(ПереченьТЧ) Then
		Струк = New Structure(ПереченьТЧ);
		For Each Элем Из Струк Do
			ИмяТЧ = Элем.Ключ;
			If вПроверитьНаличиеРеквизитаОбъекта(mObjectRef, ИмяТЧ) Then
				ТабРезультат = mObjectRef[ИмяТЧ].Выгрузить();

				ИмяТаб = _PrefixForNewItems + ИмяТЧ;
				ArrayКСозданию.Добавить(New РеквизитФормы(ИмяТаб, New ОписаниеТипов("ТаблицаЗначений"), , ИмяТЧ));
				For Each Элем Из ТабРезультат.Колонки Do
					If Элем.Name <> "НомерСтроки" Then
						ArrayКСозданию.Добавить(New РеквизитФормы(Элем.Name, Элем.ValueType, ИмяТаб, Элем.Name));
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вСоздатьСпециализированныеТабличныеЧасти_Items(Знач ОбъектМД)
	ПолноеИмя = ОбъектМД.ПолноеИмя();
	ВидОбъекта = Лев(ПолноеИмя, Найти(ПолноеИмя, ".") - 1);

	ПереченьТЧ = вПереченьСпециализированныхТабличныхЧастей(ВидОбъекта);
	If Не IsBlankString(ПереченьТЧ) Then
		Струк = New Structure(ПереченьТЧ);
		For Each Элем Из Струк Do
			ИмяТЧ = Элем.Ключ;
			If вПроверитьНаличиеРеквизитаОбъекта(mObjectRef, ИмяТЧ) Then
				ТабРезультат = mObjectRef[ИмяТЧ].Выгрузить();

				ИмяТаб = _PrefixForNewItems + ИмяТЧ;
				НоваяСтраница = Items.Добавить("Стр" + ИмяТаб, Тип("ГруппаФормы"), Items.ГруппаСтраницы);
				НоваяСтраница.Вид = ВидГруппыФормы.Страница;
				НоваяСтраница.Заголовок = ИмяТЧ;

				НоваяТаблица = Items.Добавить(ИмяТаб, Тип("ТаблицаФормы"), НоваяСтраница);
				НоваяТаблица.ПутьКДанным = ИмяТаб;

				For Each Элем Из ТабРезультат.Колонки Do
					If Элем.Name <> "НомерСтроки" Then
						НоваяКолонка = Items.Добавить(ИмяТаб + Элем.Name, Тип("ПолеФормы"), НоваяТаблица);
						НоваяКолонка.Вид = ВидПоляФормы.ПолеВвода;
						НоваяКолонка.ПутьКДанным = ИмяТаб + "." + Элем.Name;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьСпециализированныеТабличныеЧасти(Знач ОбъектМД)
	ПолноеИмя = ОбъектМД.ПолноеИмя();
	ВидОбъекта = Лев(ПолноеИмя, Найти(ПолноеИмя, ".") - 1);

	ПереченьТЧ = вПереченьСпециализированныхТабличныхЧастей(ВидОбъекта);
	If Не IsBlankString(ПереченьТЧ) Then
		Струк = New Structure(ПереченьТЧ);
		For Each Элем Из Струк Do
			ИмяТЧ = Элем.Ключ;
			ИмяТаб = _PrefixForNewItems + ИмяТЧ;

			If вПроверитьНаличиеРеквизитаОбъекта(mObjectRef, ИмяТЧ) Then
				ТабРезультат = mObjectRef[ИмяТЧ].Выгрузить();
				ЗначениеВРеквизитФормы(ТабРезультат, ИмяТаб);
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаписатьСпециализированныеТабличныеЧасти(ОбъектМД, ОбъектДляЗаписи)
	ПолноеИмя = ОбъектМД.ПолноеИмя();
	ВидОбъекта = Лев(ПолноеИмя, Найти(ПолноеИмя, ".") - 1);

	ПереченьТЧ = вПереченьСпециализированныхТабличныхЧастей(ВидОбъекта);
	If Не IsBlankString(ПереченьТЧ) Then
		Струк = New Structure(ПереченьТЧ);
		For Each Элем Из Струк Do
			ИмяТЧ = Элем.Ключ;
			ИмяТаб = _PrefixForNewItems + ИмяТЧ;

			If вПроверитьНаличиеРеквизитаОбъекта(ОбъектДляЗаписи, ИмяТЧ) Then
				ТабЧасть = ОбъектДляЗаписи[ИмяТЧ];
				ТабЧасть.Очистить();

				ТабРезультат = FormAttributeToValue(ИмяТаб);
				ТабЧасть.Загрузить(ТабРезультат);
			EndIf;
		EndDo;
	EndIf;
EndProcedure
&AtServerБезКонтекста
Function вОписаниеТиповВСтроку(ОписаниеТипов, СтрукТипы)
	If ОписаниеТипов = Undefined Then
		Return "";
	EndIf;

	Значение = "";
	Типы = ОписаниеТипов.Типы();
	For Each Элем Из Типы Do
		ИмяТипа = вИмяТипаСтрокой(СтрукТипы, Элем, ОписаниеТипов);
		If Не IsBlankString(ИмяТипа) Then
			Значение = Значение + "," + ИмяТипа;
		EndIf;
	EndDo;

	Return Сред(Значение, 2);
EndFunction

&AtServerБезКонтекста
Function вИмяТипаСтрокой(СтрукТипы, Тип, ОписаниеТипов)
	ИмяТипа = "";

	If Тип = СтрукТипы.мТипЧисло Then
		ИмяТипа = "Число";
		If ОписаниеТипов.КвалификаторыЧисла.Разрядность <> 0 Then
			ИмяТипа = ИмяТипа + "(" + ОписаниеТипов.КвалификаторыЧисла.Разрядность + "."
				+ ОписаниеТипов.КвалификаторыЧисла.РазрядностьДробнойЧасти + ")";
		EndIf;
	ElsIf Тип = СтрукТипы.мТипСтрока Then
		ИмяТипа = "Строка";
		If ОписаниеТипов.КвалификаторыСтроки.Длина <> 0 Then
			ИмяТипа = ИмяТипа + "(" + ?(ОписаниеТипов.КвалификаторыСтроки.ДопустимаяДлина = ДопустимаяДлина.Переменная,
				"П", "Ф") + ОписаниеТипов.КвалификаторыСтроки.Длина + ")";
		EndIf;
	ElsIf Тип = СтрукТипы.мТипДата Then
		ИмяТипа = ?(ОписаниеТипов.КвалификаторыДаты.ЧастиДаты = ЧастиДаты.Время, "Время", ?(
			ОписаниеТипов.КвалификаторыДаты.ЧастиДаты = ЧастиДаты.Дата, "Дата", "ДатаВремя"));
	ElsIf Тип = СтрукТипы.мТипБулево Then
		ИмяТипа = "Булево";
	ElsIf Тип = СтрукТипы.мТипДвоичныеДанные Then
		ИмяТипа = "ДвоичныеДанные";
	ElsIf Тип = СтрукТипы.мТипХранилищеЗначения Then
		ИмяТипа = "ХранилищеЗначения";
	ElsIf Тип = СтрукТипы.мТипУникальныйИдентификатор Then
		ИмяТипа = "УникальныйИдентификатор";
	Else
		ОбъектМД = Метаданные.НайтиПоТипу(Тип);
		If ОбъектМД <> Undefined Then
			ИмяТипа = ОбъектМД.ПолноеИмя();
		Else
			ИмяТипа = Строка(Тип);
		EndIf;
	EndIf;

	Return ИмяТипа;
EndFunction

&AtServerБезКонтекста
Function вСформироватьСтруктуруТипов()
	Результат = New Structure;

	Результат.Вставить("мТипСтрока", Тип("Строка"));
	Результат.Вставить("мТипБулево", Тип("Булево"));
	Результат.Вставить("мТипЧисло", Тип("Число"));
	Результат.Вставить("мТипДата", Тип("Дата"));
	Результат.Вставить("мТипStructure", Тип("Structure"));
	Результат.Вставить("мТипХранилищеЗначения", Тип("ХранилищеЗначения"));
	Результат.Вставить("мТипДвоичныеДанные", Тип("ДвоичныеДанные"));
	Результат.Вставить("мТипДеревоЗначений", Тип("ДеревоЗначений"));
	Результат.Вставить("мТипОбъектМетаданных", Тип("ОбъектМетаданных"));
	Результат.Вставить("мТипУникальныйИдентификатор", Тип("УникальныйИдентификатор"));

	Return Результат;
EndFunction

&AtServerБезКонтекста
Function vIsHierarchyFoldersAndItems(ОбъектМД)
	Струк = New Structure("Иерархический, ВидИерархии");
	ЗаполнитьЗначенияСвойств(Струк, ОбъектМД);
	Return (Струк.Иерархический = True И Струк.ВидИерархии
		= Метаданные.СвойстваОбъектов.ВидИерархии.ИерархияГруппИЭлементов);
EndFunction

&AtServerБезКонтекста
Function вОписаниеТиповСтрока(ДлинаСтроки, ПеременнаяДлина = True)
	Return New ОписаниеТипов("Строка", , , , New КвалификаторыСтроки(ДлинаСтроки, ?(ПеременнаяДлина,
		ДопустимаяДлина.Переменная, ДопустимаяДлина.Фиксированная)));
EndFunction

&AtServerБезКонтекста
Function вОписаниеТиповЧисло(ЧислоРазрядов, ЧислоРазрядовДробнойЧасти = 0)
	Return New ОписаниеТипов("Число", , , New КвалификаторыЧисла(ЧислоРазрядов, ЧислоРазрядовДробнойЧасти));
EndFunction

&AtServerБезКонтекста
Function вОписаниеТиповКода(ТипКода, ДлинаКода, ДопустимаяДлинаКода)
	Return ?(Строка(ТипКода) = "Число", вОписаниеТиповЧисло(ДлинаКода), вОписаниеТиповСтрока(ДлинаКода, ?(Строка(
		ДопустимаяДлинаКода) = "Фиксированная", False, True)));
EndFunction

&AtServerБезКонтекста
Function вОписаниеТиповНомера(ТипНомера, ДлинаНомера)
	Return ?(Строка(ТипНомера) = "Число", вОписаниеТиповЧисло(ДлинаНомера), вОписаниеТиповСтрока(ДлинаНомера, False));
EndFunction

&AtServerБезКонтекста
Function вОписаниеТиповВладельца(КоллекцияМД)
	ArrayТипов = New Array;
	For Each Элем Из КоллекцияМД Do
		ИмяТипа = Элем.ПолноеИмя();
		ИмяТипа = StrReplace(ИмяТипа, ".", "Ссылка.");
		ArrayТипов.Добавить(Тип(ИмяТипа));
	EndDo;

	Return New ОписаниеТипов(ArrayТипов);
EndFunction

&AtServer
Procedure вЗаполнитьСтандартныеРеквизиты(ОбъектМД)
	Перем НС;

	ПереченьРеквизитов = "Код, Номер, Дата, Проведен, ПометкаУдаления, ЭтоГруппа, Наименование, Владелец, Родитель, БизнесПроцесс, Выполнена, Завершен, Стартован, НомерОтправленного, НомерПринятого, ЭтотУзел";
	ПереченьСвойств = "ТипКода, ТипНомера, ДлинаКода, ДопустимаяДлинаКода, ДлинаНомера, ДлинаНаименования, Иерархический, ВидИерархии, Владельцы";

	СтрукРеквизиты = New Structure(ПереченьРеквизитов);
	СтрукСвойства = New Structure(ПереченьСвойств);

	ЗаполнитьЗначенияСвойств(СтрукСвойства, ОбъектМД);
	ЗаполнитьЗначенияСвойств(СтрукРеквизиты, mObjectRef);

	If Метаданные.ПланыОбмена.Содержит(ОбъектМД) Then
		If СтрукСвойства.ТипКода = Undefined Then
			СтрукСвойства.ТипКода = "Строка";
		EndIf;
	EndIf;

	If Метаданные.ПланыСчетов.Содержит(ОбъектМД) Then
		If СтрукСвойства.ТипКода = Undefined Then
			СтрукСвойства.ТипКода = "Строка";
		EndIf;
	EndIf;

	If СтрукСвойства.ТипНомера <> Undefined И ValueIsFilled(СтрукСвойства.ДлинаНомера) Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Номер";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = вОписаниеТиповНомера(СтрукСвойства.ТипНомера, СтрукСвойства.ДлинаНомера);
		НС.Value = СтрукРеквизиты.Номер;
	EndIf;

	If СтрукСвойства.ТипКода <> Undefined И ValueIsFilled(СтрукСвойства.ДлинаКода) Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Код";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = вОписаниеТиповКода(СтрукСвойства.ТипКода, СтрукСвойства.ДлинаКода,
			СтрукСвойства.ДопустимаяДлинаКода);
		НС.Value = СтрукРеквизиты.Код;
	EndIf;

	If СтрукРеквизиты.Наименование <> Undefined И ValueIsFilled(СтрукСвойства.ДлинаНаименования) Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Наименование";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = вОписаниеТиповСтрока(СтрукСвойства.ДлинаНаименования);
		НС.Value = СтрукРеквизиты.Наименование;
	EndIf;

	If СтрукРеквизиты.Дата <> Undefined Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Дата";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Дата", , , , , New КвалификаторыДаты(ЧастиДаты.ДатаВремя));
		НС.Value = СтрукРеквизиты.Дата;
	EndIf;

	If СтрукСвойства.Иерархический = True Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Родитель";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		Array = New Array;
		Array.Добавить(TypeOf(mObjectRef));
		НС.ValueType = New ОписаниеТипов(Array);
		НС.Value = СтрукРеквизиты.Родитель;
	EndIf;

	If СтрукРеквизиты.ПометкаУдаления <> Undefined Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "ПометкаУдаления";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.ПометкаУдаления;
	EndIf;

	If СтрукРеквизиты.ЭтоГруппа <> Undefined И СтрукСвойства.Иерархический = True И СтрукСвойства.ВидИерархии
		= Метаданные.СвойстваОбъектов.ВидИерархии.ИерархияГруппИЭлементов Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "ЭтоГруппа";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.ЭтоГруппа;
	EndIf;

	If СтрукСвойства.Владельцы <> Undefined И СтрукСвойства.Владельцы.Количество() <> 0 Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Владелец";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = вОписаниеТиповВладельца(СтрукСвойства.Владельцы);
		НС.Value = СтрукРеквизиты.Владелец;
	EndIf;

	If Метаданные.Документы.Содержит(ОбъектМД) Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Проведен";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.Проведен;
	EndIf;

	If Метаданные.Задачи.Содержит(ОбъектМД) Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "БизнесПроцесс";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		Array = New Array;
		Array.Добавить(TypeOf(СтрукРеквизиты.БизнесПроцесс));
		НС.ValueType = New ОписаниеТипов(Array);
		НС.Value = СтрукРеквизиты.БизнесПроцесс;

		НС = ObjectAttributes.Добавить();
		НС.Name = "Выполнена";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.Выполнена;
	EndIf;

	If Метаданные.БизнесПроцессы.Содержит(ОбъектМД) Then
		НС = ObjectAttributes.Добавить();
		НС.Name = "Стартован";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.Стартован;

		НС = ObjectAttributes.Добавить();
		НС.Name = "Завершен";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.Завершен;
	EndIf;

	If Метаданные.ПланыОбмена.Содержит(ОбъектМД) Then
		НС.Name = "НомерОтправленного";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Число");
		НС.Value = СтрукРеквизиты.НомерОтправленного;

		НС = ObjectAttributes.Добавить();
		НС.Name = "НомерПринятого";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Число");
		НС.Value = СтрукРеквизиты.НомерПринятого;

		НС = ObjectAttributes.Добавить();
		НС.Name = "ЭтотУзел";
		НС.Presentation = НС.Name;
		НС.Категория = 0;
		НС.ValueType = New ОписаниеТипов("Булево");
		НС.Value = СтрукРеквизиты.ЭтотУзел;
	EndIf;
EndProcedure
&AtServer
Procedure vRefreshObjectData()
	If mObjectRef <> Undefined Then
		Array = New Array;
		Array.Добавить(TypeOf(mObjectRef));
		Items.mObjectRef.ОграничениеТипа = New ОписаниеТипов(Array);
	EndIf;

	НадоСоздаватьРеквизиты = (TypeOf(mObjectRef) <> TypeOf(mPreviousObjectRef));

	If _ConfigurationAllowsAdditionalRecords И НадоСоздаватьРеквизиты И ValueIsFilled(mObjectRef) Then
		пСтрук = вОпределитьДополнительныеРегистрыДокумента(mObjectRef);
		Items._OpenAdditionalRecordsEditor.Visible = пСтрук.ЕстьДанные;
	EndIf;

	вОчиститьДанныеОбъекта();
	вЗаполнитьДанныеОбъекта(НадоСоздаватьРеквизиты);
	mPreviousObjectRef = mObjectRef;
	vRefreshRecordSet();
EndProcedure

&AtClient
Procedure ObjectAttributesOnActivateRow(Элемент)
	Return;
	ТекДанные = Items.ObjectAttributes.ТекущиеДанные;
	If ТекДанные <> Undefined Then
		Items.ObjectAttributesValue.ОграничениеТипа = ТекДанные.ValueType;
		//Items.ObjectAttributesValue.ДоступныеТипы = ТекДанные.ValueType;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectAttributesBeforeRowChange(Элемент, Отказ)
	ТекДанные = Элемент.ТекущиеДанные;
	If ТекДанные <> Undefined Then
		Значение = ТекДанные["Value"];
		
		//If TypeOf(Value) = mTypeVS или TypeOf(Value) = mTypeUUID Then
		If TypeOf(Значение) = mTypeVS Then
			Отказ = True;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectAttributesSelection(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	If Поле.Name = "ObjectAttributesValue" Then
		ТекДанные = Элемент.ТекущиеДанные;
		If ТекДанные <> Undefined Then
			Значение = ТекДанные["Value"];

			If TypeOf(Значение) = mTypeVS Then
				СтандартнаяОбработка = False;
				vShowValueVS(Значение);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ТабличнаяЧастьВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	ТекДанные = Элемент.ТекущиеДанные;
	If ТекДанные <> Undefined Then
		ИмяКолонки = Сред(Поле.Имя, СтрДлина(Элемент.Имя) + 1);
		Значение = ТекДанные[ИмяКолонки];

		If TypeOf(Значение) = mTypeVS Then
			СтандартнаяОбработка = False;
			vShowValueVS(Значение);
		EndIf;
	EndIf;
EndProcedure
&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Настройки)
//	If Настройки["_ДополнительныеСвойства"] = Undefined Then
//		_ДополнительныеСвойства.Очистить();
//	EndIf;
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Настройки)
	//If ValueIsFilled(mObjectRef) Then
	If mObjectRef <> Undefined Then
		vRefreshObjectData();
	EndIf;
EndProcedure

&AtClient
Procedure _OpenRecordsEditor(Команда)
	СтрукПарам = New Structure("FormsPath, mObjectRef", FormsPath, mObjectRef);
	Try
		OpenForm("Обработка.UT_ObjectsAttributesEditor.Форма.FormRecodsEditor", СтрукПарам, , mObjectRef);
	Except
		Сообщить(NSTR("ru = 'Не найдена форма ""FormRecodsEditor""!';en = 'Not found form ""FormRecodsEditor""!'"));
	EndTry;
EndProcedure

&AtClient
Procedure _OpenAdditionalRecordsEditor(Команда)
	СтрукПарам = New Structure("FormsPath, mObjectRef", FormsPath, mObjectRef);
	Try
		OpenForm("Обработка.UT_ObjectsAttributesEditor.Форма.FormRecordsEditorAdditional", СтрукПарам, ,
			mObjectRef);
	Except
		Сообщить(NSTR("ru = 'Не найдена форма ""FormRecodsEditor""!';en = 'Not found form ""FormRecodsEditor""!'"));
	EndTry;
EndProcedure
&AtClient
Procedure _FillCurrentColumnData(Команда)
	ТекСтраница = Items.PagesGroup.ТекущаяСтраница;
	If ТекСтраница.Name = "ObjectAttributesPage" Или ТекСтраница.Name = "SettingsPage" Then
		Return;
	EndIf;

	ТекТаб = Undefined;
	For Each Элем Из ТекСтраница.ПодчиненныеItems Do
		If TypeOf(Элем) = Тип("ТаблицаФормы") Then
			ТекТаб = Элем;
			Прервать;
		EndIf;
	EndDo;

	пЗначение = _ValueToFill;

	If ТекТаб <> Undefined Then
		СтрукДанные = vGetTableFieldProperties(ТекТаб.Имя);
		If Не СтрукДанные.Отказ Then
			пТаблица = ThisForm[СтрукДанные.Таблица];
			пПоле = СтрукДанные.Поле;

			If пТаблица.Количество() <> 0 Then

				If _ProcessOnlySelectedRows Then
					For Each Элем Из ТекТаб.ВыделенныеСтроки Do
						Стр = пТаблица.НайтиПоИдентификатору(Элем);
						Стр[пПоле] = пЗначение;
					EndDo;
				Else
					For Each Стр Из пТаблица Do
						Стр[пПоле] = пЗначение;
					EndDo;
				EndIf;

			EndIf;

		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _ValueToFillStartChoice(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	If _ValueToFill = Undefined Then
		СтандартнаяОбработка = False;
		СтрукПарам = New Structure("CloseOnOwnerClose, TypesToFillValues", True, True);
		OpenForm("ОбщаяФорма.UT_MetadataSelectionForm", СтрукПарам, Элемент, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	ElsIf TypeOf(_ValueToFill) = Тип("УникальныйИдентификатор") Then
		СтандартнаяОбработка = False;
	Else
		Array = New Array;
		Array.Добавить(TypeOf(_ValueToFill));
		Элемент.ОграничениеТипа = New ОписаниеТипов(Array);
	EndIf;
EndProcedure

&AtClient
Procedure _ValueToFillClearing(Элемент, СтандартнаяОбработка)
	Элемент.ОграничениеТипа = New ОписаниеТипов;
EndProcedure


// для документов
&AtClient
Procedure _PostDocument(Команда)
	If Не ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан документ для обработки';en = 'No document set for processing'"), 20);
		Return;
	EndIf;

	If Не _ПроведениеРазрешено Then
		ShowMessageBox( , NSTR("ru = 'Проведение документов данного типа запрещено!';en = 'Posting documents of this type is prohibited!'"), 20);
		Return;
	EndIf;

	ShowQueryBox(New NotifyDescription("вПровестиДокументДалее", ThisForm),
		NSTR("ru = 'Документ будет перепроведен. Продолжить?';en = 'Document will be reposted.Continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure _UndoPosting(Команда)
	If Не ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан документ для обработки';en = 'No document set for processing'"), 20);
		Return;
	EndIf;

	If Не _ПроведениеРазрешено Then
		ShowMessageBox( , NSTR("ru = 'Проведение документов данного типа запрещено!';en = 'Posting documents of this type is prohibited!'"), 20);
		Return;
	EndIf;

	ShowQueryBox(New NotifyDescription("вРаспровестиДокументДалее", ThisForm),
		NSTR("ru = 'Для документа будет выполнена отмена проведения. Продолжить?';en = 'Undo posting will be performed for document. Continue?'"), QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure вПровестиДокументДалее(РезультатВопроса, ДопПараметры = Undefined) Export
	If РезультатВопроса = DialogReturnCode.Да Then
		пСтрук = New Structure;

//		If _ИспользоватьДополнительныеСвойстваПриЗаписи И _ДополнительныеСвойства.Количество() <> 0 Then
//			пСтрук.ДополнительныеСвойства = New Structure;
//			Try
//				For Each Стр Из _ДополнительныеСвойства Do
//					пСтрук.ДополнительныеСвойства.Вставить(Стр.Ключ, Стр.Value);
//				EndDo;
//			Except
//				Сообщить("Ошибка при установке ДополнительныхСвойств: неправильное значение ключа """ + Стр.Ключ + """");
//				Return;
//			EndTry;
//		EndIf;

//		If _ИспользоватьПроцедуруПередЗаписью И Не IsBlankString(_ProcedureПередЗаписью) Then
//			пСтрук.ProcedureПередЗаписью = _ProcedureПередЗаписью;
//		EndIf;

		If вПровестиРаспровестиДокумент(mObjectRef, True, пСтрук) Then
			RefreshObjectData(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure вРаспровестиДокументДалее(РезультатВопроса, ДопПараметры = Undefined) Export
	If РезультатВопроса = DialogReturnCode.Да Then
		If вПровестиРаспровестиДокумент(mObjectRef, False) Then
			RefreshObjectData(Undefined);
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function вПровестиРаспровестиДокумент(Ссылка, Провести = True, пСтрукПарам = Undefined)
	Режим = ?(Провести, РежимЗаписиДокумента.Проведение, РежимЗаписиДокумента.ОтменаПроведения);

	ДокОбъект = Ссылка.ПолучитьОбъект();

	Return UT_Common.WriteObjectToDB(ДокОбъект, UT_CommonClientServer.FormWriteSettings(ЭтотОбъект), , Режим);

EndFunction


// выгрузка / загрузка объекта через XML
&AtClient
Function вПолучитьДиалогВыбораФайлаXML(Открытие = True, ПутьКФайлу = "")
	Диалог = New ДиалогВыбораФайла(?(Открытие, РежимДиалогаВыбораФайла.Открытие, РежимДиалогаВыбораФайла.Сохранение));

	Диалог.ПолноеИмяФайла = ПутьКФайлу;
	Диалог.Заголовок  = NSTR("ru = 'Файл данных XML';en = 'XML data file'");
	Диалог.Фильтр     = NSTR("ru = 'Файлы данных XML (*.xml)|*.xml|Все файлы (*.*)|*.*';en = 'XML data files (*.xml)|*.xml|All files (*.*)|*.*'");
	Диалог.Расширение = "xml";

	Return Диалог;
EndFunction

&AtClient
Procedure _UnloadRecordSet(Команда)
	If Не ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан объект для выгрузки движений';en = 'Object for records uploading is not set'"), 20);
		Return;
	EndIf;
	If IsBlankString(_RecordSetName) Then
		ShowMessageBox( ,NSTR("ru = 'Не задан набор записей для выгрузки';en = 'Recordset for uploading is not specified'") , 20);
		Return;
	EndIf;

	вВыгрузитьОбъект(4);
EndProcedure

&AtClient
Procedure _UnloadObject(Команда)
	вВыгрузитьОбъект(1);
EndProcedure

&AtClient
Procedure _UnloadObjectWithRecords(Команда)
	вВыгрузитьОбъект(2);
EndProcedure

&AtClient
Procedure _UnloadObjectRecords(Команда)
	вВыгрузитьОбъект(3);
EndProcedure

&AtClient
Procedure _LoadXMLData(Команда)
	Диалог = вПолучитьДиалогВыбораФайлаXML(True);
	Диалог.Показать(New NotifyDescription("вЗагрузитьДанныеИзФайла", ThisForm));
EndProcedure

&AtClient
Procedure вЗагрузитьДанныеИзФайла(ВыбранныеФайлы, ДопПарам = Undefined) Export
	If ВыбранныеФайлы <> Undefined Then
		пИмяФайла = ВыбранныеФайлы[0];
		ТДок = New ТекстовыйДокумент;
		ТДок.НачатьЧтение(New NotifyDescription("вПослеОкончанияЧтенияФайла", ThisForm, ТДок), пИмяФайла, "UTF-8");
	EndIf;
EndProcedure

&AtClient
Procedure вПослеОкончанияЧтенияФайла(ТДок) Export
	If TypeOf(ТДок) = Тип("ТекстовыйДокумент") Then
		СтрокаXML = ТДок.ПолучитьТекст();
		If Не IsBlankString(СтрокаXML) Then
			вЗагрузитьДанныеXML(СтрокаXML);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure вВыгрузитьОбъект(пРежим)
	If Не ValueIsFilled(mObjectRef) Then
		ShowMessageBox( , NSTR("ru = 'Не задан документ для выгрузки';en = 'Not specified  document for uploading'"), 20);
		Return;
	EndIf;

	Диалог = вПолучитьДиалогВыбораФайлаXML(False);

	If пРежим = 1 Then
		Диалог.ПолноеИмяФайла = NSTR("ru = 'Объект';en = 'Object'");
	ElsIf пРежим = 2 Then
		Диалог.ПолноеИмяФайла =NSTR("ru = 'Объект (с движениями)';en = 'Object (with records)'") ;
	ElsIf пРежим = 3 Then
		Диалог.ПолноеИмяФайла =NSTR("ru = 'Объект (движения)';en = 'Object (records)'") ;
	ElsIf пРежим = 4 Then
		Диалог.ПолноеИмяФайла = _RecordSetName;
	EndIf;

	Диалог.Показать(New NotifyDescription("вВыгрузитьОбъектВФайл", ThisForm, пРежим));
EndProcedure

&AtClient
Procedure вВыгрузитьОбъектВФайл(ВыбранныеФайлы, пРежим = Undefined) Export
	If ВыбранныеФайлы <> Undefined Then
		СтрокаXML = вСформироватьВыгрузкуXML(mObjectRef, пРежим, _RecordSetName);
		If Не IsBlankString(СтрокаXML) Then
			пИмяФайла = ВыбранныеФайлы[0];
			ТДок = New ТекстовыйДокумент;
			ТДок.УстановитьТекст(СтрокаXML);
			ТДок.НачатьЗапись(New NotifyDescription("вПослеОкончанияЗаписиФайла", ThisForm), пИмяФайла, "UTF-8");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure вПослеОкончанияЗаписиФайла(Результат, ДопПарам = Undefined) Export
	If Результат = True Then
		ShowMessageBox( , NSTR("ru = 'Данные выгружены в файл';en = 'Data is uploaded to  file'"), 20);
	EndIf;
EndProcedure
&AtServerБезКонтекста
Function вСформироватьВыгрузкуXML(Знач пСсылка, Знач пРежим, Знач пИмяНабораЗаписей = "")

	ЗаписьXML = New ЗаписьXML;
	ЗаписьXML.УстановитьСтроку("UTF-8");

	ЗаписьXML.ЗаписатьОбъявлениеXML();
	ЗаписьXML.ЗаписатьНачалоЭлемента("_1CV8DtUD", "http://www.1c.ru/V8/1CV8DtUD/");
	ЗаписьXML.ЗаписатьСоответствиеПространстваИмен("V8Exch", "http://www.1c.ru/V8/1CV8DtUD/");
	ЗаписьXML.ЗаписатьСоответствиеПространстваИмен("xsi", "http://www.w3.org/2001/XMLSchema-instance");
	ЗаписьXML.ЗаписатьСоответствиеПространстваИмен("core", "http://v8.1c.ru/data");

	ЗаписьXML.ЗаписатьСоответствиеПространстваИмен("v8", "http://v8.1c.ru/8.1/data/enterprise/current-config");
	ЗаписьXML.ЗаписатьСоответствиеПространстваИмен("xs", "http://www.w3.org/2001/XMLSchema");

	ЗаписьXML.ЗаписатьНачалоЭлемента("V8Exch:Data");
	If пРежим = 4 Then
		Менеджер = вСоздатьМенеджерНабораЗаписей(пИмяНабораЗаписей);
		If Менеджер <> Undefined Then
			Набор = Менеджер.СоздатьНаборЗаписей();
			Набор.Отбор.Регистратор.Установить(пСсылка);
			Набор.Прочитать();

			СериализаторXDTO.ЗаписатьXML(ЗаписьXML, Набор);
		EndIf;
	Else
		Try
			пОбъект = пСсылка.ПолучитьОбъект();
		Except
			Сообщить(КраткоеПредставлениеОшибки(ИнформацияОбОшибке()), СтатусСообщения.Важное);
			Сообщить(NSTR("ru = 'Выгрузка данных не выполнена!';en = 'Data upload failed!'"), СтатусСообщения.Важное);
			Return "";
		EndTry;

		If пРежим = 1 Или пРежим = 2 Then
			СериализаторXDTO.ЗаписатьXML(ЗаписьXML, пОбъект, НазначениеТипаXML.Явное);
		EndIf;

		If пРежим = 2 Или пРежим = 3 Then
			пОбъектМД = пОбъект.Метаданные();
			If Метаданные.Документы.Содержит(пОбъектМД) Then
				For Each Движение Из пОбъект.Движения Do
					Движение.Прочитать();
					СериализаторXDTO.ЗаписатьXML(ЗаписьXML, Движение);
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	ЗаписьXML.ЗаписатьКонецЭлемента(); // V8Exc:Data
	ЗаписьXML.ЗаписатьКонецЭлемента(); // V8Exc:_1CV8DtUD

	СтрокаXML = ЗаписьXML.Закрыть();

	Return СтрокаXML;
EndFunction

&AtServerБезКонтекста
Procedure вЗагрузитьДанныеXML(Знач СтрокаXML)
	ЧтениеXML = New ЧтениеXML;
	ЧтениеXML.УстановитьСтроку(СтрокаXML);

	Сообщить(NSTR("ru = 'Загрузка данных стартована';en = 'Data loading has started'"));

	пОшибкаФормата = False;
	пСтрокаНеверныйФормат = НСтр("ru = 'Неверный формат файла выгрузки';en = 'Invalid upload file format'");

	Try
		// проверка формата
		If пОшибкаФормата Или Не ЧтениеXML.Прочитать() Или ЧтениеXML.ТипУзла <> ТипУзлаXML.НачалоЭлемента
			Или ЧтениеXML.ЛокальноеИмя <> "_1CV8DtUD" Или ЧтениеXML.URIПространстваИмен
			<> "http://www.1c.ru/V8/1CV8DtUD/" Then

			пОшибкаФормата = True;
		EndIf;

		If пОшибкаФормата Или Не ЧтениеXML.Прочитать() Или ЧтениеXML.ТипУзла <> ТипУзлаXML.НачалоЭлемента
			Или ЧтениеXML.ЛокальноеИмя <> "Data" Then

			пОшибкаФормата = True;
		EndIf;

		If пОшибкаФормата Или Не ЧтениеXML.Прочитать() Then

			пОшибкаФормата = True;
		EndIf;

	Except
		пОшибкаФормата = True;
	EndTry;

	If пОшибкаФормата Then
		Сообщить(пСтрокаНеверныйФормат, СтатусСообщения.Важное);
		ЧтениеXML.Закрыть();
		Return;
	EndIf;
	
	
	// чтение данных
	НачатьТранзакцию();

	Пока СериализаторXDTO.ВозможностьЧтенияXML(ЧтениеXML) Do
		Try
			пОбъект = СериализаторXDTO.ПрочитатьXML(ЧтениеXML);
			пОбъект.ОбменДанными.Загрузка = True;
			пОбъект.Записать();
		Except
			пОшибкаФормата = True;
			Сообщить(КраткоеПредставлениеОшибки(ИнформацияОбОшибке()), СтатусСообщения.Важное);
			Прервать;
		EndTry;
	EndDo;

	If пОшибкаФормата Then
		ОтменитьТранзакцию();

		ЧтениеXML.Закрыть();
		Сообщить(NSTR("ru = 'Загрузка данных прервана';en = 'Data loading aborted'"), СтатусСообщения.Важное);
		Return;
	Else
		ЗафиксироватьТранзакцию();
	EndIf;
	
	
	// проверка формата
	If пОшибкаФормата Или ЧтениеXML.ТипУзла <> ТипУзлаXML.КонецЭлемента Или ЧтениеXML.ЛокальноеИмя <> "Data" Then

		пОшибкаФормата = True;
	EndIf;

	If пОшибкаФормата Или Не ЧтениеXML.Прочитать() Или ЧтениеXML.ТипУзла <> ТипУзлаXML.КонецЭлемента
		Или ЧтениеXML.ЛокальноеИмя <> "_1CV8DtUD" Или ЧтениеXML.URIПространстваИмен <> "http://www.1c.ru/V8/1CV8DtUD/" Then

		пОшибкаФормата = True;
	EndIf;

	If пОшибкаФормата Then
		Сообщить(пСтрокаНеверныйФормат, СтатусСообщения.Важное);
		ЧтениеXML.Закрыть();
		Сообщить(NSTR("ru = 'Загрузка данных завершена';en = 'Data loading completed'"));
		Return;
	EndIf;

	ЧтениеXML.Закрыть();
	Сообщить(NSTR("ru = 'Загрузка данных завершена';en = 'Data loading completed'"));
EndProcedure
&AtServerБезКонтекста
Function вОпределитьДополнительныеРегистрыДокумента(Знач пПолноеИмяДокумента)
	пСоотв = New Соответствие;

	пСтрук = New Structure;
	пСтрук.Вставить("ЕстьДанные", False);
	пСтрук.Вставить("ДополнительныеРегистры", пСоотв);

	пРегистраторМД = Метаданные.Документы.Найти("РегистраторРасчетов");
	If пРегистраторМД = Undefined Then
		Return пСтрук;
	EndIf;

	If TypeOf(пПолноеИмяДокумента) <> Тип("Строка") Then
		пПолноеИмяДокумента = пПолноеИмяДокумента.Метаданные().ПолноеИмя();
		If СтрНайти(пПолноеИмяДокумента, "Документ.") <> 1 Then
			Return пСтрук;
		EndIf;
	EndIf;

	For Each ЭлемМД Из пРегистраторМД.Движения Do
		пРеквизитМД = ЭлемМД.Реквизиты.Найти("ДокументРегистратор");
		If пРеквизитМД <> Undefined Then
			пИмяРегистра = ЭлемМД.ПолноеИмя();

			For Each пТип Из пРеквизитМД.Тип.Типы() Do
				пДокМД = Метаданные.НайтиПоТипу(пТип);

				If пДокМД <> Undefined Then
					пИмяДокумента = пДокМД.ПолноеИмя();

					If пИмяДокумента = пПолноеИмяДокумента И пИмяДокумента <> "Документ.РегистраторРасчетов" Then
						пСоотв[пИмяРегистра] = ЭлемМД.Представление();
						Прервать;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;

	пСтрук.ЕстьДанные = (пСоотв.Количество() <> 0);

	Return пСтрук;
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

		If ТекТаблица.Name = "ObjectAttributes" Then
			пСтрук.Вставить("Поле", "Value");
//		ElsIf ТекТаблица.Name = "_ДополнительныеСвойства" Then
//			пСтрук.Вставить("Поле", "Value");
		Else
			пСтрук.Вставить("Поле", Сред(ТекКолонка.Имя, СтрДлина(ТекТаблица.Имя) + 1));
		EndIf;

		ПоказатьВводСтроки(New NotifyDescription("вОбработатьВвод_UUID", ThisForm, пСтрук), mLastUUID,
			NStr("ru = 'Введите уникальный идентификатор';en = 'Enter a unique identifier (UUID)'"), , False);
	EndIf;
EndProcedure

&AtClient
Procedure вОбработатьВвод_UUID(Строка, пСтрук = Undefined) Export
	If Строка <> Undefined И Не IsBlankString(Строка) Then
		Try
			пЗначение = New УникальныйИдентификатор(Строка);
			mLastUUID = Строка;
		Except
			ShowMessageBox( , NSTR("ru = 'Значение не может быть преобразовано в Уникальный идентификатор!';en = 'The value cannot be converted to a Unique identifier! (UUID)'"), 20);
			Return;
		EndTry;

		If пСтрук.Таблица = "_ValueToFill" Then
			_ValueToFill = пЗначение;
		Else
			ТекДанные = Items[пСтрук.Таблица].ТекущиеДанные;
			If ТекДанные <> Undefined Then
				ТекДанные[пСтрук.Поле] = пЗначение;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Команда) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ЭтотОбъект, Команда);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_SetWriteSettings(Команда)
	UT_CommonClient.EditWriteSettings(ЭтотОбъект);
EndProcedure