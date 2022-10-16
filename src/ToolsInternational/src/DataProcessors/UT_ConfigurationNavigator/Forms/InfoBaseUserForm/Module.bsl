&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetPrivilegedMode(True);

	If Parameters.Property("WorkMode") Then
		_WorkMode = Parameters.WorkMode;
	Endif;

	If _WorkMode = 0 Then
		ID = Parameters.DBUserID;
		DBUserID = New UUID(Parameters.DBUserID);

		Try
			InfoBaseUser = InfoBaseUsers.FindByUUID(
				DBUserID);
			If InfoBaseUser = Undefined Then
				Cancel = True;
			Endif;
		Except
			Cancel = True;
		EndTry;

	ElsIf _WorkMode = 1 Then
		InfoBaseUser = InfoBaseUsers.CreateUser();
		Items.ChangePassword.Enabled = False;
		Title = "Creation";

	ElsIf _WorkMode = 2 Then
		ID = Parameters.DBUserID;
		DBUserID = New UUID(Parameters.DBUserID);

		Try
			InfoBaseUser = InfoBaseUsers.FindByUUID(
				DBUserID);
			If InfoBaseUser = Undefined Then
				Cancel = True;
			Endif;
		Except
			Cancel = True;
		EndTry;

		Items.ChangePassword.Enabled = False;
		Title = "Creation";
	Else
		Cancel = True;
	Endif;

	If Not Cancel Then
		FillPropertyValues(ThisForm, InfoBaseUser, , "Password");

		Struct = vPropertiesValue(InfoBaseUser, "UnsafeOperationProtection");
		If Struct.UnsafeOperationProtection <> Undefined Then
			UnsafeOperationProtection = InfoBaseUser.UnsafeOperationProtection.UnsafeOperationWarnings;
		Else
			UnsafeOperationProtection = False;
			Items.UnsafeOperationProtection.ReadOnly = True;
		Endif;

		If InfoBaseUser.PasswordIsSet Then
			Password = "12345";
			PasswordConfirmation = "54321";
		Endif;

		For Each Item In MetaData.Roles Do
			NewRow = UserRoles.Add();
			NewRow.Name = Item.Name;
			NewRow.Presentation = Item.Presentation();
			If InfoBaseUser.Roles.Contains(Item) Then
				NewRow.Check = True;
				NewRow.Set = True;
				If _WorkMode = 2 Then
					NewRow.Set = False;
				Endif;
			Endif;
		EndDo;

		UserRoles.Сортировать("Name");

	Endif;
	
EndProcedure

&AtServerNoContext
Function vPropertiesValue(Val Object, PropertiesList)
	Struct = New Structure(PropertiesList);
	FillPropertyValues(Struct, Object);

	Return Struct;
EndFunction

&AtServer
Procedure WriteObjectAtServer()
	If _WorkMode = 0 Then
		InfoBaseUser = InfoBaseUsers.FindByUUID(DBUserID);
	Else
		InfoBaseUser = InfoBaseUsers.CreateUser();
		InfoBaseUser.Password = Password;
	Endif;

	If Not Items.UnsafeOperationProtection.ReadOnly Then
		FillPropertyValues(InfoBaseUser, ThisForm, , "Password, UnsafeOperationProtection");
		InfoBaseUser.UnsafeOperationProtection.UnsafeOperationWarnings = UnsafeOperationProtection;
	Else
		FillPropertyValues(InfoBaseUser, ThisForm, , "Password");
	Endif;

	For each Row In UserRoles.FindRows(New Structure("Check, Set", True, False)) Do
		InfoBaseUser.Roles.Add(MetaData.Roles[Row.Name]);
	EndDo;

	For each Row In UserRoles.FindRows(New Structure("Check, Set", False, True)) Do
		InfoBaseUser.Roles.Delete(MetaData.Roles[Row.Name]);
	EndDo;

	InfoBaseUser.Write();
EndProcedure

&AtClient
Procedure WriteObject(Command)
	If _WorkMode <> 0 Then
		If Password <> PasswordConfirmation Then
			ShowMessageBox( , "ru = 'Пароль не совпадает с Подтверждением пароля!';en = 'Password not match with  Password Confirmation!'", 10);
			Return;
		Endif;
	Endif;

	Try
		WriteObjectAtServer();
		Close();
	Except
		Message(ErrorDescription());
	EndTry;
EndProcedure

&AtServer
Procedure ChangePasswordAtServer()
	InfoBaseUser = InfoBaseUsers.FindByUUID(DBUserID);
	InfoBaseUser.Password = Password;
	InfoBaseUser.Write();
EndProcedure

&AtClient
Procedure ChangePassword(Command)
	If Password <> PasswordConfirmation Then
		ShowMessageBox( , "ru = 'Пароль не совпадает с Подтверждением пароля!';en = 'Password not match with  Password Confirmation!'", 10);
		Return;
	Endif;

	ChangePasswordAtServer();
EndProcedure

&AtClient
Procedure _ShowOnlyAvailable(Command)
	Fi = Items.UserRoles_ShowOnlyAvailable;
	Fi.Check = Not Fi.Check;

	If Fi.Check Then
		Items.UserRoles.RowFilter = New FixedStructure(New Structure("Check", True));
	Else
		Items.UserRoles.RowFilter = Undefined;
	Endif;
EndProcedure