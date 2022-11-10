
// Description
// 
// Parameters:
// 	AlgorithmName - String - Algoritms catalog item name , searched by name 
// 	AlgorithmText - String - Attribute "AlgorithmText" value
// 	ParameterN - Value of any type
// Return value:
// 	String - Result of algorithm saving execution
Function CreatingOfAlgorithm(AlgorithmName, AlgorithmText = "", Val Parameter1 = Undefined, 
	Val Parameter2 = Undefined, Val Parameter3 = Undefined, Val Parameter4 = Undefined, 
	Val Parameter5 = Undefined, Val Parameter6 = Undefined, Val Parameter7 = Undefined, 
	Val Parameter8 = Undefined, Val Parameter9 = Undefined, Val ParametersNamesArray = Undefined) Export
	
	Return UT_AlgorithmsServer.CreatingOfAlgorithm(AlgorithmName, AlgorithmText, Parameter1, Parameter2, Parameter3, 
		Parameter4, Parameter5, Parameter6, Parameter7, Parameter8, Parameter9, ParametersNamesArray);	

EndFunction

Procedure ExecuteAlgorithm(Algorithm) Export
	UT_AlgorithmsServer.ExecuteAlgorithm(Algorithm);
EndProcedure

Function GetParameters(Algorithm) Export
	Return UT_AlgorithmsServer.GetParameters(Algorithm);
EndFunction