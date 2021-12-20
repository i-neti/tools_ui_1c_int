# Universal Tools  1С for managed forms

[![Quality Gate Status](https://sonar.openbsl.ru/api/project_badges/measure?project=tools_ui_1c&metric=alert_status)](https://sonar.openbsl.ru/dashboard?id=tools_ui_1c) 
[![Join telegram chat](https://img.shields.io/badge/chat-telegram-blue?style=flat&logo=telegram)](https://t.me/tools_ui_1c) 
[![Last release](https://img.shields.io/github/v/release/cpr1c/tools_ui_1c?include_prereleases&label=last%20release&style=badge)](https://github.com/cpr1c/tools_ui_1c/releases/latest)
[![download](https://img.shields.io/github/downloads/cpr1c/tools_ui_1c/total)](https://github.com/cpr1c/tools_ui_1c/releases/latest/download/UI.cfe)
[![GitHub issues](https://img.shields.io/github/issues-raw/i-neti/tools_ui_1c_international?style=badge)](https://github.com/i-neti/tools_ui_1c_international/issues)
[![License](https://img.shields.io/github/license/cpr1c/tools_ui_1c?style=badge)](https://github.com/cpr1c/tools_ui_1c/blob/master/LICENSE)

[RUSSIAN VERSION OF THIS DOCUMENT](https://github.com/i-neti/tools_ui_1c_international/blob/develop/README_RU.md)

[Подержать проект](#донаты-и-поддержка-проекта)
### Supported operating systems
* Windows x86
* Windows x64
* Linux x64
* Linux x86

It should work on Mac OS, but has not been tested

### Supported client applications

* Thick client managed application
* Thin client
* Web client(partially)

### Supported configuration modes
The module is being developed based on the disabled support for modality and synchronous calls. It should work in all modern and not so configurations

### Supported platforms
8.3.12 and later

###  Distribution method and license
The subsystem is developed and distributed under the GNU General Public License v3.0. The code is open, you can copy and distribute to anyone, but also with open source sharing.

### Currently contains tools:

- **Group processing  of catalogs and documents**- ## ЗАМЕНИТЬ ОПИСАНИЕ Similar to typical Data Processor from 1C from ITS  (ИТС) disk
- **Constant Editor** - allows you to edit the values of constants in table mode
- **Database Storage Structure**- View table names and their relationships with metadata objects.
- **Removal of marked objects**-  a copy of the standard Data Processor from the SSL (Standart Subsystems Library), adapted for use outside the SSL (Standart Subsystems Library)
- **Query Console**- Data processor for developing and executing queries without writing additional processing. Fork of https://github.com/hal9000cc/RequestConsole9000. [GPL3 License](https://github.com/hal9000cc/RequestConsole9000/blob/master/LICENSE)
- **Консоль заданий**- view and set parametrs of scheduled  and background jobs. Fork of https://github.com/kuzyara/JobsConsole2019.epf [Author's permission](https://github.com/kuzyara/JobsConsole2019.epf/issues/6)
- **Registration of changes for exchange**- ## ЗАМЕНИТЬ ОПИСАНИЕ Fork Data Processor from ITS disk with adaptations to the subsystem
- **Search and removal of duplicates**- A fork of the standard Data Processor from the SSL (Standart Subsystems Library), to which several parameters for performing the replacement have been added
- **Code Console**- Allows you to execute code from the enterprise without creating external Data Processor. There is syntax highlighting and a minimal contextual hint
- **Поиск ссылок на объект**- аналог стандартной обработки из меню "Все функции". 
- **Редактор реквизитов объекта**- позволяет низкоуровневое редактирование ссылочных объектов. Поддерживает редактирование движений документа. Форк обработки https://infostart.ru/public/983887/. Вырезана из https://infostart.ru/public/938606/. [Author's permission](http://forum.infostart.ru/forum24/topic203301/message2375899/#message2375899)
- **Консоль отчетов**- переработанная консоль компоновок с диска ИТС. Теперь ей удобнее пользоваться
- **Динамический список**- удобный просмотр списков таблиц базы из одной обработки
- **Консоль HTTP запросов**-  позволяет из 1С делать HTTP запросы. 
- **Выгрузка загрука XML с фильтрами** - Перенос информации между однородными базами данных. Форк обработки https://infostart.ru/public/1149722/ [Author's permission](http://forum.infostart.ru/forum15/topic229143/message2372663/#message2372663)
- **Навигатор по конфигурации**- Data Processor замена стандартному меню "Все функции". Здесь же дополнительные административные фукнции будут. Форк https://infostart.ru/public/931586/. [Author's permission](http://forum.infostart.ru/forum9/topic202659/message2375904/#message2375904)
- **Файловый менеджер** - Data Processor для удобной работы с файлами между клиентом и сервером. Передача, просмотр, удаление. На текущий момент содержит синхронные вызовы. Форк https://infostart.ru/public/1027326/. [Author's permission](https://github.com/cpr1c/tools_ui_1c/issues/108)
- **Конструктор регулярных выражений**-  позволяет строить сложно-структурированные выражения на основе параметрического описания, тестировать их, и в результате получить программный код 1С. На текущий момент работает только в Windows. Форк https://infostart.ru/public/592108/. [Author's permission](http://forum.infostart.ru/forum9/topic167495/message2389269/#message2389269)
- **Консоль вебсервисов** -Data Processor для чтения и выполнения веб-сервисов на платформе 1С: Предприятие 8.3. Аналог soapUI. Обработка позволяет выполнить операцию веб-сервиса и отобразить результат в виде xml или дерева. Форк  https://github.com/ghostaz/WSReader2.git. [Лицензия GPL3](https://github.com/ghostaz/WSReader2/blob/master/LICENSE)
- **Консоль сравнения данных**- предназначена для сравнения данных, полученных из разных источников данных: информационных баз 1С 8, 1С 7.7, баз данных SQL, файлов формата CSV/TXT/DBF/XLS/DOC/XML, строки JSON, вручную заполненного табличного документа. Форк https://infostart.ru/public/581794. [Author's permission](http://forum.infostart.ru/forum9/topic165873/message2373325/#message2373325)
- **Информация о лицензиях 1С**-представляющая из себя обертку функций Утилиты лицензирования 1С (ring) в понятном для обычного человека виде. По сути, это GUI утилиты RING. Форк  https://infostart.ru/public/1124442/. [Author's permission](http://forum.infostart.ru/forum9/topic226186/message2389245/#message2389245). Для работы должна быть установлена утилита ring и ее модули license
- **Загрузка данных из табличного докумнета**-Data Processor предназначена для загрузки данных в справочники и табличные части различных объектов из табличного документа. Форк обработки  https://infostart.ru/public/269425/. [Author's permission](http://forum.infostart.ru/forum15/topic107643/message2397121/#message2397121) 
- **Редактор JSON**- Позволяет в удобной форме редактировать строки JSON. Содержит подсветку синтаксиса JSON, редактирование в виде дерева, некоторые автоподстановки. Редактор реализован на основании библиотеки https://github.com/josdejong/jsoneditor. В Windows работает, начиная с версии платформы 8.3.14
- **Редактор HTML**- Быстрая отладка отображения HTML страниц в 1С. Представляет собой экран разбитый на 4 части, в левой части три редактора-тела HTML, CSS и JavaScript, а право - поле результата. Есть контекстная подсказка и автодополнение кода. Для редкторов кода используется библиотека https://ace.c9.io/. Незаменим, при тестировании вывода HTML в 1С, т.к. даже с платформы 8.3.14 отображение в браузере и 1С, а также в разных операционных системах может сильно отличаться. В Windows работает, начиная с версии платформы 8.3.14. [Публикация на infostart](https://infostart.ru/public/1273525/) 
- **Универсальный обмен данными в формате XML (с фильтрами и прямой загрузкой через HTTP сервис)** - Выгрузка и загрузка по правилам обмена. Форк стандартной Data Processor от 1С и https://infostart.ru/public/1176839/. [Author's permission](https://github.com/cpr1c/tools_ui_1c/issues/139). Добавлена возможность накладывать фильтры на выгружаемые объеты, и прямая выгрузка в базу через http сервис универсальных инструментов.  
- **Редактор СКД**- Аналог конструктора схемы компоновки данных для тонкого клиента. На текущий момент не поддерживает редактирование макетов и вложенных схема.
- **Сравнение объектов** - Сравнение по-реквизитно ссылочных объектов с выводом в табличный документ. Форк https://infostart.ru/public/1240803/. [Author's permission](https://github.com/cpr1c/tools_ui_1c/issues/246)
- **Библиотека сериализации 1С**- Набор процедур и функций для сериализации/десериализации данных 1С и объектов СКД в простые структуры данных (Структура, соответствие, массив). Форк https://github.com/arkuznetsov/SerLib1C. [Лицензия MPL-2.0 License](https://github.com/arkuznetsov/SerLib1C/blob/master/LICENSE)
- **Коннектор: удобный HTTP-клиент для 1С:Предприятие 8** - В мире python очень популярна библиотека для работы с HTTP запросами - [Requests](http://docs.python-requests.org/en/master) (автор: Kenneth Reitz). Библиотека берет на себя всю рутину работы с HTTP запросами. Буквально в одну строку можно получать данные, отправлять, не заботясь о необходимости конструирования URL, кодирования данных и т.п. В общем библиотека очень мощная и проста в использовании. **Коннектор** - это "Requests" для мира 1С. Форк https://github.com/vbondarevsky/Connector. [Лицензия Apache-2.0](https://github.com/vbondarevsky/Connector/blob/master/LICENSE)

# Интеграция с библиотекой стандартных подсистем (БСП)

1. Есть возможность удобной отладки дополнительных отчетов и обраток. Подробнее в [wiki](https://github.com/cpr1c/tools_ui_1c/wiki/Отладка-внешних-обработок-БСП)
1. В списки и формы объектов добавляется подменю "Инструменты", которое содержит пункты(Формы должны быть подключены к подсистеме "Подключаемые команды"):
	* **Добавить к сравнению** - добавляет выледенные объекты к сравнению для дальнейшего использования в инструменте "Сравнение объектов"
	* **Редактировать объект** - Позволяет текущий объект открыть в редакторе реквизитов
	* **Сравнить объекты** - Открывает инструмент "Сравнение объектов" с выделенными ссылками в качестве объектов сравнения. Доступно только для списков
    * **Найти ссылки на объект** - Открывает инструмент "Поиск ссылок на объект" для текущего объекта
    * **Выгрузить объекты в XML** - Выполняет выгрузку выбранных объектов с подчиненными ссылками с использованием инструмента "Выгрузка загрузка XML"


# Программный интерфейс

## Библиотека Коннектор: удобный HTTP-клиент для 1С:Предприятие 8

Доступна программно через общий модуль **УИ_КоннекторHTTP**. Подробное описание смотрите на странице библиотеки https://github.com/vbondarevsky/Connector

Пример использования:

`Результат = КоннекторHTTP.GetJson("https://api.github.com/events");`

## Библиотека сериализации 1С

Доступна программно через обработку **УИ_ПреобразованиеДанныхJSON**. Подробное описание методов смотрите на странице библиотеки https://github.com/arkuznetsov/SerLib1C

Инициализация:

`Сериализатор1С = Обработки.УИ_ПреобразованиеДанныхJSON.Создать()` 
 
Пример использования: 
 
```bsl
СериализаторJSON=Обработки.УИ_ПреобразованиеДанныхJSON.Создать();

СтруктураИстории=СериализаторJSON.ЗначениеВСтруктуру(ДанныеСохранения);
СериализуемаяСтрокаJSON=СериализаторJSON.ЗаписатьОписаниеОбъектаВJSON(СтруктураИстории);
``` 
## Работа с буфером обмена ОС

Доступна программно через модуль **УИ_БуферОбменаКлиент**. Описание методов в коде. Поддерживается синхронный и асинхронный режим работы. https://github.com/cpr1c/clipboard_1c


Пример использования: 
```bsl
УИ_БуферОбменаКлиент.КопироватьСтрокуВБуфер("Моя строка для копирования в буфер обмена");
``` 

## Работа с регулярными выражениями

Доступна программно через модуль **УИ_РегулярныеВыраженияКлиентСервер**. Описание методов в коде. Поддерживается синхронный и асинхронный режим работы. https://github.com/cpr1c/RegEx1C_cfe


Пример использования: 
```bsl
УИ_РегулярныеВыраженияКлиентСервер.Совпадает("Hello world", "([A-Za-z]+)\s+([a-z]+)"); //Истина
``` 

 
## Получение структуры виртуальных таблиц запроса или менеджера временных таблиц

Необходимо в форме вычисления выражения вызвать функцию **УИ_._ВТ(ЗапросИЛИМенеджерВременныхТаблиц)**. 

Примеры использования: 

`УИ_._ВТ(Запрос)`

`УИ_._ВТ(Запрос.МенеджерВременныхТаблиц)`

## Сравнение двух таблиц значений

Необходимо в форме вычисления выражения вызвать функцию **_ТЗСр(ТаблицаБазовая, ТаблицаСравнения, СписокКолонок)**. 

Примеры использования: 

`УИ_._ТЗСр(ТаблицаБазовая, ТаблицаСравнения)` - выполнит сравнение по всем колонкам параметра ТаблицаБазовая

`УИ_._ТЗСр(ТаблицаБазовая, ТаблицаСравнения, "Номенклатура,Количество")`

## Сериализация XML в простые структуры данных(массив, структура, соответствие)

Необходимо в форме вычисления выражения вызвать функцию **_XMLОбъект(ПутьЧтения, УпроститьЭлементы)**. 

Примеры использования: 

`УИ_._XMLОбъект(ЧтениеXML)` - выполнит обход сущществующего объекта ЧтениеXML

`УИ_._XMLОбъект("C:\1.xml")` - выполнит чтение в структуры файла

`УИ_._XMLОбъект(Поток)` - выполнит чтение в структуры потока

`УИ_._XMLОбъект("C:\1.xml", Ложь)` - выполнит чтение в структуры файла без упрощения полученных структур

# Отладка
[Особенности использования отладки в портативной поставке](https://github.com/cpr1c/tools_ui_1c/wiki/Особенности-использования-отладки-в-портативном-варианте)
### Вызов

Необходимо в форме вычисления выражения вызвать функцию **УИ_._От(ВашаПеременнаяОбъектаОтладки,НастройкиСКД)**. Где вместо ВашаПеременнаяОбъектаОтладки нужно передать переменную, содержащую один из доступных к отладке объектов

### Логика работы

Если контекст запуска отладки является толстым клиентом открытие формы консоли происходит сразу по окончании выполнения вызова кода

Если отладка вызывается в контексте сервера или тонкого или веб клиента, необходимая информация сохраняется в справочник **Данные для отладки**. В таком случае вызов отладки проиходит потом из списка справочника "Данные для отладки". 


### Поддерживается отладка объектов:

* **Запрос**- на текущий момент отлаживаются запросы без менеджеров временных таблиц. 
Вызов отладки 

`УИ_._От(Запрос)`

* **Схема компоновки данных**- поддерживается отладка без внешних источников данных. 

Вызов отладки

`УИ_._От(СхемаКомпоновкиДанных,НастройкиСКД)` - будет вызвана отладка с переданными настройками

`УИ_._От(СхемаКомпоновкиДанных)` - будет вызвана отладка с настройками по умолчанию для СКД

`УИ_._От(СхемаКомпоновкиДанных,НастройкиСКД, ВнешниеНаборыДанных)` - будет вызвана отладка с переданными настройками и внешними наборами данных

* **Ссылочный объект базы**- просмотр и редактирование ссылки БД

Вызов отладки

`УИ_._от(СсылкаНаОбъектБД)`

* **HTTP Запрос**- поддерживается отладка строкового и файлового содержимого запросов, а также прокси

Выззов отладки

`УИ_._От(HTTPЗапрос,СоединениеHTTP)`

# Сборка в бинарные файлы

Зависимости сборки теперь находятся в файле packagedef, в папке build для установки зависимостей необходимо выполнить команду
`opm install`  находясь в корне проекта

В корне репозитория вызвать файл сценария 

* **build.sh** - для Linux
* **build.bat** - для Windows

Доступные параметры сборки:
  * **--platformSource**  - Каталог установки платформы для выполнения сборки
  * **--versionEDT** - Версия EDT для выполнения конвертации. Для запуска через утилиту ring. Необходимо указывать, если в системе установлено более одной версии 1C:EDT
  * **--cfe** - Формировать сборку в формате Расширения
  * **--cf** - Формировать сборку в виде конфигурации
   
Пример 
`./build.sh ----platformSource=/opt/1cv8/x86_64/8.3.12.1924 --versionEDT=edt@2020.6.0`

# Развитие инструментов

Разработка ведется в 1С:EDT

Замечания и предложения оставляйте в разделе **issues**. 

Если кто хочет поучаствовать - добро пожаловать. Больше идей- лучше конечное решение. Перед началом прочитайте [инструкцию для легкого старта](https://github.com/cpr1c/tools_ui_1c/tree/develop/docs/contributing) 

# Donation and project support

Поддержать проект деньгой можно по ссылке https://donate.stream/ya410011848843350

**Все собранные средства пойдут ИСКЛЮЧИТЕЛЬНО на развитие проекта и никуда более**

# Ссылки на инструмены так или иначе участвовавшие в проекте
* https://github.com/khorevaa/xml-parser- была основной для фукнции чтения XML в простые структуры данных
* https://github.com/pm74/_37583.git- На ее основе реализовывается механизм алгоритмов(хотя пока и не доделан)
* https://github.com/partizand/debug_external_dataprocessor - Основа для разработки поддержки отладки внешних обработок БСП
* https://github.com/salexdv/bsl_console - Редактор кода 1С - Monaco
