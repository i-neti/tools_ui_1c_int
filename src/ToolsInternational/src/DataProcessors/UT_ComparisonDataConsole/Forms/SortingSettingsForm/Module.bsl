&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OrderSortTableDifferences = Параметры.OrderSortTableDifferences;
	MultilineText = StrReplace(OrderSortTableDifferences, ",", Chars.LF);
	LineCount = StrLineCount(MultilineText);
	For RowCounter = 1 По LineCount Do
		
		CurrentRow = StrGetLine(MultilineText, RowCounter);
		CurrentMultilineText = StrReplace(CurrentRow, " ", Chars.LF);
		RowVT = VT_SortingOrderOfTheDifferenceTable.Add();
		RowVT.ColumnName = StrGetLine(CurrentMultilineText, 1);
		RowVT.OrderSort = StrGetLine(CurrentMultilineText, 2);
	
	EndDo;
	
	Items.VT_SortingOrderOfTheDifferenceTableColumnName.ChoiceList.Add("Key1", "Key 1");
	Items.VT_SortingOrderOfTheDifferenceTableColumnName.ChoiceList.Add("Key2", "Key 2");
	Items.VT_SortingOrderOfTheDifferenceTableColumnName.ChoiceList.Add("Key3", "Key 3");
	
	For AttributesCounter = 1 По 5 Do
	
		Items.VT_SortingOrderOfTheDifferenceTableColumnName.ChoiceList.Add("AttributeA" + AttributesCounter, "Attribute A" + AttributesCounter);
	
	EndDo;
	
	For AttributesCounter =  1 По 5 Do
	
		Items.VT_SortingOrderOfTheDifferenceTableColumnName.ChoiceList.Add("AttributeB" + AttributesCounter, "Attribute B" + AttributesCounter);
	
	EndDo;
	
EndProcedure

&AtClient
Procedure CommandSetupComplete(Command)
	
	ThereAreFillingErrors = False;
	
	GenerateSortOrder();
		
	For Each RowVT Из VT_SortingOrderOfTheDifferenceTable Do
	
		If IsBlankString(RowVT.ColumnName) Then
			Message = New UserMessage;
			Message.Text = Nstr("ru = 'Не задан столбец';en = 'Column not set'");
			Message.Field = "VT_SortingOrderOfTheDifferenceTable[" + (VT_SortingOrderOfTheDifferenceTable.IndexOf(RowVT) + 1) + "].ColumnName";
			Message.Message(); 
			ThereAreFillingErrors = True;
		EndIf;
		
		If IsBlankString(RowVT.OrderSort) Then
			Message = New UserMessage;
			Message.Text = Nstr("ru = 'Не задан порядок сортировки столбца';en = 'Column sort order not set'");
			Message.Field = "VT_SortingOrderOfTheDifferenceTable[" + (VT_SortingOrderOfTheDifferenceTable.IndexOf(RowVT)) + "].OrderSort";
			Message.Message(); 
			ThereAreFillingErrors = True;
		EndIf;
	
	EndDo; 
	
	If ThereAreFillingErrors Then
		Return;
	EndIf;
	
	Close(OrderSortTableDifferences);
	
EndProcedure

&AtClient
Procedure VT_SortingOrderOfTheDifferenceTableOnChange(Item)
	
	GenerateSortOrder();
		
EndProcedure

&AtClient
Procedure GenerateSortOrder()
	
	OrderSortTableDifferences = "";
	
	For Each RowVT Из VT_SortingOrderOfTheDifferenceTable Do
		
		OrderSortTableDifferences = OrderSortTableDifferences + RowVT.ColumnName + " " + RowVT.OrderSort + ",";
	
	EndDo; 
	
EndProcedure
