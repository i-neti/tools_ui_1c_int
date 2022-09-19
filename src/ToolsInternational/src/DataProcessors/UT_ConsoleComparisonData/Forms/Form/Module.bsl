&AtClient
Var ClosingFormConfirmed, RepresentationHeadersAttributes;

#Region Procedure_and_functions

#Region Main
&AtServer
Procedure CompareDataOnServer(StructureParametersFromClient, RepresentationHeadersAttributes, TextErrors)

	//If source А - fail, stored on the client computer
	If Object.BaseTypeA = 3 And Object.ConnectingToExternalBaseADeviceStorageFile = 1 Then
		//Save source file paths
		PathToFileAatKlient = Object.ConnectionToExternalBaseAPathToFile;
		//Creating a temporary file on the serverе
		FileA = GetFromTempStorage(StructureParametersFromClient.TemporaryStorageAddressFileA); 
		PathToFileAatServer = GetTempFileName(Object.ConnectionToExternalBaseAFileFormat);
		FileA.Write(PathToFileAatServer);
		Object.ConnectionToExternalBaseAPathToFile = PathToFileAatServer;
	EndIf;
	
	//If source B is a file stored on the client computer
	If Object.BaseTypeB = 3 And Object.ConnectingToExternalBaseBDeviceStorageFile = 1 Then
		//Save source file paths
		PathToFileBatKlient = Object.ConnectionToExternalBaseBPathToFile;
		//Creating a temporary file on the serverе
		FileB = GetFromTempStorage(StructureParametersFromClient.TemporaryStorageAddressFileB); 
		PathToFileBatServer = GetTempFileName(Object.ConnectionToExternalBaseBFileFormat);
		FileB.Write(PathToFileBatServer);
		Object.ConnectionToExternalBaseBPathToFile = PathToFileBatServer;
	EndIf;
	
	//Compare
	ProcessingObject = FormAttributeToValue("Object");
	ProcessingObject.RefreshDataPeriod();
	ProcessingObject.CompareDataOnServer(TextErrors);
	RepresentationHeadersAttributes = ProcessingObject.RepresentationHeadersAttributes;	
	ValueToFormAttribute(ProcessingObject, "Object");
	
	For AttributesCounter = 1 To NumberOfAttributes Do 
		Items["ResultAttributeA" + AttributesCounter].Title = RepresentationHeadersAttributes["A" + AttributesCounter];
		Items["ResultAttributeB" + AttributesCounter].Title = RepresentationHeadersAttributes["B" + AttributesCounter];
	EndDo;
	
	//If source A is a file stored on the client computer
	If Object.BaseTypeA = 3 And Object.ConnectingToExternalBaseADeviceStorageFile = 1 Then
		//Delete temporary file on the server
		Try
			DeleteFiles(Object.ConnectionToExternalBaseAPathToFile);
		Except EndTry;
		//Restore the path to the original file
		Object.ConnectionToExternalBaseAPathToFile = PathToFileAatKlient;
	EndIf;
	
	//If source B is a file stored on the client computer
	If Object.BaseTypeB = 3 And Object.ConnectingToExternalBaseBDeviceStorageFile = 1 Then
		//Delete temporary file on the server
		Try
			DeleteFiles(Object.ConnectionToExternalBaseBPathToFile);
		Except EndTry;
		//Restore the path to the original file
		Object.ConnectionToExternalBaseBPathToFile = PathToFileBatKlient;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompareDataOnClient()
	
	TextErrors = "";
	StructureParametersOnClient = New Structure;
	StructureParametersOnClient.Insert("TemporaryStorageAddressFileA", "");
	StructureParametersOnClient.Insert("TemporaryStorageAddressFileB", "");
	
	CompareDataOnClientTransferFileA(StructureParametersOnClient, TextErrors);
		
EndProcedure

&AtClient
Procedure CompareDataOnClientTransferFileA(StructureParametersOnClient, TextErrors)
	
	// Transfer file A from client to server
	If Object.BaseTypeA = 3 And Object.ConnectingToExternalBaseADeviceStorageFile = 1 Then
		TemporaryStorageAddressFileA = "";
		BeginPutFile(New NotifyDescription("CompareDataOnClientTransferFileA_End", ThisForm, New Structure("StructureParametersOnClient, TextErrors", StructureParametersOnClient, TextErrors)), TemporaryStorageAddressFileA,Object.ConnectionToExternalBaseAPathToFile,False);
	Else
		CompareDataOnClientTransferFileB(StructureParametersOnClient, TextErrors);
	EndIf;
	
EndProcedure

&AtClient
Procedure CompareDataOnClientTransferFileA_End(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	StructureParametersOnClient = AdditionalParameters.StructureParametersOnClient;
	TextErrors = AdditionalParameters.TextErrors;

	If Result Then
		StructureParametersOnClient.TemporaryStorageAddressFileA = Address;
		CompareDataOnClientTransferFileB(StructureParametersOnClient, TextErrors);
	Else
		TextErrors = StrTemplate(Nstr("ru = 'Не удалось поместить во временное хранилище файл А: ""%1""';en = 'Failed to put file A into temporary storage: ""%1""'")
			, Object.ConnectionToExternalBaseAPathToFile);
		Message(Format(CurrentDate(),"DLF=DT") + ": " + TextErrors);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompareDataOnClientTransferFileB(StructureParametersOnClient, TextErrors)
	
	// Transfer file B from client to server
	If Object.BaseTypeB = 3 And Object.ConnectingToExternalBaseBDeviceStorageFile = 1 Then
		TemporaryStorageAddressFileB = "";
		BeginPutFile(New NotifyDescription("CompareDataOnClientTransferFileB_End"
				, ThisForm
				, New Structure("StructureParametersOnClient, TextErrors", StructureParametersOnClient, TextErrors))
			, TemporaryStorageAddressFileB,Object.ConnectionToExternalBaseBPathToFile
			, False);
		Return;
	Else
		CompareDataOnClientEnd(StructureParametersOnClient, TextErrors);
	EndIf;
	
EndProcedure

&AtClient
Procedure CompareDataOnClientTransferFileB_End(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	StructureParametersOnClient = AdditionalParameters.StructureParametersOnClient;
	TextErrors = AdditionalParameters.TextErrors;
	
	If Result Then
		StructureParametersOnClient.TemporaryStorageAddressFileB = Address;			
	Else
		TextErrors = StrTemplate(Nstr("ru = 'Не удалось поместить во временное хранилище файл Б: ""%1""';en = 'Failed to put file B into temporary storage: ""%1""'")
			, Object.ConnectionToExternalBaseBPathToFile);		
		Message(Format(CurrentDate(),"DLF=DT") + ": " + TextErrors);
		Return;
	EndIf;
	
	CompareDataOnClientEnd(StructureParametersOnClient, TextErrors);

EndProcedure

&AtClient
Procedure CompareDataOnClientEnd(StructureParametersOnClient, TextErrors)
	
	CompareDataOnServer(StructureParametersOnClient, RepresentationHeadersAttributes, TextErrors);
	If Not IsBlankString(TextErrors) Then
		Message(Format(CurrentDate(),"DLF=DT") + ": " + TextErrors);
	EndIf; 
	
	Items.GroupMain.CurrentPage = Items.GroupResultComparison;
	UpdateVisibilityAccessibilityFormItems();

EndProcedure

&AtServer
Procedure RefreshDataPeriod()
	
	ProcessingObject = FormAttributeToValue("Object");
	ProcessingObject.RefreshDataPeriod();
	ValueToFormAttribute(ProcessingObject, "Object");
			
EndProcedure

#EndRegion 

&AtClient
Procedure BeforeCloseEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClosingFormConfirmed = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Function GetDataAsStructure(SaveSpreadsheetDocuments)
	
	FormObject = FormAttributeToValue("Object");
	DataStructure = FormObject.GetDataAsStructureOnServer(SaveSpreadsheetDocuments);
	ValueToFormAttribute(FormObject, "Object");
	
	Return DataStructure;
	
EndFunction

&AtClient
Procedure OpenQueryConstructor(BaseID)    	
	
	QueryText = Object["QueryText" + BaseID];
		
	If Object["BaseType" + BaseID] = 0 Then
		
		If ValueIsFilled(QueryText) Then
			Constructor = New QueryWizard(QueryText);
		Else
			Constructor = New QueryWizard();
		EndIf;
		
		#If ThickClientManagedApplication Then
			If Constructor.DoModal() Then
				Object["QueryText" + BaseID] = Constructor.Text;
			EndIf;
		#ElsIf ThinClient Then
			ConstructorParameters = New Structure("Constructor, BaseID", Constructor, BaseID);
			ConstructorNotifyDescription = New NotifyDescription("ExecuteAfterClosingConstructor", ThisForm, ConstructorParameters);
			Constructor.Show(ConstructorNotifyDescription);
		#EndIf
		
	ElsIf Object["BaseType" + BaseID] = 1 Then
		
		If Object["WorkOptionExternalBase" + BaseID] = 0 Then
			ParameterConnections = 
				"File=""" + Object["ConnectingToExternalBase" + BaseID + "PathBase"]
				+ """;Usr=""" + Object["ConnectingToExternalBase" + BaseID + "Login"]
				+ """;Pwd=""" + Object["ConnectingToExternalBase" + BaseID + "Password"] + """;";	
		Else
			ParameterConnections = 
				"Srvr=""" + Object["ConnectingToExternalBase" + BaseID + "Server"]
				+ """;Ref=""" + Object["ConnectingToExternalBase" + BaseID + "PathBase"] 
				+ """;Usr=""" + Object["ConnectingToExternalBase" + BaseID + "Login"] 
				+ """;Pwd=""" + Object["ConnectingToExternalBase" + BaseID + "Password"] + """;";
		EndIf;

		
		Try
			Application = New COMObject(StrReplace(Object["VersionPlatformExternalBase" + BaseID],".","") + ".Application");
			Connection = Application.Connect(ParameterConnections);
		Except
			MessageText = StrTemplate(Nstr("ru = '%1 : Ошибка при подключении к внешней базе: %2';en = '%1 : Error connecting to external database: %2'")
				, Format(CurrentDate(),"DLF=DT")
				, ErrorDescription());
			Message(MessageText);
			Return;
		EndTry;
			
		If Connection Then
			Constructor = Application.NewObject("QueryWizard");
			Constructor.Text = Object["QueryText" + BaseID];
			If Constructor.DoModal() Then
				Object["QueryText" + BaseID] = Constructor.Text;
			EndIf;
		EndIf;
	 	
	EndIf;
			
EndProcedure

&AtClient
Procedure ExecuteAfterClosingConstructor(Result, ConstructorParameters) Export
	
	If Not IsBlankString(Result) Then
		Object["QueryText" + ConstructorParameters.BaseID] = TrimAll(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCodeToOutputAndProhibitOutputRows()
	
	If Not Object.CodeForOutputRowsEditedManually Then
		
		If Object.ConditionsOutputRows.Count() = 0 Then
			
			Object.CodeForOutputRows = "True";
			
		Else
			
			Object.CodeForOutputRows = "";
		
			For Each RowTP In Object.ConditionsOutputRows Do
				
				CodeFromRowTP = ConvertStringAttributesIntoCodeForOutputAndDisableOutputRows(RowTP);
				Object.CodeForOutputRows =
					Object.CodeForOutputRows 
					+ ?(IsBlankString(Object.CodeForOutputRows), "", Chars.LF + Object.BooleanOperatorForConditionsOutputRows + " ")
					+ CodeFromRowTP;
				
			EndDo;
				
		EndIf;
		
		Object.CodeForOutputRows = "ConditionsOutputRowCompleted = " + Object.CodeForOutputRows + ";";
		
	EndIf;
	
	If Not Object.CodeForProhibitingOutputRowsEditedManually Then
		
		If Object.ConditionsProhibitOutputRows.Count() = 0 Then
			
			Object.CodeForProhibitingOutputRows = "False";
			
		Else
			
			Object.CodeForProhibitingOutputRows = "";
		
			For Each RowTP In Object.ConditionsProhibitOutputRows Do
				
				CodeFromRowTP = ConvertStringAttributesIntoCodeForOutputAndDisableOutputRows(RowTP);
				Object.CodeForProhibitingOutputRows =
					Object.CodeForProhibitingOutputRows 
					+ ?(IsBlankString(Object.CodeForProhibitingOutputRows), "", Chars.LF + Object.BooleanOperatorForProhibitingConditionsOutputRows + " ")
					+ CodeFromRowTP;
				
			EndDo;
				
		EndIf;
		
		Object.CodeForProhibitingOutputRows = "ConditionsProhibitOutputRowCompleted = " + Object.CodeForProhibitingOutputRows + ";";
		
	EndIf;
	
EndProcedure

&AtClient
Function ConvertStringAttributesIntoCodeForOutputAndDisableOutputRows(RowTP)

	CodeFromRowTP = "";
	
	If RowTP.Condition <> "Filled" Then					
					
		If RowTP.ComparisonType = "Value" Then
			If TypeOf(RowTP.ComparedValue) = Type("Date") Then 
				RightSide = 
					"Date("
					+ Year(RowTP.ComparedValue)
					+ ","
					+ Month(RowTP.ComparedValue)
					+ ","
					+ Day(RowTP.ComparedValue)
					+ ","
					+ Hour(RowTP.ComparedValue)
					+ ","
					+ Minute(RowTP.ComparedValue)
					+ ","
					+ Second(RowTP.ComparedValue)
					+ ")";
			ElsIf TypeOf(RowTP.ComparedValue) = Type("Number") Then 
				RightSide = String(RowTP.ComparedValue);
			ElsIf TypeOf(RowTP.ComparedValue) = Type("String") Then 
				RightSide = """" + String(RowTP.ComparedValue) + """";
			ElsIf TypeOf(RowTP.ComparedValue) = Type("Boolean") Then 
				If RowTP.ComparedValue Then
					RightSide = "True";
				Else
					RightSide = "False";
				EndIf;
			Else
				RightSide = String(RowTP.ComparedValue);
			EndIf;
			
		Else
			RightSide = RowTP.NameComparedAttribute2;
		EndIf;
		
		CodeFromRowTP =
			RowTP.NameComparedAttribute
			+ " "
			+ RowTP.Condition
			+ " "
			+ RightSide;
		
	Else
		
		CodeFromRowTP =
			"ValueIsFilled("
			+ RowTP.NameComparedAttribute
			+ ")";
		
	EndIf;
	
	Return CodeFromRowTP;	

EndFunction

&AtServer
Procedure GetParametersFromQueryOnServer(BaseID)
	
	If IsBlankString(Object["QueryText" + BaseID]) Then	
		Return;
	EndIf;
	
	TextErrors = "";
	
	//Current
	If Object["BaseType" + BaseID] = 0 Then
		
		Query = New Query();
		
	//Outer
	ElsIf Object["BaseType" + BaseID] = 1 Then
		
		If Object["WorkOptionExternalBase" + BaseID] = 0 Then
			ParameterConnections = 
				"File=""" + Object["ConnectingToExternalBase" + BaseID + "PathBase"]
				+ """;Usr=""" + Object["ConnectingToExternalBase" + BaseID + "Login"]
				+ """;Pwd=""" + Object["ConnectingToExternalBase" + BaseID + "Password"] + """;";	
		Else
			ParameterConnections = 
				"Srvr=""" + Object["ConnectingToExternalBase" + BaseID + "Server"]
				+ """;Ref=""" + Object["ConnectingToExternalBase" + BaseID + "PathBase"] 
				+ """;Usr=""" + Object["ConnectingToExternalBase" + BaseID + "Login"] 
				+ """;Pwd=""" + Object["ConnectingToExternalBase" + BaseID + "Password"] + """;";
		EndIf;
				
		Try
			COMConnector = New COMObject(Object["VersionPlatformExternalBase" + BaseID] + ".COMConnector");
			Connection = COMConnector.Connect(ParameterConnections);
		Except
			TextError = StrTemplate(Nstr("ru = '%1: Ошибка при подключении к внешней базе: %2';en = '%1: Error connecting to external database: %2'")
				, Format(CurrentDate(),"DLF=DT")
				, ErrorDescription());
			Message(TextError);
			TextErrors = TextErrors + Chars.LF + TextError;
			Return;
		EndTry;

		Query = Connection.NewObject("Query");		
	
	EndIf;
	
	Query.Text = Object["QueryText" + BaseID];
	
	Try
		QueryOptions = Query.FindParameters();
	Except
		TextError = StrTemplate(Nstr("ru = '%1: Ошибка при получении списка параметров: %2';en = '%1: Error getting parameter list: %2'")
			, Format(CurrentDate(),"DLF=DT")
			,  ErrorDescription());
		Message(TextError);
		Return;
	EndTry;
	
	For Each QueryParameter In QueryOptions Do
		
		ParameterName = QueryParameter.Name;
		If ParameterName = "ValidFrom" Or ParameterName = "ValidTo" Then
			Continue;
		EndIf;
		
		FoundParameters = Object["ParameterList" + BaseID].FindRows(New Structure("ParameterName", ParameterName));
		If FoundParameters.Count() = 0 Then
			CurrentParameter = Object["ParameterList" + BaseID].Add();
			CurrentParameter.ParameterName = ParameterName;
		Else
			CurrentParameter = FoundParameters[0];
		EndIf; 
		
		CurrentParameter.ParameterValue = QueryParameter.ValueType.AdjustValue(CurrentParameter.ParameterValue);		
		CurrentParameter.ParameterType = String(TypeOf(CurrentParameter.ParameterValue));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FillColumnTypesKeyInAllRows()
	
	For Each RowTP In Object.Result Do
		
		If Object.VisibilityKey1 Then
			RowTP.ColumnType1Key = TypeOf(RowTP.Key1);
		EndIf;
		
		If Object.VisibilityKey2 Then
			RowTP.ColumnType2Key = TypeOf(RowTP.Key2);
		EndIf;
		
		If Object.VisibilityKey3 Then
			RowTP.ColumnType3Key = TypeOf(RowTP.Key3);
		EndIf;
	
	EndDo; 
		
EndProcedure

&AtServer
Function UploadResultToFileAtServer(ForClient, RepresentationHeadersAttributes)
	
	AttributeObject = FormAttributeToValue("Object");
	AttributeObject.RepresentationHeadersAttributes = RepresentationHeadersAttributes;
	FileAddress = AttributeObject.UploadResultToFileAtServer(ForClient);
	Return FileAddress;
	
EndFunction

&AtClient
Procedure CommandUploadResultToFileOnClientEndQuestion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.None Then
		Return;
	EndIf;
	
	FileAddress = UploadResultToFileAtServer(True, RepresentationHeadersAttributes);
	If FileAddress = Undefined Then
		Return;
	EndIf;
	
	FileData = GetFromTempStorage(FileAddress);
	SaveFileDialog = New FileDialog(FileDialogMode.Save);
	SaveFileDialog.FullFileName = Object.PathToDownloadFile;
	SaveFileDialog.Filter = "*." + Object.UploadFileFormat + "|*." + Object.UploadFileFormat;
	SaveFileDialog.Title = Nstr("ru = 'Выберите каталог';en = 'Select catalog'"); 
	
	SaveFileDialog.Show(New NotifyDescription("CommandUploadResultToFileOnClientEnd", ThisForm, New Structure("FileData, SaveFileDialog", FileData, SaveFileDialog)));

EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnClientEnd(SelectedFiles, AdditionalParameters) Export
	
	FileData = AdditionalParameters.FileData;
	SaveFileDialog = AdditionalParameters.SaveFileDialog;
	         	
	If (SelectedFiles <> Undefined) Then
		
		FileData.Write(SaveFileDialog.FullFileName);
		MessageText = StrTemplate(NStr("ru = '%1: Выгрузка в файл завершена (%2)';en = '%1: Upload to file completed (%2)'")
			, Format(CurrentDate(),"DF='yyyy.MM.dd HH.mm.ss'")
			, SaveFileDialog.FullFileName);
		Message(MessageText);		
		
	Else
		MessageText = StrTemplate(NStr("ru = '%1: Выгрузка в файл отменена';en = '%1: Upload to file canceled'")
			, Format(CurrentDate(),"DF='yyyy.MM.dd HH.mm.ss'"));
		Message(MessageText);		
		
	EndIf;

EndProcedure

&AtServer
Function GetSpreadsheetDocumentDataFromSourceAtServer(BaseID, MaxRows = 0, OnlyDuplicates = False, Connection = Undefined)

	TextError = "";
	ProcessingObject = FormAttributeToValue("Object");
		
	If Not ProcessingObject.CheckFillingAttributes(BaseID) Then
		Return Undefined;
	EndIf;
	
	Connection = Undefined;
	ValueTable = ProcessingObject.ReadDataAndGetValueTable(BaseID, TextError, Connection);
	
	If ValueTable = Undefined Then
		Message(Format(CurrentDate(),"DLF=DT") + ": " + TextError);
		Return Undefined;
	EndIf;
	
	Template = ProcessingObject.GetTemplate("PreviewForm");
	SpreadsheetDocument = New SpreadsheetDocument;
	
	//Key 1
	KeyName1 = ValueTable.Columns.Get(0).Name;
	ColumnsWithKeyRow = KeyName1;
	AreaHeader = Template.GetArea("Header|Key1");
	SpreadsheetDocument.Put(AreaHeader);
	
	//Key 2
	If Object.NumberColumnsInKey > 1 Then
		KeyName2 = ValueTable.Columns.Get(1).Name;
		ColumnsWithKeyRow = ColumnsWithKeyRow + "," + KeyName2;
		AreaHeader = Template.GetArea("Header|Key2");
		SpreadsheetDocument.Join(AreaHeader);
	EndIf;
	
	//Key 3
	If Object.NumberColumnsInKey > 2 Then
		KeyName3 = ValueTable.Columns.Get(2).Name;
		ColumnsWithKeyRow = ColumnsWithKeyRow + "," + KeyName3;
		AreaHeader = Template.GetArea("Header|Key3");
		SpreadsheetDocument.Join(AreaHeader);
	EndIf;
	
	ValueTable.Sort(ColumnsWithKeyRow);
	
	ValueTable_Grouped = ValueTable.Copy(); 
	
	ColumnNameNumberOfRowsDataSource = "NumberOfRowsDataSource_" + StrReplace(String(New UUID), "-", "");
	ValueTable_Grouped.Columns.Add(ColumnNameNumberOfRowsDataSource);
	
	AreaAttributes = Template.GetArea("Header|Attributes");
	SpreadsheetDocument.Join(AreaAttributes);
		
	ValueTable_Grouped.FillValues(1,ColumnNameNumberOfRowsDataSource);	
	ValueTable_Grouped.Collapse(ColumnsWithKeyRow, ColumnNameNumberOfRowsDataSource);
	ValueTable_Grouped.Indexes.Add(ColumnsWithKeyRow);
		
	NumberOfColumnVT = ValueTable.Columns.Count();
	RowsCounter = 0;
	For Each RowVT In ValueTable Do
		
		RowsCounter = RowsCounter + 1;
		
		If MaxRows > 0 And RowsCounter > MaxRows Then
			Break;
		EndIf;
		
		If Connection = Undefined Then
			SelectionStructure = New Structure;
		Else
			SelectionStructure = Connection.NewObject("Structure");
		EndIf;
				
		Key1 = RowVT.Get(0);
		SelectionStructure.Insert(KeyName1, Key1);
		
		If Object.NumberColumnsInKey > 1 Then
			Key2 = RowVT.Get(1);
			SelectionStructure.Insert(KeyName2, Key2);
		Else
			Key2 = Undefined;
		EndIf;
		
		If Object.NumberColumnsInKey > 2 Then
			Key3 = RowVT.Get(2);
			SelectionStructure.Insert(KeyName3, Key3);
		Else
			Key3 = Undefined;
		EndIf;
		
		RowsGroupedVT = ValueTable_Grouped.FindRows(SelectionStructure);
		NumberOfRowsByKey = ?(RowsGroupedVT.Count(), RowsGroupedVT.Get(0)[ColumnNameNumberOfRowsDataSource], 0);
		If NumberOfRowsByKey > 1 Then
			AreaNameRow = "RowWithErrors";
		Else
			If OnlyDuplicates Then
				Continue;
			EndIf;
			AreaNameRow = "RowWithoutErrors";
		EndIf;
		
		AreaRow = Template.GetArea(AreaNameRow + "|Key1");
		AreaRow.Parameters.Key1 = String(Key1);
		SpreadsheetDocument.Put(AreaRow);
		
		If Object.NumberColumnsInKey > 1 Then
			AreaRow = Template.GetArea(AreaNameRow + "|Key2");
			AreaRow.Parameters.Key2 = String(Key2);
			SpreadsheetDocument.Join(AreaRow);
		EndIf;
		
		If Object.NumberColumnsInKey > 2 Then
			AreaRow = Template.GetArea(AreaNameRow + "|Key3");
			AreaRow.Parameters.Key3 = String(Key3);
			SpreadsheetDocument.Join(AreaRow);
		EndIf;		
		
		AreaRow = Template.GetArea(AreaNameRow + "|Attributes");
		AreaRow.Parameters.NumberOfRows = NumberOfRowsByKey; 
				
		AttributeNumberOffset = Object.NumberColumnsInKey;
		For ColumnCounter = 1 To Min(NumberOfAttributes, NumberOfColumnVT - Object.NumberColumnsInKey) Do
			AreaRow.Parameters["Attribute" + ColumnCounter] = String(RowVT.Get(ColumnCounter + AttributeNumberOffset - 1));
		EndDo;
		
		SpreadsheetDocument.Join(AreaRow);
			
	EndDo;
	
	ValueTable = Undefined;
	ValueTable_Grouped = Undefined;
	Connection = Undefined;
	
	SpreadsheetDocument.Protection = False;
	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
		
EndFunction


#Region Visibility_Availability_of_form_elements

&AtClient
Procedure UpdateVisibilityAccessibilityFormItems()
		
	UpdateVisibilityAccessibilityFormItemsByBaseID("A");
	UpdateVisibilityAccessibilityFormItemsByBaseID("B");
	//Items.ResultKey2.Visible = Object.NumberColumnsInKey > 1;
	//Items.ResultKey3.Visible = Object.NumberColumnsInKey > 2;
	//Items.ResultColumnType1Key.Visible = Object.DisplayKeyColumnTypes;
	//Items.ResultColumnType2Key.Visible = Object.DisplayKeyColumnTypes And Object.NumberColumnsInKey > 1;
	//Items.ResultColumnType3Key.Visible = Object.DisplayKeyColumnTypes And Object.NumberColumnsInKey > 2;
	Items.ResultCommandVisibilityTypesColumnsKey.Check = Object.DisplayKeyColumnTypes;
	Items.ResultCommandVisibilityKey2.Visible = Object.NumberColumnsInKey > 1;
	Items.ResultCommandVisibilityKey3.Visible = Object.NumberColumnsInKey > 2;
	UpdateVisibilityKeysTP();
		
	//If Object.PeriodTypeAbsolute Then
	If Object.PeriodType = 1 Then
		Items.AbsolutePeriodValue.ReadOnly = True;
		Items.GroupRelativePeriod.Visible = True;
		Items.GroupSlaveRelativePeriod.Visible = False;
	ElsIf Object.PeriodType = 2 Then	
		Items.AbsolutePeriodValue.ReadOnly = True;
		Items.GroupRelativePeriod.Visible = True;
		Items.GroupSlaveRelativePeriod.Visible = True;
	Else
		Items.AbsolutePeriodValue.ReadOnly = False;
		Items.GroupRelativePeriod.Visible = False;
	EndIf;
	
	UpdateHeader();
	UpdateAttributesArbitraryCode();
	UpdateVisibilityAvailabilityPage_GroupConditionsProhibitOutputRows();
	UpdateVisibilityAvailabilityPage_GroupConditionsOutputRows();
	
EndProcedure

&AtClient
Procedure UpdateAttributesArbitraryCode()
	
	For CounterItems = 1 To 3 Do
		UpdateVisibilityAvailabilityAttribute_ArbitraryCode(CounterItems, "A"); 
		UpdateVisibilityAvailabilityAttribute_ArbitraryCode(CounterItems, "B");
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityAttribute_ArbitraryCode(FormItemNumber, BaseID)
	
	Items["ArbitraryKeyCode" + FormItemNumber + BaseID].Visible = 
		Object["ExecuteArbitraryKeyCode" + FormItemNumber + BaseID];
	
EndProcedure

&AtClient
Procedure UpdateHeader()
	
	ThisForm.Title = "КСД: " + Object.Title;
	
EndProcedure

&AtClient
Procedure UpdateTotalsByAttributesTP(BaseID)
	
	For AttributesCounter = 1 To NumberOfAttributes Do
	
		AttributeName = "Attribute" + BaseID + AttributesCounter;
		Items["Result" + AttributeName].FooterText = ?(Object["SettingsFile" + BaseID].Count() >= AttributesCounter И Object["SettingsFile" + BaseID][AttributesCounter - 1].CalculateTotal
			, Object["ValueTotal" + AttributeName]
			, "");
	
	EndDo; 
		
EndProcedure

&AtClient
Procedure UpdateVisibilityAccessibilityFormItemsByBaseID(BaseID)
	
	Items["GroupProcessKey2" + BaseID].Visible = Object.NumberColumnsInKey > 1;
	Items["GroupProcessKey3" + BaseID].Visible = Object.NumberColumnsInKey > 2;
	
	Items["GroupPageQueryParameters" + BaseID].Visible = Object["BaseType" + BaseID] <= 1;
	Items["ParameterList"  + BaseID + "CommandGetQueryParameters"  + BaseID].Visible = Object["BaseType" + BaseID] <= 2;
	
	//Table 
	Items["GroupPageTable" + BaseID].Visible = Object["BaseType" + BaseID] = 4;
		
//#Region _1C_8_внешняя
	If Object["BaseType" + BaseID] = 1 Then
		
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= True;
		Items["GroupVariantVersionPlatformsBase" + BaseID].Visible 						= True;
		If Object["WorkOptionExternalBase" + BaseID] = 1 Then
			Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 				= True;
			Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 			= Nstr("ru = 'Имя базы';en = 'Base name'");
		Else
			Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 				= False;
			Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 			= Nstr("ru = 'Путь к базе';en = 'Path to base'");
		EndIf;
		Items["ConnectionToExternalBase" + BaseID + "DriverSQL"].Visible 				= False;
		Items["GroupPageTextQuery" + BaseID].Visible 							= True;
		Items["GroupPageTextQuery" + BaseID].Title							= Nstr("ru = 'Тект запроса';en = 'Query text'");
		Items["DecorationQueryText" + BaseID].Visible									= True;
		Items["GroupQueryText" + BaseID + "Commands"].Visible 						= True;
		
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= False;	
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= True;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= True;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= True;
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["CastKey2ToString" + BaseID].Visible 								= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["CastKey3ToString" + BaseID].Visible 								= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKeyToString" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey2ToString" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey3ToString" + BaseID];
		
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= False;
							
//#EndRegion

//#Region SQL
	ElsIf Object["BaseType" + BaseID] = 2 Then
		
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= True;
		Items["GroupVariantVersionPlatformsBase" + BaseID].Visible 						= False;
		Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 					= True;
		Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 				= Nstr("ru = 'Имя базы данных';en = 'Database name'");
		Items["ConnectionToExternalBase" + BaseID + "DriverSQL"].Visible 				= True;
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= False;
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;		
		Items["GroupPageTextQuery" + BaseID].Visible 							= True;
		Items["GroupPageTextQuery" + BaseID].Title							= Nstr("ru = 'Тект запроса';en = 'Query text'");
		Items["DecorationQueryText" + BaseID].Visible									= True;
		Items["GroupQueryText" + BaseID + "Commands"].Visible 						= False;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= True;
		Items["CastKey2ToString" + BaseID].Visible 								= True;
		Items["CastKey3ToString" + BaseID].Visible 								= True;
		//Casting is performed simply to a string without specifying the length
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= False;
				                                                                       						
//#EndRegion 

//#Region Файл
	ElsIf Object["BaseType" + BaseID] = 3 Then
		
		FileFormatXML = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "XML";
		FileFormatXLS = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "XLS";
		FileFormatDOC = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "DOC";
				
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= False;
		Items["GroupPageTextQuery" + BaseID].Visible							= False;
		
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= True;
		Items["GroupSettingsConnectionsToFileGeneral" + BaseID].Visible					= True;
		Items["GroupSettingsConnectionsToXMLJSONA" + BaseID].Visible 				= FileFormatXML;
		Items["GroupSettingsConnectionsToXMLA" + BaseID].Visible 					= FileFormatXML;
		Items["GroupSettingsConnectionsToNonXMLAFile" + BaseID].Visible					= Not FileFormatXML;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= FileFormatXLS Or FileFormatDOC;
		
		ConnectionToExternalBaseTitle = ?(FileFormatXLS
			, Nstr("ru = 'Номер книги';en = 'Book number'")
			, Nstr("ru = 'Номер таблицы';en = 'Table number'"));
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Title		= ConnectionToExternalBaseTitle;
		
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= True;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= Not FileFormatXML;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= Not FileFormatXML;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= Not FileFormatXML;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= FileFormatXML;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= FileFormatXML;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= FileFormatXML;
				
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not FileFormatXML;
		Items["CastKey2ToString" + BaseID].Visible 								= Not FileFormatXML;
		Items["CastKey3ToString" + BaseID].Visible 								= Not FileFormatXML;
		//Casting is performed simply to a string without specifying the length
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= Not FileFormatXML;
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= FileFormatXML;
							
//#EndRegion 

//#Region Table
	ElsIf Object["BaseType" + BaseID] = 4 Then
		
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= False;
		Items["GroupPageTextQuery" + BaseID].Visible 							= False;
		
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= True;
		Items["GroupSettingsConnectionsToFileGeneral" + BaseID].Visible					= False;
		Items["GroupSettingsConnectionsToXMLJSONA" + BaseID].Visible				= False;
		Items["GroupSettingsConnectionsToXMLA" + BaseID].Visible					= False;
		Items["GroupSettingsConnectionsToNonXMLAFile" + BaseID].Visible					= True;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= False;
		
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible							= True;
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= True;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= True;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= True;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= True;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= True;
		Items["CastKey2ToString" + BaseID].Visible 								= True;
		Items["CastKey3ToString" + BaseID].Visible 								= True;
		//Casting is performed simply to a string without specifying the length
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= False;
		
//#EndRegion 

//#Region _1C_7_7_external
	ElsIf Object["BaseType" + BaseID] = 5 Then
		
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= True;
		Items["GroupVariantVersionPlatformsBase" + BaseID].Visible 						= False;
		Items["ConnectionToExternalBase" + BaseID + "DriverSQL"].Visible 				= False;
		Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 					= False;
		Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 				= Nstr("ru = 'Путь к базе';en = 'Path to base'");
		Items["GroupPageTextQuery" + BaseID].Visible 							= True;
		Items["GroupPageTextQuery" + BaseID].Title							= Nstr("ru = 'Тект запроса';en = 'Query text'");
		Items["DecorationQueryText" + BaseID].Visible									= True;
		Items["GroupQueryText" + BaseID + "Commands"].Visible 						= False;
		
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= False;
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;     		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;
		
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= True;
		Items["CastKey2ToString" + BaseID].Visible 								= True;
		Items["CastKey3ToString" + BaseID].Visible 								= True;
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= False;

//#EndRegion 

//#Region Строка_JSON
	ElsIf Object["BaseType" + BaseID] = 6 Then
	
		Items["GroupPageTextQuery" + BaseID].Visible 							= True;
		Items["GroupPageTextQuery" + BaseID].Title							= NStr("ru = 'Строка JSON';en = 'JSON string'");
		
		Items["DecorationQueryText" + BaseID].Visible									= False;
		Items["GroupQueryText" + BaseID + "Commands"].Visible 						= False;
		
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= False;
		
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= True;
		Items["GroupSettingsConnectionsToFileGeneral" + BaseID].Visible					= False;
		Items["GroupSettingsConnectionsToXMLJSONA" + BaseID].Visible 				= True;
		Items["GroupSettingsConnectionsToXMLA" + BaseID].Visible 					= False;
		Items["GroupSettingsConnectionsToNonXMLAFile" + BaseID].Visible					= False;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= False;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Title		= False;
		
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= True;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= True;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= True;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= True;
				
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= False;
		Items["CastKey2ToString" + BaseID].Visible 								= False;
		Items["CastKey3ToString" + BaseID].Visible 								= False;
		//Casting is performed simply to a string without specifying the length
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= True;
							
//#EndRegion 

//#Region _1С_8_текущая
	Else 
		
		Items["GroupOptionSettingsConnectionsBase" + BaseID].Visible 				= False;
		Items["GroupPageTextQuery" + BaseID].Visible 							= True;
		Items["GroupPageTextQuery" + BaseID].Title							= Nstr("ru = 'Тект запроса';en = 'Query text'");
		Items["DecorationQueryText" + BaseID].Visible									= True;
		Items["GroupQueryText" + BaseID + "Commands"].Visible 						= True;
		
		Items["GroupSettingsConnectionsFile" + BaseID].Visible 						= False;
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible		= True;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= True;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= True;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["CastKey2ToString" + BaseID].Visible 								= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["CastKey3ToString" + BaseID].Visible 								= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKeyToString" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey2ToString" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey3ToString" + BaseID];
		
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= False;
							
	EndIf;

//#EndRegion

	
	UpdateVisibilityAttributesTP(BaseID);
	UpdateTotalsByAttributesTP(BaseID);
				
EndProcedure

&AtClient
Procedure UpdateVisibilityKeysTP(Форсировать = False)
	
	UpdateVisibilityAttributeTP("Key1");
	UpdateVisibilityAttributeTP("Key2");
	UpdateVisibilityAttributeTP("Key3");
		
EndProcedure

&AtClient
Procedure UpdateVisibilityAttributesTP(BaseID = "")
	
	If IsBlankString(BaseID) Then
		UpdateVisibilityAttributeTP("NumberOfRecordsA");
		UpdateVisibilityAttributeTP("NumberOfRecordsB");
	Else 
		UpdateVisibilityAttributeTP("NumberOfRecords" + BaseID);
	EndIf;
	
	For Counter = 1 To 5 Do
		
		If IsBlankString(BaseID) Then
			UpdateVisibilityAttributeTP("AttributeA" + Counter);
			UpdateVisibilityAttributeTP("AttributeB" + Counter);
		Else
			UpdateVisibilityAttributeTP("Attribute" + BaseID + Counter);
		EndIf; 
		
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateVisibilityAttributeTP(AttributeName)
	
	VisibilityColumn = Object["Visibility" + AttributeName];
	Items["ResultCommandVisibility" + AttributeName].Check = VisibilityColumn;
	
	If ВРег(Лев(AttributeName, 4)) = "KEY" Then
		NumberKey = Mid(AttributeName,5,1);
		Items["Result" + AttributeName].Visible = VisibilityColumn И Object.NumberColumnsInKey >= Number(NumberKey);
		Items["ResultColumnType" + NumberKey + "Key"].Visible = Object.DisplayKeyColumnTypes И Object["VisibilityKey" + NumberKey] И Object.NumberColumnsInKey >= Number(NumberKey);
	Else
		Items["Result" + AttributeName].Visible = VisibilityColumn;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityItemsRelationalOperation(DisplayMode = 0)
	
	Items.CompareData.Enabled = Object.RelationalOperation > 0;
	For CounterOperations = 1 To 7 Do 
		
		If CounterOperations = Object.RelationalOperation Then
			If DisplayMode = 1 Then
				ThisForm["Operation" + CounterOperations] = ThisForm["ActiveOperationA1"];
			ElsIf DisplayMode = 2 Then
				ThisForm["Operation" + CounterOperations] = ThisForm["ActiveOperationA" + (4 + ?(CounterOperations > 1, CounterOperations + 2, CounterOperations - 1) % 2)];
			Else
				ThisForm["Operation" + CounterOperations] = ThisForm["ActiveOperation" + CounterOperations];
			EndIf;
						
		Else
			If DisplayMode = 1 Then
				ThisForm["Operation" + CounterOperations] = ThisForm["ActiveOperation" + CounterOperations];
			ElsIf DisplayMode = 2 Then
				ThisForm["Operation" + CounterOperations] = ThisForm["ActiveOperationA" + (2 + ?(CounterOperations > 1, CounterOperations + 2, CounterOperations - 1) % 2)];
			Else
				ThisForm["Operation" + CounterOperations] = ThisForm["InactiveOperation" + CounterOperations];
			EndIf;			
		EndIf;
		
	EndDo;		
	
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput()
	
	Items.BooleanOperatorForConditionsOutputRows.ReadOnly 		= Object.CodeForOutputRowsEditedManually;
	Items.ConditionsOutputRows.ReadOnly 								= Object.CodeForOutputRowsEditedManually;
	Items.BooleanOperatorForProhibitingConditionsOutputRows.ReadOnly 	= Object.CodeForProhibitingOutputRowsEditedManually;
	Items.ConditionsProhibitOutputRows.ReadOnly 						= Object.CodeForProhibitingOutputRowsEditedManually;
	
	Items.CodeForOutputRows.ReadOnly 								= Not Object.CodeForOutputRowsEditedManually;
	Items.CodeForProhibitingOutputRows.ReadOnly 						= Not Object.CodeForProhibitingOutputRowsEditedManually;
	
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityPage_GroupConditionsOutputRows()
	
	Items.GroupConditionsOutputRows.BgColor = ?(Object.ConditionsOutputRowsDisabled, WebColors.Pink, ColorBackgroundFormDefault);;
		
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityPage_GroupConditionsProhibitOutputRows()
	
	Items.GroupConditionsProhibitOutputRows.BgColor = ?(Object.ConditionsProhibitOutputRowsDisabled, WebColors.Pink, ColorBackgroundFormDefault);;
		
EndProcedure

&AtClient
Procedure UpdateVisibilityAvailabilityOrderSortTableDifferences()
	
	Items.OrderSortTableDifferences.ReadOnly = Not Object.SortTableDifferences;
	
EndProcedure

#EndRegion 


#Region Settings

#Region Save
&AtClient
Procedure SaveSettingsToFileAtClient(SaveSpreadsheetDocuments = False)
	
	Mode = FileDialogMode.Save;
	SelectionDialog = New FileDialog(Mode);
	SelectionDialog.FullFileName = Object.Title;
	Filter = "File xml (*.xml)|*.xml";
	SelectionDialog.Filter = Filter;
	SelectionDialog.Title = Nstr("ru = 'Укажите файл для сохранения настроек';en = 'Specify a file to save settings'");   

	SelectionDialog.Show(New NotifyDescription("SaveSettingsToFileAtClientEnd", ThisForm, New Structure("SelectionDialog,SaveSpreadsheetDocuments", SelectionDialog, SaveSpreadsheetDocuments)));
	
EndProcedure

&AtClient
Procedure SaveSettingsToFileAtClientEnd(SelectedFiles, AdditionalParameters) Export
	
	SelectionDialog = AdditionalParameters.SelectionDialog;
	SaveSpreadsheetDocuments = AdditionalParameters.SaveSpreadsheetDocuments;
	                             	
	If (SelectedFiles <> Undefined) Then
		
		Object.Title = Mid(SelectionDialog.FullFileName, StrFind(SelectionDialog.FullFileName, "\", SearchDirection.FromEnd) + 1);
		Address = SaveSettingsToFileAtServer(SaveSpreadsheetDocuments);
		BinaryData = GetFromTempStorage(Address);
		BinaryData.Write(SelectionDialog.FullFileName);
		
	EndIf;

EndProcedure

&AtClient
Procedure SaveSettingsToDatabaseAtClient(SaveSpreadsheetDocuments = False);
	
	If ValueIsFilled(Object.RelatedDataComparisonOperation)  Then
	
		QueryText = StrTemplate(Nstr("ru = 'Обновить элемент справочника ""%1""?';en = 'Update catalog item ""%1""?'")
			, Object.RelatedDataComparisonOperation);
		ShowQueryBox(New NotifyDescription("SaveToRelatedOperationEnd"
				, ThisObject
				, New Structure("SelectCatalogItemToSave, SaveSpreadsheetDocuments", True, SaveSpreadsheetDocuments))
			, QueryText
			, QuestionDialogMode.YesNo);
		
	Else
		
		OpenOperationSelectionFormForRecording(SaveSpreadsheetDocuments);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveToRelatedOperationEnd(Result, AdditionalParameters) Export
	
	SaveSpreadsheetDocuments = AdditionalParameters.SaveSpreadsheetDocuments;
	SelectCatalogItemToSave = AdditionalParameters.SelectCatalogItemToSave;
	OnCloseForm = AdditionalParameters.Property("OnCloseForm") And AdditionalParameters.OnCloseForm;
	
	If Result = DialogReturnCode.Yes Then
		
		SaveSettingsToBaseAtServer(Object.RelatedDataComparisonOperation, SaveSpreadsheetDocuments);
		UpdateHeader();
		
	//Click button Save to database
	ElsIf SelectCatalogItemToSave = True And OnCloseForm = False Then
		
		OpenOperationSelectionFormForRecording();
				
	EndIf;

EndProcedure

&AtClient
Procedure SaveSelectedOperationEnd(Result, AdditionalParameters) Export
	
	SaveSpreadsheetDocuments = AdditionalParameters.SaveSpreadsheetDocuments;
	
	SelectedItem = Result;
	If SelectedItem <> Undefined Then
		
		SaveSettingsToBaseAtServer(SelectedItem, SaveSpreadsheetDocuments);
		UpdateHeader();
				
	EndIf;

EndProcedure

&AtServer
Function SaveSettingsToFileAtServer(SaveSpreadsheetDocuments)
	
	PathToFile = GetTempFileName("xml");
	Data = GetDataAsStructure(SaveSpreadsheetDocuments); 
	ExternalStorage = New ValueStorage(Data);
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(PathToFile, "UTF-8");
	XDTOSerializer.WriteXML(XMLWriter, ExternalStorage);
	XMLWriter.Close();
	Address = PutToTempStorage(New BinaryData(PathToFile));
	DeleteFiles(PathToFile);
	
	Return Address;
			
EndFunction

&AtServer
Procedure SaveSettingsToBaseAtServer(SelectedItem, SaveSpreadsheetDocuments = False)

	FormObject = FormAttributeToValue("Object");
	FormObject.SaveSettingsToBaseAtServer(SelectedItem, SaveSpreadsheetDocuments);
	ValueToFormAttribute(FormObject, "Object");
		
EndProcedure

#EndRegion 


#Region Load
&AtClient
Procedure OpenSettingsFromFileAtClient(Val Notification, UploadSpreadsheetDocuments = False)

	Mode = FileDialogMode.Opening;
	SelectionDialog = New FileDialog(Mode);
	SelectionDialog.FullFileName = "";
	Filter = "File xml (*.xml)|*.xml";
	SelectionDialog.Filter = Filter;
	SelectionDialog.Title = Nstr("ru = 'Укажите файл с настройками';en = 'Specify the settings file'");   

	SelectionDialog.Show(New NotifyDescription("OpenSettingsFromFileAtClientEnd"
		, ThisForm
		, New Structure("SelectionDialog, Notification, UploadSpreadsheetDocuments", SelectionDialog, Notification, UploadSpreadsheetDocuments)));

EndProcedure

&AtClient
Procedure OpenSettingsFromFileAtClientEnd(SelectedFiles, AdditionalParameters) Export
	
	SelectionDialog = AdditionalParameters.SelectionDialog;
	Notification = AdditionalParameters.Notification;	
	UploadSpreadsheetDocuments = AdditionalParameters.UploadSpreadsheetDocuments;	
	
	If (SelectedFiles <> Undefined) Then
		
		Address = PutToTempStorage(New BinaryData(SelectionDialog.FullFileName));
		OpenSettingsFromFileAtServer(Address, UploadSpreadsheetDocuments);
		FirstChar = StrFind(SelectionDialog.FullFileName, "\", SearchDirection.FromEnd) + 1;
		LastChar = StrFind(SelectionDialog.FullFileName, ".", SearchDirection.FromEnd);
		Object.Title = Mid(SelectionDialog.FullFileName, FirstChar, LastChar - FirstChar);
		UpdateVisibilityAccessibilityFormItems();
		UpdateVisibilityAvailabilityItemsRelationalOperation();
		UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput();
		UpdateVisibilityAvailabilityOrderSortTableDifferences();
		
	EndIf;
	
	ExecuteNotifyProcessing(Notification);

EndProcedure

&AtServer
Procedure OpenSettingsFromFileAtServer(Address, UploadSpreadsheetDocuments = False)
	
	PathToFile = GetTempFileName("xml");
	BinaryData = GetFromTempStorage(Address);
	BinaryData.Write(PathToFile);
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile,,,"UTF-8");
	ExternalStorage = XDTOSerializer.ReadXML(XMLReader);
	Data = ExternalStorage.Get();
	FillPropertyValues(Object, Data);
	
	If Data.Property("ValueTableConditionsOutputRows") Then
		Object.ConditionsOutputRows.Load(Data.ValueTableConditionsOutputRows);
	Else
		Object.ConditionsOutputRows.Clear();
	EndIf;
	
	If Data.Property("ValueTableConditionsProhibitOutputRows") Then
		Object.ConditionsProhibitOutputRows.Load(Data.ValueTableConditionsProhibitOutputRows);
	Else
		Object.ConditionsProhibitOutputRows.Clear();
	EndIf;
	
	If Data.Property("ValueTableSettingsFileA") Then
		Object.SettingsFileA.Load(Data.ValueTableSettingsFileA);
	Else
		Object.SettingsFileA.Clear();
	EndIf;
	
	If Data.Property("ValueTableSettingsFileB") Then
		Object.SettingsFileB.Load(Data.ValueTableSettingsFileB);
	Else
		Object.SettingsFileB.Clear();
	EndIf;
	
	If Data.Property("ValueTableParameterListA") Then
		Object.ParameterListA.Load(Data.ValueTableParameterListA);
	Else
		Object.ParameterListA.Clear();
	EndIf;
	
	If Data.Property("ValueTableParameterListB") Then
		Object.ParameterListB.Load(Data.ValueTableParameterListB);
	Else
		Object.ParameterListB.Clear();
	EndIf;
	
	If UploadSpreadsheetDocuments Then
		If Object.BaseTypeA = 4 Then
			Try
				If Data.Property("TableAValueStorage") Then
					Object.TableA = Data.TableAValueStorage.Get();
				EndIf;
			Except
			EndTry; 
		EndIf;
		
		If Object.BaseTypeB = 4 Then
			Try
				If Data.Property("TableBValueStorage") Then
					Object.TableB = Data.TableBValueStorage.Get();
				EndIf;
			Except
			EndTry;
		EndIf;
	EndIf;
	
	XMLReader.Close();
	DeleteFiles(PathToFile);
	
	Object.Result.Clear();
	
EndProcedure

&AtServer
Procedure OpenSettingsFromBaseAtServer(SelectedItem, UploadSpreadsheetDocuments = False)
	
	FormObject = FormAttributeToValue("Object");
	FormObject.OpenSettingsFromBaseAtServer(SelectedItem, UploadSpreadsheetDocuments);
	ValueToFormAttribute(FormObject, "Object");
	
EndProcedure

&AtClient
Procedure OpenSettingsFromFileEnd(Result, AdditionalParameters) Export
	
	UpdateVisibilityAccessibilityFormItems();
	UpdateVisibilityAvailabilityItemsRelationalOperation();
	UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput();

EndProcedure

&AtClient
Procedure OpenOperationSelectionFormForRecording(SaveSpreadsheetDocuments = False)

	//SelectedItem = Undefined;
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm"
		,,,,,
		, New NotifyDescription("SaveSelectedOperationEnd", ThisForm, New Structure("SaveSpreadsheetDocuments",SaveSpreadsheetDocuments))
		, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure OpenSettingsFromBaseEnd(Result, AdditionalParameters) Export
	
	SelectedItem = Result;
	UploadSpreadsheetDocuments = AdditionalParameters <> Undefined And AdditionalParameters.Property("UploadSpreadsheetDocuments") 
		And AdditionalParameters.UploadSpreadsheetDocuments;
	
	If SelectedItem <> Undefined Then
		
		OpenSettingsFromBaseAtServer(SelectedItem, UploadSpreadsheetDocuments);
		UpdateVisibilityAccessibilityFormItems();
		UpdateVisibilityAvailabilityItemsRelationalOperation();
		UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput();
		
	EndIf;

EndProcedure
#EndRegion 

#EndRegion 


#Region Processing_selection_parameter

&AtClient
Procedure OnStartChoiceParameterValue(BaseID, StandardProcessing)
	
	If Object["BaseType" + BaseID] = 1 Then
		StandardProcessing = False;
		ListAvailableTypes = New ValueList;
		ListAvailableTypes.Add("Number");
		ListAvailableTypes.Add("String");
		ListAvailableTypes.Add("Date");
		ListAvailableTypes.Add("Boolean");
		//SelectedType = Undefined;

		ShowChooseFromList(New NotifyDescription("OnStartChoiceParameterValueEnd4", ThisForm, New Structure("BaseID", BaseID))
			, ListAvailableTypes
			, Items["ParameterList" + BaseID + "ParameterValue"]);
	
	EndIf;

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueEnd4(SelectedItem, AdditionalParameters) Export
	
	BaseID = AdditionalParameters.BaseID;
	
	
	SelectedType = SelectedItem;
	If SelectedType = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items["ParameterList" + BaseID].CurrentData;
	If CurrentData = Undefined Then
		CurrentParameterValue = Undefined; 
	Else
		CurrentParameterValue =  CurrentData.ParameterValue;
	EndIf;
	
	If SelectedType.Value = "Number" Then
		ShowInputNumber(New NotifyDescription("OnStartChoiceParameterValueEnd3", ThisForm, New Structure("SelectedType, CurrentData, CurrentParameterValue", SelectedType, CurrentData, CurrentParameterValue)), CurrentParameterValue);
		Return;
	ElsIf SelectedType.Value = "String" Then
		ShowInputString(New NotifyDescription("OnStartChoiceParameterValueEnd2", ThisForm, New Structure("SelectedType, CurrentData, CurrentParameterValue", SelectedType, CurrentData, CurrentParameterValue)), CurrentParameterValue);
		Return;
	ElsIf SelectedType.Value = "Date" Then
		ShowInputDate(New NotifyDescription("OnStartChoiceParameterValueEnd1", ThisForm, New Structure("SelectedType, CurrentData, CurrentParameterValue", SelectedType, CurrentData, CurrentParameterValue)), CurrentParameterValue);
		Return;
	ElsIf SelectedType.Value = "Boolean" Then
		ShowInputValue(New NotifyDescription("OnStartChoiceParameterValueEnd", ThisForm, New Structure("CurrentData, CurrentParameterValue", CurrentData, CurrentParameterValue)), CurrentParameterValue,,New TypeDescription("Boolean"));
		Return;
	EndIf;
	
	OnStartChoiceParameterValueFragment3(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueEnd3(Number, AdditionalParameters) Export
	
	//SelectedType = AdditionalParameters.SelectedType;
	CurrentData = AdditionalParameters.CurrentData;
	CurrentParameterValue = ?(Number = Undefined, AdditionalParameters.CurrentParameterValue, Number);
	
	
	If Not (Number <> Undefined) Then
		Return;
	EndIf;
	
	OnStartChoiceParameterValueFragment3(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueFragment3(Val CurrentParameterValue, Val CurrentData)
	
	OnStartChoiceParameterValueFragment2(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueEnd2(String, AdditionalParameters) Export
	
	//SelectedType = AdditionalParameters.SelectedType;
	CurrentData = AdditionalParameters.CurrentData;
	CurrentParameterValue = ?(String = Undefined, AdditionalParameters.CurrentParameterValue, String);
	
	
	If Not (String <> Undefined) Then
		Return;
	EndIf;
	
	OnStartChoiceParameterValueFragment2(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueFragment2(Val CurrentParameterValue, Val CurrentData)
	
	OnStartChoiceParameterValueFragment1(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueEnd1(Date, AdditionalParameters) Export
	
	//SelectedType = AdditionalParameters.SelectedType;
	CurrentData = AdditionalParameters.CurrentData;
	CurrentParameterValue = ?(Date = Undefined, AdditionalParameters.CurrentParameterValue, Date);
	
	
	If Not (Date <> Undefined) Then
		Return;
	EndIf;
	
	OnStartChoiceParameterValueFragment1(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueFragment1(Val CurrentParameterValue, Val CurrentData)
	
	OnStartChoiceParameterValueFragment(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueEnd(Value, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	CurrentParameterValue = ?(Value = Undefined, AdditionalParameters.CurrentParameterValue, Value);
	
	
	If Not (Value <> Undefined) Then
		Return;
	EndIf;
	
	OnStartChoiceParameterValueFragment(CurrentParameterValue, CurrentData);

EndProcedure

&AtClient
Procedure OnStartChoiceParameterValueFragment(Val CurrentParameterValue, Val CurrentData)
	
	CurrentData.ParameterValue = CurrentParameterValue;

EndProcedure

#EndRegion 

#EndRegion


#Region Commands

&AtClient
Procedure CompareData(Command)
	
	CompareDataOnClient();
	
EndProcedure

&AtClient
Procedure QueryConstructorB(Command)
	OpenQueryConstructor("B");
EndProcedure

&AtClient
Procedure QueryConstructorA(Command)
	OpenQueryConstructor("A");
EndProcedure

&AtClient
Procedure SaveSettingsToFile(Command)
	
	SaveSettingsToFileAtClient();
	
EndProcedure

&AtClient
Procedure SaveSettingsAndSpreadsheetDocumentsToFile(Command)
	
	SaveSettingsToFileAtClient(True);
	
EndProcedure

&AtClient
Procedure SaveSettingsToDatabase(Command)
	
	SaveSettingsToDatabaseAtClient();
		
EndProcedure

&AtClient
Procedure SaveSettingsAndSpreadsheetDocumentsToDatabase(Command)
	
	SaveSettingsToDatabaseAtClient(True);
	
EndProcedure

&AtClient
Procedure OpenSettingsFromFile(Command)
	
	OpenSettingsFromFileAtClient(New NotifyDescription("OpenSettingsFromFileEnd", ThisForm));
			
EndProcedure

&AtClient
Procedure LoadSettingsAndSpreadsheetDocumentsFromFile(Command)
	
	OpenSettingsFromFileAtClient(New NotifyDescription("OpenSettingsFromFileEnd", ThisForm), True);
	
EndProcedure

&AtClient
Procedure OpenSettingsFromBase(Command)
	
	//SelectedItem = Undefined; 
	
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("OpenSettingsFromBaseEnd", ThisForm), FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure LoadSettingsAndSpreadsheetDocumentsFromDatabase(Command)
	
	//SelectedItem = Undefined; 
	
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm"
		,
		,
		,
		,
		,
		, New NotifyDescription("OpenSettingsFromBaseEnd", ThisForm, New Structure("UploadSpreadsheetDocuments", True))
		, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure CommandGetQueryParametersA(Command)
	
	GetParametersFromQueryOnServer("A");
	Items.GroupPagesBaseA.CurrentPage = Items.GroupPageQueryParametersA;
	
EndProcedure

&AtClient
Procedure CommandGetQueryParametersB(Command)
	
	GetParametersFromQueryOnServer("B");
	Items.GroupPagesBaseB.CurrentPage = Items.GroupPageQueryParametersB;
	
EndProcedure

&AtClient
Procedure VisitAuthorPage(Command)

	BeginRunningApplication(New NotifyDescription("VisitPage", ThisForm), "http://sertakov.by");
	
EndProcedure

&AtClient
Procedure VisitPageProcessing(Command)
	
	BeginRunningApplication(New NotifyDescription("VisitPage", ThisForm), "https://infostart.ru/public/581794/");
	
EndProcedure

&AtClient
Procedure CommandDownloadProcessing(Command)
	
	BeginRunningApplication(New NotifyDescription("VisitPage", ThisForm), "http://sertakov.by/work/KSD.epf");
	
EndProcedure

&AtClient
Procedure CommandPreviewSourceA(Command)
	
	UpdateVisibilityAvailabilityItemsRelationalOperation(1);
	
EndProcedure

&AtClient
Procedure CommandPreviewSourceB(Command)
	
	UpdateVisibilityAvailabilityItemsRelationalOperation(2);
	
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_AllRows(Command)	
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("A");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник А';en = 'Source A'"));	
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_100Rows(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("A",100);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник А (100 строк)';en = 'Source A (100 rows)'"));
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_100Rows(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("B",100);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник Б (100 строк)';en = 'Source B (100 rows)'"));
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_AllRows(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("B");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник Б';en = 'Source B'"));
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_Duplicates(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("A",,True);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник А (дубликаты)';en = 'Source A (duplicates)'"));
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_Duplicates(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("B",,True);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник Б (дубликаты)';en = 'Source B (duplicates)'"));
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_1000Rows(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("A",1000);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник А (1000 строк)';en = 'Source A (1000 rows)'"));
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_1000Rows(Command)
	SpreadsheetDocument = GetSpreadsheetDocumentDataFromSourceAtServer("B",1000);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show(Nstr("ru = 'Источник Б (1000 строк)';en = 'Source B (1000 rows)'"));
	EndIf;
EndProcedure

#EndRegion


#Region Event_handlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NumberOfAttributes = 5;
	ColorBackgroundFormDefault = StyleColors.FormBackColor;
	
	If Parameters.Property("UserMode") And Parameters.UserMode Then
		Object.UserMode = True;
	EndIf;
	
	If Parameters.Property("DataComparisonOperation") And ValueIsFilled(Parameters.DataComparisonOperation) Then
		
		Object.RelatedDataComparisonOperation = Parameters.DataComparisonOperation;
		FormObject = FormAttributeToValue("Object");
		FormObject.OpenSettingsFromBaseAtServer(Object.RelatedDataComparisonOperation);
		ValueToFormAttribute(FormObject, "Object");
				
	Else 
		
		Object.VersionPlatformExternalBaseA = "V83";
		Object.VersionPlatformExternalBaseB = "V83";
		
		Object.NumberColumnsInKey = 1;
		Object.PeriodType = 0;
		Object.AbsolutePeriodValue.ValidFrom = BegOfMonth(CurrentDate());
		Object.AbsolutePeriodValue.ValidTo = EndOfDay(CurrentDate());
		Object.RelativePeriodValue = 0;
		Object.ValueOfSlaveRelativePeriod = 0;
		Object.DiscretenessOfRelativePeriod = "month";
		Object.DiscretenessOfSlaveRelativePeriod = "month";
		Object.ConnectingToExternalBaseADriverSQL = "SQL Server";
		Object.ConnectingToExternalBaseBDriverSQL = "SQL Server";
		Object.NumberFirstRowFileA = 1;
		Object.NumberFirstRowFileB = 1;
		Object.NumberOfRowsWithEmptyKeysToBreakReading = 2;
		Object.ConnectingToExternalBaseADeviceStorageFile = 0;
		Object.ConnectingToExternalBaseBDeviceStorageFile = 0;
		Object.ConnectionToExternalDatabaseANumberTableInFile = 1;
		Object.ConnectionToExternalDatabaseBNumberTableInFile = 1;
		
		Object.VisibilityKey1 = True;
		Object.VisibilityKey2 = Object.NumberColumnsInKey > 1;
		Object.VisibilityKey3 = Object.NumberColumnsInKey > 2;
		Object.VisibilityNumberOfRecordsA = True;
		Object.VisibilityNumberOfRecordsB = True;
		
		For Counter = 1 To NumberOfAttributes Do
			Object["VisibilityAttributeA" + Counter] = True;
			Object["VisibilityAttributeB" + Counter] = True;
		EndDo;
		
		For Counter = 1 To 20 Do 
			
			Object.TableA.Region(1,Counter,1,Counter).Text = Counter;
			Object.TableB.Region(1,Counter,1,Counter).Text = Counter;
			
		EndDo;
		
	EndIf;
		
	Example1 = "CurrentKey = Left(CurrentKey,10);";
	Example2 = "CurrentKey = Number(CurrentKey) + 1;";
	Example3 = "If Left(CurrentKey,1) = ""#"" Then CurrentKey = Mid(CurrentKey, 2); EndIf;";
	Example4 = "CurrentKey = Right(""0000000000"" + CurrentKey, 10);";
	Example5 = "CurrentKey = StrReplace(CurrentKey, ""_"", """");";
	Example6 = "CurrentKey = ?(ValueIsFilled(CurrentKey), CurrentKey, ""<>"");";
	
	If Object.UserMode Then
		
		Items.GroupHeaderHiddenAttributes.Visible = False;
		Items.GroupBaseAPage.Visible = False;
		Items.GroupBaseBPage.Visible = False;
		Items.GroupOutputSettings.Visible = False;
		Items.GroupMain.PagesRepresentation = FormPagesRepresentation.None;
		Items.CommandUploadResultToFileOnServer.Visible = False;
		Items.ResultGroupVisibilityColumnsKey.Visible = False;
				
	Else		
	
		TemplatePictureActiveOperation1 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation1");
		TemplatePictureInactiveOperation1 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation1");
		TemplatePictureActiveOperation2 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation2");
		TemplatePictureInactiveOperation2 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation2");
		TemplatePictureActiveOperation3 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation3");
		TemplatePictureInactiveOperation3 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation3");
		TemplatePictureActiveOperation4 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation4");
		TemplatePictureInactiveOperation4 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation4");
		TemplatePictureActiveOperation5 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation5");
		TemplatePictureInactiveOperation5 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation5");
		TemplatePictureActiveOperation6 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation6");
		TemplatePictureInactiveOperation6 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation6");
		TemplatePictureActiveOperation7 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperation7");
		TemplatePictureInactiveOperation7 	= FormAttributeToValue("Object").GetTemplate("PictureInactiveOperation7");
		
		TemplatePictureActiveOperationA1 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperationA1");
		TemplatePictureActiveOperationA2 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperationA2");
		TemplatePictureActiveOperationA3 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperationA3");
		TemplatePictureActiveOperationA4 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperationA4");
		TemplatePictureActiveOperationA5 	= FormAttributeToValue("Object").GetTemplate("PictureActiveOperationA5");
			
		ActiveOperation1 	= PutToTempStorage(TemplatePictureActiveOperation1, UUID);
		InactiveOperation1 	= PutToTempStorage(TemplatePictureInactiveOperation1, UUID);
		ActiveOperation2 	= PutToTempStorage(TemplatePictureActiveOperation2, UUID);
		InactiveOperation2 	= PutToTempStorage(TemplatePictureInactiveOperation2, UUID);
		ActiveOperation3 	= PutToTempStorage(TemplatePictureActiveOperation3, UUID);
		InactiveOperation3 	= PutToTempStorage(TemplatePictureInactiveOperation3, UUID);
		ActiveOperation4 	= PutToTempStorage(TemplatePictureActiveOperation4, UUID);
		InactiveOperation4 	= PutToTempStorage(TemplatePictureInactiveOperation4, UUID);
		ActiveOperation5 	= PutToTempStorage(TemplatePictureActiveOperation5, UUID);
		InactiveOperation5 	= PutToTempStorage(TemplatePictureInactiveOperation5, UUID);
		ActiveOperation6 	= PutToTempStorage(TemplatePictureActiveOperation6, UUID);
		InactiveOperation6 	= PutToTempStorage(TemplatePictureInactiveOperation6, UUID);
		ActiveOperation7 	= PutToTempStorage(TemplatePictureActiveOperation7, UUID);
		InactiveOperation7 	= PutToTempStorage(TemplatePictureInactiveOperation7, UUID); 
		ActiveOperationA1 = 	PutToTempStorage(TemplatePictureActiveOperationA1, UUID);
		ActiveOperationA2 = 	PutToTempStorage(TemplatePictureActiveOperationA2, UUID);
		ActiveOperationA3 = 	PutToTempStorage(TemplatePictureActiveOperationA3, UUID);
		ActiveOperationA4 = 	PutToTempStorage(TemplatePictureActiveOperationA4, UUID);
		ActiveOperationA5 = 	PutToTempStorage(TemplatePictureActiveOperationA5, UUID);
	EndIf;

	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing,
		Items.GroupPanel2);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateVisibilityAccessibilityFormItems();
	UpdateVisibilityAvailabilityItemsRelationalOperation();
	UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput();
	UpdateVisibilityAvailabilityOrderSortTableDifferences();
	UpdateCodeToOutputAndProhibitOutputRows();
		
EndProcedure

&AtClient
Procedure OperationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	Object.RelationalOperation = Number(Right(Item.Name,1));
	UpdateVisibilityAvailabilityItemsRelationalOperation();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	If Not ClosingFormConfirmed Then
		Cancel = True;
		ShowQueryBox(New NotifyDescription("BeforeCloseEnd", ThisForm)
			, Nstr("ru = 'Закрыть консоль сравнения данных?';en = 'Close Data Compare Console?'"), QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If ValueIsFilled(Object.RelatedDataComparisonOperation) And Not Object.UserMode  Then
		QueryText = StrTemplate(Nstr("ru = 'Обновить элемент справочника ""%1""?';en = 'Update catalog item ""%1""?'"), Object.RelatedDataComparisonOperation);
		ShowQueryBox(New NotifyDescription("SaveToRelatedOperationEnd", ThisObject, New Structure("SelectCatalogItemToSave,SaveSpreadsheetDocuments,OnCloseForm",True,False,True))
			, QueryText
			, QuestionDialogMode.YesNo);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure VisitPage(ReturnCode, AdditionalParameters) Export
	
EndProcedure

&AtClient
Procedure CodeForOutputRowsEditedManuallyOnChange(Item)
	
	If Not Object.CodeForOutputRowsEditedManually Then
		
		ShowQueryBox(New NotifyDescription("CodeForOutputRowsEditedManuallyOnChangeEnd", ThisForm)
			, Nstr("ru = 'Код, внесенный вручную будет утерян. Продолжить?';en = 'Code entered manually will be lost. Continue?'")
			, QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	CodeForOutputRowsEditedManuallyOnChangeFragment();
EndProcedure

&AtClient
Procedure CodeForOutputRowsEditedManuallyOnChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.None Then
		Object.CodeForOutputRowsEditedManually = True;
		Return;
	EndIf;
	
	
	CodeForOutputRowsEditedManuallyOnChangeFragment();

EndProcedure

&AtClient
Procedure CodeForOutputRowsEditedManuallyOnChangeFragment()
	
	UpdateCodeToOutputAndProhibitOutputRows();
	UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput();

EndProcedure

&AtClient
Procedure CodeForProhibitingOutputRowsEditedManuallyOnChange(Item)
	
	If Not Object.CodeForProhibitingOutputRowsEditedManually Then
		
		ShowQueryBox(New NotifyDescription("CodeForProhibitingOutputRowsEditedManuallyOnChangeEnd", ThisForm)
			, Nstr("ru = 'Код, внесенный вручную будет утерян. Продолжить?';en = 'Code entered manually will be lost. Continue?'")
			, QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	CodeForProhibitingOutputRowsEditedManuallyOnChangeFragment();
EndProcedure

&AtClient
Procedure CodeForProhibitingOutputRowsEditedManuallyOnChangeEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.None Then
		Object.CodeForProhibitingOutputRowsEditedManually = True;
		Return;
	EndIf;
	
	
	CodeForProhibitingOutputRowsEditedManuallyOnChangeFragment();

EndProcedure

&AtClient
Procedure CodeForProhibitingOutputRowsEditedManuallyOnChangeFragment()
	
	UpdateCodeToOutputAndProhibitOutputRows();
	UpdateVisibilityAvailabilityItemsOutputAndInhibitRowOutput();

EndProcedure

&AtClient
Procedure ConditionsOutputRowsOnChange(Item)
	UpdateCodeToOutputAndProhibitOutputRows();
EndProcedure

&AtClient
Procedure ConditionsProhibitOutputRowsOnChange(Item)
	UpdateCodeToOutputAndProhibitOutputRows();
EndProcedure

&AtClient
Procedure BooleanOperatorForProhibitingConditionsOutputRowsOnChange(Item)
	UpdateCodeToOutputAndProhibitOutputRows();
EndProcedure

&AtClient
Procedure BooleanOperatorForConditionsOutputRowsOnChange(Item)
	UpdateCodeToOutputAndProhibitOutputRows();
EndProcedure

&AtClient
Procedure CommandVisibilityColumnTP(Command)
	
	AttributeName = StrReplace(Command.Name, "CommandVisibility", "");
	
	Object["Visibility" + AttributeName] = Not Object["Visibility" + AttributeName];
	
	UpdateVisibilityAttributeTP(AttributeName);
		
EndProcedure

&AtClient
Procedure ТипПараметраПериодПриИзменении(Item)
	
	RefreshDataPeriod();
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure RelativePeriodValueOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfRelativePeriodOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure ConnectionToExternalBaseAPathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileDialog = New FileDialog(FileDialogMode.Opening);
	
	If IsBlankString(Object.ConnectionToExternalBaseAFileFormat) Then
		FileDialog.Filter = 
			"*.*" + 
			"|*.*";
	ElsIf Object.ConnectionToExternalBaseAFileFormat = "XLS" Or Object.ConnectionToExternalBaseAFileFormat = "DOC" Then
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseAFileFormat
			+ ";*." + Object.ConnectionToExternalBaseAFileFormat + "X"
			+ "|*." + Object.ConnectionToExternalBaseAFileFormat
			+ ";*." + Object.ConnectionToExternalBaseAFileFormat + "X";
	Else
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseAFileFormat + 
			"|*." + Object.ConnectionToExternalBaseAFileFormat;
	EndIf;
		
	FileDialog.Title = Nstr("ru = 'Выберите файл';en = 'Select a file'");
	FileDialog.FilterIndex = 0;
	FileDialog.Show(New NotifyDescription("ConnectionToExternalBaseAPathToFileStartChoiceEnd", ThisForm, New Structure("FileDialog", FileDialog)));
	
EndProcedure

&AtClient
Procedure ConnectionToExternalBaseAPathToFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileDialog = AdditionalParameters.FileDialog;
	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.ConnectionToExternalBaseAPathToFile = FileDialog.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure ConnectionToExternalBaseBPathToFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	FileDialog = New FileDialog(FileDialogMode.Opening);
	
	If IsBlankString(Object.ConnectionToExternalBaseBFileFormat) Then
		FileDialog.Filter = 
			"*.*" + 
			"|*.*";
	ElsIf Object.ConnectionToExternalBaseBFileFormat = "XLS" Or Object.ConnectionToExternalBaseBFileFormat = "DOC" Then
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseBFileFormat
			+ ";*." + Object.ConnectionToExternalBaseBFileFormat + "X"
			+ "|*." + Object.ConnectionToExternalBaseBFileFormat
			+ ";*." + Object.ConnectionToExternalBaseBFileFormat + "X";
	Else
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseBFileFormat + 
			"|*." + Object.ConnectionToExternalBaseBFileFormat;
	EndIf;
		
	FileDialog.Title = Nstr("ru = 'Выберите файл';en = 'Select a file'");
	FileDialog.FilterIndex = 0;
	FileDialog.Show(New NotifyDescription("ConnectionToExternalBaseBPathToFileStartChoiceEnd", ThisForm, New Structure("FileDialog", FileDialog)));
	
EndProcedure

&AtClient
Procedure ConnectionToExternalBaseBPathToFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileDialog = AdditionalParameters.FileDialog;
	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.ConnectionToExternalBaseBPathToFile = FileDialog.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure SettingsFileBAggregateFunctionCalculationTotalClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.SettingsFileB.CurrentData;
	If CurrentRow <> Undefined Then
		CurrentRow.AggregateFunctionCalculationTotal = "Sum";
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileAAggregateFunctionCalculationTotalClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.SettingsFileA.CurrentData;
	If CurrentRow <> Undefined Then
		CurrentRow.AggregateFunctionCalculationTotal = "Sum";
	EndIf;

EndProcedure

&AtClient
Procedure SettingsFileAOnChange(Item)
	
	CurrentRow = Items.SettingsFileA.CurrentData;
	If CurrentRow <> Undefined Then
		If IsBlankString(CurrentRow.AggregateFunctionCalculationTotal) Then
			CurrentRow.AggregateFunctionCalculationTotal = "Sum";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileBOnChange(Item)
	
	CurrentRow = Items.SettingsFileB.CurrentData;
	If CurrentRow <> Undefined Then
		If IsBlankString(CurrentRow.AggregateFunctionCalculationTotal) Then
			CurrentRow.AggregateFunctionCalculationTotal = "Sum";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileABeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	If Object.SettingsFileA.Count() = 5 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileBBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	If Object.SettingsFileB.Count() = 5 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeKeyAttribute(Item)
	
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure ParameterListAParameterValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	Items.ParameterListAParameterValue.ChooseType = TypeOf(Items.ParameterListA.CurrentData.ParameterValue) = Type("Undefined");	
	OnStartChoiceParameterValue("A", StandardProcessing);
	
EndProcedure

&AtClient
Procedure ParameterListAParameterValueOnChange(Item)
	
	CurrentParameter = Object.ParameterListA.FindByID(Items.ParameterListA.CurrentData.GetID());
	CurrentParameter.ParameterType = TypeOf(CurrentParameter.ParameterValue);

EndProcedure

&AtClient
Procedure ParameterListBParameterValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	Items.ParameterListBParameterValue.ChooseType = TypeOf(Items.ParameterListB.CurrentData.ParameterValue) = Type("Undefined");	
	OnStartChoiceParameterValue("B", StandardProcessing);
		
EndProcedure

&AtClient
Procedure ParameterListBParameterValueOnChange(Item)
	
	CurrentParameter = Object.ParameterListB.FindByID(Items.ParameterListB.CurrentData.GetID());
	CurrentParameter.ParameterType = TypeOf(CurrentParameter.ParameterValue);
	
EndProcedure

&AtClient
Procedure NumberColumnsInKeyOnChange(Item)
	
	Object.VisibilityKey1 = True;
	Object.VisibilityKey2 = Object.NumberColumnsInKey > 1;
	Object.VisibilityKey3 = Object.NumberColumnsInKey > 2;
	UpdateVisibilityAccessibilityFormItems();
	UpdateVisibilityAccessibilityFormItemsByBaseID("A");
	UpdateVisibilityAccessibilityFormItemsByBaseID("B");
	
EndProcedure

&AtClient
Procedure ResultKey1StartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ResultKey2StartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey3StartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey1Clearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey2Clearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey3Clearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure OnChangeFlagExecuteArbitraryKeyCode(Item)
	
	UpdateAttributesArbitraryCode();
	
EndProcedure

&AtClient
Procedure DisplayKeyColumnTypesOnChange(Item)
	
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure CommandVisibilityTypesColumnsKey(Command)
	
	Items.ResultCommandVisibilityTypesColumnsKey.Check = Not Items.ResultCommandVisibilityTypesColumnsKey.Check;
	Object.DisplayKeyColumnTypes = Items.ResultCommandVisibilityTypesColumnsKey.Check;
	If Object.DisplayKeyColumnTypes Then
		FillColumnTypesKeyInAllRows();
	EndIf;
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnServer(Command)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = Nstr("ru = 'Не задан формат файла выгрузки';en = 'Upload file format not set'");
		UserMessage.Message();
		Return;
	EndIf;
	
	If IsBlankString(Object.PathToDownloadFile) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.PathToDownloadFile";
		UserMessage.Text = Nstr("ru = 'Не задан путь к файлу выгрузки';en = 'The path to the upload file is not set'");
		UserMessage.Message();
		Return;
	EndIf;
			
	//Ответ = Undefined; 	
	ShowQueryBox(New NotifyDescription("CommandUploadResultToFileOnServerEnd", ThisForm)
		, Nstr("ru = 'Выгрузить таблицу в файл на сервере?';en = 'Download table to file on server?'")
		, QuestionDialogMode.YesNo
		, 
		, DialogReturnCode.None
		, Nstr("ru = 'Выгрузка';en = 'Unloading'"));
	
EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnServerEnd(Result, AdditionalParameters) Export
	
	Ответ = Result; 
	If Ответ = DialogReturnCode.None Then
		Return;
	EndIf;
	
	UploadResultToFileAtServer(False, RepresentationHeadersAttributes);

EndProcedure

&AtClient
Procedure PathToDownloadFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = Nstr("ru = 'Не задан формат файла выгрузки';en = 'Upload file format not set'");
		UserMessage.Message();
		Return;
	EndIf;
	
	Mode = FileDialogMode.Save;
	SelectionDialog = New FileDialog(Mode);
	SelectionDialog.FullFileName = Object.Title;
	Filter = "File " + Object.UploadFileFormat + " (*." + Object.UploadFileFormat + ")|*." + Object.UploadFileFormat + "";
	SelectionDialog.Filter = Filter;
	SelectionDialog.Title = Nstr("ru = 'Укажите файл для сохранения результата сравнения';en = 'Specify a file to save the comparison result'");   

	SelectionDialog.Show(New NotifyDescription("PathToDownloadFileStartChoiceEnd", ThisForm, New Structure("SelectionDialog", SelectionDialog)));
	
EndProcedure

&AtClient
Procedure PathToDownloadFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	SelectionDialog = AdditionalParameters.SelectionDialog;	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.PathToDownloadFile =  SelectionDialog.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnClient(Command)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = Nstr("ru = 'Не задан формат файла выгрузки';en = 'Upload file format not set'");
		UserMessage.Message();
		Return;
	EndIf;
	
	ShowQueryBox(New NotifyDescription("CommandUploadResultToFileOnClientEndQuestion", ThisForm)
		, Nstr("ru = 'Выгрузить таблицу в файл на клиенте?';en = 'Download table to file on client?'")
		, QuestionDialogMode.YesNo
		,
		, DialogReturnCode.None
		, Nstr("ru = 'Выгрузка';en = 'Unloading'"));
	
EndProcedure

&AtClient
Procedure PeriodTypeOnChange(Item)
	
	RefreshDataPeriod();
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure ValueOfSlaveRelativePeriodOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfSlaveRelativePeriodOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfRelativePeriodClearing(Item, StandardProcessing)
	
	Object.DiscretenessOfRelativePeriod = "day";
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfSlaveRelativePeriodClearing(Item, StandardProcessing)
	
	Object.DiscretenessOfSlaveRelativePeriod = "day";
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure ConditionsOutputRowsDisabledOnChange(Item)
	
	UpdateVisibilityAvailabilityPage_GroupConditionsOutputRows();
	
EndProcedure

&AtClient
Procedure ConditionsProhibitOutputRowsDisabledOnChange(Item)
	
	UpdateVisibilityAvailabilityPage_GroupConditionsProhibitOutputRows();
	
EndProcedure

&AtClient
Procedure SortTableDifferencesOnChange(Item)
	
	UpdateVisibilityAvailabilityOrderSortTableDifferences();
		
EndProcedure

&AtClient
Procedure OrderSortTableDifferencesStartChoice(Item, ChoiceData, StandardProcessing)
	
	//ReturnValue = Undefined;
	
	OpenForm(StrReplace(FormName, "Form", "SortingSettingsForm")
		, New Structure("OrderSortTableDifferences", Object.OrderSortTableDifferences)
		,
		,
		,
		,
		, New NotifyDescription("OrderSortTableDifferencesStartChoiceEnd", ThisForm)
		, FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure OrderSortTableDifferencesStartChoiceEnd(Result, AdditionalParameters) Export
	
	ReturnValue = Result;
	If ReturnValue <> Undefined Then
		Object.OrderSortTableDifferences = ReturnValue;
	EndIf;

EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure

#EndRegion

ClosingFormConfirmed = False;