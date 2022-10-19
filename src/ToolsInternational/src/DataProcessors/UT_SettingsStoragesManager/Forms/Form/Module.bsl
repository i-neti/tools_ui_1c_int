#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	FilterBySettingsStorages.Add("FormDataSettingsStorage", NStr("ru = 'Хранилище настроек данных форм'"));
	FilterBySettingsStorages.Add("CommonSettingsStorage", NStr("ru = 'Хранилище общих настроек'"));
	FilterBySettingsStorages.Add("DynamicListsUserSettingsStorage", NStr(
		"ru = 'Хранилище пользовательских настроек динамических списков'"));
	FilterBySettingsStorages.Add("ReportsUserSettingsStorage", NStr(
		"ru = 'Хранилище пользовательских настроек отчетов'"));
	FilterBySettingsStorages.Add("SystemSettingsStorage", NStr("ru = 'Хранилище системных настроек'"));

	UpdateUsersTable();
	
	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
		
	// Initial filling of settings tree
	UpdateOwnerSettings(Undefined);
	
	// Managing the appearance of the form
	UpdateItemsPresentation();

	Items.SelectedSettingsTable.RowFilter = New FixedStructure("Check", True);

EndProcedure

&AtClient
Procedure UpdateOwnerSettings(Command)

	UpdateOwnerSettingsAtServer();

	Items.ConfigurationTree.Expand(
		ConfigurationTree.GetItems()[0].GetID());

EndProcedure

&AtClient
Procedure ConfigurationObjectsRepresentationVariantOnChange(Item)
	
	UpdateItemsPresentation(Item.Name);
	UpdateOwnerSettings(Undefined);
	
EndProcedure

&AtClient
Procedure ConfigurationTreeCheckOnChange(Item)
	CurrentData = Items.ConfigurationTree.CurrentData;
	CheckManagement(CurrentData);
EndProcedure

&AtClient
Procedure ConfigurationTreeOnActivateRow(Item)
	CurrentData = Items.ConfigurationTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	Items.SettingsTable.RowFilter = ?(CurrentData.FilterID = 0, Undefined,
		New FixedStructure("FilterID" + CurrentData.Level, CurrentData.FilterID));

EndProcedure

&AtClient
Procedure DeselectSetting(Command)

	For Each SelectedRow In Items.SelectedSettingsTable.SelectedRows Do

		String = SettingsTable.FindByID(SelectedRow);
		If String <> Undefined Then
			String.Check = False;
		EndIf;

	EndDo;

EndProcedure

&AtClient
Procedure SettingsTableCheckOnChange(Item)
		TreeRow = Items.ConfigurationTree.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;

	ПараметрыОтбора = New Structure;
	ПараметрыОтбора.Insert("FilterID" + TreeRow.Level, TreeRow.FilterID);
	НайденныеСтроки = SettingsTable.FindRows(ПараметрыОтбора);
	If НайденныеСтроки <> Undefined Then
		ВсегоНастроек = НайденныеСтроки.Count();
	EndIf;

	ПараметрыОтбора.Insert("Check", True);
	НайденныеСтроки = SettingsTable.FindRows(ПараметрыОтбора);
	If НайденныеСтроки <> Undefined Then
		КолПометок = НайденныеСтроки.Count();
	EndIf;

	If КолПометок = 0 Then
		TreeRow.Check = 0;
	ElsIf КолПометок <> ВсегоНастроек Then
		TreeRow.Check = 2;
	Else
		TreeRow.Check = 1;
	EndIf;

	CheckManagement(TreeRow, False);
EndProcedure

&AtClient
Procedure SettingsTableSettingsAdditionalOpening(Item, StandardProcessing)
		StandardProcessing = False;

	CurrentData = Items.SettingsTable.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	ПросмотрНастроекНаСервере(CurrentData.SettingsStorageName, CurrentData.ObjectKey, CurrentData.SettingsKey,
		SettingsOwner);
EndProcedure

&AtClient
Procedure ShowSelectedSettings(Command)
	Items.ConfigurationTreeShowSelectedSettings.Check = Not Items.ConfigurationTreeShowSelectedSettings.Check;
	UpdateItemsPresentation("ShowSelectedSettings");
EndProcedure

&AtClient
Procedure SettingsOwnerOnChange(Item)
	UpdateOwnerSettings(Undefined);
EndProcedure

&AtClient
Procedure SettingsOwnerClearing(Item, StandardProcessing)
	UpdateOwnerSettings(Undefined);
EndProcedure

&AtClient
Procedure ShowSelectedUsers(Command)
	Items.CancelSearchShowSelectedUsers.Check = Not Items.CancelSearchShowSelectedUsers.Check;
	UpdateItemsPresentation("ShowSelectedUsers");
EndProcedure

&AtClient
Procedure UsersTableCheckOnChange(Item)
		CurrentData = Items.Users.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If CurrentData.Check Then
		CurrentData.Check = False;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSelectedSettings(Command)
	
	// Проверки
	ЕстьОшибка = False;
	Filter = New Structure("Check", True);
	НайденныеСтроки = SettingsTable.FindRows(Filter);
	If НайденныеСтроки.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Not выбраны настройки для удаления'"), , , ,
			ЕстьОшибка);
	EndIf;

	If ЕстьОшибка Then
		Return;
	EndIf;

	ShowQueryBox(
		New NotifyDescription("ВопросУдалитьНастройкиЗавершение", ThisForm), StrTemplate(NStr(
		"ru = 'Delete выбранные настройки у пользователя %1?'"), SettingsOwner), QuestionDialogMode.YesNo, ,
		DialogReturnCode.None, NStr("ru = 'Attention!'"));

EndProcedure

&AtClient
Procedure CopySelectedSettings(Command)
	
	// Проверки
	ЕстьОшибка = False;
	Filter = New Structure("Check", True);
	НайденныеСтроки = SettingsTable.FindRows(Filter);
	If НайденныеСтроки.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Not выбраны настройки для копирования'"), , , ,
			ЕстьОшибка);
	EndIf;
	НайденныеСтроки = Users.FindRows(Filter);
	If НайденныеСтроки.Count() = 0 Then
		UT_CommonClientServer.MessageToUser(NStr("ru = 'Not указаны пользователи (кому копировать)'"),
			, , , ЕстьОшибка);
	EndIf;

	If ЕстьОшибка Then
		Return;
	EndIf;

	ShowQueryBox(
		New NotifyDescription("ВопросСкопироватьНастройкиЗавершение", ThisForm), NStr(
		"ru = 'Copy выбранные настройки выбранным пользователям?'"), QuestionDialogMode.YesNo, ,
		DialogReturnCode.None, NStr("ru = 'Attention!'"));

EndProcedure

&AtClient
Procedure TextOfFilterBySettingsStoragesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	FilterBySettingsStorages.ShowCheckItems(
		New NotifyDescription("ИзменениеОтбораПоХранилищамНастроекЗавершение", ThisForm));
EndProcedure

&AtClient
Procedure TextOfFilterBySettingsStoragesClearing(Item, StandardProcessing)
	StandardProcessing = False;
	TextOfFilterBySettingsStorages = "";
	FilterBySettingsStorages.FillChecks(False);
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure



#EndRegion

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

#Region ОбработкиЗавершения

&AtClient
Procedure ВопросУдалитьНастройкиЗавершение(РезультатВопроса, AdditionalParameters) Export

	If РезультатВопроса = DialogReturnCode.None Then
		Return;
	EndIf;

	УдалитьВыбранныеНастройкиНаСервере();

	UpdateOwnerSettings(Undefined);

EndProcedure

&AtClient
Procedure ВопросСкопироватьНастройкиЗавершение(РезультатВопроса, AdditionalParameters) Export

	If РезультатВопроса = DialogReturnCode.None Then
		Return;
	EndIf;

	СкопироватьВыбранныеНастройкиНаСервере();

	ShowMessageBox( , NStr("ru = 'Copy настроек выполнено'"));

EndProcedure

&AtClient
Procedure ИзменениеОтбораПоХранилищамНастроекЗавершение(List, AdditionalParameters) Export

	If List = Undefined Then
		Return;
	EndIf;

	TextOfFilterBySettingsStorages = "";
	For Each ЭлементСписка In List Do
		If ЭлементСписка.Check Then
			TextOfFilterBySettingsStorages = TextOfFilterBySettingsStorages + ?(TextOfFilterBySettingsStorages = "",
				"", "; ") + ЭлементСписка.Presentation;
		EndIf;
	EndDo;

	UpdateOwnerSettings(Undefined);

EndProcedure

#EndRegion

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

#Region Private

&AtServer
Procedure UpdateUsersTable()

	Users.Clear();

	IbUsers=InfoBaseUsers.GetUsers();
	For Each IBUser In IbUsers Do
		НС=Users.Add();
		НС.Name=IBUser.Name;
		НС.FullName=IBUser.FullName;
		НС.Picture=0;
		НС.UUID=IBUser.UUID;

	EndDo;

EndProcedure

&AtClient
Procedure UpdateItemsPresentation(ЭлементыУправления = Undefined)

	// Подготовить массив имен ЭУ, отображение которых надо обновить
	МассивЭУ = New Array;
	If TypeOf(ЭлементыУправления) = Type("String") Then
		МассивЭУ = StrSplit(ЭлементыУправления, ",");
	EndIf;

	If МассивЭУ.Count() = 0 Or МассивЭУ.Find("ConfigurationObjectsRepresentationVariant") <> Undefined Then
		Items.ConfigurationTreeByName.Visible = (ConfigurationObjectsRepresentationVariant = 0);
		Items.ConfigurationTreeBySynonym.Visible = (ConfigurationObjectsRepresentationVariant = 1);
	EndIf;

	If МассивЭУ.Count() = 0 Or МассивЭУ.Find("ShowSelectedSettings") <> Undefined Then
		Items.GroupSelectedSettings.Visible = Items.ConfigurationTreeShowSelectedSettings.Check;
		Items.ConfigurationTreeShowSelectedSettings.Title = ?(Items.GroupSelectedSettings.Visible,
			NStr("ru = 'Hide выбранные настройки'"), NStr("ru = 'Show выбранные настройки'"));
	EndIf;

	If МассивЭУ.Count() = 0 Or МассивЭУ.Find("ShowSelectedUsers") <> Undefined Then
		Items.Users.RowFilter = ?(Items.CancelSearchShowSelectedUsers.Check,
			New FixedStructure("Check", True), Undefined);
		Items.CancelSearchShowSelectedUsers.Title = ?(
			Items.Users.RowFilter <> Undefined, NStr("ru = 'Show всех'"), NStr(
			"ru = 'Show выбранных'"));
	EndIf;	
	
	//If МассивЭУ.Count() = 0 Then
	// В условии описываюся свойства элементов,
	// которые обновляются независимо от переданного параметра ЭлементыУправления
	//EndIf;

EndProcedure

&AtServer
Procedure UpdateOwnerSettingsAtServer()

	// Инициализитовать дерево конфигурации и очистить его
	ДЗ = FormAttributeToValue("ConfigurationTree");
	ДЗ.Rows.Clear();
	// Инициализитовать таблицу настроек и очистить его
	ТЗ = FormAttributeToValue("SettingsTable");
	ТЗ.Clear();
	
	// Create строку для корня конфигурации
	СтрокаДереваКонфигурация = ДЗ.Rows.Add();
	СтрокаДереваКонфигурация.PresentationName = Metadata.Name + NStr("ru = ' (All настройки)'");
	СтрокаДереваКонфигурация.PresentationSynonym = Metadata.Synonym + NStr("ru = ' (All настройки)'");
	СтрокаДереваКонфигурация.Order = 0;
	//СтрокаДереваКонфигурация.Picture = 0;
	СтрокаДереваПрочее = СтрокаДереваКонфигурация.Rows.Add();
	СтрокаДереваПрочее.PresentationName = NStr("ru = 'Прочее'");
	СтрокаДереваПрочее.PresentationSynonym = СтрокаДереваПрочее.PresentationName;
	СтрокаДереваПрочее.Order = 900;
	СтрокаДереваПрочее.Path = "Прочее";
	СтрокаДереваПрочее.FilterID = 1;
	//СтрокаДереваПрочее.Picture = 0;
	
	// Parameters для создания веток дерева
	AdditionalParameters = ИнициализироватьПараметрыДляСозданияДереваКонфигурации(ТЗ);
	AdditionalParameters.Insert("СтрокаДереваКонфигурация", СтрокаДереваКонфигурация);
	AdditionalParameters.Insert("СтрокаДереваПрочее", СтрокаДереваПрочее);
	
	// Get настроки пользователя
	Filter = New Structure("User", SettingsOwner);
	For Each ЭлементСписка In FilterBySettingsStorages Do
		If ЭлементСписка.Check Or IsBlankString(TextOfFilterBySettingsStorages) Then

			ИмяХранилищаНастроек = ЭлементСписка.Value;
			Выборка = Eval(ИмяХранилищаНастроек).StartChoosing(Filter);
			AdditionalParameters.SettingsStorageName = ИмяХранилищаНастроек;
				
				// FillType дерева
			ДополнитьДеревоНастроек(Выборка, ИмяХранилищаНастроек, AdditionalParameters);

		EndIf;
	EndDo; 
		
	// Send значения на форму
	ValueToFormAttribute(ДЗ, "ConfigurationTree");
	ValueToFormAttribute(AdditionalParameters.ТаблицаЗначенийНастроек, "SettingsTable");

EndProcedure

&AtServer
Procedure ДополнитьДеревоНастроек(Выборка, ИмяХранилищаНастроек, AdditionalParameters)

	СтрокаДереваКонфигурация = AdditionalParameters.СтрокаДереваКонфигурация;
	СтрокаДереваПрочее = AdditionalParameters.СтрокаДереваПрочее;
	
	// Do по настройкам пользователя
	While Выборка.Next() Do
		
		// Разложить ObjectKey в Array(10)
		МассивКлюч = StrSplit(Выборка.ObjectKey, "/", True);
		КоличествоЭлементовВМассиве = МассивКлюч.Count();
		For Ин = КоличествоЭлементовВМассиве To 9 Do
			МассивКлюч.Add("");
		EndDo;
		
		// Разложить Key объекта настроек в Array(10)
		ПутьОбъектаКонфигурации = ?(МассивКлюч[0] = "Общее" And МассивКлюч[1] = "TableSearchHistory", МассивКлюч[2],
			МассивКлюч[0]);
		МассивПуть = StrSplit(ПутьОбъектаКонфигурации, ".", True);
		КоличествоЭлементовВМассиве = МассивПуть.Count();
		For Ин = КоличествоЭлементовВМассиве To 9 Do
			МассивПуть.Add("");
		EndDo;
		
		// Run рекурсивного создания строк дерева настроек
		AdditionalParameters.Insert("СтрокаДереваКонфигурация", СтрокаДереваКонфигурация);
		AdditionalParameters.Insert("МассивПуть", МассивПуть);
		AdditionalParameters.Insert("ВыборкаНастроек", Выборка);
		ПроверяемоеСвойство = StrReplace(МассивПуть[0], " ", "");
		Try
			If AdditionalParameters.ПредопределенныеВеткиКонфигурации.Property(ПроверяемоеСвойство) Then
				СоздатьВеткуКонфигурации(СтрокаДереваКонфигурация, AdditionalParameters);
			Else
				СоздатьВеткуКонфигурации(СтрокаДереваПрочее, AdditionalParameters);
			EndIf;
		Except
		EndTry;
	EndDo;

EndProcedure

&AtServer
Function ИнициализироватьПараметрыДляСозданияДереваКонфигурации(ТаблицаЗначенийНастроек)

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SettingsStorageName", "");
	AdditionalParameters.Insert("ТаблицаЗначенийНастроек", ТаблицаЗначенийНастроек);
	AdditionalParameters.Insert("НомерКартинки", 0);
	AdditionalParameters.Insert("СчетчикИдентификаторовОтбора", 2);
	AdditionalParameters.Insert("ПредопределенныеВеткиКонфигурации", New Structure);
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Общие", "Общие");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Подсистема", "Подсистема");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("SettingsStorage", "SettingsStorage");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ExchangePlan", "ExchangePlan");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ОбщаяФорма", "ОбщаяФорма");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Constant", "Constant");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Catalog", "Catalog");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Document", "Document");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("DocumentJournal", "DocumentJournal");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Enum", "Enum");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Report", "Report");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ExternalReport", "ExternalReport");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Processing", "Processing");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ExternalDataProcessor", "ExternalDataProcessor");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ChartOfCharacteristicTypes",
		"ChartOfCharacteristicTypes");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ChartOfAccounts", "ChartOfAccounts");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("InformationRegister", "InformationRegister");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("AccumulationRegister", "AccumulationRegister");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("AccountingRegister", "AccountingRegister");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("CalculationRegister", "CalculationRegister");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("BusinessProcess", "BusinessProcess");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("Task", "Task");
	AdditionalParameters.ПредопределенныеВеткиКонфигурации.Insert("ExternalDataSource", "ExternalDataSource");

	Return AdditionalParameters;

EndFunction

&AtServer
Procedure СоздатьВеткуКонфигурации(СтрокаРодитель, AdditionalParameters, Level = 0)
	
	// Дополнить "Path" настройки, чтобы дерево было похоже на дерево конфигурации в конфигураторе 1С
	If Level = 0 And (AdditionalParameters.МассивПуть[Level] = "ОбщаяФорма"
		Or AdditionalParameters.МассивПуть[Level] = "SettingsStorage"
		Or AdditionalParameters.МассивПуть[Level] = "ExchangePlan" Or AdditionalParameters.МассивПуть[Level]
		= "Подсистема") Then
		AdditionalParameters.МассивПуть.Insert(0, "Общие");
	EndIf; 
	
	// ПутьПоиска, нужен для того, чтобы не дублировалить ветки дерева настроек
	ПутьПоиска = ?(Level = 0, "", СтрокаРодитель.Path + ".") + AdditionalParameters.МассивПуть[Level];
	
	// Find существующую ветку
	TreeRow = СтрокаРодитель.Rows.Find(ПутьПоиска, "Path", False);
	If TreeRow = Undefined Then		
		
		// Not нашли. Create новую ветку
		TreeRow = СтрокаРодитель.Rows.Add();
		TreeRow.Path = ПутьПоиска;
		TreeRow.Level = Level;
		TreeRow.FilterID = AdditionalParameters.СчетчикИдентификаторовОтбора;
		AdditionalParameters.СчетчикИдентификаторовОтбора = AdditionalParameters.СчетчикИдентификаторовОтбора + 1;
		// Fill колонки строки дерева
		ЗаполнитьСтрокуДереваКонфигурации(TreeRow, AdditionalParameters, Level);

	EndIf;

	If AdditionalParameters.МассивПуть[Level + 1] <> "" And Level < 3 Then
		// Рекурсия
		СоздатьВеткуКонфигурации(TreeRow, AdditionalParameters, Level + 1);

	Else
		// Add строку в таблицу настроек текущей строки дерева
		СтрокаТаблицыНастроек = AdditionalParameters.ТаблицаЗначенийНастроек.Add();
		СтрокаТаблицыНастроек.SettingsStorageName = AdditionalParameters.SettingsStorageName;
		СтрокаТаблицыНастроек.SettingsAdditional = AdditionalParameters.ВыборкаНастроек.Settings;
		FillPropertyValues(СтрокаТаблицыНастроек, AdditionalParameters.ВыборкаНастроек);
		УстановитьИдентификаторОтбора(СтрокаТаблицыНастроек, TreeRow);

	EndIf; 
		
	// Sort уровня дерева взависимости от варианта отображения представления. Либо по имени, либо по синониму
	СтрокаРодитель.Rows.Sort(
		?(ConfigurationObjectsRepresentationVariant = 0, "Order, PresentationName", "Order, PresentationSynonym"));

EndProcedure

&AtServer
Function ЗаполнитьСтрокуДереваКонфигурации(TreeRow, AdditionalParameters, IndexOf)
	
	// Values по умолчанию
	TreeRow.PresentationName = AdditionalParameters.МассивПуть[IndexOf];
	TreeRow.PresentationSynonym = AdditionalParameters.МассивПуть[IndexOf];
	TreeRow.Order = 999;

	If AdditionalParameters.МассивПуть[IndexOf] = AdditionalParameters.ПредопределенныеВеткиКонфигурации.Общие Then
		TreeRow.PresentationName = "Общие";
		TreeRow.Order = 10;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Подсистема Then
		TreeRow.PresentationName = "Subsystems";
		TreeRow.PresentationSynonym = "Subsystems";
		TreeRow.КлассОбъектовМетаданных = "Подсистема";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 20;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.SettingsStorage Then
		TreeRow.PresentationName = "Хранилища настроек";
		TreeRow.PresentationSynonym = "Хранилища настроек";
		TreeRow.КлассОбъектовМетаданных = "SettingsStorage";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 21;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ExchangePlan Then
		TreeRow.PresentationName = "Планы обмена";
		TreeRow.PresentationSynonym = "Планы обмена";
		TreeRow.КлассОбъектовМетаданных = "ExchangePlan";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 22;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ОбщаяФорма Then
		TreeRow.PresentationName = "Общие формы";
		TreeRow.PresentationSynonym = "Общие формы";
		TreeRow.КлассОбъектовМетаданных = "ОбщаяФорма";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 23;
		TreeRow.Picture = 1;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Constant Then
		TreeRow.PresentationName = "Constants";
		TreeRow.PresentationSynonym = "Constants";
		TreeRow.КлассОбъектовМетаданных = "Constant";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 30;
		//TreeRow.Picture = 0;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Catalog Then
		TreeRow.PresentationName = "Catalogs";
		TreeRow.PresentationSynonym = "Catalogs";
		TreeRow.КлассОбъектовМетаданных = "Catalog";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 31;
		TreeRow.Picture = 2;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Document Then
		TreeRow.PresentationName = "Documents";
		TreeRow.PresentationSynonym = "Documents";
		TreeRow.КлассОбъектовМетаданных = "Document";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 32;
		TreeRow.Picture = 3;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.DocumentJournal Then
		TreeRow.PresentationName = "Журналы документов";
		TreeRow.PresentationSynonym = "Журналы документов";
		TreeRow.КлассОбъектовМетаданных = "DocumentJournal";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 33;
		TreeRow.Picture = 4;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Enum Then
		TreeRow.PresentationName = "Enums";
		TreeRow.PresentationSynonym = "Enums";
		TreeRow.КлассОбъектовМетаданных = "Enum";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 34;
		//TreeRow.Picture = 3;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Report Then
		TreeRow.PresentationName = "Reports";
		TreeRow.PresentationSynonym = "Reports";
		TreeRow.КлассОбъектовМетаданных = "Report";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 35;
		TreeRow.Picture = 5;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ExternalReport Then
		TreeRow.PresentationName = "ExternalReports";
		TreeRow.PresentationSynonym = "ExternalReports";
		TreeRow.Order = 36;
		TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Processing Then
		TreeRow.PresentationName = "DataProcessors";
		TreeRow.PresentationSynonym = "DataProcessors";
		TreeRow.КлассОбъектовМетаданных = "Processing";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 37;
		TreeRow.Picture = 7;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ExternalDataProcessor Then
		TreeRow.PresentationName = "ExternalDataProcessors";
		TreeRow.PresentationSynonym = "ExternalDataProcessors";
		TreeRow.Order = 38;
		TreeRow.Picture = 8;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ChartOfCharacteristicTypes Then
		TreeRow.PresentationName = "Планы видов характеристик";
		TreeRow.PresentationSynonym = "Планы видов характеристик";
		TreeRow.КлассОбъектовМетаданных = "ChartOfCharacteristicTypes";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 39;
		TreeRow.Picture = 9;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ChartOfAccounts Then
		TreeRow.PresentationName = "Планы счетов";
		TreeRow.PresentationSynonym = "Планы счетов";
		TreeRow.КлассОбъектовМетаданных = "ChartOfAccounts";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 40;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ChartOfCalculationTypes Then
		TreeRow.PresentationName = "Планы видов расчета";
		TreeRow.PresentationSynonym = "Планы видов расчета";
		TreeRow.КлассОбъектовМетаданных = "ChartOfCalculationTypes";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 41;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.InformationRegister Then
		TreeRow.PresentationName = "Регистры сведений";
		TreeRow.PresentationSynonym = "Регистры сведений";
		TreeRow.КлассОбъектовМетаданных = "InformationRegister";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 42;
		TreeRow.Picture = 10;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.AccumulationRegister Then
		TreeRow.PresentationName = "Регистры накопления";
		TreeRow.PresentationSynonym = "Регистры накопления";
		TreeRow.КлассОбъектовМетаданных = "AccumulationRegister";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 43;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.AccountingRegister Then
		TreeRow.PresentationName = "Регистры бухгалтерии";
		TreeRow.PresentationSynonym = "Регистры бухгалтерии";
		TreeRow.КлассОбъектовМетаданных = "AccountingRegister";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 44;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.CalculationRegister Then
		TreeRow.PresentationName = "Регистры расчета";
		TreeRow.PresentationSynonym = "Регистры расчета";
		TreeRow.КлассОбъектовМетаданных = "CalculationRegister";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 45;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.BusinessProcess Then
		TreeRow.PresentationName = "Бизнес-процессы";
		TreeRow.PresentationSynonym = "Бизнес-процессы";
		TreeRow.КлассОбъектовМетаданных = "BusinessProcess";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 46;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.Task Then
		TreeRow.PresentationName = "Tasks";
		TreeRow.PresentationSynonym = "Tasks";
		TreeRow.КлассОбъектовМетаданных = "Task";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 47;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf]
		= AdditionalParameters.ПредопределенныеВеткиКонфигурации.ExternalDataSource Then
		TreeRow.PresentationName = "Внешние источники данных";
		TreeRow.PresentationSynonym = "Внешние источники данных";
		TreeRow.КлассОбъектовМетаданных = "ExternalDataSource";
		TreeRow.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных = True;
		TreeRow.Order = 48;
		//TreeRow.Picture = 6;

	ElsIf AdditionalParameters.МассивПуть[IndexOf] = "Form" Then
		TreeRow.PresentationName = "Forms";
		TreeRow.PresentationSynonym = "Forms";
		TreeRow.Picture = 1;

	Else
		TreeRow.Picture = AdditionalParameters.НомерКартинки;

	EndIf;

	AdditionalParameters.НомерКартинки = TreeRow.Picture;
	
	// FillType колонок дерева PresentationSynonym, ОтсутствуетВКонфигурации
	If IndexOf > 0 And TreeRow.Parent.ФормироватьПредставлениеПодчиненныхСтрокИзСинонимаМетаданных Then
		ОбъектМетаданных = Metadata.FindByFullName(TreeRow.Parent.КлассОбъектовМетаданных + "."
			+ AdditionalParameters.МассивПуть[IndexOf]);
		If ОбъектМетаданных = Undefined Then
			TreeRow.ОтсутствуетВКонфигурации = True;
			УстановитьОтсутствуетВКонфигурации(TreeRow);
		Else
			TreeRow.PresentationSynonym = ОбъектМетаданных.Synonym;
		EndIf;
	EndIf;

EndFunction

&AtServer
Procedure УстановитьИдентификаторОтбора(СтрокаТаблицыНастроек, TreeRow)

	СтрокаТаблицыНастроек["FilterID" + TreeRow.Level] = TreeRow.FilterID;

	TreeRow.SettingsCount = TreeRow.SettingsCount + 1;

	СтрокаРодитель = TreeRow.Parent;
	If СтрокаРодитель.Parent <> Undefined Then
		// Рекурсия
		УстановитьИдентификаторОтбора(СтрокаТаблицыНастроек, СтрокаРодитель);
	EndIf;

EndProcedure

&AtServer
Procedure УстановитьОтсутствуетВКонфигурации(TreeRow)

	TreeRow.ОтсутствуетВКонфигурации = True;

	СтрокаРодитель = TreeRow.Parent;
	If СтрокаРодитель.Parent <> Undefined Then
		// Рекурсия
		УстановитьОтсутствуетВКонфигурации(СтрокаРодитель);
	EndIf;

EndProcedure

&AtServer
Procedure УдалитьВыбранныеНастройкиНаСервере()
	ПараметрыОтбора = New Structure;
	ПараметрыОтбора.Insert("Check", True);
	НайденныеСтроки = SettingsTable.FindRows(ПараметрыОтбора);
	For Each String In НайденныеСтроки Do
		ХрНастроек = Eval(String.SettingsStorageName);
		ХрНастроек.Delete(String.ObjectKey, String.SettingsKey, SettingsOwner);
	EndDo;

EndProcedure

&AtServer
Procedure СкопироватьВыбранныеНастройкиНаСервере()

	Filter = New Structure("Check", True);

	ВыбранныеПользователи = Users.FindRows(Filter);

	ВыбранныеНастроки = SettingsTable.FindRows(Filter);

	For Each СтрокаПользователь In ВыбранныеПользователи Do
		For Each СтрокаНастройка In ВыбранныеНастроки Do

			ХрНастроек = Eval(СтрокаНастройка.SettingsStorageName);

			Filter = New Structure;
			Filter.Insert("ObjectKey", СтрокаНастройка.ObjectKey);
			Filter.Insert("SettingsKey", СтрокаНастройка.SettingsKey);
			Filter.Insert("User", СтрокаПользователь.Name);
			
			
			// Get настроки для копирования. Выборка ВыборкаНастроекИсточника должен содержать один элемент
			ВыборкаНастроекИсточника = ХрНастроек.StartChoosing(Filter);
			ВыборкаНастроекИсточника.Next();
			
			// Copy настройки новому пользователю
			ХрНастроек.Save(
				СтрокаНастройка.ObjectKey, СтрокаНастройка.SettingsKey, ВыборкаНастроекИсточника.Settings,
				СтрокаНастройка.Presentation, СтрокаПользователь.Name);

		EndDo;
	EndDo;

EndProcedure

&AtServer
Procedure ПросмотрНастроекНаСервере(ИмяХранилищаНастроек, ObjectKey, SettingsKey, UserName)

	Filter = New Structure;
	Filter.Insert("ObjectKey", ObjectKey);
	Filter.Insert("SettingsKey", SettingsKey);
	Filter.Insert("User", UserName);

	Выборка = Eval(ИмяХранилищаНастроек).StartChoosing(Filter);
	Выборка.Next();

	СодержимоеНастроек = Выборка.Settings;

EndProcedure

#EndRegion

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

#Region Прочее

#Region Управление_пометками

&AtClient
Procedure УстановитьПометкуПодчиненныхЭлементов(ЭлементДерева, Check)
	
	// Set пометку
	ЭлементДерева.Check = Check;

	ПараметрыОтбора = New Structure;
	ПараметрыОтбора.Insert("FilterID" + ЭлементДерева.Level, ЭлементДерева.FilterID);
	ПараметрыОтбора.Insert("Check", Not Check);
	НайденныеСтроки = SettingsTable.FindRows(ПараметрыОтбора);
	For Each String In НайденныеСтроки Do
		String.Check = (Check = 1);
	EndDo; 
	
	// Рекурсивная установка пометки у подчиненных строк дерева
	For Each ПодчиненныйЭлемент In ЭлементДерева.GetItems() Do
		УстановитьПометкуПодчиненныхЭлементов(ПодчиненныйЭлемент, Check);
	EndDo;

EndProcedure

&AtClient
Procedure УстановитьПометкуРодительскихЭлементов(ЭлементДерева, Check)
	
	// Set пометку
	ЭлементДерева.Check = Check;	
	
	// Рекурсивная установка пометки у родительских строк дерева
	ЭлементРодитель = ЭлементДерева.GetParent();
	If Not ЭлементРодитель = Undefined Then
		
		// Считаем количесвто помеченных элементов в подчиненном уровне
		КоличествоПомеченныхЭлеметов = 0;
		КоличествоСерыхЭлеметов = 0;
		ПодчиненныеЭлементыРодителя = ЭлементРодитель.GetItems();
		For Each ПодчиненныйЭлемент In ПодчиненныеЭлементыРодителя Do
			КоличествоПомеченныхЭлеметов = КоличествоПомеченныхЭлеметов + ?(ПодчиненныйЭлемент.Check = 1, 1, 0);
			КоличествоСерыхЭлеметов = КоличествоСерыхЭлеметов + ?(ПодчиненныйЭлемент.Check = 2, 1, 0);
		EndDo;
		
		// Устанавливаем пометки
		If КоличествоПомеченныхЭлеметов = 0 And КоличествоСерыхЭлеметов = 0 Then
			УстановитьПометкуРодительскихЭлементов(ЭлементРодитель, 0);
		ElsIf КоличествоПомеченныхЭлеметов = ПодчиненныеЭлементыРодителя.Count() Then
			УстановитьПометкуРодительскихЭлементов(ЭлементРодитель, 1);
		Else
			УстановитьПометкуРодительскихЭлементов(ЭлементРодитель, 2);
		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure CheckManagement(ЭлементДерева, ОтсекатьСеруюПометку = True)

	If ЭлементДерева = Undefined Then
		Return;
	EndIf;
	
	// отсечем серую пометку, считаем что сняли пометку
	If ОтсекатьСеруюПометку And ЭлементДерева.Check = 2 Then
		ЭлементДерева.Check = 0;
	EndIf;

	УстановитьПометкуПодчиненныхЭлементов(ЭлементДерева, ЭлементДерева.Check);
	УстановитьПометкуРодительскихЭлементов(ЭлементДерева, ЭлементДерева.Check);

EndProcedure

#EndRegion

#EndRegion