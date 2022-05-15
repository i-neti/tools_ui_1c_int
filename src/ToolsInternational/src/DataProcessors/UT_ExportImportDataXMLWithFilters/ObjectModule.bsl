
Var MetadataDetails Export;
Var RefTypes Export;
Var MetadataObjectsAndRefTypesMap;
Var ProcessedConstantsCount Export;
Var ProcessedRecordSetsCount Export;
Var mRegisterRecordsColumnsMap;

// array of metadata tree rows with Export attribute
Var FullExportContent Export;
// array of metadata tree rows with export by reference
Var AuxiliaryExportContent;

// array of registers using totals
Var RegistersUsingTotals;

Var mTypeQueryResult;
Var mDeletionDataType;

Var mExportedObjects;
//Var mSavedLastExportsCount;

Var mChildObjectsExportExistence;
Var PredefinedItemsTable;
Var RefsReplacementMap;
Var Serializer;
Function ExternalDataProcessorInfo() Export
	// Declaring variable for saving and returning data.
	RegistrationParameters = New Structure;
	// Kind of data processor to register. 
	// Available kinds: AdditionalDataProcessor, AdditionalReport, ObjectFilling, Report, PrintForm, RelatedObjectsCreation.

	RegistrationParameters.Insert("Kind", "AdditionalDataProcessor");
	// Data processor description to be register in external data processors catalog.
	RegistrationParameters.Insert("Description", NStr("ru = 'Выгрузка - загрузка данных XML 8.3'; en = 'Export - import data XML 8.3'"));
	// Safe mode right. For more information see SetSafeMode() method.
	RegistrationParameters.Insert("SafeMode", True);
	// Version and info to display as data processor information.
	RegistrationParameters.Insert("Version", "1.0");
	RegistrationParameters.Insert("Information", NStr("ru = 'Выгрузка - загрузка данных XML 8.3'; en = 'Export - import data XML 8.3'"));
	// Creating command table (see below).

	CommandTable = GetCommandTable();
	// Adding commands to table.

	AddCommand(CommandTable, ThisObject.Metadata().Presentation(),    // Command presentation in the user interface.

		Metadata().FullName(), // Command universally unique identifier.

		"OpeningForm", True, );
	RegistrationParameters.Insert("Command", CommandTable);
	// Returning parameters.

	Return RegistrationParameters
	//
EndFunction

//2) Auxiliary functions***********************************************************
Function GetCommandTable()

   // Creating new command table.
	Commands = New ValueTable;

   // Data processor user presentation.
	Commands.Columns.Add("Presentation", New TypeDescription("String")); 

   // Template name for print data processor.
	Commands.Columns.Add("ID", New TypeDescription("String"));

   // Command startup option.
	// Options available:
	// - OpeningForm - the ID column must contain form name,
	// - ClientMethodCall - calls the client export procedure from data processor main form module,
	// - ServerMethodCall - calls the server export procedure from data processor object module.
	Commands.Columns.Add("StartupOption", New TypeDescription("String"));

   // If True, the notification will be displayed on execution start and finish. Not used in OpeningForm mode.
	Commands.Columns.Add("ShowNotification", New TypeDescription("Boolean"));

   // If Kind = "PrintForm", must contain "MXLPrinting". 
	Commands.Columns.Add("Modifier", New TypeDescription("String"));
	Return Commands;
EndFunction

Procedure AddCommand(CommandTable, Presentation, ID, StartupOption, ShowNotification = False,
	Modifier = "")
  // Adding command to command table according parameters.
  // Parameters described in GetCommandTable function.
	NewCommand = CommandTable.Add();
	NewCommand.Presentation = Presentation;
	NewCommand.ID = ID;
	NewCommand.StartupOption = StartupOption;
	NewCommand.ShowNotification = ShowNotification;
	NewCommand.Modifier = Modifier;

EndProcedure


// Creates an export file.
//
// Parameters:
//   FileName - a name of en export file.
//
Procedure ExecuteExport(Val FileName, InvalidCharsCheckOnly = False, FilterTable1) Export

	ObjectsExportedWithErrors = New Map;

	ExportContent();

	If FullExportContent.Count() = 0 And AdditionalObjectsToExport.Count() = 0 Then

		UserMessage(Нстр("ru = 'Не задан состав выгрузки'; en ='Export content is not set.'"));
		Return;

	EndIf;

	If InvalidCharsCheckOnly Then

		XMLWriter = CreateXMLRecordObjectForCheck();

		DataExport(XMLWriter, InvalidCharsCheckOnly, ObjectsExportedWithErrors, FilterTable1);

	Else

		If UseFastInfoSetFormat Then

			XMLWriter = New FastInfosetWriter;
			XMLWriter.OpenFile(FileName);

		Else

			XMLWriter = New XMLWriter;
			XMLWriter.OpenFile(FileName, "UTF-8");

		EndIf;

		XMLWriter.WriteXMLDeclaration();
		XMLWriter.WriteStartElement("_1CV8DtUD", "http://www.1c.ru/V8/1CV8DtUD/");
		XMLWriter.WriteNamespaceMapping("V8Exch", "http://www.1c.ru/V8/1CV8DtUD/");
		XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");
		XMLWriter.WriteNamespaceMapping("core", "http://v8.1c.ru/data");

		XMLWriter.WriteNamespaceMapping("v8", "http://v8.1c.ru/8.1/data/enterprise/current-config");
		XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");

		XMLWriter.WriteStartElement("V8Exch:Data");

		If InvalidCharsCheckOnly Then

			CheckStartTemplate = NStr("ru = 'Начало проверки: %Date'; en = 'Check started: %Date'");
			CheckStartMessage = StrReplace(CheckStartTemplate, "%Date", CurrentSessionDate());
			UserMessage(CheckStartMessage);

		Else

			ExportStartTemplate = NStr("ru = 'Начало выгрузки: %Date'; en = 'Check started: %Date'");
			ExportStartMessage = StrReplace(ExportStartTemplate, "%Date", CurrentSessionDate());
			UserMessage(ExportStartMessage);

		EndIf;

		InitializeXDTOSerializerWithTypesAnnotation();

		DataExport(XMLWriter, , , FilterTable1);

		XMLWriter.WriteEndElement(); //V8Exc:Data
		ExportPredefinedItemsTable(XMLWriter);
		XMLWriter.WriteEndElement(); //V8Exc:_1CV8DtUD

	EndIf;

	If InvalidCharsCheckOnly Then

		TemplateChecked = NStr("ru = 'Проверено объектов: %Checked'; en = 'Objects checked: %Checked'");
		MessageChecked = StrReplace(TemplateChecked, "%Checked", TotalProcessedRecords());
		UserMessage(MessageChecked);

		TemplateEnd = NStr("ru = 'Окончание проверки: %Date'; en = 'Check completed at: %Date'");
		MessageEnd = StrReplace(TemplateEnd, "%Date", CurrentSessionDate());
		UserMessage(MessageEnd);

	Else

		TemplateExported = NStr("ru = 'Выгружено объектов: %Exported'; en = 'Objects exported: %Exported'");
		MessageExported = StrReplace(TemplateExported, "%Exported", TotalProcessedRecords());
		UserMessage(MessageExported);

		TemplateEnd = NStr("ru = 'Окончание выгрузки: %Date'; en = 'Export completed at: %Date'");
		MessageEnd = StrReplace(TemplateEnd, "%Date", CurrentSessionDate());
		UserMessage(MessageEnd);

		UserMessage(NStr("ru = 'Выгрузка данных успешно завершена'; en = 'Data export is completed successfully'"));

	EndIf;

EndProcedure

// Parses an export file and writes results to IB.
//
// Parameters:
//   FileName - a name of an export file.
//
Procedure ExecuteImport(Val FileName) Export

	File = New File(FileName);

	If File.Extension = ".fi" Then

		XMLReader = New FastInfosetReader;
		XMLReader.Read();
		XMLReader.OpenFile(FileName);

		XMLWriter = New XMLWriter;
		TempFileName = GetTempFileName("xml");
		XMLWriter.OpenFile(TempFileName, "UTF-8");

		While XMLReader.Read() Do

			XMLWriter.WriteCurrent(XMLReader);

		EndDo;

		XMLWriter.Close();

		FileName = TempFileName;

	EndIf;

	XMLReader = New XMLReader;
	XMLReader.OpenFile(FileName);
	// Checking an exchange file format.
	If Not XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.LocalName <> "_1CV8DtUD"
		Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then

		UserMessage(NStr("ru = 'Неверный формат файла выгрузки'; en = 'Incorrect export file format'"));
		Return;

	EndIf;

	If Not XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.LocalName
		<> "Data" Then

		UserMessage(NStr("ru = 'Неверный формат файла выгрузки'; en = 'Incorrect export file format'"));
		Return;

	EndIf;

	If Not ThisObject.PredefinedItemsImportMode = 2 Then
		ImportPredefinedItemsTable(XMLReader);
		ReplacePredefinedItemsRefs(FileName);
	EndIf;

	XMLReader.OpenFile(FileName);
	XMLReader.Read();
	XMLReader.Read();
	
	// Reading and writing objects from export file.
	If Not XMLReader.Read() Then

		UserMessage(NStr("ru = 'Неверный формат файла выгрузки'; en = 'Incorrect export file format'"));
		Return;

	EndIf;

	Imported = 0;
	RemoveTotalsUsage();

	MessageTemplate = NStr("ru = 'Начало загрузки: %Date'; en = 'Import starts at: %Date'");
	MessageText = StrReplace(MessageTemplate, "%Date", CurrentSessionDate());

	UserMessage(MessageText);

	InitializeXDTOSerializerWithTypesAnnotation();

	While Serializer.CanReadXML(XMLReader) Do

		Try
			WrittenValue = Serializer.ReadXML(XMLReader);
		Except
			RestoreTotalsUsage();
			Raise;
		EndTry;

		If UseDataExchangeModeOnImport Then

			Try // Exchange plans does not contain a DataExchange attribute.
				WrittenValue.DataExchange.Load = True;
			Except
			EndTry;

		EndIf;

		Try
			WrittenValue.Write();
		Except

			ErrorText = ErrorDescription();

			If Not ContinueImportOnError Then

				RestoreTotalsUsage();
				Raise;

			Else

				Try
					MessageText = NStr("ru = 'При загрузке объекта %1(%2) возникла ошибка:
										  |%3'; 
									   |en = 'An error %3 occured while loading an object %1(%2).'");
					MessageText = SubstituteParametersToString(MessageText, WrittenValue, TypeOf(
						WrittenValue), ErrorText);
				Except
					MessageText = NStr("ru = 'При загрузке данных возникла ошибка:
										  |%1';
									   |en = 'An error occured on data import.'");
					MessageText = SubstituteParametersToString(MessageText, ErrorText);
				EndTry;

				UserMessage(MessageText);

			EndIf;

			Imported = Imported - 1;

		EndTry;

		Imported = Imported + 1;

	EndDo;

	RestoreTotalsUsage();
	
	// Checking an exchange file format.
	If XMLReader.NodeType <> XMLNodeType.EndElement Or XMLReader.LocalName <> "Data" Then

		UserMessage(NStr("ru = 'Неверный формат файла выгрузки'; en = 'Incorrect export file format'"));
		Return;

	EndIf;

	If Not XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.StartElement Or XMLReader.LocalName
		<> "PredefinedData" Then

		UserMessage(NStr("ru = 'Неверный формат файла выгрузки'; en = 'Incorrect export file format'"));
		Return;

	EndIf;

	XMLReader.Пропустить();

	If Не XMLReader.Read() Or XMLReader.NodeType <> XMLNodeType.EndElement Or XMLReader.LocalName <> "_1CV8DtUD"
		Or XMLReader.NamespaceURI <> "http://www.1c.ru/V8/1CV8DtUD/" Then

		UserMessage(NStr("ru = 'Неверный формат файла выгрузки'; en = 'Incorrect export file format'"));
		Return;

	EndIf;

	XMLReader.Close();

	TemplateImported = NStr("ru = 'Загружено объектов: %Count'; en = '%Count objects imported'");
	MessageImported = StrReplace(TemplateImported, "%Count", Imported);

	TemplateEnd = NStr("ru = 'Окончание загрузки: %Date'; en = 'Import finished at: %Date'");
	MessageEnd = StrReplace(TemplateEnd, "%Date", CurrentSessionDate());

	UserMessage(MessageImported);
	UserMessage(MessageEnd);
	UserMessage(NStr("ru = 'Загрузка данных успешно завершена'; en = 'Data is imported successfully'"));

EndProcedure

// Executes initial initialization, namely filling of a metadata object class tree, a metadata tree, 
// a list of reference types.
//
Procedure Initializing() Export

	AllowResultsUsageEditingRights = False;
	
	// Creating an object that describes processes of creating a tree and export.
	FillMetadataDetails();

	MetadataDetails = MetadataDetails.Rows[0];

	RefTypes = New Map;
	MetadataObjectsAndRefTypesMap = New Map;

	MetadataTree.Columns.Clear();
	// Creating required columns.
	MetadataTree.Columns.Add("ExportData", New TypeDescription("Number", New NumberQualifiers(1, 0,
		AllowedSign.Nonnegative)));
	MetadataTree.Columns.Add("ExportIfNecessary", New TypeDescription("Число",
		New NumberQualifiers(1, 0, AllowedSign.Nonnegative)));
	MetadataTree.Columns.Add("Metadata");
	MetadataTree.Columns.Add("Detail");
	MetadataTree.Columns.Add("MetadataObjectName");
	MetadataTree.Columns.Add("MDObject");
	MetadataTree.Columns.Add("FullMetadataName");
	MetadataTree.Columns.Add("ComposerSettings");
	MetadataTree.Columns.Add("UseFilter");
	MetadataTree.Columns.Add("PictureIndex");
	//MetadataTree.Columns.Add("TreeIndex");

	MetadataTree.Columns.Add("Expanded");

	RegistersUsingTotals = New Array;
	Root = MetadataTree.Rows.Add();
	BuildObjectSubtree(Metadata, Root, MetadataDetails);
	CollapseObjectSubtree(Root);

	For Each Item In RefTypes Do
		MetadataObjectsAndRefTypesMap.Insert(Item.Value, Item.Key);
	EndDo;

EndProcedure

Function CreateXMLRecordObjectForCheck()

	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-16");
	XMLWriter.WriteStartElement("CheckSSL");

	Return XMLWriter;

EndFunction

// Internal
//
Procedure CheckExchangePlanObjectsExport(NodeRef) Export

	ObjectsExportedWithErrors = New Map;
	TotalObjectsProcessed = 0;
	ErrorCount = 0;

	XMLWriter = CreateXMLRecordObjectForCheck();

	ExportContent();
	MetadataArrayForExport = New Array;

	For Each ExportTableRow In FullExportContent Do

		MetadataTreeRow = ExportTableRow.TreeRow;

		MetadataArrayForExport.Add(MetadataTreeRow.MDObject);

	EndDo;

	If MetadataArrayForExport.Count() = 0 Then
		MetadataArrayForExport = Undefined;
	EndIf;

	ChangesSelection = ExchangePlans.SelectChanges(NodeRef, NodeRef.SentNo + 1,
		MetadataArrayForExport);
	While ChangesSelection.Next() Do
		
		// changed item
		Data = ChangesSelection.Get();
		
		If Data = Undefined Then
			Continue;
		EndIf;

		IsDeletion = (mDeletionDataType = TypeOf(Data));

		If IsDeletion Then
			Continue;
		EndIf;

		TotalObjectsProcessed = TotalObjectsProcessed + 1;

		ObjectMetadata = Data.Metadata();

		Try

			ExecuteAuxiliaryActionsForXMLWriter(TotalObjectsProcessed, XMLWriter, True);

			Serializer.WriteXML(XMLWriter, Data);

		Except

			ErrorCount = ErrorCount + 1;

			ErrorDescriptionString = ErrorDescription();
			
			// Adding a reference for reference types and an object for another types.
			IsNotRef = Metadata.InformationRegisters.Contains(ObjectMetadata)
				Or Metadata.AccumulationRegisters.Contains(ObjectMetadata)
				Or Metadata.AccountingRegisters.Contains(ObjectMetadata) Or Metadata.Constants.Contains(
				ObjectMetadata);

			If IsNotRef Then

				ObjectsExportedWithErrors.Insert(Data, ErrorDescriptionString);

			Else

				If ObjectsExportedWithErrors.Get(Data.Ref) = Undefined Then
					ObjectsExportedWithErrors.Insert(Data.Ref, ErrorDescriptionString);
				EndIf;

			EndIf;

		EndTry;

	EndDo;

	GenerateErrorTable(ObjectsExportedWithErrors);

EndProcedure

Procedure GenerateErrorTable(ObjectsExportedWithErrors)

	If ObjectsExportedWithErrors.Count() = 0 Then
		UserMessage(NStr(
			"ru = 'Проверка объектов на наличие недопустимых символов завершена. Ошибок не обнаружено.'
			|en = 'Checking objects for invalid characters is complete. No errors found.'"));
	Else

		ErrorSearchString = "WriteXML):";
		SearchStringLength = StrLen(ErrorSearchString);

		DataTable = New ValueTable;
		DataTable.Columns.Add("Object");
		DataTable.Columns.Add("ErrorText");

		For Each MapRow In ObjectsExportedWithErrors Do

			TableRow = DataTable.Add();
			TableRow.Object = String(MapRow.Key);
			
			// Deletion a service symbols from error text.
			MessageText = GenerateMessageTextWithoutServiceSymbols(MapRow.Value);

			ErrorStartPosition = Find(MessageText, "WriteXML):");
			If ErrorStartPosition > 0 Then

				MessageText = Mid(MessageText, ErrorStartPosition + SearchStringLength);

			EndIf;

			TableRow.ErrorText = TrimAll(MessageText);

		EndDo;

	EndIf;

EndProcedure

Function GenerateMessageTextWithoutServiceSymbols(Val MessageText)

	ServiceMessageBegin    = Find(MessageText, "{");
	ServiceMessageEnd = Find(MessageText, "}:");

	If ServiceMessageEnd > 0 And ServiceMessageBegin > 0 And ServiceMessageBegin
		< ServiceMessageEnd Then

		MessageText = Left(MessageText, (ServiceMessageBegin - 1)) + Mid(MessageText,
			(ServiceMessageEnd + 2));

	EndIf;

	Return TrimAll(MessageText);

EndFunction // ()

// Recursively processes a metadata tree generating lists of full and auxiliary exports.
//
Procedure ExportContent(RecalculateDataToExportByRef = False) Export

	FullExportContent = New ValueTable;
	FullExportContent.Columns.Add("MDObject");
	FullExportContent.Columns.Add("TreeRow");
	FullExportContent.Indexes.Add("ОбъектМД");

	AuxiliaryExportContent = New ValueTable;
	AuxiliaryExportContent.Columns.Add("MDObject");
	AuxiliaryExportContent.Columns.Add("TreeRow");
	AuxiliaryExportContent.Indexes.Add("MDObject");

	For Each VTRow Из MetadataTree.Rows Do
		AddObjectsToExport(FullExportContent, AuxiliaryExportContent, VTRow);
	EndDo;

	mChildObjectsExportExistence = AuxiliaryExportContent.Count() > 0;

	If RecalculateDataToExportByRef Then

		RecalculateDataToExportByRef(FullExportContent);

	EndIf;

EndProcedure

Procedure ExportRefsArrayData(RefsArray, NameForQueryString, XMLWriter,
	InvalidCharsCheckOnly = False, ObjectsExportedWithErrors = Undefined, FilterTable1)

	If RefsArray.Count() = 0 Or Not ValueIsFilled(NameForQueryString) Then

		Return;

	EndIf;

	Query = New Query;
	Query.Текст = "SELECT allowed ObjectTable_.*
				   |	
				   |FROM
				   |	" + NameForQueryString + " AS ObjectTable_
												  |WHERE
												  |	ObjectTable_.Ref IN(&RefsArray)";

	Query.SetParameter("RefsArray", RefsArray);

	QueryResult = Query.Execute();

	QueryAndWriter(QueryResult, XMLWriter, True, ObjectsExportedWithErrors, InvalidCharsCheckOnly);

EndProcedure

// Writes a set of register records (accumulation register, accounting register, and other).
//
// Parameters:
//   XMLWriter - an object used to write infobase objects.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//
Procedure DataExport(XMLWriter, InvalidCharsCheckOnly = False,
	ObjectsExportedWithErrors = Undefined, FilterTable1)

	mExportedObjects = New ValueTable;
	mExportedObjects.Columns.Add("Ref");
	mExportedObjects.Indexes.Add("Ref");

	InitializePredefinedItemsTable();

	If ObjectsExportedWithErrors = Undefined Then
		ObjectsExportedWithErrors = New Map;
	EndIf;

	Try

		For Each ExportTableRow In FullExportContent Do

			MetadataTreeRow = ExportTableRow.TreeRow;

			If MetadataTreeRow.Detail.Manager = Undefined Then
				Raise (NStr("ru = 'Выгрузка данных. Внутренняя ошибка'; en = 'Data export. Internal error.'"));
			EndIf;

			If Metadata.Constants.Contains(MetadataTreeRow.MDObject) Then

				WriteConstant(XMLWriter, MetadataTreeRow.MDObject, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly, FilterTable1);

			ElsIf Metadata.InformationRegisters.Contains(MetadataTreeRow.MDObject)
				Or Metadata.AccumulationRegisters.Contains(MetadataTreeRow.MDObject)
				Or Metadata.CalculationRegisters.Contains(MetadataTreeRow.MDObject) Then

				WriteRegister(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly, , FilterTable1);

			ElsIf Metadata.AccountingRegisters.Contains(MetadataTreeRow.MDObject) Then

				WriteRegister(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly, True, FilterTable1);

			ElsIf TypeOf(MetadataTreeRow.Detail.Manager) = Type("String") Then
				// recalculations
				WriteRecalculation(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly, FilterTable1);

			ElsIf Metadata.Sequences.Contains(MetadataTreeRow.MDObject) Then

				WriteSequence(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly, FilterTable1);

			Else

				WriteObjectTypeData(MetadataTreeRow, XMLWriter, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly, FilterTable1);

			EndIf;

		EndDo;

		AdditionalObjectsToExport.Sort("ObjectForQueryName");
		CurrentRefsArray = New Array;
		CurrentQueryName = "";

		For Each ExportTableRow In AdditionalObjectsToExport Do

			If Not ValueIsFilled(ExportTableRow.Object) Or Not ValueIsFilled(
				ExportTableRow.ObjectForQueryName) Then

				Continue;

			EndIf;

			If CurrentQueryName <> ExportTableRow.ObjectForQueryName Then

				ExportRefsArrayData(CurrentRefsArray, CurrentQueryName, XMLWriter,
					InvalidCharsCheckOnly, ObjectsExportedWithErrors, FilterTable1);

				CurrentRefsArray = New Array;
				CurrentQueryName = ExportTableRow.ObjectForQueryName;

			EndIf;

			CurrentRefsArray.Add(ExportTableRow.Object);

		EndDo;

		ExportRefsArrayData(CurrentRefsArray, CurrentQueryName, XMLWriter,
			InvalidCharsCheckOnly, ObjectsExportedWithErrors, FilterTable1);

	Except
		Raise;
	EndTry;

EndProcedure

// Internal
//
Function GetRestrictionByDateStringForQuery(Properties, TypeName) Export

	FinalRestrictionByDate = "";
	TableAliasName = Properties.Name;

	If Not (TypeName = "Document" Or TypeName = "InformationRegister" Or TypeName = "Register") Then
		Return FinalRestrictionByDate;
	EndIf;

	RestrictionFieldName = TableAliasName + "." + ?(TypeName = "Document", "Date", "Period");

	If ValueIsFilled(StartDate) Then

		FinalRestrictionByDate = "
									|	WHERE
									|		ObjectTable_" + RestrictionFieldName + " >= &StartDate";

	EndIf;

	If ValueIsFilled(EndDate) Then

		If IsBlankString(FinalRestrictionByDate) Then

			FinalRestrictionByDate = "
										|	WHERE
										|		ObjectTable_" + RestrictionFieldName + " <= &EndDate";

		Else

			FinalRestrictionByDate = FinalRestrictionByDate + "
																	|	AND
																	|		ObjectTable_" + RestrictionFieldName
				+ " <= &EndDate";

		EndIf;

	EndIf;

	Return FinalRestrictionByDate;

EndFunction


// Internal
//
Function GetQueryTextForInformationRegister(MetadataName, MetadataObject, AdditionalFilters,
	FieldsForSelectionString = "", FieldsForSelectionString1 = "", FilterTable1)

	RestrictionByDateExists = (ValueIsFilled(StartDate) Or ValueIsFilled(EndDate));

	If Not ValueIsFilled(FieldsForSelectionString) Then
		FieldsForSelectionString ="ObjectTable_" + MetadataObject.Name + ".*";
		FieldsForSelectionString1="ObjectTable_" + MetadataObject.Name + "1.*";

	Else
		FieldsForSelectionString1 = " Distinct " + FieldsForSelectionString1;
		FieldsForSelectionString = " Distinct " + FieldsForSelectionString;
	EndIf;

	QueryText = "SELECT Distinct " + FieldsForSelectionString + " FROM " + MetadataName + " AS ObjectTable_"
		+ MetadataObject.Name;
	
	//If MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
	//	Return QueryText;
	//EndIf;
	
	// 0 - filter by period
	// 1 - slice of last items as of the end date
	// 2 - slice of first items as of the start date
	// 3 - slice of last items as of the start date + filter by period

	First=True;

	If MetadataObject.InformationRegisterPeriodicity
		= Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then

	ElsIf PeriodicRegistersExportType = 0 Then

		If AdditionalFilters And Not UseFilterByDateForAllObjects Then

		Else
			If RestrictionByDateExists Then
				AdditionalRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "InformationRegister");

				QueryText = QueryText + Chars.LF + AdditionalRestrictionByDate;
				First=False;
			EndIf;
		EndIf;
	ElsIf PeriodicRegistersExportType = 1 Then

		QueryText = "SELECT Allowed " + FieldsForSelectionString + " FROM " + MetadataName
			+ ".SliceLast(&EndDate) AS ObjectTable_" + MetadataObject.Name;

	ElsIf PeriodicRegistersExportType = 2 Then

		QueryText = "SELECT Allowed " + FieldsForSelectionString + " FROM " + MetadataName
			+ ".SliceFirst(&StartDate) AS ObjectTable_" + MetadataObject.Name;

	ElsIf PeriodicRegistersExportType = 3 Then

		QueryText = "SELECT Allowed " + FieldsForSelectionString1 + " FROM " + MetadataName
			+ ".SliceLast(&StartDate) AS ObjectTable_" + MetadataObject.Name + "1
																						 |
																						 |Union all
																						 |
																						 |SELECT "
			+ FieldsForSelectionString + " FROM " + MetadataName + " AS ObjectTable_" + MetadataObject.Name + "
																											   |";

		AdditionalRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "InformationRegister");

		QueryText = QueryText + Chars.LF + AdditionalRestrictionByDate;

		First=False;

	EndIf;

	For Each Row In FilterTable1 Do
		If MetadataObject.Name = Row.AttributeName Then
			For Each ItemsRow In Row.Filter.Items Do
				If ItemsRow.Use Then

					If Not First Then
						QueryText = QueryText + Chars.LF + " AND " + GetComparisonTypeForQuery(Row,
							ItemsRow, ItemsRow.ComparisonType);
					Else
						QueryText = QueryText + Chars.LF + " WHERE " + GetComparisonTypeForQuery(Row,
							ItemsRow, ItemsRow.ComparisonType);
					EndIf;
					First=False;
				EndIf;
			EndDo;
			Break;
		EndIf;
	EndDo;
	Return QueryText;

EndFunction

Function GetQueryTextForRegister(MetadataName, MetadataObject, AdditionalFilters, FieldsForSelectionString = "",
	FilterTable1)

	RestrictionByDateExists = (ValueIsFilled(StartDate) Or ValueIsFilled(EndDate))
		And UseFilterByDateForAllObjects;

	If Not ValueIsFilled(FieldsForSelectionString) Then
		FieldsForSelectionString = "ObjectTable_" + MetadataObject.Name + ".*";
	Else
		//FieldsForSelectionString = " DISTINCT ObjectTable_" + MetadataObject.Name+"."+ FieldsForSelectionString;
		
	EndIf;

	QueryText = "SELECT Allowed " + FieldsForSelectionString + " FROM " + MetadataName + " AS ObjectTable_"
		+ MetadataObject.Name;

	First=True;
	// Setting of a restriction by dates might be required.
	If RestrictionByDateExists Then

		If AdditionalFilters And Not UseFilterByDateForAllObjects Then

			Return QueryText;

		EndIf;

		AdditionalRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Register");

		QueryText = QueryText + Chars.LF + AdditionalRestrictionByDate;

		First=False;
	EndIf;
	For Each Row In FilterTable1 Do
		If MetadataObject.Name = Row.AttributeName Then
			For Each ItemsRow In Row.Отбор.Items Do
				If ItemsRow.Use Then

					If Not First Then
						QueryText = QueryText + Chars.LF + " AND " + GetComparisonTypeForQuery(Row,
							ItemsRow, ItemsRow.ComparisonType);
					Else
						QueryText = QueryText + Chars.LF + " WHERE " + GetComparisonTypeForQuery(Row,
							ItemsRow, ItemsRow.ComparisonType);
					EndIf;
					First=False;
				EndIf;
			EndDo;
			Break;
		EndIf;
	EndDo;
	Return QueryText;

EndFunction

// Для внутреннего использования
//
Function ПолучитьТекстЗапросаПоСтроке(СтрокаДереваМетаданных, ЕстьДопОтборы, СтрокаПолейДляВыборки = "",
	СтрокаПолейДляВыборки1 = "", ТаблицаОтбора1) Export

	ОбъектМетаданных  = СтрокаДереваМетаданных.Metadata;
	ИмяМетаданных     = ОбъектМетаданных.ПолноеИмя();

	If Metadata.РегистрыСведений.Содержит(ОбъектМетаданных) Then

		ТекстЗапроса = GetQueryTextForInformationRegister(ИмяМетаданных, ОбъектМетаданных, ЕстьДопОтборы,
			СтрокаПолейДляВыборки, СтрокаПолейДляВыборки1, ТаблицаОтбора1);
		Return ТекстЗапроса;

	ElsIf Metadata.РегистрыНакопления.Содержит(ОбъектМетаданных) Или Metadata.РегистрыБухгалтерии.Содержит(
		ОбъектМетаданных) Then

		ТекстЗапроса = GetQueryTextForRegister(ИмяМетаданных, ОбъектМетаданных, ЕстьДопОтборы,
			СтрокаПолейДляВыборки, ТаблицаОтбора1);
		Return ТекстЗапроса;

	EndIf;

	ЕстьОграничениеПоДатам = (ValueIsFilled(StartDate) Или ValueIsFilled(EndDate))
		И UseFilterByDateForAllObjects;

	If Не ValueIsFilled(СтрокаПолейДляВыборки) Then
		СтрокаПолейДляВыборки = "ТаблицаОбъекта_" + СтрокаДереваМетаданных.ПолноеИмяМетаданных + ".*";
	EndIf;

	ТекстЗапроса = "ВЫБРАТЬ Разрешенные " + СтрокаПолейДляВыборки + " ИЗ " + ИмяМетаданных + " КАК ТаблицаОбъекта_"
		+ СтрокаДереваМетаданных.ПолноеИмяМетаданных;
	
	// возможно нужно ограничение по датам установить
	Первая=True;

	If ЕстьОграничениеПоДатам Then

		If ЕстьДопОтборы И Не UseFilterByDateForAllObjects Then

			Return ТекстЗапроса;

		EndIf;

		ДопОграничениеПоДате = "";
		
		// можно ли для данного объекта МД строить ограничения по датам
		If Metadata.Документы.Содержит(ОбъектМетаданных) Then

			ДопОграничениеПоДате = GetRestrictionByDateStringForQuery(ОбъектМетаданных, "Документ");
			Первая=False;

		ElsIf Metadata.РегистрыБухгалтерии.Содержит(ОбъектМетаданных) Или Metadata.РегистрыНакопления.Содержит(
			ОбъектМетаданных) Then

			ДопОграничениеПоДате = GetRestrictionByDateStringForQuery(ОбъектМетаданных, "Регистр");
			Первая=False;

		EndIf;

		ТекстЗапроса = ТекстЗапроса + Символы.ПС + ДопОграничениеПоДате;
	EndIf;

	For Each Строка Из ТаблицаОтбора1 Do
		If СтрокаДереваМетаданных.ПолноеИмяМетаданных = Строка.имяреквизита
			И СтрокаДереваМетаданных.Родитель.Metadata = Строка.ИмяОбъектаМетаданных Then
			For Each СтрокаЭлементы Из Строка.Отбор.Элементы Do
				If СтрокаЭлементы.Использование Then

					If Не Первая Then
						ТекстЗапроса = ТекстЗапроса + Символы.ПС + " И " + GetComparisonTypeForQuery(Строка,
							СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
					Else
						ТекстЗапроса = ТекстЗапроса + Символы.ПС + " ГДЕ " + GetComparisonTypeForQuery(Строка,
							СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
					EndIf;
					Первая=False;
				EndIf;
			EndDo;
			Прервать;
		EndIf;
	EndDo;
	Return ТекстЗапроса;

EndFunction
Function GetComparisonTypeForQuery(Строка, СтрокаЭлементы, ВидСравнения)
	
	//Строка.ИмяРеквизита+GetComparisonTypeForQuery(СтрокаЭлементы.ВидСравнения)+"&"+Строка(СтрокаЭлементы.ЛевоеЗначение)+ Символы.ПС

	ЛевоеЗначение=StrReplace(Строка(СтрокаЭлементы.ЛевоеЗначение), ".", "_");

	If ВидСравнения = ВидСравненияКомпоновкиданных.Больше Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + ">&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.БольшеИлиРавно Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + ">=&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВИерархии Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " В ИЕРАРХИИ(&"
			+ ЛевоеЗначение + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВСписке Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " В (&"
			+ ЛевоеЗначение + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВСпискеПоИерархии Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " В ИЕРАРХИИ(&"
			+ ЛевоеЗначение + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Меньше Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + "<&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.МеньшеИлиРавно Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + "<=&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВИерархии Then
		ВозвращЗначение=" НЕ " + "ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение
			+ " В ИЕРАРХИИ(&" + ЛевоеЗначение + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВСписке Then
		ВозвращЗначение=" НЕ " + "ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " В (&"
			+ ЛевоеЗначение + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВСпискеПоИерархии Then
		ВозвращЗначение=" НЕ " + "ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение
			+ " В ИЕРАРХИИ(&" + ЛевоеЗначение + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеРавно Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + "<>&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеСодержит Then
		ВозвращЗначение=" НЕ " + "ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение
			+ " ПОДОБНО &" + ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Подобно Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " ПОДОБНО &"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеПодобно Then
		ВозвращЗначение=" НЕ " + "ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение
			+ " ПОДОБНО &" + ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Равно Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + "=&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Содержит Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " ПОДОБНО &"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НачинаетсяС Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + ">=&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеНачинаетсяС Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + "<&"
			+ ЛевоеЗначение + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Заполнено Then
		ВозвращЗначение="ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение + " ЕСТЬ NULL "
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НЕЗаполнено Then
		ВозвращЗначение=" НЕ " + "ТаблицаОбъекта_" + Строка.ИмяРеквизита + "." + СтрокаЭлементы.ЛевоеЗначение
			+ " ЕСТЬ NULL " + Символы.ПС;
	EndIf;

	Return ВозвращЗначение;

EndFunction

Function GetComparisonTypeForQueryКонстанта(Строка, СтрокаЭлементы, ВидСравнения)
	
	//Строка.ИмяРеквизита+GetComparisonTypeForQuery(СтрокаЭлементы.ВидСравнения)+"&"+Строка(СтрокаЭлементы.ЛевоеЗначение)+ Символы.ПС
	If ВидСравнения = ВидСравненияКомпоновкиданных.Больше Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + ">&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.БольшеИлиРавно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + ">=&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВИерархии Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " В ИЕРАРХИИ(&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВСписке Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " В (&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВСпискеПоИерархии Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " В ИЕРАРХИИ(&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Меньше Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + "<&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.МеньшеИлиРавно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + "<=&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВИерархии Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " В ИЕРАРХИИ(&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВСписке Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение"" В (&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВСпискеПоИерархии Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " В ИЕРАРХИИ(&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеРавно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + "<>&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеСодержит Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " ПОДОБНО &" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Подобно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " ПОДОБНО &" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеПодобно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " ПОДОБНО &" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Равно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + "=&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Содержит Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " ПОДОБНО &" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НачинаетсяС Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + ">=&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеНачинаетсяС Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + "<&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Заполнено Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " ЕСТЬ NULL " + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НЕЗаполнено Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + ".Значение" + " ЕСТЬ NULL " + Символы.ПС;
	EndIf;

	Return ВозвращЗначение;

EndFunction

Function GetComparisonTypeForQueryРегистр(Строка, СтрокаЭлементы, ВидСравнения)
	
	//Строка.ИмяРеквизита+GetComparisonTypeForQuery(СтрокаЭлементы.ВидСравнения)+"&"+Строка(СтрокаЭлементы.ЛевоеЗначение)+ Символы.ПС
	If ВидСравнения = ВидСравненияКомпоновкиданных.Больше Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ">&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.БольшеИлиРавно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ">=&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВИерархии Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + " В ИЕРАРХИИ(&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВСписке Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + " В (&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + ")"
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.ВСпискеПоИерархии Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + " В ИЕРАРХИИ(&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Меньше Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + "<&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.МеньшеИлиРавно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + "<=&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВИерархии Then
		ВозвращЗначение=" НЕ " + СтрокаЭлементы.ЛевоеЗначение + " В ИЕРАРХИИ(&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВСписке Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + " В (&" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеВСпискеПоИерархии Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + " В ИЕРАРХИИ(&" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + ")" + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеРавно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + "<>&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеСодержит Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + " ПОДОБНО &" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Подобно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + " ПОДОБНО &" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеПодобно Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + " ПОДОБНО &" + Строка(
			СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Равно Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + "=&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Содержит Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + " ПОДОБНО &" + Строка(СтрокаЭлементы.ЛевоеЗначение)
			+ Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НачинаетсяС Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + ">=&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НеНачинаетсяС Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + "<&" + Строка(СтрокаЭлементы.ЛевоеЗначение) + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.Заполнено Then
		ВозвращЗначение=Строка(СтрокаЭлементы.ЛевоеЗначение) + " ЕСТЬ NULL " + Символы.ПС;
	ElsIf ВидСравнения = ВидСравненияКомпоновкиданных.НЕЗаполнено Then
		ВозвращЗначение=" НЕ " + Строка(СтрокаЭлементы.ЛевоеЗначение) + " ЕСТЬ NULL " + Символы.ПС;
	EndIf;

	Return ВозвращЗначение;

EndFunction



// Для внутреннего использования
//
Function ПодготовитьПостроительДляВыгрузки(СтрокаДереваМетаданных, СтрокаПолейДляВыборки = "",
	СтрокаПолейДляВыборки1 = "", ТаблицаОтбора1) Export

	ЕстьДопОтборы = (СтрокаДереваМетаданных.НастройкиПостроителя <> Undefined);

	ИтоговыйТекстЗапроса = ПолучитьТекстЗапросаПоСтроке(СтрокаДереваМетаданных, ЕстьДопОтборы, СтрокаПолейДляВыборки,
		СтрокаПолейДляВыборки1, ТаблицаОтбора1);

	ПостроительОтчета = New ПостроительОтчета;

	ПостроительОтчета.Текст = ИтоговыйТекстЗапроса;

	ПостроительОтчета.ЗаполнитьНастройки();

	ПостроительОтчета.Отбор.Сбросить();
	If ЕстьДопОтборы Then

		ПостроительОтчета.УстановитьНастройки(СтрокаДереваМетаданных.НастройкиПостроителя);

	EndIf;

	ПостроительОтчета.Параметры.Вставить("StartDate", StartDate);
	ПостроительОтчета.Параметры.Вставить("EndDate", EndDate);

	For Each СтрокаТабл Из ТаблицаОтбора1 Do
		If СтрокаДереваМетаданных.Metadata.Имя = СтрокаТабл.ИмяРеквизита И СтрокаТабл.ИмяОбъектаМетаданных
			= СтрокаДереваМетаданных.Родитель.Metadata Then
			For Each СтрокаЭлемент Из СтрокаТабл.Отбор.Элементы Do

				ЛевоеЗначение=StrReplace(Строка(СтрокаЭлемент.ЛевоеЗначение), ".", "_");

				If СтрокаЭлемент.ВидСравнения = ВидСравненияКомпоновкиДанных.Содержит Или СтрокаЭлемент.ВидСравнения
					= ВидСравненияКомпоновкиДанных.НеСодержит Then
					ПостроительОтчета.Параметры.Вставить(ЛевоеЗначение, "%" + СтрокаЭлемент.ПравоеЗначение + "%");
				Else
					If Строка(TypeOf(СтрокаЭлемент.ПравоеЗначение)) = "Стандартная дата начала" Then
						ПостроительОтчета.Параметры.Вставить(ЛевоеЗначение, СтрокаЭлемент.ПравоеЗначение.Дата);
					Else
						ПостроительОтчета.Параметры.Вставить(ЛевоеЗначение, СтрокаЭлемент.ПравоеЗначение);
					EndIf;
				EndIf;

			EndDo;
			Прервать;
		EndIf;
	EndDo;
	Return ПостроительОтчета;

EndFunction

Function ПолучитьРезультатЗапросаСОграничениями(СтрокаДереваМетаданных, ТаблицаОтбора1)

	ПостроительОтчета = ПодготовитьПостроительДляВыгрузки(СтрокаДереваМетаданных, , , ТаблицаОтбора1);

	ПостроительОтчета.Выполнить();
	РезультатЗапроса = ПостроительОтчета.Результат;

	Return РезультатЗапроса;

EndFunction

Procedure WriteObjectTypeData(СтрокаДереваМетаданных, ЗаписьXML, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов = False, ТаблицаОтбора1)

	РезультатЗапроса = ПолучитьРезультатЗапросаСОграничениями(СтрокаДереваМетаданных, ТаблицаОтбора1);

	QueryAndWriter(РезультатЗапроса, ЗаписьXML, True, ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов);

EndProcedure

// Procedure исполняет переданный запрос и записывает полученные через запрос объекты
//
// Параметры
//   Запрос - запрос для исполнения, результат содержит выборку объектов для записи
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   ЗапросВерхнегоУровня - признак необходимости анимации процесса
//
Procedure QueryAndWriter(РезультатЗапроса, ЗаписьXML, ЗапросВерхнегоУровня = False, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов)
	
	// универсальная Procedure выгрузки ссылочных объектов Procedure
	ОбработкаРезультатаЗапроса(РезультатЗапроса, ЗаписьXML, True, ЗапросВерхнегоУровня, ОбъектыВыгруженныеСОшибками,
		ТолькоПроверкаНедопустимыхСимволов);

EndProcedure

Procedure ExecuteAuxiliaryActionsForXMLWriter(ВсегоОбработаноОбъектов, ЗаписьXML,
	ТолькоПроверкаНедопустимыхСимволов)

	If Не ТолькоПроверкаНедопустимыхСимволов Then
		Return;
	EndIf;

	If ВсегоОбработаноОбъектов > 1000 Then
		
		//@skip-warning
		СтрокаРезультата = ЗаписьXML.Закрыть();
		СтрокаРезультата = Undefined;
		ЗаписьXML = Undefined;

		ЗаписьXML = CreateXMLRecordObjectForCheck();

	EndIf;

EndProcedure

Function СсылкаВыгружена(Ссылка)

	Return mExportedObjects.Найти(Ссылка, "Ссылка") <> Undefined;

EndFunction

Procedure ДобавитьСсылкуКВыгруженным(Ссылка)

	СтрокаДобавления = mExportedObjects.Добавить();
	СтрокаДобавления.Ссылка = Ссылка;

EndProcedure

// Procedure записывает содержащиеся в выборке результата запроса объекты и необходимые "по ссылке" объекты ИБ
//
// Параметры
//   РезультатЗапроса - результат запроса
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   ЭтоЗапросПоОбъекту - If True, выборка должна содержать объекты, на которые может быть ссылка,
//             If False, выгружать, как объект не нужно, только обработать возможные ссылки на др. объекты ИБ
//
Procedure ОбработкаРезультатаЗапроса(РезультатЗапроса, ЗаписьXML, ЭтоЗапросПоОбъекту = False,
	ЗапросВерхнегоУровня = False, ОбъектыВыгруженныеСОшибками = Undefined, ТолькоПроверкаНедопустимыхСимволов = False)

	ВыборкаИзРезультатовЗапроса = РезультатЗапроса.Выбрать();

	ВсегоОбработаноОбъектов = 0;
//	ОбработаноОбъектов = 0;

	While ВыборкаИзРезультатовЗапроса.Следующий() Do

		If ЭтоЗапросПоОбъекту Then
			
			// выгрузка ссылочных объектов
			Ссылка = ВыборкаИзРезультатовЗапроса.Ссылка;
			If СсылкаВыгружена(Ссылка) Then

				Продолжить;

			EndIf;

			ДобавитьСсылкуКВыгруженным(Ссылка);

			ВсегоОбработаноОбъектов = TotalProcessedRecords();

		EndIf;

		If mChildObjectsExportExistence Then
		
			// перебираем колонки запроса в поисках ссылочных значений, которые, возможно, нужно выгрузить
			For Each КолонкаЗапроса Из РезультатЗапроса.Колонки Do

				ЗначениеКолонки = ВыборкаИзРезультатовЗапроса[КолонкаЗапроса.Имя];

				If TypeOf(ЗначениеКолонки) = mTypeQueryResult Then

					ОбработкаРезультатаЗапроса(ЗначениеКолонки, ЗаписьXML, , , ОбъектыВыгруженныеСОшибками,
						ТолькоПроверкаНедопустимыхСимволов);

				Else

					ЗаписатьЗначениеПриНеобходимости(ЗначениеКолонки, ЗаписьXML, ОбъектыВыгруженныеСОшибками,
						ТолькоПроверкаНедопустимыхСимволов);

				EndIf;

			EndDo;

		EndIf;

		If ЭтоЗапросПоОбъекту Then

			Объект = Ссылка.ПолучитьОбъект();

			Try

				ExecuteAuxiliaryActionsForXMLWriter(ВсегоОбработаноОбъектов, ЗаписьXML,
					ТолькоПроверкаНедопустимыхСимволов);

				Serializer.ЗаписатьXML(ЗаписьXML, Объект);

				MetadataОбъекта = Объект.Metadata();

				If ЭтоMetadataСПредопределеннымиЭлементами(MetadataОбъекта) И Объект.Предопределенный Then

					НоваяСтрока = PredefinedItemsTable.Добавить();
					НоваяСтрока.ИмяТаблицы = MetadataОбъекта.ПолноеИмя();
					НоваяСтрока.Ссылка = XMLСтрока(Ссылка);
					НоваяСтрока.ИмяПредопределенныхДанных = Объект.ИмяПредопределенныхДанных;

				EndIf;

				If ExportDocumentWithItsRecords И Metadata.Документы.Содержит(MetadataОбъекта) Then
					
					// выгрузка движений документа
					For Each Движение Из Объект.Движения Do

						Движение.Прочитать();

						If mChildObjectsExportExistence И Движение.Количество() > 0 Then

							ТипРегистра = Тип(Движение);

							ArrayКолонок = mRegisterRecordsColumnsMap.Получить(ТипРегистра);

							If ArrayКолонок = Undefined Then

								ТаблицаДвижений = Движение.Выгрузить();
								РегистрБухгалтерии = Metadata.РегистрыБухгалтерии.Содержит(Движение.Metadata());
								ArrayКолонок = ПолучитьArrayКолонокДвижения(ТаблицаДвижений, РегистрБухгалтерии);
								mRegisterRecordsColumnsMap.Вставить(ТипРегистра, ArrayКолонок);

							EndIf;

							ВыгрузитьПодчиненныеЗначенияНабора(ЗаписьXML, Движение, ArrayКолонок,
								ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов);

						EndIf;

						Serializer.ЗаписатьXML(ЗаписьXML, Движение);

					EndDo;

				EndIf;

			Except

				СтрокаОписанияОшибки = ErrorDescription();
				//не смогли записать в XML
				// возможно проблема с недопустимыми символами в XML
				If ТолькоПроверкаНедопустимыхСимволов Then

					If ОбъектыВыгруженныеСОшибками.Получить(Ссылка) = Undefined Then
						ОбъектыВыгруженныеСОшибками.Вставить(Ссылка, СтрокаОписанияОшибки);
					EndIf;

				Else

					ИтоговаяСтрокаСообщения = Нстр("ru = 'При выгрузке объекта %1(%2) возникла ошибка:
												   |%3'");
					ИтоговаяСтрокаСообщения = SubstituteParametersToString(ИтоговаяСтрокаСообщения, Объект, TypeOf(
						Объект), СтрокаОписанияОшибки);
					UserMessage(ИтоговаяСтрокаСообщения);

					Raise ИтоговаяСтрокаСообщения;

				EndIf;

			EndTry;

		EndIf;

	EndDo;

EndProcedure

Procedure ВыгрузитьПодчиненныеЗначенияНабора(ЗаписьXML, Движение, ArrayКолонок, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов)

	For Each ЗаписьИзНабора Из Движение Do

		For Each Колонка Из ArrayКолонок Do

			If Колонка = "СубконтоДт" Или Колонка = "СубконтоКт" Then

				Значение = ЗаписьИзНабора[Колонка];
				For Each КлючИЗначение Из Значение Do

					If ValueIsFilled(КлючИЗначение.Значение) Then
						ЗаписатьЗначениеПриНеобходимости(КлючИЗначение.Значение, ЗаписьXML,
							ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов);
					EndIf;

				EndDo;

			Else

				СохраненноеЗначение = ЗаписьИзНабора[Колонка];
				ЗаписатьЗначениеПриНеобходимости(СохраненноеЗначение, ЗаписьXML, ОбъектыВыгруженныеСОшибками,
					ТолькоПроверкаНедопустимыхСимволов);

			EndIf;

		EndDo;

	EndDo;

EndProcedure

Function ПолучитьArrayКолонокДвижения(ТаблицаДвижений, РегистрБухгалтерии = False)

	ArrayКолонок = New Array;
	For Each КолонкаТаблицы Из ТаблицаДвижений.Колонки Do

		If КолонкаТаблицы.Имя = "МоментВремени" Или Найти(КолонкаТаблицы.Имя, "ВидСубконтоДт") = 1 Или Найти(
			КолонкаТаблицы.Имя, "ВидСубконтоКт") = 1 Then

			Продолжить;

		EndIf;

		If Найти(КолонкаТаблицы.Имя, "СубконтоДт") = 1 И РегистрБухгалтерии Then

			If ArrayКолонок.Найти("СубконтоДт") = Undefined Then
				ArrayКолонок.Добавить("СубконтоДт");
			EndIf;

			Продолжить;

		EndIf;

		If Найти(КолонкаТаблицы.Имя, "СубконтоКт") = 1 И РегистрБухгалтерии Then

			If ArrayКолонок.Найти("СубконтоКт") = Undefined Then
				ArrayКолонок.Добавить("СубконтоКт");
			EndIf;

			Продолжить;

		EndIf;

		ArrayКолонок.Добавить(КолонкаТаблицы.Имя);

	EndDo;

	Return ArrayКолонок;

EndFunction

// Procedure анализирует необходимость записи объекта "по ссылке" и осуществляет запись
//
// Параметры
//   АнализируемоеЗначение - анализируемое значение
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//
Procedure ЗаписатьЗначениеПриНеобходимости(АнализируемоеЗначение, ЗаписьXML, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов)

	If Не ValueIsFilled(АнализируемоеЗначение) Then
		Return;
	EndIf;

	ОбъектМД = RefTypes.Получить(TypeOf(АнализируемоеЗначение));

	If ОбъектМД = Undefined Then
		Return; // это не ссылка
	EndIf;

	If СсылкаВыгружена(АнализируемоеЗначение) Then
		Return; // объект уже был выгружен
	EndIf;
	
	// Проверка того, что данный тип входит в список выгружаемых дополнительно
	СтрокаТаблицы = FullExportContent.Найти(ОбъектМД, "ОбъектМД");
	If СтрокаТаблицы <> Undefined Then
		Return;
	EndIf;

	СтрокаТаблицы = AuxiliaryExportContent.Найти(ОбъектМД, "ОбъектМД");
	If СтрокаТаблицы <> Undefined Then

		ДопЗапрос = New Запрос("ВЫБРАТЬ * ИЗ " + СтрокаТаблицы.СтрокаДерева.ЭлементОписания.ДляЗапроса + ОбъектМД.Имя
			+ " КАК ТаблицаОбъекта_" + " ГДЕ Ссылка = &Ссылка");
		ДопЗапрос.УстановитьПараметр("Ссылка", АнализируемоеЗначение);
		РезультатЗапроса = ДопЗапрос.Выполнить();
		QueryAndWriter(РезультатЗапроса, ЗаписьXML, , ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов);

	EndIf;

EndProcedure

// Procedure записывает значение константы
//
// Параметры
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   МД_Константа - описание метаданного - выгружаемой константы
//
Procedure WriteConstant(ЗаписьXML, МД_Константа, ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов,
	ТаблицаОтбора1)
	ТекстЗапроса= "ВЫБРАТЬ
				  |	АвтоматическиНастраиватьРазрешенияВПрофиляхБезопасности.Значение КАК Значение
				  |ИЗ
				  |	Константа.АвтоматическиНастраиватьРазрешенияВПрофиляхБезопасности КАК АвтоматическиНастраиватьРазрешенияВПрофиляхБезопасности
				  |";

	Первая=True;
	Найдено=False;

	For Each Строка Из ТаблицаОтбора1 Do
		If МД_Константа.ИМЯ = Строка.имяреквизита Then
			Найдено=True;
			For Each СтрокаЭлементы Из Строка.Отбор.Элементы Do
				If СтрокаЭлементы.Использование Then
					If Не Первая Then
						ТекстЗапроса = ТекстЗапроса + Символы.ПС + " И " + GetComparisonTypeForQueryКонстанта(Строка,
							СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
					Else
						ТекстЗапроса = ТекстЗапроса + Символы.ПС + " ГДЕ " + GetComparisonTypeForQueryКонстанта(
							Строка, СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
					EndIf;
					Первая=False;
				EndIf;
			EndDo;
			Прервать;
		EndIf;
	EndDo;
	Выгружать=False;
	If Не найдено Then
		МенеджерЗначения = Константы[МД_Константа.Имя].СоздатьМенеджерЗначения();
		МенеджерЗначения.Прочитать();
		ЗаписатьЗначениеПриНеобходимости(МенеджерЗначения.Значение, ЗаписьXML, ОбъектыВыгруженныеСОшибками,
			ТолькоПроверкаНедопустимыхСимволов);
		Выгружать=True;
	Else

		Запрос=New запрос;
		Запрос.Текст=Текстзапроса;

		For Each Строка Из ТаблицаОтбора1 Do
			If МД_Константа.ИМЯ = Строка.имяреквизита Then
				Найдено=True;
				For Each СтрокаЭлементы Из Строка.Отбор.Элементы Do
					If СтрокаЭлементы.Использование Then
						Запрос.УстановитьПараметр(Строка.имяреквизита, СтрокаЭлементы.ПравоеЗначение);
					EndIf;
				EndDo;
				Прервать;
			EndIf;
		EndDo;
		Выборка1=Запрос.Выполнить().Выбрать();

		While Выборка1.Следующий() Do
			МенеджерЗначения = Константы[МД_Константа.Имя].СоздатьМенеджерЗначения();
			МенеджерЗначения.Прочитать();
			If Выборка1.Значение = МенеджерЗначения.Значение Then
				ЗаписатьЗначениеПриНеобходимости(МенеджерЗначения.Значение, ЗаписьXML, ОбъектыВыгруженныеСОшибками,
					ТолькоПроверкаНедопустимыхСимволов);
				Выгружать=True;
			EndIf;
		EndDo;

	EndIf;	
	// собственно выгрузка

	ВсегоОбработаноОбъектов = TotalProcessedRecords();
	Try
		If Выгружать Then
			ExecuteAuxiliaryActionsForXMLWriter(ВсегоОбработаноОбъектов, ЗаписьXML,
				ТолькоПроверкаНедопустимыхСимволов);
			Serializer.ЗаписатьXML(ЗаписьXML, МенеджерЗначения);
		EndIf;
	Except
		СтрокаОписанияОшибки = ErrorDescription();
		//не смогли записать в XML
		// возможно проблема с недопустимыми символами в XML
		If ТолькоПроверкаНедопустимыхСимволов Then
			ОбъектыВыгруженныеСОшибками.Вставить(МенеджерЗначения, СтрокаОписанияОшибки);
		Else
			ИтоговаяСтрокаСообщения = Нстр("ru = 'При выгрузке константы %1 возникла ошибка:
										   |%2'");
			ИтоговаяСтрокаСообщения = SubstituteParametersToString(ИтоговаяСтрокаСообщения, МД_Константа.Имя,
				СтрокаОписанияОшибки);

			UserMessage(ИтоговаяСтрокаСообщения);
			Raise ИтоговаяСтрокаСообщения;
		EndIf;

	EndTry;

	ProcessedConstantsCount = ProcessedConstantsCount + 1;

EndProcedure

// Procedure записывает наборы записей регистра (накопления, бухгалтерии...)
//
// Параметры
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   СтрокаДереваМетаданных - строка дерева метаданных, соответствующая регистру
//
Procedure WriteRegister(ЗаписьXML, СтрокаДереваМетаданных, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов, РегистрБухгалтерии = False, ТаблицаОтбора1)

	МенеджерНабораЗаписей = СтрокаДереваМетаданных.ЭлементОписания.Менеджер[СтрокаДереваМетаданных.ОбъектМД.Имя];

	ИмяТаблицыДляЗапроса = СтрокаДереваМетаданных.ЭлементОписания.ДляЗапроса;

	ЗаписьЧерезНаборЗаписей(ЗаписьXML, МенеджерНабораЗаписей, ИмяТаблицыДляЗапроса,
		СтрокаДереваМетаданных.ОбъектМД.Имя, СтрокаДереваМетаданных, ОбъектыВыгруженныеСОшибками,
		ТолькоПроверкаНедопустимыхСимволов, РегистрБухгалтерии, ТаблицаОтбора1);

EndProcedure

// Procedure записывает наборы записей регистра (накопления, бухгалтерии...)
//
// Параметры
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   СтрокаДереваМетаданных - строка дерева метаданных, соответствующая регистру
//
Procedure WriteRecalculation(ЗаписьXML, СтрокаДереваМетаданных, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов, ТаблицаОтбора1)

	ИмяРегистраРасчета = СтрокаДереваМетаданных.Родитель.Родитель.ОбъектМД.Имя;
	МенеджерСтрокой = StrReplace(СтрокаДереваМетаданных.ЭлементОписания.Менеджер, "%i", ИмяРегистраРасчета);
	МенеджерПерерасчета = Вычислить(МенеджерСтрокой);
	МенеджерПерерасчета = МенеджерПерерасчета[СтрокаДереваМетаданных.ОбъектМД.Имя];
	СтрокаДляЗапроса = StrReplace(СтрокаДереваМетаданных.ЭлементОписания.ДляЗапроса, "%i", ИмяРегистраРасчета);

	ЗаписьЧерезНаборЗаписей(ЗаписьXML, МенеджерПерерасчета, СтрокаДляЗапроса, СтрокаДереваМетаданных.ОбъектМД.Имя,
		СтрокаДереваМетаданных, ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов, , ТаблицаОтбора1);

EndProcedure

// Procedure записывает последовательности документов
//
// Параметры
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   СтрокаДереваМетаданных - строка дерева метаданных, соответствующая регистру
//
Procedure WriteSequence(ЗаписьXML, СтрокаДереваМетаданных, ОбъектыВыгруженныеСОшибками,
	ТолькоПроверкаНедопустимыхСимволов, ТаблицаОтбора1)

	МенеджерНабораЗаписей = СтрокаДереваМетаданных.ЭлементОписания.Менеджер[СтрокаДереваМетаданных.ОбъектМД.Имя];

	ЗаписьЧерезНаборЗаписей(ЗаписьXML, МенеджерНабораЗаписей, СтрокаДереваМетаданных.ЭлементОписания.ДляЗапроса,
		СтрокаДереваМетаданных.ОбъектМД.Имя, СтрокаДереваМетаданных, ОбъектыВыгруженныеСОшибками,
		ТолькоПроверкаНедопустимыхСимволов, , ТаблицаОтбора1);

EndProcedure

// Procedure записывает данные, доступ к которым осуществляется через набор записей
//
// Параметры
//   ЗаписьXML - объект, через которых происходит запись объектов ИБ
//   СтрокаДереваМетаданных - строка дерева метаданных, соответствующая регистру
//
Procedure ЗаписьЧерезНаборЗаписей(ЗаписьXML, МенеджерНабораЗаписей, ДляЗапроса, ИмяОбъекта,
	СтрокаДереваМетаданных = Undefined, ОбъектыВыгруженныеСОшибками, ТолькоПроверкаНедопустимыхСимволов,
	РегистрБухгалтерии = False, ТаблицаОтбора1)
	
	// получить состав колонок записи регистра и проверить наличие хотя бы одной записи
	If ДляЗапроса = "РегистрБухгалтерии." Then
		ИмяТаблицыДляЗапроса = ДляЗапроса + ИмяОбъекта + ".ДвиженияССубконто";
	Else
		ИмяТаблицыДляЗапроса = ДляЗапроса + ИмяОбъекта;
	EndIf;

	Первая=True;
	Запрос= New Запрос;

	If ДляЗапроса = "РегистрБухгалтерии." Then

		УсловиеЗапроса="";
		//  ограничения
		For Each Строка Из ТаблицаОтбора1 Do
			If ИмяОбъекта = Строка.имяреквизита И СтрокаДереваМетаданных.ИмяОбъектаМетаданных
				= Строка.ИмяОбъектаМетаданных Then
				For Each СтрокаЭлементы Из Строка.Отбор.Элементы Do
					If СтрокаЭлементы.Использование Then

						If Строка(TypeOf(СтрокаЭлементы.ПравоеЗначение)) = "Стандартная дата начала" Then
							Запрос.УстановитьПараметр(Строка(СтрокаЭлементы.ЛевоеЗначение),
								СтрокаЭлементы.ПравоеЗначение.Дата);
						Else
							Запрос.УстановитьПараметр(Строка(СтрокаЭлементы.ЛевоеЗначение),
								СтрокаЭлементы.ПравоеЗначение);
						EndIf;

						If Не Первая Then
							УсловиеЗапроса = УсловиеЗапроса + Символы.ПС + " И " + GetComparisonTypeForQueryРегистр(
								Строка, СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
						Else
							УсловиеЗапроса = УсловиеЗапроса + Символы.ПС + " " + GetComparisonTypeForQueryРегистр(
								Строка, СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
						EndIf;
						Первая=False;
					EndIf;
				EndDo;
				Прервать;
			EndIf;
		EndDo;
		ТекстЗапроса="ВЫБРАТЬ РАЗРЕШЕННЫЕ ПЕРВЫЕ  1 * ИЗ " + ИмяТаблицыДляЗапроса + "(, , " + УсловиеЗапроса
			+ ", ,  )  КАК ТаблицаОбъекта_" + ИмяОбъекта;

	Else

		ТекстЗапроса = "ВЫБРАТЬ РАЗРЕШЕННЫЕ ПЕРВЫЕ  1 *   ИЗ " + ИмяТаблицыДляЗапроса + " КАК ТаблицаОбъекта_"
			+ ИмяОбъекта;

		For Each Строка Из ТаблицаОтбора1 Do
			If ИмяОбъекта = Строка.имяреквизита И СтрокаДереваМетаданных.ИмяОбъектаМетаданных
				= Строка.ИмяОбъектаМетаданных Then
				For Each СтрокаЭлементы Из Строка.Отбор.Элементы Do
					If СтрокаЭлементы.Использование Then

						If Строка(TypeOf(СтрокаЭлементы.ПравоеЗначение)) = "Стандартная дата начала" Then
							Запрос.УстановитьПараметр(Строка(СтрокаЭлементы.ЛевоеЗначение),
								СтрокаЭлементы.ПравоеЗначение.Дата);
						Else
							Запрос.УстановитьПараметр(Строка(СтрокаЭлементы.ЛевоеЗначение),
								СтрокаЭлементы.ПравоеЗначение);
						EndIf;

						If Не Первая Then
							ТекстЗапроса = ТекстЗапроса + Символы.ПС + " И " + GetComparisonTypeForQuery(Строка,
								СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
						Else
							ТекстЗапроса = ТекстЗапроса + Символы.ПС + " ГДЕ " + GetComparisonTypeForQuery(Строка,
								СтрокаЭлементы, СтрокаЭлементы.ВидСравнения);
						EndIf;
						Первая=False;
					EndIf;
				EndDo;
				Прервать;
			EndIf;
		EndDo;

	EndIf;
	Запрос.Текст=ТекстЗапроса;

	РезультатЗапросаПоСоставу = Запрос.Выполнить();
	If РезультатЗапросаПоСоставу.Пустой() Then
		Return;
	EndIf;

	ТаблицаДвижений = РезультатЗапросаПоСоставу.Выгрузить();
	ArrayКолонок = ПолучитьArrayКолонокДвижения(ТаблицаДвижений, РегистрБухгалтерии);
	
	// выгрузка регистров осуществляется через его набор записей
	НаборЗаписей = МенеджерНабораЗаписей.СоздатьНаборЗаписей();

	Отбор = НаборЗаписей.Отбор;
	СтрокаПолейОтбора = "";
	For Each ЭлементОтбора Из Отбор Do
		If Не IsBlankString(СтрокаПолейОтбора) Then
			СтрокаПолейОтбора = СтрокаПолейОтбора + ",";
		EndIf;
		СтрокаПолейОтбора =СтрокаПолейОтбора + "ТаблицаОбъекта_" + ИмяОбъекта + "." + ЭлементОтбора.Имя;
	EndDo;

	СтрокаПолейОтбора1 = "";
	For Each ЭлементОтбора Из Отбор Do
		If Не IsBlankString(СтрокаПолейОтбора1) Then
			СтрокаПолейОтбора1 = СтрокаПолейОтбора1 + ",";
		EndIf;
		СтрокаПолейОтбора1 =СтрокаПолейОтбора1 + "ТаблицаОбъекта_" + ИмяОбъекта + "1." + ЭлементОтбора.Имя;
	EndDo;

	ПостроительОтчета = ПодготовитьПостроительДляВыгрузки(СтрокаДереваМетаданных, СтрокаПолейОтбора, СтрокаПолейОтбора1,
		ТаблицаОтбора1);
	ПостроительОтчета.Выполнить();
	РезультатЗапросаПоЗначениямОтбора = ПостроительОтчета.Результат;
	ВыборкаИзРезультата = РезультатЗапросаПоЗначениямОтбора.Выбрать();

	КоличествоПолейОтбора = НаборЗаписей.Отбор.Количество();
	
	// читаем наборы записей с различным составом отбора и записываем их
	While ВыборкаИзРезультата.Следующий() Do
		
		// Отбор устанавливаем для регистров, у которых есть хотя бы один отбор (измерение)
		If КоличествоПолейОтбора <> 0 Then

			For Each Колонка Из РезультатЗапросаПоЗначениямОтбора.Колонки Do
				Отбор[Колонка.Имя].Значение = ВыборкаИзРезультата[Колонка.Имя];
				Отбор[Колонка.Имя].ВидСравнения = ВидСравнения.Равно;
				Отбор[Колонка.Имя].Использование = True;
			EndDo;

		EndIf;

		НаборЗаписей.Прочитать();

		If mChildObjectsExportExistence Then
		
			// проверяем все записанные в наборе значения на необходимость записи "по ссылке"
			ВыгрузитьПодчиненныеЗначенияНабора(ЗаписьXML, НаборЗаписей, ArrayКолонок, ОбъектыВыгруженныеСОшибками,
				ТолькоПроверкаНедопустимыхСимволов);

		EndIf;

		ВсегоОбработаноОбъектов = TotalProcessedRecords();
		Try

			ExecuteAuxiliaryActionsForXMLWriter(ВсегоОбработаноОбъектов, ЗаписьXML,
				ТолькоПроверкаНедопустимыхСимволов);

			Serializer.ЗаписатьXML(ЗаписьXML, НаборЗаписей);

		Except

			СтрокаОписанияОшибки = ErrorDescription();
			//не смогли записать в XML
			// возможно проблема с недопустимыми символами в XML
			If ТолькоПроверкаНедопустимыхСимволов Then

				НовыйНабор = МенеджерНабораЗаписей.СоздатьНаборЗаписей();

				For Each СтрокаОтбора Из НаборЗаписей.Отбор Do

					СтрокаОтбораФормы = НовыйНабор.Отбор.Найти(СтрокаОтбора.Имя);

					If СтрокаОтбораФормы = Undefined Then
						Продолжить;
					EndIf;

					СтрокаОтбораФормы.Использование = СтрокаОтбора.Использование;
					СтрокаОтбораФормы.ВидСравнения = СтрокаОтбора.ВидСравнения;
					СтрокаОтбораФормы.Значение = СтрокаОтбора.Значение;

				EndDo;

				ОбъектыВыгруженныеСОшибками.Вставить(НовыйНабор, СтрокаОписанияОшибки);

			Else

				ИтоговаяСтрокаСообщения = Нстр("ru = 'При выгрузке регистра %1%2 возникла ошибка:
											   |%3'");
				ИтоговаяСтрокаСообщения = SubstituteParametersToString(ИтоговаяСтрокаСообщения, ДляЗапроса, ИмяОбъекта,
					СтрокаОписанияОшибки);

				UserMessage(ИтоговаяСтрокаСообщения);

				Raise ИтоговаяСтрокаСообщения;

			EndIf;

		EndTry;

		ProcessedRecordSetsCount = ProcessedRecordSetsCount + 1;

	EndDo;

EndProcedure

// Procedure рекурсивно обрабатывает строку дерева метаданных, образуя списки полной и вспомогательной выгрузки
//
// Параметры
//   FullExportContent - список полной выгрузки
//   AuxiliaryExportContent - список вспомогательной выгрузки
//   СтрокаДЗ - обрабатываемая строка дерева метаданных
//
Procedure AddObjectsToExport(FullExportContent, AuxiliaryExportContent, СтрокаДЗ)

	If (СтрокаДЗ.ЭлементОписания <> Undefined) И СтрокаДЗ.ЭлементОписания.Выгружаемый Then

		СтрокаДобавления = Undefined;

		If СтрокаДЗ.Выгружать Then

			СтрокаДобавления = FullExportContent.Добавить();

		ElsIf СтрокаДЗ.ВыгружатьПриНеобходимости Then

			СтрокаДобавления = AuxiliaryExportContent.Добавить();

		EndIf;

		If СтрокаДобавления <> Undefined Then

			СтрокаДобавления.ОбъектМД = СтрокаДЗ.ОбъектМД;
			СтрокаДобавления.СтрокаДерева = СтрокаДЗ;

		EndIf;

	EndIf;

	For Each ПодчиненнаяСтрокаДЗ Из СтрокаДЗ.Строки Do
		AddObjectsToExport(FullExportContent, AuxiliaryExportContent, ПодчиненнаяСтрокаДЗ);
	EndDo;

EndProcedure

// Procedure заполняет строку дерева метаданных, попутно заполняя соответствие ссылочных типов объектам метаданных
//
// Параметры
//   ОбъектМД - описание объекта метаданных
//   ЭлементДЗ - заполняемая строка дерева метаданных
//   ЭлементОписания - описание класса, к которому принадлежит объект метаданных (свойства, подчиненные классы)
//
Procedure BuildObjectSubtree(ОбъектМД, ЭлементДЗ, ЭлементОписания)

	ЭлементДЗ.Metadata = ОбъектМД;
	ЭлементДЗ.ОбъектМД   = ОбъектМД;
	ЭлементДЗ.ПолноеИмяМетаданных = ОбъектМД.Имя;
	ЭлементДЗ.ИмяОбъектаМетаданных= ЭлементОписания.Класс;

	ЭлементДЗ.ЭлементОписания = ЭлементОписания;
	ЭлементДЗ.Выгружать = False;
	ЭлементДЗ.ВыгружатьПриНеобходимости = True;
	ЭлементДЗ.ИндексКартинки = ЭлементОписания.ИндексКартинки;
	//ЭлементДЗ.ИндексВДереве=НомерСтрокидерева;
	//НомерСтрокидерева=НомерСтрокидерева+1;

	If ЭлементОписания.Менеджер <> Undefined Then
		
		// заполнение соответствия ссылочных типов объектам метаданных
		If ОбъектОбразуетСсылочныйТип(ОбъектМД) Then
			RefTypes[TypeOf(ЭлементОписания.Менеджер[ОбъектМД.Имя].ПустаяСсылка())] = ОбъектМД;
		EndIf;

		If Metadata.РегистрыНакопления.Содержит(ОбъектМД) Или Metadata.РегистрыБухгалтерии.Содержит(ОбъектМД) Then

			RegistersUsingTotals.Добавить(ЭлементДЗ);

		EndIf;

	EndIf;		
		
	// подчиненные ветви
	For Each ПодчиненныйКласс Из ЭлементОписания.Строки Do

		If Не ПодчиненныйКласс.Выгружаемый Then
			Продолжить;
		EndIf;

		ВеткаКласса = ЭлементДЗ.Строки.Добавить();
		ВеткаКласса.Metadata = ПодчиненныйКласс.Класс;
		ВеткаКласса.Выгружать = False;
		ВеткаКласса.ВыгружатьПриНеобходимости = True;
		ВеткаКласса.ПолноеИмяМетаданных = ПодчиненныйКласс.Класс;
		ВеткаКласса.ИндексКартинки = ПодчиненныйКласс.ИндексКартинки;

		ПодчиненныеОбъектыДанногоКласса = ОбъектМД[ПодчиненныйКласс.Класс];

		For Each ПодчиненныйОбъектМД Из ПодчиненныеОбъектыДанногоКласса Do
			ПодчиненныйЭлементДЗ = ВеткаКласса.Строки.Добавить();
			BuildObjectSubtree(ПодчиненныйОбъектМД, ПодчиненныйЭлементДЗ, ПодчиненныйКласс);
		EndDo;

	EndDo;

EndProcedure

// Procedure удаляет из дерева метаданных строки, соответствующие метаданным, заведомо не попадающим в выгрузку
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных, подчиненные которой рассматриваются
//        с точки зрения удаления из списка потенциально выгружаемых
//
Procedure CollapseObjectSubtree(ЭлементДЗ)

	УдаляемыеВеткиКлассов = New Array;
	For Each ВеткаКласса Из ЭлементДЗ.Строки Do

		УдаляемыеПодчиненныеМД = New Array;

		For Each ПодчиненныйОбъектМД Из ВеткаКласса.Строки Do
			CollapseObjectSubtree(ПодчиненныйОбъектМД);
			If (ПодчиненныйОбъектМД.Строки.Количество()) = 0 И (Не ПодчиненныйОбъектМД.ЭлементОписания.Выгружаемый) Then

				УдаляемыеПодчиненныеМД.Добавить(ВеткаКласса.Строки.Индекс(ПодчиненныйОбъектМД));

			EndIf;

		EndDo;

		Для Сч = 1 По УдаляемыеПодчиненныеМД.Количество() Do
			ВеткаКласса.Строки.Удалить(УдаляемыеПодчиненныеМД[УдаляемыеПодчиненныеМД.Количество() - Сч]);
		EndDo;

		If ВеткаКласса.Строки.Количество() = 0 Then
			УдаляемыеВеткиКлассов.Добавить(ЭлементДЗ.Строки.Индекс(ВеткаКласса));
		EndIf;

	EndDo;

	Для Сч = 1 По УдаляемыеВеткиКлассов.Количество() Do
		ЭлементДЗ.Строки.Удалить(УдаляемыеВеткиКлассов[УдаляемыеВеткиКлассов.Количество() - Сч]);
	EndDo;

EndProcedure

// Procedure проставляет признак Выгрузка строкам дерева метаданных, подчиненных данной, вычисляет и 
//      выставляет признак выгрузки "по ссылке" другим объектам, ссылки на которые может или должен
//      содержать объект, соответствующий данной строке
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure УстановитьВыгружатьПодчиненным(ЭлементДЗ)
	For Each ПодчиненнаяСтрока Из ЭлементДЗ.Строки Do
		ПодчиненнаяСтрока.Выгружать = ЭлементДЗ.Выгружать;
		УстановитьВыгружатьПодчиненным(ПодчиненнаяСтрока);
	EndDo;
EndProcedure

// Procedure проставляет признак Выгрузка строке дерева метаданных на основании этого признака подчиненных строк,
// затем вызывает себя же для родителя, обеспечивая отработку до корня дерева
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure ОбновитьСостояниеВыгружать(ЭлементДЗ)
	If ЭлементДЗ = Undefined Then
		Return;
	EndIf;
	If (ЭлементДЗ.ЭлементОписания <> Undefined) И ЭлементДЗ.ЭлементОписания.Выгружаемый Then
		Return; // обновляем вверх или до корня, или до первого встретившегося выгружаемого
	EndIf;
	Состояние = Undefined;
	For Each ПодчиненныйЭлементДЗ Из ЭлементДЗ.Строки Do
		If Состояние = Undefined Then
			Состояние = ПодчиненныйЭлементДЗ.Выгружать;
		Else
			If Не Состояние = ПодчиненныйЭлементДЗ.Выгружать Then
				Состояние = 2;
				Прервать;
			EndIf;
		EndIf;
	EndDo;

	If Состояние <> Undefined Then
		ЭлементДЗ.Выгружать = Состояние;
		ОбновитьСостояниеВыгружать(ЭлементДЗ.Родитель);
	EndIf;
EndProcedure

// Procedure обрабатывает состояние признака Выгрузка, проставляя признаки Выгрузка и ВыгружатьПриНеобходимости
// связанным ветвям дерева
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure ОбработкаИзмененияСостоянияВыгружать(ЭлементДЗ) Export
	If ЭлементДЗ.Выгружать = 2 Then
		ЭлементДЗ.Выгружать = 0;
	EndIf;
	// Изменяем состояние "вниз"
	УстановитьВыгружатьПодчиненным(ЭлементДЗ);
	// Изменяем состояние "вверх"
	ОбновитьСостояниеВыгружать(ЭлементДЗ.Родитель);
EndProcedure

// Procedure проставляет признак Выгрузка строкам дерева метаданных, подчиненных данной, вычисляет и 
//      выставляет признак выгрузки "по ссылке" другим объектам, ссылки на которые может или должен
//      содержать объект, соответствующий данной строке
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure УстановитьВыгружатьПриНеобходимостиПодчиненным(ЭлементДЗ)

	For Each ПодчиненнаяСтрока Из ЭлементДЗ.Строки Do
		ПодчиненнаяСтрока.ВыгружатьПриНеобходимости = ЭлементДЗ.ВыгружатьПриНеобходимости;
		УстановитьВыгружатьПриНеобходимостиПодчиненным(ПодчиненнаяСтрока);
	EndDo;

EndProcedure

// Procedure проставляет признак Выгрузка строке дерева метаданных на основании этого признака подчиненных строк,
// затем вызывает себя же для родителя, обеспечивая отработку до корня дерева
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure ОбновитьСостояниеВыгружатьПриНеобходимости(ЭлементДЗ)

	If ЭлементДЗ = Undefined Then
		Return;
	EndIf;

	If (ЭлементДЗ.ЭлементОписания <> Undefined) И ЭлементДЗ.ЭлементОписания.Выгружаемый Then
		Return; // обновляем вверх или до корня, или до первого встретившегося выгружаемого
	EndIf;

	Состояние = Undefined;
	For Each ПодчиненныйЭлементДЗ Из ЭлементДЗ.Строки Do

		If Состояние = Undefined Then
			Состояние = ПодчиненныйЭлементДЗ.ВыгружатьПриНеобходимости;
		Else
			If Не Состояние = ПодчиненныйЭлементДЗ.ВыгружатьПриНеобходимости Then
				Состояние = 2;
				Прервать;
			EndIf;
		EndIf;

	EndDo;

	If Состояние <> Undefined Then
		ЭлементДЗ.ВыгружатьПриНеобходимости = Состояние;
		ОбновитьСостояниеВыгружатьПриНеобходимости(ЭлементДЗ.Родитель);
	EndIf;

EndProcedure

// Procedure обрабатывает состояние признака Выгрузка, проставляя признаки Выгрузка и ВыгружатьПриНеобходимости
// связанным ветвям дерева
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure ОбработкаИзмененияСостоянияВыгружатьПриНеобходимости(ЭлементДЗ) Export

	If ЭлементДЗ.ВыгружатьПриНеобходимости = 2 Then
		ЭлементДЗ.ВыгружатьПриНеобходимости = 0;
	EndIf;
	
	// Изменяем состояние "вниз"
	УстановитьВыгружатьПриНеобходимостиПодчиненным(ЭлементДЗ);
	// Изменяем состояние "вверх"
	ОбновитьСостояниеВыгружатьПриНеобходимости(ЭлементДЗ.Родитель);

EndProcedure

// Function определяет, являются ли объекты данного класса метаданных типизированными
//
// Параметры
//   Описание - Описание класса
// Return - True, If объекты данного класса метаданных типизированы, False в противном случае
//
Function КлассМДТипизированный(Описание)

	For Each Свойство Из Описание.Свойства Do
		If Свойство.Значение = "Тип" Then
			Return True;
		EndIf;
	EndDo;
	Return False;

EndFunction

// Function определяет, являются ли тип ссылочным
//
// Параметры
//   Тип - исследуемый тип
// Return - True, If тип ссылочный, False в противном случае
//
Function СсылочныйТип(Тип)

	MetadataТипа = RefTypes.Получить(Тип);
	Return MetadataТипа <> Undefined;

EndFunction

// Procedure добавляет в Array New элемент, If он является уникальным
//
// Параметры
//   Array - исследуемый тип
//   Элемент - добавляемый элемент
//
Procedure ДобавитьВArrayIfУникальный(Array, Элемент)

	If Array.Найти(Элемент) = Undefined Then
		Array.Добавить(Элемент);
	EndIf;

EndProcedure

// Function возвращает Array типов, которые могут иметь поля записи объекта метаданных, соответствующего строке дерева
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
// Return - Array потенциально используемых соответствующей записью типов
//
Function ПолучитьВсеТипы(ЭлементДЗ)

	ОбъектМД = ЭлементДЗ.ОбъектМД;
	If TypeOf(ОбъектМД) <> Тип("ОбъектМетаданных") И TypeOf(ОбъектМД) <> Тип("ОбъектМетаданныхКонфигурация") Then

		Raise (Нстр("ru = 'Внутренняя ошибка обработки выгрузки'"));

	EndIf;

	Return ПолучитьТипыИспользуемыеОМД(ОбъектМД, ЭлементДЗ.ЭлементОписания);

EndFunction

// Function возвращает Array типов, которые могут иметь поля записи объекта метаданных
//
// Параметры
//   ОбъектМД - описание метаданного
//   ЭлементОписания - описание класса объекта метаданного
// Return - Array потенциально используемых соответствующей записью типов
//
Function ПолучитьТипыИспользуемыеОМД(ОбъектМД, ЭлементОписания)

	ВсеТипы = New Array;

	For Each Свойство Из ЭлементОписания.Свойства Do

		ЗначениеСвойства = ОбъектМД[Свойство.Значение];
		If TypeOf(ЗначениеСвойства) = Тип("КоллекцияЗначенийСвойстваОбъектаМетаданных")
			И ЗначениеСвойства.Количество() > 0 Then

			For Each СтрокаКоллекции Из ЗначениеСвойства Do

				СсылочныйТипКлючИЗначение = MetadataObjectsAndRefTypesMap[СтрокаКоллекции];

				If СсылочныйТипКлючИЗначение <> Undefined Then

					ДобавитьВArrayIfУникальный(ВсеТипы, СсылочныйТипКлючИЗначение);

				EndIf;

			EndDo;

		ElsIf TypeOf(ЗначениеСвойства) = Тип("ОбъектМетаданных") Then

			For Each СсылочныйТипКлючИЗначение Из RefTypes Do

				If ЗначениеСвойства = СсылочныйТипКлючИЗначение.Значение Then
					ДобавитьВArrayIfУникальный(ВсеТипы, СсылочныйТипКлючИЗначение.Ключ);
				EndIf;

			EndDo;

		EndIf;

	EndDo;

	If КлассМДТипизированный(ЭлементОписания) Then

		ОписаниеТипа = ОбъектМД.Тип;
		For Each ОдинТип Из ОписаниеТипа.Типы() Do

			If СсылочныйТип(ОдинТип) Then
				ДобавитьВArrayIfУникальный(ВсеТипы, ОдинТип);
			EndIf;

		EndDo;

	Else

		If Metadata.РегистрыСведений.Содержит(ОбъектМД) Или Metadata.РегистрыНакопления.Содержит(ОбъектМД)
			Или Metadata.РегистрыБухгалтерии.Содержит(ОбъектМД) Или Metadata.РегистрыРасчета.Содержит(ОбъектМД) Then
			
			// какой-то из регистров, ищем в возможных регистраторах
			For Each ДокументМД Из Metadata.Документы Do

				If ДокументМД.Движения.Содержит(ОбъектМД) Then

					ДобавитьВArrayIfУникальный(ВсеТипы, TypeOf(Документы[ДокументМД.Имя].ПустаяСсылка()));

				EndIf;

			EndDo;

		EndIf;

	EndIf;

	For Each ПодчиненныйКласс Из ЭлементОписания.Строки Do

		For Each ПодчиненныйОбъектМД Из ОбъектМД[ПодчиненныйКласс.Класс] Do

			ТипыПодчиненного = ПолучитьТипыИспользуемыеОМД(ПодчиненныйОбъектМД, ПодчиненныйКласс);
			For Each ОдинТип Из ТипыПодчиненного Do
				ДобавитьВArrayIfУникальный(ВсеТипы, ОдинТип);
			EndDo;

		EndDo;

	EndDo;

	Return ВсеТипы;

EndFunction

// Function возвращает строку дерева метаданных, соответствующую переданному объекту метаданных
// Поиск осуществляется среди строк, подчиненных переданной
//
// Параметры
//   СтрокаДЗ - строка дерева метаданных, от которой осуществляется поиск
//   ОбъектМД - описание метаданного
// Return - строка дерева метаданных
//
Function ЭлементДЗПоОбъектуМДИСтроке(СтрокаДЗ, ОбъектМД)

	Return СтрокаДЗ.Строки.Найти(ОбъектМД, "ОбъектМД", True);

EndFunction

// Function возвращает строку дерева метаданных, соответствующую переданному объекту метаданных
// Поиск осуществляется по всему дереву метаданных
//
// Параметры
//   ОбъектМД - описание метаданного
// Return - строка дерева метаданных
//
Function ЭлементДЗПоОбъектуМД(ОбъектМД)
	For Each СтрокаДЗ Из MetadataTree.Строки Do
		ЭлементДЗ = ЭлементДЗПоОбъектуМДИСтроке(СтрокаДЗ, ОбъектМД);
		If ЭлементДЗ <> Undefined Then
			Return ЭлементДЗ;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// Procedure определяет, на какие объект может ссылаться запись, соответствующая объекту метаданных, отображаемому
// данной строкой дерева метаданных и проставляет им признак ВыгружатьПриНеобходимости
//
// Параметры
//   ЭлементДЗ - строка дерева метаданных
//
Procedure УстановкаСостоянияВыгружатьПриНеобходимости(ЭлементДЗ)

	ОбновитьСостояниеВыгружатьПриНеобходимости(ЭлементДЗ.Родитель);
	If ЭлементДЗ.Выгружать <> 1 И ЭлементДЗ.ВыгружатьПриНеобходимости <> 1 Then
		Return;
	EndIf;
	If ЭлементДЗ.ОбъектМД = Undefined Then
		Return;
	EndIf;

	ВсеТипы = ПолучитьВсеТипы(ЭлементДЗ);
	For Each СсылочныйТип Из ВсеТипы Do

		ТипИОбъект = RefTypes.Получить(СсылочныйТип);
		If ТипИОбъект = Undefined Then

			ТекстИсключения = Нстр("ru = 'Внутренняя ошибка. Неполное заполнение структуры ссылочных типов %1'");
			ТекстИсключения = SubstituteParametersToString(ТекстИсключения, СсылочныйТип);
			Raise (ТекстИсключения);

		EndIf;

		ОбъектМД = ТипИОбъект;
		СтрокаДЗ = ЭлементДЗПоОбъектуМД(ОбъектМД);
		If СтрокаДЗ = Undefined Then

			ТекстИсключения = Нстр(
				"ru = 'Внутренняя ошибка. Неполное заполнение дерева метаданных. Отсутствует объект, образующий тип %1'");
			ТекстИсключения = SubstituteParametersToString(ТекстИсключения, СсылочныйТип);
			Raise (ТекстИсключения);

		EndIf;

		If СтрокаДЗ.Выгружать = 1 Или СтрокаДЗ.ВыгружатьПриНеобходимости = 1 Then

			Продолжить;

		EndIf;

		СтрокаДЗ.ВыгружатьПриНеобходимости = 1;
		УстановкаСостоянияВыгружатьПриНеобходимости(СтрокаДЗ);

	EndDo;

EndProcedure

// Function определяет общее количество произведенных записей констант + объектного типа + наборов записей
//
// Return - общее количество произведенных записей
Function TotalProcessedRecords()

	Return mExportedObjects.Количество() + ProcessedConstantsCount + ProcessedRecordSetsCount;

EndFunction

// Procedure производит заполнение дерева описания классов объектов метаданных
//
// Параметры
//
Procedure FillMetadataDetails()

	СтэкДереваЗначенийСтроки = New Array;
	MetadataDetails = New ДеревоЗначений;
	MetadataDetails.Колонки.Добавить("Выгружаемый", New TypeDescription("Булево"));
	MetadataDetails.Колонки.Добавить("ДляЗапроса", New TypeDescription("Строка"));
	MetadataDetails.Колонки.Добавить("Класс", New TypeDescription("Строка", , New КвалификаторыСтроки(100,
		ДопустимаяДлина.Varенная)));
	MetadataDetails.Колонки.Добавить("Менеджер");
	MetadataDetails.Колонки.Добавить("Свойства", New TypeDescription("СписокЗначений"));
	MetadataDetails.Колонки.Добавить("ИндексКартинки");
	СтэкДереваЗначенийСтроки.Вставить(0, MetadataDetails.Строки);
	//////////////////////////////////
	// Конфигурации
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Конфигурации";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.ИндексКартинки = 0;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Константы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Константы";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = Константы;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.ИндексКартинки = 1;
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.Справочники
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Справочники";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = Справочники;
	ОписаниеКласса.ДляЗапроса  = "Справочник.";
	ОписаниеКласса.Свойства.Добавить("Владельцы");
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.ИндексКартинки = 3;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Справочники.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("Использование");
	//////////////////////////////////
	// Конфигурации.Справочники.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Использование");
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Справочники.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.Документы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Документы";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = Документы;
	ОписаниеКласса.ДляЗапроса  = "Документ.";
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.Свойства.Добавить("Движения");
	ОписаниеКласса.ИндексКартинки = 7;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Документы.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.Документы.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Документы.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.Последовательности
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Последовательности";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = Последовательности;
	ОписаниеКласса.ДляЗапроса  = "Последовательность.";
	ОписаниеКласса.Свойства.Добавить("Документы");
	ОписаниеКласса.Свойства.Добавить("Движения");
	ОписаниеКласса.ИндексКартинки = 5;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Последовательности.Измерения
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Измерения";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("СоответствиеДокументам");
	ОписаниеКласса.Свойства.Добавить("СоответствиеДвижениям");
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.ПланыВидовХарактеристик
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ПланыВидовХарактеристик";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = ПланыВидовХарактеристик;
	ОписаниеКласса.ДляЗапроса  = "ПланВидовХарактеристик.";
	ОписаниеКласса.Свойства.Добавить("ДополнительныеЗначенияХарактеристик");
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.ИндексКартинки = 9;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыВидовХарактеристик.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("Использование");
	//////////////////////////////////
	// Конфигурации.ПланыВидовХарактеристик.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Использование");
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыВидовХарактеристик.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.ПланыСчетов
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ПланыСчетов";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = ПланыСчетов;
	ОписаниеКласса.ДляЗапроса  = "ПланСчетов.";
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.Свойства.Добавить("ВидыСубконто");
	ОписаниеКласса.ИндексКартинки = 11;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыСчетов.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.ПланыСчетов.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыСчетов.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.ПланыВидовРасчета
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ПланыВидовРасчета";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = ПланыВидовРасчета;
	ОписаниеКласса.ДляЗапроса  = "ПланВидовРасчета.";
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.Свойства.Добавить("ЗависимостьОтВидовРасчета");
	ОписаниеКласса.Свойства.Добавить("БазовыеВидыРасчета");
	ОписаниеКласса.Свойства.Добавить("ИспользованиеПериодаДействия");
	ОписаниеКласса.ИндексКартинки = 13;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыВидовРасчета.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.ПланыВидовРасчета.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыВидовРасчета.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.РегистрыСведений
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "РегистрыСведений";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = РегистрыСведений;
	ОписаниеКласса.ДляЗапроса  = "РегистрСведений.";
	ОписаниеКласса.ИндексКартинки = 15;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.РегистрыСведений.Ресурсы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Ресурсы";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыСведений.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыСведений.Измерения
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Измерения";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.РегистрыНакопления
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "РегистрыНакопления";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = РегистрыНакопления;
	ОписаниеКласса.ДляЗапроса  = "РегистрНакопления.";
	ОписаниеКласса.ИндексКартинки = 17;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.РегистрыНакопления.Ресурсы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Ресурсы";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыНакопления.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыНакопления.Измерения
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Измерения";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.РегистрыБухгалтерии
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "РегистрыБухгалтерии";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = РегистрыБухгалтерии;
	ОписаниеКласса.ДляЗапроса  = "РегистрБухгалтерии.";
	ОписаниеКласса.Свойства.Добавить("ПланСчетов");
	ОписаниеКласса.Свойства.Добавить("Корреспонденция");
	ОписаниеКласса.ИндексКартинки = 19;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.РегистрыБухгалтерии.Измерения
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Измерения";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыБухгалтерии.Ресурсы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Ресурсы";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыБухгалтерии.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.РегистрыРасчета
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "РегистрыРасчета";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = РегистрыРасчета;
	ОписаниеКласса.ДляЗапроса  = "РегистрРасчета.";
	ОписаниеКласса.Свойства.Добавить("Периодичность");
	ОписаниеКласса.Свойства.Добавить("ПериодДействия");
	ОписаниеКласса.Свойства.Добавить("БазовыйПериод");
	ОписаниеКласса.Свойства.Добавить("График");
	ОписаниеКласса.Свойства.Добавить("ЗначениеГрафика");
	ОписаниеКласса.Свойства.Добавить("ДатаГрафика");
	ОписаниеКласса.Свойства.Добавить("ПланВидовРасчета");
	ОписаниеКласса.ИндексКартинки = 21;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.РегистрыРасчета.Ресурсы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Ресурсы";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.РегистрыРасчета.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("СвязьСГрафиком");
	//////////////////////////////////
	// Конфигурации.РегистрыРасчета.Измерения
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Измерения";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("БазовоеИзмерение");
	ОписаниеКласса.Свойства.Добавить("СвязьСГрафиком");
	//////////////////////////////////
	// Конфигурации.РегистрыРасчета.Перерасчеты
	//ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	//ОписаниеКласса.Класс = "Перерасчеты";
	//ОписаниеКласса.Выгружаемый = True;
	//ОписаниеКласса.Менеджер  = "РегистрыРасчета.%i.Перерасчеты";
	//ОписаниеКласса.ДляЗапроса  = "РегистрРасчета.%i.";
	//СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.РегистрыРасчета.Перерасчеты.Измерения
	//ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	//ОписаниеКласса.Класс = "Измерения";
	//ОписаниеКласса.Выгружаемый = False;
	//ОписаниеКласса.Свойства.Добавить("ДанныеВедущихРегистров");
	//ОписаниеКласса.Свойства.Добавить("ИзмерениеРегистра");
	//СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.БизнесПроцессы
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "БизнесПроцессы";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = БизнесПроцессы;
	ОписаниеКласса.ДляЗапроса  = "БизнесПроцесс.";
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.Свойства.Добавить("Задача");
	ОписаниеКласса.ИндексКартинки = 23;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.БизнесПроцессы.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.БизнесПроцессы.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.БизнесПроцессы.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	//////////////////////////////////
	// Конфигурации.Задачи
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Задачи";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = Задачи;
	ОписаниеКласса.ДляЗапроса  = "Задача.";
	ОписаниеКласса.Свойства.Добавить("Адресация");
	ОписаниеКласса.Свойства.Добавить("ОсновнойРеквизитАдресации");
	ОписаниеКласса.Свойства.Добавить("ТекущийИсполнитель");
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.ИндексКартинки = 25;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Задачи.РеквизитыАдресации
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "РеквизитыАдресации";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	ОписаниеКласса.Свойства.Добавить("ИзмерениеАдресации");
	//////////////////////////////////
	// Конфигурации.Задачи.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.Задачи.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.Задачи.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);
	
	//////////////////////////////////
	// Конфигурации.ПланыОбмена
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ПланыОбмена";
	ОписаниеКласса.Выгружаемый = True;
	ОписаниеКласса.Менеджер = ПланыОбмена;
	ОписаниеКласса.ДляЗапроса  = "ПланОбмена.";
	ОписаниеКласса.Свойства.Добавить("ВводитсяНаОсновании");
	ОписаниеКласса.ИндексКартинки = 27;
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыОбмена.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	//////////////////////////////////
	// Конфигурации.ПланыОбмена.ТабличныеЧасти
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "ТабличныеЧасти";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	СтэкДереваЗначенийСтроки.Вставить(0, ОписаниеКласса.Строки);
	//////////////////////////////////
	// Конфигурации.ПланыОбмена.ТабличныеЧасти.Реквизиты
	ОписаниеКласса = СтэкДереваЗначенийСтроки[0].Добавить();
	ОписаниеКласса.Класс = "Реквизиты";
	ОписаниеКласса.Выгружаемый = False;
	ОписаниеКласса.ДляЗапроса  = "";
	ОписаниеКласса.Свойства.Добавить("Тип");
	СтэкДереваЗначенийСтроки.Удалить(0);
	СтэкДереваЗначенийСтроки.Удалить(0);

	СтэкДереваЗначенийСтроки.Удалить(0);

EndProcedure

// Function определяет имеет ли переданный объект метаданных ссылочный тип
//
// Return - True, If переданный объект метаданных имеет ссылочный тип, False - противном случае
Function ОбъектОбразуетСсылочныйТип(ОбъектМД) Export

	If ОбъектМД = Undefined Then
		Return False;
	EndIf;

	If Metadata.Справочники.Содержит(ОбъектМД) Или Metadata.Документы.Содержит(ОбъектМД)
		Или Metadata.ПланыВидовХарактеристик.Содержит(ОбъектМД) Или Metadata.ПланыСчетов.Содержит(ОбъектМД)
		Или Metadata.ПланыВидовРасчета.Содержит(ОбъектМД) Или Metadata.ПланыОбмена.Содержит(ОбъектМД)
		Или Metadata.БизнесПроцессы.Содержит(ОбъектМД) Или Metadata.Задачи.Содержит(ОбъектМД) Then
		Return True;
	EndIf;

	Return False;
EndFunction

// Procedure определяет, какие типы объектов следует выгружать для сохранения ссылочной целостности
//
// Параметры
//   Выгрузка - Array строк - совокупность выгружаемых объектов
Procedure RecalculateDataToExportByRef(Выгрузка)
	
	// сброс всех флажков ВыгружатьПриНеобходимости
	СтрокаКонфигурации = MetadataTree.Строки[0];
	СтрокаКонфигурации.ВыгружатьПриНеобходимости = 0;
	ОбработкаИзмененияСостоянияВыгружатьПриНеобходимости(СтрокаКонфигурации);
	
	// обработка переданного набора объектов
	For Each Выгружаемый Из Выгрузка Do

		УстановкаСостоянияВыгружатьПриНеобходимости(Выгружаемый.СтрокаДерева);

	EndDo;

EndProcedure

// Procedure, при необходимости, устанавливает отсутствие необходимости использования итогов
//
// Параметры
Procedure RemoveTotalsUsage() Export

	If AllowResultsUsageEditingRights Then

		For Each Регистр_СДЗ Из RegistersUsingTotals Do

			Регистр_СДЗ.ЭлементОписания.Менеджер[Регистр_СДЗ.ОбъектМД.Имя].УстановитьИспользованиеИтогов(False);

		EndDo;

	EndIf;

EndProcedure

// Procedure, при необходимости, устанавливает необходимость использования итогов
//
// Параметры
Procedure RestoreTotalsUsage() Export

	If AllowResultsUsageEditingRights Then

		For Each Регистр_СДЗ Из RegistersUsingTotals Do

			Регистр_СДЗ.ЭлементОписания.Менеджер[Регистр_СДЗ.ОбъектМД.Имя].УстановитьИспользованиеИтогов(True);

		EndDo;

	EndIf;

EndProcedure

// Возвращает текущее значение версии обработки
//
// Параметры:
//  Нет.
// 
// Возвращаемое значение:
//  Текущее значение версии обработки
//
Function ВерсияОбъекта() Export

	Return "2.1.8";

EndFunction

Procedure UserMessage(Текст)

	Сообщение = New СообщениеПользователю;
	Сообщение.Текст = Текст;
	Сообщение.Сообщить();

EndProcedure

Procedure InitializePredefinedItemsTable()

	PredefinedItemsTable = New ТаблицаЗначений;
	PredefinedItemsTable.Колонки.Добавить("ИмяТаблицы");
	PredefinedItemsTable.Колонки.Добавить("Ссылка");
	PredefinedItemsTable.Колонки.Добавить("ИмяПредопределенныхДанных");

EndProcedure

Procedure ExportPredefinedItemsTable(ЗаписьXML)

	ЗаписьXML.ЗаписатьНачалоЭлемента("PredefinedData");

	If PredefinedItemsTable.Количество() > 0 Then

		PredefinedItemsTable.Сортировать("ИмяТаблицы");

		ИмяПредыдущейТаблицы = "";

		For Each Элемент Из PredefinedItemsTable Do

			If ИмяПредыдущейТаблицы <> Элемент.ИмяТаблицы Then
				If Не IsBlankString(ИмяПредыдущейТаблицы) Then
					ЗаписьXML.ЗаписатьКонецЭлемента();
				EndIf;
				ЗаписьXML.ЗаписатьНачалоЭлемента(Элемент.ИмяТаблицы);
			EndIf;

			ЗаписьXML.ЗаписатьНачалоЭлемента("item");
			ЗаписьXML.ЗаписатьАтрибут("Ссылка", Элемент.Ссылка);
			ЗаписьXML.ЗаписатьАтрибут("ИмяПредопределенныхДанных", Элемент.ИмяПредопределенныхДанных);
			ЗаписьXML.ЗаписатьКонецЭлемента();

			ИмяПредыдущейТаблицы = Элемент.ИмяТаблицы;

		EndDo;

		ЗаписьXML.ЗаписатьКонецЭлемента();

	EndIf;

	ЗаписьXML.ЗаписатьКонецЭлемента();

EndProcedure

Procedure ImportPredefinedItemsTable(ЧтениеXML)

	ЧтениеXML.Пропустить(); // При первом чтении пропускам основной блок данных
	ЧтениеXML.Прочитать();

	InitializePredefinedItemsTable();
	ВременнаяСтрока = PredefinedItemsTable.Добавить();

	RefsReplacementMap = New Соответствие;

	While ЧтениеXML.Прочитать() Do

		If ЧтениеXML.ТипУзла = ТипУзлаXML.НачалоЭлемента Then

			If ЧтениеXML.ЛокальноеИмя <> "item" Then

				ВременнаяСтрока.ИмяТаблицы = ЧтениеXML.ЛокальноеИмя;

				ТекстЗапроса = "ВЫБРАТЬ 
							   |	Таблица.Ссылка КАК Ссылка
							   |ИЗ
							   |	" + ВременнаяСтрока.ИмяТаблицы + " КАК Таблица
																	 |ГДЕ
																	 |	Таблица.ИмяПредопределенныхДанных = &ИмяПредопределенныхДанных";
				Запрос = New Запрос(ТекстЗапроса);

			Else

				While ЧтениеXML.ПрочитатьАтрибут() Do

					ВременнаяСтрока[ЧтениеXML.ЛокальноеИмя] = ЧтениеXML.Значение;

				EndDo;

				Запрос.УстановитьПараметр("ИмяПредопределенныхДанных", ВременнаяСтрока.ИмяПредопределенныхДанных);

				РезультатЗапроса = Запрос.Выполнить();
				If Не РезультатЗапроса.Пустой() Then

					Выборка = РезультатЗапроса.Выбрать();

					If Выборка.Количество() = 1 Then

						Выборка.Следующий();

						СсылкаВБазе = XMLСтрока(Выборка.Ссылка);
						СсылкаВФайле = ВременнаяСтрока.Ссылка;

						If ThisObject.PredefinedItemsImportMode = 1 Then

							ОбъектУдаляемый=Выборка.Ссылка.ПолучитьОбъект();
							ОбъектУдаляемый.Удалить();

						Else

							If СсылкаВБазе <> СсылкаВФайле Then

								XMLТип = XMLТипСсылки(Выборка.Ссылка);

								СоответствиеТипа = RefsReplacementMap.Получить(XMLТип);

								If СоответствиеТипа = Undefined Then

									СоответствиеТипа = New Соответствие;
									СоответствиеТипа.Вставить(СсылкаВФайле, СсылкаВБазе);
									RefsReplacementMap.Вставить(XMLТип, СоответствиеТипа);

								Else

									СоответствиеТипа.Вставить(СсылкаВФайле, СсылкаВБазе);

								EndIf;

							EndIf;

						EndIf;

					Else

						ТекстИсключения = НСтр(
							"ru = 'Обнаружено дублирование предопределенных элементов %1 в таблице %2!'");
						ТекстИсключения = StrReplace(ТекстИсключения, "%1", ВременнаяСтрока.ИмяПредопределенныхДанных);
						ТекстИсключения = StrReplace(ТекстИсключения, "%2", ВременнаяСтрока.ИмяТаблицы);

						Raise ТекстИсключения;

					EndIf;

				EndIf;

			EndIf;

		EndIf;

	EndDo;

	ЧтениеXML.Закрыть();

EndProcedure

Procedure ReplacePredefinedItemsRefs(ИмяФайла)

	ПотокЧтения = New ЧтениеТекста(ИмяФайла);

	ВременныйФайл = GetTempFileName("xml");

	ПотокЗаписи = New ЗаписьТекста(ВременныйФайл);
	
	// Константы для разбора текста
	НачалоТипа = "xsi:type=""v8:";
	ДлинаНачалаТипа = StrLen(НачалоТипа);
	КонецТипа = """>";
	ДлинаКонцаТипа = StrLen(КонецТипа);

	ИсходнаяСтрока = ПотокЧтения.ПрочитатьСтроку();
	While ИсходнаяСтрока <> Undefined Do

		ОстатокСтроки = Undefined;

		ТекущаяПозиция = 1;
		ПозицияТипа = Найти(ИсходнаяСтрока, НачалоТипа);
		While ПозицияТипа > 0 Do

			ПотокЗаписи.Записать(Сред(ИсходнаяСтрока, ТекущаяПозиция, ПозицияТипа - 1 + ДлинаНачалаТипа));

			ОстатокСтроки = Сред(ИсходнаяСтрока, ТекущаяПозиция + ПозицияТипа + ДлинаНачалаТипа - 1);
			ТекущаяПозиция = ТекущаяПозиция + ПозицияТипа + ДлинаНачалаТипа - 1;

			ПозицияКонцаТипа = Найти(ОстатокСтроки, КонецТипа);
			If ПозицияКонцаТипа = 0 Then
				Прервать;
			EndIf;

			ИмяТипа = Лев(ОстатокСтроки, ПозицияКонцаТипа - 1);
			СоответствиеЗамены = RefsReplacementMap.Получить(ИмяТипа);
			If СоответствиеЗамены = Undefined Then
				ПозицияТипа = Найти(ОстатокСтроки, НачалоТипа);
				Продолжить;
			EndIf;

			ПотокЗаписи.Записать(ИмяТипа);
			ПотокЗаписи.Записать(КонецТипа);

			ИсходнаяСсылкаXML = Сред(ОстатокСтроки, ПозицияКонцаТипа + ДлинаКонцаТипа, 36);

			НайденнаяСсылкаXML = СоответствиеЗамены.Получить(ИсходнаяСсылкаXML);

			If НайденнаяСсылкаXML = Undefined Then
				ПотокЗаписи.Записать(ИсходнаяСсылкаXML);
			Else
				ПотокЗаписи.Записать(НайденнаяСсылкаXML);
			EndIf;

			ТекущаяПозиция = ТекущаяПозиция + ПозицияКонцаТипа - 1 + ДлинаКонцаТипа + 36;
			ОстатокСтроки = Сред(ОстатокСтроки, ПозицияКонцаТипа + ДлинаКонцаТипа + 36);
			ПозицияТипа = Найти(ОстатокСтроки, НачалоТипа);

		EndDo;

		If ОстатокСтроки <> Undefined Then
			ПотокЗаписи.ЗаписатьСтроку(ОстатокСтроки);
		Else
			ПотокЗаписи.ЗаписатьСтроку(ИсходнаяСтрока);
		EndIf;

		ИсходнаяСтрока = ПотокЧтения.ПрочитатьСтроку();

	EndDo;

	ПотокЧтения.Закрыть();
	ПотокЗаписи.Закрыть();

	ИмяФайла = ВременныйФайл;

EndProcedure

Function ЭтоMetadataСПредопределеннымиЭлементами(ОбъектМетаданных)

	Return Metadata.Справочники.Содержит(ОбъектМетаданных) Или Metadata.ПланыСчетов.Содержит(ОбъектМетаданных)
		Или Metadata.ПланыВидовХарактеристик.Содержит(ОбъектМетаданных) Или Metadata.ПланыВидовРасчета.Содержит(
		ОбъектМетаданных);

EndFunction

// Возвращает SerializerXDTO с аннотацией типов.
//
// Возвращаемое значение:
//	SerializerXDTO - Serializer.
//
Procedure InitializeXDTOSerializerWithTypesAnnotation()

	ТипыСАннотациейСсылок = ПредопределенныеТипыПриВыгрузке();

	If ТипыСАннотациейСсылок.Количество() > 0 Then

		Фабрика = ПолучитьФабрикуСУказаниемТипов(ТипыСАннотациейСсылок);
		Serializer = New XDTOSerializer(Фабрика);

	Else

		Serializer = XDTOSerializer;

	EndIf;

EndProcedure

Function ПредопределенныеТипыПриВыгрузке()

	Типы = New Array;

	For Each ОбъектМетаданных Из Metadata.Справочники Do
		Типы.Добавить(ОбъектМетаданных);
	EndDo;

	For Each ОбъектМетаданных Из Metadata.ПланыСчетов Do
		Типы.Добавить(ОбъектМетаданных);
	EndDo;

	For Each ОбъектМетаданных Из Metadata.ПланыВидовХарактеристик Do
		Типы.Добавить(ОбъектМетаданных);
	EndDo;

	For Each ОбъектМетаданных Из Metadata.ПланыВидовРасчета Do
		Типы.Добавить(ОбъектМетаданных);
	EndDo;

	Return Типы;

EndFunction

// Возвращает фабрику с указанием типов.
//
// Параметры:
//	Типы - ФиксированныйArray (Metadata) - Array типов.
//
// Возвращаемое значение:
//	ФабрикаXDTO - фабрика.
//
Function ПолучитьФабрикуСУказаниемТипов(Знач Типы)

	НаборСхем = ФабрикаXDTO.ExportСхемыXML("http://v8.1c.ru/8.1/data/enterprise/current-config");
	Схема = НаборСхем[0];
	Схема.ОбновитьЭлементDOM();

	УказанныеТипы = New Соответствие;
	For Each Тип Из Типы Do
		УказанныеТипы.Вставить(XMLТипСсылки(Тип), True);
	EndDo;

	ПространствоИмен = New Соответствие;
	ПространствоИмен.Вставить("xs", "http://www.w3.org/2001/XMLSchema");
	РазыменовательПространствИменDOM = New РазыменовательПространствИменDOM(ПространствоИмен);
	ТекстXPath = "/xs:schema/xs:complexType/xs:sequence/xs:element[starts-with(@type,'tns:')]";

	Запрос = Схема.ДокументDOM.СоздатьВыражениеXPath(ТекстXPath, РазыменовательПространствИменDOM);
	Результат = Запрос.Вычислить(Схема.ДокументDOM);

	While True Do

		УзелПоля = Результат.ПолучитьСледующий();
		If УзелПоля = Undefined Then
			Прервать;
		EndIf;
		АтрибутТип = УзелПоля.Атрибуты.ПолучитьИменованныйЭлемент("type");
		ТипБезNSПрефикса = Сред(АтрибутТип.ТекстовоеСодержимое, StrLen("tns:") + 1);

		If УказанныеТипы.Получить(ТипБезNSПрефикса) = Undefined Then
			Продолжить;
		EndIf;

		УзелПоля.УстановитьАтрибут("nillable", "true");
		УзелПоля.УдалитьАтрибут("type");
	EndDo;

	ЗаписьXML = New ЗаписьXML;
	ИмяФайлаСхемы = GetTempFileName("xsd");
	ЗаписьXML.ОткрытьФайл(ИмяФайлаСхемы);
	ЗаписьDOM = New ЗаписьDOM;
	ЗаписьDOM.Записать(Схема.ДокументDOM, ЗаписьXML);
	ЗаписьXML.Закрыть();

	Фабрика = СоздатьФабрикуXDTO(ИмяФайлаСхемы);

	Try
		УдалитьФайлы(ИмяФайлаСхемы);
	Except
	EndTry;

	Return Фабрика;

EndFunction

// Возвращает имя типа, который будет использован в xml файле для указанного объекта метаданных
// Используется при поиске и замене ссылок при загрузке, при модификации схемы current-config при записи
// 
// Параметры:
//  Значение - Объект метаданных или Ссылка
//
// Возвращаемое значение:
//  Строка - Строка вида AccountingRegisterRecordSet.Хозрасчетный, описывающая объект метаданных 
//
Function XMLТипСсылки(Знач Значение)

	If TypeOf(Значение) = Тип("ОбъектМетаданных") Then
		ОбъектМетаданных = Значение;
		МенеджерОбъекта = ObjectManagerByFullName(ОбъектМетаданных.ПолноеИмя());
		Ссылка = МенеджерОбъекта.ПолучитьСсылку();
	Else
		ОбъектМетаданных = Значение.Metadata();
		Ссылка = Значение;
	EndIf;

	If ОбъектОбразуетСсылочныйТип(ОбъектМетаданных) Then

		Return XDTOSerializer.XMLTypeOf(Ссылка).ИмяТипа;

	Else

		ТекстИсключения = НСтр(
			"ru = 'Ошибка при определении XMLТипа ссылки для объекта %1: объект не является ссылочным!'");
		ТекстИсключения = StrReplace(ТекстИсключения, "%1", ОбъектМетаданных.ПолноеИмя());

		Raise ТекстИсключения;

	EndIf;

EndFunction

// Возвращает менеджер объекта по полному имени объекта метаданных.
// Ограничение: не обрабатываются точки маршрутов бизнес-процессов.
//
// Параметры:
//  ПолноеИмя - Строка - полное имя объекта метаданных. Пример: "Справочник.Организации".
//
// Возвращаемое значение:
//  СправочникМенеджер, ДокументМенеджер.
// 
Function ObjectManagerByFullName(ПолноеИмя)

	ЧастиИмени = РазложитьСтрокуВArrayПодстрок(ПолноеИмя);

	If ЧастиИмени.Количество() >= 2 Then
		КлассОМ = ЧастиИмени[0];
		ИмяОМ = ЧастиИмени[1];
	EndIf;

	If ВРег(КлассОМ) = "СПРАВОЧНИК" Then
		Менеджер = Справочники;
	ElsIf ВРег(КлассОМ) = "ПЛАНВИДОВХАРАКТЕРИСТИК" Then
		Менеджер = ПланыВидовХарактеристик;
	ElsIf ВРег(КлассОМ) = "ПЛАНСЧЕТОВ" Then
		Менеджер = ПланыСчетов;
	ElsIf ВРег(КлассОМ) = "ПЛАНВИДОВРАСЧЕТА" Then
		Менеджер = ПланыВидовРасчета;
	EndIf;

	Return Менеджер[ИмяОМ];

EndFunction

Function РазложитьСтрокуВArrayПодстрок(Знач Стр, Разделитель = ".")

	ArrayСтрок = New Array;
	ДлинаРазделителя = StrLen(Разделитель);
	While True Do
		Поз = Найти(Стр, Разделитель);
		If Поз = 0 Then
			If (СокрЛП(Стр) <> "") Then
				ArrayСтрок.Добавить(Стр);
			EndIf;
			Return ArrayСтрок;
		EndIf;
		ArrayСтрок.Добавить(Лев(Стр, Поз - 1));
		Стр = Сред(Стр, Поз + ДлинаРазделителя);
	EndDo;

EndFunction

// Подставляет параметры в строку. Максимально возможное число параметров - 9.
// Параметры в строке задаются как %<номер параметра>. Нумерация параметров начинается с единицы.
//
// Параметры:
//  СтрокаПодстановки  - Строка - шаблон строки с параметрами (вхождениями вида "%ИмяПараметра");
//  Параметр<n>        - Строка - подставляемый параметр.
//
// Возвращаемое значение:
//  Строка   - текстовая строка с подставленными параметрами.
//
// Пример:
//  SubstituteParametersToString(НСтр("ru='%1 пошел в %2'"), "Вася", "Зоопарк") = "Вася пошел в Зоопарк".
//
Function SubstituteParametersToString(Знач СтрокаПодстановки, Знач Параметр1, Знач Параметр2 = Undefined,
	Знач Параметр3 = Undefined, Знач Параметр4 = Undefined, Знач Параметр5 = Undefined,
	Знач Параметр6 = Undefined, Знач Параметр7 = Undefined, Знач Параметр8 = Undefined,
	Знач Параметр9 = Undefined) Export

	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%1", Параметр1);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%2", Параметр2);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%3", Параметр3);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%4", Параметр4);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%5", Параметр5);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%6", Параметр6);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%7", Параметр7);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%8", Параметр8);
	СтрокаПодстановки = StrReplace(СтрокаПодстановки, "%9", Параметр9);

	Return СтрокаПодстановки;

EndFunction

UseDataExchangeModeOnImport = True;
ContinueImportOnError = False;
UseFilterByDateForAllObjects = True;
mChildObjectsExportExistence = False;
//mSavedLastExportsCount = 50;

mTypeQueryResult = Тип("РезультатЗапроса");
mDeletionDataType = Тип("УдалениеОбъекта");

mRegisterRecordsColumnsMap = New Соответствие;
ProcessedConstantsCount = 0;
ProcessedRecordSetsCount = 0;
