////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS EVENT HANDLERS

// OK button handler
//
&AtClient
Procedure OK(Command)
	NotifyChoice(Items.SettingsList.CurrentData);
	//Close();
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
	If Not CurrentData = Undefined Then
		SettingsList.Delete(CurrentData);
	EndIf;

EndProcedure
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	CurrentData = SettingsList[0];

	If Not CurrentData = Undefined Then
		Items.SettingsList.CurrentRow = CurrentData;
	EndIf;

	Items.Delete.Enabled = Not SettingsList.Count() = 0;
	Items.OK.Enabled      = Not SettingsList.Count() = 0;

EndProcedure
&AtClient
Procedure SettingsListCheckOnChange(Item)
	CurrentData = Item.SettingsList.CurrentData;
	If CurrentData.Check Then
		For Each ListItem In SettingsList Do
			If ListItem.Check And Not ListItem = CurrentData Then
				ListItem.Check = False;
			EndIf;
		EndDo;
	EndIf;
EndProcedure