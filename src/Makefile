LOADLIBES := $(MYEXTLIB) $(LDLOADLIBS)
CPPFLAGS := $(CCFLAGS)

EXE_FILES = main$(EXE_EXT)

all: $(EXE_FILES)

main$(EXE_EXT): main.cpp
	$(LINK.cpp) $^ $(LOADLIBES) $(LDLIBS) -o $@

clean:
	- $(RM_F) \
		$(EXE_FILES)
