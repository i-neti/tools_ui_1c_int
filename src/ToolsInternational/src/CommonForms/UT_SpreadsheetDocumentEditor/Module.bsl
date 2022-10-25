///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
// Translated by Neti Company
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.WindowOpeningMode <> Undefined Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	
	If Parameters.SpreadsheetDocument = Undefined Then
		If Not IsBlankString(Parameters.TemplateMetadataObjectName) Then
			EditingDenied = Not Parameters.Edit;
			LoadSpreadsheetDocumentFromMetadata(Parameters.LanguageCode);
		EndIf;
		
	ElsIf TypeOf(Parameters.SpreadsheetDocument) = Type("SpreadsheetDocument") Then
		SpreadsheetDocument = Parameters.SpreadsheetDocument;
	Else
		BinaryData = GetFromTempStorage(Parameters.SpreadsheetDocument); // BinaryData - 
		TempFileName = GetTempFileName("mxl");
		BinaryData.Write(TempFileName);
		SpreadsheetDocument.Read(TempFileName);
		DeleteFiles(TempFileName);
	EndIf;
	
	Items.SpreadsheetDocument.Edit = Parameters.Edit;
	Items.SpreadsheetDocument.ShowGroups = True;
	
	IsTemplate = Not IsBlankString(Parameters.TemplateMetadataObjectName);
	Items.Warning.Visible = IsTemplate And Parameters.Edit;
	
	Items.EditInExternalApplication.Visible = False;
	
	If Not IsBlankString(Parameters.DocumentName) Then
		DocumentName = Parameters.DocumentName;
	EndIf;
	
	Items.SpreadsheetDocument.ShowRowAndColumnNames = SpreadsheetDocument.Template;
	Items.SpreadsheetDocument.ShowCellNames = SpreadsheetDocument.Template;
	
	Items.Translate.Visible = AutoTranslationAvailable;
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(Parameters.FilePath) Then
		File = New File(Parameters.FilePath);
		If IsBlankString(DocumentName) Then
			DocumentName = File.BaseName;
		EndIf;
		File.BeginGettingReadOnly(New NotifyDescription("OnCompleteGettingReadOnly", ThisObject));
		Return;
	EndIf;
	
	SetInitialFormSettings();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	NotifyDescription = New NotifyDescription("ConfirmAndClose", ThisObject);
	QuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сохранить изменения в %1?'; en = 'Do you want to save the changes you made to %1?'"), DocumentName);
	UT_CommonClient.ShowQuestionToUser(NotifyDescription, QuestionText , QuestionDialogMode.YesNo);
	
	If Modified Or Exit Then
		Return;
	EndIf;
	
	NotifyWritingSpreadsheetDocument();
	
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	If Result <> Undefined And Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	NotifyDescription = New NotifyDescription("CloseFormAfterWriteSpreadsheetDocument", ThisObject);
	WriteSpreadsheetDocument(NotifyDescription);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "EditedSpreadsheetDocumentNamesRequest" And Source <> ThisObject Then
		DocumentNames = Parameter; // Array -
		DocumentNames.Add(DocumentName);
	ElsIf EventName = "OwnerFormClosing" And Source = FormOwner Then
		Close();
		If IsOpen() Then
			Parameter.Cancel = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentOnActivate(Item)
	UpdateCommandBarButtonMarks();
	SynchronizeTemplateViewArea();
EndProcedure

&AtClient
Procedure DistributedTemplateOnActivate(Item)
	
	SynchronizeTemplateViewArea();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// Document actions

&AtClient
Procedure WriteAndClose(Command)
	NotifyDescription = New NotifyDescription("CloseFormAfterWriteSpreadsheetDocument", ThisObject);
	WriteSpreadsheetDocument(NotifyDescription);
EndProcedure

&AtClient
Procedure Write(Command)
	WriteSpreadsheetDocument();
	NotifyWritingSpreadsheetDocument();
EndProcedure

&AtClient
Procedure Edit(Command)
	Items.SpreadsheetDocument.Edit = Not Items.SpreadsheetDocument.Edit;
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
EndProcedure

&AtClient
Procedure EditInExternalApplication(Command)
//	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
//		OpeningParameters = New Structure;
//		OpeningParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
//		OpeningParameters.Insert("TemplateMetadataObjectName", Parameters.TemplateMetadataObjectName);
//		OpeningParameters.Insert("TemplateType", "MXL");
//		NotifyDescription = New NotifyDescription("EditInExternalApplicationCompletion", ThisObject);
//		PrintManagementClientModule = CommonClient.CommonModule("PrintManagementClient");
//		PrintManagementClientModule.EditTemplateInExternalApplication(NotifyDescription, OpeningParameters, ThisObject);
//	EndIf;
EndProcedure

// Format

&AtClient
Procedure IncreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size + IncreaseFontSizeChangeStep(Size);
		Area.Font = New Font(Area.Font,,Size);
	EndDo;
	
EndProcedure

&AtClient
Procedure DecreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size - DecreaseFontSizeChangeStep(Size);
		If Size < 1 Then
			Size = 1;
		EndIf;
		Area.Font = New Font(Area.Font,,Size);
	EndDo;
	
EndProcedure

&AtClient
Procedure Strikeout(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Strikeout = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,,,,ValueToSet);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Translate(Command)
	
	QuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполнить автоматический перевод на %1 язык?'; en = 'Do you want to automatically translate this template to %1 language?'"), Items.Language.Title);
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Выполнить перевод'; en = 'Translate'"));
	Buttons.Add(DialogReturnCode.No, NStr("ru = 'Не выполнять'; en = 'Do not translate'"));
	
	NotifyDescription = New NotifyDescription("OnAnswerTemplateTranslationQuestion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, Buttons);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure LoadSpreadsheetDocumentFromMetadata(Val LanguageCode = Undefined)
	
	TranslationRequired = False;
	
EndProcedure

&AtClient
Procedure SetUpSpreadsheetDocumentRepresentation()
	Items.SpreadsheetDocument.ShowHeaders = Items.SpreadsheetDocument.Edit;
	Items.SpreadsheetDocument.ShowGrid = Items.SpreadsheetDocument.Edit;
EndProcedure

&AtClient
Procedure UpdateCommandBarButtonMarks();
	
#If Not WebClient And Not MobileClient Then
	Area = Items.SpreadsheetDocument.CurrentArea;
	If TypeOf(Area) <> Type("SpreadsheetDocumentRange") Then
		Return;
	EndIf;
	
	// Font
	Font = Area.Font;
	Items.SpreadsheetDocumentBold.Check = Font <> Undefined AND Font.Bold = True;
	Items.SpreadsheetDocumentItalic.Check = Font <> Undefined AND Font.Italic = True;
	Items.SpreadsheetDocumentUnderline.Check = Font <> Undefined AND Font.Underline = True;
	Items.Strikeout.Check = Font <> Undefined AND Font.Strikeout = True;
	
	// Horizontal alighment
	Items.SpreadsheetDocumentAlignLeft.Check = Area.HorizontalAlign = HorizontalAlign.Left;
	Items.SpreadsheetDocumentAlignCenter.Check = Area.HorizontalAlign = HorizontalAlign.Center;
	Items.SpreadsheetDocumentAlignRight.Check = Area.HorizontalAlign = HorizontalAlign.Right;
	Items.SpreadsheetDocumentJustify.Check = Area.HorizontalAlign = HorizontalAlign.Justify;
	
#EndIf
	
EndProcedure

&AtClient
Function IncreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return 10;
	EndIf;
	
	If Size < 10 Then
		Return 1;
	ElsIf 10 <= Size And  Size < 20 Then
		Return 2;
	ElsIf 20 <= Size And  Size < 48 Then
		Return 4;
	ElsIf 48 <= Size And  Size < 72 Then
		Return 6;
	ElsIf 72 <= Size And  Size < 96 Then
		Return 8;
	Else
		Return Round(Size / 10);
	EndIf;
EndFunction

&AtClient
Function DecreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return -8;
	EndIf;
	
	If Size <= 11 Then
		Return 1;
	ElsIf 11 < Size And Size <= 23 Then
		Return 2;
	ElsIf 23 < Size And Size <= 53 Then
		Return 4;
	ElsIf 53 < Size And Size <= 79 Then
		Return 6;
	ElsIf 79 < Size And Size <= 105 Then
		Return 8;
	Else
		Return Round(Size / 11);
	EndIf;
EndFunction

// Returns:
//   - Array of SpreadsheetDocumentRange
//
&AtClient
Function AreaListForChangingFont()
	
	Result = New Array;
	
	For Each AreaToProcess In Items.SpreadsheetDocument.GetSelectedAreas() Do
		If AreaToProcess.Font <> Undefined Then
			Result.Add(AreaToProcess);
			Continue;
		EndIf;
		
		AreaToProcessTop = AreaToProcess.Top;
		AreaToProcessBottom = AreaToProcess.Bottom;
		AreaToProcessLeft = AreaToProcess.Left;
		AreaToProcessRight = AreaToProcess.Right;
		
		If AreaToProcessTop = 0 Then
			AreaToProcessTop = 1;
		EndIf;
		
		If AreaToProcessBottom = 0 Then
			AreaToProcessBottom = SpreadsheetDocument.TableHeight;
		EndIf;
		
		If AreaToProcessLeft = 0 Then
			AreaToProcessLeft = 1;
		EndIf;
		
		If AreaToProcessRight = 0 Then
			AreaToProcessRight = SpreadsheetDocument.TableWidth;
		EndIf;
		
		If AreaToProcess.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			AreaToProcessTop = AreaToProcess.Bottom;
			AreaToProcessBottom = SpreadsheetDocument.TableHeight;
		EndIf;
			
		For ColumnNumber = AreaToProcessLeft To AreaToProcessRight Do
			ColumnWidth = Undefined;
			For RowNumber = AreaToProcessTop To AreaToProcessBottom Do
				Cell = SpreadsheetDocument.Area(RowNumber, ColumnNumber, RowNumber, ColumnNumber);
				If AreaToProcess.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
					If ColumnWidth = Undefined Then
						ColumnWidth = Cell.ColumnWidth;
					EndIf;
					If Cell.ColumnWidth <> ColumnWidth Then
						Continue;
					EndIf;
				EndIf;
				If Cell.Font <> Undefined Then
					Result.Add(Cell);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure CloseFormAfterWriteSpreadsheetDocument(Close, AdditionalParameters) Export
	If Close Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure WriteSpreadsheetDocument(CompletionHandler = Undefined)
	
	If IsNew() Or EditingDenied Then
		StartFileSavingDialog(CompletionHandler);
		Return;
	EndIf;
		
	WriteSpreadsheetDocumentFileNameSelected(CompletionHandler);
	
EndProcedure

&AtClient
Procedure WriteSpreadsheetDocumentFileNameSelected(Val CompletionHandler)
	If Not IsBlankString(Parameters.FilePath) Then
		SpreadsheetDocument.BeginWriting(
			New NotifyDescription("ProcessSpreadsheetDocumentWritingResult", ThisObject, CompletionHandler),
			Parameters.FilePath);
	Else
		AfterWriteSpreadsheetDocument(CompletionHandler);
	EndIf;
EndProcedure

&AtClient
Procedure ProcessSpreadsheetDocumentWritingResult(Result, CompletionHandler) Export 
	If Result <> True Then 
		Return;
	EndIf;
	
	EditingDenied = False;
	AfterWriteSpreadsheetDocument(CompletionHandler);
EndProcedure

&AtClient
Procedure AfterWriteSpreadsheetDocument(CompletionHandler)
	WritingCompleted = True;
	Modified = False;
	SetTitle();
	
	ExecuteNotifyProcessing(CompletionHandler, True);
EndProcedure

&AtClient
Procedure StartFileSavingDialog(Val CompletionHandler)
	
	Var SaveFileDialog;
	
	SaveFileDialog = New FileDialog(FileDialogMode.Save);
	SaveFileDialog.FullFileName = UT_CommonClientServer.ReplaceProhibitedCharsInFileName(
		DocumentName);
	SaveFileDialog.Filter = NStr("ru = 'Табличный документ'; en = 'Spreadsheet documents'") + " (*.mxl)|*.mxl";
	SaveFileDialog.Show(CompletionHandler);
	
EndProcedure

&AtClient
Procedure OnCompleteFileSelectionDialog(SelectedFiles, CompletionHandler) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	FullFileName = SelectedFiles[0];
	
	Parameters.FilePath = FullFileName;
	DocumentName = Mid(FullFileName, StrLen(FileDetails(FullFileName).Path) + 1);
	If Lower(Right(DocumentName, 4)) = ".mxl" Then
		DocumentName = Left(DocumentName, StrLen(DocumentName) - 4);
	EndIf;
	
	WriteSpreadsheetDocumentFileNameSelected(CompletionHandler);
	
EndProcedure

&AtClient
Function FileDetails(FullName)
	
	SeparatorPosition = StrFind(FullName, GetPathSeparator(), SearchDirection.FromEnd);
	
	Name = Mid(FullName, SeparatorPosition + 1);
	Path = Left(FullName, SeparatorPosition);
	
	ExtensionPosition = StrFind(Name, ".", SearchDirection.FromEnd);
	
	NameWithoutExtension = Left(Name, ExtensionPosition - 1);
	Extension = Mid(Name, ExtensionPosition + 1);
	
	Result = New Structure;
	Result.Insert("FullName", FullName);
	Result.Insert("Name", Name);
	Result.Insert("Path", Path);
	Result.Insert("BaseName", NameWithoutExtension);
	Result.Insert("Extension", Extension);
	
	Return Result;
	
EndFunction
	
&AtClient
Function NewDocumentName()
	Return NStr("ru = 'Новый'; en = 'New'");
EndFunction

&AtClient
Procedure SetTitle()
	
	Title = DocumentName;
	If IsNew() Then
		Title = Title + " (" + NStr("ru = 'создание'; en = 'create'") + ")";
	ElsIf EditingDenied Then
		Title = Title + " (" + NStr("ru = 'только просмотр'; en = 'read-only'") + ")";
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpCommandPresentation()
	
	DocumentCanEdit = Items.SpreadsheetDocument.Edit;
	Items.Edit.Check = DocumentCanEdit;
	Items.EditingCommands.Enabled = DocumentCanEdit;
	Items.WriteAndClose.Enabled = DocumentCanEdit Or Modified;
	Items.Write.Enabled = DocumentCanEdit Or Modified;
	
	If DocumentCanEdit And Not IsBlankString(Parameters.TemplateMetadataObjectName) Then
		Items.Warning.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Function IsNew()
	Return IsBlankString(Parameters.TemplateMetadataObjectName) And IsBlankString(Parameters.FilePath);
EndFunction

&AtClient
Procedure EditInExternalApplicationCompletion(ImportedSpreadsheetDocument, AdditionalParameters) Export
	If ImportedSpreadsheetDocument = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	UpdateSpreadsheetDocument(ImportedSpreadsheetDocument);
EndProcedure

&AtServer
Procedure UpdateSpreadsheetDocument(ImportedSpreadsheetDocument)
	SpreadsheetDocument = ImportedSpreadsheetDocument;
EndProcedure


&AtClient
Procedure SetInitialFormSettings()
	
	If Not IsBlankString(Parameters.FilePath) And Not EditingDenied Then
		Items.SpreadsheetDocument.Edit = True;
	EndIf;
	
	SetDocumentName();
	SetTitle();
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
	
EndProcedure

&AtClient
Procedure SetDocumentName()

	If IsBlankString(DocumentName) Then
		UsedNames = New Array;
		Notify("EditedSpreadsheetDocumentNamesRequest", UsedNames, ThisObject);
		
		Index = 1;
		While UsedNames.Find(NewDocumentName() + Index) <> Undefined Do
			Index = Index + 1;
		EndDo;
		
		DocumentName = NewDocumentName() + Index;
	EndIf;

EndProcedure

&AtClient
Procedure OnCompleteGettingReadOnly(ReadOnly, AdditionalParameters) Export
	
	EditingDenied = ReadOnly;
	SetInitialFormSettings();
	
EndProcedure

&AtClient
Procedure Attachable_SwitchLanguage(Command)
	

EndProcedure

&AtClient
Procedure Attachable_OnSwitchLanguage(LanguageCode, AdditionalParameters) Export
	
	LoadSpreadsheetDocumentFromMetadata(LanguageCode);
	If TranslationRequired And AutoTranslationAvailable Then
		QuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Макет еще не переведен на %1 язык.
			|Выполнить автоматический перевод?'; en = 'This template is not translated to %1 language yet.
			|Do you want to automatically translate it?'"), Items.Language.Title);
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Выполнить перевод'; en = 'Translate'"));
		Buttons.Add(DialogReturnCode.No, NStr("ru = 'Не выполнять'; en = 'Do not translate'"));
		
		NotifyDescription = New NotifyDescription("OnAnswerTemplateTranslationQuestion", ThisObject);
		ShowQueryBox(NotifyDescription, QuestionText, Buttons);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnAnswerTemplateTranslationQuestion(Answer, AdditionalParameters) Export
	
	If Answer <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	TranslateTemplateTexts();
	
EndProcedure

&AtServer
Procedure TranslateTemplateTexts()
	

EndProcedure

&AtServer
Function DeleteParametersFromText(Val Text)
	
	FoundParameters = New Array;
	
	StringParts = StrSplit(Text, "[]", True);
	For Index = 1 To StringParts.UBound() Do
		FoundParameters.Add("[" + StringParts[Index] + "]");
		Index = Index + 1;
	EndDo;
	
	ProcessedParameters = New Array;
	Counter = 0;
	For Each Parameter In FoundParameters Do
		If StrFind(Text, Parameter) Then
			Counter = Counter + 1;
			Text = StrReplace(Text, Parameter, ParameterID(Counter));
			ProcessedParameters.Add(Parameter);
		EndIf;
	EndDo;
	
	Result = New Structure;
	Result.Insert("Text", Text);
	Result.Insert("Parameters", ProcessedParameters);
	
	Return Result;
	
EndFunction

&AtServer
Function ReturnParametersToText(Val Text, ProcessedParameters)
	
	For Counter = 1 To ProcessedParameters.Count() Do
		Text = StrReplace(Text, ParameterID(Counter), "%" + XMLString(Counter));
	EndDo;
	
	Return UT_StringFunctionsClientServer.SubstituteParametersToStringFromArray(Text, ProcessedParameters);
	
EndFunction

// This sequence must not be changed when translated into any language.
&AtServer
Function ParameterID(Number)
	
	Return "{<" + XMLString(Number) + ">}"; 
	
EndFunction

&AtClient
Procedure ShowHideOriginal(Command)
	
	Items.ShowHideOriginalButton.Check = Not Items.ShowHideOriginalButton.Check;
	Items.DistributedTemplate.Visible = Items.ShowHideOriginalButton.Check;
	If Items.ShowHideOriginalButton.Check Then
		Items.SpreadsheetDocument.TitleLocation = FormItemTitleLocation.Auto;
	Else
		Items.SpreadsheetDocument.TitleLocation = FormItemTitleLocation.None;
	EndIf;
	
EndProcedure

&AtClient
Procedure SynchronizeTemplateViewArea()
	
	If Not Items.DistributedTemplate.Visible Then
		Return;
	EndIf;
	
	ManagedItem =  Items.DistributedTemplate;
	If CurrentItem <> Items.SpreadsheetDocument Then
		ManagedItem = Items.SpreadsheetDocument;
	EndIf;
	
	Area = CurrentItem.CurrentArea;
	If Area = Undefined Then
		Return;
	EndIf;
	
	ManagedItem.CurrentArea = ThisObject[CurrentItem.Name].Area(
		Area.Top, Area.Left, Area.Bottom, Area.Right);
	
EndProcedure

&AtClient
Procedure NotifyWritingSpreadsheetDocument()
	
	NotifyParameters = New Structure;
	NotifyParameters.Insert("FilePath", Parameters.FilePath);
	NotifyParameters.Insert("TemplateMetadataObjectName", Parameters.TemplateMetadataObjectName);
	NotifyParameters.Insert("LanguageCode", CurrentLanguage);
	
	If WritingCompleted Then
		EventName = "Write_SpreadsheetDocument";
		NotifyParameters.Вставить("SpreadsheetDocument", SpreadsheetDocument);
	Else
		EventName = "UndoEditSpreadsheetDocument";
	EndIf;
	Notify(EventName, NotifyParameters, ThisObject);

EndProcedure

#EndRegion
