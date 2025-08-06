# Basic09 Scientific Calculator - Detailed Specification

## 1. Program Overview

### Purpose
A comprehensive scientific calculator with data logging, session management, and statistical analysis capabilities that demonstrates all major Basic09 language features.

### Key Features
- Multi-mode calculator (Basic, Scientific, Statistical, Programming)
- Calculation history and session logging
- Data import/export capabilities
- Customizable display formats
- Error handling and recovery
- Modular, extensible design

---

## 2. Data Structure Design

### 2.1 Core Data Types

```basic
TYPE calcResult = value:REAL; errorCode:BYTE; valid:BOOLEAN

TYPE historyEntry = 
  timeStamp:STRING[19];      (* "yy/mm/dd hh:mm:ss" *)
  expression:STRING[80];     (* Input expression *)
  result:calcResult;         (* Calculated result *)
  mode:BYTE                  (* Calculator mode *)

TYPE calcState =
  currentValue:REAL;         (* Display value *)
  memoryValue:REAL;          (* Memory storage *)
  lastResult:REAL;           (* Previous calculation *)
  angleMode:BYTE;            (* 0=RAD, 1=DEG *)
  displayFormat:BYTE;        (* 0=NORMAL, 1=SCI, 2=ENG *)
  decimalPlaces:BYTE;        (* 0-9 decimal places *)
  calcMode:BYTE;             (* 0=BASIC, 1=SCI, 2=STAT, 3=PROG *)
  errorState:BYTE;           (* Current error code *)
  historyCount:INTEGER       (* Number of history entries *)

TYPE configData =
  autoSave:BOOLEAN;          (* Save on exit *)
  maxHistory:INTEGER;        (* History limit *)
  backupInterval:INTEGER;    (* Minutes between backups *)
  startupMode:BYTE;          (* Default calculator mode *)
  soundEnabled:BOOLEAN       (* Beep on errors *)
```

### 2.2 Arrays and Collections

```basic
DIM history(500):historyEntry      (* Calculation history *)
DIM memoryBanks(10):REAL           (* Multiple memory slots *)
DIM statData(1000):REAL            (* Statistical dataset *)
DIM userConstants(26):REAL         (* A-Z user variables *)
DIM functionKeys(12):STRING[20]    (* F1-F12 definitions *)
```

---

## 3. Program Structure

### 3.1 Main Program Flow

```
PROCEDURE calculatorMain
├── Initialize system
├── Load configuration
├── Restore previous session (if exists)
├── Display splash screen
├── Main program loop
│   ├── Display current state
│   ├── Process user input
│   ├── Execute calculation
│   ├── Update history
│   └── Handle errors
└── Cleanup and exit
```

### 3.2 Core Procedures

#### 3.2.1 System Management
- **initCalculator()** - Initialize all data structures
- **loadConfig()** - Read configuration file
- **saveConfig()** - Write configuration file
- **backupSession()** - Create session backup
- **restoreSession()** - Load previous session

#### 3.2.2 User Interface
- **displayMainScreen()** - Show calculator interface
- **showMenu(menuType:BYTE)** - Display various menus
- **getUserInput():STRING** - Input handling with validation
- **formatNumber(value:REAL, format:BYTE):STRING** - Number formatting
- **displayHelp(topic:STRING)** - Context-sensitive help

#### 3.2.3 Calculation Engine
- **parseExpression(expr:STRING):calcResult** - Expression parser
- **evaluateBasic(expr:STRING):calcResult** - Basic arithmetic
- **evaluateScientific(expr:STRING):calcResult** - Scientific functions
- **evaluateStatistical():calcResult** - Statistics calculations
- **evaluateProgramming(expr:STRING):calcResult** - Programming functions

#### 3.2.4 Data Management
- **addToHistory(entry:historyEntry)** - Add calculation to history
- **searchHistory(pattern:STRING)** - Search calculation history
- **exportHistory(filename:STRING)** - Export history to file
- **importData(filename:STRING)** - Import data from file
- **clearHistory()** - Clear calculation history

---

## 4. Feature Specifications

### 4.1 Basic Calculator Mode
**Basic09 Features Demonstrated:**
- INTEGER arithmetic for simple operations
- REAL arithmetic for decimal calculations  
- String concatenation for expression building
- Input validation and error handling

**Functions:**
- Four basic operations (+, -, *, /)
- Percentage calculations
- Memory operations (M+, M-, MR, MC)
- Square root and square functions
- Sign change (+/-)

**Example Operations:**
```
123 + 456 = 579
15% of 240 = 36
√144 = 12
Memory: Store 42, Recall shows 42
```

### 4.2 Scientific Calculator Mode
**Basic09 Features Demonstrated:**
- All mathematical functions (SIN, COS, TAN, LOG, EXP, etc.)
- DEG/RAD mode switching
- Complex expression evaluation
- Type conversion functions

**Functions:**
- Trigonometric functions (with angle mode switching)
- Logarithmic and exponential functions
- Power and root functions
- Constants (π, e)
- Hyperbolic functions (calculated using exponentials)
- Factorial and gamma functions

**Example Operations:**
```
SIN(30°) = 0.5
LOG(100) = 2
2^10 = 1024
π × r² where r=5 → 78.54
```

### 4.3 Statistical Calculator Mode
**Basic09 Features Demonstrated:**
- Array processing for datasets
- Complex loops for data analysis
- Mathematical calculations for statistics
- File I/O for data import/export

**Functions:**
- Data entry and editing
- Descriptive statistics (mean, median, mode, std dev)
- Linear regression and correlation
- Probability distributions
- Data visualization (ASCII histograms)

**Example Operations:**
```
Data: [1,2,3,4,5,6,7,8,9,10]
Mean: 5.5
Std Dev: 3.03
Correlation of X,Y datasets
Histogram display
```

### 4.4 Programming Calculator Mode
**Basic09 Features Demonstrated:**
- Hexadecimal number handling
- Bitwise logical operations (LAND, LOR, LXOR, LNOT)
- Base conversions
- Memory address calculations

**Functions:**
- Number base conversions (BIN, OCT, DEC, HEX)
- Bitwise operations (AND, OR, XOR, NOT)
- Bit shifting operations
- Two's complement arithmetic
- Address calculations

**Example Operations:**
```
$FF AND $0F = $0F
255 → HEX: FF, OCT: 377, BIN: 11111111
Shift left: 8 << 2 = 32
```

---

## 5. File Operations and Data Management

### 5.1 Configuration File (calc.cfg)
**Format:** Sequential text file
**Basic09 Features:** CREATE, OPEN, READ, WRITE, CLOSE

```
Contents:
- Display format preferences
- Angle mode default
- Memory bank contents
- Function key definitions
- User constants A-Z
```

### 5.2 Session File (session.dat)
**Format:** Binary random-access file
**Basic09 Features:** GET, PUT, SEEK operations

```
Structure:
- Current calculator state
- Recent calculation history
- Statistical datasets
- Memory contents
```

### 5.3 History Export (history.txt)
**Format:** CSV text file for external analysis
**Basic09 Features:** Formatted output with PRINT USING

```
Format:
"Date/Time","Expression","Result","Mode"
"24/01/15 10:30:45","SIN(45)","0.707","Scientific"
```

### 5.4 Data Import (data.csv)
**Format:** Comma-separated values for statistical analysis
**Basic09 Features:** String parsing, VAL function, error handling

---

## 6. User Interface Design

### 6.1 Main Display Layout
```
┌─────────────────────────────────────────────────────────┐
│ Basic09 Scientific Calculator v1.0        [MODE: SCI]  │
├─────────────────────────────────────────────────────────┤
│                                            123,456.789  │
│                                                         │
│ Last: SIN(30) = 0.5                                    │
│ Mem:  42.0                              [RAD] [FIX 3]  │
├─────────────────────────────────────────────────────────┤
│ [F1-HELP] [F2-MODE] [F3-MEM] [F4-HIST] [F5-EXPORT]    │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Menu System
**Basic09 Features:** ON GOSUB for menu selection, string formatting

#### Main Menu (F2)
```
1. Basic Calculator
2. Scientific Calculator  
3. Statistical Analysis
4. Programming Functions
5. Configuration
6. File Operations
7. Help System
8. Exit Program
```

#### Memory Menu (F3)
```
1. Store to Memory (MS)
2. Recall Memory (MR)
3. Add to Memory (M+)
4. Subtract from Memory (M-)
5. Clear Memory (MC)
6. Memory Bank Select (0-9)
7. Show All Memory Banks
```

### 6.3 Input Processing
**Basic09 Features:** String functions, INPUT validation, error handling

- Expression parsing with precedence
- Function name recognition
- Variable substitution
- Error detection and reporting
- Command history with arrow keys (simulated)

---

## 7. Error Handling Strategy

### 7.1 Error Types and Codes
```basic
(* Error codes *)
DIM errNone:BYTE = 0
DIM errDivideZero:BYTE = 1
DIM errOverflow:BYTE = 2
DIM errUnderflow:BYTE = 3
DIM errInvalidFunc:BYTE = 4
DIM errDomainError:BYTE = 5
DIM errSyntaxError:BYTE = 6
DIM errFileError:BYTE = 7
DIM errMemoryFull:BYTE = 8
```

### 7.2 Error Handling Implementation
**Basic09 Features:** ON ERROR GOTO, ERR function, ERROR statement

```basic
PROCEDURE handleMathError()
  PARAM errorCode:BYTE
  ON errorCode GOSUB 100,200,300,400,500
  RETURN
  
100 (* Division by zero *)
    PRINT "Error: Division by zero"
    currentState.errorState := errDivideZero
    RETURN
    
200 (* Overflow *)
    PRINT "Error: Number too large"
    currentState.errorState := errOverflow
    RETURN
```

---

## 8. Advanced Features

### 8.1 Expression Parser
**Basic09 Features:** String processing, recursion, complex data structures

- Tokenize input expressions
- Handle operator precedence  
- Process nested parentheses
- Variable substitution
- Function call recognition

### 8.2 History and Session Management
**Basic09 Features:** Arrays, file I/O, date/time functions

- Maintain calculation history
- Search and filter history
- Export calculations
- Session persistence
- Automatic backups

### 8.3 Statistical Analysis
**Basic09 Features:** Mathematical functions, array processing, loops

- Descriptive statistics
- Linear regression
- Correlation analysis
- Probability calculations
- Data visualization

### 8.4 Customization System
**Basic09 Features:** Complex data types, file operations

- User-defined constants
- Function key programming  
- Display format preferences
- Startup configuration
- Theme customization

---

## 9. Testing Strategy

### 9.1 Unit Testing Procedures
- **testBasicArithmetic()** - Test +, -, *, / operations
- **testScientificFunctions()** - Test SIN, COS, LOG, etc.
- **testStatisticalFunctions()** - Test mean, std dev, etc.
- **testFileOperations()** - Test save/load functionality
- **testErrorHandling()** - Test error conditions
- **testMemoryOperations()** - Test memory functions

### 9.2 Integration Testing
- Complete calculation workflows
- Mode switching functionality
- File import/export processes
- Session persistence
- Error recovery procedures

### 9.3 User Acceptance Testing
- Calculation accuracy verification
- Interface usability testing
- Performance benchmarking
- Documentation validation

---

## 10. Implementation Phases

### Phase 1: Core Calculator
- Basic arithmetic operations
- Simple display interface
- Basic error handling
- Memory operations

### Phase 2: Scientific Functions
- Mathematical function library
- Angle mode switching
- Advanced display formatting
- Expression parsing

### Phase 3: Data Management
- History logging
- Session persistence
- Configuration management
- File operations

### Phase 4: Statistical Analysis
- Data input/editing
- Statistical calculations
- Data visualization
- Import/export functionality

### Phase 5: Advanced Features
- Programming calculator mode
- Customization system
- Help system
- Performance optimization

---

## 11. File Structure

```
CALCULATOR/
├── MAIN           (* Main program procedure *)
├── CONFIG         (* Configuration management *)
├── DISPLAY        (* User interface procedures *)
├── MATHLIB        (* Mathematical functions *)
├── PARSER         (* Expression parsing *)
├── HISTORY        (* History management *)
├── STATISTICS     (* Statistical functions *)
├── FILEIO         (* File operations *)
├── ERRORS         (* Error handling *)
└── UTILS          (* Utility procedures *)

Data Files:
├── CALC.CFG       (* Configuration file *)
├── SESSION.DAT    (* Current session data *)
├── HISTORY.TXT    (* Exported history *)
└── BACKUP.DAT     (* Automatic backup *)
```

## 12. Implementation Timeline and Module Dependencies

### Phase 1: Foundation (Weeks 1-2)
**Core Infrastructure - Everything else depends on this**

#### Week 1: Basic Data Structures and Utilities
```
Priority 1A: Core Data Types
├── calcResult TYPE definition
├── calcState TYPE definition  
├── Basic error constants (errNone, errDivideZero, etc.)
└── Global variable declarations

Priority 1B: Utility Procedures
├── initCalculator() - Initialize all variables
├── formatNumber() - Basic number formatting
├── isValidNumber() - Input validation
└── Basic string utilities
```

#### Week 2: Display Foundation
```
Priority 1C: Basic Display System
├── displayMainScreen() - Simple calculator display
├── showMenu() - Basic menu system
├── getUserInput() - Basic input handling
└── Simple error display functions

Priority 1D: Testing Infrastructure
├── testBasicArithmetic() - Unit test framework
├── Test harness setup
└── Basic debugging procedures
```

### Phase 2: Core Calculator (Weeks 3-4)
**Basic arithmetic engine - Required for all calculator modes**

#### Week 3: Basic Arithmetic Engine  
```
Priority 2A: Expression Parsing (Simplified)
├── parseNumber() - Convert strings to numbers
├── parseBasicExpression() - Handle +, -, *, /
├── handleParentheses() - Basic grouping
└── evaluateBasic() - Simple calculator logic

Priority 2B: Memory Operations
├── memoryStore() - Store to memory
├── memoryRecall() - Recall from memory
├── memoryClear() - Clear memory
└── memoryBanks basic functionality
```

#### Week 4: Error Handling and Validation
```
Priority 2C: Error Management System
├── handleMathError() - Math error processing
├── ON ERROR GOTO implementation
├── Error recovery procedures
└── Input validation enhancement

Priority 2D: Basic Mode Complete
├── Integration testing
├── Basic calculator fully functional
├── Memory operations working
└── Error handling validated
```

### Phase 3: Scientific Functions (Weeks 5-6)
**Mathematical library - Independent of other advanced features**

#### Week 5: Mathematical Functions
```
Priority 3A: Trigonometric Functions
├── evaluateScientific() - Scientific function handler
├── Angle mode switching (DEG/RAD)
├── SIN, COS, TAN implementations
└── Inverse trig functions (ASN, ACS, ATN)

Priority 3B: Logarithmic and Exponential
├── LOG, LOG10 functions
├── EXP function
├── Power functions (^, **)
└── Square root and nth root
```

#### Week 6: Advanced Mathematical Functions
```
Priority 3C: Additional Functions
├── Hyperbolic functions (using EXP)
├── Factorial and combination functions
├── Constants (PI, E) management
└── Complex expression parsing enhancement

Priority 3D: Scientific Mode Integration
├── Mode switching infrastructure
├── Scientific display formatting
├── Function key assignments
└── Scientific mode testing
```

### Phase 4: File Operations (Weeks 7-8)
**Data persistence - Can be developed in parallel with Phase 5**

#### Week 7: Configuration Management
```
Priority 4A: Configuration System
├── configData TYPE implementation
├── loadConfig() - Read configuration file
├── saveConfig() - Write configuration file
└── Default configuration setup

Priority 4B: Basic File Operations
├── File path management
├── OPEN, CREATE, CLOSE operations
├── Error handling for file operations
└── Directory management utilities
```

#### Week 8: Session Management
```
Priority 4C: Session Persistence
├── historyEntry TYPE implementation
├── saveSession() - Binary session data
├── restoreSession() - Reload session
└── Automatic backup functionality

Priority 4D: Data Import/Export
├── exportHistory() - Export to CSV
├── importData() - Import data files
├── File format validation
└── Data conversion utilities
```

### Phase 5: History and Data Management (Weeks 7-8)
**Can be developed in parallel with Phase 4**

#### Week 7: History System
```
Priority 5A: History Infrastructure
├── historyEntry array management
├── addToHistory() - Add calculations
├── displayHistory() - Show history
└── History navigation system

Priority 5B: History Operations
├── searchHistory() - Search functionality
├── clearHistory() - Clear operations
├── History filtering and sorting
└── History size management
```

#### Week 8: Advanced History Features
```
Priority 5C: History Enhancement
├── History recall to current calculation
├── History editing capabilities
├── Calculation replay functionality
└── History statistics and analysis
```

### Phase 6: Statistical Analysis (Weeks 9-10)
**Requires Phases 1-3 complete, can use Phase 4-5 features**

#### Week 9: Statistical Data Management
```
Priority 6A: Data Structures
├── statData array implementation
├── Data entry and editing system
├── Data validation and cleaning
└── Data visualization (ASCII graphs)

Priority 6B: Descriptive Statistics
├── Mean, median, mode calculations
├── Standard deviation and variance
├── Range and quartile calculations
└── Data summary displays
```

#### Week 10: Advanced Statistics
```
Priority 6C: Analytical Functions
├── Linear regression analysis
├── Correlation calculations
├── Probability distributions
└── Statistical testing functions

Priority 6D: Statistical Mode Integration
├── Statistical mode interface
├── Data import/export for statistics
├── Statistical report generation
└── Statistical function testing
```

### Phase 7: Programming Mode (Weeks 11-12)
**Independent feature - can be developed after core functionality**

#### Week 11: Number Base Systems
```
Priority 7A: Base Conversion
├── Binary, octal, decimal, hex conversions
├── Base conversion display formatting
├── Input parsing for different bases
└── Base arithmetic operations

Priority 7B: Bitwise Operations
├── LAND, LOR, LXOR, LNOT implementations
├── Bit shifting operations
├── Two's complement arithmetic
└── Bitwise operation display
```

#### Week 12: Programming Features
```
Priority 7C: Programming Functions
├── evaluateProgramming() implementation
├── Memory address calculations
├── Bit manipulation utilities
└── Programming mode interface

Priority 7D: Programming Mode Integration
├── Programming mode complete
├── Integration with main calculator
├── Programming function testing
└── Mode switching validation
```

### Phase 8: Polish and Optimization (Weeks 13-14)

#### Week 13: User Interface Enhancement
```
Priority 8A: Interface Polish
├── Improved formatting and layout
├── Enhanced help system (displayHelp)
├── Keyboard shortcuts and function keys
└── User experience improvements

Priority 8B: Performance Optimization
├── Expression parsing optimization
├── Memory usage optimization
├── File I/O performance tuning
└── Mathematical function optimization
```

#### Week 14: Final Integration and Testing
```
Priority 8C: Integration Testing
├── All modes working together
├── Cross-feature testing
├── Performance benchmarking
└── Stress testing

Priority 8D: Documentation and Deployment
├── User documentation
├── Technical documentation
├── Installation procedures
└── Final validation testing
```

### Critical Dependencies

**Blocking Dependencies (Must be completed in order):**
1. Phase 1 → All other phases (Foundation required)
2. Phase 2 → Phases 3, 6 (Arithmetic engine required)
3. Phase 3 → Phase 6 (Scientific functions needed for statistics)

**Parallel Development Opportunities:**
- Phases 4 and 5 can be developed simultaneously
- Phase 7 can be developed independently after Phase 2
- Testing can be developed alongside each phase

**Risk Mitigation:**
- Phases 1-3 are critical path - allocate best resources
- Phase 4-5 have file system dependencies - plan for OS-9 testing
- Phase 6 has complex mathematics - allow extra time for validation
- Phase 7 is independent - good candidate for parallel development

This timeline ensures that core functionality is available early, dependencies are properly managed, and the most complex features are tackled when the foundation is solid.