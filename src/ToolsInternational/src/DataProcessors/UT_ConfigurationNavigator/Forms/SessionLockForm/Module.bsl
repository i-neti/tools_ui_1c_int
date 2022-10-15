&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	vGetSessionsLock();
EndProcedure
&AtServer
Procedure vGetSessionsLock()
	SessionsLock = GetSessionsLock();
	FillPropertyValues(ThisForm, SessionsLock);
EndProcedure
&AtClient
Procedure kSetSessionsLock(Command)
	vSetSessionsLockAtServer();
EndProcedure

&AtServer
Procedure vSetSessionsLockAtServer()
	SessionsLock = New SessionsLock;
	FillPropertyValues(SessionsLock, ThisForm);

	Try
		SetSessionsLock(SessionsLock);
	Except
		Message(ErrorDescription());
	EndTry;;

	vGetSessionsLock();
EndProcedure