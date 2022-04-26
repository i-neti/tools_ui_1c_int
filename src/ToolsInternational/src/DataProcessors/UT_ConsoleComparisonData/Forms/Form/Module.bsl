&AtClient
Var ЗакрытиеФормыПодтверждено;

#Region Процедуры_и_функции

#Region Основные
&AtServer
Procedure CompareDataOnServer(СтруктураПараметровОтКлиента, ТекстОшибок)

	//If источник А - файл, хранящийся на клиентском компьютере
	If Object.BaseTypeA = 3 And Object.ConnectingToExternalBaseADeviceStorageFile = 1 Then
		//Save пути к исходному файлу
		PathToFileAatKlient = Object.ConnectionToExternalBaseAPathToFile;
		//Creating временного файла на сервере
		ФайлА = GetFromTempStorage(СтруктураПараметровОтКлиента.АдресВременногоХранилищаФайлаА); 
		PathToFileAatServer = GetTempFileName(Object.ConnectionToExternalBaseAFileFormat);
		ФайлА.Write(PathToFileAatServer);
		Object.ConnectionToExternalBaseAPathToFile = PathToFileAatServer;
	EndIf;
	
	//If источник Б - файл, хранящийся на клиентском компьютере
	If Object.BaseTypeB = 3 And Object.ConnectingToExternalBaseBDeviceStorageFile = 1 Then
		//Save пути к исходному файлу
		PathToFileBatKlient = Object.ConnectionToExternalBaseBPathToFile;
		//Creating временного файла на сервере
		ФайлБ = GetFromTempStorage(СтруктураПараметровОтКлиента.АдресВременногоХранилищаФайлаБ); 
		PathToFileBatServer = GetTempFileName(Object.ConnectionToExternalBaseBFileFormat);
		ФайлБ.Write(PathToFileBatServer);
		Object.ConnectionToExternalBaseBPathToFile = PathToFileBatServer;
	EndIf;
	
	//Сравнение
	ОбработкаОбъект = FormAttributeToValue("Object");
	ОбработкаОбъект.RefreshDataPeriod();
	ОбработкаОбъект.CompareDataOnServer(ТекстОшибок);
	ПредставленияЗаголовковРеквизитов = ОбработкаОбъект.ПредставленияЗаголовковРеквизитов;
	ЧислоРеквизитов = ОбработкаОбъект.ЧислоРеквизитов;
	ValueToFormAttribute(ОбработкаОбъект, "Object");
	
	For СчетчикРеквизитов = 1 To ЧислоРеквизитов Do 
		Items["ResultAttributeА" + СчетчикРеквизитов].Title = ПредставленияЗаголовковРеквизитов["А" + СчетчикРеквизитов];
		Items["ResultAttributeБ" + СчетчикРеквизитов].Title = ПредставленияЗаголовковРеквизитов["Б" + СчетчикРеквизитов];
	EndDo;
	
	//If источник А - файл, хранящийся на клиентском компьютере
	If Object.BaseTypeA = 3 And Object.ConnectingToExternalBaseADeviceStorageFile = 1 Then
		//Delete временного файла на сервере
		Try
			DeleteFiles(Object.ConnectionToExternalBaseAPathToFile);
		Except EndTry;
		//Восстановление пути к исходному файлу
		Object.ConnectionToExternalBaseAPathToFile = PathToFileAatKlient;
	EndIf;
	
	//If источник Б - файл, хранящийся на клиентском компьютере
	If Object.BaseTypeB = 3 And Object.ConnectingToExternalBaseBDeviceStorageFile = 1 Then
		//Delete временного файла на сервере
		Try
			DeleteFiles(Object.ConnectionToExternalBaseBPathToFile);
		Except EndTry;
		//Восстановление пути к исходному файлу
		Object.ConnectionToExternalBaseBPathToFile = PathToFileBatKlient;
	EndIf;
	
EndProcedure

&AtClient
Procedure СравнитьДанныеНаКлиенте()
	
	ТекстОшибок = "";
	СтруктураПараметровНаКлиенте = New Structure;
	СтруктураПараметровНаКлиенте.Insert("АдресВременногоХранилищаФайлаА", "");
	СтруктураПараметровНаКлиенте.Insert("АдресВременногоХранилищаФайлаБ", "");
	
	СравнитьДанныеНаКлиентеПередатьФайлА(СтруктураПараметровНаКлиенте, ТекстОшибок);
		
EndProcedure

&AtClient
Procedure СравнитьДанныеНаКлиентеПередатьФайлА(СтруктураПараметровНаКлиенте, ТекстОшибок)
	
	//Передача файла А с клиента на сервер
	If Object.BaseTypeA = 3 And Object.ConnectingToExternalBaseADeviceStorageFile = 1 Then
		АдресВременногоХранилищаФайлаА = "";
		BeginPutFile(New NotifyDescription("СравнитьДанныеНаКлиентеПередатьФайлАЗавершение", ThisForm, New Structure("СтруктураПараметровНаКлиенте, ТекстОшибок", СтруктураПараметровНаКлиенте, ТекстОшибок)), АдресВременногоХранилищаФайлаА,Object.ConnectionToExternalBaseAPathToFile,False);
	Else
		СравнитьДанныеНаКлиентеПередатьФайлБ(СтруктураПараметровНаКлиенте, ТекстОшибок);
	EndIf;
	
EndProcedure

&AtClient
Procedure СравнитьДанныеНаКлиентеПередатьФайлАЗавершение(Result, Address, ВыбранноеИмяФайла, AdditionalParameters) Export
	
	СтруктураПараметровНаКлиенте = AdditionalParameters.СтруктураПараметровНаКлиенте;
	ТекстОшибок = AdditionalParameters.ТекстОшибок;

	If Result Then
		СтруктураПараметровНаКлиенте.АдресВременногоХранилищаФайлаА = Address;
		СравнитьДанныеНаКлиентеПередатьФайлБ(СтруктураПараметровНаКлиенте, ТекстОшибок);
	Else
		ТекстОшибок = "Not удалось поместить во временное хранилище файл А: """ + Object.ConnectionToExternalBaseAPathToFile + """";
		Message(ТекстОшибок);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure СравнитьДанныеНаКлиентеПередатьФайлБ(СтруктураПараметровНаКлиенте, ТекстОшибок)
	
	//Передача файла Б с клиента на сервер
	If Object.BaseTypeB = 3 And Object.ConnectingToExternalBaseBDeviceStorageFile = 1 Then
		АдресВременногоХранилищаФайлаБ = "";
		BeginPutFile(New NotifyDescription("СравнитьДанныеНаКлиентеПередатьФайлБЗавершение", ThisForm, New Structure("СтруктураПараметровНаКлиенте, ТекстОшибок", СтруктураПараметровНаКлиенте, ТекстОшибок)), АдресВременногоХранилищаФайлаБ,Object.ConnectionToExternalBaseBPathToFile,False);
		Return;
	Else
		СравнитьДанныеНаКлиентеЗавершение(СтруктураПараметровНаКлиенте, ТекстОшибок);
	EndIf;
	
EndProcedure

&AtClient
Procedure СравнитьДанныеНаКлиентеПередатьФайлБЗавершение(Result, Address, ВыбранноеИмяФайла, AdditionalParameters) Export
	
	СтруктураПараметровНаКлиенте = AdditionalParameters.СтруктураПараметровНаКлиенте;
	ТекстОшибок = AdditionalParameters.ТекстОшибок;
	
	If Result Then
		СтруктураПараметровНаКлиенте.АдресВременногоХранилищаФайлаБ = Address;			
	Else
		ТекстОшибок = "Not удалось поместить во временное хранилище файл Б: """ + Object.ConnectionToExternalBaseBPathToFile + """";
		Message(ТекстОшибок);
		Return;
	EndIf;
	
	СравнитьДанныеНаКлиентеЗавершение(СтруктураПараметровНаКлиенте, ТекстОшибок);

EndProcedure

&AtClient
Procedure СравнитьДанныеНаКлиентеЗавершение(СтруктураПараметровНаКлиенте, ТекстОшибок)
	
	CompareDataOnServer(СтруктураПараметровНаКлиенте, ТекстОшибок);
	If Not IsBlankString(ТекстОшибок) Then
		Message(ТекстОшибок);
	EndIf; 
	
	Items.ГруппаОсновная.CurrentPage = Items.ГруппаРезультатСравнения;
	ОбновитьВидимостьДоступностьЭлементовФормы();

EndProcedure

&AtServer
Procedure RefreshDataPeriod()
	
	ОбработкаОбъект = FormAttributeToValue("Object");
	ОбработкаОбъект.RefreshDataPeriod();
	ValueToFormAttribute(ОбработкаОбъект, "Object");
			
EndProcedure
#EndRegion 

&AtClient
Procedure ПередЗакрытиемЗавершение(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ЗакрытиеФормыПодтверждено = True;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Function ПолучитьДанныеВВидеСтруктуры(СохранятьТабличныеДокументы)
	
	ФормаОбъект = FormAttributeToValue("Object");
	ДанныеСтруктура = ФормаОбъект.GetDataAsStructureOnServer(СохранятьТабличныеДокументы);
	ValueToFormAttribute(ФормаОбъект, "Object");
	
	Return ДанныеСтруктура;
	
EndFunction

&AtClient
Procedure ОткрытьКонструкторЗапроса(BaseID)    	
	
	QueryText = Object["QueryText" + BaseID];
		
	If Object["BaseType" + BaseID] = 0 Then
		
		If ValueIsFilled(QueryText) Then
			Конструктор = New QueryWizard(QueryText);
		Else
			Конструктор = New QueryWizard();
		EndIf;
		
		#If ТолстыйКлиентУправляемоеПриложение Then
			If Конструктор.DoModal() Then
				Object["QueryText" + BaseID] = Конструктор.Text;
			EndIf;
		#ElsIf ThinClient Then
			ПараметрыКонструктора = New Structure("Конструктор, BaseID", Конструктор, BaseID);
			ОповещениеКонструктора = New NotifyDescription("ВыполнитьПослеЗакрытияКонструктора", ThisForm, ПараметрыКонструктора);
			Конструктор.Show(ОповещениеКонструктора);
		#EndIf
		
	ElsIf Object["BaseType" + BaseID] = 1 Then
		
		If Object["WorkOptionExternalBase" + BaseID] = 0 Then
			ParameterConnections = 
				"File=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "ПутьКБазе"]
				+ """;Usr=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Логин"]
				+ """;Pwd=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Password"] + """;";	
		Else
			ParameterConnections = 
				"Srvr=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Server"]
				+ """;Ref=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "ПутьКБазе"] 
				+ """;Usr=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Логин"] 
				+ """;Pwd=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Password"] + """;";
		EndIf;

		
		Try
			Application = New COMObject(StrReplace(Object["VersionPlatformExternalBase" + BaseID],".","") + ".Application");
			Подключение = Application.Connect(ParameterConnections);
		Except
			Message("Error при подключении к внешней базе: " + ErrorDescription());
			Return;
		EndTry;
			
		If Подключение Then
			Конструктор = Application.NewObject("QueryWizard");
			Конструктор.Text = Object["QueryText" + BaseID];
			If Конструктор.DoModal() Then
				Object["QueryText" + BaseID] = Конструктор.Text;
			EndIf;
		EndIf;
	 	
	EndIf;
			
EndProcedure

&AtClient
Procedure ВыполнитьПослеЗакрытияКонструктора(Result, ПараметрыКонструктора) Export
	
	If Not IsBlankString(Result) Then
		Object["QueryText" + ПараметрыКонструктора.BaseID] = TrimAll(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ОбновитьКодДляВыводаИЗапретаВыводаСтрок()
	
	If Not Object.CodeForOutputRowsEditedManually Then
		
		If Object.ConditionsOutputRows.Count() = 0 Then
			
			Object.CodeForOutputRows = "True";
			
		Else
			
			Object.CodeForOutputRows = "";
		
			For Each СтрокаТЧ In Object.ConditionsOutputRows Do
				
				КодИзСтрокиТЧ = ПреобразоватьСтрокуРеквизитовВКодДляВыводаИЗапретаВыводаСтрок(СтрокаТЧ);
				Object.CodeForOutputRows =
					Object.CodeForOutputRows 
					+ ?(IsBlankString(Object.CodeForOutputRows), "", Chars.LF + Object.BooleanOperatorForConditionsOutputRows + " ")
					+ КодИзСтрокиТЧ;
				
			EndDo;
				
		EndIf;
		
		Object.CodeForOutputRows = "УсловияВыводаСтрокиВыполнены = " + Object.CodeForOutputRows + ";";
		
	EndIf;
	
	If Not Object.CodeForProhibitingOutputRowsEditedManually Then
		
		If Object.ConditionsProhibitOutputRows.Count() = 0 Then
			
			Object.CodeForProhibitingOutputRows = "False";
			
		Else
			
			Object.CodeForProhibitingOutputRows = "";
		
			For Each СтрокаТЧ In Object.ConditionsProhibitOutputRows Do
				
				КодИзСтрокиТЧ = ПреобразоватьСтрокуРеквизитовВКодДляВыводаИЗапретаВыводаСтрок(СтрокаТЧ);
				Object.CodeForProhibitingOutputRows =
					Object.CodeForProhibitingOutputRows 
					+ ?(IsBlankString(Object.CodeForProhibitingOutputRows), "", Chars.LF + Object.BooleanOperatorForProhibitingConditionsOutputRows + " ")
					+ КодИзСтрокиТЧ;
				
			EndDo;
				
		EndIf;
		
		Object.CodeForProhibitingOutputRows = "УсловияЗапретаВыводаСтрокиВыполнены = " + Object.CodeForProhibitingOutputRows + ";";
		
	EndIf;
	
EndProcedure

&AtClient
Function ПреобразоватьСтрокуРеквизитовВКодДляВыводаИЗапретаВыводаСтрок(СтрокаТЧ)

	КодИзСтрокиТЧ = "";
	
	If СтрокаТЧ.Condition <> "Заполнен" Then					
					
		If СтрокаТЧ.ComparisonType = "Value" Then
			If TypeOf(СтрокаТЧ.ComparedValue) = Type("Date") Then 
				ПраваяСторона = 
					"Date("
					+ Year(СтрокаТЧ.ComparedValue)
					+ ","
					+ Month(СтрокаТЧ.ComparedValue)
					+ ","
					+ Day(СтрокаТЧ.ComparedValue)
					+ ","
					+ Hour(СтрокаТЧ.ComparedValue)
					+ ","
					+ Minute(СтрокаТЧ.ComparedValue)
					+ ","
					+ Second(СтрокаТЧ.ComparedValue)
					+ ")";
			ElsIf TypeOf(СтрокаТЧ.ComparedValue) = Type("Number") Then 
				ПраваяСторона = String(СтрокаТЧ.ComparedValue);
			ElsIf TypeOf(СтрокаТЧ.ComparedValue) = Type("String") Then 
				ПраваяСторона = """" + String(СтрокаТЧ.ComparedValue) + """";
			ElsIf TypeOf(СтрокаТЧ.ComparedValue) = Type("Boolean") Then 
				If СтрокаТЧ.ComparedValue Then
					ПраваяСторона = "True";
				Else
					ПраваяСторона = "False";
				EndIf;
			Else
				ПраваяСторона = String(СтрокаТЧ.ComparedValue);
			EndIf;
			
		Else
			ПраваяСторона = СтрокаТЧ.NameComparedAttribute2;
		EndIf;
		
		КодИзСтрокиТЧ =
			СтрокаТЧ.NameComparedAttribute
			+ " "
			+ СтрокаТЧ.Condition
			+ " "
			+ ПраваяСторона;
		
	Else
		
		КодИзСтрокиТЧ =
			"ValueIsFilled("
			+ СтрокаТЧ.NameComparedAttribute
			+ ")";
		
	EndIf;
	
	Return КодИзСтрокиТЧ;	

EndFunction

&AtServer
Procedure ПолучитьПараметрыИзЗапросаНаСервере(BaseID)
	
	If IsBlankString(Object["QueryText" + BaseID]) Then	
		Return;
	EndIf;
	
	//Current
	If Object["BaseType" + BaseID] = 0 Then
		
		Query = New Query();
		
	//Outer
	ElsIf Object["BaseType" + BaseID] = 1 Then
		
		If Object["WorkOptionExternalBase" + BaseID] = 0 Then
			ParameterConnections = 
				"File=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "ПутьКБазе"]
				+ """;Usr=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Логин"]
				+ """;Pwd=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Password"] + """;";	
		Else
			ParameterConnections = 
				"Srvr=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Server"]
				+ """;Ref=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "ПутьКБазе"] 
				+ """;Usr=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Логин"] 
				+ """;Pwd=""" + Object["ПодключениеКВнешнейБазе" + BaseID + "Password"] + """;";
		EndIf;
				
		Try
			COMConnector = New COMObject(Object["VersionPlatformExternalBase" + BaseID] + ".COMConnector");
			Подключение = COMConnector.Connect(ParameterConnections);
		Except
			ТекстОшибки = "Error при подключении к внешней базе: " + ErrorDescription();
			Message(ТекстОшибки);
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return;
		EndTry;

		Query = Подключение.NewObject("Query");		
	
	EndIf;
	
	Query.Text = Object["QueryText" + BaseID];
	
	Try
		QueryOptions = Query.FindParameters();
	Except
		Message("Error при получении списка параметров: " + ErrorDescription());
		Return;
	EndTry;
	
	For Each ПараметрЗапроса In QueryOptions Do
		
		ИмяПараметра = ПараметрЗапроса.Name;
		If ИмяПараметра = "ValidFrom" Or ИмяПараметра = "ValidTo" Then
			Continue;
		EndIf;
		
		НайденныеПараметры = Object["ParameterList" + BaseID].FindRows(New Structure("ParameterName", ИмяПараметра));
		If НайденныеПараметры.Count() = 0 Then
			ТекущийПараметр = Object["ParameterList" + BaseID].Add();
			ТекущийПараметр.ParameterName = ИмяПараметра;
		Else
			ТекущийПараметр = НайденныеПараметры[0];
		EndIf; 
		
		ТекущийПараметр.ParameterValue = ПараметрЗапроса.ValueType.AdjustValue(ТекущийПараметр.ЗначениеПараметра);		
		ТекущийПараметр.ParameterType = String(TypeOf(ТекущийПараметр.ЗначениеПараметра));
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ЗаполнитьТипыСтолбцовКлючаВоВсехСтроках()
	
	For Each СтрокаТЗ In Object.Result Do
	
		СтрокаТЗ.ColumnType1Key = TypeOf(СтрокаТЗ.Key1);
		СтрокаТЗ.ColumnType2Key = TypeOf(СтрокаТЗ.Key2);
		СтрокаТЗ.ColumnType3Key = TypeOf(СтрокаТЗ.Key3);
	
	EndDo; 
		
EndProcedure

&AtServer
Function ВыгрузитьРезультатВФайлНаСервере(ДляКлиента = False)
	
	РеквизитОбъект = FormAttributeToValue("Object");
	АдресФайла = РеквизитОбъект.ВыгрузитьРезультатВФайлНаСервере(ДляКлиента);
	Return АдресФайла;
	
EndFunction

&AtClient
Procedure КомандаВыгрузитьРезультатВФайлНаКлиентеЗавершениеВопрос(РезультатВопроса, AdditionalParameters) Export
	
	If РезультатВопроса = DialogReturnCode.None Then
		Return;
	EndIf;
	
	АдресФайла = ВыгрузитьРезультатВФайлНаСервере(True);
	If АдресФайла = Undefined Then
		Return;
	EndIf;
	
	ДанныеФайла = GetFromTempStorage(АдресФайла);
	ДиалогСохраненияФайла = New FileDialog(FileDialogMode.Save);
	ДиалогСохраненияФайла.FullFileName = Object.PathToDownloadFile;
	ДиалогСохраненияФайла.Filter = "*." + Object.UploadFileFormat + "|*." + Object.UploadFileFormat;
	ДиалогСохраненияФайла.Title = "Выберите каталог"; 
	
	ДиалогСохраненияФайла.Show(New NotifyDescription("КомандаВыгрузитьРезультатВФайлНаКлиентеЗавершение", ThisForm, New Structure("ДанныеФайла, ДиалогСохраненияФайла", ДанныеФайла, ДиалогСохраненияФайла)));

EndProcedure

&AtClient
Procedure КомандаВыгрузитьРезультатВФайлНаКлиентеЗавершение(SelectedFiles, AdditionalParameters) Export
	
	ДанныеФайла = AdditionalParameters.ДанныеФайла;
	ДиалогСохраненияФайла = AdditionalParameters.ДиалогСохраненияФайла;
	         	
	If (SelectedFiles <> Undefined) Then
		
		ДанныеФайла.Write(ДиалогСохраненияФайла.FullFileName);
		Message(Format(CurrentDate(),"ДФ='yyyy.MM.dd HH.mm.ss'") + ": формирование файла завершено (" + ДиалогСохраненияФайла.FullFileName + ")");
		
	Else
		
		Message(Format(CurrentDate(),"ДФ='yyyy.MM.dd HH.mm.ss'") + ": формирование файла отменено");
		
	EndIf;

EndProcedure

&AtServer
Function ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере(BaseID, МаксимальноеЧислоСтрок = 0, ТолькоДубликаты = False, Подключение = Undefined)

	ТекстОшибки = "";
	ОбработкаОбъект = FormAttributeToValue("Object");
		
	If Not ОбработкаОбъект.CheckFillingAttributes(BaseID) Then
		Return Undefined;
	EndIf;
	
	Подключение = Undefined;
	ТЗ = ОбработкаОбъект.ReadDataAndGetValueTable(BaseID, ТекстОшибки, Подключение);
	
	If ТЗ = Undefined Then
		Message(ТекстОшибки);
		Return Undefined;
	EndIf;
	
	Template = ОбработкаОбъект.GetTemplate("ФормаПредварительногоПросмотра");
	SpreadsheetDocument = New SpreadsheetDocument;
	
	//Key 1
	ИмяКлюча1 = ТЗ.Cols.Get(0).Name;
	ColumnsWithKeyRow = ИмяКлюча1;
	ОбластьШапка = Template.GetArea("Header|Ключ1");
	SpreadsheetDocument.Put(ОбластьШапка);
	
	//Key 2
	If Object.NumberColumnsInKey > 1 Then
		ИмяКлюча2 = ТЗ.Cols.Get(1).Name;
		ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ИмяКлюча2;
		ОбластьШапка = Template.GetArea("Header|Ключ2");
		SpreadsheetDocument.Join(ОбластьШапка);
	EndIf;
	
	//Key 3
	If Object.NumberColumnsInKey > 2 Then
		ИмяКлюча3 = ТЗ.Cols.Get(2).Name;
		ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ИмяКлюча3;
		ОбластьШапка = Template.GetArea("Header|Ключ3");
		SpreadsheetDocument.Join(ОбластьШапка);
	EndIf;
	
	ТЗ.Sort(ColumnsWithKeyRow);
	
	ТЗ_Сгруппированная = ТЗ.Copy(); 
	
	ColumnNameNumberOfRowsDataSource = "NumberOfRowsDataSource_" + StrReplace(String(New UUID), "-", "");
	ТЗ_Сгруппированная.Cols.Add(ColumnNameNumberOfRowsDataSource);
	
	ОбластьРеквизиты = Template.GetArea("Header|Attributes");
	SpreadsheetDocument.Join(ОбластьРеквизиты);
		
	ТЗ_Сгруппированная.FillValues(1,ColumnNameNumberOfRowsDataSource);	
	ТЗ_Сгруппированная.Collapse(ColumnsWithKeyRow, ColumnNameNumberOfRowsDataSource);
	ТЗ_Сгруппированная.Indexes.Add(ColumnsWithKeyRow);
		
	ЧислоКолонокТЗ = ТЗ.Cols.Count();
	RowsCounter = 0;
	For Each СтрокаТЗ In ТЗ Do
		
		RowsCounter = RowsCounter + 1;
		
		If МаксимальноеЧислоСтрок > 0 And RowsCounter > МаксимальноеЧислоСтрок Then
			Break;
		EndIf;
		
		If Подключение = Undefined Then
			ОтборСтруктура = New Structure;
		Else
			ОтборСтруктура = Подключение.NewObject("Structure");
		EndIf;
				
		Ключ1 = СтрокаТЗ.Get(0);
		ОтборСтруктура.Insert(ИмяКлюча1, Ключ1);
		
		If Object.NumberColumnsInKey > 1 Then
			Ключ2 = СтрокаТЗ.Get(1);
			ОтборСтруктура.Insert(ИмяКлюча2, Ключ2);
		Else
			Ключ2 = Undefined;
		EndIf;
		
		If Object.NumberColumnsInKey > 2 Then
			Ключ3 = СтрокаТЗ.Get(2);
			ОтборСтруктура.Insert(ИмяКлюча3, Ключ3);
		Else
			Ключ3 = Undefined;
		EndIf;
		
		СтрокиСгруппированнойТЗ = ТЗ_Сгруппированная.FindRows(ОтборСтруктура);
		ЧислоСтрокПоКлючу = ?(СтрокиСгруппированнойТЗ.Count(), СтрокиСгруппированнойТЗ.Get(0)[ColumnNameNumberOfRowsDataSource], 0);
		If ЧислоСтрокПоКлючу > 1 Then
			ИмяОбластиСтрока = "СтрокаСОшибками";
		Else
			If ТолькоДубликаты Then
				Continue;
			EndIf;
			ИмяОбластиСтрока = "СтрокаБезОшибок";
		EndIf;
		
		ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Ключ1");
		ОбластьСтрока.Parameters.Ключ1 = String(Ключ1);
		SpreadsheetDocument.Put(ОбластьСтрока);
		
		If Object.NumberColumnsInKey > 1 Then
			ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Ключ2");
			ОбластьСтрока.Parameters.Ключ2 = String(Ключ2);
			SpreadsheetDocument.Join(ОбластьСтрока);
		EndIf;
		
		If Object.NumberColumnsInKey > 2 Then
			ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Ключ3");
			ОбластьСтрока.Parameters.Ключ3 = String(Ключ3);
			SpreadsheetDocument.Join(ОбластьСтрока);
		EndIf;		
		
		ОбластьСтрока = Template.GetArea(ИмяОбластиСтрока + "|Attributes");
		ОбластьСтрока.Parameters.ЧислоСтрок = ЧислоСтрокПоКлючу; 
		
		ЧислоРеквизитов = 5;
		СмещениеНомераРеквизита = Object.NumberColumnsInKey;
		For ColumnCounter = 1 To Min(ЧислоРеквизитов, ЧислоКолонокТЗ - Object.NumberColumnsInKey) Do
			ОбластьСтрока.Parameters["Attribute" + ColumnCounter] = String(СтрокаТЗ.Get(ColumnCounter + СмещениеНомераРеквизита - 1));
		EndDo;
		
		SpreadsheetDocument.Join(ОбластьСтрока);
			
	EndDo;
	
	ТЗ = Undefined;
	ТЗ_Сгруппированная = Undefined;
	Подключение = Undefined;
	
	SpreadsheetDocument.Protection = False;
	SpreadsheetDocument.ReadOnly = True;
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
		
EndFunction


#Region Видимость_доступность_элементов_формы
&AtClient
Procedure ОбновитьВидимостьДоступностьЭлементовФормы()
		
	ОбновитьВидимостьДоступностьЭлементовФормыПоИдентификаторуБазы("А");
	ОбновитьВидимостьДоступностьЭлементовФормыПоИдентификаторуБазы("Б");
	Items.ResultKey2.Visible = Object.NumberColumnsInKey > 1;
	Items.ResultKey3.Visible = Object.NumberColumnsInKey > 2;
	Items.ResultColumnType1Key.Visible = Object.DisplayKeyColumnTypes;
	Items.ResultColumnType2Key.Visible = Object.DisplayKeyColumnTypes And Object.NumberColumnsInKey > 1;
	Items.ResultColumnType3Key.Visible = Object.DisplayKeyColumnTypes And Object.NumberColumnsInKey > 2;
	Items.РезультатКомандаВидимостьТиповСтолбцовКлюча.Check = Object.DisplayKeyColumnTypes;
	
	//If Object.PeriodTypeAbsolute Then
	If Object.PeriodType = 1 Then
		Items.AbsolutePeriodValue.ReadOnly = True;
		Items.ГруппаОтносительныйПериод.Visible = True;
		Items.ГруппаПодчиненныйОтносительныйПериод.Visible = False;
	ElsIf Object.PeriodType = 2 Then	
		Items.AbsolutePeriodValue.ReadOnly = True;
		Items.ГруппаОтносительныйПериод.Visible = True;
		Items.ГруппаПодчиненныйОтносительныйПериод.Visible = True;
	Else
		Items.AbsolutePeriodValue.ReadOnly = False;
		Items.ГруппаОтносительныйПериод.Visible = False;
	EndIf;
	
	ОбновитьЗаголовок();
	ОбновитьРеквизитыПроизвольныйКод();
	ОбновитьВидимостьДоступностьВкладкиУсловияЗапретаВыводаСтрок();
	ОбновитьВидимостьДоступностьВкладкиУсловияВыводаСтрок();
	
EndProcedure

&AtClient
Procedure ОбновитьРеквизитыПроизвольныйКод()
	
	For СчетчикЭлементов = 1 To 3 Do
		ОбновитьВидимостьДоступностьРеквизитаПроизвольныйКод(СчетчикЭлементов, "А"); 
		ОбновитьВидимостьДоступностьРеквизитаПроизвольныйКод(СчетчикЭлементов, "Б");
	EndDo;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьРеквизитаПроизвольныйКод(НомерЭлементаФормы, BaseID)
	
	Items["ArbitraryKeyCode" + НомерЭлементаФормы + BaseID].Visible = 
		Object["ExecuteArbitraryKeyCode" + НомерЭлементаФормы + BaseID];
	
EndProcedure

&AtClient
Procedure ОбновитьЗаголовок()
	
	ThisForm.Title = "КСД: " + Object.Title;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьЭлементовФормыПоИдентификаторуБазы(BaseID)
	
	Items["ГруппаОбработкаКлюча2" + BaseID].Visible = Object.NumberColumnsInKey > 1;
	Items["ГруппаОбработкаКлюча3" + BaseID].Visible = Object.NumberColumnsInKey > 2;
	
	Items["ГруппаСтраницаПараметрыЗапроса" + BaseID].Visible = Object["BaseType" + BaseID] <= 1;
	Items["ParameterList"  + BaseID + "КомандаПолучитьПараметрыЗапроса"  + BaseID].Visible = Object["BaseType" + BaseID] <= 2;
	
	//Table 
	Items["ГруппаСтраницаТаблица" + BaseID].Visible = Object["BaseType" + BaseID] = 4;
		
	//1C 8 внешняя
	If Object["BaseType" + BaseID] = 1 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= True;
		Items["ГруппаВариантВерсияПлатформыБазы" + BaseID].Visible 						= True;
		If Object["WorkOptionExternalBase" + BaseID] = 1 Then
			Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 				= True;
			Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 			= "Name базы";
		Else
			Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 				= False;
			Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 			= "Path к базе";
		EndIf;
		Items["ConnectionToExternalBase" + BaseID + "ДрайверSQL"].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= True;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;	
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= True;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= True;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= True;
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["CastKey2ToString" + BaseID].Visible 								= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["CastKey3ToString" + BaseID].Visible 								= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKeyToString" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey2ToString" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey3ToString" + BaseID];
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
							
	//SQL
	ElsIf Object["BaseType" + BaseID] = 2 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= True;
		Items["ГруппаВариантВерсияПлатформыБазы" + BaseID].Visible 						= False;
		Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 					= True;
		Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 				= "Name базы данных";
		Items["ConnectionToExternalBase" + BaseID + "ДрайверSQL"].Visible 				= True;
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= False;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= True;
		Items["CastKey2ToString" + BaseID].Visible 								= True;
		Items["CastKey3ToString" + BaseID].Visible 								= True;
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
				                                                                       						
	//File
	ElsIf Object["BaseType" + BaseID] = 3 Then
		
		ФайлФорматаXML = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "XML";
		ФайлФорматаXLS = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "XLS";
		ФайлФорматаDOC = Object["ConnectionToExternalBase" + BaseID + "FileFormat" ] = "DOC";
				
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible							= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= True;
		Items["ГруппаПараметрыПодключенияКФайлуОбщие" + BaseID].Visible					= True;
		Items["ГруппаПараметрыПодключенияКФайлуXMLJSON" + BaseID].Visible 				= ФайлФорматаXML;
		Items["ГруппаПараметрыПодключенияКФайлуXML" + BaseID].Visible 					= ФайлФорматаXML;
		Items["ГруппаПараметрыПодключенияКФайлуНеXML" + BaseID].Visible					= Not ФайлФорматаXML;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= ФайлФорматаXLS Or ФайлФорматаDOC;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Title		= ?(ФайлФорматаXLS, "Number книги", "Number таблицы");
		
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;		
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= Not ФайлФорматаXML;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= Not ФайлФорматаXML;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= Not ФайлФорматаXML;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= ФайлФорматаXML;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= ФайлФорматаXML;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= ФайлФорматаXML;
				
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not ФайлФорматаXML;
		Items["CastKey2ToString" + BaseID].Visible 								= Not ФайлФорматаXML;
		Items["CastKey3ToString" + BaseID].Visible 								= Not ФайлФорматаXML;
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "NumberColumn"].Visible						= Not ФайлФорматаXML;
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= ФайлФорматаXML;
							
	//Table
	ElsIf Object["BaseType" + BaseID] = 4 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= True;
		Items["ГруппаПараметрыПодключенияКФайлуОбщие" + BaseID].Visible					= False;
		Items["ГруппаПараметрыПодключенияКФайлуXMLJSON" + BaseID].Visible				= False;
		Items["ГруппаПараметрыПодключенияКФайлуXML" + BaseID].Visible					= False;
		Items["ГруппаПараметрыПодключенияКФайлуНеXML" + BaseID].Visible					= True;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= False;
		
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible							= True;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= True;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= True;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= True;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= True;
		Items["CastKey2ToString" + BaseID].Visible 								= True;
		Items["CastKey3ToString" + BaseID].Visible 								= True;
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
		
	//1C 7.7 внешняя
	ElsIf Object["BaseType" + BaseID] = 5 Then
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= True;
		Items["ГруппаВариантВерсияПлатформыБазы" + BaseID].Visible 						= False;
		Items["ConnectionToExternalBase" + BaseID + "ДрайверSQL"].Visible 				= False;
		Items["ConnectionToExternalBase" + BaseID + "Server"].Visible 					= False;
		Items["ConnectionToExternalBase" + BaseID + "PathBase"].Title 				= "Path к базе";
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;     		
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= True;
		Items["CastKey2ToString" + BaseID].Visible 								= True;
		Items["CastKey3ToString" + BaseID].Visible 								= True;
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;

	//String JSON
	ElsIf Object["BaseType" + BaseID] = 6 Then
	
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "String JSON";
		
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= False;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= False;
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= True;
		Items["ГруппаПараметрыПодключенияКФайлуОбщие" + BaseID].Visible					= False;
		Items["ГруппаПараметрыПодключенияКФайлуXMLJSON" + BaseID].Visible 				= True;
		Items["ГруппаПараметрыПодключенияКФайлуXML" + BaseID].Visible 					= False;
		Items["ГруппаПараметрыПодключенияКФайлуНеXML" + BaseID].Visible					= False;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Visible		= False;
		Items["ConnectionToExternalBase" + BaseID + "NumberTableInFile"].Title		= False;
		
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;		
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= True;
		Items["GroupCollapseTable" + BaseID].Visible 								= True;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= True;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= True;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= True;
				
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= False;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= False;
		
		Items["CastKeyToString" + BaseID].Visible 									= False;
		Items["CastKey2ToString" + BaseID].Visible 								= False;
		Items["CastKey3ToString" + BaseID].Visible 								= False;
		//Приведение производится просто к строке без указания длины
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= False;
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= False;
		
		Items["НастройкиФайла" + BaseID + "NumberColumn"].Visible						= False;
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= True;
							
	//1С 8 текущая
	Else 
		
		Items["ГруппаВариантПараметрыПодключенияКБазе" + BaseID].Visible 				= False;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Visible 							= True;
		Items["ГруппаСтраницаТекстЗапроса" + BaseID].Title							= "Text запроса";
		Items["ДекорацияТекстЗапроса" + BaseID].Visible									= True;
		Items["ГруппаТекстЗапроса" + BaseID + "Commands"].Visible 						= True;
		
		Items["ГруппаПараметрыПодключенияКФайлу" + BaseID].Visible 						= False;
		Items["ГруппаПараметрыКолонокФайла" + BaseID].Visible 							= False;
		
		Items["GroupCollapseTable" + BaseID].Visible 								= False;
		
		Items["ColumnNumberKeyFromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNumberKey3FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKeyFromFile" + BaseID].Visible 								= False;
		Items["ColumnNameKey2FromFile" + BaseID].Visible 							= False;
		Items["ColumnNameKey3FromFile" + BaseID].Visible 							= False;
		
		Items["UseAsKeyUniqueIdentifier" + BaseID].Visible		= True;
		Items["UseAsKey2UniqueIdentifier" + BaseID].Visible 	= True;
		Items["UseAsKey3UniqueIdentifier" + BaseID].Visible 	= True;
		
		Items["CastKeyToString" + BaseID].Visible 									= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["CastKey2ToString" + BaseID].Visible 								= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["CastKey3ToString" + BaseID].Visible 								= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKeyUniqueIdentifier" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey2UniqueIdentifier" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].Visible 						= Not Object["UseAsKey3UniqueIdentifier" + BaseID];
		Items["KeyLengthWhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKeyToString" + BaseID];
		Items["KeyLength2WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey2ToString" + BaseID];
		Items["KeyLength3WhenCastingToString" + BaseID].ReadOnly 					= Not Object["CastKey3ToString" + BaseID];
		
		Items["НастройкиФайла" + BaseID + "ColumnName"].Visible							= False;
							
	EndIf;
	
	For Счетчик = 1 по 5 Do
		ОбновитьВидимостьРеквизитаТЧ("Attribute" + BaseID + Счетчик);
	EndDo;
				
EndProcedure

&AtClient
Procedure ОбновитьВидимостьРеквизитаТЧ(AttributeName)
	
	ВидимостьКолонки = Object["Visible" + AttributeName];
	Items["РезультатКомандаВидимость" + AttributeName].Check = ВидимостьКолонки;
	Items["Result" + AttributeName].Visible = ВидимостьКолонки;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация()
	
	Items.СравнитьДанные.Enabled = Object.RelationalOperation > 0;
	For СчетчикОпераций = 1 To 7 Do 
		
		If СчетчикОпераций = Object.RelationalOperation Then
			ThisForm["Операция" + СчетчикОпераций] = ThisForm["АктивнаяОперация" + СчетчикОпераций];			
		Else
			ThisForm["Операция" + СчетчикОпераций] = ThisForm["НеактивнаяОперация" + СчетчикОпераций];			
		EndIf;
		
	EndDo;		
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок()
	
	Items.BooleanOperatorForConditionsOutputRows.ReadOnly 		= Object.CodeForOutputRowsEditedManually;
	Items.ConditionsOutputRows.ReadOnly 								= Object.CodeForOutputRowsEditedManually;
	Items.BooleanOperatorForProhibitingConditionsOutputRows.ReadOnly 	= Object.CodeForProhibitingOutputRowsEditedManually;
	Items.ConditionsProhibitOutputRows.ReadOnly 						= Object.CodeForProhibitingOutputRowsEditedManually;
	
	Items.CodeForOutputRows.ReadOnly 								= Not Object.CodeForOutputRowsEditedManually;
	Items.CodeForProhibitingOutputRows.ReadOnly 						= Not Object.CodeForProhibitingOutputRowsEditedManually;
	
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьВкладкиУсловияВыводаСтрок()
	
	Items.GroupConditionsOutputRows.BgColor = ?(Object.ConditionsOutputRowsDisabled, WebColors.Pink, ЦветФонаФормыПоУмолчанию);;
		
EndProcedure

&AtClient
Procedure ОбновитьВидимостьДоступностьВкладкиУсловияЗапретаВыводаСтрок()
	
	Items.GroupConditionsProhibitOutputRows.BgColor = ?(Object.ConditionsProhibitOutputRowsDisabled, WebColors.Pink, ЦветФонаФормыПоУмолчанию);;
		
EndProcedure
#EndRegion 


#Region Settings

#Region Save
&AtClient
Procedure СохранитьНастройкиВФайлНаКлиенте(СохранятьТабличныеДокументы = False)
	
	Mode = FileDialogMode.Save;
	ДиалогВыбора = New FileDialog(Mode);
	ДиалогВыбора.FullFileName = Object.Title;
	Filter = "File xml (*.xml)|*.xml";
	ДиалогВыбора.Filter = Filter;
	ДиалогВыбора.Title = "Укажите файл для сохранения настроек";   

	ДиалогВыбора.Show(New NotifyDescription("СохранитьНастройкиВФайлНаКлиентеЗавершение", ThisForm, New Structure("ДиалогВыбора,СохранятьТабличныеДокументы", ДиалогВыбора, СохранятьТабличныеДокументы)));
	
EndProcedure

&AtClient
Procedure СохранитьНастройкиВФайлНаКлиентеЗавершение(SelectedFiles, AdditionalParameters) Export
	
	ДиалогВыбора = AdditionalParameters.ДиалогВыбора;
	СохранятьТабличныеДокументы = AdditionalParameters.СохранятьТабличныеДокументы;
	                             	
	If (SelectedFiles <> Undefined) Then
		
		Object.Title = Mid(ДиалогВыбора.FullFileName, StrFind(ДиалогВыбора.FullFileName, "\", SearchDirection.FromEnd) + 1);
		Address = СохранитьНастройкиВФайлНаСервере(СохранятьТабличныеДокументы);
		BinaryData = GetFromTempStorage(Address);
		BinaryData.Write(ДиалогВыбора.FullFileName);
		
	EndIf;

EndProcedure

&AtClient
Procedure СохранитьНастройкиВБазуНаКлиенте(СохранятьТабличныеДокументы = False);
	
	If ValueIsFilled(Object.RelatedDataComparisonOperation)  Then
	
		ShowQueryBox(New NotifyDescription("СохранитьВСвязаннуюОперациюЗавершение", ThisObject, New Structure("ВыбратьЭлементСправочникаДляСохранения,СохранятьТабличныеДокументы",True,СохранятьТабличныеДокументы)), "Update элемент справочника """ + Object.RelatedDataComparisonOperation + """?", QuestionDialogMode.YesNo);
		
	Else
		
		ОткрытьФормуВыбораОперацииДляЗаписи(СохранятьТабличныеДокументы);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure СохранитьВСвязаннуюОперациюЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	СохранятьТабличныеДокументы = AdditionalParameters.СохранятьТабличныеДокументы;
	ВыбратьЭлементСправочникаДляСохранения = AdditionalParameters.ВыбратьЭлементСправочникаДляСохранения;
	ПриЗакрытииФормы = AdditionalParameters.Property("ПриЗакрытииФормы") And AdditionalParameters.ПриЗакрытииФормы;
	
	If РезультатВопроса = DialogReturnCode.Yes Then
		
		SaveSettingsToBaseAtServer(Object.RelatedDataComparisonOperation, СохранятьТабличныеДокументы);
		ОбновитьЗаголовок();
		
	//Click кнопки Save в базу
	ElsIf ВыбратьЭлементСправочникаДляСохранения = True And ПриЗакрытииФормы = False Then
		
		ОткрытьФормуВыбораОперацииДляЗаписи();
				
	EndIf;

EndProcedure

&AtClient
Procedure СохранитьВВыбраннуюОперациюЗавершение(Result, AdditionalParameters) Export
	
	СохранятьТабличныеДокументы = AdditionalParameters.СохранятьТабличныеДокументы;
	
	ВыбранныйЭлемент = Result;
	If ВыбранныйЭлемент <> Undefined Then
		
		SaveSettingsToBaseAtServer(ВыбранныйЭлемент, СохранятьТабличныеДокументы);
		ОбновитьЗаголовок();
				
	EndIf;

EndProcedure

&AtServer
Function СохранитьНастройкиВФайлНаСервере(СохранятьТабличныеДокументы)
	
	PathToFile = GetTempFileName("xml");
	Data = ПолучитьДанныеВВидеСтруктуры(СохранятьТабличныеДокументы); 
	ХранилищеВнешнее = New ValueStorage(Data);
	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(PathToFile, "UTF-8");
	XDTOSerializer.WriteXML(XMLWriter, ХранилищеВнешнее);
	XMLWriter.Close();
	Address = PutToTempStorage(New BinaryData(PathToFile));
	DeleteFiles(PathToFile);
	
	Return Address;
			
EndFunction

&AtServer
Procedure SaveSettingsToBaseAtServer(ВыбранныйЭлемент, СохранятьТабличныеДокументы = False)

	ФормаОбъект = FormAttributeToValue("Object");
	ФормаОбъект.SaveSettingsToBaseAtServer(ВыбранныйЭлемент, СохранятьТабличныеДокументы);
	ValueToFormAttribute(ФормаОбъект, "Object");
		
EndProcedure
#EndRegion 


#Region Load
&AtClient
Procedure ОткрытьНастройкиИзФайлаНаКлиенте(Val Оповещение, ЗагружатьТабличныеДокументы = False)

	Mode = FileDialogMode.Opening;
	ДиалогВыбора = New FileDialog(Mode);
	ДиалогВыбора.FullFileName = "";
	Filter = "File xml (*.xml)|*.xml";
	ДиалогВыбора.Filter = Filter;
	ДиалогВыбора.Title = "Укажите файл с настройками";   

	ДиалогВыбора.Show(New NotifyDescription("ОткрытьНастройкиИзФайлаНаКлиентеЗавершение", ThisForm, New Structure("ДиалогВыбора, Оповещение, ЗагружатьТабличныеДокументы", ДиалогВыбора, Оповещение, ЗагружатьТабличныеДокументы)));

EndProcedure

&AtClient
Procedure ОткрытьНастройкиИзФайлаНаКлиентеЗавершение(SelectedFiles, AdditionalParameters) Export
	
	ДиалогВыбора = AdditionalParameters.ДиалогВыбора;
	Оповещение = AdditionalParameters.Оповещение;	
	ЗагружатьТабличныеДокументы = AdditionalParameters.ЗагружатьТабличныеДокументы;	
	
	If (SelectedFiles <> Undefined) Then
		
		Address = PutToTempStorage(New BinaryData(ДиалогВыбора.FullFileName));
		ОткрытьНастройкиИзФайлаНаСервере(Address, ЗагружатьТабличныеДокументы);
		ПервыйСимвол = StrFind(ДиалогВыбора.FullFileName, "\", SearchDirection.FromEnd) + 1;
		ПоследнийСимвол = StrFind(ДиалогВыбора.FullFileName, ".", SearchDirection.FromEnd);
		Object.Title = Mid(ДиалогВыбора.FullFileName, ПервыйСимвол, ПоследнийСимвол - ПервыйСимвол);
		ОбновитьВидимостьДоступностьЭлементовФормы();
		ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
		ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();
		
	EndIf;
	
	ExecuteNotifyProcessing(Оповещение);

EndProcedure

&AtServer
Procedure ОткрытьНастройкиИзФайлаНаСервере(Address, ЗагружатьТабличныеДокументы = False)
	
	PathToFile = GetTempFileName("xml");
	BinaryData = GetFromTempStorage(Address);
	BinaryData.Write(PathToFile);
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile,,,"UTF-8");
	ХранилищеВнешнее = XDTOSerializer.ReadXML(XMLReader);
	Data = ХранилищеВнешнее.Get();
	FillPropertyValues(Object, Data);
	
	If Data.Property("ТЗУсловияВыводаСтрок") Then
		Object.ConditionsOutputRows.Load(Data.ТЗУсловияВыводаСтрок);
	Else
		Object.ConditionsOutputRows.Clear();
	EndIf;
	
	If Data.Property("ТЗУсловияЗапретаВыводаСтрок") Then
		Object.ConditionsProhibitOutputRows.Load(Data.ТЗУсловияЗапретаВыводаСтрок);
	Else
		Object.ConditionsProhibitOutputRows.Clear();
	EndIf;
	
	If Data.Property("ValueTableSettingsFileA") Then
		Object.SettingsFileA.Load(Data.ValueTableSettingsFileA);
	Else
		Object.SettingsFileA.Clear();
	EndIf;
	
	If Data.Property("ValueTableSettingsFileB") Then
		Object.SettingsFileB.Load(Data.ValueTableSettingsFileB);
	Else
		Object.SettingsFileB.Clear();
	EndIf;
	
	If Data.Property("ValueTableParameterListA") Then
		Object.ParameterListA.Load(Data.ValueTableParameterListA);
	Else
		Object.ParameterListA.Clear();
	EndIf;
	
	If Data.Property("ValueTableParameterListB") Then
		Object.ParameterListB.Load(Data.ValueTableParameterListB);
	Else
		Object.ParameterListB.Clear();
	EndIf;
	
	If ЗагружатьТабличныеДокументы Then
		If Object.BaseTypeA = 4 Then
			Try
				If Data.Property("TableAValueStorage") Then
					Object.TableA = Data.TableAValueStorage.Get();
				EndIf;
			Except
			EndTry; 
		EndIf;
		
		If Object.BaseTypeB = 4 Then
			Try
				If Data.Property("TableBValueStorage") Then
					Object.TableB = Data.TableBValueStorage.Get();
				EndIf;
			Except
			EndTry;
		EndIf;
	EndIf;
	
	XMLReader.Close();
	DeleteFiles(PathToFile);
	
	Object.Result.Clear();
	
EndProcedure

&AtServer
Procedure OpenSettingsFromBaseAtServer(ВыбранныйЭлемент, ЗагружатьТабличныеДокументы = False)
	
	ФормаОбъект = FormAttributeToValue("Object");
	ФормаОбъект.OpenSettingsFromBaseAtServer(ВыбранныйЭлемент, ЗагружатьТабличныеДокументы);
	ValueToFormAttribute(ФормаОбъект, "Object");
	
EndProcedure

&AtClient
Procedure ОткрытьНастройкиИзФайлаЗавершение(Result, AdditionalParameters) Export
	
	ОбновитьВидимостьДоступностьЭлементовФормы();
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();

EndProcedure

&AtClient
Procedure ОткрытьФормуВыбораОперацииДляЗаписи(СохранятьТабличныеДокументы = False)

	ВыбранныйЭлемент = Undefined;
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("СохранитьВВыбраннуюОперациюЗавершение", ThisForm, New Structure("СохранятьТабличныеДокументы",СохранятьТабличныеДокументы)), FormWindowOpeningMode.БлокироватьВесьИнтерфейс);
	
EndProcedure

&AtClient
Procedure ОткрытьНастройкиИзБазыЗавершение(Result, AdditionalParameters) Export
	
	ВыбранныйЭлемент = Result;
	ЗагружатьТабличныеДокументы = AdditionalParameters <> Undefined And AdditionalParameters.Property("ЗагружатьТабличныеДокументы") And AdditionalParameters.ЗагружатьТабличныеДокументы;
	
	If ВыбранныйЭлемент <> Undefined Then
		
		OpenSettingsFromBaseAtServer(ВыбранныйЭлемент, ЗагружатьТабличныеДокументы);
		ОбновитьВидимостьДоступностьЭлементовФормы();
		ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
		ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();
		
	EndIf;

EndProcedure
#EndRegion 

#EndRegion 


#Region Обработка_выбора_параметра
&AtClient
Procedure ПриНачалеВыбораЗначенияПараметра(BaseID, StandardProcessing)
	
	If Object["BaseType" + BaseID] = 1 Then
		StandardProcessing = False;
		СписокДоступныхТипов = New ValueList;
		СписокДоступныхТипов.Add("Number");
		СписокДоступныхТипов.Add("String");
		СписокДоступныхТипов.Add("Date");
		СписокДоступныхТипов.Add("Boolean");
		ВыбранныйТип = Undefined;

		ShowChooseFromList(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение4", ThisForm, New Structure("BaseID", BaseID)), СписокДоступныхТипов, Items["ParameterList" + BaseID + "ParameterValue"]);
	
	EndIf;

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение4(ВыбранныйЭлемент, AdditionalParameters) Export
	
	BaseID = AdditionalParameters.BaseID;
	
	
	ВыбранныйТип = ВыбранныйЭлемент;
	If ВыбранныйТип = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items["ParameterList" + BaseID].CurrentData;
	If CurrentData = Undefined Then
		ТекущееЗначениеПараметра = Undefined; 
	Else
		ТекущееЗначениеПараметра =  CurrentData.ParameterValue;
	EndIf;
	
	If ВыбранныйТип.Value = "Number" Then
		ShowInputNumber(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение3", ThisForm, New Structure("ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра", ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра);
		Return;
	ElsIf ВыбранныйТип.Value = "String" Then
		ShowInputString(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение2", ThisForm, New Structure("ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра", ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра);
		Return;
	ElsIf ВыбранныйТип.Value = "Date" Then
		ShowInputDate(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение1", ThisForm, New Structure("ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра", ВыбранныйТип, CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра);
		Return;
	ElsIf ВыбранныйТип.Value = "Boolean" Then
		ShowInputValue(New NotifyDescription("ПриНачалеВыбораЗначенияПараметраЗавершение", ThisForm, New Structure("CurrentData, ТекущееЗначениеПараметра", CurrentData, ТекущееЗначениеПараметра)), ТекущееЗначениеПараметра,,New TypeDescription("Boolean"));
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент3(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение3(Number, AdditionalParameters) Export
	
	ВыбранныйТип = AdditionalParameters.ВыбранныйТип;
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(Number = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, Number);
	
	
	If Not (Number <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент3(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент3(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	ПриНачалеВыбораЗначенияПараметраФрагмент2(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение2(String, AdditionalParameters) Export
	
	ВыбранныйТип = AdditionalParameters.ВыбранныйТип;
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(String = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, String);
	
	
	If Not (String <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент2(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент2(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	ПриНачалеВыбораЗначенияПараметраФрагмент1(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение1(Date, AdditionalParameters) Export
	
	ВыбранныйТип = AdditionalParameters.ВыбранныйТип;
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(Date = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, Date);
	
	
	If Not (Date <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент1(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент1(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	ПриНачалеВыбораЗначенияПараметраФрагмент(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраЗавершение(Value, AdditionalParameters) Export
	
	CurrentData = AdditionalParameters.CurrentData;
	ТекущееЗначениеПараметра = ?(Value = Undefined, AdditionalParameters.ТекущееЗначениеПараметра, Value);
	
	
	If Not (Value <> Undefined) Then
		Return;
	EndIf;
	
	ПриНачалеВыбораЗначенияПараметраФрагмент(ТекущееЗначениеПараметра, CurrentData);

EndProcedure

&AtClient
Procedure ПриНачалеВыбораЗначенияПараметраФрагмент(Val ТекущееЗначениеПараметра, Val CurrentData)
	
	CurrentData.ParameterValue = ТекущееЗначениеПараметра;

EndProcedure
#EndRegion 

#EndRegion


#Region Commands
&AtClient
Procedure СравнитьДанные(Command)
	
	СравнитьДанныеНаКлиенте();
	
EndProcedure

&AtClient
Procedure КонструкторЗапросаБ(Command)
	ОткрытьКонструкторЗапроса("Б");
EndProcedure

&AtClient
Procedure КонструкторЗапросаА(Command)
	ОткрытьКонструкторЗапроса("А");
EndProcedure

&AtClient
Procedure СохранитьНастройкиВФайл(Command)
	
	СохранитьНастройкиВФайлНаКлиенте();
	
EndProcedure

&AtClient
Procedure СохранитьНастройкиИТабличныеДокументыВФайл(Command)
	
	СохранитьНастройкиВФайлНаКлиенте(True);
	
EndProcedure

&AtClient
Procedure СохранитьНастройкиВБазу(Command)
	
	СохранитьНастройкиВБазуНаКлиенте();
		
EndProcedure

&AtClient
Procedure СохранитьНастройкиИТабличныеДокументыВБазу(Command)
	
	СохранитьНастройкиВБазуНаКлиенте(True);
	
EndProcedure

&AtClient
Procedure ОткрытьНастройкиИзФайла(Command)
	
	ОткрытьНастройкиИзФайлаНаКлиенте(New NotifyDescription("ОткрытьНастройкиИзФайлаЗавершение", ThisForm));
			
EndProcedure

&AtClient
Procedure ЗагрузитьНастройкиИТабличныеДокументыИзФайла(Command)
	
	ОткрытьНастройкиИзФайлаНаКлиенте(New NotifyDescription("ОткрытьНастройкиИзФайлаЗавершение", ThisForm), True);
	
EndProcedure

&AtClient
Procedure ОткрытьНастройкиИзБазы(Command)
	
	ВыбранныйЭлемент = Undefined; 
	
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("ОткрытьНастройкиИзБазыЗавершение", ThisForm), FormWindowOpeningMode.БлокироватьВесьИнтерфейс);
	
EndProcedure

&AtClient
Procedure ЗагрузитьНастройкиИТабличныеДокументыИзБазы(Command)
	
	ВыбранныйЭлемент = Undefined; 
	
	OpenForm("Catalog.ВС_ОперацииСравненияДанных.ChoiceForm",,,,,, New NotifyDescription("ОткрытьНастройкиИзБазыЗавершение", ThisForm, New Structure("ЗагружатьТабличныеДокументы", True)), FormWindowOpeningMode.БлокироватьВесьИнтерфейс);
	
EndProcedure

&AtClient
Procedure КомандаПолучитьПараметрыЗапросаА(Command)
	
	ПолучитьПараметрыИзЗапросаНаСервере("А");
	Items.ГруппаСтраницыБазаА.CurrentPage = Items.ГруппаСтраницаПараметрыЗапросаА;
	
EndProcedure

&AtClient
Procedure КомандаПолучитьПараметрыЗапросаБ(Command)
	
	ПолучитьПараметрыИзЗапросаНаСервере("Б");
	Items.ГруппаСтраницыБазаБ.CurrentPage = Items.ГруппаСтраницаПараметрыЗапросаБ;
	
EndProcedure

&AtClient
Procedure ПосетитьСтраницуАвтора(Command)

	BeginRunningApplication(New NotifyDescription("ПосетитьСтраницу", ThisForm), "http://sertakov.by");
	
EndProcedure

&AtClient
Procedure ПосетитьСтраницуОбработки(Command)
	
	BeginRunningApplication(New NotifyDescription("ПосетитьСтраницу", ThisForm), "https://infostart.ru/public/581794/");
	
EndProcedure

&AtClient
Procedure КомандаСкачатьОбработку(Command)
	
	BeginRunningApplication(New NotifyDescription("ПосетитьСтраницу", ThisForm), "http://sertakov.by/work/KSD.epf");
	
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаАВсеСтроки(Command)	
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А");	
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаА100Строк(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А",100);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А (100 строк)");
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаБ100Строк(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б",100);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б (100 строк)");
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаБВсеСтроки(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б");
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б");
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаАДубликаты(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А",,True);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А (дубликаты)");
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаБДубликаты(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б",,True);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б (дубликаты)");
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаА1000Строк(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("А",1000);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src А (1000 строк)");
	EndIf;
EndProcedure

&AtClient
Procedure КомандаПредварительныйПросмотрИсточникаБ1000Строк(Command)
	SpreadsheetDocument = ПолучитьТабличныйДокументСДаннымиИзИсточникаНаСервере("Б",1000);
	If SpreadsheetDocument <> Undefined Then
		SpreadsheetDocument.Show("Src Б (1000 строк)");
	EndIf;
EndProcedure

#EndRegion


#Region Обработчики_событий
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ЦветФонаФормыПоУмолчанию = StyleColors.FormBackColor;
	
	If Parameters.Property("UserMode") And Parameters.UserMode Then
		Object.UserMode = True;
	EndIf;
	
	If Parameters.Property("ОперацияСравненияДанных") And ValueIsFilled(Parameters.ОперацияСравненияДанных) Then
		
		Object.RelatedDataComparisonOperation = Parameters.ОперацияСравненияДанных;
		ФормаОбъект = FormAttributeToValue("Object");
		ФормаОбъект.OpenSettingsFromBaseAtServer(Object.RelatedDataComparisonOperation);
		ValueToFormAttribute(ФормаОбъект, "Object");
				
	Else 
		
		Object.VersionPlatformExternalBaseA = "V83";
		Object.VersionPlatformExternalBaseB = "V83";
		
		Object.NumberColumnsInKey = 1;
		Object.PeriodType = 0;
		Object.AbsolutePeriodValue.ValidFrom = BegOfMonth(CurrentDate());
		Object.AbsolutePeriodValue.ValidTo = EndOfDay(CurrentDate());
		Object.RelativePeriodValue = 0;
		Object.ValueOfSlaveRelativePeriod = 0;
		Object.DiscretenessOfRelativePeriod = "month";
		Object.DiscretenessOfSlaveRelativePeriod = "month";
		Object.ConnectingToExternalBaseADriverSQL = "SQL Server";
		Object.ConnectingToExternalBaseBDriverSQL = "SQL Server";
		Object.NumberFirstRowFileA = 1;
		Object.NumberFirstRowFileB = 1;
		Object.NumberOfRowsWithEmptyKeysToBreakReading = 2;
		Object.ConnectingToExternalBaseADeviceStorageFile = 0;
		Object.ConnectingToExternalBaseBDeviceStorageFile = 0;
		Object.ConnectionToExternalDatabaseANumberTableInFile = 1;
		Object.ConnectionToExternalDatabaseBNumberTableInFile = 1;
		
		For Счетчик = 1 To 5 Do
			Object["VisibilityAttributeA" + Счетчик] = True;
			Object["VisibilityAttributeB" + Счетчик] = True;
		EndDo;
		
		For Счетчик = 1 To 20 Do 
			
			Object.TableA.Region(1,Счетчик,1,Счетчик).Text = Счетчик;
			Object.TableB.Region(1,Счетчик,1,Счетчик).Text = Счетчик;
			
		EndDo;
		
	EndIf;
		
	Пример1 = "КлючТек = Left(КлючТек,10);";
	Пример2 = "КлючТек = Number(КлючТек) + 1;";
	Пример3 = "If Left(КлючТек,1) = ""#"" Then КлючТек = Mid(КлючТек, 2); EndIf;";
	Пример4 = "КлючТек = Right(""0000000000"" + КлючТек, 10);";
	Пример5 = "КлючТек = StrReplace(КлючТек, ""_"", """");";
	Пример6 = "КлючТек = ?(ValueIsFilled(КлючТек), КлючТек, ""<>"");";
	
	If Object.UserMode Then
		
		Items.ГруппаШапкаСкрываемыеРеквизиты.Visible = False;
		Items.ГруппаБазаАСтраница.Visible = False;
		Items.ГруппаБазаБСтраница.Visible = False;
		Items.ГруппаНастройкиВывода.Visible = False;
		Items.ГруппаОсновная.PagesRepresentation = FormPagesRepresentation.None;
		Items.РезультатКомандаВыгрузитьРезультатВФайлНаСервере.Visible = False;
		Items.РезультатГруппаВидимостьСтолбцовКлюча.Visible = False;
				
	Else		
	
		МакетКартинкаАктивнаяОперация1 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация1");
		МакетКартинкаНеактивнаяОперация1 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация1");
		МакетКартинкаАктивнаяОперация2 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация2");
		МакетКартинкаНеактивнаяОперация2 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация2");
		МакетКартинкаАктивнаяОперация3 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация3");
		МакетКартинкаНеактивнаяОперация3 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация3");
		МакетКартинкаАктивнаяОперация4 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация4");
		МакетКартинкаНеактивнаяОперация4 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация4");
		МакетКартинкаАктивнаяОперация5 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация5");
		МакетКартинкаНеактивнаяОперация5 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация5");
		МакетКартинкаАктивнаяОперация6 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация6");
		МакетКартинкаНеактивнаяОперация6 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация6");
		МакетКартинкаАктивнаяОперация7 		= FormAttributeToValue("Object").GetTemplate("КартинкаАктивнаяОперация7");
		МакетКартинкаНеактивнаяОперация7 	= FormAttributeToValue("Object").GetTemplate("КартинкаНеактивнаяОперация7");
			
		АктивнаяОперация1 	= PutToTempStorage(МакетКартинкаАктивнаяОперация1, UUID);
		НеактивнаяОперация1 = PutToTempStorage(МакетКартинкаНеактивнаяОперация1, UUID);
		АктивнаяОперация2 	= PutToTempStorage(МакетКартинкаАктивнаяОперация2, UUID);
		НеактивнаяОперация2 = PutToTempStorage(МакетКартинкаНеактивнаяОперация2, UUID);
		АктивнаяОперация3 	= PutToTempStorage(МакетКартинкаАктивнаяОперация3, UUID);
		НеактивнаяОперация3 = PutToTempStorage(МакетКартинкаНеактивнаяОперация3, UUID);
		АктивнаяОперация4 	= PutToTempStorage(МакетКартинкаАктивнаяОперация4, UUID);
		НеактивнаяОперация4 = PutToTempStorage(МакетКартинкаНеактивнаяОперация4, UUID);
		АктивнаяОперация5 	= PutToTempStorage(МакетКартинкаАктивнаяОперация5, UUID);
		НеактивнаяОперация5 = PutToTempStorage(МакетКартинкаНеактивнаяОперация5, UUID);
		АктивнаяОперация6 	= PutToTempStorage(МакетКартинкаАктивнаяОперация6, UUID);
		НеактивнаяОперация6 = PutToTempStorage(МакетКартинкаНеактивнаяОперация6, UUID);
		АктивнаяОперация7 	= PutToTempStorage(МакетКартинкаАктивнаяОперация7, UUID);
		НеактивнаяОперация7 = PutToTempStorage(МакетКартинкаНеактивнаяОперация7, UUID); 
		
	EndIf;

	UT_Common.ToolFormOnCreateAtServer(ThisObject, Cancel, StandardProcessing,
		Items.ГруппаПанель2);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ОбновитьВидимостьДоступностьЭлементовФормы();
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();
	
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
		
EndProcedure

&AtClient
Procedure ОперацияНажатие(Item, StandardProcessing)
	
	StandardProcessing = False;
	Object.RelationalOperation = Number(Right(Item.Name,1));
	ОбновитьВидимостьДоступностьЭлементовРеляционнаяОперация();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	If Not ЗакрытиеФормыПодтверждено Then
		Cancel = True;
		ShowQueryBox(New NotifyDescription("ПередЗакрытиемЗавершение", ThisForm),"Close консоль сравнения данных?", QuestionDialogMode.YesNo);
	EndIf;
EndProcedure

&AtClient
Procedure OnClose(ЗавершениеРаботы)
	
	If ValueIsFilled(Object.RelatedDataComparisonOperation) And Not Object.UserMode  Then
		
		ShowQueryBox(New NotifyDescription("СохранитьВСвязаннуюОперациюЗавершение", ThisObject, New Structure("ВыбратьЭлементСправочникаДляСохранения,СохранятьТабличныеДокументы,ПриЗакрытииФормы",True,False,True)), "Update элемент справочника """ + Object.RelatedDataComparisonOperation + """?", QuestionDialogMode.YesNo);
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure ПосетитьСтраницу(КодВозврата, AdditionalParameters) Export
	
	

EndProcedure

&AtClient
Procedure КодДляВыводаСтрокРедактируетсяВручнуюПриИзменении(Item)
	
	If Not Object.CodeForOutputRowsEditedManually Then
		
		ShowQueryBox(New NotifyDescription("КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение", ThisForm), "Code, внесенный вручную будет утерян. Continue?", QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();
EndProcedure

&AtClient
Procedure КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	If РезультатВопроса = DialogReturnCode.None Then
		Object.CodeForOutputRowsEditedManually = True;
		Return;
	EndIf;
	
	
	КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();

EndProcedure

&AtClient
Procedure КодДляВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент()
	
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();

EndProcedure

&AtClient
Procedure CodeForProhibitingOutputRowsEditedManuallyOnChange(Item)
	
	If Not Object.CodeForProhibitingOutputRowsEditedManually Then
		
		ShowQueryBox(New NotifyDescription("КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение", ThisForm), "Code, внесенный вручную будет утерян. Continue?", QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();
EndProcedure

&AtClient
Procedure КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	If РезультатВопроса = DialogReturnCode.None Then
		Object.CodeForProhibitingOutputRowsEditedManually = True;
		Return;
	EndIf;
	
	
	КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент();

EndProcedure

&AtClient
Procedure КодДляЗапретаВыводаСтрокРедактируетсяВручнуюПриИзмененииФрагмент()
	
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
	ОбновитьВидимостьДоступностьЭлементовВыводИЗапретаВыводаСтрок();

EndProcedure

&AtClient
Procedure ConditionsOutputRowsOnChange(Item)
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
EndProcedure

&AtClient
Procedure ConditionsProhibitOutputRowsOnChange(Item)
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
EndProcedure

&AtClient
Procedure BooleanOperatorForProhibitingConditionsOutputRowsOnChange(Item)
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
EndProcedure

&AtClient
Procedure ЛогическийОператорДляУсловийВыводаСтрокПриИзменении(Item)
	ОбновитьКодДляВыводаИЗапретаВыводаСтрок();
EndProcedure

&AtClient
Procedure КомандаВидимостьКолонкиТЧ(Command)
	
	AttributeName = StrReplace(Command.Name, "КомандаВидимость", "");
	
	Object["Visible" + AttributeName] = Not Object["Visible" + AttributeName];
	
	ОбновитьВидимостьРеквизитаТЧ(AttributeName);
		
EndProcedure

&AtClient
Procedure ТипПараметраПериодПриИзменении(Item)
	
	RefreshDataPeriod();
	ОбновитьВидимостьДоступностьЭлементовФормы();
	
EndProcedure

&AtClient
Procedure RelativePeriodValueOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfRelativePeriodOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure ПодключениеКВнешнейБазеАПутьКФайлуНачалоВыбора(Item, ДанныеВыбора, StandardProcessing)
	
	FileDialog = New FileDialog(FileDialogMode.Opening);
	
	If IsBlankString(Object.ConnectionToExternalBaseAFileFormat) Then
		FileDialog.Filter = 
			"*.*" + 
			"|*.*";
	ElsIf Object.ConnectionToExternalBaseAFileFormat = "XLS" Or Object.ConnectionToExternalBaseAFileFormat = "DOC" Then
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseAFileFormat
			+ ";*." + Object.ConnectionToExternalBaseAFileFormat + "X"
			+ "|*." + Object.ConnectionToExternalBaseAFileFormat
			+ ";*." + Object.ConnectionToExternalBaseAFileFormat + "X";
	Else
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseAFileFormat + 
			"|*." + Object.ConnectionToExternalBaseAFileFormat;
	EndIf;
		
	FileDialog.Title = "Выберите файл";
	FileDialog.FilterIndex = 0;
	FileDialog.Show(New NotifyDescription("ПодключениеКВнешнейБазеАПутьКФайлуНачалоВыбораЗавершение", ThisForm, New Structure("FileDialog", FileDialog)));
	
EndProcedure

&AtClient
Procedure ПодключениеКВнешнейБазеАПутьКФайлуНачалоВыбораЗавершение(SelectedFiles, AdditionalParameters) Export
	
	FileDialog = AdditionalParameters.FileDialog;
	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.ConnectionToExternalBaseAPathToFile = FileDialog.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure ConnectionToExternalBaseBPathToFileStartChoice(Item, ДанныеВыбора, StandardProcessing)
	
	FileDialog = New FileDialog(FileDialogMode.Opening);
	
	If IsBlankString(Object.ConnectionToExternalBaseBFileFormat) Then
		FileDialog.Filter = 
			"*.*" + 
			"|*.*";
	ElsIf Object.ConnectionToExternalBaseBFileFormat = "XLS" Or Object.ConnectionToExternalBaseBFileFormat = "DOC" Then
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseBFileFormat
			+ ";*." + Object.ConnectionToExternalBaseBFileFormat + "X"
			+ "|*." + Object.ConnectionToExternalBaseBFileFormat
			+ ";*." + Object.ConnectionToExternalBaseBFileFormat + "X";
	Else
		FileDialog.Filter = 
			"*." + Object.ConnectionToExternalBaseBFileFormat + 
			"|*." + Object.ConnectionToExternalBaseBFileFormat;
	EndIf;
		
	FileDialog.Title = "Выберите файл";
	FileDialog.FilterIndex = 0;
	FileDialog.Show(New NotifyDescription("ConnectionToExternalBaseBPathToFileStartChoiceEnd", ThisForm, New Structure("FileDialog", FileDialog)));
	
EndProcedure

&AtClient
Procedure ConnectionToExternalBaseBPathToFileStartChoiceEnd(SelectedFiles, AdditionalParameters) Export
	
	FileDialog = AdditionalParameters.FileDialog;
	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.ConnectionToExternalBaseBPathToFile = FileDialog.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure SettingsFileABeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	If Object.SettingsFileA.Count() = 5 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettingsFileBBeforeAddRow(Item, Cancel, Copy, Parent, Group, Parameter)
	
	If Object.SettingsFileB.Count() = 5 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ПриИзмененииКлючевогоРеквизита(Item)
	
	ОбновитьВидимостьДоступностьЭлементовФормы();
	
EndProcedure

&AtClient
Procedure ParameterListAParameterValueStartChoice(Item, ДанныеВыбора, StandardProcessing)
	
	Items.ParameterListAParameterValue.ChooseType = TypeOf(Items.ParameterListA.CurrentData.ParameterValue) = Type("Undefined");	
	ПриНачалеВыбораЗначенияПараметра("А", StandardProcessing);
	
EndProcedure

&AtClient
Procedure ParameterListAParameterValueOnChange(Item)
	
	ТекущийПараметр = Object.ParameterListA.FindByID(Items.ParameterListA.CurrentData.GetID());
	ТекущийПараметр.ParameterType = TypeOf(ТекущийПараметр.ParameterValue);

EndProcedure

&AtClient
Procedure ParameterListBParameterValueStartChoice(Item, ДанныеВыбора, StandardProcessing)
	
	Items.ParameterListBParameterValue.ChooseType = TypeOf(Items.ParameterListB.CurrentData.Значениепараметра) = Type("Undefined");	
	ПриНачалеВыбораЗначенияПараметра("Б", StandardProcessing);
		
EndProcedure

&AtClient
Procedure ParameterListBParameterValueOnChange(Item)
	
	ТекущийПараметр = Object.ParameterListB.FindByID(Items.ParameterListB.CurrentData.GetID());
	ТекущийПараметр.ParameterType = TypeOf(ТекущийПараметр.ParameterValue);
	
EndProcedure

&AtClient
Procedure NumberColumnsInKeyOnChange(Item)
	
	ОбновитьВидимостьДоступностьЭлементовФормы();
	ОбновитьВидимостьДоступностьЭлементовФормыПоИдентификаторуБазы("А");
	ОбновитьВидимостьДоступностьЭлементовФормыПоИдентификаторуБазы("Б");
	
EndProcedure

&AtClient
Procedure ResultKeyStartChoice(Item, ДанныеВыбора, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ResultKey2StartChoice(Item, ДанныеВыбора, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey3StartChoice(Item, ДанныеВыбора, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKeyClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey2Clearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ResultKey3Clearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ПриИзмененииФлагаВыполнятьПроизвольныйКодКлюча(Item)
	
	ОбновитьРеквизитыПроизвольныйКод();
	
EndProcedure

&AtClient
Procedure DisplayKeyColumnTypesOnChange(Item)
	
	ОбновитьВидимостьДоступностьЭлементовФормы();
	
EndProcedure

&AtClient
Procedure КомандаВидимостьТиповСтолбцовКлюча(Command)
	
	Items.РезультатКомандаВидимостьТиповСтолбцовКлюча.Check = Not Items.РезультатКомандаВидимостьТиповСтолбцовКлюча.Check;
	Object.DisplayKeyColumnTypes = Items.РезультатКомандаВидимостьТиповСтолбцовКлюча.Check;
	If Object.DisplayKeyColumnTypes Then
		ЗаполнитьТипыСтолбцовКлючаВоВсехСтроках();
	EndIf;
	ОбновитьВидимостьДоступностьЭлементовФормы();
	
EndProcedure

&AtClient
Procedure КомандаВыгрузитьРезультатВФайлНаСервере(Command)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = "Not задан формат файла выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
	
	If IsBlankString(Object.PathToDownloadFile) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.PathToDownloadFile";
		UserMessage.Text = "Not задан путь к файлу выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
			
	Ответ = Undefined; 	
	ShowQueryBox(New NotifyDescription("КомандаВыгрузитьРезультатВФайлНаСервереЗавершение", ThisForm), "Unload таблицу в файл на сервере?", QuestionDialogMode.YesNo, , DialogReturnCode.None, "Выгрузка");
	
EndProcedure

&AtClient
Procedure КомандаВыгрузитьРезультатВФайлНаСервереЗавершение(РезультатВопроса, AdditionalParameters) Export
	
	Ответ = РезультатВопроса; 
	If Ответ = DialogReturnCode.None Then
		Return;
	EndIf;
	
	ВыгрузитьРезультатВФайлНаСервере();

EndProcedure

&AtClient
Procedure PathToDownloadFileStartChoice(Item, ДанныеВыбора, StandardProcessing)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = "Not задан формат файла выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
	
	Mode = FileDialogMode.Save;
	ДиалогВыбора = New FileDialog(Mode);
	ДиалогВыбора.FullFileName = Object.Title;
	Filter = "File " + Object.UploadFileFormat + " (*." + Object.UploadFileFormat + ")|*." + Object.UploadFileFormat + "";
	ДиалогВыбора.Filter = Filter;
	ДиалогВыбора.Title = "Укажите файл для сохранения результата сравнения";   

	ДиалогВыбора.Show(New NotifyDescription("ПутьКФайлуВыгрузкиНачалоВыбораЗавершение", ThisForm, New Structure("ДиалогВыбора", ДиалогВыбора)));
	
EndProcedure

&AtClient
Procedure ПутьКФайлуВыгрузкиНачалоВыбораЗавершение(SelectedFiles, AdditionalParameters) Export
	
	ДиалогВыбора = AdditionalParameters.ДиалогВыбора;	
	
	If (SelectedFiles <> Undefined) Then
		
		Object.PathToDownloadFile =  ДиалогВыбора.FullFileName;
		
	EndIf;

EndProcedure

&AtClient
Procedure КомандаВыгрузитьРезультатВФайлНаКлиенте(Command)
	
	If IsBlankString(Object.UploadFileFormat) Then
		UserMessage = New UserMessage;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Text = "Not задан формат файла выгрузки";
		UserMessage.Message();
		Return;
	EndIf;
	
	ShowQueryBox(New NotifyDescription("КомандаВыгрузитьРезультатВФайлНаКлиентеЗавершениеВопрос", ThisForm), "Unload таблицу в файл на клиенте?", QuestionDialogMode.YesNo,, DialogReturnCode.None, "Выгрузка");
	
EndProcedure

&AtClient
Procedure ТипПериодаПриИзменении(Item)
	
	RefreshDataPeriod();
	ОбновитьВидимостьДоступностьЭлементовФормы();
	
EndProcedure

&AtClient
Procedure ValueOfSlaveRelativePeriodOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfSlaveRelativePeriodOnChange(Item)
	
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfRelativePeriodClearing(Item, StandardProcessing)
	
	Object.DiscretenessOfRelativePeriod = "day";
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure DiscretenessOfSlaveRelativePeriodClearing(Item, StandardProcessing)
	
	Object.DiscretenessOfSlaveRelativePeriod = "day";
	RefreshDataPeriod();
	
EndProcedure

&AtClient
Procedure ConditionsOutputRowsDisabledOnChange(Item)
	
	ОбновитьВидимостьДоступностьВкладкиУсловияВыводаСтрок();
	
EndProcedure

&AtClient
Procedure ConditionsProhibitOutputRowsDisabledOnChange(Item)
	
	ОбновитьВидимостьДоступностьВкладкиУсловияЗапретаВыводаСтрок();
	
EndProcedure

//@skip-warning
&AtClient
Procedure Attachable_ExecuteToolsCommonCommand(Command) 
	UT_CommonClient.Attachable_ExecuteToolsCommonCommand(ThisObject, Command);
EndProcedure



#EndRegion

ЗакрытиеФормыПодтверждено = False;