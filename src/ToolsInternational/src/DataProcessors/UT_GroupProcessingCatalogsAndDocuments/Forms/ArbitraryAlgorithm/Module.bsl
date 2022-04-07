//Types of objects for which processing can be used.
//To default for everyone.
&AtClient
Var mTypesOfProcessedObjects Export;

&AtClient
Var mSetting;

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Performs object processing.
//
// Parameters:
//  ProcessedObject                 - processed object.
//  SequenceNumberObject - serial number of the processed object.
//
&AtServer
Procedure ProcessObject(Reference, SequenceNumberObject, TextAlgorithm)

	Try
		ProcessedObject = Reference.GetObject();
		If ProcessTabularParts Then
			//@skip-warning
			Line_TP = ProcessedObject[FoundObjects[SequenceNumberObject].T_TP][FoundObjects[SequenceNumberObject].T_LineNumber - 1];
		EndIf;

		Execute (TextAlgorithm);
	Except
		Message(ErrorDescription());
	EndTry;

EndProcedure // ProcessObject()

// Performs object processing.
//
// Parameters:
//  None.
//
&AtClient
Function ExecuteProcessing() Export
	If IsOpen() Then
		ArbitraryAlgorithmText = UT_CodeEditorClient.EditorCodeText(ThisObject, "Editor");
	EndIf;
	Indicator = UT_FormsClient.GetProcessIndicator(FoundObjects.Count());
	For IndexOf = 0 To FoundObjects.Count() - 1 Do
		UT_FormsClient.ProcessIndicator(Indicator, IndexOf + 1);

		RowFoundObjects = FoundObjects.Get(IndexOf);

		If RowFoundObjects.StartChoosing Then//

			ProcessObject(RowFoundObjects.Object, IndexOf, ArbitraryAlgorithmText);
		EndIf;

	EndDo;

	If IndexOf > 0 Then
		//NotifyChanged(Type(ОбъектПоиска.Type + "Reference." + ОбъектПоиска.Name));
	EndIf;

	Return IndexOf;
EndFunction // FoundObjects()

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtClient
Procedure OnOpen(Cancel)
	If mUseSettings Then
		UT_FormsClient.SetNameSettings(ThisForm);
		UT_FormsClient.DownloadSettings(ThisForm, mSetting);
	Else
		Items.CurrentSetting.Enabled = False;
		Items.SaveSettings.Enabled = False;
	EndIf;
	
	UT_CodeEditorClient.FormOnOpen(ThisObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UT_FormsServer.FillSettingByParametersForm(ThisForm);
	UT_CodeEditorServer.FormOnCreateAtServer(ThisObject);
	UT_CodeEditorServer.CreateCodeEditorItems(ThisObject, "Editor", Items.ArbitraryAlgorithmField);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS CALLED FROM FORM ELEMENTS

&AtClient
Procedure ExecuteCommand(Command)
	
	ProcessedObjects = ExecuteProcessing();

	Message = StrTemplate(Nstr("ru = 'Обработка <%1> завершена! 
					 |Обработано объектов: %2.';en = 'Processing of <%1> completed!
					 |Objects processed: %2.'"), TrimAll(ThisForm.Title), ProcessedObjects);
	ShowMessageBox(, Message);
	
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	UT_FormsClient.SaveSetting(ThisForm, mSetting);
EndProcedure

&AtClient
Procedure CurrentSettingChoiceProcessing(Item, SelectedValue, StandardProcessing)
	StandardProcessing = False;

	If Not CurrentSetting = SelectedValue Then

		If ThisForm.Modified Then
			ShowQueryBox(New NotifyDescription("CurrentSettingChoiceProcessingEnd", ThisForm,
				New Structure("SelectedValue", SelectedValue)), Nstr("ru = 'Сохранить текущую настройку?';en = 'Save current setting?'"),
				QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			Return;
		EndIf;

		CurrentSettingChoiceProcessingFragment(SelectedValue);

	EndIf;
EndProcedure

&AtClient
Procedure CurrentSettingChoiceProcessingEnd(ResultQuestion, AdditionalParameters) Export

	SelectedValue = AdditionalParameters.SelectedValue;
	If ResultQuestion = DialogReturnCode.Yes Then
		UT_FormsClient.SaveSetting(ThisForm, mSetting);
	EndIf;

	CurrentSettingChoiceProcessingFragment(SelectedValue);

EndProcedure

&AtClient
Procedure CurrentSettingChoiceProcessingFragment(Val SelectedValue)

	CurrentSetting = SelectedValue;
	UT_FormsClient.SetNameSettings(ThisForm);

	UT_FormsClient.DownloadSettings(ThisForm, mSetting);

EndProcedure

&AtClient
Procedure ArbitraryAlgorithmTextCurrentLine(Item)
	ThisForm.Modified = True;
EndProcedure

&AtClient
Procedure CurrentSettingOnChange(Item)
	ThisForm.Modified = True;
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_EditorFieldDocumentGenerated(Item)
	UT_CodeEditorClient.HTMLEditorFieldDocumentGenerated(ThisObject, Item);
EndProcedure

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

//@skip-warning
&AtClient 
Procedure Attachable_CodeEditorInitializingCompletion() Export
	UT_CodeEditorClient.SetEditorText(ThisObject, "Editor", ArbitraryAlgorithmText);
	
	AddedContext = New Structure;
	If FoundObjects.Count()>0 Then
		AddedContext.Insert("Object", TypeOf(FoundObjects[0].Object));
	Else
		AddedContext.Insert("Object");
	EndIf;
	UT_CodeEditorClient.AddCodeEditorContext(ThisObject, "Editor", AddedContext);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INITIALIZING MODULAR VARIABLES

mUseSettings = True;

//Attributes settings and defaults.
mSetting = New Structure("ArbitraryAlgorithmText");

mTypesOfProcessedObjects = Undefined;