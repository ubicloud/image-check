# Define URLs for all required images
include urls.mk

# Auto-detect targets from URL_* variables
IMAGES := $(patsubst URL_%,%,$(filter URL_%,$(.VARIABLES)))

# Group images by source (for better parallel distribution)
UBUNTU_IMAGES := $(filter ubuntu-%,$(IMAGES))
DEBIAN_IMAGES := $(filter debian-%,$(IMAGES))
ALMA_IMAGES := $(filter AlmaLinux-%,$(IMAGES))

# Interleave images from different sources
ORDERED_IMAGES := $(sort $(foreach i,$(shell seq 1 20),$(word $i,$(UBUNTU_IMAGES)) $(word $i,$(DEBIAN_IMAGES)) $(word $i,$(ALMA_IMAGES))))

.PHONY: all download checksums clean distclean

all: download checksums

download: $(ORDERED_IMAGES)

checksums: $(addsuffix .sha256,$(IMAGES))

$(IMAGES):
	@echo "Downloading $@ ..."
	@curl -sfL "$(URL_$@)" > "$@.tmp"
	@sync "$@.tmp"
	@mv "$@.tmp" "$@"
	@echo "Finished $@"

# Generate SHA256 files separately (can be run in parallel)
%.sha256: %
	@echo "Computing SHA256 for $< ..."
	@sha256sum "$<" | cut -d ' ' -f 1 > "$@.tmp"
	@sync "$@.tmp"
	@mv "$@.tmp" "$@"
	@echo "Generated $@"

clean:
	@rm -f $(addsuffix .tmp,$(IMAGES)) *.sha256 *.tmp

# Deep clean (removes downloaded images too)
distclean: clean
	@rm -f $(IMAGES)
