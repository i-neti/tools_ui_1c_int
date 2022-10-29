
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ReadCodeEditorSettings();

	SetItemsVisibility();
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	CodeEditorVariants = UT_CodeEditorClientServer.CodeEditorVariants();
	
	If EditorOf1CCode = CodeEditorVariants.Monaco Then
		CheckedAttributes.Add("MonacoEditorTheme");
		CheckedAttributes.Add("MonacoEditorScriptVariant");
	EndIf;

	RowNumber = 1;
	For Each Row In ConfigurationSourceFilesDirectories Do
		If Not ValueIsFilled(Row.Source) 
			And ValueIsFilled(Row.Directory) Then
			UT_CommonClientServer.MessageToUser(StrTemplate(NStr("ru = 'В строке %1 не заполнен источник исходного кода';
			|en = 'Source code source is not filled in row %1'"),RowNumber),,,, Cancel);
		EndIf;
		
		RowNumber = RowNumber +1;
	EndDo;

	SourceValueTable = ConfigurationSourceFilesDirectories.Unload(, "Source");
	SourceValueTable.GroupBy("Source");
	
	For Each Row In SourceValueTable Do
		SearchStructure = New Structure;
		SearchStructure.Insert("Source", Row.Source);

		FoundedRows = ConfigurationSourceFilesDirectories.FindRows(SearchStructure);

		If FoundedRows.Count() > 1 Then
			
			UT_CommonClientServer.MessageToUser(StrTemplate(NStr("ru = 'С источником исходного кода %1 обнаружено более одной строки. Запись невозможна';
			|en = 'More than one line was detected with the source code source %1. Recording is not possible'"),Row.Source),,,, Cancel)
			
		EndIf;
	EndDo;
EndProcedure


#EndRegion

#Region FormHeaderEventsHandlers

&AtClient
Procedure EditorOf1CCodeOnChange(Item)
	SetItemsVisibility();
EndProcedure

&AtClient
Procedure ConfigurationSourceFilesDirectoriesDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	CurrentData = Items.ConfigurationSourceFilesDirectories.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FileDescription = UT_CommonClient.EmptyDescriptionStructureOfSelectedFile();
	FileDescription.FileName = CurrentData.Directory;
	
	NotificationAdditionalParameters = New Structure;
	NotificationAdditionalParameters.Insert("CurrentRow", Items.ConfigurationSourceFilesDirectories.CurrentRow);
	
	UT_CommonClient.FormFieldFileNameStartChoice(FileDescription, Item, ChoiceData, StandardProcessing,
		FileDialogMode.ChooseDirectory,
		New NotifyDescription("ConfigurationSourceFilesDirectoriesDirectoryStartChoiceCompletion", ThisObject,
		NotificationAdditionalParameters));
EndProcedure

#EndRegion


#Region FormCommandsHandlers
&AtClient
Procedure Apply(Command)
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ApplyAtServer();
	Close();
EndProcedure

&AtClient
Procedure SaveConfigurationModulesToFiles(Command)
	
	CurrentDirectories = New Map;
	For Each CurrentRow In ConfigurationSourceFilesDirectories Do
		If Not ValueIsFilled(CurrentRow.Source) 
			Or  Not ValueIsFilled(CurrentRow.Directory) Then
				Continue;
		EndIf;

		CurrentDirectories.Insert(CurrentRow.Source, CurrentRow.Directory);
	EndDo;
	
	UT_CodeEditorClient.SaveConfigurationModulesToFiles(
		New NotifyDescription("SaveConfigurationModulesToFilesCompletion", ThisObject), CurrentDirectories);
EndProcedure

&AtClient
Procedure CodeTemplatesFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	CurrData = Items.CodeTemplates.CurrentData;
	If CurrData = Undefined Then
		Return;
	EndIf;
	
	FileDetails = UT_CommonClient.SelectedFileDetailsEmptyStructure();
	FileDetails.FileName = CurrData.FileName;
	UT_CommonClient.AddFormatToSavingFileDetails(FileDetails, NStr("ru = 'Файл шаблона кода(*.st)'; en = 'Script template file(*.st)'"), "st");
	
	NotifyAddlParameters = New Structure;
	NotifyAddlParameters.Inser("CurrentRow", Items.CodeTemplates.CurrentRow);
	
	UT_CommonClient.FormFieldFileNameStartChoice(FileDetails, Item, ChoiceData, StandardProcessing,
		FileDialogMode.Open,
		New NotifyDescription("CodeTemplatesFileNameStartChoiceCompletion", ThisObject,
		NotifyAddlParameters));
EndProcedure

#EndRegion

#Region Internal

&AtServer
Procedure ReadCodeEditorSettings()
	SetChoiseListOfStructureItem(Items.EditorOf1CCode,
		UT_CodeEditorClientServer.CodeEditorVariants());
	
	SetChoiseListOfStructureItem(Items.MonacoEditorTheme,
		UT_CodeEditorClientServer.MonacoEditorThemeVariants());
	
	SetChoiseListOfStructureItem(Items.MonacoEditorScriptVariant,
		UT_CodeEditorClientServer.MonacoEditorSyntaxLanguageVariants());

	EditorSettings = UT_CodeEditorServer.CodeEditorCurrentSettings();	
	EditorOf1CCode = EditorSettings.Variant;
	FontSize = EditorSettings.FontSize;	

	MonacoEditorTheme = EditorSettings.Monaco.Theme;
	MonacoEditorScriptVariant = EditorSettings.Monaco.ScriptVariant;
	UseScriptMap = EditorSettings.Monaco.UseScriptMap;
	HideLineNumbers = EditorSettings.Monaco.HideLineNumbers;
	LinesHeight = EditorSettings.Monaco.LinesHeight;
	DisplaySpacesAndTabs = EditorSettings.Monaco.DisplaySpacesAndTabs;
	UseCodeStandardTemplates = EditorSettings.Monaco.UseCodeStandardTemplates;

	ConfigurationSourceFilesDirectories.Clear();
	Items.ConfigurationSourceFilesDirectoriesSource.ChoiceList.Clear();
	SourceCodeSources = UT_CodeEditorServer.AvailableSourceCodeSources();
	
	For Each DirectoryDescription In EditorSettings.Monaco.SourceFilesDirectories Do
		NewRow = ConfigurationSourceFilesDirectories.Add();
		NewRow.Directory = DirectoryDescription.Directory;
		NewRow.Source = DirectoryDescription.Source;
	
		Items.ConfigurationSourceFilesDirectoriesSource.ChoiceList.Add(NewRow.Source);
	EndDo;

	CodeTemplates.Clear();
	For Each CurrFileName In EditorSettings.Monaco.CodeTemplatesFiles Do
		NewRow = CodeTemplates.Add();
		NewRow.FileName = CurrFileName;
	EndDo;

	For Each CurrentSource In SourceCodeSources Do
		SearchStructure = New Structure;
		SearchStructure.Insert("Source", CurrentSource.Value);
		
		FoundedRows = ConfigurationSourceFilesDirectories.FindRows(SearchStructure);
		If FoundedRows.Count()>0 Then
			Continue;
		EndIf;
		
		NewRow = ConfigurationSourceFilesDirectories.Add();
		NewRow.Source = CurrentSource.Value;
		
		Items.ConfigurationSourceFilesDirectoriesSource.ChoiceList.Add(CurrentSource.Value);
		
	EndDo;
EndProcedure

&AtClient
Procedure SaveConfigurationModulesToFilesCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each CurrentDirectory In Result Do
		SearchStructure = New Structure;
		SearchStructure.Insert("Source", CurrentDirectory.Source);
		
		FoundedRows = ConfigurationSourceFilesDirectories.FindRows(SearchStructure);
		If FoundedRows.Count() = 0 Then
			NewRow = ConfigurationSourceFilesDirectories.Add();
			NewRow.Source = CurrentDirectory.Source;
		Else
			NewRow = FoundedRows[0];
		EndIf;
		
		NewRow.Directory = CurrentDirectory.Directory;
	EndDo;
	
	Modified = True;
EndProcedure


&AtClient
Procedure ConfigurationSourceFilesDirectoriesDirectoryStartChoiceCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Count()=0 Then
		Return;
	EndIf;
	
	CurrentData = ConfigurationSourceFilesDirectories.FindByID(AdditionalParameters.CurrentRow);
	CurrentData.Directory = Result[0];
	
	Modified = True;
EndProcedure

&AtClient
Procedure CodeTemplatesFileNameStartChoiceCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Count()=0 Then
		Return;
	EndIf;
	
	CurrentData = CodeTemplates.FindByID(AdditionalParameters.CurrentRow);
	CurrentData.FileNale = Result[0];
	
	Modified = True;
EndProcedure

&AtServer
Procedure SetItemsVisibility()
	Variants = UT_CodeEditorClientServer.CodeEditorVariants();
	
	IsMonaco = EditorOf1CCode = Variants.Monaco;
	
	Items.GroupMonacoCodeEditor.Visible = IsMonaco;
EndProcedure

&AtServer
Procedure SetChoiseListOfStructureItem(Item, DataStructure)
	Item.ChoiceList.Clear();
	For Each KeyValue In DataStructure Do
		Item.ChoiceList.Add(KeyValue.Key, KeyValue.Value);
	EndDo;		
EndProcedure

&AtServer
Procedure ApplyAtServer()
	CodeEditorParameters = UT_CodeEditorClientServer.CodeEditorCurrentSettingsByDefault();
	CodeEditorParameters.FontSize = FontSize;
	CodeEditorParameters.Variant = EditorOf1CCode;
	
	CodeEditorParameters.Monaco.Theme = MonacoEditorTheme;
	CodeEditorParameters.Monaco.ScriptVariant = MonacoEditorScriptVariant;
	CodeEditorParameters.Monaco.UseScriptMap = UseScriptMap;
	CodeEditorParameters.Monaco.HideLineNumbers = HideLineNumbers;
	CodeEditorParameters.Monaco.LinesHeight = LinesHeight;
	CodeEditorParameters.Monaco.UseCodeStandardTemplates = UseCodeStandardTemplates;
	For Each CurrentRow In ConfigurationSourceFilesDirectories Do
		If Not ValueIsFilled(CurrentRow.Directory) Then
			Continue;
		EndIf;
	
		DirectoryDescription = UT_CodeEditorClientServer.NewDescriptionOfConfigurationSourceFilesDirectory();
		DirectoryDescription.Source = CurrentRow.Source;
		DirectoryDescription.Directory = CurrentRow.Directory;
		
		CodeEditorParameters.Monaco.SourceFilesDirectories.Add(DirectoryDescription);
	EndDo;
	
	For Each CurrRow In CodeTemplates Do
		CodeEditorParameters.Monaco.CodeTemplatesFiles.Add(CurrRow.FileName);
	EndDo;
	
	UT_CodeEditorServer.SetCodeEditorNewSettings(CodeEditorParameters);
	
EndProcedure
#EndRegion