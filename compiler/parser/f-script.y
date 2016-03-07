/* f-script grammar */
%lex
%% 

\s+|\n+|\r+|\t+         /* skip whitespace */
\/\*[\w\W]*?\*\/        /* skip comment */
\/\/[\w\W]*?[\n|\n\r]   /* skip comment */
\/\/[\w\W]*?$           /* skip comment */
\\                      /* skip line connector */
\<\%[\w\W]*?\%\>            /* skip template control string*/

/******************************
    keywords of f-script only
 ******************************/
/*package control*/
"use"                   return "USE"
"as"                    return "AS"
"meta"                  return "META"

//type 
"array"                 return "T_ARRAY"
"number"                return "T_NUMBER"
"string"                return "T_STRING"
"object"                return "T_OBJECT"
"boolean"               return "T_BOOLEAN"
"isinstance"            return "ISINSTNACE"

/*decorator*/
"@"                     return "AT"

/*template*/
"template"              return "TEMPLATE"
"#"                     return "POUND"

/****************************************
    keywords of f-script and ecmascript
    Most of them haven't been supported widely by modern browser 
*****************************************/
"import"                return "IMPORT"
"export"                return "EXPORT"
"class"                 return "CLASS"
"extends"                return "EXTENDS"

/***************************
    token of ecmascript 
 ****************************/

/* divider */
";"                     return "SEMI"
","                     return "COMMA"

/* brackets */
"["                     return "LBRACK"
"]"                     return "RBRACK"
"{"                     return "LBRACE"
"}"                     return "RBRACE"
"("                     return "LPAREN"
")"                     return "RPAREN"

/* arithmetical  operator */
"+"                     return "PLUS"
"++"                    return "PLUS2"
"-"                     return "MINUS"
"--"                    return "MINUS2"
"*"                     return "MULTIPLY"
"/"                     return "DIVIDE"
"%"                     return "MOD"

/*logic operator*/
"!"                     return "LOGICNOT"
"&&"                    return "LOGICAND"
"||"                    return "LOGICOR"
"=="                    return "EQ2"
"==="                   return "EQ3"
"!="                    return "NOTEQ"
"!=="                   return "NOTEQ2"
"<"                     return "LT"
">"                     return "GT"
"<="                    return "LTEQ"
">="                    return "GTEQ"

/* bit operator*/
"~"                     return "NOT"
"&"                     return "AND"
"|"                     return "OR"
"^"                     return "XOR"
"<<"                    return "LSHIFT"
">>"                    return "RSHIFT"
">>>"                   return "URSHIFT"

/* assignment operator*/
"="                     return "EQ"
"+="                    return "PLUSEQ"
"-="                    return "MINUSEQ"
"*="                    return "TIMESEQ"
"%="                    return "MODEQ"
"<<="                   return "LSHIFTEQ"
">>="                   return "RSHIFTEQ"
">>>="                  return "URSHIFTEQ"
"&="                    return "ANDEQ"
"|="                    return "OREQ"
"^="                    return "XOREQ"
"/="                    return "DIVIDEEQ"

/* Condition Operator */
"?"                     return "QUESTION"
":"                     return "COLON"

/* Property Operator*/
"."                     return "DOT"

/* keyword */
"break"                 return "BREAK"
"case"                  return "CASE"
"catch"                 return "CATCH"
"for"                   return "FOR"
"continue"              return "CONTINUE"
"default"               return "DEFAULT"
"delete"                return "DELETE"
"do"                    return "DO"
"else"                  return "ELSE"
"finally"               return "FINALLY"
"for"                   return "FOR"
"function"              return "FUNCTION"
"if"                    return "IF"
"in"                    return "IN"
"instanceof"            return "INSTANCEOF"
"new"                   return "NEW"
"return"                return "RETURN"
"switch"                return "SWITCH"
"this"                  return "THIS"
"throw"                 return "THROW"
"try"                   return "TRY"
"typeof"                return "TYPEOF"
"var"                   return "VAR"
"void"                  return "VOID"
"while"                 return "WHILE"
"with"                  return "WITH"

/*values*/
"true"                  return "TRUE"
"false"                 return "FALSE"
"null"                  return "NULL"

[0-9]+                  return 'NUMBER'
\"\"\"[\w\W]*\"\"\"     return 'MULTISTRING'
\"[^\"]*\"              return 'STRING'
\'[^\']*\'              return 'STRING'
[A-Za-z_0-9/$]+          return 'IDENT'

/lex


/*syntax*/
%start Program

%nonassoc IF_WITHOUT_ELSE
%nonassoc ELSE
%%

Literal
    : NULL
    | TRUE
    | FALSE
    | NUMBER
    | STRING
    | DIVIDE
    | DIVIDEEQ
    | MULTISTRING 
    {
        var mod_info = {
                pos:{
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                },
                content: $1.replace(/\n|\r\n/g,'\\n\\\n')
            }
            if(typeof this.modifyLines === 'object' && this.modifyLines.length){
                this.modifyLines.push(mod_info);
            }else{
                this.modifyLines=[mod_info];
            }
    }
    ;

Property
    : IDENT COLON AssignmentExpr
    | STRING COLON AssignmentExpr
    | NUMBER COLON AssignmentExpr
    | IDENT IDENT LPAREN RPAREN LBRACE FunctionBody RBRACE
    | IDENT IDENT LPAREN FormalParameterList RPAREN LBRACE FunctionBody RBRACE
    ;

PropertyList
    : Property
    | PropertyList COMMA Property
    ;

PrimaryExpr
    : PrimaryExprNoBrace
    | LBRACE RBRACE
    | LBRACE PropertyList RBRACE
    | LBRACE PropertyList COMMA RBRACE
    ;

PrimaryExprNoBrace
    : THIS
    | Literal
    | ArrayLiteral
    | IDENT
    | LPAREN Expr RPAREN
    ;

ArrayLiteral
    : LBRACK ElisionOpt RBRACK
    | LBRACK ElementList RBRACK
    | LBRACK ElementList COMMA ElisionOpt RBRACK
    ;

ElementList
    : ElisionOpt AssignmentExpr
    | ElementList COMMA ElisionOpt AssignmentExpr
    ;

ElisionOpt
    : 
    | Elision
    ;

Elision
    : COMMA
    | Elision COMMA
    ;

MemberExpr
    : PrimaryExpr
    | FunctionExpr
    | MemberExpr LBRACK Expr RBRACK
    | MemberExpr DOT IDENT
    | NEW MemberExpr Arguments
    ;

MemberExprNoBF
    : PrimaryExprNoBrace
    | MemberExprNoBF LBRACK Expr RBRACK
    | MemberExprNoBF DOT IDENT
    | NEW MemberExpr Arguments
    ;

NewExpr
    : MemberExpr
    | NEW NewExpr
    ;

NewExprNoBF
    : MemberExprNoBF
    | NEW NewExpr
    ;

CallExpr
    : MemberExpr Arguments
    | CallExpr Arguments
    | CallExpr LBRACK Expr RBRACK
    | CallExpr DOT IDENT
    | TemplateCallExpr
    ;

CallExprNoBF
    : MemberExprNoBF Arguments
    | CallExprNoBF Arguments
    | CallExprNoBF LBRACK Expr RBRACK
    | CallExprNoBF DOT IDENT
    | TemplateCallExpr
    ;

Arguments
    : LPAREN RPAREN
    | LPAREN ArgumentList RPAREN
    ;

ArgumentList
    : AssignmentExpr
    | ArgumentList COMMA AssignmentExpr
    ;

LeftHandSideExpr
    : NewExpr
    | CallExpr
    ;

LeftHandSideExprNoBF
    : NewExprNoBF
    | CallExprNoBF
    ;

PostfixExpr
    : LeftHandSideExpr
    | LeftHandSideExpr PLUSPLUS
    | LeftHandSideExpr MINUSMINUS
    ;

PostfixExprNoBF
    : LeftHandSideExprNoBF
    | LeftHandSideExprNoBF PLUSPLUS
    | LeftHandSideExprNoBF MINUSMINUS
    ;

UnaryExprCommon
    : DELETE UnaryExpr
    | VOID UnaryExpr
    | TYPEOF UnaryExpr
    | PLUSPLUS UnaryExpr
    | AUTOPLUSPLUS UnaryExpr
    | MINUSMINUS UnaryExpr
    | AUTOMINUSMINUS UnaryExpr
    | PLUS UnaryExpr
    | MINUS UnaryExpr
    | NOT UnaryExpr
    | LOGICNOT UnaryExpr
    ;

UnaryExpr
    : PostfixExpr
    | UnaryExprCommon
    ;

UnaryExprNoBF
    : PostfixExprNoBF
    | UnaryExprCommon
    ;

MultiplicativeExpr
    : UnaryExpr
    | MultiplicativeExpr MULTIPLY UnaryExpr
    | MultiplicativeExpr DIVIDE UnaryExpr
    | MultiplicativeExpr MOD UnaryExpr
    ;

MultiplicativeExprNoBF
    : UnaryExprNoBF
    | MultiplicativeExprNoBF MULTIPLY UnaryExpr
    | MultiplicativeExprNoBF DIVIDE UnaryExpr
    | MultiplicativeExprNoBF MOD UnaryExpr
    ;

AdditiveExpr
    : MultiplicativeExpr
    | AdditiveExpr PLUS MultiplicativeExpr
    | AdditiveExpr MINUS MultiplicativeExpr
    ;

AdditiveExprNoBF
    : MultiplicativeExprNoBF
    | AdditiveExprNoBF PLUS MultiplicativeExpr
    | AdditiveExprNoBF MINUS MultiplicativeExpr
    ;

ShiftExpr
    : AdditiveExpr
    | ShiftExpr LSHIFT AdditiveExpr
    | ShiftExpr RSHIFT AdditiveExpr
    | ShiftExpr URSHIFT AdditiveExpr
    ;

ShiftExprNoBF
    : AdditiveExprNoBF
    | ShiftExprNoBF LSHIFT AdditiveExpr
    | ShiftExprNoBF RSHIFT AdditiveExpr
    | ShiftExprNoBF URSHIFT AdditiveExpr
    ;

RelationalExpr
    : ShiftExpr
    | RelationalExpr LT ShiftExpr
    | RelationalExpr GT ShiftExpr
    | RelationalExpr LTEQ ShiftExpr
    | RelationalExpr GTEQ ShiftExpr
    | RelationalExpr INSTANCEOF ShiftExpr
    | RelationalExpr IN ShiftExpr
    ;

RelationalExprNoIn
    : ShiftExpr
    | RelationalExprNoIn LT ShiftExpr
    | RelationalExprNoIn GT ShiftExpr
    | RelationalExprNoIn LTEQ ShiftExpr
    | RelationalExprNoIn GTEQ ShiftExpr
    | RelationalExprNoIn INSTANCEOF ShiftExpr
    ;

RelationalExprNoBF
    : ShiftExprNoBF
    | RelationalExprNoBF LT ShiftExpr
    | RelationalExprNoBF GT ShiftExpr
    | RelationalExprNoBF LTEQ ShiftExpr
    | RelationalExprNoBF GTEQ ShiftExpr
    | RelationalExprNoBF INSTANCEOF ShiftExpr
    | RelationalExprNoBF IN ShiftExpr
    ;

EqualityExpr
    : RelationalExpr
    | EqualityExpr EQ2 RelationalExpr
    | EqualityExpr NOTEQ RelationalExpr
    | EqualityExpr STREQ RelationalExpr
    | EqualityExpr STRNOTEQ RelationalExpr
    ;

EqualityExprNoIn
    : RelationalExprNoIn
    | EqualityExprNoIn EQ2 RelationalExprNoIn
    | EqualityExprNoIn NOTEQ RelationalExprNoIn
    | EqualityExprNoIn EQ3 RelationalExprNoIn
    | EqualityExprNoIn NOTEQ2 RelationalExprNoIn
    ;

EqualityExprNoBF
    : RelationalExprNoBF
    | EqualityExprNoBF EQ2 RelationalExpr
    | EqualityExprNoBF NOTEQ RelationalExpr
    | EqualityExprNoBF EQ3 RelationalExpr
    | EqualityExprNoBF NOTEQ2 RelationalExpr
    ;

BitwiseANDExpr
    : EqualityExpr
    | BitwiseANDExpr AND EqualityExpr
    ;

BitwiseANDExprNoIn
    : EqualityExprNoIn
    | BitwiseANDExprNoIn AND EqualityExprNoIn
    ;

BitwiseANDExprNoBF
    : EqualityExprNoBF
    | BitwiseANDExprNoBF AND EqualityExpr
    ;

BitwiseXORExpr
    : BitwiseANDExpr
    | BitwiseXORExpr XOR BitwiseANDExpr
    ;

BitwiseXORExprNoIn
    : BitwiseANDExprNoIn
    | BitwiseXORExprNoIn XOR BitwiseANDExprNoIn
    ;

BitwiseXORExprNoBF
    : BitwiseANDExprNoBF
    | BitwiseXORExprNoBF XOR BitwiseANDExpr
    ;

BitwiseORExpr
    : BitwiseXORExpr
    | BitwiseORExpr OR BitwiseXORExpr
    ;

BitwiseORExprNoIn
    : BitwiseXORExprNoIn
    | BitwiseORExprNoIn OR BitwiseXORExprNoIn
    ;

BitwiseORExprNoBF
    : BitwiseXORExprNoBF
    | BitwiseORExprNoBF OR BitwiseXORExpr
    ;

LogicalANDExpr
    : BitwiseORExpr
    | LogicalANDExpr LOGICAND BitwiseORExpr
    ;

LogicalANDExprNoIn
    : BitwiseORExprNoIn
    | LogicalANDExprNoIn LOGICAND BitwiseORExprNoIn
    ;

LogicalANDExprNoBF
    : BitwiseORExprNoBF
    | LogicalANDExprNoBF LOGICAND BitwiseORExpr
    ;

LogicalORExpr
    : LogicalANDExpr
    | LogicalORExpr LOGICOR LogicalANDExpr
    ;

LogicalORExprNoIn
    : LogicalANDExprNoIn
    | LogicalORExprNoIn LOGICOR LogicalANDExprNoIn
    ;

LogicalORExprNoBF
    : LogicalANDExprNoBF
    | LogicalORExprNoBF LOGICOR LogicalANDExpr
    ;

ConditionalExpr
    : LogicalORExpr
    | LogicalORExpr QUESTION AssignmentExpr COLON AssignmentExpr
    ;

ConditionalExprNoIn
    : LogicalORExprNoIn
    | LogicalORExprNoIn QUESTION AssignmentExprNoIn COLON AssignmentExprNoIn
    ;

ConditionalExprNoBF
    : LogicalORExprNoBF
    | LogicalORExprNoBF QUESTION AssignmentExpr COLON AssignmentExpr
    ;

AssignmentExpr
    : ConditionalExpr
    | LeftHandSideExpr AssignmentOperator AssignmentExpr
    ;

AssignmentExprNoIn
    : ConditionalExprNoIn
    | LeftHandSideExpr AssignmentOperator AssignmentExprNoIn
    ;

AssignmentExprNoBF
    : ConditionalExprNoBF
    | LeftHandSideExprNoBF AssignmentOperator AssignmentExpr
    ;

AssignmentOperator
    : EQ
    | PLUSEQ
    | MINUSEQ
    | MULTEQ
    | DIVEQ
    | LSHIFTEQ
    | RSHIFTEQ
    | URSHIFTEQ
    | ANDEQ
    | XOREQ
    | OREQ
    | MODEQ
    ;

Expr
    : AssignmentExpr
    | Expr COMMA AssignmentExpr
    ;

ExprNoIn
    : AssignmentExprNoIn
    | ExprNoIn COMMA AssignmentExprNoIn
    ;

ExprNoBF
    : AssignmentExprNoBF
    | ExprNoBF COMMA AssignmentExpr
    ;

Statement
    : Block
    | VariableStatement
    | ConstStatement
    | FunctionDeclaration
    | EmptyStatement
    | ExprStatement
    | IfStatement
    | IterationStatement
    | ContinueStatement
    | BreakStatement
    | ReturnStatement
    | WithStatement
    | SwitchStatement
    | LabelledStatement
    | ThrowStatement
    | TryStatement
    | DebuggerStatement
    | FscriptPackageStatement {$$=""}
    | FscriptStatement {$$=""}
    ;

Block
    : LBRACE RBRACE
    | LBRACE SourceElements RBRACE
    ;

VariableStatement
    : VAR VariableDeclarationList SEMI
    | VAR VariableDeclarationList error
    ;

VariableDeclarationList
    : IDENT
    | IDENT Initializer
    | VariableDeclarationList COMMA IDENT
    | VariableDeclarationList COMMA IDENT Initializer
    ;

VariableDeclarationListNoIn
    : IDENT
    | IDENT InitializerNoIn
    | VariableDeclarationListNoIn COMMA IDENT
    | VariableDeclarationListNoIn COMMA IDENT InitializerNoIn
    ;

ConstStatement
    : CONST ConstDeclarationList SEMI
    | CONST ConstDeclarationList error
    ;

ConstDeclarationList
    : ConstDeclaration
    | ConstDeclarationList COMMA ConstDeclaration
    ;

ConstDeclaration
    : IDENT
    | IDENT Initializer
    ;

Initializer
    : EQ AssignmentExpr
    ;

InitializerNoIn
    : EQ AssignmentExprNoIn
    ;

EmptyStatement
    : SEMI
    ;

ExprStatement
    : ExprNoBF SEMI
    | ExprNoBF error
    ;

IfStatement
    : IF LPAREN Expr RPAREN Statement %prec IF_WITHOUT_ELSE
    | IF LPAREN Expr RPAREN Statement ELSE Statement
    ;

IterationStatement
    : DO Statement WHILE LPAREN Expr RPAREN SEMI
    | DO Statement WHILE LPAREN Expr RPAREN error
    | WHILE LPAREN Expr RPAREN Statement
    | FOR LPAREN ExprNoInOpt SEMI ExprOpt SEMI ExprOpt RPAREN Statement
    | FOR LPAREN VAR VariableDeclarationListNoIn SEMI ExprOpt SEMI ExprOpt RPAREN Statement
    | FOR LPAREN LeftHandSideExpr IN Expr RPAREN Statement
    | FOR LPAREN VAR IDENT IN Expr RPAREN Statement
    | FOR LPAREN VAR IDENT InitializerNoIn IN Expr RPAREN Statement
    ;

ExprOpt
    : 
    | Expr
    ;

ExprNoInOpt
    : 
    | ExprNoIn
    ;

ContinueStatement
    : CONTINUE SEMI
    | CONTINUE error
    | CONTINUE IDENT SEMI
    | CONTINUE IDENT error
    ;

BreakStatement
    : BREAK SEMI
    | BREAK error
    | BREAK IDENT SEMI
    | BREAK IDENT error
    ;

ReturnStatement
    : RETURN SEMI
    | RETURN error
    | RETURN Expr SEMI
    | RETURN Expr error
    ;

WithStatement
    : WITH LPAREN Expr RPAREN Statement
    ;

SwitchStatement
    : SWITCH LPAREN Expr RPAREN CaseBlock
    ;

CaseBlock
    : LBRACE CaseClausesOpt RBRACE
    | LBRACE CaseClausesOpt DefaultClause CaseClausesOpt RBRACE
    ;

CaseClausesOpt
    : 
    | CaseClauses
    ;

CaseClauses
    : CaseClause
    | CaseClauses CaseClause
    ;

CaseClause
    : CASE Expr COLON
    | CASE Expr COLON SourceElements
    ;

DefaultClause
    : DEFAULT COLON
    | DEFAULT COLON SourceElements
    ;

LabelledStatement
    : IDENT COLON Statement
    ;

ThrowStatement
    : THROW Expr SEMI
    | THROW Expr error
    ;

TryStatement
    : TRY Block FINALLY Block
    | TRY Block CATCH LPAREN IDENT RPAREN Block
    | TRY Block CATCH LPAREN IDENT RPAREN Block FINALLY Block
    ;

DebuggerStatement
    : DEBUGGER SEMI
    | DEBUGGER error
    ;

FunctionDeclaration
    : FUNCTION IDENT LPAREN RPAREN LBRACE FunctionBody RBRACE
    | FUNCTION IDENT LPAREN FormalParameterList RPAREN LBRACE FunctionBody RBRACE
    ;

FunctionExpr
    : FUNCTION LPAREN RPAREN LBRACE FunctionBody RBRACE
    | FUNCTION LPAREN FormalParameterList RPAREN LBRACE FunctionBody RBRACE
    | FUNCTION IDENT LPAREN RPAREN LBRACE FunctionBody RBRACE
    | FUNCTION IDENT LPAREN FormalParameterList RPAREN LBRACE FunctionBody RBRACE
    ;

FormalParameterList
    : IDENT
    | FormalParameterList COMMA IDENT
    ;

FunctionBody
    : /* Empty */ {$$={
                        start:[this._$.first_line,this._$.first_column],
                        end:[this._$.last_line,this._$.last_column]
                    }}
    | SourceElements {$$={
                        start:[this._$.first_line,this._$.first_column],
                        end:[this._$.last_line,this._$.last_column]
                    }}
    ;

Program
    : /* Empty */   {return null}
    | SourceElements {return {fs:this}}
    ;

SourceElements
    : Statement
    | SourceElements Statement
    ;

/*
    f-script own syntax,
    insert into statment syntax
 */

FscriptPackageStatement
    : ImportStatement
    | UseStatement
    | ExportStatement
    ;

FscriptStatement
    : ClassDefStatement
    | TemplateDefStatement
    | TemplateCallStatement
    ;

ImportStatement
    : IMPORT ImportList SEMI 
        {
            if(!this.import){
                this.import=[];
            };
            console.log($2);
            this.import=this.import.concat($2);
            var del_info = {
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                }
            if(typeof this.delLines === 'object' && this.delLines.length){
                this.delLines.push(del_info);
            }else{
                this.delLines=[del_info];
            }
        }
    ;
ImportExp
    : STRING {$$={name:$1,refname:null};}
    | STRING AS IDENT {$$={name:$1,refname:$3}}
    ;

ImportList
    : ImportExp
        {$$=[$1]}
    | ImportList COMMA ImportExp
        {$1.push($3);$$ = $1;}
    ;

UseStatement
    : USE STRING SEMI 
        { 
            this.use=$2; 
            var del_info = {
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                }
            if(typeof this.delLines === 'object' && this.delLines.length){
                this.delLines.push(del_info);
            }else{
                this.delLines=[del_info];
            }
        }
    ;

ExportStatement
    : EXPORT ExportList SEMI  
        { 
            if(!this.export){
                this.export=[];
            };
            this.export=this.export.concat($2);
            var del_info = {
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                }
            if(typeof this.delLines === 'object' && this.delLines.length){
                this.delLines.push(del_info);
            }else{
                this.delLines=[del_info];
            }
        }
    ;

ExportList
    : ExportExp
        {$$=[$1]}
    | ExportList COMMA ExportExp
        {$1.push($3);$$ = $1;}
    ;
PackageMember
    : IDENT {$$=[$1]}
    | PackageMember DOT IDENT {$1.push($3);$$=$1}
    ;

ExportExp
    : PackageMember {$$={orignalName:$1.join('.'),exportName:$1[$1.length-1]}}
    | PackageMember AS IDENT {$$={orignalName:$1.join('.'),exportName:$3}} 
    ;

ClassDefStatement
    // python like class def
    : CLASS IDENT LPAREN ExternClass RPAREN MetaClass LBRACE FunctionBody RBRACE
        {
            var meta = {
                'type': 'class',
                'className': $2,
                'classBody':$8,
                'extendsNames': $4,
                'metaClass': $6
            }
            var mod_info = {
                pos:{
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                },
                meta: meta,
                template:"class",
                content: ""
            }
            if(typeof this.modifyLines === 'object' && this.modifyLines.length){
                this.modifyLines.push(mod_info);
            }else{
                this.modifyLines=[mod_info];
            }
        }
    //java like class def
    | CLASS IDENT ExternClass MetaClass LBRACE FunctionBody RBRACE
        {
            var meta = {
                'type': 'class',
                'className': $2,
                'classBody':$6,
                'extendsNames': $3,
                'metaClass': $4
            };
            var mod_info = {
                pos:{
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                },
                meta: meta,
                template:"class",
                content: ""
            };
            if(typeof this.modifyLines === 'object' && this.modifyLines.length){
                this.modifyLines.push(mod_info);
            }else{
                this.modifyLines=[mod_info];
            }
        }
    ;
ExternClass
    : /*empty*/ {$$=null;}
    | EXTENDS ExternClassList {$$=$2}
    | ExternClassList {$$=$1}
    ;
ExternClassList
    : PackageMember {$$ = [$1.join('.')]}
    | ExternClassList COMMA IDENT {$1.push($3.join('.'));$$=$1;}
    ;

MetaClass
    : /*empty*/ {$$=null;}
    | META PackageMember {$$=$2.join('.');}
    ;

TemplateDefStatement
    : TEMPLATE IDENT LPAREN TemplateArguments RPAREN LBRACE FunctionBody RBRACE
        { 
            if(!this.templates){
                this.templates=[];
            };
            this.templates.push({
                name:$2,
                arguments:$4,
                content:$7,
            });
            var del_info = {
                start:[this._$.first_line,this._$.first_column],
                end:[this._$.last_line,this._$.last_column]
            }
            if(typeof this.delLines === 'object' && this.delLines.length){
                this.delLines.push(del_info);
            }else{
                this.delLines=[del_info];
            }
        }
    ;

TemplateArguments
    : 
    | TemplateArgument {$$=[$1]}
    | TemplateArguments COMMA TemplateArgument {$$=$1.push($2)}
    ;

TemplateArgument
    : STRING {$$={argument:$1,type:"string"}}
    | NUMBER {$$={argument:$1,type:"number"}}
    | IDENT  {$$={argument:$1,type:"var"}}
    ;

TemplateCallExpr
    : POUND PackageMember LPAREN ArgumentList RPAREN
        {
            var pos = {
                    start:[this._$.first_line,this._$.first_column],
                    end:[this._$.last_line,this._$.last_column]
                };
            var mod_info = {
                pos:pos,
                meta:{
                    type:"templateCall",
                    callPos:pos
                },
                content: ""
            }
            if(typeof this.modifyLines === 'object' && this.modifyLines.length){
                this.modifyLines.push(mod_info);
            }else{
                this.modifyLines=[mod_info];
            }
        }
    ;