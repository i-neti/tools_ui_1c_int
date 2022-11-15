
// Description
// 
// Parametrs:
// 	AlgorithmName - String -  Algoritms catalog item name , searched by name 
// 	AlgorithmText - String - Attribute "AlgorithmText" value
// 	ParameterN - Value of any type
// Return value:
// 	String - Result of algorithm saving execution
Function CreatingOfAlgorithm(AlgorithmName, AlgorithmText = "", Val Parameter1 = Undefined, 
	Val Parameter2 = Undefined, Val Parameter3 = Undefined, Val Parameter4 = Undefined, 
	Val Parameter5 = Undefined, Val Parameter6 = Undefined, Val Parameter7 = Undefined, 
	Val Parameter8 = Undefined, Val Parameter9 = Undefined, Val ParametersNamesArray = Undefined)  Export
	
	AlgorithRef = Catalogs.UT_Algorithms.FindByDescription(AlgorithmName);
	If AlgorithRef = Catalogs.UT_Algorithms.EmptyRef() Then
		AlgorithmsObject = Catalogs.UT_Algorithms.CreateItem();
		AlgorithmsObject.Description = AlgorithmName;	
	Else	
		AlgorithmsObject = AlgorithRef.GetObject();
	EndIf;
	If ValueIsFilled(AlgorithmText) Then
		AlgorithmsObject.AlgorithmText = AlgorithmText;
	EndIF;
	
	ParametersStructure = New Structure;
	ParameterValue = Undefined;
	
	SetSafeMode(True);
	If TypeOf(ParametersNamesArray) <> Type("Array") Then
		ParametersNamesArray = New Array;
	EndIf;
	For Parameter = 1 To 9 Do
		VariableName = "Parameter" + Parameter;
		Execute("ParameterValue = " + VariableName);
		ParameterName = ?(ParametersNamesArray.Count() >= Parameter, ParametersNamesArray[Parameter-1],"Parameter" + Parameter); 
		If ParameterValue <> Undefined Then
			ParametersStructure.Insert(ParameterName, ParameterValue);	
		EndIf;
	EndDo;	
	SetSafeMode(False);
	
	AlgorithmsObject.Storage = New ValueStorage(ParametersStructure);
	Try
		AlgorithmsObject.Записать();
	Except
		Return NSTR("ru = 'Ошибка выполнения записи ';en = 'Writing execution error'") + ErrorDescription();
	Endtry;
	
	Return NStr("ru = 'Успешно сохранено';en = 'Successfully saved'");
EndFunction

Procedure ExecuteAlgorithm(Algorithm) Export
	If Not ValueIsFilled(TrimAll(Algorithm.AlgorithmText)) Then
		Return;
	EndIf;
	
	ExecutionContext = GetParameters(Algorithm);

	ExecutionResult =  UT_CodeEditorClientServer.ExecuteAlgorithm(Algorithm.AlgorithmText, ExecutionContext);

EndProcedure

Function GetParameters(Algorithm) Export
	StorageParameters = Algorithm.Storage.Get();
	If StorageParameters = Undefined Or TypeOf(StorageParameters) <> Type("Structure")Then 
		StorageParameters =  New Structure;
	EndIf;
	Return StorageParameters;
EndFunction