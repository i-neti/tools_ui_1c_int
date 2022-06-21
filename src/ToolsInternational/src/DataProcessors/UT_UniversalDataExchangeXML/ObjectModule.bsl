///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2019, 1C-Soft LLC
// All Rights reserved. This application and supporting materials are provided under the terms of 
// Attribution 4.0 International license (CC BY 4.0)
// The license text is available at:
// https://creativecommons.org/licenses/by/4.0/legalcode
// Translated by Neti Company
///////////////////////////////////////////////////////////////////////////////////////////////////////
#Region Variables

////////////////////////////////////////////////////////////////////////////////
// ACRONYMS IN VARIABLE NAMES

//  OCR is an object conversion rule.
//  PCR is an object property conversion rule.
//  PGCR is an object property group conversion rule.
//  VCR is an object value conversion rule.
//  DER is a data export rule.
//  DCR is a data clearing rule.

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY MODULE VARIABLES FOR CREATING ALGORITHMS (FOR BOTH IMPORT AND EXPORT)

Var Conversion  Export;  // Conversion property structure (name, ID, and exchange event handlers).

Var Algorithms    Export;  // Structure containing used algorithms.
Var Queries      Export;  // Structure containing used queries.
Var AdditionalDataProcessors Export;  // Structure containing used external data processors.

Var Rules      Export;  // Structure containing references to OCR.

Var Managers    Export;  // Map containing the following fields: Name, TypeName, RefTypeAsString, Manager, MetadataObject, and OCR.
Var ManagersForExchangePlans Export;
Var ExchangeFile Export;            // Sequentially written or read exchange file.

Var AdditionalDataProcessorParameters Export;  // Structure containing parameters of used external data processors.

Var ParametersInitialized Export;  // If True, necessary conversion parameters are initialized.

Var mDataLogFile Export; // Data exchange log file.
Var CommentObjectProcessingFlag Export;

Var EventHandlersExternalDataProcessor Export; // The ExternalDataProcessorsManager object to call export procedures of handlers when debugging 
                                                   // import or export.

Var CommonProceduresFunctions;  // The variable stores a reference to the current instance of the data processor called ThisObject.
                              // It is required to call export procedures from event handlers.

Var mHandlerParameterTemplate; // Spreadsheet document with handler parameters.
Var mCommonProceduresFunctionsTemplate;  // Text document with comments, global variables and bind methods
											// of common procedures and functions.

Var mDataProcessingModes; // The structure that contains modes of using this data processor.
Var DataProcessingMode;   // It contains current value of data processing mode.

Var mAlgorithmDebugModes; // The structure that contains modes of debugging algorithms.
Var IntegratedAlgorithms; // The structure containing algorithms with integrated scripts of nested algorithms.

Var HandlersNames; // The structure that contains names of all exchange rule handlers.

Var ConfigurationSeparators; // Array: contains configuration separators.

////////////////////////////////////////////////////////////////////////////////
// FLAGS THAT SHOW WHETHER GLOBAL EVENT HANDLERS EXIST

Var HasBeforeExportObjectGlobalHandler;
Var HasAfterExportObjectGlobalHandler;

Var HasBeforeConvertObjectGlobalHandler;

Var HasBeforeImportObjectGlobalHandler;
Var HasAfterImportObjectGlobalHandler;

Var DestinationPlatformVersion;
Var DestinationPlatform;

////////////////////////////////////////////////////////////////////////////////
// VARIABLES THAT ARE USED IN EXCHANGE HANDLERS (BOTH FOR IMPORT AND EXPORT)

Var deStringType;                  // Type("String")
Var deBooleanType;                  // Type("Boolean")
Var deNumberType;                   // Type("Number")
Var deDateType;                    // Type("Date")
Var deValueStorageType;       // Type("ValueStorage")
Var deUUIDType; // Type("UUID")
Var deBinaryDataType;          // Type("BinaryData")
Var deAccumulationRecordTypeType;   // Type("AccumulationRecordType")
Var deObjectDeletionType;         // Type("ObjectDeletion")
Var deAccountTypeType;			    // Type("AccountType")
Var deTypeType;			  		    // Type("Type")
Var deMapType;		    // Type("Map").

Var deXMLNodeType_EndElement  Export;
Var deXMLNodeType_StartElement Export;
Var deXMLNodeType_Text          Export;

Var BlankDateValue Export;

Var deMessages;             // Map. Key - an error code, Value - error details.

Var mExchangeRuleTemplateList Export;


////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCESSING MODULE VARIABLES

Var mExportedObjectCounter Export;   // Number - counter of exported objects.
Var mSnCounter Export;   // Number - an sequence number counter.
Var mPropertyConversionRulesTable;      // ValueTable - a template for restoring the table structure by copying.
                                             //                   
Var mXMLRules;                           // XML string that contains exchange rule description.
Var mTypesForDestinationRow;


////////////////////////////////////////////////////////////////////////////////
// IMPORT PROCESSING MODULE VARIABLES

Var mImportedObjectCounter Export;// Number - imported object counter.

Var mExchangeFileAttributes Export;       // Structure. After opening the file it contains exchange file attributes according to the format.

Var ImportedObjects Export;         // Map. Key - object sequence number in file,
                                          // Value - a reference to the imported object.
Var ImportedGlobalObjects Export;
Var ImportedObjectToStoreCount Export;  // Number of stored imported objects. If the number of imported object exceeds the value of this 
                                          // variable, the ImportedObjects map is cleared.
                                          // 
Var RememberImportedObjects Export;

Var mExtendedSearchParameterMap;
Var mConversionRulesMap; // Map to define an object conversion rule by this object type.

Var mDataImportDataProcessor Export;

Var mEmptyTypeValueMap;
Var mTypeDescriptionMap;

Var mExchangeRulesReadOnImport Export;

Var mDataExportCallStack;

Var mDataTypeMapForImport;

Var mNotWrittenObjectGlobalStack;

Var EventsAfterParametersImport Export;

Var CurrentNestingLevelExportByRule;

////////////////////////////////////////////////////////////////////////////////
// VARIABLES TO STORE STANDARD SUBSYSTEM MODULES

Var ModulePeriodClosingDates;

#EndRegion

#Region Public

#Region StringOperations

// Splits a string into two parts: before the separator substring and after it.
//
// Parameters:
//  Str          - String - a string to be split;
//  Separator  - String - a separator substring:
//  Mode        - Number -0 - separator is not included in the returned substrings.
//                        1 - separator is included in the left substring.
//                        2 - separator is included in the right substring.
//
// Returns:
//  The right part of the string - before the separator character.
// 
Function SplitWithSeparator(Str, Val Separator, Mode=0) Export

	RightPart         = "";
	SeparatorPos      = StrFind(Str, Separator);
	SeparatorLength    = StrLen(Separator);
	If SeparatorPos > 0 Then
		RightPart	 = Mid(Str, SeparatorPos + ?(Mode=2, 0, SeparatorLength));
		Str          = TrimAll(Left(Str, SeparatorPos - ?(Mode=1, -SeparatorLength + 1, 1)));
	EndIf;

	Return(RightPart);

EndFunction

// Converts values from a string to an array using the specified separator.
//
// Parameters:
//  Str            - String - a string to be split.
//  Separator    - String - a separator substring.
//
// Returns:
//  Array - received array of values.
// 
Function ArrayFromString(Val Str, Separator=",") Export

	Array      = New Array;
	RightPart = SplitWithSeparator(Str, Separator);
	
	While Not IsBlankString(Str) Do
		Array.Add(TrimAll(Str));
		Str         = RightPart;
		RightPart = SplitWithSeparator(Str, Separator);
	EndDo; 

	Return(Array);
	
EndFunction

// Splits the string into several strings by the separator. The separator can be any length.
//
// Parameters:
//  String                 - String - delimited text;
//  Separator            - String - a text separator, at least 1 character;
//  SkipBlankStrings - Boolean - indicates whether blank strings must be included in the result.
//    If this parameter is not set, the function executes in compatibility with its earlier version.
//     - if space is used as a separator, blank strings are not included in the result, for other 
//       separators blank strings are included in the result.
//     - if the String parameter does not contain significant characters (or it is an blank string) and 
//       space is used as a separator, the function returns an array with a single blank string value (""). 
//     - if the String parameter does not contain significant characters (or it is an blank string) and 
//       any character except space is used as a separator, the function returns an empty array.
//
//
//// Returns:
//  Array - an array of strings.
//
// Example:
//  SplitStringIntoSubstringsArray(",One,,Two,", ",") - returns an array of 5 items, three of 
//  which are blank strings;
//  SplitStringIntoSubstringsArray(",one,,two,", ",", True) - returns an array of two items;
//  SplitStringIntoSubstringsArray(" one   two  ", " ") - returns an array of two items;
//  SplitStringIntoSubstringsArray("") - returns an emtpy array;
//  SplitStringIntoSubstringsArray("",,False) - returns an array of one item "" (blank string);
//  SplitStringIntoSubstringsArray - returns an array of one item "" (blank string);
//
Function SplitStringIntoSubstringsArray(Val String, Val Separator = ",", Val SkipBlankStrings = Undefined) Export
	
	Result = New Array;
	
	// This procedure ensures backward compatibility.
	If SkipBlankStrings = Undefined Then
		SkipBlankStrings = ?(Separator = " ", True, False);
		If IsBlankString(String) Then 
			If Separator = " " Then
				Result.Add("");
			EndIf;
			Return Result;
		EndIf;
	EndIf;
	//
	
	Position = StrFind(String, Separator);
	While Position > 0 Do
		Substring = Left(String, Position - 1);
		If Not SkipBlankStrings Or Not IsBlankString(Substring) Then
			Result.Add(Substring);
		EndIf;
		String = Mid(String, Position + StrLen(Separator));
		Position = StrFind(String, Separator);
	EndDo;
	
	If Not SkipBlankStrings Or Not IsBlankString(String) Then
		Result.Add(String);
	EndIf;
	
	Return Result;
	
EndFunction 

// Returns a number in the string format without a character prefix.
// Example:
//  GetStringNumberWithoutPrefixes("TM0000001234") = "0000001234"
//
// Parameters:
//  Number - String - a number, from which the function result must be calculated.
// 
// Returns:
//   String - a number string without character prefixes.
//
Function GetStringNumberWithoutPrefixes(Number) Export
	
	NumberWithoutPrefixes = "";
	Cnt = StrLen(Number);
	
	While Cnt > 0 Do
		
		Char = Mid(Number, Cnt, 1);
		
		If (Char >= "0" And Char <= "9") Then
			
			NumberWithoutPrefixes = Char + NumberWithoutPrefixes;
			
		Else
			
			Return NumberWithoutPrefixes;
			
		EndIf;
		
		Cnt = Cnt - 1;
		
	EndDo;
	
	Return NumberWithoutPrefixes;
	
EndFunction

// Splits a string into a prefix and numerical part.
//
// Parameters:
//  Str            - String - a string to be split;
//  NumericalPart  - Number - a variable that contains numeric part of the passed string.
//  Mode          - String -  if "Number", then returns the numerical part otherwise returns a prefix.
//
// Returns:
//  String - a string prefix.
//
Function GetNumberPrefixAndNumericalPart(Val Str, NumericalPart = "", Mode = "") Export

	NumericalPart = 0;
	Prefix = "";
	Str = TrimAll(Str);
	Length   = StrLen(Str);
	
	StringNumberWithoutPrefix = GetStringNumberWithoutPrefixes(Str);
	StringPartLength = StrLen(StringNumberWithoutPrefix);
	If StringPartLength > 0 Then
		NumericalPart = Number(StringNumberWithoutPrefix);
		Prefix = Mid(Str, 1, Length - StringPartLength);
	Else
		Prefix = Str;	
	EndIf;

	If Mode = "Number" Then
		Return(NumericalPart);
	Else
		Return(Prefix);
	EndIf;

EndFunction

// Casts the number (code) to the required length, splitting the number into a prefix and numeric part. 
// The space between the prefix and number is filled with zeros.
// 
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
//
// Parameters:
//  Str          - String - a string to be converted.
//  Length        - Number - required length of a string.
//  AddZerosIfLengthNotLessNumberCurrentLength - Boolean - indicates that it is necessary to add zeros.
//  Prefix      - String - a prefix to be added to the number.
//
// Returns:
//  String       - a code or number cast to the required length.
// 
Function CastNumberToLength(Val Str, Length, AddZerosIfLengthNotLessNumberCurrentLength = True, Prefix = "") Export

	If IsBlankString(Str)
		Or StrLen(Str) = Length Then
		
		Return Str;
		
	EndIf;
	
	Str             = TrimAll(Str);
	NumberIncomingLength = StrLen(Str);

	NumericalPart   = "";
	StringNumberPrefix   = GetNumberPrefixAndNumericalPart(Str, NumericalPart);
	
	FinalPrefix = ?(IsBlankString(Prefix), StringNumberPrefix, Prefix);
	ResultingPrefixLength = StrLen(FinalPrefix);
	
	NumericPartString = Format(NumericalPart, "NG=0");
	NumericPartLength = StrLen(NumericPartString);

	If (Length >= NumberIncomingLength And AddZerosIfLengthNotLessNumberCurrentLength)
		Or (Length < NumberIncomingLength) Then
		
		For TemporaryVariable = 1 To Length - ResultingPrefixLength - NumericPartLength Do
			
			NumericPartString = "0" + NumericPartString;
			
		EndDo;
	
	EndIf;
	
	// Cutting excess symbols
	NumericPartString = Right(NumericPartString, Length - ResultingPrefixLength);
		
	Result = FinalPrefix + NumericPartString;

	Return Result;

EndFunction

// Adds a substring to a number of code prefix.
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  Str          - String - a number or code.
//  Additive      - String - a substring to be added to a prefix.
//  Length        - Number - required resulting length of a string.
//  Mode        - String - pass "Left" if you want to add substring from the left, otherwise the substring will be added from the right.
//
// Returns:
//  String       - a number or code with the specified substring added to the prefix.
//
Function AddToPrefix(Val Str, Additive = "", Length = "", Mode = "Left") Export

	Str = TrimAll(Format(Str,"NG=0"));

	If IsBlankString(Length) Then
		Length = StrLen(Str);
	EndIf;

	NumericalPart   = "";
	Prefix         = GetNumberPrefixAndNumericalPart(Str, NumericalPart);

	If Mode = "Left" Then
		Result = TrimAll(Additive) + Prefix;
	Else
		Result = Prefix + TrimAll(Additive);
	EndIf;

	While Length - StrLen(Result) - StrLen(Format(NumericalPart, "NG=0")) > 0 Do
		Result = Result + "0";
	EndDo;

	Result = Result + Format(NumericalPart, "NG=0");

	Return Result;

EndFunction

// Supplements string with the specified symbol to the specified length.
//
// Parameters:
//  Str          - String - string to be supplemented;
//  Length        - Number - required length of a resulting string.
//  Symbol          - String - a character used for supplementing the string.
//
// Returns:
//  String - the received string that is supplemented with the specified symbol to the specified length.
//
Function deSupplementString(Str, Length, Symbol = " ") Export

	Result = TrimAll(Str);
	While Length - StrLen(Result) > 0 Do
		Result = Result + Symbol;
	EndDo;

	Return(Result);

EndFunction

#EndRegion

#Region DataOperations

// Returns a string - a name of the passed enumeration value.
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  Value     - EnumRef - an enumeration value.
//
// Returns:
//  String       - a name of the passed enumeration value.
//
Function deEnumValueName(Value) Export

	MDObject = Value.Metadata();

	EnumManager = Enums[MDobject.Name]; // EnumManager
	ValueIndex = EnumManager.IndexOf(Value);

	Return MDobject.EnumValues.Get(ValueIndex).Name;

EndFunction

// Defines whether the passed value is filled.
//
// Parameters:
//  Value       - Arbitrary - CatalogRef, DocumentRef, string or any other type.
//                   Value to be checked.
//  IsNULL        - Boolean - if the passed value is NULL, this variable is set to True.
//
// Returns:
//  Boolean - True, if the value is not filled in.
//
Function deEmpty(Value, IsNULL=False) Export

	// Primitive types first
	If Value = Undefined Then
		Return True;
	ElsIf Value = NULL Then
		IsNULL   = True;
		Return True;
	EndIf;
	
	ValueType = TypeOf(Value);
	
	If ValueType = deValueStorageType Then
		
		Result = deEmpty(Value.Get());
		Return Result;
		
	ElsIf ValueType = deBinaryDataType Then
		
		Return False;
		
	Else
		
		// The value is considered empty if it is equal to the default value of its type. 
		Try
			Return Not ValueIsFilled(Value);
		Except
			// In case of mutable values.
			Return False;
		EndTry;
	EndIf;
	
EndFunction

// Returns the TypeDescription object that contains the specified type.
//
// Parameters:
//  TypeValue - String, Type - contains a type name or value of the Type type.
//  
// Returns:
//  TypeDescription - the Type description object.
//
Function deTypeDescription(TypeValue) Export
	
	TypeDescription = mTypeDescriptionMap[TypeValue];
	
	If TypeDescription = Undefined Then
		
		TypesArray = New Array;
		If TypeOf(TypeValue) = deStringType Then
			TypesArray.Add(Type(TypeValue));
		Else
			TypesArray.Add(TypeValue);
		EndIf; 
		TypeDescription	= New TypeDescription(TypesArray);
		
		mTypeDescriptionMap.Insert(TypeValue, TypeDescription);
		
	EndIf;
	
	Return TypeDescription;
	
EndFunction

// Returns the empty (default) value of the specified type.
//
// Parameters:
//  Type          - String, Type - a type name or value of the Type type.
//
// Returns:
//  Arbitrary - an empty value of the specified type.
// 
Function deGetEmptyValue(Type) Export

	EmptyTypeValue = mEmptyTypeValueMap[Type];
	
	If EmptyTypeValue = Undefined Then
		
		EmptyTypeValue = deTypeDescription(Type).AdjustValue(Undefined);
		mEmptyTypeValueMap.Insert(Type, EmptyTypeValue);
		
	EndIf;
	
	Return EmptyTypeValue;

EndFunction

// Performs a simple search for infobase object by the specified property.
//
// Parameters:
//  Manager       - CatalogManager, DocumentManager - manager of the object to be searched.
//  Property       - String - a property to implement the search: Name, Code, 
//                   Description or a Name of an indexed attribute.
//  Value       - String, Number, Date - value of a property to be used for searching the object.
//  FoundByUUIDObject - CatalogObject, DocumentObject - an infobase object that was found by UUID 
//                   while executing function.
//  CommonPropertyStructure - structure - properties of the object to be searched.
//  CommonSearchProperties - Structure - common properties of the search.
//  SearchByUUIDQueryString - String - a query text for to search by UUID.
//
// Returns:
//  Arbitrary - found infobase object.
//
Function FindObjectByProperty(Manager, Property, Value, FoundByUUIDObject,
	CommonPropertyStructure = Undefined, CommonSearchProperties = Undefined,
	SearchByUUIDQueryString = "") Export
	
	If CommonPropertyStructure = Undefined Then
		Try
			CurrPropertiesStructure = Managers[TypeOf(Manager.EmptyRef())];
			TypeName = CurrPropertiesStructure.TypeName;
		Except
			TypeName = "";
		EndTry;
	Else
		TypeName = CommonPropertyStructure.TypeName;
	EndIf;
	
	If Property = "Name" Then
		
		Return Manager[Value];

	ElsIf Property = "Code"
		And (TypeName = "Catalog" Or TypeName = "ChartOfCharacteristicTypes" Or TypeName = "ChartOfAccounts"
		Or TypeName = "ExchangePlan" Or TypeName = "ChartOfCalculationTypes") Then
		
		Return Manager.FindByCode(Value);

	ElsIf Property = "Description"
		And (TypeName = "Catalog" Or TypeName = "ChartOfCharacteristicTypes" Or TypeName = "ChartOfAccounts"
		Or TypeName = "ExchangePlan" Or TypeName = "ChartOfCalculationTypes" Or TypeName = "Task") Then
		
		Return Manager.FindByDescription(Value, True);

	ElsIf Property = "Number" And (TypeName = "Document" Or TypeName = "BusinessProcess" Or TypeName = "Task") Then
		
		Return Manager.FindByNumber(Value);

	ElsIf Property = "{UUID}" Then
		
		RefByUUID = Manager.GetRef(New UUID(Value));
		
		Ref = CheckRefExists(RefByUUID, Manager, FoundByUUIDObject,
			SearchByUUIDQueryString);
			
		Return Ref;

	ElsIf Property = "{PredefinedItemName}" Then
		
		Try
			
			Ref = Manager[Value];
			
		Except
			
			Ref = Manager.FindByCode(Value);
			
		EndTry;
		
		Return Ref;

	Else
		
		// Search is possible only by attribute, except for strings of arbitrary length and value storages.
		If Not (Property = "Date" Or Property = "Posted" Or Property = "DeletionMark" Or Property = "Owner"
			Or Property = "Parent" Or Property = "IsFolder") Then

			Try
				
				UnlimitedLengthString = IsUnlimitedLengthParameter(CommonPropertyStructure, Value, Property);
				
			Except
				
				UnlimitedLengthString = False;
				
			EndTry;
			
			If NOT UnlimitedLengthString Then
				
				Return Manager.FindByAttribute(Property, Value);
				
			EndIf;
			
		EndIf;
		
		ObjectRef = FindItemUsingRequest(CommonPropertyStructure, CommonSearchProperties, , Manager);
		Return ObjectRef;
		
	EndIf;
	
EndFunction

// Performs a simple search for infobase object by the specified property.
//
// Parameters:
//  Str            - String - a property value, by which an object is searched.
//                   
//  Type            - Type - type of the document to be searched.
//  Property       - String - a property name, by which an object is searched.
//
// Returns:
//  Arbitrary - found infobase object.
//
Function deGetValueByString(Str, Type, Property = "") Export

	If IsBlankString(Str) Then
		Return New(Type);
	EndIf; 

	Properties = Managers[Type];

	If Properties = Undefined Then
		
		TypeDescription = deTypeDescription(Type);
		Return TypeDescription.AdjustValue(Str);
		
	EndIf;

	If IsBlankString(Property) Then
		
		If Properties.TypeName = "Enum" Then
			Property = "Name";
		Else
			Property = "{PredefinedItemName}";
		EndIf;
		
	EndIf;
	
	Return FindObjectByProperty(Properties.Manager, Property, Str, Undefined);
	
EndFunction

// Returns a string presentation of a value type.
//
// Parameters:
//  ValueOrType - Arbitrary - a value of any type or Type.
//
// Returns:
//  String - a string presentation of the value type.
//
Function deValueTypeAsString(ValueOrType) Export

	ValueType	= TypeOf(ValueOrType);
	
	If ValueType = deTypeType Then
		ValueType	= ValueOrType;
	EndIf; 
	
	If (ValueType = Undefined) Or (ValueOrType = Undefined) Then
		Result = "";
	ElsIf ValueType = deStringType Then
		Result = "String";
	ElsIf ValueType = deNumberType Then
		Result = "Number";
	ElsIf ValueType = deDateType Then
		Result = "Date";
	ElsIf ValueType = deBooleanType Then
		Result = "Boolean";
	ElsIf ValueType = deValueStorageType Then
		Result = "ValueStorage";
	ElsIf ValueType = deUUIDType Then
		Result = "UUID";
	ElsIf ValueType = deAccumulationRecordTypeType Then
		Result = "AccumulationRecordType";
	Else
		Manager = Managers[ValueType];
		If Manager = Undefined Then
			
			Text= NStr("ru='Неизвестный тип:'; en = 'Unknown type:'") + String(TypeOf(ValueType));
			MessageToUser(Text);
			
		Else
			Result = Manager.RefTypeString;
		EndIf;
	EndIf;

	Return Result;
	
EndFunction

// Returns an XML presentation of the TypeDescription object.
// Can be used in the event handlers whose script is stored in data exchange rules.
// 
// Parameters:
//  TypeDescription  - TypeDescription - a TypeDescription object whose XML presentation is being retrieved.
//
// Returns:
//  String - an XML presentation of the passed TypeDescription object.
//
Function deGetTypesDescriptionXMLPresentation(TypeDescription) Export
	
	TypesNode = CreateNode("Types");
	
	If TypeOf(TypeDescription) = Type("Structure") Then
		SetAttribute(TypesNode, "AllowedSign",          TrimAll(TypeDescription.AllowedSign));
		SetAttribute(TypesNode, "Digits",             TrimAll(TypeDescription.Digits));
		SetAttribute(TypesNode, "FractionDigits", TrimAll(TypeDescription.FractionDigits));
		SetAttribute(TypesNode, "Length",                   TrimAll(TypeDescription.Length));
		SetAttribute(TypesNode, "AllowedLength",         TrimAll(TypeDescription.AllowedLength));
		SetAttribute(TypesNode, "DateComposition",              TrimAll(TypeDescription.DateFractions));
		
		For each StrType In TypeDescription.Types Do
			NodeOfType = CreateNode("Type");
			NodeOfType.WriteText(TrimAll(StrType));
			AddSubordinateNode(TypesNode, NodeOfType);
		EndDo;
	Else
		NumberQualifiers       = TypeDescription.NumberQualifiers;
		StringQualifiers      = TypeDescription.StringQualifiers;
		DateQualifiers        = TypeDescription.DateQualifiers;
		
		SetAttribute(TypesNode, "AllowedSign",          TrimAll(NumberQualifiers.AllowedSign));
		SetAttribute(TypesNode, "Digits",             TrimAll(NumberQualifiers.Digits));
		SetAttribute(TypesNode, "FractionDigits", TrimAll(NumberQualifiers.FractionDigits));
		SetAttribute(TypesNode, "Length",                   TrimAll(StringQualifiers.Length));
		SetAttribute(TypesNode, "AllowedLength",         TrimAll(StringQualifiers.AllowedLength));
		SetAttribute(TypesNode, "DateComposition",              TrimAll(DateQualifiers.DateFractions));
		
		For each Type In TypeDescription.Types() Do
			NodeOfType = CreateNode("Type");
			NodeOfType.WriteText(deValueTypeAsString(Type));
			AddSubordinateNode(TypesNode, NodeOfType);
		EndDo;
	EndIf;
	
	TypesNode.WriteEndElement();
	
	Return(TypesNode.Close());
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsToWorkWithXMLWriterObject

// Replaces prohibited XML characters with other character.
//
// Parameters:
//       Text - String - a text where the characters are to be changed.
//       ReplacementChar - String - a value, by which the prohibited characters will be changed.
// Returns:
//       String - replacement result.
//
Function ReplaceProhibitedXMLChars(Val Text, ReplacementChar = " ") Export
	
	Position = FindDisallowedXMLCharacters(Text);
	While Position > 0 Do
		Text = StrReplace(Text, Mid(Text, Position, 1), ReplacementChar);
		Position = FindDisallowedXMLCharacters(Text);
	EndDo;
	
	Return Text;
EndFunction

// Creates a new XML node
// The function can be used in event handlers, application code.
// of which is stored in the data exchange rules. Is called with the Execute() method.
//
// Parameters:
//  Name  - String - a node name.
//
// Returns:
//  XMLWriter - an object of the new XML node.
//
Function CreateNode(Name) Export

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement(Name);

	Return XMLWriter;

EndFunction

// Adds a new XML node to the specified parent node.
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  ParentNode - parent XML node.
//  Name - String - a name of the node to be added.
//
// Returns:
//  New XML node added to the specified parent node.
//
Function AddNode(ParentNode, Name) Export

	ParentNode.WriteStartElement(Name);

	Return ParentNode;

EndFunction

// Copies the specified xml node.
// Can be used in the event handlers whose script is stored in data exchange rules.
//  Is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  Node - XML node.
//
// Returns:
//  New xml is a copy of the specified node.
//
Function CopyNode(Node) Export

	Str = Node.Close();

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	
	If XMLWriterAdvancedMonitoring Then
		
		Str = DeleteProhibitedXMLChars(Str);
		
	EndIf;
	
	XMLWriter.WriteRaw(Str);

	Return XMLWriter;
	
EndFunction

// Writes an element and its value to the specified object.
//
// Parameters:
//  Object - XMLWriter - an object of the XMLWriter type.
//  Name            - String - an element name.
//  Value       - Arbitrary - element value.
// 
Procedure deWriteElement(Object, Name, Value="") Export

	Object.WriteStartElement(Name);
	Str = XMLString(Value);
	
	If XMLWriterAdvancedMonitoring Then
		
		Str = DeleteProhibitedXMLChars(Str);
		
	EndIf;
	
	Object.WriteText(Str);
	Object.WriteEndElement();
	
EndProcedure

// Subordinates an xml node to the specified parent node.
//
// Parameters:
//  ParentNode - parent XML node.
//  Node           - XML - a node to be subordinated.
//
Procedure AddSubordinateNode(ParentNode, Node) Export

	If TypeOf(Node) <> deStringType Then
		Node.WriteEndElement();
		InformationToWriteToFile = Node.Close();
	Else
		InformationToWriteToFile = Node;
	EndIf;
	
	ParentNode.WriteRaw(InformationToWriteToFile);
		
EndProcedure

// Sets an attribute of the specified xml node.
//
// Parameters:
//  Node - XML node
//  Name            - String - an attribute name.
//  Value - Arbitrary - a value to set.
//
Procedure SetAttribute(Node, Name, Value) Export

	StringToWrite = XMLString(Value);
	
	If XMLWriterAdvancedMonitoring Then
		
		StringToWrite = DeleteProhibitedXMLChars(StringToWrite);
		
	EndIf;
	
	Node.WriteAttribute(Name, StringToWrite);
	
EndProcedure

#EndRegion

#Region ProceeduresAndFunctionsToWorkWithXMLReaderObject

// Reads the attribute value by the name from the specified object, converts the value to the 
// specified primitive type.
//
// Parameters:
//  Object      - XMLReader - XMLReader object positioned to the beginning of the item whose 
//                attribute is required.
//  Type        - Type - an attribute type.
//  Name         - String - an attribute name.
//
// Returns:
//  Arbitrary - an attribute value received by the name and cast to the specified type.
//
Function deAttribute(Object, Type, Name) Export

	ValueStr = Object.GetAttribute(Name);
	If Not IsBlankString(ValueStr) Then
		Return XMLValue(Type, TrimR(ValueStr));
	ElsIf Type = deStringType Then
		Return ""; 
	ElsIf Type = deBooleanType Then
		Return False;
	ElsIf Type = deNumberType Then
		Return 0;
	ElsIf Type = deDateType Then
		Return BlankDateValue;
	EndIf;
		
EndFunction
 
// Skips xml nodes to the end of the specified item (current item by default).
//
// Parameters:
//  Object   - XMLReader - an object of the XMLReader type.
//  Name      - String - a name of node, to the end of which items are skipped.
//
Procedure deSkip(Object, Name = "") Export

	AttachmentsCount = 0; // Number of attachments with the same name.

	If Name = "" Then
		
		Name = Object.LocalName;
		
	EndIf; 
	
	While Object.Read() Do
		
		If Object.LocalName <> Name Then
			Continue;
		EndIf;
		
		NodeType = Object.NodeType;
			
		If NodeType = deXMLNodeType_EndElement Then
				
			If AttachmentsCount = 0 Then
					
				Break;
					
			Else
					
				AttachmentsCount = AttachmentsCount - 1;
					
			EndIf;
				
		ElsIf NodeType = deXMLNodeType_StartElement Then
				
			AttachmentsCount = AttachmentsCount + 1;
				
		EndIf;
					
	EndDo;
	
EndProcedure

// Reads the element text and converts the value to the specified type.
//
// Parameters:
//  Object           - XMLReader - XMLReader object whose data will be read.
//  Type              - Type - type of the value to be received.
//  SearchByProperty - String - for reference types, contains a property, by which
//                     search will be implemented for the following object: Code, Description, <AttributeName>, Name (of the predefined value).
//  TrimStringRight - Boolean - True, if it is needed to trim a string from the right.
//
// Returns:
//  Value of an XML element converted to the relevant type.
//
Function deElementValue(Object, Type, SearchByProperty = "", TrimStringRight = True) Export

	Value = "";
	Name      = Object.LocalName;

	While Object.Read() Do
		
		NodeType = Object.NodeType;
		
		If NodeType = deXMLNodeType_Text Then
			
			Value = Object.Value;
			
			If TrimStringRight Then
				
				Value = TrimR(Value);
				
			EndIf;
						
		ElsIf (Object.LocalName = Name) And (NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	EndDo;
	If (Type = deStringType) Or (Type = deBooleanType) Or (Type = deNumberType) Or (Type = deDateType)
		Or (Type = deValueStorageType) Or (Type = deUUIDType) Or (Type = deAccumulationRecordTypeType)
		Or (Type = deAccountTypeType) Then
		
		Return XMLValue(Type, Value);
		
	Else
		
		Return deGetValueByString(Value, Type, SearchByProperty);
		
	EndIf;
	
EndFunction

#КонецОбласти

#Region ExchangeFileOperationsProceduresAndFunctions

// Saves the specified xml node to the file.
//
// Parameters:
//  Node - XML node to be saved to the file.
//
Procedure WriteToFile(Node) Export

	If TypeOf(Node) <> deStringType Then
		InformationToWriteToFile = Node.Close();
	Else
		InformationToWriteToFile = Node;
	EndIf;
	
	If DirectReadFromDestinationIB Then
		
		ErrorStringInDestinationInfobase = "";
		SendWriteInformationToDestination(InformationToWriteToFile, ErrorStringInDestinationInfobase);
		If Not IsBlankString(ErrorStringInDestinationInfobase) Then
			
			Raise ErrorStringInDestinationInfobase;
			
		EndIf;
		
	Else
		
		ExchangeFile.WriteLine(InformationToWriteToFile);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ExchangeLogOperationsProceduresAndFunctions

// Returns a Structure type object containing all possible fields of the execution log record 
// (such as error messages and others).
//
// Parameters:
//  MessageCode - String - a message code.
//  ErrorString - String - error string content.
//
// Returns:
//  Structure - all possible fields of the execution log.
//
Function GetProtocolRecordStructure(MessageCode = "", ErrorString = "") Export

	ErrorStructure = New Structure("OCRName,DPRName,Sn,Gsn,Source,ObjectType,Property,Value,ValueType,OCR,PCR,PGCR,DER,DCR,Object,DestinationProperty,ConvertedValue,Handler,ErrorDescription,ModulePosition,Text,MessageCode,ExchangePlanNode");
	
	ModuleLine              = SplitWithSeparator(ErrorString, "{");
	If IsBlankString(ErrorString) Then
		ErrorDescription = TrimAll(SplitWithSeparator(ModuleLine, "}:"));
	Else
		ErrorDescription = ErrorString;
		ModuleLine   = "{" + ModuleLine;
	EndIf;

	If ErrorDescription <> "" Then
		ErrorStructure.ErrorDescription         = ErrorDescription;
		ErrorStructure.ModulePosition          = ModuleLine;				
	EndIf;
	
	If ErrorStructure.MessageCode <> "" Then
		
		ErrorStructure.MessageCode           = MessageCode;
		
	EndIf;
	
	Return ErrorStructure;
	
EndFunction 

// Writes error details to the exchange log.
//
// Parameters:
//  MessageCode - String - a message code.
//  ErrorString - String - error string content.
//  Object - Arbitrary - object, which the error is related to.
//  ObjectType - Type - type of the object, which the error is related to.
//
// Returns:
//  String - an error string.
//
Function WriteErrorInfoToProtocol(MessageCode, ErrorString, Object, ObjectType = Undefined) Export
	
	WP         = GetProtocolRecordStructure(MessageCode, ErrorString);
	WP.Object  = Object;
	
	If ObjectType <> Undefined Then
		WP.ObjectType     = ObjectType;
	EndIf;	
		
	ErrorRow = WriteToExecutionLog(MessageCode, WP);	
	
	Return ErrorRow;	
	
EndFunction

// Registers the error of object conversion rule handler (import) in the execution log.
//
// Parameters:
//  MessageCode - String - a message code.
//  ErrorString - String - error string content.
//  RuleName - String - a name of an object conversion rule.
//  Source - Arbitrary - source, which conversion caused an error.
//  ObjectType - Type - type of the object, which conversion caused an error.
//  Object - Arbitrary - an object received as a result of conversion.
//  HandlerName - String - name of the handler where an error occurred.
//
Procedure WriteInfoOnOCRHandlerImportError(MessageCode, ErrorString, RuleName, Source,
	ObjectType, Object, HandlerName) Export
	
	LR            = GetLogRecordStructure(MessageCode, ErrorString);
	LR.OCRName     = RuleName;
	LR.ObjectType = ObjectType;
	LR.Handler = HandlerName;
	
	If Not IsBlankString(Source) Then
		
		LR.Source = Source;
		
	EndIf;
	
	If Object <> Undefined Then
		
		LR.Object = String(Object);
		
	EndIf;
	
	ErrorMessageString = WriteToExecutionLog(MessageCode, LR);
	
	If Not DebugModeFlag Then
		Raise ErrorMessageString;
	EndIf;
	
EndProcedure

// Registers the error of property conversion rule handler in the execution protocol.
//
// Parameters:
//  MessageCode - String - a message code.
//  ErrorString - String - error string content.
//  OCR - ValueTableRow - a property conversion rule.
//  PCR - ValueTableRow - a property conversion rule.
//  Source - Arbitrary - source, which conversion caused an error.
//  HandlerName - String - name of the handler where an error occurred.
//  Value - Arbitrary - value, which conversion caused an error.
//  IsPCR - Boolean - an error occurred when processing the rule of property conversion.
//
Procedure WriteErrorInfoPCRHandlers(MessageCode, ErrorString, OCR, PCR, Source = "", 
	HandlerName = "", Value = Undefined, IsPCR = True) Export

	LR                        = GetLogRecordStructure(MessageCode, ErrorString);
	LR.OCR                    = OCR.Name + "  (" + OCR.Description + ")";

	RuleName = PCR.Name + "  (" + PCR.Description + ")";
	If IsPCR Then
		LR.PCR                = RuleName;
	Else
		LR.PGCR               = RuleName;
	EndIf;
	
	TypesDetails = New TypeDescription("String");
	StringSource  = TypesDetails.AdjustValue(Source);
	If Not IsBlankString(StringSource) Then
		LR.Object = StringSource + "  (" + TypeOf(Source) + ")";
	Else
		LR.Object = "(" + TypeOf(Source) + ")";
	EndIf;
	
	If IsPCR Then
		LR.DestinationProperty      = PCR.Destination + "  (" + PCR.DestinationType + ")";
	EndIf;
	
	If HandlerName <> "" Then
		LR.Handler         = HandlerName;
	EndIf;
	
	If Value <> Undefined Then
		LR.ConvertedValue = String(Value) + "  (" + TypeOf(Value) + ")";
	EndIf;
	
	ErrorMessageString = WriteToExecutionLog(MessageCode, LR);
	
	If Not DebugModeFlag Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure

#EndRegion

#Region GeneratingHandlerCallInterfacesInExchangeRulesProcedures

// Complements existing collections with rules for exchanging handler call interfaces.
//
// Parameters:
//  ConversionStructure - Structure - contains the conversion rules and global handlers.
//  OCRTable           - ValueTable - contains object conversion rules.
//  DERTable           - ValuesTree - contains the data export rules.
//  DCRTable           - ValuesTree - contains data clearing rules.
//  
Procedure SupplementRulesWithHandlerInterfaces(ConversionStructure, OCRTable, DERTable, DCRTable) Export
	
	mHandlerParameterTemplate = GetTemplate("HandlersParameters");
	
	// Adding the Conversion interfaces (global).
	SupplementConversionRulesWithHandlerInterfaces(ConversionStructure);
	
	// Adding the DER interfaces
	SupplementDataExportRulesWithHandlerInterfaces(DERTable, DERTable.Rows);
	
	// Adding DCR interfaces.
	SupplementDataClearingRulesWithHandlerInterfaces(DCRTable, DCRTable.Rows);
	
	// Adding OCR, PCR, PGCR interfaces.
	SupplementObjectConversionRulesWithHandlerInterfaces(OCRTable);
	
EndProcedure 

#EndRegion

#Region ExchangeRulesOperationProcedures

// Searches for the conversion rule by name or according to the passed object type.
// 
//
// Parameters:
//  Object         -  a source object whose conversion rule will be searched.
//  RuleName     - String - a conversion rule name.
//
// Returns:
//  ValueTableRow - a conversion rule reference (a row in the rules table):
//     * Name - String -
//     * Description - String -
//     * Source - String -
//     * Properties - see PropertyConversionRulesCollection.
// 
Function FindRule(Object = Undefined, RuleName="") Export

	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		
	Else
		
		Rule = Managers[TypeOf(Object)];
		If Rule <> Undefined Then
			Rule    = Rule.OCR;
			
			If Rule <> Undefined Then 
				RuleName = Rule.Name;
			EndIf;
			
		EndIf; 
		
	EndIf;
	
	Return Rule; 
	
EndFunction

// Saves exchange rules in the internal format.
//
Procedure SaveRulesInInternalFormat() Export

	For Each Rule In ConversionRulesTable Do
		Rule.Exported.Clear();
		Rule.OnlyRefsExported.Clear();
	EndDo;

	RulesStructure = RulesStructureDetails();
	
	// Saving queries
	QueriesToSave = New Structure;
	For Each StructureItem In Queries Do
		QueriesToSave.Insert(StructureItem.Key, StructureItem.Value.Text);
	EndDo;

	ParametersToSave = New Structure;
	For Each StructureItem In Parameters Do
		ParametersToSave.Insert(StructureItem.Key, Undefined);
	EndDo;

	RulesStructure.ExportRulesTable = ExportRulesTable;
	RulesStructure.ConversionRulesTable = ConversionRulesTable;
	RulesStructure.Algorithms = Algorithms;
	RulesStructure.Queries = QueriesToSave;
	RulesStructure.Conversion = Conversion;
	RulesStructure.mXMLRules = mXMLRules;
	RulesStructure.ParametersSettingsTable = ParametersSettingsTable;
	RulesStructure.Parameters = ParametersToSave;

	RulesStructure.Insert("DestinationPlatformVersion",   DestinationPlatformVersion);

	SavedSettings  = New ValueStorage(RulesStructure);

EndProcedure

// Sets parameter values in the Parameters structure by the ParametersSettingsTable table.
//
Procedure SetParametersFromDialog() Export

	For Each TableRow In ParametersSettingsTable Do
		Parameters.Insert(TableRow.Name, TableRow.Value);
	EndDo;

EndProcedure

// Sets the parameter value in the parameter table in the data processor form.
//
// Parameters:
//   ParameterName - String - a parameter name.
//   ParameterValue - Arbitrary - parameter value.
//
Procedure SetParameterValueInTable(ParameterName, ParameterValue) Export
	
	TableRow = ParametersSettingsTable.Find(ParameterName, "Name");
	
	If TableRow <> Undefined Then
		
		TableRow.Value = ParameterValue;	
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ClearingRuleProcessing

// Deletes (or marks for deletion) a selection object according to the specified rule.
//
// Parameters:
//  Object - Arbitrary - selection object to be deleted (or to be marked for deletion).
//  Rule        - ValueTableRow - data clearing rule reference.
//  Properties - Manager - metadata object properties of the object to be deleted.
//  IncomingData - Arbitrary - arbitrary auxiliary data.
// 
Procedure SelectionObjectDeletion(Object, Rule, Properties=Undefined, IncomingData=Undefined) Export

	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	Cancel			       = False;
	DeleteDirectly = Rule.Directly;


	// BeforeSelectionObjectDeletion handler
	If Not IsBlankString(Rule.BeforeDelete) Then
	
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "BeforeDelete"));
				
			Else
				
				Execute(Rule.BeforeDelete);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(29, ErrorDescription(), Rule.Name, Object, "BeforeDeleteSelectionObject");
									
		EndTry;
		
		If Cancel Then
		
			Return;
			
		EndIf;
			
	EndIf;	 


	Try
		
		ExecuteObjectDeletion(Object, Properties, DeleteDirectly);
					
	Except
		
		WriteDataClearingHandlerErrorInfo(24, ErrorDescription(), Rule.Name, Object, "");
								
	EndTry;	

EndProcedure

#EndRegion

#Region DataExportProcedures

// Производит выгрузку объекта в соответствии с указанным правилом конвертации.
//
// Параметры:
//  Source				 - Arbitrary - a data source.
//  Destination				 - XMLWriter - a destination object XML node.
//  IncomingData			 - Arbitrary - auxiliary data to execute conversion.                           
//  OutgoingData			 - Arbitrary - auxiliary data passed to property conversion rules.                           
//  OCRName					 - String - a name of the conversion rule used to execute export.
//  RefNode				 - a destination object reference XML node.
//  GetRefNodeOnly - Boolean - if True, the object is not exported but the reference XML node is 
//                             generated.
//  OCR						 - ValueTableRow - conversion rule reference.
//  IsRuleWithGlobalObjectExport - Boolean - a flag of a rule with global object export.
//  SelectionForDataExport - QueryResultSelection - a selection containing data for export. 
//
// Returns:
//  XMLWriter - a reference XML node or a destination value.
//
Function ExportByRule(Source = Undefined, Destination = Undefined, IncomingData = Undefined,
	OutgoingData = Undefined, OCRName = "", RefNode	= Undefined, GetRefNodeOnly	= False,
	OCR	= Undefined, IsRuleWithGlobalObjectExport = False, SelectionForDataExport = Undefined) Export

	Var НеНужноВыгружатьПоСоответствиюЗначений;
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	// Searching for OCR
	If OCR = Undefined Then
		
		OCR = FindRule(Source, OCRName);
		
	ElsIf (Not IsBlankString(OCRName)) And OCR.Name <> OCRName Then
		
		OCR = FindRule(Source, OCRName);
				
	EndIf;

	If OCR = Undefined Then
		
		LR = GetLogRecordStructure(45);
		
		LR.Object = Source;
		LR.ObjectType = TypeOf(Source);
		
		WriteToExecutionLog(45, LR, True); // OCR is not found
		Return Undefined;
		
	EndIf;

	CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule + 1;

	If CommentObjectProcessingFlag Then
		
		TypeDescription = New TypeDescription("String");
		SourceToString = TypeDescription.AdjustValue(Source);
		SourceToString = ?(SourceToString = "", " ", SourceToString);
		
		ObjectRul = SourceToString + "  (" + TypeOf(Source) + ")";
		
		OCRNameString = " OCR: " + TrimAll(OCRName) + "  (" + TrimAll(OCR.Description) + ")";
		
		StringForUser = ?(GetRefNodeOnly, NStr("ru = 'Конвертация ссылки на объект: %1'; en = 'Converting object reference: %1'"), NStr("ru = 'Конвертация объекта: %1'; en = 'Converting object: %1'"));
		StringForUser = SubstituteParametersToString(StringForUser, ObjectRul);
		
		WriteToExecutionLog(StringForUser + OCRNameString, , False, CurrentNestingLevelExportByRule + 1, 7);
		
	EndIf;

	IsRuleWithGlobalObjectExport = ExecuteDataExchangeInOptimizedFormat And OCR.UseQuickSearchOnImport;

	RememberExported       = OCR.RememberExported;
	ExportedObjects          = OCR.Exported;
	ExportedObjectsOnlyRefs = OCR.OnlyRefsExported;
	AllObjectsExported         = OCR.AllObjectsExported;
	DoNotReplaceObjectOnImport = OCR.DoNotReplace;
	DoNotCreateIfNotFound     = OCR.DoNotCreateIfNotFound;
	OnMoveObjectByRefSetGIUDOnly     = OCR.OnMoveObjectByRefSetGIUDOnly;

	AutonumberingPrefix		= "";
	WriteMode     			= "";
	PostingMode 			= "";
	TempFileList = Undefined;

	TypeName          = "";
	PropertyStructure = Managers[OCR.Source];
	If PropertyStructure = Undefined Then
		PropertyStructure = Managers[TypeOf(Source)];
	EndIf;
	
	If PropertyStructure <> Undefined Then
		TypeName = PropertyStructure.TypeName;
	EndIf;

	// ExportedDataKey
	
	If (Source <> Undefined) And RememberExported Then
		If TypeName = "InformationRegister" Or TypeName = "Constants" Or IsBlankString(TypeName) Then
			RememberExported = False;
		Else
			ExportedDataKey = ValueToStringInternal(Source);
		EndIf;
	Else
		ExportedDataKey = OCRName;
		RememberExported = False;
	EndIf;
	
	
	// Variable for storing the predefined item name.
	PredefinedItemName = Undefined;

	// BeforeObjectConversion global handler.
    Cancel = False;	
	If HasBeforeConvertObjectGlobalHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Conversion, "BeforeConvertObject"));

			Else
				
				Execute(Conversion.BeforeConvertObject);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(64, ErrorDescription(), OCR, Source, NStr("ru = 'ПередКонвертациейОбъекта (глобальный)'; en = 'BeforeObjectConversion (global)'"));
		EndTry;
		
		If Cancel Then	//	Canceling further rule processing.
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Destination;
		EndIf;
		
	EndIf;
	
	// BeforeExport handler
	If OCR.HasBeforeExportHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(OCR, "BeforeExport"));
				
			Else
				
				Execute(OCR.BeforeExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(41, ErrorDescription(), OCR, Source, "BeforeExportObject");
		EndTry;
		
		If Cancel Then	//	Canceling further rule processing.
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Destination;
		EndIf;
		
	EndIf;
	
	// Perhaps this data has already been exported.
	If Not AllObjectsExported Then
		
		SN = 0;
		
		If RememberExported Then
			
			RefNode = ExportedObjects[ExportedDataKey];
			If RefNode <> Undefined Then
				
				If GetRefNodeOnly Then
					CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
					Return RefNode;
				EndIf;
				
				ExportedRefNumber = ExportedObjectsOnlyRefs[ExportedDataKey];
				If ExportedRefNumber = Undefined Then
					CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
					Return RefNode;
				Else

					ExportStackRow = DataExportCallStackCollection().Find(ExportedDataKey, "Ref");

					If ExportStackRow <> Undefined Then
						CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
						Return RefNode;
					EndIf;
					
					ExportStackRow = DataExportCallStackCollection().Add();
					ExportStackRow.Ref = ExportedDataKey;
					
					SN = ExportedRefNumber;
				EndIf;
			EndIf;
			
		EndIf;

		If SN = 0 Then

			mSNCounter = mSNCounter + 1;
			SN         = mSNCounter;

		EndIf;
		
		// Preventing cyclic reference existence.
		If RememberExported Then
			
			ExportedObjects[ExportedDataKey] = SN;
			If GetRefNodeOnly Then
				ExportedObjectsOnlyRefs[ExportedDataKey] = SN;
			Else
				
				ExportStackRow = DataExportCallStackCollection().Add();
				ExportStackRow.Ref = ExportedDataKey;
				
			EndIf;
			
		EndIf;
		
	EndIf;

	ValueMap = OCR.Values;
	ValueMapItemCount = ValueMap.Count();
	
	// Predefined item map processing.
	If DestinationPlatform = "V8" Then
		
		// If the name of predefined item is not defined yet, attempting to define it.
		If PredefinedItemName = Undefined Then
			
			If PropertyStructure <> Undefined And ValueMapItemCount > 0
				And PropertyStructure.SearchByPredefinedItemsPossible Then
			
				Try
					PredefinedNameSource = PredefinedItemName(Source);
				Except
					PredefinedNameSource = "";
				EndTry;
				
			Else
				
				PredefinedNameSource = "";
				
			EndIf;
			
			If NOT IsBlankString(PredefinedNameSource)
				And ValueMapItemCount > 0 Then
				
				PredefinedItemName = ValueMap[Source];
				
			Else
				PredefinedItemName = Undefined;
			EndIf;
			
		EndIf;
		
		If PredefinedItemName <> Undefined Then
			ValueMapItemCount = 0;
		EndIf;
		
	Else
		PredefinedItemName = Undefined;
	EndIf;

	DontExportByValueMap = (ValueMapItemCount = 0);
	
	If Not DontExportByValueMap Then
		
		// If value mapping does not contain values, exporting mapping in the ordinary way.
		RefNode = ValueMap[Source];
		If RefNode = Undefined And OCR.SearchProperties.Count() > 0 Then
			
			// Perhaps, this is a conversion from enumeration into enumeration and
			// required VCR is not found. Exporting an empty reference.
			If PropertyStructure.TypeName = "Enum" And StrFind(OCR.Destination, "EnumRef.") > 0 Then
				
				RefNode = "";
				
			Else
						
				DontExportByValueMap = True;	
				
			EndIf;
			
		EndIf;
		
	EndIf;

	MustRememberObject = RememberExported And (Not AllObjectsExported);

	If DontExportByValueMap Then
		
		If OCR.SearchProperties.Count() > 0 Or PredefinedItemName <> Undefined Then
			
			//	Creating reference node
			RefNode = CreateNode("Ref");
			
			If MustRememberObject Then
				
				If IsRuleWithGlobalObjectExport Then
					SetAttribute(RefNode, "Gsn", SN);
				Else
					SetAttribute(RefNode, "Sn", SN);
				EndIf;
				
			EndIf;

			ExportRefOnly = OCR.DoNotExportPropertyObjectsByRefs OR GetRefNodeOnly;
			
			If DoNotCreateIfNotFound Then
				SetAttribute(RefNode, "DoNotCreateIfNotFound", DoNotCreateIfNotFound);
			EndIf;
			
			If OnMoveObjectByRefSetGIUDOnly Then
				SetAttribute(RefNode, "OnMoveObjectByRefSetGIUDOnly", OnMoveObjectByRefSetGIUDOnly);
			EndIf;
			
			ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, OCR.SearchProperties, 
				RefNode, SelectionForDataExport, PredefinedItemName, ExportRefOnly);
			
			RefNode.WriteEndElement();
			RefNode = RefNode.Close();
			
			If MustRememberObject Then
				
				ExportedObjects[ExportedDataKey] = RefNode;
				
			EndIf;
			
		Else
			RefNode = SN;
		EndIf;

	Else
		
		// Searching in the value map by VCR.
		If RefNode = Undefined Then
			// If cannot find by value Map, try to find by search properties.
			RecordStructure = New Structure("Source,SourceType", Source, TypeOf(Source));
			WriteToExecutionLog(71, RecordStructure);
			If ExportStackRow <> Undefined Then
				mDataExportCallStack.Delete(ExportStackRow);
			EndIf;
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Undefined;
		EndIf;
		
		If RememberExported Then
			ExportedObjects[ExportedDataKey] = RefNode;
		EndIf;
		
		If ExportStackRow <> Undefined Then
			mDataExportCallStack.Delete(ExportStackRow);
		EndIf;
		CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
		Return RefNode;
		
	EndIf;

	If GetRefNodeOnly Or AllObjectsExported Then
	
		If ExportStackRow <> Undefined Then
			mDataExportCallStack.Delete(ExportStackRow);
		EndIf;
		CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
		Return RefNode;
		
	EndIf;

	If Destination = Undefined Then
		
		Destination = CreateNode("Object");
		
		If IsRuleWithGlobalObjectExport Then
			SetAttribute(Destination, "Gsn", SN);
		Else
			SetAttribute(Destination, "Sn", SN);
		EndIf;
		
		SetAttribute(Destination, "Type", 			OCR.Destination);
		SetAttribute(Destination, "RuleName",	OCR.Name);
		
		If DontReplaceObjectOnImport Then
			SetAttribute(Destination, "DoNotReplace",	"true");
		EndIf;
		
		If Not IsBlankString(AutonumberingPrefix) Then
			SetAttribute(Destination, "AutonumberingPrefix",	AutonumberingPrefix);
		EndIf;
		
		If Not IsBlankString(WriteMode) Then
			SetAttribute(Destination, "WriteMode",	WriteMode);
			If Not IsBlankString(PostingMode) Then
				SetAttribute(Destination, "PostingMode",	PostingMode);
			EndIf;
		EndIf;
		
		If TypeOf(RefNode) <> deNumberType Then
			AddSubordinateNode(Destination, RefNode);
		EndIf; 
		
	EndIf;

	// OnExport handler
	StandardProcessing = True;
	Cancel = False;
	
	If OCR.HasOnExportHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(OCR, "OnExport"));
				
			Else
				
				Execute(OCR.OnExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(42, ErrorDescription(), OCR, Source, "OnExportObject");
		EndTry;
		
		If Cancel Then	//	Canceling writing the object to a file.
			If ExportStackRow <> Undefined Then
				mDataExportCallStack.Delete(ExportStackRow);
			EndIf;
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return RefNode;
		EndIf;
		
	EndIf;

	// Exporting properties
	If StandardProcessing Then
		
		ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, OCR.Properties, , SelectionForDataExport, ,
			OCR.DoNotExportPropertyObjectsByRefs OR GetRefNodeOnly, TempFileList);
			
	EndIf;
	
	// AfterExport handler
	If OCR.HasAfterExportHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(OCR, "AfterExport"));
				
			Else
				
				Execute(OCR.AfterExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(43, ErrorDescription(), OCR, Source, "AfterExportObject");
		EndTry;
		
		If Cancel Then	//	Canceling writing the object to a file.
			
			If ExportStackRow <> Undefined Then
				mDataExportCallStack.Delete(ExportStackRow);
			EndIf;
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return RefNode;
			
		EndIf;
		
	EndIf;

	If TempFileList = Undefined Then
	
		//	Writing the object to a file
		Destination.WriteEndElement();
		WriteToFile(Destination);
		
	Else
		
		WriteToFile(Destination);
		
		TransferDataFromTemporaryFiles(TempFileList);
		
		WriteToFile("</Object>");
		
	EndIf;
	
	mExportedObjectCounter = 1 + mExportedObjectCounter;

	If MustRememberObject Then
				
		If IsRuleWithGlobalObjectExport Then
			ExportedObjects[ExportedDataKey] = SN;
		EndIf;
		
	EndIf;
	
	If ExportStackRow <> Undefined Then
		mDataExportCallStack.Delete(ExportStackRow);
	EndIf;
	
	CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
	
	// AfterExportToFile handler
	If OCR.HasAfterExportToFileHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(OCR, "AfterExportToFile"));
				
			Else
				
				Execute(OCR.AfterExportToFile);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(76, ErrorDescription(), OCR, Source, "HasAfterExportToFileHandler");
		EndTry;				
				
	EndIf;	
	
	Return RefNode;

EndFunction	//	ExportByRule()

// Returns the fragment of query text that expresses the restriction condition to date interval.
//
// Parameters:
//   Properties - Metadata - metadata object properties.
//   TypeName - String - a type name.
//   TableGroupName - String - a table group name.
//   SelectionForDataClearing - Boolean - a selection for data clearing.
//
// Returns:
//     String - a query fragment with restriction condition for date interval.
//
Function GetRestrictionByDateStringForQuery(Properties, TypeName, TableGroupName = "", SelectionForDataClearing = False) Export
	
	ResultingRestrictionByDate = "";
	
	If Not (TypeName = "Document" Or TypeName = "InformationRegister") Then
		Return ResultingRestrictionByDate;
	EndIf;
	
	If TypeName = "InformationRegister" Then
		
		Nonperiodical = Not Properties.Periodic;
		RestrictionByDateNotRequired = SelectionForDataClearing	OR Nonperiodical;
		
		If RestrictionByDateNotRequired Then
			Return ResultingRestrictionByDate;
		EndIf;
				
	EndIf;

	If IsBlankString(TableGroupName) Then
		RestrictionFieldName = ?(TypeName = "Document", "Date", "Period");
	Else
		RestrictionFieldName = TableGroupName + "." + ?(TypeName = "Document", "Date", "Period");
	EndIf;
	
	If StartDate <> BlankDateValue Then
		
		ResultingRestrictionByDate = "
		|	WHERE
		|		" + RestrictionFieldName + " >= &StartDate";
		
	EndIf;
		
	If EndDate <> BlankDateValue Then
		
		If IsBlankString(ResultingRestrictionByDate) Then
			
			ResultingRestrictionByDate = "
			|	WHERE
			|		" + RestrictionFieldName + " <= &EndDate";
			
		Else
			
			ResultingRestrictionByDate = ResultingRestrictionByDate + "
			|	AND
			|		" + RestrictionFieldName + " <= &EndDate";
			
		EndIf;
		
	EndIf;
	
	Return ResultingRestrictionByDate;
	
EndFunction

// Generates the query result for data clearing export.
// 
// Параметры:
//   Properties - Structure - a value type details, see ManagerParametersStructure.
//   TypeName - String - a type name.
//   SelectionForDataClearing - Boolean - selection to clear data.
//   DeleteObjectsDirectly - Boolean - a flag showing whether direct deletion is required.
//   SelectAllFields - Boolean - indicates whether it is necessary to select all fields.
//
// Returns:
//   QueryResult or Undefined - a result of the query to export data cleaning.
//
Function GetQueryResultForExportDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export 
	
	PermissionRow = ?(ExportAllowedObjectsOnly, " ALLOWED ", "");
			
	FieldSelectionString = ?(SelectAllFields, " * ", "	ObjectForExport.Ref AS Ref ");

	If TypeName = "Catalog" Or TypeName = "ChartOfCharacteristicTypes" Or TypeName = "ChartOfAccounts" Or TypeName = "ChartOfCalculationTypes" 
		Or TypeName = "AccountingRegister" Or TypeName = "ExchangePlan" Or TypeName = "Task"
		Or TypeName = "BusinessProcess" Then

		Query = New Query();
		
		If TypeName = "Catalog" Then
			ObjectsMetadata = Metadata.Catalogs[Properties.Name];
		ElsIf TypeName = "ChartOfCharacteristicTypes" Then
		    ObjectsMetadata = Metadata.ChartsOfCharacteristicTypes[Properties.Name];			
		ElsIf TypeName = "ChartOfAccounts" Then
		    ObjectsMetadata = Metadata.ChartsOfAccounts[Properties.Name];
		ElsIf TypeName = "ChartOfCalculationTypes" Then
		    ObjectsMetadata = Metadata.ChartsOfCalculationTypes[Properties.Name];
		ElsIf TypeName = "AccountingRegister" Then
		    ObjectsMetadata = Metadata.AccountingRegisters[Properties.Name];
		ElsIf TypeName = "ExchangePlan" Then
		    ObjectsMetadata = Metadata.ExchangePlans[Properties.Name];
		ElsIf TypeName = "Task" Then
		    ObjectsMetadata = Metadata.Tasks[Properties.Name];
		ElsIf TypeName = "BusinessProcess" Then
		    ObjectsMetadata = Metadata.BusinessProcesses[Properties.Name];			
		EndIf;

		If TypeName = "AccountingRegister" Then
			
			FieldSelectionString = "*";
			TableNameForSelection = Properties.Name + ".RecordsWithExtDimensions";
			
		Else
			
			TableNameForSelection = Properties.Name;	
			
			If ExportAllowedObjectsOnly And Not SelectAllFields Then
				
				FirstAttributeName = GetFirstMetadataAttributeName(ObjectsMetadata);
				If Not IsBlankString(FirstAttributeName) Then
					FieldSelectionString = FieldSelectionString + ", ObjectForExport." + FirstAttributeName;
				EndIf;
				
			EndIf;
			
		EndIf;

		Query.Text = "SELECT " + PermissionRow + "
		         |	" + FieldSelectionString + "
		         |FROM
		         |	" + TypeName + "." + TableNameForSelection + " AS ObjectForExport
				 |
				 |";

	ElsIf TypeName = "Document" Then
		
		If ExportAllowedObjectsOnly Then
			
			FirstAttributeName = GetFirstMetadataAttributeName(Metadata.Documents[Properties.Name]);
			If Not IsBlankString(FirstAttributeName) Then
				FieldSelectionString = FieldSelectionString + ", ObjectForExport." + FirstAttributeName;
			EndIf;
			
		EndIf;
		
		ResultingRestrictionByDate = GetRestrictionByDateStringForQuery(Properties, TypeName, "ObjectForExport", SelectionForDataClearing);
		
		Query = New Query();
		
		Query.SetParameter("StartDate", StartDate);
		Query.SetParameter("EndDate", EndDate);
		
		Query.Text = "SELECT " + PermissionRow + "
		         |	" + FieldSelectionString + "
		         |FROM
		         |	" + TypeName + "." + Properties.Name + " AS ObjectForExport
				 |
				 |" + ResultingRestrictionByDate;
	ElsIf TypeName = "InformationRegister" Then
		
		Nonperiodical = NOT Properties.Periodic;
		SubordinatedToRecorder = Properties.SubordinateToRecorder;		
		
		ResultingRestrictionByDate = GetRestrictionByDateStringForQuery(Properties, TypeName, "ObjectForExport", SelectionForDataClearing);
						
		Query = New Query();
		
		Query.SetParameter("StartDate", StartDate);
		Query.SetParameter("EndDate", EndDate);
		
		SelectionFieldSupplementionStringSubordinateToRecorder = ?(NOT SubordinatedToRecorder, ", NULL AS Active,
		|	NULL AS Recorder,
		|	NULL AS LineNumber", "");
		
		SelectionFieldSupplementionStringPeriodicity = ?(Nonperiodical, ", NULL AS Period", "");
		
		Query.Text = "SELECT " + PermissionRow + "
		         |	*
				 |
				 | " + SelectionFieldSupplementionStringSubordinateToRecorder + "
				 | " + SelectionFieldSupplementionStringPeriodicity + "
				 |
		         |FROM
		         |	" + TypeName + "." + Properties.Name + " AS ObjectForExport
				 |
				 |" + ResultingRestrictionByDate;
		
	Else
		
		Return Undefined;
					
	EndIf;	
	
	Return Query.Execute();
	
EndFunction

// Generates selection for data clearing export.
//
// Parameters:
//   Properties - Manager - metadata object properties.
//   TypeName - String - a type name.
//   SelectionForDataClearing - Boolean - selection to clear data.
//   DeleteObjectsDirectly - Boolean - indicates whether it is required to delete directly.
//   SelectAllFields - Boolean - indicates whether it is necessary to select all fields.
//
// Returns:
//   QueryResultSelection - a selection to export data clearing.
//
Function GetSelectionForDataClearingExport(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export
	
	QueryResult = GetQueryResultForExportDataClearing(Properties, TypeName, 
			SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
			
	If QueryResult = Undefined Then
		Return Undefined;
	EndIf;
			
	Selection = QueryResult.Select();
	
	Return Selection;
	
EndFunction

#EndRegion

#Region ExportProceduresAndFunctions

// Fills the passed values table with metadata object types which are allowed to deletion by access rights.
//
// Parameters:
//   DataTable - ValueTable - a table to fill in.
//
Procedure FillAllowedToDeletionTypesList(DataTable) Export

	DataTable.Clear();
	
	For Each MDObject In Metadata.Catalogs Do
		
		If Not AccessRight("Delete", MDObject) Then
			Continue;
		EndIf;
		
		TableRow = DataTable.Add();
		TableRow.Metadata = "CatalogRef." + MDObject.Name;
		
	EndDo;

	For Each MDObject In Metadata.ChartsOfCharacteristicTypes Do
		
		If Not AccessRight("Delete", MDObject) Then
			Continue;
		EndIf;
		
		TableRow = DataTable.Add();
		TableRow.Metadata = "ChartOfCharacteristicTypesRef." + MDObject.Name;
	EndDo;

	For Each MDObject In Metadata.Documents Do
		
		If Not AccessRight("Delete", MDObject) Then
			Continue;
		EndIf;
		
		TableRow = DataTable.Add();
		TableRow.Metadata = "DocumentRef." + MDObject.Name;
	EndDo;

	For Each MDObject In Metadata.InformationRegisters Do
		
		If Not AccessRight("Delete", MDObject) Then
			Continue;
		EndIf;
		
		Subordinate		=	(MDObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		If Subordinate Then Continue EndIf;
		
		TableRow = DataTable.Add();
		TableRow.Metadata = "InformationRegisterRecord." + MDObject.Name;
		
	EndDo;
	
EndProcedure

// Sets marks in child tree rows according to the mark in the current row.
//
// Parameters:
//  CurRow      - ValueTreeRow - a row, child rows of which are to be processed.
//  Attribute       - String - a name of an attribute, which contains the mark.
// 
Procedure SetChildMarks(curRow, Attribute) Export

	ChildItems = curRow.Rows;

	If ChildItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Row In ChildItems Do
		
		If Row.BuilderSettings = Undefined 
			And Attribute = "UseFilter" Then
			
			Row[Attribute] = 0;
			
		Else
			
			Row[Attribute] = curRow[Attribute];
			
		EndIf;
		
		SetChildMarks(Row, Attribute);
		
	EndDo;
		
EndProcedure

// Sets marks in parent tree rows according to the mark in the current row.
//
// Parameters:
//  CurRow      - ValueTreeRow - a row, parent rows of which are to be processed.
//  Attribute       - String - a name of an attribute, which contains the mark.
// 
Procedure SetParentMarks(curRow, Attribute) Export

	Parent = curRow.Parent;
	If Parent = Undefined Then
		Return;
	EndIf;

	CurState       = Parent[Attribute];

	EnabledItemsFound  = False;
	DisabledItemsFound = False;

	If Attribute = "UseFilter" Then
		
		For Each Row In Parent.Rows Do
			
			If Row[Attribute] = 0 And Row.Filter <> Undefined Then

				DisabledItemsFound = True;
				
			ElsIf Row[Attribute] = 1 Then
				EnabledItemsFound  = True;
			EndIf; 
			
			If EnabledItemsFound AND DisabledItemsFound Then
				Break;
			EndIf; 
			
		EndDo;
		
	Else

		For Each Row In Parent.Rows Do
			If Row[Attribute] = 0 Then
				DisabledItemsFound = True;
			ElsIf Row[Attribute] = 1 Or Row[Attribute] = 2 Then
				EnabledItemsFound  = True;
			EndIf; 
			If EnabledItemsFound And DisabledItemsFound Then
				Break;
			EndIf; 
		EndDo;
		
	EndIf;
	If EnabledItemsFound And DisabledItemsFound Then
		Enable = 2;
	ElsIf EnabledItemsFound And (Not DisabledItemsFound) Then
		Enable = 1;
	ElsIf (Not EnabledItemsFound) And DisabledItemsFound Then
		Enable = 0;
	ElsIf (Not EnabledItemsFound) And (Not DisabledItemsFound) Then
		Enable = 2;
	EndIf;

	If Enable = CurState Then
		Return;
	Else
		Parent[Attribute] = Enable;
		SetParentMarks(Parent, Attribute);
	EndIf; 
	
EndProcedure

// Generates the full path to a file from the directory path and the file name.
//
// Parameters:
//  DirectoryName - String - the path to the directory that contains the file.
//  FileName - String - the file name.
//
// Returns:
//   String - the full path to the file.
//
Function GetExchangeFileName(DirectoryName, FileName) Export

	If Not IsBlankString(FileName) Then
		
		Return DirectoryName + ?(Right(DirectoryName, 1) = "\", "", "\") + FileName;	
		
	Else
		
		Return DirectoryName;
		
	EndIf;

EndFunction

// Passed the data string to import in the destination base.
//
// Parameters:
//  InformationToWriteToFile - String - a data string (XML text).
//  ErrorStringInDestinationInfobase - String - contains error description upon import to the destination infobase.
// 
Procedure SendWriteInformationToDestination(InformationToWriteToFile, ErrorStringInDestinationInfobase = "") Export
	
	mDataImportDataProcessor.ExchangeFile.SetString(InformationToWriteToFile);
	
	mDataImportDataProcessor.ReadData(ErrorStringInDestinationInfobase);
	
	If Not IsBlankString(ErrorStringInDestinationInfobase) Then
		
		MessageString = SubstituteParametersToString(NStr("ru = 'Загрузка в приемнике: %1'; en = 'Import in destination: %1'"), ErrorStringInDestinationInfobase);
		WriteToExecutionLog(MessageString, Undefined, True, , , True);
		
	EndIf;
	
EndProcedure

// Writes a name, a type, and a value of the parameter to an exchange message file. This data is sent to the destination infobase.
//
// Parameters:
//   Name                          - String - a parameter name.
//   InitialParameterValue    - Arbitrary - a parameter value.
//   ConversionRule           - String - a conversion rule name for reference types.
// 
Procedure SendOneParameterToDestination(Name, InitialParameterValue, ConversionRule = "") Export
	
	If IsBlankString(ConversionRule) Then
		
		ParameterNode = CreateNode("ParameterValue");
		
		SetAttribute(ParameterNode, "Name", Name);
		SetAttribute(ParameterNode, "Type", deValueTypeAsString(InitialParameterValue));
		
		IsNULL = False;
		Empty = deEmpty(InitialParameterValue, IsNULL);
					
		If Empty Then
			
			// Writing the empty value.
			deWriteElement(ParameterNode, "Empty");
								
			ParameterNode.WriteEndElement();
			
			WriteToFile(ParameterNode);
			
			Return;
								
		EndIf;
	
		deWriteElement(ParameterNode, "Value", InitialParameterValue);
	
		ParameterNode.WriteEndElement();
		
		WriteToFile(ParameterNode);

	Else
		
		ParameterNode = CreateNode("ParameterValue");
		
		SetAttribute(ParameterNode, "Name", Name);
		
		IsNULL = False;
		Empty = deEmpty(InitialParameterValue, IsNULL);
					
		If Empty Then
			
			PropertiesOCR = FindRule(InitialParameterValue, ConversionRule);
			DestinationType  = PropertiesOCR.Destination;
			SetAttribute(ParameterNode, "Type", DestinationType);
			
			// Writing the empty value.
			deWriteElement(ParameterNode, "Empty");
								
			ParameterNode.WriteEndElement();
			
			WriteToFile(ParameterNode);
			
			Return;
								
		EndIf;
		
		ExportRefObjectData(InitialParameterValue, Undefined, ConversionRule, Undefined, Undefined, ParameterNode, True);
		
		ParameterNode.WriteEndElement();
		
		WriteToFile(ParameterNode);				
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region SetAttributesValuesAndDataProcessorModalVariables

// Returns the current value of the data processor version.
//
// Returns:
//  Number - current value of the data processor version.
//
Function ObjectVersion() Export
	
	Return 218;
	
EndFunction

#EndRegion

#Область ИнициализацияТаблицПравилОбмена

// Initializes table columns of object property conversion rules.
//
// Parameters:
//  Tab            - ValueTable - a table of property conversion rules to initialize.
// 
Procedure InitPropertyConversionRuleTable(Tab) Export

	Columns = Tab.Columns;

	AddMissingColumns(Columns, "Name");
	AddMissingColumns(Columns, "Description");
	AddMissingColumns(Columns, "Order");

	AddMissingColumns(Columns, "IsGroup", 			deTypeDescription("Boolean"));
    AddMissingColumns(Columns, "GroupRules");

	AddMissingColumns(Columns, "SourceKind");
	AddMissingColumns(Columns, "DestinationKind");
	
	AddMissingColumns(Columns, "SimplifiedPropertyExport", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "XMLNodeRequiredOnExport", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "XMLNodeRequiredOnExportGroup", deTypeDescription("Boolean"));

	AddMissingColumns(Columns, "SourceType", deTypeDescription("String"));
	AddMissingColumns(Columns, "DestinationType", deTypeDescription("String"));
	
	AddMissingColumns(Columns, "Source");
	AddMissingColumns(Columns, "Destination");

	AddMissingColumns(Columns, "ConversionRule");

	AddMissingColumns(Columns, "GetFromIncomingData", deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "DoNotReplace", deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "BeforeExport");
	AddMissingColumns(Columns, "OnExport");
	AddMissingColumns(Columns, "AfterExport");

	AddMissingColumns(Columns, "BeforeProcessExport");
	AddMissingColumns(Columns, "AfterProcessExport");

	AddMissingColumns(Columns, "HasBeforeExportHandler",			deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasOnExportHandler",				deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasAfterExportHandler",				deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "HasBeforeProcessExportHandler",	deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasAfterProcessExportHandler",	deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "CastToLength",	deTypeDescription("Number"));
	AddMissingColumns(Columns, "ParameterForTransferName");
	AddMissingColumns(Columns, "SearchByEqualDate",					deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "ExportGroupToFile",					deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "SearchFieldsString");
	
EndProcedure

#EndRegion

#Область ИнициализацияРеквизитовИМодульныхПеременных

// Initializes the external data processor with event handlers debug module.
//
// Parameters:
//  ExecutionPossible - Boolean - indicates whether an external data processor is initialized successfully.
//  OwnerObject - DataProcessorObject - an object that will own the initialized external data 
//                                     processor.
//  
Procedure InitEventHandlerExternalDataProcessor(ExecutionPossible, OwnerObject) Export
	
	If Not ExecutionPossible Then
		Return;
	EndIf;

	If HandlersDebugModeFlag And IsBlankString(EventHandlerExternalDataProcessorFileName) Then
		
		WriteToExecutionLog(77); 
		ExecutionPossible = False;

	ElsIf HandlersDebugModeFlag Then
		
		Try
			
			If IsExternalDataProcessor() Then

				EventHandlersExternalDataProcessor = ExternalDataProcessors.Create(EventHandlerExternalDataProcessorFileName, False);

			Else
				
				EventHandlersExternalDataProcessor = DataProcessors[EventHandlerExternalDataProcessorFileName].Create();
				
			EndIf;
			
			EventHandlersExternalDataProcessor.Designer(OwnerObject);

		Except
			
			EventHandlerExternalDataProcessorDestructor();
			
			MessageToUser(BriefErrorDescription(ErrorInfo()));
			WriteToExecutionProtocol(78);
			
			ExecutionPossible               = False;
			HandlersDebugModeFlag = False;
			
		EndTry;
		
	EndIf;

	If ExecutionPossible Then
		
		CommonProceduresFunctions = ThisObject;
		
	EndIf; 
	
EndProcedure

// External data processor destructor.
//
// Parameters:
//  DebugModeEnabled - Boolean - indicates whether the debug mode is on.
//  
Procedure EventHandlerExternalDataProcessorDestructor(DebugModeEnabled = False) Export
	
	If Not DebugModeEnabled Then
		
		If EventHandlersExternalDataProcessor <> Undefined Then
			
			Try
				
				EventHandlersExternalDataProcessor.Destructor();
				
			Except
				MessageToUser(BriefErrorDescription(ErrorInfo()));
			EndTry; 
			
		EndIf; 
		
		EventHandlersExternalDataProcessor = Undefined;
		CommonProceduresFunctions               = Undefined;
		
	EndIf;
	
EndProcedure

// Deletes temporary files with the specified name.
//
// Parameters:
//  TempFileName - String - a full name of the file to be deleted. It clears after the procedure is executed.
//  
Procedure DeleteTempFiles(TempFileName) Export
	
	If Not IsBlankString(TempFileName) Then
		
		Try
			
			DeleteFiles(TempFileName);
			
			TempFileName = "";
			
		Except
			WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ExchangeFileOperationsProceduresAndFunctions

// Opens an exchange file, writes a file header according to the exchange format.
//
// Parameters:
//  No.
//
Function OpenExportFile(ErrorMessageString = "")

	// Archive files are recognized by the ZIP extension.
	
	If ArchiveFile Then
		ExchangeFileName = StrReplace(ExchangeFileName, ".zip", ".xml");
	EndIf;
    	
	ExchangeFile = New TextWriter;
	Try

		If DirectReadFromDestinationIB Then
			ExchangeFile.Open(GetTempFileName(".xml"), TextEncoding.UTF8);
		Else
			ExchangeFile.Open(ExchangeFileName, TextEncoding.UTF8);
		EndIf;
				
	Except
		
		ErrorMessageString = WriteToExecutionLog(8);
		Return "";
		
	EndTry;

	XMLInfoString = "<?xml version=""1.0"" encoding=""UTF-8""?>";
	
	ExchangeFile.WriteLine(XMLInfoString);

	TempXMLWriter = New XMLWriter();
	
	TempXMLWriter.SetString();
	
	TempXMLWriter.WriteStartElement("ExchangeFile");
							
	SetAttribute(TempXMLWriter, "FormatVersion", "2.0");
	SetAttribute(TempXMLWriter, "ExportDate",				CurrentSessionDate());
	SetAttribute(TempXMLWriter, "ExportPeriodStart",		StartDate);
	SetAttribute(TempXMLWriter, "ExportPeriodEnd",	EndDate);
	SetAttribute(TempXMLWriter, "SourceConfigurationName",	Conversion().Source);
	SetAttribute(TempXMLWriter, "DestinationConfigurationName",	Conversion().Destination);
	SetAttribute(TempXMLWriter, "ConversionRuleIDs",		Conversion().ID);
	SetAttribute(TempXMLWriter, "Comment",				Comment);
	
	TempXMLWriter.WriteEndElement();
	
	Page = TempXMLWriter.Close(); 
	
	Page = StrReplace(Page, "/>", ">");
	
	ExchangeFile.WriteLine(Page);
	
	Return XMLInfoString + Chars.LF + Page;
			
EndFunction

// Closes the exchange file.
//
// Parameters:
//  No.
//
Procedure CloseFile()

    ExchangeFile.WriteLine("</ExchangeFile>");
	ExchangeFile.Close();
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfTemporaryFilesOperations

Function WriteTextToTemporaryFile(TempFileList)
	
	RecordFileName = GetTempFileName();
	
	RecordsTemporaryFile = New TextWriter;
	
	If SafeMode() <> False Then
		SetSafeModeDisabled(True);
	EndIf;
	
	Try
		RecordsTemporaryFile.Open(RecordFileName, TextEncoding.UTF8);
	Except
		WriteErrorInfoConversionHandlers(1000,
			ErrorDescription(),
			NStr("ru = 'Ошибка при создании временного файла для выгрузки данных'; en = 'Error creating temporary file for data export'"));
		Raise;
	EndTry;
	
	TempFileList.Add(RecordFileName);
		
	Return RecordsTemporaryFile;
	
EndFunction

Function ReadTextFromTemporaryFile(TempFileName)
	
	TempFile = New TextReader;
	
	If SafeMode() <> False Then
		SetSafeModeDisabled(True);
	EndIf;
	
	Try
		TempFile.Open(TempFileName, TextEncoding.UTF8);
	Except
		WriteErrorInfoConversionHandlers(1000,
			ErrorDescription(),
			NStr("ru = 'Ошибка при открытии временного файла для переноса данных в файл обмена'; en = 'An error occurred when opening the temporary file to transfer data to the exchange file'"));
		Raise;
	EndTry;
	
	Return TempFile;
EndFunction

Procedure TransferDataFromTemporaryFiles(TempFileList)
	
	For Each TempFileName In TempFileList Do
		TempFile = ReadTextFromTemporaryFile(TempFileName);
		
		TempFileLine = TempFile.ReadLine();
		While TempFileLine <> Undefined Do
			WriteToFile(TempFileLine);	
			TempFileLine = TempFile.ReadLine();
		EndDo;
		
		TempFile.Close();
	EndDo;
	
	If SafeMode() <> False Then
		SetSafeModeDisabled(True);
	EndIf;
	
	For Each TempFileName In TempFileList Do
		DeleteFiles(TempFileName);
	EndDo;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfExchangeLogOperations

// Initializes the file to write data import/export events.
//
// Parameters:
//  No.
// 
Procedure InitializeKeepExchangeLog() Export
	
	If IsBlankString(ExchangeLogFileName) Then
		
		mDataLogFile = Undefined;
		CommentObjectProcessingFlag = DisplayInfoMessagesIntoMessageWindow;
		Return;

	Else

		CommentObjectProcessingFlag = WriteInfoMessagesToLog
			Or DisplayInfoMessagesIntoMessageWindow;

	EndIf;

	mDataLogFile = New TextWriter(ExchangeLogFileName, ExchangeLogFileEncoding(), ,
		AppendDataToExchangeLog);

EndProcedure

Procedure InitializeKeepExchangeProtocolForHandlersExport()

	ExchangeLogTempFileName = GetNewUniqueTempFileName(ExchangeLogTempFileName);

	mDataLogFile = New TextWriter(ExchangeLogTempFileName, ExchangeLogFileEncoding());

	CommentObjectProcessingFlag = False;

EndProcedure

Function ExchangeLogFileEncoding()

	EncodingPresentation = TrimAll(ExchangeLogFileEncoding);

	Result = TextEncoding.ANSI;
	If Not IsBlankString(ExchangeLogFileEncoding) Then
		If StrStartsWith(EncodingPresentation, "TextEncoding.") Then
			EncodingPresentation = StrReplace(EncodingPresentation, "TextEncoding.", "");
			Try
				Result = TextEncoding[EncodingPresentation];
			Except
				ErrorText = SubstituteParametersToString(NStr("ru = 'Неизвестная кодировка файла протокола обмена: %1.
				|Используется ANSI.'; 
				|en = 'Unknown encoding of the exchange log file: %1.
				|ANSI is used.'"), EncodingPresentation);
				WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", DefaultLanguageCode()),
					EventLogLevel.Warning, , , ErrorText);
			EndTry;
		Else
			Result = EncodingPresentation;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Closes a data exchange log file. File is saved to the disk.
//
Procedure FinishKeepExchangeLog() Export 
	
	If mDataLogFile <> Undefined Then
		
		mDataLogFile.Close();
				
	EndIf;	
	
	mDataLogFile = Undefined;
	
EndProcedure

// Writes to a log or displays messages of the specified structure.
//
// Parameters:
//  Code - Number. Message code.
//  RecordStructure - Structure. Log record structure.
//  SetErrorFlag - if True, then it is an error message. Sets ErrorFlag.
//  Level - Number. A message hierarchy level in the log.
//  Align - Number. A resulting length to written string, see odSupplementString() function.
//  UnconditionalWriteToExchangeLog - Boolean. If True, DisplayInfoMessagesIntoMessageWindow flag is ignored.
// 
Function WriteToExecutionLog(Code="", RecordStructure=Undefined, SetErrorFlag=True, 
	Level=0, Align=22, UnconditionalWriteToExchangeLog = False) Export

	Indent = "";
    For Cnt = 0 To Level-1 Do
		Indent = Indent + Chars.Tab;
	EndDo;

	If TypeOf(Code) = deNumberType Then
		
		If deMessages = Undefined Then
			InitMessages();
		EndIf;
		
		Str = deMessages[Code];
		
	Else
		
		Str = String(Code);
		
	EndIf;

	Str = Indent + Str;
	
	If RecordStructure <> Undefined Then
		
		For each Field In RecordStructure Do
			
			Value = Field.Value;
			If Value = Undefined Then
				Continue;
			EndIf; 
			Key = Field.Key;
			Str  = Str + Chars.LF + Indent + Chars.Tab + odSupplementString(Key, Align) + " =  " + String(Value);
			
		EndDo;
		
	EndIf;

	ResultingStringToWrite = Chars.LF + Str;
	If SetErrorFlag Then
		
		SetErrorFlag(True);
		MessageToUser(ResultingStringToWrite);
		
	Else

		If DoNotShowInfoMessagesToUser = False And (UnconditionalWriteToExchangeLog
			Or DisplayInfoMessagesIntoMessageWindow) Then

			MessageToUser(ResultingStringToWrite);
			
		EndIf;
		
	EndIf;

	If mDataLogFile <> Undefined Then
		
		If SetErrorFlag Then
			
			mDataLogFile.WriteLine(Chars.LF + "Error.");
			
		EndIf;
		
		If SetErrorFlag Or UnconditionalWriteToExchangeLog Or WriteInfoMessagesToLog Then

			mDataLogFile.WriteLine(ResultingStringToWrite);
		
		EndIf;		
		
	EndIf;
	
	Return Str;
		
EndFunction

// Writes error details to the exchange log for data clearing handler.
//
Procedure WriteDataClearingHandlerErrorInfo(MessageCode, ErrorString, DataClearingRuleName, Object = "", HandlerName = "")

	LR                        = GetLogRecordStructure(MessageCode, ErrorString);
	LR.DCR                    = DataClearingRuleName;

	If Object <> "" Then
		TypeDescription = New TypeDescription("String");
		StringObject  = TypeDescription.AdjustValue(Object);
		If Not IsBlankString(StringObject) Then
			LR.Object = StringObject + "  (" + TypeOf(Object) + ")";
		Else
			LR.Object = "" + TypeOf(Object) + "";
		EndIf;
	EndIf;

	If HandlerName <> "" Then
		LR.Handler             = HandlerName;
	EndIf;

	ErrorMessageString = WriteToExecutionLog(MessageCode, LR);

	If Not DebugModeFlag Then
		Raise ErrorMessageString;
	EndIf;

EndProcedure

// Registers the error of object conversion rule handler (export) in the execution protocol.
//
Procedure WriteInfoOnOCRHandlerExportError(MessageCode, ErrorString, OCR, Source, HandlerName)
	
	LR                        = GetLogRecordStructure(MessageCode, ErrorString);
	LR.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
	
	TypeDescription = New TypeDescription("String");
	StringSource  = TypeDescription.AdjustValue(Source);
	If Not IsBlankString(StringSource) Then
		LR.Object = StringSource + "  (" + TypeOf(Source) + ")";
	Else
		LR.Object = "(" + TypeOf(Source) + ")";
	EndIf;
	
	LR.Handler = HandlerName;
	
	ErrorMessageString = WriteToExecutionLog(MessageCode, LR);
	
	If Not DebugModeFlag Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure

Procedure WriteErrorInfoDERHandlers(MessageCode, ErrorString, RuleName, HandlerName, Object = Undefined)
	
	LR                        = GetLogRecordStructure(MessageCode, ErrorString);
	LR.DER                    = RuleName;
	
	If Object <> Undefined Then
		TypeDescription = New TypeDescription("String");
		StringObject  = TypeDescription.AdjustValue(Object);
		If Not IsBlankString(StringObject) Then
			LR.Object = StringObject + "  (" + TypeOf(Object) + ")";
		Else
			LR.Object = "" + TypeOf(Object) + "";
		EndIf;
	EndIf;
	
	LR.Handler             = HandlerName;
	
	ErrorMessageString = WriteToExecutionLog(MessageCode, LR);
	
	If Not DebugModeFlag Then
		Raise ErrorMessageString;
	EndIf;
	
EndProcedure

Function WriteErrorInfoConversionHandlers(MessageCode, ErrorString, HandlerName)
	
	LR                        = GetLogRecordStructure(MessageCode, ErrorString);
	LR.Handler             = HandlerName;
	ErrorMessageString = WriteToExecutionLog(MessageCode, LR);
	Return ErrorMessageString;
	
EndFunction

#EndRegion

#Region CoolectionTypesDetails

// Returns:
//   ValueTable - Data conversion rules collection:
//     * Name - String - 
//     * Description - String - 
//     * Order - Number - 
//     * SynchronizeByID - Boolean -
//     * НеСоздаватьЕслиНеНайден - Boolean -
//     * DontExportPropertyObjectsByRefs - Boolean -
//     * SearchBySearchFieldsIfNotFoundByID - Boolean -
//     * OnMoveObjectByRefSetGIUDOnly - Boolean -
//     * UseQuickSearchOnImport - Boolean -
//     * GenerateNewNumberOrCodeIfNotSet - Boolean -
//     * ObjectsSmallCount - Boolean -
//     * RefExportRequestsCount - Number -
//     * IBItemsCount - Number -
//     * ExportMethod - Arbitrary -
//     * Source - Arbitrary -
//     * Destination - Arbitrary -
//     * SourceType - String -
//     * BeforeExport - Arbitrary -
//     * OnExport - Arbitrary -
//     * AfterExport - Arbitrary -
//     * AfterExportToFile - Arbitrary -
//     * HasBeforeExportHandler - Boolean -
//     * HasOnExportHandler - Boolean -
//     * HasAfterExportHandler - Boolean -
//     * HasAfterExportToFileHandler - Boolean -
//     * BeforeImport - Arbitrary -
//     * OnImport - Arbitrary -
//     * AfterImport - Arbitrary -
//     * SearchFieldsSequence - Arbitrary -
//     * SearchInTabularSections - see SearchInTabularSectionsCollection
//     * HasBeforeImportHandler - Boolean -
//     * HasOnImportHandler - Boolean -
//     * HasAfterImportHandler - Boolean -
//     * HasSearchFieldsSequenceHandler - Boolean -
//     * SearchProperties - see PropertyConversionRulesCollection
//     * Properties - см. PropertyConversionRulesCollection
//     * Exported - ValueTable -
//     * ExportSourcePresentation - Boolean -
//     * DoNotReplace - Boolean -
//     * RememberExported - Boolean -
//     * AllObjectsExported - Boolean -
// 
Function ConversionRulesCollection()

	Return ConversionRulesTable;

EndFunction

// Returns:
//   ValueTree - Data export rules collection:
//     * Enable - Number -
//     * IsGroup - Boolean -
//     * Name - String -
//     * Description - String -
//     * Order - Number -
//     * DataFilterMethod - Arbitrary -
//     * SelectionObject - Arbitrary -
//     * ConversionRule - Arbitrary -
//     * BeforeProcess - String -
//     * AfterProcess - String -
//     * BeforeExport - String -
//     * AfterExport - String -
//     * UseFilter - Boolean -
//     * BuilderSettings - Arbitrary -
//     * ObjectNameForQuery - String -
//     * ObjectNameForRegisterQuery - String -
//     * SelectExportDataInSingleQuery - Boolean -
//     * ExchangeNodeRef - ExchangePlanRef -
//
Function ExportRulesCollection()

	Return ExportRulesTable;

EndFunction

// Returns:
//   ValueTable - Search in tabular sections rules collection:
//     * ItemName - Arbitrary -
//     * VTSearchFields - Array of Arbitrary -
// 
Function SearchInTabularSectionsCollection()

	SearchInTabularSections = New ValueTable;
	SearchInTabularSections.Columns.Add("ItemName");
	SearchInTabularSections.Columns.Add("VTSearchFields");

	Return SearchInTabularSections;

EndFunction

// Returns:
//   ValueTable - Data property conversion rules collection:
//     * Name - String -
//     * Description - String - 
//     * Order - Number -
//     * IsGroup - Boolean -
//     * IsSearchField - Boolean -
//     * GroupRules - see PropertyConversionRulesCollection
//     * GroupDisabledRules - Arbitrary -
//     * SourceKind - Arbitrary -
//     * DestinationKind - Arbitrary -
//     * SimplifiedPropertyExport - Boolean -
//     * XMLNodeRequiredOnExport - Boolean -
//     * XMLNodeRequiredOnExportGroup - Boolean -
//     * SourceType - String -
//     * DestinationType - String -
//     * Source - Arbitrary -
//     * Destination - Arbitrary -
//     * ConversionRule - Arbitrary -
//     * GetFromIncomingData - Boolean -
//     * DoNotReplace - Boolean -
//     * IsRequiredProperty - Boolean -
//     * BeforeExport - Arbitrary -
//     * BeforeExportHandlerName - Arbitrary -
//     * OnExport - Arbitrary -
//     * OnExportHandlerName - Arbitrary -
//     * AfterExport - Arbitrary -
//     * AfterExportHandlerName - Arbitrary -
//     * BeforeProcessExport - Arbitrary -
//     * BeforeProcessExportHandlerName - Arbitrary -
//     * AfterProcessExport - Arbitrary -
//     * AfterProcessExportHandlerName - Arbitrary -
//     * HasBeforeExportHandler - Boolean -
//     * HasOnExportHandler - Boolean -
//     * HasAfterExportHandler - Boolean -
//     * HasBeforeProcessExportHandler - Boolean -
//     * HasAfterProcessExportHandler - Boolean -
//     * CastToLength - Number -
//     * ParameterForTransferName - String -
//     * SearchByEqualDate - Boolean -
//     * ExportGroupToFile - Boolean -
//     * SearchFieldsString - Arbitrary -
// 
Function PropertyConversionRulesCollection()

	Return mPropertyConversionRulesTable;

EndFunction

// Returns:
//   ValueTable - an export stack:
//     * Ref - AnyRef - a reference to the exported object.
//
Function DataExportCallStackCollection()

	Return mDataExportCallStack;

EndFunction

// Returns:
//   Structure - a rules structure:
//     * ExportRulesTable - see ExportRulesCollection
//     * ConversionRulesTable - see ConversionRulesCollection
//     * Algorithms - Structure -
//     * Queries - Structure -
//     * Conversion - Arbitrary -
//     * mXMLRules - Arbitrary -
//     * ParametersSettingsTable - ValueTable -
//     * Parameters - Structure -
//     * DestinationPlatformVersion - String -
//
Function RulesStructureDetails()

	RulesStructure = New Structure;

	RulesStructure.Insert("ExportRulesTable");
	RulesStructure.Insert("ConversionRulesTable");
	RulesStructure.Insert("Algorithms");
	RulesStructure.Insert("Queries");
	RulesStructure.Insert("Conversion");
	RulesStructure.Insert("mXMLRules");
	RulesStructure.Insert("ParametersSettingsTable");
	RulesStructure.Insert("Parameters");

	RulesStructure.Insert("DestinationPlatformVersion");

	Return RulesStructure;

EndFunction

#EndRegion

#Region ExchangeRulesImportProcedures

// Imports the property group conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  PropertiesTable - see PropertyConversionRulesCollection
//
Procedure ImportPGCR(ExchangeRules, PropertiesTable)

	If deAttribute(ExchangeRules, deBooleanType, "Disable") Then
		deSkip(ExchangeRules);
		Return;
	EndIf;

	
	NewRow               = PropertiesTable.Add();
	NewRow.IsGroup     = True;
	NewRow.GroupRules = PropertyConversionRulesCollection().Copy();
	
	// Default values

	NewRow.DoNotReplace               = False;
	NewRow.GetFromIncomingData = False;
	NewRow.SimplifiedPropertyExport = False;
	
	SearchFieldsString = "";

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Source" Then
			NewRow.Source		= deAttribute(ExchangeRules, deStringType, "Name");
			NewRow.SourceKind	= deAttribute(ExchangeRules, deStringType, "Kind");
			NewRow.SourceType	= deAttribute(ExchangeRules, deStringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Destination" Then
			NewRow.Destination		= deAttribute(ExchangeRules, deStringType, "Name");
			NewRow.DestinationKind	= deAttribute(ExchangeRules, deStringType, "Kind");
			NewRow.DestinationType	= deAttribute(ExchangeRules, deStringType, "Type");
			deSkip(ExchangeRules);

		ElsIf NodeName = "Property" Then
			ImportPCR(ExchangeRules, NewRow.GroupRules, , SearchFieldsString);

		ElsIf NodeName = "BeforeProcessExport" Then
			NewRow.BeforeProcessExport	= GetHandlerValueFromText(ExchangeRules);
			NewRow.HasBeforeProcessExportHandler = Not IsBlankString(NewRow.BeforeProcessExport);
			
		ElsIf NodeName = "AfterProcessExport" Then
			NewRow.AfterProcessExport	= GetHandlerValueFromText(ExchangeRules);
			NewRow.HasAfterProcessExportHandler = Not IsBlankString(NewRow.AfterProcessExport);
			
		ElsIf NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "DoNotReplace" Then
			NewRow.DoNotReplace = deElementValue(ExchangeRules, deBooleanType);

		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "BeforeExport" Then
			NewRow.BeforeExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			NewRow.OnExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			NewRow.AfterExport = GetHandlerValueFromText(ExchangeRules);
	        NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "ExportGroupToFile" Then
			NewRow.ExportGroupToFile = deElementValue(ExchangeRules, deBooleanType);
			
		ElsIf NodeName = "GetFromIncomingData" Then
			NewRow.GetFromIncomingData = deElementValue(ExchangeRules, deBooleanType);
			
		ElsIf (NodeName = "Group") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	NewRow.SearchFieldsString = SearchFieldsString;
	
	NewRow.XMLNodeRequiredOnExport = NewRow.HasOnExportHandler Or NewRow.HasAfterExportHandler;
	
	NewRow.XMLNodeRequiredOnExportGroup = NewRow.HasAfterProcessExportHandler; 

EndProcedure

Procedure AddFieldToSearchString(SearchFieldsString, FieldName)
	
	If IsBlankString(FieldName) Then
		Return;
	EndIf;
	
	If Not IsBlankString(SearchFieldsString) Then
		SearchFieldsString = SearchFieldsString + ",";
	EndIf;
	
	SearchFieldsString = SearchFieldsString + FieldName;
	
EndProcedure

// Imports the property conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  PropertiesTable - see PropertyConversionRulesCollection
//  SearchTable - see PropertyConversionRulesCollection
//
Procedure ImportPCR(ExchangeRules, PropertiesTable, SearchTable = Undefined, SearchFieldsString = "")

	If deAttribute(ExchangeRules, deBooleanType, "Disable") Then
		deSkip(ExchangeRules);
		Return;
	EndIf;
	IsSearchField = deAttribute(ExchangeRules, deBooleanType, "Search");
	
	If IsSearchField And SearchTable <> Undefined Then
		
		NewRow = SearchTable.Add();
		
	Else
		
		NewRow = PropertiesTable.Add();
		
	EndIf;  

	
	// Default values

	NewRow.DoNotReplace               = False;
	NewRow.GetFromIncomingData = False;
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Source" Then
			NewRow.Source		= deAttribute(ExchangeRules, deStringType, "Name");
			NewRow.SourceKind	= deAttribute(ExchangeRules, deStringType, "Kind");
			NewRow.SourceType	= deAttribute(ExchangeRules, deStringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Destination" Then
			NewRow.Destination		= deAttribute(ExchangeRules, deStringType, "Name");
			NewRow.DestinationKind	= deAttribute(ExchangeRules, deStringType, "Kind");
			NewRow.DestinationType	= deAttribute(ExchangeRules, deStringType, "Type");
			
			If IsSearchField Then
				AddFieldToSearchString(SearchFieldsString, NewRow.Destination);
			EndIf;
			
			deSkip(ExchangeRules);

		ElsIf NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "DoNotReplace" Then
			NewRow.DoNotReplace = deElementValue(ExchangeRules, deBooleanType);
			
		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, deStringType);

		ElsIf NodeName = "BeforeExport" Then
			NewRow.BeforeExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			NewRow.OnExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			NewRow.AfterExport = GetHandlerValueFromText(ExchangeRules);
	        NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "GetFromIncomingData" Then
			NewRow.GetFromIncomingData = deElementValue(ExchangeRules, deBooleanType);
			
		ElsIf NodeName = "CastToLength" Then
			NewRow.CastToLength = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "ParameterForTransferName" Then
			NewRow.ParameterForTransferName = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "SearchByEqualDate" Then
			NewRow.SearchByEqualDate = deElementValue(ExchangeRules, deBooleanType);
			
		ElsIf (NodeName = "Property") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	NewRow.SimplifiedPropertyExport = Not NewRow.GetFromIncomingData And Not NewRow.HasBeforeExportHandler
		And Not NewRow.HasOnExportHandler And Not NewRow.HasAfterExportHandler
		And IsBlankString(NewRow.ConversionRule) And NewRow.SourceType = NewRow.DestinationType
		And (NewRow.SourceType = "String" Or NewRow.SourceType = "Number" Or NewRow.SourceType = "Boolean" Or NewRow.SourceType = "Date");
		
	NewRow.XMLNodeRequiredOnExport = NewRow.HasOnExportHandler OR NewRow.HasAfterExportHandler;
	
EndProcedure

// Imports property conversion rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  PropertiesTable - ValueTable - a value table containing PCR.
//  SearchTable  - ValueTable - a value table containing PCR (synchronizing).
//
Procedure ImportProperties(ExchangeRules, PropertiesTable, SearchTable)

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Property" Then
			ImportPCR(ExchangeRules, PropertiesTable, SearchTable);
		ElsIf NodeName = "Group" Then
			ImportPGCR(ExchangeRules, PropertiesTable);
		ElsIf (NodeName = "Properties") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	PropertiesTable.Sort("Order");
	SearchTable.Sort("Order");
	
EndProcedure

// Imports the value conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  Values       - Map - a map of source object values to destination object presentation strings.
//                   
//  SourceType   - Type - source object type.
//
Procedure ImportVCR(ExchangeRules, Values, SourceType)

	Source = "";
	Destination = "";
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Source" Then
			Source = deElementValue(ExchangeRules, deStringType);
		ElsIf NodeName = "Destination" Then
			Destination = deElementValue(ExchangeRules, deStringType);
		ElsIf (NodeName = "Value") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If ExchangeMode <> "Load" Then
		Values[deGetValueByString(Source, SourceType)] = Destination;
	EndIf;
	
EndProcedure

// Imports value conversion rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  Values       - Map - a map of source object values to destination object presentation strings.
//                   
//  SourceType   - Type - source object type.
//
Procedure ImportValues(ExchangeRules, Values, SourceType);

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Value" Then
			ImportVCR(ExchangeRules, Values, SourceType);
		ElsIf (NodeName = "Values") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// Clears OCR for exchange rule managers.
Procedure ClearManagersOCR()
	
	If Managers = Undefined Then
		Return;
	EndIf;
	
	For Each RuleManager In Managers Do
		RuleManager.Value.OCR = Undefined;
	EndDo;
	
EndProcedure

// Imports the object conversion rule.
//
// Parameters:
//  ExchangeRules - XMLReader.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportConversionRule(ExchangeRules, XMLWriter)

	XMLWriter.WriteStartElement("Rule");

	NewRow = ConversionRulesCollection().Add();
	
	// Default values
	
	NewRow.RememberExported = True;
	NewRow.DoNotReplace            = False;

	SearchInTSTable = SearchInTabularSectionsCollection();
	NewRow.SearchInTabularSections = SearchInTSTable;

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
				
		If NodeName = "Code" Then
			
			Value = deElementValue(ExchangeRules, deStringType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.Name = Value;
			
		ElsIf NodeName = "Description" Then
			
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "SynchronizeByID" Then
			
			NewRow.SynchronizeByID = deElementValue(ExchangeRules, deBooleanType);
			deWriteElement(XMLWriter, NodeName, NewRow.SynchronizeByID);
			
		ElsIf NodeName = "DoNotCreateIfNotFound" Then
			
			NewRow.DoNotCreateIfNotFound = deElementValue(ExchangeRules, deBooleanType);

		ElsIf NodeName = "DoNotExportPropertyObjectsByRefs" Then
			
			NewRow.DoNotExportPropertyObjectsByRefs = deElementValue(ExchangeRules, deBooleanType);
						
		ElsIf NodeName = "SearchBySearchFieldsIfNotFoundByID" Then
			
			NewRow.SearchBySearchFieldsIfNotFoundByID = deElementValue(ExchangeRules, deBooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.SearchBySearchFieldsIfNotFoundByID);
			
		ElsIf NodeName = "OnMoveObjectByRefSetGIUDOnly" Then
			
			NewRow.OnMoveObjectByRefSetGIUDOnly = deElementValue(ExchangeRules, deBooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.OnMoveObjectByRefSetGIUDOnly);

		ElsIf NodeName = "DoNotReplaceObjectCreatedInDestinationInfobase" Then
			// Has no effect on the exchange
			deElementValue(ExchangeRules, deBooleanType);	
						
		ElsIf NodeName = "UseQuickSearchOnImport" Then
			
			NewRow.UseQuickSearchOnImport = deElementValue(ExchangeRules, deBooleanType);

		ElsIf NodeName = "GenerateNewNumberOrCodeIfNotSet" Then
			
			NewRow.GenerateNewNumberOrCodeIfNotSet = deElementValue(ExchangeRules, deBooleanType);
			deWriteElement(XMLWriter, NodeName, NewRow.GenerateNewNumberOrCodeIfNotSet);
			
		ElsIf NodeName = "DoNotRememberExported" Then
			
			NewRow.RememberExported = Not deElementValue(ExchangeRules, deBooleanType);
			
		ElsIf NodeName = "DoNotReplace" Then
			
			Value = deElementValue(ExchangeRules, deBooleanType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.DoNotReplace = Value;

		ElsIf NodeName = "ExchangeObjectsPriority" Then
			
			// Does not use in the universal exchange.
			deElementValue(ExchangeRules, deStringType);

		ElsIf NodeName = "Destination" Then
			
			Value = deElementValue(ExchangeRules, deStringType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.Destination = Value;

		ElsIf NodeName = "Source" Then
			
			Value = deElementValue(ExchangeRules, deStringType);
			deWriteElement(XMLWriter, NodeName, Value);
			
			If ExchangeMode = "Load" Then
				
				NewRow.Source	= Value;
				
			Else
				
				If Not IsBlankString(Value) Then
					          
					NewRow.SourceType = Value;
					NewRow.Source	= Type(Value);
					
					Try
						
						Managers[NewRow.Source].OCR = NewRow;
						
					Except
						
						WriteErrorInfoToLog(11, ErrorDescription(), String(NewRow.Source));
						
					EndTry; 
					
				EndIf;
				
			EndIf;
			
		// Properties
		
		ElsIf NodeName = "Properties" Then
		
			NewRow.SearchProperties	= mPropertyConversionRulesTable.Copy();
			NewRow.Properties		= mPropertyConversionRulesTable.Copy();
			
			
			If NewRow.SynchronizeByID <> Undefined And NewRow.SynchronizeByID Then
				
				SearchPropertyUUID = NewRow.SearchProperties.Add();
				SearchPropertyUUID.Name = "{UUID}";
				SearchPropertyUUID.Source = "{UUID}";
				SearchPropertyUUID.Destination = "{UUID}";
				
			EndIf;
			
			ImportProperties(ExchangeRules, NewRow.Properties, NewRow.SearchProperties);

			
		// Values
		
		ElsIf NodeName = "Values" Then
		
			LoadValues(ExchangeRules, NewRow.Values, NewRow.Source);
			
		// Event handlers
		
		ElsIf NodeName = "BeforeExport" Then
		
			NewRow.BeforeExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			
			NewRow.OnExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			
			NewRow.AfterExport = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "AfterExportToFile" Then
			
			NewRow.AfterExportToFile = GetHandlerValueFromText(ExchangeRules);
			NewRow.HasAfterExportToFileHandler  = Not IsBlankString(NewRow.AfterExportToFile);
			
		// For import
		
		ElsIf NodeName = "BeforeImport" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
 			If ExchangeMode = "Load" Then
				
				NewRow.BeforeImport               = Value;
				NewRow.HasBeforeImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "OnImport" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Load" Then
				
				NewRow.OnImport               = Value;
				NewRow.HasOnImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "AfterImport" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Load" Then
				
				NewRow.AfterImport               = Value;
				NewRow.HasAfterImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
	 		EndIf;

		ElsIf NodeName = "SearchFieldSequence" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			NewRow.HasSearchFieldSequenceHandler = Not IsBlankString(Value);
			
			If ExchangeMode = "Load" Then
				
				NewRow.SearchFieldSequence = Value;
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "SearchInTabularSections" Then
			
			Value = deElementValue(ExchangeRules, deStringType);
			
			For Number = 1 To StrLineCount(Value) Do
				
				CurrentLine = StrGetLine(Value, Number);
				
				SearchString = SplitWithSeparator(CurrentLine, ":");
				
				TableRow = SearchInTSTable.Add();
				TableRow.ItemName = CurrentLine;
				
				TableRow.TSSearchFields = SplitStringIntoSubstringsArray(SearchString);
				
			EndDo;

		ElsIf (NodeName = "Rule") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;

	ResultingTSSearchString = "";
	
	// Sending details of tabular section search fields to the destination.
	For Each PropertyString In NewRow.Properties Do
		
		If Not PropertyString.IsFolder Or IsBlankString(PropertyString.SourceKind)
			Or IsBlankString(PropertyString.Destination) Then
			
			Continue;
			
		EndIf;
		
		If IsBlankString(PropertyString.SearchFieldsString) Then
			Continue;
		EndIf;
		
		ResultingTSSearchString = ResultingTSSearchString + Chars.LF + PropertyString.SourceKind + "." + PropertyString.Destination + ":" + PropertyString.SearchFieldsString;
		
	EndDo;

	ResultingTSSearchString = TrimAll(ResultingTSSearchString);
	
	If Not IsBlankString(ResultingTSSearchString) Then
		
		deWriteElement(XMLWriter, "SearchInTabularSections", ResultingTSSearchString);	
		
	EndIf;

	XMLWriter.WriteEndElement();

	
	// Quick access to OCR by name.
	
	Rules.Insert(NewRow.Name, NewRow);
	
EndProcedure
 
// Imports object conversion rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportConversionRules(ExchangeRules, XMLWriter)

	ConversionRulesTable.Clear();
	ClearManagersOCR();
	
	XMLWriter.WriteStartElement("ObjectConversionRules");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Rule" Then
			
			ImportConversionRule(ExchangeRules, XMLWriter);
			
		ElsIf (NodeName = "ObjectConversionRules") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
	ConversionRulesTable.Indexes.Add("Destination");
	
EndProcedure

// Imports the data clearing rules group according to the exchange rules format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  NewRow - ValueTreeRow - a structure that describes the data clearing rules group.
//    * Name - String - a rule ID.
//    * Description - String - a user presentation of the rule.
// 
Procedure ImportDCRGroup(ExchangeRules, NewRow)

	NewRow.IsFolder = True;
	NewRow.Enable  = Number(Not deAttribute(ExchangeRules, deBooleanType, "Disable"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, deStringType);

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "Rule" Then
			VTRow = NewRow.Rows.Add();
			ImportDCR(ExchangeRules, VTRow);

		ElsIf (NodeName = "Group") And (NodeType = deXMLNodeType_StartElement) Then
			VTRow = NewRow.Rows.Add();
			ImportDCRGroup(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "Group") And (NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Imports the data clearing rule according to the format of exchange rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  NewRow - ValueTreeRow - a structure that describes the data clearing rule.
//    * Name - String - a rule ID.
//    * Description - String - a user presentation of the rule.
// 
Procedure ImportDCR(ExchangeRules, NewRow)

	NewRow.Enable = Number(Not deAttribute(ExchangeRules, deBooleanType, "Disable"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Code" Then
			Value = deElementValue(ExchangeRules, deStringType);
			NewRow.Name = Value;

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "DataFilterMethod" Then
			NewRow.DataFilterMethod = deElementValue(ExchangeRules, deStringType);

		ElsIf NodeName = "SelectionObject" Then
			SelectionObject = deElementValue(ExchangeRules, deStringType);
			If Not IsBlankString(SelectionObject) Then
				NewRow.SelectionObject = Type(SelectionObject);
			EndIf; 

		ElsIf NodeName = "DeleteForPeriod" Then
			NewRow.DeleteForPeriod = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "Directly" Then
			NewRow.Directly = deElementValue(ExchangeRules, deBooleanType);

		
		// Event handlers

		ElsIf NodeName = "BeforeProcessRule" Then
			NewRow.BeforeProcess = GetHandlerValueFromText(ExchangeRules);
			
		ElsIf NodeName = "AfterProcessRule" Then
			NewRow.AfterProcess = GetHandlerValueFromText(ExchangeRules);
		
		ElsIf NodeName = "BeforeDeleteObject" Then
			NewRow.BeforeDelete = GetHandlerValueFromText(ExchangeRules);

		// Exit
		ElsIf (NodeName = "Rule") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
			
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Imports data clearing rules.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportClearingRules(ExchangeRules, XMLWriter)
	
 	CleanupRulesTable.Rows.Clear();
	VTRows = CleanupRulesTable.Rows;
	
	XMLWriter.WriteStartElement("DataClearingRules");

	While ExchangeRules.Read() Do
		
		NodeType = ExchangeRules.NodeType;
		
		If NodeType = deXMLNodeType_StartElement Then
			NodeName = ExchangeRules.LocalName;
			If ExchangeMode <> "Load" Then
				XMLWriter.WriteStartElement(ExchangeRules.Name);
				While ExchangeRules.ReadAttribute() Do
					XMLWriter.WriteAttribute(ExchangeRules.Name, ExchangeRules.Value);
				EndDo;
			Else
				If NodeName = "Rule" Then
					VTRow = VTRows.Add();
					ImportDCR(ExchangeRules, VTRow);
				ElsIf NodeName = "Group" Then
					VTRow = VTRows.Add();
					ImportDCRGroup(ExchangeRules, VTRow);
				EndIf;
			EndIf;
		ElsIf NodeType = deXMLNodeType_EndElement Then
			NodeName = ExchangeRules.LocalName;
			If NodeName = "DataClearingRules" Then
				Break;
			Else
				If ExchangeMode <> "Load" Then
					XMLWriter.WriteEndElement();
				EndIf;
			EndIf;
		ElsIf NodeType = deXMLNodeType_Text Then
			If ExchangeMode <> "Load" Then
				XMLWriter.WriteText(ExchangeRules.Value);
			EndIf;
		EndIf; 
	EndDo;

	VTRows.Sort("Order", True);
	
 	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports the algorithm according to the exchange rules format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportAlgorithm(ExchangeRules, XMLWriter)

	UsedOnImport = deAttribute(ExchangeRules, deBooleanType, "UsedOnImport");
	Name                     = deAttribute(ExchangeRules, deStringType, "Name");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Text" Then
			Text = GetHandlerValueFromText(ExchangeRules);
		ElsIf (NodeName = "Algorithm") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		Else
			deSkip(ExchangeRules);
		EndIf;
		
	EndDo;
	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			Algorithms.Insert(Name, Text);
		Else
			XMLWriter.WriteStartElement("Algorithm");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Load" Then
			Algorithms.Insert(Name, Text);
		EndIf;
	EndIf;
	
	
EndProcedure

// Imports algorithms according to the exchange rules format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportAlgorithms(ExchangeRules, XMLWriter)

	Algorithms.Clear();

	XMLWriter.WriteStartElement("Algorithms");
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		If NodeName = "Algorithm" Then
			ImportAlgorithm(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "Algorithms") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports the query according to the exchange rules format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportQuery(ExchangeRules, XMLWriter)

	UsedOnImport = deAttribute(ExchangeRules, deBooleanType, "UsedOnImport");
	Name                     = deAttribute(ExchangeRules, deStringType, "Name");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Text" Then
			Text = GetHandlerValueFromText(ExchangeRules);
		ElsIf (NodeName = "Query") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		Else
			deSkip(ExchangeRules);
		EndIf;
		
	EndDo;

	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			Query	= New Query(Text);
			Queries.Insert(Name, Query);
		Else
			XMLWriter.WriteStartElement("Query");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Load" Then
			Query	= New Query(Text);
			Queries.Insert(Name, Query);
		EndIf;
	EndIf;
	
EndProcedure

// Imports queries according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportQueries(ExchangeRules, XMLWriter)

	Queries.Clear();

	XMLWriter.WriteStartElement("Queries");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Query" Then
			ImportQuery(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "Queries") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports parameters according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportParameters(ExchangeRules, XMLWriter)

	Parameters.Clear();
	EventsAfterParametersImport.Clear();
	ParametersSettingsTable.Clear();

	XMLWriter.WriteStartElement("Parameters");
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;

		If NodeName = "Parameter" And NodeType = deXMLNodeType_StartElement Then
			
			// Importing by the 2.01 rule version.
			Name                     = deAttribute(ExchangeRules, deStringType, "Name");
			Description            = deAttribute(ExchangeRules, deStringType, "Description");
			SetInDialog   = deAttribute(ExchangeRules, deBooleanType, "SetInDialog");
			ValueTypeString      = deAttribute(ExchangeRules, deStringType, "ValueType");
			UsedOnImport = deAttribute(ExchangeRules, deBooleanType, "UsedOnImport");
			PassParameterOnExport = deAttribute(ExchangeRules, deBooleanType, "PassParameterOnExport");
			ConversionRule = deAttribute(ExchangeRules, deStringType, "ConversionRule");
			AfterParameterImportAlgorithm = deAttribute(ExchangeRules, deStringType, "AfterImportParameter");

			If Not IsBlankString(AfterParameterImportAlgorithm) Then
				
				EventsAfterParametersImport.Insert(Name, AfterParameterImportAlgorithm);
				
			EndIf;
			
			If ExchangeMode = "Load" AND NOT UsedOnImport Then
				Continue;
			EndIf;
			
			// Determining value types and setting initial values.
			If Not IsBlankString(ValueTypeString) Then
				
				Try
					DataValueType = Type(ValueTypeString);
					TypeDefined = True;
				Except
					TypeDefined = False;
				EndTry;
				
			Else
				
				TypeDefined = False;
				
			EndIf;
			
			If TypeDefined Then
				ParameterValue = deGetEmptyValue(DataValueType);
				Parameters.Insert(Name, ParameterValue);
			Else
				ParameterValue = "";
				Parameters.Insert(Name);
			EndIf;
						
			If SetInDialog = TRUE Then
				
				TableRow              = ParametersSettingsTable.Add();
				TableRow.Description = Description;
				TableRow.Name          = Name;
				TableRow.Value = ParameterValue;				
				TableRow.PassParameterOnExport = PassParameterOnExport;
				TableRow.ConversionRule = ConversionRule;
				
			EndIf;

			If UsedOnImport And ExchangeMode = "DataExported" Then
				
				XMLWriter.WriteStartElement("Parameter");
				SetAttribute(XMLWriter, "Name",   Name);
				SetAttribute(XMLWriter, "Description", Description);
					
				If NOT IsBlankString(AfterParameterImportAlgorithm) Then
					SetAttribute(XMLWriter, "AfterImportParameter", XMLString(AfterParameterImportAlgorithm));
				EndIf;
				
				XMLWriter.WriteEndElement();
				
			EndIf;

		ElsIf (NodeType = deXMLNodeType_Text) Then
			
			// Importing from the string to provide 2.0 compatibility.
			ParametersString = ExchangeRules.Value;
			For Each Par In ArrayFromString(ParametersString) Do
				Parameters.Insert(Par);
			EndDo;
			
		ElsIf (NodeName = "Parameters") And (NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();

EndProcedure

// Imports the data processor according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportDataProcessor(ExchangeRules, XMLWriter)

	Name                     = deAttribute(ExchangeRules, deStringType, "Name");
	Description            = deAttribute(ExchangeRules, deStringType, "Description");
	IsSetupDataProcessor   = deAttribute(ExchangeRules, deBooleanType, "IsSetupDataProcessor");
	
	UsedOnExport = deAttribute(ExchangeRules, deBooleanType, "UsedOnExport");
	UsedOnImport = deAttribute(ExchangeRules, deBooleanType, "UsedOnImport");

	ParametersString        = deAttribute(ExchangeRules, deStringType, "Parameters");
	
	DataProcessorStorage      = deElementValue(ExchangeRules, deValueStorageType);

	AdditionalDataProcessorParameters.Insert(Name, ArrayFromString(ParametersString));
	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			
		Else
			XMLWriter.WriteStartElement("DataProcessor");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",                     Name);
			SetAttribute(XMLWriter, "Description",            Description);
			SetAttribute(XMLWriter, "IsSetupDataProcessor",   IsSetupDataProcessor);
			XMLWriter.WriteText(XMLString(DataProcessorStorage));
			XMLWriter.WriteEndElement();
		EndIf;
	EndIf;
	
	If IsSetupDataProcessor Then
		If (ExchangeMode = "Load") And UsedOnImport Then
			ImportSettingsDataProcessors.Add(Name, Description, , );
			
		ElsIf (ExchangeMode = "DataExported") And UsedOnExport Then
			ExportSettingsDataProcessors.Add(Name, Description, , );
			
		EndIf; 
	EndIf; 
	
EndProcedure

// Imports external data processors according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  XMLWriter - XMLWriter - rules to be saved into the exchange file and used on data import.
//
Procedure ImportDataProcessors(ExchangeRules, XMLWriter)

	AdditionalDataProcessors.Clear();
	AdditionalDataProcessorParameters.Clear();
	
	ExportSettingsDataProcessors.Clear();
	ImportSettingsDataProcessors.Clear();

	XMLWriter.WriteStartElement("DataProcessors");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "DataProcessor" Then
			ImportDataProcessor(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "DataProcessors") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Imports the data exporting rule group according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  NewRow    - ValueTreeRow - a structure that describes the data clearing rule.
//    * Name - String - a rule ID.
//    * Description - String - a user presentation of the rule.
//
Procedure ImportDERGroup(ExchangeRules, NewRow)

	NewRow.IsGroup = True;
	NewRow.Enable  = Number(Not deAttribute(ExchangeRules, deBooleanType, "Disable"));
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		If NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, deStringType);

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "Rule" Then
			VTRow = NewRow.Rows.Add();
			ImportDER(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "Group") And (NodeType = deXMLNodeType_StartElement) Then
			VTRow = NewRow.Rows.Add();
			ImportDERGroup(ExchangeRules, VTRow);
					
		ElsIf (NodeName = "Group") And (NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Imports the data export rule according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//  NewRow    - ValueTreeRow - a structure that describes the data clearing rule.
//    * Name - String - a rule ID.
//    * Description - String - a user presentation of the rule.
//
Procedure ImportDER(ExchangeRules, NewRow)

	NewRow.Enable = Number(Not deAttribute(ExchangeRules, deBooleanType, "Disable"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		If      NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, deStringType);

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, deStringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, deNumberType);
			
		ElsIf NodeName = "DataFilterMethod" Then
			NewRow.DataFilterMethod = deElementValue(ExchangeRules, deStringType);
			
		ElsIf NodeName = "SelectExportDataInSingleQuery" Then
			NewRow.SelectExportDataInSingleQuery = deElementValue(ExchangeRules, deBooleanType);

		ElsIf NodeName = "DoNotExportObjectsCreatedInDestinationInfobase" Then
			// Skipping the parameter during the data exchange.
			deElementValue(ExchangeRules, deBooleanType);

		ElsIf NodeName = "SelectionObject" Then
			SelectionObject = deElementValue(ExchangeRules, deStringType);
			If Not IsBlankString(SelectionObject) Then
				NewRow.SelectionObject = Type(SelectionObject);
			EndIf;
			// For filtering using the query builder.
			If StrFind(SelectionObject, "Ref.") Then
				NewRow.ObjectNameForQuery = StrReplace(SelectionObject, "Ref.", ".");
			Else
				NewRow.ObjectNameForRegisterQuery = StrReplace(SelectionObject, "Record.", ".");
			EndIf;

		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, deStringType);

		// Event handlers

		ElsIf NodeName = "BeforeProcessRule" Then
			NewRow.BeforeProcess = GetHandlerValueFromText(ExchangeRules);
			
		ElsIf NodeName = "AfterProcessRule" Then
			NewRow.AfterProcess = GetHandlerValueFromText(ExchangeRules);
		
		ElsIf NodeName = "BeforeExportObject" Then
			NewRow.BeforeExport = GetHandlerValueFromText(ExchangeRules);

		ElsIf NodeName = "AfterExportObject" Then
			NewRow.AfterExport = GetHandlerValueFromText(ExchangeRules);
        		
		ElsIf (NodeName = "Rule") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			Break;
		EndIf;
		
	EndDo;

	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
	If IsBlankString(NewRow.MetadataName) Then
		NewRow.MetadataName = ?(ValueIsFilled(NewRow.ObjectNameForRegisterQuery),
			NewRow.ObjectNameForRegisterQuery, NewRow.ObjectNameForQuery);
	КонецЕсли;

EndProcedure

// Imports data export rules according to the exchange rule format.
//
// Parameters:
//  ExchangeRules - XMLReader object.
//
Procedure ImportExportRules(ExchangeRules)

	ExportRulesTable.Rows.Clear();

	VTRows = ExportRulesTable.Rows;
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Rule" Then
			
			VTRow = VTRows.Add();
			ImportDER(ExchangeRules, VTRow);
			
		ElsIf NodeName = "Group" Then
			
			VTRow = VTRows.Add();
			ImportDERGroup(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "DataExportRules") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;

	VTRows.Sort("Order", True);

EndProcedure

#EndRegion

#Region ProceduresOfExportHandlersAndProceduresToTXTFileFromExchangeRules

// Exports event handlers and algorithms to the temporary text file (user temporary directory).
// 
// Generates debug module with handlers and algorithms and all necessary global variables, common 
// function bind methods, and comments.
//
// Parameters:
//  Cancel - Boolean - a flag showing that debug module creation is canceled. Sets to True in case of exchange rule 
//          reading failure.
//
Procedure ExportEventHandlers(Cancel) Export
	
	InitializeKeepExchangeLogForHandlersExport();
	
	DataProcessingMode = mDataProcessingModes.EventHandlersExport;
	
	ErrorFlag = False;
	
	ImportExchangeRulesForHandlerExport();
	
	If ErrorFlag Then
		Cancel = True;
		Return;
	EndIf;

	SupplementRulesWithHandlerInterfaces(Conversion, ConversionRulesTable, ExportRulesTable, CleanupRulesTable);

	If AlgorithmDebugMode = mAlgorithmDebugModes.CodeIntegration Then
		
		GetFullAlgorithmScriptRecursively();
		
	EndIf;

	EventHandlersTempFileName = GetNewUniqueTempFileName(
		EventHandlersTempFileName);

	Result = New TextWriter(EventHandlersTempFileName, TextEncoding.ANSI);
	
	mCommonProceduresFunctionsTemplate = GetTemplate("CommonProceduresFunctions");
	
	// Adding comments.
	AddCommentToStream(Result, "Header");
	AddCommentToStream(Result, "DataProcessorVariables");
	
	// Adding the service script.
	AddServiceCodeToStream(Result, "DataProcessorVariables");
	
	// Exporting global handlers.
	ExportConversionHandlers(Result);
	
	// Exporting DER.
	AddCommentToStream(Result, "DER", ExportRulesTable.Rows.Count() <> 0);
	ExportDataExportRuleHandlers(Result, ExportRulesTable.Rows);
	
	// Exporting DCR.
	AddCommentToStream(Result, "DCR", CleanupRulesTable.Rows.Count() <> 0);
	ExportDataClearingRuleHandlers(Result, CleanupRulesTable.Rows);
	
	// Exporting OCR, PCR, PGCR.
	ExportConversionRuleHandlers(Result);
	
	If AlgorithmDebugMode = mAlgorithmDebugModes.ProceduralCall Then
		
		// Exporting algorithms with standard (default) parameters.
		ExportAlgorithms(Result);
		
	EndIf; 
	
	// Adding comments
	AddCommentToStream(Result, "Warning");
	AddCommentToStream(Result, "CommonProceduresFunctions");
		
	// Adding common procedures and functions to the stream.
	AddServiceCodeToStream(Result, "CommonProceduresFunctions");

	// Adding the external data processor constructor.
	ExportExternalDataProcessorConstructor(Result);
	
	// Adding the destructor
	AddServiceCodeToStream(Result, "Destructor");

	Result.Close();
	
	FinishKeepExchangeLog();
	
	If IsInteractiveMode Then
		
		If ErrorFlag Then
			
			MessageToUser(NStr("ru = 'При выгрузке обработчиков были обнаружены ошибки.'; en = 'Error exporting handlers.'"));
			
		Else
			
			MessageToUser(NStr("ru = 'Обработчики успешно выгружены.'; en = 'Handlers has been successfully exported.'"));
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Clears variables with structure of exchange rules.
//
// Parameters:
//  No.
//  
Procedure ClearExchangeRules()
	
	ExportRulesTable.Rows.Clear();
	CleanupRulesTable.Rows.Clear();
	ConversionRulesTable.Clear();
	Algorithms.Clear();
	Queries.Clear();

	// Data processors
	AdditionalDataProcessors.Clear();
	AdditionalDataProcessorParameters.Clear();
	ExportSettingsDataProcessors.Clear();
	ImportSettingsDataProcessors.Clear();

EndProcedure  

// Exports exchange rules from rule file or data file.
//
// Parameters:
//  No.
//  
Procedure ImportExchangeRulesForHandlerExport()
	
	ClearExchangeRules();
	
	If ReadEventHandlersFromExchangeRulesFile Then
		
		ExchangeMode = ""; // Exporting data.

		ImportExchangeRules();
		
		mExchangeRulesReadOnImport = False;
		
		InitializeInitialParameterValues();
		
	Else // Data file
		
		ExchangeMode = "Load"; 
		
		If IsBlankString(ExchangeFileName) Then
			WriteToExecutionLog(15);
			Return;
		EndIf;
		
		OpenImportFile(True);
		
		// If the flag is set, the data processor requires to reimport rules on data export start.
		mExchangeRulesReadOnImport = True;

	EndIf;
	
EndProcedure

// Exports global conversion handlers to a text file.
// During the handler export from the data file, the content of the Conversion_AfterParametersImport handler
// is not exported, because the handler script is is in the different node.
// During the handler export from the rule file, this algorithm exported as all others.
//
// Parameters:
//  Result - TextWriter - an object to export handlers to a text file.
//
Procedure ExportConversionHandlers(Result)
	
	AddCommentToStream(Result, "Conversion");
	
	For Each Item In HandlersNames.Conversion Do
		
		AddConversionHandlerToStream(Result, Item.Key);
		
	EndDo; 
	
EndProcedure 

// Exports handlers of data export rules to the text file.
//
// Parameters:
//  Result    - TextWriter - an object to output handlers to a text file.
//  TreeRows - ValueTreeRowCollection - a DER of this value tree level.
//
Procedure ExportDataExportRuleHandlers(Result, TreeRows)
	
	For Each Rule In TreeRows Do
		
		If Rule.IsGroup Then
			
			ExportDataExportRuleHandlers(Result, Rule.Rows); 
			
		Else
			
			For Each Item In HandlersNames.DER Do
				
				AddHandlerToStream(Result, Rule, "DER", Item.Key);
				
			EndDo; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure  

// Exports handlers of data clearing rules to the text file.
//
// Parameters:
//  Result    - TextWriter - an object to output handlers to a text file.
//  TreeRows - ValueTreeRowCollection - a DCR of this value tree level.
//
Procedure ExportDataClearingRuleHandlers(Result, TreeRows)
	
	For Each Rule In TreeRows Do
		
		If Rule.IsGroup Then
			
			ExportDataClearingRuleHandlers(Result, Rule.Rows); 
			
		Else
			
			For Each Item In HandlersNames.DCR Do
				
				AddHandlerToStream(Result, Rule, "DCR", Item.Key);
				
			EndDo; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure  

// Exports the following conversion rule handlers into a text file: OCR, PCR, and PGCR.
//
// Parameters:
//  Result    - TextWriter - an object to output handlers to a text file.
//
Procedure ExportConversionRuleHandlers(Result)
	
	OutputComment = ConversionRulesTable.Count() <> 0;
	
	// Exporting OCR.
	AddCommentToStream(Result, "OCR", OutputComment);
	
	For Each OCR In ConversionRulesTable Do
		
		For Each Item In HandlersNames.OCR Do
			
			AddOCRHandlerToStream(Result, OCR, Item.Key);
			
		EndDo; 
		
	EndDo; 
	
	// Exporting PCR and PGCR.
	AddCommentToStream(Result, "PCR", OutputComment);
	
	For Each OCR In ConversionRulesTable Do
		
		ExportPropertyConversionRuleHandlers(Result, OCR.SearchProperties);
		ExportPropertyConversionRuleHandlers(Result, OCR.Properties);
		
	EndDo; 
	
EndProcedure 

// Exports handlers of property conversion rules to a text file.
//
// Parameters:
//  Result - TextWriter - an object to output handlers to a text file.
//  PCR       - ValueTable - contains rules of conversion of object properties or property groups.
//
Procedure ExportPropertyConversionRuleHandlers(Result, PCR)
	
	For Each Rule In PCR Do
		
		If Rule.IsGroup Then // PGCR
			
			For Each Item In HandlersNames.PGCR Do
				
				AddOCRHandlerToStream(Result, Rule, Item.Key);
				
			EndDo; 

			ExportPropertyConversionRuleHandlers(Result, Rule.GroupRules);
			
		Else
			
			For Each Item In HandlersNames.PCR Do
				
				AddOCRHandlerToStream(Result, Rule, Item.Key);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Exports algorithms to the text file.
//
// Parameters:
//  Result - TextWriter - an object to output algorithms to a text file.
// 
Procedure ExportAlgorithms(Result)
	
	// Commenting the Algorithms block.
	AddCommentToStream(Result, "Algorithms", Algorithms.Count() <> 0);
	
	For Each Algorithm In Algorithms Do
		
		AddAlgorithmToSteam(Result, Algorithm);
		
	EndDo; 
	
EndProcedure  

// Exports the external data processor constructor to the text file.
//  If algorithm debug mode is "debug algorithms as procedures", then the constructor receives structure
//  "Algorithms".
//  Structure item key is algorithm name and its value is the interface of procedure call that contains algorithm code.
//
// Parameters:
//  Result    - TextWriter - an object to output handlers to a text file.
//
Procedure ExportExternalDataProcessorConstructor(Result)
	
	// Displaying the comment
	AddCommentToStream(Result, "Constructor");

	ProcedureBody = GetServiceCode("Constructor_ProcedureBody");

	If AlgorithmDebugMode = mAlgorithmDebugModes.ProceduralCall Then
		
		ProcedureBody = ProcedureBody + GetServiceCode("Constructor_ProcedureBody_ProceduralAlgorithmCall");
		
		// Adding algorithm calls to the constructor body.
		For Each Algorithm In Algorithms Do
			
			AlgorithmKey = TrimAll(Algorithm.Key);
			
			AlgorithmInterface = GetAlgorithmInterface(AlgorithmKey) + ";";
			
			AlgorithmInterface = StrReplace(StrReplace(AlgorithmInterface, Chars.LF, " ")," ","");
			
			ProcedureBody = ProcedureBody + Chars.LF 
			   + "Algorithms.Insert(""" + AlgorithmKey + """, """ + AlgorithmInterface + """);";
		EndDo;

	ElsIf AlgorithmDebugMode = mAlgorithmDebugModes.CodeIntegration Then
		
		ProcedureBody = ProcedureBody + GetServiceCode("Constructor_ProcedureBody_AlgorithmCodeIntegration");
		
	ElsIf AlgorithmDebugMode = mAlgorithmDebugModes.DontUse Then
		
		ProcedureBody = ProcedureBody + GetServiceCode("Constructor_ProcedureBody_DoNotUseAlgorithmDebug");
		
	EndIf; 
	
	ExternalDataProcessorProcedureInterface = "Procedure " + GetExternalDataProcessorProcedureInterface("Constructor") + " Export";
	
	AddFullHandlerToStream(Result, ExternalDataProcessorProcedureInterface, ProcedureBody);
	
EndProcedure  

// Adds an OCR, PCR, or PGCR handler to the Result object.
//
// Parameters:
//  Result      - TextWriter - an object to output a handler to a text file.
//  Rule        - ValueTableRow - an object conversion rules.
//  HandlerName - String - a handler name.
//
Procedure AddOCRHandlerToStream(Result, Rule, HandlerName)
	
	If Not Rule["HasHandler" + HandlerName] Then
		Return;
	EndIf; 
	
	HandlerInterface = "Procedure " + Rule["HandlerInterface" + HandlerName] + " Export";
	
	AddFullHandlerToStream(Result, HandlerInterface, Rule[HandlerName]);
	
EndProcedure  

// Adds an algorithm code to the Result object.
//
// Parameters:
//  Result - TextWriter - an object to output a handler to a text file.
//  Algorithm  - structure item - an algorithm to export.
//
Procedure AddAlgorithmToSteam(Result, Algorithm)
	
	AlgorithmInterface = "Procedure " + GetAlgorithmInterface(Algorithm.Key);

	AddFullHandlerToStream(Result, AlgorithmInterface, Algorithm.Value);
	
EndProcedure  

// Adds to the Result object a DER or DCR handler.
//
// Parameters:
//  Result      - TextWriter - an object to output a handler to a text file.
//  Rule        - ValueTreeRow - rules.
//  HandlerPrefix - String - a handler prefix: DER or DCR.
//  HandlerName - String - a handler name.
//
Procedure AddHandlerToStream(Result, Rule, HandlerPrefix, HandlerName)
	
	If IsBlankString(Rule[HandlerName]) Then
		Return;
	EndIf;
	
	HandlerInterface = "Procedure " + Rule["HandlerInterface" + HandlerName] + " Export";
	
	AddFullHandlerToStream(Result, HandlerInterface, Rule[HandlerName]);
	
EndProcedure  

// Adds a global conversion handler to the Result object.
//
// Parameters:
//  Result      - TextWriter - an object to output a handler to a text file.
//  HandlerName - String - a handler name.
//
Procedure AddConversionHandlerToStream(Result, HandlerName)
	
	HandlerAlgorithm = "";
	
	If Conversion.Property(HandlerName, HandlerAlgorithm) And Not IsBlankString(HandlerAlgorithm) Then
		
		HandlerInterface = "Procedure " + Conversion["HandlerInterface" + HandlerName] + " Export";
		
		AddFullHandlerToStream(Result, HandlerInterface, HandlerAlgorithm);
		
	EndIf;
	
EndProcedure  

// Adds a procedure with a handler or algorithm code to the Result object.
//
// Parameters:
//  Result            - TextWriter - an object to output procedure to a text file.
//  HandlerInterface - String - full handler interface description:
//                         procedure name, parameters, Export keyword.
//  Handler           - String - a body of a handler or an algorithm.
//
Procedure AddFullHandlerToStream(Result, HandlerInterface, Handler)
	
	PrefixString = Chars.Tab;
	
	Result.WriteLine("");
	
	Result.WriteLine(HandlerInterface);
	
	Result.WriteLine("");

	For Index = 1 To StrLineCount(Handler) Do
		
		HandlerRow = StrGetLine(Handler, Index);
		
		// In the "Script integration" algorithm debugging mode the algorithm script is inserted directly 
		// into the handler script. The algorithm script is inserted instead of this algorithm call.
		// Algorithms can be nested. The algorithm scripts support nested algorithms.
		If AlgorithmDebugMode = mAlgorithmDebugModes.CodeIntegration Then
			
			HandlerAlgorithms = GetHandlerAlgorithms(HandlerRow);
			
			If HandlerAlgorithms.Count() <> 0 Then // There are algorithm calls in the line.
				
				// Receiving the initial algorithm code offset relative to the current handler code.
				PrefixStringForInlineCode = GetInlineAlgorithmPrefix(HandlerRow, PrefixString);
				
				For Each Algorithm In HandlerAlgorithms Do
					
					AlgorithmHandler = IntegratedAlgorithms[Algorithm];
					
					For AlgorithmRowIndex = 1 To StrLineCount(AlgorithmHandler) Do
						
						Result.WriteLine(PrefixStringForInlineCode + StrGetLine(AlgorithmHandler, AlgorithmRowIndex));
						
					EndDo;	
					
				EndDo;
				
			EndIf;
		EndIf;

		Result.WriteLine(PrefixString + HandlerRow);
		
	EndDo;
	
	Result.WriteLine("");
	Result.WriteLine("EndProcedure");
	
EndProcedure

// Adds a comment to the Result object.
//
// Parameters:
//  Result          - TextWriter - an object to output comment to a text file.
//  AreaName         - String - a name of the mCommonProceduresFunction text template area
//                       that contains the required comment.
//  OutputComment - Boolean - if True, it is necessary to display a comment.
//
Procedure AddCommentToStream(Result, AreaName, OutputComment = True)
	
	If Not OutputComment Then
		Return;
	EndIf; 
	
	// Getting handler comments by the area name.
	CurrentArea = mCommonProceduresFunctionsTemplate.GetArea(AreaName+"_Comment");
	
	CommentFromTemplate = TrimAll(GetTextByAreaWithoutAreaTitle(CurrentArea));
	
	// Excluding last line feed character.
	CommentFromTemplate = Mid(CommentFromTemplate, 1, StrLen(CommentFromTemplate));
	
	Result.WriteLine(Chars.LF + Chars.LF + CommentFromTemplate);
	
EndProcedure  

// Adds service code to the Result object: parameters, common procedures and functions, and destructor of external data processor.
//
// Parameters:
//  Result          - TextWriter - an object to output service code to a text file.
//  AreaName         - String - a name of the mCommonProceduresFunction text template area
//                       that contains the required service code.
//
Procedure AddServiceCodeToStream(Result, AreaName)
	
	// Getting the area text
	CurrentArea = mCommonProceduresFunctionsTemplate.GetArea(AreaName);
	
	Text = TrimAll(GetTextByAreaWithoutAreaTitle(CurrentArea));
	
	Text = Mid(Text, 1, StrLen(Text)); // Excluding last line feed character.
	
	Result.WriteLine(Chars.LF + Chars.LF + Text);
	
EndProcedure  

// Retrieves the service code from the specified mCommonProceduresFunctionsTemplate template area.
//
// Parameters:
//  AreaName - String - a name of the mCommonProceduresFunction text template area.
//  
// Returns:
//  - String - a text from the template.
//
Function GetServiceCode(AreaName)
	
	// Getting the area text
	CurrentArea = mCommonProceduresFunctionsTemplate.GetArea(AreaName);
	
	Return GetTextByAreaWithoutAreaTitle(CurrentArea);
EndFunction

#EndRegion

#Область FullAlgorithmScriptsMethodsConsideringNesting

// Generates the full script of algorithms considering their nesting.
//
// Parameters:
//  No.
//  
Procedure GetFullAlgorithmScriptRecursively()
	
	// Filling the structure of integrated algorithms.
	IntegratedAlgorithms = New Structure;
	
	For Each Algorithm In Algorithms Do
		
		IntegratedAlgorithms.Insert(Algorithm.Key, ReplaceAlgorithmCallsWithTheirHandlerScript(Algorithm.Value, Algorithm.Key, New Array));
		
	EndDo; 
	
EndProcedure 

// Adds the NewHandler string as a comment to algorithm code insertion.
//
// Parameters:
//  NewHandler - String - a result string that contains full algorithm scripts considering nesting.
//  AlgorithmName    - String - an algorithm name.
//  PrefixString  - String - sets the initial offset of the comment.
//  Header       - String - comment description: "{ALGORITHM START}", "{ALGORITHM END}"...
//
Procedure WriteAlgorithmBlockTitle(NewHandler, AlgorithmName, PrefixString, Title) 
	
	AlgorithmTitle = "//============================ " + Title + " """ + AlgorithmName + """ ============================";
	
	NewHandler = NewHandler + Chars.LF;
	NewHandler = NewHandler + Chars.LF + PrefixString + AlgorithmTitle;
	NewHandler = NewHandler + Chars.LF;
	
EndProcedure  

// Complements the HandlerAlgorithms array with names of algorithms that are called  from the passed 
// procedure of the handler line.
//
// Parameters:
//  HandlerLine - String - a handler line or an algorithm line where algorithm calls are searched.
//  HandlerAlgorithms - Array - algorithm names that are called from the specified handler.
//  
Procedure GetHandlerStringAlgorithms(HandlerRow, HandlerAlgorithms)
	
	HandlerRow = Upper(HandlerRow);
	
	SearchTemplate = "ALGORITHMS.";
	
	TemplateStringLength = StrLen(SearchTemplate);
	
	InitialChar = StrFind(HandlerRow, SearchTemplate);
	
	If InitialChar = 0 Then
		// There are no algorithms or all algorithms from this line have been considered.
		Return; 
	EndIf;
	
	// Checking whether this operator is commented.
	HandlerLineBeforeAlgorithmCall = Left(HandlerRow, InitialChar);

	If StrFind(HandlerLineBeforeAlgorithmCall, "//") <> 0  Then 
		// The current operator and all next operators are commented.
		// Exiting loop
		Return;
	EndIf;

	HandlerRow = Mid(HandlerRow, InitialChar + TemplateStringLength);

	EndChar = StrFind(HandlerRow, ")") - 1;
	
	AlgorithmName = Mid(HandlerRow, 1, EndChar); 
	
	HandlerAlgorithms.Add(TrimAll(AlgorithmName));
	
	// Going through the handler line to consider all algorithm calls
	// 
	GetHandlerStringAlgorithms(HandlerRow, HandlerAlgorithms);
	
EndProcedure 

// Returns the modified algorithm script considering nested algorithms. Instead of the 
// "Execute(Algorithms.Algorithm_1);" algorithm call operator, the calling algorithm script is 
// inserted with the PrefixString offset.
// Recursively calls itself to consider all nested algorithms.
//
// Parameters:
//  Handler                 - String - initial algorithm script.
//  AlgorithmOwner           - String - a name of the parent algorithm.                                      
//  RequestedItemsArray - Array - names of algorithms that were already processed in this recursion branch.
//                                        It is used to prevent endless function recursion and to 
//                                        display the error message.
//  PrefixString             - String - inserting algorithm script offset mode.
//  
// Returns:
//  NewHandler - String - modified algorithm script that includes nested algorithms.
// 
Function ReplaceAlgorithmCallsWithTheirHandlerScript(Handler, AlgorithmOwner, RequestedItemArray, Val PrefixString = "")
	
	RequestedItemArray.Add(Upper(AlgorithmOwner));
	
	// Initializing the return value.
	NewHandler = "";
	
	WriteAlgorithmBlockTitle(NewHandler, AlgorithmOwner, PrefixString, NStr("ru = '{НАЧАЛО АЛГОРИТМА}'; en = '{ALGORITHM START}'"));
	
	For Index = 1 To StrLineCount(Handler) Do
		
		HandlerLine = StrGetLine(Handler, Index);

		HandlerAlgorithms = GetHandlerAlgorithms(HandlerLine);

		If HandlerAlgorithms.Count() <> 0 Then // There are algorithm calls in the line.
			
			// Receiving the initial algorithm code offset relative to the current code.
			PrefixStringForInlineCode = GetInlineAlgorithmPrefix(HandlerLine, PrefixString);
				
			// Extracting full scripts for all algorithms that were called from HandlerLine.
			// 
			For Each Algorithm In HandlerAlgorithms Do
				
				If RequestedItemArray.Find(Upper(Algorithm)) <> Undefined Then // recursive algorithm call.
					
					WriteAlgorithmBlockTitle(NewHandler, Algorithm, PrefixStringForInlineCode, NStr("ru = '{РЕКУРСИВНЫЙ ВЫЗОВ АЛГОРИТМА}'; en = '{RECURSIVE ALGORITHM CALL}'"));

					OperatorString = NStr("ru = 'ВызватьИсключение ""РЕКУРСИВНЫЙ ВЫЗОВ АЛГОРИТМА: %1"";'; en = 'CallException ""ALGORITHM RECURSIVE CALL: %1"";'");
					OperatorString = SubstituteParametersToString(OperatorString, Algorithm);
					
					NewHandler = NewHandler + Chars.LF + PrefixStringForInlineCode + OperatorString;
					
					WriteAlgorithmBlockTitle(NewHandler, Algorithm, PrefixStringForInlineCode, NStr("ru = '{РЕКУРСИВНЫЙ ВЫЗОВ АЛГОРИТМА}'; en = '{RECURSIVE ALGORITHM CALL}'"));
					
					RecordStructure = New Structure;
					RecordStructure.Insert("Algoritm_1", AlgorithmOwner);
					RecordStructure.Insert("Algoritm_2", Algorithm);
					
					WriteToExecutionLog(79, RecordStructure);

				Else
					
					NewHandler = NewHandler + ReplaceAlgorithmCallsWithTheirHandlerScript(Algorithms[Algorithm], Algorithm, CopyArray(RequestedItemArray), PrefixStringForInlineCode);
					
				EndIf; 
				
			EndDo;
			
		EndIf; 
		
		NewHandler = NewHandler + Chars.LF + PrefixString + HandlerLine; 
		
	EndDo;

	WriteAlgorithmBlockTitle(NewHandler, AlgorithmOwner, PrefixString, NStr("ru = '{КОНЕЦ АЛГОРИТМА}'; en = '{ALGORITHM END}'"));
	
	Return NewHandler;
	
EndFunction

// Copies the passed array and returns a new array.
//
// Parameters:
//  SourceArray - Array - a source to get a new array by copying.
//  
// Returns:
//  NewArray - Array - a copy of the passed array.
// 
Function CopyArray(SourceArray)
	
	NewArray = New Array;
	
	For Each ArrayElement In SourceArray Do
		
		NewArray.Add(ArrayElement);
		
	EndDo; 
	
	Return NewArray;
EndFunction 

// Returns an array with names of algorithms that were found in the passed handler body.
//
// Parameters:
//  Handler - String - a handler body.
//  
// Returns:
//  HandlerAlgorithms - Array - an array with names of algorithms that the passed handler contains.
//
Function GetHandlerAlgorithms(Handler)
	
	// Initializing the return value.
	HandlerAlgorithms = New Array;
	
	For Index = 1 To StrLineCount(Handler) Do
		
		HandlerLine = TrimL(StrGetLine(Handler, Index));
		
		If StrStartsWith(HandlerLine, "//") Then //Skipping the commented string
			Continue;
		EndIf;
		
		GetHandlerStringAlgorithms(HandlerLine, HandlerAlgorithms);
		
	EndDo;
	
	Return HandlerAlgorithms;
EndFunction 

// Gets the prefix string to output nested algorithm script.
//
// Parameters:
//  HandlerLine - String - a source string where the call offset value will be retrieved from.
//                      
//  PrefixString    - String - the initial offset.
// Returns:
//  PrefixStringForInlineCode - String - algorithm script total offset.
// 
Function GetInlineAlgorithmPrefix(HandlerLine, PrefixString)
	
	HandlerLine = Upper(HandlerLine);

	TemplateExecutePositionNumber = StrFind(HandlerLine, "EXECUTE");

	PrefixStringForInlineCode = PrefixString + Left(HandlerLine, TemplateExecutePositionNumber - 1) + Chars.Tab;
	
	// If the handler line contained an algorithm call, clearing the handler line.
	HandlerLine = "";
	
	Return PrefixStringForInlineCode;
EndFunction

#EndRegion

#Region FunctionsForGenerationUniqueNameOfEventHandlers

// Generates PCR or PGCR handler interface, that is a unique name of the procedure with parameters of the corresponding handler).
//
// Parameters:
//  OCR            - ValueTableRow - contains the object conversion rule.
//  PGCR           - ValueTableRow - contains the property group conversion rule.
//  Rule        - ValueTableRow - contains the object property conversion rule.
//  HandlerName - String - an event handler name.
//
// Returns:
//  String - a handler interface.
//
Function GetPCRHandlerInterface(OCR, PGCR, Rule, HandlerName)
	
	NamePrefix = ?(Rule.IsGroup, "PGCR", "PCR");
	AreaName   = NamePrefix + "_" + HandlerName;
	
	OwnerName = "_" + TrimAll(OCR.Name);
	
	ParentName  = "";
	
	If PGCR <> Undefined Then
		
		If Not IsBlankString(PGCR.DestinationKind) Then 
			
			ParentName = "_" + TrimAll(PGCR.Destination);	
			
		EndIf; 
		
	EndIf; 
	
	DestinationName = "_" + TrimAll(Rule.Destination);
	DestinationKind = "_" + TrimAll(Rule.DestinationKind);
	
	PropertyCode = TrimAll(Rule.Name);
	
	FullHandlerName = AreaName + OwnerName + ParentName + DestinationName + DestinationKind + PropertyCode;
	
	Return FullHandlerName + "(" + GetHandlerParameters(AreaName) + ")";
EndFunction 

// Generates an OCR, DER, or DCR handler interface, that is a unique name of the procedure with the parameters of the corresponding handler.
//
// Parameters:
//  Rule            - ValueTableRow - an arbotrary value collection (OCR, DER, and DCR):
//    * Name - String - a rule name.
//  HandlerPrefix - String - possible values are: OCR, DER, DCR.
//  HandlerName     - String - the event handler name  for this rules.
//
// Returns:
//  String - handler interface.
// 
Function GetHandlerInterface(Rule, HandlerPrefix, HandlerName)
	
	AreaName = HandlerPrefix + "_" + HandlerName;
	
	RuleName = "_" + TrimAll(Rule.Name);
	
	FullHandlerName = AreaName + RuleName;
	
	Return FullHandlerName + "(" + GetHandlerParameters(AreaName) + ")";
EndFunction 

// Generates the interface of the global conversion handler (Generates a unique name of the 
// procedure with parameters of the corresponding handler).
//
// Parameters:
//  HandlerName - String - a conversion event handler name.
//
// Returns:
//  String - handler interface.
// 
Function GetConversionHandlerInterface(HandlerName)
	
	AreaName = "Conversion_" + HandlerName;
	
	FullHandlerName = AreaName;
	
	Return FullHandlerName + "(" + GetHandlerParameters(AreaName) + ")";
EndFunction 

// Generates procedure interface (constructor or destructor) for an external data processor.
//
// Parameters:
//  ProcedureName - String - a name of procedure.
//
// Returns:
//  String - procedure interface.
// 
Function GetExternalDataProcessorProcedureInterface(ProcedureName)
	
	AreaName = "DataProcessor_" + ProcedureName;
	
	FullHandlerName = ProcedureName;
	
	Return FullHandlerName + "(" + GetHandlerParameters(AreaName) + ")";
EndFunction 

// Generates an algorithm interface for an external data processor.
// Getting the same parameters by default for all algorithms.
//
// Parameters:
//  AlgorithmName - String - an algorithm name.
//
// Returns:
//  String - algorithm interface.
// 
Function GetAlgorithmInterface(AlgorithmName)
	
	FullHandlerName = "Algoritm_" + AlgorithmName;
	
	AreaName = "Algorithm_ByDefault";
	
	Return FullHandlerName + "(" + GetHandlerParameters(AreaName) + ")";
EndFunction

Function GetHandlerCallString(Rule, HandlerName)
	
	Return "EventHandlersExternalDataProcessor." + Rule["HandlerInterface" + HandlerName] + ";";
	
EndFunction

Function GetTextByAreaWithoutAreaTitle(Area)
	
	AreaText = Area.GetText();
	
	If StrFind(AreaText, "#Region") > 0 Then
	
		FirstLinefeed = StrFind(AreaText, Chars.LF);
		
		AreaText = Mid(AreaText, FirstLinefeed + 1);
		
	EndIf;
	
	Return AreaText;
	
EndFunction

Function GetHandlerParameters(AreaName)
	
	NewLineString = Chars.LF + "                                           ";
	
	HandlerParameters = "";
	
	TotalString = "";
	
	Area = mHandlerParameterTemplate.GetArea(AreaName);
	
	ParametersArea = Area.Areas[AreaName];
	
	For RowNumber = ParametersArea.Top To ParametersArea.Bottom Do
		
		CurrentArea = Area.GetArea(RowNumber, 2, RowNumber, 2);
		
		Parameter = TrimAll(CurrentArea.CurrentArea.Text);
		
		If Not IsBlankString(Parameter) Then
			
			HandlerParameters = HandlerParameters + Parameter + ", ";
			
			TotalString = TotalString + Parameter;
			
		EndIf; 
		
		If StrLen(TotalString) > 50 Then
			
			TotalString = "";
			
			HandlerParameters = HandlerParameters + NewLineString;
			
		EndIf; 
		
	EndDo;
	
	HandlerParameters = TrimAll(HandlerParameters);
	
	// Removing the last character "," and returning a row.
	
	Return Mid(HandlerParameters, 1, StrLen(HandlerParameters) - 1); 
EndFunction

#EndRegion

#Region GeneratingHandlerCallInterfacesInExchangeRulesProcedures

// Supplements the data clearing rules value collection with the handler interfaces.
//
// Parameters:
//  DCRTable   - ValueTree - a data clearing rules.
//  TreeRows - ValueTreeRowCollection - a data clearing rules of this value tree level.
//
Procedure SupplementDataClearingRulesWithHandlerInterfaces(DCRTable, TreeRows)
	
	For Each Rule In TreeRows Do
		
		If Rule.IsGroup Then
			
			SupplementDataClearingRulesWithHandlerInterfaces(DCRTable, Rule.Rows); 
			
		Else
			
			For Each Item In HandlersNames.DCR Do
				
				AddHandlerInterface(DCRTable, Rule, "DCR", Item.Key);
				
			EndDo; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure  

// Supplements the data export rules value collection with the handler interfaces.
//
// Parameters:
//  DERTable   - ValueTree - a data export rules.
//  TreeRows - ValueTreeRowCollection - a data export rules of this value tree level.
//
Procedure SupplementDataExportRulesWithHandlerInterfaces(DERTable, TreeRows) 
	
	For Each Rule In TreeRows Do
		
		If Rule.IsFolder Then
			
			SupplementDataExportRulesWithHandlerInterfaces(DERTable, Rule.Rows); 
			
		Else
			
			For Each Item In HandlersNames.DER Do
				
				AddHandlerInterface(DERTable, Rule, "DER", Item.Key);
				
			EndDo; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure  

// Supplements the conversion structure with the handler interfaces.
//
// Parameters:
//  ConversionStructure - Structure - the conversion rules and global handlers.
//  
Procedure SupplementConversionRulesWithHandlerInterfaces(ConversionStructure) 
	
	For Each Item In HandlersNames.Conversion Do
		
		AddConversionHandlerInterface(ConversionStructure, Item.Key);
		
	EndDo; 
	
EndProcedure  

// Supplements the object conversion rules value collection with the handler interfaces.
//
// Parameters:
//  OCRTable - see ConversionRulesCollection
//  
Procedure SupplementObjectConversionRulesWithHandlerInterfaces(OCRTable)

	For Each OCR In OCRTable Do
		
		For Each Item In HandlersNames.OCR Do
			
			AddOCRHandlerInterface(OCRTable, OCR, Item.Key);
			
		EndDo; 
		
		// Adding interfaces for PCR.
		SupplementWithPCRHandlersInterfaces(OCR, OCR.SearchProperties);
		SupplementWithPCRHandlersInterfaces(OCR, OCR.Properties);
		
	EndDo; 
	
EndProcedure

// Supplements the object property conversion rules value collection with handler interfaces.
//
// Parameters:
//  OCR - ValueTableRow    - the object conversion rule.
//  ObjectPropertyConversionRules - ValueTable - property conversion rules or rule groups of an object from the OCR rule.
//  PGCR - ValueTableRow   - the property group conversion rule.
//
Procedure SupplementWithPCRHandlersInterfaces(OCR, ObjectPropertyConversionRules, PGCR = Undefined)
	
	For Each PCR In ObjectPropertyConversionRules Do
		
		If PCR.IsFolder Then // PGCR
			
			For Each Item In HandlersNames.PGCR Do
				
				AddPCRHandlerInterface(ObjectPropertyConversionRules, OCR, PGCR, PCR, Item.Key);
				
			EndDo; 

			SupplementWithPCRHandlersInterfaces(OCR, PCR.GroupRules, PCR);
			
		Else
			
			For Each Item In HandlersNames.PCR Do
				
				AddPCRHandlerInterface(ObjectPropertyConversionRules, OCR, PGCR, PCR, Item.Key);
				
			EndDo; 
			
		EndIf; 
		
	EndDo; 
	
EndProcedure

Procedure AddHandlerInterface(Table, Rule, HandlerPrefix, HandlerName) 
	
	If IsBlankString(Rule[HandlerName]) Then
		Return;
	EndIf;
	
	FieldName = "HandlerInterface" + HandlerName;
	
	AddMissingColumns(Table.Columns, FieldName);
		
	Rule[FieldName] = GetHandlerInterface(Rule, HandlerPrefix, HandlerName);
	
EndProcedure

Procedure AddOCRHandlerInterface(Table, Rule, HandlerName) 
	
	If Not Rule["HasHandler" + HandlerName] Then
		Return;
	EndIf; 
	
	FieldName = "HandlerInterface" + HandlerName;
	
	AddMissingColumns(Table.Columns, FieldName);
	
	Rule[FieldName] = GetHandlerInterface(Rule, "OCR", HandlerName);
  
EndProcedure

Procedure AddPCRHandlerInterface(Table, OCR, PGCR, PCR, HandlerName) 
	
	If Not PCR["HasHandler" + HandlerName] Then
		Return;
	EndIf; 
	
	FieldName = "HandlerInterface" + HandlerName;
	
	AddMissingColumns(Table.Columns, FieldName);
	
	PCR[FieldName] = GetPCRHandlerInterface(OCR, PGCR, PCR, HandlerName);
	
EndProcedure

Procedure AddConversionHandlerInterface(ConversionStructure, HandlerName)
	
	HandlerAlgorithm = "";
	
	If ConversionStructure.Property(HandlerName, HandlerAlgorithm) AND Not IsBlankString(HandlerAlgorithm) Then
		
		FieldName = "HandlerInterface" + HandlerName;
		
		ConversionStructure.Insert(FieldName);
		
		ConversionStructure[FieldName] = GetConversionHandlerInterface(HandlerName); 
		
	EndIf;
	
EndProcedure  

#EndRegion

#Region ExchangeRulesOperationProcedures

Function GetPlatformByDestinationPlatformVersion(PlatformVersion)
	
	If StrFind(PlatformVersion, "8.") > 0 Then
		
		Return "V8";
		
	Else
		
		Return "V7";
		
	EndIf;	
	
EndFunction

// Restores rules from the internal format.
//
// Parameters:
// 
Procedure RestoreRulesFromInternalFormat() Export

	If SavedSettings = Undefined Then
		Return;
	EndIf;

	RulesStructure = SavedSettings.Get(); // see RulesStructureDetails

	ExportRulesTable      = RulesStructure.ExportRulesTable;
	ConversionRulesTable   = RulesStructure.ConversionRulesTable;
	Algorithms                  = RulesStructure.Algorithms;
	QueriesToRestore   = RulesStructure.Queries;
	Conversion                = RulesStructure.Conversion;
	mXMLRules                = RulesStructure.mXMLRules;
	ParametersSettingsTable = RulesStructure.ParametersSettingsTable;
	Parameters                  = RulesStructure.Parameters;

	SupplementInternalTablesWithColumns();
	
	RulesStructure.Property("DestinationPlatformVersion", DestinationPlatformVersion);
	
	DestinationPlatform = GetPlatformByDestinationPlatformVersion(DestinationPlatformVersion);
		
	HasBeforeExportObjectGlobalHandler    = Not IsBlankString(Conversion.BeforeExportObject);
	HasAfterExportObjectGlobalHandler     = Not IsBlankString(Conversion.AfterExportObject);
	HasBeforeImportObjectGlobalHandler    = Not IsBlankString(Conversion.BeforeImportObject);
	HasAfterImportObjectGlobalHandler     = Not IsBlankString(Conversion.AfterImportObject);
	HasBeforeConvertObjectGlobalHandler = Not IsBlankString(Conversion.BeforeConvertObject);

	// Restoring queries
	Queries.Clear();
	For Each StructureItem In QueriesToRestore Do
		Query = New Query(StructureItem.Value);
		Queries.Insert(StructureItem.Key, Query);
	EndDo;

	InitManagersAndMessages();
	
	Rules.Clear();
	ClearManagersOCR();
	
	If ExchangeMode = "DataExported" Then
	
		For Each TableRow In ConversionRulesCollection() Do
			Rules.Insert(TableRow.Name, TableRow);

			Source = TableRow.Source;

			If Source <> Undefined Then

				Try
					If TypeOf(Source) = deStringType Then
						Managers[Type(Source)].OCR = TableRow;
					Else
						Managers[Source].OCR = TableRow;
					EndIf;
				Except
					WriteErrorInfoToLog(11, ErrorDescription(), String(Source));
				EndTry;

			EndIf;

		EndDo;

	EndIf;

EndProcedure

// Initializes parameters by default values from the exchange rules.
//
// Parameters:
//  No.
// 
Procedure InitializeInitialParameterValues() Export
	
	For Each CurParameter In Parameters Do
		
		SetParameterValueInTable(CurParameter.Key, CurParameter.Value);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ClearingRuleProcessing

Procedure ExecuteObjectDeletion(Object, Properties, DeleteDirectly)
	
	TypeName = Properties.TypeName;
	
	If TypeName = "InformationRegister" Then
		
		Object.Delete();
		
	Else
		
		If (TypeName = "Catalog" Or TypeName = "ChartOfCharacteristicTypes" Or TypeName = "ChartOfAccounts" Or TypeName = "ChartOfCalculationTypes")
			And Object.Predefined Then
			
			Return;
			
		EndIf;
		
		If DeleteDirectly Then
			
			Object.Delete();
			
		Else
			
			SetObjectDeletionMark(Object, True, Properties.TypeName);
			
		EndIf;
			
	EndIf;	
	
EndProcedure

// Clears data according to the specified rule.
//
// Parameters:
//  Rule - data clearing rule reference.
//     * Name - String - a rule name.
// 
Procedure ClearDataByRule(Rule)
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	// BeforeProcess handler

	Cancel			= False;
	DataSelection	= Undefined;

	OutgoingData	= Undefined;


	// BeforeProcessClearingRule handler
	If Not IsBlankString(Rule.BeforeProcess) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "BeforeProcess"));
				
			Else
				
				Execute(Rule.BeforeProcess);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(27, ErrorDescription(), Rule.Name, "", "BeforeProcessClearingRule");
						
		EndTry;
		
		If Cancel Then
		
			Return;
			
		EndIf;
		
	EndIf;
	
	// Standard selection
	
	Properties = Managers[Rule.SelectionObject];
	
	If Rule.DataFilterMethod = "StandardSelection" Then
		
		TypeName = Properties.TypeName;
		
		If TypeName = "AccountingRegister" Or TypeName = "Constants" Then
			
			Return;
			
		EndIf;
		
		AllFieldsRequired  = Not IsBlankString(Rule.BeforeDelete);
		
		Selection = GetSelectionForDataClearingExport(Properties, TypeName, True, Rule.Directly, AllFieldsRequired);
		
		While Selection.Next() Do
			
			If TypeName =  "InformationRegister" Then
				
				RecordManager = Properties.Manager.CreateRecordManager(); 
				FillPropertyValues(RecordManager, Selection);
									
				SelectionObjectDeletion(RecordManager, Rule, Properties, OutgoingData);
					
			Else
					
				SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, OutgoingData);
					
			EndIf;
				
		EndDo;

	ElsIf Rule.DataFilterMethod = "ArbitraryAlgorithm" Then
		
		If DataSelection <> Undefined Then
			
			Selection = GetExportWithArbitraryAlgorithmSelection(DataSelection);
			
			If Selection <> Undefined Then
				
				While Selection.Next() Do
										
					If TypeName =  "InformationRegister" Then
				
						RecordManager = Properties.Manager.CreateRecordManager(); 
						FillPropertyValues(RecordManager, Selection);
											
						SelectionObjectDeletion(RecordManager, Rule, Properties, OutgoingData);				
											
					Else
							
						SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, OutgoingData);
							
					EndIf;					
					
				EndDo;	
				
			Else
				
				For Each Object In DataSelection Do
					
					SelectionObjectDeletion(Object.GetObject(), Rule, Properties, OutgoingData);
					
				EndDo;
				
			EndIf;
			
		EndIf; 
			
	EndIf; 

	
	// AfterProcessClearingRule handler

	If Not IsBlankString(Rule.AfterProcess) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "AfterProcess"));
				
			Else
				
				Execute(Rule.AfterProcess);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(28, ErrorDescription(), Rule.Name, "", "AfterProcessClearingRule");
									
		EndTry;
		
	EndIf;
	
EndProcedure

// Iterates the data clearing rules tree and executes clearing.
//
// Parameters:
//  Rows - value tree rows collection.
// 
Procedure ProcessClearingRules(Rows)
	
	For each ClearingRule In Rows Do
		
		If ClearingRule.Enable = 0 Then
			
			Continue;
			
		EndIf; 

		If ClearingRule.IsGroup Then
			
			ProcessClearingRules(ClearingRule.Rows);
			Continue;
			
		EndIf;
		
		ClearDataByRule(ClearingRule);
		
	EndDo; 
	
EndProcedure

#EndRegion

#Region DataImportProcedures

// Sets the Load parameter value for the DataExchange object property.
//
// Parameters:
//  Object - object whose property will be set.
//  Value - a value of the Import property being set.
// 
Procedure SetDataExchangeLoad(Object, Value = True) Export
	
	If Not ImportDataInExchangeMode Then
		Return;
	EndIf;

	If HasObjectAttributeOrProperty(Object, "DataExchange") Then
		StructureToFill = New Structure("Load", Value);
		FillPropertyValues(Object.DataExchange, StructureToFill);
	EndIf;

EndProcedure

Function SetNewObjectRef(Object, Manager, SearchProperties)
	
	UUID = SearchProperties["{UUID}"];
	
	If UUID <> Undefined Then
		
		NewRef = Manager.GetRef(New UUID(UUID));
		
		Object.SetNewObjectRef(NewRef);
		
		SearchProperties.Delete("{UUID}");
		
	Else
		
		NewRef = Undefined;
		
	EndIf;
	
	Return NewRef;
	
EndFunction

// Searches for the object by number in the imported objects list.
//
// Parameters:
//  SN - Number - a number of the object to be searched in the exchange file.
//  MainObjectSearchMode - Boolean - if False and a dummy ref was imported, an object ref will be return.  
//
// Returns:
//   Found object reference. If object is not found, Undefined is returned.
// 
Function FindObjectByNumber(SN, MainObjectSearchMode = False)

	If SN = 0 Then
		Return Undefined;
	EndIf;
	
	ResultStructure = ImportedObjects[SN];
	
	If ResultStructure = Undefined Then
		Return Undefined;
	EndIf;
	
	If MainObjectSearchMode AND ResultStructure.DummyRef Then
		Return Undefined;
	Else
		Return ResultStructure.ObjectRef;
	EndIf; 

EndFunction

Function FindObjectByGlobalNumber(SN, MainObjectSearchMode = False)

	ResultStructure = ImportedGlobalObjects[SN];
	
	If ResultStructure = Undefined Then
		Return Undefined;
	EndIf;
	
	If MainObjectSearchMode And ResultStructure.DummyRef Then
		Return Undefined;
	Else
		Return ResultStructure.ObjectRef;
	EndIf;
	
EndFunction

Procedure WriteObjectToIB(Object, Type)
		
	Try
		
		SetDataExchangeLoad(Object);
		Object.Write();
		
	Except
		
		ErrorMessageString = WriteErrorInfoToLog(26, ErrorDescription(), Object, Type);
		
		If Not DebugModeFlag Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

// Creates a new object of the specified type, sets attributes that are specified in the 
// SearchProperties structure.
//
// Parameters:
//  Type - Type - type of the object to be created.
//  SearchProperties - Map - contains attributes of a new object to be set.
//  Object - CatalogObject, DocumentObject, etc - a variable to return a created object.
//  WriteObjectImmediatelyAfterCreation - Boolean - if True, the created object will be written immediately after creation.
//  RegisterRecordSet - InformationRegisterRecordSet - a variable to return the record set.
//  NewRef - CatalogRef, DocumentRef, etc - a varialbe to return a new object reference.
//  SN - Number - a number of a created object into the non-written objects stack.
//  GSN - Number - a global number of a created object into the non-written objects stack.
//  ObjectParameters - Structure - an object parameters for a non-written objects stack.
//  SetAllObjectSearchProperties - Boolean - if True, all of the object search attributes will be set. 
//
// Returns:
//  New infobase object.
// 
Function CreateNewObject(Type, SearchProperties, Object = Undefined, 
	WriteObjectImmediatelyAfterCreation = True, RegisterRecordSet = Undefined,
	NewRef = Undefined, SN = 0, GSN = 0, ObjectParameters = Undefined,
	SetAllObjectSearchProperties = True)

	MDProperties      = Managers[Type];
	TypeName         = MDProperties.TypeName;
	Manager        = MDProperties.Manager; // CatalogManager, DocumentManager, InformationRegisterManager, etc.

	If TypeName = "Catalog" Or TypeName = "ChartOfCharacteristicTypes" Then
		
		IsFolder = SearchProperties["IsFolder"];
		
		If IsFolder = True Then
			
			Object = Manager.CreateFolder();
						
		Else
			
			Object = Manager.CreateItem();
			
		EndIf;

	ElsIf TypeName = "Document" Then
		
		Object = Manager.CreateDocument();
				
	ElsIf TypeName = "ChartOfAccounts" Then
		
		Object = Manager.CreateAccount();
				
	ElsIf TypeName = "ChartOfCalculationTypes" Then
		
		Object = Manager.CreateCalculationType();

	ElsIf TypeName = "InformationRegister" Then
		
		If WriteRegistersAsRecordSets Then
			
			RegisterRecordSet = Manager.CreateRecordSet();
			Object = RegisterRecordSet.Add();
			
		Else
			
			Object = Manager.CreateRecordManager();
						
		EndIf;
		
		Return Object;
		
	ElsIf TypeName = "ExchangePlan" Then
		
		Object = Manager.CreateNode();
				
	ElsIf TypeName = "Task" Then
		
		Object = Manager.CreateTask();
		
	ElsIf TypeName = "BusinessProcess" Then
		
		Object = Manager.CreateBusinessProcess();	
		
	ElsIf TypeName = "Enum" Then
		
		Object = MDProperties.EmptyRef;	
		Return Object;
		
	ElsIf TypeName = "BusinessProcessRoutePoint" Then
		
		Return Undefined;
				
	EndIf;

	NewRef = SetNewObjectRef(Object, Manager, SearchProperties);
	
	If SetAllObjectSearchProperties Then
		SetObjectSearchAttributes(Object, SearchProperties, Undefined, False, False);
	EndIf;
	
	// Checks
	If TypeName = "Document" Or TypeName = "Task" Or TypeName = "BusinessProcess" Then
		
		If Not ValueIsFilled(Object.Date) Then
			
			Object.Date = CurrentSessionDate();
			
		EndIf;
		
	EndIf;

	If WriteObjectImmediatelyAfterCreation Then
		
		If NOT ImportReferencedObjectsWithoutDeletionMark Then
			Object.DeletionMark = True;
		EndIf;
		
		If GSN <> 0 Or Not OptimizedObjectsWriting Then
		
			WriteObjectToIB(Object, Type);
			
		Else
			
			// The object is not written immediately. Instead of this, the object is stored to the stack of 
			// objects to be written. Both the new reference and the object are returned, although the object is 
			// not written.
			If NewRef = Undefined Then
				
				// Generating the new reference.
				NewUUID = New UUID;
				NewRef = Manager.GetRef(NewUUID);
				Object.SetNewObjectRef(NewRef);
				
			EndIf;			
			
			SupplementNotWrittenObjectsStack(SN, GSN, Object, NewRef, Type, ObjectParameters);
			
			Return NewRef;
			
		EndIf;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	Return Object.Ref;
	
EndFunction

// Reads the object property node from the file and sets the property value.
//
// Parameters:
//  Type - property value type.
//  OCRName   - an object convetation rule name.
//
// Returns:
//  Property value
// 
Function ReadProperty(Type, OCRName = "")
	
	Value = Undefined;
	PropertyExistence = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Value" Then
			
			SearchByProperty = deAttribute(ExchangeFile, deStringType, "Property");
			Value         = deElementValue(ExchangeFile, Type, SearchByProperty, RemoveTrailingSpaces);
			PropertyExistence = True;
			
		ElsIf NodeName = "Ref" Then
			
			Value       = FindObjectByRef(Type, OCRName);
			PropertyExistence = True;
			
		ElsIf NodeName = "Sn" Then
			
			deSkip(ExchangeFile);
			
		ElsIf NodeName = "Gsn" Then
			
			ExchangeFile.Read();
			GSN = Number(ExchangeFile.Value);
			If GSN <> 0 Then
				Value  = FindObjectByGlobalNumber(GSN);
				PropertyExistence = True;
			EndIf;
			
			ExchangeFile.Read();

		ElsIf (NodeName = "Property" Or NodeName = "ParameterValue") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			If Not PropertyExistence And ValueIsFilled(Type) Then
				
				// If there is no data, empty value.
				Value = deGetEmptyValue(Type);
				
			EndIf;
			
			Break;
			
		ElsIf NodeName = "Expression" Then
			
			Expression = deElementValue(ExchangeFile, deStringType, , False);
			Value  = EvalExpression(Expression);
			
			PropertyExistence = True;
			
		ElsIf NodeName = "Empty" Then
			
			Value = deGetEmptyValue(Type);
			PropertyExistence = True;		
			
		Else
			
			WriteToExecutionLog(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Value;	
	
EndFunction

Function SetObjectSearchAttributes(FoundObject, SearchProperties, SearchPropertiesDontReplace, 
	CompareWithCurrentAttributes = True, DontReplacePropertiesNotToChange = True)

	ObjectAttributesChanged = False;
				
	For Each Property In SearchProperties Do
					
		Name      = Property.Key;
		Value = Property.Value;
		
		If DontReplacePropertiesNotToChange And SearchPropertiesDontReplace[Name] <> Undefined Then
			
			Continue;
			
		EndIf;
					
		If Name = "IsFolder" Or Name = "{UUID}" Or Name = "{PredefinedItemName}" Then
						
			Continue;
						
		ElsIf Name = "DeletionMark" Then
						
			If Not CompareWithCurrentAttributes Or FoundObject.DeletionMark <> Value Then
							
				FoundObject.DeletionMark = Value;
				ObjectAttributesChanged = True;
							
			EndIf;

		Else
				
			// Setting attributes that are different.
			If FoundObject[Name] <> NULL Then
			
				If Not CompareWithCurrentAttributes Or FoundObject[Name] <> Value Then
						
					FoundObject[Name] = Value;
					ObjectAttributesChanged = True;
						
				EndIf;
				
			EndIf;
				
		EndIf;
					
	EndDo;
	
	Return ObjectAttributesChanged;
	
EndFunction

Function FindCreateObjectByProperty(PropertyStructure, ObjectType, SearchProperties, SearchPropertiesDontReplace,
	ObjectTypeName, SearchProperty, SearchPropertyValue, ObjectFound,
	CreateNewItemIfNotFound, FoundCreatedObject,
	MainObjectSearchMode, ObjectPropertiesModified, SN, GSN,
	ObjectParameters, NewUUIDRef = Undefined)

	IsEnum = PropertyStructure.TypeName = "Enum";
	
	If IsEnum Then
		
		SearchString = "";
		
	Else
		
		SearchString = PropertyStructure.SearchString;
		
	EndIf;

	If MainObjectSearchMode Or IsBlankString(SearchString) Then
		SearchByUUIDQueryString = "";
	EndIf;

	Object = FindObjectByProperty(PropertyStructure.Manager, SearchProperty, SearchPropertyValue,
		FoundCreatedObject, , , SearchByUUIDQueryString);
		
	ObjectFound = Not (Object = Undefined Or Object.IsEmpty());
		
	If Not ObjectFound Then
		If CreateNewItemIfNotFound Then
		
			Object = CreateNewObject(ObjectType, SearchProperties, FoundCreatedObject, 
				Not MainObjectSearchMode,,NewUUIDRef, SN, GSN, ObjectParameters);
				
			ObjectPropertiesModified = True;
		EndIf;
		Return Object;
	
	EndIf;

	If IsEnum Then
		Return Object;
	EndIf;			
	
	If MainObjectSearchMode Then
		
		If FoundCreatedObject = Undefined Then
			FoundCreatedObject = Object.GetObject();
		EndIf;
			
		ObjectPropertiesModified = SetObjectSearchAttributes(FoundCreatedObject, SearchProperties, SearchPropertiesDontReplace);
				
	EndIf;
		
	Return Object;
	
EndFunction

Function GetPropertyType()
	
	PropertyTypeString = deAttribute(ExchangeFile, deStringType, "Type");
	If IsBlankString(PropertyTypeString) Then
		Return Undefined;
	EndIf;
	
	Return Type(PropertyTypeString);
	
EndFunction

Function GetPropertyTypeByAdditionalData(TypesInformation, PropertyName)
	
	PropertyType = GetPropertyType();
				
	If PropertyType = Undefined And TypesInformation <> Undefined Then
		
		PropertyType = TypesInformation[PropertyName];
		
	EndIf;
	
	Return PropertyType;
	
EndFunction

Procedure ReadSearchPropertiesFromFile(SearchProperties, SearchPropertiesDontReplace, TypesInformation, 
	SearchByEqualDate = False, ObjectParameters = Undefined)
	
	SearchByEqualDate = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Property"
			Or NodeName = "ParameterValue" Then
					
			IsParameter = (NodeName = "ParameterValue");
			
			Name = deAttribute(ExchangeFile, deStringType, "Name");
			
			If Name = "{UUID}" 
				Or Name = "{PredefinedItemName}" Then
				
				PropertyType = deStringType;
				
			Else
			
				PropertyType = GetPropertyTypeByAdditionalData(TypesInformation, Name);
			
			EndIf;

			DontReplaceProperty = deAttribute(ExchangeFile, deBooleanType, "DoNotReplace");
			SearchByEqualDate = SearchByEqualDate Or deAttribute(ExchangeFile, deBooleanType, "SearchByEqualDate");
			//
			OCRName = deAttribute(ExchangeFile, deStringType, "OCRName");
			
			PropertyValue = ReadProperty(PropertyType, OCRName);
			
			If (Name = "IsFolder") AND (PropertyValue <> True) Then
				
				PropertyValue = False;
												
			EndIf;
			
			If IsParameter Then
				AddParameterIfNecessary(ObjectParameters, Name, PropertyValue);

			Else
			
				SearchProperties[Name] = PropertyValue;
				
				If DontReplaceProperty Then
					
					SearchPropertiesDontReplace[Name] = True;
					
				EndIf;
				
			EndIf;
			
		ElsIf (NodeName = "Ref") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionLog(9);
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Function UnlimitedLengthField(TypeManager, ParameterName)
	
	LongStrings = Undefined;
	If Not TypeManager.Property("LongStrings", LongStrings) Then
		
		LongStrings = New Map;
		For Each Attribute In TypeManager.MDObject.Attributes Do

			If Attribute.Type.ContainsType(deStringType) And (Attribute.Type.StringQualifiers.Length = 0) Then
				
				LongStrings.Insert(Attribute.Name, Attribute.Name);	
				
			EndIf;
			
		EndDo;
		
		TypeManager.Insert("LongStrings", LongStrings);
		
	EndIf;
	
	Return (LongStrings[ParameterName] <> Undefined);
		
EndFunction

Function IsUnlimitedLengthParameter(TypeManager, ParameterValue, ParameterName)
	
	Try
			
		If TypeOf(ParameterValue) = deStringType Then
			UnlimitedLengthString = UnlimitedLengthField(TypeManager, ParameterName);
		Else
			UnlimitedLengthString = False;
		EndIf;		
												
	Except
				
		UnlimitedLengthString = False;
				
	EndTry;
	
	Return UnlimitedLengthString;	
	
EndFunction

Function FindItemUsingRequest(PropertyStructure, SearchProperties, ObjectType = Undefined, 
	TypeManager = Undefined, RealSearchPropertiesCount = Undefined)
	
	SearchPropertiesCount = ?(RealSearchPropertiesCount = Undefined, SearchProperties.Count(), RealSearchPropertiesCount);

	If SearchPropertiesCount = 0 And PropertyStructure.TypeName = "Enum" Then
		
		Return PropertyStructure.EmptyRef;
		
	EndIf;

	QueryText       = PropertyStructure.SearchString;
	
	If IsBlankString(QueryText) Then
		Return PropertyStructure.EmptyRef;
	EndIf;
	
	SearchQuery       = New Query();
	PropertyUsedInSearchCount = 0;

	For each Property In SearchProperties Do
				
		ParameterName      = Property.Key;
		
		// The following parameters cannot be search fields.
		If ParameterName = "{UUID}" Or ParameterName = "{PredefinedItemName}" Then
						
			Continue;
						
		EndIf;

		ParameterValue = Property.Value;
		SearchQuery.SetParameter(ParameterName, ParameterValue);
				
		Try
			
			UnlimitedLengthString = IsUnlimitedLengthParameter(PropertyStructure, ParameterValue, ParameterName);		
													
		Except
					
			UnlimitedLengthString = False;
					
		EndTry;
		
		PropertyUsedInSearchCount = PropertyUsedInSearchCount + 1;
				
		If UnlimitedLengthString Then
					
			QueryText = QueryText + ?(PropertyUsedInSearchCount > 1, " AND ", "") + ParameterName + " LIKE &" + ParameterName;
					
		Else
					
			QueryText = QueryText + ?(PropertyUsedInSearchCount > 1, " AND ", "") + ParameterName + " = &" + ParameterName;
					
		EndIf;
								
	EndDo;

	If PropertyUsedInSearchCount = 0 Then
		Return Undefined;
	EndIf;
	
	SearchQuery.Text = QueryText;
	Result = SearchQuery.Execute();
			
	If Result.IsEmpty() Then
		
		Return Undefined;
								
	Else
		
		// Returning the first found object.
		Selection = Result.Select();
		Selection.Next();
		ObjectRef = Selection.Ref;
				
	EndIf;
	
	Return ObjectRef;
	
EndFunction

Function GetAdditionalSearchBySearchFieldsUsageByObjectType(RefTypeString)
	
	MapValue = mExtendedSearchParameterMap.Get(RefTypeString);
	
	If MapValue <> Undefined Then
		Return MapValue;
	EndIf;
	
	Try
	
		For Each Item In Rules Do
			
			If Item.Value.Destination = RefTypeString Then
				
				If Item.Value.SynchronizeByID = True Then
					
					ContinueSearch = (Item.Value.SearchBySearchFieldsIfNotFoundByID = True);
					mExtendedSearchParameterMap.Insert(RefTypeString, ContinueSearch);
					
					Return ContinueSearch;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		mExtendedSearchParameterMap.Insert(RefTypeString, False);
		Return False;
	
	Except
		
		mExtendedSearchParameterMap.Insert(RefTypeString, False);
		Return False;
	
    EndTry;
	
EndFunction

// Determines the object conversion rule (OCR) by destination object type.
//
// Parameters:
//  RefTypeString - String - an object type as a string, for example, "CatalogRef.Products".
// 
// Returns:
//  MapValue - an object conversion rule.
// 
Function GetConversionRuleWithSearchAlgorithmByDestinationObjectType(RefTypeString)
	
	MapValue = mConversionRulesMap.Get(RefTypeString);

	If MapValue <> Undefined Then
		Return MapValue;
	EndIf;
	
	Try
	
		For Each Item In Rules Do
			
			If Item.Value.Destination = RefTypeString Then
				
				If Item.Value.HasSearchFieldSequenceHandler = True Then
					
					Rule = Item.Value;
					
					mConversionRulesMap.Insert(RefTypeString, Rule);
					
					Return Rule;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		mConversionRulesMap.Insert(RefTypeString, Undefined);
		Return Undefined;
	
	Except
		
		mConversionRulesMap.Insert(RefTypeString, Undefined);
		Return Undefined;
	
	EndTry;
	
EndFunction

Function FindObjectRefBySingleProperty(SearchProperties, PropertyStructure)
	
	For Each Property In SearchProperties Do
					
		ParameterName      = Property.Key;
					
		// The following parameters cannot be search fields.
		If ParameterName = "{UUID}" Or ParameterName = "{PredefinedItemName}" Then
						
			Continue;
						
		EndIf;
					
		ParameterValue = Property.Value;
		ObjectRef = FindObjectByProperty(PropertyStructure.Manager, ParameterName, ParameterValue, Undefined, PropertyStructure, SearchProperties);
		
	EndDo;
	
	Return ObjectRef;
	
EndFunction

Function FindDocumentRef(SearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery, SearchByEqualDate)
	
	// Attempting to search for the document by the date and number.
	SearchWithQuery = SearchByEqualDate OR (RealSearchPropertiesCount <> 2);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
					
	DocumentNumber = SearchProperties["Number"];
	DocumentDate  = SearchProperties["Date"];
					
	If (DocumentNumber <> Undefined) AND (DocumentDate <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByNumber(DocumentNumber, DocumentDate);
																		
	Else
						
		// Cannot find by date and number. Search using a query.
		SearchWithQuery = True;
		ObjectRef = Undefined;
						
	EndIf;
	
	Return ObjectRef;
	
EndFunction

Function FindCatalogRef(SearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery)
	
	Owner     = SearchProperties["Owner"];
	Parent     = SearchProperties["Parent"];
	Code          = SearchProperties["Code"];
	Description = SearchProperties["Description"];
				
	Qty          = 0;
				
	If Owner <> Undefined Then
		Qty = 1 + Qty; 
	EndIf;
	If Parent <> Undefined Then	
		Qty = 1 + Qty; 
	EndIf;
	If Code <> Undefined Then 
		Qty = 1 + Qty; 
	EndIf;
	If Description <> Undefined Then
		Qty = 1 + Qty; 
	EndIf;

	SearchWithQuery = (Qty <> RealSearchPropertiesCount);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
					
	If (Code <> Undefined) And (Description = Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByCode(Code, , Parent, Owner);
																		
	ElsIf (Code = Undefined) And (Description <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByDescription(Description, True, Parent, Owner);
											
	Else
						
		SearchWithQuery = True;
		ObjectRef = Undefined;
						
	EndIf;
															
	Return ObjectRef;
	
EndFunction

Function FindCCTRef(SearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery)
	
	Parent     = SearchProperties["Parent"];
	Code          = SearchProperties["Code"];
	Description = SearchProperties["Description"];
	Qty          = 0;
				
	If Parent <> Undefined Then	
		Qty = 1 + Qty 
	EndIf;
	If Code <> Undefined Then 
		Qty = 1 + Qty 
	EndIf;
	If Description <> Undefined Then
		Qty = 1 + Qty 
	EndIf;
				
	SearchWithQuery = (Qty <> RealSearchPropertiesCount);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
					
	If (Code <> Undefined) And (Description = Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByCode(Code, Parent);
												
	ElsIf (Code = Undefined) And (Description <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByDescription(Description, True, Parent);
																	
	Else
						
		SearchWithQuery = True;
		ObjectRef = Undefined;
			
	EndIf;
															
	Return ObjectRef;
	
EndFunction

Function FindExchangePlanRef(SearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery)
	
	Code          = SearchProperties["Code"];
	Description = SearchProperties["Description"];
	Qty          = 0;
				
	If Code <> Undefined Then 
		Qty = 1 + Qty 
	EndIf;
	If Description <> Undefined Then
		Qty = 1 + Qty 
	EndIf;
				
	SearchWithQuery = (Qty <> RealSearchPropertiesCount);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
					
	If (Code <> Undefined) And (Description = Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByCode(Code);
												
	ElsIf (Code = Undefined) And (Description <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByDescription(Description, TRUE);
																	
	Else
						
		SearchWithQuery = True;
		ObjectRef = Undefined;
						
	EndIf;
															
	Return ObjectRef;
	
EndFunction

Function FindTaskRef(SearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery)
	
	Code          = SearchProperties["Number"];
	Description = SearchProperties["Description"];
	Qty          = 0;
				
	If Code <> Undefined Then 
		Qty = 1 + Qty 
	EndIf;
	If Description <> Undefined Then
		Qty = 1 + Qty 
	EndIf;
				
	SearchWithQuery = (Qty <> RealSearchPropertiesCount);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
	If (Code <> Undefined) And (Description = Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByNumber(Code);
												
	ElsIf (Code = Undefined) And (Description <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByDescription(Description, True);
																	
	Else
						
		SearchWithQuery = True;
		ObjectRef = Undefined;
						
	EndIf;
															
	Return ObjectRef;
	
EndFunction

Function FindBusinessProcessRef(SearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery)
	
	Code          = SearchProperties["Number"];
	Qty          = 0;
				
	If Code <> Undefined Then 
		Qty = 1 + Qty 
	EndIf;
								
	SearchWithQuery = (Qty <> RealSearchPropertiesCount);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
					
	If  (Code <> Undefined) Then
						
		ObjectRef = PropertyStructure.Manager.FindByNumber(Code);
												
	Else
						
		SearchWithQuery = True;
		ObjectRef = Undefined;
						
	EndIf;
															
	Return ObjectRef;
	
EndFunction

Procedure AddRefToImportedObjectList(GSNRef, SNRef, ObjectRef, DummyRef = False)
	
	// Remembering the object reference.
	If Not RememberImportedObjects Or ObjectRef = Undefined Then
		
		Return;
		
	EndIf;
	
	RecordStructure = New Structure("ObjectRef, DummyRef", ObjectRef, DummyRef);
	
	// Remembering the object reference.
	If GSNRef <> 0 Then
		
		ImportedGlobalObjects[GSNRef] = RecordStructure;
		
	ElsIf SNRef <> 0 Then
		
		ImportedObjects[SNRef] = RecordStructure;
						
	EndIf;	
	
EndProcedure

Function FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, 
	PropertyStructure, SearchPropertyNameString, SearchByEqualDate)
	
	// Searching by properties that are in the property name string. If this parameter is empty, searching by all available search properties. 
	// If it is empty, then search by all existing search properties.

	SearchWithQuery = False;	
	
	If IsBlankString(SearchPropertyNameString) Then
		
		TemporarySearchProperties = SearchProperties;
		
	Else
		
		ResultingStringForParsing = StrReplace(SearchPropertyNameString, " ", "");
		StringLength = StrLen(ResultingStringForParsing);
		If Mid(ResultingStringForParsing, StringLength, 1) <> "," Then
			
			ResultingStringForParsing = ResultingStringForParsing + ",";
			
		EndIf;
		
		TemporarySearchProperties = New Map;
		For Each PropertyItem In SearchProperties Do
			
			ParameterName = PropertyItem.Key;
			If StrFind(ResultingStringForParsing, ParameterName + ",") > 0 Then
				
				TemporarySearchProperties.Insert(ParameterName, PropertyItem.Value); 	
				
			EndIf;
			
		EndDo;
		
	EndIf;

	UUIDProperty = TemporarySearchProperties["{UUID}"];
	PredefinedNameProperty = TemporarySearchProperties["{PredefinedItemName}"];
	
	RealSearchPropertiesCount = TemporarySearchProperties.Count();
	RealSearchPropertiesCount = RealSearchPropertiesCount - ?(UUIDProperty <> Undefined, 1, 0);
	RealSearchPropertiesCount = RealSearchPropertiesCount - ?(PredefinedNameProperty <> Undefined, 1, 0);
	If RealSearchPropertiesCount = 1 Then
				
		ObjectRef = FindObjectRefBySingleProperty(TemporarySearchProperties, PropertyStructure);
																						
	ElsIf ObjectTypeName = "Document" Then
				
		ObjectRef = FindDocumentRef(TemporarySearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery, SearchByEqualDate);
											
	ElsIf ObjectTypeName = "Catalog" Then
				
		ObjectRef = FindCatalogRef(TemporarySearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery);
								
	ElsIf ObjectTypeName = "ChartOfCharacteristicTypes" Then
				
		ObjectRef = FindCCTRef(TemporarySearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery);
							
	ElsIf ObjectTypeName = "ExchangePlan" Then
				
		ObjectRef = FindExchangePlanRef(TemporarySearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery);
							
	ElsIf ObjectTypeName = "Task" Then
				
		ObjectRef = FindTaskRef(TemporarySearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery);
												
	ElsIf ObjectTypeName = "BusinessProcess" Then
				
		ObjectRef = FindBusinessProcessRef(TemporarySearchProperties, PropertyStructure, RealSearchPropertiesCount, SearchWithQuery);
									
	Else
				
		SearchWithQuery = True;
				
	EndIf;
		
	If SearchWithQuery Then
			
		ObjectRef = FindItemUsingRequest(PropertyStructure, TemporarySearchProperties, ObjectType, , RealSearchPropertiesCount);
				
	EndIf;
	
	Return ObjectRef;
	
EndFunction

Procedure ProcessObjectSearchPropertiesSetup(SetAllObjectSearchProperties, ObjectType, SearchProperties, 
	SearchPropertiesDontReplace, ObjectRef, CreatedObject, WriteNewObjectToInfobase = True, ObjectAttributeChanged = False)
	
	If SetAllObjectSearchProperties <> True Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ObjectRef) Then
		Return;
	EndIf;
	
	If CreatedObject = Undefined Then
		CreatedObject = ObjectRef.GetObject();
	EndIf;
	
	ObjectAttributeChanged = SetObjectSearchAttributes(CreatedObject, SearchProperties, SearchPropertiesDontReplace);
	
	// Rewriting the object if changes were made.
	If ObjectAttributeChanged
		AND WriteNewObjectToInfobase Then
		
		WriteObjectToIB(CreatedObject, ObjectType);
		
	EndIf;
	
EndProcedure

Function ProcessObjectSearchByStructure(ObjectNumber, ObjectType, CreatedObject,
	MainObjectSearchMode, ObjectPropertiesModified, ObjectFound, IsGlobalNumber, ObjectParameters)

	DataStructure = mNotWrittenObjectGlobalStack[ObjectNumber];
	
	If DataStructure <> Undefined Then
		
		ObjectPropertiesModified = True;
		CreatedObject = DataStructure.Object;
		
		If DataStructure.KnownRef = Undefined Then
			
			SetObjectRef(DataStructure);
			
		EndIf;
			
		ObjectRef = DataStructure.KnownRef;
		ObjectParameters = DataStructure.ObjectParameters;
		
		ObjectFound = False;

	Else
		
		CreatedObject = Undefined;
		
		If IsGlobalNumber Then
			ObjectRef = FindObjectByGlobalNumber(ObjectNumber, MainObjectSearchMode);
		Else
			ObjectRef = FindObjectByNumber(ObjectNumber, MainObjectSearchMode);
		EndIf;
		
	EndIf;

	If ObjectRef <> Undefined Then
		
		If MainObjectSearchMode Then
			
			SearchProperties = "";
			SearchPropertiesDontReplace = "";
			ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace, , ObjectParameters);
			
			// Verifying search fields.
			If CreatedObject = Undefined Then
				
				CreatedObject = ObjectRef.GetObject();
				
			EndIf;
			
			ObjectPropertiesModified = SetObjectSearchAttributes(CreatedObject, SearchProperties, SearchPropertiesDontReplace);
			
		Else
			
			deSkip(ExchangeFile);
			
		EndIf;
		
		Return ObjectRef;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace, 
	SearchByEqualDate = False, ObjectParameters = Undefined)
	
	If SearchProperties = "" Then
		SearchProperties = New Map;		
	EndIf;
	
	If SearchPropertiesDontReplace = "" Then
		SearchPropertiesDontReplace = New Map;		
	EndIf;	
	
	TypesInformation = mDataTypeMapForImport[ObjectType];
	ReadSearchPropertiesFromFile(SearchProperties, SearchPropertiesDontReplace, TypesInformation, SearchByEqualDate, ObjectParameters);	
	
EndProcedure

// Searches an object in the infobase and creates a new object, if it is not found.
//
// Parameters:
//  ObjectType - String - a string presentation of type of the object to be found.
//  OCRName - String - an object conversion rule name.
//  SearchProperties - Map - a properties to be used for object searching.
//  SearchPropertiesDontReplace - Map - a properties to be used for object searching that will not be replaced in the found object.
//  ObjectFound - Boolean - if False, object is not found and a new object is created.
//  CreatedObject - CatalogObject, DocumentObject, etc. - an object that created if existing object was not found.
//  DontCreateObjectIfNotFound - Boolean - if True, no object will be created.
//  MainObjectSearchMode - Boolean - if True, object transferred by ref will not be searched in destination base, 
//  	only his UUID will be set in the destination object.
//  ObjectPropertiesModified - Boolean - True, if an object properties was modified.
//  GlobalRefSN - Number - a sequence global number of the object ref.
//  RefSN - Number - a sequence number of the object ref.
//  KnownUUIDRef - CatalogRef, DocumentRef, etc - a previously found reference of the passed UUID.
//  ObjectParameters - Structure - an object parameters. 
//
// Returns:
//  New or found infobase object.
//  
Function FindObjectByRef(ObjectType,
							OCRName = "",
							SearchProperties = "", 
							SearchPropertiesDontReplace = "", 
							ObjectFound = True, 
							CreatedObject = Undefined, 
							DontCreateObjectIfNotFound = Undefined,
							MainObjectSearchMode = False, 
							ObjectPropertiesModified = False,
							GlobalRefSN = 0,
							RefSN = 0,
							KnownUUIDRef = Undefined,
							ObjectParameters = Undefined)

	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	SearchByEqualDate = False;
	ObjectRef = Undefined;
	PropertyStructure = Undefined;
	ObjectTypeName = Undefined;
	DummyObjectRef = False;
	OCR = Undefined;
	SearchAlgorithm = "";

	If RememberImportedObjects Then
		
		// Searching by the global sequence number if it is available in the file.
		GlobalRefSn = deAttribute(ExchangeFile, deNumberType, "Gsn");
		
		If GlobalRefSn <> 0 Then
			
			ObjectRef = ProcessObjectSearchByStructure(GlobalRefSn, ObjectType, CreatedObject,
				MainObjectSearchMode, ObjectPropertiesModified, ObjectFound, True, ObjectParameters);

			If ObjectRef <> Undefined Then
				Return ObjectRef;
			EndIf;
			
		EndIf;
		
		// Searching by the sequence number if it is available in the file.
		RefSN = deAttribute(ExchangeFile, deNumberType, "Sn");
		
		If RefSN <> 0 Then
		
			ObjectRef = ProcessObjectSearchByStructure(RefSN, ObjectType, CreatedObject,
				MainObjectSearchMode, ObjectPropertiesModified, ObjectFound, False, ObjectParameters);
				
			If ObjectRef <> Undefined Then
				Return ObjectRef;
			EndIf;
			
		EndIf;
		
	EndIf;

	DontCreateObjectIfNotFound = deAttribute(ExchangeFile, deBooleanType, "DoNotCreateIfNotFound");
	OnExchangeObjectByRefSetGIUDOnly = Not MainObjectSearchMode 
		And deAttribute(ExchangeFile, deBooleanType, "OnMoveObjectByRefSetGIUDOnly");
	
	// Creating object search properties.
	ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace, SearchByEqualDate, ObjectParameters);
		
	CreatedObject = Undefined;
	
	If Not ObjectFound Then
		
		ObjectRef = CreateNewObject(ObjectType, SearchProperties, CreatedObject, , , , RefSN, GlobalRefSn);
		AddRefToImportedObjectList(GlobalRefSn, RefSN, ObjectRef);
		Return ObjectRef;
		
	EndIf;

	PropertyStructure   = Managers[ObjectType];
	ObjectTypeName     = PropertyStructure.TypeName;
		
	UUIDProperty = SearchProperties["{UUID}"];
	PredefinedNameProperty = SearchProperties["{PredefinedItemName}"];
	
	OnExchangeObjectByRefSetGIUDOnly = OnExchangeObjectByRefSetGIUDOnly
		AND UUIDProperty <> Undefined;
		
	// Searching by name if the item is predefined.
	If PredefinedNameProperty <> Undefined Then
		
		CreateNewObjectAutomatically = Not DontCreateObjectIfNotFound
			And Not OnExchangeObjectByRefSetGIUDOnly;
		
		ObjectRef = FindCreateObjectByProperty(PropertyStructure, ObjectType, SearchProperties, SearchPropertiesDontReplace,
			ObjectTypeName, "{PredefinedItemName}", PredefinedNameProperty, ObjectFound, 
			CreateNewObjectAutomatically, CreatedObject, MainObjectSearchMode, ObjectPropertiesModified,
			RefSN, GlobalRefSn, ObjectParameters);

	ElsIf (UUIDProperty <> Undefined) Then
			
		// Creating the new item by the UUID is not always necessary. Perhaps, the search must be continued.
		ContinueSearchIfItemNotFoundByGUID = GetAdditionalSearchBySearchFieldsUsageByObjectType(PropertyStructure.RefTypeString);

		CreateNewObjectAutomatically = (Not DontCreateObjectIfNotFound
			And Not ContinueSearchIfItemNotFoundByGUID)
			And Not OnExchangeObjectByRefSetGIUDOnly;

		ObjectRef = FindCreateObjectByProperty(PropertyStructure, ObjectType, SearchProperties, SearchPropertiesDontReplace,
			ObjectTypeName, "{UUID}", UUIDProperty, ObjectFound, 
			CreateNewObjectAutomatically, CreatedObject, 
			MainObjectSearchMode, ObjectPropertiesModified,
			RefSN, GlobalRefSn, ObjectParameters, KnownUUIDRef);

		If Not ContinueSearchIfItemNotFoundByGUID Then

			If Not ValueIsFilled(ObjectRef)
				And OnExchangeObjectByRefSetGIUDOnly Then
				
				ObjectRef = PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
				ObjectFound = False;
				DummyObjectRef = True;
			
			EndIf;
			
			If ObjectRef <> Undefined 
				And ObjectRef.IsEmpty() Then
						
				ObjectRef = Undefined;
						
			EndIf;
			
			If ObjectRef <> Undefined
				Or CreatedObject <> Undefined Then

				AddRefToImportedObjectList(GlobalRefSn, RefSN, ObjectRef, DummyObjectRef);
				
			EndIf;
			
			Return ObjectRef;	
			
		EndIf;
		
	EndIf;

	If ObjectRef <> Undefined And ObjectRef.IsEmpty() Then
		
		ObjectRef = Undefined;
		
	EndIf;
		
	// ObjectRef is not found yet.
	If ObjectRef <> Undefined Or CreatedObject <> Undefined Then
		
		AddRefToImportedObjectList(GlobalRefSn, RefSN, ObjectRef);
		Return ObjectRef;
		
	EndIf;

	SearchVariantNumber = 1;
	SearchPropertyNameString = "";
	PreviousSearchString = Undefined;
	StopSearch = False;
	SetAllObjectSearchProperties = True;
	
	If Not IsBlankString(OCRName) Then
		
		OCR = Rules[OCRName];
		
	EndIf;
	
	If OCR = Undefined Then
		
		OCR = GetConversionRuleWithSearchAlgorithmByDestinationObjectType(PropertyStructure.RefTypeString);
		
	EndIf;
	
	If OCR <> Undefined Then
		
		SearchAlgorithm = OCR.SearchFieldSequence;
		
	EndIf;

	HasSearchAlgorithm = Not IsBlankString(SearchAlgorithm);
	
	While SearchVariantNumber <= 10 And HasSearchAlgorithm Do
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(OCR, "SearchFieldSequence"));
					
			Else
				
				Execute(SearchAlgorithm);
			
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(73, ErrorDescription(), "", "",
				ObjectType, Undefined, NStr("ru = 'Последовательность полей поиска'; en = 'Search field sequence'"));
			
		EndTry;

		DontSearch = StopSearch = True Or SearchPropertyNameString = PreviousSearchString
			OR ValueIsFilled(ObjectRef);
		
		If Not DontSearch Then
		
			ObjectRef = FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, PropertyStructure, 
				SearchPropertyNameString, SearchByEqualDate);
				
			DontSearch = ValueIsFilled(ObjectRef);
			
			If ObjectRef <> Undefined And ObjectRef.IsEmpty() Then
				ObjectRef = Undefined;
			EndIf;
			
		EndIf;

		If DontSearch Then
			
			If MainObjectSearchMode AND SetAllObjectSearchProperties = True Then
				
				ProcessObjectSearchPropertySetting(SetAllObjectSearchProperties, ObjectType, SearchProperties, SearchPropertiesDontReplace,
					ObjectRef, CreatedObject, NOT MainObjectSearchMode, ObjectPropertiesModified);
				
			EndIf;
			
			Break;
			
		EndIf;
		
		SearchVariantNumber = SearchVariantNumber + 1;
		PreviousSearchString = SearchPropertyNameString;
		
	EndDo;

	If Not HasSearchAlgorithm Then
		
		// The search with no search algorithm.
		ObjectRef = FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, PropertyStructure, 
					SearchPropertyNameString, SearchByEqualDate);
		
	EndIf;

	ObjectFound = ValueIsFilled(ObjectRef);
	
	If MainObjectSearchMode And ValueIsFilled(ObjectRef) And (ObjectTypeName = "Document" 
		Or ObjectTypeName = "Task" Or ObjectTypeName = "BusinessProcess") Then
		
		// Setting the date if it is in the document search fields.
		EmptyDate = Not ValueIsFilled(SearchProperties["Date"]);
		CanReplace = (Not EmptyDate) And (SearchPropertiesDontReplace["Date"] = Undefined);
			
		If CanReplace Then
			
			If CreatedObject = Undefined Then
				CreatedObject = ObjectRef.GetObject();
			EndIf;
			
			CreatedObject.Date = SearchProperties["Date"];
			
		EndIf;
		
	EndIf;
	
	// Creating a new object is not always necessary.
	If Not ValueIsFilled(ObjectRef) And CreatedObject = Undefined Then 
		
		If OnExchangeObjectByRefSetGIUDOnly Then
			
			ObjectRef = PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));	
			DummyObjectRef = True;
			
		ElsIf Not DontCreateObjectIfNotFound Then
		
			ObjectRef = CreateNewObject(ObjectType, SearchProperties, CreatedObject, Not MainObjectSearchMode, , KnownUUIDRef, RefSN, 
				GlobalRefSn, ,SetAllObjectSearchProperties);
				
			ObjectPropertiesModified = True;
				
		EndIf;
			
		ObjectFound = False;
		
	Else
		
		ObjectFound = ValueIsFilled(ObjectRef);
		
	EndIf;
	
	If ObjectRef <> Undefined And ObjectRef.IsEmpty() Then
		
		ObjectRef = Undefined;
		
	EndIf;
	
	AddRefToImportedObjectList(GlobalRefSn, RefSN, ObjectRef, DummyObjectRef);
		
	Return ObjectRef;
	
EndFunction

Procedure SetRecordProperties(Object, Record, TypesInformation,
	ObjectParameters, BranchName, TSSearchData, TSCopyForSearch, RecordNumber)
	
	SearchInTS = (TSSearchData <> Undefined) And (TSCopyForSearch <> Undefined)
		And TSCopyForSearch.Count() <> 0;

	If SearchInTS Then
		
		PropertyReadingStructure = New Structure();
		ExtDimensionReadingStructure = New Structure();
		
	EndIf;

	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Property" Or NodeName = "ParameterValue" Then
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name    = deAttribute(ExchangeFile, deStringType, "Name");
			OCRName = deAttribute(ExchangeFile, deStringType, "OCRName");
			
			If Name = "RecordType" And StrFind(Metadata.FindByType(TypeOf(Record)).FullName(), "AccumulationRegister") Then
				
				PropertyType = deAccumulationRecordTypeType;
				
			Else
				
				PropertyType = GetPropertyTypeByAdditionalData(TypesInformation, Name);
				
			EndIf;
			
			PropertyValue = ReadProperty(PropertyType, OCRName);

			If IsParameter Then
				AddComplexParameterIfNecessary(ObjectParameters, BranchName, RecordNumber, Name, PropertyValue);			
			ElsIf SearchInTS Then 
				PropertyReadingStructure.Insert(Name, PropertyValue);	
			Else
				
				Try
					
					Record[Name] = PropertyValue;
					
				Except
					
					LR = GetLogRecordStructure(26, ErrorDescription());
					LR.OCRName           = OCRName;
					LR.Object           = Object;
					LR.ObjectType       = TypeOf(Object);
					LR.Property         = String(Record) + "." + Name;
					LR.Value         = PropertyValue;
					LR.ValueType      = TypeOf(PropertyValue);
					ErrorMessageString = WriteToExecutionLog(26, LR, True);
					
					If Not DebugModeFlag Then
						Raise ErrorMessageString;
					EndIf;
				EndTry;
				
			EndIf;

		ElsIf NodeName = "ExtDimensionsDr" Or NodeName = "ExtDimensionsCr" Then
			
			varKey = Undefined;
			Value = Undefined;
			
			While ExchangeFile.Read() Do
				
				NodeName = ExchangeFile.LocalName;
								
				If NodeName = "Property" Then
					
					Name    = deAttribute(ExchangeFile, deStringType, "Name");
					OCRName = deAttribute(ExchangeFile, deStringType, "OCRName");
					PropertyType = GetPropertyTypeByAdditionalData(TypesInformation, Name);
										
					If Name = "Key" Then
						
						varKey = ReadProperty(PropertyType);
						
					ElsIf Name = "Value" Then
						
						Value = ReadProperty(PropertyType, OCRName);
						
					EndIf;
					
				ElsIf (NodeName = "ExtDimensionsDr" Or NodeName = "ExtDimensionsCr") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
					
					Break;
					
				Else
					
					WriteToExecutionLog(9);
					Break;
					
				EndIf;
				
			EndDo;

			If varKey <> Undefined And Value <> Undefined Then
				
				If Not SearchInTS Then
				
					Record[NodeName][varKey] = Value;
					
				Else
					
					RecordMap = Undefined;
					If Not ExtDimensionReadingStructure.Property(NodeName, RecordMap) Then
						RecordMap = New Map;
						ExtDimensionReadingStructure.Insert(NodeName, RecordMap);
					EndIf;
					
					RecordMap.Insert(varKey, Value);
					
				EndIf;
				
			EndIf;
				
		ElsIf (NodeName = "Record") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionLog(9);
			Break;
			
		EndIf;
		
	EndDo;

	If SearchInTS Then
		
		SearchStructure = New Structure();
		
		For Each SearchItem In  TSSearchData.TSSearchFields Do

			ItemValue = Undefined;
			PropertyReadingStructure.Property(SearchItem, ItemValue);
			
			SearchStructure.Insert(SearchItem, ItemValue);		
			
		EndDo;		
		
		SearchResultArray = TSCopyForSearch.FindRows(SearchStructure);
		
		RecordFound = SearchResultArray.Count() > 0;
		If RecordFound Then
			FillPropertyValues(Record, SearchResultArray[0]);
		EndIf;
		
		// Filling with properties and extra dimension value.
		For Each KeyAndValue In PropertyReadingStructure Do
			
			Record[KeyAndValue.Key] = KeyAndValue.Value;
			
		EndDo;
		
		For Each ItemName In ExtDimensionReadingStructure Do
			
			For Each ItemKey In ItemName.Value Do
			
				Record[ItemName.Key][ItemKey.Key] = ItemKey.Value;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Imports an object tabular section.
//
// Parameters:
//  Object - CatalogObject, DocumentObject, etc. - an object whose tabular section is imported.
//  Name - String - a tabular section name.
//  Clear - Boolean - if True, a tabular section is cleared before import.
//  GeneralDocumentTypeInformation - Structure - an info about column data types.
//  WriteObject - Boolean - if True, a tabular section was changed and must be written to the infobase.
//  ObjectParameters - Structure - an object writing parameters.
//  Rule - ValueTableRow - a tabular section import rule.  
// 
Procedure ImportTabularSection(Object, Name, Clear, GeneralDocumentTypeInformation, WriteObject, 
	ObjectParameters, Rule)

	TabularSectionName = Name + "TabularSection";
	If GeneralDocumentTypeInformation <> Undefined Then
		TypesInformation = GeneralDocumentTypeInformation[TabularSectionName];
	Else
	    TypesInformation = Undefined;
	EndIf;

	TSSearchData = Undefined;
	If Rule <> Undefined Then
		TSSearchData = Rule.SearchInTabularSections.Find("TabularSection." + Name, "ItemName");
	EndIf;
	
	TSCopyForSearch = Undefined;
	
	TS = Object[Name];

	If Clear And TS.Count() <> 0 Then
		
		WriteObject = True;
		
		If TSSearchData <> Undefined Then
			TSCopyForSearch = TS.Unload();
		EndIf;
		TS.Clear();
		
	ElsIf TSSearchData <> Undefined Then
		
		TSCopyForSearch = TS.Unload();
		
	EndIf;

	RecordNumber = 0;
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Record" Then
			Try
				
				WriteObject = True;
				Record = TS.Add();
				
			Except
				Record = Undefined;
			EndTry;
			
			If Record = Undefined Then
				deSkip(ExchangeFile);
			Else
				SetRecordProperties(Object, Record, TypesInformation, ObjectParameters, TabularSectionName, TSSearchData, TSCopyForSearch, RecordNumber);
			EndIf;
			
			RecordNumber = RecordNumber + 1;
			
		ElsIf (NodeName = "TabularSection") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionLog(9);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure 

// Imports object register records.
//
// Parameters:
//  Object - DocumentObject - an object whose register records is imported.
//  Name - String - a register name.
//  Clear - Boolean - if True, a record set is cleared before import.
//  GeneralDocumentTypeInformation - Structure - an info about column data types.
//  WriteObject - Boolean - if True, a record set was changed and must be written to the infobase.
//  ObjectParameters - Structure - an object writing parameters.
//  Rule - ValueTableRow - a record set import rule.
// 
Procedure ImportRegisterRecords(Object, Name, Clear, GeneralDocumentTypeInformation, WriteObject, 
	ObjectParameters, Rule)
	
	RegisterRecordName = Name + "RecordSet";
	If GeneralDocumentTypeInformation <> Undefined Then
		TypesInformation = GeneralDocumentTypeInformation[RegisterRecordName];
	Else
	    TypesInformation = Undefined;
	EndIf;
	
	TSSearchData = Undefined;
	If Rule <> Undefined Then
		SearchDataInTS = Rule.SearchInTabularSections.Find("RecordSet." + Name, "ItemName");
	EndIf;
	
	TSCopyForSearch = Undefined;
	
	RegisterRecords = Object.RegisterRecords[Name];
	RegisterRecords.Write = True;
	
	If RegisterRecords.Count()=0 Then
		RegisterRecords.Read();
	EndIf;
	
	If Clear And RegisterRecords.Count() <> 0 Then
		
		WriteObject = True;
		
		If TSSearchData <> Undefined Then 
			TSCopyForSearch = RegisterRecords.Unload();
		EndIf;
		
        RegisterRecords.Clear();
		
	ElsIf TSSearchData <> Undefined Then
		
		TSCopyForSearch = RegisterRecords.Unload();	
		
	EndIf;
	
	RecordNumber = 0;
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
			
		If NodeName = "Record" Then
			
			Record = RegisterRecords.Add();
			WriteObject = True;
			SetRecordProperties(Object, Record, TypesInformation, ObjectParameters, RegisterRecordName, TSSearchData, TSCopyForSearch, RecordNumber);
			RecordNumber = RecordNumber + 1;
			
		ElsIf (NodeName = "RecordSet") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionLog(9);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Imports an object of the TypeDescription type from the specified XML source.
//
// Parameters:
//  Source - an XML source.
// 
Function ImportObjectTypes(Source)
	
	// DateQualifiers
	
	DateContents =  deAttribute(Source, deStringType,  "DateContents");
	
	// StringQualifiers
	
	Length           =  deAttribute(Source, deNumberType,  "Length");
	LengthAllowed =  deAttribute(Source, deStringType, "AllowedLength");

	// NumberQualifiers
	
	Digits             = deAttribute(Source, deNumberType,  "Digits");
	FractionDigits = deAttribute(Source, deNumberType,  "FractionDigits");
	SignAllowed          = deAttribute(Source, deStringType, "AllowedSign");
	
	// Reading the array of types
	
	TypesArray = New Array;
	
	While Source.Read() Do
		NodeName = Source.LocalName;
		
		If NodeName = "Type" Then
			TypesArray.Add(Type(deElementValue(Source, deStringType)));
		ElsIf (NodeName = "Types") And ( Source.NodeType = deXMLNodeType_EndElement) Then
			Break;
		Else
			WriteToExecutionLog(9);
			Break;
		EndIf;
		
	EndDo;

	If TypesArray.Count() > 0 Then
		
		// DateQualifiers
		
		If DateContents = "Date" Then
			DateQualifiers   = New DateQualifiers(DateFractions.Date);
		ElsIf DateContents = "DateTime" Then
			DateQualifiers   = New DateQualifiers(DateFractions.DateTime);
		ElsIf DateContents = "Time" Then
			DateQualifiers   = New DateQualifiers(DateFractions.Time);
		Else
			DateQualifiers   = New DateQualifiers(DateFractions.DateTime);
		EndIf;
		
		// NumberQualifiers
		
		If Digits > 0 Then
			If SignAllowed = "Nonnegative" Then
				Sign = AllowedSign.Nonnegative;
			Else
				Sign = AllowedSign.Any;
			EndIf; 
			NumberQualifiers  = New NumberQualifiers(Digits, FractionDigits, Sign);
		Else
			NumberQualifiers  = New NumberQualifiers();
		EndIf;
		
		// StringQualifiers
		
		If Length > 0 Then
			If LengthAllowed = "Fixed" Then
				LengthAllowed = AllowedLength.Fixed;
			Else
				LengthAllowed = AllowedLength.Variable;
			EndIf;
			StringQualifiers = New StringQualifiers(Length, LengthAllowed);
		Else
			StringQualifiers = New StringQualifiers();
		EndIf;
		
		Return New TypeDescription(TypesArray, NumberQualifiers, StringQualifiers, DateQualifiers);
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure SetObjectDeletionMark(Object, DeletionMark, ObjectTypeName)
	
	If (DeletionMark = Undefined) And (Object.DeletionMark <> True) Then
		
		Return;
		
	EndIf;
	
	MarkToSet = ?(DeletionMark <> Undefined, DeletionMark, False);
	
	SetDataExchangeLoad(Object);
		
	// For hierarchical object the deletion mark is set only for the current object.
	If ObjectTypeName = "Catalog" Or ObjectTypeName = "ChartOfCharacteristicTypes" Or ObjectTypeName = "ChartOfAccounts" Then
			
		Object.SetDeletionMark(MarkToSet, False);
			
	Else	
		
		Object.SetDeletionMark(MarkToSet);
		
	EndIf;
	
EndProcedure

Procedure WriteDocumentInSafeMode(Document, ObjectType)
	
	If Document.Posted Then
						
		Document.Posted = False;
			
	EndIf;		
								
	WriteObjectToIB(Document, ObjectType);
	
EndProcedure

Function GetObjectByRefAndAdditionalInformation(CreatedObject, Ref)
	
	If CreatedObject <> Undefined Then
		Object = CreatedObject;
	Else
		If Ref.IsEmpty() Then
			Object = Undefined;
		Else
			Object = Ref.GetObject();
		EndIf;		
	EndIf;
	
	Return Object;
	
EndFunction

Procedure ObjectImportComments(SN, RuleName, Source, ObjectType, GSN = 0)
	
	If CommentObjectProcessingFlag Then
		
		If SN <> 0 Then
			MessageString = SubstituteParametersToString(NStr("ru = 'Загрузка объекта № %1'; en = 'Importing object #%1'"), SN);
		Else
			MessageString = SubstituteParametersToString(NStr("ru = 'Загрузка объекта № %1'; en = 'Importing object #%1'"), GSN);
		EndIf;
		
		LR = GetLogRecordStructure();
		
		If Not IsBlankString(RuleName) Then
			
			LR.OCRName = RuleName;
			
		EndIf;
		
		If Not IsBlankString(Source) Then
			
			LR.Source = Source;
			
		EndIf;
		
		LR.ObjectType = ObjectType;
		WriteToExecutionLog(MessageString, LR, False);
		
	EndIf;	
	
EndProcedure

Procedure AddParameterIfNecessary(DataParameters, ParameterName, ParameterValue)
	
	If DataParameters = Undefined Then
		DataParameters = New Map;
	EndIf;
	
	DataParameters.Insert(ParameterName, ParameterValue);
	
EndProcedure

Procedure AddComplexParameterIfNecessary(DataParameters, ParameterBranchName, LineNumber, ParameterName, ParameterValue)
	
	If DataParameters = Undefined Then
		DataParameters = New Map;
	EndIf;
	
	CurrentParameterData = DataParameters[ParameterBranchName];
	
	If CurrentParameterData = Undefined Then
		
		CurrentParameterData = New ValueTable;
		CurrentParameterData.Columns.Add("LineNumber");
		CurrentParameterData.Columns.Add("ParameterName");
		CurrentParameterData.Indexes.Add("LineNumber");
		
		DataParameters.Insert(ParameterBranchName, CurrentParameterData);	
		
	EndIf;
	
	If CurrentParameterData.Columns.Find(ParameterName) = Undefined Then
		CurrentParameterData.Columns.Add(ParameterName);
	EndIf;		
	
	LineData = CurrentParameterData.Find(LineNumber, "LineNumber");
	If LineData = Undefined Then
		LineData = CurrentParameterData.Add();
		LineData.LineNumber = LineNumber;
	EndIf;		
	
	LineData[ParameterName] = ParameterValue;
	
EndProcedure

Procedure SetObjectRef(NotWrittenObjectStackRow)
	
	// The is not written yet but need a reference.
	ObjectToWrite = NotWrittenObjectStackRow.Object;
	
	MDProperties      = Managers[NotWrittenObjectStackRow.ObjectType];
	Manager        = MDProperties.Manager;
		
	NewUUID = New UUID;
	NewRef = Manager.GetRef(NewUUID);
		
	ObjectToWrite.SetNewObjectRef(NewRef);
	NotWrittenObjectStackRow.KnownRef = NewRef;
	
EndProcedure

Procedure SupplementNotWrittenObjectsStack(SN, GSN, Object, KnownRef, ObjectType, ObjectParameters)

	NumberForStack = ?(SN = 0, GSN, SN);
	
	StackString = mNotWrittenObjectGlobalStack[NumberForStack];
	If StackString <> Undefined Then
		Return;
	EndIf;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Object", Object);
	ParametersStructure.Insert("KnownRef", KnownRef);
	ParametersStructure.Insert("ObjectType", ObjectType);
	ParametersStructure.Insert("ObjectParameters", ObjectParameters);

	mNotWrittenObjectGlobalStack.Insert(NumberForStack, ParametersStructure);
	
EndProcedure

Procedure DeleteFromNotWrittenObjectStack(SN, GSN)
	
	NumberForStack = ?(SN = 0, GSN, SN);
	StackString = mNotWrittenObjectGlobalStack[NumberForStack];
	If StackString = Undefined Then
		Return;
	EndIf;
	
	mNotWrittenObjectGlobalStack.Delete(NumberForStack);	
	
EndProcedure

Procedure ExecuteWriteNotWrittenObjects()
	
	If mNotWrittenObjectGlobalStack = Undefined Then
		Return;
	EndIf;
	
	For Each DataRow In mNotWrittenObjectGlobalStack Do
		
		// Deferred objects writing
		Object = DataRow.Value.Object; // CatalogObject, DocumentObject, etc.
		RefSN = DataRow.Key;
		
		WriteObjectToIB(Object, DataRow.Value.ObjectType);
		
		AddRefToImportedObjectList(0, RefSN, Object.Ref);
		
	EndDo;
	
	mNotWrittenObjectGlobalStack.Clear();
	
EndProcedure

Процедура ПровестиГенерациюКодаНомераПриНеобходимости(ГенерироватьНовыйНомерИлиКодЕслиНеУказан, Объект, ИмяТипаОбъекта,
	НужноЗаписатьОбъект, РежимОбменДанными)

	Если Не ГенерироватьНовыйНомерИлиКодЕслиНеУказан Или Не РежимОбменДанными Тогда
		
		// Если номер не нужно генерировать, или не в режиме обмена данными то ничего не нужно делать... платформа сама все
		// сгенерирует.
		Возврат;
	КонецЕсли;
	
	// По типу документа смотрим заполнен кол или номер.
	Если ИмяТипаОбъекта = "Документ" Или ИмяТипаОбъекта = "БизнесПроцесс" Или ИмяТипаОбъекта = "Задача" Тогда

		Если Не ЗначениеЗаполнено(Объект.Номер) Тогда

			Объект.УстановитьНовыйНомер();
			НужноЗаписатьОбъект = Истина;

		КонецЕсли;

	ИначеЕсли ИмяТипаОбъекта = "Справочник" Или ИмяТипаОбъекта = "ПланВидовХарактеристик" Или ИмяТипаОбъекта
		= "ПланОбмена" Тогда

		Если Не ЗначениеЗаполнено(Объект.Код) Тогда

			Объект.УстановитьНовыйКод();
			НужноЗаписатьОбъект = Истина;

		КонецЕсли;

	КонецЕсли;

КонецПроцедуры

// Читает очередной объект из файла обмена, производит загрузку.
//
// Параметры:
//  Нет.
// 
Функция ПрочитатьОбъект()

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	НПП						= одАтрибут(ФайлОбмена, одТипЧисло, "Нпп");
	ГНПП					= одАтрибут(ФайлОбмена, одТипЧисло, "ГНпп");
	Источник				= одАтрибут(ФайлОбмена, одТипСтрока, "Источник");
	ИмяПравила				= одАтрибут(ФайлОбмена, одТипСтрока, "ИмяПравила");
	НеЗамещатьОбъект 		= одАтрибут(ФайлОбмена, одТипБулево, "НеЗамещать");
	ПрефиксАвтонумерации	= одАтрибут(ФайлОбмена, одТипСтрока, "ПрефиксАвтонумерации");
	ТипОбъектаСтрокой       = одАтрибут(ФайлОбмена, одТипСтрока, "Тип");
	ТипОбъекта 				= Тип(ТипОбъектаСтрокой);
	ИнформацияОТипах = мСоответствиеТиповДанныхДляЗагрузки[ТипОбъекта];

	КомментарииКЗагрузкеОбъекта(НПП, ИмяПравила, Источник, ТипОбъекта, ГНПП);

	СтруктураСвойств = Менеджеры[ТипОбъекта];
	ИмяТипаОбъекта   = СтруктураСвойств.ИмяТипа;

	Если ИмяТипаОбъекта = "Документ" Тогда

		РежимЗаписи     = одАтрибут(ФайлОбмена, одТипСтрока, "РежимЗаписи");
		РежимПроведения = одАтрибут(ФайлОбмена, одТипСтрока, "РежимПроведения");

	КонецЕсли;

	Ссылка          = Неопределено;
	Объект          = Неопределено; // СправочникОбъект, ДокументОбъект, РегистрСведенийНаборЗаписей, и т.п.
	ОбъектНайден    = Истина;
	ПометкаУдаления = Неопределено;

	СвойстваПоиска  = Новый Соответствие;
	СвойстваПоискаНеЗамещать  = Новый Соответствие;

	НужноЗаписатьОбъект = Не WriteToInfobaseOnlyChangedObjects;
	Если Не ПустаяСтрока(ИмяПравила) Тогда

		Правило = Правила[ИмяПравила];
		ЕстьОбработчикПередЗагрузкой = Правило.ЕстьОбработчикПередЗагрузкой;
		ЕстьОбработчикПриЗагрузке    = Правило.ЕстьОбработчикПриЗагрузке;
		ЕстьОбработчикПослеЗагрузки  = Правило.ЕстьОбработчикПослеЗагрузки;
		ГенерироватьНовыйНомерИлиКодЕслиНеУказан = Правило.ГенерироватьНовыйНомерИлиКодЕслиНеУказан;

	Иначе

		ЕстьОбработчикПередЗагрузкой = Ложь;
		ЕстьОбработчикПриЗагрузке    = Ложь;
		ЕстьОбработчикПослеЗагрузки  = Ложь;
		ГенерироватьНовыйНомерИлиКодЕслиНеУказан = Ложь;

	КонецЕсли;


    // Глобальный обработчик события ПередЗагрузкойОбъекта.
	Если ЕстьГлобальныйОбработчикПередЗагрузкойОбъекта Тогда

		Отказ = Ложь;

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПередЗагрузкойОбъекта"));

			Иначе

				Выполнить (Конвертация.ПередЗагрузкойОбъекта);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(53, ОписаниеОшибки(), ИмяПравила, Источник, ТипОбъекта,
				Неопределено, НСтр("ru = 'ПередЗагрузкойОбъекта (глобальный)'"));

		КонецПопытки;

		Если Отказ Тогда	//	Отказ от загрузки объекта

			одПропустить(ФайлОбмена, "Объект");
			Возврат Неопределено;

		КонецЕсли;

	КонецЕсли;
	
	
    // Обработчик события ПередЗагрузкойОбъекта.
	Если ЕстьОбработчикПередЗагрузкой Тогда

		Отказ = Ложь;

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПередЗагрузкой"));

			Иначе

				Выполнить (Правило.ПередЗагрузкой);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(19, ОписаниеОшибки(), ИмяПравила, Источник, ТипОбъекта,
				Неопределено, "ПередЗагрузкойОбъекта");

		КонецПопытки;

		Если Отказ Тогда // Отказ от загрузки объекта

			одПропустить(ФайлОбмена, "Объект");
			Возврат Неопределено;

		КонецЕсли;

	КонецЕсли;

	СвойстваОбъектаМодифицированы = Ложь;
	НаборЗаписей = Неопределено;
	НППГлобальнойСсылки = 0;
	НППСсылки = 0;
	ПараметрыОбъекта = Неопределено;

	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Свойство" Или ИмяУзла = "ЗначениеПараметра" Тогда

			ЭтоПараметрДляОбъекта = (ИмяУзла = "ЗначениеПараметра");

			Если Не ЭтоПараметрДляОбъекта И Объект = Неопределено Тогда
				
				// Объект не нашли и не создали - попробуем сейчас это сделать.
				ОбъектНайден = Ложь;

			    // Обработчик события ПриЗагрузкеОбъекта.
				Если ЕстьОбработчикПриЗагрузке Тогда
					
					// Если есть обработчик при загрузке, то объект нужно перезаписывать, так как могут быть изменения.
					НужноБылоЗаписатьОбъект = НужноЗаписатьОбъект;
					ОбъектМодифицирован = Истина;

					Попытка

						Если HandlersDebugModeFlag Тогда

							Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПриЗагрузке"));

						Иначе

							Выполнить (Правило.ПриЗагрузке);

						КонецЕсли;
						НужноЗаписатьОбъект = ОбъектМодифицирован Или НужноБылоЗаписатьОбъект;

					Исключение

						ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(20, ОписаниеОшибки(), ИмяПравила, Источник,
							ТипОбъекта, Объект, "ПриЗагрузкеОбъекта");

					КонецПопытки;

				КонецЕсли;

				// Так м не смогли создать объект в событии - создаем его отдельно.
				Если Объект = Неопределено Тогда

					НужноЗаписатьОбъект = Истина;

					Если ИмяТипаОбъекта = "Константы" Тогда

						Объект = Константы.СоздатьНабор();
						Объект.Прочитать();

					Иначе

						СоздатьНовыйОбъект(ТипОбъекта, СвойстваПоиска, Объект, Ложь, НаборЗаписей, , НППСсылки,
							НППГлобальнойСсылки, ПараметрыОбъекта);

					КонецЕсли;

				КонецЕсли;

			КонецЕсли;

			Имя                = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");
			НеЗамещатьСвойство = одАтрибут(ФайлОбмена, одТипБулево, "НеЗамещать");
			ИмяПКО             = одАтрибут(ФайлОбмена, одТипСтрока, "ИмяПКО");

			Если Не ЭтоПараметрДляОбъекта И ((ОбъектНайден И НеЗамещатьСвойство) Или (Имя = "ЭтоГруппа")
				Или (Объект[Имя] = Null)) Тогда
				
				// неизвестное свойство
				одПропустить(ФайлОбмена, ИмяУзла);
				Продолжить;

			КонецЕсли; 

			
			// Читаем и устанавливаем значение свойства.
			ТипСвойства = ПолучитьТипСвойстваПоДополнительнымДанным(ИнформацияОТипах, Имя);
			Значение    = ПрочитатьСвойство(ТипСвойства, ИмяПКО);

			Если ЭтоПараметрДляОбъекта Тогда
				
				// Дополняем коллекцию параметров объекта.
				ДобавитьПараметрПриНеобходимости(ПараметрыОбъекта, Имя, Значение);

			Иначе

				Если Имя = "ПометкаУдаления" Тогда

					ПометкаУдаления = Значение;

					Если Объект.ПометкаУдаления <> ПометкаУдаления Тогда
						Объект.ПометкаУдаления = ПометкаУдаления;
						НужноЗаписатьОбъект = Истина;
					КонецЕсли;

				Иначе

					Попытка

						Если Не НужноЗаписатьОбъект Тогда

							НужноЗаписатьОбъект = (Объект[Имя] <> Значение);

						КонецЕсли;

						Объект[Имя] = Значение;

					Исключение

						ЗП = ПолучитьСтруктуруЗаписиПротокола(26, ОписаниеОшибки());
						ЗП.ИмяПКО           = ИмяПравила;
						ЗП.НПП              = НПП;
						ЗП.ГНПП             = ГНПП;
						ЗП.Источник         = Источник;
						ЗП.Объект           = Объект;
						ЗП.ТипОбъекта       = ТипОбъекта;
						ЗП.Свойство         = Имя;
						ЗП.Значение         = Значение;
						ЗП.ТипЗначения      = ТипЗнч(Значение);
						СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(26, ЗП, Истина);

						Если Не DebugModeFlag Тогда
							ВызватьИсключение СтрокаСообщенияОбОшибке;
						КонецЕсли;

					КонецПопытки;

				КонецЕсли;

			КонецЕсли;

		ИначеЕсли ИмяУзла = "Ссылка" Тогда
			
			// Ссылка на элемент - сначала получаем по ссылке объект, а потом устанавливаем свойства.
			СозданныйОбъект = Неопределено;
			НеСоздаватьОбъектЕслиНеНайден = Неопределено;
			ИзвестнаяСсылкаУникальногоИдентификатора = Неопределено;

			Ссылка = НайтиОбъектПоСсылке(ТипОбъекта, ИмяПравила, СвойстваПоиска, СвойстваПоискаНеЗамещать, ОбъектНайден,
				СозданныйОбъект, НеСоздаватьОбъектЕслиНеНайден, Истина, СвойстваОбъектаМодифицированы,
				НППГлобальнойСсылки, НППСсылки, ИзвестнаяСсылкаУникальногоИдентификатора, ПараметрыОбъекта);

			НужноЗаписатьОбъект = НужноЗаписатьОбъект Или СвойстваОбъектаМодифицированы;

			Если Ссылка = Неопределено И НеСоздаватьОбъектЕслиНеНайден = Истина Тогда

				одПропустить(ФайлОбмена, "Объект");
				Прервать;

			ИначеЕсли ИмяТипаОбъекта = "Перечисление" Тогда

				Объект = Ссылка;

			Иначе

				Объект = ПолучитьОбъектПоСсылкеИДопИнформации(СозданныйОбъект, Ссылка);

				Если ОбъектНайден И НеЗамещатьОбъект И (Не ЕстьОбработчикПриЗагрузке) Тогда

					одПропустить(ФайлОбмена, "Объект");
					Прервать;

				КонецЕсли;

				Если Ссылка = Неопределено Тогда

					SupplementNotWrittenObjectsStack(НПП, ГНПП, СозданныйОбъект,
						ИзвестнаяСсылкаУникальногоИдентификатора, ТипОбъекта, ПараметрыОбъекта);

				КонецЕсли;

			КонецЕсли; 
			
		    // Обработчик события ПриЗагрузкеОбъекта.
			Если ЕстьОбработчикПриЗагрузке Тогда

				НужноБылоЗаписатьОбъект = НужноЗаписатьОбъект;
				ОбъектМодифицирован = Истина;

				Попытка

					Если HandlersDebugModeFlag Тогда

						Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПриЗагрузке"));

					Иначе

						Выполнить (Правило.ПриЗагрузке);

					КонецЕсли;

					НужноЗаписатьОбъект = ОбъектМодифицирован Или НужноБылоЗаписатьОбъект;

				Исключение
					УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);
					ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(20, ОписаниеОшибки(), ИмяПравила, Источник,
						ТипОбъекта, Объект, "ПриЗагрузкеОбъекта");

				КонецПопытки;

				Если ОбъектНайден И НеЗамещатьОбъект Тогда

					одПропустить(ФайлОбмена, "Объект");
					Прервать;

				КонецЕсли;

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ТабличнаяЧасть" Или ИмяУзла = "НаборЗаписей" Тогда

			Если Объект = Неопределено Тогда

				ОбъектНайден = Ложь;

			    // Обработчик события ПриЗагрузкеОбъекта.

				Если ЕстьОбработчикПриЗагрузке Тогда

					НужноБылоЗаписатьОбъект = НужноЗаписатьОбъект;
					ОбъектМодифицирован = Истина;

					Попытка

						Если HandlersDebugModeFlag Тогда

							Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПриЗагрузке"));

						Иначе

							Выполнить (Правило.ПриЗагрузке);

						КонецЕсли;

						НужноЗаписатьОбъект = ОбъектМодифицирован Или НужноБылоЗаписатьОбъект;

					Исключение
						УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);
						ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(20, ОписаниеОшибки(), ИмяПравила, Источник,
							ТипОбъекта, Объект, "ПриЗагрузкеОбъекта");

					КонецПопытки;

				КонецЕсли;

			КонецЕсли;

			Имя                = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");
			НеЗамещатьСвойство = одАтрибут(ФайлОбмена, одТипБулево, "НеЗамещать");
			НеОчищать          = одАтрибут(ФайлОбмена, одТипБулево, "НеОчищать");

			Если ОбъектНайден И НеЗамещатьСвойство Тогда

				одПропустить(ФайлОбмена, ИмяУзла);
				Продолжить;

			КонецЕсли;

			Если Объект = Неопределено Тогда

				СоздатьНовыйОбъект(ТипОбъекта, СвойстваПоиска, Объект, Ложь, НаборЗаписей, , НППСсылки,
					НППГлобальнойСсылки, ПараметрыОбъекта);
				НужноЗаписатьОбъект = Истина;

			КонецЕсли;

			Если ИмяУзла = "ТабличнаяЧасть" Тогда
				
				// Загрузка элементов из табличной части.
				ЗагрузитьТабличнуюЧасть(Объект, Имя, Не НеОчищать, ИнформацияОТипах, НужноЗаписатьОбъект,
					ПараметрыОбъекта, Правило);

			ИначеЕсли ИмяУзла = "НаборЗаписей" Тогда
				
				// загрузка движений
				ЗагрузитьДвижения(Объект, Имя, Не НеОчищать, ИнформацияОТипах, НужноЗаписатьОбъект, ПараметрыОбъекта,
					Правило);

			КонецЕсли;

		ИначеЕсли (ИмяУзла = "Объект") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Отказ = Ложь;
			
		    // Глобальный обработчик события ПослеЗагрузкиОбъекта.
			Если ЕстьГлобальныйОбработчикПослеЗагрузкиОбъекта Тогда

				НужноБылоЗаписатьОбъект = НужноЗаписатьОбъект;
				ОбъектМодифицирован = Истина;

				Попытка

					Если HandlersDebugModeFlag Тогда

						Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПослеЗагрузкиОбъекта"));

					Иначе

						Выполнить (Конвертация.ПослеЗагрузкиОбъекта);

					КонецЕсли;

					НужноЗаписатьОбъект = ОбъектМодифицирован Или НужноБылоЗаписатьОбъект;

				Исключение
					УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);
					ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(54, ОписаниеОшибки(), ИмяПравила, Источник,
						ТипОбъекта, Объект, НСтр("ru = 'ПослеЗагрузкиОбъекта (глобальный)'"));

				КонецПопытки;

			КонецЕсли;
			
			// Обработчик события ПослеЗагрузкиОбъекта.
			Если ЕстьОбработчикПослеЗагрузки Тогда

				НужноБылоЗаписатьОбъект = НужноЗаписатьОбъект;
				ОбъектМодифицирован = Истина;

				Попытка

					Если HandlersDebugModeFlag Тогда

						Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПослеЗагрузки"));

					Иначе

						Выполнить (Правило.ПослеЗагрузки);

					КонецЕсли;

					НужноЗаписатьОбъект = ОбъектМодифицирован Или НужноБылоЗаписатьОбъект;

				Исключение
					УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);
					ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(21, ОписаниеОшибки(), ИмяПравила, Источник,
						ТипОбъекта, Объект, "ПослеЗагрузкиОбъекта");

				КонецПопытки;

			КонецЕсли;

			Если ИмяТипаОбъекта <> "РегистрСведений" И ИмяТипаОбъекта <> "Константы" И ИмяТипаОбъекта <> "Перечисление" Тогда
				// Проверка даты запрета для всех объектов кроме регистров сведений и констант.
				Отказ = Отказ Или ЗапретИзмененияДанныхПоДате(Объект);
			КонецЕсли;

			Если Отказ Тогда

				ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, Неопределено);
				УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);
				Возврат Неопределено;

			КонецЕсли;

			Если ИмяТипаОбъекта = "Документ" Тогда

				Если РежимЗаписи = "Проведение" Тогда

					РежимЗаписи = РежимЗаписиДокумента.Проведение;

				Иначе

					РежимЗаписи = ?(РежимЗаписи = "ОтменаПроведения", РежимЗаписиДокумента.ОтменаПроведения,
						РежимЗаписиДокумента.Запись);

				КонецЕсли;
				РежимПроведения = ?(РежимПроведения = "Оперативный", РежимПроведенияДокумента.Оперативный,
					РежимПроведенияДокумента.Неоперативный);
				

				// Если хотим провести документ помеченный на удаление, то пометку удаления снимаем ...
				Если Объект.ПометкаУдаления И (РежимЗаписи = РежимЗаписиДокумента.Проведение) Тогда

					Объект.ПометкаУдаления = Ложь;
					НужноЗаписатьОбъект = Истина;
					
					// Пометку удаления в любом случае нужно удалять.
					ПометкаУдаления = Ложь;

				КонецЕсли;

				Попытка

					НужноЗаписатьОбъект = НужноЗаписатьОбъект Или (РежимЗаписи <> РежимЗаписиДокумента.Запись);

					РежимОбменДанными = РежимЗаписи = РежимЗаписиДокумента.Запись;

					ПровестиГенерациюКодаНомераПриНеобходимости(ГенерироватьНовыйНомерИлиКодЕслиНеУказан, Объект,
						ИмяТипаОбъекта, НужноЗаписатьОбъект, РежимОбменДанными);

					Если НужноЗаписатьОбъект Тогда

						УстановитьОбменДаннымиЗагрузка(Объект, РежимОбменДанными);
						Если Объект.Проведен Тогда
							Объект.ПометкаУдаления = Ложь;
						КонецЕсли;

						Объект.Записать(РежимЗаписи, РежимПроведения);

					КонецЕсли;

				Исключение
						
					// Не смогли выполнить необходимые действия для документа.
					ЗаписатьДокументВБезопасномРежиме(Объект, ТипОбъекта);
					ЗП                        = ПолучитьСтруктуруЗаписиПротокола(25, ОписаниеОшибки());
					ЗП.ИмяПКО                 = ИмяПравила;

					Если Не ПустаяСтрока(Источник) Тогда

						ЗП.Источник           = Источник;

					КонецЕсли;

					ЗП.ТипОбъекта             = ТипОбъекта;
					ЗП.Объект                 = Строка(Объект);
					ЗаписатьВПротоколВыполнения(25, ЗП);

				КонецПопытки;

				ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, Объект.Ссылка);

				УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);

			ИначеЕсли ИмяТипаОбъекта <> "Перечисление" Тогда

				Если ИмяТипаОбъекта = "РегистрСведений" Тогда

					НужноЗаписатьОбъект = Не WriteToInfobaseOnlyChangedObjects;

					Если СтруктураСвойств.Периодический И Не ЗначениеЗаполнено(Объект.Период) Тогда

						Объект.Период = ТекущаяДатаСеанса();
						НужноЗаписатьОбъект = Истина;

					КонецЕсли;

					Если WriteRegistersAsRecordSets Тогда

						НужноПроверитьДанныеДляВременногоНабора = (WriteToInfobaseOnlyChangedObjects
							И Не НужноЗаписатьОбъект) Или НеЗамещатьОбъект;

						Если НужноПроверитьДанныеДляВременногоНабора Тогда

							ВременныйНаборЗаписей = РегистрыСведений[СтруктураСвойств.Имя].СоздатьНаборЗаписей();

						КонецЕсли;
						
						// Нужно отбор установить у регистра.
						Для Каждого ЭлементОтбора Из НаборЗаписей.Отбор Цикл

							ЭлементОтбора.Установить(Объект[ЭлементОтбора.Имя]);
							Если НужноПроверитьДанныеДляВременногоНабора Тогда
								УстановитьЗначениеЭлементаОтбора(ВременныйНаборЗаписей.Отбор, ЭлементОтбора.Имя,
									Объект[ЭлементОтбора.Имя]);
							КонецЕсли;

						КонецЦикла;

						Если НужноПроверитьДанныеДляВременногоНабора Тогда

							ВременныйНаборЗаписей.Прочитать();

							Если ВременныйНаборЗаписей.Количество() = 0 Тогда
								НужноЗаписатьОбъект = Истина;
							Иначе
								
								// Не хотим замещать существующий набор.
								Если НеЗамещатьОбъект Тогда
									Возврат Неопределено;
								КонецЕсли;

								НужноЗаписатьОбъект = Ложь;
								ТаблицаНовая = НаборЗаписей.Выгрузить(); // ТаблицаЗначений
								ТаблицаСтарая = ВременныйНаборЗаписей.Выгрузить();

								СтрокаНовая = ТаблицаНовая[0];
								СтрокаСтарая = ТаблицаСтарая[0];

								Для Каждого КолонкаТаблицы Из ТаблицаНовая.Колонки Цикл

									НужноЗаписатьОбъект = СтрокаНовая[КолонкаТаблицы.Имя]
										<> СтрокаСтарая[КолонкаТаблицы.Имя];
									Если НужноЗаписатьОбъект Тогда
										Прервать;
									КонецЕсли;

								КонецЦикла;

							КонецЕсли;

						КонецЕсли;

						Объект = НаборЗаписей;

						Если СтруктураСвойств.Периодический Тогда
							// Проверка даты запрета изменения для набора записей.
							// Если не проходит - не записывать набор.
							Если ЗапретИзмененияДанныхПоДате(Объект) Тогда
								Возврат Неопределено;
							КонецЕсли;
						КонецЕсли;

					Иначе
						
						// Регистр записываем не набором записей.
						Если НеЗамещатьОбъект Или СтруктураСвойств.Периодический Тогда
							
							// Возможно мы не хотим замещать существующую запись, либо нужна проверка на дату запрета.
							ВременныйНаборЗаписей = РегистрыСведений[СтруктураСвойств.Имя].СоздатьНаборЗаписей();
							
							// Нужно отбор установить у регистра.
							Для Каждого ЭлементОтбора Из ВременныйНаборЗаписей.Отбор Цикл

								ЭлементОтбора.Установить(Объект[ЭлементОтбора.Имя]);

							КонецЦикла;

							ВременныйНаборЗаписей.Прочитать();

							Если ВременныйНаборЗаписей.Количество() > 0 Или ЗапретИзмененияДанныхПоДате(
								ВременныйНаборЗаписей) Тогда
								Возврат Неопределено;
							КонецЕсли;

						Иначе
							// Считаем что объект следует записать.
							НужноЗаписатьОбъект = Истина;
						КонецЕсли;

					КонецЕсли;

				КонецЕсли;

				ЭтоСсылочныйТипОбъекта = Не (ИмяТипаОбъекта = "РегистрСведений" Или ИмяТипаОбъекта = "Константы"
					Или ИмяТипаОбъекта = "Перечисление");

				Если ЭтоСсылочныйТипОбъекта Тогда

					ПровестиГенерациюКодаНомераПриНеобходимости(ГенерироватьНовыйНомерИлиКодЕслиНеУказан, Объект,
						ИмяТипаОбъекта, НужноЗаписатьОбъект, ImportDataInExchangeMode);

					Если ПометкаУдаления = Неопределено Тогда
						ПометкаУдаления = Ложь;
					КонецЕсли;

					Если Объект.ПометкаУдаления <> ПометкаУдаления Тогда
						Объект.ПометкаУдаления = ПометкаУдаления;
						НужноЗаписатьОбъект = Истина;
					КонецЕсли;

				КонецЕсли;
				
				// Непосредственная запись самого объекта.
				Если НужноЗаписатьОбъект Тогда

					ЗаписатьОбъектВИБ(Объект, ТипОбъекта);

				КонецЕсли;

				Если ЭтоСсылочныйТипОбъекта Тогда

					ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, Объект.Ссылка);

				КонецЕсли;

				УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП);

			КонецЕсли;

			Прервать;

		ИначеЕсли ИмяУзла = "НаборЗаписейПоследовательности" Тогда

			одПропустить(ФайлОбмена);

		ИначеЕсли ИмяУзла = "Типы" Тогда

			Если Объект = Неопределено Тогда

				ОбъектНайден = Ложь;
				Ссылка       = СоздатьНовыйОбъект(ТипОбъекта, СвойстваПоиска, Объект, , , , НППСсылки,
					НППГлобальнойСсылки, ПараметрыОбъекта);

			КонецЕсли;

			ОписаниеТиповОбъекта = ЗагрузитьТипыОбъекта(ФайлОбмена);

			Если ОписаниеТиповОбъекта <> Неопределено Тогда

				Объект.ТипЗначения = ОписаниеТиповОбъекта;

			КонецЕсли;

		Иначе

			ЗаписатьВПротоколВыполнения(9);
			Прервать;

		КонецЕсли;

	КонецЦикла;

	Возврат Объект;

КонецФункции

// Выполняет проверку на наличие запрета загрузки по дате.
//
// Параметры:
//   ЭлементДанных	  - СправочникОбъект, ДокументОбъект, РегистрСведенийНаборЗаписей и др. данные.
//                      Данные, которые были зачитаны из сообщения обмена, но еще не были записаны в ИБ.
//   ПолучениеЭлемента - ПолучениеЭлементаДанных.
//
// Возвращаемое значение:
//   Булево - Истина - установлена дата запрета изменения и загружаемый объект имеет дату меньше установленной, иначе Ложь.
//
Функция ЗапретИзмененияДанныхПоДате(ЭлементДанных)

	ИзменениеЗапрещено = Ложь;

	Если МодульДатыЗапретаИзменения <> Неопределено И Не Метаданные.Константы.Содержит(ЭлементДанных.Метаданные()) Тогда
		Попытка
			Если МодульДатыЗапретаИзменения.ИзменениеЗапрещено(ЭлементДанных) Тогда
				ИзменениеЗапрещено = Истина;
			КонецЕсли;
		Исключение
			ИзменениеЗапрещено = Ложь;
		КонецПопытки;
	КонецЕсли;

	ЭлементДанных.ДополнительныеСвойства.Вставить("ПропуститьПроверкуЗапретаИзменения");

	Возврат ИзменениеЗапрещено;

КонецФункции

Функция ПроверитьСуществованиеСсылки(Ссылка, Менеджер, НайденныйОбъектПоУникальномуИдентификатору,
	СтрокаЗапросаПоискаПоУникальномуИдентификатору)

	Попытка

		Если ПустаяСтрока(СтрокаЗапросаПоискаПоУникальномуИдентификатору) Тогда

			НайденныйОбъектПоУникальномуИдентификатору = Ссылка.ПолучитьОбъект();

			Если НайденныйОбъектПоУникальномуИдентификатору = Неопределено Тогда

				Возврат Менеджер.ПустаяСсылка();

			КонецЕсли;

		Иначе
			// Это режим поиска по ссылке - достаточно сделать запрос к информационной базе
			// шаблон для запроса СтруктураСвойств.СтрокаПоиска.

			Запрос = Новый Запрос;
			Запрос.Текст = СтрокаЗапросаПоискаПоУникальномуИдентификатору + "  Ссылка = &Ссылка ";
			Запрос.УстановитьПараметр("Ссылка", Ссылка);

			РезультатЗапроса = Запрос.Выполнить();

			Если РезультатЗапроса.Пустой() Тогда

				Возврат Менеджер.ПустаяСсылка();

			КонецЕсли;

		КонецЕсли;

		Возврат Ссылка;

	Исключение

		Возврат Менеджер.ПустаяСсылка();

	КонецПопытки;

КонецФункции

Функция ВычислитьВыражение(Знач Выражение)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;
	
	// Вызов ВычислитьВБезопасномРежиме не требуется, т.к. безопасный режим устанавливается без использования средств БСП.
	Возврат Вычислить(Выражение);

КонецФункции

Функция HasObjectAttributeOrProperty(Объект, ИмяРеквизита)

	КлючУникальности   = Новый УникальныйИдентификатор;
	СтруктураРеквизита = Новый Структура(ИмяРеквизита, КлючУникальности);
	ЗаполнитьЗначенияСвойств(СтруктураРеквизита, Объект);

	Возврат СтруктураРеквизита[ИмяРеквизита] <> КлючУникальности;

КонецФункции

// Параметры:
//   Отбор - Отбор - произвольный отбор.
//   КлючЭлемента - Строка - имя элемента отбора.
//   ЗначениеЭлемента - Произвольный - значение элемента отбора.
//
Процедура УстановитьЗначениеЭлементаОтбора(Отбор, КлючЭлемента, ЗначениеЭлемента)

	ЭлементОтбора = Отбор.Найти(КлючЭлемента);
	Если ЭлементОтбора <> Неопределено Тогда
		ЭлементОтбора.Установить(ЗначениеЭлемента);
	КонецЕсли;

КонецПроцедуры

#КонецОбласти

#Область ПроцедурыВыгрузкиДанных

Функция ПолучитьНаборДвиженийДокумента(СсылкаНаДокумент, ВидИсточника, ИмяРегистра)

	Если ВидИсточника = "НаборДвиженийРегистраНакопления" Тогда

		НаборДвиженийДокумента = РегистрыНакопления[ИмяРегистра].СоздатьНаборЗаписей();

	ИначеЕсли ВидИсточника = "НаборДвиженийРегистраСведений" Тогда

		НаборДвиженийДокумента = РегистрыСведений[ИмяРегистра].СоздатьНаборЗаписей();

	ИначеЕсли ВидИсточника = "НаборДвиженийРегистраБухгалтерии" Тогда

		НаборДвиженийДокумента = РегистрыБухгалтерии[ИмяРегистра].СоздатьНаборЗаписей();

	ИначеЕсли ВидИсточника = "НаборДвиженийРегистраРасчета" Тогда

		НаборДвиженийДокумента = РегистрыРасчета[ИмяРегистра].СоздатьНаборЗаписей();

	Иначе

		Возврат Неопределено;

	КонецЕсли;

	УстановитьЗначениеЭлементаОтбора(НаборДвиженийДокумента.Отбор, "Регистратор", СсылкаНаДокумент);
	НаборДвиженийДокумента.Прочитать();

	Возврат НаборДвиженийДокумента;

КонецФункции

Процедура ВыполнитьЗаписьСтруктурыВXML(СтруктураДанных, УзелКоллекцииСвойств)

	УзелКоллекцииСвойств.ЗаписатьНачалоЭлемента("Свойство");

	Для Каждого ЭлементКоллекции Из СтруктураДанных Цикл

		Если ЭлементКоллекции.Ключ = "Выражение" Или ЭлементКоллекции.Ключ = "Значение" Или ЭлементКоллекции.Ключ = "Нпп"
			Или ЭлементКоллекции.Ключ = "ГНпп" Тогда

			одЗаписатьЭлемент(УзелКоллекцииСвойств, ЭлементКоллекции.Ключ, ЭлементКоллекции.Значение);

		ИначеЕсли ЭлементКоллекции.Ключ = "Ссылка" Тогда

			УзелКоллекцииСвойств.ЗаписатьБезОбработки(ЭлементКоллекции.Значение);

		Иначе

			УстановитьАтрибут(УзелКоллекцииСвойств, ЭлементКоллекции.Ключ, ЭлементКоллекции.Значение);

		КонецЕсли;

	КонецЦикла;

	УзелКоллекцииСвойств.ЗаписатьКонецЭлемента();

КонецПроцедуры

Процедура СоздатьОбъектыДляЗаписиДанныхВXML(СтруктураДанных, УзелСвойства, НуженУзелXML, ИмяУзла,
	НаименованиеУзлаXML = "Свойство")

	Если НуженУзелXML Тогда

		УзелСвойства = СоздатьУзел(НаименованиеУзлаXML);
		УстановитьАтрибут(УзелСвойства, "Имя", ИмяУзла);

	Иначе

		СтруктураДанных = Новый Структура("Имя", ИмяУзла);

	КонецЕсли;

КонецПроцедуры

Процедура ДобавитьАтрибутДляЗаписиВXML(СтруктураУзлаСвойств, УзелСвойства, ИмяАтрибута, ЗначениеАтрибута)

	Если СтруктураУзлаСвойств <> Неопределено Тогда
		СтруктураУзлаСвойств.Вставить(ИмяАтрибута, ЗначениеАтрибута);
	Иначе
		УстановитьАтрибут(УзелСвойства, ИмяАтрибута, ЗначениеАтрибута);
	КонецЕсли;

КонецПроцедуры

Процедура ПроизвестиЗаписьДанныхВГоловнойУзел(УзелКоллекцииСвойств, СтруктураУзлаСвойств, УзелСвойства)

	Если СтруктураУзлаСвойств <> Неопределено Тогда
		ВыполнитьЗаписьСтруктурыВXML(СтруктураУзлаСвойств, УзелКоллекцииСвойств);
	Иначе
		ДобавитьПодчиненный(УзелКоллекцииСвойств, УзелСвойства);
	КонецЕсли;

КонецПроцедуры

// Формирует узлы свойств объекта приемника в соответствии с указанной коллекцией правил конвертации свойств.
//
// Параметры:
//  Источник		     - произвольный источник данных.
//  Приемник		     - xml-узел объекта приемника.
//  ВходящиеДанные	     - произвольные вспомогательные данные, передаваемые правилу
//                         для выполнения конвертации.
//  ИсходящиеДанные      - произвольные вспомогательные данные, передаваемые правилам
//                         конвертации объектов свойств.
//  ПКО				     - ссылка на правило конвертации объектов (родитель коллекции правил конвертации свойств).
//  ПКГС                 - ссылка на правило конвертации группы свойств.
//  УзелКоллекцииСвойств - xml-узел коллекции свойств.
// 
Процедура ВыгрузитьГруппуСвойств(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, ПКГС, УзелКоллекцииСвойств,
	ВыгрузитьТолькоСсылку, СписокВременныхФайлов = Неопределено)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	КоллекцияОбъектов = Неопределено;
	НеЗамещать        = ПКГС.НеЗамещать;
	НеОчищать         = Ложь;
	ВыгружатьГруппуЧерезФайл = ПКГС.ВыгружатьГруппуЧерезФайл;
	
	// Обработчик ПередОбработкойВыгрузки
	Если ПКГС.ЕстьОбработчикПередОбработкойВыгрузки Тогда

		Отказ = Ложь;
		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКГС, "ПередОбработкойВыгрузки"));

			Иначе

				Выполнить (ПКГС.ПередОбработкойВыгрузки);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикиПКС(48, ОписаниеОшибки(), ПКО, ПКГС, Источник,
				"ПередОбработкойВыгрузкиГруппыСвойств", , Ложь);

		КонецПопытки;

		Если Отказ Тогда // Отказ от обработки группы свойств.

			Возврат;

		КонецЕсли;

	КонецЕсли;
	ВидПриемника = ПКГС.ВидПриемника;
	ВидИсточника = ПКГС.ВидИсточника;
	
	
    // Создание узла коллекции подчиненных объектов.
	СтруктураУзлаСвойств = Неопределено;
	УзелКоллекцииОбъектов = Неопределено;
	ИмяГоловногоУзла = "";

	Если ВидПриемника = "ТабличнаяЧасть" Тогда

		ИмяГоловногоУзла = "ТабличнаяЧасть";

		СоздатьОбъектыДляЗаписиДанныхВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, Истина, ПКГС.Приемник,
			ИмяГоловногоУзла);

		Если НеЗамещать Тогда

			ДобавитьАтрибутДляЗаписиВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, "НеЗамещать", "true");

		КонецЕсли;

		Если НеОчищать Тогда

			ДобавитьАтрибутДляЗаписиВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, "НеОчищать", "true");

		КонецЕсли;

	ИначеЕсли ВидПриемника = "ПодчиненныйСправочник" Тогда
	ИначеЕсли ВидПриемника = "НаборЗаписейПоследовательности" Тогда

		ИмяГоловногоУзла = "НаборЗаписей";

		СоздатьОбъектыДляЗаписиДанныхВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, Истина, ПКГС.Приемник,
			ИмяГоловногоУзла);

	ИначеЕсли СтрНайти(ВидПриемника, "НаборДвижений") > 0 Тогда

		ИмяГоловногоУзла = "НаборЗаписей";

		СоздатьОбъектыДляЗаписиДанныхВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, Истина, ПКГС.Приемник,
			ИмяГоловногоУзла);

		Если НеЗамещать Тогда

			ДобавитьАтрибутДляЗаписиВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, "НеЗамещать", "true");

		КонецЕсли;

		Если НеОчищать Тогда

			ДобавитьАтрибутДляЗаписиВXML(СтруктураУзлаСвойств, УзелКоллекцииОбъектов, "НеОчищать", "true");

		КонецЕсли;

	Иначе  // это простая группировка

		ВыгрузитьСвойства(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, ПКГС.ПравилаГруппы,
			УзелКоллекцииСвойств, , , ПКО.НеВыгружатьОбъектыСвойствПоСсылкам Или ВыгрузитьТолькоСсылку);

		Если ПКГС.ЕстьОбработчикПослеОбработкиВыгрузки Тогда

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКГС, "ПослеОбработкиВыгрузки"));

				Иначе

					Выполнить (ПКГС.ПослеОбработкиВыгрузки);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(49, ОписаниеОшибки(), ПКО, ПКГС, Источник,
					"ПослеОбработкиВыгрузкиГруппыСвойств", , Ложь);

			КонецПопытки;

		КонецЕсли;

		Возврат;

	КонецЕсли;
	
	// Получение коллекции подчиненных объектов.

	Если КоллекцияОбъектов <> Неопределено Тогда
		
		// Инициализировали коллекцию в обработчике ПередОбработкой.

	ИначеЕсли ПКГС.ПолучитьИзВходящихДанных Тогда

		Попытка

			КоллекцияОбъектов = ВходящиеДанные[ПКГС.Приемник];

			Если ТипЗнч(КоллекцияОбъектов) = Тип("РезультатЗапроса") Тогда

				КоллекцияОбъектов = КоллекцияОбъектов.Выгрузить();

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикиПКС(66, ОписаниеОшибки(), ПКО, ПКГС, Источник, , , Ложь);

			Возврат;
		КонецПопытки;

	ИначеЕсли ВидИсточника = "ТабличнаяЧасть" Тогда

		КоллекцияОбъектов = Источник[ПКГС.Источник];

		Если ТипЗнч(КоллекцияОбъектов) = Тип("РезультатЗапроса") Тогда

			КоллекцияОбъектов = КоллекцияОбъектов.Выгрузить();

		КонецЕсли;

	ИначеЕсли ВидИсточника = "ПодчиненныйСправочник" Тогда

	ИначеЕсли СтрНайти(ВидИсточника, "НаборДвижений") > 0 Тогда

		КоллекцияОбъектов = ПолучитьНаборДвиженийДокумента(Источник, ВидИсточника, ПКГС.Источник);

	ИначеЕсли ПустаяСтрока(ПКГС.Источник) Тогда

		КоллекцияОбъектов = Источник[ПКГС.Приемник];

		Если ТипЗнч(КоллекцияОбъектов) = Тип("РезультатЗапроса") Тогда

			КоллекцияОбъектов = КоллекцияОбъектов.Выгрузить();

		КонецЕсли;

	КонецЕсли;

	ВыгружатьГруппуЧерезФайл = ВыгружатьГруппуЧерезФайл Или (КоллекцияОбъектов.Количество() > 1000);
	ВыгружатьГруппуЧерезФайл = ВыгружатьГруппуЧерезФайл И (DirectReadFromDestinationIB = Ложь);

	Если ВыгружатьГруппуЧерезФайл Тогда

		ПКГС.НуженУзелXMLПриВыгрузке = Ложь;

		Если СписокВременныхФайлов = Неопределено Тогда
			СписокВременныхФайлов = Новый Массив;
		КонецЕсли;

		ВременныйФайлЗаписей = ЗаписьТекстаВоВременныйФайл(СписокВременныхФайлов);

		ИнформацияДляЗаписиВФайл = УзелКоллекцииОбъектов.Закрыть();
		ВременныйФайлЗаписей.ЗаписатьСтроку(ИнформацияДляЗаписиВФайл);

	КонецЕсли;

	Для Каждого ОбъектКоллекции Из КоллекцияОбъектов Цикл
		
		// Обработчик ПередВыгрузкой
		Если ПКГС.ЕстьОбработчикПередВыгрузкой Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКГС, "ПередВыгрузкой"));

				Иначе

					Выполнить (ПКГС.ПередВыгрузкой);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(50, ОписаниеОшибки(), ПКО, ПКГС, Источник,
					"ПередВыгрузкойГруппыСвойств", , Ложь);

				Прервать;

			КонецПопытки;

			Если Отказ Тогда	//	Отказ от выгрузки подчиненного объекта.

				Продолжить;

			КонецЕсли;

		КонецЕсли;
		
		// Обработчик ПриВыгрузке

		Если ПКГС.НуженУзелXMLПриВыгрузке Или ВыгружатьГруппуЧерезФайл Тогда
			УзелОбъектаКоллекции = СоздатьУзел("Запись");
		Иначе
			УзелКоллекцииОбъектов.ЗаписатьНачалоЭлемента("Запись");
			УзелОбъектаКоллекции = УзелКоллекцииОбъектов;
		КонецЕсли;

		СтандартнаяОбработка	= Истина;

		Если ПКГС.ЕстьОбработчикПриВыгрузке Тогда

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКГС, "ПриВыгрузке"));

				Иначе

					Выполнить (ПКГС.ПриВыгрузке);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(51, ОписаниеОшибки(), ПКО, ПКГС, Источник,
					"ПриВыгрузкеГруппыСвойств", , Ложь);

				Прервать;

			КонецПопытки;

		КонецЕсли;

		//	Выгрузка свойств объекта коллекции.

		Если СтандартнаяОбработка Тогда

			Если ПКГС.ПравилаГруппы.Количество() > 0 Тогда

				ВыгрузитьСвойства(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, ПКГС.ПравилаГруппы,
					УзелОбъектаКоллекции, ОбъектКоллекции, , ПКО.НеВыгружатьОбъектыСвойствПоСсылкам
					Или ВыгрузитьТолькоСсылку);

			КонецЕсли;

		КонецЕсли;
		
		// Обработчик ПослеВыгрузки

		Если ПКГС.ЕстьОбработчикПослеВыгрузки Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКГС, "ПослеВыгрузки"));

				Иначе

					Выполнить (ПКГС.ПослеВыгрузки);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(52, ОписаниеОшибки(), ПКО, ПКГС, Источник,
					"ПослеВыгрузкиГруппыСвойств", , Ложь);

				Прервать;
			КонецПопытки;

			Если Отказ Тогда	//	Отказ от выгрузки подчиненного объекта.

				Продолжить;

			КонецЕсли;

		КонецЕсли;

		Если ПКГС.НуженУзелXMLПриВыгрузке Тогда
			ДобавитьПодчиненный(УзелКоллекцииОбъектов, УзелОбъектаКоллекции);
		КонецЕсли;
		
		// Заполняем файл объектами узла.
		Если ВыгружатьГруппуЧерезФайл Тогда

			УзелОбъектаКоллекции.ЗаписатьКонецЭлемента();
			ИнформацияДляЗаписиВФайл = УзелОбъектаКоллекции.Закрыть();
			ВременныйФайлЗаписей.ЗаписатьСтроку(ИнформацияДляЗаписиВФайл);

		Иначе

			Если Не ПКГС.НуженУзелXMLПриВыгрузке Тогда

				УзелКоллекцииОбъектов.ЗаписатьКонецЭлемента();

			КонецЕсли;

		КонецЕсли;

	КонецЦикла;
	
	
    // Обработчик ПослеОбработкиВыгрузки

	Если ПКГС.ЕстьОбработчикПослеОбработкиВыгрузки Тогда

		Отказ = Ложь;

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКГС, "ПослеОбработкиВыгрузки"));

			Иначе

				Выполнить (ПКГС.ПослеОбработкиВыгрузки);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикиПКС(49, ОписаниеОшибки(), ПКО, ПКГС, Источник,
				"ПослеОбработкиВыгрузкиГруппыСвойств", , Ложь);

		КонецПопытки;

		Если Отказ Тогда	//	Отказ от записи коллекции подчиненных объектов.

			Возврат;

		КонецЕсли;

	КонецЕсли;

	Если ВыгружатьГруппуЧерезФайл Тогда
		ВременныйФайлЗаписей.ЗаписатьСтроку("</" + ИмяГоловногоУзла + ">"); // закрыть узел
		ВременныйФайлЗаписей.Закрыть(); 	// закрыть файл явно
	Иначе
		ПроизвестиЗаписьДанныхВГоловнойУзел(УзелКоллекцииСвойств, СтруктураУзлаСвойств, УзелКоллекцииОбъектов);
	КонецЕсли;

КонецПроцедуры

Процедура ПолучитьЗначениеСвойства(Значение, ОбъектКоллекции, ПКО, ПКС, ВходящиеДанные, Источник)

	Если Значение <> Неопределено Тогда
		Возврат;
	КонецЕсли;

	Если ПКС.ПолучитьИзВходящихДанных Тогда

		ОбъектДляПолученияДанных = ВходящиеДанные;

		Если Не ПустаяСтрока(ПКС.Приемник) Тогда

			ИмяСвойства = ПКС.Приемник;

		Иначе

			ИмяСвойства = ПКС.ИмяПараметраДляПередачи;

		КонецЕсли;

		КодОшибки = ?(ОбъектКоллекции <> Неопределено, 67, 68);

	ИначеЕсли ОбъектКоллекции <> Неопределено Тогда

		ОбъектДляПолученияДанных = ОбъектКоллекции;

		Если Не ПустаяСтрока(ПКС.Источник) Тогда

			ИмяСвойства = ПКС.Источник;
			КодОшибки = 16;

		Иначе

			ИмяСвойства = ПКС.Приемник;
			КодОшибки = 17;

		КонецЕсли;

	Иначе

		ОбъектДляПолученияДанных = Источник;

		Если Не ПустаяСтрока(ПКС.Источник) Тогда

			ИмяСвойства = ПКС.Источник;
			КодОшибки = 13;

		Иначе

			ИмяСвойства = ПКС.Приемник;
			КодОшибки = 14;

		КонецЕсли;

	КонецЕсли;

	Попытка

		Значение = ОбъектДляПолученияДанных[ИмяСвойства];

	Исключение

		Если КодОшибки <> 14 Тогда
			ЗаписатьИнформациюОбОшибкеОбработчикиПКС(КодОшибки, ОписаниеОшибки(), ПКО, ПКС, Источник, "");
		КонецЕсли;

	КонецПопытки;

КонецПроцедуры

Процедура ВыгрузитьТипСвойстваЭлемента(УзелСвойства, ТипСвойства)

	УстановитьАтрибут(УзелСвойства, "Тип", ТипСвойства);

КонецПроцедуры

Процедура ВыгрузитьСубконто(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, ПКС, УзелКоллекцииСвойств,
	ОбъектКоллекции, Знач ВыгрузитьТолькоСсылку)
	
	//
	// Переменные-заглушки для поддержки механизма отладки кода обработчиков событий
	// (поддержка интерфейса процедуры-обертки обработчика).
	Перем ТипПриемника, Пусто, Выражение, НеЗамещать, УзелСвойства, ПКОСвойств;

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;
	
	// Инициализация значения
	Значение = Неопределено;
	ИмяПКО = "";
	ИмяПКОВидСубконто = "";
	
	// Обработчик ПередВыгрузкой
	Если ПКС.ЕстьОбработчикПередВыгрузкой Тогда

		Отказ = Ложь;

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКС, "ПередВыгрузкой"));

			Иначе

				Выполнить (ПКС.ПередВыгрузкой);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикиПКС(55, ОписаниеОшибки(), ПКО, ПКС, Источник,
				"ПередВыгрузкойСвойства", Значение);

		КонецПопытки;

		Если Отказ Тогда // Отказ от выгрузки

			Возврат;

		КонецЕсли;

	КонецЕсли;

	ПолучитьЗначениеСвойства(Значение, ОбъектКоллекции, ПКО, ПКС, ВходящиеДанные, Источник);

	Если ПКС.ПриводитьКДлине <> 0 Тогда

		ВыполнитьПриведениеЗначенияКДлине(Значение, ПКС);

	КонецЕсли;

	Для Каждого КлючИЗначение Из Значение Цикл

		ВидСубконто = КлючИЗначение.Ключ;
		Субконто = КлючИЗначение.Значение;
		ИмяПКО = "";
		
		// Обработчик ПриВыгрузке
		Если ПКС.ЕстьОбработчикПриВыгрузке Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКС, "ПриВыгрузке"));

				Иначе

					Выполнить (ПКС.ПриВыгрузке);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(56, ОписаниеОшибки(), ПКО, ПКС, Источник,
					"ПриВыгрузкеСвойства", Значение);

			КонецПопытки;

			Если Отказ Тогда // Отказ от выгрузки субконто

				Продолжить;

			КонецЕсли;

		КонецЕсли;

		Если Субконто = Неопределено Или НайтиПравило(Субконто, ИмяПКО) = Неопределено Тогда

			Продолжить;

		КонецЕсли;

		УзелСубконто = СоздатьУзел(ПКС.Приемник);
		
		// Ключ
		УзелСвойства = СоздатьУзел("Свойство");

		Если ПустаяСтрока(ИмяПКОВидСубконто) Тогда

			ПКОКлюч = НайтиПравило(ВидСубконто, ИмяПКОВидСубконто);

		Иначе

			ПКОКлюч = НайтиПравило( , ИмяПКОВидСубконто);

		КонецЕсли;

		УстановитьАтрибут(УзелСвойства, "Имя", "Ключ");
		ВыгрузитьТипСвойстваЭлемента(УзелСвойства, ПКОКлюч.Приемник);

		УзелСсылки = ВыгрузитьПоПравилу(ВидСубконто, , ИсходящиеДанные, , ИмяПКОВидСубконто, , ВыгрузитьТолькоСсылку,
			ПКОКлюч);

		Если УзелСсылки <> Неопределено Тогда

			ЭтоПравилоСГлобальнойВыгрузкой = Ложь;
			ТипУзлаСсылки = ТипЗнч(УзелСсылки);
			ДобавитьСвойстваДляВыгрузки(УзелСсылки, ТипУзлаСсылки, УзелСвойства, ЭтоПравилоСГлобальнойВыгрузкой);

		КонецЕсли;

		ДобавитьПодчиненный(УзелСубконто, УзелСвойства);
		
		// Значение
		УзелСвойства = СоздатьУзел("Свойство");

		ПКОЗначение = НайтиПравило(Субконто, ИмяПКО);

		ТипПриемника = ПКОЗначение.Приемник;

		ЭтоNULL = Ложь;
		Пусто = одПустое(Субконто, ЭтоNULL);

		Если Пусто Тогда

			Если ЭтоNULL Или Субконто = Неопределено Тогда

				Продолжить;

			КонецЕсли;

			Если ПустаяСтрока(ТипПриемника) Тогда

				ТипПриемника = ОпределитьТипДанныхДляПриемника(Субконто);

			КонецЕсли;

			УстановитьАтрибут(УзелСвойства, "Имя", "Значение");

			Если Не ПустаяСтрока(ТипПриемника) Тогда
				УстановитьАтрибут(УзелСвойства, "Тип", ТипПриемника);
			КонецЕсли;
			
			// Если тип множественный, то возможно это пустая ссылка и выгрузить ее нужно именно с указанием типа.
			одЗаписатьЭлемент(УзелСвойства, "Пусто");

			ДобавитьПодчиненный(УзелСубконто, УзелСвойства);

		Иначе

			ЭтоПравилоСГлобальнойВыгрузкой = Ложь;
			УзелСсылки = ВыгрузитьПоПравилу(Субконто, , ИсходящиеДанные, , ИмяПКО, , ВыгрузитьТолькоСсылку,
				ПКОЗначение, ЭтоПравилоСГлобальнойВыгрузкой);

			УстановитьАтрибут(УзелСвойства, "Имя", "Значение");
			ВыгрузитьТипСвойстваЭлемента(УзелСвойства, ТипПриемника);

			Если УзелСсылки = Неопределено Тогда

				Продолжить;

			КонецЕсли;

			ТипУзлаСсылки = ТипЗнч(УзелСсылки);

			ДобавитьСвойстваДляВыгрузки(УзелСсылки, ТипУзлаСсылки, УзелСвойства, ЭтоПравилоСГлобальнойВыгрузкой);

			ДобавитьПодчиненный(УзелСубконто, УзелСвойства);

		КонецЕсли;
		
		// Обработчик ПослеВыгрузки
		Если ПКС.ЕстьОбработчикПослеВыгрузки Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКС, "ПослеВыгрузки"));

				Иначе

					Выполнить (ПКС.ПослеВыгрузки);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(57, ОписаниеОшибки(), ПКО, ПКС, Источник,
					"ПослеВыгрузкиСвойства", Значение);

			КонецПопытки;

			Если Отказ Тогда // Отказ от выгрузки

				Продолжить;

			КонецЕсли;

		КонецЕсли;

		ДобавитьПодчиненный(УзелКоллекцииСвойств, УзелСубконто);

	КонецЦикла;

КонецПроцедуры

Процедура ДобавитьСвойстваДляВыгрузки(УзелСсылки, ТипУзлаСсылки, УзелСвойства, ЭтоПравилоСГлобальнойВыгрузкой)

	Если ТипУзлаСсылки = одТипСтрока Тогда

		Если СтрНайти(УзелСсылки, "<Ссылка") > 0 Тогда

			УзелСвойства.ЗаписатьБезОбработки(УзелСсылки);

		Иначе

			одЗаписатьЭлемент(УзелСвойства, "Значение", УзелСсылки);

		КонецЕсли;

	ИначеЕсли ТипУзлаСсылки = одТипЧисло Тогда

		Если ЭтоПравилоСГлобальнойВыгрузкой Тогда

			одЗаписатьЭлемент(УзелСвойства, "ГНпп", УзелСсылки);

		Иначе

			одЗаписатьЭлемент(УзелСвойства, "Нпп", УзелСсылки);

		КонецЕсли;

	Иначе

		ДобавитьПодчиненный(УзелСвойства, УзелСсылки);

	КонецЕсли;

КонецПроцедуры

Процедура ДобавитьЗначениеСвойстваВУзел(Значение, ТипЗначения, ТипПриемника, УзелСвойства, СвойствоУстановлено)

	СвойствоУстановлено = Истина;

	Если ТипЗначения = одТипСтрока Тогда

		Если ТипПриемника = "Строка" Тогда
		ИначеЕсли ТипПриемника = "Число" Тогда

			Значение = Число(Значение);

		ИначеЕсли ТипПриемника = "Булево" Тогда

			Значение = Булево(Значение);

		ИначеЕсли ТипПриемника = "Дата" Тогда

			Значение = Дата(Значение);

		ИначеЕсли ТипПриемника = "ХранилищеЗначения" Тогда

			Значение = Новый ХранилищеЗначения(Значение);

		ИначеЕсли ТипПриемника = "УникальныйИдентификатор" Тогда

			Значение = Новый УникальныйИдентификатор(Значение);

		ИначеЕсли ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", "Строка");

		КонецЕсли;

		одЗаписатьЭлемент(УзелСвойства, "Значение", Значение);

	ИначеЕсли ТипЗначения = одТипЧисло Тогда

		Если ТипПриемника = "Число" Тогда
		ИначеЕсли ТипПриемника = "Булево" Тогда

			Значение = Булево(Значение);

		ИначеЕсли ТипПриемника = "Строка" Тогда
		ИначеЕсли ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", "Число");

		Иначе

			Возврат;

		КонецЕсли;

		одЗаписатьЭлемент(УзелСвойства, "Значение", Значение);

	ИначеЕсли ТипЗначения = одТипДата Тогда

		Если ТипПриемника = "Дата" Тогда
		ИначеЕсли ТипПриемника = "Строка" Тогда

			Значение = Лев(Строка(Значение), 10);

		ИначеЕсли ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", "Дата");

		Иначе

			Возврат;

		КонецЕсли;

		одЗаписатьЭлемент(УзелСвойства, "Значение", Значение);

	ИначеЕсли ТипЗначения = одТипБулево Тогда

		Если ТипПриемника = "Булево" Тогда
		ИначеЕсли ТипПриемника = "Число" Тогда

			Значение = Число(Значение);

		ИначеЕсли ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", "Булево");

		Иначе

			Возврат;

		КонецЕсли;

		одЗаписатьЭлемент(УзелСвойства, "Значение", Значение);

	ИначеЕсли ТипЗначения = одТипХранилищеЗначения Тогда

		Если ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", "ХранилищеЗначения");

		ИначеЕсли ТипПриемника <> "ХранилищеЗначения" Тогда

			Возврат;

		КонецЕсли;

		одЗаписатьЭлемент(УзелСвойства, "Значение", Значение);

	ИначеЕсли ТипЗначения = одТипУникальныйИдентификатор Тогда

		Если ТипПриемника = "УникальныйИдентификатор" Тогда
		ИначеЕсли ТипПриемника = "Строка" Тогда

			Значение = Строка(Значение);

		ИначеЕсли ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", "УникальныйИдентификатор");

		Иначе

			Возврат;

		КонецЕсли;

		одЗаписатьЭлемент(УзелСвойства, "Значение", Значение);

	ИначеЕсли ТипЗначения = одТипВидДвиженияНакопления Тогда

		одЗаписатьЭлемент(УзелСвойства, "Значение", Строка(Значение));

	Иначе

		СвойствоУстановлено = Ложь;

	КонецЕсли;

КонецПроцедуры

Функция ВыгрузитьДанныеСсылочногоОбъекта(Значение, ИсходящиеДанные, ИмяПКО, ПКОСвойств, ТипПриемника, УзелСвойства,
	Знач ВыгрузитьТолькоСсылку)

	ЭтоПравилоСГлобальнойВыгрузкой = Ложь;
	УзелСсылки    = ВыгрузитьПоПравилу(Значение, , ИсходящиеДанные, , ИмяПКО, , ВыгрузитьТолькоСсылку, ПКОСвойств,
		ЭтоПравилоСГлобальнойВыгрузкой);
	ТипУзлаСсылки = ТипЗнч(УзелСсылки);

	Если ПустаяСтрока(ТипПриемника) Тогда

		ТипПриемника  = ПКОСвойств.Приемник;
		УстановитьАтрибут(УзелСвойства, "Тип", ТипПриемника);

	КонецЕсли;

	Если УзелСсылки = Неопределено Тогда

		Возврат Неопределено;

	КонецЕсли;

	ДобавитьСвойстваДляВыгрузки(УзелСсылки, ТипУзлаСсылки, УзелСвойства, ЭтоПравилоСГлобальнойВыгрузкой);

	Возврат УзелСсылки;

КонецФункции

Функция ОпределитьТипДанныхДляПриемника(Значение)

	ТипПриемника = одТипЗначенияСтрокой(Значение);
	
	// Есть ли хоть какое ПКО с типом приемника ТипПриемника
	// если правила нет - то "", если есть , то то что нашли оставляем.
	СтрокаТаблицы = ConversionRulesTable.Найти(ТипПриемника, "Приемник");

	Если СтрокаТаблицы = Неопределено Тогда
		ТипПриемника = "";
	КонецЕсли;

	Возврат ТипПриемника;

КонецФункции

Процедура ВыполнитьПриведениеЗначенияКДлине(Значение, ПКС)

	Значение = ПривестиНомерКДлине(Строка(Значение), ПКС.ПриводитьКДлине);

КонецПроцедуры

// Формирует узлы свойств объекта приемника в соответствии с указанной коллекцией правил конвертации свойств.
//
// Параметры:
//  Источник		     - Произвольный - произвольный источник данных.
//  Приемник		     - ЗаписьXML - xml-узел объекта приемника.
//  ВходящиеДанные	     - Произвольный - произвольные вспомогательные данные, передаваемые правилу
//                         для выполнения конвертации.
//  ИсходящиеДанные      - Произвольный - произвольные вспомогательные данные, передаваемые правилам
//                         конвертации объектов свойств.
//  ПКО				     - СтрокаТаблицыЗначений - ссылка на правило конвертации объектов.
//  КоллекцияПКС         - см. КоллекцияПравилаКонвертацииСвойств
//  УзелКоллекцииСвойств - ЗаписьXML - xml-узел коллекции свойств.
//  ОбъектКоллекции      - Произвольный - если указан, то выполняется выгрузка свойств объекта коллекции, иначе Источника.
//  ИмяПредопределенногоЭлемента - Строка - если указан, то в свойствах пишется имя предопределенного элемента.
//  ПКГС                 - ссылка на правило конвертации группы свойств (папка-родитель коллекции ПКС). 
//                         Например, табличная часть документа.
// 
Процедура ВыгрузитьСвойства(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, КоллекцияПКС,
	УзелКоллекцииСвойств = Неопределено, ОбъектКоллекции = Неопределено, ИмяПредопределенногоЭлемента = Неопределено,
	Знач ВыгрузитьТолькоСсылку = Ложь, СписокВременныхФайлов = Неопределено)

	Перем КлючИЗначение, ВидСубконто, Субконто, ИмяПКОВидСубконто, УзелСубконто; // Пустышки, для корректного запуска
	                                                                             // обработчиков.

	Если УзелКоллекцииСвойств = Неопределено Тогда

		УзелКоллекцииСвойств = Приемник;

	КонецЕсли;
	
	// Выгружаем имя предопределенного если оно указано.
	Если ИмяПредопределенногоЭлемента <> Неопределено Тогда

		УзелКоллекцииСвойств.ЗаписатьНачалоЭлемента("Свойство");
		УстановитьАтрибут(УзелКоллекцииСвойств, "Имя", "{ИмяПредопределенногоЭлемента}");
		Если Не ExecuteDataExchangeInOptimizedFormat Тогда
			УстановитьАтрибут(УзелКоллекцииСвойств, "Тип", "Строка");
		КонецЕсли;
		одЗаписатьЭлемент(УзелКоллекцииСвойств, "Значение", ИмяПредопределенногоЭлемента);
		УзелКоллекцииСвойств.ЗаписатьКонецЭлемента();

	КонецЕсли;

	Для Каждого ПКС Из КоллекцияПКС Цикл

		Если ПКС.УпрощеннаяВыгрузкаСвойства Тогда
						
			 //	Создаем узел свойства

			УзелКоллекцииСвойств.ЗаписатьНачалоЭлемента("Свойство");
			УстановитьАтрибут(УзелКоллекцииСвойств, "Имя", ПКС.Приемник);

			Если Не ExecuteDataExchangeInOptimizedFormat И Не ПустаяСтрока(ПКС.ТипПриемника) Тогда

				УстановитьАтрибут(УзелКоллекцииСвойств, "Тип", ПКС.ТипПриемника);

			КонецЕсли;

			Если ПКС.НеЗамещать Тогда

				УстановитьАтрибут(УзелКоллекцииСвойств, "НеЗамещать", "true");

			КонецЕсли;

			Если ПКС.ПоискПоДатеНаРавенство Тогда

				УстановитьАтрибут(УзелКоллекцииСвойств, "ПоискПоДатеНаРавенство", "true");

			КонецЕсли;

			Значение = Неопределено;
			ПолучитьЗначениеСвойства(Значение, ОбъектКоллекции, ПКО, ПКС, ВходящиеДанные, Источник);

			Если ПКС.ПриводитьКДлине <> 0 Тогда

				ВыполнитьПриведениеЗначенияКДлине(Значение, ПКС);

			КонецЕсли;

			ЭтоNULL = Ложь;
			Пусто = одПустое(Значение, ЭтоNULL);

			Если Пусто Тогда
				
				// Надо записать что это пустое значение.
				Если Не ExecuteDataExchangeInOptimizedFormat Тогда
					одЗаписатьЭлемент(УзелКоллекцииСвойств, "Пусто");
				КонецЕсли;

				УзелКоллекцииСвойств.ЗаписатьКонецЭлемента();
				Продолжить;

			КонецЕсли;

			одЗаписатьЭлемент(УзелКоллекцииСвойств, "Значение", Значение);

			УзелКоллекцииСвойств.ЗаписатьКонецЭлемента();
			Продолжить;

		ИначеЕсли ПКС.ВидПриемника = "ВидыСубконтоСчета" Тогда

			ВыгрузитьСубконто(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, ПКС, УзелКоллекцииСвойств,
				ОбъектКоллекции, ВыгрузитьТолькоСсылку);

			Продолжить;

		ИначеЕсли ПКС.Имя = "{УникальныйИдентификатор}" И ПКС.Источник = "{УникальныйИдентификатор}" И ПКС.Приемник
			= "{УникальныйИдентификатор}" Тогда

			Если Источник = Неопределено Тогда
				Продолжить;
			КонецЕсли;

			Если ЗначениеСсылочногоТипа(Источник) Тогда
				УникальныйИдентификатор = Источник.УникальныйИдентификатор();
			Иначе

				НачальноеЗначение = Новый УникальныйИдентификатор;
				СтруктураДляПроверкиНаличияСвойства = Новый Структура("Ссылка", НачальноеЗначение);
				ЗаполнитьЗначенияСвойств(СтруктураДляПроверкиНаличияСвойства, Источник);

				Если НачальноеЗначение <> СтруктураДляПроверкиНаличияСвойства.Ссылка И ЗначениеСсылочногоТипа(
					СтруктураДляПроверкиНаличияСвойства.Ссылка) Тогда
					УникальныйИдентификатор = Источник.Ссылка.УникальныйИдентификатор();
				КонецЕсли;

			КонецЕсли;

			УзелКоллекцииСвойств.ЗаписатьНачалоЭлемента("Свойство");
			УстановитьАтрибут(УзелКоллекцииСвойств, "Имя", "{УникальныйИдентификатор}");

			Если Не ExecuteDataExchangeInOptimizedFormat Тогда
				УстановитьАтрибут(УзелКоллекцииСвойств, "Тип", "Строка");
			КонецЕсли;

			одЗаписатьЭлемент(УзелКоллекцииСвойств, "Значение", УникальныйИдентификатор);
			УзелКоллекцииСвойств.ЗаписатьКонецЭлемента();
			Продолжить;

		ИначеЕсли ПКС.ЭтоГруппа Тогда

			ВыгрузитьГруппуСвойств(Источник, Приемник, ВходящиеДанные, ИсходящиеДанные, ПКО, ПКС, УзелКоллекцииСвойств,
				ВыгрузитьТолькоСсылку, СписокВременныхФайлов);
			Продолжить;

		КонецЕсли;

		
		//	Инициализируем значение, которое будем конвертировать.
		Значение 	 = Неопределено;
		ИмяПКО		 = ПКС.ПравилоКонвертации;
		НеЗамещать   = ПКС.НеЗамещать;

		Пусто		 = Ложь;
		Выражение	 = Неопределено;
		ТипПриемника = ПКС.ТипПриемника;

		ЭтоNULL      = Ложь;

		
		// Обработчик ПередВыгрузкой
		Если ПКС.ЕстьОбработчикПередВыгрузкой Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКС, "ПередВыгрузкой"));

				Иначе

					Выполнить (ПКС.ПередВыгрузкой);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(55, ОписаниеОшибки(), ПКО, ПКС, Источник,
					"ПередВыгрузкойСвойства", Значение);

			КонецПопытки;

			Если Отказ Тогда	//	Отказ от выгрузки свойства

				Продолжить;

			КонецЕсли;

		КонецЕсли;

        		
        //	Создаем узел свойства
		Если ПустаяСтрока(ПКС.ИмяПараметраДляПередачи) Тогда

			УзелСвойства = СоздатьУзел("Свойство");
			УстановитьАтрибут(УзелСвойства, "Имя", ПКС.Приемник);

		Иначе

			УзелСвойства = СоздатьУзел("ЗначениеПараметра");
			УстановитьАтрибут(УзелСвойства, "Имя", ПКС.ИмяПараметраДляПередачи);

		КонецЕсли;

		Если НеЗамещать Тогда

			УстановитьАтрибут(УзелСвойства, "НеЗамещать", "true");

		КонецЕсли;

		Если ПКС.ПоискПоДатеНаРавенство Тогда

			УстановитьАтрибут(УзелКоллекцииСвойств, "ПоискПоДатеНаРавенство", "true");

		КонецЕсли;

        		
		//	Возможно правило конвертации уже определено.
		Если Не ПустаяСтрока(ИмяПКО) Тогда

			ПКОСвойств = Правила[ИмяПКО];

		Иначе

			ПКОСвойств = Неопределено;

		КонецЕсли;


		//	Попытка определить тип свойства приемника.
		Если ПустаяСтрока(ТипПриемника) И ПКОСвойств <> Неопределено Тогда

			ТипПриемника = ПКОСвойств.Приемник;
			УстановитьАтрибут(УзелСвойства, "Тип", ТипПриемника);

		ИначеЕсли Не ExecuteDataExchangeInOptimizedFormat И Не ПустаяСтрока(ТипПриемника) Тогда

			УстановитьАтрибут(УзелСвойства, "Тип", ТипПриемника);

		КонецЕсли;

		Если Не ПустаяСтрока(ИмяПКО) И ПКОСвойств <> Неопределено
			И ПКОСвойств.ЕстьОбработчикПоследовательностьПолейПоиска = Истина Тогда

			УстановитьАтрибут(УзелСвойства, "ИмяПКО", ИмяПКО);

		КонецЕсли;
		
        //	Определяем конвертируемое значение.
		Если Выражение <> Неопределено Тогда

			одЗаписатьЭлемент(УзелСвойства, "Выражение", Выражение);
			ДобавитьПодчиненный(УзелКоллекцииСвойств, УзелСвойства);
			Продолжить;

		ИначеЕсли Пусто Тогда

			Если ПустаяСтрока(ТипПриемника) Тогда

				Продолжить;

			КонецЕсли;

			Если Не ExecuteDataExchangeInOptimizedFormat Тогда
				одЗаписатьЭлемент(УзелСвойства, "Пусто");
			КонецЕсли;

			ДобавитьПодчиненный(УзелКоллекцииСвойств, УзелСвойства);
			Продолжить;

		Иначе

			ПолучитьЗначениеСвойства(Значение, ОбъектКоллекции, ПКО, ПКС, ВходящиеДанные, Источник);

			Если ПКС.ПриводитьКДлине <> 0 Тогда

				ВыполнитьПриведениеЗначенияКДлине(Значение, ПКС);

			КонецЕсли;

		КонецЕсли;
		СтароеЗначениеДоОбработчикаПриВыгрузке = Значение;
		Пусто = одПустое(Значение, ЭтоNULL);

		
		// Обработчик ПриВыгрузке
		Если ПКС.ЕстьОбработчикПриВыгрузке Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКС, "ПриВыгрузке"));

				Иначе

					Выполнить (ПКС.ПриВыгрузке);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(56, ОписаниеОшибки(), ПКО, ПКС, Источник,
					"ПриВыгрузкеСвойства", Значение);

			КонецПопытки;

			Если Отказ Тогда	//	Отказ от выгрузки свойства

				Продолжить;

			КонецЕсли;

		КонецЕсли;


		// Инициализируем еще раз переменную Пусто, может быть Значение было изменено 
		// в обработчике "При выгрузке".
		Если СтароеЗначениеДоОбработчикаПриВыгрузке <> Значение Тогда

			Пусто = одПустое(Значение, ЭтоNULL);

		КонецЕсли;

		Если Пусто Тогда

			Если ЭтоNULL Или Значение = Неопределено Тогда

				Продолжить;

			КонецЕсли;

			Если ПустаяСтрока(ТипПриемника) Тогда

				ТипПриемника = ОпределитьТипДанныхДляПриемника(Значение);

				Если Не ПустаяСтрока(ТипПриемника) Тогда

					УстановитьАтрибут(УзелСвойства, "Тип", ТипПриемника);

				КонецЕсли;

			КонецЕсли;			
				
			// Если тип множественный, то возможно это пустая ссылка и выгрузить ее нужно именно с указанием типа.
			Если Не ExecuteDataExchangeInOptimizedFormat Тогда
				одЗаписатьЭлемент(УзелСвойства, "Пусто");
			КонецЕсли;

			ДобавитьПодчиненный(УзелКоллекцииСвойств, УзелСвойства);
			Продолжить;

		КонецЕсли;
		УзелСсылки = Неопределено;

		Если (ПКОСвойств <> Неопределено) Или (Не ПустаяСтрока(ИмяПКО)) Тогда

			УзелСсылки = ВыгрузитьДанныеСсылочногоОбъекта(Значение, ИсходящиеДанные, ИмяПКО, ПКОСвойств, ТипПриемника,
				УзелСвойства, ВыгрузитьТолькоСсылку);

			Если УзелСсылки = Неопределено Тогда
				Продолжить;
			КонецЕсли;

		Иначе

			СвойствоУстановлено = Ложь;
			ТипЗначения = ТипЗнч(Значение);
			ДобавитьЗначениеСвойстваВУзел(Значение, ТипЗначения, ТипПриемника, УзелСвойства, СвойствоУстановлено);

			Если Не СвойствоУстановлено Тогда

				МенеджерЗначения = Менеджеры(ТипЗначения);

				Если МенеджерЗначения = Неопределено Тогда
					Продолжить;
				КонецЕсли;

				ПКОСвойств = МенеджерЗначения.ПКО;

				Если ПКОСвойств = Неопределено Тогда
					Продолжить;
				КонецЕсли;

				ИмяПКО = ПКОСвойств.Имя;

				УзелСсылки = ВыгрузитьДанныеСсылочногоОбъекта(Значение, ИсходящиеДанные, ИмяПКО, ПКОСвойств,
					ТипПриемника, УзелСвойства, ВыгрузитьТолькоСсылку);

				Если УзелСсылки = Неопределено Тогда
					Продолжить;
				КонецЕсли;

			КонецЕсли;

		КонецЕсли;


		
		// Обработчик ПослеВыгрузки

		Если ПКС.ЕстьОбработчикПослеВыгрузки Тогда

			Отказ = Ложь;

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКС, "ПослеВыгрузки"));

				Иначе

					Выполнить (ПКС.ПослеВыгрузки);

				КонецЕсли;

			Исключение

				ЗаписатьИнформациюОбОшибкеОбработчикиПКС(57, ОписаниеОшибки(), ПКО, ПКС, Источник,
					"ПослеВыгрузкиСвойства", Значение);

			КонецПопытки;

			Если Отказ Тогда	//	Отказ от выгрузки свойства

				Продолжить;

			КонецЕсли;

		КонецЕсли;
		ДобавитьПодчиненный(УзелКоллекцииСвойств, УзелСвойства);

	КонецЦикла;		//	по ПКС

КонецПроцедуры

// Производит выгрузку объекта выборки в соответствии с указанным правилом.
//
// Parameters:
//  Объект         - выгружаемый объект выборки.
//  Правило        - ссылка на правило выгрузки данных.
//  Свойства       - свойства объекта метаданного выгружаемого объекта.
//  ВходящиеДанные - произвольные вспомогательные данные.
// 
Процедура ВыгрузкаОбъектаВыборки(Объект, Правило, Свойства = Неопределено, ВходящиеДанные = Неопределено,
	ВыборкаДляВыгрузкиДанных = Неопределено)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	Если ФлагКомментироватьОбработкуОбъектов Тогда

		ОписаниеТипов = Новый ОписаниеТипов("Строка");
		ОбъектСтрока  = ОписаниеТипов.ПривестиЗначение(Объект);
		Если Не ПустаяСтрока(ОбъектСтрока) Тогда
			ПрОбъекта   = ОбъектСтрока + "  (" + ТипЗнч(Объект) + ")";
		Иначе
			ПрОбъекта   = ТипЗнч(Объект);
		КонецЕсли;

		СтрокаСообщения = ПодставитьПараметрыВСтроку(НСтр("ru = 'Выгрузка объекта: %1'"), ПрОбъекта);
		ЗаписатьВПротоколВыполнения(СтрокаСообщения, , Ложь, 1, 7);

	КонецЕсли;

	ИмяПКО			= Правило.ПравилоКонвертации;
	Отказ			= Ложь;
	ИсходящиеДанные	= Неопределено;
	
	// Глобальный обработчик ПередВыгрузкойОбъекта.
	Если ЕстьГлобальныйОбработчикПередВыгрузкойОбъекта Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПередВыгрузкойОбъекта"));

			Иначе

				Выполнить (Конвертация.ПередВыгрузкойОбъекта);

			КонецЕсли;

		Исключение
			ЗаписатьИнформациюОбОшибкеОбработчикиПВД(65, ОписаниеОшибки(), Правило.Имя, НСтр(
				"ru = 'ПередВыгрузкойОбъектаВыборки (глобальный)'"), Объект);
		КонецПопытки;

		Если Отказ Тогда
			Возврат;
		КонецЕсли;

	КонецЕсли;
	
	// Обработчик ПередВыгрузкой
	Если Не ПустаяСтрока(Правило.ПередВыгрузкой) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПередВыгрузкой"));

			Иначе

				Выполнить (Правило.ПередВыгрузкой);

			КонецЕсли;

		Исключение
			ЗаписатьИнформациюОбОшибкеОбработчикиПВД(33, ОписаниеОшибки(), Правило.Имя, "ПередВыгрузкойОбъектаВыборки",
				Объект);
		КонецПопытки;

		Если Отказ Тогда
			Возврат;
		КонецЕсли;

	КонецЕсли;

	УзелСсылки = Неопределено;

	ВыгрузитьПоПравилу(Объект, , ИсходящиеДанные, , ИмяПКО, УзелСсылки, , , , ВыборкаДляВыгрузкиДанных);
	
	// Глобальный обработчик ПослеВыгрузкиОбъекта.
	Если ЕстьГлобальныйОбработчикПослеВыгрузкиОбъекта Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПослеВыгрузкиОбъекта"));

			Иначе

				Выполнить (Конвертация.ПослеВыгрузкиОбъекта);

			КонецЕсли;

		Исключение
			ЗаписатьИнформациюОбОшибкеОбработчикиПВД(69, ОписаниеОшибки(), Правило.Имя, НСтр(
				"ru = 'ПослеВыгрузкиОбъектаВыборки (глобальный)'"), Объект);
		КонецПопытки;

	КонецЕсли;
	
	// Обработчик ПослеВыгрузки
	Если Не ПустаяСтрока(Правило.ПослеВыгрузки) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПослеВыгрузки"));

			Иначе

				Выполнить (Правило.ПослеВыгрузки);

			КонецЕсли;

		Исключение
			ЗаписатьИнформациюОбОшибкеОбработчикиПВД(34, ОписаниеОшибки(), Правило.Имя, "ПослеВыгрузкиОбъектаВыборки",
				Объект);
		КонецПопытки;

	КонецЕсли;

КонецПроцедуры

// Parameters:
//   МетаданныеОбъекта - ОбъектМетаданных -
//
Функция ПолучитьИмяПервогоРеквизитаМетаданных(МетаданныеОбъекта)

	НаборРеквизитов = МетаданныеОбъекта.Реквизиты; // КоллекцияОбъектовМетаданных

	Если НаборРеквизитов.Количество() = 0 Тогда
		Возврат "";
	КонецЕсли;

	Возврат НаборРеквизитов.Получить(0).Имя;

КонецФункции

Функция ПолучитьВыборкуДляВыгрузкиСОграничениями(Правило, ВыборкаДляПодстановкиВПКО = Неопределено,
	Свойства = Неопределено)

	ИмяМетаданных           = Правило.ИмяОбъектаДляЗапроса;

	СтрокаРазрешения = ?(ExportAllowedObjectsOnly, " РАЗРЕШЕННЫЕ ", "");

	ПоляВыборки = "";

	ЭтоВыгрузкаРегистра = (Правило.ИмяОбъектаДляЗапроса = Неопределено);

	Если ЭтоВыгрузкаРегистра Тогда

		Непериодический = Не Свойства.Периодический;
		ПодчиненныйРегистратору = Свойства.ПодчиненныйРегистратору;

		СтрокаДополненияПолейВыборкиПодчиненРегистратору = ?(Не ПодчиненныйРегистратору, ", NULL КАК Активность,
																						 |	NULL КАК Регистратор,
																						 |	NULL КАК НомерСтроки", "");

		СтрокаДополненияПолейВыборкиПериодичность = ?(Непериодический, ", NULL КАК Период", "");

		ИтоговоеОграничениеПоДате = ПолучитьСтрокуОграниченияПоДатеДляЗапроса(Свойства, Свойства.ИмяТипа,
			Правило.ИмяОбъектаДляЗапросаРегистра, Ложь);

		ReportBuilder.Текст = "ВЫБРАТЬ " + СтрокаРазрешения + "|	*
																  |
																  | " + СтрокаДополненияПолейВыборкиПодчиненРегистратору
			+ " | " + СтрокаДополненияПолейВыборкиПериодичность + " |
																  | ИЗ " + Правило.ИмяОбъектаДляЗапросаРегистра + " |
																												  |"
			+ ИтоговоеОграничениеПоДате;

		ReportBuilder.ЗаполнитьНастройки();

	Иначе

		Если Правило.ВыбиратьДанныеДляВыгрузкиОднимЗапросом Тогда
		
			// Выбираем все поля объекта при выгрузке.
			ПоляВыборки = "*";

		Иначе

			ПоляВыборки = "Ссылка КАК Ссылка";

		КонецЕсли;

		ИтоговоеОграничениеПоДате = ПолучитьСтрокуОграниченияПоДатеДляЗапроса(Свойства, Свойства.ИмяТипа, , Ложь);

		ReportBuilder.Текст = "ВЫБРАТЬ " + СтрокаРазрешения + " " + ПоляВыборки + " ИЗ " + ИмяМетаданных + "
																											   |
																											   |"
			+ ИтоговоеОграничениеПоДате + "
										  |
										  |{ГДЕ Ссылка.* КАК " + СтрЗаменить(ИмяМетаданных, ".", "_") + "}";

	КонецЕсли;

	ReportBuilder.Отбор.Сбросить();
	//УИ++
	//		
//	Если Правило.НастройкиПостроителя <> Неопределено Тогда
//		ПостроительОтчета.УстановитьНастройки(Правило.НастройкиПостроителя);
//	КонецЕсли;

	Если Правило.Отбор <> Неопределено Тогда
		ТекстЗапросаНовый = ПолучитьТекстЗапросаПоСтроке(Правило, Правило.Отбор <> Неопределено, "*");

		СхемаКомпоновкиДанных = СхемаКомпоновкиДанных(ТекстЗапросаНовый);
		КомпоновщикНастроек = Новый КомпоновщикНастроекКомпоновкиДанных;
		КомпоновщикНастроек.Инициализировать(Новый ИсточникДоступныхНастроекКомпоновкиДанных(СхемаКомпоновкиДанных));
		КомпоновщикНастроек.ЗагрузитьНастройки(СхемаКомпоновкиДанных.НастройкиПоУмолчанию);
		UT_CommonClientServer.CopyItems(КомпоновщикНастроек.Настройки.Отбор, Правило.Отбор);
		УстановитьНастройкуСтруктурыВыводаРезультата(КомпоновщикНастроек.Настройки);

		UT_CommonClientServer.SetDCSParemeterValue(КомпоновщикНастроек, "ДатаНачала", StartDate);
		UT_CommonClientServer.SetDCSParemeterValue(КомпоновщикНастроек, "ДатаОкончания",
			EndDate);
		// Компоновка макета компоновки данных.
		ДанныеРасшифровки = Новый ДанныеРасшифровкиКомпоновкиДанных;
		КомпоновщикМакета = Новый КомпоновщикМакетаКомпоновкиДанных;
//		UT_._От(СхемаКомпоновкиДанных, КомпоновщикНастроек

		МакетКомпоновкиДанных = КомпоновщикМакета.Выполнить( СхемаКомпоновкиДанных, КомпоновщикНастроек.Настройки,
			ДанныеРасшифровки, , Тип("ГенераторМакетаКомпоновкиДанных"));
		ЗапросВременный = Новый Запрос(МакетКомпоновкиДанных.НаборыДанных.НаборДанных1.Запрос);
		ReportBuilder.Текст = ЗапросВременный.Текст;

		Для Каждого Параметр Из МакетКомпоновкиДанных.ЗначенияПараметров Цикл
			ReportBuilder.Parameters.Вставить(Параметр.Имя, Параметр.Значение);
		КонецЦикла;
	КонецЕсли;
	//УИ--

	ReportBuilder.Parameters.Вставить("StartDate", StartDate);
	ReportBuilder.Parameters.Вставить("EndDate", EndDate);

	ReportBuilder.Выполнить();
	Выборка = ReportBuilder.Результат.Выбрать();

	Если Правило.ВыбиратьДанныеДляВыгрузкиОднимЗапросом Тогда
		ВыборкаДляПодстановкиВПКО = Выборка;
	КонецЕсли;

	Возврат Выборка;

КонецФункции

Функция ПолучитьВыборкуДляВыгрузкиПоПроизвольномуАлгоритму(ВыборкаДанных)

	Выборка = Неопределено;

	Если ТипЗнч(ВыборкаДанных) = Тип("ВыборкаИзРезультатаЗапроса") Тогда

		Выборка = ВыборкаДанных;

	ИначеЕсли ТипЗнч(ВыборкаДанных) = Тип("РезультатЗапроса") Тогда

		Выборка = ВыборкаДанных.Выбрать();

	ИначеЕсли ТипЗнч(ВыборкаДанных) = Тип("Запрос") Тогда

		РезультатЗапроса = ВыборкаДанных.Выполнить();
		Выборка          = РезультатЗапроса.Выбрать();

	КонецЕсли;

	Возврат Выборка;

КонецФункции

Функция ПолучитьСтрокуНабораКонстантДляВыгрузки(ТаблицаДанныхКонстантДляВыгрузки)

	СтрокаНабораКонстант = "";

	Для Каждого СтрокаТаблицы Из ТаблицаДанныхКонстантДляВыгрузки Цикл

		Если Не ПустаяСтрока(СтрокаТаблицы.Источник) Тогда

			СтрокаНабораКонстант = СтрокаНабораКонстант + ", " + СтрокаТаблицы.Источник;

		КонецЕсли;

	КонецЦикла;

	Если Не ПустаяСтрока(СтрокаНабораКонстант) Тогда

		СтрокаНабораКонстант = Сред(СтрокаНабораКонстант, 3);

	КонецЕсли;

	Возврат СтрокаНабораКонстант;

КонецФункции

Процедура ВыгрузитьНаборКонстант(Правило, Свойства, ИсходящиеДанные)

	Если Свойства.ПКО <> Неопределено Тогда

		СтрокаИменНабораКонстант = ПолучитьСтрокуНабораКонстантДляВыгрузки(Свойства.ПКО.Свойства);

	Иначе

		СтрокаИменНабораКонстант = "";

	КонецЕсли;

	НаборКонстант = Константы.СоздатьНабор(СтрокаИменНабораКонстант);
	НаборКонстант.Прочитать();
	ВыгрузкаОбъектаВыборки(НаборКонстант, Правило, Свойства, ИсходящиеДанные);

КонецПроцедуры

Функция ОпределитьНужноВыбиратьВсеПоля(Правило)

	НужныВсеПоляДляВыборки = Не ПустаяСтрока(Конвертация.ПередВыгрузкойОбъекта) Или Не ПустаяСтрока(
		Правило.ПередВыгрузкой) Или Не ПустаяСтрока(Конвертация.ПослеВыгрузкиОбъекта) Или Не ПустаяСтрока(
		Правило.ПослеВыгрузки);

	Возврат НужныВсеПоляДляВыборки;

КонецФункции

// Выгружает данные по указанному правилу.
//
// Parameters:
//  Правило        - ссылка на правило выгрузки данных.
// 
Процедура ВыгрузитьДанныеПоПравилу(Правило)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	ИмяПКО = Правило.ПравилоКонвертации;

	Если Не ПустаяСтрока(ИмяПКО) Тогда

		ПКО = Правила[ИмяПКО];

	КонецЕсли;

	Если ФлагКомментироватьОбработкуОбъектов Тогда

		СтрокаСообщения = ПодставитьПараметрыВСтроку(НСтр("ru = 'Правило выгрузки данных: %1 (%2)'"), СокрЛП(
			Правило.Имя), СокрЛП(Правило.Наименование));
		ЗаписатьВПротоколВыполнения(СтрокаСообщения, , Ложь, , 4);

	КонецЕсли;
	
	// Обработчик ПередОбработкой
	Отказ			= Ложь;
	ИсходящиеДанные	= Неопределено;
	ВыборкаДанных	= Неопределено;

	Если Не ПустаяСтрока(Правило.ПередОбработкой) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПередОбработкой"));

			Иначе

				Выполнить (Правило.ПередОбработкой);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикиПВД(31, ОписаниеОшибки(), Правило.Имя, "ПередОбработкойВыгрузкиДанных");

		КонецПопытки;

		Если Отказ Тогда

			Возврат;

		КонецЕсли;

	КонецЕсли;
	
	// Стандартная выборка с отбором.
	Если Правило.СпособОтбораДанных = "СтандартнаяВыборка" И Правило.ИспользоватьОтбор Тогда

		Свойства	= Менеджеры[Правило.ОбъектВыборки];
		ИмяТипа		= Свойства.ИмяТипа;

		ВыборкаДляПКО = Неопределено;
		Выборка = ПолучитьВыборкуДляВыгрузкиСОграничениями(Правило, ВыборкаДляПКО, Свойства);

		ЭтоНеСсылочныйТип = ИмяТипа = "РегистрСведений" Или ИмяТипа = "РегистрБухгалтерии";

		Пока Выборка.Следующий() Цикл

			Если ЭтоНеСсылочныйТип Тогда
				ВыгрузкаОбъектаВыборки(Выборка, Правило, Свойства, ИсходящиеДанные);
			Иначе
				ВыгрузкаОбъектаВыборки(Выборка.Ссылка, Правило, Свойства, ИсходящиеДанные, ВыборкаДляПКО);
			КонецЕсли;

		КонецЦикла;
		
	// Стандартная выборка без отбора.
	ИначеЕсли (Правило.СпособОтбораДанных = "СтандартнаяВыборка") Тогда

		Свойства	= Менеджеры(Правило.ОбъектВыборки);
		ИмяТипа		= Свойства.ИмяТипа;

		Если ИмяТипа = "Константы" Тогда

			ВыгрузитьНаборКонстант(Правило, Свойства, ИсходящиеДанные);

		Иначе

			ЭтоНеСсылочныйТип = ИмяТипа = "РегистрСведений" Или ИмяТипа = "РегистрБухгалтерии";

			Если ЭтоНеСсылочныйТип Тогда

				ВыбиратьВсеПоля = ОпределитьНужноВыбиратьВсеПоля(Правило);

			Иначе
				
				// получаем только ссылку
				ВыбиратьВсеПоля = Правило.ВыбиратьДанныеДляВыгрузкиОднимЗапросом;

			КонецЕсли;

			Выборка = ПолучитьВыборкуДляВыгрузкиОчисткиДанных(Свойства, ИмяТипа, , , ВыбиратьВсеПоля);
			ВыборкаДляПКО = ?(Правило.ВыбиратьДанныеДляВыгрузкиОднимЗапросом, Выборка, Неопределено);

			Если Выборка = Неопределено Тогда
				Возврат;
			КонецЕсли;

			Пока Выборка.Следующий() Цикл

				Если ЭтоНеСсылочныйТип Тогда

					ВыгрузкаОбъектаВыборки(Выборка, Правило, Свойства, ИсходящиеДанные);

				Иначе

					ВыгрузкаОбъектаВыборки(Выборка.Ссылка, Правило, Свойства, ИсходящиеДанные, ВыборкаДляПКО);

				КонецЕсли;

			КонецЦикла;

		КонецЕсли;

	ИначеЕсли Правило.СпособОтбораДанных = "ПроизвольныйАлгоритм" Тогда

		Если ВыборкаДанных <> Неопределено Тогда

			Выборка = ПолучитьВыборкуДляВыгрузкиПоПроизвольномуАлгоритму(ВыборкаДанных);

			Если Выборка <> Неопределено Тогда

				Пока Выборка.Следующий() Цикл

					ВыгрузкаОбъектаВыборки(Выборка, Правило, , ИсходящиеДанные);

				КонецЦикла;

			Иначе

				Для Каждого Объект Из ВыборкаДанных Цикл

					ВыгрузкаОбъектаВыборки(Объект, Правило, , ИсходящиеДанные);

				КонецЦикла;

			КонецЕсли;

		КонецЕсли;

	КонецЕсли;

	
	// Обработчик ПослеОбработки

	Если Не ПустаяСтрока(Правило.ПослеОбработки) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПослеОбработки"));

			Иначе

				Выполнить (Правило.ПослеОбработки);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикиПВД(32, ОписаниеОшибки(), Правило.Имя, "ПослеОбработкиВыгрузкиДанных");

		КонецПопытки;

	КонецЕсли;

КонецПроцедуры

// Обходит дерево правил выгрузки данных и выполняет выгрузку.
//
// Parameters:
//  Строки         - Коллекция строк дерева значений.
// 
Процедура ОбработатьПравилаВыгрузки(Строки, СоответствиеУзловПланаОбменаИСтрокВыгрузки)

	Для Каждого ПравилоВыгрузки Из Строки Цикл

		Если ПравилоВыгрузки.Включить = 0 Тогда

			Продолжить;

		КонецЕсли;

		Если (ПравилоВыгрузки.СсылкаНаУзелОбмена <> Неопределено И Не ПравилоВыгрузки.СсылкаНаУзелОбмена.Пустая()) Тогда

			МассивПравилВыгрузки = СоответствиеУзловПланаОбменаИСтрокВыгрузки.Получить(
				ПравилоВыгрузки.СсылкаНаУзелОбмена);

			Если МассивПравилВыгрузки = Неопределено Тогда

				МассивПравилВыгрузки = Новый Массив;

			КонецЕсли;

			МассивПравилВыгрузки.Добавить(ПравилоВыгрузки);

			СоответствиеУзловПланаОбменаИСтрокВыгрузки.Вставить(ПравилоВыгрузки.СсылкаНаУзелОбмена,
				МассивПравилВыгрузки);

			Продолжить;

		КонецЕсли;

		Если ПравилоВыгрузки.ЭтоГруппа Тогда

			ОбработатьПравилаВыгрузки(ПравилоВыгрузки.Строки, СоответствиеУзловПланаОбменаИСтрокВыгрузки);
			Продолжить;

		КонецЕсли;

		ВыгрузитьДанныеПоПравилу(ПравилоВыгрузки);

	КонецЦикла;

КонецПроцедуры

Функция СкопироватьМассивПравилВыгрузки(ИсходныйМассив)

	РезультирующийМассив = Новый Массив;

	Для Каждого Элемент Из ИсходныйМассив Цикл

		РезультирующийМассив.Добавить(Элемент);

	КонецЦикла;

	Возврат РезультирующийМассив;

КонецФункции

// Возвращаемое значение:
//   СтрокаДереваЗначений - строка дерева правил выгрузки данных:
//     * Имя - Строка -
//     * Наименование - Строка -
//
Функция НайтиСтрокуДереваПравилВыгрузкиПоТипуВыгрузки(МассивСтрок, ТипВыгрузки)

	Для Каждого СтрокаМассива Из МассивСтрок Цикл

		Если СтрокаМассива.ОбъектВыборки = ТипВыгрузки Тогда

			Возврат СтрокаМассива;

		КонецЕсли;

	КонецЦикла;

	Возврат Неопределено;

КонецФункции

Процедура УдалитьСтрокуДереваПравилВыгрузкиПоТипуВыгрузкиИзМассива(МассивСтрок, ЭлементУдаления)

	Счетчик = МассивСтрок.Количество() - 1;
	Пока Счетчик >= 0 Цикл

		СтрокаМассива = МассивСтрок[Счетчик];

		Если СтрокаМассива = ЭлементУдаления Тогда

			МассивСтрок.Удалить(Счетчик);
			Возврат;

		КонецЕсли;

		Счетчик = Счетчик - 1;

	КонецЦикла;

КонецПроцедуры

// Parameters:
//   Данные - ЛюбаяСсылка, РегистрСведенийНаборЗаписей, и т.п. -
//
Процедура ПолучитьСтрокуПравилВыгрузкиПоОбъектуОбмена(Данные, МетаданныеПоследнегоОбъекта, МетаданныеОбъектаВыгрузки,
	ПоследняяСтрокаПравилВыгрузки, ТекущаяСтрокаПравилаВыгрузки, ВременныйМассивПравилКонвертации,
	ОбъектДляПравилВыгрузки, ВыгружаетсяРегистр, ВыгружаютсяКонстанты, КонстантыБылиВыгружены)

	ТекущаяСтрокаПравилаВыгрузки = Неопределено;
	ОбъектДляПравилВыгрузки = Неопределено;
	ВыгружаетсяРегистр = Ложь;
	ВыгружаютсяКонстанты = Ложь;

	Если МетаданныеПоследнегоОбъекта = МетаданныеОбъектаВыгрузки И ПоследняяСтрокаПравилВыгрузки = Неопределено Тогда

		Возврат;

	КонецЕсли;

	СтруктураДанных = МенеджерыДляПлановОбмена[МетаданныеОбъектаВыгрузки];

	Если СтруктураДанных = Неопределено Тогда

		ВыгружаютсяКонстанты = Метаданные.Константы.Содержит(МетаданныеОбъектаВыгрузки);

		Если КонстантыБылиВыгружены Или Не ВыгружаютсяКонстанты Тогда

			Возврат;

		КонецЕсли;
		
		// Нужно найти правило для констант.
		Если МетаданныеПоследнегоОбъекта <> МетаданныеОбъектаВыгрузки Тогда

			ТекущаяСтрокаПравилаВыгрузки = НайтиСтрокуДереваПравилВыгрузкиПоТипуВыгрузки(
				ВременныйМассивПравилКонвертации, Тип("КонстантыНабор"));

		Иначе

			ТекущаяСтрокаПравилаВыгрузки = ПоследняяСтрокаПравилВыгрузки;

		КонецЕсли;

		Возврат;

	КонецЕсли;

	Если СтруктураДанных.ЭтоСсылочныйТип = Истина Тогда

		Если МетаданныеПоследнегоОбъекта <> МетаданныеОбъектаВыгрузки Тогда

			ТекущаяСтрокаПравилаВыгрузки = НайтиСтрокуДереваПравилВыгрузкиПоТипуВыгрузки(
				ВременныйМассивПравилКонвертации, СтруктураДанных.ТипСсылки);

		Иначе

			ТекущаяСтрокаПравилаВыгрузки = ПоследняяСтрокаПравилВыгрузки;

		КонецЕсли;

		ОбъектДляПравилВыгрузки = Данные.Ссылка;

	ИначеЕсли СтруктураДанных.ЭтоРегистр = Истина Тогда

		Если МетаданныеПоследнегоОбъекта <> МетаданныеОбъектаВыгрузки Тогда

			ТекущаяСтрокаПравилаВыгрузки = НайтиСтрокуДереваПравилВыгрузкиПоТипуВыгрузки(
				ВременныйМассивПравилКонвертации, СтруктураДанных.ТипСсылки);

		Иначе

			ТекущаяСтрокаПравилаВыгрузки = ПоследняяСтрокаПравилВыгрузки;

		КонецЕсли;

		ОбъектДляПравилВыгрузки = Данные;

		ВыгружаетсяРегистр = Истина;

	КонецЕсли;

КонецПроцедуры

Функция ВыполнитьВыгрузкуИзмененныхДанныхДляУзлаОбмена(УзелОбмена, МассивПравилКонвертации,
	СтруктураДляУдаленияРегистрацииИзменений)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	СтруктураДляУдаленияРегистрацииИзменений.Вставить("МассивПКО", Неопределено);
	СтруктураДляУдаленияРегистрацииИзменений.Вставить("НомерСообщения", Неопределено);

	ЗаписьXML = Новый ЗаписьXML;
	ЗаписьXML.УстановитьСтроку();
	
	// Создаем новое сообщение
	ЗаписьСообщения = ПланыОбмена.СоздатьЗаписьСообщения();

	ЗаписьСообщения.НачатьЗапись(ЗаписьXML, УзелОбмена);
	
	// Считаем количество записанных объектов.
	КоличествоНайденныхДляЗаписиОбъектов = 0;

	ПоследнийОбъектМетаданных = Неопределено;
	ПоследняяСтрокаПравилаВыгрузки = Неопределено; // см. НайтиСтрокуДереваПравилВыгрузкиПоТипуВыгрузки

	ТекущийОбъектМетаданных = Неопределено;
	ТекущаяСтрокаПравилаВыгрузки = Неопределено; // см. НайтиСтрокуДереваПравилВыгрузкиПоТипуВыгрузки

	ИсходящиеДанные = Неопределено;

	ВременныйМассивПравилКонвертации = СкопироватьМассивПравилВыгрузки(МассивПравилКонвертации);

	Отказ           = Ложь;
	ИсходящиеДанные = Неопределено;
	ВыборкаДанных   = Неопределено;

	ОбъектДляПравилВыгрузки = Неопределено;
	КонстантыБылиВыгружены = Ложь;
	// начинаем транзакцию
	Если UseTransactionsOnExportForExchangePlans Тогда
		НачатьТранзакцию();
	КонецЕсли;

	Попытка
	
		// Получаем выборку измененных данных.
		МассивВыгружаемыхМетаданных = Новый Массив;
		
		// Дополняем массив только теми метаданными по которым есть правила выгрузки - остальные метаданные нас не интересуют.
		Для Каждого СтрокаПравилаВыгрузки Из ВременныйМассивПравилКонвертации Цикл

			МетаданныеПВД = Метаданные.НайтиПоТипу(СтрокаПравилаВыгрузки.ОбъектВыборки);
			МассивВыгружаемыхМетаданных.Добавить(МетаданныеПВД);

		КонецЦикла;

		ВыборкаИзменений = ПланыОбмена.ВыбратьИзменения(ЗаписьСообщения.Получатель, ЗаписьСообщения.НомерСообщения,
			МассивВыгружаемыхМетаданных);

		СтруктураДляУдаленияРегистрацииИзменений.НомерСообщения = ЗаписьСообщения.НомерСообщения;

		Пока ВыборкаИзменений.Следующий() Цикл

			Данные = ВыборкаИзменений.Получить();
			КоличествоНайденныхДляЗаписиОбъектов = КоличествоНайденныхДляЗаписиОбъектов + 1;

			ТипДанныхДляВыгрузки = ТипЗнч(Данные);

			Удаление = (ТипДанныхДляВыгрузки = одТипУдалениеОбъекта);
			
			// удаление не отрабатываем
			Если Удаление Тогда
				Продолжить;
			КонецЕсли;

			ТекущийОбъектМетаданных = Данные.Метаданные();
			
			// Работа с данными полученными из узла обмена
			// по данным определяем правило конвертации и производим выгрузку данных.

			ВыгружаетсяРегистр = Ложь;
			ВыгружаютсяКонстанты = Ложь;

			ПолучитьСтрокуПравилВыгрузкиПоОбъектуОбмена(Данные, ПоследнийОбъектМетаданных, ТекущийОбъектМетаданных,
				ПоследняяСтрокаПравилаВыгрузки, ТекущаяСтрокаПравилаВыгрузки, ВременныйМассивПравилКонвертации,
				ОбъектДляПравилВыгрузки, ВыгружаетсяРегистр, ВыгружаютсяКонстанты, КонстантыБылиВыгружены);

			Если ПоследнийОбъектМетаданных <> ТекущийОбъектМетаданных Тогда
				
				// после обработки
				Если ПоследняяСтрокаПравилаВыгрузки <> Неопределено Тогда

					Если Не ПустаяСтрока(ПоследняяСтрокаПравилаВыгрузки.ПослеОбработки) Тогда

						Попытка

							Если HandlersDebugModeFlag Тогда

								Выполнить (ПолучитьСтрокуВызоваОбработчика(ПоследняяСтрокаПравилаВыгрузки,
									"ПослеОбработки"));

							Иначе

								Выполнить (ПоследняяСтрокаПравилаВыгрузки.ПослеОбработки);

							КонецЕсли;

						Исключение

							ЗаписатьИнформациюОбОшибкеОбработчикиПВД(32, ОписаниеОшибки(),
								ПоследняяСтрокаПравилаВыгрузки.Имя, "ПослеОбработкиВыгрузкиДанных");

						КонецПопытки;

					КонецЕсли;

				КонецЕсли;
				
				// перед обработкой
				Если ТекущаяСтрокаПравилаВыгрузки <> Неопределено Тогда

					Если ФлагКомментироватьОбработкуОбъектов Тогда

						СтрокаСообщения = ПодставитьПараметрыВСтроку(НСтр("ru = 'Правило выгрузки данных: %1 (%2)'"),
							СокрЛП(ТекущаяСтрокаПравилаВыгрузки.Имя), СокрЛП(ТекущаяСтрокаПравилаВыгрузки.Наименование));
						ЗаписатьВПротоколВыполнения(СтрокаСообщения, , Ложь, , 4);

					КонецЕсли;
					
					// Обработчик ПередОбработкой
					Отказ			= Ложь;
					ИсходящиеДанные	= Неопределено;
					ВыборкаДанных	= Неопределено;

					Если Не ПустаяСтрока(ТекущаяСтрокаПравилаВыгрузки.ПередОбработкой) Тогда

						Попытка

							Если HandlersDebugModeFlag Тогда

								Выполнить (ПолучитьСтрокуВызоваОбработчика(ТекущаяСтрокаПравилаВыгрузки,
									"ПередОбработкой"));

							Иначе

								Выполнить (ТекущаяСтрокаПравилаВыгрузки.ПередОбработкой);

							КонецЕсли;

						Исключение

							ЗаписатьИнформациюОбОшибкеОбработчикиПВД(31, ОписаниеОшибки(),
								ТекущаяСтрокаПравилаВыгрузки.Имя, "ПередОбработкойВыгрузкиДанных");

						КонецПопытки;

					КонецЕсли;

					Если Отказ Тогда
						
						// Удаляем правило из массива правил.
						ТекущаяСтрокаПравилаВыгрузки = Неопределено;
						УдалитьСтрокуДереваПравилВыгрузкиПоТипуВыгрузкиИзМассива(ВременныйМассивПравилКонвертации,
							ТекущаяСтрокаПравилаВыгрузки);
						ОбъектДляПравилВыгрузки = Неопределено;

					КонецЕсли;

				КонецЕсли;

			КонецЕсли;
			
			// Есть правило по которому нужно делать выгрузку данных.
			Если ТекущаяСтрокаПравилаВыгрузки <> Неопределено Тогда

				Если ВыгружаетсяРегистр Тогда

					Для Каждого СтрокаРегистра Из ОбъектДляПравилВыгрузки Цикл
						ВыгрузкаОбъектаВыборки(СтрокаРегистра, ТекущаяСтрокаПравилаВыгрузки, , ИсходящиеДанные);
					КонецЦикла;

				ИначеЕсли ВыгружаютсяКонстанты Тогда

					Свойства	= Менеджеры[ТекущаяСтрокаПравилаВыгрузки.ОбъектВыборки];
					ВыгрузитьНаборКонстант(ТекущаяСтрокаПравилаВыгрузки, Свойства, ИсходящиеДанные);

				Иначе

					ВыгрузкаОбъектаВыборки(ОбъектДляПравилВыгрузки, ТекущаяСтрокаПравилаВыгрузки, , ИсходящиеДанные);

				КонецЕсли;

			КонецЕсли;

			ПоследнийОбъектМетаданных = ТекущийОбъектМетаданных;
			ПоследняяСтрокаПравилаВыгрузки = ТекущаяСтрокаПравилаВыгрузки;

			Если ProcessedObjectsCountToUpdateStatus > 0 И КоличествоНайденныхДляЗаписиОбъектов
				% ProcessedObjectsCountToUpdateStatus = 0 Тогда

				Попытка
					ИмяМетаданных = ТекущийОбъектМетаданных.ПолноеИмя();
				Исключение
					ИмяМетаданных = "";
				КонецПопытки;

			КонецЕсли;

			Если UseTransactionsOnExportForExchangePlans
				И (TransactionItemsCountOnExportForExchangePlans > 0)
				И (КоличествоНайденныхДляЗаписиОбъектов = TransactionItemsCountOnExportForExchangePlans) Тогда
				
				// Промежуточную транзакцию закрываем и открываем новую.
				ЗафиксироватьТранзакцию();
				НачатьТранзакцию();

				КоличествоНайденныхДляЗаписиОбъектов = 0;
			КонецЕсли;

		КонецЦикла;
		
		// Завершаем запись сообщения
		ЗаписьСообщения.ЗакончитьЗапись();

		ЗаписьXML.Закрыть();

		Если UseTransactionsOnExportForExchangePlans Тогда
			ЗафиксироватьТранзакцию();
		КонецЕсли;

	Исключение

		Если UseTransactionsOnExportForExchangePlans Тогда
			ОтменитьТранзакцию();
		КонецЕсли;

		ЗП = ПолучитьСтруктуруЗаписиПротокола(72, ОписаниеОшибки());
		ЗП.УзелПланаОбмена  = УзелОбмена;
		ЗП.Объект = Данные;
		ЗП.ТипОбъекта = ТипДанныхДляВыгрузки;

		ЗаписатьВПротоколВыполнения(72, ЗП, Истина);

		ЗаписьXML.Закрыть();

		Возврат Ложь;

	КонецПопытки;
	
	// событие после обработки
	Если ПоследняяСтрокаПравилаВыгрузки <> Неопределено Тогда

		Если Не ПустаяСтрока(ПоследняяСтрокаПравилаВыгрузки.ПослеОбработки) Тогда

			Попытка

				Если HandlersDebugModeFlag Тогда

					Выполнить (ПолучитьСтрокуВызоваОбработчика(ПоследняяСтрокаПравилаВыгрузки, "ПослеОбработки"));

				Иначе

					Выполнить (ПоследняяСтрокаПравилаВыгрузки.ПослеОбработки);

				КонецЕсли;

			Исключение
				ЗаписатьИнформациюОбОшибкеОбработчикиПВД(32, ОписаниеОшибки(), ПоследняяСтрокаПравилаВыгрузки.Имя,
					"ПослеОбработкиВыгрузкиДанных");

			КонецПопытки;

		КонецЕсли;

	КонецЕсли;

	СтруктураДляУдаленияРегистрацииИзменений.МассивПКО = ВременныйМассивПравилКонвертации;

	Возврат Не Отказ;

КонецФункции

Функция ОбработатьВыгрузкуДляПлановОбмена(СоответствиеУзловИПравилВыгрузки, СтруктураДляУдаленияРегистрацииИзменений)

	УдачнаяВыгрузка = Истина;

	Для Каждого СтрокаСоответствия Из СоответствиеУзловИПравилВыгрузки Цикл

		УзелОбмена = СтрокаСоответствия.Ключ;
		МассивПравилКонвертации = СтрокаСоответствия.Значение;

		ЛокальнаяСтруктураДляУдаленияРегистрацииИзменений = Новый Структура;

		ТекущаяУдачнаяВыгрузка = ВыполнитьВыгрузкуИзмененныхДанныхДляУзлаОбмена(УзелОбмена, МассивПравилКонвертации,
			ЛокальнаяСтруктураДляУдаленияРегистрацииИзменений);

		УдачнаяВыгрузка = УдачнаяВыгрузка И ТекущаяУдачнаяВыгрузка;

		Если ЛокальнаяСтруктураДляУдаленияРегистрацииИзменений.МассивПКО <> Неопределено
			И ЛокальнаяСтруктураДляУдаленияРегистрацииИзменений.МассивПКО.Количество() > 0 Тогда

			СтруктураДляУдаленияРегистрацииИзменений.Вставить(УзелОбмена,
				ЛокальнаяСтруктураДляУдаленияРегистрацииИзменений);

		КонецЕсли;

	КонецЦикла;

	Возврат УдачнаяВыгрузка;

КонецФункции

Процедура ОбработатьИзменениеРегистрацииДляУзловОбмена(СоответствиеУзловИПравилВыгрузки)

	Для Каждого Элемент Из СоответствиеУзловИПравилВыгрузки Цикл

		Если ChangesRegistrationDeletionTypeForExportedExchangeNodes = 0 Тогда

			Возврат;

		ИначеЕсли ChangesRegistrationDeletionTypeForExportedExchangeNodes = 1 Тогда
			
			// Для всех изменений которые были в плане обмена отменяем регистрацию.
			ПланыОбмена.УдалитьРегистрациюИзменений(Элемент.Ключ, Элемент.Значение.НомерСообщения);

		ИначеЕсли ChangesRegistrationDeletionTypeForExportedExchangeNodes = 2 Тогда	
			
			// Удаление изменений только для метаданных выгруженных объектов первого уровня.

			Для Каждого ВыгруженноеПКО Из Элемент.Значение.МассивПКО Цикл

				Правило = Правила[ВыгруженноеПКО.ПравилоКонвертации]; // см. НайтиПравило

				Если ЗначениеЗаполнено(Правило.Источник) Тогда

					Менеджер = Менеджеры[Правило.Источник];

					ПланыОбмена.УдалитьРегистрациюИзменений(Элемент.Ключ, Менеджер.ОбъектМД);

				КонецЕсли;

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Функция УдалитьНедопустимыеСимволыXML(Знач Текст)

	Возврат ЗаменитьНедопустимыеСимволыXML(Текст, "");

КонецФункции

#КонецОбласти

#Область ЭкспортируемыеПроцедурыИФункции

// Открывает файл обмена, читает атрибуты корневого узла файла в соответствии с форматом обмена.
//
// Parameters:
//  ТолькоПрочитатьШапку - Булево. если Истина, то после прочтения шапки файла обмена
//  (корневой узел), файл закрывается.
//
Процедура ОткрытьФайлЗагрузки(ТолькоПрочитатьШапку = Ложь, ДанныеФайлаОбмена = "") Экспорт

	Если ПустаяСтрока(ExchangeFileName) И ТолькоПрочитатьШапку Тогда
		StartDate         = "";
		EndDate      = "";
		DataExportDate = "";
		ExchangeRulesVersion = "";
		Comment        = "";
		Возврат;
	КонецЕсли;
	ИмяФайлаЗагрузкиДанных = ExchangeFileName;
	
	
	// Архивные файлы будем идентифицировать по расширению ".zip".
	Если СтрНайти(ExchangeFileName, ".zip") > 0 Тогда

		ИмяФайлаЗагрузкиДанных = РаспаковатьZipФайл(ExchangeFileName);

	КонецЕсли;
	ErrorFlag = Ложь;
	ФайлОбмена = Новый ЧтениеXML;

	Попытка
		Если Не ПустаяСтрока(ДанныеФайлаОбмена) Тогда
			ФайлОбмена.УстановитьСтроку(ДанныеФайлаОбмена);
		Иначе
			ФайлОбмена.ОткрытьФайл(ИмяФайлаЗагрузкиДанных);
		КонецЕсли;
	Исключение
		ЗаписатьВПротоколВыполнения(5);
		Возврат;
	КонецПопытки;

	ФайлОбмена.Прочитать();
	мАтрибутыФайлаОбмена = Новый Структура;
	Если ФайлОбмена.ЛокальноеИмя = "ФайлОбмена" Тогда

		мАтрибутыФайлаОбмена.Вставить("ВерсияФормата", одАтрибут(ФайлОбмена, одТипСтрока, "ВерсияФормата"));
		мАтрибутыФайлаОбмена.Вставить("ДатаВыгрузки", одАтрибут(ФайлОбмена, одТипДата, "ДатаВыгрузки"));
		мАтрибутыФайлаОбмена.Вставить("НачалоПериодаВыгрузки", одАтрибут(ФайлОбмена, одТипДата,
			"НачалоПериодаВыгрузки"));
		мАтрибутыФайлаОбмена.Вставить("ОкончаниеПериодаВыгрузки", одАтрибут(ФайлОбмена, одТипДата,
			"ОкончаниеПериодаВыгрузки"));
		мАтрибутыФайлаОбмена.Вставить("ИмяКонфигурацииИсточника", одАтрибут(ФайлОбмена, одТипСтрока,
			"ИмяКонфигурацииИсточника"));
		мАтрибутыФайлаОбмена.Вставить("ИмяКонфигурацииПриемника", одАтрибут(ФайлОбмена, одТипСтрока,
			"ИмяКонфигурацииПриемника"));
		мАтрибутыФайлаОбмена.Вставить("ИдПравилКонвертации", одАтрибут(ФайлОбмена, одТипСтрока, "ИдПравилКонвертации"));

		StartDate         = мАтрибутыФайлаОбмена.НачалоПериодаВыгрузки;
		EndDate      = мАтрибутыФайлаОбмена.ОкончаниеПериодаВыгрузки;
		DataExportDate = мАтрибутыФайлаОбмена.ДатаВыгрузки;
		Comment        = одАтрибут(ФайлОбмена, одТипСтрока, "Comment");

	Иначе

		ЗаписатьВПротоколВыполнения(9);
		Возврат;

	КонецЕсли;
	ФайлОбмена.Прочитать();

	ИмяУзла = ФайлОбмена.ЛокальноеИмя;

	Если ИмяУзла = "ПравилаОбмена" Тогда
		Если SafeImport И ЗначениеЗаполнено(ExchangeRulesFileName) Тогда
			ЗагрузитьПравилаОбмена(ExchangeRulesFileName, "XMLФайл");
			ФайлОбмена.Пропустить();
		Иначе
			ЗагрузитьПравилаОбмена(ФайлОбмена, "ЧтениеXML");
		КонецЕсли;
	Иначе
		ФайлОбмена.Закрыть();
		ФайлОбмена = Новый ЧтениеXML;
		Попытка

			Если Не ПустаяСтрока(ДанныеФайлаОбмена) Тогда
				ФайлОбмена.УстановитьСтроку(ДанныеФайлаОбмена);
			Иначе
				ФайлОбмена.ОткрытьФайл(ИмяФайлаЗагрузкиДанных);
			КонецЕсли;

		Исключение

			ЗаписатьВПротоколВыполнения(5);
			Возврат;

		КонецПопытки;

		ФайлОбмена.Прочитать();

	КонецЕсли;

	мБылиПрочитаныПравилаОбменаПриЗагрузке = Истина;

	Если ТолькоПрочитатьШапку Тогда

		ФайлОбмена.Закрыть();
		Возврат;

	КонецЕсли;

КонецПроцедуры

Процедура ОбновитьПометкиВсехРодителейУПравилВыгрузки(СтрокиДереваПравилВыгрузки, НужноУстанавливатьПометки = Истина)

	Если СтрокиДереваПравилВыгрузки.Строки.Количество() = 0 Тогда

		Если НужноУстанавливатьПометки Тогда
			УстановитьПометкиРодителей(СтрокиДереваПравилВыгрузки, "Включить");
		КонецЕсли;

	Иначе

		НужныПометки = Истина;

		Для Каждого СтрокаДереваПравил Из СтрокиДереваПравилВыгрузки.Строки Цикл

			ОбновитьПометкиВсехРодителейУПравилВыгрузки(СтрокаДереваПравил, НужныПометки);
			Если НужныПометки = Истина Тогда
				НужныПометки = Ложь;
			КонецЕсли;

		КонецЦикла;

	КонецЕсли;

КонецПроцедуры

Процедура ЗаполнитьСвойстваДляПоиска(СтруктураДанных, ПКС)

	Для Каждого СтрокаПолей Из ПКС Цикл

		Если СтрокаПолей.ЭтоГруппа Тогда

			Если СтрокаПолей.ВидПриемника = "ТабличнаяЧасть" Или СтрНайти(СтрокаПолей.ВидПриемника, "НаборДвижений")
				> 0 Тогда

				ИмяСтруктурыПриемника = СтрокаПолей.Приемник + ?(СтрокаПолей.ВидПриемника = "ТабличнаяЧасть",
					"ТабличнаяЧасть", "НаборЗаписей");

				ВнутренняяСтруктура = СтруктураДанных[ИмяСтруктурыПриемника];

				Если ВнутренняяСтруктура = Неопределено Тогда
					ВнутренняяСтруктура = Новый Соответствие;
				КонецЕсли;

				СтруктураДанных[ИмяСтруктурыПриемника] = ВнутренняяСтруктура;

			Иначе

				ВнутренняяСтруктура = СтруктураДанных;

			КонецЕсли;

			ЗаполнитьСвойстваДляПоиска(ВнутренняяСтруктура, СтрокаПолей.ПравилаГруппы);

		Иначе

			Если ПустаяСтрока(СтрокаПолей.ТипПриемника) Тогда

				Продолжить;

			КонецЕсли;

			СтруктураДанных[СтрокаПолей.Приемник] = СтрокаПолей.ТипПриемника;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура УдалитьЛишниеЭлементыИзСоответствия(СтруктураДанных)

	Для Каждого Элемент Из СтруктураДанных Цикл

		Если ТипЗнч(Элемент.Значение) = одТипСоответствие Тогда

			УдалитьЛишниеЭлементыИзСоответствия(Элемент.Значение);

			Если Элемент.Значение.Количество() = 0 Тогда
				СтруктураДанных.Удалить(Элемент.Ключ);
			КонецЕсли;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ЗаполнитьИнформациюПоТипамДанныхПриемника(СтруктураДанных, Правила)

	Для Каждого Строка Из Правила Цикл

		Если ПустаяСтрока(Строка.Приемник) Тогда
			Продолжить;
		КонецЕсли;

		ДанныеСтруктуры = СтруктураДанных[Строка.Приемник];
		Если ДанныеСтруктуры = Неопределено Тогда

			ДанныеСтруктуры = Новый Соответствие;
			СтруктураДанных[Строка.Приемник] = ДанныеСтруктуры;

		КонецЕсли;
		
		// Обходим поля поиска и ПКС и запоминаем типы данных.
		ЗаполнитьСвойстваДляПоиска(ДанныеСтруктуры, Строка.СвойстваПоиска);
				
		// Свойства
		ЗаполнитьСвойстваДляПоиска(ДанныеСтруктуры, Строка.Свойства);

	КонецЦикла;

	УдалитьЛишниеЭлементыИзСоответствия(СтруктураДанных);

КонецПроцедуры

Процедура СоздатьСтрокуСТипамиСвойств(ЗаписьXML, ТипыСвойств)

	Если ТипЗнч(ТипыСвойств.Значение) = одТипСоответствие Тогда

		Если ТипыСвойств.Значение.Количество() = 0 Тогда
			Возврат;
		КонецЕсли;

		ЗаписьXML.ЗаписатьНачалоЭлемента(ТипыСвойств.Ключ);

		Для Каждого Элемент Из ТипыСвойств.Значение Цикл
			СоздатьСтрокуСТипамиСвойств(ЗаписьXML, Элемент);
		КонецЦикла;

		ЗаписьXML.ЗаписатьКонецЭлемента();

	Иначе

		одЗаписатьЭлемент(ЗаписьXML, ТипыСвойств.Ключ, ТипыСвойств.Значение);

	КонецЕсли;

КонецПроцедуры

Функция СоздатьСтрокуСТипамиДляПриемника(СтруктураДанных)

	ЗаписьXML = Новый ЗаписьXML;
	ЗаписьXML.УстановитьСтроку();
	ЗаписьXML.ЗаписатьНачалоЭлемента("ИнформацияОТипахДанных");

	Для Каждого Строка Из СтруктураДанных Цикл

		ЗаписьXML.ЗаписатьНачалоЭлемента("ТипДанных");
		УстановитьАтрибут(ЗаписьXML, "Имя", Строка.Ключ);

		Для Каждого СтрокаПодчинения Из Строка.Значение Цикл

			СоздатьСтрокуСТипамиСвойств(ЗаписьXML, СтрокаПодчинения);

		КонецЦикла;

		ЗаписьXML.ЗаписатьКонецЭлемента();

	КонецЦикла;

	ЗаписьXML.ЗаписатьКонецЭлемента();

	СтрокаРезультата = ЗаписьXML.Закрыть();
	Возврат СтрокаРезультата;

КонецФункции

Процедура ЗагрузитьОдинТипДанных(ПравилаОбмена, СоответствиеТипа, ИмяЛокальногоЭлемента)

	ИмяУзла = ИмяЛокальногоЭлемента;

	ПравилаОбмена.Прочитать();

	Если (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

		ПравилаОбмена.Прочитать();
		Возврат;

	ИначеЕсли ПравилаОбмена.ТипУзла = одТипУзлаXML_НачалоЭлемента Тогда
			
		// это новый элемент
		НовоеСоответствие = Новый Соответствие;
		СоответствиеТипа.Вставить(ИмяУзла, НовоеСоответствие);

		ЗагрузитьОдинТипДанных(ПравилаОбмена, НовоеСоответствие, ПравилаОбмена.ЛокальноеИмя);
		ПравилаОбмена.Прочитать();

	Иначе
		СоответствиеТипа.Вставить(ИмяУзла, Тип(ПравилаОбмена.Значение));
		ПравилаОбмена.Прочитать();
	КонецЕсли;

	ЗагрузитьСоответствиеТиповДляОдногоТипа(ПравилаОбмена, СоответствиеТипа);

КонецПроцедуры

Процедура ЗагрузитьСоответствиеТиповДляОдногоТипа(ПравилаОбмена, СоответствиеТипа)

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		КонецЕсли;
		
		// прочитали начало элемента
		ПравилаОбмена.Прочитать();

		Если ПравилаОбмена.ТипУзла = одТипУзлаXML_НачалоЭлемента Тогда
			
			// это новый элемент
			НовоеСоответствие = Новый Соответствие;
			СоответствиеТипа.Вставить(ИмяУзла, НовоеСоответствие);

			ЗагрузитьОдинТипДанных(ПравилаОбмена, НовоеСоответствие, ПравилаОбмена.ЛокальноеИмя);

		Иначе
			СоответствиеТипа.Вставить(ИмяУзла, Тип(ПравилаОбмена.Значение));
			ПравилаОбмена.Прочитать();
		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ЗагрузитьИнформациюОТипахДанных()

	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "ТипДанных" Тогда

			ИмяТипа = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");

			СоответствиеТипа = Новый Соответствие;
			мСоответствиеТиповДанныхДляЗагрузки.Вставить(Тип(ИмяТипа), СоответствиеТипа);

			ЗагрузитьСоответствиеТиповДляОдногоТипа(ФайлОбмена, СоответствиеТипа);

		ИначеЕсли (ИмяУзла = "ИнформацияОТипахДанных") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ЗагрузитьЗначенияПараметровОбменаДанными()

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	Имя = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");

	ТипСвойства = ПолучитьТипСвойстваПоДополнительнымДанным(Неопределено, Имя);

	Значение = ПрочитатьСвойство(ТипСвойства);

	Parameters.Вставить(Имя, Значение);

	АлгоритмПослеЗагрузкиПараметра = "";
	Если СобытияПослеЗагрузкиПараметров.Свойство(Имя, АлгоритмПослеЗагрузкиПараметра) И Не ПустаяСтрока(
		АлгоритмПослеЗагрузкиПараметра) Тогда

		Если HandlersDebugModeFlag Тогда

			ВызватьИсключение НСтр("ru = 'Отладка обработчика ""После загрузки параметра"" не поддерживается.'");

		Иначе

			Выполнить (АлгоритмПослеЗагрузкиПараметра);

		КонецЕсли;

	КонецЕсли;

КонецПроцедуры

Функция ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена)

	ТекстОбработчика = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

	Если СтрНайти(ТекстОбработчика, Символы.ПС) = 0 Тогда
		Возврат ТекстОбработчика;
	КонецЕсли;

	ТекстОбработчика = СтрЗаменить(ТекстОбработчика, Символ(10), Символы.ПС);

	Возврат ТекстОбработчика;

КонецФункции

// Осуществляет загрузку правил обмена в соответствии с форматом.
//
// Parameters:
//  Источник        - Объект, из которого осуществляется загрузка правил обмена;
//  ТипИсточника    - Строка, указывающая тип источника: "XMLФайл", "ЧтениеXML", "Строка".
// 
Процедура ЗагрузитьПравилаОбмена(Источник = "", ТипИсточника = "XMLФайл") Экспорт

	ИнициализироватьМенеджерыИСообщения();

	ЕстьГлобальныйОбработчикПередВыгрузкойОбъекта    = Ложь;
	ЕстьГлобальныйОбработчикПослеВыгрузкиОбъекта     = Ложь;

	ЕстьГлобальныйОбработчикПередКонвертациейОбъекта = Ложь;

	ЕстьГлобальныйОбработчикПередЗагрузкойОбъекта    = Ложь;
	ЕстьГлобальныйОбработчикПослеЗагрузкиОбъекта     = Ложь;

	СоздатьСтруктуруКонвертации();

	mPropertyConversionRulesTable = Новый ТаблицаЗначений;
	ИнициализацияТаблицыПравилКонвертацииСвойств(mPropertyConversionRulesTable);
	ДополнитьСлужебныеТаблицыКолонками();
	
	// Возможно выбраны встроенные правила обмена (один из макетов).

	ИмяВременногоФайлаПравилОбмена = "";
	Если ПустаяСтрока(Источник) Тогда

		Источник = ExchangeRulesFileName;
		Если мСписокМакетовПравилОбмена.НайтиПоЗначению(Источник) <> Неопределено Тогда
			Для Каждого Макет Из Метаданные().Макеты Цикл
				Если Макет.Синоним = Источник Тогда
					Источник = Макет.Имя;
					Прервать;
				КонецЕсли;
			КонецЦикла;
			МакетПравилОбмена              = ПолучитьМакет(Источник);
			ИмяВременногоФайлаПравилОбмена = ПолучитьИмяВременногоФайла("xml");
			МакетПравилОбмена.Записать(ИмяВременногоФайлаПравилОбмена);
			Источник = ИмяВременногоФайлаПравилОбмена;
		КонецЕсли;

	КонецЕсли;
	Если ТипИсточника = "XMLФайл" Тогда

		Если ПустаяСтрока(Источник) Тогда
			ЗаписатьВПротоколВыполнения(12);
			Возврат;
		КонецЕсли;

		Файл = Новый Файл(Источник);
		Если Не Файл.Существует() Тогда
			ЗаписатьВПротоколВыполнения(3);
			Возврат;
		КонецЕсли;

		ФайлПравилЗапакован = (Файл.Расширение = ".zip");

		Если ФайлПравилЗапакован Тогда
			
			// распаковка файла правил
			Источник = РаспаковатьZipФайл(Источник);

		КонецЕсли;

		ПравилаОбмена = Новый ЧтениеXML;
		ПравилаОбмена.ОткрытьФайл(Источник);
		ПравилаОбмена.Прочитать();

	ИначеЕсли ТипИсточника = "Строка" Тогда

		ПравилаОбмена = Новый ЧтениеXML;
		ПравилаОбмена.УстановитьСтроку(Источник);
		ПравилаОбмена.Прочитать();

	ИначеЕсли ТипИсточника = "ЧтениеXML" Тогда

		ПравилаОбмена = Источник;

	КонецЕсли;
	Если Не ((ПравилаОбмена.ЛокальноеИмя = "ПравилаОбмена") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_НачалоЭлемента)) Тогда
		ЗаписатьВПротоколВыполнения(6);
		Возврат;
	КонецЕсли;
	ЗаписьXML = Новый ЗаписьXML;
	ЗаписьXML.УстановитьСтроку();
	ЗаписьXML.Отступ = Истина;
	ЗаписьXML.ЗаписатьНачалоЭлемента("ПравилаОбмена");
	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
		
		// Реквизиты конвертации
		Если ИмяУзла = "ВерсияФормата" Тогда
			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Конвертация.Вставить("ВерсияФормата", Значение);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
		ИначеЕсли ИмяУзла = "Ид" Тогда
			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Конвертация.Вставить("Ид", Значение);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
		ИначеЕсли ИмяУзла = "Наименование" Тогда
			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Конвертация.Вставить("Наименование", Значение);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
		ИначеЕсли ИмяУзла = "ДатаВремяСоздания" Тогда
			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипДата);
			Конвертация.Вставить("ДатаВремяСоздания", Значение);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
			ExchangeRulesVersion = Конвертация.ДатаВремяСоздания;
		ИначеЕсли ИмяУзла = "Источник" Тогда
			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Конвертация.Вставить("Источник", Значение);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
		ИначеЕсли ИмяУзла = "Приемник" Тогда

			ВерсияПлатформыПриемника = ПравилаОбмена.ПолучитьАтрибут ("ВерсияПлатформы");
			ПлатформаПриемника = ОпределитьПоВерсииПлатформыПриемникаПлатформу(ВерсияПлатформыПриемника);

			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Конвертация.Вставить("Приемник", Значение);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

		ИначеЕсли ИмяУзла = "УдалятьСопоставленныеОбъектыВПриемникеПриИхУдаленииВИсточнике" Тогда
			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "Comment" Тогда
			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "ОсновнойПланОбмена" Тогда
			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "Parameters" Тогда
			ЗагрузитьПараметры(ПравилаОбмена, ЗаписьXML);

		// События конвертации
		ИначеЕсли
		ИмяУзла = "" Тогда

		ИначеЕсли ИмяУзла = "ПослеЗагрузкиПравилОбмена" Тогда
			Если ExchangeMode = "Загрузка" Тогда
				ПравилаОбмена.Пропустить();
			Иначе
				Конвертация.Вставить("ПослеЗагрузкиПравилОбмена", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));
			КонецЕсли;
		ИначеЕсли ИмяУзла = "ПередВыгрузкойДанных" Тогда
			Конвертация.Вставить("ПередВыгрузкойДанных", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));

		ИначеЕсли ИмяУзла = "ПослеВыгрузкиДанных" Тогда
			Конвертация.Вставить("ПослеВыгрузкиДанных", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));

		ИначеЕсли ИмяУзла = "ПередВыгрузкойОбъекта" Тогда
			Конвертация.Вставить("ПередВыгрузкойОбъекта", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));
			ЕстьГлобальныйОбработчикПередВыгрузкойОбъекта = Не ПустаяСтрока(Конвертация.ПередВыгрузкойОбъекта);

		ИначеЕсли ИмяУзла = "ПослеВыгрузкиОбъекта" Тогда
			Конвертация.Вставить("ПослеВыгрузкиОбъекта", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));
			ЕстьГлобальныйОбработчикПослеВыгрузкиОбъекта = Не ПустаяСтрока(Конвертация.ПослеВыгрузкиОбъекта);

		ИначеЕсли ИмяУзла = "ПередЗагрузкойОбъекта" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				Конвертация.Вставить("ПередЗагрузкойОбъекта", Значение);
				ЕстьГлобальныйОбработчикПередЗагрузкойОбъекта = Не ПустаяСтрока(Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПослеЗагрузкиОбъекта" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				Конвертация.Вставить("ПослеЗагрузкиОбъекта", Значение);
				ЕстьГлобальныйОбработчикПослеЗагрузкиОбъекта = Не ПустаяСтрока(Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПередКонвертациейОбъекта" Тогда
			Конвертация.Вставить("ПередКонвертациейОбъекта", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));
			ЕстьГлобальныйОбработчикПередКонвертациейОбъекта = Не ПустаяСтрока(Конвертация.ПередКонвертациейОбъекта);

		ИначеЕсли ИмяУзла = "ПередЗагрузкойДанных" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				Конвертация.ПередЗагрузкойДанных = Значение;

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПослеЗагрузкиДанных" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				Конвертация.ПослеЗагрузкиДанных = Значение;

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПослеЗагрузкиПараметров" Тогда
			Конвертация.Вставить("ПослеЗагрузкиПараметров", ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена));

		ИначеЕсли ИмяУзла = "ПередОтправкойИнформацииОбУдалении" Тогда
			Конвертация.Вставить("ПередОтправкойИнформацииОбУдалении", одЗначениеЭлемента(ПравилаОбмена, одТипСтрока));

		ИначеЕсли ИмяУзла = "ПередПолучениемИзмененныхОбъектов" Тогда
			Конвертация.Вставить("ПередПолучениемИзмененныхОбъектов", одЗначениеЭлемента(ПравилаОбмена, одТипСтрока));

		ИначеЕсли ИмяУзла = "ПриПолученииИнформацииОбУдалении" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				Конвертация.Вставить("ПриПолученииИнформацииОбУдалении", Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПослеПолученияИнформацииОбУзлахОбмена" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				Конвертация.Вставить("ПослеПолученияИнформацииОбУзлахОбмена", Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		// Правила

		ИначеЕсли ИмяУзла = "ПравилаВыгрузкиДанных" Тогда

			Если ExchangeMode = "Загрузка" Тогда
				одПропустить(ПравилаОбмена);
			Иначе
				ЗагрузитьПравилаВыгрузки(ПравилаОбмена);
			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПравилаКонвертацииОбъектов" Тогда
			ЗагрузитьПравилаКонвертации(ПравилаОбмена, ЗаписьXML);

		ИначеЕсли ИмяУзла = "ПравилаОчисткиДанных" Тогда
			ЗагрузитьПравилаОчистки(ПравилаОбмена, ЗаписьXML);
			
		ИначеЕсли
		ИмяУзла = "ПравилаРегистрацииОбъектов" Тогда
			одПропустить(ПравилаОбмена); // Правила регистрации объектов загружаем другой обработкой.
			
		// Алгоритмы, Запросы, Обработки.

		ИначеЕсли ИмяУзла = "Алгоритмы" Тогда
			ЗагрузитьАлгоритмы(ПравилаОбмена, ЗаписьXML);

		ИначеЕсли ИмяУзла = "Запросы" Тогда
			ЗагрузитьЗапросы(ПравилаОбмена, ЗаписьXML);

		ИначеЕсли ИмяУзла = "Обработки" Тогда
			ЗагрузитьОбработки(ПравилаОбмена, ЗаписьXML);
			
		// Выход
		ИначеЕсли (ИмяУзла = "ПравилаОбмена") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Если ExchangeMode <> "Загрузка" Тогда
				ПравилаОбмена.Закрыть();
			КонецЕсли;
			Прервать;

			
		// Ошибка формата
		Иначе
			СтруктураЗаписи = Новый Структура("ИмяУзла", ИмяУзла);
			ЗаписатьВПротоколВыполнения(7, СтруктураЗаписи);
			Возврат;
		КонецЕсли;
	КонецЦикла;
	ЗаписьXML.ЗаписатьКонецЭлемента();
	mXMLRules = ЗаписьXML.Закрыть();

	Для Каждого СтрокаПравилВыгрузки Из ExportRulesTable.Строки Цикл
		ОбновитьПометкиВсехРодителейУПравилВыгрузки(СтрокаПравилВыгрузки, Истина);
	КонецЦикла;
	
	// Удаляем временный файл правил.
	Если Не ПустаяСтрока(ИмяВременногоФайлаПравилОбмена) Тогда
		Попытка
			УдалитьФайлы(ИмяВременногоФайлаПравилОбмена);
		Исключение
			ЗаписьЖурналаРегистрации(НСтр("ru = 'Универсальный обмен данными в формате XML'", КодОсновногоЯзыка()),
				УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		КонецПопытки;
	КонецЕсли;

	Если ТипИсточника = "XMLФайл" И ФайлПравилЗапакован Тогда

		Попытка
			УдалитьФайлы(Источник);
		Исключение
			ЗаписьЖурналаРегистрации(НСтр("ru = 'Универсальный обмен данными в формате XML'", КодОсновногоЯзыка()),
				УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
		КонецПопытки;

	КонецЕсли;
	
	// Дополнительно нужна информация по типам данных приемника для быстрой загрузки данных.
	СтруктураДанных = Новый Соответствие;
	ЗаполнитьИнформациюПоТипамДанныхПриемника(СтруктураДанных, ConversionRulesTable);

	mTypeStringForDestination = СоздатьСтрокуСТипамиДляПриемника(СтруктураДанных);

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;
	
	// Нужно вызвать событие после загрузки правил обмена.
	ТекстСобытияПослеЗагрузкиПравилОбмена = "";
	Если Конвертация.Свойство("ПослеЗагрузкиПравилОбмена", ТекстСобытияПослеЗагрузкиПравилОбмена) И Не ПустаяСтрока(
		ТекстСобытияПослеЗагрузкиПравилОбмена) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				ВызватьИсключение НСтр("ru = 'Отладка обработчика ""После загрузки правил обмена"" не поддерживается.'");

			Иначе

				Выполнить (ТекстСобытияПослеЗагрузкиПравилОбмена);

			КонецЕсли;

		Исключение

			Текст = НСтр("ru = 'Обработчик: ""ПослеЗагрузкиПравилОбмена"": %1'");
			Текст = ПодставитьПараметрыВСтроку(Текст, КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));

			ЗаписьЖурналаРегистрации(НСтр("ru = 'Универсальный обмен данными в формате XML'", КодОсновногоЯзыка()),
				УровеньЖурналаРегистрации.Ошибка, , , Текст);

			СообщитьПользователю(Текст);

		КонецПопытки;

	КонецЕсли;

КонецПроцедуры

Процедура ОбработатьОкончаниеЧтенияНовогоЭлемента(ПоследнийОбъектЗагрузки)

	мСчетчикЗагруженныхОбъектов = 1 + мСчетчикЗагруженныхОбъектов;

	Если ЗапоминатьЗагруженныеОбъекты И мСчетчикЗагруженныхОбъектов % 100 = 0 Тогда

		Если ЗагруженныеОбъекты.Количество() > ЧислоХранимыхЗагруженныхОбъектов Тогда
			ЗагруженныеОбъекты.Очистить();
		КонецЕсли;

	КонецЕсли;

	Если мСчетчикЗагруженныхОбъектов % 100 = 0 И мГлобальныйСтекНеЗаписанныхОбъектов.Количество() > 100 Тогда

		ПровестиЗаписьНеЗаписанныхОбъектов();

	КонецЕсли;

	Если UseTransactions И ObjectsPerTransaction > 0 И мСчетчикЗагруженныхОбъектов
		% ObjectsPerTransaction = 0 Тогда

		ЗафиксироватьТранзакцию();
		НачатьТранзакцию();

	КонецЕсли;

КонецПроцедуры

// Выполняет последовательное чтение файла сообщения обмена и записывает данные в информационную базу.
//
// Parameters:
//  РезультирующаяСтрокаСИнформациейОбОшибке - Строка - результирующая строка с информацией об ошибке.
// 
Процедура ПроизвестиЧтениеДанных(РезультирующаяСтрокаСИнформациейОбОшибке = "") Экспорт

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	Попытка

		Пока ФайлОбмена.Прочитать() Цикл

			ИмяУзла = ФайлОбмена.ЛокальноеИмя;

			Если ИмяУзла = "Объект" Тогда

				ПоследнийОбъектЗагрузки = ПрочитатьОбъект();

				ОбработатьОкончаниеЧтенияНовогоЭлемента(ПоследнийОбъектЗагрузки);

			ИначеЕсли ИмяУзла = "ЗначениеПараметра" Тогда

				ЗагрузитьЗначенияПараметровОбменаДанными();

			ИначеЕсли ИмяУзла = "АлгоритмПослеЗагрузкиПараметров" Тогда

				Отказ = Ложь;
				ПричинаОтказа = "";

				ТекстАлгоритма = "";
				Конвертация.Свойство("ПослеЗагрузкиПараметров", ТекстАлгоритма);
				
				// При загрузке в безопасном режиме текст алгоритма получен при чтении правил.
				// В противном случае его следует получать из файла обмена.
				Если ПустаяСтрока(ТекстАлгоритма) Тогда
					ТекстАлгоритма = одЗначениеЭлемента(ФайлОбмена, одТипСтрока);
				Иначе
					ФайлОбмена.Пропустить();
				КонецЕсли;

				Если Не ПустаяСтрока(ТекстАлгоритма) Тогда

					Попытка

						Если HandlersDebugModeFlag Тогда

							ВызватьИсключение НСтр(
								"ru = 'Отладка обработчика ""После загрузки параметров"" не поддерживается.'");

						Иначе

							Выполнить (ТекстАлгоритма);

						КонецЕсли;

						Если Отказ = Истина Тогда

							Если Не ПустаяСтрока(ПричинаОтказа) Тогда
								СтрокаИсключения = ПодставитьПараметрыВСтроку(НСтр(
									"ru = 'Загрузка данных отменена по причине: %1'"), ПричинаОтказа);
								ВызватьИсключение СтрокаИсключения;
							Иначе
								ВызватьИсключение НСтр("ru = 'Загрузка данных отменена'");
							КонецЕсли;

						КонецЕсли;

					Исключение

						ЗП = ПолучитьСтруктуруЗаписиПротокола(75, ОписаниеОшибки());
						ЗП.Обработчик     = "ПослеЗагрузкиПараметров";
						СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(75, ЗП, Истина);

						Если Не DebugModeFlag Тогда
							ВызватьИсключение СтрокаСообщенияОбОшибке;
						КонецЕсли;

					КонецПопытки;

				КонецЕсли;

			ИначеЕсли ИмяУзла = "Алгоритм" Тогда

				ТекстАлгоритма = одЗначениеЭлемента(ФайлОбмена, одТипСтрока);

				Если Не ПустаяСтрока(ТекстАлгоритма) Тогда

					Попытка

						Если HandlersDebugModeFlag Тогда

							ВызватьИсключение НСтр("ru = 'Отладка глобального алгоритма не поддерживается.'");

						Иначе

							Выполнить (ТекстАлгоритма);

						КонецЕсли;

					Исключение

						ЗП = ПолучитьСтруктуруЗаписиПротокола(39, ОписаниеОшибки());
						ЗП.Обработчик     = "АлгоритмФайлаОбмена";
						СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(39, ЗП, Истина);

						Если Не DebugModeFlag Тогда
							ВызватьИсключение СтрокаСообщенияОбОшибке;
						КонецЕсли;

					КонецПопытки;

				КонецЕсли;

			ИначеЕсли ИмяУзла = "ПравилаОбмена" Тогда

				мБылиПрочитаныПравилаОбменаПриЗагрузке = Истина;

				Если ConversionRulesTable.Количество() = 0 Тогда
					ЗагрузитьПравилаОбмена(ФайлОбмена, "ЧтениеXML");
				Иначе
					одПропустить(ФайлОбмена);
				КонецЕсли;

			ИначеЕсли ИмяУзла = "ИнформацияОТипахДанных" Тогда

				ЗагрузитьИнформациюОТипахДанных();

			ИначеЕсли (ИмяУзла = "ФайлОбмена") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Иначе
				СтруктураЗаписи = Новый Структура("ИмяУзла", ИмяУзла);
				ЗаписатьВПротоколВыполнения(9, СтруктураЗаписи);
			КонецЕсли;

		КонецЦикла;

	Исключение

		СтрокаОшибки = ПодставитьПараметрыВСтроку(НСтр("ru = 'Ошибка при загрузке данных: %1'"), ОписаниеОшибки());

		РезультирующаяСтрокаСИнформациейОбОшибке = ЗаписатьВПротоколВыполнения(СтрокаОшибки, Неопределено, Истина, , ,
			Истина);

		ЗавершитьВедениеПротоколаОбмена();
		ФайлОбмена.Закрыть();
		Возврат;

	КонецПопытки;

КонецПроцедуры

// Перед началом чтения данных из файла выполняем инициализацию переменных,
// загрузку правил обмена из файла данных,
// открываем транзакцию на запись данных в ИБ,
// выполняем необходимые обработчики событий.
//
// Parameters:
//  СтрокаДанных - имя файла для загрузки данных или строка-XML, содержащая данные для загрузки.
//
//  Возвращаемое значение:
//     Булево - Истина - загрузка данных из файла возможна; Ложь - нет.
//
Функция ВыполнитьДействияПередЧтениемДанных(СтрокаДанных = "") Экспорт

	РежимОбработкиДанных = мРежимыОбработкиДанных.Загрузка;

	мСоответствиеДопПараметровПоиска       = Новый Соответствие;
	мСоответствиеПравилКонвертации         = Новый Соответствие;

	Правила.Очистить();

	ИнициализироватьКомментарииПриВыгрузкеИЗагрузкеДанных();

	ИнициализироватьВедениеПротоколаОбмена();

	ЗагрузкаВозможна = Истина;

	Если ПустаяСтрока(СтрокаДанных) Тогда

		Если ПустаяСтрока(ExchangeFileName) Тогда
			ЗаписатьВПротоколВыполнения(15);
			ЗагрузкаВозможна = Ложь;
		КонецЕсли;

	КонецЕсли;
	
	// Инициализируем внешнюю обработку с экспортными обработчиками.
	ИнициализацияВнешнейОбработкиОбработчиковСобытий(ЗагрузкаВозможна, ЭтотОбъект);

	Если Не ЗагрузкаВозможна Тогда
		Возврат Ложь;
	КонецЕсли;

	СтрокаСообщения = ПодставитьПараметрыВСтроку(НСтр("ru = 'Начало загрузки: %1'"), ТекущаяДатаСеанса());
	ЗаписатьВПротоколВыполнения(СтрокаСообщения, , Ложь, , , Истина);

	Если DebugModeFlag Тогда
		UseTransactions = Ложь;
	КонецЕсли;

	Если ProcessedObjectsCountToUpdateStatus = 0 Тогда

		ProcessedObjectsCountToUpdateStatus = 100;

	КонецЕсли;

	мСоответствиеТиповДанныхДляЗагрузки = Новый Соответствие;
	мГлобальныйСтекНеЗаписанныхОбъектов = Новый Соответствие;

	мСчетчикЗагруженныхОбъектов = 0;
	ErrorFlag                  = Ложь;
	ЗагруженныеОбъекты          = Новый Соответствие;
	ЗагруженныеГлобальныеОбъекты = Новый Соответствие;

	ИнициализироватьМенеджерыИСообщения();

	ОткрытьФайлЗагрузки( , СтрокаДанных);

	Если ErrorFlag Тогда
		ЗавершитьВедениеПротоколаОбмена();
		Возврат Ложь;
	КонецЕсли;

	// Определяем интерфейсы обработчиков.
	Если HandlersDebugModeFlag Тогда

		ДополнитьПравилаИнтерфейсамиОбработчиков(Конвертация, ConversionRulesTable, ExportRulesTable,
			CleanupRulesTable);

	КонецЕсли;
	
	// Обработчик ПередЗагрузкойДанных
	Отказ = Ложь;

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	Если Не ПустаяСтрока(Конвертация.ПередЗагрузкойДанных) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПередЗагрузкойДанных"));

			Иначе

				Выполнить (Конвертация.ПередЗагрузкойДанных);

			КонецЕсли;

		Исключение
			ЗаписатьИнформациюОбОшибкеОбработчикиКонвертации(22, ОписаниеОшибки(), НСтр(
				"ru = 'ПередЗагрузкойДанных (конвертация)'"));
			Отказ = Истина;
		КонецПопытки;

		Если Отказ Тогда // Отказ от загрузки данных
			ЗавершитьВедениеПротоколаОбмена();
			ФайлОбмена.Закрыть();
			ДеструкторВнешнейОбработкиОбработчиковСобытий();
			Возврат Ложь;
		КонецЕсли;

	КонецЕсли;

	// Очистка информационной базы по правилам.
	ОбработатьПравилаОчистки(CleanupRulesTable.Строки);

	Возврат Истина;

КонецФункции

// Процедура выполняет действия после итерации загрузки данных:
// - фиксация транзакции (при необходимости)
// - закрытие файла сообщения обмена
// - выполнение обработчика конвертации ПослеЗагрузкиДанных
// - завершение ведения протокола обмена (при необходимости).
//
// Parameters:
//  Нет.
// 
Процедура ВыполнитьДействияПослеЗавершенияЧтенияДанных() Экспорт

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	ФайлОбмена.Закрыть();
	
	// Обработчик ПослеЗагрузкиДанных
	Если Не ПустаяСтрока(Конвертация.ПослеЗагрузкиДанных) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПослеЗагрузкиДанных"));

			Иначе

				Выполнить (Конвертация.ПослеЗагрузкиДанных);

			КонецЕсли;

		Исключение
			ЗаписатьИнформациюОбОшибкеОбработчикиКонвертации(23, ОписаниеОшибки(), НСтр(
				"ru = 'ПослеЗагрузкиДанных (конвертация)'"));
		КонецПопытки;

	КонецЕсли;

	ДеструкторВнешнейОбработкиОбработчиковСобытий();

	ЗаписатьВПротоколВыполнения(ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Окончание загрузки: %1'"), ТекущаяДатаСеанса()), , Ложь, , , Истина);
	ЗаписатьВПротоколВыполнения(ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Загружено объектов: %1'"), мСчетчикЗагруженныхОбъектов), , Ложь, , , Истина);

	ЗавершитьВедениеПротоколаОбмена();

	Если IsInteractiveMode Тогда
		СообщитьПользователю(НСтр("ru = 'Загрузка данных завершена.'"));
	КонецЕсли;

КонецПроцедуры

// Выполняет загрузку данных в соответствии с установленными режимами (правилами обмена).
//
// Parameters:
//  Нет.
//
Процедура ExecuteUploading() Экспорт

	РаботаВозможна = ВыполнитьДействияПередЧтениемДанных();

	Если Не РаботаВозможна Тогда
		Возврат;
	КонецЕсли;

	Если UseTransactions Тогда
		НачатьТранзакцию();
	КонецЕсли;

	Попытка
		ПроизвестиЧтениеДанных();
		// Отложенная запись того, что не записали с самого начала.
		ПровестиЗаписьНеЗаписанныхОбъектов();
		Если UseTransactions Тогда
			ЗафиксироватьТранзакцию();
		КонецЕсли;
	Исключение
		Если UseTransactions Тогда
			ОтменитьТранзакцию();
		КонецЕсли;
	КонецПопытки;

	ВыполнитьДействияПослеЗавершенияЧтенияДанных();

КонецПроцедуры

Процедура СжатьРезультирующийФайлОбмена()

	Попытка

		ИмяИсходногоФайлаОбмена = ExchangeFileName;
		Если ArchiveFile Тогда
			ExchangeFileName = СтрЗаменить(ExchangeFileName, ".xml", ".zip");
		КонецЕсли;

		Архиватор = Новый ЗаписьZipФайла(ExchangeFileName, ExchangeFileCompressionPassword, НСтр("ru = 'Файл обмена данными'"));
		Архиватор.Добавить(ИмяИсходногоФайлаОбмена);
		Архиватор.Записать();

		УдалитьФайлы(ИмяИсходногоФайлаОбмена);

	Исключение
		ЗаписьЖурналаРегистрации(НСтр("ru = 'Универсальный обмен данными в формате XML'", КодОсновногоЯзыка()),
			УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
	КонецПопытки;

КонецПроцедуры

Функция РаспаковатьZipФайл(ИмяФайлаДляРаспаковки)

	КаталогДляРаспаковки = FilesTempDirectory;
	СоздатьКаталог(КаталогДляРаспаковки);

	ИмяРаспакованногоФайла = "";

	Попытка

		Архиватор = Новый ЧтениеZipФайла(ИмяФайлаДляРаспаковки, ExchangeFileUnpackPassword);

		Если Архиватор.Элементы.Количество() > 0 Тогда

			ЭлементАрхива = Архиватор.Элементы.Получить(0);

			Архиватор.Извлечь(ЭлементАрхива, КаталогДляРаспаковки, РежимВосстановленияПутейФайловZIP.НеВосстанавливать);
			ИмяРаспакованногоФайла = ПолучитьИмяФайлаОбмена(КаталогДляРаспаковки, ЭлементАрхива.Имя);

		Иначе

			ИмяРаспакованногоФайла = "";

		КонецЕсли;

		Архиватор.Закрыть();

	Исключение

		ЗП = ПолучитьСтруктуруЗаписиПротокола(2, ОписаниеОшибки());
		ЗаписатьВПротоколВыполнения(2, ЗП, Истина);

		Возврат "";

	КонецПопытки;

	Возврат ИмяРаспакованногоФайла;

КонецФункции

Функция ВыполнитьПередачуИнформацииОНачалеОбменаВПриемник(ТекущаяСтрокаДляЗаписи)

	Если Не DirectReadFromDestinationIB Тогда
		Возврат Истина;
	КонецЕсли;

	ТекущаяСтрокаДляЗаписи = ТекущаяСтрокаДляЗаписи + Символы.ПС + mXMLRules + Символы.ПС + "</ФайлОбмена>"
		+ Символы.ПС;

	РаботаВозможна = мОбработкаДляЗагрузкиДанных.ВыполнитьДействияПередЧтениемДанных(ТекущаяСтрокаДляЗаписи);

	Возврат РаботаВозможна;

КонецФункции

Функция ВыполнитьПередачуИнформацииПриЗавершенииПередачиДанных()
	
	//УИ++
//	Если НЕ DirectReadFromDestinationIB Тогда
//		Возврат Истина;
//	КонецЕсли;
//	
//	мОбработкаДляЗагрузкиДанных.ВыполнитьДействияПослеЗавершенияЧтенияДанных();

	Если DirectReadFromDestinationIB Тогда
		мОбработкаДляЗагрузкиДанных.ВыполнитьДействияПослеЗавершенияЧтенияДанных();
	ИначеЕсли UT_ExportViaWebService Тогда
		Сообщить("Начало загрузки через вебсервис " + ТекущаяДата());
		КэшАрхивации=ArchiveFile;
		ArchiveFile=Истина;
		СжатьРезультирующийФайлОбмена();
		ArchiveFile=КэшАрхивации;

		ДвоичныеДанные=Новый ДвоичныеДанные(ExchangeFileName);

		ПараметрыЗапросаHTTP=Новый Структура;
		ПараметрыЗапросаHTTP.Вставить("Таймайт", 0);

		Аутентификация=Новый Структура;
		Аутентификация.Вставить("Пользователь", InfobaseConnectionUsername);
		Аутентификация.Вставить("Пароль", InfobaseConnectionPassword);
		ПараметрыЗапросаHTTP.Вставить("Аутентификация", Аутентификация);

		Попытка
			РезультатВыгрузки=УИ_КоннекторHTTP.Post(UT_DestinationPublicationAddress + "/hs/tools-ui-1c/exchange",
				ДвоичныеДанные, ПараметрыЗапросаHTTP);
			СтруктураРезультата=УИ_КоннекторHTTP.КакJson(РезультатВыгрузки);

			ЛогЗагрузки=СтруктураРезультата["ЛогЗагрузки"];
			Текст=Новый ТекстовыйДокумент;
			Текст.УстановитьТекст(ЛогЗагрузки);
			Для НомерСтрокиЛога = 1 По Текст.КоличествоСтрок() Цикл
				Сообщить(Текст.ПолучитьСтроку(НомерСтрокиЛога));

			КонецЦикла;

			Если ЗначениеЗаполнено(СтруктураРезультата["ОшибкаСервиса"]) Тогда
				Сообщить(СтруктураРезультата["ОшибкаСервиса"]);
			КонецЕсли;
		Исключение
			Сообщить("Ошибка отправки сообщения в приемник " + ОписаниеОшибки());
		КонецПопытки;

		Сообщить("Окончани загрузки через вебсервис " + ТекущаяДата());

	КонецЕсли;
	//УИ--

КонецФункции

Процедура ПередатьДополнительныеПараметрыВПриемник()

	Для Каждого Параметр Из ParametersSettingsTable Цикл

		Если Параметр.ПередаватьПараметрПриВыгрузке = Истина Тогда

			ПередатьОдинПараметрВПриемник(Параметр.Имя, Параметр.Значение, Параметр.ПравилоКонвертации);

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ПередатьИнформациюОТипахВПриемник()

	Если Не ПустаяСтрока(mTypeStringForDestination) Тогда
		ЗаписатьВФайл(mTypeStringForDestination);
	КонецЕсли;

КонецПроцедуры

// Выполняет выгрузку данных в соответствии с установленными режимами (правилами обмена).
//
// Parameters:
//  Нет.
//
Процедура ВыполнитьВыгрузку() Экспорт

	РежимОбработкиДанных = мРежимыОбработкиДанных.Выгрузка;

	ИнициализироватьВедениеПротоколаОбмена();

	ИнициализироватьКомментарииПриВыгрузкеИЗагрузкеДанных();

	ВыгрузкаВозможна = Истина;
	ТекущийУровеньВложенностиВыгрузитьПоПравилу = 0;

	мСтекВызововВыгрузкиДанных = Новый ТаблицаЗначений;
	мСтекВызововВыгрузкиДанных.Колонки.Добавить("Ссылка");
	мСтекВызововВыгрузкиДанных.Индексы.Добавить("Ссылка");

	Если мБылиПрочитаныПравилаОбменаПриЗагрузке = Истина Тогда

		ЗаписатьВПротоколВыполнения(74);
		ВыгрузкаВозможна = Ложь;

	КонецЕсли;

	Если ПустаяСтрока(ExchangeRulesFileName) Тогда
		ЗаписатьВПротоколВыполнения(12);
		ВыгрузкаВозможна = Ложь;
	КонецЕсли;

	Если Не DirectReadFromDestinationIB Тогда

		Если ПустаяСтрока(ExchangeFileName) Тогда
			ЗаписатьВПротоколВыполнения(10);
			ВыгрузкаВозможна = Ложь;
		КонецЕсли;

	Иначе

		мОбработкаДляЗагрузкиДанных = ВыполнитьПодключениеКИБПриемнику();

		ВыгрузкаВозможна = мОбработкаДляЗагрузкиДанных <> Неопределено;

	КонецЕсли;
	
	// Инициализируем внешнюю обработку с экспортными обработчиками.
	ИнициализацияВнешнейОбработкиОбработчиковСобытий(ВыгрузкаВозможна, ЭтотОбъект);

	Если Не ВыгрузкаВозможна Тогда
		мОбработкаДляЗагрузкиДанных = Неопределено;
		Возврат;
	КонецЕсли;

	ЗаписатьВПротоколВыполнения(ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Начало выгрузки: %1'"), ТекущаяДатаСеанса()), , Ложь, , , Истина);

	ИнициализироватьМенеджерыИСообщения();

	мСчетчикВыгруженныхОбъектов = 0;
	mSNCounter 				= 0;
	ErrorFlag                  = Ложь;

	// Загрузка правил обмена
	Если Конвертация.Количество() = 9 Тогда

		ЗагрузитьПравилаОбмена();
		Если ErrorFlag Тогда
			ЗавершитьВедениеПротоколаОбмена();
			мОбработкаДляЗагрузкиДанных = Неопределено;
			Возврат;
		КонецЕсли;

	Иначе

		Для Каждого Правило Из ConversionRulesTable Цикл
			Правило.Выгруженные.Очистить();
			Правило.ВыгруженныеТолькоСсылки.Очистить();
		КонецЦикла;

	КонецЕсли;

	// Присваиваем параметры установленные в диалоге.
	УстановитьПараметрыИзДиалога();

	// Открываем файл обмена
	ТекущаяСтрокаДляЗаписи = ОткрытьФайлВыгрузки() + Символы.ПС;

	Если ErrorFlag Тогда
		ФайлОбмена = Неопределено;
		ЗавершитьВедениеПротоколаОбмена();
		мОбработкаДляЗагрузкиДанных = Неопределено;
		Возврат;
	КонецЕсли;
	
	// Определяем интерфейсы обработчиков.
	Если HandlersDebugModeFlag Тогда

		ДополнитьПравилаИнтерфейсамиОбработчиков(Конвертация, ConversionRulesTable, ExportRulesTable,
			CleanupRulesTable);

	КонецЕсли;

	Если UseTransactions Тогда
		НачатьТранзакцию();
	КонецЕсли;

	Отказ = Ложь;
	
	//УИ++
	Если UT_ExportViaWebService Тогда
		SafeMode=Ложь;
	КонецЕсли;
	//УИ--

	Попытка
	
		// Включаем правила обмена в файл.
		ФайлОбмена.ЗаписатьСтроку(mXMLRules);

		Отказ = Не ВыполнитьПередачуИнформацииОНачалеОбменаВПриемник(ТекущаяСтрокаДляЗаписи);

		Если Не Отказ Тогда

			Если SafeMode Тогда
				УстановитьБезопасныйРежим(Истина);
				Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
					УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
				КонецЦикла;
			КонецЕсли;
			
			// Обработчик ПередВыгрузкойДанных
			Попытка

				Если HandlersDebugModeFlag Тогда

					Если Не ПустаяСтрока(Конвертация.ПередВыгрузкойДанных) Тогда

						Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПередВыгрузкойДанных"));

					КонецЕсли;

				Иначе

					Выполнить (Конвертация.ПередВыгрузкойДанных);

				КонецЕсли;

			Исключение
				ЗаписатьИнформациюОбОшибкеОбработчикиКонвертации(62, ОписаниеОшибки(), НСтр(
					"ru = 'ПередВыгрузкойДанных (конвертация)'"));
				Отказ = Истина;
			КонецПопытки;

			Если Не Отказ Тогда

				Если ExecuteDataExchangeInOptimizedFormat Тогда
					ПередатьИнформациюОТипахВПриемник();
				КонецЕсли;
				
				// Нужно параметры передать в приемник.
				ПередатьДополнительныеПараметрыВПриемник();

				ТекстСобытияПослеЗагрузкиПараметров = "";
				Если Конвертация.Свойство("ПослеЗагрузкиПараметров", ТекстСобытияПослеЗагрузкиПараметров)
					И Не ПустаяСтрока(ТекстСобытияПослеЗагрузкиПараметров) Тогда

					ЗаписьСобытия = Новый ЗаписьXML;
					ЗаписьСобытия.УстановитьСтроку();
					одЗаписатьЭлемент(ЗаписьСобытия, "АлгоритмПослеЗагрузкиПараметров",
						ТекстСобытияПослеЗагрузкиПараметров);
					ЗаписатьВФайл(ЗаписьСобытия);

				КонецЕсли;

				СоответствиеУзловИПравилВыгрузки = Новый Соответствие;
				СтруктураДляУдаленияРегистрацииИзменений = Новый Соответствие;

				ОбработатьПравилаВыгрузки(ExportRulesCollection().Строки, СоответствиеУзловИПравилВыгрузки);

				УдачноВыгруженоПоПланамОбмена = ОбработатьВыгрузкуДляПлановОбмена(СоответствиеУзловИПравилВыгрузки,
					СтруктураДляУдаленияРегистрацииИзменений);

				Если УдачноВыгруженоПоПланамОбмена Тогда

					ОбработатьИзменениеРегистрацииДляУзловОбмена(СтруктураДляУдаленияРегистрацииИзменений);

				КонецЕсли;
				
				// Обработчик ПослеВыгрузкиДанных
				Попытка

					Если HandlersDebugModeFlag Тогда

						Если Не ПустаяСтрока(Конвертация.ПослеВыгрузкиДанных) Тогда

							Выполнить (ПолучитьСтрокуВызоваОбработчика(Конвертация, "ПослеВыгрузкиДанных"));

						КонецЕсли;

					Иначе

						Выполнить (Конвертация.ПослеВыгрузкиДанных);

					КонецЕсли;

				Исключение
					ЗаписатьИнформациюОбОшибкеОбработчикиКонвертации(63, ОписаниеОшибки(), НСтр(
						"ru = 'ПослеВыгрузкиДанных (конвертация)'"));
				КонецПопытки;

				ПровестиЗаписьНеЗаписанныхОбъектов();

				Если ТранзакцияАктивна() Тогда
					ЗафиксироватьТранзакцию();
				КонецЕсли;

			КонецЕсли;

		КонецЕсли;

		Если Отказ Тогда

			Если ТранзакцияАктивна() Тогда
				ОтменитьТранзакцию();
			КонецЕсли;

			ВыполнитьПередачуИнформацииПриЗавершенииПередачиДанных();

			ЗавершитьВедениеПротоколаОбмена();
			мОбработкаДляЗагрузкиДанных = Неопределено;
			ФайлОбмена = Неопределено;

			ДеструкторВнешнейОбработкиОбработчиковСобытий();

		КонецЕсли;

	Исключение

		Если ТранзакцияАктивна() Тогда
			ОтменитьТранзакцию();
		КонецЕсли;

		Отказ = Истина;
		СтрокаОшибки = ОписаниеОшибки();

		ЗаписатьВПротоколВыполнения(ПодставитьПараметрыВСтроку(
			НСтр("ru = 'Ошибка при выгрузке данных: %1'"), СтрокаОшибки), Неопределено, Истина, , , Истина);

		ВыполнитьПередачуИнформацииПриЗавершенииПередачиДанных();

		ЗавершитьВедениеПротоколаОбмена();
		ЗакрытьФайл();
		мОбработкаДляЗагрузкиДанных = Неопределено;

	КонецПопытки;

	Если Отказ Тогда
		Возврат;
	КонецЕсли;
	
	// Закрываем файл обмена
	ЗакрытьФайл();

	Если ArchiveFile Тогда
		СжатьРезультирующийФайлОбмена();
	КонецЕсли;

	ВыполнитьПередачуИнформацииПриЗавершенииПередачиДанных();

	ЗаписатьВПротоколВыполнения(ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Окончание выгрузки: %1'"), ТекущаяДатаСеанса()), , Ложь, , , Истина);
	ЗаписатьВПротоколВыполнения(ПодставитьПараметрыВСтроку(
		НСтр("ru = 'Выгружено объектов: %1'"), мСчетчикВыгруженныхОбъектов), , Ложь, , , Истина);

	ЗавершитьВедениеПротоколаОбмена();

	мОбработкаДляЗагрузкиДанных = Неопределено;

	ДеструкторВнешнейОбработкиОбработчиковСобытий();

	Если IsInteractiveMode Тогда
		СообщитьПользователю(НСтр("ru = 'Выгрузка данных завершена.'"));
	КонецЕсли;

КонецПроцедуры

#КонецОбласти

#Область УстановкаЗначенийРеквизитовИМодальныхПеременныхОбработки

// Процедура установки значения глобальной переменной "ФлагОшибки".
//
// Параметры:
//  Значение - Булево, новое значение переменной "ФлагОшибки".
//  
Процедура УстановитьФлагОшибки(Значение)

	ErrorFlag = Значение;

	Если ErrorFlag Тогда

		ДеструкторВнешнейОбработкиОбработчиковСобытий(DebugModeFlag);

	КонецЕсли;

КонецПроцедуры

// Возвращает текущее значение версии обработки.
//
// Параметры:
//  Нет.
// 
// Возвращаемое значение:
//  Текущее значение версии обработки.
//
Функция ВерсияОбъектаСтрокой() Экспорт

	Возврат "2.1.8";

КонецФункции

#КонецОбласти

#Область ИнициализацияТаблицПравилОбмена

Процедура ДобавитьНедостающиеКолонки(Колонки, Имя, Типы = Неопределено)

	Если Колонки.Найти(Имя) <> Неопределено Тогда
		Возврат;
	КонецЕсли;

	Колонки.Добавить(Имя, Типы);

КонецПроцедуры

// Инициализирует колонки таблицы правил конвертации объектов.
//
// Параметры:
//  Нет.
// 
Процедура ИнициализацияТаблицыПравилКонвертации()

	Колонки = ConversionRulesTable.Колонки;

	ДобавитьНедостающиеКолонки(Колонки, "Имя");
	ДобавитьНедостающиеКолонки(Колонки, "Наименование");
	ДобавитьНедостающиеКолонки(Колонки, "Порядок");

	ДобавитьНедостающиеКолонки(Колонки, "СинхронизироватьПоИдентификатору");
	ДобавитьНедостающиеКолонки(Колонки, "НеСоздаватьЕслиНеНайден", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "НеВыгружатьОбъектыСвойствПоСсылкам", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ПродолжитьПоискПоПолямПоискаЕслиПоИдентификаторуНеНашли", одОписаниеТипа(
		"Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ИспользоватьБыстрыйПоискПриЗагрузке", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ГенерироватьНовыйНомерИлиКодЕслиНеУказан", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "МаленькоеКоличествоОбъектов", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "КоличествоОбращенийДляВыгрузкиСсылки", одОписаниеТипа("Число"));
	ДобавитьНедостающиеКолонки(Колонки, "КоличествоЭлементовВИБ", одОписаниеТипа("Число"));

	ДобавитьНедостающиеКолонки(Колонки, "СпособВыгрузки");

	ДобавитьНедостающиеКолонки(Колонки, "Источник");
	ДобавитьНедостающиеКолонки(Колонки, "Приемник");

	ДобавитьНедостающиеКолонки(Колонки, "ТипИсточника", одОписаниеТипа("Строка"));

	ДобавитьНедостающиеКолонки(Колонки, "ПередВыгрузкой");
	ДобавитьНедостающиеКолонки(Колонки, "ПриВыгрузке");
	ДобавитьНедостающиеКолонки(Колонки, "ПослеВыгрузки");
	ДобавитьНедостающиеКолонки(Колонки, "ПослеВыгрузкиВФайл");

	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПередВыгрузкой", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПриВыгрузке", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПослеВыгрузки", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПослеВыгрузкиВФайл", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "ПередЗагрузкой");
	ДобавитьНедостающиеКолонки(Колонки, "ПриЗагрузке");
	ДобавитьНедостающиеКолонки(Колонки, "ПослеЗагрузки");

	ДобавитьНедостающиеКолонки(Колонки, "ПоследовательностьПолейПоиска");
	ДобавитьНедостающиеКолонки(Колонки, "ПоискПоТабличнымЧастям");

	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПередЗагрузкой", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПриЗагрузке", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПослеЗагрузки", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "ЕстьОбработчикПоследовательностьПолейПоиска", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "СвойстваПоиска", одОписаниеТипа("ТаблицаЗначений"));
	ДобавитьНедостающиеКолонки(Колонки, "Свойства", одОписаниеТипа("ТаблицаЗначений"));

	ДобавитьНедостающиеКолонки(Колонки, "Значения", одОписаниеТипа("Соответствие"));

	ДобавитьНедостающиеКолонки(Колонки, "Выгруженные", одОписаниеТипа("Соответствие"));
	ДобавитьНедостающиеКолонки(Колонки, "ВыгруженныеТолькоСсылки", одОписаниеТипа("Соответствие"));
	ДобавитьНедостающиеКолонки(Колонки, "ВыгружатьПредставлениеИсточника", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "НеЗамещать", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "ЗапоминатьВыгруженные", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ВсеОбъектыВыгружены", одОписаниеТипа("Булево"));

КонецПроцедуры

// Инициализирует колонки таблицы правил выгрузки данных.
//
// Параметры:
//  Нет
// 
Процедура ИнициализацияТаблицыПравилВыгрузки()

	Колонки = ExportRulesTable.Колонки;

	ДобавитьНедостающиеКолонки(Колонки, "Включить", одОписаниеТипа("Число"));
	ДобавитьНедостающиеКолонки(Колонки, "ЭтоГруппа", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "Имя");
	ДобавитьНедостающиеКолонки(Колонки, "Наименование");
	ДобавитьНедостающиеКолонки(Колонки, "Порядок");

	ДобавитьНедостающиеКолонки(Колонки, "СпособОтбораДанных");
	ДобавитьНедостающиеКолонки(Колонки, "ОбъектВыборки");

	ДобавитьНедостающиеКолонки(Колонки, "ПравилоКонвертации");

	ДобавитьНедостающиеКолонки(Колонки, "ПередОбработкой");
	ДобавитьНедостающиеКолонки(Колонки, "ПослеОбработки");

	ДобавитьНедостающиеКолонки(Колонки, "ПередВыгрузкой");
	ДобавитьНедостающиеКолонки(Колонки, "ПослеВыгрузки");
	
	// Колонки для поддержки отбора с помощью построителя.
	ДобавитьНедостающиеКолонки(Колонки, "ИспользоватьОтбор", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "НастройкиПостроителя");
	ДобавитьНедостающиеКолонки(Колонки, "ИмяОбъектаДляЗапроса");
	ДобавитьНедостающиеКолонки(Колонки, "ИмяОбъектаДляЗапросаРегистра");

	ДобавитьНедостающиеКолонки(Колонки, "ВыбиратьДанныеДляВыгрузкиОднимЗапросом", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "СсылкаНаУзелОбмена");

	//УИ
	ДобавитьНедостающиеКолонки(Колонки, "ИмяМетаданных");
	ДобавитьНедостающиеКолонки(Колонки, "Отбор");

КонецПроцедуры

// Инициализирует колонки таблицы правил очистки данных.
//
// Параметры:
//  Нет.
// 
Процедура ИнициализацияТаблицыПравилОчистки()

	Колонки = CleanupRulesTable.Колонки;

	ДобавитьНедостающиеКолонки(Колонки, "Включить", одОписаниеТипа("Булево"));
	ДобавитьНедостающиеКолонки(Колонки, "ЭтоГруппа", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "Имя");
	ДобавитьНедостающиеКолонки(Колонки, "Наименование");
	ДобавитьНедостающиеКолонки(Колонки, "Порядок", одОписаниеТипа("Число"));

	ДобавитьНедостающиеКолонки(Колонки, "СпособОтбораДанных");
	ДобавитьНедостающиеКолонки(Колонки, "ОбъектВыборки");

	ДобавитьНедостающиеКолонки(Колонки, "УдалятьЗаПериод");
	ДобавитьНедостающиеКолонки(Колонки, "Непосредственно", одОписаниеТипа("Булево"));

	ДобавитьНедостающиеКолонки(Колонки, "ПередОбработкой");
	ДобавитьНедостающиеКолонки(Колонки, "ПослеОбработки");
	ДобавитьНедостающиеКолонки(Колонки, "ПередУдалением");

КонецПроцедуры

// Инициализирует колонки таблицы настройки параметров.
//
// Параметры:
//  Нет.
// 
Процедура ИнициализацияТаблицыНастройкиПараметров()

	Колонки = ParametersSettingsTable.Колонки;

	ДобавитьНедостающиеКолонки(Колонки, "Имя");
	ДобавитьНедостающиеКолонки(Колонки, "Наименование");
	ДобавитьНедостающиеКолонки(Колонки, "Значение");
	ДобавитьНедостающиеКолонки(Колонки, "ПередаватьПараметрПриВыгрузке");
	ДобавитьНедостающиеКолонки(Колонки, "ПравилоКонвертации");

КонецПроцедуры

#КонецОбласти

#Область ИнициализацияРеквизитовИМодульныхПеременных

Процедура ИнициализироватьКомментарииПриВыгрузкеИЗагрузкеДанных()

	CommentOnDataExport = "";
	CommentOnDataImport = "";

КонецПроцедуры

// Инициализирует переменную одСообщения, содержащую соответствия кодов сообщений их описаниям.
//
// Параметры:
//  Нет.
// 
Процедура ИнициализацияСообщений()

	одСообщения = Новый Соответствие;

	одСообщения.Вставить(2, НСтр("ru = 'Ошибка распаковки файла обмена. Файл заблокирован'"));
	одСообщения.Вставить(3, НСтр("ru = 'Указанный файл правил обмена не существует'"));
	одСообщения.Вставить(4, НСтр("ru = 'Ошибка при создании COM-объекта Msxml2.DOMDocument'"));
	одСообщения.Вставить(5, НСтр("ru = 'Ошибка открытия файла обмена'"));
	одСообщения.Вставить(6, НСтр("ru = 'Ошибка при загрузке правил обмена'"));
	одСообщения.Вставить(7, НСтр("ru = 'Ошибка формата правил обмена'"));
	одСообщения.Вставить(8, НСтр("ru = 'Некорректно указано имя файла для выгрузки данных'"));
	одСообщения.Вставить(9, НСтр("ru = 'Ошибка формата файла обмена'"));
	одСообщения.Вставить(10, НСтр("ru = 'Не указано имя файла для выгрузки данных (Имя файла данных)'"));
	одСообщения.Вставить(11, НСтр("ru = 'Ссылка на несуществующий объект метаданных в правилах обмена'"));
	одСообщения.Вставить(12, НСтр("ru = 'Не указано имя файла с правилами обмена (Имя файла правил)'"));

	одСообщения.Вставить(13, НСтр("ru = 'Ошибка получения значения свойства объекта (по имени свойства источника)'"));
	одСообщения.Вставить(14, НСтр("ru = 'Ошибка получения значения свойства объекта (по имени свойства приемника)'"));

	одСообщения.Вставить(15, НСтр("ru = 'Не указано имя файла для загрузки данных (Имя файла для загрузки)'"));

	одСообщения.Вставить(16, НСтр(
		"ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства источника)'"));
	одСообщения.Вставить(17, НСтр(
		"ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства приемника)'"));

	одСообщения.Вставить(19, НСтр("ru = 'Ошибка в обработчике события ПередЗагрузкойОбъекта'"));
	одСообщения.Вставить(20, НСтр("ru = 'Ошибка в обработчике события ПриЗагрузкеОбъекта'"));
	одСообщения.Вставить(21, НСтр("ru = 'Ошибка в обработчике события ПослеЗагрузкиОбъекта'"));
	одСообщения.Вставить(22, НСтр("ru = 'Ошибка в обработчике события ПередЗагрузкойДанных (конвертация)'"));
	одСообщения.Вставить(23, НСтр("ru = 'Ошибка в обработчике события ПослеЗагрузкиДанных (конвертация)'"));
	одСообщения.Вставить(24, НСтр("ru = 'Ошибка при удалении объекта'"));
	одСообщения.Вставить(25, НСтр("ru = 'Ошибка при записи документа'"));
	одСообщения.Вставить(26, НСтр("ru = 'Ошибка записи объекта'"));
	одСообщения.Вставить(27, НСтр("ru = 'Ошибка в обработчике события ПередОбработкойПравилаОчистки'"));
	одСообщения.Вставить(28, НСтр("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаОчистки'"));
	одСообщения.Вставить(29, НСтр("ru = 'Ошибка в обработчике события ПередУдалениемОбъекта'"));

	одСообщения.Вставить(31, НСтр("ru = 'Ошибка в обработчике события ПередОбработкойПравилаВыгрузки'"));
	одСообщения.Вставить(32, НСтр("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаВыгрузки'"));
	одСообщения.Вставить(33, НСтр("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта'"));
	одСообщения.Вставить(34, НСтр("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта'"));

	одСообщения.Вставить(39, НСтр("ru = 'Ошибка при выполнении алгоритма, содержащегося в файле обмена'"));

	одСообщения.Вставить(41, НСтр("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта'"));
	одСообщения.Вставить(42, НСтр("ru = 'Ошибка в обработчике события ПриВыгрузкеОбъекта'"));
	одСообщения.Вставить(43, НСтр("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта'"));

	одСообщения.Вставить(45, НСтр("ru = 'Не найдено правило конвертации объектов'"));

	одСообщения.Вставить(48, НСтр("ru = 'Ошибка в обработчике события ПередОбработкойВыгрузки группы свойств'"));
	одСообщения.Вставить(49, НСтр("ru = 'Ошибка в обработчике события ПослеОбработкиВыгрузки группы свойств'"));
	одСообщения.Вставить(50, НСтр("ru = 'Ошибка в обработчике события ПередВыгрузкой (объекта коллекции)'"));
	одСообщения.Вставить(51, НСтр("ru = 'Ошибка в обработчике события ПриВыгрузке (объекта коллекции)'"));
	одСообщения.Вставить(52, НСтр("ru = 'Ошибка в обработчике события ПослеВыгрузки (объекта коллекции)'"));
	одСообщения.Вставить(53, НСтр("ru = 'Ошибка в глобальном обработчике события ПередЗагрузкойОбъекта (конвертация)'"));
	одСообщения.Вставить(54, НСтр("ru = 'Ошибка в глобальном обработчике события ПослеЗагрузкиОбъекта (конвертация)'"));
	одСообщения.Вставить(55, НСтр("ru = 'Ошибка в обработчике события ПередВыгрузкой (свойства)'"));
	одСообщения.Вставить(56, НСтр("ru = 'Ошибка в обработчике события ПриВыгрузке (свойства)'"));
	одСообщения.Вставить(57, НСтр("ru = 'Ошибка в обработчике события ПослеВыгрузки (свойства)'"));

	одСообщения.Вставить(62, НСтр("ru = 'Ошибка в обработчике события ПередВыгрузкойДанных (конвертация)'"));
	одСообщения.Вставить(63, НСтр("ru = 'Ошибка в обработчике события ПослеВыгрузкиДанных (конвертация)'"));
	одСообщения.Вставить(64, НСтр(
		"ru = 'Ошибка в глобальном обработчике события ПередКонвертациейОбъекта (конвертация)'"));
	одСообщения.Вставить(65, НСтр("ru = 'Ошибка в глобальном обработчике события ПередВыгрузкойОбъекта (конвертация)'"));
	одСообщения.Вставить(66, НСтр("ru = 'Ошибка получения коллекции подчиненных объектов из входящих данных'"));
	одСообщения.Вставить(67, НСтр("ru = 'Ошибка получения свойства подчиненного объекта из входящих данных'"));
	одСообщения.Вставить(68, НСтр("ru = 'Ошибка получения свойства объекта из входящих данных'"));

	одСообщения.Вставить(69, НСтр("ru = 'Ошибка в глобальном обработчике события ПослеВыгрузкиОбъекта (конвертация)'"));

	одСообщения.Вставить(71, НСтр("ru = 'Не найдено соответствие для значения Источника'"));

	одСообщения.Вставить(72, НСтр("ru = 'Ошибка при выгрузке данных для узла плана обмена'"));

	одСообщения.Вставить(73, НСтр("ru = 'Ошибка в обработчике события ПоследовательностьПолейПоиска'"));

	одСообщения.Вставить(74, НСтр("ru = 'Необходимо перезагрузить правила обмена для выгрузки данных'"));

	одСообщения.Вставить(75, НСтр("ru = 'Ошибка при выполнении алгоритма после загрузки значений параметров'"));

	одСообщения.Вставить(76, НСтр("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъектаВФайл'"));

	одСообщения.Вставить(77, НСтр(
		"ru = 'Не указан файл внешней обработки с подключаемыми процедурами обработчиков событий'"));

	одСообщения.Вставить(78, НСтр(
		"ru = 'Ошибка создания внешней обработки из файла с процедурами обработчиков событий'"));

	одСообщения.Вставить(79, НСтр("ru = 'Код алгоритмов не может быть интегрирован в обработчик из-за обнаруженного рекурсивного вызова алгоритмов. 
								  |Если в процессе отладки нет необходимости отлаживать код алгоритмов, то укажите режим ""не отлаживать алгоритмы""
								  |Если необходимо выполнять отладку алгоритмов с рекурсивным вызовом, то укажите режим  ""алгоритмы отлаживать как процедуры"" 
								  |и повторите выгрузку.'"));

	одСообщения.Вставить(80, НСтр("ru = 'Обмен данными можно проводить только под полными правами'"));

	одСообщения.Вставить(1000, НСтр("ru = 'Ошибка при создании временного файла выгрузки данных'"));

КонецПроцедуры

Процедура ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, ИмяТипа, Менеджер,
	ПрефиксИмениТипа, ВозможенПоискПоПредопределенным = Ложь)

	Имя              = ОбъектМД.Имя;
	ТипСсылкиСтрокой = ПрефиксИмениТипа + "." + Имя;
	СтрокаПоиска     = "ВЫБРАТЬ Ссылка ИЗ " + ИмяТипа + "." + Имя + " ГДЕ ";
	ТипСсылки        = Тип(ТипСсылкиСтрокой);
	Структура = СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД);
	Структура.Вставить("ВозможенПоискПоПредопределенным", ВозможенПоискПоПредопределенным);
	Структура.Вставить("СтрокаПоиска", СтрокаПоиска);
	Менеджеры.Вставить(ТипСсылки, Структура);
	СтруктураДляПланаОбмена = СтруктураПараметровПланаОбмена(Имя, ТипСсылки, Истина, Ложь);
	МенеджерыДляПлановОбмена.Вставить(ОбъектМД, СтруктураДляПланаОбмена);

КонецПроцедуры

Процедура ДополнитьМассивМенеджеровТипомРегистра(Менеджеры, ОбъектМД, ИмяТипа, Менеджер, ПрефиксИмениТипаЗапись,
	ПрефиксИмениТипаВыборка)

	Периодический = Неопределено;

	Имя					= ОбъектМД.Имя;
	ТипСсылкиСтрокой	= ПрефиксИмениТипаЗапись + "." + Имя;
	ТипСсылки			= Тип(ТипСсылкиСтрокой);
	Структура = СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД);

	Если ИмяТипа = "РегистрСведений" Тогда

		Периодический = (ОбъектМД.ПериодичностьРегистраСведений
			<> Метаданные.СвойстваОбъектов.ПериодичностьРегистраСведений.Непериодический);
		ПодчиненныйРегистратору = (ОбъектМД.РежимЗаписи
			= Метаданные.СвойстваОбъектов.РежимЗаписиРегистра.ПодчинениеРегистратору);

		Структура.Вставить("Периодический", Периодический);
		Структура.Вставить("ПодчиненныйРегистратору", ПодчиненныйРегистратору);

	КонецЕсли;

	Менеджеры.Вставить(ТипСсылки, Структура);
	СтруктураДляПланаОбмена = СтруктураПараметровПланаОбмена(Имя, ТипСсылки, Ложь, Истина);

	МенеджерыДляПлановОбмена.Вставить(ОбъектМД, СтруктураДляПланаОбмена);
	ТипСсылкиСтрокой	= ПрефиксИмениТипаВыборка + "." + Имя;
	ТипСсылки			= Тип(ТипСсылкиСтрокой);
	Структура = СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД);

	Если Периодический <> Неопределено Тогда

		Структура.Вставить("Периодический", Периодический);
		Структура.Вставить("ПодчиненныйРегистратору", ПодчиненныйРегистратору);

	КонецЕсли;

	Менеджеры.Вставить(ТипСсылки, Структура);

КонецПроцедуры

// Инициализирует переменную Менеджеры, содержащую соответствия типов объектов их свойствам.
//
// Parameters:
//  Нет.
// 
Процедура ИнициализацияМенеджеров()

	Менеджеры = Новый Соответствие;

	МенеджерыДляПлановОбмена = Новый Соответствие;
    	
	// ССЫЛКИ

	Для Каждого ОбъектМД Из Метаданные.Справочники Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "Справочник",
			Справочники[ОбъектМД.Имя], "СправочникСсылка", Истина);

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.Документы Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "Документ",
			Документы[ОбъектМД.Имя], "ДокументСсылка");

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.ПланыВидовХарактеристик Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД,
			"ПланВидовХарактеристик", ПланыВидовХарактеристик[ОбъектМД.Имя], "ПланВидовХарактеристикСсылка", Истина);

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.ПланыСчетов Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "ПланСчетов",
			ПланыСчетов[ОбъектМД.Имя], "ПланСчетовСсылка", Истина);

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.ПланыВидовРасчета Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "ПланВидовРасчета",
			ПланыВидовРасчета[ОбъектМД.Имя], "ПланВидовРасчетаСсылка", Истина);

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.ПланыОбмена Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "ПланОбмена",
			ПланыОбмена[ОбъектМД.Имя], "ПланОбменаСсылка");

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.Задачи Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "Задача",
			Задачи[ОбъектМД.Имя], "ЗадачаСсылка");

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.БизнесПроцессы Цикл

		ДополнитьМассивМенеджеровСсылочнымТипом(Менеджеры, МенеджерыДляПлановОбмена, ОбъектМД, "БизнесПроцесс",
			БизнесПроцессы[ОбъектМД.Имя], "БизнесПроцессСсылка");

		ИмяТипа = "ТочкаМаршрутаБизнесПроцесса";
		// ссылка на точки маршрута
		Имя              = ОбъектМД.Имя;
		Менеджер         = БизнесПроцессы[Имя].ТочкиМаршрута;
		СтрокаПоиска     = "";
		ТипСсылкиСтрокой = "ТочкаМаршрутаБизнесПроцессаСсылка." + Имя;
		ТипСсылки        = Тип(ТипСсылкиСтрокой);
		Структура = СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД);
		Структура.Вставить("ПустаяСсылка", Неопределено);
		Структура.Вставить("СтрокаПоиска", СтрокаПоиска);
		Менеджеры.Вставить(ТипСсылки, Структура);

	КонецЦикла;
	
	// РЕГИСТРЫ

	Для Каждого ОбъектМД Из Метаданные.РегистрыСведений Цикл

		ДополнитьМассивМенеджеровТипомРегистра(Менеджеры, ОбъектМД, "РегистрСведений", РегистрыСведений[ОбъектМД.Имя],
			"РегистрСведенийЗапись", "РегистрСведенийВыборка");

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.РегистрыБухгалтерии Цикл

		ДополнитьМассивМенеджеровТипомРегистра(Менеджеры, ОбъектМД, "РегистрБухгалтерии",
			РегистрыБухгалтерии[ОбъектМД.Имя], "РегистрБухгалтерииЗапись", "РегистрБухгалтерииВыборка");

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.РегистрыНакопления Цикл

		ДополнитьМассивМенеджеровТипомРегистра(Менеджеры, ОбъектМД, "РегистрНакопления",
			РегистрыНакопления[ОбъектМД.Имя], "РегистрНакопленияЗапись", "РегистрНакопленияВыборка");

	КонецЦикла;

	Для Каждого ОбъектМД Из Метаданные.РегистрыРасчета Цикл

		ДополнитьМассивМенеджеровТипомРегистра(Менеджеры, ОбъектМД, "РегистрРасчета", РегистрыРасчета[ОбъектМД.Имя],
			"РегистрРасчетаЗапись", "РегистрРасчетаВыборка");

	КонецЦикла;

	ИмяТипа = "Перечисление";

	Для Каждого ОбъектМД Из Метаданные.Перечисления Цикл

		Имя              = ОбъектМД.Имя;
		Менеджер         = Перечисления[Имя];
		ТипСсылкиСтрокой = "ПеречислениеСсылка." + Имя;
		ТипСсылки        = Тип(ТипСсылкиСтрокой);
		Структура = СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД);
		Структура.Вставить("ПустаяСсылка", Перечисления[Имя].ПустаяСсылка());

		Менеджеры.Вставить(ТипСсылки, Структура);

	КонецЦикла;	
	
	// Константы
	ИмяТипа             = "Константы";
	ОбъектМД            = Метаданные.Константы;
	Имя					= "Константы";
	Менеджер			= Константы;
	ТипСсылкиСтрокой	= "КонстантыНабор";
	ТипСсылки			= Тип(ТипСсылкиСтрокой);
	Структура = СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД);
	Менеджеры.Вставить(ТипСсылки, Структура);

КонецПроцедуры

// Выполняет инициализация менеджеров объектов и всех сообщений протокола обмена данными.
//
// Parameters:
//  Нет.
// 
Процедура ИнициализироватьМенеджерыИСообщения() Экспорт

	Если Менеджеры = Неопределено Тогда
		ИнициализацияМенеджеров();
	КонецЕсли;

	Если одСообщения = Неопределено Тогда
		ИнициализацияСообщений();
	КонецЕсли;

КонецПроцедуры

// Возвращаемое значение:
//   Структура - поля:
//     * ВерсияФормата - Строка -
//     * Ид - Строка -
//     * Наименование - Строка -
//     * ДатаВремяСоздания - Дата -
//     * ВерсияПлатформыИсточника - Строка -
//     * СинонимКонфигурацииИсточника - Строка -
//     * ВерсияКонфигурацииИсточника - Строка -
//     * Источник - Строка -
//     * ВерсияПлатформыПриемника - Строка -
//     * СинонимКонфигурацииПриемника - Строка -
//     * ВерсияКонфигурацииПриемника - Строка -
//     * Приемник - Строка -
//     * ПослеЗагрузкиПравилОбмена - Строка -
//     * ПередВыгрузкойДанных - Строка -
//     * ПередПолучениемИзмененныхОбъектов - Строка -
//     * ПослеПолученияИнформацииОбУзлахОбмена - Строка -
//     * ПослеВыгрузкиДанных - Строка -
//     * ПередОтправкойИнформацииОбУдалении - Строка -
//     * ПередВыгрузкойОбъекта - Строка -
//     * ПослеВыгрузкиОбъекта - Строка -
//     * ПередЗагрузкойОбъекта - Строка -
//     * ПослеЗагрузкиОбъекта - Строка -
//     * ПередКонвертациейОбъекта - Строка -
//     * ПередЗагрузкойДанных - Строка -
//     * ПослеЗагрузкиДанных - Строка -
//     * ПослеЗагрузкиПараметров - Строка -
//     * ПриПолученииИнформацииОбУдалении - Строка -
//
Функция Конвертация()
	Возврат Конвертация;
КонецФункции

// Возвращаемое значение:
//   Структура - содержит поля:
//     * Имя - Строка -
//     * ИмяТипа - Строка -
//     * ТипСсылкиСтрокой - Строка -
//     * Менеджер - СправочникМенеджер, ДокументМенеджер, РегистрСведенийМенеджер, и т.п. -
//     * ОбъектМД - ОбъектМетаданныхСправочник, ОбъектМетаданныхДокумент, ОбъектМетаданныхРегистрСведений, и т.п. -
//     * ПКО - см. НайтиПравило
//
Функция Менеджеры(Тип)
	Возврат Менеджеры[Тип];
КонецФункции

Процедура СоздатьСтруктуруКонвертации()

	Конвертация  = Новый Структура("ПередВыгрузкойДанных, ПослеВыгрузкиДанных, ПередВыгрузкойОбъекта, ПослеВыгрузкиОбъекта, ПередКонвертациейОбъекта, ПередЗагрузкойОбъекта, ПослеЗагрузкиОбъекта, ПередЗагрузкойДанных, ПослеЗагрузкиДанных");

КонецПроцедуры

// Инициализирует реквизиты обработки и модульные переменные.
//
// Parameters:
//  Нет.
// 
Процедура ИнициализацияРеквизитовИМодульныхПеременных()

	ProcessedObjectsCountToUpdateStatus = 100;

	ЗапоминатьЗагруженныеОбъекты     = Истина;
	ЧислоХранимыхЗагруженныхОбъектов = 5000;

	ПараметрыИнициализированы        = Ложь;

	XMLWriterAdvancedMonitoring = Ложь;
	DirectReadFromDestinationIB = Ложь;
	DoNotShowInfoMessagesToUser = Ложь;

	Менеджеры    = Неопределено;
	одСообщения  = Неопределено;

	ErrorFlag   = Ложь;

	СоздатьСтруктуруКонвертации();

	Правила      = Новый Структура;
	Алгоритмы    = Новый Структура;
	ДопОбработки = Новый Структура;
	Запросы      = Новый Структура;

	Parameters    = Новый Структура;
	СобытияПослеЗагрузкиПараметров = Новый Структура;

	ПараметрыДопОбработок = Новый Структура;
	
	// Типы
	одТипСтрока                  = Тип("Строка");
	одТипБулево                  = Тип("Булево");
	одТипЧисло                   = Тип("Число");
	одТипДата                    = Тип("Дата");
	одТипХранилищеЗначения       = Тип("ХранилищеЗначения");
	одТипУникальныйИдентификатор = Тип("УникальныйИдентификатор");
	одТипДвоичныеДанные          = Тип("ДвоичныеДанные");
	одТипВидДвиженияНакопления   = Тип("ВидДвиженияНакопления");
	одТипУдалениеОбъекта         = Тип("УдалениеОбъекта");
	одТипВидСчета			     = Тип("ВидСчета");
	одТипТип                     = Тип("Тип");
	одТипСоответствие            = Тип("Соответствие");

	ЗначениеПустаяДата		   = Дата('00010101');

	mXMLRules  = Неопределено;
	
	// Типы узлов xml

	одТипУзлаXML_КонецЭлемента  = ТипУзлаXML.КонецЭлемента;
	одТипУзлаXML_НачалоЭлемента = ТипУзлаXML.НачалоЭлемента;
	одТипУзлаXML_Текст          = ТипУзлаXML.Текст;
	мСписокМакетовПравилОбмена  = Новый СписокЗначений;

	Для Каждого Макет Из Метаданные().Макеты Цикл
		мСписокМакетовПравилОбмена.Добавить(Макет.Синоним);
	КонецЦикла;

	мФайлПротоколаДанных = Неопределено;

	ConnectedInfobaseType = Истина;
	InfobaseConnectionWindowsAuthentification = Ложь;
	PlatformVersionForInfobaseConnection = "V8";
	OpenExchangeLogAfterExecutingOperations = Ложь;
	ImportDataInExchangeMode = Истина;
	WriteToInfobaseOnlyChangedObjects = Истина;
	WriteRegistersAsRecordSets = Истина;
	OptimizedObjectsWriting = Истина;
	ExportAllowedObjectsOnly = Истина;
	ImportReferencedObjectsWithoutDeletionMark = Истина;
	UseFilterByDateForAllObjects = Истина;

	мСоответствиеПустыхЗначенийТипов = Новый Соответствие;
	мСоответствиеОписаниеТипов = Новый Соответствие;

	мБылиПрочитаныПравилаОбменаПриЗагрузке = Ложь;

	ReadEventHandlersFromExchangeRulesFile = Истина;

	мРежимыОбработкиДанных = Новый Структура;
	мРежимыОбработкиДанных.Вставить("Выгрузка", 0);
	мРежимыОбработкиДанных.Вставить("Загрузка", 1);
	мРежимыОбработкиДанных.Вставить("ЗагрузкаПравилОбмена", 2);
	мРежимыОбработкиДанных.Вставить("ЭкспортОбработчиковСобытий", 3);

	РежимОбработкиДанных = мРежимыОбработкиДанных.Выгрузка;

	мРежимыОтладкиАлгоритмов = Новый Структура;
	мРежимыОтладкиАлгоритмов.Вставить("НеИспользовать", 0);
	мРежимыОтладкиАлгоритмов.Вставить("ПроцедурныйВызов", 1);
	мРежимыОтладкиАлгоритмов.Вставить("ИнтеграцияКода", 2);

	AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.НеИспользовать;
	
	// Модули стандартных подсистем.
	Попытка
		// Вызов ВычислитьВБезопасномРежиме не требуется, т.к. для вычисления передается строковый литерал.
		МодульДатыЗапретаИзменения = Вычислить("ДатыЗапретаИзменения");
	Исключение
		МодульДатыЗапретаИзменения = Неопределено;
	КонецПопытки;

	РазделителиКонфигурации = Новый Массив;
	Для Каждого ОбщийРеквизит Из Метаданные.ОбщиеРеквизиты Цикл
		Если ОбщийРеквизит.РазделениеДанных = Метаданные.СвойстваОбъектов.РазделениеДанныхОбщегоРеквизита.Разделять Тогда
			РазделителиКонфигурации.Добавить(ОбщийРеквизит.Имя);
		КонецЕсли;
	КонецЦикла;
	РазделителиКонфигурации = Новый ФиксированныйМассив(РазделителиКонфигурации);

	FilesTempDirectory = ПолучитьИмяВременногоФайла();
	УдалитьФайлы(FilesTempDirectory);

КонецПроцедуры

Функция ОпределитьДостаточностьПараметровДляПодключенияКИнформационнойБазе(СтруктураПодключения,
	СтрокаПодключения = "", СтрокаСообщенияОбОшибке = "")

	НаличиеОшибок = Ложь;

	Если СтруктураПодключения.ФайловыйРежим Тогда

		Если ПустаяСтрока(СтруктураПодключения.КаталогИБ) Тогда

			СтрокаСообщенияОбОшибке = НСтр("ru = 'Не задан каталог информационной базы-приемника'");

			СообщитьПользователю(СтрокаСообщенияОбОшибке);

			НаличиеОшибок = Истина;

		КонецЕсли;

		СтрокаПодключения = "File=""" + СтруктураПодключения.КаталогИБ + """";
	Иначе

		Если ПустаяСтрока(СтруктураПодключения.ИмяСервера) Тогда

			СтрокаСообщенияОбОшибке = НСтр("ru = 'Не задано имя сервера 1С:Предприятия информационной базы-приемника'");

			СообщитьПользователю(СтрокаСообщенияОбОшибке);

			НаличиеОшибок = Истина;

		КонецЕсли;

		Если ПустаяСтрока(СтруктураПодключения.ИмяИБНаСервере) Тогда

			СтрокаСообщенияОбОшибке = НСтр(
				"ru = 'Не задано имя информационной базы-приемника на сервере 1С:Предприятия'");

			СообщитьПользователю(СтрокаСообщенияОбОшибке);

			НаличиеОшибок = Истина;

		КонецЕсли;

		СтрокаПодключения = "Srvr = """ + СтруктураПодключения.ИмяСервера + """; Ref = """
			+ СтруктураПодключения.ИмяИБНаСервере + """";

	КонецЕсли;

	Возврат Не НаличиеОшибок;

КонецФункции

Функция ПодключитсяКИнформационнойБазе(СтруктураПодключения, СтрокаСообщенияОбОшибке = "")

	Перем СтрокаПодключения;

	ПараметровДостаточно = ОпределитьДостаточностьПараметровДляПодключенияКИнформационнойБазе(СтруктураПодключения,
		СтрокаПодключения, СтрокаСообщенияОбОшибке);

	Если Не ПараметровДостаточно Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если Не СтруктураПодключения.АутентификацияWindows Тогда
		Если Не ПустаяСтрока(СтруктураПодключения.Пользователь) Тогда
			СтрокаПодключения = СтрокаПодключения + ";Usr = """ + СтруктураПодключения.Пользователь + """";
		КонецЕсли;
		Если Не ПустаяСтрока(СтруктураПодключения.Пароль) Тогда
			СтрокаПодключения = СтрокаПодключения + ";Pwd = """ + СтруктураПодключения.Пароль + """";
		КонецЕсли;
	КонецЕсли;
	
	// "V82" или "V83"
	ОбъектПодключения = СтруктураПодключения.ВерсияПлатформы;

	СтрокаПодключения = СтрокаПодключения + ";";

	Попытка

		ОбъектПодключения = ОбъектПодключения + ".COMConnector";
		ТекCOMПодключение = Новый COMОбъект(ОбъектПодключения);
		ТекCOMОбъект = ТекCOMПодключение.Connect(СтрокаПодключения);

	Исключение

		СтрокаСообщенияОбОшибке = НСтр("ru = 'При попытке соединения с COM-сервером произошла следующая ошибка:
									   |%1'");
		СтрокаСообщенияОбОшибке = ПодставитьПараметрыВСтроку(СтрокаСообщенияОбОшибке, ОписаниеОшибки());

		СообщитьПользователю(СтрокаСообщенияОбОшибке);

		Возврат Неопределено;

	КонецПопытки;

	Возврат ТекCOMОбъект;

КонецФункции

// Функция возвращает часть строки после последнего встреченного символа в строке.
Функция ПолучитьСтрокуОтделеннойСимволом(Знач ИсходнаяСтрока, Знач СимволПоиска)

	ПозицияСимвола = СтрДлина(ИсходнаяСтрока);
	Пока ПозицияСимвола >= 1 Цикл

		Если Сред(ИсходнаяСтрока, ПозицияСимвола, 1) = СимволПоиска Тогда

			Возврат Сред(ИсходнаяСтрока, ПозицияСимвола + 1);

		КонецЕсли;

		ПозицияСимвола = ПозицияСимвола - 1;
	КонецЦикла;

	Возврат "";

КонецФункции

// Выделяет из имени файла его расширение (набор символов после последней точки).
//
// Параметры:
//  ИмяФайла     - Строка, содержащая имя файла, неважно с именем каталога или без.
//
// Возвращаемое значение:
//   Строка - расширение файла.
//
Функция ПолучитьРасширениеИмениФайла(Знач ИмяФайла) Экспорт

	Расширение = ПолучитьСтрокуОтделеннойСимволом(ИмяФайла, ".");
	Возврат Расширение;

КонецФункции

Функция ПолучитьИмяПротоколаДляВторойИнформационнойБазыComСоединения() Экспорт

	Если Не ПустаяСтрока(ImportExchangeLogFileName) Тогда

		Возврат ImportExchangeLogFileName;

	ИначеЕсли Не ПустаяСтрока(ExchangeLogFileName) Тогда

		РасширениеФайлаПротокола = ПолучитьРасширениеИмениФайла(ExchangeLogFileName);

		Если Не ПустаяСтрока(РасширениеФайлаПротокола) Тогда

			ИмяФайлаПротоколаВыгрузки = СтрЗаменить(ExchangeLogFileName, "." + РасширениеФайлаПротокола, "");

		КонецЕсли;

		ИмяФайлаПротоколаВыгрузки = ИмяФайлаПротоколаВыгрузки + "_Загрузка";

		Если Не ПустаяСтрока(РасширениеФайлаПротокола) Тогда

			ИмяФайлаПротоколаВыгрузки = ИмяФайлаПротоколаВыгрузки + "." + РасширениеФайлаПротокола;

		КонецЕсли;

		Возврат ИмяФайлаПротоколаВыгрузки;

	КонецЕсли;

	Возврат "";

КонецФункции

// Выполняет подключение к базе-приемнику по заданным параметрам.
// Возвращает проинициализированную обработку УниверсальныйОбменДаннымиXML базы-приемника,
// которая будет использоваться для загрузки данных в базу-приемник.
//
// Параметры:
//  Нет.
// 
//  Возвращаемое значение:
//    ОбработкаОбъект - УниверсальныйОбменДаннымиXML - обработка базы-приемника для загрузки данных в базу-приемник.
//
Функция ВыполнитьПодключениеКИБПриемнику() Экспорт

	РезультатПодключения = Неопределено;

	СтруктураПодключения = Новый Структура;
	СтруктураПодключения.Вставить("ФайловыйРежим", ConnectedInfobaseType);
	СтруктураПодключения.Вставить("АутентификацияWindows", InfobaseConnectionWindowsAuthentification);
	СтруктураПодключения.Вставить("КаталогИБ", InfobaseConnectionDirectory);
	СтруктураПодключения.Вставить("ИмяСервера", InfobaseConnectionServerName);
	СтруктураПодключения.Вставить("ИмяИБНаСервере", InfobaseConnectionNameAtServer);
	СтруктураПодключения.Вставить("Пользователь", InfobaseConnectionUsername);
	СтруктураПодключения.Вставить("Пароль", InfobaseConnectionPassword);
	СтруктураПодключения.Вставить("ВерсияПлатформы", PlatformVersionForInfobaseConnection);

	ОбъектПодключения = ПодключитсяКИнформационнойБазе(СтруктураПодключения);

	Если ОбъектПодключения = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;

	Попытка
		РезультатПодключения = ОбъектПодключения.Обработки.УниверсальныйОбменДаннымиXML.Создать();
	Исключение

		Текст = НСтр("ru = 'При попытке создания обработки УниверсальныйОбменДаннымиXML произошла ошибка: %1'");
		Текст = ПодставитьПараметрыВСтроку(Текст, КраткоеПредставлениеОшибки(ИнформацияОбОшибке()));
		СообщитьПользователю(Текст);
		РезультатПодключения = Неопределено;
	КонецПопытки;

	Если РезультатПодключения <> Неопределено Тогда

		РезультатПодключения.UseTransactions = UseTransactions;
		РезультатПодключения.ObjectsPerTransaction = ObjectsPerTransaction;

		РезультатПодключения.DebugModeFlag = DebugModeFlag;

		РезультатПодключения.ИмяФайлаПротоколаОбмена = ПолучитьИмяПротоколаДляВторойИнформационнойБазыComСоединения();

		РезультатПодключения.AppendDataToExchangeLog = AppendDataToExchangeLog;
		РезультатПодключения.WriteInfoMessagesToLog = WriteInfoMessagesToLog;

		РезультатПодключения.РежимОбмена = "Загрузка";

	КонецЕсли;

	Возврат РезультатПодключения;

КонецФункции

// Выполняет удаление объектов заданного типа по правилам очистки данных
// (физическое удаление или пометка на удаление).
//
// Параметры:
//  ИмяТипаДляУдаления - Строка - имя типа в строковом представлении.
// 
Процедура УдалитьОбъектыТипа(ИмяТипаДляУдаления) Экспорт

	ТипДанныхДляУдаления = Тип(ИмяТипаДляУдаления);

	Менеджер = Менеджеры[ТипДанныхДляУдаления];
	ИмяТипа  = Менеджер.ИмяТипа;
	Свойства = Менеджеры[ТипДанныхДляУдаления];

	Правило = Новый Структура("Имя,Непосредственно,ПередУдалением", "УдалениеОбъекта", Истина, "");

	Выборка = ПолучитьВыборкуДляВыгрузкиОчисткиДанных(Свойства, ИмяТипа, Истина, Истина, Ложь);

	Пока Выборка.Следующий() Цикл

		Если ИмяТипа = "РегистрСведений" Тогда

			МенеджерЗаписи = Свойства.Менеджер.СоздатьМенеджерЗаписи();
			ЗаполнитьЗначенияСвойств(МенеджерЗаписи, Выборка);

			УдалениеОбъектаВыборки(МенеджерЗаписи, Правило, Свойства, Неопределено);

		Иначе

			УдалениеОбъектаВыборки(Выборка.Ссылка.ПолучитьОбъект(), Правило, Свойства, Неопределено);

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ДополнитьСлужебныеТаблицыКолонками()

	ИнициализацияТаблицыПравилКонвертации();
	ИнициализацияТаблицыПравилВыгрузки();
	ИнициализацияТаблицыПравилОчистки();
	ИнициализацияТаблицыНастройкиПараметров();

КонецПроцедуры

Функция ПолучитьНовоеУникальноеИмяВременногоФайла(СтароеИмяВременногоФайла, Расширение = "txt")

	УдалитьВременныеФайлы(СтароеИмяВременногоФайла);

	Возврат ПолучитьИмяВременногоФайла(Расширение);

КонецФункции

Процедура ИнициализацияСтруктурыИменОбработчиков()
	
	// Обработчики Конвертации.
	ИменаОбработчиковКонвертации = Новый Структура;
	ИменаОбработчиковКонвертации.Вставить("ПередВыгрузкойДанных");
	ИменаОбработчиковКонвертации.Вставить("ПослеВыгрузкиДанных");
	ИменаОбработчиковКонвертации.Вставить("ПередВыгрузкойОбъекта");
	ИменаОбработчиковКонвертации.Вставить("ПослеВыгрузкиОбъекта");
	ИменаОбработчиковКонвертации.Вставить("ПередКонвертациейОбъекта");
	ИменаОбработчиковКонвертации.Вставить("ПередОтправкойИнформацииОбУдалении");
	ИменаОбработчиковКонвертации.Вставить("ПередПолучениемИзмененныхОбъектов");

	ИменаОбработчиковКонвертации.Вставить("ПередЗагрузкойОбъекта");
	ИменаОбработчиковКонвертации.Вставить("ПослеЗагрузкиОбъекта");
	ИменаОбработчиковКонвертации.Вставить("ПередЗагрузкойДанных");
	ИменаОбработчиковКонвертации.Вставить("ПослеЗагрузкиДанных");
	ИменаОбработчиковКонвертации.Вставить("ПриПолученииИнформацииОбУдалении");
	ИменаОбработчиковКонвертации.Вставить("ПослеПолученияИнформацииОбУзлахОбмена");

	ИменаОбработчиковКонвертации.Вставить("ПослеЗагрузкиПравилОбмена");
	ИменаОбработчиковКонвертации.Вставить("ПослеЗагрузкиПараметров");
	
	// Обработчики ПКО.
	ИменаОбработчиковПКО = Новый Структура;
	ИменаОбработчиковПКО.Вставить("ПередВыгрузкой");
	ИменаОбработчиковПКО.Вставить("ПриВыгрузке");
	ИменаОбработчиковПКО.Вставить("ПослеВыгрузки");
	ИменаОбработчиковПКО.Вставить("ПослеВыгрузкиВФайл");

	ИменаОбработчиковПКО.Вставить("ПередЗагрузкой");
	ИменаОбработчиковПКО.Вставить("ПриЗагрузке");
	ИменаОбработчиковПКО.Вставить("ПослеЗагрузки");

	ИменаОбработчиковПКО.Вставить("ПоследовательностьПолейПоиска");
	
	// Обработчики ПКС.
	ИменаОбработчиковПКС = Новый Структура;
	ИменаОбработчиковПКС.Вставить("ПередВыгрузкой");
	ИменаОбработчиковПКС.Вставить("ПриВыгрузке");
	ИменаОбработчиковПКС.Вставить("ПослеВыгрузки");

	// Обработчики ПКГС.
	ИменаОбработчиковПКГС = Новый Структура;
	ИменаОбработчиковПКГС.Вставить("ПередВыгрузкой");
	ИменаОбработчиковПКГС.Вставить("ПриВыгрузке");
	ИменаОбработчиковПКГС.Вставить("ПослеВыгрузки");

	ИменаОбработчиковПКГС.Вставить("ПередОбработкойВыгрузки");
	ИменаОбработчиковПКГС.Вставить("ПослеОбработкиВыгрузки");
	
	// Обработчики ПВД.
	ИменаОбработчиковПВД = Новый Структура;
	ИменаОбработчиковПВД.Вставить("ПередОбработкой");
	ИменаОбработчиковПВД.Вставить("ПослеОбработки");
	ИменаОбработчиковПВД.Вставить("ПередВыгрузкой");
	ИменаОбработчиковПВД.Вставить("ПослеВыгрузки");
	
	// Обработчики ПОД.
	ИменаОбработчиковПОД = Новый Структура;
	ИменаОбработчиковПОД.Вставить("ПередОбработкой");
	ИменаОбработчиковПОД.Вставить("ПослеОбработки");
	ИменаОбработчиковПОД.Вставить("ПередУдалением");
	
	// Глобальная структура с именами обработчиков.
	ИменаОбработчиков = Новый Структура;
	ИменаОбработчиков.Вставить("Конвертация", ИменаОбработчиковКонвертации);
	ИменаОбработчиков.Вставить("ПКО", ИменаОбработчиковПКО);
	ИменаОбработчиков.Вставить("ПКС", ИменаОбработчиковПКС);
	ИменаОбработчиков.Вставить("ПКГС", ИменаОбработчиковПКГС);
	ИменаОбработчиков.Вставить("ПВД", ИменаОбработчиковПВД);
	ИменаОбработчиков.Вставить("ПОД", ИменаОбработчиковПОД);

КонецПроцедуры  

// Возвращаемое значение:
//   Структура - описание менеджера типа значения:
//     * Имя - Строка -
//     * ИмяТипа - Строка -
//     * ТипСсылкиСтрокой - Строка -
//     * Менеджер - Произвольный -
//     * ОбъектМД - ОбъектМетаданных -
//     * ВозможенПоискПоПредопределенным - Булево -
//     * ПКО - Произвольный -
//
Функция СтруктураПараметровМенеджера(Имя, ИмяТипа, ТипСсылкиСтрокой, Менеджер, ОбъектМД)
	Структура = Новый Структура;
	Структура.Вставить("Имя", Имя);
	Структура.Вставить("ИмяТипа", ИмяТипа);
	Структура.Вставить("ТипСсылкиСтрокой", ТипСсылкиСтрокой);
	Структура.Вставить("Менеджер", Менеджер);
	Структура.Вставить("ОбъектМД", ОбъектМД);
	Структура.Вставить("ВозможенПоискПоПредопределенным", Ложь);
	Структура.Вставить("ПКО");
	Возврат Структура;
КонецФункции

Функция СтруктураПараметровПланаОбмена(Имя, ТипСсылки, ЭтоСсылочныйТип, ЭтоРегистр)
	Структура = Новый Структура;
	Структура.Вставить("Имя", Имя);
	Структура.Вставить("ТипСсылки", ТипСсылки);
	Структура.Вставить("ЭтоСсылочныйТип", ЭтоСсылочныйТип);
	Структура.Вставить("ЭтоРегистр", ЭтоРегистр);
	Возврат Структура;
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// Процедуры и функции из базовой функциональности для обеспечения автономности.

Функция ПодсистемаСуществует(ПолноеИмяПодсистемы) Экспорт

	ИменаПодсистем = ИменаПодсистем();
	Возврат ИменаПодсистем.Получить(ПолноеИмяПодсистемы) <> Неопределено;

КонецФункции

Функция ИменаПодсистем() Экспорт

	Возврат Новый ФиксированноеСоответствие(ИменаПодчиненныхПодсистем(Метаданные));

КонецФункции

Функция ИменаПодчиненныхПодсистем(РодительскаяПодсистема)

	Имена = Новый Соответствие;

	Для Каждого ТекущаяПодсистема Из РодительскаяПодсистема.Подсистемы Цикл

		Имена.Вставить(ТекущаяПодсистема.Имя, Истина);
		ИменаПодчиненных = ИменаПодчиненныхПодсистем(ТекущаяПодсистема);

		Для Каждого ИмяПодчиненной Из ИменаПодчиненных Цикл
			Имена.Вставить(ТекущаяПодсистема.Имя + "." + ИмяПодчиненной.Ключ, Истина);
		КонецЦикла;
	КонецЦикла;

	Возврат Имена;

КонецФункции

Функция ОбщийМодуль(Имя) Экспорт

	Если Метаданные.ОбщиеМодули.Найти(Имя) <> Неопределено Тогда
		Модуль = Вычислить(Имя);
	Иначе
		Модуль = Неопределено;
	КонецЕсли;

	Если ТипЗнч(Модуль) <> Тип("ОбщийМодуль") Тогда
		ВызватьИсключение ПодставитьПараметрыВСтроку(НСтр("ru = 'Общий модуль ""%1"" не найден.'"), Имя);
	КонецЕсли;

	Возврат Модуль;

КонецФункции

Процедура СообщитьПользователю(ТекстСообщенияПользователю) Экспорт

	Сообщение = Новый СообщениеПользователю;
	Сообщение.Текст = ТекстСообщенияПользователю;
	Сообщение.Сообщить();

КонецПроцедуры

Функция ПодставитьПараметрыВСтроку(Знач СтрокаПодстановки, Знач Параметр1, Знач Параметр2 = Неопределено,
	Знач Параметр3 = Неопределено)

	СтрокаПодстановки = СтрЗаменить(СтрокаПодстановки, "%1", Параметр1);
	СтрокаПодстановки = СтрЗаменить(СтрокаПодстановки, "%2", Параметр2);
	СтрокаПодстановки = СтрЗаменить(СтрокаПодстановки, "%3", Параметр3);

	Возврат СтрокаПодстановки;

КонецФункции

Функция ЭтоВнешняяОбработка()

	Возврат ?(СтрНайти(EventHandlerExternalDataProcessorFileName, ".") <> 0, Истина, Ложь);

КонецФункции

Функция ИмяПредопределенного(Ссылка)

	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	Запрос.Текст = "ВЫБРАТЬ
				   | ИмяПредопределенныхДанных КАК ИмяПредопределенныхДанных
				   |ИЗ
				   |	" + Ссылка.Метаданные().ПолноеИмя() + " КАК ПсевдонимЗаданнойТаблицы
															  |ГДЕ
															  |	ПсевдонимЗаданнойТаблицы.Ссылка = &Ссылка
															  |";
	Выборка = Запрос.Выполнить().Выбрать();
	Выборка.Следующий();

	Возврат Выборка.ИмяПредопределенныхДанных;

КонецФункции

Функция ЗначениеСсылочногоТипа(Значение)

	Тип = ТипЗнч(Значение);

	Возврат Тип <> Тип("Неопределено") И (Справочники.ТипВсеСсылки().СодержитТип(Тип)
		Или Документы.ТипВсеСсылки().СодержитТип(Тип) Или Перечисления.ТипВсеСсылки().СодержитТип(Тип)
		Или ПланыВидовХарактеристик.ТипВсеСсылки().СодержитТип(Тип) Или ПланыСчетов.ТипВсеСсылки().СодержитТип(Тип)
		Или ПланыВидовРасчета.ТипВсеСсылки().СодержитТип(Тип) Или БизнесПроцессы.ТипВсеСсылки().СодержитТип(Тип)
		Или БизнесПроцессы.ТипВсеСсылкиТочекМаршрутаБизнесПроцессов().СодержитТип(Тип)
		Или Задачи.ТипВсеСсылки().СодержитТип(Тип) Или ПланыОбмена.ТипВсеСсылки().СодержитТип(Тип));

КонецФункции

Функция КодОсновногоЯзыка()
	Возврат UT_CommonClientServer.DefaultLanguageCode();
//	Если ПодсистемаСуществует("СтандартныеПодсистемы.БазоваяФункциональность") Тогда
//		МодульОбщегоНазначения = ОбщийМодуль("ОбщегоНазначения");
//		Возврат МодульОбщегоНазначения.КодОсновногоЯзыка();
//	КонецЕсли;
//	Возврат Метаданные.ОсновнойЯзык.КодЯзыка;
КонецФункции

#КонецОбласти

#КонецОбласти

#Область УИ

// Для внутреннего использования
//
Функция ПолучитьТекстЗапросаПоСтроке(СтрокаДереваМетаданных, ЕстьДопОтборы, СтрокаПолейДляВыборки = "") Экспорт

	ОбъектМетаданных = Метаданные.НайтиПоПолномуИмени(СтрокаДереваМетаданных.ИмяМетаданных);

	ИмяМетаданных     = СтрокаДереваМетаданных.ИмяМетаданных;

	Если Метаданные.РегистрыСведений.Содержит(ОбъектМетаданных) Тогда

		ТекстЗапроса = ПолучитьТекстЗапросаДляРегистраСведений(ИмяМетаданных, ОбъектМетаданных, ЕстьДопОтборы,
			СтрокаПолейДляВыборки);
		Возврат ТекстЗапроса;

	ИначеЕсли Метаданные.РегистрыНакопления.Содержит(ОбъектМетаданных) Или Метаданные.РегистрыБухгалтерии.Содержит(
		ОбъектМетаданных) Тогда

		ТекстЗапроса = ПолучитьТекстЗапросаДляРегистра(ИмяМетаданных, ОбъектМетаданных, ЕстьДопОтборы,
			СтрокаПолейДляВыборки);
		Возврат ТекстЗапроса;

	КонецЕсли;

	ЕстьОграничениеПоДатам = ЗначениеЗаполнено(StartDate) Или ЗначениеЗаполнено(EndDate);

	Если Не ЗначениеЗаполнено(СтрокаПолейДляВыборки) Тогда
		СтрокаПолейДляВыборки = "_.*";
	КонецЕсли;

	ТекстЗапроса = "ВЫБРАТЬ Разрешенные " + СтрокаПолейДляВыборки + " ИЗ " + ИмяМетаданных + " КАК _ ";
	
	// возможно нужно ограничение по датам установить
	Если ЕстьОграничениеПоДатам Тогда

		Если ЕстьДопОтборы И Не UseFilterByDateForAllObjects Тогда

			Возврат ТекстЗапроса;

		КонецЕсли;

		ДопОграничениеПоДате = "";
		
		// можно ли для данного объекта МД строить ограничения по датам
		Если Метаданные.Документы.Содержит(ОбъектМетаданных) Тогда

			ДопОграничениеПоДате = ПолучитьСтрокуОграниченияПоДатеДляЗапроса(ОбъектМетаданных, "Документ");

		ИначеЕсли Метаданные.РегистрыБухгалтерии.Содержит(ОбъектМетаданных) Или Метаданные.РегистрыНакопления.Содержит(
			ОбъектМетаданных) Тогда

			ДопОграничениеПоДате = ПолучитьСтрокуОграниченияПоДатеДляЗапроса(ОбъектМетаданных, "Регистр");

		КонецЕсли;

		ТекстЗапроса = ТекстЗапроса + Символы.ПС + ДопОграничениеПоДате;

	КонецЕсли;

	Возврат ТекстЗапроса;

КонецФункции

Функция ПолучитьТекстЗапросаДляРегистраСведений(ИмяМетаданных, ОбъектМетаданных, ЕстьДопОтборы,
	СтрокаПолейДляВыборки = "")

	ЕстьОграничениеПоДатам = ЗначениеЗаполнено(StartDate) Или ЗначениеЗаполнено(EndDate);

	Если Не ЗначениеЗаполнено(СтрокаПолейДляВыборки) Тогда
		СтрокаПолейДляВыборки = "_.*";
	Иначе
		СтрокаПолейДляВыборки = " Различные " + СтрокаПолейДляВыборки;
	КонецЕсли;

	ТекстЗапроса = "ВЫБРАТЬ Разрешенные " + СтрокаПолейДляВыборки + " ИЗ " + ИмяМетаданных + " КАК _ ";

	Если ОбъектМетаданных.ПериодичностьРегистраСведений
		= Метаданные.СвойстваОбъектов.ПериодичностьРегистраСведений.Непериодический Тогда
		Возврат ТекстЗапроса;
	КонецЕсли;
	
	// 0 - отбор за период
	// 1 - срез последних на дату окончания
	// 2 - срез первых на дату начала
	// 3 - срез последних на дату начала + отбор за период
	Если ЕстьДопОтборы И Не UseFilterByDateForAllObjects Тогда

		Возврат ТекстЗапроса;

	КонецЕсли;

	ДопОграничениеПоДате = ПолучитьСтрокуОграниченияПоДатеДляЗапроса(ОбъектМетаданных, "РегистрСведений");

	ТекстЗапроса = ТекстЗапроса + Символы.ПС + ДопОграничениеПоДате;
	Возврат ТекстЗапроса;

КонецФункции

Функция ПолучитьТекстЗапросаДляРегистра(ИмяМетаданных, ОбъектМетаданных, ЕстьДопОтборы, СтрокаПолейДляВыборки = "")

	ЕстьОграничениеПоДатам = ЗначениеЗаполнено(StartDate) Или ЗначениеЗаполнено(EndDate);

	Если Не ЗначениеЗаполнено(СтрокаПолейДляВыборки) Тогда
		СтрокаПолейДляВыборки = "_.*";
	Иначе
		СтрокаПолейДляВыборки = " РАЗЛИЧНЫЕ " + СтрокаПолейДляВыборки;
	КонецЕсли;

	ТекстЗапроса = "ВЫБРАТЬ Разрешенные " + СтрокаПолейДляВыборки + " ИЗ " + ИмяМетаданных + " КАК _ ";
	
	// возможно нужно ограничение по датам установить
	Если ЕстьОграничениеПоДатам Тогда

		Если ЕстьДопОтборы И Не UseFilterByDateForAllObjects Тогда

			Возврат ТекстЗапроса;

		КонецЕсли;

		ДопОграничениеПоДате = ПолучитьСтрокуОграниченияПоДатеДляЗапроса(ОбъектМетаданных, "Регистр");

		ТекстЗапроса = ТекстЗапроса + Символы.ПС + ДопОграничениеПоДате;

	КонецЕсли;

	Возврат ТекстЗапроса;

КонецФункции
Функция СхемаКомпоновкиДанных(ТекстЗапроса) Экспорт

	СхемаКомпоновкиДанных = Новый СхемаКомпоновкиДанных;

	ИсточникДанных = СхемаКомпоновкиДанных.ИсточникиДанных.Добавить();
	ИсточникДанных.Имя = "ИсточникДанных1";
	ИсточникДанных.ТипИсточникаДанных = "local";

	НаборДанных = СхемаКомпоновкиДанных.НаборыДанных.Добавить(Тип("НаборДанныхЗапросСхемыКомпоновкиДанных"));
	НаборДанных.ИсточникДанных = "ИсточникДанных1";
	НаборДанных.АвтоЗаполнениеДоступныхПолей = Истина;
	НаборДанных.Запрос = ТекстЗапроса;
	НаборДанных.Имя = "НаборДанных1";

	Возврат СхемаКомпоновкиДанных;

КонецФункции

Процедура УстановитьНастройкуСтруктурыВыводаРезультата(Настройки, ВыводВТабличныйДокумент = Ложь) Экспорт

	ГруппировкаКомпоновкиДанных = Настройки.Структура.Добавить(Тип("ГруппировкаКомпоновкиДанных"));

	ПолеГруппировки = ГруппировкаКомпоновкиДанных.ПоляГруппировки.Элементы.Добавить(Тип(
		"ПолеГруппировкиКомпоновкиДанных"));
	ПолеГруппировки.Использование = Истина;

	Если ВыводВТабличныйДокумент И Настройки.Выбор.ДоступныеПоляВыбора.НайтиПоле(Новый ПолеКомпоновкиДанных("Ссылка"))
		<> Неопределено Тогда
		ПолеВыбора = ГруппировкаКомпоновкиДанных.Выбор.Элементы.Добавить(Тип("ВыбранноеПолеКомпоновкиДанных"));
		ПолеВыбора.Поле = Новый ПолеКомпоновкиДанных("Ссылка");
		ПолеВыбора.Использование = Истина;
	Иначе
		Для Каждого ДоступноеПолеВыбора Из Настройки.Выбор.ДоступныеПоляВыбора.Элементы Цикл
			Если ДоступноеПолеВыбора.Поле = Новый ПолеКомпоновкиДанных("СистемныеПоля") Или ДоступноеПолеВыбора.Поле
				= Новый ПолеКомпоновкиДанных("ПараметрыДанных") Тогда
				Продолжить;
			КонецЕсли;
			ПолеВыбора = ГруппировкаКомпоновкиДанных.Выбор.Элементы.Добавить(Тип("ВыбранноеПолеКомпоновкиДанных"));
			ПолеВыбора.Поле = ДоступноеПолеВыбора.Поле;
			ПолеВыбора.Использование = Истина;
		КонецЦикла;
	КонецЕсли;

КонецПроцедуры
#КонецОбласти

#Область Инициализация

ИнициализацияРеквизитовИМодульныхПеременных();
ДополнитьСлужебныеТаблицыКолонками();
ИнициализацияСтруктурыИменОбработчиков();

#КонецОбласти