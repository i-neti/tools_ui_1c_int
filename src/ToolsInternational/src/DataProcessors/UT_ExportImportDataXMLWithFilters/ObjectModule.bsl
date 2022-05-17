
Var MetadataDetails Export;
Var RefTypes Export;
Var MetadataObjectsAndRefTypesMap;
Var ProcessedConstantsCount Export;
Var ProcessedRecordSetsCount Export;
Var mRegisterRecordsColumnsMap;

// array of metadata tree rows with ExportData attribute
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
	MetadataTree.Columns.Add("BuilderSettings");
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

// Internal
//
Function GetQueryTextByRow(MetadataTreeRow, AdditionalFilters, FieldsForSelectionString = "",
	FieldsForSelectionString1 = "", FilterTable1) Export

	MetadataObject  = MetadataTreeRow.Metadata;
	MetadataName     = MetadataObject.FullName();

	If Metadata.InformationRegisters.Contains(MetadataObject) Then

		QueryText = GetQueryTextForInformationRegister(MetadataName, MetadataObject, AdditionalFilters,
			FieldsForSelectionString, FieldsForSelectionString1, FilterTable1);
		Return QueryText;

	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Or Metadata.AccountingRegisters.Contains(
		MetadataObject) Then

		QueryText = GetQueryTextForRegister(MetadataName, MetadataObject, AdditionalFilters,
			FieldsForSelectionString, FilterTable1);
		Return QueryText;

	EndIf;

	RestrictionByDateExists = (ValueIsFilled(StartDate) Or ValueIsFilled(EndDate))
		And UseFilterByDateForAllObjects;

	If Not ValueIsFilled(FieldsForSelectionString) Then
		FieldsForSelectionString = "ObjectTable_" + MetadataTreeRow.MetadataFullName + ".*";
	EndIf;

	QueryText = "SELECT Allowed " + FieldsForSelectionString + " FROM " + MetadataName + " AS ObjectTable_"
		+ MetadataTreeRow.MetadataFullName;
	
	// Setting of a restriction by dates might be required.
	First=True;

	If RestrictionByDateExists Then

		If AdditionalFilters And Not UseFilterByDateForAllObjects Then

			Return QueryText;

		EndIf;

		AdditionalRestrictionByDate = "";
		
		// Checking of possibility to apply restrictions by dates for the metadata object.
		If Metadata.Documents.Contains(MetadataObject) Then

			AdditionalRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Document");
			First=False;

		ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Or Metadata.AccumulationRegisters.Contains(
			MetadataObject) Then

			AdditionalRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Register");
			First=False;

		EndIf;

		QueryText = QueryText + Chars.LF + AdditionalRestrictionByDate;
	EndIf;

	For Each Row In FilterTable1 Do
		If MetadataTreeRow.MetadataFullName = Row.AttributeName
			And MetadataTreeRow.Parent.Metadata = Row.MetadataObjectName Then
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
Function GetComparisonTypeForQuery(Row, ItemsRow, ComparisonType)
	
	//Row.AttributeName+GetComparisonTypeForQuery(ItemsRow.ComparisonType)+"&"+String(ItemsRow.LeftValue)+ Chars.LF

	LeftValue=StrReplace(String(ItemsRow.LeftValue), ".", "_");

	If ComparisonType = DataCompositionComparisonType.Greater Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + ">&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + ">=&" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InHierarchy Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " IN HIERARCHY(&"
			+ LeftValue + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InList Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " IN (&"
			+ LeftValue + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " IN HIERARCHY(&"
			+ LeftValue + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Less Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + "<&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.LessOrEqual Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + "<=&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
		ReturnValue=" NOT " + "ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue
			+ " IN HIERARCHY(&" + LeftValue + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.НеВСписке Then
		ReturnValue=" NOT " + "ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " IN (&"
			+ LeftValue + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
		ReturnValue=" NOT " + "ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue
			+ " IN HIERARCHY(&" + LeftValue + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotEqual Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + "<>&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotContains Then
		ReturnValue=" NOT " + "ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue
			+ " LIKE &" + LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Like Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " LIKE &"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotLike Then
		ReturnValue=" NOT " + "ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue
			+ " LIKE &" + LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Equal Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + "=&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Contains Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " LIKE &"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.BeginsWith Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + ">=&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + "<&"
			+ LeftValue + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Filled Then
		ReturnValue="ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue + " IS NULL "
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotFilled Then
		ReturnValue=" NOT " + "ObjectTable_" + Row.AttributeName + "." + ItemsRow.LeftValue
			+ " IS NULL " + Chars.LF;
	EndIf;

	Return ReturnValue;

EndFunction

Function GetComparisonTypeForQueryConstant(Row, ItemsRow, ComparisonType)
	
	//Row.AttributeName+GetComparisonTypeForQuery(ItemsRow.ComparisonType)+"&"+String(ItemsRow.LeftValue)+ Chars.LF
	If ComparisonType = DataCompositionComparisonType.Greater Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + ">&" + String(ItemsRow.LeftValue)
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + ">=&" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InHierarchy Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " IN HIERARCHY(&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InList Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " IN (&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " IN HIERARCHY(&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Less Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + "<&" + String(ItemsRow.LeftValue)
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.LessOrEqual Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + "<=&" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + ".Value" + " IN HIERARCHY(&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInList Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + ".Value"" IN (&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + ".Value" + " IN HIERARCHY(&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotEqual Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + "<>&" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.НеСодержит Then
		ReturnValue=" НЕ " + String(ItemsRow.LeftValue) + ".Value" + " LIKE &" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Like Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " LIKE &" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotLike Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " LIKE &" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Equal Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + "=&" + String(ItemsRow.LeftValue)
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Contains Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " LIKE &" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.BeginsWith Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + ">=&" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + "<&" + String(ItemsRow.LeftValue)
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Filled Then
		ReturnValue=String(ItemsRow.LeftValue) + ".Value" + " IS NULL " + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotFilled Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + ".Value" + " IS NULL " + Chars.LF;
	EndIf;

	Return ReturnValue;

EndFunction

Function GetComparisonTypeForQueryRegister(Row, ItemsRow, ComparisonType)
	
	//Row.AttributeName+GetComparisonTypeForQuery(ItemsRow.ComparisonType)+"&"+String(ItemsRow.LeftValue)+ Chars.LF
	If ComparisonType = DataCompositionComparisonType.Greater Then
		ReturnValue=String(ItemsRow.LeftValue) + ">&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
		ReturnValue=String(ItemsRow.LeftValue) + ">=&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InHierarchy Then
		ReturnValue=String(ItemsRow.LeftValue) + " IN HIERARCHY(&" + String(ItemsRow.LeftValue)
			+ ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InList Then
		ReturnValue=String(ItemsRow.LeftValue) + " IN (&" + String(ItemsRow.LeftValue) + ")"
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
		ReturnValue=String(ItemsRow.LeftValue) + " IN HIERARCHY(&" + String(ItemsRow.LeftValue)
			+ ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Less Then
		ReturnValue=String(ItemsRow.LeftValue) + "<&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.LessOrEqual Then
		ReturnValue=String(ItemsRow.LeftValue) + "<=&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInHierarchy Then
		ReturnValue=" NOT " + ItemsRow.LeftValue + " IN HIERARCHY(&" + String(ItemsRow.LeftValue)
			+ ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInList Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + " IN (&" + String(ItemsRow.LeftValue)
			+ ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + " IN HIERARCHY(&" + String(
			ItemsRow.LeftValue) + ")" + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotEqual Then
		ReturnValue=String(ItemsRow.LeftValue) + "<>&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotContains Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + " LIKE &" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Like Then
		ReturnValue=String(ItemsRow.LeftValue) + " LIKE &" + String(ItemsRow.LeftValue)
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotLike Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + " LIKE &" + String(
			ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Equal Then
		ReturnValue=String(ItemsRow.LeftValue) + "=&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Contains Then
		ReturnValue=String(ItemsRow.LeftValue) + " LIKE &" + String(ItemsRow.LeftValue)
			+ Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.BeginsWith Then
		ReturnValue=String(ItemsRow.LeftValue) + ">=&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotBeginsWith Then
		ReturnValue=String(ItemsRow.LeftValue) + "<&" + String(ItemsRow.LeftValue) + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.Filled Then
		ReturnValue=String(ItemsRow.LeftValue) + " IS NULL " + Chars.LF;
	ElsIf ComparisonType = DataCompositionComparisonType.NotFilled Then
		ReturnValue=" NOT " + String(ItemsRow.LeftValue) + " IS NULL " + Chars.LF;
	EndIf;

	Return ReturnValue;

EndFunction



// Internal
//
Function PrepareBuilderForExport(MetadataTreeRow, FieldsForSelectionString = "",
	FieldsForSelectionString1 = "", FilterTable1) Export

	AdditionalFilters = (MetadataTreeRow.BuilderSettings <> Undefined);

	FinalQueryText = GetQueryTextByRow(MetadataTreeRow, AdditionalFilters, FieldsForSelectionString,
		FieldsForSelectionString1, FilterTable1);

	ReportBuilder = New ReportBuilder;

	ReportBuilder.Text = FinalQueryText;

	ReportBuilder.FillSettings();

	ReportBuilder.Filter.Reset();
	If AdditionalFilters Then

		ReportBuilder.SetSettings(MetadataTreeRow.BuilderSettings);

	EndIf;

	ReportBuilder.Parameters.Insert("StartDate", StartDate);
	ReportBuilder.Parameters.Insert("EndDate", EndDate);

	For Each TableRow In FilterTable1 Do
		If MetadataTreeRow.Metadata.Name = TableRow.AttributeName And TableRow.MetadataObjectName
			= MetadataTreeRow.Parent.Metadata Then
			For Each ItemRow In TableRow.Filter.Items Do

				LeftValue=StrReplace(String(ItemRow.LeftValue), ".", "_");

				If ItemRow.ComparisonType = DataCompositionComparisonType.Contains Or ItemRow.ComparisonType
					= DataCompositionComparisonType.NotContains Then
					ReportBuilder.Parameters.Insert(LeftValue, "%" + ItemRow.RightValue + "%");
				Else
					If String(TypeOf(ItemRow.RightValue)) = NStr("ru = 'Стандартная дата начала'; en = 'Standard beginning date'") Then
						ReportBuilder.Parameters.Insert(LeftValue, ItemRow.RightValue.Date);
					Else
						ReportBuilder.Parameters.Insert(LeftValue, ItemRow.RightValue);
					EndIf;
				EndIf;

			EndDo;
			Break;
		EndIf;
	EndDo;
	Return ReportBuilder;

EndFunction

Function GetQueryResultWithRestrictions(MetadataTreeRow, FilterTable1)

	ReportBuilder = PrepareBuilderForExport(MetadataTreeRow, , , FilterTable1);

	ReportBuilder.Execute();
	QueryResult = ReportBuilder.Result;

	Return QueryResult;

EndFunction

Procedure WriteObjectTypeData(MetadataTreeRow, XMLWriter, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly = False, FilterTable1)

	QueryResult = GetQueryResultWithRestrictions(MetadataTreeRow, FilterTable1);

	QueryAndWriter(QueryResult, XMLWriter, True, ObjectsExportedWithErrors, InvalidCharsCheckOnly);

EndProcedure

// Executes the passed query and writes the objects received using the query.
//
// Parameters:
//   QueryResult - a result of executed query, contains a selection of objects for write.
//   XMLWriter - an object used to write infobase objects.
//   UpperLevelQuery - indicates whether process animation is required.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//
Procedure QueryAndWriter(QueryResult, XMLWriter, UpperLevelQuery = False, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly)
	
	// Universal procedure of exporting reference objects.
	QueryResultProcessing(QueryResult, XMLWriter, True, UpperLevelQuery, ObjectsExportedWithErrors,
		InvalidCharsCheckOnly);

EndProcedure

Procedure ExecuteAuxiliaryActionsForXMLWriter(TotalObjectsProcessed, XMLWriter,
	InvalidCharsCheckOnly)

	If Not InvalidCharsCheckOnly Then
		Return;
	EndIf;

	If TotalObjectsProcessed > 1000 Then
		
		//@skip-warning
		ResultString = XMLWriter.Close();
		ResultString = Undefined;
		XMLWriter = Undefined;

		XMLWriter = CreateXMLRecordObjectForCheck();

	EndIf;

EndProcedure

Function RefIsExported(Ref)

	Return mExportedObjects.Find(Ref, "Ref") <> Undefined;

EndFunction

Procedure AddRefInExportedTable(Ref)

	AddingRow = mExportedObjects.Add();
	AddingRow.Ref = Ref;

EndProcedure

// Writes an object contained in the query result selection and infobase objects required "by reference".
//
// Parameters:
//   QueryResult - a query result.
//   XMLWriter - an object used to write infobase objects.
//   IsQueryByObject - if True, selection must contain objects with references to them, if False, it 
//             is not necessary to export it as an object, just process possible references to other infobase objects.
//   UpperLevelQuery - indicates whether process animation is required.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//
Procedure QueryResultProcessing(QueryResult, XMLWriter, IsQueryByObject = False,
	UpperLevelQuery = False, ObjectsExportedWithErrors = Undefined, InvalidCharsCheckOnly = False)

	QueryResultsSelection = QueryResult.Select();

	TotalObjectsProcessed = 0;
//	ProcessedObjectsCount = 0;

	While QueryResultsSelection.Next() Do

		If IsQueryByObject Then
			
			// Reference objects export.
			Ref = QueryResultsSelection.Ref;
			If RefIsExported(Ref) Then

				Continue;

			EndIf;

			AddRefInExportedTable(Ref);

			TotalObjectsProcessed = TotalProcessedRecords();

		EndIf;

		If mChildObjectsExportExistence Then
		
			// Search for reference values in the query columns.
			For Each QueryColumn In QueryResult.Columns Do

				ColumnValue = QueryResultsSelection[QueryColumn.Имя];

				If TypeOf(ColumnValue) = mTypeQueryResult Then

					QueryResultProcessing(ColumnValue, XMLWriter, , , ObjectsExportedWithErrors,
						InvalidCharsCheckOnly);

				Else

					WriteValueIfNecessary(ColumnValue, XMLWriter, ObjectsExportedWithErrors,
						InvalidCharsCheckOnly);

				EndIf;

			EndDo;

		EndIf;

		If IsQueryByObject Then

			Object = Ref.GetObject();

			Try

				ExecuteAuxiliaryActionsForXMLWriter(TotalObjectsProcessed, XMLWriter,
					InvalidCharsCheckOnly);

				Serializer.WriteXML(XMLWriter, Object);

				ObjectMetadata = Object.Metadata();

				If IsMetadataWithPredefinedItems(ObjectMetadata) And Object.Predefined Then

					NewRow = PredefinedItemsTable.Add();
					NewRow.TableName = ObjectMetadata.FullName();
					NewRow.Ref = XMLString(Ref);
					NewRow.PredefinedDataName = Object.PredefinedDataName;

				EndIf;

				If ExportDocumentWithItsRecords And Metadata.Documents.Contains(ObjectMetadata) Then
					
					// Export document register records.
					For Each Record In Object.RegisterRecords Do

						Record.Read();

						If mChildObjectsExportExistence And Record.Count() > 0 Then

							RegisterType = Type(Record);

							ColumnArray = mRegisterRecordsColumnsMap.Get(RegisterType);

							If ColumnArray = Undefined Then

								RecordsTable = Record.Unload();
								AccountingRegister = Metadata.AccountingRegisters.Contains(Record.Metadata());
								ColumnArray = GetRecordsColumnsArray(RecordsTable, AccountingRegister);
								mRegisterRecordsColumnsMap.Insert(RegisterType, ColumnArray);

							EndIf;

							ExportSetChildValues(XMLWriter, Record, ColumnArray,
								ObjectsExportedWithErrors, InvalidCharsCheckOnly);

						EndIf;

						Serializer.WriteXML(XMLWriter, Record);

					EndDo;

				EndIf;

			Except

				ErrorDescriptionString = ErrorDescription();
				// Failed to write to XML.
				// Perhaps an issue with invalid characters in XML.
				If InvalidCharsCheckOnly Then

					If ObjectsExportedWithErrors.Get(Ref) = Undefined Then
						ObjectsExportedWithErrors.Insert(Ref, ErrorDescriptionString);
					EndIf;

				Else

					FinalMessageString = NStr("ru = 'При выгрузке объекта %1(%2) возникла ошибка:
												   |%3';
											  |en = 'An error %3 occured while exporting an object %1(%2).'");
					FinalMessageString = SubstituteParametersToString(FinalMessageString, Object, TypeOf(
						Object), ErrorDescriptionString);
					UserMessage(FinalMessageString);

					Raise FinalMessageString;

				EndIf;

			EndTry;

		EndIf;

	EndDo;

EndProcedure

Procedure ExportSetChildValues(XMLWriter, Record, ColumnArray, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly)

	For Each RecordFromSet In Record Do

		For Each Column In ColumnArray Do

			If Column = "ExtDimensionsDr" Or Column = "ExtDimensionsCr" Then

				Value = RecordFromSet[Column];
				For Each KeyValue In Value Do

					If ValueIsFilled(KeyValue.Value) Then
						WriteValueIfNecessary(KeyValue.Value, XMLWriter,
							ObjectsExportedWithErrors, InvalidCharsCheckOnly);
					EndIf;

				EndDo;

			Else

				SavedValue = RecordFromSet[Column];
				WriteValueIfNecessary(SavedValue, XMLWriter, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly);

			EndIf;

		EndDo;

	EndDo;

EndProcedure

Function GetRecordsColumnsArray(RecordsTable, AccountingRegister = False)

	ColumnArray = New Array;
	For Each TableColumn In RecordsTable.Columns Do

		If TableColumn.Name = "PointInTime" Or Find(TableColumn.Name, "ExtDimensionTypeDr") = 1 Or Find(
			TableColumn.Name, "ExtDimensionTypeCr") = 1 Then

			Continue;

		EndIf;

		If Find(TableColumn.Name, "ExtDimensionsDr") = 1 And AccountingRegister Then

			If ColumnArray.Find("ExtDimensionsDr") = Undefined Then
				ColumnArray.Add("ExtDimensionsDr");
			EndIf;

			Continue;

		EndIf;

		If Find(TableColumn.Name, "ExtDimensionsCr") = 1 And AccountingRegister Then

			If ColumnArray.Find("ExtDimensionsCr") = Undefined Then
				ColumnArray.Add("ExtDimensionsCr");
			EndIf;

			Continue;

		EndIf;

		ColumnArray.Add(TableColumn.Name);

	EndDo;

	Return ColumnArray;

EndFunction

// Analyzes whether it is necessary to write the object "by reference" and writes it.
//
// Parameters:
//   ValueToAnalyze - a value to analyze.
//   XMLWriter - an object used to write infobase objects.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//
Procedure WriteValueIfNecessary(ValueToAnalyze, XMLWriter, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly)

	If Not ValueIsFilled(ValueToAnalyze) Then
		Return;
	EndIf;

	MDObject = RefTypes.Get(TypeOf(ValueToAnalyze));

	If MDObject = Undefined Then
		Return; // It is not a reference
	EndIf;

	If RefIsExported(ValueToAnalyze) Then
		Return; // The object has already been exported
	EndIf;
	
	// Checking whether this type is included in the list to export additionally.
	TableRow = FullExportContent.Find(MDObject, "MDObject");
	If TableRow <> Undefined Then
		Return;
	EndIf;

	TableRow = AuxiliaryExportContent.Find(MDObject, "MDObject");
	If TableRow <> Undefined Then

		AddlQuery = New Query("SELECT * FROM " + TableRow.TreeRow.Detail.ForQuery + MDObject.Name
			+ " AS ObjectTable_" + " WHERE Ref = &Ref");
		AddlQuery.SetParameter("Ref", ValueToAnalyze);
		QueryResult = AddlQuery.Execute();
		QueryAndWriter(QueryResult, XMLWriter, , ObjectsExportedWithErrors, InvalidCharsCheckOnly);

	EndIf;

EndProcedure

// Writes the constant value.
//
// Parameters:
//   XMLWriter - an object used to write infobase objects.
//   MD_Constant - metadata details - a constant to export.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//   FilterTable1 - a filter table.
//
Procedure WriteConstant(XMLWriter, MD_Constant, ObjectsExportedWithErrors, InvalidCharsCheckOnly,
	FilterTable1)
	QueryText= "SELECT
				  |	AutomaticallyConfigurePermissionsInSecurityProfiles.Value AS Value
				  |FROM
				  |	Constant.AutomaticallyConfigurePermissionsInSecurityProfiles КАК AutomaticallyConfigurePermissionsInSecurityProfiles
				  |";

	First=True;
	Found=False;

	For Each Row In FilterTable1 Do
		If MD_Constant.Name = Row.AttributeName Then
			Found=True;
			For Each ItemsRow In Row.Filter.Items Do
				If ItemsRow.Use Then
					If Not First Then
						QueryText = QueryText + Chars.LF + " AND " + GetComparisonTypeForQueryConstant(Row,
							ItemsRow, ItemsRow.ComparisonType);
					Else
						QueryText = QueryText + Chars.LF + " WHERE " + GetComparisonTypeForQueryConstant(
							Row, ItemsRow, ItemsRow.ComparisonType);
					EndIf;
					First=False;
				EndIf;
			EndDo;
			Break;
		EndIf;
	EndDo;
	ExportData=False;
	If Not Found Then
		ValueManager = Constants[MD_Constant.Name].CreateValueManager();
		ValueManager.Read();
		WriteValueIfNecessary(ValueManager.Value, XMLWriter, ObjectsExportedWithErrors,
			InvalidCharsCheckOnly);
		ExportData=True;
	Else

		Query=New Query;
		Query.Text=QueryText;

		For Each Row In FilterTable1 Do
			If MD_Constant.Name = Row.AttributeName Then
				Found=True;
				For Each ItemsRow In Row.Filter.Items Do
					If ItemsRow.Use Then
						Query.SetParameter(Row.AttributeName, ItemsRow.RightValue);
					EndIf;
				EndDo;
				Break;
			EndIf;
		EndDo;
		Selection1=Query.Execute().Select();

		While Selection1.Next() Do
			ValueManager = Constants[MD_Constant.Name].CreateValueManager();
			ValueManager.Read();
			If Selection1.Value = ValueManager.Value Then
				WriteValueIfNecessary(ValueManager.Value, XMLWriter, ObjectsExportedWithErrors,
					InvalidCharsCheckOnly);
				ExportData=True;
			EndIf;
		EndDo;

	EndIf;	

	TotalObjectsProcessed = TotalProcessedRecords();
	Try
		If ExportData Then
			ExecuteAuxiliaryActionsForXMLWriter(TotalObjectsProcessed, XMLWriter,
				InvalidCharsCheckOnly);
			Serializer.WriteXML(XMLWriter, ValueManager);
		EndIf;
	Except
		ErrorDescriptionString = ErrorDescription();
		// Failed to write to XML.
		// Perhaps an issue with invalid characters in XML.
		If InvalidCharsCheckOnly Then
			ObjectsExportedWithErrors.Insert(ValueManager, ErrorDescriptionString);
		Else
			FinalMessageString = NStr("ru = 'При выгрузке константы %1 возникла ошибка:
										   |%2';
									  |en = 'An error %2 occured while importing a constant %1.'");
			FinalMessageString = SubstituteParametersToString(FinalMessageString, MD_Constant.Name,
				ErrorDescriptionString);

			UserMessage(FinalMessageString);
			Raise FinalMessageString;
		EndIf;

	EndTry;

	ProcessedConstantsCount = ProcessedConstantsCount + 1;

EndProcedure

// Writes a set of register records (accumulation register, accounting register, and other).
//
// Parameters:
//   XMLWriter - an object used to write infobase objects.
//   MetadataTreeRow - a row of the metadata tree matching the register.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//   AccountingRegister - a flag defining whether it is an accounting register.
//   FilterTable1 - a filter table.
//
Procedure WriteRegister(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly, AccountingRegister = False, FilterTable1)

	RecordSetManager = MetadataTreeRow.Detail.Manager[MetadataTreeRow.MDObject.Name];

	TableNameForQuery = MetadataTreeRow.Detail.ForQuery;

	WriteViaRecordSet(XMLWriter, RecordSetManager, TableNameForQuery,
		MetadataTreeRow.MDObject.Name, MetadataTreeRow, ObjectsExportedWithErrors,
		InvalidCharsCheckOnly, AccountingRegister, FilterTable1);

EndProcedure

// Writes a set of register records (accumulation register, accounting register, and other).
//
// Parameters:
//   XMLWriter - an object used to write infobase objects.
//   MetadataTreeRow - a row of the metadata tree matching the register.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//   FilterTable1 - a filter table.
//
Procedure WriteRecalculation(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly, FilterTable1)

	CalculationRegisterName = MetadataTreeRow.Parent.Parent.MDObject.Name;
	ManagerByString = StrReplace(MetadataTreeRow.Detail.Manager, "%i", CalculationRegisterName);
	RecalculationManager = Eval(ManagerByString);
	RecalculationManager = RecalculationManager[MetadataTreeRow.MDObject.Name];
	StringForQuery = StrReplace(MetadataTreeRow.Detail.ForQuery, "%i", CalculationRegisterName);

	WriteViaRecordSet(XMLWriter, RecalculationManager, StringForQuery, MetadataTreeRow.MDObject.Name,
		MetadataTreeRow, ObjectsExportedWithErrors, InvalidCharsCheckOnly, , FilterTable1);

EndProcedure

// Writes document sequences.
//
// Parameters:
//   XMLWriter - an object used to write infobase objects.
//   MetadataTreeRow - a row of the metadata tree matching the register.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//   FilterTable1 - a filter table.
//
Procedure WriteSequence(XMLWriter, MetadataTreeRow, ObjectsExportedWithErrors,
	InvalidCharsCheckOnly, FilterTable1)

	RecordSetManager = MetadataTreeRow.Detail.Manager[MetadataTreeRow.MDObject.Name];

	WriteViaRecordSet(XMLWriter, RecordSetManager, MetadataTreeRow.Detail.ForQuery,
		MetadataTreeRow.MDObject.Name, MetadataTreeRow, ObjectsExportedWithErrors,
		InvalidCharsCheckOnly, , FilterTable1);

EndProcedure

// Writes data, which is accessed using the record set.
//
// Parameters:
//   XMLWriter - an object used to write infobase objects.
//   RecordSetManager - a manager of the information register.
//   ForQuery - a flag defines whether it is a detail for query.
//   ObjectName - an object name.
//   MetadataTreeRow - a row of the metadata tree matching the register.
//   ObjectsExportedWithErrors - a map of an object types and an export errors.
//   InvalidCharsCheckOnly - a flag of checking only invalid chars.
//   AccountingRegister - a flag defining whether it is an accounting register.
//   FilterTable1 - a filter table.
//
Procedure WriteViaRecordSet(XMLWriter, RecordSetManager, ForQuery, ObjectName,
	MetadataTreeRow = Undefined, ObjectsExportedWithErrors, InvalidCharsCheckOnly,
	AccountingRegister = False, FilterTable1)
	
	// Getting content of the register record columns and checking for records.
	If ForQuery = "AccountingRegister." Then
		TableNameForQuery = ForQuery + ObjectName + ".RecordsWithExtDimensions";
	Else
		TableNameForQuery = ForQuery + ObjectName;
	EndIf;

	First=True;
	Query= New Query;

	If ForQuery = "AccountingRegister." Then

		QueryCondition="";
		//  Conditions
		For Each Row In FilterTable1 Do
			If ObjectName = Row.AttributeName And MetadataTreeRow.MetadataObjectName
				= Row.MetadataObjectName Then
				For Each ItemsRow In Row.Filter.Items Do
					If ItemsRow.Use Then

						If String(TypeOf(ItemsRow.RightValue)) = NStr("ru = 'Стандартная дата начала'; en = 'Standard beginning date'") Then
							Query.SetParameter(String(ItemsRow.LeftValue),
								ItemsRow.RightValue.Date);
						Else
							Query.SetParameter(String(ItemsRow.LeftValue),
								ItemsRow.RightValue);
						EndIf;

						If Not First Then
							QueryCondition = QueryCondition + Chars.LF + " AND " + GetComparisonTypeForQueryRegister(
								Row, ItemsRow, ItemsRow.ComparisonType);
						Else
							QueryCondition = QueryCondition + Chars.LF + " " + GetComparisonTypeForQueryRegister(
								Row, ItemsRow, ItemsRow.ComparisonType);
						EndIf;
						First=False;
					EndIf;
				EndDo;
				Break;
			EndIf;
		EndDo;
		QueryText="SELECT ALLOWED TOP  1 * FROM " + TableNameForQuery + "(, , " + QueryCondition
			+ ", ,  )  AS ObjectTable_" + ObjectName;

	Else

		QueryText = "SELECT ALLOWED TOP  1 *   FROM " + TableNameForQuery + " AS ObjectTable_"
			+ ObjectName;

		For Each Row In FilterTable1 Do
			If ObjectName = Row.AttributeName And MetadataTreeRow.MetadataObjectName
				= Row.MetadataObjectName Then
				For Each ItemsRow In Row.Filter.Items Do
					If ItemsRow.Use Then

						If String(TypeOf(ItemsRow.RightValue)) = NStr("ru = 'Стандартная дата начала'; en = 'Standard beginning date'") Then
							Query.SetParameter(String(ItemsRow.LeftValue),
								ItemsRow.RightValue.Date);
						Else
							Query.SetParameter(String(ItemsRow.LeftValue),
								ItemsRow.RightValue);
						EndIf;

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

	EndIf;
	Query.Text=QueryText;

	ContentQueryResult = Query.Execute();
	If ContentQueryResult.IsEmpty() Then
		Return;
	EndIf;

	RecordsTable = ContentQueryResult.Unload();
	ColumnArray = GetRecordsColumnsArray(RecordsTable, AccountingRegister);
	
	// Registers are exported via its record set.
	RecordSet = RecordSetManager.CreateRecordSet();

	Filter = RecordSet.Filter;
	FilterFieldsString = "";
	For Each FilterItem In Filter Do
		If Not IsBlankString(FilterFieldsString) Then
			FilterFieldsString = FilterFieldsString + ",";
		EndIf;
		FilterFieldsString =FilterFieldsString + "ObjectTable_" + ObjectName + "." + FilterItem.Name;
	EndDo;

	FilterFieldsString1 = "";
	For Each FilterItem In Filter Do
		If Not IsBlankString(FilterFieldsString1) Then
			FilterFieldsString1 = FilterFieldsString1 + ",";
		EndIf;
		FilterFieldsString1 =FilterFieldsString1 + "ObjectTable_" + ObjectName + "1." + FilterItem.Name;
	EndDo;

	ReportBuilder = PrepareBuilderForExport(MetadataTreeRow, FilterFieldsString, FilterFieldsString1,
		FilterTable1);
	ReportBuilder.Execute();
	FilterValuesQueryResult = ReportBuilder.Result;
	ResultSelection = FilterValuesQueryResult.Select();

	FilterFieldsCount = RecordSet.Filter.Count();
	
	// Reading record sets with different filter content and writing them.
	While ResultSelection.Next() Do
		
		// Setting a filter for registers with at least one filter (dimension).
		If FilterFieldsCount <> 0 Then

			For Each Column In FilterValuesQueryResult.Columns Do
				Filter[Column.Name].Value = ResultSelection[Column.Name];
				Filter[Column.Name].ComparisonType = ComparisonType.Equal;
				Filter[Column.Name].Use = True;
			EndDo;

		EndIf;

		RecordSet.Read();

		If mChildObjectsExportExistence Then
		
			// Checking whether values written to the set need to be written by reference.
			ExportSetChildValues(XMLWriter, RecordSet, ColumnArray, ObjectsExportedWithErrors,
				InvalidCharsCheckOnly);

		EndIf;

		TotalObjectsProcessed = TotalProcessedRecords();
		Try

			ExecuteAuxiliaryActionsForXMLWriter(TotalObjectsProcessed, XMLWriter,
				InvalidCharsCheckOnly);

			Serializer.WriteXML(XMLWriter, RecordSet);

		Except

			ErrorDescriptionString = ErrorDescription();
			// Failed to write to XML.
			// Perhaps an issue with invalid characters in XML.
			If InvalidCharsCheckOnly Then

				NewSet = RecordSetManager.CreateRecordSet();

				For Each FilterRow In RecordSet.Filter Do

					FormFilterRow = NewSet.Filter.Find(FilterRow.Name);

					If FormFilterRow = Undefined Then
						Continue;
					EndIf;

					FormFilterRow.Use = FilterRow.Use;
					FormFilterRow.ComparisonType = FilterRow.ComparisonType;
					FormFilterRow.Value = FilterRow.Value;

				EndDo;

				ObjectsExportedWithErrors.Insert(NewSet, ErrorDescriptionString);

			Else

				FinalMessageString = NStr("ru = 'При выгрузке регистра %1%2 возникла ошибка:
											   |%3';
									  	  |en = 'An error %3 occured while importing a register %1%2.'");
				FinalMessageString = SubstituteParametersToString(FinalMessageString, ForQuery, ObjectName,
					ErrorDescriptionString);

				UserMessage(FinalMessageString);

				Raise FinalMessageString;

			EndIf;

		EndTry;

		ProcessedRecordSetsCount = ProcessedRecordSetsCount + 1;

	EndDo;

EndProcedure

// Recursively processes the metadata tree row creating lists of full and auxiliary exports.
//
// Parameters:
//   FullExportContent - a full export list.
//   AuxiliaryExportContent - an auxiliary export list.
//   VTRow - a metadata tree row to be processed.
//
Procedure AddObjectsToExport(FullExportContent, AuxiliaryExportContent, VTRow)

	If (VTRow.Detail <> Undefined) And VTRow.Detail.ToExport Then

		AddedRow = Undefined;

		If VTRow.ExportData Then

			AddedRow = FullExportContent.Add();

		ElsIf VTRow.ExportIfNecessary Then

			AddedRow = AuxiliaryExportContent.Add();

		EndIf;

		If AddedRow <> Undefined Then

			AddedRow.MDObject = VTRow.MDObject;
			AddedRow.TreeRow = VTRow;

		EndIf;

	EndIf;

	For Each VTChildRow In VTRow.Rows Do
		AddObjectsToExport(FullExportContent, AuxiliaryExportContent, VTChildRow);
	EndDo;

EndProcedure

// Fills in the metadata tree row filling mapping between reference types and metadata objects.
//
// Parameters:
//   MDObject - metadata object details.
//   VTItem - a metadata tree row to be filled.
//   Detail - details of the class, to which the metadata object belongs (properties, subordinate classes).
//
Procedure BuildObjectSubtree(MDObject, VTItem, Detail)

	VTItem.Metadata = MDObject;
	VTItem.MDObject   = MDObject;
	VTItem.MetadataFullName = MDObject.Name;
	VTItem.MetadataObjectName= Detail.Class;

	VTItem.Detail = Detail;
	VTItem.ExportData = False;
	VTItem.ExportIfNecessary = True;
	VTItem.PictureIndex = Detail.PictureIndex;
	//VTItem.IndexInTree=TreeRowNo;
	//TreeRowNo=TreeRowNo+1;

	If Detail.Manager <> Undefined Then
		
		// Filling mapping between reference types and metadata objects.
		If ObjectFormsRefType(MDObject) Then
			RefTypes[TypeOf(Detail.Manager[MDObject.Name].EmptyRef())] = MDObject;
		EndIf;

		If Metadata.AccumulationRegisters.Contains(MDObject) Or Metadata.AccountingRegisters.Contains(MDObject) Then

			RegistersUsingTotals.Add(VTItem);

		EndIf;

	EndIf;		
		
	// child branches
	For Each ChildClass In Detail.Rows Do

		If Not ChildClass.ToExport Then
			Continue;
		EndIf;

		ClassBranch = VTItem.Rows.Add();
		ClassBranch.Metadata = ChildClass.Class;
		ClassBranch.ExportData = False;
		ClassBranch.ExportIfNecessary = True;
		ClassBranch.MetadataFullName = ChildClass.Class;
		ClassBranch.PictureIndex = ChildClass.PictureIndex;

		ClassChildObjects = MDObject[ChildClass.Class];

		For Each MDChildObject In ClassChildObjects Do
			VTChildItem = ClassBranch.Rows.Add();
			BuildObjectSubtree(MDChildObject, VTChildItem, ChildClass);
		EndDo;

	EndDo;

EndProcedure

// Deletes the rows with metadata not included in the data exported.
//
// Parameters:
//   VTItem - a metadata tree row whose child items are considered to be deleted from the list of 
//        potentially exported data.
//
Procedure CollapseObjectSubtree(VTItem)

	ClassBranchesToDelete = New Array;
	For Each ClassBranch In VTItem.Rows Do

		ChildMDToDelete = New Array;

		For Each ChildMDObject In ClassBranch.Rows Do
			CollapseObjectSubtree(ChildMDObject);
			If (ChildMDObject.Rows.Count()) = 0 And (Not ChildMDObject.Detail.ToExport) Then

				ChildMDToDelete.Add(ClassBranch.Rows.Index(ChildMDObject));

			EndIf;

		EndDo;

		For Counter = 1 To ChildMDToDelete.Count() Do
			ClassBranch.Rows.Delete(ChildMDToDelete[ChildMDToDelete.Count() - Counter]);
		EndDo;

		If ClassBranch.Rows.Count() = 0 Then
			ClassBranchesToDelete.Add(VTItem.Rows.Index(ClassBranch));
		EndIf;

	EndDo;

	For Counter = 1 To ClassBranchesToDelete.Count() Do
		VTItem.Rows.Delete(ClassBranchesToDelete[ClassBranchesToDelete.Count() - Counter]);
	EndDo;

EndProcedure

// Sets the ExportData flag for metadata tree rows child to current, calculates and 
//      sets the ExportData flag for other objects whose references the object matching this row contains.
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure SetExportDataToChildRows(VTItem)
	For Each ChildRow In VTItem.Rows Do
		ChildRow.ExportData = VTItem.ExportData;
		SetExportDataToChildRows(ChildRow);
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
	SetExportDataToChildRows(ЭлементДЗ);
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
Function ObjectFormsRefType(ОбъектМД) Export

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

						СсылкаВБазе = XMLString(Выборка.Ссылка);
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

Function IsMetadataWithPredefinedItems(ОбъектМетаданных)

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

	If ObjectFormsRefType(ОбъектМетаданных) Then

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
