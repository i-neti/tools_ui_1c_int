Функция ПараметрыСтартаСеанса() Экспорт

	ПараметрыСтартаСеанса=Новый Структура;

	Если Не UT_CommonClientServer.IsPortableDistribution() Тогда
		Если ПравоДоступа("Administration", Метаданные) И Не РольДоступна("UT_UniversalTools")
			И ПользователиИнформационнойБазы.ПолучитьПользователей().Количество() > 0 Тогда
			ТекущийПользователь = ПользователиИнформационнойБазы.ТекущийПользователь();
			ТекущийПользователь.Роли.Добавить(Метаданные.Роли.UT_UniversalTools);
			ТекущийПользователь.Записать();

			ПараметрыСтартаСеанса.Вставить("ДобавленыПраваНаРасширение", Истина);
		Иначе
			ПараметрыСтартаСеанса.Вставить("ДобавленыПраваНаРасширение", Ложь);
		КонецЕсли;
	Иначе
		ПараметрыСтартаСеанса.Вставить("ДобавленыПраваНаРасширение", Ложь);	
	КонецЕсли;

	ПараметрыСтартаСеанса.Вставить("НомерСеанса", НомерСеансаИнформационнойБазы());
	ПараметрыСтартаСеанса.Вставить("ЯзыкСинтаксисаКонфигурации", UT_CodeEditorServer.ЯзыкСинтаксисаКонфигурации());

	Возврат ПараметрыСтартаСеанса;
КонецФункции

// Устанавливает жирное оформление шрифта заголовков групп формы для их корректного отображения в интерфейсе 8.2.
// В интерфейсе Такси заголовки групп с обычным выделением и без выделения выводится большим шрифтом.
// В интерфейсе 8.2 такие заголовки выводятся как обычные надписи и не ассоциируются с заголовками.
// Эта функция предназначена для визуального выделения (жирным шрифтом) заголовков групп в режиме интерфейса 8.2.
//
// Параметры:
//  Форма - УправляемаяФорма - форма для изменения шрифта заголовков групп;
//  ИменаГрупп - Строка - список имен групп формы, разделенных запятыми. Если имена групп не указаны,
//                        то оформление будет применено ко всем группам на форме.
//
// Пример:
//  Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
//    СтандартныеПодсистемыСервер.УстановитьОтображениеЗаголовковГрупп(ЭтотОбъект);
//
Процедура УстановитьОтображениеЗаголовковГрупп(Форма, ИменаГрупп = "") Экспорт

	Если КлиентскоеПриложение.ТекущийВариантИнтерфейса() = ВариантИнтерфейсаКлиентскогоПриложения.Версия8_2 Тогда
		ЖирныйШрифт = Новый Шрифт(, , Истина);
		Если Не ЗначениеЗаполнено(ИменаГрупп) Тогда
			Для Каждого Элемент Из Форма.Элементы Цикл
				Если Тип(Элемент) = Тип("ГруппаФормы") И Элемент.Вид = ВидГруппыФормы.ОбычнаяГруппа
					И Элемент.ОтображатьЗаголовок = Истина И (Элемент.Отображение = ОтображениеОбычнойГруппы.ОбычноеВыделение
					Или Элемент.Отображение = ОтображениеОбычнойГруппы.Нет) Тогда
					Элемент.ШрифтЗаголовка = ЖирныйШрифт;
				КонецЕсли;
			КонецЦикла;
		Иначе
			МассивЗаголовков = UT_StringFunctionsClientServer.РазложитьСтрокуВМассивПодстрок(ИменаГрупп, , , Истина);
			Для Каждого ИмяЗаголовка Из МассивЗаголовков Цикл
				Элемент = Форма.Элементы[ИмяЗаголовка];
				Если Элемент.Отображение = ОтображениеОбычнойГруппы.ОбычноеВыделение Или Элемент.Отображение
					= ОтображениеОбычнойГруппы.Нет Тогда
					Элемент.ШрифтЗаголовка = ЖирныйШрифт;
				КонецЕсли;
			КонецЦикла;
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

Function DefaultLanguageCode() Export
	Возврат UT_CommonServerCall.DefaultLanguageCode();
EndFunction

// См. СтандартныеПодсистемыПовтИсп.СсылкиПоИменамПредопределенных
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Экспорт

	Возврат UT_CommonCached.RefsByPredefinedItemsNames(FullMetadataObjectName);

EndFunction

Функция ЗначенияРеквизитовОбъекта(Ссылка, Знач Реквизиты, ВыбратьРазрешенные = Ложь) Экспорт

	Возврат UT_Common.ЗначенияРеквизитовОбъекта(Ссылка, Реквизиты, ВыбратьРазрешенные);

КонецФункции

// Значение реквизита, прочитанного из информационной базы по ссылке на объект.
//
// Если необходимо зачитать реквизит независимо от прав текущего пользователя,
// то следует использовать предварительный переход в привилегированный режим.
//
// Параметры:
//  Ссылка    - ЛюбаяСсылка - объект, значения реквизитов которого необходимо получить.
//            - Строка      - полное имя предопределенного элемента, значения реквизитов которого необходимо получить.
//  ИмяРеквизита       - Строка - имя получаемого реквизита.
//  ВыбратьРазрешенные - Булево - если Истина, то запрос к объекту выполняется с учетом прав пользователя, и в случае,
//                                    - если есть ограничение на уровне записей, то возвращается Неопределено;
//                                    - если нет прав для работы с таблицей, то возникнет исключение.
//                              - если Ложь, то возникнет исключение при отсутствии прав на таблицу
//                                или любой из реквизитов.
//
// Возвращаемое значение:
//  Произвольный - зависит от типа значения прочитанного реквизита.
//               - если в параметр Ссылка передана пустая ссылка, то возвращается Неопределено.
//               - если в параметр Ссылка передана ссылка несуществующего объекта (битая ссылка), 
//                 то возвращается Неопределено.
//
Функция ЗначениеРеквизитаОбъекта(Ссылка, ИмяРеквизита, ВыбратьРазрешенные = Ложь) Экспорт

	Возврат UT_Common.ЗначениеРеквизитаОбъекта(Ссылка, ИмяРеквизита, ВыбратьРазрешенные);

КонецФункции

Функция ДанныеСохраненногоПароляПользователяИБ(ИмяПользователя) Экспорт
	Возврат UT_Users.StoredIBUserPasswordData(ИмяПользователя);
КонецФункции

Процедура УстановитьПарольПользователюИБ(ИмяПользователя, Пароль) Экспорт
	UT_Users.SetIBUserPassword(ИмяПользователя, Пароль);
КонецПроцедуры

Процедура ВосстановитьДанныеПользователяПослеЗапускаСеансаПодПользователем(ИмяПользователя,
	ДанныеСохраненногоПароляПользователяИБ) Экспорт
	UT_Users.RestoreUserDataAfterUserSessionStart(ИмяПользователя,
		ДанныеСохраненногоПароляПользователяИБ);
КонецПроцедуры

Процедура AddObjectsArrayToCompare(Объекты) Экспорт
	UT_Common.AddObjectsArrayToCompare(Объекты);
КонецПроцедуры

Процедура ВыгрузитьОбъектыВXMLНаСервере(МассивОбъектов, АдресФайлаВоВременномХранилище, ИдентфикаторФормы=Неопределено) Экспорт
	ОбработкаВыгрузки= Обработки.УИ_ВыгрузкаЗагрузкаДанныхXMLСФильтрами.Создать();
	ОбработкаВыгрузки.Инициализация();
	ОбработкаВыгрузки.ВыгружатьСДокументомЕгоДвижения=Истина;
	ОбработкаВыгрузки.ИспользоватьФорматFastInfoSet=Ложь;
	
	Для Каждого ТекОбъект Из МассивОбъектов Цикл
		НС=ОбработкаВыгрузки.ДополнительныеОбъектыДляВыгрузки.Добавить();
		НС.Объект=ТекОбъект;
		НС.ИмяОбъектаДляЗапроса=UT_Common.ИмяТаблицыПоСсылке(ТекОбъект);
	КонецЦикла;
		
	ИмяВременногоФайла = ПолучитьИмяВременногоФайла(".xml");
	
	ОбработкаВыгрузки.ВыполнитьВыгрузку(ИмяВременногоФайла, , Новый ТаблицаЗначений);
		
	Файл = Новый Файл(ИмяВременногоФайла);

	Если Файл.Существует() Тогда

		ДвоичныеДанные = Новый ДвоичныеДанные(ИмяВременногоФайла);
		АдресФайлаВоВременномХранилище = ПоместитьВоВременноеХранилище(ДвоичныеДанные, ИдентфикаторФормы);
		УдалитьФайлы(ИмяВременногоФайла);

	КонецЕсли;
	
КонецПроцедуры

// Convert (serializes) any value to XML-string.
// Converted to may be only those objects for which the syntax helper indicate that they are serialized.
// См. также ValueFromStringXML.
//
// Parameters:
//  Value  - Arbitrary  - value that you want to serialize into an XML string..
//
//  Return value:
//  String - XML-string.
//
Function ValueToXMLString(Value) Export

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);

	Return XMLWriter.Close();
EndFunction

// Выполняет преобразование (десериализацию) XML-строки в значение.
// См. также ValueToXMLString.
//
// Параметры:
//  СтрокаXML - Строка - XML-строка, с сериализованным объектом..
//
// Возвращаемое значение:
//  Произвольный - значение, полученное из переданной XML-строки.
//
Функция ЗначениеИзСтрокиXML(СтрокаXML, Тип = Неопределено) Экспорт

	ЧтениеXML = Новый ЧтениеXML;
	ЧтениеXML.УстановитьСтроку(СтрокаXML);

	Если Тип = Неопределено Тогда
		Возврат СериализаторXDTO.ПрочитатьXML(ЧтениеXML);
	Иначе
		Возврат СериализаторXDTO.ПрочитатьXML(ЧтениеXML, Тип);
	КонецЕсли;
КонецФункции

Функция АдресОписанияМетаданныхКонфигурации() Экспорт
	Возврат UT_Common.АдресОписанияМетаданныхКонфигурации();
КонецФункции

#Region JSON

Function mReadJSON(Value) Export
	Return UT_CommonClientServer.mReadJSON(Value);
EndFunction // ПрочитатьJSON()

Function mWriteJSON(DataStructure) Export
	Return UT_CommonClientServer.mWriteJSON(DataStructure);
EndFunction // WriteJSON(
#КонецОбласти



#Область ХранилищеНастроек

////////////////////////////////////////////////////////////////////////////////
// Сохранение, чтение и удаление настроек из хранилищ.

// Сохраняет настройку в хранилище общих настроек, как метод платформы Сохранить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, сохранение пропускается без ошибки.
//
// Параметры:
//   КлючОбъекта       - Строка           - см. синтакс-помощник платформы.
//   КлючНастроек      - Строка           - см. синтакс-помощник платформы.
//   Настройки         - Произвольный     - см. синтакс-помощник платформы.
//   ОписаниеНастроек  - ОписаниеНастроек - см. синтакс-помощник платформы.
//   ИмяПользователя   - Строка           - см. синтакс-помощник платформы.
//   ОбновитьПовторноИспользуемыеЗначения - Булево - выполнить одноименный метод платформы.
//
Процедура ХранилищеОбщихНастроекСохранить(КлючОбъекта, КлючНастроек, Настройки, ОписаниеНастроек = Неопределено,
	ИмяПользователя = Неопределено, ОбновитьПовторноИспользуемыеЗначения = Ложь) Экспорт

	UT_Common.ХранилищеОбщихНастроекСохранить(КлючОбъекта, КлючНастроек, Настройки, ОписаниеНастроек,
		ИмяПользователя, ОбновитьПовторноИспользуемыеЗначения);

КонецПроцедуры

// Сохраняет несколько настроек в хранилище общих настроек, как метод платформы Сохранить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, сохранение пропускается без ошибки.
// 
// Параметры:
//   НесколькоНастроек - Массив - со значениями:
//     * Значение - Структура - со свойствами:
//         * Объект    - Строка       - см. параметр КлючОбъекта  в синтакс-помощнике платформы.
//         * Настройка - Строка       - см. параметр КлючНастроек в синтакс-помощнике платформы.
//         * Значение  - Произвольный - см. параметр Настройки    в синтакс-помощнике платформы.
//
//   ОбновитьПовторноИспользуемыеЗначения - Булево - выполнить одноименный метод платформы.
//
Процедура ХранилищеОбщихНастроекСохранитьМассив(НесколькоНастроек, ОбновитьПовторноИспользуемыеЗначения = Ложь) Экспорт
	
	UT_Common.ХранилищеОбщихНастроекСохранитьМассив(НесколькоНастроек, ОбновитьПовторноИспользуемыеЗначения);

КонецПроцедуры

// Загружает настройку из хранилища общих настроек, как метод платформы Загрузить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Кроме того, возвращает указанное значение по умолчанию, если настройки не найдены.
// Если нет права СохранениеДанныхПользователя, возвращается значение по умолчанию без ошибки.
//
// В возвращаемом значении очищаются ссылки на несуществующий объект в базе данных, а именно
// - возвращаемая ссылка заменяется на указанное значение по умолчанию;
// - из данных типа Массив ссылки удаляются;
// - у данных типа Структура и Соответствие ключ не меняется, а значение устанавливается Неопределено;
// - анализ значений в данных типа Массив, Структура, Соответствие выполняется рекурсивно.
//
// Параметры:
//   КлючОбъекта          - Строка           - см. синтакс-помощник платформы.
//   КлючНастроек         - Строка           - см. синтакс-помощник платформы.
//   ЗначениеПоУмолчанию  - Произвольный     - значение, которое возвращается, если настройки не найдены.
//                                             Если не указано, возвращается значение Неопределено.
//   ОписаниеНастроек     - ОписаниеНастроек - см. синтакс-помощник платформы.
//   ИмяПользователя      - Строка           - см. синтакс-помощник платформы.
//
// Возвращаемое значение: 
//   Произвольный - см. синтакс-помощник платформы.
//
Функция ХранилищеОбщихНастроекЗагрузить(КлючОбъекта, КлючНастроек, ЗначениеПоУмолчанию = Неопределено,
	ОписаниеНастроек = Неопределено, ИмяПользователя = Неопределено) Экспорт
	Возврат UT_Common.ХранилищеОбщихНастроекЗагрузить(КлючОбъекта, КлючНастроек, ЗначениеПоУмолчанию,
		ОписаниеНастроек, ИмяПользователя)

КонецФункции

// Удаляет настройку из хранилища общих настроек, как метод платформы Удалить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, удаление пропускается без ошибки.
//
// Параметры:
//   КлючОбъекта     - Строка, Неопределено - см. синтакс-помощник платформы.
//   КлючНастроек    - Строка, Неопределено - см. синтакс-помощник платформы.
//   ИмяПользователя - Строка, Неопределено - см. синтакс-помощник платформы.
//
Процедура ХранилищеОбщихНастроекУдалить(КлючОбъекта, КлючНастроек, ИмяПользователя) Экспорт

	UT_Common.ХранилищеОбщихНастроекУдалить(КлючОбъекта, КлючНастроек, ИмяПользователя);

КонецПроцедуры

// Сохраняет настройку в хранилище системных настроек, как метод платформы Сохранить
// объекта СтандартноеХранилищеНастроекМенеджер, но с поддержкой длины ключа настроек
// более 128 символов путем хеширования части, которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, сохранение пропускается без ошибки.
//
// Параметры:
//   КлючОбъекта       - Строка           - см. синтакс-помощник платформы.
//   КлючНастроек      - Строка           - см. синтакс-помощник платформы.
//   Настройки         - Произвольный     - см. синтакс-помощник платформы.
//   ОписаниеНастроек  - ОписаниеНастроек - см. синтакс-помощник платформы.
//   ИмяПользователя   - Строка           - см. синтакс-помощник платформы.
//   ОбновитьПовторноИспользуемыеЗначения - Булево - выполнить одноименный метод платформы.
//
Процедура ХранилищеСистемныхНастроекСохранить(КлючОбъекта, КлючНастроек, Настройки, ОписаниеНастроек = Неопределено,
	ИмяПользователя = Неопределено, ОбновитьПовторноИспользуемыеЗначения = Ложь) Экспорт

	UT_Common.ХранилищеСистемныхНастроекСохранить(КлючОбъекта, КлючНастроек, Настройки, ОписаниеНастроек,
		ИмяПользователя, ОбновитьПовторноИспользуемыеЗначения);

КонецПроцедуры

// Загружает настройку из хранилища системных настроек, как метод платформы Загрузить,
// объекта СтандартноеХранилищеНастроекМенеджер, но с поддержкой длины ключа настроек
// более 128 символов путем хеширования части, которая превышает 96 символов.
// Кроме того, возвращает указанное значение по умолчанию, если настройки не найдены.
// Если нет права СохранениеДанныхПользователя, возвращается значение по умолчанию без ошибки.
//
// В возвращаемом значении очищаются ссылки на несуществующий объект в базе данных, а именно:
// - возвращаемая ссылка заменяется на указанное значение по умолчанию;
// - из данных типа Массив ссылки удаляются;
// - у данных типа Структура и Соответствие ключ не меняется, а значение устанавливается Неопределено;
// - анализ значений в данных типа Массив, Структура, Соответствие выполняется рекурсивно.
//
// Параметры:
//   КлючОбъекта          - Строка           - см. синтакс-помощник платформы.
//   КлючНастроек         - Строка           - см. синтакс-помощник платформы.
//   ЗначениеПоУмолчанию  - Произвольный     - значение, которое возвращается, если настройки не найдены.
//                                             Если не указано, возвращается значение Неопределено.
//   ОписаниеНастроек     - ОписаниеНастроек - см. синтакс-помощник платформы.
//   ИмяПользователя      - Строка           - см. синтакс-помощник платформы.
//
// Возвращаемое значение: 
//   Произвольный - см. синтакс-помощник платформы.
//
Функция ХранилищеСистемныхНастроекЗагрузить(КлючОбъекта, КлючНастроек, ЗначениеПоУмолчанию = Неопределено,
	ОписаниеНастроек = Неопределено, ИмяПользователя = Неопределено) Экспорт

	Возврат UT_Common.ХранилищеСистемныхНастроекЗагрузить(КлючОбъекта, КлючНастроек, ЗначениеПоУмолчанию,
		ОписаниеНастроек, ИмяПользователя);

КонецФункции

// Удаляет настройку из хранилища системных настроек, как метод платформы Удалить,
// объекта СтандартноеХранилищеНастроекМенеджер, но с поддержкой длины ключа настроек
// более 128 символов путем хеширования части, которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, удаление пропускается без ошибки.
//
// Параметры:
//   КлючОбъекта     - Строка, Неопределено - см. синтакс-помощник платформы.
//   КлючНастроек    - Строка, Неопределено - см. синтакс-помощник платформы.
//   ИмяПользователя - Строка, Неопределено - см. синтакс-помощник платформы.
//
Процедура ХранилищеСистемныхНастроекУдалить(КлючОбъекта, КлючНастроек, ИмяПользователя) Экспорт

	UT_Common.ХранилищеСистемныхНастроекУдалить(КлючОбъекта, КлючНастроек, ИмяПользователя);

КонецПроцедуры

// Сохраняет настройку в хранилище настроек данных форм, как метод платформы Сохранить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, сохранение пропускается без ошибки.
//
// Параметры:
//   КлючОбъекта       - Строка           - см. синтакс-помощник платформы.
//   КлючНастроек      - Строка           - см. синтакс-помощник платформы.
//   Настройки         - Произвольный     - см. синтакс-помощник платформы.
//   ОписаниеНастроек  - ОписаниеНастроек - см. синтакс-помощник платформы.
//   ИмяПользователя   - Строка           - см. синтакс-помощник платформы.
//   ОбновитьПовторноИспользуемыеЗначения - Булево - выполнить одноименный метод платформы.
//
Процедура ХранилищеНастроекДанныхФормСохранить(КлючОбъекта, КлючНастроек, Настройки, ОписаниеНастроек = Неопределено,
	ИмяПользователя = Неопределено, ОбновитьПовторноИспользуемыеЗначения = Ложь) Экспорт

	UT_Common.ХранилищеНастроекДанныхФормСохранить(КлючОбъекта, КлючНастроек, Настройки, ОписаниеНастроек,
		ИмяПользователя, ОбновитьПовторноИспользуемыеЗначения);

КонецПроцедуры

// Загружает настройку из хранилища настроек данных форм, как метод платформы Загрузить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Кроме того, возвращает указанное значение по умолчанию, если настройки не найдены.
// Если нет права СохранениеДанныхПользователя, возвращается значение по умолчанию без ошибки.
//
// В возвращаемом значении очищаются ссылки на несуществующий объект в базе данных, а именно
// - возвращаемая ссылка заменяется на указанное значение по умолчанию;
// - из данных типа Массив ссылки удаляются;
// - у данных типа Структура и Соответствие ключ не меняется, а значение устанавливается Неопределено;
// - анализ значений в данных типа Массив, Структура, Соответствие выполняется рекурсивно.
//
// Параметры:
//   КлючОбъекта          - Строка           - см. синтакс-помощник платформы.
//   КлючНастроек         - Строка           - см. синтакс-помощник платформы.
//   ЗначениеПоУмолчанию  - Произвольный     - значение, которое возвращается, если настройки не найдены.
//                                             Если не указано, возвращается значение Неопределено.
//   ОписаниеНастроек     - ОписаниеНастроек - см. синтакс-помощник платформы.
//   ИмяПользователя      - Строка           - см. синтакс-помощник платформы.
//
// Возвращаемое значение: 
//   Произвольный - см. синтакс-помощник платформы.
//
Функция ХранилищеНастроекДанныхФормЗагрузить(КлючОбъекта, КлючНастроек, ЗначениеПоУмолчанию = Неопределено,
	ОписаниеНастроек = Неопределено, ИмяПользователя = Неопределено) Экспорт

	Возврат UT_Common.ХранилищеНастроекДанныхФормЗагрузить(КлючОбъекта, КлючНастроек, ЗначениеПоУмолчанию,
		ОписаниеНастроек, ИмяПользователя);

КонецФункции

// Удаляет настройку из хранилища настроек данных форм, как метод платформы Удалить,
// объектов СтандартноеХранилищеНастроекМенеджер или ХранилищеНастроекМенеджер.<Имя хранилища>,
// но с поддержкой длины ключа настроек более 128 символов путем хеширования части,
// которая превышает 96 символов.
// Если нет права СохранениеДанныхПользователя, удаление пропускается без ошибки.
//
// Параметры:
//   КлючОбъекта     - Строка, Неопределено - см. синтакс-помощник платформы.
//   КлючНастроек    - Строка, Неопределено - см. синтакс-помощник платформы.
//   ИмяПользователя - Строка, Неопределено - см. синтакс-помощник платформы.
//
Процедура ХранилищеНастроекДанныхФормУдалить(КлючОбъекта, КлючНастроек, ИмяПользователя) Экспорт

	UT_Common.ХранилищеНастроекДанныхФормУдалить(КлючОбъекта, КлючНастроек, ИмяПользователя);

КонецПроцедуры

#КонецОбласти

#Область Алгоритмы

Функция ПолучитьСсылкуСправочникАлгоритмы(Алгоритм) Экспорт
	Возврат UT_Common.ПолучитьСсылкуСправочникАлгоритмы(Алгоритм);
КонецФункции

Функция ВыполнитьАлгоритм(АлгоритмСсылка, ВходящиеПараметры = Неопределено, ОшибкаВыполнения = Ложь,
	СообщениеОбОшибке = "") Экспорт
	Возврат UT_Common.ВыполнитьАлгоритм(АлгоритмСсылка, ВходящиеПараметры, ОшибкаВыполнения,
		СообщениеОбОшибке);
КонецФункции

#КонецОбласти

#Область Отладка

Функция SaveDebuggingDataToStorage(ТипОбъектаОтладки, ДанныеДляОтладки) Экспорт
	КлючНастроек=ТипОбъектаОтладки + "/" + ИмяПользователя() + "/" + Формат(ТекущаяДата(), "ДФ=yyyyMMddHHmmss;");
	КлючОбъектаДанныхОтладки=UT_CommonClientServer.DebuggingDataObjectDataKeyInSettingsStorage();

	UT_Common.ХранилищеСистемныхНастроекСохранить(КлючОбъектаДанныхОтладки, КлючНастроек, ДанныеДляОтладки);

	Возврат "Запись выполнена успешно. Ключ настроек " + КлючНастроек;
КонецФункции

Функция СтруктураДанныхОбъектаОтладкиИзСправочникаДанныхОтладки(СсылкаНаДанные) Экспорт
	Результат = Новый Структура;
	Результат.Вставить("ТипОбъектаОтладки", СсылкаНаДанные.ТипОбъектаОтладки);
	Результат.Вставить("АдресОбъектаОтладки", ПоместитьВоВременноеХранилище(
		СсылкаНаДанные.ХранилищеОбъектаОтладки.Получить()));

	Возврат Результат;
КонецФункции

Функция СтруктураДанныхОбъектаОтладкиИзСистемногоХранилищаНастроек(КлючНастроек, ИдентификаторФормы=Неопределено) Экспорт
	КлючОбъектаДанныхОтладки=UT_CommonClientServer.DebuggingDataObjectDataKeyInSettingsStorage();
	НастройкиОтладки=UT_Common.ХранилищеСистемныхНастроекЗагрузить(КлючОбъектаДанныхОтладки, КлючНастроек);

	Если НастройкиОтладки = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;

	МассивПодСтрокКлюча=СтрРазделить(КлючНастроек, "/");

	Если ИдентификаторФормы=Неопределено Тогда
		АдресОбъектаОтладки=ПоместитьВоВременноеХранилище(НастройкиОтладки);
	Иначе
		АдресОбъектаОтладки=ПоместитьВоВременноеХранилище(НастройкиОтладки, ИдентификаторФормы);
	КонецЕсли;

	Результат = Новый Структура;
	Результат.Вставить("ТипОбъектаОтладки", МассивПодСтрокКлюча[0]);
	Результат.Вставить("АдресОбъектаОтладки", АдресОбъектаОтладки);

	Возврат Результат;
КонецФункции

Function SerializeDCSForDebug(DCS, DcsSettings, ExternalDataSets) Export
	ObjectStructure = New Structure;

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, DCS, "dataCompositionSchema",
		"http://v8.1c.ru/8.1/data-composition-system/schema");

	ObjectStructure.Insert("DCSText", XMLWriter.Close());

	If DcsSettings = Undefined Then
		Settings=DCS.DefaultSettings;
	Else
		Settings=DcsSettings;
	EndIf;

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Settings, "Settings",
		"http://v8.1c.ru/8.1/data-composition-system/settings");
	ObjectStructure.Insert("DcsSettingsText", XMLWriter.Close());

	If TypeOf(ExternalDataSets) = Type("Structure") Then
		Sets = New Structure;

		For Each KeyValue In ExternalDataSets Do
			If TypeOf(KeyValue.Value) <> Type("ValueTable") Then
				Continue;
			EndIf;

			Sets.Insert(KeyValue.Key, ValueToStringInternal(KeyValue.Value));
		EndDo;

		If Sets.Count() > 0 Then
			ObjectStructure.Insert("ExternalDataSets", Sets);
		EndIf;
	EndIf;

	Return ObjectStructure;

EndFunction

Function TempTablesManagerTempTablesStructure(TempTablesManager) Экспорт
	TempTablesStructure = New Structure;
	For each TempTable In TempTablesManager.Tables Do
		TempTablesStructure.Insert(TempTable.FullName, TempTable.GetData().Unload());
	EndDo;

	Return TempTablesStructure;
EndFunction

//https://infostart.ru/public/1207287/
Функция ВыполнитьСравнениеДвухТаблицЗначений(ТаблицаБазовая, ТаблицаСравнения, СписокКолонокСравнения) Экспорт
	СписокКолонок = UT_StringFunctionsClientServer.РазложитьСтрокуВМассивПодстрок(СписокКолонокСравнения, ",", Истина);
	//Результирующая таблица
	ВременнаяТаблица = Новый ТаблицаЗначений;
	Для Каждого Колонка Из СписокКолонок Цикл
		ВременнаяТаблица.Колонки.Добавить(Колонка);
		ВременнаяТаблица.Колонки.Добавить(Колонка + "Сравнение");
	КонецЦикла;
	ВременнаяТаблица.Колонки.Добавить("НомерСтр");
	ВременнаяТаблица.Колонки.Добавить("НомерСтр" + "Сравнение");
	//---------
	СравниваемаяТаблица = ТаблицаСравнения.Скопировать();
	СравниваемаяТаблица.Колонки.Добавить("УжеИспользуем", Новый ОписаниеТипов("Булево"));

	Для Каждого Строка Из ТаблицаБазовая Цикл
		НоваяСтрока = ВременнаяТаблица.Добавить();
		ЗаполнитьЗначенияСвойств(НоваяСтрока, Строка);
		НоваяСтрока.НомерСтр = Строка.НомерСтроки;
		//формируем структуру для поиска по заданному сопоставлению
		ОтборДляПоискаСтрок = Новый Структура("УжеИспользуем", Ложь);
		Для Каждого Колонка Из СписокКолонок Цикл
			ОтборДляПоискаСтрок.Вставить(Колонка, Строка[Колонка]);
		КонецЦикла;

		НайдемСтроки = СравниваемаяТаблица.НайтиСтроки(ОтборДляПоискаСтрок);
		Если НайдемСтроки.Количество() > 0 Тогда
			СтрокаСопоставления = НайдемСтроки[0];
			НоваяСтрока.НомерСтрСравнение = СтрокаСопоставления.НомерСтроки;
			Для Каждого Колонка Из СписокКолонок Цикл
				Реквизит = Колонка + "Сравнение";
				НоваяСтрока[Реквизит] = СтрокаСопоставления[Колонка];
			КонецЦикла;
			СтрокаСопоставления.УжеИспользуем = Истина;
		КонецЕсли;
	КонецЦикла;
	//Смотрим что осталось +++
	ОтборДляПоискаСтрок = Новый Структура("УжеИспользуем", Ложь);
	НайдемСтроки = СравниваемаяТаблица.НайтиСтроки(ОтборДляПоискаСтрок);
	Для Каждого Строка Из НайдемСтроки Цикл
		НоваяСтрока = ВременнаяТаблица.Добавить();
		НоваяСтрока.НомерСтрСравнение = Строка.НомерСтроки;
		Для Каждого Колонка Из СписокКолонок Цикл
			Реквизит = Колонка + "Сравнение";
			НоваяСтрока[Реквизит] = Строка[Колонка];
		КонецЦикла;
	КонецЦикла;
	//Проверяем что получилось
	ТаблицыИдентичны = Истина;
	Для Каждого Строка Из ВременнаяТаблица Цикл
		Для Каждого Колонка Из СписокКолонок Цикл
			Если (Не ЗначениеЗаполнено(Строка[Колонка])) Или (Не ЗначениеЗаполнено(Строка[Колонка + "Сравнение"])) Тогда
				ТаблицыИдентичны = Ложь;
				Прервать;
			КонецЕсли;
		КонецЦикла;
		Если Не ТаблицыИдентичны Тогда
			Прервать;
		КонецЕсли;
	КонецЦикла;

	Возврат Новый Структура("ИдентичныеТаблицы,ТаблицаРасхождений", ТаблицыИдентичны, ВременнаяТаблица);
КонецФункции

#КонецОбласти

#Область СохранениеЧтениеДанныхКонсолей

Функция ПодготовленныеДанныеКонсолиДляЗаписиВФайл(ИмяКонсоли, ИмяФайла, АдресДанныхСохранения,
	СтруктураОписанияСохраняемогоФайла) Экспорт
	Файл=Новый Файл(ИмяФайла);

	Если ЭтоАдресВременногоХранилища(АдресДанныхСохранения) Тогда
		ДанныеСохранения=ПолучитьИзВременногоХранилища(АдресДанныхСохранения);
	Иначе
		ДанныеСохранения=АдресДанныхСохранения;
	КонецЕсли;

	Если ВРег(ИмяКонсоли) = "КОНСОЛЬHTTPЗАПРОСОВ" Тогда
		МенеджерКонсоли=Обработки.УИ_КонсольHTTPЗапросов;
	Иначе
		МенеджерКонсоли=Неопределено;
	КонецЕсли;

	Если МенеджерКонсоли = Неопределено Тогда
		Если ТипЗнч(ДанныеСохранения) = Тип("Строка") Тогда
			НовыеДанныеСохранения=ДанныеСохранения;
		Иначе
			НовыеДанныеСохранения=ЗначениеВСтрокуВнутр(ДанныеСохранения);
		КонецЕсли;
	Иначе
		Попытка
			НовыеДанныеСохранения=МенеджерКонсоли.СериализованныеДанныеСохранения(Файл.Расширение, ДанныеСохранения);
		Исключение
			НовыеДанныеСохранения=ЗначениеВСтрокуВнутр(ДанныеСохранения);
		КонецПопытки;
	КонецЕсли;

	Поток=Новый ПотокВПамяти;
	ЗаписьТекста=Новый ЗаписьДанных(Поток);
	ЗаписьТекста.ЗаписатьСтроку(НовыеДанныеСохранения);

	Возврат ПоместитьВоВременноеХранилище(Поток.ЗакрытьИПолучитьДвоичныеДанные());
	
//	Возврат НовыеДанныеСохранения;	

КонецФункции

#КонецОбласти