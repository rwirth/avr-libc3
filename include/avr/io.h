/* Copyright (c) 2002,2003,2005,2006,2007 Marek
  Michalkiewicz, Joerg Wunsch Copyright (c) 2007 Eric B.
  Weddington All rights reserved.

   Redistribution and use in source and binary forms, with
  or without modification, are permitted provided that the
  following conditions are met:

   * Redistributions of source code must retain the above
  copyright notice, this list of conditions and the
  following disclaimer.

   * Redistributions in binary form must reproduce the above
  copyright notice, this list of conditions and the
  following disclaimer in the documentation and/or other
  materials provided with the distribution.

   * Neither the name of the copyright holders nor the names
  of contributors may be used to endorse or promote products
  derived from this software without specific prior written
  permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
  CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE. */

/* $Id$ */

/** \file */
/** \defgroup avr_io <avr/io.h>: AVR device-specific IO
   definitions \code #include <avr/io.h> \endcode

    This header file includes the appropriate IO definitions
   for the device that has been specified by the
   <tt>-mmcu=</tt> compiler command-line switch.  This is
   done by diverting to the appropriate file
   <tt>&lt;avr/io</tt><em>XXXX</em><tt>.h&gt;</tt> which
   should never be included directly.  Some register names
   common to all AVR devices are defined directly within
   <tt>&lt;avr/common.h&gt;</tt>, which is included in
   <tt>&lt;avr/io.h&gt;</tt>, but most of the details come
   from the respective include file.

    Note that this file always includes the following files:
    \code
    #include <avr/common.h>
    #include <avr/portpins.h>
    #include <avr/sfr_defs.h>
    #include <avr/version.h>
    \endcode
    See \ref avr_sfr for more details about that header
   file.

    Included are definitions of the IO register set and
   their respective bit values as specified in the Atmel
   documentation. Note that inconsistencies in naming
   conventions, so even identical functions sometimes get
   different names on different devices.

    Also included are the specific names useable for
   interrupt function definitions as documented \ref
   avr_signames "here".

    Finally, the following macros are defined:

    - \b RAMEND
    <br>
    The last on-chip RAM address.
    <br>
    - \b XRAMEND
    <br>
    The last possible RAM location that is addressable. This
   is equal to RAMEND for devices that do not allow for
   external RAM. For devices that allow external RAM, this
   will be larger than RAMEND. <br>
    - \b E2END
    <br>
    The last EEPROM address.
    <br>
    - \b FLASHEND
    <br>
    The last byte address in the Flash program space.
    <br>
    - \b SPM_PAGESIZE
    <br>
    For devices with bootloader support, the flash pagesize
    (in bytes) to be used for the \c SPM instruction.
    - \b E2PAGESIZE
    <br>
    The size of the EEPROM page.

*/

#ifndef _AVR_IO_H_
#define _AVR_IO_H_

#include <avr/sfr_defs.h>

#if !defined(AVR_LIBC_LEGACY_IO)
/* By default use legacy IO, FOR NOW */
#  define AVR_LIBC_LEGACY_IO (1)
#endif

#if AVR_LIBC_LEGACY_IO
#  include <avr/legacyio.h>
#else

/***** COMMON DEFINITIONS USED BY AUTOGENERATED HEADERS ********/
#  if !defined(__ASSEMBLER__)

#    include <stdint.h>

typedef volatile uint8_t register8_t;
typedef volatile uint16_t register16_t;
typedef volatile uint32_t register32_t;

#    ifdef _REGISTER16
#      undef _REGISTER16
#    endif
#    define _REGISTER16(regname)                                                         \
      __extension__ union {                                                              \
        register16_t regname;                                                            \
        struct {                                                                         \
          register8_t regname##L;                                                        \
          register8_t regname##H;                                                        \
        };                                                                               \
      }

#    ifdef _REGISTER32
#      undef _REGISTER32
#    endif
#    define _REGISTER32(regname)    \
      __extension__ union {         \
        register32_t regname;       \
        struct {                    \
          register16_t regname##L;  \
          register16_t regname##H;  \
        }                           \
        struct {                    \
          register8_t regname##0;   \
          register8_t regname##1;   \
          register8_t regname##2;   \
          register8_t regname##3;   \
          \
        };                                                                              \
      }
#  endif /* NOT __ASSEMBLER__ */

// Generic Port Pins
#  define PIN0_bm 0x01
#  define PIN0_bp 0
#  define PIN1_bm 0x02
#  define PIN1_bp 1
#  define PIN2_bm 0x04
#  define PIN2_bp 2
#  define PIN3_bm 0x08
#  define PIN3_bp 3
#  define PIN4_bm 0x10
#  define PIN4_bp 4
#  define PIN5_bm 0x20
#  define PIN5_bp 5
#  define PIN6_bm 0x40
#  define PIN6_bp 6
#  define PIN7_bm 0x80
#  define PIN7_bp 7

/* Non Legacy IO just uses the __AVR_DEV_LIB_NAME__ to
 * autogenerate the io include name */
#  if defined(__AVR_DEV_LIB_NAME__)
#    define __avr_ioheaderx__(a) a
#    define __avr_ioheader__(a) __avr_ioheaderx__(a)
#    define __AVR_DEVICE_HEADER__ <avr/io/__avr_ioheader__(__AVR_DEV_LIB_NAME__).h>
#    include __AVR_DEVICE_HEADER__
#    if defined (__AVR_EXTRA_IO__)
#      define __AVR_EXTRA_DEVICE_HEADER__ <avr/extraio/__avr_ioheader__(__AVR_DEV_LIB_NAME__).h>
#      include __AVR_EXTRA_DEVICE_HEADER__
#    endif
#  else
#    if !defined(__COMPILING_AVR_LIBC__)
#      error "__AVR_DEV_LIB_NAME__ device type not defined"
#    endif
#  endif

#  if defined(PROGMEM_START) && !defined(FLASHSTART)
#    define FLASHSTART PROGMEM_START
#  endif

#  if defined(PROGMEM_END) && !defined(FLASHEND)
#    define FLASHEND PROGMEM_END
#  endif

#  if defined(INTERNAL_SRAM_START) && !defined(RAMSTART)
#    define RAMSTART INTERNAL_SRAM_START
#  endif

#  if defined(INTERNAL_SRAM_SIZE) && !defined(RAMSIZE)
#    define RAMSIZE INTERNAL_SRAM_SIZE
#  endif

#  if defined(INTERNAL_SRAM_END) && !defined(RAMEND)
#    define RAMEND INTERNAL_SRAM_END
#  endif

#  if defined(EEPROM_END) && !defined(E2END)
#    define E2END EEPROM_END
#  endif

#  if defined(EEPROM_PAGE_SIZE) && !defined(E2PAGESIZE)
#    define E2PAGESIZE EEPROM_PAGE_SIZE
#  endif

#endif /* AVR_LIBC_LEGACY_IO */

/* these files are always included whether using LEGACY_IO or not */
#include <avr/portpins.h>

#include <avr/common.h>

#include <avr/version.h>

#if __AVR_ARCH__ >= 100
#  include <avr/xmega.h>
#endif

/* Include fuse.h after individual IO header files. */
#include <avr/fuse.h>

/* Include lock.h after individual IO header files. */
#include <avr/lock.h>


#endif /* _AVR_IO_H_ */
