
// See SSL  StandartSybsystemsCached.RefsByPredefinedItemsNames
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export

	Return UT_CommonServerCall.RefsByPredefinedItemsNames(FullMetadataObjectName);

EndFunction

Function DataBaseObjectEditorAvailableObjectsTypes() Export
	Return UT_CommonCached.DataBaseObjectEditorAvailableObjectsTypes();
EndFunction

Function HTMLFieldBasedOnWebkit() Export
	UT_CommonClientServer.HTMLFieldBasedOnWebkit();
EndFunction