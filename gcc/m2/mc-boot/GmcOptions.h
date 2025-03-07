/* do not edit automatically generated by mc from mcOptions.  */
/* mcOptions.def handles the options for mc.

Copyright (C) 2015-2022 Free Software Foundation, Inc.
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
<http://www.gnu.org/licenses/>.  */


#if !defined (_mcOptions_H)
#   define _mcOptions_H

#include "config.h"
#include "system.h"
#   ifdef __cplusplus
extern "C" {
#   endif
#   if !defined (PROC_D)
#      define PROC_D
       typedef void (*PROC_t) (void);
       typedef struct { PROC_t proc; } PROC;
#   endif

#   include "GDynamicStrings.h"
#   include "GFIO.h"

#   if defined (_mcOptions_C)
#      define EXTERN
#   else
#      define EXTERN extern
#   endif


/*
   handleOptions - iterates over all options setting appropriate
                   values and returns the single source file
                   if found at the end of the arguments.
*/

EXTERN DynamicStrings_String mcOptions_handleOptions (void);

/*
   getQuiet - return the value of quiet.
*/

EXTERN unsigned int mcOptions_getQuiet (void);

/*
   getVerbose - return the value of verbose.
*/

EXTERN unsigned int mcOptions_getVerbose (void);

/*
   getInternalDebugging - return the value of internalDebugging.
*/

EXTERN unsigned int mcOptions_getInternalDebugging (void);
EXTERN DynamicStrings_String mcOptions_getCppCommandLine (void);

/*
   getOutputFile - sets the output filename to output.
*/

EXTERN DynamicStrings_String mcOptions_getOutputFile (void);

/*
   getExtendedOpaque - return the extendedOpaque value.
*/

EXTERN unsigned int mcOptions_getExtendedOpaque (void);

/*
   setDebugTopological - sets the flag debugTopological to value.
*/

EXTERN void mcOptions_setDebugTopological (unsigned int value);

/*
   getDebugTopological - returns the flag value of the command
                         line option --debug-top.
*/

EXTERN unsigned int mcOptions_getDebugTopological (void);

/*
   getHPrefix - saves the H file prefix.
*/

EXTERN DynamicStrings_String mcOptions_getHPrefix (void);

/*
   getIgnoreFQ - returns the ignorefq flag.
*/

EXTERN unsigned int mcOptions_getIgnoreFQ (void);

/*
   getGccConfigSystem - return the value of the gccConfigSystem flag.
*/

EXTERN unsigned int mcOptions_getGccConfigSystem (void);

/*
   getScaffoldDynamic - return true if the --scaffold-dynamic option was present.
*/

EXTERN unsigned int mcOptions_getScaffoldDynamic (void);

/*
   getScaffoldMain - return true if the --scaffold-main option was present.
*/

EXTERN unsigned int mcOptions_getScaffoldMain (void);

/*
   writeGPLheader - writes out the GPL or the GLPL as a comment.
*/

EXTERN void mcOptions_writeGPLheader (FIO_File f);
#   ifdef __cplusplus
}
#   endif

#   undef EXTERN
#endif
