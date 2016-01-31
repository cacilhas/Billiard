#----------------#
# Edit data here #
#----------------#

PROJECT_NAME= Billiard
ICON= $(PROJECT_NAME).icns


#----------------------#
# Commands and targets #
#----------------------#

TARGET= $(PROJECT_NAME).love
SRC= $(wildcard src/*.moon)
LUACODE= $(SRC:.moon=.lua)
AR= tar cf -
COMPRESS= xz -c
CC= moonc
RM= rm -rf

ifeq ($(OS),Windows_NT)
	ZIP= zip
	UNAME= Windows
	APP= $(PROJECT_NAME).exe
	DIST= $(PROJECT_NAME).zip
	LOVE= C:\love.exe
	CP= COPY
	MV= MOVE

else
	ZIP= zip -9 -q
	UNAME= $(shell uname -s)
	DIST= $(PROJECT_NAME).txz
	CP= cp
	MV= mv

	ifeq ($(UNAME),Darwin)
		LOVE= open -a love
		APP= $(PROJECT_NAME).app

	else
		LOVE= $(shell which love)
		APP= $(PROJECT_NAME)

	endif
endif
#-----------------------------------------------------------------------
all: $(TARGET)


dist: $(DIST)


run: $(TARGET)
	$(LOVE) $<


$(DIST): $(APP)
ifeq ($(UNAME),Windows)
	$(ZIP) $@ $<
else
	$(AR) $< | $(COMPRESS) > $@
endif


$(APP): $(TARGET) $(ICON)
ifeq ($(UNAME),Windows)
	$(CP) /b $(LOVE)+$< $@
else
ifeq ($(UNAME),Darwin)
	$(CP) -r /Applications/love.app $@
	$(RM) $@/Contents/Resources/*
	cat Info.plist > $@/Contents/Info.plist
	$(CP) $? $@/Contents/Resources/
else
	cat $(LOVE) $< > $@
	chmod +x $@
endif
endif


%.lua: %.moon
	$(CC) $<


.PHONY: clean
clean:
	$(RM) $(TARGET) $(APP) $(LUACODE)


.PHONY: mrproper
mrproper: clean
	$(RM) $(DIST)


test: $(LUACODE)
	$(LOVE) src


$(TARGET): $(LUACODE)
ifeq ($(UNAME),Windows)
	CHDIR src ; $(ZIP) ..\$@ -r *
else
	(cd src && $(ZIP) ../$@ -r *)
endif
