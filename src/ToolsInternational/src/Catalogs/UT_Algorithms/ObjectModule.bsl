#Region Internal

Function GetParameters() Export
	StorageParameters = Storage.Get();
	If StorageParameters = Undefined OR TypeOf(StorageParameters) <> Type("Structure") Then 
		StorageParameters =  New Structure;
	EndIf;
	Return StorageParameters;
EndFunction

Function GetParameter(ParameterName) Export
	StorageParameters = Storage.Get();
	If StorageParameters <> Undefined AND StorageParameters.Property(ParameterName) Then
		Return StorageParameters[ParameterName];
	Else 
		Return Undefined;
	EndIf;
EndFunction

Function RemoveParameter(Key) Export
	
		StorageParameters = GetParameters();
		StorageParameters.Delete(Key);
		Storage = New ValueStorage(StorageParameters);
		Write();
		Return True;	

EndFunction

Function RenameParameter(Key, NewName) Export
	Try
		StorageParameters = GetParameters();
		Value = StorageParameters[Key];
		StorageParameters.Delete(Key);
		StorageParameters.Insert(NewName,Value);
		Storage = New ValueStorage(StorageParameters);
		Write();
		Return True;
	Except
		Return False;
	EndTry;
EndFunction

Function EditParameter(Key, NewValue) Export
	StorageParameters = GetParameters();
	StorageParameters.Insert(Key,NewValue);
	Storage = New ValueStorage(StorageParameters);
	Write();
	Return True;
EndFunction

#EndRegion