# --enable-comedi-device=yes/no
AC_ARG_ENABLE([comedi-device],
              [AS_HELP_STRING([--enable-comedi-device=@<:@yes/no@:>@],
                              [Build a device that uses the comedi driver.])],
              [enable_comedi_device=$enableval],
              [enable_comedi_device=yes])

# for if ENABLE_COMEDI_DEVICE in Makefile.am
AM_CONDITIONAL(ENABLE_COMEDI_DEVICE, test x$enable_comedi_device != xno)

# Ensure our makefile is generated by autoconf
AC_CONFIG_FILES([src/devices/comedi/Makefile])
