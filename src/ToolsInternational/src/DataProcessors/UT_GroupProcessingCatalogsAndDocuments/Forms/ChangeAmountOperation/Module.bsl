//Sign of using settings
&AtClient
Var mUseSettings Export;

//Types of objects for which processing can be used.
//To default for everyone.
&AtClient
Var mTypesOfProcessedObjects Export;

&AtClient
Var mSetting;

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

&AtServer
Function ChangeTheValueOfTheAmount(Val CurrentValue)
	//SetValue
	If TypeOfActionOnTheAmount = 0 Then
		Return ActionParameter;
		
		//Increase by the amount
	ElsIf TypeOfActionOnTheAmount = 1 Then
		Return CurrentValue + ActionParameter;
		
		//Increase by %
	ElsIf TypeOfActionOnTheAmount = 2 Then
		Return CurrentValue * (100 + ActionParameter) / 100;
		
		//Reduce by the amount
	ElsIf TypeOfActionOnTheAmount = 3 Then
		Return CurrentValue - ActionParameter;
		
		//Reduce by %
	ElsIf TypeOfActionOnTheAmount = 4 Then
		Return CurrentValue * (100 - ActionParameter) / 100;
	EndIf;
EndFunction

// Performs object processing.
//
// Parameters:
//  ProcessedObject                 - processed object.
//  SequenceNumberObject - serial number of the processed object.
//
&AtServer
Procedure ProcessObject(Reference, SequenceNumberObject, ParametersWriteObjects)

	ProcessedObject = Reference.GetObject();
	If ProcessTabularParts Then
		RowTP = ProcessedObject[FoundObjectsTP[SequenceNumberObject].Т_ТЧ][FoundObjectsTP[SequenceNumberObject].T_LineNumber
			- 1];
	EndIf;

	For Each Attribute In Attributes Do
		If Attribute.Attribute = CurrentAttribute Then
			ProcessedObject[Attribute.Attribute] = ChangeTheValueOfTheAmount(ProcessedObject[Attribute.Attribute]);
		ElsIf Attribute.Attribute + "_ТЧ_12345" = CurrentAttribute Then
			RowTP[Attribute.Attribute] = ChangeTheValueOfTheAmount(RowTP[Attribute.Attribute]);
		EndIf;
	EndDo;
		
//	ProcessedObject.Write();
	If UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects) Then
		UT_CommonClientServer.MessageToUser(StrTemplate(Nstr("ru = 'Объект %1 УСПЕХ!!!';en = 'Object %1 SUCCESS!!!'"), ProcessedObject));
	EndIf;

EndProcedure // ProcessObject()

// Performs object processing.
//
// Parameters:
//  None.
//
&AtClient
Function ExecuteProcessing(ParametersWriteObjects) Export

	Indicator = UT_FormsClient.GetProcessIndicator((FoundObjects.Count()));
	For IndexOf = 0 To FoundObjects.Count() - 1 Do
		UT_FormsClient.ProcessIndicator(Indicator, IndexOf + 1);

		RowFound = FoundObjectsTP.Get(IndexOf);

		If RowFound.StartChoosing Then//

			ProcessObject(RowFound.Object, IndexOf, ParametersWriteObjects);
		EndIf;
	EndDo;

	If IndexOf > 0 Then
		//NotifyChanged(Type(ОбъектПоиска.Type + "Reference." + ОбъектПоиска.Name));
	EndIf;

	Return IndexOf;
EndFunction // ExecuteProcessing()

// Restores saved form attribute values.
//
// Parameters:
//  None.
//
&AtClient
Procedure DownloadSettings() Export

	UT_FormsClient.DownloadSettings(ThisForm, mSetting);

EndProcedure //DownloadSettings()

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtClient
Procedure OnOpen(Cancel)
	
	If mUseSettings Then
		UT_FormsClient.SetNameSettings(ThisForm);
		DownloadSettings();
	Else
		Items.CurrentSetting.Enabled = False;
		Items.SaveSettings.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UT_FormsServer.FillSettingByParametersForm(ThisForm);	

	//If Parameters.Property("ОбъектПоиска") Then
	//	ОбъектПоиска = Parameters.ОбъектПоиска;
	//EndIf;

	If Parameters.Property("ProcessTabularParts") Then
		ProcessTabularParts=Parameters.ProcessTabularParts;
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS CALLED FROM FORM ELEMENTS

&AtClient
Procedure ExecuteCommand(Command)
	ProcessedObjects = ExecuteProcessing(UT_CommonClientServer.FormWriteSettings(
		ThisObject.FormOwner));

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

	DownloadSettings();

EndProcedure

&AtClient
Procedure CurrentSettingOnChange(Item)
	ThisForm.Modified = True;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// // INITIALIZING MODULAR VARIABLES

mUseSettings = True;

////Attributes settings and defaults.
mSetting = New Structure("");

//mSetting.<Name attribute> = <Value attribute>;

mTypesOfProcessedObjects = "Document";