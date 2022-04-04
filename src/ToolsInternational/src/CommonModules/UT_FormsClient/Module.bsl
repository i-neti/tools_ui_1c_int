#Region UT_GroupProcessingCatalogsAndDocuments

// Gets a structure to indicate the progress of the loop.
//
// Parameters:
//  NumberOfPasses - Number - maximum counter value;
//  ProcessRepresentation - String, "Done" - the display name of the process;
//  InternalCounter - Boolean, *True - use internal counter with initial value 1,
//                    otherwise, you will need to pass the value of the counter each time you call to update the indicator;
//  NumberOfUpdates - Number, *100 - total number of indicator updates;
//  OutputTime - Boolean, *True - display approximate time until the end of the process;
//  AllowBreaking - Boolean, *True - allows the user to break the process.
//
// Return value:
//  Structure - which will then need to be passed to the method ProcessIndicator.
//
&AtClient
Function GetProcessIndicator(NumberOfPasses, ProcessRepresentation = "Done", InternalCounter = True,
	NumberOfUpdates = 100, OutputTime = True, AllowBreaking = True) Export

	Indicator = New Structure;
	Indicator.Insert("NumberOfPasses", NumberOfPasses);
	Indicator.Insert("ProcessStartDate", CurrentDate());
	Indicator.Insert("ProcessRepresentation", ProcessRepresentation);
	Indicator.Insert("OutputTime", OutputTime);
	Indicator.Insert("AllowBreaking", AllowBreaking);
	Indicator.Insert("InternalCounter", InternalCounter);
	Indicator.Insert("Step", NumberOfPasses / NumberOfUpdates);
	Indicator.Insert("NextCounter", 0);
	Indicator.Insert("Counter", 0);
	Return Indicator;

EndFunction // GetProcessIndicator()

// Stores form attribute values.
//
// Parameters:
//  None.
//
&AtClient
Procedure SaveSetting(Form, mSetting) Export

	If IsBlankString(Form.CurrentSettingRepresentation) Then
		ShowMessageBox( ,
			Nstr("ru = 'Задайте имя новой настройки для сохранения или выберите существующую настройку для перезаписи.';en = 'Specify a name for the new setting to save, or select an existing setting to overwrite.'"));
	EndIf;

	NewSetting = New Structure;
	NewSetting.Insert("Processing", Form.CurrentSettingRepresentation);
	NewSetting.Insert("Other", New Structure);

	For Each AttributeSetting In mSetting Do
		Execute ("NewSetting.Other.Insert(String(AttributeSetting.Key), " + String(AttributeSetting.Key)
			+ ");");
	EndDo;

	AvailableDataProcessors = Form.FormOwner.AvailableDataProcessors;
	CurrentAvailableSetting = Undefined;
	For Each CurrentAvailableSetting In AvailableDataProcessors.GetItems() Do
		If CurrentAvailableSetting.GetID() = Form.Parent Then
			Break;
		EndIf;
	EndDo;

	If Form.CurrentSetting = Undefined Or Not Form.CurrentSetting.Processing = Form.CurrentSettingRepresentation Then
		If CurrentAvailableSetting <> Undefined Then
			NewLine = CurrentAvailableSetting.GetItems().Add();
			NewLine.Processing = Form.CurrentSettingRepresentation;
			NewLine.Setting.Add(NewSetting);

			Form.FormOwner.Items.AvailableDataProcessors.CurrentLine = NewLine.GetID();
		EndIf;
	EndIf;

	If CurrentAvailableSetting <> Undefined And Form.CurrentLine > -1 Then
		For Each CurrentSettingItem In CurrentAvailableSetting.GetItems() Do
			If CurrentSettingItem.GetID() = Form.CurrentLine Then
				Break;
			EndIf;
		EndDo;

		If CurrentSettingItem.Setting.Count() = 0 Then
			CurrentSettingItem.Setting.Add(NewSetting);
		Else
			CurrentSettingItem.Setting[0].Value = NewSetting;
		EndIf;
	EndIf;

	Form.CurrentSetting = NewSetting;
	Form.Modified = False;
	
EndProcedure // SaveSetting()

#EndRegion