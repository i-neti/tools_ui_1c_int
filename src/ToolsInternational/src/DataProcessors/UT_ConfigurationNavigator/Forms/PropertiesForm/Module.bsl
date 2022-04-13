&AtClientAtServerNoContext
Function вСтрРазделить(Val Стр, Splitter, ВключатьПустые = True)

	МассивСтрок = New Array;
	If Splitter = " " Then
		Стр = TrimAll(Стр);
		While 1 = 1 Do
			Поз = Find(Стр, Splitter);
			If Поз = 0 Then
				Value = TrimAll(Стр);
				If ВключатьПустые Or Not IsBlankString(Value) Then
					МассивСтрок.Add(Value);
				EndIf;
				Return МассивСтрок;
			EndIf;

			Value = TrimAll(Left(Стр, Поз - 1));
			If ВключатьПустые Or Not IsBlankString(Value) Then
				МассивСтрок.Add(Value);
			EndIf;
			Стр = TrimL(Mid(Стр, Поз));
		EndDo;
	Else
		ДлинаРазделителя = StrLen(Splitter);
		While 1 = 1 Do
			Поз = Find(Стр, Splitter);
			If Поз = 0 Then
				Value = TrimAll(Стр);
				If ВключатьПустые Or Not IsBlankString(Value) Then
					МассивСтрок.Add(Value);
				EndIf;
				Return МассивСтрок;
			EndIf;

			Value = TrimAll(Left(Стр, Поз - 1));
			If ВключатьПустые Or Not IsBlankString(Value) Then
				МассивСтрок.Add(Value);
			EndIf;
			Стр = Mid(Стр, Поз + ДлинаРазделителя);
		EndDo;
	EndIf;

EndFunction

&AtClientAtServerNoContext
Function вЗначениеВМассив(Val Value)
	Array = New Array;
	Array.Add(Value);

	Return Array;
EndFunction

&AtServerNoContext
Function вЕстьПраваАдминистратора()
	Return AccessRight("Администрирование", Metadata);
EndFunction

&AtClient
Procedure вПоказатьВопрос(ProcedureName, ТекстВопроса, ДопПараметры = Undefined)
	ShowQueryBox(New NotifyDescription(ProcedureName, ThisForm, ДопПараметры), ТекстВопроса,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure
&AtServer
Procedure вОтладкаСервер()
	//ТабРезультат = vGetProcessor().моПолучитьТаблицеРегистраторов("ААА");
EndProcedure

&AtServer
Function вПолучитьОбработку()
	Return FormAttributeToValue("Object");
EndFunction

&AtServerNoContext
Function вСкопироватьСтруктуру(Src)
	Струк = New Structure;

	For Each Элем In Src Do
		Струк.Insert(Элем.Key, Элем.Value);
	EndDo;

	Return Струк;
EndFunction

&AtServerNoContext
Function вПроверитьНаличиеСвойства(Object, PropertyName)
	Струк = New Structure(PropertyName);
	FillPropertyValues(Струк, Object);

	Return (Струк[PropertyName] <> Undefined);
EndFunction

&AtServerNoContext
Function вСформироватьТаблицуДвиженийДокументов(АдресХранилища, Val UUID)
	Try
		ТабРезультат = GetFromTempStorage(АдресХранилища);
	Except
		ТабРезультат = Undefined;
	EndTry;

	If ТабРезультат = Undefined Then
		АдресХранилища = "";
	EndIf;

	If ТабРезультат = -1 Or ТабРезультат = Undefined Or ТабРезультат.Columns.Count() = 0 Then
		ТипСтрока = New TypeDescription("String", , , , New StringQualifiers(500));

		ТабРезультат = New ValueTable;
		ТабРезультат.Columns.Add("ИмяРегистра", ТипСтрока);
		ТабРезультат.Columns.Add("Name", ТипСтрока);
		ТабРезультат.Columns.Add("Synonym", ТипСтрока);
		ТабРезультат.Columns.Add("Comment", ТипСтрока);
		ТабРезультат.Columns.Add("StringType", ТипСтрока);

		For Each ОбъектМД In Metadata.Documents Do
			For Each Элем In ОбъектМД.RegisterRecords Do
				НС = ТабРезультат.Add();
				НС.Name = ОбъектМД.Name;
				НС.Synonym = ОбъектМД.Presentation();
				НС.Comment = ОбъектМД.Comment;
				НС.StringType = ОбъектМД.FullName();
				НС.ИмяРегистра = Элем.FullName();
			EndDo;
		EndDo;

		ТабРезультат.Sort("ИмяРегистра, Name");
		ТабРезультат.Indexes.Add("ИмяРегистра");

		АдресХранилища = PutToTempStorage(ТабРезультат, ?(АдресХранилища = "", UUID,
			АдресХранилища));
	EndIf;

	Return ТабРезультат;
EndFunction

&AtServerNoContext
Function вСформироватьТаблицуПодписокНаСобытия(АдресХранилища, Val UUID)
	Try
		ТабРезультат = GetFromTempStorage(АдресХранилища);
	Except
		ТабРезультат = Undefined;
	EndTry;

	If ТабРезультат = Undefined Then
		АдресХранилища = "";
	EndIf;

	If ТабРезультат = -1 Or ТабРезультат = Undefined Or ТабРезультат.Columns.Count() = 0 Then
		ТипСтрока = New TypeDescription("String", , , , New StringQualifiers(500));

		Кэш = New Map;

		ТабРезультат = New ValueTable;
		ТабРезультат.Columns.Add("Src", ТипСтрока);
		ТабРезультат.Columns.Add("Name", ТипСтрока);
		ТабРезультат.Columns.Add("Synonym", ТипСтрока);
		ТабРезультат.Columns.Add("Comment", ТипСтрока);

		СтрукДанные = New Structure("Name, Synonym, Comment");
		For Each Subscription In Metadata.EventSubscriptions Do
			СтрукДанные.Name = Subscription.Name;
			СтрукДанные.Synonym = Subscription.Presentation();
			СтрукДанные.Comment = СтрукДанные.Comment;

			For Each Type In Subscription.Src.Types() Do
				НС = ТабРезультат.Add();
				FillPropertyValues(НС, СтрукДанные);

				ИмяИсточника = Кэш[Type];
				If ИмяИсточника = Undefined Then
					ИмяИсточника =  Metadata.FindByType(Type).FullName();
					Кэш[Type] = ИмяИсточника;
				EndIf;

				НС.Src = ИмяИсточника;
			EndDo;
		EndDo;

		ТабРезультат.Sort("Src, Name");
		ТабРезультат.Indexes.Add("Src");

		АдресХранилища = PutToTempStorage(ТабРезультат, ?(АдресХранилища = "", UUID,
			АдресХранилища));
	EndIf;

	Return ТабРезультат;
EndFunction

&AtServerNoContext
Function вСформироватьТаблицуОбщихКоманд(АдресХранилища, Val UUID)
	Try
		ТабРезультат = GetFromTempStorage(АдресХранилища);
	Except
		ТабРезультат = Undefined;
	EndTry;

	If ТабРезультат = Undefined Then
		АдресХранилища = "";
	EndIf;

	If ТабРезультат = -1 Or ТабРезультат = Undefined Or ТабРезультат.Columns.Count() = 0 Then
		ТипСтрока = New TypeDescription("String", , , , New StringQualifiers(500));

		Кэш = New Map;

		ТабРезультат = New ValueTable;
		ТабРезультат.Columns.Add("Parameter", ТипСтрока);
		ТабРезультат.Columns.Add("Name", ТипСтрока);
		ТабРезультат.Columns.Add("Synonym", ТипСтрока);
		ТабРезультат.Columns.Add("Comment", ТипСтрока);

		СтрукДанные = New Structure("Name, Synonym, Comment");
		For Each ОбъектМД In Metadata.CommonCommands Do
			СтрукДанные.Name = ОбъектМД.Name;
			СтрукДанные.Synonym = ОбъектМД.Presentation();
			СтрукДанные.Comment = ОбъектМД.Comment;

			For Each Type In ОбъектМД.CommandParameterType.Types() Do
				НС = ТабРезультат.Add();
				FillPropertyValues(НС, СтрукДанные);

				ИмяПараметра = Кэш[Type];
				If ИмяПараметра = Undefined Then
					ИмяПараметра =  Metadata.FindByType(Type).FullName();
					Кэш[Type] = ИмяПараметра;
				EndIf;

				НС.Parameter = ИмяПараметра;
			EndDo;
		EndDo;

		ТабРезультат.Sort("Parameter, Name");
		ТабРезультат.Indexes.Add("Parameter");

		АдресХранилища = PutToTempStorage(ТабРезультат, ?(АдресХранилища = "", UUID,
			АдресХранилища));
	EndIf;

	Return ТабРезультат;
EndFunction

&AtServerNoContext
Function вСформироватьТаблицуКоманд(АдресХранилища, Val UUID)
	Try
		ТабРезультат = GetFromTempStorage(АдресХранилища);
	Except
		ТабРезультат = Undefined;
	EndTry;

	If ТабРезультат = Undefined Then
		АдресХранилища = "";
	EndIf;

	If ТабРезультат = -1 Or ТабРезультат = Undefined Or ТабРезультат.Columns.Count() = 0 Then
		ТипСтрока = New TypeDescription("String", , , , New StringQualifiers(500));

		Кэш = New Map;

		ТабРезультат = New ValueTable;
		ТабРезультат.Columns.Add("Parameter", ТипСтрока);
		ТабРезультат.Columns.Add("Name", ТипСтрока);
		ТабРезультат.Columns.Add("Synonym", ТипСтрока);
		ТабРезультат.Columns.Add("Comment", ТипСтрока);

		СтрукДанные = New Structure("Name, Synonym, Comment");

		ПереченьРазделов = "Catalogs, DocumentJournals, Documents, Enums, DataProcessors, Reports,
						   |ChartsOfAccounts, ChartsOfCharacteristicTypes, ChartsOfCalculationTypes, ExchangePlans,
						   |InformationRegisters, AccumulationRegisters, CalculationRegisters, AccountingRegisters,
						   |BusinessProcesses, Tasks, FilterCriteria";

		СтрукРазделы = New Structure(ПереченьРазделов);

		For Each Элем In СтрукРазделы Do
			For Each ОбъектХХХ In Metadata[Элем.Key] Do
				ИмяТипаХХХ = ОбъектХХХ.FullName();

				If вПроверитьНаличиеСвойства(ОбъектХХХ, "Commands") Then
					For Each ОбъектМД In ОбъектХХХ.Commands Do
						СтрукДанные.Name = ОбъектМД.FullName();
						СтрукДанные.Synonym = ОбъектМД.Presentation();
						СтрукДанные.Comment = ОбъектМД.Comment;

						For Each Type In ОбъектМД.CommandParameterType.Types() Do
							ИмяПараметра = Кэш[Type];
							If ИмяПараметра = Undefined Then
								ИмяПараметра =  Metadata.FindByType(Type).FullName();
								Кэш[Type] = ИмяПараметра;
							EndIf;

							If ИмяПараметра = ИмяТипаХХХ Then
								Continue;
							EndIf;

							НС = ТабРезультат.Add();
							FillPropertyValues(НС, СтрукДанные);

							НС.Parameter = ИмяПараметра;
						EndDo;
					EndDo;
				EndIf;
			EndDo;
		EndDo;

		ТабРезультат.Sort("Parameter, Name");
		ТабРезультат.Indexes.Add("Parameter");

		АдресХранилища = PutToTempStorage(ТабРезультат, ?(АдресХранилища = "", UUID,
			АдресХранилища));
	EndIf;

	Return ТабРезультат;
EndFunction

&AtServerNoContext
Function вСформироватьТаблицуПодсистем(АдресХранилища, Val UUID)
	Try
		ТабРезультат = GetFromTempStorage(АдресХранилища);
	Except
		ТабРезультат = Undefined;
	EndTry;

	If ТабРезультат = Undefined Then
		АдресХранилища = "";
	EndIf;

	If ТабРезультат = -1 Or ТабРезультат = Undefined Or ТабРезультат.Columns.Count() = 0 Then
		ТипСтрока = New TypeDescription("String", , , , New StringQualifiers(500));

		Кэш = New Map;

		ТабРезультат = New ValueTable;
		ТабРезультат.Columns.Add("Object", ТипСтрока);
		ТабРезультат.Columns.Add("Name", ТипСтрока);
		ТабРезультат.Columns.Add("FullName", ТипСтрока);
		ТабРезультат.Columns.Add("Synonym", ТипСтрока);
		ТабРезультат.Columns.Add("Comment", ТипСтрока);

		Коллекция = New Map;
		вСформироватьКоллекциюПодсистем( , Коллекция);

		СтрукДанные = New Structure("Name, FullName, Synonym, Comment");
		For Each Элем In Коллекция Do
			ОбъектМД = Элем.Key;

			СтрукДанные.Name = ОбъектМД.Name;
			СтрукДанные.FullName = ОбъектМД.FullName();
			СтрукДанные.Synonym = ОбъектМД.Presentation();
			СтрукДанные.Comment = ОбъектМД.Comment;

			For Each Элем In ОбъектМД.Content Do
				НС = ТабРезультат.Add();
				FillPropertyValues(НС, СтрукДанные);

				НС.Object = Элем.FullName();
			EndDo;
		EndDo;

		ТабРезультат.Sort("Object, Name");
		ТабРезультат.Indexes.Add("Object");

		АдресХранилища = PutToTempStorage(ТабРезультат, ?(АдресХранилища = "", UUID,
			АдресХранилища));
	EndIf;

	Return ТабРезультат;
EndFunction

&AtServerNoContext
Procedure вСформироватьКоллекциюПодсистем(Val Подсистема = Undefined, Val Коллекция)
	If Подсистема = Undefined Then
		For Each ОбъектМД In Metadata.Subsystems Do
			вСформироватьКоллекциюПодсистем(ОбъектМД, Коллекция);
		EndDo;
	Else
		Коллекция.Insert(Подсистема);
		For Each ОбъектМД In Подсистема.Subsystems Do
			Коллекция.Insert(ОбъектМД);
			вСформироватьКоллекциюПодсистем(ОбъектМД, Коллекция);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Function вПолучитьТаблицуРегистраторов(ИмяРегистра)
	Return вСформироватьТаблицуДвиженийДокументов(_StorageAddresses.RegisterRecords, UUID).Copy(
		New Structure("ИмяРегистра", ИмяРегистра));
EndFunction

&AtServer
Function вПолучитьТаблицуПодписок(ObjectName)
	Return вСформироватьТаблицуПодписокНаСобытия(_StorageAddresses.Подписки, UUID).Copy(
		New Structure("Src", ObjectName));
EndFunction

&AtServer
Function вПолучитьТаблицуОбщихКоманд(ObjectName)
	Return вСформироватьТаблицуОбщихКоманд(_StorageAddresses.CommonCommands, UUID).Copy(
		New Structure("Parameter", ObjectName));
EndFunction

&AtServer
Function вПолучитьТаблицуЧужихКоманд(ObjectName)
	Return вСформироватьТаблицуКоманд(_StorageAddresses.Commands, UUID).Copy(
		New Structure("Parameter", ObjectName));
EndFunction

&AtServer
Function вПолучитьТаблицуПодсистем(ObjectName)
	Return вСформироватьТаблицуПодсистем(_StorageAddresses.Subsystems, UUID).Copy(
		New Structure("Object", ObjectName));
EndFunction

&AtClient
Function вСформироватьСтруктуруНастроекФормыСвойствОбъекта()
	Струк = New Structure("_ShowEventSubscriptions, _ShowJbjectsSubsytems, _ShowCommonObjectCommands, _ShowExternalObjectCommands");
	FillPropertyValues(Струк, ThisForm);

	Return Струк;
EndFunction
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Title = Parameters.FullName;

	_FullName = Parameters.FullName;
	
	_ListFormName = ".ФормаСписка";

	PathToForms = Parameters.PathToForms;

	_StorageAddresses = вСкопироватьСтруктуру(Parameters._StorageAddresses);

	_AdditionalVars = New Structure;
	_AdditionalVars.Insert("DescriptionOfAccessRights", Parameters.DescriptionOfAccessRights);

	FillPropertyValues(ThisForm, Parameters.ProcessingSettings);

	Items.PropertyTreeGroup_UpdateNumberOfObjects.Visible = вЕстьПраваАдминистратора();

	Items._AccessRightForRole.Visible = False;
	Items.AccessRightToObject_Role.Visible = True;

	Items.ValuePage.Visible = False;
	Items.DependentObjectsPage.Visible = False;
	Items.ManagingTotalsPage.Visible = False;

	If Parameters.FullName = "Конфигурация" Then
		вЗаполнитьСвойстваКонфигурации();
		Items.PropertyTreeGroupkOpemListForm.Visible = False;
		Items.PropertyTreeGroupkOpemListFormAdditional.Visible = False;
		Items.PropertyTreeGroupkShowObjectProperties.Visible = False;
		Items.StorageStructurePage.Visible = False;
		Goto ~End;
	EndIf;

	ЭтоПрочаяКоманда = (Find(Parameters.FullName, ".Command.") <> 0);

	If Not ЭтоПрочаяКоманда And Find(Parameters.FullName, "Подсистема.") <> 1 Then
		If StrOccurrenceCount(Parameters.FullName, ".") <> 1 Then
			Cancel = True;
			Return;
		EndIf;
	EndIf;

	Items.AccessRightPage.Visible = вЕстьПраваАдминистратора();
	If Items.AccessRightPage.Visible Then
		Items._AccessRightToObject.ChoiceList.Clear();

		пСписокПрав = _AdditionalVars.DescriptionOfAccessRights[?(ЭтоПрочаяКоманда, "ОбщаяКоманда", Left(_FullName, StrFind(
			_FullName, ".") - 1))];
		If пСписокПрав <> Undefined Then
			пПравоДоступаПоУмолчанию = "";

			For Each Элем In New Structure(пСписокПрав) Do
				Items._AccessRightToObject.ChoiceList.Add(Элем.Key);
				If IsBlankString(пПравоДоступаПоУмолчанию) Then
					пПравоДоступаПоУмолчанию = Элем.Key;
				EndIf;
			EndDo;

			_AccessRightToObject = пПравоДоступаПоУмолчанию;
		EndIf;
	EndIf;

	If ЭтоПрочаяКоманда Then
		_ListFormName = "";
		вЗаполнитьСвойстваОбщейКоманды(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "Catalog.") = 1 Then
		вЗаполнитьСвойстваСправочника(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "Document.") = 1 Then
		вЗаполнитьСвойстваДокумента(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "DocumentJournal.") = 1 Then
		вЗаполнитьСвойстваЖурналаДокументов(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "ChartOfCharacteristicTypes.") = 1 Then
		вЗаполнитьСвойстваПВХ(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "ChartOfCalculationTypes.") = 1 Then
		вЗаполнитьСвойстваПВР(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "ChartOfAccounts.") = 1 Then
		вЗаполнитьСвойстваПланаСчетов(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "InformationRegister.") = 1 Then
		вЗаполнитьСвойстваРегистраСведений(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "AccumulationRegister.") = 1 Then
		вЗаполнитьСвойстваРегистраНакопления(Parameters.FullName);
		вЗаполнитьСраницуУправленияИтогами(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "AccountingRegister.") = 1 Then
		вЗаполнитьСвойстваРегистраБухгалтерии(Parameters.FullName);
		вЗаполнитьСраницуУправленияИтогами(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "CalculationRegister.") = 1 Then
		вЗаполнитьСвойстваРегистраРасчета(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "BusinessProcess.") = 1 Then
		вЗаполнитьСвойстваБизнесПроцесса(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "Task.") = 1 Then
		вЗаполнитьСвойстваЗадачи(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "ExchangePlan.") = 1 Then
		вЗаполнитьСвойстваПланаОбмена(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "Constant.") = 1 Then
		вЗаполнитьСвойстваКонстанты(Parameters.FullName);
		Items.PropertyTreeGroupkOpemListForm.Visible = False;
		Items.PropertyTreeGroupkOpemListFormAdditional.Visible = False;
	ElsIf Find(Parameters.FullName, "ПараметрСеанса.") = 1 Then
		вЗаполнитьСвойстваПараметрСеанса(Parameters.FullName);
		Items.PropertyTreeGroupkOpemListForm.Visible = False;
		Items.PropertyTreeGroupkOpemListFormAdditional.Visible = False;
	ElsIf Find(Parameters.FullName, "Enum.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		вЗаполнитьСвойстваПеречисления(Parameters.FullName);
		Items.DependentObjectsPage.Visible = True;
	ElsIf Find(Parameters.FullName, "CommonModule.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		вЗаполнитьСвойстваОбщегоМодуля(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "ОбщаяКоманда.") = 1 Then
		_ListFormName = "";
		вЗаполнитьСвойстваОбщейКоманды(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "Подсистема.") = 1 Then
		_ListFormName = "";
		вЗаполнитьСвойстваПодсистемы(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "ОпределяемыйТип.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		вЗаполнитьСвойстваОпределяемогоТипа(Parameters.FullName);
	ElsIf Find(Parameters.FullName, "ПодпискаНаСобытие.") = 1 Then
		Items.AccessRightPage.Visible = False;
		_ListFormName = "";
		вЗаполнитьСвойстваПодпискиНаСобытие(Parameters.FullName);
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

		пСписокПрав =  "Read, Create, Update, Delete, Browse, Edit, Use, УправлениеИтогами, Posting, UndoPosting, Receive, Установка, Start, Выполнение";
		For Each Элем In New Structure(пСписокПрав) Do
			Items._AccessRightToObject.ChoiceList.Add(Элем.Key);
		EndDo;

		_AccessRightToObject = "Read";
		Return;
	Else
		Cancel = True;
		Return;
	EndIf;

	Items.PropertyTreeGroup_OpenObject.Visible = (_ПустаяСсылкаНаОбъект <> Undefined);

	ОбъектМД = Metadata.FindByFullName(Parameters.FullName);
	If ОбъектМД <> Undefined Then
		ДанныеСХ = GetDBStorageStructureInfo(вЗначениеВМассив(ОбъектМД),
			Not _ShowStorageStructureIn1CTerms);
		If ДанныеСХ = Undefined Or ДанныеСХ.Count() = 0 Then
			Items.StorageStructurePage.Visible = ложь
		Else
			вЗаполнитьРазделСтруктураХранения(ДанныеСХ);
		EndIf;
	Else
		Items.StorageStructurePage.Visible = ложь
	EndIf
	;

	~End: For Each УзелДЗ In PropertyTree.GetItems() Do
		УзелДЗ.ВидУзла = 1;
		
		//If StrFind(УзелДЗ.StringType, "Enum.") <> 0 Then
		//	Break;
		//EndIf;

		For Each РазделДЗ In УзелДЗ.GetItems() Do
			РазделДЗ.ВидУзла = 2;
		EndDo;
	EndDo;

	вУстановитьУсловноеОформление();
EndProcedure

&AtServer
Procedure вУстановитьУсловноеОформление()
	ThisForm.ConditionalAppearance.Items.Clear();

	ЭлементУО = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ЭлементУО.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("PropertyTree.ВидУзла");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 1;
	ЭлементУО.Appearance.SetParameterValue("Font", New Font(Items.PropertyTree.Font, , , True));
	ЭлементУО.Fields.Items.Add().Field = New DataCompositionField("PropertyTreeName");

	ЭлементУО = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ЭлементУО.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("PropertyTree.ВидУзла");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 2;
	ЭлементУО.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	ЭлементУО.Fields.Items.Add().Field = New DataCompositionField("PropertyTreeName");

	ЭлементУО = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ЭлементУО.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("PropertyTree.Indexing");
	FilterItem.ComparisonType = DataCompositionComparisonType.NotEqual;
	FilterItem.RightValue = "";
	ЭлементУО.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	//ЭлементУО.Appearance.SetParameterValue("BgColor", WebColors.LightGoldenRodYellow);
	ЭлементУО.Fields.Items.Add().Field = New DataCompositionField("PropertyTree");

	ЭлементУО = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ЭлементУО.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("_DependentObjects.ВидУзла");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 1;
	ЭлементУО.Appearance.SetParameterValue("Font", New Font(Items._DependentObjects.Font, , , True));
	ЭлементУО.Fields.Items.Add().Field = New DataCompositionField("_DependentObjectsName");

	ЭлементУО = ThisForm.ConditionalAppearance.Items.Add();
	FilterItem = ЭлементУО.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterItem.LeftValue = New DataCompositionField("_DependentObjects.ВидУзла");
	FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	FilterItem.RightValue = 2;
	ЭлементУО.Appearance.SetParameterValue("TextColor", WebColors.DarkBlue);
	ЭлементУО.Fields.Items.Add().Field = New DataCompositionField("_DependentObjectsName");

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	For Each Элем In PropertyTree.GetItems() Do
		ExpandAll = (False Or Find(Элем.StringType, "Конфигурация.") = 1 Or Find(Элем.StringType, "Подсистема.")
			= 1 Or Find(Элем.StringType, "CommonModule.") = 1 Or Find(Элем.StringType, "ОбщаяКоманда.") = 1
			Or Find(Элем.StringType, "ПодпискаНаСобытие.") = 1 Or Find(Элем.StringType, "DocumentJournal.") = 1
			Or Find(Элем.StringType, "ОпределяемыйТип.") = 1 Or Find(Элем.StringType, ".Command.") <> 0);
		Items.PropertyTree.Expand(Элем.GetID(), ExpandAll);
		Break;
	EndDo;

	If StrFind(_FullName, "Role.") = 1 And Not IsBlankString(_AccessRightToObject) Then
		_ПравоДоступаКОбъектуПриИзменении(Items._ПравоДоступаКОбъекту);
	EndIf;
EndProcedure

&AtClient
Procedure _ExpandAllNodes(Command)
	If Items.PagesGroup.CurrentPage = Items.ObjectPage Then
		For Each Элем In PropertyTree.GetItems() Do
			Items.PropertyTree.Expand(Элем.GetID(), True);
		EndDo;
	ElsIf Items.PagesGroup.CurrentPage = Items.DependentObjectsPage Then
		For Each Элем In _DependentObjects.GetItems() Do
			Items._DependentObjects.Expand(Элем.GetID(), True);
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure _CollapseAllNodes(Command)
	If Items.PagesGroup.CurrentPage = Items.ObjectPage Then
		For Each УзелДЗ In PropertyTree.GetItems() Do
			For Each Элем In УзелДЗ.GetItems() Do
				Items.PropertyTree.Collapse(Элем.GetID());
			EndDo;
		EndDo;
	ElsIf Items.PagesGroup.CurrentPage = Items.DependentObjectsPage Then
		For Each УзелДЗ In _DependentObjects.GetItems() Do
			For Each Элем In УзелДЗ.GetItems() Do
				Items._DependentObjects.Collapse(Элем.GetID());
			EndDo;
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure kOpemListForm(Command)
	СтрДЗ = PropertyTree.FindByID(0);
	If СтрДЗ <> Undefined And Not IsBlankString(_ListFormName) Then
		Try
			OpenForm(СтрДЗ.StringType + _ListFormName);
		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
EndProcedure

&AtClient
Procedure kOpemListFormAdditional(Command)
	СтрДЗ = PropertyTree.FindByID(0);
	If СтрДЗ <> Undefined And Not IsBlankString(_ListFormName) Then
		UT_CommonClient.ОpenDynamicList(СтрДЗ.StringType);
	EndIf;
EndProcedure

&AtClient
Procedure kShowObjectProperties(Command)
	ТекДанные = Items.PropertyTree.CurrentData;
	If ТекДанные <> Undefined And Not IsBlankString(ТекДанные.ТипСтрокой) Then
		Array = вСтрокуТипаВМассив(ТекДанные.ТипСтрокой);
		If Array.Count() = 1 Then
			вПоказатьСвойстваОбъекта(Array[0]);
		ElsIf Array.Count() > 1 Then
			List = New ValueList;
			List.LoadValues(Array);
			List.SortByValue();
			Try
				List.ShowChooseItem(New NotifyDescription("кПоказатьСвойстваОбъектаДалее", ThisForm),
					"Selection типа");
			Except
				ВыбранныйЭлемент = Undefined;

				List.ShowChooseItem(New NotifyDescription("кПоказатьСвойстваОбъектаЗавершение", ThisForm),
					"Selection типа");
			EndTry;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure кПоказатьСвойстваОбъектаЗавершение(ВыбранныйЭлемент1, AdditionalParameters) Export

	ВыбранныйЭлемент = ВыбранныйЭлемент1;
	If ВыбранныйЭлемент <> Undefined Then
		кПоказатьСвойстваОбъектаДалее(ВыбранныйЭлемент, Undefined);
	EndIf;

EndProcedure

&AtClient
Procedure кПоказатьСвойстваОбъектаДалее(ВыбранныйЭлемент, ДопПараметры) Export
	If ВыбранныйЭлемент <> Undefined Then
		вПоказатьСвойстваОбъекта(ВыбранныйЭлемент.Value);
	EndIf;
EndProcedure

&AtClient
Procedure _OpenObject(Command)
	СтрукПарам = New Structure;
	СтрукПарам.Insert("мОбъектСсылка", _ПустаяСсылкаНаОбъект);
	OpenForm(PathToForms + "ФормаОбъекта", СтрукПарам, , CurrentDate());
EndProcedure
&AtClient
Procedure ДеревоСвойствВыбор(Item, SelectedRow, Field, StandardProcessing)
	СтрДЗ = PropertyTree.FindByID(SelectedRow);
	If СтрДЗ.Reference <> Undefined Then
		ShowValue( , СтрДЗ.Reference);
	ElsIf Not IsBlankString(СтрДЗ.StringType) Then
		кПоказатьСвойстваОбъекта(Undefined);
	EndIf;
EndProcedure

&AtClient
Procedure вПоказатьСвойстваОбъекта(FullName)
	If Not IsBlankString(PathToForms) Then
		Поз = StrFind(FullName, ".Command.");
		If Поз <> 0 Then
			TypeName = Left(FullName, Поз - 1);
		Else
			TypeName = FullName;
		EndIf;

		СтрукПараметры = New Structure("FullName, PathToForms, _StorageAddresses, DescriptionOfAccessRights", TypeName,
			PathToForms, _StorageAddresses, _AdditionalVars.DescriptionOfAccessRights);
		СтрукПараметры.Insert("ProcessingSettings", вСформироватьСтруктуруНастроекФормыСвойствОбъекта());
		OpenForm(PathToForms + "PropertiesForm", СтрукПараметры, , TypeName, , , , FormWindowOpeningMode.Independent);
	EndIf;
EndProcedure

&AtClient
Function вСтрокуТипаВМассив(ТипСтрокой)
	ПростыеТипы = "/Boolean/Date/DateTime/String/Number/ValueStorage/UUID/";
	Result = New Array;

	For Each Элем In вСтрРазделить(ТипСтрокой, ",", False) Do
		If Find(ПростыеТипы, Элем) = 0 Then
			If Find(Элем, "String(") = 0 And Find(Элем, "Number(") = 0 Then
				Result.Add(Элем);
			EndIf;
		EndIf;
	EndDo;

	Return Result;
EndFunction
&AtServerNoContext
Function вСформироватьСтруктуруТипов()
	Result = New Structure;

	Result.Insert("мТипСтрока", Type("String"));
	Result.Insert("мТипБулево", Type("Boolean"));
	Result.Insert("мТипЧисло", Type("Number"));
	Result.Insert("мТипДата", Type("Date"));
	Result.Insert("мТипСтруктура", Type("Structure"));
	Result.Insert("мТипХранилищеЗначения", Type("ValueStorage"));
	Result.Insert("мТипДвоичныеДанные", Type("BinaryData"));
	Result.Insert("мТипДеревоЗначений", Type("ValueTree"));
	Result.Insert("мТипОбъектМетаданных", Type("ОбъектМетаданных"));
	Result.Insert("мТипУникальныйИдентификатор", Type("UUID"));

	Result.Insert("мТипNULL", Type("NULL"));
	Result.Insert("мТипНЕОПРЕДЕЛЕНО", Type("НЕОПРЕДЕЛЕНО"));
	Result.Insert("мТипОписаниеТипов", Type("TypeDescription"));
	Result.Insert("мТипВидДвиженияБухгалтерии", Type("AccountingRecordType"));
	Result.Insert("мТипВидДвиженияНакопления", Type("AccumulationRecordType"));
	Result.Insert("мТипВидСчета", Type("AccountType"));
	Result.Insert("мТипФиксированныйМассив", Type("FixedArray"));
	Result.Insert("мТипФиксированнаяСтруктура", Type("FixedStructure"));
	Result.Insert("мТипФиксированноеСоответствие", Type("FixedMap"));

	Return Result;
EndFunction

&AtServerNoContext
Function вИмяТипаСтрокой(СтрукТипы, Type, TypeDescription)
	TypeName = "";

	If Type = СтрукТипы.мТипЧисло Then
		TypeName = "Number";
		If TypeDescription.NumberQualifiers.Digits <> 0 Then
			TypeName = TypeName + "(" + TypeDescription.NumberQualifiers.Digits + "."
				+ TypeDescription.NumberQualifiers.FractionDigits + ")";
		EndIf;
	ElsIf Type = СтрукТипы.мТипСтрока Then
		TypeName = "String";
		If TypeDescription.StringQualifiers.Length <> 0 Then
			TypeName = TypeName + "(" + ?(TypeDescription.StringQualifiers.AllowedLength = AllowedLength.Variable,
				"П", "Ф") + TypeDescription.StringQualifiers.Length + ")";
		EndIf;
	ElsIf Type = СтрукТипы.мТипДата Then
		TypeName = ?(TypeDescription.DateQualifiers.DateFractions = DateFractions.Time, "Time", ?(
			TypeDescription.DateQualifiers.DateFractions = DateFractions.Date, "Date", "DateTime"));
	ElsIf Type = СтрукТипы.мТипБулево Then
		TypeName = "Boolean";
	ElsIf Type = СтрукТипы.мТипДвоичныеДанные Then
		TypeName = "BinaryData";
	ElsIf Type = СтрукТипы.мТипХранилищеЗначения Then
		TypeName = "ValueStorage";
	ElsIf Type = СтрукТипы.мТипУникальныйИдентификатор Then
		TypeName = "UUID";

	ElsIf Type = СтрукТипы.мТипNULL Then
		TypeName = "NULL";
	ElsIf Type = СтрукТипы.мТипНЕОПРЕДЕЛЕНО Then
		TypeName = "НЕОПРЕДЕЛЕНО";
	ElsIf Type = СтрукТипы.мТипОписаниеТипов Then
		TypeName = "TypeDescription";
	ElsIf Type = СтрукТипы.мТипВидДвиженияБухгалтерии Then
		TypeName = "AccountingRecordType";
	ElsIf Type = СтрукТипы.мТипВидДвиженияНакопления Then
		TypeName = "AccumulationRecordType";
	ElsIf Type = СтрукТипы.мТипВидСчета Then
		TypeName = "AccountType";
	ElsIf Type = СтрукТипы.мТипФиксированныйМассив Then
		TypeName = "FixedArray";
	ElsIf Type = СтрукТипы.мТипФиксированнаяСтруктура Then
		TypeName = "FixedStructure";
	ElsIf Type = СтрукТипы.мТипФиксированноеСоответствие Then
		TypeName = "FixedMap";

	Else
		ОбъектМД = Metadata.FindByType(Type);
		If ОбъектМД <> Undefined Then
			TypeName = ОбъектМД.FullName();
		Else
			TypeName = String(Type);
		EndIf;
	EndIf;

	Return TypeName;
EndFunction

&AtServerNoContext
Function вОписаниеТиповВСтроку(TypeDescription)
	If TypeDescription = Undefined Then
		Return "";
	EndIf;

	СтрукТипы = вСформироватьСтруктуруТипов();

	Value = "";
	Types = TypeDescription.Types();
	For Each Элем In Types Do
		TypeName = вИмяТипаСтрокой(СтрукТипы, Элем, TypeDescription);
		If Not IsBlankString(TypeName) Then
			Value = Value + "," + TypeName;
		EndIf;
	EndDo;

	Return Mid(Value, 2);
EndFunction
&AtServer
Function вСформироватьТаблицуСвойств()
	ТипСтрока = New TypeDescription("String");

	ТабРезультат = New ValueTable;
	ТабРезультат.Columns.Add("Name", ТипСтрока);
	ТабРезультат.Columns.Add("Indexing", ТипСтрока);
	ТабРезультат.Columns.Add("Synonym", ТипСтрока);
	ТабРезультат.Columns.Add("Comment", ТипСтрока);
	ТабРезультат.Columns.Add("StringType", ТипСтрока);

	Return ТабРезультат;
EndFunction

&AtServer
Procedure вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств)
	РазделДЗ = УзелДЗ.GetItems().Add();
	РазделДЗ.Name = "Properties";

	ТипОбъектМД = Type("ОбъектМетаданных");
	ТипОписаниеТипов = Type("TypeDescription");

	Try
		// начиная с версии 8.3.8 (надо контролировать версию)
		пРасширениеКонфигурации = ОбъектМД.ConfigurationExtension();
		If пРасширениеКонфигурации <> Undefined Then
			СтрДЗ = РазделДЗ.GetItems().Add();
			СтрДЗ.Name = "ConfigurationExtension";
			СтрДЗ.Synonym = пРасширениеКонфигурации.Name;
			СтрДЗ.StringType = "ConfigurationExtension";
			СтрДЗ.Comment = пРасширениеКонфигурации.Synonym;
		EndIf;
	Except
	EndTry;

	Струк = New Structure(ПереченьСвойств);
	FillPropertyValues(Струк, ОбъектМД);
	For Each Элем In Струк Do
		СтрДЗ = РазделДЗ.GetItems().Add();
		СтрДЗ.Name = Элем.Key;
		СтрДЗ.Synonym = Элем.Value;
		If Элем.Value <> Undefined Then
			пТипЗнч = TypeOf(Элем.Value);
			If пТипЗнч = ТипОбъектМД Then
				СтрДЗ.StringType = Элем.Value.FullName();
			ElsIf пТипЗнч = ТипОписаниеТипов Then
				СтрДЗ.StringType = вОписаниеТиповВСтроку(Элем.Value);
			EndIf;
		EndIf;
	EndDo;
	
	// начиная с версии 8.3.8 (надо контролировать версию)
	//Try
	//	Х = ОбъектМД.ConfigurationExtension();
	//	If Х <> Undefined Then
	//		СтрДЗ = РазделДЗ.GetItems().Add();
	//		СтрДЗ.Name = "ConfigurationExtension";
	//		СтрДЗ.Synonym = Х.Name;
	//	EndIf;
	//Except
	//EndTry;
EndProcedure

&AtServerNoContext
Function вПолучитьСвойстовоИндексирование(Val ОбъектМД)
	Струк = New Structure("Indexing");
	пСвойствоИндексирование = Metadata.ObjectProperties.Indexing;

	FillPropertyValues(Струк, ОбъектМД);
	If Струк.Indexing = Undefined Then
		Value = "";
	ElsIf Струк.Indexing = пСвойствоИндексирование.DontIndex Then
		Value = "";
	Else
		Value = Струк.Indexing;
	EndIf;

	Return Value;
EndFunction

&AtServer
Procedure вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, ИмяГруппы, Sort = True, ВыводитьКоличество = False)
	If ОбъектМД[ИмяГруппы].Count() <> 0 Then
		Table = вСформироватьТаблицуСвойств();
		For Each Элем In ОбъектМД[ИмяГруппы] Do
			Стр = Table.Add();
			Стр.Name = Элем.Name;
			Стр.Indexing = вПолучитьСвойстовоИндексирование(Элем);
			Стр.Synonym = Элем.Presentation();
			Стр.Comment = Элем.Comment;
			Стр.StringType = вОписаниеТиповВСтроку(Элем.Type);
		EndDo;

		If Sort Then
			Table.Sort("Name");
		EndIf;

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = ИмяГруппы;
		If ВыводитьКоличество Then
			РазделДЗ.Name = РазделДЗ.Name + " (" + Table.Count() + ")";
		EndIf;

		For Each Стр In Table Do
			FillPropertyValues(РазделДЗ.GetItems().Add(), Стр);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ)
	If вПроверитьНаличиеСвойства(ОбъектМД, "Commands") And ОбъектМД.Commands.Count() <> 0 Then
		Table = вСформироватьТаблицуСвойств();
		For Each Элем In ОбъектМД.Commands Do
			Стр = Table.Add();
			Стр.Name = Элем.Name;
			Стр.Synonym = Элем.Presentation();
			Стр.Comment = Элем.Comment;
			Стр.StringType = Элем.FullName();
		EndDo;

		Table.Sort("Name");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Commands (" + Table.Count() + ")";

		For Each Стр In Table Do
			FillPropertyValues(РазделДЗ.GetItems().Add(), Стр);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ)
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Attributes", True, True);
EndProcedure

&AtServer
Procedure вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ)
	List = New ValueList;
	For Each Элем In ОбъектМД.TabularSections Do
		List.Add(Элем.Name);
	EndDo;
	List.SortByValue();

	For Each ЭлемХ In List Do
		Элем = ОбъектМД.TabularSections[ЭлемХ.Value];
		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "ТЧ." + Элем.Name;

		Table = вСформироватьТаблицуСвойств();
		For Each ЭлемТЧ In Элем.Attributes Do
			Стр = Table.Add();
			Стр.Name = ЭлемТЧ.Name;
			Стр.Synonym = ЭлемТЧ.Presentation();
			Стр.Comment = ЭлемТЧ.Comment;
			Стр.StringType = вОписаниеТиповВСтроку(ЭлемТЧ.Type);
		EndDo;
		Table.Sort("Name");

		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndDo;
EndProcedure

&AtServer
Procedure вЗаполнитьТипыЗначенийХарактеристик(ОбъектМД, УзелДЗ)
	Array = ОбъектМД.Type.Types();

	If Array.Count() <> 0 Then
		Table = вСформироватьТаблицуСвойств();
		Table.Columns.Add("NBSp", New TypeDescription("Number"));

		СтрукТипы = вСформироватьСтруктуруТипов();

		For Each Элем In Array Do
			ЭлемМД = Metadata.FindByType(Элем);

			Стр = Table.Add();
			If ЭлемМД <> Undefined Then
				Стр.Name = ЭлемМД.Name;
				Стр.Synonym = ЭлемМД.Presentation();
				Стр.Comment = "";
				Стр.StringType = ЭлемМД.FullName();
			Else
				TypeName = вИмяТипаСтрокой(СтрукТипы, Элем, ОбъектМД.Type);

				Стр.NBSp = -1;
				Стр.Name = Элем;
				Стр.Synonym = Элем;
				Стр.Comment = "";
				Стр.StringType = TypeName;
			EndIf;
		EndDo;

		If ОбъектМД.CharacteristicExtValues <> Undefined Then
			ЭлемМД = ОбъектМД.CharacteristicExtValues;

			If Table.Find(ЭлемМД.FullName(), "StringType") = Undefined Then
				Стр = Table.Add();
				Стр.Name = ЭлемМД.Name;
				Стр.Synonym = ЭлемМД.Presentation();
				Стр.Comment = "";
				Стр.StringType = ЭлемМД.FullName();
			EndIf;
		EndIf;

		Table.Sort("NBSp, StringType");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "ТипыЗначенийХарактеристик (" + Table.Count() + ")";

		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьПредопределенныеЭлементыОбъекта(ОбъектМД, УзелДЗ)
	If Metadata.Catalogs.Contains(ОбъектМД) Then
		Менеджер = Catalogs;
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(ОбъектМД) Then
		Менеджер = ChartsOfCalculationTypes;
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(ОбъектМД) Then
		Менеджер = ChartsOfCharacteristicTypes;
	ElsIf Metadata.ChartsOfAccounts.Contains(ОбъектМД) Then
		Менеджер = ChartsOfAccounts;
	Else
		Return;
	EndIf;

	Менеджер = Менеджер[ОбъектМД.Name];

	Query = New Query;
	Query.Text = "ВЫБРАТЬ Reference, Presentation КАК Title ИЗ " + ОбъектМД.FullName() + " ГДЕ Predefined";

	Try
		ValueTable = Query.Execute().Unload();
	Except
		// при отсутствии прав доступа
		ValueTable = New ValueTable;
	EndTry;

	If ValueTable.Count() <> 0 Then
		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Predefined (" + ValueTable.Count() + ")";

		For Each Элем In ValueTable Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			СтрДЗ.Name = Менеджер.ПолучитьИмяПредопределенного(Элем.Reference);
			СтрДЗ.Synonym = Элем.Title;
			СтрДЗ.Comment = "";
			СтрДЗ.StringType = "Reference";
			СтрДЗ.Reference = Элем.Reference;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьСвойствоКоллекцияОбъекта(ОбъектМД, УзелДЗ, ИмяКоллекции, Sort = True,
	ПолеСортировки = "Name")
	If ОбъектМД[ИмяКоллекции].Count() <> 0 Then
		Table = вСформироватьТаблицуСвойств();
		For Each Элем In ОбъектМД[ИмяКоллекции] Do
			Стр = Table.Add();
			Стр.Name = Элем.Name;
			Стр.Synonym = Элем.Presentation();
			Стр.Comment = Элем.Comment;
			Стр.StringType = Элем.FullName();
		EndDo;

		If Sort Then
			Table.Sort(ПолеСортировки);
		EndIf;

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = ИмяКоллекции + " (" + Table.Count() + ")";
		For Each Элем In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Элем);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьВладельцевОбъекта(ОбъектМД, УзелДЗ)
	вЗаполнитьСвойствоКоллекцияОбъекта(ОбъектМД, УзелДЗ, "Owners");
EndProcedure

&AtServer
Procedure вЗаполнитьГрафыЖурнала(ОбъектМД, УзелДЗ)
	If ОбъектМД.Columns.Count() <> 0 Then
		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Columns";
		For Each Элем In ОбъектМД.Columns Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			СтрДЗ.Name = Элем.Name;
			СтрДЗ.Synonym = Элем.Presentation();
			СтрДЗ.Comment = Элем.Comment;
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьДвиженияОбъекта(ОбъектМД, УзелДЗ)
	If ОбъектМД.RegisterRecords.Count() <> 0 Then

		Table = вСформироватьТаблицуСвойств();
		For Each Элем In ОбъектМД.RegisterRecords Do
			Стр = Table.Add();
			Стр.Name = Элем.Name;
			Стр.Synonym = Элем.Presentation();
			Стр.Comment = Элем.Comment;
			Стр.StringType = Элем.FullName();
		EndDo;
		Table.Sort("StringType");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "RegisterRecords (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьИсточникиСобытия(ОбъектМД, УзелДЗ)
	МассивТипов = ОбъектМД.Src.Types();
	If МассивТипов.Count() <> 0 Then

		Table = вСформироватьТаблицуСвойств();
		For Each Type In МассивТипов Do
			Элем = Metadata.FindByType(Type);

			Стр = Table.Add();
			Стр.Name = Элем.Name;
			Стр.Synonym = Элем.Presentation();
			Стр.Comment = Элем.Comment;
			Стр.StringType = Элем.FullName();
		EndDo;
		Table.Sort("StringType");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Sources (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьПараметрыКоманды(ОбъектМД, УзелДЗ)
	МассивТипов = ОбъектМД.CommandParameterType.Types();
	If МассивТипов.Count() <> 0 Then

		Table = вСформироватьТаблицуСвойств();
		For Each Type In МассивТипов Do
			Элем = Metadata.FindByType(Type);

			Стр = Table.Add();
			Стр.Name = Элем.Name;
			Стр.Synonym = Элем.Presentation();
			Стр.Comment = Элем.Comment;
			Стр.StringType = Элем.FullName();
		EndDo;
		Table.Sort("StringType");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Parameters команды (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьРегистраторовОбъекта(ОбъектМД, УзелДЗ)
	ТабРезультат = вПолучитьТаблицуРегистраторов(ОбъектМД.FullName());
	If ТабРезультат.Count() <> 0 Then
		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Регистраторы (" + ТабРезультат.Count() + ")";
		For Each Элем In ТабРезультат Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Элем);
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ)
	If _ShowEventSubscriptions Then
		ТабРезультат = вПолучитьТаблицуПодписок(ОбъектМД.FullName());
		If ТабРезультат.Count() <> 0 Then
			РазделДЗ = УзелДЗ.GetItems().Add();
			РазделДЗ.Name = "EventSubscriptions (" + ТабРезультат.Count() + ")";
			For Each Элем In ТабРезультат Do
				СтрДЗ = РазделДЗ.GetItems().Add();
				FillPropertyValues(СтрДЗ, Элем);
				СтрДЗ.StringType = "ПодпискаНаСобытие." + Элем.Name;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ)
	If _ShowJbjectsSubsytems Then
		ТабРезультат = вПолучитьТаблицуПодсистем(ОбъектМД.FullName());
		If ТабРезультат.Count() <> 0 Then
			РазделДЗ = УзелДЗ.GetItems().Add();
			РазделДЗ.Name = "Subsystems (" + ТабРезультат.Count() + ")";
			For Each Элем In ТабРезультат Do
				СтрДЗ = РазделДЗ.GetItems().Add();
				FillPropertyValues(СтрДЗ, Элем);
				СтрДЗ.StringType = Элем.FullName;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ)
	If _ShowCommonObjectCommands Then
		ТабРезультат = вПолучитьТаблицуОбщихКоманд(ОбъектМД.FullName());
		If ТабРезультат.Count() <> 0 Then
			РазделДЗ = УзелДЗ.GetItems().Add();
			РазделДЗ.Name = "CommonCommands (" + ТабРезультат.Count() + ")";
			For Each Элем In ТабРезультат Do
				СтрДЗ = РазделДЗ.GetItems().Add();
				FillPropertyValues(СтрДЗ, Элем);
				СтрДЗ.StringType = "ОбщаяКоманда." + Элем.Name;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ)
	If _ShowExternalObjectCommands Then
		ТабРезультат = вПолучитьТаблицуЧужихКоманд(ОбъектМД.FullName());
		If ТабРезультат.Count() <> 0 Then
			РазделДЗ = УзелДЗ.GetItems().Add();
			РазделДЗ.Name = "ЧужиеКоманды (" + ТабРезультат.Count() + ")";
			For Each Элем In ТабРезультат Do
				СтрДЗ = РазделДЗ.GetItems().Add();
				FillPropertyValues(СтрДЗ, Элем);
				СтрДЗ.StringType = Элем.Name;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ)
	If ОбъектМД.StandardAttributes.Count() <> 0 Then
		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "StandardAttributes";
		For Each Элем In ОбъектМД.StandardAttributes Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			СтрДЗ.Name = Элем.Name;
			СтрДЗ.Synonym = Элем.Presentation();
			СтрДЗ.Comment = Элем.Comment;
			//СтрДЗ.StringType = Элем.FullName();
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьСпецСвойствоОбъекта(ОбъектМД, УзелДЗ, PropertyName)
	If ОбъектМД[PropertyName].Count() <> 0 Then
		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = PropertyName;
		For Each Элем In ОбъектМД[PropertyName] Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			СтрДЗ.Name = Элем.Name;
			СтрДЗ.Synonym = Элем.Presentation();
			СтрДЗ.Comment = Элем.Comment;
			СтрДЗ.StringType = Элем.FullName();
		EndDo;
	EndIf;
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваКонфигурации()
	ОбъектМД = Metadata;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = ОбъектМД.FullName();

	ПереченьСвойств = "
					  |Copyright, ConfigurationInformationAddress, VendorInformationAddress, UpdateCatalogAddress,
					  |ScriptVariant, Version, IncludeHelpInContents,
					  |UseOrdinaryFormInManagedApplication, UseManagedFormInOrdinaryApplication,
					  |DefaultReportVariantForm, DefaultConstantsForm, DefaultDynamicListSettingsForm, DefaultReportSettingsForm, DefaultReportForm, DefaultSearchForm,
					  |DefaultInterface, DefaultRunMode, DefaultLanguage,
					  |ObjectAutonumerationMode, ModalityUseMode, SynchronousPlatformExtensionAndAddInCallUseMode,
					  |MainClientApplicationWindowMode, CompatibilityMode, InterfaceCompatibilityMode, DataLockControlMode";

	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваСправочника(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = Catalogs[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Autonumbering, Hierarchical, HierarchyType, FoldersOnTop, CodeType, CodeLength, DescriptionLength, CheckUnique, CodeSeries, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьВладельцевОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПредопределенныеЭлементыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваДокумента(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = Documents[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Autonumbering, NumberLength, RealTimePosting, Posting, CheckUnique, NumberPeriodicity, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьДвиженияОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваЖурналаДокументов(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьГрафыЖурнала(ОбъектМД, УзелДЗ);
	вЗаполнитьСвойствоКоллекцияОбъекта(ОбъектМД, УзелДЗ, "RegisteredDocuments");
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПВХ(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = ChartsOfCharacteristicTypes[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Autonumbering, Hierarchical, FoldersOnTop, CodeLength, DescriptionLength, CheckUnique, CodeSeries, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТипыЗначенийХарактеристик(ОбъектМД, УзелДЗ);
	вЗаполнитьПредопределенныеЭлементыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПВР(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = ChartsOfCalculationTypes[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "CodeLength, DescriptionLength, CodeType, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПредопределенныеЭлементыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПланаСчетов(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = ChartsOfAccounts[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "AutoOrderByCode, CodeLength, DescriptionLength, OrderLength, CheckUnique, CodeMask, CodeSeries, DataLockFields, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьСпецСвойствоОбъекта(ОбъектМД, УзелДЗ, "AccountingFlags");
	вЗаполнитьСпецСвойствоОбъекта(ОбъектМД, УзелДЗ, "ExtDimensionAccountingFlags");
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПредопределенныеЭлементыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваРегистраСведений(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "InformationRegisterPeriodicity, WriteMode, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Dimensions", False);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Resources", True);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Attributes", True);
	вЗаполнитьРегистраторовОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваРегистраНакопления(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "RegisterType, EnableTotalsSplitting, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Dimensions", False);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Resources", True);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Attributes", True);
	вЗаполнитьРегистраторовОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваРегистраБухгалтерии(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Correspondence, ChartOfAccounts, EnableTotalsSplitting, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Dimensions", False);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Resources", True);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Attributes", True);
	вЗаполнитьРегистраторовОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваРегистраРасчета(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "BasePeriod, ActionPeriod, Periodicity, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Dimensions", False);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Resources", True);
	вЗаполнитьГруппуСвойствОбъекта(ОбъектМД, УзелДЗ, "Attributes", True);
	вЗаполнитьРегистраторовОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваБизнесПроцесса(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = BusinessProcesses[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Autonumbering, NumberLength, Task, NumberType, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваЗадачи(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = Tasks[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Autonumbering, Addressing, NumberLength, DescriptionLength, CheckUnique, NumberType, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПланаОбмена(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	_ПустаяСсылкаНаОбъект = ExchangePlans[ОбъектМД.Name].EmptyRef();

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "CodeLength, DescriptionLength, CodeAllowedLength, DataLockControlMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСтандартныеРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьРеквизитыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьТабличныеЧастиОбъекта(ОбъектМД, УзелДЗ);

	If ОбъектМД.Content.Count() <> 0 Then
		СтрукТипы = вСформироватьСтруктуруТипов();

		Table = вСформироватьТаблицуСвойств();
		For Each Элем In ОбъектМД.Content Do
			Стр = Table.Add();
			//Стр.Name = Элем.Metadata.Name;
			//Стр.Name = Элем.Metadata.Name + " (" + Элем.AutoRecord + ")";
			Стр.Name = "AutoRecord: " + Элем.AutoRecord;
			Стр.Synonym = Элем.Metadata.Presentation();
			Стр.Comment = Элем.Metadata.Comment;
			Стр.StringType = Элем.Metadata.FullName();
		EndDo;
		Table.Sort("StringType");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Content (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;

	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПеречисления(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	For Each Элем In ОбъектМД.EnumValues Do
		СтрДЗ = УзелДЗ.GetItems().Add();
		СтрДЗ.Name = Элем.Name;
		СтрДЗ.Synonym = Элем.Presentation();
		СтрДЗ.Comment = Элем.Comment;
	EndDo;

	вЗаполнитьКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваОбщегоМодуля(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "ExternalConnection, ServerCall, Global, ClientOrdinaryApplication, ClientManagedApplication, ReturnValuesReuse, Privileged, Server";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваКонстанты(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	МассивТипов = ОбъектМД.Type.Types();
	If МассивТипов.Count() <> 0 Then
		СтрукТипы = вСформироватьСтруктуруТипов();

		Table = вСформироватьТаблицуСвойств();
		For Each Элем In МассивТипов Do
			Стр = Table.Add();
			Стр.Name = вИмяТипаСтрокой(СтрукТипы, Элем, ОбъектМД.Type);
			Стр.Synonym = Элем;
			Стр.StringType = Стр.Name;
		EndDo;
		Table.Sort("Name");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Types (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;

	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
	
	// проверка прав
	If Not AccessRight("Read", ОбъектМД) Then
		Return;
	EndIf;

	Items.ValuePage.Visible = True;
	Items._ConstantValue.TypeRestriction = ОбъектМД.Type;
	Items._TextConstantValue.ReadOnly = Not ОбъектМД.Type.ContainsType(Type("String"));
	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;

	пСтрук = вПрочитатьКонстанту(_FullName);
	If пСтрук.Cancel Then
		_TypeOfConstantValue = пСтрук.ПричинаОтказа;
	Else
		_ConstantValue = пСтрук.Value;
		_TypeOfConstantValue = пСтрук.ValueType;
		If TypeOf(пСтрук.Value) = Type("String") Then
			_TextConstantValue = пСтрук.Value;
		Else
			_TextConstantValue = пСтрук.Text;
		EndIf;
	EndIf;

	If пСтрук.ReadOnly Then
		Items._TextConstantValue.ReadOnly = True;
		Items._ConstantValue.ReadOnly = True;
		Items._RecordConstant.Enabled = False;
	EndIf;

	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПараметрСеанса(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	МассивТипов = ОбъектМД.Type.Types();
	If МассивТипов.Count() <> 0 Then
		СтрукТипы = вСформироватьСтруктуруТипов();

		Table = вСформироватьТаблицуСвойств();
		For Each Элем In МассивТипов Do
			Стр = Table.Add();
			Стр.Name = вИмяТипаСтрокой(СтрукТипы, Элем, ОбъектМД.Type);
			Стр.Synonym = Элем;
			Стр.StringType = Стр.Name;
		EndDo;
		Table.Sort("Name");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Types (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;

	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
	
	// проверка прав
	If Not AccessRight("Receive", ОбъектМД) Then
		Return;
	EndIf;

	Items.ValuePage.Visible = True;
	Items._ConstantValue.TypeRestriction = ОбъектМД.Type;
	Items._TextConstantValue.ReadOnly = Not ОбъектМД.Type.ContainsType(Type("String"));
	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;

	пСтрук = вПрочитатьКонстанту(_FullName);
	If пСтрук.Cancel Then
		_TypeOfConstantValue = пСтрук.ПричинаОтказа;
	Else
		_ConstantValue = пСтрук.Value;
		_TypeOfConstantValue = пСтрук.ValueType;
		If TypeOf(пСтрук.Value) = Type("String") Then
			_TextConstantValue = пСтрук.Value;
		Else
			_TextConstantValue = пСтрук.Text;
		EndIf;
	EndIf;

	If пСтрук.ReadOnly Then
		Items._TextConstantValue.ReadOnly = True;
		Items._ConstantValue.ReadOnly = True;
		Items._RecordConstant.Enabled = False;
	EndIf;

	Items._UseTextWhenWritingConstants.ReadOnly = Items._TextConstantValue.ReadOnly;

	Items._ConstantValue.Title = "Value параметра";
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваОбщейКоманды(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Group, ModifiesData, ShowInChart, ToolTip, ParameterUsageMode";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьПараметрыКоманды(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПодпискиНаСобытие(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "Handler, Event";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьИсточникиСобытия(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваПодсистемы(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	ПереченьСвойств = "IncludeInCommandInterface, Explanation";
	вЗаполнитьСвойстваОбъекта(ОбъектМД, УзелДЗ, ПереченьСвойств);
	вЗаполнитьСвойствоКоллекцияОбъекта(ОбъектМД, УзелДЗ, "Subsystems");
	вЗаполнитьСвойствоКоллекцияОбъекта(ОбъектМД, УзелДЗ, "Content", True, "StringType");
EndProcedure

&AtServer
Procedure вЗаполнитьСвойстваОпределяемогоТипа(FullName)
	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return;
	EndIf;

	УзелДЗ = PropertyTree.GetItems().Add();
	УзелДЗ.Name = ОбъектМД.Name;
	УзелДЗ.Synonym = ОбъектМД.Presentation();
	УзелДЗ.Comment = ОбъектМД.Comment;
	УзелДЗ.StringType = FullName;

	МассивТипов = ОбъектМД.Type.Types();
	If МассивТипов.Count() <> 0 Then
		СтрукТипы = вСформироватьСтруктуруТипов();

		Table = вСформироватьТаблицуСвойств();
		For Each Элем In МассивТипов Do
			Стр = Table.Add();
			Стр.Name = вИмяТипаСтрокой(СтрукТипы, Элем, ОбъектМД.Type);
			Стр.Synonym = Элем;
			Стр.StringType = Стр.Name;
		EndDo;
		Table.Sort("Name");

		РазделДЗ = УзелДЗ.GetItems().Add();
		РазделДЗ.Name = "Types (" + Table.Count() + ")";
		For Each Стр In Table Do
			СтрДЗ = РазделДЗ.GetItems().Add();
			FillPropertyValues(СтрДЗ, Стр);
		EndDo;
	EndIf;

	вЗаполнитьОбщиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьЧужиеКомандыОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодпискиОбъекта(ОбъектМД, УзелДЗ);
	вЗаполнитьПодсистемыОбъекта(ОбъектМД, УзелДЗ);
EndProcedure

&AtServer
Procedure вЗаполнитьСраницуУправленияИтогами(FullName)
	Try
		пСтрук = вПолучитьСвойстваРегистраДляУправленияИтогами(FullName);
	Except
		Return;
	EndTry;

	If Not пСтрук.ЕстьДанные Then
		Return;
	EndIf;

	Items.ManagingTotalsPage.Visible = True;

	_AggregateMode = пСтрук.РежимАгрегатов;
	_UseAggregates = пСтрук.ИспользованиеАгрегатов;
	_UseTotals = пСтрук.ИспользованиеИтогов;
	_UseCurrentTotals = пСтрук.ИспользованиеТекущихИтогов;
	_DividingTotalsMode = пСтрук.РежимРазделенияИтогов;
	_MinimumPeriodOfCalculatedTotals = пСтрук.МинимальныйПериодРассчитанныхИтогов;
	_MaximumPeriodOfCalculatedTotals = пСтрук.МаксимальныйПериодРассчитанныхИтогов;

	Items._AggregateMode.Visible = Not пСтрук.ЭтоРегистрБУ;
	Items._AggregateMode.Enabled = пСтрук.ЕстьРежимАгрегатов;
	Items._UseAggregates.Visible = Not пСтрук.ЭтоРегистрБУ;
	Items._UseAggregates.Enabled = пСтрук.ЕстьРежимАгрегатов And _AggregateMode;

	Items._UseTotals.Enabled = Not _AggregateMode;
	Items._UseCurrentTotals.Enabled = пСтрук.ЕстьТекущиеИтоги And Not _AggregateMode;

	Items._RecalculateTotals.Enabled = Not _AggregateMode;
	Items._RecalculateCurrentTotals.Enabled = пСтрук.ЕстьТекущиеИтоги And Not _AggregateMode;

	Items.RecalculateTotalsForPeriodGroup.Enabled = Not _AggregateMode;
	Items.CalculatedTotalsGroup.Enabled = Not пСтрук.ОборотныйРегистр And Not _AggregateMode;

EndProcedure

&AtServerNoContext
Function вПолучитьСвойстваРегистраДляУправленияИтогами(FullName)
	пСтрук = New Structure("ЕстьДанные, ЭтоРегистрБУ, ОборотныйРегистр", False, False, False);

	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return пСтрук;
	EndIf;

	пСтрук.ЕстьДанные = True;
	пСтрук.Insert("Name", ОбъектМД.Name);

	пПустаяДата = '00010101';
	пСтрук.Insert("Дата1", пПустаяДата);
	пСтрук.Insert("Дата2", пПустаяДата);

	If Metadata.AccountingRegisters.Contains(ОбъектМД) Then
		пСтрук.ЭтоРегистрБУ = True;
		пСтрук.Insert("ЕстьПериодИтогов", True);
		пСтрук.Insert("ЕстьРежимАгрегатов", False);
		пСтрук.Insert("ЕстьТекущиеИтоги", True);
		пМенеджер = AccountingRegisters[пСтрук.Name];
	Else
		пСтрук.ОборотныйРегистр = (ОбъектМД.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Turnovers);
		пСтрук.Insert("ЕстьПериодИтогов", Not пСтрук.ОборотныйРегистр);
		пСтрук.Insert("ЕстьРежимАгрегатов", пСтрук.ОборотныйРегистр);
		пСтрук.Insert("ЕстьТекущиеИтоги", Not пСтрук.ОборотныйРегистр);
		пМенеджер = AccumulationRegisters[пСтрук.Name];
	EndIf;

	If пСтрук.ЕстьПериодИтогов Then
		пСтрук.Insert("Дата1", пМенеджер.GetMinTotalsPeriod());
		пСтрук.Insert("Дата2", пМенеджер.GetMaxTotalsPeriod());
	EndIf;

	пСтрук.Insert("РежимАгрегатов", ?(пСтрук.ЕстьРежимАгрегатов, пМенеджер.GetAggregatesMode(), False));
	пСтрук.Insert("ИспользованиеАгрегатов", ?(пСтрук.ЕстьРежимАгрегатов, пМенеджер.GetAggregatesUsing(),
		False));
	пСтрук.Insert("ИспользованиеТекущихИтогов", ?(пСтрук.ЕстьТекущиеИтоги,
		пМенеджер.GetPresentTotalsUsing(), False));
	пСтрук.Insert("ИспользованиеИтогов", пМенеджер.GetTotalsUsing());
	пСтрук.Insert("РежимРазделенияИтогов", пМенеджер.GetTotalsSplittingMode());
	пСтрук.Insert("МинимальныйПериодРассчитанныхИтогов", ?(пСтрук.ОборотныйРегистр, пПустаяДата,
		пМенеджер.GetMinTotalsPeriod()));
	пСтрук.Insert("МаксимальныйПериодРассчитанныхИтогов", ?(пСтрук.ОборотныйРегистр, пПустаяДата,
		пМенеджер.GetMaxTotalsPeriod()));

	Return пСтрук;
EndFunction



// структура хранения

&AtClient
Procedure _ПоказыватьСтруктуруХраненияВТерминах1СПриИзменении(Item)
	_SXIndexes.Clear();
	_SXFielsd.Clear();
	_SXIndexFields.Clear();
	_SXTable.Clear();

	вЗаполнитьРазделСтруктураХранения();
EndProcedure

&AtServer
Procedure вЗаполнитьРазделСтруктураХранения(Val ДанныеСХ = Undefined)
	If ДанныеСХ = Undefined Then
		ОбъектМД = Metadata.FindByFullName(_FullName);
		If ОбъектМД <> Undefined Then
			ДанныеСХ = GetDBStorageStructureInfo(вЗначениеВМассив(ОбъектМД),
				Not _ShowStorageStructureIn1CTerms);
			If ДанныеСХ = Undefined Or ДанныеСХ.Count() = 0 Then
				Return;
			EndIf;
		Else
			Return;
		EndIf;
	EndIf;

	НомерХ = 0;
	НомерХХ = 0;

	For Each Стр In ДанныеСХ Do
		НомерХ = НомерХ + 1;
		TableNumber = "(" + НомерХ + ")";

		НС = _SXTable.Add();
		FillPropertyValues(НС, Стр);
		НС.TableNumber = TableNumber;
		If IsBlankString(НС.TableName) Then
			НС.TableName = _FullName + "(" + Стр.Purpose + ")";
		EndIf;

		For Each СтрХ In Стр.Fields Do
			НС = _SXFielsd.Add();
			FillPropertyValues(НС, СтрХ);
			НС.StorageTableName = Стр.StorageTableName;
			НС.TableNumber = TableNumber;
		EndDo;
		For Each СтрХ In Стр.Indexes Do
			НомерХХ = НомерХХ + 1;
			НомерИндекса = "(" + НомерХХ + ")";

			НС = _SXIndexes.Add();
			FillPropertyValues(НС, СтрХ);
			НС.StorageTableName = Стр.StorageTableName;
			НС.TableNumber = TableNumber;
			НС.НомерИндекса = НомерИндекса;

			For Each СтрХХ In СтрХ.Fields Do
				НС = _SXIndexFields.Add();
				FillPropertyValues(НС, СтрХХ);
				НС.НомерИндекса = НомерИндекса;
			EndDo;
		EndDo;

	EndDo;
EndProcedure

&AtClient
Procedure _СХТаблицыПриАктивизацииСтроки(Item)
	ТекДанные = Item.CurrentData;
	If ТекДанные <> Undefined Then
		Items._SXFielsd.RowFilter = New FixedStructure("TableNumber", ТекДанные.TableNumber);
		Items._SXIndexes.RowFilter = New FixedStructure("TableNumber", ТекДанные.TableNumber);
	EndIf;
EndProcedure

&AtClient
Procedure _СХИндексыПриАктивизацииСтроки(Item)
	ТекДанные = Item.CurrentData;
	If ТекДанные <> Undefined Then
		Items._SXIndexFields.RowFilter = New FixedStructure("НомерИндекса", ТекДанные.НомерИндекса);
	EndIf;
EndProcedure
&AtClient
Procedure _UpdateNumberOfObjects(Command)
	If Not вЕстьПраваАдминистратора() Then
		ShowMessageBox( , "None прав на выполнение операции!", 20);
		Return;
	EndIf;

	пТекст = ?(_FullName = "Конфигурация", "Нумерация всех объектов будет обновлена. Continue?",
		"Нумерация обекта будет обновлена. Continue?");
	ShowQueryBox(New NotifyDescription("вОбновитьНумерациюОбъектовОтвет", ThisForm), пТекст,
		QuestionDialogMode.YesNoCancel, 20);
EndProcedure

&AtClient
Procedure вОбновитьНумерациюОбъектовОтвет(РезультатВопроса, ДопПарам = Undefined) Export
	If РезультатВопроса = DialogReturnCode.Yes Then
		вОбновитьНумерациюОбъектов(_FullName);
	EndIf;
EndProcedure

&AtServerNoContext
Function вОбновитьНумерациюОбъектов(Val FullName)
	If FullName = "Конфигурация" Then
		Try
			RefreshObjectsNumbering();
		Except
			Message(BriefErrorDescription(ErrorInfo()));
		EndTry;

	ElsIf StrFind(FullName, ".") <> 0 Then
		ОбъектМД = Metadata.FindByFullName(FullName);

		If ОбъектМД <> Undefined Then
			Try
				RefreshObjectsNumbering(ОбъектМД);
			Except
				Message(BriefErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
	EndIf;

	Return True;
EndFunction


// управление итогами
&AtClient
Procedure _UpdateTotalsManagement(Command)
	вЗаполнитьСраницуУправленияИтогами(_FullName);
EndProcedure

&AtClient
Procedure _RecalculateTotals(Command)
	вПоказатьВопрос("вОбработатьКомандуУправленияИтогами", "Будет выполнен полный пересчет итогов. Continue?",
		"RecalcTotals");
EndProcedure

&AtClient
Procedure _RecalculateCurrentTotals(Command)
	вПоказатьВопрос("вОбработатьКомандуУправленияИтогами", "Текущие итоги будут пересчитаны. Continue?",
		"RecalcPresentTotals");
EndProcedure

&AtClient
Procedure _RecalculateTotalsForThePeriod(Command)
	вПоказатьВопрос("вОбработатьКомандуУправленияИтогами", "Будут пересчитаны итоги за заданный период. Continue?",
		"RecalcTotalsForPeriod");
EndProcedure

&AtClient
Procedure _InstallPriodOfCalculatedTotals(Command)
	пИмя = ThisForm.CurrentItem.Name;
	If Right(пИмя, 1) = "1" Then
		вПоказатьВопрос("вОбработатьКомандуУправленияИтогами",
			"Будет изменен минимальный период рассчитанных итогов. Continue?",
			"SetMinTotalsPeriod");
	ElsIf Right(пИмя, 1) = "2" Then
		вПоказатьВопрос("вОбработатьКомандуУправленияИтогами",
			"Будет изменен максимальный период рассчитанных итогов. Continue?",
			"SetMaxTotalsPeriod");
	EndIf;
EndProcedure

&AtClient
Procedure вОбработатьКомандуУправленияИтогами(РезультатВопроса, CommandName) Export
	If РезультатВопроса = DialogReturnCode.Yes Then
		пСтрук = вПолучитьНовыеНастройкиУправленияИтогами();
		пСтрук.Insert("CommandName", CommandName);

		пРезультат = вВыполнитКомандуУправленияИтогами(_FullName, CommandName, пСтрук);
		_ОбновитьУправлениеИтогами(Undefined);
	EndIf;
EndProcedure

&AtClient
Function вПолучитьНовыеНастройкиУправленияИтогами()
	пСтрук = New Structure;
	пСтрук.Insert("ПериодПересчетаИтогов", _PeriodRecalculationTotals);
	пСтрук.Insert("МинимальныйПериодРассчитанныхИтогов", _MinimumPeriodOfCalculatedTotals);
	пСтрук.Insert("МаксимальныйПериодРассчитанныхИтогов", _MaximumPeriodOfCalculatedTotals);

	Return пСтрук;
EndFunction

&AtClient
Procedure СвойствоРегистраПриИзменении(Item)
	вПоказатьВопрос("вОбработатьИзменениеСвойстваРегистра", "Property регистра будет изменено. Continue?",
		Item.Name);
EndProcedure

&AtClient
Procedure вОбработатьИзменениеСвойстваРегистра(РезультатВопроса, PropertyName) Export
	If РезультатВопроса = DialogReturnCode.Yes Then
		вИзменитьСвойствоРегистра(_FullName, Mid(PropertyName, 2), ThisForm[PropertyName]);
		_ОбновитьУправлениеИтогами(Undefined);
	Else
		ThisForm[PropertyName] = Not ThisForm[PropertyName];
	EndIf;
EndProcedure

&AtServerNoContext
Function вВыполнитКомандуУправленияИтогами(Val FullName, Val CommandName, Val пСтрукНастройки)
	If Not вЕстьПраваАдминистратора() Then
		Message("None прав на выполнение операции!");
		Return False;
	EndIf;

	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return False;
	EndIf;

	If Metadata.AccountingRegisters.Contains(ОбъектМД) Then
		пМенеджер = AccountingRegisters[ОбъектМД.Name];
	Else
		пМенеджер = AccumulationRegisters[ОбъектМД.Name];
	EndIf;

	Try
		If CommandName = "RecalcTotals" Then
			пМенеджер.RecalcTotals();
		ElsIf CommandName = "RecalcPresentTotals" Then
			пМенеджер.RecalcPresentTotals();
		ElsIf CommandName = "RecalcTotalsForPeriod" Then
			Дата1 = пСтрукНастройки.ПериодПересчетаИтогов.ValidFrom;
			Дата2 = пСтрукНастройки.ПериодПересчетаИтогов.ValidTo;
			пМенеджер.RecalcTotalsForPeriod(Дата1, Дата2);
		ElsIf CommandName = "SetMinTotalsPeriod" Then
			пМенеджер.SetMinTotalsPeriod(пСтрукНастройки.МинимальныйПериодРассчитанныхИтогов);
		ElsIf CommandName = "SetMaxTotalsPeriod" Then
			пМенеджер.SetMaxTotalsPeriod(
				пСтрукНастройки.МаксимальныйПериодРассчитанныхИтогов);
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
Function вИзменитьСвойствоРегистра(Val FullName, Val PropertyName, Val пЗначение)
	If Not вЕстьПраваАдминистратора() Then
		Message("None прав на выполнение операции!");
		Return False;
	EndIf;

	ОбъектМД = Metadata.FindByFullName(FullName);
	If ОбъектМД = Undefined Then
		Return False;
	EndIf;

	If Metadata.AccountingRegisters.Contains(ОбъектМД) Then
		пМенеджер = AccountingRegisters[ОбъектМД.Name];
	Else
		пМенеджер = AccumulationRegisters[ОбъектМД.Name];
	EndIf;

	Try
		If PropertyName = "РежимАгрегатов" Then
			пМенеджер.SetAggregatesMode(пЗначение);
		ElsIf PropertyName = "ИспользованиеАгрегатов" Then
			пМенеджер.SetAggregatesUsing(пЗначение);
		ElsIf PropertyName = "ИспользованиеИтогов" Then
			пМенеджер.SetTotalsUsing(пЗначение);
		ElsIf PropertyName = "ИспользованиеТекущихИтогов" Then
			пМенеджер.SetPresentTotalsUsing(пЗначение);
		ElsIf PropertyName = "РежимРазделенияИтогов" Then
			пМенеджер.SetTotalsSplittingMode(пЗначение);
		Else
			Return False;
		EndIf;
	Except
		Message(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;

	Return True;
EndFunction


// права доступа
&AtClient
Procedure _ДоступныеОбъектыВыбор(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	_ОткрытьОбъектПравДоступа(Undefined);
EndProcedure

&AtClient
Procedure _FullInAccessRights(Command)
	пЭтоРоль = (StrFind(_FullName, "Role.") = 1);

	UsersWithAccessTable.Clear();

	If пЭтоРоль Then
		_AvailableObjects.Clear();

		If IsBlankString(_AccessRightToObject) Then
			Return;
		EndIf;

		пСтрукРезультат = вПолучитьДоступныеОбъектыДляРоли(_FullName, _AccessRightToObject,
			_AdditionalVars.DescriptionOfAccessRights);
		If пСтрукРезультат.ЕстьДанные Then
			For Each Элем In пСтрукРезультат.AvailableObjects Do
				FillPropertyValues(_AvailableObjects.Add(), Элем);
			EndDo;
			_AvailableObjects.Sort("Kind, FullName");

			For Each Элем In пСтрукРезультат.Users Do
				FillPropertyValues(UsersWithAccessTable.Add(), Элем);
			EndDo;
			UsersWithAccessTable.Sort("Name");
		EndIf;

	Else
		RolesWithAccessTable.Clear();

		If IsBlankString(_AccessRightToObject) Then
			Return;
		EndIf;

		пСтрукРезультат = вПолучитьПраваДоступаКОбъекту(_AccessRightToObject, _FullName);
		If пСтрукРезультат.ЕстьДанные Then
			For Each Элем In пСтрукРезультат.Roles Do
				FillPropertyValues(RolesWithAccessTable.Add(), Элем);
			EndDo;

			For Each Элем In пСтрукРезультат.Users Do
				FillPropertyValues(UsersWithAccessTable.Add(), Элем);
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _ПравоДоступаКОбъектуПриИзменении(Item)
	_ЗаполнитьПраваДоступа(Undefined);
EndProcedure

&AtClient
Procedure ТабРолиСДоступомВыбор(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	_ОткрытьОбъектПравДоступа(Undefined);
EndProcedure

&AtClient
Procedure ТабПользователиСДоступомВыбор(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	_ОткрытьОбъектПравДоступа(Undefined);
EndProcedure

&AtClient
Procedure _OpenAccessRightsObject(Command)
	пИмяСтраницы = Items.AccessRightToObject.CurrentPage.Name;

	If пИмяСтраницы = "AccessRightToObject_Role" Then
		ТекДанные = Items.RolesWithAccessTable.CurrentData;
		If ТекДанные <> Undefined Then
			вПоказатьСвойстваОбъекта("Role." + ТекДанные.Name);
		EndIf;

	ElsIf пИмяСтраницы = "AccessRightToObject_Users" Then
		ТекДанные = Items.UsersWithAccessTable.CurrentData;
		If ТекДанные <> Undefined Then
			пИдентификаторПользователя = вПолучитьИдентификаторПользователя(ТекДанные.Name);

			If Not IsBlankString(пИдентификаторПользователя) Then
				пСтрук = New Structure("РежимРаботы, ИдентификаторПользователяИБ", 0, пИдентификаторПользователя);
				OpenForm(PathToForms + "UserForm", пСтрук, , , , , ,
					FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
		EndIf;

	ElsIf пИмяСтраницы = "_AccessRightForRole" Then
		ТекДанные = Items._AvailableObjects.CurrentData;
		If ТекДанные <> Undefined And Not IsBlankString(ТекДанные.FullName) Then
			вПоказатьСвойстваОбъекта(ТекДанные.FullName);
		EndIf;

	EndIf;
EndProcedure
&AtServerNoContext
Function вПолучитьИдентификаторПользователя(Val Name)
	пПользователь = InfoBaseUsers.FindByName(Name);

	Return ?(пПользователь = Undefined, "", String(пПользователь.UUID));
EndFunction

&AtServerNoContext
Function вПолучитьОписаниеОграниченийДляПараметровДоступа()
	пОбъектыСОгрничением = New Map;
	пОбъектыСОгрничением.Insert("ExchangePlan", "Reference");
	пОбъектыСОгрничением.Insert("Catalog", "Reference");
	пОбъектыСОгрничением.Insert("Document", "Reference");
	пОбъектыСОгрничением.Insert("DocumentJournal", "Reference");
	пОбъектыСОгрничением.Insert("ChartOfCharacteristicTypes", "Reference");
	пОбъектыСОгрничением.Insert("ChartOfAccounts", "Reference");
	пОбъектыСОгрничением.Insert("ChartOfCalculationTypes", "Reference");
	пОбъектыСОгрничением.Insert("InformationRegister", Undefined);
	пОбъектыСОгрничением.Insert("AccumulationRegister", "Recorder");
	пОбъектыСОгрничением.Insert("AccountingRegister", "Recorder");
	пОбъектыСОгрничением.Insert("CalculationRegister", "Recorder");
	пОбъектыСОгрничением.Insert("BusinessProcess", "Reference");
	пОбъектыСОгрничением.Insert("Task", "Reference");

	Return пОбъектыСОгрничением;
EndFunction

&AtServerNoContext
Function вПолучитьТаблицуРолиИПользователи()
	__ТабРолиИПользователи = New ValueTable;
	__ТабРолиИПользователи.Columns.Add("ИмяР", New TypeDescription("String"));
	__ТабРолиИПользователи.Columns.Add("ИмяП", New TypeDescription("String"));
	__ТабРолиИПользователи.Columns.Add("ПолноеИмяП", New TypeDescription("String"));

	For Each П In InfoBaseUsers.GetUsers() Do
		For Each Р In П.Roles Do
			НС = __ТабРолиИПользователи.Add();
			НС.ИмяР = Р.Name;
			НС.ИмяП = П.Name;
			НС.ПолноеИмяП = П.FullName;
		EndDo;
	EndDo;

	__ТабРолиИПользователи.Indexes.Add("ИмяР");
	__ТабРолиИПользователи.Indexes.Add("ИмяП");

	Return __ТабРолиИПользователи;
EndFunction

&AtServerNoContext
Function вПолучитьДоступныеОбъектыДляРоли(Val пРоль, Val пПраво, Val DescriptionOfAccessRights)
	пРезультат = New Structure("ЕстьДанные, AvailableObjects, Users", False);

	пРольМД = Metadata.FindByFullName(пРоль);
	If пРоль = Undefined Then
		Return пРезультат;
	EndIf;

	пРезультат.ЕстьДанные = True;
	пРезультат.Insert("AvailableObjects", New Array);
	пРезультат.Insert("Users", New Array);

	For Each П In InfoBaseUsers.GetUsers() Do
		For Each Р In П.Roles Do
			If Р.Name = пРольМД.Name Then
				пСтрук = New Structure("Name, FullName");
				FillPropertyValues(пСтрук, П);
				пРезультат.Users.Add(пСтрук);
			EndIf;
		EndDo;
	EndDo;

	пСтрукОбъектыСОгрничением = New Structure;
	пСтрукОбъектыСОгрничением.Insert("Catalog");
	пСтрукОбъектыСОгрничением.Insert("Document");

	пОбъектыСОгрничением = вПолучитьОписаниеОграниченийДляПараметровДоступа();

	пПоляРезультата = "RestrictionCondition, Kind, Name, Presentation, FullName";

	ТабПользователи = New ValueTable;
	ТабПользователи.Columns.Add("Name", New TypeDescription("String"));
	ТабПользователи.Columns.Add("FullName", New TypeDescription("String"));

	пТабОбъекты = New ValueTable;
	пТабОбъекты.Columns.Add("FullName", New TypeDescription("String"));
	пТабОбъекты.Columns.Add("ОбъектМД", New TypeDescription("ОбъектМетаданных"));

	пСтрук = New Structure("
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

	For Each Элем In пСтрук Do
		For Each ОбъектМД In Metadata[Элем.Key] Do
			НС = пТабОбъекты.Add();
			НС.FullName = ОбъектМД.FullName();
			НС.ОбъектМД = ОбъектМД;

			пСтрук = New Structure("Commands");
			FillPropertyValues(пСтрук, ОбъектМД);

			If пСтрук.Commands <> Undefined Then
				For Each пКоманда In ОбъектМД.Commands Do
					НС = пТабОбъекты.Add();
					НС.FullName = пКоманда.FullName();
					НС.ОбъектМД = пКоманда;
				EndDo;
			EndIf;
		EndDo;
	EndDo;

	For Each Стр In пТабОбъекты Do
		пСтрук = New Structure(пПоляРезультата);

		пПолноеИмя = Стр.ОбъектМД.FullName();
		If StrFind(пПолноеИмя, ".Command.") <> 0 Then
			Поз1 = StrFind(пПолноеИмя, ".", SearchDirection.FromEnd);
			пСтрук.Kind = "ЧужаяКоманда";
			пСтрук.Name = Mid(пПолноеИмя, Поз1 + 1);
		Else
			Поз1 = StrFind(пПолноеИмя, ".");
			пСтрук.Kind = Left(пПолноеИмя, Поз1 - 1);
			пСтрук.Name = Mid(пПолноеИмя, Поз1 + 1);
		EndIf;

		пСписокПрав = DescriptionOfAccessRights[пСтрук.Kind];

		If пСписокПрав = Undefined Then
			Continue;
		ElsIf StrFind(пСписокПрав, пПраво) = 0 Then
			Continue;
		EndIf;

		If AccessRight(пПраво, Стр.ОбъектМД, пРольМД) Then

			пСтрук.FullName = пПолноеИмя;
			пСтрук.Presentation = Стр.ОбъектМД.Presentation();

			пПоле = пОбъектыСОгрничением[пСтрук.Kind];
			If пПоле <> Undefined Then
				пСтрук.RestrictionCondition = AccessParameters(пПраво, Стр.ОбъектМД, пПоле, пРольМД).RestrictionCondition;
			ElsIf пСтрук.Kind = "InformationRegister" And Стр.ОбъектМД.Dimensions.Count() <> 0 Then
				пПоле = Стр.ОбъектМД.Dimensions[0].Name;
				пСтрук.RestrictionCondition = AccessParameters(пПраво, Стр.ОбъектМД, пПоле, пРольМД).RestrictionCondition;
			EndIf;

			пРезультат.AvailableObjects.Add(пСтрук);
		EndIf;
	EndDo;

	Return пРезультат;
EndFunction

&AtServerNoContext
Function вПолучитьПраваДоступаКОбъекту(Val ИмяПрава, Val FullName)
	СтрукРезультат = New Structure("ЕстьДанные, Roles, Users", False);

	If IsBlankString(ИмяПрава) Then
		Return СтрукРезультат;
	EndIf;

	пОбъектыСОгрничением = вПолучитьОписаниеОграниченийДляПараметровДоступа();

	ТабРоли = New ValueTable;
	ТабРоли.Columns.Add("RestrictionCondition", New TypeDescription("Boolean"));
	ТабРоли.Columns.Add("Name", New TypeDescription("String"));
	ТабРоли.Columns.Add("Synonym", New TypeDescription("String"));

	ТабПользователи = New ValueTable;
	ТабПользователи.Columns.Add("Name", New TypeDescription("String"));
	ТабПользователи.Columns.Add("FullName", New TypeDescription("String"));

	If StrFind(FullName, ".Command.") <> 0 Then
		ТипМД = "ЧужаяКоманда";
	Else
		ТипМД = Left(FullName, StrFind(FullName, ".") - 1);
	EndIf;

	If ТипМД <> "User" Then
		ОбъектМД = Metadata.FindByFullName(FullName);

		If ОбъектМД = Undefined Then
			Return СтрукРезультат;
		EndIf;
	EndIf;

	If ТипМД = "InformationRegister" And ОбъектМД.Dimensions.Count() <> 0 Then
		пПоле = ОбъектМД.Dimensions[0].Name;
		пОбъектыСОгрничением[ТипМД] = пПоле;
	EndIf;

	ЭтоОбычныйРежим = True;

	If ЭтоОбычныйРежим And IsBlankString(ИмяПрава) Then
		Return СтрукРезультат;
	EndIf;
	If ЭтоОбычныйРежим Then
		For Each Элем In Metadata.Roles Do
			If AccessRight(ИмяПрава, ОбъектМД, Элем) Then
				НС = ТабРоли.Add();
				FillPropertyValues(НС, Элем);

				пПоле = пОбъектыСОгрничением[ТипМД];
				If пПоле <> Undefined Then
					НС.RestrictionCondition = AccessParameters(ИмяПрава, ОбъектМД, пПоле, Элем).RestrictionCondition;
				EndIf;
			EndIf;
		EndDo;

		ТабРоли.Sort("Name");
	EndIf;

	__ТабРолиИПользователи = вПолучитьТаблицуРолиИПользователи();

	If ЭтоОбычныйРежим Then
		СтрукР = New Structure("ИмяР");
		СтрукП = New Structure("Name");

		For Each Стр In ТабРоли Do
			СтрукР.ИмяР = Стр.Name;
			For Each СтрХ In __ТабРолиИПользователи.FindRows(СтрукР) Do
				СтрукП.Name = СтрХ.ИмяП;
				If ТабПользователи.FindRows(СтрукП).Count() = 0 Then
					НС = ТабПользователи.Add();
					НС.Name = СтрХ.ИмяП;
					НС.FullName = СтрХ.ПолноеИмяП;
				EndIf;
			EndDo;
		EndDo;

		ТабПользователи.Sort("Name");
	EndIf;

	СтрукРезультат.ЕстьДанные = True;
	СтрукРезультат.Roles = New Array;
	СтрукРезультат.Users = New Array;

	For Each Стр In ТабРоли Do
		Струк = New Structure("Name, Synonym, RestrictionCondition");
		FillPropertyValues(Струк, Стр);
		СтрукРезультат.Roles.Add(Струк);
	EndDo;

	For Each Стр In ТабПользователи Do
		Струк = New Structure("Name, FullName");
		FillPropertyValues(Струк, Стр);
		СтрукРезультат.Users.Add(Струк);
	EndDo;

	Return СтрукРезультат;
EndFunction
&AtClient
Procedure _FillInDependentObjects(Command)
	_DependentObjects.GetItems().Clear();
	_WhereFound = "";

	вЗаполнитьЗависимыеОбъекты();

	For Each Элем In _DependentObjects.GetItems() Do
		Items._DependentObjects.Expand(Элем.GetID(), False);
	EndDo;
EndProcedure

&AtServer
Procedure вЗаполнитьЗависимыеОбъекты()

	пОбъектМД = Metadata.FindByFullName(_FullName);
	If пОбъектМД = Undefined Then
		Return;
	EndIf;
	пКорневойУзел = _DependentObjects.GetItems().Add();
	пКорневойУзел.ВидУзла = 1;
	пКорневойУзел.Name = пОбъектМД.Name;
	пКорневойУзел.Presentation = пОбъектМД.Presentation();
	пКорневойУзел.FullName = _FullName;

	Поз = StrFind(_FullName, ".");
	пТипДляПоиска = Type(Left(_FullName, Поз - 1) + "Reference" + Mid(_FullName, Поз));

	пНадоСмотретьВидыСубконтоПС = (Left(_FullName, Поз - 1) = "ChartOfCharacteristicTypes");

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

		For Each ОбъектМД In пРазделМД Do
			пПолноеИмя = ОбъектМД.FullName();
			пГдеНайдено = "";
			пСчетчик = 0;

			If ОбъектМД.Type.Types().Find(пТипДляПоиска) <> Undefined Then
				пПуть = "Object.Type";
				If пСчетчик = 0 Then
					пГдеНайдено = пПуть;
				Else
					пГдеНайдено = пГдеНайдено + "," + пПуть;
				EndIf;
				пСчетчик = пСчетчик + 1;

				пСоотв[пПолноеИмя] = 1;
			EndIf;

			If пСоотв[пПолноеИмя] <> Undefined Then
				НС = пТабРезультат.Add();
				НС.Name = ОбъектМД.Name;
				НС.Presentation = ОбъектМД.Presentation();
				НС.FullName = пПолноеИмя;
				НС.WhereFound = пГдеНайдено;
			EndIf;
		EndDo;

		пКоличество = пТабРезультат.Count();
		If пКоличество <> 0 Then
			пТабРезультат.Sort("Name");

			пУзелРаздела = пКорневойУзел.GetItems().Add();
			пУзелРаздела.Name = пЭлем.Key + " (" + пКоличество + ")";
			пУзелРаздела.ВидУзла = 2;
			пКоллекцияЭлементов = пУзелРаздела.GetItems();

			For Each Стр In пТабРезультат Do
				FillPropertyValues(пКоллекцияЭлементов.Add(), Стр);
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

		For Each ОбъектМД In пРазделМД Do
			пПолноеИмя = ОбъектМД.FullName();
			пГдеНайдено = "";
			пСчетчик = 0;

			If пЭтоРегистр Then
				For Each пОбласть In пСтрукОбласти Do
					For Each пРеквизит In ОбъектМД[пОбласть.Key] Do
						If пРеквизит.Type.Types().Find(пТипДляПоиска) <> Undefined Then
							пПуть = "Object." + пОбласть.Key + "." + пРеквизит.Name;
							If пСчетчик = 0 Then
								пГдеНайдено = пПуть;
							Else
								пГдеНайдено = пГдеНайдено + "," + пПуть;
							EndIf;
							пСчетчик = пСчетчик + 1;

							пСоотв[пПолноеИмя] = 1;
						EndIf;
					EndDo;
				EndDo;

				If пСоотв[пПолноеИмя] <> Undefined Then
					НС = пТабРезультат.Add();
					НС.Name = ОбъектМД.Name;
					НС.Presentation = ОбъектМД.Presentation();
					НС.FullName = пПолноеИмя;
					НС.WhereFound = пГдеНайдено;
				EndIf;

			Else
				For Each пРеквизит In ОбъектМД.Attributes Do
					If пРеквизит.Type.Types().Find(пТипДляПоиска) <> Undefined Then
						If пСчетчик = 0 Then
							пГдеНайдено = "Object.Attributes." + пРеквизит.Name;
						Else
							пГдеНайдено = пГдеНайдено + ",Object.Attributes." + пРеквизит.Name;
						EndIf;
						пСчетчик = пСчетчик + 1;

						пСоотв[пПолноеИмя] = 1;
					EndIf;
				EndDo;

				For Each пТабличнаяЧасть In ОбъектМД.TabularSections Do
					For Each пРеквизит In пТабличнаяЧасть.Attributes Do
						If пРеквизит.Type.Types().Find(пТипДляПоиска) <> Undefined Then
							If пСчетчик = 0 Then
								пГдеНайдено = "Object." + пТабличнаяЧасть.Name + ".Attributes." + пРеквизит.Name;
							Else
								пГдеНайдено = пГдеНайдено + ",Object." + пТабличнаяЧасть.Name + ".Attributes."
									+ пРеквизит.Name;
							EndIf;
							пСчетчик = пСчетчик + 1;

							пСоотв[пПолноеИмя] = 1;
						EndIf;
					EndDo;
				EndDo;

				If пЭтоПланОбмена Then
					If ОбъектМД.Content.Contains(пОбъектМД) Then
						If пСчетчик = 0 Then
							пГдеНайдено = "Object.Content";
						Else
							пГдеНайдено = пГдеНайдено + ",Object.Content";
						EndIf;
						пСчетчик = пСчетчик + 1;

						пСоотв[пПолноеИмя] = 1;
					EndIf;
				EndIf;

				If пЭтоПланСчетов And пНадоСмотретьВидыСубконтоПС Then
					If ОбъектМД.ExtDimensionTypes = пОбъектМД Then
						If пСчетчик = 0 Then
							пГдеНайдено = "Object.ExtDimensionTypes";
						Else
							пГдеНайдено = пГдеНайдено + ",Object.ExtDimensionTypes";
						EndIf;
						пСчетчик = пСчетчик + 1;

						пСоотв[пПолноеИмя] = 1;
					EndIf;
				EndIf;
			EndIf;

			If пСоотв[пПолноеИмя] <> Undefined Then
				НС = пТабРезультат.Add();
				НС.Name = ОбъектМД.Name;
				НС.Presentation = ОбъектМД.Presentation();
				НС.FullName = пПолноеИмя;
				НС.WhereFound = пГдеНайдено;
			EndIf;
		EndDo;

		пКоличество = пТабРезультат.Count();
		If пКоличество <> 0 Then
			пТабРезультат.Sort("Name");

			пУзелРаздела = пКорневойУзел.GetItems().Add();
			пУзелРаздела.Name = пЭлем.Key + " (" + пКоличество + ")";
			пУзелРаздела.ВидУзла = 2;
			пКоллекцияЭлементов = пУзелРаздела.GetItems();

			For Each Стр In пТабРезультат Do
				FillPropertyValues(пКоллекцияЭлементов.Add(), Стр);
			EndDo;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure _ЗависимыеОбъектыПриАктивизацииСтроки(Item)
	AttachIdleHandler("вОбработкаАктивизацииСтрокиЗависимых", 0.1, True);
EndProcedure

&AtClient
Procedure вОбработкаАктивизацииСтрокиЗависимых()
	ТекДанные = Items._DependentObjects.CurrentData;
	If ТекДанные <> Undefined Then
		_WhereFound = StrReplace(ТекДанные.ГдеНайдено, ",", Chars.LF);
	EndIf;
EndProcedure

&AtClient
Procedure _ЗависимыеОбъектыВыбор(Item, SelectedRow, Field, StandardProcessing)
	ТекДанные = Items._DependentObjects.CurrentData;
	If ТекДанные <> Undefined And ТекДанные.ВидУзла = 0 Then
		StandardProcessing = False;
		вПоказатьСвойстваОбъекта(ТекДанные.FullName);
	EndIf;
EndProcedure

&AtClient
Procedure _OpenSubordinateObject(Command)
	ТекДанные = Items._DependentObjects.CurrentData;
	If ТекДанные <> Undefined And ТекДанные.ВидУзла = 0 Then
		вПоказатьСвойстваОбъекта(ТекДанные.FullName);
	EndIf;
EndProcedure
&AtClient
Procedure _ReadConstant(Command)
	пРезультат = вПрочитатьКонстанту(_FullName);
	If Not пРезультат.Cancel Then
		_ConstantValue = пРезультат.Value;
		_TypeOfConstantValue = пРезультат.ValueType;

		If TypeOf(пРезультат.Value) = Type("String") Then
			_TextConstantValue = пРезультат.Value;
		Else
			_TextConstantValue = пРезультат.Text;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure _RecordConstant(Command)
	If вЗаписатьКонстанту() Then
		пВидОбъекта = Left(_FullName, StrFind(_FullName, ".") - 1);

		If пВидОбъекта = "Constant" Then
			ShowMessageBox( , "Value константы изменено!", 20);
		ElsIf пВидОбъекта = "ПараметрСеанса" Then
			ShowMessageBox( , "Value параметра сеанса изменено!", 20);
		EndIf;

		_ПрочитатьКонстанту(Undefined);
	EndIf;
EndProcedure

&AtServer
Function вЗаписатьКонстанту()
	SetPrivilegedMode(True);

	пОбъектМД = Metadata.FindByFullName(_FullName);
	If пОбъектМД = Undefined Then
		Return False;
	EndIf;

	пВидОбъекта = Left(_FullName, StrFind(_FullName, ".") - 1);

	If пВидОбъекта = "Constant" Then
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

	ElsIf пВидОбъекта = "ПараметрСеанса" Then
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
Function вПрочитатьКонстанту(Val FullName)
	SetPrivilegedMode(True);

	пРезультат = New Structure("Cancel, ПричинаОтказа, ReadOnly, Text, Value, ValueType", False, "", False,
		"");

	пОбъектМД = Metadata.FindByFullName(FullName);
	If пОбъектМД = Undefined Then
		пРезультат.Cancel = True;
		пРезультат.ReadOnly = True;
		пРезультат.ПричинаОтказа = "Not удалость найти объект метаданных!";
		Return пРезультат;
	EndIf;

	пВидОбъекта = Left(FullName, StrFind(FullName, ".") - 1);

	If пВидОбъекта = "Constant" Then
		Query = New Query;
		Query.Text = "ВЫБРАТЬ ПЕРВЫЕ 1
					   |	т.Value КАК Value
					   |ИЗ
					   |	" + FullName + " КАК т";

		Try
			Выборка = Query.Execute().StartChoosing();

			пРезультат.Value = ?(Выборка.Next(), Выборка.Value, Undefined);
			пРезультат.ValueType = вИмяТипаСтрокой(вСформироватьСтруктуруТипов(), TypeOf(пРезультат.Value),
				пОбъектМД.Type);
		Except
			Message(BriefErrorDescription(ErrorInfo()));
			пРезультат.Cancel = True;
			пРезультат.ПричинаОтказа = ErrorDescription();
			Return пРезультат;
		EndTry;

	ElsIf пВидОбъекта = "ПараметрСеанса" Then
		Try
			пРезультат.Value = SessionParameters[пОбъектМД.Name];
			пРезультат.ValueType = вИмяТипаСтрокой(вСформироватьСтруктуруТипов(), TypeOf(пРезультат.Value),
				пОбъектМД.Type);
		Except
			пРезультат.Cancel = True;
			пРезультат.ПричинаОтказа = "значение не установлено!";
		EndTry;

	Else
		пРезультат.Cancel = True;
		пРезультат.ReadOnly = True;
		пРезультат.ПричинаОтказа = пВидОбъекта + " не поддерживается!";
		Return пРезультат;
	EndIf;

	пНеПоддерживаемыеТипы = New Array;
	пНеПоддерживаемыеТипы.Add(Type("ValueStorage"));
	пНеПоддерживаемыеТипы.Add(Type("BinaryData"));
	пНеПоддерживаемыеТипы.Add(Type("TypeDescription"));
	пНеПоддерживаемыеТипы.Add(Type("FixedArray"));
	пНеПоддерживаемыеТипы.Add(Type("FixedStructure"));
	пНеПоддерживаемыеТипы.Add(Type("FixedMap"));

	For Each Элем In пНеПоддерживаемыеТипы Do
		If пОбъектМД.Type.ContainsType(Элем) Then
			пРезультат.ReadOnly = True;
			Break;
		EndIf;
	EndDo;

	If False Then
		пТипЗначения = TypeOf(пРезультат.Value);
		If пТипЗначения = Type("FixedArray") Then
			For Сч = 0 To пРезультат.Value.UBound() Do
				пРезультат.Text = пРезультат.Text + Chars.LF + String(пРезультат.Value[Сч]);
			EndDo;
		EndIf;
	EndIf;

	Return пРезультат;
EndFunction