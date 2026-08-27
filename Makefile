# Fixed TZ to ensure consistency
export TZ := UTC

OCITOOL=podman # or docker
IMAGE_NAME ?= lfdevs/archlinux-ports
BUILDDIR=$(shell pwd)/build
OUTPUTDIR=$(shell pwd)/output
SOURCE_DATE_EPOCH=$(shell date -u -d "00:00:00" +"%s")

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)

.PRECIOUS: $(OUTPUTDIR)/%.tar.zst
$(OUTPUTDIR)/%.tar.zst:
	scripts/make-rootfs.sh $(*) $(BUILDDIR) $(OUTPUTDIR)

.PRECIOUS: $(OUTPUTDIR)/Dockerfile.%
$(OUTPUTDIR)/Dockerfile.%: $(OUTPUTDIR)/%.tar.zst
	scripts/make-dockerfile.sh "$(*).tar.zst" $(*) $(OUTPUTDIR) "true" "$(*)" $(SOURCE_DATE_EPOCH)

# The following is for local builds only, it is not used by the CI/CD pipeline

all: image-base image-base-devel
image-%: $(OUTPUTDIR)/Dockerfile.%
	${OCITOOL} build -f $(OUTPUTDIR)/Dockerfile.$(*) -t $(IMAGE_NAME):$(*) $(OUTPUTDIR)
