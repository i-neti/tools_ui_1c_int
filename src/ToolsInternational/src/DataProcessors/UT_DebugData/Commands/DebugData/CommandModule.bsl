&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure;
	OpenForm("DataProcessor.UT_DebugData.Form", FormParameters, CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
EndProcedure