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

// Checks and updates the indicator. Must be called on each pass of the indicated loop.
//
// Parameters:
//  Indicator   -Structure - indicator obtained by the method GetProcessIndicator;
//  Counter     - Number - external loop counter, used when InternalCounter = False.
//
Procedure ProcessIndicator(Form, Indicator, Counter = 0) Export

	If Indicator.InternalCounter Then
		Indicator.Counter = Indicator.Counter + 1;
		Counter = Indicator.Counter;
	EndIf;
	If Indicator.AllowBreaking Then
		UserInterruptProcessing();
	EndIf;

	If Counter > Indicator.NextCounter Then
		Indicator.NextCounter = Int(Counter + Indicator.Step);
		If Indicator.OutputTime Then
			TimePassed = CurrentDate() - Indicator.ProcessStartDate;
			Remaining = TimePassed * (Indicator.NumberOfPasses / Counter - 1);
			Hours = Int(Remaining / 3600);
			Remaining = Remaining - (Hours * 3600);
			Minutes = Int(Remaining / 60);
			Seconds = Int(Int(Remaining - (Minutes * 60)));
			TimeRemaining = Format(Hours, "ND=2; NZ=00; NLZ=") + ":" + Format(Minutes, "ND=2; NZ=00; NLZ=") + ":"
				+ Format(Seconds, "ND=2; NZ=00; NLZ=");
			TextRemaining = StrTemplate(Nstr("ru = 'Осталось: ~ %1';en = 'Remaining: ~ %1'"), TimeRemaining);
		Else
			TextRemaining = "";
		EndIf;

		If Indicator.NumberOfPasses > 0 Then
			TextStates = TextRemaining;
		Else
			TextStates = "";
		EndIf;

		Status(Indicator.ProcessRepresentation, Counter / Indicator.NumberOfPasses * 100, TextStates);
	EndIf;

	If Counter = Indicator.NumberOfPasses Then
		Status(Indicator.ProcessRepresentation, 100, TextStates);
	EndIf;

EndProcedure // ProcessIndicator()
//
// Sets the value of the "CurrentSetting" attribute by the name of the setting or arbitrarily.
//
// Parameters:
//  NameSettings   - arbitrary setting name to be set.
//
Procedure SetNameSettings(Form, NameSettings = "") Export

	If IsBlankString(NameSettings) Then
		If Form.CurrentSetting = Undefined Then
			Form.CurrentSettingRepresentation = "";
		Else
			Form.CurrentSettingRepresentation = Form.CurrentSetting.Processing;
		EndIf;
	Else
		Form.CurrentSettingRepresentation = NameSettings;
	EndIf;

EndProcedure // SetNameSettings()

// Restores saved form attribute values.
//
// Parameters:
//  None.
//
Procedure DownloadSettings(Form, mSetting) Export

	If Form.Items.CurrentSetting.ChoiceList.Count() = 0 Then
		UT_FormsClient.SetNameSettings(Form, Nstr("ru = 'Новая настройка';en = 'New setting'"));
	Else
		If Not Form.CurrentSetting.Other = Undefined Then
			mSetting = Form.CurrentSetting.Other;
		EndIf;
	EndIf;

	For Each AttributeSetting In mSetting Do
		//@skip-warning
		Value = mSetting[AttributeSetting.Key];
		Execute (String(AttributeSetting.Key) + " = Value;");
	EndDo;

EndProcedure //DownloadSettings()

#EndRegion