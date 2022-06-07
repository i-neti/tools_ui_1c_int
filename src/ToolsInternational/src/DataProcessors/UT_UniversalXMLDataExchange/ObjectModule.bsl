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
Var IntegratedAlgorithms; // The structure containing algorithms with integrated codes of nested algorithms.

Var HandlersNames; // The structure that contains names of all exchange rule handlers.

Var ConfigurationSeparators; // Array: contains configuration separators.

////////////////////////////////////////////////////////////////////////////////
// FLAGS THAT SHOW WHETHER GLOBAL EVENT HANDLERS EXIST

Var HasBeforeExportObjectGlobalHandler;
Var HasAfterExportObjectGlobalHandler;

Var HasBeforeConvertObjectGlobalHandler;

Var HasBeforeImportObjectGlobalHandler;
Var HasAfterObjectImportGlobalHandler;

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
Var mPropertyConversionRuleTable;      // ValueTable - a template for restoring the table structure by copying.
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
Var mConversionRuleMap; // Map to define an object conversion rule by this object type.

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
	SupplementWithConversionRuleInterfaceHandler(ConversionStructure);
	
	// Adding the DER interfaces
	SupplementDataExportRulesWithHandlerInterfaces(DERTable, DERTable.Rows);
	
	// Adding DCR interfaces.
	SupplementWithDataClearingRuleHandlerInterfaces(DCRTable, DCRTable.Rows);
	
	// Adding OCR, PCR, PGCR interfaces.
	SupplementWithObjectConversionRuleHandlerInterfaces(OCRTable);
	
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

	IsRuleWithGlobalObjectExport = ExecuteDataExchangeInOptimizedFormat AND OCR.UseQuickSearchOnImport;

	RememberExported       = OCR.RememberExported;
	ExportedObjects          = OCR.Exported;
	ExportedObjectsOnlyRefs = OCR.OnlyRefsExported;
	AllObjectsExported         = OCR.AllObjectsExported;
	DontReplaceObjectOnImport = OCR.DoNotReplace;
	DontCreateIfNotFound     = OCR.DoNotCreateIfNotFound;
	OnExchangeObjectByRefSetGIUDOnly     = OCR.OnMoveObjectByRefSetGIUDOnly;

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
			
			If DontCreateIfNotFound Then
				SetAttribute(RefNode, "DoNotCreateIfNotFound", DontCreateIfNotFound);
			EndIf;
			
			If OnExchangeObjectByRefSetGIUDOnly Then
				SetAttribute(RefNode, "OnMoveObjectByRefSetGIUDOnly", OnExchangeObjectByRefSetGIUDOnly);
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

	AddMissingColumns(Columns, "IsFolder", 			deTypeDescription("Boolean"));
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

	Отступ = "";
	Для Сч = 0 По Уровень - 1 Цикл
		Отступ = Отступ + Символы.Таб;
	КонецЦикла;

	Если ТипЗнч(Код) = одТипЧисло Тогда

		Если одСообщения = Неопределено Тогда
			ИнициализацияСообщений();
		КонецЕсли;

		Стр = одСообщения[Код];

	Иначе

		Стр = Строка(Код);

	КонецЕсли;

	Стр = Отступ + Стр;

	Если СтруктураЗаписи <> Неопределено Тогда

		Для Каждого Поле Из СтруктураЗаписи Цикл

			Значение = Поле.Значение;
			Если Значение = Неопределено Тогда
				Продолжить;
			КонецЕсли;
			Ключ = Поле.Ключ;
			Стр  = Стр + Символы.ПС + Отступ + Символы.Таб + одДополнитьСтроку(Ключ, Выравнивание) + " =  " + Строка(
				Значение);

		КонецЦикла;

	КонецЕсли;

	ИтоговаяСтрокаДляЗаписи = Символы.ПС + Стр;
	Если ВзвестиФлагОшибок Тогда

		УстановитьФлагОшибки(Истина);
		СообщитьПользователю(ИтоговаяСтрокаДляЗаписи);

	Иначе

		Если DontShowInfoMessagesToUser = Ложь И (БезусловнаяЗаписьВПротоколОбмена
			Или DisplayInfoMessagesIntoMessageWindow) Тогда

			СообщитьПользователю(ИтоговаяСтрокаДляЗаписи);

		КонецЕсли;

	КонецЕсли;

	Если мФайлПротоколаДанных <> Неопределено Тогда

		Если ВзвестиФлагОшибок Тогда

			мФайлПротоколаДанных.ЗаписатьСтроку(Символы.ПС + "Ошибка.");

		КонецЕсли;

		Если ВзвестиФлагОшибок Или БезусловнаяЗаписьВПротоколОбмена Или WriteInfoMessagesToLog Тогда

			мФайлПротоколаДанных.ЗаписатьСтроку(ИтоговаяСтрокаДляЗаписи);

		КонецЕсли;

	КонецЕсли;

	Возврат Стр;

КонецФункции

// Записывает информацию об ошибке в протокол выполнения обмена для обработчика очистки данных.
//
Процедура ЗаписатьИнформациюОбОшибкеОбработчикаОчисткиДанных(КодСообщения, СтрокаОшибки, ИмяПравилаОчисткиДанных,
	Объект = "", ИмяОбработчика = "")

	ЗП                        = ПолучитьСтруктуруЗаписиПротокола(КодСообщения, СтрокаОшибки);
	ЗП.ПОД                    = ИмяПравилаОчисткиДанных;

	Если Объект <> "" Тогда
		ОписаниеТипов = Новый ОписаниеТипов("Строка");
		ОбъектСтрока  = ОписаниеТипов.ПривестиЗначение(Объект);
		Если Не ПустаяСтрока(ОбъектСтрока) Тогда
			ЗП.Объект = ОбъектСтрока + "  (" + ТипЗнч(Объект) + ")";
		Иначе
			ЗП.Объект = "" + ТипЗнч(Объект) + "";
		КонецЕсли;
	КонецЕсли;

	Если ИмяОбработчика <> "" Тогда
		ЗП.Обработчик             = ИмяОбработчика;
	КонецЕсли;

	СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(КодСообщения, ЗП);

	Если Не DebugModeFlag Тогда
		ВызватьИсключение СтрокаСообщенияОбОшибке;
	КонецЕсли;

КонецПроцедуры

// Регистрирует в протоколе выполнения ошибку обработчика ПКО (выгрузка).
//
Процедура ЗаписатьИнформациюОбОшибкеВыгрузкиОбработчикаПКО(КодСообщения, СтрокаОшибки, ПКО, Источник, ИмяОбработчика)

	ЗП                        = ПолучитьСтруктуруЗаписиПротокола(КодСообщения, СтрокаОшибки);
	ЗП.ПКО                    = ПКО.Имя + "  (" + ПКО.Наименование + ")";

	ОписаниеТипов = Новый ОписаниеТипов("Строка");
	ИсточникСтрока  = ОписаниеТипов.ПривестиЗначение(Источник);
	Если Не ПустаяСтрока(ИсточникСтрока) Тогда
		ЗП.Объект = ИсточникСтрока + "  (" + ТипЗнч(Источник) + ")";
	Иначе
		ЗП.Объект = "(" + ТипЗнч(Источник) + ")";
	КонецЕсли;

	ЗП.Обработчик = ИмяОбработчика;

	СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(КодСообщения, ЗП);

	Если Не DebugModeFlag Тогда
		ВызватьИсключение СтрокаСообщенияОбОшибке;
	КонецЕсли;

КонецПроцедуры

Процедура ЗаписатьИнформациюОбОшибкеОбработчикиПВД(КодСообщения, СтрокаОшибки, ИмяПравила, ИмяОбработчика,
	Объект = Неопределено)

	ЗП                        = ПолучитьСтруктуруЗаписиПротокола(КодСообщения, СтрокаОшибки);
	ЗП.ПВД                    = ИмяПравила;

	Если Объект <> Неопределено Тогда
		ОписаниеТипов = Новый ОписаниеТипов("Строка");
		ОбъектСтрока  = ОписаниеТипов.ПривестиЗначение(Объект);
		Если Не ПустаяСтрока(ОбъектСтрока) Тогда
			ЗП.Объект = ОбъектСтрока + "  (" + ТипЗнч(Объект) + ")";
		Иначе
			ЗП.Объект = "" + ТипЗнч(Объект) + "";
		КонецЕсли;
	КонецЕсли;

	ЗП.Обработчик             = ИмяОбработчика;

	СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(КодСообщения, ЗП);

	Если Не DebugModeFlag Тогда
		ВызватьИсключение СтрокаСообщенияОбОшибке;
	КонецЕсли;

КонецПроцедуры

Функция ЗаписатьИнформациюОбОшибкеОбработчикиКонвертации(КодСообщения, СтрокаОшибки, ИмяОбработчика)

	ЗП                        = ПолучитьСтруктуруЗаписиПротокола(КодСообщения, СтрокаОшибки);
	ЗП.Обработчик             = ИмяОбработчика;
	СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(КодСообщения, ЗП);
	Возврат СтрокаСообщенияОбОшибке;

КонецФункции

#КонецОбласти

#Область ОписаниеТиповКоллекций

// Возвращаемое значение:
//   ТаблицаЗначений - коллекция правил конвертации данных:
//     * Имя - Строка - 
//     * Наименование - Строка - 
//     * Порядок - Число - 
//     * СинхронизироватьПоИдентификатору - Булево -
//     * НеСоздаватьЕслиНеНайден - Булево -
//     * НеВыгружатьОбъектыСвойствПоСсылкам - Булево -
//     * ПродолжитьПоискПоПолямПоискаЕслиПоИдентификаторуНеНашли - Булево -
//     * ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD - Булево -
//     * ИспользоватьБыстрыйПоискПриЗагрузке - Булево -
//     * ГенерироватьНовыйНомерИлиКодЕслиНеУказан - Булево -
//     * МаленькоеКоличествоОбъектов - Булево -
//     * КоличествоОбращенийДляВыгрузкиСсылки - Число -
//     * КоличествоЭлементовВИБ - Число -
//     * СпособВыгрузки - Произвольный -
//     * Источник - Произвольный -
//     * Приемник - Произвольный -
//     * ТипИсточника - Строка -
//     * ПередВыгрузкой - Произвольный -
//     * ПриВыгрузке - Произвольный -
//     * ПослеВыгрузки - Произвольный -
//     * ПослеВыгрузкиВФайл - Произвольный -
//     * ЕстьОбработчикПередВыгрузкой - Булево -
//     * ЕстьОбработчикПриВыгрузке - Булево -
//     * ЕстьОбработчикПослеВыгрузки - Булево -
//     * ЕстьОбработчикПослеВыгрузкиВФайл - Булево -
//     * ПередЗагрузкой - Произвольный -
//     * ПриЗагрузке - Произвольный -
//     * ПослеЗагрузки - Произвольный -
//     * ПоследовательностьПолейПоиска - Произвольный -
//     * ПоискПоТабличнымЧастям - см. КоллекцияПоискПоТабличнымЧастям
//     * ЕстьОбработчикПередЗагрузкой - Булево -
//     * ЕстьОбработчикПриЗагрузке - Булево -
//     * ЕстьОбработчикПослеЗагрузки - Булево -
//     * ЕстьОбработчикПоследовательностьПолейПоиска - Булево -
//     * СвойстваПоиска - см. КоллекцияПравилаКонвертацииСвойств
//     * Свойства - см. КоллекцияПравилаКонвертацииСвойств
//     * Выгруженные - ТаблицаЗначений -
//     * ВыгружатьПредставлениеИсточника - Булево -
//     * НеЗамещать - Булево -
//     * ЗапоминатьВыгруженные - Булево -
//     * ВсеОбъектыВыгружены - Булево -
// 
Функция КоллекцияПравилаКонвертации()

	Возврат ConversionRulesTable;

КонецФункции

// Возвращаемое значение:
//   ДеревоЗначений - коллекция правил выгрузки данных:
//     * Включить - Число -
//     * ЭтоГруппа - Булево -
//     * Имя - Строка -
//     * Наименование - Строка -
//     * Порядок - Число -
//     * СпособОтбораДанных - Произвольный -
//     * ОбъектВыборки - Произвольный -
//     * ПравилоКонвертации - Произвольный -
//     * ПередОбработкой - Строка -
//     * ПослеОбработки - Строка -
//     * ПередВыгрузкой - Строка -
//     * ПослеВыгрузки - Строка -
//     * ИспользоватьОтбор - Булево -
//     * НастройкиПостроителя - Произвольный -
//     * ИмяОбъектаДляЗапроса - Строка -
//     * ИмяОбъектаДляЗапросаРегистра - Строка -
//     * ВыбиратьДанныеДляВыгрузкиОднимЗапросом - Булево -
//     * СсылкаНаУзелОбмена - ПланОбменаСсылка -
//
Функция КоллекцияПравилаВыгрузки()

	Возврат ExportRulesTable;

КонецФункции

// Возвращаемое значение:
//   ТаблицаЗначений - коллекция правил поиска по табличным частям:
//     * ИмяЭлемента - Произвольный -
//     * ПоляПоискаТЧ - Массив из Произвольный -
// 
Функция КоллекцияПоискПоТабличнымЧастям()

	ПоискПоТабличнымЧастям = Новый ТаблицаЗначений;
	ПоискПоТабличнымЧастям.Колонки.Добавить("ИмяЭлемента");
	ПоискПоТабличнымЧастям.Колонки.Добавить("ПоляПоискаТЧ");

	Возврат ПоискПоТабличнымЧастям;

КонецФункции

// Возвращаемое значение:
//   ТаблицаЗначений - коллекция правил конвертации свойств данных:
//     * Имя - Строка -
//     * Наименование - Строка - 
//     * Порядок - Число -
//     * ЭтоГруппа - Булево -
//     * ЭтоПолеПоиска - Булево -
//     * ПравилаГруппы - см. КоллекцияПравилаКонвертацииСвойств
//     * ПравилаГруппыОтключенные - Произвольный -
//     * ВидИсточника - Произвольный -
//     * ВидПриемника - Произвольный -
//     * УпрощеннаяВыгрузкаСвойства - Булево -
//     * НуженУзелXMLПриВыгрузке - Булево -
//     * НуженУзелXMLПриВыгрузкеГруппы - Булево -
//     * ТипИсточника - Строка -
//     * ТипПриемника - Строка -
//     * Источник - Произвольный -
//     * Приемник - Произвольный -
//     * ПравилоКонвертации - Произвольный -
//     * ПолучитьИзВходящихДанных - Булево -
//     * НеЗамещать - Булево -
//     * ЭтоОбязательноеСвойство - Булево -
//     * ПередВыгрузкой - Произвольный -
//     * ИмяОбработчикаПередВыгрузкой - Произвольный -
//     * ПриВыгрузке - Произвольный -
//     * ИмяОбработчикаПриВыгрузке - Произвольный -
//     * ПослеВыгрузки - Произвольный -
//     * ИмяОбработчикаПослеВыгрузки - Произвольный -
//     * ПередОбработкойВыгрузки - Произвольный -
//     * ИмяОбработчикаПередОбработкойВыгрузки - Произвольный -
//     * ПослеОбработкиВыгрузки - Произвольный -
//     * ИмяОбработчикаПослеОбработкиВыгрузки - Произвольный -
//     * ЕстьОбработчикПередВыгрузкой - Булево -
//     * ЕстьОбработчикПриВыгрузке - Булево -
//     * ЕстьОбработчикПослеВыгрузки - Булево -
//     * ЕстьОбработчикПередОбработкойВыгрузки - Булево -
//     * ЕстьОбработчикПослеОбработкиВыгрузки - Булево -
//     * ПриводитьКДлине - Число -
//     * ИмяПараметраДляПередачи - Строка -
//     * ПоискПоДатеНаРавенство - Булево -
//     * ВыгружатьГруппуЧерезФайл - Булево -
//     * СтрокаПолейПоиска - Произвольный -
// 
Функция КоллекцияПравилаКонвертацииСвойств()

	Возврат mPropertyConversionRulesTable;

КонецФункции

// Возвращаемое значение:
//   ТаблицаЗначений - стек выгрузки:
//     * Ссылка - ЛюбаяСсылка - ссылка на выгружаемый объект.
//
Функция DataExportCallStackCollection()

	Возврат мСтекВызововВыгрузкиДанных;

КонецФункции

// Возвращаемое значение:
//   Структура - структура правил:
//     * ExportRulesTable - см. КоллекцияПравилаВыгрузки
//     * ConversionRulesTable - см. КоллекцияПравилаКонвертации
//     * Алгоритмы - Структура -
//     * Запросы - Структура -
//     * Конвертация - Произвольный -
//     * mXMLRules - Произвольный -
//     * ParametersSettingsTable - ТаблицаЗначений -
//     * Parameters - Структура -
//     * ВерсияПлатформыПриемника - Строка -
//
Функция RulesStructureDetails()

	СтруктураПравил = Новый Структура;

	СтруктураПравил.Вставить("ExportRulesTable");
	СтруктураПравил.Вставить("ConversionRulesTable");
	СтруктураПравил.Вставить("Алгоритмы");
	СтруктураПравил.Вставить("Запросы");
	СтруктураПравил.Вставить("Конвертация");
	СтруктураПравил.Вставить("mXMLRules");
	СтруктураПравил.Вставить("ParametersSettingsTable");
	СтруктураПравил.Вставить("Parameters");

	СтруктураПравил.Вставить("ВерсияПлатформыПриемника");

	Возврат СтруктураПравил;

КонецФункции

#КонецОбласти

#Область ПроцедурыЗагрузкиПравилОбмена

// Осуществляет загрузку правила конвертации группы свойств.
//
// Parameters:
//   ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//   ТаблицаСвойств - см. КоллекцияПравилаКонвертацииСвойств
//
Процедура ЗагрузитьПКГС(ПравилаОбмена, ТаблицаСвойств)

	Если одАтрибут(ПравилаОбмена, одТипБулево, "Отключить") Тогда
		одПропустить(ПравилаОбмена);
		Возврат;
	КонецЕсли;

	НоваяСтрока               = ТаблицаСвойств.Добавить();
	НоваяСтрока.ЭтоГруппа     = Истина;
	НоваяСтрока.ПравилаГруппы = КоллекцияПравилаКонвертацииСвойств().Скопировать();
	
	// Значения по умолчанию

	НоваяСтрока.НеЗамещать               = Ложь;
	НоваяСтрока.ПолучитьИзВходящихДанных = Ложь;
	НоваяСтрока.УпрощеннаяВыгрузкаСвойства = Ложь;

	СтрокаПолейПоиска = "";

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Источник" Тогда
			НоваяСтрока.Источник		= одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");
			НоваяСтрока.ВидИсточника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Вид");
			НоваяСтрока.ТипИсточника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Тип");
			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "Приемник" Тогда
			НоваяСтрока.Приемник		= одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");
			НоваяСтрока.ВидПриемника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Вид");
			НоваяСтрока.ТипПриемника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Тип");
			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "Свойство" Тогда
			ЗагрузитьПКС(ПравилаОбмена, НоваяСтрока.ПравилаГруппы, , СтрокаПолейПоиска);

		ИначеЕсли ИмяУзла = "ПередОбработкойВыгрузки" Тогда
			НоваяСтрока.ПередОбработкойВыгрузки	= ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПередОбработкойВыгрузки = Не ПустаяСтрока(НоваяСтрока.ПередОбработкойВыгрузки);

		ИначеЕсли ИмяУзла = "ПослеОбработкиВыгрузки" Тогда
			НоваяСтрока.ПослеОбработкиВыгрузки	= ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПослеОбработкиВыгрузки = Не ПустаяСтрока(НоваяСтрока.ПослеОбработкиВыгрузки);

		ИначеЕсли ИмяУзла = "Код" Тогда
			НоваяСтрока.Имя = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Наименование" Тогда
			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Порядок" Тогда
			НоваяСтрока.Порядок = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "НеЗамещать" Тогда
			НоваяСтрока.НеЗамещать = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "КодПравилаКонвертации" Тогда
			НоваяСтрока.ПравилоКонвертации = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "ПередВыгрузкой" Тогда
			НоваяСтрока.ПередВыгрузкой = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПередВыгрузкой = Не ПустаяСтрока(НоваяСтрока.ПередВыгрузкой);

		ИначеЕсли ИмяУзла = "ПриВыгрузке" Тогда
			НоваяСтрока.ПриВыгрузке = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПриВыгрузке    = Не ПустаяСтрока(НоваяСтрока.ПриВыгрузке);

		ИначеЕсли ИмяУзла = "ПослеВыгрузки" Тогда
			НоваяСтрока.ПослеВыгрузки = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПослеВыгрузки  = Не ПустаяСтрока(НоваяСтрока.ПослеВыгрузки);

		ИначеЕсли ИмяУзла = "ВыгружатьГруппуЧерезФайл" Тогда
			НоваяСтрока.ВыгружатьГруппуЧерезФайл = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "ПолучитьИзВходящихДанных" Тогда
			НоваяСтрока.ПолучитьИзВходящихДанных = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли (ИмяУзла = "Группа") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	НоваяСтрока.СтрокаПолейПоиска = СтрокаПолейПоиска;

	НоваяСтрока.НуженУзелXMLПриВыгрузке = НоваяСтрока.ЕстьОбработчикПриВыгрузке
		Или НоваяСтрока.ЕстьОбработчикПослеВыгрузки;

	НоваяСтрока.НуженУзелXMLПриВыгрузкеГруппы = НоваяСтрока.ЕстьОбработчикПослеОбработкиВыгрузки;

КонецПроцедуры

Процедура ДобавитьПолеКСтрокеПоиска(СтрокаПолейПоиска, ИмяПоля)

	Если ПустаяСтрока(ИмяПоля) Тогда
		Возврат;
	КонецЕсли;

	Если Не ПустаяСтрока(СтрокаПолейПоиска) Тогда
		СтрокаПолейПоиска = СтрокаПолейПоиска + ",";
	КонецЕсли;

	СтрокаПолейПоиска = СтрокаПолейПоиска + ИмяПоля;

КонецПроцедуры

// Осуществляет загрузку правила конвертации свойств.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - объект, содержащий текст правил обмена.
//  ТаблицаСвойств - см. КоллекцияПравилаКонвертацииСвойств
//  ТаблицаПоиска - см. КоллекцияПравилаКонвертацииСвойств
//
Процедура ЗагрузитьПКС(ПравилаОбмена, ТаблицаСвойств, ТаблицаПоиска = Неопределено, СтрокаПолейПоиска = "")

	Если одАтрибут(ПравилаОбмена, одТипБулево, "Отключить") Тогда
		одПропустить(ПравилаОбмена);
		Возврат;
	КонецЕсли;
	ЭтоПолеПоиска = одАтрибут(ПравилаОбмена, одТипБулево, "Поиск");

	Если ЭтоПолеПоиска И ТаблицаПоиска <> Неопределено Тогда

		НоваяСтрока = ТаблицаПоиска.Добавить();

	Иначе

		НоваяСтрока = ТаблицаСвойств.Добавить();

	КонецЕсли;  

	
	// Значения по умолчанию

	НоваяСтрока.НеЗамещать               = Ложь;
	НоваяСтрока.ПолучитьИзВходящихДанных = Ложь;
	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Источник" Тогда
			НоваяСтрока.Источник		= одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");
			НоваяСтрока.ВидИсточника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Вид");
			НоваяСтрока.ТипИсточника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Тип");
			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "Приемник" Тогда
			НоваяСтрока.Приемник		= одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");
			НоваяСтрока.ВидПриемника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Вид");
			НоваяСтрока.ТипПриемника	= одАтрибут(ПравилаОбмена, одТипСтрока, "Тип");

			Если ЭтоПолеПоиска Тогда
				ДобавитьПолеКСтрокеПоиска(СтрокаПолейПоиска, НоваяСтрока.Приемник);
			КонецЕсли;

			одПропустить(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "Код" Тогда
			НоваяСтрока.Имя = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Наименование" Тогда
			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Порядок" Тогда
			НоваяСтрока.Порядок = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "НеЗамещать" Тогда
			НоваяСтрока.НеЗамещать = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "КодПравилаКонвертации" Тогда
			НоваяСтрока.ПравилоКонвертации = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "ПередВыгрузкой" Тогда
			НоваяСтрока.ПередВыгрузкой = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПередВыгрузкой = Не ПустаяСтрока(НоваяСтрока.ПередВыгрузкой);

		ИначеЕсли ИмяУзла = "ПриВыгрузке" Тогда
			НоваяСтрока.ПриВыгрузке = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПриВыгрузке    = Не ПустаяСтрока(НоваяСтрока.ПриВыгрузке);

		ИначеЕсли ИмяУзла = "ПослеВыгрузки" Тогда
			НоваяСтрока.ПослеВыгрузки = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПослеВыгрузки  = Не ПустаяСтрока(НоваяСтрока.ПослеВыгрузки);

		ИначеЕсли ИмяУзла = "ПолучитьИзВходящихДанных" Тогда
			НоваяСтрока.ПолучитьИзВходящихДанных = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "ПриводитьКДлине" Тогда
			НоваяСтрока.ПриводитьКДлине = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "ИмяПараметраДляПередачи" Тогда
			НоваяСтрока.ИмяПараметраДляПередачи = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "ПоискПоДатеНаРавенство" Тогда
			НоваяСтрока.ПоискПоДатеНаРавенство = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли (ИмяУзла = "Свойство") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	НоваяСтрока.УпрощеннаяВыгрузкаСвойства = Не НоваяСтрока.ПолучитьИзВходящихДанных И Не НоваяСтрока.ЕстьОбработчикПередВыгрузкой
		И Не НоваяСтрока.ЕстьОбработчикПриВыгрузке И Не НоваяСтрока.ЕстьОбработчикПослеВыгрузки И ПустаяСтрока(
		НоваяСтрока.ПравилоКонвертации) И НоваяСтрока.ТипИсточника = НоваяСтрока.ТипПриемника
		И (НоваяСтрока.ТипИсточника = "Строка" Или НоваяСтрока.ТипИсточника = "Число" Или НоваяСтрока.ТипИсточника
		= "Булево" Или НоваяСтрока.ТипИсточника = "Дата");

	НоваяСтрока.НуженУзелXMLПриВыгрузке = НоваяСтрока.ЕстьОбработчикПриВыгрузке
		Или НоваяСтрока.ЕстьОбработчикПослеВыгрузки;

КонецПроцедуры

// Осуществляет загрузку правил конвертации свойств.
//
// Параметры:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ТаблицаСвойств - ТаблицаЗначений - таблица значений, содержащая ПКС.
//  ТаблицаПоиска  - ТаблицаЗначений - таблица значений, содержащая ПКС (синхронизирующих).
//
Процедура ЗагрузитьСвойства(ПравилаОбмена, ТаблицаСвойств, ТаблицаПоиска)

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Свойство" Тогда
			ЗагрузитьПКС(ПравилаОбмена, ТаблицаСвойств, ТаблицаПоиска);
		ИначеЕсли ИмяУзла = "Группа" Тогда
			ЗагрузитьПКГС(ПравилаОбмена, ТаблицаСвойств);
		ИначеЕсли (ИмяУзла = "Свойства") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	ТаблицаСвойств.Сортировать("Порядок");
	ТаблицаПоиска.Сортировать("Порядок");

КонецПроцедуры

// Осуществляет загрузку правила конвертации значений.
//
// Параметры:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  Значения       - соответствие значений объекта источника - строковым
//                   представлениям объекта приемника.
//  ТипИсточника   - значение Тип - типа Тип - тип объекта источника.
//
Процедура ЗагрузитьПКЗ(ПравилаОбмена, Значения, ТипИсточника)

	Источник = "";
	Приемник = "";
	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Источник" Тогда
			Источник = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
		ИначеЕсли ИмяУзла = "Приемник" Тогда
			Приемник = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
		ИначеЕсли (ИмяУзла = "Значение") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Если ExchangeMode <> "Загрузка" Тогда
		Значения[одПолучитьЗначениеПоСтроке(Источник, ТипИсточника)] = Приемник;
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку правил конвертации значений.
//
// Параметры:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  Значения       - соответствие значений объекта источника - строковым
//                   представлениям объекта приемника.
//  ТипИсточника   - значение Тип - типа Тип - тип объекта источника.
//
Процедура ЗагрузитьЗначения(ПравилаОбмена, Значения, ТипИсточника)
	;

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Значение" Тогда
			ЗагрузитьПКЗ(ПравилаОбмена, Значения, ТипИсточника);
		ИначеЕсли (ИмяУзла = "Значения") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

// Процедура очистки ПКо у менеджеров для правил обмена.
Процедура ОчиститьПКОМенеджеров()

	Если Менеджеры = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Для Каждого МенеджерПравила Из Менеджеры Цикл
		МенеджерПравила.Значение.ПКО = Неопределено;
	КонецЦикла;

КонецПроцедуры

// Осуществляет загрузку правила конвертации объектов.
//
// Параметры:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьПравилоКонвертации(ПравилаОбмена, ЗаписьXML)

	ЗаписьXML.ЗаписатьНачалоЭлемента("Правило");

	НоваяСтрока = КоллекцияПравилаКонвертации().Добавить();
	
	// Значения по умолчанию

	НоваяСтрока.ЗапоминатьВыгруженные = Истина;
	НоваяСтрока.НеЗамещать            = Ложь;

	ТаблицаПоискПоТЧ = КоллекцияПоискПоТабличнымЧастям();
	НоваяСтрока.ПоискПоТабличнымЧастям = ТаблицаПоискПоТЧ;

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Код" Тогда

			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
			НоваяСтрока.Имя = Значение;

		ИначеЕсли ИмяУзла = "Наименование" Тогда

			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "СинхронизироватьПоИдентификатору" Тогда

			НоваяСтрока.СинхронизироватьПоИдентификатору = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, НоваяСтрока.СинхронизироватьПоИдентификатору);

		ИначеЕсли ИмяУзла = "НеСоздаватьЕслиНеНайден" Тогда

			НоваяСтрока.НеСоздаватьЕслиНеНайден = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "НеВыгружатьОбъектыСвойствПоСсылкам" Тогда

			НоваяСтрока.НеВыгружатьОбъектыСвойствПоСсылкам = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "ПродолжитьПоискПоПолямПоискаЕслиПоИдентификаторуНеНашли" Тогда

			НоваяСтрока.ПродолжитьПоискПоПолямПоискаЕслиПоИдентификаторуНеНашли = одЗначениеЭлемента(ПравилаОбмена,
				одТипБулево);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, НоваяСтрока.ПродолжитьПоискПоПолямПоискаЕслиПоИдентификаторуНеНашли);

		ИначеЕсли ИмяУзла = "ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD" Тогда

			НоваяСтрока.ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD = одЗначениеЭлемента(ПравилаОбмена,
				одТипБулево);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, НоваяСтрока.ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD);

		ИначеЕсли ИмяУзла = "НеЗамещатьОбъектСозданныйВИнформационнойБазеПриемнике" Тогда
			// не влияет на обмен
			одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "ИспользоватьБыстрыйПоискПриЗагрузке" Тогда

			НоваяСтрока.ИспользоватьБыстрыйПоискПриЗагрузке = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "ГенерироватьНовыйНомерИлиКодЕслиНеУказан" Тогда

			НоваяСтрока.ГенерироватьНовыйНомерИлиКодЕслиНеУказан = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, НоваяСтрока.ГенерироватьНовыйНомерИлиКодЕслиНеУказан);

		ИначеЕсли ИмяУзла = "НеЗапоминатьВыгруженные" Тогда

			НоваяСтрока.ЗапоминатьВыгруженные = Не одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "НеЗамещать" Тогда

			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
			НоваяСтрока.НеЗамещать = Значение;

		ИначеЕсли ИмяУзла = "ПриоритетОбъектовОбмена" Тогда
			
			// В универсальном обмене не участвует.
			одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Приемник" Тогда

			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);
			НоваяСтрока.Приемник = Значение;

		ИначеЕсли ИмяУзла = "Источник" Тогда

			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			Если ExchangeMode = "Загрузка" Тогда

				НоваяСтрока.Источник = Значение;

			Иначе

				Если Не ПустаяСтрока(Значение) Тогда

					НоваяСтрока.ТипИсточника = Значение;
					НоваяСтрока.Источник     = Тип(Значение);

					Попытка

						Менеджеры[НоваяСтрока.Источник].ПКО = НоваяСтрока;

					Исключение

						ЗаписатьИнформациюОбОшибкеВПротокол(11, ОписаниеОшибки(), Строка(НоваяСтрока.Источник));

					КонецПопытки;

				КонецЕсли;

			КонецЕсли;
			
		// Свойства

		ИначеЕсли ИмяУзла = "Свойства" Тогда

			НоваяСтрока.СвойстваПоиска	= mPropertyConversionRulesTable.Скопировать();
			НоваяСтрока.Свойства		= mPropertyConversionRulesTable.Скопировать();
			Если НоваяСтрока.СинхронизироватьПоИдентификатору <> Неопределено
				И НоваяСтрока.СинхронизироватьПоИдентификатору Тогда

				СвойствоПоискаУИ = НоваяСтрока.СвойстваПоиска.Добавить();
				СвойствоПоискаУИ.Имя = "{УникальныйИдентификатор}";
				СвойствоПоискаУИ.Источник = "{УникальныйИдентификатор}";
				СвойствоПоискаУИ.Приемник = "{УникальныйИдентификатор}";

			КонецЕсли;

			ЗагрузитьСвойства(ПравилаОбмена, НоваяСтрока.Свойства, НоваяСтрока.СвойстваПоиска);

			
		// Значения

		ИначеЕсли ИмяУзла = "Значения" Тогда

			ЗагрузитьЗначения(ПравилаОбмена, НоваяСтрока.Значения, НоваяСтрока.Источник);
		
		// Обработчики событий

		ИначеЕсли ИмяУзла = "ПередВыгрузкой" Тогда

			НоваяСтрока.ПередВыгрузкой = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПередВыгрузкой = Не ПустаяСтрока(НоваяСтрока.ПередВыгрузкой);

		ИначеЕсли ИмяУзла = "ПриВыгрузке" Тогда

			НоваяСтрока.ПриВыгрузке = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПриВыгрузке    = Не ПустаяСтрока(НоваяСтрока.ПриВыгрузке);

		ИначеЕсли ИмяУзла = "ПослеВыгрузки" Тогда

			НоваяСтрока.ПослеВыгрузки = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПослеВыгрузки  = Не ПустаяСтрока(НоваяСтрока.ПослеВыгрузки);

		ИначеЕсли ИмяУзла = "ПослеВыгрузкиВФайл" Тогда

			НоваяСтрока.ПослеВыгрузкиВФайл = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			НоваяСтрока.ЕстьОбработчикПослеВыгрузкиВФайл  = Не ПустаяСтрока(НоваяСтрока.ПослеВыгрузкиВФайл);
			
		// Для загрузки

		ИначеЕсли ИмяУзла = "ПередЗагрузкой" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
			Если ExchangeMode = "Загрузка" Тогда

				НоваяСтрока.ПередЗагрузкой               = Значение;
				НоваяСтрока.ЕстьОбработчикПередЗагрузкой = Не ПустаяСтрока(Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПриЗагрузке" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				НоваяСтрока.ПриЗагрузке               = Значение;
				НоваяСтрока.ЕстьОбработчикПриЗагрузке = Не ПустаяСтрока(Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПослеЗагрузки" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			Если ExchangeMode = "Загрузка" Тогда

				НоваяСтрока.ПослеЗагрузки               = Значение;
				НоваяСтрока.ЕстьОбработчикПослеЗагрузки = Не ПустаяСтрока(Значение);

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПоследовательностьПолейПоиска" Тогда

			Значение = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

			НоваяСтрока.ЕстьОбработчикПоследовательностьПолейПоиска = Не ПустаяСтрока(Значение);

			Если ExchangeMode = "Загрузка" Тогда

				НоваяСтрока.ПоследовательностьПолейПоиска = Значение;

			Иначе

				одЗаписатьЭлемент(ЗаписьXML, ИмяУзла, Значение);

			КонецЕсли;

		ИначеЕсли ИмяУзла = "ПоискПоТабличнымЧастям" Тогда

			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

			Для Номер = 1 По СтрЧислоСтрок(Значение) Цикл

				ТекущаяСтрока = СтрПолучитьСтроку(Значение, Номер);

				СтрокаПоиска = ОтделитьРазделителем(ТекущаяСтрока, ":");

				СтрокаТаблицы = ТаблицаПоискПоТЧ.Добавить();
				СтрокаТаблицы.ИмяЭлемента = ТекущаяСтрока;

				СтрокаТаблицы.ПоляПоискаТЧ = РазложитьСтрокуВМассивПодстрок(СтрокаПоиска);

			КонецЦикла;

		ИначеЕсли (ИмяУзла = "Правило") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		КонецЕсли;

	КонецЦикла;

	ИтоговаяСтрокаПоискаПоТЧ = "";
	
	// В приемник нужно передать информацию о полях поиска для табличных частей.
	Для Каждого СтрокаСвойств Из НоваяСтрока.Свойства Цикл

		Если Не СтрокаСвойств.ЭтоГруппа Или ПустаяСтрока(СтрокаСвойств.ВидИсточника) Или ПустаяСтрока(
			СтрокаСвойств.Приемник) Тогда

			Продолжить;

		КонецЕсли;

		Если ПустаяСтрока(СтрокаСвойств.СтрокаПолейПоиска) Тогда
			Продолжить;
		КонецЕсли;

		ИтоговаяСтрокаПоискаПоТЧ = ИтоговаяСтрокаПоискаПоТЧ + Символы.ПС + СтрокаСвойств.ВидИсточника + "."
			+ СтрокаСвойств.Приемник + ":" + СтрокаСвойств.СтрокаПолейПоиска;

	КонецЦикла;

	ИтоговаяСтрокаПоискаПоТЧ = СокрЛП(ИтоговаяСтрокаПоискаПоТЧ);

	Если Не ПустаяСтрока(ИтоговаяСтрокаПоискаПоТЧ) Тогда

		одЗаписатьЭлемент(ЗаписьXML, "ПоискПоТабличнымЧастям", ИтоговаяСтрокаПоискаПоТЧ);

	КонецЕсли;

	ЗаписьXML.ЗаписатьКонецЭлемента();

	
	// Быстрый доступ к ПКО по имени.

	Правила.Вставить(НоваяСтрока.Имя, НоваяСтрока);

КонецПроцедуры
 
// Осуществляет загрузку правил конвертации объектов.
//
// Параметры:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьПравилаКонвертации(ПравилаОбмена, ЗаписьXML)

	ConversionRulesTable.Очистить();
	ОчиститьПКОМенеджеров();

	ЗаписьXML.ЗаписатьНачалоЭлемента("ПравилаКонвертацииОбъектов");

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Правило" Тогда

			ЗагрузитьПравилоКонвертации(ПравилаОбмена, ЗаписьXML);

		ИначеЕсли (ИмяУзла = "ПравилаКонвертацииОбъектов") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		КонецЕсли;

	КонецЦикла;

	ЗаписьXML.ЗаписатьКонецЭлемента();

	ConversionRulesTable.Индексы.Добавить("Приемник");

КонецПроцедуры

// Осуществляет загрузку группы правил очистки данных в соответствии с форматом правил обмена.
//
// Параметры:
//  НоваяСтрока - СтрокаДереваЗначений - структура, описывающая группу правил очистки данных:
//    * Имя - Строка - идентификатор правила.
//    * Наименование - Строка - пользовательское представление правила.
// 
Процедура ЗагрузитьГруппуПОД(ПравилаОбмена, НоваяСтрока)

	НоваяСтрока.ЭтоГруппа = Истина;
	НоваяСтрока.Включить  = Число(Не одАтрибут(ПравилаОбмена, одТипБулево, "Отключить"));

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
		ТипУзла = ПравилаОбмена.ТипУзла;

		Если ИмяУзла = "Код" Тогда
			НоваяСтрока.Имя = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Наименование" Тогда
			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Порядок" Тогда
			НоваяСтрока.Порядок = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "Правило" Тогда
			СтрокаДЗ = НоваяСтрока.Строки.Добавить();
			ЗагрузитьПОД(ПравилаОбмена, СтрокаДЗ);

		ИначеЕсли (ИмяУзла = "Группа") И (ТипУзла = одТипУзлаXML_НачалоЭлемента) Тогда
			СтрокаДЗ = НоваяСтрока.Строки.Добавить();
			ЗагрузитьГруппуПОД(ПравилаОбмена, СтрокаДЗ);

		ИначеЕсли (ИмяУзла = "Группа") И (ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Если ПустаяСтрока(НоваяСтрока.Наименование) Тогда
		НоваяСтрока.Наименование = НоваяСтрока.Имя;
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку правила очистки данных в соответствии с форматом правил обмена.
//
// Параметры:
//  НоваяСтрока - СтрокаДереваЗначений - структура, описывающая правило очистки данных:
//    * Имя - Строка - идентификатор правила.
//    * Наименование - Строка - пользовательское представление правила.
// 
Процедура ЗагрузитьПОД(ПравилаОбмена, НоваяСтрока)

	НоваяСтрока.Включить = Число(Не одАтрибут(ПравилаОбмена, одТипБулево, "Отключить"));

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Код" Тогда
			Значение = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			НоваяСтрока.Имя = Значение;

		ИначеЕсли ИмяУзла = "Наименование" Тогда
			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Порядок" Тогда
			НоваяСтрока.Порядок = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "СпособОтбораДанных" Тогда
			НоваяСтрока.СпособОтбораДанных = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "ОбъектВыборки" Тогда
			ОбъектВыборки = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Если Не ПустаяСтрока(ОбъектВыборки) Тогда
				НоваяСтрока.ОбъектВыборки = Тип(ОбъектВыборки);
			КонецЕсли;

		ИначеЕсли ИмяУзла = "УдалятьЗаПериод" Тогда
			НоваяСтрока.УдалятьЗаПериод = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Непосредственно" Тогда
			НоваяСтрока.Непосредственно = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		
		// Обработчики событий

		ИначеЕсли ИмяУзла = "ПередОбработкойПравила" Тогда
			НоваяСтрока.ПередОбработкой = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "ПослеОбработкиПравила" Тогда
			НоваяСтрока.ПослеОбработки = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "ПередУдалениемОбъекта" Тогда
			НоваяСтрока.ПередУдалением = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		// Выход
		ИначеЕсли (ИмяУзла = "Правило") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;

		КонецЕсли;

	КонецЦикла;
	Если ПустаяСтрока(НоваяСтрока.Наименование) Тогда
		НоваяСтрока.Наименование = НоваяСтрока.Имя;
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку правил очистки данных.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьПравилаОчистки(ПравилаОбмена, ЗаписьXML)

	CleanupRulesTable.Строки.Очистить();
	СтрокиДЗ = CleanupRulesTable.Строки;

	ЗаписьXML.ЗаписатьНачалоЭлемента("ПравилаОчисткиДанных");

	Пока ПравилаОбмена.Прочитать() Цикл

		ТипУзла = ПравилаОбмена.ТипУзла;

		Если ТипУзла = одТипУзлаXML_НачалоЭлемента Тогда
			ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
			Если ExchangeMode <> "Загрузка" Тогда
				ЗаписьXML.ЗаписатьНачалоЭлемента(ПравилаОбмена.Имя);
				Пока ПравилаОбмена.ПрочитатьАтрибут() Цикл
					ЗаписьXML.ЗаписатьАтрибут(ПравилаОбмена.Имя, ПравилаОбмена.Значение);
				КонецЦикла;
			Иначе
				Если ИмяУзла = "Правило" Тогда
					СтрокаДЗ = СтрокиДЗ.Добавить();
					ЗагрузитьПОД(ПравилаОбмена, СтрокаДЗ);
				ИначеЕсли ИмяУзла = "Группа" Тогда
					СтрокаДЗ = СтрокиДЗ.Добавить();
					ЗагрузитьГруппуПОД(ПравилаОбмена, СтрокаДЗ);
				КонецЕсли;
			КонецЕсли;
		ИначеЕсли ТипУзла = одТипУзлаXML_КонецЭлемента Тогда
			ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
			Если ИмяУзла = "ПравилаОчисткиДанных" Тогда
				Прервать;
			Иначе
				Если ExchangeMode <> "Загрузка" Тогда
					ЗаписьXML.ЗаписатьКонецЭлемента();
				КонецЕсли;
			КонецЕсли;
		ИначеЕсли ТипУзла = одТипУзлаXML_Текст Тогда
			Если ExchangeMode <> "Загрузка" Тогда
				ЗаписьXML.ЗаписатьТекст(ПравилаОбмена.Значение);
			КонецЕсли;
		КонецЕсли;
	КонецЦикла;

	СтрокиДЗ.Сортировать("Порядок", Истина);

	ЗаписьXML.ЗаписатьКонецЭлемента();

КонецПроцедуры

// Осуществляет загрузку алгоритма в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьАлгоритм(ПравилаОбмена, ЗаписьXML)

	ИспользуетсяПриЗагрузке = одАтрибут(ПравилаОбмена, одТипБулево, "ИспользуетсяПриЗагрузке");
	Имя                     = одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Текст" Тогда
			Текст = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
		ИначеЕсли (ИмяУзла = "Алгоритм") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		Иначе
			одПропустить(ПравилаОбмена);
		КонецЕсли;

	КонецЦикла;
	Если ИспользуетсяПриЗагрузке Тогда
		Если ExchangeMode = "Загрузка" Тогда
			Алгоритмы.Вставить(Имя, Текст);
		Иначе
			ЗаписьXML.ЗаписатьНачалоЭлемента("Алгоритм");
			УстановитьАтрибут(ЗаписьXML, "ИспользуетсяПриЗагрузке", Истина);
			УстановитьАтрибут(ЗаписьXML, "Имя", Имя);
			одЗаписатьЭлемент(ЗаписьXML, "Текст", Текст);
			ЗаписьXML.ЗаписатьКонецЭлемента();
		КонецЕсли;
	Иначе
		Если ExchangeMode <> "Загрузка" Тогда
			Алгоритмы.Вставить(Имя, Текст);
		КонецЕсли;
	КонецЕсли;
КонецПроцедуры

// Осуществляет загрузку алгоритмов в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьАлгоритмы(ПравилаОбмена, ЗаписьXML)

	Алгоритмы.Очистить();

	ЗаписьXML.ЗаписатьНачалоЭлемента("Алгоритмы");

	Пока ПравилаОбмена.Прочитать() Цикл
		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
		Если ИмяУзла = "Алгоритм" Тогда
			ЗагрузитьАлгоритм(ПравилаОбмена, ЗаписьXML);
		ИначеЕсли (ИмяУзла = "Алгоритмы") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	ЗаписьXML.ЗаписатьКонецЭлемента();

КонецПроцедуры

// Осуществляет загрузку запроса в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьЗапрос(ПравилаОбмена, ЗаписьXML)

	ИспользуетсяПриЗагрузке = одАтрибут(ПравилаОбмена, одТипБулево, "ИспользуетсяПриЗагрузке");
	Имя                     = одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Текст" Тогда
			Текст = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);
		ИначеЕсли (ИмяУзла = "Запрос") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		Иначе
			одПропустить(ПравилаОбмена);
		КонецЕсли;

	КонецЦикла;

	Если ИспользуетсяПриЗагрузке Тогда
		Если ExchangeMode = "Загрузка" Тогда
			Запрос	= Новый Запрос(Текст);
			Запросы.Вставить(Имя, Запрос);
		Иначе
			ЗаписьXML.ЗаписатьНачалоЭлемента("Запрос");
			УстановитьАтрибут(ЗаписьXML, "ИспользуетсяПриЗагрузке", Истина);
			УстановитьАтрибут(ЗаписьXML, "Имя", Имя);
			одЗаписатьЭлемент(ЗаписьXML, "Текст", Текст);
			ЗаписьXML.ЗаписатьКонецЭлемента();
		КонецЕсли;
	Иначе
		Если ExchangeMode <> "Загрузка" Тогда
			Запрос	= Новый Запрос(Текст);
			Запросы.Вставить(Имя, Запрос);
		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку запросов в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьЗапросы(ПравилаОбмена, ЗаписьXML)

	Запросы.Очистить();

	ЗаписьXML.ЗаписатьНачалоЭлемента("Запросы");

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Запрос" Тогда
			ЗагрузитьЗапрос(ПравилаОбмена, ЗаписьXML);
		ИначеЕсли (ИмяУзла = "Запросы") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	ЗаписьXML.ЗаписатьКонецЭлемента();

КонецПроцедуры

// Осуществляет загрузку параметров в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//
Процедура ЗагрузитьПараметры(ПравилаОбмена, ЗаписьXML)

	Parameters.Очистить();
	СобытияПослеЗагрузкиПараметров.Очистить();
	ParametersSettingsTable.Очистить();

	ЗаписьXML.ЗаписатьНачалоЭлемента("Parameters");

	Пока ПравилаОбмена.Прочитать() Цикл
		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
		ТипУзла = ПравилаОбмена.ТипУзла;

		Если ИмяУзла = "Параметр" И ТипУзла = одТипУзлаXML_НачалоЭлемента Тогда
			
			// Загрузка по версии правил 2.01.
			Имя                     = одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");
			Наименование            = одАтрибут(ПравилаОбмена, одТипСтрока, "Наименование");
			УстанавливатьВДиалоге   = одАтрибут(ПравилаОбмена, одТипБулево, "УстанавливатьВДиалоге");
			СтрокаТипаЗначения      = одАтрибут(ПравилаОбмена, одТипСтрока, "ТипЗначения");
			ИспользуетсяПриЗагрузке = одАтрибут(ПравилаОбмена, одТипБулево, "ИспользуетсяПриЗагрузке");
			ПередаватьПараметрПриВыгрузке = одАтрибут(ПравилаОбмена, одТипБулево, "ПередаватьПараметрПриВыгрузке");
			ПравилоКонвертации = одАтрибут(ПравилаОбмена, одТипСтрока, "ПравилоКонвертации");
			АлгоритмПослеЗагрузкиПараметра = одАтрибут(ПравилаОбмена, одТипСтрока, "ПослеЗагрузкиПараметра");

			Если Не ПустаяСтрока(АлгоритмПослеЗагрузкиПараметра) Тогда

				СобытияПослеЗагрузкиПараметров.Вставить(Имя, АлгоритмПослеЗагрузкиПараметра);

			КонецЕсли;

			Если ExchangeMode = "Загрузка" И Не ИспользуетсяПриЗагрузке Тогда
				Продолжить;
			КонецЕсли;
			
			// Определяем типы значений и устанавливаем начальные значения.
			Если Не ПустаяСтрока(СтрокаТипаЗначения) Тогда

				Попытка
					ТипЗначенияДанных = Тип(СтрокаТипаЗначения);
					ТипОпределен = Истина;
				Исключение
					ТипОпределен = Ложь;
				КонецПопытки;

			Иначе

				ТипОпределен = Ложь;

			КонецЕсли;

			Если ТипОпределен Тогда
				ЗначениеПараметра = одПолучитьПустоеЗначение(ТипЗначенияДанных);
				Parameters.Вставить(Имя, ЗначениеПараметра);
			Иначе
				ЗначениеПараметра = "";
				Parameters.Вставить(Имя);
			КонецЕсли;

			Если УстанавливатьВДиалоге = Истина Тогда

				СтрокаТаблицы              = ParametersSettingsTable.Добавить();
				СтрокаТаблицы.Наименование = Наименование;
				СтрокаТаблицы.Имя          = Имя;
				СтрокаТаблицы.Значение = ЗначениеПараметра;
				СтрокаТаблицы.ПередаватьПараметрПриВыгрузке = ПередаватьПараметрПриВыгрузке;
				СтрокаТаблицы.ПравилоКонвертации = ПравилоКонвертации;

			КонецЕсли;

			Если ИспользуетсяПриЗагрузке И ExchangeMode = "Выгрузка" Тогда

				ЗаписьXML.ЗаписатьНачалоЭлемента("Параметр");
				УстановитьАтрибут(ЗаписьXML, "Имя", Имя);
				УстановитьАтрибут(ЗаписьXML, "Наименование", Наименование);

				Если Не ПустаяСтрока(АлгоритмПослеЗагрузкиПараметра) Тогда
					УстановитьАтрибут(ЗаписьXML, "ПослеЗагрузкиПараметра", XMLСтрока(АлгоритмПослеЗагрузкиПараметра));
				КонецЕсли;

				ЗаписьXML.ЗаписатьКонецЭлемента();

			КонецЕсли;

		ИначеЕсли (ТипУзла = одТипУзлаXML_Текст) Тогда
			
			// Для совместимости с версией правил 2.0 используем загрузку из строки.
			СтрокаПараметров = ПравилаОбмена.Значение;
			Для Каждого Пар Из МассивИзСтроки(СтрокаПараметров) Цикл
				Parameters.Вставить(Пар);
			КонецЦикла;

		ИначеЕсли (ИмяУзла = "Parameters") И (ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	ЗаписьXML.ЗаписатьКонецЭлемента();

КонецПроцедуры

// Осуществляет загрузку обработки в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьОбработку(ПравилаОбмена, ЗаписьXML)

	Имя                     = одАтрибут(ПравилаОбмена, одТипСтрока, "Имя");
	Наименование            = одАтрибут(ПравилаОбмена, одТипСтрока, "Наименование");
	ЭтоОбработкаНастройки   = одАтрибут(ПравилаОбмена, одТипБулево, "ЭтоОбработкаНастройки");

	ИспользуетсяПриВыгрузке = одАтрибут(ПравилаОбмена, одТипБулево, "ИспользуетсяПриВыгрузке");
	ИспользуетсяПриЗагрузке = одАтрибут(ПравилаОбмена, одТипБулево, "ИспользуетсяПриЗагрузке");

	СтрокаПараметров        = одАтрибут(ПравилаОбмена, одТипСтрока, "Parameters");

	ХранилищеОбработки      = одЗначениеЭлемента(ПравилаОбмена, одТипХранилищеЗначения);

	ПараметрыДопОбработок.Вставить(Имя, МассивИзСтроки(СтрокаПараметров));
	Если ИспользуетсяПриЗагрузке Тогда
		Если ExchangeMode = "Загрузка" Тогда

		Иначе
			ЗаписьXML.ЗаписатьНачалоЭлемента("Обработка");
			УстановитьАтрибут(ЗаписьXML, "ИспользуетсяПриЗагрузке", Истина);
			УстановитьАтрибут(ЗаписьXML, "Имя", Имя);
			УстановитьАтрибут(ЗаписьXML, "Наименование", Наименование);
			УстановитьАтрибут(ЗаписьXML, "ЭтоОбработкаНастройки", ЭтоОбработкаНастройки);
			ЗаписьXML.ЗаписатьТекст(XMLСтрока(ХранилищеОбработки));
			ЗаписьXML.ЗаписатьКонецЭлемента();
		КонецЕсли;
	КонецЕсли;

	Если ЭтоОбработкаНастройки Тогда
		Если (ExchangeMode = "Загрузка") И ИспользуетсяПриЗагрузке Тогда
			ImportSettingsDataProcessors.Добавить(Имя, Наименование, , );

		ИначеЕсли (ExchangeMode = "Выгрузка") И ИспользуетсяПриВыгрузке Тогда
			ExportSettingsDataProcessors.Добавить(Имя, Наименование, , );

		КонецЕсли;
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку внешних обработок в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  ЗаписьXML      - ЗаписьXML - Объект типа ЗаписьXML - правила, сохраняемые в файл обмена и
//                   используемые при загрузке данных.
//
Процедура ЗагрузитьОбработки(ПравилаОбмена, ЗаписьXML)

	ДопОбработки.Очистить();
	ПараметрыДопОбработок.Очистить();

	ExportSettingsDataProcessors.Очистить();
	ImportSettingsDataProcessors.Очистить();

	ЗаписьXML.ЗаписатьНачалоЭлемента("Обработки");

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Обработка" Тогда
			ЗагрузитьОбработку(ПравилаОбмена, ЗаписьXML);
		ИначеЕсли (ИмяУзла = "Обработки") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	ЗаписьXML.ЗаписатьКонецЭлемента();

КонецПроцедуры

// Осуществляет загрузку группы правил выгрузки данных в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - объект типа ЧтениеXML.
//  НоваяСтрока    - СтрокаДереваЗначений - структура, описывающая группу правил выгрузки данных:
//    * Имя - Строка - идентификатор правила.
//    * Наименование - Строка - пользовательское представление правила.
//
Процедура ЗагрузитьГруппуПВД(ПравилаОбмена, НоваяСтрока)

	НоваяСтрока.ЭтоГруппа = Истина;
	НоваяСтрока.Включить  = Число(Не одАтрибут(ПравилаОбмена, одТипБулево, "Отключить"));

	Пока ПравилаОбмена.Прочитать() Цикл
		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
		ТипУзла = ПравилаОбмена.ТипУзла;
		Если ИмяУзла = "Код" Тогда
			НоваяСтрока.Имя = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Наименование" Тогда
			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Порядок" Тогда
			НоваяСтрока.Порядок = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "Правило" Тогда
			СтрокаДЗ = НоваяСтрока.Строки.Добавить();
			ЗагрузитьПВД(ПравилаОбмена, СтрокаДЗ);

		ИначеЕсли (ИмяУзла = "Группа") И (ТипУзла = одТипУзлаXML_НачалоЭлемента) Тогда
			СтрокаДЗ = НоваяСтрока.Строки.Добавить();
			ЗагрузитьГруппуПВД(ПравилаОбмена, СтрокаДЗ);

		ИначеЕсли (ИмяУзла = "Группа") И (ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Если ПустаяСтрока(НоваяСтрока.Наименование) Тогда
		НоваяСтрока.Наименование = НоваяСтрока.Имя;
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку правила выгрузки данных в соответствии с форматом правил обмена.
//
// Parameters:
//  ПравилаОбмена  - ЧтениеXML - Объект типа ЧтениеXML.
//  НоваяСтрока    - СтрокаДереваЗначений - структура, описывающая правило выгрузки данных:
//    * Имя - Строка - идентификатор правила.
//    * Наименование - Строка - пользовательское представление правила.
//
Процедура ЗагрузитьПВД(ПравилаОбмена, НоваяСтрока)

	НоваяСтрока.Включить = Число(Не одАтрибут(ПравилаОбмена, одТипБулево, "Отключить"));

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;
		Если ИмяУзла = "Код" Тогда
			НоваяСтрока.Имя = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Наименование" Тогда
			НоваяСтрока.Наименование = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "Порядок" Тогда
			НоваяСтрока.Порядок = одЗначениеЭлемента(ПравилаОбмена, одТипЧисло);

		ИначеЕсли ИмяУзла = "СпособОтбораДанных" Тогда
			НоваяСтрока.СпособОтбораДанных = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		ИначеЕсли ИмяУзла = "ВыбиратьДанныеДляВыгрузкиОднимЗапросом" Тогда
			НоваяСтрока.ВыбиратьДанныеДляВыгрузкиОднимЗапросом = одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "НеВыгружатьОбъектыСозданныеВБазеПриемнике" Тогда
			// Параметр игнорируется при обмене данными.
			одЗначениеЭлемента(ПравилаОбмена, одТипБулево);

		ИначеЕсли ИмяУзла = "ОбъектВыборки" Тогда
			ОбъектВыборки = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);
			Если Не ПустаяСтрока(ОбъектВыборки) Тогда
				НоваяСтрока.ОбъектВыборки = Тип(ОбъектВыборки);
			КонецЕсли;
			// Для поддержки отбора с помощью построителя.
			Если СтрНайти(ОбъектВыборки, "Ссылка.") Тогда
				НоваяСтрока.ИмяОбъектаДляЗапроса = СтрЗаменить(ОбъектВыборки, "Ссылка.", ".");
			Иначе
				НоваяСтрока.ИмяОбъектаДляЗапросаРегистра = СтрЗаменить(ОбъектВыборки, "Запись.", ".");
			КонецЕсли;

		ИначеЕсли ИмяУзла = "КодПравилаКонвертации" Тогда
			НоваяСтрока.ПравилоКонвертации = одЗначениеЭлемента(ПравилаОбмена, одТипСтрока);

		// Обработчики событий

		ИначеЕсли ИмяУзла = "ПередОбработкойПравила" Тогда
			НоваяСтрока.ПередОбработкой = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "ПослеОбработкиПравила" Тогда
			НоваяСтрока.ПослеОбработки = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "ПередВыгрузкойОбъекта" Тогда
			НоваяСтрока.ПередВыгрузкой = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		ИначеЕсли ИмяУзла = "ПослеВыгрузкиОбъекта" Тогда
			НоваяСтрока.ПослеВыгрузки = ПолучитьИзТекстаЗначениеОбработчика(ПравилаОбмена);

		ИначеЕсли (ИмяУзла = "Правило") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Если ПустаяСтрока(НоваяСтрока.Наименование) Тогда
		НоваяСтрока.Наименование = НоваяСтрока.Имя;
	КонецЕсли; 
	
	//УИ Изменено
	Если ПустаяСтрока(НоваяСтрока.ИмяМетаданных) Тогда
		НоваяСтрока.ИмяМетаданных = ?(ЗначениеЗаполнено(НоваяСтрока.ИмяОбъектаДляЗапросаРегистра),
			НоваяСтрока.ИмяОбъектаДляЗапросаРегистра, НоваяСтрока.ИмяОбъектаДляЗапроса);
	КонецЕсли;

КонецПроцедуры

// Осуществляет загрузку правил выгрузки данных в соответствии с форматом правил обмена.
//
// Параметры:
//  ПравилаОбмена - ЧтениеXML - Объект типа ЧтениеXML.
//
Процедура ЗагрузитьПравилаВыгрузки(ПравилаОбмена)

	ExportRulesTable.Строки.Очистить();

	СтрокиДЗ = ExportRulesTable.Строки;

	Пока ПравилаОбмена.Прочитать() Цикл

		ИмяУзла = ПравилаОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Правило" Тогда

			СтрокаДЗ = СтрокиДЗ.Добавить();
			ЗагрузитьПВД(ПравилаОбмена, СтрокаДЗ);

		ИначеЕсли ИмяУзла = "Группа" Тогда

			СтрокаДЗ = СтрокиДЗ.Добавить();
			ЗагрузитьГруппуПВД(ПравилаОбмена, СтрокаДЗ);

		ИначеЕсли (ИмяУзла = "ПравилаВыгрузкиДанных") И (ПравилаОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		КонецЕсли;

	КонецЦикла;

	СтрокиДЗ.Сортировать("Порядок", Истина);

КонецПроцедуры

#КонецОбласти

#Область ПроцедурыЭкспортаОбработчиковИАлгоритмовВTXTФайлИзПравилОбмена

// Выгружает обработчики событий и алгоритмы во временный текстовый файл 
// (во временный каталог пользователя).
// Формирует модуль отладки с обработчиками и алгоритмами и со всеми 
// необходимыми глобальными переменными, обертками общих функций и комментариями.
//
// Параметры:
//  Отказ - Булево - флаг отказа от создания модуля отладки. Возникает если не
//          удалось прочесть правила обмена.
//
Процедура ВыгрузитьОбработчикиСобытий(Отказ) Экспорт

	ИнициализироватьВедениеПротоколаОбменаДляЭкспортаОбработчиков();

	РежимОбработкиДанных = мРежимыОбработкиДанных.ЭкспортОбработчиковСобытий;

	ErrorFlag = Ложь;

	ЗагрузитьПравилаОбменаДляЭкспортаОбработчиков();

	Если ErrorFlag Тогда
		Отказ = Истина;
		Возврат;
	КонецЕсли;

	ДополнитьПравилаИнтерфейсамиОбработчиков(Конвертация, ConversionRulesTable, ExportRulesTable,
		CleanupRulesTable);

	Если AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.ИнтеграцияКода Тогда

		ПолучитьПолныйКодАлгоритмовСУчетомВложенности();

	КонецЕсли;

	EventHandlersTempFileName = ПолучитьНовоеУникальноеИмяВременногоФайла(
		EventHandlersTempFileName);

	Результат = Новый ЗаписьТекста(EventHandlersTempFileName, КодировкаТекста.ANSI);

	мМакетОбщиеПроцедурыФункции = ПолучитьМакет("ОбщиеПроцедурыФункции");
	
	// Выводим комментарии.
	ДобавитьВПотокКомментарий(Результат, "Шапка");
	ДобавитьВПотокКомментарий(Результат, "ПеременныеОбработки");
	
	// Выводим служебный код.
	ДобавитьВПотокСлужебныйКод(Результат, "ПеременныеОбработки");
	
	// Выгружаем глобальные обработчики.
	ВыгрузитьОбработчикиКонвертации(Результат);
	
	// Выгружаем ПВД.
	ДобавитьВПотокКомментарий(Результат, "ПВД", ExportRulesTable.Строки.Количество() <> 0);
	ВыгрузитьОбработчикиПравилВыгрузкиДанных(Результат, ExportRulesTable.Строки);
	
	// Выгружаем ПОД.
	ДобавитьВПотокКомментарий(Результат, "ПОД", CleanupRulesTable.Строки.Количество() <> 0);
	ВыгрузитьОбработчикиПравилОчисткиДанных(Результат, CleanupRulesTable.Строки);
	
	// Выгружаем ПКО, ПКС, ПКГС.
	ВыгрузитьОбработчикиПравилКонвертации(Результат);

	Если AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.ПроцедурныйВызов Тогда
		
		// Выгружаем Алгоритмы со стандартными параметрами (параметрами по умолчанию).
		ВыгрузитьАлгоритмы(Результат);

	КонецЕсли; 
	
	// Выводим комментарии
	ДобавитьВПотокКомментарий(Результат, "Предупреждение");
	ДобавитьВПотокКомментарий(Результат, "ОбщиеПроцедурыФункции");
		
	// Выводим общие процедуры и функции в поток.
	ДобавитьВПотокСлужебныйКод(Результат, "ОбщиеПроцедурыФункции");

	// Выводим конструктор внешней обработки.
	ВыгрузитьКонструкторВнешнейОбработки(Результат);
	
	// Выводим деструктор
	ДобавитьВПотокСлужебныйКод(Результат, "Деструктор");

	Результат.Закрыть();

	ЗавершитьВедениеПротоколаОбмена();

	Если IsInteractiveMode Тогда

		Если ErrorFlag Тогда

			СообщитьПользователю(НСтр("ru = 'При выгрузке обработчиков были обнаружены ошибки.'"));

		Иначе

			СообщитьПользователю(НСтр("ru = 'Обработчики успешно выгружены.'"));

		КонецЕсли;

	КонецЕсли;

КонецПроцедуры

// Очищает переменные со структурой правил обмена.
//
// Параметры:
//  Нет.
//  
Процедура ОчиститьПравилаОбмена()

	ExportRulesTable.Строки.Очистить();
	CleanupRulesTable.Строки.Очистить();
	ConversionRulesTable.Очистить();
	Алгоритмы.Очистить();
	Запросы.Очистить();

	// Обработки
	ДопОбработки.Очистить();
	ПараметрыДопОбработок.Очистить();
	ExportSettingsDataProcessors.Очистить();
	ImportSettingsDataProcessors.Очистить();

КонецПроцедуры  

// Производит загрузку правил обмена из файла-правил или файла-данных.
//
// Параметры:
//  Нет.
//  
Процедура ЗагрузитьПравилаОбменаДляЭкспортаОбработчиков()

	ОчиститьПравилаОбмена();

	Если ReadEventHandlersFromExchangeRulesFile Тогда

		ExchangeMode = ""; // Выгрузка

		ЗагрузитьПравилаОбмена();

		мБылиПрочитаныПравилаОбменаПриЗагрузке = Ложь;

		ИнициализироватьПервоначальныеЗначенияПараметров();

	Иначе // файл данных

		ExchangeMode = "Загрузка";

		Если ПустаяСтрока(ExchangeFileName) Тогда
			ЗаписатьВПротоколВыполнения(15);
			Возврат;
		КонецЕсли;

		ОткрытьФайлЗагрузки(Истина);
		
		// При наличии флага обработка потребует перечитать
		// правила при попытке выгрузки данных.
		мБылиПрочитаныПравилаОбменаПриЗагрузке = Истина;

	КонецЕсли;

КонецПроцедуры

// Выгружает глобальные обработчики конвертации в текстовый файл.
// При выгрузке обработчиков из файла с данными содержимое обработчика "Конвертация_ПослеЗагрузкиПараметров"
// не выгружается, т.к. код обработчика находится не в узле правил обмена, а в отдельном узле.
// При выгрузке обработчиков из файла правил этот алгоритм выгружается как и другие.
//
// Параметры:
//  Результат - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчиков в текстовый файл.
//
Процедура ВыгрузитьОбработчикиКонвертации(Результат)

	ДобавитьВПотокКомментарий(Результат, "Конвертация");

	Для Каждого Элемент Из ИменаОбработчиков.Конвертация Цикл

		ДобавитьВПотокОбработчикКонвертации(Результат, Элемент.Ключ);

	КонецЦикла;

КонецПроцедуры 

// Выгружает обработчики правил выгрузки данных в текстовый файл.
//
// Параметры:
//  Результат    - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчиков в текстовый файл.
//  СтрокиДерева - КоллекцияСтрокДереваЗначений - Объект типа КоллекцияСтрокДереваЗначений - содержит ПВД данного уровня
//                                                дерева значений.
//
Процедура ВыгрузитьОбработчикиПравилВыгрузкиДанных(Результат, СтрокиДерева)

	Для Каждого Правило Из СтрокиДерева Цикл

		Если Правило.ЭтоГруппа Тогда

			ВыгрузитьОбработчикиПравилВыгрузкиДанных(Результат, Правило.Строки);

		Иначе

			Для Каждого Элемент Из ИменаОбработчиков.ПВД Цикл

				ДобавитьВПотокОбработчик(Результат, Правило, "ПВД", Элемент.Ключ);

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры  

// Выгружает обработчики правил очистки данных в текстовый файл.
//
// Параметры:
//  Результат    - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчиков в текстовый файл.
//  СтрокиДерева - КоллекцияСтрокДереваЗначений - Объект типа КоллекцияСтрокДереваЗначений - содержит ПОД данного уровня
//                                                дерева значений.
//
Процедура ВыгрузитьОбработчикиПравилОчисткиДанных(Результат, СтрокиДерева)

	Для Каждого Правило Из СтрокиДерева Цикл

		Если Правило.ЭтоГруппа Тогда

			ВыгрузитьОбработчикиПравилОчисткиДанных(Результат, Правило.Строки);

		Иначе

			Для Каждого Элемент Из ИменаОбработчиков.ПОД Цикл

				ДобавитьВПотокОбработчик(Результат, Правило, "ПОД", Элемент.Ключ);

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры  

// Выгружает обработчики правил конвертации: ПКО, ПКС, ПКГС в текстовый файл.
//
// Параметры:
//  Результат    - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчиков в текстовый файл.
//
Процедура ВыгрузитьОбработчикиПравилКонвертации(Результат)

	ВывестиКомментарий = ConversionRulesTable.Количество() <> 0;
	
	// Выгружаем ПКО.
	ДобавитьВПотокКомментарий(Результат, "ПКО", ВывестиКомментарий);

	Для Каждого ПКО Из ConversionRulesTable Цикл

		Для Каждого Элемент Из ИменаОбработчиков.ПКО Цикл

			ДобавитьВПотокОбработчикПКО(Результат, ПКО, Элемент.Ключ);

		КонецЦикла;

	КонецЦикла; 
	
	// Выгружаем ПКС и ПКГС.
	ДобавитьВПотокКомментарий(Результат, "ПКС", ВывестиКомментарий);

	Для Каждого ПКО Из ConversionRulesTable Цикл

		ВыгрузитьОбработчикиПравилКонвертацииСвойств(Результат, ПКО.СвойстваПоиска);
		ВыгрузитьОбработчикиПравилКонвертацииСвойств(Результат, ПКО.Свойства);

	КонецЦикла;

КонецПроцедуры 

// Выгружает обработчики правил конвертации свойств в текстовый файл.
//
// Параметры:
//  Результат - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчиков в текстовый файл.
//  ПКС       - ТаблицаЗначений - содержит правила конвертации свойств или групп свойств объекта.
//
Процедура ВыгрузитьОбработчикиПравилКонвертацииСвойств(Результат, ПКС)

	Для Каждого Правило Из ПКС Цикл

		Если Правило.ЭтоГруппа Тогда // ПКГС

			Для Каждого Элемент Из ИменаОбработчиков.ПКГС Цикл

				ДобавитьВПотокОбработчикПКО(Результат, Правило, Элемент.Ключ);

			КонецЦикла;

			ВыгрузитьОбработчикиПравилКонвертацииСвойств(Результат, Правило.ПравилаГруппы);

		Иначе

			Для Каждого Элемент Из ИменаОбработчиков.ПКС Цикл

				ДобавитьВПотокОбработчикПКО(Результат, Правило, Элемент.Ключ);

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

// Выгружает алгоритмы в текстовый файл.
//
// Параметры:
//  Результат - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода алгоритмов в текстовый файл.
//
Процедура ВыгрузитьАлгоритмы(Результат)
	
	// Комментарий к блоку "Алгоритмы".
	ДобавитьВПотокКомментарий(Результат, "Алгоритмы", Алгоритмы.Количество() <> 0);

	Для Каждого Алгоритм Из Алгоритмы Цикл

		ДобавитьВПотокАлгоритм(Результат, Алгоритм);

	КонецЦикла;

КонецПроцедуры  

// Выгружает конструктор внешней обработки в текстовый файл.
//  Если режим отладки алгоритмов - "алгоритмы отлаживать как процедуры", то в конструктор добавляется структура
//  "Алгоритмы".
//  Ключ элемента структуры - имя алгоритма, значение - интерфейс вызова процедуры, содержащей код алгоритма.
//
// Параметры:
//  Результат    - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчиков в текстовый файл.
//
Процедура ВыгрузитьКонструкторВнешнейОбработки(Результат)
	
	// Выводим комментарий
	ДобавитьВПотокКомментарий(Результат, "Конструктор");

	ТелоПроцедуры = ПолучитьСлужебныйКод("Конструктор_ТелоПроцедуры");

	Если AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.ПроцедурныйВызов Тогда

		ТелоПроцедуры = ТелоПроцедуры + ПолучитьСлужебныйКод("Конструктор_ТелоПроцедуры_ПроцедурныйВызовАлгоритмов");
		
		// Добавляем в тело конструктора вызовы Алгоритмов.
		Для Каждого Алгоритм Из Алгоритмы Цикл

			КлючАлгоритма = СокрЛП(Алгоритм.Ключ);

			ИнтерфейсАлгоритма = ПолучитьИнтерфейсАлгоритма(КлючАлгоритма) + ";";

			ИнтерфейсАлгоритма = СтрЗаменить(СтрЗаменить(ИнтерфейсАлгоритма, Символы.ПС, " "), " ", "");

			ТелоПроцедуры = ТелоПроцедуры + Символы.ПС + "Алгоритмы.Вставить(""" + КлючАлгоритма + """, """
				+ ИнтерфейсАлгоритма + """);";
		КонецЦикла;

	ИначеЕсли AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.ИнтеграцияКода Тогда

		ТелоПроцедуры = ТелоПроцедуры + ПолучитьСлужебныйКод("Конструктор_ТелоПроцедуры_ИнтеграцияКодаАлгоритмов");

	ИначеЕсли AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.НеИспользовать Тогда

		ТелоПроцедуры = ТелоПроцедуры + ПолучитьСлужебныйКод(
			"Конструктор_ТелоПроцедуры_НеИспользоватьОтладкуАлгоритмов");

	КонецЕсли;

	ИнтерфейсПроцедурыВнешнейОбработки = "Процедура " + ПолучитьИнтерфейсПроцедурыВнешнейОбработки("Конструктор")
		+ " Экспорт";

	ДобавитьВПотокПолныйОбработчик(Результат, ИнтерфейсПроцедурыВнешнейОбработки, ТелоПроцедуры);

КонецПроцедуры  

// Добавляет в объект "Результат" обработчик ПКО, ПКС или ПКГС.
//
// Параметры:
//  Результат      - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчика в текстовый файл.
//  Правило        - строка таблицы значений с правилами конвертации объекта.
//  ИмяОбработчика - строка - имя обработчика.
//
Процедура ДобавитьВПотокОбработчикПКО(Результат, Правило, ИмяОбработчика)

	Если Не Правило["ЕстьОбработчик" + ИмяОбработчика] Тогда
		Возврат;
	КонецЕсли;

	ИнтерфейсОбработчика = "Процедура " + Правило["ИнтерфейсОбработчика" + ИмяОбработчика] + " Экспорт";

	ДобавитьВПотокПолныйОбработчик(Результат, ИнтерфейсОбработчика, Правило[ИмяОбработчика]);

КонецПроцедуры  

// Добавляет в объект "Результат" код алгоритма.
//
// Параметры:
//  Результат - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчика в текстовый файл.
//  Алгоритм  - элемент структуры - алгоритм для выгрузки.
//
Процедура ДобавитьВПотокАлгоритм(Результат, Алгоритм)

	ИнтерфейсАлгоритма = "Процедура " + ПолучитьИнтерфейсАлгоритма(Алгоритм.Ключ);

	ДобавитьВПотокПолныйОбработчик(Результат, ИнтерфейсАлгоритма, Алгоритм.Значение);

КонецПроцедуры  

// Добавляет в объект "Результат" обработчик ПВД или ПОД.
//
// Параметры:
//  Результат      - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчика в текстовый файл.
//  Правило        - строка дерева значений с правилами.
//  ПрефиксОбработчика - строка - префикс обработчика: "ПВД" или "ПОД".
//  ИмяОбработчика - строка - имя обработчика.
//
Процедура ДобавитьВПотокОбработчик(Результат, Правило, ПрефиксОбработчика, ИмяОбработчика)

	Если ПустаяСтрока(Правило[ИмяОбработчика]) Тогда
		Возврат;
	КонецЕсли;

	ИнтерфейсОбработчика = "Процедура " + Правило["ИнтерфейсОбработчика" + ИмяОбработчика] + " Экспорт";

	ДобавитьВПотокПолныйОбработчик(Результат, ИнтерфейсОбработчика, Правило[ИмяОбработчика]);

КонецПроцедуры  

// Добавляет в объект "Результат" глобальный обработчик конвертации.
//
// Parameters:
//  Результат      - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода обработчика в текстовый файл.
//  ИмяОбработчика - строка - имя обработчика.
//
Процедура ДобавитьВПотокОбработчикКонвертации(Результат, ИмяОбработчика)

	АлгоритмОбработчика = "";

	Если Конвертация.Свойство(ИмяОбработчика, АлгоритмОбработчика) И Не ПустаяСтрока(АлгоритмОбработчика) Тогда

		ИнтерфейсОбработчика = "Процедура " + Конвертация["ИнтерфейсОбработчика" + ИмяОбработчика] + " Экспорт";

		ДобавитьВПотокПолныйОбработчик(Результат, ИнтерфейсОбработчика, АлгоритмОбработчика);

	КонецЕсли;

КонецПроцедуры  

// Добавляет в объект "Результат" процедуру с кодом обработчика или кодом алгоритма.
//
// Parameters:
//  Результат            - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода процедуры в текстовый файл.
//  ИнтерфейсОбработчика - Строка - полное описание интерфейса обработчика:
//                         имя процедуры, параметры процедуры, ключевое слово "Экспорт".
//  Обработчик           - Строка - тело обработчика или алгоритма.
//
Процедура ДобавитьВПотокПолныйОбработчик(Результат, ИнтерфейсОбработчика, Обработчик)

	СтрокаПрефикса = Символы.Таб;

	Результат.ЗаписатьСтроку("");

	Результат.ЗаписатьСтроку(ИнтерфейсОбработчика);

	Результат.ЗаписатьСтроку("");

	Для Индекс = 1 По СтрЧислоСтрок(Обработчик) Цикл

		СтрокаОбработчика = СтрПолучитьСтроку(Обработчик, Индекс);
		
		// В режиме отладки алгоритмов "Интеграция кода" вставляем код алгоритмов 
		// непосредственно в код обработчика. Код алгоритма вставляем взамен его вызова.
		// В коде алгоритмов уже учтена вложенность алгоритмов друг в друга.
		Если AlgorithmDebugMode = мРежимыОтладкиАлгоритмов.ИнтеграцияКода Тогда

			АлгоритмыОбработчика = ПолучитьАлгоритмыОбработчика(СтрокаОбработчика);

			Если АлгоритмыОбработчика.Количество() <> 0 Тогда // В этой строке есть вызовы алгоритмов.
				
				// Получаем начальное смещение кода алгоритма относительно текущего кода обработчика.
				СтрокаПрефиксаДляВложенногоКода = ПолучитьПрефиксДляВложенногоАлгоритма(СтрокаОбработчика,
					СтрокаПрефикса);

				Для Каждого Алгоритм Из АлгоритмыОбработчика Цикл

					ОбработчикАлгоритма = АлгоритмыИнтегрированные[Алгоритм];

					Для ИндексСтрокиАлгоритма = 1 По СтрЧислоСтрок(ОбработчикАлгоритма) Цикл

						Результат.ЗаписатьСтроку(СтрокаПрефиксаДляВложенногоКода + СтрПолучитьСтроку(
							ОбработчикАлгоритма, ИндексСтрокиАлгоритма));

					КонецЦикла;

				КонецЦикла;

			КонецЕсли;
		КонецЕсли;

		Результат.ЗаписатьСтроку(СтрокаПрефикса + СтрокаОбработчика);

	КонецЦикла;

	Результат.ЗаписатьСтроку("");
	Результат.ЗаписатьСтроку("КонецПроцедуры");

КонецПроцедуры

// Добавляет в объект "Результат" комментарий.
//
// Parameters:
//  Результат          - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода комментария в текстовый файл.
//  ИмяОбласти         - Строка - имя области текстового макета "мМакетОбщиеПроцедурыФункции"
//                       в которой содержится требуемый комментарий.
//  ВывестиКомментарий - Булево - признак необходимости вывода комментария.
//
Процедура ДобавитьВПотокКомментарий(Результат, ИмяОбласти, ВывестиКомментарий = Истина)

	Если Не ВывестиКомментарий Тогда
		Возврат;
	КонецЕсли; 
	
	// Получаем комментарии обработчиков по названию области.
	ТекущаяОбласть = мМакетОбщиеПроцедурыФункции.ПолучитьОбласть(ИмяОбласти + "_Комментарий");

	КомментарийИзМакета = СокрЛП(ПолучитьТекстПоОбластиБезНазванияОбласти(ТекущаяОбласть));
	
	// Исключаем последний перевод строки.
	КомментарийИзМакета = Сред(КомментарийИзМакета, 1, СтрДлина(КомментарийИзМакета));

	Результат.ЗаписатьСтроку(Символы.ПС + Символы.ПС + КомментарийИзМакета);

КонецПроцедуры  

// Добавляет в объект "Результат" служебный код: параметры, общие процедуры и функции, деструктор внешней обработки.
//
// Parameters:
//  Результат          - ЗаписьТекста - Объект типа ЗаписьТекста - для вывода служебного кода в текстовый файл.
//  ИмяОбласти         - Строка - имя области текстового макета "мМакетОбщиеПроцедурыФункции"
//                       в которой содержится требуемый служебный код.
//
Процедура ДобавитьВПотокСлужебныйКод(Результат, ИмяОбласти)
	
	// Получаем текст области
	ТекущаяОбласть = мМакетОбщиеПроцедурыФункции.ПолучитьОбласть(ИмяОбласти);

	Текст = СокрЛП(ПолучитьТекстПоОбластиБезНазванияОбласти(ТекущаяОбласть));

	Текст = Сред(Текст, 1, СтрДлина(Текст)); // Исключаем последний перевод строки.

	Результат.ЗаписатьСтроку(Символы.ПС + Символы.ПС + Текст);

КонецПроцедуры  

// Получает служебный код из указанной области макета "мМакетОбщиеПроцедурыФункции".
//
// Parameters:
//  ИмяОбласти - Строка - имя области текстового макета "мМакетОбщиеПроцедурыФункции".
//  
// Возвращаемое значение:
//  Текст из макета
//
Функция ПолучитьСлужебныйКод(ИмяОбласти)
	
	// Получаем текст области
	ТекущаяОбласть = мМакетОбщиеПроцедурыФункции.ПолучитьОбласть(ИмяОбласти);

	Возврат ПолучитьТекстПоОбластиБезНазванияОбласти(ТекущаяОбласть);
КонецФункции

#КонецОбласти

#Область ПроцедурыИФункцииПолученияПолногоКодаАлгоритмовСУчетомИхВложенности

// Формирует полный код алгоритмов с учетом их вложенности друг в друга.
//
// Parameters:
//  Нет.
//  
Процедура ПолучитьПолныйКодАлгоритмовСУчетомВложенности()
	
	// Заполняем структуру интегрированных алгоритмов.
	АлгоритмыИнтегрированные = Новый Структура;

	Для Каждого Алгоритм Из Алгоритмы Цикл

		АлгоритмыИнтегрированные.Вставить(Алгоритм.Ключ, ЗаменитьВызовыАлгоритмовКодомЭтихАлгоритмовВОбработчике(
			Алгоритм.Значение, Алгоритм.Ключ, Новый Массив));

	КонецЦикла;

КонецПроцедуры 

// Добавляет строку "ОбработчикНовый" комментарием к вставке кода очередного алгоритма.
//
// Parameters:
//  ОбработчикНовый - Строка - итоговая строка содержащая полный код алгоритма с учетом вложенности алгоритмов.
//  ИмяАлгоритма    - Строка - имя алгоритма.
//  СтрокаПрефикса  - строка - задает начальное смещение выводимого комментария.
//  Заголовок       - строка - наименование комментария: "{НАЧАЛО АЛГОРИТМА}", "{КОНЕЦ АЛГОРИТМА}"...
//
Процедура ЗаписатьЗаголовокБлокаАлгоритма(ОбработчикНовый, ИмяАлгоритма, СтрокаПрефикса, Заголовок)

	ЗаголовокАлгоритма = "//============================ " + Заголовок + " """ + ИмяАлгоритма
		+ """ ============================";

	ОбработчикНовый = ОбработчикНовый + Символы.ПС;
	ОбработчикНовый = ОбработчикНовый + Символы.ПС + СтрокаПрефикса + ЗаголовокАлгоритма;
	ОбработчикНовый = ОбработчикНовый + Символы.ПС;

КонецПроцедуры  

// Дополняет массив "АлгоритмыОбработчика" именами алгоритмов, которые вызываются 
// из переданной процедуре строки обработчика "СтрокаОбработчика".
//
// Parameters:
//  СтрокаОбработчика - Строка - строка обработчика или алгоритма в которой выполняется поиск вызовов алгоритмов.
//  АлгоритмыОбработчика - Массив- содержит имена алгоритмов, которые вызывается из заданного обработчика.
//  
Процедура ПолучитьАлгоритмыСтрокиОбработчика(СтрокаОбработчика, АлгоритмыОбработчика)

	СтрокаОбработчика = ВРег(СтрокаОбработчика);

	ШаблонПоиска = "АЛГОРИТМЫ.";

	ДлинаСтрокиШаблона = СтрДлина(ШаблонПоиска);

	СимволНачальный = СтрНайти(СтрокаОбработчика, ШаблонПоиска);

	Если СимволНачальный = 0 Тогда
		// В данной строке нет алгоритмов или все алгоритмы из этой строки уже учтены.
		Возврат;
	КонецЕсли;
	
	// Проверка на наличие признака того, что этот оператор закомментирован.
	СтрокаОбработчикаДоВызоваАлгоритма = Лев(СтрокаОбработчика, СимволНачальный);

	Если СтрНайти(СтрокаОбработчикаДоВызоваАлгоритма, "//") <> 0 Тогда 
		// Этот оператор и все последующие закомментированы.
		// Выходим из цикла.
		Возврат;
	КонецЕсли;

	СтрокаОбработчика = Сред(СтрокаОбработчика, СимволНачальный + ДлинаСтрокиШаблона);

	СимволКонечный = СтрНайти(СтрокаОбработчика, ")") - 1;

	ИмяАлгоритма = Сред(СтрокаОбработчика, 1, СимволКонечный);

	АлгоритмыОбработчика.Добавить(СокрЛП(ИмяАлгоритма));
	
	// Пробегаем строку обработчика до конца, 
	// пока все вызовы алгоритмов из этой строки не будут учтены.
	ПолучитьАлгоритмыСтрокиОбработчика(СтрокаОбработчика, АлгоритмыОбработчика);

КонецПроцедуры 

// Функция возвращает измененный код алгоритма с учетом вложенных алгоритмов. Вместо оператора вызова
// алгоритма "Выполнить(Алгоритмы.Алгоритм_1);" вставляется полный код вызываемого алгоритма 
// со сдвигом на величину "СтрокаПрефикса".
// Функция рекурсивно вызывает саму себя до тех по, пока все вложенные алгоритмы не будут учтены.
//
// Parameters:
//  Обработчик                 - Строка - исходный код алгоритма.
//  СтрокаПрефикса             - Строка - значение смещения вставляемого кода алгоритма.
//  АлгоритмВладелец           - Строка - имя алгоритма, являющегося родительским по отношению 
//                                        к алгоритму, код которого обрабатывается этой функцией.
//  МассивЗапрошенныхЭлементов - Массив - содержит имена алгоритмов которые уже были обработаны в данной ветке рекурсии.
//                                        Необходим для предотвращения бесконечной рекурсии функции
//                                        и вывода предупреждения об ошибке.
//  
// Возвращаемое значение:
//  ОбработчикНовый - Строка - измененный код алгоритма с учетом вложенных алгоритмов.
// 
Функция ЗаменитьВызовыАлгоритмовКодомЭтихАлгоритмовВОбработчике(Обработчик, АлгоритмВладелец,
	МассивЗапрошенныхЭлементов, Знач СтрокаПрефикса = "")

	МассивЗапрошенныхЭлементов.Добавить(ВРег(АлгоритмВладелец));
	
	// Инициализируем возвращаемое значение.
	ОбработчикНовый = "";

	ЗаписатьЗаголовокБлокаАлгоритма(ОбработчикНовый, АлгоритмВладелец, СтрокаПрефикса, НСтр(
		"ru = '{НАЧАЛО АЛГОРИТМА}'"));

	Для Индекс = 1 По СтрЧислоСтрок(Обработчик) Цикл

		СтрокаОбработчика = СтрПолучитьСтроку(Обработчик, Индекс);

		АлгоритмыОбработчика = ПолучитьАлгоритмыОбработчика(СтрокаОбработчика);

		Если АлгоритмыОбработчика.Количество() <> 0 Тогда // В этой строке есть вызовы алгоритмов.
			
			// Получаем начальное смещение кода алгоритма относительно текущего кода.
			СтрокаПрефиксаДляВложенногоКода = ПолучитьПрефиксДляВложенногоАлгоритма(СтрокаОбработчика, СтрокаПрефикса);
				
			// Разворачиваем полный код каждого алгоритма, 
			// который был вызван из строки "СтрокаОбработчика".
			Для Каждого Алгоритм Из АлгоритмыОбработчика Цикл

				Если МассивЗапрошенныхЭлементов.Найти(ВРег(Алгоритм)) <> Неопределено Тогда // Рекурсивный вызов алгоритма.

					ЗаписатьЗаголовокБлокаАлгоритма(ОбработчикНовый, Алгоритм, СтрокаПрефиксаДляВложенногоКода, НСтр(
						"ru = '{РЕКУРСИВНЫЙ ВЫЗОВ АЛГОРИТМА}'"));

					СтрокаОператора = НСтр("ru = 'ВызватьИсключение ""РЕКУРСИВНЫЙ ВЫЗОВ АЛГОРИТМА: %1"";'");
					СтрокаОператора = ПодставитьПараметрыВСтроку(СтрокаОператора, Алгоритм);

					ОбработчикНовый = ОбработчикНовый + Символы.ПС + СтрокаПрефиксаДляВложенногоКода + СтрокаОператора;

					ЗаписатьЗаголовокБлокаАлгоритма(ОбработчикНовый, Алгоритм, СтрокаПрефиксаДляВложенногоКода, НСтр(
						"ru = '{РЕКУРСИВНЫЙ ВЫЗОВ АЛГОРИТМА}'"));

					СтруктураЗаписи = Новый Структура;
					СтруктураЗаписи.Вставить("Алгоритм_1", АлгоритмВладелец);
					СтруктураЗаписи.Вставить("Алгоритм_2", Алгоритм);

					ЗаписатьВПротоколВыполнения(79, СтруктураЗаписи);

				Иначе

					ОбработчикНовый = ОбработчикНовый + ЗаменитьВызовыАлгоритмовКодомЭтихАлгоритмовВОбработчике(
						Алгоритмы[Алгоритм], Алгоритм, СкопироватьМассив(МассивЗапрошенныхЭлементов),
						СтрокаПрефиксаДляВложенногоКода);

				КонецЕсли;

			КонецЦикла;

		КонецЕсли;

		ОбработчикНовый = ОбработчикНовый + Символы.ПС + СтрокаПрефикса + СтрокаОбработчика;

	КонецЦикла;

	ЗаписатьЗаголовокБлокаАлгоритма(ОбработчикНовый, АлгоритмВладелец, СтрокаПрефикса, НСтр("ru = '{КОНЕЦ АЛГОРИТМА}'"));

	Возврат ОбработчикНовый;

КонецФункции

// Копирует переданный массив и возвращает новый массив.
//
// Parameters:
//  МассивИсточник - Массив - источник для получения нового массива копированием.
//  
// Возвращаемое значение:
//  НовыйМассив - Массив - массив, полученный копированием из переданного массива.
// 
Функция СкопироватьМассив(МассивИсточник)

	НовыйМассив = Новый Массив;

	Для Каждого ЭлементМассива Из МассивИсточник Цикл

		НовыйМассив.Добавить(ЭлементМассива);

	КонецЦикла;

	Возврат НовыйМассив;
КонецФункции 

// Возвращает массив с именами алгоритмов, которые были обнаружены в теле переданного обработчика.
//
// Parameters:
//  Обработчик - Строка - тело обработчика.
//  
// Возвращаемое значение:
//  АлгоритмыОбработчика - Массив - массив с именами алгоритмов, которые присутствуют в переданном обработчике.
//
Функция ПолучитьАлгоритмыОбработчика(Обработчик)
	
	// Инициализируем возвращаемое значение.
	АлгоритмыОбработчика = Новый Массив;

	Для Индекс = 1 По СтрЧислоСтрок(Обработчик) Цикл

		СтрокаОбработчика = СокрЛ(СтрПолучитьСтроку(Обработчик, Индекс));

		Если СтрНачинаетсяС(СтрокаОбработчика, "//") Тогда //Строка закомментирована, ее пропускаем.
			Продолжить;
		КонецЕсли;

		ПолучитьАлгоритмыСтрокиОбработчика(СтрокаОбработчика, АлгоритмыОбработчика);

	КонецЦикла;

	Возврат АлгоритмыОбработчика;
КонецФункции 

// Получает строку префикса для вывода кода вложенного алгоритма.
//
// Parameters:
//  СтрокаОбработчика - Строка - строка из которой извлекается значение смещения вызова
//                      (смещение при котором производится вызов алгоритма).
//  СтрокаПрефикса    - Строка - начальное смещение.
// Возвращаемое значение:
//  СтрокаПрефиксаДляВложенногоКода - Строка - Итоговое смещение кода алгоритма.
// 
Функция ПолучитьПрефиксДляВложенногоАлгоритма(СтрокаОбработчика, СтрокаПрефикса)

	СтрокаОбработчика = ВРег(СтрокаОбработчика);

	НомерПозицииШаблонаВыполнить = СтрНайти(СтрокаОбработчика, "ВЫПОЛНИТЬ");

	СтрокаПрефиксаДляВложенногоКода = СтрокаПрефикса + Лев(СтрокаОбработчика, НомерПозицииШаблонаВыполнить - 1)
		+ Символы.Таб;
	
	// Если в строке обработчика был вызов алгоритма (алгоритмов), то строку полностью удаляем из кода.
	СтрокаОбработчика = "";

	Возврат СтрокаПрефиксаДляВложенногоКода;
КонецФункции

#КонецОбласти

#Область ФункцииФормированияУникальногоИмениОбработчиковСобытий

// Формирует интерфейс обработчика ПКС, ПКГС (уникальное имя процедуры с параметрами соответствующего обработчика).
//
// Parameters:
//  ПКО            - СтрокаТаблицыЗначений - содержит правило конвертации объекта.
//  ПКГС           - СтрокаТаблицыЗначений - содержит правило конвертации группы свойств.
//  Правило        - СтрокаТаблицыЗначений - содержит правило конвертации свойств объекта.
//  ИмяОбработчика - Строка - имя обработчика события.
//
// Возвращаемое значение:
//  Строка - интерфейс обработчика.
//
Функция ПолучитьИнтерфейсОбработчикаПКС(ПКО, ПКГС, Правило, ИмяОбработчика)

	ПрефиксИмени = ?(Правило.ЭтоГруппа, "ПКГС", "ПКС");
	ИмяОбласти   = ПрефиксИмени + "_" + ИмяОбработчика;

	ИмяВладельца = "_" + СокрЛП(ПКО.Имя);

	ИмяРодителя  = "";

	Если ПКГС <> Неопределено Тогда

		Если Не ПустаяСтрока(ПКГС.ВидПриемника) Тогда

			ИмяРодителя = "_" + СокрЛП(ПКГС.Приемник);

		КонецЕсли;

	КонецЕсли;

	ИмяПриемника = "_" + СокрЛП(Правило.Приемник);
	ВидПриемника = "_" + СокрЛП(Правило.ВидПриемника);

	КодСвойства = СокрЛП(Правило.Имя);

	ПолноеИмяОбработчика = ИмяОбласти + ИмяВладельца + ИмяРодителя + ИмяПриемника + ВидПриемника + КодСвойства;

	Возврат ПолноеИмяОбработчика + "(" + ПолучитьПараметрыОбработчика(ИмяОбласти) + ")";
КонецФункции 

// Формирует интерфейс обработчика ПКО, ПВД, ПОД (уникальное имя процедуры с параметрами соответствующего обработчика).
//
// Parameters:
//  Правило            - СтрокаТаблицыЗначений - ПКО, ПВД, ПОД:
//    * Имя - Строка - имя правила.
//  ПрефиксОбработчика - Строка - принимает значения: "ПКО", "ПВД", "ПОД".
//  ИмяОбработчика     - Строка - имя обработчика события для данного правила.
//
// Возвращаемое значение:
//  Строка - интерфейс обработчика.
// 
Функция ПолучитьИнтерфейсОбработчика(Правило, ПрефиксОбработчика, ИмяОбработчика)

	ИмяОбласти = ПрефиксОбработчика + "_" + ИмяОбработчика;

	ИмяПравила = "_" + СокрЛП(Правило.Имя);

	ПолноеИмяОбработчика = ИмяОбласти + ИмяПравила;

	Возврат ПолноеИмяОбработчика + "(" + ПолучитьПараметрыОбработчика(ИмяОбласти) + ")";
КонецФункции 

// Формирует интерфейс глобального обработчика конвертации (уникальное имя процедуры с параметрами соответствующего
// обработчика).
//
// Parameters:
//  ИмяОбработчика - Строка - имя обработчика события конвертации.
//
// Возвращаемое значение:
//  Строка - интерфейс обработчика.
// 
Функция ПолучитьИнтерфейсОбработчикаКонвертация(ИмяОбработчика)

	ИмяОбласти = "Конвертация_" + ИмяОбработчика;

	ПолноеИмяОбработчика = ИмяОбласти;

	Возврат ПолноеИмяОбработчика + "(" + ПолучитьПараметрыОбработчика(ИмяОбласти) + ")";
КонецФункции 

// Формирует интерфейс процедуры (конструктора или деструктора) для внешней обработки.
//
// Parameters:
//  ИмяПроцедуры - Строка - имя процедуры.
//
// Возвращаемое значение:
//  Строка - интерфейс процедуры.
// 
Функция ПолучитьИнтерфейсПроцедурыВнешнейОбработки(ИмяПроцедуры)

	ИмяОбласти = "Обработка_" + ИмяПроцедуры;

	ПолноеИмяОбработчика = ИмяПроцедуры;

	Возврат ПолноеИмяОбработчика + "(" + ПолучитьПараметрыОбработчика(ИмяОбласти) + ")";
КонецФункции 

// Формирует интерфейс алгоритма для внешней обработки.
// Для всех алгоритмов получаем одинаковый набор параметров по умолчанию.
//
// Parameters:
//  ИмяАлгоритма - Строка - имя алгоритма.
//
// Возвращаемое значение:
//  Строка - интерфейс алгоритма.
// 
Функция ПолучитьИнтерфейсАлгоритма(ИмяАлгоритма)

	ПолноеИмяОбработчика = "Алгоритм_" + ИмяАлгоритма;

	ИмяОбласти = "Алгоритм_ПоУмолчанию";

	Возврат ПолноеИмяОбработчика + "(" + ПолучитьПараметрыОбработчика(ИмяОбласти) + ")";
КонецФункции

Функция ПолучитьСтрокуВызоваОбработчика(Правило, ИмяОбработчика)

	Возврат "ВнешняяОбработкаОбработчиковСобытий." + Правило["ИнтерфейсОбработчика" + ИмяОбработчика] + ";";

КонецФункции

Функция ПолучитьТекстПоОбластиБезНазванияОбласти(Область)

	ТекстОбласти = Область.ПолучитьТекст();

	Если СтрНайти(ТекстОбласти, "#Область") > 0 Тогда

		ПервыйПереводСтроки = СтрНайти(ТекстОбласти, Символы.ПС);

		ТекстОбласти = Сред(ТекстОбласти, ПервыйПереводСтроки + 1);

	КонецЕсли;

	Возврат ТекстОбласти;

КонецФункции

Функция ПолучитьПараметрыОбработчика(ИмяОбласти)

	СтрокаПеревода = Символы.ПС + "                                           ";

	ПараметрыОбработчика = "";

	ИтогоСтрока = "";

	Область = мМакетПараметровОбработчиков.ПолучитьОбласть(ИмяОбласти);

	ОбластьПараметров = Область.Области[ИмяОбласти];

	Для НомерСтроки = ОбластьПараметров.Верх По ОбластьПараметров.Низ Цикл

		ТекущаяОбласть = Область.ПолучитьОбласть(НомерСтроки, 2, НомерСтроки, 2);

		Параметр = СокрЛП(ТекущаяОбласть.ТекущаяОбласть.Текст);

		Если Не ПустаяСтрока(Параметр) Тогда

			ПараметрыОбработчика = ПараметрыОбработчика + Параметр + ", ";

			ИтогоСтрока = ИтогоСтрока + Параметр;

		КонецЕсли;

		Если СтрДлина(ИтогоСтрока) > 50 Тогда

			ИтогоСтрока = "";

			ПараметрыОбработчика = ПараметрыОбработчика + СтрокаПеревода;

		КонецЕсли;

	КонецЦикла;

	ПараметрыОбработчика = СокрЛП(ПараметрыОбработчика);
	
	// Убираем последний знак "," и возвращаем строку.

	Возврат Сред(ПараметрыОбработчика, 1, СтрДлина(ПараметрыОбработчика) - 1);
КонецФункции

#КонецОбласти

#Область ПроцедурыСозданияИнтерфейсаВызоваОбработчиковВПравилахОбмена

// Дополняет коллекцию значений правил очистки данных интерфейсами обработчиков.
//
// Parameters:
//  ТаблицаПОД   - ДеревоЗначений - содержит правила очистки данных.
//  СтрокиДерева - КоллекцияСтрокДереваЗначений - Объект типа КоллекцияСтрокДереваЗначений - содержит ПОД данного уровня
//                                                дерева значений.
//
Процедура ДополнитьИнтерфейсамиОбработчиковПравилаОчисткиДанных(ТаблицаПОД, СтрокиДерева)

	Для Каждого Правило Из СтрокиДерева Цикл

		Если Правило.ЭтоГруппа Тогда

			ДополнитьИнтерфейсамиОбработчиковПравилаОчисткиДанных(ТаблицаПОД, Правило.Строки);

		Иначе

			Для Каждого Элемент Из ИменаОбработчиков.ПОД Цикл

				ДобавитьИнтерфейсОбработчика(ТаблицаПОД, Правило, "ПОД", Элемент.Ключ);

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры  

// Дополняет коллекцию значений правил выгрузки данных интерфейсами обработчиков.
//
// Parameters:
//  ТаблицаПВД   - ДеревоЗначений - содержит правила выгрузки данных.
//  СтрокиДерева - КоллекцияСтрокДереваЗначений - Объект типа КоллекцияСтрокДереваЗначений - содержит ПВД данного уровня
//                                                дерева значений.
//
Процедура ДополнитьИнтерфейсамиОбработчиковПравилаВыгрузкиДанных(ТаблицаПВД, СтрокиДерева)

	Для Каждого Правило Из СтрокиДерева Цикл

		Если Правило.ЭтоГруппа Тогда

			ДополнитьИнтерфейсамиОбработчиковПравилаВыгрузкиДанных(ТаблицаПВД, Правило.Строки);

		Иначе

			Для Каждого Элемент Из ИменаОбработчиков.ПВД Цикл

				ДобавитьИнтерфейсОбработчика(ТаблицаПВД, Правило, "ПВД", Элемент.Ключ);

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры  

// Дополняет структуру конвертации интерфейсами обработчиков.
//
// Parameters:
//  СтруктураКонвертация - Структура - содержит правила конвертации и глобальные обработчики.
//  
Процедура ДополнитьИнтерфейсамиОбработчиковПравилаКонвертации(СтруктураКонвертация)

	Для Каждого Элемент Из ИменаОбработчиков.Конвертация Цикл

		ДобавитьИнтерфейсОбработчикаКонвертации(СтруктураКонвертация, Элемент.Ключ);

	КонецЦикла;

КонецПроцедуры  

// Дополняет коллекцию значений правил конвертации объектов интерфейсами обработчиков.
//
// Parameters:
//  ТаблицаПКО - см. КоллекцияПравилаКонвертации
//  
Процедура ДополнитьИнтерфейсамиОбработчиковПравилаКонвертацииОбъектов(ТаблицаПКО)

	Для Каждого ПКО Из ТаблицаПКО Цикл

		Для Каждого Элемент Из ИменаОбработчиков.ПКО Цикл

			ДобавитьИнтерфейсОбработчикаПКО(ТаблицаПКО, ПКО, Элемент.Ключ);

		КонецЦикла; 
		
		// Добавляем интерфейсы для ПКС.
		ДополнитьИнтерфейсамиОбработчиковПКС(ПКО, ПКО.СвойстваПоиска);
		ДополнитьИнтерфейсамиОбработчиковПКС(ПКО, ПКО.Свойства);

	КонецЦикла;

КонецПроцедуры

// Дополняет коллекцию значений правил конвертации свойств объектов интерфейсами обработчиков.
//
// Parameters:
//  ПКО - СтрокаТаблицыЗначений    - содержит правило конвертации объекта.
//  ПравилаКонвертацииСвойствОбъекта - ТаблицаЗначений - содержит правила конвертации свойств или группы свойств
//                                                       объекта из правила ПКО.
//  ПКГС - СтрокаТаблицыЗначений   - содержит правило конвертации группы свойств.
//
Процедура ДополнитьИнтерфейсамиОбработчиковПКС(ПКО, ПравилаКонвертацииСвойствОбъекта, ПКГС = Неопределено)

	Для Каждого ПКС Из ПравилаКонвертацииСвойствОбъекта Цикл

		Если ПКС.ЭтоГруппа Тогда // ПКГС

			Для Каждого Элемент Из ИменаОбработчиков.ПКГС Цикл

				ДобавитьИнтерфейсОбработчикаПКС(ПравилаКонвертацииСвойствОбъекта, ПКО, ПКГС, ПКС, Элемент.Ключ);

			КонецЦикла;

			ДополнитьИнтерфейсамиОбработчиковПКС(ПКО, ПКС.ПравилаГруппы, ПКС);

		Иначе

			Для Каждого Элемент Из ИменаОбработчиков.ПКС Цикл

				ДобавитьИнтерфейсОбработчикаПКС(ПравилаКонвертацииСвойствОбъекта, ПКО, ПКГС, ПКС, Элемент.Ключ);

			КонецЦикла;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Процедура ДобавитьИнтерфейсОбработчика(Таблица, Правило, ПрефиксОбработчика, ИмяОбработчика)

	Если ПустаяСтрока(Правило[ИмяОбработчика]) Тогда
		Возврат;
	КонецЕсли;

	ИмяПоля = "ИнтерфейсОбработчика" + ИмяОбработчика;

	ДобавитьНедостающиеКолонки(Таблица.Колонки, ИмяПоля);

	Правило[ИмяПоля] = ПолучитьИнтерфейсОбработчика(Правило, ПрефиксОбработчика, ИмяОбработчика);

КонецПроцедуры

Процедура ДобавитьИнтерфейсОбработчикаПКО(Таблица, Правило, ИмяОбработчика)

	Если Не Правило["ЕстьОбработчик" + ИмяОбработчика] Тогда
		Возврат;
	КонецЕсли;

	ИмяПоля = "ИнтерфейсОбработчика" + ИмяОбработчика;

	ДобавитьНедостающиеКолонки(Таблица.Колонки, ИмяПоля);

	Правило[ИмяПоля] = ПолучитьИнтерфейсОбработчика(Правило, "ПКО", ИмяОбработчика);

КонецПроцедуры

Процедура ДобавитьИнтерфейсОбработчикаПКС(Таблица, ПКО, ПКГС, ПКС, ИмяОбработчика)

	Если Не ПКС["ЕстьОбработчик" + ИмяОбработчика] Тогда
		Возврат;
	КонецЕсли;

	ИмяПоля = "ИнтерфейсОбработчика" + ИмяОбработчика;

	ДобавитьНедостающиеКолонки(Таблица.Колонки, ИмяПоля);

	ПКС[ИмяПоля] = ПолучитьИнтерфейсОбработчикаПКС(ПКО, ПКГС, ПКС, ИмяОбработчика);

КонецПроцедуры

Процедура ДобавитьИнтерфейсОбработчикаКонвертации(СтруктураКонвертация, ИмяОбработчика)

	АлгоритмОбработчика = "";

	Если СтруктураКонвертация.Свойство(ИмяОбработчика, АлгоритмОбработчика) И Не ПустаяСтрока(АлгоритмОбработчика) Тогда

		ИмяПоля = "ИнтерфейсОбработчика" + ИмяОбработчика;

		СтруктураКонвертация.Вставить(ИмяПоля);

		СтруктураКонвертация[ИмяПоля] = ПолучитьИнтерфейсОбработчикаКонвертация(ИмяОбработчика);

	КонецЕсли;

КонецПроцедуры

#КонецОбласти

#Область ПроцедурыРаботыСПравиламиОбмена

Функция ОпределитьПоВерсииПлатформыПриемникаПлатформу(ВерсияПлатформы)

	Если СтрНайти(ВерсияПлатформы, "8.") > 0 Тогда

		Возврат "V8";

	Иначе

		Возврат "V7";

	КонецЕсли;

КонецФункции

// Восстанавливает правила из внутреннего формата.
//
// Parameters:
// 
Процедура ВосстановитьПравилаИзВнутреннегоФормата() Экспорт

	Если SavedSettings = Неопределено Тогда
		Возврат;
	КонецЕсли;

	СтруктураПравил = SavedSettings.Получить(); // см. RulesStructureDetails

	ExportRulesTable      = СтруктураПравил.ExportRulesTable;
	ConversionRulesTable   = СтруктураПравил.ConversionRulesTable;
	Алгоритмы                  = СтруктураПравил.Алгоритмы;
	ЗапросыДляВосстановления   = СтруктураПравил.Запросы;
	Конвертация                = СтруктураПравил.Конвертация;
	mXMLRules                = СтруктураПравил.mXMLRules;
	ParametersSettingsTable = СтруктураПравил.ParametersSettingsTable;
	Parameters                  = СтруктураПравил.Parameters;

	ДополнитьСлужебныеТаблицыКолонками();

	СтруктураПравил.Свойство("ВерсияПлатформыПриемника", ВерсияПлатформыПриемника);

	ПлатформаПриемника = ОпределитьПоВерсииПлатформыПриемникаПлатформу(ВерсияПлатформыПриемника);

	ЕстьГлобальныйОбработчикПередВыгрузкойОбъекта    = Не ПустаяСтрока(Конвертация.ПередВыгрузкойОбъекта);
	ЕстьГлобальныйОбработчикПослеВыгрузкиОбъекта     = Не ПустаяСтрока(Конвертация.ПослеВыгрузкиОбъекта);
	ЕстьГлобальныйОбработчикПередЗагрузкойОбъекта    = Не ПустаяСтрока(Конвертация.ПередЗагрузкойОбъекта);
	ЕстьГлобальныйОбработчикПослеЗагрузкиОбъекта     = Не ПустаяСтрока(Конвертация.ПослеЗагрузкиОбъекта);
	ЕстьГлобальныйОбработчикПередКонвертациейОбъекта = Не ПустаяСтрока(Конвертация.ПередКонвертациейОбъекта);

	// Восстанавливаем запросы
	Запросы.Очистить();
	Для Каждого ЭлементСтруктуры Из ЗапросыДляВосстановления Цикл
		Запрос = Новый Запрос(ЭлементСтруктуры.Значение);
		Запросы.Вставить(ЭлементСтруктуры.Ключ, Запрос);
	КонецЦикла;

	ИнициализироватьМенеджерыИСообщения();

	Правила.Очистить();
	ОчиститьПКОМенеджеров();

	Если ExchangeMode = "Выгрузка" Тогда

		Для Каждого СтрокаТаблицы Из КоллекцияПравилаКонвертации() Цикл
			Правила.Вставить(СтрокаТаблицы.Имя, СтрокаТаблицы);

			Источник = СтрокаТаблицы.Источник;

			Если Источник <> Неопределено Тогда

				Попытка
					Если ТипЗнч(Источник) = одТипСтрока Тогда
						Менеджеры[Тип(Источник)].ПКО = СтрокаТаблицы;
					Иначе
						Менеджеры[Источник].ПКО = СтрокаТаблицы;
					КонецЕсли;
				Исключение
					ЗаписатьИнформациюОбОшибкеВПротокол(11, ОписаниеОшибки(), Строка(Источник));
				КонецПопытки;

			КонецЕсли;

		КонецЦикла;

	КонецЕсли;

КонецПроцедуры

// Выполняет инициализацию параметров значениями по умолчанию, из правил обмена.
//
// Parameters:
//  Нет.
// 
Процедура ИнициализироватьПервоначальныеЗначенияПараметров() Экспорт

	Для Каждого ТекПараметр Из Parameters Цикл

		УстановитьЗначениеПараметраВТаблице(ТекПараметр.Ключ, ТекПараметр.Значение);

	КонецЦикла;

КонецПроцедуры

#КонецОбласти

#Область ОбработкаПравилОчистки

Процедура ВыполнитьУдалениеОбъекта(Объект, Свойства, УдалитьНепосредственно)

	ИмяТипа = Свойства.ИмяТипа;

	Если ИмяТипа = "РегистрСведений" Тогда

		Объект.Удалить();

	Иначе

		Если (ИмяТипа = "Справочник" Или ИмяТипа = "ПланВидовХарактеристик" Или ИмяТипа = "ПланСчетов" Или ИмяТипа
			= "ПланВидовРасчета") И Объект.Предопределенный Тогда

			Возврат;

		КонецЕсли;

		Если УдалитьНепосредственно Тогда

			Объект.Удалить();

		Иначе

			УстановитьПометкуУдаленияУОбъекта(Объект, Истина, Свойства.ИмяТипа);

		КонецЕсли;

	КонецЕсли;

КонецПроцедуры

// Очищает данные по указанному правилу.
//
// Parameters:
//   Правило - СтрокаТаблицыЗначений - ссылка на правило очистки данных:
//     * Имя - Строка - имя правила.
// 
Процедура ОчиститьДанныеПоПравилу(Правило)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;
	
	// Обработчик ПередОбработкой

	Отказ			= Ложь;
	ВыборкаДанных	= Неопределено;

	ИсходящиеДанные	= Неопределено;


	// Обработчик ПередОбработкойПравилаОчистки
	Если Не ПустаяСтрока(Правило.ПередОбработкой) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПередОбработкой"));

			Иначе

				Выполнить (Правило.ПередОбработкой);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикаОчисткиДанных(27, ОписаниеОшибки(), Правило.Имя, "",
				"ПередОбработкойПравилаОчистки");

		КонецПопытки;

		Если Отказ Тогда

			Возврат;

		КонецЕсли;

	КонецЕсли;
	
	// Стандартная выборка

	Свойства = Менеджеры[Правило.ОбъектВыборки];

	Если Правило.СпособОтбораДанных = "СтандартнаяВыборка" Тогда

		ИмяТипа = Свойства.ИмяТипа;

		Если ИмяТипа = "РегистрБухгалтерии" Или ИмяТипа = "Константы" Тогда

			Возврат;

		КонецЕсли;

		НужныВсеПоля  = Не ПустаяСтрока(Правило.ПередУдалением);

		Выборка = ПолучитьВыборкуДляВыгрузкиОчисткиДанных(Свойства, ИмяТипа, Истина, Правило.Непосредственно,
			НужныВсеПоля);

		Пока Выборка.Следующий() Цикл

			Если ИмяТипа = "РегистрСведений" Тогда

				МенеджерЗаписи = Свойства.Менеджер.СоздатьМенеджерЗаписи();
				ЗаполнитьЗначенияСвойств(МенеджерЗаписи, Выборка);

				УдалениеОбъектаВыборки(МенеджерЗаписи, Правило, Свойства, ИсходящиеДанные);

			Иначе

				УдалениеОбъектаВыборки(Выборка.Ссылка.ПолучитьОбъект(), Правило, Свойства, ИсходящиеДанные);

			КонецЕсли;

		КонецЦикла;

	ИначеЕсли Правило.СпособОтбораДанных = "ПроизвольныйАлгоритм" Тогда

		Если ВыборкаДанных <> Неопределено Тогда

			Выборка = ПолучитьВыборкуДляВыгрузкиПоПроизвольномуАлгоритму(ВыборкаДанных);

			Если Выборка <> Неопределено Тогда

				Пока Выборка.Следующий() Цикл

					Если ИмяТипа = "РегистрСведений" Тогда

						МенеджерЗаписи = Свойства.Менеджер.СоздатьМенеджерЗаписи();
						ЗаполнитьЗначенияСвойств(МенеджерЗаписи, Выборка);

						УдалениеОбъектаВыборки(МенеджерЗаписи, Правило, Свойства, ИсходящиеДанные);

					Иначе

						УдалениеОбъектаВыборки(Выборка.Ссылка.ПолучитьОбъект(), Правило, Свойства, ИсходящиеДанные);

					КонецЕсли;

				КонецЦикла;

			Иначе

				Для Каждого Объект Из ВыборкаДанных Цикл

					УдалениеОбъектаВыборки(Объект.ПолучитьОбъект(), Правило, Свойства, ИсходящиеДанные);

				КонецЦикла;

			КонецЕсли;

		КонецЕсли;

	КонецЕсли; 

	
	// Обработчик ПослеОбработкиПравилаОчистки

	Если Не ПустаяСтрока(Правило.ПослеОбработки) Тогда

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(Правило, "ПослеОбработки"));

			Иначе

				Выполнить (Правило.ПослеОбработки);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеОбработчикаОчисткиДанных(28, ОписаниеОшибки(), Правило.Имя, "",
				"ПослеОбработкиПравилаОчистки");

		КонецПопытки;

	КонецЕсли;

КонецПроцедуры

// Обходит дерево правил очистки данных и выполняет очистку.
//
// Параметры:
//  Строки         - Коллекция строк дерева значений.
// 
Процедура ОбработатьПравилаОчистки(Строки)

	Для Каждого ПравилоОчистки Из Строки Цикл

		Если ПравилоОчистки.Включить = 0 Тогда

			Продолжить;

		КонецЕсли;

		Если ПравилоОчистки.ЭтоГруппа Тогда

			ОбработатьПравилаОчистки(ПравилоОчистки.Строки);
			Продолжить;

		КонецЕсли;

		ОчиститьДанныеПоПравилу(ПравилоОчистки);

	КонецЦикла;

КонецПроцедуры

#КонецОбласти

#Область ПроцедурыЗагрузкиДанных

// Устанавливает значение параметра "Загрузка" для свойства объекта "ОбменДанными".
//
// Параметры:
//  Объект   - объект, для которого устанавливается свойство.
//  Значение - значение устанавливаемого свойства "Загрузка".
// 
Процедура УстановитьОбменДаннымиЗагрузка(Объект, Значение = Истина) Экспорт

	Если Не ImportDataInExchangeMode Тогда
		Возврат;
	КонецЕсли;

	Если ЕстьРеквизитИлиСвойствоОбъекта(Объект, "ОбменДанными") Тогда
		СтруктураДляЗаполнения = Новый Структура("Загрузка", Значение);
		ЗаполнитьЗначенияСвойств(Объект.ОбменДанными, СтруктураДляЗаполнения);
	КонецЕсли;

КонецПроцедуры

Функция УстановитьСсылкуНового(Объект, Менеджер, СвойстваПоиска)

	УИ = СвойстваПоиска["{УникальныйИдентификатор}"];

	Если УИ <> Неопределено Тогда

		НоваяСсылка = Менеджер.ПолучитьСсылку(Новый УникальныйИдентификатор(УИ));

		Объект.УстановитьСсылкуНового(НоваяСсылка);

		СвойстваПоиска.Удалить("{УникальныйИдентификатор}");

	Иначе

		НоваяСсылка = Неопределено;

	КонецЕсли;

	Возврат НоваяСсылка;

КонецФункции

// Ищет объект по номеру в списке уже загруженных объектов.
//
// Параметры:
//  НПП          - номер искомого объекта в файле обмена.
//
// Возвращаемое значение:
//  Ссылка на найденный объект. Если объект не найден, возвращается Неопределено.
// 
Функция НайтиОбъектПоНомеру(НПП, РежимПоискаОсновногоОбъекта = Ложь)

	Если НПП = 0 Тогда
		Возврат Неопределено;
	КонецЕсли;

	СтруктураРезультата = ЗагруженныеОбъекты[НПП];

	Если СтруктураРезультата = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если РежимПоискаОсновногоОбъекта И СтруктураРезультата.СсылкаФиктивная Тогда
		Возврат Неопределено;
	Иначе
		Возврат СтруктураРезультата.СсылкаНаОбъект;
	КонецЕсли;

КонецФункции

Функция НайтиОбъектПоГлобальномуНомеру(НПП, РежимПоискаОсновногоОбъекта = Ложь)

	СтруктураРезультата = ЗагруженныеГлобальныеОбъекты[НПП];

	Если СтруктураРезультата = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если РежимПоискаОсновногоОбъекта И СтруктураРезультата.СсылкаФиктивная Тогда
		Возврат Неопределено;
	Иначе
		Возврат СтруктураРезультата.СсылкаНаОбъект;
	КонецЕсли;

КонецФункции

Процедура ЗаписатьОбъектВИБ(Объект, Тип)

	Попытка

		УстановитьОбменДаннымиЗагрузка(Объект);
		Объект.Записать();

	Исключение

		СтрокаСообщенияОбОшибке = ЗаписатьИнформациюОбОшибкеВПротокол(26, ОписаниеОшибки(), Объект, Тип);

		Если Не DebugModeFlag Тогда
			ВызватьИсключение СтрокаСообщенияОбОшибке;
		КонецЕсли;

	КонецПопытки;

КонецПроцедуры

// Создает новый объект указанного типа, устанавливает реквизиты, указанные
// в структуре СвойстваПоиска.
//
// Параметры:
//  Тип            - тип создаваемого объекта.
//  СвойстваПоиска - Структура, содержащая устанавливаемые реквизиты нового объекта.
//
// Возвращаемое значение:
//  Новый объект информационной базы.
// 
Функция СоздатьНовыйОбъект(Тип, СвойстваПоиска, Объект = Неопределено, ЗаписыватьОбъектСразуПослеСоздания = Истина,
	НаборЗаписейРегистра = Неопределено, НоваяСсылка = Неопределено, НПП = 0, ГНПП = 0, ПараметрыОбъекта = Неопределено,
	УстанавливатьУОбъектаВсеСвойстваПоиска = Истина)

	СвойстваМД      = Менеджеры[Тип];
	ИмяТипа         = СвойстваМД.ИмяТипа;
	Менеджер        = СвойстваМД.Менеджер; // СправочникМенеджер, ДокументМенеджер, РегистрСведенийМенеджер, и т.п.

	Если ИмяТипа = "Справочник" Или ИмяТипа = "ПланВидовХарактеристик" Тогда

		ЭтоГруппа = СвойстваПоиска["ЭтоГруппа"];

		Если ЭтоГруппа = Истина Тогда

			Объект = Менеджер.СоздатьГруппу();

		Иначе

			Объект = Менеджер.СоздатьЭлемент();

		КонецЕсли;

	ИначеЕсли ИмяТипа = "Документ" Тогда

		Объект = Менеджер.СоздатьДокумент();

	ИначеЕсли ИмяТипа = "ПланСчетов" Тогда

		Объект = Менеджер.СоздатьСчет();

	ИначеЕсли ИмяТипа = "ПланВидовРасчета" Тогда

		Объект = Менеджер.СоздатьВидРасчета();

	ИначеЕсли ИмяТипа = "РегистрСведений" Тогда

		Если WriteRegistersAsRecordSets Тогда

			НаборЗаписейРегистра = Менеджер.СоздатьНаборЗаписей();
			Объект = НаборЗаписейРегистра.Добавить();

		Иначе

			Объект = Менеджер.СоздатьМенеджерЗаписи();

		КонецЕсли;

		Возврат Объект;

	ИначеЕсли ИмяТипа = "ПланОбмена" Тогда

		Объект = Менеджер.СоздатьУзел();

	ИначеЕсли ИмяТипа = "Задача" Тогда

		Объект = Менеджер.СоздатьЗадачу();

	ИначеЕсли ИмяТипа = "БизнесПроцесс" Тогда

		Объект = Менеджер.СоздатьБизнесПроцесс();

	ИначеЕсли ИмяТипа = "Перечисление" Тогда

		Объект = СвойстваМД.ПустаяСсылка;
		Возврат Объект;

	ИначеЕсли ИмяТипа = "ТочкаМаршрутаБизнесПроцесса" Тогда

		Возврат Неопределено;

	КонецЕсли;

	НоваяСсылка = УстановитьСсылкуНового(Объект, Менеджер, СвойстваПоиска);

	Если УстанавливатьУОбъектаВсеСвойстваПоиска Тогда
		УстановитьРеквизитыПоискаУОбъекта(Объект, СвойстваПоиска, Неопределено, Ложь, Ложь);
	КонецЕсли;
	
	// Проверки
	Если ИмяТипа = "Документ" Или ИмяТипа = "Задача" Или ИмяТипа = "БизнесПроцесс" Тогда

		Если Не ЗначениеЗаполнено(Объект.Дата) Тогда

			Объект.Дата = ТекущаяДатаСеанса();

		КонецЕсли;

	КонецЕсли;
		
	// Если Владелец не установлен, то нужно поле добавить
	// в возможные поля поиска, а в событии ПОЛЯПОИСКА указать поля без Владельца, если по нему поиск реально не нужен.

	Если ЗаписыватьОбъектСразуПослеСоздания Тогда

		Если Не ImportReferencedObjectsWithoutDeletionMark Тогда
			Объект.ПометкаУдаления = Истина;
		КонецЕсли;

		Если ГНПП <> 0 Или Не OptimizedObjectsWriting Тогда

			ЗаписатьОбъектВИБ(Объект, Тип);

		Иначе
			
			// Записывать объект сразу не будем, а только запомним что нужно записать
			// сохраним эту информацию в специальном стеке объектов для записи
			// вернем и новую ссылку и сам объект, хотя он еще не записан.
			Если НоваяСсылка = Неопределено Тогда
				
				// Самостоятельно генерируем новую ссылку.
				НовыйУникальныйИдентификатор = Новый УникальныйИдентификатор;
				НоваяСсылка = Менеджер.ПолучитьСсылку(НовыйУникальныйИдентификатор);
				Объект.УстановитьСсылкуНового(НоваяСсылка);

			КонецЕсли;

			ДополнитьСтекНеЗаписанныхОбъектов(НПП, ГНПП, Объект, НоваяСсылка, Тип, ПараметрыОбъекта);

			Возврат НоваяСсылка;

		КонецЕсли;

	Иначе

		Возврат Неопределено;

	КонецЕсли;

	Возврат Объект.Ссылка;

КонецФункции

// Читает из файла узел свойства объекта, устанавливает значение свойства.
//
// Параметры:
//  Тип            - тип значения свойства.
//  ОбъектНайден   - если после выполнения функции - Ложь, то значит
//                   объект свойства не найден в информационной базе и создан новый.
//
// Возвращаемое значение:
//  Значение свойства
// 
Функция ПрочитатьСвойство(Тип, ИмяПКО = "")

	Значение = Неопределено;
	НаличиеСвойств = Ложь;

	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Значение" Тогда

			ИскатьПоСвойству = одАтрибут(ФайлОбмена, одТипСтрока, "Свойство");
			Значение         = одЗначениеЭлемента(ФайлОбмена, Тип, ИскатьПоСвойству, RemoveTrailingSpaces);
			НаличиеСвойств = Истина;

		ИначеЕсли ИмяУзла = "Ссылка" Тогда

			Значение       = НайтиОбъектПоСсылке(Тип, ИмяПКО);
			НаличиеСвойств = Истина;

		ИначеЕсли ИмяУзла = "Нпп" Тогда

			одПропустить(ФайлОбмена);

		ИначеЕсли ИмяУзла = "ГНпп" Тогда

			ФайлОбмена.Прочитать();
			ГНПП = Число(ФайлОбмена.Значение);
			Если ГНПП <> 0 Тогда
				Значение  = НайтиОбъектПоГлобальномуНомеру(ГНПП);
				НаличиеСвойств = Истина;
			КонецЕсли;

			ФайлОбмена.Прочитать();

		ИначеЕсли (ИмяУзла = "Свойство" Или ИмяУзла = "ЗначениеПараметра") И (ФайлОбмена.ТипУзла
			= одТипУзлаXML_КонецЭлемента) Тогда

			Если Не НаличиеСвойств И ЗначениеЗаполнено(Тип) Тогда
				
				// Если вообще ничего нет - значит пустое значение.
				Значение = одПолучитьПустоеЗначение(Тип);

			КонецЕсли;

			Прервать;

		ИначеЕсли ИмяУзла = "Выражение" Тогда

			Выражение = одЗначениеЭлемента(ФайлОбмена, одТипСтрока, , Ложь);
			Значение  = ВычислитьВыражение(Выражение);

			НаличиеСвойств = Истина;

		ИначеЕсли ИмяУзла = "Пусто" Тогда

			Значение = одПолучитьПустоеЗначение(Тип);
			НаличиеСвойств = Истина;

		Иначе

			ЗаписатьВПротоколВыполнения(9);
			Прервать;

		КонецЕсли;

	КонецЦикла;

	Возврат Значение;

КонецФункции

Функция УстановитьРеквизитыПоискаУОбъекта(НайденныйОбъект, СвойстваПоиска, СвойстваПоискаНеЗамещать,
	НужноСравниватьСТекущимиРеквизитами = Истина, НЕЗаменятьСвойстваНеПодлежащиеИзменению = Истина)

	ИзмененыРеквизитыОбъекта = Ложь;

	Для Каждого Свойство Из СвойстваПоиска Цикл

		Имя      = Свойство.Ключ;
		Значение = Свойство.Значение;

		Если НЕЗаменятьСвойстваНеПодлежащиеИзменению И СвойстваПоискаНеЗамещать[Имя] <> Неопределено Тогда

			Продолжить;

		КонецЕсли;

		Если Имя = "ЭтоГруппа" Или Имя = "{УникальныйИдентификатор}" Или Имя = "{ИмяПредопределенногоЭлемента}" Тогда

			Продолжить;

		ИначеЕсли Имя = "ПометкаУдаления" Тогда

			Если Не НужноСравниватьСТекущимиРеквизитами Или НайденныйОбъект.ПометкаУдаления <> Значение Тогда

				НайденныйОбъект.ПометкаУдаления = Значение;
				ИзмененыРеквизитыОбъекта = Истина;

			КонецЕсли;

		Иначе
				
			// Отличные реквизиты устанавливаем.
			Если НайденныйОбъект[Имя] <> Null Тогда

				Если Не НужноСравниватьСТекущимиРеквизитами Или НайденныйОбъект[Имя] <> Значение Тогда

					НайденныйОбъект[Имя] = Значение;
					ИзмененыРеквизитыОбъекта = Истина;

				КонецЕсли;

			КонецЕсли;

		КонецЕсли;

	КонецЦикла;

	Возврат ИзмененыРеквизитыОбъекта;

КонецФункции

Функция НайтиИлиСоздатьОбъектПоСвойству(СтруктураСвойств, ТипОбъекта, СвойстваПоиска, СвойстваПоискаНеЗамещать,
	ИмяТипаОбъекта, СвойствоПоиска, ЗначениеСвойстваПоиска, ОбъектНайден, СоздаватьНовыйЭлементЕслиНеНайден,
	НайденныйИлиСозданныйОбъект, РежимПоискаОсновногоОбъекта, СвойстваОбъектаМодифицированы, НПП, ГНПП,
	ПараметрыОбъекта, НоваяСсылкаУникальногоИдентификатора = Неопределено)

	ЭтоПеречисление = СтруктураСвойств.ИмяТипа = "Перечисление";

	Если ЭтоПеречисление Тогда

		СтрокаПоиска = "";

	Иначе

		СтрокаПоиска = СтруктураСвойств.СтрокаПоиска;

	КонецЕсли;

	Если РежимПоискаОсновногоОбъекта Или ПустаяСтрока(СтрокаПоиска) Тогда
		СтрокаЗапросаПоискаПоУникальномуИдентификатору = "";
	КонецЕсли;

	Объект = НайтиОбъектПоСвойству(СтруктураСвойств.Менеджер, СвойствоПоиска, ЗначениеСвойстваПоиска,
		НайденныйИлиСозданныйОбъект, , , СтрокаЗапросаПоискаПоУникальномуИдентификатору);

	ОбъектНайден = Не (Объект = Неопределено Или Объект.Пустая());

	Если Не ОбъектНайден Тогда
		Если СоздаватьНовыйЭлементЕслиНеНайден Тогда

			Объект = СоздатьНовыйОбъект(ТипОбъекта, СвойстваПоиска, НайденныйИлиСозданныйОбъект,
				Не РежимПоискаОсновногоОбъекта, , НоваяСсылкаУникальногоИдентификатора, НПП, ГНПП, ПараметрыОбъекта);

			СвойстваОбъектаМодифицированы = Истина;
		КонецЕсли;
		Возврат Объект;

	КонецЕсли;

	Если ЭтоПеречисление Тогда
		Возврат Объект;
	КонецЕсли;

	Если РежимПоискаОсновногоОбъекта Тогда

		Если НайденныйИлиСозданныйОбъект = Неопределено Тогда
			НайденныйИлиСозданныйОбъект = Объект.ПолучитьОбъект();
		КонецЕсли;

		СвойстваОбъектаМодифицированы = УстановитьРеквизитыПоискаУОбъекта(НайденныйИлиСозданныйОбъект, СвойстваПоиска,
			СвойстваПоискаНеЗамещать);

	КонецЕсли;

	Возврат Объект;

КонецФункции

Функция ПолучитьТипСвойства()

	СтроковыйТипСвойства = одАтрибут(ФайлОбмена, одТипСтрока, "Тип");
	Если ПустаяСтрока(СтроковыйТипСвойства) Тогда
		Возврат Неопределено;
	КонецЕсли;

	Возврат Тип(СтроковыйТипСвойства);

КонецФункции

Функция ПолучитьТипСвойстваПоДополнительнымДанным(ИнформацияОТипах, ИмяСвойства)

	ТипСвойства = ПолучитьТипСвойства();

	Если ТипСвойства = Неопределено И ИнформацияОТипах <> Неопределено Тогда

		ТипСвойства = ИнформацияОТипах[ИмяСвойства];

	КонецЕсли;

	Возврат ТипСвойства;

КонецФункции

Процедура ПрочитатьСвойстваПоискаИзФайла(СвойстваПоиска, СвойстваПоискаНеЗамещать, ИнформацияОТипах,
	ПоискПоДатеНаРавенство = Ложь, ПараметрыОбъекта = Неопределено)

	ПоискПоДатеНаРавенство = Ложь;

	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Свойство" Или ИмяУзла = "ЗначениеПараметра" Тогда

			ЭтоПараметр = (ИмяУзла = "ЗначениеПараметра");

			Имя = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");

			Если Имя = "{УникальныйИдентификатор}" Или Имя = "{ИмяПредопределенногоЭлемента}" Тогда

				ТипСвойства = одТипСтрока;

			Иначе

				ТипСвойства = ПолучитьТипСвойстваПоДополнительнымДанным(ИнформацияОТипах, Имя);

			КонецЕсли;

			НеЗамещатьСвойство = одАтрибут(ФайлОбмена, одТипБулево, "НеЗамещать");
			ПоискПоДатеНаРавенство = ПоискПоДатеНаРавенство Или одАтрибут(ФайлОбмена, одТипБулево,
				"ПоискПоДатеНаРавенство");
			//
			ИмяПКО = одАтрибут(ФайлОбмена, одТипСтрока, "ИмяПКО");

			ЗначениеСвойства = ПрочитатьСвойство(ТипСвойства, ИмяПКО);

			Если (Имя = "ЭтоГруппа") И (ЗначениеСвойства <> Истина) Тогда

				ЗначениеСвойства = Ложь;

			КонецЕсли;

			Если ЭтоПараметр Тогда
				ДобавитьПараметрПриНеобходимости(ПараметрыОбъекта, Имя, ЗначениеСвойства);

			Иначе

				СвойстваПоиска[Имя] = ЗначениеСвойства;

				Если НеЗамещатьСвойство Тогда

					СвойстваПоискаНеЗамещать[Имя] = Истина;

				КонецЕсли;

			КонецЕсли;

		ИначеЕсли (ИмяУзла = "Ссылка") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		Иначе

			ЗаписатьВПротоколВыполнения(9);
			Прервать;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

Функция ОпределитьУПоляНеограниченнаяДлина(МенеджерТипа, ИмяПараметра)

	ДлинныеСтроки = Неопределено;
	Если Не МенеджерТипа.Свойство("ДлинныеСтроки", ДлинныеСтроки) Тогда

		ДлинныеСтроки = Новый Соответствие;
		Для Каждого Реквизит Из МенеджерТипа.ОбъектМД.Реквизиты Цикл

			Если Реквизит.Тип.СодержитТип(одТипСтрока) И (Реквизит.Тип.КвалификаторыСтроки.Длина = 0) Тогда

				ДлинныеСтроки.Вставить(Реквизит.Имя, Реквизит.Имя);

			КонецЕсли;

		КонецЦикла;

		МенеджерТипа.Вставить("ДлинныеСтроки", ДлинныеСтроки);

	КонецЕсли;

	Возврат (ДлинныеСтроки[ИмяПараметра] <> Неопределено);

КонецФункции

Функция ОпределитьЭтотПараметрНеограниченнойДлинны(МенеджерТипа, ЗначениеПараметра, ИмяПараметра)

	Попытка

		Если ТипЗнч(ЗначениеПараметра) = одТипСтрока Тогда
			СтрокаНеограниченнойДлины = ОпределитьУПоляНеограниченнаяДлина(МенеджерТипа, ИмяПараметра);
		Иначе
			СтрокаНеограниченнойДлины = Ложь;
		КонецЕсли;

	Исключение

		СтрокаНеограниченнойДлины = Ложь;

	КонецПопытки;

	Возврат СтрокаНеограниченнойДлины;

КонецФункции

Функция НайтиЭлементЗапросом(СтруктураСвойств, СвойстваПоиска, ТипОбъекта = Неопределено, МенеджерТипа = Неопределено,
	КоличествоРеальныхСвойствДляПоиска = Неопределено)

	КоличествоСвойствДляПоиска = ?(КоличествоРеальныхСвойствДляПоиска = Неопределено, СвойстваПоиска.Количество(),
		КоличествоРеальныхСвойствДляПоиска);

	Если КоличествоСвойствДляПоиска = 0 И СтруктураСвойств.ИмяТипа = "Перечисление" Тогда

		Возврат СтруктураСвойств.ПустаяСсылка;

	КонецЕсли;

	ТекстЗапроса       = СтруктураСвойств.СтрокаПоиска;

	Если ПустаяСтрока(ТекстЗапроса) Тогда
		Возврат СтруктураСвойств.ПустаяСсылка;
	КонецЕсли;

	ЗапросПоиска       = Новый Запрос;
	КоличествоСвойствПоКоторымУстановленПоиск = 0;

	Для Каждого Свойство Из СвойстваПоиска Цикл

		ИмяПараметра      = Свойство.Ключ;
		
		// Не по всем параметрам можно искать.
		Если ИмяПараметра = "{УникальныйИдентификатор}" Или ИмяПараметра = "{ИмяПредопределенногоЭлемента}" Тогда

			Продолжить;

		КонецЕсли;

		ЗначениеПараметра = Свойство.Значение;
		ЗапросПоиска.УстановитьПараметр(ИмяПараметра, ЗначениеПараметра);

		Попытка

			СтрокаНеограниченнойДлины = ОпределитьЭтотПараметрНеограниченнойДлинны(СтруктураСвойств, ЗначениеПараметра,
				ИмяПараметра);

		Исключение

			СтрокаНеограниченнойДлины = Ложь;

		КонецПопытки;

		КоличествоСвойствПоКоторымУстановленПоиск = КоличествоСвойствПоКоторымУстановленПоиск + 1;

		Если СтрокаНеограниченнойДлины Тогда

			ТекстЗапроса = ТекстЗапроса + ?(КоличествоСвойствПоКоторымУстановленПоиск > 1, " И ", "") + ИмяПараметра
				+ " ПОДОБНО &" + ИмяПараметра;

		Иначе

			ТекстЗапроса = ТекстЗапроса + ?(КоличествоСвойствПоКоторымУстановленПоиск > 1, " И ", "") + ИмяПараметра
				+ " = &" + ИмяПараметра;

		КонецЕсли;

	КонецЦикла;

	Если КоличествоСвойствПоКоторымУстановленПоиск = 0 Тогда
		Возврат Неопределено;
	КонецЕсли;

	ЗапросПоиска.Текст = ТекстЗапроса;
	Результат = ЗапросПоиска.Выполнить();

	Если Результат.Пустой() Тогда

		Возврат Неопределено;

	Иначе
		
		// Возвращаем первый найденный объект.
		Выборка = Результат.Выбрать();
		Выборка.Следующий();
		СсылкаНаОбъект = Выборка.Ссылка;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция ОпределитьПоТипуОбъектаИспользоватьДополнительныйПоискПоПолямПоиска(ТипСсылкиСтрокой)

	ЗначениеСоответствия = мСоответствиеДопПараметровПоиска.Получить(ТипСсылкиСтрокой);

	Если ЗначениеСоответствия <> Неопределено Тогда
		Возврат ЗначениеСоответствия;
	КонецЕсли;

	Попытка

		Для Каждого Элемент Из Правила Цикл

			Если Элемент.Значение.Приемник = ТипСсылкиСтрокой Тогда

				Если Элемент.Значение.СинхронизироватьПоИдентификатору = Истина Тогда

					НужноПродолжитьПоиск = (Элемент.Значение.ПродолжитьПоискПоПолямПоискаЕслиПоИдентификаторуНеНашли
						= Истина);
					мСоответствиеДопПараметровПоиска.Вставить(ТипСсылкиСтрокой, НужноПродолжитьПоиск);

					Возврат НужноПродолжитьПоиск;

				КонецЕсли;

			КонецЕсли;

		КонецЦикла;

		мСоответствиеДопПараметровПоиска.Вставить(ТипСсылкиСтрокой, Ложь);
		Возврат Ложь;

	Исключение

		мСоответствиеДопПараметровПоиска.Вставить(ТипСсылкиСтрокой, Ложь);
		Возврат Ложь;

	КонецПопытки;

КонецФункции

// Определяет по типу объекта приемника правило конвертации объекта (ПКО).
//
// Параметры:
//  ТипСсылкиСтрокой - Строка - тип объекта в строковом представлении, например, "СправочникСсылка.Номенклатура".
// 
// Возвращаемое значение:
//  ЗначениеСоответствия = Правило конвертации объекта.
// 
Функция ОпределитьПоТипуОбъектаПриемникаПравилоКонвертацииКотороеСодержитАлгоритмПоиска(ТипСсылкиСтрокой)

	ЗначениеСоответствия = мСоответствиеПравилКонвертации.Получить(ТипСсылкиСтрокой);

	Если ЗначениеСоответствия <> Неопределено Тогда
		Возврат ЗначениеСоответствия;
	КонецЕсли;

	Попытка

		Для Каждого Элемент Из Правила Цикл

			Если Элемент.Значение.Приемник = ТипСсылкиСтрокой Тогда

				Если Элемент.Значение.ЕстьОбработчикПоследовательностьПолейПоиска = Истина Тогда

					Правило = Элемент.Значение;

					мСоответствиеПравилКонвертации.Вставить(ТипСсылкиСтрокой, Правило);

					Возврат Правило;

				КонецЕсли;

			КонецЕсли;

		КонецЦикла;

		мСоответствиеПравилКонвертации.Вставить(ТипСсылкиСтрокой, Неопределено);
		Возврат Неопределено;

	Исключение

		мСоответствиеПравилКонвертации.Вставить(ТипСсылкиСтрокой, Неопределено);
		Возврат Неопределено;

	КонецПопытки;

КонецФункции

Функция НайтиСсылкуНаОбъектПоОдномуСвойству(СвойстваПоиска, СтруктураСвойств)

	Для Каждого Свойство Из СвойстваПоиска Цикл

		ИмяПараметра      = Свойство.Ключ;
					
		// Не по всем параметрам можно искать.
		Если ИмяПараметра = "{УникальныйИдентификатор}" Или ИмяПараметра = "{ИмяПредопределенногоЭлемента}" Тогда

			Продолжить;

		КонецЕсли;

		ЗначениеПараметра = Свойство.Значение;
		СсылкаНаОбъект = НайтиОбъектПоСвойству(СтруктураСвойств.Менеджер, ИмяПараметра, ЗначениеПараметра,
			Неопределено, СтруктураСвойств, СвойстваПоиска);

	КонецЦикла;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция НайтиСсылкуНаДокумент(СвойстваПоиска, СтруктураСвойств, КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом,
	ПоискПоДатеНаРавенство)
	
	// Попробуем документ по дате и номеру найти.
	ИскатьЗапросом = ПоискПоДатеНаРавенство Или (КоличествоРеальныхСвойствДляПоиска <> 2);

	Если ИскатьЗапросом Тогда
		Возврат Неопределено;
	КонецЕсли;

	НомерДокумента = СвойстваПоиска["Номер"];
	ДатаДокумента  = СвойстваПоиска["Дата"];

	Если (НомерДокумента <> Неопределено) И (ДатаДокумента <> Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНомеру(НомерДокумента, ДатаДокумента);

	Иначе
						
		// По дате и номеру найти не удалось - надо искать запросом.
		ИскатьЗапросом = Истина;
		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция НайтиСсылкуНаСправочник(СвойстваПоиска, СтруктураСвойств, КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом)

	Владелец     = СвойстваПоиска["Владелец"];
	Родитель     = СвойстваПоиска["Родитель"];
	Код          = СвойстваПоиска["Код"];
	Наименование = СвойстваПоиска["Наименование"];

	Кол          = 0;

	Если Владелец <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли;
	Если Родитель <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли;
	Если Код <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли;
	Если Наименование <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли;

	ИскатьЗапросом = (Кол <> КоличествоРеальныхСвойствДляПоиска);

	Если ИскатьЗапросом Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если (Код <> Неопределено) И (Наименование = Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоКоду(Код, , Родитель, Владелец);

	ИначеЕсли (Код = Неопределено) И (Наименование <> Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНаименованию(Наименование, Истина, Родитель, Владелец);

	Иначе

		ИскатьЗапросом = Истина;
		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция НайтиСсылкуНаПВХ(СвойстваПоиска, СтруктураСвойств, КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом)

	Родитель     = СвойстваПоиска["Родитель"];
	Код          = СвойстваПоиска["Код"];
	Наименование = СвойстваПоиска["Наименование"];
	Кол          = 0;

	Если Родитель <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;
	Если Код <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;
	Если Наименование <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;

	ИскатьЗапросом = (Кол <> КоличествоРеальныхСвойствДляПоиска);

	Если ИскатьЗапросом Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если (Код <> Неопределено) И (Наименование = Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоКоду(Код, Родитель);

	ИначеЕсли (Код = Неопределено) И (Наименование <> Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНаименованию(Наименование, Истина, Родитель);

	Иначе

		ИскатьЗапросом = Истина;
		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция НайтиСсылкуНаПланОбмена(СвойстваПоиска, СтруктураСвойств, КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом)

	Код          = СвойстваПоиска["Код"];
	Наименование = СвойстваПоиска["Наименование"];
	Кол          = 0;

	Если Код <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;
	Если Наименование <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;

	ИскатьЗапросом = (Кол <> КоличествоРеальныхСвойствДляПоиска);

	Если ИскатьЗапросом Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если (Код <> Неопределено) И (Наименование = Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоКоду(Код);

	ИначеЕсли (Код = Неопределено) И (Наименование <> Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНаименованию(Наименование, Истина);

	Иначе

		ИскатьЗапросом = Истина;
		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция НайтиСсылкуНаЗадачу(СвойстваПоиска, СтруктураСвойств, КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом)

	Код          = СвойстваПоиска["Номер"];
	Наименование = СвойстваПоиска["Наименование"];
	Кол          = 0;

	Если Код <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;
	Если Наименование <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;

	ИскатьЗапросом = (Кол <> КоличествоРеальныхСвойствДляПоиска);

	Если ИскатьЗапросом Тогда
		Возврат Неопределено;
	КонецЕсли;
	Если (Код <> Неопределено) И (Наименование = Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНомеру(Код);

	ИначеЕсли (Код = Неопределено) И (Наименование <> Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНаименованию(Наименование, Истина);

	Иначе

		ИскатьЗапросом = Истина;
		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Функция НайтиСсылкуНаБизнесПроцесс(СвойстваПоиска, СтруктураСвойств, КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом)

	Код          = СвойстваПоиска["Номер"];
	Кол          = 0;

	Если Код <> Неопределено Тогда
		Кол = 1 + Кол;
	КонецЕсли
	;

	ИскатьЗапросом = (Кол <> КоличествоРеальныхСвойствДляПоиска);

	Если ИскатьЗапросом Тогда
		Возврат Неопределено;
	КонецЕсли;

	Если (Код <> Неопределено) Тогда

		СсылкаНаОбъект = СтруктураСвойств.Менеджер.НайтиПоНомеру(Код);

	Иначе

		ИскатьЗапросом = Истина;
		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Процедура ДобавитьСсылкуВСписокЗагруженныхОбъектов(ГНППСсылки, НППСсылки, СсылкаНаОбъект, СсылкаФиктивная = Ложь)
	
	// Запоминаем ссылку на объект.
	Если Не ЗапоминатьЗагруженныеОбъекты Или СсылкаНаОбъект = Неопределено Тогда

		Возврат;

	КонецЕсли;

	СтруктураЗаписи = Новый Структура("СсылкаНаОбъект, СсылкаФиктивная", СсылкаНаОбъект, СсылкаФиктивная);
	
	// Запоминаем ссылку на объект.
	Если ГНППСсылки <> 0 Тогда

		ЗагруженныеГлобальныеОбъекты[ГНППСсылки] = СтруктураЗаписи;

	ИначеЕсли НППСсылки <> 0 Тогда

		ЗагруженныеОбъекты[НППСсылки] = СтруктураЗаписи;

	КонецЕсли;

КонецПроцедуры

Функция НайтиЭлементПоСвойствамПоиска(ТипОбъекта, ИмяТипаОбъекта, СвойстваПоиска, СтруктураСвойств,
	СтрокаИменСвойствПоиска, ПоискПоДатеНаРавенство)
	
	// Не нужно искать по имени предопределенного элемента и по уникальной ссылке на объект
	// нужно искать только по тем свойствам, которые имеются в строке имен свойств. Если там пусто, то по
	// всем имеющимся свойствам поиска.

	ИскатьЗапросом = Ложь;

	Если ПустаяСтрока(СтрокаИменСвойствПоиска) Тогда

		ВременныеСвойстваПоиска = СвойстваПоиска;

	Иначе

		ГотоваяСтрокаДляРазбора = СтрЗаменить(СтрокаИменСвойствПоиска, " ", "");
		ДлинаСтроки = СтрДлина(ГотоваяСтрокаДляРазбора);
		Если Сред(ГотоваяСтрокаДляРазбора, ДлинаСтроки, 1) <> "," Тогда

			ГотоваяСтрокаДляРазбора = ГотоваяСтрокаДляРазбора + ",";

		КонецЕсли;

		ВременныеСвойстваПоиска = Новый Соответствие;
		Для Каждого ЭлементСвойств Из СвойстваПоиска Цикл

			ИмяПараметра = ЭлементСвойств.Ключ;
			Если СтрНайти(ГотоваяСтрокаДляРазбора, ИмяПараметра + ",") > 0 Тогда

				ВременныеСвойстваПоиска.Вставить(ИмяПараметра, ЭлементСвойств.Значение);

			КонецЕсли;

		КонецЦикла;

	КонецЕсли;

	СвойствоУникальныйИдентификатор = ВременныеСвойстваПоиска["{УникальныйИдентификатор}"];
	СвойствоИмяПредопределенного = ВременныеСвойстваПоиска["{ИмяПредопределенногоЭлемента}"];

	КоличествоРеальныхСвойствДляПоиска = ВременныеСвойстваПоиска.Количество();
	КоличествоРеальныхСвойствДляПоиска = КоличествоРеальныхСвойствДляПоиска - ?(СвойствоУникальныйИдентификатор
		<> Неопределено, 1, 0);
	КоличествоРеальныхСвойствДляПоиска = КоличествоРеальныхСвойствДляПоиска - ?(СвойствоИмяПредопределенного
		<> Неопределено, 1, 0);
	Если КоличествоРеальныхСвойствДляПоиска = 1 Тогда

		СсылкаНаОбъект = НайтиСсылкуНаОбъектПоОдномуСвойству(ВременныеСвойстваПоиска, СтруктураСвойств);

	ИначеЕсли ИмяТипаОбъекта = "Документ" Тогда

		СсылкаНаОбъект = НайтиСсылкуНаДокумент(ВременныеСвойстваПоиска, СтруктураСвойств,
			КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом, ПоискПоДатеНаРавенство);

	ИначеЕсли ИмяТипаОбъекта = "Справочник" Тогда

		СсылкаНаОбъект = НайтиСсылкуНаСправочник(ВременныеСвойстваПоиска, СтруктураСвойств,
			КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом);

	ИначеЕсли ИмяТипаОбъекта = "ПланВидовХарактеристик" Тогда

		СсылкаНаОбъект = НайтиСсылкуНаПВХ(ВременныеСвойстваПоиска, СтруктураСвойств,
			КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом);

	ИначеЕсли ИмяТипаОбъекта = "ПланОбмена" Тогда

		СсылкаНаОбъект = НайтиСсылкуНаПланОбмена(ВременныеСвойстваПоиска, СтруктураСвойств,
			КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом);

	ИначеЕсли ИмяТипаОбъекта = "Задача" Тогда

		СсылкаНаОбъект = НайтиСсылкуНаЗадачу(ВременныеСвойстваПоиска, СтруктураСвойств,
			КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом);

	ИначеЕсли ИмяТипаОбъекта = "БизнесПроцесс" Тогда

		СсылкаНаОбъект = НайтиСсылкуНаБизнесПроцесс(ВременныеСвойстваПоиска, СтруктураСвойств,
			КоличествоРеальныхСвойствДляПоиска, ИскатьЗапросом);

	Иначе

		ИскатьЗапросом = Истина;

	КонецЕсли;

	Если ИскатьЗапросом Тогда

		СсылкаНаОбъект = НайтиЭлементЗапросом(СтруктураСвойств, ВременныеСвойстваПоиска, ТипОбъекта, ,
			КоличествоРеальныхСвойствДляПоиска);

	КонецЕсли;

	Возврат СсылкаНаОбъект;

КонецФункции

Процедура ОбработатьУстановкуСвойствПоискаУОбъекта(УстанавливатьУОбъектаВсеСвойстваПоиска, ТипОбъекта, СвойстваПоиска,
	СвойстваПоискаНеЗамещать, СсылкаНаОбъект, СозданныйОбъект, ЗаписыватьНовыйОбъектВИнформационнуюБазу = Истина,
	ИзмененыРеквизитыОбъекта = Ложь)

	Если УстанавливатьУОбъектаВсеСвойстваПоиска <> Истина Тогда
		Возврат;
	КонецЕсли;

	Если Не ЗначениеЗаполнено(СсылкаНаОбъект) Тогда
		Возврат;
	КонецЕсли;

	Если СозданныйОбъект = Неопределено Тогда
		СозданныйОбъект = СсылкаНаОбъект.ПолучитьОбъект();
	КонецЕсли;

	ИзмененыРеквизитыОбъекта = УстановитьРеквизитыПоискаУОбъекта(СозданныйОбъект, СвойстваПоиска,
		СвойстваПоискаНеЗамещать);
	
	// Если было то что изменено, тогда перезаписываем объект.
	Если ИзмененыРеквизитыОбъекта И ЗаписыватьНовыйОбъектВИнформационнуюБазу Тогда

		ЗаписатьОбъектВИБ(СозданныйОбъект, ТипОбъекта);

	КонецЕсли;

КонецПроцедуры

Функция ОбработатьПоискОбъектаПоСтруктуре(НомерОбъекта, ТипОбъекта, СозданныйОбъект, РежимПоискаОсновногоОбъекта,
	СвойстваОбъектаМодифицированы, ОбъектНайден, ЭтоГлобальныйНомер, ПараметрыОбъекта)

	СтруктураДанных = мГлобальныйСтекНеЗаписанныхОбъектов[НомерОбъекта];

	Если СтруктураДанных <> Неопределено Тогда

		СвойстваОбъектаМодифицированы = Истина;
		СозданныйОбъект = СтруктураДанных.Объект;

		Если СтруктураДанных.ИзвестнаяСсылка = Неопределено Тогда

			УстановитьСсылкуДляОбъекта(СтруктураДанных);

		КонецЕсли;

		СсылкаНаОбъект = СтруктураДанных.ИзвестнаяСсылка;
		ПараметрыОбъекта = СтруктураДанных.ПараметрыОбъекта;

		ОбъектНайден = Ложь;

	Иначе

		СозданныйОбъект = Неопределено;

		Если ЭтоГлобальныйНомер Тогда
			СсылкаНаОбъект = НайтиОбъектПоГлобальномуНомеру(НомерОбъекта, РежимПоискаОсновногоОбъекта);
		Иначе
			СсылкаНаОбъект = НайтиОбъектПоНомеру(НомерОбъекта, РежимПоискаОсновногоОбъекта);
		КонецЕсли;

	КонецЕсли;

	Если СсылкаНаОбъект <> Неопределено Тогда

		Если РежимПоискаОсновногоОбъекта Тогда

			СвойстваПоиска = "";
			СвойстваПоискаНеЗамещать = "";
			ПрочитатьИнформациюОСвойствахПоиска(ТипОбъекта, СвойстваПоиска, СвойстваПоискаНеЗамещать, ,
				ПараметрыОбъекта);
			
			// Для основного поиска нужно поля поиска еще раз проверить, возможно нужно их переустановить...
			Если СозданныйОбъект = Неопределено Тогда

				СозданныйОбъект = СсылкаНаОбъект.ПолучитьОбъект();

			КонецЕсли;

			СвойстваОбъектаМодифицированы = УстановитьРеквизитыПоискаУОбъекта(СозданныйОбъект, СвойстваПоиска,
				СвойстваПоискаНеЗамещать);

		Иначе

			одПропустить(ФайлОбмена);

		КонецЕсли;

		Возврат СсылкаНаОбъект;

	КонецЕсли;

	Возврат Неопределено;

КонецФункции

Процедура ПрочитатьИнформациюОСвойствахПоиска(ТипОбъекта, СвойстваПоиска, СвойстваПоискаНеЗамещать,
	ПоискПоДатеНаРавенство = Ложь, ПараметрыОбъекта = Неопределено)

	Если СвойстваПоиска = "" Тогда
		СвойстваПоиска = Новый Соответствие;
	КонецЕсли;

	Если СвойстваПоискаНеЗамещать = "" Тогда
		СвойстваПоискаНеЗамещать = Новый Соответствие;
	КонецЕсли;

	ИнформацияОТипах = мСоответствиеТиповДанныхДляЗагрузки[ТипОбъекта];
	ПрочитатьСвойстваПоискаИзФайла(СвойстваПоиска, СвойстваПоискаНеЗамещать, ИнформацияОТипах, ПоискПоДатеНаРавенство,
		ПараметрыОбъекта);

КонецПроцедуры

// Производит поиск объекта в информационной базе, если не найден создает новый.
//
// Параметры:
//  ТипОбъекта     - тип искомого объекта.
//  СвойстваПоиска - структура, содержащая свойства по которым производится поиск объекта.
//  ОбъектНайден   - если Ложь, то объект не найден, а создан новый.
//
// Возвращаемое значение:
//  Новый или найденный объект информационной базы.
//  
Функция НайтиОбъектПоСсылке(ТипОбъекта, ИмяПКО = "", СвойстваПоиска = "", СвойстваПоискаНеЗамещать = "",
	ОбъектНайден = Истина, СозданныйОбъект = Неопределено, НеСоздаватьОбъектЕслиНеНайден = Неопределено,
	РежимПоискаОсновногоОбъекта = Ложь, СвойстваОбъектаМодифицированы = Ложь, НППГлобальнойСсылки = 0, НППСсылки = 0,
	ИзвестнаяСсылкаУникальногоИдентификатора = Неопределено, ПараметрыОбъекта = Неопределено)

	Если SafeMode Тогда
		УстановитьБезопасныйРежим(Истина);
		Для Каждого ИмяРазделителя Из РазделителиКонфигурации Цикл
			УстановитьБезопасныйРежимРазделенияДанных(ИмяРазделителя, Истина);
		КонецЦикла;
	КонецЕсли;

	ПоискПоДатеНаРавенство = Ложь;
	СсылкаНаОбъект = Неопределено;
	СтруктураСвойств = Неопределено;
	ИмяТипаОбъекта = Неопределено;
	СсылкаНаОбъектФиктивная = Ложь;
	ПКО = Неопределено;
	АлгоритмПоиска = "";

	Если ЗапоминатьЗагруженныеОбъекты Тогда
		
		// Есть номер по порядку из файла - по нему и ищем.
		НППГлобальнойСсылки = одАтрибут(ФайлОбмена, одТипЧисло, "ГНпп");

		Если НППГлобальнойСсылки <> 0 Тогда

			СсылкаНаОбъект = ОбработатьПоискОбъектаПоСтруктуре(НППГлобальнойСсылки, ТипОбъекта, СозданныйОбъект,
				РежимПоискаОсновногоОбъекта, СвойстваОбъектаМодифицированы, ОбъектНайден, Истина, ПараметрыОбъекта);

			Если СсылкаНаОбъект <> Неопределено Тогда
				Возврат СсылкаНаОбъект;
			КонецЕсли;

		КонецЕсли;
		
		// Есть номер по порядку из файла - по нему и ищем.
		НППСсылки = одАтрибут(ФайлОбмена, одТипЧисло, "Нпп");

		Если НППСсылки <> 0 Тогда

			СсылкаНаОбъект = ОбработатьПоискОбъектаПоСтруктуре(НППСсылки, ТипОбъекта, СозданныйОбъект,
				РежимПоискаОсновногоОбъекта, СвойстваОбъектаМодифицированы, ОбъектНайден, Ложь, ПараметрыОбъекта);

			Если СсылкаНаОбъект <> Неопределено Тогда
				Возврат СсылкаНаОбъект;
			КонецЕсли;

		КонецЕсли;

	КонецЕсли;

	НеСоздаватьОбъектЕслиНеНайден = одАтрибут(ФайлОбмена, одТипБулево, "НеСоздаватьЕслиНеНайден");
	ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD = Не РежимПоискаОсновногоОбъекта И одАтрибут(ФайлОбмена,
		одТипБулево, "ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD");
	
	// Создаем свойства поиска объектов.
	ПрочитатьИнформациюОСвойствахПоиска(ТипОбъекта, СвойстваПоиска, СвойстваПоискаНеЗамещать, ПоискПоДатеНаРавенство,
		ПараметрыОбъекта);

	СозданныйОбъект = Неопределено;

	Если Не ОбъектНайден Тогда

		СсылкаНаОбъект = СоздатьНовыйОбъект(ТипОбъекта, СвойстваПоиска, СозданныйОбъект, , , , НППСсылки,
			НППГлобальнойСсылки);
		ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, СсылкаНаОбъект);
		Возврат СсылкаНаОбъект;

	КонецЕсли;

	СтруктураСвойств   = Менеджеры[ТипОбъекта];
	ИмяТипаОбъекта     = СтруктураСвойств.ИмяТипа;

	СвойствоУникальныйИдентификатор = СвойстваПоиска["{УникальныйИдентификатор}"];
	СвойствоИмяПредопределенного = СвойстваПоиска["{ИмяПредопределенногоЭлемента}"];

	ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD = ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD
		И СвойствоУникальныйИдентификатор <> Неопределено;
		
	// Если это предопределенный элемент ищем по имени.
	Если СвойствоИмяПредопределенного <> Неопределено Тогда

		АвтоматическиСоздаватьНовыйОбъект = Не НеСоздаватьОбъектЕслиНеНайден
			И Не ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD;

		СсылкаНаОбъект = НайтиИлиСоздатьОбъектПоСвойству(СтруктураСвойств, ТипОбъекта, СвойстваПоиска,
			СвойстваПоискаНеЗамещать, ИмяТипаОбъекта, "{ИмяПредопределенногоЭлемента}", СвойствоИмяПредопределенного,
			ОбъектНайден, АвтоматическиСоздаватьНовыйОбъект, СозданныйОбъект, РежимПоискаОсновногоОбъекта,
			СвойстваОбъектаМодифицированы, НППСсылки, НППГлобальнойСсылки, ПараметрыОбъекта);

	ИначеЕсли (СвойствоУникальныйИдентификатор <> Неопределено) Тогда
			
		// Не всегда нужно по уникальному идентификатору новый элемент создавать, возможно нужно продолжить поиск.
		НужноПродолжитьПоискЕслиЭлементПоGUIDНеНайден = ОпределитьПоТипуОбъектаИспользоватьДополнительныйПоискПоПолямПоиска(
			СтруктураСвойств.ТипСсылкиСтрокой);

		АвтоматическиСоздаватьНовыйОбъект = (Не НеСоздаватьОбъектЕслиНеНайден
			И Не НужноПродолжитьПоискЕслиЭлементПоGUIDНеНайден) И Не ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD;

		СсылкаНаОбъект = НайтиИлиСоздатьОбъектПоСвойству(СтруктураСвойств, ТипОбъекта, СвойстваПоиска,
			СвойстваПоискаНеЗамещать, ИмяТипаОбъекта, "{УникальныйИдентификатор}", СвойствоУникальныйИдентификатор,
			ОбъектНайден, АвтоматическиСоздаватьНовыйОбъект, СозданныйОбъект, РежимПоискаОсновногоОбъекта,
			СвойстваОбъектаМодифицированы, НППСсылки, НППГлобальнойСсылки, ПараметрыОбъекта,
			ИзвестнаяСсылкаУникальногоИдентификатора);

		Если Не НужноПродолжитьПоискЕслиЭлементПоGUIDНеНайден Тогда

			Если Не ЗначениеЗаполнено(СсылкаНаОбъект) И ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD Тогда

				СсылкаНаОбъект = СтруктураСвойств.Менеджер.ПолучитьСсылку(
					Новый УникальныйИдентификатор(СвойствоУникальныйИдентификатор));
				ОбъектНайден = Ложь;
				СсылкаНаОбъектФиктивная = Истина;

			КонецЕсли;

			Если СсылкаНаОбъект <> Неопределено И СсылкаНаОбъект.Пустая() Тогда

				СсылкаНаОбъект = Неопределено;

			КонецЕсли;

			Если СсылкаНаОбъект <> Неопределено Или СозданныйОбъект <> Неопределено Тогда

				ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, СсылкаНаОбъект,
					СсылкаНаОбъектФиктивная);

			КонецЕсли;

			Возврат СсылкаНаОбъект;

		КонецЕсли;

	КонецЕсли;

	Если СсылкаНаОбъект <> Неопределено И СсылкаНаОбъект.Пустая() Тогда

		СсылкаНаОбъект = Неопределено;

	КонецЕсли;
		
	// СсылкаНаОбъект пока не найден.
	Если СсылкаНаОбъект <> Неопределено Или СозданныйОбъект <> Неопределено Тогда

		ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, СсылкаНаОбъект);
		Возврат СсылкаНаОбъект;

	КонецЕсли;

	НомерВариантаПоиска = 1;
	СтрокаИменСвойствПоиска = "";
	ПредыдущаяСтрокаПоиска = Неопределено;
	ПрекратитьПоиск = Ложь;
	УстанавливатьУОбъектаВсеСвойстваПоиска = Истина;

	Если Не ПустаяСтрока(ИмяПКО) Тогда

		ПКО = Правила[ИмяПКО];

	КонецЕсли;

	Если ПКО = Неопределено Тогда

		ПКО = ОпределитьПоТипуОбъектаПриемникаПравилоКонвертацииКотороеСодержитАлгоритмПоиска(
			СтруктураСвойств.ТипСсылкиСтрокой);

	КонецЕсли;

	Если ПКО <> Неопределено Тогда

		АлгоритмПоиска = ПКО.ПоследовательностьПолейПоиска;

	КонецЕсли;

	ЕстьАлгоритмПоиска = Не ПустаяСтрока(АлгоритмПоиска);

	Пока НомерВариантаПоиска <= 10 И ЕстьАлгоритмПоиска Цикл

		Попытка

			Если HandlersDebugModeFlag Тогда

				Выполнить (ПолучитьСтрокуВызоваОбработчика(ПКО, "ПоследовательностьПолейПоиска"));

			Иначе

				Выполнить (АлгоритмПоиска);

			КонецЕсли;

		Исключение

			ЗаписатьИнформациюОбОшибкеЗагрузкиОбработчикаПКО(73, ОписаниеОшибки(), "", "", ТипОбъекта, Неопределено,
				НСтр("ru = 'Последовательность полей поиска'"));

		КонецПопытки;

		НеНужноВыполнятьПоиск = ПрекратитьПоиск = Истина Или СтрокаИменСвойствПоиска = ПредыдущаяСтрокаПоиска
			Или ЗначениеЗаполнено(СсылкаНаОбъект);

		Если Не НеНужноВыполнятьПоиск Тогда
		
			// сам поиск непосредственно
			СсылкаНаОбъект = НайтиЭлементПоСвойствамПоиска(ТипОбъекта, ИмяТипаОбъекта, СвойстваПоиска, СтруктураСвойств,
				СтрокаИменСвойствПоиска, ПоискПоДатеНаРавенство);

			НеНужноВыполнятьПоиск = ЗначениеЗаполнено(СсылкаНаОбъект);

			Если СсылкаНаОбъект <> Неопределено И СсылкаНаОбъект.Пустая() Тогда
				СсылкаНаОбъект = Неопределено;
			КонецЕсли;

		КонецЕсли;

		Если НеНужноВыполнятьПоиск Тогда

			Если РежимПоискаОсновногоОбъекта И УстанавливатьУОбъектаВсеСвойстваПоиска = Истина Тогда

				ОбработатьУстановкуСвойствПоискаУОбъекта(УстанавливатьУОбъектаВсеСвойстваПоиска, ТипОбъекта,
					СвойстваПоиска, СвойстваПоискаНеЗамещать, СсылкаНаОбъект, СозданныйОбъект,
					Не РежимПоискаОсновногоОбъекта, СвойстваОбъектаМодифицированы);

			КонецЕсли;

			Прервать;

		КонецЕсли;

		НомерВариантаПоиска = НомерВариантаПоиска + 1;
		ПредыдущаяСтрокаПоиска = СтрокаИменСвойствПоиска;

	КонецЦикла;

	Если Не ЕстьАлгоритмПоиска Тогда
		
		// Сам поиск непосредственно и без алгоритма поиска.
		СсылкаНаОбъект = НайтиЭлементПоСвойствамПоиска(ТипОбъекта, ИмяТипаОбъекта, СвойстваПоиска, СтруктураСвойств,
			СтрокаИменСвойствПоиска, ПоискПоДатеНаРавенство);

	КонецЕсли;

	ОбъектНайден = ЗначениеЗаполнено(СсылкаНаОбъект);

	Если РежимПоискаОсновногоОбъекта И ЗначениеЗаполнено(СсылкаНаОбъект) И (ИмяТипаОбъекта = "Документ"
		Или ИмяТипаОбъекта = "Задача" Или ИмяТипаОбъекта = "БизнесПроцесс") Тогда
		
		// Если у документа дата есть в свойствах поиска - то устанавливаем ее.
		ДатаПустая = Не ЗначениеЗаполнено(СвойстваПоиска["Дата"]);
		МожноЗамещать = (Не ДатаПустая) И (СвойстваПоискаНеЗамещать["Дата"] = Неопределено);

		Если МожноЗамещать Тогда

			Если СозданныйОбъект = Неопределено Тогда
				СозданныйОбъект = СсылкаНаОбъект.ПолучитьОбъект();
			КонецЕсли;

			СозданныйОбъект.Дата = СвойстваПоиска["Дата"];

		КонецЕсли;

	КонецЕсли;
	
	// Создавать новый объект нужно не всегда.
	Если Не ЗначениеЗаполнено(СсылкаНаОбъект) И СозданныйОбъект = Неопределено Тогда

		Если ПриПереносеОбъектаПоСсылкеУстанавливатьТолькоGIUD Тогда

			СсылкаНаОбъект = СтруктураСвойств.Менеджер.ПолучитьСсылку(
				Новый УникальныйИдентификатор(СвойствоУникальныйИдентификатор));
			СсылкаНаОбъектФиктивная = Истина;

		ИначеЕсли Не НеСоздаватьОбъектЕслиНеНайден Тогда

			СсылкаНаОбъект = СоздатьНовыйОбъект(ТипОбъекта, СвойстваПоиска, СозданныйОбъект,
				Не РежимПоискаОсновногоОбъекта, , ИзвестнаяСсылкаУникальногоИдентификатора, НППСсылки,
				НППГлобальнойСсылки, , УстанавливатьУОбъектаВсеСвойстваПоиска);

			СвойстваОбъектаМодифицированы = Истина;

		КонецЕсли;

		ОбъектНайден = Ложь;

	Иначе

		ОбъектНайден = ЗначениеЗаполнено(СсылкаНаОбъект);

	КонецЕсли;

	Если СсылкаНаОбъект <> Неопределено И СсылкаНаОбъект.Пустая() Тогда

		СсылкаНаОбъект = Неопределено;

	КонецЕсли;

	ДобавитьСсылкуВСписокЗагруженныхОбъектов(НППГлобальнойСсылки, НППСсылки, СсылкаНаОбъект, СсылкаНаОбъектФиктивная);

	Возврат СсылкаНаОбъект;

КонецФункции

// Устанавливает свойства объекта (записи).
//
// Параметры:
//  Запись         - объект, свойства которого устанавливаем.
//                   Например, строка табличной части или запись регистра.
//
Процедура УстановитьСвойстваЗаписи(Объект, Запись, ИнформацияОТипах, ПараметрыОбъекта, ИмяВетки, ДанныеПоискаПоТЧ,
	КопияТЧДляПоиска, НомерЗаписи)

	НужноОрганизоватьПоискПоТЧ = (ДанныеПоискаПоТЧ <> Неопределено) И (КопияТЧДляПоиска <> Неопределено)
		И КопияТЧДляПоиска.Количество() <> 0;

	Если НужноОрганизоватьПоискПоТЧ Тогда

		СтруктураЧтенияСвойств = Новый Структура;
		СтруктураЧтенияСубконто = Новый Структура;

	КонецЕсли;

	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Свойство" Или ИмяУзла = "ЗначениеПараметра" Тогда

			ЭтоПараметр = (ИмяУзла = "ЗначениеПараметра");

			Имя    = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");
			ИмяПКО = одАтрибут(ФайлОбмена, одТипСтрока, "ИмяПКО");

			Если Имя = "ВидДвижения" И СтрНайти(Метаданные.НайтиПоТипу(ТипЗнч(Запись)).ПолноеИмя(),
				"РегистрНакопления") Тогда

				ТипСвойства = одТипВидДвиженияНакопления;

			Иначе

				ТипСвойства = ПолучитьТипСвойстваПоДополнительнымДанным(ИнформацияОТипах, Имя);

			КонецЕсли;

			ЗначениеСвойства = ПрочитатьСвойство(ТипСвойства, ИмяПКО);

			Если ЭтоПараметр Тогда
				ДобавитьСложныйПараметрПриНеобходимости(ПараметрыОбъекта, ИмяВетки, НомерЗаписи, Имя, ЗначениеСвойства);
			ИначеЕсли НужноОрганизоватьПоискПоТЧ Тогда
				СтруктураЧтенияСвойств.Вставить(Имя, ЗначениеСвойства);
			Иначе

				Попытка

					Запись[Имя] = ЗначениеСвойства;

				Исключение

					ЗП = ПолучитьСтруктуруЗаписиПротокола(26, ОписаниеОшибки());
					ЗП.ИмяПКО           = ИмяПКО;
					ЗП.Объект           = Объект;
					ЗП.ТипОбъекта       = ТипЗнч(Объект);
					ЗП.Свойство         = Строка(Запись) + "." + Имя;
					ЗП.Значение         = ЗначениеСвойства;
					ЗП.ТипЗначения      = ТипЗнч(ЗначениеСвойства);
					СтрокаСообщенияОбОшибке = ЗаписатьВПротоколВыполнения(26, ЗП, Истина);

					Если Не DebugModeFlag Тогда
						ВызватьИсключение СтрокаСообщенияОбОшибке;
					КонецЕсли;
				КонецПопытки;

			КонецЕсли;

		ИначеЕсли ИмяУзла = "СубконтоДт" Или ИмяУзла = "СубконтоКт" Тогда
			
			// Поиск по субконто не реализован.

			Ключ = Неопределено;
			Значение = Неопределено;

			Пока ФайлОбмена.Прочитать() Цикл

				ИмяУзла = ФайлОбмена.ЛокальноеИмя;

				Если ИмяУзла = "Свойство" Тогда

					Имя    = одАтрибут(ФайлОбмена, одТипСтрока, "Имя");
					ИмяПКО = одАтрибут(ФайлОбмена, одТипСтрока, "ИмяПКО");
					ТипСвойства = ПолучитьТипСвойстваПоДополнительнымДанным(ИнформацияОТипах, Имя);

					Если Имя = "Ключ" Тогда

						Ключ = ПрочитатьСвойство(ТипСвойства);

					ИначеЕсли Имя = "Значение" Тогда

						Значение = ПрочитатьСвойство(ТипСвойства, ИмяПКО);

					КонецЕсли;

				ИначеЕсли (ИмяУзла = "СубконтоДт" Или ИмяУзла = "СубконтоКт") И (ФайлОбмена.ТипУзла
					= одТипУзлаXML_КонецЭлемента) Тогда

					Прервать;

				Иначе

					ЗаписатьВПротоколВыполнения(9);
					Прервать;

				КонецЕсли;

			КонецЦикла;

			Если Ключ <> Неопределено И Значение <> Неопределено Тогда

				Если Не НужноОрганизоватьПоискПоТЧ Тогда

					Запись[ИмяУзла][Ключ] = Значение;

				Иначе

					СоответствиеЗаписи = Неопределено;
					Если Не СтруктураЧтенияСубконто.Свойство(ИмяУзла, СоответствиеЗаписи) Тогда
						СоответствиеЗаписи = Новый Соответствие;
						СтруктураЧтенияСубконто.Вставить(ИмяУзла, СоответствиеЗаписи);
					КонецЕсли;

					СоответствиеЗаписи.Вставить(Ключ, Значение);

				КонецЕсли;

			КонецЕсли;

		ИначеЕсли (ИмяУзла = "Запись") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		Иначе

			ЗаписатьВПротоколВыполнения(9);
			Прервать;

		КонецЕсли;

	КонецЦикла;

	Если НужноОрганизоватьПоискПоТЧ Тогда

		СтруктураПоиска = Новый Структура;

		Для Каждого ЭлементПоиска Из ДанныеПоискаПоТЧ.ПоляПоискаТЧ Цикл

			ЗначениеЭлемента = Неопределено;
			СтруктураЧтенияСвойств.Свойство(ЭлементПоиска, ЗначениеЭлемента);

			СтруктураПоиска.Вставить(ЭлементПоиска, ЗначениеЭлемента);

		КонецЦикла;

		МассивРезультатовПоиска = КопияТЧДляПоиска.НайтиСтроки(СтруктураПоиска);

		НайденаЗапись = МассивРезультатовПоиска.Количество() > 0;
		Если НайденаЗапись Тогда
			ЗаполнитьЗначенияСвойств(Запись, МассивРезультатовПоиска[0]);
		КонецЕсли;
		
		// Поверх заполнение свойствами и значением субконто.
		Для Каждого КлючИЗначение Из СтруктураЧтенияСвойств Цикл

			Запись[КлючИЗначение.Ключ] = КлючИЗначение.Значение;

		КонецЦикла;

		Для Каждого ЭлементИмя Из СтруктураЧтенияСубконто Цикл

			Для Каждого ЭлементКлюч Из ЭлементИмя.Значение Цикл

				Запись[ЭлементИмя.Ключ][ЭлементКлюч.Ключ] = ЭлементКлюч.Значение;

			КонецЦикла;

		КонецЦикла;

	КонецЕсли;

КонецПроцедуры

// Загружает табличную часть объекта.
//
// Параметры:
//  Объект         - объект, табличную часть которого загружаем.
//  Имя            - имя табличной части.
//  Очистить       - если Истина, то табличная часть предварительно очищается.
// 
Процедура ЗагрузитьТабличнуюЧасть(Объект, Имя, Очистить, ОбщаяИнформацияОТипеДокумента, НужноЗаписатьОбъект,
	ПараметрыОбъекта, Правило)

	ИмяТабличнойЧасти = Имя + "ТабличнаяЧасть";
	Если ОбщаяИнформацияОТипеДокумента <> Неопределено Тогда
		ИнформацияОТипах = ОбщаяИнформацияОТипеДокумента[ИмяТабличнойЧасти];
	Иначе
		ИнформацияОТипах = Неопределено;
	КонецЕсли;

	ДанныеПоискаПоТЧ = Неопределено;
	Если Правило <> Неопределено Тогда
		ДанныеПоискаПоТЧ = Правило.ПоискПоТабличнымЧастям.Найти("ТабличнаяЧасть." + Имя, "ИмяЭлемента");
	КонецЕсли;

	КопияТЧДляПоиска = Неопределено;

	ТЧ = Объект[Имя];

	Если Очистить И ТЧ.Количество() <> 0 Тогда

		НужноЗаписатьОбъект = Истина;

		Если ДанныеПоискаПоТЧ <> Неопределено Тогда
			КопияТЧДляПоиска = ТЧ.Выгрузить();
		КонецЕсли;
		ТЧ.Очистить();

	ИначеЕсли ДанныеПоискаПоТЧ <> Неопределено Тогда

		КопияТЧДляПоиска = ТЧ.Выгрузить();

	КонецЕсли;

	НомерЗаписи = 0;
	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Запись" Тогда
			Попытка

				НужноЗаписатьОбъект = Истина;
				Запись = ТЧ.Добавить();

			Исключение
				Запись = Неопределено;
			КонецПопытки;

			Если Запись = Неопределено Тогда
				одПропустить(ФайлОбмена);
			Иначе
				УстановитьСвойстваЗаписи(Объект, Запись, ИнформацияОТипах, ПараметрыОбъекта, ИмяТабличнойЧасти,
					ДанныеПоискаПоТЧ, КопияТЧДляПоиска, НомерЗаписи);
			КонецЕсли;

			НомерЗаписи = НомерЗаписи + 1;

		ИначеЕсли (ИмяУзла = "ТабличнаяЧасть") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		Иначе

			ЗаписатьВПротоколВыполнения(9);
			Прервать;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры 

// Загружает движения объекта
//
// Параметры:
//  Объект         - объект, движения которого загружаем.
//  Имя            - имя регистра.
//  Очистить       - если Истина, то движения предварительно очищается.
// 
Процедура ЗагрузитьДвижения(Объект, Имя, Очистить, ОбщаяИнформацияОТипеДокумента, НужноЗаписатьОбъект,
	ПараметрыОбъекта, Правило)

	ИмяДвижений = Имя + "НаборЗаписей";
	Если ОбщаяИнформацияОТипеДокумента <> Неопределено Тогда
		ИнформацияОТипах = ОбщаяИнформацияОТипеДокумента[ИмяДвижений];
	Иначе
		ИнформацияОТипах = Неопределено;
	КонецЕсли;

	ДанныеПоискаПоТЧ = Неопределено;
	Если Правило <> Неопределено Тогда
		ДанныеПоискаПоТЧ = Правило.ПоискПоТабличнымЧастям.Найти("НаборЗаписей." + Имя, "ИмяЭлемента");
	КонецЕсли;

	КопияТЧДляПоиска = Неопределено;

	Движения = Объект.Движения[Имя];
	Движения.Записывать = Истина;

	Если Движения.Количество() = 0 Тогда
		Движения.Прочитать();
	КонецЕсли;

	Если Очистить И Движения.Количество() <> 0 Тогда

		НужноЗаписатьОбъект = Истина;

		Если ДанныеПоискаПоТЧ <> Неопределено Тогда
			КопияТЧДляПоиска = Движения.Выгрузить();
		КонецЕсли;

		Движения.Очистить();

	ИначеЕсли ДанныеПоискаПоТЧ <> Неопределено Тогда

		КопияТЧДляПоиска = Движения.Выгрузить();

	КонецЕсли;

	НомерЗаписи = 0;
	Пока ФайлОбмена.Прочитать() Цикл

		ИмяУзла = ФайлОбмена.ЛокальноеИмя;

		Если ИмяУзла = "Запись" Тогда

			Запись = Движения.Добавить();
			НужноЗаписатьОбъект = Истина;
			УстановитьСвойстваЗаписи(Объект, Запись, ИнформацияОТипах, ПараметрыОбъекта, ИмяДвижений, ДанныеПоискаПоТЧ,
				КопияТЧДляПоиска, НомерЗаписи);
			НомерЗаписи = НомерЗаписи + 1;

		ИначеЕсли (ИмяУзла = "НаборЗаписей") И (ФайлОбмена.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда

			Прервать;

		Иначе

			ЗаписатьВПротоколВыполнения(9);
			Прервать;

		КонецЕсли;

	КонецЦикла;

КонецПроцедуры

// Загружает объект типа ОписаниеТипов из указанного xml-источника.
//
// Параметры:
//  Источник         - xml-источник.
// 
Функция ЗагрузитьТипыОбъекта(Источник)
	
	// КвалификаторыДаты

	СоставДаты =  одАтрибут(Источник, одТипСтрока, "СоставДаты");
	
	// КвалификаторыСтроки

	Длина           =  одАтрибут(Источник, одТипЧисло, "Длина");
	ДлинаДопустимая =  одАтрибут(Источник, одТипСтрока, "ДопустимаяДлина");
	
	// КвалификаторыЧисла

	Разрядность             = одАтрибут(Источник, одТипЧисло, "Разрядность");
	РазрядностьДробнойЧасти = одАтрибут(Источник, одТипЧисло, "РазрядностьДробнойЧасти");
	ЗнакДопустимый          = одАтрибут(Источник, одТипСтрока, "ДопустимыйЗнак");
	
	// Читаем массив типов

	МассивТипов = Новый Массив;

	Пока Источник.Прочитать() Цикл
		ИмяУзла = Источник.ЛокальноеИмя;

		Если ИмяУзла = "Тип" Тогда
			МассивТипов.Добавить(Тип(одЗначениеЭлемента(Источник, одТипСтрока)));
		ИначеЕсли (ИмяУзла = "Типы") И (Источник.ТипУзла = одТипУзлаXML_КонецЭлемента) Тогда
			Прервать;
		Иначе
			ЗаписатьВПротоколВыполнения(9);
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Если МассивТипов.Количество() > 0 Тогда
		
		// КвалификаторыДаты

		Если СоставДаты = "Дата" Тогда
			КвалификаторыДаты   = Новый КвалификаторыДаты(ЧастиДаты.Дата);
		ИначеЕсли СоставДаты = "ДатаВремя" Тогда
			КвалификаторыДаты   = Новый КвалификаторыДаты(ЧастиДаты.ДатаВремя);
		ИначеЕсли СоставДаты = "Время" Тогда
			КвалификаторыДаты   = Новый КвалификаторыДаты(ЧастиДаты.Время);
		Иначе
			КвалификаторыДаты   = Новый КвалификаторыДаты(ЧастиДаты.ДатаВремя);
		КонецЕсли;
		
		// КвалификаторыЧисла

		Если Разрядность > 0 Тогда
			Если ЗнакДопустимый = "Неотрицательный" Тогда
				Знак = ДопустимыйЗнак.Неотрицательный;
			Иначе
				Знак = ДопустимыйЗнак.Любой;
			КонецЕсли;
			КвалификаторыЧисла  = Новый КвалификаторыЧисла(Разрядность, РазрядностьДробнойЧасти, Знак);
		Иначе
			КвалификаторыЧисла  = Новый КвалификаторыЧисла;
		КонецЕсли;
		
		// КвалификаторыСтроки

		Если Длина > 0 Тогда
			Если ДлинаДопустимая = "Фиксированная" Тогда
				ДлинаДопустимая = ДопустимаяДлина.Фиксированная;
			Иначе
				ДлинаДопустимая = ДопустимаяДлина.Переменная;
			КонецЕсли;
			КвалификаторыСтроки = Новый КвалификаторыСтроки(Длина, ДлинаДопустимая);
		Иначе
			КвалификаторыСтроки = Новый КвалификаторыСтроки;
		КонецЕсли;

		Возврат Новый ОписаниеТипов(МассивТипов, КвалификаторыЧисла, КвалификаторыСтроки, КвалификаторыДаты);
	КонецЕсли;

	Возврат Неопределено;

КонецФункции

Процедура УстановитьПометкуУдаленияУОбъекта(Объект, ПометкаУдаления, ИмяТипаОбъекта)

	Если (ПометкаУдаления = Неопределено) И (Объект.ПометкаУдаления <> Истина) Тогда

		Возврат;

	КонецЕсли;

	ПометкаДляУстановки = ?(ПометкаУдаления <> Неопределено, ПометкаУдаления, Ложь);

	УстановитьОбменДаннымиЗагрузка(Объект);
		
	// Дли иерархических объектов пометку удаления только у конкретного объекта ставим.
	Если ИмяТипаОбъекта = "Справочник" Или ИмяТипаОбъекта = "ПланВидовХарактеристик" Или ИмяТипаОбъекта = "ПланСчетов" Тогда

		Объект.УстановитьПометкуУдаления(ПометкаДляУстановки, Ложь);

	Иначе

		Объект.УстановитьПометкуУдаления(ПометкаДляУстановки);

	КонецЕсли;

КонецПроцедуры

Процедура ЗаписатьДокументВБезопасномРежиме(Документ, ТипОбъекта)

	Если Документ.Проведен Тогда

		Документ.Проведен = Ложь;

	КонецЕсли;

	ЗаписатьОбъектВИБ(Документ, ТипОбъекта);

КонецПроцедуры

Функция ПолучитьОбъектПоСсылкеИДопИнформации(СозданныйОбъект, Ссылка)
	
	// Если объект создали, то работаем с ним, если нашли - получаем объект.
	Если СозданныйОбъект <> Неопределено Тогда
		Объект = СозданныйОбъект;
	Иначе
		Если Ссылка.Пустая() Тогда
			Объект = Неопределено;
		Иначе
			Объект = Ссылка.ПолучитьОбъект();
		КонецЕсли;
	КонецЕсли;

	Возврат Объект;

КонецФункции

Процедура КомментарииКЗагрузкеОбъекта(НПП, ИмяПравила, Источник, ТипОбъекта, ГНПП = 0)

	Если ФлагКомментироватьОбработкуОбъектов Тогда

		Если НПП <> 0 Тогда
			СтрокаСообщения = ПодставитьПараметрыВСтроку(НСтр("ru = 'Загрузка объекта № %1'"), НПП);
		Иначе
			СтрокаСообщения = ПодставитьПараметрыВСтроку(НСтр("ru = 'Загрузка объекта № %1'"), ГНПП);
		КонецЕсли;

		ЗП = ПолучитьСтруктуруЗаписиПротокола();

		Если Не ПустаяСтрока(ИмяПравила) Тогда

			ЗП.ИмяПКО = ИмяПравила;

		КонецЕсли;

		Если Не ПустаяСтрока(Источник) Тогда

			ЗП.Источник = Источник;

		КонецЕсли;

		ЗП.ТипОбъекта = ТипОбъекта;
		ЗаписатьВПротоколВыполнения(СтрокаСообщения, ЗП, Ложь);

	КонецЕсли;

КонецПроцедуры

Процедура ДобавитьПараметрПриНеобходимости(ПараметрыДанных, ИмяПараметра, ЗначениеПараметра)

	Если ПараметрыДанных = Неопределено Тогда
		ПараметрыДанных = Новый Соответствие;
	КонецЕсли;

	ПараметрыДанных.Вставить(ИмяПараметра, ЗначениеПараметра);

КонецПроцедуры

Процедура ДобавитьСложныйПараметрПриНеобходимости(ПараметрыДанных, ИмяВеткиПараметров, НомерСтроки, ИмяПараметра,
	ЗначениеПараметра)

	Если ПараметрыДанных = Неопределено Тогда
		ПараметрыДанных = Новый Соответствие;
	КонецЕсли;

	ТекущиеДанныеПараметра = ПараметрыДанных[ИмяВеткиПараметров];

	Если ТекущиеДанныеПараметра = Неопределено Тогда

		ТекущиеДанныеПараметра = Новый ТаблицаЗначений;
		ТекущиеДанныеПараметра.Колонки.Добавить("НомерСтроки");
		ТекущиеДанныеПараметра.Колонки.Добавить("ИмяПараметра");
		ТекущиеДанныеПараметра.Индексы.Добавить("НомерСтроки");

		ПараметрыДанных.Вставить(ИмяВеткиПараметров, ТекущиеДанныеПараметра);

	КонецЕсли;

	Если ТекущиеДанныеПараметра.Колонки.Найти(ИмяПараметра) = Неопределено Тогда
		ТекущиеДанныеПараметра.Колонки.Добавить(ИмяПараметра);
	КонецЕсли;

	ДанныеСтроки = ТекущиеДанныеПараметра.Найти(НомерСтроки, "НомерСтроки");
	Если ДанныеСтроки = Неопределено Тогда
		ДанныеСтроки = ТекущиеДанныеПараметра.Добавить();
		ДанныеСтроки.НомерСтроки = НомерСтроки;
	КонецЕсли;

	ДанныеСтроки[ИмяПараметра] = ЗначениеПараметра;

КонецПроцедуры

Процедура УстановитьСсылкуДляОбъекта(СтрокаСтекаНезаписанныхОбъектов)
	
	// Объект еще не записан, а на него ссылаются.
	ОбъектДляЗаписи = СтрокаСтекаНезаписанныхОбъектов.Объект;

	СвойстваМД      = Менеджеры[СтрокаСтекаНезаписанныхОбъектов.ТипОбъекта];
	Менеджер        = СвойстваМД.Менеджер;

	НовыйУникальныйИдентификатор = Новый УникальныйИдентификатор;
	НоваяСсылка = Менеджер.ПолучитьСсылку(НовыйУникальныйИдентификатор);

	ОбъектДляЗаписи.УстановитьСсылкуНового(НоваяСсылка);
	СтрокаСтекаНезаписанныхОбъектов.ИзвестнаяСсылка = НоваяСсылка;

КонецПроцедуры

Процедура ДополнитьСтекНеЗаписанныхОбъектов(НПП, ГНПП, Объект, ИзвестнаяСсылка, ТипОбъекта, ПараметрыОбъекта)

	НомерДляСтека = ?(НПП = 0, ГНПП, НПП);

	СтрокаСтека = мГлобальныйСтекНеЗаписанныхОбъектов[НомерДляСтека];
	Если СтрокаСтека <> Неопределено Тогда
		Возврат;
	КонецЕсли;
	СтруктураПараметров = Новый Структура;
	СтруктураПараметров.Вставить("Объект", Объект);
	СтруктураПараметров.Вставить("ИзвестнаяСсылка", ИзвестнаяСсылка);
	СтруктураПараметров.Вставить("ТипОбъекта", ТипОбъекта);
	СтруктураПараметров.Вставить("ПараметрыОбъекта", ПараметрыОбъекта);

	мГлобальныйСтекНеЗаписанныхОбъектов.Вставить(НомерДляСтека, СтруктураПараметров);

КонецПроцедуры

Процедура УдалитьИзСтекаНеЗаписанныхОбъектов(НПП, ГНПП)

	НомерДляСтека = ?(НПП = 0, ГНПП, НПП);
	СтрокаСтека = мГлобальныйСтекНеЗаписанныхОбъектов[НомерДляСтека];
	Если СтрокаСтека = Неопределено Тогда
		Возврат;
	КонецЕсли;

	мГлобальныйСтекНеЗаписанныхОбъектов.Удалить(НомерДляСтека);

КонецПроцедуры

Процедура ПровестиЗаписьНеЗаписанныхОбъектов()

	Если мГлобальныйСтекНеЗаписанныхОбъектов = Неопределено Тогда
		Возврат;
	КонецЕсли;

	Для Каждого СтрокаДанных Из мГлобальныйСтекНеЗаписанныхОбъектов Цикл
		
		// отложенная запись объектов
		Объект = СтрокаДанных.Значение.Объект; // СправочникОбъект, ДокументОбъект, и т.п.
		НППСсылки = СтрокаДанных.Ключ;

		ЗаписатьОбъектВИБ(Объект, СтрокаДанных.Значение.ТипОбъекта);

		ДобавитьСсылкуВСписокЗагруженныхОбъектов(0, НППСсылки, Объект.Ссылка);

	КонецЦикла;

	мГлобальныйСтекНеЗаписанныхОбъектов.Очистить();

КонецПроцедуры

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

					ДополнитьСтекНеЗаписанныхОбъектов(НПП, ГНПП, СозданныйОбъект,
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

Функция ЕстьРеквизитИлиСвойствоОбъекта(Объект, ИмяРеквизита)

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

				ОбработатьПравилаВыгрузки(КоллекцияПравилаВыгрузки().Строки, СоответствиеУзловИПравилВыгрузки);

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
	DontShowInfoMessagesToUser = Ложь;

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
