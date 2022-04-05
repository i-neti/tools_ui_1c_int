//Sign of using settings
&AtClient
Var mUseSettings Export;

//Types of objects for which processing can be used.
//To default for everyone.
&AtClient
Var mTypesOfProcessedObjects Export;

&AtClient
Var mSetting;

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Performs object processing.
//
// Parameters:
//  ProcessedObject                 - processed object.
//  SequenceNumberObject - serial number of the processed object.
//
&AtServer
Procedure ProcessObject(Reference, SequenceNumberObject, ParametersWriteObjects)

	ProcessedObject = Reference.GetObject();
	ProcessedObject.SetDeletionMark(False);
	If UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects, "СнятьПометкуУдаления") Then
		UT_CommonClientServer.MessageToUser(StrTemplate(Nstr("ru = 'Объект %1 УСПЕХ!!!';en = 'Object %1 SUCCESS!!!'"), ProcessedObject));
	EndIf;
EndProcedure // ProcessObject()

// Performs object processing.
//
// Parameters:
//  None.
//
&AtClient
Function ExecuteProcessing(ParametersWriteObjects) Export

	Indicator = GetProcessIndicator(FoundObjects.Count());
	For IndexOf = 0 To FoundObjects.Count() - 1 Do
		ProcessIndicator(Indicator, IndexOf + 1);

		RowFoundObjectValue = FoundObjects.Get(IndexOf).Value;
		ProcessObject(RowFoundObjectValue, IndexOf, ParametersWriteObjects);
	EndDo;

	If IndexOf > 0 Then
		//NotifyChanged(Type(ОбъектПоиска.Type + "Reference." + ОбъектПоиска.Name));
	EndIf;

	Return IndexOf;
EndFunction // ExecuteProcessing()

// Stores form attribute values.
//
// Parameters:
//  None.
//
&AtClient
Procedure SaveSetting() Export

	If IsBlankString(CurrentSettingRepresentation) Then
		ShowMessageBox( ,
			Nstr("ru = 'Задайте имя новой настройки для сохранения или выберите существующую настройку для перезаписи.';en = 'Specify a name for the new setting to save, or select an existing setting to overwrite.'"));
	EndIf;

	NewSetting = New Structure;
	NewSetting.Insert("Processing", CurrentSettingRepresentation);
	NewSetting.Insert("Other", New Structure);

	For Each AttributeSetting In mSetting Do
		Execute ("NewSetting.Other.Insert(String(AttributeSetting.Key), " + String(AttributeSetting.Key)
			+ ");");
	EndDo;

	AvailableDataProcessors = ThisForm.FormOwner.AvailableDataProcessors;
	CurrentAvailableSetting = Undefined;
	For Each CurrentAvailableSetting In AvailableDataProcessors.GetItems() Do
		If CurrentAvailableSetting.GetID() = Parent Then
			Break;
		EndIf;
	EndDo;

	If CurrentSetting = Undefined Or Not CurrentSetting.Processing = CurrentSettingRepresentation Then
		If CurrentAvailableSetting <> Undefined Then
			NewLine = CurrentAvailableSetting.GetItems().Add();
			NewLine.Processing = CurrentSettingRepresentation;
			NewLine.Setting.Add(NewSetting);

			ThisForm.FormOwner.Items.AvailableDataProcessors.CurrentLine = NewLine.GetID();
		EndIf;
	EndIf;

	If CurrentAvailableSetting <> Undefined And CurrentLine > -1 Then
		For Each CurrentSettingItem In CurrentAvailableSetting.GetItems() Do
			If CurrentSettingItem.GetID() = CurrentLine Then
				Break;
			EndIf;
		EndDo;

		If CurrentSettingItem.Setting.Count() = 0 Then
			CurrentSettingItem.Setting.Add(NewSetting);
		Else
			CurrentSettingItem.Setting[0].Value = NewSetting;
		EndIf;
	EndIf;

	CurrentSetting = NewSetting;
	ThisForm.Modified = False;
	
EndProcedure // вSaveSetting()

// // Restores saved form attribute values.
//
// Parameters:
//  None.
//
&AtClient
Procedure DownloadSettings() Export

	If Items.CurrentSetting.ChoiceList.Count() = 0 Then
		SetNameSettings(Nstr("ru = 'Новая настройка';en = 'New setting'"));
	Else
		If Not CurrentSetting.Other = Undefined Then
			mSetting = CurrentSetting.Other;
		EndIf;
	EndIf;

	For Each AttributeSetting In mSetting Do
		//@skip-warning
		Value = mSetting[AttributeSetting.Key];
		Execute (String(AttributeSetting.Key) + " = Value;");
	EndDo;

EndProcedure //DownloadSettings()

// Sets the value of the "CurrentSetting" attribute by the name of the setting or arbitrarily.
//
// Parameters:
//  NameSettings   - arbitrary setting name to be set.
//
&AtClient
Procedure SetNameSettings(NameSettings = "") Export

	If IsBlankString(NameSettings) Then
		If CurrentSetting = Undefined Then
			CurrentSettingRepresentation = "";
		Else
			CurrentSettingRepresentation = CurrentSetting.Processing;
		EndIf;
	Else
		CurrentSettingRepresentation = NameSettings;
	EndIf;

EndProcedure // SetNameSettings()

// Gets a structure to indicate the progress of the loop.
//
// Parameters:
//  NumberOfPasses - Number - maximum counter value;
//  ProcessRepresentation - String, "Done" - the display name of the process;
//  InternalCounter - Boolean, *True - use internal counter with initial value 1,
//                    otherwise, you will need to pass the value of the counter each time you call to update the indicator;
//  NumberOfUpdates - Number, *100 - total number of indicator updates;
//  OutputTime - Boolean, *True - display approximate time until the end of the process;
//  AllowBreaking - Boolean, *True - allows the user to break the process.
//
// Return value:
//  Structure - which will then need to be passed to the method ProcessIndicator.
//
&AtClient
Function GetProcessIndicator(КоличествоПроходов, ПредставлениеПроцесса = "Выполнено", ВнутреннийСчетчик = True,
	КоличествоОбновлений = 100, ЛиВыводитьВремя = True, РазрешитьПрерывание = True) Export

	Indicator = New Structure;
	Indicator.Insert("КоличествоПроходов", КоличествоПроходов);
	Indicator.Insert("ДатаНачалаПроцесса", CurrentDate());
	Indicator.Insert("ПредставлениеПроцесса", ПредставлениеПроцесса);
	Indicator.Insert("ЛиВыводитьВремя", ЛиВыводитьВремя);
	Indicator.Insert("РазрешитьПрерывание", РазрешитьПрерывание);
	Indicator.Insert("ВнутреннийСчетчик", ВнутреннийСчетчик);
	Indicator.Insert("Step", КоличествоПроходов / КоличествоОбновлений);
	Indicator.Insert("СледующийСчетчик", 0);
	Indicator.Insert("Счетчик", 0);
	Return Indicator;

EndFunction // ЛксGetProcessIndicator()

// Проверяет и обновляет индикатор. Нужно вызывать на каждом проходе индицируемого цикла.
//
// Parameters:
//  Indicator    - Structure - индикатора, полученная методом ЛксGetProcessIndicator;
//  Счетчик      - Number - внешний счетчик цикла, используется при ВнутреннийСчетчик = False.
//
&AtClient
Procedure ProcessIndicator(Indicator, Счетчик = 0) Export

	If Indicator.ВнутреннийСчетчик Then
		Indicator.Счетчик = Indicator.Счетчик + 1;
		Счетчик = Indicator.Счетчик;
	EndIf;
	If Indicator.РазрешитьПрерывание Then
		UserInterruptProcessing();
	EndIf;

	If Счетчик > Indicator.СледующийСчетчик Then
		Indicator.СледующийСчетчик = Int(Счетчик + Indicator.Step);
		If Indicator.ЛиВыводитьВремя Then
			ПрошлоВремени = CurrentDate() - Indicator.ДатаНачалаПроцесса;
			Осталось = ПрошлоВремени * (Indicator.КоличествоПроходов / Счетчик - 1);
			Часов = Int(Осталось / 3600);
			Осталось = Осталось - (Часов * 3600);
			Минут = Int(Осталось / 60);
			Секунд = Int(Int(Осталось - (Минут * 60)));
			ОсталосьВремени = Format(Часов, "ЧЦ=2; ЧН=00; ЧВН=") + ":" + Format(Минут, "ЧЦ=2; ЧН=00; ЧВН=") + ":"
				+ Format(Секунд, "ЧЦ=2; ЧН=00; ЧВН=");
			ТекстОсталось = "Осталось: ~" + ОсталосьВремени;
		Else
			ТекстОсталось = "";
		EndIf;

		If Indicator.КоличествоПроходов > 0 Then
			ТекстСостояния = ТекстОсталось;
		Else
			ТекстСостояния = "";
		EndIf;

		Status(Indicator.ПредставлениеПроцесса, Счетчик / Indicator.КоличествоПроходов * 100, ТекстСостояния);
	EndIf;

	If Счетчик = Indicator.КоличествоПроходов Then
		Status(Indicator.ПредставлениеПроцесса, 100, ТекстСостояния);
	EndIf;

EndProcedure // ЛксProcessIndicator()

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ ФОРМЫ

&AtClient
Procedure OnOpen(Cancel)
	If mUseSettings Then
		SetNameSettings();
		DownloadSettings();
	Else
		Items.CurrentSetting.Enabled = False;
		Items.SaveSettings.Enabled = False;
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Setting") Then
		CurrentSetting = Parameters.Setting;
	EndIf;
	If Parameters.Property("FoundObjects") Then
		FoundObjects.LoadValues(Parameters.НайденныеОбъекты);
	EndIf;
	CurrentLine = -1;
	If Parameters.Property("CurrentLine") Then
		If Parameters.CurrentLine <> Undefined Then
			CurrentLine = Parameters.CurrentLine;
		EndIf;
	EndIf;
	If Parameters.Property("Parent") Then
		Parent = Parameters.Parent;
	EndIf;
	If Parameters.Property("ОбъектПоиска") Then
		ОбъектПоиска = Parameters.ОбъектПоиска;
	EndIf;

	Items.CurrentSetting.ChoiceList.Clear();
	If Parameters.Property("Settings") Then
		For Each String In Parameters.Settings Do
			Items.CurrentSetting.ChoiceList.Add(String, String.Processing);
		EndDo;
	EndIf;

	DeletionMark=True;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ОБРАБОТЧИКИ СОБЫТИЙ, ВЫЗЫВАЕМЫЕ ИЗ ЭЛЕМЕНТОВ ФОРМЫ

&AtClient
Procedure ExecuteCommand(Command)
	ОбработаноОбъектов = ExecuteProcessing(UT_CommonClientServer.FormWriteSettings(
		ThisObject.FormOwner));

	ShowMessageBox( , "Processing <" + TrimAll(ThisForm.Title) + "> завершена!
																		   |Обработано объектов: " + ОбработаноОбъектов
		+ ".");
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	SaveSetting();
EndProcedure

&AtClient
Procedure ТекущаяНастройкаОбработкаВыбора(Item, ВыбранноеЗначение, StandardProcessing)
	StandardProcessing = False;

	If Not CurrentSetting = ВыбранноеЗначение Then

		If ThisForm.Modified Then
			ShowQueryBox(New NotifyDescription("ТекущаяНастройкаОбработкаВыбораЗавершение", ThisForm,
				New Structure("ВыбранноеЗначение", ВыбранноеЗначение)), "Save текущую настройку?",
				QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			Return;
		EndIf;

		ТекущаяНастройкаОбработкаВыбораФрагмент(ВыбранноеЗначение);

	EndIf;
EndProcedure

&AtClient
Procedure ТекущаяНастройкаОбработкаВыбораЗавершение(РезультатВопроса, AdditionalParameters) Export

	ВыбранноеЗначение = AdditionalParameters.ВыбранноеЗначение;
	If РезультатВопроса = DialogReturnCode.Yes Then
		SaveSetting();
	EndIf;

	ТекущаяНастройкаОбработкаВыбораФрагмент(ВыбранноеЗначение);

EndProcedure

&AtClient
Procedure ТекущаяНастройкаОбработкаВыбораФрагмент(Val ВыбранноеЗначение)

	CurrentSetting = ВыбранноеЗначение;
	SetNameSettings();

	DownloadSettings();

EndProcedure

&AtClient
Procedure ТекущаяНастройкаПриИзменении(Item)
	ThisForm.Modified = True;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// ИНИЦИАЛИЗАЦИЯ МОДУЛЬНЫХ ПЕРЕМЕННЫХ

mUseSettings = False;

//Attributes настройки и значения по умолчанию.
mSetting = New Structure("");

//mSetting.<Name реквизита> = <Value реквизита>;

mTypesOfProcessedObjects = "Catalog,Document";