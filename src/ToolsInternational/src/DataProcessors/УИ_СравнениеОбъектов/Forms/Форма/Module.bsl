&НаСервереБезКонтекста
Процедура ДобавитьВДерево(ДЗ, СсылкаНаОбъект)
	МД = СсылкаНаОбъект.Метаданные();
	УИД = СсылкаНаОбъект.УникальныйИдентификатор();
	ГУИД = "id_" + СтрЗаменить(УИД, "-", "_");
	
	ДЗ.Колонки.Добавить(ГУИД, Новый ОписаниеТипов());

	//Реквизиты
	Строки = ДЗ.Строки;
	Строка = Строки.Найти(" Реквизиты", "Реквизит");
	Если Строка = Неопределено Тогда
		Строка = Строки.Добавить();
		Строка.Реквизит = " Реквизиты";
	КонецЕсли;
	Строка[ГУИД] = СсылкаНаОбъект;

	Строки = Строка.Строки;
	Реквизиты = МД.Реквизиты;
	Для Каждого Реквизит Из Реквизиты Цикл
		РеквизитИмя = Реквизит.Имя; 
		
		Строка = Строки.Найти(РеквизитИмя, "Реквизит");
		Если Строка = Неопределено Тогда
			Строка = Строки.Добавить();
			Строка.Реквизит = РеквизитИмя;
		КонецЕсли;
		Строка[ГУИД] = СсылкаНаОбъект[РеквизитИмя]; 
	КонецЦикла;

	//Табличные части
	Для Каждого ТЧ Из МД.ТабличныеЧасти Цикл
		Если СсылкаНаОбъект[ТЧ.Имя].Количество() = 0 Тогда Продолжить; КонецЕсли;
		РеквизитИмя = ТЧ.Имя; 
		
		Строки = ДЗ.Строки;
		Строка = Строки.Найти(РеквизитИмя, "Реквизит");
		Если Строка = Неопределено Тогда
			Строка = Строки.Добавить();
			Строка.Реквизит = РеквизитИмя;
		КонецЕсли;

		//Строки табличной части
		СтрокиНС = Строка.Строки;
		Для Каждого СтрокаТЧ Из СсылкаНаОбъект[ТЧ.Имя] Цикл
			НомерСтроки = "Строка № " + Формат(СтрокаТЧ.НомерСтроки, "ЧЦ=4; ЧВН=; ЧГ=");
			СтрокаНС = СтрокиНС.Найти(НомерСтроки, "Реквизит");
			Если СтрокаНС = Неопределено Тогда 
				СтрокаНС = СтрокиНС.Добавить();
				СтрокаНС.Реквизит = НомерСтроки;
			КонецЕсли;
			
			//Значения строк табличной части
			СтрокиРС = СтрокаНС.Строки;
			Для Каждого Реквизит Из МД.ТабличныеЧасти[ТЧ.Имя].Реквизиты Цикл
				РеквизитИмя = Реквизит.Имя; 

				СтрокаРС = СтрокиРС.Найти(РеквизитИмя, "Реквизит");
				Если СтрокаРС = Неопределено Тогда
					СтрокаРС = СтрокиРС.Добавить();
					СтрокаРС.Реквизит = РеквизитИмя;
				КонецЕсли;
				Значение = СтрокаТЧ[РеквизитИмя];
				СтрокаРС[ГУИД] = ?(ЗначениеЗаполнено(Значение), Значение, Неопределено);
			КонецЦикла;

		КонецЦикла;
	КонецЦикла;
	
	Строки = ДЗ.Строки;
	Строки.Сортировать("Реквизит", Истина);
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ПочиститьДерево(ДЗ, Строки = Неопределено) 
	
	Колонки = Новый Массив;
	Для Каждого Колонка Из ДЗ.Колонки Цикл
		Если Колонка.Имя = "Реквизит" Тогда Продолжить; КонецЕсли;
		Колонки.Добавить(Колонка.Имя);
	КонецЦикла;
	Колонок = Колонки.Количество() - 1;
	Если Колонок = 0 Тогда Возврат КонецЕсли;

	Если Строки = Неопределено Тогда
		Строки = ДЗ.Строки;
	КонецЕсли;

	УдаляемыеСтроки = Новый Массив;
	Для Каждого Строка Из Строки Цикл
		ЕстьПодчиненные = Строка.Строки.Количество() > 0;
		
		Если ЕстьПодчиненные Тогда
			ПочиститьДерево(ДЗ, Строка.Строки);
		Иначе Сч = 0;
			Для Кол = 1 По Колонок Цикл
				Сч = Сч + ?(Строка[Колонки[0]] = Строка[Колонки[Кол]], 1, 0);
			КонецЦикла;
			Если Сч = Колонок Тогда УдаляемыеСтроки.Добавить(Строка); КонецЕсли;
		КонецЕсли;
	КонецЦикла;
	
	Для Каждого Строка Из УдаляемыеСтроки Цикл
		Строки.Удалить(Строка);
	КонецЦикла;

КонецПроцедуры

&НаСервере
Процедура СформироватьПечатнуюФормуСравненияОбъектов() Экспорт

	ДЗ = Новый ДеревоЗначений;
	ДЗ.Колонки.Добавить("Реквизит", Новый ОписаниеТипов());

	Для Каждого ОбъектЭлемент Из Объекты Цикл
		СсылкаНаОбъект = ОбъектЭлемент.Значение;
		ДобавитьВДерево(ДЗ, СсылкаНаОбъект);
	КонецЦикла;

	ПочиститьДерево(ДЗ);

	ТабличныйДокумент = Новый ТабличныйДокумент;
	ТабличныйДокумент.ИмяПараметровПечати = "ПАРАМЕТРЫ_ПЕЧАТИ_Обработка_СравнениеОбъектов";
	Макет = Обработки.УИ_СравнениеОбъектов.ПолучитьМакет("ПФ_MXL_СравнениеОбъектов");
	
	ТабличныйДокумент.НачатьАвтогруппировкуСтрок();
	Уровень = 1;
	Для Каждого Строка Из ДЗ.Строки Цикл
		ВывестиСтроку(Строка, ДЗ.Колонки, ТабличныйДокумент, Макет, Уровень);
	КонецЦикла;
	ТабличныйДокумент.ЗакончитьАвтогруппировкуСтрок();
	
	ОбластьШапка = ТабличныйДокумент.Область(1,,1);
	ТабличныйДокумент.ПовторятьПриПечатиСтроки = ОбластьШапка;
	ТабличныйДокумент.ТолькоПросмотр = Истина;
	ТабличныйДокумент.АвтоМасштаб = Истина;
	ТабличныйДокумент.ФиксацияСверху = 1;
	ТабличныйДокумент.ФиксацияСлева = 1;
	
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ВывестиСтроку(Строка, Колонки, ТабличныйДокумент, Макет, Уровень)
	ЕстьВложенныеСтроки = Строка.Строки.Количество() > 0;
	
	ОбластьРеквизит = Макет.ПолучитьОбласть("Реквизит");
	ОбластьРеквизит.Параметры.Реквизит = СокрЛП(Строка.Реквизит);
	Если ЕстьВложенныеСтроки Тогда ОформитьОбласть(ОбластьРеквизит); КонецЕсли;
	ТабличныйДокумент.Вывести(ОбластьРеквизит, Уровень);
	
	ОбластьКолонка = Макет.ПолучитьОбласть("Значение");
	Для Каждого Колонка Из Колонки Цикл
		Если Колонка.Имя = "Реквизит" Тогда Продолжить; КонецЕсли;
		Значение = Строка[Колонка.Имя];
		ОбластьКолонка.Параметры.Значение = Значение;
		Если ЕстьВложенныеСтроки Тогда ОформитьОбласть(ОбластьКолонка); КонецЕсли;
		ТабличныйДокумент.Присоединить(ОбластьКолонка, Уровень);
	КонецЦикла;
	

	Если ЕстьВложенныеСтроки Тогда
		Для Каждого ПодСтрока Из Строка.Строки Цикл
			ВывестиСтроку(ПодСтрока, Колонки, ТабличныйДокумент, Макет, Уровень + 1);
		КонецЦикла;
	КонецЕсли;
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ОформитьОбласть(Область)
	Шрифт = Область.ТекущаяОбласть.Шрифт;
	Область.ТекущаяОбласть.Шрифт = Новый Шрифт(Шрифт,,,Истина);
	Область.ТекущаяОбласть.ЦветФона = ЦветаСтиля.ЦветФонаШапкиОтчета;
КонецПроцедуры


&НаСервере
Процедура СформироватьНаСервере()
	СформироватьПечатнуюФормуСравненияОбъектов();
КонецПроцедуры

&НаКлиенте
Процедура Generate(Команда)
	Если Объекты.Количество() = 0 Тогда
		Элементы.ФормаПараметры.Пометка = Истина;
		Элементы.ГруппаПараметры.Видимость = Истина;
		ТекущийЭлемент = Элементы.Объекты;
		Возврат;
	КонецЕсли;
	СформироватьНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура Параметры(Команда)
	Пометка = Не Элементы.ФормаПараметры.Пометка;
	Элементы.ФормаПараметры.Пометка = Пометка;
	Элементы.ГруппаПараметры.Видимость = Пометка;
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	Объекты.Очистить();
	Если Параметры.Свойство("СравниваемыеОбъекты") Тогда
		Объекты.ЗагрузитьЗначения(Параметры.СравниваемыеОбъекты);
	КонецЕсли;
	СформироватьНаСервере();
	
	//UT_Common.ToolFormOnCreateAtServer(ЭтотОбъект, Отказ, СтандартнаяОбработка);
	
КонецПроцедуры


&НаСервере
Процедура ДобавитьРанееДобавленныеКСравнениюНаСервере()
	МассивОбъектовКСравнению=UT_Common.ОбъектыДобавленныеКСравнению();
	
	Для Каждого ТекОбъект ИЗ МассивОбъектовКСравнению Цикл
		Если Объекты.НайтиПоЗначению(ТекОбъект)<>Неопределено Тогда
			Продолжить;
		КонецЕсли;
		
		Объекты.Добавить(ТекОбъект);
	КонецЦикла;
КонецПроцедуры


&НаКлиенте
Процедура ДобавитьРанееДобавленныеКСравнению(Команда)
	ДобавитьРанееДобавленныеКСравнениюНаСервере();
КонецПроцедуры


&НаСервере
Процедура ОчиститьРанееДобавленныеКСравнениюНаСервере()
	UT_Common.ОчиститьОбъектыДобавленныеКСравнению();
КонецПроцедуры


&НаКлиенте
Процедура ОчиститьРанееДобавленныеКСравнению(Команда)
	ОчиститьРанееДобавленныеКСравнениюНаСервере();
КонецПроцедуры

//@skip-warning
&НаКлиенте
Процедура Подключаемый_ВыполнитьОбщуюКомандуИнструментов(Команда) 
	UT_CommonClient.Подключаемый_ВыполнитьОбщуюКомандуИнструментов(ЭтотОбъект, Команда);
КонецПроцедуры

