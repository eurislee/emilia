NAME = meris
PREFIX    ?= /usr/local
BINPREFIX ?= $(PREFIX)/bin

ARGS =

SRC_DIR = src
BUILD_DIR = build
TARGET_DIR = .

ifeq ($(shell uname -s),FreeBSD)
	CC?= gcc
	INCLUDES = -I/usr/local/include/freetype2/
	INCLUDES += -I/usr/local/include
	LDLIBS = -lGL -lfreetype -lfontconfig -lutil -L/usr/local/lib -lm
else
	CC?= cc
	INCLUDES = -I/usr/include/freetype2/
	LDLIBS = -lGL -lfreetype -lfontconfig -lutil -L/usr/lib -lm
endif

ifeq ($(mode),sanitized)
	CFLAGS = -std=c18 -MD -O0 -g3 -ffinite-math-only -fno-rounding-math -fshort-enums -fsanitize=address -fsanitize=undefined -DDEBUG
	LDFLAGS =  -fsanitize=address -fsanitize=undefined -fsanitize=unreachable
	LDLIBS += -lGLU
else ifeq ($(mode),debug)
	CFLAGS = -std=c18 -MD -g -O0 -fno-omit-frame-pointer -fshort-enums -DDEBUG
	LDFLAGS = -O0 -g
	LDLIBS += -lGLU
else ifeq ($(mode),debugoptimized)
	CFLAGS = -std=c18 -MD -g -O2 -fno-omit-frame-pointer -mtune=generic -ffast-math -fshort-enums -DDEBUG
	LDFLAGS = -O2 -g
	LDLIBS += -lGLU
else
	CFLAGS = -std=c18 -MD -O2 -flto=auto -mtune=generic -ffast-math -fshort-enums
	LDFLAGS = -O2 -flto=auto
endif

ifeq ($(libutf8proc),off)
$(info libutf8proc not found. Support for language-specific combining characters and unicode normalization will be disabled.)
	CFLAGS += -DNOUTF8PROC
else
	LDLIBS += -lutf8proc
endif

CCWNO = -Wall -Wextra -Wno-unused-parameter -Wno-unused-function -Werror=implicit-function-declaration

SRCS = $(wildcard $(SRC_DIR)/*.c)

XLDLIBS = -lX11 -lXrender -lXrandr
WLLDLIBS = -lwayland-client -lwayland-egl -lwayland-cursor -lxkbcommon -lEGL

ifeq ($(window_protocol), x11)
	CFLAGS += -DNOWL
	OBJ = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
	LDLIBS += $(XLDLIBS)
else ifeq ($(window_protocol), wayland)
	CFLAGS += -DNOX
	OBJ = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
	LDLIBS += $(WLLDLIBS)
else
	OBJ = $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)
	LDLIBS += $(XLDLIBS) $(WLLDLIBS)
endif

ifeq ($(renderer), gles20)
	CFLAGS += -DGFX_GLES
	LDLIBS += -lGLESv2
else
	LDLIBS += -lGL
endif


$(NAME): $(OBJ)
	$(CC) $(OBJ) $(LDLIBS) -o $(TARGET_DIR)/$(NAME) $(LDFLAGS)

all: $(OBJ)
	$(CC) $(OBJ) $(LDLIBS) -o $(TARGET_DIR)/$(NAME) $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) -c $< $(CFLAGS) $(CCWNO) $(INCLUDES) -o $@

run:
	./$(TARGET_DIR)/$(NAME) $(ARGS)

debug:
	gdb --args ./$(TARGET_DIR)/$(NAME) $(ARGS)

clean:
	$(RM) -f $(OBJ)

cleanall:
	$(RM) -f $(NAME) $(OBJ) $(OBJ:.o=.d)

install:
	@mkdir -p "$(DESTDIR)$(BINPREFIX)"
	@cp -pf $(NAME) "$(DESTDIR)$(BINPREFIX)"

uninstall:
	$(RM) $(DESTDIR)$(BINPREFIX)/$(NAME)

-include $(OBJ:.o=.d)