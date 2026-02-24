CC = gcc
CFLAGS = -Wall -Wextra -Iinclude -fPIC
LDFLAGS =
AR = ar
ARFLAGS = rcs

SRCDIR = src
INCDIR = include
OBJDIR = obj
LIBDIR = lib
TESTDIR = test

SRCS = $(wildcard $(SRCDIR)/*.c)
OBJS = $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.o,$(SRCS))

TARGET_LIB = $(LIBDIR)/libbash_toolkit.a
TARGET_SO = $(LIBDIR)/libbash_toolkit.so
TEST_BIN = $(TESTDIR)/test_sdk

.PHONY: all clean test

all: $(TARGET_LIB) $(TARGET_SO) $(TEST_BIN)

$(TARGET_LIB): $(OBJS) | $(LIBDIR)
	$(AR) $(ARFLAGS) $@ $^

$(TARGET_SO): $(OBJS) | $(LIBDIR)
	$(CC) -shared -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(TEST_BIN): $(TESTDIR)/test_sdk.c $(TARGET_LIB)
	$(CC) $(CFLAGS) $< -o $@ -L$(LIBDIR) -lbash_toolkit

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(LIBDIR):
	mkdir -p $(LIBDIR)

clean:
	rm -rf $(OBJDIR) $(LIBDIR) $(TEST_BIN)

test: $(TEST_BIN)
	./$(TEST_BIN)
