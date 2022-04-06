#Region Public
#Region FormEventsWithEditor
Procedure FormOnOpen(Form, CompletionNotifyDescription = Undefined) Export
	Form.UT_CodeEditorClientData = New Structure;
	Form.UT_CodeEditorClientData.Insert("Events", new Array);
	Form.UT_CodeEditorClientData.Insert("EventsHandlers", New Structure);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionNotifyDescription", CompletionNotifyDescription);
	AdditionalParameters.Insert("Form", Form);

	UT_CommonClient.AttachFileSystemExtensionWithPossibleInstallation(
			New NotifyDescription("FormOnOpenEndAttachFileSystemExtension", ThisObject, AdditionalParameters));
EndProcedure
Procedure HTMLEditorFieldDocumentGenerated(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];

	EditorSettings = FormEditors[EditorID];
	EditorSettings.Insert("Initialized", True);

	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;
	Form.AttachIdleHandler("Attachable_CodeEditorDeferredInitializingEditors", 0.1, True);
EndProcedure
Procedure HTMLEditorFieldOnClick(Form, Item, EventData, StandardProcessing) Export
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);
	EditorTypes = UT_CodeEditorClientServer.CodeEditorVariants();

	If EditorType = EditorTypes.Monaco Then
		HTMLEditorFieldOnClickMonaco(Form, Item, EventData, StandardProcessing);
	EndIf;
EndProcedure
Procedure EditorEventsDeferProcessing(Form) Export

	For Each CurrentEvent In Form.UT_CodeEditorClientData.Events Do
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("Item", CurrentEvent.Item);

		If CurrentEvent.EventName = "EVENT_QUERY_CONSTRUCT" Then
			OpenMonacoQueryWizard(CurrentEvent.EventData, AdditionalParameters);
		ElsIf CurrentEvent.EventName = "EVENT_FORMAT_CONSTRUCT" Then
			OpenMonacoFormatStringWizard(CurrentEvent.EventData, AdditionalParameters);
		ElsIf CurrentEvent.EventName = "EVENT_GET_METADATA" Then
			MetadataNameArray = StrSplit(CurrentEvent.EventData, ".");

			If MetadataNameArray[0] = "module" Then
				SetModuleDescriptionForMonacoEditor(CurrentEvent.EventData, AdditionalParameters);
			Else
				SetMetadataEditorForMonacoEditor(CurrentEvent.EventData, AdditionalParameters);
			EndIf;
		Elsif CurrentEvent.EventName = "EVENT_CONTENT_CHANGED" Then
			FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
			EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form,CurrentEvent.Item);
			EditorEvents = FormEditors[EditorID].EditorEvents;

			If ValueIsFilled(EditorEvents.OnChange) Then
				ExecuteNotifyProcessing(New NotifyDescription(EditorEvents.OnChange, Form,
					AdditionalParameters), CurrentEvent.Item);
			EndIf;

		EndIf;
	EndDo;

	Form.UT_CodeEditorClientData.Events.Clear();
КонецПроцедуры

#EndRegion
Function AllFormEditorsInitialized(FormEditors)
	Result = True;
	For Each KeyValue In FormEditors Do
		If Not KeyValue.Value.Initialized Then
			Result = False;
			Break;
		EndIf;
	EndDo;

	Return Result;
EndFunction

Procedure CodeEditorDeferredInitializingEditors(Form) Export
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);
	EditorTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];

	InitializeFormEditorsAfterFieldsGeneration(Form, FormEditors, EditorType, EditorTypes);
	Form.Attachable_CodeEditorInitializingCompletion();
//	Form.Attachable_EditorFieldInitializingCompletion(UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item));
EndProcedure

Procedure InitializeFormEditorsAfterFieldsGeneration(Form, FormEditors, EditorType, EditorTypes)
	For Each KeyValue In FormEditors Do
		EditorSettings = KeyValue.Value;
		EditorFormItem = Form.Item[EditorSettings.EditorField];

		If EditorType = EditorTypes.Text Then
			If ValueIsFilled(EditorSettings.EditorSettings.FontSize) Then
				EditorFormItem.Font = New Font(, EditorSettings.EditorSettings.FontSize);
			EndIf;
		ElsIf EditorType = EditorTypes.Ace Then
			DocumentView = EditorFormItem.Document.defaultView;
			If ValueIsFilled(EditorSettings.EditorSettings.FontSize) Then
				DocumentView.editor.setFontSize(EditorSettings.EditorSettings.FontSize);
			EndIf;
		ElsIf EditorType = EditorTypes.Monaco Then
			DocumentView = EditorFormItem.Document.defaultView;
			DocumentView.setOption("autoResizeEditorLayout", True);

			Info = New SystemInfo;
			DocumentView.init(Info.AppVersion);
			If EditorSettings.EditorLanguage <> "bsl" Then
				DocumentView.setLanguageMode(EditorSettings.EditorLanguage);

				If EditorSettings.EditorLanguage = "bsl_query" Then
					DocumentView.setOption("renderQueryDelimiters", True);
				EndIf;
			EndIf;
			DocumentView.hideScrollX();
			DocumentView.hideScrollY();
			DocumentView.showStatusBar();
			DocumentView.enableQuickSuggestions();
			If ValueIsFilled(EditorSettings.EditorSettings.FontSize) Then
				DocumentView.setFontSize(EditorSettings.EditorSettings.FontSize);
			EndIf;
			If ValueIsFilled(EditorSettings.EditorSettings.LinesHeight) Then
				DocumentView.setLineHeight(EditorSettings.EditorSettings.LinesHeight);
			EndIf;

			DocumentView.disableKeyBinding(9);
			DocumentView.setOption("dragAndDrop", True);

			EditorThemes = UT_CodeEditorClientServer.MonacoEditorThemeVariants();
			If EditorSettings.EditorSettings.Тема = EditorThemes.Dark Then
				If EditorSettings.EditorLanguage = "bsl_query" Then
					DocumentView.setTheme("bsl-dark-query");
				Else
					DocumentView.setTheme("bsl-dark");
				EndIf;
			Else
				If EditorSettings.EditorLanguage = "bsl_query" Then
					DocumentView.setTheme("bsl-white-query");
				Else
					DocumentView.setTheme("bsl-white");
				EndIf;
			EndIf;

			ScriptVariants = UT_CodeEditorClientServer.MonacoEditorSyntaxLanguageVariants();
			If EditorSettings.EditorSettings.ScriptVariant = ScriptVariants.English Then
				DocumentView.switchLang();
			ElsIf EditorSettings.EditorSettings.ScriptVariant = ScriptVariants.Auto Then
				ScriptVariant = UT_ApplicationParameters["ConfigurationScriptVariant"];
				If ScriptVariant = "English" Then
					DocumentView.switchLang();
				EndIf;
			EndIf;

			DocumentView.minimap(EditorSettings.EditorSettings.UseScriptMap);

			If EditorSettings.EditorSettings.HideLineNumbers Then
				DocumentView.hideLineNumbers();
			EndIf;

			If EditorSettings.EditorSettings.DisplaySpacesAndTabs Then
				DocumentView.renderWhitespace(True);
			EndIf;

			If ValueIsFilled(EditorSettings.EditorEvents.OnChange) Then
				DocumentView.setOption("generateModificationEvent", True);
			EndIf;

			DocumentView.clearMetadata();

			ConfigurationDescriptionForInitialization = MetadataDescriptionForMonacoEditorInitialization();

			DocumentView.updateMetadata(UT_CommonClientServer.mWriteJSON(
				GetMetadataObjectsListFromCollectionForMonacoEditor(
				ConfigurationDescriptionForInitialization.CommonModules)), "commonModules.items");
		EndIf;
	EndDo;
EndProcedure

Procedure SetFormItemEditorText(Form, Item, Text) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	SetEditorText(Form, EditorID, Text);
EndProcedure

Procedure SetEditorText(Form, EditorID, Text, SetOriginalText = False) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;

	EditorSettings = FormEditors[EditorID];
	If EditorType = EditorsTypes.Text Then
		Form[EditorSettings.AttributeName] = Text;
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		HTMLDocument.editor.setValue(Text, -1);
	ElsIf EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		If SetOriginalText Then 
			HTMLDocument.setOriginalText(Text);
		EndIf;
		HTMLDocument.updateText(Text);
	EndIf;
EndProcedure

Procedure SetEditorOriginalText(Form, EditorID, Text) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;

	EditorSettings = FormEditors[EditorID];
	If EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		HTMLDocument.setOriginalText(Text);
	EndIf;
EndProcedure

Procedure SetEditorOriginalTextEqualToCurrent(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;

	EditorSettings = FormEditors[EditorID];
	If EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.getText();
		HTMLDocument.setOriginalText(CodeText);
	Endif;
EndProcedure

Function EditorCodeText(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType    = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return "";
	EndIf;
	EditorSettings = FormEditors[EditorID];

	CodeText="";

	If EditorType = EditorsTypes.Text Then
		CodeText = Form[EditorSettings.AttributeName];
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.editor.getValue();
	ElsIf EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.getText();
	EndIf;

	Return TrimAll(CodeText);
EndFunction

Function EditorCodeTextItemForm(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return "";
	EndIf;

	Return EditorCodeText(Form, EditorID);
EndFunction

Function EditorSelectionBorders(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return NewSelectionBorders();
	EndIf;

	EditorSettings = FormEditors[EditorID];

	SelectionBounds = NewSelectionBorders();

	If EditorType = EditorsTypes.Text Then
		EditorItem = Form.Items[EditorSettings.EditorField];

		EditorItem.GetTextSelectionBounds(SelectionBounds.RowBeginning, SelectionBounds.ColumnBeginning,
			SelectionBounds.RowEnd, SelectionBounds.ColumnEnd);
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		SelectedArea = HTMLDocument.editor.getSelectionRange();

		SelectionBounds.RowBeginning= SelectedArea.start.row;
		SelectionBounds.ColumnBeginning = SelectedArea.start.column;
		SelectionBounds.RowEnd = SelectedArea.end.row;
		SelectionBounds.ColumnEnd = SelectedArea.end.column;
	ElsIf EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;

		Select = HTMLDocument.getSelection();
		SelectionBounds.RowBeginning= Select.startLineNumber;
		SelectionBounds.ColumnBeginning = Select.startColumn;
		SelectionBounds.RowEnd = Select.endLineNumber;
		SelectionBounds.ColumnEnd = Select.endColumn;
	EndIf;

	Return SelectionBounds;

EndFunction

Function EditorSelectionBordersFormItem(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return NewSelectionBorders();
	EndIf;

	Return EditorSelectionBorders(Form, EditorID);
EndFunction

Procedure SetTextSelectionBorders(Form, EditorID, RowBeginning, ColumnBeginning, RowEnd, ColumnEnd) Export

	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;

	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Text Then
		EditorItem = Form.Items[EditorSettings.EditorField];

		EditorItem.SetTextSelectionBorders(RowBeginning, ColumnBeginning, RowEnd, ColumnEnd);
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		HTMLDocument.setSelection(RowBeginning, ColumnBeginning, RowEnd, ColumnEnd);
	ElsIf EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		HTMLDocument.setSelection(RowBeginning, ColumnBeginning, RowEnd, ColumnEnd);
	EndIf;

EndProcedure

Procedure SetTextSelectionBordersFormItem(Form, Item, RowBeginning, ColumnBeginning, LineEnd, ColumnEnd) Export

	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	SetTextSelectionBorders(Form, EditorID, RowBeginning, ColumnBeginning, LineEnd, ColumnEnd);

EndProcedure

Procedure InsertTextInCursorLocation(Form, EditorID, Text) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;

	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Text Then
		EditorItem = Form.Items[EditorSettings.EditorField];
		EditorItem.SelectedText = Text;
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		HTMLDocument.editor.insert(Text);
	ElsIf EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		HTMLDocument.selectedText(Text);
	EndIf;
EndProcedure

Procedure InsertTextInCursorLocationFormItem(Form, Item, Text) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	InsertTextInCursorLocation(Form, EditorID, Text);

EndProcedure

Procedure AddCodeEditorContext(Form, EditorID, AddedContext) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;

	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		TypesMap = ConfigurationReferenceTypesMap();
		AddingObjects = New Structure;
		FillMonacoCodeEditorContextStructure(AddingObjects, AddedContext, TypesMap);
		HTMLDocument.updateMetadata(UT_CommonClientServer.mWriteJSON(New Structure("customObjects", AddingObjects)));
	EndIf;
EndProcedure

Procedure OpenQueryWizard(QueryText, CompletionNotifyDescription, CompositionMode = False) Export
#If Not MobileClient Then
	Wizard=New QueryWizard;
	If UT_CommonClientServer.PlatformVersionNotLess_8_3_14() Then
		Wizard.DataCompositionMode=CompositionMode;
	EndIf;

	If ValueIsFilled(TrimAll(QueryText)) Then
		Try
			Wizard.Text=QueryText;
		Except
			Message(ErrorDescription());
			Return;
		EndTry;
	EndIf;
	Wizard.Show(CompletionNotifyDescription);
#EndIf
EndProcedure

Procedure OpenFormatStringWizard(FormatString, CompletionNotifyDescription) Export
	Wizard = New FormatStringWizard;
	Try
		Wizard.Text = FormatString;
	Except
		Info = ErrorInfo();
		ShowMessageBox( , NStr("ru = 'Ошибка в тексте форматной строки:';
							   |en = 'Error in the text of the format string:'") + Chars.LF + Info.Reason.Description);
		Return;
	EndTry;
	Wizard.Show(CompletionNotifyDescription);
EndProcedure

Procedure SaveConfigurationModulesToFiles(CompletionNotifyDescription, CurrentDirectories) Export
	NotificationAdditionalParameters = New Structure;
	NotificationAdditionalParameters.Insert("CompletionNotifyDescription", CompletionNotifyDescription);
	NotificationAdditionalParameters.Insert("CurrentDirectories", CurrentDirectories);

	UT_CommonClient.AttachFileSystemExtensionWithPossibleInstallation(
		New NotifyDescription("SaveConfigurationModulesToFilesEndAttachFileSystemExtension", ThisObject,
		NotificationAdditionalParameters));

EndProcedure

Function EditorSelectedText(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return "";
	EndIf;
	EditorSettings = FormEditors[EditorID];

	CodeText="";

	If EditorType = EditorsTypes.Text Then
		CodeText = Form.Items[EditorSettings.EditorField].SelectedText;
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.editor.getCopyText();
	ElsIf EditorType = EditorsTypes.Monaco Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.selectedText();
	EndIf;

	Return TrimAll(CodeText);

EndFunction

Function EditorSelectedTextFormItem(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return "";
	EndIf;

	Return EditorSelectedText(Form, EditorID);

EndFunction

Procedure AddCommentsToEditorLines(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;
	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Text Then
		CodeText = Form[EditorSettings.AttributeName];
		SelectionBorders = EditorSelectionBorders(Form, EditorID);

		AddAdditionToTextAtLineBeginningBySelectionBorders(CodeText, SelectionBorders, "//");
		Form[EditorSettings.AttributeName] = CodeText;

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.editor.getValue();

		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		SelectionBorders.RowBeginning= SelectionBorders.RowBeginning + 1;
		SelectionBorders.RowEnd = SelectionBorders.RowEnd + 1;

		AddAdditionToTextAtLineBeginningBySelectionBorders(CodeText, SelectionBorders, "//");

		HTMLDocument.editor.setValue(CodeText, -1);
		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning - 1, SelectionBorders.ColumnBeginning
			+ 2, SelectionBorders.RowEnd - 1, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Monaco Then
		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.addComment();

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);

	EndIf;

EndProcedure

Procedure AddCommentsToEditorLinesFormItem(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	AddCommentsToEditorLines(Form, EditorID);
EndProcedure

Procedure DeleteEditorLinesComments(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;
	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Текст Then
		CodeText = Form[EditorSettings.AttributeName];
		SelectionBorders = EditorSelectionBorders(Form, EditorID);

		DeleteTextAdditionInLineBeginningBySelectionBorders(CodeText, SelectionBorders, "//");
		Form[EditorSettings.AttributeName] = CodeText;

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.editor.getValue();

		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		SelectionBorders.RowBeginning= SelectionBorders.RowBeginning + 1;
		SelectionBorders.RowEnd = SelectionBorders.RowEnd + 1;

		DeleteTextAdditionInLineBeginningBySelectionBorders(CodeText, SelectionBorders, "//");

		HTMLDocument.editor.setValue(CodeText, -1);
		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning - 1, SelectionBorders.ColumnBeginning
			+ 2, SelectionBorders.RowEnd - 1, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Monaco Then
		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.removeComment();

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);

	EndIf;

EndProcedure

Procedure DeleteEditorLinesCommentsFormItem(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	DeleteEditorLinesComments(Form, EditorID);
EndProcedure
Procedure AddEditorLineBreaks(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Не AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;
	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Text Then
		CodeText = Form[EditorSettings.AttributeName];
		SelectionBorders = EditorSelectionBorders(Form, EditorID);

		AddAdditionToTextAtLineBeginningBySelectionBorders(CodeText, SelectionBorders, "|");
		Form[EditorSettings.AttributeName] = CodeText;

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.editor.getValue();

		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		SelectionBorders.RowBeginning= SelectionBorders.RowBeginning + 1;
		SelectionBorders.RowEnd = SelectionBorders.RowEnd + 1;

		AddAdditionToTextAtLineBeginningBySelectionBorders(CodeText, SelectionBorders, "|");

		HTMLDocument.editor.setValue(CodeText, -1);
		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning - 1, SelectionBorders.ColumnBeginning
			+ 2, SelectionBorders.RowEnd - 1, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Monaco Then
		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.addWordWrap();

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);

	EndIf;

EndProcedure

Procedure AddEditorLineBreaksFormItem(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	AddEditorLineBreaks(Form, EditorID);
EndProcedure

Procedure DeleteEditorLineBreaks(Form, EditorID) Export
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);

	FormEditors = Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	If Not AllFormEditorsInitialized(FormEditors) Then
		Return;
	EndIf;
	EditorSettings = FormEditors[EditorID];

	If EditorType = EditorsTypes.Текст Then
		CodeText = Form[EditorSettings.AttributeName];
		SelectionBorders = EditorSelectionBorders(Form, EditorID);

		DeleteTextAdditionInLineBeginningBySelectionBorders(CodeText, SelectionBorders, "|");
		Form[EditorSettings.AttributeName] = CodeText;

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Ace Then
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.editor.getValue();

		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		SelectionBorders.RowBeginning= SelectionBorders.RowBeginning + 1;
		SelectionBorders.RowEnd = SelectionBorders.RowEnd + 1;

		DeleteTextAdditionInLineBeginningBySelectionBorders(CodeText, SelectionBorders, "|");

		HTMLDocument.editor.setValue(CodeText, -1);
		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning - 1, SelectionBorders.ColumnBeginning
			+ 2, SelectionBorders.RowEnd - 1, SelectionBorders.ColumnEnd + 2);
	ElsIf EditorType = EditorsTypes.Monaco Then
		SelectionBorders = EditorSelectionBorders(Form, EditorID);
		HTMLDocument=Form.Items[EditorSettings.EditorField].Document.defaultView;
		CodeText = HTMLDocument.removeWordWrap();

		SetTextSelectionBorders(Form, EditorID, SelectionBorders.RowBeginning, SelectionBorders.ColumnBeginning + 2,
			SelectionBorders.RowEnd, SelectionBorders.ColumnEnd + 2);

	EndIf;

EndProcedure

Procedure DeleteEditorLineBreaksFormItem(Form, Item) Export
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(Form, Item);
	If EditorID = Undefined Then
		Return;
	EndIf;

	DeleteEditorLineBreaks(Form, EditorID);
EndProcedure
#EndRegion

#Region Internal

Procedure FormOnOpenEndAttachFileSystemExtension(Result, AdditionalParameters) Export
	LibraryURL =  AdditionalParameters.Form[UT_CodeEditorClientServer.AttributeNameCodeEditorLibraryURL()];
	If LibraryURL = Undefined Or Not ValueIsFilled(LibraryURL) Then
		FormOnOpenEndEditorLibrarySaving(True, AdditionalParameters);
	Else
		EditorType = UT_CodeEditorClientServer.FormCodeEditorType(AdditionalParameters.Form);

		SaveEditorLibraryToDisk(LibraryURL, EditorType, New NotifyDescription("FormOnOpenEndEditorLibrarySaving",
			ThisObject, AdditionalParameters));
	EndIf;
EndProcedure

Procedure FormOnOpenEndEditorLibrarySaving(Result, AdditionalParameters) Export
	Form = AdditionalParameters.Form;
	EditorType = UT_CodeEditorClientServer.FormCodeEditorType(Form);
	EditorsTypes = UT_CodeEditorClientServer.CodeEditorVariants();

	If UT_CodeEditorClientServer.CodeEditorUsesHTMLField(EditorType) Then
		For Each KeyValue In Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()] Do
			//EditorAttributeName = UT_CodeEditorClientServer.AttributeNameCodeEditor(KeyValue.Value.AttributeName);	

			If EditorType = EditorsTypes.Monaco Then
				Form[KeyValue.Value.AttributeName] = EditorSaveDirectory(EditorType) + GetPathSeparator() + "index.html";
			ElsIf EditorType = EditorsTypes.Ace Then
				Form[KeyValue.Value.AttributeName] = AceEditorFileNameForLanguage(KeyValue.Value.EditorLanguage);
			EndIf;
		EndDo;
	Else
		CodeEditorDeferredInitializingEditors(Form);
	EndIf;
	
	// We will notify about the completion of processing initialization of editors when opening the form
	CompletionNotifyDescription= AdditionalParameters.CompletionNotifyDescription;
	If CompletionNotifyDescription = Undefined Then
		Return;
	EndIf;

	ExecuteNotifyProcessing(CompletionNotifyDescription, True);
EndProcedure

Procedure SaveEditorLibraryToDiskEndLibraryDirectoryCreation(DirectoryName, AdditionalParameters) Export

	LibraryURL = AdditionalParameters.LibraryURL;
	LibrarySavingDirectory = AdditionalParameters.LibrarySavingDirectory;

	SavedFilesArray = New Array;
	LibraryFilesMap=GetFromTempStorage(LibraryURL);

	If AdditionalParameters.EditorType = "Ace" Then
		AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, "bsl");
		AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, "css");
		AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, "xml");
		AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, "bsl_query");
		AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, "javascript");
		AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, "html");
	EndIf;

	AdditionalParameters.Insert("SavedFilesArray", SavedFilesArray);
	AdditionalParameters.Insert("LibraryFilesMap", LibraryFilesMap);

	SaveEditorLibraryWriteBeginWritingNextFile(AdditionalParameters);
EndProcedure

Procedure SaveEditorLibraryUnpackEditorLibraryToDirectory(AdditionalParameters, NotifyDescriptionOnCompletion) Export
#If Not WebClient And Not MobileClient Then
	Stream=AdditionalParameters.LibraryFilesMap[AdditionalParameters.CurrentFileKey].OpenStreamForRead();

	ZipReader=New ZipFileReader(Stream);
	ZipReader.ExtractAll(AdditionalParameters.LibrarySavingDirectory, ZIPRestoreFilePathsMode.Restore);

#EndIf

EndProcedure

Procedure SaveEditorLibraryUnpackEditorLibraryToDirectoryEnd(Result, AdditionalParameters) Export

EndProcedure

Procedure SaveEditorLibraryWriteBeginWritingNextFileEnd(AdditionalParameters) Export
	SavedFilesArray = AdditionalParameters.SavedFilesArray;
	SavedFilesArray.Add(AdditionalParameters.CurrentFileKey);

	File = New File(AdditionalParameters.CurrentFileKey);

	If File.Extension = ".zip" Then
		SaveEditorLibraryUnpackEditorLibraryToDirectory(AdditionalParameters,
			New NotifyDescription("SaveEditorLibraryUnpackEditorLibraryToDirectoryEnd", ThisObject,
			AdditionalParameters));
	EndIf;	
		//Else
	SaveEditorLibraryWriteBeginWritingNextFile(AdditionalParameters);
	//EndIf;
EndProcedure

Procedure SaveEditorLibraryWriteBeginWritingNextFileOfTextDocumentEnd(Result, AdditionalParameters) Export
	SavedFilesArray = AdditionalParameters.SavedFilesArray;
	SavedFilesArray.Add(AdditionalParameters.CurrentFileKey);

	SaveEditorLibraryWriteBeginWritingNextFile(AdditionalParameters);
EndProcedure

Procedure SaveEditorLibraryToDiskEndCheckOfLibraryExistOnDisk(Exists, AdditionalParameters) Export
	If Exists Then
		ExecuteNotifyProcessing(AdditionalParameters.CompletionNotifyDescription);
		Return;
	EndIf;

	LibrarySavingDirectory = AdditionalParameters.LibrarySavingDirectory;

	BeginCreatingDirectory(
		New NotifyDescription("SaveEditorLibraryToDiskEndLibraryDirectoryCreation", ThisObject, AdditionalParameters),
		LibrarySavingDirectory);

EndProcedure

Procedure SaveConfigurationModulesToFilesEndAttachFileSystemExtension(Result, AdditionalParameters) Export
	FormParameters = New Structure;
	FormParameters.Insert("CurrentDirectories", AdditionalParameters.CurrentDirectories);

	NotificationAdditionalParameters = New Structure;
	NotificationAdditionalParameters.Insert("CompletionNotifyDescription",
		AdditionalParameters.CompletionNotifyDescription);

	OpenForm("CommonForm.UT_ConfigurationSourseFilesSaveSettings", FormParameters, , , , ,
		New NotifyDescription("SaveConfigurationModulesToFilesEndSettings", ThisObject,
		NotificationAdditionalParameters), FormWindowOpeningMode.Independent);

EndProcedure

Procedure SaveConfigurationModulesToFilesEndSettings(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;

	ConfigurationMetadataDescription = UT_CodeEditorServerCall.ConfigurationMetadataDescription(False);

	SourceFilesSavingParameters = New Structure;
	SourceFilesSavingParameters.Insert("ConfigurationMetadataDescription", ConfigurationMetadataDescription);
	SourceFilesSavingParameters.Insert("Parameters", Result);
	SourceFilesSavingParameters.Insert("AdditionalParameters", AdditionalParameters);
	SourceFilesSavingParameters.Insert("DirectoryIndex", 0);

	SaveConfigurationModulesToFilesBeginProcessingSourceDirectory(SourceFilesSavingParameters);

EndProcedure

Procedure SaveConfigurationModulesToFilesBeginProcessingSourceDirectory(SaveOptions)
	If SaveOptions.DirectoryIndex >= SaveOptions.Parameters.SourceDirectories.Count() Then
		SaveConfigurationModulesToFilesEnd(SaveOptions);
		Return;
	EndIf;

	SourceDirectoryDescription = SaveOptions.Parameters.SourceDirectories[SaveOptions.DirectoryIndex];

	SaveOptions.Insert("SourceDirectoryDescription", SourceDirectoryDescription);
	
	//First you need to clear the directory
	BeginDeletingFiles(New NotifyDescription("SaveConfigurationModulesToFilesEndOfDirectoryFilesDeleting", ThisObject,
		SaveOptions), SourceDirectoryDescription.Directory, "*");

EndProcedure

Procedure SaveConfigurationModulesToFilesEndOfDirectoryFilesDeleting(SaveOptions) Export
	If SaveOptions.SourceDirectoryDescription.OnlyModules Then
		SaveConfigurationModulesToFilesSaveMetadataListWithModules(SaveOptions);
	Else
		SaveConfigurationModulesToFilesRunDesignerForMetadataDump(SaveOptions);
	EndIf;
EndProcedure

Procedure SaveConfigurationModulesToFilesSaveMetadataListWithModules(SaveOptions) Export
	MetadataText = New TextDocument;

	If SaveOptions.SourceDirectoryDescription.Source <> "MainConfiguration" Then
		ExtensionName = SaveOptions.SourceDirectoryDescription.Source;
	Else
		ExtensionName = Undefined;
	EndIf;

	For Each CurrentCollection In SaveOptions.ConfigurationMetadataDescription Do
		If TypeOf(CurrentCollection.Value) <> Type("Structure") Then
			Continue;
		EndIf;

		If CurrentCollection.Key = "Catalogs" Then
			CollectionNameForFile = "Catalog";
		ElsIf CurrentCollection.Key = "Documents" Then
			CollectionNameForFile = "Document";
		ElsIf CurrentCollection.Key = "InformationRegisters" Then
			CollectionNameForFile = "InformationRegister";
		ElsIf CurrentCollection.Key = "AccumulationRegisters" Then
			CollectionNameForFile = "AccumulationRegister";
		ElsIf CurrentCollection.Key = "AccountingRegisters" Then
			CollectionNameForFile = "AccountingRegister";
		ElsIf CurrentCollection.Key = "CalculationRegisters" Then
			CollectionNameForFile = "CalculationRegister";
		ElsIf CurrentCollection.Key = "DataProcessors" Then
			CollectionNameForFile = "DataProcessor";
		ElsIf CurrentCollection.Key = "Reports" Then
			CollectionNameForFile = "Report";
		ElsIf CurrentCollection.Key = "Enums" Then
			CollectionNameForFile = "Enum";
		ElsIf CurrentCollection.Key = "CommonModules" Then
			CollectionNameForFile = "CommonModule";
		ElsIf CurrentCollection.Key = "ChartsOfAccounts" Then
			CollectionNameForFile = "ChartOfAccounts";
		ElsIf CurrentCollection.Key = "BusinessProcesses" Then
			CollectionNameForFile = "BusinessProcess";
		ElsIf CurrentCollection.Key = "Tasks" Then
			CollectionNameForFile = "Task";
		ElsIf CurrentCollection.Key = "ExchangePlans" Then
			CollectionNameForFile = "ExchangePlan";
		ElsIf CurrentCollection.Key = "ChartsOfCharacteristicTypes" Then
			CollectionNameForFile = "ChartOfCharacteristicTypes";
		ElsIf CurrentCollection.Key = "ChartsOfCalculationTypes" Then
			CollectionNameForFile = "ChartOfCalculationTypes";
		ElsIf CurrentCollection.Key = "Constants" Then
			CollectionNameForFile = "Constant";
		Else
			Continue;
		EndIf;

		For Each MetadataKeyValue In CurrentCollection.Value Do
			If MetadataKeyValue.Value.Extension <> ExtensionName Then
				Continue;
			EndIf;
			MetadataText.AddRow(CollectionNameForFile + "." + MetadataKeyValue.Key);
		EndDo;
	EndDo;

	SessionFileVariablesStructure = UT_CommonClient.SessionFileVariablesStructure();
	SaveFileName = SessionFileVariablesStructure.TempFilesDirectory + GetPathSeparator()
		+ "tools_ui_1c_int_list_metadata.txt";
	SaveOptions.Insert("MetadataListFileName", SaveFileName);
	MetadataText.BeginWriting(
		New NotifyDescription("SaveConfigurationModulesToFilesSaveMetadataListWithModulesEnd", ThisObject,
		SaveOptions), SaveFileName);

EndProcedure

Procedure SaveConfigurationModulesToFilesSaveMetadataListWithModulesEnd(Result, SaveOptions) Export
	If Result <> True Then
		Message(Nstr("ru = 'Не удалось сохранить список метаданных с модулями в файл для источника';
					 |en = 'The list of metadata with modules could not be saved to a file for the source'")
			+ SaveOptions.SourceDirectoryDescription.Source);

		SaveOptions.DirectoryIndex = SaveOptions.DirectoryIndex + 1;
		SaveConfigurationModulesToFilesBeginProcessingSourceDirectory(SaveOptions);
		Return;
	EndIf;

	SaveConfigurationModulesToFilesRunDesignerForMetadataDump(SaveOptions);

EndProcedure

Procedure SaveConfigurationModulesToFilesRunDesignerForMetadataDump(SaveOptions) Export
	RunAppString = UT_StringFunctionsClientServer.WrapInOuotationMarks(
		SaveOptions.Parameters.PlatformLaunchFile) + " DESIGNER";

	If SaveOptions.Parameters.InfobasePlacement = 0 Then
		RunAppString = RunAppString + " /F " + UT_StringFunctionsClientServer.WrapInOuotationMarks(
			SaveOptions.Parameters.InfobaseDirectory);
	Else
		DatabasePath = SaveOptions.Parameters.InfobaseServer + "\" + SaveOptions.Parameters.InfoBaseName;
		RunAppString = RunAppString + " /S " + UT_StringFunctionsClientServer.WrapInOuotationMarks(
			DatabasePath);
	EndIf;
	RunAppString = RunAppString + " /N" + UT_StringFunctionsClientServer.WrapInOuotationMarks(
		SaveOptions.Parameters.User);

	If ValueIsFilled(SaveOptions.Parameters.Password) Then
		RunAppString = RunAppString + " /P" + UT_StringFunctionsClientServer.WrapInOuotationMarks(
			SaveOptions.Parameters.Password);
	EndIf;
	RunAppString = RunAppString + " /DisableStartupMessages /DisableStartupDialogs";

	RunAppString = RunAppString + " /DumpConfigToFiles " + UT_StringFunctionsClientServer.WrapInOuotationMarks(
		SaveOptions.SourceDirectoryDescription.Directory) + " -format Hierarchical";

	If SaveOptions.SourceDirectoryDescription.Source <> "MainConfiguration" Then
		RunAppString = RunAppString + " -Extension " + SaveOptions.SourceDirectoryDescription.Source;
	EndIf;
	If SaveOptions.SourceDirectoryDescription.OnlyModules Then
		RunAppString = RunAppString + " -listFile " + UT_StringFunctionsClientServer.WrapInOuotationMarks(
			SaveOptions.MetadataListFileName);

	EndIf;
	SessionFileVariablesStructure = UT_CommonClient.SessionFileVariablesStructure();

	SaveOptions.Insert("RunDesignerLogFileName", SessionFileVariablesStructure.TempFilesDirectory + GetPathSeparator()
		+ "tools_ui_1c_int_list_metadata_out.txt");

	RunAppString = RunAppString + " /Out " + UT_StringFunctionsClientServer.WrapInOuotationMarks(
		SaveOptions.RunDesignerLogFileName);

	BeginRunningApplication(
		New NotifyDescription("SaveConfigurationModulesToFilesOnEndMetadataDumpToDirectory", ThisObject, SaveOptions),
		RunAppString, , True);
EndProcedure

Procedure SaveConfigurationModulesToFilesOnEndMetadataDumpToDirectory(CompletionCode, SaveOptions) Export
	If CompletionCode <> 0 Then
		TextDocument = New TextDocument;

		NotificationAdditionalParameters = New Structure;
		NotificationAdditionalParameters.Insert("TextDocument", TextDocument);
		NotificationAdditionalParameters.Insert("SaveOptions", SaveOptions);

		TextDocument.BeginReading(
			New NotifyDescription("SaveConfigurationModulesToFilesOnEndMetadataDumpToDirectoryEndLogReading",
			ThisObject, NotificationAdditionalParameters), SaveOptions.RunDesignerLogFileName);
		Return;
	EndIf;
	SaveOptions.DirectoryIndex = SaveOptions.DirectoryIndex + 1;
	SaveConfigurationModulesToFilesBeginProcessingSourceDirectory(SaveOptions);
EndProcedure

Procedure SaveConfigurationModulesToFilesOnEndMetadataDumpToDirectoryEndLogReading(AdditionalParameters) Export
	SaveOptions = AdditionalParameters.SaveOptions;
	TextDocument = AdditionalParameters.TextDocument;
	Message(Nstr("ru = 'Не удалось сохранить исходные файлы для источника';
				 |en = 'Could not save the source files for the source'")
		+ SaveOptions.SourceDirectoryDescription.Source + ":" + Chars.LF + TextDocument.GetText());

	SaveOptions.DirectoryIndex = SaveOptions.DirectoryIndex + 1;
	SaveConfigurationModulesToFilesBeginProcessingSourceDirectory(SaveOptions);

EndProcedure

Procedure SaveConfigurationModulesToFilesEnd(SaveOptions)
	ExecuteNotifyProcessing(SaveOptions.AdditionalParameters.CompletionNotifyDescription,
		SaveOptions.Parameters.SourceDirectories);
EndProcedure

#Region Monaco

Procedure OnEndEditMonacoFormattedString(Text, AdditionalParameters) Export
	If Text = Undefined Then
		Return;
	EndIf;

	FormatString = StrReplace(Text, "'", "");
	FormatString = """" + FormatString + """";

	DocumentView = AdditionalParameters.Form.Items[AdditionalParameters.Item.Name].Document.defaultView;

	If AdditionalParameters.Property("Position") Then
		SetTextMonaco(DocumentView, FormatString, UT_CommonClientServer.mWriteJSON(
			AdditionalParameters.Position), True);
	Else
		SetTextMonaco(DocumentView, FormatString, , True);
	EndIf;
EndProcedure

Procedure OnEndEditMonacoQuery(Text, AdditionalParameters) Export

	If Text = Undefined Then
		Return;
	EndIf;

	isQueryMode = False;
	If AdditionalParameters.Property("isQueryMode") Then
		isQueryMode = AdditionalParameters.isQueryMode;
	Endif;
	
	If isQueryMode Then
		QueryText = Text;
	Else
		QueryText = StrReplace(Text, Chars.LF, Chars.LF + "|");
		QueryText = StrReplace(QueryText, """", """""");
		QueryText = """" + QueryText + """";
	EndIf;

     DocumentView = AdditionalParameters.Form.Items[AdditionalParameters.Item.Name].Document.defaultView;
     
	If AdditionalParameters.Property("Position") Then
		If AdditionalParameters.Position.startLineNumber = AdditionalParameters.Position.endLineNumber
			And AdditionalParameters.Position.startColumn = AdditionalParameters.Position.endColumn Then
			DocumentView.updateText(QueryText);
		Else
			SetTextMonaco(DocumentView, QueryText, UT_CommonClientServer.mWriteJSON(
			AdditionalParameters.Position), True);
		Endif;
	Else
		SetTextMonaco(DocumentView, QueryText, , True);
	EndIf;
	
EndProcedure

Procedure OpenMonacoQueryWizardQuestionCompletion(Result, AdditionalParameters) Export
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	OpenQueryWizard("", New NotifyDescription("OnEndEditMonacoQuery", ThisObject, AdditionalParameters));

EndProcedure

Procedure OpenMonacoFormatStringWizardQuestionCompletion(Result, AdditionalParameters) Export
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	OpenFormatStringWizard("", New NotifyDescription("OnEndEditMonacoFormattedString", ThisObject,
		AdditionalParameters));

EndProcedure
#EndRegion
#EndRegion

#Region Private

Procedure AddAdditionToTextAtLineBeginningBySelectionBorders(CodeText, SelectionBorders, Addition)
	Text = New TextDocument;
	Text.SetText(CodeText);

	If Not ValueIsFilled(SelectionBorders.RowBeginning) And Not ValueIsFilled(SelectionBorders.RowEnd) Then
		Return;
	EndIf;

	For LineNumber = SelectionBorders.RowBeginning To SelectionBorders.RowEnd Do
		TextLine = Text.GetLine(LineNumber);
		Text.ReplaceLine(LineNumber, Addition + TextLine);
	EndDo;
	CodeText = Text.GetText();
EndProcedure

Procedure DeleteTextAdditionInLineBeginningBySelectionBorders(CodeText, SelectionBorders, Addition)
	Text = New TextDocument;
	Text.SetText(CodeText);

	If Not ValueIsFilled(SelectionBorders.RowBeginning) And Not ValueIsFilled(SelectionBorders.RowEnd) Then
		Return;
	EndIf;

	For LineNumber = SelectionBorders.RowBeginning To SelectionBorders.RowEnd Do
		TextLine = Text.GetLine(LineNumber);
		If StrStartsWith(TextLine, Addition) Then
			TextLine = Mid(TextLine, StrLen(Addition) + 1);
		EndIf;

		Text.ReplaceLine(LineNumber, TextLine);
	EndDo;
	CodeText = Text.GetText();
EndProcedure

Function CodeEditorNewEventForProcessing()
	Event = New Structure;
	Event.Insert("Item");
	Event.Insert("EventName");
	Event.Insert("EventData");

	Return Event;
EndFunction

Function PrepareTextForQueryWizard(Text)

	QueryText = StrReplace(Text, "|", "");
	QueryText = StrReplace(QueryText, """""", "$");
	QueryText = StrReplace(QueryText, """", "");
	QueryText = StrReplace(QueryText, "$", """");

	Return QueryText;
EndFunction

Function NewSelectionBorders()
	Borders = New Structure;
	Borders.Insert("RowBeginning", 1);
	Borders.Insert("ColumnBeginning", 1);
	Borders.Insert("RowEnd", 1);
	Borders.Insert("ColumnEnd", 1);

	Return Borders;
EndFunction

#Region Monaco
Procedure FillMonacoCodeEditorContextStructure(AddingObjects, AddedContext, TypesMap)
	For Each KeyValue In AddedContext Do
		AddedObject = New Structure("ref,name");
		AddedObject.name = KeyValue.Key;
		If TypeOf(KeyValue.Value) = Type("Structure") Then
			TypeName = KeyValue.Value.Type;

			If KeyValue.Value.Property("ChildProperties") And KeyValue.Value.ChildProperties.Count() > 0 Then

				AddedObject.Insert("properties", New Structure);

				FillMonacoCodeEditorContextStructure(AddedObject.properties, KeyValue.Value.ChildProperties, TypesMap);
//				For each Property In KeyValue.Value.ChildProperties Do
//					AddAttributeDescriptionForMonacoEditor(AddedObject.properties,
//																Property,
//																True,
//																TypesMap);
//				EndDo;

			EndIf;

		Else
			TypeName = KeyValue.Value;
		EndIf;
		AddedObject.ref = MonacoEditorTypeBy1CTypeAsString(TypeName, TypesMap);
		AddingObjects.Insert(KeyValue.Ключ, AddedObject);
	EndDo;

EndProcedure

Function MetadataDescriptionForMonacoEditorInitialization()
	Description = UT_ApplicationParameters["MetadataDescriptionForMonacoEditorInitialization"];
	If Description <> Undefined Then
		Return Description;
	EndIf;

	ConfigurationDescriptionForInitialization = UT_CodeEditorServerCall.MetaDataDescriptionForMonacoEditorInitialize();
	UT_ApplicationParameters.Insert("MetadataDescriptionForMonacoEditorInitialization",
		ConfigurationDescriptionForInitialization);

	Return ConfigurationDescriptionForInitialization;

EndFunction

Procedure SetTextMonaco(DocumentView, Text, Position = Undefined, ConsiderFirstLineIndent = True)
	DocumentView.setText(Text, Position);
EndProcedure

Procedure OpenMonacoFormatStringWizard(EventParameters, AdditionalParameters)
	If EventParameters = Undefined Then
		UT_CommonClient.ShowQuestionToUser(
			New NotifyDescription("OpenMonacoFormatStringWizardQuestionCompletion", ThisObject, AdditionalParameters),
			Nstr("ru = 'Форматная строка не найдена.';
				 |en = 'Format string was not found.'") + Chars.LF + NSTR("ru = 'Создать новую форматную строку?';
																		  |en = 'Create a new format string?'"),
			QuestionDialogMode.YesNo);
	Else
		FormatString = StrReplace(StrReplace(EventParameters.text, "|", ""), """", "");

		NotificationParameters = AdditionalParameters;

		Position = New Structure;
		Position.Insert("startLineNumber", EventParameters.startLineNumber);
		Position.Insert("startColumn", EventParameters.startColumn);
		Position.Insert("endLineNumber", EventParameters.endLineNumber);
		Position.Insert("endColumn", EventParameters.endColumn);

		NotificationParameters.Insert("Position", Position);

		OpenFormatStringWizard(FormatString, New NotifyDescription("OnEndEditMonacoFormattedString", ThisObject,
			NotificationParameters));
	EndIf;
EndProcedure

Procedure OpenMonacoQueryWizard(EventParameters, AdditionalParameters)
	If EventParameters = Undefined Then
		UT_CommonClient.ShowQuestionToUser(
			New NotifyDescription("OpenMonacoQueryWizardQuestionCompletion", ThisObject, AdditionalParameters), NSTR("ru = 'Не найден текст запроса';
																													 |en = 'Query text not found'")
			+ Chars.LF + NSTR("ru = 'Создать новый запрос?';
							  |en = 'Create a new query?'"), QuestionDialogMode.YesNo);
	Else

		If EventParameters.isQueryMode Then
			QueryText = EventParameters.text;
		Else
			QueryText = PrepareTextForQueryWizard(EventParameters.text);
		EndIf;
		NotificationParameters = AdditionalParameters;

		Position = New Structure;
		Position.Insert("startLineNumber", EventParameters.startLineNumber);
		Position.Insert("startColumn", EventParameters.startColumn);
		Position.Insert("endLineNumber", EventParameters.endLineNumber);
		Position.Insert("endColumn", EventParameters.endColumn);

		NotificationParameters.Insert("Position", Position);
		NotificationParameters.Insert("isQueryMode", EventParameters.isQueryMode);
		OpenQueryWizard(QueryText, New NotifyDescription("OnEndEditMonacoQuery", ThisObject, NotificationParameters));
	EndIf;
EndProcedure

Procedure HTMLEditorFieldOnClickMonaco(Form, Item, EventData, StandardProcessing)
	
		Event = EventData.Event.eventData1C;

	If Event = Undefined Then
		Return;
	EndIf;
//	StandardProcessing = False;
		
	EventForProcessing = CodeEditorNewEventForProcessing();
	EventForProcessing.Item = Item;
	EventForProcessing.EventName = Event.event;
	
	DataOfEventForProcessing = Undefined;
	If Event.event = "EVENT_GET_METADATA" Then
		DataOfEventForProcessing = Event.params;
	ElsIf Event.event = "EVENT_QUERY_CONSTRUCT" Then 
		QueryParameters = Event.params;
		DocumentHTMLView = EventData.Document.defaultView;
		
		If DocumentHTMLView.isQueryMode() Then
			SelectionBorders = EditorSelectionBordersFormItem(Form, Item);
			DataOfEventForProcessing = New Structure;
			DataOfEventForProcessing.Insert("isQueryMode", True);
			DataOfEventForProcessing.Insert("startLineNumber", SelectionBorders.RowBeginning);
			DataOfEventForProcessing.Insert("startColumn", SelectionBorders.ColumnBeginning);
			DataOfEventForProcessing.Insert("endLineNumber", SelectionBorders.RowEnd);
			DataOfEventForProcessing.Insert("endColumn", SelectionBorders.ColumnEnd);
			DataOfEventForProcessing.Insert("text", DocumentHTMLView.getText());
		Else
			If QueryParameters = Undefined Then
				QueryParameters = DocumentHTMLView.getQuery();
			Endif;

			If QueryParameters <> Undefined And ValueIsFilled(QueryParameters) Then
				DataOfEventForProcessing = New Structure;
				DataOfEventForProcessing.Insert("isQueryMode", False);
				DataOfEventForProcessing.Insert("startLineNumber", QueryParameters.range.startLineNumber);
				DataOfEventForProcessing.Insert("startColumn", QueryParameters.range.startColumn);
				DataOfEventForProcessing.Insert("endLineNumber", QueryParameters.range.endLineNumber);
				DataOfEventForProcessing.Insert("endColumn", QueryParameters.range.endColumn);
				DataOfEventForProcessing.Insert("text", QueryParameters.text);
			Endif;

		EndIf;
		
	ElsIf Event.event = "EVENT_FORMAT_CONSTRUCT" Then 
		If Event.params <> Undefined And ValueIsFilled(QueryParameters) Then
			DataOfEventForProcessing = New Structure;
			DataOfEventForProcessing.Insert("startLineNumber", Event.params.range.startLineNumber);
			DataOfEventForProcessing.Insert("startColumn", Event.params.range.startColumn);
			DataOfEventForProcessing.Insert("endLineNumber", Event.params.range.endLineNumber);
			DataOfEventForProcessing.Insert("endColumn", Event.params.range.endColumn);
			DataOfEventForProcessing.Insert("text", Event.params.text);
		Endif;
	Endif;	
	
	EventForProcessing.EventData = DataOfEventForProcessing;
	Form.UT_CodeEditorClientData.Events.Add(EventForProcessing);

	Form.AttachIdleHandler("Attachable_CodeEditorDeferProcessingOfEditorEvents", 0.1, True);
EndProcedure

Function MetadataTypeDirectoryName(MetadataObjectType)
	If MetadataObjectType = "catalogs" Then
		Return "Catalogs";
	ElsIf MetadataObjectType = "documents" Then
		Return "Documents";
	ElsIf MetadataObjectType = "constants" Then
		Return "Constants";
	ElsIf MetadataObjectType = "enums" Then
		Return "Enums";
	ElsIf MetadataObjectType = "reports" Then
		Return "Reports";
	ElsIf MetadataObjectType = "dataprocessors" Then
		Return "DataProcessors";
	ElsIf MetadataObjectType = "chartsofcharacteristictypes" Then
		Return "ChartsOfCharacteristicTypes";
	ElsIf MetadataObjectType = "chartsofaccounts" Then
		Return "ChartsOfAccounts";
	ElsIf MetadataObjectType = "chartsofcalculationtypes" Then
		Return "ChartsOfCalculationTypes";
	ElsIf MetadataObjectType = "informationregisters" Then
		Return "InformationRegisters";
	ElsIf MetadataObjectType = "accumulationregisters" Then
		Return "AccumulationRegisters";
	ElsIf MetadataObjectType = "accountingregisters" Then
		Return "AccountingRegisters";
	ElsIf MetadataObjectType = "calculationregisters" Then
		Return "CalculationRegisters";
	ElsIf MetadataObjectType = "businessprocesses" Then
		Return "BusinessProcesses";
	ElsIf MetadataObjectType = "tasks" Then
		Return "Tasks";
	ElsIf MetadataObjectType = "exchangeplans" Then
		Return "ExchangePlans";
	EndIf;

EndFunction

Procedure StartSearchOfModuleFileInSourceFilesDirectory(AdditionalParameters)
	If AdditionalParameters.SourcesDirectories.Count() <= AdditionalParameters.SourcesDirectoryIndex Then
		Return;
	EndIf;
	SourceFilesDirectory = AdditionalParameters.SourcesDirectories[AdditionalParameters.SourcesDirectoryIndex].Directory;

	If Not ValueIsFilled(SourceFilesDirectory) Then
		AdditionalParameters.SourcesDirectoryIndex = AdditionalParameters.SourcesDirectoryIndex + 1;
		StartSearchOfModuleFileInSourceFilesDirectory(AdditionalParameters);
		Return;
	EndIf;

	FileSeacrhDirectoryName = SourceFilesDirectory + GetPathSeparator() + AdditionalParameters.ModuleDirectory
		+ GetPathSeparator() + AdditionalParameters.MetadataObjectDescription.Name;
	AdditionalParameters.Insert("FileSeacrhDirectoryName", FileSeacrhDirectoryName);

	BeginFindingFiles(New NotifyDescription("SetModuleDescriptionForMonacoEditorOnEndModuleFilesSeacrh", ThisObject,
		AdditionalParameters), FileSeacrhDirectoryName, AdditionalParameters.ModuleFileName, True);

EndProcedure

Procedure SetModuleDescriptionForMonacoEditor(UpdatedMetadataObject, AdditionalParameters)
	MetadataNamesArray = StrSplit(UpdatedMetadataObject, ".");

	If MetadataNamesArray.Count() < 2 Then
		Return;
	EndIf;

	FormEditors = AdditionalParameters.Form[UT_CodeEditorClientServer.AttributeNameCodeEditorFormCodeEditors()];
	EditorID = UT_CodeEditorClientServer.EditorIDByFormItem(AdditionalParameters.Form, AdditionalParameters.Item);
	EditorSettings = FormEditors[EditorID];
	AdditionalParameters.Insert("SourcesDirectories", EditorSettings.EditorSettings.SourceFilesDirectories);

	If AdditionalParameters.SourcesDirectories.Count() = 0 Then
		Return;
	EndIf;

	AdditionalParameters.Insert("SourcesDirectoryIndex", 0);

	ModuleType = MetadataNamesArray[1];

	AdditionalParameters.Insert("UpdatedMetadataObject", UpdatedMetadataObject);
	AdditionalParameters.Insert("MetadataNamesArray", MetadataNamesArray);

	If ModuleType = "manager" Then
		MetadataObjectDescription = UT_CodeEditorServerCall.ConfigurationMetadataObjectDescriptionByName(
			MetadataNamesArray[2], MetadataNamesArray[3]);

		ModuleDirectory = MetadataTypeDirectoryName(MetadataNamesArray[2]);
		FileName = "ManagerModule.bsl";

		AdditionalParameters.Insert("IsCommonModule", False);

	ElsIf ModuleType = "object" Then
		MetadataObjectDescription = UT_CodeEditorServerCall.ConfigurationMetadataObjectDescriptionByName(
			MetadataNamesArray[2], MetadataNamesArray[3]);

		ModuleDirectory = MetadataTypeDirectoryName(MetadataNamesArray[2]);
		FileName = "ObjectModule.bsl";

		AdditionalParameters.Insert("IsCommonModule", False);
	Else
		MetadataObjectDescription = UT_CodeEditorServerCall.ConfigurationMetadataObjectDescriptionByName(
			"CommonModules", MetadataNamesArray[1]);

		ModuleDirectory = "CommonModules";
		FileName = "Module.bsl";

		AdditionalParameters.Insert("IsCommonModule", True);
	EndIf;

	AdditionalParameters.Insert("MetadataObjectDescription", MetadataObjectDescription);
	AdditionalParameters.Insert("ModuleDirectory", ModuleDirectory);
	AdditionalParameters.Insert("ModuleFileName", FileName);

	StartSearchOfModuleFileInSourceFilesDirectory(AdditionalParameters);
EndProcedure
Procedure SetModuleDescriptionForMonacoEditorOnEndModuleFilesSeacrh(FoundFiles, AdditionalParameters) Export
	If FoundFiles = Undefined Then
		AdditionalParameters.SourcesDirectoryIndex = AdditionalParameters.SourcesDirectoryIndex + 1;
		StartSearchOfModuleFileInSourceFilesDirectory(AdditionalParameters);
		Return;
	EndIf;

	If FoundFiles.Count() = 0 Then
		AdditionalParameters.SourcesDirectoryIndex = AdditionalParameters.SourcesDirectoryIndex + 1;
		StartSearchOfModuleFileInSourceFilesDirectory(AdditionalParameters);
		Return;
	EndIf;

	FileName = FoundFiles[0].FullName;
	AdditionalParameters.Insert("FileName", FileName);

	TextDocument = New TextDocument;

	AdditionalParameters.Insert("TextDocument", TextDocument);
	TextDocument.BeginReading(
		New NotifyDescription("SetModuleDescriptionForMonacoEditorEndFileReading", ThisObject, AdditionalParameters),
		AdditionalParameters.FileName);

EndProcedure

Procedure SetModuleDescriptionForMonacoEditorEndFileReading(AdditionalParameters) Export
	ModuleText = AdditionalParameters.TextDocument.GetText();

	DocumentView = AdditionalParameters.Item.Document.defaultView;

	If AdditionalParameters.IsCommonModule Then
		DocumentView.parseCommonModule(AdditionalParameters.MetadataObjectDescription.Name, ModuleText, False);
	Else
		UpdatedMetadataObjectsMap = MapOfMonacoEditorUpdatedMetadataObjectsAndMetadataUpdateEventParameters();
		UpdatedEditorCollection = UpdatedMetadataObjectsMap[AdditionalParameters.MetadataObjectDescription.ObjectType];
		UpdatedEditorCollection = UpdatedEditorCollection + "." + AdditionalParameters.MetadataObjectDescription.Name + "."
			+ AdditionalParameters.MetadataNamesArray[1];

		DocumentView.parseMetadataModule(ModuleText, UpdatedEditorCollection);
	EndIf;
	DocumentView.triggerSuggestions();

EndProcedure

Procedure SetMetadataEditorForMonacoEditor(UpdatedMetadataObject, AdditionalParameters)

	MetadataNamesArray = StrSplit(UpdatedMetadataObject, ".");

	ObjectType = MetadataNamesArray[0];

	UpdatedMetadataObjectsMap = MapOfMonacoEditorUpdatedMetadataObjectsAndMetadataUpdateEventParameters();
	UpdatedEditorCollection = UpdatedMetadataObjectsMap[ObjectType];

	If MetadataNamesArray.Count() = 1 Then
		UpdatedData = New Structure;

		NamesArray = UT_CodeEditorServerCall.MetadataListByType(ObjectType);
		For Each CurrentName In NamesArray Do
			UpdatedData.Insert(CurrentName, New Structure);
		EndDo;
	Else
		MetadataObjectDescription = UT_CodeEditorServerCall.ConfigurationMetadataObjectDescriptionByName(
			ObjectType, MetadataNamesArray[1]);
		Description = MetadataObjectDescriptionForMonacoEditor(MetadataObjectDescription);

		UpdatedData = Description;

		UpdatedEditorCollection = UpdatedEditorCollection + "." + MetadataObjectDescription.Name;
	EndIf;

	DocumentView = AdditionalParameters.Item.Document.defaultView;
	DocumentView.updateMetadata(UT_CommonClientServer.mWriteJSON(
			UpdatedData), UpdatedEditorCollection);

	DocumentView.triggerSuggestions();
EndProcedure

Function MonacoEditorObjectTypeBy1CObjectType(ObjectType)

EndFunction

Function MonacoEditorTypeBy1CTypeAsString(Type1COrString, ReferenceTypesMap)
	If ReferenceTypesMap = Undefined Then
		Return "";
	EndIf;

	Type1C = Type1COrString;
	If TypeOf(Type1C) = Type("String") Then
		If StrFind(Type1COrString, ".") > 0 Then
			Return Type1COrString;
		EndIf;

		Try
			Type1C = Type(Type1C);
		Except
			Return "types." + Type1COrString;
		EndTry;
	ElsIf TypeOf(Type1C) = Type("TypeDescription") Then
		TypesFromType = Type1C.Types();
		If TypesFromType.Count() > 0 Then
			Type1C = TypesFromType[0];
		EndIf;
	EndIf;

	TypeMetadata=ReferenceTypesMap[Type1C];

	If TypeMetadata = Undefined Then
		If TypeOf(Type1COrString) = Type("String") Then
			Try
				Str = New (Type1COrString);
				Return "classes." + Type1COrString;
			Except
				Return "types." + Type1COrString;
			EndTry;
		Else
			Return "";
		EndIf;
	EndIf;

	If TypeMetadata.ObjectType = "Catalog" Then
		Return "catalogs." + TypeMetadata.Name;
	ElsIf TypeMetadata.ObjectType = "Document" Then
		Return "documents." + TypeMetadata.Name;
	ElsIf TypeMetadata.ObjectType = "Task" Then
		Return "tasks." + TypeMetadata.Name;
	ElsIf TypeMetadata.ObjectType = "ChartOfCalculationTypes" Then
		Return "chartsOfCalculationTypes." + TypeMetadata.Name;
	ElsIf TypeMetadata.ObjectType = "ChartOfCharacteristicTypes" Then
		Return "chartsOfCharacteristicTypes." + TypeMetadata.Name;
	ElsIf TypeMetadata.ObjectType = "ExchangePlan" Then
		Return "exchangePlans." + TypeMetadata.Name;
	ElsIf TypeMetadata.ObjectType = "ChartOfAccounts" Then
		Return "сhartsOfAccounts." + TypeMetadata.Name;
	EndIf;

	Return "";
EndFunction

Function GetLinkToMetadataObjectForMonacoEditor(Attribute, TypesMap)

	Link = "";

	Types = Attribute.Type.Types();

	IndexOf = 0;

	For Each CurrentType In Types Do
		Link = MonacoEditorTypeBy1CTypeAsString(CurrentType, TypesMap);

		If ValueIsFilled(Link) Then
			Break;
		EndIf;
	EndDo;
	Return Link;

EndFunction

Procedure AddAttributeDescriptionForMonacoEditor(AttributesDescription, Attribute, GetAttributeLinks, TypesMap)

	Link = "";
	If GetAttributeLinks Then
		Link= GetLinkToMetadataObjectForMonacoEditor(Attribute, TypesMap);
	EndIf;

	AttributeDescription = New Structure("name", Attribute.Name);

	If ValueIsFilled(Link) Then
		AttributeDescription.Insert("ref", Link);
	EndIf;

	AttributesDescription.Insert(Attribute.Name, AttributeDescription);

EndProcedure

Function MetadataObjectDescriptionForMonacoEditor(MetadataObjectDescription)
	TypesMap = ConfigurationReferenceTypesMap();
	AttributesDescription = New Structure;
	ResourcesDescription = New Structure;
	PredefinedDescription = New Structure;
	TabularSectionsDescription = New Structure;
	AdditionalProperties = New Structure;

	If MetadataObjectDescription.ObjectType = "Enum" Or MetadataObjectDescription.ObjectType = "enums" Then

		For Each EmunValueKeyValue In MetadataObjectDescription.EnumValues Do
			AttributesDescription.Insert(EmunValueKeyValue.Key, New Structure("name", EmunValueKeyValue.Value));
		EndDo;

	Else

		If MetadataObjectDescription.Property("Attributes") Then
			For Each AttributeKeyValue In MetadataObjectDescription.Attributes Do
				AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, True, TypesMap);
			EndDo;
		EndIf;
		If MetadataObjectDescription.Property("StandardAttributes") Then
			For Each AttributeKeyValue In MetadataObjectDescription.StandardAttributes Do
				AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, False, TypesMap);
			EndDo;
		EndIf;
		If MetadataObjectDescription.Property("Predefined") Then
				
				//If MetadataName(FullName) = "ChartOfAccounts" Then
				//	
				//	Query = New Query(
				//	"SELECT
				//	|	ChartOfAccounts.Code AS Code,
				//	|	ChartOfAccounts.PredefinedDataName AS Name
				//	|FROM
				//	|	&Table AS ChartOfAccounts
				//	|WHERE
				//	|	ChartOfAccounts.Predefined");				
				//						
				//	Query.Text = StrReplace(Query.Text, "&Table", FullName);
				//	
				//	Selection = Query.Execute().StartChoosing();
				//	
				//	While Selection.Next() Do 
				//		PredefinedDescription.Insert(Selection.Name, StrTemplate("%1 (%2)", Selection.Name, Selection.Code));
				//	EndDo;
				//	
				//Else				
			For Each NameKeyValue In MetadataObjectDescription.Predefined Do
				PredefinedDescription.Insert(NameKeyValue.Key, "");
			EndDo;
				
				//EndIf;

		EndIf;

		If MetadataObjectDescription.Property("Dimensions") Then

			For Each AttributeKeyValue In MetadataObjectDescription.Dimensions Do
				AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, True, TypesMap);
			EndDo;
			For Each AttributeKeyValue In MetadataObjectDescription.Resources Do
				AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, True, TypesMap);
			EndDo;
				
				//FillRegisterType(AdditionalProperties, MetadataObject, FullName);				

		EndIf;

		If MetadataObjectDescription.Property("TabularSections") Then

			For Each TabularSectionKeyValue In MetadataObjectDescription.TabularSections Do

				TabularSection = TabularSectionKeyValue.Value;
				AttributesDescription.Insert(TabularSection.Name, New Structure("name", "TS: "
					+ TabularSection.Synonym));

				TabularSectionDescription = New Structure;

				If TabularSection.Property("StandardAttributes") Then
					For Each TabularSectionAttribute In TabularSection.StandardAttributes Do
						TabularSectionDescription.Insert(TabularSectionAttribute.Value.Name,
							TabularSectionAttribute.Value.Synonym);
					EndDo;
				EndIf;

				If TabularSection.Property("Attributes") Then
					For Each TabularSectionAttribute In TabularSection.Attributes Do
						AddAttributeDescriptionForMonacoEditor(TabularSectionDescription, TabularSectionAttribute.Value,
							True, TypesMap);
					EndDo;
				EndIf;

				TabularSectionsDescription.Insert(TabularSection.Name, TabularSectionDescription);

			EndDo;

		EndIf;
		If MetadataObjectDescription.Property("StandardTabularSections") Then

			For Each TabularSectionKeyValue In MetadataObjectDescription.StandardTabularSections Do

				TabularSection = TabularSectionKeyValue.Value;
				AttributesDescription.Insert(TabularSection.Name, New Structure("name", "ТЧ: "
					+ TabularSection.Synonym));

				TabularSectionDescription = New Structure;

				If TabularSection.Property("StandardAttributes") Then
					For Each TabularSectionAttribute In TabularSection.StandardAttributes Do
						TabularSectionDescription.Insert(TabularSectionAttribute.Value.Name,
							TabularSectionAttribute.Value.Synonym);
					EndDo;
				EndIf;

				If TabularSection.Property("Attributes") Then
					For Each TabularSectionAttribute In TabularSection.Attributes Do
						AddAttributeDescriptionForMonacoEditor(TabularSectionDescription, TabularSectionAttribute.Value,
							True, TypesMap);
					EndDo;
				EndIf;

				TabularSectionsDescription.Insert(TabularSection.Name, TabularSectionDescription);

			EndDo;

		EndIf;

	EndIf;

	ObjectStructure = New Structure;
	ObjectStructure.Insert("properties", AttributesDescription);

	For Each Iterator In AdditionalProperties Do
		ObjectStructure.Insert(Iterator.Key, Iterator.Value);
	EndDo;

	If ResourcesDescription.Count() > 0 Then
		ObjectStructure.Insert("resources", ResourcesDescription);
	EndIf;

	If PredefinedDescription.Count() > 0 Then
		ObjectStructure.Insert("predefined", PredefinedDescription);
	EndIf;

	If TabularSectionsDescription.Count() > 0 Then
		ObjectStructure.Insert("tabulars", TabularSectionsDescription);
	EndIf;

	Return ObjectStructure;
EndFunction

Function DescribeMetadataObjectsCollectionForMonacoEditor(Collection, TypesMap)

	CollectionDescription = New Structure;

	For Each CollectionItemKeyValue In Collection Do

		AttributesDescription = New Structure;
		ResourcesDescription = New Structure;
		PredefinedDescription = New Structure;
		TabularSectionsDescription = New Structure;
		AdditionalProperties = New Structure;

		MetadataObject = CollectionItemKeyValue.Value;

		If MetadataObject.ObjectType = "Enum" Then

			For Each EmunValueKeyValue In MetadataObject.EnumValues Do
				AttributesDescription.Insert(EmunValueKeyValue.Key, New Structure("name", EmunValueKeyValue.Value));
			EndDo;

		Else

			If MetadataObject.Property("Attributes") Then
				For Each AttributeKeyValue In MetadataObject.Attributes Do
					AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, True,
						TypesMap);
				EndDo;
			EndIf;
			If MetadataObject.Property("StandardAttributes") Then
				For Each AttributeKeyValue In MetadataObject.StandardAttributes Do
					AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, False,
						TypesMap);
				EndDo;
			EndIf;
			If MetadataObject.Property("Predefined") Then
				
				//If MetadataObject(FullName) = "ChartOfAccounts" Then
				//	
				//	Query = New Query(
				//	"SELECT
				//	|	ChartOfAccounts.Code AS Code,
				//	|	ChartOfAccounts.PredefinedDataName AS Name
				//	|FROM
				//	|	&Table AS ChartOfAccounts
				//	|WHERE
				//	|	ChartOfAccounts.Predefined");				
				//						
				//	Query.Text = StrReplace(Query.Text, "&Table", FullName);
				//	
				//	Selection = Query.Execute().StartChoosing();
				//	
				//	While Selection.Next() Do 
				//		PredefinedDescription.Insert(Selection.Name, StrTemplate("%1 (%2)", Selection.Name, Selection.Code));
				//	EndDo;
				//	
				//Else				
				For Each NameKeyValue In MetadataObject.Predefined Do
					PredefinedDescription.Insert(NameKeyValue.Key, New Structure("name, ref", NameKeyValue.Key, ""));
				EndDo;
				
				//EndIf;

			EndIf;

			If MetadataObject.Property("Dimensions") Then

				For Each AttributeKeyValue In MetadataObject.Dimensions Do
					AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, True,
						TypesMap);
				EndDo;
				For Each AttributeKeyValue In MetadataObject.Resources Do
					AddAttributeDescriptionForMonacoEditor(AttributesDescription, AttributeKeyValue.Value, True,
						TypesMap);
				EndDo;
				
				//FillRegisterType(AdditionalProperties, MetadataObject, FullName);				

			EndIf;

			If MetadataObject.Property("TabularSections") Then

				For Each TabularSectionKeyValue In MetadataObject.TabularSections Do

					TabularSection = TabularSectionKeyValue.Value;
					AttributesDescription.Insert(TabularSection.Name, New Structure("name", "TS: "
						+ TabularSection.Synonym));

					TabularSectionDescription = New Structure;

					If TabularSection.Property("StandardAttributes") Then
						For Each TabularSectionAttribute In TabularSection.StandardAttributes Do
							TabularSectionDescription.Insert(TabularSectionAttribute.Value.Name,
								TabularSectionAttribute.Value.Synonym);
						EndDo;
					EndIf;

					If TabularSection.Property("Attributes") Then
						For Each TabularSectionAttribute In TabularSection.Attributes Do
							AddAttributeDescriptionForMonacoEditor(TabularSectionDescription,
								TabularSectionAttribute.Value, True, TypesMap);
						EndDo;
					EndIf;

					TabularSectionsDescription.Insert(TabularSection.Name, TabularSectionDescription);

				EndDo;

			EndIf;
			If MetadataObject.Property("StandardTabularSections") Then

				For Each TabularSectionKeyValue In MetadataObject.StandardTabularSections Do

					TabularSection = TabularSectionKeyValue.Value;
					AttributesDescription.Insert(TabularSection.Name, New Structure("name", "TS: "
						+ TabularSection.Synonym));

					TabularSectionDescription = New Structure;

					If TabularSection.Property("StandardAttributes") Then
						For Each TabularSectionAttribute In TabularSection.StandardAttributes Do
							TabularSectionDescription.Insert(TabularSectionAttribute.Value.Name,
								TabularSectionAttribute.Value.Synonym);
						EndDo;
					EndIf;

					If TabularSection.Property("Attributes") Then
						For Each TabularSectionAttribute In TabularSection.Attributes Do
							AddAttributeDescriptionForMonacoEditor(TabularSectionDescription,
								TabularSectionAttribute.Value, True, TypesMap);
						EndDo;
					EndIf;

					TabularSectionsDescription.Insert(TabularSection.Name, TabularSectionDescription);

				EndDo;

			EndIf;

		EndIf;

		ObjectStructure = New Structure;
		ObjectStructure.Insert("properties", AttributesDescription);

		For Each Iterator In AdditionalProperties Do
			ObjectStructure.Insert(Iterator.Key, Iterator.Value);
		EndDo;

		If 0 < ResourcesDescription.Count() Then
			ObjectStructure.Insert("resources", ResourcesDescription);
		EndIf;

		If 0 < PredefinedDescription.Count() Then
			ObjectStructure.Insert("predefined", PredefinedDescription);
		EndIf;

		If 0 < TabularSectionsDescription.Count() Then
			ObjectStructure.Insert("tabulars", TabularSectionsDescription);
		EndIf;

		CollectionDescription.Insert(MetadataObject.Name, ObjectStructure);

	EndDo;

	Return CollectionDescription;

EndFunction

Function GetMetadataObjectsListFromCollectionForMonacoEditor(Collection)

	CollectionDescription = New Structure;

	For Each KeyValue In Collection Do
		CollectionDescription.Insert(KeyValue.Key, New Structure);
	EndDo;

	Return CollectionDescription;

EndFunction

Function ConfigurationReferenceTypesMap()
	Map = UT_ApplicationParameters["ConfigurationReferenceTypesMap"];
	If Map <> Undefined Then
		Return Map;
	EndIf;

	TypesMap = UT_CodeEditorServerCall.ReferenceTypesMap();
	UT_ApplicationParameters.Insert("ConfigurationReferenceTypesMap", TypesMap);

	Return TypesMap;
EndFunction

Function ConfigurationMetadataDescriptionForMonacoEditor()
	MetadataDescription = UT_ApplicationParameters["MetadataDescriptionForMonacoEditor"];
	If MetadataDescription <> Undefined Then
		Return MetadataDescription;
	EndIf;

	MetadataDescriptionURL = UT_ApplicationParameters["ConfigurationMetadataDescriptionAdress"];
	If Not IsTempStorageURL(MetadataDescriptionURL) Then
		MetadataDescriptionURL = UT_CommonServerCall.ConfigurationMetadataDescriptionAdress();
		UT_ApplicationParameters.Insert("ConfigurationMetadataDescriptionAdress", MetadataDescriptionURL);
	EndIf;
	ConfigurationMetadata = GetFromTempStorage(MetadataDescriptionURL);

	TypesMap = ConfigurationMetadata.ReferenceTypesMap;

	MetadataCollection = New Structure;
	MetadataCollection.Insert("catalogs", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.Catalogs, TypesMap));
	MetadataCollection.Insert("documents", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.Documents, TypesMap));
	MetadataCollection.Insert("infoRegs", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.InformationRegisters, TypesMap));
	MetadataCollection.Insert("accumRegs", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.AccumulationRegisters, TypesMap));
	MetadataCollection.Insert("accountRegs", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.AccountingRegisters, TypesMap));
	MetadataCollection.Insert("calcRegs", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.CalculationRegisters, TypesMap));
	MetadataCollection.Insert("dataProc", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.DataProcessors, TypesMap));
	MetadataCollection.Insert("reports", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.Reports, TypesMap));
	MetadataCollection.Insert("enums", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.Enums, TypesMap));
	MetadataCollection.Insert("commonModules", GetMetadataObjectsListFromCollectionForMonacoEditor(
		ConfigurationMetadata.CommonModules));
	MetadataCollection.Insert("сhartsOfAccounts", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.ChartsOfAccounts, TypesMap));
	MetadataCollection.Insert("businessProcesses", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.BusinessProcesses, TypesMap));
	MetadataCollection.Insert("tasks", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.Tasks, TypesMap));
	MetadataCollection.Insert("exchangePlans", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.ExchangePlans, TypesMap));
	MetadataCollection.Insert("chartsOfCharacteristicTypes", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.ChartsOfCharacteristicTypes, TypesMap));
	MetadataCollection.Insert("chartsOfCalculationTypes", DescribeMetadataObjectsCollectionForMonacoEditor(
		ConfigurationMetadata.ChartsOfCalculationTypes, TypesMap));
	MetadataCollection.Insert("constants", GetMetadataObjectsListFromCollectionForMonacoEditor(
		ConfigurationMetadata.Constants));

	UT_ApplicationParameters.Insert("MetadataDescriptionForMonacoEditor", UT_CommonClientServer.CopyStructure(
		MetadataCollection));
	UT_ApplicationParameters.Insert("ConfigurationReferenceTypesMap", TypesMap);

	Return MetadataCollection;
EndFunction

Function MapOfMonacoEditorUpdatedMetadataObjectsAndMetadataUpdateEventParameters()
	Map = New Structure;
	Map.Insert("справочники", "catalogs.items");
	Map.Insert("catalogs", "catalogs.items");
	Map.Insert("документы", "documents.items");
	Map.Insert("documents", "documents.items");
	Map.Insert("регистрысведений", "infoRegs.items");
	Map.Insert("informationregisters", "infoRegs.items");
	Map.Insert("регистрынакопления", "accumRegs.items");
	Map.Insert("accumulationregisters", "accumRegs.items");
	Map.Insert("регистрыбухгалтерии", "accountRegs.items");
	Map.Insert("accountingregisters", "accountRegs.items");
	Map.Insert("регистрырасчета", "calcRegs.items");
	Map.Insert("calculationregisters", "calcRegs.items");
	Map.Insert("обработки", "dataProc.items");
	Map.Insert("dataprocessors", "dataProc.items");
	Map.Insert("отчеты", "reports.items");
	Map.Insert("reports", "reports.items");
	Map.Insert("перечисления", "enums.items");
	Map.Insert("enums", "enums.items");
	Map.Insert("планысчетов", "сhartsOfAccounts.items");
	Map.Insert("chartsofaccounts", "сhartsOfAccounts.items");
	Map.Insert("бизнеспроцессы", "businessProcesses.items");
	Map.Insert("businessprocesses", "businessProcesses.items");
	Map.Insert("задачи", "tasks.items");
	Map.Insert("tasks", "tasks.items");
	Map.Insert("планыобмена", "exchangePlans.items");
	Map.Insert("exchangeplans", "exchangePlans.items");
	Map.Insert("планывидовхарактеристик", "chartsOfCharacteristicTypes.items");
	Map.Insert("chartsofcharacteristictypes", "chartsOfCharacteristicTypes.items");
	Map.Insert("планывидоврасчета", "chartsOfCalculationTypes.items");
	Map.Insert("chartsofcalculationtypes", "chartsOfCalculationTypes.items");
	Map.Insert("константы", "constants.items");
	Map.Insert("constants", "constants.items");
	Map.Insert("module", "commonModules.items");

	Return Map;
EndFunction

#EndRegion
Procedure SaveEditorLibraryToDisk(LibraryURL, EditorType, CompletionNotifyDescription)
	LibrarySavingDirectory=EditorSaveDirectory(EditorType);
	EditorFile=New File(LibrarySavingDirectory);

	AdditionalParameters= New Structure;
	AdditionalParameters.Insert("LibraryURL", LibraryURL);
	AdditionalParameters.Insert("LibrarySavingDirectory", LibrarySavingDirectory);
	AdditionalParameters.Insert("EditorType", EditorType);
	AdditionalParameters.Insert("CompletionNotifyDescription", CompletionNotifyDescription);
	EditorFile.BeginCheckingExistence(
		New NotifyDescription("SaveEditorLibraryToDiskEndCheckOfLibraryExistOnDisk", ThisObject, AdditionalParameters));
EndProcedure

Procedure SaveEditorLibraryWriteBeginWritingNextFile(AdditionalParameters)
	SavedFilesArray = AdditionalParameters.SavedFilesArray;
	LibrarySavingDirectory = AdditionalParameters.LibrarySavingDirectory;
	LibraryFilesMap = AdditionalParameters.LibraryFilesMap;
	IsNotSaved = False;
	For Each KeyValue In LibraryFilesMap Do
		If SavedFilesArray.Find(KeyValue.Key) <> Undefined Then
			Continue;
		EndIf;
		IsNotSaved = True;

		FileName=LibrarySavingDirectory + GetPathSeparator() + KeyValue.Key;
		AdditionalParameters.Insert("CurrentFileKey", KeyValue.Key);

		If TypeOf(KeyValue.Value) = Type("TextDocument") Then
			CompletionNotify = New NotifyDescription("SaveEditorLibraryWriteBeginWritingNextFileOfTextDocumentEnd",
				ThisObject, AdditionalParameters);
		Else
			CompletionNotify = New NotifyDescription("SaveEditorLibraryWriteBeginWritingNextFileEnd", ThisObject,
				AdditionalParameters);
		EndIf;
		If TypeOf(KeyValue.Value) = Type("TextDocument") Then
			KeyValue.Value.BeginWriting(CompletionNotify, FileName);
		ElsIf TypeOf(KeyValue.Value) = Type("BinaryData") Then
			KeyValue.Value.BeginWrite(CompletionNotify, FileName);
		Else
			KeyValue.Value.BeginWriting(CompletionNotify, FileName);
		EndIf;
		Break;
	EndDo;

	If Not IsNotSaved Then
		ExecuteNotifyProcessing(AdditionalParameters.CompletionNotifyDescription, True);
	EndIf;
EndProcedure

Function EditorSaveDirectory(EditorType)
	FileVariablesStructure=UT_CommonClient.SessionFileVariablesStructure();
	If Not FileVariablesStructure.Property("TempFilesDirectory") Then
		Return "";
	EndIf;

	Return FileVariablesStructure.TempFilesDirectory + "tools_ui_1c_int" + GetPathSeparator() + Format(
		UT_CommonClientServer.Version(), "NG=0;") + GetPathSeparator() + EditorType;
EndFunction

Function AceEditorFileNameForLanguage(Language = "bsl") Export
	Return EditorSaveDirectory(UT_CodeEditorClientServer.CodeEditorVariants().Ace) + GetPathSeparator() + Language
		+ ".html";
EndFunction

Function AceCodeEditorHTMLText(LibrarySavingDirectory, Language)

	TextAce=LibrarySavingDirectory + GetPathSeparator() + "ace" + GetPathSeparator() + "ace.js";
	TextLT=LibrarySavingDirectory + GetPathSeparator() + "ace" + GetPathSeparator() + "ext-language_tools.js";

	CurrentLanguage=Lower(Language);
	If CurrentLanguage = "bsl" Then
		CurrentLanguage="_1c";
	EndIf;
	HTMLText= "<!DOCTYPE html>
			  |<html lang=""ru"">
			  |<head>
			  |<title>ACE in Action</title>
			  |<style type=""text/css"" media=""screen"">
			  |    #editor { 
			  |        position: absolute;
			  |        top: 0;
			  |        right: 0;
			  |        bottom: 0;
			  |        left: 0;
			  |    }
			  |</style>
			  |</head>
			  |<body>
			  |
			  |<div id=""editor""></div>
			  |    
			  |<script src=""file://" + TextAce + """ type=""text/javascript"" charset=""utf-8""></script>
												  |<script src=""file://" + TextLT + """ type=""text/javascript"" charset=""utf-8""></script>
																					 |<script>
																					 |    // trigger extension
																					 |    ace.require(""ace/ext/language_tools"");
																					 |    var editor = ace.edit(""editor"");
																					 |    editor.session.setMode(""ace/mode/"
		+ CurrentLanguage + """);
							|    editor.setTheme(""ace/theme/ones"");
							|    // enable autocompletion and snippets
							|    editor.setOptions({
							|        selectionStyle: 'line',
							|        highlightSelectedWord: true,
							|        showLineNumbers: true,
							|        enableBasicAutocompletion: true,
							|        enableSnippets: true,
							|        enableLiveAutocompletion: true
							|    });
							|
							|	editor.setHighlightSelectedWord(true);
							|
							|	function setSelection(startRow, startColumn, endRow, endColumn) {
							|		editor.clearSelection();
							|		var rangeEditor = new ace.Range(startRow, startColumn, endRow, endColumn);
							|       var selection = editor.getSelection();
							|       selection.setSelectionRange(rangeEditor, false);
							|		editor.centerSelection();
							|
							|	}
							|
							|</script>
							|
							|</body>
							|</html>";

	Return HTMLText;
EndFunction

Procedure AddToSavingFilesTextDocumentForAceCodeEditorLanguage(LibraryFilesMap, LibrarySavingDirectory, Language)
	Text= New TextDocument;
	Text.SetText(AceCodeEditorHTMLText(LibrarySavingDirectory, Language));

	LibraryFilesMap.Insert(Language + ".html", Text);

EndProcedure
#EndRegion