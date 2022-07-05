#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueryParametersIsExpressionOnChange(Item)

	CurrentData = Items.QueryParameters.CurrentData;

	If CurrentData.IsExpression And Not TypeOf(CurrentData.ParameterValue) = Type("String") Then
		CurrentData.ParameterValue = "";
	EndIf;
	
	ChangeTypeSelection();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure ExecuteQuery(Command)
	
	QueryText = DocumentQueryText.GetText();
	
	If IsBlankString(QueryText) Then
		
		MessageToUser(NStr("ru = 'Не задан текст запроса'; en = 'Query text is not specified'"), "QueryText");
		Return;
		
	EndIf;
	
	ExecuteQueryAtServer(QueryText);
	
EndProcedure

&AtClient
Procedure FillParameters(Command)
	FillParametersAtServer();
EndProcedure

&AtClient
Procedure AddToExportResult(Command)
	
	If Items.Find("QueryResult") = Undefined Then
		
	Else
		
		NotifyChoice(ThisObject.QueryResult);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ExecuteQueryAtServer(QueryText)
	
	Query = New Query;

	For Each ParametersRow In QueryParameters Do
		If ParametersRow.IsExpression Then
			Query.SetParameter(ParametersRow.ParameterName, Eval(ParametersRow.ParameterValue));
		Else
			Query.SetParameter(ParametersRow.ParameterName, ParametersRow.ParameterValue);
		EndIf;
	EndDo;

	Query.Text = QueryText;
	Result = Query.Execute();
	ResultTable = Result.Unload();

	DeleteFormItems();
	AddFormItems(ResultTable);

EndProcedure

&AtServer
Procedure AddFormItems(ResultTable)
	
	AttributesArray = New Array;
	AttributesArray.Add(New FormAttribute("QueryResult", New TypeDescription("ValueTable")));
	
	For Each Column In ResultTable.Columns Do
		AttributesArray.Add(New FormAttribute(Column.Name, Column.ValueType, "QueryResult"));
	EndDo;
	
	ChangeAttributes(AttributesArray);
	
	FormTable = Items.Add("QueryResult", Type("FormTable"), Items.QueryResultGroup);
	FormTable.DataPath = "QueryResult";
	FormTable.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	FormTable.VerticalStretch = False;
	
	For Each Column In ResultTable.Columns Do
		NewItem = Items.Add("Column_" + Column.Name, Type("FormField"), FormTable);
		NewItem.Type = FormFieldType.InputField;
		NewItem.DataPath = "QueryResult." + Column.Name;
	EndDo; 
	
	ValueToFormAttribute(ResultTable,"QueryResult");
	
	Items.QueryResultGroup.CurrentPage = Items.QueryResultGroup.ChildItems.QueryResultGroup1;
	
EndProcedure

&AtServer
Procedure DeleteFormItems()
	
	If Items.Find("QueryResult") <> Undefined Then
		
		AttributesArray = New Array;
		AttributesArray.Add("QueryResult");
		
		ChangeAttributes(, AttributesArray);

		Items.Delete(Items.QueryResult);

	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure MessageToUser(Text, DataPath = "")
	
	Message = New UserMessage;
	Message.Text = Text;
	Message.DataPath = DataPath;
	Message.Message();
	
EndProcedure

&AtServer
Procedure FillParametersAtServer()
	
	Query = New Query;
	Query.Text = DocumentQueryText.GetText();
	
	ParametersDetails = Query.FindParameters();
	
	For Each Parameter In ParametersDetails Do
		ParameterName =  Parameter.Name;
		FilterParameters = New Structure;
		FilterParameters.Insert("ParameterName", ParameterName);
		RowsArray = QueryParameters.FindRows(FilterParameters);

		If RowsArray.Count() = 1 Then
			
			ParametersString = RowsArray[0];
			
		Else
			
			ParametersString = QueryParameters.Add();
			ParametersString.ParameterName = ParameterName;
			
		EndIf;
		
		ParametersString.ParameterValue = Parameter.ValueType.AdjustValue(ParametersString.ParameterValue);
		ParametersString.ParameterType = Parameter.ValueType;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeTypeSelection()
	
	CurrentData = Items.QueryParameters.CurrentData;
	QueryParameter = Items.QueryParameters.ChildItems.QueryParametersParameterValue;
	
	QueryParameter.TypeRestriction = ?(CurrentData.IsExpression, New TypeDescription, CurrentData.ParameterType);
	QueryParameter.ChooseType = Not CurrentData.IsExpression;
	
EndProcedure

#EndRegion