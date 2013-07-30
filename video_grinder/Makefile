
VIDEOS_DIR = /path/to/all/your/videos
FFMPEG_EXTRA_OPTS = -b:a 128k
OUTPUT_DIR = .

# Create a file named Makefile.local to override the latter variables
-include Makefile.local

SUBDIRS = $(wildcard $(OUTPUT_DIR)/*/)

all: $(SUBDIRS)

%: %/
%/: %.timestamps.txt
	@mkdir -p "$@"
	./video_grinder.pl $< "$(VIDEOS_DIR)" "$@" $(FFMPEG_EXTRA_OPTS)
	@touch "$@".foobar && rm -f "$@".foobar
