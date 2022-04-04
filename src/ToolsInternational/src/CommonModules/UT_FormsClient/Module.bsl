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
&AtClient
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

#EndRegion