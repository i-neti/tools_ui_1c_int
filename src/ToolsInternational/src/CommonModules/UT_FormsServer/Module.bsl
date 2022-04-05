#Region UT_GroupProcessingCatalogsAndDocuments

Procedure FillSettingByParametersForm(Form) Export
	
	If Form.Parameters.Property("Setting") Then
		Form.CurrentSetting = Form.Parameters.Setting;
	EndIf;
	If Form.Parameters.Property("FoundObjects") Then
		Form.FoundObjects.LoadValues(Form.Parameters.FoundObjects);
	EndIf;
	Form.CurrentLine = -1;
	If Form.Parameters.Property("CurrentLine") Then
		If Form.Parameters.CurrentLine <> Undefined Then
			Form.CurrentLine = Form.Parameters.CurrentLine;
		EndIf;
	EndIf;
	If Form.Parameters.Property("Parent") Then
		Form.Parent = Form.Parameters.Parent;
	EndIf;
	If Form.Parameters.Property("SearchObject") Then
		Form.SearchObject = Form.Parameters.SearchObject;
	EndIf;

	Form.Items.CurrentSetting.ChoiceList.Clear();
	If Form.Parameters.Property("Settings") Then
		For Each String In Form.Parameters.Settings Do
			Form.Items.CurrentSetting.ChoiceList.Add(String, String.Processing);
		EndDo;
	EndIf;

EndProcedure

#EndRegion

