
&AtClient
Procedure ExecuteAlgorithm(Command)
	
	AlgorithmsArray = Items.List.SelectedRows;
	
		For Each Algorithm In  AlgorithmsArray Do
		Error = False;
		ErrorMessage = "";

		If AlgorithmExecutedAtClient(Algorithm) Then
			UT_CommonClient.ExecuteAlgorithm(Algorithm, , Error, ErrorMessage);
		Else
			UT_CommonServerCall.ExecuteAlgorithm(Algorithm, , Error, ErrorMessage);
		EndIf;
		If Error Then
			UT_CommonClientServer.MessageToUser(ErrorMessage);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Function AlgorithmExecutedAtClient(Algorithm)

	Return Algorithm.AtClient;

EndFunction