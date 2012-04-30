AC_INIT(sancus-lua-web, 0.0, amery@geeks.cl)

AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])

AM_INIT_AUTOMAKE([foreign dist-bzip2 -Wall -Werror])

PKG_CHECK_MODULES(CORE, [sancus-lua-core])
AC_MSG_CHECKING([where to install lua modules])
install_lmod=`pkg-config --variable INSTALL_LMOD sancus-lua-core`
if test "x${install_lmod}" = x; then
	AC_MSG_ERROR([no INSTALL_LMOD found])
fi
AC_MSG_RESULT(${install_lmod})
AC_SUBST(INSTALL_LMOD,${install_lmod})

AC_CONFIG_FILES([Makefile
		 doc/Makefile
		 src/lua/Makefile
		 src/Makefile])
AC_OUTPUT
