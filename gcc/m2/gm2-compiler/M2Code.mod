(* M2Code.mod coordinate the activity of the front end.

Copyright (C) 2001-2022 Free Software Foundation, Inc.
Contributed by Gaius Mulley <gaius.mulley@southwales.ac.uk>.

This file is part of GNU Modula-2.

GNU Modula-2 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option)
any later version.

GNU Modula-2 is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Modula-2; see the file COPYING3.  If not see
<http://www.gnu.org/licenses/>.  *)

IMPLEMENTATION MODULE M2Code ;


FROM SYSTEM IMPORT WORD ;
FROM M2Options IMPORT Statistics, DisplayQuadruples, OptimizeUncalledProcedures,
                      (* OptimizeDynamic, *) OptimizeCommonSubExpressions,
                      StyleChecking, Optimizing, WholeProgram ;

FROM M2Error IMPORT InternalError ;
FROM M2Students IMPORT StudentVariableCheck ;

FROM SymbolTable IMPORT GetMainModule, IsProcedure,
                        IsModuleWithinProcedure,
                        CheckHiddenTypeAreAddress, IsModule, IsDefImp,
			DebugLineNumbers,
                        ForeachProcedureDo,
                        ForeachInnerModuleDo, GetSymName ;

FROM M2Printf IMPORT printf2, printf1, printf0 ;
FROM NameKey IMPORT Name ;
FROM M2Batch IMPORT ForeachSourceModuleDo ;

FROM M2Quads IMPORT CountQuads, GetFirstQuad, DisplayQuadList, DisplayQuadRange,
                    BackPatchSubrangesAndOptParam, VariableAnalysis,
                    LoopAnalysis, ForLoopAnalysis, GetQuad, QuadOperator ;

FROM M2Pass IMPORT SetPassToNoPass, SetPassToCodeGeneration ;

FROM M2BasicBlock IMPORT BasicBlock,
                         InitBasicBlocks, InitBasicBlocksFromRange,
			 KillBasicBlocks, FreeBasicBlocks,
                         ForeachBasicBlockDo ;

FROM M2Optimize IMPORT FoldBranches, RemoveProcedures ;
FROM M2GenGCC IMPORT ConvertQuadsToTree ;

FROM M2GCCDeclare IMPORT FoldConstants, StartDeclareScope,
                         DeclareProcedure, InitDeclarations,
                         DeclareModuleVariables, MarkExported ;

FROM M2Scope IMPORT ScopeBlock, InitScopeBlock, KillScopeBlock, ForeachScopeBlockDo ;
FROM m2top IMPORT StartGlobalContext, EndGlobalContext, SetFlagUnitAtATime ;
FROM M2Error IMPORT FlushErrors, FlushWarnings ;
FROM M2Swig IMPORT GenerateSwigFile ;
FROM m2flex IMPORT GetTotalLines ;
FROM FIO IMPORT FlushBuffer, StdOut ;
FROM M2Quiet IMPORT qprintf0 ;
FROM M2SSA IMPORT DiscoverSSA ;


CONST
   MaxOptimTimes = 10 ;   (* upper limit of no of times we run through all optimization *)
   Debugging     = TRUE ;


VAR
   Total,
   Count,
   OptimTimes,
   DeltaProc,
   Proc,
   DeltaConst,
   Const,
   DeltaJump,
   Jump,
   DeltaBasicB,
   BasicB     : CARDINAL ;


(*
   Percent - calculates the percentage from numerator and divisor
*)

PROCEDURE Percent (numerator, divisor: CARDINAL) ;
VAR
   value: CARDINAL ;
BEGIN
   printf0 ('  (') ;
   IF divisor=0
   THEN
      printf0 ('overflow error')
   ELSE
      value := numerator*100 DIV divisor ;
      printf1 ('%3d', value)
   END ;
   printf0 ('\%)')
END Percent ;


(*
   OptimizationAnalysis - displays some simple front end optimization statistics.
*)

PROCEDURE OptimizationAnalysis ;
VAR
   value: CARDINAL ;
BEGIN
   IF Statistics
   THEN
      Count := CountQuads() ;

      printf1 ('M2 initial number of quadruples: %6d', Total) ;
      Percent (Total, Total) ; printf0 ('\n');
      printf1 ('M2 constant folding achieved   : %6d', Const) ;
      Percent (Const, Total) ; printf0 ('\n');
      printf1 ('M2 branch folding achieved     : %6d', Jump) ;
      Percent (Jump, Total) ; printf0 ('\n');
      value := Const+Jump+Proc ;
      printf1 ('Front end optimization removed : %6d', value) ;
      Percent (value, Total) ; printf0 ('\n') ;
      printf1 ('Front end final                : %6d', Count) ;
      Percent (Count, Total) ; printf0 ('\n') ;
      Count := GetTotalLines () ;
      printf1 ('Total source lines compiled    : %6d\n', Count) ;
      FlushBuffer (StdOut)
   END ;
   IF DisplayQuadruples
   THEN
      printf0 ('after all front end optimization\n') ;
      DisplayQuadList
   END
END OptimizationAnalysis ;


(*
   RemoveUnreachableCode -
*)

PROCEDURE RemoveUnreachableCode ;
BEGIN
   IF WholeProgram
   THEN
      ForeachSourceModuleDo(RemoveProcedures)
   ELSE
      RemoveProcedures(GetMainModule())
   END
END RemoveUnreachableCode ;


(*
   DoModuleDeclare - declare all constants, types, variables, procedures for the
                     main module or all modules.
*)

PROCEDURE DoModuleDeclare ;
BEGIN
   IF WholeProgram
   THEN
      ForeachSourceModuleDo (StartDeclareScope)
   ELSE
      StartDeclareScope (GetMainModule ())
   END
END DoModuleDeclare ;


(*
   PrintModule -
*)

(*
PROCEDURE PrintModule (sym: CARDINAL) ;
VAR
   n: Name ;
BEGIN
   n := GetSymName (sym) ;
   printf1 ('module %a\n', n)
END PrintModule ;
*)


(*
   DoCodeBlock - generate code for the main module or all modules.
*)

PROCEDURE DoCodeBlock ;
BEGIN
   IF WholeProgram
   THEN
      (* ForeachSourceModuleDo(PrintModule) ; *)
      CodeBlock (GetMainModule ())
   ELSE
      CodeBlock (GetMainModule ())
   END
END DoCodeBlock ;


(*
   DetermineSubExpTemporaries -
*)

PROCEDURE DetermineSubExpTemporaries ;
BEGIN
   IF WholeProgram
   THEN
      ForeachSourceModuleDo (DiscoverSSA)
   ELSE
      DiscoverSSA (GetMainModule ())
   END
END DetermineSubExpTemporaries ;


(*
   Code - calls procedures to generates trees from the quadruples.
          All front end quadruple optimization is performed via this call.
*)

PROCEDURE Code ;
BEGIN
   CheckHiddenTypeAreAddress ;
   SetPassToNoPass ;
   BackPatchSubrangesAndOptParam ;
   Total := CountQuads () ;

   ForLoopAnalysis ;   (* must be done before any optimization as the index variable increment quad might change *)

   IF DisplayQuadruples
   THEN
      printf0 ('before any optimization\n') ;
      DisplayQuadList
   END ;

   (* now is a suitable time to check for student errors as *)
   (* we know all the front end symbols must be resolved.   *)

   IF StyleChecking
   THEN
      StudentVariableCheck
   END ;

   SetPassToCodeGeneration ;
   SetFlagUnitAtATime (Optimizing) ;
   StartGlobalContext ;
   InitDeclarations ;     (* default and fixed sized types are all declared from now on.  *)

   RemoveUnreachableCode ;

   IF DisplayQuadruples
   THEN
      printf0 ('after dead procedure elimination\n') ;
      DisplayQuadList
   END ;

   DetermineSubExpTemporaries ;

   IF DisplayQuadruples
   THEN
      printf0 ('after identifying simple subexpression temporaries\n') ;
      DisplayQuadList
   END ;

   qprintf0 ('        symbols to gcc trees\n') ;
   DoModuleDeclare ;

   FlushWarnings ;
   FlushErrors ;
   qprintf0 ('        statements to gcc trees\n') ;
   DoCodeBlock ;

   MarkExported (GetMainModule ()) ;
   GenerateSwigFile (GetMainModule ()) ;
   DebugLineNumbers (GetMainModule ()) ;
   qprintf0 ('        gcc trees given to the gcc backend\n') ;
   EndGlobalContext ;

   OptimizationAnalysis
END Code ;


(*
   InitialDeclareAndCodeBlock - declares all objects within scope,
*)

PROCEDURE InitialDeclareAndOptimize (start, end: CARDINAL) ;
BEGIN
   Count := CountQuads() ;
   FreeBasicBlocks(InitBasicBlocksFromRange(start, end)) ;
   BasicB := Count - CountQuads() ;
   Count := CountQuads() ;

   FoldBranches(start, end) ;
   Jump := Count - CountQuads() ;
   Count := CountQuads()
END InitialDeclareAndOptimize ;


(*
   DeclareAndCodeBlock - declares all objects within scope,
*)

PROCEDURE SecondDeclareAndOptimize (start, end: CARDINAL) ;
BEGIN
   REPEAT
      FoldConstants(start, end) ;
      DeltaConst := Count - CountQuads () ;
      Count := CountQuads () ;

      FreeBasicBlocks(InitBasicBlocksFromRange (start, end)) ;

      DeltaBasicB := Count - CountQuads () ;
      Count := CountQuads () ;

      FreeBasicBlocks (InitBasicBlocksFromRange (start, end)) ;
      FoldBranches(start, end) ;
      DeltaJump := Count - CountQuads () ;
      Count := CountQuads () ;

      FreeBasicBlocks(InitBasicBlocksFromRange (start, end)) ;
      INC (DeltaBasicB, Count - CountQuads ()) ;
      Count := CountQuads () ;

      (* now total the optimization components *)
      INC (Proc, DeltaProc) ;
      INC (Const, DeltaConst) ;
      INC (Jump, DeltaJump) ;
      INC (BasicB, DeltaBasicB)
   UNTIL (OptimTimes>=MaxOptimTimes) OR
         ((DeltaProc=0) AND (DeltaConst=0) AND (DeltaJump=0) AND (DeltaBasicB=0)) ;

   IF (DeltaProc#0) OR (DeltaConst#0) OR (DeltaJump#0) OR (DeltaBasicB#0)
   THEN
      printf0 ('optimization finished although more reduction may be possible (increase MaxOptimTimes)\n')
   END
END SecondDeclareAndOptimize ;


(*
   InitOptimizeVariables -
*)

PROCEDURE InitOptimizeVariables ;
BEGIN
   Count       := CountQuads () ;
   OptimTimes  := 0 ;
   DeltaProc   := 0 ;
   DeltaConst  := 0 ;
   DeltaJump   := 0 ;
   DeltaBasicB := 0
END InitOptimizeVariables ;


(*
   Init -
*)

PROCEDURE Init ;
BEGIN
   Proc   := 0 ;
   Const  := 0 ;
   Jump   := 0 ;
   BasicB := 0
END Init ;


(*
   BasicBlockVariableAnalysis -
*)

PROCEDURE BasicBlockVariableAnalysis (start, end: CARDINAL) ;
VAR
   bb: BasicBlock ;
BEGIN
   bb := InitBasicBlocksFromRange(start, end) ;
   ForeachBasicBlockDo (bb, VariableAnalysis) ;
   KillBasicBlocks (bb)
END BasicBlockVariableAnalysis ;


(*
   DisplayQuadsInScope -
*)

(*
PROCEDURE DisplayQuadsInScope (sb: ScopeBlock) ;
BEGIN
   printf0 ('Quads in scope\n') ;
   ForeachScopeBlockDo (sb, DisplayQuadRange) ;
   printf0 ('===============\n')
END DisplayQuadsInScope ;
*)


(*
   OptimizeScopeBlock -
*)

PROCEDURE OptimizeScopeBlock (sb: ScopeBlock) ;
VAR
   OptimTimes,
   Previous,
   Current   : CARDINAL ;
BEGIN
   InitOptimizeVariables ;
   OptimTimes := 1 ;
   Current := CountQuads () ;
   ForeachScopeBlockDo (sb, InitialDeclareAndOptimize) ;
   ForeachScopeBlockDo (sb, BasicBlockVariableAnalysis) ;
   REPEAT
      ForeachScopeBlockDo (sb, SecondDeclareAndOptimize) ;
      Previous := Current ;
      Current := CountQuads () ;
      INC (OptimTimes)
   UNTIL (OptimTimes=MaxOptimTimes) OR (Current=Previous) ;
   ForeachScopeBlockDo (sb, LoopAnalysis)
END OptimizeScopeBlock ;


(*
   DisplayQuadNumbers - the range, start..end.
*)

(*
PROCEDURE DisplayQuadNumbers (start, end: CARDINAL) ;
BEGIN
   IF DisplayQuadruples
   THEN
      printf2 ('Coding [%d..%d]\n', start, end)
   END
END DisplayQuadNumbers ;
*)


(*
   CodeProceduresWithinBlock - codes the procedures within the module scope.
*)

PROCEDURE CodeProceduresWithinBlock (scope: CARDINAL) ;
BEGIN
   ForeachProcedureDo (scope, CodeBlock)
END CodeProceduresWithinBlock ;


(*
   CodeProcedures -
*)

PROCEDURE CodeProcedures (scope: CARDINAL) ;
BEGIN
   IF IsDefImp (scope) OR IsModule (scope)
   THEN
      ForeachProcedureDo (scope, CodeBlock)
   END
END CodeProcedures ;


(*
   CodeBlock - generates all code for this block and also declares
               all types and procedures for this block. It will
               also optimize quadruples within this scope.
*)

PROCEDURE CodeBlock (scope: WORD) ;
VAR
   sb: ScopeBlock ;
   n : Name ;
BEGIN
   IF DisplayQuadruples
   THEN
      n := GetSymName (scope) ;
      printf1 ('before coding block %a\n', n)
   END ;
   sb := InitScopeBlock (scope) ;
   OptimizeScopeBlock (sb) ;
   IF IsProcedure (scope)
   THEN
      IF DisplayQuadruples
      THEN
         n := GetSymName(scope) ;
         printf1('before coding procedure %a\n', n) ;
         ForeachScopeBlockDo(sb, DisplayQuadRange) ;
         printf0('===============\n')
      END ;
      ForeachScopeBlockDo(sb, ConvertQuadsToTree)
   ELSIF IsModuleWithinProcedure(scope)
   THEN
      IF DisplayQuadruples
      THEN
         n := GetSymName(scope) ;
         printf1('before coding module %a within procedure\n', n) ;
         ForeachScopeBlockDo(sb, DisplayQuadRange) ;
         printf0('===============\n')
      END ;
      ForeachScopeBlockDo(sb, ConvertQuadsToTree) ;
      ForeachProcedureDo(scope, CodeBlock)
   ELSE
      IF DisplayQuadruples
      THEN
         n := GetSymName(scope) ;
         printf1('before coding module %a\n', n) ;
         ForeachScopeBlockDo(sb, DisplayQuadRange) ;
         printf0('===============\n')
      END ;
      ForeachScopeBlockDo(sb, ConvertQuadsToTree) ;
      IF WholeProgram
      THEN
         ForeachSourceModuleDo(CodeProcedures)
      ELSE
         ForeachProcedureDo(scope, CodeBlock)
      END ;
      ForeachInnerModuleDo(scope, CodeProceduresWithinBlock)
   END ;
   KillScopeBlock(sb)
END CodeBlock ;


BEGIN
   Init
END M2Code.
