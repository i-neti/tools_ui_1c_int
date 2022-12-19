
&AtClient
Procedure ExecuteAlgorithm(Command)
	AlgorithmsArray = Items.List.SelectedRows;
	
		For Each Algorithm In  AlgorithmsArray Do
		Error = False;
		ErrorMessage = "";
		TransmittedStructure = New Structure;

		If AlgorithmExecutedAtClient(Algorithm) Then
			ExecuteAlgorithmAtClient(Algorithm,TransmittedStructure);
		Else
			UT_AlgorithmsServerCall.ExecuteAlgorithm(Algorithm);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function AlgorithmExecutedAtClient(Algorithm)

	Return Algorithm.AtClient;

EndFunction

&AtClient
Procedure ExecuteAlgorithmAtClient(Algorithm, TransmittedStructure)
	If Not ValueIsFilled(TrimAll(Algorithm.AlgorithmText)) Then
		Return;
	EndIf;

	ExecutionContext =  UT_AlgorithmsServerCall.GetParameters(Algorithm);

	ExecutionResult = UT_CodeEditorClientServer.ExecuteAlgorithm(Algorithm.AlgorithmText, ExecutionContext);

КонецПроцедуры