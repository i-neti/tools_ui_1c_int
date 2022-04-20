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
					
					//Values реквизитов выводятся только при наличии единственной записи по ключу
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
						Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ErrorText);
					EndIf;
					ErrorMessageRunningCodeForOutputRows = True;
				EndTry;
			EndIf;
			
			//If число строк с одним ключом больше 1, результирующую строку нужно вывести обязательно, 
			//т.к. условия в данном случае некорректно применять вообще
			If RowTP_Result.NumberOfRecordsA <= 1 And RowTP_Result.NumberOfRecordsB <= 1 Then
				
				ConditionsProhibitOutputRowCompleted = False;
				
				If Not ConditionsProhibitOutputRowsDisabled Then 
					Try
						Execute CodeForProhibitingOutputRows; 
					Except
						If Not ErrorMessageWhenExecutingCodeToForbidRowOutput Then
							ErrorText = ErrorDescription();
							Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ErrorText);						
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
					
					ИмяРеквизита = "РеквизитА" + AttributesCounter;
					If TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог And TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = False Then
						Try
							пЗначениеРеквизита = RowTP_Result[ИмяРеквизита];
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
									EndIf;
								Иначе
									TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
								EndIf;
							EndIf;
						Except
							TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = True;
						EndTry;
					EndIf;
					
					ИмяРеквизита = "AttributeB" + AttributesCounter;
					Если TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог И TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = False Then
						Попытка
							пЗначениеРеквизита = RowTP_Result[ИмяРеквизита];
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
									EndIf;
								Иначе
									TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
								EndIf;
							EndIf;
						Исключение
							TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
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
							Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ErrorText);						
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
							Message(Format(CurrentDate(),"ДЛФ=DT") + ": " + ErrorText);
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
															
					ИмяРеквизита = "AttributeB" + AttributesCounter;
					Если TotalsByAttributesMap[ИмяРеквизита].РассчитыватьИтог И TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Ложь Тогда
						Попытка
							пЗначениеРеквизита = RowTP_Result[ИмяРеквизита];
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
									EndIf;
								Иначе
									TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
								EndIf;
							EndIf;
						Исключение
							TotalsByAttributesMap[ИмяРеквизита].ОшибкаПриВычислении = Истина;
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
					
		ИмяРеквизита = "РеквизитА" + AttributesCounter;
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
				EndIf;
			EndIf;
		
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "A" + AttributesCounter + ": " + TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога;
		
		Иначе
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "";
		EndIf;
		
		ИмяРеквизита = "AttributeB" + AttributesCounter;
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
				EndIf;
			EndIf;
			
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "B" + AttributesCounter + ": " + TotalsByAttributesMap[ИмяРеквизита].ЗначениеИтога;
			
		Иначе
			ЭтотОбъект["ЗначениеИтога" + ИмяРеквизита] = "";
		EndIf;
		
	EndDo;

	Если SortTableDifferences Тогда
		Result.Сортировать(OrderSortTableDifferences);
	EndIf;
		
	If MessageHaveMultipleRowsOneKey Then
		Message(Формат(ТекущаяДата(),"ДЛФ=DT") + ": Обнаружены дубликаты (подсвечены красным цветом), настройки отбора на них не распространяются. Просмотреть дублирующиеся строки можно на форме предварительного просмотра.");
	EndIf;
	
EndProcedure

Function ReadDataAndGetValueTable(BaseID, ErrorText = "", Connection = Undefined) Export
	
	//Current or external base 1C 8
	If ThisObject["BaseType" + BaseID] = 0 Or ThisObject["BaseType" + BaseID] = 1 Then
		 ТЗ = ВыполнитьЗапрос1С8ИПолучитьТЗ(BaseID, ErrorText, Connection);
	//SQL
	ElsIf ThisObject["BaseType" + BaseID] = 2 Then		
		ТЗ = ВыполнитьЗапросSQLИПолучитьТЗ(BaseID, ErrorText);
	//File
	ElsIf ThisObject["BaseType" + BaseID] = 3 Then
		ТЗ = ПрочитатьДанныеИзФайлаИПолучитьТЗ(BaseID, ErrorText);
	//Table
	ElsIf ThisObject["BaseType" + BaseID] = 4 Then		
		ТЗ = ПолучитьДанныеИзТабличногоДокумента(BaseID, ErrorText);
	//Outer база 1С 7.7
	ElsIf ThisObject["BaseType" + BaseID] = 5 Then		
		ТЗ = ВыполнитьЗапрос1С77ИПолучитьТЗ(BaseID, ErrorText);
	//JSON
	ElsIf ThisObject["BaseType" + BaseID] = 6 Then		
		ТЗ = ПрочитатьДанныеИзJSONИПолучитьТЗ(BaseID, ErrorText);
	Else
		ErrorText = "Type базы " + BaseID + " '" + ThisObject["BaseType" + BaseID] + "' не предусмотрен";
		Message(Формат(ТекущаяДата(),"ДЛФ=DT") + ": " + ErrorText);
		ТЗ = Undefined;
	EndIf;
	
	If ThisObject["BaseType" + BaseID] >= 3 And ThisObject["CollapseTable" + BaseID] Then
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

Function ВыполнитьЗапрос1С8ИПолучитьТЗ(BaseID, ErrorsText = "", Connection = Undefined)
	
	//Current
	If ThisObject["BaseType" + BaseID] = 0 Then
		
		Query = New Query;
		Query.Text = ThisObject["QueryText" + BaseID];
		
		SetParameters(Query, BaseID); 
		
	//Outer
	ElsIf ThisObject["BaseType" + BaseID] = 1 Then
		
		If ThisObject["WorkOptionExternalBase" + BaseID] = 0 Then
			ПараметрСоединения = 
				"File=""" + ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"]
				+ """;Usr=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Login"]
				+ """;Pwd=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Password"] + """;";	
		Else
			ПараметрСоединения = 
				"Srvr=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Server"]
				+ """;Ref=""" + ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"] 
				+ """;Usr=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Login"] 
				+ """;Pwd=""" + ThisObject["ConnectionToExternalBase" + BaseID + "Password"] + """;";
		EndIf;
				
		Try
			COMConnector = New COMObject(ThisObject["ВерсияПлатформыВнешнейБазы" + BaseID] + ".COMConnector");
			Connection = COMConnector.Connect(ПараметрСоединения);
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
		ТЗ = Query.Execute().Unload();
	Except
		ErrorText = ErrorDescription();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		ТЗ = Undefined;
	EndTry;
	
	If ТЗ <> Undefined Then
				
		ЧислоКолонокВТЗ = ТЗ.Columns.Count();
		If NumberColumnsInKey > ЧислоКолонокВТЗ Then
			ErrorText = "Выборка из источника " + BaseID + " содержит " + ЧислоКолонокВТЗ + " колонок, проверьте корректность заданного числа столбцов в ключе";
			UserMessage = New UserMessage;
			UserMessage.Text = ErrorText;
			UserMessage.Field = "Object.NumberColumnsInKey";
			UserMessage.Message();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndIf;
		    
		For AttributesCounter = 1 To Min(ЧислоКолонокВТЗ - NumberColumnsInKey, NumberOfRequisites) Do //
			
			Если ЭтотОбъект["SettingsFile" + BaseID].Количество() >= AttributesCounter Тогда
				ЗаголовокРеквизитаИзНастроек = ЭтотОбъект["SettingsFile" + BaseID][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			Иначе
				ЗаголовокРеквизитаИзНастроек = "";
			EndIf;
			
			ИмяРеквизита = String(BaseID) + AttributesCounter;			
			ViewsHeadersAttributes[ИмяРеквизита] = ИмяРеквизита + ": " + ?(ПустаяСтрока(ЗаголовокРеквизитаИзНастроек), ТЗ.Колонки.Get(AttributesCounter + NumberColumnsInKey - 1).Title, ЗаголовокРеквизитаИзНастроек);
			
		
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
			
			If ThisObject["UseAsKeyUniqueIdentifier" + BaseID]
				Or ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
				
				ИмяКолонкиКлюч1 = "Key1" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
				ТЗ.Columns.Insert(НомерКолонкиКлюч1, ИмяКолонкиКлюч1);
				НомерКолонкиКлюч2 = НомерКолонкиКлюч2 + 1;
				НомерКолонкиКлюч3 = НомерКолонкиКлюч3 + 1;

			EndIf;
		
			If NumberColumnsInKey > 1 Then
			
				If ThisObject["UseAsKey2UniqueIdentifier" + BaseID]
					Or ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ИмяКолонкиКлюч2 = "Key2" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(НомерКолонкиКлюч2, ИмяКолонкиКлюч2);
					НомерКолонкиКлюч3 = НомерКолонкиКлюч3 + 1;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ThisObject["UseAsKey3UniqueIdentifier" + BaseID]
					Or ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
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
					
					If ThisObject["UseAsKeyUniqueIdentifier" + BaseID] Then
						If ThisObject["BaseType" + BaseID] = 0 Then
							СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(XMLString(СтрокаТЗ[ИмяПервойКолонки]));
						Else
							СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Connection.XMLString(СтрокаТЗ[ИмяПервойКолонки]));
						EndIf;
					ElsIf ThisObject["CastKeyToString" + BaseID]
						Or ThisObject["CastKeyToUpperCase" + BaseID]
						Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(String(СтрокаТЗ[ИмяПервойКолонки]));
					EndIf;
					
					If ThisObject["KeyLengthWhenCastingToString" + BaseID] > 0 Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Left(СтрокаТЗ[ИмяКолонкиКлюч1], ThisObject["KeyLengthWhenCastingToString" + BaseID]));
					EndIf;
						
					If ThisObject["CastKeyToUpperCase" + BaseID] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч1])));
					EndIf;
					
					If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч1]), "{", ""), "}", ""));
					EndIf;
					
				Except
					
					ErrorText = "Ошибка при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
				If NumberColumnsInKey > 1 Then
						
					Try
						
						If ThisObject["UseAsKey2UniqueIdentifier" + BaseID] Then
							If ThisObject["BaseType" + BaseID] = 0 Then
								СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(XMLString(СтрокаТЗ[ИмяВторойКолонки]));
							Else
								СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Connection.XMLString(СтрокаТЗ[ИмяВторойКолонки]));
							EndIf;
						ElsIf ThisObject["CastKey2ToString" + BaseID]
							Or ThisObject["CastKey2ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(String(СтрокаТЗ[ИмяВторойКолонки]));
						EndIf;

						
						If ThisObject["KeyLength2WhenCastingToString" + BaseID] > 0 Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Left(СтрокаТЗ[ИмяКолонкиКлюч2], ThisObject["KeyLengthWhenCastingToString" + BaseID]));
						EndIf;
						
						If ThisObject["CastKey2ToUpperCase" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч2])));
						EndIf;
						
						If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч2]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
						
					Try
						
						If ThisObject["UseAsKey3UniqueIdentifier" + BaseID] Then
							If ThisObject["BaseType" + BaseID] = 0 Then
								СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(XMLString(СтрокаТЗ[ИмяТретьейКолонки]));
							Else
								СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Connection.XMLString(СтрокаТЗ[ИмяТретьейКолонки]));
							EndIf;
						ElsIf ThisObject["CastKey3ToString" + BaseID]
							Or ThisObject["CastKey3ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(String(СтрокаТЗ[ИмяТретьейКолонки]));
						EndIf;
						
						If ThisObject["KeyLength3WhenCastingToString" + BaseID] > 0 Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Left(СтрокаТЗ[ИмяКолонкиКлюч3], ThisObject["KeyLengthWhenCastingToString" + BaseID]));
						EndIf;
						
						If ThisObject["CastKey3ToUpperCase" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч3])));
						EndIf;
						
						If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч3]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
						
#Region Произвольный_код_обработки_ключа

				КлючТек = СтрокаТЗ[ИмяКолонкиКлюч1];
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + КлючТек + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаТЗ[ИмяКолонкиКлюч1] = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч2];
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + КлючТек + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч2] = КлючТек;
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч3];
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + КлючТек + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч3] = КлючТек;
				EndIf;
	
#EndRegion
				
			EndDo;
			
			If ThisObject["UseAsKeyUniqueIdentifier" + BaseID] 
				Or ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
			
				ТЗ.Columns.Delete(ИмяПервойКолонки);
			
			EndIf;
		
			If NumberColumnsInKey > 1 Then
								
				If ThisObject["UseAsKey2UniqueIdentifier" + BaseID] 
					Or ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ТЗ.Columns.Delete(ИмяВторойКолонки);
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
								
				If ThisObject["UseAsKey3UniqueIdentifier" + BaseID] 
					Or ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ТЗ.Columns.Delete(ИмяТретьейКолонки);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ВыполнитьЗапрос1С77ИПолучитьТЗ(BaseID, ErrorsText = "", Connection = Undefined)
	
	PathBase = ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"];
	User = ThisObject["ConnectionToExternalBase" + BaseID + "Login"];
	Password = ThisObject["ConnectionToExternalBase" + BaseID + "Password"];
		
	Connection = New COMObject("V1CEnterprise.Application");
    
    Try   
		
		СтрокаПодключения = "/D"""+TrimAll(PathBase)+""" /N"""+TrimAll(User)+""" /P"""+TrimAll(Password)+"""";
        ConnectionInstalled = Connection.Initialize(Connection.RMTrade,СтрокаПодключения,"NO_SPLASH_SHOW");
        
        If ConnectionInstalled Then
            YesConnection = True;
        Else
            ErrorText = "Error при подключении к внешней базе";
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
        EndIf;    
    Except
        ErrorText = "Error при подключении к внешней базе: " + ErrorDescription();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		Return Undefined;
	EndTry;
		
	Query = Connection.CreateObject("Query");
	QueryText = ThisObject["QueryText" + BaseID];
	
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
	
	ТаблицаЗначений1С77 = Connection.CreateObject("ValueTable");
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
			
			If ThisObject["CastKeyToString" + BaseID] Then
				Ключ1 = TrimAll(String(Ключ1));
			EndIf;
		
			If ThisObject["CastKeyToUpperCase" + BaseID] Then
				Ключ1 = TrimAll(Upper(String(Ключ1)));
			EndIf;
			
			If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
				Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
			EndIf;
			
		Except
			
			ErrorText = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			
		EndTry;
		
		If NumberColumnsInKey > 1 Then
			
			Try
			
				If ThisObject["CastKey2ToString" + BaseID] Then
					Ключ2 = TrimAll(String(Ключ2));
				EndIf;
			
				If ThisObject["CastKey2ToUpperCase" + BaseID] Then
					Ключ2 = TrimAll(Upper(String(Ключ2)));
				EndIf;
				
				If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
				EndIf;
			
			Except
				
				ErrorText = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			EndTry;
			
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			Try
			
			If ThisObject["CastKey3ToString" + BaseID] Then
				Ключ3 = TrimAll(String(Ключ3));
			EndIf;
		
			If ThisObject["CastKey3ToUpperCase" + BaseID] Then
				Ключ3 = TrimAll(Upper(String(Ключ3)));
			EndIf;
			
			If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
				Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
			EndIf;
			
			Except
				
				ErrorText = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			EndTry;
			
		EndIf;
			          			
#Region Произвольный_код_обработки_ключа

			КлючТек = Ключ1;
			If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
				Except
					ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
					Message(ErrorText);
				EndTry;
			EndIf;
			СтрокаТЗ.Key1 = КлючТек;
			
			If NumberColumnsInKey > 1 Then
				КлючТек = Ключ2;				
				If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаТЗ.Key2 = КлючТек;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				КлючТек = Ключ3;
				If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаТЗ.Key3 = КлючТек;
			EndIf;
			
#EndRegion 
			
		For СчетчикКолонок = 1 To Min(NumberOfRequisites, ColumnsCount - NumberColumnsInKey) Do    
			
			//ColumnName = = ТаблицаЗначений1С77.ПолучитьПараметрыКолонки(СчетчикКолонок);
			CellValue = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, СчетчикКолонок + NumberColumnsInKey);
			СтрокаТЗ["Attribute" + СчетчикКолонок] = CellValue;
			
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
	
	//ТаблицаЗначений1С77 = CreateObject("ValueTable");
	//Query.Unload(ТаблицаЗначений1С77,1,0);	
	//LineCount = ТаблицаЗначений1С77.LineCount();
	//ColumnsCount = ТаблицаЗначений1С77.ColumnsCount();
	//For СчетчикСтрок = 1 To LineCount Do
	//	ВсяСтрока = "";
	//	For СчетчикКолонок = 1 To ТаблицаЗначений1С77.ColumnsCount() Do    
	//		//ColumnName = = ТаблицаЗначений1С77.ПолучитьПараметрыКолонки(СчетчикКолонок);
	//		CellValue = ТаблицаЗначений1С77.GetValue(СчетчикСтрок, СчетчикКолонок); 
	//		ВсяСтрока = ВсяСтрока + ", " + CellValue;
	//	EndDo;
	//	Message(ВсяСтрока);
	//	
	//EndDo
	
//#Region Заполнение_ТЗ
	
	If ТЗ <> Undefined Then
		
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
			
			If ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
				
				ИмяКолонкиКлюч1 = "Key1" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
				ТЗ.Columns.Insert(0, ИмяКолонкиКлюч1);//, ОписаниеСтроки);

			EndIf;
		
			If NumberColumnsInKey > 1 Then
			
				If ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ИмяКолонкиКлюч2 = "Key2" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(1, ИмяКолонкиКлюч2);
				EndIf;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ИмяКолонкиКлюч3 = "Key3" + Format(CurrentDate(), "ДФ=ddMMyyyyHHmmss");
					ТЗ.Columns.Insert(2, ИмяКолонкиКлюч3);
				EndIf;
			EndIf;
			       						
			СчетчикСтрок = 0;			
			For Each СтрокаТЗ In ТЗ Do
				
				СчетчикСтрок = СчетчикСтрок + 1;
				
				Try
					
					If ThisObject["CastKeyToString" + BaseID]
						Or ThisObject["CastKeyToUpperCase" + BaseID]
						Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(String(СтрокаТЗ[ИмяПервойКолонки]));
					EndIf;
						
					If ThisObject["CastKeyToUpperCase" + BaseID] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч1])));
					EndIf;
					
					If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
						СтрокаТЗ[ИмяКолонкиКлюч1] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч1]), "{", ""), "}", ""));
					EndIf;
					
				Except
					
					ErrorText = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
				If NumberColumnsInKey > 1 Then
						
					Try
						
						If ThisObject["CastKey2ToString" + BaseID]
							Or ThisObject["CastKey2ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(String(СтрокаТЗ[ИмяВторойКолонки]));
						EndIf;

						If ThisObject["CastKey2ToUpperCase" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч2])));
						EndIf;
						
						If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч2] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч2]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
						
					Try
						
						If ThisObject["CastKey3ToString" + BaseID]
							Or ThisObject["CastKey3ToUpperCase" + BaseID]
							Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(String(СтрокаТЗ[ИмяТретьейКолонки]));
						EndIf;
						
						If ThisObject["CastKey3ToUpperCase" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(Upper(String(СтрокаТЗ[ИмяКолонкиКлюч3])));
						EndIf;
						
						If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
							СтрокаТЗ[ИмяКолонкиКлюч3] = TrimAll(StrReplace(StrReplace(String(СтрокаТЗ[ИмяКолонкиКлюч3]), "{", ""), "}", ""));
						EndIf;
						
					Except
						
						ErrorText = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndTry;
					
				EndIf;
						
	#Region Произвольный_код_обработки_ключа

				КлючТек = СтрокаТЗ[ИмяКолонкиКлюч1];
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + КлючТек + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаТЗ[ИмяКолонкиКлюч1] = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч2];
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + КлючТек + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч2] = КлючТек;
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					КлючТек = СтрокаТЗ[ИмяКолонкиКлюч3];
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + КлючТек + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаТЗ[ИмяКолонкиКлюч3] = КлючТек;
				EndIf;

	#EndRegion
				
			EndDo;
			
			If ThisObject["CastKeyToString" + BaseID] 
				Or ThisObject["CastKeyToUpperCase" + BaseID] 
				Or ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
			
				ТЗ.Columns.Delete(ИмяПервойКолонки);
			
			EndIf;
		
			If NumberColumnsInKey > 1 Then
								
				If ThisObject["CastKey2ToString" + BaseID] 
					Or ThisObject["CastKey2ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
					
					ТЗ.Columns.Delete(ИмяВторойКолонки);
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
								
				If ThisObject["CastKey3ToString" + BaseID] 
					Or ThisObject["CastKey3ToUpperCase" + BaseID] 
					Or ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					
					ТЗ.Columns.Delete(ИмяТретьейКолонки);
					
				EndIf;
				
			EndIf;
			
		EndIf;
	
//#EndRegion
	
		//Индексирование
		КолонкиСКлючомСтрокой = ИмяКолонкиКлюч1;
		Если NumberColumnsInKey > 1 Тогда
			КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + "," + ИмяКолонкиКлюч2;
		EndIf;
		Если NumberColumnsInKey > 2 Тогда
			КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + "," + ИмяКолонкиКлюч3;
		EndIf;

		ТЗ.Индексы.Добавить(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 По ЭтотОбъект["SettingsFile" + BaseID].Количество() Цикл
			
			ИмяРеквизита = Строка(BaseID) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ЭтотОбъект["SettingsFile" + BaseID][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ViewsHeadersAttributes[ИмяРеквизита] = ?(ПустаяСтрока(ЗаголовокРеквизитаИзНастроек), "Реквизит " + BaseID + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ВыполнитьЗапросSQLИПолучитьТЗ(BaseID, ErrorsText = "")
	
	ServerName =  ThisObject["ConnectionToExternalBase" + BaseID + "Server"];
	DSN 	= ThisObject["ConnectionToExternalBase" + BaseID + "PathBase"];                                                                                                           
	UID 	= ThisObject["ConnectionToExternalBase" + BaseID + "Login"];
	PWD 	= ThisObject["ConnectionToExternalBase" + BaseID + "Password"];
	Driver 	= ThisObject["ConnectionToExternalBase" + BaseID + "ДрайверSQL"];
	
	Try              
		ConnectString = "Driver={" + Driver + "};Server="+ServerName+";Database="+DSN+";Uid="+UID+";Pwd="+PWD;
		Соединение = New COMObject("ADODB.Connection");
		Соединение.Open(ConnectString); 
	Except
		ErrorText = ErrorDescription();
		Message("Not удалось подключиться к : " + ErrorText);
		Return Undefined;
	EndTry;
	
	OffsetNumberAttribute = NumberColumnsInKey - 1;
		
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
		Command.CommandText = ThisObject["QueryText" + BaseID];
		Command.CommandType = 1;
		
		Рекордсет = Command.Execute();
		
		ЧислоКолонокВТЗ = Рекордсет.Fields.Count;
		If NumberColumnsInKey > ЧислоКолонокВТЗ Then
			
			ErrorText = "Выборка из источника " + BaseID + " содержит " + ЧислоКолонокВТЗ + " кол., проверьте корректность заданного числа столбцов в ключе";
			UserMessage = New UserMessage;
			UserMessage.Text = ErrorText;
			UserMessage.Field = "Object.NumberColumnsInKey";
			UserMessage.Message();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Рекордсет.Close();
			Соединение.Close();
			
			Return Undefined;
			
		EndIf;
				
		СчетчикСтрок = 0;			
		While Рекордсет.EOF = 0 Do
			
			СчетчикСтрок = СчетчикСтрок + 1;
			
			If СчетчикСтрок = 1 Then
				
				For AttributesCounter = 1 To Min(ЧислоКолонокВТЗ - NumberColumnsInKey, NumberOfRequisites) Do
					
					Если ЭтотОбъект["SettingsFile" + BaseID].Количество() >= AttributesCounter Тогда
						ЗаголовокРеквизитаИзНастроек = ЭтотОбъект["SettingsFile" + BaseID][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
					Иначе
						ЗаголовокРеквизитаИзНастроек = "";
					EndIf;
					
					ИмяРеквизита = String(BaseID) + AttributesCounter;					
					ViewsHeadersAttributes[ИмяРеквизита] = ИмяРеквизита + ": " + ?(ПустаяСтрока(ЗаголовокРеквизитаИзНастроек), Рекордсет.Fields(AttributesCounter + NumberColumnsInKey - 1).Name, ЗаголовокРеквизитаИзНастроек);
					
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
				
				If ThisObject["CastKeyToString" + BaseID] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
				
			Except
				
				ErrorText = "Error при обработке ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			EndTry;
			
			If NumberColumnsInKey > 1 Then
				
				Try
				
					If ThisObject["CastKey2ToString" + BaseID] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
				
				Except
					
					ErrorText = "Error при обработке столбца 2 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				
				Try
				
				If ThisObject["CastKey3ToString" + BaseID] Then
					Ключ3 = TrimAll(String(Ключ3));
				EndIf;
			
				If ThisObject["CastKey3ToUpperCase" + BaseID] Then
					Ключ3 = TrimAll(Upper(String(Ключ3)));
				EndIf;
				
				If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
					Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
				EndIf;
				
				Except
					
					ErrorText = "Error при обработке столбца 3 ключа в строке " + СчетчикСтрок + " выборки из базы " + BaseID + ": " + ErrorDescription();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndTry;
				
			EndIf;
			          			
#Region Произвольный_код_обработки_ключа

			КлючТек = Ключ1;
			If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
				Except
					ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
					Message(ErrorText);
				EndTry;
			EndIf;
			СтрокаТЗ.Key1 = КлючТек;
			
			If NumberColumnsInKey > 1 Then
				КлючТек = Ключ2;				
				If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаТЗ.Key2 = КлючТек;
			EndIf;
			
			If NumberColumnsInKey > 2 Then
				КлючТек = Ключ3;
				If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаТЗ.Key3 = КлючТек;
			EndIf;
			
#EndRegion 
			
			ЧислоКолонокВВыборке = Рекордсет.Fields.Count;
			
			For Счетчик = 1 To Min(NumberOfRequisites, ЧислоКолонокВВыборке - NumberColumnsInKey) Do
				СтрокаТЗ["Attribute" + Счетчик] = Рекордсет.Fields(Счетчик + NumberColumnsInKey - 1).Value 
			EndDo;
			
			Рекордсет.MoveNext();
			
		EndDo;

		Рекордсет.Close();
		Соединение.Close();
		
	Except
		
		ErrorText = ErrorDescription();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		ТЗ = Undefined;
		
	EndTry;
	
	//Indexing
	If ТЗ <> Undefined Then
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ПрочитатьДанныеИзФайлаИПолучитьТЗ(BaseID, ErrorsText = "")
	
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
	
	ПутьКФайлу 			= ThisObject["ConnectionToExternalBase"		+ BaseID + "ПутьКФайлу"];
	ФорматФайла 		= ThisObject["ConnectionToExternalBase" 		+ BaseID + "ФорматФайла"];
	НомерПервойСтроки 	= ThisObject["НомерПервойСтрокиФайла" 		+ BaseID];
	SettingsFile 		= ThisObject["SettingsFile" 				+ BaseID];
	НомерТаблицы		= ThisObject["ConnectionToExternalBase"		+ BaseID + "НомерТаблицыВФайле"];
	
	НомерСтолбцаСКлючом = ThisObject["ColumnNumberKeyFromFile" 	+ BaseID];
	ИмяСтолбцаСКлючом 	= ThisObject["ColumnNameKeyFromFile" 	+ BaseID];	
	If NumberColumnsInKey > 1 Then
		НомерСтолбцаСКлючом2 	= ThisObject["ColumnNumberKey2FromFile" + BaseID];
		ИмяСтолбцаСКлючом2 		= ThisObject["ColumnNameKey2FromFile" + BaseID];
	EndIf;	
	If NumberColumnsInKey > 2 Then
		НомерСтолбцаСКлючом3 	= ThisObject["ColumnNumberKey3FromFile" + BaseID];
		ИмяСтолбцаСКлючом3 		= ThisObject["ColumnNameKey3FromFile" + BaseID];
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
			ErrorText = "Error при открытии XLS-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
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
			ErrorText = "Error при открытии DOC-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Word = Undefined;
			Return Undefined;
		EndTry;
		
		Try 
			File = Document.Tables(НомерТаблицы);
		Except
			ErrorText = "Error при обращении к таблице " + НомерТаблицы + " DOC-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
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
			ErrorText = "Error при открытии " + ФорматФайла + "-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndTry;
		
	ElsIf ФорматФайла = "DBF" Then 
		
		Try
			ФайлDBF = New XBase;
			ФайлDBF.OpenFile(ПутьКФайлу,,True);
			НомерПоследнейСтроки = ФайлDBF.RecCount();
			ФайлDBF.First();
		Except
			ErrorText = "Error при открытии DBF-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined;
		EndTry;

	ElsIf ФорматФайла = "XML" Then
		
		Try
			Парсер = New XMLReader;
		    Парсер.OpenFile(ПутьКФайлу);	 
		    Построитель = New DOMBuilder;	 
		    ФайлXML = Построитель.Read(Парсер);
		Except
			ErrorText = "Error при открытии XML-файла " + ПутьКФайлу + ": " + ErrorDescription();
			ErrorsText = ErrorsText + Chars.LF + ErrorText;
			Return Undefined
		EndTry;
		
	Else
		
		ErrorText = "Format файла '" + ФорматФайла + "' не предусмотрен";
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
		Return Undefined;
		
	EndIf;
	
	//Processing строк
//#Region XML
	
	If ФорматФайла = "XML" Then
		
		ИмяРодительскогоУзла = ThisObject["ИмяРодительскогоУзлаФайла" + BaseID];
		ИмяЭлементаСДаннымиФайла = ThisObject["ИмяЭлементаСДаннымиФайла" + BaseID];
		
		КорневойУзел = ФайлXML.DocumentElement;
		If IsBlankString(ИмяРодительскогоУзла) Then
			ParentNode = КорневойУзел
		Else
			ParentNode = FindSlaveNodeXMLFileByName(КорневойУзел, ИмяРодительскогоУзла);
		EndIf;
		
		If ParentNode <> Undefined Then
			
			For Each CurrentItem In ParentNode.ChildNodes Do
				
				If IsBlankString(ИмяЭлементаСДаннымиФайла) Or CurrentItem.NodeName = ИмяЭлементаСДаннымиФайла Then
					
//#Region XML_СпособХраненияДанныхВXMLФайле_В_атрибутах
				
					If ThisObject["СпособХраненияДанныхВXMLФайле" + BaseID] = "В атрибутах" Then
						
						ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
												
						СтрокаПриемник = ТЗ.Add();
						
						Item = CurrentItem.Attributes.GetNamedItem(ИмяСтолбцаСКлючом);
						If Item = Undefined Then
							Raise "Attribute с именем " + ИмяСтолбцаСКлючом + " не найден";
						EndIf;
						
						Ключ1 = Item.Value;
						If ThisObject["CastKeyToUpperCase" + BaseID] Then
							Ключ1 = TrimAll(Upper(String(Ключ1)));
						EndIf;
						If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
							Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
						EndIf;
						
						If NumberColumnsInKey > 1 Then
						
							Item = CurrentItem.Attributes.GetNamedItem(ИмяСтолбцаСКлючом2);
							If Item = Undefined Then
								Raise "Attribute с именем " + ИмяСтолбцаСКлючом2 + " не найден";
							EndIf;
							
							Ключ2 = Item.Value;
									
							If ThisObject["CastKey2ToString" + BaseID] Then
								Ключ2 = TrimAll(String(Ключ2));
							EndIf;
							
							If ThisObject["CastKey2ToUpperCase" + BaseID] Then
								Ключ2 = TrimAll(Upper(String(Ключ2)));
							EndIf;
							
							If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
								Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
							EndIf;
														
						EndIf;
						
						If NumberColumnsInKey > 2 Then
						
							Item = CurrentItem.Attributes.GetNamedItem(ИмяСтолбцаСКлючом3);
							If Item = Undefined Then
								Raise "Attribute с именем " + ИмяСтолбцаСКлючом3 + " не найден";
							EndIf;
							
							Ключ3 = Item.Value;
									
							If ThisObject["CastKey3ToString" + BaseID] Then
								Ключ3 = TrimAll(String(Ключ3));
							EndIf;
							
							If ThisObject["CastKey3ToUpperCase" + BaseID] Then
								Ключ3 = TrimAll(Upper(String(Ключ3)));
							EndIf;
							
							If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
								Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
							EndIf;
							
						EndIf;
						
//#Region Произвольный_код_обработки_ключа

						КлючТек = Ключ1;
						If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
							Try
							    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
							Except
								ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
								Message(ErrorText);
							EndTry;
						EndIf;
						
						СтрокаПриемник.Key1 = КлючТек;
						
						If NumberColumnsInKey > 1 Then
							
							КлючТек = Ключ2;
							If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
								Except
									ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
									Message(ErrorText);
								EndTry;
							EndIf;
							СтрокаПриемник.Key2 = КлючТек;
							
						EndIf;
						
						If NumberColumnsInKey > 2 Then
							
							КлючТек = Ключ3;
							If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
								Except
									ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
									Message(ErrorText);
								EndTry;
							EndIf;
							СтрокаПриемник.Key3 = КлючТек;
							
						EndIf;
						
//#EndRegion  

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
						
//#EndRegion

//#Region XML_СпособХраненияДанныхВXMLФайле_В_элементах
						
					ElsIf ThisObject["СпособХраненияДанныхВXMLФайле" + BaseID] = "В элементах" Then
						
						ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
						
						СтрокаПриемник = ТЗ.Add();
						
						For Each ДочернийЭлемент In CurrentItem.ChildNodes Do
							
							If ДочернийЭлемент.NodeName = ИмяСтолбцаСКлючом Then
								
								Ключ1 = ДочернийЭлемент.TextContent;
								If ThisObject["CastKeyToUpperCase" + BaseID] Then
									Ключ1 = TrimAll(Upper(String(Ключ1)));
								EndIf;
								If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
									Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
								EndIf;
								
								СтрокаПриемник.Key1 = Ключ1;
								
							EndIf;
								
							If ДочернийЭлемент.NodeName = ИмяСтолбцаСКлючом2 And NumberColumnsInKey > 1 Then
								
								Ключ2 = ДочернийЭлемент.TextContent;
								If ThisObject["CastKey2ToUpperCase" + BaseID] Then
									Ключ2 = TrimAll(Upper(String(Ключ2)));
								EndIf;
								If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
									Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
								EndIf;
								
								СтрокаПриемник.Key2 = Ключ2;
			                    						
							EndIf;                
							
							If ДочернийЭлемент.NodeName = ИмяСтолбцаСКлючом3 And NumberColumnsInKey > 2 Then
								
								Ключ3 = ДочернийЭлемент.TextContent;
								If ThisObject["CastKey3ToUpperCase" + BaseID] Then
									Ключ3 = TrimAll(Upper(String(Ключ2)));
								EndIf;
								If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
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
						
//#Region Произвольный_код_обработки_ключа
						КлючТек = СтрокаПриемник.Key1;
						If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
							Try
							    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
							Except
								ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
								Message(ErrorText);
							EndTry;
						EndIf;
						СтрокаПриемник.Key1 = КлючТек;
						
						If NumberColumnsInKey > 1 Then
							
							КлючТек = СтрокаПриемник.Key2;
							If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
								Except
									ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
									Message(ErrorText);
								EndTry;
							EndIf;
							СтрокаПриемник.Key2 = КлючТек;
							
						EndIf;
						
						If NumberColumnsInKey > 2 Then
							КлючТек = СтрокаПриемник.Key3;
							If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
								Try
								    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
								Except
									ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
									Message(ErrorText);
								EndTry;
							EndIf;
							СтрокаПриемник.Key3 = КлючТек;
						EndIf;
//#EndRegion 

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
						Raise "Not задан способ хранения данных в XML-файле базы " + BaseID;				
					EndIf;
					
					For Each СтрокаНастроекФайла In SettingsFile Do
				
						ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
						РТек = СтрокаПриемник[ИмяРеквизита];

						Try
							Execute СтрокаНастроекФайла.ArbitraryCode;
						Except
							ErrorText = ErrorDescription();
							Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ErrorText);
						EndTry;
						
						If ThisObject["CollapseTable" + BaseID] Then
							Try
								Execute CodeCastingAttributeToTypeNumber;
							Except
								РТек = 0;
							EndTry;
						EndIf;
						
						СтрокаПриемник[ИмяРеквизита] = РТек;

					EndDo;
					
//#EndRegion

				EndIf;
				
			EndDo; 
			
		EndIf;
		
//#EndRegion 

	Else
	
		For НомерТекущейСтроки = НомерПервойСтроки To НомерПоследнейСтроки Do
			
			ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
			
			СтрокаПриемник = ТЗ.Add();
			
//#Region XLS

			If ФорматФайла = "XLS" Then
				
				ЧислоКолонокВФайлеМеньшеТребуемого = False;
				
				If НомерСтолбцаСКлючом > НомерПоследнейКолонки Then					
					ErrorText = "Файл " + BaseID + " содержит " + НомерПоследнейКолонки + " кол., проверьте настройки столбцов ключа";					
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKeyFromFile " + BaseID;
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					ЧислоКолонокВФайлеМеньшеТребуемого = True;
				EndIf;
				
				If NumberColumnsInKey > 1 And НомерСтолбцаСКлючом2 > НомерПоследнейКолонки Then					
					ErrorText = "Файл " + BaseID + " содержит " + НомерПоследнейКолонки + " кол., проверьте настройки столбца 2 ключа";					
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKey2FromFile " + BaseID;
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					ЧислоКолонокВФайлеМеньшеТребуемого = True;
				EndIf;
				
				If NumberColumnsInKey > 2 And НомерСтолбцаСКлючом3 > НомерПоследнейКолонки Then					
					ErrorText = "Файл " + BaseID + " содержит " + НомерПоследнейКолонки + " кол., проверьте настройки столбца 3 ключа";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKey3FromFile " + BaseID;
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					ЧислоКолонокВФайлеМеньшеТребуемого = True;
				EndIf;
				
				If ЧислоКолонокВФайлеМеньшеТребуемого Then
					
					Книга.Close(0);
					Excel.Quit();
					Return ТЗ;
					
				EndIf;
				
				Ключ1 = TrimAll(File.Cells(НомерТекущейСтроки, НомерСтолбцаСКлючом).Value);
							
				If ThisObject["CastKeyToString" + BaseID] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
				
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
								
				If NumberColumnsInKey > 1 Then			
					
					Ключ2 = TrimAll(File.Cells(НомерТекущейСтроки, НомерСтолбцаСКлючом2).Value);
							
					If ThisObject["CastKey2ToString" + BaseID] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
					     										
				EndIf;
				
				If NumberColumnsInKey > 2 Then
										
					Ключ3 = TrimAll(File.Cells(НомерТекущейСтроки, НомерСтолбцаСКлючом3).Value);
							
					If ThisObject["CastKey3ToString" + BaseID] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
				
				
//#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаПриемник.Key = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
//#EndRegion

				ЗаполнитьПеременныеРЗначениямиПоУмолчанию();
				For Each СтрокаНастроекФайла In SettingsFile Do
					//Not задан номер колонки (например, если реквизит заполняется программно)
					If СтрокаНастроекФайла.НомерКолонки = 0 Then
						Continue;
					EndIf;
					ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
					
					If СтрокаНастроекФайла.НомерКолонки > НомерПоследнейКолонки Then						
						ErrorText = "Файл " + BaseID + " содержит " + НомерПоследнейКолонки + " кол., проверьте настройки колонок реквизитов";						
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.SettingsFile" + BaseID;
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
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
							
//#EndRegion 	

			
//#Region DOC

			ElsIf ФорматФайла = "DOC" Then

				//In документа WORD попадают символы, которые 1С не может вывести в ТЗ на форме и выдает ошибку Text XML содержит недопустимый символ
	        	ЗаменяемыеСимволы = New Array;
				ЗаменяемыеСимволы.Add(Char(7));	//¶
				ЗаменяемыеСимволы.Add(Char(13));	//черный круг
								
				Ключ1 = TrimAll(File.Cell(НомерТекущейСтроки, НомерСтолбцаСКлючом).Range.Text);
				For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
					Ключ1 = StrReplace(Ключ1, ЗаменямыйСимвол, "");
				EndDo;
							
				If ThisObject["CastKeyToString" + BaseID] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
				
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
								
				If NumberColumnsInKey > 1 Then
					
					Ключ2 = TrimAll(File.Cell(НомерТекущейСтроки, НомерСтолбцаСКлючом2).Range.Text);
					For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
						Ключ2 = StrReplace(Ключ2, ЗаменямыйСимвол, "");
					EndDo;
					
					If ThisObject["CastKey2ToString" + BaseID] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
					     										
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					Ключ3 = TrimAll(File.Cell(НомерТекущейСтроки, НомерСтолбцаСКлючом3).Range.Text);
					For Each ЗаменямыйСимвол In ЗаменяемыеСимволы Do 
						Ключ3 = StrReplace(Ключ3, ЗаменямыйСимвол, "");
					EndDo;

							
					If ThisObject["CastKey3ToString" + BaseID] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
				
				
//#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаПриемник.Key = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
//#EndRegion

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
							
//#EndRegion 	


//#Region CSV_TXT

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
				
				If ThisObject["CastKeyToString" + BaseID] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
								
				If NumberColumnsInKey > 1 Then
					
					Ключ2 = StrGetLine(СтрокаМногострочногоТекста,НомерСтолбцаСКлючом2);
				
					If ThisObject["CastKeyToString" + BaseID] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
															
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					Ключ3 = StrGetLine(СтрокаМногострочногоТекста,НомерСтолбцаСКлючом3);
				
					If ThisObject["CastKeyToString" + BaseID] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
				
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
//#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаПриемник.Key1 = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;

				If NumberColumnsInKey > 2 Then
					
					КлючТек = Ключ3;
				 	If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
//#EndRegion 

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

//#EndRegion 	


//#Region DBF

			ElsIf ФорматФайла = "DBF" Then
				
				//На всякий случай, хотя такого не должно быть
				If ФайлDBF.EOF() Then
					Continue;
				EndIf;
				
				Ключ1 = ФайлDBF[ФайлDBF.Fields[НомерСтолбцаСКлючом - 1].Name];
				
				If ThisObject["CastKeyToString" + BaseID] Then
					Ключ1 = TrimAll(String(Ключ1));
				EndIf;
			
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
				
				If NumberColumnsInKey > 1 Then
					
					Ключ2 = ФайлDBF[ФайлDBF.Fields[НомерСтолбцаСКлючом2 - 1].Name];
				
					If ThisObject["CastKey2ToString" + BaseID] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
				
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					Ключ3 = ФайлDBF[ФайлDBF.Fields[НомерСтолбцаСКлючом3 - 1].Name];
				
					If ThisObject["CastKey3ToString" + BaseID] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
				
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
										
				EndIf;
				
//#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				СтрокаПриемник.Key1 = КлючТек;
				
				If NumberColumnsInKey > 1 Then

					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ3 = КлючТек;
					
				EndIf;
				
//#EndRegion  

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

//#EndRegion


//#Region Произвольный_код_заполнения_реквизитов
			
			For Each СтрокаНастроекФайла In SettingsFile Do
				
				ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
				РТек = СтрокаПриемник[ИмяРеквизита];

				Try
					Execute СтрокаНастроекФайла.ПроизвольныйКод;
				Except
					ErrorText = ErrorDescription();
					Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ErrorText);
				EndTry;
				
				If ThisObject["CollapseTable" + BaseID] Then
					Try
						Execute CodeCastingAttributeToTypeNumber;
					Except
						РТек = 0;
					EndTry;
				EndIf;
				
				СтрокаПриемник[ИмяРеквизита] = РТек;
								
			EndDo;
			
//#EndRegion 

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
	
	If ТЗ <> Undefined Then
		
		//Indexing
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + BaseID].Count() Do
			
			ИмяРеквизита = String(BaseID) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ViewsHeadersAttributes[ИмяРеквизита] = ?(IsBlankString(ЗаголовокРеквизитаИзНастроек), "Attribute " + BaseID + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ПрочитатьДанныеИзJSONИПолучитьТЗ(BaseID, ErrorsText = "")
	
	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key");
	КолонкиСКлючомСтрокой = "Key";
	
	If NumberColumnsInKey > 1 Then
		ТЗ.Columns.Add("Ключ2");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ТЗ.Columns.Add("Ключ3");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ3";
	EndIf;
	
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	//ПутьКФайлу 			= ThisObject["ConnectionToExternalBase"		+ BaseID + "ПутьКФайлу"];
	//ФорматФайла 		= ThisObject["ConnectionToExternalBase" 		+ BaseID + "ФорматФайла"];
	//НомерПервойСтроки 	= ThisObject["НомерПервойСтрокиФайла" 		+ BaseID];
	SettingsFile 		= ThisObject["SettingsFile" 				+ BaseID];
	//НомерТаблицы		= ThisObject["ConnectionToExternalBase"		+ BaseID + "НомерТаблицыВФайле"];
	ИмяЭлементаСДаннымиФайла = ThisObject["ИмяЭлементаСДаннымиФайла" + BaseID];
	
	НомерСтолбцаСКлючом = ThisObject["ColumnNumberKeyFromFile" 	+ BaseID];
	ИмяСтолбцаСКлючом 	= ThisObject["ColumnNameKeyFromFile" 	+ BaseID];	
	If NumberColumnsInKey > 1 Then
		НомерСтолбцаСКлючом2 	= ThisObject["ColumnNumberKey2FromFile" + BaseID];
		ИмяСтолбцаСКлючом2 		= ThisObject["ColumnNameKey2FromFile" + BaseID];
	EndIf;	
	If NumberColumnsInKey > 2 Then
		НомерСтолбцаСКлючом3 	= ThisObject["ColumnNumberKey3FromFile" + BaseID];
		ИмяСтолбцаСКлючом3 		= ThisObject["ColumnNameKey3FromFile" + BaseID];
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(ThisObject["QueryText" + BaseID]);
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
					ErrorText = "Attribute JSON с именем " + ИмяСтолбцаСКлючом + " не найден";
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					Return Undefined;
				EndTry; 
				
				Ключ1 = ТекущееЗначениеJSON[ИмяСтолбцаСКлючом];
				
				If ThisObject["CastKeyToUpperCase" + BaseID] Then
					Ключ1 = TrimAll(Upper(String(Ключ1)));
				EndIf;
				If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
					Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
				EndIf;
				
				If NumberColumnsInKey > 1 Then
				
					Try				
						If Not ТекущееЗначениеJSON.Property(ИмяСтолбцаСКлючом2) Then
							Raise "Attribute JSON с именем " + ИмяСтолбцаСКлючом2 + " не найден";
						EndIf;
					Except
						ErrorText = "Attribute JSON с именем " + ИмяСтолбцаСКлючом2 + " не найден";
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						Return Undefined;
					EndTry; 
					
					Ключ2 = ТекущееЗначениеJSON[ИмяСтолбцаСКлючом2];
							
					If ThisObject["CastKey2ToString" + BaseID] Then
						Ключ2 = TrimAll(String(Ключ2));
					EndIf;
					
					If ThisObject["CastKey2ToUpperCase" + BaseID] Then
						Ключ2 = TrimAll(Upper(String(Ключ2)));
					EndIf;
					
					If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
						Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
					EndIf;
												
				EndIf;
				
				If NumberColumnsInKey > 2 Then
				
					Try				
						If Not ТекущееЗначениеJSON.Property(ИмяСтолбцаСКлючом3) Then
							Raise "Attribute JSON с именем " + ИмяСтолбцаСКлючом3 + " не найден";
						EndIf;
					Except
						ErrorText = "Attribute JSON с именем " + ИмяСтолбцаСКлючом3 + " не найден";
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						Return Undefined;
					EndTry; 
					
					Ключ3 = ТекущееЗначениеJSON[ИмяСтолбцаСКлючом3];
							
					If ThisObject["CastKey3ToString" + BaseID] Then
						Ключ3 = TrimAll(String(Ключ3));
					EndIf;
					
					If ThisObject["CastKey3ToUpperCase" + BaseID] Then
						Ключ3 = TrimAll(Upper(String(Ключ3)));
					EndIf;
					
					If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
						Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
					EndIf;
					
				EndIf;
					
#Region Произвольный_код_обработки_ключа

				КлючТек = Ключ1;
				If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
					Try
					    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
					Except
						ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
						Message(ErrorText);
					EndTry;
				EndIf;
				
				СтрокаПриемник.Key1 = КлючТек;
				
				If NumberColumnsInKey > 1 Then
					
					КлючТек = Ключ2;
					If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
						EndTry;
					EndIf;
					СтрокаПриемник.Ключ2 = КлючТек;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
					
					КлючТек = Ключ3;
					If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
						Try
						    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
						Except
							ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
							Message(ErrorText);
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
						ErrorText = "Attribute JSON с именем " + СтрокаНастроекФайла.ColumnName + " не найден";
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
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
						ErrorText = ErrorDescription();
						Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ErrorText);
					EndTry;
					
					If ThisObject["CollapseTable" + BaseID] Then
						Try
							Execute CodeCastingAttributeToTypeNumber;
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
		
	If ТЗ <> Undefined Then
		
		//Indexing
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + BaseID].Count() Do
			
			ИмяРеквизита = String(BaseID) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ViewsHeadersAttributes[ИмяРеквизита] = ?(IsBlankString(ЗаголовокРеквизитаИзНастроек), "Attribute " + BaseID + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

Function ПолучитьДанныеИзТабличногоДокумента(BaseID, ErrorsText = "")
	
	ТЗ = New ValueTable;
	ТЗ.Columns.Add("Key");
	КолонкиСКлючомСтрокой = "Key";
	
	If NumberColumnsInKey > 1 Then
		ТЗ.Columns.Add("Ключ2");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ2";
	EndIf;
	
	If NumberColumnsInKey > 2 Then
		ТЗ.Columns.Add("Ключ3");
		КолонкиСКлючомСтрокой = КолонкиСКлючомСтрокой + ",Ключ3";
	EndIf;
	
	ТЗ.Columns.Add("Реквизит1");
	ТЗ.Columns.Add("Реквизит2");
	ТЗ.Columns.Add("Реквизит3");
	ТЗ.Columns.Add("Реквизит4");
	ТЗ.Columns.Add("Реквизит5");
	
	НомерПервойСтроки 	= ThisObject["НомерПервойСтрокиФайла" + BaseID];
	SettingsFile 		= ThisObject["SettingsFile" + BaseID];
	
	НомерСтолбцаСКлючом = ThisObject["ColumnNumberKeyFromFile" + BaseID];
	If NumberColumnsInKey > 1 Then
		НомерСтолбцаСКлючом2 = ThisObject["ColumnNumberKey2FromFile" + BaseID];
	EndIf;
	If NumberColumnsInKey > 2 Then
		НомерСтолбцаСКлючом3 = ThisObject["ColumnNumberKey3FromFile" + BaseID];
	EndIf;
	
	НомерТекущейСтроки = НомерПервойСтроки;	
	ТекущееЧислоСтрокСПустымиКлючами = 0;
	While True Do
		
		Ключ1 = ThisObject["Table" + BaseID].Region(НомерТекущейСтроки,НомерСтолбцаСКлючом,НомерТекущейСтроки,НомерСтолбцаСКлючом).Text;
								
		If ThisObject["CastKeyToString" + BaseID] Then
			Ключ1 = TrimAll(String(Ключ1));
		EndIf;
		
		If ThisObject["CastKeyToUpperCase" + BaseID] Then
			Ключ1 = TrimAll(Upper(String(Ключ1)));
		EndIf;
		
		If ThisObject["DeleteFromKeyCurlyBrackets" + BaseID] Then
			Ключ1 = TrimAll(StrReplace(StrReplace(String(Ключ1), "{", ""), "}", ""));
		EndIf;
						
		If NumberColumnsInKey > 1 Then
			
			Ключ2 = ThisObject["Table" + BaseID].Region(НомерТекущейСтроки,НомерСтолбцаСКлючом2,НомерТекущейСтроки,НомерСтолбцаСКлючом2).Text;
					
			If ThisObject["CastKey2ToString" + BaseID] Then
				Ключ2 = TrimAll(String(Ключ2));
			EndIf;
			
			If ThisObject["CastKey2ToUpperCase" + BaseID] Then
				Ключ2 = TrimAll(Upper(String(Ключ2)));
			EndIf;
			
			If ThisObject["DeleteFromKey2CurlyBrackets" + BaseID] Then
				Ключ2 = TrimAll(StrReplace(StrReplace(String(Ключ2), "{", ""), "}", ""));
			EndIf;
						
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			Ключ3 = ThisObject["Table" + BaseID].Region(НомерТекущейСтроки,НомерСтолбцаСКлючом3,НомерТекущейСтроки,НомерСтолбцаСКлючом3).Text;
					
			If ThisObject["CastKey3ToString" + BaseID] Then
				Ключ3 = TrimAll(String(Ключ3));
			EndIf;
			
			If ThisObject["CastKey3ToUpperCase" + BaseID] Then
				Ключ3 = TrimAll(Upper(String(Ключ3)));
			EndIf;
			
			If ThisObject["DeleteFromKey3CurlyBrackets" + BaseID] Then
				Ключ3 = TrimAll(StrReplace(StrReplace(String(Ключ3), "{", ""), "}", ""));
			EndIf;
						
		EndIf;
						
		If Not ValueIsFilled(Ключ1) Then
			If NumberColumnsInKey > 1 Then
				If Not ValueIsFilled(Ключ2) Then
					If NumberColumnsInKey > 2 Then
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
		If ThisObject["ExecuteArbitraryKeyCode1" + BaseID] Then
			Try
			    Execute ThisObject["ArbitraryKeyCode1" + BaseID];
			Except
				ErrorText = "Error при выполнении произвольного кода (ключ 1: """ + Ключ1 + """) источника " + BaseID + ": " + ErrorDescription();
				Message(ErrorText);
			EndTry;
		EndIf;
		СтрокаПриемник.Key1 = КлючТек;
		
		If NumberColumnsInKey > 1 Then
			
			КлючТек = Ключ2;
			If ThisObject["ExecuteArbitraryKeyCode2" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode2" + BaseID];
				Except
					ErrorText = "Error при выполнении произвольного кода (ключ 2: """ + Ключ2 + """) источника " + BaseID + ": " + ErrorDescription();
					Message(ErrorText);
				EndTry;
			EndIf;
			СтрокаПриемник.Ключ2 = КлючТек;
			
		EndIf;
		
		If NumberColumnsInKey > 2 Then
			
			КлючТек = Ключ3;
			If ThisObject["ExecuteArbitraryKeyCode3" + BaseID] Then
				Try
				    Execute ThisObject["ArbitraryKeyCode3" + BaseID];
				Except
					ErrorText = "Error при выполнении произвольного кода (ключ 3: """ + Ключ3 + """) источника " + BaseID + ": " + ErrorDescription();
					Message(ErrorText);
				EndTry;
			EndIf;
			СтрокаПриемник.Ключ3 = КлючТек;
			
		EndIf;
		
#EndRegion 
		
		For Each СтрокаНастроекФайла In SettingsFile Do
		
			ИмяРеквизита = "Attribute" + СтрокаНастроекФайла.LineNumber;
			СтрокаПриемник[ИмяРеквизита] = TrimAll(ThisObject["Table" + BaseID].Region(НомерТекущейСтроки,СтрокаНастроекФайла.НомерКолонки,НомерТекущейСтроки,СтрокаНастроекФайла.НомерКолонки).Text);
			
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
				ErrorText = ErrorDescription();
				Message("Error при выполнении произвольного кода (реквизит " + СтрокаНастроекФайла.LineNumber + "):" + ErrorText);
			EndTry;
			
			If ThisObject["CollapseTable" + BaseID] Then
				Try
					Execute CodeCastingAttributeToTypeNumber;
				Except
					РТек = 0;
				EndTry;
			EndIf;
			
			СтрокаПриемник[ИмяРеквизита] = РТек;
							
		EndDo;
		
		НомерТекущейСтроки = НомерТекущейСтроки + 1;
		
	EndDo;
	
	If ТЗ <> Undefined Then
		
		//Indexing
		ТЗ.Indexes.Add(КолонкиСКлючомСтрокой);
		
		For AttributesCounter = 1 To ThisObject["SettingsFile" + BaseID].Count() Do
			
			ИмяРеквизита = String(BaseID) + AttributesCounter;
			ЗаголовокРеквизитаИзНастроек = ThisObject["SettingsFile" + BaseID][AttributesCounter - 1].ЗаголовокРеквизитаДляПользователя;
			
			ViewsHeadersAttributes[ИмяРеквизита] = ?(IsBlankString(ЗаголовокРеквизитаИзНастроек), "Attribute " + BaseID + AttributesCounter, ИмяРеквизита + ": " + ЗаголовокРеквизитаИзНастроек);
		
		EndDo;
		
	EndIf;
	
	Return ТЗ;
	
EndFunction

#EndRegion


#Region Вспомогательные_процедуры_и_функции

Function CheckFillingAttributes(ИсточникДляПредварительногоПросмотра = "", ErrorsText = "") Export
	
	РеквизитыЗаполненыКорректно = True;
	
	If NumberColumnsInKey = 0 Then
		РеквизитыЗаполненыКорректно = False;
		ErrorText = "Not заполнено число столбцов в ключе";
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.NumberColumnsInKey";
		UserMessage.Message();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
	EndIf;
		
	If NumberOfRowsWithEmptyKeysToBreakReading = 0 Then
		РеквизитыЗаполненыКорректно = False;
		ErrorText = "Not заполнено число строк с пустыми ключами для прерывания чтения";
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.NumberOfRowsWithEmptyKeysToBreakReading";
		UserMessage.Message();
		ErrorsText = ErrorsText + Chars.LF + ErrorText;
	EndIf;
	
#Region _1С_8_1С_77_SQL

	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "A" Then
	
		If BaseTypeA >= 0 And BaseTypeA <= 2 Or BaseTypeA = 5 Then
			
			If IsBlankString(QueryTextA) Then
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнен текст запроса к базе А";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextA";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "B" Then
		
		If BaseTypeB >= 0 And BaseTypeB <= 2 Or BaseTypeB = 5 Then
		
			If IsBlankString(QueryTextB) Then
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнен текст запроса к базе Б";
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

	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "A" Then
	
		If BaseTypeA = 3 Or BaseTypeA = 4 Then
				
			If BaseTypeA = 3 And IsBlankString(ConnectionToExternalBaseAFileFormat) Then
				
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнен формат файла А";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ConnectionToExternalBaseAFileFormat";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			ElsIf BaseTypeA = 3 And ConnectionToExternalBaseAFileFormat = "XML" Then
				
				If IsBlankString(ColumnNameKeyFromFileA) Then
				
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя столбца с ключом файла А";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKeyFromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf; 
				
				If NumberColumnsInKey > 1 Then
				
					If ColumnNameKey2FromFileA = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнено имя столбца с ключом 2 файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey2FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
					
				EndIf;
				
				If NumberColumnsInKey > 2 Then
				
					If ColumnNameKey3FromFileA = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнено имя столбца с ключом 3 файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey3FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
					
				EndIf;
				
				If IsBlankString(DataStorageMethodInXMLFileA) Then
				
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен способ хранения данных в файле А";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.DataStorageMethodInXMLFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf;
			
			Else
				
				//For файлов xls и doc должен быть указан номер книги /таблицы
				If BaseTypeA = 3 And (ConnectionToExternalBaseAFileFormat = "XLS" Or ConnectionToExternalBaseAFileFormat = "DOC") Then
					
					If ConnectionToExternalDatabaseANumberTableInFile = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер " + ?(ConnectionToExternalBaseAFileFormat = "XLS", "книги", "таблицы") + " файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConnectionToExternalDatabaseANumberTableInFile";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
					
				EndIf;
				
				If NumberFirstRowFileA = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен номер первой строки файла/таблицы А";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.NumberFirstRowFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If ColumnNumberKeyFromFileA = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен номер столбца с ключом файла/таблицы А";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKeyFromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If NumberColumnsInKey > 1 Then			
					If ColumnNumberKey2FromFileA = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер столбца с ключом 2 файла/таблицы А";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey2FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;			
				EndIf;
				
				If NumberColumnsInKey > 2 Then			
					If ColumnNumberKey3FromFileA = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер столбца с ключом 3 файла/таблицы А";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey3FromFileA";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;			
				EndIf; 
				
				For Each СтрокаТЧ In SettingsFileA Do
					If IsBlankString(СтрокаТЧ.ПроизвольныйКод) And СтрокаТЧ.НомерКолонки = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер колонки файла/таблицы А, соответствующий реквизиту А" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.SettingsFileA[" + (СтрокаТЧ.LineNumber - 1) + "].НомерКолонки";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
				EndDo;
				
			EndIf; 
			
		EndIf;
		
	EndIf; 
	
	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "B" Then
		If BaseTypeB = 3 Or BaseTypeB = 4 Then
				
			If BaseTypeB = 3 And IsBlankString(ConnectionToExternalBaseBFileFormat) Then
				
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнен формат файла Б";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ConnectionToExternalBaseBFileFormat";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
			ElsIf BaseTypeB = 3 And ConnectionToExternalBaseBFileFormat = "XML" Then

				If IsBlankString(ColumnNameKeyFromFileB) Then
				
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя столбца с ключом файла Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKeyFromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				
				EndIf;
				
				If NumberColumnsInKey > 1 Then			
					If ColumnNameKey2FromFileB = 0 Then					
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнено имя столбца с ключом 2 файла Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey2FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;				
				EndIf;
				
				If NumberColumnsInKey > 2 Then			
					If ColumnNameKey3FromFileB = 0 Then					
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнено имя столбца с ключом 3 файла Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNameKey3FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;					
					EndIf;				
				EndIf;
				
				If IsBlankString(DataStorageMethodInXMLFileB) Then
				
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен способ хранения данных в файле Б";
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
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер " + ?(ConnectionToExternalBaseBFileFormat = "XLS", "книги", "таблицы") + " файла А";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConnectionToExternalDatabaseBNumberTableInFile";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
				EndIf;
				
				If NumberFirstRowFileB = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен номер первой строки файла/таблицы Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.NumberFirstRowFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If ColumnNumberKeyFromFileB = 0 Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен номер столбца с ключом файла/таблицы Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNumberKeyFromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If NumberColumnsInKey > 1 Then
				
					If ColumnNumberKey2FromFileB = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер столбца с ключом 2 файла/таблицы Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey2FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
				
				EndIf;
				
				If NumberColumnsInKey > 2 Then
				
					If ColumnNumberKey3FromFileB = 0 Then
						
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер столбца с ключом 3 файла/таблицы Б";
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ColumnNumberKey3FromFileB";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
						
					EndIf;
				
				EndIf;
				
				For Each СтрокаТЧ In SettingsFileB Do
					If IsBlankString(СтрокаТЧ.ПроизвольныйКод) And СтрокаТЧ.НомерКолонки = 0 Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнен номер колонки файла/таблицы Б, соответствующий реквизиту Б" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.SettingsFileB[" + (СтрокаТЧ.LineNumber - 1) + "].НомерКолонки";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
#EndRegion 


 #Region JSON
 
	 If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "A" Then
		 
	 	If BaseTypeA = 6 Then
		 
			If IsBlankString(QueryTextA) Then
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнена строка JSON";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextA";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
						
			If IsBlankString(ColumnNameKeyFromFileA) Then
					
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнено имя столбца с ключом файла А";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ColumnNameKeyFromFileA";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			
			EndIf; 
			
			If NumberColumnsInKey > 1 Then
			
				If ColumnNameKey2FromFileA = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя столбца с ключом 2 файла А";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey2FromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ColumnNameKey3FromFileA = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя столбца с ключом 3 файла А";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey3FromFileA";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf; 
			
		EndIf;
			
	EndIf;
	
	
	If IsBlankString(ИсточникДляПредварительногоПросмотра) Or ИсточникДляПредварительногоПросмотра = "B" Then
			
		If BaseTypeB = 6 Then
		 
			If IsBlankString(QueryTextB) Then
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнена строка JSON";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.QueryTextB";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
			If IsBlankString(ColumnNameKeyFromFileB) Then
					
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнено имя столбца с ключом файла Б";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.ColumnNameKeyFromFileB";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			
			EndIf; 
			
			If NumberColumnsInKey > 1 Then
			
				If ColumnNameKey2FromFileB = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя столбца с ключом 2 файла Б";
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ColumnNameKey2FromFileB";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
					
				EndIf;
				
			EndIf;
			
			If NumberColumnsInKey > 2 Then
			
				If ColumnNameKey3FromFileB = 0 Then
					
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя столбца с ключом 3 файла Б";
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

 	If IsBlankString(ИсточникДляПредварительногоПросмотра) Then
	 
		//If код формируется автоматически, поля таблиц условий д.б. заполнены правильно
		If Not CodeForOutputRowsEditedManually And Not ConditionsOutputRowsDisabled Then
			
			If ConditionsOutputRows.Count() > 1 And Not ValueIsFilled(BooleanOperatorForConditionsOutputRows) Then
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнен логический оператор для объединения условий вывода строк";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.BooleanOperatorForConditionsOutputRows";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
			For Each СтрокаТЧ In ConditionsOutputRows Do
				
				If Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute) Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя реквизита в строке условий вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.Condition) Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено условие в строке условий вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].Condition";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.ComparisonType) Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен тип сравнения в строке условий вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].ComparisonType";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If СтрокаТЧ.Condition <> "Заполнен" Then
				
					If СтрокаТЧ.ComparisonType = "Attribute" And Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute2) Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнено имя реквизита в строке условий вывода №" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConditionsOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute2";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;     
			
		If Not CodeForProhibitingOutputRowsEditedManually And Not ConditionsProhibitOutputRowsDisabled Then
			
			If ConditionsProhibitOutputRows.Count() > 1 And Not ValueIsFilled(BooleanOperatorForProhibitingConditionsOutputRows) Then
				РеквизитыЗаполненыКорректно = False;
				ErrorText = "Not заполнен логический оператор для объединения условий запрета вывода строк";
				UserMessage = New UserMessage;
				UserMessage.Text = ErrorText;
				UserMessage.Field = "Object.BooleanOperatorForProhibitingConditionsOutputRows";
				UserMessage.Message();
				ErrorsText = ErrorsText + Chars.LF + ErrorText;
			EndIf;
			
			For Each СтрокаТЧ In ConditionsProhibitOutputRows Do
				
				If Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute) Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено имя реквизита в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.Condition) Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнено условие в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].Condition";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If Not ValueIsFilled(СтрокаТЧ.ComparisonType) Then
					РеквизитыЗаполненыКорректно = False;
					ErrorText = "Not заполнен тип сравнения в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
					UserMessage = New UserMessage;
					UserMessage.Text = ErrorText;
					UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].ComparisonType";
					UserMessage.Message();
					ErrorsText = ErrorsText + Chars.LF + ErrorText;
				EndIf;
				
				If СтрокаТЧ.Condition <> "Заполнен" Then
					
					If СтрокаТЧ.ComparisonType = "Attribute" And Not ValueIsFilled(СтрокаТЧ.NameComparedAttribute2) Then
						РеквизитыЗаполненыКорректно = False;
						ErrorText = "Not заполнено имя реквизита в строке условий запрета вывода №" + СтрокаТЧ.LineNumber;
						UserMessage = New UserMessage;
						UserMessage.Text = ErrorText;
						UserMessage.Field = "Object.ConditionsProhibitOutputRows[" + (СтрокаТЧ.LineNumber - 1) + "].NameComparedAttribute2";
						UserMessage.Message();
						ErrorsText = ErrorsText + Chars.LF + ErrorText;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;   
		
	EndIf;
	
	Return РеквизитыЗаполненыКорректно; 
	
EndFunction

Function СохранитьНастройкиВБазуНаСервере(SettingRef, SaveSpreadsheetDocuments) Export
	
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

Procedure ОткрытьНастройкиИзБазыНаСервере(SettingRef, ЗагружатьТабличныеДокументы = False) Export
	
	OperationCompletedSuccessfully = True;
	
	Try
		
		StorageExternal = SettingRef.Операция;
		Data = StorageExternal.Get();
		FillPropertyValues(ThisObject, Data);
		//For меньшей путаницы с наименованиями в заголовок попадает наименование элемента справочника,
		//на основании которого была заполнена обработка
		Title = SettingRef.Title;
		RelatedDataComparisonOperation = SettingRef;
		
		//До версии 12.1.38 вместо реквизита PeriodType использовался флаг PeriodTypeAbsolute
		//Value True флага PeriodTypeAbsolute соответствует значение 0 реквизита PeriodType
		//If в настройке нет реквизита PeriodType, необходимо его заполнить на основании флага PeriodTypeAbsolute
		If Not Data.Property("PeriodType") Then
			If Data.Property("PeriodTypeAbsolute") Then
				PeriodType = ?(Data.PeriodTypeAbsolute, 0, 1);
			EndIf;
		EndIf;
		
		//Настройки видимости колонок ключей появились в версии 15.5.58
		Если Не Данные.Свойство("VisibilityKey1") Тогда
			VisibilityKey1 = Истина;
		EndIf;
		
		Если Не Данные.Свойство("VisibilityKey2") Тогда
			VisibilityKey2 = NumberColumnsInKey > 1;
		EndIf;
		
		Если Не Данные.Свойство("VisibilityKey3") Тогда
			VisibilityKey3 = NumberColumnsInKey > 2;
		EndIf;
		
		//Настройки видимости колонок число записей появились в версии 15.5.58
		Если Не Данные.Свойство("VisibilityNumberOfRecordsA") Тогда
			VisibilityNumberOfRecordsA = Истина;
		EndIf;
		
		Если Не Данные.Свойство("VisibilityNumberOfRecordsB") Тогда
			VisibilityNumberOfRecordsB = Истина;
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
		
		//Реструктуризация параметров
		
		//Parameter CompositeKey заменен на NumberColumnsInKey
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
		ErrorText = "Not указан формат файла выгрузки";
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
		UserMessage.Field = "Object.UploadFileFormat";
		UserMessage.Message();
		Return Undefined;
	EndIf;
	
	If ДляКлиента Then
		ПутьКВременномуФайлу = GetTempFileName(UploadFileFormat);
	Else
		If IsBlankString(PathToDownloadFile) Then
			ErrorText = "Not заполнен путь к файлу выгрузки (на сервере)";
			UserMessage = New UserMessage;
			UserMessage.Text = ErrorText;
			UserMessage.Field = "Object.PathToDownloadFile";
			UserMessage.Message();
			Return Undefined;
		EndIf;
		
		ПутьКВременномуФайлу = PathToDownloadFile;
	EndIf;
	
	If Result.Count() = 0 Then
		ErrorText = "None данных для выгрузки";
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
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
		СписокЗаголовковСтрокой = "№ строки" + РазделительКолонок
				+ ?(VisibilityKey1, "Ключ 1" + РазделительКолонок, "")
				+ ?(NumberColumnsInKey > 1 И VisibilityKey2, "Ключ 2" + РазделительКолонок, "")
				+ ?(NumberColumnsInKey > 2 И VisibilityKey3, "Ключ 3" + РазделительКолонок, "")
				+ ?(VisibilityNumberOfRecordsA, "Число записей А" + РазделительКолонок, "")
				+ ?(VisibilityNumberOfRecordsB, "Число записей Б" + РазделительКолонок, "");
		
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ЭтотОбъект["VisibilityAttributeA" + AttributesCounter] Тогда
				СписокЗаголовковСтрокой = СписокЗаголовковСтрокой + РазделительКолонок + СтрЗаменить(ViewsHeadersAttributes["A" + AttributesCounter], РазделительКолонок,",");
			EndIf;
		EndDo;
		
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ЭтотОбъект["VisibilityAttributeB" + AttributesCounter] Тогда
				СписокЗаголовковСтрокой = СписокЗаголовковСтрокой + РазделительКолонок + СтрЗаменить(ViewsHeadersAttributes["B" + AttributesCounter], РазделительКолонок,",");
			EndIf;
		EndDo;
		
		СписокЗаголовковСтрокой = СтрЗаменить(СписокЗаголовковСтрокой, "" + РазделительКолонок + РазделительКолонок, РазделительКолонок);
		TextWriter.Write(СписокЗаголовковСтрокой);
			
		СчетчикСтрок = 0;
		For Each СтрокаТЧ In Result Do
			
			СчетчикСтрок = СчетчикСтрок + 1;
			
			TextWriter.Write(
				Chars.LF
					+ "" + СтрокаТЧ.LineNumber + РазделительКолонок
					+ ?(VisibilityKey1, "" + СтрокаТЧ.Key1 + РазделительКолонок, "")
					+ ?(NumberColumnsInKey > 1 И VisibilityKey2, "" + СтрокаТЧ.Key2 + РазделительКолонок, "")
					+ ?(NumberColumnsInKey > 2 И VisibilityKey3, "" + СтрокаТЧ.Key3 + РазделительКолонок, "")
					+ ?(VisibilityNumberOfRecordsA, "" + СтрокаТЧ.NumberOfRecordsA + РазделительКолонок, "")
					+ ?(VisibilityNumberOfRecordsB, "" + СтрокаТЧ.NumberOfRecordsB + РазделительКолонок, "")
					+ ?(VisibilityAttributeA1, "" + СтрокаТЧ.AttributeA1 + РазделительКолонок, "")
					+ ?(VisibilityAttributeA2, "" + СтрокаТЧ.AttributeA2 + РазделительКолонок, "")
					+ ?(VisibilityAttributeA3, "" + СтрокаТЧ.AttributeA3 + РазделительКолонок, "")
					+ ?(VisibilityAttributeA4, "" + СтрокаТЧ.AttributeA4 + РазделительКолонок, "")
					+ ?(VisibilityAttributeA5, "" + СтрокаТЧ.AttributeA5 + РазделительКолонок, "")
					+ ?(VisibilityAttributeB1, "" + СтрокаТЧ.AttributeB1 + РазделительКолонок, "")
					+ ?(VisibilityAttributeB2, "" + СтрокаТЧ.AttributeB2 + РазделительКолонок, "")
					+ ?(VisibilityAttributeB3, "" + СтрокаТЧ.AttributeB3 + РазделительКолонок, "")
					+ ?(VisibilityAttributeB4, "" + СтрокаТЧ.AttributeB4 + РазделительКолонок, "")
					+ ?(VisibilityAttributeB5, "" + СтрокаТЧ.AttributeB5 + РазделительКолонок, "")
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
				
		//НомерКолонкиЧислоЗаписейА = ?(ЧислоСтолбцовВКлюче > 1 И VisibilityKey2, ?(ЧислоСтолбцовВКлюче > 2 И VisibilityKey3, 5, 4), 3);
		ЧислоВыгружаемыхКлючей = ?(VisibilityKey1, 1, 0) + ?(ЧислоСтолбцовВКлюче > 1 И VisibilityKey2, 1, 0) + ?(ЧислоСтолбцовВКлюче > 2 И VisibilityKey3, 1, 0);
		НомерКолонкиСПервымВыгружаемымРеквизитом = ЧислоВыгружаемыхКлючей + ?(VisibilityNumberOfRecordsA, 1, 0) + ?(VisibilityNumberOfRecordsB, 1, 0) + 2;		
		
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
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, ЧислоВыгружаемыхКлючей + 2,  		"Число записей А",, 7);
		EndIf; 
		
		Если VisibilityNumberOfRecordsB Тогда
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, ЧислоВыгружаемыхКлючей + ?(VisibilityNumberOfRecordsA, 1, 0) + 2,  	"Число записей Б",, 7);
		EndIf;
		
		СмещениеОтКолонкиСПервымВыгружаемымРеквизитом = 0;
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ЭтотОбъект["VisibilityAttributeA" + AttributesCounter] Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, НомерКолонкиСПервымВыгружаемымРеквизитом + СмещениеОтКолонкиСПервымВыгружаемымРеквизитом, ViewsHeadersAttributes["A" + AttributesCounter]);
				СмещениеОтКолонкиСПервымВыгружаемымРеквизитом = СмещениеОтКолонкиСПервымВыгружаемымРеквизитом + 1;
			EndIf;
		EndDo;
		
		For AttributesCounter = 1 По NumberOfRequisites Цикл 
			Если ЭтотОбъект["VisibilityAttributeB" + AttributesCounter] Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, 1, НомерКолонкиСПервымВыгружаемымРеквизитом + СмещениеОтКолонкиСПервымВыгружаемымРеквизитом, ViewsHeadersAttributes["B" + AttributesCounter]);
				СмещениеОтКолонкиСПервымВыгружаемымРеквизитом = СмещениеОтКолонкиСПервымВыгружаемымРеквизитом + 1;
			EndIf;
		EndDo;
		
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
			
			РазмерыКолонок.K1 = Max(2, РазмерыКолонок.K1, StrLen(СтрокаТЧ.Key1));
			If NumberColumnsInKey > 1 And VisibilityKey2 Then
				РазмерыКолонок.К2 = Макс(2,РазмерыКолонок.K2, StrLen(СтрокаТЧ.Key2));
			EndIf;
			If NumberColumnsInKey > 2 And VisibilityKey3 Then				
				РазмерыКолонок.К3 = Max(2, РазмерыКолонок.К3, StrLen(СтрокаТЧ.Key3));
			EndIf;
			
			РазмерыКолонок.A1 = Макс(2,РазмерыКолонок.А1,StrLen(СтрокаТЧ.AttributeA1));
			РазмерыКолонок.A2 = Макс(2,РазмерыКолонок.А2,StrLen(СтрокаТЧ.AttributeA2));
			РазмерыКолонок.A3 = Макс(2,РазмерыКолонок.А3,StrLen(СтрокаТЧ.AttributeA3));
			РазмерыКолонок.A4 = Макс(2,РазмерыКолонок.А4,StrLen(СтрокаТЧ.AttributeA4));
			РазмерыКолонок.A5 = Макс(2,РазмерыКолонок.А5,StrLen(СтрокаТЧ.AttributeA5));
			РазмерыКолонок.B1 = Макс(2,РазмерыКолонок.Б1,StrLen(СтрокаТЧ.AttributeB1));
			РазмерыКолонок.B2 = Макс(2,РазмерыКолонок.Б2,StrLen(СтрокаТЧ.AttributeB2));
			РазмерыКолонок.B3 = Макс(2,РазмерыКолонок.Б3,StrLen(СтрокаТЧ.AttributeB3));
			РазмерыКолонок.B4 = Макс(2,РазмерыКолонок.Б4,StrLen(СтрокаТЧ.AttributeB4));
			РазмерыКолонок.B5 = Макс(2,РазмерыКолонок.Б5,StrLen(СтрокаТЧ.AttributeB5));
			
			СчетчикСтрок = СчетчикСтрок + 1;
			
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, 1, СтрокаТЧ.LineNumber, 1, 7);
			If VisibilityKey1 Then
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, 2, СтрокаТЧ.Key1,, РазмерыКолонок.K1);
			EndIf;
			If NumberColumnsInKey > 1 And VisibilityKey2 Then
				SetCellValueSpreadsheetDocument(SpreadsheetDocument
					, СчетчикСтрок + 1
					, ?(VisibilityKey1, 1, 0) + 2
					, СтрокаТЧ.Ключ2
					,
					, РазмерыКолонок.K2);
			EndIf;
			If NumberColumnsInKey > 2 And VisibilityKey3 Then
				SetCellValueSpreadsheetDocument(SpreadsheetDocument
					, СчетчикСтрок + 1
					, ?(VisibilityKey1, 1, 0) + ?(VisibilityKey2, 1, 0) + 2
					, СтрокаТЧ.Key3
					,
					, РазмерыКолонок.K3);
			EndIf;
				
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА,		СтрокаТЧ.ЧислоЗаписейА, 1, 7);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 1, СтрокаТЧ.ЧислоЗаписейБ, 1, 7);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 2, СтрокаТЧ.AttributeA1,, МаксДлинаА1);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 3,	СтрокаТЧ.AttributeA2,, МаксДлинаА2);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 4,	СтрокаТЧ.AttributeA3,, МаксДлинаА3);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 5, СтрокаТЧ.AttributeA4,, МаксДлинаА4);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 6, СтрокаТЧ.AttributeA5,, МаксДлинаА5);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 7, СтрокаТЧ.AttributeB1,, МаксДлинаБ1);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 8, СтрокаТЧ.AttributeB2,, МаксДлинаБ2);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 9, СтрокаТЧ.AttributeB3,, МаксДлинаБ3);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 10,СтрокаТЧ.AttributeB4,, МаксДлинаБ4);
			SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиЧислоЗаписейА + 11,СтрокаТЧ.AttributeB5,, МаксДлинаБ5);
		
			Если VisibilityNumberOfRecordsA Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, ЧислоВыгружаемыхКлючей + 2,	СтрокаТЧ.ЧислоЗаписейА, 1, 7);
			EndIf;
			
			Если VisibilityNumberOfRecordsB Тогда
				SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, ЧислоВыгружаемыхКлючей + ?(VisibilityNumberOfRecordsA, 1, 0) + 2, СтрокаТЧ.ЧислоЗаписейБ, 1, 7);
			EndIf;
			
			СмещениеОтКолонкиСПервымВыгружаемымРеквизитом = 0;
			For СчетчикРеквизитов = 1 По NumberOfRequisites Цикл 
				Если ЭтотОбъект["VisibilityAttributeA" + СчетчикРеквизитов] Тогда
					SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиСПервымВыгружаемымРеквизитом + СмещениеОтКолонкиСПервымВыгружаемымРеквизитом, СтрокаТЧ["РеквизитА" + СчетчикРеквизитов],, РазмерыКолонок["A" + СчетчикРеквизитов]);
					СмещениеОтКолонкиСПервымВыгружаемымРеквизитом = СмещениеОтКолонкиСПервымВыгружаемымРеквизитом + 1;
				EndIf;
			EndDo;
			
			For СчетчикРеквизитов = 1 По NumberOfRequisites Цикл 
				Если ЭтотОбъект["VisibilityAttributeB" + СчетчикРеквизитов] Тогда
					SetCellValueSpreadsheetDocument(SpreadsheetDocument, СчетчикСтрок + 1, НомерКолонкиСПервымВыгружаемымРеквизитом + СмещениеОтКолонкиСПервымВыгружаемымРеквизитом, СтрокаТЧ["РеквизитБ" + СчетчикРеквизитов],, РазмерыКолонок["B" + СчетчикРеквизитов]);
					СмещениеОтКолонкиСПервымВыгружаемымРеквизитом = СмещениеОтКолонкиСПервымВыгружаемымРеквизитом + 1;
				EndIf;
			EndDo;
			
		EndDo; 
		
		SpreadsheetDocument.Write(ПутьКВременномуФайлу, SpreadsheetDocumentFileType[UploadFileFormat]);
		
	Else
		
		ErrorText = "Format файла выгрузки """ + UploadFileFormat + """ не предусмотрен";
		UserMessage = New UserMessage;
		UserMessage.Text = ErrorText;
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
 