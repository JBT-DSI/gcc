/* do not edit automatically generated by mc from mcStream.  */
/* mcStream.def provides an interface to create a file from fragments.

Copyright (C) 2015-2022 Free Software Foundation, Inc.
Contributed by Gaius Mulley <gaius@glam.ac.uk>.

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


#if !defined (_mcStream_H)
#   define _mcStream_H

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

#   include "GFIO.h"

#   if defined (_mcStream_C)
#      define EXTERN
#   else
#      define EXTERN extern
#   endif


/*
   openFrag - create and open fragment, id, and return the file.
              The file should not be closed by the user.
*/

EXTERN FIO_File mcStream_openFrag (unsigned int id);

/*
   setDest - informs the stream module and all fragments must be copied
             info, f.
*/

EXTERN void mcStream_setDest (FIO_File f);

/*
   combine - closes all fragments and then writes them in
             order to the destination file.  The dest file
             is returned.
*/

EXTERN FIO_File mcStream_combine (void);

/*
   removeFiles - remove any fragment.
*/

EXTERN void mcStream_removeFiles (void);
#   ifdef __cplusplus
}
#   endif

#   undef EXTERN
#endif
