
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
	MetadataTree.Columns.Add("MetadataFullName");
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
// sets the ExportData flag for other objects whose references the object matching this row contains.
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

// Sets the ExportData flag for the metadata tree row based on this flag of child rows, 
// then calls itself for the parent ensuring processing to the tree root.
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure UpdateExportDataState(VTItem)
	If VTItem = Undefined Then
		Return;
	EndIf;
	If (VTItem.Detail <> Undefined) And VTItem.Detail.ToExport Then
		Return; // Updating up to a root or to the first item to be exported.
	EndIf;
	State = Undefined;
	For Each VTChildItem In VTItem.Rows Do
		If State = Undefined Then
			State = VTChildItem.ExportData;
		Else
			If Not State = VTChildItem.ExportData Then
				State = 2;
				Break;
			EndIf;
		EndIf;
	EndDo;

	If State <> Undefined Then
		VTItem.ExportData = State;
		UpdateExportDataState(VTItem.Parent);
	EndIf;
EndProcedure

// Processes a state of an ExportData flag - sets a Export and ExportIfNecessary flag for a related tree branches.
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure ExportDataStateChangeProcessing(VTItem) Export
	If VTItem.ExportData = 2 Then
		VTItem.ExportData = 0;
	EndIf;
	// Changing "down"
	SetExportDataToChildRows(VTItem);
	// Changing "up"
	UpdateExportDataState(VTItem.Parent);
EndProcedure

// Sets the ExportData flag for metadata tree rows child to current,  
// calculates and sets the export by reference flag for other objects 
// whose references the object matching this row must contain. 
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure SetExportIfNecessaryToChildRows(VTItem)

	For Each ChildRow In VTItem.Rows Do
		ChildRow.ExportIfNecessary = VTItem.ExportIfNecessary;
		SetExportIfNecessaryToChildRows(ChildRow);
	EndDo;

EndProcedure

// Sets the ExportData flag for the metadata tree row based on this flag of child 
// rows, then it calls itself for the parent ensuring processing to the tree root.
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure UpdateExportIfNecessaryState(VTItem)

	If VTItem = Undefined Then
		Return;
	EndIf;

	If (VTItem.Detail <> Undefined) And VTItem.Detail.ToExport Then
		Return; // Updating up to a root or to the first item to be exported.
	EndIf;

	State = Undefined;
	For Each VTChildItem In VTItem.Rows Do

		If State = Undefined Then
			State = VTChildItem.ExportIfNecessary;
		Else
			If Not State = VTChildItem.ExportIfNecessary Then
				State = 2;
				Break;
			EndIf;
		EndIf;

	EndDo;

	If State <> Undefined Then
		VTItem.ExportIfNecessary = State;
		UpdateExportIfNecessaryState(VTItem.Parent);
	EndIf;

EndProcedure

// Processes the status of the ExportData flag, setting the ExportData and ExportIfNecessary 
// flags for related branches of the tree.
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure ExportIfNecessaryStateChangeProcessing(VTItem) Export

	If VTItem.ExportIfNecessary = 2 Then
		VTItem.ExportIfNecessary = 0;
	EndIf;
	
	// Changing "down"
	SetExportIfNecessaryToChildRows(VTItem);
	// Changing "up"
	UpdateExportIfNecessaryState(VTItem.Parent);

EndProcedure

// Determines whether objects of this metadata class are typed ones.
//
// Parameters:
//   Details - class details.
//   
// Return value - True if objects of this metadata class are typed ones.
//
Function MDClassTyped(Details)

	For Each Property In Details.Properties Do
		If Property.Value = "Type" Then
			Return True;
		EndIf;
	EndDo;
	Return False;

EndFunction

// Determines whether the type is a reference one.
//
// Parameters:
//   Type - a type to check.
//   
// Return value - True, if type is a reference one.
//
Function RefType(Type)

	TypeMetadata = RefTypes.Get(Type);
	Return TypeMetadata <> Undefined;

EndFunction

// Adds a new item to the array if it is unique.
//
// Parameters:
//   Array - an array to add an item.
//   Item - an item to be added.
//
Procedure AddToArrayIfUnique(Array, Item)

	If Array.Find(Item) = Undefined Then
		Array.Add(Item);
	EndIf;

EndProcedure

// Returns an array of types that can have record fields of a metadata object matching the tree row.
//
// Parameters:
//   VTItem - a metadata tree row.
//   
// Return value - an array of types potentially used by the matching record.
//
Function GetAllTypes(VTItem)

	MDObject = VTItem.MDObject;
	If TypeOf(MDObject) <> Type("MetadataObject") And TypeOf(MDObject) <> Type("ConfigurationMetadataObject") Then

		Raise (NStr("ru = 'Внутренняя ошибка обработки выгрузки'; en = 'Export internal error'"));

	EndIf;

	Return GetMDOTypes(MDObject, VTItem.Detail);

EndFunction

// Returns an array of types that can have metadata object record fields.
//
// Parameters:
//   MDObject - metadata details.
//   Detail - details of the metadata object class.
//   
// Return value - an array of types potentially used by the matching record.
//
Function GetMDOTypes(MDObject, Detail)

	AllTypes = New Array;

	For Each Property In Detail.Properties Do

		PropertyValue = MDObject[Property.Value];
		If TypeOf(PropertyValue) = Type("MetadataObjectPropertyValueCollection")
			И PropertyValue.Count() > 0 Then

			For Each CollectionRow In PropertyValue Do

				RefTypeKeyValue = MetadataObjectsAndRefTypesMap[CollectionRow];

				If RefTypeKeyValue <> Undefined Then

					AddToArrayIfUnique(AllTypes, RefTypeKeyValue);

				EndIf;

			EndDo;

		ElsIf TypeOf(PropertyValue) = Type("MetadataObject") Then

			For Each RefTypeKeyValue In RefTypes Do

				If PropertyValue = RefTypeKeyValue.Value Then
					AddToArrayIfUnique(AllTypes, RefTypeKeyValue.Key);
				EndIf;

			EndDo;

		EndIf;

	EndDo;

	If MDClassTyped(Detail) Then

		TypeDescription = MDObject.Тип;
		For Each OneType In TypeDescription.Types() Do

			If RefType(OneType) Then
				AddToArrayIfUnique(AllTypes, OneType);
			EndIf;

		EndDo;

	Else

		If Metadata.InformationRegisters.Contains(MDObject) Or Metadata.AccumulationRegisters.Contains(MDObject)
			Or Metadata.AccountingRegisters.Contains(MDObject) Or Metadata.CalculationRegisters.Contains(MDObject) Then
			
			// Searching for some registers in possible recorders.
			For Each MDDocument In Metadata.Documents Do

				If MDDocument.RegisterRecords.Contains(MDObject) Then

					AddToArrayIfUnique(AllTypes, TypeOf(Documents[MDDocument.Name].EmptyRef()));

				EndIf;

			EndDo;

		EndIf;

	EndIf;

	For Each ChildClass In Detail.Rows Do

		For Each MDChildObject In MDObject[ChildClass.Class] Do

			ChildTypes = GetMDOTypes(MDChildObject, ChildClass);
			For Each OneType In ChildTypes Do
				AddToArrayIfUnique(AllTypes, OneType);
			EndDo;

		EndDo;

	EndDo;

	Return AllTypes;

EndFunction

// Returns the metadata tree row matching the passed metadata object.
// Rows child to the passed row are searched.
//
// Parameters:
//   VTRow - a metadata tree row from which the search is started.
//   MDObject - metadata details.
//   
// Return value - a metadata tree row.
//
Function VTItemByMDObjectAndRow(VTRow, MDObject)

	Return VTRow.Rows.Find(MDObject, "MDObject", True);

EndFunction

// Returns the metadata tree row matching the passed metadata object.
// The entire metadata tree is searched.
//
// Parameters:
//   MDObject - metadata details.
//   
// Return value - a metadata tree row.
//
Function VTItemByMDObject(MDObject)
	For Each VTRow In MetadataTree.Rows Do
		VTItem = VTItemByMDObjectAndRow(VTRow, MDObject);
		If VTItem <> Undefined Then
			Return VTItem;
		EndIf;
	EndDo;
	Return Undefined;
EndFunction

// Determines, to which objects the record matching the metadata object displayed by 
// this metadata tree row can refer, and sets the ExportIfNecessary flag for them.
//
// Parameters:
//   VTItem - a metadata tree row.
//
Procedure SetExportIfNecessaryState(VTItem)

	UpdateExportIfNecessaryState(VTItem.Parent);
	If VTItem.ExportData <> 1 And VTItem.ExportIfNecessary <> 1 Then
		Return;
	EndIf;
	If VTItem.MDObject = Undefined Then
		Return;
	EndIf;

	AllTypes = GetAllTypes(VTItem);
	For Each RefType In AllTypes Do

		TypeAndObject = RefTypes.Get(RefType);
		If TypeAndObject = Undefined Then

			ExceptionText = NStr("ru = 'Внутренняя ошибка. Неполное заполнение структуры ссылочных типов %1'; en = 'Internal error. Incomplete structure of reference types %1.'");
			ExceptionText = SubstituteParametersToString(ExceptionText, RefType);
			Raise (ExceptionText);

		EndIf;

		MDObject = TypeAndObject;
		VTRow = VTItemByMDObject(MDObject);
		If VTRow = Undefined Then

			ExceptionText = NStr(
				"ru = 'Внутренняя ошибка. Неполное заполнение дерева метаданных. Отсутствует объект, образующий тип %1';
				|en = 'Internal error. Incomplete metadata tree. Object of type %1 is missing.'");
			ExceptionText = SubstituteParametersToString(ExceptionText, RefType);
			Raise (ExceptionText);

		EndIf;

		If VTRow.ExportData = 1 Or VTRow.ExportIfNecessary = 1 Then

			Continue;

		EndIf;

		VTRow.ExportIfNecessary = 1;
		SetExportIfNecessaryState(VTRow);

	EndDo;

EndProcedure

// Determines a total number of records of constants, object types, and record sets.
//
// Return value - a total number of records.
//
Function TotalProcessedRecords()

	Return mExportedObjects.Count() + ProcessedConstantsCount + ProcessedRecordSetsCount;

EndFunction

// Fills in a tree of metadata object classes.
//
Procedure FillMetadataDetails()

	RowValuesTreeStack = New Array;
	MetadataDetails = New ValueTree;
	MetadataDetails.Columns.Add("ToExport", New TypeDescription("Boolean"));
	MetadataDetails.Columns.Add("ForQuery", New TypeDescription("String"));
	MetadataDetails.Columns.Add("Class", New TypeDescription("String", , New StringQualifiers(100,
		AllowedLength.Variable)));
	MetadataDetails.Columns.Add("Manager");
	MetadataDetails.Columns.Add("Properties", New TypeDescription("ValueList"));
	MetadataDetails.Columns.Add("PictureIndex");
	RowValuesTreeStack.Insert(0, MetadataDetails.Rows);
	//////////////////////////////////
	// Configurations
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Configurations";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.PictureIndex = 0;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Constants
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Constants";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Constants;
	ClassDetails.ForQuery  = "";
	ClassDetails.PictureIndex = 1;
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.Catalogs
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Catalogs";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Catalogs;
	ClassDetails.ForQuery  = "Catalog.";
	ClassDetails.Properties.Add("Owners");
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 3;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Catalogs.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("Use");
	//////////////////////////////////
	// Configurations.Catalogs.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Use");
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Catalogs.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.Documents
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Documents";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Documents;
	ClassDetails.ForQuery  = "Document.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("RegisterRecords");
	ClassDetails.PictureIndex = 7;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Documents.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.Documents.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Documents.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.Sequences
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Sequences";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Sequences;
	ClassDetails.ForQuery  = "Sequence.";
	ClassDetails.Properties.Add("Documents");
	ClassDetails.Properties.Add("RegisterRecords");
	ClassDetails.PictureIndex = 5;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Sequences.Dimensions
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("DocumentMap");
	ClassDetails.Properties.Add("RegisterRecordsMap");
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "ChartsOfCharacteristicTypes";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ChartsOfCharacteristicTypes;
	ClassDetails.ForQuery  = "ChartOfCharacteristicTypes.";
	ClassDetails.Properties.Add("CharacteristicExtValues");
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 9;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("Use");
	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Use");
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ChartsOfCharacteristicTypes.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.ChartsOfAccounts
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "ChartsOfAccounts";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ChartsOfAccounts;
	ClassDetails.ForQuery  = "ChartOfAccounts.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("ExtDimensionTypes");
	ClassDetails.PictureIndex = 11;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ChartsOfAccounts.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.ChartsOfAccounts.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ChartsOfAccounts.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "ChartsOfCalculationTypes";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ChartsOfCalculationTypes;
	ClassDetails.ForQuery  = "ChartOfCalculationTypes.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("DependenceOnCalculationTypes");
	ClassDetails.Properties.Add("BaseCalculationTypes");
	ClassDetails.Properties.Add("ActionPeriodUse");
	ClassDetails.PictureIndex = 13;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ChartsOfCalculationTypes.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.InformationRegisters
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "InformationRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = InformationRegisters;
	ClassDetails.ForQuery  = "InformationRegister.";
	ClassDetails.PictureIndex = 15;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.InformationRegisters.Resources
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.InformationRegisters.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.InformationRegisters.Dimensions
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.AccumulationRegisters
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "AccumulationRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = AccumulationRegisters;
	ClassDetails.ForQuery  = "AccumulationRegister.";
	ClassDetails.PictureIndex = 17;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.AccumulationRegisters.Resources
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.AccumulationRegisters.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.AccumulationRegisters.Dimensions
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.AccountingRegisters
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "AccountingRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = AccountingRegisters;
	ClassDetails.ForQuery  = "AccountingRegister.";
	ClassDetails.Properties.Add("ChartOfAccounts");
	ClassDetails.Properties.Add("Correspondence");
	ClassDetails.PictureIndex = 19;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.AccountingRegisters.Dimensions
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.AccountingRegisters.Resources
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.AccountingRegisters.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.CalculationRegisters
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "CalculationRegisters";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = CalculationRegisters;
	ClassDetails.ForQuery  = "CalculationRegister.";
	ClassDetails.Properties.Add("Periodicity");
	ClassDetails.Properties.Add("ActionPeriod");
	ClassDetails.Properties.Add("BasePeriod");
	ClassDetails.Properties.Add("Schedule");
	ClassDetails.Properties.Add("ScheduleValue");
	ClassDetails.Properties.Add("ScheduleDate");
	ClassDetails.Properties.Add("ChartOfCalculationTypes");
	ClassDetails.PictureIndex = 21;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.CalculationRegisters.Resources
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Resources";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.CalculationRegisters.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("ScheduleLink");
	//////////////////////////////////
	// Configurations.CalculationRegisters.Dimensions
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Dimensions";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("BaseDimension");
	ClassDetails.Properties.Add("ScheduleLink");
	//////////////////////////////////
	// Configurations.CalculationRegisters.Recalculations
	//ClassDetails = RowValuesTreeStack[0].Add();
	//ClassDetails.Class = "Recalculations";
	//ClassDetails.ToExport = True;
	//ClassDetails.Manager  = "CalculationRegisters.%i.Recalculations";
	//ClassDetails.ForQuery  = "CalculationRegister.%i.";
	//RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.CalculationRegisters.Recalculations.Dimensions
	//ClassDetails = RowValuesTreeStack[0].Add();
	//ClassDetails.Class = "Dimensions";
	//ClassDetails.ToExport = False;
	//ClassDetails.Properties.Add("LeadingRegisterData");
	//ClassDetails.Properties.Add("RegisterDimension");
	//RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.BusinessProcesses
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "BusinessProcesses";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = BusinessProcesses;
	ClassDetails.ForQuery  = "BusinessProcess.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.Properties.Add("Task");
	ClassDetails.PictureIndex = 23;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.BusinessProcesses.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.BusinessProcesses.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.BusinessProcesses.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	//////////////////////////////////
	// Configurations.Tasks
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Tasks";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = Задачи;
	ClassDetails.ForQuery  = "Task.";
	ClassDetails.Properties.Add("Addressing");
	ClassDetails.Properties.Add("MainAddressingAttribute");
	ClassDetails.Properties.Add("CurrentPerformer");
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 25;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Tasks.AddressingAttributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "AddressingAttributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	ClassDetails.Properties.Add("AddressingDimension");
	//////////////////////////////////
	// Configurations.Tasks.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.Tasks.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.Tasks.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);
	
	//////////////////////////////////
	// Configurations.ExchangePlans
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "ExchangePlans";
	ClassDetails.ToExport = True;
	ClassDetails.Manager = ExchangePlans;
	ClassDetails.ForQuery  = "ExchangePlan.";
	ClassDetails.Properties.Add("BasedOn");
	ClassDetails.PictureIndex = 27;
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ExchangePlans.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	//////////////////////////////////
	// Configurations.ExchangePlans.TabularSections
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "TabularSections";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	RowValuesTreeStack.Insert(0, ClassDetails.Rows);
	//////////////////////////////////
	// Configurations.ExchangePlans.TabularSections.Attributes
	ClassDetails = RowValuesTreeStack[0].Add();
	ClassDetails.Class = "Attributes";
	ClassDetails.ToExport = False;
	ClassDetails.ForQuery  = "";
	ClassDetails.Properties.Add("Type");
	RowValuesTreeStack.Delete(0);
	RowValuesTreeStack.Delete(0);

	RowValuesTreeStack.Delete(0);

EndProcedure

// Determines whether the passed metadata object has a reference type.
//
// Return value - True, if the passed metadata object has a reference type
//
Function ObjectFormsRefType(MDObject) Export

	If MDObject = Undefined Then
		Return False;
	EndIf;

	If Metadata.Catalogs.Contains(MDObject) Or Metadata.Documents.Contains(MDObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MDObject) Or Metadata.ChartsOfAccounts.Contains(MDObject)
		Or Metadata.ChartsOfCalculationTypes.Contains(MDObject) Or Metadata.ExchangePlans.Contains(MDObject)
		Or Metadata.BusinessProcesses.Contains(MDObject) Or Metadata.Tasks.Contains(MDObject) Then
		Return True;
	EndIf;

	Return False;
EndFunction

// Determines which object types are to be exported to maintain referential integrity.
//
// Parameters:
//   DataToExport - an array of strings - a combination of objects to be exported.
//
Procedure RecalculateDataToExportByRef(DataToExport)
	
	// Clearing all ExportIfNecessary flags.
	ConfigurationRow = MetadataTree.Rows[0];
	ConfigurationRow.ExportIfNecessary = 0;
	ExportIfNecessaryStateChangeProcessing(ConfigurationRow);
	
	// Processing of the passed object set.
	For Each ToExport In DataToExport Do

		SetExportIfNecessaryState(ToExport.TreeRow);

	EndDo;

EndProcedure

// Disables the use of register totals
//
Procedure RemoveTotalsUsage() Export

	If AllowResultsUsageEditingRights Then

		For Each Register_WithVT In RegistersUsingTotals Do

			Register_WithVT.Detail.Manager[Register_WithVT.MDObject.Name].SetTotalsUsing(False);

		EndDo;

	EndIf;

EndProcedure

// Enables the use of register totals
//
Procedure RestoreTotalsUsage() Export

	If AllowResultsUsageEditingRights Then

		For Each Register_WithVT In RegistersUsingTotals Do

			Register_WithVT.Detail.Manager[Register_WithVT.MDObject.Name].SetTotalsUsing(True);

		EndDo;

	EndIf;

EndProcedure

// Returns a current data processor version.
//
Function ObjectVersion() Export

	Return "2.1.8";

EndFunction

Procedure UserMessage(Text)

	Message = New UserMessage;
	Message.Text = Text;
	Message.Message();

EndProcedure

Procedure InitializePredefinedItemsTable()

	PredefinedItemsTable = New ValueTable;
	PredefinedItemsTable.Columns.Add("TableName");
	PredefinedItemsTable.Columns.Add("Ref");
	PredefinedItemsTable.Columns.Add("PredefinedDataName");

EndProcedure

Procedure ExportPredefinedItemsTable(XMLWriter)

	XMLWriter.WriteStartElement("PredefinedData");

	If PredefinedItemsTable.Count() > 0 Then

		PredefinedItemsTable.Sort("TableName");

		PreviousTableName = "";

		For Each Item In PredefinedItemsTable Do

			If PreviousTableName <> Item.TableName Then
				If Not IsBlankString(PreviousTableName) Then
					XMLWriter.WriteEndElement();
				EndIf;
				XMLWriter.WriteStartElement(Item.TableName);
			EndIf;

			XMLWriter.WriteStartElement("item");
			XMLWriter.WriteAttribute("Ref", Item.Ref);
			XMLWriter.WriteAttribute("PredefinedDataName", Item.PredefinedDataName);
			XMLWriter.WriteEndElement();

			PreviousTableName = Item.TableName;

		EndDo;

		XMLWriter.WriteEndElement();

	EndIf;

	XMLWriter.WriteEndElement();

EndProcedure

Procedure ImportPredefinedItemsTable(XMLReader)

	XMLReader.Skip(); // Skipping the main data block on the first reading.
	XMLReader.Read();

	InitializePredefinedItemsTable();
	TempRow = PredefinedItemsTable.Add();

	RefsReplacementMap = New Map;

	While XMLReader.Read() Do

		If XMLReader.NodeType = ТипУзлаXML.НачалоЭлемента Then

			If XMLReader.LocalName <> "item" Then
				
				TempRow.TableName = XMLReader.LocalName;
				
				QueryText = 
				"SELECT
				|	Table.Ref AS Ref
				|FROM
				|	" + TempRow.TableName + " AS Table
				|WHERE
				|	Table.PredefinedDataName = &PredefinedDataName";
				Query = New Query(QueryText);

			Else

				While XMLReader.ReadAttribute() Do
					
					TempRow[XMLReader.LocalName] = XMLReader.Value;
					
				EndDo;
				
				Query.SetParameter("PredefinedDataName", TempRow.PredefinedDataName);
				
				QueryResult = Query.Execute();
				If Not QueryResult.IsEmpty() Then
					
					Selection = QueryResult.Select();
					
					If Selection.Count() = 1 Then
						
						Selection.Next();
						
						RefInBase = XMLString(Selection.Ref);
						RefInFile = TempRow.Ref;

						If ThisObject.PredefinedItemsImportMode = 1 Then

							ObjectToDelete=Selection.Ref.GetObject();
							ObjectToDelete.Delete();

						Else

							If RefInBase <> RefInFile Then

								XMLType = XMLRefType(Selection.Ref);

								TypeMap = RefsReplacementMap.Get(XMLType);

								If TypeMap = Undefined Then

									TypeMap = New Map;
									TypeMap.Insert(RefInFile, RefInBase);
									RefsReplacementMap.Insert(XMLType, TypeMap);

								Else

									TypeMap.Insert(RefInFile, RefInBase);

								EndIf;

							EndIf;

						EndIf;

					Else

						ExceptionText = NStr("ru = 'Обнаружено дублирование предопределенных элементов %1 в таблице %2.'; en = 'Duplicate predefined items %1 are found in table %2.'");
						ExceptionText = StrReplace(ExceptionText, "%1", TempRow.PredefinedDataName);
						ExceptionText = StrReplace(ExceptionText, "%2", TempRow.TableName);
						
						Raise ExceptionText;

					EndIf;

				EndIf;

			EndIf;

		EndIf;

	EndDo;

	XMLReader.Close();

EndProcedure

Procedure ReplacePredefinedItemsRefs(FileName)

	ReaderStream = New TextReader(FileName);
	
	TempFile = GetTempFileName("xml");
	
	WriteStream = New TextWriter(TempFile);
	
	// Constants for parsing the text.
	TypeBeginning = "xsi:type=""v8:";
	TypeBeginningLength = StrLen(TypeBeginning);
	TypeEnd = """>";
	TypeEndLength = StrLen(TypeEnd);
	
	InitialLine = ReaderStream.ReadLine();
	While InitialLine <> Undefined Do
		
		LineBalance = Undefined;
		
		CurrentPosition = 1;
		TypePosition = StrFind(InitialLine, TypeBeginning);
		While TypePosition > 0 Do
			
			WriteStream.Write(Mid(InitialLine, CurrentPosition, TypePosition - 1 + TypeBeginningLength));
			
			LineBalance = Mid(InitialLine, CurrentPosition + TypePosition + TypeBeginningLength - 1);
			CurrentPosition = CurrentPosition + TypePosition + TypeBeginningLength - 1;
			
			TypeEndPosition = Find(LineBalance, TypeEnd);
			If TypeEndPosition = 0 Then
				Break;
			EndIf;
			
			TypeName = Left(LineBalance, TypeEndPosition - 1);
			ReplacementMap = RefsReplacementMap.Get(TypeName);
			If ReplacementMap = Undefined Then
				TypePosition = Find(LineBalance, TypeBeginning);
				Continue;
			EndIf;
			
			WriteStream.Write(TypeName);
			WriteStream.Write(TypeEnd);

			SourceRefXML = Mid(LineBalance, TypeEndPosition + TypeEndLength, 36);
			
			FoundXMLRef = ReplacementMap.Get(SourceRefXML);
			
			If FoundXMLRef = Undefined Then
				WriteStream.Write(SourceRefXML);
			Else
				WriteStream.Write(FoundXMLRef);
			EndIf;
			
			CurrentPosition = CurrentPosition + TypeEndPosition - 1 + TypeEndLength + 36;
			LineBalance = Mid(LineBalance, TypeEndPosition + TypeEndLength + 36);
			TypePosition = Find(LineBalance, TypeBeginning);
			
		EndDo;
		
		If LineBalance <> Undefined Then
			WriteStream.WriteLine(LineBalance);
		Else
			WriteStream.WriteLine(InitialLine);
		EndIf;
		
		InitialLine = ReaderStream.ReadLine();
		
	EndDo;
	
	ReaderStream.Close();
	WriteStream.Close();

	FileName = TempFile;

EndProcedure

Function IsMetadataWithPredefinedItems(MetadataObject)

	Return Metadata.Catalogs.Contains(MetadataObject) Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Or Metadata.ChartsOfCalculationTypes.Contains(
		MetadataObject);

EndFunction

// Returns XDTOSerializer with type annotation.
//
Procedure InitializeXDTOSerializerWithTypesAnnotation()

	TypesWithRefsAnnotation = PredefinedTypesOnExport();
	
	If TypesWithRefsAnnotation.Count() > 0 Then
		
		Factory = GetFactoryWithTypes(TypesWithRefsAnnotation);
		Serializer = New XDTOSerializer(Factory);
		
	Else
		
		Serializer = XDTOSerializer;
		
	EndIf;

EndProcedure

Function PredefinedTypesOnExport()

	Types = New Array;
	
	For Each MetadataObject In Metadata.Catalogs Do
		Types.Add(MetadataObject);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfAccounts Do
		Types.Add(MetadataObject);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCharacteristicTypes Do
		Types.Add(MetadataObject);
	EndDo;
	
	For Each MetadataObject In Metadata.ChartsOfCalculationTypes Do
		Types.Add(MetadataObject);
	EndDo;
	
	Return Types;

EndFunction

// Returns a factory specifying types.
//
// Parameters:
//	Types - FixedArray (Metadata) - an array of types.
//
// Returns:
//	XDTOFactory - a factory.
//
Function GetFactoryWithTypes(Val Types)

	SchemasSet = XDTOFactory.ExportXMLSchema("http://v8.1c.ru/8.1/data/enterprise/current-config");
	Schema = SchemasSet[0];
	Schema.UpdateDOMElement();
	
	SpecifiedTypes = New Map;
	For Each Type In Types Do
		SpecifiedTypes.Insert(XMLRefType(Type), True);
	EndDo;
	
	Namespace = New Map;
	Namespace.Insert("xs", "http://www.w3.org/2001/XMLSchema");
	DOMNamespaceResolver = New DOMNamespaceResolver(Namespace);
	XPathText = "/xs:schema/xs:complexType/xs:sequence/xs:element[starts-with(@type,'tns:')]";

	Query = Schema.DOMDocument.CreateXPathExpression(XPathText, DOMNamespaceResolver);
	Result = Query.Evaluate(Schema.DOMDocument);

	While True Do
		
		FieldNode = Result.IterateNext();
		If FieldNode = Undefined Then
			Break;
		EndIf;
		TypeAttribute = FieldNode.Attributes.GetNamedItem("type");
		TypeWithoutNSPrefix = Mid(TypeAttribute.TextContent, StrLen("tns:") + 1);
		
		If SpecifiedTypes.Get(TypeWithoutNSPrefix) = Undefined Then
			Continue;
		EndIf;
		
		FieldNode.SetAttribute("nillable", "true");
		FieldNode.RemoveAttribute("type");
	EndDo;
	
	XMLWriter = New XMLWriter;
	SchemaFileName = GetTempFileName("xsd");
	XMLWriter.OpenFile(SchemaFileName);
	DOMWriter = New DOMWriter;
	DOMWriter.Write(Schema.DOMDocument, XMLWriter);
	XMLWriter.Close();

	Factory = CreateXDTOFactory(SchemaFileName);

	Try
		УдалитьФайлы(SchemaFileName);
	Except
	EndTry;

	Return Factory;

EndFunction

// Returns a name of the type that will be used in an XML file for the specified metadata object.
// Used for reference search and replacement upon import, and for current-config schema editing upon writing.
// 
// Parameters:
//  Value - Metadata object or Ref.
//
// Returns:
//  String - a string that describes a metadata object (in format similar to AccountingRegisterRecordSet.SelfFinancing). 
//
Function XMLRefType(Val Value)

	If TypeOf(Value) = Type("MetadataObject") Then
		MetadataObject = Value;
		ObjectManager = ObjectManagerByFullName(MetadataObject.FullName());
		Ref = ObjectManager.GetRef();
	Else
		MetadataObject = Value.Metadata();
		Ref = Value;
	EndIf;
	
	If ObjectFormsRefType(MetadataObject) Then
		
		Return XDTOSerializer.XMLTypeOf(Ref).TypeName;
		
	Else
		
		ExceptionText = NStr("ru = 'Ошибка при определении XMLТипа ссылки для объекта %1: объект не является ссылочным.'; en = 'Error determining XML Ref type for object %1: this is not a reference object.'");
		ExceptionText = StrReplace(ExceptionText, "%1", MetadataObject.FullName());
		
		Raise ExceptionText;
		
	EndIf;

EndFunction

// Returns an object manager by the passed full name of a metadata object.
// Restriction: business process route points does not process.
//
// Parameters:
//  FullName - String - full name of a metadata object. Example: "Catalog.Company".
//
// Return value:
//  CatalogManager, DocumentManager.
// 
Function ObjectManagerByFullName(FullName)

	NameParts = ParseStringIntoSubstringsArray(FullName);
	
	If NameParts.Count() >= 2 Then
		MOClass = NameParts[0];
		MOName = NameParts[1];
	EndIf;
	
	If Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
	EndIf;
	
	Return Manager[MOName];

EndFunction

Function ParseStringIntoSubstringsArray(Val Str, Separator = ".")

	RowsArray = New Array;
	SeparatorLength = StrLen(Separator);
	While True Do
		Pos = Find(Str, Separator);
		If Pos = 0 Then
			If (TrimAll(Str) <> "") Then
				RowsArray.Add(Str);
			EndIf;
			Return RowsArray;
		EndIf;
		RowsArray.Add(Left(Str, Pos - 1));
		Str = Mid(Str, Pos + SeparatorLength);
	EndDo;

EndFunction

// Substitutes parameters in a string. The maximum number of parameters is 9.
// Parameters in the string have the following format: %<parameter number>. The parameter numbering starts from 1.
//
// Parameters:
//  StringPattern  - String - string pattern with parameters formatted as "%<parameter number>", for 
//                           example, "%1 went to %2".
//  Parameter<n>   - String - parameter value to insert.
//
// Returns:
//  String   - text string with parameters inserted.
//
// Example:
//  StringFunctionsClientServer.SubstituteParametersToString(NStr("en='%1 went to %2.'"), "Jane", 
//  "the zoo") = "Jane went to the zoo."
//
Function SubstituteParametersToString(Val StringPattern,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val Parameter6 = Undefined,
	Val Parameter7 = Undefined, Val Parameter8 = Undefined, Val Parameter9 = Undefined) Export

	StringPattern = StrReplace(StringPattern, "%1", Parameter1);
	StringPattern = StrReplace(StringPattern, "%2", Parameter2);
	StringPattern = StrReplace(StringPattern, "%3", Parameter3);
	StringPattern = StrReplace(StringPattern, "%4", Parameter4);
	StringPattern = StrReplace(StringPattern, "%5", Parameter5);
	StringPattern = StrReplace(StringPattern, "%6", Parameter6);
	StringPattern = StrReplace(StringPattern, "%7", Parameter7);
	StringPattern = StrReplace(StringPattern, "%8", Parameter8);
	StringPattern = StrReplace(StringPattern, "%9", Parameter9);

	Return StringPattern;

EndFunction

UseDataExchangeModeOnImport = True;
ContinueImportOnError = False;
UseFilterByDateForAllObjects = True;
mChildObjectsExportExistence = False;
//mSavedLastExportsCount = 50;

mTypeQueryResult = Тип("QueryResult");
mDeletionDataType = Тип("ObjectDeletion");

mRegisterRecordsColumnsMap = New Соответствие;
ProcessedConstantsCount = 0;
ProcessedRecordSetsCount = 0;
