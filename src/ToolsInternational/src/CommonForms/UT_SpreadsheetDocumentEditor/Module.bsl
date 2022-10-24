///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
// Translated by Neti Company
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.WindowOpeningMode <> Undefined Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	
	If Parameters.SpreadsheetDocument = Undefined Then
		If Not IsBlankString(Parameters.TemplateMetadataObjectName) Then
			EditingDenied = Not Parameters.Edit;
			LoadSpreadsheetDocumentFromMetadata(Parameters.LanguageCode);
		EndIf;
		
	ElsIf TypeOf(Parameters.SpreadsheetDocument) = Type("SpreadsheetDocument") Then
		SpreadsheetDocument = Parameters.SpreadsheetDocument;
	Else
		BinaryData = GetFromTempStorage(Parameters.SpreadsheetDocument); // BinaryData - 
		TempFileName = GetTempFileName("mxl");
		BinaryData.Write(TempFileName);
		SpreadsheetDocument.Read(TempFileName);
		DeleteFiles(TempFileName);
	EndIf;
	
	Items.SpreadsheetDocument.Edit = Parameters.Edit;
	Items.SpreadsheetDocument.ShowGroups = True;
	
	IsTemplate = Not IsBlankString(Parameters.TemplateMetadataObjectName);
	Items.Warning.Visible = IsTemplate And Parameters.Edit;
	
	Items.EditInExternalApplication.Visible = False;
	
	If Not IsBlankString(Parameters.DocumentName) Then
		DocumentName = Parameters.DocumentName;
	EndIf;
	
	Items.SpreadsheetDocument.ShowRowAndColumnNames = SpreadsheetDocument.Template;
	Items.SpreadsheetDocument.ShowCellNames = SpreadsheetDocument.Template;
	
	Items.Translate.Visible = AutoTranslationAvailable;
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBlankString(Parameters.FilePath) Then
		File = New File(Parameters.FilePath);
		If IsBlankString(DocumentName) Then
			DocumentName = File.BaseName;
		EndIf;
		File.BeginGettingReadOnly(New NotifyDescription("OnCompleteGettingReadOnly", ThisObject));
		Return;
	EndIf;
	
	SetInitialFormSettings();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	NotifyDescription = New NotifyDescription("ConfirmAndClose", ThisObject);
	QuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Сохранить изменения в %1?'; en = 'Do you want to save the changes you made to %1?'"), DocumentName);
	UT_CommonClient.ShowQuestionToUser(NotifyDescription, QuestionText , QuestionDialogMode.YesNo);
	
	If Modified Or Exit Then
		Return;
	EndIf;
	
	NotifyWritingSpreadsheetDocument();
	
EndProcedure

&AtClient
Procedure ConfirmAndClose(Result = Undefined, AdditionalParameters = Undefined) Export
	If Result <> Undefined And Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	NotifyDescription = New NotifyDescription("CloseFormAfterWriteSpreadsheetDocument", ThisObject);
	WriteSpreadsheetDocument(NotifyDescription);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "EditedSpreadsheetDocumentNamesRequest" And Source <> ThisObject Then
		DocumentNames = Parameter; // Array -
		DocumentNames.Add(DocumentName);
	ElsIf EventName = "OwnerFormClosing" And Source = FormOwner Then
		Close();
		If IsOpen() Then
			Parameter.Cancel = True;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SpreadsheetDocumentOnActivate(Item)
	UpdateCommandBarButtonMarks();
	SynchronizeTemplateViewArea();
EndProcedure

&AtClient
Procedure DistributedTemplateOnActivate(Item)
	
	SynchronizeTemplateViewArea();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// Document actions

&AtClient
Procedure WriteAndClose(Command)
	NotifyDescription = New NotifyDescription("CloseFormAfterWriteSpreadsheetDocument", ThisObject);
	WriteSpreadsheetDocument(NotifyDescription);
EndProcedure

&AtClient
Procedure Write(Command)
	WriteSpreadsheetDocument();
	NotifyWritingSpreadsheetDocument();
EndProcedure

&AtClient
Procedure Edit(Command)
	Items.SpreadsheetDocument.Edit = Not Items.SpreadsheetDocument.Edit;
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
EndProcedure

&AtClient
Procedure EditInExternalApplication(Command)
//	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
//		OpeningParameters = New Structure;
//		OpeningParameters.Insert("SpreadsheetDocument", SpreadsheetDocument);
//		OpeningParameters.Insert("TemplateMetadataObjectName", Parameters.TemplateMetadataObjectName);
//		OpeningParameters.Insert("TemplateType", "MXL");
//		NotifyDescription = New NotifyDescription("EditInExternalApplicationCompletion", ThisObject);
//		PrintManagementClientModule = CommonClient.CommonModule("PrintManagementClient");
//		PrintManagementClientModule.EditTemplateInExternalApplication(NotifyDescription, OpeningParameters, ThisObject);
//	EndIf;
EndProcedure

// Format

&AtClient
Procedure IncreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size + IncreaseFontSizeChangeStep(Size);
		Area.Font = New Font(Area.Font,,Size);
	EndDo;
	
EndProcedure

&AtClient
Procedure DecreaseFontSize(Command)
	
	For Each Area In AreaListForChangingFont() Do
		Size = Area.Font.Size;
		Size = Size - IncreaseFontSizeChangeStep(Size);
		If Size < 1 Then
			Size = 1;
		EndIf;
		Area.Font = New Font(Area.Font,,Size);
	EndDo;
	
EndProcedure

&AtClient
Procedure Strikeout(Command)
	
	ValueToSet = Undefined;
	For Each Area In AreaListForChangingFont() Do
		If ValueToSet = Undefined Then
			ValueToSet = Not Area.Font.Strikeout = True;
		EndIf;
		Area.Font = New Font(Area.Font,,,,,,ValueToSet);
	EndDo;
	
	UpdateCommandBarButtonMarks();
	
EndProcedure

&AtClient
Procedure Translate(Command)
	
	QuestionText = UT_StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Выполнить автоматический перевод на %1 язык?'; en = 'Do you want to automatically translate this template to %1 language?'"), Items.Language.Title);
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("ru = 'Выполнить перевод'; en = 'Translate'"));
	Buttons.Add(DialogReturnCode.No, NStr("ru = 'Не выполнять'; en = 'Do not translate'"));
	
	NotifyDescription = New NotifyDescription("OnAnswerTemplateTranslationQuestion", ThisObject);
	ShowQueryBox(NotifyDescription, QuestionText, Buttons);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure LoadSpreadsheetDocumentFromMetadata(Val LanguageCode = Undefined)
	
	TranslationRequired = False;
	
EndProcedure

&AtClient
Procedure SetUpSpreadsheetDocumentRepresentation()
	Items.SpreadsheetDocument.ShowHeaders = Items.SpreadsheetDocument.Edit;
	Items.SpreadsheetDocument.ShowGrid = Items.SpreadsheetDocument.Edit;
EndProcedure

&AtClient
Procedure UpdateCommandBarButtonMarks();
	
#If Not WebClient And Not MobileClient Then
	Area = Items.SpreadsheetDocument.CurrentArea;
	If TypeOf(Area) <> Type("SpreadsheetDocumentRange") Then
		Return;
	EndIf;
	
	// Font
	Font = Area.Font;
	Items.SpreadsheetDocumentBold.Check = Font <> Undefined AND Font.Bold = True;
	Items.SpreadsheetDocumentItalic.Check = Font <> Undefined AND Font.Italic = True;
	Items.SpreadsheetDocumentUnderline.Check = Font <> Undefined AND Font.Underline = True;
	Items.Strikeout.Check = Font <> Undefined AND Font.Strikeout = True;
	
	// Horizontal alighment
	Items.SpreadsheetDocumentAlignLeft.Check = Area.HorizontalAlign = HorizontalAlign.Left;
	Items.SpreadsheetDocumentAlignCenter.Check = Area.HorizontalAlign = HorizontalAlign.Center;
	Items.SpreadsheetDocumentAlignRight.Check = Area.HorizontalAlign = HorizontalAlign.Right;
	Items.SpreadsheetDocumentJustify.Check = Area.HorizontalAlign = HorizontalAlign.Justify;
	
#EndIf
	
EndProcedure

&AtClient
Function IncreaseFontSizeChangeStep(Size)
	If Size = -1 Then
		Return 10;
	EndIf;
	
	If Size < 10 Then
		Return 1;
	ElsIf 10 <= Size And  Size < 20 Then
		Return 2;
	ElsIf 20 <= Size And  Size < 48 Then
		Return 4;
	ElsIf 48 <= Size And  Size < 72 Then
		Return 6;
	ElsIf 72 <= Size And  Size < 96 Then
		Return 8;
	Else
		Return Round(Size / 10);
	EndIf;
EndFunction

&AtClient
Function ШагИзмененияРазмераШрифтаУменьшение(Размер)
	If Размер = -1 Then
		Return -8;
	EndIf;
	
	If Размер <= 11 Then
		Return 1;
	ElsIf 11 < Размер И Размер <= 23 Then
		Return 2;
	ElsIf 23 < Размер И Размер <= 53 Then
		Return 4;
	ElsIf 53 < Размер И Размер <= 79 Then
		Return 6;
	ElsIf 79 < Размер И Размер <= 105 Then
		Return 8;
	Else
		Return Окр(Размер / 11);
	EndIf;
EndFunction

// Возвращаемое значение:
//   Массив из ОбластьЯчеекТабличногоДокумента
//
&AtClient
Function AreaListForChangingFont()
	
	Результат = Новый Массив;
	
	For Each ОбрабатываемаяОбласть Из Items.SpreadsheetDocument.ПолучитьВыделенныеОбласти() Do
		If ОбрабатываемаяОбласть.Font <> Undefined Then
			Результат.Добавить(ОбрабатываемаяОбласть);
			Продолжить;
		EndIf;
		
		ОбрабатываемаяОбластьВерх = ОбрабатываемаяОбласть.Верх;
		ОбрабатываемаяОбластьНиз = ОбрабатываемаяОбласть.Низ;
		ОбрабатываемаяОбластьЛево = ОбрабатываемаяОбласть.Лево;
		ОбрабатываемаяОбластьПраво = ОбрабатываемаяОбласть.Право;
		
		If ОбрабатываемаяОбластьВерх = 0 Then
			ОбрабатываемаяОбластьВерх = 1;
		EndIf;
		
		If ОбрабатываемаяОбластьНиз = 0 Then
			ОбрабатываемаяОбластьНиз = SpreadsheetDocument.ВысотаТаблицы;
		EndIf;
		
		If ОбрабатываемаяОбластьЛево = 0 Then
			ОбрабатываемаяОбластьЛево = 1;
		EndIf;
		
		If ОбрабатываемаяОбластьПраво = 0 Then
			ОбрабатываемаяОбластьПраво = SpreadsheetDocument.ШиринаТаблицы;
		EndIf;
		
		If ОбрабатываемаяОбласть.ТипОбласти = ТипОбластиЯчеекТабличногоДокумента.Колонки Then
			ОбрабатываемаяОбластьВерх = ОбрабатываемаяОбласть.Низ;
			ОбрабатываемаяОбластьНиз = SpreadsheetDocument.ВысотаТаблицы;
		EndIf;
			
		Для НомерКолонки = ОбрабатываемаяОбластьЛево По ОбрабатываемаяОбластьПраво Do
			ШиринаКолонки = Undefined;
			Для НомерСтроки = ОбрабатываемаяОбластьВерх По ОбрабатываемаяОбластьНиз Do
				Ячейка = SpreadsheetDocument.Область(НомерСтроки, НомерКолонки, НомерСтроки, НомерКолонки);
				If ОбрабатываемаяОбласть.ТипОбласти = ТипОбластиЯчеекТабличногоДокумента.Колонки Then
					If ШиринаКолонки = Undefined Then
						ШиринаКолонки = Ячейка.ШиринаКолонки;
					EndIf;
					If Ячейка.ШиринаКолонки <> ШиринаКолонки Then
						Продолжить;
					EndIf;
				EndIf;
				If Ячейка.Font <> Undefined Then
					Результат.Добавить(Ячейка);
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return Результат;
	
EndFunction

&AtClient
Procedure CloseFormAfterWriteSpreadsheetDocument(Закрывать, ДополнительныеParameters) Export
	If Закрывать Then
		Закрыть();
	EndIf;
EndProcedure

&AtClient
Procedure WriteSpreadsheetDocument(ОбработчикЗавершения = Undefined)
	
	If ЭтоНовый() Или EditingProhibited Then
		НачатьДиалогСохраненияФайла(ОбработчикЗавершения);
		Return;
	EndIf;
		
	ЗаписатьТабличныйДокументИмяФайлаВыбрано(ОбработчикЗавершения);
	
EndProcedure

&AtClient
Procedure ЗаписатьТабличныйДокументИмяФайлаВыбрано(Знач ОбработчикЗавершения)
	If Не IsBlankString(Parameters.FilePath) Then
		SpreadsheetDocument.НачатьЗапись(
			Новый NotifyDescription("ОбработатьРезультатЗаписиТабличногоДокумента", ThisObject, ОбработчикЗавершения),
			Parameters.FilePath);
	Else
		ПослеЗаписиТабличногоДокумента(ОбработчикЗавершения);
	EndIf;
EndProcedure

&AtClient
Procedure ОбработатьРезультатЗаписиТабличногоДокумента(Результат, ОбработчикЗавершения) Export 
	If Результат <> True Then 
		Return;
	EndIf;
	
	EditingProhibited = False;
	ПослеЗаписиТабличногоДокумента(ОбработчикЗавершения);
EndProcedure

&AtClient
Procedure ПослеЗаписиТабличногоДокумента(ОбработчикЗавершения)
	WritingCompleted = True;
	Модифицированность = False;
	УстановитьЗаголовок();
	
	ВыполнитьОбработкуОповещения(ОбработчикЗавершения, True);
EndProcedure

&AtClient
Procedure НачатьДиалогСохраненияФайла(Знач ОбработчикЗавершения)
	
	Перем ДиалогСохраненияФайла, NotifyDescription;
	
	ДиалогСохраненияФайла = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.Сохранение);
	ДиалогСохраненияФайла.ПолноеИмяФайла = УИ_ОбщегоНазначенияКлиентСервер.ЗаменитьНедопустимыеСимволыВИмениФайла(
		DocumentName);
	ДиалогСохраненияФайла.Фильтр = НСтр("ru = 'Табличный документ'") + " (*.mxl)|*.mxl";
	
	NotifyDescription = Новый NotifyDescription("ПриЗавершенииДиалогаВыбораФайла", ThisObject, ОбработчикЗавершения);
	ФайловаяСистемаКлиент.ПоказатьДиалогВыбора(NotifyDescription, ДиалогСохраненияФайла);
	
EndProcedure

&AtClient
Procedure ПриЗавершенииДиалогаВыбораФайла(ВыбранныеФайлы, ОбработчикЗавершения) Export
	
	If ВыбранныеФайлы = Undefined Then
		Return;
	EndIf;
	
	ПолноеИмяФайла = ВыбранныеФайлы[0];
	
	Parameters.FilePath = ПолноеИмяФайла;
	DocumentName = Сред(ПолноеИмяФайла, СтрДлина(ОписаниеФайла(ПолноеИмяФайла).Путь) + 1);
	If НРег(Прав(DocumentName, 4)) = ".mxl" Then
		DocumentName = Лев(DocumentName, СтрДлина(DocumentName) - 4);
	EndIf;
	
	ЗаписатьТабличныйДокументИмяФайлаВыбрано(ОбработчикЗавершения);
	
EndProcedure

&AtClient
Function ОписаниеФайла(ПолноеИмя)
	
	ПозицияРазделителя = СтрНайти(ПолноеИмя, ПолучитьРазделительПути(), НаправлениеПоиска.СКонца);
	
	Имя = Сред(ПолноеИмя, ПозицияРазделителя + 1);
	Путь = Лев(ПолноеИмя, ПозицияРазделителя);
	
	ПозицияРасширения = СтрНайти(Имя, ".", НаправлениеПоиска.СКонца);
	
	ИмяБезРасширения = Лев(Имя, ПозицияРасширения - 1);
	Расширение = Сред(Имя, ПозицияРасширения + 1);
	
	Результат = Новый Структура;
	Результат.Вставить("ПолноеИмя", ПолноеИмя);
	Результат.Вставить("Имя", Имя);
	Результат.Вставить("Путь", Путь);
	Результат.Вставить("ИмяБезРасширения", ИмяБезРасширения);
	Результат.Вставить("Расширение", Расширение);
	
	Return Результат;
	
EndFunction
	
&AtClient
Function ИмяНовогоДокумента()
	Return НСтр("ru = 'Новый'");
EndFunction

&AtClient
Procedure УстановитьЗаголовок()
	
	Заголовок = DocumentName;
	If ЭтоНовый() Then
		Заголовок = Заголовок + " (" + НСтр("ru = 'создание'") + ")";
	ElsIf EditingProhibited Then
		Заголовок = Заголовок + " (" + НСтр("ru = 'только просмотр'") + ")";
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpCommandPresentation()
	
	ДокументРедактируется = Items.SpreadsheetDocument.Edit;
	Items.Edit.Пометка = ДокументРедактируется;
	Items.EditCommands.Доступность = ДокументРедактируется;
	Items.WriteAndClose.Доступность = ДокументРедактируется Или Модифицированность;
	Items.Write.Доступность = ДокументРедактируется Или Модифицированность;
	
	If ДокументРедактируется И Не IsBlankString(Parameters.TemplateMetadataObjectName) Then
		Items.Warning.Видимость = True;
	EndIf;
	
EndProcedure

&AtClient
Function ЭтоНовый()
	Return IsBlankString(Parameters.TemplateMetadataObjectName) И IsBlankString(Parameters.FilePath);
EndFunction

&AtClient
Procedure EditInExternalApplicationCompletion(ЗагруженныйТабличныйДокумент, ДополнительныеParameters) Export
	If ЗагруженныйТабличныйДокумент = Undefined Then
		Return;
	EndIf;
	
	Модифицированность = True;
	ОбновитьТабличныйДокумент(ЗагруженныйТабличныйДокумент);
EndProcedure

&AtServer
Procedure ОбновитьТабличныйДокумент(ЗагруженныйТабличныйДокумент)
	SpreadsheetDocument = ЗагруженныйТабличныйДокумент;
EndProcedure


&AtClient
Procedure SetInitialFormSettings()
	
	If Не IsBlankString(Parameters.FilePath) И Не EditingProhibited Then
		Items.SpreadsheetDocument.Edit = True;
	EndIf;
	
	УстановитьDocumentName();
	УстановитьЗаголовок();
	SetUpCommandPresentation();
	SetUpSpreadsheetDocumentRepresentation();
	
EndProcedure

&AtClient
Procedure УстановитьDocumentName()

	If IsBlankString(DocumentName) Then
		ИспользованныеИмена = Новый Массив;
		Оповестить("EditedSpreadsheetDocumentNamesRequest", ИспользованныеИмена, ThisObject);
		
		Индекс = 1;
		Пока ИспользованныеИмена.Найти(ИмяНовогоДокумента() + Индекс) <> Undefined Do
			Индекс = Индекс + 1;
		EndDo;
		
		DocumentName = ИмяНовогоДокумента() + Индекс;
	EndIf;

EndProcedure

&AtClient
Procedure OnCompleteGettingReadOnly(ТолькоЧтение, ДополнительныеParameters) Export
	
	EditingDenied = ТолькоЧтение;
	SetInitialFormSettings();
	
EndProcedure

&AtClient
Procedure Подключаемый_ПереключитьЯзык(Команда)
	

EndProcedure

&AtClient
Procedure Подключаемый_ПриПереключенииЯзыка(LanguageCode, ДополнительныеParameters) Export
	
	LoadSpreadsheetDocumentFromMetadata(LanguageCode);
	If TranslationRequired И AutoTranslationAvailable Then
		ТекстВопроса = СтроковыеФункцииКлиентСервер.ПодставитьParametersВСтроку(
			НСтр("ru = 'Макет еще не переведен на %1 язык.
			|Выполнить автоматический перевод?'"), Items.Language.Заголовок);
		Кнопки = Новый СписокЗначений;
		Кнопки.Добавить(DialogReturnCode.Да, НСтр("ru = 'Выполнить перевод'"));
		Кнопки.Добавить(DialogReturnCode.Нет, НСтр("ru = 'Не выполнять'"));
		
		NotifyDescription = Новый NotifyDescription("OnAnswerTemplateTranslationQuestion", ThisObject);
		ПоказатьВопрос(NotifyDescription, ТекстВопроса, Кнопки);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnAnswerTemplateTranslationQuestion(Ответ, ДополнительныеParameters) Export
	
	If Ответ <> DialogReturnCode.Да Then
		Return;
	EndIf;
	
	ПеревестиТекстыМакета();
	
EndProcedure

&AtServer
Procedure ПеревестиТекстыМакета()
	

EndProcedure

&AtServer
Function УбратьParametersИзТекста(Знач Текст)
	
	НайденныеParameters = Новый Массив;
	
	ЧастиСтроки = СтрРазделить(Текст, "[]", True);
	Для Индекс = 1 По ЧастиСтроки.ВГраница() Do
		НайденныеParameters.Добавить("[" + ЧастиСтроки[Индекс] + "]");
		Индекс = Индекс + 1;
	EndDo;
	
	ОбработанныеParameters = Новый Массив;
	Счетчик = 0;
	For Each Параметр Из НайденныеParameters Do
		If СтрНайти(Текст, Параметр) Then
			Счетчик = Счетчик + 1;
			Текст = СтрЗаменить(Текст, Параметр, ИдентификаторПараметра(Счетчик));
			ОбработанныеParameters.Добавить(Параметр);
		EndIf;
	EndDo;
	
	Результат = Новый Структура;
	Результат.Вставить("Текст", Текст);
	Результат.Вставить("Parameters", ОбработанныеParameters);
	
	Return Результат;
	
EndFunction

&AtServer
Function ВернутьParametersВТекст(Знач Текст, ОбработанныеParameters)
	
	Для Счетчик = 1 По ОбработанныеParameters.Количество() Do
		Текст = СтрЗаменить(Текст, ИдентификаторПараметра(Счетчик), "%" + XMLСтрока(Счетчик));
	EndDo;
	
	Return УИ_СтроковыеФункцииКлиентСервер.ПодставитьParametersВСтрокуИзМассива(Текст, ОбработанныеParameters);
	
EndFunction

// Последовательность символов, которая не должна меняться при переводе на любой язык.
&AtServer
Function ИдентификаторПараметра(Номер)
	
	Return "{<" + XMLСтрока(Номер) + ">}"; 
	
EndFunction

&AtClient
Procedure ShowHideOriginal(Команда)
	
	Items.ShowHideOriginalButton.Пометка = Не Items.ShowHideOriginalButton.Пометка;
	Items.DistributedTemplate.Видимость = Items.ShowHideOriginalButton.Пометка;
	If Items.ShowHideOriginalButton.Пометка Then
		Items.SpreadsheetDocument.ПоложениеЗаголовка = ПоложениеЗаголовкаЭлементаФормы.Авто;
	Else
		Items.SpreadsheetDocument.ПоложениеЗаголовка = ПоложениеЗаголовкаЭлементаФормы.Нет;
	EndIf;
	
EndProcedure

&AtClient
Procedure SynchronizeTemplateViewArea()
	
	If Не Items.DistributedTemplate.Видимость Then
		Return;
	EndIf;
	
	УправляемыйЭлемент =  Items.DistributedTemplate;
	If ТекущийЭлемент <> Items.SpreadsheetDocument Then
		УправляемыйЭлемент = Items.SpreadsheetDocument;
	EndIf;
	
	Область = ТекущийЭлемент.ТекущаяОбласть;
	If Область = Undefined Then
		Return;
	EndIf;
	
	УправляемыйЭлемент.ТекущаяОбласть = ThisObject[ТекущийЭлемент.Имя].Область(
		Область.Верх, Область.Лево, Область.Низ, Область.Право);
	
EndProcedure

&AtClient
Procedure NotifyWritingSpreadsheetDocument()
	
	ParametersОповещения = Новый Структура;
	ParametersОповещения.Вставить("FilePath", Parameters.FilePath);
	ParametersОповещения.Вставить("TemplateMetadataObjectName", Parameters.TemplateMetadataObjectName);
	ParametersОповещения.Вставить("LanguageCode", CurrentLanguage);
	
	If WritingCompleted Then
		ИмяСобытия = "Запись_ТабличныйДокумент";
		ParametersОповещения.Вставить("SpreadsheetDocument", SpreadsheetDocument);
	Else
		ИмяСобытия = "ОтменаРедактированияТабличногоДокумента";
	EndIf;
	Оповестить(ИмяСобытия, ParametersОповещения, ThisObject);

EndProcedure

#КонецОбласти
