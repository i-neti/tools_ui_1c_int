//Sign of using settings
&AtClient
Var mUseSettings Export;

//Types of objects for which processing can be used.
//To default for everyone.
&AtClient
Var mTypesOfProcessedObjects Export;

&AtClient
Var mSetting;

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

// Defines and sets the Type and Length of the object number
//
// Parameters:
//  None.
//
&AtServer
Procedure DefineTypeAndLengthNumbers()
	ObjectTypeName = SearchObject.Type;
	ObjectMetadata = Metadata.FindByFullName(SearchObject.Type + "." + SearchObject.Name);
	If ObjectTypeName = "Document" Then
		NumberType   = String(ObjectMetadata.NumberType);
		NumberLength = ObjectMetadata.NumberLength;
	ElsIf ObjectTypeName = "Catalog" Then
		NumberType   = String(ObjectMetadata.CodeType);
		NumberLength = ObjectMetadata.CodeLength;
	EndIf;
EndProcedure // ()

// Performs object processing.
//
// Parameters:
//  ProcessedObject                 - processed object.
//  SequenceNumberObject - serial number of the processed object.
//
&AtServer
Procedure ProcessObject(Reference, Counter, NonUniqueNumbers, MaximumNumber, NumericPartNumbers,
	ParametersWriteObjects)

	ProcessedObject = Reference.GetObject();

	If NumberType = "Number" Then
		If Not DoNotChangeNumericalNumbering Then
			If ObjectTypeName = "Document" Then
				ProcessedObject.Number = NumericPartNumbers;
			Else
				ProcessedObject.Code = NumericPartNumbers;
			EndIf;
			If Not UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects) Then
				If ObjectTypeName = "Document" Then
					ProcessedObject.Number = MaximumNumber - Counter;
				Else
					ProcessedObject.Code = MaximumNumber - Counter;
				EndIf;
				//				ProcessedObject.Write();

				If Not UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects) Then
					Raise Nstr("ru = 'Ошибка обработки номеров объектов';en = 'Error processing object numbers'");
				EndIf;
				NonUniqueNumbers.Insert(NumericPartNumbers, ProcessedObject.Reference);
			EndIf;
//			Try
//				ProcessedObject.Write();
//			Except
//				If ObjectTypeName = "Document" Then
//					ProcessedObject.Number = MaximumNumber - Counter;
//				Else
//					ProcessedObject.Code = MaximumNumber - Counter;
//				EndIf; 
//				ProcessedObject.Write();
//				NonUniqueNumbers.Insert(NumericPartNumbers, ProcessedObject.Reference);
//			EndTry;		
			NumericPartNumbers = NumericPartNumbers + 1;
		EndIf;
		Return;
	EndIf;
	If ObjectTypeName = "Document" Then
		ТекНомер = TrimAll(ProcessedObject.Number);
	Else
		ТекНомер = TrimAll(ProcessedObject.Code);
	EndIf;

	If DoNotChangeNumericalNumbering Then
		СтроковаяЧастьНомера = GetPrefixNumberNumbers(ТекНомер, NumericPartNumbers);
	Else
		СтроковаяЧастьНомера = GetPrefixNumberNumbers(ТекНомер);
	EndIf;
	If PrefixHandlingMethod = 1 Then
		NewNumber = СтроковаяЧастьНомера;
	ElsIf PrefixHandlingMethod = 2 Then
		NewNumber = TrimAll(LinePrefix);
	ElsIf PrefixHandlingMethod = 3 Then
		NewNumber = TrimAll(LinePrefix) + СтроковаяЧастьНомера;
	ElsIf PrefixHandlingMethod = 4 Then
		NewNumber = СтроковаяЧастьНомера + TrimAll(LinePrefix);
	ElsIf PrefixHandlingMethod = 5 Then
		NewNumber = StrReplace(СтроковаяЧастьНомера, TrimAll(ReplaceableSubstring), TrimAll(LinePrefix));
	EndIf;

	While NumberLength - StrLen(NewNumber) - StrLen(Format(NumericPartNumbers, "ЧГ=0")) > 0 Do
		NewNumber = NewNumber + "0";
	EndDo;

	NewNumber 	 = NewNumber + Format(NumericPartNumbers, "ЧГ=0");

	If ObjectTypeName = "Document" Then
		ProcessedObject.Number = NewNumber;
	Else
		ProcessedObject.Code = NewNumber;
	EndIf;

	If Not UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects) Then
		If ObjectTypeName = "Document" Then
			ProcessedObject.Number = Format(MaximumNumber - Counter, "ЧГ=0");
		Else
			ProcessedObject.Code = Format(MaximumNumber - Counter, "ЧГ=0");
		EndIf; 
//		ProcessedObject.Write();			
		If Not UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects) Then
			Raise "Error обработки номеров объектов";
		EndIf;
		NonUniqueNumbers.Insert(NewNumber, ProcessedObject.Reference);

	EndIf;
//	Try
//		ProcessedObject.Write();
//	Except
//		If ObjectTypeName = "Document" Then
//			ProcessedObject.Number = Format(MaximumNumber - Counter, "ЧГ=0");
//		Else
//			ProcessedObject.Code = Format(MaximumNumber - Counter, "ЧГ=0");
//		EndIf;
//		ProcessedObject.Write();
//		NonUniqueNumbers.Insert(NewNumber, ProcessedObject.Reference);
//	EndTry;

	If Not DoNotChangeNumericalNumbering Then
		NumericPartNumbers = NumericPartNumbers + 1;
	EndIf;

EndProcedure // ProcessObject()

&AtServer
Procedure CheckNonUniqueNumbers(NonUniqueNumbers, ParametersWriteObjects)
	For Each NonUniqueNumber In NonUniqueNumbers Do
		NewNumber   = NonUniqueNumber.Key;
		ProcessedObject       = NonUniqueNumber.Value.GetObject();
		If ObjectTypeName = "Document" Then
			ProcessedObject.Number = NewNumber;
		Else
			ProcessedObject.Code = NewNumber;
		EndIf;
		If Not UT_Common.WriteObjectToDB(ProcessedObject, ParametersWriteObjects) Then
			UT_CommonClientServer.MessageToUser(StrTemplate(
				Nstr("ru = 'Повтор номера: %1 за пределами данной выборки!';en = 'Repeating number: %1 out of range!'")
				, NewNumber));
		EndIf;
//		Try
//			ProcessedObject.Write();
//		Except
//			Message("Повтор номера: " + NewNumber + " за пределами данной выборки!");
//		EndTry;
	EndDo;
EndProcedure

// Performs object processing.
//
// Parameters:
//  None.
//
&AtClient
Function ExecuteProcessing(ParametersWriteObjects) Export
	DefineTypeAndLengthNumbers();
	If (PrefixHandlingMethod = 1) And (DoNotChangeNumericalNumbering) Then
		Return 0;
	EndIf;

	If (InitialNumber = 0) And (Not DoNotChangeNumericalNumbering) Then
		ShowMessageBox( , Nstr("ru = 'Измените начальный номер!';en = 'Change start number!'"));
		Return 0;
	EndIf;

	If Not DoNotChangeNumericalNumbering Then
		NumericPartNumbers = InitialNumber;
	EndIf;

	NonUniqueNumbers = New Map;
	MaximumNumber  = Number(SupplementStringWithCharacters("", NumberLength, "9"));

	Indicator = UT_FormsClient.GetProcessIndicator(FoundObjects.Count());
	For ind = 0 To FoundObjects.Count() - 1 Do
		UT_FormsClient.ProcessIndicator(Indicator, ind + 1);

		RowFoundObjectValue = FoundObjects.Get(ind).Value;
		ProcessObject(RowFoundObjectValue, ind, NonUniqueNumbers, MaximumNumber, NumericPartNumbers,
			ParametersWriteObjects);
	EndDo;

	CheckNonUniqueNumbers(NonUniqueNumbers, ParametersWriteObjects);

	If ind > 0 Then
		NotifyChanged(Type(SearchObject.Type + "Reference." + SearchObject.Name));
	EndIf;

	Return ind;
EndFunction // ExecuteProcessing()

// Restores saved form attribute values.
//
// Parameters:
//  None.
//
&AtClient
Procedure DownloadSettings() Export

	UT_FormsClient.DownloadSettings(ThisForm, mSetting);

	PrefixHandlingMethodOnChange("");
	DoNotChangeNumericalNumberingOnChange("");
	
EndProcedure //DownloadSettings()

// Parses a string extracting a prefix and a numeric part from it
//
// Parameters:
//  Row            - String. Parsed string
//  NumericPart  - Number. Variable which will return the numeric part of the string
//  Mode          - String. If "Number", then return the numeric part otherwise - prefix
//
// Return value:
//  Prefix string
//              
&AtServer
Function GetPrefixNumberNumbers(Val Row, NumericPart = "", Mode = "") Export

	Row		=	TrimAll(Row);
	Prefix	=	Row;
	Length	=	StrLen(Row);

	For Counter = 1 To Length Do
		Try
			NumericPart = Number(Row);
		Except
			Row = Right(Row, Length - Counter);
			Continue;
		EndTry;

		If (NumericPart > 0) And (StrLen(Format(NumericPart, "ЧГ=0")) = Length - Counter + 1) Then
			Prefix	=	Left(Prefix, Counter - 1);

			While Right(Prefix, 1) = "0" Do
				Prefix = Left(Prefix, StrLen(Prefix) - 1);
			EndDo;

			Break;
		Else
			Row = Right(Row, Length - Counter);
		EndIf;

		If NumericPart < 0 Then
			NumericPart = -NumericPart;
		EndIf;

	EndDo;

	If Mode = "Number" Then
		Return (NumericPart);
	Else
		Return (Prefix);
	EndIf;

EndFunction // вGetPrefixNumberNumbers()

// Brings the number (code) to the required length. This highlights the prefix
// and the numeric part of the number, the rest of the space between the prefix and
// number is filled with zeros
//
// Parameters:
//  Row    - String to convert
//  Length - Required string length
//
// Return value:
//  String - code or number reduced to the required length
// 
&AtServer
Function LeadNumberToLength(Val Row, Length) Export

	Row			    =	TrimAll(Row);

	NumericPart	=	"";
	Result		=	GetPrefixNumberNumbers(Row, NumericPart);
	While Length - StrLen(Result) - StrLen(Format(NumericPart, "ЧГ=0")) > 0 Do
		Result	=	Result + "0";
	EndDo;
	Result	=	Result + Format(NumericPart, "ЧГ=0");

	Return (Result);

EndFunction // LeadNumberToLength()

// Adds a substring to the number or code prefi
//
// Parameters:
//  Row           - String, Number or code
//  SubstrigToAdd - Substring to add to prefix
//  Length        - Required result string length
//  Mode          - "Left" - the substring is added to the left of the prefix, otherwise to the right
//
// Return value:
//  String - the number or code to which the specified substring is prefixed
//                                                                                                     
&AtServer
Function AddToPrefix(Val Row, SubstrigToAdd = "", Length = "", Mode = "Left") Export

	Row = TrimAll(Row);

	If IsBlankString(Length) Then
		Length = StrLen(Row);
	EndIf;

	NumericPart	= "";
	Prefix =	GetPrefixNumberNumbers(Row, NumericPart);
	If Mode = "Left" Then
		Result = TrimAll(SubstrigToAdd) + Prefix;
	Else
		Result = Prefix + TrimAll(SubstrigToAdd);
	EndIf;

	While Length - StrLen(Result) - StrLen(Format(NumericPart, "ЧГ=0")) > 0 Do
		Result = Result + "0";
	EndDo;
	Result = Result + Format(NumericPart, "ЧГ=0");

	Return (Result);

EndFunction // AddToPrefix()

// Complements a string with the specified character to the specified length
//
// Parameters: 
//  Row            - padding string
//  Length          - Required length of the resulting string
//  Char            - Char to complete the string
//
// Return value:
//  String padded with the specified character to the specified length
//
&AtServer
Function SupplementStringWithCharacters(Row = "", Length, Char = " ") Export
	
	Result = TrimAll(Row);
	While Length - StrLen(Result) > 0 Do
		Result	=	Result + Char;
	EndDo;
	Return (Result);
	
EndFunction // SupplementStringWithCharacters() 

////////////////////////////////////////////////////////////////////////////////
// FORM EVENT HANDLERS

&AtClient
Procedure OnOpen(Cancel)
	
	DefineTypeAndLengthNumbers();
	If NumberType <> "String" Then
		Items.GroupNumberPrefixes.Visible = False;
	EndIf;

	If mUseSettings Then
		UT_FormsClient.SetNameSettings(ThisForm);
		DownloadSettings();
	Else
		Items.CurrentSetting.Enabled = False;
		Items.SaveSettings.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UT_FormsServer.FillSettingByParametersForm(ThisForm);

	Items.CurrentSetting.ChoiceList.Clear();
	If Parameters.Property("Settings") Then
		For Each String In Parameters.Settings Do
			Items.CurrentSetting.ChoiceList.Add(String, String.Processing);
		EndDo;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// // EVENT HANDLERS CALLED FROM FORM ELEMENTS

&AtClient
Procedure ExecuteCommand(Command)
	ProcessedObjects = ExecuteProcessing(UT_CommonClientServer.FormWriteSettings(
		ThisObject.FormOwner));

	Message = StrTemplate(Nstr("ru = 'Обработка <%1> завершена! 
					 |Обработано объектов: %2.';en = 'Processing of <%1> completed!
					 |Objects processed: %2.'"), TrimAll(ThisForm.Title), ProcessedObjects);
	ShowMessageBox(, Message);
EndProcedure

&AtClient
Procedure SaveSettings(Command)
	UT_FormsClient.SaveSetting(ThisForm, mSetting);
EndProcedure

&AtClient
Procedure CurrentSettingChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	StandardProcessing = False;

	If Not CurrentSetting = SelectedValue Then

		If ThisForm.Modified Then
			ShowQueryBox(New NotifyDescription("CurrentSettingChoiceProcessingEnd", ThisForm,
				New Structure("SelectedValue", SelectedValue)), Nstr("ru = 'Сохранить текущую настройку?';en = 'Save current setting?'"),
				QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
			Return;
		EndIf;

		CurrentSettingChoiceProcessingFragment(SelectedValue);

	EndIf;
	
EndProcedure

&AtClient
Procedure CurrentSettingChoiceProcessingEnd(ResultQuestion, AdditionalParameters) Export

	SelectedValue = AdditionalParameters.SelectedValue;
	If ResultQuestion = DialogReturnCode.Yes Then
		UT_FormsClient.SaveSetting(ThisForm, mSetting);
	EndIf;

	CurrentSettingChoiceProcessingFragment(SelectedValue);

EndProcedure

&AtClient
Procedure CurrentSettingChoiceProcessingFragment(Val SelectedValue)

	CurrentSetting = SelectedValue;
	UT_FormsClient.SetNameSettings(ThisForm);

	DownloadSettings();

EndProcedure

&AtClient
Procedure CurrentSettingOnChange(Item)
	ThisForm.Modified = True;
EndProcedure

&AtClient
Procedure DoNotChangeNumericalNumberingOnChange(Item)
	Items.InitialNumber.Enabled = Not DoNotChangeNumericalNumbering;
EndProcedure

&AtClient
Procedure PrefixHandlingMethodOnChange(Item)
	
	If PrefixHandlingMethod = 1 Then
		Items.LinePrefix.Enabled      = False;
		Items.ReplaceableSubstring.Enabled = False;
	ElsIf PrefixHandlingMethod = 5 Then
		Items.LinePrefix.Enabled      = True;
		Items.ReplaceableSubstring.Enabled = True;
	Else
		Items.LinePrefix.Enabled      = True;
		Items.ReplaceableSubstring.Enabled = False;
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// INITIALIZING MODULAR VARIABLES

mUseSettings = True;

////Attributes settings and defaults.
mSetting = New Structure("InitialNumber,DoNotChangeNumericalNumbering,LinePrefix,ReplaceableSubstring,PrefixHandlingMethod");

mSetting.InitialNumber              = 1;
mSetting.DoNotChangeNumericalNumbering = False;
mSetting.PrefixHandlingMethod    = 1;

mTypesOfProcessedObjects = "Catalog,Document";