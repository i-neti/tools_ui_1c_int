#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	QueryConsoleUsageOption = Parameters.QueryConsoleUsageOption;
	PathToExternalQueryConsole = Parameters.PathToExternalQueryConsole;
	
	Items.PathToExternalQueryConsole.Enabled = (QueryConsoleUsageOption = 2);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueryConsoleUsageOptionOnChange(Item)
	
	Items.PathToExternalQueryConsole.Enabled = (QueryConsoleUsageOption = 2);
	
EndProcedure

&AtClient
Procedure PathToExternalQueryConsoleStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.CheckFileExistence = True;
	Dialog.Filter = NStr("ru='Внешние обработки (*.epf)|*.epf'; en = 'External data processors (*.epf)|*.epf'");
	Dialog.Show(New NotifyDescription("PathToExternalQueryConsoleStartChoiceCompletion", ThisForm,
		New Structure("Dialog", Dialog)));

EndProcedure

&AtClient
Procedure PathToExternalQueryConsoleStartChoiceCompletion(SelectedFiles, AdditionalParameters) Export

	Dialog = AdditionalParameters.Dialog;
	If (SelectedFiles <> Undefined) Then
		PathToExternalQueryConsole = Dialog.FullFileName;
	EndIf;

EndProcedure

&AtClient
Procedure Confirm(Command)

	QueryConsoleSettings = New Structure;
	QueryConsoleSettings.Insert("QueryConsoleUsageOption", QueryConsoleUsageOption);
	QueryConsoleSettings.Insert("PathToExternalQueryConsole", PathToExternalQueryConsole);

	Notify("QueryConsoleSettingsFormClosed", QueryConsoleSettings);

	Close();

EndProcedure

#EndRegion