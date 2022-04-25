&AtClient
Procedure VisibilityControl()
	Items.LinkByOwner.Visible = UseOwner;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SysInfo = New SystemInfo;
	If Left(SysInfo.AppVersion, 3) = "8.3" Then
		Items.SearchBy.DropListButton = True;
		Items.LinkByOwner.DropListButton = True;
	EndIf;
	VisibilityControl();
EndProcedure

&AtClient
Procedure OK(Command)

	NotifyChoice(New Structure("Source, Result, SearchBy, LinkByOwner", "EditLinkForm",
		True, SearchBy, LinkByOwner));

EndProcedure