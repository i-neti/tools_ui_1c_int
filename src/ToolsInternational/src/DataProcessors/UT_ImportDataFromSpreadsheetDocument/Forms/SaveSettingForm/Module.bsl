////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENT HANDLERS

// OK button handler
//
&AtClient
Procedure OK(Command)
	Close(Items.SettingsList.CurrentData);
EndProcedure

// Cancel button handler
//
&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

// Delete button handler
//
&AtClient
Procedure Delete(Command)

	CurrentData = Items.SettingsList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If NewRowAdded And CurrentData = SettingsList[SettingsList.Count() - 1] Then
		NewRowAdded = False;
	EndIf;

	If SettingsList.Count() = 1 Then
		NewRowAdded = True;
		CurrentData.Presentation = "";
		CurrentData.Check = False;
	Else
		SettingsList.Delete(CurrentData);
	EndIf;

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If SettingsList.Count() = 0 Then
		CurrentData = SettingsList.Add();
		CurrentData.Presentation = NStr("ru = 'Основная'; en = 'Main'");
		CurrentData.Value.Add(NStr("ru = 'Новая'; en = 'New'"));
		NewRowAdded = True;
	Else
		NewRowAdded = False;
		CurrentData = SettingsList[0];
	EndIf;

EndProcedure

&AtClient
Procedure SettingDescriptionTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	Found = False;

	For Each CurrentData In SettingsList Do
		If CurrentData.Presentation = Text Then
			Found = True;
			Break;
		EndIf;
	EndDo;

	If Not Found Then

		If Not NewRowAdded Then
			CurrentData = SettingsList.Add();
			NewRowAdded = True;
		Else
			CurrentData = SettingsList[SettingsList.Count() - 1];
		EndIf;

		CurrentData.Presentation = Text;
	EndIf;

	Items.SettingsList.CurrentRow = CurrentData;
EndProcedure

&AtClient
Procedure UseOnOpenOnChange(Item)
	CurrentData = Items.SettingsList.CurrentData;
	If CurrentData.Check Then
		For Each ListItem In SettingsList Do
			If ListItem.Check And Not ListItem = CurrentData Then
				ListItem.Check = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure SettingsListCheckOnChange(Item)
	CurrentData = Items.SettingsList.CurrentData;
	If CurrentData.Check Then
		For Each ListItem In SettingsList Do
			If ListItem.Check And Not ListItem = CurrentData Then
				ListItem.Check = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure