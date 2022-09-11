Var NumberOfRequisites Export;
Var ViewsHeadersAttributes Export; //type - Map
Var CodeCastingAttributeToTypeNumber;

#Region Main_procedures_and_functions

Procedure CompareDataOnServer(ErrorsText = "") Export
	
	//Сообщения при ошибке в произвольном коде незачем показывать больше одного раза, они скорее всего будут одинаковые
	//Error messages in arbitrary code should not be shown more than once, they will most likely be the same
	ErrorMessageRunningCodeForOutputRows = False;
	ErrorMessageWhenExecutingCodeToForbidRowOutput = False;
	MessageHaveMultipleRowsOneKey = False;
		
	If Not CheckFillingAttributes() Then
		Return;
	EndIf;
	
	OffsetNumberAttribute = NumberColumnsInKey - 1;
	
	ErrorText = "";
	ConnectionA = Undefined;
	ValueTable_A = ReadDataAndGetValueTable("A", ErrorText, ConnectionA);
	
	If ValueTable_A = Undefined Then
		ErrorsText = ErrorsText + ?(IsBlankString(ErrorsText), "", Chars.LF) + ErrorText;
	EndIf;
	
	ErrorText = "";
	ConnectionB = Undefined;
	ValueTable_B = ReadDataAndGetValueTable("B", ErrorText, ConnectionB);
	
	If ValueTable_B = Undefined Then
		ErrorsText = ErrorsText + ?(IsBlankString(ErrorsText), "", Chars.LF) + ErrorText;
	EndIf;
	
	If ValueTable_A = Undefined Or ValueTable_B = Undefined Then
		Return;
	EndIf;
		
	ColumnNameNumberOfRowsDataSource = "NumberOfRowsDataSource_" + StrReplace(String(New UUID), "-", "");
	
	
#Region ValueTable_A_Grouped
	
	ValueTable_A_Grouped = ValueTable_A.Copy();
	ValueTable_A_Grouped.Columns.Add(ColumnNameNumberOfRowsDataSource);
	
	KeyNameA1 = ValueTable_A_Grouped.Columns.Get(0).Name;
	ColumnsKeyAString = KeyNameA1;
	
	If NumberColumnsInKey > 1 Then
		KeyNameA2 = ValueTable_A_Grouped.Columns.Get(1).Name;
		ColumnsKeyAString = ColumnsKeyAString + "," + KeyNameA2;
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		KeyNameA3 = ValueTable_A_Grouped.Columns.Get(2).Name;
		ColumnsKeyAString = ColumnsKeyAString + "," + KeyNameA3;
	EndIf;
		
	ValueTable_A_Grouped.FillValues(1,ColumnNameNumberOfRowsDataSource);	
	ValueTable_A_Grouped.Collapse(ColumnsKeyAString, ColumnNameNumberOfRowsDataSource);	
	ValueTable_A_Grouped.Indexes.Add(ColumnsKeyAString);
	
#EndRegion


#Region ValueTable_B_Grouped

	ValueTable_B_Grouped = ValueTable_B.Copy();
	ValueTable_B_Grouped.Columns.Add(ColumnNameNumberOfRowsDataSource);
	
	KeyNameB1 = ValueTable_B_Grouped.Columns.Get(0).Name;
	ColumnsKeyBString = KeyNameB1;
	If NumberColumnsInKey > 1 Then
		KeyNameB2 = ValueTable_B_Grouped.Columns.Get(1).Name;
		ColumnsKeyBString = ColumnsKeyBString + "," + KeyNameB2;
	EndIf;
	If NumberColumnsInKey > 2 Then
		KeyNameB3 = ValueTable_B_Grouped.Columns.Get(2).Name;
		ColumnsKeyBString = ColumnsKeyBString + "," + KeyNameB3;
	EndIf;
			
	ValueTable_B_Grouped.FillValues(1, ColumnNameNumberOfRowsDataSource);
	ValueTable_B_Grouped.Collapse(ColumnsKeyBString, ColumnNameNumberOfRowsDataSource);
	ValueTable_B_Grouped.Indexes.Add(ColumnsKeyBString);
	
#EndRegion


	NumberOfColumnsValueTable_A = ValueTable_A.Columns.Count();
	NumberOfColumnsValueTable_B = ValueTable_B.Columns.Count();
	
	TotalsByAttributesMap = New Map;
	For AttributesCounter = 1 To NumberOfRequisites Do
		
		ThisObject["VisibilityAttributeA" + AttributesCounter] = ThisObject["VisibilityAttributeA" + AttributesCounter] And NumberOfColumnsValueTable_A >= AttributesCounter;
		ThisObject["VisibilityAttributeB" + AttributesCounter] = ThisObject["VisibilityAttributeB" + AttributesCounter] And NumberOfColumnsValueTable_B >= AttributesCounter;
		
		TotalsByAttributesMap.Insert("AttributeA" + AttributesCounter, New Structure(
			"ОшибкаПриВычислении,CalculateTotal,AggregateFunctionCalculationTotal,ValueTotal,СуммаЗначений,ЧислоЗначений"
				, False
				, ?(SettingsFileA.Count() < AttributesCounter, False, SettingsFileA[AttributesCounter - 1].CalculateTotal)
				, ?(SettingsFileA.Count() < AttributesCounter, "Сумма", SettingsFileA[AttributesCounter - 1].AggregateFunctionCalculationTotal)
				, Undefined
				, 0
				, 0));
		TotalsByAttributesMap.Insert("AttributeB" + AttributesCounter, New Structure(
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
		
		For Each RowValueTable_A_Grouped In ValueTable_A_Grouped Do 		
			           			
			Key1 = RowValueTable_A_Grouped[KeyNameA1];
			
			If NumberColumnsInKey > 1 Then
				Key2 = RowValueTable_A_Grouped[KeyNameA2];				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				Key3 = RowValueTable_A_Grouped[KeyNameA3];
			EndIf;

			If ConnectionB = Undefined Then
				SelectionStructure = New Structure;
			Else
				SelectionStructure = ConnectionB.NewObject("Structure");
			EndIf;
			
			SelectionStructure.Insert(KeyNameB1, Key1);
			
			If NumberColumnsInKey > 1 Then
				SelectionStructure.Insert(KeyNameB2, Key2);
			EndIf;
			If NumberColumnsInKey > 2 Then
				SelectionStructure.Insert(KeyNameB3, Key3);
			EndIf;
			
			FoundRows = ValueTable_B_Grouped.FindRows(SelectionStructure);
			RowValueTable_B_Grouped = ?(FoundRows.Count() > 0, FoundRows.Get(0), Undefined);
			
			If RelationalOperation = 2 Or RelationalOperation = 3
				Or ((RelationalOperation = 1 Or RelationalOperation = 7) And RowValueTable_B_Grouped = Undefined) 
				Or ((RelationalOperation = 4 Or RelationalOperation = 6) And RowValueTable_B_Grouped <> Undefined) Then
				
				RowTP_Result = Result.Add();
				
			Else
				Continue;
			EndIf;
			
			RowTP_Result.Key1 = Key;
			If DisplayKeyColumnTypes Then
				RowTP_Result.ColumnType1Key = TypeOf(RowTP_Result.Key1);
			EndIf;
			If NumberColumnsInKey > 1 Then
				RowTP_Result.Key2 = Key2;
				If DisplayKeyColumnTypes Then
					RowTP_Result.ColumnType2Key = TypeOf(RowTP_Result.Key2);
				EndIf;
			EndIf;
			If NumberColumnsInKey > 2 Then
				RowTP_Result.Key3 = Key3;
				If DisplayKeyColumnTypes Then
					RowTP_Result.ColumnType3Key = TypeOf(RowTP_Result.Key3);
				EndIf;
			EndIf;
			
			RowTP_Result.NumberOfRecordsA = RowValueTable_A_Grouped[ColumnNameNumberOfRowsDataSource];
			If RowValueTable_B_Grouped <> Undefined Then
				RowTP_Result.NumberOfRecordsB = RowValueTable_B_Grouped[ColumnNameNumberOfRowsDataSource];
			EndIf;
			
			If NumberOfColumnsValueTable_A > 1 Then
								
				If ConnectionA = Undefined Then
					SelectionStructure = New Structure;
				Else
					SelectionStructure = ConnectionA.NewObject("Structure");
				EndIf;
				SelectionStructure.Insert(KeyNameA1, Key);
				If NumberColumnsInKey > 1 Then
					SelectionStructure.Insert(KeyNameA2, Key2);
				EndIf;
				If NumberColumnsInKey > 2 Then
					SelectionStructure.Insert(KeyNameA3, Key3);
				EndIf;
				
				FoundRows = ValueTable_A.FindRows(SelectionStructure);
				RowValueTable_A = ?(FoundRows.Count() > 0, FoundRows.Get(0), Undefined);
				
				//Values ​​of attributes are displayed only if there is a single entry by key
				If RowTP_Result.NumberOfRecordsA = 1 Then
					For CounterColumnA = 1 To Min(NumberOfRequisites, NumberOfColumnsValueTable_A - NumberColumnsInKey) Do
						RowTP_Result["AttributeA" + CounterColumnA] = RowValueTable_A.Get(CounterColumnA + OffsetNumberAttribute);
					EndDo;
				EndIf;
				
			EndIf;
						
			If NumberOfColumnsValueTable_B > 1 Then
								
				If ConnectionB = Undefined Then
					SelectionStructure = New Structure;
				Else
					SelectionStructure = ConnectionB.NewObject("Structure");
				EndIf;
				SelectionStructure.Insert(KeyNameB1, Key);
				If NumberColumnsInKey > 1 Then
					SelectionStructure.Insert(KeyNameB2, Key2);
				EndIf;
				If NumberColumnsInKey > 2 Then
					SelectionStructure.Insert(KeyNameB3, Key3);
				EndIf;
				
				FoundRows = ValueTable_B.FindRows(SelectionStructure);
				RowValueTable_B = ?(FoundRows.Count() > 0, FoundRows.Get(0), Undefined);
							
				If RowValueTable_B <> Undefined Then
					
					//Values ​​of attributes are displayed only if there is a single entry by key
					If RowTP_Result.NumberOfRecordsB = 1 Then
						For CounterColumnB = 1 To Min(NumberOfRequisites, NumberOfColumnsValueTable_B - NumberColumnsInKey) Do
							RowTP_Result["AttributeB" + CounterColumnB] = RowValueTable_B.Get(CounterColumnB + OffsetNumberAttribute);
						EndDo;
					EndIf;
					
				EndIf;
				
			EndIf;
						
			ConditionsOutputRowCompleted = True;
			
			If Not ConditionsOutputRowsDisabled Then 
				Try
					Execute CodeForOutputRows;
				Except
					If Not ErrorMessageRunningCodeForOutputRows Then
						ErrorText = ErrorDescription();
						Message(Format(CurrentDate(),"DLF=DT") + ": " + ErrorText);
					EndIf;
					ErrorMessageRunningCodeForOutputRows = True;
				EndTry;
			EndIf;
			
			//If the number of rows with the same key is greater than 1, the resulting row must be displayed,
			//because conditions in this case it is incorrect to apply at all
			If RowTP_Result.NumberOfRecordsA <= 1 And RowTP_Result.NumberOfRecordsB <= 1 Then
				
				ConditionsProhibitOutputRowCompleted = False;
				
				If Not ConditionsProhibitOutputRowsDisabled Then 
					Try
						Execute CodeForProhibitingOutputRows; 
					Except
						If Not ErrorMessageWhenExecutingCodeToForbidRowOutput Then
							ErrorText = ErrorDescription();
							Message(Format(CurrentDate(),"DLF=DT") + ": " + ErrorText);						
						EndIf;
						ErrorMessageWhenExecutingCodeToForbidRowOutput = True;
					EndTry;
				EndIf;
				
				//Условия вывода строк, установленные пользователем
				If Not ConditionsOutputRowCompleted Or ConditionsProhibitOutputRowCompleted Then					
					
					Result.Delete(RowTP_Result);
					Continue;
					
				EndIf;
				
				For AttributesCounter = 1 По NumberOfRequisites Do
					
					AttributeName = "AttributeA" + AttributesCounter;
					If TotalsByAttributesMap[AttributeName].РассчитыватьИтог And TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = False Then
						Try
							пЗначениеРеквизита = RowTP_Result[AttributeName];
							Если ЗначениеЗаполнено(пЗначениеРеквизита) Then
								пТипЗначения = ТипЗнч(пЗначениеРеквизита);
								//Количество
								Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Количество" Then
									TotalsByAttributesMap[AttributeName].ЧислоЗначений = TotalsByAttributesMap[AttributeName].ЧислоЗначений + 1;
								ИначеЕсли пТипЗначения = Тип("Число") Или пТипЗначения = Тип("Строка") Then
									пЗначениеРеквизитаЧисло = Число(пЗначениеРеквизита);																		
									//Сумма
									Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Сумма" Then
										TotalsByAttributesMap[AttributeName].СуммаЗначений = TotalsByAttributesMap[AttributeName].СуммаЗначений + пЗначениеРеквизитаЧисло;
									//Среднее
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Среднее" Then
										TotalsByAttributesMap[AttributeName].СуммаЗначений = TotalsByAttributesMap[AttributeName].СуммаЗначений + пЗначениеРеквизитаЧисло;
										TotalsByAttributesMap[AttributeName].ЧислоЗначений = TotalsByAttributesMap[AttributeName].ЧислоЗначений + 1;
									//Максимум
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Максимум" Then
										TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЗначениеИтога <> Undefined, Max(TotalsByAttributesMap[AttributeName].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									//Минимум
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Минимум" Then
										TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЗначениеИтога <> Undefined, Min(TotalsByAttributesMap[AttributeName].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									EndIf;
								Иначе
									TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = Истина;
								EndIf;
							EndIf;
						Except
							TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = True;
						EndTry;
					EndIf;
					
					AttributeName = "AttributeB" + AttributesCounter;
					Если TotalsByAttributesMap[AttributeName].РассчитыватьИтог И TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = False Then
						Попытка
							пЗначениеРеквизита = RowTP_Result[AttributeName];
							Если ЗначениеЗаполнено(пЗначениеРеквизита) Then
								пТипЗначения = ТипЗнч(пЗначениеРеквизита);
								//Количество
								Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Количество" Then
									TotalsByAttributesMap[AttributeName].ЧислоЗначений = TotalsByAttributesMap[AttributeName].ЧислоЗначений + 1;
								ИначеЕсли пТипЗначения = Тип("Число") Или пТипЗначения = Тип("Строка") Then
									пЗначениеРеквизитаЧисло = Число(пЗначениеРеквизита);																		
									//Сумма
									Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Сумма" Then
										TotalsByAttributesMap[AttributeName].СуммаЗначений = TotalsByAttributesMap[AttributeName].СуммаЗначений + пЗначениеРеквизитаЧисло;
									//Среднее
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Среднее" Then
										TotalsByAttributesMap[AttributeName].СуммаЗначений = TotalsByAttributesMap[AttributeName].СуммаЗначений + пЗначениеРеквизитаЧисло;
										TotalsByAttributesMap[AttributeName].ЧислоЗначений = TotalsByAttributesMap[AttributeName].ЧислоЗначений + 1;
									//Максимум
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Максимум" Then
										TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЗначениеИтога <> Undefined, Max(TotalsByAttributesMap[AttributeName].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									//Минимум
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Минимум" Then
										TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЗначениеИтога <> Undefined, Min(TotalsByAttributesMap[AttributeName].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									EndIf;
								Иначе
									TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = Истина;
								EndIf;
							EndIf;
						Исключение
							TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = Истина;
						КонецПопытки;
					EndIf;
					
				EndDo;
				
			Else
				
				MessageHaveMultipleRowsOneKey = True;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
#EndRegion 


#Region _3_4_5_7
	
	If RelationalOperation = 3 Or RelationalOperation = 4 Or RelationalOperation = 5 Or RelationalOperation = 7 Then
		
		For Each RowValueTable_B_Grouped In ValueTable_B_Grouped Do 		
			
			Key1 = RowValueTable_B_Grouped[KeyNameB1];
			
			If NumberColumnsInKey > 1 Then
				Key2 = RowValueTable_B_Grouped[KeyNameB2];				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				Key3 = RowValueTable_B_Grouped[KeyNameB3];
			EndIf;

			If ConnectionA = Undefined Then
				SelectionStructure = New Structure;
			Else
				SelectionStructure = ConnectionA.NewObject("Structure");
			EndIf;
			SelectionStructure.Insert(KeyNameA1, Key);
			If NumberColumnsInKey > 1 Then
				SelectionStructure.Insert(KeyNameA2, Key2);
			EndIf;
			If NumberColumnsInKey > 2 Then
				SelectionStructure.Insert(KeyNameA3, Key3);
			EndIf;
			
			FoundRows = ValueTable_A_Grouped.FindRows(SelectionStructure);
			RowValueTable_A_Grouped = ?(FoundRows.Count() > 0, FoundRows.Get(0), Undefined);
						
			//All intersections processed in the previous section
			If RowValueTable_A_Grouped <> Undefined Then
				Continue;
			EndIf;
			
			RowTP_Result = Result.Add();
			
			RowTP_Result.Key1 = Key;
			If DisplayKeyColumnTypes Then
				RowTP_Result.ColumnType1Key = TypeOf(RowTP_Result.Key1);
			EndIf;
			
			If NumberColumnsInKey > 1 Then
				RowTP_Result.Key2 = Key2;
				If DisplayKeyColumnTypes Then
					RowTP_Result.ColumnType2Key = TypeOf(RowTP_Result.Key2);
				EndIf;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				RowTP_Result.Key3 = Key3;
				If DisplayKeyColumnTypes Then
					RowTP_Result.ColumnType3Key = TypeOf(RowTP_Result.Key3);
				EndIf;
			EndIf;
			
			RowTP_Result.NumberOfRecordsB = RowValueTable_B_Grouped[ColumnNameNumberOfRowsDataSource];
			
			If NumberOfColumnsValueTable_B > 1 Then
				      							
				If ConnectionB = Undefined Then
					SelectionStructure = New Structure;
				Else
					SelectionStructure = ConnectionB.NewObject("Structure");
				EndIf;
				SelectionStructure.Insert(KeyNameB1, Key);
				If NumberColumnsInKey > 1 Then
					SelectionStructure.Insert(KeyNameB2, Key2);
				EndIf;
				If NumberColumnsInKey > 2 Then
					SelectionStructure.Insert(KeyNameB3, Key3);
				EndIf;
				
				FoundRows = ValueTable_B.FindRows(SelectionStructure);
				RowValueTable_B = ?(FoundRows.Count() > 0, FoundRows.Get(0), Undefined);
			
				If RowValueTable_B <> Undefined Then
					
					//Values реквизитов выводятся только при наличии единственной записи по ключу
					If RowTP_Result.NumberOfRecordsB = 1 Then
						For CounterColumnB = 1 To Min(NumberOfRequisites, NumberOfColumnsValueTable_B - NumberColumnsInKey) Do
							RowTP_Result["AttributeB" + CounterColumnB] = RowValueTable_B.Get(CounterColumnB + OffsetNumberAttribute);
						EndDo;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			//If число строк с одним ключом больше 1, результирующую строку нужно вывести обязательно, 
			//т.к. условия в данном случае некорректно применять вообще
			If RowTP_Result.NumberOfRecordsA <= 1 And RowTP_Result.NumberOfRecordsB <= 1 Then
				
				ConditionsOutputRowCompleted = True;
				
				If Not ConditionsOutputRowsDisabled Then
					Try
						Execute CodeForOutputRows; 
					Except
						If Not ErrorMessageRunningCodeForOutputRows Then
							ErrorText = ErrorDescription();
							Message(Format(CurrentDate(),"DLF=DT") + ": " + ErrorText);						
						EndIf;
						ErrorMessageRunningCodeForOutputRows = True;
					EndTry;
				EndIf;
				
				ConditionsProhibitOutputRowCompleted = False;
				
				If Not ConditionsProhibitOutputRowsDisabled Then
					Try
						Execute CodeForProhibitingOutputRows; 
					Except
						If Not ErrorMessageWhenExecutingCodeToForbidRowOutput Then
							ErrorText = ErrorDescription();
							Message(Format(CurrentDate(),"DLF=DT") + ": " + ErrorText);
						EndIf;
						ErrorMessageWhenExecutingCodeToForbidRowOutput = True;
					EndTry;
				EndIf;
				
				//Условия вывода строк, установленные пользователем
				If Not ConditionsOutputRowCompleted Or ConditionsProhibitOutputRowCompleted Then					
					
					Result.Delete(RowTP_Result);
					Continue;
				EndIf;
				
				For AttributesCounter = 1 По NumberOfRequisites Цикл
															
					AttributeName = "AttributeB" + AttributesCounter;
					Если TotalsByAttributesMap[AttributeName].РассчитыватьИтог И TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = Ложь Тогда
						Попытка
							пЗначениеРеквизита = RowTP_Result[AttributeName];
							Если ЗначениеЗаполнено(пЗначениеРеквизита) Тогда
								пТипЗначения = ТипЗнч(пЗначениеРеквизита);
								//Количество
								Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Количество" Тогда
									TotalsByAttributesMap[AttributeName].ЧислоЗначений = TotalsByAttributesMap[AttributeName].ЧислоЗначений + 1;
								ИначеЕсли пТипЗначения = Тип("Число") Или пТипЗначения = Тип("Строка") Тогда
									пЗначениеРеквизитаЧисло = Число(пЗначениеРеквизита);																		
									//Сумма
									Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Сумма" Тогда
										TotalsByAttributesMap[AttributeName].СуммаЗначений = TotalsByAttributesMap[AttributeName].СуммаЗначений + пЗначениеРеквизитаЧисло;
									//Среднее
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Среднее" Тогда
										TotalsByAttributesMap[AttributeName].СуммаЗначений = TotalsByAttributesMap[AttributeName].СуммаЗначений + пЗначениеРеквизитаЧисло;
										TotalsByAttributesMap[AttributeName].ЧислоЗначений = TotalsByAttributesMap[AttributeName].ЧислоЗначений + 1;
									//Максимум
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Максимум" Тогда
										TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЗначениеИтога <> Неопределено, Макс(TotalsByAttributesMap[AttributeName].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									//Минимум
									ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Минимум" Тогда
										TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЗначениеИтога <> Неопределено, Мин(TotalsByAttributesMap[AttributeName].ЗначениеИтога, пЗначениеРеквизитаЧисло), пЗначениеРеквизитаЧисло);
									EndIf;
								Иначе
									TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = Истина;
								EndIf;
							EndIf;
						Исключение
							TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении = Истина;
						КонецПопытки;
					EndIf;
					
				EndDo;
				
			Else
				
				MessageHaveMultipleRowsOneKey = True;
				
			EndIf;
			
		EndDo;

	EndIf;
#EndRegion 

	For AttributesCounter = 1 По NumberOfRequisites Цикл
					
		AttributeName = "AttributeA" + AttributesCounter;
		Если TotalsByAttributesMap[AttributeName].РассчитыватьИтог Тогда
			Если TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении Тогда
				TotalsByAttributesMap[AttributeName].ЗначениеИтога = "Ошибка";
			Иначе
				//Сумма
				Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Сумма" Тогда
					TotalsByAttributesMap[AttributeName].ЗначениеИтога = TotalsByAttributesMap[AttributeName].СуммаЗначений;
				//Среднее
				ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Среднее" Тогда
					TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЧислоЗначений <> 0, TotalsByAttributesMap[AttributeName].СуммаЗначений / TotalsByAttributesMap[AttributeName].ЧислоЗначений, 0);
				//Количество
				ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Количество" Тогда
					TotalsByAttributesMap[AttributeName].ЗначениеИтога = TotalsByAttributesMap[AttributeName].ЧислоЗначений;
				EndIf;
			EndIf;
		
			ThisObject["ЗначениеИтога" + AttributeName] = "A" + AttributesCounter + ": " + TotalsByAttributesMap[AttributeName].ЗначениеИтога;
		
		Иначе
			ThisObject["ЗначениеИтога" + AttributeName] = "";
		EndIf;
		
		AttributeName = "AttributeB" + AttributesCounter;
		Если TotalsByAttributesMap[AttributeName].РассчитыватьИтог Тогда
			Если TotalsByAttributesMap[AttributeName].ОшибкаПриВычислении Тогда
				TotalsByAttributesMap[AttributeName].ЗначениеИтога = "Ошибка";
			Иначе
				//Сумма
				Если TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Сумма" Тогда
					TotalsByAttributesMap[AttributeName].ЗначениеИтога = TotalsByAttributesMap[AttributeName].СуммаЗначений;
				//Среднее
				ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Среднее" Тогда
					TotalsByAttributesMap[AttributeName].ЗначениеИтога = ?(TotalsByAttributesMap[AttributeName].ЧислоЗначений <> 0, TotalsByAttributesMap[AttributeName].СуммаЗначений / TotalsByAttributesMap[AttributeName].ЧислоЗначений, 0);
					//Количество
				ИначеЕсли TotalsByAttributesMap[AttributeName].AggregateFunctionCalculationTotal = "Количество" Тогда
					TotalsByAttributesMap[AttributeName].ЗначениеИтога = TotalsByAttributesMap[AttributeName].ЧислоЗначений;
				EndIf;
			EndIf;
			
			ThisObject["ЗначениеИтога" + AttributeName] = "B" + AttributesCounter + ": " + TotalsByAttributesMap[AttributeName].ЗначениеИтога;
			
		Иначе
			ThisObject["ЗначениеИтога" + AttributeName] = "";
		EndIf;
		
	EndDo;

	Если SortTableDifferences Тогда
		Result.Сортировать(OrderSortTableDifferences);
	EndIf;
		
	If MessageHaveMultipleRowsOneKey Then
		Message(Формат(ТекущаяДата(),"DLF=DT") + ": Обнаружены дубликаты (подсвечены красным цветом), настройки отбора на них не распространяются. Просмотреть дублирующиеся строки можно на форме предварительного просмотра.");
	EndIf;
	
EndProcedure

Function ReadDataAndGetValueTable(BaseID, ErrorText = "", Connection = Undefined) Export
	
	//Current or external base 1C 8
	If ThisObject["BaseType" + BaseID] = 0 Or ThisObject["BaseType" + BaseID] = 1 Then
		 ValueTable = ExecuteQuery1C8AndGetValueTable(BaseID, ErrorText, Connection);
	//SQL
	ElsIf ThisObject["BaseType" + BaseID] = 2 Then		
		ValueTable = ExecuteQuerySQLAndGetValueTable(BaseID, ErrorText);
	//File
	ElsIf ThisObject["BaseType" + BaseID] = 3 Then
		ValueTable = ReadDataFromFileAndGetValueTable(BaseID, ErrorText);
	//Table
	ElsIf ThisObject["BaseType" + BaseID] = 4 Then		
		ValueTable = GetDataFromSpreadsheetDocument(BaseID, ErrorText);
	//Outer base 1С 7.7
	ElsIf ThisObject["BaseType" + BaseID] = 5 Then		
		ValueTable = ExecuteQuery1C77AndGetValueTable(BaseID, ErrorText);
	//JSON
	ElsIf ThisObject["BaseType" + BaseID] = 6 Then		
		ValueTable = ReadDataFromJSONAndGetValueTable(BaseID, ErrorText);
	Else
		ErrorText = StrTemplate(Nstr("ru = 'Тип базы %1 ''%2'' не предусмотрен';en = 'Base type %1 ''%2'' is not provided'")
			, BaseID
			, ThisObject["BaseType" + BaseID]);
		Message(Format(CurrentDate(),"DLF=DT") + ": " + ErrorText);
		ValueTable = Undefined;
	EndIf;
	
	If ThisObject["BaseType" + BaseID] >= 3 And ThisObject["CollapseTable" + BaseID] Then
		KeyColumns = "Key1";
		If NumberColumnsInKey > 1 Then
			KeyColumns = KeyColumns + ",Key2";
		EndIf;
		If NumberColumnsInKey > 2 Then
			KeyColumns = KeyColumns + ",Key3";
		EndIf;
		ValueTable.Collapse(KeyColumns,"Attribute1, Attribute2, Attribute3, Attribute4, Attribute5");
	EndIf;
	
	Return ValueTable;
	
EndFunction

Function ExecuteQuery1C8AndGetValueTable(BaseID, ErrorsText = "", Connection = Undefined)
	
	//Current
	If ThisObject["BaseType" + BaseID] = 0 Then
		
		Query = New Query;
		Query.Text = ThisObject["QueryText" + BaseID];
		
		SetParameters(Query, BaseID); 
		
	//Outer
	ElsIf ThisObject["BaseType" + BaseID] = 1 Then
		
		If ThisObject["WorkOptionExternalBase" + BaseID] = 0 Then
			ParameterConnections = 
				"File=""" + ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"]
				+ """;Usr=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Login"]
				+ """;Pwd=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Password"] + """;";	
		Else
			ParameterConnections = 
				"Srvr=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Server"]
				+ """;Ref=""" + ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"] 
				+ """;Usr=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Login"] 
				+ """;Pwd=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Password"] + """;";
		EndIf;
				
		Try
			COMConnector = New COMObject(ThisObject["VersionPlatformExternalBase" + BaseID] + ".COMConnector");
			Connection = COMConnector.Connect(ParameterConnections);
		Except
			ErrorText = ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndTry;

		Query = Connection.NewObject("Query");
		Query.Text = ThisObject["QueryText" + BaseID];
		
		SetParameters(Query, BaseID); 
	
	EndIf;
	
	Query.SetParameter("ValidFrom", 	AbsolutePeriodValue.ValidFrom);
	Query.SetParameter("ValidTo", 	AbsolutePeriodValue.ValidTo);
	
	Try
		ValueTable = Query.Execute().Unload();
	Except
		ErrorText = ErrorDescription();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		ValueTable = Undefined;
	EndTry;
	
	If ValueTable <> Undefined Then
				
		NumberOfcolumnsInValueTable = ValueTable.Columns.Count();
		If NumberColumnsInKey > NumberOfcolumnsInValueTable Then
			ErrorText = StrTemplate(Nstr("ru = 'Выборка из источника %1 содержит %2 колонок, проверьте корректность заданного числа столбцов в ключе';en = 'The selection from the source %1 contains %2 columns, check the correctness of the specified number of columns in the key'")
				, BaseID
				, NumberOfcolumnsInValueTable);
			UserMessage = New UserMessage;
			UserMessage.Text = ErrorText;
			UserMessage.Field = "Object.NumberColumnsInKey";
			UserMessage.Message();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndIf;
		    
		For AttributesCounter = 1 To Min(NumberOfcolumnsInValueTable - NumberColumnsInKey, NumberOfRequisites) Do //
			
			If ThisObject["SettingsFile" + BaseID].Count() >= AttributesCounter Then
				HeaderAttributeFromSettings = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].HeaderAttributeForUser;
			Else
				HeaderAttributeFromSettings = "";
			EndIf;
			
			AttributeName = String(BaseID) + AttributesCounter;			
			ViewsHeadersAttributes[AttributeName] = AttributeName + ": " + ?(IsBlankString(HeaderAttributeFromSettings), ValueTable.Columns.Get(AttributesCounter + NumberColumnsInKey - 1).Title, HeaderAttributeFromSettings);
					
		EndDo; 
		
		If (ThisObject["UseAsKeyUniqueIdentifier" + BaseID]
			Or ThisObject["CastKeyToUpperCase" + BaseID] 
			Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] 
			Or ThisObject["CastKeyToString" + BaseID]
			Or ThisObject["ExecuteArbitraryKeyCode1" + BaseID])
			Or NumberColumnsInKey > 1 And 
			(ThisObject["UseAsKey2UniqueIdentifier" + BaseID] 
			Or ThisObject["CastKey2ToUpperCase" + BaseID] 
			Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] 
			Or ThisObject["CastKey2ToString" + BaseID]
			Or ThisObject["ExecuteArbitraryKeyCode2" + BaseID])
			Or NumberColumnsInKey > 2 And 
			(ThisObject["UseAsKey3UniqueIdentifier" + BaseID] 
			Or ThisObject["CastKey3ToUpperCase" + BaseID] 
			Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] 
			Or ThisObject["CastKey3ToString" + BaseID]
			Or ThisObject["ExecuteArbitraryKeyCode3" + BaseID])Then
			
			FirstColumnName 	= ValueTable.Columns.Get(0).Name;
			ColumnNameKey1		= FirstColumnName;
			ColumnNumberKey1	= 0;
			ColumnNumberKey2	= 1;
			ColumnNumberKey3	= 2;
			
			If NumberColumnsInKey > 1 Then
				SecondColumnName = ValueTable.Columns.Get(1).Name;
				ColumnNameKey2 = SecondColumnName;
			Else
				SecondColumnName = "";
				ColumnNameKey2 = "";
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				ThirdColumnName = ValueTable.Columns.Get(2).Name;
				ColumnNameKey3 = ThirdColumnName;
			Else
				ThirdColumnName = "";
				ColumnNameKey3 = "";
			EndIf;
			
			If ThisObject["UseAsKeyUniqueIdentifier" + BaseID]
				Or ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
				
				ColumnNameKey1 = "Key1" + Format(CurrentDate(), "DF=ddMMyyyyHHmmss");
				ValueTable.Columns.Insert(ColumnNumberKey1, ColumnNameKey1);
				ColumnNumberKey2 = ColumnNumberKey2 + 1;
				ColumnNumberKey3 = ColumnNumberKey3 + 1;

			EndIf;
		
			If NumberColumnsInKey > 1 Then
			
				If ThisObject["UseAsKey2UniqueIdentifier" + BaseID]
					Or ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ColumnNameKey2 = "Key2" + Format(CurrentDate(), "DF=ddMMyyyyHHmmss");
					ValueTable.Columns.Insert(ColumnNumberKey2, ColumnNameKey2);
					ColumnNumberKey3 = ColumnNumberKey3 + 1;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ThisObject["UseAsKey3UniqueIdentifier" + BaseID]
					Or ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ColumnNameKey3 = "Key3" + Format(CurrentDate(), "DF=ddMMyyyyHHmmss");
					ValueTable.Columns.Insert(ColumnNumberKey3, ColumnNameKey3);
					
				EndIf;
				
			EndIf;
			
			//Indexing
			ColumnsWithKeyRow = ColumnNameKey1;
			If NumberColumnsInKey > 1 Then
				ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ColumnNameKey2;
			EndIf;
			If NumberColumnsInKey > 2 Then
				ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ColumnNameKey3;
			EndIf;

			ValueTable.Indexes.Add(ColumnsWithKeyRow);
			       						
			RowsCounter = 0;
			For Each RowValueTable In ValueTable Do
				
				RowsCounter = RowsCounter + 1;
								
				Try
					
					If ThisObject["UseAsKeyUniqueIdentifier" + BaseID] Then
						If ThisObject["BaseType" + BaseID] = 0 Then
							RowValueTable[ColumnNameKey1] = TrimAll(XMLString(RowValueTable[FirstColumnName]));
						Else
							RowValueTable[ColumnNameKey1] = TrimAll(Connection.XMLString(RowValueTable[FirstColumnName]));
						EndIf;
					ElsIf ThisObject["CastKeyToString" + BaseID]
						Or ThisObject["CastKeyToUpperCase" + BaseID]
						Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						RowValueTable[ColumnNameKey1] = TrimAll(String(RowValueTable[FirstColumnName]));
					EndIf;
					
					If ThisObject["KeyLengthWhenCastingToString" + BaseID] > 0 Then
						RowValueTable[ColumnNameKey1] = TrimAll(Left(RowValueTable[ColumnNameKey1], ThisObject["KeyLengthWhenCastingToString" + BaseID]));
					EndIf;
						
					If ThisObject["CastKeyToUpperCase" + BaseID] Then
						RowValueTable[ColumnNameKey1] = TrimAll(Upper(String(RowValueTable[ColumnNameKey1])));
					EndIf;
					
					If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						RowValueTable[ColumnNameKey1] = TrimAll(StrReplace(StrReplace(String(RowValueTable[ColumnNameKey1]), "{", ""), "}", ""));
					EndIf;
					
				Except
					
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке ключа в строке %1 выборки из базы %2: %3';en = 'Error processing key in row %1 of selection from base %2: %3'")
						, RowsCounter
						, BaseID
						, ErrorDescription());
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
				If NumberColumnsInKey > 1 Then
						
					Try
						
						If ThisObject["UseAsKey2UniqueIdentifier" + BaseID] Then
							If ThisObject["BaseType" + BaseID] = 0 Then
								RowValueTable[ColumnNameKey2] = TrimAll(XMLString(RowValueTable[SecondColumnName]));
							Else
								RowValueTable[ColumnNameKey2] = TrimAll(Connection.XMLString(RowValueTable[SecondColumnName]));
							EndIf;
						ElsIf ThisObject["CastKey2ToString" + BaseID]
							Or ThisObject["CastKey2ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey2] = TrimAll(String(RowValueTable[SecondColumnName]));
						EndIf;

						
						If ThisObject["KeyLength2WhenCastingToString" + BaseID] > 0 Then
							RowValueTable[ColumnNameKey2] = TrimAll(Left(RowValueTable[ColumnNameKey2], ThisObject["KeyLengthWhenCastingToString" + BaseID]));
						EndIf;
						
						If ThisObject["CastKey2ToUpperCase" + BaseID] Then
							RowValueTable[ColumnNameKey2] = TrimAll(Upper(String(RowValueTable[ColumnNameKey2])));
						EndIf;
						
						If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey2] = TrimAll(StrReplace(StrReplace(String(RowValueTable[ColumnNameKey2]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке столбца 2 ключа в строке %1 выборки из базы %2: %3';en = 'Error processing column 2 of key in row %1 of fetch from base %2: %3'")
							, RowsCounter
							, BaseID
							, ErrorDescription());
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
						
					Try
						
						If ThisObject["UseAsKey3UniqueIdentifier" + BaseID] Then
							If ThisObject["BaseType" + BaseID] = 0 Then
								RowValueTable[ColumnNameKey3] = TrimAll(XMLString(RowValueTable[ThirdColumnName]));
							Else
								RowValueTable[ColumnNameKey3] = TrimAll(Connection.XMLString(RowValueTable[ThirdColumnName]));
							EndIf;
						ElsIf ThisObject["CastKey3ToString" + BaseID]
							Or ThisObject["CastKey3ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey3] = TrimAll(String(RowValueTable[ThirdColumnName]));
						EndIf;
						
						If ThisObject["KeyLength3WhenCastingToString" + BaseID] > 0 Then
							RowValueTable[ColumnNameKey3] = TrimAll(Left(RowValueTable[ColumnNameKey3], ThisObject["KeyLengthWhenCastingToString" + BaseID]));
						EndIf;
						
						If ThisObject["CastKey3ToUpperCase" + BaseID] Then
							RowValueTable[ColumnNameKey3] = TrimAll(Upper(String(RowValueTable[ColumnNameKey3])));
						EndIf;
						
						If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey3] = TrimAll(StrReplace(StrReplace(String(RowValueTable[ColumnNameKey3]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке столбца 3 ключа в строке %1 выборки из базы %2: %3';en = 'Error processing column 3 of key in row %1 of fetch from base %2: %3'")
							, RowsCounter
							,  BaseID
							, ErrorDescription());
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
						
#Region Arbitrary_key_processing_code

				KeyCurrent = RowValueTable[ColumnNameKey1];
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, KeyCurrent
							, BaseID
							, ErrorDescription());
						Message(ErrorText);
					EndTry;
				EndIf;
				RowValueTable[ColumnNameKey1] = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then
					KeyCurrent = RowValueTable[ColumnNameKey2];
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
							, KeyCurrent
							, BaseID
							, ErrorDescription());							
							Message(ErrorText);
						EndTry;
					EndIf;
					RowValueTable[ColumnNameKey2] = KeyCurrent;
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					KeyCurrent = RowValueTable[ColumnNameKey3];
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
							, KeyCurrent
							, BaseID
							, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowValueTable[ColumnNameKey3] = KeyCurrent;
				EndIf;
	
#EndRegion
				
			EndDo;
			
			If ThisObject["UseAsKeyUniqueIdentifier" + BaseID] 
				Or ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
			
				ValueTable.Columns.Delete(FirstColumnName);
			
			EndIf;
		
			If NumberColumnsInKey > 1 Then
								
				If ThisObject["UseAsKey2UniqueIdentifier" + BaseID] 
					Or ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ValueTable.Columns.Delete(SecondColumnName);
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
								
				If ThisObject["UseAsKey3UniqueIdentifier" + BaseID] 
					Or ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ValueTable.Columns.Delete(ThirdColumnName);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ValueTable;
	
EndFunction

Function ExecuteQuery1C77AndGetValueTable(BaseID, ErrorsText = "", Connection = Undefined)
	
	PathBase = ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"];
	User = ThisObject["ConnectionToExternalBase" + BaseID + "Login"];
	Password = ThisObject["ConnectionToExternalBase" + BaseID + "Password"];
		
	Connection = New COMObject("V1CEnterprise.Application");
    
    Try   
		
		RowConnection = "/D""" + TrimAll(PathBase) + """ /N""" + TrimAll(User) + """ /P""" + TrimAll(Password) + """";
        ConnectionInstalled = Connection.Initialize(Connection.RMTrade, RowConnection, "NO_SPLASH_SHOW");
        
        If ConnectionInstalled Then
            YesConnection = True;
        Else
            ErrorText = Nstr("ru = 'Ошибка при подключении к внешней базе';en = 'Error connecting to external database'");
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
        EndIf;    
    Except
        ErrorText = StrTemplate(Nstr("ru = 'Ошибка при подключении к внешней базе: %1';en = 'Error connecting to external database: %1'")
        	, ErrorDescription());
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		Return Undefined;
	EndTry;
		
	Query = Connection.CreateObject("Query");
	QueryText = ThisObject["QueryText" + BaseID];
	
	If Query.Execute(QueryText) = 0 Then
		Return Undefined;
	EndIf;

	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Key1");
	If NumberColumnsInKey > 1 Then
		ValueTable.Columns.Add("Key2");
	EndIf;
	If NumberColumnsInKey > 2 Then
		ValueTable.Columns.Add("Key3");
	EndIf;
	ValueTable.Columns.Add("Attribute1");
	ValueTable.Columns.Add("Attribute2");
	ValueTable.Columns.Add("Attribute3");
	ValueTable.Columns.Add("Attribute4");
	ValueTable.Columns.Add("Attribute5");
	
	ValueTable1C77 = Connection.CreateObject("ValueTable");
	Query.Unload(ValueTable1C77,1,0);	
	LineCount = ValueTable1C77.LineCount();
	ColumnsCount = ValueTable1C77.ColumnsCount();
	For RowsCounter = 1 To LineCount Do
		
		RowValueTable = ValueTable.Add();
			
		Key1 = ValueTable1C77.GetValue(RowsCounter, 1);
		
		If NumberColumnsInKey > 1 Then
			Key2 = ValueTable1C77.GetValue(RowsCounter, 2);
		Else
			Key2 = "";				
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			Key3 = ValueTable1C77.GetValue(RowsCounter, 3);
		Else
			Key3 = "";				
		EndIf;
		
		Try
			
			If ThisObject["CastKeyToString" + BaseID] Then
				Key1 = TrimAll(String(Key1));
			EndIf;
		
			If ThisObject["CastKeyToUpperCase" + BaseID] Then
				Key1 = TrimAll(Upper(String(Key1)));
			EndIf;
			
			If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
				Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
			EndIf;
			
		Except
			
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке ключа в строке %1 выборки из базы %2: %3';en = 'Error processing key in row %1 of fetch from base %2: %3'")
				, RowsCounter
				, BaseID
				, ErrorDescription());
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			
		EndTry;
		
		If NumberColumnsInKey > 1 Then
			
			Try
			
				If ThisObject["CastKey2ToString" + BaseID] Then
					Key2 = TrimAll(String(Key2));
				EndIf;
			
				If ThisObject["CastKey2ToUpperCase" + BaseID] Then
					Key2 = TrimAll(Upper(String(Key2)));
				EndIf;
				
				If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
				EndIf;
			
			Except
				
				ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке столбца 2 ключа в строке %1 выборки из базы %2: %3';en = 'Error processing column 2 of key in row %1 of fetch from base %2: %3'")
					, RowsCounter
					, BaseID
					, ErrorDescription());
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			EndTry;
			
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			Try
			
			If ThisObject["CastKey3ToString" + BaseID] Then
				Key3 = TrimAll(String(Key3));
			EndIf;
		
			If ThisObject["CastKey3ToUpperCase" + BaseID] Then
				Key3 = TrimAll(Upper(String(Key3)));
			EndIf;
			
			If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
				Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
			EndIf;
			
			Except
				
				ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке столбца 3 ключа в строке %1 выборки из базы %2: %3';en = 'Error processing column 3 of key in row %1 of fetch from base %2: %3'")
					, RowsCounter
					, BaseID
					, ErrorDescription());				
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			EndTry;
			
		EndIf;
			          			
#Region Arbitrary_key_processing_code

			KeyCurrent = Key1;
			If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
				Except
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, Key1
							, BaseID
							, ErrorDescription());					
					Message(ErrorText);
				EndTry;
			EndIf;
			RowValueTable.Key1 = KeyCurrent;
			
			If NumberColumnsInKey > 1 Then
				KeyCurrent = Key2;				
				If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
							, Key2
							, BaseID
							, ErrorDescription());						
						Message(ErrorText);
					EndTry;
				EndIf;
				RowValueTable.Key2 = KeyCurrent;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				KeyCurrent = Key3;
				If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
							, Key3
							, BaseID
							, ErrorDescription());						
						Message(ErrorText);
					EndTry;
				EndIf;
				RowValueTable.Key3 = KeyCurrent;
			EndIf;
			
#EndRegion 
			
		For ColumnCounter = 1 To Min(NumberOfRequisites, ColumnsCount - NumberColumnsInKey) Do    
			
			//ColumnName = = ValueTable1C77.ПолучитьПараметрыКолонки(ColumnCounter);
			CellValue = ValueTable1C77.GetValue(RowsCounter, ColumnCounter + NumberColumnsInKey);
			RowValueTable["Attribute" + ColumnCounter] = CellValue;
			
		EndDo;
				
	EndDo;
	
	Connection.Exit(0);
	
	Connection = Undefined;
		
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
	
	//ValueTable1C77 = CreateObject("ValueTable");
	//Query.Unload(ValueTable1C77,1,0);	
	//LineCount = ValueTable1C77.LineCount();
	//ColumnsCount = ValueTable1C77.ColumnsCount();
	//For RowsCounter = 1 To LineCount Do
	//	ВсяСтрока = "";
	//	For ColumnCounter = 1 To ValueTable1C77.ColumnsCount() Do    
	//		//ColumnName = = ValueTable1C77.ПолучитьПараметрыКолонки(ColumnCounter);
	//		CellValue = ValueTable1C77.GetValue(RowsCounter, ColumnCounter); 
	//		ВсяСтрока = ВсяСтрока + ", " + CellValue;
	//	EndDo;
	//	Message(ВсяСтрока);
	//	
	//EndDo
	
//#Region Заполнение_ТЗ
	
	If ValueTable <> Undefined Then
		
		If (ThisObject["CastKeyToUpperCase" + BaseID] 
		Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] 
		Or ThisObject["CastKeyToString" + BaseID]
		Or ThisObject["ExecuteArbitraryKeyCode1" + BaseID])
		Or NumberColumnsInKey > 1 And 
		(ThisObject["CastKey2ToUpperCase" + BaseID] 
		Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] 
		Or ThisObject["CastKey2ToString" + BaseID]
		Or ThisObject["ExecuteArbitraryKeyCode2" + BaseID])
		Or NumberColumnsInKey > 2 And 
		(ThisObject["CastKey3ToUpperCase" + BaseID] 
		Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] 
		Or ThisObject["CastKey3ToString" + BaseID]
		Or ThisObject["ExecuteArbitraryKeyCode3" + BaseID])Then
		
			FirstColumnName = ValueTable.Columns.Get(0).Name;
			
			If NumberColumnsInKey > 1 Then
				SecondColumnName = ValueTable.Columns.Get(1).Name;
			Else
				SecondColumnName = "";
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				ThirdColumnName = ValueTable.Columns.Get(2).Name;
			Else
				ThirdColumnName = "";
			EndIf;
			
			ColumnNameKey1 		= ValueTable.Columns.Get(0).Name;
			If NumberColumnsInKey > 1 Then
				ColumnNameKey2 = ValueTable.Columns.Get(1).Name;
			Else
				ColumnNameKey2 = "";
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				ColumnNameKey3 = ValueTable.Columns.Get(2).Name;
			Else
				ColumnNameKey3 = "";
			EndIf;
			
			If ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
				
				ColumnNameKey1 = "Key1" + Format(CurrentDate(), "DF=ddMMyyyyHHmmss");
				ValueTable.Columns.Insert(0, ColumnNameKey1);//, DescriptionString);

			EndIf;
		
			If NumberColumnsInKey > 1 Then
			
				If ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ColumnNameKey2 = "Key2" + Format(CurrentDate(), "DF=ddMMyyyyHHmmss");
					ValueTable.Columns.Insert(1, ColumnNameKey2);
				EndIf;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ColumnNameKey3 = "Key3" + Format(CurrentDate(), "DF=ddMMyyyyHHmmss");
					ValueTable.Columns.Insert(2, ColumnNameKey3);
				EndIf;
			EndIf;
			       						
			RowsCounter = 0;			
			For Each RowValueTable In ValueTable Do
				
				RowsCounter = RowsCounter + 1;
				
				Try
					
					If ThisObject["CastKeyToString" + BaseID]
						Or ThisObject["CastKeyToUpperCase" + BaseID]
						Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						RowValueTable[ColumnNameKey1] = TrimAll(String(RowValueTable[FirstColumnName]));
					EndIf;
						
					If ThisObject["CastKeyToUpperCase" + BaseID] Then
						RowValueTable[ColumnNameKey1] = TrimAll(Upper(String(RowValueTable[ColumnNameKey1])));
					EndIf;
					
					If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						RowValueTable[ColumnNameKey1] = TrimAll(StrReplace(StrReplace(String(RowValueTable[ColumnNameKey1]), "{", ""), "}", ""));
					EndIf;
					
				Except
					
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке ключа в строке %1 выборки из базы %2: %3';en = 'Error processing key in row %1 of fetch from base %2: %3'")
						, RowsCounter
						, BaseID
						, ErrorDescription());
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
				If NumberColumnsInKey > 1 Then
						
					Try
						
						If ThisObject["CastKey2ToString" + BaseID]
							Or ThisObject["CastKey2ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey2] = TrimAll(String(RowValueTable[SecondColumnName]));
						EndIf;

						If ThisObject["CastKey2ToUpperCase" + BaseID] Then
							RowValueTable[ColumnNameKey2] = TrimAll(Upper(String(RowValueTable[ColumnNameKey2])));
						EndIf;
						
						If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey2] = TrimAll(StrReplace(StrReplace(String(RowValueTable[ColumnNameKey2]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = "Error при обработке столбца 2 ключа в строке " + RowsCounter + " выборки из базы " + BaseID + ": " + ErrorDescription();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
						
					Try
						
						If ThisObject["CastKey3ToString" + BaseID]
							Or ThisObject["CastKey3ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey3] = TrimAll(String(RowValueTable[ThirdColumnName]));
						EndIf;
						
						If ThisObject["CastKey3ToUpperCase" + BaseID] Then
							RowValueTable[ColumnNameKey3] = TrimAll(Upper(String(RowValueTable[ColumnNameKey3])));
						EndIf;
						
						If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							RowValueTable[ColumnNameKey3] = TrimAll(StrReplace(StrReplace(String(RowValueTable[ColumnNameKey3]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = "Error при обработке столбца 3 ключа в строке " + RowsCounter + " выборки из базы " + BaseID + ": " + ErrorDescription();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
						
	#Region Arbitrary_key_processing_code

				KeyCurrent = RowValueTable[ColumnNameKey1];
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, KeyCurrent
							, BaseID
							, ErrorDescription());						
						Message(ErrorText);
					EndTry;
				EndIf;
				RowValueTable[ColumnNameKey1] = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then
					KeyCurrent = RowValueTable[ColumnNameKey2];
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
							, KeyCurrent
							, BaseID
							, ErrorDescription());							
							Message(ErrorText);
						EndTry;
					EndIf;
					RowValueTable[ColumnNameKey2] = KeyCurrent;
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					KeyCurrent = RowValueTable[ColumnNameKey3];
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
							, KeyCurrent
							, BaseID
							, ErrorDescription());							
							Message(ErrorText);
						EndTry;
					EndIf;
					RowValueTable[ColumnNameKey3] = KeyCurrent;
				EndIf;

	#EndRegion
				
			EndDo;
			
			If ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
			
				ValueTable.Columns.Delete(FirstColumnName);
			
			EndIf;
		
			If NumberColumnsInKey > 1 Then
								
				If ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ValueTable.Columns.Delete(SecondColumnName);
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
								
				If ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ValueTable.Columns.Delete(ThirdColumnName);
					
				EndIf;
				
			EndIf;
			
		EndIf;
	
//#EndRegion
	
		//Indexing
		ColumnsWithKeyRow = ColumnNameKey1;
		If NumberColumnsInKey > 1 Then
			ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ColumnNameKey2;
		EndIf;
		If NumberColumnsInKey > 2 Then
			ColumnsWithKeyRow = ColumnsWithKeyRow + "," + ColumnNameKey3;
		EndIf;

		ValueTable.Индексы.Добавить(ColumnsWithKeyRow);
		
		For AttributesCounter = 1 По ThisObject["SettingsFile" + BaseID].Count() Цикл
			
			AttributeName = Строка(BaseID) + AttributesCounter;
			HeaderAttributeFromSettings = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].HeaderAttributeForUser;
			
			ViewsHeadersAttributes[AttributeName] = ?(IsBlankString(HeaderAttributeFromSettings), "Реквизит " + BaseID + AttributesCounter, AttributeName + ": " + HeaderAttributeFromSettings);
		
		EndDo;
		
	EndIf;
	
	Return ValueTable;
	
EndFunction

Function ExecuteQuerySQLAndGetValueTable(BaseID, ErrorsText = "")
	
	ServerName =  ThisObject["ConnectionToExternalBase" + BaseID + "Server"];
	DSN 	= ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"];                                                                                                           
	UID 	= ThisObject["ConnectionToExternalBase" + BaseID + "Login"];
	PWD 	= ThisObject["ConnectionToExternalBase" + BaseID + "Password"];
	Driver 	= ThisObject["ConnectionToExternalBase" + BaseID + "ДрайверSQL"];
	
	Try              
		ConnectString = "Driver={" + Driver + "};Server=" + ServerName + ";Database=" + DSN + ";Uid=" + UID + ";Pwd=" + PWD;
		Connection = New COMObject("ADODB.Connection");
		Connection.Open(ConnectString); 
	Except
		ErrorText = ErrorDescription();
		MessageText = StrTemplate(Nstr("ru = 'Не удалось подключиться к : %1';en = 'Failed to connect to : %1'"), ErrorText);
		Message(MessageText);
		Return Undefined;
	EndTry;
	
	OffsetNumberAttribute = NumberColumnsInKey - 1;
		
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Key1");
	ColumnsWithKeyRow = "Key1";
	
	If NumberColumnsInKey > 1 Then
		ValueTable.Columns.Add("Key2");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ValueTable.Columns.Add("Key3");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key3";
	EndIf;
	
	ValueTable.Columns.Add("Attribute1");
	ValueTable.Columns.Add("Attribute2");
	ValueTable.Columns.Add("Attribute3");
	ValueTable.Columns.Add("Attribute4");
	ValueTable.Columns.Add("Attribute5");
	
	Try
		
		RecordSet = New COMObject("ADODB.RecordSet"); 
		Command = New COMObject("ADODB.Command");
		Command.ActiveConnection = Connection;
		Command.CommandText = ThisObject["QueryText" + BaseID];
		Command.CommandType = 1;
		
		RecordSet = Command.Execute();
		
		NumberOfcolumnsInValueTable = RecordSet.Fields.Count;
		If NumberColumnsInKey > NumberOfcolumnsInValueTable Then
			
			ErrorText = StrTemplate(Nstr("ru = 'Выборка из источника %1 содержит %2 колонок, проверьте корректность заданного числа столбцов в ключе';en = 'The selection from the source %1 contains %2 columns, check the correctness of the specified number of columns in the key'")
				, BaseID
				, NumberOfcolumnsInValueTable);
			UserMessage = New UserMessage;
			UserMessage.Text = ErrorText;
			UserMessage.Field = "Object.NumberColumnsInKey";
			UserMessage.Message();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			RecordSet.Close();
			Connection.Close();
			
			Return Undefined;
			
		EndIf;
				
		RowsCounter = 0;			
		While RecordSet.EOF = 0 Do
			
			RowsCounter = RowsCounter + 1;
			
			If RowsCounter = 1 Then
				
				For AttributesCounter = 1 To Min(NumberOfcolumnsInValueTable - NumberColumnsInKey, NumberOfRequisites) Do
					
					Если ThisObject["SettingsFile" + BaseID].Count() >= AttributesCounter Тогда
						HeaderAttributeFromSettings = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].HeaderAttributeForUser;
					Иначе
						HeaderAttributeFromSettings = "";
					EndIf;
					
					AttributeName = String(BaseID) + AttributesCounter;					
					ViewsHeadersAttributes[AttributeName] = AttributeName + ": " 
						+ ?(IsBlankString(HeaderAttributeFromSettings), RecordSet.Fields(AttributesCounter + NumberColumnsInKey - 1).Name, HeaderAttributeFromSettings);
					
				EndDo; 
				
			EndIf;
			
			RowValueTable = ValueTable.Add();
			
			Key1 = RecordSet.Fields(0).Value;
			
			If NumberColumnsInKey > 1 Then
				Key2 = RecordSet.Fields(1).Value;
			Else
				Key2 = "";				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				Key3 = RecordSet.Fields(2).Value;
			Else
				Key3 = "";				
			EndIf;
			
			Try
				
				If ThisObject["CastKeyToString" + BaseID] Then
					Key1 = TrimAll(String(Key1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Key1 = TrimAll(Upper(String(Key1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
				EndIf;
				
			Except
				
				ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке ключа в строке %1 выборки из базы %2: %3';en = 'Error processing key in row %1 of fetch from base %2: %3'")
						, RowsCounter
						, BaseID
						, ErrorDescription());
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			EndTry;
			
			If NumberColumnsInKey > 1 Then
				
				Try
				
					If ThisObject["CastKey2ToString" + BaseID] Then
						Key2 = TrimAll(String(Key2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Key2 = TrimAll(Upper(String(Key2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
					EndIf;
				
				Except
					
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке столбца 2 ключа в строке %1 выборки из базы %2: %3';en = 'Error processing column 2 of key in row %1 of fetch from base %2: %3'")
						, RowsCounter
						, BaseID
						, ErrorDescription());					
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				
				Try
				
				If ThisObject["CastKey3ToString" + BaseID] Then
					Key3 = TrimAll(String(Key3));
				EndIf;
			
				If ThisObject["CastKey3ToUpperCase" + BaseID] Then
					Key3 = TrimAll(Upper(String(Key3)));
				EndIf;
				
				If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
				EndIf;
				
				Except
					
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обработке столбца 3 ключа в строке %1 выборки из базы %2: %3';en = 'Error processing column 3 of key in row %1 of fetch from base %2: %3'")
						, RowsCounter
						, BaseID
						, ErrorDescription());					
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
			EndIf;
			          			
#Region Arbitrary_key_processing_code

			KeyCurrent = Key1;
			If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
				Except
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
						, Key1
						, BaseID
						, ErrorDescription());					
					Message(ErrorText);
				EndTry;
			EndIf;
			RowValueTable.Key1 = KeyCurrent;
			
			If NumberColumnsInKey > 1 Then
				KeyCurrent = Key2;				
				If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
						, Key2
						, BaseID
						, ErrorDescription());						
						Message(ErrorText);
					EndTry;
				EndIf;
				RowValueTable.Key2 = KeyCurrent;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				KeyCurrent = Key3;
				If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
						, Key3
						, BaseID
						, ErrorDescription());						
						Message(ErrorText);
					EndTry;
				EndIf;
				RowValueTable.Key3 = KeyCurrent;
			EndIf;
			
#EndRegion 
			
			NumberOfcolumnsInSelection = RecordSet.Fields.Count;
			
			For Counter = 1 To Min(NumberOfRequisites, NumberOfcolumnsInSelection - NumberColumnsInKey) Do
				RowValueTable["Attribute" + Counter] = RecordSet.Fields(Counter + NumberColumnsInKey - 1).Value 
			EndDo;
			
			RecordSet.MoveNext();
			
		EndDo;

		RecordSet.Close();
		Connection.Close();
		
	Except
		
		ErrorText = ErrorDescription();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		ValueTable = Undefined;
		
	EndTry;
	
	//Indexing
	If ValueTable <> Undefined Then
		ValueTable.Indexes.Add(ColumnsWithKeyRow);
	EndIf;
	
	Return ValueTable;
	
EndFunction

Function ReadDataFromFileAndGetValueTable(BaseID, ErrorsText = "")
	
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Key1");
	ColumnsWithKeyRow = "Key1";
	
	If NumberColumnsInKey > 1 Then
		ValueTable.Columns.Add("Key2");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ValueTable.Columns.Add("Key3");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key3";
	EndIf;
	
	ValueTable.Columns.Add("Attribute1");
	ValueTable.Columns.Add("Attribute2");
	ValueTable.Columns.Add("Attribute3");
	ValueTable.Columns.Add("Attribute4");
	ValueTable.Columns.Add("Attribute5");
	
	PathToFile 		= ThisObject["ConnectionToExternalBase"	+ BaseID + "PathToFile"];
	FileFormat 		= ThisObject["ConnectionToExternalBase" + BaseID + "FileFormat"];
	NumberFirstRow 	= ThisObject["NumberFirstRowFile" 		+ BaseID];
	SettingsFile 	= ThisObject["SettingsFile" 			+ BaseID];
	NumberTable		= ThisObject["ConnectionToExternalBase"	+ BaseID + "NumberTableInFile"];
	
	ColumnNumberWithKey = ThisObject["ColumnNumberKeyFromFile" 	+ BaseID];
	ColumnNameWithKey 	= ThisObject["ColumnNameKeyFromFile" 	+ BaseID];	
	If NumberColumnsInKey > 1 Then
		ColumnNumberWithKey2 	= ThisObject["ColumnNumberKey2FromFile" + BaseID];
		ColumnNameWithKey2 		= ThisObject["ColumnNameKey2FromFile" + BaseID];
	EndIf;	
	If NumberColumnsInKey > 2 Then
		ColumnNumberWithKey3 	= ThisObject["ColumnNumberKey3FromFile" + BaseID];
		ColumnNameWithKey3 		= ThisObject["ColumnNameKey3FromFile" + BaseID];
	EndIf;
	
	//File open check
	If FileFormat = "XLS" Then
		
		Try
			Excel = New COMObject("Excel.Application");
			Excel.DisplayAlerts = 0;
			Excel.Visible = False;
			
			Book = Excel.WorkBooks.Open(PathToFile);
			File = Book.WorkSheets(NumberTable);
		Except
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при открытии XLS-файла %1: %2';en = 'Error opening .XLS file %1: %2'")
				, PathToFile
				, ErrorDescription());
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndTry;
		
		xlCellTypeLastCell = 11;
		
		Try
			NumberLastRow = File.Cells.SpecialCells(xlCellTypeLastCell).Row;			
		Except
			MessageText = Nstr("ru = 'Ошибка при определении номера последней строки в файле. Номер последней строки установлен в 1000';en = 'An error occurred while determining the number of the last line in the file. Last row number set to 1000'");			
			NumberLastRow = 1000;
		EndTry;
		
		Try
			NumberLastColumn = File.Cells.SpecialCells(xlCellTypeLastCell).Column;
		Except			
			NumberLastColumn = 1000;
		EndTry;
				
	ElsIf FileFormat = "DOC" Then
		
		Try
			Word = New COMObject("Word.Application");
			Word.DisplayAlerts = 0;
			Word.Visible = False;
			
			Word.Application.Documents.Open(PathToFile);
			Document = Word.ActiveDocument();
			
		Except
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при открытии DOC-файла %1: %2';en = 'Error opening .DOC file %1: %2'")
				, PathToFile
				, ErrorDescription());			
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Word = Undefined;
			Return Undefined;
		EndTry;
		
		Try 
			File = Document.Tables(NumberTable);
		Except			
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при обращении к таблице %1 DOC-файла %2: %3';en = 'Error accessing table %1 of DOC file %2: %3'")
				, NumberTable
				, PathToFile
				, ErrorDescription());
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Document.Close(0);
			Word.Quit();
			Return Undefined;
		EndTry;

		Try
			NumberLastRow = File.Rows.count;
		Except
			Message("Ошибка при определении номера последней строки в файле. Number последней строки установлен в 1000");
			NumberLastRow = 1000;
		EndTry;
		
	ElsIf FileFormat = "CSV" Or FileFormat = "TXT" Then
		
		Try
			File = New TextDocument();
			File.Read(PathToFile);
			NumberLastRow = File.LineCount(); 
		Except
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при открытии %1-файла %2: %3';en = 'Error opening .%1 file %2: %3'")
				, FileFormat
				, PathToFile
				, ErrorDescription());			
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndTry;
		
	ElsIf FileFormat = "DBF" Then 
		
		Try
			FileDBF = New XBase;
			FileDBF.OpenFile(PathToFile,,True);
			NumberLastRow = FileDBF.RecCount();
			FileDBF.First();
		Except
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при открытии DBF-файла %1: %2';en = 'Error opening .DBF file %1: %2'")
				, PathToFile
				, ErrorDescription());
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndTry;

	ElsIf FileFormat = "XML" Then
		
		Try
			XMLReader = New XMLReader;
		    XMLReader.OpenFile(PathToFile);	 
		    DOMBuilder = New DOMBuilder;	 
		    FileXML = DOMBuilder.Read(XMLReader);
		Except
			ErrorText = StrTemplate(Nstr("ru = 'Ошибка при открытии XML-файла %1: %2';en = 'Error opening .XML file %1: %2'")
				, PathToFile
				, ErrorDescription());
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined
		EndTry;
		
	Else
		
		ErrorText = StrTemplate(Nstr("ru = 'Формат файла ''%1'' не предусмотрен';en = 'File format ''%1'' is not supported'")
			, FileFormat);
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		Return Undefined;
		
	EndIf;
	
	//Processing строк
//#Region XML
	
	If FileFormat = "XML" Then
		
		ParentNodeName = ThisObject["ParentNodeNameFile" + BaseID];
		ElementNameWithDataFile = ThisObject["ElementNameWithDataFile" + BaseID];
		
		RootNode = FileXML.DocumentElement;
		If IsBlankString(ParentNodeName) Then
			ParentNode = RootNode
		Else
			ParentNode = FindSlaveNodeXMLFileByName(RootNode, ParentNodeName);
		EndIf;
		
		If ParentNode <> Undefined Then
			
			For Each CurrentItem In ParentNode.ChildNodes Do
				
				If IsBlankString(ElementNameWithDataFile) Or CurrentItem.NodeName = ElementNameWithDataFile Then
					
//#Region XML_MethodStoringDataInXMLFile_In_Attributes
				
					If ThisObject["DataStorageMethodInXMLFile" + BaseID] = "В атрибутах" Then
						
						FillVariablesPWithDefaultValues();
												
						RowReceiver = ValueTable.Add();
						
						Item = CurrentItem.Attributes.GetNamedItem(ColumnNameWithKey);
						If Item = Undefined Then							
							Raise StrTemplate(Nstr("ru = 'Реквизит с именем %1 не найден';en = 'Attribute named %1 not found'"), ColumnNameWithKey);
						EndIf;
						
						Key1 = Item.Value;
						If ThisObject["CastKeyToUpperCase" + BaseID] Then
							Key1 = TrimAll(Upper(String(Key1)));
						EndIf;
						If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
							Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
						EndIf;
						
						If NumberColumnsInKey > 1 Then
						
							Item = CurrentItem.Attributes.GetNamedItem(ColumnNameWithKey2);
							If Item = Undefined Then
								Raise StrTemplate(Nstr("ru = 'Реквизит с именем %1 не найден';en = 'Attribute named %1 not found'"), ColumnNameWithKey2);								
							EndIf;
							
							Key2 = Item.Value;
									
							If ThisObject["CastKey2ToString" + BaseID] Then
								Key2 = TrimAll(String(Key2));
							EndIf;
							
							If ThisObject["CastKey2ToUpperCase" + BaseID] Then
								Key2 = TrimAll(Upper(String(Key2)));
							EndIf;
							
							If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
								Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
							EndIf;
														
						EndIf;
						
						If NumberColumnsInKey > 2 Then
						
							Item = CurrentItem.Attributes.GetNamedItem(ColumnNameWithKey3);
							If Item = Undefined Then
								Raise StrTemplate(Nstr("ru = 'Реквизит с именем %1 не найден';en = 'Attribute named %1 not found'"), ColumnNameWithKey3);								
							EndIf;
							
							Key3 = Item.Value;
									
							If ThisObject["CastKey3ToString" + BaseID] Then
								Key3 = TrimAll(String(Key3));
							EndIf;
							
							If ThisObject["CastKey3ToUpperCase" + BaseID] Then
								Key3 = TrimAll(Upper(String(Key3)));
							EndIf;
							
							If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
								Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
							EndIf;
							
						EndIf;
						
//#Region Arbitrary_key_processing_code

						KeyCurrent = Key1;
						If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
							Try
							    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
							Except
								ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
									, Key1
									, BaseID
									, ErrorDescription());								
								Message(ErrorText);
							EndTry;
						EndIf;
						
						RowReceiver.Key1 = KeyCurrent;
						
						If NumberColumnsInKey > 1 Then
							
							KeyCurrent = Key2;
							If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
								Except
									ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
										, Key2
										, BaseID
										, ErrorDescription());									
									Message(ErrorText);
								EndTry;
							EndIf;
							RowReceiver.Key2 = KeyCurrent;
							
						EndIf;
						
						If NumberColumnsInKey > 2 Then
							
							KeyCurrent = Key3;
							If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
								Except
									ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
										, Key3
										, BaseID
										, ErrorDescription());
									Message(ErrorText);
								EndTry;
							EndIf;
							RowReceiver.Key3 = KeyCurrent;
							
						EndIf;
						
//#EndRegion  

						FillVariablesPWithDefaultValues();
						For Each RowSettingsFile In SettingsFile Do
							
							//Not the column name is set (for example, if the attribute is filled programmatically)
							If IsBlankString(RowSettingsFile.ColumnName) Then
								Continue;
							EndIf;
							
							AttributeName = "Attribute" + RowSettingsFile.LineNumber;
							Item = CurrentItem.Attributes.GetNamedItem(RowSettingsFile.ColumnName);
							If Item = Undefined Then
								Raise StrTemplate(Nstr("ru = 'Реквизит с именем %1 не найден';en = 'Attribute named %1 not found'"), RowSettingsFile.ColumnName);								
							EndIf;
							RowReceiver[AttributeName] = Item.Value;
							
							//FillType of variables to be used in arbitrary code
							РВрем = RowReceiver[AttributeName];
							If RowSettingsFile.LineNumber = 1 Then
								Р1 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 2 Then
								Р2 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 3 Then
								Р3 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 4 Then
								Р4 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 5 Then
								Р5 = РВрем;
							EndIf;

						EndDo;
						
//#EndRegion

//#Region XML_MethodStoringDataInXMLFile_In_Elements
						
					ElsIf ThisObject["DataStorageMethodInXMLFile" + BaseID] = "В элементах" Then
						
						FillVariablesPWithDefaultValues();
						
						RowReceiver = ValueTable.Add();
						
						For Each ChildElement In CurrentItem.ChildNodes Do
							
							If ChildElement.NodeName = ColumnNameWithKey Then
								
								Key1 = ChildElement.TextContent;
								If ThisObject["CastKeyToUpperCase" + BaseID] Then
									Key1 = TrimAll(Upper(String(Key1)));
								EndIf;
								If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
									Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
								EndIf;
								
								RowReceiver.Key1 = Key1;
								
							EndIf;
								
							If ChildElement.NodeName = ColumnNameWithKey2 And NumberColumnsInKey > 1 Then
								
								Key2 = ChildElement.TextContent;
								If ThisObject["CastKey2ToUpperCase" + BaseID] Then
									Key2 = TrimAll(Upper(String(Key2)));
								EndIf;
								If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
									Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
								EndIf;
								
								RowReceiver.Key2 = Key2;
			                    						
							EndIf;                
							
							If ChildElement.NodeName = ColumnNameWithKey3 And NumberColumnsInKey > 2 Then
								
								Key3 = ChildElement.TextContent;
								If ThisObject["CastKey3ToUpperCase" + BaseID] Then
									Key3 = TrimAll(Upper(String(Key2)));
								EndIf;
								If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
									Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
								EndIf;
								
								RowReceiver.Key3 = Key3;
			                    						
							EndIf;
							
							For Each RowSettingsFile In SettingsFile Do
							
								//Not the column name is set (for example, if the attribute is filled programmatically)
								If IsBlankString(RowSettingsFile.ColumnName) Then
									Continue;
								EndIf;
								
								TagName = RowSettingsFile.ColumnName;
								AttributeName = "Attribute" + RowSettingsFile.LineNumber;
								If ChildElement.NodeName = TagName Then
									
									RowReceiver[AttributeName] = ChildElement.TextContent;;
									
								EndIf;
																
							EndDo;
							
						EndDo;
						
//#Region Arbitrary_key_processing_code
						KeyCurrent = RowReceiver.Key1;
						If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
							Try
							    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
							Except
								ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
									, Key1
									, BaseID
									, ErrorDescription());								
								Message(ErrorText);
							EndTry;
						EndIf;
						RowReceiver.Key1 = KeyCurrent;
						
						If NumberColumnsInKey > 1 Then
							
							KeyCurrent = RowReceiver.Key2;
							If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
								Except
									ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
										, Key2
										, BaseID
										, ErrorDescription());
									Message(ErrorText);
								EndTry;
							EndIf;
							RowReceiver.Key2 = KeyCurrent;
							
						EndIf;
						
						If NumberColumnsInKey > 2 Then
							KeyCurrent = RowReceiver.Key3;
							If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
								Except
									ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
										, Key3
										, BaseID
										, ErrorDescription());
									Message(ErrorText);
								EndTry;
							EndIf;
							RowReceiver.Key3 = KeyCurrent;
						EndIf;
//#EndRegion 

						FillVariablesPWithDefaultValues();
						For Each RowSettingsFile In SettingsFile Do
							//Not the column name is set (for example, if the attribute is filled programmatically)
							If IsBlankString(RowSettingsFile.ColumnName) Then
								Continue;
							EndIf;
							
							AttributeName = "Attribute" + RowSettingsFile.LineNumber;
							
							РВрем = RowReceiver[AttributeName];
							If RowSettingsFile.LineNumber = 1 Then
								Р1 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 2 Then
								Р2 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 3 Then
								Р3 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 4 Then
								Р4 = РВрем;
							ElsIf RowSettingsFile.LineNumber = 5 Then
								Р5 = РВрем;
							EndIf;
							
						EndDo;
																		
					Else 
						Raise StrTemplate(Nstr("ru = 'Не задан способ хранения данных в XML-файле базы %1';en = 'No way to store data in database XML file %1'")
							, BaseID);				
					EndIf;
					
					For Each RowSettingsFile In SettingsFile Do
				
						AttributeName = "Attribute" + RowSettingsFile.LineNumber;
						РТек = RowReceiver[AttributeName];

						Try
							Execute RowSettingsFile.ArbitraryCode;
						Except
							ErrorText = ErrorDescription();
							ErrorMessage = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (реквизит %1):%2';en = 'Error executing arbitrary code (attribute %1):%2'")
								, RowSettingsFile.LineNumber
								, ErrorText);	
							Message(ErrorMessage);
						EndTry;
						
						If ThisObject["CollapseTable" + BaseID] Then
							Try
								Execute CodeCastingAttributeToTypeNumber;
							Except
								РТек = 0;
							EndTry;
						EndIf;
						
						RowReceiver[AttributeName] = РТек;

					EndDo;
					
//#EndRegion

				EndIf;
				
			EndDo; 
			
		EndIf;
		
//#EndRegion 

	Else
	
		For NumberCurrentRow = NumberFirstRow To NumberLastRow Do
			
			FillVariablesPWithDefaultValues();
			
			RowReceiver = ValueTable.Add();
			
//#Region XLS

			If FileFormat = "XLS" Then
				
				NumberOfColumnsInFileLessThanRequired = False;
				
				If ColumnNumberWithKey > NumberLastColumn Then					
					ErrorText = StrTemplate(Nstr("ru = 'Файл %1 содержит %2 колонок, проверьте настройки столбцов ключа';en = 'File %1 contains %2 columns, check key column settings'")
						, BaseID
						, NumberLastColumn);					
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKeyFromFile " + BaseID;
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					NumberOfColumnsInFileLessThanRequired = True;
				EndIf;
				
				If NumberColumnsInKey > 1 And ColumnNumberWithKey2 > NumberLastColumn Then					
					ErrorText = StrTemplate(Nstr("ru = 'Файл %1 содержит %2 колонок, проверьте настройки столбца 2 ключа';en = 'File %1 contains %2 columns, check column 2 key settings'")
						, BaseID
						, NumberLastColumn);					
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKey2FromFile " + BaseID;
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					NumberOfColumnsInFileLessThanRequired = True;
				EndIf;
				
				If NumberColumnsInKey > 2 And ColumnNumberWithKey3 > NumberLastColumn Then					
					ErrorText = StrTemplate(Nstr("ru = 'Файл %1 содержит %2 колонок, проверьте настройки столбца 3 ключа';en = 'File %1 contains %2 columns, check column 3 key settings'")
						, BaseID
						, NumberLastColumn);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKey3FromFile " + BaseID;
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					NumberOfColumnsInFileLessThanRequired = True;
				EndIf;
				
				If NumberOfColumnsInFileLessThanRequired Then
					
					Book.Close(0);
					Excel.Quit();
					Return ValueTable;
					
				EndIf;
				
				Key1 = TrimAll(File.Cells(NumberCurrentRow, ColumnNumberWithKey).Value);
							
				If ThisObject["CastKeyToString" + BaseID] Then
					Key1 = TrimAll(String(Key1));
				EndIf;
				
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Key1 = TrimAll(Upper(String(Key1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
				EndIf;
								
				If NumberColumnsInKey > 1 Then			
					
					Key2 = TrimAll(File.Cells(NumberCurrentRow, ColumnNumberWithKey2).Value);
							
					If ThisObject["CastKey2ToString" + BaseID] Then
						Key2 = TrimAll(String(Key2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Key2 = TrimAll(Upper(String(Key2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
					EndIf;
					     										
				EndIf;
				
				If NumberColumnsInKey > 2 Then
										
					Key3 = TrimAll(File.Cells(NumberCurrentRow, ColumnNumberWithKey3).Value);
							
					If ThisObject["CastKey3ToString" + BaseID] Then
						Key3 = TrimAll(String(Key3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Key3 = TrimAll(Upper(String(Key3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
				
				
//#Region Arbitrary_key_processing_code

				KeyCurrent = Key1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, Key1
							, BaseID
							, ErrorDescription());								
						Message(ErrorText);
					EndTry;
				EndIf;
				RowReceiver.Key = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then
					
					KeyCurrent = Key2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
								, Key2
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key2 = KeyCurrent;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					KeyCurrent = Key3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
								, Key3
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key3 = KeyCurrent;
					
				EndIf;
				
//#EndRegion

				FillVariablesPWithDefaultValues();
				For Each RowSettingsFile In SettingsFile Do
					//Not set the column number (for example, if the attribute is filled programmatically)
					If RowSettingsFile.NumberColumn = 0 Then
						Continue;
					EndIf;
					AttributeName = "Attribute" + RowSettingsFile.LineNumber;
					
					If RowSettingsFile.NumberColumn > NumberLastColumn Then						
						ErrorText = StrTemplate(Nstr("ru = 'Файл %1 содержит %2 колонок, проверьте настройки колонок реквизитов';en = 'File %1 contains %2 columns, check attribute column settings'")
							, BaseID
							, NumberLastColumn);						
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.SettingsFile" + BaseID;
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						Return ValueTable;
					EndIf;
					
					RowReceiver[AttributeName] = TrimAll(File.Cells(NumberCurrentRow, RowSettingsFile.NumberColumn).Value);
					
					//FillType variables to be used in arbitrary code
					РВрем = RowReceiver[AttributeName];
					If RowSettingsFile.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;
							
//#EndRegion 	

			
//#Region DOC

			ElsIf FileFormat = "DOC" Then

				//In the WORD document, characters enter that 1C cannot display in the Value table on the form and gives an error Text XML contains an invalid character
	        	ReplaceableSymbols = New Array;
				ReplaceableSymbols.Add(Char(7));	//¶
				ReplaceableSymbols.Add(Char(13));	//black circle
								
				Key1 = TrimAll(File.Cell(NumberCurrentRow, ColumnNumberWithKey).Range.Text);
				For Each ReplaceableSymbol In ReplaceableSymbols Do 
					Key1 = StrReplace(Key1, ReplaceableSymbol, "");
				EndDo;
							
				If ThisObject["CastKeyToString" + BaseID] Then
					Key1 = TrimAll(String(Key1));
				EndIf;
				
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Key1 = TrimAll(Upper(String(Key1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
				EndIf;
								
				If NumberColumnsInKey > 1 Then
					
					Key2 = TrimAll(File.Cell(NumberCurrentRow, ColumnNumberWithKey2).Range.Text);
					For Each ReplaceableSymbol In ReplaceableSymbols Do 
						Key2 = StrReplace(Key2, ReplaceableSymbol, "");
					EndDo;
					
					If ThisObject["CastKey2ToString" + BaseID] Then
						Key2 = TrimAll(String(Key2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Key2 = TrimAll(Upper(String(Key2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
					EndIf;
					     										
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					Key3 = TrimAll(File.Cell(NumberCurrentRow, ColumnNumberWithKey3).Range.Text);
					For Each ReplaceableSymbol In ReplaceableSymbols Do 
						Key3 = StrReplace(Key3, ReplaceableSymbol, "");
					EndDo;

							
					If ThisObject["CastKey3ToString" + BaseID] Then
						Key3 = TrimAll(String(Key3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Key3 = TrimAll(Upper(String(Key3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
				
				
//#Region Arbitrary_key_processing_code

				KeyCurrent = Key1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, Key1
							, BaseID
							, ErrorDescription());								
						Message(ErrorText);
					EndTry;
				EndIf;
				RowReceiver.Key = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then
					
					KeyCurrent = Key2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
								, Key2
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key2 = KeyCurrent;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					KeyCurrent = Key3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
								, Key3
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key3 = KeyCurrent;
					
				EndIf;
				
//#EndRegion

				FillVariablesPWithDefaultValues();
				For Each RowSettingsFile In SettingsFile Do
					//Not set the column number (for example, if the attribute is filled programmatically)
					If RowSettingsFile.NumberColumn = 0 Then
						Continue;
					EndIf;
					AttributeName = "Attribute" + RowSettingsFile.LineNumber;
					ValueAttribute = TrimAll(File.Cell(NumberCurrentRow, RowSettingsFile.NumberColumn).Range.Text);
					For Each ReplaceableSymbol In ReplaceableSymbols Do 
						ValueAttribute = StrReplace(ValueAttribute, ReplaceableSymbol, "");
					EndDo;
					RowReceiver[AttributeName] = ValueAttribute;
					
					//FillType variables to be used in arbitrary code
					РВрем = RowReceiver[AttributeName];
					If RowSettingsFile.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;
							
//#EndRegion 	


//#Region CSV_TXT

			ElsIf FileFormat = "CSV" Or FileFormat = "TXT" Then

				RowTextFromFile = File.GetLine(NumberCurrentRow);
						
				If FileFormat = "CSV" Then
					ColumnSeparatorCharacter = ";";
				Else
					ColumnSeparatorCharacter = "	";
				EndIf;	
				
				SeparatorCharacter = Chars.LF;
				
				RowMultilineText = StrReplace(RowTextFromFile, ColumnSeparatorCharacter, SeparatorCharacter);
				
				Key1 = StrGetLine(RowMultilineText,ColumnNumberWithKey);
				
				If ThisObject["CastKeyToString" + BaseID] Then
					Key1 = TrimAll(String(Key1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Key1 = TrimAll(Upper(String(Key1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
				EndIf;
								
				If NumberColumnsInKey > 1 Then
					
					Key2 = StrGetLine(RowMultilineText, ColumnNumberWithKey2);
				
					If ThisObject["CastKeyToString" + BaseID] Then
						Key2 = TrimAll(String(Key2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Key2 = TrimAll(Upper(String(Key2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
					EndIf;
															
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					Key3 = StrGetLine(RowMultilineText, ColumnNumberWithKey3);
				
					If ThisObject["CastKeyToString" + BaseID] Then
						Key3 = TrimAll(String(Key3));
					EndIf;
				
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Key3 = TrimAll(Upper(String(Key3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
//#Region Arbitrary_key_processing_code

				KeyCurrent = Key1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, Key1
							, BaseID
							, ErrorDescription());								
						Message(ErrorText);
					EndTry;
				EndIf;
				RowReceiver.Key1 = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then
					
					KeyCurrent = Key2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
								, Key2
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key2 = KeyCurrent;
					
				EndIf;

				If NumberColumnsInKey > 2 Then
					
					KeyCurrent = Key3;
				 	If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
								, Key3
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key3 = KeyCurrent;
					
				EndIf;
				
//#EndRegion 

				FillVariablesPWithDefaultValues();
				For Each RowSettingsFile In SettingsFile Do
					//Not set the column number (for example, if the attribute is filled programmatically)
					If RowSettingsFile.NumberColumn = 0 Then
						Continue;
					EndIf;
					AttributeName = "Attribute" + RowSettingsFile.LineNumber;
					RowReceiver[AttributeName] = StrGetLine(RowMultilineText,RowSettingsFile.NumberColumn);
					
					//FillType variables to be used in arbitrary code
					РВрем = RowReceiver[AttributeName];
					If RowSettingsFile.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;

//#EndRegion 	


//#Region DBF

			ElsIf FileFormat = "DBF" Then
				
				//Just in case, although this should not be
				If FileDBF.EOF() Then
					Continue;
				EndIf;
				
				Key1 = FileDBF[FileDBF.Fields[ColumnNumberWithKey - 1].Name];
				
				If ThisObject["CastKeyToString" + BaseID] Then
					Key1 = TrimAll(String(Key1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Key1 = TrimAll(Upper(String(Key1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
				EndIf;
				
				If NumberColumnsInKey > 1 Then
					
					Key2 = FileDBF[FileDBF.Fields[ColumnNumberWithKey2 - 1].Name];
				
					If ThisObject["CastKey2ToString" + BaseID] Then
						Key2 = TrimAll(String(Key2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Key2 = TrimAll(Upper(String(Key2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					Key3 = FileDBF[FileDBF.Fields[ColumnNumberWithKey3 - 1].Name];
				
					If ThisObject["CastKey3ToString" + BaseID] Then
						Key3 = TrimAll(String(Key3));
					EndIf;
				
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Key3 = TrimAll(Upper(String(Key3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
//#Region Arbitrary_key_processing_code

				KeyCurrent = Key1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, Key1
							, BaseID
							, ErrorDescription());								
						Message(ErrorText);
					EndTry;
				EndIf;
				RowReceiver.Key1 = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then

					KeyCurrent = Key2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
								, Key2
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key2 = KeyCurrent;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					KeyCurrent = Key3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
								, Key3
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key3 = KeyCurrent;
					
				EndIf;
				
//#EndRegion  

				FillVariablesPWithDefaultValues();
				For Each RowSettingsFile In SettingsFile Do
					//Not set the column number (for example, if the attribute is filled programmatically)
					If RowSettingsFile.NumberColumn = 0 Then
						Continue;
					EndIf;
					AttributeName = "Attribute" + RowSettingsFile.LineNumber;
					RowReceiver[AttributeName] = FileDBF[FileDBF.поля[RowSettingsFile.NumberColumn - 1].Name];
					
					//FillType variables to be used in arbitrary code
					РВрем = RowReceiver[AttributeName];
					If RowSettingsFile.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;
					
				EndDo;	
				
				FileDBF.Next();
							
			EndIf;

//#EndRegion


//#Region Arbitrary_code_of_filling_details
			
			For Each RowSettingsFile In SettingsFile Do
				
				AttributeName = "Attribute" + RowSettingsFile.LineNumber;
				РТек = RowReceiver[AttributeName];

				Try
					Execute RowSettingsFile.ArbitraryCode;
				Except
					ErrorText = ErrorDescription();
					ErrorMessage = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (реквизит %1):%2';en = 'Error executing arbitrary code (attribute %1):%2'")
						, RowSettingsFile.LineNumber
						, ErrorText);
					Message(ErrorMessage);
				EndTry;
				
				If ThisObject["CollapseTable" + BaseID] Then
					Try
						Execute CodeCastingAttributeToTypeNumber;
					Except
						РТек = 0;
					EndTry;
				EndIf;
				
				RowReceiver[AttributeName] = РТек;
								
			EndDo;
			
//#EndRegion 

		EndDo;

	EndIf;
	
	If FileFormat = "XLS" Then
		Book.Close(0);
		Excel.Quit();
	ElsIf FileFormat = "DOC" Then
		Document.Close(0);
		Word.Quit();
	ElsIf FileFormat = "DBF" Then
		FileDBF.CloseFile();
	ElsIf FileFormat = "XML" Then
		XMLReader.Close();
	EndIf;
	
	If ValueTable <> Undefined Then
		
		//Indexing
		ValueTable.Indexes.Add(ColumnsWithKeyRow);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + BaseID].Count() Do
			
			AttributeName = String(BaseID) + AttributesCounter;
			HeaderAttributeFromSettings = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].HeaderAttributeForUser;
			
			ViewsHeadersAttributes[AttributeName] = ?(IsBlankString(HeaderAttributeFromSettings), "Attribute " + BaseID + AttributesCounter, AttributeName + ": " + HeaderAttributeFromSettings);
		
		EndDo;
		
	EndIf;
	
	Return ValueTable;
	
EndFunction

Function ReadDataFromJSONAndGetValueTable(BaseID, ErrorsText = "")
	
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Key");
	ColumnsWithKeyRow = "Key";
	
	If NumberColumnsInKey > 1 Then
		ValueTable.Columns.Add("Key2");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ValueTable.Columns.Add("Key3");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key3";
	EndIf;
	
	ValueTable.Columns.Add("Attribute1");
	ValueTable.Columns.Add("Attribute2");
	ValueTable.Columns.Add("Attribute3");
	ValueTable.Columns.Add("Attribute4");
	ValueTable.Columns.Add("Attribute5");
	
	//PathToFile 			= ThisObject["ConnectionToExternalBase"		+ BaseID + "PathToFile"];
	//FileFormat 		= ThisObject["ConnectionToExternalBase" 		+ BaseID + "FileFormat"];
	//NumberFirstRow 	= ThisObject["NumberFirstRowFile" 		+ BaseID];
	SettingsFile 		= ThisObject["SettingsFile" 				+ BaseID];
	//NumberTable		= ThisObject["ConnectionToExternalBase"		+ BaseID + "NumberTableInFile"];
	ElementNameWithDataFile = ThisObject["ElementNameWithDataFile" + BaseID];
	
	ColumnNumberWithKey = ThisObject["ColumnNumberKeyFromFile" 	+ BaseID];
	ColumnNameWithKey 	= ThisObject["ColumnNameKeyFromFile" 	+ BaseID];	
	If NumberColumnsInKey > 1 Then
		ColumnNumberWithKey2 	= ThisObject["ColumnNumberKey2FromFile" + BaseID];
		ColumnNameWithKey2 		= ThisObject["ColumnNameKey2FromFile" + BaseID];
	EndIf;	
	If NumberColumnsInKey > 2 Then
		ColumnNumberWithKey3 	= ThisObject["ColumnNumberKey3FromFile" + BaseID];
		ColumnNameWithKey3 		= ThisObject["ColumnNameKey3FromFile" + BaseID];
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(ThisObject["QueryText" + BaseID]);
	ДанныеJSON = ReadJSON(JSONReader);
	JSONReader.Close();
	
	ЭлементНайден = False;
	For Each CurrentData In ДанныеJSON Do
		
		//Array with data already found in previous iteration
		If ЭлементНайден Then 
			Break;
		EndIf;
		
		If TrimAll(Upper(CurrentData.Key)) = TrimAll(Upper(ElementNameWithDataFile)) And
			TypeOf(CurrentData.Value) = Type("Array") Then
			
			ЭлементНайден = True;
			
			For каждого CurrentValueJSON In CurrentData.Value Do
			
				FillVariablesPWithDefaultValues();
										
				RowReceiver = ValueTable.Add();
				
				Try				
					If Not CurrentValueJSON.Property(ColumnNameWithKey) Then
						RaiseMessage = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
							, ColumnNameWithKey);
						Raise RaiseMessage;
					EndIf;
				Except
					ErrorText = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
						, ColumnNameWithKey);
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					Return Undefined;
				EndTry; 
				
				Key1 = CurrentValueJSON[ColumnNameWithKey];
				
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Key1 = TrimAll(Upper(String(Key1)));
				EndIf;
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
				EndIf;
				
				If NumberColumnsInKey > 1 Then
				
					Try				
						If Not CurrentValueJSON.Property(ColumnNameWithKey2) Then
							RaiseMessage = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
								, ColumnNameWithKey2);
							Raise RaiseMessage;							
						EndIf;
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
							, ColumnNameWithKey2);
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						Return Undefined;
					EndTry; 
					
					Key2 = CurrentValueJSON[ColumnNameWithKey2];
							
					If ThisObject["CastKey2ToString" + BaseID] Then
						Key2 = TrimAll(String(Key2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Key2 = TrimAll(Upper(String(Key2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
					EndIf;
												
				EndIf;
				
				If NumberColumnsInKey > 2 Then
				
					Try				
						If Not CurrentValueJSON.Property(ColumnNameWithKey3) Then
							RaiseMessage = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
								, ColumnNameWithKey3);
							Raise RaiseMessage;
						EndIf;
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
							, ColumnNameWithKey3);
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						Return Undefined;
					EndTry; 
					
					Key3 = CurrentValueJSON[ColumnNameWithKey3];
							
					If ThisObject["CastKey3ToString" + BaseID] Then
						Key3 = TrimAll(String(Key3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Key3 = TrimAll(Upper(String(Key3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
					
#Region Arbitrary_key_processing_code

				KeyCurrent = Key1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
							, Key1
							, BaseID
							, ErrorDescription());							
						Message(ErrorText);
					EndTry;
				EndIf;
				
				RowReceiver.Key1 = KeyCurrent;
				
				If NumberColumnsInKey > 1 Then
					
					KeyCurrent = Key2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
								, Key2
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key2 = KeyCurrent;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					KeyCurrent = Key3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
								, Key3
								, BaseID
								, ErrorDescription());
							Message(ErrorText);
						EndTry;
					EndIf;
					RowReceiver.Key3 = KeyCurrent;
					
				EndIf;
				
#EndRegion  

				FillVariablesPWithDefaultValues();
				For Each RowSettingsFile In SettingsFile Do
					
					//Not set the column number (for example, if the attribute is filled programmatically)
					If IsBlankString(RowSettingsFile.ColumnName) Then
						Continue;
					EndIf;
					
					AttributeName = "Attribute" + RowSettingsFile.LineNumber;
					Try				
						If Not CurrentValueJSON.Property(RowSettingsFile.ColumnName) Then
							RaiseMessage = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
								, RowSettingsFile.ColumnName);
							Raise RaiseMessage;							
						EndIf;
					Except
						ErrorText = StrTemplate(Nstr("ru = 'Реквизит JSON с именем %1 не найден';en = 'JSON attribute named %1 not found'")
							, RowSettingsFile.ColumnName);								
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						Return Undefined;
					EndTry; 
					
					RowReceiver[AttributeName] = CurrentValueJSON[RowSettingsFile.ColumnName];
										
					//FillType variables to be used in arbitrary code
					РВрем = RowReceiver[AttributeName];
					If RowSettingsFile.LineNumber = 1 Then
						Р1 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 2 Then
						Р2 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 3 Then
						Р3 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 4 Then
						Р4 = РВрем;
					ElsIf RowSettingsFile.LineNumber = 5 Then
						Р5 = РВрем;
					EndIf;

				EndDo;
		
		
#Region Arbitrary_code_of_filling_details
		
				For Each RowSettingsFile In SettingsFile Do
					
					AttributeName = "Attribute" + RowSettingsFile.LineNumber;
					РТек = RowReceiver[AttributeName];

					Try
						Execute RowSettingsFile.ArbitraryCode;
					Except
						ErrorText = ErrorDescription();
						ErrorMessage = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (реквизит %1):%2';en = 'Error executing arbitrary code (attribute %1):%2'")
							, RowSettingsFile.LineNumber
							, ErrorText);
						Message(ErrorMessage);
					EndTry;
					
					If ThisObject["CollapseTable" + BaseID] Then
						Try
							Execute CodeCastingAttributeToTypeNumber;
						Except
							РТек = 0;
						EndTry;
					EndIf;
				
					RowReceiver[AttributeName] = РТек;
				
				EndDo;
													
			EndDo;
		
		EndIf;
	
#EndRegion 

	EndDo;
		
	If ValueTable <> Undefined Then
		
		//Indexing
		ValueTable.Indexes.Add(ColumnsWithKeyRow);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + BaseID].Count() Do
			
			AttributeName = String(BaseID) + AttributesCounter;
			HeaderAttributeFromSettings = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].HeaderAttributeForUser;
			
			ViewsHeadersAttributes[AttributeName] = ?(IsBlankString(HeaderAttributeFromSettings), "Attribute " + BaseID + AttributesCounter, AttributeName + ": " + HeaderAttributeFromSettings);
		
		EndDo;
		
	EndIf;
	
	Return ValueTable;
	
EndFunction

Function GetDataFromSpreadsheetDocument(BaseID, ErrorsText = "")
	
	ValueTable = New ValueTable;
	ValueTable.Columns.Add("Key");
	ColumnsWithKeyRow = "Key";
	
	If NumberColumnsInKey > 1 Then
		ValueTable.Columns.Add("Key2");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ValueTable.Columns.Add("Key3");
		ColumnsWithKeyRow = ColumnsWithKeyRow + ",Key3";
	EndIf;
	
	ValueTable.Columns.Add("Attribute1");
	ValueTable.Columns.Add("Attribute2");
	ValueTable.Columns.Add("Attribute3");
	ValueTable.Columns.Add("Attribute4");
	ValueTable.Columns.Add("Attribute5");
	
	NumberFirstRow 	= ThisObject["NumberFirstRowFile" + BaseID];
	SettingsFile 		= ThisObject["SettingsFile" + BaseID];
	
	ColumnNumberWithKey = ThisObject["ColumnNumberKeyFromFile" + BaseID];
	If NumberColumnsInKey > 1 Then
		ColumnNumberWithKey2 = ThisObject["ColumnNumberKey2FromFile" + BaseID];
	EndIf;
	If NumberColumnsInKey > 2 Then
		ColumnNumberWithKey3 = ThisObject["ColumnNumberKey3FromFile" + BaseID];
	EndIf;
	
	NumberCurrentRow = NumberFirstRow;	
	CurrentNumberRowsWithEmptyKeys = 0;
	While True Do
		
		Key1 = ThisObject["Table" + BaseID].Region(NumberCurrentRow, ColumnNumberWithKey, NumberCurrentRow, ColumnNumberWithKey).Text;
								
		If ThisObject["CastKeyToString" + BaseID] Then
			Key1 = TrimAll(String(Key1));
		EndIf;
		
		If ThisObject["CastKeyToUpperCase" + BaseID] Then
			Key1 = TrimAll(Upper(String(Key1)));
		EndIf;
		
		If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
			Key1 = TrimAll(StrReplace(StrReplace(String(Key1), "{", ""), "}", ""));
		EndIf;
						
		If NumberColumnsInKey > 1 Then
			
			Key2 = ThisObject["Table" + BaseID].Region(NumberCurrentRow, ColumnNumberWithKey2, NumberCurrentRow, ColumnNumberWithKey2).Text;
					
			If ThisObject["CastKey2ToString" + BaseID] Then
				Key2 = TrimAll(String(Key2));
			EndIf;
			
			If ThisObject["CastKey2ToUpperCase" + BaseID] Then
				Key2 = TrimAll(Upper(String(Key2)));
			EndIf;
			
			If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
				Key2 = TrimAll(StrReplace(StrReplace(String(Key2), "{", ""), "}", ""));
			EndIf;
						
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			Key3 = ThisObject["Table" + BaseID].Region(NumberCurrentRow, ColumnNumberWithKey3, NumberCurrentRow, ColumnNumberWithKey3).Text;
					
			If ThisObject["CastKey3ToString" + BaseID] Then
				Key3 = TrimAll(String(Key3));
			EndIf;
			
			If ThisObject["CastKey3ToUpperCase" + BaseID] Then
				Key3 = TrimAll(Upper(String(Key3)));
			EndIf;
			
			If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
				Key3 = TrimAll(StrReplace(StrReplace(String(Key3), "{", ""), "}", ""));
			EndIf;
						
		EndIf;
						
		If Not ValueIsFilled(Key1) Then
			If NumberColumnsInKey > 1 Then
				If Not ValueIsFilled(Key2) Then
					If NumberColumnsInKey > 2 Then
						If Not ValueIsFilled(Key3) Then
							CurrentNumberRowsWithEmptyKeys = CurrentNumberRowsWithEmptyKeys + 1;
						EndIf;
					Else
						CurrentNumberRowsWithEmptyKeys = CurrentNumberRowsWithEmptyKeys + 1;
					EndIf;
				EndIf;
			Else
				CurrentNumberRowsWithEmptyKeys = CurrentNumberRowsWithEmptyKeys + 1;
			EndIf;
		Else
			CurrentNumberRowsWithEmptyKeys = 0;
		EndIf;
		
		If CurrentNumberRowsWithEmptyKeys = NumberOfRowsWithEmptyKeysToBreakReading Then
			Break;
		EndIf;
		
		FillVariablesPWithDefaultValues();
		
		RowReceiver = ValueTable.Add();
		
#Region Arbitrary_key_processing_code
	
		KeyCurrent = Key1;
		If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
			Try
			    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
			Except
				ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 1: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 1: ""%1"") on source %2: %3'") 
					, Key1
					, BaseID
					, ErrorDescription()); 				
				Message(ErrorText);
			EndTry;
		EndIf;
		RowReceiver.Key1 = KeyCurrent;
		
		If NumberColumnsInKey > 1 Then
			
			KeyCurrent = Key2;
			If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
				Except
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 2: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 2: ""%1"") on source %2: %3'") 
						, Key2
						, BaseID
						, ErrorDescription());
					Message(ErrorText);
				EndTry;
			EndIf;
			RowReceiver.Key2 = KeyCurrent;
			
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			KeyCurrent = Key3;
			If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
				Except
					ErrorText = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (ключ 3: ""%1"") источника %2: %3';en = 'Arbitrary code execution error (key 3: ""%1"") on source %2: %3'") 
						, Key3
						, BaseID
						, ErrorDescription());
					Message(ErrorText);
				EndTry;
			EndIf;
			RowReceiver.Key3 = KeyCurrent;
			
		EndIf;
		
#EndRegion 
		
		For Each RowSettingsFile In SettingsFile Do
		
			AttributeName = "Attribute" + RowSettingsFile.LineNumber;
			RowReceiver[AttributeName] = TrimAll(ThisObject["Table" + BaseID].Region(NumberCurrentRow,RowSettingsFile.NumberColumn,NumberCurrentRow,RowSettingsFile.NumberColumn).Text);
			
			//FillType переменных, которые будут использоваться в произвольном коде
			РВрем = RowReceiver[AttributeName];
			If RowSettingsFile.LineNumber = 1 Then
				Р1 = РВрем;
			ElsIf RowSettingsFile.LineNumber = 2 Then
				Р2 = РВрем;
			ElsIf RowSettingsFile.LineNumber = 3 Then
				Р3 = РВрем;
			ElsIf RowSettingsFile.LineNumber = 4 Then
				Р4 = РВрем;
			ElsIf RowSettingsFile.LineNumber = 5 Then
				Р5 = РВрем;
			EndIf;	
			
		EndDo;
		
		For Each RowSettingsFile In SettingsFile Do
				
			AttributeName = "Attribute" + RowSettingsFile.LineNumber;
			РТек = RowReceiver[AttributeName];

			Try
				Execute RowSettingsFile.ArbitraryCode;
			Except
				ErrorText = ErrorDescription();
				ErrorMessage = StrTemplate(Nstr("ru = 'Ошибка при выполнении произвольного кода (реквизит %1):%2';en = 'Error executing arbitrary code (attribute %1):%2'")
					, RowSettingsFile.LineNumber
					, ErrorText);
				Message(ErrorMessage);		
			EndTry;
			
			If ThisObject["CollapseTable" + BaseID] Then
				Try
					Execute CodeCastingAttributeToTypeNumber;
				Except
					РТек = 0;
				EndTry;
			EndIf;
			
			RowReceiver[AttributeName] = РТек;
							
		EndDo;
		
		NumberCurrentRow = NumberCurrentRow + 1;
		
	EndDo;
	
	If ValueTable <> Undefined Then
		
		//Indexing
		ValueTable.Indexes.Add(ColumnsWithKeyRow);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + BaseID].Count() Do
			
			AttributeName = String(BaseID) + AttributesCounter;
			HeaderAttributeFromSettings = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].HeaderAttributeForUser;
			
			ViewsHeadersAttributes[AttributeName] = ?(IsBlankString(HeaderAttributeFromSettings), "Attribute " + BaseID + AttributesCounter, AttributeName + ": " + HeaderAttributeFromSettings);
		
		EndDo;
		
	EndIf;
	
	Return ValueTable;
	
EndFunction

#EndRegion


#Region Auxiliary_procedures_and_functions

Function CheckFillingAttributes(SourceForPreview = "", ErrorsText = "") Export
	
	AttributesFilledOutCorrectly = True;
	
	If NumberColumnsInKey = 0 Then
		AttributesFilledOutCorrectly = False;
		ErrorText = Nstr("ru = 'Не заполнено число столбцов в ключе';en = 'The number of columns in the key is not filled'");
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.NumberColumnsInKey";
		UserMessage.Message();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
	EndIf;
		
	If NumberOfRowsWithEmptyKeysToBreakReading = 0 Then
		AttributesFilledOutCorrectly = False;
		ErrorText = Nstr("ru = 'Не заполнено число строк с пустыми ключами для прерывания чтения';en = 'The number of rows with empty keys to abort reading is not filled'");
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.NumberOfRowsWithEmptyKeysToBreakReading";
		UserMessage.Message();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
	EndIf;
	
#Region _1С_8_1С_77_SQL

	If IsBlankString(SourceForPreview) Or SourceForPreview = "A" Then
	
		If BaseTypeA >= 0 And BaseTypeA <= 2 Or BaseTypeA = 5 Then
			
			If IsBlankString(QueryTextA) Then
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнен текст запроса к базе А';en = 'The text of the request to the base A is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextA";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If IsBlankString(SourceForPreview) Or SourceForPreview = "B" Then
		
		If BaseTypeB >= 0 And BaseTypeB <= 2 Or BaseTypeB = 5 Then
		
			If IsBlankString(QueryTextB) Then
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнен текст запроса к базе Б';en = 'The text of the request to the base B is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextB";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
		EndIf;
		
	EndIf;
	
#EndRegion 


#Region Файл_Табличный_документ

	If IsBlankString(SourceForPreview) Or SourceForPreview = "A" Then
	
		If BaseTypeA = 3 Or BaseTypeA = 4 Then
				
			If BaseTypeA = 3 And IsBlankString(ConnectionToExternalBaseAFileFormat) Then
				
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнен формат файла А';en = 'File format A is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ConnectionToExternalBaseAFileFormat";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			ElsIf BaseTypeA = 3 And ConnectionToExternalBaseAFileFormat = "XML" Then
				
				If IsBlankString(ColumnNameKeyFromFileA) Then
				
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом файла А';en = 'The name of the column with the key of file A is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKeyFromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf; 
				
				If NumberColumnsInKey > 1 Then
				
					If ColumnNameKey2FromFileA = 0 Then
						
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 2 файла А';en = 'The name of the column with the key 2 of file A is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey2FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
				
					If ColumnNameKey3FromFileA = 0 Then
						
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 3 файла А';en = 'The name of the column with the key 3 of file A is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey3FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
					
				EndIf;
				
				If IsBlankString(DataStorageMethodInXMLFileA) Then
				
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнен способ хранения данных в файле А';en = 'The method of storing data in file A is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.DataStorageMethodInXMLFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf;
			
			Else
				
				//For xls and doc files the book/table number must be specified
				If BaseTypeA = 3 And (ConnectionToExternalBaseAFileFormat = "XLS" Or ConnectionToExternalBaseAFileFormat = "DOC") Then
					
					If ConnectionToExternalDatabaseANumberTableInFile = 0 Then
						AttributesFilledOutCorrectly = False;						
						ErrorText = StrTemplate(Nstr("ru = 'Не заполнен номер %1 файла А';en = 'The %1 number of file A is not filled'")
							, ?(ConnectionToExternalBaseAFileFormat = "XLS", Nstr("ru = 'книги';en = 'book'"), Nstr("ru = 'таблицы';en = 'table'")));
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConnectionToExternalDatabaseANumberTableInFile";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
					
				EndIf;
				
				If NumberFirstRowFileA = 0 Then
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнен номер первой строки файла/таблицы А';en = 'The number of the first line of file/table A is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.NumberFirstRowFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If ColumnNumberKeyFromFileA = 0 Then
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнен номер столбца с ключом файла/таблицы А';en = 'The column number with the file/table A key is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKeyFromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If NumberColumnsInKey > 1 Then			
					If ColumnNumberKey2FromFileA = 0 Then
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнен номер столбца с ключом 2 файла/таблицы А';en = 'Column number with key 2 of file/table A is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey2FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;			
				EndIf;
				
				If NumberColumnsInKey > 2 Then			
					If ColumnNumberKey3FromFileA = 0 Then
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнен номер столбца с ключом 3 файла/таблицы А';en = 'Column number with key 3 of file/table A is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey3FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;			
				EndIf; 
				
				For Each RowTP_SettingsFileA In SettingsFileA Do
					If IsBlankString(RowTP_SettingsFileA.ArbitraryCode) And RowTP_SettingsFileA.NumberColumn = 0 Then
						AttributesFilledOutCorrectly = False;
						ErrorText = StrTemplate(Nstr("ru = 'Не заполнен номер колонки файла/таблицы А, соответствующий реквизиту А%1';en = 'File/table A column number corresponding to attribute A%1 is not filled'")
							, RowTP_SettingsFileA.LineNumber);
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.SettingsFileA[" + (RowTP_SettingsFileA.LineNumber - 1) + "].NumberColumn";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
				EndDo;
				
			EndIf; 
			
		EndIf;
		
	EndIf; 
	
	If IsBlankString(SourceForPreview) Or SourceForPreview = "B" Then
		If BaseTypeB = 3 Or BaseTypeB = 4 Then
				
			If BaseTypeB = 3 And IsBlankString(ConnectionToExternalBaseBFileFormat) Then
				
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнен формат файла Б';en = 'File format B is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ConnectionToExternalBaseBFileFormat";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			ElsIf BaseTypeB = 3 And ConnectionToExternalBaseBFileFormat = "XML" Then

				If IsBlankString(ColumnNameKeyFromFileB) Then
				
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом файла Б';en = 'The name of the column with the key of file B is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKeyFromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf;
				
				If NumberColumnsInKey > 1 Then			
					If ColumnNameKey2FromFileB = 0 Then					
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 2 файла Б';en = 'The name of the column with the key 2 of file B is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey2FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;				
				EndIf;
				
				If NumberColumnsInKey > 2 Then			
					If ColumnNameKey3FromFileB = 0 Then					
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 3 файла Б';en = 'The name of the column with the key 3 of file B is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey3FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;				
				EndIf;
				
				If IsBlankString(DataStorageMethodInXMLFileB) Then
				
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнен способ хранения данных в файле Б';en = 'The method of storing data in file B is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.DataStorageMethodInXMLFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf;
				
			Else
				
				If BaseTypeB = 3 And (ConnectionToExternalBaseBFileFormat = "XLS" Or ConnectionToExternalBaseBFileFormat = "DOC") Then
					
					//For файлов xls и doc должен быть указан номер книги /таблицы
					If ConnectionToExternalDatabaseBNumberTableInFile = 0 Then
						AttributesFilledOutCorrectly = False;
						ErrorText = StrTemplate(Nstr("ru = 'Не заполнен номер %1 файла А';en = 'The %1 number of file A is not filled'")
							, ?(ConnectionToExternalBaseAFileFormat = "XLS", Nstr("ru = 'книги';en = 'book'"), Nstr("ru = 'таблицы';en = 'table'")));
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConnectionToExternalDatabaseBNumberTableInFile";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
				EndIf;
				
				If NumberFirstRowFileB = 0 Then
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнен номер первой строки файла/таблицы Б';en = 'The number of the first line of file/table B is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.NumberFirstRowFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If ColumnNumberKeyFromFileB = 0 Then
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнен номер столбца с ключом файла/таблицы Б';en = 'The column number with the file/table B key is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKeyFromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If NumberColumnsInKey > 1 Then
				
					If ColumnNumberKey2FromFileB = 0 Then
						
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнен номер столбца с ключом 2 файла/таблицы B';en = 'Column number with key 2 of file/table Б is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey2FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
				
				EndIf;
				
				If NumberColumnsInKey > 2 Then
				
					If ColumnNumberKey3FromFileB = 0 Then
						
						AttributesFilledOutCorrectly = False;
						ErrorText = Nstr("ru = 'Не заполнен номер столбца с ключом 3 файла/таблицы Б';en = 'Column number with key 3 of file/table B is not filled'");
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey3FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
				
				EndIf;
				
				For Each RowTP_SettingsFileB In SettingsFileB Do
					If IsBlankString(RowTP_SettingsFileB.ArbitraryCode) And RowTP_SettingsFileB.NumberColumn = 0 Then
						AttributesFilledOutCorrectly = False;
						ErrorText = StrTemplate(Nstr("ru = 'Не заполнен номер колонки файла/таблицы Б, соответствующий реквизиту Б%1';en = 'File/table B column number corresponding to attribute B%1 is not filled'")
							, RowTP_SettingsFileB.LineNumber);							
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.SettingsFileB[" + (RowTP_SettingsFileB.LineNumber - 1) + "].NumberColumn";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
#EndRegion 


 #Region JSON
 
	 If IsBlankString(SourceForPreview) Or SourceForPreview = "A" Then
		 
	 	If BaseTypeA = 6 Then
		 
			If IsBlankString(QueryTextA) Then
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнена строка JSON';en = 'JSON string not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextA";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
						
			If IsBlankString(ColumnNameKeyFromFileA) Then
					
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом файла А';en = 'The name of the column with the key of file A is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ColumnNameKeyFromFileA";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			
			EndIf; 
			
			If NumberColumnsInKey > 1 Then
			
				If ColumnNameKey2FromFileA = 0 Then
					
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 2 файла А';en = 'The name of the column with the key 2 of file A is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey2FromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ColumnNameKey3FromFileA = 0 Then
					
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 3 файла А';en = 'The name of the column with the key 3 of file A is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey3FromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf; 
			
		EndIf;
			
	EndIf;
	
	
	If IsBlankString(SourceForPreview) Or SourceForPreview = "B" Then
			
		If BaseTypeB = 6 Then
		 
			If IsBlankString(QueryTextB) Then
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнена строка JSON';en = 'JSON string not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextB";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
			If IsBlankString(ColumnNameKeyFromFileB) Then
					
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом файла Б';en = 'The name of the column with the key of file B is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ColumnNameKeyFromFileB";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			
			EndIf; 
			
			If NumberColumnsInKey > 1 Then
			
				If ColumnNameKey2FromFileB = 0 Then
					
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 2 файла Б';en = 'The name of the column with the key 2 of file B is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey2FromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ColumnNameKey3FromFileB = 0 Then
					
					AttributesFilledOutCorrectly = False;
					ErrorText = Nstr("ru = 'Не заполнено имя столбца с ключом 3 файла Б';en = 'The name of the column with the key 3 of file B is not filled'");
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey3FromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
 #EndRegion 

 	If IsBlankString(SourceForPreview) Then
	 
		//If the code is generated automatically, the fields of the condition tables must be filled in correctly
		If Not CodeForOutputRowsEditedManually And Not ConditionsOutputRowsDisabled Then
			
			If ConditionsOutputRows.Count() > 1 And Not ValueIsFilled(BooleanOperatorForConditionsOutputRows) Then
				AttributesFilledOutCorrectly = False;
				ErrorText = Nstr("ru = 'Не заполнен логический оператор для объединения условий вывода строк';en = 'The logical operator for combining string output conditions is not filled'");
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.BooleanOperatorForConditionsOutputRows";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
			For Each RowTP_ConditionsOutputRows In ConditionsOutputRows Do
				
				If Not ValueIsFilled(RowTP_ConditionsOutputRows.NameComparedAttribute) Then
					AttributesFilledOutCorrectly = False;
					ErrorText = StrTemplate(Nstr("ru = 'Не заполнено имя реквизита в строке условий вывода №%1';en = 'The attribute name is not filled in the line of output conditions No.%1'")
						,RowTP_ConditionsOutputRows.LineNumber);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (RowTP_ConditionsOutputRows.LineNumber - 1) + "].NameComparedAttribute";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(RowTP_ConditionsOutputRows.Condition) Then
					AttributesFilledOutCorrectly = False;
					ErrorText = StrTemplate(Nstr("ru = 'Не заполнено условие в строке условий вывода №%1';en = 'The condition in the line of output conditions No.%1 is not filled'")
						, RowTP_ConditionsOutputRows.LineNumber);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (RowTP_ConditionsOutputRows.LineNumber - 1) + "].Condition";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(RowTP_ConditionsOutputRows.ComparisonType) Then
					AttributesFilledOutCorrectly = False;
					ErrorText = StrTemplate(Nstr("ru = 'Не заполнен тип сравнения в строке условий вывода №%1';en = 'The comparison type is not filled in the line of output conditions No. %1'")
						, RowTP_ConditionsOutputRows.LineNumber);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (RowTP_ConditionsOutputRows.LineNumber - 1) + "].ComparisonType";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If RowTP_ConditionsOutputRows.Condition <> "Filled" Then
				
					If RowTP_ConditionsOutputRows.ComparisonType = "Attribute" And Not ValueIsFilled(RowTP_ConditionsOutputRows.NameComparedAttribute2) Then
						AttributesFilledOutCorrectly = False;
						ErrorText = StrTemplate(Nstr("ru = 'Не заполнено имя реквизита в строке условий вывода №%1';en = 'The attribute name is not filled in the line of output conditions No.%1'")
							,RowTP_ConditionsOutputRows.LineNumber);						
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConditionsOutputRows[" + (RowTP_ConditionsOutputRows.LineNumber - 1) + "].NameComparedAttribute2";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;     
			
		If Not CodeForProhibitingOutputRowsEditedManually And Not ConditionsProhibitOutputRowsDisabled Then
			
			If ConditionsProhibitOutputRows.Count() > 1 And Not ValueIsFilled(BooleanOperatorForProhibitingConditionsOutputRows) Then
				AttributesFilledOutCorrectly = False;
				ErrorText = StrTemplate(Nstr("ru = 'Не заполнен логический оператор для объединения условий запрета вывода строк';en = 'The logical operator for combining the conditions for prohibiting the output of rows is not filled'"));
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.BooleanOperatorForProhibitingConditionsOutputRows";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
			For Each RowTP_ConditionsProhibitOutputRows In ConditionsProhibitOutputRows Do
				
				If Not ValueIsFilled(RowTP_ConditionsProhibitOutputRows.NameComparedAttribute) Then
					AttributesFilledOutCorrectly = False;
					ErrorText = StrTemplate(Nstr("ru = 'Не заполнено имя реквизита в строке условий запрета вывода №%1';en = 'The attribute name is not filled in the line of conditions for the prohibition of output No. %1'")
						, RowTP_ConditionsProhibitOutputRows.LineNumber);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (RowTP_ConditionsProhibitOutputRows.LineNumber - 1) + "].NameComparedAttribute";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(RowTP_ConditionsProhibitOutputRows.Condition) Then
					AttributesFilledOutCorrectly = False;
					ErrorText = StrTemplate(Nstr("ru = 'Не заполнено условие в строке условий запрета вывода №%1';en = 'The condition in the line of conditions of the prohibition of output No. %1 is not filled'")
						, RowTP_ConditionsProhibitOutputRows.LineNumber);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (RowTP_ConditionsProhibitOutputRows.LineNumber - 1) + "].Condition";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(RowTP_ConditionsProhibitOutputRows.ComparisonType) Then
					AttributesFilledOutCorrectly = False;
					ErrorText = StrTemplate(Nstr("ru = 'Не заполнен тип сравнения в строке условий запрета вывода №%1';en = 'The comparison type is not filled in the line of conditions for prohibiting output No. %1'")
						, RowTP_ConditionsProhibitOutputRows.LineNumber);
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (RowTP_ConditionsProhibitOutputRows.LineNumber - 1) + "].ComparisonType";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If RowTP_ConditionsProhibitOutputRows.Condition <> "Filled" Then
					
					If RowTP_ConditionsProhibitOutputRows.ComparisonType = "Attribute" And Not ValueIsFilled(RowTP_ConditionsProhibitOutputRows.NameComparedAttribute2) Then
						AttributesFilledOutCorrectly = False;
						ErrorText = StrTemplate(Nstr("ru = 'Не заполнено имя реквизита в строке условий запрета вывода №%1';en = 'The attribute name is not filled in the line of conditions for the prohibition of output No. %1'")
							, RowTP_ConditionsProhibitOutputRows.LineNumber);						
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (RowTP_ConditionsProhibitOutputRows.LineNumber - 1) + "].NameComparedAttribute2";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;   
		
	EndIf;
	
	Return AttributesFilledOutCorrectly; 
	
EndFunction

Function SaveSettingsToBaseAtServer(SettingRef, SaveSpreadsheetDocuments) Export
	
	OperationCompletedSuccessfully = True;
	
	Try
		SettingObject = SettingRef.GetObject();
		Data = GetDataAsStructureOnServer(SaveSpreadsheetDocuments); 
		StorageExternal = New ValueStorage(Data);
		SettingObject.Операция = StorageExternal;
		SettingObject.Write();
		MessageText = StrTemplate(Nstr("ru = 'Данные успешно записаны в операцию %1';en = 'Data was successfully written to the operation %1'")
			, SettingObject.Title);
		Message(MessageText);
		RelatedDataComparisonOperation = SettingRef;
		Title = SettingObject.Title;
	Except
		ErrorText = StrTemplate(Nstr("ru = 'Ошибка при записи данных в операцию  %1 : %2';en = '%1 : %2'")
			, SettingRef.Titl, ErrorDescription());
		Message(ErrorText);
		OperationCompletedSuccessfully = False;
	EndTry;

	Return OperationCompletedSuccessfully;
	
EndFunction

Procedure OpenSettingsFromBaseAtServer(SettingRef, UploadSpreadsheetDocuments = False) Export
	
	OperationCompletedSuccessfully = True;
	
	Try
		
		StorageExternal = SettingRef.Операция;
		Data = StorageExternal.Get();
		FillPropertyValues(ThisObject, Data);
		//For less confusion with names, the name of the directory element gets into the heading,
		//based on which processing was completed
		Title = SettingRef.Title;
		RelatedDataComparisonOperation = SettingRef;
		
		//Prior to version 12.1.38, the PeriodTypeAbsolute flag was used instead of the PeriodType attribute
		//Value True of the PeriodTypeAbsolute flag corresponds to the value 0 of the PeriodType attribute
		//If there is no PeriodType attribute in the setting, it must be filled in based on the PeriodTypeAbsolute flag
		If Not Data.Property("PeriodType") Then
			If Data.Property("PeriodTypeAbsolute") Then
				PeriodType = ?(Data.PeriodTypeAbsolute, 0, 1);
			EndIf;
		EndIf;
		
		//Key column visibility settings appeared in version 15.5.58
		If Not Data.Property("VisibilityKey1") Then
			VisibilityKey1 = True;
		EndIf;
		
		If Not Data.Property("VisibilityKey2") Then
			VisibilityKey2 = NumberColumnsInKey > 1;
		EndIf;
		
		If Not Data.Property("VisibilityKey3") Then
			VisibilityKey3 = NumberColumnsInKey > 2;
		EndIf;
		
		//Column visibility settings for number of records appeared in version 15.5.58
		If Not Data.Property("VisibilityNumberOfRecordsA") Then
			VisibilityNumberOfRecordsA = True;
		EndIf;
		
		If Not Data.Property("VisibilityNumberOfRecordsB") Then
			VisibilityNumberOfRecordsB = True;
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
		
		If UploadSpreadsheetDocuments Then
			If Data.BaseTypeA = 4 Then
				Try
					If Data.Property("TableAValueStorage") Then
						TableA = Data.TableAValueStorage.Get();
					EndIf;
				Except
				EndTry; 
			EndIf;
			
			If Data.BaseTypeB = 4 Then
				Try
					If Data.Property("TableBValueStorage") Then
						TableB = Data.TableBValueStorage.Get();
					EndIf;
				Except
				EndTry; 
			EndIf;
		EndIf;
		
		//Restructuring parameters
		
		//Parameter CompositeKey replaced by NumberColumnsInKey
		If NumberColumnsInKey = 0 Then
			NumberColumnsInKey = ?(CompositeKey, 2, 1); 
		EndIf;
		
		If NumberOfRowsWithEmptyKeysToBreakReading = 0 Then
			NumberOfRowsWithEmptyKeysToBreakReading = 2;
		EndIf;
		
		Result.Clear();

	Except
		ErrorText = ErrorDescription();
		Message(ErrorText);
	EndTry;

EndProcedure

Function GetDataAsStructureOnServer(SaveSpreadsheetDocuments = False) Export
	
	DataStructure = New Structure;
	DataStructure.Insert("QueryTextA", 											QueryTextA);
	DataStructure.Insert("QueryTextB", 											QueryTextB);
	DataStructure.Insert("BaseTypeA", 											BaseTypeA);
	DataStructure.Insert("BaseTypeB", 											BaseTypeB);
	DataStructure.Insert("ConnectionToExternalBaseAPathBase", 					ConnectionToExternalBaseAPathBase);
	DataStructure.Insert("ConnectionToExternalBaseBPathBase",  					ConnectionToExternalBaseBPathBase);
	DataStructure.Insert("ConnectionToExternalBaseALogin",  					ConnectionToExternalBaseALogin);
	DataStructure.Insert("ConnectionToExternalBaseBLogin",  					ConnectionToExternalBaseBLogin);
	DataStructure.Insert("ConnectionToExternalBaseAPassword", 					ConnectionToExternalBaseAPassword);
	DataStructure.Insert("ConnectionToExternalBaseBPassword",  					ConnectionToExternalBaseBPassword);
	DataStructure.Insert("ConnectionToExternalBaseAServer",  					ConnectionToExternalBaseAServer);
	DataStructure.Insert("ConnectionToExternalBaseBServer",  					ConnectionToExternalBaseBServer);
	DataStructure.Insert("WorkOptionExternalBaseA",  							WorkOptionExternalBaseA);
	DataStructure.Insert("WorkOptionExternalBaseB",   							WorkOptionExternalBaseB);
	DataStructure.Insert("VersionPlatformExternalBaseA",   						VersionPlatformExternalBaseA);
	DataStructure.Insert("VersionPlatformExternalBaseB",   						VersionPlatformExternalBaseB);
	DataStructure.Insert("ConnectingToExternalBaseADriverSQL",					ConnectingToExternalBaseADriverSQL);
	DataStructure.Insert("ConnectingToExternalBaseBDriverSQL",					ConnectingToExternalBaseBDriverSQL);
	DataStructure.Insert("ConnectionToExternalBaseAFileFormat",					ConnectionToExternalBaseAFileFormat);
	DataStructure.Insert("ConnectionToExternalBaseBFileFormat",					ConnectionToExternalBaseBFileFormat);
	DataStructure.Insert("ConnectionToExternalBaseAPathToFile",					ConnectionToExternalBaseAPathToFile);
	DataStructure.Insert("ConnectionToExternalBaseBPathToFile",					ConnectionToExternalBaseBPathToFile);
	DataStructure.Insert("ConnectingToExternalBaseADeviceStorageFile",			ConnectingToExternalBaseADeviceStorageFile);
	DataStructure.Insert("ConnectingToExternalBaseBDeviceStorageFile",			ConnectingToExternalBaseBDeviceStorageFile);
	DataStructure.Insert("ConnectionToExternalDatabaseANumberTableInFile",		ConnectionToExternalDatabaseANumberTableInFile);
	DataStructure.Insert("ConnectionToExternalDatabaseBNumberTableInFile",		ConnectionToExternalDatabaseBNumberTableInFile);
	
	DataStructure.Insert("CodeForOutputRows", 									CodeForOutputRows);
	DataStructure.Insert("CodeForProhibitingOutputRows", 						CodeForProhibitingOutputRows);
	DataStructure.Insert("BooleanOperatorForConditionsOutputRows", 				BooleanOperatorForConditionsOutputRows);
	DataStructure.Insert("BooleanOperatorForProhibitingConditionsOutputRows",	BooleanOperatorForProhibitingConditionsOutputRows);
	DataStructure.Insert("CodeForOutputRowsEditedManually", 					CodeForOutputRowsEditedManually);
	DataStructure.Insert("CodeForProhibitingOutputRowsEditedManually", 			CodeForProhibitingOutputRowsEditedManually);
	DataStructure.Insert("ConditionsOutputRowsDisabled", 						ConditionsOutputRowsDisabled);
	DataStructure.Insert("ConditionsProhibitOutputRowsDisabled", 				ConditionsProhibitOutputRowsDisabled);
	
	DataStructure.Insert("RelationalOperation",   								RelationalOperation);
	
	DataStructure.Insert("PeriodTypeAbsolute",									PeriodTypeAbsolute);
	DataStructure.Insert("PeriodType",											PeriodType);
	DataStructure.Insert("AbsolutePeriodValue",									AbsolutePeriodValue);
	DataStructure.Insert("RelativePeriodValue",									RelativePeriodValue);
	DataStructure.Insert("ValueOfSlaveRelativePeriod",							ValueOfSlaveRelativePeriod);
	DataStructure.Insert("DiscretenessOfRelativePeriod",						DiscretenessOfRelativePeriod);
	DataStructure.Insert("DiscretenessOfSlaveRelativePeriod",					DiscretenessOfSlaveRelativePeriod);
	DataStructure.Insert("CompositeKey",										CompositeKey);
	DataStructure.Insert("NumberColumnsInKey",									NumberColumnsInKey);
	DataStructure.Insert("NumberOfRowsWithEmptyKeysToBreakReading",				NumberOfRowsWithEmptyKeysToBreakReading);
	DataStructure.Insert("DisplayKeyColumnTypes",								DisplayKeyColumnTypes);
	DataStructure.Insert("PathToDownloadFile",									PathToDownloadFile);
	DataStructure.Insert("UploadFileFormat",									UploadFileFormat);
	DataStructure.Insert("SortTableDifferences",								SortTableDifferences);
	DataStructure.Insert("OrderSortTableDifferences",							OrderSortTableDifferences);
			
	DataStructure.Insert("NumberFirstRowFileA",									NumberFirstRowFileA);
	DataStructure.Insert("NumberFirstRowFileB",									NumberFirstRowFileB);
	DataStructure.Insert("ColumnNumberKeyFromFileA",							ColumnNumberKeyFromFileA);	
	DataStructure.Insert("ColumnNumberKey2FromFileA",							ColumnNumberKey2FromFileA);
	DataStructure.Insert("ColumnNumberKey3FromFileA",							ColumnNumberKey3FromFileA);
	DataStructure.Insert("ColumnNumberKeyFromFileB",							ColumnNumberKeyFromFileB);
	DataStructure.Insert("ColumnNumberKey2FromFileB",							ColumnNumberKey2FromFileB);
	DataStructure.Insert("ColumnNumberKey3FromFileB",							ColumnNumberKey3FromFileB);
	DataStructure.Insert("ColumnNameKeyFromFileA",								ColumnNameKeyFromFileA);	
	DataStructure.Insert("ColumnNameKey2FromFileA",								ColumnNameKey2FromFileA);	
	DataStructure.Insert("ColumnNameKey3FromFileA",								ColumnNameKey3FromFileA);	
	DataStructure.Insert("ColumnNameKeyFromFileB",								ColumnNameKeyFromFileB);	
	DataStructure.Insert("ColumnNameKey2FromFileB",								ColumnNameKey2FromFileB);
	DataStructure.Insert("ColumnNameKey3FromFileB",								ColumnNameKey3FromFileB);
	DataStructure.Insert("ElementNameWithDataFileA",							ElementNameWithDataFileA);	
	DataStructure.Insert("ElementNameWithDataFileB",							ElementNameWithDataFileB);
	DataStructure.Insert("ParentNodeNameFileA",									ParentNodeNameFileA);
	DataStructure.Insert("ParentNodeNameFileB",									ParentNodeNameFileB);
	DataStructure.Insert("DataStorageMethodInXMLFileA",							DataStorageMethodInXMLFileA);
	DataStructure.Insert("DataStorageMethodInXMLFileB",							DataStorageMethodInXMLFileB);
	DataStructure.Insert("CastKeyToStringA",									CastKeyToStringA);
	DataStructure.Insert("CastKey2ToStringA",									CastKey2ToStringA);
	DataStructure.Insert("CastKey3ToStringA",									CastKey3ToStringA);
	DataStructure.Insert("CastKeyToStringB",									CastKeyToStringB);
	DataStructure.Insert("CastKey2ToStringB",									CastKey2ToStringB);
	DataStructure.Insert("CastKey3ToStringB",									CastKey3ToStringB);
	DataStructure.Insert("KeyLengthWhenCastingToStringA",						KeyLengthWhenCastingToStringA);
	DataStructure.Insert("KeyLength2WhenCastingToStringA",						KeyLength2WhenCastingToStringA);
	DataStructure.Insert("KeyLength3WhenCastingToStringA",						KeyLength3WhenCastingToStringA);
	DataStructure.Insert("KeyLengthWhenCastingToStringB",						KeyLengthWhenCastingToStringB);
	DataStructure.Insert("KeyLength2WhenCastingToStringB",						KeyLength2WhenCastingToStringB);
	DataStructure.Insert("KeyLength3WhenCastingToStringB",						KeyLength3WhenCastingToStringB);
	DataStructure.Insert("UseAsKeyUniqueIdentifierA", 							UseAsKeyUniqueIdentifierA);
	DataStructure.Insert("UseAsKey2UniqueIdentifierA", 							UseAsKey2UniqueIdentifierA);
	DataStructure.Insert("UseAsKey3UniqueIdentifierA", 							UseAsKey3UniqueIdentifierA);
	DataStructure.Insert("UseAsKeyUniqueIdentifierB", 							UseAsKeyUniqueIdentifierB);
	DataStructure.Insert("UseAsKey2UniqueIdentifierB", 							UseAsKey2UniqueIdentifierB);
	DataStructure.Insert("UseAsKey3UniqueIdentifierB", 							UseAsKey3UniqueIdentifierB);
	DataStructure.Insert("CastKeyToUpperCaseA", 								CastKeyToUpperCaseA);
	DataStructure.Insert("CastKey2ToUpperCaseА", 								CastKey2ToUpperCaseA);
	DataStructure.Insert("CastKey3ToUpperCaseА", 								CastKey3ToUpperCaseA);
	DataStructure.Insert("CastKeyToUpperCaseБ", 								CastKeyToUpperCaseB);
	DataStructure.Insert("CastKey2ToUpperCaseБ", 								CastKey2ToUpperCaseB);
	DataStructure.Insert("CastKey3ToUpperCaseБ", 								CastKey3ToUpperCaseB);
	DataStructure.Insert("DeleteFromKeyCurlyBracketsA", 						DeleteFromKeyCurlyBracketsA);
	DataStructure.Insert("DeleteFromKey2CurlyBracketsA", 						DeleteFromKey2CurlyBracketsA);
	DataStructure.Insert("DeleteFromKey3CurlyBracketsA", 						DeleteFromKey3CurlyBracketsA);
	DataStructure.Insert("DeleteFromKeyCurlyBracketsB", 						DeleteFromKeyCurlyBracketsB);
	DataStructure.Insert("DeleteFromKey2CurlyBracketsB", 						DeleteFromKey2CurlyBracketsB);
	DataStructure.Insert("DeleteFromKey3CurlyBracketsB", 						DeleteFromKey3CurlyBracketsB);
	DataStructure.Insert("ArbitraryKeyCode1A",		 							ArbitraryKeyCode1A);
	DataStructure.Insert("ArbitraryKeyCode2A",		 							ArbitraryKeyCode2A);
	DataStructure.Insert("ArbitraryKeyCode3A",		 							ArbitraryKeyCode3A);
	DataStructure.Insert("ArbitraryKeyCode1B",		 							ArbitraryKeyCode1B);
	DataStructure.Insert("ArbitraryKeyCode2B",		 							ArbitraryKeyCode2B);
	DataStructure.Insert("ArbitraryKeyCode3B",		 							ArbitraryKeyCode3B);
	DataStructure.Insert("ExecuteArbitraryKeyCode1A",		 					ExecuteArbitraryKeyCode1A);
	DataStructure.Insert("ExecuteArbitraryKeyCode2A",		 					ExecuteArbitraryKeyCode2A);
	DataStructure.Insert("ExecuteArbitraryKeyCode3A",		 					ExecuteArbitraryKeyCode3A);
	DataStructure.Insert("ExecuteArbitraryKeyCode1B",		 					ExecuteArbitraryKeyCode1B);
	DataStructure.Insert("ExecuteArbitraryKeyCode2B",		 					ExecuteArbitraryKeyCode2B);
	DataStructure.Insert("ExecuteArbitraryKeyCode3B",		 					ExecuteArbitraryKeyCode3B);
	DataStructure.Insert("VisibilityAttributeA1",								VisibilityAttributeA1);
	DataStructure.Insert("VisibilityAttributeA2",								VisibilityAttributeA2);
	DataStructure.Insert("VisibilityAttributeA3",								VisibilityAttributeA3);
	DataStructure.Insert("VisibilityAttributeA4",								VisibilityAttributeA4);
	DataStructure.Insert("VisibilityAttributeA5",								VisibilityAttributeA5);
	DataStructure.Insert("VisibilityAttributeB1",								VisibilityAttributeB1);
	DataStructure.Insert("VisibilityAttributeB2",								VisibilityAttributeB2);
	DataStructure.Insert("VisibilityAttributeB3",								VisibilityAttributeB3);
	DataStructure.Insert("VisibilityAttributeB4",								VisibilityAttributeB4);
	DataStructure.Insert("VisibilityAttributeB5",								VisibilityAttributeB5);
	
	DataStructure.Insert("CollapseTableA",		 								CollapseTableA);
	DataStructure.Insert("CollapseTableB",		 								CollapseTableB);

	DataStructure.Insert("ValueTableConditionsOutputRows", 						ConditionsOutputRows.Unload());
	DataStructure.Insert("ValueTableConditionsProhibitOutputRows", 				ConditionsProhibitOutputRows.Unload());
	DataStructure.Insert("ValueTableSettingsFileA", 							SettingsFileA.Unload());
	DataStructure.Insert("ValueTableSettingsFileB", 							SettingsFileB.Unload());
	DataStructure.Insert("ValueTableParameterListA", 							ParameterListA.Unload());
	DataStructure.Insert("ValueTableParameterListB", 							ParameterListB.Unload());	
	
	If SaveSpreadsheetDocuments Then
		
		If BaseTypeA = 4 Then
			TableAValueStorage = New ValueStorage(TableA);
			
			If DataStructure.Property("TableAValueStorage") Then
				DataStructure.TableAValueStorage = TableAValueStorage;
			Else
				DataStructure.Insert("TableAValueStorage", TableAValueStorage);
			EndIf;
		EndIf;
		
		If BaseTypeB = 4 Then
			TableBValueStorage = New ValueStorage(TableB);
			
			If DataStructure.Property("TableBValueStorage") Then
				DataStructure.TableBValueStorage = TableBValueStorage;
			Else
				DataStructure.Insert("TableBValueStorage", TableBValueStorage);
			EndIf;
		EndIf;
		
	EndIf;
	
	Return DataStructure;
	
EndFunction

Procedure SetParameters(Query, BaseID)
	
	For Each Parameter In ThisObject["ParameterList" + BaseID] Do
		If TypeOf(Parameter.ParameterValue) <> Type("Undefined") Then
			If Parameter.ParameterName = "ValidFrom" Or Parameter.ParameterName = "ValidTo" Then
				Continue;
			EndIf;
			Query.SetParameter(Parameter.ParameterName, Parameter.ParameterValue);			
		EndIf;
	EndDo;
	       	
EndProcedure

Procedure FillVariablesPWithDefaultValues()
	
	Р1 = Undefined;
	Р2 = Undefined;
	Р3 = Undefined;
	Р4 = Undefined;
	Р5 = Undefined;
	
EndProcedure

Function UploadResultToFileAtServer(ForClient = False) Export
	
	UploadFileFormat = Upper(UploadFileFormat);
	
	If IsBlankString(UploadFileFormat) Then
		ErrorText = Nstr("ru = 'Не указан формат файла выгрузки';en = 'Upload file format not specified'");
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Message();
		Return Undefined;
	EndIf;
	
	If ForClient Then
		PathToTemporaryFile = GetTempFileName(UploadFileFormat);
	Else
		If IsBlankString(PathToDownloadFile) Then
			ErrorText = Nstr("ru = 'Не заполнен путь к файлу выгрузки (на сервере)';en = 'The path to the upload file is not filled (at server)'");
			UserMessage = New UserMessage;
			UserMessage.Text = ErrorText;
			UserMessage.Field = "Object.PathToDownloadFile";
			UserMessage.Message();
			Return Undefined;
		EndIf;
		
		PathToTemporaryFile = PathToDownloadFile;
	EndIf;
	
	If Result.Count() = 0 Then
		ErrorText = Nstr("ru = 'Нет данных для выгрузки';en = 'No data to upload'");
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.Result";
		UserMessage.Message();
		Return Undefined;
	EndIf;
		
	Try	
		DeleteFiles(PathToTemporaryFile);	
	Except EndTry;
	
	Message(Format(CurrentDate(), "DLF=DT") + " Выгрузка в файл """ + PathToTemporaryFile + """ формата """ + UploadFileFormat + """ начата");
	
	If UploadFileFormat = "CSV" Then
		
		ColumnSeparator = ";";
		TextWriter = New TextWriter(PathToTemporaryFile, TextEncoding.UTF8);
		ListHeaderString = "№ строки" + ColumnSeparator
				+ ?(VisibilityKey1, "Ключ 1" + ColumnSeparator, "")
				+ ?(NumberColumnsInKey > 1 И VisibilityKey2, "Ключ 2" + ColumnSeparator, "")
				+ ?(NumberColumnsInKey > 2 И VisibilityKey3, "Ключ 3" + ColumnSeparator, "")
				+ ?(VisibilityNumberOfRecordsA, "Число записей А" + ColumnSeparator, "")
				+ ?(VisibilityNumberOfRecordsB, "Число записей Б" + ColumnSeparator, "");
		
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ThisObject["VisibilityAttributeA" + AttributesCounter] Тогда
				ListHeaderString = ListHeaderString + ColumnSeparator + СтрЗаменить(ViewsHeadersAttributes["A" + AttributesCounter], ColumnSeparator,",");
			EndIf;
		EndDo;
		
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ThisObject["VisibilityAttributeB" + AttributesCounter] Тогда
				ListHeaderString = ListHeaderString + ColumnSeparator + СтрЗаменить(ViewsHeadersAttributes["B" + AttributesCounter], ColumnSeparator,",");
			EndIf;
		EndDo;
		
		ListHeaderString = СтрЗаменить(ListHeaderString, "" + ColumnSeparator + ColumnSeparator, ColumnSeparator);
		TextWriter.Write(ListHeaderString);
			
		RowsCounter = 0;
		For Each RowTP_Result In Result Do
			
			RowsCounter = RowsCounter + 1;
			
			TextWriter.Write(
				Chars.LF
					+ "" + RowTP_Result.LineNumber + ColumnSeparator
					+ ?(VisibilityKey1, "" + RowTP_Result.Key1 + ColumnSeparator, "")
					+ ?(NumberColumnsInKey > 1 И VisibilityKey2, "" + RowTP_Result.Key2 + ColumnSeparator, "")
					+ ?(NumberColumnsInKey > 2 И VisibilityKey3, "" + RowTP_Result.Key3 + ColumnSeparator, "")
					+ ?(VisibilityNumberOfRecordsA, "" + RowTP_Result.NumberOfRecordsA + ColumnSeparator, "")
					+ ?(VisibilityNumberOfRecordsB, "" + RowTP_Result.NumberOfRecordsB + ColumnSeparator, "")
					+ ?(VisibilityAttributeA1, "" + RowTP_Result.AttributeA1 + ColumnSeparator, "")
					+ ?(VisibilityAttributeA2, "" + RowTP_Result.AttributeA2 + ColumnSeparator, "")
					+ ?(VisibilityAttributeA3, "" + RowTP_Result.AttributeA3 + ColumnSeparator, "")
					+ ?(VisibilityAttributeA4, "" + RowTP_Result.AttributeA4 + ColumnSeparator, "")
					+ ?(VisibilityAttributeA5, "" + RowTP_Result.AttributeA5 + ColumnSeparator, "")
					+ ?(VisibilityAttributeB1, "" + RowTP_Result.AttributeB1 + ColumnSeparator, "")
					+ ?(VisibilityAttributeB2, "" + RowTP_Result.AttributeB2 + ColumnSeparator, "")
					+ ?(VisibilityAttributeB3, "" + RowTP_Result.AttributeB3 + ColumnSeparator, "")
					+ ?(VisibilityAttributeB4, "" + RowTP_Result.AttributeB4 + ColumnSeparator, "")
					+ ?(VisibilityAttributeB5, "" + RowTP_Result.AttributeB5 + ColumnSeparator, "")
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
				
		//NumberColumnsNumberOfRecordsA = ?(NumberColumnsInKey > 1 И VisibilityKey2, ?(NumberColumnsInKey > 2 И VisibilityKey3, 5, 4), 3);
		NumberOfUploadedKeys = ?(VisibilityKey1, 1, 0) + ?(NumberColumnsInKey > 1 И VisibilityKey2, 1, 0) + ?(NumberColumnsInKey > 2 И VisibilityKey3, 1, 0);
		ColumnNumberFirstPageDownAttributes = NumberOfUploadedKeys + ?(VisibilityNumberOfRecordsA, 1, 0) + ?(VisibilityNumberOfRecordsB, 1, 0) + 2;		
		
		SpreadsheetDocument = New SpreadsheetDocument;
		SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
		SpreadsheetDocument.FitToPage = True;
		
		SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, 1, "№ строки",,7);
		If VisibilityKey1 Then
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, 2, "Key 1");
		EndIf;
		If NumberColumnsInKey > 1 AND VisibilityKey2 Then			
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, ?(VisibilityKey1, 1, 0) + 2, "Ключ 2");			
		EndIf;
		If NumberColumnsInKey > 2 AND VisibilityKey3 Then
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, ?(VisibilityKey1, 1, 0) + ?(VisibilityKey2, 1, 0) + 2, "Ключ 3");			
		EndIf;
		
		Если VisibilityNumberOfRecordsA Тогда
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, NumberOfUploadedKeys + 2,  		"Число записей А",, 7);
		EndIf; 
		
		Если VisibilityNumberOfRecordsB Тогда
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, NumberOfUploadedKeys + ?(VisibilityNumberOfRecordsA, 1, 0) + 2,  	"Число записей Б",, 7);
		EndIf;
		
		OffsetFromColumnWithFirstUploadedAttribute = 0;
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ThisObject["VisibilityAttributeA" + AttributesCounter] Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, ColumnNumberFirstPageDownAttributes + OffsetFromColumnWithFirstUploadedAttribute, ViewsHeadersAttributes["A" + AttributesCounter]);
				OffsetFromColumnWithFirstUploadedAttribute = OffsetFromColumnWithFirstUploadedAttribute + 1;
			EndIf;
		EndDo;
		
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ThisObject["VisibilityAttributeB" + AttributesCounter] Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, ColumnNumberFirstPageDownAttributes + OffsetFromColumnWithFirstUploadedAttribute, ViewsHeadersAttributes["B" + AttributesCounter]);
				OffsetFromColumnWithFirstUploadedAttribute = OffsetFromColumnWithFirstUploadedAttribute + 1;
			EndIf;
		EndDo;
		
		ColumnsSizesStructure = New Structure;
		ColumnsSizesStructure.Insert("K1", 0);
		ColumnsSizesStructure.Insert("K2", 0);
		ColumnsSizesStructure.Insert("K3", 0);
		ColumnsSizesStructure.Insert("A1", 0);
		ColumnsSizesStructure.Insert("A2", 0);
		ColumnsSizesStructure.Insert("A3", 0);
		ColumnsSizesStructure.Insert("A4", 0);
		ColumnsSizesStructure.Insert("A5", 0);
		ColumnsSizesStructure.Insert("B1", 0);
		ColumnsSizesStructure.Insert("B2", 0);
		ColumnsSizesStructure.Insert("B3", 0);
		ColumnsSizesStructure.Insert("B4", 0);
		ColumnsSizesStructure.Insert("B5", 0);
		RowsCounter = 0;
		For Each RowTP_Result In Result Do
			
			ColumnsSizesStructure.K1 = Max(2, ColumnsSizesStructure.K1, StrLen(RowTP_Result.Key1));
			If NumberColumnsInKey > 1 And VisibilityKey2 Then
				ColumnsSizesStructure.K2 = Макс(2,ColumnsSizesStructure.K2, StrLen(RowTP_Result.Key2));
			EndIf;
			If NumberColumnsInKey > 2 And VisibilityKey3 Then				
				ColumnsSizesStructure.K3 = Max(2, ColumnsSizesStructure.K3, StrLen(RowTP_Result.Key3));
			EndIf;
			
			ColumnsSizesStructure.A1 = Макс(2,ColumnsSizesStructure.A1,StrLen(RowTP_Result.AttributeA1));
			ColumnsSizesStructure.A2 = Макс(2,ColumnsSizesStructure.A2,StrLen(RowTP_Result.AttributeA2));
			ColumnsSizesStructure.A3 = Макс(2,ColumnsSizesStructure.A3,StrLen(RowTP_Result.AttributeA3));
			ColumnsSizesStructure.A4 = Макс(2,ColumnsSizesStructure.A4,StrLen(RowTP_Result.AttributeA4));
			ColumnsSizesStructure.A5 = Макс(2,ColumnsSizesStructure.A5,StrLen(RowTP_Result.AttributeA5));
			ColumnsSizesStructure.B1 = Макс(2,ColumnsSizesStructure.B1,StrLen(RowTP_Result.AttributeB1));
			ColumnsSizesStructure.B2 = Макс(2,ColumnsSizesStructure.B2,StrLen(RowTP_Result.AttributeB2));
			ColumnsSizesStructure.B3 = Макс(2,ColumnsSizesStructure.B3,StrLen(RowTP_Result.AttributeB3));
			ColumnsSizesStructure.B4 = Макс(2,ColumnsSizesStructure.B4,StrLen(RowTP_Result.AttributeB4));
			ColumnsSizesStructure.B5 = Макс(2,ColumnsSizesStructure.B5,StrLen(RowTP_Result.AttributeB5));
			
			RowsCounter = RowsCounter + 1;
			
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, RowsCounter + 1, 1, RowTP_Result.LineNumber, 1, 7);
			If VisibilityKey1 Then
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, RowsCounter + 1, 2, RowTP_Result.Key1,, ColumnsSizesStructure.K1);
			EndIf;
			If NumberColumnsInKey > 1 And VisibilityKey2 Then
				SetCellValueSpreadsheetDocument(SpreadsheetDocument
					, RowsCounter + 1
					, ?(VisibilityKey1, 1, 0) + 2
					, RowTP_Result.Key2
					,
					, ColumnsSizesStructure.K2);
			EndIf;
			If NumberColumnsInKey > 2 And VisibilityKey3 Then
				SetCellValueSpreadsheetDocument(SpreadsheetDocument
					, RowsCounter + 1
					, ?(VisibilityKey1, 1, 0) + ?(VisibilityKey2, 1, 0) + 2
					, RowTP_Result.Key3
					,
					, ColumnsSizesStructure.K3);
			EndIf;							
		
			Если VisibilityNumberOfRecordsA Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, RowsCounter + 1, NumberOfUploadedKeys + 2,	RowTP_Result.NumberOfRecordsA, 1, 7);
			EndIf;
			
			Если VisibilityNumberOfRecordsB Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, RowsCounter + 1, NumberOfUploadedKeys + ?(VisibilityNumberOfRecordsA, 1, 0) + 2, RowTP_Result.NumberOfRecordsB, 1, 7);
			EndIf;
			
			OffsetFromColumnWithFirstUploadedAttribute = 0;
			For CounterAttributes = 1 По NumberOfRequisites Цикл 
				Если ThisObject["VisibilityAttributeA" + CounterAttributes] Тогда
					SetCellValueSpreadsheetDocument(SpreadsheetDocument, RowsCounter + 1, ColumnNumberFirstPageDownAttributes + OffsetFromColumnWithFirstUploadedAttribute, RowTP_Result["AttributeA" + CounterAttributes],, ColumnsSizesStructure["A" + CounterAttributes]);
					OffsetFromColumnWithFirstUploadedAttribute = OffsetFromColumnWithFirstUploadedAttribute + 1;
				EndIf;
			EndDo;
			
			For CounterAttributes = 1 По NumberOfRequisites Цикл 
				Если ThisObject["VisibilityAttributeB" + CounterAttributes] Тогда
					SetCellValueSpreadsheetDocument(SpreadsheetDocument, RowsCounter + 1, ColumnNumberFirstPageDownAttributes + OffsetFromColumnWithFirstUploadedAttribute, RowTP_Result["AttributeB" + CounterAttributes],, ColumnsSizesStructure["B" + CounterAttributes]);
					OffsetFromColumnWithFirstUploadedAttribute = OffsetFromColumnWithFirstUploadedAttribute + 1;
				EndIf;
			EndDo;
			
		EndDo; 
		
		SpreadsheetDocument.Write(PathToTemporaryFile, SpreadsheetDocumentFileType[UploadFileFormat]);
		
	Else
		
		ErrorText = StrTemplate(Nstr("ru = 'Формат файла выгрузки ""%1"" не предусмотрен';en = 'Upload file format ''%1'' is not supported'")
			, UploadFileFormat);
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Message();
		Return Undefined;
		
	EndIf;
	
	If ForClient Then
		
		FileData = New BinaryData(PathToTemporaryFile);
		FileAddress = PutToTempStorage(FileData);
		
		Try
			DeleteFiles(PathToTemporaryFile);
		Except EndTry;
		
		Return FileAddress;
		
	Else
		
		Message(Format(CurrentDate(), "DLF=DT") + " Выгрузка в файл """ + PathToTemporaryFile + """ формата """ + UploadFileFormat + """ завершена (число строк: " + RowsCounter + ")");
		Return Undefined;
		
	EndIf;
	
EndFunction

Procedure SetCellValueSpreadsheetDocument(SpreadsheetDocument, LineNumber, NumberColumn, CellValue, vTypeValues = 0, ColumnWidth = 6)
	
	If vTypeValues = 0 Then
		ValueType = New TypeDescription("String");
	ElsIf vTypeValues = 1 Then
		ValueType = New TypeDescription("Number");
	EndIf;
	
	If False Then
		SpreadsheetDocument = New SpreadsheetDocument;
	EndIf;
	
	SpreadsheetDocument.Region(LineNumber,NumberColumn).ContainsValue = True;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).ValueType = 	ValueType;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).Value = 		CellValue;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).ColumnWidth = 	ColumnWidth;
	Line = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	SpreadsheetDocument.Region(LineNumber,NumberColumn).TopBorder = Line;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).BottomBorder = Line;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).LeftBorder = Line;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).RightBorder = Line;
	SpreadsheetDocument.Region(LineNumber,NumberColumn).HorizontalAlign = HorizontalAlign.Left;
	
EndProcedure

Procedure RefreshDataPeriod() Export
	
	CurrentDate = BegOfDay(CurrentDate());
	StartingPointDateBeginning = BegOfDay(CurrentDate) + 24 * 3600;
	
	//Defaults
	ValidFrom = CurrentDate;
	ValidTo = EndOfDay(CurrentDate);
	
	//Absolute period
	If PeriodType = 0 Then
		
	Else
		
		If DiscretenessOfRelativePeriod = "year" Then
			ValidFrom = AddMonth(StartingPointDateBeginning, -1 * 12 * RelativePeriodValue);
		ElsIf DiscretenessOfRelativePeriod = "month" Then
			ValidFrom = AddMonth(StartingPointDateBeginning, -1 * RelativePeriodValue);
		ElsIf DiscretenessOfRelativePeriod = "day" Then
			ValidFrom = StartingPointDateBeginning - 24 * 3600 * RelativePeriodValue;
		EndIf;
		
		//Last Х
		If PeriodType = 1 Then

			ValidTo = EndOfDay(CurrentDate);
			
		//First X of the last Y
		ElsIf PeriodType = 2 Then
			
			StartingPointDatesEnds = ValidFrom - 1;
			
			If DiscretenessOfSlaveRelativePeriod = "year" Then
				ValidTo = AddMonth(StartingPointDatesEnds, 1 * 12 * ValueOfSlaveRelativePeriod);
			ElsIf DiscretenessOfSlaveRelativePeriod = "month" Then
				ValidTo = AddMonth(StartingPointDatesEnds, 1 * ValueOfSlaveRelativePeriod);
			ElsIf DiscretenessOfSlaveRelativePeriod = "day" Then
				ValidTo = StartingPointDatesEnds + 24 * 3600 * ValueOfSlaveRelativePeriod;
			EndIf;
			
		Else
			
			ValidTo = EndOfDay(CurrentDate);
		
		EndIf;
		
		AbsolutePeriodValue.ValidFrom = Min(ValidFrom,ValidTo);
		AbsolutePeriodValue.ValidTo = ValidTo;
		
	EndIf;
		
EndProcedure

Function FindSlaveNodeXMLFileByName(CurrentNode, SearchNodeName)
	
	//Branch for root element
	If CurrentNode.NodeName = SearchNodeName Then
					
		Return CurrentNode;
		
	EndIf;
	
	For Each SlaveNode In CurrentNode.ChildNodes Do
					
		If SlaveNode.NodeName = SearchNodeName Then
					
			FoundNode = SlaveNode;
			
		Else 
		
			FoundNode = FindSlaveNodeXMLFileByName(SlaveNode, SearchNodeName); 
			
		EndIf;
		
		If FoundNode <> Undefined Then
			
			Return FoundNode
			
		EndIf;
		
	EndDo;

	Return Undefined;
	
EndFunction

#EndRegion

NumberOfRequisites = 5;
CodeCastingAttributeToTypeNumber = "РТек = Number(РТек);";
ViewsHeadersAttributes = New Map;

For AttributesCounter = 1 To NumberOfRequisites Do

	ViewsHeadersAttributes.Insert("A" + AttributesCounter , "Attribute A" + AttributesCounter);
	ViewsHeadersAttributes.Insert("B" + AttributesCounter , "Attribute B" + AttributesCounter);

EndDo;
 