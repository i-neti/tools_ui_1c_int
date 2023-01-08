#Region FormItemsEventHandlers
&AtClient
Procedure FixedSettingsFilterSelection(Item, RowSelected, Field, StandardProcessing)
	IF Field = Items.FixedSettingsFilterRightValue Then
		ShowValue( , SettingsComposer.FixedSettings.Filter.GetObjectByID(
			RowSelected).RightValue);
	EndIf;
EndProcedure

&AtClient
Procedure SettingsFilterSelection(Item, RowSelected, Field, StandardProcessing)
	If Field = Items.SettingsFilterRightValue Then
		ShowValue( , SettingsComposer.Settings.Filter.GetObjectByID(RowSelected).RightValue);
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled("" + Parameters.FixedSettings.Filter) Then
		Presentation = "1";
	Else
		Presentation = "0";
	EndIf;
	Items.FixedSettings.Title = Items.FixedSettings.Title + "(" + Presentation + ")";
	If ValueIsFilled("" + Parameters.Settings.Filter) Then
		Presentation = "1";
	Else
		Presentation = "0";
	EndIf;
	Items.StandartSettings.Title = Items.StandartSettings.Title + "(" + Presentation + ")";

EndProcedure
#EndRegion