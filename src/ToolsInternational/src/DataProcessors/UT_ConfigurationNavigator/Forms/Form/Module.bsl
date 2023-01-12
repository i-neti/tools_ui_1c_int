&AtClient
Var mOrdinaryApplicationObjects;

&AtClient
Var mCurrentTreeObject;

&AtClient
Var mDescriptionAccessRights;

&AtClient
Var mFavoriteID;

&AtClient
Var mClusterParameters;
&AtServer
Function vGetProcessor()
	Return FormAttributeToValue("Object");
EndFunction
&AtClient
Procedure vShowMessageBox(Text)
	ShowMessageBox( , Text, 20);
EndProcedure

&AtClient
Procedure vShowQueryBox(QueryText, ProcedureName, AdditionalParameters = Undefined)
	ShowQueryBox(New NotifyDescription(ProcedureName, ThisForm, AdditionalParameters), QueryText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure vOperationNotSupportedForWebClient()
	vShowMessageBox("ru = 'Для Web-клиента данная операция не поддерживается!';en = 'The operation is not supported for a web-client!'");
EndProcedure

&AtServerNoContext
Procedure vFillInFormContext(_FormContext)
	_FormContext.Insert("SubsystemVersions", (Metadata.InformationRegisters.Find("SubsystemVersions") <> Undefined));
	_FormContext.Insert("ExclusiveMode", ExclusiveMode());
EndProcedure

&AtServerNoContext
Function vIsAdministratorRights()
	Return AccessRight("Administration", Metadata);
EndFunction

&AtServerNoContext
Function vGetUserId(Val Name)
	vUser = InfoBaseUsers.FindByName(Name);

	Return ?(vUser = Undefined, "", String(vUser.UUID));
EndFunction

&AtClientAtServerNoContext
Function vValueToArray(Val Value)
	Array = New Array;
	Array.Add(Value);

	Return Array;
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	ThisForm.ConditionalAppearance.Items.Clear();

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ObjectsTree.FullName");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = "Configuration";
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.ServiceTree.Font, , , True));
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("ObjectsTreeName");

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ObjectsTree.NType");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 1;
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("ObjectsTreeName");

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ServiceTree.IsGroup");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.ServiceTree.Font, , , True));
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("ServiceTreePresentation");

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("ServiceTree.Enabled");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = False;
	AppearanceItem.Appearance.SetParameterValue("Text", New Color(83, 106, 194));
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("ServiceTreePresentation");

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("VerifiableRightsTable.Mark");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	AppearanceItem.Appearance.SetParameterValue("Font", New Font(Items.VerifiableRightsTable.Font, , ,
		True));
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("VerifiableRightsTableMetadataObject");
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("VerifiableRightsTableRight");

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("_SessionList.CurrentSession");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("_SessionList");

	AppearanceItem = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("_ConnectionsList.CurrentConnections");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = True;
	AppearanceItem.Appearance.SetParameterValue("TextColor", WebColors.Blue);
	AppearanceItem.Fields.Items.Add().Field = New DataCompositionField("_ConnectionsList");

EndProcedure

&AtClient
Function vFormStructureOfObjectPropertiesFormSettings()
	_Structure = New Structure("_ShowObjectSubscribtion, _ShowObjectSubsystems, _ShowCommonObjectCommands, _ShowExternalObjectCommands, _ShowStorageStructureInTermsOf1C");
	FillPropertyValues(_Structure, ThisForm);

	Return _Structure;
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	PathToForms = vGetProcessor().Metadata().FullName() + ".Form.";

	pIsAdministratorRights = vIsAdministratorRights();
	WaitingTimeBeforePasswordRecovery=20;
	
	//Items.SettingsPage.Visible = False;
	Items.StorageStructurePage.Visible = False;
	Items.ObjectRightPages.Visible = False;
	Items._DisplayObjectsRights.Enabled = pIsAdministratorRights;
	Items.ObjectsTreeForAdministrators.Enabled = pIsAdministratorRights;
	Items.DBUsers.Visible = pIsAdministratorRights;
	Items._SessionList_FinishSessions.Enabled = pIsAdministratorRights;
	Items.SessionsPage.Visible = AccessRight("ActiveUsers", Metadata);
	Items._SessionList_FinishSessions.Enabled = pIsAdministratorRights;

	Items.ConfigurationExtensions.Visible = False;
	//Items.ConfigurationExtensions.Visible = vCheckType("ConfigurationExtension");

	_FormContext = New Structure;
	vFillInFormContext(_FormContext);
	vFillServiceTree();

	_FavoritesContent = New Structure("Version, Data", 1, New Array);

	SetConditionalAppearance();

	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing,
		Items.ObjectsTree.CommandBar);

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	If _ShowStandardSettings Then
		Items.DefaultSettingsPage.Visible = True;
	EndIf;

	If _ShowTablesAndIndexesDB Then
		Items.StorageStructurePage.Visible = True;
	EndIf;

	Value = Settings["_FavoritesContent"];
	If Value <> Undefined Then
		If Not Value.Property("Version") Then
			Value.Insert("Version", 1);
		EndIf;
		_FavoritesContent = Value;

		TreeLines = ObjectsTree.GetItems();
		If TreeLines.Count() <> 0 Then
			// re-fill favorites
			For Each TreeSection In TreeLines Do
				If TreeSection.FullName = "Favorites" Then
					TreeSection.GetItems().Clear();
					For Each Item In _FavoritesContent.Data Do
						FillPropertyValues(TreeSection.GetItems().Add(), Item);
					EndDo;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

	Items._DBUserListListOfRoles.Visible = _ShowUserRolesList;
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	// let's form favorites
	For Each TreeSection In ObjectsTree.GetItems() Do
		If TreeSection.FullName = "Favorites" Then
			ListOfTreeFields = vListOfTreeFields();
			_FavoritesContent.Data.Clear();
			For Each TreeLine In TreeSection.GetItems() Do
				_Structure = New Structure(ListOfTreeFields);
				FillPropertyValues(_Structure, TreeLine);
				_FavoritesContent.Data.Add(_Structure);
			EndDo;
			Break;
		EndIf;
	EndDo;

	Settings.Insert("_FavoritesContent", _FavoritesContent);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	mCurrentTreeObject = "";

	vFormDescriptionOfAccessRights();
	vFillAccessRights();

	mOrdinaryApplicationObjects = New Structure("Constant, Catalog, Document, DocumentJournal, ChartOfCharacteristicTypes, ChartOfCalculationTypes, ChartOfAccounts
												|, Processing, Report, InformationRegister, AccumulationRegister, AccountingRegister, CalculationRegister, BusinessProcess, Task
												|, ExchangePlan");

	TreeLines = ObjectsTree.GetItems();
	TreeLines.Clear();

	TreeLine = TreeLines.Add();
	FillPropertyValues(TreeLine, vFormConfigurationNode());
	TreeLine.NType = 1;
	
	
	// Favorites
	TreeLine = TreeLines.Add();
	TreeLine.Name = "Favorites...";
	TreeLine.NodeType = "Favorites";
	TreeLine.NType = 1;
	TreeLine.FullName = "Favorites";
	mFavoriteID = TreeLine.GetID();

	For Each Item In _FavoritesContent.Data Do
		NewRow = TreeLine.GetItems().Add();
		FillPropertyValues(NewRow, Item);
	EndDo;
	TreeLine = TreeLines.Add();
	TreeLine.Name = "Common";
	TreeLine.NodeType = "SectionGroupMD";
	TreeLine.NType = 1;
	TreeLine.GetItems().Add();

	SectionStructure = New Structure("Constants, Catalogs, Documents, DocumentJournals, Enums, ChartsOfCharacteristicTypes, ChartsOfCalculationTypes, ChartsOfAccounts
								   |, DataProcessors, Reports, InformationRegisters, AccumulationRegisters, AccountingRegisters, CalculationRegisters, BusinessProcesses, Tasks");

	vCalculateNumberOfObjectsMD(SectionStructure);

	For Each Item In SectionStructure Do
		TreeLine = TreeLines.Add();
		TreeLine.Name = Item.Key;
		TreeLine.Name = Item.Key + " (" + Item.Value + ")";
		TreeLine.NodeType = "SectionMD";
		TreeLine.NType = 1;
		TreeLine.GetItems().Add();
	EndDo;

	_StorageAddresses = New Structure("RegisterRecords, Subscriptions, Commands, CommonCommands, Subsystems, RolesAndUsers");
	_StorageAddresses.RegisterRecords = PutToTempStorage(-1, UUID);
	_StorageAddresses.Subscriptions = PutToTempStorage(-1, UUID);
	_StorageAddresses.Commands  = PutToTempStorage(-1, UUID);
	_StorageAddresses.CommonCommands = PutToTempStorage(-1, UUID);
	_StorageAddresses.Subsystems = PutToTempStorage(-1, UUID);
	_StorageAddresses.RolesAndUsers = "";
	
	// Settings Storages
	TreeLines = SettingsTree.GetItems();
	TreeLines.Clear();

	ValueTreeGroup = TreeLines.Add();
	ValueTreeGroup.Presentation = NSTR("ru = 'Стандартные хранилища настроек';en = 'Standart settings storages'");

	SectionStructure = New Structure("ReportsVariantsStorage, FormDataSettingsStorage, CommonSettingsStorage
								   |, DynamicListsUserSettingsStorage, ReportsUserSettingsStorage, SystemSettingsStorage");

	For Each Item In SectionStructure Do
		TreeLine = ValueTreeGroup.GetItems().Add();
		TreeLine.Name = Item.Key;
		TreeLine.Presentation = Item.Key;
		TreeLine.NodeType = "Х";
	EndDo;
EndProcedure

&AtClient
Procedure kOpenInNewWindow(Command)
	OpenForm(PathToForms, , , CurrentDate(), , , , FormWindowOpeningMode.Independent);
EndProcedure

&AtClient
Procedure _CollapseAllNodes(Command)
	For Each TreeNode In ObjectsTree.GetItems() Do
		Items.ObjectsTree.Collapse(TreeNode.GetID());
	EndDo;
EndProcedure

&AtClient
Procedure _UpdateDBUsersList(Command)
	For Each Row In ObjectsTree.GetItems() Do
		If Row.Name = "Common" Then
			For Each TreeNode In Row.GetItems() Do
				If TreeNode.NodeType = "SectionMD" And StrFind(TreeNode.Name, "Users") = 1 Then
					TreeLines = TreeNode.GetItems();
					TreeLines.Clear();

					_Structure = vGetCompositionSectionMD("Users");
					For Each Item In _Structure.ObjectsArray Do
						TreeLine = TreeLines.Add();
						FillPropertyValues(TreeLine, Item);
					EndDo;
					TreeNode.Name = "Users (" + _Structure.NumberOfObjects + ")";

					Break;
				EndIf;
			EndDo;

			Break;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure _CreateDBUser(Command)
	StructureOfParameters = New Structure("WorkMode", 1);
	OpenForm(PathToForms + "InfoBaseUserForm", StructureOfParameters, , , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure _CopyDBUser(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined And StrFind(CurrentData.FullName, "User.") = 1 Then
		StructureOfParameters = New Structure("WorkMode, DBUserID", 2, CurrentData.ObjectPresentation);
		OpenForm(PathToForms + "InfoBaseUserForm", StructureOfParameters, , , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure _DeleteDBUser(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined And StrFind(CurrentData.FullName, "User.") = 1 Then
		nText = StrTemplate(
		NStr("ru = 'Пользователь ""%1"" будет удален из информационной базы!
								  |Продолжить?';en = 'The user ""%1"" will be deleted from the base!
								  |Continue?'"), CurrentData.Name);
								  
		ShowQueryBox(New NotifyDescription("vDeleteUserAnswer", ThisForm, CurrentData), nText,
			QuestionDialogMode.YesNoCancel, 20);
	EndIf;
EndProcedure

&AtClient
Procedure vDeleteUserAnswer(Answer, CurrentData) Export
	If Answer = DialogReturnCode.Yes Then
		pResult = vDeleteUser(CurrentData.ObjectPresentation);
		If pResult.Cancel Then
			vShowMessageBox(pResult.ReasonForRefusal);
		Else
			CurrentData.GetParent().GetItems().Delete(CurrentData);
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function vDeleteUser(ID)
	pResult = New Structure("Cancel, ReasonForRefusal", False, "");

	Try
		userUUID = New UUID(ID);

		vUser = InfoBaseUsers.FindByUUID(userUUID);
		If vUser = Undefined Then
			pResult.Cancel = True;
			pResult.ReasonForRefusal = Nstr("ru = 'Указанный пользователь не найден!';en = 'The specified user was not found!'");
			Return pResult;
		EndIf;

		pCurrentUser = InfoBaseUsers.CurrentUser();

		If pCurrentUser.UUID = userUUID Then
			pResult.Cancel = True;
			pResult.ReasonForRefusal = Nstr("ru = 'Нельзя удалить текущего пользоватля!';en = 'You cannot delete the current user!'");
			Return pResult;
		EndIf;

		vUser.Delete();
	Except
		pResult.Cancel = True;
		pResult.ReasonForRefusal = ErrorDescription();
	EndTry;

	Return pResult;
EndFunction
&AtClient
Procedure kShowObjectProperties(Command)
	If Items.PagesGroup.CurrentPage.Name = "StorageStructurePage" Then
		CurrentData = Undefined;
		If Items.TableAndIndexesGrpip.CurrentPage.Name = "_IndexesPage" Then
			CurrentData = Items._Indexes.CurrentData;
		ElsIf Items.TableAndIndexesGrpip.CurrentPage.Name = "TablePage" Then
			CurrentData = Items._Tables.CurrentData;
		EndIf;

		If CurrentData <> Undefined Then
			pFullName = CurrentData.Metadata;
			If pFullName = Nstr("ru = '<не задано>';en = '<not set>'") Then
				Return;
			EndIf;

			Position = StrFind(pFullName, ".", , , 2);
			If Position <> 0 Then
				pFullName = Left(pFullName, Position - 1);
			EndIf;

			StructureOfParameters = New Structure("FullName, PathToForms, _StorageAddresses, DescriptionOfAccessRights",
				pFullName, PathToForms, _StorageAddresses, mDescriptionAccessRights);
			StructureOfParameters.Insert("ProcessingSettings", vFormStructureOfObjectPropertiesFormSettings());
			OpenForm(PathToForms + "PropertiesForm", StructureOfParameters, , pFullName, , , ,
				FormWindowOpeningMode.Independent);
		EndIf;

		Return;
	EndIf;

	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" Then
			If StrFind(CurrentData.FullName, "User.") = 1 Then
				StructureOfParameters = New Structure("DBUserID", CurrentData.ObjectPresentation);
				OpenForm(PathToForms + "InfoBaseUserForm", StructureOfParameters, , CurrentData.FullName, , , ,
					FormWindowOpeningMode.LockOwnerWindow);
			Else
				StructureOfParameters = New Structure("FullName, PathToForms, _StorageAddresses, DescriptionOfAccessRights",
					CurrentData.FullName, PathToForms, _StorageAddresses, mDescriptionAccessRights);
				StructureOfParameters.Insert("ProcessingSettings", vFormStructureOfObjectPropertiesFormSettings());
				OpenForm(PathToForms + "PropertiesForm", StructureOfParameters, , CurrentData.FullName, , , ,
					FormWindowOpeningMode.Independent);
			EndIf;
		ElsIf CurrentData.NodeType = "Configuration" Then
			StructureOfParameters = New Structure("FullName, PathToForms, _StorageAddresses, DescriptionOfAccessRights",
				"Configuration", PathToForms, _StorageAddresses, mDescriptionAccessRights);
			StructureOfParameters.Insert("ProcessingSettings", vFormStructureOfObjectPropertiesFormSettings());
			OpenForm(PathToForms + "PropertiesForm", StructureOfParameters, , CurrentData.FullName, , , ,
				FormWindowOpeningMode.Independent);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure kOpenListForm(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" And Not vIsOtherCommand(CurrentData.FullName) Then
			Try
				ObjectTypeMD = Left(CurrentData.FullName, StrFind(CurrentData.FullName, ".") - 1);

				If ObjectTypeMD = "User" Then
					StandardProcessing = False;
					StructureOfParameters = New Structure("DBUserID", CurrentData.ObjectPresentation);
					OpenForm(PathToForms + "InfoBaseUserForm", StructureOfParameters, , CurrentData.FullName, , , ,
						FormWindowOpeningMode.LockOwnerWindow);
					Return;
				EndIf;

				If Not mOrdinaryApplicationObjects.Property(ObjectTypeMD) Then
					Return;
				EndIf;

				If ObjectTypeMD = "DataProcessor" Then
					FormNameMD = ".Form";
				ElsIf ObjectTypeMD = "Report" Then
					FormNameMD = ".Form";
				ElsIf ObjectTypeMD = "Constant" Then
					FormNameMD = ".ConstantsForm";
				ElsIf ObjectTypeMD = "CommonForm" Then
					FormNameMD = "";
				ElsIf ObjectTypeMD = "Enum" Then
					StandardProcessing = True;
					Return;
				Else
					FormNameMD = ".ListForm";
				EndIf;

				StandardProcessing = False;
				OpenForm(CurrentData.FullName + FormNameMD);
			Except
				Message(BriefErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure kCollapseTreeSection(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		TreeNode = CurrentData.GetParent();
		If TreeNode <> Undefined Then
			String = TreeNode.GetID();
			Items.ObjectsTree.CurrentRow = String;
			Items.ObjectsTree.Collapse(String);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure kRunDesigner(Command)
	vLaunch1C(1);
EndProcedure

&AtClient
Procedure kRunOrdinaryClient(Command)
	vLaunch1C(2);
EndProcedure

&AtClient
Procedure kRunThickClient(Command)
	vLaunch1C(3);
EndProcedure

&AtClient
Procedure kRunThinClient(Command)
	vLaunch1C(4);
EndProcedure

&AtClient
Procedure kRun1CForAnyBase(Command)
#If WebClient Then
	vOperationNotSupportedForWebClient();
#Else
		OpenForm(PathToForms + "Launch1CForm", , ThisForm, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
#EndIf
EndProcedure

&AtClient
Procedure ObjectsTreeBeforeExpand(Item, String, Cancel)
	If Not _DisplayObjectsRights Then
		Items.ObjectsTree.CurrentRow = String; // it is usefull when opening nodes are above
	EndIf;

	TreeNode = ObjectsTree.FindByID(String);
	TreeLines = TreeNode.GetItems();
	If TreeLines.Count() = 1 And IsBlankString(TreeLines[0].NodeType) Then
		Cancel = True;
		TreeLines.Clear();

		TreeNodeName = TreeNode.Name;
		Position = StrFind(TreeNodeName, " (");
		If Position <> 0 Then
			TreeNodeName = Left(TreeNodeName, Position - 1);
		EndIf;

		If TreeNode.NodeType = "SectionMD" Then
			TreeNode = ObjectsTree.FindByID(String);
			TreeLines = TreeNode.GetItems();
			TreeLines.Clear();

			If TreeNodeName = "Documents" Then
				_Structure = New Structure("DocumentNumerators, Sequences");
				vCalculateNumberOfObjectsMD(_Structure);
				For Each Item In _Structure Do
					TreeLine = TreeLines.Add();
					TreeLine.NodeType = "SectionMD";
					TreeLine.Name = Item.Key + " (" + Item.Value + ")";
					TreeLine.GetItems().Add();
				EndDo;
				
				//TreeLine = TreeLines.Add();
				//TreeLine.NodeType = "SectionMD";
				//TreeLine.Name = "DocumentNumerators";
				//TreeLine.GetItems().Add();
				//
				//TreeLine = TreeLines.Add();
				//TreeLine.NodeType = "SectionMD";
				//TreeLine.Name = "Sequences";
				//TreeLine.GetItems().Add();
			EndIf;

			_Structure = vGetCompositionSectionMD(TreeNodeName);
			For Each Item In _Structure.ObjectsArray Do
				TreeLine = TreeLines.Add();
				FillPropertyValues(TreeLine, Item);
				If StrFind(TreeLine.FullName, "Enum.") = 1 Then
					TreeLine.GetItems().Add();
				ElsIf StrFind(TreeLine.FullName, "Subsystems.") = 1 Then
					If Item.ThereAreChildren Then
						TreeLine.GetItems().Add();
					EndIf;
				ElsIf StrFind(TreeLine.FullName, "WebService.") = 1 Then
					TreeLine.GetItems().Add();
				ElsIf StrFind(TreeLine.FullName, "HTTPService.") = 1 Then
					TreeLine.GetItems().Add();
				EndIf;
			EndDo;
			TreeNode.Name = TreeNodeName + " (" + _Structure.NumberOfObjects + ")";

		ElsIf TreeNode.NodeType = "SectionGroupMD" Then
			SectionStructure = New Structure("Subsystems, CommonModules, SessionParameters, Users, Roles, CommonAttributes, ExchangePlans, EventSubscriptions, ScheduledJobs
										   |, FunctionalOptions, FunctionalOptionsParameters, DefinedTypes, SettingsStorages, CommonForms, CommonCommands, CommandGroups, OtherCommands, CommonTemplates, XDTOPackages, WebServices, HTTPServices");

			vCalculateNumberOfObjectsMD(SectionStructure);

			For Each Item In SectionStructure Do
				If Item.Key = "Users" And Not vIsAdministratorRights() Then
					Continue;
				EndIf;
				TreeLine = TreeLines.Add();
				TreeLine.Name = Item.Key;
				TreeLine.Name = Item.Key + " (" + Item.Value + ")";
				TreeLine.NodeType = "SectionMD";
				TreeLine.NType = 1;
				TreeLine.GetItems().Add();
			EndDo;

		ElsIf TreeNode.NodeType = "MetadataObject" Then
			ObjectTypeMD = Left(TreeNode.FullName, StrFind(TreeNode.FullName, ".") - 1);

			TreeNode = ObjectsTree.FindByID(String);
			TreeLines = TreeNode.GetItems();
			TreeLines.Clear();

			If ObjectTypeMD = "Enum" Then
				ObjectsArray = vGetCompositionEnum(TreeNode.FullName);
				For Each Item In ObjectsArray Do
					TreeLine = TreeLines.Add();
					FillPropertyValues(TreeLine, Item);
				EndDo;
			ElsIf ObjectTypeMD = "Subsystems" Then
				ObjectsArray = vGetCompositionSubsytem(TreeNode.FullName);
				For Each Item In ObjectsArray Do
					TreeLine = TreeLines.Add();
					FillPropertyValues(TreeLine, Item);
					If Item.ThereAreChildren Then
						TreeLine.GetItems().Add();
					EndIf;
				EndDo;
			ElsIf ObjectTypeMD = "WebService" Then
				ObjectsArray = vGetWebServiceOperations(TreeNode.FullName);
				For Each Item In ObjectsArray Do
					TreeLine = TreeLines.Add();
					FillPropertyValues(TreeLine, Item);
				EndDo;
			ElsIf ObjectTypeMD = "HTTPService" Then
				ObjectsArray = vGetHTTPServiceMethods(TreeNode.FullName);
				For Each Item In ObjectsArray Do
					TreeLine = TreeLines.Add();
					FillPropertyValues(TreeLine, Item);
					For Each ItemX In Item.Methods Do
						FillPropertyValues(TreeLine.GetItems().Add(), ItemX);
					EndDo;
				EndDo;
			EndIf;
		EndIf;
		Items.ObjectsTree.Expand(String);
	EndIf;
EndProcedure

&AtClient
Procedure vLaunch1C(LaunchType)
	UT_CommonClient.Run1CSession(LaunchType, UserName());
EndProcedure

&AtClient
Procedure vRunOSCommand(pCommand)
	Try
		BeginRunningApplication(New NotifyDescription("vAfterRunningApplication", ThisForm), pCommand);
	Except
		Message(BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtClient
Procedure vAfterRunningApplication(ReturnCode, AdditionalParameters = Undefined) Export
	// the procedure for compatibility of different versions of the platform
EndProcedure
&AtClientAtServerNoContext
Function vListOfTreeFields()
	Return "Name, Synonym, MainSQLTable, FullName, NodeType, NType, ObjectPresentation, NumberOfObjects";
EndFunction

&AtServerNoContext
Function vFormStructureTreeNode(NodeType = "", Name = "", FullName = "", Synonym = "", ThereAreChildren = False,
	ObjectPresentation = "")
	_Structure = New Structure("NodeType, Name, FullName, Synonym, ObjectPresentation, ThereAreChildren, MainSQLTable",
		NodeType, Name, FullName, Synonym, ObjectPresentation, ThereAreChildren, "");
	Return _Structure;
EndFunction

&AtServerNoContext
Function vFormConfigurationNode()
	_Structure = New Structure("Name, Synonym, Version", "", "", "");
	FillPropertyValues(_Structure, Metadata);

	If IsBlankString(_Structure.Synonym) Then
		_Structure.Synonym = _Structure.Name;
	EndIf;
	If Not IsBlankString(_Structure.Version) Then
		_Structure.Synonym = _Structure.Synonym + " (" + _Structure.Version + ")";
	EndIf;

	Return vFormStructureTreeNode("Configuration", _Structure.Name, "Configuration", _Structure.Synonym);
EndFunction

&AtServerNoContext
Function vCheckProperty(Object, PropertyName)
	_Structure = New Structure(PropertyName);
	FillPropertyValues(_Structure, Object);

	Return (_Structure[PropertyName] <> Undefined);
EndFunction

&AtServerNoContext
Function vGetCompositionSectionMD(Val NameOfSection)
	Position = StrFind(NameOfSection, " ");
	If Position <> 0 Then
		NameOfSection = Left(NameOfSection, Position - 1);
	EndIf;

	ResultStructure = New Structure("NumberOfObjects, ObjectsArray", 0, New Array);
	
	// for ordering by object names
	ObjectsWithAdditionalPresentation = New Structure("ExchangePlans, Catalogs, Documents, ChartsOfCharacteristicTypes, ChartsOfCalculationTypes, ChartsOfAccounts, BusinessProcesses, Tasks");
	IsAdditionalPresentation = ObjectsWithAdditionalPresentation.Property(NameOfSection);

	StringType = New TypeDescription("String");

	Table = New ValueTable;
	Table.Columns.Add("MetadataObject");
	Table.Columns.Add("Name", StringType);
	Table.Columns.Add("Synonym", StringType);
	Table.Columns.Add("ObjectPresentation", StringType);
	Table.Columns.Add("MainSQLTable", StringType);
	Table.Columns.Add("FullName", StringType);
	Table.Columns.Add("NodeType", StringType);
	Table.Columns.Add("ThereAreChildren", New TypeDescription("Boolean"));

	If NameOfSection = "Users" Then
		If vIsAdministratorRights() Then
			For Each Item In InfoBaseUsers.GetUsers() Do
				Row = Table.Add();
				Row.Name = Item.Name;
				Row.Synonym = Item.FullName;
				Row.ObjectPresentation = Item.UUID;
				Row.FullName = "User." + Item.Name;
				Row.NodeType = "MetadataObject";
			EndDo;
		EndIf;
	ElsIf NameOfSection = "OtherCommands" Then
		ListOfSections = "Catalogs, DocumentJournals, Documents, Enums, DataProcessors, Reports,
						   |ChartsOfAccounts, ChartsOfCharacteristicTypes, ChartsOfCalculationTypes, ExchangePlans,
						   |InformationRegisters, AccumulationRegisters, CalculationRegisters, AccountingRegisters,
						   |BusinessProcesses, Tasks, FilterCriteria";

		SectionStructure = New Structure(ListOfSections);

		For Each Item In SectionStructure Do
			For Each ObjectXXX In Metadata[Item.Key] Do
				TypeNameXXX = ObjectXXX.FullName();

				If vCheckProperty(ObjectXXX, "Commands") Then
					For Each Item In ObjectXXX.Commands Do
						Row = Table.Add();
						Row.MetadataObject = Item;
						Row.Name = Item.Name;
						Row.Synonym = Item.Presentation();
						Row.FullName = Item.FullName();
						Row.NodeType = "MetadataObject";
					EndDo;
				EndIf;
			EndDo;
		EndDo;

	Else
		For Each Item In Metadata[NameOfSection] Do
			Row = Table.Add();
			Row.MetadataObject = Item;
			Row.Name = Item.Name;
			Row.Synonym = Item.Presentation();
			Row.ObjectPresentation = ?(IsAdditionalPresentation, Item.ObjectPresentation, "");
			Row.FullName = Item.FullName();
			Row.NodeType = "MetadataObject";

			If NameOfSection = "Subsystems" Then
				Row.ThereAreChildren = (Item.Subsystems.Count() <> 0);
			EndIf;
		EndDo;
	EndIf;

	If NameOfSection = "OtherCommands" Then
		Table.Sort("FullName");
	Else
		Table.Sort("Name");
	EndIf;

	For Each Row In Table Do
		_Structure = vFormStructureTreeNode();
		FillPropertyValues(_Structure, Row);
		ResultStructure.ObjectsArray.Add(_Structure);
	EndDo;

	If NameOfSection = "Subsystems" Then
		ResultStructure.NumberOfObjects = vGetNumberOfSubSytems();
	Else
		ResultStructure.NumberOfObjects = ResultStructure.ObjectsArray.Count();
	EndIf;

	Return ResultStructure;
EndFunction

&AtServerNoContext
Function vGetCompositionEnum(Val FullName)
	ObjectsArray = New Array;

	ObjectMD = Metadata.FindByFullName(FullName);
	If ObjectMD <> Undefined Then
		For Each ItemX In ObjectMD.EnumValues Do
			_Structure = vFormStructureTreeNode("EnumValue", ItemX.Name, "", ItemX.Presentation());
			ObjectsArray.Add(_Structure);
		EndDo;
	EndIf;

	Return ObjectsArray;
EndFunction

&AtServerNoContext
Function vGetWebServiceOperations(Val FullName)
	ObjectsArray = New Array;

	ObjectMD = Metadata.FindByFullName(FullName);
	If ObjectMD <> Undefined Then
		For Each ItemX In ObjectMD.Operations Do
			_Structure = vFormStructureTreeNode("MetadataObject", ItemX.Name, ItemX.FullName(), ItemX.Presentation());
			ObjectsArray.Add(_Structure);
		EndDo;
	EndIf;

	Return ObjectsArray;
EndFunction

&AtServerNoContext
Function vGetHTTPServiceMethods(Val FullName)
	ObjectsArray = New Array;

	ObjectMD = Metadata.FindByFullName(FullName);
	If ObjectMD <> Undefined Then
		For Each ItemX In ObjectMD.URLTemplates Do
			_Structure = vFormStructureTreeNode("MetadataObject", ItemX.Name, ItemX.FullName(), ItemX.Presentation());
			ObjectsArray.Add(_Structure);
			_Structure.Insert("Methods", New Array);
			For Each ItemXХХ In ItemX.Methods Do
				StructureXXX = vFormStructureTreeNode("MetadataObject", ItemXХХ.Name, ItemXХХ.FullName(),
					ItemXХХ.Presentation());
				_Structure.Methods.Add(StructureXXX);
			EndDo;
		EndDo;
	EndIf;

	Return ObjectsArray;
EndFunction

&AtServerNoContext
Function vGetCompositionSubsytem(Val FullName)
	StringType = New TypeDescription("String");

	Table = New ValueTable;
	Table.Columns.Add("MetadataObject");
	Table.Columns.Add("Name", StringType);
	Table.Columns.Add("Synonym", StringType);
	Table.Columns.Add("ObjectPresentation", StringType);
	Table.Columns.Add("FullName", StringType);
	Table.Columns.Add("NodeType", StringType);
	Table.Columns.Add("ThereAreChildren", New TypeDescription("Boolean"));

	ObjectMD = Metadata.FindByFullName(FullName);
	If ObjectMD <> Undefined Then
		For Each Item In ObjectMD.Subsystems Do
			Row = Table.Add();
			Row.MetadataObject = Item;
			Row.Name = Item.Name;
			Row.Synonym = Item.Presentation();
			Row.FullName = Item.FullName();
			Row.NodeType = "MetadataObject";
			Row.ThereAreChildren = (Item.Subsystems.Count() <> 0);
		EndDo;
	EndIf;
	Table.Sort("Name");

	ObjectsArray = New Array;

	For Each Row In Table Do
		_Structure = vFormStructureTreeNode();
		FillPropertyValues(_Structure, Row);
		ObjectsArray.Add(_Structure);
	EndDo;

	Return ObjectsArray;
EndFunction

&AtServerNoContext
Procedure vCalculateNumberOfObjectsMD(SectionStructure)
	SetPrivilegedMode(True);

	For Each Item In SectionStructure Do
		NumberOfObjects = 0;
		If Item.Key = "Users" Then
			If vIsAdministratorRights() Then
				NumberOfObjects = InfoBaseUsers.GetUsers().Count();
			EndIf;
		ElsIf Item.Key = "Subsystems" Then
			NumberOfObjects = vGetNumberOfSubSytems();
		ElsIf Item.Key = "OtherCommands" Then
			NumberOfObjects = "???"; //vGetNumberOfSubSytems();
		Else
			NumberOfObjects = Metadata[Item.Key].Count();
		EndIf;
		SectionStructure.Insert(Item.Key, NumberOfObjects);
	EndDo;
EndProcedure

&AtServerNoContext
Function vGetNumberOfSubSytems(Val FirstCall = True, SubSytemMD = Undefined, MapMD = Undefined)
	If FirstCall Then
		MapMD = New Map;

		For Each Item In Metadata.Subsystems Do
			vGetNumberOfSubSytems(False, Item, MapMD);
		EndDo;

		Return MapMD.Count();
	Else
		MapMD.Insert(SubSytemMD, 1);
		For Each Item In SubSytemMD.Subsystems Do
			MapMD.Insert(Item, 1);
			vGetNumberOfSubSytems(False, Item, MapMD);
		EndDo;

		Return 0;
	EndIf;
EndFunction
&AtClient
Function vIsOtherCommand(FullName)
	Return (StrFind(FullName, "Subsystems.") <> 1 And StrFind(FullName, ".Command.") <> 0);
EndFunction

&AtClient
Procedure ObjectTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	CurrentData = Items.ObjectsTree.CurrentData;

	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" Then
			If vIsOtherCommand(CurrentData.FullName) Then
				kShowObjectProperties(Undefined);
				Return;
			EndIf;

			SpecialList = "DataProcessor, Report";
			_Structure = New Structure(SpecialList);

			ObjectTypeMD = Left(CurrentData.FullName, StrFind(CurrentData.FullName, ".") - 1);
			If _Structure.Property(ObjectTypeMD) Then
				kOpenListForm(Undefined);
			Else
				kShowObjectProperties(Undefined);
			EndIf;
		ElsIf CurrentData.NodeType = "Configuration" Then
			kShowObjectProperties(Undefined);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ObjectsTreeOnChange(Item)
	EnableSettingsChangeFlag();
EndProcedure

&AtClient
Procedure kChangeScaleOfForm(Command)
	OpenForm(PathToForms + "DisplayScaleSelectionForm", , ThisForm, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure kOpenDynamicList(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" And Not vIsOtherCommand(CurrentData.FullName) Then
			SectionStructure = New Structure("Catalog, Document, DocumentJournal,ChartOfCharacteristicTypes, ChartOfCalculationTypes, ChartOfAccounts
											 |, InformationRegister, AccumulationRegister, AccountingRegister, CalculationRegister, BusinessProcess, Task");

			NecessaryToProcess = False;
			For Each Item In SectionStructure Do
				If StrFind(CurrentData.FullName, Item.Key) = 1 Then
					NecessaryToProcess = True;
					Break;
				EndIf;
			EndDo;

			If NecessaryToProcess Then
				UT_CommonClient.ОpenDynamicList(CurrentData.FullName);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Function vUpdateTableSettings(Val NodeType, Val Name)
	SetPrivilegedMode(True);

	If NodeType = "Х" Then
		StorageManager = Eval(Name);
	Else
		Return False;
	EndIf;

	If TypeOf(StorageManager) <> Type("StandardSettingsStorageManager") Then
		Return False;
	EndIf;

	If Not vIsAdministratorRights() Then
		CurrentUser = InfoBaseUsers.CurrentUser();
		Filter = New Structure("User", CurrentUser.Name);
	Else
		Filter = Undefined;
	EndIf;

	Try
		Selection = StorageManager.StartChoosing(Filter);
		While Selection.Next() Do
			NewRow = SettingsTable.Add();
			NewRow.SettingsKey = Selection.SettingsKey;
			NewRow.ObjectKey = Selection.ObjectKey;
			NewRow.User = Selection.User;
			NewRow.Presentation = Selection.Presentation;
		EndDo;
	Except
		Message(BriefErrorDescription(ErrorInfo()));
	EndTry;

	Return True;
EndFunction

&AtServer
Procedure vDeleteSettings(Val Name, Val RowArray)
	SetPrivilegedMode(True);

	Try
		StorageManager = Eval(Name);

		For Each Item In RowArray Do
			Row = SettingsTable.FindByID(Item);
			If Row <> Undefined Then
				StorageManager.Delete(Row.ObjectKey, Row.SettingsKey, Row.User);
				SettingsTable.Delete(Row);
			EndIf;
		EndDo;
	Except
		Message(BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtClient
Procedure SettingsTableBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure SettingsTableBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	If Not IsBlankString(_NameOfSettingsManager) Then
		StructureOfParameters = New Structure;
		StructureOfParameters.Insert("RowArray", New FixedArray(Item.SelectedRows));
		vShowQueryBox(NStr("ru = 'Отмеченные настройки будут удалены. Продолжить?';en = 'The marked settings will be deleted. Continue?'"), "SettingsTableBeforeDeleteRowNext",
			StructureOfParameters);
	EndIf;
EndProcedure

&AtClient
Procedure SettingsTableBeforeDeleteRowNext(Result, Parameters) Export
	If Result = DialogReturnCode.Yes Then
		vDeleteSettings(_NameOfSettingsManager, Parameters.RowArray);
		vUpdateHeadersSettings();
	EndIf;
EndProcedure

&AtClient
Procedure kUpdateSettingsTable(Command)
	CurrentData = Items.SettingsTree.CurrentData;

	If CurrentData <> Undefined And CurrentData.NodeType = "Х" Then
		SettingsTable.Clear();

		If Not vUpdateTableSettings(CurrentData.NodeType, CurrentData.Name) Then
			CurrentData.NodeType = "-";
			CurrentData.Presentation = CurrentData.Name + Nstr("ru = ' (не поддерживается)';en = ' (not supported)'");
		EndIf;

		_NameOfSettingsManager = CurrentData.Name;

		vUpdateHeadersSettings();
	EndIf;
EndProcedure

&AtClient
Procedure vUpdateHeadersSettings()
	Items.DecorationSettings.Title = _NameOfSettingsManager + " (" + SettingsTable.Count() + NStr("ru = ' шт.';en = 'pcs.'") + ")";
EndProcedure



// Page Service

&AtServer
Procedure vFillServiceTree()
	Template = vGetProcessor().GetTemplate("ServiceTemplate");
	If Template = Undefined Then
		Template = New SpreadsheetDocument;
	EndIf;

	PropertyStructure = New Structure("Enabled, Presentation, NodeType, Name, Comment, AvailabilityExpression",
		True);

	TreeRoot = ServiceTree;
	TreeNode = ServiceTree;

	For LineNumber = 2 To Template.TableHeight Do
		PropertyStructure.Presentation = TrimAll(Template.Area(LineNumber, 1).Text);

		If Not IsBlankString(PropertyStructure.Presentation) Then
			PropertyStructure.NodeType = TrimAll(Template.Area(LineNumber, 2).Text);
			PropertyStructure.Name = TrimAll(Template.Area(LineNumber, 3).Text);
			PropertyStructure.AvailabilityExpression = TrimAll(Template.Area(LineNumber, 4).Text);
			PropertyStructure.Comment = TrimAll(Template.Area(LineNumber, 5).Text);

			If PropertyStructure.NodeType = "G" Then
				TreeNode = TreeRoot.GetItems().Add();
				FillPropertyValues(TreeNode, PropertyStructure);
				TreeNode.IsGroup = True;
				TreeNode.Picture = -1;
			Else
				TreeLine = TreeNode.GetItems().Add();
				FillPropertyValues(TreeLine, PropertyStructure);
				If Not IsBlankString(PropertyStructure.AvailabilityExpression) Then
					TreeLine.Enabled = Eval(PropertyStructure.AvailabilityExpression);
				EndIf;
				If Not TreeLine.Enabled Then
					TreeLine.Presentation = TreeLine.Presentation +Nstr("ru = '(не доступно)';en = 'not available'") ;
				EndIf;

				If TreeLine.Name = "ExclusiveMode" Then
					TreeLine.Presentation = ?(_FormContext.ExclusiveMode, Nstr("ru = 'Отключить монопольный режим';en = 'Turn off exclusive mode'"),
						NStr("ru = 'Установить монопольный режим';en = 'Set exclusive mode'"));
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ServiceTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	TreeLine = ServiceTree.FindByID(SelectedRow);
	If TreeLine <> Undefined Then
		If Not TreeLine.IsGroup Then
			StandardProcessing = False;
			If TreeLine.Enabled Then
				Try
					vProcessServiceCommand(TreeLine);
				Except
				EndTry;
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure vProcessServiceCommand(TreeLine)
	If TreeLine.Name = "SubsystemVersions" Then
		OpenForm("InformationRegister.SubsystemsVersions.ListForm");
	ElsIf TreeLine.Name = "RefreshReusableValues" Then
		RefreshReusableValues();
	ElsIf TreeLine.Name = "ClearFavorites" Then
		vShowQueryBox(Nstr("ru = 'Избранное будет очищено. Продолжить?';en = 'The favorites will clear. Continue?'"), "vClearFavorites");
	ElsIf TreeLine.Name = "DisplayScale" Then
		kChangeScaleOfForm(Undefined);
	ElsIf TreeLine.Name = "SetSessionsLock" Then
		OpenForm(PathToForms + "SessionLockForm", , ThisForm, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	ElsIf TreeLine.Name = "ExclusiveMode" Then
		vSetExclusiveMode(_FormContext);
		TreeLine.Presentation = ?(_FormContext.ExclusiveMode, NStr("ru = 'Отключить монопольный режим';en = 'Disable exclusive mode'"),
			NStr("ru = 'Установить монопольный режим';en = 'Set exclusive mode'"));
	ElsIf TreeLine.Name = "Run1C" Then
#If WebClient Then
		vOperationNotSupportedForWebClient();
#Else
			OpenForm(PathToForms + "Launch1CForm", , ThisForm, , , , ,
				FormWindowOpeningMode.LockOwnerWindow);
#EndIf
	ElsIf
	TreeLine.Name = "1CDesigner" Then
		vLaunch1C(1);
	ElsIf TreeLine.Name = "OrdinaryСlient" Then
		vLaunch1C(2);
	ElsIf TreeLine.Name = "ThickСlient" Then
		vLaunch1C(3);
	ElsIf TreeLine.Name = "ThinСlient" Then
		vLaunch1C(4);
	ElsIf TreeLine.Name = "WinStartMenu" Then
		vRunOSCommand("%ProgramData%\Microsoft\Windows\Start Menu\Programs");
	ElsIf TreeLine.Name = "WinAppData" Then
		vRunOSCommand("%AppData%");
	EndIf;
EndProcedure

&AtClient
Procedure vClearFavorites(Result, AdditionalParameters = Undefined) Export
	If Result = DialogReturnCode.Yes Then
		vClearFavoritesServer();
	EndIf;
EndProcedure

&AtServerNoContext
Procedure vClearFavoritesServer()
	Favorites = SystemSettingsStorage.Load("Common/UserWorkFavorites");
	Favorites.Clear();
	SystemSettingsStorage.Save("Common/UserWorkFavorites", "", Favorites);
EndProcedure

&AtServerNoContext
Procedure vSetExclusiveMode(_FormContext)
	Try
		SetExclusiveMode(Not ExclusiveMode());
		_FormContext.ExclusiveMode = ExclusiveMode();
	Except
		Message(BriefErrorDescription(ErrorInfo()));
	EndTry;
EndProcedure

&AtClient
Procedure kRunServiceCommand(Command)
	CurrentData = Items.ServiceTree.CurrentData;
	ServiceTreeSelection(Items.ServiceTree, Items.ServiceTree.CurrentRow, Undefined, False);
EndProcedure

&AtClient
Procedure _DisplayObjectsRightsOnChange(Item)
	Items.ObjectRightPages.Visible = _DisplayObjectsRights;

	If Not _DisplayObjectsRights And Not IsBlankString(_StorageAddresses.RolesAndUsers) Then
		DeleteFromTempStorage(_StorageAddresses.RolesAndUsers);
		_StorageAddresses.RolesAndUsers = "";
	EndIf;
EndProcedure

&AtClient
Procedure ObjectsTreeOnActivateRow(Item)
	If _DisplayObjectsRights Then
		AttachIdleHandler("ProcessingActivationOfNavigatorLine", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure ProcessingActivationOfNavigatorLine()
	CurrentData = Items.ObjectsTree.CurrentData;
	TypeMD = "";
	If CurrentData <> Undefined And CurrentData.NodeType = "MetadataObject" Then
		If CurrentData.FullName = mCurrentTreeObject Then
			Return;
		EndIf;

		mCurrentTreeObject = CurrentData.FullName;

		For Each Row In VerifiableRightsTable.FindRows(New Structure("Mark", True)) Do
			Row.Mark = False;
		EndDo;

		If StrFind(CurrentData.FullName, ".Command.") <> 0 Then
			TypeMD = "CommonCommand";
		Else
			TypeMD = Left(CurrentData.FullName, StrFind(CurrentData.FullName, ".") - 1);
		EndIf;

		If TypeMD = "WebService" And StrFind(CurrentData.FullName, ".Operation.") <> 0 Then
			TypeMD = "WebService.Property";
		ElsIf TypeMD = "HTTPService" And StrFind(CurrentData.FullName, ".URLTemplates.") <> 0 And StrFind(
			CurrentData.FullName, ".Method.") <> 0 Then
			TypeMD = "HTTPService.Property";
		EndIf;

		For Each Row In VerifiableRightsTable.FindRows(New Structure("MetadataObject", TypeMD)) Do
			Row.Mark = True;
		EndDo;
	Else
		mCurrentTreeObject = "";

		For Each Row In VerifiableRightsTable.FindRows(New Structure("Mark", True)) Do
			Row.Mark = False;
		EndDo;
	EndIf;

	RolesWithAccessTable.Clear();
	UsersWithAccessTable.Clear();

	If CurrentData <> Undefined And CurrentData.NodeType = "MetadataObject" Then

		If StrFind(CurrentData.FullName, "Role.") = 1 Then
			If Items.ObjectRightPages.CurrentPage <> Items.UsersLine Then
				Items.ObjectRightPages.CurrentPage = Items.UsersLine;
			EndIf;
			RightName = "Х";
		ElsIf StrFind(CurrentData.FullName, "User.") = 1 Then
			If Items.ObjectRightPages.CurrentPage <> Items.RolesLine Then
				Items.ObjectRightPages.CurrentPage = Items.RolesLine;
			EndIf;
			RightName = "Х";
		Else
			If TypeMD = "" Then
				TypeMD = Left(CurrentData.FullName, StrFind(CurrentData.FullName, ".") - 1);
			EndIf;
			FoundLines = VerifiableRightsTable.FindRows(New Structure("MetadataObject", TypeMD));
			If FoundLines.Count() = 0 Then
				vSetHeadersOfRightsTables();
				Return;
			EndIf;
			RightName = FoundLines[0].Right;
			If RightName = "" Then
				vSetHeadersOfRightsTables();
				Return;
			EndIf;
		EndIf;

		_Structure = vGetAccessRightsToObject(RightName, CurrentData.FullName, _StorageAddresses.RolesAndUsers,
			UUID);
		If _Structure.HaveData Then
			For Each Item In _Structure.Roles Do
				FillPropertyValues(RolesWithAccessTable.Add(), Item);
			EndDo;

			For Each Item In _Structure.Users Do
				FillPropertyValues(UsersWithAccessTable.Add(), Item);
			EndDo;
		EndIf;
	EndIf;

	vSetHeadersOfRightsTables();
EndProcedure

&AtClient
Procedure vSetHeadersOfRightsTables()
	FoundLines = VerifiableRightsTable.FindRows(New Structure("Mark", True));
	If FoundLines.Count() = 0 Then
		RightName = "";
	Else
		RightName = FoundLines[0].Right + ": ";
	EndIf;

	RoleTitle = RightName + NStr("ru = 'Роли, имеющие доступ';en = 'Roles that have access'")+" (";
	UsersTitle = RightName + NStr("ru = 'Пользователи, имеющие доступ';en = 'Users that have access'")+" (";

	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined And CurrentData.NodeType = "MetadataObject" Then
		If StrFind(CurrentData.FullName, "Role.") = 1 Then
			RoleTitle = "";
			UsersTitle = NStr("ru = 'Пользователи, имеющие данную роль';en = 'Users who have this role'")+" (";
		ElsIf StrFind(CurrentData.FullName, "User.") = 1 Then
			RoleTitle = NStr("ru = 'Роли данного пользователя';en = 'Roles of this user'")+" (";
			UsersTitle = "";
		EndIf;
	EndIf;

	If IsBlankString(RoleTitle) Then
		Items.RolesDecoration.Title = NStr("ru = 'Для заданного объекта не используются';en = 'Not used for the specified object'");
	Else
		Items.RolesDecoration.Title = RoleTitle + RolesWithAccessTable.Count() + NStr("ru = ' шт.)';en = 'pcs.)'");
	EndIf;

	If IsBlankString(UsersTitle) Then
		Items.UsersDecoration.Title = NStr("ru = 'Для заданного объекта не используются';en = 'Not used for the specified object'");
	Else
		Items.UsersDecoration.Title = UsersTitle + UsersWithAccessTable.Count()
			+ NStr("ru = ' шт.)';en = 'pcs.)'");
	EndIf;

EndProcedure

&AtServerNoContext
Function vGetAccessRightsToObject(Val RightName, Val FullName, AddressOfRolesAndUsersTable,
	Val UUID)
	ResultStructure = New Structure("HaveData, Roles, Users", False);

	RoleTable = New ValueTable;
	RoleTable.Columns.Add("Name", New TypeDescription("String"));
	RoleTable.Columns.Add("Synonym", New TypeDescription("String"));

	UsersTable = New ValueTable;
	UsersTable.Columns.Add("Name", New TypeDescription("String"));
	UsersTable.Columns.Add("FullName", New TypeDescription("String"));
	If StrFind(FullName, ".Command.") <> 0 Then
		TypeMD = "CommonCommand";
	Else
		TypeMD = Left(FullName, StrFind(FullName, ".") - 1);
	EndIf;

	If TypeMD <> "User" Then
		ObjectMD = Metadata.FindByFullName(FullName);

		If ObjectMD = Undefined Then
			Return ResultStructure;
		EndIf;
	EndIf;

	IsOrdinaryMode = (RightName <> "Х");

	If IsOrdinaryMode And IsBlankString(RightName) Then
		Return ResultStructure;
	EndIf;
	If IsOrdinaryMode Then
		For Each Item In Metadata.Roles Do
			If AccessRight(RightName, ObjectMD, Item) Then
				FillPropertyValues(RoleTable.Add(), Item);
			EndIf;
		EndDo;

		RoleTable.Sort("Name");
	EndIf;
	If IsBlankString(AddressOfRolesAndUsersTable) Then
		__RolesAndUsersTable = New ValueTable;
		__RolesAndUsersTable.Columns.Add("RoleName", New TypeDescription("String"));
		__RolesAndUsersTable.Columns.Add("UserName", New TypeDescription("String"));
		__RolesAndUsersTable.Columns.Add("FullUserName", New TypeDescription("String"));

		For Each User In InfoBaseUsers.GetUsers() Do
			For Each Role In User.Roles Do
				NewRow = __RolesAndUsersTable.Add();
				NewRow.RoleName = Role.Name;
				NewRow.UserName = User.Name;
				NewRow.FullUserName = User.FullName;
			EndDo;
		EndDo;

		__RolesAndUsersTable.Indexes.Add("RoleName");
		__RolesAndUsersTable.Indexes.Add("UserName");
		AddressOfRolesAndUsersTable = PutToTempStorage(__RolesAndUsersTable, UUID);
	Else
		__RolesAndUsersTable = GetFromTempStorage(AddressOfRolesAndUsersTable);
	EndIf;
	If IsOrdinaryMode Then
		RoleStructure = New Structure("RoleName");
		UserStructure = New Structure("Name");

		For Each Row In RoleTable Do
			RoleStructure.RoleName = Row.Name;
			For Each LineX In __RolesAndUsersTable.FindRows(RoleStructure) Do
				UserStructure.Name = LineX.UserName;
				If UsersTable.FindRows(UserStructure).Count() = 0 Then
					NewRow = UsersTable.Add();
					NewRow.Name = LineX.UserName;
					NewRow.FullName = LineX.FullUserName;
				EndIf;
			EndDo;
		EndDo;

		UsersTable.Sort("Name");
	EndIf;

	If Not IsOrdinaryMode Then
		If TypeMD = "Role" Then
			RoleName = Mid(FullName, StrFind(FullName, ".") + 1);
			For Each Row In __RolesAndUsersTable.FindRows(New Structure("RoleName", RoleName)) Do
				NewRow = UsersTable.Add();
				NewRow.Name = Row.UserName;
				NewRow.FullName = Row.FullUserName;
			EndDo;
			UsersTable.Sort("Name");

		ElsIf TypeMD = "User" Then
			UserName = Mid(FullName, StrFind(FullName, ".") + 1);
			For Each Row In __RolesAndUsersTable.FindRows(New Structure("UserName", UserName)) Do
				NewRow = RoleTable.Add();
				NewRow.Name = Row.RoleName;
			EndDo;
			RoleTable.Sort("Name");
		EndIf;
	EndIf;

	ResultStructure.HaveData = True;
	ResultStructure.Roles = New Array;
	ResultStructure.Users = New Array;

	For Each Row In RoleTable Do
		_Structure = New Structure("Name, Synonym");
		FillPropertyValues(_Structure, Row);
		ResultStructure.Roles.Add(_Structure);
	EndDo;

	For Each Row In UsersTable Do
		_Structure = New Structure("Name, FullName");
		FillPropertyValues(_Structure, Row);
		ResultStructure.Users.Add(_Structure);
	EndDo;

	Return ResultStructure;
EndFunction

&AtClient
Procedure vFillAccessRights()
	For Each Item In mDescriptionAccessRights Do
		NewRow = VerifiableRightsTable.Add();
		NewRow.MetadataObject = Item.Key;
		Position = StrFind(Item.Value, ",");
		NewRow.Right = ?(Position = 0, Item.Value, Left(Item.Value, Position - 1));
	EndDo;

	VerifiableRightsTable.Sort("MetadataObject");
EndProcedure

&AtClient
Procedure VerifiableRightsTableOnStartEdit(Item, NewLine, Copy)
	CurrentData = Item.CurrentData;
	_Structure = New Structure(mDescriptionAccessRights[CurrentData.MetadataObject]);

	ElemF = Items.VerifiableRightsTableRight;
	ElemF.ChoiceList.Clear();
	For Each Item In _Structure Do
		ElemF.ChoiceList.Add(Item.Key);
	EndDo;
EndProcedure

&AtClient
Procedure RolesWithAccessTableSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;

	CurrentData = Items.RolesWithAccessTable.CurrentData;
	If CurrentData <> Undefined Then
		pFullName = "Role." + CurrentData.Name;
		StructureOfParameters = New Structure("FullName, PathToForms, _StorageAddresses, DescriptionOfAccessRights", pFullName,
			PathToForms, _StorageAddresses, mDescriptionAccessRights);
		StructureOfParameters.Insert("ProcessingSettings", vFormStructureOfObjectPropertiesFormSettings());
		OpenForm(PathToForms + "PropertiesForm", StructureOfParameters, , pFullName, , , ,
			FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure


&AtClient
Procedure UsersWithAccessTableSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;

	CurrentData = Items.UsersWithAccessTable.CurrentData;
	If CurrentData <> Undefined Then
		pUserID = vGetUserId(CurrentData.Name);

		If Not IsBlankString(pUserID) Then
			pStructure = New Structure("WorkMode, DBUserID", 0, pUserID);
			OpenForm(PathToForms + "InfoBaseUserForm", pStructure, , , , , ,
				FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure vFormDescriptionOfAccessRights()
	ListA = "Read, Insert, Update, Delete, View, Edit";
	ListB = "Read, Update, View, Edit, TotalsManagement";

	mDescriptionAccessRights = New Map;
	mDescriptionAccessRights.Insert("Subsystems", "View");
	mDescriptionAccessRights.Insert("SessionParameter", "Receive, Set");
	mDescriptionAccessRights.Insert("CommonAttribute", "View, Edit");
	mDescriptionAccessRights.Insert("ExchangePlan", ListA);
	mDescriptionAccessRights.Insert("FilterCriterion", "View");
	mDescriptionAccessRights.Insert("CommonForm", "View");
	mDescriptionAccessRights.Insert("CommonCommand", "View");
	mDescriptionAccessRights.Insert("OtherCommand", "View");
	mDescriptionAccessRights.Insert("WebService.Property", "Use");
	mDescriptionAccessRights.Insert("HTTPService.Property", "Use");
	mDescriptionAccessRights.Insert("Constant", "Read, Update, View, Edit");
	mDescriptionAccessRights.Insert("Catalog", ListA);
	mDescriptionAccessRights.Insert("Document", ListA + ", Posting, UndoPosting");
	mDescriptionAccessRights.Insert("Sequence", "Read, Update");
	mDescriptionAccessRights.Insert("DocumentJournal", "Read, View");
	mDescriptionAccessRights.Insert("Report", "Use, View");
	mDescriptionAccessRights.Insert("DataProcessor", "Use, View");
	mDescriptionAccessRights.Insert("ChartOfCharacteristicTypes", ListA);
	mDescriptionAccessRights.Insert("ChartOfCalculationTypes", ListA);
	mDescriptionAccessRights.Insert("ChartOfAccounts", ListA);
	mDescriptionAccessRights.Insert("InformationRegister", ListB);
	mDescriptionAccessRights.Insert("AccumulationRegister", ListB);
	mDescriptionAccessRights.Insert("AccountingRegister", ListB);
	mDescriptionAccessRights.Insert("CalculationRegister", "Read, Update, View, Edit");
	mDescriptionAccessRights.Insert("BusinessProcess", ListA + ", Start");
	mDescriptionAccessRights.Insert("Task", ListA + ", Execute");

EndProcedure

&AtClient
Procedure kCalculateObjectsNumber(Command)
	CurrentData = Items.ObjectsTree.CurrentData;

	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" Then
			_List = "Sequence, ExchangePlan, Catalog, Document, DocumentJournal, ChartOfCharacteristicTypes
					   |, ChartOfCalculationTypes, ChartOfAccounts, InformationRegister, AccumulationRegister, AccountingRegister, CalculationRegister, BusinessProcess, Task";

			_Structure = New Structure(_List);
			TypeMD = Left(CurrentData.FullName, StrFind(CurrentData.FullName, ".") - 1);

			If Not _Structure.Property(TypeMD) Then
				Return;
			EndIf;

			ObjectsArray = New Array;

			_Structure = New Structure("FullName, NumberOfObjects", CurrentData.FullName);
			ObjectsArray.Add(_Structure);

			TreeParent = CurrentData.GetParent();

			TreeParent.NumberOfObjects = TreeParent.NumberOfObjects - CurrentData.NumberOfObjects;

			vCalculateNumberOfObjects(ObjectsArray);
			CurrentData.NumberOfObjects = ObjectsArray[0].NumberOfObjects;

			TreeParent.NumberOfObjects = TreeParent.NumberOfObjects + CurrentData.NumberOfObjects;

		ElsIf CurrentData.NodeType = "SectionMD" Then
			TreeLines = CurrentData.GetItems();
			If TreeLines.Count() = 1 And IsBlankString(TreeLines[0].NodeType) Then
				Return;
			EndIf;

			_List = "Sequences, ExchangePlans, Catalogs, Documents, DocumentJournals, ChartsOfCharacteristicTypes
					   |, ChartsOfCalculationTypes, ChartsOfAccounts, InformationRegisters, AccumulationRegisters, AccountingRegisters, CalculationRegisters, BusinessProcesses, Tasks";

			_Structure = New Structure(_List);
			Position = StrFind(CurrentData.Name, " ");
			If Position = 0 Then
				NameOfSection = CurrentData.Name;
			Else
				NameOfSection = Left(CurrentData.Name, Position - 1);
			EndIf;

			If Not _Structure.Property(NameOfSection) Then
				Return;
			EndIf;

			ObjectsArray = New Array;

			For Each Row In TreeLines Do
				If Row.NodeType = "MetadataObject" Then
					_Structure = New Structure("ID, FullName, NumberOfObjects",
						Row.GetID(), Row.FullName);
					ObjectsArray.Add(_Structure);
				EndIf;
			EndDo;

			vCalculateNumberOfObjects(ObjectsArray);

			ObjectCount = 0;
			For Each Row In ObjectsArray Do
				TreeLine = ObjectsTree.FindByID(Row.ID);
				If TreeLine <> Undefined Then
					ObjectCount= ObjectCount + Row.NumberOfObjects;
					TreeLine.NumberOfObjects = Row.NumberOfObjects;
				EndIf;
			EndDo;
			CurrentData.NumberOfObjects = ObjectCount;

		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function vCalculateNumberOfObjects(ObjectsArray)
	SetPrivilegedMode(True);

	pUseAttempt = Not PrivilegedMode() And Not vIsAdministratorRights();

	For Each Item In ObjectsArray Do
		Query = New Query;
		Query.Text = "SELECT
					   |	COUNT(*) AS NumberOfObjects
					   |FROM
					   |	" + Item.FullName + " AS DBTable";

		If pUseAttempt Then
			Try
				Selection = Query.Execute().Select();
				Item.NumberOfObjects = ?(Selection.Next(), Selection.NumberOfObjects, 0);
			Except
				Item.NumberOfObjects = 0;
			EndTry;
		Else
			Selection = Query.Execute().Select();
			Item.NumberOfObjects = ?(Selection.Next(), Selection.NumberOfObjects, 0);
		EndIf;

	EndDo;

	Return True;
EndFunction

&AtClient
Procedure _ShowStandartSettingsOnChange(Item)
	Items.DefaultSettingsPage.Visible = _ShowStandardSettings;
EndProcedure

&AtClient
Procedure _ShowTablesAndIndexesDBOnChange(Item)
	Items.StorageStructurePage.Visible = _ShowTablesAndIndexesDB;
EndProcedure


// working with the section "Favorites..."
&AtClient
Procedure _AddToFavorites(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" Then
			TreeLine = ObjectsTree.FindByID(mFavoriteID).GetItems().Add();
			FillPropertyValues(TreeLine, CurrentData);
			EnableSettingsChangeFlag();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _DeleteFromFavorites(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		If Not IsBlankString(CurrentData.FullName) Then
			TreeLines = ObjectsTree.FindByID(mFavoriteID).GetItems();
			For Each TreeLine In TreeLines Do
				If TreeLine.FullName = CurrentData.FullName Then
					TreeLines.Delete(TreeLine);
					EnableSettingsChangeFlag();
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure EnableSettingsChangeFlag()
	_DateOfSettingsChange = CurrentDate();
EndProcedure

&AtClient
Procedure _ClearFavorites(Command)
	ObjectsTree.FindByID(mFavoriteID).GetItems().Clear();
	EnableSettingsChangeFlag();
EndProcedure

&AtClient
Procedure _OderFavorites(Command)
	vOrganizeFavorites(); // bad way

	For Each TreeLine In ObjectsTree.GetItems() Do
		If TreeLine.FullName = "Favorites" Then
			mFavoriteID = TreeLine.GetID();
			Break;
		EndIf;
	EndDo;

	EnableSettingsChangeFlag();
EndProcedure

&AtServer
Procedure vOrganizeFavorites()
	pTree = FormAttributeToValue("ObjectsTree");
	pTree.Rows.Find("Favorites", "FullName", False).Rows.Sort("FullName");
	ValueToFormAttribute(pTree, "ObjectsTree");
EndProcedure
&AtClient
Procedure _OpenObjectsEditor(Command)
	ParamsStructure = New Structure;
	ParamsStructure.Insert("mObjectRef", Undefined);
	OpenForm("DataProcessor.UT_ObjectsAttributesEditor.Form", ParamsStructure, , CurrentDate());
EndProcedure

&AtClient
Procedure _UpdateNumberingOfObjects(Command)
	CurrentData = Items.ObjectsTree.CurrentData;
	If CurrentData <> Undefined Then
		If CurrentData.NodeType = "MetadataObject" Or CurrentData.NodeType = "Configuration" Then
			If Not vIsAdministratorRights() Then
				vShowMessageBox(NStr("ru = 'Нет прав на выполнение операции!';en = 'No rights to perform the operation!'"));
				Return;
			EndIf;

			pText = ?(CurrentData.NodeType = "Configuration", NStr("ru = 'Нумерация всех объектов будет обновлена. Продолжить?';en = 'The numbering of all objects will be updated. Continue?'"),
				NStr("ru = 'Нумерация объекта будет обновлена. Продолжить?';en = 'The numbering the object will be updated. Continue?'"));
			ShowQueryBox(New NotifyDescription("vUpdateNumberOfObjectsResponse", ThisForm, CurrentData.FullName),
				pText, QuestionDialogMode.YesNoCancel, 20);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _UpdateNumberingOfAllObjects(Command)
	pText = NStr("ru = 'Нумерация всех объектов будет обновлена. Продолжить?';en = 'The numbering of all objects will be updated. Continue?'");
	ShowQueryBox(New NotifyDescription("vUpdateNumberOfObjectsResponse", ThisForm, "Configuration"), pText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure vUpdateNumberOfObjectsResponse(QuestionResult, AdditionalParameters = Undefined) Export
	If QuestionResult = DialogReturnCode.Yes Then
		vUpdateNumberOfObjects(AdditionalParameters);
	EndIf;
EndProcedure

&AtServerNoContext
Function vUpdateNumberOfObjects(Val FullName)
	If FullName = "Configuration" Then
		Try
			RefreshObjectsNumbering();
		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;

	ElsIf StrFind(FullName, ".") <> 0 Then
		ObjectMD = Metadata.FindByFullName(FullName);

		If ObjectMD <> Undefined Then
			Try
				RefreshObjectsNumbering(ObjectMD);
			Except
				Message(BriefErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndIf;

	Return True;
EndFunction

// working with the database storage structure (tables and indexes)
&AtClient
Procedure _FillInSchema(Command)
	_Indexes.Clear();
	_Tables.Clear();

	vFillInSX();

	Items._IndexesPage.Title = NStr("ru = 'Все индексы БД (';en = 'All indexes of DB ('") + _Indexes.Count() + ")";
	Items.TablePage.Title = NStr("ru = 'Все таблицы БД (';en = 'All tables  of DB ('") + _Tables.Count() + ")";
EndProcedure

&AtServer
Procedure vFillInSX()
	ResultTable = GetDBStorageStructureInfo( , Not _ShowStorageStructureInTermsOf1C);

	For Each Row In ResultTable Do
		NewRow = _Tables.Add();
		FillPropertyValues(NewRow, Row);

		If NewRow.TableName = "" Then
			NewRow.TableName = NStr("ru = '<не задано>'; en = '<not set>'");
		EndIf;
		If NewRow.Metadata = "" Then
			NewRow.Metadata = NStr("ru = '<не задано>'; en = '<not set>'");
		EndIf;    
		

		For Each LineX In Row.Indexes Do
			NewRow = _Indexes.Add();
			NewRow.IndexName = LineX.StorageIndexName;
			FillPropertyValues(NewRow, Row, "TableName, Metadata");
			If NewRow.Metadata = "" Then
				NewRow.Metadata = NStr("ru = '<не задано>'; en = '<not set>'");
			EndIf;
		EndDo;
	EndDo;

EndProcedure

&AtClient
Procedure _TablesSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	kShowObjectProperties(Undefined);
EndProcedure

&AtClient
Procedure _IndexesSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	kShowObjectProperties(Undefined);
EndProcedure

&AtClient
Procedure _MoveToTableFromIndex(Command)
	CurrentData = Items._Indexes.CurrentData;
	If CurrentData <> Undefined Then
		Array = _Tables.FindRows(New Structure("TableName", CurrentData.TableName));
		If Array.Count() <> 0 Then
			String = Array[0].GetID();
			CurrentRow = _Tables.FindByID(String);
			If CurrentRow <> Undefined Then
				Items._Tables.CurrentRow = String;
				Items.TableAndIndexesGrpip.CurrentPage = Items.TablePage;
			EndIf;
		EndIf;
	EndIf;
EndProcedure


// Work with database users
&AtClient
Procedure _FillInDBUsersList(Command)
	_DBUserList.Clear();

	pFieldList = "OpenIDAuthentication, AuthenticationOS, StandartAuthentication, Name, PasswordIsSet,
					 |StandartAuthentication, FullName, OSUser, LaunchMode, UUID,
					 |ListOfRoles";

	pArray = vGetDataBaseUsers(pFieldList, _ShowUserRolesList);
	For Each Item In pArray Do
		FillPropertyValues(_DBUserList.Add(), Item);
	EndDo;

	_DBUserList.Sort("Name");

	If Items._DBUserListListOfRoles.Visible <> _ShowUserRolesList Then
		Items._DBUserListListOfRoles.Visible = _ShowUserRolesList;
	EndIf;

	Items.DBUsers.Title = "Users (" + pArray.Count() + ")";
EndProcedure

&AtServerNoContext
Function vGetDataBaseUsers(Val pFieldList, Val pFillRolesList = False)
	pResult = New Array;

	For Each Item In InfoBaseUsers.GetUsers() Do
		pStructure = New Structure(pFieldList);
		FillPropertyValues(pStructure, Item);

		If pFillRolesList Then
			pRolesList = New ValueList;
			For Each pRole In Item.Roles Do
				pRolesList.Add(pRole.Name);
			EndDo;
			pRolesList.SortByValue();

			pRolesString = "";
			For Each pRole In pRolesList Do
				pRolesString = pRolesString + ", " + pRole.Value;
			EndDo;
			pStructure.ListOfRoles = Mid(pRolesString, 2);
		EndIf;

		pResult.Add(pStructure);
	EndDo;

	Return pResult;
EndFunction

&AtClient
Procedure _DBUserListSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;

	CurrentData = _DBUserList.FindByID(SelectedRow);
	If CurrentData <> Undefined Then
		pStructure = New Structure("WorkMode, DBUserID", 0, CurrentData.UUID);
		OpenForm(PathToForms + "InfoBaseUserForm", pStructure, , , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure _DBUserListBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	Cancel = True;

	If Copy Then
		CurrentData = Item.CurrentData;
		If CurrentData <> Undefined Then
			pStructure = New Structure("WorkMode, DBUserID", 2, CurrentData.UUID);
			OpenForm(PathToForms + "InfoBaseUserForm", pStructure, , , , , ,
				FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	Else
		pStructure = New Structure("WorkMode", 1);
		OpenForm(PathToForms + "InfoBaseUserForm", pStructure, , , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtClient
Procedure _DBUserListBeforeDeleteRow(Item, Cancel)
	Cancel = True;

	pSelectedLines = Item.SelectedRows;
	pCount = pSelectedLines.Count();

	If pCount = 0 Then
		Return;
	ElsIf pCount = 1 Then
		pText = StrTemplate (NSTR("ru = 'Отмеченные пользователи (%1 шт) будут удалены из информационной базы! 
		|Продолжить?'; en = 'Selected users  (%1 pc) will be deleted from database! 
		|Continue?'"),_DBUserList.FindByID(pSelectedLines[0]).Name)                 			   
	Else
		pText = StrTemplate (NSTR("ru = 'Отмеченные пользователи (%1 шт) будут удалены из информационной базы! 
		|Продолжить?'; en = 'Selected users  (%1 pc) will be deleted from database! 
		|Continue?'"),pCount)      				   
	EndIf;

	vShowQueryBox(pText, "vDeleteDataBaseUsersResponse", pSelectedLines);
EndProcedure

&AtClient
Procedure vDeleteDataBaseUsersResponse(Response, pSelectedLines) Export
	If Response = DialogReturnCode.Yes Then
		pArray = New Array;
		For Each Row In pSelectedLines Do
			CurrentData = _DBUserList.FindByID(Row);
			If CurrentData <> Undefined Then
				pArray.Add(CurrentData.UUID);
			EndIf;
		EndDo;

		If pArray.Count() <> 0 Then
			pDeletedArray = vDeleteDataBaseUsers(pArray);
			For Each Item In pDeletedArray Do
				For Each LineX In _DBUserList.FindRows(New Structure("UUID",
					Item)) Do
					_DBUserList.Delete(LineX);
				EndDo;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServerNoContext
Function vDeleteDataBaseUsers(Val pIdentifersArray)
	pResult = New Array;

	pCurrentUser = InfoBaseUsers.CurrentUser();

	For Each Item In pIdentifersArray Do
		Try
			userUUID = New UUID(Item);

			vUser = InfoBaseUsers.FindByUUID(userUUID);
			If vUser = Undefined Or (pCurrentUser <> Undefined
				And pCurrentUser.UUID = userUUID) Then
				Continue;
			EndIf;

			vUser.Delete();
			pResult.Add(Item);
		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;

	Return pResult;
EndFunction


// work with sessions
&AtClient
Procedure _SetSessionsLock(Command)
	OpenForm(PathToForms + "SessionLockForm", , ThisForm, , , , ,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure _FillInSessionsList(Command)
	_SessionList.Clear();

	pFieldList = "CurrentSession, ComputerName, ApplicationName, ApplicationPresentation, SessionStart, SessionNumber, ConnectionNumber, User, DBUserID,
					 |MethodName, Key, Start, End, Name, Placement, ScheduledJob, State, BackgroundJobID";

	pArray = vGetSessions(pFieldList);

	For Each Item In pArray Do
		FillPropertyValues(_SessionList.Add(), Item);
	EndDo;

	_SessionList.Sort("SessionStart");

	Items.SessionsGroup.Title = NStr("ru = 'Сеансы информационной базы (';en = 'Sessions of the information base ('") + pArray.Count() + ")";
EndProcedure

&AtServerNoContext
Function vGetSessions(Val pFieldList)
	SetPrivilegedMode(True);

	pCurrentNamber = InfoBaseSessionNumber();

	pResult = New Array;

	For Each Item In GetInfoBaseSessions() Do
		pStructure = New Structure(pFieldList);
		FillPropertyValues(pStructure, Item);

		pStructure.CurrentSession = (Item.SessionNumber = pCurrentNamber);

		pStructure.ApplicationPresentation = ApplicationPresentation(pStructure.ApplicationName);

		pStructure.User = String(pStructure.User);

		If Item.User <> Undefined Then
			pStructure.DBUserID = String(Item.User.UUID);
		EndIf;

		pBackgroundJob = Item.GetBackgroundJob();
		If pBackgroundJob <> Undefined Then
			FillPropertyValues(pStructure, pBackgroundJob);
			pStructure.State = String(pBackgroundJob.Status);
			pStructure.ScheduledJob = String(pBackgroundJob.ScheduledJob);
			pStructure.BackgroundJobID = String(pBackgroundJob.UUID);
		EndIf;

		pResult.Add(pStructure);
	EndDo;

	Return pResult;
EndFunction

&AtClient
Procedure _FillInConnectionsList(Command)
	_ConnectionsList.Clear();

	pFieldList = "CurrentConnections, Active, ComputerName, ApplicationName, ApplicationPresentation, SessionStart, SessionNumber, ConnectionNumber, User, DBUserID";

	pArray = vGetConnections(pFieldList);

	For Each Item In pArray Do
		FillPropertyValues(_ConnectionsList.Add(), Item);
	EndDo;

	_ConnectionsList.Sort("SessionStart");

	Items.ConnectionsGroup.Title = NStr("ru = 'Соединения информационной базы';en = 'Connections of the information base'")+" (" + pArray.Count() + ")";
EndProcedure

&AtServerNoContext
Function vGetConnections(Val pFieldList)
	SetPrivilegedMode(True);

	pCurrentConnectionNumber = InfoBaseConnectionNumber();

	pResult = New Array;

	For Each Item In GetInfoBaseConnections() Do
		pStructure = New Structure(pFieldList);
		FillPropertyValues(pStructure, Item);

		pStructure.CurrentConnections = (Item.ConnectionNumber = pCurrentConnectionNumber);

		pStructure.Active = ValueIsFilled(Item.SessionNumber);

		pStructure.ApplicationPresentation = ApplicationPresentation(pStructure.ApplicationName);

		pStructure.User = String(pStructure.User);

		If Item.User <> Undefined Then
			pStructure.DBUserID = String(Item.User.UUID);
		EndIf;

		pResult.Add(pStructure);
	EndDo;

	Return pResult;
EndFunction
&AtClient
Procedure _FinishSessions(Command)
	pSelectedLines = Items._SessionList.SelectedRows;
	If pSelectedLines.Count() = 0 Then
		Return;
	EndIf;

	pSessionsArray = New Array;
	For Each Item In pSelectedLines Do
		Row = _SessionList.FindByID(Item);
		If Not Row.CurrentSession Then
			pSessionsArray.Add(Row.SessionNumber);
		EndIf;
	EndDo;

	If pSessionsArray.Count() = 0 Then
		vShowMessageBox(NStr("ru = 'Невозможно завершить текущий Session!
							 |For выхода из программы можно закрыть главное окно программы.';
							 |en = 'Unable to terminate the current session!
							 |For exiting the program, you can close the main program window.'"));
		Return;
	EndIf;

	pText = StrTemplate(NStr("ru = 'Отмеченные сеансы (%1 шт) будут завершены.
							 |Продолжить?';
							 |en = 'The marked sessions (%1 pcs) will be completed.
							 |Continue?'"), 
					   pSessionsArray.Count());

	vShowQueryBox(pText, "vEndSessionsResponse", pSessionsArray);
EndProcedure

&AtClient
Procedure vEndSessionsResponse(Response, pSessionsArray) Export
	If Response = DialogReturnCode.Yes Then
		If mClusterParameters = Undefined Then
			mClusterParameters = vGe1CClusterParameters();
		EndIf;

		If mClusterParameters.FileDB Then
			Items._SessionList_FinishSessions.Enabled = False;
			Items.ClusterAdministratorGroup.ReadOnly = True;
			vShowMessageBox(NStr("ru = 'Завершение сеансов реализовано только для клиент-серверного варианта!';en = 'Session termination is implemented only for the client-server version!'"));
			Return;
		EndIf;

		Try
			vEndSessions(pSessionsArray);
		Except
			Message(vGenerateDescriptionOfError(ErrorInfo()));
		EndTry;

		_FillInSessionsList(Undefined);
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function vGenerateDescriptionOfError(Val pErrorInfo)
	pText = pErrorInfo.LongDesc;

	While True Do
		If pErrorInfo.Reason <> Undefined Then
			pText = pText + "
							  |" + pErrorInfo.Reason.LongDesc;
			pErrorInfo = pErrorInfo.Reason;
		Else
			Break;
		EndIf;
	EndDo;

	Return pText;
EndFunction
&AtClient
Procedure vEndSessions(pSessionsArray)
	COMConnector = New COMObject(mClusterParameters.COMConnectorName, mClusterParameters.COMConnectorServer);

	pConnectionToServerAgent = vConnectionToServerAgent(
		COMConnector, mClusterParameters.ServerAgentAdress, mClusterParameters.ServerAgentPort);

	pClaster = vGetClaster(
		pConnectionToServerAgent, mClusterParameters.ClasterPort, _ClusterAdministratorName, ?(IsBlankString(
		_ClusterAdministratorName), "", _ClusterAdministratorPassword));

	pSessionsToDelete = New Array;

	For Each Session In pConnectionToServerAgent.GetSessions(pClaster).Unload() Do
		If pSessionsArray.Find(Session.SessionID) <> Undefined Then
			pSessionsToDelete.Add(Session);
		EndIf;
	EndDo;

	For Each Session In pSessionsToDelete Do
		UserInterruptProcessing();

		Try
			pConnectionToServerAgent.TerminateSession(pClaster, Session);
		Except
		EndTry;
	EndDo;
EndProcedure

&AtClient
Function vConnectionToServerAgent(COMConnector, Val ServerAgentAdress, Val ServerAgentPort)

	pConnectionString = "tcp://" + ServerAgentAdress + ":" + Format(ServerAgentPort, "NG=0;");
	pConnectionToServerAgent = COMConnector.ConnectAgent(pConnectionString);

	Return pConnectionToServerAgent;

EndFunction

&AtClient
Function vGetClaster(ServerAgentConnection, Val ClasterPort, Val NameOfClusterAdministrator,
	Val PasswordOfClusterAdministrator)

	For Each Cluster In ServerAgentConnection.GetClusters() Do

		If Cluster.MainPort = ClasterPort Then

			ServerAgentConnection.Authenticate(Cluster, NameOfClusterAdministrator, PasswordOfClusterAdministrator);

			Return Cluster;

		EndIf;

	EndDo;

	Raise StrTemplate(NStr("ru = 'На рабочем сервере %1 не найден класетер %2';en = 'Cluster %2 not found on production server %1'"), ServerAgentConnection.ConnectionString,
		ClasterPort);

EndFunction

&AtServerNoContext
Function vGe1CClusterParameters()
	pResult = New Structure;

	pSystemInfo = New SystemInfo;
	pConnectionString = InfoBaseConnectionString();

	pResult.Insert("FileDB", (Find(Upper(pConnectionString), "FILE=") = 1));
	pResult.Insert("COMConnectorServer", "");
	pResult.Insert("ServerAgentPort", 1540);
	pResult.Insert("ClasterPort", 1541);
	pResult.Insert("ServerAgentAdress", "LocalHost");
	pResult.Insert("NameOfClusterAdministrator", "");
	pResult.Insert("PasswordOfClusterAdministrator", "");
	pResult.Insert("NameIntoCluster", "");
	pResult.Insert("ConnectionType", "COM");
	pResult.Insert("COMConnectorName", "V83.COMConnector");
	pResult.Insert("NameOfDBAdministrator", InfoBaseUsers.CurrentUser().Name);
	pResult.Insert("PasswordOfDBAdministrator", "");
	pResult.Insert("1CPlatform", "83");

	pStringArray = StrSplit(pConnectionString, ";", False);

	pValue = StrReplace(vKeyStringValue(pStringArray, "Srvr"), """", "");
	Position = Find(pValue, ":");
	If Position <> 0 Then
		pResult.Insert("ServerAgentAdress", TrimAll(Mid(pValue, 1, Position - 1)));
		pResult.Insert("ClasterPort", Number(Mid(pValue, Position + 1)));
	Else
		pResult.Insert("ServerAgentAdress", pValue);
		pResult.Insert("ClasterPort", 1541);
	EndIf;
	pResult.ServerAgentPort = pResult.ClasterPort - 1;

	pResult.Insert("NameIntoCluster", StrReplace(vKeyStringValue(pStringArray, "Ref"), """", ""));

	pResult.Insert("AppVersion", pSystemInfo.AppVersion);
	pResult.Insert("BinDir", BinDir());

	If Find(pResult.AppVersion, "8.4.") = 1 Then
		pResult.Insert("COMConnectorName", "V84.COMConnector");
		pResult.Insert("1CPlatform", "84");
	EndIf;

	Return pResult;
EndFunction

&AtServerNoContext
Function vKeyStringValue(RowArray, Key, DefaultValue = "") Export
	KeyVR = Upper(Key) + "=";
	For Each Row In RowArray Do
		pValue = TrimAll(Row);
		If Find(Upper(pValue), KeyVR) = 1 Then
			Return Mid(pValue, StrLen(KeyVR) + 1);
		EndIf;
	EndDo;

	Return DefaultValue;
EndFunction


// CONFIGURATION EXTENSIONS
&AtClient
Procedure _FillInExtensionList(Command)
	_ExtensionsList.Clear();

	pArray = vGetExtensionList();

	For Each Item In pArray Do
		FillPropertyValues(_ExtensionsList.Add(), Item);
	EndDo;
	
	//vFillExtensionList();

	_ExtensionsList.Sort("Name");

	Items.ConfigurationExtensions.Title = NStr("ru = 'Расширения конфигурации';en = 'Configuration Extensions'")+" (" + _ExtensionsList.Count() + ")";
EndProcedure

&AtServer
Procedure vFillExtensionList()
	_ExtensionsList.Clear();

	pArray = ConfigurationExtensions.Get();

	For Each Item In pArray Do
		NewRow = _ExtensionsList.Add();
		FillPropertyValues(NewRow, Item);
	EndDo;
EndProcedure

&AtClientAtServerNoContext
Function vMakePropertyStructureOfExtension(pMode = 0)
	pStructure = New Structure("Active, SafeMode, Version, UnsafeOperationProtection, Name, Purpose, Scope, Synonym, UUID, HashSum");

	If pMode = 1 Then
		For Each Item In pStructure Do
			pStructure[Item.Key] = -1;
		EndDo;
	EndIf;

	Return pStructure;
EndFunction

&AtServerNoContext
Function vCheckType(Val pTypeName)
	Try
		pType = Type(pTypeName);
	Except
		Return False;
	EndTry;

	Return True;
EndFunction
&AtServerNoContext
Function vGetExtensionList()
	pResult = New Array;

	pArray = ConfigurationExtensions.Get();

	For Each Item In pArray Do
		pStructure = vMakePropertyStructureOfExtension(1);
		FillPropertyValues(pStructure, Item);

		If pStructure.UnsafeOperationProtection = -1 Then
			pStructure.UnsafeOperationProtection = Undefined;
		Else
			pStructure.UnsafeOperationProtection = pStructure.UnsafeOperationProtection.UnsafeOperationWarnings;
		EndIf;

		If pStructure.Scope = -1 Then
			pStructure.Scope = Undefined;
		Else
			pStructure.Scope = String(pStructure.Scope);
		EndIf;

		If pStructure.Purpose = -1 Then
			pStructure.Purpose = Undefined;
		Else
			pStructure.Purpose = String(pStructure.Purpose);
		EndIf;

		pResult.Add(pStructure);
	EndDo;

	Return pResult;
EndFunction

&AtClient
Procedure RunDesignerUnderUser(Command)
	CurrentData=Items._DBUserList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CommonClient.Run1CSession(1, CurrentData.Name, True,
		WaitingTimeBeforePasswordRecovery);
EndProcedure

&AtClient
Procedure RunOrdinaryClientUnderUser(Command)
	CurrentData=Items._DBUserList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CommonClient.Run1CSession(2, CurrentData.Name, True,
		WaitingTimeBeforePasswordRecovery);
EndProcedure

&AtClient
Procedure RunThickClientUnderUser(Command)
	CurrentData=Items._DBUserList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CommonClient.Run1CSession(3, CurrentData.Name, True,
		WaitingTimeBeforePasswordRecovery);
EndProcedure

&AtClient
Procedure RunThinClientUnderUser(Command)
	CurrentData=Items._DBUserList.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	UT_CommonClient.Run1CSession(4, CurrentData.Name, True,
		WaitingTimeBeforePasswordRecovery);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure