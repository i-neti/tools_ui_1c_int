
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ThisObject.AutoUpdate = Parameters.AutoUpdate;
	ThisObject.AutoUpdatePeriod = Parameters.AutoUpdatePeriod;
	IntervalSeconds = 5;
	If ThisObject.AutoUpdatePeriod < IntervalSeconds Then
		ThisObject.AutoUpdatePeriod = IntervalSeconds;
	EndIf;
EndProcedure


&AtClient
Procedure OK(Command)
	IntervalSeconds = 5;
	If ThisObject.AutoUpdatePeriod < IntervalSeconds Then
		ThisObject.AutoUpdatePeriod = IntervalSeconds;
	EndIf;
	Result = New Structure("AutoUpdate, AutoUpdatePeriod", AutoUpdate, ThisObject.AutoUpdatePeriod);
	Close(Result);
EndProcedure
