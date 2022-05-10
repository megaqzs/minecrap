ifdef USE_FLOAT
include "lib/math/fltmath.asm"
endif

ifdef USE_FIXED
include "math/fxdmath.asm"
endif

ifdef USE_INT
include "math/intmath.asm"
endif
