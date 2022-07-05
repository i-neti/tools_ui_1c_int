//Sign of using settings
&AtClient
Var mUseSettings Export;

//Types of objects for which processing can be used.
//To default for everyone.
&AtClient
Var mTypesOfProcessedObjects Export;

&AtClient
Var mSetting;

&AtServer
Var FoundObjectsValueTable;

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Performs object processing.
//
// Parameters:
//  ProcessedObject                 - processed object.
//  SequenceNumberObject - serial number of the processed object.
//
&AtServer
Procedure ProcessObject(Reference, SequenceNumberObject, ParametersWriteObjects)
	//RowTP=
	//
	ProcessedObject = Reference.GetObject();
	If ProcessTabularParts Then
		RowTP=ProcessedObject[FoundObjects[SequenceNumberObject].T_TP][FoundObjects[SequenceNumberObject].T_LineNumber
			- 1];
	EndIf;

	For Each Attribute In Attributes Do
		If Attribute.Choose Then
			If Attribute.AttributeTP Then
				RowTP[Attribute.Attribute] = Attribute.Value;
			Else
				ProcessedObject[Attribute.Attribute] = Attribute.Value;
			EndIf;
		EndIf;
	EndDo;

//		ProcessedObject.Write();
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

	Indicator = UT_FormsClient.GetProcessIndicator(FoundObjects.Count());
	For IndexOf = 0 To FoundObjects.Count() - 1 Do
		UT_FormsClient.ProcessIndicator(Indicator, IndexOf + 1);

		RowFoundObjects = FoundObjects.Get(IndexOf);

		If RowFoundObjects.Choose Then//

			ProcessObject(RowFoundObjects.Object, IndexOf, ParametersWriteObjects);
		EndIf;
	EndDo;

	If IndexOf > 0 Then
		//NotifyChanged(Type(SearchObject.Type + "Reference." + SearchObject.Name));
	EndIf;

	Return IndexOf;
EndFunction // ExecuteProcessing()

&AtServer
Function GetArrayOfAttributes()
	ArrayAttributes = New Array;
	For Each Row In Attributes Do
		If Not Row.Choose Then
			Continue;
		EndIf;

		StructureAttribute = New Structure;
		StructureAttribute.Insert("Choose", Row.Choose);
		StructureAttribute.Insert("Attribute", Row.Attribute);
		StructureAttribute.Insert("ID", Row.ID);
		StructureAttribute.Insert("Type", Row.Type);
		StructureAttribute.Insert("Value", Row.Value);

		ArrayAttributes.Add(StructureAttribute);
	EndDo;

	Return ArrayAttributes;
EndFunction

&AtServer
Procedure LoadAttributesFromArray(ArrayAttributes)
	TableAttributes = FormAttributeToValue("Attributes");
	
	//Clean up existing installations before installation
	For Each RowAttribute In TableAttributes Do
		RowAttribute.Choose = False;
		RowAttribute.Value = RowAttribute.Type.AdjustValue();
	EndDo;

	For Each Row In ArrayAttributes Do
		If Not Row.Choose Then
			Continue;
		EndIf;

		SearchStructure = New Structure;
		SearchStructure.Insert("Attribute", Row.Attribute);

		ArrayString = TableAttributes.FindRows(SearchStructure);
		If ArrayString.Count() = 0 Then
			Continue;
		EndIf;

		ТекСтр = ArrayString[0];
		FillPropertyValues(ТекСтр, Row);
	EndDo;

	ValueToFormAttribute(TableAttributes, "Attributes");
EndProcedure

// Restores saved form attribute values.
//
// Parameters:
//  None.
//
&AtClient
Procedure DownloadSettings() Export

	If Items.CurrentSetting.ChoiceList.Count() = 0 Then
		UT_FormsClient.SetNameSettings(ThisForm, Nstr("ru = 'Новая настройка';en = 'New setting'"));
	Else
		If Not CurrentSetting.Other = Undefined Then
			mSetting = CurrentSetting.Other;
		EndIf;
	EndIf;

	AttributesForSaving = Undefined;

	For Each AttributeSetting In mSetting Do
		//@skip-warning
		Value = mSetting[AttributeSetting.Key];
		Execute (String(AttributeSetting.Key) + " = Value;");
	EndDo;

	If AttributesForSaving <> Undefined And AttributesForSaving.Count() Then
		LoadAttributesFromArray(AttributesForSaving);
	EndIf;

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
	UT_FormsServer.FillSettingByParametersForm_ProcessTabularParts(ThisForm);
	UT_FormsServer.FillSettingByParametersForm_TableAttributes(ThisForm);
	If Parameters.Property("FoundObjectsTP") Then
		FoundObjectsValueTable = Parameters.FoundObjectsTP.Unload();
		FoundObjects.Load(FoundObjectsValueTable);
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
	UT_FormsClient.SetNameSettings(ThisForm);
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
		UT_FormsClient.SetNameSettings(ThisForm);
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

&AtClient
Procedure CooseAll(Command)
	SelectItems(True);
EndProcedure

&AtClient
Procedure CancelChoice(Command)
	SelectItems(False);
EndProcedure

&AtServer
Procedure SelectItems(Selection)
	For Each Row In Attributes Do
		Row.Choose = Selection;
	EndDo;
EndProcedure

&AtClient
Procedure AttributesValueClearing(Item, StandardProcessing)
	Items.AttributesValue.ChooseType = True;
EndProcedure

&AtClient
Procedure AttributesValueOnChange(Item)
	Items.Attributes.CurrentData.Choose = True;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INITIALIZING MODULAR VARIABLES

mUseSettings = True;

//Attributes settings and defaults.
mSetting = New Structure("AttributesForSaving");

//mSetting.<Name attribute> = <Value attribute>;

mTypesOfProcessedObjects = "Catalog,Document";