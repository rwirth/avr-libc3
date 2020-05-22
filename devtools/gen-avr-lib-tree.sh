#! /bin/sh
#
# Copyright (c) 2004,  Theodore A. Roth
# Copyright (c) 2005,2006,2007,2008,2009  Anatoly Sokolov
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in
#   the documentation and/or other materials provided with the
#   distribution.
# * Neither the name of the copyright holders nor the names of
#   contributors may be used to endorse or promote products derived
#   from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# $Id$
#

# This is a script to automate the generation of the avr/lib/ tree. Since
# there is a build directory for each device and each of those directories is
# virtually the same, it is easier to maintain a single file instead of an
# ever growing number of small Makefile.am fragments.

# Make sure that we are the top-level of the source tree. We will look for the
# the AUTHORS file in the current dir and the parent. After that, we complain
# and fatal error out.

# Define the special flags for special sub-targets.

PATH=/usr/xpg4/bin:$PATH

CFLAGS_SPACE="-mcall-prologues -Os"
CFLAGS_TINY_STACK="-msp8 -mcall-prologues -Os"
CFLAGS_SHORT_CALLS="-mshort-calls -mcall-prologues -Os"
CFLAGS_BIG_MEMORY='-Os $(FNO_JUMP_TABLES)'
CFLAGS_SPEED="-Os"

ASFLAGS_SPEED="-DOPTIMIZE_SPEED"

: ${AVR_GCC:=avr-gcc}

avr_spec_dir=$("$AVR_GCC" -v 2>&1 | sed -ne '/^Reading specs from / s/^Reading specs from //p')
avr_spec_dir=${avr_spec_dir%/*}

: ${AVR_SPEC_DIR:="$avr_spec_dir"}

dev_infos=''
nl="
"

echo "Retrieving devices supported by ${AVR_GCC}..."
echo "   Spec directory: $AVR_SPEC_DIR"

for specfile in "$AVR_SPEC_DIR/"*; do
    device=${specfile##*specs-}

    tiny_stack=$(grep -- -msp8 "$specfile")
    short_calls=$(grep -- -mshort-calls "$specfile")
    smallmem=$(grep -- -mn-flash=1 "$specfile")
    subarch=$(sed -ne '/^\*asm_arch:/,/^$/ s/^[^-]*-mmcu=\([a-zA-Z0-9]\+\).*$/\1/ p' "$specfile")
    crtfile=$(sed -ne '/^\*avrlibc_startfile:/,/^$/ s/^\s*\([a-zA-Z0-9]\+.o\).*$/\1/ p' "$specfile")

    [ "x$device" = "x$subarch" ] && continue

    [ -z "$subarch" -o -z "$crtfile" ] && echo >&2 "WARNING: could not parse specfile for $device"

    dev_info_var=$(echo "$subarch" | tr '[:lower:]' '[:upper:]')
    [ -n "$tiny_stack" ] && dev_info_var="${dev_info_var}TS"
    [ -n "$short_calls" ] && dev_info_var="${dev_info_var}SC"
    dev_info_var="${dev_info_var}_DEV_INFO"

    dev_infos="${dev_infos}${nl}${dev_info_var}"

    if [ -n "$smallmem" ]; then
        if [ -n "$tiny_stack" ]; then
            cflags='${CFLAGS_TINY_STACK}'
            multilib='tiny-stack'
        elif [ -n "$short_calls" ]; then
            cflags='${CFLAGS_SHORT_CALLS}'
            multilib='short-calls'
        else
            cflags='${CFLAGS_SPACE}'
            multilib=''
        fi
    else
        cflags='${CFLAGS_BIG_MEMORY}'
        multilib=''
    fi

    arh_line="${subarch}:${multilib}:${dev_info_var}:\${DEV_DEFS}:${cflags}:\${DEV_ASFLAGS};$nl"
    dev_line="${device}:${crtfile}:\${DEV_DEFS}:${cflags}:\${DEV_ASFLAGS};"

    eval "$dev_info_var=\${$dev_info_var}'${dev_line}'"

    if [ -z "$smallmem" ]; then
        AVR_ARH_INFO="${arh_line}${AVR_ARH_INFO}"
    else
        AVR_ARH_INFO="${AVR_ARH_INFO}${arh_line}"
    fi
done

clean_dev_infos=$(LC_ALL=C sort -u <<-END
$dev_infos
END
)

AVR_ARH_INFO=$(LC_ALL=C sort -su -t: -k1,3 <<END | tr -d '\n'
$AVR_ARH_INFO
END
)
AVR_ARH_INFO="${AVR_ARH_INFO%;*}"

for dev_info_var in $clean_dev_infos; do
    eval contents=\$$dev_info_var
    contents="${contents%;}"
    eval $dev_info_var=\$contents
done


LIB_DEFS="-D__COMPILING_AVR_LIBC__"

echo "Generating source directories:"

top_dir="UNKNOWN"

if test -f AUTHORS
then
	top_dir="$PWD"
else
	cd ..
	if test -f AUTHORS
	then
		top_dir="$PWD"
	fi
fi

if test $top_dir = "UNKNOWN"
then
	echo "Can't determine the top level source dir. Aborting."
	exit 1
fi

test -d avr || mkdir avr
test -d avr/lib || mkdir avr/lib

cd avr/lib || exit 1

IFS=';'
ARH_SUBDIRS=""

ARH_CONDITIONALS=""
ARH_FILES=""

for ath_lib in $AVR_ARH_INFO
do
	arh=`echo $ath_lib | cut -d ':' -f 1`
	sublib=`echo $ath_lib | cut -d ':' -f 2`
	dev_info=`echo $ath_lib | cut -d ':' -f 3`
	lib_defs=`echo $ath_lib | cut -d ':' -f 4`
	lib_cflags=`echo $ath_lib | cut -d ':' -f 5`
	lib_asflags=`echo $ath_lib | cut -d ':' -f 6`

	install_dir=$arh
	if [ $arh = avr2 -o $arh = avr1 ]
	then
		if [ -z "$sublib" ] ; then
			install_dir=""
		else
			install_dir=$sublib
		fi
	else
		if [ -z "$sublib" ] ; then
			install_dir=$arh
		else
			install_dir=$arh'/'$sublib
		fi
	fi

	# Install directory for sed substitution, the '/' character is masked.
	inst_dir_masked=`echo $install_dir | sed 's/\\//\\\\\\//'`

    # In build tree.
    subdir=${arh}${sublib:+/}${sublib}
    echo "  avr/lib/$subdir/"

    # The first record of each arch must be sublib-free.
    test -d $subdir || mkdir $subdir
    cd $subdir || exit 1

    ARH_FILES="${ARH_FILES}avr/lib/$subdir/Makefile$nl"

    case "$arh" in
    avr[1-5])
        ARH_CONDITIONALS="\
${ARH_CONDITIONALS}
# ${arh}
AM_CONDITIONAL(HAS_${arh}, true)$nl"
        ;;
    *)
        ARH_CONDITIONALS="\
${ARH_CONDITIONALS}
# ${arh}
CHECK_AVR_DEVICE(${arh})
AM_CONDITIONAL(HAS_${arh}, test \"x\$HAS_${arh}\" = \"xyes\")$nl$nl"
        ;;
    esac

    DEV_SUBDIRS=""

	eval DEV_INFO=\"\$\{$dev_info\}\"

	for dev_crt in $DEV_INFO
	do
		dev=`echo $dev_crt | cut -d ':' -f 1`
		crt=`echo $dev_crt | cut -d ':' -f 2`
		crt_defs=`echo $dev_crt | cut -d ':' -f 3`
		crt_cflags=`echo $dev_crt | cut -d ':' -f 4`
		crt_asflags=`echo $dev_crt | cut -d ':' -f 5`

		echo "  avr/lib/$subdir/$dev"

		test -d $dev || mkdir $dev

		cat $top_dir/devtools/Device.am > $dev/Makefile.am

		sed -e "s/<<dev>>/$dev/g" \
		    -e "s/<<crt>>/$crt/g" \
		    -e "s/<<crt_defs>>/$crt_defs/g" \
		    -e "s/<<crt_cflags>>/$crt_cflags/g" \
		    -e "s/<<crt_asflags>>/$crt_asflags/g"  \
		    -e "s/<<install_dir>>/$inst_dir_masked/g" $dev/Makefile.am \
		    > $dev/tempfile

		case "$dev" in
		  at90s1200|attiny11|attiny12|attiny15|attiny28)
			sed -e "s/\$(eeprom_c_sources)//g" \
				-e "s/\$(dev_c_sources)//g" $dev/tempfile \
			> $dev/tempfile_2 && mv -f $dev/tempfile_2 $dev/Makefile.am
			;;
		  *)
			mv -f $dev/tempfile $dev/Makefile.am
			;;
		esac

		case "$dev" in
		at90s1200|attiny1[125]|attiny28|\
		at90s23[1-4]3|at90s4414|at90s443[34]|at90s8515|at90s853[45]|attiny2[26]|\
		at43usb320|at43usb355|at76c711|\
		atmega103|\
		atmega8|atmega8515|atmega8535|\
		atmega128)
			ARH_CONDITIONALS="\
${ARH_CONDITIONALS}\
AM_CONDITIONAL(HAS_${dev}, true)$nl"
			;;
		*)
			ARH_CONDITIONALS="\
${ARH_CONDITIONALS}\
CHECK_AVR_DEVICE(${dev})
AM_CONDITIONAL(HAS_${dev}, test \"x\$HAS_${dev}\" = \"xyes\")$nl$nl"
			;;
		esac

		ARH_FILES="${ARH_FILES}avr/lib/$subdir/$dev/Makefile$nl"
		DEV_SUBDIRS="$DEV_SUBDIRS $dev"
	done

	cat $top_dir/devtools/Architecture.am > Makefile.am

	sed -e "s/<<dev_subdirs>>/$DEV_SUBDIRS/g" \
	    -e "s/<<arh>>/$arh/g" \
	    -e "s/<<lib_defs>>/$lib_defs/g" \
	    -e "s/<<lib_cflags>>/$lib_cflags/g" \
	    -e "s/<<lib_asflags>>/$lib_asflags/g" \
	    -e "s/<<install_dir>>/$inst_dir_masked/g" Makefile.am \
	    > tempfile && mv -f tempfile Makefile.am

	if [ $arh = avr1 ]; then
		sed -e '/^if HAS_avr1/,/^endif # avr1/ d' Makefile.am \
		    > tempfile && mv -f tempfile Makefile.am
	else
		# Find the first and the last lines of <<dev>> block.
		n1=`grep -En '^if[[:blank:]]+HAS_<<dev>>' Makefile.am	\
		    | cut -d ':' -f 1`
		n2=`grep -En '^endif[[:blank:]]+#[[:blank:]]*<<dev>>' Makefile.am \
		    | cut -d ':' -f 1`

		# Before the <<dev>> block.
		head -n `expr $n1 - 1` Makefile.am > tempfile

		# Duplicate the <<dev>> block and substitute.
		for dev_crt in $DEV_INFO ; do
			dev=`echo $dev_crt | cut -d ':' -f 1`
			tail -n +$n1 Makefile.am	\
			    | head -n `expr $n2 - $n1 + 1`	\
			    | sed -e "s/<<dev>>/$dev/g" >> tempfile
		done

		# After the <<dev>> block.
		tail -n +`expr $n2 + 1` Makefile.am >> tempfile

		# Result.
		mv -f tempfile Makefile.am
	fi

	ARH_SUBDIRS="$ARH_SUBDIRS $subdir"

	cd .. || exit 1
	if [ -n "$sublib" ] ; then
		cd .. || exit 1
	fi
done

cat $top_dir/devtools/Lib.am > Makefile.am

sed -e "s/<<arh_subdirs>>/`echo $ARH_SUBDIRS | sed 's/\\//\\\\\\//g'`/g" \
    Makefile.am > tempfile && mv -f tempfile Makefile.am

cd ..

cat > $top_dir/Devices.m4 <<END
${ARH_CONDITIONALS}

AC_CONFIG_FILES([
${ARH_FILES}])
END

cat $top_dir/devtools/Avr.am > Makefile.am
