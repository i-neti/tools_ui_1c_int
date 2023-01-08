&AtClient
Var UT_CodeEditorClientData Export;

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillParametersTable();

	If Not Parameters.Key.IsEmpty() Then

		AlgorithmTextSettings = CommonSettingsStorage.GetList(String(Parameters.Key) + "-n1");

		For Each ListItem In AlgorithmTextSettings Do

			AlgorithmTextSetting = CommonSettingsStorage.Load(String(Parameters.Key) + "-n1",
				ListItem.Value);
			Items.AlgorithmText[ListItem.Value] = AlgorithmTextSetting;
		EndDo;

	EndIf;

	FillFormFieldsChoiceLists();

	SetVisibleAndEnabled();
	
	// CodeEditor
	UT_CodeEditorServer.FormOnCreateAtServer(ThisObject);
	UT_CodeEditorServer.CreateCodeEditorItems(ThisObject,"Algorithm" ,Items.FieldAlgorithmText);
	//CodeEditor
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	SetVisibleAndEnabled();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
		If EventName = "ParameterChanged" Then
		Read();
		FillParametersTable();
	ElsIf EventName = "Update" Then
		Read();
	ElsIf EventName = "UpdateCode" Then
		Read();
		Write();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeadEventsHandlers

&AtClient
Procedure GroupPagesPanelOnCurrentPageChange(Item, CurrentPage)
		If Modified And CurrentPage.Name <> "GroupCode" Then
		Write();
	EndIf;
EndProcedure

&AtClient
Procedure AtClientOnChange(Item)
	SetVisibleAndEnabled();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers_Parameters

&AtClient
Procedure ParametersTableBeforeDeleteRow(Item, Cancel)
	ShowQueryBox(New NotifyDescription("ParametersTableBeforeDeleteEnd", ThisObject,
		New Structure("String,Parameter", Item.CurrentLine, Item.CurrentData.Parameter)), Nstr("ru = 'Элемент структуры настроек будет удален без возможности  восстановления !';
		|en = 'The element of the settings structure will be deleted without the possibility of recovery !'")
		+ Chars.LF +Nstr("ru = 'Продолжить выполнение ?';en = 'Continue execution ?'"), QuestionDialogMode.YesNoCancel);
	Cancel = True;
EndProcedure
&AtClient
Procedure ParametersTableBeforeDeleteEnd(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.Yes Then
		If DeleteParameterAtServer(AdditionalParameters.Parameter) Then
			Read();
			FillParametersTable();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ParametersTableParameterOpening(Item, StandardProcessing)
		StandardProcessing = False;
	If Item.Parent.CurrentData.TypeDescription = "Value table"
		Or Item.Parent.CurrentData.TypeDescription = "Binary data" Then
		Return;
	EndIf;
	Try
		Value = GetParameterAtServer(Items.ParametersTable.CurrentData.Parameter);
		ShowValue( , Value);
	Except
		Message(ErrorDescription());
	EndTry;
EndProcedure

&AtClient
Procedure ParametersTableOnActivateRow(Item)
		If Item.CurrentData = Undefined Then
		Return;	
	EndIf;
	If SelectedParameter <> Item.CurrentData.Parameter Then
		SelectedParameter = Item.CurrentData.Parameter;	
		AttachIdleHandler("RepresentParameterValue", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure EditParametersEnd(Result, AdditionalParameters) Export
	
	AttachIdleHandler("RepresentParameterValue", 0.1, True);

EndProcedure


&AtClient
Procedure RepresentParameterValue()
	
	If  Items.ParametersTable.CurrentData = Undefined Then
		Return;	
	EndIf;
	
	Items.ParameterCollection.Visible = False;
	Items.DecorationGapParameterValues.Visible = False;
	Items.PrimitiveTypeParameterValue.Visible = False;
	
	RepresentParameterValueServer(Items.ParametersTable.CurrentData.Parameter, Items.ParametersTable.CurrentData.TypeDescription);	
EndProcedure

&AtServer
Procedure RepresentParameterValueServer(ParameterName, TypeOfStringParameter)
	SelectedObject=FormAttributeToValue("Object");
	Parameter = SelectedObject.GetParameter(ParameterName);
    TypeDescription = New TypeDescription();
	
	Map = New Map;
	Map.Insert("Array", "Collection");
	Map.Insert("Structure", "Collection");
	Map.Insert("Map", "Collection");
	Map.Insert("Value Table", "Collection");
	Map.Insert("Binary data", "ExternalFile");
	Map.Insert(Undefined, "AvailableTypes");
	ParameterType = Map.Get(TypeOfStringParameter);
	If ParameterType = Undefined Then
		PrimitiveTypeParameterValue = Parameter;
		Items.PrimitiveTypeParameterValue.Visible = True;
	ElsIf ParameterType = "Collection" Then
		ItemsToDeletion = New Array;
		For Each CollectionItem In Items.ParameterCollection.ChildItems Do
			ItemsToDeletion.Add(CollectionItem.Name);
		EndDo;
        UT_Forms.DeleteColumnsNL(ThisObject, ItemsToDeletion, "ParameterCollection");		
		If TypeOfStringParameter = "Array" Then
			UT_Forms.AddColumnNL(ThisObject, "Value", TypeDescription, "ParameterCollection");
			Table = UT_Common.CollectionToValueTable(Parameter);
			ParameterCollection.Load(Table);
		ElsIf TypeOfStringParameter = "Structure" Then
			TD = New TypeDescription("String", , New StringQualifiers(20, AllowedLength.Variable));
			UT_Forms.AddColumnNL(ThisObject, "Key", TD, "ParameterCollection");
			UT_Forms.AddColumnNL(ThisObject, "Value", TypeDescription, "ParameterCollection");
			Table = UT_Common.CollectionToValueTable(Parameter);
			ParameterCollection.Load(Table);
		ElsIf TypeOfStringParameter = "Map" Then
			UT_Forms.AddColumnNL(ThisObject, "Key", TypeDescription, "ParameterCollection");
			UT_Forms.AddColumnNL(ThisObject, "Value", TypeDescription, "ParameterCollection");
			Table = UT_Common.CollectionToValueTable(Parameter);
			ParameterCollection.Load(Table);
		Else
			For Each Column In Parameter.Columns Do
				UT_Forms.AddColumnNL(ThisObject, Column.Name, Column.ValueType, "ParameterCollection");
			EndDo;
			ParameterCollection.Load(Parameter);
		EndIf;
		Items.ParameterCollection.Visible = True;
	Else
		Parameters.ParameterType="ExternalFile";
	EndIf;
	Items.DecorationGapParameterValues.Visible = True;	
EndProcedure

#EndRegion

#Region FormCommandsHandlers
///
&AtClient
Procedure AddParameter(Command)
	FormParameters = New Structure("Key", Object.Ref);
	OpenForm("Catalog.UT_Algorithms.Form.ParameterForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure EditName(Command)
	If Items.ParametersTable.CurrentData = Undefined Then
		Return;
	EndIf 	;
	FormParameters = New Structure("Key,ParameterName,Rename", Parameters.Key,
		Items.ParametersTable.CurrentData.Parameter, True);
	OpenForm("Catalog.UT_Algorithms.Form.ParameterForm", FormParameters, ThisObject);
EndProcedure

&AtClient
Procedure EditValue(Command)
		If Items.ParametersTable.CurrentData <> Undefined Then
		Notify = New NotifyDescription("EditParametersEnd", ThisObject);
		FormParameters = New Structure;
		FormParameters.Insert("Key", Parameters.Key);
		FormParameters.Insert("ParameterName", Items.ParametersTable.CurrentData.Parameter);
		FormParameters.Insert("ParameterType", Items.ParametersTable.CurrentData.TypeDescription);
		OpenForm("Catalog.UT_Algorithms.Form.ParameterForm", FormParameters, ThisObject,,,, Notify);
	Endif;
EndProcedure

///
&AtClient
Procedure ExecuteProcedure(Command)
	//TODO    When changing the code when using monako, there is no sign of modification
   // this is why there is a record every time, it is necessary to find out how changing the text can change this flag	
	Write();

	StartTime = CurrentUniversalDateInMilliseconds();

	Error = False;
	ErrorMessage = "";
	TransmittedStructure = New Structure;
	
	If Object.AtClient Then
		ExecuteAlgorithmAtClient(TransmittedStructure);
	else
		UT_AlgorithmsServerCall.ExecuteAlgorithm(Object.Ref);
	Endif;

	Items.ExecuteProcedure.Title =StrTemplate(NStr("ru = 'Выполнить процедуру (%1 мс.)';en = 'Execute procedure (%1 ms.)'"),Строка(CurrentUniversalDateInMilliseconds()
		- StartTime));
EndProcedure

///
&AtClient
Procedure ShowQueryWizard(Command)
	Wizard = New QueryWizard;
	SelectedText = Items.AlgorithmText.SelectedText;
	WholeText = Items.AlgorithmText.EditText;
	FoundWholeTextInQuotationMarks(SelectedText, WholeText);
	Wizard.Text = StrReplace(SelectedText, "|", "");
	AdditionalParameters = New Structure("WizardFirstCall,WholeText,SelectedText", StrFind(
		SelectedText, "SELECT") = 0, WholeText, SelectedText);
	Notification = New NotifyDescription("GetQueryText", ThisObject, AdditionalParameters);
	Wizard.Show(Notification);
EndProcedure

&AtClient
Procedure FormatText(Command)
	Text = Object.AlgorithmText;
	Text = StrReplace(Text, Chars.LF, " \\ ");
	Text = StrReplace(Text, Chars.Tab, " ");
	Text = StrReplace(Text, "=", " = ");
	Text = StrReplace(Text, "< =", " <=");
	Text = StrReplace(Text, "> =", " >=");
	For А = 0 To Round(Sqrt(StrOccurrenceCount(Text, "  ")), 0) Do
		Text = StrReplace(Text, "  ", " ");
	EndDo;
	Text = StrReplace(Text, " ;", ";");
	WordsArray = StrSplit(Text, Char(32));
	FormattedText = "";
	TabulationString = "";
	WordsTypes = New Array;
	WordsTypes.Add(StrSplit("THEN,DO,\\", ",")); // right transfer
	WordsTypes.Add(StrSplit("IF,WHILE,FOR", ",")); // operator brackets open
	WordsTypes.Add(StrSplit("ENDDO;,ENDIF;", ",")); // operator brackets close
	WordsTypes.Add(StrSplit("ELSE,ELSIF", ",")); //operator brackets inside
	WasType = New Map;
	For Iterator = 0 To WordsArray.Count() - 1 Do
		FormatBefore = "";
		FormatAfter = "";

		WordType = WordType(WordsArray[Iterator], WordsTypes);

		If WordType["OpenBracket"] Then
			TabulationString = TabulationString + Chars.Tab;
		EndIf;

		If WordType["InsideBracket"] Then
			FormattedText = Left(FormattedText, StrLen(FormattedText) - 1);
		EndIf;

		If WordType["CloseBracket"] Then
			TabulationString = Left(TabulationString, StrLen(TabulationString) - 1);
			FormattedText = Left(FormattedText, StrLen(FormattedText) - 1);
		EndIf;

		If WordType["RightTransfer"] And Not WasType["RightTransfer"] Then
			FormatAfter = Chars.LF + TabulationString;
		EndIf;

		FormattedText = FormattedText + FormatBefore + WordsArray[Iterator] + Char(32) + FormatAfter;

		WasType = WordType;
	EndDo;

	FormattedText = StrReplace(FormattedText, "\\ ", "");
	FormattedText = StrReplace(FormattedText, "\\", "");
	Object.AlgorithmText = FormattedText;

EndProcedure

&AtClient
Procedure AddScheduledJob(Command)
	If Object.AtClient Then
		Message(Nstr("ru = 'это клиентская процедура';en = 'This is a client procedure'"));
		Return;
	EndIf;
	CreateScheduledJob();
EndProcedure

&AtClient
Procedure DeleteScheduledJob(Command)
	DeleteScheduledJobAtServer();
EndProcedure

&AtClient
Procedure EventLog(Command)
	ConnectExternalDataProcessorAtServer();
	OpenParameters = New Structure;
	OpenParameters.Insert("Data", Object.Ref);
	OpenParameters.Insert("StartDate", BegOfDay(CurrentDate()));
	OpenForm("ExternalDataProcessor.StandardEventLog.Form", OpenParameters);
EndProcedure

#EndRegion

#Region Private

#Region WorkWithParameters

&AtServer
Procedure FillParametersTable()
	SelectedObject = FormAttributeToValue("Object");
	TableOfParameters = FormAttributeToValue("ParametersTable");
	TableOfParameters.Clear();
	ParametersStructure = SelectedObject.Storage.Get();
	If Not ParametersStructure = Undefined Then
		For Each StructureItem In ParametersStructure Do
			NewRow = TableOfParameters.Add();
			NewRow.Parameter = StructureItem.Key;
			NewRow.TypeDescription = GetTypeDescriptionString(StructureItem.Value);
		EndDo;
		ValueToFormAttribute(TableOfParameters, "ParametersTable");
	EndIf;
EndProcedure

&AtServer
Function GetTypeDescriptionString(Value)
	If XMLTypeOf(Value) <> Undefined Then
		Return XMLType(TypeOf(Value)).TypeName;
	Else
		Return String(TypeOf(Value));
	EndIf;
EndFunction

&AtServer
Procedure AddNewParameterAtServer(ParameterStructure)
	ChangeParameter(ParameterStructure);
EndProcedure

&AtServer
Function DeleteParameterAtServer(Key)
	SelectedObject = FormAttributeToValue("Object");
	Return SelectedObject.RemoveParameter(Key);
EndFunction

&AtServer
Function GetParameterAtServer(ParameterName, IsJSON = False)
	SelectedObject = FormAttributeToValue("Object");
	ReceivedParameterValue = SelectedObject.GetParameter(ParameterName);
	If TypeOf(ReceivedParameterValue) = Type("ValueTable") Then
		

		ReceivedParameterValue = Common.ValueTableToArray(ReceivedParameterValue);
		IsJSON = True;
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, ReceivedParameterValue); 
		JsonResponseString = JSONWriter.Close();

		Return JsonResponseString;	
	EndIf;
	Return ReceivedParameterValue;
EndFunction

&AtServer
Procedure ChangeParameter(NewData) Export
	ParameterName = NewData.ParameterName;
	If TypeOf(NewData.ParameterValue) = Type("String") Then
		If Left(NewData.ParameterValue, 1) = "{" Then
			Position = StrFind(NewData.ParameterValue, "}");
			If Position > 0 Then
				StorageURL = Mid(NewData.ParameterValue, Position + 1);
				ParameterValue = GetFromTempStorage(StorageURL);
				FileExtention = StrReplace(Mid(NewData.ParameterValue, 2, Position - 2), Char(32), "");
				ParameterName = "File" + Upper(FileExtention) + "_" + ParameterName;
			Else
				If Object.ThrowException Then
					Raise NSTR("ru = 'Ошибка при чтении файла из хранилища';en = 'Error when reading a file from storage'");
				EndIf;
			EndIf;
		Else
			ParameterValue = NewData.ParameterValue;
		EndIf;
	Else
		ParameterValue = NewData.ParameterValue;
	EndIf;
EndProcedure

#EndRegion

#Region WorkWithScript

&AtClient
Procedure MarkError(ErrorText)
	ErrorPosition = StrFind(ErrorText, "{(");
	If ErrorPosition > 0 Then
		PositionBracketClosed = StrFind(ErrorText, ")}", , ErrorPosition);
		If PositionBracketClosed > 0 Then
			PositionComma = StrFind(Left(ErrorText, PositionBracketClosed), ",", , ErrorPosition);
			If PositionComma > 0 Then
				TextLineNumber = Mid(ErrorText, ErrorPosition + 2, StrLen(Left(ErrorText, PositionComma)) - StrLen(
					Left(ErrorText, ErrorPosition)) - 2);
			Else
				TextLineNumber = Mid(ErrorText, ErrorPosition + 2, StrLen(Left(ErrorText, PositionBracketClosed))
					- StrLen(Left(ErrorText, ErrorPosition)) - 2);
			EndIf;
			// nested error e.g. request
			ErrorPosition2 = StrFind(ErrorText, "{(", , , 2);
			If ErrorPosition2 > 0 Then
				PositionBracketClosed2 = StrFind(ErrorText, ")}", , ErrorPosition2);
				If PositionBracketClosed2 > 0 Then
					PositionComma2 = StrFind(Left(ErrorText, PositionBracketClosed2), ",", , ErrorPosition2);
					If PositionComma2 > 0 Then
						TextLineNumber2 = Mid(ErrorText, ErrorPosition2 + 2, StrLen(Left(ErrorText, PositionComma2))
							- StrLen(Left(ErrorText, ErrorPosition2)) - 2);
					Else
						TextLineNumber2 = Mid(ErrorText, ErrorPosition2 + 2, StrLen(Left(ErrorText,
							PositionBracketClosed2)) - StrLen(Left(ErrorText, ErrorPosition2)) - 2);
					EndIf;
				EndIf;
			EndIf;
			Try
				LineNumber = Number(TextLineNumber);
				StringsArray = StrSplit(Object.Text, Chars.LF, True);
				StringsArray[LineNumber - 1] = StringsArray[LineNumber - 1] + " <<<<<";
				If ErrorPosition2 > 0 Then
					LineNumber2 = Number(TextLineNumber2);
					Ъ = LineNumber - 1;
					While Ъ >= 0 Do
						If StrFind(StringsArray[Ъ], "SELECT") > 0 Or StrFind(StringsArray[Ъ], "Select") > 0 Or StrFind(
							StringsArray[Ъ], "select") > 0 Then
							StringsArray[Ъ + LineNumber2 - 1] = StringsArray[Ъ + LineNumber2 - 1] + " <<<<<";
						EndIf;
						Ъ = Ъ - 1;
					EndDo;
				EndIf;
				Object.Text = StrConcat(StringsArray, Chars.LF);
			Except
				Return;
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure HighlightChangedCode()
	Modified = True;
EndProcedure

&AtClient
Procedure FoundWholeTextInQuotationMarks(SelectedText, WholeText)
	If StrLen(SelectedText) > 10 Then // we need a unique text , we need to check the number of inclusions in a good way
		SeachingHere = StrFind(WholeText, SelectedText);
		FoundQuotationMarkBefore = 0;
		For А = 1 To StrOccurrenceCount(WholeText, """") Do
			FoundQuotationMarkAfter = StrFind(WholeText, """", , , А);
			If FoundQuotationMarkAfter > SeachingHere Then
				SelectedText = Mid(WholeText, FoundQuotationMarkBefore + 1, StrLen(Left(WholeText, FoundQuotationMarkAfter))
					- StrLen(Left(WholeText, FoundQuotationMarkBefore)) - 1);
				Break;
			EndIf;
			FoundQuotationMarkBefore = FoundQuotationMarkAfter;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure GetQueryText(Text, AdditionalParameters) Export
	If Text = Undefined Then
		Return;
	EndIf;
	StringsArray = StrSplit(Text, Chars.LF);
	QueryText = StringsArray[0];
	For Iterator = 1 To StringsArray.Count() - 1 Do
		QueryText = QueryText + Chars.LF + "|" + TrimAll(StringsArray[Iterator]);
	EndDo;
	InsertionText = "";
	If AdditionalParameters.WizardFirstCall Then
		InsertionText = "
					   |Query = New Query;
					   |QueryText = """ + QueryText + """;
															|Query.Text = QueryText;";
		While Find(QueryText, "&") > 0 Do
			QueryParameter = UT_AlgorithmsClientServer.GetWordFirstOccurrenceWithOutPrefix(QueryText, "&");
			InsertionText = InsertionText + "
										  |Query.SetParameter(""" + QueryParameter + """,@" + QueryParameter
				+ " );";
			QueryText = StrReplace(QueryText, "&" + QueryParameter, "~" + QueryParameter);
		EndDo;
		Text = Text + "
						|Result = Query.Execute();
						|If Not Result.IsEmpty() Then
						|	Selection = Result.Select();
						|	While Selection.Next() Do
						|	 	// Message("");
						|	EndDo;
						|EndIf;";
	Else
		InsertionText = QueryText;
	EndIf;
	If IsBlankString(AdditionalParameters.SelectedText) Then
		Object.Text = Object.Text + InsertionText;
		Items.AlgorithmText.UpdateEditText();
	Else
		Object.Text = StrReplace(AdditionalParameters.WholeText, AdditionalParameters.SelectedText,
			InsertionText);
		Items.AlgorithmText.UpdateEditText();
	EndIf;
	HighlightChangedCode();

EndProcedure

&AtClient
Function WordType(Word, WordsTypes)
	WordType = New Map;

	WordType["RightTransfer"] = ?(WordsTypes[0].Find(Upper(TrimAll(Word))) = Undefined, False, True);
	WordType["OpenBracket"] = ?(WordsTypes[1].Find(Upper(TrimAll(Word))) = Undefined, False, True);
	WordType["CloseBracket"] = ?(WordsTypes[2].Find(Upper(TrimAll(Word))) = Undefined, False, True);
	WordType["InsideBracket"] = ?(WordsTypes[3].Find(Upper(TrimAll(Word))) = Undefined, False, True);
	Return WordType;

EndFunction

&AtServer
Procedure ExecuteProcedureAtServer(ExecutionError = False, ErrorMessage = "")
	SelectedObject = FormAttributeToValue("Object");
	AdditionalParameters = New Structure;
	SelectedObject.ExecuteProcedure(AdditionalParameters);
	ExecutionError = AdditionalParameters.Cancel;
	ErrorMessage = AdditionalParameters.ErrorMessage;
EndProcedure

#EndRegion //------------------------------------- WorkwithScript

&AtServer
Procedure FillFormFieldsChoiceLists()

	Query = New Query;
	Query.Text = "SELECT DISTINCT
  					|UT_AlgorithmsParameters.ParameterType
 					|FROM
 					|	Catalog.UT_Algorithms.Parameters AS UT_AlgorithmsParameters";

    Selection = Query.Execute().StartChoosing();

	While Selection.Next() Do

		If Not IsBlankString(Selection.ParameterType) Then

			Items.ApiParameterType.ChoiceList.Add(TrimAll(Selection.ParameterType));
		EndIf;

	EndDo;

EndProcedure
&AtServer
Procedure SetVisibleAndEnabled()
	Items.GroupPagesPanel.Enabled = Not Parameters.Key.IsEmpty();

	Items.EventLog.Title = " ";

	Items.GroupServer.Visible=Not Object.AtClient;
EndProcedure


&AtClient
Procedure ExecuteAlgorithmAtClient(TransmittedStructure)
	If Not ValueIsFilled(TrimAll(Object.AlgorithmText)) Then
		Return;
	EndIf;
	Try
		ExecutionContext = AlgorithmExecutionContext(TransmittedStructure);
	Except
		Raise  NSTR("ru = 'Нет возможности получить на клиенте текущие параметры';en = 'There is no way to get the current parameters At Client'") ;
	EndTry;
	ExecutionResult = UT_CodeEditorClientServer.ExecuteAlgorithm(Object.AlgorithmText, ExecutionContext);

EndProcedure

&AtServer
Procedure ExecuteAlgorithmAtServer(TransmittedStructure)
	If Not ValueIsFilled(TrimAll(Object.AlgorithmText)) Then
		Return;
	Endif;
	
	ExecutionContext = AlgorithmExecutionContext(TransmittedStructure);

	ExecutionResult =  UT_CodeEditorClientServer.ExecuteAlgorithm(Object.AlgorithmText, ExecutionContext);

EndProcedure

&AtServer
Function AlgorithmExecutionContext(TransmittedStructure)
	ExecutionContext = New Structure;
	ExecutionContext.Insert("TransmittedStructure", TransmittedStructure);
	
	SelectedObject = FormAttributeToValue("Object");
	Variables = SelectedObject.Storage.Get();
	If ValueIsFilled(Variables) Then
		For Each Item In Variables Do
			ExecutionContext.Insert(Item.Key, Item.Value);
		EndDo;
	Endif;
	
	Return ExecutionContext;	
EndFunction

#Region ImportExport
//Import
&AtClient
Procedure ExternalFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	If (TypeOf(SelectedFiles) = Type("Array") And SelectedFiles.Count() > 0) Then
		ExternalFile = SelectedFiles[0];
		Directory = Left(ExternalFile, StrFind(ExternalFile, GetPathSeparator(), SearchDirection.FromEnd));
		NotifyDescription = New NotifyDescription("PutFileEnd", ThisObject, New Structure("Directory",
			Directory));
		BeginPutFile(NotifyDescription, , ExternalFile, False, ThisObject.UUID);
	Else
		UT_CommonClientServer.MessageToUser(NSTR("ru = 'Нет файла';en = 'No file'"));
	EndIf;
EndProcedure

&AtClient
Procedure PutFileEnd(Result, StorageURL, SelectedFileName, AdditionalParameters) Export
	If Result Then
		ReadAtServer(StorageURL, SelectedFileName, AdditionalParameters);
	Else
		UT_CommonClientServer.MessageToUser(Nstr("ru = 'Ошибка помещения файла в хранилище';en = 'Error putting a file to storage'"));
	EndIf;
EndProcedure

&AtServer
Procedure ReadAtServer(StorageURL, SelectedFileName, AdditionalParameters)
	ParameterName = StrReplace(StrReplace(StrReplace(StrReplace(Upper(SelectedFileName), Upper(
		AdditionalParameters.Directory), ""), ".", ""), "XML", ""), Char(32), "");
	Try
		BinaryData = GetFromTempStorage(StorageURL);
		Stream = BinaryData.OpenStreamForRead();
		XMLReader = New XMLReader;
		XMLReader.OpenStream(Stream);
		ParameterValue = XDTOSerializer.ReadXML(XMLReader);
		AddNewParameterAtServer(New Structure("ParameterName,ParameterValue",
			ParameterName, ParameterValue));
	Except
		Raise NSTR("ru = 'Ошибка записи файла XML';en = 'Error writing XML file'") + ErrorDescription();
	EndTry;
EndProcedure

//Export
&AtClient
Procedure ChooseDirectoryEnd(SelectedFiles, AdditionalParameters) Export
	If (TypeOf(SelectedFiles) = Type("Array") And SelectedFiles.Count() > 0) Then
		Directory = SelectedFiles[0];
		Parameter = Items.ParametersTable.CurrentData.Parameter;
		FileExtention = "";
		FileName = TrimAll(Parameter);
		If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("UnloadXML") Then
			FileExtention = ".xml";
			StorageURL = GetFileAtServer(Parameter, True);
		Else
			If StrFind(Parameter, "File") > 0 Then
				Position = StrFind(FileName, "_");
				FileExtention = "." + Lower(Mid(FileName, 5, Position - 5));
				FileName = Mid(FileName, Position + 1);
			EndIf;
			StorageURL = GetFileAtServer(Parameter, False);
		EndIf;
		Notification = New NotifyDescription("AfterGetFile", ThisObject);
		FileDescription = New TransferableFileDescription;
		FileDescription.Location = StorageURL;
		FileDescription.Name = Directory + GetPathSeparator() + FileName + FileExtention;
		ObtainedFiles = New Array;
		ObtainedFiles.Add(FileDescription);
		BeginGettingFiles(Notification, ObtainedFiles, , False);
	EndIf;
EndProcedure

&AtServer
Function GetFileAtServer(Parameter, UnloadXML)
	SelectedParameter = GetParameterAtServer(Parameter);
	If UnloadXML Then
		XMLWriter = New XMLWriter;
		Stream = New MemoryStream;
		XMLWriter.OpenStream(Stream);
		XDTOSerializer.WriteXML(XMLWriter, SelectedParameter);
		XMLWriter.Close();
		BinaryData = Stream.CloseAndGetBinaryData();
		StorageURL = PutToTempStorage(BinaryData, ThisObject.UUID);
	Else
		StorageURL = PutToTempStorage(SelectedParameter, ThisObject.UUID);
	EndIf;
	Return StorageURL;
EndFunction

&AtClient
Procedure AfterGetFile(ObtainedFiles, AdditionalParameters) Export
	If TypeOf(ObtainedFiles) = Type("Array") Then
		UT_CommonClientServer.MessageToUser(StrTemplate(Nstr("ru = 'Файл %1 записан';en = 'File %1 writed'"),ObtainedFiles[0].Name));
	EndIf;
EndProcedure

&AtClient
Procedure ApiCheckParameters(Command)
	Object.Parameters.Clear();
	AlgorithmCode = Object.AlgorithmCode;
	mExcluding = UT_AlgorithmsClientServer.ExcludedSymbolsArray();
	Prefix = "Parameters.";
	FillType = New Structure;
	While Find(AlgorithmCode, Prefix) > 0 Do
		Word = UT_AlgorithmsClientServer.GetWordFirstOccurrenceWithOutPrefix(AlgorithmCode, Prefix, mExcluding);
		AlgorithmCode = StrReplace(AlgorithmCode, Prefix + Word, Word);
		Try
			FillType.Insert(Word, True);
		Except
		EndTry;
	EndDo;
	Text = Object.Text;
	Prefix = "$";
	While Find(AlgorithmCode, Prefix) > 0 Do
		Word = UT_AlgorithmsClientServer.GetWordFirstOccurrenceWithOutPrefix(Text, Prefix, mExcluding);
		Text = StrReplace(Text, Prefix + Word, Word);
		Try
			FillType.Insert(Word, False);
		Except
		EndTry;
	EndDo;
     
	StorageURL = UT_AlgorithmsClientServer.GetParameters(Object.Ref, True);

	StoredParameters = GetFromTempStorage(StorageURL);

	For Each Item In FillType Do
		NewRow = Object.Parameters.Add();
		NewRow.Entry = Item.Value;
		NewRow.Name = Item.Key;
		If NewRow.Entry And StoredParameters.Property(Item.Key) Then
			NewRow.ParameterType = GetTypeDescriptionString(StoredParameters[Item.Key]);
			NewRow.ByDefault = String(StoredParameters[Item.Key]);
		EndIf;
	EndDo;
EndProcedure

#EndRegion

&AtServer
Procedure ConnectExternalDataProcessorAtServer()
	ExternalDataProcessors.Connect("v8res://mngbase/StandardEventLog.epf", "StandardEventLog", False);
EndProcedure

&AtServer
Procedure CreateScheduledJob()
	If Parameters.Key.IsEmpty() Then
		Return;
	EndIf;
	ParametersArray = New Array;
	ParametersArray.Add(Object.Ref);
	Filter = New Structure;
	Filter.Insert("Key", Object.Ref.UUID());
	JobsArray = ScheduledJobs.GetScheduledJobs(Filter);
	If JobsArray.Count() >= 1 Then
		Message(NSTR("ru = 'Задание с ключом %1 уже существует';en = 'Scheduled job  with key %1  already exist'",Filter.Key));
	Else
		Job = ScheduledJobs.CreateScheduledJob("alg_UniversalScheduledJob");
		Job.Title = Object.Title;
		Job.Key = Filter.Key;
		Job.Use = False;
		Job.Parameters = ParametersArray;
		Job.Write();
		Message(StrTemplate(NSTR("ru = 'Создано регламентное задание %1 с  ключом %2';en = 'Created scheduled job %1 with key %2 '"), Object.Title,Filter.Key));
	EndIf;
EndProcedure

&AtServer
Procedure DeleteScheduledJobAtServer()
	If Parameters.Key.IsEmpty() Then
		Return;
	EndIf;
	ParametersArray = New Array;
	ParametersArray.Add(Object.Ref);
	Filter = New Structure;
	Filter.Insert("Key", Object.Ref.UUID());
	JobsArray = ScheduledJobs.GetScheduledJobs(Filter);
	If JobsArray.Count() >= 1 Then
		JobsArray[0].Delete();
		Message(Nstr("ru = 'Удалено регламентное задание';en = 'Deleted scheluded job'")+ Object.Title);
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// CodeEditor
	UT_CodeEditorClient.FormOnOpen(ThisObject,Undefined);
   	// CodeEditor
EndProcedure


//@skip-warning
&AtClient
Процедура Attachable_EditorFieldDocumentGenerated(Item)
	UT_CodeEditorClient.HTMLEditorFieldDocumentGenerated(ThisObject, Item);
КонецПроцедуры

//@skip-warning
&AtClient
Procedure Attachable_EditorFieldOnClick(Item, EventData, StandardProcessing)
	UT_CodeEditorClient.HTMLEditorFieldOnClick(ThisObject, Item, EventData, StandardProcessing);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_CodeEditorDeferredInitializingEditors()
	UT_CodeEditorClient.CodeEditorDeferredInitializingEditors(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_CodeEditorDeferProcessingOfEditorEvents() Export
	UT_CodeEditorClient.EditorEventsDeferProcessing(ThisObject)
EndProcedure

&AtClient 
Procedure Attachable_CodeEditorInitializingCompletion() Export
	UT_CodeEditorClient.SetEditorText(ThisObject, "Algorithm", Object.AlgorithmText, True);
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	Object.AlgorithmText = UT_CodeEditorClient.EditorCodeText(ThisObject, "Algorithm");
EndProcedure


#EndRegion