&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		ValueList = Items.UserName.ChoiceList;

	If AccessRight("DataAdministration", Metadata) Then
		For Each Item In InfoBaseUsers.GetUsers() Do
			ValueList.Add(Item.Name);
		EndDo;
		ValueList.SortByValue();
	Иначе
		ValueList.Add(UserName());
		Items.UserName.ReadOnly = True;
	EndIf;

	ScaleVariant = "Auto";
	UserName = UserName();
EndProcedure


&AtClient
Procedure SetScaleVariant(Command)
	If Not IsBlankString(ScaleVariant) Then
		ShowQueryBox(New NotifyDescription("SetScaleVariantAfter", ThisForm),
			"ru = 'Масштаб отображения форм будет изменен. Продолжить?';en = 'Forms scale variant will be changed. Continue?'", QuestionDialogMode.YesNoCancel, 20);
	EndIf;
EndProcedure

&AtClient
Procedure SetScaleVariantAfter(QuestionResult, AdditionalParameters) Export
	If QuestionResult = DialogReturnCode.Yes Then
		If SetScaleVariantAtServer(ScaleVariant, UserName) Then
			ShowMessageBox( , "ru = 'Масштаб отображения форм изменен.
							  |Чтобы изменения вступили в силу надо перезайти в 1С:Предприятие.';en = 'Forms scale variant has been changed
							  | Restart application to apply changes.'", 20);
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function SetScaleVariantAtServer(ScaleVariant, Val UserName)
	If IsBlankString(UserName) Then
		UserName = Undefined;
	EndIf;

	Try
		Setting = SystemSettingsStorage.Load("Common/ClientSettings", "", , UserName);

		If Not TypeOf(Setting) = Type("ClientSettings") Then
			Setting = New ClientSettings;
		EndIf;

		Setting.ClientApplicationFormScaleVariant = ClientApplicationFormScaleVariant[ScaleVariant];
		SystemSettingsStorage.Save("Common/ClientSettings", "", Setting, , UserName);
		Return True;
	Except
		Message(ErrorDescription());
		Return False;
	EndTry;
EndFunction