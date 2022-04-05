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

	If Form.Parameters.Property("FoundObjectsTP") Then

		FoundObjectsValueTable = Form.Parameters.FoundObjectsTP.Unload();

		Form.FoundObjectsTP.Load(FoundObjectsValueTable);
	EndIf;

	If Form.Parameters.Property("ProcessTabularParts") Then
		Form.ProcessTabularParts = Form.Parameters.ProcessTabularParts;
	EndIf;
	If Form.Parameters.Property("TableAttributes") Then
		TableAttributes = Form.Parameters.TableAttributes;
		TableAttributes.Sort("ThisTP");
		For Each Attribute In Form.Parameters.TableAttributes Do
			NewLine = Form.Attributes.Add();
			NewLine.Attribute = Attribute.Name;//?(IsBlankString(Attribute.Synonym), Attribute.Name, Attribute.Synonym);
			NewLine.ID = Attribute.Presentation;
			NewLine.Type = Attribute.Type;
			NewLine.Value = NewLine.Type.AdjustValue();
			NewLine.AttributeTP = Attribute.ThisTP;
			If Form.Items.Find("CurrentAttribute") <> Undefined Then
				If Attribute.Type = TypeDescription("Number") Then
					Form.Items.CurrentAttribute.ChoiceList.Add(Attribute.Name + ?(Attribute.ThisTP, "_TP_12345", ""),
						Attribute.Presentation + ?(Attribute.ThisTP, " [TP]", ""));
				EndIf;
			EndIf;
		EndDo;
		If Form.Items.Find("CurrentAttribute") <> Undefined Then
			If Form.Items.CurrentAttribute.ChoiceList.Count() > 0 Then
				Form.CurrentAttribute= Form.Items.CurrentAttribute.ChoiceList[0].Value;
			EndIf;
		EndIf;

	EndIf;
	
EndProcedure

Function TypeDescription(TypeString) Export

	ArrayTypes = New Array;
	ArrayTypes.Add(Type(TypeString));
	TypeDescription = New TypeDescription(ArrayTypes);

	Return TypeDescription;

EndFunction

#EndRegion

