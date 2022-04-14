
///////////////////////////////////////////////////////////////////////////////
// PRIVATE

&AtServer
Function DataProcessorID()
	DataProcessorObject = FormAttributeToValue("Object");
	Return DataProcessorObject.Metadata().FullName();
EndFunction

// Displays error message and sets Cancel to True.
// If at client or at server, displays message in message window.
// If external connection, raises exception.
//
// Parameters:
//  MessageText - String - message text.
//  Cancel      - Boolean, (optional) cancel flag.
//
&AtServerNoContext
Procedure mErrorMessage(MessageText, Cancel = False, Title = "") Export

	InternalMessageBegin    = Find(MessageText, "{");
	InternalMessageEnd = Find(MessageText, "}:");
	If InternalMessageEnd > 0 And InternalMessageBegin > 0 Then
		MessageText = Left(MessageText, (InternalMessageBegin - 1)) + Mid(MessageText,
			(InternalMessageEnd + 2));
	EndIf;

	Cancel = True;

	If ValueIsFilled(Title) Then
		Message(Title);
		Title = "";
	EndIf;

	Message(MessageText, MessageStatus.Important);

EndProcedure

// Splits the string into several strings by the specified separator. The separator can be any length.
// If space is used as a separator, adjacent spaces are treated as one separator, 
// leading and trailing spaces of the Str parameter are ignored.
// 
// Example:
//		mSplitStringIntoSubstringsArray(",qu,,,mu", ",")
//			- returns an array of five items, three of which are empty strings;
//		mSplitStringIntoSubstringsArray(" qu   mu", " ")
//			- returns an array of two items: "qu", "mu".
//
//	Parameters:
//		Str - String - a delimited text.
//		Separator - String - a text separator, "," by default.
//
//
//	Return value:
//		Array - an array of strings.
//
&AtServer
Function mSplitStringIntoSubstringsArray(Val Str, Separator = ",")

	StringArray = New Array;
	If Separator = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Separator);
			If Pos = 0 Then
				StringArray.Add(Str);
				Return StringArray;
			EndIf;
			StringArray.Add(Left(Str, Pos - 1));
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SeparatorLength = StrLen(Separator);
		While 1 = 1 Do
			Pos = Find(Str, Separator);
			If Pos = 0 Then
				StringArray.Add(Str);
				Return StringArray;
			EndIf;
			StringArray.Add(Left(Str, Pos - 1));
			Str = Mid(Str, Pos + SeparatorLength);
		EndDo;
	EndIf;

EndFunction

// Adjusts a string presentation of number to its value.
//
// Parameters:
//  Presentation - String - a number presentation.
//  TypeDescription - TypeDescription - a description of number type.
//  Comment - String - an error description.
//
// Return value:
//  Number - Adjusted value.
//
&AtServer
Function mAdjustToNumber(Presentation, Val TypeDescription = Undefined, Comment = "")

	If TypeDescription = Undefined Then
		TypeDescription = New TypeDescription("Number");
	EndIf;

	PresentationLower = Lower(Presentation);
	If PresentationLower = "yes" Or PresentationLower = "True" Or PresentationLower = "enabled" Then
		Return 1;
	ElsIf PresentationLower = "no" Or PresentationLower = "False" Or PresentationLower = "disabled" Then
		Return 0;
	EndIf;

	Result = StrReplace(Presentation, " ", "");
	Try
		Result = Number(Result);
	Except
		Comment = NStr("ru = 'Неправильный формат числа'; en = 'Incorrect number format'");
		Return 0;
	EndTry;

	Result1 = TypeDescription.AdjustValue(Result);

	If Not Result1 = Result Then
		Comment = NStr("ru = 'Недопустимое числовое значение'; en = 'Invalid number value'");
	EndIf;

	Return Result1;

EndFunction // mAdjustToNumber()

// Adjusts a string presentation of date to its value.
//
// Parameters:
//  Presentation - String - a date presentation.
//  AttributeType - TypeDescription - a description of date type.
//  Comment - String - an error description.
//
// Return value:
//  Date - Adjusted value.
//
&AtServer
Function mAdjustToDate(Presentation, AttributeType, Comment = "")

	Result = AttributeType.ПривестиЗначение(Presentation);
	If Result = '00010101' Then

		FractionsArray = GetDatePresentationFractions(Presentation);
		If AttributeType.DateQualifiers.DateFractions = DateFractions.Time Then

			Try

				If FractionsArray.Count() = 3 Then
					Result = Date(1, 1, 1, FractionsArray[0], FractionsArray[1], FractionsArray[2]);
				ElsIf FractionsArray.Count() = 6 Then
					Result = Date(1, 1, 1, FractionsArray[3], FractionsArray[4], FractionsArray[5]);
				EndIf;

			Except
				Comment = NStr("ru = 'Неправильный формат даты'; en = 'Invalid date format'");
			EndTry;

		ElsIf FractionsArray.Count() = 3 Or FractionsArray.Count() = 6 Then

			If FractionsArray[0] >= 1000 Then
				Temp = FractionsArray[0];
				FractionsArray[0] = FractionsArray[2];
				FractionsArray[2] = Temp;
			EndIf;

			If FractionsArray[2] < 100 Then
				FractionsArray[2] = FractionsArray[2] + ?(FractionsArray[2] < 30, 2000, 1900);
			EndIf;

			Try
				If FractionsArray.Count() = 3 Or AttributeType.DateQualifiers.DateFractions = DateFractions.Date Then
					Result = Date(FractionsArray[2], FractionsArray[1], FractionsArray[0]);
				Else
					Result = Date(FractionsArray[2], FractionsArray[1], FractionsArray[0], FractionsArray[3],
						FractionsArray[4], FractionsArray[5]);
				EndIf;
			Except
				Comment = NStr("ru = 'Неправильный формат даты'; en = 'Invalid date format'");
			EndTry;

		EndIf;

	EndIf;

	Return Result;

EndFunction

// Returns date presentation fractions.
//
// Parameters:
//  Presentation - String - date presentation.
//
// Return valus:
//  Array - date fractions.
//
&AtServer
Function GetDatePresentationFractions(Val Presentation)

	FractionsArray = New Array;
	BeginOfDigit = 0;
	For k = 1 To StrLen(Presentation) Do

		Char = Mid(Presentation, k, 1);
		IsDigit = Char >= "0" And Char <= "9";

		If IsDigit Then

			If BeginOfDigit = 0 Then
				BeginOfDigit = k;
			EndIf;

		Else

			If Not BeginOfDigit = 0 Then
				FractionsArray.Add(Number(Mid(Presentation, BeginOfDigit, k - BeginOfDigit)));
			EndIf;

			BeginOfDigit = 0;
		EndIf;

	EndDo;

	If Not BeginOfDigit = 0 Then
		FractionsArray.Add(Number(Mid(Presentation, BeginOfDigit)));
	EndIf;

	Return FractionsArray;
EndFunction // ()

// Returns manager by value type.
//
// Parameters:
//  ValueType - Type - type of value to get manager.
//
// Return value:
//  CatalogManager, DocumentManager, etc.
//
&AtServer
Function GetManagerByType(ValueType) Export

	If Not ValueType = Undefined Then
		MetadataObjectManagers = New Structure("Catalogs, Enums, Documents, ChartsOfCharacteristicTypes, ChartsOfAccounts, ChartsOfCalculationTypes, BusinessProcesses, Tasks",
			Catalogs, Enums, Documents, ChartsOfCharacteristicTypes, ChartsOfAccounts, ChartsOfCalculationTypes,
			BusinessProcesses, Tasks);
		For Each MetadataObjectManager In MetadataObjectManagers Do
			If MetadataObjectManager.Value.AllRefsType().ContainsType(ValueType) Then
				Manager = MetadataObjectManager.Value[Metadata.FindByType(ValueType).Name];
				Break;
			EndIf;
		EndDo;
		Return Manager;
	Else
		Return Undefined;
	EndIf;

EndFunction

&AtServer
Function GetTypeDescription(AttributeTypesDescription) Export

	TypesDescription = "";

	For Each Type In AttributeTypesDescription.Types() Do
		TypeMetadata = Metadata.FindByType(Type);
		If Not TypeMetadata = Undefined Then
			TypeDescription = TypeMetadata.FullName();
		ElsIf Type = Type("String") Then

			TypeDescription = "String";
			If AttributeTypesDescription.StringQualifiers.Length Then
				TypeDescription = TypeDescription + ", " + AttributeTypesDescription.StringQualifiers.Length;
				If AttributeTypesDescription.StringQualifiers.AllowedLength = AllowedLength.Fixed Then
					TypeDescription = TypeDescription + ", " + AllowedLength.Fixed;
				EndIf;
			EndIf;

		ElsIf Type = Type("Number") Then
			TypeDescription = "Number" + ", " + AttributeTypesDescription.NumberQualifiers.Digits + ", "
				+ AttributeTypesDescription.NumberQualifiers.FractionDigits + ?(
				AttributeTypesDescription.NumberQualifiers.AllowedSign = AllowedSign.Nonnegative,
				", Nonnegative", "");
		ElsIf Type = Type("Date") Then
			TypeDescription = "" + AttributeTypesDescription.DateQualifiers.DateFractions;
		ElsIf Type = Type("Boolean") Then
			TypeDescription = "Boolean";
		Else
			Continue;
		EndIf;

		TypesDescription = ?(IsBlankString(TypesDescription), "", TypesDescription + Chars.LF) + TypeDescription;

	EndDo;

	Return TypesDescription;

EndFunction // GetTypeDescription()

////////////////////////////////////////////////////////////////////////////////
//

&AtServer
Function mRestoreValue(Name)
	Return FormDataSettingsStorage.Load(DataProcessorID(), Name);
EndFunction

&AtServer
Procedure mSaveValue(Name, Val Value)

	If TypeOf(Value) = Type("FormDataCollection") Then

		Value = FormDataToValue(Value, Type("ValueTable"));

	EndIf;

	FormDataSettingsStorage.Save(DataProcessorID(), Name, Value);

EndProcedure

// Returns setting from saved settings list.
//
// Parameters:
//  SettingsList - ValueList - a list of saved settings.
//
// Return value:
//  Arbitrary - a value of setting. 
//
&AtServer
Function GetDefaultSetting(SettingsList)

	SourceMetadata = GetSourceMetadata();

	If SourceMetadata = Undefined Then
		Return Undefined;
	EndIf;
	//VT = FormAttributeToValue("SavedSettingsList");
	For Each ListRow In SettingsList Do
		If ListRow.Check Then
			Return ListRow.Value;
		EndIf;
	EndDo;
	Return Undefined;

EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Fills SourceTabularSection form item choice list.
//
&AtServer
Procedure SetTabularSectionsList()

	ChoiceList = Items.SourceTabularSection.ChoiceList;
	ChoiceList.Clear();
	If Object.SourceRef = Undefined Then
		Return;
	EndIf;
	For Each TabularSection In Object.SourceRef.Metadata().TabularSections Do
		ChoiceList.Add(TabularSection.Name, TabularSection.Presentation());
	EndDo;
	If Not IsBlankString(Object.SourceTabularSection) And ChoiceList.FindByValue(Object.SourceTabularSection)
		= Undefined Then
		Object.SourceTabularSection = "";
	EndIf;

EndProcedure // ()

// Generates a structure of columns of imported attributes from ImportedAttributesTable table.
//
&AtServer
Procedure GenerateColumnsStructure()

	ColumnNumber = 1;
	Columns = New Structure;

	VT = FormAttributeToValue("ImportedAttributesTable");

	TempColumns = VT.CopyColumns();
	For Each ImportedAttribute In VT Do
		Column = New Structure;
		For Each ImportedAttributesColumn In TempColumns.Columns Do
			If Not Object.ManualSpreadsheetDocumentColumnsNumeration And ImportedAttributesColumn.Name
				= "ColumnNumber" Then
				If ImportedAttribute.Check Then
					Column.Insert("ColumnNumber", ColumnNumber);
					ColumnNumber = ColumnNumber + 1;
				Else
					Column.Insert("ColumnNumber", 0);
				EndIf;
			Else
				Column.Insert(ImportedAttributesColumn.Name,
					ImportedAttribute[ImportedAttributesColumn.Name]);
			EndIf;

		EndDo;

		Columns.Insert(Column.AttributeName, Column);

	EndDo;

	Object.AdditionalProperties.Insert("Columns", Columns);

EndProcedure // ()

// Generates a spreadsheet document header according to imported attributes table.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument - spreadsheet document to generate a header.
//
&AtServer
Procedure GenerateSpreadsheetDocumentHeader(SpreadsheetDocument)

	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);

	VT = FormAttributeToValue("ImportedAttributesTable");

	Table = VT.Copy();
	Table.Sort("ColumnNumber");

	Columns = Object.AdditionalProperties.Columns;

	For Each KeyValue In Columns Do
		ImportedAttribute = KeyValue.Value;
		ColumnNumber = ImportedAttribute.ColumnNumber;
		If Not ImportedAttribute.Check Or ColumnNumber = 0 Then
			Continue;
		EndIf;

		If ImportedAttribute.ColumnWidth = 0 Then

			ColumnWidth = 40;
			If ImportedAttribute.TypeDescription.Types().Count() = 1 Then
				FirstType = ImportedAttribute.TypeDescription.Types()[0];
				If FirstType = Type("String") Then
					If ImportedAttribute.TypeDescription.StringQualifiers.Length = 0 Then
						ColumnWidth = 80;
					Else
						ColumnWidth = Min(Max(ImportedAttribute.TypeDescription.StringQualifiers.Length, 10), 80);
					EndIf;
				ElsIf FirstType = Type("Number") Then
					ColumnWidth = Max(ImportedAttribute.TypeDescription.NumberQualifiers.Digits, 10);
				ElsIf FirstType = Type("Boolean") Then
					ColumnWidth = 10;
				EndIf;
			EndIf;
		Else
			ColumnWidth = ImportedAttribute.ColumnWidth;
		EndIf;
		Area = SpreadsheetDocument.Area("R1C" + ColumnNumber);
		HasText = Not IsBlankString(Area.Text);
		Area.Text       = ?(HasText, Area.Text + Chars.LF, "") + ImportedAttribute.AttributePresentation;
		Area.Details = ImportedAttribute.AttributeName;
		Area.BackColor = StyleColors.FormBackColor;
		Area.Outline(Line, Line, Line, Line);

		ColumnArea = SpreadsheetDocument.Area("C" + ColumnNumber);
		ColumnArea.ColumnWidth = ?(HasText, Max(ColumnArea.ColumnWidth, ColumnWidth), ColumnWidth);

	EndDo;

EndProcedure // GenerateSpreadsheetDocumentHeader()

// Returns source metadata.
//
// Return value:
//  Metadata object.
//
&AtServer
Function GetSourceMetadata()

	If Object.ImportMode = 0 Then
		If Not IsBlankString(Object.CatalogObjectType) Then
			Return Metadata.Catalogs.Find(Object.CatalogObjectType);
		EndIf;
	ElsIf Object.ImportMode = 1 Then
		If Not Object.SourceRef = Undefined And Not Object.SourceTabularSection = Undefined Then
			Return Object.SourceRef.Metadata().TabularSections.Find(Object.SourceTabularSection);
		EndIf;
	ElsIf Object.ImportMode = 2 Then
		If Not IsBlankString(Object.RegisterTypeName) Then
			Return Metadata.InformationRegisters.Find(Object.RegisterTypeName);
		EndIf;
	EndIf;

	Return Undefined;

EndFunction // ()

&AtServer
Function SelectedMetadataExists()

	Return Not GetSourceMetadata() = Undefined;

EndFunction // SelectedMetadataExists()

&AtServer
Function GetSourceQuestionText()

	SourceMetadata = GetSourceMetadata();

	Error = "";
	SourceQuestionText = "";

	If Object.ImportMode = 0 Then
		SourceQuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'элементов в справочник: ""%1""'; en = 'Import items into %1 catalog'"), SourceMetadata.Presentation());

	ElsIf Object.ImportMode = 1 Then

		If Object.SourceRef.IsEmpty() Then
			Error = NStr("ru = 'Не выбрана ссылка'; en = 'Reference not selected.'");
		Else
			SourceObject = Object.SourceRef.GetObject();
			SourceQuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'строк в табличную часть: ""%1""'; en = 'Import rows into %1 tabular section'"), SourceMetadata.Presentation());
		EndIf;

	ElsIf Object.ImportMode = 2 Then

		SourceQuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'записей в регистр сведений: ""%1""'; en = 'Import records into %1 information register'"), SourceMetadata.Представление());

	EndIf;

	Return New Structure("Error, QuestionText", Error, SourceQuestionText);

EndFunction

&AtServer
Function ImportDataServer()

	WriteObject = True;
	FolderCreationEnabled = False;

	GenerateColumnsStructure();

	SourceMetadata = GetSourceMetadata();

	Columns = Object.AdditionalProperties.Колонки;

	If Object.ImportMode = 0 Then
		Source = Catalogs[Object.CatalogObjectType].EmptyRef();
	ElsIf Object.ImportMode = 1 Then
		SourceObject = Object.SourceRef.GetObject();
		Source = SourceObject[Object.SourceTabularSection];
	EndIf;

	SourceQuestionText = GetSourceQuestionText().QuestionText;
	ItemsCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;

	Query = Undefined;
	If Object.ImportMode = 0 Then

		FolderCreationEnabled = FolderCreationEnabled(SourceMetadata);
		SearchRows = ImportedAttributesTable.FindRows(New Structure("SearchField,Check", True, True));
		If Not SearchRows.Count() = 0 Then

			QueryText = "Select Top 1
						   |Catalog.Ref AS Ref
						   |From Catalog." + SourceMetadata.Name + " AS Catalog
																		|Where";

			For Each SearchRow In SearchRows Do
				QueryText = QueryText + "
											  |Catalog." + SearchRow.AttributeName + " = &"
					+ SearchRow.AttributeName + "
												  |AND";

			EndDo;

			QueryText = Left(QueryText, StrLen(QueryText) - 2);
			Query = New Query(QueryText);
		EndIf;
	ElsIf Object.ImportMode = 1 Then

		Source.Clear();
	ElsIf Object.ImportMode = 2 Then

		RegisterDimensions = New Structure;
		For Each Column In Columns Do
			If Column.Value.PossibleSearchField Then
				RegisterDimensions.Insert(Column.Key, Column.Value);
			EndIf;
		EndDo;
	EndIf;
	Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполняется загрузка %1'; en = '%1 is in progress.'"), SourceQuestionText),
	MessageStatus.Information);
	Message(NStr("ru = 'Всего: '; en = 'Total: '") + ItemsCount, MessageStatus.Information);
	Message("---------------------------------------------", MessageStatus.WithoutStatus);
	CurrentRowNumber = 0;
	Imported = 0;
	For K = Object.SpreadsheetDocumentFirstDataRow To SpreadsheetDocument.TableHeight Do
		CurrentRowNumber = CurrentRowNumber + 1;
		CellsTexts = Undefined;
		Cancel = False;
		CurrentRow = RowFillControl(SpreadsheetDocument, K, CellsTexts);
		If Object.ImportMode = 0 Then

			ImportedObject = Undefined;
			If Not Query = Undefined Then
				ErrorString = "";
				For Each SearchRow In SearchRows Do

					AttributeValue = Undefined;

					CurrentRow.Property(SearchRow.AttributeName, AttributeValue);
					If IsBlankString(AttributeValue) Then
						ErrorString = ?(IsBlankString(ErrorString), "", ErrorString + ", ")
							+ SearchRow.AttributePresentation;
					Else
						Query.SetParameter(SearchRow.AttributeName, CurrentRow[SearchRow.AttributeName]);
					EndIf;

				EndDo;

				If Not IsBlankString(ErrorString) Then
					Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Строка %1 не может быть записана. Не указано значение ключевых реквизитов: %2';
							 |en = 'Unable to write row %1. Key attributes %2 are not defined.'"), CurrentRowNumber, ErrorString),
						MessageStatus.Important);
					Continue;
				EndIf;

				Selection = Query.Execute().Select();
				If Selection.Next() Then
					ImportedObject = Selection.Ref.GetObject();
				EndIf;

			EndIf;

			ObjectFound = Not ImportedObject = Undefined;
			If Not ObjectFound Then
				If Object.DontCreateNewItems Then
					Continue;
				ElsIf FolderCreationEnabled And CurrentRow.IsFolder Then
					ImportedObject = Catalogs[SourceMetadata.Name].CreateFolder();
				Else
					ImportedObject = Catalogs[SourceMetadata.Name].CreateItem();
				EndIf;

			EndIf;
		ElsIf Object.ImportMode = 1 Then
			ImportedObject = Source.Add();
			ObjectFound = False;
		ElsIf Object.ImportMode = 2 Then
			ImportedObject = InformationRegisters[SourceMetadata.Name].CreateRecordManager();
			For Each KeyValue In CurrentRow Do

				If RegisterDimensions.Property(KeyValue.Key) Then
					ImportedObject[KeyValue.Key] = KeyValue.Value;
				EndIf;

			EndDo;

			If Not Object.ReplaceExistingRecords Then
				ImportedObject.Read();
				ObjectFound = ImportedObject.Selected();
			Else
				ObjectFound = False;
			EndIf;

		EndIf;

		For Each KeyValue In CurrentRow Do
			
			If KeyValue.Key = "IsFolder" Then
				Continue;	
			EndIf; 

			If Not ObjectFound Or Columns[KeyValue.Key].Check Then
				Try
					ImportedObject[KeyValue.Key] = KeyValue.Value;
				Except
					mErrorMessage(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при установке значения реквизита ""%1""'; en = '%1 attribute value setting error.'") + ErrorDescription(), KeyValue.Key));
					Cancel = True;
					Break;
				EndTry;
			EndIf;

		EndDo;

		If Object.ImportMode = 0 Then
			If Not Cancel And WriteObject(ImportedObject, CellsTexts, Object.BeforeWriteObject,
				Object.OnWriteObject) Then
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1 %2 справочника: %3'; en = 'Catalog %2 %3 was %1.'"),
						?(ObjectFound, NStr("ru = 'Изменен'; en = 'changed'"), NStr("ru = 'Загружен'; en = 'imported'")),
						?(ImportedObject.IsFolder, NStr("ru = 'группа'; en = 'folder'"), NStr("ru = 'элемент'; en = 'item'")),
						ImportedObject.Ref), 
					MessageStatus.Information);
				Imported = Imported + 1;
			Else
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Объект не %1. %2 справочника: %3'; en = 'Object was not %1. Catalog %2 %3.'"),
						?(ObjectFound, NStr("ru = 'изменен'; en = 'changed'"), NStr("ru = 'загружен'; en = 'imported'")),
						?(ImportedObject.IsFolder, NStr("ru = 'Группа'; en = 'folder'"), NStr("ru = 'Элемент'; en = 'item'")),
						ImportedObject),
					MessageStatus.Important);
			EndIf;
		ElsIf Object.ImportMode = 1 Then

			If Not AfterAddRowEventHandler(SourceObject, ImportedObject, CellsTexts,
				Object.AfterAddRow) Then
				Cancel = True;
			EndIf;

			If Not Cancel Then
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Добавлена строка: %1; 'Row %1 added.'"), (Imported + 1)));
			Else
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'При добавлении строки %1 возникли ошибки.'; en = 'An error occured while adding row %1.'"), (Imported + 1)));
				WriteObject = False;
			EndIf;

			Imported = Imported + 1;

		ElsIf Object.ImportMode = 2 Then
			If Not Cancel And WriteObject(ImportedObject, CellsTexts, Object.BeforeWriteObject,
				Object.OnWriteObject) Then
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = '%1 запись № %2.'; en = 'Record %2 was %1.'"),
					?(ObjectFound, NStr("ru = 'Изменена'; en = 'changed'"), NStr("ru = 'Добавлена'; en = 'added'")), CurrentRowNumber));
				Imported = Imported + 1;
			Else
				Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Запись не %1. № записи: %2.'; en = 'Record was not %1. Record no. %2.'"),
					?(ObjectFound, NStr("ru = 'изменена'; en = 'changed'"), NStr("ru = 'загружена'; en = 'imported'")), CurrentRowNumber), 
				MessageStatus.Important);
			EndIf;
		EndIf;

	EndDo;
	Message("---------------------------------------------", MessageStatus.WithoutStatus);

	If Object.ImportMode = 1 Then
		If WriteObject And WriteObject(SourceObject, "", Object.BeforeWriteObject,
			Object.OnWriteObject) Then

			Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Выполнена загрузка %1'; en = '%1 was executed'"), SourceQuestionText), 
			MessageStatus.Information);
			Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = '%1 из %2 элементов.'; en = '%1 out of %2 items.'"), Imported, ItemsCount), 
			MessageStatus.Information);
			Return True;
		Else
			Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Объект не записан: %1.'; en = 'Object %1 was not written.'"), ImportedObject),
			MessageStatus.Important);
			Return False;
		EndIf;
	ElsIf Object.ImportMode = 0 Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполнена загрузка %1'; en = '%1 was executed'"), SourceQuestionText), 
		MessageStatus.Information);
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 из %2 элементов.'; en = '%1 out of %2 items.'"), Imported, ItemsCount), 
		MessageStatus.Information);
		Return True;
	ElsIf Object.ImportMode = 2 Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выполнена загрузка %1'; en = '%1 was executed'"), SourceQuestionText), 
		MessageStatus.Information);
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = '%1 из %2 записей.'; en = '%1 out of %2 records.'"), Imported, ItemsCount), 
		MessageStatus.Information);
		Return True;
	EndIf;

EndFunction

// Checks if folders are available for metadata type.
//
// Parameters:
//  SourceMetadata - Metadata - object metadata.
//
// Return value:
//  Boolean - True, if folders are available.
//
&AtServer
Function FolderCreationEnabled(Val SourceMetadata)
	
	Return SourceMetadata.Hierarchical 
			And SourceMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;

EndFunction // ()

// Evaluates cell value for Evaluate mode.
//
// Parameters:
//  Expression - String - a code to execute.
//  CurrentData  - Structure - imported values.
//  CellText    - String - a text of a current cell.
//  CellsTexts    - Array - a texts of a current row cells.
//  Result      - Arbitrary - a result of a code execution.
//
// Return value:
//  Structure - Result and ErrorDescription.
//
&AtServerNoContext
Function EvaluateCellValue(Val Expression, Val CurrentData, Val CellText, Val CellsTexts, Val Result)

	CellText = TrimAll(CellText);
	ErrorDescription = "";
	Try
		Execute (Expression);
	Except
		mErrorMessage(ErrorDescription());
	EndTry;

	Return New Structure("Result,ErrorDescription", Result, ErrorDescription);

EndFunction

// Writes an object to the infodatabase
// using events defined by the user in the event edit form.
//
// Parameters:
//  Object - CatalogObject, DocumentObject, etc - an object to write.
//  CellsTexts - Array - a texts of a imported row cells.
//  BeforeWriteObject - String - before write event handler.
//  OnWriteObject - String - on write event handler.
//
// Return value:
//  Boolean - True, If object successfully written, False - if there was an error.
//
&AtServerNoContext
Function WriteObject(Object, CellsTexts = Undefined, BeforeWriteObject, OnWriteObject)

	Cancel = False;
	BeginTransaction();
	If Not IsBlankString(BeforeWriteObject) Then
		Try
			Execute (BeforeWriteObject);
			If Cancel Then
				ErrorDescription = "";//Cancel was set to True in the BeforeWriteObject event handler
			EndIf;
		Except
			Cancel = True;
			ErrorDescription = ErrorDescription();
		EndTry;
	EndIf;

	If Not Cancel Then
		Try
			Object.Write();
		Except
			Cancel = True;
			ErrorDescription = ErrorDescription();
		EndTry;
	EndIf;

	If Not Cancel And Not IsBlankString(OnWriteObject) Then

		Try
			Execute (OnWriteObject);
			If Cancel Then
				ErrorDescription = "";//Cancel was set to True in the OnWriteObject event handler
			EndIf;

		Except
			Cancel = True;
			ErrorDescription = ErrorDescription();
		EndTry;

		If Not Cancel Then
			Try
				Object.Write();
			Except
				Cancel = True;
				ErrorDescription = ErrorDescription();
			EndTry;
		EndIf;

	EndIf;

	If Not Cancel Then
		CommitTransaction();
	Else
		mErrorMessage(ErrorDescription);
		RollbackTransaction();
	EndIf;

	Return Not Cancel;

EndFunction // ()

// Executes the AfterAddRow event handler
// defined by the user in the event edit form.
//
// Parameters:
//  Object - CatalogObject, DocumentObject, etc - an object to write.
//  CurrentData  - Structure - imported values.
//  CellsTexts    - Array - a texts of a current row cells.
//  AfterAddRow - String - after add row event handler.
//
// Return value:
//  True, If Cancel was not set in the AfterAddRow event handler.
//
&AtServerNoContext
Function AfterAddRowEventHandler(Object, CurrentData, CellsTexts, AfterAddRow)

	Try

		Execute (AfterAddRow);

	Except

		mErrorMessage(ErrorDescription());
		Return False;

	EndTry;

	Return True;

EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Controls a spreadsheet document data filling.
// Messages an errors and sets an error cells comments.
//
// Parameters:
//  SpreadsheetDocument - spreadsheet document to generate the header.
//
&AtServer
Procedure FillControl(SpreadsheetDocument) Export

	ItemCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;

	ErrorCount = 0;
	For K = 0 To ItemCount - 1 Do
		//Status(UT_StringFunctionsClientServer.SubstituteParametersToString(
		//NStr("ru = 'Выполняется контроль заполнения строки № %1'; en = 'Row no. %1 fill control is in progress.'"), (К + 1)));
		RowFillControl(SpreadsheetDocument, K + Object.SpreadsheetDocumentFirstDataRow, ,
			ErrorCount);
	EndDo;

	Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Контроль заполнения завершен. Проверено строк: %1'; en = 'Fill control completed. %1 rows was checked.'"), ItemCount));
	If ErrorCount Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выявлено ячеек, содержащих ошибки/неоднозначное представление: %1'; en = '%1 cells with errors/ambiguous presentation was found.'"), ErrorCount));
	Else
		Message(NStr("ru = 'Ячеек, содержащих ошибки не выявлено'; en = 'No error cell was found.'"));
	EndIf;

EndProcedure // FillControl()

// Controls a spreadsheet document row data filling.
// Messages an errors and writes an error cells comments.
//
// Параметры:
//  SpreadsheetDocument - spreadsheet document to generate the header.
//  RowNumber       - Number - spreadsheet document row number.
//  CellsTexts    - Array - a texts of a row cells.
//  ErrorCount 	- Number - a count of errors.
//
// Return value:
//  Structure - 
//  	Key - imported attrubure name.
//  	Value - imported attribute value.
//
&AtServer
Function RowFillControl(SpreadsheetDocument, RowNumber, CellsTexts = Undefined, ErrorCount = 0)

	CellsTexts = New Array;
	CellsTexts.Add(Undefined);
	For K = 1 To SpreadsheetDocument.TableWidth Do
		CellsTexts.Add(TrimAll(SpreadsheetDocument.Area("R" + Format(RowNumber, "NG=") + "C" + Format(K,
			"NG=")).Text));
	EndDo;

	Columns = Object.AdditionalProperties.Columns;

	CurrentRow     = New Structure;
	For Each KeyValue In Columns Do

		Column = KeyValue.Value;

		If Column.Check Then

			If Column.ImportMode = "Set" Then

				Result = Column.DefaultValue;
				CurrentRow.Insert(Column.AttributeName, Result);

			ElsIf Not Column.ColumnNumber = 0 Then

				If Not ProcessArea(SpreadsheetDocument.Area("R" + Format(RowNumber, "NG=") + "C" + Format(
					Column.ColumnNumber, "NG=")), Column, CurrentRow, CellsTexts) Then
					ErrorCount = ErrorCount + 1;
				EndIf;

			ElsIf Column.ImportMode = "Evaluate" Then

				Evaluation  = EvaluateCellValue(Column.Expression, CurrentRow, "", CellsTexts,
					Column.DefaultValue);
				Result   = Evaluation.Result;
				Note  = Evaluation.ErrorDescription;

				If Not ValueIsFilled(Result) Then
					Result = Column.DefaultValue;
				EndIf;

				CurrentRow.Insert(Column.AttributeName, Result);

				If Not IsBlankString(Note) Then
					Message(NStr("ru = 'Строка ['; en = 'Row ['") + RowNumber + "](" + Column.AttributePresentation + "): " + Note);
					ErrorCount = ErrorCount + 1;
				EndIf;

			EndIf;

		EndIf;

	EndDo;
	Return CurrentRow;

EndFunction

// Processes a spreadsheet document area:
// fills the details by the cell presentation according to imported attributes structure.
// If the cell contains an error, messages an error and writes a comment.
//
// Parameters:
//  Area - SpreadsheetDocumentRange - spreadsheet document cells range.
//  Column - Structure - properties, according to which the processing will be executed.
//  CurrentData  - Structure - imported values.
//  CellsTexts    - Array - a texts of a row cells.
//
&AtServer
Function ProcessArea(Area, Column, CurrentData, CellsTexts)

	Presentation = Area.Text;
	Note = "";

	If Column.ImportMode = "Evaluate" Then

		Evaluation = EvaluateCellValue(Column.Expression, CurrentData, Presentation, CellsTexts,
			Column.DefaultValue);
		If Not IsBlankString(Evaluation.ErrorDescription) Then
			Result   = Undefined;
			Note = "" + Evaluation.ErrorDescription;
		Else
			Result = Evaluation.Result;
		EndIf;

	ElsIf IsBlankString(Presentation) Then
		Result = Undefined;
	Else
		FoundValues = GetPossibleValues(Column, Presentation, Note, CurrentData);

		If FoundValues.Count() = 0 Then

			Note = NStr("ru = 'Не найден'; en = 'Not found'") + ?(Note = "", "", Chars.LF + Note);
			Result = Undefined;

		ElsIf FoundValues.Count() = 1 Then

			Result = FoundValues[0];
		Else

			Note = UT_StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не однозначное представление. Вариантов: %1'; en = 'Ambiguous presentation. %1 options.'"), FoundValues.Количество()) + 
				?(Note = "", "", Chars.LF + Note);

			Found = False;
			FoundDefaultValue = False;
			For Each FoundValue In FoundValues Do
				If FoundValue = Area.Details Then
					Found = True;
					Break;
				EndIf;
				If FoundValue = Column.DefaultValue Then
					FoundDefaultValue = True;
				EndIf;
			EndDo;

			If Not Found Then

				If FoundDefaultValue Then
					FoundValue = Column.DefaultValue;
				Else
					FoundValue = FoundValues[0];
				EndIf;
			EndIf;
			Result = FoundValue;
		EndIf;
	EndIf;

	If Not ValueIsFilled(Result) Then
		Result = Column.DefaultValue;
	EndIf;

	CurrentData.Insert(Column.AttributeName, Result);

	Area.Details = Result;
	Area.Note.Text = Note;

	If Не IsBlankString(Note) Then
		Message(NStr("ru = 'Ячейка['; en = 'Cell['") + Area.Name + "](" + Column.AttributePresentation + "): " + Note);
	EndIf;

	Return IsBlankString(Note);

EndFunction

// Returns an array of current row possible values by presentation.
//
// Parameters:
//  Column - Structure - properties, according to which the possible values will be getting.
//  Presentation - String - string, by which the possible values will be getting.
//  Note    - Array - a texts of a row cells.
//  CurrentData  - Structure - imported values.
//
// Return value:
//  Array of possible values.
//
&AtServer
Function GetPossibleValues(Column, Presentation, Note, CurrentData)
	Note = "";

	FoundValues = New Array;

	If IsBlankString(Presentation) Then

		Return FoundValues;

	Else
		LinkByType = Undefined;
		If Not IsBlankString(Column.LinkByType) Then

			If TypeOf(Column.LinkByType) = Type("String") Then
				CurrentData.Property(Column.LinkByType, LinkByType);
			Else
				LinkByType = Column.LinkByType;
			EndIf;
			If Not LinkByType = Undefined Then

				LinkByTypeItem = Column.LinkByTypeItem;
				If LinkByTypeItem = 0 Then
					LinkByTypeItem = 1;
				EndIf;
				ExtDimensionTypes = LinkByType.ExtDimensionTypes;
				If LinkByTypeItem > ExtDimensionTypes.Count() Then
					Return FoundValues;
				EndIf;
				Type = LinkByType.ExtDimensionTypes[LinkByTypeItem - 1].ExtDimensionType.ValueType;
			Else
				Type = Column.TypeDescription;
			EndIf;

		Else
			Type = Column.TypeDescription;
		EndIf;
	EndIf;
	PrimitiveTypes = New Structure("Number, String, Date, Boolean", Type("Number"), Type("String"), Type("Date"), Type(
		"Boolean"));
	For Each AttributeType In Type.Types() Do

		If AttributeType = PrimitiveTypes.Number Or AttributeType = PrimitiveTypes.Boolean Then
			FoundValues.Add(mAdjustToNumber(Presentation, Column.TypeDescription, Note));
		ElsIf AttributeType = PrimitiveTypes.String Или AttributeType = PrimitiveTypes.Date Then
			FoundValues.Add(mAdjustToDate(Presentation, Column.TypeDescription, Note));

		Else

			TypeMetadata = Metadata.FindByType(AttributeType);

			If Enums.AllRefsType().ContainsType(AttributeType) Then
				
				//Enumeration
				For Each Enum In GetManagerByType(AttributeType) Do
					If String(Enum) = Presentation Then
						FoundValues.Add(Enum);
					EndIf;
				EndDo;

			ElsIf Documents.AllRefsType().ContainsType(AttributeType) Then
				
				//Document

				Manager = GetManagerByType(AttributeType);
				If Column.SearchBy = "Number" Then
					//FoundValue = Manager.FindByCode(Presentation);
				ElsIf Column.SearchBy = "Date" Then
					//FoundValue = Manager.Find
				Else

					SynonymLength = StrLen("" + TypeMetadata);

					If Left(Presentation, SynonymLength) = "" + TypeMetadata Then
						NumberAndDate = TrimAll(Mid(Presentation, SynonymLength + 1));
						PositionFrom = Find(NumberAndDate, NStr("ru = ' от '; en = ' from '"));
						If Not PositionFrom = 0 Then
							DocNumber = Left(NumberAndDate, PositionFrom - 1);
							Try
								DocDate  = Date(Mid(NumberAndDate, PositionFrom + 4));
							Except
								DocDate = Undefined;
							EndTry;
							If Not DocDate = Undefined Then
								FoundValue = Manager.FindByNumber(DocNumber, DocDate);
								If Not FoundValue.IsEmpty() Then
									FoundValues.Add(FoundValue);
								EndIf;
							EndIf;
						EndIf;
					EndIf;

				EndIf;

			ElsIf Not TypeMetadata = Undefined Then

				SearchBy = Column.SearchBy;
				IsCatalog = Catalogs.AllRefsType().ContainsType(AttributeType);
				If IsBlankString(SearchBy) Then
					DefaultPresentationString = String(TypeMetadata.DefaultPresentation);

					If DefaultPresentationString = "AsCode" Then
						SearchBy = "Code";
					ElsIf DefaultPresentationString = "AsDescription" Then
						SearchBy = "Description";
					ElsIf DefaultPresentationString = "AsNumber" Then
						SearchBy = "Number";
					EndIf;
				EndIf;
				Query = New Query;
				Query.Text = "SELECT
							 |	_Table.Ref
							 |FROM
							 |	" + TypeMetadata.FullName() + " AS _Table
															  |WHERE";

				Query.Text = Query.Text + "
											  |	Table." + SearchBy + " = &Presentation";
				Query.SetParameter("Presentation", Presentation);

				If IsCatalog And Not IsBlankString(Column.LinkByOwner) And TypeMetadata.Owners.Count() Then

					LinkByOwner = Undefined;
					If TypeOf(Column.LinkByOwner) = Type("String") Then
						CurrentData.Property(Column.LinkByOwner, LinkByOwner);
					Else
						LinkByOwner = Column.LinkByOwner;
					EndIf;

					If Not LinkByOwner = Undefined Then
						Query.Text = Query.Text + "
													  |	AND _Table.Owner = &LinkByOwner";
						Query.SetParameter("LinkByOwner", LinkByOwner);
					EndIf;

				EndIf;

				Selection =  Query.Execute().Select();

				While Selection.Next() Do
					FoundValues.Add(Selection.Ref);
				EndDo;
			Else
				Note = NStr("ru = 'Не описан способ поиска'; en = 'Search type is not defined.'");
				Note = NStr("ru = 'Для Колонки не определен тип значения'; en = 'Column value type is not defined.'");
			EndIf;
		EndIf;

	EndDo;
	Return FoundValues;
EndFunction // ()

////////////////////////////////////////////////////////////////////////////////
//

// Returns an array of imported attribute possible presentations.
//
// Parameters:
//  TypeDescription - Type description.
//
// Return value:
//  Value list - presentations.
//
&AtServer
Function GetNamePresentationList(TypeDescription)

	ChioceList = New ValueList;
	If TypeDescription.Types().Count() = 1 Then

		Type = TypeDescription.Types()[0];

		TypeMetadata      = Метаданные.НайтиПоТипу(Type);
		IsCatalog       = Catalogs.AllRefsType().ContainsType(Type);
		IsAccount             = ChartsOfAccounts.AllRefsType().ContainsType(Type);
		IsCharacteristicType = ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type);
		If IsCatalog Or IsAccount Or IsCharacteristicType Then

			CodeExists = TypeMetadata.CodeLength > 0;
			NameExists = TypeMetadata.DescriptionLength > 0;

			DefaultPresentationType = ?(IsCatalog, Metadata.ObjectProperties.CatalogMainPresentation,
				?(IsAccount, Metadata.ObjectProperties.AccountMainPresentation,
				Metadata.ObjectProperties.CharacteristicTypeMainPresentation));

			If TypeMetadata.DefaultPresentation = DefaultPresentationType.AsCode Then

				If CodeExists Then
					ChioceList.Add("Code", "Code");
				EndIf;

				If NameExists Then
					ChioceList.Add("Description", "Description");
				EndIf;

			Else

				If NameExists Then
					ChioceList.Add("Description", "Description");
				EndIf;

				If CodeExists Then
					ChioceList.Add("Code", "Code");
				EndIf;

			EndIf;

			For Each Attribute In TypeMetadata.Attributes Do

				If Not Attribute.Indexing = Metadata.ObjectProperties.Indexing.DontIndex
					And Attribute.Type.Types().Count() = 1 And Attribute.Type.Types()[0] = Type("String") Then

					ChioceList.Add(Attribute.Name, Attribute.Presentation());

				EndIf;

			EndDo;
		Else
		
		EndIf;

	EndIf;
	Return ChioceList;
EndFunction // ()

// Returns a list of imported attribute links by type.
//
// Parameters:
//  ImportedAttribute - ValueTableRow - imported attribute.
//  VT - ValueTable - imported attributes table.
//
// Return value:
//  ValueList - list of link column names or link item references.
//
&AtServer
Function GetLinkByTypeList(ImportedAttribute, VT)

	ChoiceList = New ValueList;

	PossibleChartsOfAccounts = New Structure;
	For Each ChartOfAccounts In Metadata.ChartsOfAccounts Do
		Try
			If ChartOfAccounts.ExtDimensionTypes.Type = ImportedAttribute.TypeDescription Then

				PossibleChartsOfAccounts.Insert(ChartOfAccounts.Name, ChartsOfAccounts[ChartOfAccounts.Name]);

			EndIf;
		Except

		EndTry;
	EndDo;

	For Each ChartOfAccounts In PossibleChartsOfAccounts Do
		TypeOfChartOfAccounts = TypeOf(ChartOfAccounts.Value.EmptyRef());
		For Each LinkByTypeColumn In VT Do
			If LinkByTypeColumn.TypeDescription.Types()[0] = TypeOfChartOfAccounts Then
				ChoiceList.Add(LinkByTypeColumn.AttributeName, LinkByTypeColumn.AttributeName);
			EndIf;
		EndDo;
	EndDo;

	If Not PossibleChartsOfAccounts.Count() = 0 Then
		ChoiceList.Add(Undefined, NStr("ru = '< пустое значение >' en = '< empty value >'"));
	EndIf;

	For Each ChartOfAccounts In PossibleChartsOfAccounts Do
		ChoiceList.Add("ChartOfAccountsRef." + ChartOfAccounts.Key, "<" + ChartOfAccounts.Key + ">");
	EndDo;

	Return ChoiceList;
EndFunction // ()

// Returns a list of imported attribute links by owner.
//
// Parameters:
//  TypeDescription - type description.
//  ColumnTable - ValueTable - a table of link by owner columns.
//
// Return value:
//  ValueList - list of link column names or link item references.
//
&AtServer
Function GetLinkByOwnerList(TypeDescription, ColumnTable)

	ThisObjectTypeExists = False;
	SourceMetadata = GetSourceMetadata();
	If Object.ImportMode = 0 Then
		CatalogTypeDescription = Type(StrReplace(SourceMetadata.FullName(), ".", "Ref."));
	Else
		CatalogTypeDescription = Undefined;
	EndIf;

	ChoiceList = New ValueList;
	OwnerTypes = New Map;
	For Each ColumnType In TypeDescription.Types() Do
		If Catalogs.AllRefsType().ContainsType(ColumnType) Then
			For Each Owner In Metadata.FindByType(ColumnType).Owners Do
				OwnerType   = Type(StrReplace(Owner.FullName(), ".", "Ref."));
				If OwnerTypes[OwnerType] = Undefined Then

					If OwnerType = CatalogTypeDescription Then

						ThisObjectTypeExists = True;

					EndIf;

					OwnerTypes.Insert(Owner.FullName(), Owner.FullName());
					For Each LinkByOwnerColumn In ColumnTable Do
						If LinkByOwnerColumn.TypeDescription.Types()[0] = OwnerType
							And ChoiceList.FindByValue(LinkByOwnerColumn.AttributeName) = Undefined Then
							ChoiceList.Add(LinkByOwnerColumn.AttributeName,
								LinkByOwnerColumn.AttributeName);
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndDo;

	If Not OwnerTypes.Count() = 0 Then
		ChoiceList.Add(Undefined, NStr("ru = '< пустое значение >'; en = '< empty value >'"));
	EndIf;
	For Each KeyValue In OwnerTypes Do
		ChoiceList.Add(KeyValue.Value, "<" + KeyValue.Value + ">");
	EndDo;

	If ThisObjectTypeExists Then

		ChoiceList.Insert(0, NStr("ru = '<Создаваемый объект>'; en = '<This object>'"), NStr("ru = '<Создаваемый объект>'; en = '<This object>'"));

	EndIf;

	Return ChoiceList;

EndFunction // ()

// Returns a choice list cached in the attribute value table.
//
// Parameters:
//  AttributeName  - String - name of an attribute to get a related choice list.
//
// Return value:
//   ValueList - list of values to choice.
//
&AtServer
Function GetLinkByOwnerChoiceList(AttributeName)

	VT = FormAttributeToValue("LinkByOwnerChoiceLists");
	Str = VT.Find(AttributeName, "AttributeName");

	Return Str.ChioceList;

EndFunction // GetLinkByOwnerChoiceList()

// Saves an attribute chioce list to cache.
//
// Parameters:
//  AttributeName  - String - name of an attribute to save a related choice list.
//  NewChoiceList  - ValueList - list of values to save.
//
&AtServer
Procedure SaveLinkByOwnerChoiceList(AttributeName, Val NewChoiceList)

	VT = FormAttributeToValue("LinkByOwnerChoiceLists");
	Str = VT.Find(AttributeName, "AttributeName");
	Str.ChoiceList = NewChoiceList;
	ValueToFormAttribute(VT, "LinkByOwnerChoiceLists");

EndProcedure // SaveLinkByOwnerChoiceList()

&AtServer
Procedure FillControlServer()

	GenerateColumnsStructure();
	ItemCount = SpreadsheetDocument.TableHeight - Object.SpreadsheetDocumentFirstDataRow + 1;

	ErrorCount = 0;
	For K = 0 To ItemCount - 1 Do
		//Status(UT_StringFunctionsClientServer.SubstituteParametersToString(
		//NStr("ru = 'Выполняется контроль заполнения строки № %1'; en = 'Row no. %1 fill control is in progress.'"), (К + 1)));
		RowFillControl(SpreadsheetDocument, K + Object.SpreadsheetDocumentFirstDataRow, ,
			ErrorCount);
	EndDo;

	Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Контроль заполнения завершен. Проверено строк: %1'; en = 'Fill control completed. %1 rows was checked.'"), ItemCount));
	If ErrorCount Then
		Message(UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Выявлено ячеек, содержащих ошибки/неоднозначное представление: %1'; en = '%1 cells with errors/ambiguous presentation was found.'"), ErrorCount));
	Else
		Message(NStr("ru = 'Ячеек, содержащих ошибки не выявлено'; en = 'No error cell was found.'"));
	EndIf;

EndProcedure // FillControlServer()

////////////////////////////////////////////////////////////////////////////////
//

// Fills column settings by default or by passed settings.
//
// Parameters:
//  Settings - SpreadsheetDocument or Undefined.
//
&AtServer
Procedure FillColumnSettings(Settings)

	BeforeWriteObject   = "";
	OnWriteObject      = "";
	AfterAddRow = "";

	If TypeOf(Settings) = Type("SpreadsheetDocument") Then

		DataProcessorVersion = TrimAll(Settings.Area("R1C5").Text);
		If DataProcessorVersion = "1.2" Then
			CurrentRow = 11; //Attribute table start row
		ElsIf DataProcessorVersion = "1.3" Then
			CurrentRow = 11; //Attribute table start row			
		Else
			DataProcessorVersion = "1.1";
			CurrentRow = 9; //Attribute table start row
		EndIf;
		Try

			RestoredImportModeText = TrimAll(Settings.Area(?(DataProcessorVersion = "1.1", "R1", "R2")
				+ "C5").Text);
			If RestoredImportModeText = NStr("ru = 'в справочник'; en = 'to catalog'") Or RestoredImportModeText = "" Then
				RestoredImportMode = 0;
			ElsIf RestoredImportModeText = NStr("ru = 'в табличную часть'; en = 'to tabular section'") Or RestoredImportModeText = "Х" Then
				RestoredImportMode = 1;
			ElsIf RestoredImportModeText = NStr("ru = 'в регистр сведений'; en = 'to information register'") Then
				RestoredImportMode = 2;
			EndIf;

			ObjectMetadata = Metadata.FindByFullName(Settings.Area(?(DataProcessorVersion = "1.1", "R2", "R3")
				+ "C5").Text);
			If ObjectMetadata = Undefined Then
				Raise NStr("ru = 'Неправильный формат файла'; en = 'Invalid file format'");
			EndIf;

			If RestoredImportMode = 0 Then
				RestoredSourceRef = New (StrReplace(ObjectMetadata.FullName(), ".", "Ref."));
			ElsIf RestoredImportMode = 1 Then
				RestoredSourceRef = New (StrReplace(ObjectMetadata.Parent().FullName(), ".",
					"Ref."));
			Else
				RestoredSourceRef = Undefined;
			EndIf;
			
			//SourceRef = EmptyRef();
			DefaultsStructure = New Structure;
			CurrentAreaRow = "R" + Format(CurrentRow, "NG=");
			AttributeName = Settings.Area(CurrentAreaRow + "C2").Text;
			While Not IsBlankString(AttributeName) Do
				AttributeDefaultStructure = New Structure;
				AttributeDefaultStructure.Insert("AttributeName", AttributeName);
				AttributeDefaultStructure.Insert("Check", Not IsBlankString(Settings.Area(CurrentAreaRow
					+ "C1").Text));
				AttributeDefaultStructure.Insert("SearchField", Not IsBlankString(Settings.Area(
					CurrentAreaRow + "C3").Text));

				Types = New Array;
				TypeDescriptionString = Settings.Area(CurrentAreaRow + "C4").Text;
				For k = 1 To StrLineCount(TypeDescriptionString) Do

					sq = Undefined;
					nq = Undefined;
					dq = Undefined;
					TypeFractionsArray = mSplitStringIntoSubstringsArray(Lower(TrimAll(StrGetLine(
						TypeDescriptionString, k))), ",");
					If TypeFractionsArray.Count() = 0 Then
						Continue;
					ElsIf Find(TypeFractionsArray[0], ".") Then
						Type = Type(StrReplace(TypeFractionsArray[0], ".", "Ref."));
					ElsIf TypeFractionsArray[0] = NStr("ru = 'строка'; en = 'string'") Then
						Type = Type("String");
						If TypeFractionsArray.Count() = 2 Then
							sq = New StringQualifiers(mAdjustToNumber(TypeFractionsArray[1]),
								AllowedLength.Variable);
						ElsIf TypeFractionsArray.Count() = 3 Then
							sq = New StringQualifiers(mAdjustToNumber(TypeFractionsArray[1]),
								AllowedLength.Fixed);
						Else
							sq = New StringQualifiers;
						EndIf;
					ElsIf TypeFractionsArray[0] = NStr("ru = 'число'; en = 'number'") Then
						Type = Type("Number");
						nq = New NumberQualifiers(mAdjustToNumber(TypeFractionsArray[1]), mAdjustToNumber(
							TypeFractionsArray[2]), ?(TypeFractionsArray.Count() = 4, AllowedSign.Nonnegative,
							AllowedSign.Any));
					ElsIf TypeFractionsArray[0] = NStr("ru = 'булево'; en = 'boolean'") Then
						Type = Type("Boolean");
					ElsIf TypeFractionsArray[0] = NStr("ru = 'дата'; en = 'date'") Then
						Type = Type("Date");
						dq = New DateQualifiers(DateFractions.Date);
					ElsIf TypeFractionsArray[0] = NStr("ru = 'время'; en = 'time'") Then
						Type = Type("Date");
						dq = New DateQualifiers(DateFractions.Time);
					ElsIf TypeFractionsArray[0] = NStr("ru = 'дата и время'; en = 'date and time'") Then
						Type = Type("Date");
						dq = New DateQualifiers(DateFractions.DateTime);
					Else
						Continue;
					EndIf;
					Types.Add(Type);
				EndDo;
				TypeDescription = New TypeDescription(Types, nq, sq, dq);
				AttributeDefaultStructure.Insert("TypeDescription", TypeDescription);

				AttributeImportMode = Settings.Area(CurrentAreaRow + "C5").Text;

				AttributeDefaultStructure.Insert("ImportMode", AttributeImportMode);

				DefaultValue = Settings.Area(CurrentAreaRow + "C6").Text;
				AttributeDefaultStructure.Insert("DefaultValue", ?(IsBlankString(DefaultValue),
					TypeDescription.AdjustValue(Undefined), ValueFromStringInternal(DefaultValue)));

				If AttributeImportMode = "Evaluate" Then
					AttributeDefaultStructure.Insert("Expression", Settings.Area(CurrentAreaRow
						+ "C7").Text);
				Else
					AttributeDefaultStructure.Insert("SearchBy", Settings.Area(CurrentAreaRow
						+ "C7").Text);

					LinkByOwner   = Settings.Area(CurrentAreaRow + "C8").Text;
					AttributeDefaultStructure.Insert("LinkByOwner", ?(Left(LinkByOwner, 1) = "{",
						ValueFromStringInternal(LinkByOwner), LinkByOwner));

					LinkByType        = Settings.Area(CurrentAreaRow + "C9").Text;
					AttributeDefaultStructure.Insert("LinkByType", ?(Left(LinkByType, 1) = "{",
						ValueFromStringInternal(LinkByType), LinkByType));

					AttributeDefaultStructure.Insert("LinkByTypeItem", mAdjustToNumber(Settings.Area(
						CurrentAreaRow + "C10").Text));
				EndIf;
				If DataProcessorVersion = "1.3" Then
					AttributeDefaultStructure.Insert("ColumnNumber", mAdjustToNumber(Settings.Area(
						CurrentAreaRow + "C11").Text));
				EndIf;

				DefaultsStructure.Insert(AttributeName, AttributeDefaultStructure);
				CurrentRow = CurrentRow + 1;
				CurrentAreaRow = "R" + Format(CurrentRow, "NG=");
				AttributeName = Settings.Area(CurrentAreaRow + "C2").Text;

			EndDo;

		Except
			mErrorMessage(ErrorDescription());
		EndTry;
		
		//SourceMetadata = GetSourceMetadata();
		//If SourceMetadata = Undefined Then
		//	Return;
		//EndIf;

		Object.ImportMode   = RestoredImportMode;
		If RestoredImportMode = 0 Then
			Object.CatalogObjectType = ObjectMetadata.Name;
		ElsIf RestoredImportMode = 1 Then
			//Object.SourceRef = RestoredSourceRef;
			Object.SourceTabularSection = ?(RestoredImportMode, ObjectMetadata.Name, Undefined);
		ElsIf RestoredImportMode = 2 Then
			Object.RegisterTypeName = ObjectMetadata.Name;
		EndIf;
		Object.DontCreateNewItems                 = Not IsBlankString(Settings.Area(?(DataProcessorVersion = "1.1",
			"R3", "R4") + "C5").Text);
		Object.ReplaceExistingRecords = ?(DataProcessorVersion = "1.1", False, Not IsBlankString(Settings.Area(
			"R5C5").Text));
		Object.ManualSpreadsheetDocumentColumnsNumeration = Not IsBlankString(Settings.Area(?(DataProcessorVersion = "1.1",
			"R4", "R6") + "C5").Text);
		Object.SpreadsheetDocumentFirstDataRow     = mAdjustToNumber(Settings.Area(?(DataProcessorVersion = "1.1",
			"R5", "R7") + "C5").Text);

		Object.BeforeWriteObject = Settings.Area("R" + Format(CurrentRow + 2, "NG=") + "C3").Text;
		Object.OnWriteObject    = Settings.Area("R" + Format(CurrentRow + 3, "NG=") + "C3").Text;

		If Object.ImportMode Then
			Object.AfterAddRow = Settings.Area("R" + Format(CurrentRow + 4, "NG=") + "C3").Text;
		EndIf;

		CurrentRow = CurrentRow + 1;

	EndIf;
	Appearance = Undefined;
	//SourceMetadata = GetSourceMetadata();

	VT = FormAttributeToValue("ImportedAttributesTable");

	VT.Clear();

	If Object.ImportMode = 0 Then
		FillCatalogColumnSettings(VT);
	ElsIf Object.ImportMode = 1 Then
		FillTabularSectionColumnSettings(VT);
	ElsIf Object.ImportMode = 2 Then
		FillInformationRegisterColumnSettings(VT);
	EndIf;

	If Not DefaultsStructure = Undefined Then

		AppearanceColumnNumber = 0;
		ColumnNumber = 1;
		For Each KeyValue In DefaultsStructure Do
			Column = KeyValue.Value;
			ImportedAttribute = VT.Find(Column.AttributeName, "AttributeName");
			If Not ImportedAttribute = Undefined Then
				Index = VT.Index(ImportedAttribute);
				If Index >= AppearanceColumnNumber Then
					FillPropertyValues(ImportedAttribute, Column);

					VT.Move(ImportedAttribute, AppearanceColumnNumber - Index);
					If Column.Check And Not DataProcessorVersion = "1.3" Then
						ImportedAttribute.ColumnNumber = ColumnNumber;
						ColumnNumber = ColumnNumber + 1;
					EndIf;
					AppearanceColumnNumber = AppearanceColumnNumber + 1;

				EndIf;
			EndIf;

		EndDo;

	Else
		ColumnNumber = 1;
		For Each ImportedAttribute In VT Do

			ImportedAttribute.Check      = True;
			ImportedAttribute.ColumnNumber = ColumnNumber;
			ColumnNumber = ColumnNumber + 1;

		EndDo;

	EndIf;

	For Each ImportedAttribute In VT Do
		If ImportedAttribute.ImportMode = "Evaluate" Then
			ImportedAttribute.AdditionalConditionsPresentation = ImportedAttribute.Expression;
		Else
			ImportedAttribute.AdditionalConditionsPresentation = ?(IsBlankString(ImportedAttribute.SearchBy), "", NStr("ru = 'Искать по '; en = 'Search by '")
				+ ImportedAttribute.SearchBy) + ?(IsBlankString(ImportedAttribute.LinkByOwner), "",
				NStr("ru = ' по владельцу '; en = ' by owner '") + ImportedAttribute.LinkByOwner);
		EndIf;
	EndDo;

	ValueToFormAttribute(VT, "ImportedAttributesTable");

EndProcedure // ()

// Заполняет настройки колонок по умолчанию для табличной части
//
&AtServer
Procedure FillTabularSectionColumnSettings(ТЗ)

	МетаданныеИсточника = GetSourceMetadata();

	If МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	For Each Реквизит Из МетаданныеИсточника.Реквизиты Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Реквизиты[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СписокВыбора = GetNamePresentationList(ЗагружаемыйРеквизит.ОписаниеТипов);
		ЗагружаемыйРеквизит.SearchBy = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = GetLinkByOwnerList(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
		ЗагружаемыйРеквизит.LinkByOwner = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = GetLinkByTypeList(ЗагружаемыйРеквизит, ТЗ);
		If СписокВыбора.Количество() = 0 Then
			ЗагружаемыйРеквизит.LinkByType = "";
			ЗагружаемыйРеквизит.LinkByTypeItem = 0;
		Else
			ЗагружаемыйРеквизит.LinkByType = СписокВыбора[0].Значение;
			If Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "3") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 3;

			ElsIf Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "2") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 2;

			Else

				ЗагружаемыйРеквизит.LinkByTypeItem = 1;

			EndIf;

		EndIf;

		ЗагружаемыйРеквизит.DefaultValue = ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined);
		ЗагружаемыйРеквизит.AvailableTypes = ЗагружаемыйРеквизит.TypeDescription;
		ЗагружаемыйРеквизит.ImportMode = "Искать";
	EndDo;

EndProcedure // ()

// Заполняет настройки колонок по умолчанию для справочника
//
&AtServer
Procedure FillCatalogColumnSettings(ТЗ)

	МетаданныеИсточника = GetSourceMetadata();

	If МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	If МетаданныеИсточника.ДлинаКода > 0 Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Код";
		ЗагружаемыйРеквизит.AttributePresentation = "Код";
		ЗагружаемыйРеквизит.PossibleSearchField   =  True;

		If МетаданныеИсточника.ТипКода = Метаданные.СвойстваОбъектов.ТипКодаСправочника.Строка Then
			ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Строка", ,
				Новый КвалификаторыСтроки(МетаданныеИсточника.ДлинаКода));
		Else
			ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Число", , ,
				Новый КвалификаторыЧисла(МетаданныеИсточника.ДлинаКода));
		EndIf;

	EndIf;

	If МетаданныеИсточника.ДлинаНаименования > 0 Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Наименование";
		ЗагружаемыйРеквизит.AttributePresentation = "Наименование";
		ЗагружаемыйРеквизит.PossibleSearchField   =  True;
		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Строка", ,
			Новый КвалификаторыСтроки(МетаданныеИсточника.ДлинаНаименования));

	EndIf;

	If МетаданныеИсточника.Владельцы.Количество() > 0 Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Владелец";
		ЗагружаемыйРеквизит.AttributePresentation = "Владелец";
		ЗагружаемыйРеквизит.PossibleSearchField   =  True;

		СтрокаОписанияТипов = "";

		For Each Владелец Из МетаданныеИсточника.Владельцы Do
			СтрокаОписанияТипов = ?(IsBlankString(СтрокаОписанияТипов), "", СтрокаОписанияТипов + ", ")
				+ Владелец.ПолноеИмя();
		EndDo;

		СтрокаОписанияТипов = СтрЗаменить(СтрокаОписанияТипов, ".", "Ссылка.");
		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов(СтрокаОписанияТипов);

	EndIf;

	If МетаданныеИсточника.Иерархический Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Родитель";
		ЗагружаемыйРеквизит.AttributePresentation = "Родитель";
		ЗагружаемыйРеквизит.PossibleSearchField   = True;
		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов(СтрЗаменить(МетаданныеИсточника.ПолноеИмя(), ".",
			"Ссылка."));
		
		If МетаданныеИсточника.ВидИерархии = Метаданные.СвойстваОбъектов.ВидИерархии.ИерархияГруппИЭлементов Then
			ЗагружаемыйРеквизит = ТЗ.Добавить();
			ЗагружаемыйРеквизит.AttributeName           = "ЭтоГруппа";
			ЗагружаемыйРеквизит.AttributePresentation = "ЭтоГруппа";
			ЗагружаемыйРеквизит.PossibleSearchField   = True;
			ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Булево");
		EndIf; 

	EndIf;

	For Each Реквизит Из МетаданныеИсточника.Реквизиты Do
		If Не Реквизит.Использование = Метаданные.СвойстваОбъектов.ИспользованиеРеквизита.ДляГруппы Then
			ЗагружаемыйРеквизит                        = ТЗ.Добавить();
			ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
			ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
			ЗагружаемыйРеквизит.PossibleSearchField   = Не Реквизит.Индексирование
				= Метаданные.СвойстваОбъектов.Индексирование.НеИндексировать;
			ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Реквизиты[ЗагружаемыйРеквизит.AttributeName].Тип;
		EndIf;
	EndDo;

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СписокВыбора = GetNamePresentationList(ЗагружаемыйРеквизит.ОписаниеТипов);
		ЗагружаемыйРеквизит.SearchBy = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = GetLinkByOwnerList(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
		ЗагружаемыйРеквизит.LinkByOwner = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = GetLinkByTypeList(ЗагружаемыйРеквизит, ТЗ);
		If СписокВыбора.Количество() = 0 Then
			ЗагружаемыйРеквизит.LinkByType = "";
			ЗагружаемыйРеквизит.LinkByTypeItem = 0;
		Else
			ЗагружаемыйРеквизит.LinkByType = СписокВыбора[0].Значение;
			If Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "3") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 3;

			ElsIf Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "2") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 2;

			Else

				ЗагружаемыйРеквизит.LinkByTypeItem = 1;

			EndIf;
		EndIf;

		ЗагружаемыйРеквизит.DefaultValue = ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined);
		ЗагружаемыйРеквизит.AvailableTypes = ЗагружаемыйРеквизит.TypeDescription;
		ЗагружаемыйРеквизит.ImportMode = "Искать";
	EndDo;
EndProcedure // ()

// Заполняет настройки колонок по умолчанию для регистра сведений
//
&AtServer
Procedure FillInformationRegisterColumnSettings(ТЗ)

	МетаданныеИсточника = GetSourceMetadata();

	If МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	If Не МетаданныеИсточника.ПериодичностьРегистраСведений
		= Метаданные.СвойстваОбъектов.ПериодичностьРегистраСведений.Непериодический Then

		ЗагружаемыйРеквизит = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = "Период";
		ЗагружаемыйРеквизит.AttributePresentation = "Период";
		ЗагружаемыйРеквизит.PossibleSearchField = True;
		ЗагружаемыйРеквизит.SearchField           = True;

		ЗагружаемыйРеквизит.TypeDescription = Новый ОписаниеТипов("Дата", , , ,
			Новый КвалификаторыДаты(ЧастиДаты.ДатаВремя));

	EndIf;

	For Each Реквизит Из МетаданныеИсточника.Измерения Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.PossibleSearchField = True;
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Измерения[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each Реквизит Из МетаданныеИсточника.Ресурсы Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Ресурсы[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each Реквизит Из МетаданныеИсточника.Реквизиты Do
		ЗагружаемыйРеквизит                        = ТЗ.Добавить();
		ЗагружаемыйРеквизит.AttributeName           = Реквизит.Имя;
		ЗагружаемыйРеквизит.AttributePresentation = Реквизит.Представление();
		ЗагружаемыйРеквизит.TypeDescription = МетаданныеИсточника.Реквизиты[ЗагружаемыйРеквизит.AttributeName].Тип;
	EndDo;

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СписокВыбора = GetNamePresentationList(ЗагружаемыйРеквизит.ОписаниеТипов);
		ЗагружаемыйРеквизит.SearchBy = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = GetLinkByOwnerList(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
		ЗагружаемыйРеквизит.LinkByOwner = ?(СписокВыбора.Количество() = 0, "", СписокВыбора[0].Значение);

		СписокВыбора = GetLinkByTypeList(ЗагружаемыйРеквизит, ТЗ);
		If СписокВыбора.Количество() = 0 Then
			ЗагружаемыйРеквизит.LinkByType = "";
			ЗагружаемыйРеквизит.LinkByTypeItem = 0;
		Else
			ЗагружаемыйРеквизит.LinkByType = СписокВыбора[0].Значение;
			If Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "3") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 3;

			ElsIf Найти(ЗагружаемыйРеквизит.ИмяРеквизита, "2") <> 0 Then

				ЗагружаемыйРеквизит.LinkByTypeItem = 2;

			Else

				ЗагружаемыйРеквизит.LinkByTypeItem = 1;

			EndIf;
		EndIf;

		ЗагружаемыйРеквизит.DefaultValue = ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined);
		ЗагружаемыйРеквизит.AvailableTypes = ЗагружаемыйРеквизит.TypeDescription;
		ЗагружаемыйРеквизит.ImportMode = "Искать";
	EndDo;
EndProcedure // ()

// Function формирует табличный документ с настройками обработки
&AtServer
Function ПолучитьНастройки()

	МетаданныеОбъекта = GetSourceMetadata();

	If МетаданныеОбъекта = Undefined Then
		Return Undefined;
	EndIf;

	ВидОбъекта     = МетаданныеОбъекта.ПолноеИмя();

	ДокументРезультат = Новый ТабличныйДокумент;
	ОбработкаОбъект = FormAttributeToValue("Object");
	Макет = ОбработкаОбъект.ПолучитьМакетОбработки("МакетСохраненияНастроек");

	ОбластьШапки = Макет.ПолучитьОбласть("Шапка");
	If Object.ImportMode = 0 Then
		ОбластьШапки.Параметры.ImportMode = "в справочник";
	ElsIf Object.ImportMode = 1 Then
		ОбластьШапки.Параметры.ImportMode = "в табличную часть";
	ElsIf Object.ImportMode = 2 Then
		ОбластьШапки.Параметры.ImportMode = "в регистр сведений";
	EndIf;

	ОбластьШапки.Параметры.ВидОбъекта                                = ВидОбъекта;
	ОбластьШапки.Параметры.DontCreateNewItems                 = ?(Object.DontCreateNewItems, "Х", "");
	ОбластьШапки.Параметры.ReplaceExistingRecords                 = ?(Object.ReplaceExistingRecords, "Х", "");
	ОбластьШапки.Параметры.ManualSpreadsheetDocumentColumnsNumeration = ?(
		Object.ManualSpreadsheetDocumentColumnsNumeration, "Х", "");
	ОбластьШапки.Параметры.SpreadsheetDocumentFirstDataRow     = Object.SpreadsheetDocumentFirstDataRow;

	ДокументРезультат.Вывести(ОбластьШапки);

	ТЗ = FormAttributeToValue("ImportedAttributesTable");

	For Each ЗагружаемыйРеквизит Из ТЗ Do
		ОбластьСтроки = Макет.ПолучитьОбласть("Строка" + ?(ЗагружаемыйРеквизит.ImportMode = "Вычислять", "Expression",
			""));

		ОбластьСтроки.Параметры.Check      = ?(ЗагружаемыйРеквизит.Пометка, "Х", "");
		ОбластьСтроки.Параметры.AttributeName = ЗагружаемыйРеквизит.AttributeName;
		ОбластьСтроки.Параметры.SearchField   = ?(ЗагружаемыйРеквизит.ПолеПоиска, "Х", "");

		ОбластьСтроки.Параметры.TypeDescription       = GetTypeDescription(ЗагружаемыйРеквизит.ОписаниеТипов);

		ОбластьСтроки.Параметры.ImportMode       = ЗагружаемыйРеквизит.ImportMode;
		If ЗагружаемыйРеквизит.TypeDescription.ПривестиЗначение(Undefined) = ЗагружаемыйРеквизит.DefaultValue Then
			ОбластьСтроки.Параметры.DefaultValue = "";
		Else
			ОбластьСтроки.Параметры.DefaultValue = ЗначениеВСтрокуВнутр(ЗагружаемыйРеквизит.ЗначениеПоУмолчанию);
		EndIf;

		If ЗагружаемыйРеквизит.ImportMode = "Вычислять" Then

			ОбластьСтроки.Параметры.Expression           = ЗагружаемыйРеквизит.Expression;

		Else
			ОбластьСтроки.Параметры.SearchBy            = ЗагружаемыйРеквизит.SearchBy;
			ОбластьСтроки.Параметры.LinkByOwner    = ?(ТипЗнч(ЗагружаемыйРеквизит.СвязьПоВладельцу) = Тип(
				"Строка"), ЗагружаемыйРеквизит.СвязьПоВладельцу, ЗначениеВСтрокуВнутр(
				ЗагружаемыйРеквизит.СвязьПоВладельцу));
			ОбластьСтроки.Параметры.LinkByType         = ?(ТипЗнч(ЗагружаемыйРеквизит.СвязьПоТипу) = Тип("Строка"),
				ЗагружаемыйРеквизит.СвязьПоТипу, ЗначениеВСтрокуВнутр(ЗагружаемыйРеквизит.СвязьПоТипу));
			ОбластьСтроки.Параметры.LinkByTypeItem  = ЗагружаемыйРеквизит.LinkByTypeItem;
		EndIf;
		// Добавлен параметр ColumnNumber
		ОбластьСтроки.Параметры.ColumnNumber			= ЗагружаемыйРеквизит.ColumnNumber;

		ДокументРезультат.Вывести(ОбластьСтроки);

	EndDo;

	ОбластьПодвала = Макет.ПолучитьОбласть("Events");
	ОбластьПодвала.Параметры.BeforeWriteObject = Object.BeforeWriteObject;
	ОбластьПодвала.Параметры.OnWriteObject = Object.OnWriteObject;
	ДокументРезультат.Вывести(ОбластьПодвала);
	If Object.ImportMode Then

		ОбластьПодвала = Макет.ПолучитьОбласть("СобытияПослеДобавленияСтроки");
		ОбластьПодвала.Параметры.AfterAddRow = Object.AfterAddRow;
		ДокументРезультат.Вывести(ОбластьПодвала);

	EndIf;

	Return ДокументРезультат;

EndFunction

// Function читает mxl-файл с настройками обработки
&AtServer
Function ПрочитатьНастройкиНаСервере(АдресХранилища)

	Данные = ПолучитьИзВременногоХранилища(АдресХранилища);

	ИмяФайлаВременное = ПолучитьИмяВременногоФайла("mxl");
	ВремДок = Новый ТабличныйДокумент;
	Данные.Записать(ИмяФайлаВременное);
	ВремДок.Прочитать(ИмяФайлаВременное);
	УдалитьФайлы(ИмяФайлаВременное);

	Return ВремДок;
EndFunction

// Function возвращает содержимое mxl-файла с настройками обработки
&НаКлиенте
Function мПрочитатьНастройкиИзФайла(ИмяФайла)

	ДанныеФайла = Новый ДвоичныеДанные(ИмяФайла);

	АдресФайла = "";
	АдресФайла = ПоместитьВоВременноеХранилище(ДанныеФайла, ЭтаФорма.УникальныйИдентификатор);

	Return ПрочитатьНастройкиНаСервере(АдресФайла);

EndFunction

&AtServer
Procedure СкопироватьНастройки(Знач Источник, Приемник)
	
	//If ТипЗнч(Источник) = Тип("FormDataCollection") Then
	//	Источник = FormDataToValue(Источник, Тип("ValueTable"));
	//Else
	If Не ТипЗнч(Источник) = Тип("ValueTable") Then
		Return;
	EndIf;

	Приемник.Очистить();

	For Each Стр Из Источник Do
		НовСтр = Приемник.Добавить();
		FillPropertyValues(НовСтр, Стр);
	EndDo;

EndProcedure

&AtServer
Procedure ПриЗакрытииНаСервере()

	mSaveValue("ImportMode", Object.ImportMode);
	mSaveValue("SourceRef", Object.SourceRef);
	mSaveValue("SourceTabularSection", Object.SourceTabularSection);
	mSaveValue("RegisterTypeName", Object.RegisterTypeName);
	mSaveValue("CatalogObjectType", Object.CatalogObjectType);

EndProcedure // ПриЗакрытииНаСервере()

////////////////////////////////////////////////////////////////////////////////
//

&AtServer
Procedure ОбновитьДанныеТабличногоДокументаСервер()

	SpreadsheetDocument.Очистить();

	GenerateColumnsStructure();
	GenerateSpreadsheetDocumentHeader(SpreadsheetDocument);

	НомерСтроки = Object.SpreadsheetDocumentFirstDataRow;

	МетаданныеИсточника = GetSourceMetadata();
	If Object.ImportMode = 0 Или Object.ImportMode = 2 Или МетаданныеИсточника = Undefined Then
		Return;
	EndIf;

	Источник = Object.SourceRef[Object.SourceTabularSection];
	
	//ТЗ = FormAttributeToValue("ImportedAttributesTable");

	For Each Строка Из Источник Do

		НомерКолонки = 0;

		For Each ЗагружаемыйРеквизит Из ImportedAttributesTable Do

			If ЗагружаемыйРеквизит.Check Then

				If Object.ManualSpreadsheetDocumentColumnsNumeration Then
					НомерКолонки = ЗагружаемыйРеквизит.ColumnNumber;
				Else
					НомерКолонки = НомерКолонки + 1;
				EndIf;

				Область = SpreadsheetDocument.Область("R" + Формат(НомерСтроки, "ЧГ=") + "C" + НомерКолонки);
				Значение = Строка[ЗагружаемыйРеквизит.AttributeName];

				Try
					Представление = Значение[ЗагружаемыйРеквизит.SearchBy];

				Except

					Представление = Значение;

				EndTry;

				Область.Текст = Представление;
				Область.Расшифровка = Значение;

			EndIf;

		EndDo;

		НомерСтроки = НомерСтроки + 1;
	EndDo;

EndProcedure // ОбновитьДанныеТабличногоДокументаСервер()

&НаКлиенте
Procedure ОбновитьДанныеТабличногоДокумента(Знач Оповещение, БезВопросов = False)

	If (Object.ImportMode = 0 Или Object.ImportMode = 2) И Элементы.SpreadsheetDocument.Высота > 1 И Не БезВопросов Then
		ПоказатьВопрос(Новый ОписаниеОповещения("ОбновитьДанныеТабличногоДокументаЗавершение", ЭтаФорма,
			Новый Структура("Оповещение", Оповещение)), "Табличный документ содержит данные. Очистить?",
			РежимДиалогаВопрос.ДаНет);
		Return;
	Else
		ОбновитьДанныеТабличногоДокументаСервер();
	EndIf;

	ОбновитьДанныеТабличногоДокументаФрагмент(Оповещение);
EndProcedure

&НаКлиенте
Procedure ОбновитьДанныеТабличногоДокументаЗавершение(РезультатВопроса, ДополнительныеПараметры) Export

	Оповещение = ДополнительныеПараметры.Оповещение;
	If РезультатВопроса = КодReturnаДиалога.Да Then
		ОбновитьДанныеТабличногоДокументаСервер();
		ВыполнитьОбработкуОповещения(Оповещение);
		Return;
	EndIf;

	ОбновитьДанныеТабличногоДокументаФрагмент(Оповещение);

EndProcedure

&НаКлиенте
Procedure ОбновитьДанныеТабличногоДокументаФрагмент(Знач Оповещение)

	ВыполнитьОбработкуОповещения(Оповещение);

EndProcedure

// Function считывает в табличный документ данные из файла в формате Excel
//
// Параметры:
//  SpreadsheetDocument  - SpreadsheetDocument, в который необходимо прочитать данные
//  ИмяФайла           - имя файла в формате Excel, из которого необходимо прочитать данные
//  НомерЛистаExcel    - номер листа книги Excel, из которого необходимо прочитать данные
//
// Возвращаемое значение:
//  True, If файл прочитан, False - Else
//
&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзExcel(ИмяФайла, НомерЛистаExcel = 1) Export

	НачатьПроверкуСуществованияФайла(ИмяФайла,
		Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзExcelЗаверешениеПроверкиСуществованияФайла", ЭтотОбъект,
		Новый Структура("ИмяФайла,НомерЛистаExcel", ИмяФайла, НомерЛистаExcel)));

EndProcedure // ()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзExcelЗаверешениеПроверкиСуществованияФайла(Существует, ДополнительныеПараметры) Export
	If Не Существует Then
		Сообщить("Файл не существует!");
		Return;
	EndIf;
	НомерЛистаExcel=ДополнительныеПараметры.НомерЛистаExcel;
	ИмяФайла=ДополнительныеПараметры.ИмяФайла;

	xlLastCell = 11;
	Try
		Excel = Новый COMОбъект("Excel.Application");
		Excel.WorkBooks.Open(ИмяФайла);
		Сообщить("Обработка файла Microsoft Excel...");
		ExcelЛист = Excel.Sheets(НомерЛистаExcel);
	Except
		Сообщить("Ошибка. Возможно неверно указан номер листа книги Excel.");
		Return;

	EndTry;

	SpreadsheetDocument = Новый ТабличныйДокумент;

	ActiveCell = Excel.ActiveCell.SpecialCells(xlLastCell);
	RowCount = ActiveCell.Row;
	ColumnCount = ActiveCell.Column;
	Для Column = 1 По ColumnCount Do
		SpreadsheetDocument.Область("C" + Формат(Column, "ЧГ=")).ColumnWidth = ExcelЛист.Columns(Column).ColumnWidth;
	EndDo;
	Для Row = 1 По RowCount Do

		Для Column = 1 По ColumnCount Do
			SpreadsheetDocument.Область("R" + Формат(Row, "ЧГ=") + "C" + Формат(Column, "ЧГ=")).Текст = ExcelЛист.Cells(
				Row, Column).Text;
		EndDo;

	EndDo;

	Excel.WorkBooks.Close();
	Excel = 0;
EndProcedure

// Function считывает в табличный документ данные из файла в формате TXT
//
// Параметры:
//  SpreadsheetDocument  - SpreadsheetDocument, в который необходимо прочитать данные
//  ИмяФайла           - имя файла в формате TXT, из которого необходимо прочитать данные
//
// Возвращаемое значение:
//  True, If файл прочитан, False - Else
//
&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекста(ИмяФайла) Export

	ВыбФайл = Новый Файл(ИмяФайла);
	ВыбФайл.НачатьПроверкуСуществования(
		Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзТекстаЗавершениеПроверкиСуществованияФайла", ЭтаФорма,
		Новый Структура("ИмяФайла", ИмяФайла)));

EndProcedure

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекстаЗавершениеПроверкиСуществованияФайла(Существует, ДополнительныеПараметры) Export

	ИмяФайла = ДополнительныеПараметры.ИмяФайла;
	If Существует Then
		ТекстовыйДокумент = Новый ТекстовыйДокумент;
		ТекстовыйДокумент.НачатьЧтение(Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзТекстаЗавершение",
			ЭтотОбъект, Новый Структура("ТекстовыйДокумент", ТекстовыйДокумент),
			"мПрочитатьТабличныйДокументИзТекстаЗавершениеОшибкаЧтения", ЭтотОбъект), ИмяФайла);

	Else
		Сообщить("Файл не существует!");

	EndIf;

EndProcedure // ()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекстаЗавершение(ДополнительныеПараметры) Export
	ТекстовыйДокумент=ДополнительныеПараметры.ТекстовыйДокумент;

	SpreadsheetDocument = Новый ТабличныйДокумент;
	Для ТекущаяСтрока = 1 По ТекстовыйДокумент.КоличествоСтрок() Do
		ТекущаяКолонка = 0;
		For Each Значение Из mSplitStringIntoSubstringsArray(ТекстовыйДокумент.ПолучитьСтроку(ТекущаяСтрока),
			Символы.Таб) Do
			ТекущаяКолонка = ТекущаяКолонка + 1;
			SpreadsheetDocument.Область("R" + Формат(ТекущаяСтрока, "ЧГ=") + "C" + Формат(ТекущаяКолонка,
				"ЧГ=")).Текст = Значение;

		EndDo;

	EndDo;
EndProcedure

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзТекстаЗавершениеОшибкаЧтения(ИнформацияОбОшибке, СтандартнаяОбработка,
	ДополнительныеПараметры) Export
	СтандартнаяОбработка=False;
	Сообщить("Ошибка открытия файла!");
EndProcedure

&НаКлиенте
Procedure НачатьПроверкуСуществованияФайла(ИмяФайла, ОписаниеОповещенияОЗавершении)
	ВыбФайл = Новый Файл(ИмяФайла);
	ВыбФайл.НачатьПроверкуСуществования(ОписаниеОповещенияОЗавершении);
EndProcedure

// Function считывает в табличный документ данные из файла в формате dBase III (*.dbf)
//
// Параметры:
//  SpreadsheetDocument  - SpreadsheetDocument, в который необходимо прочитать данные
//  ИмяФайла           - имя файла в формате TXT, из которого необходимо прочитать данные
//
// Возвращаемое значение:
//  True, If файл прочитан, False - Else
//
&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзDBF(ИмяФайла) Export
	НачатьПроверкуСуществованияФайла(ИмяФайла,
		Новый ОписаниеОповещения("мПрочитатьТабличныйДокументИзDBFЗавершениеПроверкиСуществованияФайла", ЭтотОбъект,
		Новый Структура("ИмяФайла", ИмяФайла)));
EndProcedure // ()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзDBFЗавершениеПроверкиСуществованияФайла(Существует, ДополнительныеПараметры) Export
	If Не Существует Then
		Сообщить("Файл не существует!");
		Return;
	EndIf;

#If Не ВебКлиент Then

	ИмяФайла=ДополнительныеПараметры.ИмяФайла;

	XBase  = Новый XBase;
	XBase.Кодировка = ПредопределенноеЗначение("КодировкаXBase.OEM");
	Try
		XBase.ОткрытьФайл(ИмяФайла);
	Except
		Сообщить("Ошибка открытия файла!");
		Return;
	EndTry;

	SpreadsheetDocument = Новый ТабличныйДокумент;
	ТекущаяСтрока = 1;
	ТекущаяКолонка = 0;
	For Each Поле Из XBase.поля Do
		ТекущаяКолонка = ТекущаяКолонка + 1;
		SpreadsheetDocument.Область("R" + Формат(ТекущаяСтрока, "ЧГ=") + "C" + Формат(ТекущаяКолонка,
			"ЧГ=")).Текст = Поле.Имя;
	EndDo;
	Рез = XBase.Первая();
	Пока Не XBase.ВКонце() Do
		ТекущаяСтрока = ТекущаяСтрока + 1;

		ТекущаяКолонка = 0;
		For Each Поле Из XBase.поля Do
			ТекущаяКолонка = ТекущаяКолонка + 1;
			SpreadsheetDocument.Область("R" + Формат(ТекущаяСтрока, "ЧГ=") + "C" + Формат(ТекущаяКолонка,
				"ЧГ=")).Текст = XBase.ПолучитьЗначениеПоля(ТекущаяКолонка - 1);
		EndDo;

		XBase.Следующая();
	EndDo;
#Else
		ПоказатьПредупреждение(Undefined, "Чтение DBF файлов недоступно в веб клиенте");
#EndIf

EndProcedure

&AtServer
Procedure ПрочитатьТабличныйДокументИзMXLНаСервере(АдресХранилища)

	Данные = ПолучитьИзВременногоХранилища(АдресХранилища);

	ИмяФайлаВременное = ПолучитьИмяВременногоФайла("mxl");

	Данные.Записать(ИмяФайлаВременное);
	SpreadsheetDocument.Прочитать(ИмяФайлаВременное);
	УдалитьФайлы(ИмяФайлаВременное);

EndProcedure // ПрочитатьТабличныйДокументИзMXLНаСервере()

&НаКлиенте
Procedure мПрочитатьТабличныйДокументИзMXL(ИмяФайла)

	ДанныеФайла = Новый ДвоичныеДанные(ИмяФайла);

	АдресФайла = "";
	АдресФайла = ПоместитьВоВременноеХранилище(ДанныеФайла, ЭтаФорма.УникальныйИдентификатор);

	ПрочитатьТабличныйДокументИзMXLНаСервере(АдресФайла);

EndProcedure // ()

////////////////////////////////////////////////////////////////////////////////
//

&НаКлиенте
Procedure УправлениеВидимостью()

	РежимЗагрузки = Object.ImportMode;
	РучнаяНумерацияКолонокТабличногоДокумента = Object.ManualSpreadsheetDocumentColumnsNumeration;

	If РежимЗагрузки = 0 Then
		ТекЭлемент = Элементы.ImportToCatalogGroup;
	ElsIf РежимЗагрузки = 1 Then
		ТекЭлемент = Элементы.ImportToTabularSectionGroup;
	ElsIf РежимЗагрузки = 2 Then
		ТекЭлемент = Элементы.ImportToInformationRegisterGroup;
	Else
		Return; // Неизвестный режим
	EndIf;
	If Не Элементы.ModeBarGroup.ТекущаяСтраница = ТекЭлемент Then
		Элементы.ModeBarGroup.ТекущаяСтраница = ТекЭлемент;
	EndIf;

	Элементы.ImportedAttributesTableSearchField.Видимость         = РежимЗагрузки = 0;

	Элементы.DontCreateNewItems.Видимость = РежимЗагрузки = 0;
	Элементы.ReplaceExistingRecords.Видимость = РежимЗагрузки = 2;

	ДоступностьКнопкиСохранитьЗначения    = SelectedMetadataExists();
	ДоступностьКнопкиВосстановитьЗначения = False; //Не СписокСохраненныхНастроек.Количество() = 0;

	Элементы.SaveValues.Доступность = False; //ДоступностьКнопкиСохранитьЗначения;
	Элементы.RestoreValues.Доступность = ДоступностьКнопкиВосстановитьЗначения;

	Элементы.SaveValuesToFile.Доступность = ДоступностьКнопкиСохранитьЗначения;

	Элементы.ImportedAttributesTableColumnNumber.Видимость = РучнаяНумерацияКолонокТабличногоДокумента;
	Элементы.RenumberColumns.Доступность = РучнаяНумерацияКолонокТабличногоДокумента;
	Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check = РучнаяНумерацияКолонокТабличногоДокумента;

EndProcedure // УправлениеВидимостью()

// Procedure выполняет установку реквизитов, связанных с источником данных
//
&AtServer
Procedure УстановитьИсточник(СписокНастроек = Undefined)

	Источник        = Undefined;
	ОбъектИсточника = Undefined;
	//СписокСохраненныхНастроек.Очистить();
	ПрошлыйМетаданныеСсылкиИсточника = Undefined;
	МетаданныеИсточника = GetSourceMetadata();
	If МетаданныеИсточника = Undefined Then
		ImportedAttributesTable.Очистить();
	Else
		Врем = mRestoreValue(МетаданныеИсточника.ПолноеИмя());
		//If НЕ СписокНастроек = Undefined Then
		//	СкопироватьНастройки(Врем, СписокНастроек);
		//	Настройка = GetDefaultSetting(СписокНастроек);
		//	ВосстановитьНастройкиИзСписка(Настройка);
		//Else
		//	ВосстановитьНастройкиИзСписка(Undefined);
		FillColumnSettings(Undefined);
		//EndIf;
	EndIf;

	ОбновитьДанныеТабличногоДокументаСервер();

	СпискиВыбораСвязиПоВладельцу.Очистить();

	ТЗ = FormAttributeToValue("ImportedAttributesTable");

	For Each ЗагружаемыйРеквизит Из ТЗ Do

		СтрокаСписка = СпискиВыбораСвязиПоВладельцу.Добавить();
		СтрокаСписка.AttributeName = ЗагружаемыйРеквизит.AttributeName;
		СтрокаСписка.СписокВыбора = GetLinkByOwnerList(ЗагружаемыйРеквизит.ОписаниеТипов, ТЗ);
	EndDo;

EndProcedure

// Procedure выполняет инициализацию служебных переменных и констант модуля
//
&AtServer
Procedure Инициализация()

	Object.AdditionalProperties = Новый Структура;

	Object.AdditionalProperties.Вставить("ПримитивныеТипы", Новый Структура("Число, Строка, Дата, Булево", Тип(
		"Число"), Тип("Строка"), Тип("Дата"), Тип("Булево")));

	If Object.SpreadsheetDocumentFirstDataRow < 2 Then
		Object.SpreadsheetDocumentFirstDataRow = 2;
	EndIf;

	Object.AdditionalProperties.Вставить("Колонки", Новый Структура);

EndProcedure // ()

///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ КОМАНД

&НаКлиенте
Procedure ImportCommand(Команда)

	СтруктураТекстВопроса = GetSourceQuestionText();
	КоличествоЭлементов = SpreadsheetDocument.ВысотаТаблицы - Object.SpreadsheetDocumentFirstDataRow + 1;
	If Не IsBlankString(СтруктураТекстВопроса.Ошибка) Then
		ПоказатьПредупреждение( , СтруктураТекстВопроса.Ошибка, , "Ошибка при загрузке!");
	Else
		ПоказатьВопрос(Новый ОписаниеОповещения("КомандаЗагрузитьЗавершение", ЭтаФорма), "Import "
			+ КоличествоЭлементов + СтруктураТекстВопроса.ТекстВопроса, РежимДиалогаВопрос.ДаНет);
	EndIf;

EndProcedure

&НаКлиенте
Procedure КомандаЗагрузитьЗавершение(РезультатВопроса, ДополнительныеПараметры) Export

	If РезультатВопроса = КодReturnаДиалога.Да Then
		ОчиститьСообщения();
		ImportDataServer();
	EndIf;

EndProcedure
&НаКлиенте
Procedure OpenCommand(Команда)

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);

	ДиалогВыбораФайла.Заголовок = "Прочитать табличный документ из файла";
	ДиалогВыбораФайла.Фильтр    = "Табличный документ (*.mxl)|*.mxl|Лист Excel (*.xls,*.xlsx)|*.xls;*.xlsx|Текстовый документ (*.txt)|*.txt|dBase III (*.dbf)|*.dbf|";
	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаОткрытьЗавершение", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла", ДиалогВыбораФайла)));

EndProcedure

&НаКлиенте
Procedure КомандаОткрытьЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	If (ВыбранныеФайлы <> Undefined) Then

		SpreadsheetDocument = Элементы.SpreadsheetDocument;
		ФайлНаДиске = Новый Файл(ДиалогВыбораФайла.ПолноеИмяФайла);
		If нРег(ФайлНаДиске.Расширение) = ".mxl" Then
			мПрочитатьТабличныйДокументИзMXL(ДиалогВыбораФайла.ПолноеИмяФайла);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".xls" Или нРег(ФайлНаДиске.Расширение) = ".xlsx" Then
			мПрочитатьТабличныйДокументИзExcel(ДиалогВыбораФайла.ПолноеИмяФайла);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".txt" Then
			мПрочитатьТабличныйДокументИзТекста(ДиалогВыбораФайла.ПолноеИмяФайла);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".dbf" Then
			мПрочитатьТабличныйДокументИзDBF(ДиалогВыбораФайла.ПолноеИмяФайла);
		EndIf;
		УправлениеВидимостью();
	EndIf;

EndProcedure

&НаКлиенте
Procedure SaveCommand(Команда)

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);

	ДиалогВыбораФайла.Заголовок = "Сохранить табличный документ в файл";
	ДиалогВыбораФайла.Фильтр    = "Табличный документ (*.mxl)|*.mxl|Лист Excel (*.xls)|*.xls|Текстовый документ (*.txt)|*.txt|";
	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаСохранитьЗавершение", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла", ДиалогВыбораФайла)));

EndProcedure

&НаКлиенте
Procedure КомандаСохранитьЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	If (ВыбранныеФайлы <> Undefined) Then

		SpreadsheetDocument = Элементы.SpreadsheetDocument;
		ФайлНаДиске = Новый Файл(ДиалогВыбораФайла.ПолноеИмяФайла);
		If нРег(ФайлНаДиске.Расширение) = ".mxl" Then
			SpreadsheetDocument.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла,
				ТипФайлаТабличногоДокумента.MXL);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".xls" Then
			SpreadsheetDocument.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла,
				ТипФайлаТабличногоДокумента.XLS);
		ElsIf нРег(ФайлНаДиске.Расширение) = ".txt" Then
			SpreadsheetDocument.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла,
				ТипФайлаТабличногоДокумента.TXT);
		EndIf;

	EndIf;

EndProcedure

&НаКлиенте
Procedure RefreshCommand(Команда)
	ОбновитьДанныеТабличногоДокумента(Undefined);
EndProcedure

&НаКлиенте
Procedure FillControlCommand(Команда)
	FillControlServer();
EndProcedure

&НаКлиенте
Procedure NextNoteCommand(Команда)
	
	//SpreadsheetDocument = Элементы.SpreadsheetDocument;

	Нашли = False;

	Колонка = SpreadsheetDocument.ТекущаяОбласть.Лево + 1;
	Строка  = SpreadsheetDocument.ТекущаяОбласть.Верх;

	Пока Не Нашли И Строка <= SpreadsheetDocument.ВысотаТаблицы Do

		Пока Не Нашли И Колонка <= SpreadsheetDocument.ШиринаТаблицы Do

			Область = SpreadsheetDocument.Область("R" + Формат(Строка, "ЧГ=") + "C" + Формат(Колонка, "ЧГ="));
			Нашли = Не IsBlankString(Область.Примечание.Текст);

			Колонка = Колонка + 1;
		EndDo;
		Строка = Строка + 1;
		Колонка = 1;
	EndDo;

	If Нашли Then
		SpreadsheetDocument.ТекущаяОбласть = Область;
	Else
		Сообщить("Достигнут конец документа", СтатусСообщения.Информация);
	EndIf;

EndProcedure

&НаКлиенте
Procedure PreviousNoteCommand(Команда)
	
	//SpreadsheetDocument = Элементы.SpreadsheetDocument;

	Нашли = False;

	Колонка = SpreadsheetDocument.ТекущаяОбласть.Лево - 1;
	Строка  = SpreadsheetDocument.ТекущаяОбласть.Верх;

	Пока Не Нашли И Строка > 0 Do

		Пока Не Нашли И Колонка > 0 Do

			Область = SpreadsheetDocument.Область("R" + Формат(Строка, "ЧГ=") + "C" + Формат(Колонка, "ЧГ="));
			Нашли = Не IsBlankString(Область.Примечание.Текст);

			Колонка = Колонка - 1;
		EndDo;
		Строка = Строка - 1;
		Колонка = SpreadsheetDocument.ШиринаТаблицы;
	EndDo;

	If Нашли Then
		SpreadsheetDocument.ТекущаяОбласть = Область;
	Else
		Сообщить("Достигнуто начало документа", СтатусСообщения.Информация);
	EndIf;

EndProcedure

&НаКлиенте
Procedure RestoreValuesFromFileCommand(Команда)

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Открытие);
	ДиалогВыбораФайла.Заголовок	= "Восстановить значения из файла";
	ДиалогВыбораФайла.Фильтр	= "Настройка загрузки в табличный документ (*.mxlz)|*.mxlz|Все файлы (*.*)|*.*|";

	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаВосстановитьЗначенияИзФайлаЗавершение1", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла", ДиалогВыбораФайла)));

EndProcedure

&НаКлиенте
Procedure КомандаВосстановитьЗначенияИзФайлаЗавершение1(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	If (ВыбранныеФайлы <> Undefined) Then
		Настройки = мПрочитатьНастройкиИзФайла(ДиалогВыбораФайла.ПолноеИмяФайла);
		FillColumnSettings(Настройки);
		SetTabularSectionsList();
		ОбновитьДанныеТабличногоДокумента(Новый ОписаниеОповещения("КомандаВосстановитьЗначенияИзФайлаЗавершение",
			ЭтаФорма), True);
	Else
		КомандаВосстановитьЗначенияИзФайлаФрагмент();
	EndIf;

EndProcedure

&НаКлиенте
Procedure КомандаВосстановитьЗначенияИзФайлаЗавершение(Результат, ДополнительныеПараметры) Export

	КомандаВосстановитьЗначенияИзФайлаФрагмент();

EndProcedure

&НаКлиенте
Procedure КомандаВосстановитьЗначенияИзФайлаФрагмент()

	УправлениеВидимостью();

EndProcedure

&НаКлиенте
Procedure SaveValuesToFileCommand(Команда)

	Настройки = ПолучитьНастройки();
	If Настройки = Undefined Then
		Return;
	EndIf;

	ДиалогВыбораФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);

	ДиалогВыбораФайла.Заголовок = "Сохранить значения настройки в файл";
	ДиалогВыбораФайла.Фильтр    = "Настройка загрузки в табличный документ (*.mxlz)|*.mxlz|Все файлы (*.*)|*.*|";
	ДиалогВыбораФайла.Показать(Новый ОписаниеОповещения("КомандаСохранитьЗначенияВФайлЗавершение", ЭтаФорма,
		Новый Структура("ДиалогВыбораФайла, Настройки", ДиалогВыбораФайла, Настройки)));

EndProcedure

&НаКлиенте
Procedure КомандаСохранитьЗначенияВФайлЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Export

	ДиалогВыбораФайла = ДополнительныеПараметры.ДиалогВыбораФайла;
	Настройки = ДополнительныеПараметры.Настройки;
	If (ВыбранныеФайлы <> Undefined) Then

		Настройки.НачатьЗапись(Undefined, ДиалогВыбораФайла.ПолноеИмяФайла);

	EndIf;

EndProcedure

&НаКлиенте
Procedure RestoreValuesCommand(Команда)

	ФормаВыбораНастройки = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаВыбораНастройки", , ЭтаФорма);
	ФормаВыбораНастройки.СписокНастроек = СписокСохраненныхНастроек;
	ТекущиеДанные = ФормаВыбораНастройки.Открыть();
	If Не ТекущиеДанные = Undefined Then
		FillColumnSettings(ТекущиеДанные.Значение);
	EndIf;

	mSaveValue(DataProcessorID(), ФормаВыбораНастройки.СписокНастроек);

EndProcedure

&НаКлиенте
Procedure SaveValuesCommand(Команда)

	ФормаСохраненияНастройки = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаСохраненияНастройки", , ЭтаФорма);
	If Не СписокСохраненныхНастроек.Количество() = 0 Then
		//ФормаСохраненияНастройки.СписокНастроек = СписокСохраненныхНастроек;
		For Each Стр Из СписокСохраненныхНастроек Do

			НовСтр = ФормаСохраненияНастройки.СписокНастроек.Добавить();
			НовСтр.Check = Стр.Check;
			НовСтр.Представление = Стр.Представление;

		EndDo;
	EndIf;

	ТекущиеДанные = ФормаСохраненияНастройки.Открыть();

	If Не ТекущиеДанные = Undefined Then
		
		//ПолучитьНастройкиСписком(ТекущиеДанные.Значение);
		//СкопироватьНастройки(ФормаСохраненияНастройки.СписокНастроек);
		//УстановитьТекущиеНастройки(СписокСохраненныхНастроек, ТекущиеДанные.Check, ТекущиеДанные.Представление, ПолучитьСтруктуруНастроек());
		mSaveValue(DataProcessorID(), СписокСохраненныхНастроек);

	EndIf;

EndProcedure

&НаКлиенте
Procedure RereadCommand(Команда)
	FillColumnSettings(Undefined);
EndProcedure

&НаКлиенте
Procedure CheckAllCommand(Команда)
	For Each ЗагружаемыйРеквизит Из ImportedAttributesTable Do
		ЗагружаемыйРеквизит.Check = True;
	EndDo;
EndProcedure

&НаКлиенте
Procedure UncheckAllCommand(Команда)
	For Each ЗагружаемыйРеквизит Из ImportedAttributesTable Do
		ЗагружаемыйРеквизит.Check = False;
	EndDo;
EndProcedure

&НаКлиенте
Procedure ManualSpreadsheetDocumentColumnsNumerationCommand(Команда)
	Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check = Не Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check;
	Object.ManualSpreadsheetDocumentColumnsNumeration = Элементы.ManualSpreadsheetDocumentColumnsNumeration.Check;
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure RenumberColumnsCommand(Команда)
	НомерКолонки = 1;
	For Each Реквизит Из ImportedAttributesTable Do
		If Реквизит.Check Then
			If Не Реквизит.ColumnNumber = НомерКолонки Then
				Реквизит.ColumnNumber = НомерКолонки;
			EndIf;
			НомерКолонки = НомерКолонки + 1;
		Else
			Реквизит.ColumnNumber = 0;
		EndIf;

		If Реквизит.ColumnNumber = 0 И Реквизит.ImportMode = "Искать" Then
			Реквизит.ImportMode = "Устанавливать";
		ElsIf Не Реквизит.ColumnNumber = 0 И Реквизит.ImportMode = "Устанавливать" Then
			Реквизит.ImportMode = "Искать";
		EndIf;

	EndDo;
EndProcedure

&НаКлиенте
Procedure EventsCommand(Команда)

	ФормаРедактированиеСобытий = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаРедактированияСобытий", ,
		ЭтаФорма);

	ФормаРедактированиеСобытий.ImportMode = Object.ImportMode;

	ФормаРедактированиеСобытий.BeforeWriteObject.УстановитьТекст(Object.BeforeWriteObject);
	ФормаРедактированиеСобытий.OnWriteObject.УстановитьТекст(Object.OnWriteObject);
	ФормаРедактированиеСобытий.AfterAddRow.УстановитьТекст(Object.AfterAddRow);

	ФормаРедактированиеСобытий.Открыть();

	If True = True Then

		Object.BeforeWriteObject   = ФормаРедактированиеСобытий.BeforeWriteObject.ПолучитьТекст();
		Object.OnWriteObject      = ФормаРедактированиеСобытий.OnWriteObject.ПолучитьТекст();
		Object.AfterAddRow = ФормаРедактированиеСобытий.AfterAddRow.ПолучитьТекст();

	EndIf;

EndProcedure

//@skip-warning
&НаКлиенте
Procedure Attachable_ExecuteToolsCommonCommand(Команда) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ЭтотОбъект, Команда);
EndProcedure



///////////////////////////////////////////////////////////////////////////////
// ПРЕДОПРЕДЕЛЁННЫЕ ОБРАБОТЧИКИ ФОРМЫ

&AtServer
Procedure ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)

	For Each МДСправочник Из Метаданные.Справочники Do
		Элементы.ObjectType.СписокВыбора.Добавить(МДСправочник.Имя, МДСправочник.Синоним);
	EndDo;
	МДНезависимый = Метаданные.СвойстваОбъектов.РежимЗаписиРегистра.Независимый;
	For Each МДРегистрСведений Из Метаданные.РегистрыСведений Do
		If МДРегистрСведений.РежимЗаписи = МДНезависимый Then
			Элементы.RegisterTypeName.СписокВыбора.Добавить(МДРегистрСведений.Имя, МДРегистрСведений.Синоним);
		EndIf;
	EndDo;

	Типы = Новый Массив;
	ВидыТипов = Новый Структура("Справочники,Документы");
	For Each КлючИЗначение Из ВидыТипов Do
		For Each ОбъектМетаданных Из Метаданные[КлючИЗначение.Ключ] Do
			If ОбъектМетаданных.ТабличныеЧасти.Количество() Then
				Типы.Добавить(Тип(СтрЗаменить(ОбъектМетаданных.ПолноеИмя(), ".", "Ссылка.")));
			EndIf;
		EndDo;
	EndDo;

	Элементы.SourceRef.ОграничениеТипа = Новый ОписаниеТипов(Типы);

	Object.ImportMode           = mRestoreValue("ImportMode");
	Object.RegisterTypeName         = mRestoreValue("RegisterTypeName");
	Object.CatalogObjectType   = mRestoreValue("CatalogObjectType");
	Object.SourceRef         = mRestoreValue("SourceRef");

	SetTabularSectionsList();

	ТабличнаяЧастьИсточника = mRestoreValue("SourceTabularSection");

	Инициализация();

	УстановитьИсточник();

	ОбновитьДанныеТабличногоДокументаСервер();
	
	UT_Common.ToolFormOnCreateAtServer(ЭтотОбъект, Отказ, СтандартнаяОбработка);

EndProcedure

&НаКлиенте
Procedure ПриОткрытии(Отказ)
	СисИнфо = Новый СистемнаяИнформация;
	If Лев(СисИнфо.ВерсияПриложения, 3) = "8.3" Then
		Выполнить ("Элементы.SourceRef.ОтображениеКнопкиВыбора = ОтображениеКнопкиВыбора.ОтображатьВПолеВвода;");
		Выполнить ("Элементы.ТаблицаЗагружаемыхРеквизитовЗначениеПоУмолчанию.ОтображениеКнопкиВыбора = ОтображениеКнопкиВыбора.ОтображатьВПолеВвода;");
	EndIf;

	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure ПриЗакрытии()
	ПриЗакрытииНаСервере();
EndProcedure


///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ ЭЛЕМЕНТОВ ФОРМЫ

&НаКлиенте
Procedure ImportModeOnChange(Элемент)
	Object.CatalogObjectType	= Undefined;
	Object.SourceRef			= Undefined;
	Object.RegisterTypeName			= Undefined;
	Object.SourceTabularSection	= Undefined;
	SetTabularSectionsList();
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure ObjectTypeOnChange(Элемент)
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure ObjectTypeOpening(Элемент, СтандартнаяОбработка)
	СтандартнаяОбработка = False;
	If IsBlankString(Object.CatalogObjectType) Then
		Return;
	EndIf;

	Форма = ПолучитьФорму("Справочник." + Object.CatalogObjectType + ".ФормаСписка");
	Форма.Открыть();
EndProcedure

&НаКлиенте
Procedure SourceRefOnChange(Элемент)
	SetTabularSectionsList();
	УстановитьИсточник();
EndProcedure

&НаКлиенте
Procedure SourceTabularSectionOnChange(Элемент)
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure RegisterTypeNameOnChange(Элемент)
	УстановитьИсточник();
	УправлениеВидимостью();
EndProcedure

&НаКлиенте
Procedure RegisterTypeNameOpening(Элемент, СтандартнаяОбработка)
	СтандартнаяОбработка = False;
	If IsBlankString(Object.RegisterTypeName) Then
		Return;
	EndIf;

	Форма = ПолучитьФорму("РегистрСведений." + Object.RegisterTypeName + ".ФормаСписка");
	Форма.Открыть();
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ ТАБЛИЦЫ ЗНАЧЕНИЙ ЗАГРУЖАЕМЫХ РЕКВИЗИТОВ

&НаКлиенте
Procedure ImportedAttributesTableTypeDescriptionStartChoice(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	Элемент.AvailableTypes = ТекДанные.AvailableTypes;
EndProcedure

&НаКлиенте
Procedure ImportedAttributesTableAdditionalConditionsPresentationStartChoice(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	СтандартнаяОбработка = False;
	If ТекДанные.ImportMode = "Вычислять" Then
		ФормаРедактированияВыражения = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаРедактированияВыражения", ,
			ЭтаФорма);

		ПолеТекстовогоДокумента = ФормаРедактированияВыражения.ПолеТекстовогоДокумента;
		ПолеТекстовогоДокумента.УстановитьТекст(ТекДанные.Выражение);

		ФормаРедактированияВыражения.Открыть();
		//If ФормаРедактированияВыражения.Open() = True Then
		//	ТекДанные.Expression = ПолеТекстовогоДокумента.ПолучитьТекст();
		//EndIf;
	Else
		ДоступныеТипы	= ТекДанные.TypeDescription;
		СписокВыбораВладельца	= GetLinkByOwnerChoiceList(ТекДанные.AttributeName);
		ФормаРедактированияСвязи = ПолучитьФорму(DataProcessorID() + ".Форма.ФормаРедактированияСвязи", ,
			ЭтаФорма);
		ФормаРедактированияСвязи.ИспользуемыеТипы = ДоступныеТипы;
		ФормаРедактированияСвязи.SearchBy = ТекДанные.SearchBy;
		ФормаРедактированияСвязи.ИспользоватьВладельца = (СписокВыбораВладельца.Количество() > 0);
		ФормаРедактированияСвязи.LinkByOwner = ТекДанные.LinkByOwner;

		СписокВыбораИскатьПо = GetNamePresentationList(ТекДанные.ОписаниеТипов);
		Сп = ФормаРедактированияСвязи.Элементы.SearchBy.СписокВыбора;
		Сп.Очистить();
		For Each ЭлСписка Из СписокВыбораИскатьПо Do
			Сп.Добавить(ЭлСписка.Значение, ЭлСписка.Представление);
		EndDo;

		Сп = ФормаРедактированияСвязи.Элементы.LinkByOwner.СписокВыбора;
		Сп.Очистить();
		For Each ЭлСписка Из СписокВыбораВладельца Do
			Сп.Добавить(ЭлСписка.Значение, ЭлСписка.Представление);
		EndDo;
		ФормаРедактированияСвязи.Открыть();
		//If ФормаРедактированияСвязи.Open() = True Then
		//	ТекДанные.SearchBy = ФормаРедактированияСвязи.SearchBy;
		//	ТекДанные.LinkByOwner = ФормаРедактированияСвязи.LinkByOwner;
		//EndIf;
	EndIf;
	//If ТекДанные.ImportMode = "Вычислять" Then
	//	ТекДанные.AdditionalConditionsPresentation = ТекДанные.Expression;
	//Else
	//	ТекДанные.AdditionalConditionsPresentation = ?(IsBlankString(ТекДанные.SearchBy), "", "Искать по "+ТекДанные.SearchBy)
	//			+?(IsBlankString(ТекДанные.LinkByOwner), "", " по владельцу "+ТекДанные.LinkByOwner);
	//EndIf;
EndProcedure

&НаКлиенте
Procedure ImportedAttributesTableAdditionalConditionsPresentationClearing(Элемент, СтандартнаяОбработка)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	ТекДанные.AdditionalConditionsPresentation = "";
	ТекДанные.SearchBy = "";
	ТекДанные.LinkByOwner = "";
EndProcedure

&НаКлиенте
Procedure ImportedAttributesTableImportModeOnChange(Элемент)
	ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
	If ТекДанные.ImportMode = "Вычислять" Then
		ТекДанные.AdditionalConditionsPresentation = ТекДанные.Expression;
	Else
		ТекДанные.AdditionalConditionsPresentation = ?(IsBlankString(ТекДанные.SearchBy), "", "Искать по " + ТекДанные.SearchBy)
			+ ?(IsBlankString(ТекДанные.СвязьПоВладельцу), "", " по владельцу " + ТекДанные.LinkByOwner);
	EndIf;
EndProcedure

&НаКлиенте
Procedure ОбработкаВыбора(ВыбранноеЗначение, ИсточникВыбора)
	If ТипЗнч(ВыбранноеЗначение) = Тип("Структура") Then

		If ВыбранноеЗначение.Источник = "ФормаРедактированияСобытий" И ВыбранноеЗначение.Результат = True Then
			Object.BeforeWriteObject		= ВыбранноеЗначение.BeforeWriteObject;
			Object.OnWriteObject			= ВыбранноеЗначение.OnWriteObject;
			Object.AfterAddRow	= ВыбранноеЗначение.AfterAddRow;
		ElsIf ВыбранноеЗначение.Источник = "ФормаРедактированияВыражения" И ВыбранноеЗначение.Результат = True Then
			ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
			ТекДанные.Expression = ВыбранноеЗначение.Expression;
			ТекДанные.AdditionalConditionsPresentation = ТекДанные.Expression;
		ElsIf ВыбранноеЗначение.Источник = "ФормаРедактированияСвязи" И ВыбранноеЗначение.Результат = True Then
			ТекДанные = Элементы.ImportedAttributesTable.ТекущиеДанные;
			ТекДанные.SearchBy = ВыбранноеЗначение.SearchBy;
			ТекДанные.LinkByOwner = ВыбранноеЗначение.LinkByOwner;
			ТекДанные.AdditionalConditionsPresentation = ?(IsBlankString(ТекДанные.SearchBy), "", "Искать по "
				+ ТекДанные.SearchBy) + ?(IsBlankString(ТекДанные.СвязьПоВладельцу), "", " по владельцу "
				+ ТекДанные.LinkByOwner);
		EndIf;

	EndIf;
EndProcedure
