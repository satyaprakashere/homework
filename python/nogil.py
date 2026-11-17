#!/usr/bin/env python3

import sys

#is_freethreaded = bool(sysconfig.get_config_var("Py_GIL_DISABLED"))

print(sys._is_gil_enabled())