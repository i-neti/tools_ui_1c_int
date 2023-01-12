&AtClientAtServerNoContext
Function vSplitString(Val Str, Splitter, IncludeEmpty = True)

	StringArray = New Array;
	If Splitter = " " Then
		Str = TrimAll(Str);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				Value = TrimAll(Str);
				If IncludeEmpty Or Not IsBlankString(Value) Then
					StringArray.Add(Value);
				EndIf;
				Return StringArray;
			EndIf;

			Value = TrimAll(Left(Str, Pos - 1));
			If IncludeEmpty Or Not IsBlankString(Value) Then
				StringArray.Add(Value);
			EndIf;
			Str = TrimL(Mid(Str, Pos));
		EndDo;
	Else
		SplitterLength = StrLen(Splitter);
		While 1 = 1 Do
			Pos = Find(Str, Splitter);
			If Pos = 0 Then
				Value = TrimAll(Str);
				If IncludeEmpty Or Not IsBlankString(Value) Then
					StringArray.Add(Value);
				EndIf;
				Return StringArray;
			EndIf;

			Value = TrimAll(Left(Str, Pos - 1));
			If IncludeEmpty Or Not IsBlankString(Value) Then
				StringArray.Add(Value);
			EndIf;
			Str = Mid(Str, Pos + SplitterLength);
		EndDo;
	EndIf;

EndFunction

&AtClientAtServerNoContext
Function vValueToArray(Val Value)
	Array = New Array;
	Array.Add(Value);

	Return Array;
EndFunction

&AtServerNoContext
Function vHaveAdministratorRights()
	Return AccessRight("Administration", Metadata);
EndFunction

&AtClient
Procedure vShowQuestion(ProcedureName, QuestionText, AdditionalParameters = Undefined)
	ShowQueryBox(New NotifyDescription(ProcedureName, ThisForm, AdditionalParameters), QuestionText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure
&AtServer
Procedure vDebugAtServer()
	//TableOfResults = vGetProcessor().GetRegistrarsTable("AAA");
EndProcedure

&AtServer
Function vGetDataProcessor()
	Return FormAttributeToValue("Object");
EndFunction

&AtServerNoContext
Function vCopyStructure(Src)
	Struc = New Structure;

	For Each Itm In Src Do
		Struc.Insert(Itm.Key, Itm.Value);
	EndDo;

	Return Struc;
EndFunction

&AtServerNoContext
Function vCheckHasProperty(Object, PropertyName)
	Struc = New Structure(PropertyName);
	FillPropertyValues(Struc, Object);

	Return (Struc[PropertyName] <> Undefined);
EndFunction

&AtServerNoContext
Function vCreatePostingTableOfDocuments(StorageAddress, Val UUID)
	Try
		TableOfResults = GetFromTempStorage(StorageAddress);
	Except
		TableOfResults = Undefined;
	EndTry;

	If TableOfResults = Undefined Then
		StorageAddress = "";
	EndIf;

	If TableOfResults = -1 Or TableOfResults = Undefined Or TableOfResults.Columns.Count() = 0 Then
		StringType = New TypeDescription("String", , , , New StringQualifiers(500));

		TableOfResults = New ValueTable;
		TableOfResults.Columns.Add("AttributeName", StringType);
		TableOfResults.Columns.Add("Name", StringType);
		TableOfResults.Columns.Add("Synonym", StringType);
		TableOfResults.Columns.Add("Comment", StringType);
		TableOfResults.Columns.Add("StringType", StringType);

		For Each MDObject In Metadata.Documents Do
			For Each Itm In MDObject.RegisterRecords Do
				NewLine = TableOfResults.Add();
				NewLine.Name = MDObject.Name;
				NewLine.Synonym = MDObject.Presentation();
				NewLine.Comment = MDObject.Comment;
				NewLine.StringType = MDObject.FullName();
				NewLine.AttributeName = Itm.FullName();
			EndDo;
		EndDo;

		TableOfResults.Sort("AttributeName, Name");
		TableOfResults.Indexes.Add("AttributeName");

		StorageAddress = PutToTempStorage(TableOfResults, ?(StorageAddress = "", UUID,
			StorageAddress));
	EndIf;

	Return TableOfResults;
EndFunction

&AtServerNoContext
Function CreateSubscriptionsTable(StorageAddress, Val UUID)
	Try
		TableOfResults = GetFromTempStorage(StorageAddress);
	Except
		TableOfResults = Undefined;
	EndTry;

	If TableOfResults = Undefined Then
		StorageAddress = "";
	EndIf;

	If TableOfResults = -1 Or TableOfResults = Undefined Or TableOfResults.Columns.Count() = 0 Then
		StringType = New TypeDescription("String", , , , New StringQualifiers(500));

		Cache = New Map;

		TableOfResults = New ValueTable;
		TableOfResults.Columns.Add("Src", StringType);
		TableOfResults.Columns.Add("Name", StringType);
		TableOfResults.Columns.Add("Synonym", StringType);
		TableOfResults.Columns.Add("Comment", StringType);

		StructureOfData = New Structure("Name, Synonym, Comment");
		For Each Subscription In Metadata.EventSubscriptions Do
			StructureOfData.Name = Subscription.Name;
			StructureOfData.Synonym = Subscription.Presentation();
			StructureOfData.Comment = StructureOfData.Comment;

			For Each Type In Subscription.Src.Types() Do
				NewLine = TableOfResults.Add();
				FillPropertyValues(NewLine, StructureOfData);

				SourceName = Cache[Type];
				If SourceName = Undefined Then
					SourceName =  Metadata.FindByType(Type).FullName();
					Cache[Type] = SourceName;
				EndIf;

				NewLine.Src = SourceName;
			EndDo;
		EndDo;

		TableOfResults.Sort("Src, Name");
		TableOfResults.Indexes.Add("Src");

		StorageAddress = PutToTempStorage(TableOfResults, ?(StorageAddress = "", UUID,
			StorageAddress));
	EndIf;

	Return TableOfResults;
EndFunction

&AtServerNoContext
Function vCreateCommonCommandsTable(StorageAddress, Val UUID)
	Try
		TableOfResults = GetFromTempStorage(StorageAddress);
	Except
		TableOfResults = Undefined;
	EndTry;

	If TableOfResults = Undefined Then
		StorageAddress = "";
	EndIf;

	If TableOfResults = -1 Or TableOfResults = Undefined Or TableOfResults.Columns.Count() = 0 Then
		StringType = New TypeDescription("String", , , , New StringQualifiers(500));

		Cache = New Map;

		TableOfResults = New ValueTable;
		TableOfResults.Columns.Add("Parameter", StringType);
		TableOfResults.Columns.Add("Name", StringType);
		TableOfResults.Columns.Add("Synonym", StringType);
		TableOfResults.Columns.Add("Comment", StringType);

		StructureOfData = New Structure("Name, Synonym, Comment");
		For Each MDObject In Metadata.CommonCommands Do
			StructureOfData.Name = MDObject.Name;
			StructureOfData.Synonym = MDObject.Presentation();
			StructureOfData.Comment = MDObject.Comment;

			For Each Type In MDObject.CommandParameterType.Types() Do
				NewLine = TableOfResults.Add();
				FillPropertyValues(NewLine, StructureOfData);

				ParameterName = Cache[Type];
				If ParameterName = Undefined Then
					ParameterName =  Metadata.FindByType(Type).FullName();
					Cache[Type] = ParameterName;
				EndIf;

				NewLine.Parameter = ParameterName;
			EndDo;
		EndDo;

		TableOfResults.Sort("Parameter, Name");
		TableOfResults.Indexes.Add("Parameter");

		StorageAddress = PutToTempStorage(TableOfResults, ?(StorageAddress = "", UUID,
			StorageAddress));
	EndIf;

	Return TableOfResults;
EndFunction

&AtServerNoContext
Function vCreateCommandsTable(StorageAddress, Val UUID)
	Try
		TableOfResults = GetFromTempStorage(StorageAddress);
	Except
		TableOfResults = Undefined;
	EndTry;

	If TableOfResults = Undefined Then
		StorageAddress = "";
	EndIf;

	If TableOfResults = -1 Or TableOfResults = Undefined Or TableOfResults.Columns.Count() = 0 Then
		StringType = New TypeDescription("String", , , , New StringQualifiers(500));

		Cache = New Map;

		TableOfResults = New ValueTable;
		TableOfResults.Columns.Add("Parameter", StringType);
		TableOfResults.Columns.Add("Name", StringType);
		TableOfResults.Columns.Add("Synonym", StringType);
		TableOfResults.Columns.Add("Comment", StringType);

		StructureOfData = New Structure("Name, Synonym, Comment");

		SectionList = "Catalogs, DocumentJournals, Documents, Enums, DataProcessors, Reports,
						   |ChartsOfAccounts, ChartsOfCharacteristicTypes, ChartsOfCalculationTypes, ExchangePlans,
						   |InformationRegisters, AccumulationRegisters, CalculationRegisters, AccountingRegisters,
						   |BusinessProcesses, Tasks, FilterCriteria";

		SectionStructure = New Structure(SectionList);

		For Each Itm In SectionStructure Do
			For Each ObjectXXX In Metadata[Itm.Key] Do
				TypeNameXXX = ObjectXXX.FullName();

				If vCheckHasProperty(ObjectXXX, "Commands") Then
					For Each MDObject In ObjectXXX.Commands Do
						StructureOfData.Name = MDObject.FullName();
						StructureOfData.Synonym = MDObject.Presentation();
						StructureOfData.Comment = MDObject.Comment;

						For Each Type In MDObject.CommandParameterType.Types() Do
							ParameterName = Cache[Type];
							If ParameterName = Undefined Then
								ParameterName =  Metadata.FindByType(Type).FullName();
								Cache[Type] = ParameterName;
							EndIf;

							If ParameterName = TypeNameXXX Then
								Continue;
							EndIf;

							NewLine = TableOfResults.Add();
							FillPropertyValues(NewLine, StructureOfData);

							NewLine.Parameter = ParameterName;
						EndDo;
					EndDo;
				EndIf;
			EndDo;
		EndDo;

		TableOfResults.Sort("Parameter, Name");
		TableOfResults.Indexes.Add("Parameter");

		StorageAddress = PutToTempStorage(TableOfResults, ?(StorageAddress = "", UUID,
			StorageAddress));
	EndIf;

	Return TableOfResults;
EndFunction

&AtServerNoContext
Function vCreateSubsystemTable(StorageAddress, Val UUID)
	Try
		TableOfResults = GetFromTempStorage(StorageAddress);
	Except
		TableOfResults = Undefined;
	EndTry;

	If TableOfResults = Undefined Then
		StorageAddress = "";
	EndIf;

	If TableOfResults = -1 Or TableOfResults = Undefined Or TableOfResults.Columns.Count() = 0 Then
		StringType = New TypeDescription("String", , , , New StringQualifiers(500));

		Cache = New Map;

		TableOfResults = New ValueTable;
		TableOfResults.Columns.Add("Object", StringType);
		TableOfResults.Columns.Add("Name", StringType);
		TableOfResults.Columns.Add("FullName", StringType);
		TableOfResults.Columns.Add("Synonym", StringType);
		TableOfResults.Columns.Add("Comment", StringType);

		Collection = New Map;
		vCreateSubsystemCollection( , Collection);

		StructureOfData = New Structure("Name, FullName, Synonym, Comment");
		For Each Itm In Collection Do
			MDObject = Itm.Key;

			StructureOfData.Name = MDObject.Name;
			StructureOfData.FullName = MDObject.FullName();
			StructureOfData.Synonym = MDObject.Presentation();
			StructureOfData.Comment = MDObject.Comment;

			For Each Itm In MDObject.Content Do
				NewLine = TableOfResults.Add();
				FillPropertyValues(NewLine, StructureOfData);

				NewLine.Object = Itm.FullName();
			EndDo;
		EndDo;

		TableOfResults.Sort("Object, Name");
		TableOfResults.Indexes.Add("Object");

		StorageAddress = PutToTempStorage(TableOfResults, ?(StorageAddress = "", UUID,
			StorageAddress));
	EndIf;

	Return TableOfResults;
EndFunction

&AtServerNoContext
Procedure vCreateSubsystemCollection(Val SubSystem = Undefined, Val Collection)
	If SubSystem = Undefined Then
		For Each MDObject In Metadata.Subsystems Do
			vCreateSubsystemCollection(MDObject, Collection);
		EndDo;
	Else
		Collection.Insert(SubSystem);
		For Each MDObject In SubSystem.Subsystems Do
			Collection.Insert(MDObject);
			vCreateSubsystemCollection(MDObject, Collection);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Function vGetRecorderTable(AttributeName)
	Return vCreatePostingTableOfDocuments(_StorageAddresses.RegisterRecords, UUID).Copy(
		New Structure("AttributeName", AttributeName));
EndFunction

&AtServer
Function vGetEventSubscriptionsTable(ObjectName)
	Return CreateSubscriptionsTable(_StorageAddresses.Subscriptions, UUID).Copy(
		New Structure("Src", ObjectName));
EndFunction

&AtServer
Function vGetCommonCommandsTable(ObjectName)
	Return vCreateCommonCommandsTable(_StorageAddresses.CommonCommands, UUID).Copy(
		New Structure("Parameter", ObjectName));
EndFunction

&AtServer
Function vGetExternalCommandsTable(ObjectName)
	Return vCreateCommandsTable(_StorageAddresses.Commands, UUID).Copy(
		New Structure("Parameter", ObjectName));
EndFunction

&AtServer
Function vGetSubSystemTable(ObjectName)
	Return vCreateSubsystemTable(_StorageAddresses.Subsystems, UUID).Copy(
		New Structure("Object", ObjectName));
EndFunction

&AtClient
Function vCreateSettingsStructureOfObjectsProperies()
	Struc = New Structure("_ShowEventSubscriptions, _ShowObjectsSubsytems, _ShowCommonObjectCommands, _ShowExternalObjectCommands");
	FillPropertyValues(Struc, ThisForm);

	Return Struc;
EndFunction
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Title = Parameters.FullName;

	_FullName = Parameters.FullName;
	
	_ListFormName = ".ListForm";

	PathToForms = Parameters.PathToForms;

	_StorageAddresses = vCopyStructure(Parameters._StorageAddresses);

	_AdditionalVars = New Structure;
	_AdditionalVars.Insert("DescriptionOfAccessRights", Parameters.DescriptionOfAccessRights);

	FillPropertyValues(ThisForm, Parameters.ProcessingSettings);

	Items.PropertyTreeGroup_UpdateNumberOfObjects.Visible = vHaveAdministratorRights();

	Items._AccessRightForRole.Visible = False;
	Items.AccessRightToObject_Role.Visible = True;

	Items.ValuePage.Visible = False;
	Items.DependentObjectsPage.Visible = False;
	Items.ManagingTotalsPage.Visible = False;

	If Parameters.FullName = "Configuration" Then
		vFullInConfigurationProperties();
		Items.PropertyTreeGroupkOpemListForm.Visible = False;
		Items.PropertyTreeGroupkOpemListFormAdditional.Visible = False;
		Items.PropertyTreeGroupkShowObjectProperties.Visible = False;
		Items.StorageStructurePage.Visible = False;
		Goto ~End;
	EndIf;

	IsDifferentCommand = (Find(Parameters.FullName, ".Command.") <> 0);

	If Not IsDifferentCommand And Find(Parameters.FullName, "SubSystem.") <> 1 Then
		If StrOccurrenceCount(Parameters.FullName, ".") <> 1 Then
			Cancel = True;
			Return;
		EndIf;
	EndIf;

	Items.AccessRightPage.Visible = vHaveAdministratorRights();
	If Items.AccessRightPage.Visible Then
		Items._AccessRightToObject.ChoiceList.Clear();

		pRightsList = _AdditionalVars.DescriptionOfAccessRights[?(IsDifferentCommand, "CommonCommand", Left(_FullName, StrFind(
			_FullName, ".") - 1))];
		If pRightsList <> Undefined Then
			pDefaultAccessRight = "";

			For Each Itm In New Structure(pRightsList) Do
				Items._AccessRightToObject.ChoiceList.Add(Itm.Key);
				If IsBlankString(pDefaultAccessRight) Then
					pDefaultAccessRight = Itm.Key;
				EndIf;
			EndDo;

			_AccessRightToObject = pDefaultAccessRight;
		EndIf;
	EndIf;

	If IsDifferentCommand Then
		_ListFormName = "";
		vFullInCommonCommandProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "Catalog.") = 1 Then
		vFullInCatalogProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "Document.") = 1 Then
		vFullInDocumentProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "DocumentJournal.") = 1 Then
		vFullInDocumentJournalProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "ChartOfCharacteristicTypes.") = 1 Then
		vFullInChartOfCharacteristicTypesProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "ChartOfCalculationTypes.") = 1 Then
		vFullInChartOfCalculationTypesProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "ChartOfAccounts.") = 1 Then
		vFullInChartOfAccountsProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "InformationRegister.") = 1 Then
		vFullInInformationRegisterProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "AccumulationRegister.") = 1 Then
		vFullInAccumulationRegisterProperty(Parameters.FullName);
		vFullInTotalControlPage(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "AccountingRegister.") = 1 Then
		vFullInAccountingRegisterProperty(Parameters.FullName);
		vFullInTotalControlPage(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "CalculationRegister.") = 1 Then
		vFullInCalculationRegisterProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "BusinessProcess.") = 1 Then
		vFullInBusinessProcessProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "Task.") = 1 Then
		vFullInTaskProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "ExchangePlan.") = 1 Then
		vFullInExchangePlanProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "Constant.") = 1 Then
		vFullInConstantProperty(Parameters.FullName);
		Items.PropertyTreeGroupkOpemListForm.Visible = False;
		Items.PropertyTreeGroupkOpemListFormAdditional.Visible = False;
	ElsIf Find(Parameters.FullName, "SessionParameter.") = 1 Then
		vFullInSessionParameterProperty(Parameters.FullName);
		Items.PropertyTreeGroupkOpemListForm.Visible = False;
		Items.PropertyTreeGroupkOpemListFormAdditional.Visible = False;
	ElsIf Find(Parameters.FullName, "Enum.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		vFullInEnumProperty(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "CommonModule.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		vFullInCommonModuleProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "CommonCommand.") = 1 Then
		_ListFormName = "";
		vFullInCommonCommandProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "SubSystem.") = 1 Then
		_ListFormName = "";
		vFullInSubSystemProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "DefinedType.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		vFullInDefinedTypeProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "EventSubscription.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		vFullInEventSubscriptionProperty(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "Role.") = 1 Then
		If Not Items.AccessRightPage.Visible Then
			Cancel = True;
			Return;
		EndIf;

		_ListFormName = "";
		Items.PagesGroup.PagesRepresentation = FormPagesRepresentation.None;
		Items._AccessRightForRole.Visible = True;
		Items.AccessRightToObject_Role.Visible = False;
		Items.PagesGroup.CurrentPage = Items.AccessRightPage;
		Items.ObjectPage.Visible = False;
		Items.StorageStructurePage.Visible = False;

		pRightsList =  "Read, Insert, Update, Delete, View, Edit, Use, TotalControl, Posting, UndoPosting, Get, Set, Start, Execute";
		For Each Itm In New Structure(pRightsList) Do
			Items._AccessRightToObject.ChoiceList.Add(Itm.Key);
		EndDo;

		_AccessRightToObject = "Read";
		Return;
	Else
		Cancel = True;
		Return;
	EndIf;

	Items.PropertyTreeGroup_OpenObject.Visible = (_EmptyRef <> Undefined);

	MDObject = Metadata.FindByFullName(Parameters.FullName);
	If MDObject <> Undefined Then
		SXData = GetDBStorageStructureInfo(vValueToArray(MDObject),
			Not _ShowStorageStructureIn1CTerms);
		If SXData = Undefined Or SXData.Count() = 0 Then
			Items.StorageStructurePage.Visible = ложь
		Else
			vFullInSectionOfStorage(SXData);
		EndIf;
	Else
		Items.StorageStructurePage.Visible = ложь
	EndIf
	;

	~End: For Each TreeNode In PropertyTree.GetItems() Do
		TreeNode.NodeType = 1;
		
		//If StrFind(TreeNode.StringType, "Enum.") <> 0 Then
		//	Break;
		//EndIf;

		For Each TreeSection In TreeNode.GetItems() Do
			TreeSection.NodeType = 2;
		EndDo;
	EndDo;

	vSetConditionalApprentice();
EndProcedure

&AtServer
Procedure vSetConditionalApprentice()
	ThisForm.ConditionalAppearance.Items.Clear();

	ItemCA = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ItemCA.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("PropertyTree.NodeType");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 1;
	ItemCA.Appearance.SetParameterValue("Font", New Font(Items.PropertyTree.Font, , , True));
	ItemCA.Fields.Items.Add().Field = New DataCompositionField("PropertyTreeName");

	ItemCA = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ItemCA.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("PropertyTree.NodeType");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 2;
	ItemCA.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	ItemCA.Fields.Items.Add().Field = New DataCompositionField("PropertyTreeName");

	ItemCA = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ItemCA.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("PropertyTree.Indexing");
	FilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	FilterItem.RightValue = "";
	ItemCA.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	//ItemCA.Appearance.SetParameterValue("BgColor", WebColors.LightGoldenRodYellow);
	ItemCA.Fields.Items.Add().Field = New DataCompositionField("PropertyTree");

	ItemCA = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ItemCA.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("_DependentObjects.NodeType");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 1;
	ItemCA.Appearance.SetParameterValue("Font", New Font(Items._DependentObjects.Font, , , True));
	ItemCA.Fields.Items.Add().Field = New DataCompositionField("_DependentObjectsName");

	ItemCA = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ItemCA.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("_DependentObjects.NodeType");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 2;
	ItemCA.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	ItemCA.Fields.Items.Add().Field = New DataCompositionField("_DependentObjectsName");

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	For Each Itm In PropertyTree.GetItems() Do
		ExpandAll = (False Or Find(Itm.StringType, "Configuration.") = 1 Or Find(Itm.StringType, "SubSystem.")
			= 1 Or Find(Itm.StringType, "CommonModule.") = 1 Or Find(Itm.StringType, "CommonCommand.") = 1
			Or Find(Itm.StringType, "EventSubscription.") = 1 Or Find(Itm.StringType, "DocumentJournal.") = 1
			Or Find(Itm.StringType, "DefinedType.") = 1 Or Find(Itm.StringType, ".Command.") <> 0);
		Items.PropertyTree.Expand(Itm.GetID(), ExpandAll);
		Break;
	EndDo;

	If StrFind(_FullName, "Role.") = 1 And Not IsBlankString(_AccessRightToObject) Then
		_AccessRightToObjectOnChange(Items._ПравоДоступаКОбъекту);
	EndIf;
EndProcedure

&AtClient
Procedure _ExpandAllNodes(Command)
	If Items.PagesGroup.CurrentPage = Items.ObjectPage Then
		For Each Itm In PropertyTree.GetItems() Do
			Items.PropertyTree.Expand(Itm.GetID(), True);
		EndDo;
	ElsIf Items.PagesGroup.CurrentPage = Items.DependentObjectsPage Then
		For Each Itm In _DependentObjects.GetItems() Do
			Items._DependentObjects.Expand(Itm.GetID(), True);
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure _CollapseAllNodes(Command)
	If Items.PagesGroup.CurrentPage = Items.ObjectPage Then
		For Each TreeNode In PropertyTree.GetItems() Do
			For Each Itm In TreeNode.GetItems() Do
				Items.PropertyTree.Collapse(Itm.GetID());
			EndDo;
		EndDo;
	ElsIf Items.PagesGroup.CurrentPage = Items.DependentObjectsPage Then
		For Each TreeNode In _DependentObjects.GetItems() Do
			For Each Itm In TreeNode.GetItems() Do
				Items._DependentObjects.Collapse(Itm.GetID());
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure kOpemListForm(Command)
	TreeRow = PropertyTree.FindByID(0);
	If TreeRow <> Undefined And Not IsBlankString(_ListFormName) Then
		Try
			OpenForm(TreeRow.StringType + _ListFormName);
		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
EndProcedure

&AtClient
Procedure kOpemListFormAdditional(Command)
	TreeRow = PropertyTree.FindByID(0);
	If TreeRow <> Undefined And Not IsBlankString(_ListFormName) Then
		UT_CommonClient.ОpenDynamicList(TreeRow.StringType);
	EndIf;
EndProcedure

&AtClient
Procedure kShowObjectProperties(Command)
	CurData = Items.PropertyTree.CurrentData;
	If CurData <> Undefined And Not IsBlankString(CurData.StringType) Then
		Array = vStringToArray(CurData.StringType);
		If Array.Count() = 1 Then
			vShowObjectProperties(Array[0]);
		ElsIf Array.Count() > 1 Then
			List = New ValueList;
			List.LoadValues(Array);
			List.SortByValue();
			Try
				List.ShowChooseItem(New NotifyDescription("kShowObjectPropertiesNext", ThisForm),
					NStr("ru = 'Выбор типа';en = 'Selection of type'"));
			Except
				SelectedItem = Undefined;

				List.ShowChooseItem(New NotifyDescription("kShowObjectPropertiesFinish", ThisForm),
					NStr("ru = 'Выбор типа';en = 'Selection of type'"));
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure kShowObjectPropertiesFinish(SelectedItem1, AdditionalParameters) Export

	SelectedItem = SelectedItem1;
	If SelectedItem <> Undefined Then
		kShowObjectPropertiesNext(SelectedItem, Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure kShowObjectPropertiesNext(SelectedItem, AdditionalParameters) Export
	If SelectedItem <> Undefined Then
		vShowObjectProperties(SelectedItem.Value);
	EndIf;
EndProcedure

&AtClient
Procedure _OpenObject(Command)
	StructureParams = New Structure;
	StructureParams.Insert("mObjectRef", _EmptyRef);
	OpenForm("DataProcessor.UT_ObjectsAttributesEditor.Form.ObjectForm", StructureParams, , CurrentDate());
EndProcedure
&AtClient
Procedure PropertyTreeSelection(Item, SelectedRow, Field, StandardProcessing)
	TreeRow = PropertyTree.FindByID(SelectedRow);
	If TreeRow.Ref <> Undefined Then
		ShowValue( , TreeRow.Ref);
	ElsIf Not IsBlankString(TreeRow.StringType) Then
		kShowObjectProperties(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure vShowObjectProperties(FullName)
	If Not IsBlankString(PathToForms) Then
		Pos = StrFind(FullName, ".Command.");
		If Pos <> 0 Then
			TypeName = Left(FullName, Pos - 1);
		Else
			TypeName = FullName;
		EndIf;

		StructureParameters = New Structure("FullName, PathToForms, _StorageAddresses, DescriptionOfAccessRights", TypeName,
			PathToForms, _StorageAddresses, _AdditionalVars.DescriptionOfAccessRights);
		StructureParameters.Insert("ProcessingSettings", vCreateSettingsStructureOfObjectsProperies());
		OpenForm(PathToForms + "PropertiesForm", StructureParameters, , TypeName, , , , FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

&AtClient
Function vStringToArray(StringType)
	SimpleTypes = "/Boolean/Date/DateTime/String/Number/ValueStorage/UUID/";
	Result = New Array;

	For Each Itm In vSplitString(StringType, ",", False) Do
		If Find(SimpleTypes, Itm) = 0 Then
			If Find(Itm, "String(") = 0 And Find(Itm, "Number(") = 0 Then
				Result.Add(Itm);
			EndIf;
		EndIf;
	EndDo;

	Return Result;
EndFunction
&AtServerNoContext
Function vCreateStructureOfTypes()
	Result = New Structure;

	Result.Insert("mTypeOfString", Type("String"));
	Result.Insert("mTypeOfBoolean", Type("Boolean"));
	Result.Insert("mTypeOfNumber", Type("Number"));
	Result.Insert("mTypeOfDate", Type("Date"));
	Result.Insert("mTypeOfStructure", Type("Structure"));
	Result.Insert("mTypeOfValueStorage", Type("ValueStorage"));
	Result.Insert("mTypeOfBinaryData", Type("BinaryData"));
	Result.Insert("mTypeOfValueTree", Type("ValueTree"));
	Result.Insert("mTypeOfMetadataObject", Type("MetadataObject"));
	Result.Insert("mTypeOfUUID", Type("UUID"));

	Result.Insert("mTypeOfNULL", Type("NULL"));
	Result.Insert("mTypeOfUndefined", Type("Undefined"));
	Result.Insert("mTypeOfTypeDescription", Type("TypeDescription"));
	Result.Insert("mTypeOfAccountingRecord", Type("AccountingRecordType"));
	Result.Insert("mTypeOfAccumulationRecord", Type("AccumulationRecordType"));
	Result.Insert("mTypeOfAccount", Type("AccountType"));
	Result.Insert("mTypeOfFixedArray", Type("FixedArray"));
	Result.Insert("mTypeOfFixedStructure", Type("FixedStructure"));
	Result.Insert("mTypeOfFixedMap", Type("FixedMap"));

	Return Result;
EndFunction

&AtServerNoContext
Function vTypeNameToString(StructureOfTypes, Type, TypeDescription)
	TypeName = "";

	If Type = StructureOfTypes.mTypeOfNumber Then
		TypeName = "Number";
		If TypeDescription.NumberQualifiers.Digits <> 0 Then
			TypeName = TypeName + "(" + TypeDescription.NumberQualifiers.Digits + "."
				+ TypeDescription.NumberQualifiers.FractionDigits + ")";
		EndIf;
	ElsIf Type = StructureOfTypes.mTypeOfString Then
		TypeName = "String";
		If TypeDescription.StringQualifiers.Length <> 0 Then
			TypeName = TypeName + "(" + ?(TypeDescription.StringQualifiers.AllowedLength = AllowedLength.Variable,
				"V", "A") + TypeDescription.StringQualifiers.Length + ")";
		EndIf;
	ElsIf Type = StructureOfTypes.mTypeOfDate Then
		TypeName = ?(TypeDescription.DateQualifiers.DateFractions = DateFractions.Time, "Time", ?(
			TypeDescription.DateQualifiers.DateFractions = DateFractions.Date, "Date", "DateTime"));
	ElsIf Type = StructureOfTypes.mTypeOfBoolean Then
		TypeName = "Boolean";
	ElsIf Type = StructureOfTypes.mTypeOfBinaryData Then
		TypeName = "BinaryData";
	ElsIf Type = StructureOfTypes.mTypeOfValueStorage Then
		TypeName = "ValueStorage";
	ElsIf Type = StructureOfTypes.mTypeOfUUID Then
		TypeName = "UUID";

	ElsIf Type = StructureOfTypes.mTypeOfNULL Then
		TypeName = "NULL";
	ElsIf Type = StructureOfTypes.mTypeOfUndefined Then
		TypeName = "Undefined";
	ElsIf Type = StructureOfTypes.mTypeOfTypeDescription Then
		TypeName = "TypeDescription";
	ElsIf Type = StructureOfTypes.mTypeOfAccountingRecord Then
		TypeName = "AccountingRecordType";
	ElsIf Type = StructureOfTypes.mTypeOfAccumulationRecord Then
		TypeName = "AccumulationRecordType";
	ElsIf Type = StructureOfTypes.mTypeOfAccount Then
		TypeName = "AccountType";
	ElsIf Type = StructureOfTypes.mTypeOfFixedArray Then
		TypeName = "FixedArray";
	ElsIf Type = StructureOfTypes.mTypeOfFixedStructure Then
		TypeName = "FixedStructure";
	ElsIf Type = StructureOfTypes.mTypeOfFixedMap Then
		TypeName = "FixedMap";

	Else
		MDObject = Metadata.FindByType(Type);
		If MDObject <> Undefined Then
			TypeName = MDObject.FullName();
		Else
			TypeName = String(Type);
		EndIf;
	EndIf;

	Return TypeName;
EndFunction

&AtServerNoContext
Function vTypeDescriptionToString(TypeDescription)
	If TypeDescription = Undefined Then
		Return "";
	EndIf;

	StructureOfTypes = vCreateStructureOfTypes();

	Value = "";
	Types = TypeDescription.Types();
	For Each Itm In Types Do
		TypeName = vTypeNameToString(StructureOfTypes, Itm, TypeDescription);
		If Not IsBlankString(TypeName) Then
			Value = Value + "," + TypeName;
		EndIf;
	EndDo;

	Return Mid(Value, 2);
EndFunction
&AtServer
Function vCreatePropertiesTable()
	StringType = New TypeDescription("String");

	TableOfResults = New ValueTable;
	TableOfResults.Columns.Add("Name", StringType);
	TableOfResults.Columns.Add("Indexing", StringType);
	TableOfResults.Columns.Add("Synonym", StringType);
	TableOfResults.Columns.Add("Comment", StringType);
	TableOfResults.Columns.Add("StringType", StringType);

	Return TableOfResults;
EndFunction

&AtServer
Procedure vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList)
	TreeSection = TreeNode.GetItems().Add();
	TreeSection.Name = "Properties";

	ObjectMDType = Type("MetadataObject");
	TypeDescriptionType = Type("TypeDescription");

	Try
		// starting from version 8.3.8 (it is necessary to control the version)
		pConfigurationExtension = MDObject.ConfigurationExtension();
		If pConfigurationExtension <> Undefined Then
			TreeRow = TreeSection.GetItems().Add();
			TreeRow.Name = "ConfigurationExtension";
			TreeRow.Synonym = pConfigurationExtension.Name;
			TreeRow.StringType = "ConfigurationExtension";
			TreeRow.Comment = pConfigurationExtension.Synonym;
		EndIf;
	Except
	EndTry;

	Struc = New Structure(PropertiesList);
	FillPropertyValues(Struc, MDObject);
	For Each Itm In Struc Do
		TreeRow = TreeSection.GetItems().Add();
		TreeRow.Name = Itm.Key;
		TreeRow.Synonym = Itm.Value;
		If Itm.Value <> Undefined Then
			pValueType = TypeOf(Itm.Value);
			If pValueType = ObjectMDType Then
				TreeRow.StringType = Itm.Value.FullName();
			ElsIf pValueType = TypeDescriptionType Then
				TreeRow.StringType = vTypeDescriptionToString(Itm.Value);
			EndIf;
		EndIf;
	EndDo;
	
	// starting from version 8.3.8 (it is necessary to control the version)
	//Try
	//	Х = MDObject.ConfigurationExtension();
	//	If Х <> Undefined Then
	//		TreeRow = TreeSection.GetItems().Add();
	//		TreeRow.Name = "ConfigurationExtension";
	//		TreeRow.Synonym = Х.Name;
	//	EndIf;
	//Except
	//EndTry;
EndProcedure

&AtServerNoContext
Function vGetPropertyOfIndexing(Val MDObject)
	Struc = New Structure("Indexing");
	pPropertyOfIndexing = Metadata.ObjectProperties.Indexing;

	FillPropertyValues(Struc, MDObject);
	If Struc.Indexing = Undefined Then
		Value = "";
	ElsIf Struc.Indexing = pPropertyOfIndexing.DontIndex Then
		Value = "";
	Else
		Value = Struc.Indexing;
	EndIf;

	Return Value;
EndFunction

&AtServer
Procedure vFillObjectGroupOfProperties(MDObject, TreeNode, GroupName, Sort = True, OutputQuantity = False)
	If MDObject[GroupName].Count() <> 0 Then
		Table = vCreatePropertiesTable();
		For Each Itm In MDObject[GroupName] Do
			Row = Table.Add();
			Row.Name = Itm.Name;
			Row.Indexing = vGetPropertyOfIndexing(Itm);
			Row.Synonym = Itm.Presentation();
			Row.Comment = Itm.Comment;
			Row.StringType = vTypeDescriptionToString(Itm.Type);
		EndDo;

		If Sort Then
			Table.Sort("Name");
		EndIf;

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = GroupName;
		If OutputQuantity Then
			TreeSection.Name = TreeSection.Name + " (" + Table.Count() + ")";
		EndIf;

		For Each Row In Table Do
			FillPropertyValues(TreeSection.GetItems().Add(), Row);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillObjectCommands(MDObject, TreeNode)
	If vCheckHasProperty(MDObject, "Commands") And MDObject.Commands.Count() <> 0 Then
		Table = vCreatePropertiesTable();
		For Each Itm In MDObject.Commands Do
			Row = Table.Add();
			Row.Name = Itm.Name;
			Row.Synonym = Itm.Presentation();
			Row.Comment = Itm.Comment;
			Row.StringType = Itm.FullName();
		EndDo;

		Table.Sort("Name");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "Commands (" + Table.Count() + ")";

		For Each Row In Table Do
			FillPropertyValues(TreeSection.GetItems().Add(), Row);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillObjectAttrebutes(MDObject, TreeNode)
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Attributes", True, True);
EndProcedure

&AtServer
Procedure vFillObjectTabularSection(MDObject, TreeNode)
	List = New ValueList;
	For Each Itm In MDObject.TabularSections Do
		List.Add(Itm.Name);
	EndDo;
	List.SortByValue();

	For Each ItemX In List Do
		Itm = MDObject.TabularSections[ItemX.Value];
		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "TS." + Itm.Name;

		Table = vCreatePropertiesTable();
		For Each ItemTS In Itm.Attributes Do
			Row = Table.Add();
			Row.Name = ItemTS.Name;
			Row.Synonym = ItemTS.Presentation();
			Row.Comment = ItemTS.Comment;
			Row.StringType = vTypeDescriptionToString(ItemTS.Type);
		EndDo;
		Table.Sort("Name");

		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure vFillValuesTypeOfCharacteristic(MDObject, TreeNode)
	Array = MDObject.Type.Types();

	If Array.Count() <> 0 Then
		Table = vCreatePropertiesTable();
		Table.Columns.Add("NBSp", New TypeDescription("Number"));

		StructureOfTypes = vCreateStructureOfTypes();

		For Each Itm In Array Do
			ItemMD = Metadata.FindByType(Itm);

			Row = Table.Add();
			If ItemMD <> Undefined Then
				Row.Name = ItemMD.Name;
				Row.Synonym = ItemMD.Presentation();
				Row.Comment = "";
				Row.StringType = ItemMD.FullName();
			Else
				TypeName = vTypeNameToString(StructureOfTypes, Itm, MDObject.Type);

				Row.NBSp = -1;
				Row.Name = Itm;
				Row.Synonym = Itm;
				Row.Comment = "";
				Row.StringType = TypeName;
			EndIf;
		EndDo;

		If MDObject.CharacteristicExtValues <> Undefined Then
			ItemMD = MDObject.CharacteristicExtValues;

			If Table.Find(ItemMD.FullName(), "StringType") = Undefined Then
				Row = Table.Add();
				Row.Name = ItemMD.Name;
				Row.Synonym = ItemMD.Presentation();
				Row.Comment = "";
				Row.StringType = ItemMD.FullName();
			EndIf;
		EndIf;

		Table.Sort("NBSp, StringType");

		TreeSection = TreeNode.GetItems().Add();
		Text = Nstr("ru = 'ТипыЗначенийХарактеристик';en = 'TypesOfCharacteristicValues'");
		TreeSection.Name = StrTemplate("1% (2%)" ,Text, Table.Count());

		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillPredefinedObjectItems(MDObject, TreeNode)
	If Metadata.Catalogs.Contains(MDObject) Then
		Manager = Catalogs;
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MDObject) Then
		Manager = ChartsOfCalculationTypes;
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MDObject) Then
		Manager = ChartsOfCharacteristicTypes;
	ElsIf Metadata.ChartsOfAccounts.Contains(MDObject) Then
		Manager = ChartsOfAccounts;
	Else
		Return;
	EndIf;

	Manager = Manager[MDObject.Name];

	Query = New Query;
	Query.Text = "SELCECT Ref, Presentation AS Title FROM " + MDObject.FullName() + " WHERE Predefined";

	Try
		ValueTable = Query.Execute().Unload();
	Except
		// when the access rights is absence 
		ValueTable = New ValueTable;
	EndTry;

	If ValueTable.Count() <> 0 Then
		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "Predefined (" + ValueTable.Count() + ")";

		For Each Itm In ValueTable Do
			TreeRow = TreeSection.GetItems().Add();
			TreeRow.Name = Manager.GetPredefinedNames(Itm.Ref);
			TreeRow.Synonym = Itm.Title;
			TreeRow.Comment = "";
			TreeRow.StringType = "Ref";
			TreeRow.Ref = Itm.Ref;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillPropertyCollectionObject(MDObject, TreeNode, CollectionName, Sort = True,
	SortField = "Name")
	If MDObject[CollectionName].Count() <> 0 Then
		Table = vCreatePropertiesTable();
		For Each Itm In MDObject[CollectionName] Do
			Row = Table.Add();
			Row.Name = Itm.Name;
			Row.Synonym = Itm.Presentation();
			Row.Comment = Itm.Comment;
			Row.StringType = Itm.FullName();
		EndDo;

		If Sort Then
			Table.Sort(SortField);
		EndIf;

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = CollectionName + " (" + Table.Count() + ")";
		For Each Itm In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Itm);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillObjectOwners(MDObject, TreeNode)
	vFillPropertyCollectionObject(MDObject, TreeNode, "Owners");
EndProcedure

&AtServer
Procedure FillColumnsOfJournal(MDObject, TreeNode)
	If MDObject.Columns.Count() <> 0 Then
		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "Columns";
		For Each Itm In MDObject.Columns Do
			TreeRow = TreeSection.GetItems().Add();
			TreeRow.Name = Itm.Name;
			TreeRow.Synonym = Itm.Presentation();
			TreeRow.Comment = Itm.Comment;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillObjectRecords(MDObject, TreeNode)
	If MDObject.RegisterRecords.Count() <> 0 Then

		Table = vCreatePropertiesTable();
		For Each Itm In MDObject.RegisterRecords Do
			Row = Table.Add();
			Row.Name = Itm.Name;
			Row.Synonym = Itm.Presentation();
			Row.Comment = Itm.Comment;
			Row.StringType = Itm.FullName();
		EndDo;
		Table.Sort("StringType");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "RegisterRecords (" + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillEventSource(MDObject, TreeNode)
	TypesArray = MDObject.Src.Types();
	If TypesArray.Count() <> 0 Then

		Table = vCreatePropertiesTable();
		For Each Type In TypesArray Do
			Itm = Metadata.FindByType(Type);

			Row = Table.Add();
			Row.Name = Itm.Name;
			Row.Synonym = Itm.Presentation();
			Row.Comment = Itm.Comment;
			Row.StringType = Itm.FullName();
		EndDo;
		Table.Sort("StringType");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "Sources (" + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillParametersOfCommand(MDObject, TreeNode)
	TypesArray = MDObject.CommandParameterType.Types();
	If TypesArray.Count() <> 0 Then

		Table = vCreatePropertiesTable();
		For Each Type In TypesArray Do
			Itm = Metadata.FindByType(Type);

			Row = Table.Add();
			Row.Name = Itm.Name;
			Row.Synonym = Itm.Presentation();
			Row.Comment = Itm.Comment;
			Row.StringType = Itm.FullName();
		EndDo;
		Table.Sort("StringType");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = Nstr("ru = 'Параметры команды (';en = 'Command parameters ('") + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillObjectRecorders(MDObject, TreeNode)
	TableOfResults = vGetRecorderTable(MDObject.FullName());
	If TableOfResults.Count() <> 0 Then
		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = Nstr("ru = 'Регистраторы (';en = 'Recorders ('") + TableOfResults.Count() + ")";
		For Each Itm In TableOfResults Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Itm);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillEventSubscriptionsOfObject(MDObject, TreeNode)
	If _ShowEventSubscriptions Then
		TableOfResults = vGetEventSubscriptionsTable(MDObject.FullName());
		If TableOfResults.Count() <> 0 Then
			TreeSection = TreeNode.GetItems().Add();
			TreeSection.Name = Nstr("ru = 'ПодпискиНаСобытия (';en = 'EventSubscriptions ('") + TableOfResults.Count() + ")";
			For Each Itm In TableOfResults Do
				TreeRow = TreeSection.GetItems().Add();
				FillPropertyValues(TreeRow, Itm);
				TreeRow.StringType = "EventSubscription." + Itm.Name;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure vFillSubsytemOfObject(MDObject, TreeNode)
	If _ShowObjectsSubsytems Then
		TableOfResults = vGetSubSystemTable(MDObject.FullName());
		If TableOfResults.Count() <> 0 Then
			TreeSection = TreeNode.GetItems().Add();
			TreeSection.Name = Nstr("ru = 'Подсистемы (';en = 'Subsystems ('") + TableOfResults.Count() + ")";
			For Each Itm In TableOfResults Do
				TreeRow = TreeSection.GetItems().Add();
				FillPropertyValues(TreeRow, Itm);
				TreeRow.StringType = Itm.FullName;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure vFillCommonObjectCommand(MDObject, TreeNode)
	If _ShowCommonObjectCommands Then
		TableOfResults = vGetCommonCommandsTable(MDObject.FullName());
		If TableOfResults.Count() <> 0 Then
			TreeSection = TreeNode.GetItems().Add();
			TreeSection.Name = Nstr("ru = 'ОбщиеКоманды (';en = 'CommonCommands ('") + TableOfResults.Count() + ")";			
			For Each Itm In TableOfResults Do
				TreeRow = TreeSection.GetItems().Add();
				FillPropertyValues(TreeRow, Itm);
				TreeRow.StringType = "CommonCommand." + Itm.Name;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure vFillOtherObjectCommand(MDObject, TreeNode)
	If _ShowExternalObjectCommands Then
		TableOfResults = vGetExternalCommandsTable(MDObject.FullName());
		If TableOfResults.Count() <> 0 Then
			TreeSection = TreeNode.GetItems().Add();
			TreeSection.Name = Nstr("ru = 'ЧужиеКоманды (';en = 'OtherCommands ('") + TableOfResults.Count() + ")";			
			For Each Itm In TableOfResults Do
				TreeRow = TreeSection.GetItems().Add();
				FillPropertyValues(TreeRow, Itm);
				TreeRow.StringType = Itm.Name;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure vFillStandartObjectsAttributes(MDObject, TreeNode)
	If MDObject.StandardAttributes.Count() <> 0 Then
		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = Nstr("ru = 'СтандартныеРеквизиты';en = 'StandardAttributes'");
		For Each Itm In MDObject.StandardAttributes Do
			TreeRow = TreeSection.GetItems().Add();
			TreeRow.Name = Itm.Name;
			TreeRow.Synonym = Itm.Presentation();
			TreeRow.Comment = Itm.Comment;
			//TreeRow.StringType = Itm.FullName();
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFillObjectSpecialProperties(MDObject, TreeNode, PropertyName)
	If MDObject[PropertyName].Count() <> 0 Then
		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = PropertyName;
		For Each Itm In MDObject[PropertyName] Do
			TreeRow = TreeSection.GetItems().Add();
			TreeRow.Name = Itm.Name;
			TreeRow.Synonym = Itm.Presentation();
			TreeRow.Comment = Itm.Comment;
			TreeRow.StringType = Itm.FullName();
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure vFullInConfigurationProperties()
	MDObject = Metadata;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = MDObject.FullName();

	PropertiesList = "
					  |Copyright, ConfigurationInformationAddress, VendorInformationAddress, UpdateCatalogAddress,
					  |ScriptVariant, Version, IncludeHelpInContents,
					  |UseOrdinaryFormInManagedApplication, UseManagedFormInOrdinaryApplication,
					  |DefaultReportVariantForm, DefaultConstantsForm, DefaultDynamicListSettingsForm, DefaultReportSettingsForm, DefaultReportForm, DefaultSearchForm,
					  |DefaultInterface, DefaultRunMode, DefaultLanguage,
					  |ObjectAutonumerationMode, ModalityUseMode, SynchronousPlatformExtensionAndAddInCallUseMode,
					  |MainClientApplicationWindowMode, CompatibilityMode, InterfaceCompatibilityMode, DataLockControlMode";

	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
EndProcedure

&AtServer
Procedure vFullInCatalogProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = Catalogs[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Autonumbering, Hierarchical, HierarchyType, FoldersOnTop, CodeType, CodeLength, DescriptionLength, CheckUnique, CodeSeries, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectOwners(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillPredefinedObjectItems(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInDocumentProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = Documents[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Autonumbering, NumberLength, RealTimePosting, Posting, CheckUnique, NumberPeriodicity, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillObjectRecords(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInDocumentJournalProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	vFillStandartObjectsAttributes(MDObject, TreeNode);
	FillColumnsOfJournal(MDObject, TreeNode);
	vFillPropertyCollectionObject(MDObject, TreeNode, "RegisteredDocuments");
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInChartOfCharacteristicTypesProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = ChartsOfCharacteristicTypes[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Autonumbering, Hierarchical, FoldersOnTop, CodeLength, DescriptionLength, CheckUnique, CodeSeries, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillValuesTypeOfCharacteristic(MDObject, TreeNode);
	vFillPredefinedObjectItems(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInChartOfCalculationTypesProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = ChartsOfCalculationTypes[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "CodeLength, DescriptionLength, CodeType, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillPredefinedObjectItems(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInChartOfAccountsProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = ChartsOfAccounts[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "AutoOrderByCode, CodeLength, DescriptionLength, OrderLength, CheckUnique, CodeMask, CodeSeries, DataLockFields, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectSpecialProperties(MDObject, TreeNode, "AccountingFlags");
	vFillObjectSpecialProperties(MDObject, TreeNode, "ExtDimensionAccountingFlags");
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillPredefinedObjectItems(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInInformationRegisterProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "InformationRegisterPeriodicity, WriteMode, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Dimensions", False);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Resources", True);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Attributes", True);
	vFillObjectRecorders(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInAccumulationRegisterProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "RegisterType, EnableTotalsSplitting, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Dimensions", False);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Resources", True);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Attributes", True);
	vFillObjectRecorders(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInAccountingRegisterProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Correspondence, ChartOfAccounts, EnableTotalsSplitting, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Dimensions", False);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Resources", True);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Attributes", True);
	vFillObjectRecorders(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInCalculationRegisterProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "BasePeriod, ActionPeriod, Periodicity, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Dimensions", False);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Resources", True);
	vFillObjectGroupOfProperties(MDObject, TreeNode, "Attributes", True);
	vFillObjectRecorders(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInBusinessProcessProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = BusinessProcesses[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Autonumbering, NumberLength, Task, NumberType, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInTaskProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = Tasks[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Autonumbering, Addressing, NumberLength, DescriptionLength, CheckUnique, NumberType, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);
	vFillObjectCommands(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInExchangePlanProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	_EmptyRef = ExchangePlans[MDObject.Name].EmptyRef();

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "CodeLength, DescriptionLength, CodeAllowedLength, DataLockControlMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillStandartObjectsAttributes(MDObject, TreeNode);
	vFillObjectAttrebutes(MDObject, TreeNode);
	vFillObjectTabularSection(MDObject, TreeNode);

	If MDObject.Content.Count() <> 0 Then
		StructureOfTypes = vCreateStructureOfTypes();

		Table = vCreatePropertiesTable();
		For Each Itm In MDObject.Content Do
			Row = Table.Add();
			//Row.Name = Itm.Metadata.Name;
			//Row.Name = Itm.Metadata.Name + " (" + Itm.AutoRecord + ")";
			Row.Name = "AutoRecord: " + Itm.AutoRecord;
			Row.Synonym = Itm.Metadata.Presentation();
			Row.Comment = Itm.Metadata.Comment;
			Row.StringType = Itm.Metadata.FullName();
		EndDo;
		Table.Sort("StringType");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "Content (" + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;

	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInEnumProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	For Each Itm In MDObject.EnumValues Do
		TreeRow = TreeNode.GetItems().Add();
		TreeRow.Name = Itm.Name;
		TreeRow.Synonym = Itm.Presentation();
		TreeRow.Comment = Itm.Comment;
	EndDo;

	vFillObjectCommands(MDObject, TreeNode);
	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInCommonModuleProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "ExternalConnection, ServerCall, Global, ClientOrdinaryApplication, ClientManagedApplication, ReturnValuesReuse, Privileged, Server";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInConstantProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	TypesArray = MDObject.Type.Types();
	If TypesArray.Count() <> 0 Then
		StructureOfTypes = vCreateStructureOfTypes();

		Table = vCreatePropertiesTable();
		For Each Itm In TypesArray Do
			Row = Table.Add();
			Row.Name = vTypeNameToString(StructureOfTypes, Itm, MDObject.Type);
			Row.Synonym = Itm;
			Row.StringType = Row.Name;
		EndDo;
		Table.Sort("Name");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = "Types (" + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;

	vFillSubsytemOfObject(MDObject, TreeNode);
	
	// check the rights
	If Not AccessRight("Read", MDObject) Then
		Return;
	EndIf;

	Items.ValuePage.Visible = True;
	Items._ConstantValue.TypeRestriction = MDObject.Type;
	Items._TextConstantValue.ReadOnly = Not MDObject.Type.ContainsType(Type("String"));
	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;

	pStruct = vGetConstant(_FullName);
	If pStruct.Cancel Then
		_TypeOfConstantValue = pStruct.ReasonForRefusal;
	Else
		_ConstantValue = pStruct.Value;
		_TypeOfConstantValue = pStruct.ValueType;
		If TypeOf(pStruct.Value) = Type("String") Then
			_TextConstantValue = pStruct.Value;
		Else
			_TextConstantValue = pStruct.Text;
		EndIf;
	EndIf;

	If pStruct.ReadOnly Then
		Items._TextConstantValue.ReadOnly = True;
		Items._ConstantValue.ReadOnly = True;
		Items._RecordConstant.Enabled = False;
	EndIf;

	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;
EndProcedure

&AtServer
Procedure vFullInSessionParameterProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	TypesArray = MDObject.Type.Types();
	If TypesArray.Count() <> 0 Then
		StructureOfTypes = vCreateStructureOfTypes();

		Table = vCreatePropertiesTable();
		For Each Itm In TypesArray Do
			Row = Table.Add();
			Row.Name = vTypeNameToString(StructureOfTypes, Itm, MDObject.Type);
			Row.Synonym = Itm;
			Row.StringType = Row.Name;
		EndDo;
		Table.Sort("Name");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = NStr("ru = 'Типы (';en = 'Types ('") + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;

	vFillSubsytemOfObject(MDObject, TreeNode);
	
	// checking the rights
	If Not AccessRight("Receive", MDObject) Then
		Return;
	EndIf;

	Items.ValuePage.Visible = True;
	Items._ConstantValue.TypeRestriction = MDObject.Type;
	Items._TextConstantValue.ReadOnly = Not MDObject.Type.ContainsType(Type("String"));
	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;

	pStruct = vGetConstant(_FullName);
	If pStruct.Cancel Then
		_TypeOfConstantValue = pStruct.ReasonForRefusal;
	Else
		_ConstantValue = pStruct.Value;
		_TypeOfConstantValue = pStruct.ValueType;
		If TypeOf(pStruct.Value) = Type("String") Then
			_TextConstantValue = pStruct.Value;
		Else
			_TextConstantValue = pStruct.Text;
		EndIf;
	EndIf;

	If pStruct.ReadOnly Then
		Items._TextConstantValue.ReadOnly = True;
		Items._ConstantValue.ReadOnly = True;
		Items._RecordConstant.Enabled = False;
	EndIf;

	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;

	Items._ConstantValue.Title =  NStr("ru = 'Значение параметра';en = 'Parameter value'");
EndProcedure

&AtServer
Procedure vFullInCommonCommandProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Group, ModifiesData, ShowInChart, ToolTip, ParameterUsageMode";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillParametersOfCommand(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInEventSubscriptionProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "Handler, Event";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillEventSource(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInSubSystemProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	PropertiesList = "IncludeInCommandInterface, Explanation";
	vFillPropertiesOfObject(MDObject, TreeNode, PropertiesList);
	vFillPropertyCollectionObject(MDObject, TreeNode, "Subsystems");
	vFillPropertyCollectionObject(MDObject, TreeNode, "Content", True, "StringType");
EndProcedure

&AtServer
Procedure vFullInDefinedTypeProperty(FullName)
	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return;
	EndIf;

	TreeNode = PropertyTree.GetItems().Add();
	TreeNode.Name = MDObject.Name;
	TreeNode.Synonym = MDObject.Presentation();
	TreeNode.Comment = MDObject.Comment;
	TreeNode.StringType = FullName;

	TypesArray = MDObject.Type.Types();
	If TypesArray.Count() <> 0 Then
		StructureOfTypes = vCreateStructureOfTypes();

		Table = vCreatePropertiesTable();
		For Each Itm In TypesArray Do
			Row = Table.Add();
			Row.Name = vTypeNameToString(StructureOfTypes, Itm, MDObject.Type);
			Row.Synonym = Itm;
			Row.StringType = Row.Name;
		EndDo;
		Table.Sort("Name");

		TreeSection = TreeNode.GetItems().Add();
		TreeSection.Name = NsTR("ru = 'Типы (';en = 'Types ('") + Table.Count() + ")";
		For Each Row In Table Do
			TreeRow = TreeSection.GetItems().Add();
			FillPropertyValues(TreeRow, Row);
		EndDo;
	EndIf;

	vFillCommonObjectCommand(MDObject, TreeNode);
	vFillOtherObjectCommand(MDObject, TreeNode);
	vFillEventSubscriptionsOfObject(MDObject, TreeNode);
	vFillSubsytemOfObject(MDObject, TreeNode);
EndProcedure

&AtServer
Procedure vFullInTotalControlPage(FullName)
	Try
		pStruct = vGetRegisterPropertiesToManageTotals(FullName);
	Except
		Return;
	EndTry;

	If Not pStruct.HasData Then
		Return;
	EndIf;

	Items.ManagingTotalsPage.Visible = True;

	_AggregateMode = pStruct.AggregatesMode;
	_UseAggregates = pStruct.AggregatesUsing;
	_UseTotals = pStruct.TotalsUsing;
	_UseCurrentTotals = pStruct.PresentTotalsUsing;
	_DividingTotalsMode = pStruct.TotalsSplittingMode;
	_MinimumPeriodOfCalculatedTotals = pStruct.MinimumPeriodOfCalculatedTotals;
	_MaximumPeriodOfCalculatedTotals = pStruct.MaximumPeriodOfCalculatedTotals;

	Items._AggregateMode.Visible = Not pStruct.IsAccountingRegister;
	Items._AggregateMode.Enabled = pStruct.HasAggregateMode;
	Items._UseAggregates.Visible = Not pStruct.IsAccountingRegister;
	Items._UseAggregates.Enabled = pStruct.HasAggregateMode And _AggregateMode;

	Items._UseTotals.Enabled = Not _AggregateMode;
	Items._UseCurrentTotals.Enabled = pStruct.HasCurrentTotals And Not _AggregateMode;

	Items._RecalculateTotals.Enabled = Not _AggregateMode;
	Items._RecalculateCurrentTotals.Enabled = pStruct.HasCurrentTotals And Not _AggregateMode;

	Items.RecalculateTotalsForPeriodGroup.Enabled = Not _AggregateMode;
	Items.CalculatedTotalsGroup.Enabled = Not pStruct.TurnoversRegister And Not _AggregateMode;

EndProcedure

&AtServerNoContext
Function vGetRegisterPropertiesToManageTotals(FullName)
	pStruct = New Structure("HasData, IsAccountingRegister, TurnoversRegister", False, False, False);

	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return pStruct;
	EndIf;

	pStruct.HasData = True;
	pStruct.Insert("Name", MDObject.Name);

	pEmptyDate = '00010101';
	pStruct.Insert("Date1", pEmptyDate);
	pStruct.Insert("Date2", pEmptyDate);

	If Metadata.AccountingRegisters.Contains(MDObject) Then
		pStruct.IsAccountingRegister = True;
		pStruct.Insert("HasTotalsPeriod", True);
		pStruct.Insert("HasAggregateMode", False);
		pStruct.Insert("HasCurrentTotals", True);
		pManager = AccountingRegisters[pStruct.Name];
	Else
		pStruct.TurnoversRegister = (MDObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers);
		pStruct.Insert("HasTotalsPeriod", Not pStruct.TurnoversRegister);
		pStruct.Insert("HasAggregateMode", pStruct.TurnoversRegister);
		pStruct.Insert("HasCurrentTotals", Not pStruct.TurnoversRegister);
		pManager = AccumulationRegisters[pStruct.Name];
	EndIf;

	If pStruct.HasTotalsPeriod Then
		pStruct.Insert("Date1", pManager.GetMinTotalsPeriod());
		pStruct.Insert("Date2", pManager.GetMaxTotalsPeriod());
	EndIf;

	pStruct.Insert("AggregatesMode", ?(pStruct.HasAggregateMode, pManager.GetAggregatesMode(), False));
	pStruct.Insert("AggregatesUsing", ?(pStruct.HasAggregateMode, pManager.GetAggregatesUsing(),
		False));
	pStruct.Insert("PresentTotalsUsing", ?(pStruct.HasCurrentTotals,
		pManager.GetPresentTotalsUsing(), False));
	pStruct.Insert("TotalsUsing", pManager.GetTotalsUsing());
	pStruct.Insert("TotalsSplittingMode", pManager.GetTotalsSplittingMode());
	pStruct.Insert("MinimumPeriodOfCalculatedTotals", ?(pStruct.TurnoversRegister, pEmptyDate,
		pManager.GetMinTotalsPeriod()));
	pStruct.Insert("MaximumPeriodOfCalculatedTotals", ?(pStruct.TurnoversRegister, pEmptyDate,
		pManager.GetMaxTotalsPeriod()));

	Return pStruct;
EndFunction



// storage structure

&AtClient
Procedure _ShowStorageStructureIn1CTermsOnChange(Item)
	_SXIndexes.Clear();
	_SXFielsd.Clear();
	_SXIndexFields.Clear();
	_SXTable.Clear();

	vFullInSectionOfStorage();
EndProcedure

&AtServer
Procedure vFullInSectionOfStorage(Val SXData = Undefined)
	If SXData = Undefined Then
		MDObject = Metadata.FindByFullName(_FullName);
		If MDObject <> Undefined Then
			SXData = GetDBStorageStructureInfo(vValueToArray(MDObject),
				Not _ShowStorageStructureIn1CTerms);
			If SXData = Undefined Or SXData.Count() = 0 Then
				Return;
			EndIf;
		Else
			Return;
		EndIf;
	EndIf;

	NumberX = 0;
	NumberXX = 0;

	For Each Row In SXData Do
		NumberX = NumberX + 1;
		TableNumber = "(" + NumberX + ")";

		NewLine = _SXTable.Add();
		FillPropertyValues(NewLine, Row);
		NewLine.TableNumber = TableNumber;
		If IsBlankString(NewLine.TableName) Then
			NewLine.TableName = _FullName + "(" + Row.Purpose + ")";
		EndIf;

		For Each LineX In Row.Fields Do
			NewLine = _SXFielsd.Add();
			FillPropertyValues(NewLine, LineX);
			NewLine.StorageTableName = Row.StorageTableName;
			NewLine.TableNumber = TableNumber;
		EndDo;
		For Each LineX In Row.Indexes Do
			NumberXX = NumberXX + 1;
			IndexNumber = "(" + NumberXX + ")";

			NewLine = _SXIndexes.Add();
			FillPropertyValues(NewLine, LineX);
			NewLine.StorageTableName = Row.StorageTableName;
			NewLine.TableNumber = TableNumber;
			NewLine.IndexNumber = IndexNumber;

			For Each LineXX In LineX.Fields Do
				NewLine = _SXIndexFields.Add();
				FillPropertyValues(NewLine, LineXX);
				NewLine.IndexNumber = IndexNumber;
			EndDo;
		EndDo;

	EndDo;
EndProcedure

&AtClient
Procedure _SXTableOnActivateRow(Item)
	CurData = Item.CurrentData;
	If CurData <> Undefined Then
		Items._SXFielsd.RowFilter = New FixedStructure("TableNumber", CurData.TableNumber);
		Items._SXIndexes.RowFilter = New FixedStructure("TableNumber", CurData.TableNumber);
	EndIf;
EndProcedure

&AtClient
Procedure _SXIndexesOnActivateRow(Item)
	CurData = Item.CurrentData;
	If CurData <> Undefined Then
		Items._SXIndexFields.RowFilter = New FixedStructure("IndexNumber", CurData.IndexNumber);
	EndIf;
EndProcedure

&AtClient
Procedure _UpdateNumberOfObjects(Command)
	If Not vHaveAdministratorRights() Then
		TextMassage = Nstr("ru = 'Нет прав на выполнение операции!';en = 'No rights to perform the operation!'");
		ShowMessageBox( , TextMassage, 20);
		Return;
	EndIf;

	pText = ?(_FullName = "Configuration", 
		Nstr("ru = 'Нумерация всех объектов будет обновлена. Продолжить?';en = 'The numbering of all objects will be updated. Continue?'"),
		Nstr("ru = 'Нумерация обекта будет обновлена. Продолжить?';en = 'The numbering of object will be updated. Continue?'"));

	ShowQueryBox(New NotifyDescription("vUpdateNumberOfObjectsResponse", ThisForm), pText,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure vUpdateNumberOfObjectsResponse(QuestionResult, AdditionalParams = Undefined) Export
	If QuestionResult = DialogReturnCode.Yes Then
		vUpdateNumberingOfObjects(_FullName);
	EndIf;
EndProcedure

&AtServerNoContext
Function vUpdateNumberingOfObjects(Val FullName)
	If FullName = "Configuration" Then
		Try
			RefreshObjectsNumbering();
		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;

	ElsIf StrFind(FullName, ".") <> 0 Then
		MDObject = Metadata.FindByFullName(FullName);

		If MDObject <> Undefined Then
			Try
				RefreshObjectsNumbering(MDObject);
			Except
				Message(BriefErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndIf;

	Return True;
EndFunction


// managing  totals
&AtClient
Procedure _UpdateTotalsManagement(Command)
	vFullInTotalControlPage(_FullName);
EndProcedure

&AtClient
Procedure _RecalculateTotals(Command)
	vShowQuestion("vProcessTotalsManagementCommand", Nstr("ru = 'Будет выполнен полный пересчет итогов. Продолжить?';en = 'A complete recalculation of the totals will be performed. Continue?'"),
		"RecalcTotals");
EndProcedure

&AtClient
Procedure _RecalculateCurrentTotals(Command)
	vShowQuestion("vProcessTotalsManagementCommand", Nstr("ru = 'Текущие итоги будут пересчитаны. Продолжить?';en = 'The current totals will be recalculated. Continue?'"),
		"RecalcPresentTotals");
EndProcedure

&AtClient
Procedure _RecalculateTotalsForThePeriod(Command)
	vShowQuestion("vProcessTotalsManagementCommand", Nstr("ru = 'Будут пересчитаны итоги за заданный период. Продолжить?';en = 'The totals for the specified period will be recalculated. Continue?'"),
		"RecalcTotalsForPeriod");
EndProcedure

&AtClient
Procedure _InstallPriodOfCalculatedTotals(Command)
	pName = ThisForm.CurrentItem.Name;
	If Right(pName, 1) = "1" Then
		vShowQuestion("vProcessTotalsManagementCommand",
			Nstr("ru = 'Будет изменен минимальный период рассчитанных итогов. Продолжить?';en = 'The minimum period of calculated totals will be changed. Continue?'"),
			"SetMinTotalsPeriod");
	ElsIf Right(pName, 1) = "2" Then
		vShowQuestion("vProcessTotalsManagementCommand",
			Nstr("ru = 'Будет изменен максимальный период рассчитанных итогов. Продолжить?';en = 'The maximum period of calculated totals will be changed. Continue?'"),
			"SetMaxTotalsPeriod");
	EndIf;
EndProcedure

&AtClient
Procedure vProcessTotalsManagementCommand(QuestionResult, CommandName) Export
	If QuestionResult = DialogReturnCode.Yes Then
		pStruct = vGetNewTotalsManagementSettings();
		pStruct.Insert("CommandName", CommandName);

		pResult = vRunTotalsManagementCommand(_FullName, CommandName, pStruct);
		_UpdateTotalsManagement(Undefined);
	EndIf;
EndProcedure

&AtClient
Function vGetNewTotalsManagementSettings()
	pStruct = New Structure;
	pStruct.Insert("PeriodRecalculationTotals", _PeriodRecalculationTotals);
	pStruct.Insert("MinimumPeriodOfCalculatedTotals", _MinimumPeriodOfCalculatedTotals);
	pStruct.Insert("MaximumPeriodOfCalculatedTotals", _MaximumPeriodOfCalculatedTotals);

	Return pStruct;
EndFunction

&AtClient
Procedure _RegistryPropertyOnChange(Item)
	vShowQuestion("vProcessRegisterPropertyChange", NStr("ru = 'Свойство регистра будет изменено. Продолжить?';en = 'The register property will be changed. Continue?'"),
		Item.Name);
EndProcedure

&AtClient
Procedure vProcessRegisterPropertyChange(QuestionResult, PropertyName) Export
	If QuestionResult = DialogReturnCode.Yes Then
		vChangeRegisterProperty(_FullName, Mid(PropertyName, 2), ThisForm[PropertyName]);
		_UpdateTotalsManagement(Undefined);
	Else
		ThisForm[PropertyName] = Not ThisForm[PropertyName];
	EndIf;
EndProcedure

&AtServerNoContext
Function vRunTotalsManagementCommand(Val FullName, Val CommandName, Val pSettingsStructure)
	If Not vHaveAdministratorRights() Then
		Message(NStr("ru = 'Нет прав на выполнение операции!';en = 'No rights to perform the operation!'"));
		Return False;
	EndIf;

	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return False;
	EndIf;

	If Metadata.AccountingRegisters.Contains(MDObject) Then
		pManager = AccountingRegisters[MDObject.Name];
	Else
		pManager = AccumulationRegisters[MDObject.Name];
	EndIf;

	Try
		If CommandName = "RecalcTotals" Then
			pManager.RecalcTotals();
		ElsIf CommandName = "RecalcPresentTotals" Then
			pManager.RecalcPresentTotals();
		ElsIf CommandName = "RecalcTotalsForPeriod" Then
			Date1 = pSettingsStructure.PeriodRecalculationTotals.StartDate;
			Date2 = pSettingsStructure.PeriodRecalculationTotals.EndDate;
			pManager.RecalcTotalsForPeriod(Date1, Date2);
		ElsIf CommandName = "SetMinTotalsPeriod" Then
			pManager.SetMinTotalsPeriod(pSettingsStructure.MinimumPeriodOfCalculatedTotals);
		ElsIf CommandName = "SetMaxTotalsPeriod" Then
			pManager.SetMaxTotalsPeriod(
				pSettingsStructure.MaximumPeriodOfCalculatedTotals);
		Else
			Return False;
		EndIf;
	Except
		Message(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;

	Return True;
EndFunction

&AtServerNoContext
Function vChangeRegisterProperty(Val FullName, Val PropertyName, Val pValue)
	If Not vHaveAdministratorRights() Then
		Message(NStr("ru = 'Нет прав на выполнение операции!';en = 'No rights to perform the operation!'"));
		Return False;
	EndIf;

	MDObject = Metadata.FindByFullName(FullName);
	If MDObject = Undefined Then
		Return False;
	EndIf;

	If Metadata.AccountingRegisters.Contains(MDObject) Then
		pManager = AccountingRegisters[MDObject.Name];
	Else
		pManager = AccumulationRegisters[MDObject.Name];
	EndIf;

	Try
		If PropertyName = "AggregatesMode" Then
			pManager.SetAggregatesMode(pValue);
		ElsIf PropertyName = "AggregatesUsing" Then
			pManager.SetAggregatesUsing(pValue);
		ElsIf PropertyName = "TotalsUsing" Then
			pManager.SetTotalsUsing(pValue);
		ElsIf PropertyName = "PresentTotalsUsing" Then
			pManager.SetPresentTotalsUsing(pValue);
		ElsIf PropertyName = "TotalsSplittingMode" Then
			pManager.SetTotalsSplittingMode(pValue);
		Else
			Return False;
		EndIf;
	Except
		Message(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;

	Return True;
EndFunction


// access rights
&AtClient
Procedure _AvailableObjectsSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	_OpenAccessRightsObject(Undefined);
EndProcedure

&AtClient
Procedure _FullInAccessRights(Command)
	pIsRole = (StrFind(_FullName, "Role.") = 1);

	UsersWithAccessTable.Clear();

	If pIsRole Then
		_AvailableObjects.Clear();

		If IsBlankString(_AccessRightToObject) Then
			Return;
		EndIf;

		pResultStructure = vGetAvailableObjectsForRole(_FullName, _AccessRightToObject,
			_AdditionalVars.DescriptionOfAccessRights);
		If pResultStructure.HasData Then
			For Each Itm In pResultStructure.AvailableObjects Do
				FillPropertyValues(_AvailableObjects.Add(), Itm);
			EndDo;
			_AvailableObjects.Sort("Kind, FullName");

			For Each Itm In pResultStructure.Users Do
				FillPropertyValues(UsersWithAccessTable.Add(), Itm);
			EndDo;
			UsersWithAccessTable.Sort("Name");
		EndIf;

	Else
		RolesWithAccessTable.Clear();

		If IsBlankString(_AccessRightToObject) Then
			Return;
		EndIf;

		pResultStructure = vGetAccessRightsToObject(_AccessRightToObject, _FullName);
		If pResultStructure.HasData Then
			For Each Itm In pResultStructure.Roles Do
				FillPropertyValues(RolesWithAccessTable.Add(), Itm);
			EndDo;

			For Each Itm In pResultStructure.Users Do
				FillPropertyValues(UsersWithAccessTable.Add(), Itm);
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _AccessRightToObjectOnChange(Item)
	_FullInAccessRights(Undefined);
EndProcedure

&AtClient
Procedure RolesWithAccessTableSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	_OpenAccessRightsObject(Undefined);
EndProcedure

&AtClient
Procedure UsersWithAccessTableSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	_OpenAccessRightsObject(Undefined);
EndProcedure

&AtClient
Procedure _OpenAccessRightsObject(Command)
	pPageName = Items.AccessRightToObject.CurrentPage.Name;

	If pPageName = "AccessRightToObject_Role" Then
		CurData = Items.RolesWithAccessTable.CurrentData;
		If CurData <> Undefined Then
			vShowObjectProperties("Role." + CurData.Name);
		EndIf;

	ElsIf pPageName = "AccessRightToObject_Users" Then
		CurData = Items.UsersWithAccessTable.CurrentData;
		If CurData <> Undefined Then
			pUserId = vGetUserID(CurData.Name);

			If Not IsBlankString(pUserId) Then
				pStruct = New Structure("WorkMode, DBUserID", 0, pUserId);
				OpenForm(PathToForms + "InfoBaseUserForm", pStruct, , , , , ,
					FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
		EndIf;

	ElsIf pPageName = "_AccessRightForRole" Then
		CurData = Items._AvailableObjects.CurrentData;
		If CurData <> Undefined And Not IsBlankString(CurData.FullName) Then
			vShowObjectProperties(CurData.FullName);
		EndIf;

	EndIf;
EndProcedure
&AtServerNoContext
Function vGetUserID(Val Name)
	pUser = InfoBaseUsers.FindByName(Name);

	Return ?(pUser = Undefined, "", String(pUser.UUID));
EndFunction

&AtServerNoContext
Function vGetDescriptionOfRestrictionsForAccessParameters()
	vRestrictedObjects = New Map;
	vRestrictedObjects.Insert("ExchangePlan", "Ref");
	vRestrictedObjects.Insert("Catalog", "Ref");
	vRestrictedObjects.Insert("Document", "Ref");
	vRestrictedObjects.Insert("DocumentJournal", "Ref");
	vRestrictedObjects.Insert("ChartOfCharacteristicTypes", "Ref");
	vRestrictedObjects.Insert("ChartOfAccounts", "Ref");
	vRestrictedObjects.Insert("ChartOfCalculationTypes", "Ref");
	vRestrictedObjects.Insert("InformationRegister", Undefined);
	vRestrictedObjects.Insert("AccumulationRegister", "Recorder");
	vRestrictedObjects.Insert("AccountingRegister", "Recorder");
	vRestrictedObjects.Insert("CalculationRegister", "Recorder");
	vRestrictedObjects.Insert("BusinessProcess", "Ref");
	vRestrictedObjects.Insert("Task", "Ref");

	Return vRestrictedObjects;
EndFunction

&AtServerNoContext
Function vRolesAndUsersTable()
	_TableRolesAndUsers = New ValueTable;
	_TableRolesAndUsers.Columns.Add("NameR", New TypeDescription("String"));
	_TableRolesAndUsers.Columns.Add("NameUsr", New TypeDescription("String"));
	_TableRolesAndUsers.Columns.Add("FullNameUsr", New TypeDescription("String"));

	For Each Usr In InfoBaseUsers.GetUsers() Do
		For Each Role In Usr.Roles Do
			NewLine = _TableRolesAndUsers.Add();
			NewLine.NameR = Role.Name;
			NewLine.NameUsr = Usr.Name;
			NewLine.FullNameUsr = Usr.FullName;
		EndDo;
	EndDo;

	_TableRolesAndUsers.Indexes.Add("NameR");
	_TableRolesAndUsers.Indexes.Add("NameUsr");

	Return _TableRolesAndUsers;
EndFunction

&AtServerNoContext
Function vGetAvailableObjectsForRole(Val pRole, Val pRight, Val DescriptionOfAccessRights)
	pResult = New Structure("HasData, AvailableObjects, Users", False);

	pRoleMetadata = Metadata.FindByFullName(pRole);
	If pRole = Undefined Then
		Return pResult;
	EndIf;

	pResult.HasData = True;
	pResult.Insert("AvailableObjects", New Array);
	pResult.Insert("Users", New Array);

	For Each User In InfoBaseUsers.GetUsers() Do
		For Each Р In User.Roles Do
			If Р.Name = pRoleMetadata.Name Then
				pStruct = New Structure("Name, FullName");
				FillPropertyValues(pStruct, User);
				pResult.Users.Add(pStruct);
			EndIf;
		EndDo;
	EndDo;

	pStructObjectsWithRestrictions = New Structure;
	pStructObjectsWithRestrictions.Insert("Catalog");
	pStructObjectsWithRestrictions.Insert("Document");

	vRestrictedObjects = vGetDescriptionOfRestrictionsForAccessParameters();

	pResultFields = "RestrictionByCondition, Kind, Name, Presentation, FullName";

	UsersTable = New ValueTable;
	UsersTable.Columns.Add("Name", New TypeDescription("String"));
	UsersTable.Columns.Add("FullName", New TypeDescription("String"));

	pTabObjects = New ValueTable;
	pTabObjects.Columns.Add("FullName", New TypeDescription("String"));
	pTabObjects.Columns.Add("MDObject", New TypeDescription("MetadataObject"));

	pStruct = New Structure("
							 |SessionParameters,
							 |CommonCommands,
							 |ExchangePlans,
							 |Catalogs,
							 |Documents,
							 |DocumentJournals,
							 |BusinessProcesses,
							 |Tasks,
							 |InformationRegisters,
							 |AccumulationRegisters,
							 |AccountingRegisters,
							 |CalculationRegisters
							 |");

	For Each Itm In pStruct Do
		For Each MDObject In Metadata[Itm.Key] Do
			NewLine = pTabObjects.Add();
			NewLine.FullName = MDObject.FullName();
			NewLine.MDObject = MDObject;

			pStruct = New Structure("Commands");
			FillPropertyValues(pStruct, MDObject);

			If pStruct.Commands <> Undefined Then
				For Each pCommand In MDObject.Commands Do
					NewLine = pTabObjects.Add();
					NewLine.FullName = pCommand.FullName();
					NewLine.MDObject = pCommand;
				EndDo;
			EndIf;
		EndDo;
	EndDo;

	For Each Row In pTabObjects Do
		pStruct = New Structure(pResultFields);

		pFullName = Row.MDObject.FullName();
		If StrFind(pFullName, ".Command.") <> 0 Then
			Pos1 = StrFind(pFullName, ".", SearchDirection.FromEnd);
			pStruct.Kind = "OtherCommand";
			pStruct.Name = Mid(pFullName, Pos1 + 1);
		Else
			Pos1 = StrFind(pFullName, ".");
			pStruct.Kind = Left(pFullName, Pos1 - 1);
			pStruct.Name = Mid(pFullName, Pos1 + 1);
		EndIf;

		pRightsList = DescriptionOfAccessRights[pStruct.Kind];

		If pRightsList = Undefined Then
			Continue;
		ElsIf StrFind(pRightsList, pRight) = 0 Then
			Continue;
		EndIf;

		If AccessRight(pRight, Row.MDObject, pRoleMetadata) Then

			pStruct.FullName = pFullName;
			pStruct.Presentation = Row.MDObject.Presentation();

			pField = vRestrictedObjects[pStruct.Kind];
			If pField <> Undefined Then
				pStruct.RestrictionByCondition = AccessParameters(pRight, Row.MDObject, pField, pRoleMetadata).RestrictionByCondition;
			ElsIf pStruct.Kind = "InformationRegister" And Row.MDObject.Dimensions.Count() <> 0 Then
				pField = Row.MDObject.Dimensions[0].Name;
				pStruct.RestrictionByCondition = AccessParameters(pRight, Row.MDObject, pField, pRoleMetadata).RestrictionByCondition;
			EndIf;

			pResult.AvailableObjects.Add(pStruct);
		EndIf;
	EndDo;

	Return pResult;
EndFunction

&AtServerNoContext
Function vGetAccessRightsToObject(Val ИмяПрава, Val FullName)
	СтрукРезультат = New Structure("HasData, Roles, Users", False);

	If IsBlankString(ИмяПрава) Then
		Return СтрукРезультат;
	EndIf;

	vRestrictedObjects = vGetDescriptionOfRestrictionsForAccessParameters();

	ТабРоли = New ValueTable;
	ТабРоли.Columns.Add("RestrictionByCondition", New TypeDescription("Boolean"));
	ТабРоли.Columns.Add("Name", New TypeDescription("String"));
	ТабРоли.Columns.Add("Synonym", New TypeDescription("String"));

	UsersTable = New ValueTable;
	UsersTable.Columns.Add("Name", New TypeDescription("String"));
	UsersTable.Columns.Add("FullName", New TypeDescription("String"));

	If StrFind(FullName, ".Command.") <> 0 Then
		MDType = "OtherCommand";
	Else
		MDType = Left(FullName, StrFind(FullName, ".") - 1);
	EndIf;

	If MDType <> "User" Then
		MDObject = Metadata.FindByFullName(FullName);

		If MDObject = Undefined Then
			Return СтрукРезультат;
		EndIf;
	EndIf;

	If MDType = "InformationRegister" And MDObject.Dimensions.Count() <> 0 Then
		pField = MDObject.Dimensions[0].Name;
		vRestrictedObjects[MDType] = pField;
	EndIf;

	ЭтоОбычныйРежим = True;

	If ЭтоОбычныйРежим And IsBlankString(ИмяПрава) Then
		Return СтрукРезультат;
	EndIf;
	If ЭтоОбычныйРежим Then
		For Each Itm In Metadata.Roles Do
			If AccessRight(ИмяПрава, MDObject, Itm) Then
				NewLine = ТабРоли.Add();
				FillPropertyValues(NewLine, Itm);

				pField = vRestrictedObjects[MDType];
				If pField <> Undefined Then
					NewLine.RestrictionByCondition = AccessParameters(ИмяПрава, MDObject, pField, Itm).RestrictionByCondition;
				EndIf;
			EndIf;
		EndDo;

		ТабРоли.Sort("Name");
	EndIf;

	_TableRolesAndUsers = vRolesAndUsersTable();

	If ЭтоОбычныйРежим Then
		StructureR = New Structure("NameR");
		StructureP = New Structure("Name");

		For Each Row In ТабРоли Do
			StructureR.NameR = Row.Name;
			For Each LineX In _TableRolesAndUsers.FindRows(StructureR) Do
				StructureP.Name = LineX.NameP;
				If UsersTable.FindRows(StructureP).Count() = 0 Then
					NewLine = UsersTable.Add();
					NewLine.Name = LineX.NameP;
					NewLine.FullName = LineX.FullNameP;
				EndIf;
			EndDo;
		EndDo;

		UsersTable.Sort("Name");
	EndIf;

	СтрукРезультат.HasData = True;
	СтрукРезультат.Roles = New Array;
	СтрукРезультат.Users = New Array;

	For Each Row In ТабРоли Do
		Struc = New Structure("Name, Synonym, RestrictionByCondition");
		FillPropertyValues(Struc, Row);
		СтрукРезультат.Roles.Add(Struc);
	EndDo;

	For Each Row In UsersTable Do
		Struc = New Structure("Name, FullName");
		FillPropertyValues(Struc, Row);
		СтрукРезультат.Users.Add(Struc);
	EndDo;

	Return СтрукРезультат;
EndFunction
&AtClient
Procedure _FillInDependentObjects(Command)
	_DependentObjects.GetItems().Clear();
	_WhereFound = "";

	вЗаполнитьЗависимыеОбъекты();

	For Each Itm In _DependentObjects.GetItems() Do
		Items._DependentObjects.Expand(Itm.GetID(), False);
	EndDo;
EndProcedure

&AtServer
Procedure вЗаполнитьЗависимыеОбъекты()

	пОбъектМД = Metadata.FindByFullName(_FullName);
	If пОбъектМД = Undefined Then
		Return;
	EndIf;
	пКорневойУзел = _DependentObjects.GetItems().Add();
	пКорневойУзел.NodeType = 1;
	пКорневойУзел.Name = пОбъектМД.Name;
	пКорневойУзел.Presentation = пОбъектМД.Presentation();
	пКорневойУзел.FullName = _FullName;

	Pos = StrFind(_FullName, ".");
	пТипДляПоиска = Type(Left(_FullName, Pos - 1) + "Ref" + Mid(_FullName, Pos));

	пНадоСмотретьВидыСубконтоПС = (Left(_FullName, Pos - 1) = "ChartOfCharacteristicTypes");

	пТабРезультат = New ValueTable;
	пТабРезультат.Columns.Add("Name", New TypeDescription("String"));
	пТабРезультат.Columns.Add("Presentation", New TypeDescription("String"));
	пТабРезультат.Columns.Add("FullName", New TypeDescription("String"));
	пТабРезультат.Columns.Add("WhereFound", New TypeDescription("String"));
	
	
	// ---
	пСтрукРазделы = New Structure("SessionParameters, DefinedTypes, Constants");

	пСоотв = New Map;

	For Each пЭлем In пСтрукРазделы Do
		пТабРезультат.Clear();

		пРазделМД = Metadata[пЭлем.Key];

		For Each MDObject In пРазделМД Do
			pFullName = MDObject.FullName();
			пГдеНайдено = "";
			пСчетчик = 0;

			If MDObject.Type.Types().Find(пТипДляПоиска) <> Undefined Then
				пПуть = "Object.Type";
				If пСчетчик = 0 Then
					пГдеНайдено = пПуть;
				Else
					пГдеНайдено = пГдеНайдено + "," + пПуть;
				EndIf;
				пСчетчик = пСчетчик + 1;

				пСоотв[pFullName] = 1;
			EndIf;

			If пСоотв[pFullName] <> Undefined Then
				NewLine = пТабРезультат.Add();
				NewLine.Name = MDObject.Name;
				NewLine.Presentation = MDObject.Presentation();
				NewLine.FullName = pFullName;
				NewLine.WhereFound = пГдеНайдено;
			EndIf;
		EndDo;

		пКоличество = пТабРезультат.Count();
		If пКоличество <> 0 Then
			пТабРезультат.Sort("Name");

			пУзелРаздела = пКорневойУзел.GetItems().Add();
			пУзелРаздела.Name = пЭлем.Key + " (" + пКоличество + ")";
			пУзелРаздела.NodeType = 2;
			пКоллекцияЭлементов = пУзелРаздела.GetItems();

			For Each Row In пТабРезультат Do
				FillPropertyValues(пКоллекцияЭлементов.Add(), Row);
			EndDo;
		EndIf;
	EndDo;
	
	// ---
	пСтрукРазделы = New Structure("ExchangePlans, Catalogs, Documents, ChartsOfCalculationTypes, ChartsOfCharacteristicTypes, ChartsOfAccounts,
									|InformationRegisters, AccumulationRegisters, AccountingRegisters, CalculationRegisters,
									|BusinessProcesses, Tasks");

	пСтрукОбласти = New Structure("Dimensions, Resources, Attributes");

	пСоотв = New Map;

	For Each пЭлем In пСтрукРазделы Do
		пТабРезультат.Clear();

		пРазделМД = Metadata[пЭлем.Key];

		пЭтоПланСчетов = (пЭлем.Key = "ChartsOfAccounts");
		пЭтоПланОбмена = (пЭлем.Key = "ExchangePlans");
		пЭтоРегистр = (StrFind(пЭлем.Key, "Регистры") = 1);

		For Each MDObject In пРазделМД Do
			pFullName = MDObject.FullName();
			пГдеНайдено = "";
			пСчетчик = 0;

			If пЭтоРегистр Then
				For Each пОбласть In пСтрукОбласти Do
					For Each пРеквизит In MDObject[пОбласть.Key] Do
						If пРеквизит.Type.Types().Find(пТипДляПоиска) <> Undefined Then
							пПуть = "Object." + пОбласть.Key + "." + пРеквизит.Name;
							If пСчетчик = 0 Then
								пГдеНайдено = пПуть;
							Else
								пГдеНайдено = пГдеНайдено + "," + пПуть;
							EndIf;
							пСчетчик = пСчетчик + 1;

							пСоотв[pFullName] = 1;
						EndIf;
					EndDo;
				EndDo;

				If пСоотв[pFullName] <> Undefined Then
					NewLine = пТабРезультат.Add();
					NewLine.Name = MDObject.Name;
					NewLine.Presentation = MDObject.Presentation();
					NewLine.FullName = pFullName;
					NewLine.WhereFound = пГдеНайдено;
				EndIf;

			Else
				For Each пРеквизит In MDObject.Attributes Do
					If пРеквизит.Type.Types().Find(пТипДляПоиска) <> Undefined Then
						If пСчетчик = 0 Then
							пГдеНайдено = "Object.Attributes." + пРеквизит.Name;
						Else
							пГдеНайдено = пГдеНайдено + ",Object.Attributes." + пРеквизит.Name;
						EndIf;
						пСчетчик = пСчетчик + 1;

						пСоотв[pFullName] = 1;
					EndIf;
				EndDo;

				For Each пТабличнаяЧасть In MDObject.TabularSections Do
					For Each пРеквизит In пТабличнаяЧасть.Attributes Do
						If пРеквизит.Type.Types().Find(пТипДляПоиска) <> Undefined Then
							If пСчетчик = 0 Then
								пГдеНайдено = "Object." + пТабличнаяЧасть.Name + ".Attributes." + пРеквизит.Name;
							Else
								пГдеНайдено = пГдеНайдено + ",Object." + пТабличнаяЧасть.Name + ".Attributes."
									+ пРеквизит.Name;
							EndIf;
							пСчетчик = пСчетчик + 1;

							пСоотв[pFullName] = 1;
						EndIf;
					EndDo;
				EndDo;

				If пЭтоПланОбмена Then
					If MDObject.Content.Contains(пОбъектМД) Then
						If пСчетчик = 0 Then
							пГдеНайдено = "Object.Content";
						Else
							пГдеНайдено = пГдеНайдено + ",Object.Content";
						EndIf;
						пСчетчик = пСчетчик + 1;

						пСоотв[pFullName] = 1;
					EndIf;
				EndIf;

				If пЭтоПланСчетов And пНадоСмотретьВидыСубконтоПС Then
					If MDObject.ExtDimensionTypes = пОбъектМД Then
						If пСчетчик = 0 Then
							пГдеНайдено = "Object.ExtDimensionTypes";
						Else
							пГдеНайдено = пГдеНайдено + ",Object.ExtDimensionTypes";
						EndIf;
						пСчетчик = пСчетчик + 1;

						пСоотв[pFullName] = 1;
					EndIf;
				EndIf;
			EndIf;

			If пСоотв[pFullName] <> Undefined Then
				NewLine = пТабРезультат.Add();
				NewLine.Name = MDObject.Name;
				NewLine.Presentation = MDObject.Presentation();
				NewLine.FullName = pFullName;
				NewLine.WhereFound = пГдеНайдено;
			EndIf;
		EndDo;

		пКоличество = пТабРезультат.Count();
		If пКоличество <> 0 Then
			пТабРезультат.Sort("Name");

			пУзелРаздела = пКорневойУзел.GetItems().Add();
			пУзелРаздела.Name = пЭлем.Key + " (" + пКоличество + ")";
			пУзелРаздела.NodeType = 2;
			пКоллекцияЭлементов = пУзелРаздела.GetItems();

			For Each Row In пТабРезультат Do
				FillPropertyValues(пКоллекцияЭлементов.Add(), Row);
			EndDo;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure _DependentObjectsOnActivateRow(Item)
	AttachIdleHandler("вОбработкаАктивизацииСтрокиЗависимых", 0.1, True);
EndProcedure

&AtClient
Procedure вОбработкаАктивизацииСтрокиЗависимых()
	CurData = Items._DependentObjects.CurrentData;
	If CurData <> Undefined Then
		_WhereFound = StrReplace(CurData.NodeType, ",", Chars.LF);
	EndIf;
EndProcedure

&AtClient
Procedure _DependentObjectsSelection(Item, SelectedRow, Field, StandardProcessing)
	CurData = Items._DependentObjects.CurrentData;
	If CurData <> Undefined And CurData.NodeType = 0 Then
		StandardProcessing = False;
		vShowObjectProperties(CurData.FullName);
	EndIf;
EndProcedure

&AtClient
Procedure _OpenSubordinateObject(Command)
	CurData = Items._DependentObjects.CurrentData;
	If CurData <> Undefined And CurData.NodeType = 0 Then
		vShowObjectProperties(CurData.FullName);
	EndIf;
EndProcedure
&AtClient
Procedure _ReadConstant(Command)
	pResult = vGetConstant(_FullName);
	If Not pResult.Cancel Then
		_ConstantValue = pResult.Value;
		_TypeOfConstantValue = pResult.ValueType;

		If TypeOf(pResult.Value) = Type("String") Then
			_TextConstantValue = pResult.Value;
		Else
			_TextConstantValue = pResult.Text;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _RecordConstant(Command)
	If вЗаписатьКонстанту() Then
		pObjectType = Left(_FullName, StrFind(_FullName, ".") - 1);

		If pObjectType = "Constant" Then
			ShowMessageBox( , "Value константы изменено!", 20);
		ElsIf pObjectType = "SessionParameter" Then
			ShowMessageBox( , "Value параметра сеанса изменено!", 20);
		EndIf;

		_ReadConstant(Undefined);
	EndIf;
EndProcedure

&AtServer
Function вЗаписатьКонстанту()
	SetPrivilegedMode(True);

	пОбъектМД = Metadata.FindByFullName(_FullName);
	If пОбъектМД = Undefined Then
		Return False;
	EndIf;

	pObjectType = Left(_FullName, StrFind(_FullName, ".") - 1);

	If pObjectType = "Constant" Then
		пМенеджерЗначения = Constants[пОбъектМД.Name].CreateValueManager();
		If _UseTextWhenWritingConstants Then
			пМенеджерЗначения.Value = _TextConstantValue;
		Else
			пМенеджерЗначения.Value = _ConstantValue;
		EndIf;

		Try
			пМенеджерЗначения.Write();
			Return True;
		Except
			Message(BriefErrorDescription(ErrorInfo()));
			Return False;
		EndTry;

	ElsIf pObjectType = "SessionParameter" Then
		Try
			If _UseTextWhenWritingConstants Then
				SessionParameters[пОбъектМД.Name] = _TextConstantValue;
			Else
				SessionParameters[пОбъектМД.Name] = _ConstantValue;
			EndIf;
			Return True;
		Except
			Message(BriefErrorDescription(ErrorInfo()));
			Return False;
		EndTry;

	Else
		Return False;
	EndIf;
EndFunction

&AtServerNoContext
Function vGetConstant(Val FullName)
	SetPrivilegedMode(True);

	pResult = New Structure("Cancel, ReasonForRefusal, ReadOnly, Text, Value, ValueType", False, "", False,
		"");

	пОбъектМД = Metadata.FindByFullName(FullName);
	If пОбъектМД = Undefined Then
		pResult.Cancel = True;
		pResult.ReadOnly = True;
		pResult.ReasonForRefusal = "Not удалость найти объект метаданных!";
		Return pResult;
	EndIf;

	pObjectType = Left(FullName, StrFind(FullName, ".") - 1);

	If pObjectType = "Constant" Then
		Query = New Query;
		Query.Text = "ВЫБРАТЬ ПЕРВЫЕ 1
					   |	т.Value КАК Value
					   |ИЗ
					   |	" + FullName + " КАК т";

		Try
			Выборка = Query.Execute().StartChoosing();

			pResult.Value = ?(Выборка.Next(), Выборка.Value, Undefined);
			pResult.ValueType = vTypeNameToString(vCreateStructureOfTypes(), TypeOf(pResult.Value),
				пОбъектМД.Type);
		Except
			Message(BriefErrorDescription(ErrorInfo()));
			pResult.Cancel = True;
			pResult.ReasonForRefusal = ErrorDescription();
			Return pResult;
		EndTry;

	ElsIf pObjectType = "SessionParameter" Then
		Try
			pResult.Value = SessionParameters[пОбъектМД.Name];
			pResult.ValueType = vTypeNameToString(vCreateStructureOfTypes(), TypeOf(pResult.Value),
				пОбъектМД.Type);
		Except
			pResult.Cancel = True;
			pResult.ReasonForRefusal = "значение не установлено!";
		EndTry;

	Else
		pResult.Cancel = True;
		pResult.ReadOnly = True;
		pResult.ReasonForRefusal = pObjectType + " не поддерживается!";
		Return pResult;
	EndIf;

	pUnsupportedTypes = New Array;
	pUnsupportedTypes.Add(Type("ValueStorage"));
	pUnsupportedTypes.Add(Type("BinaryData"));
	pUnsupportedTypes.Add(Type("TypeDescription"));
	pUnsupportedTypes.Add(Type("FixedArray"));
	pUnsupportedTypes.Add(Type("FixedStructure"));
	pUnsupportedTypes.Add(Type("FixedMap"));

	For Each Itm In pUnsupportedTypes Do
		If пОбъектМД.Type.ContainsType(Itm) Then
			pResult.ReadOnly = True;
			Break;
		EndIf;
	EndDo;

	If False Then
		pValueType = TypeOf(pResult.Value);
		If pValueType = Type("FixedArray") Then
			For Counter = 0 To pResult.Value.UBound() Do
				pResult.Text = pResult.Text + Chars.LF + String(pResult.Value[Counter]);
			EndDo;
		EndIf;
	EndIf;

	Return pResult;
EndFunction