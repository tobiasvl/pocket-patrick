# http://voidptr.io/blog/2017/01/21/GameBoy.html

# Simple makefile for assembling and linking a GB program.
rwildcard       =   $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
ASM             :=  rgbasm
LINKER          :=  rgblink
FIX             :=  rgbfix
BUILD_DIR       :=  build
PROJECT_NAME    ?=  patrick
OUTPUT          :=  $(BUILD_DIR)/$(PROJECT_NAME)
SRC_DIR         :=  src
INC_DIR         :=  inc/
SRC_ASM         :=  $(call rwildcard, $(SRC_DIR)/, *.asm)
OBJ_FILES       :=  $(addprefix $(BUILD_DIR)/obj/, $(SRC_ASM:src/%.asm=%.obj))
OBJ_DIRS        :=  $(addprefix $(BUILD_DIR)/obj/, $(dir $(SRC_ASM:src/%.asm=%.obj)))
ASMFLAGS        :=  -p0 -v -i $(INC_DIR)
LINKERFLAGS     :=  -m $(OUTPUT).map -n $(OUTPUT).sym -d
FIXFLAGS        :=  -v -p0

.PHONY: all clean

all: fix
    
fix: build
	$(FIX) $(FIXFLAGS) $(OUTPUT).gb

build: $(OBJ_FILES)
	$(LINKER) -o $(OUTPUT).gb $(LINKERFLAGS) $(OBJ_FILES)
 
$(BUILD_DIR)/obj/%.obj : src/%.asm | $(OBJ_DIRS)
	$(ASM) -o $@ $(ASMFLAGS) $<

$(OBJ_DIRS): 
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)

print-%  : ; @echo $* = $($*)
