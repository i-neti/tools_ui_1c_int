Var ЧислоРеквизитов Export;
Var ПредставленияЗаголовковРеквизитов Export;
Var КодПриведенияРеквизитаКТипуЧисло;

#Region Основные_процедуры_и_функции
Procedure СравнитьДанныеНаСервере(ТекстОшибок = "") Export
	
	//Сообщения при ошибке в произвольном коде незачем показывать больше одного раза, они скорее всего будут одинаковые
	СообщениеОбОшибкеПриВыполненииКодаДляВыводаСтрок = False;
	СообщениеОбОшибкеПриВыполненииКодаДляЗапретаВыводаСтрок = False;
	СообщениеОНаличииНесколькихСтрокПоОдномуКлючу = False;
		
	If Not ПроверитьЗаполнениеРеквизитов() Then
		Return;
	EndIf;
	
	СмещениеНомераРеквизита = NumberColumnsInKey - 1;
	
	ТекстОшибки = "";
	ПодключениеА = Undefined;
	ТЗ_А = ПрочитатьДанныеИПолучитьТЗ("А", ТекстОшибки, ПодключениеА);
	
	If ТЗ_А = Undefined Then
		ТекстОшибок = ТекстОшибок + ?(IsBlankString(ТекстОшибок), "", Chars.LF) + ТекстОшибки;
	EndIf;
	
	ТекстОшибки = "";
	ПодключениеБ = Undefined;
	ТЗ_Б = ПрочитатьДанныеИПолучитьТЗ("Б", ТекстОшибки, ПодключениеБ);
	
	If ТЗ_Б = Undefined Then
		ТекстОшибок = ТекстОшибок + ?(IsBlankString(ТекстОшибок), "", Chars.LF) + ТекстОшибки;
	EndIf;
	
	If ТЗ_А = Undefined Or ТЗ_Б = Undefined Then
		Return;
	EndIf;
		
	ИмяКолонкиКоличествоСтрокИсточникаДанных = "КоличествоСтрокИсточникаДанных_" + StrReplace(String(New UUID), "-", "");
	
	
#Region ТЗ_А_Сгруппированная
	
	ТЗ_А_Сгруппированная = ТЗ_А.Copy();
	ТЗ_А_Сгруппированная.Columns.Add(ИмяКолонкиКоличествоСтрокИсточникаДанных);
	
	KeyNameA1 = ТЗ_А_Сгруппированная.Columns.Get(0).Name;
	КолонкиСКлючомАСтрокой = KeyNameA1;
	
	If NumberColumnsInKey > 1 Then
		KeyNameA2 = ТЗ_А_Сгруппированная.Columns.Get(1).Name;
		КолонкиСКлючомАСтрокой = КолонкиСКлючомАСтрокой + "," + KeyNameA2;
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		KeyNameA3 = ТЗ_А_Сгруппированная.Columns.Get(2).Name;
		КолонкиСКлючомАСтрокой = КолонкиСКлючомАСтрокой + "," + KeyNameA3;
	EndIf;
		
	ТЗ_А_Сгруппированная.FillValues(1,ИмяКолонкиКоличествоСтрокИсточникаДанных);	
	ТЗ_А_Сгруппированная.Collapse(КолонкиСКлючомАСтрокой, ИмяКолонкиКоличествоСтрокИсточникаДанных);	
	ТЗ_А_Сгруппированная.Indexes.Add(КолонкиСКлючомАСтрокой);
	
#EndRegion


#Region ТЗ_Б_Сгруппированная

	ТЗ_Б_Сгруппированная = ТЗ_Б.Copy();
	ТЗ_Б_Сгруппированная.Columns.Add(ИмяКолонкиКоличествоСтрокИсточникаДанных);
	
	KeyNameB1 = ТЗ_Б_Сгруппированная.Columns.Get(0).Name;
	КолонкиСКлючомБСтрокой = KeyNameB1;
	If NumberColumnsInKey > 1 Then
		KeyNameB2 = ТЗ_Б_Сгруппированная.Columns.Get(1).Name;
		КолонкиСКлючомБСтрокой = КолонкиСКлючомБСтрокой + "," + KeyNameB2;
	EndIf;
	If NumberColumnsInKey > 2 Then
		KeyNameB3 = ТЗ_Б_Сгруппированная.Columns.Get(2).Name;
		КолонкиСКлючомБСтрокой = КолонкиСКлючомБСтрокой + "," + KeyNameB3;
	EndIf;
			
	ТЗ_Б_Сгруппированная.FillValues(1, ИмяКолонкиКоличествоСтрокИсточникаДанных);
	ТЗ_Б_Сгруппированная.Collapse(КолонкиСКлючомБСтрокой, ИмяКолонкиКоличествоСтрокИсточникаДанных);
	ТЗ_Б_Сгруппированная.Indexes.Add(КолонкиСКлючомБСтрокой);
	
#EndRegion


	ЧислоКолонокТЗ_А = ТЗ_А.Columns.Count();
	ЧислоКолонокТЗ_Б = ТЗ_Б.Columns.Count();
	
	TotalsByAttributesMap = New Map;
	For AttributesCounter = 1 To ЧислоРеквизитов Do
		
		ThisObject["VisibilityAttributeA" + AttributesCounter] = ThisObject["VisibilityAttributeA" + AttributesCounter] And ЧислоКолонокТЗ_А >= AttributesCounter;
		ThisObject["VisibilityAttributeB" + AttributesCounter] = ThisObject["VisibilityAttributeB" + AttributesCounter] And ЧислоКолонокТЗ_Б >= AttributesCounter;
		
		TotalsByAttributesMap.Вставить("AttributeA" + AttributesCounter, New Structure(
			"ОшибкаПриВычислении,CalculateTotal,AggregateFunctionCalculationTotal,ValueTotal,СуммаЗначений,ЧислоЗначений"
				, False
				, ?(SettingsFileA.Count() < AttributesCounter, False, SettingsFileA[AttributesCounter - 1].CalculateTotal)
				, ?(SettingsFileA.Count() < AttributesCounter, "Сумма", SettingsFileA[AttributesCounter - 1].AggregateFunctionCalculationTotal)
				, Undefined
				, 0
				, 0));
		TotalsByAttributesMap.Вставить("AttributeB" + AttributesCounter, New Structure(
			"ОшибкаПриВычислении,CalculateTotal,AggregateFunctionCalculationTotal,ValueTotal,СуммаЗначений,ЧислоЗначений"
				, False
				, ?(SettingsFileB.Count() < AttributesCounter, False, SettingsFileB[AttributesCounter - 1].CalculateTotal)
				, ?(SettingsFileB.Count() < AttributesCounter, "Сумма", SettingsFileB[AttributesCounter - 1].AggregateFunctionCalculationTotal)
				, Undefined
				, 0
				, 0));
				
	EndDo;
	
	Result.Clear();
	
	
#Region _1_2_3_4_6_7
	
	If RelationalOperation = 1 Or RelationalOperation = 2 Or RelationalOperation = 3 Or RelationalOperation = 4 Or RelationalOperation = 6 Or RelationalOperation = 7 Then
		
		For Each СтрокаТЗ_А_Сгруппированная In ТЗ_А_Сгруппированная Do 		
			           			
			Key1 = СтрокаТЗ_А_Сгруппированная[KeyNameA1];
			
			If NumberColumnsInKey > 1 Then
				Ключ2 = СтрокаТЗ_А_Сгруппированная[KeyNameA2];				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				Key3 = СтрокаТЗ_А_Сгруппированная[KeyNameA3];
			EndIf;

			If ПодключениеБ = Undefined Then
				ОтборСтруктура = New Structure;
			Else
				ОтборСтруктура = ПодключениеБ.NewObject("Structure");
			EndIf;
			ОтборСтруктура.Insert(KeyNameB1, Key);
			If NumberColumnsInKey > 1 Then
				ОтборСтруктура.Insert(KeyNameB2, Ключ2);
			EndIf;
			If NumberColumnsInKey > 2 Then
				ОтборСтруктура.Insert(KeyNameB3, Key3);
			EndIf;
			
			НайденныеСтроки = ТЗ_Б_Сгруппированная.FindRows(ОтборСтруктура);
			СтрокаТЗ_Б_Сгруппированная = ?(НайденныеСтроки.Count() > 0, НайденныеСтроки.Get(0), Undefined);
			
			If RelationalOperation = 2 Or RelationalOperation = 3
				Or ((RelationalOperation = 1 Or RelationalOperation = 7) And СтрокаТЗ_Б_Сгруппированная = Undefined) 
				Or ((RelationalOperation = 4 Or RelationalOperation = 6) And СтрокаТЗ_Б_Сгруппированная <> Undefined) Then
				
				СтрокаТР = Result.Add();
				
			Else
				Continue;
			EndIf;
			
			СтрокаТР.Key1 = Key;
			If DisplayKeyColumnTypes Then
				СтрокаТР.ColumnType1Key = TypeOf(СтрокаТР.Key1);
			EndIf;
			If NumberColumnsInKey > 1 Then
				СтрокаТР.Key2 = Ключ2;
				If DisplayKeyColumnTypes Then
					СтрокаТР.ColumnType2Key = TypeOf(СтрокаТР.Key2);
				EndIf;
			EndIf;
			If NumberColumnsInKey > 2 Then
				СтрокаТР.Key3 = Key3;
				If DisplayKeyColumnTypes Then
					СтрокаТР.ColumnType3Key = TypeOf(СтрокаТР.Key3);
				EndIf;
			EndIf;
			
			СтрокаТР.NumberOfRecordsA = СтрокаТЗ_А_Сгруппированная[ИмяКолонкиКоличествоСтрокИсточникаДанных];
			If СтрокаТЗ_Б_Сгруппированная <> Undefined Then
				СтрокаТР.NumberOfRecordsB = СтрокаТЗ_Б_Сгруппированная[ИмяКолонкиКоличествоСтрокИсточникаДанных];
			EndIf;
			
			If ЧислоКолонокТЗ_А > 1 Then
								
				If ПодключениеА = Undefined Then
					ОтборСтруктура = New Structure;
				Else
					ОтборСтруктура = ПодключениеА.NewObject("Structure");
				EndIf;
				ОтборСтруктура.Insert(KeyNameA1, Key);
				If NumberColumnsInKey > 1 Then
					ОтборСтруктура.Insert(KeyNameA2, Ключ2);
				EndIf;
				If NumberColumnsInKey > 2 Then
					ОтборСтруктура.Insert(KeyNameA3, Key3);
				EndIf;
				
				НайденныеСтроки = ТЗ_А.FindRows(ОтборСтруктура);
				СтрокаТЗ_А = ?(НайденныеСтроки.Count() > 0, НайденныеСтроки.Get(0), Undefined);
				
				//Values реквизитов выводятся только при наличии единственной записи по ключу
				If СтрокаТР.NumberOfRecordsA = 1 Then
					For СчетчикКолонокА = 1 To Min(ЧислоРеквизитов, ЧислоКолонокТЗ_А - NumberColumnsInKey) Do
						СтрокаТР["AttributeA" + СчетчикКолонокА] = СтрокаТЗ_А.Get(СчетчикКолонокА + СмещениеНомераРеквизита);
					EndDo;
				EndIf;
				
			EndIf;
						
			If ЧислоКолонокТЗ_Б > 1 Then
								
				If ПодключениеБ = Undefined Then
					ОтборСтруктура = New Structure;
				Else
					ОтборСтруктура = ПодключениеБ.NewObject("Structure");
				EndIf;
				ОтборСтруктура.Insert(KeyNameB1, Key);
				If NumberColumnsInKey > 1 Then
					ОтборСтруктура.Insert(KeyNameB2, Ключ2);
				EndIf;
				If NumberColumnsInKey > 2 Then
					ОтборСтруктура.Insert(KeyNameB3, Key3);
				EndIf;
				
				НайденныеСтроки = ТЗ_Б.FindRows(ОтборСтруктура);
				СтрокаТЗ_Б = ?(НайденныеСтроки.Count() > 0, НайденныеСтроки.Get(0), Undefined);
							
				If СтрокаТЗ_Б <> Undefined Then
					
					//Values реквизитов выводятся только при наличии единственной записи по ключу
					If СтрокаТР.NumberOfRecordsB = 1 Then
						For СчетчикКолонокБ = 1 To Min(ЧислоРеквизитов, ЧислоКолонокТЗ_Б - NumberColumnsInKey) Do
							СтрокаТР["AttributeB" + СчетчикКолонокБ] = СтрокаТЗ_Б.Get(СчетчикКолонокБ + СмещениеНомераРеквизита);
						EndDo;
					EndIf;
					
				EndIf;
				
			EndIf;
						
			ConditionsOutputRowCompleted = True;
			
			If Not ConditionsOutputRowsDisabled Then 
				Try
					Execute CodeForOutputRows;
				Except
					If Not СообщениеОбОшибкеПриВыполненииКодаДляВыводаСтрок Then
						ТекстОшибки = ErrorDescription();
						Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ТекстОшибки);
					EndIf;
					СообщениеОбОшибкеПриВыполненииКодаДляВыводаСтрок = True;
				EndTry;
			EndIf;
			
			//If число строк с одним ключом больше 1, результирующую строку нужно вывести обязательно, 
			//т.к. условия в данном случае некорректно применять вообще
			If СтрокаТР.NumberOfRecordsA <= 1 And СтрокаТР.NumberOfRecordsB <= 1 Then
				
				ConditionsProhibitOutputRowCompleted = False;
				
				If Not ConditionsProhibitOutputRowsDisabled Then 
					Try
						Execute CodeForProhibitingOutputRows; 
					Except
						If Not СообщениеОбОшибкеПриВыполненииКодаДляЗапретаВыводаСтрок Then
							ТекстОшибки = ErrorDescription();
							Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ТекстОшибки);						
						EndIf;
						СообщениеОбОшибкеПриВыполненииКодаДляЗапретаВыводаСтрок = True;
					EndTry;
				EndIf;
				
				//Условия вывода строк, установленные пользователем
				If Not ConditionsOutputRowCompleted Or ConditionsProhibitOutputRowCompleted Then					
					
					Result.Delete(СтрокаТР);
					Continue;
					
				EndIf;
				
				For AttributesCounter = 1 По ЧислоРеквизитов Do
					
					ИмяРеквизита = "РеквизитА" + AttributesCounter;
					If TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог And TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = False Then
						Try
							пЗначениеРеквизита = СтрокаТР[ИмяРеквизита];
							Если ЗначениеЗаполнено(пЗначениеРеквизита) Then
								пТипЗначения = ТипЗнч(пЗначениеРеквизита);
								//Количество
								Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Количество" Then
									TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений + 1;
								ИначеЕсли пТипЗначения = Тип("Число") Или пТипЗначения = Тип("Строка") Then
									пЗначениеРеквизитаЧисло = Число(пЗначениеРеквизита);																		
									//Сумма
									Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Сумма" Then
										TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений + пЗначениеРеквизитаЧисло;
									//Среднее
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Среднее" Then
										TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений + пЗначениеРеквизитаЧисло;
										TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений + 1;
									//Максимум
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Максимум" Then
										TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога <> Undefined, Max(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									//Минимум
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Минимум" Then
										TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога <> Undefined, Min(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									КонецЕсли;
								Иначе
									TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
								КонецЕсли;
							КонецЕсли;
						Except
							TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = True;
						EndTry;
					EndIf;
					
					ИмяРеквизита = "AttributeB" + AttributesCounter;
					Если TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог И TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = False Then
						Попытка
							пЗначениеРеквизита = СтрокаТР[ИмяРеквизита];
							Если ЗначениеЗаполнено(пЗначениеРеквизита) Then
								пТипЗначения = ТипЗнч(пЗначениеРеквизита);
								//Количество
								Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Количество" Then
									TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений + 1;
								ИначеЕсли пТипЗначения = Тип("Число") Или пТипЗначения = Тип("Строка") Then
									пЗначениеРеквизитаЧисло = Число(пЗначениеРеквизита);																		
									//Сумма
									Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Сумма" Then
										TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений + пЗначениеРеквизитаЧисло;
									//Среднее
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Среднее" Then
										TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений + пЗначениеРеквизитаЧисло;
										TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений + 1;
									//Максимум
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Максимум" Then
										TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога <> Undefined, Max(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									//Минимум
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Минимум" Then
										TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога <> Undefined, Min(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									КонецЕсли;
								Иначе
									TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
								КонецЕсли;
							КонецЕсли;
						Исключение
							TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
						КонецПопытки;
					КонецЕсли;
					
				КонецЦикла;
				
			Else
				
				СообщениеОНаличииНесколькихСтрокПоОдномуКлючу = True;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
#EndRegion 


#Region _3_4_5_7
	
	If RelationalOperation = 3 Or RelationalOperation = 4 Or RelationalOperation = 5 Or RelationalOperation = 7 Then
		
		For Each СтрокаТЗ_Б_Сгруппированная In ТЗ_Б_Сгруппированная Do 		
			
			Key1 = СтрокаТЗ_Б_Сгруппированная[KeyNameB1];
			
			If NumberColumnsInKey > 1 Then
				Ключ2 = СтрокаТЗ_Б_Сгруппированная[KeyNameB2];				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				Key3 = СтрокаТЗ_Б_Сгруппированная[KeyNameB3];
			EndIf;

			If ПодключениеА = Undefined Then
				ОтборСтруктура = New Structure;
			Else
				ОтборСтруктура = ПодключениеА.NewObject("Structure");
			EndIf;
			ОтборСтруктура.Insert(KeyNameA1, Key);
			If NumberColumnsInKey > 1 Then
				ОтборСтруктура.Insert(KeyNameA2, Ключ2);
			EndIf;
			If NumberColumnsInKey > 2 Then
				ОтборСтруктура.Insert(KeyNameA3, Key3);
			EndIf;
			
			НайденныеСтроки = ТЗ_А_Сгруппированная.FindRows(ОтборСтруктура);
			СтрокаТЗ_А_Сгруппированная = ?(НайденныеСтроки.Count() > 0, НайденныеСтроки.Get(0), Undefined);
						
			//All пересечения обработаны в предыдущей секции
			If СтрокаТЗ_А_Сгруппированная <> Undefined Then
				Continue;
			EndIf;
			
			СтрокаТР = Result.Add();
			
			СтрокаТР.Key1 = Key;
			If DisplayKeyColumnTypes Then
				СтрокаТР.ColumnType1Key = TypeOf(СтрокаТР.Key1);
			EndIf;
			
			If NumberColumnsInKey > 1 Then
				СтрокаТР.Key2 = Ключ2;
				If DisplayKeyColumnTypes Then
					СтрокаТР.ColumnType2Key = TypeOf(СтрокаТР.Key2);
				EndIf;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				СтрокаТР.Key3 = Key3;
				If DisplayKeyColumnTypes Then
					СтрокаТР.ColumnType3Key = TypeOf(СтрокаТР.Key3);
				EndIf;
			EndIf;
			
			СтрокаТР.NumberOfRecordsB = СтрокаТЗ_Б_Сгруппированная[ИмяКолонкиКоличествоСтрокИсточникаДанных];
			
			If ЧислоКолонокТЗ_Б > 1 Then
				      							
				If ПодключениеБ = Undefined Then
					ОтборСтруктура = New Structure;
				Else
					ОтборСтруктура = ПодключениеБ.NewObject("Structure");
				EndIf;
				ОтборСтруктура.Insert(KeyNameB1, Key);
				If NumberColumnsInKey > 1 Then
					ОтборСтруктура.Insert(KeyNameB2, Ключ2);
				EndIf;
				If NumberColumnsInKey > 2 Then
					ОтборСтруктура.Insert(KeyNameB3, Key3);
				EndIf;
				
				НайденныеСтроки = ТЗ_Б.FindRows(ОтборСтруктура);
				СтрокаТЗ_Б = ?(НайденныеСтроки.Count() > 0, НайденныеСтроки.Get(0), Undefined);
			
				If СтрокаТЗ_Б <> Undefined Then
					
					//Values реквизитов выводятся только при наличии единственной записи по ключу
					If СтрокаТР.NumberOfRecordsB = 1 Then
						For СчетчикКолонокБ = 1 To Min(ЧислоРеквизитов, ЧислоКолонокТЗ_Б - NumberColumnsInKey) Do
							СтрокаТР["AttributeB" + СчетчикКолонокБ] = СтрокаТЗ_Б.Get(СчетчикКолонокБ + СмещениеНомераРеквизита);
						EndDo;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			//If число строк с одним ключом больше 1, результирующую строку нужно вывести обязательно, 
			//т.к. условия в данном случае некорректно применять вообще
			If СтрокаТР.NumberOfRecordsA <= 1 And СтрокаТР.NumberOfRecordsB <= 1 Then
				
				ConditionsOutputRowCompleted = True;
				
				If Not ConditionsOutputRowsDisabled Then
					Try
						Execute CodeForOutputRows; 
					Except
						If Not СообщениеОбОшибкеПриВыполненииКодаДляВыводаСтрок Then
							ТекстОшибки = ErrorDescription();
							Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ТекстОшибки);						
						EndIf;
						СообщениеОбОшибкеПриВыполненииКодаДляВыводаСтрок = True;
					EndTry;
				EndIf;
				
				ConditionsProhibitOutputRowCompleted = False;
				
				If Not ConditionsProhibitOutputRowsDisabled Then
					Try
						Execute CodeForProhibitingOutputRows; 
					Except
						If Not СообщениеОбОшибкеПриВыполненииКодаДляЗапретаВыводаСтрок Then
							ТекстОшибки = ErrorDescription();
							Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ТекстОшибки);
						EndIf;
						СообщениеОбОшибкеПриВыполненииКодаДляЗапретаВыводаСтрок = True;
					EndTry;
				EndIf;
				
				//Условия вывода строк, установленные пользователем
				If Not ConditionsOutputRowCompleted Or ConditionsProhibitOutputRowCompleted Then					
					
					Result.Delete(СтрокаТР);
					Continue;
				EndIf;
				
				Для СчетчикРеквизитов = 1 По ЧислоРеквизитов Цикл
															
					ИмяРеквизита = "AttributeB" + СчетчикРеквизитов;
					Если TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог И TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Ложь Тогда
						Попытка
							пЗначениеРеквизита = СтрокаТР[ИмяРеквизита];
							Если ЗначениеЗаполнено(пЗначениеРеквизита) Тогда
								пТипЗначения = ТипЗнч(пЗначениеРеквизита);
								//Количество
								Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Количество" Тогда
									TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений + 1;
								ИначеЕсли пТипЗначения = Тип("Число") Или пТипЗначения = Тип("Строка") Тогда
									пЗначениеРеквизитаЧисло = Число(пЗначениеРеквизита);																		
									//Сумма
									Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Сумма" Тогда
										TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений + пЗначениеРеквизитаЧисло;
									//Среднее
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Среднее" Тогда
										TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений + пЗначениеРеквизитаЧисло;
										TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений + 1;
									//Максимум
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Максимум" Тогда
										TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога <> Неопределено, Макс(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									//Минимум
									ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Минимум" Тогда
										TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога <> Неопределено, Мин(TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									КонецЕсли;
								Иначе
									TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
								КонецЕсли;
							КонецЕсли;
						Исключение
							TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
						КонецПопытки;
					КонецЕсли;
					
				КонецЦикла;
				
			Else
				
				СообщениеОНаличииНесколькихСтрокПоОдномуКлючу = True;
				
			EndIf;
			
		EndDo;

	EndIf;
#EndRegion 

	Для СчетчикРеквизитов = 1 По ЧислоРеквизитов Цикл
					
		ИмяРеквизита = "РеквизитА" + СчетчикРеквизитов;
		Если TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог Тогда
			Если TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении Тогда
				TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = "Ошибка";
			Иначе
				//Сумма
				Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Сумма" Тогда
					TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений;
				//Среднее
				ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Среднее" Тогда
					TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений <> 0, TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений / TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений, 0);
				//Количество
				ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Количество" Тогда
					TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений;
				КонецЕсли;
			КонецЕсли;
		
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "А" + СчетчикРеквизитов + ": " + TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога;
		
		Иначе
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "";
		КонецЕсли;
		
		ИмяРеквизита = "AttributeB" + СчетчикРеквизитов;
		Если TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог Тогда
			Если TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении Тогда
				TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = "Ошибка";
			Иначе
				//Сумма
				Если TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Сумма" Тогда
					TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений;
				//Среднее
				ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Среднее" Тогда
					TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = ?(TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений <> 0, TotalsByAttributesMap[ИмяРеквизита].СуммаЗначений / TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений, 0);
					//Количество
				ИначеЕсли TotalsByAttributesMap[ИмяРеквизита].AggregateFunctionCalculationTotal = "Количество" Тогда
					TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога = TotalsByAttributesMap[ИмяРеквизита].ЧислоЗначений;
				КонецЕсли;
			КонецЕсли;
			
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "Б" + СчетчикРеквизитов + ": " + TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога;
			
		Иначе
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "";
		КонецЕсли;
		
	КонецЦикла;

	Если SortTableDifferences Тогда
		Result.Сортировать(OrderSortTableDifferences);
	КонецЕсли;
		
	If СообщениеОНаличииНесколькихСтрокПоОдномуКлючу Then
		Message(Формат(ТекущаяДата(),"ДЛФ=DT") + ": Обнаружены дубликаты (подсвечены красным цветом), настройки отбора на них не распространяются. Просмотреть дублирующиеся строки можно на форме предварительного просмотра.");
	EndIf;
	
EndProcedure

Function ПрочитатьДанныеИПолучитьТЗ(ИдентификаторБазы, ТекстОшибки = "", Подключение = Undefined) Export
	
	//Current или внешняя база 1С 8
	If ThisObject["BaseType" + ИдентификаторБазы] = 0 Or ThisObject["BaseType" + ИдентификаторБазы] = 1 Then
		 ТЗ = ВыполнитьЗапрос1С8ИПолучитьТЗ(ИдентификаторБазы, ТекстОшибки, Подключение);
	//SQL
	ElsIf ThisObject["BaseType" + ИдентификаторБазы] = 2 Then		
		ТЗ = ВыполнитьЗапросSQLИПолучитьТЗ(ИдентификаторБазы, ТекстОшибки);
	//File
	ElsIf ThisObject["BaseType" + ИдентификаторБазы] = 3 Then
		ТЗ = ПрочитатьДанныеИзФайлаИПолучитьТЗ(ИдентификаторБазы, ТекстОшибки);
	//Table
	ElsIf ThisObject["BaseType" + ИдентификаторБазы] = 4 Then		
		ТЗ = ПолучитьДанныеИзТабличногоДокумента(ИдентификаторБазы, ТекстОшибки);
	//Outer база 1С 7.7
	ElsIf ThisObject["BaseType" + ИдентификаторБазы] = 5 Then		
		ТЗ = ВыполнитьЗапрос1С77ИПолучитьТЗ(ИдентификаторБазы, ТекстОшибки);
	//JSON
	ElsIf ThisObject["BaseType" + ИдентификаторБазы] = 6 Then		
		ТЗ = ПрочитатьДанныеИзJSONИПолучитьТЗ(ИдентификаторБазы, ТекстОшибки);
	Else
		ТекстОшибки = "Type базы " + ИдентификаторБазы + " '" + ThisObject["BaseType" + ИдентификаторБазы] + "' не предусмотрен";
		Message(Формат(ТекущаяДата(),"ДЛФ=DT") + ": " + ТекстОшибки);
		ТЗ = Undefined;
	EndIf;
	
	If ThisObject["BaseType" + ИдентификаторБазы] >= 3 And ThisObject["CollapseTable" + ИдентификаторБазы] Then
		СтолбцыКлюча = "Key1";
		If NumberColumnsInKey > 1 Then
			СтолбцыКлюча = СтолбцыКлюча + ",Key2";
		EndIf;
		If NumberColumnsInKey > 2 Then
			СтолбцыКлюча = СтолбцыКлюча + ",Key3";
		EndIf;
		ТЗ.Collapse(СтолбцыКлюча,"Реквизит1,Реквизит2,Реквизит3,Реквизит4,Реквизит5");
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ВыполнитьЗапрос1С8ИПолучитьТЗ(ИдентификаторБазы, ТекстОшибок = "", Подключение = Undefined)
	
	//Current
	If ThisObject["BaseType" + ИдентификаторБазы] = 0 Then
		
		Query = New Query;
		Query.Text = ThisObject["QueryText" + ИдентификаторБазы];
		
		УстановитьПараметры(Query, ИдентификаторБазы); 
		
	//Outer
	ElsIf ThisObject["BaseType" + ИдентификаторБазы] = 1 Then
		
		If ThisObject["WorkOptionExternalBase" + ИдентификаторБазы] = 0 Then
			ПараметрСоединения = 
				"File=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "PathBase"]
				+ """;Usr=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Login"]
				+ """;Pwd=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Password"] + """;";	
		Else
			ПараметрСоединения = 
				"Srvr=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Server"]
				+ """;Ref=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "PathBase"] 
				+ """;Usr=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Login"] 
				+ """;Pwd=""" + ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Password"] + """;";
		EndIf;
				
		Try
			COMConnector = New COMObject(ThisObject["ВерсияПлатформыВнешнейБазы" + ИдентификаторБазы] + ".COMConnector");
			Подключение = COMConnector.Connect(ПараметрСоединения);
		Except
			ТекстОшибки = ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined;
		EndTry;

		Query = Подключение.NewObject("Query");
		Query.Text = ThisObject["QueryText" + ИдентификаторБазы];
		
		УстановитьПараметры(Query, ИдентификаторБазы); 
	
	EndIf;
	
	Query.SetParameter("ValidFrom", 	AbsolutePeriodValue.ValidFrom);
	Query.SetParameter("ValidTo", 	AbsolutePeriodValue.ValidTo);
	
	Try
		ТЗ = Query.Execute().Unload();
	Except
		ТекстОшибки = ErrorDescription();
		ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
		ТЗ = Undefined;
	EndTry;
	
	If ТЗ <> Undefined Then
				
		ЧислоКолонокВТЗ = ТЗ.Columns.Count();
		If NumberColumnsInKey > ЧислоКолонокВТЗ Then
			ТекстОшибки = "Выборка из источника " + ИдентификаторБазы + " содержит " + ЧислоКолонокВТЗ + " колонок, проверьте корректность заданного числа столбцов в ключе";
			UserMessage = New UserMessage;
			UserMessage.Text = ТекстОшибки;
			UserMessage.Field = "Object.NumberColumnsInKey";
			UserMessage.Message();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined;
		EndIf;
		    
		For AttributesCounter = 1 To Min(ЧислоКолонокВТЗ - NumberColumnsInKey, ЧислоРеквизитов) Do //
			
			Если ЭтотОбъект["НастройкиФайла" + ИдентификаторБазы].Количество() >= AttributesCounter Тогда
				ЗаголовокРеквизитаИзНастроек = ЭтотОбъект["НастройкиФайла" + ИдентификаторБазы][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			Иначе
				ЗаголовокРеквизитаИзНастроек = "";
			КонецЕсли;
			
			ИмяРеквизита = String(ИдентификаторБазы) + AttributesCounter;			
			ПредставленияЗаголовковРеквизитов[ИмяРеквизита] = ИмяРеквизита + ": " + ?(ПустаяСтрока(ЗаголовокРеквизитаИзНастроек), ТЗ.Колонки.Get(AttributesCounter + NumberColumnsInKey - 1).Title, ЗаголовокРеквизитаИзНастроек);
			
		
		EndDo; 
		
		If (ThisObject["UseAsKeyUniqueIdentifier" + ИдентификаторБазы]
			Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] 
			Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] 
			Or ThisObject["CastKeyToString" + ИдентификаторБазы]
			Or ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы])
			Or NumberColumnsInKey > 1 And 
			(ThisObject["UseAsKey2UniqueIdentifier" + ИдентификаторБазы] 
			Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] 
			Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] 
			Or ThisObject["CastKey2ToString" + ИдентификаторБазы]
			Or ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы])
			Or NumberColumnsInKey > 2 And 
			(ThisObject["UseAsKey3UniqueIdentifier" + ИдентификаторБазы] 
			Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] 
			Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] 
			Or ThisObject["CastKey3ToString" + ИдентификаторБазы]
			Or ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы])Then
			
			ИмяПервойКолонки 	= ТЗ.Columns.Get(0).Name;
			ИмяКолонкиКлюч1		= ИмяПервойКолонки;
			НомерКолонкиКлюч1	= 0;
			НомерКолонкиКлюч2	= 1;
			НомерКолонкиКлюч3	= 2;
			
			If NumberColumnsInKey > 1 Then
				ИмяВторойКолонки = ТЗ.Columns.Get(1).Name;
				ИмяКолонкиКлюч2 = ИмяВторойКолонки;
			Else
				ИмяВторойКолонки = "";
				ИмяКолонкиКлюч2 = "";
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				ИмяТретьейКолонки = ТЗ.Columns.Get(2).Name;
				ИмяКолонкиКлюч3 = ИмяТретьейКолонки;
			Else
				ИмяТретьейКолонки = "";
				ИмяКолонкиКлюч3 = "";
			EndIf;
			
			If ThisObject["UseAsKeyUniqueIdentifier" + ИдентификаторБазы]
				Or ThisObject["CastKeyToString" + ИдентификаторБазы] 
				Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
				
				ИмяКолонкиКлюч1 = "Key1" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
				ТЗ.Columns.Insert(НомерКолонкиКлюч1, ИмяКолонкиКлюч1);
				НомерКолонкиКлюч2 = НомерКолонкиКлюч2 + 1;
				НомерКолонкиКлюч3 = НомерКолонкиКлюч3 + 1;

			EndIf;
		
			If NumberColumnsInKey > 1 Then
			
				If ThisObject["UseAsKey2UniqueIdentifier" + ИдентификаторБазы]
					Or ThisObject["CastKey2ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
					
					ИмяКолонкиКлюч2 = "Key2" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(НомерКолонкиКлюч2, ИмяКолонкиКлюч2);
					НомерКолонкиКлюч3 = НомерКолонкиКлюч3 + 1;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ThisObject["UseAsKey3UniqueIdentifier" + ИдентификаторБазы]
					Or ThisObject["CastKey3ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
					
					ИмяКолонкиКлюч3 = "Key3" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(НомерКолонкиКлюч3, ИмяКолонкиКлюч3);
					
				EndIf;
				
			EndIf;
			
			//Indexing
			КолонкиСКлючомСтрокой = ИмяКолонкиКлюч1;
			If NumberColumnsInKey > 1 Then
				КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + "," + ИмяКолонкиКлюч2;
			EndIf;
			If NumberColumnsInKey > 2 Then
				КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + "," + ИмяКолонкиКлюч3;
			EndIf;

			ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
			       						
			СчетчикСтрок = 0;
			For Each СтрокаТЗ In ТЗ Do
				
				СчетчикСтрок = СчетчикСтрок + 1;
								
				Try
					
					If ThisObject["UseAsKeyUniqueIdentifier" + ИдентификаторБазы] Then
						If ThisObject["BaseType" + ИдентификаторБазы] = 0 Then
							СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(XMLString(СтрокаТЗ[ИмяПервойКолонки]));
						Else
							СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Подключение.XMLString(СтрокаТЗ[ИмяПервойКолонки]));
						EndIf;
					ElsIf ThisObject["CastKeyToString" + ИдентификаторБазы]
						Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы]
						Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(String(СтрокаТЗ[ИмяПервойКолонки]));
					EndIf;
					
					If ThisObject["KeyLengthWhenCastingToString" + ИдентификаторБазы] > 0 Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Left(СтрокаТЗ[ИмяКолонкиКлюч1], ThisObject["KeyLengthWhenCastingToString" + ИдентификаторБазы]));
					EndIf;
						
					If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч1])));
					EndIf;
					
					If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч1]), "{", ""), "}", ""));
					EndIf;
					
				Except
					
					ТекстОшибки = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndTry;
				
				If NumberColumnsInKey > 1 Then
						
					Try
						
						If ThisObject["UseAsKey2UniqueIdentifier" + ИдентификаторБазы] Then
							If ThisObject["BaseType" + ИдентификаторБазы] = 0 Then
								СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(XMLString(СтрокаТЗ[ИмяВторойКолонки]));
							Else
								СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Подключение.XMLString(СтрокаТЗ[ИмяВторойКолонки]));
							EndIf;
						ElsIf ThisObject["CastKey2ToString" + ИдентификаторБазы]
							Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы]
							Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(String(СтрокаТЗ[ИмяВторойКолонки]));
						EndIf;

						
						If ThisObject["KeyLength2WhenCastingToString" + ИдентификаторБазы] > 0 Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Left(СтрокаТЗ[ИмяКолонкиКлюч2], ThisObject["KeyLengthWhenCastingToString" + ИдентификаторБазы]));
						EndIf;
						
						If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч2])));
						EndIf;
						
						If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч2]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ТекстОшибки = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndTry;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
						
					Try
						
						If ThisObject["UseAsKey3UniqueIdentifier" + ИдентификаторБазы] Then
							If ThisObject["BaseType" + ИдентификаторБазы] = 0 Then
								СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(XMLString(СтрокаТЗ[ИмяТретьейКолонки]));
							Else
								СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Подключение.XMLString(СтрокаТЗ[ИмяТретьейКолонки]));
							EndIf;
						ElsIf ThisObject["CastKey3ToString" + ИдентификаторБазы]
							Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы]
							Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(String(СтрокаТЗ[ИмяТретьейКолонки]));
						EndIf;
						
						If ThisObject["KeyLength3WhenCastingToString" + ИдентификаторБазы] > 0 Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Left(СтрокаТЗ[ИмяКолонкиКлюч3], ThisObject["KeyLengthWhenCastingToString" + ИдентификаторБазы]));
						EndIf;
						
						If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч3])));
						EndIf;
						
						If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч3]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ТекстОшибки = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndTry;
					
				EndIf;
						
#Region Произвольный_код_обработки_ключа

				КлючТек = СтрокаТЗ[ИмяКолонкиКлюч1];
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + КлючТек + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаТЗ[ИмяКолонкиКлюч1] = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч2];
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + КлючТек + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч2] = КлючТек;
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч3];
					If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + КлючТек + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч3] = КлючТек;
				EndIf;
	
#EndRegion
				
			EndDo;
			
			If ThisObject["UseAsKeyUniqueIdentifier" + ИдентификаторБазы] 
				Or ThisObject["CastKeyToString" + ИдентификаторБазы] 
				Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
			
				ТЗ.Columns.Delete(ИмяПервойКолонки);
			
			EndIf;
		
			If NumberColumnsInKey > 1 Then
								
				If ThisObject["UseAsKey2UniqueIdentifier" + ИдентификаторБазы] 
					Or ThisObject["CastKey2ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
					
					ТЗ.Columns.Delete(ИмяВторойКолонки);
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
								
				If ThisObject["UseAsKey3UniqueIdentifier" + ИдентификаторБазы] 
					Or ThisObject["CastKey3ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
					
					ТЗ.Columns.Delete(ИмяТретьейКолонки);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ВыполнитьЗапрос1С77ИПолучитьТЗ(ИдентификаторБазы, ТекстОшибок = "", Подключение = Undefined)
	
	PathBase = ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "PathBase"];
	User = ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Login"];
	Password = ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Password"];
		
	Подключение = New COMObject("V1CEnterprise.Application");
    
    Try   
		
		СтрокаПодключения = "/D"""+TrimAll(PathBase)+""" /N"""+TrimAll(User)+""" /P"""+TrimAll(Password)+"""";
        ПодключениеУстановлено = Подключение.Initialize(Подключение.RMTrade,СтрокаПодключения,"NO_SPLASH_SHOW");
        
        If ПодключениеУстановлено Then
            ЕстьПодключение = True;
        Else
            ТекстОшибки = "Error при подключении к внешней базе";
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined;
        EndIf;    
    Except
        ТекстОшибки = "Error при подключении к внешней базе: " + ErrorDescription();
		ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
		Return Undefined;
	EndTry;
		
	Query = Подключение.CreateObject("Query");
	QueryText = ThisObject["QueryText" + ИдентификаторБазы];
	
	If Query.Execute(QueryText) = 0 Then
		Return Undefined;
	EndIf;

	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key1");
	If NumberColumnsInKey > 1 Then
		ТЗ.Columns.Add("Key2");
	EndIf;
	If NumberColumnsInKey > 2 Then
		ТЗ.Columns.Add("Key3");
	EndIf;
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	ТаблицаЗначений1С77 = Подключение.CreateObject("ValueTable");
	Query.Unload(ТаблицаЗначений1С77,1,0);	
	LineCount = ТаблицаЗначений1С77.LineCount();
	ColumnsCount = ТаблицаЗначений1С77.ColumnsCount();
	For СчетчикСтрок = 1 To LineCount Do
		
		СтрокаТЗ = ТЗ.Add();
			
		Ключ1 = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, 1);
		
		If NumberColumnsInKey > 1 Then
			Ключ2 = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, 2);
		Else
			Ключ2 = "";				
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			Ключ3 = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, 3);
		Else
			Ключ3 = "";				
		EndIf;
		
		Try
			
			If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
				Ключ1 = TrimAll(String(Ключ1));
			EndIf;
		
			If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
				Ключ1 = TrimAll(Upper(String(Ключ1)));
			EndIf;
			
			If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
				Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
			EndIf;
			
		Except
			
			ТекстОшибки = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			
		EndTry;
		
		If NumberColumnsInKey > 1 Then
			
			Try
			
				If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
					Ключ2 = TrimAll(String(Ключ2));
				EndIf;
			
				If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
					Ключ2 = TrimAll(Upper(String(Ключ2)));
				EndIf;
				
				If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
					Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
				EndIf;
			
			Except
				
				ТекстОшибки = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
			EndTry;
			
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			Try
			
			If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
				Ключ3 = TrimAll(String(Ключ3));
			EndIf;
		
			If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
				Ключ3 = TrimAll(Upper(String(Ключ3)));
			EndIf;
			
			If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
				Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
			EndIf;
			
			Except
				
				ТекстОшибки = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
			EndTry;
			
		EndIf;
			          			
#Region Произвольный_код_обработки_ключа

			КлючТек = Ключ1;
			If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
				Except
					ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
					Message(ТекстОшибки);
				EndTry;
			EndIf;
			СтрокаТЗ.Key1 = КлючТек;
			
			If NumberColumnsInKey > 1 Then
				КлючТек = Ключ2;				
				If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаТЗ.Key2 = КлючТек;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				КлючТек = Ключ3;
				If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаТЗ.Key3 = КлючТек;
			EndIf;
			
#EndRegion 
			
		For СчетчикКолонок = 1 To Min(ЧислоРеквизитов, ColumnsCount - NumberColumnsInKey) Do    
			
			//ColumnName = = ТаблицаЗначений1С77.ПолучитьПараметрыКолонки(СчетчикКолонок);
			ЗначениеЯчейки = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, СчетчикКолонок + NumberColumnsInKey);
			СтрокаТЗ["Attribute" + СчетчикКолонок] = ЗначениеЯчейки;
			
		EndDo;
				
	EndDo;
	
	Подключение.Exit(0);
	
	Подключение = Undefined;
		
	//Query = CreateObject("Query");
	//QueryText = 
	//"//{{ЗАПРОС(Сформировать)
	//|с ВыбНачПериода по ВыбКонПериода;
	//|Бренд = Catalog.Товары.Бренд;
	//|Товар = Catalog.Товары.Title;
	//|Balance = Catalog.Товары.Balance;
	//|Function СуммаОстаток = Сумма(Balance);
	//|Group Бренд;	
	//|"//}}ЗАПРОС
	//;
	// If ошибка в запросе, то выход из процедуры
	//If Query.Execute(QueryText) = 0 Then
	//	Return;
	//EndIf;
	
	//ТаблицаЗначений1С77 = CreateObject("ValueTable");
	//Query.Unload(ТаблицаЗначений1С77,1,0);	
	//LineCount = ТаблицаЗначений1С77.LineCount();
	//ColumnsCount = ТаблицаЗначений1С77.ColumnsCount();
	//For СчетчикСтрок = 1 To LineCount Do
	//	ВсяСтрока = "";
	//	For СчетчикКолонок = 1 To ТаблицаЗначений1С77.ColumnsCount() Do    
	//		//ColumnName = = ТаблицаЗначений1С77.ПолучитьПараметрыКолонки(СчетчикКолонок);
	//		ЗначениеЯчейки = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, СчетчикКолонок); 
	//		ВсяСтрока = ВсяСтрока + ", " + ЗначениеЯчейки;
	//	EndDo;
	//	Message(ВсяСтрока);
	//	
	//EndDo
	
#Region Заполнение_ТЗ
	
	If ТЗ <> Undefined Then
		
		If (ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] 
		Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] 
		Or ThisObject["CastKeyToString" + ИдентификаторБазы]
		Or ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы])
		Or NumberColumnsInKey > 1 And 
		(ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] 
		Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] 
		Or ThisObject["CastKey2ToString" + ИдентификаторБазы]
		Or ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы])
		Or NumberColumnsInKey > 2 And 
		(ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] 
		Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] 
		Or ThisObject["CastKey3ToString" + ИдентификаторБазы]
		Or ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы])Then
		
			ИмяПервойКолонки = ТЗ.Columns.Get(0).Name;
			
			If NumberColumnsInKey > 1 Then
				ИмяВторойКолонки = ТЗ.Columns.Get(1).Name;
			Else
				ИмяВторойКолонки = "";
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				ИмяТретьейКолонки = ТЗ.Columns.Get(2).Name;
			Else
				ИмяТретьейКолонки = "";
			EndIf;
			
			ИмяКолонкиКлюч1 		= ТЗ.Columns.Get(0).Name;
			If NumberColumnsInKey > 1 Then
				ИмяКолонкиКлюч2 = ТЗ.Columns.Get(1).Name;
			Else
				ИмяКолонкиКлюч2 = "";
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				ИмяКолонкиКлюч3 = ТЗ.Columns.Get(2).Name;
			Else
				ИмяКолонкиКлюч3 = "";
			EndIf;
			
			If ThisObject["CastKeyToString" + ИдентификаторБазы] 
				Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
				
				ИмяКолонкиКлюч1 = "Key1" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
				ТЗ.Columns.Insert(0, ИмяКолонкиКлюч1);//, ОписаниеСтроки);

			EndIf;
		
			If NumberColumnsInKey > 1 Then
			
				If ThisObject["CastKey2ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
					
					ИмяКолонкиКлюч2 = "Key2" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(1, ИмяКолонкиКлюч2);
				EndIf;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ThisObject["CastKey3ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
					
					ИмяКолонкиКлюч3 = "Key3" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(2, ИмяКолонкиКлюч3);
				EndIf;
			EndIf;
			       						
			СчетчикСтрок = 0;			
			For Each СтрокаТЗ In ТЗ Do
				
				СчетчикСтрок = СчетчикСтрок + 1;
				
				Try
					
					If ThisObject["CastKeyToString" + ИдентификаторБазы]
						Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы]
						Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(String(СтрокаТЗ[ИмяПервойКолонки]));
					EndIf;
						
					If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч1])));
					EndIf;
					
					If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч1]), "{", ""), "}", ""));
					EndIf;
					
				Except
					
					ТекстОшибки = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndTry;
				
				If NumberColumnsInKey > 1 Then
						
					Try
						
						If ThisObject["CastKey2ToString" + ИдентификаторБазы]
							Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы]
							Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(String(СтрокаТЗ[ИмяВторойКолонки]));
						EndIf;

						If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч2])));
						EndIf;
						
						If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч2]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ТекстОшибки = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndTry;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
						
					Try
						
						If ThisObject["CastKey3ToString" + ИдентификаторБазы]
							Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы]
							Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(String(СтрокаТЗ[ИмяТретьейКолонки]));
						EndIf;
						
						If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч3])));
						EndIf;
						
						If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч3]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ТекстОшибки = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndTry;
					
				EndIf;
						
	#Region Произвольный_код_обработки_ключа

				КлючТек = СтрокаТЗ[ИмяКолонкиКлюч1];
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + КлючТек + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаТЗ[ИмяКолонкиКлюч1] = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч2];
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + КлючТек + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч2] = КлючТек;
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч3];
					If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + КлючТек + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч3] = КлючТек;
				EndIf;

	#EndRegion
				
			EndDo;
			
			If ThisObject["CastKeyToString" + ИдентификаторБазы] 
				Or ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
			
				ТЗ.Columns.Delete(ИмяПервойКолонки);
			
			EndIf;
		
			If NumberColumnsInKey > 1 Then
								
				If ThisObject["CastKey2ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
					
					ТЗ.Columns.Delete(ИмяВторойКолонки);
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
								
				If ThisObject["CastKey3ToString" + ИдентификаторБазы] 
					Or ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
					
					ТЗ.Columns.Delete(ИмяТретьейКолонки);
					
				EndIf;
				
			EndIf;
			
		EndIf;
	
#EndRegion
	
		//Индексирование
		КолонкиСКлючомСтрокой = ИмяКолонкиКлюч1;
		Если ЧислоСтолбцовВКлюче > 1 Тогда
			КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + "," + ИмяКолонкиКлюч2;
		КонецЕсли;
		Если ЧислоСтолбцовВКлюче > 2 Тогда
			КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + "," + ИмяКолонкиКлюч3;
		КонецЕсли;

		ТЗ.Индексы.Добавить(КолонкиСКлючомСтрокой);
		
		Для СчетчикРеквизитов = 1 По ЭтотОбъект["НастройкиФайла" + ИдентификаторБазы].Количество() Цикл
			
			ИмяРеквизита = Строка(ИдентификаторБазы) + СчетчикРеквизитов;
			ЗаголовокРеквизитаИзНастроек = ЭтотОбъект["НастройкиФайла" + ИдентификаторБазы][СчетчикРеквизитов - 1].ЗаголовокРеквизитаДляПользователя;
			
			ПредставленияЗаголовковРеквизитов[ИмяРеквизита] = ?(ПустаяСтрока(ЗаголовокРеквизитаИзНастроек), "Реквизит " + ИдентификаторБазы + СчетчикРеквизитов, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		КонецЦикла;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ВыполнитьЗапросSQLИПолучитьТЗ(ИдентификаторБазы, ТекстОшибок = "")
	
	ServerName =  ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Server"];
	DSN 	= ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "PathBase"];                                                                                                           
	UID 	= ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Login"];
	PWD 	= ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "Password"];
	Driver 	= ThisObject["ConnectionToExternalBase" + ИдентификаторБазы + "ДрайверSQL"];
	
	Try              
		ConnectString = "Driver={" + Driver + "};Server="+ServerName+";Database="+DSN+";Uid="+UID+";Pwd="+PWD;
		Соединение = New COMObject("ADODB.Connection");
		Соединение.Open(ConnectString); 
	Except
		ТекстОшибки = ErrorDescription();
		Message("Not удалось подключиться к : " + ТекстОшибки);
		Return Undefined;
	EndTry;
	
	СмещениеНомераРеквизита = NumberColumnsInKey - 1;
		
	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key1");
	КолонкиСКлючомСтрокой = "Key1";
	
	If NumberColumnsInKey > 1 Then
		ТЗ.Columns.Add("Key2");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Key2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ТЗ.Columns.Add("Key3");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Key3";
	EndIf;
	
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	Try
		
		Рекордсет = New COMObject("ADODB.RecordSet"); 
		Command = New COMObject("ADODB.Command");
		Command.ActiveConnection = Соединение;
		Command.CommandText = ThisObject["QueryText" + ИдентификаторБазы];
		Command.CommandType = 1;
		
		Рекордсет = Command.Execute();
		
		ЧислоКолонокВТЗ = Рекордсет.Fields.Count;
		If NumberColumnsInKey > ЧислоКолонокВТЗ Then
			
			ТекстОшибки = "Выборка содержит " + ЧислоКолонокВТЗ + " кол., проверьте корректность заданного числа столбцов в ключе";
			UserMessage = New UserMessage;
			UserMessage.Text = ТекстОшибки;
			UserMessage.Field = "Object.NumberColumnsInKey";
			UserMessage.Message();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Рекордсет.Close();
			Соединение.Close();
			
			Return Undefined;
			
		EndIf;
				
		СчетчикСтрок = 0;			
		While Рекордсет.EOF = 0 Do
			
			СчетчикСтрок = СчетчикСтрок + 1;
			
			If СчетчикСтрок = 1 Then
				
				For AttributesCounter = 1 To Min(ЧислоКолонокВТЗ - NumberColumnsInKey, ЧислоРеквизитов) Do
					
					ИмяРеквизита = String(ИдентификаторБазы) + AttributesCounter;
					ПредставленияЗаголовковРеквизитов[ИмяРеквизита] = ИмяРеквизита + ": " + Рекордсет.Fields(AttributesCounter + NumberColumnsInKey - 1).Name;
				
				EndDo; 
				
			EndIf;
			
			СтрокаТЗ = ТЗ.Add();
			
			Ключ1 = Рекордсет.Fields(0).Value;
			
			If NumberColumnsInKey > 1 Then
				Ключ2 = Рекордсет.Fields(1).Value;
			Else
				Ключ2 = "";				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				Ключ3 = Рекордсет.Fields(2).Value;
			Else
				Ключ3 = "";				
			EndIf;
			
			Try
				
				If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
				
			Except
				
				ТекстОшибки = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
			EndTry;
			
			If NumberColumnsInKey > 1 Then
				
				Try
				
					If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
				
				Except
					
					ТекстОшибки = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndTry;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				
				Try
				
				If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
					Ключ3 = TrimAll(String(Ключ3));
				EndIf;
			
				If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
					Ключ3 = TrimAll(Upper(String(Ключ3)));
				EndIf;
				
				If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
					Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
				EndIf;
				
				Except
					
					ТекстОшибки = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + ИдентификаторБазы + ": " + ErrorDescription();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndTry;
				
			EndIf;
			          			
#Region Произвольный_код_обработки_ключа

			КлючТек = Ключ1;
			If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
				Except
					ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
					Message(ТекстОшибки);
				EndTry;
			EndIf;
			СтрокаТЗ.Key1 = КлючТек;
			
			If NumberColumnsInKey > 1 Then
				КлючТек = Ключ2;				
				If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаТЗ.Key2 = КлючТек;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				КлючТек = Ключ3;
				If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаТЗ.Key3 = КлючТек;
			EndIf;
			
#EndRegion 
			
			ЧислоКолонокВВыборке = Рекордсет.Fields.Count;
			
			For Счетчик = 1 To Min(ЧислоРеквизитов, ЧислоКолонокВВыборке - NumberColumnsInKey) Do
				СтрокаТЗ["Attribute" + Счетчик] = Рекордсет.Fields(Счетчик + NumberColumnsInKey - 1).Value 
			EndDo;
			
			Рекордсет.MoveNext();
			
		EndDo;

		Рекордсет.Close();
		Соединение.Close();
		
	Except
		
		ТекстОшибки = ErrorDescription();
		ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
		ТЗ = Undefined;
		
	EndTry;
	
	//Indexing
	If ТЗ <> Undefined Then
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ПрочитатьДанныеИзФайлаИПолучитьТЗ(ИдентификаторБазы, ТекстОшибок = "")
	
	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key1");
	КолонкиСКлючомСтрокой = "Key1";
	
	If NumberColumnsInKey > 1 Then
		ТЗ.Columns.Add("Key2");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Key2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ТЗ.Columns.Add("Key3");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Key3";
	EndIf;
	
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	ПутьКФайлу 			= ThisObject["ConnectionToExternalBase"		+ ИдентификаторБазы + "ПутьКФайлу"];
	ФорматФайла 		= ThisObject["ConnectionToExternalBase" 		+ ИдентификаторБазы + "ФорматФайла"];
	НомерПервойСтроки 	= ThisObject["НомерПервойСтрокиФайла" 		+ ИдентификаторБазы];
	SettingsFile 		= ThisObject["SettingsFile" 				+ ИдентификаторБазы];
	НомерТаблицы		= ThisObject["ConnectionToExternalBase"		+ ИдентификаторБазы + "НомерТаблицыВФайле"];
	
	НомерСтолбцаСКлючом = ThisObject["ColumnNumberKeyFromFile" 	+ ИдентификаторБазы];
	ИмяСтолбцаСКлючом 	= ThisObject["ColumnNameKeyFromFile" 	+ ИдентификаторБазы];	
	If NumberColumnsInKey > 1 Then
		НомерСтолбцаСКлючом2 	= ThisObject["ColumnNumberKey2FromFile" + ИдентификаторБазы];
		ИмяСтолбцаСКлючом2 		= ThisObject["ColumnNameKey2FromFile" + ИдентификаторБазы];
	EndIf;	
	If NumberColumnsInKey > 2 Then
		НомерСтолбцаСКлючом3 	= ThisObject["ColumnNumberKey3FromFile" + ИдентификаторБазы];
		ИмяСтолбцаСКлючом3 		= ThisObject["ColumnNameKey3FromFile" + ИдентификаторБазы];
	EndIf;
	
	//Проверка открытия файла
	If ФорматФайла = "XLS" Then
		
		Try
			Excel = New COMObject("Excel.Application");
			Excel.DisplayAlerts = 0;
			Excel.Visible = False;
			
			Книга = Excel.WorkBooks.Open(ПутьКФайлу);
			File = Книга.WorkSheets(НомерТаблицы);
		Except
			ТекстОшибки = "Error при открытии XLS-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined;
		EndTry;
		
		xlCellTypeLastCell = 11;
		
		Try
			НомерПоследнейСтроки = File.Cells.SpecialCells(xlCellTypeLastCell).Row;			
		Except
			Message("Error при определении номера последней строки в файле. Number последней строки установлен в 1000");
			НомерПоследнейСтроки = 1000;
		EndTry;
		
		Try
			НомерПоследнейКолонки = File.Cells.SpecialCells(xlCellTypeLastCell).Column;
		Except			
			НомерПоследнейКолонки = 1000;
		EndTry;
				
	ElsIf ФорматФайла = "DOC" Then
		
		Try
			Word = New COMObject("Word.Application");
			Word.DisplayAlerts = 0;
			Word.Visible = False;
			
			Word.Application.Documents.Open(ПутьКФайлу);
			Document = Word.ActiveDocument();
			
		Except
			ТекстОшибки = "Error при открытии DOC-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Word = Undefined;
			Return Undefined;
		EndTry;
		
		Try 
			File = Document.Tables(НомерТаблицы);
		Except
			ТекстОшибки = "Error при обращении к таблице " + НомерТаблицы + " DOC-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Document.Close(0);
			Word.Quit();
			Return Undefined;
		EndTry;

		Try
			НомерПоследнейСтроки = File.Rows.count;
		Except
			Message("Error при определении номера последней строки в файле. Number последней строки установлен в 1000");
			НомерПоследнейСтроки = 1000;
		EndTry;
		
	ElsIf ФорматФайла = "CSV" Or ФорматФайла = "TXT" Then
		
		Try
			File = New TextDocument();
			File.Read(ПутьКФайлу);
			НомерПоследнейСтроки = File.LineCount(); 
		Except
			ТекстОшибки = "Error при открытии " + ФорматФайла + "-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined;
		EndTry;
		
	ElsIf ФорматФайла = "DBF" Then 
		
		Try
			ФайлDBF = New XBase;
			ФайлDBF.OpenFile(ПутьКФайлу,,True);
			НомерПоследнейСтроки = ФайлDBF.RecCount();
			ФайлDBF.First();
		Except
			ТекстОшибки = "Error при открытии DBF-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined;
		EndTry;

	ElsIf ФорматФайла = "XML" Then
		
		Try
			Парсер = New XMLReader;
		    Парсер.OpenFile(ПутьКФайлу);	 
		    Построитель = New DOMBuilder;	 
		    ФайлXML = Построитель.Read(Парсер);
		Except
			ТекстОшибки = "Error при открытии XML-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			Return Undefined
		EndTry;
		
	Else
		
		ТекстОшибки = "Format файла '" + ФорматФайла + "' не предусмотрен";
		ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
		Return Undefined;
		
	EndIf;
	
	//Processing строк
#Region XML
	
	If ФорматФайла = "XML" Then
		
		ИмяРодительскогоУзла = ThisObject["ИмяРодительскогоУзлаФайла" + ИдентификаторБазы];
		ИмяЭлементаСДаннымиФайла = ThisObject["ИмяЭлементаСДаннымиФайла" + ИдентификаторБазы];
		
		КорневойУзел = ФайлXML.DocumentElement;
		If IsBlankString(ИмяРодительскогоУзла) Then
			ParentNode = КорневойУзел
		Else
			ParentNode = НайтиПодчиненныйУзелXMLФайлаПоИмени(КорневойУзел, ИмяРодительскогоУзла);
		EndIf;
		
		If ParentNode <> Undefined Then
			
			For Each CurrentItem In ParentNode.ChildNodes Do
				
				If IsBlankString(ИмяЭлементаСДаннымиФайла) Or CurrentItem.NodeName = ИмяЭлементаСДаннымиФайла Then
					
#Region XML_СпособХраненияДанныхВXMLФайле_В_атрибутах
				
					If ThisObject["СпособХраненияДанныхВXMLФайле" + ИдентификаторБазы] = "В атрибутах" Then
						
						ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
												
						СтрокаПриемник = ТЗ.Add();
						
						Item = CurrentItem.Attributes.GetNamedItem(ИмяСтолбцаСКлючом);
						If Item = Undefined Then
							Raise "Attribute с именем " + ИмяСтолбцаСКлючом + " не найден";
						EndIf;
						
						Ключ1 = Item.Value;
						If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
							Ключ1 = TrimAll(Upper(String(Ключ1)));
						EndIf;
						If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
							Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
						EndIf;
						
						If NumberColumnsInKey > 1 Then
						
							Item = CurrentItem.Attributes.GetNamedItem(ИмяСтолбцаСКлючом2);
							If Item = Undefined Then
								Raise "Attribute с именем " + ИмяСтолбцаСКлючом2 + " не найден";
							EndIf;
							
							Ключ2 = Item.Value;
									
							If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
								Ключ2 = TrimAll(String(Ключ2));
							EndIf;
							
							If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
								Ключ2 = TrimAll(Upper(String(Ключ2)));
							EndIf;
							
							If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
								Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
							EndIf;
														
						EndIf;
						
						If NumberColumnsInKey > 2 Then
						
							Item = CurrentItem.Attributes.GetNamedItem(ИмяСтолбцаСКлючом3);
							If Item = Undefined Then
								Raise "Attribute с именем " + ИмяСтолбцаСКлючом3 + " не найден";
							EndIf;
							
							Ключ3 = Item.Value;
									
							If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
								Ключ3 = TrimAll(String(Ключ3));
							EndIf;
							
							If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
								Ключ3 = TrimAll(Upper(String(Ключ3)));
							EndIf;
							
							If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
								Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
							EndIf;
							
						EndIf;
						
#Region Произвольный_код_обработки_ключа

						КлючТек = Ключ1;
						If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
							Try
							    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
							Except
								ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
								Message(ТекстОшибки);
							EndTry;
						EndIf;
						
						СтрокаПриемник.Key1 = КлючТек;
						
						If NumberColumnsInKey > 1 Then
							
							КлючТек = Ключ2;
							If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
								Except
									ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
									Message(ТекстОшибки);
								EndTry;
							EndIf;
							СтрокаПриемник.Key2 = КлючТек;
							
						EndIf;
						
						If NumberColumnsInKey > 2 Then
							
							КлючТек = Ключ3;
							If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
								Except
									ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
									Message(ТекстОшибки);
								EndTry;
							EndIf;
							СтрокаПриемник.Key3 = КлючТек;
							
						EndIf;
						
#EndRegion  

						ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
						For Each СтрокаНастроекФайла In SettingsFile Do
							
							//Not задано имя колонки (например, если реквизит заполняется программно)
							If IsBlankString(СтрокаНастроекФайла.ColumnName) Then
								Continue;
							EndIf;
							
							ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
							Item = CurrentItem.Attributes.GetNamedItem(СтрокаНастроекФайла.ColumnName);
							If Item = Undefined Then
								Raise "Attribute с именем " + СтрокаНастроекФайла.ColumnName + " не найден";
							EndIf;
							СтрокаПриемник[ИмяРеквизита] = Item.Value;
							
							//FillType переменных, которые будут использоваться в произвольном коде
							РВрем = СтрокаПриемник[ИмяРеквизита];
							If СтрокаНастроекФайла.LineNumber = 1 Then
								Р1 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
								Р2 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
								Р3 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
								Р4 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
								Р5 = РВрем;
							EndIf;

						EndDo;
						
#EndRegion

#Region XML_СпособХраненияДанныхВXMLФайле_В_элементах
						
					ElsIf ThisObject["СпособХраненияДанныхВXMLФайле" + ИдентификаторБазы] = "В элементах" Then
						
						ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
						
						СтрокаПриемник = ТЗ.Add();
						
						For Each ДочернийЭлемент In CurrentItem.ChildNodes Do
							
							If ДочернийЭлемент.NodeName = ИмяСтолбцаСКлючом Then
								
								Ключ1 = ДочернийЭлемент.TextContent;
								If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
									Ключ1 = TrimAll(Upper(String(Ключ1)));
								EndIf;
								If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
									Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
								EndIf;
								
								СтрокаПриемник.Key1 = Ключ1;
								
							EndIf;
								
							If ДочернийЭлемент.NodeName = ИмяСтолбцаСКлючом2 And NumberColumnsInKey > 1 Then
								
								Ключ2 = ДочернийЭлемент.TextContent;
								If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
									Ключ2 = TrimAll(Upper(String(Ключ2)));
								EndIf;
								If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
									Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
								EndIf;
								
								СтрокаПриемник.Key2 = Ключ2;
			                    						
							EndIf;                
							
							If ДочернийЭлемент.NodeName = ИмяСтолбцаСКлючом3 And NumberColumnsInKey > 2 Then
								
								Ключ3 = ДочернийЭлемент.TextContent;
								If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
									Ключ3 = TrimAll(Upper(String(Ключ2)));
								EndIf;
								If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
									Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
								EndIf;
								
								СтрокаПриемник.Key3 = Ключ3;
			                    						
							EndIf;
							
							For Each СтрокаНастроекФайла In SettingsFile Do
							
								//Not задано имя колонки (например, если реквизит заполняется программно)
								If IsBlankString(СтрокаНастроекФайла.ColumnName) Then
									Continue;
								EndIf;
								
								TagName = СтрокаНастроекФайла.ColumnName;
								ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
								If ДочернийЭлемент.NodeName = TagName Then
									
									СтрокаПриемник[ИмяРеквизита] = ДочернийЭлемент.TextContent;;
									
								EndIf;
																
							EndDo;
							
						EndDo;
						
#Region Произвольный_код_обработки_ключа
						КлючТек = СтрокаПриемник.Key1;
						If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
							Try
							    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
							Except
								ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
								Message(ТекстОшибки);
							EndTry;
						EndIf;
						СтрокаПриемник.Key1 = КлючТек;
						
						If NumberColumnsInKey > 1 Then
							
							КлючТек = СтрокаПриемник.Key2;
							If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
								Except
									ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
									Message(ТекстОшибки);
								EndTry;
							EndIf;
							СтрокаПриемник.Key2 = КлючТек;
							
						EndIf;
						
						If NumberColumnsInKey > 2 Then
							КлючТек = СтрокаПриемник.Key3;
							If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
								Except
									ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
									Message(ТекстОшибки);
								EndTry;
							EndIf;
							СтрокаПриемник.Key3 = КлючТек;
						EndIf;
#EndRegion 

						ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
						For Each СтрокаНастроекФайла In SettingsFile Do
							//Not задано имя колонки (например, если реквизит заполняется программно)
							If IsBlankString(СтрокаНастроекФайла.ColumnName) Then
								Continue;
							EndIf;
							
							ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
							
							РВрем = СтрокаПриемник[ИмяРеквизита];
							If СтрокаНастроекФайла.LineNumber = 1 Then
								Р1 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
								Р2 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
								Р3 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
								Р4 = РВрем;
							ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
								Р5 = РВрем;
							EndIf;
							
						EndDo;
																		
					Else 
						Raise "Not задан способ хранения данных в XML-файле базы " + ИдентификаторБазы;				
					EndIf;
					
					For Each СтрокаНастроекФайла In SettingsFile Do
				
						ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
						РТек = СтрокаПриемник[ИмяРеквизита];

						Try
							Execute СтрокаНастроекФайла.ArbitraryCode;
						Except
							ТекстОшибки = ErrorDescription();
							Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ТекстОшибки);
						EndTry;
						
						If ThisObject["CollapseTable" + ИдентификаторБазы] Then
							Try
								Execute КодПриведенияРеквизитаКТипуЧисло;
							Except
								РТек = 0;
							EndTry;
						EndIf;
						
						СтрокаПриемник[ИмяРеквизита] = РТек;

					EndDo;
					
#EndRegion

				EndIf;
				
			EndDo; 
			
		EndIf;
		
#EndRegion 

	Else
	
		For НомерТекущейСтроки = НомерПервойСтроки To НомерПоследнейСтроки Do
			
			ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
			
			СтрокаПриемник = ТЗ.Add();
			
#Region XLS

			If ФорматФайла = "XLS" Then
				
				ЧислоКолонокВФайлеМеньшеТребуемого = False;
				
				If НомерСтолбцаСКлючом > НомерПоследнейКолонки Then
					ТекстОшибки = "File содержит " + НомерПоследнейКолонки + " кол., проверьте настройки столбцов ключа";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNumberKeyFromFile " + ИдентификаторБазы;
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					ЧислоКолонокВФайлеМеньшеТребуемого = True;
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 1 And НомерСтолбцаСКлючом2 > НомерПоследнейКолонки Then
					ТекстОшибки = "File содержит " + НомерПоследнейКолонки + " кол., проверьте настройки столбца 2 ключа";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNumberKey2FromFile " + ИдентификаторБазы;
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					ЧислоКолонокВФайлеМеньшеТребуемого = True;
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 And НомерСтолбцаСКлючом3 > НомерПоследнейКолонки Then
					ТекстОшибки = "File содержит " + НомерПоследнейКолонки + " кол., проверьте настройки столбца 3 ключа";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNumberKey3FromFile " + ИдентификаторБазы;
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					ЧислоКолонокВФайлеМеньшеТребуемого = True;
				EndIf;
				
				If ЧислоКолонокВФайлеМеньшеТребуемого Then
					
					Книга.Close(0);
					Excel.Quit();
					Return ТЗ;
					
				EndIf;
				
				Ключ1 = TrimAll(File.Cells(НомерТекущейСтроки, НомерСтолбцаСКлючом).Value);
							
				If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
				
				If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
								
				If ЧислоСтолбцовВКлюче > 1 Then			
					
					Ключ2 = TrimAll(File.Cells(НомерТекущейСтроки, НомерСтолбцаСКлючом2).Value);
							
					If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
					     										
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
										
					Ключ3 = TrimAll(File.Cells(НомерТекущейСтроки, НомерСтолбцаСКлючом3).Value);
							
					If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
				
				
#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаПриемник.Key = КлючТек;
				
				If ЧислоСтолбцовВКлюче > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
#EndRegion

				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
				For Each СтрокаНастроекФайла In SettingsFile Do
					//Not задан номер колонки (например, если реквизит заполняется программно)
					If СтрокаНастроекФайла.НомерКолонки = 0 Then
						Continue;
					EndIf;
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					
					If СтрокаНастроекФайла.НомерКолонки > НомерПоследнейКолонки Then
						ТекстОшибки = "File содержит " + НомерПоследнейКолонки + " кол., проверьте настройки колонок реквизитов";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.SettingsFile" + ИдентификаторБазы;
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						Return ТЗ;
					EndIf;
					
					СтрокаПриемник[ИмяРеквизита] = TrimAll(File.Cells(НомерТекущейСтроки, СтрокаНастроекФайла.НомерКолонки).Value);
					
					//FillType переменных, которые будут использоваться в произвольном коде
					РВрем = СтрокаПриемник[ИмяРеквизита];
					If СтрокаНастроекФайла.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;
							
#EndRegion 	

			
#Region DOC

			ElsIf ФорматФайла = "DOC" Then

				//In документа WORD попадают символы, которые 1С не может вывести в ТЗ на форме и выдает ошибку Text XML содержит недопустимый символ
	        	ЗаменяемыеСимволы = New Array;
				ЗаменяемыеСимволы.Add(Char(7));	//¶
				ЗаменяемыеСимволы.Add(Char(13));	//черный круг
								
				Ключ1 = TrimAll(File.Cell(НомерТекущейСтроки, НомерСтолбцаСКлючом).Range.Text);
				For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
					Ключ1 = StrReplace(Ключ1, ЗаменямыйСимвол, "");
				EndDo;
							
				If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
				
				If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
								
				If ЧислоСтолбцовВКлюче > 1 Then
					
					Ключ2 = TrimAll(File.Cell(НомерТекущейСтроки, НомерСтолбцаСКлючом2).Range.Text);
					For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
						Ключ2 = StrReplace(Ключ2, ЗаменямыйСимвол, "");
					EndDo;
					
					If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
					     										
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					Ключ3 = TrimAll(File.Cell(НомерТекущейСтроки, НомерСтолбцаСКлючом3).Range.Text);
					For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
						Ключ3 = StrReplace(Ключ3, ЗаменямыйСимвол, "");
					EndDo;

							
					If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
				
				
#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаПриемник.Key = КлючТек;
				
				If ЧислоСтолбцовВКлюче > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
#EndRegion

				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
				For Each СтрокаНастроекФайла In SettingsFile Do
					//Not задан номер колонки (например, если реквизит заполняется программно)
					If СтрокаНастроекФайла.НомерКолонки = 0 Then
						Continue;
					EndIf;
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					ЗнчениеРеквизита = TrimAll(File.Cell(НомерТекущейСтроки, СтрокаНастроекФайла.НомерКолонки).Range.Text);
					For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
						ЗнчениеРеквизита = StrReplace(ЗнчениеРеквизита, ЗаменямыйСимвол, "");
					EndDo;
					СтрокаПриемник[ИмяРеквизита] = ЗнчениеРеквизита;
					
					//FillType переменных, которые будут использоваться в произвольном коде
					РВрем = СтрокаПриемник[ИмяРеквизита];
					If СтрокаНастроекФайла.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;
							
#EndRegion 	


#Region CSV_TXT

			ElsIf ФорматФайла = "CSV" Or ФорматФайла = "TXT" Then

				СтрокаТекста = File.GetLine(НомерТекущейСтроки);
						
				If ФорматФайла = "CSV" Then
					СимволРазделителяКолонок = ";";
				Else
					СимволРазделителяКолонок = "	";
				EndIf;	
				
				СимволРазделителя = Chars.LF;
				
				СтрокаМногострочногоТекста = StrReplace(СтрокаТекста,СимволРазделителяКолонок,СимволРазделителя);
				
				Ключ1 = StrGetLine(СтрокаМногострочногоТекста,НомерСтолбцаСКлючом);
				
				If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
								
				If ЧислоСтолбцовВКлюче > 1 Then
					
					Ключ2 = StrGetLine(СтрокаМногострочногоТекста,НомерСтолбцаСКлючом2);
				
					If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
															
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					Ключ3 = StrGetLine(СтрокаМногострочногоТекста,НомерСтолбцаСКлючом3);
				
					If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
				
					If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаПриемник.Key = КлючТек;
				
				If ЧислоСтолбцовВКлюче > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;

				If ЧислоСтолбцовВКлюче > 2 Then
					
					КлючТек = Ключ3;
				 	If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
#EndRegion 

				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
				For Each СтрокаНастроекФайла In SettingsFile Do
					//Not задан номер колонки (например, если реквизит заполняется программно)
					If СтрокаНастроекФайла.НомерКолонки = 0 Then
						Continue;
					EndIf;
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					СтрокаПриемник[ИмяРеквизита] = StrGetLine(СтрокаМногострочногоТекста,СтрокаНастроекФайла.НомерКолонки);
					
					//FillType переменных, которые будут использоваться в произвольном коде
					РВрем = СтрокаПриемник[ИмяРеквизита];
					If СтрокаНастроекФайла.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;

#EndRegion 	


#Region DBF

			ElsIf ФорматФайла = "DBF" Then
				
				//На всякий случай, хотя такого не должно быть
				If ФайлDBF.EOF() Then
					Continue;
				EndIf;
				
				Ключ1 = ФайлDBF[ФайлDBF.Fields[НомерСтолбцаСКлючом - 1].Name];
				
				If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 1 Then
					
					Ключ2 = ФайлDBF[ФайлDBF.Fields[НомерСтолбцаСКлючом2 - 1].Name];
				
					If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					Ключ3 = ФайлDBF[ФайлDBF.Fields[НомерСтолбцаСКлючом3 - 1].Name];
				
					If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
				
					If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				СтрокаПриемник.Key = КлючТек;
				
				If ЧислоСтолбцовВКлюче > 1 Then

					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
#EndRegion  

				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
				For Each СтрокаНастроекФайла In SettingsFile Do
					//Not задан номер колонки (например, если реквизит заполняется программно)
					If СтрокаНастроекФайла.НомерКолонки = 0 Then
						Continue;
					EndIf;
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					СтрокаПриемник[ИмяРеквизита] = ФайлDBF[ФайлDBF.поля[СтрокаНастроекФайла.НомерКолонки - 1].Name];
					
					//FillType переменных, которые будут использоваться в произвольном коде
					РВрем = СтрокаПриемник[ИмяРеквизита];
					If СтрокаНастроекФайла.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;	
				
				ФайлDBF.Next();
							
			EndIf;

#EndRegion


#Region Произвольный_код_заполнения_реквизитов
			
			For Each СтрокаНастроекФайла In SettingsFile Do
				
				ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
				РТек = СтрокаПриемник[ИмяРеквизита];

				Try
					Execute СтрокаНастроекФайла.ПроизвольныйКод;
				Except
					ТекстОшибки = ErrorDescription();
					Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ТекстОшибки);
				EndTry;
				
				If ThisObject["CollapseTable" + ИдентификаторБазы] Then
					Try
						Execute КодПриведенияРеквизитаКТипуЧисло;
					Except
						РТек = 0;
					EndTry;
				EndIf;
				
				СтрокаПриемник[ИмяРеквизита] = РТек;
								
			EndDo;
			
#EndRegion 

		EndDo;

	EndIf;
	
	If ФорматФайла = "XLS" Then
		Книга.Close(0);
		Excel.Quit();
	ElsIf ФорматФайла = "DOC" Then
		Document.Close(0);
		Word.Quit();
	ElsIf ФорматФайла = "DBF" Then
		ФайлDBF.CloseFile();
	ElsIf ФорматФайла = "XML" Then
		Парсер.Close();
	EndIf;
	
	//Indexing
	If ТЗ <> Undefined Then
		
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + ИдентификаторБазы].Count() Do
			
			ИмяРеквизита = String(ИдентификаторБазы) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ThisObject["SettingsFile" + ИдентификаторБазы][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ПредставленияЗаголовковРеквизитов[ИмяРеквизита] = ?(IsBlankString(ЗаголовокРеквизитаИзНастроек), "Attribute " + ИдентификаторБазы + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ПрочитатьДанныеИзJSONИПолучитьТЗ(ИдентификаторБазы, ТекстОшибок = "")
	
	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key");
	КолонкиСКлючомСтрокой = "Key";
	
	If ЧислоСтолбцовВКлюче > 1 Then
		ТЗ.Columns.Add("Ключ2");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ2";
	EndIf;
	
	If ЧислоСтолбцовВКлюче > 2 Then
		ТЗ.Columns.Add("Ключ3");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ3";
	EndIf;
	
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	//ПутьКФайлу 			= ThisObject["ConnectionToExternalBase"		+ ИдентификаторБазы + "ПутьКФайлу"];
	//ФорматФайла 		= ThisObject["ConnectionToExternalBase" 		+ ИдентификаторБазы + "ФорматФайла"];
	//НомерПервойСтроки 	= ThisObject["НомерПервойСтрокиФайла" 		+ ИдентификаторБазы];
	SettingsFile 		= ThisObject["SettingsFile" 				+ ИдентификаторБазы];
	//НомерТаблицы		= ThisObject["ConnectionToExternalBase"		+ ИдентификаторБазы + "НомерТаблицыВФайле"];
	ИмяЭлементаСДаннымиФайла = ThisObject["ИмяЭлементаСДаннымиФайла" + ИдентификаторБазы];
	
	НомерСтолбцаСКлючом = ThisObject["ColumnNumberKeyFromFile" 	+ ИдентификаторБазы];
	ИмяСтолбцаСКлючом 	= ThisObject["ColumnNameKeyFromFile" 	+ ИдентификаторБазы];	
	If ЧислоСтолбцовВКлюче > 1 Then
		НомерСтолбцаСКлючом2 	= ThisObject["ColumnNumberKey2FromFile" + ИдентификаторБазы];
		ИмяСтолбцаСКлючом2 		= ThisObject["ColumnNameKey2FromFile" + ИдентификаторБазы];
	EndIf;	
	If ЧислоСтолбцовВКлюче > 2 Then
		НомерСтолбцаСКлючом3 	= ThisObject["ColumnNumberKey3FromFile" + ИдентификаторБазы];
		ИмяСтолбцаСКлючом3 		= ThisObject["ColumnNameKey3FromFile" + ИдентификаторБазы];
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(ThisObject["QueryText" + ИдентификаторБазы]);
	ДанныеJSON = ReadJSON(JSONReader);
	JSONReader.Close();
	
	ЭлементНайден = False;
	For каждого CurrentData In ДанныеJSON Do
		
		//Array с данными уже найден на предыдущей итерации
		If ЭлементНайден Then 
			Break;
		EndIf;
		
		If TrimAll(Upper(CurrentData.Key)) = TrimAll(Upper(ИмяЭлементаСДаннымиФайла)) And
			TypeOf(CurrentData.Value) = Type("Array") Then
			
			ЭлементНайден = True;
			
			For каждого ТекущееЗначениеJSON In CurrentData.Value Do
			
				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
										
				СтрокаПриемник = ТЗ.Add();
				
				Try				
					If Not ТекущееЗначениеJSON.Property(ИмяСтолбцаСКлючом) Then
						Raise "Attribute JSON с именем " + ИмяСтолбцаСКлючом + " не найден";
					EndIf;
				Except
					ТекстОшибки = "Attribute JSON с именем " + ИмяСтолбцаСКлючом + " не найден";
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					Return Undefined;
				EndTry; 
				
				Ключ1 = ТекущееЗначениеJSON[ИмяСтолбцаСКлючом];
				
				If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 1 Then
				
					Try				
						If Not ТекущееЗначениеJSON.Property(ИмяСтолбцаСКлючом2) Then
							Raise "Attribute JSON с именем " + ИмяСтолбцаСКлючом2 + " не найден";
						EndIf;
					Except
						ТекстОшибки = "Attribute JSON с именем " + ИмяСтолбцаСКлючом2 + " не найден";
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						Return Undefined;
					EndTry; 
					
					Ключ2 = ТекущееЗначениеJSON[ИмяСтолбцаСКлючом2];
							
					If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
												
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
				
					Try				
						If Not ТекущееЗначениеJSON.Property(ИмяСтолбцаСКлючом3) Then
							Raise "Attribute JSON с именем " + ИмяСтолбцаСКлючом3 + " не найден";
						EndIf;
					Except
						ТекстОшибки = "Attribute JSON с именем " + ИмяСтолбцаСКлючом3 + " не найден";
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						Return Undefined;
					EndTry; 
					
					Ключ3 = ТекущееЗначениеJSON[ИмяСтолбцаСКлючом3];
							
					If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
					
#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
					Except
						ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
						Message(ТекстОшибки);
					EndTry;
				EndIf;
				
				СтрокаПриемник.Key = КлючТек;
				
				If ЧислоСтолбцовВКлюче > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
						Except
							ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
							Message(ТекстОшибки);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
#EndRegion  

				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
				For Each СтрокаНастроекФайла In SettingsFile Do
					
					//Not задано имя колонки (например, если реквизит заполняется программно)
					If IsBlankString(СтрокаНастроекФайла.ColumnName) Then
						Continue;
					EndIf;
					
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					Try				
						If Not ТекущееЗначениеJSON.Property(СтрокаНастроекФайла.ColumnName) Then
							Raise "Attribute JSON с именем " + СтрокаНастроекФайла.ColumnName + " не найден";
						EndIf;
					Except
						ТекстОшибки = "Attribute JSON с именем " + СтрокаНастроекФайла.ColumnName + " не найден";
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						Return Undefined;
					EndTry; 
					
					СтрокаПриемник[ИмяРеквизита] = ТекущееЗначениеJSON[СтрокаНастроекФайла.ColumnName];
										
					//FillType переменных, которые будут использоваться в произвольном коде
					РВрем = СтрокаПриемник[ИмяРеквизита];
					If СтрокаНастроекФайла.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;

				EndDo;
		
		
#Region Произвольный_код_заполнения_реквизитов
		
				For Each СтрокаНастроекФайла In SettingsFile Do
					
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					РТек = СтрокаПриемник[ИмяРеквизита];

					Try
						Execute СтрокаНастроекФайла.ПроизвольныйКод;
					Except
						ТекстОшибки = ErrorDescription();
						Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ТекстОшибки);
					EndTry;
					
					If ThisObject["CollapseTable" + ИдентификаторБазы] Then
						Try
							Execute КодПриведенияРеквизитаКТипуЧисло;
						Except
							РТек = 0;
						EndTry;
					EndIf;
				
					СтрокаПриемник[ИмяРеквизита] = РТек;
				
				EndDo;
													
			EndDo;
		
		EndIf;
	
#EndRegion 

	EndDo;
	
	//Indexing
	If ТЗ <> Undefined Then
		
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + ИдентификаторБазы].Count() Do
			
			ИмяРеквизита = String(ИдентификаторБазы) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ThisObject["SettingsFile" + ИдентификаторБазы][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ПредставленияЗаголовковРеквизитов[ИмяРеквизита] = ?(IsBlankString(ЗаголовокРеквизитаИзНастроек), "Attribute " + ИдентификаторБазы + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ПолучитьДанныеИзТабличногоДокумента(ИдентификаторБазы, ТекстОшибок = "")
	
	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key");
	КолонкиСКлючомСтрокой = "Key";
	
	If ЧислоСтолбцовВКлюче > 1 Then
		ТЗ.Columns.Add("Ключ2");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ2";
	EndIf;
	
	If ЧислоСтолбцовВКлюче > 2 Then
		ТЗ.Columns.Add("Ключ3");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ3";
	EndIf;
	
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	НомерПервойСтроки 	= ThisObject["НомерПервойСтрокиФайла" + ИдентификаторБазы];
	SettingsFile 		= ThisObject["SettingsFile" + ИдентификаторБазы];
	
	НомерСтолбцаСКлючом = ThisObject["ColumnNumberKeyFromFile" + ИдентификаторБазы];
	If ЧислоСтолбцовВКлюче > 1 Then
		НомерСтолбцаСКлючом2 = ThisObject["ColumnNumberKey2FromFile" + ИдентификаторБазы];
	EndIf;
	If ЧислоСтолбцовВКлюче > 2 Then
		НомерСтолбцаСКлючом3 = ThisObject["ColumnNumberKey3FromFile" + ИдентификаторБазы];
	EndIf;
	
	НомерТекущейСтроки = НомерПервойСтроки;	
	ТекущееЧислоСтрокСПустымиКлючами = 0;
	While True Do
		
		Ключ1 = ThisObject["Table" + ИдентификаторБазы].Region(НомерТекущейСтроки,НомерСтолбцаСКлючом,НомерТекущейСтроки,НомерСтолбцаСКлючом).Text;
								
		If ThisObject["CastKeyToString" + ИдентификаторБазы] Then
			Ключ1 = TrimAll(String(Ключ1));
		EndIf;
		
		If ThisObject["CastKeyToUpperCase" + ИдентификаторБазы] Then
			Ключ1 = TrimAll(Upper(String(Ключ1)));
		EndIf;
		
		If ThisObject["DeleteFromKeyCurlyBrackets" + ИдентификаторБазы] Then
			Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
		EndIf;
						
		If ЧислоСтолбцовВКлюче > 1 Then
			
			Ключ2 = ThisObject["Table" + ИдентификаторБазы].Region(НомерТекущейСтроки,НомерСтолбцаСКлючом2,НомерТекущейСтроки,НомерСтолбцаСКлючом2).Text;
					
			If ThisObject["CastKey2ToString" + ИдентификаторБазы] Then
				Ключ2 = TrimAll(String(Ключ2));
			EndIf;
			
			If ThisObject["CastKey2ToUpperCase" + ИдентификаторБазы] Then
				Ключ2 = TrimAll(Upper(String(Ключ2)));
			EndIf;
			
			If ThisObject["DeleteFromKey2CurlyBrackets" + ИдентификаторБазы] Then
				Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
			EndIf;
						
		EndIf;
		
		If ЧислоСтолбцовВКлюче > 2 Then
			
			Ключ3 = ThisObject["Table" + ИдентификаторБазы].Region(НомерТекущейСтроки,НомерСтолбцаСКлючом3,НомерТекущейСтроки,НомерСтолбцаСКлючом3).Text;
					
			If ThisObject["CastKey3ToString" + ИдентификаторБазы] Then
				Ключ3 = TrimAll(String(Ключ3));
			EndIf;
			
			If ThisObject["CastKey3ToUpperCase" + ИдентификаторБазы] Then
				Ключ3 = TrimAll(Upper(String(Ключ3)));
			EndIf;
			
			If ThisObject["DeleteFromKey3CurlyBrackets" + ИдентификаторБазы] Then
				Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
			EndIf;
						
		EndIf;
						
		If Not ValueIsFilled(Ключ1) Then
			If ЧислоСтолбцовВКлюче > 1 Then
				If Not ValueIsFilled(Ключ2) Then
					If ЧислоСтолбцовВКлюче > 2 Then
						If Not ValueIsFilled(Ключ3) Then
							ТекущееЧислоСтрокСПустымиКлючами = ТекущееЧислоСтрокСПустымиКлючами + 1;
						EndIf;
					Else
						ТекущееЧислоСтрокСПустымиКлючами = ТекущееЧислоСтрокСПустымиКлючами + 1;
					EndIf;
				EndIf;
			Else
				ТекущееЧислоСтрокСПустымиКлючами = ТекущееЧислоСтрокСПустымиКлючами + 1;
			EndIf;
		Else
			ТекущееЧислоСтрокСПустымиКлючами = 0;
		EndIf;
		
		If ТекущееЧислоСтрокСПустымиКлючами = NumberOfRowsWithEmptyKeysToBreakReading Then
			Break;
		EndIf;
		
		ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
		
		СтрокаПриемник = ТЗ.Add();
		
#Region Произвольный_код_обработки_ключа
	
		КлючТек = Ключ1;
		If ThisObject["ExecuteArbitraryKeyCode1" + ИдентификаторБазы] Then
			Try
			    Execute ThisObject["ArbitraryKeyCode1" + ИдентификаторБазы];
			Except
				ТекстОшибки = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
				Message(ТекстОшибки);
			EndTry;
		EndIf;
		СтрокаПриемник.Key = КлючТек;
		
		If ЧислоСтолбцовВКлюче > 1 Then
			
			КлючТек = Ключ2;
			If ThisObject["ExecuteArbitraryKeyCode2" + ИдентификаторБазы] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode2" + ИдентификаторБазы];
				Except
					ТекстОшибки = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
					Message(ТекстОшибки);
				EndTry;
			EndIf;
			СтрокаПриемник.Ключ2 = КлючТек;
			
		EndIf;
		
		If ЧислоСтолбцовВКлюче > 2 Then
			
			КлючТек = Ключ3;
			If ThisObject["ExecuteArbitraryKeyCode3" + ИдентификаторБазы] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode3" + ИдентификаторБазы];
				Except
					ТекстОшибки = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + ИдентификаторБазы + ": " + ErrorDescription();
					Message(ТекстОшибки);
				EndTry;
			EndIf;
			СтрокаПриемник.Ключ3 = КлючТек;
			
		EndIf;
		
#EndRegion 
		
		For Each СтрокаНастроекФайла In SettingsFile Do
		
			ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
			СтрокаПриемник[ИмяРеквизита] = TrimAll(ThisObject["Table" + ИдентификаторБазы].Region(НомерТекущейСтроки,СтрокаНастроекФайла.НомерКолонки,НомерТекущейСтроки,СтрокаНастроекФайла.НомерКолонки).Text);
			
			//FillType переменных, которые будут использоваться в произвольном коде
			РВрем = СтрокаПриемник[ИмяРеквизита];
			If СтрокаНастроекФайла.LineNumber = 1 Then
				Р1 = РВрем;
			ElsIf СтрокаНастроекФайла.LineNumber = 2 Then
				Р2 = РВрем;
			ElsIf СтрокаНастроекФайла.LineNumber = 3 Then
				Р3 = РВрем;
			ElsIf СтрокаНастроекФайла.LineNumber = 4 Then
				Р4 = РВрем;
			ElsIf СтрокаНастроекФайла.LineNumber = 5 Then
				Р5 = РВрем;
			EndIf;	
			
		EndDo;
		
		For Each СтрокаНастроекФайла In SettingsFile Do
				
			ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
			РТек = СтрокаПриемник[ИмяРеквизита];

			Try
				Execute СтрокаНастроекФайла.ПроизвольныйКод;
			Except
				ТекстОшибки = ErrorDescription();
				Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ТекстОшибки);
			EndTry;
			
			If ThisObject["CollapseTable" + ИдентификаторБазы] Then
				Try
					Execute КодПриведенияРеквизитаКТипуЧисло;
				Except
					РТек = 0;
				EndTry;
			EndIf;
			
			СтрокаПриемник[ИмяРеквизита] = РТек;
							
		EndDo;
		
		НомерТекущейСтроки = НомерТекущейСтроки + 1;
		
	EndDo;
	
	//Indexing
	If ТЗ <> Undefined Then
		
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + ИдентификаторБазы].Count() Do
			
			ИмяРеквизита = String(ИдентификаторБазы) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ThisObject["SettingsFile" + ИдентификаторБазы][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ПредставленияЗаголовковРеквизитов[ИмяРеквизита] = ?(IsBlankString(ЗаголовокРеквизитаИзНастроек), "Attribute " + ИдентификаторБазы + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction
#EndRegion


#Region Вспомогательные_процедуры_и_функции
Function ПроверитьЗаполнениеРеквизитов(ИсточникДляПредварительногоПросмотра = "", ТекстОшибок = "") Export
	
	РеквизитыЗаполненыКорректно = True;
	
	If ЧислоСтолбцовВКлюче = 0 Then
		РеквизитыЗаполненыКорректно = False;
		ТекстОшибки = "Not заполнено число столбцов в ключе";
		UserMessage = New UserMessage;
		UserMessage.Text = ТекстОшибки;
		UserMessage.Field = "Object.ЧислоСтолбцовВКлюче";
		UserMessage.Message();
		ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
	EndIf;
		
	If NumberOfRowsWithEmptyKeysToBreakReading = 0 Then
		РеквизитыЗаполненыКорректно = False;
		ТекстОшибки = "Not заполнено число строк с пустыми ключами для прерывания чтения";
		UserMessage = New UserMessage;
		UserMessage.Text = ТекстОшибки;
		UserMessage.Field = "Object.NumberOfRowsWithEmptyKeysToBreakReading";
		UserMessage.Message();
		ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
	EndIf;
	
#Region _1С_8_1С_77_SQL

	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "А" Then
	
		If BaseTypeA >= 0 And BaseTypeA <= 2 Or BaseTypeA = 5 Then
			
			If IsBlankString(QueryTextA) Then
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнен текст запроса к базе А";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.QueryTextA";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "Б" Then
		
		If BaseTypeB >= 0 And BaseTypeB <= 2 Or BaseTypeB = 5 Then
		
			If IsBlankString(QueryTextB) Then
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнен текст запроса к базе Б";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.QueryTextB";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			EndIf;
			
		EndIf;
		
	EndIf;
	
#EndRegion 


#Region Файл_Табличный_документ

	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "А" Then
	
		If BaseTypeA = 3 Or BaseTypeA = 4 Then
				
			If BaseTypeA = 3 And IsBlankString(ConnectionToExternalBaseAFileFormat) Then
				
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнен формат файла А";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.ConnectionToExternalBaseAFileFormat";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
			ElsIf BaseTypeA = 3 And ConnectionToExternalBaseAFileFormat = "XML" Then
				
				If IsBlankString(ColumnNameKeyFromFileA) Then
				
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя столбца с ключом файла А";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNameKeyFromFileA";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
				EndIf; 
				
				If ЧислоСтолбцовВКлюче > 1 Then
				
					If ColumnNameKey2FromFileA = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнено имя столбца с ключом 2 файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNameKey2FromFileA";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndIf;
					
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
				
					If ColumnNameKey3FromFileA = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнено имя столбца с ключом 3 файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNameKey3FromFileA";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndIf;
					
				EndIf;
				
				If IsBlankString(DataStorageMethodInXMLFileA) Then
				
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен способ хранения данных в файле А";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.DataStorageMethodInXMLFileA";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
				EndIf;
			
			Else
				
				//For файлов xls и doc должен быть указан номер книги /таблицы
				If BaseTypeA = 3 And (ConnectionToExternalBaseAFileFormat = "XLS" Or ConnectionToExternalBaseAFileFormat = "DOC") Then
					
					If ConnectionToExternalDatabaseANumberTableInFile = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер " + ?(ConnectionToExternalBaseAFileFormat = "XLS", "книги", "таблицы") + " файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ConnectionToExternalDatabaseANumberTableInFile";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					EndIf;
					
				EndIf;
				
				If NumberFirstRowFileA = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен номер первой строки файла/таблицы А";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.NumberFirstRowFileA";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If ColumnNumberKeyFromFileA = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен номер столбца с ключом файла/таблицы А";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNumberKeyFromFileA";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 1 Then			
					If ColumnNumberKey2FromFileA = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер столбца с ключом 2 файла/таблицы А";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNumberKey2FromFileA";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;					
					EndIf;			
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then			
					If ColumnNumberKey3FromFileA = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер столбца с ключом 3 файла/таблицы А";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNumberKey3FromFileA";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;					
					EndIf;			
				EndIf; 
				
				For Each СтрокаТЧ In SettingsFileA Do
					If IsBlankString(СтрокаТЧ.ПроизвольныйКод) And СтрокаТЧ.НомерКолонки = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер колонки файла/таблицы А, соответствующий реквизиту А" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.SettingsFileA[" + (СтрокаТЧ.LineNumber - 1) + "].НомерКолонки";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					EndIf;
				EndDo;
				
			EndIf; 
			
		EndIf;
		
	EndIf; 
	
	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "Б" Then
		If BaseTypeB = 3 Or BaseTypeB = 4 Then
				
			If BaseTypeB = 3 And IsBlankString(ConnectionToExternalBaseBFileFormat) Then
				
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнен формат файла Б";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.ConnectionToExternalBaseBFileFormat";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
			ElsIf BaseTypeB = 3 And ConnectionToExternalBaseBFileFormat = "XML" Then

				If IsBlankString(ColumnNameKeyFromFileB) Then
				
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя столбца с ключом файла Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNameKeyFromFileB";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 1 Then			
					If ColumnNameKey2FromFileB = 0 Then					
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнено имя столбца с ключом 2 файла Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNameKey2FromFileB";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;					
					EndIf;				
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then			
					If ColumnNameKey3FromFileB = 0 Then					
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнено имя столбца с ключом 3 файла Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNameKey3FromFileB";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;					
					EndIf;				
				EndIf;
				
				If IsBlankString(DataStorageMethodInXMLFileB) Then
				
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен способ хранения данных в файле Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.DataStorageMethodInXMLFileB";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				
				EndIf;
				
			Else
				
				If BaseTypeB = 3 And (ConnectionToExternalBaseBFileFormat = "XLS" Or ConnectionToExternalBaseBFileFormat = "DOC") Then
					
					//For файлов xls и doc должен быть указан номер книги /таблицы
					If ConnectionToExternalDatabaseBNumberTableInFile = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер " + ?(ConnectionToExternalBaseBFileFormat = "XLS", "книги", "таблицы") + " файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ConnectionToExternalDatabaseBNumberTableInFile";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					EndIf;
				EndIf;
				
				If NumberFirstRowFileB = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен номер первой строки файла/таблицы Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.NumberFirstRowFileB";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If ColumnNumberKeyFromFileB = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен номер столбца с ключом файла/таблицы Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNumberKeyFromFileB";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 1 Then
				
					If ColumnNumberKey2FromFileB = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер столбца с ключом 2 файла/таблицы Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNumberKey2FromFileB";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndIf;
				
				EndIf;
				
				If ЧислоСтолбцовВКлюче > 2 Then
				
					If ColumnNumberKey3FromFileB = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер столбца с ключом 3 файла/таблицы Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ColumnNumberKey3FromFileB";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
						
					EndIf;
				
				EndIf;
				
				For Each СтрокаТЧ In SettingsFileB Do
					If IsBlankString(СтрокаТЧ.ПроизвольныйКод) And СтрокаТЧ.НомерКолонки = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнен номер колонки файла/таблицы Б, соответствующий реквизиту Б" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.SettingsFileB[" + (СтрокаТЧ.LineNumber - 1) + "].НомерКолонки";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
#EndRegion 


 #Region JSON
 
	 If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "А" Then
		 
	 	If BaseTypeA = 6 Then
		 
			If IsBlankString(QueryTextA) Then
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнена строка JSON";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.QueryTextA";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			EndIf;
						
			If IsBlankString(ColumnNameKeyFromFileA) Then
					
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнено имя столбца с ключом файла А";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.ColumnNameKeyFromFileA";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			
			EndIf; 
			
			If ЧислоСтолбцовВКлюче > 1 Then
			
				If ColumnNameKey2FromFileA = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя столбца с ключом 2 файла А";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNameKey2FromFileA";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndIf;
				
			EndIf;
			
			If ЧислоСтолбцовВКлюче > 2 Then
			
				If ColumnNameKey3FromFileA = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя столбца с ключом 3 файла А";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNameKey3FromFileA";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndIf;
				
			EndIf; 
			
		EndIf;
			
	EndIf;
	
	
	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "Б" Then
			
		If BaseTypeB = 6 Then
		 
			If IsBlankString(QueryTextB) Then
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнена строка JSON";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.QueryTextB";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			EndIf;
			
			If IsBlankString(ColumnNameKeyFromFileB) Then
					
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнено имя столбца с ключом файла Б";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.ColumnNameKeyFromFileB";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			
			EndIf; 
			
			If ЧислоСтолбцовВКлюче > 1 Then
			
				If ColumnNameKey2FromFileB = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя столбца с ключом 2 файла Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNameKey2FromFileB";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndIf;
				
			EndIf;
			
			If ЧислоСтолбцовВКлюче > 2 Then
			
				If ColumnNameKey3FromFileB = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя столбца с ключом 3 файла Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ColumnNameKey3FromFileB";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
 #EndRegion 

 	If IsBlankString(ИсточникДляПредварительногоПросмотра) Then
	 
		//If код формируется автоматически, поля таблиц условий д.б. заполнены правильно
		If Not CodeForOutputRowsEditedManually And Not RowOutputConditionsDisabled Then
			
			If ConditionsOutputRows.Count() > 1 And Not ValueIsFilled(BooleanOperatorForConditionsOutputRows) Then
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнен логический оператор для объединения условий вывода строк";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.BooleanOperatorForConditionsOutputRows";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			EndIf;
			
			For Each СтрокаТЧ In ConditionsOutputRows Do
				
				If Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute) Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя реквизита в строке условий вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.Condition) Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено условие в строке условий вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].Condition";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.ComparisonType) Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен тип сравнения в строке условий вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].ComparisonType";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If СтрокаТЧ.Condition <> "Заполнен" Then
				
					If СтрокаТЧ.ComparisonType = "Attribute" And Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute2) Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнено имя реквизита в строке условий вывода №" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute2";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;     
			
		If Not CodeForProhibitingOutputRowsEditedManually And Not ConditionsProhibitOutputRowsDisabled Then
			
			If ConditionsProhibitOutputRows.Count() > 1 And Not ValueIsFilled(BooleanOperatorForProhibitingConditionsOutputRows) Then
				РеквизитыЗаполненыКорректно = False;
				ТекстОшибки = "Not заполнен логический оператор для объединения условий запрета вывода строк";
				UserMessage = New UserMessage;
				UserMessage.Text = ТекстОшибки;
				UserMessage.Field = "Object.BooleanOperatorForProhibitingConditionsOutputRows";
				UserMessage.Message();
				ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
			EndIf;
			
			For Each СтрокаТЧ In ConditionsProhibitOutputRows Do
				
				If Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute) Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено имя реквизита в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.Condition) Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнено условие в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].Condition";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.ComparisonType) Then
					РеквизитыЗаполненыКорректно = False;
					ТекстОшибки = "Not заполнен тип сравнения в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ТекстОшибки;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].ComparisonType";
					UserMessage.Message();
					ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
				EndIf;
				
				If СтрокаТЧ.Condition <> "Заполнен" Then
					
					If СтрокаТЧ.ComparisonType = "Attribute" And Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute2) Then
						РеквизитыЗаполненыКорректно = False;
						ТекстОшибки = "Not заполнено имя реквизита в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ТекстОшибки;
						UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute2";
						UserMessage.Message();
						ТекстОшибок = ТекстОшибок + Chars.LF + ТекстОшибки;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;   
		
	EndIf;
	
	Return РеквизитыЗаполненыКорректно; 
	
EndFunction

Function СохранитьНастройкиВБазуНаСервере(НастройкаСсылка, СохранятьТабличныеДокументы) Export
	
	ОперацияЗавершенаУспешно = True;
	
	Try
		НастройкаОбъект = НастройкаСсылка.GetObject();
		Data = ПолучитьДанныеВВидеСтруктурыНаСервере(СохранятьТабличныеДокументы); 
		ХранилищеВнешнее = New ValueStorage(Data);
		НастройкаОбъект.Операция = ХранилищеВнешнее;
		НастройкаОбъект.Write();
		Message("Data успешно записаны в операцию """ + НастройкаОбъект.Title + """");
		СвязаннаяОперацияСравненияДанных = НастройкаСсылка;
		Title = НастройкаОбъект.Title;
	Except
		ТекстОшибки = "Error при записи данных в операцию """ + НастройкаСсылка.Title + """: " + ErrorDescription();
		Message(ТекстОшибки);
		ОперацияЗавершенаУспешно = False;
	EndTry;

	Return ОперацияЗавершенаУспешно;
	
EndFunction

Procedure ОткрытьНастройкиИзБазыНаСервере(НастройкаСсылка, ЗагружатьТабличныеДокументы = False) Export
	
	ОперацияЗавершенаУспешно = True;
	
	Try
		
		ХранилищеВнешнее = НастройкаСсылка.Операция;
		Data = ХранилищеВнешнее.Get();
		FillPropertyValues(ThisObject, Data);
		//For меньшей путаницы с наименованиями в заголовок попадает наименование элемента справочника,
		//на основании которого была заполнена обработка
		Title = НастройкаСсылка.Title;
		СвязаннаяОперацияСравненияДанных = НастройкаСсылка;
		
		//До версии 12.1.38 вместо реквизита PeriodType использовался флаг PeriodTypeAbsolute
		//Value True флага PeriodTypeAbsolute соответствует значение 0 реквизита PeriodType
		//If в настройке нет реквизита PeriodType, необходимо его заполнить на основании флага PeriodTypeAbsolute
		If Not Data.Property("PeriodType") Then
			If Data.Property("PeriodTypeAbsolute") Then
				PeriodType = ?(Data.PeriodTypeAbsolute, 0, 1);
			EndIf;
		EndIf;
				
		If Data.Property("ValueTableConditionsOutputRows") Then
			ConditionsOutputRows.Load(Data.ValueTableConditionsOutputRows);
		Else
			ConditionsOutputRows.Clear();
		EndIf;
		
		If Data.Property("ValueTableConditionsProhibitOutputRows") Then
			ConditionsProhibitOutputRows.Load(Data.ValueTableConditionsProhibitOutputRows);
		Else
			ConditionsProhibitOutputRows.Clear();
		EndIf;
		
		If Data.Property("ValueTableSettingsFileA") Then
			SettingsFileA.Load(Data.ValueTableSettingsFileA);
		Else
			SettingsFileA.Clear();
		EndIf;
		
		If Data.Property("ValueTableSettingsFileB") Then
			SettingsFileB.Load(Data.ValueTableSettingsFileB);
		Else
			SettingsFileB.Clear();
		EndIf;
		
		If Data.Property("ValueTableParameterListA") Then
			ParameterListA.Load(Data.ValueTableParameterListA);
		Else
			ParameterListA.Clear();
		EndIf;
		
		If Data.Property("ValueTableParameterListB") Then
			ParameterListB.Load(Data.ValueTableParameterListB);
		Else
			ParameterListB.Clear();
		EndIf;
		
		If Data.Property("ValueTableParameterListB") Then
			ParameterListB.Load(Data.ValueTableParameterListB);
		Else
			ParameterListB.Clear();
		EndIf;
		
		If ЗагружатьТабличныеДокументы Then
			If Data.BaseTypeA = 4 Then
				Try
					If Data.Property("TableAValueStorage") Then
						ТаблицаА = Data.TableAValueStorage.Get();
					EndIf;
				Except
				EndTry; 
			EndIf;
			
			If Data.BaseTypeB = 4 Then
				Try
					If Data.Property("TableBValueStorage") Then
						ТаблицаБ = Data.TableBValueStorage.Get();
					EndIf;
				Except
				EndTry; 
			EndIf;
		EndIf;
		
		//Реструктуризация параметров
		
		//Parameter CompositeKey заменен на NumberColumnsInKey
		If ЧислоСтолбцовВКлюче = 0 Then
			ЧислоСтолбцовВКлюче = ?(CompositeKey, 2, 1); 
		EndIf;
		
		If NumberOfRowsWithEmptyKeysToBreakReading = 0 Then
			NumberOfRowsWithEmptyKeysToBreakReading = 2;
		EndIf;
		
		Result.Clear();

	Except
		ТекстОшибки = ErrorDescription();
		Message(ТекстОшибки);
	EndTry;

EndProcedure

Function ПолучитьДанныеВВидеСтруктурыНаСервере(СохранятьТабличныеДокументы = False) Export
	
	ДанныеСтруктура = New Structure;
	ДанныеСтруктура.Insert("QueryTextA", 											QueryTextA);
	ДанныеСтруктура.Insert("QueryTextB", 											QueryTextB);
	ДанныеСтруктура.Insert("BaseTypeA", 												BaseTypeA);
	ДанныеСтруктура.Insert("BaseTypeB", 												BaseTypeB);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseAPathBase", 						ConnectionToExternalBaseAPathBase);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseBPathBase",  						ConnectionToExternalBaseBPathBase);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseALogin",  							ConnectionToExternalBaseALogin);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseBLogin",  							ConnectionToExternalBaseBLogin);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseAPassword", 							ConnectionToExternalBaseAPassword);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseBPassword",  						ConnectionToExternalBaseBPassword);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseAServer",  						ConnectionToExternalBaseAServer);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseBServer",  						ConnectionToExternalBaseBServer);
	ДанныеСтруктура.Insert("WorkOptionExternalBaseA",  								WorkOptionExternalBaseA);
	ДанныеСтруктура.Insert("WorkOptionExternalBaseB",   							WorkOptionExternalBaseB);
	ДанныеСтруктура.Insert("VersionPlatformExternalBaseA",   							VersionPlatformExternalBaseA);
	ДанныеСтруктура.Insert("VersionPlatformExternalBaseB",   							VersionPlatformExternalBaseB);
	ДанныеСтруктура.Insert("ConnectingToExternalBaseADriverSQL",						ConnectingToExternalBaseADriverSQL);
	ДанныеСтруктура.Insert("ConnectingToExternalBaseBDriverSQL",						ConnectingToExternalBaseBDriverSQL);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseAFileFormat",						ConnectionToExternalBaseAFileFormat);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseBFileFormat",						ConnectionToExternalBaseBFileFormat);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseAPathToFile",						ConnectionToExternalBaseAPathToFile);
	ДанныеСтруктура.Insert("ConnectionToExternalBaseBPathToFile",						ConnectionToExternalBaseBPathToFile);
	ДанныеСтруктура.Insert("ConnectingToExternalBaseADeviceStorageFile",			ConnectingToExternalBaseADeviceStorageFile);
	ДанныеСтруктура.Insert("ConnectingToExternalBaseBDeviceStorageFile",			ConnectingToExternalBaseBDeviceStorageFile);
	ДанныеСтруктура.Insert("ConnectionToExternalDatabaseANumberTableInFile",				ConnectionToExternalDatabaseANumberTableInFile);
	ДанныеСтруктура.Insert("ConnectionToExternalDatabaseBNumberTableInFile",				ConnectionToExternalDatabaseBNumberTableInFile);
	
	ДанныеСтруктура.Insert("CodeForOutputRows", 										CodeForOutputRows);
	ДанныеСтруктура.Insert("CodeForProhibitingOutputRows", 								CodeForProhibitingOutputRows);
	ДанныеСтруктура.Insert("BooleanOperatorForConditionsOutputRows", 				BooleanOperatorForConditionsOutputRows);
	ДанныеСтруктура.Insert("BooleanOperatorForProhibitingConditionsOutputRows", 			BooleanOperatorForProhibitingConditionsOutputRows);
	ДанныеСтруктура.Insert("CodeForOutputRowsEditedManually", 					CodeForOutputRowsEditedManually);
	ДанныеСтруктура.Insert("CodeForProhibitingOutputRowsEditedManually", 			CodeForProhibitingOutputRowsEditedManually);
	ДанныеСтруктура.Insert("RowOutputConditionsDisabled", 							RowOutputConditionsDisabled);
	ДанныеСтруктура.Insert("ConditionsProhibitOutputRowsDisabled", 						ConditionsProhibitOutputRowsDisabled);
	
	ДанныеСтруктура.Insert("RelationalOperation",   									RelationalOperation);
	ДанныеСтруктура.Insert("VisibilityAttributeA1",										VisibilityAttributeA1);
	ДанныеСтруктура.Insert("VisibilityAttributeA2",										VisibilityAttributeA2);
	ДанныеСтруктура.Insert("VisibilityAttributeA3",										VisibilityAttributeA3);
	ДанныеСтруктура.Insert("VisibilityAttributeA4",										VisibilityAttributeA4);
	ДанныеСтруктура.Insert("VisibilityAttributeA5",										VisibilityAttributeA5);
	ДанныеСтруктура.Insert("VisibilityAttributeB1",										VisibilityAttributeB1);
	ДанныеСтруктура.Insert("VisibilityAttributeB2",										VisibilityAttributeB2);
	ДанныеСтруктура.Insert("VisibilityAttributeB3",										VisibilityAttributeB3);
	ДанныеСтруктура.Insert("VisibilityAttributeB4",										VisibilityAttributeB4);
	ДанныеСтруктура.Insert("VisibilityAttributeB5",										VisibilityAttributeB5);
	
	ДанныеСтруктура.Insert("PeriodTypeAbsolute",									PeriodTypeAbsolute);
	ДанныеСтруктура.Insert("PeriodType",												PeriodType);
	ДанныеСтруктура.Insert("AbsolutePeriodValue",								AbsolutePeriodValue);
	ДанныеСтруктура.Insert("RelativePeriodValue",							RelativePeriodValue);
	ДанныеСтруктура.Insert("ValueOfSlaveRelativePeriod",				ValueOfSlaveRelativePeriod);
	ДанныеСтруктура.Insert("DiscretenessOfRelativePeriod",						DiscretenessOfRelativePeriod);
	ДанныеСтруктура.Insert("DiscretenessOfSlaveRelativePeriod",			DiscretenessOfSlaveRelativePeriod);
	ДанныеСтруктура.Insert("CompositeKey",											CompositeKey);
	ДанныеСтруктура.Insert("ЧислоСтолбцовВКлюче",										ЧислоСтолбцовВКлюче);
	ДанныеСтруктура.Insert("NumberOfRowsWithEmptyKeysToBreakReading",			NumberOfRowsWithEmptyKeysToBreakReading);
	ДанныеСтруктура.Insert("ОтображатьТипыСтолбцовКлюча",								ОтображатьТипыСтолбцовКлюча);
	ДанныеСтруктура.Insert("PathToDownloadFile",										PathToDownloadFile);
	ДанныеСтруктура.Insert("UploadFileFormat",										UploadFileFormat);
			
	ДанныеСтруктура.Insert("NumberFirstRowFileA",									NumberFirstRowFileA);
	ДанныеСтруктура.Insert("NumberFirstRowFileB",									NumberFirstRowFileB);
	ДанныеСтруктура.Insert("ColumnNumberKeyFromFileA",								ColumnNumberKeyFromFileA);	
	ДанныеСтруктура.Insert("ColumnNumberKey2FromFileA",							ColumnNumberKey2FromFileA);
	ДанныеСтруктура.Insert("ColumnNumberKey3FromFileA",							ColumnNumberKey3FromFileA);
	ДанныеСтруктура.Insert("ColumnNumberKeyFromFileB",								ColumnNumberKeyFromFileB);
	ДанныеСтруктура.Insert("ColumnNumberKey2FromFileB",							ColumnNumberKey2FromFileB);
	ДанныеСтруктура.Insert("ColumnNumberKey3FromFileB",							ColumnNumberKey3FromFileB);
	ДанныеСтруктура.Insert("ColumnNameKeyFromFileA",								ColumnNameKeyFromFileA);	
	ДанныеСтруктура.Insert("ColumnNameKey2FromFileA",								ColumnNameKey2FromFileA);	
	ДанныеСтруктура.Insert("ColumnNameKey3FromFileA",								ColumnNameKey3FromFileA);	
	ДанныеСтруктура.Insert("ColumnNameKeyFromFileB",								ColumnNameKeyFromFileB);	
	ДанныеСтруктура.Insert("ColumnNameKey2FromFileB",								ColumnNameKey2FromFileB);
	ДанныеСтруктура.Insert("ColumnNameKey3FromFileB",								ColumnNameKey3FromFileB);
	ДанныеСтруктура.Insert("ElementNameWithDataFileA",								ElementNameWithDataFileA);	
	ДанныеСтруктура.Insert("ElementNameWithDataFileB",								ElementNameWithDataFileB);
	ДанныеСтруктура.Insert("ParentNodeNameFileA",								ParentNodeNameFileA);
	ДанныеСтруктура.Insert("ParentNodeNameFileB",								ParentNodeNameFileB);
	ДанныеСтруктура.Insert("DataStorageMethodInXMLFileA",							DataStorageMethodInXMLFileA);
	ДанныеСтруктура.Insert("DataStorageMethodInXMLFileB",							DataStorageMethodInXMLFileB);
	ДанныеСтруктура.Insert("CastKeyToStringA",									CastKeyToStringA);
	ДанныеСтруктура.Insert("CastKey2ToStringA",									CastKey2ToStringA);
	ДанныеСтруктура.Insert("CastKey3ToStringA",									CastKey3ToStringA);
	ДанныеСтруктура.Insert("CastKeyToStringB",									CastKeyToStringB);
	ДанныеСтруктура.Insert("CastKey2ToStringB",									CastKey2ToStringB);
	ДанныеСтруктура.Insert("CastKey3ToStringB",									CastKey3ToStringB);
	ДанныеСтруктура.Insert("KeyLengthWhenCastingToStringA",							KeyLengthWhenCastingToStringA);
	ДанныеСтруктура.Insert("KeyLength2WhenCastingToStringA",						KeyLength2WhenCastingToStringA);
	ДанныеСтруктура.Insert("KeyLength3WhenCastingToStringA",						KeyLength3WhenCastingToStringA);
	ДанныеСтруктура.Insert("KeyLengthWhenCastingToStringB",							KeyLengthWhenCastingToStringB);
	ДанныеСтруктура.Insert("KeyLength2WhenCastingToStringB",						KeyLength2WhenCastingToStringB);
	ДанныеСтруктура.Insert("KeyLength3WhenCastingToStringB",						KeyLength3WhenCastingToStringB);
	ДанныеСтруктура.Insert("UseAsKeyUniqueIdentifierA", 		UseAsKeyUniqueIdentifierA);
	ДанныеСтруктура.Insert("UseAsKey2UniqueIdentifierA", 	UseAsKey2UniqueIdentifierA);
	ДанныеСтруктура.Insert("UseAsKey3UniqueIdentifierA", 	UseAsKey3UniqueIdentifierA);
	ДанныеСтруктура.Insert("UseAsKeyUniqueIdentifierB", 		UseAsKeyUniqueIdentifierB);
	ДанныеСтруктура.Insert("UseAsKey2UniqueIdentifierB", 	UseAsKey2UniqueIdentifierB);
	ДанныеСтруктура.Insert("UseAsKey3UniqueIdentifierB", 	UseAsKey3UniqueIdentifierB);
	ДанныеСтруктура.Insert("CastKeyToUpperCaseA", 						CastKeyToUpperCaseA);
	ДанныеСтруктура.Insert("CastKey2ToUpperCaseА", 						CastKey2ToUpperCaseA);
	ДанныеСтруктура.Insert("CastKey3ToUpperCaseА", 						CastKey3ToUpperCaseA);
	ДанныеСтруктура.Insert("CastKeyToUpperCaseБ", 						CastKeyToUpperCaseB);
	ДанныеСтруктура.Insert("CastKey2ToUpperCaseБ", 						CastKey2ToUpperCaseB);
	ДанныеСтруктура.Insert("CastKey3ToUpperCaseБ", 						CastKey3ToUpperCaseB);
	ДанныеСтруктура.Insert("DeleteFromKeyCurlyBracketsA", 							DeleteFromKeyCurlyBracketsA);
	ДанныеСтруктура.Insert("DeleteFromKey2CurlyBracketsA", 							DeleteFromKey2CurlyBracketsA);
	ДанныеСтруктура.Insert("DeleteFromKey3CurlyBracketsA", 							DeleteFromKey3CurlyBracketsA);
	ДанныеСтруктура.Insert("DeleteFromKeyCurlyBracketsB", 							DeleteFromKeyCurlyBracketsB);
	ДанныеСтруктура.Insert("DeleteFromKey2CurlyBracketsB", 							DeleteFromKey2CurlyBracketsB);
	ДанныеСтруктура.Insert("DeleteFromKey3CurlyBracketsB", 							DeleteFromKey3CurlyBracketsB);
	ДанныеСтруктура.Insert("ArbitraryKeyCode1A",		 							ArbitraryKeyCode1A);
	ДанныеСтруктура.Insert("ArbitraryKeyCode2A",		 							ArbitraryKeyCode2A);
	ДанныеСтруктура.Insert("ArbitraryKeyCode3A",		 							ArbitraryKeyCode3A);
	ДанныеСтруктура.Insert("ArbitraryKeyCode1B",		 							ArbitraryKeyCode1B);
	ДанныеСтруктура.Insert("ArbitraryKeyCode2B",		 							ArbitraryKeyCode2B);
	ДанныеСтруктура.Insert("ArbitraryKeyCode3B",		 							ArbitraryKeyCode3B);
	ДанныеСтруктура.Insert("ExecuteArbitraryKeyCode1A",		 					ExecuteArbitraryKeyCode1A);
	ДанныеСтруктура.Insert("ExecuteArbitraryKeyCode2A",		 					ExecuteArbitraryKeyCode2A);
	ДанныеСтруктура.Insert("ExecuteArbitraryKeyCode3A",		 					ExecuteArbitraryKeyCode3A);
	ДанныеСтруктура.Insert("ExecuteArbitraryKeyCode1B",		 					ExecuteArbitraryKeyCode1B);
	ДанныеСтруктура.Insert("ExecuteArbitraryKeyCode2B",		 					ExecuteArbitraryKeyCode2B);
	ДанныеСтруктура.Insert("ExecuteArbitraryKeyCode3B",		 					ExecuteArbitraryKeyCode3B);
	ДанныеСтруктура.Insert("CollapseTableA",		 								CollapseTableA);
	ДанныеСтруктура.Insert("CollapseTableB",		 								CollapseTableB);

	ДанныеСтруктура.Insert("ValueTableConditionsOutputRows", 									ConditionsOutputRows.Unload());
	ДанныеСтруктура.Insert("ValueTableConditionsProhibitOutputRows", 							ConditionsProhibitOutputRows.Unload());
	ДанныеСтруктура.Insert("ValueTableSettingsFileA", 										SettingsFileA.Unload());
	ДанныеСтруктура.Insert("ValueTableSettingsFileB", 										SettingsFileB.Unload());
	ДанныеСтруктура.Insert("ValueTableParameterListA", 									ParameterListA.Unload());
	ДанныеСтруктура.Insert("ValueTableParameterListB", 									ParameterListB.Unload());	
	
	If СохранятьТабличныеДокументы Then
		
		If BaseTypeA = 4 Then
			TableAValueStorage = New ValueStorage(ТаблицаА);
			
			If ДанныеСтруктура.Property("TableAValueStorage") Then
				ДанныеСтруктура.TableAValueStorage = TableAValueStorage;
			Else
				ДанныеСтруктура.Insert("TableAValueStorage", TableAValueStorage);
			EndIf;
		EndIf;
		
		If BaseTypeB = 4 Then
			TableBValueStorage = New ValueStorage(ТаблицаБ);
			
			If ДанныеСтруктура.Property("TableBValueStorage") Then
				ДанныеСтруктура.TableBValueStorage = TableBValueStorage;
			Else
				ДанныеСтруктура.Insert("TableBValueStorage", TableBValueStorage);
			EndIf;
		EndIf;
		
	EndIf;
	
	Return ДанныеСтруктура;
	
EndFunction

Procedure УстановитьПараметры(Query, ИдентификаторБазы)
	For Each Parameter In ThisObject["ParameterList" + ИдентификаторБазы] Do
		If TypeOf(Parameter.ParameterValue) <> Type("Undefined") Then
			If Parameter.ParameterName = "ValidFrom" Or Parameter.ParameterName = "ValidTo" Then
				Continue;
			EndIf;
			Query.SetParameter(Parameter.ParameterName, Parameter.ParameterValue);			
		EndIf;
	EndDo;       	
EndProcedure

Procedure ЗаполнитьПеременныеРЗначениямиПоУмолчанию()
	
	Р1 = Undefined;
	Р2 = Undefined;
	Р3 = Undefined;
	Р4 = Undefined;
	Р5 = Undefined;
	
EndProcedure

Function ВыгрузитьРезультатВФайлНаСервере(ДляКлиента = False) Export
	
	UploadFileFormat = Upper(UploadFileFormat);
	
	If IsBlankString(UploadFileFormat) Then
		ТекстОшибки = "Not указан формат файла выгрузки";
		UserMessage = New UserMessage;
		UserMessage.Text = ТекстОшибки;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Message();
		Return Undefined;
	EndIf;
	
	If ДляКлиента Then
		ПутьКВременномуФайлу = GetTempFileName(UploadFileFormat);
	Else
		If IsBlankString(PathToDownloadFile) Then
			ТекстОшибки = "Not заполнен путь к файлу выгрузки (на сервере)";
			UserMessage = New UserMessage;
			UserMessage.Text = ТекстОшибки;
			UserMessage.Field = "Object.PathToDownloadFile";
			UserMessage.Message();
			Return Undefined;
		EndIf;
		
		ПутьКВременномуФайлу = PathToDownloadFile;
	EndIf;
	
	If Result.Count() = 0 Then
		ТекстОшибки = "None данных для выгрузки";
		UserMessage = New UserMessage;
		UserMessage.Text = ТекстОшибки;
		UserMessage.Field = "Object.Result";
		UserMessage.Message();
		Return Undefined;
	EndIf;
		
	Try	
		DeleteFiles(ПутьКВременномуФайлу);	
	Except EndTry;
	
	Message(Format(CurrentDate(), "ДЛФ=DT") + " Выгрузка в файл """ + ПутьКВременномуФайлу + """ формата """ + UploadFileFormat + """ начата");
	
	If UploadFileFormat = "CSV" Then
		
		РазделительКолонок = ";";
		TextWriter = New TextWriter(ПутьКВременномуФайлу, TextEncoding.UTF8);
		TextWriter.Write(
			"№ строки;Столбец ключа 1;"
				+ ?(ЧислоСтолбцовВКлюче > 1, "Столбец ключа 2;", "")
				+ ?(ЧислоСтолбцовВКлюче > 2, "Столбец ключа 3;", "")
				+ "Number записей А;Number записей Б;А1;А2;А3;А4;А5;Б1;Б2;Б3;Б4;Б5"
			);
			
		СчетчикСтрок = 0;
		For Each СтрокаТЧ In Result Do
			
			СчетчикСтрок = СчетчикСтрок + 1;
			
			TextWriter.Write(
				Chars.LF
					+ СтрокаТЧ.LineNumber + РазделительКолонок
					+ СтрокаТЧ.Key + РазделительКолонок
					+ ?(ЧислоСтолбцовВКлюче > 1, "" + СтрокаТЧ.Ключ2 + РазделительКолонок, "")
					+ ?(ЧислоСтолбцовВКлюче > 2, "" + СтрокаТЧ.Key3 + РазделительКолонок, "")
					+ СтрокаТЧ.NumberOfRecordsA + РазделительКолонок
					+ СтрокаТЧ.NumberOfRecordsB + РазделительКолонок
					+ СтрокаТЧ.AttributeA1 + РазделительКолонок
					+ СтрокаТЧ.AttributeA2 + РазделительКолонок
					+ СтрокаТЧ.AttributeA3 + РазделительКолонок
					+ СтрокаТЧ.AttributeA4 + РазделительКолонок
					+ СтрокаТЧ.AttributeA5 + РазделительКолонок
					+ СтрокаТЧ.AttributeB1 + РазделительКолонок
					+ СтрокаТЧ.AttributeB2 + РазделительКолонок
					+ СтрокаТЧ.AttributeB3 + РазделительКолонок
					+ СтрокаТЧ.AttributeB4 + РазделительКолонок
					+ СтрокаТЧ.AttributeB5
			);
		
		EndDo; 
		
		TextWriter.Close();
		
	ElsIf UploadFileFormat = "XLS" Or
		UploadFileFormat = "DOCX" Or
		UploadFileFormat = "HTML" Or
		UploadFileFormat = "MXL" Or
		UploadFileFormat = "ODS" Or
		UploadFileFormat = "PDF" Or
		UploadFileFormat = "TXT" Or
		UploadFileFormat = "XLSX" Then
		
		НомерКолонкиЧислоЗаписейА = ?(ЧислоСтолбцовВКлюче > 1, ?(ЧислоСтолбцовВКлюче > 2, 5, 4), 3);
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
		SpreadsheetDocument.FitToPage = True;
		
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, 1, "№ строки",,7);
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, 2, "Key 1");
		If ЧислоСтолбцовВКлюче > 1 Then
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, 3, "Key 2");
		EndIf;
		If ЧислоСтолбцовВКлюче > 2 Then
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, 4, "Key 3");
		EndIf;
		
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА,  		"Rows А",, 7);
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 1,  	"Rows Б",, 7);
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 2,  	"А1");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 3,  	"А2");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 4,  	"А3");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 5,  	"А4");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 6,  	"А5");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 7,  	"Б1");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 8,  	"Б2");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 9,  	"Б3");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 10, 	"Б4");
		УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, 1, НомерКолонкиЧислоЗаписейА + 11, 	"Б5");
		
		РазмерыКолонок = New Structure;
		РазмерыКолонок.Insert("К1", 0);
		РазмерыКолонок.Insert("К2", 0);
		РазмерыКолонок.Insert("К3", 0);
		РазмерыКолонок.Insert("А1", 0);
		РазмерыКолонок.Insert("А2", 0);
		РазмерыКолонок.Insert("А3", 0);
		РазмерыКолонок.Insert("А4", 0);
		РазмерыКолонок.Insert("А5", 0);
		РазмерыКолонок.Insert("Б1", 0);
		РазмерыКолонок.Insert("Б2", 0);
		РазмерыКолонок.Insert("Б3", 0);
		РазмерыКолонок.Insert("Б4", 0);
		РазмерыКолонок.Insert("Б5", 0);
		СчетчикСтрок = 0;
		For Each СтрокаТЧ In Result Do
			
			МаксДлинаК1 = Max(РазмерыКолонок.К1,StrLen(СтрокаТЧ.Key));
			РазмерыКолонок.К1 = МаксДлинаК1;
			If ЧислоСтолбцовВКлюче > 1 Then
				МаксДлинаК2 = Max(РазмерыКолонок.К2,StrLen(СтрокаТЧ.Ключ2));
				РазмерыКолонок.К2 = МаксДлинаК2;
			EndIf;
			If ЧислоСтолбцовВКлюче > 2 Then
				МаксДлинаК3 = Max(РазмерыКолонок.К3,StrLen(СтрокаТЧ.Key3));
				РазмерыКолонок.К3 = МаксДлинаК3;
			EndIf;
			
			МаксДлинаА1 = Max(РазмерыКолонок.А1,StrLen(СтрокаТЧ.AttributeA1));
			РазмерыКолонок.А1 = МаксДлинаА1;
			МаксДлинаА2 = Max(РазмерыКолонок.А2,StrLen(СтрокаТЧ.AttributeA2));
			РазмерыКолонок.А2 = МаксДлинаА2;
			МаксДлинаА3 = Max(РазмерыКолонок.А3,StrLen(СтрокаТЧ.AttributeA3));
			РазмерыКолонок.А3 = МаксДлинаА3;
			МаксДлинаА4 = Max(РазмерыКолонок.А4,StrLen(СтрокаТЧ.AttributeA4));
			РазмерыКолонок.А4 = МаксДлинаА4;
			МаксДлинаА5 = Max(РазмерыКолонок.А5,StrLen(СтрокаТЧ.AttributeA5));
			РазмерыКолонок.А5 = МаксДлинаА5;
			МаксДлинаБ1 = Max(РазмерыКолонок.Б1,StrLen(СтрокаТЧ.AttributeB1));
			РазмерыКолонок.Б1 = МаксДлинаБ1;
			МаксДлинаБ2 = Max(РазмерыКолонок.Б2,StrLen(СтрокаТЧ.AttributeB2));
			РазмерыКолонок.Б2 = МаксДлинаБ2;
			МаксДлинаБ3 = Max(РазмерыКолонок.Б3,StrLen(СтрокаТЧ.AttributeB3));
			РазмерыКолонок.Б3 = МаксДлинаБ3;
			МаксДлинаБ4 = Max(РазмерыКолонок.Б4,StrLen(СтрокаТЧ.AttributeB4));
			РазмерыКолонок.Б4 = МаксДлинаБ4;
			МаксДлинаБ5 = Max(РазмерыКолонок.Б5,StrLen(СтрокаТЧ.AttributeB5));
			РазмерыКолонок.Б5 = МаксДлинаБ5;
			
			СчетчикСтрок = СчетчикСтрок + 1;
			
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, 1, СтрокаТЧ.LineNumber, 1, 7);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, 2, СтрокаТЧ.Key,, МаксДлинаК1);
			If ЧислоСтолбцовВКлюче > 1 Then
				УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, 3, СтрокаТЧ.Ключ2,, МаксДлинаК2);
			EndIf;
			If ЧислоСтолбцовВКлюче > 2 Then
				УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, 4, СтрокаТЧ.Key3,, МаксДлинаК3);
			EndIf;
				
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА,		СтрокаТЧ.ЧислоЗаписейА, 1, 7);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 1, СтрокаТЧ.ЧислоЗаписейБ, 1, 7);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 2, СтрокаТЧ.AttributeA1,, МаксДлинаА1);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 3,	СтрокаТЧ.AttributeA2,, МаксДлинаА2);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 4,	СтрокаТЧ.AttributeA3,, МаксДлинаА3);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 5, СтрокаТЧ.AttributeA4,, МаксДлинаА4);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 6, СтрокаТЧ.AttributeA5,, МаксДлинаА5);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 7, СтрокаТЧ.AttributeB1,, МаксДлинаБ1);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 8, СтрокаТЧ.AttributeB2,, МаксДлинаБ2);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 9, СтрокаТЧ.AttributeB3,, МаксДлинаБ3);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 10,СтрокаТЧ.AttributeB4,, МаксДлинаБ4);
			УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 11,СтрокаТЧ.AttributeB5,, МаксДлинаБ5);
		
		EndDo; 
		
		SpreadsheetDocument.Write(ПутьКВременномуФайлу, SpreadsheetDocumentFileType[UploadFileFormat]);
		
	Else
		
		ТекстОшибки = "Format файла выгрузки """ + UploadFileFormat + """ не предусмотрен";
		UserMessage = New UserMessage;
		UserMessage.Text = ТекстОшибки;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Message();
		Return Undefined;
		
	EndIf;
	
	If ДляКлиента Then
		
		ДанныеФайла = New BinaryData(ПутьКВременномуФайлу);
		АдресФайла = PutToTempStorage(ДанныеФайла);
		
		Try
			DeleteFiles(ПутьКВременномуФайлу);
		Except EndTry;
		
		Return АдресФайла;
		
	Else
		
		Message(Format(CurrentDate(), "ДЛФ=DT") + " Выгрузка в файл """ + ПутьКВременномуФайлу + """ формата """ + UploadFileFormat + """ завершена (число строк: " + СчетчикСтрок + ")");
		Return Undefined;
		
	EndIf;
	
EndFunction

Procedure УстановитьЗначениеЯчейкиТабличногоДокумента(SpreadsheetDocument, LineNumber, НомерКолонки, ЗначениеЯчейки, пТипЗначения = 0, ColumnWidth = 6)
	
	If пТипЗначения = 0 Then
		ValueType = New TypeDescription("String");
	ElsIf пТипЗначения = 1 Then
		ValueType = New TypeDescription("Number");
	EndIf;
	
	If False Then
		SpreadsheetDocument = New SpreadsheetDocument;
	EndIf;
	
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).ContainsValue = 	True;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).ValueType = 		ValueType;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).Value = 			ЗначениеЯчейки;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).ColumnWidth = 	ColumnWidth;
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).TopBorder = Line;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).BottomBorder = Line;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).LeftBorder = Line;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).RightBorder = Line;
	SpreadsheetDocument.Region(LineNumber,НомерКолонки).HorizontalAlign = HorizontalAlign.Left;
	
EndProcedure

Procedure ОбновитьДанныеПериода() Export
	
	CurrentDate = BegOfDay(CurrentDate());
	ТочкаОтсчетаДатыНачала = BegOfDay(CurrentDate) + 24 * 3600;
	
	//Умолчания
	ValidFrom = CurrentDate;
	ValidTo = EndOfDay(CurrentDate);
	
	//Absolute период
	If PeriodType = 0 Then
		
	Else
		
		If DiscretenessOfRelativePeriod = "год" Then
			ValidFrom = AddMonth(ТочкаОтсчетаДатыНачала, -1 * 12 * RelativePeriodValue);
		ElsIf DiscretenessOfRelativePeriod = "месяц" Then
			ValidFrom = AddMonth(ТочкаОтсчетаДатыНачала, -1 * RelativePeriodValue);
		ElsIf DiscretenessOfRelativePeriod = "день" Then
			ValidFrom = ТочкаОтсчетаДатыНачала - 24 * 3600 * RelativePeriodValue;
		EndIf;
		
		//Last Х
		If PeriodType = 1 Then

			ValidTo = EndOfDay(CurrentDate);
			
		//First X из последних Y
		ElsIf PeriodType = 2 Then
			
			ТочкаОтсчетаДатыОкончания = ValidFrom - 1;
			
			If DiscretenessOfSlaveRelativePeriod = "год" Then
				ValidTo = AddMonth(ТочкаОтсчетаДатыОкончания, 1 * 12 * ValueOfSlaveRelativePeriod);
			ElsIf DiscretenessOfSlaveRelativePeriod = "месяц" Then
				ValidTo = AddMonth(ТочкаОтсчетаДатыОкончания, 1 * ValueOfSlaveRelativePeriod);
			ElsIf DiscretenessOfSlaveRelativePeriod = "день" Then
				ValidTo = ТочкаОтсчетаДатыОкончания + 24 * 3600 * ValueOfSlaveRelativePeriod;
			EndIf;
			
		Else
			
			ValidTo = EndOfDay(CurrentDate);
		
		EndIf;
		
		AbsolutePeriodValue.ValidFrom = Min(ValidFrom,ValidTo);
		AbsolutePeriodValue.ValidTo = ValidTo;
		
	EndIf;
		
EndProcedure

Function НайтиПодчиненныйУзелXMLФайлаПоИмени(CurrentNode, ИмяИскомогоУзла)
	
	//Ветка для корневого элемента
	If CurrentNode.NodeName = ИмяИскомогоУзла Then
					
		Return CurrentNode;
		
	EndIf;
	
	For Each ПодчиненныйУзел In CurrentNode.ChildNodes Do
					
		If ПодчиненныйУзел.NodeName = ИмяИскомогоУзла Then
					
			НайденныйУзел = ПодчиненныйУзел;
			
		Else 
		
			НайденныйУзел = НайтиПодчиненныйУзелXMLФайлаПоИмени(ПодчиненныйУзел, ИмяИскомогоУзла); 
			
		EndIf;
		
		If НайденныйУзел <> Undefined Then
			
			Return НайденныйУзел
			
		EndIf;
		
	EndDo;

	Return Undefined;
	
EndFunction
#EndRegion

ЧислоРеквизитов = 5;
КодПриведенияРеквизитаКТипуЧисло = "РТек = Number(РТек);";
ПредставленияЗаголовковРеквизитов = New Map;

For AttributesCounter = 1 To ЧислоРеквизитов Do

	ПредставленияЗаголовковРеквизитов.Insert("А" + AttributesCounter , "Attribute А" + AttributesCounter);
	ПредставленияЗаголовковРеквизитов.Insert("Б" + AttributesCounter , "Attribute Б" + AttributesCounter);

EndDo; 