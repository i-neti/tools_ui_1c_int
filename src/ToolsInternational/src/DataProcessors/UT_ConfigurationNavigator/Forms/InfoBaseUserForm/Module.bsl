&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	УстановитьПривилегированныйРежим(True);

	If Parameters.Property("WorkMode") Then
		_WorkMode = Parameters.WorkMode;
	Endif;

	If _WorkMode = 0 Then
		ID = Parameters.DBUserID;
		DBUserID = New UUID(Parameters.DBUserID);

		Try
			ПользовательИБ = InfoBaseUsers.НайтиПоУникальномуИдентификатору(
				DBUserID);
			If ПользовательИБ = Неопределено Then
				Отказ = True;
			Endif;
		Исключение
			Отказ = True;
		КонецПопытки;

	ИначеЕсли _WorkMode = 1 Then
		ПользовательИБ = InfoBaseUsers.СоздатьПользователя();
		Элементы.ChangePassword.Доступность = Ложь;
		Заголовок = "Создание";

	ИначеЕсли _WorkMode = 2 Then
		ID = Parameters.DBUserID;
		DBUserID = New UUID(Parameters.DBUserID);

		Try
			ПользовательИБ = InfoBaseUsers.НайтиПоУникальномуИдентификатору(
				DBUserID);
			If ПользовательИБ = Неопределено Then
				Отказ = True;
			Endif;
		Исключение
			Отказ = True;
		КонецПопытки;

		Элементы.ChangePassword.Доступность = Ложь;
		Заголовок = "Создание";
	Иначе
		Отказ = True;
	Endif;

	If Не Отказ Then
		ЗаполнитьЗначенияСвойств(ЭтаФорма, ПользовательИБ, , "Password");

		Струк = вЗначениеСвойств(ПользовательИБ, "UnsafeOperationProtection");
		If Струк.UnsafeOperationProtection <> Неопределено Then
			UnsafeOperationProtection = ПользовательИБ.UnsafeOperationProtection.ПредупреждатьОбОпасныхДействиях;
		Иначе
			UnsafeOperationProtection = Ложь;
			Элементы.UnsafeOperationProtection.ТолькоПросмотр = True;
		Endif;

		If ПользовательИБ.ПарольУстановлен Then
			Password = "12345";
			PasswordConfirmation = "54321";
		Endif;

		Для Каждого Элем Из Метаданные.Роли Цикл
			НС = UserRoles.Добавить();
			НС.Name = Элем.Name;
			НС.Presentation = Элем.Представление();
			If ПользовательИБ.Роли.Содержит(Элем) Then
				НС.Check = True;
				НС.Set = True;
				If _WorkMode = 2 Then
					НС.Set = Ложь;
				Endif;
			Endif;
		КонецЦикла;

		UserRoles.Сортировать("Name");

	Endif;
	
EndProcedure


&НаСервереБезКонтекста
Функция вЗначениеСвойств(Знач Объект, ПереченьСвойств)
	Струк = New Структура(ПереченьСвойств);
	ЗаполнитьЗначенияСвойств(Струк, Объект);

	Возврат Струк;
КонецФункции

&AtServer
Процедура ЗаписатьОбъектНаСервере()
	If _WorkMode = 0 Then
		ПользовательИБ = InfoBaseUsers.НайтиПоУникальномуИдентификатору(DBUserID);
	Иначе
		ПользовательИБ = InfoBaseUsers.СоздатьПользователя();
		ПользовательИБ.Password = Password;
	Endif;

	If Не Элементы.UnsafeOperationProtection.ТолькоПросмотр Then
		ЗаполнитьЗначенияСвойств(ПользовательИБ, ЭтаФорма, , "Password, UnsafeOperationProtection");
		ПользовательИБ.UnsafeOperationProtection.ПредупреждатьОбОпасныхДействиях = UnsafeOperationProtection;
	Иначе
		ЗаполнитьЗначенияСвойств(ПользовательИБ, ЭтаФорма, , "Password");
	Endif;

	Для Каждого Стр Из UserRoles.НайтиСтроки(New Структура("Check, Set", True, Ложь)) Цикл
		ПользовательИБ.Роли.Добавить(Метаданные.Роли[Стр.Name]);
	КонецЦикла;

	Для Каждого Стр Из UserRoles.НайтиСтроки(New Структура("Check, Set", Ложь, True)) Цикл
		ПользовательИБ.Роли.Удалить(Метаданные.Роли[Стр.Name]);
	КонецЦикла;

	ПользовательИБ.Записать();
КонецПроцедуры

&НаКлиенте
Процедура WriteObject(Команда)
	If _WorkMode <> 0 Then
		If Password <> PasswordConfirmation Then
			ПоказатьПредупреждение( , "Password не совпадает с Подтверждением пароля!", 10);
			Возврат;
		Endif;
	Endif;

	Try
		ЗаписатьОбъектНаСервере();
		Закрыть();
	Исключение
		Сообщить(ОписаниеОшибки());
	КонецПопытки;
КонецПроцедуры

&AtServer
Процедура ИзменитьПарольНаСервере()
	ПользовательИБ = InfoBaseUsers.НайтиПоУникальномуИдентификатору(DBUserID);
	ПользовательИБ.Password = Password;
	ПользовательИБ.Записать();
КонецПроцедуры

&НаКлиенте
Процедура ChangePassword(Команда)
	Если Password <> PasswordConfirmation Then
		ПоказатьПредупреждение( , "Password не совпадает с Подтверждением пароля!", 10);
		Возврат;
	Endif;

	ИзменитьПарольНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура _ShowOnlyAvailable(Команда)
	ЭФ = Элементы.UserRoles_ShowOnlyAvailable;
	ЭФ.Check = Не Эф.Check;

	Если ЭФ.Check Then
		Элементы.UserRoles.ОтборСтрок = New ФиксированнаяСтруктура(New Структура("Check", True));
	Иначе
		Элементы.UserRoles.ОтборСтрок = Неопределено;
	Endif;
КонецПроцедуры