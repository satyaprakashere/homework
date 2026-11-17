import sys, sysconfig

# 1. Verify Free-Threaded (GIL Disabled) Status
# Returns False if the GIL is disabled, True if active
print("GIL Enabled:", sys._is_gil_enabled())

# 2. Check interpreter details / build flags
print(sys.version)
print(sysconfig.get_config_var('CONFIG_ARGS'))