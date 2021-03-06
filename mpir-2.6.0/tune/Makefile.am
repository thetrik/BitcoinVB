## Process this file with automake to generate Makefile.in
 
# Copyright 2000, 2001, 2002, 2003, 2005 Free Software Foundation, Inc.
#
# This file is part of the GNU MP Library.
#
# The GNU MP Library is free software; you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation; either version 2.1 of the License, or (at your
# option) any later version.
#
# The GNU MP Library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
# License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with the GNU MP Library; see the file COPYING.LIB.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA.


INCLUDES = -I$(top_srcdir) -I$(top_srcdir)/tests

EXTRA_DIST = alpha.asm pentium.asm sparcv9.asm hppa.asm hppa2.asm hppa2w.asm \
  ia64.asm powerpc.asm powerpc64.asm x86_64.as many.pl
noinst_HEADERS = speed.h

# Prefer -static on the speed and tune programs, since that can avoid
# overheads of shared library linkages on some systems.  Libtool tends to
# botch -static if configured with --disable-static, perhaps reasonably
# enough.  In any event under --disable-static the only choice is a dynamic
# link so there's no point in -static.
#
if ENABLE_STATIC
STATIC = -static
else
STATIC =
endif


EXTRA_LTLIBRARIES = libspeed.la

libspeed_la_SOURCES =							\
  common.c divrem1div.c divrem1inv.c divrem2div.c divrem2inv.c		\
  freq.c gcd_bin.c 				\
  gcdextod.c gcdextos.c			\
  jacbase1.c jacbase2.c jacbase3.c					\
  mod_1_div.c mod_1_inv.c modlinv.c					\
  noop.c powm_mod.c powm_redc.c preinv_divrem_1.c				\
  fac_ui_large.c fac_ui_small.c						\
  set_strb.c set_strs.c set_strp.c time.c

libspeed_la_DEPENDENCIES = $(SPEED_CYCLECOUNTER_OBJ) \
  $(top_builddir)/tests/libtests.la $(top_builddir)/libmpir.la
libspeed_la_LIBADD = $(libspeed_la_DEPENDENCIES) $(LIBM)
libspeed_la_LDFLAGS = $(STATIC)

$(top_builddir)/tests/libtests.la:
	cd $(top_builddir)/tests; $(MAKE) $(AM_MAKEFLAGS) libtests.la


# The library code is faster static than shared on some systems, so do
# tuning and measuring with static, since users who care about maximizing
# speed will be using that.  speed-dynamic exists to show the difference.
#
# On Solaris 8, gcc 2.95.2 -static is somehow broken (it creates executables
# that immediately seg fault), so -all-static is not used.  The only thing
# -all-static does is make libc static linked as well as libmpir, and that
# makes a difference only when measuring malloc and friends in the speed
# program.  This can always be forced with "make speed_LDFLAGS=-all-static
# ..." if desired, see tune/README.

EXTRA_PROGRAMS = speed speed-dynamic speed-ext tuneup

DEPENDENCIES = libspeed.la
LDADD = $(DEPENDENCIES)

speed_SOURCES = speed.c
speed_LDFLAGS = $(STATIC)

speed_dynamic_SOURCES = speed.c

speed_ext_SOURCES = speed-ext.c
speed_ext_LDFLAGS = $(STATIC)

tuneup_SOURCES = tuneup.c
nodist_tuneup_SOURCES = sqr_basecase.c $(TUNE_MPN_SRCS)
tuneup_DEPENDENCIES = $(TUNE_SQR_OBJ) libspeed.la
tuneup_LDADD = $(tuneup_DEPENDENCIES)
tuneup_LDFLAGS = $(STATIC)


tune:
	$(MAKE) $(AM_MAKEFLAGS) tuneup$(EXEEXT)
	./tuneup

allprogs: $(EXTRA_PROGRAMS)

# $(MANY_CLEAN) and $(MANY_DISTCLEAN) are hooks for many.pl
CLEANFILES = $(EXTRA_PROGRAMS) $(EXTRA_LTLIBRARIES) \
	$(TUNE_MPN_SRCS) sqr_asm.asm \
	stg.gnuplot stg.data \
	mtg.gnuplot mtg.data \
	fibg.gnuplot fibg.data \
	graph.gnuplot graph.data \
	$(MANY_CLEAN)
DISTCLEANFILES = sqr_basecase.c  $(MANY_DISTCLEAN)


# Generating these little files at build time seems better than including
# them in the distribution, since the list can be changed more easily.
#
# mpn/generic/tdiv_qr.c uses mpn_divrem_1 and mpn_divrem_2, but only for 1
# and 2 limb divisors, which are never used during tuning, so it doesn't
# matter whether it picks up a tuned or untuned version of those.
#
# divrem_1 and mod_1 are recompiled renamed to "_tune" to avoid a linking
# problem.  If a native divrem_1 provides an mpn_divrem_1c entrypoint then
# common.c will want that, but the generic divrem_1 doesn't provide it,
# likewise for mod_1.  The simplest way around this is to have the tune
# build versions renamed suitably.
#
# FIXME: Would like say mul_n.c to depend on $(top_builddir)/mul_n.c so the
# recompiled object will be rebuilt if that file changes.

TUNE_MPN_SRCS = $(TUNE_MPN_SRCS_BASIC) $(TUNE_FFT_SRCS_BASIC) divrem_1.c mod_1.c
TUNE_MPN_SRCS_BASIC = divrem_2.c gcd.c gcdext.c get_str.c \
  mul_n.c mullow_n.c mulhigh_n.c mul.c tdiv_qr.c \
  toom4_mul_n.c toom4_mul.c toom3_mul.c toom3_mul_n.c \
  toom8h_mul.c toom8_sqr_n.c mulmod_2expm1.c rootrem.c divrem_euclidean_r_1.c \
  divrem_hensel_qr_1.c rsh_divrem_hensel_qr_1.c dc_divappr_q.c dc_div_qr.c dc_div_qr_n.c \
  inv_divappr_q.c inv_div_qr.c tdiv_q.c dc_bdiv_qr.c dc_bdiv_qr_n.c dc_bdiv_q.c 
TUNE_FFT_SRCS_BASIC = split_bits.c revbin.c normmod_2expp1.c mulmod_2expp1.c \
  mul_trunc_sqrt2.c mul_mfa_trunc_sqrt2.c mul_fft_main.c \
  mul_2expmod_2expp1.c ifft_trunc_sqrt2.c ifft_trunc.c ifft_radix2.c \
  ifft_negacyclic.c fft_trunc.c fft_radix2.c fft_negacylic.c \
  fft_mfa_trunc_sqrt2.c fft_mfa_trunc_sqrt2_inner.c fermat_to_mpz.c \
  div_2expmod_2expp1.c combine_bits.c butterfly_rshB.c butterfly_lshB.c \
  adjust_sqrt2.c adjust.c

$(TUNE_MPN_SRCS_BASIC):
	for i in $(TUNE_MPN_SRCS_BASIC); do \
	  echo "#define TUNE_PROGRAM_BUILD 1" >$$i; \
	  echo "#include \"mpn/generic/$$i\"" >>$$i; \
	done

$(TUNE_FFT_SRCS_BASIC):
	for i in $(TUNE_FFT_SRCS_BASIC); do \
	  echo "#define TUNE_PROGRAM_BUILD 1" >$$i; \
	  echo "#include \"fft/$$i\"" >>$$i; \
	done

divrem_1.c:
	echo "#define TUNE_PROGRAM_BUILD 1"                >divrem_1.c
	echo "#define __gmpn_divrem_1  mpn_divrem_1_tune" >>divrem_1.c
	echo "#include \"mpn/generic/divrem_1.c\""        >>divrem_1.c

mod_1.c:
	echo "#define TUNE_PROGRAM_BUILD 1"          >mod_1.c
	echo "#define __gmpn_mod_1  mpn_mod_1_tune" >>mod_1.c
	echo "#include \"mpn/generic/mod_1.c\""     >>mod_1.c

sqr_asm.asm: $(top_builddir)/mpn/sqr_basecase.asm
	echo 'define(SQR_KARATSUBA_THRESHOLD_OVERRIDE,SQR_KARATSUBA_THRESHOLD_MAX)' >sqr_asm.asm
	echo 'include(../mpn/sqr_basecase.asm)' >>sqr_asm.asm


include ../mpn/Makeasm.am
