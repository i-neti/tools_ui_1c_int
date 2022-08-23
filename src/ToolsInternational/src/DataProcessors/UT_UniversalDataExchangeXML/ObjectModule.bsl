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
Var mTypeStringForDestination;


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

Var mExtendedSearchParametersMap;
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

Var PeriodClosingDateModule;

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
// The function can be used in the event handlers whose script is stored in data exchange rules.
//  It is called with the Execute() method.
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
// The function can be used in the event handlers whose script is stored in data exchange rules.
//  It is called with the Execute() method.
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
// The function can be used in the event handlers whose script is stored in data exchange rules.
//  It is called with the Execute() method.
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

// Defines whether the value is filled.
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
		
		ObjectRef = FindItemUsingQuery(CommonPropertyStructure, CommonSearchProperties, , Manager);
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
// The function can be used in the event handlers whose script is stored in data exchange rules.
// 
// Parameters:
//  TypeDescription  - TypeDescription - a TypeDescription object whose XML presentation is being retrieved.
//
// Returns:
//  String - an XML presentation of the passed TypeDescription object.
//
Function deGetTypeDescriptionXMLPresentation(TypeDescription) Export
	
	TypesNode = CreateNode("Types");
	
	If TypeOf(TypeDescription) = Type("Structure") Then
		SetAttribute(TypesNode, "AllowedSign",          TrimAll(TypeDescription.AllowedSign));
		SetAttribute(TypesNode, "Digits",             TrimAll(TypeDescription.Digits));
		SetAttribute(TypesNode, "FractionDigits", TrimAll(TypeDescription.FractionDigits));
		SetAttribute(TypesNode, "Length",                   TrimAll(TypeDescription.Length));
		SetAttribute(TypesNode, "AllowedLength",         TrimAll(TypeDescription.AllowedLength));
		SetAttribute(TypesNode, "DateComposition",              TrimAll(TypeDescription.DateFractions));
		
		For Each StrType In TypeDescription.Types Do
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
		
		For Each Type In TypeDescription.Types() Do
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
// of which is stored in the data exchange rules. It is called with the Execute() method.
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
// The function can be used in the event handlers whose script is stored in data exchange rules.
//  It is called with the Execute() method.
// The "No links to function found" message during the configuration check is not an error.
// 
//
// Parameters:
//  ParentNode - a parent XML node.
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
// The function can be used in the event handlers whose script is stored in data exchange rules.
//  It is called with the Execute() method.
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
Function GetLogRecordStructure(MessageCode = "", ErrorString = "") Export

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
Function WriteErrorInfoToLog(MessageCode, ErrorString, Object, ObjectType = Undefined) Export
	
	WP         = GetLogRecordStructure(MessageCode, ErrorString);
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

// Exports an object according to the conversion rule
//
// Parameters:
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

	DoNotExportByValueMap = (ValueMapItemCount = 0);
	
	If Not DoNotExportByValueMap Then
		
		// If value mapping does not contain values, exporting mapping in the ordinary way.
		RefNode = ValueMap[Source];
		If RefNode = Undefined And OCR.SearchProperties.Count() > 0 Then
			
			// Perhaps, this is a conversion from enumeration into enumeration and
			// required VCR is not found. Exporting an empty reference.
			If PropertyStructure.TypeName = "Enum" And StrFind(OCR.Destination, "EnumRef.") > 0 Then
				
				RefNode = "";
				
			Else
						
				DoNotExportByValueMap = True;	
				
			EndIf;
			
		EndIf;
		
	EndIf;

	MustRememberObject = RememberExported And (Not AllObjectsExported);

	If DoNotExportByValueMap Then
		
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
		
		If DoNotReplaceObjectOnImport Then
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

#Region ExportMethods

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
Procedure SendSingleParameterToDestination(Name, InitialParameterValue, ConversionRule = "") Export
	
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
Procedure InitPropertyConversionRulesTable(Tab) Export

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
			WriteToExecutionLog(78);
			
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

Procedure InitializeKeepExchangeLogForHandlersExport()

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
//  Align - Number. A resulting length to written string, see deSupplementString() function.
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
		
		For Each Field In RecordStructure Do
			
			Value = Field.Value;
			If Value = Undefined Then
				Continue;
			EndIf; 
			Key_ = Field.Key;
			Str  = Str + Chars.LF + Indent + Chars.Tab + deSupplementString(Key_, Align) + " =  " + String(Value);
			
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
	
	If ExchangeMode <> "Import" Then
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
			
			If ExchangeMode = "Import" Then
				
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
		
			ImportValues(ExchangeRules, NewRow.Values, NewRow.Source);
			
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
 			If ExchangeMode = "Import" Then
				
				NewRow.BeforeImport               = Value;
				NewRow.HasBeforeImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "OnImport" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				NewRow.OnImport               = Value;
				NewRow.HasOnImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "AfterImport" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				NewRow.AfterImport               = Value;
				NewRow.HasAfterImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
	 		EndIf;

		ElsIf NodeName = "SearchFieldSequence" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			NewRow.HasSearchFieldSequenceHandler = Not IsBlankString(Value);
			
			If ExchangeMode = "Import" Then
				
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
		
		If Not PropertyString.IsGroup Or IsBlankString(PropertyString.SourceKind)
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
			If ExchangeMode <> "Import" Then
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
				If ExchangeMode <> "Import" Then
					XMLWriter.WriteEndElement();
				EndIf;
			EndIf;
		ElsIf NodeType = deXMLNodeType_Text Then
			If ExchangeMode <> "Import" Then
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
		If ExchangeMode = "Import" Then
			Algorithms.Insert(Name, Text);
		Else
			XMLWriter.WriteStartElement("Algorithm");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Import" Then
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
		If ExchangeMode = "Import" Then
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
		If ExchangeMode <> "Import" Then
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
			
			If ExchangeMode = "Import" And Not UsedOnImport Then
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

			If UsedOnImport And ExchangeMode = "Export" Then
				
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
		If ExchangeMode = "Import" Then
			
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
		If (ExchangeMode = "Import") And UsedOnImport Then
			ImportSettingsDataProcessors.Add(Name, Description, , );
			
		ElsIf (ExchangeMode = "Export") And UsedOnExport Then
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
		
		ExchangeMode = "Import"; 
		
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

#Region FullAlgorithmScriptsMethodsConsideringNesting

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
		
		If Rule.IsGroup Then
			
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
		
		If PCR.IsGroup Then // PGCR
			
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
	
	If ExchangeMode = "Export" Then
	
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
			
			If (Name = "IsFolder") And (PropertyValue <> True) Then
				
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

Function FindItemUsingQuery(PropertyStructure, SearchProperties, ObjectType = Undefined, 
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
	
	MapValue = mExtendedSearchParametersMap.Get(RefTypeString);
	
	If MapValue <> Undefined Then
		Return MapValue;
	EndIf;
	
	Try
	
		For Each Item In Rules Do
			
			If Item.Value.Destination = RefTypeString Then
				
				If Item.Value.SynchronizeByID = True Then
					
					ContinueSearch = (Item.Value.SearchBySearchFieldsIfNotFoundByID = True);
					mExtendedSearchParametersMap.Insert(RefTypeString, ContinueSearch);
					
					Return ContinueSearch;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		mExtendedSearchParametersMap.Insert(RefTypeString, False);
		Return False;
	
	Except
		
		mExtendedSearchParametersMap.Insert(RefTypeString, False);
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

Procedure AddRefToImportedObjectsList(GSNRef, SNRef, ObjectRef, DummyRef = False)
	
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
			
		ObjectRef = FindItemUsingQuery(PropertyStructure, TemporarySearchProperties, ObjectType, , RealSearchPropertiesCount);
				
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
	OnMoveObjectByRefSetGIUDOnly = Not MainObjectSearchMode 
		And deAttribute(ExchangeFile, deBooleanType, "OnMoveObjectByRefSetGIUDOnly");
	
	// Creating object search properties.
	ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace, SearchByEqualDate, ObjectParameters);
		
	CreatedObject = Undefined;
	
	If Not ObjectFound Then
		
		ObjectRef = CreateNewObject(ObjectType, SearchProperties, CreatedObject, , , , RefSN, GlobalRefSn);
		AddRefToImportedObjectsList(GlobalRefSn, RefSN, ObjectRef);
		Return ObjectRef;
		
	EndIf;

	PropertyStructure   = Managers[ObjectType];
	ObjectTypeName     = PropertyStructure.TypeName;
		
	UUIDProperty = SearchProperties["{UUID}"];
	PredefinedNameProperty = SearchProperties["{PredefinedItemName}"];
	
	OnMoveObjectByRefSetGIUDOnly = OnMoveObjectByRefSetGIUDOnly
		AND UUIDProperty <> Undefined;
		
	// Searching by name if the item is predefined.
	If PredefinedNameProperty <> Undefined Then
		
		CreateNewObjectAutomatically = Not DontCreateObjectIfNotFound
			And Not OnMoveObjectByRefSetGIUDOnly;
		
		ObjectRef = FindCreateObjectByProperty(PropertyStructure, ObjectType, SearchProperties, SearchPropertiesDontReplace,
			ObjectTypeName, "{PredefinedItemName}", PredefinedNameProperty, ObjectFound, 
			CreateNewObjectAutomatically, CreatedObject, MainObjectSearchMode, ObjectPropertiesModified,
			RefSN, GlobalRefSn, ObjectParameters);

	ElsIf (UUIDProperty <> Undefined) Then
			
		// Creating the new item by the UUID is not always necessary. Perhaps, the search must be continued.
		ContinueSearchIfItemNotFoundByGUID = GetAdditionalSearchBySearchFieldsUsageByObjectType(PropertyStructure.RefTypeString);

		CreateNewObjectAutomatically = (Not DontCreateObjectIfNotFound
			And Not ContinueSearchIfItemNotFoundByGUID)
			And Not OnMoveObjectByRefSetGIUDOnly;

		ObjectRef = FindCreateObjectByProperty(PropertyStructure, ObjectType, SearchProperties, SearchPropertiesDontReplace,
			ObjectTypeName, "{UUID}", UUIDProperty, ObjectFound, 
			CreateNewObjectAutomatically, CreatedObject, 
			MainObjectSearchMode, ObjectPropertiesModified,
			RefSN, GlobalRefSn, ObjectParameters, KnownUUIDRef);

		If Not ContinueSearchIfItemNotFoundByGUID Then

			If Not ValueIsFilled(ObjectRef)
				And OnMoveObjectByRefSetGIUDOnly Then
				
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

				AddRefToImportedObjectsList(GlobalRefSn, RefSN, ObjectRef, DummyObjectRef);
				
			EndIf;
			
			Return ObjectRef;	
			
		EndIf;
		
	EndIf;

	If ObjectRef <> Undefined And ObjectRef.IsEmpty() Then
		
		ObjectRef = Undefined;
		
	EndIf;
		
	// ObjectRef is not found yet.
	If ObjectRef <> Undefined Or CreatedObject <> Undefined Then
		
		AddRefToImportedObjectsList(GlobalRefSn, RefSN, ObjectRef);
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
			
			If MainObjectSearchMode And SetAllObjectSearchProperties = True Then
				
				ProcessObjectSearchPropertiesSetup(SetAllObjectSearchProperties, ObjectType, SearchProperties, SearchPropertiesDontReplace,
					ObjectRef, CreatedObject, Not MainObjectSearchMode, ObjectPropertiesModified);
				
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
		
		If OnMoveObjectByRefSetGIUDOnly Then
			
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
	
	AddRefToImportedObjectsList(GlobalRefSn, RefSN, ObjectRef, DummyObjectRef);
		
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

Procedure DeleteFromNotWrittenObjectsStack(SN, GSN)
	
	NumberForStack = ?(SN = 0, GSN, SN);
	StackString = mNotWrittenObjectGlobalStack[NumberForStack];
	If StackString = Undefined Then
		Return;
	EndIf;
	
	mNotWrittenObjectGlobalStack.Delete(NumberForStack);	
	
EndProcedure

Procedure WriteNotWrittenObjects()
	
	If mNotWrittenObjectGlobalStack = Undefined Then
		Return;
	EndIf;
	
	For Each DataRow In mNotWrittenObjectGlobalStack Do
		
		// Deferred objects writing
		Object = DataRow.Value.Object; // CatalogObject, DocumentObject, etc.
		RefSN = DataRow.Key;
		
		WriteObjectToIB(Object, DataRow.Value.ObjectType);
		
		AddRefToImportedObjectsList(0, RefSN, Object.Ref);
		
	EndDo;
	
	mNotWrittenObjectGlobalStack.Clear();
	
EndProcedure

Procedure ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, ObjectTypeName, WriteObject, 
	DataExchangeMode)
	
	If Not GenerateNewNumberOrCodeIfNotSet Or Not DataExchangeMode Then
		
		// Platform code/number generation
		Return;
	EndIf;
	
	// Checking whether the code or number are filled (depends on the object type).
	If ObjectTypeName = "Document" Or ObjectTypeName =  "BusinessProcess" Or ObjectTypeName = "Task" Then
		
		If Not ValueIsFilled(Object.Number) Then
			
			Object.SetNewNumber();
			WriteObject = True;
			
		EndIf;
		
	ElsIf ObjectTypeName = "Catalog" Or ObjectTypeName = "ChartOfCharacteristicTypes" Or ObjectTypeName = "ExchangePlan" Then
		
		If Not ValueIsFilled(Object.Code) Then
			
			Object.SetNewCode();
			WriteObject = True;
			
		EndIf;	
		
	EndIf;
	
EndProcedure

// Reads the object from the exchange file and imports it.
//
// Parameters:
//  No.
// 
Function ReadObject()

	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	SN						= deAttribute(ExchangeFile, deNumberType,  "Sn");
	GSN					= deAttribute(ExchangeFile, deNumberType,  "Gsn");
	Source				= deAttribute(ExchangeFile, deStringType, "Source");
	RuleName				= deAttribute(ExchangeFile, deStringType, "RuleName");
	DontReplaceObject 		= deAttribute(ExchangeFile, deBooleanType, "DoNotReplace");
	AutonumberingPrefix	= deAttribute(ExchangeFile, deStringType, "AutonumberingPrefix");
	ObjectTypeString       = deAttribute(ExchangeFile, deStringType, "Type");
	ObjectType 				= Type(ObjectTypeString);
	TypesInformation = mDataTypeMapForImport[ObjectType];

	ObjectImportComments(SN, RuleName, Source, ObjectType, GSN);    
	
	PropertyStructure = Managers[ObjectType];
	ObjectTypeName   = PropertyStructure.TypeName;

	If ObjectTypeName = "Document" Then
		
		WriteMode     = deAttribute(ExchangeFile, deStringType, "WriteMode");
		PostingMode = deAttribute(ExchangeFile, deStringType, "PostingMode");
		
	EndIf;

	Ref          = Undefined;
	Object          = Undefined; // CatalogObject, DocumentObject, InformationRegisterRecordSet, etc.
	ObjectFound    = True;
	DeletionMark = Undefined;
	
	SearchProperties  = New Map;
	SearchPropertiesDontReplace  = New Map;
	
	WriteObject = NOT WriteToInfobaseOnlyChangedObjects;
	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		HasBeforeImportHandler = Rule.HasBeforeImportHandler;
		HasOnImportHandler    = Rule.HasOnImportHandler;
		HasAfterImportHandler  = Rule.HasAfterImportHandler;
		GenerateNewNumberOrCodeIfNotSet = Rule.GenerateNewNumberOrCodeIfNotSet;
		
	Else
		
		HasBeforeImportHandler = False;
		HasOnImportHandler    = False;
		HasAfterImportHandler  = False;
		GenerateNewNumberOrCodeIfNotSet = False;
		
	EndIf;


    // BeforeImportObject global event handler.
	If HasBeforeImportObjectGlobalHandler Then
		
		Cancel = False;
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Conversion, "BeforeImportObject"));
				
			Else
				
				Execute(Conversion.BeforeImportObject);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(53, ErrorDescription(), RuleName, Source,
				ObjectType, Undefined, NStr("ru = 'ПередЗагрузкойОбъекта (глобальный)'; en = 'BeforeImportObject (global)'"));
							
		EndTry;
						
		If Cancel Then	//	Canceling the object import
			
			deSkip(ExchangeFile, "Object");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	
    // BeforeImportObject event handler.
	If HasBeforeImportHandler Then
		
		Cancel = False;
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "BeforeImport"));
				
			Else
				
				Execute(Rule.BeforeImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(19, ErrorDescription(), RuleName, Source,
				ObjectType, Undefined, "BeforeImportObject");
			
		EndTry;
		
		If Cancel Then // Canceling the object import
			
			deSkip(ExchangeFile, "Object");
			Return Undefined;
			
		EndIf;
		
	EndIf;

	ObjectPropertiesModified = False;
	RecordSet = Undefined;
	GlobalRefSn = 0;
	RefSN = 0;
	ObjectParameters = Undefined;

	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Property" Or NodeName = "ParameterValue" Then
			
			IsParameterForObject = (NodeName = "ParameterValue");
			
			If Not IsParameterForObject And Object = Undefined Then
				
				// The object was not found and was not created.
				ObjectFound = False;

			    // OnImportObject event handler.
				If HasOnImportHandler Then
					
					// Rewriting the object if OnImporthandler exists.
					WriteObjectWasRequired = WriteObject;
      				ObjectModified = True;

					Try
						
						If HandlersDebugModeFlag Then
							
							Execute(GetHandlerCallString(Rule, "OnImport"));
							
						Else
							
							Execute(Rule.OnImport);
						
						EndIf;
						WriteObject = ObjectModified Or WriteObjectWasRequired;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source,
							ObjectType, Object, "OnImportObject");
						
					EndTry;

				EndIf;

				// Failed to create the object in the event.
				If Object = Undefined Then
					
					WriteObject = True;
					
					If ObjectTypeName = "Constants" Then
						
						Object = Constants.CreateSet();
						Object.Read();
						
					Else
						
						CreateNewObject(ObjectType, SearchProperties, Object, False, RecordSet, , RefSN, GlobalRefSn, ObjectParameters);
												
					EndIf;
					
				EndIf;
				
			EndIf;

			Name                = deAttribute(ExchangeFile, deStringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, deBooleanType, "DoNotReplace");
			OCRName             = deAttribute(ExchangeFile, deStringType, "OCRName");
			
			If Not IsParameterForObject And ((ObjectFound And DontReplaceProperty) 
				Or (Name = "IsFolder") Or (Object[Name] = Null)) Then
				
				// Unknown property
				deSkip(ExchangeFile, NodeName);
				Continue;
				
			EndIf; 

			
			// Reading and setting the property value.
			PropertyType = GetPropertyTypeByAdditionalData(TypesInformation, Name);
			Value    = ReadProperty(PropertyType, OCRName);
			
			If IsParameterForObject Then
				
				// Supplementing the object parameter collection.
				AddParameterIfNecessary(ObjectParameters, Name, Value);
				
			Else
			
				If Name = "DeletionMark" Then
					
					DeletionMark = Value;
					
					If Object.DeletionMark <> DeletionMark Then
						Object.DeletionMark = DeletionMark;
						WriteObject = True;
					EndIf;
										
				Else

					Try
						
						If Not WriteObject Then
							
							WriteObject = (Object[Name] <> Value);
							
						EndIf;
						
						Object[Name] = Value;
						
					Except
						
						LR = GetLogRecordStructure(26, ErrorDescription());
						LR.OCRName           = RuleName;
						LR.Sn              = SN;
						LR.Gsn             = GSN;
						LR.Source         = Source;
						LR.Object           = Object;
						LR.ObjectType       = ObjectType;
						LR.Property         = Name;
						LR.Value         = Value;
						LR.ValueType      = TypeOf(Value);
						ErrorMessageString = WriteToExecutionLog(26, LR, True);
						
						If Not DebugModeFlag Then
							Raise ErrorMessageString;
						EndIf;
						
					EndTry;					
									
				EndIf;
				
			EndIf;

		ElsIf NodeName = "Ref" Then
			
			// Getting an object by reference and setting properties.
			CreatedObject = Undefined;
			DontCreateObjectIfNotFound = Undefined;
			KnownUUIDRef = Undefined;
			
			Ref = FindObjectByRef(ObjectType, RuleName, SearchProperties, SearchPropertiesDontReplace, ObjectFound,
								CreatedObject, DontCreateObjectIfNotFound, True, ObjectPropertiesModified,
								GlobalRefSn, RefSN, KnownUUIDRef, ObjectParameters);

			WriteObject = WriteObject Or ObjectPropertiesModified;
			
			If Ref = Undefined And DontCreateObjectIfNotFound = True Then
				
				deSkip(ExchangeFile, "Object");
				Break;
			
			ElsIf ObjectTypeName = "Enum" Then
				
				Object = Ref;
			
			Else
				
				Object = GetObjectByRefAndAdditionalInformation(CreatedObject, Ref);
				
				If ObjectFound And DontReplaceObject And (Not HasOnImportHandler) Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
				If Ref = Undefined Then
					
					SupplementNotWrittenObjectsStack(SN, GSN, CreatedObject, KnownUUIDRef, ObjectType, ObjectParameters);
					
				EndIf;
							
			EndIf; 
			
		    // OnImportObject event handler.
			If HasOnImportHandler Then
				
				WriteObjectWasRequired = WriteObject;
      			ObjectModified = True;
				
				Try
					
					If HandlersDebugModeFlag Then
						
						Execute(GetHandlerCallString(Rule, "OnImport"));
						
					Else
						
						Execute(Rule.OnImport);
						
					EndIf;
					
					WriteObject = ObjectModified Or WriteObjectWasRequired;
					
				Except
					DeleteFromNotWrittenObjectsStack(SN, GSN);
					WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source, 
							ObjectType, Object, "OnImportObject");
					
				EndTry;
				
				If ObjectFound And DontReplaceObject Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
			EndIf;

		ElsIf NodeName = "TabularSection" Or NodeName = "RecordSet" Then

			If Object = Undefined Then
				
				ObjectFound = False;

			    // OnImportObject event handler.
				
				If HasOnImportHandler Then
					
					WriteObjectWasRequired = WriteObject;
      				ObjectModified = True;
					
					Try
						
						If HandlersDebugModeFlag Then
							
							Execute(GetHandlerCallString(Rule, "OnImport"));
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
						WriteObject = ObjectModified Or WriteObjectWasRequired;
						
					Except
						DeleteFromNotWrittenObjectsStack(SN, GSN);
						WriteInfoOnOCRHandlerImportError(20, ErrorDescription(), RuleName, Source, 
							ObjectType, Object, "OnImportObject");
						
					EndTry;
					
				EndIf;
				
			EndIf;

			Name                = deAttribute(ExchangeFile, deStringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, deBooleanType, "DoNotReplace");
			DontClear          = deAttribute(ExchangeFile, deBooleanType, "DoNotClear");

			If ObjectFound And DontReplaceProperty Then
				
				deSkip(ExchangeFile, NodeName);
				Continue;
				
			EndIf;
			
			If Object = Undefined Then
					
				CreateNewObject(ObjectType, SearchProperties, Object, False, RecordSet, , RefSN, GlobalRefSn, ObjectParameters);
				WriteObject = True;
									
			EndIf;
			
			If NodeName = "TabularSection" Then
				
				// Importing items from the tabular section
				ImportTabularSection(Object, Name, Not DontClear, TypesInformation, WriteObject, ObjectParameters, Rule);
				
			ElsIf NodeName = "RecordSet" Then
				
				// Importing register
				ImportRegisterRecords(Object, Name, Not DontClear, TypesInformation, WriteObject, ObjectParameters, Rule);
				
			EndIf;

		ElsIf (NodeName = "Object") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			Cancel = False;
			
		    // AfterObjectImport global event handler.
			If HasAfterImportObjectGlobalHandler Then
				
				WriteObjectWasRequired = WriteObject;
      			ObjectModified = True;
				
				Try
					
					If HandlersDebugModeFlag Then
						
						Execute(GetHandlerCallString(Conversion, "AfterImportObject"));
						
					Else
						
						Execute(Conversion.AfterImportObject);
						
					EndIf;
					
					WriteObject = ObjectModified Or WriteObjectWasRequired;
					
				Except
					DeleteFromNotWrittenObjectsStack(SN, GSN);
					WriteInfoOnOCRHandlerImportError(54, ErrorDescription(), RuleName, Source,
							ObjectType, Object, NStr("ru = 'ПослеЗагрузкиОбъекта (глобальный)'; en = 'AfterImportObject (global)'"));
					
				EndTry;
				
			EndIf;
			
			// AfterObjectImport event handler.
			If HasAfterImportHandler Then
				
				WriteObjectWasRequired = WriteObject;
				ObjectModified = True;
				
				Try
					
					If HandlersDebugModeFlag Then
						
						Execute(GetHandlerCallString(Rule, "AfterImport"));
						
					Else
						
						Execute(Rule.AfterImport);
				
					EndIf;
					
					WriteObject = ObjectModified Or WriteObjectWasRequired;
					
				Except
					DeleteFromNotWrittenObjectsStack(SN, GSN);
					WriteInfoOnOCRHandlerImportError(21, ErrorDescription(), RuleName, Source,
												ObjectType, Object, "AfterImportObject");
						
				EndTry;
				
			EndIf;

			If ObjectTypeName <> "InformationRegister" And ObjectTypeName <> "Constants" And ObjectTypeName <> "Enum" Then
				// Checking the restriction date for all objects except for information registers and constants.
				Cancel = Cancel Or DisableDataChangeByDate(Object);
			EndIf;
			
			If Cancel Then
				
				AddRefToImportedObjectsList(GlobalRefSn, RefSN, Undefined);
				DeleteFromNotWrittenObjectsStack(SN, GSN);
				Return Undefined;
				
			EndIf;

			If ObjectTypeName = "Document" Then
				
				If WriteMode = "Posting" Then
					
					WriteMode = DocumentWriteMode.Posting;
					
				Else
					
					WriteMode = ?(WriteMode = "UndoPosting", DocumentWriteMode.UndoPosting, DocumentWriteMode.Write);
					
				EndIf;
				PostingMode = ?(PostingMode = "RealTime", DocumentPostingMode.RealTime, DocumentPostingMode.Regular);
				

				// Clearing the deletion mark to post the object.
				If Object.DeletionMark And (WriteMode = DocumentWriteMode.Posting) Then
					
					Object.DeletionMark = False;
					WriteObject = True;
					
					// The deletion mark is deleted anyway.
					DeletionMark = False;
									
				EndIf;

				Try
					
					WriteObject = WriteObject Or (WriteMode <> DocumentWriteMode.Write);
					
					DataExchangeMode = WriteMode = DocumentWriteMode.Write;
					
					ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, 
						ObjectTypeName, WriteObject, DataExchangeMode);
					
					If WriteObject Then
					
						SetDataExchangeLoad(Object, DataExchangeMode);
						If Object.Posted Then
							Object.DeletionMark = False;
						EndIf;
						
						Object.Write(WriteMode, PostingMode);
						
					EndIf;

				Except
						
					// Failed to execute actions required for the document.
					WriteDocumentInSafeMode(Object, ObjectType);
					LR                        = GetLogRecordStructure(25, ErrorDescription());
					LR.OCRName                 = RuleName;
						
					If Not IsBlankString(Source) Then
							
						LR.Source           = Source;
							
					EndIf;
						
					LR.ObjectType             = ObjectType;
					LR.Object                 = String(Object);
					WriteToExecutionLog(25, LR);
						
				EndTry;

				AddRefToImportedObjectsList(GlobalRefSn, RefSN, Object.Ref);
									
				DeleteFromNotWrittenObjectsStack(SN, GSN);

			ElsIf ObjectTypeName <> "Enum" Then
				
				If ObjectTypeName = "InformationRegister" Then
					
					WriteObject = Not WriteToInfobaseOnlyChangedObjects;
					
					If PropertyStructure.Periodic And Not ValueIsFilled(Object.Period) Then
						
						Object.Period = CurrentSessionDate();
						WriteObject = True;							
												
					EndIf;

					If WriteRegistersAsRecordSets Then
						
						CheckDataForTempSet = (WriteToInfobaseOnlyChangedObjects And Not WriteObject) 
							Or DontReplaceObject;
						
						If CheckDataForTempSet Then
							
							TemporaryRecordSet = InformationRegisters[PropertyStructure.Name].CreateRecordSet();
							
						EndIf;
						
						// The register requires the filter to be set.
						For Each FilterItem In RecordSet.Filter Do
							
							FilterItem.Set(Object[FilterItem.Name]);
							If CheckDataForTempSet Then
								SetFilterItemValue(TemporaryRecordSet.Filter, FilterItem.Name,
									Object[FilterItem.Name]);
							EndIf;
							
						EndDo;

						If CheckDataForTempSet Then
							
							TemporaryRecordSet.Read();
							
							If TemporaryRecordSet.Count() = 0 Then
								WriteObject = True;
							Else
								
								If DontReplaceObject Then
									Return Undefined;
								EndIf;
								
								WriteObject = False;
								NewTable = RecordSet.Unload();
								OldTable = TemporaryRecordSet.Unload(); 
								
								NewRow = NewTable[0]; 
								OldRow = OldTable[0]; 
								
								For Each TableColumn In NewTable.Columns Do
									
									WriteObject = NewRow[TableColumn.Name] <>  OldRow[TableColumn.Name];
									If WriteObject Then
										Break;
									EndIf;
									
								EndDo;
								
							EndIf;
							
						EndIf;

						Object = RecordSet;
						
						If PropertyStructure.Periodic Then
							// Checking the change restriction date for a record set.
							If DisableDataChangeByDate(Object) Then
								Return Undefined;
							EndIf;
						EndIf;
						
					Else
						
						If DontReplaceObject Or PropertyStructure.Periodic Then
							
							TemporaryRecordSet = InformationRegisters[PropertyStructure.Name].CreateRecordSet();
							
							For Each FilterItem In TemporaryRecordSet.Filter Do
							
								FilterItem.Set(Object[FilterItem.Name]);
																
							EndDo;

							TemporaryRecordSet.Read();
							
							If TemporaryRecordSet.Count() > 0
								Or DisableDataChangeByDate(TemporaryRecordSet) Then
								Return Undefined;
							EndIf;
							
						Else
							WriteObject = True;
						EndIf;
						
					EndIf;
					
				EndIf;

				IsReferenceObjectType = Not( ObjectTypeName = "InformationRegister" Or ObjectTypeName = "Constants"
					Or ObjectTypeName = "Enum");

				If IsReferenceObjectType Then 	
					
					ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, ObjectTypeName, WriteObject, ImportDataInExchangeMode);
					
					If DeletionMark = Undefined Then
						DeletionMark = False;
					EndIf;
					
					If Object.DeletionMark <> DeletionMark Then
						Object.DeletionMark = DeletionMark;
						WriteObject = True;
					EndIf;
					
				EndIf;
				
				If WriteObject Then
				
					WriteObjectToIB(Object, ObjectType);
					
				EndIf;
				
				If IsReferenceObjectType Then
					
					AddRefToImportedObjectsList(GlobalRefSn, RefSN, Object.Ref);
					
				EndIf;
				
				DeleteFromNotWrittenObjectsStack(SN, GSN);
								
			EndIf;
			
			Break;

		ElsIf NodeName = "SequenceRecordSet" Then
			
			deSkip(ExchangeFile);
			
		ElsIf NodeName = "Types" Then

			If Object = Undefined Then
				
				ObjectFound = False;
				Ref = CreateNewObject(ObjectType, SearchProperties, Object, , , , RefSN, GlobalRefSn, ObjectParameters);
								
			EndIf; 

			ObjectTypesDetails = ImportObjectTypes(ExchangeFile);

			If ObjectTypesDetails <> Undefined Then
				
				Object.ValueType = ObjectTypesDetails;
				
			EndIf; 
			
		Else
			
			WriteToExecutionLog(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Object;

EndFunction

// Checks whether the import restriction by date is enabled.
//
// Parameters:
//   DataItem	  - CatalogObject, DocumentObject, InformationRegisterRecordSet, etc.
//                      Data that is read from the exchange message but is not yet written to the infobase.
//
// Returns:
//   Boolean - True, if change restriction date is set and the imported object date is less than the set date.
//
Function DisableDataChangeByDate(DataItem)
	
	DataChangesDenied = False;
	
	If PeriodClosingDateModule <> Undefined And Not Metadata.Constants.Contains(DataItem.Metadata()) Then
		Try
			If PeriodClosingDateModule.DataChangesDenied(DataItem) Then
				DataChangesDenied = True;
			EndIf;
		Except
			DataChangesDenied = False;
		EndTry;
	EndIf;
	
	DataItem.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	
	Return DataChangesDenied;
	
EndFunction

Function CheckRefExists(Ref, Manager, FoundByUUIDObject, SearchByUUIDQueryString)
	
	Try
			
		If IsBlankString(SearchByUUIDQueryString) Then
			
			FoundByUUIDObject = Ref.GetObject();
			
			If FoundByUUIDObject = Undefined Then
			
				Return Manager.EmptyRef();
				
			EndIf;
			
		Else
			
			Query = New Query();
			Query.Text = SearchByUUIDQueryString + "  Ref = &Ref ";
			Query.SetParameter("Ref", Ref);
			
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
			
				Return Manager.EmptyRef();
				
			EndIf;
			
		EndIf;
		
		Return Ref;	
		
	Except
			
		Return Manager.EmptyRef();
		
	EndTry;
	
EndFunction

Function EvalExpression(Val Expression)
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	Return Eval(Expression);
	
EndFunction

Function HasObjectAttributeOrProperty(Object, AttributeName)

	UniqueKey   = New UUID;
	AtributeStructure = New Structure(AttributeName, UniqueKey);
	FillPropertyValues(AtributeStructure, Object);

	Return AtributeStructure[AttributeName] <> UniqueKey;

EndFunction

// Parameters:
//   Filter - Filter - an arbitrary filter.
//   ItemKey - String - filter item name.
//   ItemValue - Arbitrary - filter item value.
//
Procedure SetFilterItemValue(Filter, ItemKey, ItemValue)

	FilterItem = Filter.Find(ItemKey);
	If FilterItem <> Undefined Then
		FilterItem.Set(ItemValue);
	EndIf;

EndProcedure

#EndRegion

#Region DataExportProcedures

Function GetDocumentRegisterRecordSet(DocumentRef, SourceKind, RegisterName)
	
	If SourceKind = "AccumulationRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = AccumulationRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "InformationRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = InformationRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "AccountingRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = AccountingRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "CalculationRegisterRecordSet" Then	
		
		DocumentRegisterRecordSet = CalculationRegisters[RegisterName].CreateRecordSet();
		
	Else
		
		Return Undefined;
		
	EndIf;

	SetFilterItemValue(DocumentRegisterRecordSet.Filter, "Recorder", DocumentRef);
	DocumentRegisterRecordSet.Read();
	
	Return DocumentRegisterRecordSet;
	
EndFunction

Procedure WriteStructureToXML(DataStructure, PropertyCollectionNode)
	
	PropertyCollectionNode.WriteStartElement("Property");
	
	For Each CollectionItem In DataStructure Do
		
		If CollectionItem.Key = "Expression" Or CollectionItem.Key = "Value" Or CollectionItem.Key = "Sn" Or CollectionItem.Key = "Gsn" Then
			
			deWriteElement(PropertyCollectionNode, CollectionItem.Key, CollectionItem.Value);
			
		ElsIf CollectionItem.Key = "Ref" Then
			
			PropertyCollectionNode.WriteRaw(CollectionItem.Value);
			
		Else
			
			SetAttribute(PropertyCollectionNode, CollectionItem.Key, CollectionItem.Value);
			
		EndIf;
		
	EndDo;
	
	PropertyCollectionNode.WriteEndElement();		
	
EndProcedure

Procedure CreateObjectsForXMLWriter(DataStructure, PropertyNode, XMLNodeRequired, NodeName, XMLNodeDescription = "Property")
	
	If XMLNodeRequired Then
		
		PropertyNode = CreateNode(XMLNodeDescription);
		SetAttribute(PropertyNode, "Name", NodeName);
		
	Else
		
		DataStructure = New Structure("Name", NodeName);	
		
	EndIf;		
	
EndProcedure

Procedure AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		SetAttribute(PropertyNode, AttributeName, AttributeValue);
	EndIf;
	
EndProcedure

Procedure WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode)
	
	If PropertyNodeStructure <> Undefined Then
		WriteStructureToXML(PropertyNodeStructure, PropertyCollectionNode);
	Else
		AddSubordinateNode(PropertyCollectionNode, PropertyNode);
	EndIf;
	
EndProcedure

// Generates destination object property nodes according to the specified property conversion rule collection.
//
// Parameters:
//  Source		 - an arbitrary data source.
//  Destination		 - a destination object XML node.
//  IncomingData	 - an arbitrary auxiliary data that is passed to the conversion rule.                       
//  OutgoingData - an arbitrary auxiliary data that is passed to the property object conversion rules.                       
//  OCR				     - a reference to the object conversion rule (property conversion rule collection parent).
//  PGCR                 - a reference to the property group conversion rule.
//  PropertyCollectionNode - property collection XML node.
//  ExportRefOnly - if True, object by reference will not be exported.
//  TempFileList - a list of temporary files to save an exported data.
// 
Procedure ExportPropertyGroup(Source, Destination, IncomingData, OutgoingData, OCR, PGCR, PropertyCollectionNode, 
	ExportRefOnly, TempFileList = Undefined)

	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	ObjectCollection = Undefined;
	DontReplace        = PGCR.DoNotReplace;
	DontClear         = False;
	ExportGroupToFile = PGCR.ExportGroupToFile;
	
	// BeforeProcessExport handler
	If PGCR.HasBeforeProcessExportHandler Then
		
		Cancel = False;
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(PGCR, "BeforeProcessExport"));
				
			Else
				
				Execute(PGCR.BeforeProcessExport);
				
			EndIf;
			
		Except
			
			WriteErrorInfoPCRHandlers(48, ErrorDescription(), OCR, PGCR,
				Source, "BeforeProcessPropertyGroupExport",, False);
		
		EndTry;
		
		If Cancel Then // Canceling property group processing.
			
			Return;
			
		EndIf;
		
	EndIf;
    DestinationKind = PGCR.DestinationKind;
	SourceKind = PGCR.SourceKind;
	
	
    // Creating a node of subordinate object collection.
	PropertyNodeStructure = Undefined;
	ObjectCollectionNode = Undefined;
	MasterNodeName = "";
	
	If DestinationKind = "TabularSection" Then
		
		MasterNodeName = "TabularSection";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, True, PGCR.Destination, MasterNodeName);
		
		If DontReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotReplace", "true");
						
		EndIf;
		
		If DontClear Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotClear", "true");
						
		EndIf;
		
	ElsIf DestinationKind = "SubordinateCatalog" Then
	ElsIf DestinationKind = "SequenceRecordSet" Then
		
		MasterNodeName = "RecordSet";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, True, PGCR.Destination, MasterNodeName);

	ElsIf StrFind(DestinationKind, "RecordSet") > 0 Then
		
		MasterNodeName = "RecordSet";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, True, PGCR.Destination, MasterNodeName);
		
		If DontReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotReplace", "true");
						
		EndIf;
		
		If DontClear Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "DoNotClear", "true");
						
		EndIf;

	Else  // Simple group
		
		ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, PGCR.GroupRules, 
		     PropertyCollectionNode, , , OCR.DoNotExportPropertyObjectsByRefs OR ExportRefOnly);
			
		If PGCR.HasAfterProcessExportHandler Then
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PGCR, "AfterProcessExport"));
					
				Else
					
					Execute(PGCR.AfterProcessExport);
			
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(49, ErrorDescription(), OCR, PGCR,
					Source, "AfterProcessPropertyGroupExport",, False);
				
			EndTry;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	// Getting the collection of subordinate objects.
	
	If ObjectCollection <> Undefined Then
		
		// The collection was initialized in the BeforeProcess handler.
		
	ElsIf PGCR.GetFromIncomingData Then
		
		Try
			
			ObjectCollection = IncomingData[PGCR.Destination];
			
			If TypeOf(ObjectCollection) = Type("QueryResult") Then
				
				ObjectCollection = ObjectCollection.Unload();
				
			EndIf;
			
		Except
			
			WriteErrorInfoPCRHandlers(66, ErrorDescription(), OCR, PGCR, Source,,,False);
			
			Return;
		EndTry;

	ElsIf SourceKind = "TabularSection" Then
		
		ObjectCollection = Source[PGCR.Source];
		
		If TypeOf(ObjectCollection) = Type("QueryResult") Then
			
			ObjectCollection = ObjectCollection.Unload();
			
		EndIf;
		
	ElsIf SourceKind = "SubordinateCatalog" Then
		
	ElsIf StrFind(SourceKind, "RecordSet") > 0 Then
		
		ObjectCollection = GetDocumentRegisterRecordSet(Source, SourceKind, PGCR.Source);
				
	ElsIf IsBlankString(PGCR.Source) Then
		
		ObjectCollection = Source[PGCR.Destination];
		
		If TypeOf(ObjectCollection) = Type("QueryResult") Then
			
			ObjectCollection = ObjectCollection.Unload();
			
		EndIf;
		
	EndIf;

	ExportGroupToFile = ExportGroupToFile Or (ObjectCollection.Count() > 1000);
	ExportGroupToFile = ExportGroupToFile AND (DirectReadFromDestinationIB = False);

	If ExportGroupToFile Then
		
		PGCR.XMLNodeRequiredOnExport = False;
		
		If TempFileList = Undefined Then
			TempFileList = New Array;
		EndIf;
		
		RecordsTemporaryFile = WriteTextToTemporaryFile(TempFileList);
		
		InformationToWriteToFile = ObjectCollectionNode.Close();
		RecordsTemporaryFile.WriteLine(InformationToWriteToFile);
		
	EndIf;

	For Each CollectionObject In ObjectCollection Do
		
		// BeforeExport handler
		If PGCR.HasBeforeExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PGCR, "BeforeExport"));
					
				Else
					
					Execute(PGCR.BeforeExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(50, ErrorDescription(), OCR, PGCR,
					Source, "BeforeExportPropertyGroup",, False);
				
				Break;
				
			EndTry;
			
			If Cancel Then	//	Cancel subordinate object export.
			
				Continue;
				
			EndIf;
			
		EndIf;
		
		// OnExport handler
		
		If PGCR.XMLNodeRequiredOnExport OR ExportGroupToFile Then
			CollectionObjectNode = CreateNode("Record");
		Else
			ObjectCollectionNode.WriteStartElement("Record");
			CollectionObjectNode = ObjectCollectionNode;
		EndIf;
		
		StandardProcessing	= True;
		
		If PGCR.HasOnExportHandler Then
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PGCR, "OnExport"));
					
				Else
					
					Execute(PGCR.OnExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(51, ErrorDescription(), OCR, PGCR,
					Source, "OnExportPropertyGroup",, False);
				
				Break;
				
			EndTry;
			
		EndIf;

		//	Export the collection object properties.
		
		If StandardProcessing Then
			
			If PGCR.GroupRules.Count() > 0 Then
				
		 		ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, PGCR.GroupRules, 
		 			CollectionObjectNode, CollectionObject, , OCR.DoNotExportPropertyObjectsByRefs OR ExportRefOnly);
				
			EndIf;
			
		EndIf;
		
		// AfterExport handler
		
		If PGCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PGCR, "AfterExport"));
					
				Else
					
					Execute(PGCR.AfterExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(52, ErrorDescription(), OCR, PGCR,
					Source, "AfterExportPropertyGroup",, False);
				
				Break;
			EndTry; 
			
			If Cancel Then	//	Cancel subordinate object export.
				
				Continue;
				
			EndIf;
			
		EndIf;

		If PGCR.XMLNodeRequiredOnExport Then
			AddSubordinateNode(ObjectCollectionNode, CollectionObjectNode);
		EndIf;
		
		// Filling the file with node objects.
		If ExportGroupToFile Then
			
			CollectionObjectNode.WriteEndElement();
			InformationToWriteToFile = CollectionObjectNode.Close();
			RecordsTemporaryFile.WriteLine(InformationToWriteToFile);
			
		Else
			
			If Not PGCR.XMLNodeRequiredOnExport Then
				
				ObjectCollectionNode.WriteEndElement();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	
    // AfterProcessExport handler

	If PGCR.HasAfterProcessExportHandler Then
		
		Cancel = False;
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(PGCR, "AfterProcessExport"));
				
			Else
				
				Execute(PGCR.AfterProcessExport);
				
			EndIf;
			
		Except
			
			WriteErrorInfoPCRHandlers(49, ErrorDescription(), OCR, PGCR,
				Source, "AfterProcessPropertyGroupExport",, False);
			
		EndTry;
		
		If Cancel Then	//	Cancel subordinate object collection writing.
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If ExportGroupToFile Then
		RecordsTemporaryFile.WriteLine("</" + MasterNodeName + ">"); // Closing the node
		RecordsTemporaryFile.Close(); 	// Closing the file
	Else
		WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, ObjectCollectionNode);
	EndIf;

EndProcedure

Procedure GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source)
	
	If Value <> Undefined Then
		Return;
	EndIf;
	
	If PCR.GetFromIncomingData Then
			
			ObjectForReceivingData = IncomingData;
			
			If Not IsBlankString(PCR.Destination) Then
			
				PropertyName = PCR.Destination;
				
			Else
				
				PropertyName = PCR.ParameterForTransferName;
				
			EndIf;
			
			ErrorCode = ?(CollectionObject <> Undefined, 67, 68);
	
	ElsIf CollectionObject <> Undefined Then
		
		ObjectForReceivingData = CollectionObject;
		
		If Not IsBlankString(PCR.Source) Then
			
			PropertyName = PCR.Source;
			ErrorCode = 16;
						
		Else
			
			PropertyName = PCR.Destination;
			ErrorCode = 17;
			
		EndIf;

	Else
		
		ObjectForReceivingData = Source;
		
		If Not IsBlankString(PCR.Source) Then
		
			PropertyName = PCR.Source;
			ErrorCode = 13;
		
		Else
			
			PropertyName = PCR.Destination;
			ErrorCode = 14;
			
		EndIf;
		
	EndIf;
	
	Try
		
		Value = ObjectForReceivingData[PropertyName];
		
	Except
		
		If ErrorCode <> 14 Then
			WriteErrorInfoPCRHandlers(ErrorCode, ErrorDescription(), OCR, PCR, Source, "");
		EndIf;
		
	EndTry;
	
EndProcedure

Procedure ExportItemPropertyType(PropertyNode, PropertyType)
	
	SetAttribute(PropertyNode, "Type", PropertyType);	
	
EndProcedure

Procedure ExportExtDimension(Source, Destination, IncomingData, OutgoingData, OCR, PCR, PropertyCollectionNode,
							CollectionObject, Val ExportRefOnly)
	
	// Variables for supporting the event handler script debugging mechanism. (supporting the bind 
	// procedure interface).
	Var DestinationType, Empty, Expression, DontReplace, PropertyNode, PropertiesOCR;
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	// Initializing the value
	Value = Undefined;
	OCRName = "";
	OCRNameExtDimensionType = "";
	
	// BeforeExport handler
	If PCR.HasBeforeExportHandler Then
		
		Cancel = False;
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(PCR, "BeforeExport"));
				
			Else
				
				Execute(PCR.BeforeExport);
				
			EndIf;
			
		Except
			
			WriteErrorInfoPCRHandlers(55, ErrorDescription(), OCR, PCR, Source, 
				"BeforeExportProperty", Value);
				
		EndTry;
			
		If Cancel Then // Cancel the export
			
			Return;
			
		EndIf;
		
	EndIf;

	GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source);
	
	If PCR.CastToLength <> 0 Then
		
		CastValueToLength(Value, PCR);
		
	EndIf;

	For Each KeyAndValue In Value Do

		ExtDimensionType = KeyAndValue.Key;
		ExtDimension = KeyAndValue.Value;
		OCRName = "";
		
		// OnExport handler
		If PCR.HasOnExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PCR, "OnExport"));
					
				Else
					
					Execute(PCR.OnExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(56, ErrorDescription(), OCR, PCR, Source, 
					"OnExportProperty", Value);
				
			EndTry;
				
			If Cancel Then // Cancel the extra dimension export
				
				Continue;
				
			EndIf;
			
		EndIf;

		If ExtDimension = Undefined Or FindRule(ExtDimension, OCRName) = Undefined Then
			
			Continue;
			
		EndIf;
			
		ExtDimensionNode = CreateNode(PCR.Destination);
		
		// Key
		PropertyNode = CreateNode("Property");
		
		If IsBlankString(OCRNameExtDimensionType) Then
			
			OCRKey = FindRule(ExtDimensionType, OCRNameExtDimensionType);
			
		Else
			
			OCRKey = FindRule(, OCRNameExtDimensionType);
			
		EndIf;
		
		SetAttribute(PropertyNode, "Name", "Key");
		ExportItemPropertyType(PropertyNode, OCRKey.Destination);
			
		RefNode = ExportByRule(ExtDimensionType,, OutgoingData,, OCRNameExtDimensionType,, ExportRefOnly, OCRKey);
			
		If RefNode <> Undefined Then
			
			IsRuleWithGlobalExport = False;
			RefNodeType = TypeOf(RefNode);
			AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport);
			
		EndIf;
		
		AddSubordinateNode(ExtDimensionNode, PropertyNode);
		
		// Value
		PropertyNode = CreateNode("Property");
		
		OCRValue = FindRule(ExtDimension, OCRName);
		
		DestinationType = OCRValue.Destination;
		
		IsNULL = False;
		Empty = deEmpty(ExtDimension, IsNULL);

		If Empty Then
			
			If IsNULL Or ExtDimension = Undefined Then
				
				Continue;
				
			EndIf;
			
			If IsBlankString(DestinationType) Then
				
				DestinationType = GetDataTypeForDestination(ExtDimension);
				
			EndIf;
			
			SetAttribute(PropertyNode, "Name", "Value");
			
			If Not IsBlankString(DestinationType) Then
				SetAttribute(PropertyNode, "Type", DestinationType);
			EndIf;
			
			// If it is a variable of multiple type, it must be exported with the specified type, perhaps this is an empty reference.
			deWriteElement(PropertyNode, "Empty");
			
			AddSubordinateNode(ExtDimensionNode, PropertyNode);

		Else
			
			IsRuleWithGlobalExport = False;
			RefNode = ExportByRule(ExtDimension,, OutgoingData, , OCRName, , ExportRefOnly, OCRValue, IsRuleWithGlobalExport);
			
			SetAttribute(PropertyNode, "Name", "Value");
			ExportItemPropertyType(PropertyNode, DestinationType);
			
			If RefNode = Undefined Then
				
				Continue;
				
			EndIf;
			
			RefNodeType = TypeOf(RefNode);
			
			AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport);
			
			AddSubordinateNode(ExtDimensionNode, PropertyNode);
			
		EndIf;
		
		// AfterExport handler
		If PCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PCR, "AfterExport"));
					
				Else
					
					Execute(PCR.AfterExport);
					
				EndIf;
					
			Except
					
				WriteErrorInfoPCRHandlers(57, ErrorDescription(), OCR, PCR, Source,
					"AfterExportProperty", Value);
					
			EndTry;
			
			If Cancel Then // Cancel the export
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		AddSubordinateNode(PropertyCollectionNode, ExtDimensionNode);
		
	EndDo;
	
EndProcedure

Procedure AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport)
	
	If RefNodeType = deStringType Then
				
		If StrFind(RefNode, "<Ref") > 0 Then
					
			PropertyNode.WriteRaw(RefNode);
					
		Else
			
			deWriteElement(PropertyNode, "Value", RefNode);
					
		EndIf;
				
	ElsIf RefNodeType = deNumberType Then
		
		If IsRuleWithGlobalExport Then
		
			deWriteElement(PropertyNode, "Gsn", RefNode);
			
		Else     		
			
			deWriteElement(PropertyNode, "Sn", RefNode);
			
		EndIf;
				
	Else
				
		AddSubordinateNode(PropertyNode, RefNode);
				
	EndIf;	
	
EndProcedure

Procedure AddPropertyValueToNode(Value, ValueType, DestinationType, PropertyNode, PropertyIsSet)
	
	PropertyIsSet = True;
		
	If ValueType = deStringType Then
				
		If DestinationType = "String"  Then
		ElsIf DestinationType = "Number"  Then
					
			Value = Number(Value);
					
		ElsIf DestinationType = "Boolean"  Then
					
			Value = Boolean(Value);
					
		ElsIf DestinationType = "Date"  Then
					
			Value = Date(Value);
					
		ElsIf DestinationType = "ValueStorage"  Then
					
			Value = New ValueStorage(Value);
					
		ElsIf DestinationType = "UUID" Then
					
			Value = New UUID(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			SetAttribute(PropertyNode, "Type", "String");
					
		EndIf;
				
		deWriteElement(PropertyNode, "Value", Value);

	ElsIf ValueType = deNumberType Then
				
		If DestinationType = "Number"  Then
		ElsIf DestinationType = "Boolean"  Then
					
			Value = Boolean(Value);
					
		ElsIf DestinationType = "String"  Then
		ElsIf IsBlankString(DestinationType) Then
					
			SetAttribute(PropertyNode, "Type", "Number");
					
		Else
					
			Return;
					
		EndIf;
				
		deWriteElement(PropertyNode, "Value", Value);

	ElsIf ValueType = deDateType Then
				
		If DestinationType = "Date"  Then
		ElsIf DestinationType = "String"  Then
					
			Value = Left(String(Value), 10);
					
		ElsIf IsBlankString(DestinationType) Then
					
			SetAttribute(PropertyNode, "Type", "Date");
					
		Else
					
			Return;
					
		EndIf;
				
		deWriteElement(PropertyNode, "Value", Value);
				
	ElsIf ValueType = deBooleanType Then
				
		If DestinationType = "Boolean"  Then
		ElsIf DestinationType = "Number"  Then
					
			Value = Number(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			SetAttribute(PropertyNode, "Type", "Boolean");
					
		Else
					
			Return;
					
		EndIf;
				
		deWriteElement(PropertyNode, "Value", Value);

	ElsIf ValueType = deValueStorageType Then
				
		If IsBlankString(DestinationType) Then
					
			SetAttribute(PropertyNode, "Type", "ValueStorage");
					
		ElsIf DestinationType <> "ValueStorage"  Then
					
			Return;
					
		EndIf;
				
		deWriteElement(PropertyNode, "Value", Value);
				
	ElsIf ValueType = deUUIDType Then
		
		If DestinationType = "UUID" Then
		ElsIf DestinationType = "String"  Then
					
			Value = String(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			SetAttribute(PropertyNode, "Type", "UUID");
					
		Else
					
			Return;
					
		EndIf;
		
		deWriteElement(PropertyNode, "Value", Value);
		
	ElsIf ValueType = deAccumulationRecordTypeType Then
				
		deWriteElement(PropertyNode, "Value", String(Value));		
		
	Else	
		
		PropertyIsSet = False;
		
	EndIf;	
	
EndProcedure

Function ExportRefObjectData(Value, OutgoingData, OCRName, PropertiesOCR, DestinationType, PropertyNode, Val ExportRefOnly)
	
	IsRuleWithGlobalExport = False;
	RefNode    = ExportByRule(Value, , OutgoingData, , OCRName, , ExportRefOnly, PropertiesOCR, IsRuleWithGlobalExport);
	RefNodeType = TypeOf(RefNode);

	If IsBlankString(DestinationType) Then
				
		DestinationType  = PropertiesOCR.Destination;
		SetAttribute(PropertyNode, "Type", DestinationType);
				
	EndIf;
			
	If RefNode = Undefined Then
				
		Return Undefined;
				
	EndIf;
				
	AddPropertiesForExport(RefNode, RefNodeType, PropertyNode, IsRuleWithGlobalExport);	
	
	Return RefNode;
	
EndFunction

Function GetDataTypeForDestination(Value)
	
	DestinationType = deValueTypeAsString(Value);
	
	// Checking for any OCR with the DestinationType destination type.
	TableRow = ConversionRulesTable.Find(DestinationType, "Destination");
	
	If TableRow = Undefined Then
		DestinationType = "";
	EndIf;
	
	Return DestinationType;
	
EndFunction

Procedure CastValueToLength(Value, PCR)
	
	Value = CastNumberToLength(String(Value), PCR.CastToLength);
		
EndProcedure

// Generates destination object property nodes according to the specified property conversion rule collection.
//
// Parameters:
//  Source		     - Arbitrary - an arbitrary data source.
//  Destination		     - XMLWriter - a destination object XML node.
//  IncomingData	     - Arbitrary - an arbitrary auxiliary data that is passed to the conversion rule.
//  OutgoingData      - Arbitrary - an arbitrary auxiliary data that is passed to the property object conversion rules.
//  OCR				     - ValueTableRow - a reference to the object conversion rule.
//  PCRCollection         - see PropertyConversionRulesCollection.
//  PropertyCollectionNode - XMLWriter - a property collection XML node.
//  CollectionObject      - Arbitrary - if not Undefined, collection object properties are exported, otherwise source object properties are exported.
//  PredefinedItemName - String - if not Undefined, the predefined item name is written to the properties.
//  ExportRefOnly      - Boolean  - if True, object by reference is not exported.
//  TempFileList		- Array - a list of temporary files to save an exported data.
// 
Procedure ExportProperties(Source, Destination, IncomingData, OutgoingData, OCR, PCRCollection, PropertyCollectionNode = Undefined, 
	CollectionObject = Undefined, PredefinedItemName = Undefined, Val ExportRefOnly = False, 
	TempFileList = Undefined)
	
	Var KeyAndValue, ExtDimensionType, ExtDimension, OCRNameExtDimensionType, ExtDimensionNode; // for correct handler execution.

	If PropertyCollectionNode = Undefined Then
		
		PropertyCollectionNode = Destination;
		
	EndIf;
	
	// Exporting the predefined item name if it is specified.
	If PredefinedItemName <> Undefined Then
		
		PropertyCollectionNode.WriteStartElement("Property");
		SetAttribute(PropertyCollectionNode, "Name", "{PredefinedItemName}");
		If Not ExecuteDataExchangeInOptimizedFormat Then
			SetAttribute(PropertyCollectionNode, "Type", "String");
		EndIf;
		deWriteElement(PropertyCollectionNode, "Value", PredefinedItemName);
		PropertyCollectionNode.WriteEndElement();		
		
	EndIf;

	For each PCR In PCRCollection Do
		
		If PCR.SimplifiedPropertyExport Then
						
			 //	Creating the property node
			 
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", PCR.Destination);
			
			If Not ExecuteDataExchangeInOptimizedFormat And Not IsBlankString(PCR.DestinationType) Then
			
				SetAttribute(PropertyCollectionNode, "Type", PCR.DestinationType);
				
			EndIf;
			
			If PCR.DoNotReplace Then
				
				SetAttribute(PropertyCollectionNode, "DoNotReplace",	"true");
				
			EndIf;
			
			If PCR.SearchByEqualDate  Then
				
				SetAttribute(PropertyCollectionNode, "SearchByEqualDate", "true");
				
			EndIf;
			
			Value = Undefined;
			GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source);
			
			If PCR.CastToLength <> 0 Then
				
				CastValueToLength(Value, PCR);
								
			EndIf;
			
			IsNULL = False;
			Empty = deEmpty(Value, IsNULL);

			If Empty Then
				
				If Not ExecuteDataExchangeInOptimizedFormat Then
					deWriteElement(PropertyCollectionNode, "Empty");
				EndIf;
				
				PropertyCollectionNode.WriteEndElement();
				Continue;
				
			EndIf;
			
			deWriteElement(PropertyCollectionNode,	"Value", Value);
			
			PropertyCollectionNode.WriteEndElement();
			Continue;

		ElsIf PCR.DestinationKind = "AccountExtDimensionTypes" Then
			
			ExportExtDimension(Source, Destination, IncomingData, OutgoingData, OCR,
				PCR, PropertyCollectionNode, CollectionObject, ExportRefOnly);
			
			Continue;

		ElsIf PCR.Name = "{UUID}" And PCR.Source = "{UUID}" And PCR.Destination = "{UUID}" Then
			
			If Source = Undefined Then
				Continue;
			EndIf;
			
			If RefTypeValue(Source) Then
				UUID = Source.UUID();
			Else
				
				InitialValue = New UUID();
				StructureToCheckPropertyExisting = New Structure("Ref", InitialValue);
				FillPropertyValues(StructureToCheckPropertyExisting, Source);
				
				If InitialValue <> StructureToCheckPropertyExisting.Ref And RefTypeValue(StructureToCheckPropertyExisting.Ref) Then
					UUID = Source.Ref.UUID();
				EndIf;
				
			EndIf;

			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", "{UUID}");
			
			If NOT ExecuteDataExchangeInOptimizedFormat Then 
				SetAttribute(PropertyCollectionNode, "Type", "String");
			EndIf;
			
			deWriteElement(PropertyCollectionNode, "Value", UUID);
			PropertyCollectionNode.WriteEndElement();
			Continue;
			
		ElsIf PCR.IsGroup Then
			
			ExportPropertyGroup(Source, Destination, IncomingData, OutgoingData, OCR, PCR, PropertyCollectionNode, ExportRefOnly, TempFileList);
			Continue;
			
		EndIf;

		
		//	Initializing the value to be converted.
		Value 	 = Undefined;
		OCRName		 = PCR.ConversionRule;
		DontReplace   = PCR.DoNotReplace;
		
		Empty		 = False;
		Expression	 = Undefined;
		DestinationType = PCR.DestinationType;

		IsNULL      = False;

		
		// BeforeExport handler
		If PCR.HasBeforeExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PCR, "BeforeExport"));
					
				Else
					
					Execute(PCR.BeforeExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(55, ErrorDescription(), OCR, PCR, Source, 
						"BeforeExportProperty", Value);
														
			EndTry;
				                             
			If Cancel Then	//	Cancel property export
				
				Continue;
				
			EndIf;
			
		EndIf;

        		
        //	Creating the property node
		If IsBlankString(PCR.ParameterForTransferName) Then
			
			PropertyNode = CreateNode("Property");
			SetAttribute(PropertyNode, "Name", PCR.Destination);
			
		Else
			
			PropertyNode = CreateNode("ParameterValue");
			SetAttribute(PropertyNode, "Name", PCR.ParameterForTransferName);
			
		EndIf;
		
		If DontReplace Then
			
			SetAttribute(PropertyNode, "DoNotReplace",	"true");
			
		EndIf;
		
		If PCR.SearchByEqualDate  Then
			
			SetAttribute(PropertyCollectionNode, "SearchByEqualDate", "true");
			
		EndIf;

        		
		If Not IsBlankString(OCRName) Then
			
			PropertiesOCR = Rules[OCRName];
			
		Else
			
			PropertiesOCR = Undefined;
			
		EndIf;


		//	Attempting to define a destination property type.
		If IsBlankString(DestinationType) And PropertiesOCR <> Undefined Then
			
			DestinationType = PropertiesOCR.Destination;
			SetAttribute(PropertyNode, "Type", DestinationType);
			
		ElsIf Not ExecuteDataExchangeInOptimizedFormat And Not IsBlankString(DestinationType) Then
			
			SetAttribute(PropertyNode, "Type", DestinationType);
						
		EndIf;
		
		If Not IsBlankString(OCRName) And PropertiesOCR <> Undefined And PropertiesOCR.HasSearchFieldSequenceHandler = True Then
			
			SetAttribute(PropertyNode, "OCRName", OCRName);
			
		EndIf;
		
        //	Determining the value to be converted.
		If Expression <> Undefined Then
			
			deWriteElement(PropertyNode, "Expression", Expression);
			AddSubordinateNode(PropertyCollectionNode, PropertyNode);
			Continue;
			
		ElsIf Empty Then
			
			If IsBlankString(DestinationType) Then
				
				Continue;
				
			EndIf;
			
			If NOT ExecuteDataExchangeInOptimizedFormat Then 
				deWriteElement(PropertyNode, "Empty");
			EndIf;
			
			AddSubordinateNode(PropertyCollectionNode, PropertyNode);
			Continue;
			
		Else
			
			GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source);
			
			If PCR.CastToLength <> 0 Then
				
				CastValueToLength(Value, PCR);
								
			EndIf;
						
		EndIf;
		OldValueBeforeOnExportHandler = Value;
		Empty = deEmpty(Value, IsNULL);

		
		// OnExport handler
		If PCR.HasOnExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PCR, "OnExport"));
					
				Else
					
					Execute(PCR.OnExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(56, ErrorDescription(), OCR, PCR, Source, 
						"OnExportProperty", Value);
														
			EndTry;
				
			If Cancel Then	//	Cancel property export
				
				Continue;
				
			EndIf;
			
		EndIf;


		// Initializing the Empty variable, perhaps its value has been changed in the OnExport handler.
		If OldValueBeforeOnExportHandler <> Value Then
			
			Empty = deEmpty(Value, IsNULL);
			
		EndIf;

		If Empty Then
			
			If IsNULL Or Value = Undefined Then
				
				Continue;
				
			EndIf;
			
			If IsBlankString(DestinationType) Then
				
				DestinationType = GetDataTypeForDestination(Value);
				
				If Not IsBlankString(DestinationType) Then				
				
					SetAttribute(PropertyNode, "Type", DestinationType);
				
				EndIf;
				
			EndIf;			
				
			// If it is a variable of multiple type, it must be exported with the specified type.
			If Not ExecuteDataExchangeInOptimizedFormat Then
				deWriteElement(PropertyNode, "Empty");
			EndIf;
			
			AddSubordinateNode(PropertyCollectionNode, PropertyNode);
			Continue;
			
		EndIf;	
		RefNode = Undefined;

		If (PropertiesOCR <> Undefined) Or (Not IsBlankString(OCRName)) Then
			
			RefNode = ExportRefObjectData(Value, OutgoingData, OCRName, PropertiesOCR, DestinationType, PropertyNode, ExportRefOnly);
			
			If RefNode = Undefined Then
				Continue;				
			EndIf;				
										
		Else
			
			PropertySet = False;
			ValueType = TypeOf(Value);
			AddPropertyValueToNode(Value, ValueType, DestinationType, PropertyNode, PropertySet);
						
			If Not PropertySet Then
				
				ValueManager = Managers[ValueType];
				
				If ValueManager = Undefined Then
					Continue;
				EndIf;
				
				PropertiesOCR = ValueManager.OCR;
				
				If PropertiesOCR = Undefined Then
					Continue;
				EndIf;
				
				OCRName = PropertiesOCR.Name;
				
				RefNode = ExportRefObjectData(Value, OutgoingData, OCRName, PropertiesOCR, DestinationType, PropertyNode, ExportRefOnly);
			
				If RefNode = Undefined Then
					Continue;				
				EndIf;				
												
			EndIf;
			
		EndIf;


		
		// AfterExport handler

		If PCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(PCR, "AfterExport"));
					
				Else
					
					Execute(PCR.AfterExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(57, ErrorDescription(), OCR, PCR, Source, 
						"AfterExportProperty", Value);					
				
			EndTry;
				
			If Cancel Then	//	Cancel property export
				
				Continue;
				
			EndIf;
			
		EndIf;		
		AddSubordinateNode(PropertyCollectionNode, PropertyNode);
		
	EndDo;

EndProcedure

// Exports the selection object according to the specified rule.
//
// Parameters:
//  Object - selection object to be exported.
//  Rule - data export rule reference.
//  Properties - metadata object properties of the object to be exported.
//  IncomingData - arbitrary auxiliary data.
//  SelectionForDataExport - a selection containing data for export.
// 
Procedure ExportSelectionObject(Object, Rule, Properties=Undefined, IncomingData=Undefined, SelectionForDataExport = Undefined)

	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	If CommentObjectProcessingFlag Then
		
		TypeDescription = New TypeDescription("String");
		StringObject  = TypeDescription.AdjustValue(Object);
		If Not IsBlankString(StringObject) Then
			ObjectRule   = StringObject + "  (" + TypeOf(Object) + ")";
		Else
			ObjectRule   = TypeOf(Object);
		EndIf;
		
		MessageString = SubstituteParametersToString(NStr("ru = 'Выгрузка объекта: %1'; en = 'Exporting object: %1'"), ObjectRule);
		WriteToExecutionLog(MessageString, , False, 1, 7);
		
	EndIf;

	OCRName			= Rule.ConversionRule;
	Cancel			= False;
	OutgoingData	= Undefined;
	
	// BeforeExportObject global handler.
	If HasBeforeExportObjectGlobalHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Conversion, "BeforeExportObject"));
				
			Else
				
				Execute(Conversion.BeforeExportObject);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(65, ErrorDescription(), Rule.Name, "BeforeExportSelectionObject (global)", Object);
		EndTry;
			
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	// BeforeExport handler
	If Not IsBlankString(Rule.BeforeExport) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "BeforeExport"));
				
			Else
				
				Execute(Rule.BeforeExport);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(33, ErrorDescription(), Rule.Name, "BeforeExportSelectionObject", Object);
		EndTry;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;

	RefNode = Undefined;
	
	ExportByRule(Object, , OutgoingData, , OCRName, RefNode, , , , SelectionForDataExport);
	
	// AfterExportObject global handler.
	If HasAfterExportObjectGlobalHandler Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Conversion, "AfterExportObject"));
				
			Else
				
				Execute(Conversion.AfterExportObject);
			
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(69, ErrorDescription(), Rule.Name, "AfterExportSelectionObject (global)", Object);
		EndTry;
		
	EndIf;
	
	// AfterExport handler
	If Not IsBlankString(Rule.AfterExport) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "AfterExport"));
				
			Else
				
				Execute(Rule.AfterExport);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(34, ErrorDescription(), Rule.Name, "AfterExportSelectionObject", Object);
		EndTry;
		
	EndIf;
	
EndProcedure

// Parameters:
//   ObjectMetadata - MetadataObject -
//
Function GetFirstMetadataAttributeName(ObjectMetadata)

	AttributeSet = ObjectMetadata.Attributes; // MetadataObjectCollection

	If AttributeSet.Count() = 0 Then
		Return "";
	EndIf;

	Return AttributeSet.Get(0).Name;

EndFunction

Function GetSelectionForExportWithRestrictions(Rule, SelectionForSubstitutionToOCR = Undefined, Properties = Undefined)
	
	MetadataName           = Rule.ObjectNameForQuery;
	
	PermissionString = ?(ExportAllowedObjectsOnly, " ALLOWED ", "");

	SelectionFields = "";
	
	IsRegisterExport = (Rule.ObjectNameForQuery = Undefined);

	If IsRegisterExport Then
		
		Nonperiodic = Not Properties.Periodic;
		SubordinateToRecorder = Properties.SubordinateToRecorder;
		
		SelectionFieldSupplementionStringSubordinateToRecorder = ?(Not SubordinateToRecorder, ", NULL AS Active,
		|	NULL AS Recorder,
		|	NULL AS LineNumber", "");

		SelectionFieldSupplementionStringPeriodicity = ?(Nonperiodic, ", NULL AS Period", "");
		
		ResultingRestrictionByDate = GetRestrictionByDateStringForQuery(Properties, Properties.TypeName, 
			Rule.ObjectNameForRegisterQuery, False);

		ReportBuilder.Text = "SELECT " + PermissionString 
			+ "|	*
				 |
				 | " + SelectionFieldSupplementionStringSubordinateToRecorder 
			 + " | " + SelectionFieldSupplementionStringPeriodicity 
			 + " |
				 | FROM " + Rule.ObjectNameForRegisterQuery
			+ " |
				 |" + ResultingRestrictionByDate;		
				 
		ReportBuilder.FillSettings();

	Else
		
		If Rule.SelectExportDataInSingleQuery Then
		
			SelectionFields = "*";
			
		Else
			
			SelectionFields = "Ref AS Ref";
			
		EndIf;
		
		ResultingRestrictionByDate = GetRestrictionByDateStringForQuery(Properties, Properties.TypeName,, False);
		
		ReportBuilder.Text = "SELECT " + PermissionString + " " + SelectionFields + " FROM " + MetadataName + "
		|
		|" + ResultingRestrictionByDate + "
		|
		|{WHERE Ref.* AS " + StrReplace(MetadataName, ".", "_") + "}";
		
	EndIf;

	ReportBuilder.Filter.Reset();
	//UT++
	//		
//	If Rule.BuilderSettings <> Undefined Then
//		ReportBuilder.SetSettings(Rule.BuilderSettings);
//	EndIf;

	If Rule.Filter <> Undefined Then
		NewQueryText = GetRowQueryText(Rule, Rule.Filter <> Undefined, "*");

		DataCompositionSchema = DataCompositionSchema(NewQueryText);
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
		UT_CommonClientServer.CopyItems(SettingsComposer.Settings.Filter, Rule.Filter);
		SetResultOutputStructureSettings(SettingsComposer.Settings);

		UT_CommonClientServer.SetDCSParemeterValue(SettingsComposer, "StartDate", StartDate);
		UT_CommonClientServer.SetDCSParemeterValue(SettingsComposer, "EndDate",
			EndDate);

		DetailsData = New DataCompositionDetailsData;
		TemplateComposer = New DataCompositionTemplateComposer;

		DataCompositionTemplate = TemplateComposer.Execute( DataCompositionSchema, SettingsComposer.Settings,
			DetailsData, , Type("DataCompositionTemplateGenerator"));
		TempQuery = New Query(DataCompositionTemplate.DataSets.DataSet1.Query);
		ReportBuilder.Text = TempQuery.Text;

		For Each Parameter In DataCompositionTemplate.ParameterValues Do
			ReportBuilder.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndDo;
	EndIf;
	//UT--

	ReportBuilder.Parameters.Insert("StartDate", StartDate);
	ReportBuilder.Parameters.Insert("EndDate", EndDate);

	ReportBuilder.Execute();
	Selection = ReportBuilder.Result.Select();
	
	If Rule.SelectExportDataInSingleQuery Then
		SelectionForSubstitutionToOCR = Selection;
	EndIf;
		
	Return Selection;
		
EndFunction

Function GetExportWithArbitraryAlgorithmSelection(DataSelection)
	
	Selection = Undefined;

	If TypeOf(DataSelection) = Type("QueryResultSelection") Then
				
		Selection = DataSelection;
		
	ElsIf TypeOf(DataSelection) = Type("QueryResult") Then
				
		Selection = DataSelection.Select();
					
	ElsIf TypeOf(DataSelection) = Type("Query") Then
				
		QueryResult = DataSelection.Execute();
		Selection          = QueryResult.Select();
									
	EndIf;
		
	Return Selection;	
	
EndFunction

Function GetConstantSetStringForExport(ConstantDataTableForExport)
	
	ConstantSetString = "";
	
	For Each TableRow In ConstantDataTableForExport Do
		
		If Not IsBlankString(TableRow.Source) Then
		
			ConstantSetString = ConstantSetString + ", " + TableRow.Source;
			
		EndIf;
		
	EndDo;	
	
	If Not IsBlankString(ConstantSetString) Then
		
		ConstantSetString = Mid(ConstantSetString, 3);
		
	EndIf;
	
	Return ConstantSetString;
	
EndFunction

Procedure ExportConstantSet(Rule, Properties, OutgoingData)
	
	If Properties.OCR <> Undefined Then
	
		ConstantSetNameString = GetConstantSetStringForExport(Properties.OCR.Properties);
		
	Else
		
		ConstantSetNameString = "";
		
	EndIf;
			
	ConstantsSet = Constants.CreateSet(ConstantSetNameString);
	ConstantsSet.Read();
	ExportSelectionObject(ConstantsSet, Rule, Properties, OutgoingData);	
	
EndProcedure

Function MustSelectAllFields(Rule)
	
	AllFieldsRequiredForSelection = Not IsBlankString(Conversion.BeforeExportObject)
		Or Not IsBlankString(Rule.BeforeExport) Or Not IsBlankString(Conversion.AfterExportObject)
		Or Not IsBlankString(Rule.AfterExport);		
		
	Return AllFieldsRequiredForSelection;	
	
EndFunction

// Exports data according to the specified rule.
//
// Parameters:
//  Rule - data export rule reference.
// 
Procedure ExportDataByRule(Rule)
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	OCRName = Rule.ConversionRule;
	
	If Not IsBlankString(OCRName) Then
		
		OCR = Rules[OCRName];
		
	EndIf;
	
	If CommentObjectProcessingFlag Then
		
		MessageString = SubstituteParametersToString(NStr("ru = 'Правило выгрузки данных: %1 (%2)'; en = 'Data export rule: %1 (%2)'"), 
			TrimAll(Rule.Name), TrimAll(Rule.Description));
		WriteToExecutionLog(MessageString, , False, , 4);
		
	EndIf;
	
	// BeforeProcess handle
	Cancel			= False;
	OutgoingData	= Undefined;
	DataSelection	= Undefined;

	If Not IsBlankString(Rule.BeforeProcess) Then
	
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "BeforeProcess"));
				
			Else
				
				Execute(Rule.BeforeProcess);
				
			EndIf;
			
		Except
			
			WriteErrorInfoDERHandlers(31, ErrorDescription(), Rule.Name, "BeforeProcessDataExport");
			
		EndTry;
		
		If Cancel Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// Standard selection with filter.
	If Rule.DataFilterMethod = "StandardSelection" AND Rule.UseFilter Then
		
		Properties	= Managers[Rule.SelectionObject];
		TypeName		= Properties.TypeName;
		
		SelectionForOCR = Undefined;
		Selection = GetSelectionForExportWithRestrictions(Rule, SelectionForOCR, Properties);
		
		IsNotReferenceType = TypeName =  "InformationRegister" Or TypeName = "AccountingRegister";
		
		While Selection.Next() Do
			
			If IsNotReferenceType Then
				ExportSelectionObject(Selection, Rule, Properties, OutgoingData);
			Else					
				ExportSelectionObject(Selection.Ref, Rule, Properties, OutgoingData, SelectionForOCR);
			EndIf;
			
		EndDo;
		
	// Standard selection without filter.
	ElsIf (Rule.DataFilterMethod = "StandardSelection") Then
		
		Properties	= Managers[Rule.SelectionObject];
		TypeName		= Properties.TypeName;
		
		If TypeName = "Constants" Then
			
			ExportConstantSet(Rule, Properties, OutgoingData);
			
		Else
			
			IsNotReferenceType = TypeName =  "InformationRegister" Or TypeName = "AccountingRegister";
			
			If IsNotReferenceType Then
					
				SelectAllFields = MustSelectAllFields(Rule);
				
			Else
				
				SelectAllFields = Rule.SelectExportDataInSingleQuery;	
				
			EndIf;
			
			Selection = GetSelectionForDataClearingExport(Properties, TypeName, , , SelectAllFields);
			SelectionForOCR = ?(Rule.SelectExportDataInSingleQuery, Selection, Undefined);
			
			If Selection = Undefined Then
				Return;
			EndIf;

			While Selection.Next() Do
				
				If IsNotReferenceType Then
					
					ExportSelectionObject(Selection, Rule, Properties, OutgoingData);
					
				Else
					
					ExportSelectionObject(Selection.Ref, Rule, Properties, OutgoingData, SelectionForOCR);
					
				EndIf;
				
			EndDo;
			
		EndIf;

	ElsIf Rule.DataFilterMethod = "ArbitraryAlgorithm" Then

		If DataSelection <> Undefined Then
			
			Selection = GetExportWithArbitraryAlgorithmSelection(DataSelection);
			
			If Selection <> Undefined Then
				
				While Selection.Next() Do
					
					ExportSelectionObject(Selection, Rule, , OutgoingData);
					
				EndDo;
				
			Else
				
				For Each Object In DataSelection Do
					
					ExportSelectionObject(Object, Rule, , OutgoingData);
					
				EndDo;
				
			EndIf;
			
		EndIf;
			
	EndIf;

	
	// AfterProcess handler

	If Not IsBlankString(Rule.AfterProcess) Then
	
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Rule, "AfterProcess"));
				
			Else
				
				Execute(Rule.AfterProcess);
				
			EndIf;
			
		Except
			
			WriteErrorInfoDERHandlers(32, ErrorDescription(), Rule.Name, "AfterProcessDataExport");
			
		EndTry;
		
	 EndIf;	
	
EndProcedure

// Iterates the tree of data export rules and executes export.
//
// Parameters:
//  Rows - value tree rows collection.
//  ExchangePlanNodesAndExportRowsMap - a map of an exchange plan nodes and a rules tree rows.
// 
Procedure ProcessExportRules(Rows, ExchangePlanNodesAndExportRowsMap)
	
	For each ExportRule In Rows Do
		
		If ExportRule.Enable = 0 Then
			
			Continue;
			
		EndIf; 
		
		If (ExportRule.ExchangeNodeRef <> Undefined And Not ExportRule.ExchangeNodeRef.IsEmpty()) Then
			
			ExportRulesArray = ExchangePlanNodesAndExportRowsMap.Get(ExportRule.ExchangeNodeRef);
			
			If ExportRulesArray = Undefined Then
				
				ExportRulesArray = New Array();	
				
			EndIf;
			
			ExportRulesArray.Add(ExportRule);
			
			ExchangePlanNodesAndExportRowsMap.Insert(ExportRule.ExchangeNodeRef, ExportRulesArray);
			
			Continue;
			
		EndIf;

		If ExportRule.IsGroup Then
			
			ProcessExportRules(ExportRule.Rows, ExchangePlanNodesAndExportRowsMap);
			Continue;
			
		EndIf;
		
		ExportDataByRule(ExportRule);
		
	EndDo; 
	
EndProcedure

Function CopyExportRulesArray(SourceArray)
	
	ResultingArray = New Array();
	
	For Each Item In SourceArray Do
		
		ResultingArray.Add(Item);	
		
	EndDo;
	
	Return ResultingArray;
	
EndFunction

// Returns:
//   ValueTreeRow - a data export rules tree row:
//     * Name - String -
//     * Description - String -
//
Function FindExportRulesTreeRowByExportType(RowsArray, ExportType)
	
	For Each ArrayRow In RowsArray Do
		
		If ArrayRow.SelectionObject = ExportType Then
			
			Return ArrayRow;
			
		EndIf;
			
	EndDo;
	
	Return Undefined;
	
EndFunction

Procedure DeleteExportByExportTypeRulesTreeRowFromArray(RowsArray, ItemToDelete)
	
	Counter = RowsArray.Count() - 1;
	While Counter >= 0 Do
		
		ArrayRow = RowsArray[Counter];
		
		If ArrayRow = ItemToDelete Then
			
			RowsArray.Delete(Counter);
			Return;
			
		EndIf; 
		
		Counter = Counter - 1;	
		
	EndDo;
	
EndProcedure

// Parameters:
//   Data - AnyRef, IformatinRegisterRecordSet, etc
//
Procedure GetExportRulesRowByExchangeObject(Data, LastObjectMetadata, ExportObjectMetadata, 
	LastExportRulesRow, CurrentExportRuleRow, TempConversionRulesArray, ObjectForExportRules, 
	ExportingRegister, ExportingConstants, ConstantsWereExported)
	
	CurrentExportRuleRow = Undefined;
	ObjectForExportRules = Undefined;
	ExportingRegister = False;
	ExportingConstants = False;
	
	If LastObjectMetadata = ExportObjectMetadata And LastExportRulesRow = Undefined Then
		
		Return;
		
	EndIf;

	DataStructure = ManagersForExchangePlans[ExportObjectMetadata];
	
	If DataStructure = Undefined Then
		
		ExportingConstants = Metadata.Constants.Contains(ExportObjectMetadata);
		
		If ConstantsWereExported Or Not ExportingConstants Then
			
			Return;
			
		EndIf;
		
		// Searching for the rule for constants.
		If LastObjectMetadata <> ExportObjectMetadata Then
		
			CurrentExportRuleRow = FindExportRulesTreeRowByExportType(TempConversionRulesArray, Type("ConstantsSet"));
			
		Else
			
			CurrentExportRuleRow = LastExportRulesRow;
			
		EndIf;
		
		Return;

	EndIf;

	If DataStructure.IsReferenceType = True Then
		
		If LastObjectMetadata <> ExportObjectMetadata Then
		
			CurrentExportRuleRow = FindExportRulesTreeRowByExportType(TempConversionRulesArray, DataStructure.RefType);
			
		Else
			
			CurrentExportRuleRow = LastExportRulesRow;
			
		EndIf;
		
		ObjectForExportRules = Data.Ref;
		
	ElsIf DataStructure.IsRegister = True Then
		
		If LastObjectMetadata <> ExportObjectMetadata Then
		
			CurrentExportRuleRow = FindExportRulesTreeRowByExportType(TempConversionRulesArray, DataStructure.RefType);
			
		Else
			
			CurrentExportRuleRow = LastExportRulesRow;	
			
		EndIf;
		
		ObjectForExportRules = Data;
		
		ExportingRegister = True;
		
	EndIf;
	
EndProcedure

Function ExecuteExchangeNodeChangedDataExport(ExchangeNode, ConversionRulesArray, StructureForChangeRegistrationDeletion)
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	StructureForChangeRegistrationDeletion.Insert("OCRArray", Undefined);
	StructureForChangeRegistrationDeletion.Insert("MessageNo", Undefined);
	
	XMLWriter = New XMLWriter();
	XMLWriter.SetString();
	
	// Creating a new message.
	WriteMessage = ExchangePlans.CreateMessageWriter();
		
	WriteMessage.BeginWrite(XMLWriter, ExchangeNode);
	
	// Counting the number of written objects.
	FoundObjectsToWriteCount = 0;

	LastMetadataObject = Undefined;
	LastExportRuleRow = Undefined; // see FindExportRulesTreeRowByExportType

	CurrentMetadataObject = Undefined;
	ExportRuleCurrentRow = Undefined; // see FindExportRulesTreeRowByExportType

	OutgoingData = Undefined;
	
	TempConversionRulesArray = CopyExportRulesArray(ConversionRulesArray);
	
	Cancel			= False;
	OutgoingData	= Undefined;
	DataSelection	= Undefined;
	
	ObjectForExportRules = Undefined;
	ConstantsWereExported = False;
	// Beginning a transaction
	If UseTransactionsOnExportForExchangePlans Then
		BeginTransaction();
	EndIf;

	Try
	
		MetadataToExportArray = New Array();
		
		// Filling in array with the metadata types that does have an export rules.
		For Each ExportRuleRow In TempConversionRulesArray Do
			
			DERMetadata = Metadata.FindByType(ExportRuleRow.SelectionObject);
			MetadataToExportArray.Add(DERMetadata);
			
		EndDo;

		ChangesSelection = ExchangePlans.SelectChanges(WriteMessage.Recipient, WriteMessage.MessageNo, MetadataToExportArray);
		
		StructureForChangeRegistrationDeletion.MessageNo = WriteMessage.MessageNo;

		While ChangesSelection.Next() Do
					
			Data = ChangesSelection.Get();
			FoundObjectToWriteCount = FoundObjectToWriteCount + 1;
			
			ExportDataType = TypeOf(Data); 
			
			Delete = (ExportDataType = deObjectDeletionType);
			
			If Delete Then
				Continue;
			EndIf;

			CurrentMetadataObject = Data.Metadata();
			
			// Processing data received from the exchange node. Determining the conversion rule and the exporting data.

			ExportingRegister = False;
			ExportingConstants = False;
			
			GetExportRulesRowByExchangeObject(Data, LastMetadataObject, CurrentMetadataObject,
				LastExportRuleRow, ExportRuleCurrentRow, TempConversionRulesArray, ObjectForExportRules,
				ExportingRegister, ExportingConstants, ConstantsWereExported);

			If LastMetadataObject <> CurrentMetadataObject Then
				
				// after processing
				If LastExportRuleRow <> Undefined Then
			
					If Not IsBlankString(LastExportRuleRow.AfterProcess) Then
					
						Try
							
							If HandlersDebugModeFlag Then
								
								Execute(GetHandlerCallString(LastExportRuleRow, "AfterProcess"));
								
							Else
								
								Execute(LastExportRuleRow.AfterProcess);
								
							EndIf;
							
						Except
							
							WriteErrorInfoDERHandlers(32, ErrorDescription(), LastExportRuleRow.Name, "AfterProcessDataExport");
							
						EndTry;
						
					EndIf;
					
				EndIf;
				
				// before processing
				If ExportRuleCurrentRow <> Undefined Then
					
					If CommentObjectProcessingFlag Then
						
						MessageString = SubstituteParametersToString(NStr("ru = 'Правило выгрузки данных: %1 (%2)'; en = 'Data export rule: %1 (%2)'"),
							TrimAll(ExportRuleCurrentRow.Name), TrimAll(ExportRuleCurrentRow.Description));
						WriteToExecutionLog(MessageString, , False, , 4);
						
					EndIf;
					
					// BeforeProcess handle
					Cancel			= False;
					OutgoingData	= Undefined;
					DataSelection	= Undefined;
					
					If Not IsBlankString(ExportRuleCurrentRow.BeforeProcess) Then
					
						Try
							
							If HandlersDebugModeFlag Then
								
								Execute(GetHandlerCallString(ExportRuleCurrentRow, "BeforeProcess"));
								
							Else
								
								Execute(ExportRuleCurrentRow.BeforeProcess);
								
							EndIf;
							
						Except
							
							WriteErrorInfoDERHandlers(31, ErrorDescription(), ExportRuleCurrentRow.Name, "BeforeProcessDataExport");
							
						EndTry;
						
					EndIf;

					If Cancel Then
						
						// Deleting the rule from rules array.
						ExportRuleCurrentRow = Undefined;
						DeleteExportByExportTypeRulesTreeRowFromArray(TempConversionRulesArray, ExportRuleCurrentRow);
						ObjectForExportRules = Undefined;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If ExportRuleCurrentRow <> Undefined Then
				
				If ExportingRegister Then
					
					For Each RegisterLine In ObjectForExportRules Do
						ExportSelectionObject(RegisterLine, ExportRuleCurrentRow, , OutgoingData);
					EndDo;
					
				ElsIf ExportingConstants Then
					
					Properties	= Managers[ExportRuleCurrentRow.SelectionObject];
					ExportConstantSet(ExportRuleCurrentRow, Properties, OutgoingData);
					
				Else
				
					ExportSelectionObject(ObjectForExportRules, ExportRuleCurrentRow, , OutgoingData);
				
				EndIf;
				
			EndIf;

			LastMetadataObject = CurrentMetadataObject;
			LastExportRuleRow = ExportRuleCurrentRow;

			If ProcessedObjectsCountToUpdateStatus > 0 
				And FoundObjectsToWriteCount % ProcessedObjectsCountToUpdateStatus = 0 Then

				Try
					MetadataName = CurrentMetadataObject.FullName();
				Except
					MetadataName = "";
				EndTry;
				
			EndIf;

			If UseTransactionsOnExportForExchangePlans
				And (TransactionItemsCountOnExportForExchangePlans > 0)
				And (FoundObjectsToWriteCount = TransactionItemsCountOnExportForExchangePlans) Then
				
				CommitTransaction();
				BeginTransaction();
				
				FoundObjectToWriteCount = 0;
			EndIf;
			
		EndDo;
		
		WriteMessage.EndWrite();
		
		XMLWriter.Close();
		
		If UseTransactionsOnExportForExchangePlans Then
			CommitTransaction();
		EndIf;
		
	Except
		
		If UseTransactionsOnExportForExchangePlans Then
			RollbackTransaction();
		EndIf;
		
		LR = GetLogRecordStructure(72, ErrorDescription());
		LR.ExchangePlanNode  = ExchangeNode;
		LR.Object = Data;
		LR.ObjectType = ExportDataType;
		
		WriteToExecutionLog(72, LR, True);
						
		XMLWriter.Close();
		
		Return False;
		
	EndTry;
	
	// After processing
	If LastExportRuleRow <> Undefined Then
	
		If Not IsBlankString(LastExportRuleRow.AfterProcess) Then
		
			Try
				
				If HandlersDebugModeFlag Then
					
					Execute(GetHandlerCallString(LastExportRuleRow, "AfterProcess"));
					
				Else
					
					Execute(LastExportRuleRow.AfterProcess);
					
				EndIf;
				
			Except
				WriteErrorInfoDERHandlers(32, ErrorDescription(), LastExportRuleRow.Name, "AfterProcessDataExport");
				
			EndTry;
			
		EndIf;
		
	EndIf;
	
	StructureForChangeRegistrationDeletion.OCRArray = TempConversionRulesArray;
	
	Return Not Cancel;
	
EndFunction

Function ProcessExportForExchangePlans(NodeAndExportRuleMap, StructureForChangeRegistrationDeletion)
	
	ExportSuccessful = True;
	
	For Each MapRow In NodeAndExportRuleMap Do
		
		ExchangeNode = MapRow.Key;
		ConversionRulesArray = MapRow.Value;
		
		LocalStructureForChangeRegistrationDeletion = New Structure();
		
		CurrentExportSuccessful = ExecuteExchangeNodeChangedDataExport(ExchangeNode, ConversionRulesArray, LocalStructureForChangeRegistrationDeletion);
		
		ExportSuccessful = ExportSuccessful AND CurrentExportSuccessful;
		
		If LocalStructureForChangeRegistrationDeletion.OCRArray <> Undefined And LocalStructureForChangeRegistrationDeletion.OCRArray.Count() > 0 Then
			
			StructureForChangeRegistrationDeletion.Insert(ExchangeNode, LocalStructureForChangeRegistrationDeletion);	
			
		EndIf;
		
	EndDo;
	
	Return ExportSuccessful;
	
EndFunction

Procedure ProcessExchangeNodeRecordChangeEditing(NodeAndExportRuleMap)
	
	For Each Item In NodeAndExportRuleMap Do
	
		If ChangesRegistrationDeletionTypeForExportedExchangeNodes = 0 Then
			
			Return;
			
		ElsIf ChangesRegistrationDeletionTypeForExportedExchangeNodes = 1 Then
			
			// Deleting the registration of all changes in the exchange plan.
			ExchangePlans.DeleteChangeRecords(Item.Key, Item.Value.MessageNo);

		ИначеЕсли ChangesRegistrationDeletionTypeForExportedExchangeNodes = 2 Тогда	
			
			// Deleting changes of the first level exported objects metadata.

			For Each ExportedOCR In Item.Value.OCRArray Do
				
				Rule = Rules[ExportedOCR.ConversionRule]; // see FindRule

				If ValueIsFilled(Rule.Source) Then
					
					Manager = Managers[Rule.Source];
					
					ExchangePlans.DeleteChangeRecords(Item.Key, Manager.MetadateObject);
					
				EndIf;
				
			EndDo;
			
		EndIf;
	
	EndDo;
	
EndProcedure

Function DeleteProhibitedXMLChars(Val Text)
	
	Return ReplaceProhibitedXMLChars(Text, "");
	
EndFunction

#EndRegion

#Region ExportProceduresAndFunctions

// Opens an exchange file and reads attributes of file master node according to the exchange format.
//
// Parameters:
//  ReadHeaderOnly - Boolean - If True, file closes after reading the exchange file header (master node).
//  ExchangeFileData - String - an exchane file data.
//
Procedure OpenImportFile(ReadHeaderOnly=False, ExchangeFileData = "") Export

	If IsBlankString(ExchangeFileName) AND ReadHeaderOnly Then
		StartDate         = "";
		EndDate      = "";
		DataExportDate = "";
		ExchangeRulesVersion = "";
		Comment        = "";
		Return;
	EndIf;
	DataImportFileName = ExchangeFileName;
	
	
	// Archive files are recognized by the ZIP extension.
	If StrFind(ExchangeFileName, ".zip") > 0 Then
		
		DataImportFileName = UnpackZipFile(ExchangeFileName);		 
		
	EndIf;
	ErrorFlag = False;
	ExchangeFile = New XMLReader();

	Try
		If Not IsBlankString(ExchangeFileData) Then
			ExchangeFile.SetString(ExchangeFileData);
		Else
			ExchangeFile.OpenFile(DataImportFileName);
		EndIf;
	Except
		WriteToExecutionLog(5);
		Return;
	EndTry;

	ExchangeFile.Read();
	mExchangeFileAttributes = New Structure;
	If ExchangeFile.LocalName = "ExchangeFile" Then
		
		mExchangeFileAttributes.Insert("FormatVersion",            deAttribute(ExchangeFile, deStringType, "FormatVersion"));
		mExchangeFileAttributes.Insert("ExportDate",             deAttribute(ExchangeFile, deDateType,   "ExportDate"));
		mExchangeFileAttributes.Insert("ExportPeriodStart",    deAttribute(ExchangeFile, deDateType,   "ExportPeriodStart"));
		mExchangeFileAttributes.Insert("ExportPeriodEnd", deAttribute(ExchangeFile, deDateType,   "ExportPeriodEnd"));
		mExchangeFileAttributes.Insert("SourceConfigurationName", deAttribute(ExchangeFile, deStringType, "SourceConfigurationName"));
		mExchangeFileAttributes.Insert("DestinationConfigurationName", deAttribute(ExchangeFile, deStringType, "DestinationConfigurationName"));
		mExchangeFileAttributes.Insert("ConversionRuleIDs",      deAttribute(ExchangeFile, deStringType, "ConversionRuleIDs"));
		
		StartDate         = mExchangeFileAttributes.ExportPeriodStart;
		EndDate      = mExchangeFileAttributes.ExportPeriodEnd;
		DataExportDate = mExchangeFileAttributes.ExportDate;
		Comment        = deAttribute(ExchangeFile, deStringType, "Comment");
		
	Else
		
		WriteToExecutionLog(9);
		Return;
		
	EndIf;
	ExchangeFile.Read();

	NodeName = ExchangeFile.LocalName;

	If NodeName = "ExchangeRules" Then
		If SafeImport And ValueIsFilled(ExchangeRulesFileName) Then
			ImportExchangeRules(ExchangeRulesFileName, "XMLFile");
			ExchangeFile.Skip();
		Else
			ImportExchangeRules(ExchangeFile, "XMLReader");
		EndIf;
	Else
		ExchangeFile.Close();
		ExchangeFile = New XMLReader();
		Try
			
			If Not IsBlankString(ExchangeFileData) Then
				ExchangeFile.SetString(ExchangeFileData);
			Else
				ExchangeFile.OpenFile(DataImportFileName);
			EndIf;
			
		Except
			
			WriteToExecutionLog(5);
			Return;
			
		EndTry;
		
		ExchangeFile.Read();
		
	EndIf; 
	
	mExchangeRulesReadOnImport = True;

	If ReadHeaderOnly Then
		
		ExchangeFile.Close();
		Return;
		
	EndIf;
   
EndProcedure

Procedure RefreshAllExportRuleParentMarks(ExportRuleTreeRows, SetMarks = True)
	
	If ExportRuleTreeRows.Rows.Count() = 0 Then
		
		If SetMarks Then
			SetParentMarks(ExportRuleTreeRows, "Enable");	
		EndIf;
		
	Else
		
		MarksRequired = True;
		
		For Each RuleTreeRow In ExportRuleTreeRows.Rows Do
			
			RefreshAllExportRuleParentMarks(RuleTreeRow, MarksRequired);
			If MarksRequired = True Then
				MarksRequired = False;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillPropertiesForSearch(DataStructure, PCR)
	
	For Each FieldsRow In PCR Do
		
		If FieldsRow.IsGroup Then
						
			If FieldsRow.DestinationKind = "TabularSection" Or StrFind(FieldsRow.DestinationKind, "RecordSet") > 0 Then

				DestinationStructureName = FieldsRow.Destination + ?(FieldsRow.DestinationKind = "TabularSection", "TabularSection", "RecordSet");
				
				InternalStructure = DataStructure[DestinationStructureName];
				
				If InternalStructure = Undefined Then
					InternalStructure = New Map();
				EndIf;
				
				DataStructure[DestinationStructureName] = InternalStructure;
				
			Else
				
				InternalStructure = DataStructure;	
				
			EndIf;
			
			FillPropertiesForSearch(InternalStructure, FieldsRow.GroupRules);
									
		Else
			
			If IsBlankString(FieldsRow.DestinationType)	Then
				
				Continue;
				
			EndIf;
			
			DataStructure[FieldsRow.Destination] = FieldsRow.DestinationType;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteExcessiveItemsFromMap(DataStructure)
	
	For Each Item In DataStructure Do
		
		If TypeOf(Item.Value) = deMapType Then
			
			DeleteExcessiveItemsFromMap(Item.Value);
			
			If Item.Value.Count() = 0 Then
				DataStructure.Delete(Item.Key);
			EndIf;
			
		EndIf;		
		
	EndDo;		
	
EndProcedure

Procedure FillInformationByDestinationDataTypes(DataStructure, Rules)
	
	For Each Row In Rules Do
		
		If IsBlankString(Row.Destination) Then
			Continue;
		EndIf;
		
		StructureData = DataStructure[Row.Destination];
		If StructureData = Undefined Then
			
			StructureData = New Map();
			DataStructure[Row.Destination] = StructureData;
			
		EndIf;
		
		FillPropertiesForSearch(StructureData, Row.SearchProperties);
				
		FillPropertiesForSearch(StructureData, Row.Properties);
		
	EndDo;
	
	DeleteExcessiveItemsFromMap(DataStructure);	
	
EndProcedure

Procedure CreateStringWithPropertyTypes(XMLWriter, PropertyTypes)
	
	If TypeOf(PropertyTypes.Value) = deMapType Then
		
		If PropertyTypes.Value.Count() = 0 Then
			Return;
		EndIf;
		
		XMLWriter.WriteStartElement(PropertyTypes.Key);
		
		For Each Item In PropertyTypes.Value Do
			CreateStringWithPropertyTypes(XMLWriter, Item);
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	Else		
		
		deWriteElement(XMLWriter, PropertyTypes.Key, PropertyTypes.Value);
		
	EndIf;
	
EndProcedure

Function CreateTypeStringForDestination(DataStructure)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement("DataTypeInformation");	
	
	For Each Row In DataStructure Do
		
		XMLWriter.WriteStartElement("DataType");
		SetAttribute(XMLWriter, "Name", Row.Key);
		
		For Each SubordinateRow In Row.Value Do
			
			CreateStringWithPropertyTypes(XMLWriter, SubordinateRow);	
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndDo;	
	
	XMLWriter.WriteEndElement();
	
	ResultString = XMLWriter.Close();
	Return ResultString;
	
EndFunction

Procedure ImportSingleTypeData(ExchangeRules, TypeMap, LocalItemName)
	
	NodeName = LocalItemName;
	
	ExchangeRules.Read();
	
	If (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
		
		ExchangeRules.Read();
		Return;
		
	ElsIf ExchangeRules.NodeType = deXMLNodeType_StartElement Then
			
		NewMap = New Map;
		TypeMap.Insert(NodeName, NewMap);
		
		ImportSingleTypeData(ExchangeRules, NewMap, ExchangeRules.LocalName);			
		ExchangeRules.Read();
		
	Else
		TypeMap.Insert(NodeName, Type(ExchangeRules.Value));
		ExchangeRules.Read();
	EndIf;	
	
	ImportTypeMapForSingleType(ExchangeRules, TypeMap);
	
EndProcedure

Procedure ImportTypeMapForSingleType(ExchangeRules, TypeMap)
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
			
		    Break;
			
		EndIf;
		
		ExchangeRules.Read();
		
		If ExchangeRules.NodeType = deXMLNodeType_StartElement Then
			
			NewMap = New Map;
			TypeMap.Insert(NodeName, NewMap);
			
			ImportSingleTypeData(ExchangeRules, NewMap, ExchangeRules.LocalName);			
			
		Else
			TypeMap.Insert(NodeName, Type(ExchangeRules.Value));
			ExchangeRules.Read();
		EndIf;	
		
	EndDo;	
	
EndProcedure

Procedure ImportDataTypeInformation()
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "DataType" Then
			
			TypeName = deAttribute(ExchangeFile, deStringType, "Name");
			
			TypeMap = New Map;
			mDataTypeMapForImport.Insert(Type(TypeName), TypeMap);

			ImportTypeMapForSingleType(ExchangeFile, TypeMap);	
			
		ElsIf (NodeName = "DataTypeInformation") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ImportDataExchangeParameterValues()
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	Name = deAttribute(ExchangeFile, deStringType, "Name");
		
	PropertyType = GetPropertyTypeByAdditionalData(Undefined, Name);
	
	Value = ReadProperty(PropertyType);
	
	Parameters.Insert(Name, Value);	
	
	AfterParameterImportAlgorithm = "";
	If EventsAfterParametersImport.Property(Name, AfterParameterImportAlgorithm)
		And Not IsBlankString(AfterParameterImportAlgorithm) Then
		
		If HandlersDebugModeFlag Then
			
			Raise NStr("ru = 'Отладка обработчика ""После загрузки параметра"" не поддерживается.'; en = 'Debugging of handler ""After parameter import"" is not supported.'");
			
		Else
			
			Execute(AfterParameterImportAlgorithm);
			
		EndIf;
		
	EndIf;
		
EndProcedure

Function GetHandlerValueFromText(ExchangeRules)
	
	HandlerText = deElementValue(ExchangeRules, deStringType);
	
	If StrFind(HandlerText, Chars.LF) = 0 Then
		Return HandlerText;
	EndIf;
	
	HandlerText = StrReplace(HandlerText, Char(10), Chars.LF);
	
	Return HandlerText;
	
EndFunction

// Imports exchange rules according to the format.
//
// Parameters:
//  Source - object where the exchange rules are imported from.
//  SourceType    - a string indicating the source type: "XMLFile", "XMLReader", "String".
// 
Procedure ImportExchangeRules(Source="", SourceType="XMLFile") Export
	
	InitManagersAndMessages();
	
	HasBeforeExportObjectGlobalHandler    = False;
	HasAfterExportObjectGlobalHandler     = False;
	
	HasBeforeConvertObjectGlobalHandler = False;

	HasBeforeImportObjectGlobalHandler    = False;
	HasAfterImportObjectGlobalHandler     = False;
	
	CreateConversionStructure();

	mPropertyConversionRulesTable = New ValueTable;
	InitPropertyConversionRulesTable(mPropertyConversionRulesTable);
	SupplementInternalTablesWithColumns();
	
	ExchangeRulesTempFileName = "";
	If IsBlankString(Source) Then
		
		Source = ExchangeRulesFileName;
		If mExchangeRuleTemplateList.FindByValue(Source) <> Undefined Then
			For each Template In Metadata().Templates Do
				If Template.Synonym = Source Then
					Source = Template.Name;
					Break;
				EndIf; 
			EndDo; 
			ExchangeRuleTemplate              = GetTemplate(Source);
			ExchangeRulesTempFileName = GetTempFileName("xml");
			ExchangeRuleTemplate.Write(ExchangeRulesTempFileName);
			Source = ExchangeRulesTempFileName;
		EndIf;
		
	EndIf;
	If SourceType="XMLFile" Then
		
		If IsBlankString(Source) Then
			WriteToExecutionLog(12);
			Return; 
		EndIf;
		
		File = New File(Source);
		If Not File.Exist() Then
			WriteToExecutionLog(3);
			Return; 
		EndIf;
		
		RuleFilePacked = (File.Extension = ".zip");
		
		If RuleFilePacked Then
			
			Source = UnpackZipFile(Source);
			
		EndIf;
		
		ExchangeRules = New XMLReader();
		ExchangeRules.OpenFile(Source);
		ExchangeRules.Read();
		
	ElsIf SourceType="String" Then
		
		ExchangeRules = New XMLReader();
		ExchangeRules.SetString(Source);
		ExchangeRules.Read();
		
	ElsIf SourceType="XMLReader" Then
		
		ExchangeRules = Source;
		
	EndIf;
	If Not ((ExchangeRules.LocalName = "ExchangeRules") And (ExchangeRules.NodeType = deXMLNodeType_StartElement)) Then
		WriteToExecutionLog(6);
		Return;
	EndIf;
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.Indent = True;
	XMLWriter.WriteStartElement("ExchangeRules");
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		// Conversion attributes
		If NodeName = "FormatVersion" Then
			Value = deElementValue(ExchangeRules, deStringType);
			Conversion.Insert("FormatVersion", Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "ID" Then
			Value = deElementValue(ExchangeRules, deStringType);
			Conversion.Insert("ID",                   Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "Description" Then
			Value = deElementValue(ExchangeRules, deStringType);
			Conversion.Insert("Description",         Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "CreationDateTime" Then
			Value = deElementValue(ExchangeRules, deDateType);
			Conversion.Insert("CreationDateTime",    Value);
			deWriteElement(XMLWriter, NodeName, Value);
			ExchangeRulesVersion = Conversion.CreationDateTime;
		ElsIf NodeName = "Source" Then
			Value = deElementValue(ExchangeRules, deStringType);
			Conversion.Insert("Source",             Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "Destination" Then
			
			DestinationPlatformVersion = ExchangeRules.GetAttribute ("PlatformVersion");
			DestinationPlatform = GetPlatformByDestinationPlatformVersion(DestinationPlatformVersion);
			
			Value = deElementValue(ExchangeRules, deStringType);
			Conversion.Insert("Destination",             Value);
			deWriteElement(XMLWriter, NodeName, Value);
			
		ElsIf NodeName = "DeleteMappedObjectsFromDestinationOnDeleteFromSource" Then
			deSkip(ExchangeRules);
		
		ElsIf NodeName = "Comment" Then
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "MainExchangePlan" Then
			deSkip(ExchangeRules);

		ElsIf NodeName = "Parameters" Then
			ImportParameters(ExchangeRules, XMLWriter);

		// Conversion events
		ElsIf NodeName = "" Then
			
		ElsIf NodeName = "AfterImportExchangeRules" Then
			If ExchangeMode = "Import" Then
				ExchangeRules.Skip();
			Else
				Conversion.Insert("AfterImportExchangeRules", GetHandlerValueFromText(ExchangeRules));
			EndIf;
		ElsIf NodeName = "BeforeExportData" Then
			Conversion.Insert("BeforeExportData", GetHandlerValueFromText(ExchangeRules));
			
		ElsIf NodeName = "AfterExportData" Then
			Conversion.Insert("AfterExportData",  GetHandlerValueFromText(ExchangeRules));

		ElsIf NodeName = "BeforeExportObject" Then
			Conversion.Insert("BeforeExportObject", GetHandlerValueFromText(ExchangeRules));
			HasBeforeExportObjectGlobalHandler = Not IsBlankString(Conversion.BeforeExportObject);

		ElsIf NodeName = "AfterExportObject" Then
			Conversion.Insert("AfterExportObject", GetHandlerValueFromText(ExchangeRules));
			HasAfterExportObjectGlobalHandler = Not IsBlankString(Conversion.AfterExportObject);

		ElsIf NodeName = "BeforeImportObject" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				Conversion.Insert("BeforeImportObject", Value);
				HasBeforeImportObjectGlobalHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "AfterImportObject" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				Conversion.Insert("AfterImportObject", Value);
				HasAfterImportObjectGlobalHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "BeforeConvertObject" Then
			Conversion.Insert("BeforeConvertObject", GetHandlerValueFromText(ExchangeRules));
			HasBeforeConvertObjectGlobalHandler = Not IsBlankString(Conversion.BeforeConvertObject);
			
		ElsIf NodeName = "BeforeImportData" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				Conversion.BeforeImportData = Value;
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "AfterImportData" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				Conversion.AfterImportData = Value;
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "AfterImportParameters" Then
			Conversion.Insert("AfterImportParameters", GetHandlerValueFromText(ExchangeRules));
			
		ElsIf NodeName = "BeforeSendDeletionInfo" Then
			Conversion.Insert("BeforeSendDeletionInfo",  deElementValue(ExchangeRules, deStringType));
			
		ElsIf NodeName = "BeforeGetChangedObjects" Then
			Conversion.Insert("BeforeGetChangedObjects", deElementValue(ExchangeRules, deStringType));
			
		ElsIf NodeName = "OnGetDeletionInfo" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				Conversion.Insert("OnGetDeletionInfo", Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		ElsIf NodeName = "AfterGetExchangeNodesInformation" Then
			
			Value = GetHandlerValueFromText(ExchangeRules);
			
			If ExchangeMode = "Import" Then
				
				Conversion.Insert("AfterGetExchangeNodesInformation", Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;

		// Rules
		
		ElsIf NodeName = "DataExportRules" Then
		
 			If ExchangeMode = "Import" Then
				deSkip(ExchangeRules);
			Else
				ImportExportRules(ExchangeRules);
 			EndIf; 
			
		ElsIf NodeName = "ObjectConversionRules" Then
			ImportConversionRules(ExchangeRules, XMLWriter);
			
		ElsIf NodeName = "DataClearingRules" Then
			ImportClearingRules(ExchangeRules, XMLWriter)
			
		ElsIf NodeName = "ObjectsRegistrationRules" Then
			deSkip(ExchangeRules); // Object registration rules are imported with another data processor.
			
		// Algorithms, Queries, DataProcessors.
		
		ElsIf NodeName = "Algorithms" Then
			ImportAlgorithms(ExchangeRules, XMLWriter);
			
		ElsIf NodeName = "Queries" Then
			ImportQueries(ExchangeRules, XMLWriter);

		ElsIf NodeName = "DataProcessors" Then
			ImportDataProcessors(ExchangeRules, XMLWriter);
			
		// Exit
		ElsIf (NodeName = "ExchangeRules") And (ExchangeRules.NodeType = deXMLNodeType_EndElement) Then
		
			If ExchangeMode <> "Import" Then
				ExchangeRules.Close();
			EndIf;
			Break;

			
		// Format error
		Else
		    RecordStructure = New Structure("NodeName", NodeName);
			WriteToExecutionLog(7, RecordStructure);
			Return;
		EndIf;
	EndDo;
	XMLWriter.WriteEndElement();
	mXMLRules = XMLWriter.Close();

	For Each ExportRulesString In ExportRulesTable.Rows Do
		RefreshAllExportRuleParentMarks(ExportRulesString, True);
	EndDo;
	
	// Deleting the temporary rule file.
	If Not IsBlankString(ExchangeRulesTempFileName) Then
		Try
 			DeleteFiles(ExchangeRulesTempFileName);
		Except 
			WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;

	If SourceType="XMLFile" And RuleFilePacked Then
		
		Try
			DeleteFiles(Source);
		Except 
			WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", DefaultLanguageCode()),
				EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	// Information on destination data types for quick data import.
	DataStructure = New Map();
	FillInformationByDestinationDataTypes(DataStructure, ConversionRulesTable);

	mTypeStringForDestination = CreateTypeStringForDestination(DataStructure);

	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	AfterExchangeRulesImportEventText = "";
	If Conversion.Property("AfterImportExchangeRules", AfterExchangeRulesImportEventText)
		And Not IsBlankString(AfterExchangeRulesImportEventText) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Raise NStr("ru = 'Отладка обработчика ""После загрузки правил обмена"" не поддерживается.'; en = '""After exchange rule import"" handler debugging is not supported.'");
				
			Else
				
				Execute(AfterExchangeRulesImportEventText);
				
			EndIf;
			
		Except
			
			Text = NStr("ru = 'Обработчик: ""ПослеЗагрузкиПравилОбмена"": %1'; en = 'AfterExchangeRuleImport handler: %1'");
			Text = SubstituteParametersToString(Text, BriefErrorDescription(ErrorInfo()));
			
			WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", DefaultLanguageCode()),
				EventLogLevel.Error,,, Text);
				
			MessageToUser(Text);
			
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure ProcessNewItemReadEnd(LastImportObject)
	
	mImportedObjectCounter = 1 + mImportedObjectCounter;
				
	If RememberImportedObjects And mImportedObjectCounter % 100 = 0 Then
				
		If ImportedObjects.Count() > ImportedObjectToStoreCount Then
			ImportedObjects.Clear();
		EndIf;
				
	EndIf;
	
	If mImportedObjectCounter % 100 = 0 And mNotWrittenObjectGlobalStack.Count() > 100 Then
		
		WriteNotWrittenObjects();
		
	EndIf;
	
	If UseTransactions And ObjectsPerTransaction > 0 And mImportedObjectCounter % ObjectsPerTransaction = 0 Then
		
		CommitTransaction();
		BeginTransaction();
		
	EndIf;	

EndProcedure

// Reads files of exchange message and writes data to the infobase.
//
// Parameters:
//  ErrorInfoResultString - String - an error info result string.
// 
Procedure ReadData(ErrorInfoResultString = "") Export
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	Try
	
		While ExchangeFile.Read() Do
			
			NodeName = ExchangeFile.LocalName;
			
			If NodeName = "Object" Then
				
				LastImportObject = ReadObject();
				
				ProcessNewItemReadEnd(LastImportObject);
				
			ElsIf NodeName = "ParameterValue" Then	
				
				ImportDataExchangeParameterValues();

			ElsIf NodeName = "AfterParameterExportAlgorithm" Then	
				
				Cancel = False;
				CancelReason = "";
				
				AlgorithmText = "";
				Conversion.Property("AfterImportParameters", AlgorithmText);
				
				// On import in the safe mode the algorithm text is received when reading rules.
				// Otherwise it is received from the exchange file.
				If IsBlankString(AlgorithmText) Then
					AlgorithmText = deElementValue(ExchangeFile, deStringType);
				Else
					ExchangeFile.Skip();
				EndIf;

				If Not IsBlankString(AlgorithmText) Then
				
					Try
						
						If HandlersDebugModeFlag Then
							
							Raise NStr("ru = 'Отладка обработчика ""После загрузки параметров"" не поддерживается.'; en = 'Debugging of handler ""After parameters import"" is not supported.'");
							
						Else
							
							Execute(AlgorithmText);
							
						EndIf;
						
						If Cancel = True Then
							
							If Not IsBlankString(CancelReason) Then
								ExceptionString = SubstituteParametersToString(NStr("ru = 'Загрузка данных отменена по причине: %1'; en = 'The data import is canceled. Reason: %1'"), CancelReason);
								Raise ExceptionString;
							Else
								Raise NStr("ru = 'Загрузка данных отменена'; en = 'The data import is canceled.'");
							EndIf;
							
						EndIf;

					Except
												
						LR = GetLogRecordStructure(75, ErrorDescription());
						LR.Handler     = "AfterImportParameters";
						ErrorMessageString = WriteToExecutionLog(75, LR, True);
						
						If Not DebugModeFlag Then
							Raise ErrorMessageString;
						EndIf;
						
					EndTry;
					
				EndIf;

			ElsIf NodeName = "Algorithm" Then
				
				AlgorithmText = deElementValue(ExchangeFile, deStringType);
				
				If Not IsBlankString(AlgorithmText) Then
				
					Try
						
						If HandlersDebugModeFlag Then
							
							Raise NStr("ru = 'Отладка глобального алгоритма не поддерживается.'; en = 'Global algorithm debugging is not supported.'");
							
						Else
							
							Execute(AlgorithmText);
							
						EndIf;
						
					Except
						
						LR= GetLogRecordStructure(39, ErrorDescription());
						LR.Handler     = "ExchangeFileAlgorithm";
						ErrorMessageString = WriteToExecutionLog(39, LR, True);
						
						If Not DebugModeFlag Then
							Raise ErrorMessageString;
						EndIf;
						
					EndTry;
					
				EndIf;

			ElsIf NodeName = "ExchangeRules" Then
				
				mExchangeRulesReadOnImport = True;
				
				If ConversionRulesTable.Count() = 0 Then
					ImportExchangeRules(ExchangeFile, "XMLReader");
				Else
					deSkip(ExchangeFile);
				EndIf;
				
			ElsIf NodeName = "DataTypeInformation" Then
				
				ImportDataTypeInformation();
				
			ElsIf (NodeName = "ExchangeFile") And (ExchangeFile.NodeType = deXMLNodeType_EndElement) Then
				
			Else
				RecordStructure = New Structure("NodeName", NodeName);
				WriteToExecutionLog(9, RecordStructure);
			EndIf;
			
		EndDo;

	Except
		
		ErrorRow = SubstituteParametersToString(NStr("ru = 'Ошибка при загрузке данных: %1'; en = 'Cannot import data: %1'"), ErrorDescription());
		
		ErrorInfoResultString = WriteToExecutionLog(ErrorRow, Undefined, True, , , True);
		
		FinishKeepExchangeLog();
		ExchangeFile.Close();
		Return;
		
	EndTry;
	
EndProcedure

// Performs the following actions before reading data from the file:   
// 	- initializes variables;   
// 	- imports exchange rules from the data file;   
// 	- begins a transaction for writing data to the infobase;   
// 	- executes required event handlers.
// 
//
// Parameters:
//  DataString - an import file name or XML string containing data to import.
// 
//  Returns:
//    Boolean - True, if the data can be imported from file.
//
Function ExecuteActionsBeforeReadData(DataString = "") Export
	
	DataProcessingMode = mDataProcessingModes.Load;

	mSearchAdditionalParametersMap       = New Map;
	mConversionRulesMap         = New Map;

	Rules.Clear();
	
	InitializeCommentsOnDataExportImport();
	
	InitializeKeepExchangeLog();

	ImportIsPossible = True;
	
	If IsBlankString(DataString) Then
	
		If IsBlankString(ExchangeFileName) Then
			WriteToExecutionLog(15);
			ImportIsPossible = False;
		EndIf;
	
	EndIf;
	
	// Initializing the external data processor with export handlers.
	InitEventHandlerExternalDataProcessor(ImportIsPossible, ThisObject);

	If Not ImportIsPossible Then
		Return False;
	EndIf;

	MessageString = SubstituteParametersToString(NStr("ru = 'Начало загрузки: %1'; en = 'Import started at: %1'"), CurrentSessionDate());
	WriteToExecutionLog(MessageString, , False, , , True);

	If DebugModeFlag Then
		UseTransactions = False;
	EndIf;
	
	If ProcessedObjectsCountToUpdateStatus = 0 Then
		
		ProcessedObjectsCountToUpdateStatus = 100;
		
	EndIf;
	
	mDataTypeMapForImport = New Map;
	mNotWrittenObjectGlobalStack = New Map;

	mImportedObjectCounter = 0;
	ErrorFlag                  = False;
	ImportedObjects          = New Map;
	ImportedGlobalObjects = New Map;

	InitManagersAndMessages();
	
	OpenImportFile(,DataString);
	
	If ErrorFlag Then 
		FinishKeepExchangeLog();
		Return False; 
	EndIf;

	// Defining handler interfaces.
	If HandlersDebugModeFlag Then
		
		SupplementRulesWithHandlerInterfaces(Conversion, ConversionRulesTable, ExportRulesTable, CleanupRulesTable);
		
	EndIf;
	
	// BeforeDataImport handler
	Cancel = False;
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;

	If Not IsBlankString(Conversion.BeforeImportData) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Conversion, "BeforeImportData"));
				
			Else
				
				Execute(Conversion.BeforeImportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(22, ErrorDescription(), NStr("ru = 'ПередЗагрузкойДанных (конвертация)'; en = 'BeforeDataImport (conversion)'"));
			Cancel = True;
		EndTry;
		
		If Cancel Then // Canceling data import
			FinishKeepExchangeLog();
			ExchangeFile.Close();
			EventHandlerExternalDataProcessorDestructor();
			Return False;
		EndIf;
		
	EndIf;

	// Clearing infobase by rules.
	ProcessClearingRules(CleanupRulesTable.Rows);
	
	Return True;
	
EndFunction

// Performs the following actions after the data import iteration:
// - commits the transaction (if necessary)
// - closes the exchange message file;
// - Executing the AfterDataImport conversion handler
// - completing exchange logging (if necessary).
//
// Parameters:
//  No.
// 
Procedure ExecuteActionsAfterDataReadingCompleted() Export
	
	If SafeMode Then
		SetSafeMode(True);
		For Each SeparatorName In ConfigurationSeparators Do
			SetDataSeparationSafeMode(SeparatorName, True);
		EndDo;
	EndIf;
	
	ExchangeFile.Close();
	
	// Handler AfterDataImport
	If Not IsBlankString(Conversion.AfterImportData) Then
		
		Try
			
			If HandlersDebugModeFlag Then
				
				Execute(GetHandlerCallString(Conversion, "AfterImportData"));
				
			Else
				
				Execute(Conversion.AfterImportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(23, ErrorDescription(), NStr("ru = 'ПослеЗагрузкиДанных (конвертация)'; en = 'AfterDataImport (conversion)'"));
		EndTry;
		
	EndIf;

	EventHandlerExternalDataProcessorDestructor();
	
	WriteToExecutionLog(SubstituteParametersToString(
		NStr("ru = 'Окончание загрузки: %1'; en = 'Import finished at: %1'"), CurrentSessionDate()), , False, , , True);
	WriteToExecutionLog(SubstituteParametersToString(
		NStr("ru = 'Загружено объектов: %1'; en = '%1 objects imported'"), mImportedObjectCounter), , False, , , True);
	
	FinishKeepExchangeLog();
	
	If IsInteractiveMode Then
		MessageToUser(NStr("ru = 'Загрузка данных завершена.'; en = 'Data import completed.'"));
	EndIf;
	
EndProcedure

// Imports data according to the set modes (exchange rules).
//
// Parameters:
//  No.
//
Procedure ExecuteImport() Export
	
	ExecutionIsPossible = ExecuteActionsBeforeReadData();
	
	If Not ExecutionIsPossible Then
		Return;
	EndIf;
	
	If UseTransactions Then
		BeginTransaction();
	EndIf;
	
	Try
		ReadData();
		WriteNotWrittenObjects();
		If UseTransactions Then
			CommitTransaction();
		EndIf;
	Except
		If UseTransactions Then
			RollbackTransaction();
		EndIf;
	EndTry;
	
	ExecuteActionsAfterDataReadingCompleted();
	
EndProcedure

Procedure CompressResultingExchangeFile()
	
	Try
		
		SourceExchangeFileName = ExchangeFileName;
		If ArchiveFile Then
			ExchangeFileName = StrReplace(ExchangeFileName, ".xml", ".zip");
		EndIf;
		
		Archiver = New ZipFileWriter(ExchangeFileName, ExchangeFileCompressionPassword, NStr("ru = 'Файл обмена данными'; en = 'Data exchange file'"));
		Archiver.Add(SourceExchangeFileName);
		Archiver.Write();
		
		DeleteFiles(SourceExchangeFileName);
		
	Except
		WriteLogEvent(NStr("ru = 'Универсальный обмен данными в формате XML'; en = 'Universal data exchange in XML format'", DefaultLanguageCode()),
			EventLogLevel.Error,,, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Function UnpackZipFile(FileNameForUnpacking)
	
	DirectoryToUnpack = GetTempFileName();
	CreateDirectory(DirectoryToUnpack);
	
	UnpackedFileName = "";
	
	Try
		
		Archiver = New ZipFileReader(FileNameForUnpacking, ExchangeFileUnpackPassword);
		
		If Archiver.Items.Count() > 0 Then

			ArchiveItem = Archiver.Items.Get(0);

			Archiver.Extract(ArchiveItem, DirectoryToUnpack, ZIPRestoreFilePathsMode.DontRestore);
			UnpackedFileName = GetExchangeFileName(DirectoryToUnpack, Archiver.Items[0].Name);
			
		Else
			
			UnpackedFileName = "";
			
		EndIf;
		
		Archiver.Close();
	
	Except
		
		LR = GetLogRecordStructure(2, ErrorDescription());
		WriteToExecutionLog(2, LR, True);
		
		Return "";
							
	EndTry;
	
	Return UnpackedFileName;
		
EndFunction

Function SendExchangeStartedInformationToDestination(CurrentRowForWrite)
	
	If Not DirectReadFromDestinationIB Then
		Return True;
	EndIf;
	
	CurrentRowForWrite = CurrentRowForWrite + Chars.LF + mXMLRules + Chars.LF + "</ExchangeFile>" + Chars.LF;
	
	ExecutionPossible = mDataImportDataProcessor.ExecuteActionsBeforeReadData(CurrentRowForWrite);
	
	Return ExecutionPossible;	
	
EndFunction

Function ExecuteInformationTransferOnCompleteDataTransfer()
	
	//UT++
//	If Not DirectReadFromDestinationIB Then
//		Return True;
//	EndIf;
//	
//	mDataImportDataProcessor.ExecuteActionsAfterDataReadingCompleted();

	If DirectReadFromDestinationIB Then
		mDataImportDataProcessor.ExecuteActionsAfterDataReadingCompleted();
	ElsIf UT_ExportViaWebService Then
		Message(NStr("ru = 'Начало загрузки через вебсервис '; en = 'Importing via web-service started at '") + CurrentDate());
		ArchiveCache=ArchiveFile;
		ArchiveFile=True;
		CompressResultingExchangeFile();
		ArchiveFile=ArchiveCache;

		BinaryData=New BinaryData(ExchangeFileName);

		HTTPRequestParameters=New Structure;
		HTTPRequestParameters.Insert("Timeout", 0);

		Authentication=New Structure;
		Authentication.Insert("Username", InfobaseConnectionUsername);
		Authentication.Insert("Password", InfobaseConnectionPassword);
		HTTPRequestParameters.Insert("Authentication", Authentication);

		Try
			ExportResult=UT_HTTPConnector.Post(UT_DestinationPublicationAddress + "/hs/tools-ui-1c/exchange",
				BinaryData, HTTPRequestParameters);
			ResultStructure=UT_HTTPConnector.AsJson(ExportResult);

			ImportLog=ResultStructure["ImportLog"];
			Text=New TextDocument;
			Text.SetText(ImportLog);
			For LogLineNumber = 1 To Text.LineCount() Do
				Message(Text.GetLine(LogLineNumber));

			EndDo;

			If ValueIsFilled(ResultStructure["ServiceError"]) Тогда
				Message(ResultStructure["ServiceError"]);
			EndIf;
		Except
			Message(NStr("ru = 'Ошибка отправки сообщения в приемник '; en = 'A message sending error: '") + ErrorDescription());
		EndTry;

		Message(NStr("ru = 'Окончание загрузки через вебсервис '; en = 'A message sending finished '") + CurrentDate());

	EndIf;
	//UT--

EndFunction

Procedure SendAdditionalParametersToDestination()
	
	For Each Parameter In ParametersSettingsTable Do
		
		If Parameter.PassParameterOnExport = True Then
			
			SendSingleParameterToDestination(Parameter.Name, Parameter.Value, Parameter.ConversionRule);
					
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SendTypesInformationToDestination()
	
	If Not IsBlankString(mTypeStringForDestination) Then
		WriteToFile(mTypeStringForDestination);
	EndIf;
		
EndProcedure

// Exports data according to the set modes (exchange rules).
//
// Parameters:
//  No.
//
Procedure ExecuteExport() Export
	
	DataProcessingMode = mDataProcessingModes.DataExported;
	
	InitializeKeepExchangeLog();
	
	InitializeCommentsOnDataExportImport();
	
	ExportIsPossible = True;
	CurrentNestingLevelExportByRule = 0;
	
	mDataExportCallStack = New ValueTable;
	mDataExportCallStack.Columns.Add("Ref");
	mDataExportCallStack.Indexes.Add("Ref");
	
	If mExchangeRulesReadOnImport = True Then
		
		WriteToExecutionLog(74);
		ExportIsPossible = False;	
		
	EndIf;
	
	If IsBlankString(ExchangeRulesFileName) Then
		WriteToExecutionLog(12);
		ExportIsPossible = False;
	EndIf;

	If Not DirectReadFromDestinationIB Then
		
		If IsBlankString(ExchangeFileName) Then
			WriteToExecutionLog(10);
			ExportIsPossible = False;
		EndIf;
		
	Else
		
		mDataImportDataProcessor = EstablishConnectionWithDestinationIB(); 
		
		ExportIsPossible = mDataImportDataProcessor <> Undefined;
		
	EndIf;
	
	// Initializing the external data processor with export handlers.
	InitEventHandlerExternalDataProcessor(ExportIsPossible, ThisObject);
	
	If Not ExportIsPossible Then
		mDataImportDataProcessor = Undefined;
		Return;
	EndIf;
	
	WriteToExecutionLog(SubstituteParametersToString(
		NStr("ru = 'Начало выгрузки: %1'; en = 'Export started at: %1'"), CurrentSessionDate()), , False, , , True);
		
	InitManagersAndMessages();
	
	mExportedObjectCounter = 0;
	mSnCounter 				= 0;
	ErrorFlag                  = False;

	// Importing exchange rules
	If Conversion.Count() = 9 Then
		
		ImportExchangeRules();
		If ErrorFlag Then
			FinishKeepExchangeLog();
			mDataImportDataProcessor = Undefined;
			Return;
		EndIf;
		
	Else
		
		For Each Rule In ConversionRulesTable Do
			Rule.Exported.Clear();
			Rule.OnlyRefsExported.Clear();
		EndDo;
		
	EndIf;

	// Assigning parameters that are set in the dialog.
	SetParametersFromDialog();

	// Opening the exchange file
	CurrentLineToWrite = OpenExportFile() + Chars.LF;

	If ErrorFlag Then
		ExchangeFile = Undefined;
		FinishKeepExchangeLog();
		mDataImportDataProcessor = Undefined;
		Return; 
	EndIf;
	
	// Defining handler interfaces.
	If HandlersDebugModeFlag Then
		
		SupplementRulesWithHandlerInterfaces(Conversion, ConversionRulesTable, ExportRulesTable, CleanupRulesTable);
		
	EndIf;

	If UseTransactions Then
		BeginTransaction();
	EndIf;
	
	Cancel = False;
	
	//UT++
	If UT_ExportViaWebService Then
		SafeMode=False;
	EndIf;
	//UT--

	Try
	
		// Writing the exchange rules to the file.
		ExchangeFile.WriteLine(mXMLRules);
		
		Cancel = Not SendExchangeStartedInformationToDestination(CurrentLineToWrite);
		
		If Not Cancel Then
			
			If SafeMode Then
				SetSafeMode(True);
				For Each SeparatorName In ConfigurationSeparators Do
					SetDataSeparationSafeMode(SeparatorName, True);
				EndDo;
			EndIf;
			
			// BeforeDataExport handler
			Try
				
				If HandlersDebugModeFlag Then
					
					If Not IsBlankString(Conversion.BeforeExportData) Then
						
						Execute(GetHandlerCallString(Conversion, "BeforeExportData"));
						
					EndIf;
					
				Else
					
					Execute(Conversion.BeforeExportData);
					
				EndIf;
				
			Except
				WriteErrorInfoConversionHandlers(62, ErrorDescription(), "BeforeExportData (conversion)");
				Cancel = True;
			EndTry;

			If Not Cancel Then
				
				If ExecuteDataExchangeInOptimizedFormat Then
					SendTypesInformationToDestination();
				EndIf;
				
				// Sending parameters to the destination.
				SendAdditionalParametersToDestination();
				
				EventTextAfterParametersImport = "";
				If Conversion.Property("AfterImportParameters", EventTextAfterParametersImport)
					And Not IsBlankString(EventTextAfterParametersImport) Then
					
					WritingEvent = New XMLWriter;
					WritingEvent.SetString();
					deWriteElement(WritingEvent, "AfterParameterExportAlgorithm", EventTextAfterParametersImport);
					WriteToFile(WritingEvent);
					
				EndIf;

				NodeAndExportRuleMap = New Map();
				StructureForChangeRegistrationDeletion = New Map();
				
				ProcessExportRules(ExportRulesCollection().Rows, NodeAndExportRuleMap);

				SuccessfullyExportedByExchangePlans = ProcessExportForExchangePlans(NodeAndExportRuleMap, StructureForChangeRegistrationDeletion);
				
				If SuccessfullyExportedByExchangePlans Then
				
					ProcessExchangeNodeRecordChangeEditing(StructureForChangeRegistrationDeletion);
				
				EndIf;
				
				// AfterExportData handler
				Try
					
					If HandlersDebugModeFlag Then
						
						If Not IsBlankString(Conversion.AfterExportData) Then
							
							Execute(GetHandlerCallString(Conversion, "AfterExportData"));
							
						EndIf;
						
					Else
						
						Execute(Conversion.AfterExportData);
						
					EndIf;

				Except
					WriteErrorInfoConversionHandlers(63, ErrorDescription(), "AfterExportData (conversion)");
				EndTry;

				WriteNotWrittenObjects();

				If TransactionActive() Then
					CommitTransaction();
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If Cancel Then
			
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			ExecuteInformationTransferOnCompleteDataTransfer();
			
			FinishKeepExchangeLog();
			mDataImportDataProcessor = Undefined;
			ExchangeFile = Undefined;
			
			EventHandlerExternalDataProcessorDestructor();
			
		EndIf;

	Except
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		Cancel = True;
		ErrorRow = ErrorDescription();
		
		WriteToExecutionLog(SubstituteParametersToString(
			NStr("ru = 'Ошибка при выгрузке данных: %1'; en = 'Error exporting data: %1'"), ErrorRow), Undefined, True, , , True);
		
		ExecuteInformationTransferOnCompleteDataTransfer();
		
		FinishKeepExchangeLog();
		CloseFile();
		mDataImportDataProcessor = Undefined;
				
	EndTry;
	
	If Cancel Then
		Return;
	EndIf;
	
	// Closing the exchange file
	CloseFile();
	
	If ArchiveFile Then
		CompressResultingExchangeFile();
	EndIf;
	
	ExecuteInformationTransferOnCompleteDataTransfer();
	
	WriteToExecutionLog(SubstituteParametersToString(
		NStr("ru = 'Окончание выгрузки: %1'; en = 'Export completed at: %1'"), CurrentSessionDate()), , False, , ,True);
	WriteToExecutionLog(SubstituteParametersToString(
		NStr("ru = 'Выгружено объектов: %1'; en = 'Objects exported: %1'"), mExportedObjectCounter), , False, , , True);
	
	FinishKeepExchangeLog();
	
	mDataImportDataProcessor = Undefined;
	
	EventHandlerExternalDataProcessorDestructor();
	
	If IsInteractiveMode Then
		MessageToUser(NStr("ru = 'Выгрузка данных завершена.'; en = 'Data has been exported.'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region SetAttributesValuesAndDataProcessorModalVariables

// Sets the ErrorFlag global variable value.
//
// Parameters:
//  Value - Boolean. A new value of the ErrorFlag variable.
//  
Procedure SetErrorFlag(Value)
	
	ErrorFlag = Value;
	
	If ErrorFlag Then
		
		EventHandlerExternalDataProcessorDestructor(DebugModeFlag);
		
	EndIf;
	
EndProcedure

// Returns the current value of the data processor version.
//
// Parameters:
//  No.
// 
// Returns:
//  Current value of the data processor version.
//
Function ObjectVersionAsString() Export
	
	Return "2.1.8";
	
EndFunction

#EndRegion

#Region InitializingExchangeRulesTables

Procedure AddMissingColumns(Columns, Name, Types = Undefined)
	
	If Columns.Find(Name) <> Undefined Then
		Return;
	EndIf;
	
	Columns.Add(Name, Types);	
	
EndProcedure

// Initializes table columns of object conversion rules.
//
// Parameters:
//  No.
// 
Procedure InitConversionRulesTable()

	Columns = ConversionRulesTable.Columns;
	
	AddMissingColumns(Columns, "Name");
	AddMissingColumns(Columns, "Description");
	AddMissingColumns(Columns, "Order");

	AddMissingColumns(Columns, "SynchronizeByID");
	AddMissingColumns(Columns, "DoNotCreateIfNotFound", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "DoNotExportPropertyObjectsByRefs", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "SearchBySearchFieldsIfNotFoundByID", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "OnMoveObjectByRefSetGIUDOnly", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "UseQuickSearchOnImport", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "GenerateNewNumberOrCodeIfNotSet", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "TinyObjectCount", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "RefExportReferenceCount", deTypeDescription("Number"));
	AddMissingColumns(Columns, "IBItemsCount", deTypeDescription("Number"));
	
	AddMissingColumns(Columns, "ExportMethod");

	AddMissingColumns(Columns, "Source");
	AddMissingColumns(Columns, "Destination");
	
	AddMissingColumns(Columns, "SourceType",  deTypeDescription("String"));

	AddMissingColumns(Columns, "BeforeExport");
	AddMissingColumns(Columns, "OnExport");
	AddMissingColumns(Columns, "AfterExport");
	AddMissingColumns(Columns, "AfterExportToFile");
	
	AddMissingColumns(Columns, "HasBeforeExportHandler",	    deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasOnExportHandler",		deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasAfterExportHandler",		deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasAfterExportToFileHandler",	deTypeDescription("Boolean"));

	AddMissingColumns(Columns, "BeforeImport");
	AddMissingColumns(Columns, "OnImport");
	AddMissingColumns(Columns, "AfterImport");
	
	AddMissingColumns(Columns, "SearchFieldSequence");
	AddMissingColumns(Columns, "SearchInTabularSections");
	
	AddMissingColumns(Columns, "HasBeforeImportHandler", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasOnImportHandler",    deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "HasAfterImportHandler",  deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "HasSearchFieldSequenceHandler",  deTypeDescription("Boolean"));

	AddMissingColumns(Columns, "SearchProperties",	deTypeDescription("ValueTable"));
	AddMissingColumns(Columns, "Properties",		deTypeDescription("ValueTable"));
	
	AddMissingColumns(Columns, "Values",		deTypeDescription("Map"));

	AddMissingColumns(Columns, "Exported",							deTypeDescription("Map"));
	AddMissingColumns(Columns, "OnlyRefsExported",				deTypeDescription("Map"));
	AddMissingColumns(Columns, "ExportSourcePresentation",		deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "DoNotReplace",					deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "RememberExported",       deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "AllObjectsExported",         deTypeDescription("Boolean"));
	
EndProcedure

// Initializes table columns of data export rules.
//
// Parameters:
//  No
// 
Procedure InitExportRulesTable()

	Columns = ExportRulesTable.Columns;

	AddMissingColumns(Columns, "Enable",		deTypeDescription("Number"));
	AddMissingColumns(Columns, "IsGroup",		deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "Name");
	AddMissingColumns(Columns, "Description");
	AddMissingColumns(Columns, "Order");

	AddMissingColumns(Columns, "DataFilterMethod");
	AddMissingColumns(Columns, "SelectionObject");
	
	AddMissingColumns(Columns, "ConversionRule");

	AddMissingColumns(Columns, "BeforeProcess");
	AddMissingColumns(Columns, "AfterProcess");

	AddMissingColumns(Columns, "BeforeExport");
	AddMissingColumns(Columns, "AfterExport");
	
	// Columns for filtering using the query builder.
	AddMissingColumns(Columns, "UseFilter", deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "BuilderSettings");
	AddMissingColumns(Columns, "ObjectNameForQuery");
	AddMissingColumns(Columns, "ObjectNameForRegisterQuery");
	
	AddMissingColumns(Columns, "SelectExportDataInSingleQuery", deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "ExchangeNodeRef");

	//UT
	AddMissingColumns(Columns, "MetadataName");
	AddMissingColumns(Columns, "Filter");

EndProcedure

// Initializes table columns of data cleanup rules.
//
// Parameters:
//  No.
// 
Procedure InitCleanupRulesTable()

	Columns = CleanupRulesTable.Columns;

	AddMissingColumns(Columns, "Enable",		deTypeDescription("Boolean"));
	AddMissingColumns(Columns, "IsGroup",		deTypeDescription("Boolean"));
	
	AddMissingColumns(Columns, "Name");
	AddMissingColumns(Columns, "Description");
	AddMissingColumns(Columns, "Order",	deTypeDescription("Number"));

	AddMissingColumns(Columns, "DataFilterMethod");
	AddMissingColumns(Columns, "SelectionObject");
	
	AddMissingColumns(Columns, "DeleteForPeriod");
	AddMissingColumns(Columns, "Directly",	deTypeDescription("Boolean"));

	AddMissingColumns(Columns, "BeforeProcess");
	AddMissingColumns(Columns, "AfterProcess");
	AddMissingColumns(Columns, "BeforeDelete");
	
EndProcedure

// Инициализирует колонки таблицы настройки параметров.
//
// Параметры:
//  Нет.
// 
Procedure InitParametersSettingsTable()

	Columns = ParametersSettingsTable.Columns;

	AddMissingColumns(Columns, "Name");
	AddMissingColumns(Columns, "Description");
	AddMissingColumns(Columns, "Value");
	AddMissingColumns(Columns, "PassParameterOnExport");
	AddMissingColumns(Columns, "ConversionRule");

EndProcedure

#EndRegion

#Region InitAttributesAndModuleVariables

Procedure InitializeCommentsOnDataExportImport()
	
	CommentOnDataExport = "";
	CommentOnDataImport = "";
	
EndProcedure

// Initializes the deMessages variable that contains mapping of message codes and their description.
//
// Parameters:
//  No.
// 
Procedure InitMessages()

	deMessages = New Map;
	
	deMessages.Insert(2,  NStr("ru = 'Ошибка распаковки файла обмена. Файл заблокирован'; en = 'An error occurred when unpacking an exchange file. The file is locked'"));
	deMessages.Insert(3,  NStr("ru = 'Указанный файл правил обмена не существует'; en = 'The specified exchange rule file does not exist'"));
	deMessages.Insert(4,  NStr("ru = 'Ошибка при создании COM-объекта Msxml2.DOMDocument'; en = 'Error creating Msxml2.DOMDocument COM object.'"));
	deMessages.Insert(5,  NStr("ru = 'Ошибка открытия файла обмена'; en = 'Error opening exchange file'"));
	deMessages.Insert(6,  NStr("ru = 'Ошибка при загрузке правил обмена'; en = 'Error importing exchange rules'"));
	deMessages.Insert(7,  NStr("ru = 'Ошибка формата правил обмена'; en = 'Exchange rule format error'"));
	deMessages.Insert(8,  NStr("ru = 'Некорректно указано имя файла для выгрузки данных'; en = 'File name for data export is specified incorrectly'"));
	deMessages.Insert(9,  NStr("ru = 'Ошибка формата файла обмена'; en = 'Exchange file format error'"));
	deMessages.Insert(10, NStr("ru = 'Не указано имя файла для выгрузки данных (Имя файла данных)'; en = 'Data export file name is not specified.'"));
	deMessages.Insert(11, NStr("ru = 'Ссылка на несуществующий объект метаданных в правилах обмена'; en = 'Exchange rules contain a reference to a nonexistent metadata object'"));
	deMessages.Insert(12, NStr("ru = 'Не указано имя файла с правилами обмена (Имя файла правил)'; en = 'Exchange rule file name is not specified.'"));
	
	deMessages.Insert(13, NStr("ru = 'Ошибка получения значения свойства объекта (по имени свойства источника)'; en = 'Error retrieving object property value (by source property name).'"));
	deMessages.Insert(14, NStr("ru = 'Ошибка получения значения свойства объекта (по имени свойства приемника)'; en = 'Error retrieving object property value (by destination property name).'"));
	
	deMessages.Insert(15, NStr("ru = 'Не указано имя файла для загрузки данных (Имя файла для загрузки)'; en = 'Import file name is not specified.'"));
	
	deMessages.Insert(16, NStr("ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства источника)'; en = 'Error retrieving subordinate object property value (by source property name).'"));
	deMessages.Insert(17, NStr("ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства приемника)'; en = 'Error retrieving subordinate object property value (by destination property name).'"));
	
	deMessages.Insert(19, NStr("ru = 'Ошибка в обработчике события ПередЗагрузкойОбъекта'; en = 'BeforeImportObject event handler error'"));
	deMessages.Insert(20, NStr("ru = 'Ошибка в обработчике события ПриЗагрузкеОбъекта'; en = 'OnImportObject event handler error'"));
	deMessages.Insert(21, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиОбъекта'; en = 'AfterImportObject event handler error'"));
	deMessages.Insert(22, NStr("ru = 'Ошибка в обработчике события ПередЗагрузкойДанных (конвертация)'; en = 'BeforeDataImport event handler error (data conversion).'"));
	deMessages.Insert(23, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиДанных (конвертация)'; en = 'AfterDataImport event handler error (data conversion).'"));
	deMessages.Insert(24, NStr("ru = 'Ошибка при удалении объекта'; en = 'Error deleting object'"));
	deMessages.Insert(25, NStr("ru = 'Ошибка при записи документа'; en = 'Error writing document'"));
	deMessages.Insert(26, NStr("ru = 'Ошибка записи объекта'; en = 'Error writing object'"));
	deMessages.Insert(27, NStr("ru = 'Ошибка в обработчике события ПередОбработкойПравилаОчистки'; en = 'BeforeProcessClearingRule event handler error'"));
	deMessages.Insert(28, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаОчистки'; en = 'AfterProcessClearingRule event handler error'"));
	deMessages.Insert(29, NStr("ru = 'Ошибка в обработчике события ПередУдалениемОбъекта'; en = 'BeforeDeleteObject event handler error'"));
	
	deMessages.Insert(31, NStr("ru = 'Ошибка в обработчике события ПередОбработкойПравилаВыгрузки'; en = 'BeforeProcessExportRule event handler error'"));
	deMessages.Insert(32, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаВыгрузки'; en = 'AfterProcessExportRule event handler error'"));
	deMessages.Insert(33, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта'; en = 'BeforeExportObject event handler error'"));
	deMessages.Insert(34, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта'; en = 'AfterExportObject event handler error'"));
	
	deMessages.Insert(39, NStr("ru = 'Ошибка при выполнении алгоритма, содержащегося в файле обмена'; en = 'Error executing algorithm from exchange file.'"));
	
	deMessages.Insert(41, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта'; en = 'BeforeExportObject event handler error'"));
	deMessages.Insert(42, NStr("ru = 'Ошибка в обработчике события ПриВыгрузкеОбъекта'; en = 'OnExportObject event handler error'"));
	deMessages.Insert(43, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта'; en = 'AfterExportObject event handler error'"));
	
	deMessages.Insert(45, NStr("ru = 'Не найдено правило конвертации объектов'; en = 'No conversion rule is found'"));
	
	deMessages.Insert(48, NStr("ru = 'Ошибка в обработчике события ПередОбработкойВыгрузки группы свойств'; en = 'BeforeProcessExport property group event handler error'"));
	deMessages.Insert(49, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиВыгрузки группы свойств'; en = 'AfterProcessExport property group event handler error'"));
	deMessages.Insert(50, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкой (объекта коллекции)'; en = 'BeforeExport event handler error (collection object).'"));
	deMessages.Insert(51, NStr("ru = 'Ошибка в обработчике события ПриВыгрузке (объекта коллекции)'; en = 'OnExport event handler error (collection object).'"));
	deMessages.Insert(52, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузки (объекта коллекции)'; en = 'AfterExport event handler error (collection object).'"));
	deMessages.Insert(53, NStr("ru = 'Ошибка в глобальном обработчике события ПередЗагрузкойОбъекта (конвертация)'; en = 'BeforeImportObject global event handler error (data conversion).'"));
	deMessages.Insert(54, NStr("ru = 'Ошибка в глобальном обработчике события ПослеЗагрузкиОбъекта (конвертация)'; en = 'AfterImportObject global event handler error (data conversion).'"));
	deMessages.Insert(55, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкой (свойства)'; en = 'BeforeExport event handler error (property).'"));
	deMessages.Insert(56, NStr("ru = 'Ошибка в обработчике события ПриВыгрузке (свойства)'; en = 'OnExport event handler error (property).'"));
	deMessages.Insert(57, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузки (свойства)'; en = 'AfterExport event handler error (property).'"));
	
	deMessages.Insert(62, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойДанных (конвертация)'; en = 'BeforeExportData event handler error (data conversion).'"));
	deMessages.Insert(63, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиДанных (конвертация)'; en = 'AfterExportData event handler error (data conversion).'"));
	deMessages.Insert(64, NStr("ru = 'Ошибка в глобальном обработчике события ПередКонвертациейОбъекта (конвертация)'; en = 'BeforeObjectConversion global event handler error (data conversion).'"));
	deMessages.Insert(65, NStr("ru = 'Ошибка в глобальном обработчике события ПередВыгрузкойОбъекта (конвертация)'; en = 'BeforeExportObject global event handler error (data conversion).'"));
	deMessages.Insert(66, NStr("ru = 'Ошибка получения коллекции подчиненных объектов из входящих данных'; en = 'Error retrieving subordinate object collection from incoming data'"));
	deMessages.Insert(67, NStr("ru = 'Ошибка получения свойства подчиненного объекта из входящих данных'; en = 'Error retrieving subordinate object properties from incoming data'"));
	deMessages.Insert(68, NStr("ru = 'Ошибка получения свойства объекта из входящих данных'; en = 'Error retrieving object properties from incoming data'"));
	
	deMessages.Insert(69, NStr("ru = 'Ошибка в глобальном обработчике события ПослеВыгрузкиОбъекта (конвертация)'; en = 'AfterExportObject global event handler error (data conversion).'"));
	
	deMessages.Insert(71, NStr("ru = 'Не найдено соответствие для значения Источника'; en = 'The map of the Source value is not found'"));
	
	deMessages.Insert(72, NStr("ru = 'Ошибка при выгрузке данных для узла плана обмена'; en = 'Error exporting data for exchange plan node'"));
	
	deMessages.Insert(73, NStr("ru = 'Ошибка в обработчике события ПоследовательностьПолейПоиска'; en = 'SearchFieldSequence event handler error'"));
	
	deMessages.Insert(74, NStr("ru = 'Необходимо перезагрузить правила обмена для выгрузки данных'; en = 'Exchange rules for data export must be reread'"));
	
	deMessages.Insert(75, NStr("ru = 'Ошибка при выполнении алгоритма после загрузки значений параметров'; en = 'Error executing algorithm after parameter value import'"));
	
	deMessages.Insert(76, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъектаВФайл'; en = 'AfterExportObjectToFile event handler error'"));
	
	deMessages.Insert(77, NStr("ru = 'Не указан файл внешней обработки с подключаемыми процедурами обработчиков событий'; en = 'The external data processor file with pluggable event handler procedures is not specified'"));
	
	deMessages.Insert(78, NStr("ru = 'Ошибка создания внешней обработки из файла с процедурами обработчиков событий'; en = 'Error creating external data processor from file with event handler procedures'"));
	
	deMessages.Insert(79, NStr("ru = 'Код алгоритмов не может быть интегрирован в обработчик из-за обнаруженного рекурсивного вызова алгоритмов. 
	                         |Если в процессе отладки нет необходимости отлаживать код алгоритмов, то укажите режим ""не отлаживать алгоритмы""
	                         |Если необходимо выполнять отладку алгоритмов с рекурсивным вызовом, то укажите режим  ""алгоритмы отлаживать как процедуры"" 
	                         |и повторите выгрузку.'; 
	                         |en = 'Algorithm code cannot be integrated into the handler due to detected recursive algorithm call.
	                         |If algorithm code debugging is not required in the debug process, specify the ""without algorithm debugging"" mode.
	                         |If it is required to debug algorithms with recursive call, specify the ""debug algorithms as procedures"" mode 
	                         |and try again.'"));
	
	deMessages.Insert(80, NStr("ru = 'Обмен данными можно проводить только под полными правами'; en = 'You must have the full rights to execute the data exchange'"));
	
	deMessages.Insert(1000, NStr("ru = 'Ошибка при создании временного файла выгрузки данных'; en = 'Error creating temporary data export file'"));

EndProcedure

Procedure SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, TypeName, Manager,
	TypeNamePrefix, SearchByPredefinedItemsPossible = False)

	Name              = MDObject.Name;
	RefTypeString = TypeNamePrefix + "." + Name;
	SearchString     = "SELECT Ref FROM " + TypeName + "." + Name + " WHERE ";
	RefType        = Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject);
	Structure.Insert("SearchByPredefinedItemsPossible", SearchByPredefinedItemsPossible);
	Structure.Insert("SearchString", SearchString);
	Managers.Insert(RefType, Structure);
	StructureForExchangePlan = ExchangePlanParametersStructure(Name, RefType, True, False);
	ManagersForExchangePlans.Insert(MDObject, StructureForExchangePlan);
	
EndProcedure

Procedure SupplementManagerArrayWithRegisterType(Managers, MDObject, TypeName, Manager, RecordTypeNamePrefix, SelectionTypeNamePrefix)

	Periodic = Undefined;
	
	Name					= MDObject.Name;
	RefTypeString	= RecordTypeNamePrefix + "." + Name;
	RefType			= Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject);
	
	If TypeName = "InformationRegister" Then
		
		Periodic = (MDObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical);
		SubordinatedToRecorder = (MDObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		
		Structure.Insert("Periodic", Periodic);
		Structure.Insert("SubordinateToRecorder", SubordinatedToRecorder);
		
	EndIf;	
	
	Managers.Insert(RefType, Structure);
	StructureForExchangePlan = ExchangePlanParametersStructure(Name, RefType, False, True);

	ManagersForExchangePlans.Insert(MDObject, StructureForExchangePlan);
	RefTypeString	= SelectionTypeNamePrefix + "." + Name;
	RefType			= Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject);

	If Periodic <> Undefined Then
		
		Structure.Insert("Periodic", Periodic);
		Structure.Insert("SubordinateToRecorder", SubordinatedToRecorder);	
		
	EndIf;
	
	Managers.Insert(RefType, Structure);	
		
EndProcedure

// Initializes the Managers variable that contains mapping of object types and their properties.
//
// Parameters:
//  No.
// 
Procedure ManagersInitialization()

	Managers = New Map;
	
	ManagersForExchangePlans = New Map;
    	
	// REFERENCES
	
	For Each MDObject In Metadata.Catalogs Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "Catalog",
			Catalogs[MDObject.Name], "CatalogRef", True);
					
	EndDo;

	For Each MDObject In Metadata.Documents Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "Document",
			Documents[MDObject.Name], "DocumentRef");
				
	EndDo;

	For Each MDObject In Metadata.ChartsOfCharacteristicTypes Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "ChartOfCharacteristicTypes",
			ChartsOfCharacteristicTypes[MDObject.Name], "ChartOfCharacteristicTypesRef", True);
				
	EndDo;
	
	For Each MDObject In Metadata.ChartsOfAccounts Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "ChartOfAccounts",
			ChartsOfAccounts[MDObject.Name], "ChartOfAccountsRef", True);
						
	EndDo;
	
	For Each MDObject In Metadata.ChartsOfCalculationTypes Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "ChartOfCalculationTypes",
			ChartsOfCalculationTypes[MDObject.Name], "ChartOfCalculationTypesRef", True);
				
	EndDo;
	
	For Each MDObject In Metadata.ExchangePlans Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "ExchangePlan",
			ExchangePlans[MDObject.Name], "ExchangePlanRef");
				
	EndDo;
	
	For Each MDObject In Metadata.Tasks Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "Task",
			Tasks[MDObject.Name], "TaskRef");
				
	EndDo;
	
	For Each MDObject In Metadata.BusinessProcesses Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MDObject, "BusinessProcess",
			BusinessProcesses[MDObject.Name], "BusinessProcessRef");
		
		TypeName = "BusinessProcessRoutePoint";
		// Route point references
		Name              = MDObject.Name;
		Manager         = BusinessProcesses[Name].RoutePoints;
		SearchString     = "";
		RefTypeString = "BusinessProcessRoutePointRef." + Name;
		RefType        = Type(RefTypeString);
		Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject);
		Structure.Insert("EmptyRef", Undefined);
		Structure.Insert("SearchString", SearchString);
		Managers.Insert(RefType, Structure);
				
	EndDo;
	
	// REGISTERS

	For Each MDObject In Metadata.InformationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MDObject, "InformationRegister",
			InformationRegisters[MDObject.Name], "InformationRegisterRecord", "InformationRegisterSelection");
						
	EndDo;

	For Each MDObject In Metadata.AccountingRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MDObject, "AccountingRegister",
			AccountingRegisters[MDObject.Name], "AccountingRegisterRecord", "AccountingRegisterSelection");
				
	EndDo;
	
	For Each MDObject In Metadata.AccumulationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MDObject, "AccumulationRegister",
			AccumulationRegisters[MDObject.Name], "AccumulationRegisterRecord", "AccumulationRegisterSelection");
						
	EndDo;
	
	For Each MDObject In Metadata.CalculationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MDObject, "CalculationRegister",
			CalculationRegisters[MDObject.Name], "CalculationRegisterRecord", "CalculationRegisterSelection");
						
	EndDo;
	
	TypeName = "Enum";
	
	For Each MDObject In Metadata.Enums Do
		
		Name              = MDObject.Name;
		Manager         = Enums[Name];
		RefTypeString = "EnumRef." + Name;
		RefType        = Type(RefTypeString);
		Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject);
		Structure.Insert("EmptyRef", Enums[Name].EmptyRef());

		Managers.Insert(RefType, Structure);
		
	EndDo;	
	
	// Constants
	TypeName             = "Constants";
	MDObject            = Metadata.Constants;
	Name					= "Constants";
	Manager			= Constants;
	RefTypeString	= "ConstantsSet";
	RefType			= Type(RefTypeString);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject);
	Managers.Insert(RefType, Structure);
	
EndProcedure

// Initializes object managers and all messages of the data exchange log.
//
// Parameters:
//  No.
// 
Procedure InitManagersAndMessages() Export
	
	If Managers = Undefined Then
		ManagersInitialization();
	EndIf; 

	If deMessages = Undefined Then
		InitMessages();
	EndIf;
	
EndProcedure

// Returns:
//   Structure:
//     * FormatVersion - String -
//     * ID - String -
//     * Description - String -
//     * CreationDateTime - Date -
//     * SourcePlatformVersion - String -
//     * SourceConfigurationSynonym - String -
//     * SourceConfigurationVersion - String -
//     * Source - String -
//     * DestinationPlatformVersion - String -
//     * DestinationConfigurationSynonym - String -
//     * DestinationConfigurationVersion - String -
//     * Destination - String -
//     * AfterImportExchangeRules - String -
//     * BeforeExportData - String -
//     * BeforeGetChangedObjects - String -
//     * AfterGetExchangeNodesInformation - String -
//     * AfterExportData - String -
//     * BeforeSendDeletionInfo - String -
//     * BeforeExportObject - String -
//     * AfterExportObject - String -
//     * BeforeImportObject - String -
//     * AfterImportObject - String -
//     * BeforeConvertObject - String -
//     * BeforeImportData - String -
//     * AfterImportData - String -
//     * AfterImportParameters - String -
//     * OnGetDeletionInfo - String -
//
Function Conversion()
	Return Conversion;
EndFunction

// Returns:
//   Structure:
//     * Name - String -
//     * TypeName - String -
//     * RefTypeString - String -
//     * Manager - CatalogManager, DocumentManager, InformationRegisterManager, etc. -
//     * MDObject - MetadataObject: Catalog, MetadataObject: Document, MetadataObject: InformationRegister, etc. -
//     * OCR - see FindRule
//
Function Managers(Type)
	Return Managers[Type];
EndFunction

Procedure CreateConversionStructure()
	
	Conversion  = New Structure("BeforeExportData, AfterExportData, BeforeExportObject, AfterExportObject, BeforeConvertObject, BeforeImportObject, AfterImportObject, BeforeImportData, AfterImportData");
	
EndProcedure

// Initializes data processor attributes and module variables.
//
// Parameters:
//  No.
// 
Procedure InitAttributesAndModuleVariables()

	ProcessedObjectsCountToUpdateStatus = 100;
	
	RememberImportedObjects     = True;
	ImportedObjectToStoreCount = 5000;
	
	ParametersInitialized        = False;

	XMLWriterAdvancedMonitoring = False;
	DirectReadFromDestinationIB = False;
	DoNotShowInfoMessagesToUser = False;

	Managers    = Undefined;
	deMessages  = Undefined;
	
	ErrorFlag   = False;
	
	CreateConversionStructure();
	
	Rules      = New Structure;
	Algorithms    = New Structure;
	AdditionalDataProcessors = New Structure;
	Queries      = New Structure;

	Parameters    = New Structure;
	EventsAfterParametersImport = New Structure;
	
	AdditionalDataProcessorParameters = New Structure;
	
	// Types
	deStringType                  = Type("String");
	deBooleanType                  = Type("Boolean");
	deNumberType                   = Type("Number");
	deDateType                    = Type("Date");
	deValueStorageType       = Type("ValueStorage");
	deUUIDType = Type("UUID");
	deBinaryDataType          = Type("BinaryData");
	deAccumulationRecordTypeType   = Type("AccumulationRecordType");
	deObjectDeletionType         = Type("ObjectDeletion");
	deAccountTypeType			     = Type("AccountType");
	deTypeType                     = Type("Type");
	deMapType            = Type("Map");

	BlankDateValue		   = Date('00010101');
	
	mXMLRules  = Undefined;
	
	// XML node types
	
	deXMLNodeType_EndElement  = XMLNodeType.EndElement;
	deXMLNodeType_StartElement = XMLNodeType.StartElement;
	deXMLNodeType_Text          = XMLNodeType.Text;
	mExchangeRuleTemplateList  = New ValueList;

	For each Template In Metadata().Templates Do
		mExchangeRuleTemplateList.Add(Template.Synonym);
	EndDo;

	mDataLogFile = Undefined;

	ConnectedInfobaseType = True;
	InfobaseConnectionWindowsAuthentication = False;
	PlatformVersionForInfobaseConnection = "V8";
	OpenExchangeLogAfterExecutingOperations = False;
	ImportDataInExchangeMode = True;
	WriteToInfobaseOnlyChangedObjects = True;
	WriteRegistersAsRecordSets = True;
	OptimizedObjectsWriting = True;
	ExportAllowedObjectsOnly = True;
	ImportReferencedObjectsWithoutDeletionMark = True;
	UseFilterByDateForAllObjects = True;

	mEmptyTypeValueMap = New Map;
	mTypeDescriptionMap = New Map;
	
	mExchangeRulesReadOnImport = False;

	ReadEventHandlersFromExchangeRulesFile = True;

	mDataProcessingModes = New Structure;
	mDataProcessingModes.Insert("Export",                   0);
	mDataProcessingModes.Insert("Import",                   1);
	mDataProcessingModes.Insert("ExchangeRulesImport",       2);
	mDataProcessingModes.Insert("EventHandlersExport", 3);

	DataProcessingMode = mDataProcessingModes.DataExported;
	
	mAlgorithmDebugModes = New Structure;
	mAlgorithmDebugModes.Insert("DontUse",   0);
	mAlgorithmDebugModes.Insert("ProceduralCall", 1);
	mAlgorithmDebugModes.Insert("CodeIntegration",   2);
	
	AlgorithmDebugMode = mAlgorithmDebugModes.DontUse;
	
	// Standard subsystem modules.
	Try
		// Calling CalculateInSafeMode is not required as a string literal is being passed for calculation.
		ModulePeriodClosingDates = Eval("PeriodClosingDates");
	Except
		ModulePeriodClosingDates = Undefined;
	EndTry;
	
	ConfigurationSeparators = New Array;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			ConfigurationSeparators.Add(CommonAttribute.Name);
		EndIf;
	EndDo;
	ConfigurationSeparators = New FixedArray(ConfigurationSeparators);

	FilesTempDirectory = GetTempFileName();
	DeleteFiles(FilesTempDirectory);

EndProcedure

Function DetermineIfEnoughInfobaseConnectionParameters(ConnectionStructure, StringForConnection = "", ErrorMessageString = "")
	
	ErrorsExist = False;
	
	If ConnectionStructure.FileMode  Then
		
		If IsBlankString(ConnectionStructure.IBDirectory) Then
			
			ErrorMessageString = NStr("ru='Не задан каталог информационной базы-приемника'; en = 'The destination infobase directory is not specified.'");
			
			MessageToUser(ErrorMessageString);
			
			ErrorsExist = True;
			
		EndIf;
		
		StringForConnection = "File=""" + ConnectionStructure.IBDirectory + """";
	Else
		
		If IsBlankString(ConnectionStructure.ServerName) Then
			
			ErrorMessageString = NStr("ru='Не задано имя сервера 1С:Предприятия информационной базы-приемника'; en = 'The destination infobase platform server name is not specified.'");
			
			MessageToUser(ErrorMessageString);
			
			ErrorsExist = True;
			
		EndIf;
		
		If IsBlankString(ConnectionStructure.IBNameAtServer) Then
			
			ErrorMessageString = NStr("ru='Не задано имя информационной базы-приемника на сервере 1С:Предприятия'; en = 'The destination infobase name on the platform server is not specified.'");
			
			MessageToUser(ErrorMessageString);
			
			ErrorsExist = True;
			
		EndIf;		
		
		StringForConnection = "Srvr = """ + ConnectionStructure.ServerName + """; Ref = """ + ConnectionStructure.IBNameAtServer + """";		
		
	EndIf;
	
	Return Not ErrorsExist;	
	
EndFunction

Function ConnectToInfobase(ConnectionStructure, ErrorMessageString = "")
	
	Var ConnectionString;
	
	EnoughParameters = DetermineIfEnoughInfobaseConnectionParameters(ConnectionStructure, ConnectionString, ErrorMessageString);
	
	If Not EnoughParameters Then
		Return Undefined;
	EndIf;
	
	If Not ConnectionStructure.WindowsAuthentication Then
		If Not IsBlankString(ConnectionStructure.User) Then
			ConnectionString = ConnectionString + ";Usr = """ + ConnectionStructure.User + """";
		EndIf;
		If Not IsBlankString(ConnectionStructure.Password) Then
			ConnectionString = ConnectionString + ";Pwd = """ + ConnectionStructure.Password + """";
		EndIf;
	EndIf;
	
	// "V82" or "V83"
	ConnectionObject = ConnectionStructure.PlatformVersion;
	
	ConnectionString = ConnectionString + ";";
	
	Try
		
		ConnectionObject = ConnectionObject +".COMConnector";
		CurrentCOMConnection = New COMObject(ConnectionObject);
		CurCOMObject = CurrentCOMConnection.Connect(ConnectionString);
		
	Except
		
		ErrorMessageString = NStr("ru = 'При попытке соединения с COM-сервером произошла следующая ошибка:
			|%1'; 
			|en = 'When trying to connect to the COM server, the following error occurred:
			|%1'");
		ErrorMessageString = SubstituteParametersToString(ErrorMessageString, ErrorDescription());
		
		MessageToUser(ErrorMessageString);
		
		Return Undefined;
		
	EndTry;
	
	Return CurCOMObject;
	
EndFunction

// Returns the string part that follows the last specified character.
Function GetStringAfterCharacter(Val SourceString, Val SearchChar)
	
	CharPosition = StrLen(SourceString);
	While CharPosition >= 1 Do
		
		If Mid(SourceString, CharPosition, 1) = SearchChar Then
						
			Return Mid(SourceString, CharPosition + 1); 
			
		EndIf;
		
		CharPosition = CharPosition - 1;	
	EndDo;

	Return "";
  	
EndFunction

// Returns the file extension.
//
// Parameters:
//  FileName     - a string containing the file name (with or without the directory name).
//
// Returns:
//   String - the file extension.
//
Function GetFileNameExtension(Val FileName) Export
	
	Extension = GetStringAfterCharacter(FileName, ".");
	Return Extension;
	
EndFunction

Function GetLogNameForCOMConnectionSecondInfobase() Export
	
	If Not IsBlankString(ImportExchangeLogFileName) Then
			
		Return ImportExchangeLogFileName;	
		
	ElsIf Not IsBlankString(ExchangeLogFileName) Then
		
		LogFileExtension = GetFileNameExtension(ExchangeLogFileName);
		
		If Not IsBlankString(LogFileExtension) Then
							
			ExportLogFileName = StrReplace(ExchangeLogFileName, "." + LogFileExtension, "");
			
		EndIf;
		
		ExportLogFileName = ExportLogFileName + "_Import";
		
		If Not IsBlankString(LogFileExtension) Then
			
			ExportLogFileName = ExportLogFileName + "." + LogFileExtension;	
			
		EndIf;
		
		Return ExportLogFileName;
		
	EndIf;
	
	Return "";
	
EndFunction

// Establishing the connection to the destination infobase by the specified parameters.
// Returns the initialized UniversalDataExchangeXML destination infobase data processor, which is 
// used for importing data into the destination infobase.
//
// Parameters:
//  No.
// 
//  Returns:
//    DataProcessorObject - UniversalDataExchangeXML - processing receiver base to import data there.
//
Function EstablishConnectionWithDestinationIB() Export
	
	ConnectionResult = Undefined;
	
	ConnectionStructure = New Structure();
	ConnectionStructure.Insert("FileMode", ConnectedInfobaseType);
	ConnectionStructure.Insert("WindowsAuthentication", InfobaseConnectionWindowsAuthentication);
	ConnectionStructure.Insert("IBDirectory", InfobaseConnectionDirectory);
	ConnectionStructure.Insert("ServerName", InfobaseConnectionServerName);
	ConnectionStructure.Insert("IBNameAtServer", InfobaseConnectionNameAtServer);
	ConnectionStructure.Insert("User", InfobaseConnectionUsername);
	ConnectionStructure.Insert("Password", InfobaseConnectionPassword);
	ConnectionStructure.Insert("PlatformVersion", PlatformVersionForInfobaseConnection);

	ConnectionObject = ConnectToInfobase(ConnectionStructure);
	
	If ConnectionObject = Undefined Then
		Return Undefined;
	EndIf;
	
	Try
		ConnectionResult = ConnectionObject.DataProcessors.UniversalDataExchangeXML.Create();
	Except
		
		Text = NStr("ru='При попытке создания обработки УниверсальныйОбменДаннымиXML произошла ошибка: %1'; en = 'Creating the UniversalDataExchangeXML data processor failed with the following error: %1'");
		Text = SubstituteParametersToString(Text, BriefErrorDescription(ErrorInfo()));
		MessageToUser(Text);
		ConnectionResult = Undefined;
	EndTry;
	
	If ConnectionResult <> Undefined Then

		ConnectionResult.UseTransactions = UseTransactions;
		ConnectionResult.ObjectsPerTransaction = ObjectsPerTransaction;

		ConnectionResult.DebugModeFlag = DebugModeFlag;

		ConnectionResult.ExchangeLogFileName = GetLogNameForCOMConnectionSecondInfobase();

		ConnectionResult.AppendDataToExchangeLog = AppendDataToExchangeLog;
		ConnectionResult.WriteInfoMessagesToLog = WriteInfoMessagesToLog;

		ConnectionResult.ExchangeMode = "Import";

	EndIf;
	
	Return ConnectionResult;
	
EndFunction

// Deletes objects of the specified type according to the data clearing rules (deletes physically or 
// marks for deletion.)
//
// Parameters:
//  TypeNameToRemove - String - a string type name.
// 
Procedure DeleteObjectsOfType(TypeNameToDelete) Export
	
	DataToDeleteType = Type(TypeNameToDelete);
	
	Manager = Managers[DataToDeleteType];
	TypeName  = Manager.TypeName;
	Properties = Managers[DataToDeleteType];
	
	Rule = New Structure("Name,Directly,BeforeDelete", "ObjectDeletion", True, "");
					
	Selection = GetSelectionForDataClearingExport(Properties, TypeName, True, True, False);
	
	While Selection.Next() Do
		
		If TypeName =  "InformationRegister" Then
			
			RecordManager = Properties.Manager.CreateRecordManager(); 
			FillPropertyValues(RecordManager, Selection);
								
			SelectionObjectDeletion(RecordManager, Rule, Properties, Undefined);
				
		Else
				
			SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, Undefined);
				
		EndIf;
			
	EndDo;	
	
EndProcedure

Procedure SupplementInternalTablesWithColumns()
	
	InitConversionRulesTable();
	InitExportRulesTable();
	InitCleanupRulesTable();
	InitParametersSettingsTable();	
	
EndProcedure

Function GetNewUniqueTempFileName(OldTempFileName, Extension = "txt")
	
	DeleteTempFiles(OldTempFileName);
	
	Return GetTempFileName(Extension);
	
EndFunction 

Procedure InitHandlersNamesStructure()
	
	// Conversion handlers.
	ConversionHandlersNames = New Structure;
	ConversionHandlersNames.Insert("BeforeExportData");
	ConversionHandlersNames.Insert("AfterExportData");
	ConversionHandlersNames.Insert("BeforeExportObject");
	ConversionHandlersNames.Insert("AfterExportObject");
	ConversionHandlersNames.Insert("BeforeConvertObject");
	ConversionHandlersNames.Insert("BeforeSendDeletionInfo");
	ConversionHandlersNames.Insert("BeforeGetChangedObjects");
	
	ConversionHandlersNames.Insert("BeforeImportObject");
	ConversionHandlersNames.Insert("AfterImportObject");
	ConversionHandlersNames.Insert("BeforeImportData");
	ConversionHandlersNames.Insert("AfterImportData");
	ConversionHandlersNames.Insert("OnGetDeletionInfo");
	ConversionHandlersNames.Insert("AfterGetExchangeNodesInformation");
	
	ConversionHandlersNames.Insert("AfterImportExchangeRules");
	ConversionHandlersNames.Insert("AfterImportParameters");
	
	// OCR handlers.
	OCRHandlersNames = New Structure;
	OCRHandlersNames.Insert("BeforeExport");
	OCRHandlersNames.Insert("OnExport");
	OCRHandlersNames.Insert("AfterExport");
	OCRHandlersNames.Insert("AfterExportToFile");
	
	OCRHandlersNames.Insert("BeforeImport");
	OCRHandlersNames.Insert("OnImport");
	OCRHandlersNames.Insert("AfterImport");
	
	OCRHandlersNames.Insert("SearchFieldSequence");
	
	// PCR handlers.
	PCRHandlersNames = New Structure;
	PCRHandlersNames.Insert("BeforeExport");
	PCRHandlersNames.Insert("OnExport");
	PCRHandlersNames.Insert("AfterExport");

	// PGCR handlers.
	PGCRHandlersNames = New Structure;
	PGCRHandlersNames.Insert("BeforeExport");
	PGCRHandlersNames.Insert("OnExport");
	PGCRHandlersNames.Insert("AfterExport");
	
	PGCRHandlersNames.Insert("BeforeProcessExport");
	PGCRHandlersNames.Insert("AfterProcessExport");
	
	// DER handlers.
	DERHandlersNames = New Structure;
	DERHandlersNames.Insert("BeforeProcess");
	DERHandlersNames.Insert("AfterProcess");
	DERHandlersNames.Insert("BeforeExport");
	DERHandlersNames.Insert("AfterExport");
	
	// DCR handlers.
	DCRHandlersNames = New Structure;
	DCRHandlersNames.Insert("BeforeProcess");
	DCRHandlersNames.Insert("AfterProcess");
	DCRHandlersNames.Insert("BeforeDelete");
	
	// Global structure with handler names.
	HandlersNames = New Structure;
	HandlersNames.Insert("Conversion", ConversionHandlersNames); 
	HandlersNames.Insert("OCR",         OCRHandlersNames); 
	HandlersNames.Insert("PCR",         PCRHandlersNames); 
	HandlersNames.Insert("PGCR",        PGCRHandlersNames); 
	HandlersNames.Insert("DER",         DERHandlersNames); 
	HandlersNames.Insert("DPR",         DCRHandlersNames); 
	
EndProcedure  

// Returns:
//   Structure - a value type manager description:
//     * Name - String -
//     * TypeName - String -
//     * RefTypeString - String -
//     * Manager - Arbitrary -
//     * MDObject - MetadataObject -
//     * SearchByPredefinedItemsPossible - Boolean -
//     * OCR - Arbitrary -
//
Function ManagerParametersStructure(Name, TypeName, RefTypeString, Manager, MDObject)
	Structure = New Structure;
	Structure.Insert("Name", Name);
	Structure.Insert("TypeName", TypeName);
	Structure.Insert("RefTypeString", RefTypeString);
	Structure.Insert("Manager", Manager);
	Structure.Insert("MDObject", MDObject);
	Structure.Insert("SearchByPredefinedItemsPossible", False);
	Structure.Insert("OCR");
	Return Structure;
EndFunction

Function ExchangePlanParametersStructure(Name, RefType, IsReferenceObjectType, IsRegister)
	Structure = New Structure;
	Structure.Insert("Name", Name);
	Structure.Insert("RefType", RefType);
	Structure.Insert("IsReferenceObjectType", IsReferenceObjectType);
	Structure.Insert("IsRegister", IsRegister);
	Return Structure;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions to ensure autonomy.

Function SubsystemExists(SubSystemFullName) Export

	SubsystemsNames = SubsystemsNames();
	Return SubsystemsNames.Get(SubSystemFullName) <> Undefined;

EndFunction

Function SubsystemsNames() Export

	Return New FixedMap(ChildSubsystemsNames(Metadata));

EndFunction

Function ChildSubsystemsNames(ParentSubsystem)

	Names = New Map;

	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do

		Names.Insert(CurrentSubsystem.Name, True);
		ChildNames = ChildSubsystemsNames(CurrentSubsystem);

		For Each ChildName In ChildNames Do
			Names.Insert(CurrentSubsystem.Name + "." + ChildName.Key, True);
		EndDo;
	EndDo;

	Return Names;

EndFunction

Function CommonModule(Name) Export

	If Metadata.CommonModules.Find(Name) <> Undefined Then
		Module = Eval(Name);
	Else
		Module = Undefined;
	EndIf;

	If TypeOf(Module) <> Type("CommonModule") Then
		Raise SubstituteParametersToString(NStr("ru = 'Общий модуль ""%1"" не найден.'; en = '%1 module is not found.'"), Name);
	EndIf;

	Return Module;

EndFunction

Procedure MessageToUser(MessageToUserText) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Message();
	
EndProcedure

Function SubstituteParametersToString(Val SubstitutionString,
	Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined)
	
	SubstitutionString = StrReplace(SubstitutionString, "%1", Parameter1);
	SubstitutionString = StrReplace(SubstitutionString, "%2", Parameter2);
	SubstitutionString = StrReplace(SubstitutionString, "%3", Parameter3);
	
	Return SubstitutionString;
	
EndFunction

Function IsExternalDataProcessor()
	
	Return ?(StrFind(EventHandlerExternalDataProcessorFileName, ".") <> 0, True, False);
	
EndFunction

Function PredefinedItemName(Ref)
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	| PredefinedDataName AS PredefinedDataName
	|FROM
	|	" + Ref.Metadata().FullName() + " AS SpecifiedTableAlias
	|WHERE
	|	SpecifiedTableAlias.Ref = &Ref
	|";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.PredefinedDataName;
	
EndFunction

Function RefTypeValue(Value)
	
	Type = TypeOf(Value);
	
	Return Type <> Type("Undefined") 
		And (Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type));
	
EndFunction

Function DefaultLanguageCode()
	Return UT_CommonClientServer.DefaultLanguageCode();
//	If SubsystemExists("StandardSubsystems.BaseFunctionality") Then
//		CommonModule = CommonModule("Common");
//		Return CommonModule.DefaultLanguageCode();
//	EndIf;
//	Return Metadata.DefaultLanguage.LanguageCode;
EndFunction

#EndRegion

#Region UT

// Internal
//
Function GetRowQueryText(MetadataTreeRow, HasAddlFilters, FieldStringForSelection = "") Export

	MetadataObject = Metadata.FindByFullName(MetadataTreeRow.MetadataName);

	MetadataName     = MetadataTreeRow.MetadataName;

	If Metadata.InformationRegisters.Contains(MetadataObject) Then

		QueryText = GetQueryTextForInformationRegister(MetadataName, MetadataObject, HasAddlFilters,
			FieldStringForSelection);
		Return QueryText;

	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Or Metadata.AccountingRegisters.Contains(
		MetadataObject) Then

		QueryText = GetQueryTextForRegister(MetadataName, MetadataObject, HasAddlFilters,
			FieldStringForSelection);
		Return QueryText;

	EndIf;

	RestrictByDate = ValueIsFilled(StartDate) Or ValueIsFilled(EndDate);

	If Not ValueIsFilled(FieldStringForSelection) Then
		FieldStringForSelection = "_.*";
	EndIf;

	QueryText = "SELECT Allowed " + FieldStringForSelection + " FROM " + MetadataName + " AS _ ";
	
	If RestrictByDate Then

		If HasAddlFilters And Not UseFilterByDateForAllObjects Then

			Return QueryText;

		EndIf;

		AddlRestrictionByDate = "";
		
		If Metadata.Documents.Contains(MetadataObject) Then

			AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Document");

		ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Or Metadata.AccumulationRegisters.Contains(
			MetadataObject) Then

			AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Register");

		EndIf;

		QueryText = QueryText + Chars.LF + AddlRestrictionByDate;

	EndIf;

	Return QueryText;

EndFunction

Function GetQueryTextForInformationRegister(MetadataName, MetadataObject, HasAddlFilters,
	FieldStringForSelection = "")

	RestrictByDate = ValueIsFilled(StartDate) Or ValueIsFilled(EndDate);

	If Not ValueIsFilled(FieldStringForSelection) Then
		FieldStringForSelection = "_.*";
	Else
		FieldStringForSelection = " Distinct " + FieldStringForSelection;
	EndIf;

	QueryText = "SELECT Allowed " + FieldStringForSelection + " FROM " + MetadataName + " AS _ ";

	If MetadataObject.InformationRegisterPeriodicity
		= Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		Return QueryText;
	EndIf;
	
	// 0 - filter by period
	// 1 - slice last on an end date
	// 2 - slice first on a begin date
	// 3 - slice first on a begin date + filter by period
	If HasAddlFilters And Not UseFilterByDateForAllObjects Then

		Return QueryText;

	EndIf;

	AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "InformationRegister");

	QueryText = QueryText + Chars.LF + AddlRestrictionByDate;
	Return QueryText;

EndFunction

Function GetQueryTextForRegister(MetadataName, MetadataObject, HasAddlFilters, FieldStringForSelection = "")

	RestrictByDate = ValueIsFilled(StartDate) Or ValueIsFilled(EndDate);

	If Not ValueIsFilled(FieldStringForSelection) Then
		FieldStringForSelection = "_.*";
	Else
		FieldStringForSelection = " DISTINCT " + FieldStringForSelection;
	EndIf;

	QueryText = "SELECT Allowed " + FieldStringForSelection + " FROM " + MetadataName + " AS _ ";
	
	If RestrictByDate Then

		If HasAddlFilters And Not UseFilterByDateForAllObjects Then

			Return QueryText;

		EndIf;

		AddlRestrictionByDate = GetRestrictionByDateStringForQuery(MetadataObject, "Register");

		QueryText = QueryText + Chars.LF + AddlRestrictionByDate;

	EndIf;

	Return QueryText;

EndFunction
Function DataCompositionSchema(QueryText) Export

	DataCompositionSchema = New DataCompositionSchema;

	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "local";

	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	DataSet.Query = QueryText;
	DataSet.Name = "DataSet1";

	Return DataCompositionSchema;

EndFunction

Procedure SetResultOutputStructureSettings(Settings, PutToSpreadsheetDocument = False) Export

	DataCompositionGroup = Settings.Structure.Add(Type("DataCompositionGroup"));

	GroupField = DataCompositionGroup.GroupFields.Items.Add(Type(
		"DataCompositionGroupField"));
	GroupField.Use = True;

	If PutToSpreadsheetDocument And Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref"))
		<> Undefined Then
		SelectionField = DataCompositionGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectionField.Field = New DataCompositionField("Ref");
		SelectionField.Use = True;
	Else
		For Each SelectionAvailableField In Settings.Selection.SelectionAvailableFields.Items Do
			If SelectionAvailableField.Field = New DataCompositionField("SystemFields") Or SelectionAvailableField.Field
				= New DataCompositionField("DataParameters") Then
				Continue;
			EndIf;
			SelectionField = DataCompositionGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
			SelectionField.Field = SelectionAvailableField.Field;
			SelectionField.Use = True;
		EndDo;
	EndIf;

EndProcedure
#EndRegion

#EndRegion

#Region Initializing

InitAttributesAndModuleVariables();
SupplementInternalTablesWithColumns();
InitHandlersNamesStructure();

#EndRegion
