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
Function ПолучитьДанныеВВидеСтруктуры(SaveSpreadsheetDocuments)
	
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
	
	If RowTP.Condition <> "Заполнен" Then					
					
		If RowTP.ComparisonType = "Value" Then
			If TypeOf(RowTP.ComparedValue) = Type("Date") Then 
				ПраваяСторона = 
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
				ПраваяСторона = String(RowTP.ComparedValue);
			ElsIf TypeOf(RowTP.ComparedValue) = Type("String") Then 
				ПраваяСторона = """" + String(RowTP.ComparedValue) + """";
			ElsIf TypeOf(RowTP.ComparedValue) = Type("Boolean") Then 
				If RowTP.ComparedValue Then
					ПраваяСторона = "True";
				Else
					ПраваяСторона = "False";
				EndIf;
			Else
				ПраваяСторона = String(RowTP.ComparedValue);
			EndIf;
			
		Else
			ПраваяСторона = RowTP.NameComparedAttribute2;
		EndIf;
		
		CodeFromRowTP =
			RowTP.NameComparedAttribute
			+ " "
			+ RowTP.Condition
			+ " "
			+ ПраваяСторона;
		
	Else
		
		CodeFromRowTP =
			"ValueIsFilled("
			+ RowTP.NameComparedAttribute
			+ ")";
		
	EndIf;
	
	Return CodeFromRowTP;	

EndFunction

&AtServer
Procedure ПолучитьПараметрыИзЗапросаНаСервере(BaseID)
	
	If IsBlankString(Object["QueryText" + BaseID]) Then	
		Return;
	EndIf;
	
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
			ТекстОшибки = "Error при подключении к внешней базе: " + ErrorDescription();
			Message(Формат(CurrentDate(),"DLF=DT") + ": " + ТекстОшибки);
			TextErrors = TextErrors + Chars.LF + ТекстОшибки;
			Return;
		EndTry;

		Query = Connection.NewObject("Query");		
	
	EndIf;
	
	Query.Text = Object["QueryText" + BaseID];
	
	Try
		QueryOptions = Query.FindParameters();
	Except
		Message(Формат(CurrentDate(),"DLF=DT") + "Error при получении списка параметров: " + ErrorDescription());
		Return;
	EndTry;
	
	For Each ПараметрЗапроса In QueryOptions Do
		
		ИмяПараметра = ПараметрЗапроса.Name;
		If ИмяПараметра = "ValidFrom" Or ИмяПараметра = "ValidTo" Then
			Continue;
		EndIf;
		
		НайденныеПараметры = Object["ParameterList" + BaseID].FindRows(New Structure("ParameterName", ИмяПараметра));
		If НайденныеПараметры.Count() = 0 Then
			ТекущийПараметр = Object["ParameterList" + BaseID].Add();
			ТекущийПараметр.ParameterName = ИмяПараметра;
		Else
			ТекущийПараметр = НайденныеПараметры[0];
		EndIf; 
		
		ТекущийПараметр.ParameterValue = ПараметрЗапроса.ValueType.AdjustValue(ТекущийПараметр.ЗначениеПараметра);		
		ТекущийПараметр.ParameterType = String(TypeOf(ТекущийПараметр.ЗначениеПараметра));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ЗаполнитьТипыСтолбцовКлючаВоВсехСтроках()
	
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
Function ВыгрузитьРезультатВФайлНаСервере(ДляКлиента, RepresentationHeadersAttributes)
	
	РеквизитОбъект = FormAttributeToValue("Object");
	РеквизитОбъект.RepresentationHeadersAttributes = RepresentationHeadersAttributes;
	АдресФайла = РеквизитОбъект.ВыгрузитьРезультатВФайлНаСервере(ДляКлиента);
	Return АдресФайла;
	
EndFunction

&AtClient
Procedure CommandUploadResultToFileOnClientEndQuestion(РезультатВопроса, AdditionalParameters) Export
	
	If РезультатВопроса = DialogReturnCode.None Then
		Return;
	EndIf;
	
	АдресФайла = ВыгрузитьРезультатВФайлНаСервере(True);
	If АдресФайла = Undefined Then
		Return;
	EndIf;
	
	ДанныеФайла = GetFromTempStorage(АдресФайла, RepresentationHeadersAttributes);
	ДиалогСохраненияФайла = New FileDialog(FileDialogMode.Save);
	ДиалогСохраненияФайла.FullFileName = Object.PathToDownloadFile;
	ДиалогСохраненияФайла.Filter = "*." + Object.UploadFileFormat + "|*." + Object.UploadFileFormat;
	ДиалогСохраненияФайла.Title = "Выберите каталог"; 
	
	ДиалогСохраненияФайла.Show(New NotifyDescription("CommandUploadResultToFileOnClientEnd", ThisForm, New Structure("ДанныеФайла, ДиалогСохраненияФайла", ДанныеФайла, ДиалогСохраненияФайла)));

EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnClientEnd(SelectedFiles, AdditionalParameters) Export
	
	ДанныеФайла = AdditionalParameters.ДанныеФайла;
	ДиалогСохраненияФайла = AdditionalParameters.ДиалогСохраненияФайла;
	         	
	If (SelectedFiles <> Undefined) Then
		
		ДанныеФайла.Write(ДиалогСохраненияФайла.FullFileName);
		Message(Format(CurrentDate(),"ДФ='yyyy.MM.dd HH.mm.ss'") + ": Выгрузка в файл завершена (" + ДиалогСохраненияФайла.FullFileName + ")");		
		
	Else
		
		Message(Format(CurrentDate(),"ДФ='yyyy.MM.dd HH.mm.ss'") + ": Выгрузка в файл отменена");
		
	EndIf;

EndProcedure

&AtServer
Function ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере(BaseID, МаксимальноеЧислоСтрок = 0, ТолькоДубликаты = False, Connection = Undefined)

	ТекстОшибки = "";
	ProcessingObject = FormAttributeToValue("Object");
		
	If Not ProcessingObject.CheckFillingAttributes(BaseID) Then
		Return Undefined;
	EndIf;
	
	Connection = Undefined;
	ТЗ = ProcessingObject.ReadDataAndGetValueTable(BaseID, ТекстОшибки, Connection);
	
	If ТЗ = Undefined Then
		Message(Формат(CurrentDate(),"DLF=DT") + ": " + ТекстОшибки);
		Return Undefined;
	EndIf;
	
	Template = ProcessingObject.GetTemplate("PreviewForm");
	SpreadsheetDocument = New SpreadsheetDocument;
	
	//Key 1
	ИмяКлюча1 = ТЗ.Cols.Get(0).Name;
	ColumnsWithKeyRow = ИмяКлюча1;
	ОбластьШапка = Template.GetArea("Header|Ключ1");
	SpreadsheetDocument.Put(ОбластьШапка);
	
	//Key 2
	If Object.NumberColumnsInKey > 1 Then
		ИмяКлюча2 = ТЗ.Cols.Get(1).Name;
		ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ИмяКлюча2;
		ОбластьШапка = Template.GetArea("Header|Ключ2");
		SpreadsheetDocument.Join(ОбластьШапка);
	EndIf;
	
	//Key 3
	If Object.NumberColumnsInKey > 2 Then
		ИмяКлюча3 = ТЗ.Cols.Get(2).Name;
		ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ИмяКлюча3;
		ОбластьШапка = Template.GetArea("Header|Ключ3");
		SpreadsheetDocument.Join(ОбластьШапка);
	EndIf;
	
	ТЗ.Sort(ColumnsWithKeyRow);
	
	ТЗ_Сгруппированная = ТЗ.Copy(); 
	
	ColumnNameNumberOfRowsDataSource = "NumberOfRowsDataSource_" + StrReplace(String(New UUID), "-", "");
	ТЗ_Сгруппированная.Cols.Add(ColumnNameNumberOfRowsDataSource);
	
	ОбластьРеквизиты = Template.GetArea("Header|Attributes");
	SpreadsheetDocument.Join(ОбластьРеквизиты);
		
	ТЗ_Сгруппированная.FillValues(1,ColumnNameNumberOfRowsDataSource);	
	ТЗ_Сгруппированная.Collapse(ColumnsWithKeyRow, ColumnNameNumberOfRowsDataSource);
	ТЗ_Сгруппированная.Indexes.Add(ColumnsWithKeyRow);
		
	ЧислоКолонокТЗ = ТЗ.Cols.Count();
	RowsCounter = 0;
	For Each СтрокаТЗ In ТЗ Do
		
		RowsCounter = RowsCounter + 1;
		
		If МаксимальноеЧислоСтрок > 0 And RowsCounter > МаксимальноеЧислоСтрок Then
			Break;
		EndIf;
		
		If Connection = Undefined Then
			ОтборСтруктура = New Structure;
		Else
			ОтборСтруктура = Connection.NewObject("Structure");
		EndIf;
				
		Ключ1 = СтрокаТЗ.Get(0);
		ОтборСтруктура.Insert(ИмяКлюча1, Ключ1);
		
		If Object.NumberColumnsInKey > 1 Then
			Ключ2 = СтрокаТЗ.Get(1);
			ОтборСтруктура.Insert(ИмяКлюча2, Ключ2);
		Else
			Ключ2 = Undefined;
		EndIf;
		
		If Object.NumberColumnsInKey > 2 Then
			Ключ3 = СтрокаТЗ.Get(2);
			ОтборСтруктура.Insert(ИмяКлюча3, Ключ3);
		Else
			Ключ3 = Undefined;
		EndIf;
		
		СтрокиСгруппированнойТЗ = ТЗ_Сгруппированная.FindRows(ОтборСтруктура);
		ЧислоСтрокПоКлючу = ?(СтрокиСгруппированнойТЗ.Count(), СтрокиСгруппированнойТЗ.Get(0)[ColumnNameNumberOfRowsDataSource], 0);
		If ЧислоСтрокПоКлючу > 1 Then
			ИмяОбластиСтрока = "СтрокаСОшибками";
		Else
			If ТолькоДубликаты Then
				Continue;
			EndIf;
			ИмяОбластиСтрока = "СтрокаБезОшибок";
		EndIf;
		
		ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Ключ1");
		ОбластьСтрока.Parameters.Ключ1 = String(Ключ1);
		SpreadsheetDocument.Put(ОбластьСтрока);
		
		If Object.NumberColumnsInKey > 1 Then
			ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Ключ2");
			ОбластьСтрока.Parameters.Ключ2 = String(Ключ2);
			SpreadsheetDocument.Join(ОбластьСтрока);
		EndIf;
		
		If Object.NumberColumnsInKey > 2 Then
			ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Ключ3");
			ОбластьСтрока.Parameters.Ключ3 = String(Ключ3);
			SpreadsheetDocument.Join(ОбластьСтрока);
		EndIf;		
		
		ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Attributes");
		ОбластьСтрока.Parameters.ЧислоСтрок = ЧислоСтрокПоКлючу; 
				
		СмещениеНомераРеквизита = Object.NumberColumnsInKey;
		For ColumnCounter = 1 To Min(NumberOfAttributes, ЧислоКолонокТЗ - Object.NumberColumnsInKey) Do
			ОбластьСтрока.Parameters["Attribute" + ColumnCounter] = String(СтрокаТЗ.Get(ColumnCounter + СмещениеНомераРеквизита - 1));
		EndDo;
		
		SpreadsheetDocument.Join(ОбластьСтрока);
			
	EndDo;
	
	ТЗ = Undefined;
	ТЗ_Сгруппированная = Undefined;
	Connection = Undefined;
	
	SpreadsheetDocument.Protection = False;
	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
		
EndFunction


#Region Видимость_доступность_элементов_формы
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
	ОбновитьВидимостьКлючейТЧ();
		
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
	
	ОбновитьЗаголовок();
	ОбновитьРеквизитыПроизвольныйКод();
	ОбновитьВидимостьДоступностьВкладкиУсловияЗапретаВыводаСтрок();
	ОбновитьВидимостьДоступностьВкладкиУсловияВыводаСтрок();
	
EndProcedure

&AtClient
Procedure ОбновитьРеквизитыПроизвольныйКод()
	
	For СчетчикЭлементов = 1 To 3 Do
		ОбновитьВидимостьДоступностьРеквизитаПроизвольныйКод(СчетчикЭлементов, "А"); 
		ОбновитьВидимостьДоступностьРеквизитаПроизвольныйКод(СчетчикЭлементов, "Б");
	EndDo;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьРеквизитаПроизвольныйКод(НомерЭлементаФормы, BaseID)
	
	Items["ArbitraryKeyCode" + НомерЭлементаФормы + BaseID].Visible = 
		Object["ExecuteArbitraryKeyCode" + НомерЭлементаФормы + BaseID];
	
EndProcedure

&AtClient
Procedure ОбновитьЗаголовок()
	
	ThisForm.Title = "КСД: " + Object.Title;
	
EndProcedure

&AtClient
Procedure ОбновитьИтогиПоРеквизитамТЧ(ИдентификаторБазы)
	
	For AttributesCounter = 1 To NumberOfAttributes Do
	
		ИмяРеквизита = "Реквизит" + ИдентификаторБазы + AttributesCounter;
		Элементы["Результат" + ИмяРеквизита].ТекстПодвала = ?(Объект["НастройкиФайла" + ИдентификаторБазы].Количество() >= AttributesCounter И Объект["НастройкиФайла" + ИдентификаторБазы][AttributesCounter - 1].РассчитыватьИтог, Объект["ЗначениеИтога" + ИмяРеквизита], "");
	
	EndDo; 
		
EndProcedure

&AtClient
Procedure UpdateVisibilityAccessibilityFormItemsByBaseID(BaseID)
	
	Items["ГруппаОбработкаКлюча2" + BaseID].Visible = Object.NumberColumnsInKey > 1;
	Items["ГруппаОбработкаКлюча3" + BaseID].Visible = Object.NumberColumnsInKey > 2;
	
	Items["ГруппаСтраницаПараметрыЗапроса" + BaseID].Visible = Object["BaseType" + BaseID] <= 1;
	Items["ParameterList"  + BaseID + "КомандаПолучитьПараметрыЗапроса"  + BaseID].Visible = Object["BaseType" + BaseID] <= 2;
	
	//Table 
	Items["ГруппаСтраницаТаблица" + BaseID].Visible = Object["BaseType" + BaseID] = 4;
		
//#Region _1C_8_внешняя
	If Object["BaseType" + BaseID] = 1 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= True;
		Items["ГруппаВариантВерсияПлатформыБазы" + BaseID].Visible 						= True;
		If Object["WorkOptionExternalBase" + BaseID] = 1 Then
			Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 				= True;
			Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 			= "Name базы";
		Else
			Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 				= False;
			Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 			= "Path к базе";
		EndIf;
		Items["ConnectionToExternalBase" + BaseID + "ДрайверSQL"].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= True;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;	
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
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
							
//#EndRegion

//#Region SQL
	ElsIf Object["BaseType" + BaseID] = 2 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= True;
		Items["ГруппаВариантВерсияПлатформыБазы" + BaseID].Visible 						= False;
		Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 					= True;
		Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 				= "Name базы данных";
		Items["ConnectionToExternalBase" + BaseID + "ДрайверSQL"].Visible 				= True;
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;		
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= False;
		
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
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
				                                                                       						
//#EndRegion 

//#Region Файл
	ElsIf Object["BaseType" + BaseID] = 3 Then
		
		ФайлФорматаXML = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "XML";
		ФайлФорматаXLS = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "XLS";
		ФайлФорматаDOC = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "DOC";
				
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible							= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= True;
		Items["ГруппаПараметрыПодключенияКФайлуОбщие" + BaseID].Visible					= True;
		Items["ГруппаПараметрыПодключенияКФайлуXMLJSON" + BaseID].Visible 				= ФайлФорматаXML;
		Items["ГруппаПараметрыПодключенияКФайлуXML" + BaseID].Visible 					= ФайлФорматаXML;
		Items["ГруппаПараметрыПодключенияКФайлуНеXML" + BaseID].Visible					= Not ФайлФорматаXML;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= ФайлФорматаXLS Or ФайлФорматаDOC;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Title		= ?(ФайлФорматаXLS, "Number книги", "Number таблицы");
		
		//Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= True;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= Not ФайлФорматаXML;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= Not ФайлФорматаXML;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= Not ФайлФорматаXML;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= ФайлФорматаXML;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= ФайлФорматаXML;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= ФайлФорматаXML;
				
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not ФайлФорматаXML;
		Items["CastKey2ToString" + BaseID].Visible 								= Not ФайлФорматаXML;
		Items["CastKey3ToString" + BaseID].Visible 								= Not ФайлФорматаXML;
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "NumberColumn"].Visible						= Not ФайлФорматаXML;
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= ФайлФорматаXML;
							
//#EndRegion 

//#Region Таблица
	ElsIf Object["BaseType" + BaseID] = 4 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= True;
		Items["ГруппаПараметрыПодключенияКФайлуОбщие" + BaseID].Visible					= False;
		Items["ГруппаПараметрыПодключенияКФайлуXMLJSON" + BaseID].Visible				= False;
		Items["ГруппаПараметрыПодключенияКФайлуXML" + BaseID].Visible					= False;
		Items["ГруппаПараметрыПодключенияКФайлуНеXML" + BaseID].Visible					= True;
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
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
		
//#EndRegion 

//#Region _1C_7_7_внешняя
	ElsIf Object["BaseType" + BaseID] = 5 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= True;
		Items["ГруппаВариантВерсияПлатформыБазы" + BaseID].Visible 						= False;
		Items["ConnectionToExternalBase" + BaseID + "ДрайверSQL"].Visible 				= False;
		Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 					= False;
		Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 				= "Path к базе";
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;
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
	
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "String JSON";
		
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= False;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= False;
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= True;
		Items["ГруппаПараметрыПодключенияКФайлуОбщие" + BaseID].Visible					= False;
		Items["ГруппаПараметрыПодключенияКФайлуXMLJSON" + BaseID].Visible 				= True;
		Items["ГруппаПараметрыПодключенияКФайлуXML" + BaseID].Visible 					= False;
		Items["ГруппаПараметрыПодключенияКФайлуНеXML" + BaseID].Visible					= False;
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
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["SettingsFile" + BaseID + "NumberColumn"].Visible						= False;
		Items["SettingsFile" + BaseID + "ColumnName"].Visible							= True;
							
//#EndRegion 

//#Region _1С_8_текущая
	Else 
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= True;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;
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

	
	ОбновитьВидимостьРеквизитовТЧ(BaseID);
	ОбновитьИтогиПоРеквизитамТЧ(BaseID);
				
EndProcedure

&AtClient
Procedure ОбновитьВидимостьКлючейТЧ(Форсировать = Ложь)
	
	ОбновитьВидимостьРеквизитаТЧ("Key1");
	ОбновитьВидимостьРеквизитаТЧ("Key2");
	ОбновитьВидимостьРеквизитаТЧ("Key3");
		
EndProcedure

&AtClient
Procedure ОбновитьВидимостьРеквизитовТЧ(BaseID = "")
	
	If ПустаяСтрока(BaseID) Then
		ОбновитьВидимостьРеквизитаТЧ("ЧислоЗаписейА");
		ОбновитьВидимостьРеквизитаТЧ("ЧислоЗаписейБ");
	Else 
		ОбновитьВидимостьРеквизитаТЧ("ЧислоЗаписей" + BaseID);
	EndIf;
	
	For Счетчик = 1 To 5 Do
		
		If ПустаяСтрока(BaseID) Then
			ОбновитьВидимостьРеквизитаТЧ("РеквизитА" + Счетчик);
			ОбновитьВидимостьРеквизитаТЧ("РеквизитБ" + Счетчик);
		Else
			ОбновитьВидимостьРеквизитаТЧ("Реквизит" + BaseID + Счетчик);
		EndIf; 
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьРеквизитаТЧ(AttributeName)
	
	ВидимостьКолонки = Object["Visibility" + AttributeName];
	Items["РезультатКомандаВидимость" + AttributeName].Check = ВидимостьКолонки;
	
	If ВРег(Лев(ИмяРеквизита, 4)) = "KEY" Then
		НомерКлюча = Сред(ИмяРеквизита,5,1);
		Items["Result" + ИмяРеквизита].Видимость = ВидимостьКолонки И Object.NumberColumnsInKey >= Number(НомерКлюча);
		Items["РезультатТипСтолбца" + НомерКлюча + "Ключа"].Видимость = Object.ОтображатьТипыСтолбцовКлюча И Object["VisibilityKey" + НомерКлюча] И Object.NumberColumnsInKey >= Число(НомерКлюча);
	Else
		Items["Result" + AttributeName].Visible = ВидимостьКолонки;
	EndIf;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация(РежимОтображения = 0)
	
	Items.CompareData.Enabled = Object.RelationalOperation > 0;
	For СчетчикОпераций = 1 To 7 Do 
		
		If СчетчикОпераций = Object.RelationalOperation Then
			If РежимОтображения = 1 Then
				ThisForm["Operation" + СчетчикОпераций] = ThisForm["ActiveOperationA1"];
			ElsIf РежимОтображения = 2 Then
				ThisForm["Operation" + СчетчикОпераций] = ThisForm["ActiveOperationA" + (4 + ?(СчетчикОпераций > 1, СчетчикОпераций + 2, СчетчикОпераций - 1) % 2)];
			Else
				ThisForm["Operation" + СчетчикОпераций] = ThisForm["ActiveOperation" + СчетчикОпераций];
			EndIf;
						
		Else
			If РежимОтображения = 1 Then
				ThisForm["Operation" + СчетчикОпераций] = ThisForm["ActiveOperation" + СчетчикОпераций];
			ElsIf РежимОтображения = 2 Then
				ThisForm["Operation" + СчетчикОпераций] = ThisForm["ActiveOperationA" + (2 + ?(СчетчикОпераций > 1, СчетчикОпераций + 2, СчетчикОпераций - 1) % 2)];
			Else
				ThisForm["Operation" + СчетчикОпераций] = ThisForm["InactiveOperation" + СчетчикОпераций];
			EndIf;			
		EndIf;
		
	EndDo;		
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок()
	
	Items.BooleanOperatorForConditionsOutputRows.ReadOnly 		= Object.CodeForOutputRowsEditedManually;
	Items.ConditionsOutputRows.ReadOnly 								= Object.CodeForOutputRowsEditedManually;
	Items.BooleanOperatorForProhibitingConditionsOutputRows.ReadOnly 	= Object.CodeForProhibitingOutputRowsEditedManually;
	Items.ConditionsProhibitOutputRows.ReadOnly 						= Object.CodeForProhibitingOutputRowsEditedManually;
	
	Items.CodeForOutputRows.ReadOnly 								= Not Object.CodeForOutputRowsEditedManually;
	Items.CodeForProhibitingOutputRows.ReadOnly 						= Not Object.CodeForProhibitingOutputRowsEditedManually;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьВкладкиУсловияВыводаСтрок()
	
	Items.GroupConditionsOutputRows.BgColor = ?(Object.ConditionsOutputRowsDisabled, WebColors.Pink, ColorBackgroundFormDefault);;
		
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьВкладкиУсловияЗапретаВыводаСтрок()
	
	Items.GroupConditionsProhibitOutputRows.BgColor = ?(Object.ConditionsProhibitOutputRowsDisabled, WebColors.Pink, ColorBackgroundFormDefault);;
		
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьПорядкаСортировкиТаблицыРасхождений()
	
	Items.OrderSortTableDifferences.ReadOnly = Not Object.SortTableDifferences;
	
EndProcedure
#EndRegion 


#Region Settings

#Region Save
&AtClient
Procedure SaveSettingsToFileAtClient(SaveSpreadsheetDocuments = False)
	
	Mode = FileDialogMode.Save;
	ДиалогВыбора = New FileDialog(Mode);
	ДиалогВыбора.FullFileName = Object.Title;
	Filter = "File xml (*.xml)|*.xml";
	ДиалогВыбора.Filter = Filter;
	ДиалогВыбора.Title = "Укажите файл для сохранения настроек";   

	ДиалогВыбора.Show(New NotifyDescription("SaveSettingsToFileAtClientEnd", ThisForm, New Structure("ДиалогВыбора,SaveSpreadsheetDocuments", ДиалогВыбора, SaveSpreadsheetDocuments)));
	
EndProcedure

&AtClient
Procedure SaveSettingsToFileAtClientEnd(SelectedFiles, AdditionalParameters) Export
	
	ДиалогВыбора = AdditionalParameters.ДиалогВыбора;
	SaveSpreadsheetDocuments = AdditionalParameters.SaveSpreadsheetDocuments;
	                             	
	If (SelectedFiles <> Undefined) Then
		
		Object.Title = Mid(ДиалогВыбора.FullFileName, StrFind(ДиалогВыбора.FullFileName, "\", SearchDirection.FromEnd) + 1);
		Address = SaveSettingsToFileAtServer(SaveSpreadsheetDocuments);
		BinaryData = GetFromTempStorage(Address);
		BinaryData.Write(ДиалогВыбора.FullFileName);
		
	EndIf;

EndProcedure

&AtClient
Procedure SaveSettingsToDatabaseAtClient(SaveSpreadsheetDocuments = False);
	
	If ValueIsFilled(Object.RelatedDataComparisonOperation)  Then
	
		ShowQueryBox(New NotifyDescription("СохранитьВСвязаннуюОперациюЗавершение", ThisObject, New Structure("ВыбратьЭлементСправочникаДляСохранения,SaveSpreadsheetDocuments",True,SaveSpreadsheetDocuments)), "Update элемент справочника """ + Object.RelatedDataComparisonOperation + """?", QuestionDialogMode.YesNo);
		
	Else
		
		ОткрытьФормуВыбораОперацииДляЗаписи(SaveSpreadsheetDocuments);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure СохранитьВСвязаннуюОперациюЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	SaveSpreadsheetDocuments = AdditionalParameters.SaveSpreadsheetDocuments;
	ВыбратьЭлементСправочникаДляСохранения = AdditionalParameters.ВыбратьЭлементСправочникаДляСохранения;
	ПриЗакрытииФормы = AdditionalParameters.Property("ПриЗакрытииФормы") And AdditionalParameters.ПриЗакрытииФормы;
	
	If РезультатВопроса = DialogReturnCode.Yes Then
		
		SaveSettingsToBaseAtServer(Object.RelatedDataComparisonOperation, SaveSpreadsheetDocuments);
		ОбновитьЗаголовок();
		
	//Click кнопки Save в базу
	ElsIf ВыбратьЭлементСправочникаДляСохранения = True And ПриЗакрытииФормы = False Then
		
		ОткрытьФормуВыбораОперацииДляЗаписи();
				
	EndIf;

EndProcedure

&AtClient
Procedure СохранитьВВыбраннуюОперациюЗавершение(Result, AdditionalParameters) Export
	
	SaveSpreadsheetDocuments = AdditionalParameters.SaveSpreadsheetDocuments;
	
	ВыбранныйЭлемент = Result;
	If ВыбранныйЭлемент <> Undefined Then
		
		SaveSettingsToBaseAtServer(ВыбранныйЭлемент, SaveSpreadsheetDocuments);
		ОбновитьЗаголовок();
				
	EndIf;

EndProcedure

&AtServer
Function SaveSettingsToFileAtServer(SaveSpreadsheetDocuments)
	
	PathToFile = GetTempFileName("xml");
	Data = ПолучитьДанныеВВидеСтруктуры(SaveSpreadsheetDocuments); 
	ХранилищеВнешнее = New ValueStorage(Data);
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(PathToFile, "UTF-8");
	XDTOSerializer.WriteXML(XMLWriter, ХранилищеВнешнее);
	XMLWriter.Close();
	Address = PutToTempStorage(New BinaryData(PathToFile));
	DeleteFiles(PathToFile);
	
	Return Address;
			
EndFunction

&AtServer
Procedure SaveSettingsToBaseAtServer(ВыбранныйЭлемент, SaveSpreadsheetDocuments = False)

	FormObject = FormAttributeToValue("Object");
	FormObject.SaveSettingsToBaseAtServer(ВыбранныйЭлемент, SaveSpreadsheetDocuments);
	ValueToFormAttribute(FormObject, "Object");
		
EndProcedure
#EndRegion 


#Region Load
&AtClient
Procedure OpenSettingsFromFileAtClient(Val Оповещение, ЗагружатьТабличныеДокументы = False)

	Mode = FileDialogMode.Opening;
	ДиалогВыбора = New FileDialog(Mode);
	ДиалогВыбора.FullFileName = "";
	Filter = "File xml (*.xml)|*.xml";
	ДиалогВыбора.Filter = Filter;
	ДиалогВыбора.Title = "Укажите файл с настройками";   

	ДиалогВыбора.Show(New NotifyDescription("OpenSettingsFromFileAtClientEnd", ThisForm, New Structure("ДиалогВыбора, Оповещение, ЗагружатьТабличныеДокументы", ДиалогВыбора, Оповещение, ЗагружатьТабличныеДокументы)));

EndProcedure

&AtClient
Procedure OpenSettingsFromFileAtClientEnd(SelectedFiles, AdditionalParameters) Export
	
	ДиалогВыбора = AdditionalParameters.ДиалогВыбора;
	Оповещение = AdditionalParameters.Оповещение;	
	ЗагружатьТабличныеДокументы = AdditionalParameters.ЗагружатьТабличныеДокументы;	
	
	If (SelectedFiles <> Undefined) Then
		
		Address = PutToTempStorage(New BinaryData(ДиалогВыбора.FullFileName));
		OpenSettingsFromFileAtServer(Address, ЗагружатьТабличныеДокументы);
		ПервыйСимвол = StrFind(ДиалогВыбора.FullFileName, "\", SearchDirection.FromEnd) + 1;
		ПоследнийСимвол = StrFind(ДиалогВыбора.FullFileName, ".", SearchDirection.FromEnd);
		Object.Title = Mid(ДиалогВыбора.FullFileName, ПервыйСимвол, ПоследнийСимвол - ПервыйСимвол);
		UpdateVisibilityAccessibilityFormItems();
		ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
		ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();
		ОбновитьВидимостьДоступностьПорядкаСортировкиТаблицыРасхождений();
		
	EndIf;
	
	ExecuteNotifyProcessing(Оповещение);

EndProcedure

&AtServer
Procedure OpenSettingsFromFileAtServer(Address, ЗагружатьТабличныеДокументы = False)
	
	PathToFile = GetTempFileName("xml");
	BinaryData = GetFromTempStorage(Address);
	BinaryData.Write(PathToFile);
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile,,,"UTF-8");
	ХранилищеВнешнее = XDTOSerializer.ReadXML(XMLReader);
	Data = ХранилищеВнешнее.Get();
	FillPropertyValues(Object, Data);
	
	If Data.Property("ТЗУсловияВыводаСтрок") Then
		Object.ConditionsOutputRows.Load(Data.ТЗУсловияВыводаСтрок);
	Else
		Object.ConditionsOutputRows.Clear();
	EndIf;
	
	If Data.Property("ТЗУсловияЗапретаВыводаСтрок") Then
		Object.ConditionsProhibitOutputRows.Load(Data.ТЗУсловияЗапретаВыводаСтрок);
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
	
	If ЗагружатьТабличныеДокументы Then
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
Procedure OpenSettingsFromBaseAtServer(ВыбранныйЭлемент, ЗагружатьТабличныеДокументы = False)
	
	FormObject = FormAttributeToValue("Object");
	FormObject.OpenSettingsFromBaseAtServer(ВыбранныйЭлемент, ЗагружатьТабличныеДокументы);
	ValueToFormAttribute(FormObject, "Object");
	
EndProcedure

&AtClient
Procedure OpenSettingsFromFileEnd(Result, AdditionalParameters) Export
	
	UpdateVisibilityAccessibilityFormItems();
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();

EndProcedure

&AtClient
Procedure ОткрытьФормуВыбораОперацииДляЗаписи(SaveSpreadsheetDocuments = False)

	ВыбранныйЭлемент = Undefined;
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("СохранитьВВыбраннуюОперациюЗавершение", ThisForm, New Structure("SaveSpreadsheetDocuments",SaveSpreadsheetDocuments)), FormWindowOpeningMode.БлокироватьВесьИнтерфейс);
	
EndProcedure

&AtClient
Procedure OpenSettingsFromBaseEnd(Result, AdditionalParameters) Export
	
	ВыбранныйЭлемент = Result;
	ЗагружатьТабличныеДокументы = AdditionalParameters <> Undefined And AdditionalParameters.Property("ЗагружатьТабличныеДокументы") And AdditionalParameters.ЗагружатьТабличныеДокументы;
	
	If ВыбранныйЭлемент <> Undefined Then
		
		OpenSettingsFromBaseAtServer(ВыбранныйЭлемент, ЗагружатьТабличныеДокументы);
		UpdateVisibilityAccessibilityFormItems();
		ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
		ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();
		
	EndIf;

EndProcedure
#EndRegion 

#EndRegion 


#Region Обработка_выбора_параметра
&AtClient
Procedure ПриНачалеВыбораЗначенияПараметра(BaseID, StandardProcessing)
	
	If Object["BaseType" + BaseID] = 1 Then
		StandardProcessing = False;
		СписокДоступныхТипов = New ValueList;
		СписокДоступныхТипов.Add("Number");
		СписокДоступныхТипов.Add("String");
		СписокДоступныхТипов.Add("Date");
		СписокДоступныхТипов.Add("Boolean");
		ВыбранныйТип = Undefined;

		ShowChooseFromList(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение4", ThisForm, New Structure("BaseID", BaseID)), СписокДоступныхТипов, Items["ParameterList" + BaseID + "ParameterValue"]);
	
	EndIf;

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение4(ВыбранныйЭлемент, AdditionalParameters) Export
	
	BaseID = AdditionalParameters.BaseID;
	
	
	ВыбранныйТип = ВыбранныйЭлемент;
	If ВыбранныйТип = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items["ParameterList" + BaseID].CurrentData;
	If CurrentData = Undefined Then
		ТекущееЗначениеПараметра = Undefined; 
	Else
		ТекущееЗначениеПараметра =  CurrentData.ParameterValue;
	EndIf;
	
	If ВыбранныйТип.Value = "Number" Then
		ShowInputNumber(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение3", ThisForm, New Structure("ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра", ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра);
		Return;
	ElsIf ВыбранныйТип.Value = "String" Then
		ShowInputString(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение2", ThisForm, New Structure("ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра", ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра);
		Return;
	ElsIf ВыбранныйТип.Value = "Date" Then
		ShowInputDate(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение1", ThisForm, New Structure("ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра", ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра);
		Return;
	ElsIf ВыбранныйТип.Value = "Boolean" Then
		ShowInputValue(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение", ThisForm, New Structure("CurrentData, ТекущееЗначениеПараметра", CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра,,New TypeDescription("Boolean"));
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент3(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение3(Number, AdditionalParameters) Export
	
	ВыбранныйТип = AdditionalParameters.ВыбранныйТип;
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(Number = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, Number);
	
	
	If Not (Number <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент3(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент3(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	ПриНачалеВыбораЗначенияПараметраФрагмент2(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение2(String, AdditionalParameters) Export
	
	ВыбранныйТип = AdditionalParameters.ВыбранныйТип;
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(String = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, String);
	
	
	If Not (String <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент2(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент2(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	ПриНачалеВыбораЗначенияПараметраФрагмент1(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение1(Date, AdditionalParameters) Export
	
	ВыбранныйТип = AdditionalParameters.ВыбранныйТип;
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(Date = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, Date);
	
	
	If Not (Date <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент1(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент1(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	ПриНачалеВыбораЗначенияПараметраФрагмент(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение(Value, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(Value = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, Value);
	
	
	If Not (Value <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	CurrentData.ParameterValue = ТекущееЗначениеПараметра;

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
	OpenQueryConstructor("Б");
EndProcedure

&AtClient
Procedure QueryConstructorA(Command)
	OpenQueryConstructor("А");
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
	
	ВыбранныйЭлемент = Undefined; 
	
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("OpenSettingsFromBaseEnd", ThisForm), FormWindowOpeningMode.БлокироватьВесьИнтерфейс);
	
EndProcedure

&AtClient
Procedure LoadSettingsAndSpreadsheetDocumentsFromDatabase(Command)
	
	ВыбранныйЭлемент = Undefined; 
	
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("OpenSettingsFromBaseEnd", ThisForm, New Structure("ЗагружатьТабличныеДокументы", True)), FormWindowOpeningMode.БлокироватьВесьИнтерфейс);
	
EndProcedure

&AtClient
Procedure CommandGetQueryParametersA(Command)
	
	ПолучитьПараметрыИзЗапросаНаСервере("А");
	Items.GroupPagesBaseA.CurrentPage = Items.GroupPageQueryParametersA;
	
EndProcedure

&AtClient
Procedure CommandGetQueryParametersB(Command)
	
	ПолучитьПараметрыИзЗапросаНаСервере("Б");
	Items.GroupPagesBaseB.CurrentPage = Items.GroupPageQueryParametersB;
	
EndProcedure

&AtClient
Procedure ПосетитьСтраницуАвтора(Command)

	BeginRunningApplication(New NotifyDescription("ПосетитьСтраницу", ThisForm), "http://sertakov.by");
	
EndProcedure

&AtClient
Procedure VisitPageProcessing(Command)
	
	BeginRunningApplication(New NotifyDescription("ПосетитьСтраницу", ThisForm), "https://infostart.ru/public/581794/");
	
EndProcedure

&AtClient
Procedure CommandDownloadProcessing(Command)
	
	BeginRunningApplication(New NotifyDescription("ПосетитьСтраницу", ThisForm), "http://sertakov.by/work/KSD.epf");
	
EndProcedure

&AtClient
Procedure CommandPreviewSourceA(Command)
	
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация(1);
	
EndProcedure

&AtClient
Procedure CommandPreviewSourceB(Command)
	
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация(2);
	
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_AllRows(Command)	
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А");	
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_100Rows(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А",100);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А (100 строк)");
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_100Rows(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б",100);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б (100 строк)");
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_AllRows(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б");
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_Duplicates(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А",,True);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А (дубликаты)");
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_Duplicates(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б",,True);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б (дубликаты)");
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceA_1000Rows(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А",1000);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А (1000 строк)");
	EndIf;
EndProcedure

&AtClient
Procedure CommandPreviewSourceB_1000Rows(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б",1000);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б (1000 строк)");
	EndIf;
EndProcedure

#EndRegion


#Region Обработчики_событий
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NumberOfAttributes = 5;
	ColorBackgroundFormDefault = StyleColors.FormBackColor;
	
	If Parameters.Property("UserMode") And Parameters.UserMode Then
		Object.UserMode = True;
	EndIf;
	
	If Parameters.Property("ОперацияСравненияДанных") And ValueIsFilled(Parameters.ОперацияСравненияДанных) Then
		
		Object.RelatedDataComparisonOperation = Parameters.ОперацияСравненияДанных;
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
		
		For Счетчик = 1 To NumberOfAttributes Do
			Object["VisibilityAttributeA" + Счетчик] = True;
			Object["VisibilityAttributeB" + Счетчик] = True;
		EndDo;
		
		For Счетчик = 1 To 20 Do 
			
			Object.TableA.Region(1,Счетчик,1,Счетчик).Text = Счетчик;
			Object.TableB.Region(1,Счетчик,1,Счетчик).Text = Счетчик;
			
		EndDo;
		
	EndIf;
		
	Example1 = "КлючТек = Left(КлючТек,10);";
	Example2 = "КлючТек = Number(КлючТек) + 1;";
	Example3 = "If Left(КлючТек,1) = ""#"" Then КлючТек = Mid(КлючТек, 2); EndIf;";
	Example4 = "КлючТек = Right(""0000000000"" + КлючТек, 10);";
	Example5 = "КлючТек = StrReplace(КлючТек, ""_"", """");";
	Example6 = "КлючТек = ?(ValueIsFilled(КлючТек), КлючТек, ""<>"");";
	
	If Object.UserMode Then
		
		Items.GroupHeaderHiddenAttributes.Visible = False;
		Items.GroupBaseAPage.Visible = False;
		Items.GroupBaseBPage.Visible = False;
		Items.GroupOutputSettings.Visible = False;
		Items.GroupMain.PagesRepresentation = FormPagesRepresentation.None;
		Items.РезультатКомандаВыгрузитьРезультатВФайлНаСервере.Visible = False;
		Items.РезультатГруппаВидимостьСтолбцовКлюча.Visible = False;
				
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
		Items.ГруппаПанель2);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateVisibilityAccessibilityFormItems();
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();
	ОбновитьВидимостьДоступностьПорядкаСортировкиТаблицыРасхождений();
	UpdateCodeToOutputAndProhibitOutputRows();
		
EndProcedure

&AtClient
Procedure ОперацияНажатие(Item, StandardProcessing)
	
	StandardProcessing = False;
	Object.RelationalOperation = Number(Right(Item.Name,1));
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	If Not ClosingFormConfirmed Then
		Cancel = True;
		ShowQueryBox(New NotifyDescription("BeforeCloseEnd", ThisForm),"Close консоль сравнения данных?", QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure OnClose(ЗавершениеРаботы)
	
	If ValueIsFilled(Object.RelatedDataComparisonOperation) And Not Object.UserMode  Then
		
		ShowQueryBox(New NotifyDescription("СохранитьВСвязаннуюОперациюЗавершение", ThisObject, New Structure("ВыбратьЭлементСправочникаДляСохранения,SaveSpreadsheetDocuments,ПриЗакрытииФормы",True,False,True)), "Update элемент справочника """ + Object.RelatedDataComparisonOperation + """?", QuestionDialogMode.YesNo);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure ПосетитьСтраницу(КодВозврата, AdditionalParameters) Export
	
	

EndProcedure

&AtClient
Procedure КодДляВыводаСтрокРедактируетсяВручнуюПриИзменении(Item)
	
	If Not Object.CodeForOutputRowsEditedManually Then
		
		ShowQueryBox(New NotifyDescription("КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение", ThisForm), "Code, внесенный вручную будет утерян. Continue?", QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();
EndProcedure

&AtClient
Procedure КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	If РезультатВопроса = DialogReturnCode.None Then
		Object.CodeForOutputRowsEditedManually = True;
		Return;
	EndIf;
	
	
	КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();

EndProcedure

&AtClient
Procedure КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент()
	
	UpdateCodeToOutputAndProhibitOutputRows();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();

EndProcedure

&AtClient
Procedure CodeForProhibitingOutputRowsEditedManuallyOnChange(Item)
	
	If Not Object.CodeForProhibitingOutputRowsEditedManually Then
		
		ShowQueryBox(New NotifyDescription("КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение", ThisForm), "Code, внесенный вручную будет утерян. Continue?", QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();
EndProcedure

&AtClient
Procedure КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	If РезультатВопроса = DialogReturnCode.None Then
		Object.CodeForProhibitingOutputRowsEditedManually = True;
		Return;
	EndIf;
	
	
	КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();

EndProcedure

&AtClient
Procedure КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент()
	
	UpdateCodeToOutputAndProhibitOutputRows();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();

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
Procedure ЛогическийОператорДляУсловийВыводаСтрокПриИзменении(Item)
	UpdateCodeToOutputAndProhibitOutputRows();
EndProcedure

&AtClient
Procedure CommandVisibilityColumnTP(Command)
	
	AttributeName = StrReplace(Command.Name, "CommandVisibility", "");
	
	Object["Visibility" + AttributeName] = Not Object["Visibility" + AttributeName];
	
	ОбновитьВидимостьРеквизитаТЧ(AttributeName);
		
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
Procedure ПодключениеКВнешнейБазеАПутьКФайлуНачалоВыбора(Item, ChoiceData, StandardProcessing)
	
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
		
	FileDialog.Title = "Выберите файл";
	FileDialog.FilterIndex = 0;
	FileDialog.Show(New NotifyDescription("ПодключениеКВнешнейБазеАПутьКФайлуНачалоВыбораЗавершение", ThisForm, New Structure("FileDialog", FileDialog)));
	
EndProcedure

&AtClient
Procedure ПодключениеКВнешнейБазеАПутьКФайлуНачалоВыбораЗавершение(SelectedFiles, AdditionalParameters) Export
	
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
		
	FileDialog.Title = "Выберите файл";
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
	
	StandardProcessing = Ложь;
	пТекущаяСтрока = Items.SettingsFileB.CurrentData;
	If пТекущаяСтрока <> Undefined Then
		пТекущаяСтрока.АгрегатнаяФункцияРасчетаИтога = "Сумма";
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileAAggregateFunctionCalculationTotalClearing(Item, StandardProcessing)
	
	StandardProcessing = Ложь;
	пТекущаяСтрока = Items.SettingsFileA.CurrentData;
	If пТекущаяСтрока <> Undefined Then
		пТекущаяСтрока.АгрегатнаяФункцияРасчетаИтога = "Сумма";
	EndIf;

EndProcedure


&AtClient
Procedure SettingsFileAOnChange(Item)
	
	пТекущаяСтрока = Items.SettingsFileA.CurrentData;
	If пТекущаяСтрока <> Undefined Then
		If ПустаяСтрока(пТекущаяСтрока.АгрегатнаяФункцияРасчетаИтога) Then
			пТекущаяСтрока.АгрегатнаяФункцияРасчетаИтога = "Сумма";
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileBOnChange(Item)
	
	пТекущаяСтрока = Items.SettingsFileB.CurrentData;
	If пТекущаяСтрока <> Undefined Then
		If ПустаяСтрока(пТекущаяСтрока.АгрегатнаяФункцияРасчетаИтога) Then
			пТекущаяСтрока.АгрегатнаяФункцияРасчетаИтога = "Сумма";
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
Procedure ПриИзмененииКлючевогоРеквизита(Item)
	
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure ParameterListAParameterValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	Items.ParameterListAParameterValue.ChooseType = TypeOf(Items.ParameterListA.CurrentData.ParameterValue) = Type("Undefined");	
	ПриНачалеВыбораЗначенияПараметра("А", StandardProcessing);
	
EndProcedure

&AtClient
Procedure ParameterListAParameterValueOnChange(Item)
	
	ТекущийПараметр = Object.ParameterListA.FindByID(Items.ParameterListA.CurrentData.GetID());
	ТекущийПараметр.ParameterType = TypeOf(ТекущийПараметр.ParameterValue);

EndProcedure

&AtClient
Procedure ParameterListBParameterValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	Items.ParameterListBParameterValue.ChooseType = TypeOf(Items.ParameterListB.CurrentData.Значениепараметра) = Type("Undefined");	
	ПриНачалеВыбораЗначенияПараметра("Б", StandardProcessing);
		
EndProcedure

&AtClient
Procedure ParameterListBParameterValueOnChange(Item)
	
	ТекущийПараметр = Object.ParameterListB.FindByID(Items.ParameterListB.CurrentData.GetID());
	ТекущийПараметр.ParameterType = TypeOf(ТекущийПараметр.ParameterValue);
	
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
Procedure ПриИзмененииФлагаВыполнятьПроизвольныйКодКлюча(Item)
	
	ОбновитьРеквизитыПроизвольныйКод();
	
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
		ЗаполнитьТипыСтолбцовКлючаВоВсехСтроках();
	EndIf;
	UpdateVisibilityAccessibilityFormItems();
	
EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnServer(Command)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = "Not задан формат файла выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
	
	If IsBlankString(Object.PathToDownloadFile) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.PathToDownloadFile";
		UserMessage.Text = "Not задан путь к файлу выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
			
	Ответ = Undefined; 	
	ShowQueryBox(New NotifyDescription("CommandUploadResultToFileOnServerEnd", ThisForm), "Unload таблицу в файл на сервере?", QuestionDialogMode.YesNo, , DialogReturnCode.None, "Выгрузка");
	
EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnServerEnd(РезультатВопроса, AdditionalParameters) Export
	
	Ответ = РезультатВопроса; 
	If Ответ = DialogReturnCode.None Then
		Return;
	EndIf;
	
	ВыгрузитьРезультатВФайлНаСервере(False, RepresentationHeadersAttributes);

EndProcedure

&AtClient
Procedure PathToDownloadFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = "Not задан формат файла выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
	
	Mode = FileDialogMode.Save;
	ДиалогВыбора = New FileDialog(Mode);
	ДиалогВыбора.FullFileName = Object.Title;
	Filter = "File " + Object.UploadFileFormat + " (*." + Object.UploadFileFormat + ")|*." + Object.UploadFileFormat + "";
	ДиалогВыбора.Filter = Filter;
	ДиалогВыбора.Title = "Укажите файл для сохранения результата сравнения";   

	ДиалогВыбора.Show(New NotifyDescription("ПутьКФайлуВыгрузкиНачалоВыбораЗавершение", ThisForm, New Structure("ДиалогВыбора", ДиалогВыбора)));
	
EndProcedure

&AtClient
Procedure ПутьКФайлуВыгрузкиНачалоВыбораЗавершение(SelectedFiles, AdditionalParameters) Export
	
	ДиалогВыбора = AdditionalParameters.ДиалогВыбора;	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.PathToDownloadFile =  ДиалогВыбора.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure CommandUploadResultToFileOnClient(Command)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = "Not задан формат файла выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
	
	ShowQueryBox(New NotifyDescription("CommandUploadResultToFileOnClientEndQuestion", ThisForm), "Unload таблицу в файл на клиенте?", QuestionDialogMode.YesNo,, DialogReturnCode.None, "Выгрузка");
	
EndProcedure

&AtClient
Procedure ТипПериодаПриИзменении(Item)
	
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
	
	ОбновитьВидимостьДоступностьВкладкиУсловияВыводаСтрок();
	
EndProcedure

&AtClient
Procedure ConditionsProhibitOutputRowsDisabledOnChange(Item)
	
	ОбновитьВидимостьДоступностьВкладкиУсловияЗапретаВыводаСтрок();
	
EndProcedure

&AtClient
Procedure SortTableDifferencesOnChange(Item)
	
	ОбновитьВидимостьДоступностьПорядкаСортировкиТаблицыРасхождений();
		
EndProcedure

&AtClient
Procedure OrderSortTableDifferencesStartChoice(Item, ChoiceData, StandardProcessing)
	
	ReturnValue = Undefined;
	
	OpenForm(StrReplace(FormName, "Form", "SortingSettingsForm")
		, New Structure("OrderSortTableDifferences", Object.OrderSortTableDifferences)
		,
		,
		,
		,
		, New NotifyDescription("OrderSortTableDifferencesStartChoiceEnd", ThisForm)
		, РежимОткрытияОкнаФормы.БлокироватьВесьИнтерфейс);
	
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